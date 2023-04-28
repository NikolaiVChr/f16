#
#   State and autostart (and repair and reinit management)

var enableViews = func {
  setprop("sim/view[101]/enabled",1);# Missile view
  setprop("sim/view[102]/enabled",1);# GoPro #1 View
  setprop("sim/view[103]/enabled",1);# GoPro #2 View
  setprop("sim/view[104]/enabled",1);# GoPro #3 View
  setprop("sim/view[105]/enabled",0);# TGP
}

###################################################################################################
# REPAIR
###################################################################################################

var inAutostart = 0;

var repair = func {
  #
  # Called from GUI dialog
  #
  if (getprop("payload/armament/msg")==1 and !getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
    screen.log.write(f16.msgA);
  } else {
    repair2();
  }
}

var repair2 = func {
  setprop("f16/ejected",0);
  setprop("f16/chute/done",0);
  setprop("sim/view[0]/enabled",1);
  setprop("sim/current-view/view-number",0);
  setprop("f16/cockpit/hydrazine-minutes", 10);
  setprop("f16/cockpit/oxygen-liters", 5);
  setprop("f16/cockpit/alt-gear-pneu",1);
  setprop("canopy/not-serviceable", 0);
  
  if (inAutostart) {
    return;
  }
  inAutostart = 1;
  screen.log.write("Repairing, standby..");
  f16.reloadCannon();
  f16.reloadHydras();
  eng.accu_1_psi = eng.accu_psi_max;
  eng.accu_2_psi = eng.accu_psi_max;
  crash.repair();
  fail.trigger_eng.arm();
  
  if (0 and getprop("f16/engine/running-state")) {
    # f16/engine/running-state is what the pilot originally chose from the FG launcher.
    setprop("fdm/jsbsim/elec/switches/epu",1);
    setprop("fdm/jsbsim/elec/switches/epu-cover",0);
    setprop("fdm/jsbsim/elec/switches/main-pwr",2);
    if (getprop("engines/engine[0]/running")!=1) {
      # engine is not running, lets attempt to start it
      setprop("f16/engine/feed",1);
      setprop("f16/engine/cutoff-release-lever",1);
      if (getprop("/fdm/jsbsim/gear/unit[0]/WOW")) {
        setprop("f16/engine/jfs-start-switch",1);# If airborne while doing this, maybe should set this to -1 (START 1) instead. And only to 1 (START 2) if on ground WOW.
      } else {
        setprop("f16/engine/jfs-start-switch",-1);# If airborne while doing this, maybe should set this to -1 (START 1) instead. And only to 1 (START 2) if on ground WOW.
      }
      settimer(repair3, 35);# Needs to allow time to: Spool up JFS and Spool up engine
    } else {
      # Engine is running, lets exit.
      screen.log.write("Done.");
      inAutostart = 0;
    }
  } else {
    screen.log.write("Done.");
    inAutostart = 0;
  }
}

var repair3 = func {
  setprop("f16/engine/cutoff-release-lever", 0);
  screen.log.write("Attempting engine start, standby for engine..");
  inAutostart = 0;
}

var repair4 = func {
  # this pps settings is for when reinit with non zero fuel dump value in jsb propulsion, that value gets set on non-mounted tanks.
    setprop("fdm/jsbsim/propulsion/tank[0]/external-flow-rate-pps", 0);
    setprop("fdm/jsbsim/propulsion/tank[1]/external-flow-rate-pps", 0);
    setprop("fdm/jsbsim/propulsion/tank[2]/external-flow-rate-pps", 0);
    setprop("fdm/jsbsim/propulsion/tank[3]/external-flow-rate-pps", 0);
    setprop("fdm/jsbsim/propulsion/tank[4]/external-flow-rate-pps", 0);
    setprop("fdm/jsbsim/propulsion/tank[5]/external-flow-rate-pps", 0);
    if (getprop("/consumables/fuel/tank[6]/name") != "Not attached") {
      setprop("fdm/jsbsim/propulsion/tank[6]/external-flow-rate-pps", 0);
    }
    if (getprop("/consumables/fuel/tank[7]/name") != "Not attached") {
      setprop("fdm/jsbsim/propulsion/tank[7]/external-flow-rate-pps", 0);
    }
    if (getprop("/consumables/fuel/tank[8]/name") != "Not attached") {
      setprop("fdm/jsbsim/propulsion/tank[8]/external-flow-rate-pps", 0);
    }
    if (getprop("/consumables/fuel/tank[4]/level-norm")<0.5 and getprop("f16/engine/running-state")) {
      setprop("/consumables/fuel/tank[4]/level-norm", 0.55);
    }
}

###################################################################################################
# AUTOSTART
###################################################################################################

var autostart = func {
  #
  # Called from GUI dialog
  #
  if (inAutostart) {
    return;
  }
  inAutostart = 1;
  screen.log.write("Starting, standby..");

  # If on the ground put in the EPU pin
  if (getprop("/fdm/jsbsim/gear/unit[0]/WOW")) {
    setprop("fdm/jsbsim/elec/switches/epu-pin",1);
  }

  setprop("fdm/jsbsim/elec/switches/master-fuel-cmd",1);
  setprop("f16/engine/feed",1);
  setprop("fdm/jsbsim/elec/switches/epu",1);
  setprop("fdm/jsbsim/elec/switches/epu-cover",0);
  setprop("controls/ventilation/airconditioning-enabled",1);
  setprop("controls/ventilation/airconditioning-source",1);
  setprop("f16/avionics/pbg-switch",0);
  
  # See if the engine is already running, then we can skip this part
  if (getprop("engines/engine[0]/running") == 1) {
      autostartengine();
      return;
  }

  setprop("f16/engine/cutoff-release-lever",1);
  
  setprop("fdm/jsbsim/elec/switches/main-pwr",1);

  eng.JFS.start_switch_last = 0; # bypass check for switch was in OFF

  if (getprop("/fdm/jsbsim/gear/unit[0]/WOW") and !(eng.accu_1_psi == eng.accu_psi_max or eng.accu_2_psi == eng.accu_psi_max or (eng.accu_1_psi >= eng.accu_psi_both_max and eng.accu_2_psi >= eng.accu_psi_both_max))) {
      screen.log.write("Both JFS accumulators de-pressurized. Engine start aborted.");
      print("Both JFS accumulators de-pressurized. Auto engine start aborted.");
      print("Menu->F-16->Config to fill them up again.");
      inAutostart = 0;
      return;
  } elsif  (!getprop("/fdm/jsbsim/gear/unit[0]/WOW") and eng.accu_1_psi < eng.accu_psi_max and eng.accu_2_psi < eng.accu_psi_max) {
      screen.log.write("Both JFS accumulators de-pressurized. Engine start aborted.");
      print("Both JFS accumulators de-pressurized. Auto engine start aborted.");
      print("Menu->F-16->Config to fill them up again. Or wait for Hydraulic-B system to do it.");
      inAutostart = 0;
      return;
  }

  setprop("fdm/jsbsim/elec/switches/main-pwr",2);

  # Wait a second for the elec bus to stabilize
  settimer(autostartelec, 1);
}

var autostartelec = func {
  if (getprop("/fdm/jsbsim/gear/unit[0]/WOW")) {
    setprop("f16/engine/jfs-start-switch",1);# Only to 1 (START 2) if on ground WOW.
  } else {
    setprop("f16/engine/jfs-start-switch",-1);# If airborne while doing this, set to -1 (START 1) instead.
  }

  # Wait for the JFS to spool up
  autostart_watchdog.restart(55);
  autostart_jfs.start();
}

var autostartjfs = func {
  # Wait for 20% core speed
  if (getprop("engines/engine[0]/n2") < 20)
    return;

  # Check f16/avionics/caution/sec too?
    
  autostart_jfs.stop();

  setprop("f16/engine/cutoff-release-lever",0);

  # Wait for the engine to spool up
  autostart_watchdog.restart(30);
  autostart_engine.start();
}

var autostartengine = func {
  # Wait for engine to run
  if (getprop("engines/engine[0]/running") != 1)
    return;

  autostart_engine.stop();

  autostart_watchdog.stop();

  # Make sure power is set to main and EPU is not inhibited
  setprop("fdm/jsbsim/elec/switches/main-pwr",2);
  setprop("fdm/jsbsim/elec/switches/epu-pin",0);

  setprop("f16/avionics/power-mmc",1);
  setprop("f16/avionics/power-st-sta",1);
  setprop("f16/avionics/power-mfd",1);
  setprop("f16/avionics/power-ufc",1);
  setprop("f16/avionics/power-gps",1);
  setprop("f16/avionics/power-dl",1);

  setprop("f16/avionics/ins-knob", 2); #ALIGN NORM

  setprop("f16/avionics/power-rdr-alt",2);
  setprop("f16/avionics/power-fcr",1);
  setprop("f16/avionics/power-right-hdpt",1);
  setprop("f16/avionics/power-left-hdpt",1);

  setprop("f16/avionics/hud-sym", 1);
  setprop("f16/avionics/hud-brt", 0);

  setprop("f16/avionics/ew-mws-switch",1);
  setprop("f16/avionics/ew-jmr-switch",1);
  setprop("f16/avionics/ew-rwr-switch",1);
  setprop("f16/avionics/ew-disp-switch",1);
  setprop("f16/avionics/ew-mode-knob",1);
  setprop("f16/avionics/cmds-01-switch",1);
  setprop("f16/avionics/cmds-02-switch",1);
  setprop("f16/avionics/cmds-ch-switch",1);
  setprop("f16/avionics/cmds-fl-switch",1);

  setprop("controls/lighting/ext-lighting-panel/form-knob", 1);
  setprop("controls/lighting/ext-lighting-panel/master", 1);

  setprop("controls/lighting/lighting-panel/console-flood-knob", 0.3);
  setprop("controls/lighting/lighting-panel/pri-inst-pnl-knob", 0.5);
  setprop("controls/lighting/lighting-panel/flood-inst-pnl-knob", 0.2);
  setprop("controls/lighting/lighting-panel/console-primary-knob", 0.3);
  setprop("controls/lighting/lighting-panel/data-entry-display", 1.0);
  
  setprop("controls/test/test-panel/oxy-test", 0);

  setprop("instrumentation/radar/radar-enable", 1);
  setprop("instrumentation/comm[0]/volume",1);
  setprop("instrumentation/comm[1]/volume",1);

  setprop("fdm/jsbsim/fcs/canopy-engage", 0);
  setprop("controls/seat/ejection-safety-lever",1);
  setprop("f16/avionics/ins-knob", 3); #NAV

  fail.master_caution();

  screen.log.write("Done.");
  inAutostart = 0;
}

var autostartfail = func {
  autostart_jfs.stop();
  autostart_engine.stop();
  screen.log.write("Engine start failed.");
  print("Auto engine start failed.");
  setprop("f16/engine/jfs-start-switch",0);
  setprop("f16/engine/cutoff-release-lever",1);
  inAutostart = 0;
}

var autostart_watchdog = maketimer(1, autostartfail);
autostart_watchdog.singleShot = 1;

var autostart_jfs = maketimer(1, autostartjfs);

var autostart_engine = maketimer(1, autostartengine);

##################################################################################################
# Cold and Dark
##################################################################################################

var coldndark = func {
  #
  # Called from GUI dialog
  #
  screen.log.write("Shutting down, standby..");
  setprop("fdm/jsbsim/fcs/canopy-engage", 1);
  setprop("fdm/jsbsim/elec/switches/epu",0);
  setprop("fdm/jsbsim/elec/switches/epu-cover",1);
  setprop("fdm/jsbsim/elec/switches/epu-pin",1);
  eng.JFS.start_switch_last = 0;# bypass check for switch was in OFF
  setprop("fdm/jsbsim/elec/switches/main-pwr",0);
  setprop("f16/avionics/power-rdr-alt",0);
  setprop("f16/avionics/power-fcr",0);
  setprop("f16/avionics/power-right-hdpt",0);
  setprop("f16/avionics/power-left-hdpt",0);
  setprop("f16/avionics/power-mfd",0);
  setprop("f16/avionics/power-ufc",0);
  setprop("f16/avionics/power-mmc",0);
  setprop("f16/avionics/power-gps",0);
  setprop("f16/avionics/power-dl",0);
  setprop("f16/avionics/power-st-sta",0);
  setprop("f16/avionics/ins-knob", 0);#OFF
  setprop("f16/avionics/hud-sym", 0);
  setprop("f16/avionics/hud-brt", 0);
  setprop("f16/avionics/ew-rwr-switch",0);
  setprop("f16/avionics/ew-disp-switch",0);
  setprop("f16/avionics/ew-mws-switch",0);
  setprop("f16/avionics/ew-jmr-switch",0);
  setprop("f16/avionics/ew-mode-knob",0);
  setprop("f16/avionics/cmds-01-switch",0);
  setprop("f16/avionics/cmds-02-switch",0);
  setprop("f16/avionics/cmds-ch-switch",0);
  setprop("f16/avionics/cmds-fl-switch",0);
  setprop("f16/avionics/pbg-switch",-1);
  setprop("controls/ventilation/airconditioning-enabled",0);
  setprop("controls/ventilation/airconditioning-source",0);
  setprop("controls/lighting/ext-lighting-panel/master", 0);
  setprop("controls/lighting/landing-light",0);
  setprop("controls/lighting/lighting-panel/console-flood-knob", 0.0);
  setprop("controls/lighting/lighting-panel/pri-inst-pnl-knob", 0.0);
  setprop("controls/lighting/lighting-panel/flood-inst-pnl-knob", 0.0);
  setprop("controls/lighting/lighting-panel/console-primary-knob", 0.0);
  setprop("controls/lighting/lighting-panel/data-entry-display", 0.0);
  setprop("instrumentation/radar/radar-enable", 1);
  setprop("instrumentation/comm[0]/volume",0);
  setprop("instrumentation/comm[1]/volume",0);
  setprop("controls/seat/ejection-safety-lever",0);
  setprop("f16/engine/feed",0);
  setprop("f16/engine/cutoff-release-lever",1);
  setprop("f16/engine/jfs-start-switch",0);
};

##################################################################################################
# Re-initialize
##################################################################################################

var re_init_listener = setlistener("/sim/signals/reinit", func {
  if (getprop("/sim/signals/reinit") != 0) {
    setprop("/controls/gear/gear-down",1);
    setprop("/controls/gear/brake-parking",1);
    setprop("f16/fcs/autopilot-on",0);
    setprop("f16/fcs/switch-pitch-block15",0);
    setprop("f16/fcs/switch-roll-block15",0);
    setprop("f16/fcs/switch-roll-block20",0);
    setprop("f16/fcs/switch-pitch-block20",0);
    settimer(repair4,3);    
    if (pylons.fcs != nil) {
      # replenish cooling fluid on all aim-9:
      var aim9s = pylons.fcs.getAllOfType("AIM-9L");
      foreach(aim;aim9s) {
        aim.cool_total_time = 0;#consider making a method in AIM for this!
        aim.setCooling(0);
      }
      var aim9s = pylons.fcs.getAllOfType("AIM-9M");
      foreach(aim;aim9s) {
        aim.cool_total_time = 0;#consider making a method in AIM for this!
        aim.setCooling(0);
      }
      var aim9s = pylons.fcs.getAllOfType("AIM-9X");
      foreach(aim;aim9s) {
        aim.cool_total_time = 0;#consider making a method in AIM for this!
        aim.setCooling(0);
      }
    }
    repair2();
  }
 }, 0, 0);
