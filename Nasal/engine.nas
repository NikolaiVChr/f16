var jfs_start    = props.globals.initNode("f16/engine/jfs-start-switch", 0, "INT");# -1 = start 1   0 = off  1 = start 2
var cutoff_lever = props.globals.initNode("f16/engine/cutoff-release-lever", 1, "BOOL");#
var jfs_full     = props.globals.initNode("f16/engine/jfs-full-speed", 0, "BOOL");# anim run light
#var accu_1_norm  = props.globals.initNode("f16/engine/jfs-accu-1-charge-normalized", 1, "DOUBLE");# 
#var accu_2_norm  = props.globals.initNode("f16/engine/jfs-accu-2-charge-normalized", 1, "DOUBLE");# 
var jfs_rpm_norm = props.globals.getNode("f16/engine/jfs-rpm-normalized", 0);#
var hyd_b        = props.globals.getNode("fdm/jsbsim/systems/hydraulics/sysb-psi", 0);
var wow          = props.globals.getNode("gear/gear[0]/wow", 0);
var n2           = props.globals.getNode("engines/engine[0]/n2", 0);
var starter      = props.globals.getNode("controls/engines/engine[0]/starter", 0);
var cutoff       = props.globals.getNode("controls/engines/engine[0]/cutoff", 0);
var feed         = props.globals.getNode("f16/engine/feed", 0);
var running      = props.globals.getNode("engines/engine[0]/running", 0);
var fuel         = props.globals.getNode("consumables/fuel/total-fuel-lbs", 0);
var batt         = props.globals.getNode("fdm/jsbsim/elec/bus/batt-1", 0);
var speedUp      = props.globals.getNode("sim/speed-up");


var accu_psi_max = 3000;
var accu_psi_both_max = 2800;
var accu_charge_time_s = 50;
var accu_1_psi = accu_psi_max;
var accu_2_psi = accu_psi_max;
var accu_charge_allowed = 1;
var jfs_spooling = 0;
var jfs_spool_up_time_s = getprop("f16/engine/jfs-spool-up-start1-s");# 30s for 1 accu. Some are clocked to 8s only, some 30.
var jfs_spool_up_time_2_s = getprop("f16/engine/jfs-spool-up-start2-s");
var jfs_spool_down_time_s = 17;
var jfs_n_norm = 0;

var JFS = {
	# and PDF page 384 in block 50 manual
	init: func {
		me.elapsed_last = systime();
		me.start_switch_last = 0;
		me.timer = maketimer(0, me, func {me.loop()});
		me.timer.start();
	},
	
	loop: func {
		me.elapsed = systime();
		me.dt = (me.elapsed - me.elapsed_last)*speedUp.getValue();
		
		me.start_switch = jfs_start.getValue();
		me.wow = wow.getValue();
		me.n2 = n2.getValue();
		
		if (me.wow and me.n2 >= 55) {
			me.start_switch = 0;
			jfs_start.setIntValue(0);
		}
		
		if (me.start_switch != 0 and me.start_switch != me.start_switch_last and batt.getValue() >= 20) {
			if (output_to_console) print("JFS start requested",timesincestart());
			me.psi_for_start = 0;
			if (me.start_switch == 1) {
				if (accu_1_psi == accu_psi_max or accu_2_psi == accu_psi_max or (accu_1_psi >= accu_psi_both_max and accu_2_psi >= accu_psi_both_max)) {
					me.psi_for_start = (accu_1_psi >= accu_psi_both_max and accu_2_psi >= accu_psi_both_max)?2:1;
				}
				accu_1_psi = 0;
				accu_2_psi = 0;
				#print("blow both");
			} else {
				if (accu_1_psi == accu_psi_max) {
					accu_1_psi = 0;
					me.psi_for_start = 1;
					#print("blow 1");
				} elsif (accu_2_psi == accu_psi_max) {
					accu_2_psi = 0;
					me.psi_for_start = 1;
					#print("blow 2");
				}
			}
			if (me.psi_for_start > 0 and jfs_spooling != 1) {
				if (output_to_console) print("Start spooling JFS",timesincestart());
				jfs_spooling = 1;
			}
			accu_charge_allowed = 0;
		} elsif (me.start_switch == 0) {
			if (jfs_n_norm > 0) {
				if (output_to_console and jfs_spooling != -1) print("JFS spooling down",timesincestart());
				jfs_spooling = -1;
			}
		}
		
		if (jfs_spooling == 1 and (jfs_n_norm < 0.4 or fuel.getValue() > 5)) {
			jfs_n_norm += me.dt / (me.psi_for_start==2?jfs_spool_up_time_2_s:jfs_spool_up_time_s);
		} elsif (jfs_spooling == 1) {
			# no fuel to sustain rpm
			if (output_to_console) print("Stop spooling JFS, too little fuel",timesincestart());
			jfs_spooling = -1;
		} elsif (jfs_spooling == -1) {
			jfs_n_norm -= me.dt / jfs_spool_down_time_s;
		}
		if (jfs_n_norm > 1) {
			jfs_spooling = 0;
			jfs_n_norm = 1;
			if (output_to_console) print("JFS full speed",timesincestart());
		} elsif (jfs_n_norm < 0) {
			jfs_spooling = 0;
			jfs_n_norm = 0;
			if (output_to_console) print("JFS at full stop",timesincestart());
		}
		
		
		
		if (me.wow and me.n2 >= 12) {
			accu_charge_allowed = 1;
		} elsif (!me.wow and jfs_n_norm > 0.7) {
			accu_charge_allowed = 1;
		}
		
		if (accu_charge_allowed and accu_1_psi < hyd_b.getValue()) {
			accu_1_psi += me.dt * accu_psi_max/accu_charge_time_s;
			if (accu_1_psi > hyd_b.getValue()) {
				accu_1_psi = hyd_b.getValue();
				#print("accu 1 to "~accu_1_psi);
			}
		}
		if (accu_charge_allowed and accu_2_psi < hyd_b.getValue()) {
			accu_2_psi += me.dt * accu_psi_max/accu_charge_time_s;
			if (accu_2_psi > hyd_b.getValue()) {
				accu_2_psi = hyd_b.getValue();
				#print("accu 2 to "~accu_2_psi);
			}
		}
		
		jfs_full.setBoolValue(jfs_n_norm == 1);
		jfs_rpm_norm.setDoubleValue(jfs_n_norm);
		
		if (!cutoff_lever.getValue() and (feed.getValue() > 0 or running.getValue())) {
			cutoff.setValue(0);
		} else {
			cutoff.setValue(1);
		}
		if (jfs_n_norm == 1) {
			if (output_to_console and starter.getValue() == 0) print("Engine being spooled up to low RPM by JFS",timesincestart());
			starter.setBoolValue(1);
		} elsif (me.n2 >= 55 and !running.getValue() and jfs_spooling == -1) {
			# Engine is self-sustaining and still spooling up
			# Keep the starter on till engine is idle
			starter.setBoolValue(1);
		} else {
			if (output_to_console and starter.getValue() == 1) print("Engine idle or start failed/interupted",timesincestart());
			starter.setBoolValue(0);
		}
		
		me.start_switch_last = me.start_switch;
		me.elapsed_last = me.elapsed;
	},
};

var starttime = 0; #used for timing autostart
var output_to_console = 0;# set this to 1 for startup info in console. It can also be set runtime, do it before hitting the START 1/2 switch for best result.

var timesincestart = func {
	return " ("~int(getprop("sim/time/elapsed-sec")-starttime)~" sec since start)";
}

setlistener("f16/engine/jfs-start-switch", func (node) {
	if (output_to_console and node.getValue() == 1) {
		print("START 2");
		starttime = getprop("sim/time/elapsed-sec");
	} elsif (output_to_console and node.getValue() == -1) {
		print("START 1");
		starttime = getprop("sim/time/elapsed-sec");
	}
});

setlistener("f16/engine/cutoff-release-lever", func (node) {
	if (!output_to_console) return;
	if (node.getValue() == 1) {
		print("Cutoff release lever closed. RPM N1/N2 is "~sprintf("%.2f", getprop("engines/engine[0]/n1"))~"/"~sprintf("%.2f", getprop("engines/engine[0]/n2"))~"%", timesincestart());
	} else {
		print("Cutoff release lever open. RPM N1/N2 is "~sprintf("%.2f", getprop("engines/engine[0]/n1"))~"/"~sprintf("%.2f", getprop("engines/engine[0]/n2"))~"%", timesincestart());
	}
});