# provides relative vectors from eye-point to aircraft lights
# in east/north/up coordinates the renderer uses
# Thanks to BAWV12 / Thorsten

# 5H1N0B1 201911 :
# Put light stuff in a different object inorder to manage different kind of light
# This need to have work in order to initialize the differents lights with the new object
# Then we need to put a foreach loop in the update loop


var als_on = props.globals.getNode("/sim/rendering/shaders/skydome");
var alt_agl = props.globals.getNode("/position/altitude-agl-ft");
var cur_alt = 0;

var taxiLight = props.globals.getNode("sim/multiplay/generic/bool[46]", 1);
var landingLight = props.globals.getNode("sim/multiplay/generic/bool[47]", 1);
var gearPos = props.globals.getNode("gear/gear[0]/position-norm", 1);


var light_manager = {

	run: 0,
	
	lat_to_m: 110952.0,
	lon_to_m: 0.0,
	
	
	init: func {
		# define your lights here

		# lights ########
      me.data_light = [
                        #light_xpos,light_ypos,light_zpos, light_dir,light_size,light_stretch,light_r,light_g,light_b,light_is_on,number
        ALS_light_spot.new(10,0,-1,  0, 1,-2.5, 0.7,0.7,0.7,0,0),#landing
        ALS_light_spot.new(70,0,-1,  0,12,-7.0, 0.7,0.7,0.7,0,1),#taxi
#        ALS_light_spot.new(-4,4.5,2,0,3.5,0,1,0,0,1,2),#test
#        ALS_light_spot.new(-4,-4.5,2,0,3.5,0,0,0.4,0,1,3)
      ];

		
		
		#setprop("sim/rendering/als-secondary-lights/flash-radius", 13);

		me.start();
	},

	start: func {
		setprop("/sim/rendering/als-secondary-lights/num-lightspots", size(me.data_light));
 
 
		me.run = 1;		
		me.update();
	},

	stop: func {
		me.run = 0;
	},

	update: func {
		if (me.run == 0) {
			return;
		}
		
		cur_alt = alt_agl.getValue();
    if(cur_alt != nil){
      if (als_on.getValue() == 1) {
        
          #Condition for lights
          if(gearPos.getValue() > 0.3 and landingLight.getValue() and alt_agl.getValue() < 750.0){
              me.data_light[0].light_r = 0.8-0.8*alt_agl.getValue()/750;
              me.data_light[0].light_g = me.data_light[0].light_r;
              me.data_light[0].light_b = me.data_light[0].light_r;
              me.data_light[0].light_on();    
          }else{
              me.data_light[0].light_off();
          }
          
          if(gearPos.getValue() > 0.3 and taxiLight.getValue() and alt_agl.getValue() < 50.0){
              me.data_light[1].light_on();            
          }else{
              me.data_light[1].light_off();
          }
          
         #Updating each light position 
        for(var i = 0; i < size(me.data_light); i += 1)
        {
          me.data_light[i].position();
        }
      }
    }
		
		settimer ( func me.update(), 0.00);
	},
};


var ALS_light_spot = {
    new:func (
            light_xpos,
            light_ypos,
            light_zpos,
            light_dir,
            light_size,
            light_stretch,
            light_r,
            light_g,
            light_b,
            light_is_on,
            number
          ){
            var me = { parents : [ALS_light_spot] };
            if(number ==0){
              me.nd_ref_light_x=  props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-x-m", 1);
              me.nd_ref_light_y=  props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-y-m", 1);
              me.nd_ref_light_z= props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-z-m", 1);
              me.nd_ref_light_dir= props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/dir", 1);
              me.nd_ref_light_size= props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/size", 1);
              me.nd_ref_light_stretch= props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/stretch", 1);
              me.nd_ref_light_r=props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/lightspot-r",1);
              me.nd_ref_light_g=props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/lightspot-g",1);
              me.nd_ref_light_b=props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/lightspot-b",1);
            }else{
              me.nd_ref_light_x=  props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-x-m["~number~"]", 1);
              me.nd_ref_light_y=  props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-y-m["~number~"]", 1);
              me.nd_ref_light_z= props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-z-m["~number~"]", 1);
              me.nd_ref_light_dir= props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/dir["~number~"]", 1);
              me.nd_ref_light_size= props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/size["~number~"]", 1);
              me.nd_ref_light_stretch= props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/stretch["~number~"]", 1);
              me.nd_ref_light_r=props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/lightspot-r["~number~"]", 1);
              me.nd_ref_light_g=props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/lightspot-g["~number~"]", 1);
              me.nd_ref_light_b=props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/lightspot-b["~number~"]", 1);
            }
            
              me.light_xpos = light_xpos;
              me.light_ypos=light_ypos;
              me.light_zpos=light_zpos;
              me.light_dir=light_dir;
              me.light_size=light_size;
              me.light_stretch=light_stretch;
              me.light_r=light_r;
              me.light_g=light_g;
              me.light_b=light_b;
              me.light_is_on=light_is_on;
              me.number = number;
              
              #print("light_stretch:"~light_stretch);
              
              me.lon_to_m  = 0;
              me.lat_to_m = 110952.0;
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
    
    position: func(){
      
      cur_alt = alt_agl.getValue();
      var apos = geo.aircraft_position();
			var vpos = geo.viewer_position();

			me.lon_to_m = math.cos(apos.lat()*D2R) * me.lat_to_m;
			var heading = getprop("/orientation/heading-deg")*D2R;

			var lat = apos.lat();
			var lon = apos.lon();
			var alt = apos.alt();

			var sh = math.sin(heading);
			var ch = math.cos(heading);
      if (me.number == 0) {
        #landing light
        
        var test = fix.testForDistance();
        if (test != nil) {
          apos = test[1];
       
          var delta_x = (apos.lat() - vpos.lat()) * me.lat_to_m;
          var delta_y = -(apos.lon() - vpos.lon()) * me.lon_to_m;
          var delta_z = apos.alt() - vpos.alt();
          
          me.nd_ref_light_x.setValue(delta_x);
          me.nd_ref_light_y.setValue(delta_y);
          me.nd_ref_light_z.setValue(delta_z);
          me.nd_ref_light_dir.setValue(heading);  
          me.nd_ref_light_size.setValue(me.light_size*test[0]);
        } else {
          me.nd_ref_light_r.setValue(0);
          me.nd_ref_light_g.setValue(0);
          me.nd_ref_light_b.setValue(0);
          me.light_is_on = 0;
        }
      } else {
        #taxi light
        var proj_x = cur_alt*FT2M*10;
  			var proj_z = cur_alt*FT2M;
        
        #print("sh:"~sh ~" ch:"~ch~ " proj_x:"~proj_x~ " proj_z:"~proj_z ~" me.light_stretch:"~me.light_stretch);
        #print("me.nd_ref_light_x.getValue():"~me.nd_ref_light_x.getValue() ~ " me.nd_ref_light_y.getValue():"~ me.nd_ref_light_y.getValue());
  	 
  			apos.set_lat(lat + ((me.light_xpos + proj_x) * ch + me.light_ypos * sh) / me.lat_to_m);
  			apos.set_lon(lon + ((me.light_xpos + proj_x)* sh - me.light_ypos * ch) / me.lon_to_m);
        

  	 
  			var delta_x = (apos.lat() - vpos.lat()) * me.lat_to_m;
  			var delta_y = -(apos.lon() - vpos.lon()) * me.lon_to_m;
  			var delta_z = apos.alt()- proj_z - vpos.alt();
        
  #        print("delta_x:"~delta_x);
  	 
  			me.nd_ref_light_x.setValue(delta_x);
  			me.nd_ref_light_y.setValue(delta_y);
  			me.nd_ref_light_z.setValue(delta_z);
  			me.nd_ref_light_dir.setValue(heading);	
        me.nd_ref_light_size.setValue(me.light_size+me.light_size*cur_alt*0.05);
      }
    },
    light_on : func {
      if (me.light_is_on == 1) {return;}
        me.nd_ref_light_r.setValue(me.light_r);
        me.nd_ref_light_g.setValue(me.light_g);
        me.nd_ref_light_b.setValue(me.light_b);
        me.light_is_on = 1;
      },
  
    light_off : func {
        if (me.light_is_on == 0) {return;}
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
      me.light = aircraftToCart({x:3.13064, y:0.307693, z: 1.23477});
      me.accoord = geo.Coord.new().set_xyz(me.light.x,me.light.y,me.light.z);
      return me.accoord;
  },
  
  getAttitude: func {
    return [me.acHeading.getValue(),me.acPitch.getValue(),me.acRoll.getValue()];
  },
  
  getSpeedVector: func {
    me.speed_down_mps  = me.acdns.getValue()*FT2M;
        me.speed_east_mps  = me.aceas.getValue()*FT2M;
        me.speed_north_mps = me.acnos.getValue()*FT2M;
        return [me.speed_north_mps,-me.speed_east_mps,-me.speed_down_mps];
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
  new: func () {
    var fb = {parents: [FixedBeamRadar, Radar]};
    
    fb.beam_pitch_deg = 0;
    
    return fb;
  },
  
  setBeamPitch: func (pitch_deg) {
    me.beam_pitch_deg = pitch_deg;
  },
  
  computeBeamVector: func {
    me.beamVector = [math.cos(me.beam_pitch_deg*D2R), 0, math.sin(me.beam_pitch_deg*D2R)];
    me.beamVectorFix = vector.Math.yawPitchRollVector(-self.getHeading(), self.getPitch(), self.getRoll(), me.beamVector);
    me.geoVector = vector.Math.vectorToGeoVector(me.beamVectorFix, self.getLightCoord());
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

# example code
var fix = FixedBeamRadar.new();
fix.setBeamPitch(-7.5);

light_manager.init();



