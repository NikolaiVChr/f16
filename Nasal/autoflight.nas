# General Dynamics F-16 Autoflight System
# Copyright (c) 2019 Josh Davidson (Octal450)

var max_bank_limit = 20;
setprop("/autopilot/route-manager/advance", 1);

# Calculates the optimum distance from waypoint to begin turning to next waypoint
var apLoop = maketimer(1, func {
	if (getprop("/autopilot/route-manager/route/num") > 0 and getprop("/autopilot/route-manager/active") == 1 and getprop("f16/avionics/power-mmc") and getprop("/autopilot/route-manager/current-wp") != -1) {
		if ((getprop("/autopilot/route-manager/current-wp") + 1) < getprop("/autopilot/route-manager/route/num")) {
			gnds_mps = getprop("/velocities/groundspeed-kt") * KT2MPS;
			wp_fly_from = getprop("/autopilot/route-manager/current-wp");
			if (wp_fly_from < 0) {
				wp_fly_from = 0;
			}
			current_course = getprop("/autopilot/route-manager/route/wp[" ~ wp_fly_from ~ "]/leg-bearing-true-deg");
			wp_fly_to = getprop("/autopilot/route-manager/current-wp") + 1;
			if (wp_fly_to < 0) {
				wp_fly_to = 0;
			}
			next_course = getprop("/autopilot/route-manager/route/wp[" ~ wp_fly_to ~ "]/leg-bearing-true-deg");

			delta_angle = math.abs(geo.normdeg180(current_course - next_course));
			max_bank = delta_angle * 1.5;
			max_bank_limit = getprop("/fdm/jsbsim/autoflight/roll/max-bank-deg");
			if (max_bank > max_bank_limit) {
				max_bank = max_bank_limit;
			}
			radius = (gnds_mps * gnds_mps) / (9.81 * math.tan(max_bank * D2R));
			time = 0.64 * gnds_mps * delta_angle * 0.7 / (360 * math.tan(max_bank * D2R));
			delta_angle_rad = (180 - delta_angle) * D2R * 0.5;
			R = radius/math.sin(delta_angle_rad);
			dist_coeff = delta_angle * -1/90 + 2;
			if (dist_coeff < 1) {
				dist_coeff = 1;
			}
			turn_dist = math.cos(delta_angle_rad) * R * dist_coeff * M2NM;
			if (getprop("/gear/gear[0]/wow") == 1 and turn_dist < 1) {
				turn_dist = 1;
			}
			setprop("/autopilot/route-manager/advance", turn_dist);
			
			if (getprop("/autopilot/route-manager/wp/dist") <= turn_dist) {
				setprop("/autopilot/route-manager/current-wp", getprop("/autopilot/route-manager/current-wp") + 1);
			}
		}
	}
});

# Burn Baby Burn
var start = setlistener("/sim/signals/fdm-initialized", func {
	apLoop.start();
	removelistener(start);
});
