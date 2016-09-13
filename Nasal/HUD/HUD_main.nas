# Canvas HUD
# ---------------------------
# HUD uses data in the frame notification
# HUD is in two parts so we have a single class that we can instantiate
# twice on for each combiner pane
# ---------------------------
# Richard Harrison (rjh@zaretto.com) 2016-07-01  - based on F-15 HUD
# ---------------------------

var ht_xcf = 1024;
var ht_ycf = -1024;
var ht_xco = 0;
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
                    "mipmapping": 1     
                    });                          
                          
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
  
#pitch ladder
        me.ladder.setTranslation (0.0, hdp.pitch * pitch_factor+pitch_offset);                                           
        me.ladder.setCenter (118,830 - hdp.pitch * pitch_factor-pitch_offset);
        me.ladder.setRotation (roll_rad);
  
# velocity vector
        me.VV.setTranslation (hdp.VV_x, hdp.VV_y+pitch_offset);

#Altitude
        me.alt_range.setTranslation(0, hdp.measured_altitude * alt_range_factor);

# IAS
        me.ias_range.setTranslation(0, hdp.IAS * ias_range_factor);
     
        me.window2.setVisible(0);
        me.window3.setText("NAV");
        if (hdp.nav_range != "")
          me.window3.setText("NAV");
        else
          me.window3.setText("");
        me.window4.setText(hdp.nav_range);
#        me.window5.setText(hdp.hud_window5);
        me.window6.setVisible(0); # SRM UNCAGE / TARGET ASPECT

        if (hdp.range_rate != nil)
        {
            me.window1.setVisible(1);
            me.window1.setText("");
        }
        else
            me.window1.setVisible(0);
  
        me.window8.setText(sprintf("%02d", hdp.Nz*10));

        if (hdp.heading < 180)
            me.heading_tape_position = -hdp.heading*54/10;
        else
            me.heading_tape_position = (360-hdp.heading)*54/10;
     
        me.heading_tape.setTranslation (me.heading_tape_position,0);
        me.roll_pointer.setRotation (roll_rad);
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
          } else
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
        new_class.HUDobj = F16_HUD.new("Nasal/HUD/HUD.svg", "HUDImage2", 260, 216, 0,0);

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
