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
  var airspeed = getprop("instrumentation/airspeed-indicator/indicated-speed-kt");
  var vne      = getprop("limits-custom/vne");
  

  if ((airspeed != nil) and (vne != nil) and (airspeed > vne))
  {
    msg = "Airspeed exceeds Vne!";
    setprop("f16/vne",1);
  } elsif ((airspeedM != nil) and (vneM != nil) and (airspeedM > vneM)) {
    msg = "Airspeed exceeds Vne!";
    setprop("f16/vne",1);
  }  else {
    setprop("f16/vne",0);
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
    interpolate("sim/current-view/y-offset-m", 0.81, 1); 
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
      #call(func{fgcommand('dialog-close', multiplayer.dialog.dialog.prop())},nil,var err= []);# props.Node.new({"dialog-name": "location-in-air"}));
      call(func{multiplayer.dialog.del();},nil,var err= []);
      if (!getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        call(func{fgcommand('dialog-close', props.Node.new({"dialog-name": "WeightAndFuel"}))},nil,var err2 = []);          
      }      
      setprop("/sim/speed-up", 1);
      setprop("/sim/rendering/als-filters/use-filtering", 1);
    }

    settimer(loop_flare, 0.10);
};

var medium = {
  loop: func {
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
    if (pylons.fcs != nil) {
      setprop("f16/stores-cat", pylons.fcs.getCategory());
      } else {
        setprop("f16/stores-cat", 1);
      }

    if (getprop("controls/lighting/ext-lighting-panel/anti-collision") == 1 and getprop("controls/lighting/ext-lighting-panel/master") == 1) {
      setprop("controls/lighting/ext-lighting-panel/anti-collision2",1);
    } else {
      setprop("controls/lighting/ext-lighting-panel/anti-collision2",0);
    }
    settimer(func {me.loop()},0.5);
  },
};

var main_init_listener = setlistener("sim/signals/fdm-initialized", func {
  if (getprop("sim/signals/fdm-initialized") == 1) {
    removelistener(main_init_listener);
   loop_flare();
   medium.loop();   
  }
 }, 0, 0);


var repair = func {
  if (getprop("payload/armament/msg")==1 and !getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
    screen.log.write(msgA);
  } else {
    repair2();
  }
}

var repair2 = func {
  screen.log.write("Repairing, standby..");
  setprop("ai/submodels/submodel[0]/count",100);
  crash.repair();
  if (getprop("engines/engine[0]/running")!=1) {
    setprop("controls/engines/engine[0]/cutoff", 1);
    setprop("controls/engines/engine[0]/starter", 1);
    settimer(repair3, 10);
  } else {
    screen.log.write("Done.");
  }
}

var repair3 = func {
  setprop("controls/engines/engine[0]/cutoff", 0);
  screen.log.write("Attempting engine restart, standby for engine..");
}

var re_init_listener = setlistener("/sim/signals/reinit", func {
  if (getprop("/sim/signals/reinit") != 0) {
    setprop("/controls/gear/gear-down",1);
    setprop("/controls/gear/brake-parking",1);
    if (getprop("/consumables/fuel/tank[0]/level-norm")<0.5) {
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

