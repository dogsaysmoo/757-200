# Pneumatics

var pneumatic = {
    new : func {
        m = { parents : [pneumatic]};
	m.controls = props.globals.getNode("controls/pneumatic",1);
	m.system = props.globals.getNode("systems/pneumatic",1);
	# Switches
	m.apu_valve = m.controls.initNode("apu-bleed",0,"BOOL");
	m.eng_bleed = [ m.controls.initNode("eng-bleed[0]",0,"BOOL"),
			m.controls.initNode("eng-bleed[1]",0,"BOOL") ];
	m.isln = m.controls.initNode("isln",0,"BOOL");

	# Supplies
	m.APU = props.globals.getNode("engines/apu/running",1);
	m.eng = [ props.globals.getNode("engines/engine[0]/started",1),
		  props.globals.getNode("engines/engine[1]/started",1) ];
	m.service = m.system.initNode("service-air",0,"BOOL");

	# Packs
	m.pack_knob = [ m.controls.initNode("packs/pack-knob[0]",0,"BOOL"),
			m.controls.initNode("packs/pack-knob[1]",0,"BOOL") ];
	m.pack_status = [ m.system.initNode("pack[0]",0,"INT"),
			  m.system.initNode("pack[1]",0,"INT") ];

	# Demands
	m.starter = [ props.globals.getNode("controls/engines/engine[0]/starter",1),
		      props.globals.getNode("controls/engines/engine[1]/starter",1) ];
	m.APU_gen = props.globals.getNode("controls/electric/APU-generator",1);
	m.deice = props.globals.getNode("controls/anti-ice/wing-heat",1);
	m.deice.setBoolValue(0);

	# Output
	m.bleed_air = [ m.system.initNode("bleed-air[0]",0,"BOOL"),
			m.system.initNode("bleed-air[1]",0,"BOOL") ];
	m.pressure = [ m.system.initNode("pres[0]",0,"DOUBLE"),
		       m.system.initNode("pres[1]",0,"DOUBLE") ];
	m.pres = [ 0.0, 0.0 ];

    return m;
    },

    update_pres : func {
	# Supply
	var supply_l = 0.0;
	var supply_r = 0.0;

	#   Left
	if (me.service.getBoolValue())
		supply_l = supply_l + 0.89;
	if (me.APU.getBoolValue() and me.apu_valve.getBoolValue())
		supply_l = supply_l + 1.02;
	if (me.eng[0].getBoolValue() and me.eng_bleed[0].getBoolValue())
		supply_l = supply_l + 1.08;

	#   Right
	if (!me.isln.getBoolValue())
		supply_r = supply_l;
	if (me.eng[1].getBoolValue() and me.eng_bleed[1].getBoolValue())
		supply_r = supply_r + 1.08;

	if (!me.isln.getBoolValue())
		supply_l = supply_r;

	supply_l = 45 * supply_l;
	supply_r = 45 * supply_r;

	# Demand
	var demand_l = 0.0;
	var demand_r = 0.0;

	#   Left
	if (me.pack_status[0].getValue() == 1)
		demand_l = demand_l + 0.3;
	if (me.starter[0].getBoolValue())
	    if (getprop("engines/engine[0]/rpm") < (0.68 * getprop("engines/engine[0]/n1"))) {
		demand_l = demand_l + 0.33;
	    } else {
		demand_l = demand_l + 0.12;
	    }
	if (me.APU_gen.getBoolValue())
		demand_l = demand_l + 0.07;

	#   Right
	if (!me.isln.getBoolValue())
		demand_r = demand_l;
	if (me.pack_status[1].getValue() == 1)
		demand_r = demand_r + 0.3;
	if (me.starter[1].getBoolValue())
	    if (getprop("engines/engine[1]/rpm") < (0.68 * getprop("engines/engine[1]/n1"))) {
		demand_r = demand_r + 0.33;
	    } else {
		demand_r = demand_r + 0.12;
	    }
	if (!me.isln.getBoolValue())
		demand_l = demand_r;

	if (me.deice.getBoolValue()) {
		demand_l = demand_l + 0.18;
		demand_r = demand_r + 0.18;
	}

	demand_l = 8 * demand_l;
	demand_r = 8 * demand_r;


	supply_l = supply_l - demand_l;
	supply_r = supply_r - demand_r;

	if (supply_l > 45) supply_l = 45;
	if (supply_r > 45) supply_r = 45;
	if (supply_l < 0) supply_l = 0;
	if (supply_r < 0) supply_r = 0;

	if (supply_l > 36.8) {
		me.bleed_air[0].setBoolValue(1);
	} else {
		me.bleed_air[0].setBoolValue(0);
	}
	if (supply_r > 36.8) {
		me.bleed_air[1].setBoolValue(1);
	} else {
		me.bleed_air[1].setBoolValue(0);
	}
	me.pres[0] = supply_l;
	me.pres[1] = supply_r;
    },

    change_needle : func (side) {
	var dt = getprop("sim/time/delta-sec");
	if (abs(me.pressure[side].getValue() - me.pres[side]) > (9 * dt)) {
		if (me.pressure[side].getValue() > me.pres[side])
			me.pressure[side].setValue(me.pressure[side].getValue() - ((3.5 + rand()) * 2 * dt));
		if (me.pressure[side].getValue() < me.pres[side])
			me.pressure[side].setValue(me.pressure[side].getValue() + ((3.5 + rand()) * 2 * dt));
			
	} else {
		me.pressure[side].setValue(me.pres[side]);
	}
	settimer(func{me.change_needle(side);},0);
    },

    update : func {
	# Packs
	if (me.pack_knob[0].getBoolValue() and (me.pack_status[0].getValue() != -1)) {
		me.pack_status[0].setValue(1);
	} elsif (!me.pack_knob[0].getBoolValue()) {
		me.pack_status[0].setValue(0);
	}
	if (me.pack_knob[1].getBoolValue() and (me.pack_status[1].getValue() != -1)) {
		me.pack_status[1].setValue(1);
	} elsif (!me.pack_knob[1].getBoolValue()) {
		me.pack_status[1].setValue(0);
	}

	# Low pressure cutouts
	var cutout_l = 0;
	var cutout_r = 0;

	if (!me.bleed_air[0].getBoolValue())
		cutout_l = 1;
	if (!me.bleed_air[1].getBoolValue())
		cutout_r = 1;

	if (getprop("instrumentation/airspeed-indicator/indicated-speed-kt") < 180) {
	    if (cutout_l == 1 and me.starter[0].getBoolValue()) {
		me.starter[0].setBoolValue(0);
		cutout_l = 0;
		cutout_r = 0;
	    }
	    if (cutout_r == 1 and me.starter[1].getBoolValue()) {
		me.starter[1].setBoolValue(0);
		cutout_l = 0;
		cutout_r = 0;
	    }
	}
	if (cutout_l == 1 and me.pack_status[0].getValue() == 1) {
		me.pack_status[0].setValue(-1);
		cutout_l = 0;
		cutout_r = 0;
	}
	if (cutout_r == 1 and me.pack_status[1].getValue() == 1) {
		me.pack_status[1].setValue(-1);
		cutout_l = 0;
		cutout_r = 0;
	}
	if (cutout_l == 1 and cutout_r == 1)
		me.deice.setBoolValue(0);

	me.update_pres();
	settimer(func{me.update();},1);
    }
	
};
B757air = pneumatic.new();
setlistener("/sim/signals/fdm-initialized", func (init) {
	if (init.getBoolValue()) {
		settimer( func {
		    B757air.update();
		    B757air.change_needle(0);
		    B757air.change_needle(1);
		},2);
	}
},0,0);



