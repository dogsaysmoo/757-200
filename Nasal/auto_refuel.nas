var l_auto_refuel = setlistener('/sim/signals/fdm-initialized', func {
    if (!getprop('/autopilot/route-manager/active')) {
        return;
    }

	var range = getprop('/limits/estimated-range-nm');
	var route_len = getprop('/autopilot/route-manager/total-distance');
	var fuel_norm = route_len / range + 0.1;
	if (fuel_norm > 1.0) {
		fuel_norm = 1.0;
	}

	var density = getprop('/consumables/fuel/tank/density-ppg');
	var capacity_wing = (getprop('/consumables/fuel/tank/capacity-gal_us') + getprop('/consumables/fuel/tank[1]/capacity-gal_us')) * density;
	var capacity_center = getprop('/consumables/fuel/tank[2]/capacity-gal_us') * density;
	var refuel_lbs = (capacity_wing + capacity_center) * fuel_norm;
	if (refuel_lbs < capacity_wing) {
		setprop('/consumables/fuel/tank[2]/level-norm', 0);
		setprop('/consumables/fuel/tank/level-lbs', refuel_lbs / 2);
		setprop('/consumables/fuel/tank[1]/level-lbs', refuel_lbs / 2);
	} else {
		setprop('/consumables/fuel/tank/level-norm', 1);
		setprop('/consumables/fuel/tank[1]/level-norm', 1);
		setprop('/consumables/fuel/tank[2]/level-lbs', refuel_lbs - capacity_wing);
	}

    removelistener(l_auto_refuel);
	print('Aircraft refueled.');
});

