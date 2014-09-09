# Airbus A330-200 Doors by Omega Pilot
######################################

var doors =
 {
 new: func(name, transit_time)
  {
  doors[name] = aircraft.door.new("sim/model/door-positions/" ~ name, transit_time);
  },
 toggle: func(name)
  {
  doors[name].toggle();
  },
 open: func(name)
  {
  doors[name].open();
  },
 close: func(name)
  {
  doors[name].close();
  },
 setpos: func(name, value)
  {
  doors[name].setpos(value);
  }
 };
doors.new("toilet1", 1);
doors.new("toilet2", 1);
doors.new("toilet3", 1);
doors.new("toilet4", 1);
doors.new("cockpit-door", 1);
doors.new("toilet5", 1);
doors.new("seat1", 2);
doors.new("seat2", 2);
doors.new("windshield1", 10);
doors.new("windshield2", 10);