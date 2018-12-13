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
        obj.scaling = [obj.get_element("alt_tick_0"),obj.get_element("alt_label0"),obj.heading_tape,obj.heading_tape_pointer];
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

        obj.ralt = obj.get_text("radalt", HUD_FONT,9,1.1);

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
        append(obj.total, obj.ralt);
        append(obj.total, obj.radalt_box);

        #obj.VV.set("z-index", 11000);# hmm, its inside layer1, so will still be below the heading readout.
        obj.layer1 = obj.get_element("layer1");#main svg layer.

        input = {
                 IAS                       : "/velocities/airspeed-kt",
                 calibrated                : "/fdm/jsbsim/velocities/vc-kts",
                 TAS                       : "/fdm/jsbsim/velocities/vtrue-kts",
                 GND_SPD                   : "/velocities/groundspeed-kt",
                 HUD_VEL                   : "/f16/avionics/hud-velocity",
                 HUD_SCA                   : "/f16/avionics/hud-scales",
                 Nz                        : "/accelerations/pilot-gdamped",
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
                 hud_brightness            : "f16/avionics/hud-brt",
                 hud_power                 : "f16/avionics/hud-power",
                 hud_display               : "controls/HUD/display-on",
                 hud_serviceable           : "sim/failure-manager/instrumentation/hud/serviceable",
                 time_until_crash          : "instrumentation/radar/time-till-crash",
                 vne                       : "f16/vne",
                 texUp                     : "f16/hud/texels-up",
                 wp_bearing_deg            : "autopilot/route-manager/wp/true-bearing-deg",
                 total_fuel_lbs            : "/consumables/fuel/total-fuel-lbs",
                 bingo                     : "f16/settings/bingo",
                 alow                      : "f16/settings/cara-alow",
                 altitude_agl_ft           : "position/altitude-agl-ft",
                 wp0_eta                   : "autopilot/route-manager/wp[0]/eta",
                 approach_speed            : "fdm/jsbsim/systems/approach-speed",
                 standby                   : "instrumentation/radar/radar-standby",
                 elapsed                   : "sim/time/elapsed-sec",
                 cara                      : "f16/avionics/cara-on",
                 fpm                       : "f16/avionics/hud-fpm",
                 ded                       : "f16/avionics/hud-ded",
                 tgp_mounted               : "f16/stores/tgp-mounted",
                 view_number               : "sim/current-view/view-number",
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
                                            var color = [0.3,1,0.3,0];
                                            foreach(item;obj.total) {
                                              item.setColor(color);
                                            }
                                            obj.triangle120.setColorFill(color);
                                            obj.triangle65.setColorFill(color);
                                          } elsif (hdp.hud_brightness != nil and hdp.hud_power != nil) {
                                            var color = [0.3,1,0.3,hdp.hud_brightness * hdp.hud_power];
                                            foreach(item;obj.total) {
                                              item.setColor(color);
                                            }
                                            obj.triangle120.setColorFill(color);
                                            obj.triangle65.setColorFill(color);
                                          }
                                      }),
            props.UpdateManager.FromHashList([], 0.01, func(hdp)
                                      {
                                      }),
            props.UpdateManager.FromHashList(["master_arm", "altitude_ft", "roll", "groundspeed_kt", "density_altitude", "mach", "speed_down_fps", "speed_east_fps", "speed_north_fps"], 0.01, func(hdp)
                                      {
                                          hdp.CCRP_active = obj.CCRP(hdp);
                                      }),

            props.UpdateManager.FromHashList(["texUp","route_manager_active", "wp_bearing_deg", "heading","VV_x","VV_y"], 0.01, func(hdp)
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
                                                         obj.thing.setTranslation(obj.thingX, obj.sy-obj.texels_up_into_hud+hdp.VV_y * obj.texelPerDegreeY);
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

            props.UpdateManager.FromHashList(["texUp","gear_down"], 0.01, func(val)
                                             {
                                                 if (val.gear_down) {
                                                     obj.boreSymbol.hide();
                                                 } else {
                                                     obj.boreSymbol.setTranslation(obj.sx/2,obj.sy-obj.texels_up_into_hud);
                                                     obj.offangle.setTranslation(obj.sx/2-10,obj.sy-obj.texels_up_into_hud);
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
                                        if (hdp.fpm > 0) {
                                            obj.VV.setTranslation (obj.sx*0.5+hdp.VV_x * obj.texelPerDegreeX, obj.sy-obj.texels_up_into_hud+hdp.VV_y * obj.texelPerDegreeY);
                                            obj.VV.show();
                                            obj.VV.update();
                                        } else {
                                            obj.VV.hide();
                                        }
                                      }),
            props.UpdateManager.FromHashList(["fpm","texUp","gear_down","VV_x","VV_y", "wow"], 0.01, func(hdp)
                                      {
                                        if (hdp.gear_down and !hdp.wow) {
                                          obj.bracket.setTranslation (obj.sx/2+hdp.VV_x * obj.texelPerDegreeX, obj.sy-obj.texels_up_into_hud+13 * obj.texelPerDegreeY);
                                          obj.bracket.show();
                                          obj.roll_lines.hide();
                                          obj.roll_pointer.hide();
                                        } else {
                                          obj.bracket.hide();
                                          if (hdp.fpm==2) {
                                              obj.roll_lines.show();
                                              obj.roll_pointer.show();
                                          } else {
                                              obj.roll_lines.hide();
                                              obj.roll_pointer.hide();
                                          }
                                        }
                                      }),
            props.UpdateManager.FromHashList(["texUp","pitch","roll","fpm","VV_x","VV_y","gear_down"], 0.001, func(hdp)
                                      {
                                          obj.ladder.hide();
                                          obj.roll_pointer.setRotation (hdp.roll_rad);
                                          if (hdp.fpm != 2 and !hdp.gear_down) {
                                            obj.ladder_group.hide();
                                            return;
                                          }
                                            #obj.ladder.setTranslation (0.0, hdp.pitch * pitch_factor+pitch_offset);                                           
                                            #obj.ladder.setCenter (obj.ladder_center[0], obj.ladder_center[1] - hdp.pitch * pitch_factor);
                                            #obj.ladder.setRotation (hdp.roll_rad);
                                            
                                            #obj.ladder.show();
                                            
                                        
                                        #############################
                                        # start new ladder:
                                        #############################
                                        obj.fpi_x = hdp.VV_x * obj.texelPerDegreeX;
                                        obj.fpi_y = hdp.VV_y * obj.texelPerDegreeY;
                                        obj.rot = -hdp.roll * D2R;
                                        
                                        obj.pos_y_rel = obj.fpi_y;#position from bore
                                        obj.fpi_polar = clamp(math.sqrt(obj.fpi_x*obj.fpi_x+obj.pos_y_rel*obj.pos_y_rel),0.0001,10000);
                                        obj.inv_angle = clamp(-obj.pos_y_rel/obj.fpi_polar,-1,1);
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
                                        obj.horizon_lateral  = clamp(obj.fpi_pos_rel_x,-obj.max_lateral_pitchnumbers,obj.max_lateral_pitchnumbers_p);




                                        #obj.horizon_vertical = clamp(-math.cos(obj.fpi_angle-obj.rot)*obj.fpi_polar, -obj.sy*0, obj.sy*0.75);
                                        obj.h_rot.setRotation(obj.rot);
                                        obj.horizon_group.setTranslation(obj.sx*0.5, obj.sy-obj.texels_up_into_hud);#place it on bore
                                        obj.ladder_group.setTranslation(obj.horizon_lateral, obj.texelPerDegreeY * hdp.pitch);
                                        obj.ladder_group.show();
                                        obj.ladder_group.update();
                                        obj.horizon_group.update();
                                      }),
#            props.UpdateManager.FromHashValue("roll_rad", 1.0, func(roll_rad)
#                                      {
#                                      }),
            props.UpdateManager.FromHashList(["altitude_agl_ft","cara"], 1.0, func(hdp)
                                      {
                                          obj.agl=hdp.altitude_agl_ft;
                                          if(hdp.cara) {
                                              if(obj.agl < 10) {
                                                obj.ralt.setText(sprintf("R %05d ",obj.agl));
                                              } else {
                                                obj.ralt.setText(sprintf("R %05d ",math.round(obj.agl,10)));
                                              }
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
                                          obj.alt_curr.setText(sprintf("%5d",10*int(measured_altitude*0.1)));
                                      }),
            props.UpdateManager.FromHashValue("HUD_SCA", 0.5, func(HUD_SCA)
                                      {
                                          if (HUD_SCA) {
                                            foreach(tck;obj.scaling) {
                                                tck.show();
                                              }
                                          } else {
                                              foreach(tck;obj.scaling) {
                                                tck.hide();
                                              }
                                          }
                                      }),
            props.UpdateManager.FromHashList(["calibrated", "GND_SPD", "HUD_VEL", "gear_down"], 0.5, func(hdp)
                                      {   
                                          # the real F-16 has calibrated airspeed as default in HUD.
                                          if (hdp.HUD_VEL == 1 or hdp.gear_down) {
                                            obj.ias_range.setTranslation(0, hdp.calibrated * ias_range_factor);
                                            obj.speed_type.setText("C");
                                            obj.speed_curr.setText(sprintf("%d",hdp.calibrated));
                                          } elsif (hdp.HUD_VEL == 0) {
                                            obj.ias_range.setTranslation(0, hdp.TAS * ias_range_factor);
                                            obj.speed_type.setText("T");
                                            obj.speed_curr.setText(sprintf("%d",hdp.TAS));
                                          } else {
                                            obj.ias_range.setTranslation(0, hdp.GND_SPD * ias_range_factor);
                                            obj.speed_type.setText("G");
                                            obj.speed_curr.setText(sprintf("%d",hdp.GND_SPD));
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
            props.UpdateManager.FromHashValue("Nz", 0.1, func(Nz)
                                      {
                                          obj.window8.setText(sprintf("%.1f", Nz));
                                          obj.window8.show();
                                      }),
            props.UpdateManager.FromHashList(["heading", "headingMag", "useMag","gear_down"], 0.1, func(hdp)
                                      {
                                          var head = hdp.useMag?hdp.headingMag:hdp.heading;
                                          obj.head_curr.setText(sprintf("%03d",head));
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

                                          obj.heading_tape.setTranslation (obj.heading_tape_position,obj.heading_tape_positionY);
                                          obj.heading_tape_pointer.setTranslation (0,obj.heading_tape_positionY);
                                      }
                                            ),
            props.UpdateManager.FromHashList(["time_until_crash","vne"], 0.1, func(hdp)
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
            props.UpdateManager.FromHashList(["standby"], 0.5, func(hdp)
                                             {
                                                 if (hdp.standby) {
                                                     obj.stby.setText("NO RAD");
                                                     obj.stby.show();
                                                 } else {
                                                     obj.stby.hide();
                                                 }
                                                 obj.stby.update();
                                             }
                                            ),
            props.UpdateManager.FromHashList(["brake_parking", "gear_down", "flap_pos_deg", "CCRP_active", "master_arm","submode"], 0.1, func(hdp)
                                             {
                                                 if (hdp.brake_parking) {
                                                     obj.window2.setVisible(1);
                                                     obj.window2.setText(" BRAKES");
                                                 } elsif (hdp.flap_pos_deg > 0 or hdp.gear_down) {
                                                     obj.window2.setVisible(1);
                                                     obj.gd = "";
                                                     if (hdp.gear_down)
                                                       obj.gd = " G";
                                                     obj.window2.setText(sprintf(" F %d%s",hdp.flap_pos_deg,obj.gd));
                                                 } elsif (hdp.master_arm) {
                                                     var submode = "";
                                                     if (hdp.CCRP_active) {
                                                        submode = "CCRP";
                                                     } elsif (hdp.submode == 1) {
                                                        submode = "BORE";
                                                     }
                                                     obj.window2.setText(" ARM "~submode);
                                                     obj.window2.setVisible(1);
                                                 } else {
                                                     obj.window2.setText(" NAV");
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
                .setAlignment("center-center")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(11, 1.1);

          append(obj.total, obj.stby);
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
              append(obj.total, obj.raltFrame);
        obj.boreSymbol = obj.svg.createChild("path")
                .moveTo(-5,0)
                .horiz(10)
                .moveTo(0,-5)
                .vert(10)
                .setStrokeLineWidth(1)
                .setColor(0,1,0);
            append(obj.total, obj.boreSymbol);
        obj.bracket = obj.svg.createChild("path")
                .moveTo(0,-34)
                .horiz(-10)
                .vert(68)
                .horiz(10)
                .setStrokeLineWidth(1)
                .setColor(0,1,0);
                append(obj.total, obj.bracket);
        obj.speed_indicator = obj.svg.createChild("path")
                .moveTo(0.25*sx*0.695633,sy*0.245)
                .horiz(7)
                .setStrokeLineWidth(1)
                .setColor(1,0,0);
                append(obj.total, obj.speed_indicator);
        obj.alti_indicator = obj.svg.createChild("path")
                .moveTo(3+0.75*sx*0.695633,sy*0.245)
                .horiz(7)
                .setStrokeLineWidth(1)
                .setColor(1,0,0);
                append(obj.total, obj.alti_indicator);
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
        append(obj.total, obj.speed_type);
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
                .setTranslation(5+3+0.79*sx*0.695633,sy*0.245-6)
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
                .moveTo(8-2+0.80*sx*0.695633,sy*0.245)
                .lineTo(8-2+0.80*sx*0.695633+5,sy*0.245-6)
                .horiz(28)
                .vert(12)
                .horiz(-28)
                .lineTo(8-2+0.80*sx*0.695633,sy*0.245)
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
                .setTranslation(8+0.82*sx*0.695633,sy*0.245)
                .setAlignment("left-center")
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
        obj.offangle = obj.svg.createChild("text")# real name: locator line
                .setText("0")
                .setAlignment("right-center")
                .setColor(0,1,0,1)
                .setFont(HUD_FONT)
                .setFontSize(9, 1.1);
                append(obj.total, obj.offangle);
        obj.trackLine = obj.svg.createChild("path")
                .moveTo(0,0)
                #.horiz(10)
                .vert(-30)
                .setStrokeLineWidth(1)
                .setColor(0,1,0);

            append(obj.total, obj.trackLine);
        obj.bombFallLine = obj.svg.createChild("path")
                .moveTo(sx*0.5*0.695633,0)
                #.horiz(10)
                .vert(400)
                .setStrokeLineWidth(1)
                .setColor(0,1,0).hide();
                append(obj.total, obj.bombFallLine);
        obj.solutionCue = obj.svg.createChild("path")
                .moveTo(sx*0.5*0.695633-5,0)
                .horiz(10)
                .setStrokeLineWidth(2)
                .setColor(0,1,0);
                append(obj.total, obj.solutionCue);
        obj.ccrpMarker = obj.svg.createChild("path")
                .moveTo(sx*0.5*0.695633-10,sy*0.5)
                .horiz(20)
                .setStrokeLineWidth(1)
                .setColor(0,1,0);
                append(obj.total, obj.ccrpMarker);
        obj.thing = obj.svg.createChild("path")
            .moveTo(-2.5,0)
            .arcSmallCW(2.5,2.5, 0, 2.5*2, 0)
            .arcSmallCW(2.5,2.5, 0, -2.5*2, 0)
            .moveTo(0,-2.5)
            .vert(-10)
            .setStrokeLineWidth(1)
            .setColor(0,1,0);
            append(obj.total, obj.thing);
        var mr = 0.4;#milliradians
        obj.circle262 = obj.svg.createChild("path")#rdsearch (Allowable Steering Error Circle (ASEC))
            .moveTo(-262*mr,0)
            .arcSmallCW(262*mr,262*mr, 0, 262*mr*2, 0)
            .arcSmallCW(262*mr,262*mr, 0, -262*mr*2, 0)
            .setStrokeLineWidth(1)
            .setColor(0,1,0).hide()
            .setTranslation(sx*0.5*0.695633,sy*0.25+262*mr*0.5);
            append(obj.total, obj.circle262);
        obj.circle100 = obj.svg.createChild("path")#irsearch
            .moveTo(-100*mr,0)
            .arcSmallCW(100*mr,100*mr, 0, 100*mr*2, 0)
            .arcSmallCW(100*mr,100*mr, 0, -100*mr*2, 0)
            .setStrokeLineWidth(1)
            .setColor(0,1,0).hide()
            .setTranslation(sx*0.5*0.695633,sy*0.25);
            append(obj.total, obj.circle100);
        obj.circle120 = obj.svg.createChild("path")#rdlock
            .moveTo(-120*mr,0)
            .arcSmallCW(120*mr,120*mr, 0, 120*mr*2, 0)
            .arcSmallCW(120*mr,120*mr, 0, -120*mr*2, 0)
            .setStrokeLineWidth(1)
            .setColor(0,1,0).hide()
            .setTranslation(sx*0.5*0.695633,sy*0.25);
            append(obj.total, obj.circle120);
        obj.circle65 = obj.svg.createChild("path")#irlock
            .moveTo(-65*mr,0)
            .arcSmallCW(65*mr,65*mr, 0, 65*mr*2, 0)
            .arcSmallCW(65*mr,65*mr, 0, -65*mr*2, 0)
            .setStrokeLineWidth(1)
            .setColor(0,1,0).hide()
            .setTranslation(sx*0.5*0.695633,sy*0.25);
            append(obj.total, obj.circle65);
        obj.triangle65  = obj.svg.createChild("path")
            .moveTo(0,-65*mr)
            .lineTo(-5*mr,-75*mr)
            .lineTo(5*mr,-75*mr)
            .lineTo(0,-65*mr)
            .setStrokeLineWidth(1)
            .setColorFill(0,1,0)
            .setColor(0,1,0)
            #.set("z-index",10500)
            .setTranslation(sx*0.5*0.695633,sy*0.25);
            append(obj.total, obj.triangle65);
        obj.triangle120 = obj.svg.createChild("path")
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
            append(obj.total, obj.triangle120);
        var boxRadius = 10;
        var boxRadiusHalf = boxRadius*0.5;
        var hairFactor = 0.8;
        obj.radarLock = obj.svg.createChild("path")
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
        obj.irLock = obj.svg.createChild("path")
            .moveTo(-boxRadius,0)
            .lineTo(0,-boxRadius)
            .lineTo(boxRadius,0)
            .lineTo(0,boxRadius)
            .lineTo(-boxRadius,0)
            .setStrokeLineWidth(1)
            .setColor(0,1,0);
            append(obj.total, obj.irLock);
        obj.irSearch = obj.svg.createChild("path")
            .moveTo(-boxRadiusHalf,0)
            .lineTo(0,-boxRadiusHalf)
            .lineTo(boxRadiusHalf,0)
            .lineTo(0,boxRadiusHalf)
            .lineTo(-boxRadiusHalf,0)
            .setStrokeLineWidth(1)
            .setColor(0,1,0);
            append(obj.total, obj.irSearch);
        obj.target_locked.hide();
        obj.target_locked = obj.svg.createChild("path")
            .moveTo(-boxRadius,-boxRadius)
            .vert(boxRadius*2)
            .horiz(boxRadius*2)
            .vert(-boxRadius*2)
            .horiz(-boxRadius*2)
            .setStrokeLineWidth(1)
            .setColor(0,1,0);
            append(obj.total, obj.target_locked);
        obj.VV.hide();
        mr = mr*1.5;#incorrect, but else in FG it will seem too small.
        obj.VV = obj.svg.createChild("path")
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


    obj.horizon_group = obj.svg.createChild("group")
      .set("z-order", 1);
    obj.ladder_group = obj.horizon_group.createChild("group");
    obj.h_rot   = obj.horizon_group.createTransform();

    # pitch lines
    var pixelPerDegreeY = 15.43724802231049;
    var pixelPerDegreeX = 16.70527172464148;
    var distance = pixelPerDegreeY * 5;
    var minuss = 0.125*sx*0.695633;
    var minuso = 20*mr;
    for(var i = 1; i <= 18; i += 1) # full drawn lines
      append(obj.total, obj.ladder_group.createChild("path")
         .moveTo(minuso, -i * distance)
         .horiz(minuss)
         .vert(minuso*0.5)

         .moveTo(-minuso, -i * distance)
         .horiz(-minuss)
         .vert(minuso*0.5)
         
         .setStrokeLineWidth(1)
         .setColor(0,0,0));
    
    for(var i = -18; i <= -1; i += 1) { # stipled lines
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

    #pitch line numbers
    for(var i = -18; i <= 0; i += 1) {
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
    for(var i = 1; i <= 18; i += 1) {
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
                     .moveTo(-0.40*sx*0.695633, 0)
                     .horiz(0.40*sx*0.695633-20*mr)
                     .moveTo(20*mr, 0)
                     .horiz(0.40*sx*0.695633)
                     .setStrokeLineWidth(1)
                     .setColor(0,0,0));

    obj.tgpPointF = obj.svg.createChild("path")
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
    obj.tgpPointC = obj.svg.createChild("path")
                     .moveTo(-10*mr, -10*mr)
                     .lineTo(10*mr, 10*mr)
                     .moveTo(10*mr, -10*mr)
                     .lineTo(-10*mr, 10*mr)
                     .setStrokeLineWidth(1)
                     .setColor(0,0,0);
    append(obj.total, obj.tgpPointF);
    append(obj.total, obj.tgpPointC);











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
        if (pylons.fcs != nil and pylons.fcs.getSelectedWeapon() != nil and (pylons.fcs.getSelectedWeapon().type=="MK-82" or pylons.fcs.getSelectedWeapon().type=="MK-83" or pylons.fcs.getSelectedWeapon().type=="MK-84" or pylons.fcs.getSelectedWeapon().type=="GBU-12" or pylons.fcs.getSelectedWeapon().type=="GBU-31" or pylons.fcs.getSelectedWeapon().type=="GBU-24") 
            and hdp.active_u != nil and hdp.master_arm ==1 and pylons.fcs.getSelectedWeapon().status == armament.MISSILE_LOCK) {

            if (pylons.fcs.getSelectedWeapon().type=="MK-82" or pylons.fcs.getSelectedWeapon().type=="MK-83") {
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
            hdp.window2_txt = "3";
            hdp.window4_txt = "4";
            hdp.window5_txt = "5";
            hdp.window6_txt = "6";
            hdp.window7_txt = "7";
            hdp.window8_txt = "8";
            hdp.window9_txt = "9";
            hdp.window10_txt = "10";
            hdp.window11_txt = "11";
        }

        if (hdp.FrameCount == 2 or me.initUpdate == 1) {
            # calc of pitch_offset (compensates for AC3D model translated and rotated when loaded. Also semi compensates for HUD being at an angle.)
            me.Hz_b =    0.669786;#0.676226;#0.663711;#0.801701;# HUD position inside ac model after it is loaded, translated (0.08m) and rotated (0.7d).
            me.Hz_t =    0.85608;#0.86608;#0.841082;#0.976668;
            me.Hx_m =   -4.62918;#-4.62737;#-4.65453;#-4.6429;# HUD median X pos
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
        me.submode = 0;

        if (hdp.wow0) {
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
            hdp.window10_txt = "";
            hdp.window11_txt = "";

            me.circle262.hide();
            me.circle100.hide();
            me.circle120.hide();
            me.circle65.hide();

            if(hdp.master_arm and pylons.fcs != nil)
            {
                hdp.weapon_selected = pylons.fcs.selectedType;
                hdp.weapn = pylons.fcs.getSelectedWeapon();
                
                if (hdp.weapon_selected != nil)
                {
                    if (hdp.weapon_selected == "20mm Cannon") {
                        hdp.window9_txt = sprintf("%3d", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "AIM-9") {
                        hdp.window9_txt = sprintf("%d SRM", pylons.fcs.getAmmo());
                        if (hdp.weapn != nil) {
                            if (hdp.weapn.status == armament.MISSILE_LOCK) {
                                me.circle65.show();
                            } else {
                                me.circle100.show();
                            }
                        }
                    } elsif (hdp.weapon_selected == "AIM-120") {
                        hdp.window9_txt = sprintf("%d LRM", pylons.fcs.getAmmo());
                        if (hdp.weapn != nil) {
                            if (hdp.weapn.status == armament.MISSILE_LOCK) {
                                me.circle120.show();
                            } else {
                                me.circle262.show();
                            }
                        }
                    } elsif (hdp.weapon_selected == "AIM-7") {
                        hdp.window9_txt = sprintf("%d MRM", pylons.fcs.getAmmo());
                        if (hdp.weapn != nil) {
                            if (hdp.weapn.status == armament.MISSILE_LOCK) {
                                me.circle120.show();
                            } else {
                                me.circle262.show();
                            }
                        }
                    } elsif (hdp.weapon_selected == "GBU-12") {
                        hdp.window9_txt = sprintf("%d GB12", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "AGM-65") {
                        hdp.window9_txt = sprintf("%d AG65", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "AGM-84") {
                        hdp.window9_txt = sprintf("%d AG84", pylons.fcs.getAmmo());
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
                    } elsif (hdp.weapon_selected == "GBU-24") {
                        hdp.window9_txt = sprintf("%d GB24", pylons.fcs.getAmmo());
                    } elsif (hdp.weapon_selected == "AGM-158") {
                        hdp.window9_txt = sprintf("%d AG158", pylons.fcs.getAmmo());
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
                
                if (hdp.gear_down and !hdp.wow) {
                    hdp.window6_txt = sprintf("A%d", hdp.approach_speed);
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

            if (hdp.total_fuel_lbs < hdp.bingo and math.mod(int(4*(hdp.elapsed-int(hdp.elapsed))),2)>0) {
              hdp.window11_txt = "FUEL";
            } elsif (hdp.total_fuel_lbs < hdp.bingo) {
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

            hdp.window7_txt = sprintf(" %.2f",hdp.mach);
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

        me.irL = 0;
        me.irS = 0;
        me.rdL = 0;
        me.irT = 0;
        me.rdT = 0;
        #printf("%d %d %d %s",hdp.master_arm,pylons.fcs != nil,pylons.fcs.getAmmo(),hdp.weapon_selected);
        if(hdp.master_arm and pylons.fcs != nil and pylons.fcs.getAmmo() > 0) {
            hdp.weapon_selected = pylons.fcs.selectedType;
            if (hdp.weapon_selected == "AIM-120" or hdp.weapon_selected == "AIM-7") {
                if (!pylons.fcs.isLock()) {
                    me.radarLock.setTranslation(me.sx/2, me.sy*0.25+262*0.4*0.5);
                    me.rdL = 1;
                }                
            } elsif (!pylons.fcs.isLock() and hdp.weapon_selected == "AIM-9") {
                if (pylons.bore) {
                    var aim = pylons.fcs.getSelectedWeapon();
                    if (aim != nil) {
                        me.submode = 1;
                        var coords = aim.getSeekerInfo();
                        me.irSearch.setTranslation(me.sx/2+me.texelPerDegreeX*coords[0],me.sy-me.texels_up_into_hud-me.texelPerDegreeY*coords[1]);
                    }
                } else {
                    me.irSearch.setTranslation(me.sx/2, me.sy*0.25);
                }
                me.irS = 1;
            } elsif (pylons.fcs.isLock() and hdp.weapon_selected == "AIM-9" and pylons.bore) {
                var aim = pylons.fcs.getSelectedWeapon();
                if (aim != nil) {
                    var coords = aim.getSeekerInfo();
                    if (coords != nil) {
                        me.irLock.setTranslation(me.sx/2+me.texelPerDegreeX*coords[0],me.sy-me.texels_up_into_hud-me.texelPerDegreeY*coords[1]);
                        me.irL = 1;
                    }
                }
            }
        }
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
                                me.tgt.hide();
                                me.xcS = me.sx/2                     + (me.pixelPerMeterX * me.combined_dev_length * math.sin(me.combined_dev_deg*D2R));
                                me.ycS = me.sy-me.texels_up_into_hud - (me.pixelPerMeterY * me.combined_dev_length * math.cos(me.combined_dev_deg*D2R));
                                me.target_locked.setTranslation (me.xcS, me.ycS);
                                
                                if (pylons.fcs != nil and pylons.fcs.isLock()) {
                                    #me.target_locked.setRotation(45*D2R);
                                    if (hdp.weapon_selected == "AIM-120" or hdp.weapon_selected == "AIM-7" or hdp.weapon_selected == "AIM-9") {
                                        var aim = pylons.fcs.getSelectedWeapon();
                                        if (aim != nil) {
                                            var coords = aim.getSeekerInfo();
                                            if (coords != nil) {
                                                me.irLock.setTranslation(me.sx/2+me.texelPerDegreeX*coords[0],me.sy-me.texels_up_into_hud-me.texelPerDegreeY*coords[1]);
                                                me.radarLock.setTranslation(me.sx/2+me.texelPerDegreeX*coords[0],me.sy-me.texels_up_into_hud-me.texelPerDegreeY*coords[1]);
                                            }
                                        }
                                    }
                                    if (hdp.weapon_selected == "AIM-120" or hdp.weapon_selected == "AIM-7") {
                                        #me.radarLock.setTranslation(me.xcS, me.ycS); too perfect
                                        me.triangle120.setRotation(D2R*(hdp.active_u.get_heading()-hdp.heading));
                                        me.rdL = 1;
                                        me.rdT = 1;
                                    } elsif (hdp.weapon_selected == "AIM-9") {
                                        #me.irLock.setTranslation(me.xcS, me.ycS);
                                        me.triangle65.setRotation(D2R*(hdp.active_u.get_heading()-hdp.heading));
                                        me.irL = 1;
                                        me.irT = 1;
                                    }                                    
                                } else {
                                    #me.target_locked.setRotation(0);
                                }
                                if (me.clamped) {
                                    me.trackLine.setTranslation(me.sx/2,me.sy-me.texels_up_into_hud);
                                    me.trackLine.setRotation(me.combined_dev_deg*D2R);
                                    me.dev_h_d = me.u.get_deviation(hdp.heading);
                                    me.dev_e_d = me.u.get_total_elevation(hdp.pitch);
                                    me.offangle.setText(sprintf("%d", math.sqrt(me.dev_h_d*me.dev_h_d+me.dev_e_d*me.dev_e_d)));
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
        
        
        #print(me.irS~" "~me.irL);

        me.trackLine.setVisible(me.trackLineShow);
        me.offangle.setVisible(me.trackLineShow);

        


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
                    me.scale120 = clamp(me.scale120,30/120,1);
                    me.circle120.setScale(me.scale120,me.scale120);
                    me.circle120.setStrokeLineWidth(1/me.scale120);
                    #me.triangle120.setScale(me.scale120,me.scale120);
                    #me.triangle120.setStrokeLineWidth(1/me.scale120);
                    me.triangle120.setTranslation(me.sx*0.5,me.sy*0.25-me.scale120*0.4*120);#0.4=mr
                    #me.triangle120.setCenter(0,me.scale120*0.4*120);
                    me.triangle120.setCenter(0,me.scale120*0.4*120);
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
        me.triangle120.setVisible(me.rdT);
        me.triangle65.setVisible(me.irT);
        me.radarLock.update();
        me.irLock.update();

        if (hdp.ded) {
            me.ded0.setText(ded.text[0]);
            me.ded1.setText(ded.text[1]);
            me.ded2.setText(ded.text[2]);
            me.ded3.setText(ded.text[3]);
            me.ded4.setText(ded.text[4]);
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

        if (hdp.tgp_mounted and tgp.flir_updater.click_coord_cam != nil) {
            var b = geo.normdeg180(getprop("sim/view[102]/heading-offset-deg"));
            var p = getprop("sim/view[102]/pitch-offset-deg");
            var y = me.clamp(-p*me.texelPerDegreeY+me.sy-me.texels_up_into_hud,me.sy*0.05,me.sy*0.95);
            var x = me.clamp(b*me.texelPerDegreeX+me.sx*0.5,me.sx*0.025,me.sx*0.975);
            if (y == me.sy*0.05 or y == me.sy*0.95 or x == me.sx*0.025 or x == me.sx*0.975) {
                me.tgpPointC.setTranslation(x,y);
                me.tgpPointC.show();
            } else {
                me.tgpPointC.hide();
            }
            me.tgpPointF.setTranslation(x,y);
            me.tgpPointF.show();
        } else {
            me.tgpPointF.hide();
            me.tgpPointC.hide();
        }


        me.initUpdate = 0;

        hdp.submode = me.submode;
        
        foreach(var update_item; me.update_items)
        {
            update_item.update(hdp);
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
