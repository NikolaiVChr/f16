var jfs_start    = props.globals.initNode("f16/engine/jfs-start-switch", 0, "INT");# -1 = start 1   0 = off  1 = start 2
var cutoff_lever = props.globals.initNode("f16/engine/cutoff-release-lever", 1, "BOOL");#
var jfs_full     = props.globals.initNode("f16/engine/jfs-full-speed", 0, "BOOL");# anim run light
#var accu_1_norm  = props.globals.initNode("f16/engine/jfs-accu-1-charge-normalized", 1, "DOUBLE");# 
#var accu_2_norm  = props.globals.initNode("f16/engine/jfs-accu-2-charge-normalized", 1, "DOUBLE");# 
var jfs_rpm_norm = props.globals.initNode("f16/engine/jfs-rpm-normalized", 0, "DOUBLE");#
var hyd_b        = props.globals.getNode("fdm/jsbsim/systems/hydraulics/sysb-psi", 0);
var wow          = props.globals.getNode("gear/gear[0]/wow", 0);
var n2           = props.globals.getNode("engines/engine[0]/n2", 0);
var starter      = props.globals.getNode("controls/engines/engine[0]/starter", 0);
var cutoff       = props.globals.getNode("controls/engines/engine[0]/cutoff", 0);
var feed         = props.globals.getNode("f16/engine/feed", 0);
var running      = props.globals.getNode("engines/engine[0]/running", 0);
var fuel         = props.globals.getNode("consumables/fuel/total-fuel-lbs", 0);

var accu_psi_max = 3000;
var accu_psi_both_max = 2800;
var accu_charge_time_s = 50;
var accu_1_psi = accu_psi_max;
var accu_2_psi = accu_psi_max;
var accu_charge_allowed = 1;
var jfs_spooling = 0;
var jfs_spool_up_time_s = 30;
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
		me.dt = me.elapsed - me.elapsed_last;
		
		me.start_switch = jfs_start.getValue();
		me.wow = wow.getValue();
		me.n2 = n2.getValue();
		
		if (me.wow and me.n2 >= 55) {
			me.start_switch = 0;
			jfs_start.setIntValue(0);
		}
		
		if (me.start_switch != 0 and me.start_switch != me.start_switch_last) {
			#print("JFS start requested");
			me.psi_for_start = 0;
			if (me.start_switch == 1) {
				if (accu_1_psi == accu_psi_max or accu_2_psi == accu_psi_max or (accu_1_psi >= accu_psi_both_max and accu_2_psi >= accu_psi_both_max)) {
					me.psi_for_start = 1;
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
			if (me.psi_for_start and jfs_spooling != 1) {
				jfs_spooling = 1;
			}
			accu_charge_allowed = 0;
		} elsif (me.start_switch == 0) {
			if (jfs_n_norm > 0) {
				jfs_spooling = -1;
			}
		}
		
		if (jfs_spooling == 1 and (jfs_n_norm < 0.4 or fuel.getValue() > 5)) {
			jfs_n_norm += me.dt / jfs_spool_up_time_s;
		} elsif (jfs_spooling == 1) {
			# no fuel to sustain rpm
			jfs_spooling = -1;
		} elsif (jfs_spooling == -1) {
			jfs_n_norm -= me.dt / jfs_spool_down_time_s;
		}
		if (jfs_n_norm > 1) {
			jfs_spooling = 0;
			jfs_n_norm = 1;
			#print("JFS full speed");
		} elsif (jfs_n_norm < 0) {
			jfs_spooling = 0;
			jfs_n_norm = 0;
			#print("JFS stopped");
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
		
		if (!cutoff_lever.getValue() and feed.getValue()) {
			cutoff.setValue(0);
		} else {
			cutoff.setValue(1);
		}
		if (jfs_n_norm == 1 or (me.n2 >= 55 and !running.getValue() and jfs_spooling == -1)) {
			starter.setBoolValue(1);
		} else {
			starter.setBoolValue(0);
		}
		
		me.start_switch_last = me.start_switch;
		me.elapsed_last = me.elapsed;
	},
};

