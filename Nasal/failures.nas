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
    
    
    #f16/vne-exceed

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


foreach (mode;FailureMgr.get_failure_modes()) print(mode.id);

var trigger_eng = RandVneTrigger.new(0.25, 1, "f16/vne");
FailureMgr.set_trigger("engines/engine", trigger_eng);
trigger_eng.arm();
}