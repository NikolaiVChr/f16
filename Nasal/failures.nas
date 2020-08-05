var trigger_eng = nil;

var start = func {
    ##
    # Trigger object that will fire when aircraft air-speed is over
    # min, specified in knots. Probability of failing will
    # be 0% at min speed and 100% at max speed and beyond.
    # When the specified property is 0 there is zero chance of failing.
    var RandVneTrigger = {

        parents: [FailureMgr.Trigger],
        requires_polling: 1,
        type: "RandVne",

        new: func(min, max, prop) {
            if(min == nil or max == nil)
                die("RandVneTrigger.new: min and max must be specified");

            if(min >= max)
                die("RandVneTrigger.new: min must be less than max");

            if(min < 0 or max <= 0)
                die("RandVneTrigger.new: min must be positive or zero and max larger than zero");

            if(prop == nil or prop == "")
                die("RandVneTrigger.new: prop must be specified");

            var m = FailureMgr.Trigger.new();
            m.parents = [RandVneTrigger];
            m.params["min-speed"] = min;
            m.params["max-speed"] = max;
            m.params["property"] = prop;
            m._speed_prop = "f16/vne-exceed";
            return m;
        },

        to_str: func {
            sprintf("Increasing probability of fails between %d and %d Vne exceeded",
                int(me.params["min-speed"]), int(me.params["max-speed"]))
        },

        update: func {
            if(getprop(me.params["property"]) != 0) {
                var speed = getprop(me._speed_prop);
                var min = me.params["min-speed"];
                var max = me.params["max-speed"];
                var speed_d =  0;
                if(speed > min) {
                    speed_d = speed-min;
                    var delta_factor = 1/(max - min);
                    var factor = speed <= max ? delta_factor*speed_d : 1;
                    if(rand() < factor) {
                        return me.fired = 1;
                    }
                }
            }
            return me.fired = 0;
        }
    };
    
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

	var fl = compat_failure_modes.set_unserviceable("consumables/fuel-tanks");
	FailureMgr.add_failure_mode("consumables/fuel-tanks", "Fuel tank integrity", fl);

    var tacan = compat_failure_modes.set_unserviceable("instrumentation/tacan");
    FailureMgr.add_failure_mode("instrumentation/tacan", "Tacan", tacan);
    
    var hud = compat_failure_modes.set_unserviceable("instrumentation/hud");
    FailureMgr.add_failure_mode("instrumentation/hud", "HUD", hud);
    
    #var ch = compat_failure_modes.set_unserviceable("canopy");
    #FailureMgr.add_failure_mode("canopy", "Canopy hinges", ch);
    
	#foreach (mode;FailureMgr.get_failure_modes()) print(mode.id);

	trigger_eng = RandVneTrigger.new(0.25, 1, "f16/vne");
	FailureMgr.set_trigger("engines/engine", trigger_eng);
	trigger_eng.arm();
}

var loop = func {
    var fail_keys = keys(fail_list);
    foreach (key;fail_keys) {
        var sys = fail_list[key];
        var status = getprop(sys[1]);
        sys[2] = status == 1;
        fail_list[key] = sys;
        #print(sys[1]~" "~sys[2]);
    }
    fail_list["eng"][2] = !FailureMgr.get_failure_level("engines/engine");
    loop_caution();
    settimer(loop,1);
}

var fail_list = {
    a: ["TANK LEAK", "consumables/fuel-tanks/serviceable", 1, 0],
    b: ["RWR DEGR", "instrumentation/rwr/serviceable", 1, 0],
    c: ["FCR BUS FAIL", "instrumentation/radar/serviceable", 1, 0],
    d: ["HYD B FAIL", "systems/hydraulics/edpb-pump/serviceable", 1, 0],
    e: ["HYD A FAIL", "systems/hydraulics/edpa-pump/serviceable", 1, 0],
    f: ["FIRE", "damage/fire/serviceable", 1, 0],
    g: ["GEN STBY FAIL", "fdm/jsbsim/elec/failures/stby-gen/serviceable", 1, 0],
    h: ["GEN MAIN FAIL", "fdm/jsbsim/elec/failures/main-gen/serviceable", 1, 0],
    i: ["EPU FAIL", "fdm/jsbsim/elec/failures/epu/serviceable", 1, 0],
    j: ["BATT HOT", "fdm/jsbsim/elec/failures/battery/serviceable", 1, 0],
    k: ["WPN FAIL", "payload/armament/fire-control/serviceable", 1, 0],
    l: ["ISA RUD FAIL", "sim/failure-manager/controls/flight/rudder/serviceable", 1, 0],
    m: ["ISA ELV FAIL", "sim/failure-manager/controls/flight/elevator/serviceable", 1, 0],
    n: ["ISA ROLL FAIL", "sim/failure-manager/controls/flight/aileron/serviceable", 1, 0],
    o: ["ISA FLAP FAIL", "sim/failure-manager/controls/flight/flaps/serviceable", 1, 0],
    eng: ["ENG FAIL", "engines/engine/service", 1, 0],
    q: ["HUD BUS FAIL", "instrumentation/hud/serviceable", 1, 0],
    r: ["TCN FAIL", "instrumentation/tacan/serviceable", 1, 0],
    s: ["AIR DATA FAIL", "instrumentation/airspeed-indicator/serviceable", 1, 0],
    t: ["GEAR FAIL", "sim/failure-manager/controls/gear/serviceable", 1, 0],
    u: ["DME FAIL", "instrumentation/dme/serviceable", 1, 0],
    v: ["ALTI FAIL", "instrumentation/altimeter/serviceable", 1, 0],
    w: ["HEAD FAIL", "instrumentation/heading-indicator/serviceable", 1, 0],
    x: ["MAGN COMP FAIL", "instrumentation/magnetic-compass/serviceable", 1, 0],
    y: ["IND TURN FAIL", "instrumentation/turn-indicator/serviceable", 1, 0],
};

var getList = func {
    var fail_keys = keys(fail_list);
    var fails = [];
    foreach (key;fail_keys) {
        if (!fail_list[key][2] and !fail_list[key][3]) {
            append(fails, fail_list[key][0]);
        }
    }
    return fails;
}

var fail_reset = func {
    var fail_keys = keys(fail_list);
    foreach (key;fail_keys) {
        fail_list[key][3] = 0;
    }
}

var f_ack = func {
    var fail_keys = keys(fail_list);
    foreach (key;fail_keys) {
        if (fail_list[key][2] == 0) {
            fail_list[key][3] = 1;
        }
    }
}


var caution_ignore = {};

var caution = func (node) {
    var path = node.getPath();
    var value = node.getValue();
    var ignore = caution_ignore[path];
    if (ignore == nil) {
        ignore = 0;
        if (value and !getprop("controls/test/test-panel/mal-ind-lts")) {#TODO the check for MAL IND LTS here is not ideal. What if an error occurs while it is on?
            caution_ignore[path] = 0;
        }
    }
    if (!value) {
        delete(caution_ignore,path);
    }
    update_master();
};

var master_caution = func {
    if (getprop("controls/test/test-panel/mal-ind-lts")) {
        return;
    }
    foreach(key;keys(caution_ignore)) {
        if (key != "/f16/avionics/caution/elec-sys") {
            caution_ignore[key] = 1;
        }
    }
    update_master();
};

var elec_caution_reset = func {
    if (getprop("f16/avionics/caution/elec-sys")) {
        caution_ignore["/f16/avionics/caution/elec-sys"] = 1;
    }
    update_master();
}

var update_master = func {
    var new = 0;
    foreach(key;keys(caution_ignore)) {
        if (caution_ignore[key] == 0) {
            new = 1;
        }
    }
    setprop("f16/avionics/caution/master", new);
};

var loop_caution = func {# TODO: unlit the caution lights except elec-sys when master is pressed.
    var batt2 = getprop("fdm/jsbsim/elec/bus/batt-2") >= 20;
    var test  = getprop("controls/test/test-panel/mal-ind-lts");
	var testFire = getprop("controls/test/test-panel/fire-ovht-test");
    setprop("f16/avionics/caution/stores-config",     test or (batt2 and ((getprop("f16/stores-cat")>1 and getprop("fdm/jsbsim/fcs/fly-by-wire/enable-cat-III") < 1) or (getprop("f16/stores-cat")==1 and getprop("fdm/jsbsim/fcs/fly-by-wire/enable-cat-III") == 1))));
    setprop("f16/avionics/caution/seat-not-armed",    test or (batt2 and !getprop("controls/seat/ejection-safety-lever")));
    setprop("f16/avionics/caution/oxy-low",           test or (batt2 and getprop("f16/cockpit/oxygen-liters")<0.5));
    setprop("f16/avionics/caution/le-flaps",          test or (batt2 and (!getprop("f16/avionics/le-flaps-switch") or getprop("fdm/jsbsim/fcs/fly-by-wire/enable-standby-gains"))));
    setprop("f16/avionics/caution/hook",              test or (batt2 and getprop("fdm/jsbsim/systems/hook/tailhook-cmd-norm")));
    setprop("f16/avionics/caution/fwd-fuel-low",      test or (batt2 and getprop("consumables/fuel/tank[0]/level-lbs")<400));
    setprop("f16/avionics/caution/aft-fuel-low",      test or (batt2 and getprop("consumables/fuel/tank[1]/level-lbs")<400));
    setprop("f16/avionics/caution/elec-sys",          test or (batt2 and getprop("fdm/jsbsim/elec/bus/light/elec-sys")));
    setprop("f16/avionics/caution/cabin-press",       test or (batt2 and getprop("f16/cockpit/pressure-ft")>27000));
    setprop("f16/avionics/caution/adc",               test or (batt2 and getprop("fdm/jsbsim/fcs/fly-by-wire/enable-standby-gains")));
    setprop("f16/avionics/caution/equip-hot",         test or (batt2 and (!getprop("controls/ventilation/airconditioning-source") and getprop("f16/avionics/power-ufc-warm"))));
    setprop("f16/avionics/caution/overheat",          test or testFire or (batt2 and !getprop("damage/fire/serviceable")));
    setprop("f16/avionics/caution/avionics",          test or (batt2 and (!getprop("instrumentation/hud/serviceable") or !getprop("instrumentation/radar/serviceable") or !getprop("instrumentation/rwr/serviceable") or !getprop("instrumentation/tacan/serviceable"))));
};

setlistener("f16/avionics/caution/stores-config",caution,0,0);
setlistener("f16/avionics/caution/seat-not-armed",caution,0,0);
setlistener("f16/avionics/caution/oxy-low",caution,0,0);
setlistener("f16/avionics/caution/le-flaps",caution,0,0);
setlistener("f16/avionics/caution/hook",caution,0,0);
setlistener("f16/avionics/caution/fwd-fuel-low",caution,0,0);
setlistener("f16/avionics/caution/aft-fuel-low",caution,0,0);
setlistener("f16/avionics/caution/elec-sys",caution,0,0);
setlistener("f16/avionics/caution/cabin-press",caution,0,0);
setlistener("f16/avionics/caution/adc",caution,0,0);
setlistener("f16/avionics/caution/equip-hot",caution,0,0);
setlistener("f16/avionics/caution/overheat",caution,0,0);
setlistener("f16/avionics/caution/avionics",caution,0,0);
setlistener("f16/avionics/caution/probe-heat",caution,0,0);

loop();