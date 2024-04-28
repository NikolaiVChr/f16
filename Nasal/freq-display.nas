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





var line2 = nil;
var line3 = nil;
var callInit2 = func {
  if (variant != 2 and variant != 6) return;
  var canvasPrimeDsply = canvas.new({
        "name": "PRIME_MLU",
        "size": [512, 256],
        "view": [512, 256],
        "mipmapping": 1
  });
      
  canvasPrimeDsply.addPlacement({"node": "cmDisplay"});
  canvasPrimeDsply.addPlacement({"node": "jmrDisplay"});
  canvasPrimeDsply.setColorBackground(0.0, 0.0, 0.0, 1.00);

  var primeDsplyGroup = canvasPrimeDsply.createGroup();
  primeDsplyGroup.show();
  var color = [0.96,0.99,0.34];
  line2 = primeDsplyGroup.createChild("text")
        .setFontSize(70, 0.90)#higher aspect = thinner font
        .setColor(color)
        .setAlignment("center-bottom-baseline")
        .setFont("DSEG/DSEG14/Classic/DSEG14Classic-Regular.ttf")
        .setText("120.25")
        .setTranslation(256, 256*0.30);
  line3 = primeDsplyGroup.createChild("text")
        .setFontSize(70, 0.90)#higher aspect = thinner font
        .setColor(color)
        .setAlignment("center-bottom-baseline")
        .setFont("DSEG/DSEG14/Classic/DSEG14Classic-Regular.ttf")
        .setText("120.25")
        .setTranslation(256, 250);
  primeDsplyGroup.createChild("path")
                .moveTo(127,60)
                .horiz(3)
                .vert(-4)
                .horiz(-3)
                .vert(4)
                .setStrokeLineWidth(1)
                .setColor(color)
                .setColorFill(color)
                .hide();
};

var loop_freqDsply = func {# one line is max 24 chars
  if (!getprop("f16/avionics/uhf-radio-display-test")) {
      var freq   = getprop("instrumentation/comm[0]/frequencies/selected-mhz");
      freq *= 1000;
      line1.setText(sprintf("%06d",math.round(freq)));
  } else {
    line1.setText(sprintf("888888"));
  }
  

  if (variant == 2 or variant == 6) {
    # These 3 lines is sim stuff, should not be in this file
    var EWMU_disp = getprop("f16/ews/ew-disp-switch");#cm dispenser
    setprop("f16/avionics/cmds-ch-switch",EWMU_disp);
    setprop("f16/avionics/cmds-fl-switch",EWMU_disp);

    # Display stuff
    var flareCount = sprintf("%03d",getprop("ai/submodels/submodel[0]/count"));
    var chaffCount = flareCount;
    var EWMU_knob = getprop("f16/ews/ew-mode-knob");#0, 1, 2
    var EWMU_jmr = getprop("f16/ews/ew-jmr-switch");    
    var EWMU_chaff = getprop("f16/avionics/cmds-ch-switch");
    var EWMU_flare = getprop("f16/avionics/cmds-fl-switch");
    var EWMU_mws = getprop("f16/ews/ew-mws-switch");#TODO: make MAW and MLW depend on this property
    var EWMU_rwr = getprop("f16/ews/ew-rwr-switch");
    var notquiet = getprop("instrumentation/radar/radar-enable");

    line2.setVisible(EWMU_knob > 0);
    line3.setVisible(EWMU_knob > 0);

    var jmrMode = EWMU_jmr == 0?"OFF":"SBY";
    var jmrMethod = EWMU_jmr == 0?"---":(notquiet==1?methods[jmrMD]:"---");# Not doing anything anyway so just some random stuff

    if (!EWMU_chaff) {
      chaffCount = "OFF";
    }
    if (!EWMU_flare) {
      flareCount = "OFF";
    }

    line2.setText(sprintf("%s  %s",chaffCount,flareCount));

    line3.setText(sprintf("%s  %s",jmrMode,jmrMethod));
  } else {
    setprop("f16/avionics/cmds-ch-switch", getprop("f16/avionics/cmds-fl-switch"));#until better system
  }

  settimer(loop_freqDsply, 0.25);
};

var jmrMD = 0;
var methods = ["INH","SSS","ESI"];
var variant = getprop("sim/variant-id");

setlistener("f16/ews/jmr-md", func (node) {if(node.getValue()==0)return;jmrMD+=1;if(jmrMD==3) jmrMD = 0;});

# EWMS Panels:
#  EWMU (main modes: STBY (no jam, no cm, everything else ON), MAN, EWMI, AUTO)
#  EWPI (MLU prime):
#  RWR Display