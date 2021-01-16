# Canvas HUD
# ---------------------------
# HUD uses data in the frame notification
# HUD is in two parts so we have a single class that we can instantiate
# twice on for each combiner pane
# ---------------------------
# Richard Harrison (rjh@zaretto.com) 2016-07-01  - based on F-15 HUD
# ---------------------------

var ht_debug = 0;

var pitch_offset = 12;
var pitch_factor = 14.85;#19.8;
var pitch_factor_2 = pitch_factor * 180.0 / math.pi;
var alt_range_factor = (9317-191) / 100000; # alt tape size and max value.
var ias_range_factor = (694-191) / 1100;

var F16_HUD = {
    new : func (svgname, canvas_item, sx, sy, tran_x,tran_y){
        var obj = {parents : [F16_HUD] };

        obj.canvas= canvas.new({
                "name": "F16 HUD",
                    "size": [1024,1024], 
                    "view": [sx,sy],#340,260
                    "mipmapping": 0, # mipmapping will make the HUD text blurry on smaller screens     
                    "additive-blend": 1# bool
                    });  

        obj.sy = sy;                        
        obj.sx = sx*0.695633;
        
        # Real HUD:
        #
        # F16C: Optics provides a 25degree Total Field of View and a 20o by 13.5o Instantaneous Field of View
        #
        # F16A: Total Field of View of the F-16 A/B PDU is 20deg but the Instantaneous FoV is only 9deg in elevation and 13.38deg in azimuth
        
        
        HudMath.init([-4.53759+0.013,-0.07814,0.85796+0.010], [-4.7148+0.013,0.07924,0.66213+0.010], [sx,sy], [0,1.0], [0.695633,0.0], 0);
                          
        obj.canvas.addPlacement({"node": canvas_item});
        obj.canvas.setColorBackground(0.30, 1, 0.3, 0.00);

# Create a group for the parsed elements
        obj.svg = obj.canvas.createGroup().hide();
        obj.main_mask = obj.canvas.createGroup().set("z-index",20000);
 
# Parse an SVG file and add the parsed elements to the given group
        #print("HUD Parse SVG ",
            canvas.parsesvg(obj.svg, svgname);
            #);

        obj.canvas._node.setValues({
                "name": "F16 HUD",
                    "size": [1024,1024], 
                    "view": [sx,sy],
                    "mipmapping": 0,
                    "additive-blend": 1# bool
                    });

        obj.svg.setTranslation (tran_x,tran_y);

        obj.ladder = obj.get_element("ladder");

        var cent = obj.ladder.getCenter();
        obj.ladder_center = cent;

        obj.VV = obj.get_element("VelocityVector");

        obj.heading_tape = obj.get_element("heading-scale");
        obj.heading_tape_pointer = obj.get_element("path3419");

        obj.roll_pointer = obj.get_element("roll-pointer");
        obj.roll_lines = obj.get_element("g3415");

        obj.alt_range = obj.get_element("alt_range");
        obj.ias_range = obj.get_element("ias_range");
        obj.oldBore = obj.get_element("path4530-6");
        obj.target_locked = obj.get_element("target_locked");
        obj.target_locked.setVisible(0);
        obj.alt_line = obj.get_element("alt_tick_vert_line");
        obj.alt_line.hide();
        obj.vel_line = obj.get_element("ias_tick_vert_line");
        obj.vel_line.hide();
        obj.vel_ind = obj.get_element("path3111");
        obj.vel_ind.hide();
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


        HUD_FONT = "LiberationFonts/LiberationMono-Bold.ttf";#"condensed.txf";  with condensed the FLYUP text was not displayed until minutes into flight, no clue why
        obj.window1 = obj.get_text("window1", HUD_FONT,9,1.1);
        obj.window2 = obj.get_text("window2", HUD_FONT,9,1.1);
        obj.window3 = obj.get_text("window3", HUD_FONT,9,1.1);
        obj.window4 = obj.get_text("window4", HUD_FONT,9,1.1);
        obj.window5 = obj.get_text("window5", HUD_FONT,9,1.1);
        obj.window6 = obj.get_text("window6", HUD_FONT,9,1.1);
        obj.window7 = obj.get_text("window7", HUD_FONT,9,1.1);
        obj.window8 = obj.get_text("window8", HUD_FONT,9,1.1);
        obj.window9 = obj.get_text("window9", HUD_FONT,9,1.1);
        obj.window10 = obj.get_text("window10", HUD_FONT,9,1.1);
        obj.window11 = obj.get_text("window11", HUD_FONT,9,1.1);
        obj.window12 = obj.svg.createChild("text")
                .setText("1.0")
                .setTranslation(45,20)
                .setAlignment("right-bottom-baseline")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(9, 1.1);

        obj.ralt = obj.get_text("radalt", HUD_FONT,9,1.1);
        obj.ralt.setAlignment("right-bottom-baseline");
        obj.ralt.setTranslation(35,0);
        
        
        #obj.alt_range.set("clip", "rect(75px, 10000px, 10000px, -10000px)"); # top,right,bottom,left
        #obj.ias_range.set("clip", "rect(125px, 10000px, 10000px, -10000px)"); # top,right,bottom,left
        
        #append(obj.total, obj.ladder);
        append(obj.total, obj.heading_tape);
        #append(obj.total, obj.VV);
        append(obj.total, obj.heading_tape_pointer);
        append(obj.total, obj.roll_pointer);
        append(obj.total, obj.roll_lines);
        append(obj.total, obj.alt_range);
        append(obj.total, obj.ias_range);
        #append(obj.total, obj.target_locked);
        append(obj.total, obj.alt_line);
        append(obj.total, obj.vel_ind);
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

        #obj.VV.set("z-index", 11000);# hmm, its inside layer1, so will still be below the heading readout.
        obj.layer1 = obj.get_element("layer1");#main svg layer.

        
# A 2D 3x2 matrix with six parameters a, b, c, d, e and f is equivalent to the matrix:
# a  c  0 e 
# b  d  0 f
# 0  0  1 0 

#
#
# Load the target symbosl.
        obj.max_symbols = 10;
        obj.tgt_symbols =  setsize([],obj.max_symbols);

        for (var i = 0; i < obj.max_symbols; i += 1)
        {
            var name = "target_"~i;
            var tgt = obj.svg.getElementById(name);
            if (tgt != nil)
            {
                obj.tgt_symbols[i] = tgt;
                tgt.updateCenter();
                tgt.setVisible(0);
                append(obj.total, tgt);
#                print("HUD: loaded ",name);
            }
            else
                print("HUD: could not locate ",name);
        }
        obj.custom = obj.canvas.createGroup();
        obj.flyup = obj.svg.createChild("text")
                .setText("FLYUP")
                .setTranslation(sx*0.5*0.695633,sy*0.30)
                .setAlignment("center-center")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(13, 1.4);
        append(obj.total, obj.flyup);
        obj.stby = obj.svg.createChild("text")
                .setText("NO RAD")
                .setTranslation(sx*0.5*0.695633,sy*0.15)                
                .setAlignment("center-top")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(11, 1.1);

          append(obj.total, obj.stby);
#        obj.raltR = obj.svg.createChild("text")
#                .setText("R")
#                .setTranslation(sx*1*0.675633-5,sy*0.45)
#                .setAlignment("right-center")
#                .setColor(0,1,0)
#                .setFont(HUD_FONT)
#                .setFontSize(9, 1.1);
#        obj.raltFrame = obj.svg.createChild("path")
#                .moveTo(sx*1*0.695633-9,sy*0.45+5)
#                .horiz(-41)
#                .vert(-10)
#                .horiz(41)
#                .vert(10)
#                .setStrokeLineWidth(1)
#                .hide()
#                .setColor(0,1,0);
#              append(obj.total, obj.raltFrame);
        obj.boreSymbol = obj.svg.createChild("path")
                .moveTo(-5,0)
                .horiz(10)
                .moveTo(0,-5)
                .vert(10)
                .setStrokeLineWidth(1)
                .setColor(0,1,0);
            append(obj.total, obj.boreSymbol);
            
            
        obj.speed_indicator = obj.svg.createChild("path")
                .moveTo(0.25*sx*0.695633,sy*0.245)
                .horiz(7)
                .setStrokeLineWidth(1)
                .setColor(1,0,0);
        obj.alti_indicator = obj.svg.createChild("path")
                .moveTo(0.75*sx*0.695633,sy*0.245)
                .horiz(-7)
                .setStrokeLineWidth(1)
                .setColor(1,0,0);
        append(obj.scaling, obj.alti_indicator);
        append(obj.scaling, obj.speed_indicator);
        append(obj.total, obj.alti_indicator);
        append(obj.total, obj.speed_indicator);
        obj.speed_type = obj.svg.createChild("text")
                .setText("C")
                .setTranslation(1+0.25*sx*0.695633,sy*0.24)
                .setAlignment("left-bottom")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(9, 1.1);
        obj.soi_indicator = obj.svg.createChild("text") # SOI indicator on HUD upper left
                .setText("*")
                .setTranslation(1+0.25*sx*0.60,sy*0.14)
                .setAlignment("left-bottom")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(11, 1.1);
        append(obj.total, obj.soi_indicator);
        obj.alt_type = obj.svg.createChild("text")
                .setText("R")
                .setTranslation(-1+0.75*sx*0.695633,sy*0.24)
                .setAlignment("right-bottom")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(9, 1.1);
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
        obj.speed_mask = obj.svg.createChild("image")
                .setTranslation(-27+0.21*sx*0.695633,sy*0.245-6)
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
                .moveTo(2+0.20*sx*0.695633,sy*0.245)
                .lineTo(2+0.20*sx*0.695633-5,sy*0.245-6)
                .horiz(-25)
                .vert(12)
                .horiz(25)
                .lineTo(2+0.20*sx*0.695633,sy*0.245)
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
                .setTranslation(0.18*sx*0.695633,sy*0.245)
                .setAlignment("right-center")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(9, 1.1);
append(obj.total, obj.speed_curr);
        obj.alt_mask = obj.svg.createChild("image")
                .setTranslation(5+3+0.79*sx*0.695633-10,sy*0.245-6)
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
                .moveTo(8-2+0.80*sx*0.695633-10,sy*0.245)
                .lineTo(8-2+0.80*sx*0.695633+5-10,sy*0.245-6)
                .horiz(28)
                .vert(12)
                .horiz(-28)
                .lineTo(8-2+0.80*sx*0.695633-10,sy*0.245)
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
                .setTranslation(4+0.82*sx*0.695633-10,sy*0.245+3.5)
                .setAlignment("left-bottom-baseline")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(9, 1.1);
                append(obj.total, obj.alt_curr);
        obj.head_mask = obj.svg.createChild("image")
                .setTranslation(-10+0.5*sx*0.695633,sy*0.1-20)
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
                .moveTo(10+0.50*sx*0.695633,sy*0.1-10)
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
                .setTranslation(0.5*sx*0.695633,sy*0.1-12)
                .setAlignment("center-bottom")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(9, 1.1);
                append(obj.total, obj.head_curr);
        obj.ded0 = obj.svg.createChild("text")
                .setText("")
                .setTranslation(0.25*sx*0.695633,sy*0.75-20)
                .setAlignment("left-center")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(9, 1.1);
                append(obj.total, obj.ded0);
        obj.ded1 = obj.svg.createChild("text")
                .setText("")
                .setTranslation(0.25*sx*0.695633,sy*0.75-10)
                .setAlignment("left-center")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(9, 1.1);
                append(obj.total, obj.ded1);
        obj.ded2 = obj.svg.createChild("text")
                .setText("")
                .setTranslation(0.25*sx*0.695633,sy*0.75+0)
                .setAlignment("left-center")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(9, 1.1);
                append(obj.total, obj.ded2);
        obj.ded3 = obj.svg.createChild("text")
                .setText("")
                .setTranslation(0.25*sx*0.695633,sy*0.75+10)
                .setAlignment("left-center")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(9, 1.1);
                append(obj.total, obj.ded3);
        obj.ded4 = obj.svg.createChild("text")
                .setText("")
                .setTranslation(0.25*sx*0.695633,sy*0.75+20)
                .setAlignment("left-center")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(9, 1.1);
                append(obj.total, obj.ded4);
        obj.bombFallLine = obj.svg.createChild("path")
                .moveTo(sx*0.5*0.695633,0)
                #.horiz(10)
                .vert(400)
                .setStrokeLineWidth(1)
                .setColor(0,1,0).hide();
                append(obj.total, obj.bombFallLine);
        obj.solutionCue = obj.svg.createChild("path")#the moving line
                .moveTo(sx*0.5*0.695633-5,0)
                .horiz(10)
                .setStrokeLineWidth(2)
                .set("z-index",10005)
                .setColor(0,1,0);
                append(obj.total, obj.solutionCue);
        obj.ccrpMarker = obj.svg.createChild("path")
                .moveTo(sx*0.5*0.695633-10,sy*0.5)
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
            .setTranslation(sx*0.5*0.695633,sy*0.25+262*mr*0.5);
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
            .setTranslation(sx*0.5*0.695633,sy*0.25);
            append(obj.total, obj.ASEC100);
        obj.ASEC120 = obj.svg.createChild("path")#rdlock
            .moveTo(-120*mr,0)
            .arcSmallCW(120*mr,120*mr, 0, 120*mr*2, 0)
            .arcSmallCW(120*mr,120*mr, 0, -120*mr*2, 0)
            .setStrokeLineWidth(1)
            .setColor(0,1,0).hide()
            .setTranslation(sx*0.5*0.695633,sy*0.25);
            append(obj.total, obj.ASEC120);
        obj.ASEC65 = obj.svg.createChild("path")#irlock
            .moveTo(-65*mr,0)
            .arcSmallCW(65*mr,65*mr, 0, 65*mr*2, 0)
            .arcSmallCW(65*mr,65*mr, 0, -65*mr*2, 0)
            .setStrokeLineWidth(1)
            .setColor(0,1,0).hide()
            .setTranslation(sx*0.5*0.695633,sy*0.25);
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
            .setTranslation(sx*0.5*0.695633,sy*0.25);
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
            .setTranslation(sx*0.5*0.695633,sy*0.25);
            append(obj.total, obj.ASEC120Aspect);
        
        obj.VV.hide();
        mr = mr*1.5;#incorrect, but else in FG it will seem too small.

        obj.initUpdate =1;
        
        obj.alpha = getprop("f16/avionics/hud-sym");
        obj.power = getprop("f16/avionics/hud-power");

        obj.orangePeelGroup = obj.svg.createChild("group")
                                     .setTranslation(sx*0.695633*0.5, sy*0.245);
        append(obj.total, obj.orangePeelGroup);

        obj.dlzX      = sx*0.695633*0.75-16;
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

        obj.svg.setColor(0.3,1,0.3);
        
        ############################## new center origin stuff that used hud math #################
        
        
        obj.centerOrigin = obj.canvas.createGroup()
                           .setTranslation(HudMath.getCenterOrigin());
        
        obj.flyupLeft    = obj.centerOrigin.createChild("path")
                            .lineTo(-50,-50)
                            .moveTo(0,0)
                            .lineTo(-50,50)
                            .setStrokeLineWidth(1)
                            .setColor(0,1,0);
        obj.flyupRight  = obj.centerOrigin.createChild("path")
                            .lineTo(50,-50)
                            .moveTo(0,0)
                            .lineTo(50,50)
                            .setStrokeLineWidth(1)
                            .setColor(0,1,0);
        append(obj.total, obj.flyupRight);
        append(obj.total, obj.flyupLeft);
        
                            
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
        obj.irLock = obj.centerOrigin.createChild("path")
            .moveTo(-boxRadius,0)
            .lineTo(0,-boxRadius)
            .lineTo(boxRadius,0)
            .lineTo(0,boxRadius)
            .lineTo(-boxRadius,0)
            .setStrokeLineWidth(1)
            .setColor(0,1,0);
        append(obj.total, obj.irLock);
        obj.irSearch = obj.centerOrigin.createChild("path")
            .moveTo(-boxRadiusHalf,0)
            .lineTo(0,-boxRadiusHalf)
            .lineTo(boxRadiusHalf,0)
            .lineTo(0,boxRadiusHalf)
            .lineTo(-boxRadiusHalf,0)
            .setStrokeLineWidth(1)
            .setColor(0,1,0);
        append(obj.total, obj.irSearch);
        obj.irBore = obj.centerOrigin.createChild("path")
            .moveTo(-boxRadiusHalf*4,0)
            .horiz(boxRadius*4)
            .moveTo(0,-boxRadiusHalf*6)
            .vert(boxRadius*6)
            .setStrokeLineWidth(1)
            .setColor(0,1,0);
        append(obj.total, obj.irBore);
        obj.target_locked.hide();
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
        obj.locatorAngle = obj.svg.createChild("text")
                .setText("0")
                .setAlignment("right-center")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(9, 1.1);
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
                .setFontSize(11, 1.4);
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
            #.setTranslation(sx*0.5*0.695633,sy*0.25);
            append(obj.total, obj.VV);
        obj.localizer = obj.centerOrigin.createChild("group");
        
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
        var pixelPerDegreeY = HudMath.getPixelPerDegreeAvg(5.0);#15.43724802231049;
        var pixelPerDegreeX = 16.70527172464148;
        var distance = pixelPerDegreeY * 5;
        var minuss = 0.125*sx*0.695633;
        var minuso = 20*mr;
        for(var i = 1; i <= 17; i += 1) # full drawn lines
          append(obj.total, obj.ladder_group.createChild("path")
             .moveTo(minuso, -i * distance)
             .horiz(minuss)
             .vert(minuso*0.5)

             .moveTo(-minuso, -i * distance)
             .horiz(-minuss)
             .vert(minuso*0.5)
             
             .setStrokeLineWidth(1)
             .setColor(0,0,0));
        
        for(var i = -17; i <= -1; i += 1) { # stipled lines
          #var rad = me.extrapolate(-i*5,10,90,8,45)*D2R;#as per US manual pitch lines bend down from 8 to 45 degrees
          append(obj.total, obj.ladder_group.createChild("path")
                         .moveTo(minuso, -i * distance)
                         .horiz(minuss*0.2)
                         .moveTo(minuso+minuss*0.4, -i * distance)
                         .horiz(minuss*0.2)
                         .moveTo(minuso+minuss*0.8, -i * distance)
                         .horiz(minuss*0.2)
                         .vert(-minuso*0.5)

                         .moveTo(-minuso, -i * distance)
                         .horiz(-minuss*0.2)
                         .moveTo(-minuso-minuss*0.4, -i * distance)
                         .horiz(-minuss*0.2)
                         .moveTo(-minuso-minuss*0.8, -i * distance)
                         .horiz(-minuss*0.2)
                         .vert(-minuso*0.5)

                         .setStrokeLineWidth(1)
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
             .setFontSize(9,1.1)
             .setFont(HUD_FONT)
             .setAlignment("right-center")
             .setTranslation(-minuso-minuss-minuss*0.2, -i * distance)
             .setColor(0,0,0));
          append(obj.total, obj.ladder_group.createChild("text")
             .setText(i*-5)
             .setFontSize(9,1.1)
             .setFont(HUD_FONT)
             .setAlignment("left-center")
             .setTranslation(minuso+minuss+minuss*0.2, -i * distance)
             .setColor(0,0,0));
        }
        for(var i = 1; i <= 17; i += 1) {
          if (i==0) continue;
          append(obj.total, obj.ladder_group.createChild("text")
             .setText(i*5)
             .setFontSize(9,1.1)
             .setFont(HUD_FONT)
             .setAlignment("right-center")
             .setTranslation(-minuso-minuss-minuss*0.2, -i * distance)
             .setColor(0,0,0));
          append(obj.total, obj.ladder_group.createChild("text")
             .setText(i*5)
             .setFontSize(9,1.1)
             .setFont(HUD_FONT)
             .setAlignment("left-center")
             .setTranslation(minuso+minuss+minuss*0.2, -i * distance)
             .setColor(0,0,0));
        }

        # approach line
        var i = -0.5;
        obj.appLine = obj.ladder_group.createChild("path")
                         .moveTo(minuso, -i * distance)
                         .horiz(minuss*0.2)
                         .moveTo(minuso+minuss*0.4, -i * distance)
                         .horiz(minuss*0.2)
                         .moveTo(minuso+minuss*0.8, -i * distance)
                         .horiz(minuss*0.2)

                         .moveTo(-minuso, -i * distance)
                         .horiz(-minuss*0.2)
                         .moveTo(-minuso-minuss*0.4, -i * distance)
                         .horiz(-minuss*0.2)
                         .moveTo(-minuso-minuss*0.8, -i * distance)
                         .horiz(-minuss*0.2)

                         .setStrokeLineWidth(1)
                         .setColor(0,0,0);
        
        append(obj.total, obj.appLine);

        #Horizon line
        append(obj.total, obj.ladder_group.createChild("path")
                         .moveTo(-0.50*sx*0.695633, 0)
                         .horiz(0.50*sx*0.695633-20*mr)
                         .moveTo(20*mr, 0)
                         .horiz(0.50*sx*0.695633-20*mr)
                         .setStrokeLineWidth(1)
                         .setColor(0,0,0));
        
        
        obj.thermometerScaleGrp = obj.svg.createChild("group");
        obj.thermoGroup = obj.thermometerScaleGrp.createChild("group");
        obj.thermoXstart = 0.80*sx*0.695633;
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
        
        input = {
                 IAS                       : "/velocities/airspeed-kt",
                 calibrated                : "/fdm/jsbsim/velocities/vc-kts",
                 TAS                       : "/fdm/jsbsim/velocities/vtrue-kts",
                 GND_SPD                   : "/velocities/groundspeed-kt",
                 HUD_VEL                   : "/f16/avionics/hud-velocity",
                 HUD_SCA                   : "/f16/avionics/hud-scales",
                 Nz                        : "/accelerations/pilot-gdamped",
                 nReset                    : "f16/avionics/n-reset",
                 alpha                     : "/fdm/jsbsim/aero/alpha-deg",
                 altitude_ft               : "/position/altitude-ft",
                 beta                      : "/orientation/side-slip-deg",
                 brake_parking             : "/controls/gear/brake-parking",
                 eta_s                     : "/autopilot/route-manager/wp/eta-seconds",
                 flap_pos_deg              : "/fdm/jsbsim/fcs/flap-pos-deg",
                 gear_down                 : "/controls/gear/gear-down",
                 heading                   : "/orientation/heading-deg",
                 headingMag                : "/orientation/heading-magnetic-deg",
                 useMag:                     "/instrumentation/heading-indicator/use-mag-in-hud",
                 mach                      : "/instrumentation/airspeed-indicator/indicated-mach",
                 measured_altitude         : "/instrumentation/altimeter/indicated-altitude-ft",
                 pitch                     : "/orientation/pitch-deg",
                 nav_range                 : "/autopilot/route-manager/wp/dist",
                 roll                      : "/orientation/roll-deg",
                 route_manager_active      : "/autopilot/route-manager/active",
                 route_manager_power       : "f16/avionics/power-mmc",
                 speed                     : "/fdm/jsbsim/velocities/vt-fps",
                 symbol_reject             : "/controls/HUD/sym-rej",
                 target_display            : "/sim/model/f16/instrumentation/radar-awg-9/hud/target-display",
                 wow                       : "/fdm/jsbsim/gear/wow",
                 wow0                      : "/fdm/jsbsim/gear/unit[0]/WOW",
                 current_view_x_offset_m   : "sim/current-view/x-offset-m",
                 current_view_y_offset_m   : "sim/current-view/y-offset-m",
                 current_view_z_offset_m   : "sim/current-view/z-offset-m",
                 master_arm                : "controls/armament/master-arm",
                 groundspeed_kt            : "velocities/groundspeed-kt",
                 density_altitude          : "fdm/jsbsim/atmosphere/density-altitude",
                 speed_down_fps            : "velocities/speed-down-fps",
                 speed_east_fps            : "velocities/speed-east-fps",
                 speed_north_fps           : "velocities/speed-north-fps",
                 hud_brightness            : "f16/avionics/hud-sym",
                 hud_power                 : "f16/avionics/hud-power",
                 hud_display               : "controls/HUD/display-on",
                 hud_serviceable           : "instrumentation/hud/serviceable",
                 time_until_crash          : "instrumentation/radar/time-till-crash",
                 vne                       : "f16/vne",
                 texUp                     : "f16/hud/texels-up",
                 wp_bearing_deg            : "autopilot/route-manager/wp/true-bearing-deg",
                 bingo                     : "f16/avionics/bingo",
                 alow                      : "f16/settings/cara-alow",
                 altitude_agl_ft           : "position/altitude-agl-ft",
                 wp0_eta                   : "autopilot/route-manager/wp[0]/eta",
                 approach_speed            : "fdm/jsbsim/systems/approach-speed",
                 standby                   : "instrumentation/radar/radar-standby",
                 elapsed                   : "sim/time/elapsed-sec",
                 cara                      : "f16/avionics/cara-on",
                 altSwitch                 : "f16/avionics/hud-alt",
                 drift                     : "f16/avionics/hud-drift",
                 fpm                       : "f16/avionics/hud-fpm",
                 ded                       : "f16/avionics/hud-ded",
                 dgft                      : "f16/avionics/dgft",
                 tgp_mounted               : "f16/stores/tgp-mounted",
                 view_number               : "sim/current-view/view-number",
                 rotary                    : "sim/model/f16/controls/navigation/instrument-mode-panel/mode/rotary-switch-knob",
                 hasGS                     : "instrumentation/nav[0]/has-gs",
                 GSinRange                 : "instrumentation/nav[0]/gs-in-range",
                 GSDeg                     : "instrumentation/nav[0]/gs-needle-deflection-norm",
                 ILSDeg                    : "instrumentation/nav[0]/heading-needle-deflection",
                 ILSinRange                : "instrumentation/nav[0]/in-range",
                 GSdist                    : "instrumentation/nav[0]/gs-distance",
                 #cross                     : "instrumentation/nav[0]/crosstrack-heading-error-deg",
                 #cross                     : "instrumentation/nav[0]/heading-deg",
                 cross                     : "instrumentation/nav[0]/radials/target-auto-hdg-deg",
                 ins_knob                  : "f16/avionics/ins-knob",
                 servAtt                   : "instrumentation/attitude-indicator/serviceable",
                 servHead                  : "instrumentation/heading-indicator/serviceable",
                 servTurn                  : "instrumentation/turn-indicator/serviceable",
                 servSpeed                 : "instrumentation/airspeed-indicator/serviceable",
                 servStatic                : "systems/static/serviceable",
                 servPitot                 : "systems/pitot/serviceable",
                 warn                      : "f16/avionics/fault-warning",
                 strf                      : "f16/avionics/strf",
                };

        foreach (var name; keys(input)) {
            emesary.GlobalTransmitter.NotifyAll(notifications.FrameNotificationAddProperty.new("HUD", name, input[name]));
        }

        #
        # set the update list - using the update manager to improve the performance
        # of the HUD update - without this there was a drop of 20fps (when running at 60fps)
        obj.update_items = [
            props.UpdateManager.FromHashList(["hud_serviceable", "hud_display", "hud_brightness", "hud_power"], 0.1, func(hdp)#changed to 0.1, this function is VERY heavy to run.
                                      {
# print("HUD hud_serviceable=", hdp.hud_serviceable," display=", hdp.hud_display, " brt=", hdp.hud_brightness, " power=", hdp.hud_power);

                                          if (!hdp.hud_display or !hdp.hud_serviceable) {
                                            obj.color = [0.3,1,0.3,0];
                                            foreach(item;obj.total) {
                                              item.setColor(obj.color);
                                            }
                                            obj.ASEC120Aspect.setColorFill(obj.color);
                                            obj.ASEC65Aspect.setColorFill(obj.color);
                                          } elsif (hdp.hud_brightness != nil and hdp.hud_power != nil) {
                                            obj.color = [0.3,1,0.3,hdp.hud_brightness * hdp.hud_power];
                                            foreach(item;obj.total) {
                                              item.setColor(obj.color);
                                            }
                                            obj.ASEC120Aspect.setColorFill(obj.color);
                                            obj.ASEC65Aspect.setColorFill(obj.color);
                                          }
                                      }),
            props.UpdateManager.FromHashList([], 0.01, func(hdp)
                                      {
                                      }),
            props.UpdateManager.FromHashList(["master_arm", "altitude_ft", "roll", "groundspeed_kt", "density_altitude", "mach", "speed_down_fps", "speed_east_fps", "speed_north_fps"], 0.01, func(hdp)
                                      {
                                          if (hdp.fcs_available) {
                                            if (pylons.fcs.getDropMode() == 1) {
                                                hdp.CCIP_active = 1;
                                            } else {
                                                hdp.CCIP_active = 0;
                                            }
                                          } else {
                                              hdp.CCIP_active = 0;
                                          }
                                          hdp.CCRP_active = obj.CCRP(hdp);
                                          var lw = obj.CCIP(hdp);
                                          if (lw==-1) {
                                            obj.cciplow.setTranslation(hdp.VV_x+15,hdp.VV_y);
                                            obj.cciplow.show();
                                          } else {
                                            obj.cciplow.hide();
                                          }
                                      }),
            props.UpdateManager.FromHashList(["texUp","route_manager_active", "route_manager_power", "wp_bearing_deg", "heading","VV_x","VV_y", "dgft"], 0.01, func(hdp)
                                             {
                                                 # the Y position is still not accurate due to HUD being at an angle, but will have to do.
                                                 if (hdp.route_manager_active and hdp.route_manager_power and !hdp.dgft) {
                                                     obj.wpbear = hdp.wp_bearing_deg;
                                                     if (obj.wpbear!=nil) {
                                
                                                         obj.wpbear=geo.normdeg180(obj.wpbear-hdp.heading);
                                                         obj.tadpoleX = HudMath.getCenterPosFromDegs(obj.wpbear,0)[0];

                                                         if (obj.tadpoleX>obj.sx*0.20) {
                                                             obj.tadpoleX=obj.sx*0.20;
                                                         } elsif (obj.tadpoleX<-obj.sx*0.20) {
                                                             obj.tadpoleX=-obj.sx*0.20;
                                                         }
                                                         obj.greatCircleSteeringCue.setTranslation(obj.tadpoleX, hdp.VV_y);
                                                         obj.greatCircleSteeringCue.setRotation(obj.wpbear*D2R);
                                                         obj.greatCircleSteeringCue.show();
                                                     } else {
                                                         obj.greatCircleSteeringCue.hide();
                                                     }
                                                 } else {
                                                     obj.greatCircleSteeringCue.hide();
                                                 }
                                             }
                                            ),

            props.UpdateManager.FromHashList(["texUp","gear_down"], 0.01, func(val)
                                             {
                                                 if (val.gear_down) {
                                                     obj.boreSymbol.hide();
                                                 } else {
                                                     obj.boreSymbol.setTranslation(obj.sx/2,obj.sy-obj.texels_up_into_hud);
                                                     #obj.eegsGroup.setTranslation(obj.sx/2,obj.sy-obj.texels_up_into_hud);
                                                     #printf("bore %d,%d",obj.sx/2,obj.sy-obj.texels_up_into_hud);
                                                     obj.locatorAngle.setTranslation(obj.sx/2-10,obj.sy-obj.texels_up_into_hud);
                                                     obj.boreSymbol.show();
                                                 }
                                                 obj.oldBore.hide();
                                      }),
            props.UpdateManager.FromHashList(["gear_down"], 0.5, func(val)
                                             {
                                                 if (val.gear_down) {
                                                     obj.appLine.show();
                                                 } else {
                                                     obj.appLine.hide();
                                                 }
                                      }),
            props.UpdateManager.FromHashList(["texUp","VV_x","VV_y","fpm"], 0.001, func(hdp)
                                      {
                                        if (hdp.fpm > 0 and (!obj.showmeCCIP or !isDropping or math.mod(int(8*(systime()-int(systime()))),2)>0)) {
                                            #obj.VV.setTranslation (obj.sx*0.5+hdp.VV_x * obj.texelPerDegreeX, obj.sy-obj.texels_up_into_hud+hdp.VV_y * obj.texelPerDegreeY);
                                            obj.VV.setTranslation (hdp.VV_x, hdp.VV_y);
                                            obj.VV.show();
                                            obj.VV.update();
                                        } else {
                                            obj.VV.hide();
                                        }
                                        obj.localizer.setTranslation (hdp.VV_x, hdp.VV_y);
                                      }),
            props.UpdateManager.FromHashList(["rotary","hasGS","GSDeg","GSinRange","ILSDeg", "ILSinRange", "GSdist", "DGFT"], 0.01, func(hdp)
                                      {
                                        if (hdp.rotary == 0 or hdp.rotary == 3 or hdp.rotary == 5) {
                                            #printf("ILSinRange %d GSdist %d", hdp.ILSinRange, hdp.GSdist == nil);
                                            if (hdp.ILSinRange) {
                                                #printf("ILS %d", hdp.ILSDeg);
                                                obj.ilsGroup.setTranslation(4*obj.clamp(hdp.ILSDeg,-5,5),0);
                                                if (math.abs(hdp.ILSDeg)>5) {
                                                    obj.ils.hide();
                                                    obj.ilsOff.show();
                                                } else {
                                                    obj.ils.show();
                                                    obj.ilsOff.hide();
                                                }
                                                
                                                if (hdp.hasGS and hdp.GSinRange) {
                                                    obj.gsGroup.setTranslation(0,-20*hdp.GSDeg);
                                                    #printf("GS %d", hdp.GSDeg*10);
                                                    if (math.abs(hdp.GSDeg)>0.99) {
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
                                                    #obj.inv_v.setTranslation(obj.sx*0.5+5.4*hdp.cross, 20+obj.heading_tape_positionY);
                                                    obj.heading_tape_pointer.setTranslation (5.4*obj.clamp(geo.normdeg180(hdp.cross-hdp.heading),-10,10), obj.heading_tape_positionY);
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
                                      }),
            props.UpdateManager.FromHashList(["fpm","texUp","gear_down","VV_x","VV_y", "wow", "ded", "dgft"], 0.01, func(hdp)
                                      {
                                        if (hdp.gear_down and !hdp.wow) {
                                          obj.bracket.setTranslation (hdp.VV_x, HudMath.getCenterPosFromDegs(0,-11)[1]);
                                          #obj.bracket.setTranslation (obj.sx/2+hdp.VV_x * obj.texelPerDegreeX, obj.sy-obj.texels_up_into_hud+13 * obj.texelPerDegreeY);
                                          obj.bracket.show();
                                          obj.roll_lines.hide();
                                          obj.roll_pointer.hide();
                                        } else {
                                          obj.bracket.hide();
                                          if (hdp.fpm==2 and hdp.ded == 0 and !hdp.dgft) {
                                              obj.roll_lines.show();
                                              obj.roll_pointer.show();
                                          } else {
                                              obj.roll_lines.hide();
                                              obj.roll_pointer.hide();
                                          }
                                        }
                                      }),
            props.UpdateManager.FromHashList(["texUp","pitch","roll","fpm","VV_x","VV_y","gear_down", "dgft", "drift"], 0.001, func(hdp)
                                      {
                                          obj.ladder.hide();
                                          if (hdp.servTurn) {
                                            obj.roll_pointer.setRotation (hdp.roll_rad);
                                          }
                                          if ((hdp.fpm != 2 and !hdp.gear_down) or hdp.dgft) {
                                            obj.ladder_group.hide();
                                            return;
                                          }
                                            #obj.ladder.setTranslation (0.0, hdp.pitch * pitch_factor+pitch_offset);                                           
                                            #obj.ladder.setCenter (obj.ladder_center[0], obj.ladder_center[1] - hdp.pitch * pitch_factor);
                                            #obj.ladder.setRotation (hdp.roll_rad);
                                            
                                            #obj.ladder.show();
                                        
                                        var result = HudMath.getDynamicHorizon(5,0.5,0.5,0.7,0.5,hdp.drift < 2,-0.25);
                                        if (hdp.servTurn) {
                                            obj.h_rot.setRotation(result[1]);
                                            obj.zenith.setRotation(-result[1]);
                                            obj.nadir.setRotation(-result[1]);
                                        }
                                        obj.horizon_group.setTranslation(result[0]);#place it on bore
                                        if (hdp.servAtt) {
                                            obj.ladder_group.setTranslation(result[2]);
                                        }
                                        obj.ladder_group.show();
                                        obj.ladder_group.update();
                                        obj.horizon_group.update();
                                        return;
                                        #############################
                                        # start new ladder:
                                        #############################
                                        obj.fpi_x = hdp.VV_x;
                                        obj.fpi_y = hdp.VV_y;
                                        #obj.fpi_x = hdp.VV_x * obj.texelPerDegreeX;
                                        #obj.fpi_y = hdp.VV_y * obj.texelPerDegreeY;
                                        obj.rot = -hdp.roll * D2R;
                                        
                                        obj.pos_y_rel = obj.fpi_y;#position from bore
                                        obj.fpi_polar = obj.clamp(math.sqrt(obj.fpi_x*obj.fpi_x+obj.pos_y_rel*obj.pos_y_rel),0.0001,10000);
                                        obj.inv_angle = obj.clamp(-obj.pos_y_rel/obj.fpi_polar,-1,1);
                                        obj.fpi_angle = math.acos(obj.inv_angle);
                                        if (obj.fpi_x < 0) {
                                          obj.fpi_angle *= -1;
                                        }
                                        obj.fpi_pos_rel_x    = math.sin(obj.fpi_angle-obj.rot)*obj.fpi_polar;

                                        obj.rot_deg = geo.normdeg(-hdp.roll);
                                        obj.default_lateral_pitchnumbers = obj.sx*0.40;
                                        var centerOffset = -obj.texels_up_into_hud+0.5*obj.sy;
                                        var frac = 1;
                                        if (obj.rot_deg >= 0 and obj.rot_deg < 90) {
                                          obj.max_lateral_pitchnumbers   = obj.extrapolate(obj.rot_deg,0,90,obj.default_lateral_pitchnumbers,obj.default_lateral_pitchnumbers+centerOffset);
                                          obj.max_lateral_pitchnumbers_p = obj.extrapolate(obj.rot_deg,0,90,obj.default_lateral_pitchnumbers*frac,obj.default_lateral_pitchnumbers*frac-centerOffset);
                                        } elsif (obj.rot_deg >= 90 and obj.rot_deg < 180) {
                                          obj.max_lateral_pitchnumbers   = obj.extrapolate(obj.rot_deg,90,180,obj.default_lateral_pitchnumbers+centerOffset,obj.default_lateral_pitchnumbers);
                                          obj.max_lateral_pitchnumbers_p = obj.extrapolate(obj.rot_deg,90,180,obj.default_lateral_pitchnumbers*frac-centerOffset,obj.default_lateral_pitchnumbers*frac);
                                        } elsif (obj.rot_deg >= 180 and obj.rot_deg < 270) {
                                          obj.max_lateral_pitchnumbers   = obj.extrapolate(obj.rot_deg,180,270,obj.default_lateral_pitchnumbers,obj.default_lateral_pitchnumbers-centerOffset);
                                          obj.max_lateral_pitchnumbers_p = obj.extrapolate(obj.rot_deg,180,270,obj.default_lateral_pitchnumbers*frac,obj.default_lateral_pitchnumbers*frac+centerOffset);
                                        } else {
                                          obj.max_lateral_pitchnumbers   = obj.extrapolate(obj.rot_deg,270,360,obj.default_lateral_pitchnumbers-centerOffset,obj.default_lateral_pitchnumbers);
                                          obj.max_lateral_pitchnumbers_p = obj.extrapolate(obj.rot_deg,270,360,obj.default_lateral_pitchnumbers*frac+centerOffset,obj.default_lateral_pitchnumbers*frac);
                                        }
                                        obj.horizon_lateral  = obj.clamp(obj.fpi_pos_rel_x,-obj.max_lateral_pitchnumbers,obj.max_lateral_pitchnumbers_p);




                                        #obj.horizon_vertical = clamp(-math.cos(obj.fpi_angle-obj.rot)*obj.fpi_polar, -obj.sy*0, obj.sy*0.75);
                                        obj.h_rot.setRotation(result[1]);
                                        obj.horizon_group.setTranslation(result[0]);#place it on bore
                                        obj.ladder_group.setTranslation(result[2]);
                                        obj.ladder_group.show();
                                        obj.ladder_group.update();
                                        obj.horizon_group.update();
                                      }),
#            props.UpdateManager.FromHashValue("roll_rad", 1.0, func(roll_rad)
#                                      {
#                                      }),
            props.UpdateManager.FromHashList(["altitude_agl_ft","cara","measured_altitude","altSwitch","alow","dgft"], 1.0, func(hdp)
                                      {
                                          obj.agl=hdp.altitude_agl_ft;
                                          obj.altScaleMode = 0;#0=baro, 1=radar 2=thermo
                                          if (hdp.altSwitch == 2) {#RDR
                                                obj.altScaleMode = hdp.cara;
                                          } elsif (hdp.altSwitch == 1) {#BARO
                                                obj.altScaleMode = 0;
                                          } else {#AUTO
                                                if (obj["altScaleModeOld"] != nil) {
                                                    if (obj.altScaleModeOld == 2) {
                                                        obj.altScaleMode = (obj.agl < 1500 and hdp.cara and !hdp.dgft and !obj.hidingScales)*2;
                                                    } else {
                                                        obj.altScaleMode = (obj.agl < 1200 and hdp.cara and !hdp.dgft and !obj.hidingScales)*2;
                                                    }
                                                } else {
                                                    obj.altScaleMode = (obj.agl < 1300 and hdp.cara and !hdp.dgft and !obj.hidingScales)*2;
                                                }
                                          }
                                          obj.altScaleModeOld = obj.altScaleMode;
                                          #print("UPDATE "~obj.altScaleMode~"  CARA "~hdp.cara~"  AGL "~obj.agl);
                                          if(hdp.altSwitch == 0 and hdp.cara and obj.altScaleMode == 0) {
                                              obj.ralt.setText(sprintf("AR %s", obj.getAltTxt(obj.agl)));
                                          } elsif(hdp.cara and obj.altScaleMode == 0) {
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
                                            if (hdp.alow < 1000) {
                                                obj.thermoAlow = hdp.alow*0.01*obj.thermoY100;
                                            } else {                                                
                                                obj.thermoAlow = obj.extrapolate(hdp.alow, 1000, 1500, obj.thermoEnd1, obj.thermoEnd2);
                                            }
                                            obj.thermoGroup.removeAllChildren();
                                            obj.thermoBar = obj.thermoGroup.createChild("path")
                                                .moveTo(obj.thermoXstart, obj.thermoYstart)
                                                .horiz(-5)
                                                .lineTo(obj.thermoXstart-5, obj.thermoYstart-obj.thermoEnd)
                                                .horiz(5)
                                                .setStrokeLineWidth(1)
                                                .setColor(obj.color);
                                            if (hdp.gear_down or (obj.agl > hdp.alow or math.mod(int(4*(hdp.elapsed-int(hdp.elapsed))),2)>0)) {
                                                obj.thermoBar.moveTo(obj.thermoXstart-5, obj.thermoYstart-obj.thermoAlow)
                                                .horiz(-4)
                                                .moveTo(obj.thermoXstart-9, obj.thermoYstart-obj.thermoAlow-2)
                                                .vert(4);
                                            }
                                            obj.thermometerScaleGrp.show();
                                          } elsif (obj.altScaleMode == 1) {
                                            #print("radar");
                                            # radar scale
                                            obj.alt_range.setTranslation(-10, obj.agl * alt_range_factor);
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
                                            obj.alt_range.setTranslation(-10, hdp.measured_altitude * alt_range_factor);
                                            obj.alt_curr.setText(obj.getAltTxt(hdp.measured_altitude));
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
                                      }),
            props.UpdateManager.FromHashList(["HUD_SCA", "DGFT"], 0.5, func(hdp)
                                      {
                                            
                                          if (hdp.HUD_SCA and !hdp.dgft and obj.hidingScales) {
                                            foreach(tck;obj.scaling) {
                                                tck.show();
                                              }
                                            obj.hidingScales = 0;
                                          } elsif (!obj.hidingScales and !(hdp.HUD_SCA and !hdp.dgft)) {
                                              foreach(tck;obj.scaling) {
                                                tck.hide();
                                              }
                                              obj.heading_tape_pointer.hide();
                                              obj.hidingScales = 1;
                                          }
                                      }),
            props.UpdateManager.FromHashList(["calibrated", "GND_SPD", "HUD_VEL", "gear_down"], 0.5, func(hdp)
                                      {   
                                          # the real F-16 has calibrated airspeed as default in HUD.
                                          var pitot = hdp.servPitot and hdp.servStatic;
                                          if (hdp.HUD_VEL == 1 or hdp.gear_down) {
                                            if (hdp.servSpeed) {
                                                obj.ias_range.setTranslation(0, hdp.calibrated * ias_range_factor * pitot);
                                                obj.speed_curr.setText(!pitot?""~0:sprintf("%d",hdp.calibrated));
                                            }
                                            obj.speed_type.setText("C");
                                          } elsif (hdp.HUD_VEL == 0) {
                                            if (hdp.servSpeed) {
                                                obj.ias_range.setTranslation(0, hdp.TAS * ias_range_factor * pitot);
                                                obj.speed_curr.setText(!pitot?""~0:sprintf("%d",hdp.TAS));
                                            }
                                            obj.speed_type.setText("T");
                                          } else {
                                            if (hdp.servSpeed) {
                                                obj.ias_range.setTranslation(0, hdp.GND_SPD * ias_range_factor * pitot);                                            
                                                obj.speed_curr.setText(!pitot?""~0:sprintf("%d",hdp.GND_SPD));
                                            }
                                            obj.speed_type.setText("G");
                                          }
                                      }),
            props.UpdateManager.FromHashValue("range_rate", 0.01, func(range_rate)
                                      {
                                          if (range_rate != nil) {
                                              obj.window1.setVisible(1);
                                              obj.window1.setText("");
                                          } else
                                            obj.window1.setVisible(0);
                                          }
                                             ),
            props.UpdateManager.FromHashList(["Nz","nReset"], 0.1, func(hdp)
                                      {
                                          obj.window12.setText(sprintf("%.1f", hdp.Nz));
                                          obj.window12.show();
                                          obj.NzMax = math.max(hdp.Nz, obj.NzMax);
                                          obj.window8.setText(sprintf("%.1f", obj.NzMax));
                                          obj.window8.show();
                                      }),
            props.UpdateManager.FromHashList(["heading", "headingMag", "useMag","gear_down"], 0.1, func(hdp)
                                      {
                                          var head = geo.normdeg(hdp.useMag?hdp.headingMag:hdp.heading);
                                          
                                          if (head < 180)
                                            obj.heading_tape_position = -head*54/10;
                                          else
                                            obj.heading_tape_position = (360-head)*54/10;
                                          if (hdp.gear_down) {
                                              obj.heading_tape_positionY = -10;
                                              obj.head_curr.setTranslation(0.5*sx*0.695633,sy*0.1-12);
                                              obj.head_mask.setTranslation(-10+0.5*sx*0.695633,sy*0.1-20);
                                              obj.head_frame.setTranslation(0,0);
                                          } else {
                                              obj.heading_tape_positionY = 95;
                                              obj.head_curr.setTranslation(0.5*sx*0.695633,sy*0.1-12+105);
                                              obj.head_mask.setTranslation(-10+0.5*sx*0.695633,sy*0.1-20+105);
                                              obj.head_frame.setTranslation(0,105);
                                          }
                                          if (hdp.servHead) {
                                            obj.head_curr.setText(sprintf("%03d",head));
                                            obj.heading_tape.setTranslation (obj.heading_tape_position,obj.heading_tape_positionY);
                                          }
                                          
                                      }
                                            ),
            props.UpdateManager.FromHashList(["time_until_crash","vne","warn", "elapsed"], 0.05, func(hdp)
                                             {
                                                 obj.ttc = hdp.time_until_crash;
                                                 if (obj.ttc != nil and obj.ttc>0 and obj.ttc<8) {
                                                     obj.flyup.setText("FLYUP");
                                                     #obj.flyup.setColor(1,0,0,1);
                                                     obj.flyup.show();
                                                 } elsif (hdp.vne) {
                                                         obj.flyup.setText("LIMIT");
                                                         obj.flyup.show();
                                                 } elsif (hdp.warn == 1 and math.mod(int(4*(hdp.elapsed-int(hdp.elapsed))),2)>0) {
                                                         obj.flyup.setText("WARN");
                                                         obj.flyup.show();
                                                 } elsif (hdp.bingo == 1 and math.mod(int(4*(hdp.elapsed-int(hdp.elapsed))),2)>0) {
                                                         obj.flyup.setText("FUEL");
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
                                            ),
            props.UpdateManager.FromHashList(["standby"], 0.5, func(hdp)
                                             {
                                                 if (hdp.standby) {
                                                     obj.stby.setText("NO RAD");
                                                     obj.stby.setTranslation(obj.sx/2,obj.sy-obj.texels_up_into_hud+7);
                                                     obj.stby.show();
                                                 } else {
                                                     obj.stby.hide();
                                                 }
                                                 obj.stby.update();
                                             }
                                            ),
            props.UpdateManager.FromHashList(["brake_parking", "gear_down", "flap_pos_deg", "CCRP_active", "master_arm","submode","VV_x","DGFT"], 0.1, func(hdp)
                                             {
                                                 if (hdp.brake_parking) {
                                                     obj.window2.setVisible(1);
                                                     obj.window2.setText("  BRAKES");
                                                 } elsif (hdp.flap_pos_deg > 0 or hdp.gear_down) {
                                                     obj.window2.setVisible(1);
                                                     obj.gd = "";
                                                     if (hdp.gear_down)
                                                       obj.gd = " G";
                                                     obj.window2.setText(sprintf("  F %d%s",hdp.flap_pos_deg,obj.gd));
                                                 } elsif (hdp.master_arm) {
                                                     var submode = "";
                                                     if (hdp.CCRP_active) {
                                                        submode = "CCRP";
                                                     } elsif (obj.showmeCCIP) {
                                                        submode = "CCIP";
                                                     } elsif (obj.eegsLoop.isRunning) {
                                                        submode = hdp.strf?"STRF":"EEGS";
                                                     } elsif (hdp.submode == 1) {
                                                        submode = "BORE";
                                                     }
                                                     var dgft = hdp.dgft?"DGFT ":"";
                                                     obj.window2.setText("  ARM "~dgft~submode);
                                                     obj.window2.setVisible(1);
                                                 } elsif (hdp.rotary == 0 or hdp.rotary == 3) {
                                                     obj.window2.setText("  ILS");
                                                     obj.window2.setVisible(1);
                                                 } else {
                                                    if (hdp.ins_knob==3) {
                                                        obj.window2.setText("  NAV");
                                                    } elsif (hdp.ins_knob==2 or hdp.ins_knob==4) {
                                                        obj.window2.setText("  ALIGN");
                                                    } else {
                                                        obj.window2.setText(" ");
                                                    }
                                                     obj.window2.setVisible(1);
                                                 }
                                             }
                                            ),
            props.UpdateManager.FromHashValue("window3_txt", nil, func(txt)
                                      { 
                                          if (txt != nil and txt != ""){
                                              obj.window3.setText(txt);
                                              obj.window3.show();
                                          }else
                                            obj.window3.hide();

                                      }),
            props.UpdateManager.FromHashValue("window4_txt", nil, func(txt)
                                      {
                                          if (txt != nil and txt != ""){
                                              obj.window4.show();
                                              obj.window4.setText(txt);
                                          }
                                          else
                                            obj.window4.hide();

                                      }),
            props.UpdateManager.FromHashValue("window5_txt", nil, func(txt)
                                      {
                                          if (txt != nil and txt != ""){
                                              obj.window5.show();
                                              obj.window5.setText(txt);
                                          }
                                          else
                                            obj.window5.hide();

                                      }),
            props.UpdateManager.FromHashValue("window6_txt", nil, func(txt)
                                      {
                                          if (txt != nil and txt != ""){
                                              obj.window6.show();
                                              obj.window6.setText(txt);
                                          }
                                          else
                                            obj.window6.hide();

                                      }),
            props.UpdateManager.FromHashValue("window7_txt", nil, func(txt)
                                      {
                                          if (txt != nil and txt != ""){
                                              obj.window7.show();
                                              obj.window7.setText(txt);
                                          }
                                          else
                                            obj.window7.hide();

                                      }),
            props.UpdateManager.FromHashValue("window9_txt", nil, func(txt)
                                      {
                                          if (txt != nil and txt != ""){
                                              obj.window9.show();
                                              obj.window9.setText(txt);
                                          }
                                          else
                                            obj.window9.hide();

                                      }),
            props.UpdateManager.FromHashValue("window10_txt", nil, func(txt)
                                      {
                                          if (txt != nil and txt != ""){
                                              obj.window10.show();
                                              obj.window10.setText(txt);
                                          }
                                          else
                                            obj.window10.hide();

                                      }),
            props.UpdateManager.FromHashValue("window11_txt", nil, func(txt)
                                      {
                                          if (txt != nil and txt != ""){
                                              obj.window11.show();
                                              obj.window11.setText(txt);
                                          }
                                          else
                                            obj.window11.hide();

                                      }),

        ];
        
        #EEGS: (other gun sights not made: lcos snap sslc)
        obj.eegsGroup = obj.centerOrigin.createChild("group");
        obj.funnelParts = 17;#number of segments in funnel sides. If increase, remember to increase all relevant vectors also.
        obj.eegsRightX = obj.makeVector(obj.funnelParts,0);
        obj.eegsRightY = obj.makeVector(obj.funnelParts,0);
        obj.eegsLeftX  = obj.makeVector(obj.funnelParts,0);
        obj.eegsLeftY  = obj.makeVector(obj.funnelParts,0);
        obj.gunPos   = nil;#[[nil,nil],[nil,nil,nil],[nil,nil,nil,nil],[nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil,nil,nil,nil],[nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil]];
        obj.eegsMe = {ac: geo.Coord.new(), eegsPos: geo.Coord.new(),shellPosX: obj.makeVector(obj.funnelParts,0),shellPosY: obj.makeVector(obj.funnelParts,0),shellPosDist: obj.makeVector(obj.funnelParts,0)};
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
        
        if (hdp.nReset) {
            me.NzMax = 1.0;
            setprop("f16/avionics/n-reset",0);
        }
#
# short cut the whole thing if the display is turned off
#        if (!hdp.hud_display or !hdp.hud_serviceable) {
#            me.svg.setColor(0.3,1,0.3,0);
#            return;
#        }
        # part 1. update data items
        hdp.roll_rad = -hdp.roll*D2R;
        if (me.initUpdate) {
            hdp.window1_txt = "1";
            hdp.window2_txt = "2";
            hdp.window2_txt = "3";
            hdp.window4_txt = "4";
            hdp.window5_txt = "5";
            hdp.window6_txt = "6";
            hdp.window7_txt = "7";
            hdp.window8_txt = "8";
            hdp.window9_txt = "9";
            hdp.window10_txt = "10";
            hdp.window11_txt = "11";
            hdp.window12_txt = "12";
        }

        if (hdp.FrameCount == 2 or me.initUpdate == 1) {
            # calc of pitch_offset (compensates for AC3D model translated and rotated when loaded. Also semi compensates for HUD being at an angle.)
            me.Hz_b =    0.66213+0.010;#0.676226;#0.663711;#0.801701;# HUD position inside ac model after it is loaded, translated (0.08m) and rotated (0.7d).
            me.Hz_t =    0.85796+0.010;#0.86608;#0.841082;#0.976668;
            me.Hx_m =   (-4.7148+0.013-4.53759+0.013)*0.5;#-4.62737;#-4.65453;#-4.6429;# HUD median X pos
            me.Vz   =    hdp.current_view_y_offset_m; # view Z position (0.94 meter per default)
            me.Vx   =    hdp.current_view_z_offset_m; # view X position (0.94 meter per default)
            

            me.bore_over_bottom = me.Vz - me.Hz_b;
            me.Hz_height        = me.Hz_t-me.Hz_b;
            me.hozizon_line_offset_from_middle_in_svg = 0.1346; #horizline and radar echoes fraction up from middle
            me.frac_up_the_hud = me.bore_over_bottom / me.Hz_height;
            me.texels_up_into_hud = me.frac_up_the_hud * me.sy;#sy default is 260
            me.texels_over_middle = me.texels_up_into_hud - me.sy/2;
            pitch_offset = -me.texels_over_middle + me.hozizon_line_offset_from_middle_in_svg*me.sy;
            setprop("f16/hud/texels-up",me.texels_up_into_hud);
        }
        
        me.Vy   =    hdp.current_view_x_offset_m;
            
        me.pixelPerMeterX = (340*0.695633)/0.15848;
        me.pixelPerMeterY = 260/(me.Hz_t-me.Hz_b);
        
        me.pixelside = me.pixelPerMeterX*me.Vy;
        
        me.svg.setTranslation(me.pixelside, 0);
        me.custom.setTranslation(me.pixelside, 0);
        me.centerOrigin.setTranslation(HudMath.getCenterOrigin()[0]+me.pixelside, HudMath.getCenterOrigin()[1]);
        me.custom.update();
        me.centerOrigin.update();
        me.svg.update();
        
#Text windows on the HUD (F-16)
#               1 
#                   10 ALOW
# 2 nav/arm         3 callsign
# 7 mach            4 eta/altitude
# 8 g               5 waypoint/slant range
# 9 weap/aoa        6 type/tacan
# 11 fuel

# velocity vector
        #340,260
        # 0.078135*2 = width of HUD  = 0.15627m
        
        me.submode = 0;
        
        if (1) {
            var vvpos = HudMath.getFlightPathIndicatorPos();
            if (hdp.drift < 2) {
                hdp.VV_x = vvpos[0];
            } else {
                hdp.VV_x = 0;
            }
            hdp.VV_y = vvpos[1];
        } elsif (hdp.wow0) {
            me.vectorMag = math.sqrt(hdp.speed_east_fps*hdp.speed_east_fps+hdp.speed_north_fps*hdp.speed_north_fps);
            if (me.vectorMag == 0) {
                me.vectorMag = 0.0001;
            }
            if (me.vectorMag<0.5) {
                hdp.VV_x = 0;
            } else {
                me.headingvv = -math.asin(hdp.speed_north_fps/me.vectorMag)*R2D+90;#divide by vector mag, to get normalized unit vector length
                if (hdp.speed_east_fps/me.vectorMag < 0) {
                  me.headingvv = -me.headingvv;
                }
                if (me.vectorMag < 0.1) {
                    me.headingvv = hdp.heading;
                }
                hdp.VV_x = geo.normdeg180(me.headingvv-hdp.heading);
            }
            hdp.VV_y = 0;
        } else {
            hdp.VV_x = hdp.beta;
            hdp.VV_y = hdp.alpha;
        }
        

        # UV mapped to x: 0-0.695633
        me.averageDegX = math.atan2(0.078135*1.0, me.Vx-me.Hx_m)*R2D;
        me.averageDegY = math.atan2((me.Hz_t-me.Hz_b)*0.5, me.Vx-me.Hx_m)*R2D;
        me.texelPerDegreeX = me.pixelPerMeterX*(((me.Vx-me.Hx_m)*math.tan(me.averageDegX*D2R))/me.averageDegX);
        me.texelPerDegreeY = me.pixelPerMeterY*(((me.Vx-me.Hx_m)*math.tan(me.averageDegY*D2R))/me.averageDegY);

        if (hdp["active_u"] != nil) {
            hdp.active_target_available = hdp.active_u != nil;
            if (hdp.active_target_available) {
                hdp.active_target_callsign = hdp.active_u.Callsign;
                if (hdp.active_u.ModelType != "")
                  hdp.active_target_model = hdp.active_u.ModelType;
                else
                  hdp.active_target_model = "XX";
            }
        } else {
            hdp.active_target_available = 0;
            hdp.active_target_callsign = "";
            hdp.active_target_model = "XX";
        }

        hdp.fcs_available = pylons.fcs != nil;
        hdp.weapon_selected = "";

        # part2. update display, first with the update managed items
        var showASC = 0;
        if (1) {#hdp.FrameCount == 2 or me.initUpdate == 1) {
            hdp.window1_txt = "";
            hdp.window2_txt = "";
            hdp.window3_txt = "";
            hdp.window4_txt = "";
            hdp.window5_txt = "";
            hdp.window6_txt = "";
            hdp.window7_txt = "";
            hdp.window8_txt = "";
            hdp.window9_txt = "";
            hdp.window10_txt = "";
            hdp.window11_txt = "";
            hdp.window12_txt = "";

            me.ASEC262.hide();
            me.ASEC100.hide();
            me.ASEC120.hide();
            me.ASEC65.hide();
            var eegsShow = 0;
            var currASEC = nil;
            
            if(hdp.master_arm and pylons.fcs != nil)
            {
                hdp.weapon_selected = pylons.fcs.selectedType;
                hdp.weapn = pylons.fcs.getSelectedWeapon();
                
                if (hdp.weapon_selected != nil)
                {
                    var mr = 0.4;
                    if (hdp.weapon_selected == "20mm Cannon") {
                        hdp.window9_txt = sprintf("%3d", pylons.fcs.getAmmo());
                        eegsShow = 1;
                    } elsif (hdp.weapon_selected == "AIM-9") {
                        hdp.window9_txt = sprintf("%d SRM", pylons.fcs.getAmmo());#short range missile
                        if (hdp.weapn != nil) {
                            if (hdp.weapn.status == armament.MISSILE_LOCK and !hdp.standby) {
                                me.ASEC65.show();
                                currASEC = nil;#[me.sx*0.5,me.sy*0.25];
                            } elsif (!hdp.standby) {
                                me.ASEC100.show();
                                currASEC = nil;#[me.sx*0.5,me.sy*0.25];
                            }
                        }
                    } elsif (hdp.weapon_selected == "IRIS-T") {
                        hdp.window9_txt = sprintf("%d ASM", pylons.fcs.getAmmo());#short range missile
                        if (hdp.weapn != nil) {
                            if (hdp.weapn.status == armament.MISSILE_LOCK and !hdp.standby) {
                                me.ASEC65.show();
                                currASEC = nil;#[me.sx*0.5,me.sy*0.25];
                            } elsif (!hdp.standby) {
                                me.ASEC100.show();
                                currASEC = nil;#[me.sx*0.5,me.sy*0.25];
                            }
                        }
                    } elsif (hdp.weapon_selected == "AIM-120") {
                        hdp.window9_txt = sprintf("%d AMM", pylons.fcs.getAmmo());#adv. medium range missile
                        if (hdp.weapn != nil) {
                            if (hdp.weapn.status == armament.MISSILE_LOCK and !hdp.standby) {
                                me.ASEC120.show();
                                currASEC = [me.sx*0.5,me.sy*0.25];
                            } elsif (!hdp.standby) {
                                me.ASEC262.show();
                                currASEC = [me.sx*0.5,me.sy*0.25+262*mr*0.5];
                            }
                        }
                    } elsif (hdp.weapon_selected == "AIM-7") {
                        hdp.window9_txt = sprintf("%d MRM", pylons.fcs.getAmmo());#medium range missile
                        if (hdp.weapn != nil) {
                            if (hdp.weapn.status == armament.MISSILE_LOCK and !hdp.standby) {
                                me.ASEC120.show();
                                currASEC = [me.sx*0.5,me.sy*0.25];
                            } elsif (!hdp.standby) {
                                me.ASEC262.show();
                                currASEC = [me.sx*0.5,me.sy*0.25+262*mr*0.5];
                            }
                        }
                        
                    } elsif (hdp.weapon_selected == "GBU-12") {
                        hdp.window9_txt = sprintf("%d GB12", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "AGM-65B") {
                        hdp.window9_txt = sprintf("%d AG65", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "AGM-65D") {
                        hdp.window9_txt = sprintf("%d AG65", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "AGM-84") {
                        hdp.window9_txt = sprintf("%d AG84", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "AGM-119") {
                        hdp.window9_txt = sprintf("%d AG119", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "MK-82") {
                        hdp.window9_txt = sprintf("%d B82", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "MK-83") {
                        hdp.window9_txt = sprintf("%d B83", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "MK-84") {
                        hdp.window9_txt = sprintf("%d B84", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "AGM-88") {
                        hdp.window9_txt = sprintf("%d AG88", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "GBU-31") {
                        hdp.window9_txt = sprintf("%d GB31", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "GBU-54") {
                        hdp.window9_txt = sprintf("%d GB54", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "GBU-24") {
                        hdp.window9_txt = sprintf("%d GB24", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "AGM-158") {
                        hdp.window9_txt = sprintf("%d AG158", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "AGM-154A") {
                        hdp.window9_txt = sprintf("%d AG154", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "CBU-87") {
                        hdp.window9_txt = sprintf("%d CB87", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "CBU-105") {
                        hdp.window9_txt = sprintf("%d CB105", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "M151") {
                        hdp.window9_txt = sprintf("%d M151", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "B61-7") {
                        hdp.window9_txt = sprintf("%d B617", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "B61-12") {
                        hdp.window9_txt = sprintf("%d B6112", pylons.fcs.getAmmo());
                    } else hdp.window9_txt = "";
                    
                    
                }
                
                if (hdp.active_u != nil)
                {
                    if (hdp.active_u.Callsign != nil) {
                        hdp.window3_txt = hdp.active_u.Callsign.getValue();
                    } else {
                        hdp.window3_txt = "";
                    }

    #        var w2 = sprintf("%-4d", hdp.active_u.get_closure_rate());
    #        w3_22 = sprintf("%3d-%1.1f %.5s %.4s",hdp.active_u.get_bearing(), hdp.active_u.get_range(), callsign, model);
    #
    #
    #these labels aren't correct - but we don't have a full simulation of the targetting and missiles so 
    #have no real idea on the details of how this works.
                    if (hdp.active_u.get_display() == 0) {
                        hdp.window4_txt = "TA XX";
                        hdp.window5_txt = "FXXX.X";#slant range
                    } else {
                        hdp.window4_txt = sprintf("TA%3d", hdp.active_u.get_altitude()*0.001);
                        hdp.window5_txt = sprintf("F%05.1f", hdp.active_u.get_slant_range());#slant range
                    }
                    
                    hdp.window6_txt = hdp.active_target_model;
                }
                else {
                    hdp.window3_txt = "";
                    hdp.window4_txt = "";
                    hdp.window5_txt = "";
                    hdp.window6_txt = "";
                }
            }
            else # weapons not armed
            {
                #me.window7.setVisible(0);
                if (hdp.nav_range != nil) {
                    me.plan = flightplan();
                    me.planSize = me.plan.getPlanSize();
                    if (me.plan.current != nil and me.plan.current >= 0 and me.plan.current < me.planSize) {
                        hdp.window5_txt = sprintf("%d>%d", hdp.nav_range, me.plan.current+1);
                    } else {
                        hdp.window5_txt = "";
                    }
                    me.eta = hdp.wp0_eta;
                    if (me.eta != nil and me.eta != "") {
                        hdp.window4_txt = me.eta;
                    } else {
                        hdp.window4_txt = "XX:XX";
                    }
                } else {
                    hdp.window4_txt = "";
                    hdp.window5_txt = "";
                }
                var knob = getprop("sim/model/f16/controls/navigation/instrument-mode-panel/mode/rotary-switch-knob");
                if (hdp.gear_down and !hdp.wow) {
                    hdp.window6_txt = "";#sprintf("A%d", hdp.approach_speed);
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
                    hdp.window6_txt = sprintf("%s TCN%03d",tcnDist,geo.normdeg(hdp.headingMag+getprop("instrumentation/tacan/bearing-relative-deg")));
                } elsif (0 and (knob==2 or knob == 3) and getprop("instrumentation/adf/in-range")) {
                    # show adf mag heading.
                    hdp.window6_txt = sprintf("ADF%03d",geo.normdeg(hdp.headingMag+getprop("instrumentation/adf/indicated-bearing-deg")));
                } elsif (0 and (knob==2 or knob == 3) and getprop("instrumentation/nav[0]/in-range") and !getprop("instrumentation/nav[0]/nav-loc")) {
                    # show vor mag heading.
                    hdp.window6_txt = sprintf("VOR%03d",geo.normdeg(getprop("orientation/heading-deg")-getprop("orientation/heading-magnetic-deg")+getprop("instrumentation/nav[0]/radials/target-auto-hdg-deg")));
                } else {
                    hdp.window6_txt = "";
                }
                var fp = flightplan();
                var slant = "";
                if (fp != nil) {
                    var wp = fp.currentWP();
                    if (wp != nil) {
                      slant = "B XXX";
                      var lat = wp.lat;
                      var lon = wp.lon;
                      var alt = wp.alt_cstr;
                      if (alt != nil) {
                        var g = geo.Coord.new();
                        g.set_latlon(lat,lon,alt*FT2M);
                        var a = geo.aircraft_position();
                        var r = a.direct_distance_to(g)*M2NM;
                        if (r>= 1) {
                            slant = sprintf("B %5.1f",r);#tenths of NM.
                        } else {
                            slant = sprintf("B %4.2f",r);#should really be hundreds of feet, but that will confuse everyone.
                        }
                      }
                    }
                }
                hdp.window3_txt = slant;
            }
            me.eegsGroup.setVisible(eegsShow);
            if (eegsShow and !me.eegsLoop.isRunning) {
                me.eegsLoop.start();
            } elsif (!eegsShow and me.eegsLoop.isRunning) {
                me.eegsLoop.stop();
            }
            

            if (hdp.bingo and math.mod(int(4*(hdp.elapsed-int(hdp.elapsed))),2)>0) {
              hdp.window11_txt = "FUEL";
            } elsif (hdp.bingo) {
              hdp.window11_txt = "";
            } elsif (ded.dataEntryDisplay.bullMode) {
				me.bullLat = getprop("f16/avionics/bulls-eye-lat");
                me.bullLon = getprop("f16/avionics/bulls-eye-lon");
                me.bullCoord = geo.Coord.new().set_latlon(me.bullLat,me.bullLon);
                me.ownCoord = geo.aircraft_position();
                me.bullDirToMe = me.bullCoord.course_to(me.ownCoord);
                me.bullDistToMe = me.bullCoord.distance_to(me.ownCoord)*M2NM;
                if (me.bullDistToMe > 999) me.bullDistToMe = 999;
                me.bullDirToMe = sprintf("%03d", me.bullDirToMe);
				me.bullDistToMe = sprintf("%02d", me.bullDistToMe);
			    hdp.window11_txt = sprintf("%s %s", me.bullDirToMe, me.bullDistToMe); 
			} else {
                hdp.window11_txt = "";
			}
			
            if (!hdp.cara) {
                hdp.window10_txt = "AL";
            } elsif (hdp.alow<hdp.altitude_agl_ft or math.mod(int(4*(hdp.elapsed-int(hdp.elapsed))),2)>0 or hdp.gear_down) {
                hdp.window10_txt = sprintf("AL%4d",hdp.alow);
            } else {
                hdp.window10_txt = "";
            }
            

            #if (hdp.window9_txt=="") {
            #    me.alphaHUD = hdp.alpha;
            #    if (hdp.gear_down) {
            #        if (hdp.wow) {
            #            me.alphaHUD = 0;
            #        }
            #    }
            #    hdp.window9_txt = sprintf("AOA %d",me.alphaHUD);
            #}
            
            hdp.window7_txt = sprintf("  %.2f",hdp.mach);
        }

        


        me.locatorLineShow = 0;
#        if (hdp.FrameCount == 1 or hdp.FrameCount == 3 or me.initUpdate == 1) {
            me.target_idx = 0;
            me.designated = 0;
            
        me.target_locked.setVisible(0);

        me.irL = 0;
        me.irS = 0;
        me.rdL = 0;
        me.irT = 0;
        me.rdT = 0;
        me.irB = 0;
        #printf("%d %d %d %s",hdp.master_arm,pylons.fcs != nil,pylons.fcs.getAmmo(),hdp.weapon_selected);
        if(hdp.master_arm and pylons.fcs != nil and pylons.fcs.getAmmo() > 0) {
            hdp.weapon_selected = pylons.fcs.selectedType;
            if (hdp.weapon_selected == "AIM-120" or hdp.weapon_selected == "AIM-7") {
                if (!pylons.fcs.isLock()) {
                    me.radarLock.setTranslation(0, -me.sy*0.25+262*0.3*0.5);
                    me.rdL = 1;
                }                
            } elsif (!pylons.fcs.isLock() and hdp.weapon_selected == "AIM-9" or hdp.weapon_selected == "IRIS-T") {
                if (pylons.bore) {
                    var aim = pylons.fcs.getSelectedWeapon();
                    if (aim != nil) {
                        me.submode = 1;
                        #var coords = aim.getSeekerInfo();
                        #me.irSearch.setTranslation(HudMath.getCenterPosFromDegs(coords[0],coords[1]));
                        me.irBore.setTranslation(HudMath.getCenterPosFromDegs(0,-3.5));
                        me.irB = 1;
                    }
                } else {
                    me.irS = 1;
                    me.irSearch.setTranslation(0, -me.sy*0.25);
                }
            } elsif (pylons.fcs.isLock() and hdp.weapon_selected == "AIM-9" or hdp.weapon_selected == "IRIS-T" and pylons.bore) {
                var aim = pylons.fcs.getSelectedWeapon();
                if (aim != nil) {
                    var coords = aim.getSeekerInfo();
                    if (coords != nil) {
                        me.irLock.setTranslation(HudMath.getCenterPosFromDegs(coords[0],coords[1]));
                        me.irL = 1;
                    }
                }
            }
        }
        me.designatedDistanceFT = nil;
        me.groundDistanceFT = nil;
        if (hdp["tgt_list"] != nil) {
            foreach ( me.u; hdp.tgt_list ) {
                if (hdp.dgft and !(hdp.active_u != nil and hdp.active_u.Callsign != nil and me.u.Callsign != nil and me.u.Callsign.getValue() == hdp.active_u.Callsign.getValue())) {
                    continue;
                }
                me.callsign = "XX";
                if (rdrMode == RADAR_MODE_SEA and me.u.get_type() != armament.MARINE) {
                    continue;
                }
                if (rdrMode == RADAR_MODE_CRM and me.u.get_type() == armament.MARINE) {
                    continue;
                }
                if (me.u.get_display()) {
                    if (me.u.Callsign != nil)
                      me.callsign = me.u.Callsign.getValue();
                    me.model = "XX";

                    if (me.u.ModelType != "")
                      me.model = me.u.ModelType;
                    
                    if (me.target_idx < me.max_symbols or me.designatedDistanceFT == nil) {
                        me.echoPos = HudMath.getPosFromCoord(me.u.get_Coord(0));
                        #print(HudMath.dir_x);
                        if (me.target_idx < me.max_symbols) {
                            me.tgt = me.tgt_symbols[me.target_idx];
                        } else {
                            me.tgt = nil;
                        }
                        if (me.tgt != nil or me.designatedDistanceFT == nil) {
                            if (me.tgt != nil) {
                                me.tgt.setVisible(me.u.get_display());
                            }
                            #me.u_dev_rad = (90-me.u.get_deviation(hdp.heading))  * D2R;
                            #me.u_elev_rad = (90-me.u.get_total_elevation( hdp.pitch))  * D2R;
                            #me.devs = me.develev_to_devroll(hdp, me.u_dev_rad, me.u_elev_rad);
                            #me.combined_dev_deg = me.devs[0];
                            #me.combined_dev_length =  me.devs[1];
                            #me.clamped = me.devs[2];
                            #me.yc = ht_yco + (ht_ycf * me.combined_dev_length * math.cos(me.combined_dev_deg*D2R));
                            #me.xc = ht_xco + (ht_xcf * me.combined_dev_length * math.sin(me.combined_dev_deg*D2R));
                            
                            #me.clamped = me.yc > me.sy*0.5 or me.yc < -me.sy*0.5+me.hozizon_line_offset_from_middle_in_svg*me.sy or me.xc > me.sx *0.5 or me.xc < -me.sx*0.5; # outside HUD
                            me.clamped = HudMath.isCenterPosClamped(me.echoPos[0],me.echoPos[1]);
                            
                            if (hdp.active_u != nil and hdp.active_u.Callsign != nil and me.u.Callsign != nil and me.u.Callsign.getValue() == hdp.active_u.Callsign.getValue()) {
                                me.designatedDistanceFT = hdp.active_u.get_Coord().direct_distance_to(geo.aircraft_position())*M2FT;
                                me.target_locked.setVisible(1);
                                if (me.tgt != nil) {
                                    me.tgt.hide();
                                }
                                #me.xcS = me.sx/2                     + (me.pixelPerMeterX * me.combined_dev_length * math.sin(me.combined_dev_deg*D2R));
                                #me.ycS = me.sy-me.texels_up_into_hud - (me.pixelPerMeterY * me.combined_dev_length * math.cos(me.combined_dev_deg*D2R));
                                #me.target_locked.setTranslation (me.xcS, me.ycS);
                                me.target_locked.setTranslation (me.echoPos);
                                if (0 and currASEC != nil) {
                                    # disabled for now as it has issues
                                    me.cue = nil;
                                    call(func {me.cue = hdp.weapn.getIdealFireSolution();},[], nil, nil, var err = []);
                                    if (me.cue != nil) {
                                        me.ascpixel = me.cue[1]*HudMath.getPixelPerDegreeAvg(2);
                                        me.ascPos = HudMath.getPosFromDegs(me.echoPos[2], me.echoPos[3]);
                                        me.ascDist = math.sqrt(math.pow(me.ascPos[0]+math.cos(me.cue[0]*D2R)*me.ascpixel,2)+math.pow(me.ascPos[1]+math.sin(me.cue[0]*D2R)*me.ascpixel,2));
                                        me.ascReduce = me.ascDist > me.sx*0.20?me.sx*0.20/me.ascDist:1;
                                        me.ASC.setTranslation(currASEC[0]+me.ascReduce*(me.ascPos[0]+math.cos(me.cue[0]*D2R)*me.ascpixel),currASEC[1]+me.ascReduce*(me.ascPos[1]+math.sin(me.cue[0]*D2R)*me.ascpixel));
                                        showASC = 1;
                                    }
                                }
                                if (pylons.fcs != nil and pylons.fcs.isLock()) {
                                    #me.target_locked.setRotation(45*D2R);
                                    if (hdp.weapon_selected == "AIM-120" or hdp.weapon_selected == "AIM-7" or hdp.weapon_selected == "AIM-9" or hdp.weapon_selected == "IRIS-T") {
                                        var aim = pylons.fcs.getSelectedWeapon();
                                        if (aim != nil) {
                                            var coords = aim.getSeekerInfo();
                                            if (coords != nil) {
                                                me.seekPos = HudMath.getCenterPosFromDegs(coords[0],coords[1]);
                                                #me.irLock.setTranslation(me.sx/2+me.texelPerDegreeX*coords[0],me.sy-me.texels_up_into_hud-me.texelPerDegreeY*coords[1]);
                                                #me.radarLock.setTranslation(me.sx/2+me.texelPerDegreeX*coords[0],me.sy-me.texels_up_into_hud-me.texelPerDegreeY*coords[1]);
                                                me.irLock.setTranslation(me.seekPos);
                                                me.radarLock.setTranslation(me.seekPos);
                                            }
                                        }
                                    }
                                    if (hdp.weapon_selected == "AIM-120" or hdp.weapon_selected == "AIM-7") {
                                        #me.radarLock.setTranslation(me.xcS, me.ycS); too perfect
                                        me.ASEC120Aspect.setRotation(D2R*(hdp.active_u.get_heading()-hdp.heading+180));
                                        me.rdL = 1;
                                        me.rdT = 1;
                                    } elsif (hdp.weapon_selected == "AIM-9" or hdp.weapon_selected == "IRIS-T") {
                                        #me.irLock.setTranslation(me.xcS, me.ycS);
                                        me.ASEC65Aspect.setRotation(D2R*(hdp.active_u.get_heading()-hdp.heading+180));
                                        me.irL = 1;
                                        me.irT = 1;
                                    }
                                } else {
                                    #me.target_locked.setRotation(0);
                                }
                                if (me.clamped) {
                                    #me.locatorLine.setTranslation(me.sx/2,me.sy-me.texels_up_into_hud);
                                    #me.locatorLine.setRotation(me.combined_dev_deg*D2R);
                                    me.locatorLine.setTranslation(HudMath.getBorePos());
                                    me.locatorLine.setRotation(HudMath.getPolarFromCenterPos(me.echoPos[0],me.echoPos[1])[0]);
                                    me.dev_h_d = me.u.get_deviation(hdp.heading);
                                    me.dev_e_d = me.u.get_total_elevation(hdp.pitch);
                                    me.locatorAngle.setText(sprintf("%d", math.sqrt(me.dev_h_d*me.dev_h_d+me.dev_e_d*me.dev_e_d)));
                                    me.locatorLineShow = 1;
                                }
                            } else {
                                #
                                # if in symbol reject mode then only show the active target.
                                if (hdp.symbol_reject and me.tgt != nil) {
                                  me.tgt.setVisible(0);
                                }
                            }
                            if (me.tgt != nil) {
                                me.tgt.setTranslation (me.echoPos);
                                me.tgt.update();
                            }
                            if (ht_debug)
                              printf("%-10s %f,%f [%f,%f,%f] :: %f,%f",me.callsign,me.xc,me.yc, me.devs[0], me.devs[1], me.devs[2], me.u_dev_rad*D2R, me.u_elev_rad*D2R); 
                        }
                        else print("[ERROR]: HUD too many targets ",me.target_idx);
                    }
                    me.target_idx += 1;
                }
            }

            for (me.nv = me.target_idx; me.nv < me.max_symbols;me.nv += 1) {
                me.tgt = me.tgt_symbols[me.nv];
                if (me.tgt != nil) {
                    me.tgt.setVisible(0);
                }
            }
        }
        else print("[ERROR] Radar system missing or uninit (frame notifier)");
        me.ASC.setVisible(showASC);
        
        #print(me.irS~" "~me.irL);

        me.locatorLine.setVisible(me.locatorLineShow);
        me.locatorAngle.setVisible(me.locatorLineShow);

        if (hdp.dgft) {
            me.peelDeg = 90-hdp.pitch;
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
            if (hdp.servTurn) {
                me.orangePeelGroup.setRotation(-hdp.roll*D2R);
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
        } else {
            #printf("%d %d %d %d %d",me.dlzArray[0],me.dlzArray[1],me.dlzArray[2],me.dlzArray[3],me.dlzArray[4]);
            me.dlz2.removeAllChildren();
            me.dlzArrow.setTranslation(0,-me.dlzArray[4]/me.dlzArray[0]*me.dlzHeight);
            if (hdp.active_u != nil) {
                me.dlzClo.setTranslation(0,-me.dlzArray[4]/me.dlzArray[0]*me.dlzHeight);
                me.dlzClo.setText(sprintf("%+d ",hdp.active_u.get_closure_rate()));
                if (pylons.fcs.isLock() and me.dlzArray[4] < me.dlzArray[2] and math.mod(int(4*(hdp.elapsed-int(hdp.elapsed))),2)>0) {
                    me.irL = 0;
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
                    .setColor(0.3,1,0.3);
            me.dlz2.update();
            me.dlz.show();
        }

        me.radarLock.setVisible(me.rdL);
        me.irSearch.setVisible(me.irS);
        me.irLock.setVisible(me.irL);
        me.irBore.setVisible(me.irB);
        me.ASEC120Aspect.setVisible(me.rdT);
        me.ASEC65Aspect.setVisible(me.irT);
        me.radarLock.update();
        me.irLock.update();

        if (hdp.ded == 2 and !hdp.dgft) {
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
        } elsif (hdp.ded == 1 and !hdp.dgft) {
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

        if (tgp.flir_updater.click_coord_cam != nil and getprop("f16/avionics/tgp-lock")) {# hdp.tgp_mounted and 
            if (getprop("sim/view[105]/heading-offset-deg")==0 and getprop("sim/view[105]/pitch-offset-deg")==-30 and armament.contactPoint != nil) {
                #var b = geo.normdeg180(armament.contactPoint.get_relative_bearing());
                #var p = armament.contactPoint.getElevation()-hdp.pitch;
                var xy = HudMath.getPosFromCoord(armament.contactPoint.get_Coord());
                var y = me.clamp(xy[1],-me.sy*0.40,me.sy*0.40);
                var x = me.clamp(xy[0],-me.sx*0.45,me.sx*0.45);
                #var y = me.clamp(-p*me.texelPerDegreeY+me.sy-me.texels_up_into_hud,me.sy*0.05,me.sy*0.95);
                #var x = me.clamp(b*me.texelPerDegreeX+me.sx*0.5,me.sx*0.025,me.sx*0.975);
                if (y != xy[1] or x != xy[0]) {
                    me.tgpPointC.setTranslation(x,y);
                    me.tgpPointC.show();
                } else {
                    me.tgpPointC.hide();
                }
                me.tgpPointF.setTranslation(x,y);
                me.tgpPointF.show();
            } else {
                var b = geo.normdeg180(getprop("sim/view[105]/heading-offset-deg"));
                var p = getprop("sim/view[105]/pitch-offset-deg");
                var xy = HudMath.getCenterPosFromDegs(b,p);
                var y = me.clamp(xy[1],-me.sy*0.40,me.sy*0.40);
                var x = me.clamp(xy[0],-me.sx*0.45,me.sx*0.45);
                #var y = me.clamp(-p*me.texelPerDegreeY+me.sy-me.texels_up_into_hud,me.sy*0.05,me.sy*0.95);
                #var x = me.clamp(b*me.texelPerDegreeX+me.sx*0.5,me.sx*0.025,me.sx*0.975);
                if (y != xy[1] or x != xy[0]) {
                    me.tgpPointC.setTranslation(x,y);
                    me.tgpPointC.show();
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
        
        foreach(var update_item; me.update_items)
        {
            update_item.update(hdp);
        }
        me.svg.show();
    },
    resetGunPos: func {
        me.gunPos   = [];
        for(i = 0;i < me.funnelParts*2;i+=1){
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

    develev_to_devroll : func(notification, dev_rad, elev_rad)
    {
        var eye_hud_m          = me.Vx-me.Hx_m;
        var hud_position       = 4.65453;#4.6429;#4.61428;#4.65415;#5.66824; # really -5.6 but avoiding more complex equations by being optimal with the signs.
        var hud_radius_m       = 0.08429;
        var clamped = 0;

        eye_hud_m = hud_position + notification.current_view_z_offset_m; # optimised for signs so we get a positive distance.
# Deviation length on the HUD (at level flight),
        var h_dev = eye_hud_m / ( math.sin(dev_rad) / math.cos(dev_rad) );
        var v_dev = eye_hud_m / ( math.sin(elev_rad) / math.cos(elev_rad) );
# Angle between HUD center/top <-> HUD center/symbol position.
        # -90° left, 0° up, 90° right, +/- 180° down. 
        var dev_deg =  math.atan2( h_dev, v_dev ) * R2D;
# Correction with own a/c roll.
        var combined_dev_deg = dev_deg - notification.roll;
# Lenght HUD center <-> symbol pos on the HUD:
        var combined_dev_length = math.sqrt((h_dev*h_dev)+(v_dev*v_dev));

# clamping
        var abs_combined_dev_deg = math.abs( combined_dev_deg );
        var clmp = hud_radius_m;

# squeeze the top of the display area for egg shaped HUD limits.
#   if ( abs_combined_dev_deg >= 0 and abs_combined_dev_deg < 90 ) {
#       var coef = ( 90 - abs_combined_dev_deg ) * 0.00075;
#       if ( coef > 0.050 ) { coef = 0.050 }
#       clamp -= coef; 
        #   }
        if ( combined_dev_length > clmp ) {
            #combined_dev_length = clamp;
            clamped = 1;
        }
        var v = [combined_dev_deg, combined_dev_length, clamped];
        return(v);
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
            clip_el.setVisible(0);
            var tran_rect = clip_el.getTransformedBounds();

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
        if (hdp.fcs_available and hdp.master_arm ==1) {
            var trgt = armament.contactPoint;
            if(trgt == nil and hdp.active_u != nil) {
                trgt = hdp.active_u;
            } elsif (trgt == nil) {
                return 0;
            }
            var selW = pylons.fcs.getSelectedWeapon();
            if (selW != nil and !hdp.CCIP_active and 
                (selW.type=="MK-82" or selW.type=="MK-83" or selW.type=="MK-84" or selW.type=="GBU-12" or selW.type=="GBU-31" or selW.type=="GBU-54" or selW.type=="GBU-24" or selW.type=="CBU-87" or selW.type=="CBU-105" or selW.type=="AGM-154A" or selW.type=="B61-7" or selW.type=="B61-12") and selW.status == armament.MISSILE_LOCK ) {

                if (selW.guidance == "unguided") {
                    me.dt = 0.1;
                    me.maxFallTime = 20;
                } else {
                    me.agl = (hdp.altitude_ft-trgt.get_altitude())*FT2M;
                    me.dt = me.agl*0.000025;#4000 ft = ~0.1
                    if (me.dt < 0.1) me.dt = 0.1;
                    me.maxFallTime = 45;
                }
                me.distCCRP = pylons.fcs.getSelectedWeapon().getCCRP(me.maxFallTime,me.dt);
                if (me.distCCRP == nil or (me.distCCRP*M2NM > 13.2 and selW.guidance == "laser")) {#1F-F16CJ-34-1: max laser dist is 13.2nm
                    me.solutionCue.hide();
                    me.ccrpMarker.hide();
                    me.bombFallLine.hide();
                    return 0;
                }
                me.distCCRP/=4000;
                if (me.distCCRP > 0.75) {
                    me.distCCRP = 0.75;
                }
                me.bombFallLine.setTranslation(trgt.get_relative_bearing()*me.texelPerDegreeX,0);
                me.ccrpMarker.setTranslation(trgt.get_relative_bearing()*me.texelPerDegreeX,0);
                me.solutionCue.setTranslation(trgt.get_relative_bearing()*me.texelPerDegreeX,me.sy*0.5-me.sy*0.5*me.distCCRP);
                me.bombFallLine.show();
                me.ccrpMarker.show();
                me.solutionCue.show();
                return 1;
            } else {
                me.solutionCue.hide();
                me.ccrpMarker.hide();
                me.bombFallLine.hide();
                return 0;
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
            if (hdp.fcs_available and hdp.master_arm ==1) {
                var selW = pylons.fcs.getSelectedWeapon();
                if (selW != nil and (selW.type=="MK-82" or selW.type=="MK-83" or selW.type=="MK-84" or selW.type=="GBU-12" or selW.type=="GBU-31" or selW.type=="GBU-54" or selW.type=="GBU-24" or selW.type=="CBU-87" or selW.type=="CBU-105" or selW.type=="B61-12")) {
                    me.showmeCCIP = 1;
                    me.ccipPos = pylons.fcs.getSelectedWeapon().getCCIPadv(18,0.20);
                    if (me.ccipPos == nil) {
                        me.pipper.setVisible(me.showPipper);
                        me.pipperLine.setVisible(me.showPipper);
                        return 0;
                    }
                    me.showme = TRUE;
                    
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
                    #        me.showme = FALSE;
                    #    }
                    #} else {
                    #    me.showme = FALSE;
                    #}
                    me.hud_pos = HudMath.getPosFromCoord(me.ccipPos[0]);
                    if(me.hud_pos != nil) {
                        me.pos_x = me.hud_pos[0];
                        me.pos_y = me.hud_pos[1];
                        #printf("HUDMath  %.1f", HudMath.dir_x);
                        #printf("Aircraft %.1f", hdp.heading);
                        #printf("dist=%0.1f (%3d , %3d)", dist, pos_x, pos_y);

                        #if(me.pos_x > (512/1024)*canvasWidth) {
                        #  me.showme = FALSE;
                        #} elsif(me.pos_x < -(512/1024)*canvasWidth) {
                        #  me.showme = FALSE;
                        #} elsif(me.pos_y > (512/1024)*canvasWidth) {
                        #  me.showme = FALSE;
                        #} elsif(me.pos_y < -(512/1024)*canvasWidth) {
                        #  me.showme = FALSE;
                        #}

                        if(me.showme == TRUE) {
                            me.pipperLine.removeAllChildren();
                            me.bPos = [hdp.VV_x,hdp.VV_y]; #HudMath.getBorePos(); 
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
    
    displayEEGS: func() {
        #note: this stuff is expensive like hell to compute, but..lets do it anyway.
        var strf = getprop("f16/avionics/strf");
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
            
            var hdp = {roll:me.eegsMe.roll,current_view_z_offset_m: getprop("sim/current-view/z-offset-m")};
            
            #var geodPos = aircraftToCart({x:-getprop("sim/current-view/z-offset-m"), y:getprop("sim/current-view/x-offset-m"), z: -getprop("sim/current-view/y-offset-m")});
            #me.eegsMe.ac.set_xyz(geodPos.x, geodPos.y, geodPos.z);#position of pilot eyes in aircraft
            me.eegsMe.ac = geo.aircraft_position();
            me.eegsMe.allow = 1;
            me.drawEEGSPipper = 0;
            me.strfRange = 10000;
            if(strf) {
                me.groundDistanceFT = nil;
                var l = 0;
                for (l = 0;l < me.funnelParts*2;l+=1) {
                    # compute display positions of funnel on hud
                    var pos = me.gunPos[l][0];
                    if (pos == nil) {
                        me.eegsMe.allow = 0;
                    } else {
                        var ac  = me.gunPos[l][0][1];
                        pos     = me.gunPos[l][0][0];
                        var el = geo.elevation(pos.lat(),pos.lon());
                        if (el == nil) {
                            el = 0;
                        }

                        if (l != 0 and el > pos.alt()) {
                            var hitPos = geo.Coord.new(pos);
                            hitPos.set_alt(el);
                            me.groundDistanceFT = (el-pos.alt())*M2FT;#ac.direct_distance_to(hitPos)*M2FT;
                            me.strfRange = hitPos.direct_distance_to(me.eegsMe.ac)*M2FT;
                            l = l;
                            break;
                        }
                    }
                }

                # compute display positions of funnel on hud
                
                if (me.eegsMe.allow and me.groundDistanceFT != nil) {
                    for (var ll = l-1;ll <= l;ll+=1) {
                        var ac  = me.gunPos[ll][0][1];
                        var pos = me.gunPos[ll][0][0];

                        me.eegsMe.posTemp = HudMath.getPosFromCoord(pos,ac);
                        me.eegsMe.shellPosDist[ll] = ac.direct_distance_to(pos)*M2FT;
                        me.eegsMe.shellPosX[ll] = me.eegsMe.posTemp[0];#me.eegsMe.xcS;
                        me.eegsMe.shellPosY[ll] = me.eegsMe.posTemp[1];#me.eegsMe.ycS;
                        
                        if (l == ll and me.strfRange < 10000) {
                            var highdist = me.eegsMe.shellPosDist[ll];
                            var lowdist = me.eegsMe.shellPosDist[ll-1];
                            me.groundDistanceFT = math.sqrt(me.groundDistanceFT*me.groundDistanceFT+me.groundDistanceFT*me.groundDistanceFT);#we just assume impact angle of 45 degs
                            me.eegsPipperX = HudMath.extrapolate(highdist-me.groundDistanceFT,lowdist,highdist,me.eegsMe.shellPosX[ll-1],me.eegsMe.shellPosX[ll]);
                            me.eegsPipperY = HudMath.extrapolate(highdist-me.groundDistanceFT,lowdist,highdist,me.eegsMe.shellPosY[ll-1],me.eegsMe.shellPosY[ll]);
                            me.drawEEGSPipper = 1;
                        }
                    }
                }
            } else {
                for (var l = 0;l < me.funnelParts;l+=1) {
                    # compute display positions of funnel on hud
                    var pos = me.gunPos[l][l+1];
                    if (pos == nil) {
                        me.eegsMe.allow = 0;
                    } else {
                        var ac  = me.gunPos[l][l][1];
                        pos     = me.gunPos[l][l][0];
                        #me.eegsMe.u_dev_rad  = (90-awg_9.deviation_normdeg(me.eegsMe.hdg,   ac.course_to(pos)))  * D2R;
                        #me.eegsMe.u_elev_rad = (90-awg_9.deviation_normdeg(me.eegsMe.pitch, math.atan2(pos.alt()-ac.alt(),ac.distance_to(pos))*R2D))  * D2R;
                        #if (l==0) {
                        #    #printf("prev %.2f alt %.2f our-pitch %.2f our-alt %.2f",math.atan2(pos.alt()-me.eegsMe.ac.alt(),pos.distance_to(me.eegsMe.ac))*R2D-me.eegsMe.pitch,pos.alt(),me.eegsMe.pitch, me.eegsMe.ac.alt());
                        #    printf("seen bearing %.2f from heading %.2f", me.eegsMe.ac.course_to(pos[0]), me.eegsMe.hdg);
                        #    printf("realdist=%d",pos[0].distance_to(me.eegsMe.ac));
                            #pos.dump();
                        #    print();
                        #}
                        #me.eegsMe.devs = me.develev_to_devroll(hdp, me.eegsMe.u_dev_rad, me.eegsMe.u_elev_rad);
                        #me.eegsMe.combined_dev_deg    =  me.eegsMe.devs[0];
                        #me.eegsMe.combined_dev_length =  me.eegsMe.devs[1];
                        #me.eegsMe.xcS = me.sx/2                     + (me.pixelPerMeterX * me.eegsMe.combined_dev_length * math.sin(me.eegsMe.combined_dev_deg*D2R));
                        #me.eegsMe.ycS = me.sy-me.texels_up_into_hud - (me.pixelPerMeterY * me.eegsMe.combined_dev_length * math.cos(me.eegsMe.combined_dev_deg*D2R));
                        me.eegsMe.posTemp = HudMath.getPosFromCoord(pos,ac);
                        me.eegsMe.shellPosDist[l] = ac.direct_distance_to(pos)*M2FT;
                        me.eegsMe.shellPosX[l] = me.eegsMe.posTemp[0];#me.eegsMe.xcS;
                        me.eegsMe.shellPosY[l] = me.eegsMe.posTemp[1];#me.eegsMe.ycS;
                        
                        if (me.designatedDistanceFT != nil and !me.drawEEGSPipper) {
                          if (l != 0 and me.eegsMe.shellPosDist[l] >= me.designatedDistanceFT and me.eegsMe.shellPosDist[l]>me.eegsMe.shellPosDist[l-1]) {
                            var highdist = me.eegsMe.shellPosDist[l];
                            var lowdist = me.eegsMe.shellPosDist[l-1];
                            me.eegsPipperX = HudMath.extrapolate(me.designatedDistanceFT,lowdist,highdist,me.eegsMe.shellPosX[l-1],me.eegsMe.shellPosX[l]);
                            me.eegsPipperY = HudMath.extrapolate(me.designatedDistanceFT,lowdist,highdist,me.eegsMe.shellPosY[l-1],me.eegsMe.shellPosY[l]);
                            me.drawEEGSPipper = 1;
                          }
                        }
                    }
                }
            }
            if (me.eegsMe.allow and !strf) {
                # draw the funnel
                for (var k = 0;k<me.funnelParts;k+=1) {
                    var halfspan = math.atan2(getprop("f16/avionics/eegs-wingspan-ft")*0.5,me.eegsMe.shellPosDist[k])*R2D*me.texelPerDegreeX;#35ft average fighter wingspan
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
                if (me.drawEEGSPipper) {
                    var radius = 2;
                    me.eegsGroup.createChild("path")
                          .moveTo(me.eegsPipperX, me.eegsPipperY-radius)
                          .arcSmallCW(radius,radius,0,0,radius*2)
                          .arcSmallCW(radius,radius,0,0,-radius*2)
                          .setStrokeLineWidth(1)
                          .setColor(me.color);
                }
                me.eegsGroup.update();
            }
            if (me.eegsMe.allow and strf) {
                # draw the STRF pipper (T.O. GR1F-16CJ-34-1-1 page 1-442)
                me.eegsGroup.removeAllChildren();
                if (me.drawEEGSPipper) {
                    var mr = 0.4 * 1.5;
                    var pipperRadius = 15 * mr;
                    if (me.strfRange <= 4000) {
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
                }
                me.eegsGroup.update();
            }
            
            
            
            
            #calc shell positions
            
            me.eegsMe.vel = getprop("velocities/uBody-fps")+2041;#2041 = speed
            
            #me.eegsMe.geodPos = aircraftToCart({x:3.16, y:-0.81, z: -0.17});#position of gun in aircraft (x and z inverted)
            #me.eegsMe.eegsPos.set_xyz(me.eegsMe.geodPos.x, me.eegsMe.geodPos.y, me.eegsMe.geodPos.z);
            me.eegsMe.geodPos = aircraftToCart({x:0, y:-0.81, z: -(0.17-getprop("sim/current-view/y-offset-m"))});#position of gun in aircraft (x and z inverted)
            me.eegsMe.eegsPos.set_xyz(me.eegsMe.geodPos.x, me.eegsMe.geodPos.y, me.eegsMe.geodPos.z);
            #me.eegsMe.eegsPos = geo.Coord.new(me.eegsMe.ac);
            me.eegsMe.altC = me.eegsMe.eegsPos.alt();
            
            me.eegsMe.rs = armament.AIM.rho_sndspeed(me.eegsMe.altC*M2FT);#simplified
            me.eegsMe.rho = me.eegsMe.rs[0];
            me.eegsMe.mass =  0.1069/ armament.slugs_to_lbm;#0.1069=lbs
            
            #print("x,y");
            #printf("%d,%d",0,0);
            #print("-----");
            var multi = strf?2:1;
            for (var j = 0;j < me.funnelParts*multi;j+=1) {
                
                #calc new speed
                me.eegsMe.Cd = drag(me.eegsMe.vel/ me.eegsMe.rs[1],0.193);#0.193=cd
                me.eegsMe.q = 0.5 * me.eegsMe.rho * me.eegsMe.vel * me.eegsMe.vel;
                me.eegsMe.deacc = (me.eegsMe.Cd * me.eegsMe.q * 0.00136354) / me.eegsMe.mass;#0.00136354=eda
                me.eegsMe.vel -= me.eegsMe.deacc * me.averageDt;
                me.eegsMe.speed_down_fps       = -math.sin(me.eegsMe.pitch * D2R) * (me.eegsMe.vel);
                me.eegsMe.speed_horizontal_fps = math.cos(me.eegsMe.pitch * D2R) * (me.eegsMe.vel);
                
                me.eegsMe.speed_down_fps += 9.81 *M2FT *me.averageDt;
                
                
                 
                me.eegsMe.altC -= (me.eegsMe.speed_down_fps*me.averageDt)*FT2M;
                
                
                #printf("altC %d   vel_z %d   acc_z=%d",me.eegsMe.altC,me.eegsMe.vel_z,me.eegsMe.acc * averageDt);
                
                
                me.eegsMe.dist = (me.eegsMe.speed_horizontal_fps*me.averageDt)*FT2M;
                
                #printf("vel_x %d  acc_x %d", me.eegsMe.vel_x,me.eegsMe.acc);
                #printf("pitch=%.1f  vel=%d  vdown=%.1f",me.eegsMe.pitch, me.eegsMe.vel, me.eegsMe.speed_down_fps, );
                me.eegsMe.eegsPos.apply_course_distance(me.eegsMe.hdg, me.eegsMe.dist);
                me.eegsMe.eegsPos.set_alt(me.eegsMe.altC);
                
                var old = me.gunPos[j];
                me.gunPos[j] = [[geo.Coord.new(me.eegsMe.eegsPos),me.eegsMe.ac]];
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
    },
    extrapolate: func (x, x1, x2, y1, y2) {
        return y1 + ((x - x1) / (x2 - x1)) * (y2 - y1);
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

            if (notification.NotificationType == "FrameNotification")
            {
                if (notification.route_manager_active and notification.route_manager_power) {
                    if (notification.nav_range != nil) {
                        notification.hud_window5 = sprintf("%2d MIN",notification.nav_range);
                    } else {
                        notification.hud_window5 = "XXX";
                    }

                    if (notification.eta_s != nil)
                      notification.hud_window5 = sprintf("%2d MIN",notification.eta_s/60);
                    else
                      notification.hud_window5 = "XX MIN";
                } else {
                    notification.nav_range = nil;
                    notification.hud_window5 = "";
                }
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