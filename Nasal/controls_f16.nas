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
        setprop("instrumentation/radar/radar-standby-std", getprop("instrumentation/radar/radar-standby"));
        setprop("instrumentation/radar/radar-standby", 1);
        pylons.fcs.selectWeapon("20mm Cannon");
        setprop("instrumentation/radar/radar2-range-std", getprop("instrumentation/radar/radar2-range"));
        setprop("instrumentation/radar/radar2-range", 10);
        setprop("instrumentation/radar/az-field-std", getprop("instrumentation/radar/az-field"));
        setprop("instrumentation/radar/ho-field-std", getprop("instrumentation/radar/ho-field"));
        setprop("instrumentation/radar/az-field", 30);
        setprop("instrumentation/radar/ho-field", 20);
        ded.dataEntryDisplay.page = ded.pEWS;
        f16.f16_mfd.MFDl.resetColorAll();
        f16.f16_mfd.MFDl.PFD.selectPage(f16.f16_mfd.MFDl.p_RDR);
        f16.f16_mfd.MFDl.p_RDR.selectionBox.show();
        f16.f16_mfd.MFDl.p_RDR.setSelection(nil, f16.f16_mfd.MFDl.PFD.buttons[10], 10);
        f16.f16_mfd.MFDr.resetColorAll();
        f16.f16_mfd.MFDr.PFD.selectPage(f16.f16_mfd.MFDr.p_WPN);
        f16.f16_mfd.MFDr.p_WPN.selectionBox.show();
        f16.f16_mfd.MFDr.p_WPN.setSelection(nil, f16.f16_mfd.MFDr.PFD.buttons[18], 18);
        f16.rdrModeGM = 0;
    } else {
        setprop("instrumentation/radar/radar2-range", getprop("instrumentation/radar/radar2-range-std"));
        setprop("instrumentation/radar/az-field", getprop("instrumentation/radar/az-field-std"));
        setprop("instrumentation/radar/ho-field", getprop("instrumentation/radar/ho-field-std"));
        setprop("instrumentation/radar/radar-standby", getprop("instrumentation/radar/radar-standby") and getprop("instrumentation/radar/radar-standby-std"));
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
	screen.log.write("Radar "~(getprop("instrumentation/radar/radar-standby")==1?"SILENT":"ACTIVE"), 0.5, 0.5, 1);
}

var masterarm = func {
	var variantID = getprop("/sim/variant-id");
    if ((variantID == 0 or variantID == 1 or variantID == 3) and getprop("controls/armament/master-arm") == 0 and getprop("controls/armament/master-arm-cover-open") == 0) {
        setprop("controls/armament/master-arm-cover-open",1);
        screen.log.write("Master-arm cover open.", 0.5, 0.5, 1);
    } else {
        setprop("controls/armament/master-arm",!getprop("controls/armament/master-arm"));
        screen.log.write("Master-arm "~(getprop("controls/armament/master-arm")==0?"OFF":"ON"), 0.5, 0.5, 1);
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