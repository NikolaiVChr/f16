var line1 = nil;
var line2 = nil;
var line3 = nil;
var line4 = nil;
var line5 = nil;
var callInit = func {
  canvaspfd = canvas.new({
        "name": "PFD",
        "size": [256, 128],
        "view": [256, 128],
        "mipmapping": 0
  });
      
  canvaspfd.addPlacement({"node": "PFDscreen", "texture": "canvas.png"});
  if (getprop("sim/variant-id") == 2) {
        canvaspfd.setColorBackground(0.00, 0.04, 0.01, 1.00);
  } else if (getprop("sim/variant-id") == 4) {
        canvaspfd.setColorBackground(0.00, 0.04, 0.01, 1.00);
  } else if (getprop("sim/variant-id") == 5) {
        canvaspfd.setColorBackground(0.00, 0.04, 0.01, 1.00);
  } else if (getprop("sim/variant-id") == 6) {
        canvaspfd.setColorBackground(0.00, 0.04, 0.01, 1.00);
  } else {
        canvaspfd.setColorBackground(0.01, 0.075, 0.00, 1.00);
  }

  pfdGroup = canvaspfd.createGroup();
  pfdGroup.show();
  var color = [0.45,0.98,0.06];
  line1 = pfdGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("left-bottom-baseline")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("LINE 1            LINE 1")
        .setTranslation(55, 128*0.2);
  line2 = pfdGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("left-bottom-baseline")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("LINE 2            LINE 2")
        .setTranslation(55, 128*0.3);
  line3 = pfdGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("left-bottom-baseline")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("LINE 3            LINE 3")
        .setTranslation(55, 128*0.4);
  line4 = pfdGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("left-bottom-baseline")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("LINE 4            LINE 4")
        .setTranslation(55, 128*0.5);
  line5 = pfdGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("left-bottom-baseline")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("LINE 5            LINE 5")
        .setTranslation(55, 128*0.6);
};

var scrollF = 0;
var text = ["","","","",""];

var loop_pfd = func {
    var no = getprop("autopilot/route-manager/current-wp")+1;
    if (no == 0) {
      no = "";
    } else {
      no = sprintf("%2d",no);
    }
  var fails = fail.getList();
	var last = size(fails);
  text[0] = sprintf("  %s     %s     %s",(fail.fail_master[0] or fail.fail_master[1])?"FLCS":"   ",fail.fail_master[2]?"ENG":"   ",fail.fail_master[3]?"AV":"  ");# Source: GR1F-F16CJ-34-1 page 1-475
	if (last == 0) {		
		text[1] = sprintf("     ");
		text[2] = "";
		text[3] = "";
		text[4] = "";
	} else {
		var used = subvec(fails,0,3);
		text[1] = sprintf("                        ");
		if (size(used)>0) text[2] = sprintf(" %s ",used[0]);
		else text[2] = "";
		if (size(used)>1) text[3] = sprintf(" %s ",used[1]);
		else text[3] = "";
		if (size(used)>2) text[4] = sprintf(" %s ",used[2]);
		else text[4] = "";
	}
  line1.setText(text[0]);
  line2.setText(text[1]);
  line3.setText(text[2]);
  line4.setText(text[3]);
  line5.setText(text[4]);
  settimer(loop_pfd, 0.5);
};