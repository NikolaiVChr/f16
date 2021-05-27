# Canvas HMD
# ---------------------------
# HUD uses data in the frame notification
# HUD is in two parts so we have a single class that we can instantiate
# twice on for each combiner pane
# ---------------------------
# Richard Harrison (rjh@zaretto.com) 2016-07-01  - based on F-15 HUD
# ---------------------------

var stroke1 = 4;
var fontSize = 36;
var fontRatio = 1;

var flirImageReso = 16;

var ht_debug = 0;

var pitch_factor = 14.85;#19.8;
var pitch_factor_2 = pitch_factor * 180.0 / math.pi;
var alt_range_factor = (9317-191) / 100000; # alt tape size and max value.
var ias_range_factor = (694-191) / 1100;
var use_war_hud = 1;
var uv_x1 = 0;
var uv_x2 = 0;
var semi_width = 0.0;
var uv_used = uv_x2-uv_x1;
var tran_x = 0;
var tran_y = 0;

var F16_HMD = {
    map: func (value, leftMin, leftMax, rightMin, rightMax) {
        # Figure out how 'wide' each range is
        var leftSpan = leftMax - leftMin;
        var rightSpan = rightMax - rightMin;

        # Convert the left range into a 0-1 range (float)
        var valueScaled = (value - leftMin) / leftSpan;

        # Convert the 0-1 range into a value in the right range.
        return rightMin + (valueScaled * rightSpan);
    },

    new : func (canvas_item, sx, sy){
        var obj = {parents : [F16_HMD] };

        obj.canvas= canvas.new({
                "name": "F16 HMD",
                    "size": [1024,1024], 
                    "view": [sx,sy],#1024,1024
                    "mipmapping": 0, # mipmapping will make the HUD text blurry on smaller screens     
                    "additive-blend": 1# bool
                    });  

        
        
        # Real HUD:
        #
        # F16C: Optics provides a 25degree Total Field of View and a 20o by 13.5o Instantaneous Field of View
        #
        # F16A: Total Field of View of the F-16 A/B PDU is 20deg but the Instantaneous FoV is only 9deg in elevation and 13.38deg in azimuth
        
        
        
        uv_x1 = 0;
        uv_x2 = 1;
        semi_width = 0.025;
        uv_used = uv_x2-uv_x1;
        tran_x = 0;

        obj.sy = sy;                        
        obj.sx = sx*uv_used;

        obj.canvas.addPlacement({"node": canvas_item});
        obj.canvas.setColorBackground(0.30, 1, 0.3, 0.00);

# Create a group for the parsed elements
        obj.svg = obj.canvas.createGroup().hide();
        obj.svg.setColor(0.3,1,0.3);

        obj.mainCross = obj.svg.createChild("path")
                .moveTo(0,0)
                .lineTo(1024,1024)
                .moveTo(1024,0)
                .lineTo(0,1024)
                .setStrokeLineWidth(stroke1)
                .setColor(0,0,1)
                .hide();
        obj.mainCircle = obj.svg.createChild("path")
            .moveTo(12,512)
            .arcSmallCW(500,500, 0, 500*2, 0)
            .arcSmallCW(500,500, 0, -500*2, 0)
            .setStrokeLineWidth(stroke1)
            .hide()
            .setColor(0,0,1);

        obj.hydra = 0;

        obj.canvas._node.setValues({
                "name": "F16 HMD",
                    "size": [1024,1024], 
                    "view": [sx,sy],
                    "mipmapping": 0,
                    "additive-blend": 1# bool
                    });

        obj.svg.setTranslation (tran_x,tran_y);
        
        obj.off = 1;


        HUD_FONT = "LiberationFonts/LiberationMono-Bold.ttf";#"condensed.txf";  with condensed the FLYUP text was not displayed until minutes into flight, no clue why
        
        obj.window2 = obj.svg.createChild("text")
                .setText("BRAKES")
                .setTranslation(240,600)
                .setAlignment("right-bottom-baseline")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(fontSize, 1.1);
        obj.window3 = obj.svg.createChild("text")
                .setText("R 30")
                .setTranslation(800,670)
                .setAlignment("right-bottom-baseline")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(fontSize, 1.1);
        obj.window5 = obj.svg.createChild("text")
                .setText("05>07")
                .setTranslation(800,700)
                .setAlignment("right-bottom-baseline")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(fontSize, 1.1);
        obj.window9 = obj.svg.createChild("text")
                .setText("AMM9")
                .setTranslation(240,630)
                .setAlignment("right-bottom-baseline")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(fontSize, 1.1);
        obj.window12 = obj.svg.createChild("text")
                .setText("1.0")
                .setTranslation(240,240)
                .setAlignment("right-bottom-baseline")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(fontSize, 1.1);

        obj.total = [];        
        obj.scaling = [];      
        
        append(obj.total, obj.window2);
        append(obj.total, obj.window3);
        append(obj.total, obj.window5);
        append(obj.total, obj.window9);
        append(obj.total, obj.window12);
        append(obj.total, obj.mainCircle);
        
        obj.color = [0,1,0];

        

#
# Load the target symbosl.
        obj.max_symbols = 10;
        obj.tgt_symbols =  setsize([],obj.max_symbols);

        
        obj.custom = obj.svg.createChild("group");
        obj.flyup = obj.svg.createChild("text")
                .setText("FLYUP")
                .setTranslation(sx*0.5*uv_used,sy*0.30)
                .setAlignment("center-center")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(fontSize, 1.4);
        append(obj.total, obj.flyup);
        obj.stby = obj.svg.createChild("text")
                .setText("NO RAD")
                .setTranslation(sx*0.5*uv_used,sy*0.15)                
                .setAlignment("center-top")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(fontSize, 1.1);

          append(obj.total, obj.stby);
#        obj.raltR = obj.svg.createChild("text")
#                .setText("R")
#                .setTranslation(sx*1*0.675633-5,sy*0.45)
#                .setAlignment("right-center")
#                .setColor(0,1,0)
#                .setFont(HUD_FONT)
#                .setFontSize(9, 1.1);
#        obj.raltFrame = obj.svg.createChild("path")
#                .moveTo(sx*1*uv_x2-9,sy*0.45+5)
#                .horiz(-41)
#                .vert(-10)
#                .horiz(41)
#                .vert(10)
#                .setStrokeLineWidth(stroke1)
#                .hide()
#                .setColor(0,1,0);
#              append(obj.total, obj.raltFrame);
        obj.boreSymbol = obj.svg.createChild("path")
                .moveTo(472,512)
                .horiz(80)
                .moveTo(512,472)
                .vert(80)
                .setStrokeLineWidth(stroke1)
                .setColor(0,1,0);
            append(obj.total, obj.boreSymbol);
            
            
        
        #obj.speed_type = obj.svg.createChild("text")
        #        .setText("C")
        #        .setTranslation(4+0.25*sx*uv_used,sy*0.49)
        #        .setAlignment("left-bottom")
        #        .setColor(0,1,0,1)
        #        .setFont(HUD_FONT)
        #        .setFontSize(fontSize, 1.1);
        #obj.alt_type = obj.svg.createChild("text")
        #        .setText("R")
        #        .setTranslation(-4+0.75*sx*uv_used,sy*0.49)
        #        .setAlignment("right-bottom")
        #        .setColor(0,1,0,1)
        #        .setFont(HUD_FONT)
        #        .setFontSize(fontSize, 1.1);
        #append(obj.total, obj.speed_type);
        #append(obj.total, obj.alt_type);
        
        
        obj.speed_frame = obj.svg.createChild("path")
                .set("z-index",10001)
                .moveTo(8+0.20*sx*uv_used,sy*0.5)
                .lineTo(8+0.20*sx*uv_used-20,sy*0.5-24)
                .horiz(-100)
                .vert(48)
                .horiz(100)
                .lineTo(8+0.20*sx*uv_used,sy*0.5)
                .setStrokeLineWidth(stroke1)
                .setColor(1,0,0);
                append(obj.total, obj.speed_frame);
        obj.speed_curr = obj.svg.createChild("text")
                .set("z-index",10002)
                .setText("425")
                .setTranslation(0.18*sx*uv_used,sy*0.5)
                .setAlignment("right-center")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(fontSize, 1.1);
        append(obj.total, obj.speed_curr);
        
        obj.alt_frame = obj.svg.createChild("path")
                .set("z-index",10001)
                .moveTo(32-8+0.80*sx*uv_used-40,sy*0.5)
                .lineTo(32-8+0.80*sx*uv_used+20-40,sy*0.5-24)
                .horiz(112)
                .vert(48)
                .horiz(-112)
                .lineTo(32-8+0.80*sx*uv_used-40,sy*0.5)
                .setStrokeLineWidth(stroke1)
                .setColor(1,0,0);
                append(obj.total, obj.alt_frame);
        obj.alt_curr = obj.svg.createChild("text")
                .set("z-index",10002)
                .setText("88888")
                .setTranslation(16+0.82*sx*uv_used-40,sy*0.5+14)
                .setAlignment("left-bottom-baseline")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(fontSize, 1.1);
                append(obj.total, obj.alt_curr);
        
                #append(obj.total, obj.head_mask);
        obj.head_frame = obj.svg.createChild("path")
                .set("z-index",10001)
                .moveTo(40+0.50*sx*uv_used,sy*0.15-40)
                .vert(-40)
                .horiz(-80)
                .vert(40)
                .horiz(80)
                .setStrokeLineWidth(stroke1)
                .setColor(1,0,0);
                append(obj.total, obj.head_frame);
        obj.head_curr = obj.svg.createChild("text")
                .set("z-index",10002)
                .setText("360")
                .setTranslation(0.5*sx*uv_used,sy*0.15-48)
                .setAlignment("center-bottom")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(fontSize, 1.1);
                append(obj.total, obj.head_curr);
        
        
        
        var mr = 0.4;#milliradians
        obj.ASEC262 = obj.svg.createChild("path")#rdsearch (Allowable Steering Error Circle (ASEC))
            .moveTo(-262*mr,0)
            .arcSmallCW(262*mr,262*mr, 0, 262*mr*2, 0)
            .arcSmallCW(262*mr,262*mr, 0, -262*mr*2, 0)
            .setStrokeLineWidth(stroke1)
            .setColor(0,1,0).hide()
            .setTranslation(sx*0.5*uv_used,sy*0.25+262*mr*0.5);
            append(obj.total, obj.ASEC262);
        obj.ASC = obj.svg.createChild("path")# (Attack Steering Cue (ASC))
            .moveTo(-8*mr,0)
            .arcSmallCW(8*mr,8*mr, 0, 8*mr*2, 0)
            .arcSmallCW(8*mr,8*mr, 0, -8*mr*2, 0)
            .setStrokeLineWidth(stroke1)
            .setColor(0,1,0).hide();
            append(obj.total, obj.ASC);
        obj.ASEC100 = obj.svg.createChild("path")#irsearch
            .moveTo(-100*mr,0)
            .arcSmallCW(100*mr,100*mr, 0, 100*mr*2, 0)
            .arcSmallCW(100*mr,100*mr, 0, -100*mr*2, 0)
            .setStrokeLineWidth(stroke1)
            .setColor(0,1,0).hide()
            .setTranslation(sx*0.5*uv_used,sy*0.25);
            append(obj.total, obj.ASEC100);
        obj.ASEC120 = obj.svg.createChild("path")#rdlock
            .moveTo(-120*mr,0)
            .arcSmallCW(120*mr,120*mr, 0, 120*mr*2, 0)
            .arcSmallCW(120*mr,120*mr, 0, -120*mr*2, 0)
            .setStrokeLineWidth(stroke1)
            .setColor(0,1,0).hide()
            .setTranslation(sx*0.5*uv_used,sy*0.25);
            append(obj.total, obj.ASEC120);
        obj.ASEC65 = obj.svg.createChild("path")#irlock
            .moveTo(-65*mr,0)
            .arcSmallCW(65*mr,65*mr, 0, 65*mr*2, 0)
            .arcSmallCW(65*mr,65*mr, 0, -65*mr*2, 0)
            .setStrokeLineWidth(stroke1)
            .setColor(0,1,0).hide()
            .setTranslation(sx*0.5*uv_used,sy*0.25);
            append(obj.total, obj.ASEC65);
        obj.ASEC65Aspect  = obj.svg.createChild("path")#small triangle on ASEC that denotes aspect of target
            .moveTo(0,-65*mr)
            .lineTo(-5*mr,-75*mr)
            .lineTo(5*mr,-75*mr)
            .lineTo(0,-65*mr)
            .setStrokeLineWidth(stroke1)
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
            .setStrokeLineWidth(stroke1)
            .setColor(0,1,0)
            #.set("z-index",10500)
            .setTranslation(sx*0.5*uv_used,sy*0.25);
            append(obj.total, obj.ASEC120Aspect);
        
        
        mr = mr*1.5;#incorrect, but else in FG it will seem too small.

        obj.initUpdate =1;
        
        obj.alpha = getprop("f16/avionics/hud-sym");
        obj.power = getprop("f16/avionics/hud-power");

        

        obj.dlzX      = sx*uv_used*0.75-16;
        obj.dlzY      = sy*0.4;
        obj.dlzWidth  =  20;
        obj.dlzHeight = sy*0.25;
        obj.dlzLW     =   stroke1;
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
                .setFontSize(fontSize, 1.0);

        
        
        ############################## new center origin stuff that used hud math #################
        
        
        obj.centerOrigin = obj.svg.createChild("group");
        
        obj.flyupLeft    = obj.centerOrigin.createChild("path")
                            .lineTo(-50,-50)
                            .moveTo(0,0)
                            .lineTo(-50,50)
                            .setStrokeLineWidth(stroke1)
                            .setColor(0,1,0);
        obj.flyupRight  = obj.centerOrigin.createChild("path")
                            .lineTo(50,-50)
                            .moveTo(0,0)
                            .lineTo(50,50)
                            .setStrokeLineWidth(stroke1)
                            .setColor(0,1,0);
        append(obj.total, obj.flyupRight);
        append(obj.total, obj.flyupLeft);
        
                            
        
        var boxRadius = 30;
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
                .setStrokeLineWidth(stroke1)
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
            .setStrokeLineWidth(stroke1)
            .setColor(0,1,0);
        append(obj.total, obj.radarLock);
        obj.irLock = obj.centerOrigin.createChild("path")
            .moveTo(-boxRadius*1.5,0)
            .lineTo(0,-boxRadius*1.5)
            .lineTo(boxRadius*1.5,0)
            .lineTo(0,boxRadius*1.5)
            .lineTo(-boxRadius*1.5,0)
            .setStrokeLineWidth(stroke1)
            .setColor(0,1,0);
        append(obj.total, obj.irLock);
        obj.irBore = obj.centerOrigin.createChild("path")
            .moveTo(-boxRadius*0.75,0)
            .lineTo(0,-boxRadius*0.75)
            .lineTo(boxRadius*0.75,0)
            .lineTo(0,boxRadius*0.75)
            .lineTo(-boxRadius*0.75,0)
            .setStrokeLineWidth(stroke1)
            .setColor(0,1,0);
        append(obj.total, obj.irBore);
        obj.irSearch = obj.centerOrigin.createChild("path")
            .moveTo(-boxRadiusHalf*0.75,0)
            .lineTo(0,-boxRadiusHalf*0.75)
            .lineTo(boxRadiusHalf*0.75,0)
            .lineTo(0,boxRadiusHalf*0.75)
            .lineTo(-boxRadiusHalf*0.75,0)
            .setStrokeLineWidth(stroke1)
            .setColor(0,1,0);
        append(obj.total, obj.irSearch);
        obj.rdrBore = obj.centerOrigin.createChild("path")
#            .moveTo(-boxRadiusHalf*4,0)
 #           .horiz(boxRadius*4)
#            .moveTo(0,-boxRadiusHalf*6)
#            .vert(boxRadius*6)
            .moveTo(-boxRadiusHalf*4,0)
            .arcSmallCW(boxRadiusHalf*4,boxRadius*4, 0, boxRadiusHalf*4*2, 0)
            .arcSmallCW(boxRadiusHalf*4,boxRadius*4, 0, -boxRadiusHalf*4*2, 0)
            .setStrokeLineWidth(stroke1)
            .hide()
            .setColor(0,1,0);
        append(obj.total, obj.rdrBore);
        
        obj.target_locked = obj.centerOrigin.createChild("path")
            .moveTo(-boxRadius,-boxRadius)
            .vert(boxRadius*2)
            .horiz(boxRadius*2)
            .vert(-boxRadius*2)
            .horiz(-boxRadius*2)
            .setStrokeLineWidth(stroke1)
            .hide()
            .setColor(0,1,0);
        append(obj.total, obj.target_locked);
        obj.locatorAngle = obj.svg.createChild("text")
                .setText("0")
                .setAlignment("right-center")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(fontSize, 1.1);
        append(obj.total, obj.locatorAngle);
        obj.locatorLine = obj.centerOrigin.createChild("path")
                .moveTo(0,0)
                #.horiz(10)
                .vert(-30)
                .setStrokeLineWidth(stroke1)
                .setColor(0,1,0);
        append(obj.total, obj.locatorLine);
        
        
        
        

        

        
        
        obj.hidingScales = 0;
        
        input2 = {
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
                 flap_pos_deg              : "/fdm/jsbsim/fcs/flap-pos-deg",
                 gear_down                 : "/controls/gear/gear-down",
                 heading                   : "/orientation/heading-deg",
                 headingMag                : "/orientation/heading-magnetic-deg",
                 useMag:                     "/instrumentation/heading-indicator/use-mag-in-hud",
                 mach                      : "/instrumentation/airspeed-indicator/indicated-mach",
                 measured_altitude         : "/instrumentation/altimeter/indicated-altitude-ft",
                 pitch                     : "/orientation/pitch-deg",
                 roll                      : "/orientation/roll-deg",
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
                 bingo                     : "f16/avionics/bingo",
                 alow                      : "f16/settings/cara-alow",
                 altitude_agl_ft           : "position/altitude-agl-ft",
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
                 data                      : "instrumentation/datalink/data",
                };

        #foreach (var name; keys(input)) {
        #    emesary.GlobalTransmitter.NotifyAll(notifications.FrameNotificationAddProperty.new("HUD", name, input[name]));
        #}

        #
        # set the update list - using the update manager to improve the performance
        # of the HUD update - without this there was a drop of 20fps (when running at 60fps)
        obj.update_items = [
            props.UpdateManager.FromHashList(["hud_serviceable", "hud_display", "hmcs_sym", "hud_power"], 0.1, func(hdp)#changed to 0.1, this function is VERY heavy to run.
                                      {
# print("HUD hud_serviceable=", hdp.hud_serviceable," display=", hdp.hud_display, " brt=", hdp.hud_brightness, " power=", hdp.hud_power);
                                            
                                          if (!hdp.hud_display or !hdp.hud_serviceable) {
                                            obj.color = [0.3,1,0.3,0];
                                            foreach(item;obj.total) {
                                              item.setColor(obj.color);
                                            }
                                            obj.ASEC120Aspect.setColorFill(obj.color);
                                            obj.ASEC65Aspect.setColorFill(obj.color);
                                          } elsif (hdp.hmcs_sym != nil and hdp.hud_power != nil) {
                                            obj.color = [0.3,1,0.3,hdp.hmcs_sym * hdp.hud_power];
                                            foreach(item;obj.total) {
                                              item.setColor(obj.color);
                                            }
                                            obj.ASEC120Aspect.setColorFill(obj.color);
                                            obj.ASEC65Aspect.setColorFill(obj.color);
                                          }
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
                                          hdp.timeToRelease = nil;
                                          hdp.CCRP_active = 0;
                                      }),
            props.UpdateManager.FromHashList(["texUp","gear_down"], 0.01, func(val)
                                             {
                                                 if (val.gear_down) {
                                                     #obj.boreSymbol.hide();
                                                 } else {
                                                     #obj.boreSymbol.setTranslation(obj.sx/2,obj.sy-obj.texels_up_into_hud);
                                                     #obj.eegsGroup.setTranslation(obj.sx/2,obj.sy-obj.texels_up_into_hud);
                                                     #printf("bore %d,%d",obj.sx/2,obj.sy-obj.texels_up_into_hud);
                                                     #obj.locatorAngle.setTranslation(obj.sx/2-10,obj.sy-obj.texels_up_into_hud);
                                                     #obj.boreSymbol.show();
                                                 }
                                      }),
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

                                          if(hdp.altSwitch == 0 and hdp.cara and obj.altScaleMode == 0) {
                                              #obj.ralt.setText(sprintf("AR %s", obj.getAltTxt(obj.agl)));
                                          } elsif(hdp.cara and obj.altScaleMode == 0) {
                                              #obj.ralt.setText(sprintf("R %s", obj.getAltTxt(obj.agl)));
                                          } else {
                                              #obj.ralt.setText("    ,   ");
                                          }
                                      }),
            props.UpdateManager.FromHashList(["calibrated", "GND_SPD", "HUD_VEL", "gear_down"], 0.5, func(hdp)
                                      {   
                                          # the real F-16 has calibrated airspeed as default in HUD.
                                          var pitot = hdp.servPitot and hdp.servStatic;
                                            if (hdp.servSpeed) {
                                                obj.speed_curr.setText(!pitot?""~0:sprintf("%d",hdp.calibrated));
                                            }
                                      }),
            props.UpdateManager.FromHashList(["altitude_agl_ft","cara","measured_altitude","altSwitch","alow","dgft"], 1.0, func(hdp)
                                      {
                                          
                                            # baro scale
                                            
                                            obj.alt_curr.setText(obj.getAltTxt(hdp.measured_altitude));
                                            

                                      }),
            props.UpdateManager.FromHashList(["Nz","nReset"], 0.1, func(hdp)
                                      {
                                          obj.window12.setText(sprintf("%.1f", hdp.Nz));
                                          obj.window12.show();
                                      }),
            props.UpdateManager.FromHashList(["heading", "headingMag", "useMag","gear_down","hmdH","hmdP","roll","pitch"], 0.1, func(hdp)
                                      {
                                          if (hdp.servHead) {
                                            var lookDir = vector.Math.yawPitchVector(hdp.hmdH,hdp.hmdP,[1,0,0]);
                                            lookDir = vector.Math.yawPitchRollVector(-hdp.heading, hdp.pitch, hdp.roll, lookDir);
                                            obj.lookEuler = vector.Math.cartesianToEuler(lookDir);
                                            var lookingAt = obj.lookEuler[0]==nil?hdp.heading:obj.lookEuler[0];
                                            lookingAt += (hdp.headingMag-hdp.heading);#convert to magn
                                            obj.head_curr.setText(sprintf("%03d",geo.normdeg(lookingAt)));
                                          }
                                          
                                      }
                                            ),
            props.UpdateManager.FromHashList(["hmdH","hmdP"], 0.1, func(hdp)
                                      {
                                          var currLimit = 0;
                                          var hd = math.abs(geo.normdeg180(hdp.hmdH));
                                          
                                          if (hd < 5) currLimit = 1.5;
                                          elsif (hd < 15) currLimit = -14;
                                          elsif (hd < 30) currLimit = -30;
                                          else currLimit = -50;
                                          
                                          if (hdp.hmdP < currLimit) obj.off = 1;
                                          else 
                                            obj.off = 0;
                                          
                                      }
                                            ),
            props.UpdateManager.FromHashList(["time_until_crash","vne","warn", "elapsed", "data"], 0.05, func(hdp)
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
                                                 } elsif (hdp.data != 0) {
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
                                            ),
            props.UpdateManager.FromHashList(["standby", "data"], 0.5, func(hdp)
                                             {
                                                 if (hdp.data != 0) {
                                                     obj.stby.setText("MKPT"~sprintf("%03d",hdp.data));
                                                     obj.stby.setTranslation(obj.sx/2,obj.sy-obj.texels_up_into_hud+7+75);
                                                     obj.stby.show();
                                                 } elsif (hdp.standby) {
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
                                                     if (hdp.CCRP_active > 0) {
                                                        submode = "CCRP";
                                                     } elsif (obj.showmeCCIP) {
                                                        submode = "CCIP";
                                                     #} elsif (obj.eegsLoop.isRunning) {
                                                     #   submode = obj.hydra?"CCIP":(hdp.strf?"STRF":"EEGS");
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
                        props.UpdateManager.FromHashValue("window5_txt", nil, func(txt)
                                      {
                                          if (txt != nil and txt != ""){
                                              obj.window5.show();
                                              obj.window5.setText(txt);
                                          }
                                          else
                                            obj.window5.hide();

                                      }),
                        props.UpdateManager.FromHashValue("window3_txt", nil, func(txt)
                                      {
                                          if (txt != nil and txt != ""){
                                              obj.window3.show();
                                              obj.window3.setText(txt);
                                          }
                                          else
                                            obj.window3.hide();

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

        ];
        
        
        
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
        if (hdp.hmcs_sym == 0 or hdp.view_number != 0) {
            me.svg.hide();
            setprop("payload/armament/hmd-active", 0);
            return;
        }
        if (me.off and !me.initUpdate) {
            me.svg.hide();
            foreach(var update_item; me.update_items)
            {
                update_item.update(hdp);
            }
            setprop("payload/armament/hmd-active", 0);
            return;
        }
        setprop("payload/armament/hmd-active", 1);
        setprop("payload/armament/hmd-horiz-deg", geo.normdeg180(-hdp.hmdH));
        setprop("payload/armament/hmd-vert-deg", hdp.hmdP);

        me.svg.show();

        setprop("sim/rendering/als-filters/use-night-vision", 0);# NVG not allowed while using HMD
        
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
            me.frac_up_the_hud = me.bore_over_bottom / me.Hz_height;
            me.texels_up_into_hud = me.frac_up_the_hud * me.sy;#sy default is 260
        }
        
        me.Vy   =    hdp.current_view_x_offset_m;
            
        me.pixelPerMeterX = (340*uv_used)/(semi_width*2);
        me.pixelPerMeterY = 260/(me.Hz_t-me.Hz_b);
        
        
        me.centerOrigin.setTranslation(512, 512);
        me.custom.update();
        me.centerOrigin.update();
        me.svg.update();
        


        



# velocity vector
        #340,260
        # semi_width*2 = width of HUD  = 0.15627m
        
        me.submode = 0;
        
        
        

        # UV mapped to x: uv_x1 to uv_x2
        me.averageDegX = math.atan2(semi_width*1.0, me.Vx-me.Hx_m)*R2D;
        me.averageDegY = math.atan2((me.Hz_t-me.Hz_b)*0.5, me.Vx-me.Hx_m)*R2D;
        me.texelPerDegreeX = me.pixelPerMeterX*(((me.Vx-me.Hx_m)*math.tan(me.averageDegX*D2R))/me.averageDegX);
        me.texelPerDegreeY = me.pixelPerMeterY*(((me.Vx-me.Hx_m)*math.tan(me.averageDegY*D2R))/me.averageDegY);

        me.hydra = 0;

        # part2. update display, first with the update managed items
        var showASC = 0;
        me.ALOW_top = 0;
        me.TA_text = "";
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
            var currASEC = nil;
        }
                   


        me.locatorLineShow = 0;
#        if (hdp.FrameCount == 1 or hdp.FrameCount == 3 or me.initUpdate == 1) {
            me.target_idx = 0;
            me.designated = 0;
            
        me.target_locked.setVisible(0);

        me.irL = 0;#IR lock
        me.irS = 0;#IR medium circle
        me.rdL = 0;
        me.irT = 0;#IR triangle aspect indicator
        me.rdT = 0;
        me.irB = 0;#IR search bore
        #printf("%d %d %d %s",hdp.master_arm,pylons.fcs != nil,pylons.fcs.getAmmo(),hdp.weapon_selected);
        if(hdp.master_arm and pylons.fcs != nil and pylons.fcs.getAmmo() > 0) {
            hdp.weapon_selected = pylons.fcs.selectedType;
            if (0 and hdp.weapon_selected == "AIM-120" or hdp.weapon_selected == "AIM-7") {
                if (!pylons.fcs.isLock()) {
                    me.radarLock.setTranslation(0, -me.sy*0.25+262*0.3*0.5);
                    me.rdL = 1;
                }                
            } elsif (pylons.fcs.isCaged() and hdp.weapon_selected == "AIM-9" or hdp.weapon_selected == "IRIS-T") {
                #if (pylons.bore > 0) {
                    var aim = pylons.fcs.getSelectedWeapon();
                    if (aim != nil) {
                        #me.submode = 1;
                        var coords = aim.getSeekerInfo();
                        if (coords != nil) {
                            me.echoPos = f16.HudMath.getDevFromHMD(coords[0], coords[1], -hdp.hmdH, hdp.hmdP);
                            me.echoPos[0] = geo.normdeg180(me.echoPos[0]);
                            me.echoPos[0] = (512/0.025)*(math.tan(math.clamp(me.echoPos[0],-89,89)*D2R))*0.2;#0.2m from eye, 0.025 = 512 (should be 0.1385 from eye instead to be like real f16)
                            me.echoPos[1] = -(512/0.025)*(math.tan(math.clamp(me.echoPos[1],-89,89)*D2R))*0.2;#0.2m from eye, 0.025 = 512
                            me.irBore.setTranslation(me.echoPos);
                            me.irB = 1;
                        }#atan((0.025*500)/(0.2*512)) = radius_fg = atan(12.5/102.4) = 6.96 degs => 13.92 deg diam
                    }#atan((0.025*500)/(x*512)) => 12.5/tan(10)*512 = x
                #} else {
                #    me.irS = 0;
                    #me.irSearch.setTranslation(0, -me.sy*0.25);
                #}
            } elsif (!pylons.fcs.isCaged() and hdp.weapon_selected == "AIM-9" or hdp.weapon_selected == "IRIS-T") {
                var aim = pylons.fcs.getSelectedWeapon();
                if (aim != nil) {
                    var coords = aim.getSeekerInfo();
                    if (coords != nil) {
                        me.echoPos = f16.HudMath.getDevFromHMD(coords[0], coords[1], -hdp.hmdH, hdp.hmdP);
                        me.echoPos[0] = geo.normdeg180(me.echoPos[0]);
                        me.echoPos[0] = (512/0.025)*(math.tan(math.clamp(me.echoPos[0],-89,89)*D2R))*0.2;#0.2m from eye, 0.025 = 512
                        me.echoPos[1] = -(512/0.025)*(math.tan(math.clamp(me.echoPos[1],-89,89)*D2R))*0.2;#0.2m from eye, 0.025 = 512
                        me.irLock.setTranslation(me.echoPos);
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
                if (f16.rdrMode == f16.RADAR_MODE_SEA and me.u.get_type() != armament.MARINE) {
                    continue;
                }
                if (f16.rdrMode == f16.RADAR_MODE_CRM and me.u.get_type() == armament.MARINE) {
                    continue;
                }
                if (hdp.active_u == nil or me.u.Callsign.getValue() != hdp.active_u.Callsign.getValue()) {
                    continue;
                }
                if (me.u.get_display()) {
                    if (me.u.Callsign != nil)
                      me.callsign = me.u.Callsign.getValue();
                    me.model = "XX";

                    if (me.u.ModelType != "")
                      me.model = me.u.ModelType;
                    
                    if (me.target_idx < me.max_symbols or me.designatedDistanceFT == nil) {
                        me.echoPos = f16.HudMath.getDevFromCoord(me.u.get_Coord(0), hdp.hmdH, hdp.hmdP, hdp, geo.viewer_position());
                        #print(me.echoPos[0],",",me.echoPos[1],"    ", hdp.hmdH, "," ,hdp.hmdP);
                        me.echoPos[0] = geo.normdeg180(me.echoPos[0]);
                        #print("    ",me.echoPos[0]);
                        me.echoPos[0] = (512/0.025)*(math.tan(math.clamp(me.echoPos[0],-89,89)*D2R))*0.2;#0.2m from eye, 0.025 = 512
                        me.echoPos[1] = -(512/0.025)*(math.tan(math.clamp(me.echoPos[1],-89,89)*D2R))*0.2;#0.2m from eye, 0.025 = 512
                        
                        if (me.target_idx < me.max_symbols) {
                            me.tgt = me.tgt_symbols[me.target_idx];
                        } else {
                            me.tgt = nil;
                        }
                        if (me.tgt != nil or me.designatedDistanceFT == nil) {
                            if (me.tgt != nil) {
                                me.tgt.setVisible(me.u.get_display());
                            }
                            me.clamped = math.sqrt(me.echoPos[0]*me.echoPos[0]+me.echoPos[1]*me.echoPos[1]) > 500;

                            if (me.clamped) {
                                me.clampAmount = 500/math.sqrt(me.echoPos[0]*me.echoPos[0]+me.echoPos[1]*me.echoPos[1]);
                                me.echoPos[0] *= me.clampAmount;
                                me.echoPos[1] *= me.clampAmount;
                                me.tgt.setStrokeDashArray([7,7]);
                            } else {
                                me.tgt.setStrokeDashArray([1]);
                            }
                            
                            if (hdp.active_u != nil and hdp.active_u.Callsign != nil and me.u.Callsign != nil and me.u.Callsign.getValue() == hdp.active_u.Callsign.getValue()) {
                                me.designatedDistanceFT = hdp.active_u.get_Coord().direct_distance_to(geo.aircraft_position())*M2FT;
                                me.target_locked.setVisible(1);
                                if (me.tgt != nil) {
                                    me.tgt.hide();
                                }
                                
                                me.target_locked.setTranslation (me.echoPos);
                                if (me.clamped) {
                                    me.target_locked.setStrokeDashArray([7,7]);
                                } else {
                                    me.target_locked.setStrokeDashArray([1]);
                                }
                                me.target_locked.update();
                                if (0 and currASEC != nil) {
                                    # disabled for now as it has issues
                                    me.cue = nil;
                                    call(func {me.cue = hdp.weapn.getIdealFireSolution();},[], nil, nil, var err = []);
                                    if (me.cue != nil) {
                                        me.ascpixel = me.cue[1]*hmd.HudMath.getPixelPerDegreeAvg(2);
                                        me.ascPos = hmd.HudMath.getPosFromDegs(me.echoPos[2], me.echoPos[3]);
                                        me.ascDist = math.sqrt(math.pow(me.ascPos[0]+math.cos(me.cue[0]*D2R)*me.ascpixel,2)+math.pow(me.ascPos[1]+math.sin(me.cue[0]*D2R)*me.ascpixel,2));
                                        me.ascReduce = me.ascDist > me.sx*0.20?me.sx*0.20/me.ascDist:1;
                                        me.ASC.setTranslation(currASEC[0]+me.ascReduce*(me.ascPos[0]+math.cos(me.cue[0]*D2R)*me.ascpixel),currASEC[1]+me.ascReduce*(me.ascPos[1]+math.sin(me.cue[0]*D2R)*me.ascpixel));
                                        showASC = 1;
                                    }
                                }
                                if (0 and pylons.fcs != nil and pylons.fcs.isLock()) {
                                    #me.target_locked.setRotation(45*D2R);
                                    if (hdp.weapon_selected == "AIM-120" or hdp.weapon_selected == "AIM-7" or hdp.weapon_selected == "AIM-9" or hdp.weapon_selected == "IRIS-T") {
                                        var aim = pylons.fcs.getSelectedWeapon();
                                        if (aim != nil) {
                                            var coords = aim.getSeekerInfo();
                                            if (coords != nil) {
                                                me.seekPos = hmd.HudMath.getCenterPosFromDegs(coords[0],coords[1]);
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
                                    me.locatorLineShow = 0;
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
                    .setColor(me.color);
            me.dlz2.update();
            me.dlz.show();
        }

        me.radarLock.setVisible(0 and me.rdL);
        me.irSearch.setVisible(me.irS);
        me.irLock.setVisible(me.irL);
        me.irBore.setVisible(me.irB);
        me.ASEC120Aspect.setVisible(0 and me.rdT);
        me.ASEC65Aspect.setVisible(0 and me.irT);
        me.radarLock.update();
        me.irLock.update();
        me.irSearch.update();

        

        


        me.initUpdate = 0;

        hdp.submode = me.submode;

        hdp.window5_txt = f16.transfer_stpt;
        hdp.window3_txt = f16.transfer_dist;
        hdp.window9_txt = f16.transfer_arms;
        hdp.window2_txt = f16.transfer_mode;
        hdp.window12_txt = f16.transfer_g;
        
        foreach(var update_item; me.update_items)
        {
            update_item.update(hdp);
        }
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


    
    
    makeVector: func (siz,content) {
        var vec = setsize([],siz*2);
        var k = 0;
        while(k<siz*2) {
            vec[k] = content;
            k += 1;
        }
        return vec;
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


    
    extrapolate: func (x, x1, x2, y1, y2) {
        return y1 + ((x - x1) / (x2 - x1)) * (y2 - y1);
    },
    clamp: func(v, min, max) { v < min ? min : v > max ? max : v },
    list: [],
};

var F16HMDRecipient = 
{
    new: func(_ident)
    {
        var new_class = emesary.Recipient.new(_ident~".HMD");
        new_class.HUDobj = F16_HMD.new("canvasHMCS", 1024,1024, 0,0);

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
                
                me.HUDobj.update(notification);
                return emesary.Transmitter.ReceiptStatus_OK;
            }
            return emesary.Transmitter.ReceiptStatus_NotProcessed;
        };
        return new_class;
    },
    del: func()
    {
        HUDobj.canvas.del();
        emesary.GlobalTransmitter.DeRegister(f16_hmd);
    },
};

var f16_hmd = nil;
var HUDobj = nil;

var main = func (module) {
    var t = maketimer(1,main2);
    t.singleShot = 1;
    t.start();
}

var main2 = func () {
    f16_hmd = F16HMDRecipient.new("F16-HMD");
    HUDobj = f16_hmd.HUDobj;
    emesary.GlobalTransmitter.Register(f16_hmd);
}

var unload = func {
    if (f16_hmd != nil) {
        F16HMDRecipient.del();
        f16_hmd = nil;
        HUDobj = nil;
    }
}

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