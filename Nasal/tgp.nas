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

# Position of the FLIR camera ([z (back), x (right), y (up)])
var coords_cam = [
    getprop("/sim/view[102]/config/z-offset-m"),
    getprop("/sim/view[102]/config/x-offset-m"),
    getprop("/sim/view[102]/config/y-offset-m")
];
io.include("Aircraft/Generic/updateloop.nas");
io.load_nasal(getprop("/sim/fg-root") ~ "/Aircraft/c172p/Nasal/generic/math_ext.nas","math_ext");
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

        return m;
    },

    enable: func {
        #me.loop.reset();
        me.loop.enable();
    },

    disable: func {
        me.remove_listeners();
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

        if (getprop("sim/current-view/view-number") ==9 and getprop("/aircraft/flir/target/auto-track") and me.click_coord_cam != nil) {
            var (yaw, pitch, distance) = computer(coords_cam, me.click_coord_cam);
            me.update_cam(roll_deg, pitch_deg, yaw, pitch);
        }
#        else {
#            me.manual_update_cam(roll_deg, pitch_deg);
#        }
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

            setprop("/sim/current-view/goal-heading-offset-deg", -yaw);
            setprop("/sim/current-view/goal-pitch-offset-deg", pitch);
        };
    },

    _get_flir_computer: func (roll_deg, pitch_deg, heading) {
        return func (coords, target) {
            var (position_2d, position) = math_ext.get_point(coords[0], coords[1], coords[2], roll_deg, pitch_deg, heading);
            return math_ext.get_yaw_pitch_distance_inert(position_2d, position, target, heading);
        }
    }

};

var flir_updater = FLIRCameraUpdater.new();

setlistener("/sim/signals/fdm-initialized", func {
    setlistener("/aircraft/flir/target/view-enabled", func (node) {
        flir_updater.enable_or_disable(node.getBoolValue());
    }, 1, 0);
});

setlistener("controls/MFD[2]/button-pressed", func (node) {
    if (getprop("controls/MFD[2]/button-pressed") == 1) {
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

            #(yaw, pitch) = math_ext.get_yaw_pitch_body(getprop("orientation/roll-deg"), getprop("orientation/pitch-deg"), vHead, vPitch, getprop("orientation/heading-deg"));
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
            flir_updater.click_coord_cam = terrain;
            setprop("/aircraft/flir/target/auto-track", 1);
            interpolate("f16/avionics/lock-flir",1,1.5);
        }
    } elsif (getprop("controls/MFD[2]/button-pressed") == 2) {
        flir_updater.click_coord_cam = nil;
        setprop("/aircraft/flir/target/auto-track", 0);
        lock.hide();
        setprop("f16/avionics/lock-flir",0.05);
    } elsif (getprop("controls/MFD[2]/button-pressed") == 20) {
        setprop("sim/current-view/view-number",0);
        setprop("/aircraft/flir/target/auto-track", 0);
        lock.hide();
        setprop("f16/avionics/lock-flir",0.05);
    } elsif (getprop("controls/MFD[2]/button-pressed") == 6) {
        ir = !ir;
    }
});

var fast_loop = func {
  var viewName = getprop("/sim/current-view/name"); 
  if (viewName == "TGP" and (getprop("gear/gear/wow") or !getprop("f16/stores/tgp-mounted"))) {
    setprop("sim/current-view/view-number",0);
    setprop("sim/rendering/als-filters/use-IR-vision", 0);
    setprop("sim/view[102]/enabled", 0);
    setprop("f16/avionics/lock-flir",0.05);
    lock.hide();
  } elsif (viewName == "TGP") {
    # FLIR TGP stuff:
    setprop("aircraft/flir/target/view-enabled", viewName == "TGP");
    setprop("sim/rendering/als-filters/use-filtering", viewName == "TGP");
    setprop("sim/rendering/als-filters/use-IR-vision", viewName == "TGP" and ir);
    setprop("sim/rendering/als-filters/use-night-vision", 0);
    var fov = getprop("sim/current-view/field-of-view");
    if (fov > 50) {
      fov = 50;
      setprop("sim/current-view/field-of-view",fov);
    }
    var scale = 20/fov;
    setprop("sim/current-view/field-of-view-scale",scale);
    var scaleLock = getprop("f16/avionics/lock-flir");
    lock.setScale(scaleLock,scaleLock);
    lock.setStrokeLineWidth(1/scaleLock);
    if (scaleLock != 0.05) {
        lock.show();
    }
    lock.update();
    zoom.setText(sprintf("%.1fX",getprop("sim/current-view/field-of-view-scale")));
    line6.setText(ir==1?"WHOT":"TV");
    midl.setText(sprintf("%s POINT %s", ir==1?"IR":"TV", getprop("controls/armament/laser-arm-dmd")?"L":""));
    if (getprop("/aircraft/flir/target/auto-track") and flir_updater.click_coord_cam != nil) {
        var dist = flir_updater.click_coord_cam.direct_distance_to(geo.aircraft_position())*M2NM;
        bott.setText(sprintf("%2.1f  CMBT  %d",dist,lasercode));
    } else {
        bott.setText(sprintf("      CMBT  %d",lasercode));
    }
  } else {
    setprop("sim/rendering/als-filters/use-IR-vision", 0);
    setprop("sim/view[102]/enabled", 0);#!getprop("gear/gear/wow"));
    lock.hide();
    setprop("f16/avionics/lock-flir",0.05);
  }
  settimer(fast_loop,0);
}


var line1 = nil;
var line2 = nil;
var line3 = nil;
var line4 = nil;
var line6 = nil;
var line20 = nil;
var cross = nil;
var lock = nil;
var zoom = nil;
var bott = nil;
var midl = nil;
var ir = 1;
var lasercode = int(rand()*10000);

var callInit = func {
  var canvasMFDext = canvas.new({
        "name": "MFD-EXT",
        "size": [256, 256],
        "view": [256, 256],
        "mipmapping": 1
  });
      
  canvasMFDext.addPlacement({"node": "MFDimage3", "texture": "tranbg.png"});
  canvasMFDext.setColorBackground(1.00, 1.00, 1.00, 0.00);

  dedGroup = canvasMFDext.createGroup();
  dedGroup.show();
  var color = [0,1,0,1];
  line1 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("left-center")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("LOCK")
        .setTranslation(5, 256*0.20);
  line2 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("left-center")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("UNLOCK")
        .setTranslation(5, 256*0.35);
  line3 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("left-center")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("")
        .setTranslation(5, 256*0.50);
  line4 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("left-center")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("")
        .setTranslation(5, 256*0.65);
  line6 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("right-center")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("WHOT")
        .setTranslation(256-5, 256*0.2);
  line20 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("center-bottom")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("BACK")
        .setTranslation(256*0.8, 256-5);

    zoom = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(1,1,1)
        .setAlignment("center-top")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("1.0X")
        .setTranslation(256*0.5, 15);
    midl = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(1,1,1)
        .setAlignment("center-bottom")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("IR POINT    L")
        .setTranslation(256*0.5, 256*0.8);
    bott = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(1,1,1)
        .setAlignment("center-bottom")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("13.0  CMBT  1538")
        .setTranslation(256*0.5, 256*0.9);

  cross = dedGroup.createChild("path")
            .moveTo(128,0)
            .vert(256)
            .moveTo(0,128)
            .horiz(256)
            .setStrokeLineWidth(1)
            .setColor(1,1,1);
    lock = dedGroup.createChild("path")
            #.setCenter(128,128)
            .moveTo(48,48)
            .vert(-96)
            .horiz(-96)
            .vert(96)
            .horiz(96)
            .setTranslation(128,128)
            .setStrokeLineWidth(1)
            .setColor(1,1,1);
};

callInit();
fast_loop();