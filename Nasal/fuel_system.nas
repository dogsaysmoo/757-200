# 757 fuel system, John Williams, March 2014

var fuelsys = {
    new : func {
        m = { parents : [fuelsys] };

	m.controls = props.globals.getNode("controls/fuel",1);
	m.tanks = props.globals.getNode("consumables/fuel",1);
	
	m.pumpL = m.controls.initNode("tank/pump",0,"BOOL");
	m.pumpR = m.controls.initNode("tank[1]/pump",0,"BOOL");
	m.pumpC = m.controls.initNode("tank[2]/pump",0,"BOOL");
	m.xfeed = m.controls.initNode("x-feed",0,"BOOL");

	m.sel = [ m.tanks.getNode("tank/selected",1),
		m.tanks.getNode("tank[1]/selected",1),
		m.tanks.getNode("tank[2]/selected",1),
		m.tanks.getNode("tank[3]/selected",1),
		m.tanks.getNode("tank[4]/selected",1) ];

	m.lev = [ m.tanks.getNode("tank/level-lbs",1),
		m.tanks.getNode("tank[1]/level-lbs",1),
		m.tanks.getNode("tank[2]/level-lbs",1),
		m.tanks.getNode("tank[3]/level-lbs",1),
		m.tanks.getNode("tank[4]/level-lbs",1) ];

	m.emp = [ m.tanks.getNode("tank/empty",1),
		m.tanks.getNode("tank[1]/empty",1),
		m.tanks.getNode("tank[2]/empty",1),
		m.tanks.getNode("tank[3]/empty",1),
		m.tanks.getNode("tank[4]/empty",1) ];

	m.aircraft = props.globals.getNode("sim/aircraft",1);

	return m;
    },

    startup : func {
	var density = getprop('/consumables/fuel/tank/density-ppg');
	var capacity_wing = (getprop('/consumables/fuel/tank/capacity-gal_us') + getprop('/consumables/fuel/tank[1]/capacity-gal_us')) * density;
	var capacity_center = getprop('/consumables/fuel/tank[2]/capacity-gal_us') * density;
	var fuel_lbs = me.lev[0].getValue() + me.lev[1].getValue() + me.lev[2].getValue();
	if (me.aircraft.getValue() == 'C-32A'){
		fuel_lbs += me.lev[3].getValue() + me.lev[4].getValue();
	}
	if (fuel_lbs < capacity_wing) {
		me.lev[0].setValue(fuel_lbs / 2);
		me.lev[1].setValue(fuel_lbs / 2);
		me.lev[2].setValue(0);
		me.lev[3].setValue(0);
		me.lev[4].setValue(0);
	} else if (me.aircraft.getValue() == 'C-32A' and fuel_lbs > (capacity_wing + capacity_center)) {
		setprop('/consumables/fuel/tank/level-norm', 1);
		setprop('/consumables/fuel/tank[1]/level-norm', 1);
		setprop('/consumables/fuel/tank[2]/level-norm', 1);
		me.lev[3].setValue((fuel_lbs - capacity_wing - capacity_center) / 2);
		me.lev[4].setValue((fuel_lbs - capacity_wing - capacity_center) / 2);
	} else {
		setprop('/consumables/fuel/tank/level-norm', 1);
		setprop('/consumables/fuel/tank[1]/level-norm', 1);
		me.lev[2].setValue(fuel_lbs - capacity_wing);
		me.lev[3].setValue(0);
		me.lev[4].setValue(0);
	}
    },

    update : func {
	var Lsel = 0;
	var Rsel = 0;
	var Csel = 0;

	var aux_fuel = (me.aircraft.getValue() == 'C-32A' and !(me.emp[3].getBoolValue() and me.emp[4].getBoolValue()));

	var n1L = getprop("engines/engine[0]/rpm");
	var n1R = getprop("engines/engine[1]/rpm");

	# Cut out pumps on empty tanks
	if (me.pumpL.getBoolValue() and me.emp[0].getBoolValue())
		 setprop("controls/fuel/tank[0]/pump",0);
	if (me.pumpR.getBoolValue() and me.emp[1].getBoolValue())
		 setprop("controls/fuel/tank[1]/pump",0);
	if (me.pumpC.getBoolValue() and me.emp[2].getBoolValue() and !aux_fuel)
		 setprop("controls/fuel/tank[2]/pump",0);

	# Pump status
	if (me.pumpL.getBoolValue())
		Lsel = 1;
	if (me.pumpR.getBoolValue())
		Rsel = 1;
	if (me.pumpC.getBoolValue())
		Csel = 1;

	# Center tank pumps are inhibited when N2 < 50%
	# Otherwise, center tank pumps override wing tank pumps
	if (Lsel == 1 and Rsel == 1 and Csel == 1) {
		if (n1L < 55 and n1R < 55) {
			Csel = 0;
		} elsif (me.lev[2].getValue() > 50) {
			Lsel = 0;
			Rsel = 0;
		}
	}

	# Engine suction and Engine cutouts
	if (Lsel == 0 and Csel == 0 and !(Rsel == 1 and me.xfeed.getBoolValue())) {
		if (n1L > 21 and n1L < 89 and getprop("/instrumentation/airspeed-indicator/indicated-speed-kt") > 180) {
			Lsel = 1;
		} else {
			if (getprop("engines/engine[0]/running"))
			    setprop("engines/engine[0]/started",0);
		}
	
	}
	if (Rsel == 0 and Csel == 0 and !(Lsel == 1 and me.xfeed.getBoolValue())) {
		if (n1R > 21 and n1R < 89 and getprop("/instrumentation/airspeed-indicator/indicated-speed-kt") > 180) {
			Rsel = 1;
		} else {
			if (getprop("engines/engine[1]/running"))
			    setprop("engines/engine[1]/started",0);
		}
	}

	# Deselect empty tanks and set the tank selection statuses
	if (me.aircraft.getValue() == 'C-32A') {
		if (me.emp[3].getBoolValue()) me.sel[3].setBoolValue(0);
		else me.sel[3].setBoolValue(Csel);
		if (me.emp[4].getBoolValue()) me.sel[4].setBoolValue(0);
		else me.sel[4].setBoolValue(Csel);
	}
	if (me.emp[0].getBoolValue()) Lsel = 0;
	if (me.emp[1].getBoolValue()) Rsel = 0;
	if (me.emp[2].getBoolValue()) Csel = 0;

	me.sel[0].setBoolValue(Lsel);
	me.sel[1].setBoolValue(Rsel);
	me.sel[2].setBoolValue(Csel);

#		if (me.emp[3].getBoolValue() and me.emp[4].getBoolValue()) {
#		    me.sel[2].setBoolValue(Csel);
#		    me.sel[3].setBoolValue(0);
#		    me.sel[4].setBoolValue(0);
#		} else {
#		    me.sel[2].setBoolValue(0);
#		    if (me.emp[3].getBoolValue()) {
#			me.sel[3].setBoolValue(0);
#		    } else {
#			me.sel[3].setBoolValue(Csel);
#		    }
#		    if (me.emp[4].getBoolValue()) {
#			me.sel[4].setBoolValue(0);
#		    } else {
#			me.sel[4].setBoolValue(Csel);
#		    }
#		}
#	} else {
#		me.sel[2].setBoolValue(Csel);
#	}

	me.elec_update();
	settimer(func { me.update();},0.5);
    },

    elec_update : func {
	var busL = getprop("systems/electrical/left-bus");
	var busR = getprop("systems/electrical/right-bus");
	var tieL = getprop("systems/electrical/bus-tie[0]");
	var tieR = getprop("systems/electrical/bus-tie[1]");

	var left = 0;
	var right = 0;

	if (busL > 25 or (busR > 25 and tieR and tieL))
		left = 1;
	if (busR > 25 or (busL > 25 and tieR and tieL))
		right = 1;

	if (autostarting == 1) {
		left = 1;
		right = 1;
	}

	if (left == 0)
		me.pumpL.setBoolValue(0);
	if (right == 0)
		me.pumpR.setBoolValue(0);
	if (left == 0 and right == 0)
		me.pumpC.setBoolValue(0);
    },

    apu_fuelcon : func (dt,src) {
	var rate = 541;  #lbs/hr

	var cons = (rand() * rate) * dt / 3600;
	var surcharge = 0.0;

	if (src < 0) src = 0;

	# Insert surcharges here:
	if (getprop("controls/electrical/APU-generator"))
		surcharge = surcharge + 0.003;
	if (getprop("controls/pneumatic/apu-bleed"))
		surcharge = surcharge + 0.02;
	if (getprop("systems/pneumatic/packs/pack[0]") == 1)
		surcharge = surcharge + 0.02;
	if (getprop("systems/pneumatic/packs/pack[1]") == 1)
		surcharge = surcharge + 0.02;
	if (getprop("controls/engines/engine[0]/starter")) surcharge = surcharge + 0.2;
	if (getprop("controls/engines/engine[1]/starter")) surcharge = surcharge + 0.2;

	cons = cons * (1 + surcharge);

	if (!me.emp[src].getBoolValue()) {
		me.lev[src].setValue(me.lev[src].getValue() - cons);
	} else {
		setprop("controls/APU/off-start-run",0);
	}
    },

    idle_fuelcon : func {
	var dt = getprop("sim/time/delta-sec");

	var get_src = func (side) {
		var src = -1;
		var otherside = abs(side - 1);

		if (me.sel[2].getBoolValue()) {
			src = 2;
		} elsif (me.sel[side].getBoolValue()) {
			src = side;
		} elsif (me.sel[otherside].getBoolValue() and me.xfeed.getBoolValue()) {
			src = otherside;
		}
		return src;
	}

	var idle_ff = func (eng,src) {
		var rate = getprop("engines/engine[" ~eng~ "]/n1") * (26.0 + rand());
		#lbs/hr
		var cons = rate * dt / 3600;
		var cutoff = getprop("controls/engines/engine[" ~eng~ "]/cutoff");
		var frate = getprop("engines/engine[" ~eng~ "]/fuel-flow-gph");

		if (!cutoff and !me.emp[src].getBoolValue() and frate<10)
			me.lev[src].setValue(me.lev[src].getValue() - cons);
	}

	if (getprop("engines/engine[0]/started")) idle_ff(0,get_src(0));
	if (getprop("engines/engine[1]/started")) idle_ff(1,get_src(1));
	if (getprop("engines/apu/running")) me.apu_fuelcon(dt,get_src(0));

	settimer(func{me.idle_fuelcon();},0);
    }
};
var autostarting = 0;
var B757fuel = fuelsys.new();
setlistener("/sim/signals/fdm-initialized", func {
	B757fuel.startup();
	B757fuel.update();
	B757fuel.idle_fuelcon();
},0,0);
setlistener("/sim/model/start-idling", func (auto) {
	if (auto.getBoolValue()) {
		autostarting = 1;
		settimer(func {autostarting = 0;},30);
	}
},0,0);

