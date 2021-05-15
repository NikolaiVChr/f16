
var TRUE = 1;
var FALSE = 0;

# Use: f16.tree("/",0);
var tree = func(n = "", graph = 1) {
  n = debug.propify(n);
  if (n == nil)
    return debug.dump(n);
  _tree(n, graph);
}


var _tree = func(n, graph = 1, prefix = "", level = 0) {
  var path = n.getPath();
  var children = n.getChildren();
  var s = "";

  if (graph) {
    s = prefix ~ n.getName();
    var index = n.getIndex();
    if (index)
      s ~= "[" ~ index ~ "]";
  } else {
    s = n.getPath();
  }

  if (size(children)) {
    #s ~= "/";
    #if (n.getType() != "NONE")
    #  s ~= " = " ~ debug.string(n.getValue()) ~ " " ~ attributes(n)
    #      ~ "    " ~ _section(" PARENT-VALUE ");
  } else {
    #s ~= " = " ~ debug.string(n.getValue()) ~ " " ~ attributes(n);
  }

  if ((var a = n.getAliasTarget()) != nil)
    s ~= "  " ~ debug._title(" alias to ") ~ "  " ~ a.getPath();

  if(n.getName() == "serviceable") print(s);

  if (n.getType() != "ALIAS")
    forindex (var i; children)
      _tree(children[i], graph, prefix ~ ".   ", level + 1);
}








# strobes ===========================================================
#var strobe_switch = props.globals.getNode("controls/lighting/ext-lighting-panel/anti-collision2", 1);
#aircraft.light.new("sim/model/lighting/strobe", [0.03, 1.9+rand()/5], strobe_switch);
var msgA = "If you need to repair now, then use Menu-Location-SelectAirport instead.";
var msgB = "Please land before changing payload.";
var msgC = "Please land before refueling.";
var cockpit_blink = props.globals.getNode("f16/avionics/cockpit_blink", 1);
aircraft.light.new("f16/avionics/cockpit_blinker", [0.25, 0.25], cockpit_blink);
setprop("f16/avionics/cockpit_blink", 1);

var extrapolate = func (x, x1, x2, y1, y2) {
    return y1 + ((x - x1) / (x2 - x1)) * (y2 - y1);
};

var checkVNE = func {
  if (getprop("/sim/freeze/replay-state")) {
    settimer(checkVNE, 1);
    return;
  }

  var msg = "";

  # Now check VNE
  var airspeedM= getprop("instrumentation/airspeed-indicator/indicated-mach");
  var vneM     = getprop("limits-custom/mach");
  var airspeed = getprop("/fdm/jsbsim/velocities/vc-kts");
  var vne      = getprop("limits-custom/vne");
  var nose      = getprop("limits-custom/tire-nose");
  var main      = getprop("limits-custom/tire-main");
  var MLG_kt   = getprop("fdm/jsbsim/gear/unit[1]/WOW")?(getprop("fdm/jsbsim/gear/unit[1]/wheel-speed-fps")*FPS2KT):0;
  var NLG_kt   = getprop("fdm/jsbsim/gear/unit[0]/WOW")?(getprop("fdm/jsbsim/gear/unit[0]/wheel-speed-fps")*FPS2KT):0;
  var old = getprop("f16/vne");

  if ((airspeed != nil) and (vne != nil) and (airspeed > vne))
  {
    msg = "Airspeed exceeds Vne!";
    setprop("f16/vne",1);
    setprop("f16/vne-exceed",extrapolate(airspeed-vne,0,100,0,1));
  } elsif ((airspeedM != nil) and (vneM != nil) and (airspeedM > vneM)) {
    msg = "Airspeed exceeds Vne!";
    setprop("f16/vne",1);
    setprop("f16/vne-exceed",extrapolate(airspeedM-vneM,0,0.20,0,1));
  } elsif ((nose!=nil and NLG_kt>nose)or (main!=nil and MLG_kt>main)) {
    msg = "Groundspeed exceeds tire limit!";
    setprop("f16/vne",0);
    setprop("f16/vne-exceed",0);
  }  else {
    setprop("f16/vne",0);
    setprop("f16/vne-exceed",0);
  }

  if (msg != "")
  {
    # If we have a message, display it, but don't bother checking for
    # any other errors for 10 seconds. Otherwise we're likely to get
    # repeated messages.
    if (rand()>0.9 or old == 0) {
      screen.log.write(msg);
    }
    settimer(checkVNE, 1);
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
    interpolate("sim/current-view/y-offset-m", 0.86, 1); 
    interpolate("sim/current-view/z-offset-m", -4.015, 1);
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
    interpolate("sim/current-view/pitch-offset-deg", -10.85,0.66);
    interpolate("sim/current-view/roll-offset-deg", 0,0.66);
    interpolate("sim/current-view/x-offset-m", 0.1166, 1); 
    interpolate("sim/current-view/y-offset-m", 0.6282, 1); 
    interpolate("sim/current-view/z-offset-m", -3.94, 1);
  }
}

var HSIView = func () {
  if (getprop("sim/current-view/view-number") == 0) {
    var hd = getprop("sim/current-view/heading-offset-deg");
    var hd_t = 360;
    if (hd < 180) {
      hd_t = hd_t - 360;
    }
    interpolate("sim/current-view/field-of-view", 12, 0.66);
    interpolate("sim/current-view/heading-offset-deg", hd_t,0.66);
    interpolate("sim/current-view/pitch-offset-deg", -41,0.66);
    interpolate("sim/current-view/roll-offset-deg", 0,0.66);
    interpolate("sim/current-view/x-offset-m", 0, 1); 
    interpolate("sim/current-view/y-offset-m", 0.85, 1); 
    interpolate("sim/current-view/z-offset-m", -4, 1);
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
    interpolate("sim/current-view/pitch-offset-deg", -6.9,0.66);
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

var medium_fast = {
  loop: func {
    # Flare/chaff release
    if (getprop("ai/submodels/submodel[0]/flare-release-snd") == nil) {
        setprop("ai/submodels/submodel[0]/flare-release-snd", FALSE);
        setprop("ai/submodels/submodel[0]/flare-release-out-snd", FALSE);
    }
    var flareOn = getprop("ai/submodels/submodel[0]/flare-release-cmd") and getprop("f16/avionics/ew-mode-knob") == 1;
    var flareOnA = getprop("ai/submodels/submodel[0]/flare-auto-release-cmd") > rand() and getprop("f16/avionics/ew-mode-knob") == 2 and getprop("ai/submodels/submodel[0]/flare-release-cmd") == 0;
    flareOn = flareOn or flareOnA;
    
    if (flareOn == TRUE and getprop("ai/submodels/submodel[0]/flare-release") == FALSE
            and getprop("ai/submodels/submodel[0]/flare-release-out-snd") == FALSE
            and getprop("ai/submodels/submodel[0]/flare-release-snd") == FALSE) {
        flareCount = getprop("ai/submodels/submodel[0]/count");
        flareStart = getprop("sim/time/elapsed-sec");
        setprop("ai/submodels/submodel[0]/flare-release-cmd", FALSE);
        if (flareCount > 0 and getprop("fdm/jsbsim/elec/bus/emergency-dc-2")>20) {
            # release a flare
            setprop("ai/submodels/submodel[0]/flare-release-snd", TRUE);
            setprop("ai/submodels/submodel[0]/flare-release", TRUE);
            setprop("rotors/main/blade[3]/flap-deg", flareStart);
            setprop("rotors/main/blade[3]/position-deg", flareStart);
            damage.flare_released();
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
    if (getprop("ai/submodels/submodel[0]/flare-release-out-snd") == TRUE and (flareStart + 1.5) < getprop("sim/time/elapsed-sec")) {
        setprop("ai/submodels/submodel[0]/flare-release-out-snd", FALSE);
    }
    if (flareCount > getprop("ai/submodels/submodel[0]/count")) {
        # A flare was released in last loop, we stop releasing flares, so user have to press button again to release new.
        setprop("ai/submodels/submodel[0]/flare-release", FALSE);
        flareCount = -1;
    }

    setprop("instrumentation/mfd-sit-1/inputs/tfc", 0);
    #setprop("instrumentation/mfd-sit/inputs/lh-vor-adf", 0);
    #setprop("instrumentation/mfd-sit/inputs/rh-vor-adf", 0);
    setprop("instrumentation/mfd-sit-1/inputs/wpt", 0);
    setprop("instrumentation/mfd-sit-2/inputs/tfc", 0);
    #setprop("instrumentation/mfd-sit/inputs/lh-vor-adf", 0);
    #setprop("instrumentation/mfd-sit/inputs/rh-vor-adf", 0);
    setprop("instrumentation/mfd-sit-2/inputs/wpt", 0);
    if (getprop("payload/armament/msg") == TRUE) {
      setprop("sim/rendering/redout/enabled", TRUE);
      if (getprop("sim/rendering/redout/new")) {
        newsuit();
      } else {
        oldsuit();
      }
      #call(func{fgcommand('dialog-close', multiplayer.dialog.dialog.prop())},nil,var err= []);# props.Node.new({"dialog-name": "location-in-air"}));
      call(func{multiplayer.dialog.del();},nil,var err= []);
      if (!getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        call(func{fgcommand('dialog-close', props.Node.new({"dialog-name": "WeightAndFuel"}))},nil,var err2 = []);
        call(func{fgcommand('dialog-close', props.Node.new({"dialog-name": "system-failures"}))},nil,var err2 = []);
        call(func{fgcommand('dialog-close', props.Node.new({"dialog-name": "instrument-failures"}))},nil,var err2 = []);
      }      
      setprop("sim/freeze/fuel",0);
      setprop("/sim/freeze/master", 0);
      setprop("/sim/freeze/clock", 0);
      setprop("/sim/speed-up", 1);
      setprop("/gui/map/draw-traffic", 0);
      setprop("/sim/gui/dialogs/map-canvas/draw-TFC", 0);
      setprop("/sim/rendering/als-filters/use-filtering", 1);
      call(func{var interfaceController = fg1000.GenericInterfaceController.getOrCreateInstance();
      interfaceController.stop();},nil,var err2=[]);
    }
    setprop("/sim/multiplay/visibility-range-nm", 160);
    if (getprop("payload/armament/es/flags/deploy-id-10")!= nil) {
      setprop("f16/force", 7-5*getprop("payload/armament/es/flags/deploy-id-10"));
      } else {
        setprop("f16/force", 7);
      }

    if (getprop("fdm/jsbsim/elec/bus/noness-ac-2")<100) {
      setprop("controls/lighting/lighting-panel/flood-inst-pnl", 0);
    } else {
      setprop("controls/lighting/lighting-panel/flood-inst-pnl", getprop("controls/lighting/lighting-panel/flood-inst-pnl-knob"));
    }
    if (getprop("fdm/jsbsim/elec/bus/noness-ac-2")<100) {
      setprop("controls/lighting/lighting-panel/console-flood", 0);
    } else {
      setprop("controls/lighting/lighting-panel/console-flood", getprop("controls/lighting/lighting-panel/console-flood-knob"));
    }
    if (getprop("fdm/jsbsim/elec/bus/emergency-ac-1")<100) {
      setprop("controls/lighting/lighting-panel/console-primary", 0);
      setprop("controls/lighting/lighting-panel/pri-inst-pnl", 0);
    } else {
      setprop("controls/lighting/lighting-panel/console-primary", getprop("controls/lighting/lighting-panel/console-primary-knob"));
      setprop("controls/lighting/lighting-panel/pri-inst-pnl", getprop("controls/lighting/lighting-panel/pri-inst-pnl-knob"));
    }

    # mal-ind-lts-brightness-switch: DIM (-1), BRT (1) or springloaded center (0)
    # additional logic from T.O. 1F-16A-1, page 1-155.
    if ((getprop("controls/lighting/lighting-panel/mal-ind-lts-brightness-switch") == -1) and
        (getprop("controls/lighting/lighting-panel/pri-inst-pnl-knob") > 0))
    {
       setprop("controls/lighting/lighting-panel/mal-ind-lts-brightness", 0.5);
    }

    if ((getprop("controls/lighting/lighting-panel/console-flood-knob") == 1.0) or
        (getprop("controls/lighting/lighting-panel/pri-inst-pnl-knob") == 0.0) or
        (getprop("fdm/jsbsim/elec/bus/noness-dc") < 20) or
        (getprop("controls/lighting/lighting-panel/mal-ind-lts-brightness-switch") == 1))
    {
       setprop("controls/lighting/lighting-panel/mal-ind-lts-brightness", 1.0);
    }
    
    setprop("/instrumentation/nav[0]/volume", getprop("/f16/avionics/ils-volume")*getprop("sim/current-view/internal"));

    setprop("f16/external", !getprop("sim/current-view/internal"));
    
    setprop("sim/multiplay/generic/float[19]",  getprop("controls/engines/engine/throttle"));

    settimer(func {me.loop()},LOOP_MEDIUM_FAST_RATE);
  },
};
var LOOP_MEDIUM_FAST_RATE = 0.1;

var medium = {
  loop: func {
    
    # Store CAT:
    if (pylons.fcs != nil) {
      setprop("f16/stores-cat", pylons.fcs.getCategory());
      } else {
        setprop("f16/stores-cat", 1);
      }
    # strobe light:
    if (getprop("controls/lighting/ext-lighting-panel/anti-collision") == 1 and getprop("controls/lighting/ext-lighting-panel/master") == 1) {
      setprop("controls/lighting/ext-lighting-panel/anti-collision2",1);
    } else {
      setprop("controls/lighting/ext-lighting-panel/anti-collision2",0);
    }
    
    var tcnTrue = getprop("instrumentation/tacan/indicated-bearing-true-deg");
    var trueH   = getprop("orientation/heading-deg");
    var tcnDev  = geo.normdeg180(tcnTrue-trueH);
    setprop("instrumentation/tacan/bearing-relative-deg", tcnDev);
#    if (getprop("autopilot/route-manager/wp/dist") != nil) {
#      setprop("autopilot/route-manager/wp/dist-int",int(getprop("autopilot/route-manager/wp/dist")));
#    } else {
#      setprop("autopilot/route-manager/wp/dist-int",0);
#    }
    if (getprop("sim/model/f16/controls/navigation/instrument-mode-panel/mode/rotary-switch-knob") == 0 or getprop("sim/model/f16/controls/navigation/instrument-mode-panel/mode/rotary-switch-knob") == 1) {
      #tacan
      if (!getprop("instrumentation/tacan/in-range") or getprop("f16/avionics/tacan-receive-only")) {
          setprop("f16/avionics/hsi-dist",-1);
        } else {
          setprop("f16/avionics/hsi-dist",getprop("instrumentation/tacan/indicated-distance-nm"));
        }
    } elsif (getprop("sim/model/f16/controls/navigation/instrument-mode-panel/mode/rotary-switch-knob") == 2 or getprop("sim/model/f16/controls/navigation/instrument-mode-panel/mode/rotary-switch-knob") == 3) {
      if (getprop("autopilot/route-manager/wp/dist") != nil and getprop("f16/avionics/power-mmc")) {
        setprop("f16/avionics/hsi-dist",getprop("autopilot/route-manager/wp/dist"));
      } else {
        setprop("f16/avionics/hsi-dist",-1);
      }
    } else {
      if (getprop("instrumentation/dme/in-range") != nil and getprop("instrumentation/dme/in-range") and getprop("instrumentation/dme/indicated-distance-nm") != nil and getprop("instrumentation/dme/indicated-distance-nm") > 0) {
        setprop("f16/avionics/hsi-dist",getprop("instrumentation/dme/indicated-distance-nm"));
      } else {
        setprop("f16/avionics/hsi-dist",-1);
      }
    }
    # HUD power:
    if (getprop("fdm/jsbsim/elec/bus/emergency-ac-2")>100 or getprop("fdm/jsbsim/elec/bus/emergency-dc-2")>20) {
      setprop("f16/avionics/hud-power",getprop("f16/avionics/power-ufc"));
    } else {
      var ac = getprop("fdm/jsbsim/elec/bus/emergency-ac-2")/100;
      var dc = getprop("fdm/jsbsim/elec/bus/emergency-dc-2")/20;
      var power = ac*getprop("f16/avionics/power-ufc");
      if (ac < dc) {
        power=dc*getprop("f16/avionics/power-ufc");
      }
      if (power<0.5) {
        power=0;
      }
      setprop("f16/avionics/hud-power",power);
    }
    var drift = getprop("f16/avionics/hud-drift");
    if (drift == 0) {
      setprop("f16/avionics/hud-drift", 1);
      if (getprop("f16/avionics/fault-warning") == 1) {
        setprop("f16/avionics/fault-warning", 2);
      }
      if (getprop("f16/avionics/bingo") == 1) {
        setprop("f16/avionics/bingo", 2);
      }
      setprop("f16/avionics/n-reset", 1);# yep, manual dash 34 says it does that.
    }
    batteryChargeDischarge(); ########## To work optimally, should run at or below 0.5 in a loop ##########
    
    sendLightsToMp();
    sendABtoMP();
    CARA();
    laser();
    buffeting();
    f16_fuel.fuelqty();
    cockpit_temperature_control.loop();
    settimer(func {me.loop()},LOOP_MEDIUM_RATE);
  },
};
var LOOP_MEDIUM_RATE = 0.5;

var slow = {
  loop: func {
    #var valid = 0;
    #if (awg_9.active_u != nil) {
    #  valid = iff.interrogate(awg_9.active_u.propNode);
    #}
    #setprop("instrumentation/iff/response", valid);
    if (getprop("fdm/jsbsim/elec/bus/emergency-dc-1")<20 and getprop("fdm/jsbsim/elec/bus/emergency-dc-2")<20) {
      setprop("sound/rwr-new", -1);#prevent sound from going off whenever it gets elec
    }
    if (!getprop("systems/pitot/serviceable") or !getprop("systems/static/serviceable")) {
      setprop("fdm/jsbsim/fcs/fly-by-wire/enable-standby-gains", 1);
    } else {
      setprop("fdm/jsbsim/fcs/fly-by-wire/enable-standby-gains", 0);
    }
    setprop("f16/avionics/emer-jett-switch",0);
    settimer(func {me.loop()},5);
  },
};

var fast = {
  loop: func {
    # Terrain warning:
    if ((getprop("velocities/speed-east-fps") != 0 or getprop("velocities/speed-north-fps") != 0) and getprop("fdm/jsbsim/gear/unit[0]/WOW") != 1 and
          getprop("fdm/jsbsim/gear/unit[1]/WOW") != 1 and (
         (getprop("fdm/jsbsim/gear/gear-pos-norm")<1)
      or (getprop("fdm/jsbsim/gear/gear-pos-norm")>0.99 and getprop("/position/altitude-agl-ft") > 164)
      )) {
      me.start = geo.aircraft_position();

      me.speed_down_fps  = getprop("velocities/speed-down-fps");
      me.speed_east_fps  = getprop("velocities/speed-east-fps");
      me.speed_north_fps = getprop("velocities/speed-north-fps");
      me.speed_horz_fps  = math.sqrt((me.speed_east_fps*me.speed_east_fps)+(me.speed_north_fps*me.speed_north_fps));
      me.speed_fps       = math.sqrt((me.speed_horz_fps*me.speed_horz_fps)+(me.speed_down_fps*me.speed_down_fps));
      me.heading = 0;
      if (me.speed_north_fps >= 0) {
        me.heading -= math.acos(me.speed_east_fps/me.speed_horz_fps)*R2D - 90;
      } else {
        me.heading -= -math.acos(me.speed_east_fps/me.speed_horz_fps)*R2D - 90;
      }
      me.heading = geo.normdeg(me.heading);
      #cos(90-heading)*horz = east
      #acos(east/horz) - 90 = -head

      me.end = geo.Coord.new(me.start);
      me.end.apply_course_distance(me.heading, me.speed_horz_fps*FT2M);
      me.end.set_alt(me.end.alt()-me.speed_down_fps*FT2M);

      me.dir_x = me.end.x()-me.start.x();
      me.dir_y = me.end.y()-me.start.y();
      me.dir_z = me.end.z()-me.start.z();
      me.xyz = {"x":me.start.x(),  "y":me.start.y(),  "z":me.start.z()};
      me.dir = {"x":me.dir_x,      "y":me.dir_y,      "z":me.dir_z};

      me.geod = get_cart_ground_intersection(me.xyz, me.dir);
      if (me.geod != nil) {
        me.end.set_latlon(me.geod.lat, me.geod.lon, me.geod.elevation);
        me.dist = me.start.direct_distance_to(me.end)*M2FT;
        me.time = me.dist / me.speed_fps;
        setprop("instrumentation/radar/time-till-crash", me.time);
      } else {
        setprop("instrumentation/radar/time-till-crash", 15);
      }
    } else {
      setprop("instrumentation/radar/time-till-crash", 15);
    }
    var spd_deg = getprop("fdm/jsbsim/fcs/speedbrake-pos-deg");
    var spd_anim = -35;#-35 = closed -165 = stripes -270 = dots
    if (getprop("fdm/jsbsim/elec/bus/emergency-dc-1")<20) {
      spd_anim = -165;
    } elsif (last_spd_deg != spd_deg) {
      spd_anim = -165;
    } elsif (spd_deg > 2) {
      spd_anim = -270;
    }
    setprop("surface-positions/speedbrake-pos-anim", spd_anim);
    last_spd_deg = spd_deg;
    settimer(func {me.loop()},0.05);
  },
};

var last_spd_deg = 0;

var sendABtoMP = func {
  var red = getprop("rendering/scene/diffuse/red");
  
  # non-tied property for effect:
  setprop("rendering/scene/diffuse/red-unbound", red);
  
  # afterburner density:
  setprop("sim/multiplay/generic/float[10]",  1-red*0.90);
  
  # turbine emission:
  setprop("sim/multiplay/generic/float[22]",  getprop("sim/multiplay/generic/bool[39]") ? (1.0-red)*(getprop("fdm/jsbsim/fcs/fly-by-wire/throttle/pos-norm")-1.0) : 0.0);

  # color of afterburner:
  # *0.5 is to prevent it from getting too white during night
  setprop("sim/multiplay/generic/float[11]",  0.75+(0.25-red*0.25)*0.5);#red
  setprop("sim/multiplay/generic/float[12]",  0.25+(0.75-red*0.75)*0.5);#green
  setprop("sim/multiplay/generic/float[13]",  0.2+(0.4-red*0.4)*0.5);   #blue
  
  # scene red inverted:
  setprop("sim/multiplay/generic/float[14]",  (1-red)*0.5);  
}

var sendLightsToMp = func {
  var master = getprop("controls/lighting/ext-lighting-panel/master");#all ext. lights except for taxi and landing.
  var flash = getprop("controls/lighting/ext-lighting-panel/pos-lights-flash");#will flash all light controll by WingTail switch
  var wing = getprop("controls/lighting/ext-lighting-panel/wing-tail");#all red/green plus tail white. BRT (1)/off (0)/dim (-1)
  var fuse = getprop("controls/lighting/ext-lighting-panel/fuselage");#white flood lights mounted at base of tail
  var refuel = getprop("systems/refuel/serviceable");
  var form = getprop("controls/lighting/ext-lighting-panel/form-knob");#white formation lights on top and bottom
  var strobe = getprop("controls/lighting/ext-lighting-panel/anti-collision");#white flashing light at top of tail
  var ar = getprop("controls/lighting/ext-lighting-panel/ar-knob");#flood light in hatch of refuel ext. panel
  var land = getprop("controls/lighting/landing-light");# LAND: white bright light pointed downward in fwd gear door (1). TAXI: white light in fwd gear door (-1)

  var ac_non_ess_2 = getprop("fdm/jsbsim/elec/bus/noness-ac-2");# FORM and TAXI (I added fuselage to this as well)
  var ac_em_2 = getprop("fdm/jsbsim/elec/bus/emergency-ac-2");# POS, ANTICOLL and LAND

  var dragChuteRoot = getprop("sim/model/f16/dragchute");#elongated tailroot
  var gear = getprop("fdm/jsbsim/gear/gear-pos-norm");

  # TODO: review elec

  if (land == -1 and ac_non_ess_2 > 100 and gear > 0.3) {
    # taxi
    setprop("sim/multiplay/generic/bool[46]",1);
  } else {
    setprop("sim/multiplay/generic/bool[46]",0);
  }
  
  if (land == 1 and ac_em_2 > 100 and gear > 0.3) {
    # land
    setprop("sim/multiplay/generic/bool[47]",1);
  } else {
    setprop("sim/multiplay/generic/bool[47]",0);
  }

  if (master and ac_em_2 > 100) {
    if (wing != 0) { # wing lights become part of position lights
      # The use of 'flash' in this expression causes the blinking of the posiiton lights at the speed of LOOP_MEDIUM_RATE
      if (!(getprop("sim/multiplay/generic/bool[40]") and flash)) {
        setprop("sim/multiplay/generic/bool[40]",1);#on/off for wingtip and inlet sides.
        setprop("sim/multiplay/generic/float[9]",0.60+wing*0.40);#brightness for back of tail and inlet sides.
        setprop("sim/multiplay/generic/float[20]",0.60+wing*0.40);#brightness for wingtips.
        if (dragChuteRoot) {
          # tail light with dragchute
          setprop("sim/multiplay/generic/bool[42]",1);
          setprop("sim/multiplay/generic/bool[43]",0);
        } else {
          # tail light without dragchute
          setprop("sim/multiplay/generic/bool[42]",0);
          setprop("sim/multiplay/generic/bool[43]",1);
        }
      } else {
        setprop("sim/multiplay/generic/bool[40]",0);
        setprop("sim/multiplay/generic/bool[42]",0);
        setprop("sim/multiplay/generic/bool[43]",0);
        setprop("sim/multiplay/generic/float[9]",0.001);
        setprop("sim/multiplay/generic/float[20]",0.001);
      }
    } else { # wing lights become part of formation lights
      setprop("sim/multiplay/generic/bool[40]",0);
      setprop("sim/multiplay/generic/bool[42]",0);
      setprop("sim/multiplay/generic/bool[43]",0);
      setprop("sim/multiplay/generic/float[9]",0.001);
      if (ac_non_ess_2 > 100) {
        setprop("sim/multiplay/generic/float[20]",form);
      } else {
        setprop("sim/multiplay/generic/float[20]",0.001);
      }
    }
  } else {
    setprop("sim/multiplay/generic/bool[40]",0);
    setprop("sim/multiplay/generic/bool[42]",0);
    setprop("sim/multiplay/generic/bool[43]",0);
    setprop("sim/multiplay/generic/float[9]",0.001);
    setprop("sim/multiplay/generic/float[20]",0.001);
  }

  if (form > 0 and master and ac_non_ess_2 > 100) {
    # belly and spine lights
    setprop("sim/multiplay/generic/bool[41]",1);
    setprop("sim/multiplay/generic/float[8]",form);
  } else {
    setprop("sim/multiplay/generic/bool[41]",0);
    setprop("sim/multiplay/generic/float[8]",0.001);
  }

  if (master and refuel and ac_non_ess_2 > 100) {
    # ar flood and slipway lights
    setprop("sim/multiplay/generic/bool[49]",1);
    # ar slipway light
    if (ar > 0) {
      setprop("sim/multiplay/generic/float[21]",ar);
    } else {
      setprop("sim/multiplay/generic/float[21]",0.001);
    }
  } else {
    setprop("sim/multiplay/generic/bool[49]",0);
    setprop("sim/multiplay/generic/float[21]",0.001);
  }

  if ((fuse == -1 or fuse == 1) and master and ac_non_ess_2 > 100) {
    # fuselage flood
    setprop("sim/multiplay/generic/bool[48]",1);
    setprop("sim/multiplay/generic/float[15]",0.70+fuse*0.30);
  } else {
    setprop("sim/multiplay/generic/bool[48]",0);
    setprop("sim/multiplay/generic/float[15]",0.001);
  }

  if (strobe and master and ac_em_2 > 100) {
    # strobe
    setprop("sim/multiplay/generic/bool[44]",1);
  } else {
    setprop("sim/multiplay/generic/bool[44]",0);
  }
}

var laser = func {
  var lasercode = getprop("f16/avionics/laser-code");
  lasercode = math.clamp(lasercode,1111,2888);#1F-F16CJ-34-1 page 1-232
  setprop("f16/avionics/laser-code",lasercode);
  var laserarm = getprop("controls/armament/laser-arm-dmd");
  if (laserarm == 1 and getprop("fdm/jsbsim/atmosphere/density-altitude") > 25000) {
    #1F-F16CJ-34-1 page 1-227
    screen.log.write("Laser disarm: Above 25000 pressure altitude feet", 1.0, 0.0, 0.0);
    setprop("controls/armament/laser-arm-dmd", 0);
  }
}

var autopilot_inhibit = {
  init: func {
    setlistener("/systems/refuel/serviceable", me.evaluate, 0, 0);
    setlistener("/controls/flight/flaps", me.evaluate, 0, 0);
    setlistener("/controls/gear/gear-down", me.evaluate, 0, 0);
    setlistener("/fdm/jsbsim/fcs/fly-by-wire/enable-standby-gains", me.evaluate, 0, 0);
    setlistener("/f16/avionics/trim-ap-disc-switch", me.evaluate, 0, 0);

    me.evaluate();
  },

  evaluate: func {
    if (
      (getprop("/systems/refuel/serviceable")) or
      (getprop("/controls/flight/flaps")) or
      (getprop("/controls/gear/gear-down")) or
      (getprop("/fdm/jsbsim/fcs/fly-by-wire/enable-standby-gains")) or
      (getprop("/f16/avionics/trim-ap-disc-switch"))
    )
    {
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

var cockpit_temperature_control = {
  loop: func {
    ###########################################################
    #               Aircondition, frost, fog and rain         #
    ###########################################################

    if (me["currentFrost"]==nil) settimer(func {
      setprop("environment/aircraft-effects/temperature-inside-degC", getprop("environment/temperature-degc"));
      if (getprop("environment/temperature-degc") < 0) setprop("/environment/aircraft-effects/frost-outside",1);
      },3);

    # auto temp adjust:
    me.currentFrost = getprop("/environment/aircraft-effects/frost-level");
    me.tempInside  = getprop("environment/aircraft-effects/temperature-inside-degC");
    me.tempAC = getprop("controls/ventilation/airconditioning-temperature");
    if (me.currentFrost > 0.8) {
      me.tempAC += 0.70;
    } elsif (me.currentFrost > 0.4) {
      me.tempAC += 0.30;
    } elsif (me.currentFrost > 0.2) {
      me.tempAC += 0.15;
    } elsif (me.currentFrost > 0.0) {
      me.tempAC += 0.05;
    } elsif (me.tempInside > 21) {
      me.tempAC -= me.tempAC*0.1;
    } elsif (me.tempInside < 10) {
      me.tempAC += 0.25;
    }
    if (me.tempAC > 80) me.tempAC = 80;
    if (me.tempAC < -4) me.tempAC = -4;
    setprop("controls/ventilation/airconditioning-temperature", me.tempAC);
    
    # If the AC is turned on and on auto setting, it will slowly move the cockpit temperature toward its temperature setting.
    # The dewpoint inside the cockpit depends on the outside dewpoint and how the AC is working.
    me.tempOutside = getprop("environment/temperature-degc");
    me.ramRise     = (getprop("fdm/jsbsim/velocities/vtrue-kts")*getprop("fdm/jsbsim/velocities/vtrue-kts"))/(87*87);#this is called the ram rise formula
    me.tempOutside += me.ramRise;
    
    me.tempOutsideDew = getprop("environment/dewpoint-degc");
    me.tempInsideDew = getprop("/environment/aircraft-effects/dewpoint-inside-degC");
    me.tempACDew = 5;# aircondition dew point target. 5 = dry
    me.ACRunning = getprop("fdm/jsbsim/elec/bus/emergency-dc-1") > 20 and getprop("controls/ventilation/airconditioning-enabled") == TRUE;

    # calc inside temp
    me.hotAir_deg_min = 2.0;# how fast does the sources heat up cockpit.
    me.pilot_deg_min  = 0.2;
    me.glass_deg_min_per_deg_diff  = 0.15;
    me.AC_deg_min_per_deg_diff     = 0.50;
    me.knob = getprop("controls/ventilation/windshield-hot-air-knob");
    me.hotAirOnWindshield = getprop("fdm/jsbsim/elec/bus/emergency-dc-1") > 20?me.knob:0;
    if (getprop("canopy/position-norm") > 0) {
      me.tempInside = getprop("environment/temperature-degc");
    } else {
      me.tempInside += me.hotAirOnWindshield * (me.hotAir_deg_min/(60/LOOP_MEDIUM_RATE)); # having hot air on windshield will also heat cockpit (10 degs/5 mins).
      if (me.tempInside < 37) {
        me.tempInside += me.pilot_deg_min/(60/LOOP_MEDIUM_RATE); # pilot will also heat cockpit with 1 deg per 5 mins
      }
      # outside temp ram air temp and static temp will influence inside temp:
      me.coolingFactor = ((me.tempOutside+getprop("environment/temperature-degc"))*0.5-me.tempInside)*me.glass_deg_min_per_deg_diff/(60/LOOP_MEDIUM_RATE);# 1 degrees difference will cool/warm with 0.5 DegCelsius/min
      me.tempInside += me.coolingFactor;
      if (me.ACRunning) {
        # AC is running and will work to influence the inside temperature
        me.tempInside += (me.tempAC-me.tempInside)*me.AC_deg_min_per_deg_diff/(60/LOOP_MEDIUM_RATE);# (tempAC-tempInside) = degs/mins it should change
      }
    }

    # calc temp of glass itself
    me.tempIndex = getprop("/environment/aircraft-effects/glass-temperature-index"); # 0.80 = good window   0.45 = bad window
    me.tempGlass = me.tempIndex*(me.tempInside - me.tempOutside)+me.tempOutside;
    
    # calc dewpoint inside
    if (getprop("canopy/position-norm") > 0) {
      # canopy is open, inside dewpoint aligns to outside dewpoint instead
      me.tempInsideDew = me.tempOutsideDew;
    } else {
      me.tempInsideDewTarget = 0;
      if (me.ACRunning == TRUE) {
        # calculate dew point for inside air. When full airconditioning is achieved at tempAC dewpoint will be tempACdew.
        # slope = (outsideDew - desiredInsideDew)/(outside-desiredInside)
        # insideDew = slope*(inside-desiredInside)+desiredInsideDew
        if ((me.tempOutside-me.tempAC) == 0) {
          me.slope = 1; # divide by zero prevention
        } else {
          me.slope = (me.tempOutsideDew - me.tempACDew)/(me.tempOutside-me.tempAC);
        }
        me.tempInsideDewTarget = me.slope*(me.tempInside-me.tempAC)+me.tempACDew;
      } else {
        me.tempInsideDewTarget = me.tempOutsideDew;
      }
      if (me.tempInsideDewTarget > me.tempInsideDew) {
        me.tempInsideDew = math.clamp(me.tempInsideDew + 0.15, -1000, me.tempInsideDewTarget);
      } else {
        me.tempInsideDew = math.clamp(me.tempInsideDew - 0.15, me.tempInsideDewTarget, 1000);
      }
    }
    

    # calc fogging outside and inside on glass
    me.fogNormOutside = math.clamp((me.tempOutsideDew-me.tempGlass)*0.05, 0, 1);
    me.fogNormInside =math.clamp((me.tempInsideDew-me.tempGlass)*0.05, 0, 1);
    
    # calc frost
    me.frostNormOutside = getprop("/environment/aircraft-effects/frost-outside");
    me.frostNormInside = getprop("/environment/aircraft-effects/frost-inside");
    me.rain = getprop("/environment/rain-norm");
    if (me.rain == nil) {
      me.rain = 0;
    }
    me.frostSpeedInside = math.clamp(-me.tempGlass, -60, 60)/600 + (me.tempGlass<0?me.fogNormInside/50:0);
    me.frostSpeedOutside = math.clamp(-me.tempGlass, -60, 60)/600 + (me.tempGlass<0?(me.fogNormOutside/50 + me.rain/50):0);
    me.maxFrost = math.clamp(1 + ((me.tempGlass + 5) / (0 + 5)) * (0 - 1), 0, 1);# -5 is full frost, 0 is no frost
    me.maxFrostInside = math.clamp(me.maxFrost - math.clamp(me.tempInside/30,0,1), 0, 1);# frost having harder time to form while being constantly thawed.
    me.frostNormOutside = math.clamp(me.frostNormOutside + me.frostSpeedOutside, 0, me.maxFrost);
    me.frostNormInside = math.clamp(me.frostNormInside + me.frostSpeedInside, 0, me.maxFrostInside);
    me.frostNorm = me.frostNormOutside>me.frostNormInside?me.frostNormOutside:me.frostNormInside;
    #var frostNorm = math.clamp((tempGlass-0)*-0.05, 0, 1);# will freeze below 0

    # recalc fogging from frost levels, frost will lower the fogging
    me.fogNormOutside = math.clamp(me.fogNormOutside - me.frostNormOutside / 4, 0, 1);
    me.fogNormInside = math.clamp(me.fogNormInside - me.frostNormInside / 4, 0, 1);
    me.fogNorm = me.fogNormOutside>me.fogNormInside?me.fogNormOutside:me.fogNormInside;

    # If the hot air on windshield is enabled and its setting is high enough, then apply the mask which will defog the windshield.
    #me.mask = FALSE;
    #if (me.frostNorm <= me.hotAirOnWindshield and me.hotAirOnWindshield != 0) {
      me.mask = TRUE;
    #}

    # internal environment
    setprop("/environment/aircraft-effects/fog-inside", me.fogNormInside);
    setprop("/environment/aircraft-effects/fog-outside", me.fogNormOutside);
    setprop("/environment/aircraft-effects/frost-inside", me.frostNormInside);
    setprop("/environment/aircraft-effects/frost-outside", me.frostNormOutside);
    setprop("/environment/aircraft-effects/temperature-glass-degC", me.tempGlass);
    setprop("/environment/aircraft-effects/dewpoint-inside-degC", me.tempInsideDew);
    setprop("/environment/aircraft-effects/temperature-inside-degC", me.tempInside);
    setprop("/environment/aircraft-effects/temperature-outside-ram-degC", me.tempOutside);
    # effects
    setprop("/environment/aircraft-effects/frost-level", me.frostNorm);
    setprop("/environment/aircraft-effects/fog-level", me.fogNorm);
    setprop("/environment/aircraft-effects/use-mask", me.mask);
    if (rand() > 0.95) {
      if (me.tempInside < 10) {
        if (me.tempInside < 5) {
#          screen.log.write("You are freezing, the cabin is very cold", 1.0, 0.0, 0.0);
        } else {
#          screen.log.write("You feel cold, the cockpit is cold", 1.0, 0.5, 0.0);
        }
      } elsif (me.tempInside > 25) {
        if (me.tempInside > 28) {
#          screen.log.write("You are sweating, the cabin is way too hot", 1.0, 0.0, 0.0);
        } else {
#          screen.log.write("You feel its too warm in the cabin", 1.0, 0.5, 0.0);
        }
      }
    }
  },
};

var buffeting = func {
    var g = getprop("/accelerations/pilot-gdamped");
    if (getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        var magn = 0.00025*getprop("/velocities/groundspeed-kt")/225;
        setprop("fdm/jsbsim/systems/buffeting/magnitude",magn);
    } elsif (g > 6) {
        setprop("fdm/jsbsim/systems/buffeting/magnitude",0.00025*g/12);    
    } else {
        setprop("fdm/jsbsim/systems/buffeting/magnitude",0);
    }
}

var CARA = func {
  # Tri-service combined altitude radar altimeter
  if (getprop("f16/avionics/power-rdr-alt-warm")<2) {
    setprop("f16/avionics/cara-on",0);
    return;
  }
  var viewOnGround = 0;
  var attitudeConv = vector.Math.convertAngles(getprop("orientation/heading-deg"),getprop("orientation/pitch-deg"),getprop("orientation/roll-deg"));
  var down = vector.Math.eulerToCartesian3Z(attitudeConv[0],attitudeConv[1],attitudeConv[2]);#vector pointing up from aircraft
  var up = [0,0,1];#vector pointing up from ground
  var angle = vector.Math.angleBetweenVectors(down,up);
  setprop("f16/avionics/cara-on",angle<70 and getprop("position/altitude-agl-ft")<50000);#yep, really goes up to 50000 ft!
}



var batteryChargeDischarge = func {
    var battery_percent = getprop("/fdm/jsbsim/elec/sources/battery-percent");
    var mainpwr_sw = getprop("/fdm/jsbsim/elec/switches/main-pwr");
    if (battery_percent < 100 and getprop("/fdm/jsbsim/elec/bus/charger") >= 100 and getprop("/fdm/jsbsim/elec/failures/battery/serviceable") and mainpwr_sw > 0) {
        if (getprop("/fdm/jsbsim/elec/sources/battery-time") + 5 < getprop("/sim/time/elapsed-sec")) {
            battery_percent_calc = battery_percent + 0.75; # Roughly 90 percent every 10 mins
            if (battery_percent_calc > 100) {
                battery_percent_calc = 100;
            }
            setprop("/fdm/jsbsim/elec/sources/battery-percent", battery_percent_calc);
            setprop("/fdm/jsbsim/elec/sources/battery-time", getprop("/sim/time/elapsed-sec"));
        }
    } else if (battery_percent == 100 and getprop("/fdm/jsbsim/elec/bus/charger") >= 100 and getprop("/fdm/jsbsim/elec/failures/battery/serviceable") and mainpwr_sw > 0) {
        setprop("/fdm/jsbsim/elec/sources/battery-time", getprop("/sim/time/elapsed-sec"));
    } else if (battery_percent > 0 and getprop("/fdm/jsbsim/elec/sources/batt-bus") and getprop("/fdm/jsbsim/elec/failures/battery/serviceable") and mainpwr_sw > 0) {
        if (getprop("/fdm/jsbsim/elec/sources/battery-time") + 5 < getprop("/sim/time/elapsed-sec")) {
            battery_percent_calc = battery_percent - 0.375; # Roughly 90 percent every 20 mins
            if (battery_percent_calc < 0) {
                battery_percent_calc = 0;
            }
            setprop("/fdm/jsbsim/elec/sources/battery-percent", battery_percent_calc);
            setprop("/fdm/jsbsim/elec/sources/battery-time", getprop("/sim/time/elapsed-sec"));
        }
    } else {
        setprop("/fdm/jsbsim/elec/sources/battery-time", getprop("/sim/time/elapsed-sec"));
    }
}


var LBM2KG = 0.4535;
var flexer = func {
  # this function needs to become optimized using Nodes
  if (getprop("sim/multiplay/generic/float[5]")!=nil) {
    setprop("surface-positions/leftrad", getprop("sim/multiplay/generic/float[5]")*20*D2R);  
    setprop("surface-positions/leftrad2", -getprop("surface-positions/left-aileron-pos-norm")*21.5*D2R);  
    setprop("surface-positions/rightrad", getprop("sim/multiplay/generic/float[6]")*20*D2R);  
    setprop("surface-positions/rightrad2", getprop("surface-positions/right-aileron-pos-norm")*21.5*D2R);  
    setprop("surface-positions/radlefr", getprop("fdm/jsbsim/fcs/lef-pos-deg")*D2R);
    setprop("surface-positions/radlefl", -getprop("fdm/jsbsim/fcs/lef-pos-deg")*D2R);

    var wingcontent = 0;
    if (getprop("consumables/fuel/tank[1]/level-kg")!=nil) {
      wingcontent += getprop("consumables/fuel/tank[1]/level-kg");
    }
    if (getprop("consumables/fuel/tank[2]/level-kg")!=nil) {
      wingcontent += getprop("consumables/fuel/tank[2]/level-kg");
    }
    if (getprop("payload/weight[0]/weight-lb") !=nil
        and getprop("payload/weight[1]/weight-lb") !=nil 
        and getprop("payload/weight[2]/weight-lb") !=nil 
        and getprop("payload/weight[3]/weight-lb") !=nil 
        and getprop("payload/weight[7]/weight-lb") !=nil 
        and getprop("payload/weight[8]/weight-lb") !=nil 
        and getprop("payload/weight[9]/weight-lb") !=nil 
        and getprop("payload/weight[10]/weight-lb") !=nil ) {
      setprop("f16/wings/fuel-and-stores-kg", 
      (getprop("payload/weight[0]/weight-lb")
      +getprop("payload/weight[1]/weight-lb")
      +getprop("payload/weight[2]/weight-lb")
      +getprop("payload/weight[3]/weight-lb")
      +getprop("payload/weight[7]/weight-lb")
      +getprop("payload/weight[8]/weight-lb")
      +getprop("payload/weight[9]/weight-lb")
      +getprop("payload/weight[10]/weight-lb"))*LBM2KG
      +wingcontent);
    } elsif (getprop("payload/weight[0]/weight-lb") !=nil
        and getprop("payload/weight[1]/weight-lb") !=nil) {
      # for prototype
      setprop("f16/wings/fuel-and-stores-kg", (getprop("payload/weight[0]/weight-lb")+getprop("payload/weight[1]/weight-lb"))*LBM2KG+wingcontent);
    }
    #setprop("f16/wings/fuel-and-stores-kg", ground*(getprop("f16/wings/fuel-and-stores-kg-a")));
    
    # since the wingflexer works wrong in air we make the wing more stiff in air:
    #if (ground) {
      #setprop("sim/systems/wingflexer/params/K",250);
    #} else {
      #setprop("sim/systems/wingflexer/params/K",2500);
    #}
  }
  #setprop("f16/wings/normal-lbf", -getprop("fdm/jsbsim/aero/coefficient/force/Z_t-lbf"));
  
  var errors = [];
  call(func {var z = getprop("sim/systems/wingflexer/z-m");
      #var max2 = (9.2-2.84)*0.5;
      #max2 = max2 * max2;
      setprop("sim/systems/wingflexer/NaN", z);# this line will fail if NaN, so that an error is raised.
      #setprop("sim/systems/wingflexer/z-m-tip",z);
      #setprop("sim/systems/wingflexer/z-m-outer", z*((3.70-1.42)*(3.70-1.42))/(max2));
      #setprop("sim/systems/wingflexer/z-m-middle",z*((2.88-1.42)*(2.88-1.42))/(max2));
      #setprop("sim/systems/wingflexer/z-m-inner", z*((1.63-1.42)*(1.63-1.42))/(max2));
      },nil,nil, errors);
  if (size(errors)) {
    fgcommand('reinit', props.Node.new({ subsystem: "xml-autopilot" }));
  }
  #if (getprop("/sim/frame-rate-worst")<12) {
  #  setprop("/sim/systems/property-rule[100]/serviceable",0);
  #  setprop("sim/systems/wingflexer/z-m",0);
  #} else {
  #  setprop("/sim/systems/property-rule[100]/serviceable",1);
  #}
  
  var mach = getprop("velocities/mach") >= 1;
  var cam = getprop("sim/current-view/name");
  var still = cam == "Fly-By View" or cam == "Tower View" or cam == "Tower View Look From";
  var nofrontsound = still and mach;
  
  setprop("f16/sound/front-on", !nofrontsound);
  setprop("f16/sound/front-off", nofrontsound);
    
  settimer(flexer,0);
}






############ Cannon impact messages #####################

var hits_count = 0;
var hit_timer  = nil;
var hit_callsign = "";

var Mp = props.globals.getNode("ai/models");
var valid_mp_types = {
  multiplayer: 1, tanker: 1, aircraft: 1, ship: 1, groundvehicle: 1,
};

# Find a MP aircraft close to a given point (code from the Mirage 2000)
var findmultiplayer = func(targetCoord, dist) {
  if(targetCoord == nil) return nil;

  var raw_list = Mp.getChildren();
  var SelectedMP = nil;
  foreach(var c ; raw_list)
  {    
    var is_valid = c.getNode("valid");
    if(is_valid == nil or !is_valid.getBoolValue()) continue;
    
    var type = c.getName();
    
    var position = c.getNode("position");
    var name = c.getValue("callsign");
    if(name == nil or name == "") {
      # fallback, for some AI objects
      var name = c.getValue("name");
    }
    if(position == nil or name == nil or name == "" or !contains(valid_mp_types, type)) continue;

    var lat = position.getValue("latitude-deg");
    var lon = position.getValue("longitude-deg");
    var elev = position.getValue("altitude-ft") * FT2M;

    if(lat == nil or lon == nil or elev == nil) continue;

    MpCoord = geo.Coord.new().set_latlon(lat, lon, elev);
    var tempoDist = MpCoord.direct_distance_to(targetCoord);
    if(dist > tempoDist) {
      dist = tempoDist;
      SelectedMP = name;
    }
  }
  return SelectedMP;
}

var impact_listener = func {
  var ballistic_name = props.globals.getNode("/ai/models/model-impact").getValue();
  var ballistic = props.globals.getNode(ballistic_name, 0);
  if (ballistic != nil and ballistic.getName() != "munition") {
    var typeNode = ballistic.getNode("impact/type");
    if (typeNode != nil and typeNode.getValue() != "terrain") {
      var lat = ballistic.getNode("impact/latitude-deg").getValue();
      var lon = ballistic.getNode("impact/longitude-deg").getValue();
      var elev = ballistic.getNode("impact/elevation-m").getValue();
      var impactPos = geo.Coord.new().set_latlon(lat, lon, elev);
      var target = findmultiplayer(impactPos, 80);

      if (target != nil) {
        var typeOrd = ballistic.getNode("name").getValue();
        if(target == hit_callsign) {
          # Previous impacts on same target
          hits_count += 1;
        }
        else {
          if (hit_timer != nil) {
            # Previous impacts on different target, flush them first
            hit_timer.stop();
            hitmessage(typeOrd);
          }
          hits_count = 1;
          hit_callsign = target;
          hit_timer = maketimer(1, func {hitmessage(typeOrd);});
          hit_timer.singleShot = 1;
          hit_timer.start();
        }
      }
    }
  }
}

var hitmessage = func(typeOrd) {
  #print("inside hitmessage");
  var phrase = typeOrd ~ " hit: " ~ hit_callsign ~ ": " ~ hits_count ~ " hits";
  if (getprop("payload/armament/msg") == TRUE) {
    #armament.defeatSpamFilter(phrase);
    var msg = notifications.ArmamentNotification.new("mhit", 4, -1*(damage.shells[typeOrd][0]+1));
            msg.RelativeAltitude = 0;
            msg.Bearing = 0;
            msg.Distance = hits_count;
            msg.RemoteCallsign = hit_callsign;
    notifications.hitBridgedTransmitter.NotifyAll(msg);
    damage.damageLog.push("You hit "~hit_callsign~" with "~typeOrd~", "~hits_count~" times.");
  } else {
    setprop("/sim/messages/atc", phrase);
  }
  hit_callsign = "";
  hit_timer = nil;
  hits_count = 0;
}

# setup impact listener
setlistener("/ai/models/model-impact", impact_listener, 0, 0);





# setup properties required for frame notifier.
# NOTE: This is a deprecated way of doing things; each subsystem should do this
#       for the properties that are required, however this aircraft predates
#       the updated frame notifier that supports this.

var ownship_pos = geo.Coord.new();
var SubSystem_Main = {
	new : func (_ident){

        var obj = { parents: [SubSystem_Main]};
        input = {
                 FrameRate                 : "/sim/frame-rate",
                 frame_rate                : "/sim/frame-rate",
                 frame_rate_worst          : "/sim/frame-rate-worst",
                 elapsed_seconds           : "/sim/time/elapsed-sec",

                 ElapsedSeconds            : "/sim/time/elapsed-sec",
                 IAS                       : "/velocities/airspeed-kt",
                 Nz                        : "/accelerations/pilot-gdamped",
                 alpha                     : "/fdm/jsbsim/aero/alpha-deg",
                 altitude_ft               : "/position/altitude-ft",
                 baro                      : "/instrumentation/altimeter/setting-hpa",
                 beta                      : "/orientation/side-slip-deg",
                 brake_parking             : "/controls/gear/brake-parking",
                 engine_n2                 : "/engines/engine[0]/n2",
                 eta_s                     : "/autopilot/route-manager/wp/eta-seconds",
                 flap_pos_deg              : "/fdm/jsbsim/fcs/flap-pos-deg",
                 gear_down                 : "/controls/gear/gear-down",
                 gmt                       : "/sim/time/gmt",
                 gmt_string                : "/sim/time/gmt-string",
                 groundspeed_kt            : "/velocities/groundspeed-kt",
                 gun_rounds                : "/sim/model/f16/systems/gun/rounds",
                 heading                   : "/orientation/heading-deg",
                 mach                      : "/instrumentation/airspeed-indicator/indicated-mach",
                 measured_altitude         : "/instrumentation/altimeter/indicated-altitude-ft",
                 pitch                     : "/orientation/pitch-deg",
                 radar_range               : "/instrumentation/radar/radar2-range",
                 nav_range                 : "/autopilot/route-manager/wp/dist",
                 roll                      : "/orientation/roll-deg",
                 route_manager_active      : "/autopilot/route-manager/active",
                 speed                     : "/fdm/jsbsim/velocities/vt-fps",
                 symbol_reject             : "/controls/HUD/sym-rej",
                 target_display            : "/sim/model/f16/instrumentation/radar-awg-9/hud/target-display",
                 v                         : "/fdm/jsbsim/velocities/v-fps",
                 vc_kts                    : "/fdm/jsbsim/velocities/vc-kts",
                 view_internal             : "/sim/current-view/internal",
                 w                         : "/fdm/jsbsim/velocities/w-fps",
                 weapon_mode               : "/sim/model/f16/controls/armament/weapon-selector",
                 wow                       : "/fdm/jsbsim/gear/wow",
                 yaw                       : "/fdm/jsbsim/aero/beta-deg",
                };

        foreach (var name; keys(input)) {
            emesary.GlobalTransmitter.NotifyAll(notifications.FrameNotificationAddProperty.new(_ident,name, input[name]));
        }

        #
        # recipient that will be registered on the global transmitter and connect this
        # subsystem to allow subsystem notifications to be received
        obj.recipient = emesary.Recipient.new(_ident~".Subsystem");
        obj.recipient.Main = obj;

        obj.recipient.Receive = func(notification)
        {
            if (notification.NotificationType == "FrameNotification")
            {
                me.Main.update(notification);
                ownship_pos.set_latlon(getprop("position/latitude-deg"), getprop("position/longitude-deg"), getprop("position/altitude-ft")*FT2M);
                notification.ownship_pos = ownship_pos;
                return emesary.Transmitter.ReceiptStatus_OK;
            }
            return emesary.Transmitter.ReceiptStatus_NotProcessed;
        };
        emesary.GlobalTransmitter.Register(obj.recipient);

		return obj;
	},
    update : func(notification) {
    },
};

subsystem = SubSystem_Main.new("SubSystem_Main");



var reloadCannon = func {
    setprop("ai/submodels/submodel[0]/count", 100);#flares
    pylons.cannon.reloadAmmo();
}

var reloadHydras = func {
    pylons.hyd70lh3.reloadAmmo();
    pylons.hyd70rh3.reloadAmmo();
    pylons.hyd70lh7.reloadAmmo();
    pylons.hyd70rh7.reloadAmmo();
}

var eject = func{
  if (getprop("f16/ejected")==1 or !getprop("controls/seat/ejection-safety-lever")) {
      return;
  }
  # ACES II activation
  view.setViewByIndex(1);
  setprop("f16/ejected",1);
  settimer(eject2, 1.5);# this is to give the sim time to load the exterior view, so there is no stutter while seat fires and it gets stuck.
}

var eject2 = func{
  setprop("canopy/not-serviceable", 1);
  var es = armament.AIM.new(10, "es","gamma", nil ,[-3.65,0,0.7]);
  #setprop("fdm/jsbsim/fcs/canopy/hinges/serviceable",0);
  es.releaseAtNothing();
  view.view_firing_missile(es);
  #setprop("sim/view[0]/enabled",0); #disabled since it might get saved so user gets no pilotview in next aircraft he flies in.
  settimer(func {crash.exp();},3.5);
}

var chute = func{
  if (getprop("f16/chute/done") or getprop("fdm/jsbsim/elec/bus/batt-1") < 20) {
      return;
  }
  chuteLoop.start();
}

var chuteLoopFunc = func{
  if (getprop("f16/chute/repack")) {
    setprop("f16/chute/repack", 0);
	return;
  }
  if (!getprop("sim/model/f16/dragchute") or (!getprop("f16/chute/enable") and getprop("f16/chute/done"))) {
	  chuteLoop.stop();
      return;
  } elsif (!getprop("f16/chute/enable")) {
    setprop("f16/chute/done", 1);
    setprop("f16/chute/enable", 1);
    setprop("f16/chute/force", 2);
    setprop("f16/chute/fold", 0);
  } else {
    if (getprop("/velocities/airspeed-kt") > 250) {
      setprop("f16/chute/fold", 1);
      setprop("fdm/jsbsim/external_reactions/chute/magnitude", 0);
      settimer(chuteRelease, 2.0);
	  chuteLoop.stop();
      return;
    } elsif (getprop("/velocities/groundspeed-kt") <= 25) {
      setprop("f16/chute/fold",1-getprop("/velocities/groundspeed-kt") / 25);
    }
    var pressure = getprop("fdm/jsbsim/aero/qbar-psf"); # dynamic pressure
    var chuteArea = 200; # squarefeet of chute canopy
    var dragCoeff = 0.50;
    var force     = pressure * chuteArea * dragCoeff;
    setprop("fdm/jsbsim/external_reactions/chute/magnitude", force);
    setprop("f16/chute/force", 0, force * 0.000154);
  }
}

var chuteRelease = func{
  setprop("f16/chute/enable", 0);
}

# used in left panel knobs anims.
var freqDigits = func {
    var freq = getprop("instrumentation/nav[0]/frequencies/selected-mhz");
    freq = roundabout(freq*100)*0.01;
    var a = int(roundabout((freq*10-int(freq*10))*10));
    var b = int(roundabout((freq*1-int(freq*1))*10-0.1*a));
    var c = int((freq*0.1-int(freq*0.1))*10);
    var d = int((freq*0.01-int(freq*0.01))*10);
    var e = int((freq*0.001-int(freq*0.001))*10);
    setprop("instrumentation/nav[0]/frequencies/current-mhz-digit-1", a);
    setprop("instrumentation/nav[0]/frequencies/current-mhz-digit-2", b);
    setprop("instrumentation/nav[0]/frequencies/current-mhz-digit-3", c);
    setprop("instrumentation/nav[0]/frequencies/current-mhz-digit-4", d);
    setprop("instrumentation/nav[0]/frequencies/current-mhz-digit-5", e);
    settimer(freqDigits, 0.2);
}
var roundabout = func(x) {
  var y = x - int(x);
  return y < 0.5 ? int(x) : 1 + int(x) ;
};
freqDigits();

# pilot view that translates left or right depending on view direction.
var pilot_view_limiter = {
  new : func {
    return { parents: [pilot_view_limiter] };
  },
  init : func {
    me.hdgN = props.globals.getNode("/sim/current-view/heading-offset-deg");
    me.xoffsetN = props.globals.getNode("/sim/current-view/x-offset-m");
    me.xoffset_lowpass = aircraft.lowpass.new(0.1);
    me.last_offset = 0;
    me.needs_start = 0;
  },
  start : func {
    var limits = view.current.getNode("config/limits", 1);
    me.left = {
      heading_max : math.abs(limits.getNode("left/heading-max-deg", 1).getValue() or 1000),
      threshold : math.abs(limits.getNode("left/x-offset-threshold-deg", 1).getValue() or 0),
      xoffset_max : math.abs(limits.getNode("left/x-offset-max-m", 1).getValue() or 0),
      xoffset_t_max : math.abs(limits.getNode("left/x-offset-threshold-max-m", 1).getValue() or 0),
    };
    me.right = {
      heading_max : -math.abs(limits.getNode("right/heading-max-deg", 1).getValue() or 1000),
      threshold : -math.abs(limits.getNode("right/x-offset-threshold-deg", 1).getValue() or 0),
      xoffset_max : -math.abs(limits.getNode("right/x-offset-max-m", 1).getValue() or 0),
      xoffset_t_max : -math.abs(limits.getNode("right/x-offset-threshold-max-m", 1).getValue() or 0),
    };
    me.left.scale = me.left.xoffset_t_max / me.left.threshold;
    me.right.scale = me.right.xoffset_t_max / me.right.threshold;
    me.last_hdg = geo.normdeg180(me.hdgN.getValue());
    me.enable_xoffset = me.right.xoffset_t_max > 0.001 or me.left.xoffset_t_max > 0.001;

    me.needs_start = 0;
  },
  update : func {
    if (getprop("/devices/status/keyboard/ctrl"))
      return;

    if( getprop("/sim/signals/reinit") )
    {
      me.needs_start = 1;
      return;
    }
    else if( me.needs_start )
      me.start();

    var hdg = geo.normdeg180(me.hdgN.getValue());
    if (math.abs(me.last_hdg - hdg) > 180) { # avoid wrap-around skips
      me.hdgN.setDoubleValue(hdg = me.last_hdg);
      #print("wrap skip");
    } elsif (hdg > me.left.heading_max) {
      me.hdgN.setDoubleValue(hdg = me.left.heading_max);
      #print("wrap left");
    } elsif (hdg < me.right.heading_max) {
      me.hdgN.setDoubleValue(hdg = me.right.heading_max);
      #print("wrap right");
    }
    me.last_hdg = hdg;

    # translate view on X axis to look far right or far left
    if (me.enable_xoffset) {
      var offset = 0;
      #print(hdg~" "~me.left.threshold);
      if (hdg > 0 and hdg < me.left.threshold)
        offset = -hdg * me.left.scale;
      elsif (hdg > 0)
        offset = -(me.left.xoffset_t_max+(me.left.xoffset_max-me.left.xoffset_t_max)*(hdg-me.left.threshold)/(me.left.heading_max-me.left.threshold));
      elsif (hdg < 0 and hdg > me.right.threshold)
        offset = -hdg * me.right.scale;
      elsif (hdg < 0)
        offset = -(me.right.xoffset_t_max+(me.right.xoffset_max-me.right.xoffset_t_max)*(hdg-me.right.threshold)/(me.right.heading_max-me.right.threshold));

      var new_offset = me.xoffset_lowpass.filter(offset);
      me.xoffsetN.setDoubleValue(me.xoffsetN.getValue() - me.last_offset + new_offset);
      me.last_offset = new_offset;
    }
    return 0;
  },
};

dynamic_view.view_manager.noGforce = func {
  if (getprop("sim/current-view/view-number") !=0 ) {
    me.pitch_offset = 0;
    me.heading_offset = 0;
    me.roll_offset = 0;
    return;
  }
  var wow = me.wow.get();

  # calculate steering factor
  var hdg = me.headingN.getValue();
  var hdiff = dynamic_view.normdeg(me.last_heading - hdg);
  me.last_heading = hdg;
  var steering = 0; # normatan(me.hdg_change.filter(hdiff)) * me.size_factor;

  var az = me.az.get();
  var vx = me.vx.get();

  # calculate sideslip factor (zeroed when no forward ground speed)
  var wspd = me.wind_speedN.getValue();
  var wdir = me.headingN.getValue() - me.wind_dirN.getValue();
  var u = vx - wspd * dynamic_view.cos(wdir);
  var slip = dynamic_view.sin(me.slipN.getValue()) * me.ubody.filter(dynamic_view.normatan(u / 10));

  me.heading_offset =             # view heading
    -15 * dynamic_view.sin(me.roll) * dynamic_view.cos(me.pitch)        #     due to roll
    + 40 * steering * wow           #     due to ground steering
    + 10 * slip * (1 - wow);          #     due to sideslip (in air)

  me.pitch_offset =             # view pitch
    10 * dynamic_view.sin(me.roll) * dynamic_view.sin(me.roll)        #     due to roll
    + 30 * (1 / (1 + math.exp(2 - az))        #     due to G load
      - 0.119202922);           #         [move to origin; 1/(1+exp(2)) ]

  me.roll_offset = 0;
}

dynamic_view.register(func {me.noGforce();});# no G-force head movement in goPro views even though they are internal.



# Probe heat switch
var probe_heat_switch = props.globals.getNode("/f16/avionics/probe-heat-switch");
var probe_heat_light = props.globals.getNode("/f16/avionics/caution/probe-heat");
setlistener("/f16/avionics/probe-heat-switch", func() {
	if (probe_heat_switch.getValue() == -1) {
		flashTimer.start();
	} else {
		flashTimer.stop();
		probe_heat_light.setBoolValue(0);
	}
}, 0, 0);

var flashLoop = func() {
	probe_heat_light.setBoolValue(!probe_heat_light.getBoolValue());
}

var flashTimer = maketimer(0.15, flashLoop);



## Following code adapted from script shared by Warty at https://forum.flightgear.org/viewtopic.php?f=10&t=28665
## (C) pinto aka Justin Nicholson - 2016
## GPL v2

var updateRater = 2;

var ignoreLoop = func () {
  if (getprop("sim/multiplay/txhost") != "mpserver.opredflag.com") {
    var trolls = [
                  getprop("ignore-list/troll-1"),
                  getprop("ignore-list/troll-2"),
                  getprop("ignore-list/troll-3"),
                  getprop("ignore-list/troll-4"),
                  getprop("ignore-list/troll-5"),
                  getprop("ignore-list/troll-6")];
    var listMP = props.globals.getNode("ai/models/").getChildren("multiplayer");
    foreach (m; listMP) {
      var thisCallsign = m.getValue("callsign");
      if(thisCallsign != nil and thisCallsign != "") {
        var clear = 1;
        foreach(csToIgnore; trolls){
          if(thisCallsign == csToIgnore){
            setInvisible(m);
            clear = 0;
          }
        }
        if (clear) {
          if (contains(multiplayer.ignore, thisCallsign)) {
              delete(multiplayer.ignore, thisCallsign);
          }
          m.setValue("controls/invisible", 0);
        }
      }
    }
  }
  settimer( func { ignoreLoop(); }, updateRater);
}

var setInvisible = func (m) {
  var currentlyInvisible = m.getValue("controls/invisible");
  if(!currentlyInvisible){
    var thisCallsign = m.getValue("callsign");
    if (thisCallsign != "" and thisCallsign != nil) {
      multiplayer.ignore[thisCallsign] = 1;
      #multiplayer.dialog.toggle_ignore(thisCallsign);
      m.setValue("controls/invisible",1);
      screen.log.write("Automatically ignoring " ~ thisCallsign ~ ".");
    }
  }
}

settimer( func { ignoreLoop(); }, 5);

setlistener("controls/flight/alt-rel-button", func (node) {setprop("controls/armament/trigger", node.getValue());});

var SOI = int(rand() * 3)+1; # 1 to 3

var MFDControlsNodes = {
	dmsX: props.globals.getNode("controls/displays/display-management-switch-x"),
	dmsY: props.globals.getNode("controls/displays/display-management-switch-y"),
	tgtX: props.globals.getNode("controls/displays/cursor-slew-x-delta"),
	tgtY: props.globals.getNode("controls/displays/cursor-slew-y-delta"),
};

setlistener("/controls/displays/display-management-switch-x", func() {
	if (MFDControlsNodes.dmsY.getValue() != 0) { return; }
	if (MFDControlsNodes.dmsX.getValue() == 0) { return; }
}, 0, 0);

setlistener("controls/displays/cursor-slew-x-delta", func() {
	if (SOI == 1) { return; }
	setprop("controls/displays/target-management-switch-x[" ~ (SOI - 2) ~ "]", MFDControlsNodes.tgtX.getValue());
}, 0, 0);

var resetSlew = func {
  setprop("controls/displays/cursor-slew-x-delta",0);
  setprop("controls/displays/cursor-slew-y-delta",0);
}

setlistener("controls/displays/display-management-switch-y", func() {
	if (MFDControlsNodes.dmsX.getValue() != 0) { return; }
	if (MFDControlsNodes.dmsY.getValue() == 0) { return; }
	if (MFDControlsNodes.dmsY.getValue() == -1) {
		SOI = 1;
	} else {
		if (SOI == 1) {
			SOI = 2;
		} elsif (SOI == 2) {
			SOI = 3;
		} else {
			SOI = 2;
		}
	}
}, 0, 0);

setlistener("controls/displays/cursor-slew-y-delta", func() {
	if (SOI == 1) { return; }
	setprop("controls/displays/target-management-switch-y[" ~ (SOI - 2) ~ "]", MFDControlsNodes.tgtY.getValue());
}, 0, 0);

setlistener("controls/displays/cursor-click", func() {
	if (SOI == 1) { return; }
}, 0, 0);

var secSelfTest = 0;
setlistener("f16/engine/cutoff-release-lever", func() {
	if (!getprop("f16/engine/cutoff-release-lever") and !secSelfTest) {
		secSelfTest = 1;
		setprop("f16/engine/sec-self-test", 1);
		settimer(func() {
			setprop("f16/engine/sec-self-test", 0);
			secSelfTest = 0;
		}, 3);
	}
}, 0, 0);

var setup_custom_stick_bindings = func {
  call(func {
      append(joystick.buttonBindings, joystick.NasalHoldButton.new  ("Cursor Click", 'setprop("controls/displays/cursor-click",1);', 'setprop("controls/displays/cursor-click",0);'));
      append(joystick.axisBindings,   joystick.PropertyScaleAxis.new("Cursor Vertical", "/controls/displays/cursor-slew-y"));
      append(joystick.axisBindings,   joystick.PropertyScaleAxis.new("Cursor Horizontal", "/controls/displays/cursor-slew-x"));
  },nil,var err=[]);
  var dlg = gui.Dialog.new("/sim/gui/dialogs/button-axis-config/dialog", "Aircraft/f16/gui/dialogs/button-axis-config.xml", "button-axis-config");
  var dlg = gui.Dialog.new("/sim/gui/dialogs/button-config/dialog", "Aircraft/f16/gui/dialogs/button-config.xml", "button-config");
}

# EPU pin handler
var epu_pin_listener = setlistener("engines/engine[0]/running", func(runningNode) {
    var running = runningNode.getValue();
    if (running == 1)
    {
        # Simulate pulling of EPU safety pin after engine start.
        setprop("fdm/jsbsim/elec/switches/epu-pin", 0);
    }
}, 0, 0);

var main_init_listener = setlistener("sim/signals/fdm-initialized", func {
  if (getprop("sim/signals/fdm-initialized") == 1) {
    removelistener(main_init_listener);
    print();
    print("********************************************************************");
    print("      Initializing "~getprop("sim/description")~" systems.           ");
    print("                Version "~getprop("sim/aircraft-version")~" on FlightGear "~getprop("sim/version/flightgear"));
    print("********************************************************************");
    print();
    screen.log.write("Welcome to the "~getprop("sim/description")~", version "~getprop("sim/aircraft-version"), 1.0, 0.2, 0.2);
    
    hack.init();
    medium_fast.loop();
    slow.loop();
    #fx = flex.WingFlexer.new(1, 250, 25, 500, 0.375, "f16/wings/fuel-and-stores-kg","f16/wings/fuel-and-stores-kg","sim/systems/wingflexer/","f16/wings/lift-lbf");
    flexer();
    medium.loop();
    fast.loop();
    ehsi.init();
    tgp.callInit();
    tgp.fast_loop();
    ded.dataEntryDisplay.init();
    ded.dataEntryDisplay.update();
    pfd.callInit();
    pfd.loop_pfd();
    frd.callInit();
    frd.loop_freqDsply();
    mps.loop();
    start.enableViews();
    fail.init();
    awg_9.loopDGFT();
    eng.JFS.init();
    autopilot_inhibit.init();
    setup_custom_stick_bindings();
    setprop("consumables/fuel/tank[6]/capacity-gal_us",0);
    setprop("consumables/fuel/tank[7]/capacity-gal_us",0);
    setprop("consumables/fuel/tank[8]/capacity-gal_us",0);
    setprop("/consumables/fuel/total-fuel-lbs-1", 8); # Show some other, random, value instead of 000000
    setprop("/consumables/fuel/total-fuel-lbs-10", 20);
    setprop("/consumables/fuel/total-fuel-lbs-100", 700);
    setprop("/consumables/fuel/total-fuel-lbs-1000", 1000);
    if (getprop("f16/disable-custom-view") != 1) view.manager.register("Cockpit View", pilot_view_limiter);
    emesary.GlobalTransmitter.Register(f16_mfd);
    emesary.GlobalTransmitter.Register(f16_hud);
    emesary.GlobalTransmitter.Register(awg_9.aircraft_radar);
    #execTimer.start();
    rtExec_loop();
    
    # Setup F-16 custom ATC chat menu:
    var chatNode = props.globals.getNode("/sim/multiplay/chat-menu");
    chatNode.removeAllChildren();
    call(func{fgcommand('loadxml', props.Node.new({ filename: getprop("/sim/aircraft-dir") ~ "/Systems/f16-chat-menu-entries.xml", targetnode: "sim/multiplay/chat-menu" }));},nil,var err= []);
    
    # Engine running, setup some stuff:
    if (getprop("f16/engine/running-state")) {
      #skip warmup if not cold and dark selected from launcher.
      setprop("/f16/avionics/power-fcr-warm", 1);
      setprop("/f16/avionics/power-rdr-alt-warm", 1);
      setprop("/f16/avionics/power-ufc-warm", 1);
      setprop("/f16/avionics/power-mfd-warm", 1);  # Can't force an actuator
    }
    setprop("/f16/cockpit/oxygen-liters", 5.0);
    setprop("f16/cockpit/hydrazine-minutes", 10);
    
    # debug:
    #
    #screen.property_display.add("fdm/jsbsim/fcs/fly-by-wire/pitch/pitch-rate-lower-lag");
    #screen.property_display.add("fdm/jsbsim/fcs/fly-by-wire/pitch/bias-final");
  }
 }, 0, 0);

var chuteLoop = maketimer(0.05, chuteLoopFunc);

# Switch to ext. view for short time to make sure to not get big stutter when switching in-flight.
var load_interior = func {
    view.setViewByIndex(0);
}
settimer(load_interior, 0.5, 1);
view.setViewByIndex(1);
