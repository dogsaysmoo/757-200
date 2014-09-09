# A handler to turn off auto-coordination on the ground and when the AP is on.

var ac_handler = {
    new : func {
	m = { parents : [ac_handler] };
	
	m.autocoord = props.globals.getNode("controls/flight/auto-coordination",1);
	m.wow = props.globals.getNode("gear/gear[0]/wow",1);
	m.AP = props.globals.getNode("instrumentation/afds/inputs/AP",1);

	m.uses_autocoord = 0;

	return m;
    },
    update : func {
	if (me.autocoord.getBoolValue()) {
	    me.uses_autocoord = 0;
	    if (me.wow.getBoolValue() or me.AP.getBoolValue()) {
		me.uses_autocoord = 1;
		me.autocoord.setBoolValue(0);
	    }
	}
    },
    listeners : func {
	setlistener("controls/flight/auto-coordination", func {
	    if (me.autocoord.getBoolValue()) me.update();
	},0,0);
#	var state = 1;
#	var ac_state = func {
#	    if (me.autocoord.getBoolValue() and state == 1) {
#		me.update();
#		state = 0;
#	    }
#	    if (!me.autocoord.getBoolValue()) state = 1;
#	    settimer(ac_state,0);
#	}
#	ac_state();

	setlistener("gear/gear[0]/wow", func {
	    if (me.wow.getBoolValue()) {
		me.update();
	    } else {
		if (me.uses_autocoord == 1) me.autocoord.setBoolValue(1);
	    }
	},0,0);
	setlistener("instrumentation/afds/inputs/AP", func {
	    if (me.AP.getBoolValue()) {
		me.update();
	    } else {
		if (me.uses_autocoord == 1) me.autocoord.setBoolValue(1);
	    }
	},0,0);
    }
};
var acrd = ac_handler.new();
setlistener("/sim/signals/fdm-initialized", func {
	acrd.listeners();
	acrd.update();
},0,0);

