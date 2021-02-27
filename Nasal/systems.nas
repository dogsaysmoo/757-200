# BOEING 757-200 SYSTEMS FILE
#############################

## LIVERY SELECT
################
if (getprop("sim/model/variant") == 3) {
	aircraft.livery.init("Aircraft/757-200/Models/Liveries-300");
} else {
	aircraft.livery.init("Aircraft/757-200/Models/Liveries");
}

## LIGHTS
#########

# create all lights
#var beacon_switch = props.globals.getNode("controls/switches/beacon", 2);
var beacon = aircraft.light.new("sim/model/lights/beacon", [0.05, 2], "controls/lighting/beacon");

#var strobe_switch = props.globals.getNode("controls/switches/strobe", 2);
var strobe = aircraft.light.new("sim/model/lights/strobe", [0.05, 1.3], "controls/lighting/strobe");

var light_stat = {
    new : func {
	m = { parents : [light_stat] };
	
	m.light_controls = props.globals.getNode("controls/lighting",0);

	m.beacon_sw = m.light_controls.getNode("beacon",0);
	m.nav_sw = m.light_controls.getNode("nav-lights",0);
	m.strobe_sw = m.light_controls.getNode("strobe",0);
	m.logo_sw = m.light_controls.getNode("logo-lights",0);
	m.wing_sw = m.light_controls.getNode("wing-lights",1);
	m.taxi_sw = m.light_controls.getNode("taxi-lights",0);
	m.toff_sw = m.light_controls.getNode("turn-off-lights",0);
	m.Lland_sw = m.light_controls.getNode("landing-lights[0]",0);
#	m.Rland_sw = m.light_controls.getNode("landing-lights[2]",0);
	
	m.beacon = props.globals.initNode("systems/electrical/lighting/beacon",0,"BOOL");
	m.nav = props.globals.initNode("systems/electrical/lighting/nav-lights",0,"BOOL");
	m.strobe = props.globals.initNode("systems/electrical/lighting/strobe",0,"BOOL");
	m.logo = props.globals.initNode("systems/electrical/lighting/logo-lights",0,"BOOL");
	m.wing = props.globals.initNode("systems/electrical/lighting/wing-lights",0,"BOOL");
	m.taxi = props.globals.initNode("systems/electrical/lighting/taxi-lights",0,"BOOL");
	m.toff = props.globals.initNode("systems/electrical/lighting/turn-off-lights",0,"BOOL");
	m.Lland = props.globals.initNode("systems/electrical/lighting/landing-lights[0]",0,"BOOL");
	m.Cland = props.globals.initNode("systems/electrical/lighting/landing-lights[1]",0,"BOOL");
#	m.Rland = props.globals.initNode("systems/electrical/lighting/landing-lights[2]",0,"BOOL");

	return m;
    },
    update : func {
	if ((getprop("systems/electrical/left-bus") > 27.5 or getprop("systems/electrical/right-bus") > 27.5) and !getprop("sim/crashed")) {
	    # Beacon:
	    if (me.beacon_sw.getBoolValue() and getprop("sim/model/lights/beacon/state")) {
		me.beacon.setBoolValue(1);
	    } else {
		me.beacon.setBoolValue(0);
	    }
	    # Strobe:
	    if (me.strobe_sw.getBoolValue() and getprop("sim/model/lights/strobe/state")) {
		me.strobe.setBoolValue(1);
	    } else {
		me.strobe.setBoolValue(0);
	    }
	    # Logo lights:
	    if (me.logo_sw.getBoolValue()) {
		me.logo.setBoolValue(1);
	    } else {
		me.logo.setBoolValue(0);
	    }
	    # Wing lights:
	    if (me.wing_sw.getBoolValue()) {
		me.wing.setBoolValue(1);
	    } else {
		me.wing.setBoolValue(0);
	    }
	    # Taxi light:
	    if (me.taxi_sw.getBoolValue() and getprop("gear/gear[0]/position-norm") > 0.99) {
		me.taxi.setBoolValue(1);
	    } else {
		me.taxi.setBoolValue(0);
	    }
	    # Runway turn off lights:
	    if (me.toff_sw.getBoolValue() and getprop("gear/gear[0]/position-norm") > 0.99) {
		me.toff.setBoolValue(1);
	    } else {
		me.toff.setBoolValue(0);
	    }
	    # Left landing light:
	    if (me.Lland_sw.getBoolValue()) {
		me.Lland.setBoolValue(1);
	    } else {
		me.Lland.setBoolValue(0);
	    }
	    # Center landing lights:
	    if (me.Lland_sw.getBoolValue() and getprop("gear/gear[0]/position-norm") > 0.99) {
		me.Cland.setBoolValue(1);
	    } else {
		me.Cland.setBoolValue(0);
	    }
	    # Right landing light:
#	    if (me.Rland_sw.getBoolValue()) {
#		me.Rland.setBoolValue(1);
#	    } else {
#		me.Rland.setBoolValue(0);
#	    }
	} else {
	    me.beacon.setBoolValue(0);
	    me.strobe.setBoolValue(0);
	    me.logo.setBoolValue(0);
	    me.wing.setBoolValue(0);
	    me.taxi.setBoolValue(0);
	    me.toff.setBoolValue(0);
	    me.Lland.setBoolValue(0);
	    me.Cland.setBoolValue(0);
#	    me.Rland.setBoolValue(0);
	}
	if ((getprop("systems/electrical/left-bus") > 22.5 or getprop("systems/electrical/right-bus") > 22.5) and !getprop("sim/crashed")) {
	    # Nav lights:
	    if (me.nav_sw.getBoolValue() and !getprop("sim/crashed")) {
		me.nav.setBoolValue(1);
	    } else {
		me.nav.setBoolValue(0);
	    }
	} else {
	    me.nav.setBoolValue(0);
	}
	if ((me.taxi.getBoolValue() or me.toff.getBoolValue()) and getprop("sim/current-view/internal")) {
	    setprop("sim/rendering/als-secondary-lights/use-landing-light",1);
	    setprop("sim/rendering/als-secondary-lights/landing-light1-offset-deg",2);
	    setprop("sim/rendering/als-secondary-lights/landing-light3-offset-deg",10);
	} else {
	    setprop("sim/rendering/als-secondary-lights/use-landing-light",0);
	}
    },
};
var lighting_status = light_stat.new();
	    
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
		if (getprop("sim/engines") == "RR")
		    setprop(engineOutTree ~ "n3", (2.8 * rpm));
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
	    if (getprop("sim/engines") == "RR")
		setprop(engineOutTree ~ "n3", (1.2 * getprop(engineOutTree ~ "n2")));
	} else {
	    if (getprop(engineOutTree ~ "rpm") > 0) {
		var rpm = getprop(engineOutTree ~ "rpm");
		rpm -= getprop("sim/time/delta-realtime-sec") * 2.5;
		setprop(engineOutTree ~ "rpm", rpm);
		setprop(engineOutTree ~ "n2-ind", (2.5 * rpm));
		if (getprop("sim/engines") == "RR")
		    setprop(engineOutTree ~ "n3", (2.8 * rpm));
	    } else {
		setprop(engineOutTree ~ "rpm", 0);
		setprop(engineOutTree ~ "n2-ind", 0);
		if (getprop("sim/engines") == "RR")
		    setprop(engineOutTree ~ "n3", 0);
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
#var fltctrls = props.globals.getNode("controls/flight",1);
#var ailnctrl = fltctrls.getNode("aileron",1);
#var elevctrl = fltctrls.getNode("elevator",1);
#var rudrctrl = fltctrls.getNode("rudder",1);
#var ailnpos = fltctrls.initNode("aileron-pos",0,"DOUBLE");
#var elevpos = fltctrls.initNode("elevator-pos",0,"DOUBLE");
#var rudrpos = fltctrls.initNode("rudder-pos",0,"DOUBLE");
#
#var set_fltctrls = func {
#    if (getprop("systems/hydraulic/equipment/enable-sfc")) {
#	ailnpos.setValue(ailnctrl.getValue());
#	elevpos.setValue(elevctrl.getValue());
#	rudrpos.setValue(rudrctrl.getValue());
#    }
#    settimer(set_fltctrls,0);
#}

## System updater function, updates each frame
var update_systems = func {
	engineLoop(0);
	engineLoop(1);
	apuLoop();
	lighting_status.update();
#	set_fltctrls();
	settimer(update_systems,0);
}

# start the loop 2 seconds after the FDM initializes
setlistener("sim/signals/fdm-initialized", func {
	props.globals.initNode("engines/engine[0]/n2-ind",0,"DOUBLE");
	props.globals.initNode("engines/engine[1]/n2-ind",0,"DOUBLE");
	if (getprop("sim/engines") == "RR") {
	    props.globals.initNode("engines/engine[0]/n3",0,"DOUBLE");
	    props.globals.initNode("engines/engine[1]/n3",0,"DOUBLE");
	}
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
	setprop("controls/lighting/nav-lights", 1);
	setprop("controls/lighting/beacon", 1);
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
	setprop("controls/inertial-reference/position",2);
	setprop("controls/inertial-reference/position[1]",2);
	setprop("controls/inertial-reference/position[2]",2);
	setprop("systems/inertial-reference/mode",2);
	setprop("systems/inertial-reference/mode[1]",2);
	setprop("systems/inertial-reference/mode[2]",2);
	setprop("systems/inertial-reference/alignment",2);
	setprop("systems/inertial-reference/alignment[1]",2);
	setprop("systems/inertial-reference/alignment[2]",2);

	if (!getprop("gear/gear[0]/wow"))
	    setprop("controls/gear/brake-parking",0);
	

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
		    setprop("controls/pneumatic/packs/pack-knob", 1);
		    setprop("controls/pneumatic/packs/pack-knob[1]", 1);
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
    if (getprop("systems/hydraulic/equipment/enable-flap") and getprop("controls/flight/alt-flaps-pos") == -1) {
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
var altn_flapsDown = func(step) {
    if (step == 0) return;
    if (step < 0 and getprop("controls/flight/alt-flaps-pos") == -1) return;
    if (step > 0 and getprop("controls/flight/alt-flaps-pos") == 6) return;
    setprop("controls/flight/alt-flaps-pos",getprop("controls/flight/alt-flaps-pos") + step);
    if (getprop("controls/flight/alt-flaps-pos") > 0) {
	setprop("controls/flight/alt-flaps",step);
	settimer(func {setprop("controls/flight/alt-flaps",0);}, 0.15);
#	globals.controls.flapsDown(step);
	globals.controls.stepProps("/controls/flight/flaps", "/sim/flaps", step);
    } elsif (getprop("controls/flight/alt-flaps-pos") == 0) {
	while (getprop("controls/flight/flaps") != 0)
	    globals.controls.stepProps("/controls/flight/flaps", "/sim/flaps", -1);
    }
}

## SPEEDBRAKES
##############

setlistener("controls/flight/speedbrake-lever", func (spoiler) {
	if (spoiler.getValue() > 1 and !getprop("systems/hydraulic/equipment/enable-spoil")) setprop("controls/flight/speedbrake-lever",1);
},0,0);

## IRS/INS
##########
var IRS = {
    new : func (n) {
        m = { parents : [IRS] };
        m.position = props.globals.initNode("controls/inertial-reference/position["~n~"]",0,"INT");
        m.mode = props.globals.initNode("systems/inertial-reference/mode["~n~"]",0,"INT");
        m.align = props.globals.initNode("systems/inertial-reference/alignment["~n~"]",0,"INT");
        return m;
    },
    knob : func (chg) {
        var pos = me.position.getValue() + chg;
        if (pos > 3) pos = 3;
        if (pos < 0) pos = 0;
        me.position.setValue(pos);

        var spin_time = 300;
#       if (getprop("systems/inertial-reference/fast")) {
#               spin_time = 5;
#       } elsif (getprop("systems/inertial-reference/slow")) {
#               spin_time = 300;
#       } elsif (getprop("systems/inertial-reference/real")) {
#               spin_time = 780;
#	}

        if (pos == 0) {
                me.mode.setValue(0);
                if (me.align.getValue() == 2) {
                    settimer(func {
                        if (me.mode.getValue() == 0) me.align.setValue(0);
                    },17);
                # spin down time
                } else {
                    me.align.setValue(0);
                }
        }
	if (pos == 1) {
            var tcnt = 0;
            var irs_align = func (spinup) {
                settimer(func {
                    if (me.align.getValue() == 1 and me.position.getValue() != 0 and getprop("controls/gear/brake-parking") and getprop("gear/gear/wow")) {
                        tcnt += 1;
                        if (tcnt >= spinup) {
                            me.align.setValue(2);
                        } else {
                            irs_align(spinup);
                        }
                    } elsif (me.align.getValue() != 2) {
                        me.align.setValue(0);
                    }
                },1);
            }

            if (me.align.getValue() == 0) {
                me.align.setValue(1);
        # spin up time
                irs_align(spin_time);
            } elsif (me.align.getValue() == 2) {
                settimer(func {
                    if (me.mode.getValue() != 0 and me.position.getValue() == 1) {
                        me.align.setValue(1);
        # spin up time (realignment)
                        irs_align(30);
                    } else {
                        me.position.setValue(me.mode.getValue());
                    }
                },1);
            }
        }
        if (pos == 2) {
                me.mode.setValue(2);
        }
        if (pos == 3)
                me.mode.setValue(3);
    }
};
var IRSl = IRS.new(0);
var IRSc = IRS.new(1);
var IRSr = IRS.new(2);

## TRANSPONDER
##############
var xpndr = {
    new : func {
	m = { parents : [xpndr] };
	m.knob = props.globals.initNode("instrumentation/transponder/inputs/knob-pos",0,"INT");
	m.mode = props.globals.getNode("instrumentation/transponder/inputs/knob-mode",1);
#	m.ident = props.globals.getNode("instrumentation/transponder/inputs/ident-btn",1);
	m.squawk = props.globals.getNode("instrumentation/transponder/id-code",1);
	m.digits = [ props.globals.initNode("instrumentation/transponder/inputs/display[0]",0,"INT"),
		     props.globals.initNode("instrumentation/transponder/inputs/display[1]",0,"INT"),
		     props.globals.initNode("instrumentation/transponder/inputs/display[2]",0,"INT"),
		     props.globals.initNode("instrumentation/transponder/inputs/display[3]",0,"INT") ];

	m.d1 = setlistener(m.digits[0], func m.code_update(1),0,0);
	m.d2 = setlistener(m.digits[1], func m.code_update(1),0,0);
	m.d3 = setlistener(m.digits[2], func m.code_update(1),0,0);
	m.d4 = setlistener(m.digits[3], func m.code_update(1),0,0);
	m.d1234 = setlistener(m.squawk, func m.code_update(0),0,0);

	return m;
    },
    update : func {
	if (getprop("/controls/electric/battery-switch")) {
	    if (me.knob.getValue() == 0) me.mode.setValue(1);
	    if (me.knob.getValue() == 1) me.mode.setValue(4);
	    if (me.knob.getValue() == 2) me.mode.setValue(3);
	    if (me.knob.getValue() == 3 or me.knob.getValue() == 4)
		me.mode.setValue(5);
	} else {
	    me.mode.setValue(0);
	}
    },
    ident : func {
	var ident_btn = props.globals.getNode("instrumentation/transponder/inputs/ident-btn",1);
        if (!(ident_btn.getBoolValue())) {
            ident_btn.setBoolValue(1);
            settimer(func { ident_btn.setBoolValue(0); },18);
        }
    },
    code_update : func(n) {
	if (n == 0) {
	    var a = int(int(me.squawk.getValue()) / 1000);
	    var b = int((int(me.squawk.getValue()) - (1000*a)) / 100);
	    var c = int((int(me.squawk.getValue()) - (1000*a) - (100*b)) / 10);
	    var d = int(int(me.squawk.getValue()) - (1000*a) - (100*b) - (10*c));
	    if (a > 7 or a < 0) a = 0;
	    if (b > 7 or b < 0) b = 0;
	    if (c > 7 or c < 0) c = 0;
	    if (d > 7 or d < 0) d = 0;

	    me.digits[0].setValue(a);
	    me.digits[1].setValue(b);
	    me.digits[2].setValue(c);
	    me.digits[3].setValue(d);
	} else {
	    var code = (1000 * me.digits[0].getValue()) + (100 * me.digits[1].getValue()) + (10 * me.digits[2].getValue()) + me.digits[3].getValue();
	    me.squawk.setValue(sprintf ("%04i", code));
	}
    },
};
var transponder = xpndr.new();
settimer(func {
	transponder.update();
	transponder.code_update(0);
},2);
setlistener("/controls/electric/battery-switch", func {
	transponder.update();
},0,0);
setlistener("instrumentation/transponder/inputs/knob-pos", func {
	transponder.update();
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
#setlistener("sim/signals/fdm-initialized", func {
#	settimer(instruments.loop, 2);
#});


## EFIS CONTROLS
################
var modes = ["VOR","APP","MAP","PLAN"];
var ranges = [10,20,40,80,160,320];

var efis = {
    new : func (n) {
	m = { parents : [efis] };

	m.inputs = props.globals.getNode("instrumentation/efis["~n~"]/inputs",1);
	m.mfd = props.globals.getNode("instrumentation/efis["~n~"]/mfd",1);
	m.mode = m.mfd.getNode("display-mode",1);
#	m.ctr = m.inputs.getNode("nd-centered",1);
	m.range = m.inputs.getNode("range",1);
	m.nd_plan_wpt = m.inputs.initNode("plan-wpt-index",0,"INT");
#	m.lh = m.inputs.initNode("lh-vor-adf",1,"INT");
#	m.rh = m.inputs.initNode("rh-vor-adf",1,"INT");

	m.mode_index = 2;
	m.range_index = 0;

	return m;
    },
    mode_adj : func (i) {
	me.mode_index += i;
	if (me.mode_index < 0) me.mode_index = 0;
	if (me.mode_index > 3) me.mode_index = 3;
	
	if (me.mode_index == 3)
	    me.nd_plan_wpt.setValue(getprop("autopilot/route-manager/current-wp"));
	me.mode.setValue(modes[me.mode_index]);
    },
    range_adj : func (i) {
	me.range_index += i;
	if (me.range_index < 0) me.range_index = 0;
	if (me.range_index > 5) me.range_index = 5;

	me.range.setValue(ranges[me.range_index]);
    },
};
var EFIS_l = efis.new(0);
var EFIS_r = efis.new(1);

