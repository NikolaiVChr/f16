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
        print("EPIC01, in toggleMaster");
        if(master.getBoolValue()) { 
                        print("master is true");
                        master.setBoolValue(0);
        } else {
                        print("master is false");
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
        if(!malIndLts.getBoolValue()) {
                malIndLts.setBoolValue(1);
        } else {
                malIndLts.setBoolValue(0);
        }
 }


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
# Aces II Ejection seat
# =====================

var ejectionSafetyLever = props.globals.getNode("controls/seat/ejection-safety-lever");

 var toggleEjectionSafetyLever = func {
        if(ejectionSafetyLever.getBoolValue()) {
                ejectionSafetyLever.setBoolValue(0);
        } else {
                ejectionSafetyLever.setBoolValue(1);
        }
 }
