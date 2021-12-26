# FUEL ==============================================================


var fuelqty = func {
  var sel = getprop("controls/fuel/qty-selector");
  var fuel = getprop("/consumables/fuel/total-fuel-lbs");
  var fwdFuel = getprop("consumables/fuel/tank[0]/level-lbs") + getprop("consumables/fuel/tank[4]/level-lbs");
  var aftFuel = getprop("consumables/fuel/tank[3]/level-lbs") + getprop("consumables/fuel/tank[5]/level-lbs");

  # Bingo fuel determination
  if (fuel<getprop("f16/settings/bingo") or (sel == 1 and (fwdFuel+aftFuel)<getprop("f16/settings/bingo"))) {
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

  # Automatic forward fuel transfer system
  # Notes:
  # - The fuel system diagram doesn't make it clear, assumed here that A-1 fuel is
  #   transfered to the F-1 + F-2 combined tank.
  # - This does not take into consideration any unusable fuel, but does try to prevent
  #   'ghost fuel' from being created.
  # - Transfer rate is unknown. The assumed value fits flight idle to AB burn rates.
  if (getprop("fdm/jsbsim/elec/bus/emergency-dc-2") > 20 and sel == 1 and fwdFuel < 2800) {
    if (fwdFuel - aftFuel < 300 and
      getprop("consumables/fuel/tank[0]/level-norm") < 0.99 and
      getprop("consumables/fuel/tank[3]/level-norm") > 0.01) {
      # start fwd fuel transfer
      setprop("/fdm/jsbsim/propulsion/tank[3]/external-flow-rate-pps", -1);  # from aft
      setprop("/fdm/jsbsim/propulsion/tank[0]/external-flow-rate-pps", 1);   # to fwd
    } elsif (fwdFuel - aftFuel > 450 or
      getprop("consumables/fuel/tank[0]/level-norm") >= 0.99 or
      getprop("consumables/fuel/tank[3]/level-norm") <= 0.01) {
      # stop fwd fuel transfer, if any
      setprop("/fdm/jsbsim/propulsion/tank[3]/external-flow-rate-pps", 0);
      setprop("/fdm/jsbsim/propulsion/tank[0]/external-flow-rate-pps", 0);
    }
  } else {
    # stop fwd fuel transfer, if any
    setprop("/fdm/jsbsim/propulsion/tank[3]/external-flow-rate-pps", 0);
    setprop("/fdm/jsbsim/propulsion/tank[0]/external-flow-rate-pps", 0);
  }

  # Power requirement check for following systems
  if (getprop("fdm/jsbsim/elec/bus/emergency-ac-2")<100) {
    return;
  }

  # Fuel quantity indication
  if (sel == 0) {
    # test
    setprop("f16/fuel/hand-fwd", 2000);
    setprop("f16/fuel/hand-aft", 2000);
    fuel = 6000;
  } elsif (sel == 1) {
    #norm
    setprop("f16/fuel/hand-fwd", fwdFuel);
    setprop("f16/fuel/hand-aft", aftFuel);
  } elsif (sel == 2) {
    #reservoir tanks
    setprop("f16/fuel/hand-fwd", getprop("consumables/fuel/tank[4]/level-lbs"));
    setprop("f16/fuel/hand-aft", getprop("consumables/fuel/tank[5]/level-lbs"));
  } elsif (sel == 3) {
    # int wing
    setprop("f16/fuel/hand-fwd", getprop("consumables/fuel/tank[2]/level-lbs")); # right
    setprop("f16/fuel/hand-aft", getprop("consumables/fuel/tank[1]/level-lbs")); # left
  } elsif (sel == 4) {
    # ext wing
    setprop("f16/fuel/hand-fwd", getprop("consumables/fuel/tank[7]/level-lbs")); 
    setprop("f16/fuel/hand-aft", getprop("consumables/fuel/tank[6]/level-lbs"));
  } elsif (sel == 5) {
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

    if (feed == 1) { # NORM
        tank_priority[0] = 5;
        tank_priority[3] = 5;
    } elsif (feed == 2) { # AFT
        tank_priority[0] = 5;
        tank_priority[3] = 1;
    } elsif (feed == 3) { # FWD
        tank_priority[0] = 1;
        tank_priority[3] = 5;
    }

    if (master) {
        setprop("/fdm/jsbsim/propulsion/tank[0]/priority", tank_priority[0]);
        setprop("/fdm/jsbsim/propulsion/tank[3]/priority", tank_priority[3]);
    }
}, 1, 0);

var set_ext_tank_prio = func {
    var airsrc = getprop("controls/ventilation/airconditioning-source");
    var transfer = getprop("controls/fuel/external-transfer");
    var master = getprop("fdm/jsbsim/elec/switches/master-fuel");

    if (airsrc == 0 or airsrc == 3) { # OFF/RAM
        tank_priority[6] = 0;
        tank_priority[7] = 0;
        tank_priority[8] = 0;
        if (maxtank == 9) tank_priority[9] = 0;
    } else { # NORM/DUMP
        if (transfer == 0) { # Ext wing first
            tank_priority[6] = 2;
            tank_priority[7] = 2;
            tank_priority[8] = 3;
            if (maxtank == 9) tank_priority[9] = 3;
        } else { # Norm
            tank_priority[6] = 3;
            tank_priority[7] = 3;
            tank_priority[8] = 2;
            if (maxtank == 9) tank_priority[9] = 2;
        }
    }

    if (master) {
        setprop("/fdm/jsbsim/propulsion/tank[6]/priority", tank_priority[6]);
        setprop("/fdm/jsbsim/propulsion/tank[7]/priority", tank_priority[7]);
        setprop("/fdm/jsbsim/propulsion/tank[8]/priority", tank_priority[8]);
        if (maxtank == 9) setprop("/fdm/jsbsim/propulsion/tank[9]/priority", tank_priority[9]);
    }
}

set_ext_tank_prio();

# Fuel transfer switch
setlistener("controls/fuel/external-transfer", func {
    set_ext_tank_prio();
}, 0, 0);

# Fuel tank pressurization
setlistener("controls/ventilation/airconditioning-source", func {
    set_ext_tank_prio();
}, 0, 0);

var fuelDigits = func {
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
