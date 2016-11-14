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
var ht_xco = 15;
var ht_yco = -30;
var ht_debug = 0;

var pitch_offset = 12;
var pitch_factor = 19.8;
var pitch_factor_2 = pitch_factor * 180.0 / 3.14159;
var alt_range_factor = (9317-191) / 100000; # alt tape size and max value.
var ias_range_factor = (694-191) / 1100;

var F16_HUD = {
	new : func (svgname, canvas_item, sx, sy, tran_x,tran_y){
		var obj = {parents : [F16_HUD] };

        obj.canvas= canvas.new({
                "name": "F16 HUD",
                    "size": [1024,1024], 
                    "view": [sx,sy],
                    "mipmapping": 0 # mipmapping will make the HUD text blurry on smaller screens     
                    });  

        obj.sy = sy;                        
                          
        obj.canvas.addPlacement({"node": canvas_item});
        obj.canvas.setColorBackground(0.36, 1, 0.3, 0.00);

# Create a group for the parsed elements
        obj.svg = obj.canvas.createGroup();
 
# Parse an SVG file and add the parsed elements to the given group
        print("HUD Parse SVG ",canvas.parsesvg(obj.svg, svgname));

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
        var hud_position = 4.65415;#5.66824; # really -5.6 but avoiding more complex equations by being optimal with the signs.
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
            combined_dev_length = clamp;
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
        var  roll_rad = -hdp.roll*3.14159/180.0;


        # calc of pitch_offset (compensates for AC3D model translated and rotated when loaded. Also semi compensates for HUD being at an angle.)
        var Hz_b =    0.80643; # HUD position inside ac model after it is loaded translated and rotated.
        var Hz_t =    0.96749;
        var Vz   =    getprop("sim/current-view/y-offset-m"); # view Z position (0.94 meter per default)

        var bore_over_bottom = Vz - Hz_b;
        var Hz_height        = Hz_t-Hz_b;
        var hozizon_line_offset_from_middle_in_svg = 0.137; #fraction up from middle
        var frac_up_the_hud = bore_over_bottom / Hz_height - hozizon_line_offset_from_middle_in_svg;
        var texels_up_into_hud = frac_up_the_hud * me.sy;#sy default is 260
        var texels_over_middle = texels_up_into_hud - me.sy/2;


        pitch_offset = -texels_over_middle;
        ht_yco = pitch_offset;
#pitch ladder
        
        me.ladder.setTranslation (0.0, hdp.pitch * pitch_factor+pitch_offset);                                           
        me.ladder.setCenter (me.ladder_center[0], me.ladder_center[1] - hdp.pitch * pitch_factor);
        me.ladder.setRotation (roll_rad);
  
# velocity vector
        me.VV.setTranslation (hdp.VV_x, hdp.VV_y+pitch_offset);

#Altitude
        me.alt_range.setTranslation(0, hdp.measured_altitude * alt_range_factor);

# IAS
        me.ias_range.setTranslation(0, hdp.IAS * ias_range_factor);
     
        if(getprop("sim/model/f15/controls/armament/master-arm-switch"))
        {
            var w_s = getprop("sim/model/f15/controls/armament/weapon-selector");
            me.window2.setVisible(1);
            var txt = "";
            if (w_s == 0)
            {
                txt = sprintf("%3d",getprop("sim/model/f15/systems/gun/rounds"));
            }
            else if (w_s == 1)
            {
                txt = sprintf("S%dL", getprop("sim/model/f15/systems/armament/aim9/count"));
            }
            else if (w_s == 2)
            {
                txt = sprintf("M%dF", getprop("sim/model/f15/systems/armament/aim120/count")+getprop("sim/model/f15/systems/armament/aim7/count"));
            }
            me.window2.setText(txt);
            if (awg_9.active_u != nil)
            {
                if (awg_9.active_u.Callsign != nil)
                    me.window3.setText(awg_9.active_u.Callsign.getValue());
                var model = "XX";
                if (awg_9.active_u.ModelType != "")
                    model = awg_9.active_u.ModelType;

#        var w2 = sprintf("%-4d", awg_9.active_u.get_closure_rate());
#        w3_22 = sprintf("%3d-%1.1f %.5s %.4s",awg_9.active_u.get_bearing(), awg_9.active_u.get_range(), callsign, model);
#
#
#these labels aren't correct - but we don't have a full simulation of the targetting and missiles so 
#have no real idea on the details of how this works.
                me.window4.setText(sprintf("RNG %3.1f", awg_9.active_u.get_range()));
                me.window5.setText(sprintf("CLO %-3d", awg_9.active_u.get_closure_rate()));
                me.window6.setText(model);
                me.window6.setVisible(1); # SRM UNCAGE / TARGET ASPECT
            }
        }
        else
        {
        me.window2.setVisible(0);
        me.window3.setText("NAV");
        if (hdp.nav_range != "")
          me.window3.setText("NAV");
        else
          me.window3.setText("");
        me.window4.setText(hdp.nav_range);
            me.window5.setText(hdp.hud_window5);
        me.window6.setVisible(0); # SRM UNCAGE / TARGET ASPECT
        }

        if (hdp.range_rate != nil)
        {
            me.window1.setVisible(1);
            me.window1.setText("");
        }
        else
            me.window1.setVisible(0);
  
        me.window8.setText(sprintf("%3.1f", hdp.Nz));

        if (hdp.heading < 180)
            me.heading_tape_position = -hdp.heading*54/10;
        else
            me.heading_tape_position = (360-hdp.heading)*54/10;
     
        me.heading_tape.setTranslation (me.heading_tape_position,0);
        me.roll_pointer.setRotation (roll_rad);

        var target_idx = 0;
        var designated = 0;
        me.target_locked.setVisible(0);
        foreach( u; awg_9.tgts_list ) 
        {
            var callsign = "XX";
            if(u.get_display())
            {
                if (u.Callsign != nil)
                    callsign = u.Callsign.getValue();
                var model = "XX";

                if (u.ModelType != "")
                    model = u.ModelType;

                if (target_idx < me.max_symbols)
                {
                    tgt = me.tgt_symbols[target_idx];
                    if (tgt != nil)
                    {
                        tgt.setVisible(u.get_display());
                        var u_dev_rad = (90-u.get_deviation(hdp.heading))  * D2R;
                        var u_elev_rad = (90-u.get_total_elevation( hdp.pitch))  * D2R;
                        var devs = me.develev_to_devroll(hdp, u_dev_rad, u_elev_rad);
                        var combined_dev_deg = devs[0];
                        var combined_dev_length =  devs[1];
                        var clamped = devs[2];
                        var yc  = ht_yco + (ht_ycf * combined_dev_length * math.cos(combined_dev_deg*D2R));
                        var xc = ht_xco + (ht_xcf * combined_dev_length * math.sin(combined_dev_deg*D2R));
                        if(devs[2])
                            tgt.setVisible(1);#getprop("sim/model/f16/lighting/hud-diamond-switch/state"));
                        else
                            tgt.setVisible(1);

                        if (awg_9.active_u != nil and awg_9.active_u.Callsign != nil and u.Callsign != nil and u.Callsign.getValue() == awg_9.active_u.Callsign.getValue())
                        {
                            me.target_locked.setVisible(1);
                            me.target_locked.setTranslation (xc, yc);
                        }
                        else
                        {
                            #
                            # if in symbol reject mode then only show the active target.
                            if(hdp.symbol_reject)
                                tgt.setVisible(0);
                        }
                        tgt.setTranslation (xc, yc);

                        if (ht_debug)
                            printf("%-10s %f,%f [%f,%f,%f] :: %f,%f",callsign,xc,yc, devs[0], devs[1], devs[2], u_dev_rad*D2R, u_elev_rad*D2R); 
                    }
                }
                target_idx = target_idx+1;
            }
        }
        for(var nv = target_idx; nv < me.max_symbols;nv += 1)
        {
            tgt = me.tgt_symbols[nv];
            if (tgt != nil)
            {
                tgt.setVisible(0);
            }
        }


        if(hdp.brake_parking)
          {
            me.window7.setVisible(1);
            me.window7.setText("BRAKES");
        }
        else if (hdp.flap_pos_deg > 0 or hdp.gear_down)
          {
            me.window7.setVisible(1);
              var gd = "";
              if (hdp.gear_down)
                gd = " G";
              me.window7.setText(sprintf("F %d %s",hdp.flap_pos_deg,gd));
        }
        else
            me.window7.setVisible(0);
        #
#
#               1 
#
# 2                 3
# 7                 4
# 8                 5
# 9                 6
        me.window9.setText(sprintf("AOA %d",hdp.alpha));
        me.window5.setText(sprintf("M %1.3f",hdp.mach));

        me.roll_rad = 0.0;

        me.VV_x = hdp.beta*10; # adjust for view
        me.VV_y = hdp.alpha*10; # adjust for view

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
