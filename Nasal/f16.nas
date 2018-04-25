# $Id$

var TRUE = 1;
var FALSE = 0;

# strobes ===========================================================
var strobe_switch = props.globals.getNode("controls/lighting/ext-lighting-panel/anti-collision", 1);
aircraft.light.new("sim/model/lighting/strobe", [0.03, 1.9+rand()/5], strobe_switch);

var checkVNE = func {
  if (getprop("/sim/freeze/replay-state")) {
    settimer(checkVNE, 1);
    return;
  }

  var msg = "";

  # Now check VNE
  var airspeedM= getprop("instrumentation/airspeed-indicator/indicated-mach");
  var vneM     = getprop("limits-custom/mach");
  var airspeed = getprop("instrumentation/airspeed-indicator/indicated-speed-kt");
  var vne      = getprop("limits-custom/vne");
  

  if ((airspeed != nil) and (vne != nil) and (airspeed > vne))
  {
    msg = "Airspeed exceeds Vne!";
  } elsif ((airspeedM != nil) and (vneM != nil) and (airspeedM > vneM)) {
    msg = "Airspeed exceeds Vne!";
  }

  if (msg != "")
  {
    # If we have a message, display it, but don't bother checking for
    # any other errors for 10 seconds. Otherwise we're likely to get
    # repeated messages.
    screen.log.write(msg);
    settimer(checkVNE, 10);
  }
  else
  {
    settimer(checkVNE, 1);
  }
}

checkVNE();

var oldsuit = func {
  setprop("sim/rendering/redout/parameters/blackout-onset-g", 5);
  setprop("sim/rendering/redout/parameters/blackout-complete-g", 9);
  setprop("sim/rendering/redout/parameters/redout-onset-g", -1.5);
  setprop("sim/rendering/redout/parameters/redout-complete-g", -4);
  setprop("sim/rendering/redout/parameters/onset-blackout-sec", 300);
  setprop("sim/rendering/redout/parameters/fast-blackout-sec", 10);
  setprop("sim/rendering/redout/parameters/onset-redout-sec", 45);
  setprop("sim/rendering/redout/parameters/fast-redout-sec", 3.5);
  setprop("sim/rendering/redout/parameters/recover-fast-sec", 7);
  setprop("sim/rendering/redout/parameters/recover-slow-sec", 15);
}
var newsuit = func {
  setprop("sim/rendering/redout/parameters/blackout-onset-g", 5);
  setprop("sim/rendering/redout/parameters/blackout-complete-g", 8);
  setprop("sim/rendering/redout/parameters/redout-onset-g", -1.5);
  setprop("sim/rendering/redout/parameters/redout-complete-g", -4);
  setprop("sim/rendering/redout/parameters/onset-blackout-sec", 300);
  setprop("sim/rendering/redout/parameters/fast-blackout-sec", 30);
  setprop("sim/rendering/redout/parameters/onset-redout-sec", 45);
  setprop("sim/rendering/redout/parameters/fast-redout-sec", 3.5);
  setprop("sim/rendering/redout/parameters/recover-fast-sec", 7);
  setprop("sim/rendering/redout/parameters/recover-slow-sec", 15);
}

setlistener("sim/rendering/redout/new", func {
      if (getprop("sim/rendering/redout/new")) {
        newsuit();
      } else {
        oldsuit();
      }
});

var resetView = func () {
  var hd = getprop("sim/current-view/heading-offset-deg");
  var hd_t = getprop("sim/current-view/config/heading-offset-deg");
  if (hd > 180) {
    hd_t = hd_t + 360;
  }
  interpolate("sim/current-view/field-of-view", getprop("sim/current-view/config/default-field-of-view-deg"), 0.66);
  interpolate("sim/current-view/heading-offset-deg", hd_t,0.66);
  interpolate("sim/current-view/pitch-offset-deg", getprop("sim/current-view/config/pitch-offset-deg"),0.66);
  interpolate("sim/current-view/roll-offset-deg", getprop("sim/current-view/config/roll-offset-deg"),0.66);
  
  if (getprop("sim/current-view/view-number") == 0) {
    interpolate("sim/current-view/x-offset-m", 0, 1); 
    interpolate("sim/current-view/y-offset-m", 0.94, 1); 
    interpolate("sim/current-view/z-offset-m", -3.94, 1);
  } else {
    interpolate("sim/current-view/x-offset-m", 0, 1);
  }
}

var HDDView = func () {
  if (getprop("sim/current-view/view-number") == 0) {
    var hd = getprop("sim/current-view/heading-offset-deg");
    var hd_t = 360;
    if (hd < 180) {
      hd_t = hd_t - 360;
    }
    interpolate("sim/current-view/field-of-view", 41, 0.66);
    interpolate("sim/current-view/heading-offset-deg", hd_t,0.66);
    interpolate("sim/current-view/pitch-offset-deg", -5,0.66);
    interpolate("sim/current-view/roll-offset-deg", 0,0.66);
    interpolate("sim/current-view/x-offset-m", 0.1166, 1); 
    interpolate("sim/current-view/y-offset-m", 0.6282, 1); 
    interpolate("sim/current-view/z-offset-m", -3.94, 1);
  }
}

var RWRView = func () {
  if (getprop("sim/current-view/view-number") == 0) {
    var hd = getprop("sim/current-view/heading-offset-deg");
    var hd_t = 360;
    if (hd < 180) {
      hd_t = hd_t - 360;
    }
    interpolate("sim/current-view/field-of-view", 28, 0.66);
    interpolate("sim/current-view/heading-offset-deg", hd_t,0.66);
    interpolate("sim/current-view/pitch-offset-deg", 2,0.66);
    interpolate("sim/current-view/roll-offset-deg", 0,0.66);
    interpolate("sim/current-view/x-offset-m", -0.1166, 1); 
    interpolate("sim/current-view/y-offset-m", 0.6282, 1); 
    interpolate("sim/current-view/z-offset-m", -3.94, 1);
  }
}

# to prevent dynamic view to act like helicopter due to defining <rotors>:
dynamic_view.register(func {me.default_plane();});

var flareCount = -1;
var flareStart = -1;

var loop_flare = func {
    # Flare/chaff release
    if (getprop("ai/submodels/submodel[0]/flare-release-snd") == nil) {
        setprop("ai/submodels/submodel[0]/flare-release-snd", FALSE);
        setprop("ai/submodels/submodel[0]/flare-release-out-snd", FALSE);
    }
    var flareOn = getprop("ai/submodels/submodel[0]/flare-release-cmd");
    if (flareOn == TRUE and getprop("ai/submodels/submodel[0]/flare-release") == FALSE
            and getprop("ai/submodels/submodel[0]/flare-release-out-snd") == FALSE
            and getprop("ai/submodels/submodel[0]/flare-release-snd") == FALSE) {
        flareCount = getprop("ai/submodels/submodel[0]/count");
        flareStart = getprop("sim/time/elapsed-sec");
        setprop("ai/submodels/submodel[0]/flare-release-cmd", FALSE);
        if (flareCount > 0) {
            # release a flare
            setprop("ai/submodels/submodel[0]/flare-release-snd", TRUE);
            setprop("ai/submodels/submodel[0]/flare-release", TRUE);
            setprop("rotors/main/blade[3]/flap-deg", flareStart);
            setprop("rotors/main/blade[3]/position-deg", flareStart);
        } else {
            # play the sound for out of flares
            setprop("ai/submodels/submodel[0]/flare-release-out-snd", TRUE);
        }
    }
    if (getprop("ai/submodels/submodel[0]/flare-release-snd") == TRUE and (flareStart + 1) < getprop("sim/time/elapsed-sec")) {
        setprop("ai/submodels/submodel[0]/flare-release-snd", FALSE);
        setprop("rotors/main/blade[3]/flap-deg", 0);
        setprop("rotors/main/blade[3]/position-deg", 0);#MP interpolates between numbers, so nil is better than 0.
    }
    if (getprop("ai/submodels/submodel[0]/flare-release-out-snd") == TRUE and (flareStart + 1) < getprop("sim/time/elapsed-sec")) {
        setprop("ai/submodels/submodel[0]/flare-release-out-snd", FALSE);
    }
    if (flareCount > getprop("ai/submodels/submodel[0]/count")) {
        # A flare was released in last loop, we stop releasing flares, so user have to press button again to release new.
        setprop("ai/submodels/submodel[0]/flare-release", FALSE);
        flareCount = -1;
    }

    setprop("instrumentation/mfd-sit/inputs/tfc", 0);
    setprop("instrumentation/mfd-sit/inputs/lh-vor-adf", 0);
    setprop("instrumentation/mfd-sit/inputs/rh-vor-adf", 0);
    setprop("instrumentation/mfd-sit/inputs/wpt", 0);
    if (getprop("payload/armament/msg") == TRUE) {
      setprop("sim/rendering/redout/enabled", TRUE);
      if (getprop("sim/rendering/redout/new")) {
        newsuit();
      } else {
        oldsuit();
      }
    }

    settimer(loop_flare, 0.10);
};

loop_flare();

var repair = func {
  screen.log.write("Repairing, standby..");
  crash.repair();
  if (getprop("engines/engine[0]/running")!=1) {
    setprop("controls/engines/engine[0]/cutoff", 1);
    setprop("controls/engines/engine[0]/starter", 1);
    settimer(repair2, 10);
  }
}

var repair2 = func {
  setprop("controls/engines/engine[0]/cutoff", 0);
  screen.log.write("Attempting engine restart, standby..");
}

var re_init_listener = setlistener("/sim/signals/reinit", func {
  if (getprop("/consumables/fuel/tank[0]/level-norm")<0.5) {
    setprop("/consumables/fuel/tank[0]/level-norm", 0.55);
  }
  repair();
 }, 0, 0);