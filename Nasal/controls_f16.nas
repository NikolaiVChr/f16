#
# Avoid putting Nasal scripts into inputs.xml as people then copy them and put them in their joystick.
#  And when we change it, they forget to change their joystick, and their aircraft will not work as it should.
#
var emerg_alt = func {
	if (getprop("payload/armament/msg")==1) {
        screen.log.write("CTRL-U disabled at the moment.");
    } else {
        setprop("position/altitude-ft", getprop("position/altitude-ft")+1000);
        setprop("sim/startup/onground", 0);
    }
                    
}

var speed_up = func {
	if (getprop("payload/armament/msg")==1) {
        screen.log.write("Speed-up disabled at the moment.");
    } else {
        controls.speedup(1);
    }
}

var speed_down = func {
	if (getprop("payload/armament/msg")) {
        screen.log.write("Speed-down disabled at the moment.");
    } else {
        controls.speedup(-1);
    }
}

var dogfight = func {        
	var dg = getprop("f16/avionics/dgft");
    dg = !dg;
    setprop("f16/avionics/dgft", dg);
    if (dg) {
        var prio = radar_system.apg68Radar.getPriorityTarget();
        setprop("instrumentation/radar/radar-enable-std", getprop("instrumentation/radar/radar-enable"));
        if (prio == nil) {
            setprop("instrumentation/radar/radar-enable", 0);
        }
        pylons.fcs.selectWeapon("20mm Cannon");
        ded.dataEntryDisplay.page = ded.pEWS;
        radar_system.apg68Radar.setRootMode(1, prio);
        f16.f16_mfd.MFDl.resetColorAll();
        f16.f16_mfd.MFDl.PFD.selectPage(f16.f16_mfd.MFDl.p_RDR);
        f16.f16_mfd.MFDl.p_RDR.selectionBox.show();
        f16.f16_mfd.MFDl.p_RDR.setSelection(nil, f16.f16_mfd.MFDl.PFD.buttons[10], 10);
        f16.f16_mfd.MFDr.resetColorAll();
        f16.f16_mfd.MFDr.PFD.selectPage(f16.f16_mfd.MFDr.p_WPN);
        f16.f16_mfd.MFDr.p_WPN.selectionBox.show();
        f16.f16_mfd.MFDr.p_WPN.setSelection(nil, f16.f16_mfd.MFDr.PFD.buttons[18], 18);
        setprop("f16/avionics/strf",0);
        if (pylons.fcs != nil and getprop("controls/armament/master-arm")) {
            foreach(var snake;pylons.fcs.getAllOfType("AIM-9L")) {
                snake.setCooling(1);
            }
            foreach(var snake;pylons.fcs.getAllOfType("AIM-9M")) {
                snake.setCooling(1);
            }
        }
        #f16.rdrModeGM = 0;
    } else {
        radar_system.apg68Radar.setRootMode(0, radar_system.apg68Radar.getPriorityTarget());
        setprop("instrumentation/radar/radar-enable", getprop("instrumentation/radar/radar-enable") and getprop("instrumentation/radar/radar-enable-std"));
    }
    setprop("f16/avionics/dgft", dg); # extra invocation on purpose
}

var replay = func {
    if (getprop("payload/armament/msg")==1) {
        screen.log.write("Please do not use replay while in combat over MP!");
    } else {
        call(func{fgcommand('replay', props.Node.new({}))},nil,var err2 = []);
        call(func{fgcommand('dialog-show', props.Node.new({"dialog-name": "replay"}))},nil,var err2 = []);
    }

}

var radar_standby = func {
	screen.log.write("Radar "~(getprop("instrumentation/radar/radar-enable")==0?"SILENT":"ACTIVE"), 0.5, 0.5, 1);
}

var masterarm = func {
	var variantID = getprop("/sim/variant-id");
    if ((variantID == 0 or variantID == 1 or variantID == 3) and getprop("controls/armament/master-arm-switch") == 0 and getprop("controls/armament/master-arm-cover-open") == 0) {
        setprop("controls/armament/master-arm-cover-open",1);
        screen.log.write("Master-arm cover open.", 0.5, 0.5, 1);
    } else {
        var now = getprop("controls/armament/master-arm-switch");
        now += 1;
        if (now > 1) {
            now = -1;
        }
        setprop("controls/armament/master-arm-switch", now);
        screen.log.write("Master-arm "~(getprop("controls/armament/master-arm-switch")==0?"OFF":(getprop("controls/armament/master-arm-switch")==1?"ON":"SIM")), 0.5, 0.5, 1);
    }
}

var chute_release = func {
	if (getprop("f16/chute/done")) {
        setprop("f16/chute/enable", 0);
        setprop("f16/chute/fold", 1);
        setprop("fdm/jsbsim/external_reactions/chute/magnitude", 0);
        f16.chuteRelease();
    }
}

var pause = func {
    if (getprop("payload/armament/msg")) {
        screen.log.write("Please do not pause while in combat over MP!");
    } else {
        setprop("/sim/freeze/master", !getprop("/sim/freeze/master"));
        setprop("/sim/freeze/clock", !getprop("/sim/freeze/clock"));
        if (getprop("/sim/freeze/master")) {
            screen.log.write("Sim is paused");
        } else {
            screen.log.write("Sim is resumed");
        }
    }
}