# ======================================
# External Lighting panel (left console)
# ======================================

var master = props.globals.getNode("controls/lighting/ext-lighting-panel/master");
var antiCollision = props.globals.getNode("controls/lighting/ext-lighting-panel/anti-collision");
var posLightsFlash = props.globals.getNode("controls/lighting/ext-lighting-panel/pos-lights-flash");
var wingTail = props.globals.getNode("controls/lighting/ext-lighting-panel/wing-tail");
var fuselage = props.globals.getNode("controls/lighting/ext-lighting-panel/fuselage");
var formation = props.globals.getNode("controls/lighting/ext-lighting-panel/form-knob");
var aerialRefueling = props.globals.getNode("controls/lighting/ext-lighting-panel/ar-knob");


# Initialize the external lighting panel
# ======================================
 var initExtLightingPanel = func {
        if(!master.getBoolValue()) {
                master.setBoolValue(1);
        }
 }       


# Switches
# ========
 var toggleMaster = func {
        if(master.getBoolValue()) { 
                        master.setBoolValue(0);
        } else {
                        master.setBoolValue(1);
        }
 }


 var toggleAntiCollision = func {
        if(master.getBoolValue()) { 
                if(antiCollision.getBoolValue()) {
                        antiCollision.setBoolValue(0);
                } else {
                        antiCollision.setBoolValue(1);
                }       
        }
 }


 var togglePosLightsFlash = func {
        if(posLightsFlash.getBoolValue()) {
                posLightsFlash.setBoolValue(0);
        } else {
                posLightsFlash.setBoolValue(1);
        }
 }

 # Controlling both wing-tail and fuselage switches for now 
 var toggleWingTailUp = func {
        if(wingTail.getValue() == 0) {
                wingTail.setValue(1);
                fuselage.setValue(1);
        } elsif (wingTail.getValue() == 1) {
                wingTail.setValue(2);
                fuselage.setValue(2);
        } 
 } 


 var toggleWingTailDn = func {
        if(wingTail.getValue() == 2) {
                wingTail.setValue(1);
                fuselage.setValue(1);
        } elsif (wingTail.getValue() == 1) {
                wingTail.setValue(0);
                fuselage.setValue(0);
        } 
 }
 
 var toggleWingTail = func {
    wingTail.setValue(!wingTail.getValue());
 }

# Using the wing-tail property for now
 var toggleFuselage = func {
    fuselage.setValue(!fuselage.getValue());
 }

# Using the wing-tail property for now
 var toggleFuselageUp = func {
        if(wingTail.getValue() == 0) {
                wingTail.setValue(1);
                fuselage.setValue(1);
        } elsif (wingTail.getValue() == 1) {
                wingTail.setValue(2);
                fuselage.setValue(2);
        }
 }


 var toggleFuselageDn = func {
        if(wingTail.getValue() == 2) {
                wingTail.setValue(1);
                fuselage.setValue(1);
        } elsif (wingTail.getValue() == 1) {
                wingTail.setValue(0);
                fuselage.setValue(0);
        }
 }
 
 # FIXME this is supposed to be a rotary
 var toggleFormationUp = func {
        if(formation.getValue() == 0) {
                formation.setValue(1);
        }
 }

 var toggleFormationDn = func {
        if(formation.getValue() == 1) {
                formation.setValue(0);
        }
 }
 
 # FIXME this is not supposed to be a toggle
 var toggleAerialRefuelingUp = func {
        if(aerialRefueling.getValue() == 0) {
                aerialRefueling.setValue(1);
        }
 }

 var toggleAerialRefuelingDn = func {
        if(aerialRefueling.getValue() == 1) {
                aerialRefueling.setValue(0);
        }
 }

# =========================
# Test Panel (left console)
# =========================

var malIndLts = props.globals.getNode("controls/test/test-panel/mal-ind-lts");

 var toggleMalIndLts = func {
        if (getprop("fdm/jsbsim/elec/bus/batt-2")<20) {
            malIndLts.setBoolValue(0);
            return;
        }
        if(!malIndLts.getBoolValue()) {
                malIndLts.setBoolValue(1);
        } else {
                malIndLts.setBoolValue(0);
        }
 }

# =========================
# E/J Start Panel (left console)
# =========================

# FIXME: the JFS is more complex in reality 
# (F-16 A/B dash-1 (pdf page 36) (PW220 Engine info starts at pdf page 31)

var jfs = props.globals.getNode("controls/engines/engine/starter");

 var toggleJFS = func {
        if(!jfs.getBoolValue()) {
                jfs.setBoolValue(1);
        } else {
                jfs.setBoolValue(0);
        }
 }

# =========================
# UHF Panel (left console)
# =========================

# Use UHF channel preset mode
 var getPresetUHF = func {
    var ch = props.globals.getNode("sim/model/f16/instrumentation/uhf/selected-preset");
    var getCH = ch.getValue();

    var uhfPreset = props.globals.getNode("sim/model/f16/instrumentation/uhf/presets/preset["~getCH~"]");
    var getPreset = uhfPreset.getValue();

    setprop("instrumentation/comm/frequencies/selected-mhz", getPreset);
 }

getPresetUHF();

# Display active selected UHF frequency

 var getSelectedUHF = func {
    var uhfSelectedFreq = props.globals.getNode("instrumentation/comm/frequencies/selected-mhz");
    var uhfFreq = int(uhfSelectedFreq.getValue() * 1000);

    var toString = ""~uhfFreq~"";

    var altSelMhz100000 = substr(toString, 0, 1) or 0;
    var altSelMhz010000 = substr(toString, 1, 1) or 0;
    var altSelMhz001000 = substr(toString, 2, 1) or 0;
    var altSelMhz000100 = substr(toString, 3, 1) or 0;
    var altSelMhz000011 = substr(toString, 4, 2) or 0;

    #counter some wrong roundings (should always be 00, 25, 50 or 75)
    if (altSelMhz000011 > 00 and altSelMhz000011 <= 25) {
      altSelMhz000011 = 25;
    } else if (altSelMhz000011 > 25 and altSelMhz000011 <= 50) {
      altSelMhz000011 = 50;
    } else if (altSelMhz000011 > 50 and altSelMhz000011 <= 75) {
      altSelMhz000011 = 75;
    } else if (altSelMhz000011 == 99) {
      #frequencies like 100.800 could get rounded to 100.799
      altSelMhz000011 = 00;
      altSelMhz000100 = altSelMhz000100 + 1;
    } else {
      altSelMhz000011 = 00;
    }

    setprop("sim/model/f16/instrumentation/uhf/frequencies/alt-selected-mhz-100000", altSelMhz100000);
    setprop("sim/model/f16/instrumentation/uhf/frequencies/alt-selected-mhz-010000", altSelMhz010000);
    setprop("sim/model/f16/instrumentation/uhf/frequencies/alt-selected-mhz-001000", altSelMhz001000);
    setprop("sim/model/f16/instrumentation/uhf/frequencies/alt-selected-mhz-000100", altSelMhz000100);
    setprop("sim/model/f16/instrumentation/uhf/frequencies/alt-selected-mhz-000011", altSelMhz000011);
 }

getSelectedUHF();

# Manually tune UHF frequency or set GUARD frequency
  
 var setSelectedUHF = func {
    var inputSelect = props.globals.getNode("sim/model/f16/instrumentation/uhf/selector");
    inputSelect = inputSelect.getValue();
    var guardFreq = props.globals.getNode("sim/model/f16/instrumentation/uhf/guard-frequency");
    guardFreq = guardFreq.getValue();

    if(inputSelect == 3) {
      setprop("instrumentation/comm/frequencies/selected-mhz", guardFreq);
    } else if(inputSelect == 2) {

      getPresetUHF();

      var altSelMhz100000 = props.globals.getNode("sim/model/f16/instrumentation/uhf/frequencies/alt-selected-mhz-100000");
      var tempAltSelMhz100000 = altSelMhz100000.getValue();
      var altSelMhz010000 = props.globals.getNode("sim/model/f16/instrumentation/uhf/frequencies/alt-selected-mhz-010000");
      var tempAltSelMhz010000 = altSelMhz010000.getValue();
      var altSelMhz001000 = props.globals.getNode("sim/model/f16/instrumentation/uhf/frequencies/alt-selected-mhz-001000");
      var tempAltSelMhz001000 = altSelMhz001000.getValue();
      var altSelMhz000100 = props.globals.getNode("sim/model/f16/instrumentation/uhf/frequencies/alt-selected-mhz-000100");
      var tempAltSelMhz000100 = altSelMhz000100.getValue();
      var altSelMhz000011 = props.globals.getNode("sim/model/f16/instrumentation/uhf/frequencies/alt-selected-mhz-000011");
      var tempAltSelMhz000011 = altSelMhz000011.getValue();

      var selUHFmhz = tempAltSelMhz100000~tempAltSelMhz010000~tempAltSelMhz001000~"."~tempAltSelMhz000100~tempAltSelMhz000011;

      setprop("instrumentation/comm/frequencies/selected-mhz", selUHFmhz);

      } else {
      var altSelMhz100000 = props.globals.getNode("sim/model/f16/instrumentation/uhf/frequencies/alt-selected-mhz-100000");
      var tempAltSelMhz100000 = altSelMhz100000.getValue();
      var altSelMhz010000 = props.globals.getNode("sim/model/f16/instrumentation/uhf/frequencies/alt-selected-mhz-010000");
      var tempAltSelMhz010000 = altSelMhz010000.getValue();
      var altSelMhz001000 = props.globals.getNode("sim/model/f16/instrumentation/uhf/frequencies/alt-selected-mhz-001000");
      var tempAltSelMhz001000 = altSelMhz001000.getValue();
      var altSelMhz000100 = props.globals.getNode("sim/model/f16/instrumentation/uhf/frequencies/alt-selected-mhz-000100");
      var tempAltSelMhz000100 = altSelMhz000100.getValue();
      var altSelMhz000011 = props.globals.getNode("sim/model/f16/instrumentation/uhf/frequencies/alt-selected-mhz-000011");
      var tempAltSelMhz000011 = altSelMhz000011.getValue();

      var selUHFmhz = tempAltSelMhz100000~tempAltSelMhz010000~tempAltSelMhz001000~"."~tempAltSelMhz000100~tempAltSelMhz000011;

      setprop("instrumentation/comm/frequencies/selected-mhz", selUHFmhz);
    }
 }

setlistener("instrumentation/comm/frequencies/selected-mhz", getSelectedUHF);

# =====================================
# Landing Gear Panel (left aux console)
# =====================================

var hook = props.globals.getNode("fdm/jsbsim/systems/hook/tailhook-cmd-norm");
var landingGear = props.globals.getNode("controls/gear/gear-down");
var landingLights = props.globals.getNode("controls/lighting/landing-lights");
var parkingBrake = props.globals.getNode("controls/gear/brake-parking");

 var toggleHook = func {
        if(!hook.getBoolValue()) {
                hook.setBoolValue(1);
        } else {
                hook.setBoolValue(0);
        }
 }

 var toggleLandingGear = func {
        if(landingGear.getBoolValue()) {
                landingGear.setBoolValue(0);
        } else {
                landingGear.setBoolValue(1);
        }
 }

#FIXME landing lights switch should be 3-way
 var toggleLandingLightsUp = func {
        if(landingLights.getBoolValue()) {
                landingLights.setBoolValue(1);
        } else {
                landingLights.setBoolValue(0);
        }
 }

 var toggleLandingLightsDn = func {
        if(landingLights.getBoolValue()) {
                landingLights.setBoolValue(0);
        } else {
                landingLights.setBoolValue(1);
        }
 }

 var toggleParkingBrake = func {
        if(parkingBrake.getBoolValue()) {
                parkingBrake.setBoolValue(0);
        } else {
                parkingBrake.setBoolValue(1);
        }
 }


# ==============================
# Lighting Panel (right console)
# ==============================

var priInstPnl = props.globals.getNode("controls/lighting/lighting-panel/pri-inst-pnl");
var floodInstPnl = props.globals.getNode("controls/lighting/lighting-panel/flood-inst-pnl");

#FIXME to be transformed to rotary switch
 var togglePriInstPnlUp = func {
        if(priInstPnl.getValue() == 0) {
                priInstPnl.setValue(1);
        } 
 }

#FIXME to be transformed to rotary switch
 var togglePriInstPnlDn = func {
        if(priInstPnl.getValue() == 1) {
                priInstPnl.setValue(0);
        }
 }

#FIXME to be transformed to rotary switch
 var toggleFloodInstPnlUp = func {
        if(floodInstPnl.getValue() == 0) {
                floodInstPnl.setValue(1);
        }
 }

#FIXME to be transformed to rotary switch
 var toggleFloodInstPnlDn = func {
        if(floodInstPnl.getValue() == 1) {
                floodInstPnl.setValue(0);
        }
 }

# =====================
# Throttle
# =====================

var cutoff = props.globals.getNode("controls/engines/engine/cutoff");

 var toggleCutOff = func {
        if(!cutoff.getBoolValue()) {
                cutoff.setBoolValue(1);
        } else {
                cutoff.setBoolValue(0);
        }
 }

# =====================
# F16 Ejection seat
# =====================

var ejectionSafetyLever = props.globals.getNode("controls/seat/ejection-safety-lever");

 var toggleEjectionSafetyLever = func {
        if(ejectionSafetyLever.getBoolValue()) {
                ejectionSafetyLever.setBoolValue(0);
        } else {
                ejectionSafetyLever.setBoolValue(1);
        }
 }
