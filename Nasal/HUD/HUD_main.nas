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
        obj.heading_tape_pointer = obj.get_element("path3419");

        obj.roll_pointer = obj.get_element("roll-pointer");
        obj.alt_range = obj.get_element("alt_range");
        obj.ias_range = obj.get_element("ias_range");
        obj.oldBore = obj.get_element("path4530-6");
        obj.target_locked = obj.get_element("target_locked");
        obj.target_locked.setVisible(0);

        HUD_FONT = "LiberationFonts/LiberationMono-Bold.ttf";#"condensed.txf";  with condensed the FLYUP text was not displayed until minutes into flight, no clue why
        obj.window1 = obj.get_text("window1", HUD_FONT,9,1.4);
        obj.window2 = obj.get_text("window2", HUD_FONT,9,1.4);
        obj.window3 = obj.get_text("window3", HUD_FONT,9,1.4);
        obj.window4 = obj.get_text("window4", HUD_FONT,9,1.4);
        obj.window5 = obj.get_text("window5", HUD_FONT,9,1.4);
        obj.window6 = obj.get_text("window6", HUD_FONT,9,1.4);
        obj.window7 = obj.get_text("window7", HUD_FONT,9,1.4);
        obj.window8 = obj.get_text("window8", HUD_FONT,9,1.4);
        obj.window9 = obj.get_text("window9", HUD_FONT,9,1.4);
        obj.window2.setFont("LiberationFonts/LiberationMono-Bold.ttf").setFontSize(10,1.1);
        obj.window3.setFont("LiberationFonts/LiberationMono-Bold.ttf").setFontSize(10,1.1);
        obj.window4.setFont("LiberationFonts/LiberationMono-Bold.ttf").setFontSize(10,1.1);
        obj.window5.setFont("LiberationFonts/LiberationMono-Bold.ttf").setFontSize(10,1.1);
        obj.window6.setFont("LiberationFonts/LiberationMono-Bold.ttf").setFontSize(10,1.1);
        obj.window7.setFont("LiberationFonts/LiberationMono-Bold.ttf").setFontSize(10,1.1);
        obj.window8.setFont("LiberationFonts/LiberationMono-Bold.ttf").setFontSize(10,1.1);
        obj.window9.setFont("LiberationFonts/LiberationMono-Bold.ttf").setFontSize(10,1.1);

        obj.ralt = obj.get_text("radalt", HUD_FONT,9,1.4);
        obj.ralt.setFont("LiberationFonts/LiberationMono-Bold.ttf").setFontSize(9,1.1);

        input = {
                 IAS                       : "/velocities/airspeed-kt",
                 Nz                        : "/accelerations/pilot-gdamped",
                 alpha                     : "/fdm/jsbsim/aero/alpha-deg",
                 altitude_ft               : "/position/altitude-ft",
                 beta                      : "/orientation/side-slip-deg",
                 brake_parking             : "/controls/gear/brake-parking",
                 eta_s                     : "/autopilot/route-manager/wp/eta-seconds",
                 flap_pos_deg              : "/fdm/jsbsim/fcs/flap-pos-deg",
                 gear_down                 : "/controls/gear/gear-down",
                 heading                   : "/orientation/heading-deg",
                 mach                      : "/instrumentation/airspeed-indicator/indicated-mach",
                 measured_altitude         : "/instrumentation/altimeter/indicated-altitude-ft",
                 pitch                     : "/orientation/pitch-deg",
                 nav_range                 : "/autopilot/route-manager/wp/dist",
                 roll                      : "/orientation/roll-deg",
                 route_manager_active      : "/autopilot/route-manager/active",
                 speed                     : "/fdm/jsbsim/velocities/vt-fps",
                 symbol_reject             : "/controls/HUD/sym-rej",
                 target_display            : "/sim/model/f16/instrumentation/radar-awg-9/hud/target-display",
                 wow                       : "/fdm/jsbsim/gear/wow",
                 current_view_x_offset_m   : "sim/current-view/x-offset-m",
                 current_view_y_offset_m   : "sim/current-view/y-offset-m",
                 current_view_z_offset_m   : "sim/current-view/z-offset-m",
                 master_arm                : "controls/armament/master-arm",
                 groundspeed_kt            : "velocities/groundspeed-kt",
                 density_altitude          : "fdm/jsbsim/atmosphere/density-altitude",
                 speed_down_fps            : "velocities/speed-down-fps",
                 speed_east_fps            : "velocities/speed-east-fps",
                 speed_north_fps           : "velocities/speed-north-fps",
                 hud_brightness            : "f16/avionics/hud-brt",
                 hud_power                 : "f16/avionics/hud-power",
                 hud_display               : "controls/HUD/display-on",
                 hud_serviceable           : "sim/failure-manager/instrumentation/hud/serviceable",
                 time_until_crash          : "instrumentation/radar/time-till-crash",
                 vne                       : "f16/vne",
                 wp_bearing_deg            : "autopilot/route-manager/wp/true-bearing-deg",
                 total_fuel_lbs            : "/consumables/fuel/total-fuel-lbs",
                 altitude_agl_ft           : "position/altitude-agl-ft",
                 wp0_eta                   : "autopilot/route-manager/wp[0]/eta",
                 approach_speed            : "fdm/jsbsim/systems/approach-speed",
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
                                            obj.svg.setColor(0.3,1,0.3,0);
                                          } elsif (hdp.hud_brightness != nil and hdp.hud_power != nil) {
                                            obj.svg.setColor(0.3,1,0.3,hdp.hud_brightness * hdp.hud_power);
                                          }
                                      }),
            props.UpdateManager.FromHashList([], 0.01, func(hdp)
                                      {
                                      }),
            props.UpdateManager.FromHashList(["master_arm", "altitude_ft", "roll", "groundspeed_kt", "density_altitude", "mach", "speed_down_fps", "speed_east_fps", "speed_north_fps"], 0.01, func(hdp)
                                      {
                                          hdp.CCRP_active = obj.CCRP(hdp);
                                      }),

            props.UpdateManager.FromHashList(["route_manager_active", "wp_bearing_deg", "heading"], 0.01, func(hdp)
                                             {
                                                 # the Y position is still not accurate due to HUD being at an angle, but will have to do.
                                                 if (hdp.route_manager_active) {
                                                     obj.wpbear = hdp.wp_bearing_deg;
                                                     if (obj.wpbear!=nil) {
                                
                                                         obj.wpbear=geo.normdeg180(obj.wpbear-hdp.heading);
                                                         obj.thingX = obj.sx*0.5+obj.wpbear*obj.texelPerDegreeX;

                                                         if (obj.thingX>obj.sx*0.66) {
                                                             obj.thingX=obj.sx*0.66;
                                                         } elsif (obj.thingX<obj.sx*0.33) {
                                                             obj.thingX=obj.sx*0.33;
                                                         }
                                                         obj.thing.setTranslation(obj.thingX,obj.sy-obj.texels_up_into_hud+15);
                                                         obj.thing.setRotation(obj.wpbear*D2R);
                                                         obj.thing.show();
                                                     } else {
                                                         obj.thing.hide();
                                                     }
                                                 } else {
                                                     obj.thing.hide();
                                                 }
                                             }
                                            ),

            props.UpdateManager.FromHashList(["gear_down"], 0.01, func(val)
                                             {
                                                 if (val.gear_down) {
                                                     obj.boreSymbol.hide();
                                                 } else {
                                                     obj.boreSymbol.setTranslation(obj.sx/2,obj.sy-obj.texels_up_into_hud);
                                                     obj.boreSymbol.show();
                                                 }
                                                 obj.oldBore.hide();
                                      }),
            props.UpdateManager.FromHashList(["VV_x","VV_y"], 0.01, func(hdp)
                                      {
                                        obj.VV.setTranslation (hdp.VV_x, hdp.VV_y + pitch_offset);
                                        obj.VV.setTranslation (hdp.VV_x * obj.texelPerDegreeX, hdp.VV_y * obj.texelPerDegreeY+pitch_offset);
                                        obj.VV.update();
                                      }),

            props.UpdateManager.FromHashList(["pitch","roll"], 0.025, func(hdp)
                                      {
                                          obj.ladder.setTranslation (0.0, hdp.pitch * pitch_factor+pitch_offset);                                           
                                          obj.ladder.setCenter (obj.ladder_center[0], obj.ladder_center[1] - hdp.pitch * pitch_factor);
                                          obj.ladder.setRotation (hdp.roll_rad);
                                          obj.roll_pointer.setRotation (hdp.roll_rad);
                                          obj.ladder.update();
                                      }),
#            props.UpdateManager.FromHashValue("roll_rad", 1.0, func(roll_rad)
#                                      {
#                                      }),
            props.UpdateManager.FromHashList(["altitude_agl_ft"], 1.0, func(hdp)
                                      {
                                          obj.agl=hdp.altitude_agl_ft;
                                          if(obj.agl < 13000) {
                                              obj.ralt.setText(sprintf("R %05d ",obj.agl));
                                              obj.ralt.show();
                                              obj.raltFrame.hide();
                                          } else {
                                              obj.ralt.hide();
                                              obj.raltFrame.hide();
                                          }
                                      }),
            props.UpdateManager.FromHashValue("measured_altitude", 1.0, func(measured_altitude)
                                      {
                                          obj.alt_range.setTranslation(0, measured_altitude * alt_range_factor);
                                      }),
            props.UpdateManager.FromHashValue("IAS", 0.1, func(IAS)
                                      {
                                          obj.ias_range.setTranslation(0, IAS * ias_range_factor);
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
            props.UpdateManager.FromHashValue("Nz", 0.1, func(Nz)
                                      {
                                          obj.window8.setText(sprintf("%.1f", Nz));
                                          obj.window8.show();
                                      }),
            props.UpdateManager.FromHashList(["heading", "gear_down"], 0.1, func(hdp)
                                      {
                                          if (hdp.heading < 180)
                                            obj.heading_tape_position = -hdp.heading*54/10;
                                          else
                                            obj.heading_tape_position = (360-hdp.heading)*54/10;
                                          if (hdp.gear_down) {
                                              obj.heading_tape_positionY = -10;
                                          } else {
                                              obj.heading_tape_positionY = 95;
                                          }
                                          obj.heading_tape.setTranslation (obj.heading_tape_position,obj.heading_tape_positionY);
                                          obj.heading_tape_pointer.setTranslation (0,obj.heading_tape_positionY);
                                      }
                                            ),
            props.UpdateManager.FromHashList(["time_until_crash"], 0.1, func(hdp)
                                             {
                                                 obj.ttc = hdp.time_until_crash;
                                                 if (obj.ttc != nil and obj.ttc>0 and obj.ttc<10) {
                                                     obj.flyup.setText("FLYUP");
                                                     #obj.flyup.setColor(1,0,0,1);
                                                     obj.flyup.show();
                                                 } else {
                                                     if (hdp.vne) {
                                                         obj.flyup.setText("LIMIT");
                                                         obj.flyup.show();
                                                     } else {
                                                         obj.flyup.hide();
                                                     }
                                                 }
                                                 obj.flyup.update();
                                             }
                                            ),

            props.UpdateManager.FromHashList(["brake_parking", "gear_down", "flap_pos_deg", "CCRP_active", "master_arm"], 0.1, func(hdp)
                                             {
                                                 if (hdp.brake_parking) {
                                                     obj.window2.setVisible(1);
                                                     obj.window2.setText("BRAKES");
                                                 } elsif (hdp.flap_pos_deg > 0 or hdp.gear_down) {
                                                     obj.window2.setVisible(1);
                                                     obj.gd = "";
                                                     if (hdp.gear_down)
                                                       obj.gd = " G";
                                                     obj.window2.setText(sprintf("F %d%s",hdp.flap_pos_deg,obj.gd));
                                                 } elsif (hdp.master_arm) {
                                                     if (hdp.CCRP_active) {
                                                         obj.window2.setText("ARM CCRP");
                                                     } else {
                                                         obj.window2.setText("ARM");
                                                     }
                                                     obj.window2.setVisible(1);
                                                 } else {
                                                     obj.window2.setText("NAV");
                                                     obj.window2.setVisible(1);
                                                 }
                                             }
                                            ),
            props.UpdateManager.FromHashValue("window3_txt", nil, func(txt)
                                      {
                                          if (txt != nil and txt != ""){
                                              obj.window3.show();
                                              obj.window3.setText(txt);
                                          }
                                          else
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

        ];
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
                .setTranslation(sx*0.5*0.695633,sy*0.30)
                .setAlignment("center-center")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(13, 1.4);
#        obj.ralt = obj.svg.createChild("text")
#                .setText("R 00000 ")
#                .setTranslation(sx*1*0.675633-5,sy*0.45)
#                .setAlignment("right-center")
#                .setColor(0,1,0)
#                .setFont(HUD_FONT)
#                .setFontSize(9, 1.4);
        obj.raltFrame = obj.svg.createChild("path")
                .moveTo(sx*1*0.695633-9,sy*0.45+5)
                .horiz(-41)
                .vert(-10)
                .horiz(41)
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
        obj.bombFallLine = obj.svg.createChild("path")
                .moveTo(sx*0.5*0.695633,0)
                #.horiz(10)
                .vert(400)
                .setStrokeLineWidth(1)
                .setColor(0,1,0);
        obj.solutionCue = obj.svg.createChild("path")
                .moveTo(sx*0.5*0.695633-5,0)
                .horiz(10)
                .setStrokeLineWidth(1)
                .setColor(0,1,0);
        obj.ccrpMarker = obj.svg.createChild("path")
                .moveTo(sx*0.5*0.695633-10,sy*0.5)
                .horiz(20)
                .setStrokeLineWidth(1)
                .setColor(0,1,0);
        obj.thing = obj.svg.createChild("path")
            .moveTo(-3,0)
            .arcSmallCW(3,3, 0, 3*2, 0)
            .arcSmallCW(3,3, 0, -3*2, 0)
            .moveTo(0,-3)
            .vert(-6)
            .setStrokeLineWidth(1)
            .setColor(0,1,0);
        obj.initUpdate =1;
        
        obj.alpha = getprop("f16/avionics/hud-brt");
        obj.power = getprop("f16/avionics/hud-power");

        obj.dlzX      = sx*0.695633*0.75-6;
        obj.dlzY      = sy*0.4;
        obj.dlzWidth  =  10;
        obj.dlzHeight = sy*0.25;
        obj.dlzLW     =   1;
        obj.dlz      = obj.svg.createChild("group")
                        .setTranslation(obj.dlzX, obj.dlzY);
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

    CCRP: func(hdp) {
        if (pylons.fcs != nil and pylons.fcs.getSelectedWeapon() != nil and (pylons.fcs.getSelectedWeapon().type=="MK-82" or pylons.fcs.getSelectedWeapon().type=="GBU-12" or pylons.fcs.getSelectedWeapon().type=="B61-7" or pylons.fcs.getSelectedWeapon().type=="B61-12" or pylons.fcs.getSelectedWeapon().type=="GBU-31") 
            and hdp.active_u != nil and hdp.master_arm ==1 and pylons.fcs.getSelectedWeapon().status == armament.MISSILE_LOCK) {

            if (pylons.fcs.getSelectedWeapon().type=="MK-82") {
                me.dt = 0.1;
                me.maxFallTime = 20;
            } else {
                me.agl = (hdp.altitude_ft-hdp.active_u.get_altitude())*FT2M;
                me.dt = me.agl*0.000025;#4000 ft = ~0.1
                if (me.dt < 0.1) me.dt = 0.1;
                me.maxFallTime = 45;
            }
            me.distCCRP = pylons.fcs.getSelectedWeapon().getCCRP(me.maxFallTime,me.dt);
            if (me.distCCRP == nil) {
                me.solutionCue.hide();
                me.ccrpMarker.hide();
                me.bombFallLine.hide();
                return 0;
            }
            me.distCCRP/=4000;
            if (me.distCCRP > 0.75) {
                me.distCCRP = 0.75;
            }
            me.bombFallLine.setTranslation(hdp.active_u.get_relative_bearing()*me.texelPerDegreeX,0);
            me.ccrpMarker.setTranslation(hdp.active_u.get_relative_bearing()*me.texelPerDegreeX,0);
            me.solutionCue.setTranslation(hdp.active_u.get_relative_bearing()*me.texelPerDegreeX,me.sy*0.5-me.sy*0.5*me.distCCRP);
            me.bombFallLine.show();
            me.ccrpMarker.show();
            me.solutionCue.show();
            return 1;




            me.agl = (hdp.altitude_ft-hdp.active_u.get_altitude())*FT2M;
            #me.agl = getprop("position/altitude-agl-ft")*FT2M;
            me.alti = hdp.altitude_ft*FT2M;
            me.roll = hdp.roll;
            me.vel = hdp.groundspeed_kt*0.5144;#m/s
            me.dens = hdp.density_altitude;
            me.mach = hdp.mach;
            me.speed_down_fps = hdp.speed_down_fps;
            me.speed_east_fps = hdp.speed_east_fps;
            me.speed_north_fps = hdp.speed_north_fps;

            

            me.t = 0.0;
            
            me.altC = me.agl;
            me.vel_z = -me.speed_down_fps*FT2M;#positive upwards
            me.fps_z = -me.speed_down_fps;
            me.vel_x = math.sqrt(me.speed_east_fps*me.speed_east_fps+me.speed_north_fps*me.speed_north_fps)*FT2M;
            me.fps_x = me.vel_x * M2FT;
            me.bomb = pylons.fcs.getSelectedWeapon();

            me.rs = me.bomb.rho_sndspeed(me.dens-(me.agl/2)*M2FT);
            me.rho = me.rs[0];
            me.Cd = me.bomb.drag(me.mach);
            me.mass = me.bomb.weight_launch_lbm / armament.slugs_to_lbm;
            me.q = 0.5 * me.rho * me.fps_z * me.fps_z;
            me.deacc = (me.Cd * me.q * me.bomb.ref_area_sqft) / me.mass;

            while (me.altC > 0 and me.t <= me.maxFallTime) {#16 secs is max fall time according to manual
              me.t += me.dt;
              me.acc = -9.81 + me.deacc * FT2M;
              me.vel_z += me.acc * me.dt;
              me.altC = me.altC + me.vel_z*me.dt+0.5*me.acc*me.dt*me.dt;
            }
            #printf("predict fall time=%0.1f", me.t);

            if (me.t >= me.maxFallTime) {
              me.solutionCue.hide();
              me.ccrpMarker.hide();
              me.bombFallLine.hide();
              return 0;
            }
            #t -= 0.75 * math.cos(pitch*D2R);            # fudge factor

            me.q = 0.5 * me.rho * me.fps_x * me.fps_x;
            me.deacc = (me.Cd * me.q * me.bomb.ref_area_sqft) / me.mass;
            me.acc = -me.deacc * FT2M;
            
            me.fps_x_final = me.t*me.acc+me.fps_x;# calc final horz speed
            me.fps_x_average = (me.fps_x-(me.fps_x-me.fps_x_final)*0.5);
            me.mach_average = me.fps_x_average / me.rs[1];
            
            me.Cd = me.bomb.drag(me.mach_average);
            me.q = 0.5 * me.rho * me.fps_x_average * me.fps_x_average;
            me.deacc = (me.Cd * me.q * me.bomb.ref_area_sqft) / me.mass;
            me.acc = -me.deacc * FT2M;
            me.dist = me.vel_x*me.t+0.5*me.acc*me.t*me.t;

            me.ac = geo.aircraft_position();
            me.ccipPos = geo.Coord.new(me.ac);

            # we calc heading from composite speeds, due to alpha and beta might influence direction bombs will fall:
            me.vectorMag = math.sqrt(me.speed_east_fps*me.speed_east_fps+me.speed_north_fps*me.speed_north_fps);
            if (me.vectorMag == 0) {
                me.vectorMag = 0.0001;
            }
            me.heading = -math.asin(me.speed_north_fps/me.vectorMag)*R2D+90;#divide by vector mag, to get normalized unit vector length
            if (me.speed_east_fps/me.vectorMag < 0) {
              me.heading = -me.heading;
              while (me.heading > 360) {
                me.heading -= 360;
              }
              while (me.heading < 0) {
                me.heading += 360;
              }
            }
            me.ccipPos.apply_course_distance(me.heading, me.dist);
            #var elev = geo.elevation(ac.lat(), ac.lon());
            #printf("Will fall %0.1f NM ahead of aircraft.", me.dist*M2NM);
            me.elev = me.alti-me.agl;#faster
            me.ccipPos.set_alt(me.elev);
            
            me.distCCRP = me.ccipPos.distance_to(hdp.active_u.get_Coord())/4000;
            if (me.distCCRP > 0.75) {
                me.distCCRP = 0.75;
            }
            me.bombFallLine.setTranslation(hdp.active_u.get_relative_bearing()*me.texelPerDegreeX,0);
            me.ccrpMarker.setTranslation(hdp.active_u.get_relative_bearing()*me.texelPerDegreeX,0);
            me.solutionCue.setTranslation(hdp.active_u.get_relative_bearing()*me.texelPerDegreeX,me.sy*0.5-me.sy*0.5*me.distCCRP);
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
    },

    update : func(hdp) {

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
            hdp.window4_txt = "3";
            hdp.window5_txt = "4";
            hdp.window6_txt = "5";
            hdp.window7_txt = "6";
            hdp.window8_txt = "7";
            hdp.window9_txt = "8";
        }

        if (hdp.FrameCount == 2 or me.initUpdate == 1) {
            # calc of pitch_offset (compensates for AC3D model translated and rotated when loaded. Also semi compensates for HUD being at an angle.)
            me.Hz_b =    0.663711;#0.801701;# HUD position inside ac model after it is loaded, translated (0.08m) and rotated (0.7d).
            me.Hz_t =    0.841082;#0.976668;
            me.Hx_m =   -4.65453;#-4.6429;# HUD median X pos
            me.Vz   =    hdp.current_view_y_offset_m; # view Z position (0.94 meter per default)
            me.Vx   =    hdp.current_view_z_offset_m; # view X position (0.94 meter per default)

            me.bore_over_bottom = me.Vz - me.Hz_b;
            me.Hz_height        = me.Hz_t-me.Hz_b;
            me.hozizon_line_offset_from_middle_in_svg = 0.1346; #horizline and radar echoes fraction up from middle
            me.frac_up_the_hud = me.bore_over_bottom / me.Hz_height;
            me.texels_up_into_hud = me.frac_up_the_hud * me.sy;#sy default is 260
            me.texels_over_middle = me.texels_up_into_hud - me.sy/2;
            pitch_offset = -me.texels_over_middle + me.hozizon_line_offset_from_middle_in_svg*me.sy;

        }
#Text windows on the HUD (F-16)
#               1 
#
# 2 nav/arm         3 fuel/callsign
# 7 mach            4 eta/altitude
# 8 g               5 waypoint/slant range
# 9 weap/aoa        6 type

# velocity vector
        #340,260
        # 0.078135*2 = width of HUD  = 0.15627m
        me.pixelPerMeterX = (340*0.695633)/0.15627;
        me.pixelPerMeterY = 260/(me.Hz_t-me.Hz_b);

        hdp.VV_x = hdp.beta;
        hdp.VV_y = hdp.alpha;

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
            }
        } else {
            hdp.active_target_available = 0;
            hdp.active_target_callsign = "";
            hdp.active_target_model = "XX";
        }

        hdp.fcs_available = pylons.fcs != nil;
        hdp.weapon_selected = "";

        # part2. update display, first with the update managed items

        if (hdp.FrameCount == 2 or me.initUpdate == 1) {
            hdp.window1_txt = "";
            hdp.window2_txt = "";
            hdp.window3_txt = "";
            hdp.window4_txt = "";
            hdp.window5_txt = "";
            hdp.window6_txt = "";
            hdp.window7_txt = "";
            hdp.window8_txt = "";
            hdp.window9_txt = "";

            if(hdp.master_arm and pylons.fcs != nil)
            {
                hdp.weapon_selected = pylons.fcs.selectedType;
                me.window9.setVisible(1);
                
                if (hdp.weapon_selected != nil)
                {
                    if (hdp.weapon_selected == "20mm Cannon") {
                        hdp.window9_txt = sprintf("%3d", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "AIM-9") {
                        hdp.window9_txt = sprintf("%d SRM", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "AIM-120") {
                        hdp.window9_txt = sprintf("%d LRM", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "AIM-7") {
                        hdp.window9_txt = sprintf("%d MRM", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "GBU-12") {
                        hdp.window9_txt = sprintf("%d B12", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "AGM-65") {
                        hdp.window9_txt = sprintf("%d M65", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "AGM-84") {
                        hdp.window9_txt = sprintf("%d M84", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "MK-82") {
                        hdp.window9_txt = sprintf("%d B82", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "AGM-88") {
                        hdp.window9_txt = sprintf("%d M88", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "GBU-31") {
                        hdp.window9_txt = sprintf("%d B31", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "B61-12") {
                        hdp.window9_txt = sprintf("%d B61-12", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "B61-7") {
                        hdp.window9_txt = sprintf("%d B61-7", pylons.fcs.getAmmo());
                    } else hdp.window9_txt = "";
                }
                if (hdp.active_u != nil)
                {
                    if (hdp.active_u.Callsign != nil) {
                        hdp.window3_txt = hdp.active_u.Callsign.getValue();
                        me.window3.show();
                    } else {
                        me.window3.hide();
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
                        me.window4.show();
                        me.window5.show();
                    } else {
                        hdp.window4_txt = sprintf("TA%3d", hdp.active_u.get_altitude()*0.001);
                        hdp.window5_txt = sprintf("F%05.1f", hdp.active_u.get_slant_range());#slant range
                        me.window4.show();
                        me.window5.show();
                    }
                    
                    hdp.window6_txt = hdp.active_target_model;
                    me.window6.show(); # SRM UNCAGE / TARGET ASPECT
                }
                else {
                    me.window3.hide();
                    me.window4.hide();
                    me.window5.hide();
                    me.window6.hide();
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
                        me.window5.show();
                    } else {
                        me.window5.hide();
                    }
                    me.eta = hdp.wp0_eta;
                    if (me.eta != nil and me.eta != "") {
                        hdp.window4_txt = me.eta;
                    } else {
                        hdp.window4 = "XX:XX";
                    }
                    me.window4.show();
                } else {
                    me.window4.hide();
                    me.window5.hide();
                }
                
                if (hdp.gear_down and !hdp.wow) {
                    hdp.window6_txt = sprintf("A%d", hdp.approach_speed);
                    me.window6.show();
                } else {
                    me.window6.hide(); # SRM UNCAGE / TARGET ASPECT
                }
            }

            if (hdp.total_fuel_lbs < 500)
              hdp.window3_txt = "FUEL";

            if (hdp.window9_txt=="") {
                me.alphaHUD = hdp.alpha;
                if (hdp.gear_down) {
                    if (hdp.wow) {
                        me.alphaHUD = 0;
                    }
                }
                hdp.window9_txt = sprintf("AOA %d",me.alphaHUD);
            }

            hdp.window7_txt = sprintf("%.2f",hdp.mach);
            me.window7.show();
        }

        foreach(var update_item; me.update_items)
        {
            update_item.update(hdp);
        }


        me.trackLineShow = 0;
#        if (hdp.FrameCount == 1 or hdp.FrameCount == 3 or me.initUpdate == 1) {
            me.target_idx = 0;
            me.designated = 0;
            ht_yco = pitch_offset;
            ht_xco = 0;
            ht_xcf = me.pixelPerMeterX;
            ht_ycf = -me.pixelPerMeterY;
            
            me.target_locked.setVisible(0);

        if (hdp["tgt_list"] != nil) {
            foreach ( me.u; hdp.tgt_list ) {
                me.callsign = "XX";
                if (me.u.get_display()) {
                    if (me.u.Callsign != nil)
                      me.callsign = me.u.Callsign.getValue();
                    me.model = "XX";

                    if (me.u.ModelType != "")
                      me.model = me.u.ModelType;

                    if (me.target_idx < me.max_symbols) {
                        me.tgt = me.tgt_symbols[me.target_idx];
                        if (me.tgt != nil) {
                            me.tgt.setVisible(me.u.get_display());
                            me.u_dev_rad = (90-me.u.get_deviation(hdp.heading))  * D2R;
                            me.u_elev_rad = (90-me.u.get_total_elevation( hdp.pitch))  * D2R;
                            me.devs = me.develev_to_devroll(hdp, me.u_dev_rad, me.u_elev_rad);
                            me.combined_dev_deg = me.devs[0];
                            me.combined_dev_length =  me.devs[1];
                            #me.clamped = me.devs[2];
                            me.yc = ht_yco + (ht_ycf * me.combined_dev_length * math.cos(me.combined_dev_deg*D2R));
                            me.xc = ht_xco + (ht_xcf * me.combined_dev_length * math.sin(me.combined_dev_deg*D2R));

                            me.clamped = me.yc > me.sy*0.5 or me.yc < -me.sy*0.5+me.hozizon_line_offset_from_middle_in_svg*me.sy or me.xc > me.sx *0.5 or me.xc < -me.sx*0.5; # outside HUD

                            if (hdp.active_u != nil and hdp.active_u.Callsign != nil and me.u.Callsign != nil and me.u.Callsign.getValue() == hdp.active_u.Callsign.getValue()) {
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
                            } else {
                                #
                                # if in symbol reject mode then only show the active target.
                                if (hdp.symbol_reject)
                                  me.tgt.setVisible(0);
                            }
                            me.tgt.setTranslation (me.xc, me.yc);
                            me.tgt.update();
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
        
        me.trackLine.setVisible(me.trackLineShow);

        


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

            notification.range_rate = "RNGRATE";

            if (notification.NotificationType == "FrameNotification")
            {
                if (notification.route_manager_active) {
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

emesary.GlobalTransmitter.Register(f16_hud);
