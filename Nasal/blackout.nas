###################################################################################
##                                                                               ##
## Improved redout/blackout system for Flightgear                                ##
##                                                                               ##
## Author: Nikolai V. Chr.                                                       ##
##                                                                               ##
## Version 1.0             License: GPL 2.0                                      ##
##                                                                               ##
###################################################################################


var clamp = func(v, min, max) { v < min ? min : v > max ? max : v }

var invert = func (acc) {
	var g_inv = -1 * (acc - 5);
	return g_inv;
}


#
# Customize the values according to the quality of the G-suit the pilot is wearing. The times are in seconds.
#
# According to NASA (1979), this should be the blackout values for generic:
#
# blackout_onset      =   5;
# blackout_fast       =   9;
# blackout_onset_time = 300;
# blackout_fast_time  =  10;
#
# That means at 9G it will take 10 seconds to blackout completely.
# At 5G it will take 300 seconds.
#

var blackout_onset      =    5;
var blackout_fast       =    9;
var redout_onset        = -1.5;
var redout_fast         =   -4;

var blackout_onset_time =  300;
var blackout_fast_time  =   10;
var redout_onset_time   =   45;
var redout_fast_time    =  3.5;

var fast_time_recover   =    7;
var slow_time_recover   =   15;






## Do not modify anything below this line ##

var fdm = "jsb";
var g1_log = math.log10(1);
var blackout_onset_log = math.log10(blackout_onset);
var blackout_fast_log = math.log10(blackout_fast);
var redout_onset_log = math.log10(invert(redout_onset));
var redout_fast_log = math.log10(invert(redout_fast));

var blackout = 0;
var redout   = 0;



var blackout_loop = func {
	setprop("/sim/rendering/redout/enabled", 0);# disable the Fg default redout/blackout system.
	var dt = getprop("sim/time/delta-sec");
	var g = 0;
	if (fdm == "jsb") {
		# JSBSim
		g = getprop("fdm/jsbsim/accelerations/Nz");
	} else {
		# Yasim
		g = getprop("/accelerations/pilot-g[0]");
	}
	if (g == nil) {
		g = 1;
	}

	var g_log = g <= 1?0:math.log10(g);
	if (g < blackout_onset) {
		# reduce blackout

		var curr_time = fast_time_recover + ((g_log - g1_log) / (blackout_onset_log - g1_log)) * (slow_time_recover - fast_time_recover);

		curr_time = clamp(curr_time, 0, 1000);

		blackout -= (1/curr_time)*dt;

		blackout = clamp(blackout, 0, 1);

	} elsif (g >= blackout_onset) {
		# increase blackout

		var curr_time = math.log10(blackout_onset_time) + ((g_log - blackout_onset_log) / (blackout_fast_log - blackout_onset_log)) * (math.log10(blackout_fast_time) - math.log10(blackout_onset_time));

		curr_time = math.pow(10, curr_time);

		curr_time = clamp(curr_time, 0, 1000);

		blackout += (1/curr_time)*dt;

		blackout = clamp(blackout, 0, 1);

	}

	var g_inv = invert (g);
	var g_inv_log = g_inv <= 1?0:math.log10(g_inv);
	if (g > redout_onset) {
		# reduce redout

		var curr_time = fast_time_recover + ((g_inv_log - g1_log) / (redout_onset_log - g1_log)) * (slow_time_recover - fast_time_recover);

		curr_time = clamp(curr_time, 0, 1000);

		redout -= (1/curr_time)*dt;

		redout = clamp(redout, 0, 1);

	} elsif (g <= redout_onset) {
		# increase redout

		var curr_time = math.log10(redout_onset_time) + ((g_inv_log - redout_onset_log) / (redout_fast_log - redout_onset_log)) * (math.log10(redout_fast_time) - math.log10(redout_onset_time));

		curr_time = math.pow(10, curr_time);

		curr_time = clamp(curr_time, 0, 1000);

		redout += (1/curr_time)*dt;

		redout = clamp(redout, 0, 1);

	}

	var sum = blackout - redout;

	if (getprop("/sim/current-view/internal") == 0) {
		# not inside aircraft
		setprop("/sim/rendering/redout/red", 0);
    	setprop("/sim/rendering/redout/alpha", 0);
	} elsif (sum < 0) {
		setprop("/sim/rendering/redout/red", 1);
    	setprop("/sim/rendering/redout/alpha", -1 * sum);
    } else {
    	setprop("/sim/rendering/redout/red", 0);
    	setprop("/sim/rendering/redout/alpha", sum);
    }

    settimer(blackout_loop, 0);
}


var blackout_init = func {
	fdm = getprop("/sim/flight-model");

	blackout_loop();
}



var blackout_init_listener = setlistener("sim/signals/fdm-initialized", func {
	blackout_init();
	removelistener(blackout_init_listener);
}, 0, 0);


var test = func (blackout_onset, blackout_fast, blackout_onset_time, blackout_fast_time) {
	var blackout_onset_log = math.log10(blackout_onset);
	var blackout_fast_log = math.log10(blackout_fast);

	var g = 5;
	print();
	while(g <= 20) {

		var g_log = g <= 1?0:math.log10(g);

		var curr_time = math.log10(blackout_onset_time) + ((g_log - blackout_onset_log) / (blackout_fast_log - blackout_onset_log)) * (math.log10(blackout_fast_time) - math.log10(blackout_onset_time));

		curr_time = math.pow(10, curr_time);

		curr_time = clamp(curr_time, 0, 1000);

		printf("%0.1f, %0.2f", g, curr_time);

		g += .5;
	}
	print();
}