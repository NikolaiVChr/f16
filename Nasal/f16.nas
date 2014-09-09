# $Id$

# strobes ===========================================================
var strobe_switch = props.globals.getNode("controls/lighting/ext-lighting-panel/anti-collision", 1);
aircraft.light.new("sim/model/lighting/strobe", [0.03, 1.9+rand()/5], strobe_switch);

setlistener("/sim/current-view/view-number", func(n) {
        setprop("/sim/hud/visibility[1]", !n.getValue());
}, 1);
