var trigger_eng = nil;

var init = func {
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
	FailureMgr.add_failure_mode(prop, "Fire control computer", actuator_fc);

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

	var hyda_fc = compat_failure_modes.set_unserviceable("fdm/jsbsim/systems/hydraulics/edpa-pump");
	FailureMgr.add_failure_mode("fdm/jsbsim/systems/hydraulics/edpa-pump", "Hydr. pump A", hyda_fc);

	var hydb_fc = compat_failure_modes.set_unserviceable("fdm/jsbsim/systems/hydraulics/edpb-pump");
	FailureMgr.add_failure_mode("fdm/jsbsim/systems/hydraulics/edpb-pump", "Hydr. pump B", hydb_fc);

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
    
    #
    # Add failure for HUD to the compatible failures. This will setup the property tree in the normal way; 
    # but it will not add it to the gui dialog.
    #append(compat_failure_modes.compat_modes,{ id: "instrumentation/hud", type: compat_failure_modes.MTBF, failure: compat_failure_modes.SERV, desc: "HUD" });
}



#################################
#
#     PILOTS FAULT LIST DISPLAY and F-ACK
#
#
var loop = func {
    fail_master_tmp = [0,0,0,0];
    foreach (sys;fail_list) {
        if (sys[2] != nil) {
            var status = getprop(sys[2]);
            sys[3] = status == 1;
            if (status == 0) {
                fail_master_tmp[sys[0]] = 1;
            }
        } else {
            var status = !FailureMgr.get_failure_level("engines/engine");# Engine works a bit different than those with serviceable properties, so we fix that with this call.
            sys[3] = status;
            fail_master_tmp[2] = !sys[3] or fail_master_tmp[2];
        }
    }
    fail_master = fail_master_tmp;
    loop_caution();
    settimer(loop,1);
}

var fail_master = [0,0,0,0];
var fail_list = [
    #  [System | String displayed in the F-ACK DED page | serviceable property | working? | if reset has been requested by the pilot so failure remains but is no longer shown to him]
       [2," TANK LEAK      ", "consumables/fuel-tanks/serviceable", 1, 0],
       [3," RWR  DEGR      ", "instrumentation/rwr/serviceable", 1, 0],
       [3," FCR       FAIL ", "instrumentation/radar/serviceable", 1, 0],
       [1," HYD  B    FAIL ", "fdm/jsbsim/systems/hydraulics/edpb-pump/serviceable", 1, 0],
       [1," HYD  A    FAIL ", "fdm/jsbsim/systems/hydraulics/edpa-pump/serviceable", 1, 0],
       [0,">FIRE          <", "damage/fire/serviceable", 1, 0],
       [3," GEN  STBY FAIL ", "fdm/jsbsim/elec/failures/stby-gen/serviceable", 1, 0],
       [3," GEN  MAIN FAIL ", "fdm/jsbsim/elec/failures/main-gen/serviceable", 1, 0],
       [3," EPU       FAIL ", "fdm/jsbsim/elec/failures/epu/serviceable", 1, 0],
       [3," BATT HOT       ", "fdm/jsbsim/elec/failures/battery/serviceable", 1, 0],
       [3," FCC       FAIL ", "payload/armament/fire-control/serviceable", 1, 0],
       [1," ISA  RUD  FAIL ", "sim/failure-manager/controls/flight/rudder/serviceable", 1, 0],
       [0,">ISA  ELV  FAIL<", "sim/failure-manager/controls/flight/elevator/serviceable", 1, 0],
       [0,">ISA  ROL  FAIL<", "sim/failure-manager/controls/flight/aileron/serviceable", 1, 0],
       [1," ISA  FLAP FAIL ", "sim/failure-manager/controls/flight/flaps/serviceable", 1, 0],
       [1," SPD  BRAK FAIL ", "sim/failure-manager/controls/flight/speedbrake/serviceable", 1, 0],
       [2," ENG       FAIL ", nil, 1, 0],
       [3," HUD       FAIL ", "instrumentation/hud/serviceable", 1, 0],
       [3," TCN       FAIL ", "instrumentation/tacan/serviceable", 1, 0],
       [3," AIR  DATA FAIL ", "instrumentation/airspeed-indicator/serviceable", 1, 0],
       [1," GEAR      FAIL ", "sim/failure-manager/controls/gear/serviceable", 1, 0],
       [3," DME       FAIL ", "instrumentation/dme/serviceable", 1, 0],
       [3," ALTI      FAIL ", "instrumentation/altimeter/serviceable", 1, 0],
       [3," HEAD      FAIL ", "instrumentation/heading-indicator/serviceable", 1, 0],
       [3," MAGN COMP FAIL ", "instrumentation/magnetic-compass/serviceable", 1, 0],
       [3," IND  TURN FAIL ", "instrumentation/turn-indicator/serviceable", 1, 0],
       [3," IND  ATTI FAIL ", "instrumentation/attitude-indicator/serviceable", 1, 0],
       [3," ADF       FAIL ", "instrumentation/adf/serviceable", 1, 0],
       [3," PLS  GS   FAIL ", "instrumentation/nav/gs/serviceable", 1, 0],
#      [3," ENG FAIL      ", "instrumentation/nav/cdi", 1, 0], not used by F-16
       [3," ELEC MAIN FAIL ", "systems/electrical/serviceable", 1, 0],    
       [0,">STBY      GAIN<", "systems/pitot/serviceable", 1, 0], 
       [0,">STBY      GAIN<", "systems/static/serviceable", 1, 0], 
       [3," CADC BUS  FAIL ", "systems/vacuum/serviceable", 1, 0]
]; 
# Systems:
# 0: FLCS (Warning)
# 1: FLCS
# 2: Engine
# 3: Avionics
#
# Source for names and systems: GR1F-F16CJ-34-1 page 1-475

var sorter = func(a, b) {
    if(a[0] < b[0]){
        return -1; # A should before b in the returned vector
    }elsif(a[0] == b[0]){
        return 0; # A is equivalent to b 
    }else{
        return 1; # A should after b in the returned vector
    }
}

fail_list = sort(fail_list, sorter);

var getList = func {
    # Get a list of strings of the current non-acknowledged failures
    var fails = [];
    foreach (var sys;fail_list) {
        if (!sys[3] and !sys[4]) {
            append(fails, sys[1]);
        }
    }
    return fails;
}

var fail_reset = func {
    # Remove all acknowledgements by pilot.
    foreach (var sys;fail_list) {
        sys[4] = 0;
    }
}

var f_ack = func {
    # Pilot acknowledge the top 3 failures, so lets stop displaying them.
    var ack = 0;
    foreach (var sys;fail_list) {
        if (ack < 3 and sys[3] == 0 and sys[4] == 0) {
            sys[4] = 1;
            ack += 1;
        }
    }
    if (ack == 0) {
        fail_reset();
    }
}


################################
#
#     CAUTION SYSTEM
#
#
# List of non-ignored/ignored caution warnings
# entry: property-name: ignored
var caution_ignore = {};

var caution = func (node) {
    # Manage the caution list
    var path = node.getPath();
    var value = node.getValue();
    var ignore = caution_ignore[path];
    if (ignore == nil) {
        # This is a new caution warning, process it:
        ignore = 0;# Hmm this line don't seem to be used..
        if (value and !getprop("controls/test/test-panel/mal-ind-lts")) {#TODO the check for MAL IND LTS here is not ideal. What if an error occurs while it is on?
            # The caution is active and MAL IND LTS is not active, its a real caution
            caution_ignore[path] = 0;# add it to the list as a non-ingored item.
        }
    }
    if (!value) {
        # The cause for the caution is no longer we remove it from the list.
        delete(caution_ignore,path);
    }
    update_master();
};

var master_caution = func {
    if (getprop("controls/test/test-panel/mal-ind-lts")) {
        return;
    }
    foreach(key;keys(caution_ignore)) {
        # Iterate over all active cautions and mark them as ignored/acknowledged.
        if (key != "/f16/avionics/caution/elec-sys") {
            # ..except for ELEC-SYS, it has its own caution reset button on the elec panel
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
    # Check if new cautions was added that has yet to be acknowledged, if so; lit up master caution.
    var new = 0;
    foreach(key;keys(caution_ignore)) {
        if (caution_ignore[key] == 0) {
            new = 1;
        }
    }
    setprop("f16/avionics/caution/master", new);
};

var loop_caution = func {# TODO: unlit the caution lights except elec-sys when master is pressed.
    # Caution panel main logic
    var batt2 = getprop("fdm/jsbsim/elec/bus/batt-2") >= 20;
    var dc1 = getprop("fdm/jsbsim/elec/bus/emergency-dc-1") >= 20;
    var test  = getprop("controls/test/test-panel/mal-ind-lts");
	var testFire = getprop("controls/test/test-panel/fire-ovht-test");
	var fuelTest = getprop("controls/fuel/qty-selector") == 0;
    setprop("f16/avionics/caution/stores-config",     test or (batt2 and ((getprop("f16/stores-cat")>1 and getprop("fdm/jsbsim/fcs/fly-by-wire/enable-cat-III") < 1) or (getprop("f16/stores-cat")==1 and getprop("fdm/jsbsim/fcs/fly-by-wire/enable-cat-III") == 1))));
    setprop("f16/avionics/caution/seat-not-armed",    test or (batt2 and !getprop("controls/seat/ejection-safety-lever")));
    setprop("f16/avionics/caution/oxy-low",           test or (batt2 and getprop("f16/cockpit/oxygen-liters-output")<0.5) or (batt2 and getprop("f16/avionics/oxy-psi")<42));
    setprop("f16/avionics/caution/le-flaps",          test or (batt2 and (!getprop("f16/avionics/le-flaps-switch") or getprop("fdm/jsbsim/fcs/fly-by-wire/enable-standby-gains"))));
    setprop("f16/avionics/caution/hook",              test or (batt2 and getprop("fdm/jsbsim/systems/hook/tailhook-cmd-norm")));
    setprop("f16/avionics/caution/fwd-fuel-low",      test or (dc1 and (fuelTest or getprop("consumables/fuel/tank[4]/level-lbs")<400)));
    setprop("f16/avionics/caution/aft-fuel-low",      test or (dc1 and (fuelTest or getprop("consumables/fuel/tank[5]/level-lbs")<400)));
    setprop("f16/avionics/caution/elec-sys",          test or (batt2 and getprop("fdm/jsbsim/elec/bus/light/elec-sys")));
    setprop("f16/avionics/caution/cabin-press",       test or (batt2 and getprop("f16/cockpit/pressure-ft")>27000));
    setprop("f16/avionics/caution/adc",               test or (batt2 and getprop("fdm/jsbsim/fcs/fly-by-wire/enable-standby-gains")));
    setprop("f16/avionics/caution/equip-hot",         test or (batt2 and (!getprop("controls/ventilation/airconditioning-source") and getprop("f16/avionics/power-ufc-warm"))));
    setprop("f16/avionics/caution/overheat",          test or (batt2 and (!getprop("damage/fire/serviceable") or testFire)));
	setprop("f16/avionics/caution/sec",               test or (batt2 and (getprop("f16/engine/sec-self-test") or getprop("f16/engine/ctl-sec"))));
    setprop("f16/avionics/caution/avionics",          test or (batt2 and (!getprop("instrumentation/hud/serviceable") or !getprop("instrumentation/radar/serviceable") or !getprop("instrumentation/rwr/serviceable") or !getprop("instrumentation/tacan/serviceable"))));
};

# Call caution method when a caution condition changes.
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
 
# NOTES:
#
# probe heat conditions is in f16.nas
# sec has conditions but is missing tie into caution light, is it even a caution? If not it should not be here.
# 
#
# ~Leto