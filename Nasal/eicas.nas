#EICAS
var throttle		= 0;
var radio_alt		= 0;
var flaps			= 0;
var parkbrake		= 0;
var speed			= 0;
var reverser		= 0;
var apu_running		= 0;
var gear_down		= 0;
var gear_override	= 0;
var flap_override	= 0;
var ap_passive		= 1;
var ap_disengaged	= 0;
var rudder_trim		= 0;
var elev_trim		= 0;
var eng1fire		= 0;
var eng2fire		= 0;

msgs_warning = [];
msgs_caution = [];
msgs_advisory = [];
msgs_memo = [];

#props.globals.initNode("/instrumentation/weu/state/stall-speed",-100);
#/instrumentation/fmc/vspeeds/stall-speed

eicas = props.globals.initNode("/instrumentation/eicas");
eicas_msg_warning	= eicas.initNode("msg/warning"," ","STRING");
eicas_msg_caution	= eicas.initNode("msg/caution"," ","STRING");
eicas_msg_advisory	= eicas.initNode("msg/advisory"," ","STRING");
eicas_msg_memo		= eicas.initNode("msg/memo"," ","STRING");

setlistener("sim/signals/fdm-initialized", func() {
	setlistener("controls/gear/gear-down",          func { update_listener_inputs() } );
	setlistener("controls/gear/brake-parking",      func { update_listener_inputs() } );
	setlistener("controls/engines/engine/reverser", func { update_listener_inputs() } );
	setlistener("controls/flight/rudder-trim",      func { update_listener_inputs() } );
	setlistener("controls/flight/elevator-trim",    func { update_listener_inputs() } );
	setlistener("sim/freeze/replay-state",          func { update_listener_inputs() } );
	setlistener("/autopilot/autobrake/step",        func { update_listener_inputs() } );
	setlistener("engines/apu/n1",                   func { update_listener_inputs() } );
	setlistener("controls/engines/engine/throttle", func { update_throttle_input() } );

	update_listener_inputs();
	update_throttle_input();
    update_system();
});

var update_eicas = func(warningmsgs,cautionmsgs,advisorymsgs,memomsgs) {
	var msg="";
	var spacer="";
	for(var i=0; i<size(warningmsgs); i+=1)
	{
		msg = msg ~ warningmsgs[i] ~ "\n";
		spacer = spacer ~ "\n";
	}
	eicas_msg_warning.setValue(msg);
	msg=spacer;
	for(var i=0; i<size(cautionmsgs); i+=1)
	{
		msg = msg ~ cautionmsgs[i] ~ "\n";
		spacer = spacer ~ "\n";
	}
	eicas_msg_caution.setValue(msg);
	msg=spacer;
	for(var i=0; i<size(advisorymsgs); i+=1)
	{
		msg = msg ~ advisorymsgs[i] ~ "\n";
		spacer = spacer ~ "\n";
	}
	eicas_msg_advisory.setValue(msg);
	msg=spacer;
	for(var i=0; i<size(memomsgs); i+=1)
	{
		msg = msg ~ memomsgs[i] ~ "\n";
	}
	eicas_msg_memo.setValue(msg);
}
	
var takeoff_config_warnings = func {
	if ((throttle>=0.667)and
		(!reverser))
	{
		if (((flaps<0.1)or(flaps>0.7)) and (speed < getprop("/instrumentation/fmc/vspeeds/V1")))
			append(msgs_warning," CONFIG FLAPS");
		if (parkbrake)
			append(msgs_warning," CONFIG PARK BRK");
   }
}

var approach_config_warnings = func {
	# approach warnings below 800ft when thrust lever in idle...
	# ... or flaps in landing configuration
	if (((radio_alt<800) and (throttle<0.5)) or (flaps>0.6))
	{
		if (!gear_down)
		{
			append(msgs_alert," CONFIG GEAR");
		}
	 }
}

var warning_messages = func {
	if (eng1fire and eng2fire) {
		append(msgs_warning,"FIRE ENGINE 1, 2");
	} else {
	    if (eng1fire)
		append(msgs_warning,"FIRE ENGINE 1");
	    if (eng2fire)
		append(msgs_warning,"FIRE ENGINE 2");
	}
	if (getprop("systems/pressurization/cabin-altitude-ft") > 10000)
		append(msgs_warning,"CABIN ALTITUDE");
	if (getprop("controls/failures/gear[0]/stuck") or getprop("controls/failures/gear[1]/stuck") or getprop("controls/failures/gear[2]/stuck"))
		append(msgs_warning,"GEAR DISAGREE");
#	if (getprop("gear/brake-thermal-energy") > 1.2)
#            	append(msgs_caution," L R BRAKE OVERHEAT");
}

var caution_messages = func {
	if ((getprop("/consumables/fuel/tank[0]/level-lbs") < 2185) or (getprop("/consumables/fuel/tank[1]/level-lbs") < 2185))
		append(msgs_caution," *FUEL QTY LOW");
	if (getprop("controls/pressurization/valve-manual"))
		append(msgs_caution,"CABIN AUTO INOP");
}

var advisory_messages = func {
	if (getprop("instrumentation/afds/settings/alarm") or getprop("instrumentation/afds/inputs/reset"))
		append(msgs_advisory, " A P DISCONNECT");
	if (math.abs((getprop("/consumables/fuel/tank[0]/level-lbs")-getprop("/consumables/fuel/tank[1]/level-lbs"))) > 2200)
		append(msgs_advisory," *FUEL IMBAL");
	if (math.abs((getprop("/consumables/fuel/tank[0]/level-lbs")-getprop("/consumables/fuel/tank[1]/level-lbs"))) > 1800 or (getprop("consumables/fuel/tank[2]/level-lbs") > 1200 and !getprop("controls/fuel/tank[2]/pump") and getprop("instrumentation/airspeed-indicator/indicated-speed-kt") > 180))
		append(msgs_advisory," FUEL CONFIG");
	if ((getprop("/controls/anti-ice/engine[0]/carb-heat") or getprop("/controls/anti-ice/engine[1]/carb-heat") or getprop("/controls/anti-ice/wing-heat")) and getprop("/environment/temperature-degc") > 12)
		append(msgs_advisory," ANTI-ICE");
	if (!getprop("/controls/electric/battery-switch"))
		append(msgs_advisory," BATTERY OFF");
	if (getprop("/autopilot/route-manager/active") and !(getprop("systems/inertial-reference/alignment") == 2 or getprop("systems/inertial-reference/alignment[1]") == 2 or getprop("systems/inertial-reference/alignment[2]") == 2))
		append(msgs_advisory," IRS ALIGN");
#	if (!(getprop("instrumentation/transponder/inputs/knob-mode") == 5))
#		append(msgs_advisory," *TCAS SYSTEM");
	if (!getprop("/controls/electric/engine[0]/generator"))
		append(msgs_advisory," ELEC GEN OFF 1");
	if (!getprop("/controls/electric/engine[1]/generator"))
		append(msgs_advisory," ELEC GEN OFF 2");
	if (getprop("/systems/hydraulic/system-fault"))
		append(msgs_advisory," HYDR SYS 1");
	if (getprop("/systems/hydraulic/system-fault[1]"))
		append(msgs_advisory," HYDR SYS 2");
	if (getprop("/systems/hydraulic/system-fault[2]"))
		append(msgs_advisory," HYDR SYS 3");
	if (!getprop("controls/pneumatic/eng-bleed"))
		append(msgs_advisory," *BLEED 1 OFF");
	if (!getprop("controls/pneumatic/eng-bleed[1]"))
		append(msgs_advisory," *BLEED 2 OFF");
	if (getprop("engines/engine/rpm") < 19)
		append(msgs_advisory," *ENG SHUTDOWN 1");
	if (getprop("engines/engine[1]/rpm") < 19)
		append(msgs_advisory," *ENG SHUTDOWN 2");
	if (getprop("autopilot/route-manager/active") and (getprop("autopilot/route-manager/route/num") < 2 or getprop("autopilot/route-manager/departure/runway") == ""))
		append(msgs_advisory,"INVALID ROUTE");
	if (getprop("instrumentation/afds/ap-modes/roll-mode") == "LNAV" and !getprop("autopilot/route-manager/active"))
		append(msgs_advisory,"NO ACTIVE ROUTE");
}

var memo_messages = func {
	if (getprop("/controls/engines/con-ignition"))
		append(msgs_memo,"CON IGNITION ON");
	if (getprop("engines/apu/running"))
		append(msgs_memo,"APU RUNNING");
	if (parkbrake)
		append(msgs_memo," PARK BRAKE SET");
	if (getprop("systems/inertial-reference/alignment") == 1)
		append(msgs_memo,"IRS ALIGN MODE L");
	if (getprop("systems/inertial-reference/alignment[1]") == 1)
		append(msgs_memo,"IRS ALIGN MODE C");
	if (getprop("systems/inertial-reference/alignment[2]") == 1)
		append(msgs_memo,"IRS ALIGN MODE R");
	if (reverser)
		append(msgs_memo,"*L R THRUST REV SET");
	if (getprop("/autopilot/autobrake/step") == -2)
		append(msgs_memo,"AUTOBRAKES RTO");
	if (getprop("/autopilot/autobrake/step") == 1)
		append(msgs_memo,"AUTOBRAKES 1");
	if (getprop("/autopilot/autobrake/step") == 2)
		append(msgs_memo,"AUTOBRAKES 2");
	if (getprop("/autopilot/autobrake/step") == 3)
		append(msgs_memo,"AUTOBRAKES 3");
	if (getprop("/autopilot/autobrake/step") == 4)
		append(msgs_memo,"AUTOBRAKES 4");
	if (getprop("/autopilot/autobrake/step") == 5)
		append(msgs_memo,"AUTOBRAKES MAX");
	if (getprop("/controls/switches/seatbelt-sign"))
		append(msgs_memo,"SEATBELTS ON");
		
	if (!getprop("/systems/pneumatic/pack[0]") and !getprop("/systems/pneumatic/pack[1]"))
		append(msgs_memo,"PACKS OFF");
	else {
		if (!getprop("/systems/pneumatic/pack[0]"))
			append(msgs_memo,"PACK 1 OFF");
		if (!getprop("/systems/pneumatic/pack[1]"))
			append(msgs_memo,"PACK 2 OFF");
	}
	if (getprop("/controls/pneumatic/pack-high-flow"))
		append(msgs_memo,"PACKS HIGH FLOW");
}
	
var update_listener_inputs = func() {
	# be nice to sim: some inputs rarely change. use listeners.
	enabled       = (getprop("sim/freeze/replay-state")!=1);
	reverser      = getprop("controls/engines/engine/reverser");
	gear_down     = getprop("controls/gear/gear-down");
	parkbrake     = getprop("controls/gear/brake-parking");
#	apu_running   = getprop("controls/electric/apu");
	apu_running   = getprop("engines/apu/running");
	rudder_trim   = getprop("controls/flight/rudder-trim");
	elev_trim     = getprop("controls/flight/elevator-trim");
	eng1fire      = getprop("controls/engines/engine[0]/on-fire");
	eng2fire      = getprop("controls/engines/engine[1]/on-fire");
}

var update_throttle_input = func() {
	throttle = getprop("controls/engines/engine/throttle");
}
	
var update_system = func() {
	msgs_warning   = [];
	msgs_caution = [];
	msgs_advisory = [];
	msgs_memo    = [];
	
	radio_alt	= getprop("position/altitude-agl-ft");
	speed		= getprop("velocities/airspeed-kt");
	flaps           = getprop("surface-positions/flap-pos-norm");
	
	takeoff_config_warnings();
	warning_messages();
	caution_messages();
	advisory_messages();
	memo_messages();
	
	update_eicas(msgs_warning,msgs_caution,msgs_advisory,msgs_memo);
	
	settimer(update_system,0.5);
}
