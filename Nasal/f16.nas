# $Id$

var TRUE = 1;
var FALSE = 0;

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
    interpolate("sim/current-view/y-offset-m", 0.85, 1); 
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
        if (flareCount > 0 and getprop("fdm/jsbsim/elec/bus/emergency-dc-2")>20) {
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
      call(func{var interfaceController = fg1000.GenericInterfaceController.getOrCreateInstance();
      interfaceController.stop();},nil,var err2=[]);
    }
    setprop("sim/multiplay/visibility-range-nm", 160);
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
    if (getprop("fdm/jsbsim/elec/bus/emergency-ac-1")<100) {
      setprop("controls/lighting/lighting-panel/console-primary", 0);
      setprop("controls/lighting/lighting-panel/pri-inst-pnl", 0);
    } else {
      setprop("controls/lighting/lighting-panel/console-primary", getprop("controls/lighting/lighting-panel/console-primary-knob"));
      setprop("controls/lighting/lighting-panel/pri-inst-pnl", getprop("controls/lighting/lighting-panel/pri-inst-pnl-knob"));
    }

    setprop("f16/external", !getprop("sim/current-view/internal"));
    
    setprop("sim/multiplay/generic/float[19]",  getprop("controls/engines/engine/throttle"));
    
    
      
    settimer(loop_flare, 0.10);
};

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
      if (!getprop("instrumentation/tacan/in-range")) {
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
    # engine
    if (getprop("engines/engine[0]/running")) {
      setprop("f16/engine/jet-fuel",0);
    }
    if (getprop("f16/engine/feed")) {
      setprop("controls/engines/engine[0]/cutoff",!getprop("f16/engine/jfs-start"));
      if (getprop("f16/engine/jet-fuel") != 0) {
        setprop("controls/engines/engine[0]/starter", 1);
      } else {
        setprop("controls/engines/engine[0]/starter", 0);
      }
    } else {
      setprop("controls/engines/engine[0]/starter", 0);
      setprop("controls/engines/engine[0]/cutoff", 1);
    }   
    if (getprop("fdm/jsbsim/elec/bus/emergency-dc-1")<20) {
      setprop("controls/test/test-panel/mal-ind-lts", 0);
    }
    
    batteryChargeDischarge(); ########## To work optimally, should run at or below 0.5 in a loop ##########
    
    sendLightsToMp();
    sendABtoMP();
    CARA();
    buffeting();
    fuelqty();
    settimer(func {me.loop()},0.5);
  },
};

var slow = {
  loop: func {
    var valid = 0;
    if (awg_9.active_u != nil) {
      valid = iff.interrogate(awg_9.active_u.propNode);
    }
    setprop("instrumentation/iff/response", valid);
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
    if (getprop("fdm/jsbsim/elec/bus/emergency-dc-1")<20) {#TODO: this hack should be done proper.
        setprop("controls/test/test-panel/mal-ind-lts", 0);
    }
    settimer(func {me.loop()},0.05);
  },
};

var sendABtoMP = func {
  var red = getprop("rendering/scene/diffuse/red");
  
  # non-tied property for effect:
  setprop("rendering/scene/diffuse/red-unbound", red);
  
  # afterburner density:
  setprop("sim/multiplay/generic/float[10]",  1-red*0.75);
  
  #color of afterburner:
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
  var fuse = getprop("controls/lighting/ext-lighting-panel/fuselage");#white flood light mounted leading edge of tail
  var form = getprop("controls/lighting/ext-lighting-panel/form-knob");#white formation lights on top and bottom
  var strobe = getprop("controls/lighting/ext-lighting-panel/anti-collision");#white flashing light at top of tail
  var ar = getprop("controls/lighting/ext-lighting-panel/ar-knob");#flood light in hatch of refuel ext. panel
  var land = getprop("controls/lighting/landing-light");# LAND: white bright light pointed downward in fwd gear door (1). TAXI: white light in fwd gear door (-1)

  var ac_non_ess_2 = getprop("fdm/jsbsim/elec/bus/noness-ac-2");# FORM and TAXI (I added fuselage to this as well)
  var ac_em_2 = getprop("fdm/jsbsim/elec/bus/emergency-ac-2");# POS, ANTICOLL and LAND

  var vi = getprop("sim/model/f16/dragchute");#elongated tailroot
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

  if ((wing == -1 or wing == 1) and master and ac_em_2 > 100 and (!getprop("sim/multiplay/generic/bool[40]") or !flash)) {
    setprop("sim/multiplay/generic/bool[40]",1);#on/off for wingtip and inlet sides.
    setprop("sim/multiplay/generic/float[9]",0.60+wing*0.40);#brightness for wingtip, back of tail and inlet sides.
      if (vi) {
        # tail light with dragchute
        setprop("sim/multiplay/generic/bool[42]",1);
      } else {
        setprop("sim/multiplay/generic/bool[42]",0);
      }

      if (!vi) {
        # tail light without dragchute
        setprop("sim/multiplay/generic/bool[43]",1);
      } else {
        setprop("sim/multiplay/generic/bool[43]",0);
      }
  } else {
    setprop("sim/multiplay/generic/bool[40]",0);
    setprop("sim/multiplay/generic/bool[42]",0);
    setprop("sim/multiplay/generic/bool[43]",0);
    setprop("sim/multiplay/generic/float[9]",0.001);
  }

  if (form > 0 and master and ac_non_ess_2 > 100) {
    # belly and spine lights
    setprop("sim/multiplay/generic/bool[41]",1);
    setprop("sim/multiplay/generic/float[8]",form);
  } else {
    setprop("sim/multiplay/generic/bool[41]",0);
    setprop("sim/multiplay/generic/float[8]",0.001);
  }
  
  if ((fuse == -1 or fuse == 1) and master and ac_non_ess_2 > 100) {
    # fuselage flood
    setprop("sim/multiplay/generic/bool[48]",1);
    setprop("sim/multiplay/generic/float[15]",0.60+fuse*0.40);
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

var fuelqty = func {
  var sel = getprop("controls/fuel/qty-selector");
  var fuel = getprop("/consumables/fuel/total-fuel-lbs");

  if (fuel<getprop("f16/settings/bingo")) {
    setprop("f16/avionics/bingo", 1);
  } else {
    setprop("f16/avionics/bingo", 0);
  }
  if (!getprop("consumables/fuel-tanks/serviceable")) {
    props.globals.getNode("fdm/jsbsim/propulsion/fuel_dump").setBoolValue(1);
  } else {
    props.globals.getNode("fdm/jsbsim/propulsion/fuel_dump").clearValue();
  }
  if (getprop("fdm/jsbsim/elec/bus/emergency-ac-2")<100) {
    return;
  }
  if (sel == 0) {
    # test
    setprop("f16/fuel/hand-fwd", 2000);
    setprop("f16/fuel/hand-aft", 2000);
    fuel = 6000;
  } elsif (sel == 1) {
    #norm
    setprop("f16/fuel/hand-fwd", getprop("consumables/fuel/tank[0]/level-lbs"));
    setprop("f16/fuel/hand-aft", getprop("consumables/fuel/tank[1]/level-lbs"));
  } elsif (sel == 2) {
    #reservoir tanks
    setprop("f16/fuel/hand-fwd", 0);
    setprop("f16/fuel/hand-aft", 0);
  } elsif (sel == 3) {
    # int wing
    setprop("f16/fuel/hand-fwd", getprop("consumables/fuel/tank[6]/level-lbs"));
    setprop("f16/fuel/hand-aft", getprop("consumables/fuel/tank[5]/level-lbs"));
  } elsif (sel == 4) {
    # ext wing
    setprop("f16/fuel/hand-fwd", getprop("consumables/fuel/tank[3]/level-lbs"));
    setprop("f16/fuel/hand-aft", getprop("consumables/fuel/tank[2]/level-lbs"));
  } elsif (sel == 5) {
    # ext center
    setprop("f16/fuel/hand-fwd", getprop("consumables/fuel/tank[4]/level-lbs"));
    setprop("f16/fuel/hand-aft", 0);
  }
  setprop("/consumables/fuel/total-fuel-lbs-1",     int(fuel       )     -int(fuel*0.1)*10);
  setprop("/consumables/fuel/total-fuel-lbs-10",    int(fuel*0.1   )*10  -int(fuel*0.01)*100);
  setprop("/consumables/fuel/total-fuel-lbs-100",   int(fuel*0.01  )*100 -int(fuel*0.001)*1000);
  setprop("/consumables/fuel/total-fuel-lbs-1000",  int(fuel*0.001 )*1000-int(fuel*0.0001)*10000);
  setprop("/consumables/fuel/total-fuel-lbs-10000", int(fuel*0.0001)*10000);
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

var main_init_listener = setlistener("sim/signals/fdm-initialized", func {
  if (getprop("sim/signals/fdm-initialized") == 1) {
    removelistener(main_init_listener);
    print();
    print("***************************************************************");
    print("         Initializing "~getprop("sim/description")~" systems.           ");
    print("           Version "~getprop("sim/aircraft-version")~" on Flightgear "~getprop("sim/version/flightgear"));
    print("***************************************************************");
    print();
    screen.log.write("Welcome to "~getprop("sim/description")~", version "~getprop("sim/aircraft-version"), 1.0, 0.2, 0.2);
    
    hack.init();
    loop_flare();
    slow.loop();
    #fx = flex.WingFlexer.new(1, 250, 25, 500, 0.375, "f16/wings/fuel-and-stores-kg","f16/wings/fuel-and-stores-kg","sim/systems/wingflexer/","f16/wings/lift-lbf");
    flexer();
    medium.loop();
    fast.loop();
    ehsi.init();
    tgp.callInit();
    tgp.fast_loop();
    ded.callInit();
    ded.loop_ded();
    frd.callInit();
    frd.loop_ded();
    mps.loop();
    enableViews();
    fail.start();
    if (getprop("f16/disable-custom-view") != 1) view.manager.register("Cockpit View", pilot_view_limiter);
    emesary.GlobalTransmitter.Register(f16_mfd);
    emesary.GlobalTransmitter.Register(f16_hud);
    emesary.GlobalTransmitter.Register(awg_9.aircraft_radar);
    execTimer.start();
    if (getprop("f16/engine/running-state")) {
      #skip warmup if not cold and dark selected from launcher.
      setprop("/f16/avionics/power-fcr-warm", 1);
      setprop("/f16/avionics/power-rdr-alt-warm", 1);
    }
  }
 }, 0, 0);

var enableViews = func {
  setprop("sim/view[101]/enabled",1);
  setprop("sim/view[102]/enabled",1);
  setprop("sim/view[103]/enabled",1);
  setprop("sim/view[104]/enabled",1);
  setprop("sim/view[105]/enabled",0);
}


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
  reloadCannon();
  reloadHydras();
  crash.repair();
  if (getprop("f16/engine/running-state")) {
    setprop("fdm/jsbsim/elec/switches/epu",1);
    setprop("fdm/jsbsim/elec/switches/main-pwr",2);
    if (getprop("engines/engine[0]/running")!=1) {
      setprop("f16/engine/feed",1);
      setprop("f16/engine/jet-fuel",1);
      setprop("f16/engine/jfs-start",0);
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
  setprop("f16/engine/jfs-start", 1);
  screen.log.write("Attempting engine start, standby for engine..");
  inAutostart = 0;
}
var repair4 = func {
  # this pps settings is for when reinit with non zero fuel dump value in jsb propulsion, that value gets set on non-mounted tanks.
    setprop("fdm/jsbsim/propulsion/tank[0]/external-flow-rate-pps", 0);
    setprop("fdm/jsbsim/propulsion/tank[1]/external-flow-rate-pps", 0);
    if (getprop("/consumables/fuel/tank[2]/name") != "Not attached") {
      setprop("fdm/jsbsim/propulsion/tank[2]/external-flow-rate-pps", 0);
    }
    if (getprop("/consumables/fuel/tank[3]/name") != "Not attached") {
      setprop("fdm/jsbsim/propulsion/tank[3]/external-flow-rate-pps", 0);
    }
    if (getprop("/consumables/fuel/tank[4]/name") != "Not attached") {
      setprop("fdm/jsbsim/propulsion/tank[4]/external-flow-rate-pps", 0);
    }
    setprop("fdm/jsbsim/propulsion/tank[5]/external-flow-rate-pps", 0);
    setprop("fdm/jsbsim/propulsion/tank[6]/external-flow-rate-pps", 0);
    if (getprop("/consumables/fuel/tank[0]/level-norm")<0.5 and getprop("f16/engine/running-state")) {
      setprop("/consumables/fuel/tank[0]/level-norm", 0.55);
    }
}

var autostart = func {
  if (inAutostart) {
    return;
  }
  inAutostart = 1;
  screen.log.write("Starting, standby..");
  setprop("fdm/jsbsim/elec/switches/epu",1);
  setprop("fdm/jsbsim/elec/switches/main-pwr",2);
  setprop("controls/seat/ejection-safety-lever",1);
  setprop("f16/avionics/power-rdr-alt",2);
  setprop("f16/avionics/power-fcr",1);
  setprop("f16/avionics/power-right-hdpt",1);
  setprop("f16/avionics/power-left-hdpt",1);
  setprop("f16/avionics/power-mfd",1);
  setprop("f16/avionics/power-ufc",1);
  setprop("f16/avionics/power-mmc",1);
  setprop("f16/avionics/power-gps",1);
  setprop("f16/avionics/power-dl",1);
  setprop("f16/avionics/power-st-sta",1);
  if (getprop("engines/engine[0]/running")!=1) {
    setprop("f16/engine/feed",1);
    setprop("f16/engine/jet-fuel",1);
    setprop("f16/engine/jfs-start",0);
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
    setprop("f16/fcs/autopilot-on",0);
    setprop("f16/fcs/switch-pitch-block15",0);
    setprop("f16/fcs/switch-roll-block15",0);
    setprop("f16/fcs/switch-roll-block20",0);
    setprop("f16/fcs/switch-pitch-block20",0);
    settimer(repair4,3);    
    if (pylons.fcs != nil) {
      # replenish cooling fluid on all aim-9:
      var aim9s = pylons.fcs.getAllOfType("AIM-9");
      foreach(aim;aim9s) {
        aim.cool_total_time = 0;#consider making a method in AIM for this!
        aim.setCooling(0);
      }
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

#sound for hydra:
var h3ltrigger = func {
  if (getprop("fdm/jsbsim/fcs/hydra3ltrigger") and !getprop("fdm/jsbsim/fcs/hydra3ltriggers") and getprop("ai/submodels/submodel[4]/count") > 0) {
    setprop("fdm/jsbsim/fcs/hydra3ltriggers",1);
    settimer(h3ltrigger2, 0.45);# soundclip is 0.36 secs
  }
}

var h3ltrigger2 = func {
  setprop("fdm/jsbsim/fcs/hydra3ltriggers",0);
}

setlistener("controls/armament/trigger", h3ltrigger, 0, 0);# listen to main trigger since direct trigger gets aliased on/off all the time so wont work.

var h3rtrigger = func {
  if (getprop("fdm/jsbsim/fcs/hydra3rtrigger") and !getprop("fdm/jsbsim/fcs/hydra3rtriggers") and getprop("ai/submodels/submodel[5]/count") > 0) {
    setprop("fdm/jsbsim/fcs/hydra3rtriggers",1);
    settimer(h3rtrigger2, 0.45);
  }
}

var h3rtrigger2 = func {
  setprop("fdm/jsbsim/fcs/hydra3rtriggers",0);
}

setlistener("controls/armament/trigger", h3rtrigger, 0, 0);

var h7ltrigger = func {
  if (getprop("fdm/jsbsim/fcs/hydra7ltrigger") and !getprop("fdm/jsbsim/fcs/hydra7ltriggers") and getprop("ai/submodels/submodel[6]/count") > 0) {
    setprop("fdm/jsbsim/fcs/hydra7ltriggers",1);
    settimer(h7ltrigger2, 0.45);
  }
}

var h7ltrigger2 = func {
  setprop("fdm/jsbsim/fcs/hydra7ltriggers",0);
}

setlistener("controls/armament/trigger", h7ltrigger, 0, 0);

var h7rtrigger = func {
  if (getprop("fdm/jsbsim/fcs/hydra7rtrigger") and !getprop("fdm/jsbsim/fcs/hydra7rtriggers") and getprop("ai/submodels/submodel[7]/count") > 0) {
    setprop("fdm/jsbsim/fcs/hydra7rtriggers",1);
    settimer(h7rtrigger2, 0.45);
  }
}

var h7rtrigger2 = func {
  setprop("fdm/jsbsim/fcs/hydra7rtriggers",0);
}

setlistener("controls/armament/trigger", h7rtrigger, 0, 0);



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
  if (getprop("f16/chute/done")==1 or getprop("fdm/jsbsim/elec/bus/batt-1")<20) {
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



var fuelDigits = func {
  var maxtank = 7;
  for (var i=0;i<=maxtank;i+=1) {
    var fuel = getprop("consumables/fuel/tank["~i~"]/level-lbs"); 
    fuel = roundabout(fuel);
    var a = int((fuel*1-int(fuel*1))*10);
    var b = int((fuel*0.1-int(fuel*0.1))*10);
    var c = int((fuel*0.01-int(fuel*0.01))*10);
    var d = int((fuel*0.001-int(fuel*0.001))*10);
    var e = int((fuel*0.0001-int(fuel*0.0001))*10);
    var f = int((fuel*0.00001-int(fuel*0.00001))*10);
    setprop("consumables/fuel/tank["~i~"]/level-lbs-digit-1", a);
    setprop("consumables/fuel/tank["~i~"]/level-lbs-digit-2", b);
    setprop("consumables/fuel/tank["~i~"]/level-lbs-digit-3", c);
    setprop("consumables/fuel/tank["~i~"]/level-lbs-digit-4", d);
    setprop("consumables/fuel/tank["~i~"]/level-lbs-digit-5", e);
    setprop("consumables/fuel/tank["~i~"]/level-lbs-digit-6", f);
  }
  var fuel = getprop("/consumables/fuel/total-fuel-lbs");
  fuel = roundabout(fuel);
  var a = int((fuel*1-int(fuel*1))*10);
  var b = int((fuel*0.1-int(fuel*0.1))*10);
  var c = int((fuel*0.01-int(fuel*0.01))*10);
  var d = int((fuel*0.001-int(fuel*0.001))*10);
  var e = int((fuel*0.0001-int(fuel*0.0001))*10);
  var f = int((fuel*0.00001-int(fuel*0.00001))*10);
  setprop("consumables/fuel/total-level-lbs-digit-1", a);
  setprop("consumables/fuel/total-level-lbs-digit-2", b);
  setprop("consumables/fuel/total-level-lbs-digit-3", c);
  setprop("consumables/fuel/total-level-lbs-digit-4", d);
  setprop("consumables/fuel/total-level-lbs-digit-5", e);
  setprop("consumables/fuel/total-level-lbs-digit-6", f);
  settimer(fuelDigits,0.5);# runs 2 times every second.
}
#fuelDigits();

gui.showHelpDialog = func(path, toggle=0) {
    var node = props.globals.getNode(path);
    if (path == "/sim/help" and size(node.getChildren()) < 4) {
        node = node.getChild("common");
    }

    var name = node.getNode("title", 1).getValue();
    if (name == nil) {
        name = getprop("/sim/description");
        if (name == nil) {
            name = getprop("/sim/aircraft");
        }
    }
    var toggle = toggle > 0;
    var dialog = gui.dialog;
    if (toggle and contains(dialog, name)) {
        fgcommand("dialog-close", props.Node.new({ "dialog-name": name }));
        delete(dialog, name);
        return;
    }
    
    

    dialog[name] = gui.Widget.new();
    dialog[name].set("layout", "vbox");
    dialog[name].set("default-padding", 0);
    dialog[name].set("name", name);

    # title bar
    var titlebar = dialog[name].addChild("group");
    titlebar.set("layout", "hbox");
    titlebar.addChild("empty").set("stretch", 1);
    titlebar.addChild("text").set("label", name);
    titlebar.addChild("empty").set("stretch", 1);

    var w = titlebar.addChild("button");
    w.set("pref-width", 16);
    w.set("pref-height", 16);
    w.set("legend", "");
    w.set("default", 1);
    w.set("key", "esc");
    w.setBinding("nasal", "delete(gui.dialog, \"" ~ name ~ "\")");
    w.setBinding("dialog-close");

    dialog[name].addChild("hrule");

    # key list
    var keylist = dialog[name].addChild("group");
    keylist.set("layout", "table");
    keylist.set("default-padding", 2);
    var keydefs = node.getChildren("key");
    var n = size(keydefs);
    var row = var col = 0;
    foreach (var key; keydefs) {
        if (n >= 60 and row >= n / 3 or n >= 16 and row >= n / 2) {
            col += 1;
            row = 0;
        }

        var w = keylist.addChild("text");
        w.set("row", row);
        w.set("col", 2 * col);
        w.set("halign", "right");
        w.set("label", " " ~ key.getNode("name").getValue());

        w = keylist.addChild("text");
        w.set("row", row);
        w.set("col", 2 * col + 1);
        w.set("halign", "left");
        w.set("label", "... " ~ key.getNode("desc").getValue() ~ "  ");
        row += 1;
    }

    # separate lines
    var lines = node.getChildren("line");
    if (size(lines)) {
        if (size(keydefs)) {
            dialog[name].addChild("empty").set("pref-height", 4);
            dialog[name].addChild("hrule");
            dialog[name].addChild("empty").set("pref-height", 4);
        }

        var g = dialog[name].addChild("group");
        g.set("layout", "vbox");
        g.set("default-padding", 1);
        foreach (var lin; lines) {
            foreach (var l; split("\n", lin.getValue())) {
                var w = g.addChild("text");
                w.set("halign", "left");
                w.set("label", " " ~ l ~ " ");
            }
        }
    }
    if (path=="/sim/help") {
      # flying hud rwr MFD A/P weapons misc scenario variants
      dialog[name].addChild("hrule");
      var tabbar = dialog[name].addChild("group");
      tabbar.set("layout", "hbox");
      tabbar.addChild("empty").set("stretch", 1);
      var w1 = tabbar.addChild("button");
      w1.set("pref-width", 64);
      w1.set("pref-height", 16);
      w1.set("legend", "Flying");
      w1.set("default", 1);
      w1.set("key", "esc");
      #"delete(gui.dialog, \"" ~ name ~ "\")"
      w1.setBinding("nasal", "setprop('sim/help/text', getprop('sim/help/text-1'))");
      tabbar.addChild("empty").set("stretch", 1);
      var w2 = tabbar.addChild("button");
      w2.set("pref-width", 64);
      w2.set("pref-height", 16);
      w2.set("legend", "HUD");
      w2.set("default", 1);
      w2.set("key", "esc");
      w2.setBinding("nasal", "setprop('sim/help/text', getprop('sim/help/text-2'))");
      tabbar.addChild("empty").set("stretch", 1);
      var w3 = tabbar.addChild("button");
      w3.set("pref-width", 64);
      w3.set("pref-height", 16);
      w3.set("legend", "RWR");
      w3.set("default", 1);
      w3.set("key", "esc");
      w3.setBinding("nasal", "setprop('sim/help/text', getprop('sim/help/text-3'))");
      tabbar.addChild("empty").set("stretch", 1);
      var w4 = tabbar.addChild("button");
      w4.set("pref-width", 64);
      w4.set("pref-height", 16);
      w4.set("legend", "Displays");
      w4.set("default", 1);
      w4.set("key", "esc");
      w4.setBinding("nasal", "setprop('sim/help/text', getprop('sim/help/text-4'))");
      tabbar.addChild("empty").set("stretch", 1);
      var w5 = tabbar.addChild("button");
      w5.set("pref-width", 64);
      w5.set("pref-height", 16);
      w5.set("legend", "A/P");
      w5.set("default", 1);
      w5.set("key", "esc");
      w5.setBinding("nasal", "setprop('sim/help/text', getprop('sim/help/text-5'))");
      tabbar.addChild("empty").set("stretch", 1);
      var w6 = tabbar.addChild("button");
      w6.set("pref-width", 64);
      w6.set("pref-height", 16);
      w6.set("legend", "WEAP");
      w6.set("default", 1);
      w6.set("key", "esc");
      w6.setBinding("nasal", "setprop('sim/help/text', getprop('sim/help/text-6'))");
      tabbar.addChild("empty").set("stretch", 1);
      var w7 = tabbar.addChild("button");
      w7.set("pref-width", 64);
      w7.set("pref-height", 16);
      w7.set("legend", "Controls");
      w7.set("default", 1);
      w7.set("key", "esc");
      w7.setBinding("nasal", "setprop('sim/help/text', getprop('sim/help/text-7'))");
      tabbar.addChild("empty").set("stretch", 1);
      var w8 = tabbar.addChild("button");
      w8.set("pref-width", 64);
      w8.set("pref-height", 16);
      w8.set("legend", "Scenario");
      w8.set("default", 1);
      w8.set("key", "esc");
      w8.setBinding("nasal", "setprop('sim/help/text', getprop('sim/help/text-8'))");
      tabbar.addChild("empty").set("stretch", 1);
      var w9 = tabbar.addChild("button");
      w9.set("pref-width", 64);
      w9.set("pref-height", 16);
      w9.set("legend", "Variants");
      w9.set("default", 1);
      w9.set("key", "esc");
      w9.setBinding("nasal", "setprop('sim/help/text', getprop('sim/help/text-9'))");
      tabbar.addChild("empty").set("stretch", 1);
    }
 
    # scrollable text area
    if (node.getNode("text") != nil) {
        dialog[name].set("resizable", 1);
        dialog[name].addChild("empty").set("pref-height", 10);

        var width = [640, 800, 1152][col];
        var height = gui.screenHProp.getValue() - (100 + (size(keydefs) / (col + 1) + size(lines)) * 28);
        if (height < 200) {
            height = 200;
        }

        var w = dialog[name].addChild("textbox");
        w.set("padding", 4);
        w.set("halign", "fill");
        w.set("valign", "fill");
        w.set("stretch", "true");
        w.set("slider", 20);
        w.set("pref-width", width);
        w.set("pref-height", height);
        w.set("editable", 0);
        w.set("live", 1);
        w.set("property", node.getPath() ~ "/text");
    } else {
        dialog[name].addChild("empty").set("pref-height", 8);
    }

    fgcommand("dialog-new", dialog[name].prop());
    gui.showDialog(name);
}


var button = func {
  setprop("f16/sound/button",1);
  settimer(func {setprop("f16/sound/button",0);},0.35);
}

var button2 = func {
  setprop("f16/sound/button2",1);
  settimer(func {setprop("f16/sound/button2",0);},0.20);#0.10 but on some pc dont get time to play
}

var clamp0 = func {
  setprop("f16/sound/clamp",1);
  settimer(func {setprop("f16/sound/clamp",0);},0.40);
}

var click1 = func {
  setprop("f16/sound/click1",1);
  settimer(func {setprop("f16/sound/click1",0);},0.20);
}

var click2 = func {
  setprop("f16/sound/click2",1);
  settimer(func {setprop("f16/sound/click2",0);},0.15);
}

var click3 = func {
  setprop("f16/sound/click3",1);
  settimer(func {setprop("f16/sound/click3",0);},0.075);
}

var doubleClick = func {
  setprop("f16/sound/double-click",1);
  settimer(func {setprop("f16/sound/double-click",0);},0.30);
}

var doubleClick2 = func {
  setprop("f16/sound/double-click2",1);
  settimer(func {setprop("f16/sound/double-click2",0);},0.40);
}

var scroll = func {
  setprop("f16/sound/scroll",1);
  settimer(func {setprop("f16/sound/scroll",0);},0.35);
}

var knob = func {
  setprop("f16/sound/knob",1);
  settimer(func {setprop("f16/sound/knob",0);},0.20);
}

var knob2 = func {
  setprop("f16/sound/knob2",1);
  settimer(func {setprop("f16/sound/knob2",0);},0.30);
}

var lift_cover = func {
  setprop("f16/sound/lift_cover",1);
  settimer(func {setprop("f16/sound/lift_cover",0);},0.15);
}

# cockpit control sounds: (don't add ICP buttons to this list, they are calling the functions directly)
setlistener("controls/lighting/ext-lighting-panel/master", button2, nil, 0);
setlistener("controls/armament/master-arm", button2, nil, 0);
setlistener("controls/armament/master-arm-cover-open", lift_cover, nil, 0);
setlistener("controls/armament/laser-arm-dmd", button2, nil, 0);
setlistener("controls/gear/brake-parking", button2, nil, 0);
setlistener("controls/gear/gear-down", clamp0, nil, 0);
setlistener("fdm/jsbsim/systems/hook/tailhook-cmd-norm", clamp0, nil, 0);
setlistener("controls/seat/ejection-safety-lever", clamp0, nil, 0);
setlistener("instrumentation/radar/radar-standby", button2, nil, 0);
setlistener("controls/fuel/external-transfer", button2, nil, 0);
setlistener("sim/model/f16/controls/navigation/instrument-mode-panel/mode/rotary-switch-knob", knob, nil, 0);
setlistener("controls/fuel/qty-selector", knob, nil, 0);
setlistener("sim/model/f16/instrumentation/radar-awg-9/select-target", knob2, nil, 0);
setlistener("f16/engine/feed", knob, nil, 0);
setlistener("systems/refuel/serviceable", button2, nil, 0);
setlistener("controls/flight/flaps", button2, nil, 0);
setlistener("controls/test/test-panel/mal-ind-lts", doubleClick2, nil, 0);
setlistener("controls/lighting/ext-lighting-panel/master", button2, nil, 0);
setlistener("controls/lighting/ext-lighting-panel/anti-collision", button2, nil, 0);
setlistener("controls/lighting/ext-lighting-panel/pos-lights-flash", button2, nil, 0);
setlistener("controls/lighting/ext-lighting-panel/wing-tail", button2, nil, 0);
setlistener("controls/lighting/ext-lighting-panel/fuselage", button2, nil, 0);
setlistener("controls/lighting/ext-lighting-panel/form-knob", click3, nil, 0);
setlistener("fdm/jsbsim/fcs/fly-by-wire/enable-cat-III", button2, nil, 0);
setlistener("f16/fcs/switch-pitch-block20", button2, nil, 0);
setlistener("f16/fcs/switch-roll-block20", button2, nil, 0);
setlistener("f16/fcs/autopilot-off", button2, nil, 0);
setlistener("f16/fcs/autopilot-on", button2, nil, 0);
setlistener("f16/fcs/switch-pitch-block15", button2, nil, 0);
setlistener("f16/fcs/switch-roll-block15", button2, nil, 0);
setlistener("fdm/jsbsim/fcs/fbw-override", button2, nil, 0);
setlistener("controls/lighting/landing-light", button2, nil, 0);
setlistener("controls/MFD[0]/button-pressed", doubleClick, nil, 0);
setlistener("controls/MFD[1]/button-pressed", doubleClick, nil, 0);
setlistener("controls/MFD[2]/button-pressed", doubleClick, nil, 0);
setlistener("f16/avionics/hud-test", button2, nil, 0);
setlistener("f16/avionics/hud-ded", button2, nil, 0);
setlistener("f16/avionics/hud-brt", button2, nil, 0);
setlistener("f16/avionics/hud-alt", button2, nil, 0);
setlistener("f16/avionics/hud-velocity", button2, nil, 0);
setlistener("f16/avionics/hud-fpm", click1, nil, 0);
setlistener("f16/avionics/hud-scales", click1, nil, 0);
setlistener("fdm/jsbsim/elec/switches/main-pwr", button2, nil, 0);
setlistener("f16/engine/jet-fuel", button2, nil, 0);
setlistener("f16/avionics/hud-brt", click3, nil, 0);
setlistener("f16/avionics/rwr-int", click3, nil, 0);
setlistener("f16/avionics/mfd-l-con", click3, nil, 0);
setlistener("f16/avionics/mfd-l-brt", click3, nil, 0);
setlistener("f16/avionics/mfd-r-con", click3, nil, 0);
setlistener("f16/avionics/mfd-r-brt", click3, nil, 0);
setlistener("instrumentation/nav[0]/frequencies/current-mhz-digit-1", knob, nil, 0);
setlistener("instrumentation/nav[0]/frequencies/current-mhz-digit-2", knob, nil, 0);
setlistener("instrumentation/nav[0]/frequencies/current-mhz-digit-3", knob, nil, 0);
setlistener("instrumentation/nav[0]/frequencies/current-mhz-digit-4", knob, nil, 0);
setlistener("instrumentation/nav[0]/frequencies/current-mhz-digit-5", knob, nil, 0);
setlistener("f16/avionics/power-rdr-alt", click1, nil, 0);
setlistener("f16/avionics/power-fcr", click1, nil, 0);
setlistener("f16/avionics/power-right-hdpt", click1, nil, 0);
setlistener("f16/avionics/power-left-hdpt", click1, nil, 0);
setlistener("f16/avionics/power-mfd", click1, nil, 0);
setlistener("f16/avionics/power-mmc", click1, nil, 0);
setlistener("f16/avionics/power-st-sta", click1, nil, 0);
setlistener("f16/avionics/power-ufc", click1, nil, 0);
setlistener("f16/avionics/power-gps", click1, nil, 0);
setlistener("f16/avionics/power-dl", click1, nil, 0);
# valid methods: button, button2, knob, knob2, clamp0, click3, lift_cover
#                click1, click2, doubleClick, doubleClick2, scroll


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
                  getprop("ignore-list/troll-6"),
                  getprop("ignore-list/troll-7"),
                  getprop("ignore-list/troll-8"),
                  getprop("ignore-list/troll-9")];
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
              delete(ignore, thisCallsign);
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

var LBM2KG = 0.4535;

var fx = nil;

var flexer = func {
  # this function needs to become optimized using Nodes
  if (getprop("sim/multiplay/generic/float[5]")!=nil and getprop("payload/weight[0]/weight-lb") !=nil
    and getprop("payload/weight[1]/weight-lb") !=nil 
    and getprop("payload/weight[2]/weight-lb") !=nil 
    and getprop("payload/weight[3]/weight-lb") !=nil 
    and getprop("payload/weight[7]/weight-lb") !=nil 
    and getprop("payload/weight[8]/weight-lb") !=nil 
    and getprop("payload/weight[9]/weight-lb") !=nil 
    and getprop("payload/weight[10]/weight-lb") !=nil ) {
    setprop("surface-positions/leftrad", getprop("sim/multiplay/generic/float[5]")*20*D2R);  
    setprop("surface-positions/leftrad2", -getprop("surface-positions/left-aileron-pos-norm")*21.5*D2R);  
    setprop("surface-positions/rightrad", getprop("sim/multiplay/generic/float[6]")*20*D2R);  
    setprop("surface-positions/rightrad2", getprop("surface-positions/right-aileron-pos-norm")*21.5*D2R);  
    setprop("surface-positions/radlefr", getprop("surface-positions/flap-pos-norm")*D2R);  
    setprop("surface-positions/radlefl", -getprop("surface-positions/flap-pos-norm")*D2R);  
    # sice weight works wrong in air, we remove the weight when in air:
    #var ground = 1;#getprop("fdm/jsbsim/gear/unit[1]/WOW");
    setprop("f16/wings/fuel-and-stores-kg", 
    (getprop("payload/weight[0]/weight-lb")
    +getprop("payload/weight[1]/weight-lb")
    +getprop("payload/weight[2]/weight-lb")
    +getprop("payload/weight[3]/weight-lb")
    +getprop("payload/weight[7]/weight-lb")
    +getprop("payload/weight[8]/weight-lb")
    +getprop("payload/weight[9]/weight-lb")
    +getprop("payload/weight[10]/weight-lb"))*LBM2KG
    +getprop("consumables/fuel/tank[5]/level-kg")+getprop("consumables/fuel/tank[6]/level-kg"));
    #setprop("f16/wings/fuel-and-stores-kg", ground*(getprop("f16/wings/fuel-and-stores-kg-a")));
    
    # since the wingflexer works wrong in air we make the wing more stiff in air:
    #if (ground) {
      #setprop("sim/systems/wingflexer/params/K",250);
    #} else {
      #setprop("sim/systems/wingflexer/params/K",2500);
    #}
  }
  setprop("f16/wings/normal-lbf", -getprop("fdm/jsbsim/aero/coefficient/force/Z_t-lbf"));
  
  var errors = [];
  call(func {var z = getprop("sim/systems/wingflexer/z-m");
      var max2 = (9.2-2.84)*0.5;
      max2 = max2 * max2;
      
      setprop("sim/systems/wingflexer/z-m-tip",z);
      setprop("sim/systems/wingflexer/z-m-outer", z*((3.70-1.42)*(3.70-1.42))/(max2));
      setprop("sim/systems/wingflexer/z-m-middle",z*((2.88-1.42)*(2.88-1.42))/(max2));
      setprop("sim/systems/wingflexer/z-m-inner", z*((1.63-1.42)*(1.63-1.42))/(max2));},nil,nil, errors);
  if (size(errors)) {
    fgcommand('reinit', props.Node.new({ subsystem: "xml-proprules" }));
  }
  settimer(flexer,0);
}
