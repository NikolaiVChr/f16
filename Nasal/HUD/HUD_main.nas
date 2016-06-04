# F-15 Canvas HUD
# ---------------------------
# HUD class has dataprovider
# F-15C HUD is in two parts so we have a single class that we can instantiate
# twice on for each combiner pane
# ---------------------------
# Richard Harrison (rjh@zaretto.com) 2015-01-27  - based on F-20 HUD main module Enrique Laso (Flying toaster) 
# ---------------------------

var ht_xcf = 1024;
var ht_ycf = -1024;
var ht_xco = 0;
var ht_yco = -30;
var ht_debug = 0;

#angular definitions
#up angle 1.73 deg
#left/right angle 5.5 deg
#down angle 10.2 deg
#total size 11x11.93 deg
#texture square 256x256
#bottom left 0,0
#viewport size  236x256
#center at 118,219
#pixels per deg = 21.458507963

# paste into nasal console for debugging
#aircraft.HUDcanvas._node.setValues({
#                           "name": "F-15 HUD",
#                           "size": [1024,1024], 
#                           "view": [256,256],                       
#                           "mipmapping": 0     
#  });
#aircraft.svg.setTranslation (-6.0, 37.0);

var pitch_offset = 12;
var pitch_factor = 19.8;
var pitch_factor_2 = pitch_factor * 180.0 / 3.14159;
var alt_range_factor = (9317-191) / 100000; # alt tape size and max value.
var ias_range_factor = (694-191) / 1100;

var F15HUD = {
	new : func (svgname, canvas_item,tran_x,tran_y){
		var obj = {parents : [F15HUD] };

        obj.canvas= canvas.new({
                "name": "F-15 HUD",
                    "size": [1024,1024], 
                    "view": [276,256],
                    "mipmapping": 1     
                    });                          
                          
        obj.canvas.addPlacement({"node": canvas_item});
        obj.canvas.setColorBackground(0.36, 1, 0.3, 0.00);

# Create a group for the parsed elements
        obj.svg = obj.canvas.createGroup();
 
# Parse an SVG file and add the parsed elements to the given group
        print("HUD Parse SVG ",canvas.parsesvg(obj.svg, svgname));

        obj.svg.setTranslation (-20.0, 37.0);

#        print("HUD INIT");
 
        obj.canvas._node.setValues({
                "name": "F-15 HUD",
                    "size": [1024,1024], 
                    "view": [276,106],                       
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
     
        if (hdp.range_rate != nil)
        {
            me.window1.setVisible(1);
            me.window1.setText("");
        }
        else
            me.window1.setVisible(0);
  
        if(getprop("sim/model/f15/controls/armament/master-arm-switch"))
        {
            var w_s = getprop("sim/model/f15/controls/armament/weapon-selector");
            me.window2.setVisible(1);
            var txt = "";
            if (w_s == 0)
            {
                txt = sprintf("%3d",getprop("/sim/model/f15/systems/gun/rounds"));
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
            me.window5.setText(hdp.window5);
            me.window6.setVisible(0); # SRM UNCAGE / TARGET ASPECT
        }

        me.window7.setText(hdp.window7);

#        me.window8.setText(sprintf("%02d NOWS", hdp.Nz*10));
        me.window8.setText(sprintf("%02d %02d", hdp.Nz*10, getprop("/fdm/jsbsim/systems/cadc/ows-maximum-g")*10));

#heading tape
        if (hdp.heading < 180)
            me.heading_tape_position = -hdp.heading*54/10;
        else
            me.heading_tape_position = (360-hdp.heading)*54/10;
     
        me.heading_tape.setTranslation (me.heading_tape_position,0);
  
#roll pointer
#roll_pointer.setCenter (118,-50);
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
                        var devs = aircraft.develev_to_devroll(u_dev_rad, u_elev_rad);
                        var combined_dev_deg = devs[0];
                        var combined_dev_length =  devs[1];
                        var clamped = devs[2];
                        var yc  = ht_yco + (ht_ycf * combined_dev_length * math.cos(combined_dev_deg*D2R));
                        var xc = ht_xco + (ht_xcf * combined_dev_length * math.sin(combined_dev_deg*D2R));
                        if(devs[2])
                            tgt.setVisible(getprop("sim/model/f15/lighting/hud-diamond-switch/state"));
                        else
                            tgt.setVisible(1);

                        if (awg_9.active_u != nil and awg_9.active_u.Callsign != nil and u.Callsign != nil and u.Callsign.getValue() == awg_9.active_u.Callsign.getValue())
                        {
                            me.target_locked.setVisible(1);
                            me.target_locked.setTranslation (xc, yc);
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
    },
    list: [],
};

#
#
# connects the properties to the HUD; did this really to save a few cycles for the two panes on the F-15
var HUD_DataProvider  = {
	new : func (){
		var obj = {parents : [HUD_DataProvider] };

        return obj;
    },
    update : func() {
        me.IAS = getprop("/velocities/airspeed-kt");
        me.Nz = getprop("sim/model/f15/instrumentation/g-meter/g-max-mooving-average");
        me.WOW = getprop ("/gear/gear[1]/wow") or getprop ("/gear/gear[2]/wow");
        me.alpha = getprop ("fdm/jsbsim/aero/alpha-indicated-deg");
        me.beta = getprop("/orientation/side-slip-deg");
        me.altitude_ft =  getprop ("/position/altitude-ft");
        me.heading =  getprop("/orientation/heading-deg");
        me.mach = getprop ("/velocities/mach");
        me.measured_altitude = getprop("/instrumentation/altimeter/indicated-altitude-ft");
        me.pitch =  getprop ("orientation/pitch-deg");
        me.roll =  getprop ("orientation/roll-deg");
        me.speed = getprop("/fdm/jsbsim/velocities/vt-fps");
        me.v = getprop("/fdm/jsbsim/velocities/v-fps");
        me.w = getprop("/fdm/jsbsim/velocities/w-fps");
        me.range_rate = "0";
        if (getprop("/autopilot/route-manager/active"))
        {
            var rng = getprop("autopilot/route-manager/wp/dist");
            var eta_s = getprop("autopilot/route-manager/wp/eta-seconds");
            if (rng != nil)
            {
                me.window5 = sprintf("%2d MIN",rng);
                me.nav_range = sprintf("N %4.1f", rng);
            }
            else
            {
                me.window5 = "XXX";
                me.nav_range = "N XXX";
            }

            if (eta_s != nil)
                me.window5 = sprintf("%2d MIN",eta_s/60);
            else
                me.window5 = "XX MIN";
        }
        else
        {
            me.nav_range = "";
            me.window5 = "";
        }

        if(getprop("/controls/gear/brake-parking"))
            me.window7 = "BRAKES";
        else if(getprop("controls/gear/gear-down") or me.alpha > 20)
            me.window7 = sprintf("AOA %d",me.alpha);
        else
            me.window7 = sprintf(" %1.3f",me.mach);

        me.roll_rad = 0.0;

#velocity vector 
##

#        var Vxx = getprop("/velocities/uBody-fps");
#        var Vyy = getprop("/velocities/vBody-fps"); 
#        var Vzz = getprop("/velocities/wBody-fps");
#        var Axx = getprop("/accelerations/pilot/x-accel-fps_sec");
#        var Ayy = getprop("/accelerations/pilot/y-accel-fps_sec");
#        var Azz = getprop("/accelerations/pilot/z-accel-fps_sec");
#        var psi = getprop("/orientation/heading-deg") * D2R;

#        var total_vel = math.sqrt(Vxx * Vxx + Vyy * Vyy + Vzz * Vzz);
#        var ground_vel = math.sqrt(Vxx * Vxx + Vyy * Vyy);
#        var up_vel = Vzz;

#        if (ground_vel < 2.0)
#        {
#            if (math.abs(up_vel) < 2.0)
#                actslope = 0.0;
#            else
#                actslope = (up_vel / math.abs(up_vel)) * 90.0;
#
#        }
#        else
#        {
#            actslope = math.atan2(up_vel, ground_vel) / D2R;
#        }
#        var _compression = 1;
#        var view_aspect_ratio = 1;
#        xvvr = (-me.beta * (_compression / view_aspect_ratio));
#        vel_y = -me.alpha * _compression;
#        vel_x = -me.beta * (_compression / view_aspect_ratio);

#        var sin_x = me.v/me.speed;
#        if (sin_x < -1) 
#            sin_x = -1;
#        else if (sin_x > 1)
#            sin_x = 1;

#        var sin_y =me.w/me.speed;
#        if (sin_y < -1)
#            sin_y = -1;
#        else if (sin_y > 1) 
#            sin_y = 1;

#        me.VV_x = math.asin (sin_x) * pitch_factor_2;
#        me.VV_y = math.asin (sin_y) * pitch_factor_2;
#        printf("VV: %d,%d : %d,%d",me.VV_x, me.VV_y, vel_x, vel_y);
        me.VV_x = -me.beta*10; # adjust for view
        me.VV_y = me.alpha*10; # adjust for view

    },
};

var hud_data_provider = HUD_DataProvider.new();
#
# The F-15C HUD is provided by 2 combiners.
# We model this accurately by having two instances of the HUD
# 2015-01-27: Note that the geometry isn't right and the projection needs to be adjusted (somehow) as the
# image elements in the 3d model are correctly angled and this results in trapezoidal distortion

var UpperHUD = F15HUD.new("Nasal/HUD/HUD.svg", "HUDImage1", 0,0);
var LowerHUD = F15HUD.new("Nasal/HUD/HUD.svg", "HUDImage2", 0, -106);

var updateHUD = func ()
{  
    hud_data_provider.update();
    UpperHUD.update(hud_data_provider);
    LowerHUD.update(hud_data_provider);
}
