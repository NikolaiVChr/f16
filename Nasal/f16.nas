# $Id$

# strobes ===========================================================
var strobe_switch = props.globals.getNode("controls/lighting/ext-lighting-panel/anti-collision", 1);
aircraft.light.new("sim/model/lighting/strobe", [0.03, 1.9+rand()/5], strobe_switch);

var checkVNE = func {
  if (getprop("/sim/freeze/replay-state")) {
    settimer(checkVNE, 1);
    return;
  }

  var msg = "";

  # Now check VNE
  var airspeedM= getprop("instrumentation/airspeed-indicator/indicated-mach");
  var vneM     = getprop("limits-custom/mach");
  var airspeed = getprop("instrumentation/airspeed-indicator/indicated-speed-kt");
  var vne      = getprop("limits-custom/vne");
  

  if ((airspeed != nil) and (vne != nil) and (airspeed > vne))
  {
    msg = "Airspeed exceeds Vne!";
  } elsif ((airspeedM != nil) and (vneM != nil) and (airspeedM > vneM)) {
    msg = "Airspeed exceeds Vne!";
  }

  if (msg != "")
  {
    # If we have a message, display it, but don't bother checking for
    # any other errors for 10 seconds. Otherwise we're likely to get
    # repeated messages.
    screen.log.write(msg);
    settimer(checkVNE, 10);
  }
  else
  {
    settimer(checkVNE, 1);
  }
}

checkVNE();