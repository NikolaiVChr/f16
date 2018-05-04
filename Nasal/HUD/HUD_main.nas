# Canvas HUD
# ---------------------------
# HUD uses data in the frame notification
# HUD is in two parts so we have a single class that we can instantiate
# twice on for each combiner pane
# ---------------------------
# Richard Harrison (rjh@zaretto.com) 2016-07-01  - based on F-15 HUD
# ---------------------------

var ht_xcf =  1750;# 340pixels / 0.15m = 2267 texels/meter (in an ideal world where canvas is UV mapped to edges of texture)
var ht_ycf = -1614;# 260pixels / 0.16m
var ht_xco =  15;
var ht_yco = -30;
var ht_debug = 0;

var pitch_offset = 12;
var pitch_factor = 19.8;
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
                    "mipmapping": 0 # mipmapping will make the HUD text blurry on smaller screens     
                    });  

        obj.sy = sy;                        
        obj.sx = sx*0.695633;
                          
        obj.canvas.addPlacement({"node": canvas_item});
        obj.canvas.setColorBackground(0.30, 1, 0.3, 0.00);

# Create a group for the parsed elements
        obj.svg = obj.canvas.createGroup();
 
# Parse an SVG file and add the parsed elements to the given group
        #print("HUD Parse SVG ",
            canvas.parsesvg(obj.svg, svgname);
            #);

        obj.canvas._node.setValues({
                "name": "F16 HUD",
                    "size": [1024,1024], 
                    "view": [sx,sy],
                    "mipmapping": 0     
                    });

        obj.svg.setTranslation (tran_x,tran_y);

        obj.ladder = obj.get_element("ladder");

        var cent = obj.ladder.getCenter();
        obj.ladder_center = cent;

        obj.VV = obj.get_element("VelocityVector");
        obj.heading_tape = obj.get_element("heading-scale");
        obj.roll_pointer = obj.get_element("roll-pointer");
        obj.alt_range = obj.get_element("alt_range");
        obj.ias_range = obj.get_element("ias_range");
        obj.oldBore = obj.get_element("path4530-6");
        obj.target_locked = obj.get_element("target_locked");
        obj.target_locked.setVisible(0);

        obj.window1 = obj.get_text("window1", "condensed.txf",9,1.4);
        obj.window2 = obj.get_text("window2", "condensed.txf",9,1.4);
        obj.window3 = obj.get_text("window3", "condensed.txf",9,1.4);
        obj.window4 = obj.get_text("window4", "condensed.txf",9,1.4);
        obj.window5 = obj.get_text("window5", "condensed.txf",9,1.4);
        obj.window6 = obj.get_text("window6", "condensed.txf",9,1.4);
        obj.window7 = obj.get_text("window7", "condensed.txf",9,1.4);
        obj.window8 = obj.get_text("window8", "condensed.txf",9,1.4);
        obj.window9 = obj.get_text("window9", "condensed.txf",9,1.4);


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
#                print("HUD: loaded ",name);
            }
            else
                print("HUD: could not locate ",name);
        }

        obj.custom = obj.canvas.createGroup();
        obj.flyup = obj.svg.createChild("text")
                .setText("FLYUP")
                .setTranslation(sx*0.5*0.695633,sy*0.25)
                .setAlignment("center-center")
                .setColor(0,1,0)
                .setFontSize(15, 1.0)
                .hide();
        obj.ralt = obj.svg.createChild("text")
                .setText("R 00000 ")
                .setTranslation(sx*1*0.695633-5,sy*0.45)
                .setAlignment("right-center")
                .setColor(0,1,0)
                .setFontSize(10, 1.0);
        obj.raltFrame = obj.svg.createChild("path")
                .moveTo(sx*1*0.695633-10,sy*0.45+5)
                .horiz(-40)
                .vert(-10)
                .horiz(40)
                .vert(10)
                .setStrokeLineWidth(1)
                .setColor(0,1,0);
        obj.boreSymbol = obj.svg.createChild("path")
                .moveTo(-5,0)
                .horiz(10)
                .moveTo(0,-5)
                .vert(10)
                .setStrokeLineWidth(1)
                .setColor(0,1,0);
        obj.trackLine = obj.svg.createChild("path")
                .moveTo(0,0)
                #.horiz(10)
                .vert(-30)
                .setStrokeLineWidth(1)
                .setColor(0,1,0);
        obj.initUpdate =1;
        obj.svg.setColor(0.3,1,0.3);
        obj.alpha = getprop("f16/avionics/hud-brt");
		return obj;
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

    develev_to_devroll : func(notification, dev_rad, elev_rad)
    {
        var eye_hud_m          = 0.5123;
        var hud_position       = 4.6429;#4.61428;#4.65415;#5.66824; # really -5.6 but avoiding more complex equations by being optimal with the signs.
        var hud_radius_m       = 0.08429;
        var clamped = 0;

        eye_hud_m = hud_position + getprop("sim/current-view/z-offset-m"); # optimised for signs so we get a positive distance.
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
        var clamp = hud_radius_m;

# squeeze the top of the display area for egg shaped HUD limits.
#	if ( abs_combined_dev_deg >= 0 and abs_combined_dev_deg < 90 ) {
#		var coef = ( 90 - abs_combined_dev_deg ) * 0.00075;
#		if ( coef > 0.050 ) { coef = 0.050 }
#		clamp -= coef; 
        #	}
        if ( combined_dev_length > clamp ) {
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

#
#
#
    update : func(hdp) {
        me.roll_rad = -hdp.roll*D2R;

        if (hdp.FrameCount == 2 or me.initUpdate == 1) {
            var alpha = getprop("f16/avionics/hud-brt");
            if (alpha != me.alpha) {
                me.alpha = alpha;
                me.svg.setColor(0.3,1,0.3,alpha);
            }
            # calc of pitch_offset (compensates for AC3D model translated and rotated when loaded. Also semi compensates for HUD being at an angle.)
            me.Hz_b =    0.801701;# HUD position inside ac model after it is loaded, translated (0.08m) and rotated (0.7d).
            me.Hz_t =    0.976668;
            me.Hx_m =   -4.6429;# HUD median X pos
            me.Vz   =    getprop("sim/current-view/y-offset-m"); # view Z position (0.94 meter per default)
            me.Vx   =    getprop("sim/current-view/z-offset-m"); # view X position (0.94 meter per default)

            me.bore_over_bottom = me.Vz - me.Hz_b;
            me.Hz_height        = me.Hz_t-me.Hz_b;
            me.hozizon_line_offset_from_middle_in_svg = 0.137; #horizline and radar echoes fraction up from middle
            me.frac_up_the_hud = me.bore_over_bottom / me.Hz_height;
            me.texels_up_into_hud = me.frac_up_the_hud * me.sy;#sy default is 260
            me.texels_over_middle = me.texels_up_into_hud - me.sy/2;


            pitch_offset = -me.texels_over_middle + me.hozizon_line_offset_from_middle_in_svg*me.sy;
            me.boreSymbol.setTranslation(me.sx/2,me.sy-me.texels_up_into_hud);
            me.oldBore.hide();
        }

#pitch ladder
        
        me.ladder.setTranslation (0.0, hdp.pitch * pitch_factor+pitch_offset);                                           
        me.ladder.setCenter (me.ladder_center[0], me.ladder_center[1] - hdp.pitch * pitch_factor);
        me.ladder.setRotation (me.roll_rad);
        me.ladder.update();
        me.ttc = getprop("instrumentation/radar/time-till-crash");
        if (me.ttc != nil and me.ttc>0 and me.ttc<10) {
            me.flyup.show();
        } else {
            me.flyup.hide();
        }
  
# velocity vector
        #340,260
        # 0.078135*2 = width of HUD  = 0.15627m
        me.pixelPerMeterX = (340*0.695633)/0.15627;
        me.pixelPerMeterY = 260/(me.Hz_t-me.Hz_b);
        # UV mapped to x: 0-0.695633
        me.averageDegX = math.atan2(0.078135*0.5, me.Vx-me.Hx_m)*R2D;
        me.averageDegY = math.atan2((me.Hz_t-me.Hz_b)*0.25, me.Vx-me.Hx_m)*R2D;
        me.texelPerDegreeX = me.pixelPerMeterX*(((me.Vx-me.Hx_m)*math.tan(me.averageDegX*D2R))/me.averageDegX);
        me.texelPerDegreeY = me.pixelPerMeterY*(((me.Vx-me.Hx_m)*math.tan(me.averageDegY*D2R))/me.averageDegY);
        # the Y position is still not accurate due to HUD being at an angle, but will have to do.
        me.VV.setTranslation (hdp.VV_x*0.1*me.texelPerDegreeX, hdp.VV_y*0.1*me.texelPerDegreeY+pitch_offset);# the 0.1 is to cancel out the factor applied in exec.nas
        me.VV.update();

#Altitude
        me.alt_range.setTranslation(0, hdp.measured_altitude * alt_range_factor);

# IAS
        me.ias_range.setTranslation(0, hdp.IAS * ias_range_factor);
        if (hdp.FrameCount == 2 or me.initUpdate == 1) {
            me.agl=getprop("position/altitude-agl-ft");
            if(me.agl < 13000) {
                me.ralt.setText(sprintf("R %05d ",me.agl));
                me.ralt.show();
                me.raltFrame.show();
            } else {
                me.ralt.hide();
                me.raltFrame.hide();
            }

            if(hdp.brake_parking)
              {
                me.window2.setVisible(1);
                me.window2.setText("BRAKES");
            }
            elsif (hdp.flap_pos_deg > 0 or hdp.gear_down)
            {
                me.window2.setVisible(1);
                me.gd = "";
                if (hdp.gear_down)
                    me.gd = " G";
                me.window2.setText(sprintf("F %d %s",hdp.flap_pos_deg,me.gd));
            } elsif (getprop("controls/armament/master-arm")) {
                me.window2.setText("ARM");
                me.window2.setVisible(1);
            } else {
                me.window2.setText("NAV");
                me.window2.setVisible(1);
            }
            me.win5 = 0;
            if(getprop("controls/armament/master-arm"))
            {
                me.weap = pylons.fcs.selectedType;
                me.window7.setVisible(1);
                
                me.txt = "";
                if (me.weap != nil)
                {
                    if (me.weap == "20mm Cannon") {
                        me.txt = sprintf("%3d", pylons.fcs.getAmmo());
                    } elsif (me.weap == "AIM-9") {
                        me.txt = sprintf("%dSRM", pylons.fcs.getAmmo());
                    } elsif (me.weap == "AIM-120") {
                        me.txt = sprintf("%dLRM", pylons.fcs.getAmmo());
                    } elsif (me.weap == "AIM-7") {
                        me.txt = sprintf("%dMRM", pylons.fcs.getAmmo());
                    } elsif (me.weap == "GBU-12") {
                        me.txt = sprintf("%dGBU", pylons.fcs.getAmmo());
                    } elsif (me.weap == "AGM-65") {
                        me.txt = sprintf("%dAGM", pylons.fcs.getAmmo());
                    }
                }
                me.window7.setText(me.txt);
                if (awg_9.active_u != nil)
                {
                    if (awg_9.active_u.Callsign != nil) {
                        me.window3.setText(awg_9.active_u.Callsign.getValue());
                        me.window3.show();
                    } else {
                        me.window3.hide();
                    }
                    me.model = "XX";
                    if (awg_9.active_u.ModelType != "")
                        me.model = awg_9.active_u.ModelType;

    #        var w2 = sprintf("%-4d", awg_9.active_u.get_closure_rate());
    #        w3_22 = sprintf("%3d-%1.1f %.5s %.4s",awg_9.active_u.get_bearing(), awg_9.active_u.get_range(), callsign, model);
    #
    #
    #these labels aren't correct - but we don't have a full simulation of the targetting and missiles so 
    #have no real idea on the details of how this works.
                    if (awg_9.active_u.get_display() == 0) {
                        me.window4.setText("");
                        me.window5.setText("");
                    } else {
                        me.window4.setText(sprintf("RNG %3.1f", awg_9.active_u.get_range()));
                        me.window5.setText(sprintf("CLO %-3d", awg_9.active_u.get_closure_rate()));
                    }
                    me.window4.show();
                    me.win5 = 1;
                    me.window6.setText(me.model);
                    me.window6.show(); # SRM UNCAGE / TARGET ASPECT
                }
                else {
                    me.window3.hide();
                    me.window4.hide();
                    me.window6.hide();
                }
            }
            else
            {
                me.window7.setVisible(0);
                #me.window3.setText("NAV");
                #if (hdp.nav_range != "")
                #  me.window3.setText("NAV");
                #else
                #  me.window3.setText("");
                me.window3.hide();
                me.window4.setText(hdp.nav_range);
                me.window4.show();
                me.window5.setText(hdp.hud_window5);
                me.window6.hide(); # SRM UNCAGE / TARGET ASPECT
            }

            if (hdp.range_rate != nil)
            {
                me.window1.setVisible(1);
                me.window1.setText("");
            }
            else
                me.window1.setVisible(0);
      
            me.window8.setText(sprintf("%3.1f", hdp.Nz));
            me.window9.setText(sprintf("AOA %d",hdp.alpha));
            if(me.win5 == 0) {
                me.window5.setText(sprintf("M %1.3f",hdp.mach));
            }
        }
        if (hdp.heading < 180)
            me.heading_tape_position = -hdp.heading*54/10;
        else
            me.heading_tape_position = (360-hdp.heading)*54/10;
         
        me.heading_tape.setTranslation (me.heading_tape_position,0);
        me.roll_pointer.setRotation (me.roll_rad);
        me.trackLineShow = 0;
#        if (hdp.FrameCount == 1 or hdp.FrameCount == 3 or me.initUpdate == 1) {
            me.target_idx = 0;
            me.designated = 0;
            ht_yco = pitch_offset;
            ht_xco = 0;
            ht_xcf = me.pixelPerMeterX;
            ht_ycf = -me.pixelPerMeterY;
            
            me.target_locked.setVisible(0);
            foreach( me.u; awg_9.tgts_list ) 
            {
                me.callsign = "XX";
                if(me.u.get_display())
                {
                    if (me.u.Callsign != nil)
                        me.callsign = me.u.Callsign.getValue();
                    me.model = "XX";

                    if (me.u.ModelType != "")
                        me.model = me.u.ModelType;

                    if (me.target_idx < me.max_symbols)
                    {
                        me.tgt = me.tgt_symbols[me.target_idx];
                        if (me.tgt != nil)
                        {
                            me.tgt.setVisible(me.u.get_display());
                            me.u_dev_rad = (90-me.u.get_deviation(hdp.heading))  * D2R;
                            me.u_elev_rad = (90-me.u.get_total_elevation( hdp.pitch))  * D2R;
                            me.devs = me.develev_to_devroll(hdp, me.u_dev_rad, me.u_elev_rad);
                            me.combined_dev_deg = me.devs[0];
                            me.combined_dev_length =  me.devs[1];
                            #me.clamped = me.devs[2];
                            me.yc = ht_yco + (ht_ycf * me.combined_dev_length * math.cos(me.combined_dev_deg*D2R));
                            me.xc = ht_xco + (ht_xcf * me.combined_dev_length * math.sin(me.combined_dev_deg*D2R));

                            me.clamped = me.yc > me.sy*0.5 or me.yc < -me.sy*0.5 or me.xc > me.sx *0.5 or me.xc < -me.sx*0.5;# outside HUD

                            if (awg_9.active_u != nil and awg_9.active_u.Callsign != nil and me.u.Callsign != nil and me.u.Callsign.getValue() == awg_9.active_u.Callsign.getValue())
                            {
                                me.target_locked.setVisible(1);
                                me.target_locked.setTranslation (me.xc, me.yc);
                                if (pylons.fcs.isLock()) {
                                    me.target_locked.setRotation(45*D2R);
                                } else {
                                    me.target_locked.setRotation(0);
                                }
                                if (me.clamped) {
                                    me.trackLine.setTranslation(me.sx/2,me.sy-me.texels_up_into_hud);
                                    me.trackLine.setRotation(me.combined_dev_deg*D2R);
                                    me.trackLineShow = 1;
                                }
                            }
                            else
                            {
                                #
                                # if in symbol reject mode then only show the active target.
                                if(hdp.symbol_reject)
                                    me.tgt.setVisible(0);
                            }
                            me.tgt.setTranslation (me.xc, me.yc);
                            me.tgt.update();
                            if (ht_debug)
                                printf("%-10s %f,%f [%f,%f,%f] :: %f,%f",me.callsign,me.xc,me.yc, me.devs[0], me.devs[1], me.devs[2], me.u_dev_rad*D2R, me.u_elev_rad*D2R); 
                        }
                    }
                    me.target_idx += 1;
                }
            }

            for(me.nv = me.target_idx; me.nv < me.max_symbols;me.nv += 1)
            {
                me.tgt = me.tgt_symbols[me.nv];
                if (me.tgt != nil)
                {
                    me.tgt.setVisible(0);
                }
            }
 #       }
        me.trackLine.setVisible(me.trackLineShow);

        
#
#               1 
#
# 2                 3
# 7                 4
# 8                 5
# 9                 6
        me.initUpdate = 0;
 
    },
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

            if (notification.NotificationType == "FrameNotification")
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

emesary.GlobalTransmitter.Register(f16_hud);
