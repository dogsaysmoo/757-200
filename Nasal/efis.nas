# A script to run the EFIS controls

var modes = ["APP","VOR","MAP","PLAN"];
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


