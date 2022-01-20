var line1 = nil;
var callInit = func {
  canvasFreqDsply = canvas.new({
        "name": "FRD",
        "size": [256, 64],
        "view": [256, 64],
        "mipmapping": 1
  });
      
  canvasFreqDsply.addPlacement({"node": "freqDisplay", "texture": "navFreq.png"});
  canvasFreqDsply.setColorBackground(0.018, 0.020, 0.05, 1.00);

  freqDsplyGroup = canvasFreqDsply.createGroup();
  freqDsplyGroup.show();
  var color = [0.96,0.99,0.34];
  line1 = freqDsplyGroup.createChild("text")
        .setFontSize(47, 0.90)#higher aspect = thinner font
        .setColor(color)
        .setAlignment("right-bottom-baseline")
        .setFont("DSEG/DSEG14/Classic/DSEG14Classic-Regular.ttf")
        .setText("120.25")
        .setTranslation(256, 60);
  freqDsplyGroup.createChild("path")
                .moveTo(127,60)
                .horiz(3)
                .vert(-4)
                .horiz(-3)
                .vert(4)
                .setStrokeLineWidth(1)
                .setColor(color)
                .setColorFill(color);
};

var loop_freqDsply = func {# one line is max 24 chars
	if (!getprop("f16/avionics/uhf-radio-display-test")) {
      var freq   = getprop("instrumentation/comm[0]/frequencies/selected-mhz");
      freq *= 1000;
      line1.setText(sprintf("%06d",math.round(freq)));
	} else {
	  line1.setText(sprintf("888888"));
	}
    settimer(loop_freqDsply, 0.25);
};