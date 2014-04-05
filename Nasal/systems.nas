# BOEING 757-200 SYSTEMS FILE
#############################

## LIVERY SELECT
################
aircraft.livery.init("Aircraft/757-200/Models/Liveries");

## LIGHTS
#########

# create all lights
var beacon_switch = props.globals.getNode("controls/switches/beacon", 2);
var beacon = aircraft.light.new("sim/model/lights/beacon", [0.05, 2], "controls/lighting/beacon");

var strobe_switch = props.globals.getNode("controls/switches/strobe", 2);
var strobe = aircraft.light.new("sim/model/lights/strobe", [0.05, 1.3], "controls/lighting/strobe");

## SOUNDS
#########

# seatbelt/no smoking sign triggers
setlistener("controls/switches/seatbelt-sign", func {
	props.globals.getNode("sim/sound/seatbelt-sign").setBoolValue(1);

	settimer(func {
	    props.globals.getNode("sim/sound/seatbelt-sign").setBoolValue(0);
	}, 2);
});
setlistener("controls/switches/no-smoking-sign", func {
	props.globals.getNode("sim/sound/no-smoking-sign").setBoolValue(1);

	settimer(func {
	    props.globals.getNode("sim/sound/no-smoking-sign").setBoolValue(0);
	}, 2);
});

## ENGINES
##########

# explanation of engine properties
# controls/engines/engine[X]/throttle-lever	When the engine isn't running, this value is constantly set to 0; otherwise, we transfer the value of controls/engines/engine[X]/throttle to it
# controls/engines/engine[X]/starter		Triggering it fires up the engine
# engines/engine[X]/running			Set based on the engine state
# engines/engine[X]/rpm				Used in place of the n1 value for the animations and set dynamically based on the engine state
# engines/engine[X]/failed			When triggered the engine is "failed" and cannot be restarted
# engines/engine[X]/on-fire			Self-explanatory

## APU loop function
var apuLoop = func {
	if (props.globals.getNode("engines/apu/on-fire").getBoolValue()) {
	    props.globals.getNode("engines/apu/serviceable").setBoolValue(0);
	}
	if (props.globals.getNode("controls/APU/fire-switch").getBoolValue()) {
	    props.globals.getNode("engines/apu/on-fire").setBoolValue(0);
	}

	var setting = getprop("controls/APU/off-start-run");

	if (props.globals.getNode("engines/apu/serviceable").getBoolValue() and setting != 0) {
	    if (setting == 1) {
		var rpm = getprop("engines/apu/rpm");
		rpm += getprop("sim/time/delta-realtime-sec") * 20;
		if (getprop("engines/apu/running")) {
		    setprop("controls/APU/off-start-run",0);
		} elsif (rpm >= 100) {
		    rpm = 100;
		    setprop("controls/APU/off-start-run",2);
		}
		setprop("engines/apu/rpm", rpm);
	    } elsif (setting == 2 and getprop("engines/apu/rpm") == 100) {
		props.globals.getNode("engines/apu/running").setBoolValue(1);
	    }
	} else {
	    props.globals.getNode("engines/apu/running").setBoolValue(0);

	    var rpm = getprop("engines/apu/rpm");
	    rpm -= getprop("sim/time/delta-realtime-sec") * 30;
	    if (rpm < 0) {
		rpm = 0;
	    }
	    setprop("engines/apu/rpm", rpm);
	}

#	settimer(apuLoop, 0);
};

## Engine loop function
var engineLoop = func(engine_no) {
 # control the throttles and main engine properties
	var engineCtlTree = "controls/engines/engine[" ~ engine_no ~ "]/";
	var engineOutTree = "engines/engine[" ~ engine_no ~ "]/";

	var bleed_air = getprop("systems/pneumatic/bleed-air[" ~ engine_no ~ "]");

 # the FDM switches the running property to true automatically if the cutoff is set to false, this is unwanted
	if (props.globals.getNode(engineOutTree ~ "running").getBoolValue() and !props.globals.getNode(engineOutTree ~ "started").getBoolValue()) {
	    props.globals.getNode(engineOutTree ~ "running").setBoolValue(0);
	}

	if (props.globals.getNode(engineOutTree ~ "on-fire").getBoolValue()) {
	    props.globals.getNode(engineOutTree ~ "failed").setBoolValue(1);
	}
	if (props.globals.getNode(engineCtlTree ~ "cutoff").getBoolValue() or props.globals.getNode(engineOutTree ~ "failed").getBoolValue() or props.globals.getNode(engineOutTree ~ "out-of-fuel").getBoolValue()) {
	    props.globals.getNode(engineOutTree ~ "started").setBoolValue(0);
	}

	if (props.globals.getNode(engineCtlTree ~ "starter").getBoolValue() and (bleed_air or getprop("instrumentation/airspeed-indicator/indicated-speed-kt") > 178)) {
#	    props.globals.getNode(engineCtlTree ~ "cutoff").setBoolValue(0);

	    var rpm = getprop(engineOutTree ~ "rpm");
	    var stop = getprop(engineOutTree ~ "n1") * 0.66;

	    if (rpm <= stop or !props.globals.getNode(engineCtlTree ~ "cutoff").getBoolValue()) {
		rpm += getprop("sim/time/delta-realtime-sec") * 3;
		setprop(engineOutTree ~ "rpm", rpm);
		setprop(engineOutTree ~ "n2-ind", (2.5 * rpm));
	    }

	    if (rpm >= getprop(engineOutTree ~ "n1")) {
		props.globals.getNode(engineCtlTree ~ "starter").setBoolValue(0);
		props.globals.getNode(engineOutTree ~ "started").setBoolValue(1);
		props.globals.getNode(engineOutTree ~ "running").setBoolValue(1);
	    } else {
		props.globals.getNode(engineOutTree ~ "running").setBoolValue(0);
	    }
	} elsif (props.globals.getNode(engineOutTree ~ "running").getBoolValue()) {
	    if (getprop("autopilot/settings/speed") == "speed-to-ga") {
		setprop(engineCtlTree ~ "throttle-lever", 1);
	    } else {
		setprop(engineCtlTree ~ "throttle-lever", getprop(engineCtlTree ~ "throttle"));
	    }

	    setprop(engineOutTree ~ "rpm", getprop(engineOutTree ~ "n1"));
	    setprop(engineOutTree ~ "n2-ind", getprop(engineOutTree ~ "n2"));
	} else {
	    if (getprop(engineOutTree ~ "rpm") > 0) {
		var rpm = getprop(engineOutTree ~ "rpm");
		rpm -= getprop("sim/time/delta-realtime-sec") * 2.5;
		setprop(engineOutTree ~ "rpm", rpm);
		setprop(engineOutTree ~ "n2-ind", (2.5 * rpm));
	    } else {
		setprop(engineOutTree ~ "rpm", 0);
		setprop(engineOutTree ~ "n2-ind", 0);
	    }

	    props.globals.getNode(engineOutTree ~ "running").setBoolValue(0);
	    props.globals.getNode(engineOutTree ~ "started").setBoolValue(0);
	    setprop(engineCtlTree ~ "throttle-lever", 0);
	}

#	settimer(func {
#	    engineLoop(engine_no);
#	}, 0);
};

## FLIGHT CONTROLS
##################
var fltctrls = props.globals.getNode("controls/flight",1);
var ailnctrl = fltctrls.getNode("aileron",1);
var elevctrl = fltctrls.getNode("elevator",1);
var rudrctrl = fltctrls.getNode("rudder",1);
var ailnpos = fltctrls.initNode("aileron-pos",0,"DOUBLE");
var elevpos = fltctrls.initNode("elevator-pos",0,"DOUBLE");
var rudrpos = fltctrls.initNode("rudder-pos",0,"DOUBLE");

var set_fltctrls = func {
    if (getprop("systems/hydraulic/equipment/enable-sfc")) {
	ailnpos.setValue(ailnctrl.getValue());
	elevpos.setValue(elevctrl.getValue());
	rudrpos.setValue(rudrctrl.getValue());
    }
#    settimer(set_fltctrls,0);
}

## System updater function, updates each frame
var update_systems = func {
	engineLoop(0);
	engineLoop(1);
	apuLoop();
	set_fltctrls();
	settimer(update_systems,0);
}

# start the loop 2 seconds after the FDM initializes
setlistener("sim/signals/fdm-initialized", func {
	props.globals.initNode("engines/engine[0]/n2-ind",0,"DOUBLE");
	props.globals.initNode("engines/engine[1]/n2-ind",0,"DOUBLE");
	settimer(func {
#	    engineLoop(0);
#	    engineLoop(1);
#	    apuLoop();
#	    set_fltctrls();
	    update_systems();
	}, 2);
});

## Startup/Shutdown functions
#############################

var startup = func {
	setprop("controls/electric/battery-switch", 1);
	setprop("controls/APU/off-start-run", 1);
	setprop("controls/electric/APU-generator", 1);
	setprop("controls/electric/engine[0]/generator", 1);
	setprop("controls/electric/engine[1]/generator", 1);
	setprop("consumables/fuel/tank[0]/selected",1);
	setprop("consumables/fuel/tank[1]/selected",1);
	setprop("consumables/fuel/tank[2]/selected",1);
	setprop("controls/fuel/tank[0]/pump", 1);
	setprop("controls/fuel/tank[1]/pump", 1);
	setprop("controls/fuel/tank[2]/pump", 1);
	setprop("controls/pneumatic/apu-bleed", 1);
	setprop("controls/pneumatic/eng-bleed[0]", 1);
	setprop("controls/pneumatic/eng-bleed[1]", 1);
	setprop("controls/hydraulic/engine-pump[0]",1);
	setprop("controls/hydraulic/engine-pump[1]",1);
	setprop("controls/hydraulic/electric-pump[0]",1);
	setprop("controls/hydraulic/electric-pump[1]",1);
	setprop("controls/hydraulic/electric-pump[2]",1);
	

	var listener1 = setlistener("engines/apu/rpm", func {
	    if (getprop("engines/apu/rpm") >= 100) {
		setprop("controls/APU/off-start-run", 2);
		settimer(func {
		    setprop("controls/engines/engine[0]/cutoff", 0);
		    setprop("controls/engines/engine[1]/cutoff", 0);
		    setprop("controls/engines/engine[0]/starter", 1);
		    setprop("controls/engines/engine[1]/starter", 1);
		}, 1.1);
		removelistener(listener1);
	    }
	}, 0, 0);
	var listener2 = setlistener("engines/engine[0]/rpm", func {
	    if (getprop("engines/engine[0]/rpm") >= getprop("engines/engine[0]/n1")) {
		settimer(func {
		    setprop("controls/APU/off-start-run", 0);
		    setprop("controls/electric/APU-generator", 0);
		    setprop("controls/pneumatic/apu-bleed", 0);
		}, 2);
		removelistener(listener2);
	    }
	}, 0, 0);
};
var shutdown = func {
	setprop("controls/electric/battery-switch", 0);
	setprop("controls/electric/engine[0]/generator", 0);
	setprop("controls/electric/engine[1]/generator", 0);
	setprop("controls/engines/engine[0]/cutoff", 1);
	setprop("controls/engines/engine[1]/cutoff", 1);
	setprop("controls/fuel/tank[0]/pump", 0);
	setprop("controls/fuel/tank[1]/pump", 0);
	setprop("controls/fuel/tank[2]/pump", 0);
	setprop("controls/pneumatic/eng-bleed[0]", 0);
	setprop("controls/pneumatic/eng-bleed[1]", 0);
	setprop("controls/hydraulic/engine-pump[0]",0);
	setprop("controls/hydraulic/engine-pump[1]",0);
	setprop("controls/hydraulic/electric-pump[0]",0);
	setprop("controls/hydraulic/electric-pump[1]",0);
	setprop("controls/hydraulic/electric-pump[2]",0);
};

# listener to activate these functions accordingly
setlistener("sim/model/start-idling", func(idle) {
	var run = idle.getBoolValue();
	if (run) {
	    startup();
	} else {
	    shutdown();
	}
}, 0, 0);

## GEAR
#######

# prevent retraction of the landing gear when any of the wheels are compressed
controls.gearDown = func(v) {
    var wow = getprop("gear/gear[0]/wow") or getprop("gear/gear[1]/wow") or getprop("gear/gear[2]/wow");
    if (v < 0 and getprop("systems/hydraulic/equipment/enable-flap")) {
        # flaps and gear up have the same hydraulic requirements
        if(!wow) setprop("/controls/gear/gear-down", 0);
    }
        elsif (v > 0 and getprop("systems/hydraulic/equipment/enable-gear")) {
      setprop("/controls/gear/gear-down", 1);
    }
}

setlistener("controls/gear/alt-gear", func (alt) {
        if (alt.getBoolValue()) {
                setprop("controls/gear/gear-down",1);
                setlistener("controls/gear/gear-down", func {
                    setprop("controls/gear/gear-down",1);
                },0,0);
        }
},0,0);

## FLAPS
########

controls.flapsDown = func(step) {
    if (getprop("systems/hydraulic/equipment/enable-flap") or getprop("controls/flight/alt-flaps") != 0) {
        if(step == 0) return;
        if(props.globals.getNode("/sim/flaps") != nil) {
                globals.controls.stepProps("/controls/flight/flaps", "/sim/flaps", step);
                return;
        }
        # Hard-coded flaps movement in 3 equal steps:
        var val = 0.3333334 * step + getprop("/controls/flight/flaps");
        setprop("/controls/flight/flaps", val > 1 ? 1 : val < 0 ? 0 : val);
    }
}

var altflapspos = props.globals.initNode("controls/flight/alt-flaps-pos",-1,"INT");
var altflap = props.globals.initNode("controls/flight/alt-flaps",0,"INT");
var altn_flapsDown = func (step) {
    if (step == 0) return;
    if (step < 0 and altflapspos.getValue() == -1) return;
    if (step > 0 and altflapspos.getValue() == 6) return;
    altflapspos.setValue(altflapspos.getValue() + step);
    if (altflapspos.getValue() > 0) {
	altflap.setValue(step);
	settimer(func {altflap.setValue(0);}, 0.15);
	controls.flapsDown(step);
    }
}

## SPEEDBRAKES
##############

setlistener("controls/flight/speedbrake-lever", func (spoiler) {
	if (spoiler.getValue() > 1 and !getprop("systems/hydraulic/equipment/enable-spoil")) setprop("controls/flight/speedbrake-lever",1);
},0,0);

## INSTRUMENTS
##############

var instruments =
 {
    loop: func {
	instruments.setHSIBugsDeg();
	instruments.setwinddisplay();

	settimer(instruments.loop, 0);
    },
 # set the rotation of the HSI bugs
    setHSIBugsDeg: func {
	var calcBugDeg = func(bug) {
	    var heading = getprop("orientation/heading-deg");
	    var bugDeg = 0;

	    while (bug < 0) {
		bug += 360;
	    }
	    while (bug > 360) {
		bug -= 360;
	    }
	    if (bug < 32) {
		bug += 360;
	    }
	    if (heading < 32) {
		heading += 360;
	    }
   # bug is adjusted normally
	    if (math.abs(heading - bug) < 32) {
		bugDeg = heading - bug;
	    } elsif (heading - bug < 0) {
    # bug is on the far right
		if (math.abs(heading - bug + 360 >= 180)) {
		    bugDeg = -32;
		} elsif (math.abs(heading - bug + 360 < 180)) {
    # bug is on the far left
		    bugDeg = 32;
		}
	    } else {
    # bug is on the far right
		if (math.abs(heading - bug >= 180)) {
		    bugDeg = -32;
		} elsif (math.abs(heading - bug < 180)) {
    # bug is on the far left
		    bugDeg = 32;
		}
	    }

	    return bugDeg;
	};
	var true_hdgbug = getprop("orientation/heading-deg") - getprop("orientation/heading-magnetic-deg") + getprop("autopilot/settings/heading-bug-deg");
	var adfbug1 = getprop("orientation/heading-deg") + getprop("instrumentation/adf/indicated-bearing-deg");
	var adfbug2 = getprop("orientation/heading-deg") + getprop("instrumentation/adf[1]/indicated-bearing-deg");
	var radialbug = getprop("orientation/heading-deg") - getprop("orientation/heading-magnetic-deg") + getprop("instrumentation/nav[0]/radials/selected-deg");
#	setprop("sim/model/B757/heading-bug-deg", calcBugDeg(getprop("autopilot/settings/heading-bug-deg")));
	setprop("sim/model/B757/heading-bug-deg", calcBugDeg(true_hdgbug));
	setprop("sim/model/B757/nav1-track-deg", calcBugDeg(radialbug));
	setprop("sim/model/B757/nav1-bug-deg", calcBugDeg(getprop("instrumentation/nav[0]/heading-deg")));
	setprop("sim/model/B757/nav2-bug-deg", calcBugDeg(getprop("instrumentation/nav[1]/heading-deg")));
#	setprop("sim/model/B757/adf-bug-deg", calcBugDeg(getprop("instrumentation/adf/indicated-bearing-deg")));
	setprop("sim/model/B757/adf1-bug-deg", calcBugDeg(adfbug1));
	setprop("sim/model/B757/adf2-bug-deg", calcBugDeg(adfbug2));
    },
    setwinddisplay: func {
	var wind = getprop("environment/wind-from-heading-deg");
	var disp = props.globals.initNode("environment/wind-display",0,"DOUBLE");
	while (wind < 0) wind+=360;
	while (wind >= 360) wind-=360;
	disp.setValue(wind);
    }
};
# start the loop 2 seconds after the FDM initializes
setlistener("sim/signals/fdm-initialized", func {
	settimer(instruments.loop, 2);
});

