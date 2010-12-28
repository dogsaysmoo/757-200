# generic reverse thrust activation script for autostart-equipped YASim aircraft
# prohibits activation unless throttles are idle and the landing gears are compressed

var togglereverser = func
 {
 var reversing = props.globals.getNode("controls/engines/engine[0]/reverser").getBoolValue();
 if (reversing)
  {
  props.globals.getNode("controls/engines/engine[0]/reverser").setBoolValue(0);
  props.globals.getNode("controls/engines/engine[1]/reverser").setBoolValue(0);
  }
 elsif (getprop("controls/engines/engine[0]/throttle") == 0 and getprop("controls/engines/engine[1]/throttle") == 0 and props.globals.getNode("gear/gear[1]/wow").getBoolValue())
  {
  props.globals.getNode("controls/engines/engine[0]/reverser").setBoolValue(1);
  props.globals.getNode("controls/engines/engine[1]/reverser").setBoolValue(1);
  }
 };
