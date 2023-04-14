# provides relative vectors from eye-point to aircraft lights
# in east/north/up coordinates the renderer uses
# Thanks to BAWV12 / Thorsten

# 5H1N0B1 201911 :
# Put light stuff in a different object inorder to manage different kind of light
# This need to have work in order to initialize the differents lights with the new object
# Then we need to put a foreach loop in the update loop

# NikolaiVChr:
# made landing spot be placed correct from light beam
# Adapted for F-16 2020-03


var als_on = props.globals.getNode("/sim/rendering/shaders/skydome");
var alt_agl = props.globals.getNode("/position/altitude-agl-ft");
var cur_alt = 0;

var taxiLight    = props.globals.getNode("sim/multiplay/generic/bool[46]", 1);
var landingLight = props.globals.getNode("sim/multiplay/generic/bool[47]", 1);
var navLight     = props.globals.getNode("sim/multiplay/generic/bool[40]", 1);
var formLight    = props.globals.getNode("sim/multiplay/generic/bool[41]", 1);

var navLightBrt  = props.globals.getNode("controls/lighting/ext-lighting-panel/wing-tail",1);
var formLightBrt = props.globals.getNode("controls/lighting/ext-lighting-panel/form-knob",1);

var gearPos = props.globals.getNode("gear/gear[0]/position-norm", 1);
var sceneLight = props.globals.getNode("rendering/scene/diffuse/red", 1);

var light_manager = {

    lat_to_m: 110952.0,
    lon_to_m: 0.0,

    init: func {
        # Define your lights here
        me.data_light = [
            # light_xpos, light_ypos, light_zpos, light_dir, light_size, light_stretch, light_r, light_g, light_b, light_is_on, number
            ALS_light_spot.new(10, 0, -1, 0, 1.5, -2.7, 0.7, 0.7, 0.7, 0, 0),   #landing
            ALS_light_spot.new(70, 0, -1, 0, 12, -7.0, 0.7, 0.7, 0.7, 0, 1),    #taxi
            ALS_light_spot.new(1.60236, -4.55165, 0.012629, 0, 2, 0, 0.5, 0, 0, 0, 2),  #left
            ALS_light_spot.new(1.60236,  4.55165, 0.012629, 0, 2, 0, 0, 0.5, 0, 0, 3),  #right
            ALS_light_spot.new(-1.23466, 0 , -0.862066, 0, 2, 0, 0.5, 0.5, 0.5, 0, 4),  #belly
        ];

        me.timer = maketimer(0, me, me.update);
        me.start();
    },

    start: func {
        setprop("/sim/rendering/als-secondary-lights/num-lightspots", size(me.data_light));

        me.timer.start();
    },

    stop: func {
        setprop("/sim/rendering/als-secondary-lights/num-lightspots", 0);

        me.timer.stop();
    },

    update: func {
        cur_alt = alt_agl.getValue();
        if (cur_alt != nil) {
            if (als_on.getValue() == 1) {
                # Condition for lights
                if (gearPos.getValue() > 0.3 and landingLight.getValue() and alt_agl.getValue() < 1000.0) {
                    me.data_light[0].light_on();
                } else {
                    me.data_light[0].light_off();
                }

                if (gearPos.getValue() > 0.3 and taxiLight.getValue() and alt_agl.getValue() < 50.0) {
                    me.data_light[1].light_on();
                } else {
                    me.data_light[1].light_off();
                }

                if (alt_agl.getValue() < 20.0) {
                    if (navLight.getValue()) {
                        me.data_light[2].light_on();
                        me.data_light[3].light_on();
                        me.data_light[2].light_r = (navLightBrt.getValue() == -1 ? 0.3 : 0.7);
                        me.data_light[3].light_g = (navLightBrt.getValue() == -1 ? 0.3 : 0.7);
                    } elsif (formLight.getValue()) {
                        me.data_light[2].light_on();
                        me.data_light[3].light_on();
                        me.data_light[2].light_r = formLightBrt.getValue() * 0.7;
                        me.data_light[3].light_g = formLightBrt.getValue() * 0.7;
                    } else {
                        me.data_light[2].light_off();
                        me.data_light[3].light_off();
                    }
                    if (formLight.getValue()) {
                        me.data_light[4].light_on();
                        me.data_light[4].light_r = formLightBrt.getValue() / 3;
                        me.data_light[4].light_g = me.data_light[4].light_r;
                        me.data_light[4].light_b = me.data_light[4].light_r;
                    } else {
                        me.data_light[4].light_off();
                    }
                }
        
                # Updating each light position
                for (var i = 0; i < size(me.data_light); i += 1)
                {
                    me.data_light[i].position();
                }
            } else {
                me.data_light[0].light_off();
                me.data_light[1].light_off();
                me.data_light[2].light_off();
                me.data_light[3].light_off();
                me.data_light[4].light_off();
            }
        } else {
            me.data_light[0].light_off();
            me.data_light[1].light_off();
            me.data_light[2].light_off();
            me.data_light[3].light_off();
            me.data_light[4].light_off();
        }

    },
};


var ALS_light_spot = {
    new: func (light_xpos, light_ypos, light_zpos, light_dir, light_size, light_stretch, light_r, light_g, light_b, light_is_on, number) {
        var me = { parents : [ALS_light_spot] };

        if (number == 0) {
            me.nd_ref_light_x = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-x-m", 1);
            me.nd_ref_light_y = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-y-m", 1);
            me.nd_ref_light_z = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-z-m", 1);
            me.nd_ref_light_dir = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/dir", 1);
            me.nd_ref_light_size = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/size", 1);
            me.nd_ref_light_stretch = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/stretch", 1);
            me.nd_ref_light_r = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/lightspot-r", 1);
            me.nd_ref_light_g = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/lightspot-g", 1);
            me.nd_ref_light_b = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/lightspot-b", 1);
        } else {
            me.nd_ref_light_x = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-x-m["~number~"]", 1);
            me.nd_ref_light_y = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-y-m["~number~"]", 1);
            me.nd_ref_light_z = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-z-m["~number~"]", 1);
            me.nd_ref_light_dir = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/dir["~number~"]", 1);
            me.nd_ref_light_size = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/size["~number~"]", 1);
            me.nd_ref_light_stretch = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/stretch["~number~"]", 1);
            me.nd_ref_light_r = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/lightspot-r["~number~"]", 1);
            me.nd_ref_light_g = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/lightspot-g["~number~"]", 1);
            me.nd_ref_light_b = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/lightspot-b["~number~"]", 1);
        }
            
        me.light_xpos = light_xpos;
        me.light_ypos = light_ypos;
        me.light_zpos = light_zpos;
        me.light_dir = light_dir;
        me.light_size = light_size;
        me.light_stretch = light_stretch;
        me.light_r = light_r;
        me.light_g = light_g;
        me.light_b = light_b;
        me.light_is_on = light_is_on;
        me.number = number;
            
        me.lon_to_m  = 0;

        me.nd_ref_light_x.setValue(me.light_xpos);
        me.nd_ref_light_y.setValue(me.light_ypos);
        me.nd_ref_light_z.setValue(me.light_zpos);
        me.nd_ref_light_r.setValue(me.light_r);
        me.nd_ref_light_g.setValue(me.light_g);
        me.nd_ref_light_b.setValue(me.light_b);
        me.nd_ref_light_dir.setValue(me.light_dir);
        me.nd_ref_light_size.setValue(me.light_size);
        me.nd_ref_light_stretch.setValue(me.light_stretch);

        return me;
    },
    
    lat2m: func(lat) {
        # Nikolai V Chr
        me.lat_to_nm = [59.7052, 59.7453, 59.8554, 60.0062, 60.1577, 60.2690, 60.3098]; # 15 deg intervals
        me.indexLat = math.abs(lat)/15;

        if (me.indexLat == 0) {
            me.lat2nm = me.lat_to_nm[0];
        } elsif (me.indexLat == 6) {
            me.lat2nm = me.lat_to_nm[6];
        } else {
            me.lat2nm = me.extrapolate(me.indexLat-int(me.indexLat), 0, 1, me.lat_to_nm[int(me.indexLat)], me.lat_to_nm[int(me.indexLat)+1]);
        }
        return me.lat2nm * NM2M;
    },
    
    extrapolate: func(x, x1, x2, y1, y2) {
        return y1 + ((x - x1) / (x2 - x1)) * (y2 - y1);
    },
    
    position: func() {
        cur_alt = alt_agl.getValue();
        var apos = geo.aircraft_position();
        var vpos = geo.viewer_position();

        me.lon_to_m = math.cos(vpos.lat()*D2R) * me.lat2m(0);
        var heading = self.getHeading()*D2R;

        var lat = apos.lat();
        var lon = apos.lon();
        var alt = apos.alt();

        var sh = math.sin(heading);
        var ch = math.cos(heading);
        if (me.number == 0) {
            # Landing light

            # calculate where beam hits ground
            var test = fix.testForDistance();
        
            if (test != nil) {
                # grab spot position
                apos = test[1];

                # light intensity. fade fully out at 750m dist:
                me.light_r = 0.8 - 0.8 * math.clamp(test[0], 0, 750) / 750;
                me.light_g = me.light_r;
                me.light_b = me.light_r;

                # calculate spot position in relation to view position:
                var delta_x = (apos.lat() - vpos.lat()) * me.lat2m(vpos.lat());
                var delta_y = -(apos.lon() - vpos.lon()) * me.lon_to_m;
                var delta_z = apos.alt() - vpos.alt();

                me.nd_ref_light_x.setValue(delta_x);
                me.nd_ref_light_y.setValue(delta_y);
                me.nd_ref_light_z.setValue(delta_z);

                me.nd_ref_light_dir.setValue(heading);  # used to determine spot stretch direction
                me.nd_ref_light_size.setValue(me.light_size*(((test[0] - 3) / 2) + 3)); # spot radius grows linear with distance
            } else {
                me.nd_ref_light_r.setValue(0);
                me.nd_ref_light_g.setValue(0);
                me.nd_ref_light_b.setValue(0);
                me.light_is_on = 0;
            }
        } elsif (me.number == 2 or me.number == 3 or me.number == 4) {
            # red/green nav light and belly light
            me.lightGPS = aircraftToCart({x:-me.light_xpos, y:me.light_ypos, z:-me.light_zpos});
            apos = geo.Coord.new().set_xyz(me.lightGPS.x, me.lightGPS.y, me.lightGPS.z);
        
            var delta_x = (apos.lat() - vpos.lat()) * me.lat2m(vpos.lat());
            var delta_y = -(apos.lon() - vpos.lon()) * me.lon_to_m;
            var delta_z = apos.alt() - vpos.alt();

            me.nd_ref_light_x.setValue(delta_x);
            me.nd_ref_light_y.setValue(delta_y);
            me.nd_ref_light_z.setValue(delta_z);
        
            me.nd_ref_light_size.setValue(me.light_size);
        } else {
            # Taxi light
            var proj_x = cur_alt*FT2M * 10;
            var proj_z = cur_alt*FT2M;
        
            apos.set_lat(lat + ((me.light_xpos + proj_x) * ch + me.light_ypos * sh) / me.lat2m(vpos.lat()));
            apos.set_lon(lon + ((me.light_xpos + proj_x) * sh - me.light_ypos * ch) / me.lon_to_m);
        
            var delta_x = (apos.lat() - vpos.lat()) * me.lat2m(vpos.lat());
            var delta_y = -(apos.lon() - vpos.lon()) * me.lon_to_m;
            var delta_z = apos.alt() - proj_z - vpos.alt();
        
            me.nd_ref_light_x.setValue(delta_x);
            me.nd_ref_light_y.setValue(delta_y);
            me.nd_ref_light_z.setValue(delta_z);
            me.nd_ref_light_dir.setValue(heading);
            me.nd_ref_light_size.setValue(me.light_size + me.light_size * cur_alt * 0.05);
        }
    },

    light_on : func {
        # scene red inverted will dim the light so it dont compete with sun
        var red = 1 - sceneLight.getValue();
        me.nd_ref_light_r.setValue(me.light_r * red);
        me.nd_ref_light_g.setValue(me.light_g * red);
        me.nd_ref_light_b.setValue(me.light_b * red);
        me.light_is_on = 1;
    },

    light_off : func {
        me.nd_ref_light_r.setValue(0);
        me.nd_ref_light_g.setValue(0);
        me.nd_ref_light_b.setValue(0);
        me.light_is_on = 0;
        },
    
    light_setSize : func(size) {
        me.nd_ref_light_size.setValue(size);
    },

};


SelfContact = {
# Ownship info
# 
    new: func {
        var c = {parents: [SelfContact]};

        c.init();

        return c;
    },

    init: func {
        # read all properties and store them for fast lookup.
        me.acHeading  = props.globals.getNode("orientation/heading-deg");
        me.acPitch    = props.globals.getNode("orientation/pitch-deg");
        me.acRoll     = props.globals.getNode("orientation/roll-deg");
        me.acalt      = props.globals.getNode("position/altitude-ft");
        me.aclat      = props.globals.getNode("position/latitude-deg");
        me.aclon      = props.globals.getNode("position/longitude-deg");
        me.acgns      = props.globals.getNode("velocities/groundspeed-kt");
        me.acdns      = props.globals.getNode("velocities/speed-down-fps");
        me.aceas      = props.globals.getNode("velocities/speed-east-fps");
        me.acnos      = props.globals.getNode("velocities/speed-north-fps");
    },

    getCoord: func {
        # this is much faster than calling geo.aircraft_position().
        me.accoord = geo.Coord.new().set_latlon(me.aclat.getValue(), me.aclon.getValue(), me.acalt.getValue()*FT2M);

        return me.accoord;
    },

    getLightCoord: func {
        # this is much faster than calling geo.aircraft_position().
        me.light = aircraftToCart({x:3.13064, y:0.307693, z:1.15951});
        me.accoord = geo.Coord.new().set_xyz(me.light.x, me.light.y, me.light.z);
        me.accoord.alt(); # TODO: once fixed in FG this line is no longer needed.

        return me.accoord;
    },

    getAttitude: func {
        return [me.acHeading.getValue(), me.acPitch.getValue(), me.acRoll.getValue()];
    },

    getSpeedVector: func {
        me.speed_down_mps  = me.acdns.getValue() * FT2M;
        me.speed_east_mps  = me.aceas.getValue() * FT2M;
        me.speed_north_mps = me.acnos.getValue() * FT2M;

        return [me.speed_north_mps, -me.speed_east_mps, -me.speed_down_mps];
    },

    getHeading: func {
        return me.acHeading.getValue();
    },

    getPitch: func {
        return me.acPitch.getValue();
    },

    getRoll: func {
        return me.acRoll.getValue();
    },

    getSpeed: func {
        return me.acgns.getValue();
    },
};

var self = SelfContact.new();


Radar = {
# master radar class
#
# Attributes:
#   on/off
#   limitedContactVector of RadarContacts
enabled: 1,
};


var FixedBeamRadar = {
    # inherits from Radar
    new: func() {
        var fb = {parents: [FixedBeamRadar, Radar]};
    
        fb.beam_pitch_deg = 0;
    
        return fb;
    },

    setBeamPitch: func(pitch_deg) {
        me.beam_pitch_deg = pitch_deg;
    },

    computeBeamVector: func {
        me.beamVector = [math.cos(me.beam_pitch_deg * D2R), 0, math.sin(me.beam_pitch_deg * D2R)];
        me.beamVectorFix = vector.Math.rollPitchYawVector(self.getRoll(), self.getPitch(), -self.getHeading(), me.beamVector);
        me.geoVector = vector.Math.vectorToGeoVector(vector.Math.normalize(me.beamVectorFix), self.getLightCoord());

        return me.geoVector;
    },

    testForDistance: func {
        if (me.enabled) {
            me.selfPos = self.getLightCoord();
            me.pick = get_cart_ground_intersection({"x":me.selfPos.x(), "y":me.selfPos.y(), "z":me.selfPos.z()}, me.computeBeamVector());
            if (me.pick != nil) {
                me.terrain = geo.Coord.new();
                me.terrain.set_latlon(me.pick.lat, me.pick.lon, me.pick.elevation);
                me.terrainDist_m = me.selfPos.direct_distance_to(me.terrain);

                return [me.terrainDist_m, me.terrain];
            }
        }
        return nil;
    },
};

var fix = FixedBeamRadar.new();
# AoA of 13 degs, Glideslope of -2.86 degs: Attitude = 13-2.86 = 10.14 degs
# Aircraft FoV of -15 degs: FoV below horizon = -15+10.14 = -4.86 degs
# Beam: -10.14+(-4.86/2) = -12.57
fix.setBeamPitch(-12.57);

if (getprop("/sim/version/compositor-support") != 1) {
    # we only start this if not running in 2020.4.0
    #light_manager.init();
}



