var line1 = nil;
var callInit = func {
  canvasded = canvas.new({
        "name": "FRD",
        "size": [256, 64],
        "view": [256, 64],
        "mipmapping": 1
  });
      
  canvasded.addPlacement({"node": "freqDisplay", "texture": "navFreq.png"});
  canvasded.setColorBackground(0.00, 0.00, 0.00, 1.00);

  dedGroup = canvasded.createGroup();
  dedGroup.show();
  var color = [0.3,1,0.3];
  line1 = dedGroup.createChild("text")
        .setFontSize(50, 0.90)#higher aspect = thinner font
        .setColor(color)
        .setAlignment("right-bottom-baseline")
        .setFont("LED-8.ttf")
        .setText("120.25")
        .setTranslation(256, 60);
  dedGroup.createChild("path")
                .moveTo(126,60)
                .horiz(3)
                .vert(-4)
                .horiz(-3)
                .vert(4)
                .setStrokeLineWidth(1)
                .setColor(color)
                .setColorFill(color);
};

var loop_ded = func {# one line is max 24 chars
      var freq   = getprop("instrumentation/nav[0]/frequencies/selected-mhz");
      freq *= 1000;
      line1.setText(sprintf("%06d",math.round(freq)));
    settimer(loop_ded, 0.25);
};