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

			if (getprop("/autopilot/route-manager/wp/dist") <= turn_dist_nm and steerpoints.autoMode) {
				setprop("/autopilot/route-manager/current-wp", getprop("/autopilot/route-manager/current-wp") + 1);
			}
		}
	}
});

var apLoopDelay = maketimer(3, func {
	if (getprop("f16/fcs/adv-mode")) {
		#terr_foll.long_view_avoiding();# set the lookahead time depending on how far from target alt we are
		var agl = getprop("/position/altitude-agl-ft");
		var delay = 14;
		if (agl < 350) {
			delay = 20;
		} elsif (agl < 700) {
			delay = 18;
		} elsif (agl < 1200) {
			delay = 16;
		}
		if (getprop("velocities/groundspeed-kt") < 400) {
			delay += 8;
		} elsif (getprop("velocities/groundspeed-kt") < 550) {
			delay += 4;
		}
		setprop("instrumentation/tfs/delay-big-sec",delay);
	}
});

var apLoopHalf = maketimer(0.5, func {
	# Terrain follow loop
	#print("TF Looping");
	var ready = ready_for_TF();
	var half =50;
	var full = 100;
	var vs = 3000;
	var vsd = -3000;
	var vsg = -7;
	if (!ready) {
		#print("Not ready");
		setprop("f16/fcs/adv-mode", 0);
		setprop("f16/fcs/stby-mode", 0);
		terr_foll.reset_TF_malfunction();
		if (getprop("f16/fcs/adv-mode-sel")) {
			setprop("instrumentation/tfs/aft-not-engaged", 1);
		} else {
			setprop("instrumentation/tfs/aft-not-engaged", 0);
		}
		setprop("fdm/jsbsim/autoflight/pitch/alt/full", full);
    	setprop("fdm/jsbsim/autoflight/pitch/alt/half", half);
    	setprop("fdm/jsbsim/autoflight/pitch/alt/max-vs", vs);
    	setprop("fdm/jsbsim/autoflight/pitch/alt/min-vs", vsd);
    	setprop("fdm/jsbsim/autoflight/pitch/alt/gain-vs", vsg);
    	setprop ("instrumentation/tfs/delay-big-sec", terr_foll.minim_delay);
		return;
	}
	setprop("instrumentation/tfs/aft-not-engaged", 0);
	if (getprop("instrumentation/tfs/malfunction")) {
		setprop("f16/fcs/adv-mode", 0);
		setprop("f16/fcs/stby-mode", 1);
		print("TF failed, will retry");
	}
	if(getprop("f16/fcs/adv-mode-sel") and !getprop("instrumentation/tfs/malfunction") and ready) {

        call(terr_foll.tfs_radar,nil,nil,nil, var myErr= []);
        if(size(myErr)) {
          	foreach(var i ; myErr) {
            	print(i);
        	}
        	setprop("f16/fcs/adv-mode", 0);
			setprop("f16/fcs/stby-mode", 1);
			#print("Error in TF Nasal");
        } else {
        	setprop("f16/fcs/adv-mode", 1);
        	setprop("f16/fcs/stby-mode", 0);
        	full = 1;# the higher the smoother. Max 10. Min 1.
        	half = full * 0.0;
        	vsg  = -11.5-4*getprop("velocities/groundspeed-kt")/600-(getprop("instrumentation/radar/time-till-crash") < 15)*10;
        	vs   = vs + math.min(12500, 4000*getprop("velocities/groundspeed-kt")/400+(4000*getprop("velocities/groundspeed-kt")/400) * (getprop("instrumentation/radar/time-till-crash") < 15));
			vsd  = vsd - math.min(4000, 3500*getprop("velocities/groundspeed-kt")/600);
        	#print("TF working");
        }
    } else {
    	setprop("f16/fcs/adv-mode", 0);
    	setprop("f16/fcs/stby-mode", 1);
    	#print("TF not engaged");
    }
    setprop("fdm/jsbsim/autoflight/pitch/alt/full", full);
    setprop("fdm/jsbsim/autoflight/pitch/alt/half", half);
    setprop("fdm/jsbsim/autoflight/pitch/alt/max-vs", vs);
    setprop("fdm/jsbsim/autoflight/pitch/alt/min-vs", vsd);
    setprop("fdm/jsbsim/autoflight/pitch/alt/gain-vs", vsg);
    aTF_execute();
});

var apLoopFast = maketimer(0.1, func {
	# Steerpoint bearing loop
	 
    if (steerpoints.getCurrentNumber() != 0) {
	  var bearing = steerpoints.getCurrentDirection()[0];
	  if (bearing != nil) {
	      setprop("autopilot/route-manager/custom/bearing-deg", bearing);
	  } else {
	      setprop("autopilot/route-manager/custom/bearing-deg", -1);
	  }
	} else {
		setprop("autopilot/route-manager/custom/bearing-deg", -1);
	}
});

var start = setlistener("/sim/signals/fdm-initialized", func {
	apLoop.start();
	apLoopHalf.start();
	apLoopFast.start();
	apLoopDelay.start();
	autopilot_inhibit.init();
	removelistener(start);
});

var ready_for_TF = func {
	return getprop("/fdm/jsbsim/autoflight/output/pitch-master") and getprop("/fdm/jsbsim/autoflight/switch-pitch") == 1 and getprop("f16/stores/nav-mounted") and getprop("f16/avionics/power-left-hdpt");# and getprop("f16/avionics/power-right-hdpt-warm") >= 1  and getprop("f16/stores/tgp-mounted");
};

var aTF_listen = setlistener("f16/fcs/adv-mode-sel", func {
	if (getprop("f16/fcs/adv-mode-sel") == 1) {
		print("TF requested");
	} else {
		terr_foll.reset_TF_malfunction();
	}
});

var aTF_execute = func {
	# Terrain follow starting
	if (!getprop("f16/fcs/adv-mode")) {
		setprop ("instrumentation/tfs/delay-big-sec", terr_foll.minim_delay);
		return;
	}
	#var target = getprop ("/instrumentation/altimeter/mode-c-alt-ft");
    #target = 100 * int (target / 100 + 0.5);
    #setprop ("/autopilot/settings/target-altitude-ft", target);
    setprop ("/autopilot/settings/target-tf-altitude-ft", getprop("instrumentation/tfs/ground-altitude-ft")+getprop ("/autopilot/settings/tf-minimums")+getprop("instrumentation/tfs/padding"));
    #print("TF sending info to A/P: "~(getprop("instrumentation/tfs/ground-altitude-ft")+getprop ("/autopilot/settings/tf-minimums")));
};

var autopilot_inhibit = {
    # Ref (up to block 40): 1F-16A-1 page 1-133
    # Ref (block 40 and up): GR1F-16CJ-1 page 1-135
    init: func {
        setlistener("/systems/refuel/serviceable", me.evaluate, 0, 0);
        setlistener("/controls/flight/flaps", me.evaluate, 0, 0);
        setlistener("/controls/gear/gear-down", me.evaluate, 0, 0);
        setlistener("/fdm/jsbsim/fcs/fly-by-wire/enable-standby-gains", me.evaluate, 0, 0);
        setlistener("/f16/fcs/trim-ap-disc-switch", me.evaluate, 0, 0);
        setlistener("/autopilot/serviceable", me.evaluate, 0, 0);
        if (getprop("/sim/variant-id") >= 4) {
            # TODO: A/P FAIL PFL occurs
            setlistener("/f16/fcs/autopilot-aoa-limit-exceed", me.evaluate, 0, 0);
            setlistener("/fdm/jsbsim/fcs/fly-by-wire/digital-backup", me.evaluate, 0, 0);
            setlistener("/f16/avionics/low-speed-warning-tone-a", me.evaluate, 0, 0);
            setlistener("/f16/avionics/low-speed-warning-tone-b", me.evaluate, 0, 0);
            setlistener("/fdm/jsbsim/fcs/fbw-override", me.evaluate, 0, 0);
        }
        me.evaluate();
    },

    evaluate: func {
        if (
            getprop("/systems/refuel/serviceable") or
            getprop("/controls/flight/flaps") or
            getprop("/controls/gear/gear-down") or
            getprop("/fdm/jsbsim/fcs/fly-by-wire/enable-standby-gains") or
            getprop("/f16/fcs/trim-ap-disc-switch") or
            !getprop("autopilot/serviceable") or # this makes also A/P FAIL PFL occur
            (
            getprop("/sim/variant-id") >= 4 and
            (            
            getprop("/f16/fcs/autopilot-aoa-limit-exceed") or
            getprop("/fdm/jsbsim/fcs/fly-by-wire/digital-backup") or
            getprop("/f16/avionics/low-speed-warning-tone-a") or
            getprop("/f16/avionics/low-speed-warning-tone-b") or
            getprop("/fdm/jsbsim/fcs/fbw-override")
            )
            )
            ) {
            setprop("/f16/fcs/autopilot-inhibit", 1);
            setprop("/f16/fcs/autopilot-on", 0);
            setprop("/f16/fcs/switch-pitch-block20", 0);
        } else {
            setprop("/f16/fcs/autopilot-inhibit", 0);
        }
    },

    inhibit_check: func {
        if (getprop("/f16/fcs/autopilot-inhibit") == 1) {
            setprop("/f16/fcs/autopilot-on", 0);
            setprop("/f16/fcs/switch-pitch-block20", 0);
        }
    },
};

props.globals.getNode("instrumentation/tfs/malfunction", 1).setBoolValue(0);
props.globals.getNode("instrumentation/tfs/ground-altitude-ft",1).setDoubleValue(20000);
props.globals.getNode("instrumentation/tfs/aft-not-engaged", 1).setBoolValue(0);
props.globals.getNode("instrumentation/tfs/padding", 1).setDoubleValue(0);

return;

screen.property_display.add("f16/fcs/adv-mode-sel");
screen.property_display.add("f16/fcs/adv-mode");
screen.property_display.add("f16/fcs/stby-mode");
screen.property_display.add("instrumentation/tfs/aft-not-engaged");
screen.property_display.add("instrumentation/tfs/malfunction");
screen.property_display.add("instrumentation/tfs/ground-altitude-ft");
screen.property_display.add("instrumentation/tfs/delay-big-sec");
screen.property_display.add("autopilot/settings/target-tf-altitude-ft");
screen.property_display.add("autopilot/settings/tf-minimums");
screen.property_display.add("fdm/jsbsim/autoflight/pitch/alt/error-tf");
screen.property_display.add("fdm/jsbsim/autoflight/pitch/g-demand-switched");
screen.property_display.add("position/altitude-agl-ft");
screen.property_display.add("fdm/jsbsim/autoflight/pitch/alt/max-vs");
screen.property_display.add("instrumentation/gps/indicated-vertical-speed");
screen.property_display.add("instrumentation/tfs/padding");
screen.property_display.add("fdm/jsbsim/autoflight/pitch/alt/gain-vs");