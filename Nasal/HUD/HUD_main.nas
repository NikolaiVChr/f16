# Canvas HUD
# ---------------------------
# HUD uses data in the frame notification
# HUD is in two parts so we have a single class that we can instantiate
# twice on for each combiner pane
# ---------------------------
# Richard Harrison (rjh@zaretto.com) 2016-07-01  - based on F-15 HUD
# ---------------------------
#setprop("a-alt",-10);#13
#setprop("a-spd",  0);#5
#setprop("a-rll",  0);#16
var skew_alt = 0;
var skew_spd = 0;
var skew_rll = 0;
var skew_hdg = 0;
#setprop("a-mask",1.32);
var flirImageReso = 16;
var transfer_dist = "";
var transfer_mode = "";
var transfer_arms = "";
var transfer_g    = "";
var transfer_stpt = "";
var transfer_fuel_bullseye = "";

var ht_debug = 0;

var alt_range_factor = (9317-191) / 100000; # alt tape size and max value.
var ias_range_factor = (694-191) / 1100;
var use_war_hud = 0;
var uv_x1 = 0;
var uv_x2 = 0;
var semi_width = 0.0;
var uv_used = uv_x2-uv_x1;
var tran_x = 0;
var tran_y = 0;

var versionString = getprop("sim/version/flightgear");
var version = split(".", versionString);
var major = num(version[0]);
var minor = num(version[1]);
var pica  = num(version[2]);

var F16_HUD = {
    map: func (value, leftMin, leftMax, rightMin, rightMax) {
        # Figure out how 'wide' each range is
        var leftSpan = leftMax - leftMin;
        var rightSpan = rightMax - rightMin;

        # Convert the left range into a 0-1 range (float)
        var valueScaled = (value - leftMin) / leftSpan;

        # Convert the 0-1 range into a value in the right range.
        return rightMin + (valueScaled * rightSpan);
    },

    new : func (svgname, canvas_item, sx, sy){
        var obj = {parents : [F16_HUD] };

        obj.canvas= canvas.new({
                "name": "F16 HUD",
                    "size": [1024,1024],
                    "view": [sx,sy],#340,260
                    "mipmapping": 0, # mipmapping will make the HUD text blurry on smaller screens
                    "additive-blend": 1# bool
                    });



        # Real HUD:
        #
        # F16C: Optics provides a 25degree Total Field of View and a 20o by 13.5o Instantaneous Field of View
        #
        # F16A: Total Field of View of the F-16 A/B PDU is 20deg but the Instantaneous FoV is only 9deg in elevation and 13.38deg in azimuth

        if (getprop("sim/variant-id") == 4) {
            setprop("sim/current-view/z-offset-m", -4.075);
            setprop("sim/current-view/pitch-offset-deg", -15.5);
            setprop("sim/view[0]/z-offset-m", -4.075);
            setprop("sim/view[0]/pitch-offset-deg", -15.5);
            HudMath.init([-4.54553+0.013,-0.057863,0.84791+0.010], [-4.56837+0.013, 0.057863,0.71547+0.010], [sx,sy], [0,1.0], [0.788878,0.0], 0);
            uv_x1 = 0;
            uv_x2 = 0.788878;
            semi_width = 0.05302;# meters
            uv_used = uv_x2-uv_x1;
            tran_x = 0;
            use_war_hud = 1;
            #print(me.map(0,-0.092742, 0.347811, -0.05921, 0));
            # -0.05921   x  0
            # -0.092742  0  0.347811
        } else {
            HudMath.init([-4.53759+0.013,-0.07814,0.85796+0.010], [-4.7148+0.013,0.07924,0.66213+0.010], [sx,sy], [0,1.0], [0.695633,0.0], 0);
            uv_x1 = 0;
            uv_x2 = 0.695633;
            semi_width = 0.07924;
            uv_used = uv_x2-uv_x1;
            tran_x = 0;
        }
        skew_alt = use_war_hud?13:-10;
        skew_spd = use_war_hud?5:0;
        skew_rll = use_war_hud?16:0;
        skew_hdg = use_war_hud?16:0;

        obj.sy = sy;
        obj.sx = sx*uv_used;

        obj.canvas.addPlacement({"node": canvas_item});
        obj.canvas.setColorBackground(0.30, 1, 0.3, 0.00);

        # Create a group for the parsed elements
        obj.svg = obj.canvas.createGroup().hide();
        obj.main_mask = obj.canvas.createGroup().set("z-index",20000);

        # Parse an SVG file and add the parsed elements to the given group
        canvas.parsesvg(obj.svg, svgname);

        obj.hydra = 0;

        obj.canvas._node.setValues({
                "name": "F16 HUD",
                    "size": [1024,1024],
                    "view": [sx,sy],
                    "mipmapping": 0,
                    "additive-blend": 1# bool
                    });

        obj.svg.setTranslation (tran_x,tran_y);

        #obj.VV = obj.get_element("VelocityVector");

        obj.heading_tape = obj.get_element("heading-scale");
        obj.heading_tape_pointer = obj.get_element("path3419");

        obj.roll_pointer = obj.get_element("roll-pointer");
        obj.roll_lines = obj.get_element("g3415");
        obj.roll_lines.hide();
        obj.roll_pointer.hide();


        obj.alt_range = obj.get_element("alt_range");
        obj.ias_range = obj.get_element("ias_range");

        obj.alt_line = obj.get_element("alt_tick_vert_line");
        obj.alt_line.hide();
        obj.vel_line = obj.get_element("ias_tick_vert_line");
        obj.vel_line.hide();
        obj.ias_desired = obj.get_element("path3111");
        obj.ias_desired.hide();
        obj.alt_ind = obj.get_element("path3111-1");
        obj.alt_ind.hide();
        obj.radalt_box = obj.get_element("radalt-box");
        obj.scaling = [obj.get_element("alt_tick_0"),obj.get_element("alt_label0"),obj.heading_tape];
        obj.total   = [obj.get_element("alt_tick_0"),obj.get_element("alt_label0"),obj.heading_tape,obj.heading_tape_pointer];
        for(var ii=1;ii<=1000;ii+=1) {
          var tmp = obj.get_element("alt_tick_"~ii~"00");
          append(obj.scaling, tmp);
          append(obj.total, tmp);
        }
        for(var ii=500;ii<=100000;ii+=500) {
          var tmp = obj.get_element("alt_label"~ii);
          append(obj.scaling, tmp);
          append(obj.total, tmp);
        }
        for(var ii=0;ii<=1100;ii+=20) {
          var tmp = obj.get_element("ias_tick_"~ii);
          append(obj.scaling, tmp);
          append(obj.total, tmp);
        }
        for(var ii=0;ii<=1100;ii+=100) {
          var tmp = obj.get_element("ias_label"~ii);
          append(obj.scaling, tmp);
          append(obj.total, tmp);
        }


        var HUD_FONT = "NotoF16HUD-SemiBold.ttf";#"LiberationFonts/LiberationMono-Regular.ttf";#"condensed.txf";  with condensed the FLYUP text was not displayed until minutes into flight, no clue why
        var HUD_FONT_SIZE_TINY     =   8;
        var HUD_FONT_SIZE_SMALL    =   9;
        var HUD_FONT_SIZE_MEDIUM   =  11;
        var HUD_FONT_SIZE_LARGE    =  13;
        var HUD_FONT_ASPECT_SMALL  = 1.1;
        var HUD_FONT_ASPECT_NARROW = 1.4;
        obj.window1 = obj.get_text("window1", HUD_FONT,HUD_FONT_SIZE_SMALL,HUD_FONT_ASPECT_SMALL).setTranslation(30,-65);
        obj.window2 = obj.get_text("window2", HUD_FONT,HUD_FONT_SIZE_SMALL,HUD_FONT_ASPECT_SMALL);
        obj.window3 = obj.get_text("window3", HUD_FONT,HUD_FONT_SIZE_SMALL,HUD_FONT_ASPECT_SMALL);
        obj.window4 = obj.get_text("window4", HUD_FONT,HUD_FONT_SIZE_SMALL,HUD_FONT_ASPECT_SMALL);
        obj.window5 = obj.get_text("window5", HUD_FONT,HUD_FONT_SIZE_SMALL,HUD_FONT_ASPECT_SMALL);
        obj.window6 = obj.get_text("window6", HUD_FONT,HUD_FONT_SIZE_SMALL,HUD_FONT_ASPECT_SMALL).setAlignment("center-bottom");
        obj.window7 = obj.get_text("window7", HUD_FONT,HUD_FONT_SIZE_SMALL,HUD_FONT_ASPECT_SMALL);
        obj.window8 = obj.get_text("window8", HUD_FONT,HUD_FONT_SIZE_SMALL,HUD_FONT_ASPECT_SMALL);
        obj.window9 = obj.get_text("window9", HUD_FONT,HUD_FONT_SIZE_SMALL,HUD_FONT_ASPECT_SMALL);
        obj.window10 = obj.get_text("window10", HUD_FONT,HUD_FONT_SIZE_SMALL,HUD_FONT_ASPECT_SMALL);
        obj.window11 = obj.get_text("window11", HUD_FONT,HUD_FONT_SIZE_SMALL,HUD_FONT_ASPECT_SMALL);
        obj.window12 = obj.svg.createChild("text")
                .setText("1.0")
                .setTranslation(45,20)
                .setAlignment("right-bottom-baseline")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(HUD_FONT_SIZE_SMALL, HUD_FONT_ASPECT_SMALL);

        obj.ralt = obj.get_text("radalt", HUD_FONT,HUD_FONT_SIZE_SMALL,HUD_FONT_ASPECT_SMALL);
        obj.ralt.setAlignment("right-bottom-baseline");
        obj.ralt.setTranslation(35,0);
        
        #Replace Font in heading tape
        obj.headinTexts = obj.svg.getElementById("heading-scale").getChildrenOfType(canvas.Text);
        foreach(var dir ; obj.headinTexts) {
            dir.setFont(HUD_FONT).setFontSize(HUD_FONT_SIZE_TINY, HUD_FONT_ASPECT_SMALL);
        }
        obj.headinTexts = obj.svg.getElementById("ias_range").getChildrenOfType(canvas.Text);
        foreach(var dir ; obj.headinTexts) {
            dir.setFont(HUD_FONT).setFontSize(HUD_FONT_SIZE_TINY, HUD_FONT_ASPECT_SMALL);
        }
        obj.headinTexts = obj.svg.getElementById("alt_range").getChildrenOfType(canvas.Text);
        foreach(var dir ; obj.headinTexts) {
            dir.setFont(HUD_FONT).setFontSize(HUD_FONT_SIZE_TINY, HUD_FONT_ASPECT_SMALL);
        }

        #obj.alt_range.set("clip", "rect(75px, 10000px, 10000px, -10000px)"); # top,right,bottom,left
        #obj.ias_range.set("clip", "rect(125px, 10000px, 10000px, -10000px)"); # top,right,bottom,left

        #append(obj.total, obj.ladder);
        append(obj.total, obj.heading_tape);
        #append(obj.total, obj.VV);
        append(obj.total, obj.heading_tape_pointer);
        #append(obj.total, obj.roll_pointer);
        #append(obj.total, obj.roll_lines);
        append(obj.total, obj.alt_range);
        append(obj.total, obj.ias_range);
        append(obj.total, obj.alt_line);
        append(obj.total, obj.ias_desired);
        append(obj.total, obj.vel_line);
        append(obj.total, obj.alt_ind);
        append(obj.total, obj.window1);
        append(obj.total, obj.window2);
        append(obj.total, obj.window3);
        append(obj.total, obj.window4);
        append(obj.total, obj.window5);
        append(obj.total, obj.window6);
        append(obj.total, obj.window7);
        append(obj.total, obj.window8);
        append(obj.total, obj.window9);
        append(obj.total, obj.window10);
        append(obj.total, obj.window11);
        append(obj.total, obj.window12);
        append(obj.total, obj.ralt);
        append(obj.total, obj.radalt_box);

        obj.color = [0,1,0];

        obj.layer1 = obj.get_element("layer1");#main svg layer.


# A 2D 3x2 matrix with six parameters a, b, c, d, e and f is equivalent to the matrix:
# a  c  0 e
# b  d  0 f
# 0  0  1 0


        obj.flirPicHD = obj.svg.createChild("image")
                .set("src", "Aircraft/f16/Nasal/HUD/flir"~flirImageReso~".png")
                .setScale(256/flirImageReso,256/flirImageReso)#340,260
                .set("z-index",10001);
        obj.scanY = 0;
        obj.scans = flirImageReso/(getprop("f16/avionics/hud-flir-optimum")?4:2);

        #
        #
        # Load the target symbosl.
        obj.max_symbols = 10;
        obj.tgt_symbols =  setsize([],obj.max_symbols);


#        obj.raltR = obj.svg.createChild("text")
#                .setText("R")
#                .setTranslation(sx*1*0.675633-5,sy*0.45)
#                .setAlignment("right-center")
#                .setColor(0,1,0)
#                .setFont(HUD_FONT)
#                .setFontSize(HUD_FONT_SIZE_SMALL, HUD_FONT_ASPECT_SMALL);
#        obj.raltFrame = obj.svg.createChild("path")
#                .moveTo(sx*1*uv_x2-9,sy*0.45+5)
#                .horiz(-41)
#                .vert(-10)
#                .horiz(41)
#                .vert(10)
#                .setStrokeLineWidth(1)
#                .hide()
#                .setColor(0,1,0);
#              append(obj.total, obj.raltFrame);



        obj.speed_indicator = obj.svg.createChild("path")
                .moveTo(0.25*sx*uv_used,sy*0.245)
                .horiz(7)
                .setStrokeLineWidth(1)
                .setColor(1,0,0);
        obj.alti_indicator = obj.svg.createChild("path")
                .moveTo(0.75*sx*uv_used,sy*0.245)
                .horiz(-7)
                .setStrokeLineWidth(1)
                .setColor(1,0,0);
        append(obj.scaling, obj.alti_indicator);
        append(obj.scaling, obj.speed_indicator);
        append(obj.total, obj.alti_indicator);
        append(obj.total, obj.speed_indicator);
        obj.speed_type = obj.svg.createChild("text")
                .setText("C")
                .setTranslation(1+0.25*sx*uv_used,sy*0.24)
                .setAlignment("left-bottom")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(HUD_FONT_SIZE_SMALL, HUD_FONT_ASPECT_SMALL);
        obj.soi_indicator = obj.svg.createChild("text") # SOI indicator on HUD upper left
                .setText("*")
                .setTranslation(1+0.25*sx*0.60,sy*0.14)
                .setAlignment("left-bottom")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(HUD_FONT_SIZE_MEDIUM, HUD_FONT_ASPECT_SMALL);
        append(obj.total, obj.soi_indicator);
        obj.alt_type = obj.svg.createChild("text")
                .setText("R")
                .setTranslation(-1+0.75*sx*uv_used,sy*0.24)
                .setAlignment("right-bottom")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(HUD_FONT_SIZE_SMALL, HUD_FONT_ASPECT_SMALL);
        append(obj.total, obj.speed_type);
        append(obj.total, obj.alt_type);
        obj.super_mask = obj.main_mask.createChild("image")
                .setTranslation(0,0)
                #.set("blend-source-rgb","one")
                #.set("blend-source-alpha","one")
                .set("blend-source","zero")
                .set("blend-destination-rgb","one")
                .set("blend-destination-alpha","one-minus-src-alpha")
                #.set("blend-destination","zero")
                .set("src", "Aircraft/f16/Nasal/HUD/main_mask.png");
        if (use_war_hud) {
            #obj.super_mask.hide();
            obj.super_mask.setScale(1.132,1);
        }
        obj.speed_mask = obj.svg.createChild("image")
                .setTranslation(-27+0.21*sx*uv_used,sy*0.245-6)
                .set("z-index",10000)
                #.set("blend-source-rgb","one")
                #.set("blend-source-alpha","one")
                .set("blend-source","zero")
                .set("blend-destination-rgb","one")
                .set("blend-destination-alpha","one-minus-src-alpha")
                #.set("blend-destination","zero")
                .set("src", "Aircraft/f16/Nasal/HUD/speed_mask.png");
        obj.speed_frame = obj.svg.createChild("path")
                .set("z-index",10001)
                .moveTo(2+0.20*sx*uv_used,sy*0.245)
                .lineTo(2+0.20*sx*uv_used-5,sy*0.245-6)
                .horiz(-25)
                .vert(12)
                .horiz(25)
                .lineTo(2+0.20*sx*uv_used,sy*0.245)
                .setStrokeLineWidth(1)
                .setColor(1,0,0);
                append(obj.total, obj.speed_frame);
        obj.speed_curr = obj.svg.createChild("text")
                .set("z-index",10002)
                .set("blend-source-rgb","one")
                .set("blend-source-alpha","one")
                .set("blend-destination-rgb","one")
                .set("blend-destination-alpha","one")
                .setText("425")
                .setTranslation(0.18*sx*uv_used,sy*0.245)
                .setAlignment("right-center")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(HUD_FONT_SIZE_SMALL, HUD_FONT_ASPECT_SMALL);
append(obj.total, obj.speed_curr);
        obj.alt_mask = obj.svg.createChild("image")
                .setTranslation(5+3+0.79*sx*uv_used-10,sy*0.245-6)
                .set("z-index",10000)
                #.set("blend-source-rgb","one")
                #.set("blend-source-alpha","one")
                .set("blend-source","zero")
                .set("blend-destination-rgb","one")
                .set("blend-destination-alpha","one-minus-src-alpha")
                #.set("blend-destination","zero")
                .set("src", "Aircraft/f16/Nasal/HUD/alt_mask.png");
        obj.alt_frame = obj.svg.createChild("path")
                .set("z-index",10001)
                .moveTo(8-2+0.80*sx*uv_used-10,sy*0.245)
                .lineTo(8-2+0.80*sx*uv_used+5-10,sy*0.245-6)
                .horiz(28)
                .vert(12)
                .horiz(-28)
                .lineTo(8-2+0.80*sx*uv_used-10,sy*0.245)
                .setStrokeLineWidth(1)
                .setColor(1,0,0);
                append(obj.total, obj.alt_frame);
        obj.alt_curr = obj.svg.createChild("text")
                .set("z-index",10002)
                .set("blend-source-rgb","one")
                .set("blend-source-alpha","one")
                .set("blend-destination-rgb","one")
                .set("blend-destination-alpha","one")
                .setText("88888")
                .setTranslation(4+0.82*sx*uv_used-10,sy*0.245+3.5)
                .setAlignment("left-bottom-baseline")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(HUD_FONT_SIZE_SMALL, HUD_FONT_ASPECT_SMALL);
                append(obj.total, obj.alt_curr);
        obj.head_mask = obj.svg.createChild("image")
                .setTranslation(-10+0.5*sx*uv_used,sy*0.1-20)
                .set("z-index",10000)
                #.set("blend-source-rgb","one")
                #.set("blend-source-alpha","one")
                .set("blend-source","zero")
                .set("blend-destination-rgb","one")
                .set("blend-destination-alpha","one-minus-src-alpha")
                #.set("blend-destination","zero")
                .set("src", "Aircraft/f16/Nasal/HUD/head_mask.png");
                #append(obj.total, obj.head_mask);
        obj.head_frame = obj.svg.createChild("path")
                .set("z-index",10001)
                .moveTo(10+0.50*sx*uv_used,sy*0.1-10)
                .vert(-10)
                .horiz(-20)
                .vert(10)
                .horiz(20)
                .setStrokeLineWidth(1)
                .setColor(1,0,0);
                append(obj.total, obj.head_frame);
        obj.head_curr = obj.svg.createChild("text")
                .set("z-index",10002)
                .set("blend-source-rgb","one")
                .set("blend-source-alpha","one")
                .set("blend-destination-rgb","one")
                .set("blend-destination-alpha","one")
                .setText("360")
                .setTranslation(0.5*sx*uv_used,sy*0.1-12)
                .setAlignment("center-bottom")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(HUD_FONT_SIZE_SMALL, HUD_FONT_ASPECT_SMALL);
                append(obj.total, obj.head_curr);
        obj.ded0 = obj.svg.createChild("text")
                .setText("")
                .setTranslation(0.25*sx*uv_used,sy*0.75-20)
                .setAlignment("left-center")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(HUD_FONT_SIZE_SMALL, HUD_FONT_ASPECT_SMALL);
                append(obj.total, obj.ded0);
        obj.ded1 = obj.svg.createChild("text")
                .setText("")
                .setTranslation(0.25*sx*uv_used,sy*0.75-10)
                .setAlignment("left-center")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(HUD_FONT_SIZE_SMALL, HUD_FONT_ASPECT_SMALL);
                append(obj.total, obj.ded1);
        obj.ded2 = obj.svg.createChild("text")
                .setText("")
                .setTranslation(0.25*sx*uv_used,sy*0.75+0)
                .setAlignment("left-center")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(HUD_FONT_SIZE_SMALL, HUD_FONT_ASPECT_SMALL);
                append(obj.total, obj.ded2);
        obj.ded3 = obj.svg.createChild("text")
                .setText("")
                .setTranslation(0.25*sx*uv_used,sy*0.75+10)
                .setAlignment("left-center")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(HUD_FONT_SIZE_SMALL, HUD_FONT_ASPECT_SMALL);
                append(obj.total, obj.ded3);
        obj.ded4 = obj.svg.createChild("text")
                .setText("")
                .setTranslation(0.25*sx*uv_used,sy*0.75+20)
                .setAlignment("left-center")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(HUD_FONT_SIZE_SMALL, HUD_FONT_ASPECT_SMALL);
                append(obj.total, obj.ded4);
        obj.bombFallLine = obj.svg.createChild("path")
                .moveTo(sx*0.5*uv_used,0)
                #.horiz(10)
                .vert(400)
                .setStrokeLineWidth(1)
                .setColor(0,1,0).hide();
                append(obj.total, obj.bombFallLine);
        obj.solutionCue = obj.svg.createChild("path")#the moving line
                .moveTo(sx*0.5*uv_used-5,0)
                .horiz(10)
                .setStrokeLineWidth(2)
                .set("z-index",10005)
                .setColor(0,1,0);
                append(obj.total, obj.solutionCue);
        obj.ccrpMarker = obj.svg.createChild("path")
                .moveTo(sx*0.5*uv_used-10,sy*0.5)
                .horiz(20)
                .setStrokeLineWidth(1)
                .setColor(0,1,0);
                append(obj.total, obj.ccrpMarker);

        var mr = 0.4;#milliradians
        obj.ASEC262 = obj.svg.createChild("path")#rdsearch (Allowable Steering Error Circle (ASEC))
            .moveTo(-262*mr,0)
            .arcSmallCW(262*mr,262*mr, 0, 262*mr*2, 0)
            .arcSmallCW(262*mr,262*mr, 0, -262*mr*2, 0)
            .setStrokeLineWidth(1)
            .setColor(0,1,0).hide()
            .setTranslation(sx*0.5*uv_used,sy*0.25+262*mr*0.5);
            append(obj.total, obj.ASEC262);
        obj.ASC = obj.svg.createChild("path")# (Attack Steering Cue (ASC))
            .moveTo(-8*mr,0)
            .arcSmallCW(8*mr,8*mr, 0, 8*mr*2, 0)
            .arcSmallCW(8*mr,8*mr, 0, -8*mr*2, 0)
            .setStrokeLineWidth(1)
            .setColor(0,1,0).hide();
            append(obj.total, obj.ASC);

        obj.ASEC100 = obj.svg.createChild("path")#irsearch
            .moveTo(-100*mr,0)
            .arcSmallCW(100*mr,100*mr, 0, 100*mr*2, 0)
            .arcSmallCW(100*mr,100*mr, 0, -100*mr*2, 0)
            .setStrokeLineWidth(1)
            .setColor(0,1,0).hide()
            .setTranslation(sx*0.5*uv_used,sy*0.25);
            append(obj.total, obj.ASEC100);
        obj.ASEC120 = obj.svg.createChild("path")#rdlock
            .moveTo(-120*mr,0)
            .arcSmallCW(120*mr,120*mr, 0, 120*mr*2, 0)
            .arcSmallCW(120*mr,120*mr, 0, -120*mr*2, 0)
            .setStrokeLineWidth(1)
            .setColor(0,1,0).hide()
            .setTranslation(sx*0.5*uv_used,sy*0.25);
            append(obj.total, obj.ASEC120);
        obj.ASEC65 = obj.svg.createChild("path")#irlock
            .moveTo(-65*mr,0)
            .arcSmallCW(65*mr,65*mr, 0, 65*mr*2, 0)
            .arcSmallCW(65*mr,65*mr, 0, -65*mr*2, 0)
            .setStrokeLineWidth(1)
            .setColor(0,1,0).hide()
            .setTranslation(sx*0.5*uv_used,sy*0.25);
            append(obj.total, obj.ASEC65);
        obj.ASEC65Aspect  = obj.svg.createChild("path")#small triangle on ASEC that denotes aspect of target
            .moveTo(0,-65*mr)
            .lineTo(-5*mr,-75*mr)
            .lineTo(5*mr,-75*mr)
            .lineTo(0,-65*mr)
            .setStrokeLineWidth(1)
            .setColorFill(0,1,0)
            .setColor(0,1,0)
            #.set("z-index",10500)
            .setTranslation(sx*0.5*uv_used,sy*0.25);
            append(obj.total, obj.ASEC65Aspect);
        obj.ASEC120Aspect = obj.svg.createChild("path")
            .setCenter(0,0)
            .moveTo(0,-0*mr)
            .lineTo(-5*mr,-10*mr)
            .lineTo(5*mr,-10*mr)
            .lineTo(0,-0*mr)
            .setColorFill(0,1,0)
            .setStrokeLineWidth(1)
            .setColor(0,1,0)
            #.set("z-index",10500)
            .setTranslation(sx*0.5*uv_used,sy*0.25);
            append(obj.total, obj.ASEC120Aspect);

        mr = mr*1.5;#incorrect, but else in FG it will seem too small.

        obj.initUpdate =1;

        obj.alpha = getprop("f16/avionics/hud-sym");
        obj.power = getprop("f16/avionics/hud-power");

        obj.orangePeelGroup = obj.svg.createChild("group")
                                     .setTranslation(sx*uv_used*0.5, sy*0.245);
        append(obj.total, obj.orangePeelGroup);

        obj.dlzX      = sx*uv_used*0.75-16;
        obj.dlzY      = sy*0.4;
        obj.dlzWidth  =  10;
        obj.dlzHeight = sy*0.25;
        obj.dlzLW     =   1;
        obj.dlz      = obj.svg.createChild("group")
                        .setTranslation(obj.dlzX, obj.dlzY);
        append(obj.total, obj.dlz);
        obj.dlz2     = obj.dlz.createChild("group");
        obj.dlzArrow = obj.dlz.createChild("path")
           .moveTo(0, 0)
           .lineTo( -obj.dlzWidth*0.5, obj.dlzWidth*0.4)
           .moveTo(0, 0)
           .lineTo( -obj.dlzWidth*0.5, -obj.dlzWidth*0.4)
           .setColor(1,1,1)
           .setStrokeLineWidth(obj.dlzLW);
        obj.dlzClo = obj.dlz.createChild("text")
                .setText("+3409")
                .setAlignment("right-center")
                .setColor(0,1,0)
                .setFont(HUD_FONT)
                .setFontSize(8, 1.0);
        obj.dlzFCRRange = obj.dlz.createChild("text")
                .setText("XX")
                .setAlignment("center-bottom")
                .setColor(0,1,0)
                .setFont(HUD_FONT)
                .setFontSize(8, 1.0);

        obj.svg.setColor(0.3,1,0.3);

        ############################## new center origin stuff that used hud math #################


        obj.centerOrigin = obj.canvas.createGroup()
                           .setTranslation(HudMath.getCenterOrigin());

        #obj.ASC2 = obj.centerOrigin.createChild("path")# (Attack Steering Cue (ASC))
        #    .moveTo(-8*mr,0)
        #    .arcSmallCW(8*mr,8*mr, 0, 8*mr*2, 0)
        #    .arcSmallCW(8*mr,8*mr, 0, -8*mr*2, 0)
        #    .setStrokeLineWidth(1)
        #    .setColor(1,0,0).hide();
        obj.rollPos = [0,25];
        var tickShort = 8;
        var rollRadius = 50;
        var bankRadius = 15*mr;
        obj.bank_angle_indicator = obj.centerOrigin.createChild("path")
                            .moveTo(0, -bankRadius)
                            .lineTo(0, -bankRadius-tickShort*0.5)
                            .moveTo(math.sin(10*D2R)*bankRadius, -math.cos(10*D2R)*bankRadius)
                            .lineTo(math.sin(10*D2R)*(bankRadius+tickShort*0.2), -math.cos(10*D2R)*(bankRadius+tickShort*0.2))
                            .moveTo(math.sin(-10*D2R)*bankRadius, -math.cos(-10*D2R)*bankRadius)
                            .lineTo(math.sin(-10*D2R)*(bankRadius+tickShort*0.2), -math.cos(-10*D2R)*(bankRadius+tickShort*0.2))
                            .moveTo(math.sin(20*D2R)*bankRadius, -math.cos(20*D2R)*bankRadius)
                            .lineTo(math.sin(20*D2R)*(bankRadius+tickShort*0.2), -math.cos(20*D2R)*(bankRadius+tickShort*0.2))
                            .moveTo(math.sin(-20*D2R)*bankRadius, -math.cos(-20*D2R)*bankRadius)
                            .lineTo(math.sin(-20*D2R)*(bankRadius+tickShort*0.2), -math.cos(-20*D2R)*(bankRadius+tickShort*0.2))
                            .moveTo(math.sin(30*D2R)*bankRadius, -math.cos(30*D2R)*bankRadius)
                            .lineTo(math.sin(30*D2R)*(bankRadius+tickShort*0.5), -math.cos(30*D2R)*(bankRadius+tickShort*0.5))
                            .moveTo(math.sin(-30*D2R)*bankRadius, -math.cos(-30*D2R)*bankRadius)
                            .lineTo(math.sin(-30*D2R)*(bankRadius+tickShort*0.5), -math.cos(-30*D2R)*(bankRadius+tickShort*0.5))
                            .moveTo(math.sin(60*D2R)*bankRadius, -math.cos(60*D2R)*bankRadius)
                            .lineTo(math.sin(60*D2R)*(bankRadius+tickShort*0.5), -math.cos(60*D2R)*(bankRadius+tickShort*0.5))
                            .moveTo(math.sin(-60*D2R)*bankRadius, -math.cos(-60*D2R)*bankRadius)
                            .lineTo(math.sin(-60*D2R)*(bankRadius+tickShort*0.5), -math.cos(-60*D2R)*(bankRadius+tickShort*0.5))
                            .setStrokeLineWidth(1)
                            .setColor(0,1,0);
        obj.roll_lines   = obj.centerOrigin.createChild("path")
                            .moveTo(obj.rollPos[0], obj.rollPos[1]+rollRadius)
                            .lineTo(obj.rollPos[0], obj.rollPos[1]+rollRadius+tickShort*2)
                            .moveTo(obj.rollPos[0]+math.sin(10*D2R)*rollRadius, obj.rollPos[1]+math.cos(10*D2R)*rollRadius)
                            .lineTo(obj.rollPos[0]+math.sin(10*D2R)*(rollRadius+tickShort), obj.rollPos[1]+math.cos(10*D2R)*(rollRadius+tickShort))
                            .moveTo(obj.rollPos[0]+math.sin(20*D2R)*rollRadius, obj.rollPos[1]+math.cos(20*D2R)*rollRadius)
                            .lineTo(obj.rollPos[0]+math.sin(20*D2R)*(rollRadius+tickShort), obj.rollPos[1]+math.cos(20*D2R)*(rollRadius+tickShort))
                            .moveTo(obj.rollPos[0]+math.sin(30*D2R)*rollRadius, obj.rollPos[1]+math.cos(30*D2R)*rollRadius)
                            .lineTo(obj.rollPos[0]+math.sin(30*D2R)*(rollRadius+tickShort*2), obj.rollPos[1]+math.cos(30*D2R)*(rollRadius+tickShort*2))
                            .moveTo(obj.rollPos[0]+math.sin(45*D2R)*rollRadius, obj.rollPos[1]+math.cos(45*D2R)*rollRadius)
                            .lineTo(obj.rollPos[0]+math.sin(45*D2R)*(rollRadius+tickShort*2), obj.rollPos[1]+math.cos(45*D2R)*(rollRadius+tickShort*2))
                            .moveTo(obj.rollPos[0]+math.sin(-10*D2R)*rollRadius, obj.rollPos[1]+math.cos(-10*D2R)*rollRadius)
                            .lineTo(obj.rollPos[0]+math.sin(-10*D2R)*(rollRadius+tickShort), obj.rollPos[1]+math.cos(-10*D2R)*(rollRadius+tickShort))
                            .moveTo(obj.rollPos[0]+math.sin(-20*D2R)*rollRadius, obj.rollPos[1]+math.cos(-20*D2R)*rollRadius)
                            .lineTo(obj.rollPos[0]+math.sin(-20*D2R)*(rollRadius+tickShort), obj.rollPos[1]+math.cos(-20*D2R)*(rollRadius+tickShort))
                            .moveTo(obj.rollPos[0]+math.sin(-30*D2R)*rollRadius, obj.rollPos[1]+math.cos(-30*D2R)*rollRadius)
                            .lineTo(obj.rollPos[0]+math.sin(-30*D2R)*(rollRadius+tickShort*2), obj.rollPos[1]+math.cos(-30*D2R)*(rollRadius+tickShort*2))
                            .moveTo(obj.rollPos[0]+math.sin(-45*D2R)*rollRadius, obj.rollPos[1]+math.cos(-45*D2R)*rollRadius)
                            .lineTo(obj.rollPos[0]+math.sin(-45*D2R)*(rollRadius+tickShort*2), obj.rollPos[1]+math.cos(-45*D2R)*(rollRadius+tickShort*2))
                            .setStrokeLineWidth(1)
                            .setColor(0,1,0);
        obj.roll_pointer = obj.centerOrigin.createChild("path")
                            .moveTo(0, rollRadius+tickShort*2)
                            .lineTo(tickShort*0.5, rollRadius+tickShort*2+tickShort)
                            .lineTo(-tickShort*0.5, rollRadius+tickShort*2+tickShort)
                            .lineTo(0, rollRadius+tickShort*2)
                            .setStrokeLineWidth(1)
                            .setColor(0,1,0);
        append(obj.total, obj.roll_pointer);
        append(obj.total, obj.roll_lines);
        append(obj.total, obj.bank_angle_indicator);

        var fov_y =  0;
        var fov_x = 55;
        var fov_h = 20;
        obj.fov_box = obj.centerOrigin.createChild("path")
                            .moveTo(-fov_x, fov_y)
                            .horiz(fov_x * 2)
                            .vert(fov_h)
                            .horiz(-fov_x * 2)
                            .vert(-fov_h)
                            .setStrokeLineWidth(1)
                            .hide()
                            .setColor(0,1,0);
        append(obj.total, obj.fov_box);

        var vTick = 4;
        var tickSpace = 6;
        obj.vertical_pointer = obj.centerOrigin.createChild("path")
                            .setTranslation(0.25*sx*uv_used-vTick*1.5-8,sy*0.245-sy*0.5)
                            .lineTo(-tickShort*0.66, vTick*0.66)
                            .lineTo(-tickShort*0.66, -vTick*0.66)
                            .lineTo(0, 0)
                            .setStrokeLineWidth(1)
                            .setColor(0,1,0);
        obj.vertical_scale = obj.centerOrigin.createChild("path")
                            .setTranslation(0.25*sx*uv_used-vTick*1.5-8,sy*0.245-sy*0.5)
                            .moveTo(0, 0)
                            .lineTo(vTick*1.5,0)
                            .moveTo(0, tickSpace)
                            .lineTo(vTick,tickSpace)
                            .moveTo(0, -tickSpace)
                            .lineTo(vTick,-tickSpace)
                            .moveTo(0, tickSpace*2)
                            .lineTo(vTick*1.5,tickSpace*2)
                            .moveTo(0, -tickSpace*2)
                            .lineTo(vTick*1.5,-tickSpace*2)
                            .moveTo(0, tickSpace*3)
                            .lineTo(vTick,tickSpace*3)
                            .moveTo(0, -tickSpace*3)
                            .lineTo(vTick,-tickSpace*3)
                            .moveTo(0, tickSpace*4)
                            .lineTo(vTick*1.5,tickSpace*4)
                            .moveTo(0, -tickSpace*4)
                            .lineTo(vTick*1.5,-tickSpace*4)
                            .setStrokeLineWidth(1)
                            .setColor(0,1,0);
        append(obj.total, obj.vertical_pointer);
        append(obj.total, obj.vertical_scale);
        obj.flyupLeft    = obj.centerOrigin.createChild("path")
                            .lineTo(-50,-50)
                            .moveTo(0,0)
                            .lineTo(-50,50)
                            .setStrokeLineWidth(1)
                            .setColor(0,1,0)
                            .hide();
        obj.flyupRight  = obj.centerOrigin.createChild("path")
                            .lineTo(50,-50)
                            .moveTo(0,0)
                            .lineTo(50,50)
                            .setStrokeLineWidth(1)
                            .setColor(0,1,0)
                            .hide();
        append(obj.total, obj.flyupRight);
        append(obj.total, obj.flyupLeft);
        obj.flyup = obj.centerOrigin.createChild("text")
                .setText("FLYUP")
                .setTranslation(0,-75)
                .setAlignment("center-center")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(13, 1.4);
        append(obj.total, obj.flyup);
        obj.stby = obj.centerOrigin.createChild("text")
                .setText("NO RAD")
                .setTranslation(0,0)
                .setAlignment("center-top")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(HUD_FONT_SIZE_MEDIUM, HUD_FONT_ASPECT_SMALL);
          append(obj.total, obj.stby);


        obj.greatCircleSteeringCue = obj.centerOrigin.createChild("path")# nickname: tadpole
            .moveTo(-2.5,0)
            .arcSmallCW(2.5,2.5, 0, 2.5*2, 0)
            .arcSmallCW(2.5,2.5, 0, -2.5*2, 0)
            .moveTo(0,-2.5)
            .vert(-10)
            .setStrokeLineWidth(1)
            .setColor(0,1,0);
        append(obj.total, obj.greatCircleSteeringCue);

        obj.pipperLine = obj.centerOrigin.createChild("group");
        obj.pipperRadius = 15*mr;
        obj.pipper = obj.centerOrigin.createChild("path")
            .moveTo(-obj.pipperRadius,0)
            .arcSmallCW(obj.pipperRadius,obj.pipperRadius, 0, obj.pipperRadius*2, 0)
            .arcSmallCW(obj.pipperRadius,obj.pipperRadius, 0, -obj.pipperRadius*2, 0)
            .moveTo(-2*mr,0)
            .arcSmallCW(2*mr,2*mr, 0, 2*mr*2, 0)
            .arcSmallCW(2*mr,2*mr, 0, -2*mr*2, 0)
            .setStrokeLineWidth(1)
            .setColor(0,1,0);
        #obj.pipperCross = obj.centerOrigin.createChild("path")
        #    .moveTo(-obj.pipperRadius,0)
        #    .horiz(obj.pipperRadius*2)
        #    .moveTo(0,-obj.pipperRadius)
        #    .vert(obj.pipperRadius*2)
        #    .setRotation(45*D2R)
        #    .setStrokeLineWidth(1)
        #    .setColor(0,1,0);
        append(obj.total, obj.pipper);
        append(obj.total, obj.pipperLine);
        var boxRadius = 10;
        var boxRadiusHalf = boxRadius*0.5;
        var hairFactor = 0.8;
        obj.tgt_symbols = [];
        for(var k = 0; k<obj.max_symbols;k+=1) {
            obj.tgt = obj.centerOrigin.createChild("path")
                .moveTo(-boxRadiusHalf,-boxRadiusHalf)
                .vert(boxRadius)
                .horiz(boxRadius)
                .vert(-boxRadius)
                .horiz(-boxRadius)
                .setStrokeLineWidth(1)
                .hide()
                .setColor(0,1,0);
            append(obj.tgt_symbols, obj.tgt);
            append(obj.total, obj.tgt);
        }
        obj.steerPT = obj.centerOrigin.createChild("path")
                .moveTo(-boxRadius*0.3, 0)
                .lineTo(0, boxRadiusHalf*0.85)
                .lineTo(boxRadius*0.3, 0)
                .lineTo(0, -boxRadiusHalf*0.85)
                .lineTo(-boxRadius*0.3, 0)
                .setStrokeLineWidth(1)
                .hide()
                .setColor(0,1,0);
        append(obj.total, obj.steerPT);
        obj.radarLock = obj.centerOrigin.createChild("path")
            .moveTo(-boxRadius*hairFactor,0)
            .horiz(boxRadiusHalf*hairFactor)
            .lineTo(0,boxRadiusHalf*hairFactor)
            .moveTo(boxRadius*hairFactor,0)
            .horiz(-boxRadiusHalf*hairFactor)
            .lineTo(0,-boxRadiusHalf*hairFactor)
            .moveTo(0,boxRadius*hairFactor)
            .vert(-boxRadiusHalf*hairFactor)
            .lineTo(boxRadiusHalf*hairFactor,0)
            .moveTo(0,-boxRadius*hairFactor)
            .vert(boxRadiusHalf*hairFactor)
            .lineTo(-boxRadiusHalf*hairFactor,0)
            .setStrokeLineWidth(1)
            .setColor(0,1,0);
        append(obj.total, obj.radarLock);
        obj.irDiamond = obj.centerOrigin.createChild("path")
            .moveTo(-boxRadius,0)
            .lineTo(0,-boxRadius)
            .lineTo(boxRadius,0)
            .lineTo(0,boxRadius)
            .lineTo(-boxRadius,0)
            .setStrokeLineWidth(1)
            .setColor(0,1,0);
        append(obj.total, obj.irDiamond);
        obj.irDiamondSmall = obj.centerOrigin.createChild("path")
            .moveTo(-boxRadiusHalf*0.75,0)
            .lineTo(0,-boxRadiusHalf*0.75)
            .lineTo(boxRadiusHalf*0.75,0)
            .lineTo(0,boxRadiusHalf*0.75)
            .lineTo(-boxRadiusHalf*0.75,0)
            .setStrokeLineWidth(1)
            .setColor(0,1,0);
        append(obj.total, obj.irDiamondSmall);
        obj.irCross = obj.centerOrigin.createChild("path")
            .moveTo(-boxRadiusHalf*4,0)
            .horiz(boxRadius*4)
            .moveTo(0,-boxRadiusHalf*6)
            .vert(boxRadius*6)
            .setStrokeLineWidth(1)
            .setColor(0,1,0);
        append(obj.total, obj.irCross);
        obj.target_locked = obj.centerOrigin.createChild("path")
            .moveTo(-boxRadius,-boxRadius)
            .vert(boxRadius*2)
            .horiz(boxRadius*2)
            .vert(-boxRadius*2)
            .horiz(-boxRadius*2)
            .setStrokeLineWidth(1)
            .hide()
            .setColor(0,1,0);
        append(obj.total, obj.target_locked);
        obj.aaTargetDesignationGrp = obj.centerOrigin.createChild("group");
        obj.boreSymbol = obj.centerOrigin.createChild("path")
                .moveTo(-5,0)
                .horiz(10)
                .moveTo(0,-5)
                .vert(10)
                .setStrokeLineWidth(1)
                .setColor(0,1,0);
        append(obj.total, obj.boreSymbol);
        var boreY = HudMath.getCenterPosFromDegs(0,-3-4.55*0.5)[1]-HudMath.getCenterPosFromDegs(0,-3+4.55*0.5)[1];
        var boreX = HudMath.getCenterPosFromDegs(3.25*0.5,-3)[0]-HudMath.getCenterPosFromDegs(-3.25*0.5,-3)[0];
        obj.acmBoreSymbol = obj.centerOrigin.createChild("path")
                .moveTo(-boreX/2,0)
                .horiz(boreX)
                .moveTo(0,-boreY/2)
                .vert(boreY)
                .setStrokeLineWidth(1)
                .setColor(0,1,0);
        append(obj.total, obj.acmBoreSymbol);
        obj.acmVertSymbol = obj.centerOrigin.createChild("path")
                .moveTo(0, 10)
                .vert(1000)
                .setStrokeLineWidth(1)
                .setColor(0,1,0);
        append(obj.total, obj.acmVertSymbol);
        obj.locatorAngle = obj.centerOrigin.createChild("text")
                .setText("0")
                .setAlignment("right-center")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(HUD_FONT_SIZE_SMALL, HUD_FONT_ASPECT_SMALL);
        append(obj.total, obj.locatorAngle);
        obj.locatorLine = obj.centerOrigin.createChild("path")
                .moveTo(0,0)
                #.horiz(10)
                .vert(-30)
                .setStrokeLineWidth(1)
                .setColor(0,1,0);
        append(obj.total, obj.locatorLine);

        obj.tgpPointF = obj.centerOrigin.createChild("path")
                     .moveTo(-10*mr, -10*mr)
                     .horiz(20*mr)
                     .vert(20*mr)
                     .horiz(-20*mr)
                     .vert(-20*mr)
                     .moveTo(-1*mr,-1*mr)
                     .horiz(2*mr)
                     .moveTo(-1*mr,0*mr)
                     .horiz(2*mr)
                     .setStrokeLineWidth(1)
                     .setColor(0,0,0);
        obj.tgpPointC = obj.centerOrigin.createChild("path")
                     .moveTo(-10*mr, -10*mr)
                     .lineTo(10*mr, 10*mr)
                     .moveTo(10*mr, -10*mr)
                     .lineTo(-10*mr, 10*mr)
                     .setStrokeLineWidth(1)
                     .setColor(0,0,0);
        append(obj.total, obj.tgpPointF);
        append(obj.total, obj.tgpPointC);


        var bracketsize = HudMath.getPosFromDegs(0,-13)[1]-HudMath.getPosFromDegs(0,-9)[1];#fudge factored for when raising seat it gets higher up in HUD where degrees are less. (is really 11 to 15)
        obj.bracket = obj.centerOrigin.createChild("path")
                .moveTo(0,0)
                .horiz(-10)
                .vert(bracketsize)
                .horiz(10)
                .setStrokeLineWidth(1)
                .setColor(0,1,0);
        append(obj.total, obj.bracket);

        obj.cciplow = obj.centerOrigin.createChild("text")
                .setText("LOW")
                .setTranslation(0,0)
                .setAlignment("left-center")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .hide()
                .setFontSize(HUD_FONT_SIZE_MEDIUM, HUD_FONT_ASPECT_NARROW);
        append(obj.total, obj.cciplow);

        obj.VV = obj.centerOrigin.createChild("path")
            .moveTo(-5*mr,0)
            .arcSmallCW(5*mr,5*mr, 0, 5*mr*2, 0)
            .arcSmallCW(5*mr,5*mr, 0, -5*mr*2, 0)
            .moveTo(-5*mr,0)
            .horiz(-10*mr)
            .moveTo(5*mr,0)
            .horiz(10*mr)
            .moveTo(0,-5*mr)
            .vert(-5*mr)
            .setStrokeLineWidth(1)
            .setColor(0,1,0)
            .set("z-index",11000);
            #.setTranslation(sx*0.5*uv_used,sy*0.25);
        append(obj.total, obj.VV);
        obj.localizer = obj.centerOrigin.createChild("group");

        obj.tfrVertSteeringCue = obj.centerOrigin.createChild("path")
            .moveTo(-30*mr,-10*mr)
            .horiz(60*mr)
            .vert(20*mr)
            .horiz(-60*mr)
            .vert(-20*mr)
            .setStrokeLineWidth(1)
            .setColor(0,1,0);
        append(obj.total, obj.tfrVertSteeringCue);
        obj.tfrVertSteeringCueX = obj.centerOrigin.createChild("path")
            .moveTo(-30*mr,-10*mr)
            .lineTo(30*mr,10*mr)
            .moveTo(30*mr,-10*mr)
            .lineTo(-30*mr,10*mr)
            .setStrokeLineWidth(1)
            .setColor(0,1,0);
        append(obj.total, obj.tfrVertSteeringCueX);

        obj.ilsGroup  = obj.localizer.createChild("group");
        obj.gsGroup   = obj.localizer.createChild("group");
        obj.ils = obj.ilsGroup.createChild("path")
                .moveTo(0,-20)
                .vert(40)
                .moveTo(-2,-20)
                .horiz(4)
                .moveTo(-2,20)
                .horiz(4)
                .moveTo(-2,-10)
                .horiz(4)
                .moveTo(-2,10)
                .horiz(4)
                .setStrokeLineWidth(1)
                .setColor(0,1,0)
                .set("z-index",11000);
        obj.ilsOff = obj.ilsGroup.createChild("path")
                .moveTo(0,-20)
                .vert(4)
                .moveTo(0,-12)
                .vert(4)
                .moveTo(0,-4)
                .vert(8)
                .moveTo(0,8)
                .vert(4)
                .moveTo(0,16)
                .vert(4)
                .moveTo(-2,-20)
                .horiz(4)
                .moveTo(-2,20)
                .horiz(4)
                .moveTo(-2,-10)
                .horiz(4)
                .moveTo(-2,10)
                .horiz(4)
                .setStrokeLineWidth(1)
                .setColor(0,1,0)
                .set("z-index",11000);
        obj.gs = obj.gsGroup.createChild("path")
                .moveTo(-20,0)
                .horiz(40)
                .moveTo(-20,-2)
                .vert(4)
                .moveTo(20,-2)
                .vert(4)
                .moveTo(-10,-2)
                .vert(4)
                .moveTo(10,-2)
                .vert(4)
                .setStrokeLineWidth(1)
                .setColor(0,1,0)
                .set("z-index",11000);
        obj.gsOff = obj.gsGroup.createChild("path")
                .moveTo(-20,0)
                .horiz(4)
                .moveTo(-12,0)
                .horiz(4)
                .moveTo(-4,0)
                .horiz(8)
                .moveTo(8,0)
                .horiz(4)
                .moveTo(16,0)
                .horiz(4)

                .moveTo(-20,-2)
                .vert(4)
                .moveTo(20,-2)
                .vert(4)
                .moveTo(-10,-2)
                .vert(4)
                .moveTo(10,-2)
                .vert(4)
                .setStrokeLineWidth(1)
                .setColor(0,1,0)
                .set("z-index",11000);
    #    obj.inv_v = obj.svg.createChild("path")
    #            .moveTo(0,0)
    #            .lineTo(-4,-5)
    #            .moveTo(0,0)
    #            .lineTo(4,5)
    #            .setStrokeLineWidth(1)
    #            .setColor(0,1,0)
    #            .set("z-index",11000);
        append(obj.total, obj.ils);
        append(obj.total, obj.ilsOff);
        append(obj.total, obj.gs);
        append(obj.total, obj.gsOff);
    #    append(obj.total, obj.inv_v);


        obj.horizon_group = obj.centerOrigin.createChild("group")
          .set("z-order", 1);
        obj.ladder_group = obj.horizon_group.createChild("group");
        obj.h_rot   = obj.horizon_group.createTransform();

        # pitch lines
        var pixelPerDegreeY = HudMath.getPixelPerDegreeAvg(5.0);
        var pixelPerDegreeX = 16.70527172464148;
        var distance = pixelPerDegreeY * 5;
        var minuss = 0.140*sx*uv_used;#Made a little longer since they bend
        var pluss = 0.125*sx*uv_used;
        var minuso = 20*mr;
        for(var i = 1; i <= 17; i += 1) # full drawn lines
          append(obj.total, obj.ladder_group.createChild("path")
             .moveTo(minuso, -i * distance)
             .horiz(pluss)
             .vert(minuso*0.5)

             .moveTo(-minuso, -i * distance)
             .horiz(-pluss)
             .vert(minuso*0.5)

             .setStrokeLineWidth(1)
             .setColor(0,0,0));

        var v = getprop("sim/variant-id");
        var rads = [];
        for(var i = -17; i <= -1; i += 1) { # stipled lines
          var rad = (v==0 or v==1 or v==3)?0:me.extrapolate(-i*5,5,85,8,45)*D2R;#as per US manual pitch lines bend down from 8 to 45 degrees
          append(rads, minuss*math.sin(rad));
          append(obj.total, obj.ladder_group.createChild("path")
                         .moveTo(minuso, -i * distance - minuso*0.5)
                         .vert(minuso*0.5)
                         .lineTo(minuso+minuss*math.cos(rad), -i * distance + minuss*math.sin(rad))
                         
                         .moveTo(-minuso, -i * distance - minuso*0.5)
                         .vert(minuso*0.5)
                         .lineTo(-minuso-minuss*math.cos(rad), -i * distance + minuss*math.sin(rad))
                         
                         .setStrokeLineWidth(1)
                         .setStrokeDashArray([minuso*0.5+minuss*0.1, minuss*0.1, minuss*0.2, minuss*0.1, minuss*0.2, minuss*0.1, minuss*0.2, 0])
                         .setColor(0,0,0));
        }

        obj.zenith = obj.ladder_group.createChild("path")
                        .setTranslation(0, -18 * distance)
                        .moveTo(0,-minuso*1.25)
                        .lineTo(minuso*1/4, -minuso*1.5/3)
                        .lineTo(minuso*2/3, -minuso*2/3)
                        .lineTo(minuso*1.5/3, -minuso*1/4)
                        .lineTo(minuso*1.25,0)
                        .lineTo(minuso*1.5/3, minuso*1/4)
                        .lineTo(minuso*2/3, minuso*2/3)
                        .lineTo(minuso*1/4, minuso*1.5/3)
                        .lineTo(0, minuso*2)
                        .lineTo(-minuso*1/4, minuso*1.5/3)
                        .lineTo(-minuso*2/3, minuso*2/3)
                        .lineTo(-minuso*1.5/3, minuso*1/4)
                        .lineTo(-minuso*1.25,0)
                        .lineTo(-minuso*1.5/3, -minuso*1/4)
                        .lineTo(-minuso*2/3, -minuso*2/3)
                        .lineTo(-minuso*1/4, -minuso*1.5/3)
                        .lineTo(0,-minuso*1.25)
                        .setStrokeLineWidth(1)
                        .setColor(1,0,0);
        append(obj.total, obj.zenith);
        obj.nadir = obj.ladder_group.createChild("path")
                        .setTranslation(0, 18 * distance)
                        .moveTo(-minuso,0)
                        .arcSmallCW(minuso,minuso, 0, minuso*2, 0)
                        .arcSmallCW(minuso,minuso, 0, -minuso*2, 0)
                        .moveTo(0,-minuso)
                        .vert(-minuso)
                        .moveTo(-minuso,0)
                        .horiz(minuso*2)
                        .moveTo(-minuso*0.6614,minuso*0.75)
                        .horiz(minuso*0.6614*2)
                        .moveTo(-minuso*0.6614,-minuso*0.75)
                        .horiz(minuso*0.6614*2)
                        .moveTo(-minuso*0.968,-minuso*0.25)
                        .horiz(minuso*0.968*2)
                        .moveTo(-minuso*0.968,minuso*0.25)
                        .horiz(minuso*0.968*2)
                        .moveTo(-minuso*0.866,minuso*0.5)
                        .horiz(minuso*0.866*2)
                        .moveTo(-minuso*0.866,-minuso*0.5)
                        .horiz(minuso*0.866*2)
                        .setStrokeLineWidth(1)
                        .setColor(1,0,0);
        append(obj.total, obj.nadir);

        #pitch line numbers
        for(var i = -17; i <= 0; i += 1) {
          if (i==0) continue;
          append(obj.total, obj.ladder_group.createChild("text")
             .setText(i*-5)
             .setFontSize(HUD_FONT_SIZE_SMALL, HUD_FONT_ASPECT_SMALL)
             .setFont(HUD_FONT)
             .setAlignment("right-center")
             .setTranslation(-minuso-pluss-pluss*0.2, -i * distance + rads[i])
             .setColor(0,0,0));
          append(obj.total, obj.ladder_group.createChild("text")
             .setText(i*-5)
             .setFontSize(HUD_FONT_SIZE_SMALL, HUD_FONT_ASPECT_SMALL)
             .setFont(HUD_FONT)
             .setAlignment("left-center")
             .setTranslation(minuso+pluss+pluss*0.2, -i * distance + rads[i])
             .setColor(0,0,0));
        }
        for(var i = 1; i <= 17; i += 1) {
          if (i==0) continue;
          append(obj.total, obj.ladder_group.createChild("text")
             .setText(i*5)
             .setFontSize(HUD_FONT_SIZE_SMALL, HUD_FONT_ASPECT_SMALL)
             .setFont(HUD_FONT)
             .setAlignment("right-center")
             .setTranslation(-minuso-pluss-pluss*0.2, -i * distance)
             .setColor(0,0,0));
          append(obj.total, obj.ladder_group.createChild("text")
             .setText(i*5)
             .setFontSize(HUD_FONT_SIZE_SMALL, HUD_FONT_ASPECT_SMALL)
             .setFont(HUD_FONT)
             .setAlignment("left-center")
             .setTranslation(minuso+pluss+pluss*0.2, -i * distance)
             .setColor(0,0,0));
        }

        # approach line
        var i = -0.5;
        pluss *= 0.8;# Approach line is shorter
        obj.appLine = obj.ladder_group.createChild("path")
                         .moveTo(minuso, -i * distance)
                         .horiz(pluss*0.2)
                         .moveTo(minuso+pluss*0.4, -i * distance)
                         .horiz(pluss*0.2)
                         .moveTo(minuso+pluss*0.8, -i * distance)
                         .horiz(pluss*0.2)

                         .moveTo(-minuso, -i * distance)
                         .horiz(-pluss*0.2)
                         .moveTo(-minuso-pluss*0.4, -i * distance)
                         .horiz(-pluss*0.2)
                         .moveTo(-minuso-pluss*0.8, -i * distance)
                         .horiz(-pluss*0.2)

                         .setStrokeLineWidth(1)
                         .setColor(0,0,0);

        append(obj.total, obj.appLine);

        #Horizon line
        append(obj.total, obj.ladder_group.createChild("path")
                         .moveTo(-0.50*sx*uv_used, 0)
                         .horiz(0.50*sx*uv_used-20*mr)
                         .moveTo(20*mr, 0)
                         .horiz(0.50*sx*uv_used-20*mr)
                         .setStrokeLineWidth(1)
                         .setColor(0,0,0));


        obj.thermometerScaleGrp = obj.svg.createChild("group");
        obj.thermoGroup = obj.thermometerScaleGrp.createChild("group");
        obj.thermoXstart = 0.80*sx*uv_used;
        obj.thermoYstart = sy*0.39;
        obj.thermoY100   = sy*0.03;
        obj.thermometerText2 = obj.thermometerScaleGrp.createChild("text")
                .setText("2")
                .setFontSize(8,1.1)
                .setFont(HUD_FONT)
                .setAlignment("left-center")
                .setTranslation(obj.thermoXstart+5,sy*0.33);
        obj.thermometerText4 = obj.thermometerScaleGrp.createChild("text")
                .setText("4")
                .setFontSize(8,1.1)
                .setFont(HUD_FONT)
                .setAlignment("left-center")
                .setTranslation(obj.thermoXstart+5,sy*0.27);
        obj.thermometerText6 = obj.thermometerScaleGrp.createChild("text")
                .setText("6")
                .setFontSize(8,1.1)
                .setFont(HUD_FONT)
                .setAlignment("left-center")
                .setTranslation(obj.thermoXstart+5,sy*0.21);
        obj.thermometerText8 = obj.thermometerScaleGrp.createChild("text")
                .setText("8")
                .setFontSize(8,1.1)
                .setFont(HUD_FONT)
                .setAlignment("left-center")
                .setTranslation(obj.thermoXstart+5,sy*0.15);
        obj.thermometerText10 = obj.thermometerScaleGrp.createChild("text")
                .setText("10")
                .setFontSize(8,1.1)
                .setFont(HUD_FONT)
                .setAlignment("left-center")
                .setTranslation(obj.thermoXstart+5,sy*0.09);
        obj.thermometerText15 = obj.thermometerScaleGrp.createChild("text")
                .setText("15")
                .setFontSize(8,1.1)
                .setFont(HUD_FONT)
                .setAlignment("left-center")
                .setTranslation(obj.thermoXstart+5,sy*0.06);
        obj.thermometerScale = obj.thermometerScaleGrp.createChild("path")
                .moveTo(obj.thermoXstart,sy*0.39)#0
                .horiz(5)
                .moveTo(obj.thermoXstart,sy*0.375)
                .horiz(3)
                .moveTo(obj.thermoXstart,sy*0.36)
                .horiz(5)
                .moveTo(obj.thermoXstart,sy*0.345)
                .horiz(3)
                .moveTo(obj.thermoXstart,sy*0.33)#2
                .horiz(5)
                .moveTo(obj.thermoXstart,sy*0.315)
                .horiz(3)
                .moveTo(obj.thermoXstart,sy*0.30)
                .horiz(5)
                .moveTo(obj.thermoXstart,sy*0.285)
                .horiz(3)
                .moveTo(obj.thermoXstart,sy*0.27)#4
                .horiz(5)
                .moveTo(obj.thermoXstart,sy*0.255)
                .horiz(3)
                .moveTo(obj.thermoXstart,sy*0.24)
                .horiz(5)
                .moveTo(obj.thermoXstart,sy*0.225)
                .horiz(3)
                .moveTo(obj.thermoXstart,sy*0.21)#6
                .horiz(5)
                .moveTo(obj.thermoXstart,sy*0.195)
                .horiz(3)
                .moveTo(obj.thermoXstart,sy*0.18)
                .horiz(5)
                .moveTo(obj.thermoXstart,sy*0.165)
                .horiz(3)
                .moveTo(obj.thermoXstart,sy*0.15)#8
                .horiz(5)
                .moveTo(obj.thermoXstart,sy*0.135)
                .horiz(3)
                .moveTo(obj.thermoXstart,sy*0.12)
                .horiz(5)
                .moveTo(obj.thermoXstart,sy*0.105)
                .horiz(3)
                .moveTo(obj.thermoXstart,sy*0.09)#10
                .horiz(5)
                .moveTo(obj.thermoXstart,sy*0.075)
                .horiz(3)
                .moveTo(obj.thermoXstart,sy*0.06)#15
                .horiz(5)
                .setStrokeLineWidth(1)
                .setColor(1,0,0);

        append(obj.total, obj.thermometerScale);
        append(obj.total, obj.thermometerText2);
        append(obj.total, obj.thermometerText4);
        append(obj.total, obj.thermometerText6);
        append(obj.total, obj.thermometerText8);
        append(obj.total, obj.thermometerText10);
        append(obj.total, obj.thermometerText15);
        append(obj.scaling, obj.thermometerScaleGrp);
        obj.hidingScales = 0;

        
        #
        # set the update list - using the update manager to improve the performance
        # of the HUD update - without this there was a drop of 20fps (when running at 60fps)
        obj.update_items = [
            props.UpdateManager.FromHashList(["hud_serviceable", "hud_display", "hud_sym", "hud_power", "hud_daytime", "red"], 0.05, func(hdp)#changed to 0.1, this function is VERY heavy to run.
                                      {
# print("HUD hud_serviceable=", hdp.getproper("hud_serviceable," display=", hdp.getproper("hud_display, " brt=", hdp.getproper("hud_sym, " power=", hdp.getproper("hud_power);

                                          if (!hdp.hud_display or !hdp.hud_serviceable) {
                                            obj.svg.hide();
                                            obj.color = [0.3,1,0.3,0];
                                            foreach(item;obj.total) {
                                              item.setColor(obj.color);
                                            }
                                            obj.ASEC120Aspect.setColorFill(obj.color);
                                            obj.ASEC65Aspect.setColorFill(obj.color);
                                          } elsif (hdp.hud_sym != nil and hdp.hud_power != nil) {
                                            obj.svg.show();
                                            var brt = hdp.hud_sym * hdp.hud_power;
                                            # Ref: GR1F-16CJ-34-1-1 page 1-158, adjusted up slightly
                                            var night_ratio = 0.75;
                                            if (hdp.hud_daytime == 0) { # Auto
                                                obj.daylight_red = math.min(1, obj.extrapolate(hdp.red, 0, 0.85, 0, 1));# treat 0.85 as full day light, so it dont have to june and noon at equator to get full brightness
                                                brt *= (night_ratio + (obj.daylight_red * (1 - night_ratio)));
                                            } elsif (hdp.hud_daytime == -1) { # Night
                                                brt *= night_ratio;
                                            }
                                            obj.color = [0.3,1,0.3,brt];
                                            foreach(item;obj.total) {
                                              item.setColor(obj.color);
                                            }
                                            obj.ASEC120Aspect.setColorFill(obj.color);
                                            obj.ASEC65Aspect.setColorFill(obj.color);
                                          }
                                      }),
             func(hdp)
                                      {
                                        if (!hdp.getproper("dgft") and !hdp.getproper("gear_down")) {
                                          # IAS range clip is set to 79.739967, so let's stay within that
                                          var minmax_range = 79.739967/2;
                                          if (getprop("f16/ded/cur-crus-mode") == "TOS") {
                                            var desired_kt = getprop("/f16/ded/crus-req-gs");
                                            if (desired_kt != nil) {
                                              obj.ias_desired.show();
                                              obj.ias_desired.setTranslation(0, math.max(math.min((hdp.getproper("groundspeed_kt")-desired_kt) * ias_range_factor,minmax_range),-minmax_range));
                                            } else {
                                              obj.ias_desired.hide();
                                            }
                                          } else {
                                            obj.ias_desired.hide();
                                          }
                                        } else {
                                          obj.ias_desired.hide();
                                        }
                                      },
            #props.UpdateManager.FromHashList([], 0.01,
             func(hdp)
                                      {
                                      },
            #props.UpdateManager.FromHashList(["master_arm", "altitude_ft", "roll", "groundspeed_kt", "density_altitude", "mach", "speed_down_fps", "speed_east_fps", "speed_north_fps"], 0.01,
             func(hdp)
                                      {
                                          if (hdp.fcs_available) {
                                            if (pylons.fcs.getDropMode() == fc.DROP_CCIP) {
                                                hdp.CCIP_active = 1;
                                            } else {
                                                hdp.CCIP_active = 0;
                                            }
                                          } else {
                                              hdp.CCIP_active = 0;
                                          }
                                          obj.timeToRelease = nil;
                                          hdp.CCRP_active = obj.CCRP(hdp);
                                          var lw = obj.CCIP(hdp);
                                          if (lw==-1) {
                                            obj.cciplow.setTranslation(hdp.VV_x+15,hdp.VV_y);
                                            obj.cciplow.show();
                                          } else {
                                            obj.cciplow.hide();
                                          }
                                      },
            #props.UpdateManager.FromHashList(["texUp", "heading","VV_x","VV_y", "dgft"], 0.01,
             func(hdp)
                                             {
                                                 # the Y position is still not accurate due to HUD being at an angle, but will have to do.
                                                 if (steerpoints.getCurrentNumber() != 0 and !hdp.getproper("dgft")) {
                                                     obj.steerDir = steerpoints.getCurrentDirectionForHUD();
                                                     obj.wpbear = obj.steerDir[0];
                                                     if (obj.wpbear!=nil) {
                                                         obj.wpbear=geo.normdeg180(obj.wpbear-hdp.getproper("heading"));
                                                         obj.tadpoleX = HudMath.getCenterPosFromDegs(obj.wpbear,0)[0];

                                                         if (obj.tadpoleX>obj.sx*0.20) {
                                                             obj.tadpoleX=obj.sx*0.20;
                                                         } elsif (obj.tadpoleX<-obj.sx*0.20) {
                                                             obj.tadpoleX=-obj.sx*0.20;
                                                         }
                                                         obj.greatCircleSteeringCue.setTranslation(obj.tadpoleX, hdp.VV_y);
                                                         obj.greatCircleSteeringCue.setRotation(obj.wpbear*D2R);
                                                         obj.greatCircleSteeringCue.show();
                                                         if (obj.steerDir[1] != nil) {
                                                            obj.steerCart = vector.Math.eulerToCartesian2(-obj.steerDir[0], obj.steerDir[1]);
                                                            obj.steerLocal = vector.Math.yawPitchRollVector(hdp.getproper("heading"), -hdp.getproper("pitch"), -hdp.getproper("roll"), obj.steerCart);
                                                            obj.steerLocalEuler = vector.Math.cartesianToEuler(obj.steerLocal);
                                                            obj.steerHUD = HudMath.getCenterPosFromDegs(obj.steerLocalEuler[0]==nil?0:geo.normdeg180(obj.steerLocalEuler[0]),obj.steerLocalEuler[1]);
                                                            obj.steerPT.setTranslation(obj.steerHUD);
                                                            obj.steerPT.show();
                                                         } else {
                                                            obj.steerPT.hide();
                                                         }
                                                     } else {
                                                         obj.greatCircleSteeringCue.hide();
                                                         obj.steerPT.hide();
                                                     }
                                                 } else {
                                                     obj.greatCircleSteeringCue.hide();
                                                     obj.steerPT.hide();
                                                 }
                                             }
                                            ,

            #props.UpdateManager.FromHashList(["texUp","gear_down"], 0.01,
             func(hdp)
                                             {
                                                 if (hdp.getproper("gear_down")) {
                                                     obj.boreSymbol.hide();
                                                 } else {
                                                     obj.boreSymbol.setTranslation(HudMath.getBorePos());
                                                     obj.boreSymbol.show();
                                                 }
                                      },
            #props.UpdateManager.FromHashList(["gear_down"], 0.5,
             func(hdp)
                                             {
                                                 if (hdp.getproper("gear_down")) {
                                                     obj.appLine.show();
                                                 } else {
                                                     obj.appLine.hide();
                                                 }
                                      },
            #props.UpdateManager.FromHashList(["VV_x","VV_y","fpm","HUD_SCA","ded","dgft","gear_down","wow","fpm"], 0.001,
             func(hdp)
                                      {
                                        obj.r_show = 1;

                                        if (getprop("f16/fcs/adv-mode") == 1 and getprop("f16/stores/nav-mounted") == 1) {
                                                obj.tfrVertSteeringCue.show();
                                                obj.tfrVertSteeringCueDiff = getprop("fdm/jsbsim/autoflight/pitch/vs/target-kin")/150;#-3k to 3k
                                                obj.tfrVertSteeringCue.setTranslation (hdp.VV_x, hdp.VV_y-obj.tfrVertSteeringCueDiff);
                                                obj.tfrVertSteeringCueX.setTranslation (hdp.VV_x, hdp.VV_y-obj.tfrVertSteeringCueDiff);
                                                obj.tfrVertSteeringCueX.setVisible(getprop("instrumentation/tfs/malfunction"));
                                        } else {
                                                obj.tfrVertSteeringCue.hide();
                                                obj.tfrVertSteeringCueX.hide();
                                        }
                                        
                                        if (hdp.getproper("fpm") > 0 and !hdp.getproper("dgft")) {
                                            obj.VV.setTranslation (hdp.VV_x, hdp.VV_y);
                                            if (hdp.getproper("HUD_SCA") == 2) {
                                                obj.bank_angle_indicator.setTranslation (hdp.VV_x, hdp.VV_y);
                                                obj.r_show = 0;
                                            }

                                            obj.ccrpReleased = getprop("payload/armament/releasedCCRP");
                                            obj.controlTrigger = getprop("controls/armament/trigger");

                                            obj.blinkRockets = hdp.getproper("rocketsBusy");
                                            obj.blinkCCRP = obj.controlTrigger > 0 and obj.ccrpReleased > 0;
                                            obj.blinkCCIP = obj.showmeCCIP and isDropping;

                                            obj.VV.setVisible((!obj.blinkCCIP and !obj.blinkCCRP and !obj.blinkRockets) or math.mod(int(8*(systime()-int(systime()))),2)>0);
                                            obj.VV.update();
                                        } else {
                                            obj.VV.hide();
                                        }
                                        obj.bank_angle_indicator.setVisible(!obj.r_show);
                                        obj.vertical_pointer.setVisible(hdp.getproper("HUD_SCA") == 2 and hdp["dlz_show"] != 1);
                                        obj.vertical_scale.setVisible(hdp.getproper("HUD_SCA") == 2 and hdp["dlz_show"] != 1);
                                        if (obj.r_show and hdp.getproper("fpm")==2 and hdp.getproper("ded") == 0 and !hdp.getproper("dgft") and !(hdp.getproper("gear_down") and !hdp.getproper("wow"))) {
                                              obj.roll_pointer.setTranslation(obj.rollPos);
                                              obj.roll_lines.show();
                                              obj.roll_pointer.setVisible(math.abs(hdp.getproper("roll")) <= 45);
                                          } else {
                                              obj.roll_lines.hide();
                                              obj.roll_pointer.hide();
                                          }
                                        obj.localizer.setTranslation (hdp.VV_x, hdp.VV_y);
                                      },
            #props.UpdateManager.FromHashList(["rotary","hasGS","GSDeg","GSinRange","ILSDeg", "ILSinRange", "GSdist", "DGFT"], 0.01,
             func(hdp)
                                      {
                                        if (hdp.getproper("rotary") == 0 or hdp.getproper("rotary") == 3 or hdp.getproper("rotary") == 5) {
                                            #printf("ILSinRange %d GSdist %d", hdp.getproper("ILSinRange"), hdp.getproper("GSdist") == nil);
                                            if (hdp.getproper("ILSinRange")) {
                                                #printf("ILS %d", hdp.getproper("ILSDeg"));
                                                obj.ilsGroup.setTranslation(4*obj.clamp(hdp.getproper("ILSDeg"),-5,5),0);
                                                if (math.abs(hdp.getproper("ILSDeg"))>5) {
                                                    obj.ils.hide();
                                                    obj.ilsOff.show();
                                                } else {
                                                    obj.ils.show();
                                                    obj.ilsOff.hide();
                                                }

                                                if (hdp.getproper("hasGS") and hdp.getproper("GSinRange")) {
                                                    obj.gsGroup.setTranslation(0,-20*hdp.getproper("GSDeg"));
                                                    #printf("GS %d", hdp.getproper("GSDeg")*10);
                                                    if (math.abs(hdp.getproper("GSDeg"))>0.99) {
                                                        obj.gs.hide();
                                                        obj.gsOff.show();
                                                    } else {
                                                        obj.gs.show();
                                                        obj.gsOff.hide();
                                                    }
                                                } else {
                                                    obj.gsGroup.setTranslation(0,0);
                                                    obj.gs.hide();
                                                    obj.gsOff.show();
                                                }
                                                if (obj["heading_tape_positionY"]!=nil) {
                                                    #obj.inv_v.setTranslation(obj.sx*0.5+5.4*hdp.getproper("cross"), 20+obj.heading_tape_positionY);
                                                    obj.heading_tape_pointer.setTranslation (5.4*obj.clamp(geo.normdeg180(hdp.getproper("cross")-hdp.getproper("heading")),-10,10), obj.heading_tape_positionY);
                                                    obj.heading_tape_pointer.show();
                                                } else {
                                                    obj.heading_tape_pointer.hide();
                                                }
                                            } else {
                                                obj.ilsGroup.setTranslation(0,0);
                                                obj.ils.hide();
                                                obj.ilsOff.show();
                                                obj.gsGroup.setTranslation(0,0);
                                                obj.gs.hide();
                                                obj.gsOff.show();
                                                obj.heading_tape_pointer.hide();
                                            }
                                            obj.localizer.show();
                                        } else {
                                            obj.localizer.hide();
                                            obj.heading_tape_pointer.hide();
                                        }
                                      },
            #props.UpdateManager.FromHashList(["fpm","texUp","gear_down","VV_x","VV_y", "wow", "ded", "dgft"], 0.01,
             func(hdp)
                                      {
                                        if (hdp.getproper("gear_down")) {#used to be wow check here, but YT vids show its there all the time
                                          obj.bracket.setTranslation (hdp.VV_x, HudMath.getCenterPosFromDegs(0,-11)[1]);
                                          obj.bracket.show();
                                        } else {
                                          obj.bracket.hide();
                                        }
                                      },
            #props.UpdateManager.FromHashList(["vSpeed"], 0.10,
             func(hdp)
                                      {
                                        obj.vertical_pointer.setTranslation(0.25*sx*uv_used-4*1.5-8,sy*0.245-sy*0.5-6*hdp.getproper("vSpeed")/500);
                                      },
            #props.UpdateManager.FromHashList(["texUp","pitch","roll","fpm","VV_x","VV_y","gear_down", "dgft", "drift"], 0.001,
             func(hdp)
                                      {
                                          if (hdp.getproper("servTurn")) {
                                            obj.roll_pointer.setRotation (math.clamp(hdp.getproper("roll"),-45,45)*D2R);
                                            obj.bank_angle_indicator.setRotation(hdp.roll_rad);
                                          }
                                          if ((hdp.getproper("fpm") != 2 and !hdp.getproper("gear_down")) or hdp.getproper("dgft")) {
                                            obj.ladder_group.hide();
                                            return;
                                          }

                                        var result = HudMath.getDynamicHorizon(5,0.5,0.5,0.7,0.5,hdp.getproper("drift") < 2,-0.25);
                                        if (hdp.getproper("servTurn")) {
                                            obj.h_rot.setRotation(result[1]);
                                            obj.zenith.setRotation(-result[1]);
                                            obj.nadir.setRotation(-result[1]);
                                        }
                                        obj.horizon_group.setTranslation(result[0]);#place it on bore
                                        if (hdp.getproper("servAtt")) {
                                            obj.ladder_group.setTranslation(result[2]);
                                        }
                                        obj.ladder_group.show();
                                        obj.ladder_group.update();
                                        obj.horizon_group.update();
                                        return;

                                      },
            #props.UpdateManager.FromHashList(["altitude_agl_ft","cara","measured_altitude","altSwitch","alow","dgft"], 1.0,
             func(hdp)
                                      {
                                          obj.agl=hdp.getproper("altitude_agl_ft");
                                          obj.altScaleMode = 0;#0=baro, 1=radar 2=thermo
                                          if (!hdp.getproper("dgft")) {
                                              if (hdp.getproper("altSwitch") == 2) {#RDR
                                                    obj.altScaleMode = hdp.getproper("cara");
                                              } elsif (hdp.getproper("altSwitch") == 1) {#BARO
                                                    obj.altScaleMode = 0;
                                              } else {#AUTO
                                                    if (obj["altScaleModeOld"] != nil) {
                                                        if (obj.altScaleModeOld == 2) {
                                                            obj.altScaleMode = (obj.agl < 1500 and hdp.getproper("cara") and !hdp.getproper("dgft") and !obj.hidingScales)*2;
                                                        } else {
                                                            obj.altScaleMode = (obj.agl < 1200 and hdp.getproper("cara") and !hdp.getproper("dgft") and !obj.hidingScales)*2;
                                                        }
                                                    } else {
                                                        obj.altScaleMode = (obj.agl < 1300 and hdp.getproper("cara") and !hdp.getproper("dgft") and !obj.hidingScales)*2;
                                                    }
                                              }
                                          }
                                          obj.altScaleModeOld = obj.altScaleMode;
                                          #print("UPDATE "~obj.altScaleMode~"  CARA "~hdp.getproper("cara")~"  AGL "~obj.agl);
                                          if(hdp.getproper("altSwitch") == 0 and hdp.getproper("cara") and obj.altScaleMode == 0) {
                                              obj.ralt.setText(sprintf("AR %s", obj.getAltTxt(obj.agl)));
                                          } elsif(hdp.getproper("cara") and obj.altScaleMode == 0) {
                                              obj.ralt.setText(sprintf("R %s", obj.getAltTxt(obj.agl)));
                                          } else {
                                              obj.ralt.setText("    ,   ");
                                          }
                                          if (obj.altScaleMode == 2) {
                                            #thermometer scale source: GR1F-F16CJ-34-1 page 185
                                            #print("Thermo");
                                            obj.alt_type.setText("");
                                            obj.alt_range.hide();
                                            obj.alt_curr.hide();
                                            obj.alt_mask.hide();
                                            obj.alt_frame.hide();
                                            obj.ralt.hide();
                                            obj.radalt_box.hide();
                                            obj.alti_indicator.hide();
                                            obj.thermoEnd1 = 10*obj.thermoY100;
                                            obj.thermoEnd2 = 11*obj.thermoY100;
                                            if (obj.agl < 1000) {
                                                obj.thermoEnd = obj.agl*0.01*obj.thermoY100;
                                            } else {
                                                obj.thermoEnd = obj.extrapolate(obj.agl, 1000, 1500, obj.thermoEnd1, obj.thermoEnd2);
                                            }
                                            if (hdp.getproper("alow") < 1000) {
                                                obj.thermoAlow = hdp.getproper("alow")*0.01*obj.thermoY100;
                                            } else {
                                                obj.thermoAlow = obj.extrapolate(hdp.getproper("alow"), 1000, 1500, obj.thermoEnd1, obj.thermoEnd2);
                                            }
                                            obj.thermoGroup.removeAllChildren();
                                            obj.thermoBar = obj.thermoGroup.createChild("path")
                                                .moveTo(obj.thermoXstart, obj.thermoYstart)
                                                .horiz(-5)
                                                .lineTo(obj.thermoXstart-5, obj.thermoYstart-obj.thermoEnd)
                                                .horiz(5)
                                                .setStrokeLineWidth(1)
                                                .setColor(obj.color);
                                            if (hdp.getproper("gear_down") or (obj.agl > hdp.getproper("alow") or math.mod(int(4*(hdp.getproper("elapsed")-int(hdp.getproper("elapsed")))),2)>0)) {
                                                obj.thermoBar.moveTo(obj.thermoXstart-5, obj.thermoYstart-obj.thermoAlow)
                                                .horiz(-4)
                                                .moveTo(obj.thermoXstart-9, obj.thermoYstart-obj.thermoAlow-2)
                                                .vert(4);
                                            }
                                            obj.thermometerScaleGrp.show();
                                          } elsif (obj.altScaleMode == 1) {
                                            #print("radar");
                                            # radar scale
                                            obj.alt_range.setTranslation(skew_alt, obj.agl * alt_range_factor);
                                            obj.alt_curr.setText(obj.getAltTxt(obj.agl));
                                            obj.alt_type.setText("R");
                                            obj.ralt.hide();
                                            obj.radalt_box.hide();
                                            obj.thermometerScaleGrp.hide();
                                            obj.alt_curr.show();
                                            obj.alt_mask.show();
                                            obj.alt_frame.show();
                                            if (!obj.hidingScales) {
                                                obj.alti_indicator.show();
                                                obj.alt_range.show();
                                            }
                                          } else {
                                            #print("baro");
                                            # baro scale
                                            obj.alt_range.setTranslation(skew_alt, hdp.getproper("measured_altitude") * alt_range_factor);
                                            obj.alt_curr.setText(obj.getAltTxt(hdp.getproper("measured_altitude")));
                                            obj.alt_type.setText("");
                                            obj.ralt.show();
                                            obj.radalt_box.show();
                                            obj.thermometerScaleGrp.hide();
                                            obj.alt_curr.show();
                                            obj.alt_mask.show();
                                            obj.alt_frame.show();
                                            if (!obj.hidingScales) {
                                                obj.alti_indicator.show();
                                                obj.alt_range.show();
                                            }
                                          }
                                      },
            #props.UpdateManager.FromHashList(["HUD_SCA", "DGFT"], 0.5,
             func(hdp)
                                      {

                                          if (hdp.getproper("HUD_SCA") and !hdp.getproper("dgft") and obj.hidingScales) {
                                            foreach(tck;obj.scaling) {
                                                tck.show();
                                              }
                                            obj.hidingScales = 0;
                                          } elsif (!obj.hidingScales and !(hdp.getproper("HUD_SCA") and !hdp.getproper("dgft"))) {
                                              foreach(tck;obj.scaling) {
                                                tck.hide();
                                              }
                                              obj.heading_tape_pointer.hide();
                                              obj.hidingScales = 1;
                                          }
                                      },
            #props.UpdateManager.FromHashList(["calibrated", "GND_SPD", "HUD_VEL", "gear_down"], 0.5,
             func(hdp)
                                      {
                                          # the real F-16 has calibrated airspeed as default in HUD.
                                          var pitot = hdp.getproper("servPitot") and hdp.getproper("servStatic");
                                          if (hdp.getproper("HUD_VEL") == 1 or hdp.getproper("gear_down") or hdp.getproper("dgft")) {
                                            if (hdp.getproper("servSpeed")) {
                                                obj.ias_range.setTranslation(skew_spd, hdp.getproper("calibrated") * ias_range_factor * pitot);
                                                obj.speed_curr.setText(!pitot?""~0:sprintf("%d",hdp.getproper("calibrated")));
                                            }
                                            obj.speed_type.setText("C");
                                          } elsif (hdp.getproper("HUD_VEL") == 0) {
                                            if (hdp.getproper("servSpeed")) {
                                                obj.ias_range.setTranslation(skew_spd, hdp.getproper("TAS") * ias_range_factor * pitot);
                                                obj.speed_curr.setText(!pitot?""~0:sprintf("%d",hdp.getproper("TAS")));
                                            }
                                            obj.speed_type.setText("T");
                                          } else {
                                            if (hdp.getproper("servSpeed")) {
                                                obj.ias_range.setTranslation(skew_spd, hdp.getproper("groundspeed_kt") * ias_range_factor * pitot);
                                                obj.speed_curr.setText(!pitot?""~0:sprintf("%d",hdp.getproper("groundspeed_kt")));
                                            }
                                            obj.speed_type.setText("G");
                                          }
                                      },
            #props.UpdateManager.FromHashList(["Nz","nReset"], 0.1,
             func(hdp)
                                      {
                                          obj.window12.setText(sprintf("%.1f", hdp.getproper("Nz")));
                                          obj.window12.show();
                                          obj.NzMax = math.max(hdp.getproper("Nz"), obj.NzMax);
                                          obj.window8.setText(sprintf("%.1f", obj.NzMax));
                                          obj.window8.show();
                                      },
            #props.UpdateManager.FromHashList(["heading", "headingMag", "useMag","gear_down"], 0.1,
             func(hdp)
                                      {
                                          var head = geo.normdeg(hdp.getproper("useMag")?hdp.getproper("headingMag"):hdp.getproper("heading"));

                                          if (head < 180)
                                            obj.heading_tape_position = -head*54/10+skew_hdg;
                                          else
                                            obj.heading_tape_position = (360-head)*54/10+skew_hdg;
                                          if (hdp.getproper("gear_down")) {
                                              obj.heading_tape_positionY = -10;
                                              obj.head_curr.setTranslation(0.5*sx*uv_used,sy*0.1-12);
                                              obj.head_mask.setTranslation(-10+0.5*sx*uv_used,sy*0.1-20);
                                              obj.head_frame.setTranslation(0,0);
                                          } else {
                                              obj.heading_tape_positionY = 95;
                                              obj.head_curr.setTranslation(0.5*sx*uv_used,sy*0.1-12+105);
                                              obj.head_mask.setTranslation(-10+0.5*sx*uv_used,sy*0.1-20+105);
                                              obj.head_frame.setTranslation(0,105);
                                          }
                                          if (hdp.getproper("servHead")) {
                                            obj.head_curr.setText(sprintf("%03d",head));
                                            obj.heading_tape.setTranslation (obj.heading_tape_position,obj.heading_tape_positionY);
                                          }

                                      }
                                            ,
            #props.UpdateManager.FromHashList(["time_until_crash","vne","warn", "elapsed", "data"], 0.05,
             func(hdp)
                                             {
                                                 obj.ttc = hdp.getproper("time_until_crash");
                                                 #obj.flyup.setTranslation(0, 0);
                                                 if (obj.ttc != nil and obj.ttc>0 and obj.ttc<8) {
                                                     obj.flyup.setText("FLYUP");
                                                     obj.flyup.show();
                                                 } elsif (hdp.getproper("vne")) {
                                                         obj.flyup.setText("LIMIT");
                                                         obj.flyup.show();
                                                 } elsif (hdp.getproper("warn") == 1 and math.mod(int(4*(hdp.getproper("elapsed")-int(hdp.getproper("elapsed")))),2)>0) {
                                                         obj.flyup.setText("WARN");
                                                         obj.flyup.show();
                                                 } elsif (getprop("f16/fcs/adv-mode-sel") and getprop("instrumentation/tfs/malfunction") and math.mod(int(4*(hdp.getproper("elapsed")-int(hdp.getproper("elapsed")))),2)>0) {
                                                         obj.flyup.setText("WARN");
                                                         obj.flyup.show();
                                                 } elsif (hdp.getproper("bingo") == 1 and math.mod(int(4*(hdp.getproper("elapsed")-int(hdp.getproper("elapsed")))),2)>0) {
                                                         obj.flyup.setText("FUEL");
                                                         obj.flyup.show();
                                                 } elsif (hdp.getproper("data") != 0) {
                                                         obj.flyup.setText("DATA");
                                                         obj.flyup.show();
                                                 } else {
                                                         obj.flyup.hide();
                                                 }
                                                 obj.flyup.update();
                                                 if (obj.ttc != nil and obj.ttc>0 and obj.ttc<10.5) {
                                                    obj.flyupAmount = math.max(0,obj.extrapolate(obj.ttc,8,9.5,0,1));
                                                    obj.flyupLeft.setTranslation(-obj.flyupAmount*150,0);
                                                    obj.flyupRight.setTranslation(obj.flyupAmount*150,0);
                                                    obj.flyupLeft.show().update();
                                                    obj.flyupRight.show().update();
                                                } else {
                                                    obj.flyupLeft.hide();
                                                    obj.flyupRight.hide();
                                                }
                                             }
                                            ,
            #props.UpdateManager.FromHashList(["wow0","standby", "data"], 0.5,
             func(hdp)
                                             {
                                                 if (hdp.getproper("data") != 0) {
                                                     obj.stby.setText("MKPT"~sprintf("%03d",hdp.getproper("data")));
                                                     obj.stby.setTranslation(0,HudMath.getBorePos()[1]+7+75);
                                                     obj.stby.show();
                                                 } elsif (hdp.getproper("standby") and !hdp.getproper("wow0")) {
                                                     obj.stby.setText("NO RAD");
                                                     obj.stby.setTranslation(0,HudMath.getBorePos()[1]+7);
                                                     obj.stby.show();
                                                 } else {
                                                     obj.stby.hide();
                                                 }
                                                 obj.stby.update();
                                             }
                                            ,
            #props.UpdateManager.FromHashList(["brake_parking", "gear_down", "flap_pos_deg", "CCRP_active", "master_arm","submode","VV_x","DGFT","rotary"], 0.1,
             func(hdp)
                                             {
                                                 if (hdp.getproper("brake_parking")) {
                                                     obj.window2_txt = "  BRAKES";
                                                 } elsif (hdp.getproper("flap_pos_deg") > 0 or hdp.getproper("gear_down")) {
                                                     obj.gd = "";
                                                     if (hdp.getproper("gear_down"))
                                                       obj.gd = " G";
                                                     obj.window2_txt = sprintf("  F %d%s",hdp.getproper("flap_pos_deg"),obj.gd);
                                                 } elsif (hdp.getproper("master_arm") != pylons.ARM_OFF) {
                                                     var submodeVar = "";
                                                     if (hdp.CCRP_active > 0) {
                                                        submodeVar = "CCRP";
                                                     } elsif (obj.showmeCCIP) {
                                                        submodeVar = "CCIP";
                                                     } elsif (obj.eegsLoop.isRunning) {
                                                        submodeVar = obj.hydra?"CCIP":(hdp.getproper("gunSight")==0?"EEGS":(hdp.getproper("gunSight")==1?"STRF":"SNAP"));
                                                     } elsif (hdp.submode == 1) {
                                                        submodeVar = "BORE";
                                                     }
                                                     var dgft = hdp.getproper("dgft")?"DGFT ":"";
                                                     var armmode = hdp.getproper("master_arm")==pylons.ARM_ARM?"  ARM ":"  SIM ";
                                                     obj.window2_txt = armmode~dgft~submodeVar;
                                                 } elsif (hdp.getproper("rotary") == 0 or hdp.getproper("rotary") == 3) {
                                                     obj.window2_txt = "  ILS";
                                                 } else {
                                                    if (hdp.getproper("ins_knob")==3) {
                                                        obj.window2_txt = "  NAV";
                                                    } elsif (hdp.getproper("ins_knob")==2 or hdp.getproper("ins_knob")==4) {
                                                        obj.window2_txt = "  ALIGN";
                                                    } else {
                                                        obj.window2_txt = " ";
                                                    }
                                                 }
                                                 obj.window2.setText(obj.window2_txt);
                                                 obj.window2.setVisible(1);
                                             }
                                            

        ];

        #EEGS: (other gun sights not made: lcos sslc)
        obj.eegsGroup = obj.centerOrigin.createChild("group");
        obj.funnelPartsMax = 51;#strf (hydra is 34)
        obj.funnelParts = 17;#eegs (number of segments in funnel sides. If increase, remember to increase all relevant vectors also.)
        obj.eegsRightX = obj.makeVector(obj.funnelParts,0);
        obj.eegsRightY = obj.makeVector(obj.funnelParts,0);
        obj.eegsLeftX  = obj.makeVector(obj.funnelParts,0);
        obj.eegsLeftY  = obj.makeVector(obj.funnelParts,0);
        obj.gunPos   = nil;#[[nil,nil],[nil,nil,nil],[nil,nil,nil,nil],[nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil]];
        obj.eegsMe = {ac: geo.Coord.new(), eegsPos: geo.Coord.new(),shellPosX: obj.makeVector(obj.funnelPartsMax,0),shellPosY: obj.makeVector(obj.funnelPartsMax,0),shellPosDist: obj.makeVector(obj.funnelPartsMax,0)};
        obj.lastTime = systime();
        obj.averageDt = 0.100;
        obj.eegsLoop = maketimer(obj.averageDt, obj, obj.displayEEGS);
        obj.eegsLoop.simulatedTime = 1;
        obj.resetGunPos();

        obj.showmeCCIP = 0;
        obj.NzMax = 1.0;

        return obj;
    },

    #######################################################################################################
    #######################################################################################################
    ########                                                                                     ##########
    ########                           Update loop                                               ##########
    ########                                                                                     ##########
    ########                                                                                     ##########
    #######################################################################################################
    #######################################################################################################

    update : func(hdp) {
        HudMath.reCalc();

        if (hdp.getproper("nReset")) {
            me.NzMax = 1.0;
            setprop("f16/avionics/n-reset",0);
        }

        # part 1. update data items
        hdp.roll_rad = -hdp.getproper("roll")*D2R;
        if (me.initUpdate) {
            me.window1_txt = "1";
            me.window2_txt = "2";
            me.window3_txt = "3";
            me.window4_txt = "4";
            me.window5_txt = "5";
            me.window6_txt = "6";
            me.window7_txt = "7";
            me.window8_txt = "8";
            me.window9_txt = "9";
            me.window10_txt = "10";
            me.window11_txt = "11";
            me.window12_txt = "12";
        }

        me.Vz   =    hdp.getproper("current_view_y_offset_m"); # view Z position (0.94 meter per default)
        me.Vx   =    hdp.getproper("current_view_z_offset_m"); # view X position (0.94 meter per default)
        setprop("f16/hud/texels-up", HudMath.getBorePos()[1]);

        me.Vy   =    hdp.getproper("current_view_x_offset_m");

        me.pixelPerMeterX = HudMath.pixelPerMeterX;
        me.pixelPerMeterY = HudMath.pixelPerMeterY;

        me.pixelside = me.pixelPerMeterX*me.Vy;#*!(use_war_hud);# slide whole hud sideways when pilot moves head sideways

        me.svg.setTranslation(me.pixelside+tran_x, tran_y);
        me.centerOrigin.setTranslation(HudMath.getCenterOrigin()[0]+me.pixelside, HudMath.getCenterOrigin()[1]);
        me.centerOrigin.update();
        me.svg.update();


        me.submode = 0;

        if (1) {
            var vvpos = HudMath.getFlightPathIndicatorPos();
            if (hdp.getproper("drift") < 2) {
                hdp.VV_x = vvpos[0];
            } else {
                hdp.VV_x = 0;
            }
            hdp.VV_y = vvpos[1];
        } elsif (hdp.getproper("wow0")) {
            me.vectorMag = math.sqrt(hdp.getproper("speed_east_fps")*hdp.getproper("speed_east_fps")+hdp.getproper("speed_north_fps")*hdp.getproper("speed_north_fps"));
            if (me.vectorMag == 0) {
                me.vectorMag = 0.0001;
            }
            if (me.vectorMag<0.5) {
                hdp.VV_x = 0;
            } else {
                me.headingvv = -math.asin(hdp.getproper("speed_north_fps")/me.vectorMag)*R2D+90;#divide by vector mag, to get normalized unit vector length
                if (hdp.getproper("speed_east_fps")/me.vectorMag < 0) {
                  me.headingvv = -me.headingvv;
                }
                if (me.vectorMag < 0.1) {
                    me.headingvv = hdp.getproper("heading");
                }
                hdp.VV_x = geo.normdeg180(me.headingvv-hdp.getproper("heading"));
            }
            hdp.VV_y = 0;
        } else {
            hdp.VV_x = hdp.getproper("beta");
            hdp.VV_y = hdp.getproper("alpha");
        }


        # UV mapped to x: uv_x1 to uv_x2
        me.texelPerDegreeX = HudMath.getPixelPerDegreeXAvg(5);
        me.texelPerDegreeY = HudMath.getPixelPerDegreeYAvg(5);

        # FLIR
        me.xBore = int(me.sx*0.5/(256/flirImageReso));
        me.yBore = flirImageReso-1-int((HudMath.getCenterOrigin()[1]+HudMath.getBorePos()[1])/(256/flirImageReso));
        me.distMin = hdp.getproper("groundspeed_kt")*getprop("f16/avionics/hud-flir-distance-min");
        me.distMax = hdp.getproper("groundspeed_kt")*getprop("f16/avionics/hud-flir-distance-max");
        me.cont = getprop("f16/avionics/hud-cont");
        me.brt = getprop("f16/avionics/hud-brt");
        if (me.brt > 0 and getprop("f16/stores/nav-mounted")==1 and getprop("f16/avionics/power-left-hdpt")==1 and me.color[3] != 0) {
            for(me.x = 0; me.x < flirImageReso; me.x += 1) {
                me.xDevi = (me.x-me.xBore)*(256/flirImageReso);
                me.xDevi /= me.texelPerDegreeX;
                for(me.y = me.scanY; me.y < me.scanY+me.scans; me.y += 1) {
                    me.yDevi = (me.y-me.yBore)*(256/flirImageReso);
                    me.yDevi /= me.texelPerDegreeY;
                    me.value = 0;
                    me.start = geo.viewer_position();
                    me.vecto = [math.cos(me.xDevi*D2R)*math.cos(me.yDevi*D2R),math.sin(-me.xDevi*D2R)*math.cos(me.yDevi*D2R),math.sin(me.yDevi*D2R)];

                    me.direction = vector.Math.vectorToGeoVector(vector.Math.rollPitchYawVector(getprop("orientation/roll-deg"),getprop("orientation/pitch-deg"),-getprop("orientation/heading-deg"), me.vecto),me.start);
                    me.intercept = get_cart_ground_intersection({x:me.start.x(),y:me.start.y(),z:me.start.z()}, me.direction);
                    if (me.intercept == nil) {
                        me.value = 0;
                    } else {
                        me.terrain = geo.Coord.new();
                        me.terrain.set_latlon(me.intercept.lat, me.intercept.lon ,me.intercept.elevation);
                        me.value = math.min(1,((math.max(me.distMin-me.distMax, me.distMin-me.start.direct_distance_to(me.terrain))+(me.distMax-me.distMin))/me.distMax));
                    }
                    me.gain = math.min(1,1+2*me.cont*(1-2*me.value));
                    me.flirPicHD.setPixel(me.x, me.y, [me.color[0],me.color[1],me.color[2],me.brt*math.pow(me.value, me.gain)]);
                }
            }
            me.scanY+=me.scans;if (me.scanY>flirImageReso-me.scans) me.scanY=0;
            #me.flirPicHD.setPixel(me.xBore, me.yBore, [0,0,1,1]);# blue dot at bore
            me.flirPicHD.dirtyPixels();
            me.flirPicHD.show();
        } else {
            me.flirPicHD.hide();
        }





        hdp.fcs_available = pylons.fcs != nil;
        hdp.weapon_selected = "";

        me.hydra = 0;

        # part2. update display, first with the update managed items
        var showASC = 0;
        me.ALOW_top = 0;
        me.TA_text = "";
        if (1) {#hdp.getproper("FrameCount == 2 or me.initUpdate == 1) {
            me.window1_txt = "";
            me.window2_txt = "";
            me.window3_txt = "";
            me.window4_txt = "";
            me.window5_txt = "";
            me.window6_txt = "";
            me.window7_txt = "";
            me.window8_txt = "";
            me.window9_txt = "";
            me.window10_txt = "";
            me.window11_txt = "";
            me.window12_txt = "";


            me.asec262 = 0;
            me.asec120 = 0;
            me.asec100 = 0;
            me.asec65  = 0;
            var eegsShow = 0;
            var currASEC = nil;
            me.showFov = 0;

            if(hdp.getproper("master_arm") != pylons.ARM_OFF and pylons.fcs != nil)
            {
                hdp.weapon_selected = pylons.fcs.selectedType;
                hdp.weapn = pylons.fcs.getSelectedWeapon();

                if (hdp.weapon_selected != nil)
                {
                    var mr = 0.4;
                    if (hdp.weapon_selected == fc.defaultCannon) {
                        me.window9_txt = sprintf("%3d", pylons.fcs.getAmmo());
                        eegsShow = 1;
                        me.ALOW_top = 1;
                    } elsif (hdp.weapon_selected == "AIM-9L" or hdp.weapon_selected == "AIM-9M" or hdp.weapon_selected == "AIM-9X") {
                        me.window9_txt = sprintf("%d SRM", pylons.fcs.getAmmo());#short range missile
                        if (hdp.weapn != nil) {
                            if (hdp.weapn.status == armament.MISSILE_LOCK and !hdp.getproper("standby")) {
                                me.asec65 = 1;
                                currASEC = nil;#[me.sx*0.5,me.sy*0.25];
                            } elsif (!hdp.getproper("standby")) {
                                me.asec100 = 1;
                                currASEC = nil;#[me.sx*0.5,me.sy*0.25];
                            }
                        }
                        me.ALOW_top = 1;
                    } elsif (hdp.weapon_selected == "IRIS-T") {
                        me.window9_txt = sprintf("%d ASM", pylons.fcs.getAmmo());#short range missile
                        if (hdp.weapn != nil) {
                            if (hdp.weapn.status == armament.MISSILE_LOCK and !hdp.getproper("standby")) {
                                me.asec65 = 1;
                                currASEC = nil;#[me.sx*0.5,me.sy*0.25];
                            } elsif (!hdp.getproper("standby")) {
                                me.asec100 = 1;
                                currASEC = nil;#[me.sx*0.5,me.sy*0.25];
                            }
                        }
                        me.ALOW_top = 1;
                    } elsif (hdp.weapon_selected == "AIM-120") {
                        me.window9_txt = sprintf("%d AMM", pylons.fcs.getAmmo());#adv. medium range missile
                        if (hdp.weapn != nil) {
                            if (hdp.weapn.status == armament.MISSILE_LOCK and !hdp.getproper("standby")) {
                                me.asec120 = 1;
                                currASEC = [me.sx*0.5,me.sy*0.25];
                            } elsif (!hdp.getproper("standby")) {
                                me.asec262 = 1;
                                currASEC = [me.sx*0.5,me.sy*0.25+262*mr*0.5];
                            }
                        }
                        me.ALOW_top = 1;
                    } elsif (hdp.weapon_selected == "AIM-7") {
                        me.window9_txt = sprintf("%d MRM", pylons.fcs.getAmmo());#medium range missile
                        if (hdp.weapn != nil) {
                            if (hdp.weapn.status == armament.MISSILE_LOCK and !hdp.getproper("standby")) {
                                me.asec120 = 1;
                                currASEC = nil;#[me.sx*0.5,me.sy*0.25];
                            } elsif (!hdp.getproper("standby")) {
                                me.asec262 = 1;
                                currASEC = nil;#[me.sx*0.5,me.sy*0.25+262*mr*0.5];
                            }
                        }
                        me.ALOW_top = 1;
                    } elsif (hdp.weapon_selected == "GBU-12") {
                        me.window9_txt = sprintf("%d GB12", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "AGM-65B") {
                        me.window9_txt = sprintf("%d AG65", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "AGM-65D") {
                        me.window9_txt = sprintf("%d AG65", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "AGM-84") {
                        me.window9_txt = sprintf("%d AG84", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "AGM-119") {
                        me.window9_txt = sprintf("%d AG119", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "MK-82") {
                        me.window9_txt = sprintf("%d B82", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "MK-82AIR") {
                        me.window9_txt = sprintf("%d B82A", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "MK-83") {
                        me.window9_txt = sprintf("%d B83", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "MK-84") {
                        me.window9_txt = sprintf("%d B84", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "AGM-88") {
                        me.showFov = 1;
                        if (pylons.fcs.isLock()) {
                            me.showFov = math.mod(hdp.getproper("elapsed"), 0.5) < 0.25;
                        }
                        me.window9_txt = sprintf("%d AG88", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "GBU-31") {
                        me.window9_txt = sprintf("%d GB31", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "GBU-54") {
                        me.window9_txt = sprintf("%d GB54", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "GBU-24") {
                        me.window9_txt = sprintf("%d GB24", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "AGM-158") {
                        me.window9_txt = sprintf("%d AG158", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "AGM-154A") {
                        me.window9_txt = sprintf("%d AG154", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "CBU-87") {
                        me.window9_txt = sprintf("%d CB87", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "CBU-105") {
                        me.window9_txt = sprintf("%d CB105", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "LAU-68") {
                        me.window9_txt = sprintf("%d M151", pylons.fcs.getAmmo());
                        eegsShow = 1;
                        me.hydra = 1;
                    } elsif (hdp.weapon_selected == "B61-7") {
                        me.window9_txt = sprintf("%d B617", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "B61-12") {
                        me.window9_txt = sprintf("%d B6112", pylons.fcs.getAmmo());
                    } else me.window9_txt = "";


                }

                if (radar_system.apg68Radar.getPriorityTarget() != nil) {
                    if (radar_system.apg68Radar.getPriorityTarget().get_Callsign() != nil) {
                        me.window6_txt = radar_system.apg68Radar.getPriorityTarget().get_Callsign();
                    } else {
                        me.window6_txt = "";
                    }

                    me.lard = radar_system.apg68Radar.getPriorityTarget().getLastRangeDirect();
                    me.laal = radar_system.apg68Radar.getPriorityTarget().getLastAltitude();

                    if (me.lard ==nil or me.laal == nil) {
                        me.TA_text = "TA XX";
                        me.window3_txt = "FXXX.X";#slant range
                    } else {
                        me.TA_text = sprintf("TA%3d", me.laal*0.001);
                        me.window3_txt = sprintf("F%05.1f", me.lard*M2NM);#slant range
                    }

                    me.window6_txt ~= "/"~radar_system.apg68Radar.getPriorityTarget().getModel();
                    if (size(me.window6_txt)>14) {
                        me.window6_txt = substr(me.window6_txt,0,14);
                    }
                } elsif (armament.contactPoint != nil) {
                    me.lardC = armament.contactPoint.getCoord();
                    me.lard = radar_system.self.getCoord().direct_distance_to(me.lardC);
                    me.laal = armament.contactPoint.get_altitude();

                    if (me.lard ==nil or me.laal == nil) {
                        me.TA_text = "TA XX";
                        me.window3_txt = "FXXX.X";#slant range
                    } else {
                        me.TA_text = sprintf("TA%3d", me.laal*0.001);
                        me.window3_txt = sprintf("F%05.1f", me.lard*M2NM);#slant range
                    }
                    me.window6_txt = "";
                } else {
                    me.window3_txt = "";
                    me.window6_txt = "";
                }
                me.etaS = armament.AIM.getETA();
                if (hdp["CCRP_active"] == 2 and me["timeToRelease"] != nil) {
                    me.timeToReleaseH = int(me.timeToRelease/3600);
                    me.timeToRelease = me.timeToRelease-me.timeToReleaseH*3600;
                    me.timeToReleaseM = int(me.timeToRelease/60);
                    me.timeToRelease = me.timeToRelease-me.timeToReleaseM*60;
                    if (me.timeToReleaseH < 1) {
                        me.window4_txt = sprintf("%03d:%02d",me.timeToReleaseM,me.timeToRelease);# 3 digits so pilot can tell it apart from time to steerpoint.
                    } else {
                        me.window4_txt = "XXX";
                    }
                } elsif (me.etaS != nil and me.etaS != -1) {
                    me.etaH = int(me.etaS/3600);
                    me.etaS = me.etaS-me.etaH*3600;
                    me.etaM = int(me.etaS/60);
                    me.etaS = me.etaS-me.etaM*60;
                    if (me.etaH < 1) {
                        me.window4_txt = sprintf("%03d:%02d",me.etaM,me.etaS);# 3 digits so pilot can tell it apart from time to steerpoint.
                    } else {
                        me.window4_txt = "XXX";
                    }
                } else {
                    me.window4_txt = "";
                }
                me.scurr = steerpoints.getCurrentNumber();
                if (me.scurr != 0) {
                    me.navRange = steerpoints.getCurrentRange();
                    me.window5_txt = sprintf("%d>%02d", me.navRange, me.scurr);# as per MLU tape 3 manual
                } else {
                    me.window5_txt = "";
                }
            } else # weapons not armed
            {
                me.scurr = steerpoints.getCurrentNumber();
                if (me.scurr != 0) {
                    me.navRange = steerpoints.getCurrentRange();
                    me.window5_txt = sprintf("%d>%02d", me.navRange, me.scurr);# as per MLU tape 3 manual
                    me.etaS = steerpoints.getCurrentETA();
                    if (me.etaS != nil) {
                        me.etaH = int(me.etaS/3600);
                        me.etaS = me.etaS-me.etaH*3600;
                        me.etaM = int(me.etaS/60);
                        me.etaS = me.etaS-me.etaM*60;
                        if (me.etaH < 100) {
                            me.window4_txt = sprintf("%02d:%02d",me.etaH,me.etaM);
                        } else {
                            me.window4_txt = "99:99";
                        }
                    } else {
                        me.window4_txt = "XX:XX";
                    }
                } else {
                    me.window4_txt = "";
                    me.window5_txt = "";
                }
                var knob = getprop("sim/model/f16/controls/navigation/instrument-mode-panel/mode/rotary-switch-knob");
                if (hdp.getproper("gear_down") and !hdp.getproper("wow")) {
                    me.window6_txt = "";#sprintf("A%d", hdp.getproper("approach_speed"));
                } elsif (0 and (knob==0 or knob == 1) and getprop("instrumentation/tacan/in-range")) {
                    # show tacan distance and mag heading. (not authentic like this, saw a paper on putting Tacan in hud, but not sure if it was done for F16)
                    if (getprop("f16/avionics/tacan-receive-only")) {
						var tcnDist = "   ";
					} else {
						var tcnDist = getprop("instrumentation/tacan/indicated-distance-nm");
						if (tcnDist >= 10) {
							# tacan can under right conditions be 3 digits
							tcnDist = sprintf("%d", tcnDist);
						} else {
							tcnDist = sprintf("%.1f", tcnDist);
						}
					}
                    me.window6_txt = sprintf("%s TCN%03d",tcnDist,geo.normdeg(hdp.getproper("headingMag")+getprop("instrumentation/tacan/bearing-relative-deg")));
                } elsif (0 and (knob==2 or knob == 3) and getprop("instrumentation/adf/in-range")) {
                    # show adf mag heading.
                    me.window6_txt = sprintf("ADF%03d",geo.normdeg(hdp.getproper("headingMag")+getprop("instrumentation/adf/indicated-bearing-deg")));
                } elsif (0 and (knob==2 or knob == 3) and getprop("instrumentation/nav[0]/in-range") and !getprop("instrumentation/nav[0]/nav-loc")) {
                    # show vor mag heading.
                    me.window6_txt = sprintf("VOR%03d",geo.normdeg(getprop("orientation/heading-deg")-getprop("orientation/heading-magnetic-deg")+getprop("instrumentation/nav[0]/radials/target-auto-hdg-deg")));
                } else {
                    me.window6_txt = "";
                }

                var slant = "";

                var r = steerpoints.getCurrentSlantRange();
                if (r != nil) {
                    if (r >= 1) {
                        slant = sprintf("B %5.1f",r);#tenths of NM.
                    } else {
                        slant = sprintf("B %4.2f",r);#should really be hundreds of feet, but that will confuse everyone.
                    }
                }

                me.window3_txt = slant;
            }
            me.ASEC262.setVisible(me.asec262);
            me.ASEC100.setVisible(me.asec100);
            me.ASEC120.setVisible(me.asec120);
            me.ASEC65.setVisible(me.asec65);
            me.fov_box.setVisible(me.showFov);
            me.eegsGroup.setVisible(eegsShow);
            if (eegsShow and !me.eegsLoop.isRunning) {
                me.eegsLoop.start();
            } elsif (!eegsShow and me.eegsLoop.isRunning) {
                me.eegsLoop.stop();
            }

            me.bullPt = steerpoints.getNumber(steerpoints.index_of_bullseye);
            me.bullOn = me.bullPt != nil and steerpoints.bullseyeMode;
            if (hdp.getproper("bingo") and math.mod(int(4*(hdp.getproper("elapsed")-int(hdp.getproper("elapsed")))),2)>0) {
              me.window11_txt = "FUEL";
            } elsif (hdp.getproper("bingo")) {
              me.window11_txt = "";
            } elsif (me.bullOn) {
                me.bullLat = me.bullPt.lat;
                me.bullLon = me.bullPt.lon;
                me.bullCoord = geo.Coord.new().set_latlon(me.bullLat,me.bullLon);
                me.ownCoord = geo.aircraft_position();
                me.bullDirToMe = me.bullCoord.course_to(me.ownCoord);
                me.bullDistToMe = me.bullCoord.distance_to(me.ownCoord)*M2NM;
                if (me.bullDistToMe > 999) me.bullDistToMe = 999;
                me.bullDirToMe = sprintf("%03d", me.bullDirToMe);
				me.bullDistToMe = sprintf("%02d", me.bullDistToMe);
			    me.window11_txt = sprintf("%s %s", me.bullDirToMe, me.bullDistToMe);
			} else {
                me.window11_txt = "";
			}


            if (!hdp.getproper("cara")) {
                me.alow_text = "AL";
            } elsif (hdp.getproper("alow")<hdp.getproper("altitude_agl_ft") or math.mod(int(4*(hdp.getproper("elapsed")-int(hdp.getproper("elapsed")))),2)>0 or hdp.getproper("gear_down")) {
                me.alow_text = sprintf("AL%4d",hdp.getproper("alow"));
            } else {
                me.alow_text = "";
            }

            if ((hdp.getproper("dgft") or me.ALOW_top) and me["altScaleMode"] != 2) {
                me.window1_txt = me.alow_text;
                me.window10_txt = me.TA_text;# Since MLU Tape 2
            } else {
                me.window10_txt = me.alow_text;
                me.window1_txt = "";
            }

            me.window7_txt = sprintf("  %.2f",hdp.getproper("mach"));
        }





        me.locatorLineShow = 0;
#        if (hdp.getproper("FrameCount == 1 or hdp.getproper("FrameCount == 3 or me.initUpdate == 1) {
        me.target_idx = 0;
        me.designated = 0;

       
        me.irL = 0;
        me.irS = 0;
        me.rdL = 0;
        me.irT = 0;
        me.rdT = 0;
        me.irB = 0;
        #printf("%d %d %d %s",hdp.getproper("master_arm"),pylons.fcs != nil,pylons.fcs.getAmmo(),hdp.weapon_selected);
        if(hdp.getproper("master_arm") != pylons.ARM_OFF and pylons.fcs != nil and pylons.fcs.getAmmo() > 0) {
            hdp.weapon_selected = pylons.fcs.selectedType;
            var aim = pylons.fcs.getSelectedWeapon();
            if (hdp.weapon_selected == "AIM-120" or hdp.weapon_selected == "AIM-7") {
                if (!pylons.fcs.isLock()) {
                    me.radarLock.setTranslation(0, -me.sy*0.25+262*0.3*0.5);
                    me.rdL = 1;
                }
            } elsif (hdp.weapon_selected == "AIM-9L" or hdp.weapon_selected == "AIM-9M" or hdp.weapon_selected == "AIM-9X" or hdp.weapon_selected == "IRIS-T") {
                if (aim != nil and aim.isCaged()) {
                    var coords = aim.getSeekerInfo();
                    if (coords != nil) {
                        me.irDiamondSmall.setTranslation(HudMath.getCenterPosFromDegs(coords[0],coords[1]));
                        me.irS = 1;
                    }
                } elsif (aim != nil) {
                    var coords = aim.getSeekerInfo();
                    if (coords != nil) {
                        me.irDiamond.setTranslation(HudMath.getCenterPosFromDegs(coords[0],coords[1]));
                        me.irL = 1;
                    }
                }
                if (pylons.bore == 1) {
                    if (aim != nil) {
                        me.submode = 1;
                        me.irCross.setTranslation(HudMath.getCenterPosFromDegs(0,-4));
                        me.irB = 1;

                    }
                }
            }
        }
        me.designatedDistanceFT = nil;
        me.groundAltDiffLastPointFT = nil;
        me.u = radar_system.apg68Radar.getPriorityTarget();
        var showACMBore = 0;
        var showACMVert = 0;
        me.target_locked_setVisible=0;
        me.aaTargetDesignationGrp_setVisible=0;
        me.azimuth = "";
        if (me.u != nil) {
            me.lastCoord = me.u.getLastCoord();
            if (me.lastCoord == nil) {
                print("HUD lastCoord has no valid bleps! ("~radar_system.apg68Radar.currentMode.longName~") ["~size(me.u.getBleps())~" bleps]");
                radar_system.apg68Radar.undesignate();
            } elsif (!me.lastCoord.is_defined()) {
                print("HUD lastCoord not defined!");
            } else {
                if (me.u.get_Callsign() != nil) {
                  me.callsign = me.u.get_Callsign();
                }
                me.model = "XX";
                if (me.u.getModel() != "") {
                    me.model = me.u.getModel();
                }
                if (me.target_idx < me.max_symbols or me.designatedDistanceFT == nil) {
                    me.echoPos = HudMath.getPosFromCoord(me.lastCoord);
                    if (me.target_idx < me.max_symbols) {
                        me.tgt = me.tgt_symbols[me.target_idx];
                    } else {
                        me.tgt = nil;
                    }
                    if (me.tgt != nil or me.designatedDistanceFT == nil) {
                        if (me.tgt != nil) {
                            me.tgt.setVisible(1);
                        }
                        me.clamped = HudMath.isCenterPosClamped(me.echoPos[0],me.echoPos[1]);
                        if (me.clamped) {
                            # b50: Clamped:  120, -86  Canvas Y is 0 to 260  Canvas X is 0 to 236
                            # b40: Clamped: -118,-116  Canvas Y is 0 to 260  Canvas X is 0 to 236
                            #printf("Clamped: %d,%d  Canvas Y is %d to %d  Canvas X is %d to %d",me.echoPos[0],me.echoPos[1],HudMath.originCanvas[1], HudMath.originCanvas[1]+HudMath.canvasHeight,HudMath.originCanvas[0], HudMath.originCanvas[0]+HudMath.canvasWidth);
                        }
                        me.ulrd = me.u.getLastRangeDirect();
                        if (me.ulrd != nil) me.designatedDistanceFT = me.ulrd*M2FT;
                        me.eegsTDshowing = getprop("f16/avionics/gun-sight") != 1 and !me.hydra and eegsShow and me.ulrd != nil;
                        me.target_locked_setVisible = !me.clamped and !me.eegsTDshowing;
                        me.aaTargetDesignationGrp_setVisible = !me.clamped and me.eegsTDshowing;
                        if (me.tgt != nil) {
                            me.tgt.hide();
                        }
                        me.target_locked.setTranslation (me.echoPos);
                        me.aaTargetDesignationGrp.setTranslation (me.echoPos);
                        me.aaTargetDesignationGrp.update();
                        me.loft_cue = 0;
                        if (currASEC != nil) {
                            # disabled for now as it has issues
                            me.cue = nil;
                            call(func {me.cue = hdp.weapn.getIdealFireSolution();},[], nil, nil, var err = []);
                            if(size(err)) {
                                print(err[0]);
                                print(err[1]);
                            }
                            if (me.cue != nil) {
                                me.cueXDeg1 = geo.normdeg180(me.cue[0]-hdp.getproper("heading"));
                                me.cueYDeg1 = me.cue[1]-hdp.getproper("pitch");

                                #printf("%02d, %02d", me.cueXDeg1, me.cueYDeg1);

                                # account for aircraft roll:
                                me.cueXDeg = me.cueXDeg1*math.cos(-hdp.getproper("roll")*D2R)+me.cueYDeg1*math.sin(-hdp.getproper("roll")*D2R);
                                me.cueYDeg = -me.cueXDeg1*math.sin(-hdp.getproper("roll")*D2R)+me.cueYDeg1*math.cos(-hdp.getproper("roll")*D2R);

                                me.ascPos = HudMath.getPosFromDegs(me.cueXDeg, me.cueYDeg);
                                me.ascpixel = math.sqrt(me.ascPos[0]*me.ascPos[0]+me.ascPos[1]*me.ascPos[1]);

                                if (me.ascpixel > 48) {
                                    me.ascReduce = 48/me.ascpixel;# hard clamp
                                } elsif (me.ascpixel > 0) {
                                    me.ascReduce = 1;#math.pow(me.ascpixel/48,0.65) * 48/me.ascpixel;# soft clamp. ASEC120 is 48 pixel radius.
                                } else {
                                    me.ascReduce = 1;
                                }

                                me.ASC.setTranslation(currASEC[0]+me.ascReduce*me.ascPos[0], currASEC[1]+me.ascReduce*me.ascPos[1]);#currASEC = center of ASEC
                                #me.ASC2.setTranslation(HudMath.getCenterPosFromDegs(me.cueXDeg1, me.cueYDeg1));#currASEC = center of ASEC

                                me.loft_cue = me.cue[1];# set loft cue for DLZ
                                showASC = 1;
                            } else {
                                #print("me.cue is nil");
                            }
                        } else {
                            #print("currASEC is nil");
                        }
                        if (pylons.fcs != nil and pylons.fcs.isLock()) {
                            if (hdp.weapon_selected == "AIM-120" or hdp.weapon_selected == "AIM-7" or hdp.weapon_selected == "AIM-9L" or hdp.weapon_selected == "AIM-9M" or hdp.weapon_selected == "AIM-9X" or hdp.weapon_selected == "IRIS-T") {
                                var aim = pylons.fcs.getSelectedWeapon();
                                if (aim != nil) {
                                    var coords = aim.getSeekerInfo();
                                    if (coords != nil) {
                                        me.seekPos = HudMath.getCenterPosFromDegs(coords[0],coords[1]);
                                        me.irDiamond.setTranslation(me.seekPos);
                                        me.radarLock.setTranslation(me.seekPos);
                                    }
                                }
                            }
                            me.asp = radar_system.apg68Radar.getPriorityTarget();
                            if (me.asp != nil) {
                                me.lastH = me.asp.getLastHeading();
                            } else {
                                me.lastH = nil;
                            }
                            if (me.lastH != nil and (hdp.weapon_selected == "AIM-120" or hdp.weapon_selected == "AIM-7")) {
                                me.ASEC120Aspect.setRotation(D2R*(me.lastH-hdp.getproper("heading")+180));
                                me.rdL = 1;
                                me.rdT = 1;
                            } elsif (me.lastH != nil and (hdp.weapon_selected == "AIM-9L" or hdp.weapon_selected == "AIM-9M" or hdp.weapon_selected == "AIM-9X" or hdp.weapon_selected == "IRIS-T")) {
                                me.ASEC65Aspect.setRotation(D2R*(me.lastH-hdp.getproper("heading")+180));
                                me.irT = 1;
                            }
                        } else {
                            #me.target_locked.setRotation(0);
                        }
                        me.dr = me.u.getLastAZDeviation();
                        me.drE = me.u.getLastElevDeviation();
                        if (me.clamped and me.dr != nil and me.drE != nil and math.abs(me.dr) < 90) {
                            me.locatorLine.setTranslation(HudMath.getBorePos());
                            me.veccy = vector.Math.pitchYawVector(me.u.getLastElev(),-me.dr, [1,0,0]);# There is probably simpler ways to do this, but at least I know this works well at great angles.
                            me.veccy = vector.Math.yawPitchRollVector(0, -hdp.getproper("pitch"), -hdp.getproper("roll"), me.veccy);
                            me.lineRot = math.atan2(-me.veccy[1],me.veccy[2]);
                            me.locatorLine.setRotation(me.lineRot);
                            me.align = me.lineRot>0?"right-center":"left-center";
                            me.alignX = me.lineRot>0?-10:10;
                            me.locatorAngle.setText(sprintf("%d", vector.Math.angleBetweenVectors([1,0,0], vector.Math.pitchYawVector(me.drE,-me.dr, [1,0,0]))))
                                .setAlignment(me.align)
                                .setTranslation(HudMath.getBorePos()[0]+me.alignX, HudMath.getBorePos()[1]);
                            me.locatorLineShow = 1;
                        } elsif (!me.clamped and me.eegsTDshowing and !me.hydra and eegsShow and getprop("f16/avionics/gun-sight") == 0) {
                            if (me.u.getLastHeading() != nil) {
                                me.azimuth = geo.normdeg180(me.u.get_bearing()-me.u.getLastHeading());
                                if (me.azimuth == 180 or me.azimuth == 0) {
                                    me.azSide = " ";
                                } else {
                                    me.azSide = me.azimuth > 0 ?"L":"R";# 0 is looking at its engine
                                }
                                me.azimuth = sprintf("AA%3d%s", math.abs(me.azimuth), me.azSide);
                                me.locatorAngle.setText(me.azimuth)
                                    .setAlignment("center-bottom")
                                    .setTranslation(HudMath.getBorePos()[0], HudMath.getBorePos()[1]-6);
                            }
                        }
                        if (me.tgt != nil) {
                            me.tgt.setTranslation (me.echoPos);
                            me.tgt.update();
                        }
                        if (ht_debug) {
                            printf("%-10s %f,%f [%f,%f,%f] :: %f,%f",me.callsign,me.xc,me.yc, me.devs[0], me.devs[1], me.devs[2], me.u_dev_rad*D2R, me.u_elev_rad*D2R);
                        }
                        me.target_idx += 1;
                    }
                } else {
                    print("[ERROR]: HUD too many targets ",me.target_idx);
                }
            }
        } else {
            showACMBore = radar_system.apg68Radar.currentMode.longName == "Air Combat Mode Bore" and radar_system.apg68Radar.enabled and !getprop("payload/armament/hmd-active");
            if (showACMBore) {
                me.acmBoreSymbol.setTranslation(HudMath.getCenterPosFromDegs(0,-3));
            }
            showACMVert = radar_system.apg68Radar.currentMode.longName == "Air Combat Mode 10x60" and radar_system.apg68Radar.enabled;
            if (showACMVert) {
                me.acmVertSymbol.setTranslation(HudMath.getCenterPosFromDegs(0, 0));
            }
        }
        for (me.nv = me.target_idx; me.nv < me.max_symbols;me.nv += 1) {
            me.tgt = me.tgt_symbols[me.nv];
            if (me.tgt != nil) {
                me.tgt.setVisible(0);
            }
        }

        me.ASC.setVisible(showASC);
        #me.ASC2.setVisible(showASC);
        me.acmBoreSymbol.setVisible(showACMBore);
        me.acmVertSymbol.setVisible(showACMVert);
        me.target_locked.setVisible(me.target_locked_setVisible);
        me.aaTargetDesignationGrp.setVisible(me.aaTargetDesignationGrp_setVisible);

        #print(me.irS~" "~me.irL);

        me.locatorLine.setVisible(me.locatorLineShow);
        me.locatorAngle.setVisible(me.locatorLineShow or me.azimuth != "");

        if (hdp.getproper("dgft")) {
            me.ALOW_top = 1;# thsi line is AFTER the code that needs it
            me.peelDeg = 90-hdp.getproper("pitch");
            me.peelRadius = 0.25*me.sx;
            me.peelTickRadius = me.peelRadius+8;
            me.orangePeelGroup.removeAllChildren();
            me.peelLeft = me.orangePeelGroup.createChild("path")
                .moveTo(0,me.peelRadius)
                .arcSmallCW(me.peelRadius, me.peelRadius, 0,-me.peelRadius*math.sin(me.peelDeg*D2R), me.peelRadius*math.cos(me.peelDeg*D2R)-me.peelRadius)
                .lineTo(-me.peelTickRadius*math.sin(me.peelDeg*D2R), me.peelTickRadius*math.cos(me.peelDeg*D2R))
                .moveTo(0,me.peelRadius)
                .arcSmallCCW(me.peelRadius, me.peelRadius, 0, me.peelRadius*math.sin(me.peelDeg*D2R), me.peelRadius*math.cos(me.peelDeg*D2R)-me.peelRadius)
                .lineTo(me.peelTickRadius*math.sin(me.peelDeg*D2R), me.peelTickRadius*math.cos(me.peelDeg*D2R))
                .setStrokeLineWidth(1)
                .setColor(me.color);
            if (hdp.getproper("servTurn")) {
                me.orangePeelGroup.setRotation(-hdp.getproper("roll")*D2R);
            }
            me.orangePeelGroup.show();
            me.orangePeelGroup.update();
        } else {
            me.orangePeelGroup.hide();
        }


        me.dlzArray = pylons.getDLZ();
        #me.dlzArray =[10,8,6,2,9];#test
        if (me.dlzArray == nil or size(me.dlzArray) == 0) {
                me.dlz.hide();
                hdp.dlz_show = 0;
        } else {
            #printf("%d %d %d %d %d",me.dlzArray[0],me.dlzArray[1],me.dlzArray[2],me.dlzArray[3],me.dlzArray[4]);
            me.dlz2.removeAllChildren();
            me.dlzArrow.setTranslation(0,-me.dlzArray[4]/me.dlzArray[0]*me.dlzHeight);
            me.dlzPrio = radar_system.apg68Radar.getPriorityTarget();
            if (me.dlzPrio != nil) {
                me.dlzClos = me.dlzPrio.getLastClosureRate();
            } else {
                me.dlzClos = nil;
            }
            if (me.dlzClos != nil) {
                me.dlzClo.setTranslation(0,-me.dlzArray[4]/me.dlzArray[0]*me.dlzHeight);
                me.dlzClo.setText(sprintf("%+d ",me.dlzClos));
                if (pylons.fcs.isLock() and me.dlzArray[4] < me.dlzArray[2] and math.mod(int(4*(hdp.getproper("elapsed")-int(hdp.getproper("elapsed")))),2)>0) {
                    #me.irL = 0;
                    me.rdL = 0;
                }
                if (pylons.fcs.isLock()) {
                    me.scale120 = me.extrapolate(me.dlzArray[4],me.dlzArray[2],me.dlzArray[3],1,30/120);
                    me.scale120 = me.clamp(me.scale120,30/120,1);
                    me.ASEC120.setScale(me.scale120,me.scale120);#todo error
                    me.ASEC120.setStrokeLineWidth(1/me.scale120);
                    #me.ASEC120Aspect.setScale(me.scale120,me.scale120);
                    #me.ASEC120Aspect.setStrokeLineWidth(1/me.scale120);
                    me.ASEC120Aspect.setTranslation(me.sx*0.5,me.sy*0.25-me.scale120*0.4*120);#0.4=mr
                    #me.ASEC120Aspect.setCenter(0,me.scale120*0.4*120);
                    me.ASEC120Aspect.setCenter(0,me.scale120*0.4*120);
                }
            } else {
                me.dlzClo.setText("");
            }
            me.dlzGeom = me.dlz2.createChild("path")
                    .moveTo(me.dlzWidth, 0)
                    .horiz(-me.dlzWidth)
                    .lineTo(0, -me.dlzArray[3]/me.dlzArray[0]*me.dlzHeight)
                    .moveTo(0, -me.dlzArray[3]/me.dlzArray[0]*me.dlzHeight)
                    .lineTo(0, -me.dlzArray[2]/me.dlzArray[0]*me.dlzHeight)
                    .lineTo(me.dlzWidth, -me.dlzArray[2]/me.dlzArray[0]*me.dlzHeight)
                    .lineTo(me.dlzWidth, -me.dlzArray[3]/me.dlzArray[0]*me.dlzHeight)
                    .lineTo(0, -me.dlzArray[3]/me.dlzArray[0]*me.dlzHeight)
                    .lineTo(0, -me.dlzArray[1]/me.dlzArray[0]*me.dlzHeight)
                    .lineTo(me.dlzWidth, -me.dlzArray[1]/me.dlzArray[0]*me.dlzHeight)
                    .moveTo(0, -me.dlzHeight)
                    .lineTo(me.dlzWidth, -me.dlzHeight-3)
                    .lineTo(me.dlzWidth, -me.dlzHeight+3)
                    .lineTo(0, -me.dlzHeight)
                    .setStrokeLineWidth(me.dlzLW)
                    .setColor(me.color);
            me.dlz2.update();
            if (me.dlzArray[4] > me.dlzArray[0]*1.25) {# MLU Tape 3 page 29
                me.dlzFCRRange.setTranslation(me.dlzWidth*0.5, -me.dlzHeight-5);
                me.dlzFCRRange.setText(""~radar_system.apg68Radar.getRange());
                me.dlzFCRRange.show();
            } elsif (me["loft_cue"] != nil and me.loft_cue > 0.999) {
                me.dlzFCRRange.setTranslation(me.dlzWidth*0.5, -me.dlzHeight-5);
                me.dlzFCRRange.setText(sprintf("%2d\xc2\xb0", me.loft_cue));
                me.dlzFCRRange.show();
            } else {
                me.dlzFCRRange.hide();
            }
            me.dlz.show();
            hdp.dlz_show = 1;
        }

        me.radarLock.setVisible(me.rdL);
        me.irDiamondSmall.setVisible(me.irS);
        me.irDiamond.setVisible(me.irL);
        me.irCross.setVisible(me.irB);
        me.ASEC120Aspect.setVisible(me.rdT);
        me.ASEC65Aspect.setVisible(me.irT);
        me.radarLock.update();
        me.irDiamond.update();
        me.irDiamondSmall.update();


        if (hdp.getproper("ded") == 2 and !hdp.getproper("dgft")) {
            me.ded0.setText(ded.dataEntryDisplay.text[0]);
            me.ded1.setText(ded.dataEntryDisplay.text[1]);
            me.ded2.setText(ded.dataEntryDisplay.text[2]);
            me.ded3.setText(ded.dataEntryDisplay.text[3]);
            me.ded4.setText(ded.dataEntryDisplay.text[4]);
            me.ded0.show();
            me.ded1.show();
            me.ded2.show();
            me.ded3.show();
            me.ded4.show();
        } elsif (hdp.getproper("ded") == 1 and !hdp.getproper("dgft")) {
            me.ded0.setText(pfd.text[0]);
            me.ded1.setText(pfd.text[1]);
            me.ded2.setText(pfd.text[2]);
            me.ded3.setText(pfd.text[3]);
            me.ded4.setText(pfd.text[4]);
            me.ded0.show();
            me.ded1.show();
            me.ded2.show();
            me.ded3.show();
            me.ded4.show();
        } else {
            me.ded0.hide();
            me.ded1.hide();
            me.ded2.hide();
            me.ded3.hide();
            me.ded4.hide();
        }

        if (tgp.flir_updater.click_coord_cam != nil and getprop("f16/avionics/tgp-lock")) {# hdp.getproper("tgp_mounted") and
            if (getprop("sim/view[105]/heading-offset-deg")==0 and getprop("sim/view[105]/pitch-offset-deg")==-30 and armament.contactPoint != nil) {
                #var b = geo.normdeg180(armament.contactPoint.get_relative_bearing());
                #var p = armament.contactPoint.getElevation()-hdp.getproper("pitch");
                var xy = HudMath.getPosFromCoord(armament.contactPoint.get_Coord());
                var y = me.clamp(xy[1],-me.sy*0.40,me.sy*0.40);
                var x = me.clamp(xy[0],-me.sx*0.45,me.sx*0.45);
                #var y = me.clamp(-p*me.texelPerDegreeY+me.sy-me.texels_up_into_hud,me.sy*0.05,me.sy*0.95);
                #var x = me.clamp(b*me.texelPerDegreeX+me.sx*0.5,me.sx*0.025,me.sx*0.975);
                #printf("TGP idle: %.2f,%.2f",xy[2],xy[3]);
                if (y != xy[1] or x != xy[0]) {
                    if (xy[0] != 0 and xy[1] != 0) {
                        var x_scale = me.sx*0.40/math.abs(xy[0]);
                        var y_scale = me.sy*0.45/math.abs(xy[1]);
                        if (x_scale < y_scale) {
                            x = xy[0] * x_scale;
                            y = xy[1] * x_scale;
                        } else {
                            x = xy[0] * y_scale;
                            y = xy[1] * y_scale;
                        }
                        me.tgpPointC.setTranslation(x,y);
                        me.tgpPointC.show();
                    } else {
                        me.tgpPointC.hide();
                    }
                } else {
                    me.tgpPointC.hide();
                }
                me.tgpPointF.setTranslation(x,y);
                me.tgpPointF.show();
            } else {
                var b = geo.normdeg180(getprop("sim/view[105]/heading-offset-deg"));
                var p = getprop("sim/view[105]/pitch-offset-deg");
                #printf("TGP stat: %.2f,%.2f",b,p);
                var behind = 0;
                if(b < -90) {
                    b = -180-b;
                    p = -p;
                    behind = 1;
                } elsif (b > 90) {
                    b = 180-b;
                    p = -p;
                    behind = 1;
                }

                var xy = HudMath.getCenterPosFromDegs(b,p);
                var x = me.clamp(xy[0],-me.sx*0.45,me.sx*0.45);
                var y = me.clamp(xy[1],-me.sy*0.40,me.sy*0.40);

                if (y != xy[1] or x != xy[0] or behind) {
                    if (xy[0] != 0 and xy[1] != 0) {
                        var x_scale = me.sx*0.45/math.abs(xy[0]);
                        var y_scale = me.sy*0.40/math.abs(xy[1]);
                        if (x_scale < y_scale) {
                            x = xy[0] * x_scale;
                            y = xy[1] * x_scale;
                        } else {
                            x = xy[0] * y_scale;
                            y = xy[1] * y_scale;
                        }
                        me.tgpPointC.setTranslation(x,y);
                        me.tgpPointC.show();
                    } else {
                        me.tgpPointC.hide();
                    }
                } else {
                    me.tgpPointC.hide();
                }
                me.tgpPointF.setTranslation(x,y);
                me.tgpPointF.show();
            }
        } else {
            me.tgpPointF.hide();
            me.tgpPointC.hide();
        }

        if (f16.SOI == 1) {
		    me.soi_indicator.show();
        } else {
		    me.soi_indicator.hide();
        }


        me.initUpdate = 0;

        hdp.submode = me.submode;

        me.old_hdp = {
        "hud_serviceable":hdp.getproper("hud_serviceable"),
        "hud_display":hdp.getproper("hud_display"),
        "hud_sym":hdp.getproper("hud_sym"),
        "hud_power":hdp.getproper("hud_power"),
        "hud_daytime":hdp.getproper("hud_daytime"),
        "red":hdp.getproper("red"),
        };
        me.firstOne = 1;
        foreach(var update_item; me.update_items)
        {
            if(me.firstOne) {update_item.update(me.old_hdp);me.firstOne = 0;}
            else update_item(hdp);
        }
          if (me.window3_txt != nil and me.window3_txt != ""){
              me.window3.setText(me.window3_txt);
              me.window3.show();
          }else
            me.window3.hide();

          if (me.window4_txt != nil and me.window4_txt != ""){
              me.window4.show();
              me.window4.setText(me.window4_txt);
          }
          else
            me.window4.hide();

          if (me.window5_txt != nil and me.window5_txt != ""){
              me.window5.show();
              me.window5.setText(me.window5_txt);
          }
          else
            me.window5.hide();

          if (me.window6_txt != nil and me.window6_txt != ""){
              me.window6.show();
              me.window6.setText(me.window6_txt);
          }
          else
            me.window6.hide();

          if (me.window7_txt != nil and me.window7_txt != ""){
              me.window7.show();
              me.window7.setText(me.window7_txt);
          }
          else
            me.window7.hide();

          if (me.window9_txt != nil and me.window9_txt != ""){
              me.window9.show();
              me.window9.setText(me.window9_txt);
          }
          else
            me.window9.hide();

          if (me.window10_txt != nil and me.window10_txt != ""){
              me.window10.show();
              me.window10.setText(me.window10_txt);
          }
          else
            me.window10.hide();

          if (me.window11_txt != nil and me.window11_txt != ""){
              me.window11.show();
              me.window11.setText(me.window11_txt);
          }
          else
            me.window11.hide();

          if (me.window1_txt != nil and me.window1_txt != ""){
              me.window1.show();
              me.window1.setText(me.window1_txt);
          }
          else
            me.window1.hide();
        me.svg.show();
        transfer_stpt = me.window5_txt;
        transfer_dist = me.window3_txt;
        transfer_arms = me.window9_txt;
        transfer_mode = me.window2_txt;
        transfer_fuel_bullseye = me.window11_txt;
        transfer_g    = me.window12_txt;
        return;
        me.window1.setText("window  1").show();
        me.window2.setText("window  2").show();
        me.window3.setText("window  3").show();
        me.window4.setText("window  4").show();
        me.window5.setText("window  5").show();
        me.window6.setText("window  6").show();
        me.window7.setText("window  7").show();
        me.window8.setText("window  8").show();
        me.window9.setText("window  9").show();
        me.window10.setText("window 10").show();
        me.window11.setText("window 11").show();
        me.window12.setText("window 12").show();#
    },

#  12
#
#     FG
#
#
#  2      10
#  7       3
#  8       4
#  9       5
# 11       6

#  5
#
#    REAL
#
#
#   30    32
#    3    37
#    4      26
#   7       25
#  8        10
# 15        13
# 35        14
# 36

#Text windows on the HUD (FG F-16 May 11 2021)
# 12 currG           1 not used
#                   10 ALOW
# 2 mode             3 slant            / callsign
# 7 mach             4 eta              / target angels
# 8 maxG             5 waypoint
# 9 weap             6 not used
# 11 fuel

#Text windows on the HUD (FG F-16 rework)
# 12 currG           1 ALOW-top
#
#                   10 ALOW             / target angels
# 2 mode             3 slant
# 7 mach             4 eta              / time to go      TODO: CCRP: time to release / closure rate in kt: A/A guns
# 8 maxG             5 waypoint
# 9 weap             6 callsign
# 11 fuel
#
# TA replace ALOW in A-A ALOW:top
# slant is F for radar computed, B for steerpoint, R for CARA, X XXX elsewise, empty for no target


    resetGunPos: func {
        me.gunPos   = [];
        for(i = 0;i < me.funnelPartsMax;i+=1){
          var tmp = [];
          for(var myloopy = 0;myloopy <= i+1;myloopy+=1){
            append(tmp,nil);
          }
          append(me.gunPos, tmp);
        }
    },

    makeVector: func (siz,content) {
        var vec = setsize([],siz*2);
        var k = 0;
        while(k<siz*2) {
            vec[k] = content;
            k += 1;
        }
        return vec;
    },
#
#
# get a text element from the SVG and set the font / sizing
    get_text : func(id, font, size, ratio)
    {
        var el = me.svg.getElementById(id);
        el.setFont(font).setFontSize(size,ratio);
        return el;
    },

    getAltTxt: func (alt) {
        if (alt < 1000) {
            me.txtRAlt = sprintf("%03d",math.round(alt,10));
        } else {
            # CARA is never more than 5 digits, and aircraft is not supposed to fly above 100k ft
            me.txtRAlt = sprintf("%d",math.round(alt,10));
        }
        if (alt < 0) {
            if (alt>-1000) {
                me.txtRAlt = sprintf(" -,%s", right(me.txtRAlt,3));
            } else {
                me.txtRAlt = sprintf("%s,%s", left(me.txtRAlt,size(me.txtRAlt)-3),right(me.txtRAlt,3));
            }
            # no reason to cope for alts lower than -9999ft
        } elsif (alt<1000) {
            me.txtRAlt = sprintf("  ,%s", right(me.txtRAlt,3));
        } else {
            me.txtRAlt = sprintf("%s%s,%s", size(me.txtRAlt)==4?" ":"",left(me.txtRAlt,size(me.txtRAlt)-3),right(me.txtRAlt,3));
        }
        return me.txtRAlt; # always return 6 char string
    },


#
#
# Get an element from the SVG; handle errors; and apply clip rectangle
# if found (by naming convention : addition of _clip to object name).

    get_element : func(id) {
        var el = me.svg.getElementById(id);
        if (el == nil)
        {
            print("Failed to locate ",id," in SVG");
            return el;
        }
        var clip_el = me.svg.getElementById(id ~ "_clip");
        if (clip_el != nil)
        {

            var tran_rect = clip_el.getTransformedBounds();

            if (use_war_hud and id == "heading-scale") {
                #obj.heading_tape_clip.createChild("path").square(-500,-500,1000).setColorFill(0,0,1);
                tran_rect[2] = tran_rect[2]+7;#left
                tran_rect[0] = tran_rect[0]+7;
                clip_el.setTranslation(7,0);
            }# else {
                clip_el.setVisible(0);
            #}

            var clip_rect = sprintf("rect(%d,%d, %d,%d)",
                                   tran_rect[1], # 0 ys
                                   tran_rect[2],  # 1 xe
                                   tran_rect[3], # 2 ye
                                   tran_rect[0]); #3 xs
#            print(id," using clip element ",clip_rect, " trans(",tran_rect[0],",",tran_rect[1],"  ",tran_rect[2],",",tran_rect[3],")");
#   see line 621 of simgear/canvas/CanvasElement.cxx
#   not sure why the coordinates are in this order but are top,right,bottom,left (ys, xe, ye, xs)
            el.set("clip", clip_rect);
            el.set("clip-frame", canvas.Element.PARENT);
        }
        return el;
    },

    CCRP: func(hdp) {
        if (hdp.fcs_available and hdp.getproper("master_arm") != pylons.ARM_OFF and pylons.fcs.getDropMode() == fc.DROP_CCRP) {
            var selW = pylons.fcs.getSelectedWeapon();
            if (selW == nil) {
                me.solutionCue.hide();
                me.ccrpMarker.hide();
                me.bombFallLine.hide();
                return 0;
            }
            var trgt = fc.getCCRPTarget();
            
            if (trgt == nil) {
                # We must return 1 if its a bomb and were in CCRP drop mode
                me.solutionCue.hide();
                me.ccrpMarker.hide();
                me.bombFallLine.hide();
                return fc.containsVector(fc.CCIP_CCRP, selW.type);
            }
            
            if (!hdp.CCIP_active and
                    fc.containsVector(fc.CCIP_CCRP, selW.type) and selW.status == armament.MISSILE_LOCK ) {
                me.distCCRP = getprop("payload/armament/distCCRP");
                if (me.distCCRP == -1 or (me.distCCRP*M2NM > 13.2 and selW.guidance == "laser")) {#1F-F16CJ-34-1: max laser dist is 13.2nm
                    me.solutionCue.hide();
                    me.ccrpMarker.hide();
                    me.bombFallLine.hide();
                    return 1;
                }
                if (hdp.getproper("groundspeed_kt") > 0) {
                    me.timeToRelease = me.distCCRP/hdp.getproper("groundspeed_kt");
                }
                me.distCCRP/=4000;
                if (me.distCCRP > 0.75) {
                    me.distCCRP = 0.75;
                }
                me.ldr = trgt.getLastAZDeviation();
                if (me.ldr == nil) {
                    me.blepCoord = trgt.get_Coord();
                    if (trgt == armament.contactPoint and me.blepCoord != nil) {
                        me.blepHeading = radar_system.self.getCoord().course_to(me.blepCoord);
                        me.ldr = geo.normdeg180(me.blepHeading-radar_system.self.getHeading());
                    } else {
                        me.solutionCue.hide();
                        me.ccrpMarker.hide();
                        me.bombFallLine.hide();
                        return 1;
                    }
                }
                me.bombFallLine.setTranslation(me.ldr*me.texelPerDegreeX,0);
                me.ccrpMarker.setTranslation(me.ldr*me.texelPerDegreeX,0);
                me.solutionCue.setTranslation(me.ldr*me.texelPerDegreeX,me.sy*0.5-me.sy*0.5*me.distCCRP);
                me.bombFallLine.show();
                me.ccrpMarker.show();
                me.solutionCue.show();
                return math.abs(me.ldr)<20?2:1;
            } else {
                me.solutionCue.hide();
                me.ccrpMarker.hide();
                me.bombFallLine.hide();
                return 1;
            }
        } else {
            me.solutionCue.hide();
            me.ccrpMarker.hide();
            me.bombFallLine.hide();
            return 0;
        }
    },

    CCIP: func (hdp) {
        me.showPipper = 0;
        me.showPipperCross = 0;
        me.showmeCCIP = 0;
        if(hdp.CCIP_active) {
            if (hdp.fcs_available and hdp.getproper("master_arm") != pylons.ARM_OFF) {
                var selW = pylons.fcs.getSelectedWeapon();
                if (selW != nil and fc.containsVector(fc.CCIP_CCRP, selW.type)) {
                    me.showmeCCIP = 1;
                    me.ccipPos = pylons.fcs.getSelectedWeapon().getCCIPadv(18,0.20);
                    if (me.ccipPos == nil) {
                        me.pipper.setVisible(me.showPipper);
                        me.pipperLine.setVisible(me.showPipper);
                        return 0;
                    }
                    me.showme = 1;

                    #me.myOwnPos = geo.aircraft_position();
                    #me.xyz = {"x":me.myOwnPos.x(),                  "y":me.myOwnPos.y(),                 "z":me.myOwnPos.z()};
                    #me.dir = {"x":me.ccipPos[0].x()-me.myOwnPos.x(),  "y":me.ccipPos[0].y()-me.myOwnPos.y(), "z":me.ccipPos[0].z()-me.myOwnPos.z()};
                    #me.v = get_cart_ground_intersection(me.xyz, me.dir);
                    #if (me.v != nil) {
                    #    me.terrain = geo.Coord.new();
                    #    me.terrain.set_latlon(me.v.lat, me.v.lon, me.v.elevation);
                    #    me.maxDist = me.myOwnPos.direct_distance_to(me.ccipPos[0])-1;
                    #    me.terrainDist = me.myOwnPos.direct_distance_to(me.terrain);
                    #    if (me.terrainDist < me.maxDist) {
                    #        me.showme = 0;
                    #    }
                    #} else {
                    #    me.showme = 0;
                    #}
                    me.hud_pos = HudMath.getPosFromCoord(me.ccipPos[0]);
                    if(me.hud_pos != nil) {
                        me.pos_x = me.hud_pos[0];
                        me.pos_y = me.hud_pos[1];
                        #printf("HUDMath  %.1f", HudMath.dir_x);
                        #printf("Aircraft %.1f", hdp.getproper("heading"));
                        #printf("dist=%0.1f (%3d , %3d)", dist, pos_x, pos_y);

                        #if(me.pos_x > (512/1024)*canvasWidth) {
                        #  me.showme = 0;
                        #} elsif(me.pos_x < -(512/1024)*canvasWidth) {
                        #  me.showme = 0;
                        #} elsif(me.pos_y > (512/1024)*canvasWidth) {
                        #  me.showme = 0;
                        #} elsif(me.pos_y < -(512/1024)*canvasWidth) {
                        #  me.showme = 0;
                        #}

                        if(me.showme == 1) {
                            me.pipperLine.removeAllChildren();
                            me.bPos = [hdp.VV_x,hdp.VV_y];
                            me.llx  = me.pos_x-me.bPos[0];
                            me.lly  = me.pos_y-me.bPos[1];
                            me.ll = math.sqrt(me.llx*me.llx+me.lly*me.lly);
                            if (me.ll != 0) {
                                me.pipAng = math.acos(me.llx/me.ll);
                                #printf("angle %d  %d,%d",me.pipAng*R2D,me.llx,me.lly);
                                if (me.lly < 0) {
                                    me.pipAng *= -1;
                                }
                                me.pipperLine.createChild("path")
                                    .moveTo(me.bPos)
                                    .lineTo(me.pos_x-math.cos(me.pipAng)*me.pipperRadius, me.pos_y-math.sin(me.pipAng)*me.pipperRadius)
                                    .setStrokeLineWidth(1)
                                    .setColor(me.color)
                                    .update();
                                me.pipper.setTranslation(me.pos_x, me.pos_y);
                                #me.pipperCross.setTranslation(me.pos_x, me.pos_y);
                                me.showPipperCross = !me.ccipPos[1];
                                me.pipper.update();
                                #me.pipperCross.update();
                                me.showPipper = 1;
                            }
                        }
                    }
                }
            }
        }
        me.pipper.setVisible(me.showPipper);
        #me.pipperCross.setVisible(0);#me.showPipperCross);
        me.pipperLine.setVisible(me.showPipper);
        return me.showPipperCross?-1:1;
    },

    # Should match gun submodel parameters
    gunEda: 0.00338158219,
    gunWeight: 0.226,
    gunSpeed: 3379.0,
    gunCd: 0.09,
    gunLoc: [-3.16, -0.81, 0.17],

    displayEEGS: func() {
        #note: this stuff is expensive like hell to compute, but..lets do it anyway.
        var gunSight = getprop("f16/avionics/gun-sight");
        var st = systime();
        me.eegsMe.dt = st-me.lastTime;
        if (me.eegsMe.dt > me.averageDt*3) {
            me.lastTime = st;
            me.resetGunPos();
            me.eegsGroup.removeAllChildren();
        } else {
            #printf("dt %05.3f",me.eegsMe.dt);
            me.lastTime = st;

            me.eegsMe.hdg   = getprop("orientation/heading-deg");
            me.eegsMe.pitch = getprop("orientation/pitch-deg");
            me.eegsMe.roll  = getprop("orientation/roll-deg");

            me.eegsMe.hdg_ac   = me.eegsMe.hdg;
            me.eegsMe.pitch_ac = me.eegsMe.pitch;
            me.eegsMe.roll_ac  = me.eegsMe.roll;

            var hdp = {roll:me.eegsMe.roll,current_view_z_offset_m: getprop("sim/current-view/z-offset-m")};

            me.eegsMe.ac = geo.aircraft_position();
            me.eegsMe.eye = geo.viewer_position();
            me.eegsMe.allow = 1;
            me.drawSTRFPipper = 0;
            me.drawGunAim = 0;
            me.strfRange = 24000;
            if(gunSight == 1 or me.hydra) {
                me.groundAltDiffLastPointFT = nil;
                var currSegmentPt = 0;
                for (currSegmentPt = 0;currSegmentPt < me.funnelPartsMax;currSegmentPt+=1) {
                    # compute terrain impact position of trajectory
                    var pos = me.gunPos[currSegmentPt][0];
                    if (pos == nil) {
                        me.eegsMe.allow = 0;
                    } else {
                        var ptc = me.gunPos[currSegmentPt][0][2];
                        var ac  = me.gunPos[currSegmentPt][0][1];
                        pos     = me.gunPos[currSegmentPt][0][0];
                        var el = geo.elevation(pos.lat(),pos.lon());
                        if (el == nil) {
                            el = 0;
                        }

                        if (currSegmentPt != 0 and el > pos.alt()) {
                            var hitPos = geo.Coord.new(pos);
                            hitPos.set_alt(el);
                            me.groundAltDiffLastPointFT = (el-pos.alt())*M2FT;
                            me.strfRange = hitPos.direct_distance_to(me.eegsMe.ac)*M2FT;
                            me.elevationToEnd = vector.Math.getPitch(me.eegsMe.ac, pos);
                            if (me.groundAltDiffLastPointFT > 0 and me.elevationToEnd < 0 and math.sin(-me.elevationToEnd*D2R) != 0) {
                                # We assume the ground is level and flat at impact position
                                me.strfRange -= me.groundAltDiffLastPointFT/math.sin(-me.elevationToEnd*D2R);
                            }
                            break;# this gunpos is below terrain, break the loop.
                        }
                    }
                }
                
                if (me.eegsMe.allow and me.groundAltDiffLastPointFT != nil) {
                    # compute display positions of STRF pipper on hud
                    for (var ll = currSegmentPt-1;ll <= currSegmentPt;ll+=1) {
                        var pos   = me.gunPos[ll][0][0];
                        var ac    = me.gunPos[ll][0][1];
                        var pitch = me.gunPos[ll][0][2];

                        me.eegsMe.posTemp = HudMath.getPosFromCoord(pos,me.eegsMe.eye);
                        #me.eegsMe.shellPosDist[ll] = ac.direct_distance_to(pos)*M2FT;
                        me.eegsMe.shellPosX[ll] = me.eegsMe.posTemp[0];
                        me.eegsMe.shellPosY[ll] = me.eegsMe.posTemp[1];

                        if (currSegmentPt == ll and me.strfRange < 24000) {
                            #var highdist = me.eegsMe.shellPosDist[ll];
                            #var lowdist = me.eegsMe.shellPosDist[ll-1];
                            if (pitch >= 0) {
                                #me.eegsPipperX = me.interpolate(highdist-me.groundAltDiffLastPointFT,lowdist,highdist,me.eegsMe.shellPosX[ll-1],me.eegsMe.shellPosX[ll]);
                                #me.eegsPipperY = me.interpolate(highdist-me.groundAltDiffLastPointFT,lowdist,highdist,me.eegsMe.shellPosY[ll-1],me.eegsMe.shellPosY[ll]);
                                me.eegsPipperX = 0.5*me.eegsMe.shellPosX[ll-1]+0.5*me.eegsMe.shellPosX[ll];
                                me.eegsPipperY = 0.5*me.eegsMe.shellPosY[ll-1]+0.5*me.eegsMe.shellPosY[ll];
                            } else {
                                # increasing accuracy me.strfRange and pipper HUD position
                                me.groundDistDiffLastPointFT = me.groundAltDiffLastPointFT/math.sin(-pitch*D2R);# We assume the ground is level and flat at impact position

                                me.posLow = me.gunPos[ll-1][0][0];
                                me.posHigh = me.gunPos[ll][0][0];
                                me.posDist = me.posHigh.direct_distance_to(me.posLow)*M2FT;
                                me.impactPos = me.interpolateCoords(me.posLow, me.posHigh, 1-me.groundDistDiffLastPointFT/me.posDist);
                                me.strfRange = me.impactPos.direct_distance_to(me.eegsMe.ac)*M2FT;
                                me.tmpImpact = HudMath.getPosFromCoord(me.impactPos,me.eegsMe.eye);
                                me.eegsPipperX = me.tmpImpact[0];
                                me.eegsPipperY = me.tmpImpact[1];
                            }
                            me.drawSTRFPipper = 1;
                        }
                    }
                }
            } else {
                for (var currSegmentPt = 0;currSegmentPt < me.funnelParts;currSegmentPt+=1) {
                    # compute display positions of gun path on hud
                    var pos = me.gunPos[currSegmentPt][currSegmentPt+1];
                    if (pos == nil) {
                        me.eegsMe.allow = 0;
                    } else {
                        var ac  = me.gunPos[currSegmentPt][currSegmentPt][1];
                        pos     = me.gunPos[currSegmentPt][currSegmentPt][0];
                        me.eegsMe.posTemp = HudMath.getPosFromCoord(pos,me.eegsMe.eye);
                        me.eegsMe.shellPosX[currSegmentPt] = me.eegsMe.posTemp[0];
                        me.eegsMe.shellPosY[currSegmentPt] = me.eegsMe.posTemp[1];
                        me.eegsMe.shellPosDist[currSegmentPt] = ac.direct_distance_to(pos)*M2FT;

                        if (me.designatedDistanceFT != nil and !me.drawGunAim and gunSight != 2) {
                          #eegs pipper
                          if (currSegmentPt != 0 and me.eegsMe.shellPosDist[currSegmentPt] >= me.designatedDistanceFT and me.eegsMe.shellPosDist[currSegmentPt]>me.eegsMe.shellPosDist[currSegmentPt-1]) {
                            var highdist = me.eegsMe.shellPosDist[currSegmentPt];
                            var lowdist = me.eegsMe.shellPosDist[currSegmentPt-1];
                            me.eegsPipperX = HudMath.extrapolate(me.designatedDistanceFT,lowdist,highdist,me.eegsMe.shellPosX[currSegmentPt-1],me.eegsMe.shellPosX[currSegmentPt]);
                            me.eegsPipperY = HudMath.extrapolate(me.designatedDistanceFT,lowdist,highdist,me.eegsMe.shellPosY[currSegmentPt-1],me.eegsMe.shellPosY[currSegmentPt]);
                            me.drawGunAim = 1;
                          }
                        }
                    }
                }
                if (me.designatedDistanceFT != nil and gunSight == 2) {
                    #snap pipper
                    for (var currSegmentPt = 6;currSegmentPt < me.funnelParts;currSegmentPt+=5) {
                        if (!me.drawGunAim and (me.eegsMe.shellPosDist[currSegmentPt] >= me.designatedDistanceFT or currSegmentPt==16) and me.eegsMe.shellPosDist[currSegmentPt]>me.eegsMe.shellPosDist[currSegmentPt-5]) {
                            # The check for 16 is to draw the aim extending from last segment if range is larger than last.
                            var highdist = me.eegsMe.shellPosDist[currSegmentPt];
                            var lowdist = me.eegsMe.shellPosDist[currSegmentPt-5];
                            me.eegsPipperX = HudMath.extrapolate(me.designatedDistanceFT,lowdist,highdist,me.eegsMe.shellPosX[currSegmentPt-5],me.eegsMe.shellPosX[currSegmentPt]);
                            me.eegsPipperY = HudMath.extrapolate(me.designatedDistanceFT,lowdist,highdist,me.eegsMe.shellPosY[currSegmentPt-5],me.eegsMe.shellPosY[currSegmentPt]);
                            me.drawGunAim = 1;
                        }
                    }
                }
            }
            if (me.eegsMe.allow and gunSight == 0 and !me.hydra) {
                # draw the funnel
                for (var k = 0;k<me.funnelParts;k+=1) {
                    var halfspan = math.atan2(getprop("f16/avionics/gun-eegs-wingspan-ft")*0.5,me.eegsMe.shellPosDist[k])*R2D*me.texelPerDegreeX;#35ft average fighter wingspan
                    me.eegsRightX[k] = me.eegsMe.shellPosX[k]-halfspan;
                    me.eegsRightY[k] = me.eegsMe.shellPosY[k];
                    me.eegsLeftX[k]  = me.eegsMe.shellPosX[k]+halfspan;
                    me.eegsLeftY[k]  = me.eegsMe.shellPosY[k];
                }
                me.eegsGroup.removeAllChildren();
                for (var i = 1; i < me.funnelParts-1; i+=1) {#changed to i=1 as we dont need funnel to start so close
                    me.eegsGroup.createChild("path")
                        .moveTo(me.eegsRightX[i], me.eegsRightY[i])
                        .lineTo(me.eegsRightX[i+1], me.eegsRightY[i+1])
                        .moveTo(me.eegsLeftX[i], me.eegsLeftY[i])
                        .lineTo(me.eegsLeftX[i+1], me.eegsLeftY[i+1])
                        .setStrokeLineWidth(1)
                        .setColor(me.color);
                }
                # Test snake:
                #for (var i = 0; i < me.funnelParts-1; i+=1) {
                #     me.tmpSegment = me.eegsGroup.createChild("path")
                #        .moveTo(me.eegsMe.shellPosX[i], me.eegsMe.shellPosY[i])
                #        .lineTo(me.eegsMe.shellPosX[i+1], me.eegsMe.shellPosY[i+1])
                #        .setStrokeLineWidth(1)
                #        .setColor(me.color);
                #}
                if (me.drawGunAim) {
                    var radius = 2;
                    me.eegsGroup.createChild("path")
                          .moveTo(me.eegsPipperX, me.eegsPipperY-radius)
                          .arcSmallCW(radius,radius,0,0,radius*2)
                          .arcSmallCW(radius,radius,0,0,-radius*2)
                          .setStrokeLineWidth(1)
                          .setColor(me.color);
                }
                me.eegsGroup.update();
            } elsif (me.eegsMe.allow and gunSight == 2 and !me.hydra) {
                # draw snap
                me.eegsGroup.removeAllChildren();
                for (var i = 1; i < me.funnelParts-5; i+=5) {#changed to i=1 as we dont need lines to start so close
                    me.tmpSegment = me.eegsGroup.createChild("path")
                        .moveTo(me.eegsMe.shellPosX[i], me.eegsMe.shellPosY[i])
                        .lineTo(me.eegsMe.shellPosX[i+5], me.eegsMe.shellPosY[i+5])
                        .setStrokeLineWidth(1)
                        .setColor(me.color);
                    if (i > 5) {
                        me.dx = me.eegsMe.shellPosX[i] - me.eegsMe.shellPosX[i+5];
                        me.dy = me.eegsMe.shellPosY[i] - me.eegsMe.shellPosY[i+5];
                        me.dl = math.sqrt(me.dx*me.dx+me.dy*me.dy);
                        if (me.dl != 0) {
                            me.angle1 = math.acos(math.clamp(me.dx/me.dl,-1,1));
                            me.angle2 = math.asin(math.clamp(me.dy/me.dl,-1,1));
                            me.angle  = me.angle2<0?-me.angle1:me.angle1;
                            me.angle += 90 * D2R;
                            me.segmentRel = [3*math.cos(me.angle),3*math.sin(me.angle)];
                            me.tmpSegment
                                    .moveTo(me.eegsMe.shellPosX[i+5]+me.segmentRel[0], me.eegsMe.shellPosY[i+5]+me.segmentRel[1])
                                    .lineTo(me.eegsMe.shellPosX[i+5]-me.segmentRel[0], me.eegsMe.shellPosY[i+5]-me.segmentRel[1]);
                        }
                    }
                }
                if (me.drawGunAim) {
                    var radius = 2;
                    me.eegsGroup.createChild("path")
                          .moveTo(me.eegsPipperX, me.eegsPipperY-radius)
                          .arcSmallCW(radius,radius,0,0,radius*2)
                          .arcSmallCW(radius,radius,0,0,-radius*2)
                          .setStrokeLineWidth(1)
                          .setColor(me.color);
                }
                me.eegsGroup.update();
            } elsif (me.eegsMe.allow and (gunSight == 1 or me.hydra)) {
                # draw STRF
                me.eegsGroup.removeAllChildren();
                if (me.drawSTRFPipper) {
                        me.vari = getprop("sim/variant-id");
                        me.oldStrf = me.vari == 0 or me.vari == 1 or me.vari == 3;
                        var mr = 0.4 * 1.5;
                        if (me.oldStrf) {
                                # draw the old STRF pipper (T.O. GR1F-16CJ-34-1-1 page 1-442 and MLU Tape 1 page 185)
                                var pipperRadius = 15 * mr;
                                if (me.strfRange <= (me.hydra?4000:getprop("f16/avionics/gun-strf-max-range-ft"))) {
                                        me.eegsGroup.createChild("path")
                                                .moveTo(me.eegsPipperX-pipperRadius, me.eegsPipperY-pipperRadius-2)
                                                .horiz(pipperRadius*2)
                                                .moveTo(me.eegsPipperX-pipperRadius, me.eegsPipperY)
                                                .arcSmallCW(pipperRadius, pipperRadius, 0, pipperRadius*2, 0)
                                                .arcSmallCW(pipperRadius, pipperRadius, 0, -pipperRadius*2, 0)
                                                .moveTo(me.eegsPipperX-2*mr,me.eegsPipperY)
                                                .arcSmallCW(2*mr,2*mr, 0, 2*mr*2, 0)
                                                .arcSmallCW(2*mr,2*mr, 0, -2*mr*2, 0)
                                                .setStrokeLineWidth(1)
                                                .setColor(me.color);
                                } else {
                                        me.eegsGroup.createChild("path")
                                                .moveTo(me.eegsPipperX-pipperRadius, me.eegsPipperY)
                                                .arcSmallCW(pipperRadius, pipperRadius, 0, pipperRadius*2, 0)
                                                .arcSmallCW(pipperRadius, pipperRadius, 0, -pipperRadius*2, 0)
                                                .moveTo(me.eegsPipperX-2*mr,me.eegsPipperY)
                                                .arcSmallCW(2*mr,2*mr, 0, 2*mr*2, 0)
                                                .arcSmallCW(2*mr,2*mr, 0, -2*mr*2, 0)
                                                .setStrokeLineWidth(1)
                                                .setColor(me.color);
                                }
                        } else {
                                # draw the new STRF pipper (T.O. GR1F-16CJ-34-1-1(new) page 2-299 and MLU Tape 2 page 79)
                                me.pipperOuterRadius = 25 * mr;
                                me.pipperInnerRadius = 20 * mr;
                                me.pipperRangeTick   =  5 * mr;
                                me.pipperRangeMode = me.strfRange <= getprop("f16/avionics/gun-strf-max-range-ft") and me.strfRange <= 12000?0:(me.strfRange <= 12000?1:(me.strfRange <= getprop("f16/avionics/gun-strf-max-range-ft") and me.strfRange <= 24000?2:(me.strfRange <= 24000?3:4)));
                                
                                if (me.pipperRangeMode < 4) {

                                        if (me.pipperRangeMode < 2) {
                                                me.td_rads = me.interpolate(me.strfRange, 0, 12000, 0, 2*math.pi);
                                        } else {
                                                me.td_rads = me.interpolate(me.strfRange, 12000, 24000, 0, 2*math.pi);
                                        }
                                        me.td_x = me.pipperInnerRadius*math.sin(me.td_rads);
                                        me.td_y = -me.pipperInnerRadius*math.cos(me.td_rads);
                                        me.td_x2 = me.pipperOuterRadius*math.sin(me.td_rads);
                                        me.td_y2 = -me.pipperOuterRadius*math.cos(me.td_rads);

                                        if (getprop("f16/avionics/gun-strf-max-range-ft") <= 12000) {
                                                me.td_rads = me.interpolate(getprop("f16/avionics/gun-strf-max-range-ft"), 0, 12000, 0, 2*math.pi);
                                        } else {
                                                me.td_rads = me.interpolate(getprop("f16/avionics/gun-strf-max-range-ft"), 12000, 24000, 0, 2*math.pi);
                                        }
                                        me.td_x3 = (me.pipperOuterRadius+me.pipperRangeTick)*math.sin(me.td_rads);
                                        me.td_y3 = -(me.pipperOuterRadius+me.pipperRangeTick)*math.cos(me.td_rads);

                                        # Draw inner arc and range tick
                                        if (me.pipperRangeMode == 3) {
                                                # Out of range (between 12000 and 24000 ft)
                                                me.newPipper = me.eegsGroup.createChild("path")
                                                        .moveTo(me.td_x, me.td_y)
                                                        .lineTo(me.td_x2, me.td_y2);
                                        } elsif (me.pipperRangeMode == 2) {
                                                # In range (between 12000 and 24000 ft)
                                                me.newPipper = me.eegsGroup.createChild("path")
                                                        .moveTo(-me.pipperInnerRadius, 0)
                                                        .arcSmallCW(me.pipperInnerRadius, me.pipperInnerRadius, 0, 2*me.pipperInnerRadius, 0)
                                                        .arcSmallCW(me.pipperInnerRadius, me.pipperInnerRadius, 0, -2*me.pipperInnerRadius, 0)
                                                        .moveTo(me.td_x, me.td_y)
                                                        .lineTo(me.td_x2, me.td_y2);
                                        } elsif (me.pipperRangeMode == 1) {
                                                # Out of range (less than 12000 ft)
                                                me.newPipper = me.eegsGroup.createChild("path")
                                                                .moveTo(me.td_x, me.td_y)
                                                                .lineTo(me.td_x2, me.td_y2);
                                        } elsif (me.pipperRangeMode == 0) {
                                                # in range (less than 12000 ft)
                                                if (me.td_x >= 0) {
                                                        me.newPipper = me.eegsGroup.createChild("path")
                                                                .moveTo(0, -me.pipperInnerRadius)
                                                                .arcSmallCW(me.pipperInnerRadius, me.pipperInnerRadius, 0, me.td_x, me.td_y+me.pipperInnerRadius)
                                                                .lineTo(me.td_x2, me.td_y2)
                                                                .moveTo(0, -me.pipperInnerRadius)
                                                                .vert(-me.pipperRangeTick);
                                                } else {
                                                        me.newPipper = me.eegsGroup.createChild("path")
                                                                .moveTo(0, -me.pipperInnerRadius)
                                                                .arcLargeCW(me.pipperInnerRadius, me.pipperInnerRadius, 0, me.td_x, me.td_y+me.pipperInnerRadius)
                                                                .lineTo(me.td_x2, me.td_y2)
                                                                .moveTo(0, -me.pipperInnerRadius)
                                                                .vert(-me.pipperRangeTick);
                                                }
                                        }

                                        # Draw outer arc and outer ticks
                                        me.newPipper
                                                .moveTo(-me.pipperOuterRadius, 0)
                                                .arcSmallCW(me.pipperOuterRadius, me.pipperOuterRadius, 0, 2*me.pipperOuterRadius, 0)
                                                .arcSmallCW(me.pipperOuterRadius, me.pipperOuterRadius, 0, -2*me.pipperOuterRadius, 0)
                                                .moveTo(me.pipperOuterRadius, 0)
                                                .horiz(me.pipperRangeTick)
                                                .moveTo(-me.pipperOuterRadius, 0)
                                                .horiz(-me.pipperRangeTick)
                                                .moveTo(0, me.pipperOuterRadius)
                                                .vert(me.pipperRangeTick)
                                                .moveTo(0, -me.pipperOuterRadius)
                                                .vert(-me.pipperRangeTick);

                                        # Draw center dot
                                        me.newPipper.moveTo(-mr,0);
                                        me.newPipper.arcSmallCW(mr,mr, 0, mr*2, 0);
                                        me.newPipper.arcSmallCW(mr,mr, 0, -mr*2, 0);

                                        # Draw in-range dot
                                        me.newPipper.moveTo(-mr+me.td_x3,me.td_y3);
                                        me.newPipper.arcSmallCW(mr,mr, 0, mr*2, 0);
                                        me.newPipper.arcSmallCW(mr,mr, 0, -mr*2, 0);

                                        # Place the pipper on impact point
                                        me.newPipper.setTranslation(me.eegsPipperX, me.eegsPipperY)
                                                .setStrokeLineWidth(1)
                                                .setColor(me.color)
                                                .update();
                                }
                        }
                }
                me.eegsGroup.update();
            }




            #calc shell positions

            # speed = aircraft groundspeed vector + aircraft attitude vector with shell speed for magnitude
            #

            me.eegs_ac_north_fps = getprop("velocities/speed-north-fps");
            me.eegs_ac_east_fps  = getprop("velocities/speed-east-fps");
            me.eegs_ac_down_fps  = getprop("velocities/speed-down-fps");

            me.eegs_sm_down_fps       = -math.sin(me.eegsMe.pitch_ac * D2R) * (me.hydra?2000:me.gunSpeed);
            me.eegs_sm_horizontal_fps = math.cos(me.eegsMe.pitch_ac * D2R) * (me.hydra?2000:me.gunSpeed);
            me.eegs_sm_north_fps      = math.cos(me.eegsMe.hdg_ac * D2R) * me.eegs_sm_horizontal_fps;
            me.eegs_sm_east_fps       = math.sin(me.eegsMe.hdg_ac * D2R) * me.eegs_sm_horizontal_fps;

            me.eegs_north_fps = me.eegs_ac_north_fps + me.eegs_sm_north_fps;
            me.eegs_east_fps  = me.eegs_ac_east_fps  + me.eegs_sm_east_fps;
            me.eegs_down_fps  = me.eegs_ac_down_fps  + me.eegs_sm_down_fps;

            me.eegs_horiz_fps = math.sqrt(me.eegs_north_fps*me.eegs_north_fps+me.eegs_east_fps*me.eegs_east_fps);
            me.eegs_total_fps = math.sqrt(me.eegs_down_fps*me.eegs_down_fps+me.eegs_horiz_fps*me.eegs_horiz_fps);

            me.eegs_hdging = geo.normdeg(math.atan2(me.eegs_east_fps,me.eegs_north_fps)*R2D);
            me.eegs_ptch   = math.atan2(-me.eegs_down_fps, me.eegs_horiz_fps)*R2D;

            if (me.eegs_total_fps > 1) {
                me.eegsMe.hdg = me.eegs_hdging;
                me.eegsMe.pitch = me.eegs_ptch;
            }

            me.eegsMe.vel = me.eegs_total_fps;

            me.eegsMe.geodPos = aircraftToCart({x:-me.gunLoc[0], y:me.gunLoc[1], z: -me.gunLoc[2]});#position of gun in aircraft (x and z inverted)
            me.eegsMe.eegsPos.set_xyz(me.eegsMe.geodPos.x, me.eegsMe.geodPos.y, me.eegsMe.geodPos.z);
            me.eegsMe.altC = me.eegsMe.eegsPos.alt();

            me.eegsMe.rs = armament.AIM.rho_sndspeed(me.eegsMe.altC*M2FT);#simplified
            me.eegsMe.rho = me.eegsMe.rs[0];
            me.eegsMe.mass =  (me.hydra?23.6:me.gunWeight) * armament.LBM2SLUGS;

            #print("x,y");
            #printf("%d,%d",0,0);
            #print("-----");
            
            var buggedFG = major < 2024;

            var multi = gunSight == 1?3:(me.hydra?2:1);# double the funnel segments for HYDRA (3.4 secs) and triple for STRF (5.1 secs)
            for (var j = 0;j < me.funnelParts*multi;j+=1) {

                if (buggedFG) {
                        # there is a unit bug in FG 2020.3.19 submodels which is applied every frame, which means we gotta compensate:
                        me.eegsMe.vel_kt = me.eegsMe.vel * FPS2KT;

                        #calc new airpressure incorrect (using wrong units like FG do)
                        me.eegsMe.q = 0.5 * me.eegsMe.rho * me.eegsMe.vel_kt * me.eegsMe.vel_kt;
                } else {
                        me.eegsMe.q = 0.5 * me.eegsMe.rho * me.eegsMe.vel * me.eegsMe.vel;
                }
                me.eegsMe.Cd = drag(me.eegsMe.vel/ me.eegsMe.rs[1],me.hydra?0:me.gunCd);
                        
                me.eegsMe.deacc = (me.eegsMe.Cd * me.eegsMe.q * (me.hydra?0.00136354:me.gunEda)) / me.eegsMe.mass;#0.00136354=eda
                
                if (buggedFG) {
                        me.eegsMe.vel -= me.eegsMe.deacc * KT2FPS * me.averageDt;
                } else {
                        me.eegsMe.vel -= me.eegsMe.deacc * me.averageDt;
                }

                me.eegsMe.speed_down_fps       = -math.sin(me.eegsMe.pitch * D2R) * (me.eegsMe.vel);
                me.eegsMe.speed_horizontal_fps = math.cos(me.eegsMe.pitch * D2R) * (me.eegsMe.vel);

                me.eegsMe.speed_down_fps += getprop("environment/gravitational-acceleration-mps2") * M2FT * me.averageDt;



                me.eegsMe.altC -= (me.eegsMe.speed_down_fps*me.averageDt)*FT2M;


                #printf("altC %d   vel_z %d   acc_z=%d",me.eegsMe.altC,me.eegsMe.vel_z,me.eegsMe.acc * averageDt);


                me.eegsMe.dist = (me.eegsMe.speed_horizontal_fps*me.averageDt)*FT2M;

                #printf("vel_x %d  acc_x %d", me.eegsMe.vel_x,me.eegsMe.acc);
                #printf("pitch=%.1f  vel=%d  vdown=%.1f",me.eegsMe.pitch, me.eegsMe.vel, me.eegsMe.speed_down_fps, );
                #me.eegsMe.eegsPos.apply_course_distance(me.eegsMe.hdg, me.eegsMe.dist);
                me.great = greatCircleMove(me.eegsMe.eegsPos, me.eegsMe.hdg, me.eegsMe.dist*M2NM);
                me.eegsMe.eegsPos.set_latlon(me.great.lat, me.great.lon, me.eegsMe.altC);

                var old = me.gunPos[j];
                me.gunPos[j] = [[geo.Coord.new(me.eegsMe.eegsPos),me.eegsMe.ac, me.eegsMe.pitch]];
                for (var m = 0;m<j+1;m+=1) {
                    append(me.gunPos[j], old[m]);
                }

                #print(me.eegsMe.speed_down_fps*me.eegsMe.speed_down_fps+me.eegsMe.speed_horizontal_fps*me.eegsMe.speed_horizontal_fps);
                #print(me.eegsMe.speed_down_fps*me.eegsMe.speed_down_fps);
                #print(me.eegsMe.speed_horizontal_fps*me.eegsMe.speed_horizontal_fps);

                #if (j==0) {
                #    var p = math.atan2(me.eegsMe.altC-me.eegsMe.ac.alt(),me.eegsMe.eegsPos.distance_to(me.eegsMe.ac))*R2D;
                    #printf("next %.2f alt %.2f our-pitch %.2f our-alt %.2f",p-getprop("orientation/pitch-deg"),me.eegsMe.altC,getprop("orientation/pitch-deg"),me.eegsMe.ac.alt());
                #    printf("shot heading %.2f bearing %.2f", me.eegsMe.hdg, me.eegsMe.ac.course_to(me.eegsMe.eegsPos));
                #    printf("dist=%d vel=%d realdist=%d",me.eegsMe.dist,me.eegsMe.vel,me.eegsMe.eegsPos.distance_to(me.eegsMe.ac));
                    #me.eegsMe.eegsPos.dump();
                #}
                me.eegsMe.vel = math.sqrt(me.eegsMe.speed_down_fps*me.eegsMe.speed_down_fps+me.eegsMe.speed_horizontal_fps*me.eegsMe.speed_horizontal_fps);
                me.eegsMe.pitch = math.atan2(-me.eegsMe.speed_down_fps,me.eegsMe.speed_horizontal_fps)*R2D;
            }
        }
        if (gunSight != 1 and !me.hydra and me.designatedDistanceFT != nil) {
            # Draw A-A gun reticle
            me.aaTargetDesignationGrp.removeAllChildren();
            var mr = 0.4 * 1.5;
            var radius = 20 * mr;
            me.td_rads = me.interpolate(me.designatedDistanceFT, 0, 12000, 0, 2*math.pi);
            me.td_x = radius*math.sin(me.td_rads);
            me.td_y = -radius*math.cos(me.td_rads);
            me.td_factor = me.designatedDistanceFT >= 12000?1:0.75;
            me.td_x2 = me.td_factor*radius*math.sin(me.td_rads);
            me.td_y2 = -me.td_factor*radius*math.cos(me.td_rads);
            # The open part of the circle is not segmented as per manuals and YT (1FJF5PD1uqM)
            # More modern MLU (or some export models) do have it segmented though.
            if (me.td_x >= 0) {
                me.aaTargetDesignator = me.aaTargetDesignationGrp.createChild("path")
                    .moveTo(0, -radius)
                    .arcSmallCW(radius, radius, 0, me.td_x, me.td_y+radius)
                    .lineTo(me.td_x2, me.td_y2)
                    .setStrokeLineWidth(1)
                    .setColor(me.color)
                    .update();
            } else {
                me.aaTargetDesignator = me.aaTargetDesignationGrp.createChild("path")
                    .moveTo(0, -radius)
                    .arcLargeCW(radius, radius, 0, me.td_x, me.td_y+radius)
                    .lineTo(me.td_x2, me.td_y2)
                    .setStrokeLineWidth(1)
                    .setColor(me.color)
                    .update();
            }
            # Draw in-range dot
            if (me.designatedDistanceFT > getprop("f16/avionics/gun-aa-max-range-ft")) {
                me.td_rads = me.interpolate(getprop("f16/avionics/gun-aa-max-range-ft"), 0, 12000, 0, 2*math.pi);
                me.td_x3 = (1.20*radius)*math.sin(me.td_rads);
                me.td_y3 = -(1.20*radius)*math.cos(me.td_rads);
                me.aaTargetDesignator.moveTo(-mr+me.td_x3,me.td_y3);
                me.aaTargetDesignator.arcSmallCW(mr,mr, 0, mr*2, 0);
                me.aaTargetDesignator.arcSmallCW(mr,mr, 0, -mr*2, 0);
            }
        }
    },
    interpolateCoords: func (start, end, fraction) {
        me.xx = math.clamp((start.x()*(1-fraction)+end.x()*fraction),math.min(start.x(),end.x()),math.max(start.x(),end.x()));
        me.yy = math.clamp((start.y()*(1-fraction)+end.y()*fraction),math.min(start.y(),end.y()),math.max(start.y(),end.y()));
        me.zz = math.clamp((start.z()*(1-fraction)+end.z()*fraction),math.min(start.z(),end.z()),math.max(start.z(),end.z()));

        me.cc = geo.Coord.new();
        me.cc.set_xyz(me.xx,me.yy,me.zz);
        return me.cc;
    },
    extrapolate: func (x, x1, x2, y1, y2) {
        return y1 + ((x - x1) / (x2 - x1)) * (y2 - y1);
    },
    interpolate: func (x, x1, x2, y1, y2) {
        return math.clamp(me.extrapolate(x, x1, x2, y1, y2),math.min(y1,y2),math.max(y1,y2));
    },
    clamp: func(v, min, max) { v < min ? min : v > max ? max : v },
    list: [],
};

var F16HudRecipient =
{
    new: func(_ident)
    {
        var new_class = emesary.Recipient.new(_ident~".HUD");
        new_class.HUDobj = F16_HUD.new("Nasal/HUD/HUD.svg", "HUDImage2", 340,260, 0,0);

        new_class.Receive = func(notification)
        {
            if (notification == nil)
            {
                print("bad notification nil");
                return emesary.Transmitter.ReceiptStatus_NotProcessed;
            }

            notification.range_rate = "RNGRATE";

            if (notification.NotificationType == "FrameNotification16")
            {

                me.HUDobj.update(notification);
                return emesary.Transmitter.ReceiptStatus_OK;
            }
            return emesary.Transmitter.ReceiptStatus_NotProcessed;
        };
        return new_class;
    },
};
f16_hud = F16HudRecipient.new("F16-HUD");
HUDobj = f16_hud.HUDobj;

#emesary.GlobalTransmitter.Register(f16_hud);

var drag = func (Mach, _cd) {
    if (Mach < 0.7)
        return 0.0125 * Mach + _cd;
    elsif (Mach < 1.2)
        return 0.3742 * math.pow(Mach, 2) - 0.252 * Mach + 0.0021 + _cd;
    else
        return 0.2965 * math.pow(Mach, -1.1506) + _cd;
};

var isDropping = 0;

var dropping = func {
    if (getprop("payload/armament/gravity-dropping")) {
        isDropping = 1;
    } else {
        settimer(func {isDropping = 0;}, 1.0);
    }
}

setlistener("payload/armament/gravity-dropping",func{dropping()},nil,0);
