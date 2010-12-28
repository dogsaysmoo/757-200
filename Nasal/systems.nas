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
setlistener("controls/switches/seatbelt-sign", func
 {
 props.globals.getNode("sim/sound/seatbelt-sign").setBoolValue(1);

 settimer(func
  {
  props.globals.getNode("sim/sound/seatbelt-sign").setBoolValue(0);
  }, 2);
 });
setlistener("controls/switches/no-smoking-sign", func
 {
 props.globals.getNode("sim/sound/no-smoking-sign").setBoolValue(1);

 settimer(func
  {
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

# main loop function
var engineLoop = func(engine_no)
 {
 # control the throttles and main engine properties
 var engineCtlTree = "controls/engines/engine[" ~ engine_no ~ "]/";
 var engineOutTree = "engines/engine[" ~ engine_no ~ "]/";

 # the FDM switches the running property to true automatically if the cutoff is set to false, this is unwanted
 if (props.globals.getNode(engineOutTree ~ "running").getBoolValue() and !props.globals.getNode(engineOutTree ~ "started").getBoolValue())
  {
  props.globals.getNode(engineOutTree ~ "running").setBoolValue(0);
  }

 if (props.globals.getNode(engineOutTree ~ "on-fire").getBoolValue())
  {
  props.globals.getNode(engineOutTree ~ "failed").setBoolValue(1);
  }
 if (props.globals.getNode(engineCtlTree ~ "cutoff").getBoolValue() or props.globals.getNode(engineOutTree ~ "failed").getBoolValue() or props.globals.getNode(engineOutTree ~ "out-of-fuel").getBoolValue())
  {
  if (getprop(engineOutTree ~ "rpm") > 0)
   {
   var rpm = getprop(engineOutTree ~ "rpm");
   rpm -= getprop("sim/time/delta-realtime-sec") * 2.5;
   setprop(engineOutTree ~ "rpm", rpm);
   }
  else
   {
   setprop(engineOutTree ~ "rpm", 0);
   }

  props.globals.getNode(engineOutTree ~ "running").setBoolValue(0);
  props.globals.getNode(engineOutTree ~ "started").setBoolValue(0);
  setprop(engineCtlTree ~ "throttle-lever", 0);
  }
 elsif (props.globals.getNode(engineCtlTree ~ "starter").getBoolValue())
  {
  props.globals.getNode(engineCtlTree ~ "cutoff").setBoolValue(0);

  var rpm = getprop(engineOutTree ~ "rpm");
  rpm += getprop("sim/time/delta-realtime-sec") * 3.0;
  setprop(engineOutTree ~ "rpm", rpm);

  if (rpm >= getprop(engineOutTree ~ "n1"))
   {
   props.globals.getNode(engineCtlTree ~ "starter").setBoolValue(0);
   props.globals.getNode(engineOutTree ~ "started").setBoolValue(1);
   props.globals.getNode(engineOutTree ~ "running").setBoolValue(1);
   }
  else
   {
   props.globals.getNode(engineOutTree ~ "running").setBoolValue(0);
   }
  }
 elsif (props.globals.getNode(engineOutTree ~ "running").getBoolValue())
  {
  if (getprop("autopilot/settings/speed") == "speed-to-ga")
   {
   setprop(engineCtlTree ~ "throttle-lever", 1);
   }
  else
   {
   setprop(engineCtlTree ~ "throttle-lever", getprop(engineCtlTree ~ "throttle"));
   }

  setprop(engineOutTree ~ "rpm", getprop(engineOutTree ~ "n1"));
  }

 settimer(func
  {
  engineLoop(engine_no);
  }, 0);
 };
# start the loop 2 seconds after the FDM initializes
setlistener("sim/signals/fdm-initialized", func
 {
 settimer(func
  {
  engineLoop(0);
  engineLoop(1);
  }, 2);
 });

# startup/shutdown functions
var startup = func
 {
 setprop("controls/engines/engine[0]/cutoff", 0);
 setprop("controls/engines/engine[1]/cutoff", 0);
 setprop("engines/engine[0]/started", 1);
 setprop("engines/engine[1]/started", 1);
# setprop("controls/engines/engine[0]/starter", 1);
# setprop("controls/engines/engine[1]/starter", 1);
 setprop("controls/electric/avionics-switch", 1);
 setprop("controls/electric/battery-switch", 1);
 };
var shutdown = func
 {
 setprop("controls/engines/engine[0]/cutoff", 1);
 setprop("controls/engines/engine[1]/cutoff", 1);
 setprop("controls/electric/avionics-switch", 0);
 setprop("controls/electric/battery-switch", 0);
 };

# listener to activate these functions accordingly
setlistener("sim/model/start-idling", func(idle)
 {
 var run = idle.getBoolValue();
 if (run)
  {
  startup();
  }
 else
  {
  shutdown();
  }
 }, 0, 0);

## GEAR
#######

# prevent retraction of the landing gear when any of the wheels are compressed
setlistener("controls/gear/gear-down", func
 {
 var down = props.globals.getNode("controls/gear/gear-down").getBoolValue();
 if (!down and (getprop("gear/gear[0]/wow") or getprop("gear/gear[1]/wow") or getprop("gear/gear[2]/wow")))
  {
  props.globals.getNode("controls/gear/gear-down").setBoolValue(1);
  }
 });

## INSTRUMENTS
##############

var instruments =
 {
 loop: func
  {
  instruments.setHSIBugsDeg();

  settimer(instruments.loop, 0);
  },
 # set the rotation of the HSI bugs
 setHSIBugsDeg: func
  {
  var calcBugDeg = func(bug)
   {
   var heading = getprop("orientation/heading-magnetic-deg");
   var bugDeg = 0;

   while (bug < 0)
    {
    bug += 360;
    }
   while (bug > 360)
    {
    bug -= 360;
    }
   if (bug < 32)
    {
    bug += 360;
    }
   if (heading < 32)
    {
    heading += 360;
    }
   # bug is adjusted normally
   if (math.abs(heading - bug) < 32)
    {
    bugDeg = heading - bug;
    }
   elsif (heading - bug < 0)
    {
    # bug is on the far right
    if (math.abs(heading - bug + 360 >= 180))
     {
     bugDeg = -32;
     }
    # bug is on the far left
    elsif (math.abs(heading - bug + 360 < 180))
     {
     bugDeg = 32;
     }
    }
   else
    {
    # bug is on the far right
    if (math.abs(heading - bug >= 180))
     {
     bugDeg = -32;
     }
    # bug is on the far left
    elsif (math.abs(heading - bug < 180))
     {
     bugDeg = 32;
     }
    }

   return bugDeg;
   };
  setprop("sim/model/B757/heading-bug-deg", calcBugDeg(getprop("autopilot/settings/heading-bug-deg")));
  setprop("sim/model/B757/nav1-track-deg", calcBugDeg(getprop("instrumentation/nav[0]/radials/selected-deg")));
  setprop("sim/model/B757/nav1-bug-deg", calcBugDeg(getprop("instrumentation/nav[0]/heading-deg")));
  setprop("sim/model/B757/nav2-bug-deg", calcBugDeg(getprop("instrumentation/nav[1]/heading-deg")));
  setprop("sim/model/B757/adf-bug-deg", calcBugDeg(getprop("instrumentation/adf/indicated-bearing-deg")));
  }
 };
# start the loop 2 seconds after the FDM initializes
setlistener("sim/signals/fdm-initialized", func
 {
 settimer(instruments.loop, 2);
 });

## AUTOBRAKES/SPEEDBRAKES
#########################

# autobrake setting listener
setlistener("autopilot/autobrake/step", func
 {
 var setting = getprop("autopilot/autobrake/step");
 if (setting == -2)
  {
  gui.popupTip("Autobrakes set to RTO.");
  }
 elsif (setting == -1)
  {
  gui.popupTip("Autobrakes off.");
  }
 elsif (setting == 0)
  {
  gui.popupTip("Autobrakes disarmed.");
  }
 elsif (setting == 1)
  {
  gui.popupTip("Autobrakes set to 1.");
  }
 elsif (setting == 2)
  {
  gui.popupTip("Autobrakes set to 2.");
  }
 elsif (setting == 3)
  {
  gui.popupTip("Autobrakes set to 3.");
  }
 elsif (setting == 4)
  {
  gui.popupTip("Autobrakes set to 4.");
  }
 elsif (setting == 5)
  {
  gui.popupTip("Autobrakes set to maximum power.");
  }
 }, 0, 0);

# function to deploy speedbrakes on touchdown
var speedbrakes =
 {
 inair: "false",
 landed: "false",
 loop: func
  {
  # set in air/landed values
  if (speedbrakes.inair == "true" and getprop("gear/gear[1]/wow") == 1)
   {
   speedbrakes.inair = "false";
   speedbrakes.landed = "true";
   }
  if (speedbrakes.inair == "false" and getprop("gear/gear[1]/wow") == 0)
   {
   speedbrakes.inair = "true";
   speedbrakes.landed = "false";
   }

  if (props.globals.getNode("autopilot/autobrake/engaged").getBoolValue() and props.globals.getNode("autopilot/autobrake/rto-selected").getBoolValue())
   {
   setprop("controls/flight/speedbrake-lever", 2);
   }
  if (speedbrakes.landed == "true" and getprop("controls/flight/speedbrake-lever") == 1)
   {
   setprop("controls/flight/speedbrake-lever", 2);

   speedbrakes.landed = "false";
   }
  if (getprop("velocities/groundspeed-kt") < 60)
   {
   speedbrakes.landed = "false";
   }

  # rerun after 1/5 of a second
  settimer(speedbrakes.loop, 0.2);
  }
 };
# start the loop 2 seconds after the FDM initializes
setlistener("sim/signals/fdm-initialized", func
 {
 settimer(speedbrakes.loop, 2);
 });

# speedbrake setting listener
setlistener("controls/flight/speedbrake-lever", func
 {
 var setting = getprop("controls/flight/speedbrake-lever");
 if (setting == 0)
  {
  gui.popupTip("Speedbrakes retracted.");
  setprop("controls/flight/speedbrake", 0);
  }
 elsif (setting == 1)
  {
  gui.popupTip("Speedbrakes armed to deploy on touchdown.");
  }
 elsif (setting == 2)
  {
  gui.popupTip("Speedbrakes deployed.");
  setprop("controls/flight/speedbrake", 1);
  }
 }, 0, 0);

## AUTOPILOT
############

# flight director pitch/roll computer
var flightDirectorLoop = func
 {
 var apPitch = getprop("autopilot/internal/target-pitch-deg");
 var acPitch = getprop("orientation/pitch-deg");
 if (apPitch and acPitch)
  {
  setprop("autopilot/internal/flight-director-pitch-deg", apPitch - acPitch);
  }

 var apRoll = getprop("autopilot/internal/target-roll-deg");
 var acRoll = getprop("orientation/roll-deg");
 if (apRoll and acRoll)
  {
  setprop("autopilot/internal/flight-director-roll-deg", apRoll - acRoll);
  }

 settimer(flightDirectorLoop, 0.05);
 };
# start the loop 2 seconds after the FDM initializes
setlistener("sim/signals/fdm-initialized", func
 {
 settimer(flightDirectorLoop, 2);
 });
