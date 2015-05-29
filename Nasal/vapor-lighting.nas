
var color_r_n = props.getNode("/rendering/scene/diffuse/red");
var color_g_n = props.getNode("/rendering/scene/diffuse/green");
var color_b_n = props.getNode("/rendering/scene/diffuse/blue");
var scattering_n = props.getNode("/rendering/scene/scattering");

var vapor_r_n = props.getNode("/sim/model/f16/vapor/red");
var vapor_g_n = props.getNode("/sim/model/f16/vapor/green");
var vapor_b_n = props.getNode("/sim/model/f16/vapor/blue");


var ltimer = maketimer(1.0, func {
   vapor_r_n.setValue(color_r_n.getValue()*scattering_n.getValue());
   vapor_g_n.setValue(color_g_n.getValue()*scattering_n.getValue());
   vapor_b_n.setValue(color_b_n.getValue()*scattering_n.getValue());
   }
);

# start the timer
ltimer.start();
