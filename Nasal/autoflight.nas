# General Dynamics F-16 Autoflight System
# Copyright (c) 2021 Josh Davidson (Octal450)

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

			if (getprop("/fdm/jsbsim/gear/unit[0]/WOW") == 1 and turn_dist_nm < 1) {
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

var apLoopHalf = maketimer(0.5, func {
	# Terrain follow loop
	var ready = ready_for_TF();
	if (!ready) {
		setprop("f16/fcs/adv-mode", 0);
		setprop("f16/fcs/stby-mode", 0);
		setprop("instrumentation/tfs/malfunction", 0);
		return;
	}
	if (getprop("instrumentation/tfs/malfunction")) {
		setprop("f16/fcs/adv-mode", 0);
		setprop("f16/fcs/stby-mode", ready);
		print("TF failed");
		return;
	}
	if(getprop("f16/fcs/adv-mode-sel") and !getprop("instrumentation/tfs/malfunction") and ready) {
        call(terr_foll.tfs_radar,nil,nil,nil, var myErr= []);
        if(size(myErr)) {
          	foreach(var i ; myErr) {
            	print(i);
        	}
        	setprop("f16/fcs/adv-mode", 0);
			setprop("f16/fcs/stby-mode", 1);
        } else {
        	aTF_execute();
        	setprop("f16/fcs/adv-mode", 1);
        	setprop("f16/fcs/stby-mode", 0);
        }
    } else {
    	setprop("f16/fcs/adv-mode", 0);
    	setprop("f16/fcs/stby-mode", 1);
    }
});

var start = setlistener("/sim/signals/fdm-initialized", func {
	apLoop.start();
	apLoopHalf.start();
	setprop("f16/fcs/adv-mode-sel", 0);
	removelistener(start);
});

var ready_for_TF = func {
	# TODO: check that the TGP is of type LANTIRN
	return getprop("/fdm/jsbsim/autoflight/output/pitch-master") and getprop("/fdm/jsbsim/autoflight/switch-pitch") == 1 and getprop("f16/stores/tgp-mounted") and getprop("f16/stores/nav-mounted") and getprop("sim/variant-id") == 4 and getprop("f16/avionics/power-left-hdpt") and getprop("f16/avionics/power-right-hdpt-warm") >= 1;
};

var aTF_listen = setlistener("f16/fcs/adv-mode-sel", func {
	if (getprop("f16/fcs/adv-mode-sel") == 1) {
		print("TF started");
		aTF_execute();
	} else {
		setprop("instrumentation/tfs/malfunction", 0);
	}
});

var aTF_execute = func {
	# Terrain follow starting
	var target = getprop ("/instrumentation/altimeter/mode-c-alt-ft");
    target = 100 * int (target / 100 + 0.5);
    setprop ("/autopilot/settings/target-altitude-ft", target);
    setprop ("/autopilot/settings/target-tf-altitude-ft", getprop("instrumentation/tfs/ground-altitude-ft")+getprop ("/autopilot/settings/tf-minimums"));
    #print("TF sending info to A/P: "~(getprop("instrumentation/tfs/ground-altitude-ft")+getprop ("/autopilot/settings/tf-minimums")));
};

props.globals.getNode("instrumentation/tfs/malfunction", 1).setBoolValue(0);
props.globals.getNode("instrumentation/tfs/ground-altitude-ft",1).setDoubleValue(20000);

#screen.property_display.add("f16/fcs/adv-mode-sel");
#screen.property_display.add("f16/fcs/adv-mode");
#screen.property_display.add("f16/fcs/stby-mode");
#screen.property_display.add("instrumentation/tfs/malfunction");
#screen.property_display.add("instrumentation/tfs/ground-altitude-ft");
#screen.property_display.add("autopilot/settings/target-tf-altitude-ft");
#screen.property_display.add("autopilot/settings/tf-minimums");
#screen.property_display.add("fdm/jsbsim/autoflight/pitch/alt/error-tf");