# $Id$

var TRUE = 1;
var FALSE = 0;

# strobes ===========================================================
var strobe_switch = props.globals.getNode("controls/lighting/ext-lighting-panel/anti-collision2", 1);
aircraft.light.new("sim/model/lighting/strobe", [0.03, 1.9+rand()/5], strobe_switch);
var msgA = "If you need to repair now, then use Menu-Location-SelectAirport instead.";
var msgB = "Please land before changing payload.";
var cockpit_blink = props.globals.getNode("f16/avionics/cockpit_blink", 1);
aircraft.light.new("f16/avionics/cockpit_blinker", [0.25, 0.25], cockpit_blink);
setprop("f16/avionics/cockpit_blink", 1);

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
  } elsif ((airspeedM != nil) and (vneM != nil) and (airspeedM > vneM)) {
    msg = "Airspeed exceeds Vne!";
    setprop("f16/vne",1);
  } elsif ((nose!=nil and NLG_kt>nose)or (main!=nil and MLG_kt>main)) {
    msg = "Groundspeed exceeds tire limit!";
    setprop("f16/vne",0);
  }  else {
    setprop("f16/vne",0);
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
    interpolate("sim/current-view/y-offset-m", 0.82, 1); 
    interpolate("sim/current-view/z-offset-m", -4, 1);
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
      setprop("/sim/speed-up", 1);
      setprop("/gui/map/draw-traffic", 0);
      setprop("/sim/gui/dialogs/map-canvas/draw-TFC", 0);
      setprop("/sim/rendering/als-filters/use-filtering", 1);
    }
    setprop("sim/multiplay/visibility-range-nm", 150);
    if (getprop("payload/armament/es/flags/deploy-id-10")!= nil) {
      setprop("f16/force", 7-5*getprop("payload/armament/es/flags/deploy-id-10"));
      } else {
        setprop("f16/force", 7);
      }
      
    settimer(loop_flare, 0.10);
};

var medium = {
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
    # Fuel:
    var fuel = getprop("/consumables/fuel/total-fuel-lbs");
    setprop("/consumables/fuel/total-fuel-lbs-1",     int(fuel       )     -int(fuel*0.1)*10);
    setprop("/consumables/fuel/total-fuel-lbs-10",    int(fuel*0.1   )*10  -int(fuel*0.01)*100);
    setprop("/consumables/fuel/total-fuel-lbs-100",   int(fuel*0.01  )*100 -int(fuel*0.001)*1000);
    setprop("/consumables/fuel/total-fuel-lbs-1000",  int(fuel*0.001 )*1000-int(fuel*0.0001)*10000);
    setprop("/consumables/fuel/total-fuel-lbs-10000", int(fuel*0.0001)*10000);
    if (fuel<500) {
      setprop("f16/avionics/bingo", 1);
    } else {
      setprop("f16/avionics/bingo", 0);
    }
    # HUD power:
    if (getprop("fdm/jsbsim/elec/bus/emergency-ac-2")>100 or getprop("fdm/jsbsim/elec/bus/emergency-dc-2")>20) {
      setprop("f16/avionics/hud-power",1);
    } else {
      var ac = getprop("fdm/jsbsim/elec/bus/emergency-ac-2")/100;
      var dc = getprop("fdm/jsbsim/elec/bus/emergency-dc-2")/20;
      var power = ac;
      if (ac < dc) {
        power=dc;
      }
      if (power<0.5) {
        power=0;
      }
      setprop("f16/avionics/hud-power",power);
    }
    # engine
    if (getprop("engines/engine[0]/running")) {
      setprop("f16/engine/jet-fuel",0);
    }
    if (getprop("f16/engine/feed")) {
      setprop("controls/engines/engine[0]/cutoff",!getprop("f16/engine/jsf-start"));
      if (getprop("f16/engine/jet-fuel") != 0) {
        setprop("controls/engines/engine[0]/starter", 1);
      } else {
        setprop("controls/engines/engine[0]/starter", 0);
      }
    } else {
      setprop("controls/engines/engine[0]/starter", 0);
      setprop("controls/engines/engine[0]/cutoff", 1);
    }   
    if (getprop("fdm/jsbsim/elec/bus/batt-2")<20) {
      setprop("controls/test/test-panel/mal-ind-lts", 0);
    }
    
    batteryChargeDischarge(); ########## To work optimally, should run at or below 0.5 in a loop ##########
    
    sendLightsToMp();
    sendABtoMP();

    settimer(func {me.loop()},0.5);
  },
};

var sendABtoMP = func {
  var red = getprop("rendering/scene/diffuse/red");
  setprop("sim/multiplay/generic/float[10]",  1-red*0.75);

  setprop("sim/multiplay/generic/float[11]",  0.75+(0.25-red*0.25));
  setprop("sim/multiplay/generic/float[12]",  0.25+(0.75-red*0.75));
  setprop("sim/multiplay/generic/float[13]",  0.2+(0.8-red*0.8));
  setprop("sim/multiplay/generic/float[14]",  1-red);
}

var sendLightsToMp = func {
  var master = getprop("controls/lighting/ext-lighting-panel/master");
  var pos = getprop("controls/lighting/ext-lighting-panel/pos-lights-flash");
  var wing = getprop("controls/lighting/ext-lighting-panel/wing-tail");
  var dc = getprop("fdm/jsbsim/elec/bus/ess-dc");
  var form = getprop("controls/lighting/ext-lighting-panel/form-knob");
  var vi = getprop("sim/model/f16/dragchute");

  if (pos and (wing == 0 or wing == 2) and master and dc > 20) {
    setprop("sim/multiplay/generic/bool[40]",1);
  } else {
    setprop("sim/multiplay/generic/bool[40]",0);
  }

  if (form == 1 and master and dc > 20) {
    setprop("sim/multiplay/generic/bool[41]",1);
  } else {
    setprop("sim/multiplay/generic/bool[41]",0);
  }

  if (form == 1 and master and dc > 20 and vi) {
    setprop("sim/multiplay/generic/bool[42]",1);
  } else {
    setprop("sim/multiplay/generic/bool[42]",0);
  }

  if (form == 1 and master and dc > 20 and !vi) {
    setprop("sim/multiplay/generic/bool[43]",1);
  } else {
    setprop("sim/multiplay/generic/bool[43]",0);
  }

  if (master and dc > 20) {
    setprop("sim/multiplay/generic/bool[44]",1);
  } else {
    setprop("sim/multiplay/generic/bool[44]",0);
  }
}

var batteryChargeDischarge = func {
    var battery_percent = getprop("/fdm/jsbsim/elec/sources/battery-percent");
    var mainpwr_sw = getprop("/fdm/jsbsim/elec/switches/main-pwr");
    if (battery_percent < 100 and getprop("/fdm/jsbsim/elec/bus/charger") >= 20 and getprop("/fdm/jsbsim/elec/failures/battery/serviceable") and mainpwr_sw > 0) {
        if (getprop("/fdm/jsbsim/elec/sources/battery-time") + 5 < getprop("/sim/time/elapsed-sec")) {
            battery_percent_calc = battery_percent + 0.75; # Roughly 90 percent every 10 mins
            if (battery_percent_calc > 100) {
                battery_percent_calc = 100;
            }
            setprop("/fdm/jsbsim/elec/sources/battery-percent", battery_percent_calc);
            setprop("/fdm/jsbsim/elec/sources/battery-time", getprop("/sim/time/elapsed-sec"));
        }
    } else if (battery_percent == 100 and getprop("/fdm/jsbsim/elec/bus/charger") >= 20 and getprop("/fdm/jsbsim/elec/failures/battery/serviceable") and mainpwr_sw > 0) {
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

var main_init_listener = setlistener("sim/signals/fdm-initialized", func {
  if (getprop("sim/signals/fdm-initialized") == 1) {
    removelistener(main_init_listener);
   loop_flare();
   medium.loop();
    print();
    print("***************************************************************");
    print("         Initializing "~getprop("sim/description")~" systems.           ");
    print("           Version "~getprop("sim/aircraft-version")~" on Flightgear "~getprop("sim/version/flightgear"));
    print("***************************************************************");
    print();
    screen.log.write("Welcome to "~getprop("sim/description")~", version "~getprop("sim/aircraft-version"), 1.0, 0.2, 0.2);
  }
 }, 0, 0);


var inAutostart = 0;

var repair = func {
  if (getprop("payload/armament/msg")==1 and !getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
    screen.log.write(msgA);
  } else {
    repair2();
  }
}

var repair2 = func {
  setprop("f16/done",0);
  setprop("f16/chute/done",0);
  setprop("sim/view[0]/enabled",1);
  setprop("sim/current-view/view-number",0);
  if (inAutostart) {
    return;
  }
  inAutostart = 1;
  screen.log.write("Repairing, standby..");
  setprop("ai/submodels/submodel[0]/count",100);
  crash.repair();
  if (getprop("f16/engine/running-state")) {
    setprop("fdm/jsbsim/elec/switches/epu",1);
    setprop("fdm/jsbsim/elec/switches/main-pwr",2);
    if (getprop("engines/engine[0]/running")!=1) {
      setprop("f16/engine/feed",1);
      setprop("f16/engine/jet-fuel",1);
      setprop("f16/engine/jsf-start",0);
      settimer(repair3, 10);
    } else {
      screen.log.write("Done.");
      inAutostart = 0;
    }
  } else {
    screen.log.write("Done.");
    inAutostart = 0;
  }
}

var repair3 = func {
  setprop("f16/engine/jsf-start", 1);
  screen.log.write("Attempting engine start, standby for engine..");
  inAutostart = 0;
}

var autostart = func {
  if (inAutostart) {
    return;
  }
  inAutostart = 1;
  screen.log.write("Starting, standby..");
  setprop("fdm/jsbsim/elec/switches/epu",1);
  setprop("fdm/jsbsim/elec/switches/main-pwr",2);
  if (getprop("engines/engine[0]/running")!=1) {
    setprop("f16/engine/feed",1);
    setprop("f16/engine/jet-fuel",1);
    setprop("f16/engine/jsf-start",0);
    settimer(repair3, 10);
  } else {
    screen.log.write("Done.");
    inAutostart = 0;
  }
}

var re_init_listener = setlistener("/sim/signals/reinit", func {
  if (getprop("/sim/signals/reinit") != 0) {
    setprop("/controls/gear/gear-down",1);
    setprop("/controls/gear/brake-parking",1);
    if (getprop("/consumables/fuel/tank[0]/level-norm")<0.5 and getprop("f16/engine/running-state")) {
      setprop("/consumables/fuel/tank[0]/level-norm", 0.55);
    }
    
    repair2();
  }
 }, 0, 0);

############ Cannon impact messages #####################

var hits_count = 0;
var hit_timer  = FALSE;
var hit_callsign = "";

var impact_listener = func {
  if (awg_9.active_u != nil) {
    var ballistic_name = props.globals.getNode("/ai/models/model-impact").getValue();
    var ballistic = props.globals.getNode(ballistic_name, 0);
    if (ballistic != nil and ballistic.getName() != "munition") {
      var typeNode = ballistic.getNode("impact/type");
      if (typeNode != nil and typeNode.getValue() != "terrain") {
        var lat = ballistic.getNode("impact/latitude-deg").getValue();
        var lon = ballistic.getNode("impact/longitude-deg").getValue();
        var impactPos = geo.Coord.new().set_latlon(lat, lon);

        var selectionPos = awg_9.active_u.get_Coord();

        var distance = impactPos.distance_to(selectionPos);
        if (distance < 75) {
          var typeOrd = ballistic.getNode("name").getValue();
          hits_count += 1;
          if ( hit_timer == FALSE ) {
            hit_timer = TRUE;
            hit_callsign = awg_9.active_u.get_Callsign();
            settimer(func{hitmessage(typeOrd);},1);
          }
        }
      }
    }
  }
}

var hitmessage = func(typeOrd) {
  #print("inside hitmessage");
  var phrase = typeOrd ~ " hit: " ~ hit_callsign ~ ": " ~ hits_count ~ " hits";
  if (getprop("payload/armament/msg") == TRUE) {
    armament.defeatSpamFilter(phrase);
  } else {
    setprop("/sim/messages/atc", phrase);
  }
  hit_callsign = "";
  hit_timer = 0;
  hits_count = 0;
}

# setup impact listener
setlistener("/ai/models/model-impact", impact_listener, 0, 0);

var prop = "payload/armament/fire-control";
var actuator_fc = compat_failure_modes.set_unserviceable(prop);
FailureMgr.add_failure_mode(prop, "Fire control", actuator_fc);

var battery_fc = compat_failure_modes.set_unserviceable("fdm/jsbsim/elec/failures/battery");
FailureMgr.add_failure_mode("fdm/jsbsim/elec/failures/battery", "Battery", battery_fc);

var epu_fc = compat_failure_modes.set_unserviceable("fdm/jsbsim/elec/failures/epu");
FailureMgr.add_failure_mode("fdm/jsbsim/elec/failures/epu", "EPU", epu_fc);

var maingen_fc = compat_failure_modes.set_unserviceable("fdm/jsbsim/elec/failures/main-gen");
FailureMgr.add_failure_mode("fdm/jsbsim/elec/failures/main-gen", "Main Generator", maingen_fc);

var stbygen_fc = compat_failure_modes.set_unserviceable("fdm/jsbsim/elec/failures/stby-gen");
FailureMgr.add_failure_mode("fdm/jsbsim/elec/failures/stby-gen", "Stby Generator", stbygen_fc);

var fire_fc = compat_failure_modes.set_unserviceable("damage/fire");
FailureMgr.add_failure_mode("damage/fire", "Fire", fire_fc);

var hyda_fc = compat_failure_modes.set_unserviceable("systems/hydraulics/edpa-pump");
FailureMgr.add_failure_mode("systems/hydraulics/edpa-pump", "Hydr. pump A", hyda_fc);

var hydb_fc = compat_failure_modes.set_unserviceable("systems/hydraulics/edpb-pump");
FailureMgr.add_failure_mode("systems/hydraulics/edpb-pump", "Hydr. pump B", hydb_fc);

var radar_fc = compat_failure_modes.set_unserviceable("instrumentation/radar");
FailureMgr.add_failure_mode("instrumentation/radar", "Radar", radar_fc);

var rwr_fc = compat_failure_modes.set_unserviceable("instrumentation/rwr");
FailureMgr.add_failure_mode("instrumentation/rwr", "RWR", rwr_fc);


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
#
# Add failure for HUD to the compatible failures. This will setup the property tree in the normal way; 
# but it will not add it to the gui dialog.
append(compat_failure_modes.compat_modes,{ id: "instrumentation/hud", type: compat_failure_modes.MTBF, failure: compat_failure_modes.SERV, desc: "HUD" });

subsystem = SubSystem_Main.new("SubSystem_Main");

########### Thunder sounds (from c172p) ###################

var clamp = func(v, min, max) { v < min ? min : v > max ? max : v };

var speed_of_sound = func (t, re) {
    # Compute speed of sound in m/s
    #
    # t = temperature in Celsius
    # re = amount of water vapor in the air

    # Compute virtual temperature using mixing ratio (amount of water vapor)
    # Ratio of gas constants of dry air and water vapor: 287.058 / 461.5 = 0.622
    var T = 273.15 + t;
    var v_T = T * (1 + re/0.622)/(1 + re);

    # Compute speed of sound using adiabatic index, gas constant of air,
    # and virtual temperature in Kelvin.
    return math.sqrt(1.4 * 287.058 * v_T);
};

var thunder_listener = func {
    var thunderCalls = 0;

    var lightning_pos_x = getprop("/environment/lightning/lightning-pos-x");
    var lightning_pos_y = getprop("/environment/lightning/lightning-pos-y");
    var lightning_distance = math.sqrt(math.pow(lightning_pos_x, 2) + math.pow(lightning_pos_y, 2));

    # On the ground, thunder can be heard up to 16 km. Increase this value
    # a bit because the aircraft is usually in the air.
    if (lightning_distance > 20000)
        return;

    var t = getprop("/environment/temperature-degc");
    var re = getprop("/environment/relative-humidity") / 100;
    var delay_seconds = lightning_distance / speed_of_sound(t, re);

    # Maximum volume at 5000 meter
    var lightning_distance_norm = std.min(1.0, 1 / math.pow(lightning_distance / 5000.0, 2));

    settimer(func {
        var thunder1 = getprop("f16/sound/thunder1");
        var thunder2 = getprop("f16/sound/thunder2");
        var thunder3 = getprop("f16/sound/thunder3");
        var vol = 0;
        if(getprop("sim/current-view/internal") != nil and getprop("canopy/position-norm") != nil) {
          vol = clamp(1-(getprop("sim/current-view/internal")*0.5)+(getprop("canopy/position-norm")*0.5), 0, 1);
        } else {
          vol = 0;
        }
        if (!thunder1) {
            thunderCalls = 1;
            setprop("f16/sound/dist-thunder1", lightning_distance_norm * vol * 2.25);
        }
        else if (!thunder2) {
            thunderCalls = 2;
            setprop("f16/sound/dist-thunder2", lightning_distance_norm * vol * 2.25);
        }
        else if (!thunder3) {
            thunderCalls = 3;
            setprop("f16/sound/dist-thunder3", lightning_distance_norm * vol * 2.25);
        }
        else
            return;

        # Play the sound (sound files are about 9 seconds)
        play_thunder("thunder" ~ thunderCalls, 9.0, 0);
    }, delay_seconds);
};

var play_thunder = func (name, timeout=0.1, delay=0) {
    var sound_prop = "/f16/sound/" ~ name;

    settimer(func {
        # Play the sound
        setprop(sound_prop, TRUE);

        # Reset the property after timeout so that the sound can be
        # played again.
        settimer(func {
            setprop(sound_prop, FALSE);
        }, timeout);
    }, delay);
};

setlistener("/environment/lightning/lightning-pos-y", thunder_listener);

var eject = func{
  if (getprop("f16/done")==1 or !getprop("controls/seat/ejection-safety-lever")) {
      return;
  }
  setprop("f16/done",1);
  var es = armament.AIM.new(10, "es","gamma", nil ,[-3.65,0,0.7]);
  #setprop("fdm/jsbsim/fcs/canopy/hinges/serviceable",0);
  es.releaseAtNothing();
  view.view_firing_missile(es);
  #setprop("sim/view[0]/enabled",0); #disabled since it might get saved so user gets no pilotview in next aircraft he flies in.
  settimer(func {crash.exp();},3.5);
}

var chute = func{
  if (getprop("f16/chute/done")==1) {
      return;
  }
  chute1();
}

var chute1 = func{
  if (!getprop("sim/model/f16/dragchute") or (getprop("f16/chute/enable")==0 and getprop("f16/chute/done")==1)) {
      return;
  } elsif (getprop("f16/chute/enable")==0) {
    setprop("f16/chute/done",1);
    setprop("f16/chute/enable",1);
    setprop("f16/chute/force",2);
    setprop("f16/chute/fold",0);
  } else {
    if (getprop("/velocities/groundspeed-kt")<=3 or getprop("/velocities/airspeed-kt")>250) {
      setprop("f16/chute/fold",1);
      setprop("fdm/jsbsim/external_reactions/chute/magnitude", 0);
      settimer(chute2,2.0);
      return;
    } elsif (getprop("/velocities/groundspeed-kt")<=25) {
      setprop("f16/chute/fold",1-getprop("/velocities/groundspeed-kt")/25);
    }
    var pressure = getprop("fdm/jsbsim/aero/qbar-psf");#dynamic
    var chuteArea = 200;#squarefeet of chute canopy
    var dragCoeff = 0.50;
    var force     = pressure*chuteArea*dragCoeff;
    setprop("fdm/jsbsim/external_reactions/chute/magnitude", force);
    setprop("f16/chute/force", 0,force*0.000154);
  }
  settimer(chute1,0.05);
}

var chute2 = func{
  setprop("fdm/jsbsim/external_reactions/chute/magnitude", 0);
  setprop("f16/chute/enable",0);
}