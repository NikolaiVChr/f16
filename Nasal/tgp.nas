# Copyright (C) 2016  onox
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Lines below FLIRCameraUpdater has been modified/added by Nikolai V. Chr.
#
# Position of the FLIR camera ([z (back), x (right), y (up)])
var coords_cam = [
    getprop("/sim/view[105]/config/z-offset-m"),
    getprop("/sim/view[105]/config/x-offset-m"),
    getprop("/sim/view[105]/config/y-offset-m")
];
io.include("Aircraft/Generic/updateloop.nas");
#io.load_nasal(getprop("/sim/fg-root") ~ "/Aircraft/c172p/Nasal/generic/math_ext.nas","math_ext");
var FLIRCameraUpdater = {

    new: func {
        var m = {
            parents: [FLIRCameraUpdater, Updatable]
        };
        m.loop = UpdateLoop.new(components: [m], update_period: 0.0);

        # Create a function to update the position of the FLIR camera
        m.update_cam = me._get_flir_auto_updater(180.0);

        # Create a function to update the position using an input device
        m.manual_update_cam = me._get_flir_updater(180.0, m.update_cam);

        m.click_coord_cam = nil;

        m.listeners = std.Vector.new();

        m.offsetP = 0;
        m.offsetH = 0;

        return m;
    },

    enable: func {
        #me.loop.reset();
        me.loop.enable();
    },

    disable: func {
        #me.remove_listeners();
        me.loop.disable();
    },

    enable_or_disable: func (enable) {
        if (enable) {
            me.enable();
        }
        else {
            me.disable();
        }
    },

    remove_listeners: func {
        foreach (var listener; me.listeners.vector) {
            removelistener(listener);
        }
        me.listeners.clear();
    },

    reset: func {
        #print("reset called?!?!");
        return;
        me.remove_listeners();
        me.listeners.append(setlistener("/sim/signals/click", func {
            var lat = getprop("/sim/input/click/latitude-deg");
            var lon = getprop("/sim/input/click/longitude-deg");
            var elev = getprop("/sim/input/click/elevation-m");

            var click_position = geo.Coord.new().set_latlon(lat, lon, elev);

            var origin_position = geo.aircraft_position();
            var distance_m = origin_position.direct_distance_to(click_position);

            if (getprop("/aircraft/flir/locks/auto-track")) {
                me.click_coord_cam = click_position;
                setprop("/aircraft/flir/target/auto-track", 1);
                logger.screen.white(sprintf("New tracking position at %d meter distance", distance_m));
            }
            else {
                setprop("/aircraft/flir/target/auto-track", 0);
                me.click_coord_cam = nil;
                logger.screen.red("Press F6 to enable automatic tracking by FLIR camera");
            }
        }));

        me.listeners.append(setlistener("/aircraft/flir/locks/auto-track", func (n) {
            setprop("/aircraft/flir/target/auto-track", 0);
            me.click_coord_cam = nil;
            if (n.getBoolValue()) {
                logger.screen.green("Automatic tracking by FLIR camera enabled. Click on the terrain to start tracking.");
            }
            else {
                logger.screen.red("Automatic tracking by FLIR camera disabled");
            }
        }));
    },

    update: func (dt) {
        var roll_deg  = getprop("/orientation/roll-deg");
        var pitch_deg = getprop("/orientation/pitch-deg");
        var heading   = getprop("/orientation/heading-deg");

        var computer = me._get_flir_computer(roll_deg, pitch_deg, heading);

        if (getprop("/aircraft/flir/target/auto-track") and me.click_coord_cam != nil) {
            var (yaw, pitch, distance) = computer(coords_cam, me.click_coord_cam);
            if (lock_tgp) {
                me.update_cam(roll_deg, pitch_deg, yaw, pitch);
            } else {
                me.update_cam(roll_deg, pitch_deg, yaw+me.offsetH, pitch+me.offsetP);
            }
        }
#        else {
#            me.manual_update_cam(roll_deg, pitch_deg);
#        }
    },

    aim: func () {
        var roll_deg  = getprop("/orientation/roll-deg");
        var pitch_deg = getprop("/orientation/pitch-deg");
        var heading   = getprop("/orientation/heading-deg");

        var computer = me._get_flir_computer(roll_deg, pitch_deg, heading);

        if (getprop("/sim/current-view/name") == "TGP" and me.click_coord_cam != nil) {
            var (yaw, pitch, distance) = computer(coords_cam, me.click_coord_cam);
            me.update_cam(roll_deg, pitch_deg, yaw, pitch);
        }
    },

    ######################################################################
    # Gyro stabilization                                                 #
    ######################################################################

    _get_flir_updater: func (offset, updater) {
        return func (roll_deg, pitch_deg) {
            var yaw   = getprop("/aircraft/flir/input/yaw-deg") + (180.0 - offset);
            var pitch = getprop("/aircraft/flir/input/pitch-deg");

            updater(roll_deg, pitch_deg, yaw, pitch);
        };
    },

    ######################################################################
    # Automatic tracking computation                                     #
    ######################################################################

    _get_flir_auto_updater: func (offset) {
        return func (roll_deg, pitch_deg, yaw, pitch) {
            (yaw, pitch) = math_ext.get_yaw_pitch_body(roll_deg, pitch_deg, yaw, pitch, offset);

            setprop("/aircraft/flir/target/yaw-deg", yaw);
            setprop("/aircraft/flir/target/pitch-deg", pitch);
            if (getprop("/sim/current-view/name") == "TGP") {
                setprop("/sim/current-view/goal-heading-offset-deg", -yaw);
                setprop("/sim/current-view/goal-pitch-offset-deg", pitch);
            }
            setprop("sim/view[105]/heading-offset-deg", yaw);
            setprop("sim/view[105]/pitch-offset-deg", pitch);
        };
    },

    _get_flir_computer: func (roll_deg, pitch_deg, heading) {
        return func (coords, target) {
            var (position_2d, position) = math_ext.get_point(coords[0], coords[1], coords[2], roll_deg, pitch_deg, heading);
            return math_ext.get_yaw_pitch_distance_inert(position_2d, position, target, heading);
        }
    }

};

math_ext.get_yaw_pitch_distance_inert = func (position_2d, position, target_position, heading, f=nil) {
    # Does the same as Onox's version, except takes curvature of Earth into account.
    var heading_deg = positioned.courseAndDistance(position_2d, target_position)[0] - heading;
    var pitch_deg   = vector.Math.getPitch(position, target_position);
    var distance_m  = position.direct_distance_to(target_position);
    return [heading_deg, pitch_deg, distance_m];
}

var flir_updater = FLIRCameraUpdater.new();

setlistener("/sim/signals/fdm-initialized", func {
    setlistener("/aircraft/flir/target/view-enabled", func (node) {
        flir_updater.enable_or_disable(node.getBoolValue());
    }, 1, 0);
});

var steerlock = 0;
var enable = 1;
var camera_movement_speed_lock = 75;#Higher number means slower
var camera_movement_speed_free =  5;

var list = func () {
    var button = getprop("controls/MFD[2]/button-pressed");
    if (button == 20) {#BACK
        setprop("sim/current-view/view-number",0);
        #setprop("/aircraft/flir/target/auto-track", 0);
        #lock.hide();
        #setprop("f16/avionics/lock-flir",0.05);
        return;
    } elsif (button == 3) {#STBY/A-G/A-A
        if (getprop("f16/avionics/power-mfd") and getprop("f16/avionics/power-ufc-warm")==1 and getprop("f16/avionics/power-right-hdpt") == 1 and getprop("fdm/jsbsim/elec/bus/ess-dc") > 20) {
            masterMode = !masterMode;
        }
    }
    if (!enable) return;
    
    
    
    if (button == 1 or (getprop("controls/displays/cursor-click") and getprop("/sim/current-view/name") == "TGP")) {#LOCK
        gps = 0;
        if (lock_tgp) {
            lock_tgp = 0;
            armament.contactPoint = nil;
            return;
        }
        var x = -2.5856;
        var y =  0.8536;
        var z = -1.4121;
        var pos = aircraftToCart({x:-x, y:y, z: -z});
        var coordA = geo.Coord.new();
        coordA.set_xyz(pos.x, pos.y, pos.z);
        var matrixMath = 0;
        if (matrixMath) {
            var dirCoord = geo.Coord.new(coordA);
            var vHead = getprop("sim/current-view/heading-offset-deg");
            var vPitch = getprop("sim/current-view/pitch-offset-deg");

            var vectorF = vector.Math.eulerToCartesian3X(-getprop("orientation/heading-deg"),getprop("orientation/pitch-deg"),getprop("orientation/roll-deg"));
            var vectorL = vector.Math.eulerToCartesian3Y(-getprop("orientation/heading-deg"),getprop("orientation/pitch-deg"),getprop("orientation/roll-deg"));
            var vectorU = vector.Math.eulerToCartesian3Z(-getprop("orientation/heading-deg"),getprop("orientation/pitch-deg"),getprop("orientation/roll-deg"));
            var viewM   = vector.Math.viewMatrix(vectorF,vectorL,vectorU);
            var pitchM = vector.Math.pitchMatrix(vPitch);
            var yawM   = vector.Math.yawMatrix(-vHead);
            var rotation = vector.Math.multiplyMatrices(pitchM, yawM);#heading, pitch
            var viewGlobal = vector.Math.multiplyMatrices4(viewM, vector.Math.to4x4(rotation));#order?
            #viewGlobal = vector.Math.multiplyMatrices4(viewGlobal,vector.Math.mirrorMatrix);
            #var vectorA = [viewGlobal[2],viewGlobal[6],viewGlobal[10]];
            var vectorA = vector.Math.normalize(vector.Math.xFromView(viewGlobal));
            #vectorA = vector.Math.multiplyMatrixWithVector(rotation, vectorF);
            print(vector.Math.format(vectorA));
            var set = vector.Math.cartesianToEuler(vectorA);
            
            #if (set[0] == nil) {print("0 heading");return;}
            #printf("%d heading %d pitch",set[0],set[1]);
            dirCoord.apply_course_distance(set[0],50);
            var up = math.tan(set[1]*D2R)*50;
            dirCoord.set_alt(coordA.alt()+up);
        }

        # get quaternion for view rotation:
        var q = [getprop("sim/current-view/debug/orientation-w"),getprop("sim/current-view/debug/orientation-x"),getprop("sim/current-view/debug/orientation-y"),getprop("sim/current-view/debug/orientation-z")];

        var V = [2 * (q[1] * q[3] - q[0] * q[2]), 2 * (q[2] * q[3] + q[0] * q[1]),1 - 2 * (q[1] * q[1] + q[2] * q[2])];
        var w= q[0];
        var x= q[1];
        var y= q[2];
        var z= q[3];

        #rotate from x axis using the quaternion:
        V = [1 - 2 * (y*y + z*z),2 * (x*y + w*z),2 * (x*z - w*y)];

        var xyz          = {"x":coordA.x(),                "y":coordA.y(),               "z":coordA.z()};
        #var directionLOS = {"x":dirCoord.x()-coordA.x(),   "y":dirCoord.y()-coordA.y(),  "z":dirCoord.z()-coordA.z()};
        var directionLOS = {"x":V[0],   "y":V[1],  "z":V[2]};

        # Check for terrain between own weapon and target:
        var terrainGeod = get_cart_ground_intersection(xyz, directionLOS);
        if (terrainGeod == nil) {
            #print("0 terrain");
            return;
        } else {
            var terrain = geo.Coord.new();
            terrain.set_latlon(terrainGeod.lat, terrainGeod.lon, terrainGeod.elevation);
            var ut = nil;
            foreach (u ; radar_system.getCompleteList()) {
                if (terrain.direct_distance_to(u.get_Coord())<45) {
                    ut = u;
                    break;
                }
            }
            if (ut!=nil) {
                var contact = ut.getNearbyVirtualContact(0);
                armament.contactPoint = contact;
            } else {
                armament.contactPoint = fc.ContactTGP.new("TGP-Spot",terrain,1);
            }
            #flir_updater.click_coord_cam = terrain;
            #setprop("/aircraft/flir/target/auto-track", 1);
            #interpolate("f16/avionics/lock-flir",1,1.5);
            #flir_updater.offsetP = 0;
            #flir_updater.offsetH = 0;# commented so we get back to where we were when unlocking
            lock_tgp = 1;
        }
    } elsif (button == 6) {#TV/IR
        ir = !ir;
    } elsif (button == 9) {#CZ
        if (lock_tgp) return;
        gps = 0;
        if (getprop("/aircraft/flir/target/auto-track")) {
            flir_updater.offsetP = 0;
            flir_updater.offsetH = 0;
        } else {
            interpolate("sim/current-view/pitch-offset-deg", -30, 2.5);
            interpolate("sim/current-view/heading-offset-deg", 0, 2.5);
        }
    } elsif (button == 10) {#MARK
        if (!lock_tgp or armament.contactPoint == nil) return;
        line10.setText("#"~steerpoints.markTGP(armament.contactPoint.get_Coord()));
        settimer(func {line10.setText("MARK");}, 2.5);
    } elsif (button == 11) {#UP
        if (lock_tgp) return;
        gps = 0;
        var fov = getprop("sim/current-view/field-of-view");
        if (getprop("/aircraft/flir/target/auto-track")) {
            flir_updater.offsetP += fov/camera_movement_speed_lock;
        } else {
            setprop("sim/current-view/pitch-offset-deg",getprop("sim/current-view/pitch-offset-deg")+fov/camera_movement_speed_free);
        }
    } elsif (button == 12) {#DOWN
        if (lock_tgp) return;
        gps = 0;
        var fov = getprop("sim/current-view/field-of-view");
        if (getprop("/aircraft/flir/target/auto-track")) {
            flir_updater.offsetP -= fov/camera_movement_speed_lock;
        } else {
            setprop("sim/current-view/pitch-offset-deg",getprop("sim/current-view/pitch-offset-deg")-fov/camera_movement_speed_free);
        }
    } elsif (button == 14) {#LEFT
        if (lock_tgp) return;
        gps = 0;
        var fov = getprop("sim/current-view/field-of-view");
        if (getprop("/aircraft/flir/target/auto-track")) {
            flir_updater.offsetH -= fov/camera_movement_speed_lock;
        } else {
            setprop("sim/current-view/heading-offset-deg",getprop("sim/current-view/heading-offset-deg")+fov/camera_movement_speed_free);
        }
    } elsif (button == 15) {#RGHT
        if (lock_tgp) return;
        gps = 0;
        var fov = getprop("sim/current-view/field-of-view");
        if (getprop("/aircraft/flir/target/auto-track")) {
            flir_updater.offsetH += fov/camera_movement_speed_lock;
        } else {
            setprop("sim/current-view/heading-offset-deg",getprop("sim/current-view/heading-offset-deg")-fov/camera_movement_speed_free);
        }
    } elsif (button == 13) {#WIDE/NARO
        wide = !wide;        
    } elsif (button == 2) {#ZOOM
        zoomlvl += 1;
        if (zoomlvl > 4) {
            zoomlvl = 1;
        }
    }
};
setlistener("controls/MFD[2]/button-pressed", list);
setlistener("controls/displays/cursor-click", list);



var fast_loop = func {
  var viewName = getprop("/sim/current-view/name"); 

    if (viewName == "TGP" and (getprop("gear/gear/wow") or !getprop("f16/stores/tgp-mounted"))) {
        # deselect view back to pilot default
        masterMode = STBY;
        setprop("sim/current-view/view-number",0);
        setprop("sim/rendering/als-filters/use-IR-vision", 0);
        setprop("sim/view[105]/enabled", 0);

    } elsif (viewName == "TGP") {
        if (!getprop("f16/avionics/power-mfd") or getprop("f16/avionics/power-ufc-warm")!=1) {
            canvasMFDext.setColorBackground(0.00, 0.00, 0.00, 1.00);
            midl.setText("    MFD OFF   ");
            bott.setText("");
            ralt.setText("");
            line9.hide();
            line10.hide();
            line3.setText("");
            cross.hide();
            enable = 0;
            masterMode = STBY;
        } elsif (getprop("f16/avionics/power-right-hdpt") == 0 or getprop("fdm/jsbsim/elec/bus/ess-dc") <=20) {
            canvasMFDext.setColorBackground(0.00, 0.00, 0.00, 1.00);
            midl.setText("      OFF     ");
            bott.setText("");
            ralt.setText("");
            line9.hide();
            line10.hide();
            line3.setText("");
            cross.hide();
            enable = 0;
            masterMode = STBY;
        } elsif (getprop("f16/avionics/power-right-hdpt-warm") < 1) {
            canvasMFDext.setColorBackground(0.00, 0.00, 0.00, 1.00);
            
            var to_secs = (1.0-getprop("/f16/avionics/power-right-hdpt-warm"))*180;
            var mins = int(to_secs/60);
            var secs = to_secs-mins*60;
            var ttxt = sprintf(" %1d:%02d ", mins, secs);
            midl.setText("NOT TIMED OUT");
            bott.setText(ttxt);
            ralt.setText("");
            line9.hide();
            line10.hide();
            line3.setText(masterMode==0?"STBY":(hiddenMode==AG?"A-G":"A-A"));
            cross.hide();
            enable = 0;
        } elsif (masterMode == STBY) {
            canvasMFDext.setColorBackground(0.00, 0.00, 0.00, 1.00);
            midl.setText("   STANDBY   ");
            bott.setText("");
            ralt.setText("");
            line9.hide();
            line10.hide();
            line3.setText("STBY");
            cross.hide();
            enable = 0;
        } else {
            canvasMFDext.setColorBackground(1.00, 1.00, 1.00, 0.00);
            line3.setText(hiddenMode==AG?"A-G":"A-A");
            cross.show();
            enable = 1;
        }
        
        # FLIR TGP stuff:
        setprop("aircraft/flir/target/view-enabled", viewName == "TGP");
        setprop("sim/rendering/als-filters/use-filtering", viewName == "TGP");
        setprop("sim/rendering/als-filters/use-IR-vision", viewName == "TGP" and ir);
        setprop("sim/rendering/als-filters/use-night-vision", 0);
        
        var x = getprop("sim/gui/canvas/size[0]");
        var y = getprop("sim/gui/canvas/size[1]");
                
        var degs = 3.6/zoomlvl;
        if (wide) {            
            line13.setText("WIDE");
        } else {
            degs = 1.0/zoomlvl;
            line13.setText("NARO");
        }
        var fov = degs*(x/y);
        var format = (x/y)/2.25;#16/9 = 1.777
        var scale = format*20/fov;# we take into account that different pilots have different screen formats so the height of the MFD in screen stays same relative.
        setprop("sim/current-view/field-of-view-scale",scale);
        setprop("sim/current-view/field-of-view",fov);

        zoom.setText(sprintf("%.1fX",zoomlvl));
        
        line6.setText(ir==1?"WHOT":"TV");
        
        if (enable) {
            lasercode = getprop("f16/avionics/laser-code");
            if (getprop("/aircraft/flir/target/auto-track") and flir_updater.click_coord_cam != nil) {
                var dist = flir_updater.click_coord_cam.direct_distance_to(geo.aircraft_position())*M2NM;
                bott.setText(sprintf("%2.1f  CMBT  %04d",dist,lasercode));
                lat.setText(ded.convertDegreeToStringLat(flir_updater.click_coord_cam.lat()));
                lon.setText(ded.convertDegreeToStringLon(flir_updater.click_coord_cam.lon()));
            } else {
                bott.setText(sprintf("      CMBT  %04d",lasercode));
                lat.setText("");
                lon.setText("");
            }
            if (getprop("f16/avionics/cara-on")) {
                #1F-F16CJ-34-1 page 1-224
                ralt.setText(sprintf("%4d",getprop("position/altitude-agl-ft")));
            } else {
                ralt.setText("");
            }
        } else {
            lat.setText("");
            lon.setText("");
        }
        if (!getprop("/aircraft/flir/target/auto-track") or flir_updater.click_coord_cam == nil) {
            setprop("sim/view[105]/heading-offset-deg", -getprop("sim/current-view/heading-offset-deg"));
            setprop("sim/view[105]/pitch-offset-deg", getprop("sim/current-view/pitch-offset-deg"));
        }
        setprop("sim/current-view/x-offset-m",0.8536);
        setprop("sim/current-view/y-offset-m",-1.4121);
        setprop("sim/current-view/z-offset-m",-2.5856);
    } else {
        # remove FLIR effects and disable TGP view
        setprop("sim/rendering/als-filters/use-IR-vision", 0);
        setprop("sim/view[105]/enabled", 0);#!getprop("gear/gear/wow"));
        #lock.hide();
        #setprop("f16/avionics/lock-flir",0.05);
    }
    
    steerlock = 0;
    var follow = 0;
    if (armament.contactPoint !=nil and armament.contactPoint.get_range()>35 and armament.contactPoint.get_Callsign() != "GPS-Spot") {
        armament.contactPoint = nil;
    }
    var gpps = 0;
    if (armament.contactPoint == nil or !enable) {
        # no TGP lock
        if (armament.contact == nil and enable and masterMode) {# we do not check for get_display here since as long as something is selected we dont show steerpoint.
            if (steerpoints.getCurrentNumber() != 0) {
                # TGP follow steerpoint
                hiddenMode = AG;
                var stpt = steerpoints.getCurrent();
                var ele = stpt.alt;
                var lat = stpt.lat;
                var lon = stpt.lon;
                if (ele == nil) {
                    ele = 0;
                }
                ele *= FT2M;
                var ele2 = geo.elevation(lat,lon);
                if (ele2 != nil) {
                    ele = ele2;
                }                
                var sp = geo.Coord.new();
                sp.set_latlon(lat,lon,ele);
                flir_updater.click_coord_cam = sp;
                setprop("/aircraft/flir/target/auto-track", 1);
                if (callsign != "#"~steerpoints.getCurrentNumber()) {
                    # we switched steerpoint or from radar to steerpoint
                    flir_updater.offsetP = 0;
                    flir_updater.offsetH = 0;
                }
                callsign = "#"~steerpoints.getCurrentNumber();
                steerlock = 1;
                steer = 1;
            } else {
                # TGP not follow, locked from aircraft
                hiddenMode = AG;
                setprop("/aircraft/flir/target/auto-track", 0);
                flir_updater.click_coord_cam = nil;
                flir_updater.offsetP = 0;
                flir_updater.offsetH = 0;
                steer = 0;
                callsign = nil;
            }
        } elsif (armament.contact != nil and armament.contact.get_display() and enable and masterMode) {
            # TGP follow radar lock
            flir_updater.click_coord_cam = armament.contact.get_Coord();
            setprop("/aircraft/flir/target/auto-track", 1);
            if (callsign != armament.contact.getUnique()) {
                flir_updater.offsetP = 0;
                flir_updater.offsetH = 0;
            }
            callsign = armament.contact.getUnique();
            hiddenMode = armament.contact.get_type() == armament.AIR?AA:AG;
            steer = 0;
        } else {
            hiddenMode = AG;
            setprop("/aircraft/flir/target/auto-track", 0);
            flir_updater.click_coord_cam = nil;
            callsign = nil;
            flir_updater.offsetP = 0;
            flir_updater.offsetH = 0;
            steer = 0;
        }
        lock_tgp = 0;
        gps = 0;
    } else {
        # TGP lock
        var vis = 1;
        line10.show();
        gpss = armament.contactPoint.get_Callsign() == "GPS-Spot";# GPS-Spot only used by "program GPS dialog"
        if (armament.contactPoint.get_Callsign() != "TGP-Spot" and !gps and !gpss and !steer) {
            # we do not check for visibility if:
            # - following steerpoint
            # - a GPS coord has been entered manually by "program GPS dialog"
            follow = 1;
            vis = radar_system.terrain.fastTerrainCheck(armament.contactPoint);
            if (vis > 0) vis = 1;
        }
        if (!vis or !masterMode) {
            setprop("/aircraft/flir/target/auto-track", 0);
            flir_updater.click_coord_cam = nil;
            callsign = nil;
            flir_updater.offsetP = 0;
            flir_updater.offsetH = 0;
            lock_tgp = 0;
            armament.contactPoint = nil;
            hiddenMode = AG;
        } else {
            lock_tgp = 1;
            flir_updater.click_coord_cam = armament.contactPoint.get_Coord();
            #callsign = armament.contactPoint.getUnique();
            setprop("/aircraft/flir/target/auto-track", 1);
            #flir_updater.offsetP = 0;
            #flir_updater.offsetH = 0;# commented so we get back to where we were when unlocking
        }
    }
    setprop("f16/avionics/tgp-lock", lock_tgp);#used in HUD
        
    if (getprop("f16/stores/tgp-mounted") and enable) {
        if (lock_tgp and !lock_tgp_last) {
            interpolate("f16/avionics/lock-flir",1,1.5);
        } elsif (!lock_tgp) {
            setprop("f16/avionics/lock-flir",0.05);
        }
        lock_tgp_last = lock_tgp;
        if (lock_tgp) {
            line1box.show();
            line9.hide();
            line11.hide();
            line12.hide();
            line14.hide();
            line15.hide();            
        } else {
            line1box.hide();
            line9.show();
            line11.show();
            line12.show();
            line14.show();
            line15.show();
        }
        if (lock_tgp and gps) {
            midl.setText(sprintf("%s      %s", "GPS", getprop("controls/armament/laser-arm-dmd")?"L":""));
        } elsif (lock_tgp and follow) {
            midl.setText(sprintf("%s POINT %s", gps?"GPS":(ir==1?"IR":"TV"), getprop("controls/armament/laser-arm-dmd")?"L":""));
        } elsif (lock_tgp) {
            midl.setText(sprintf("%s AREA  %s", gps?"GPS":(ir==1?"IR":"TV"), getprop("controls/armament/laser-arm-dmd")?"L":""));
        } elsif (getprop("/aircraft/flir/target/auto-track") and flir_updater.click_coord_cam != nil and steerlock) {
            midl.setText(sprintf("STPT %s  %s", "#"~steerpoints.getCurrentNumber(), getprop("controls/armament/laser-arm-dmd")?"L":""));
        } elsif (getprop("/aircraft/flir/target/auto-track") and flir_updater.click_coord_cam != nil) {
            midl.setText(sprintf("  RADAR  %s", getprop("controls/armament/laser-arm-dmd")?"L":""));
        } else {
            midl.setText(sprintf("         %s", getprop("controls/armament/laser-arm-dmd")?"L":""));
        }
        
        var scaleLock = getprop("f16/avionics/lock-flir");
        lock.setScale(scaleLock,scaleLock);
        lock.setStrokeLineWidth(1/scaleLock);
        if (scaleLock != 0.05) {
            lock.show();
        } else {
            lock.hide();
        }
        lock.update();
    
        # animate the LANTIRN camera:
        var b = geo.normdeg180(getprop("sim/view[105]/heading-offset-deg"));
        var p = getprop("sim/view[105]/pitch-offset-deg");
        var polarL = math.sqrt(p*p+b*b);
        var polarD = polarL!=0 and b!=0?math.atan2(p,b)*R2D:-90;
        setprop("aircraft/flir/swivel/pitch-deg",polarL);
        setprop("aircraft/flir/swivel/roll-deg",polarD);
    } elsif (!masterMode) {
        lock.hide();
    }
    var dt = systime();
    if (viewName == "TGP" and getprop("f16/stores/tgp-mounted") and enable) {
        var cx = -getprop("/controls/displays/cursor-slew-x-delta");
        var cy = -getprop("/controls/displays/cursor-slew-y-delta");
        setprop("/controls/displays/cursor-slew-x-delta",0);
        setprop("/controls/displays/cursor-slew-y-delta",0);

        if (!lock_tgp and (cy != 0 or cx != 0)) {
            gps = 0;
            var fov = getprop("sim/current-view/field-of-view");
            #var tme = dt - dt_old;
            if (getprop("/aircraft/flir/target/auto-track")) {
                flir_updater.offsetP += cy*fov/camera_movement_speed_lock;
                flir_updater.offsetH -= cx*fov/camera_movement_speed_lock;
            } else {
                setprop("sim/current-view/pitch-offset-deg",getprop("sim/current-view/pitch-offset-deg")+cy*fov/camera_movement_speed_free);
                setprop("sim/current-view/heading-offset-deg",getprop("sim/current-view/heading-offset-deg")+cx*fov/camera_movement_speed_free);
            }
        }
    }
    dt_old = dt;
}

var flooptimer = nil;# started from f16.nas

var dt_old = 0;

var line1 = nil;
var line1box = nil;
var line2 = nil;
var line3 = nil;
var line4 = nil;
var line6 = nil;
var line7 = nil;
var line10 = nil;
var line11 = nil;
var line12 = nil;
var line13 = nil;
var line14 = nil;
var line15 = nil;
var line20 = nil;
var cross = nil;
var lock = nil;
var zoom = nil;
var bott = nil;
var ralt = nil;
var lat = nil;
var lon = nil;
var line9 = nil;
var midl = nil;
var ir = 1;
var lasercode = int(rand()*1778+1111);setprop("f16/avionics/laser-code",lasercode);
var callsign = nil;
var lock_tgp = 0;
var lock_tgp_last = 0;
var wide = 1;
var zoomlvl = 1.0;
var gps = 0;# set from Program GPS dialog
var steer = 0;
var STBY = 0;
var AG = 1;
var AA = 2;
var masterMode = STBY;
var hiddenMode = AG;

var canvasMFDext = nil;
var callInit = func {
  canvasMFDext = canvas.new({
        "name": "MFD-EXT",
        "size": [256, 256],
        "view": [256, 256],
        "mipmapping": 1
  });
      
  canvasMFDext.addPlacement({"node": "MFDimage3", "texture": "tranbg.png"});
  canvasMFDext.setColorBackground(1.00, 1.00, 1.00, 0.00);

  dedGroup = canvasMFDext.createGroup();
  dedGroup.show();
  var color = [getprop("/sim/model/MFD-color/text1/red"),getprop("/sim/model/MFD-color/text1/green"),getprop("/sim/model/MFD-color/text1/blue"),1];
  line1 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("left-center")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("LOCK")
        .setTranslation(5, 256*0.20);# 1
  line1box = dedGroup.createChild("path")
        .moveTo(0,-7)
        .vert(14)
        .horiz(35)
        .vert(-14)
        .horiz(-35)
        .setStrokeLineWidth(1)
        .setColor(getprop("/sim/model/MFD-color/text1/red"),getprop("/sim/model/MFD-color/text1/green"),getprop("/sim/model/MFD-color/text1/blue"))
        .hide()
        .setTranslation(5, 256*0.20);
  line2 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("left-center")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("ZOOM")
        .setTranslation(5, 256*0.35);# 2
  line3 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("left-center")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("STBY")
        .setTranslation(5, 256*0.50);# 3
  line4 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("left-center")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("")
        .setTranslation(5, 256*0.65);# 4
  line6 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("right-center")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("WHOT")
        .setTranslation(256-5, 256*0.2);# 6
  line7 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("right-center")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("XFER")
        .hide()
        .setTranslation(256-5, 256*0.35);# 7
  line9 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("right-center")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("CZ")
        .hide()
        .setTranslation(256-5, 256*0.65);# 9
  line10 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("right-center")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("MARK")
        .hide()
        .setTranslation(256-5, 256*0.8);# 10
  line11 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("center-top")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("UP")
        .setTranslation(256*0.2, 5);# 11
  line12 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("center-top")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("DOWN")
        .setTranslation(256*0.35, 5);# 12
  line13 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("center-top")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("WIDE")
        .setTranslation(256*0.50, 5);# 13
  line14 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("center-top")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("LEFT")
        .setTranslation(256*0.65, 5);# 14
  line15 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("center-top")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("RGHT")
        .setTranslation(256*0.8, 5);# 15
  line20 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("center-bottom")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("BACK")
        .setTranslation(256*0.8, 256-5);# 20

    zoom = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(getprop("/sim/model/MFD-color/text1/red"),getprop("/sim/model/MFD-color/text1/green"),getprop("/sim/model/MFD-color/text1/blue"))
        .setAlignment("center-top")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("1.0X")
        .setTranslation(256*0.5, 20);
    midl = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(getprop("/sim/model/MFD-color/text1/red"),getprop("/sim/model/MFD-color/text1/green"),getprop("/sim/model/MFD-color/text1/blue"))
        .setAlignment("center-bottom")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("IR POINT    L")
        .setTranslation(256*0.5, 256*0.8);
    bott = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(getprop("/sim/model/MFD-color/text1/red"),getprop("/sim/model/MFD-color/text1/green"),getprop("/sim/model/MFD-color/text1/blue"))
        .setAlignment("center-bottom")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("13.0  CMBT  1538")
        .setTranslation(256*0.5, 256*0.9);
    ralt = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("right-center")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("RALT")
        .setTranslation(256-25, 256*0.1);
    lat = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("left-center")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("LAT")
        .setTranslation(50, 256*0.2);
    lon = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("left-center")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("LON")
        .setTranslation(50, 256*0.25);

  cross = dedGroup.createChild("path")
            .moveTo(128,0)
            .vert(120)
            .moveTo(128,256)
            .vert(-120)
            .moveTo(0,128)
            .horiz(120)
            .moveTo(256,128)
            .horiz(-120)
            .setStrokeLineWidth(1)
            .setColor(getprop("/sim/model/MFD-color/text1/red"),getprop("/sim/model/MFD-color/text1/green"),getprop("/sim/model/MFD-color/text1/blue"));
    lock = dedGroup.createChild("path")
            #.setCenter(128,128)
            .moveTo(48,48)
            .vert(-96)
            .horiz(-96)
            .vert(96)
            .horiz(96)
            .hide()
            .setTranslation(128,128)
            .setStrokeLineWidth(1)
            .setColor(getprop("/sim/model/MFD-color/text1/red"),getprop("/sim/model/MFD-color/text1/green"),getprop("/sim/model/MFD-color/text1/blue"));
};

#callInit();
#fast_loop();