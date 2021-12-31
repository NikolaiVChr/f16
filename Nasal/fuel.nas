# FUEL ==============================================================
var hydB         = props.globals.getNode("fdm/jsbsim/systems/hydraulics/sysa-psi", 0);
var hydA         = props.globals.getNode("fdm/jsbsim/systems/hydraulics/sysb-psi", 0);

var FUEL_QTY_TEST = 0;
var FUEL_QTY_NORM = 1;
var FUEL_QTY_RESV = 2;
var FUEL_QTY_WING = 3;
var FUEL_QTY_EXT_WING = 4;
var FUEL_QTY_EXT_CENT = 5;

var FEED_OFF = 0;
var FEED_NORM = 1;
var FEED_FWD = 3;
var FEED_AFT = 2;

var FUEL_TRANS_WING = 0;
var FUEL_TRANS_NORM = 1;

var AIR_SOURCE_OFF = 0;
var AIR_SOURCE_NORM = 1;
var AIR_SOURCE_DUMP = 2;
var AIR_SOURCE_RAM = 3;

var TANK_FWD = 0;
var TANK_WING_LEFT = 1;
var TANK_WING_RIGHT = 2;
var TANK_AFT = 3;
var TANK_FWD_RSV = 4;
var TANK_AFT_RSV = 5;
var TANK_EXT_LEFT = 6;
var TANK_EXT_RIGHT = 7;
var TANK_EXT_CENTER = 8;
var TANK_EXT_CFT = 9;

# Notes: Engine in Block 60 can probably consume more than 13 pps.
var max_int_wing_lbm = 550;

var aft_to_fwd = 0;
var ext_center_to_wing_left = 0;
var ext_center_to_wing_right = 0;
var ext_left_to_wing_left = 0;
var ext_right_to_wing_right = 0;
var cft_to_wing_left = 0;
var cft_to_wing_right = 0;


var fuelqty = func {# 0.5 Hz loop
  var qty_selector = getprop("controls/fuel/qty-selector");
  var total_fuel = getprop("/consumables/fuel/total-fuel-lbs");
  var fwdFuel = getprop("consumables/fuel/tank[0]/level-lbs") + getprop("consumables/fuel/tank[4]/level-lbs");
  var aftFuel = getprop("consumables/fuel/tank[3]/level-lbs") + getprop("consumables/fuel/tank[5]/level-lbs");

  # Bingo fuel determination
  if (total_fuel<getprop("f16/settings/bingo") or (qty_selector == FUEL_QTY_NORM and (fwdFuel+aftFuel)<getprop("f16/settings/bingo"))) {
    if (getprop("f16/avionics/bingo") == 0) {
      setprop("f16/avionics/bingo", 1);
    }
  } else {
    setprop("f16/avionics/bingo", 0);
  }

  # Fuel system failure
  if (!getprop("consumables/fuel-tanks/serviceable")) {
    props.globals.getNode("fdm/jsbsim/propulsion/fuel_dump").setBoolValue(1);
  } else {
    props.globals.getNode("fdm/jsbsim/propulsion/fuel_dump").clearValue();
  }


    #################################################################################
    #############         TRANSFER                                   ################
    #################################################################################
    var airsrc = getprop("controls/ventilation/airconditioning-source");
    var transfer = getprop("controls/fuel/external-transfer");
    var refuel_door = getprop("systems/refuel/serviceable");


    ############# Automatic forward fuel transfer system
    # Notes:
    # - The fuel system diagram doesn't make it clear, assumed here that A-1 fuel is
    #   transfered to the F-1 + F-2 combined tank.
    # - This does not take into consideration any unusable fuel, but does try to prevent
    #   'ghost fuel' from being created.
    # - Transfer rate is unknown. The assumed value fits flight idle to AB burn rates.
    if (getprop("fdm/jsbsim/elec/bus/emergency-dc-2") > 20 and qty_selector == FUEL_QTY_NORM and (fwdFuel+aftFuel) < 2800) {
        if (fwdFuel - aftFuel < 300 and
            getprop("consumables/fuel/tank[0]/level-norm") < 0.99 and
            getprop("consumables/fuel/tank[3]/level-norm") > 0.01) {
            # start fwd fuel transfer
            aft_to_fwd = 1;
        } elsif (fwdFuel - aftFuel > 450 or
            getprop("consumables/fuel/tank[0]/level-norm") >= 0.99 or
            getprop("consumables/fuel/tank[3]/level-norm") <= 0.01) {
            # stop fwd fuel transfer, if any
            aft_to_fwd = 0;
        }
    } else {
        aft_to_fwd = 0;
    }

    ############# External transfer system
    ext_center_to_wing_right = 0;
    ext_center_to_wing_left = 0;
    ext_left_to_wing_left = 0;
    ext_right_to_wing_right = 0;
    cft_to_wing_left = 0;
    cft_to_wing_right = 0;

    if ((airsrc == AIR_SOURCE_NORM or airsrc == AIR_SOURCE_DUMP) and !refuel_door and (hydA.getValue() >= 2000 or hydB.getValue() >= 2000)) {#TODO: find proper hyd/elec requirements
        if (transfer == FUEL_TRANS_NORM) {
            if (getprop("/consumables/fuel/tank[8]/selected") == 1 and getprop("consumables/fuel/tank[8]/level-norm") > 0.01 and getprop("consumables/fuel/tank[1]/level-lbs") < 525 and getprop("consumables/fuel/tank[2]/level-lbs") < 525) {
                ext_center_to_wing_right = 7.5;
                ext_center_to_wing_left = 7.5;
            } elsif (getprop("consumables/fuel/tank[8]/level-norm") < 0.02) {
                # Not transfering from center, and center approx empty
                if (getprop("/consumables/fuel/tank[6]/selected") == 1 and getprop("consumables/fuel/tank[6]/level-norm") > 0.01 and getprop("consumables/fuel/tank[1]/level-lbs") < 525) {
                  # left side
                  ext_left_to_wing_left = 7.5;
                }
                if (getprop("/consumables/fuel/tank[7]/selected") == 1 and getprop("consumables/fuel/tank[7]/level-norm") > 0.01 and getprop("consumables/fuel/tank[2]/level-lbs") < 525) {
                  # right side
                  ext_right_to_wing_right = 7.5;
                }
            }
        } elsif (transfer == FUEL_TRANS_WING) {
            if (getprop("consumables/fuel/tank[6]/level-norm") > 0.01 and getprop("consumables/fuel/tank[1]/level-lbs") < 525) {
              # left side
              ext_left_to_wing_left = 7.5;
            }
            if (getprop("consumables/fuel/tank[7]/level-norm") > 0.01 and getprop("consumables/fuel/tank[2]/level-lbs") < 525) {
              # right side
              ext_right_to_wing_right = 7.5;
            }
            if (ext_left_to_wing_left == 0 and ext_right_to_wing_right == 0 and getprop("consumables/fuel/tank[8]/level-norm") > 0.01 and getprop("consumables/fuel/tank[1]/level-lbs") < 525 and getprop("consumables/fuel/tank[2]/level-lbs") < 525) {
                ext_center_to_wing_right = 7.5;
                ext_center_to_wing_left = 7.5;
            }
        }
    }
    if (   getprop("/consumables/fuel/tank[9]/selected") == 1 and getprop("consumables/fuel/tank[9]/level-norm") > 0.01
           and getprop("consumables/fuel/tank[1]/level-lbs") < 525 and getprop("consumables/fuel/tank[2]/level-lbs") < 525
           and ext_center_to_wing_left == 0 and ext_center_to_wing_right == 0 and ext_right_to_wing_right == 0 and ext_left_to_wing_left == 0
           and getprop("sim/variant-id")>=5 and getprop("fdm/jsbsim/accelerations/a_n") > 0.75) {# gravity powered
        cft_to_wing_left  = 7.5;
        cft_to_wing_right = 7.5;
    }

    

    ############# Internal transfer system
    # todo



    # execute the actual transfers
    setprop("/fdm/jsbsim/propulsion/tank[3]/external-flow-rate-pps", -aft_to_fwd);  # from aft
    setprop("/fdm/jsbsim/propulsion/tank[0]/external-flow-rate-pps", aft_to_fwd);   # to fwd
    setprop("/fdm/jsbsim/propulsion/tank[1]/external-flow-rate-pps", ext_center_to_wing_left  + ext_left_to_wing_left   + cft_to_wing_left);  # wing left
    setprop("/fdm/jsbsim/propulsion/tank[2]/external-flow-rate-pps", ext_center_to_wing_right + ext_right_to_wing_right + cft_to_wing_right);   # wing right
    # for the ext tanks important not to write to these properties if not mounted: (as pylon system will set flow rate)
    if (getprop("/consumables/fuel/tank[6]/selected") == 1)
        setprop("/fdm/jsbsim/propulsion/tank[6]/external-flow-rate-pps", -ext_left_to_wing_left);   # left ext
    if (getprop("/consumables/fuel/tank[7]/selected") == 1)
        setprop("/fdm/jsbsim/propulsion/tank[7]/external-flow-rate-pps", -ext_right_to_wing_right);   # right ext
    if (getprop("/consumables/fuel/tank[8]/selected") == 1)
        setprop("/fdm/jsbsim/propulsion/tank[8]/external-flow-rate-pps", -ext_center_to_wing_right -ext_center_to_wing_left);   # center ext
    if (getprop("sim/variant-id")>=5 and getprop("/consumables/fuel/tank[9]/selected") == 1)
        setprop("/fdm/jsbsim/propulsion/tank[9]/external-flow-rate-pps", -cft_to_wing_left -cft_to_wing_right);   # center ext

    #################################################################################
    #################################################################################
    #################################################################################

  # Power requirement check for following systems
  if (getprop("fdm/jsbsim/elec/bus/emergency-ac-2")<100) {
    return;
  }

  var fuel = total_fuel;

  # Fuel quantity indication
  if (qty_selector == FUEL_QTY_TEST) {
    # test
    setprop("f16/fuel/hand-fwd", 2000);
    setprop("f16/fuel/hand-aft", 2000);
    fuel = 6000;
  } elsif (qty_selector == FUEL_QTY_NORM) {
    #norm
    setprop("f16/fuel/hand-fwd", fwdFuel);
    setprop("f16/fuel/hand-aft", aftFuel);
  } elsif (qty_selector == FUEL_QTY_RESV) {
    #reservoir tanks
    setprop("f16/fuel/hand-fwd", getprop("consumables/fuel/tank[4]/level-lbs"));
    setprop("f16/fuel/hand-aft", getprop("consumables/fuel/tank[5]/level-lbs"));
  } elsif (qty_selector == FUEL_QTY_WING) {
    # int wing
    setprop("f16/fuel/hand-fwd", getprop("consumables/fuel/tank[2]/level-lbs")); # right
    setprop("f16/fuel/hand-aft", getprop("consumables/fuel/tank[1]/level-lbs")); # left
  } elsif (qty_selector == FUEL_QTY_EXT_WING) {
    # ext wing
    setprop("f16/fuel/hand-fwd", getprop("consumables/fuel/tank[7]/level-lbs")); 
    setprop("f16/fuel/hand-aft", getprop("consumables/fuel/tank[6]/level-lbs"));
  } elsif (qty_selector == FUEL_QTY_EXT_CENT) {
    # ext center
    var lvlcft = getprop("consumables/fuel/tank[9]/level-lbs");
    setprop("f16/fuel/hand-fwd", getprop("consumables/fuel/tank[8]/level-lbs")+(lvlcft!=nil?lvlcft:0));
    setprop("f16/fuel/hand-aft", 0);
  }
  setprop("/consumables/fuel/total-fuel-lbs-1",     int(fuel       )     -int(fuel*0.1)*10);
  setprop("/consumables/fuel/total-fuel-lbs-10",    int(fuel*0.1   )*10  -int(fuel*0.01)*100);
  setprop("/consumables/fuel/total-fuel-lbs-100",   int(fuel*0.01  )*100 -int(fuel*0.001)*1000);
  setprop("/consumables/fuel/total-fuel-lbs-1000",  int(fuel*0.001 )*1000-int(fuel*0.0001)*10000);
  setprop("/consumables/fuel/total-fuel-lbs-10000", int(fuel*0.0001)*10000);
}

# Fuel tank priority store
var maxtank = getprop("sim/variant-id")>=5?9:8;
var tank_priority = {};

var store_tank_prio = func {
    for (var i=0;i<=maxtank;i+=1) {
        tank_priority[i] = getprop("/fdm/jsbsim/propulsion/tank["~i~"]/priority");
    }
}

store_tank_prio();

# Fuel master switch
setlistener("fdm/jsbsim/elec/switches/master-fuel", func(masterNode) {
    var master = masterNode.getValue();

    if (master == 0) { # Off
        for (var i=0;i<=maxtank;i+=1) {
            tank_priority[i] = getprop("/fdm/jsbsim/propulsion/tank["~i~"]/priority");
            setprop("/fdm/jsbsim/propulsion/tank["~i~"]/priority", 0);
        }
    } else {
        for (var i=0;i<=maxtank;i+=1) {
            setprop("/fdm/jsbsim/propulsion/tank["~i~"]/priority", tank_priority[i]);
        }
    }
}, 1, 0);

# Engine feed knob handler
setlistener("f16/engine/feed", func(feedNode) {
    var feed = feedNode.getValue();
    var master = getprop("fdm/jsbsim/elec/switches/master-fuel");

    if (feed == FEED_NORM) { # NORM
        tank_priority[TANK_FWD] = 5;
        tank_priority[TANK_AFT] = 5;
    } elsif (feed == FEED_AFT) { # AFT
        tank_priority[TANK_FWD] = 5;
        tank_priority[TANK_AFT] = 1;
    } elsif (feed == FEED_FWD) { # FWD
        tank_priority[TANK_FWD] = 1;
        tank_priority[TANK_AFT] = 5;
    }

    if (master) {
        setprop("/fdm/jsbsim/propulsion/tank[0]/priority", tank_priority[TANK_FWD]);
        setprop("/fdm/jsbsim/propulsion/tank[3]/priority", tank_priority[TANK_AFT]);
    }
}, 1, 0);

var set_ext_tank_prio = func {
    var airsrc = getprop("controls/ventilation/airconditioning-source");
    var transfer = getprop("controls/fuel/external-transfer");
    var master = getprop("fdm/jsbsim/elec/switches/master-fuel");

    if (airsrc == AIR_SOURCE_OFF or airsrc == AIR_SOURCE_RAM) { # OFF/RAM
        tank_priority[TANK_EXT_LEFT] = 0;
        tank_priority[TANK_EXT_RIGHT] = 0;
        tank_priority[TANK_EXT_CENTER] = 0;
        if (maxtank == 9) tank_priority[TANK_EXT_CFT] = 0;
    } else { # NORM/DUMP
        if (transfer == FUEL_TRANS_WING) { # Ext wing first
            tank_priority[TANK_EXT_LEFT] = 2;
            tank_priority[TANK_EXT_RIGHT] = 2;
            tank_priority[TANK_EXT_CENTER] = 3;
            if (maxtank == 9) tank_priority[TANK_EXT_CFT] = 3;
        } else { # Norm
            tank_priority[TANK_EXT_LEFT] = 3;
            tank_priority[TANK_EXT_RIGHT] = 3;
            tank_priority[TANK_EXT_CENTER] = 2;
            if (maxtank == 9) tank_priority[TANK_EXT_CFT] = 2;
        }
    }

    if (master) {
        setprop("/fdm/jsbsim/propulsion/tank[6]/priority", tank_priority[TANK_EXT_LEFT]);
        setprop("/fdm/jsbsim/propulsion/tank[7]/priority", tank_priority[TANK_EXT_RIGHT]);
        setprop("/fdm/jsbsim/propulsion/tank[8]/priority", tank_priority[TANK_EXT_CENTER]);
        if (maxtank == 9) setprop("/fdm/jsbsim/propulsion/tank[9]/priority", tank_priority[TANK_EXT_CFT]);
    }
}

#set_ext_tank_prio();

# Fuel transfer switch
#setlistener("controls/fuel/external-transfer", func {
#    set_ext_tank_prio();
#}, 0, 0);

# Fuel tank pressurization
#setlistener("controls/ventilation/airconditioning-source", func {
#    set_ext_tank_prio();
#}, 0, 0);

var fuelDigits = func {# this method is not in use
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
