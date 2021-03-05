var TRUE = 1;
var FALSE = 0;



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


########### Thunder sounds (from c172p) ###################

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

    # Minimum volume at 12000 meter, maximum at 2000
    var lightning_distance_norm = std.min(1.0, 1 / math.pow(math.max(0,lightning_distance-2000) / 10000.0, 2));

    settimer(func {
        var thunder1 = getprop("f16/sound/thunder1");
        var thunder2 = getprop("f16/sound/thunder2");
        var thunder3 = getprop("f16/sound/thunder3");
        var thunder4 = getprop("f16/sound/thunder4");
        var thunder5 = getprop("f16/sound/thunder5");
        var thunder6 = getprop("f16/sound/thunder6");
        var thunder7 = getprop("f16/sound/thunder7");
        var vol = 0;
        if(getprop("sim/current-view/internal") != nil and getprop("canopy/position-norm") != nil) {
          vol = math.clamp(1-(getprop("sim/current-view/internal")*0.5)+(getprop("canopy/position-norm")*0.5), 0, 1) * lightning_distance_norm;
        } else {
          vol = 0;
        }
        if (rand() > 0.5) {
          if (!thunder1) {
              thunderCalls = 1;
          } elsif (!thunder2) {
              thunderCalls = 2;
          } elsif (!thunder3) {
              thunderCalls = 3;
          } elsif (!thunder4) {
              thunderCalls = 4;
          } elsif (!thunder5) {
              thunderCalls = 5;
          } elsif (!thunder6) {
              thunderCalls = 6;
          } elsif (!thunder7) {
              thunderCalls = 7;
          } else
              return;
        } else {
          if (!thunder7) {
              thunderCalls = 7;
          } elsif (!thunder6) {
              thunderCalls = 6;
          } elsif (!thunder5) {
              thunderCalls = 5;
          } elsif (!thunder4) {
              thunderCalls = 4;
          } elsif (!thunder3) {
              thunderCalls = 3;
          } elsif (!thunder2) {
              thunderCalls = 2;
          } elsif (!thunder1) {
              thunderCalls = 1;
          } else
              return;
        }
        # Play the sound (sound files are about 9 to 12 seconds)
        setprop("f16/sound/dist-thunder"~thunderCalls, vol);
        play_thunder("thunder" ~ thunderCalls, 14.0);
    }, delay_seconds);
};

var play_thunder = func (name, timeout=0.1) {
    var sound_prop = "/f16/sound/" ~ name;

    #settimer(func {
        # Play the sound
        setprop(sound_prop, TRUE);

        # Reset the property after timeout so that the sound can be
        # played again.
        settimer(func {
            setprop(sound_prop, FALSE);
        }, timeout);
    #}, delay);
};

setlistener("/environment/lightning/lightning-pos-y", thunder_listener);







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

var click3 = func () {
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
setlistener("controls/armament/master-arm", button2, nil, 0);
setlistener("controls/armament/master-arm-cover-open", lift_cover, nil, 0);
setlistener("controls/armament/laser-arm-dmd", click2, nil, 0);
setlistener("controls/gear/brake-parking", button2, nil, 0);
setlistener("controls/gear/gear-down", clamp0, nil, 0);
setlistener("controls/gear/gear-horn-cutout", doubleClick, nil, 0);
setlistener("f16/avionics/gnd-jett", button2, nil, 0);
setlistener("fdm/jsbsim/systems/hook/tailhook-cmd-norm", clamp0, nil, 0);
setlistener("controls/seat/ejection-safety-lever", clamp0, nil, 0);
setlistener("f16/cockpit/alt-gear-handle", clamp0, nil, 0);
setlistener("instrumentation/radar/radar-standby", button2, nil, 0);
setlistener("instrumentation/altimeter/setting-inhg", click3, nil, 0);
setlistener("sim/model/f16/instrumentation/airspeed-indicator/safe-speed-limit-bug", click3, nil, 0);
setlistener("controls/fuel/external-transfer", click2, nil, 0);
setlistener("instrumentation/heading-indicator-fg/offset-deg", click3, nil, 0);
setlistener("instrumentation/nav[0]/radials/selected-deg", click3, nil, 0);
setlistener("sim/model/f16/controls/navigation/instrument-mode-panel/mode/rotary-switch-knob", knob, nil, 0);
setlistener("controls/fuel/qty-selector", knob, nil, 0);
setlistener("controls/displays/cursor-click", knob2, nil, 0);
setlistener("controls/displays/display-management-switch-x", knob2, nil, 0);
setlistener("controls/displays/display-management-switch-y", knob2, nil, 0);
setlistener("fdm/jsbsim/elec/switches/master-fuel-cmd", click1, nil, 0);
setlistener("controls/fuel/tank-inerting", button2, nil, 0);
setlistener("f16/engine/feed", knob, nil, 0);
setlistener("systems/refuel/serviceable", button2, nil, 0);
setlistener("controls/flight/flaps", button2, nil, 0);
setlistener("controls/test/test-panel/mal-ind-lts", doubleClick2, nil, 0);
setlistener("controls/test/test-panel/fire-ovht-test", doubleClick2, nil, 0);
setlistener("controls/test/test-panel/oxy-test", click2, nil, 0);
setlistener("controls/test/test-panel/epu-test", click2, nil, 0);
setlistener("controls/test/test-panel/pbg-test", doubleClick2, nil, 0);
setlistener("controls/test/avtr-test", doubleClick2, nil, 0);
setlistener("f16/avionics/emer-jett-switch", doubleClick2, nil, 0);
setlistener("f16/avionics/caution/elec-reset-btn", doubleClick, nil, 0);
setlistener("fdm/jsbsim/elec/switches/flcs-pwr-test", click2, nil, 0);
setlistener("f16/avionics/le-flaps-switch", button2, nil, 0);
setlistener("f16/fail/servo-rudder-switch", button2, nil, 0);
setlistener("f16/fail/servo-flaperon-switch", button2, nil, 0);
setlistener("f16/fail/servo-tail-switch", button2, nil, 0);
setlistener("f16/avionics/anti-ice-switch", click2, nil, 0);
setlistener("f16/avionics/voice-msg-inhibit", click2, nil, 0);
setlistener("f16/avionics/probe-heat-switch", click2, nil, 0);
setlistener("f16/avionics/ant-sel-iff-switch", click2, nil, 0);
setlistener("f16/avionics/ant-sel-uhf-switch", click2, nil, 0);
setlistener("controls/lighting/ext-lighting-panel/master", button2, nil, 0);
setlistener("controls/lighting/ext-lighting-panel/anti-collision", button2, nil, 0);
setlistener("controls/lighting/ext-lighting-panel/pos-lights-flash", button2, nil, 0);
setlistener("controls/lighting/ext-lighting-panel/wing-tail", button2, nil, 0);
setlistener("controls/lighting/ext-lighting-panel/fuselage", button2, nil, 0);
setlistener("controls/lighting/ext-lighting-panel/form-knob", click3, nil, 0);
setlistener("controls/lighting/ext-lighting-panel/ar-knob", click3, nil, 0);
setlistener("fdm/jsbsim/fcs/fly-by-wire/enable-cat-III", button2, nil, 0);
setlistener("f16/fcs/switch-pitch-block20", button2, nil, 0);
setlistener("f16/fcs/switch-roll-block20", button2, nil, 0);
setlistener("f16/fcs/autopilot-off", button2, nil, 0);
setlistener("f16/fcs/autopilot-on", button2, nil, 0);
setlistener("f16/fcs/switch-pitch-block15", button2, nil, 0);
setlistener("f16/fcs/switch-roll-block15", button2, nil, 0);
setlistener("fdm/jsbsim/fcs/fbw-override", button2, nil, 0);
setlistener("controls/lighting/landing-light", click2, nil, 0);
setlistener("controls/MFD[0]/button-pressed", doubleClick, nil, 0);
setlistener("controls/MFD[1]/button-pressed", doubleClick, nil, 0);
setlistener("controls/MFD[2]/button-pressed", doubleClick, nil, 0);
setlistener("instrumentation/radar/iff", doubleClick, nil, 0);
setlistener("f16/avionics/hud-test", button2, nil, 0);
setlistener("f16/avionics/hud-ded", button2, nil, 0);
setlistener("f16/avionics/hud-alt", button2, nil, 0);
setlistener("f16/avionics/hud-velocity", button2, nil, 0);
setlistener("f16/avionics/hud-fpm", click1, nil, 0);
setlistener("f16/avionics/hud-scales", click1, nil, 0);
setlistener("f16/avionics/hud-drift", button2, nil, 0);
setlistener("fdm/jsbsim/elec/switches/main-pwr", click2, nil, 0);
setlistener("f16/engine/jfs-start-switch", button2, nil, 0);
setlistener("fdm/jsbsim/elec/switches/epu", click2, nil, 0);
setlistener("f16/engine/ab-reset", button2, nil, 0);
setlistener("f16/engine/max-power", button2, nil, 0);
setlistener("f16/avionics/hud-brt", scroll, nil, 0);
setlistener("f16/avionics/hud-sym", scroll, nil, 0);
setlistener("f16/avionics/rwr-int", click3, nil, 0);
setlistener("f16/avionics/mfd-l-con", click3, nil, 0);
setlistener("f16/avionics/mfd-l-brt", click3, nil, 0);
setlistener("f16/avionics/mfd-r-con", click3, nil, 0);
setlistener("f16/avionics/mfd-r-brt", click3, nil, 0);
setlistener("f16/fcs/adv-mode-sel", doubleClick2, nil, 0);
setlistener("f16/avionics/caution/master-btn", doubleClick2, nil, 0);
setlistener("instrumentation/nav[0]/frequencies/current-mhz-digit-1", knob, nil, 0);
setlistener("instrumentation/nav[0]/frequencies/current-mhz-digit-2", knob, nil, 0);
setlistener("instrumentation/nav[0]/frequencies/current-mhz-digit-3", knob, nil, 0);
setlistener("instrumentation/nav[0]/frequencies/current-mhz-digit-4", knob, nil, 0);
setlistener("instrumentation/nav[0]/frequencies/current-mhz-digit-5", knob, nil, 0);
setlistener("instrumentation/comm[0]/volume", click3, nil, 0);
setlistener("instrumentation/comm[1]/volume", click3, nil, 0);
setlistener("instrumentation/tacan/volume", click3, nil, 0);
setlistener("f16/avionics/msl-vol-knob", click3, nil, 0);
setlistener("f16/avionics/ils-volume", click3, nil, 0);
setlistener("f16/avionics/rwr-volume", click3, nil, 0);
setlistener("f16/avionics/intercom-volume", click3, nil, 0);
setlistener("controls/lighting/lighting-panel/console-flood-knob", click3, nil, 0);
setlistener("controls/lighting/lighting-panel/flood-inst-pnl-knob", click3, nil, 0);
setlistener("controls/lighting/lighting-panel/pri-inst-pnl-knob", click3, nil, 0);
setlistener("controls/lighting/lighting-panel/data-entry-display", click3, nil, 0);
setlistener("controls/lighting/lighting-panel/console-primary-knob", click3, nil, 0);
setlistener("controls/lighting/lighting-panel/mal-ind-lts-brightness-switch", button2, nil, 0);
setlistener("controls/flight/rudder-trim", click3, nil, 0);
setlistener("controls/flight/elevator-trim", click3, nil, 0);
setlistener("controls/flight/aileron-trim", click3, nil, 0);
setlistener("f16/avionics/trim-ap-disc-switch", button2, nil, 0);
setlistener("f16/avionics/indv-ltg-brightness-switch", click2, nil, 0);
setlistener("f16/avionics/nvis", button2, nil, 0);
setlistener("f16/avionics/ky58-volume", click3, nil, 0);
setlistener("f16/avionics/ky58-mode", knob, nil, 0);
setlistener("f16/avionics/ky58-z", knob, nil, 0);
setlistener("f16/avionics/ky58-enable", knob, nil, 0);
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
setlistener("f16/avionics/ins-knob", knob, nil, 0);
setlistener("f16/avionics/ew-disp-switch", click1, nil, 0);
setlistener("f16/avionics/ew-rwr-switch", click1, nil, 0);
setlistener("f16/avionics/ew-mws-switch", click1, nil, 0);
setlistener("f16/avionics/ew-jmr-switch", click1, nil, 0);
setlistener("f16/avionics/ew-jett-switch", click1, nil, 0);
setlistener("f16/avionics/ew-mode-knob", knob, nil, 0);
setlistener("f16/avionics/cmds-01-switch", button2, nil, 0);
setlistener("f16/avionics/cmds-02-switch", button2, nil, 0);
setlistener("f16/avionics/cmds-ch-switch", button2, nil, 0);
setlistener("f16/avionics/cmds-fl-switch", button2, nil, 0);
setlistener("controls/ventilation/airconditioning-enabled", knob, nil, 0);
setlistener("controls/ventilation/airconditioning-source", knob, nil, 0);
setlistener("f16/avionics/o2-switch", click3, nil, 0);
setlistener("f16/avionics/em-no-te-switch", click3, nil, 0);
setlistener("f16/avionics/pbg-switch", click3, nil, 0);
setlistener("f16/avionics/uhf-radio-display-test", click3, nil, 0);
setlistener("controls/flight/alt-rel-button", button2, nil, 0);
setlistener("f16/avionics/rtn-seq", click3, nil, 0);
setlistener("f16/avionics/ded-up-down", click3, nil, 0);
# valid methods: button, button2, knob, knob2, clamp0, click3, lift_cover
#                click1, click2, doubleClick, doubleClick2, scroll
