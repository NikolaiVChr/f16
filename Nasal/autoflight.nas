# General Dynamics F-16 Autoflight System
# Copyright (c) 2019 Josh Davidson (Octal450)

setprop("/autopilot/route-manager/advance", 1);

# Calculates the optimum distance from waypoint to begin turning to next waypoint
var apLoop = maketimer(1, func {
	if (getprop("/autopilot/route-manager/route/num") > 0 and getprop("/autopilot/route-manager/active") == 1 and getprop("f16/avionics/power-mmc") and getprop("/autopilot/route-manager/current-wp") != -1) {
		if ((getprop("/autopilot/route-manager/current-wp") + 1) < getprop("/autopilot/route-manager/route/num")) {
			var gnds_kt = getprop("/velocities/groundspeed-kt");
			var max_wp   = getprop("/autopilot/route-manager/route/num"); 
			var current_course = getprop("/autopilot/route-manager/wp/true-bearing-deg");
			var wp_fly_to = getprop("/autopilot/route-manager/current-wp") + 1;
			if (wp_fly_to < 0) {
				wp_fly_to = 0;
			}
			var next_course = getprop("/autopilot/route-manager/route/wp[" ~ wp_fly_to ~ "]/leg-bearing-true-deg");
			var delta_angle = math.abs(geo.normdeg180(current_course - next_course));
			var roll = getprop("fdm/jsbsim/autoflight/output/roll-master");
			var strg = roll * (getprop("fdm/jsbsim/autoflight/switch-roll") == -1);
			var turn_dist_nm = delta_angle*delta_angle*0.0005*(strg?8:1)*gnds_kt/400;

			if (getprop("/gear/gear[0]/wow") == 1 and turn_dist_nm < 1) {
				turn_dist_nm = 1;
			}
			if (turn_dist_nm < 0.25) {
				turn_dist_nm = 0.25;
			}
			if (turn_dist_nm > 5) {
				turn_dist_nm = 5;
			}

			setprop("/autopilot/route-manager/advance", turn_dist_nm);
			
			if (getprop("/autopilot/route-manager/wp/dist") <= turn_dist_nm) {
				setprop("/autopilot/route-manager/current-wp", getprop("/autopilot/route-manager/current-wp") + 1);
			}
		}
	}
});

var start = setlistener("/sim/signals/fdm-initialized", func {
	apLoop.start();
	removelistener(start);
});