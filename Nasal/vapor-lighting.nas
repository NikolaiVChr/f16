var ltimer = maketimer(1.0, func {
   var ground_color = getprop("/rendering/scene/diffuse/red");
   var color_altitude = getprop("/rendering/dome/cloud/red");
   var alt = getprop("position/altitude-ft");

   var norm = alt/15000;
   var color = norm*color_altitude + (1-norm)*ground_color;

   setprop("/sim/model/f16/strake-color", color);
   }
);

# start the timer
ltimer.start();
