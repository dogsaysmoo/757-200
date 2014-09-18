# Hour meters for electrical system, engines, and in-the-air flight time.
# J Williams, Aug 2014

var meter = {
    new : func (proppath) {
	m = { parents : [meter] };
	
	m.meterpath = props.globals.getNode(proppath);

	m.tick = 0;
	m.last_time = 0.0;
	m.elap_time = 0.0;
	m.meter_active = 0;

	return m;
    },
    activate : func (go) {
	me.meter_active = go;
	if (go == 1) {
	    me.tick = 0;
	    me.last_time = getprop("sim/time/elapsed-sec");
	    me.elap_time = 0.0;
	    settimer(func me.cycle(),1);
	}

    },
    cycle : func {
	me.tick += 1;
	me.elap_time = me.elap_time + ((getprop("sim/time/elapsed-sec") - me.last_time) * getprop("sim/speed-up"));
	me.last_time = getprop("sim/time/elapsed-sec");
	if (me.tick == 6 or me.meter_active == 0) {
	    me.meterpath.setValue(me.meterpath.getValue() + (me.elap_time / 3600));
	    me.elap_time = 0.0;
	    me.tick = 0;
	}
	if (me.meter_active == 1) settimer(func me.cycle(),1);
    },
};
var ENGmeter = [ meter.new("systems/hour-meters/engine-hours[0]"),
		 meter.new("systems/hour-meters/engine-hours[1]") ];
var ELECmeter = meter.new("systems/hour-meters/electrical-hours");
var FLTmeter = meter.new("systems/hour-meters/flight-hours");

setlistener("gear/gear[2]/wow", func (wow) {
	if (wow.getBoolValue()) {
	    FLTmeter.activate(0);
	} else {
	    FLTmeter.activate(1);
	}
},0,0);
setlistener("sim/model/start-idling", func {
# For in-air starting
	if (!getprop("gear/gear[2]/wow") and FLTmeter.meter_active == 0)
	    FLTmeter.activate(1);
},0,0);

var elec_check = func {
	var elec = getprop("systems/electrical/left-bus") > 15 or getprop("systems/electrical/right-bus") > 15;
	if (ELECmeter.meter_active == 0 and elec) ELECmeter.activate(1);
	if (ELECmeter.meter_active == 1 and !elec) ELECmeter.activate(0);
}
setlistener("systems/electrical/left-bus", func {
	elec_check();
},0,0);
setlistener("systems/electrical/right-bus", func {
	elec_check();
},0,0);

var eng_check = func (i) {
	var cutoff = getprop("engines/engine["~i~"]/started");
	if (cutoff) {
	    ENGmeter[i].activate(1);
	} else {
	    ENGmeter[i].activate(0);
	}
}
setlistener("engines/engine[0]/started", func {
	eng_check(0);
},0,0);
setlistener("engines/engine[1]/started", func {
	eng_check(1);
},0,0);

aircraft.data.add(
	"systems/hour-meters/engine-hours[0]",
	"systems/hour-meters/engine-hours[1]",
	"systems/hour-meters/electrical-hours",
	"systems/hour-meters/flight-hours");

