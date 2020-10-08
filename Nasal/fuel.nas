# FUEL ==============================================================


var fuelqty = func {
  var sel = getprop("controls/fuel/qty-selector");
  var fuel = getprop("/consumables/fuel/total-fuel-lbs");
  var fuseFuel = getprop("consumables/fuel/tank[0]/level-lbs") + getprop("consumables/fuel/tank[3]/level-lbs") + getprop("consumables/fuel/tank[4]/level-lbs") + getprop("consumables/fuel/tank[5]/level-lbs");

  if (fuel<getprop("f16/settings/bingo") or (sel == 1 and fuseFuel<getprop("f16/settings/bingo"))) {
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
    setprop("f16/fuel/hand-fwd", getprop("consumables/fuel/tank[0]/level-lbs") + getprop("consumables/fuel/tank[4]/level-lbs"));
    setprop("f16/fuel/hand-aft", getprop("consumables/fuel/tank[3]/level-lbs") + getprop("consumables/fuel/tank[5]/level-lbs"));
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
    setprop("f16/fuel/hand-fwd", getprop("consumables/fuel/tank[8]/level-lbs"));
    setprop("f16/fuel/hand-aft", 0);
  }
  setprop("/consumables/fuel/total-fuel-lbs-1",     int(fuel       )     -int(fuel*0.1)*10);
  setprop("/consumables/fuel/total-fuel-lbs-10",    int(fuel*0.1   )*10  -int(fuel*0.01)*100);
  setprop("/consumables/fuel/total-fuel-lbs-100",   int(fuel*0.01  )*100 -int(fuel*0.001)*1000);
  setprop("/consumables/fuel/total-fuel-lbs-1000",  int(fuel*0.001 )*1000-int(fuel*0.0001)*10000);
  setprop("/consumables/fuel/total-fuel-lbs-10000", int(fuel*0.0001)*10000);
}


var fuelDigits = func {
  var maxtank = 8;
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