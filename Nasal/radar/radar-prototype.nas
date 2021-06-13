#
# Prototype to test Richard and radar-mafia's radar designs.
#
# In Richards design, the class called RadarSystem is being represented as AIToNasal, NoseRadar, OmniRadar & TerrainChecker classes.
#                     the class called AircraftRadar is represented as ActiveDiscRadar & RWR.
#                     the class called AIContact does allow for direct reading of properties, but this is forbidden outside RadarSystem. Except for Missile-code.
#
# v1: 7 Nov. 2017 - Modular
# v2: 8 Nov 2017 - Decoupled via emesary
# v3: 10 Nov 2017 - NoseRadar now finds everything inside an elevation bar on demand,
#     and stuff is stored in Nasal.
#     Most methods are reused from v2, and therefore the code is a bit messy now, especially method/variable names and AIContact.
#     Weakness:
#         1) Asking NoseRadar for a slice when locked, is very inefficient.
#         2) If RWR should be feed almost realtime data, at least some properties needs to be read all the time for all aircraft. (damn it!)
# v4: 10 Nov 2017 - Fixed weakness 1 in v3.
# v5: 11 Nov 2017 - Fixed weakness 2 in v3. And added terrain checker.
# v5.1 Added buttons to stop radars and their screens.
# v5.2 Optimized the canvas displays a bit.
# v6.0 Optimized reading the property tree when its updated.
# v6.1 Added doppler readings to contact, they are still not used in the example radars though.
# v6.2 Better behind terrain detection. And some minor bugfixes and refactoring.
# v6.3 June 4th 2021 - Use picking for check if in clutter. And rewrote notching code.
# v7.0 June 9th 2021 - Rewrote Discradar as APG-68 as example, with 3 modes. Relies less on math that only works near horizon.
# v7.1 June 10th 2021 - Added more modes and rootMode vs mainModes (still plus submodes)
# v7.2 June 12th 2021 - Added support for multibleps per contact, and enabled terrain and type checks in APG68.
#                       Added ANSI art to be able to quicker navigate this file.
#
# RCS check done in ActiveDiscRadar at detection time, so about every 5-10 seconds per contact.
#      Faster for locks since its important to lose lock if it turns nose to us suddenly and can no longer be seen.
# Terrain check done in TerrainChecker, 10 contacts per second. All contacts being evaluated due to rwr needs that.
# 
# Properties is only being read in the modules that represent RadarSystem.
#
#
#
#
# Notice that everything below test code line, is not decoupled, nor optimized in any way.
# Also notice that most comments at start of classes are old and not updated.
#
# Needs rcs.nas and vector.nas. Nothing else. When run, it will display a couple of example canvas dialogs on screen.
#
# GPL 2.0


var AIR = 0;
var MARINE = 1;
var SURFACE = 2;
var ORDNANCE = 3;

var ECEF = 0;
var GPS = 1;

var FALSE = 0;
var TRUE = 1;

var knownShips = {
    "missile_frigate":       nil,
    "frigate":       nil,
    "fleet":       nil,
    "USS-LakeChamplain":     nil,
    "USS-NORMANDY":     nil,
    "USS-OliverPerry":     nil,
    "USS-SanAntonio":     nil,
};

var knownSurface = {
    "S-75":       nil,
    "buk-m2":       nil,
    "s-300":       nil,
    "depot":       nil,
    "struct":       nil,
    "point":       nil,
    "rig":       nil,
    "gci":       nil,
    "truck":     nil,
    "tower":     nil,
    "MIM104D":       nil,
    "ZSU-23-4M":       nil,
};

var VectorNotification = {
    new: func(type) {
        var new_class = emesary.Notification.new(type, rand());
        new_class.updateV = func (vector) {
	    	me.vector = vector;
	    	return me;
	    };
        return new_class;
    },
};

var SliceNotification = {
    new: func() {
        var new_class = emesary.Notification.new("SliceNotification", rand());
        new_class.slice = func (elev, yaw, elev_radius, yaw_radius, dist_m, fa, fg, fs) {
	    	me.elev = elev;
	    	me.yaw = yaw;
	    	me.elev_radius = elev_radius;
	    	me.yaw_radius = yaw_radius;
	    	me.dist_m = dist_m;
	    	me.fa = fa;
	    	me.fg = fg;
	    	me.fs = fs;
	    	return me;
	    };
        return new_class;
    },
};


#  ███    ███  ██████  ██████  ███████ ██          ██████   █████  ██████  ███████ ███████ ██████  
#  ████  ████ ██    ██ ██   ██ ██      ██          ██   ██ ██   ██ ██   ██ ██      ██      ██   ██ 
#  ██ ████ ██ ██    ██ ██   ██ █████   ██          ██████  ███████ ██████  ███████ █████   ██████  
#  ██  ██  ██ ██    ██ ██   ██ ██      ██          ██      ██   ██ ██   ██      ██ ██      ██   ██ 
#  ██      ██  ██████  ██████  ███████ ███████     ██      ██   ██ ██   ██ ███████ ███████ ██   ██ 
#                                                                                                  
#                                                                                                  
AIToNasal = {
# convert AI property tree to Nasal vector
# will send notification when some is updated (emesary?)
# listeners for adding/removing AI nodes.
# very slow loop (5 min)
# updates AIContacts, does not replace them. (yes will make slower, but solves many issues. Can divide workload over 2 frames.)
#
# Attributes:
#   fullContactVector of AIContacts
#   index keys for fast locating: callsign, model-path??
	enabled: 1,
	new: func {
		me.prop_AIModels = props.globals.getNode("ai/models");
		me.vector_aicontacts = [];
		me.scanInProgress = 0;
		me.startOver = 0;
		me.lookupCallsign = {};
		me.AINotification = VectorNotification.new("AINotification");
		me.AINotification.updateV(me.vector_aicontacts);

		me.l1 = setlistener("/ai/models/model-added", func me.callReadTree());
		me.l2 = setlistener("/ai/models/model-removed", func me.callReadTree());
		me.loop = maketimer(300, me, func me.callReadTree());
		me.loop.start();
		me.callReadTree();
		return me;
	},

	callReadTree: func {
		if(!me.enabled) return;
		#print("NR: listenr called");
		if (!me.scanInProgress) {
			me.scanInProgress = 1;
			me.readTree();
		} else {
			me.startOver = 1;
		}
	},
	
	readTree: func {
		#print("NR: readtree called");
		#me.lookupCallsignRaw = {};
		me.lookupCallsignNew = {};
		me.vector_aicontacts = [];
		me.vector_raw = me.prop_AIModels.getChildren();
		me.vector_raw_index = 0;
		me.startOver = 0;
		if (size(me.vector_raw)) {
			me.readTreeFrame();
		} else {
			me.updateVector();
        	me.scanInProgress = 0;
		}
	},

	readTreeFrame: func {
		# called once per frame until scan is finished.
		if (me.startOver) {
			me.readTree();
			return;
		}
		
		me.prop_ai = me.vector_raw[me.vector_raw_index];
		me.prop_valid = me.prop_ai.getNode("valid");
		if (me.prop_valid == nil or !me.prop_valid.getValue() or me.prop_ai.getNode("impact") != nil) {
			# its either not a valid entity or its a impact report.
            me.nextReadTreeFrame();
		    return;
        }

        # find short model xml name: (better to do here, even though its slow) [In viggen its placed inside the property tree, which leads to too much code to update it when tree changes]
        me.name_prop = me.prop_ai.getName();
        me.model = me.prop_ai.getNode("sim/model/path");
        if (me.model != nil) {
          	me.path = me.model.getValue();

          	me.model = split(".", split("/", me.path)[-1])[0];
          	me.model = me.remove_suffix(me.model, "-model");
          	me.model = me.remove_suffix(me.model, "-anim");
        } else {
        	me.model = "";
        }

        # position type
        me.pos_type = nil;
        me.pos = me.prop_ai.getNode("position");
	    me.x = me.pos.getNode("global-x");
	    me.y = me.pos.getNode("global-y");
	    me.z = me.pos.getNode("global-z");
	    if(me.x == nil or me.y == nil or me.z == nil) {
	    	me.alt = me.pos.getNode("altitude-ft");
	    	me.lat = me.pos.getNode("latitude-deg");
	    	me.lon = me.pos.getNode("longitude-deg");	
	    	if(me.alt == nil or me.lat == nil or me.lon == nil) {
		      	me.nextReadTreeFrame();
		      	return;
			}
		    me.pos_type = GPS;
		    me.aircraftPos = geo.Coord.new().set_latlon(me.lat.getValue(), me.lon.getValue(), me.alt.getValue()*FT2M);
	    } else {
	    	me.pos_type = ECEF;
	    	me.aircraftPos = geo.Coord.new().set_xyz(me.x.getValue(), me.y.getValue(), me.z.getValue());
	    }
	    
	    me.alt = me.aircraftPos.alt()*M2FT;
	    
	    me.prop_speed = me.prop_ai.getNode("velocities/true-airspeed-kt");
	    me.prop_ord   = me.prop_ai.getNode("missile");

	    me.type = me.determineType(me.name_prop, me.prop_ord, me.alt, me.model, me.prop_speed==nil?nil:me.prop_speed.getValue());
        
        #append(me.vector_aicontacts_raw, me.aicontact);
        me.callsign = me.prop_ai.getNode("callsign");
        if (me.callsign == nil) {
        	me.callsign = "";
        } else {
        	me.callsign = me.callsign.getValue();
        }
        me.id = me.prop_ai.getNode("id");
        if (me.id == nil) {
        	me.id = "0";
        } else {
        	me.id = me.id.getValue();
        }

        #AIcontact needs 2 calls to work. new() [cheap] and init() [expensive]. Only new is called here, updateVector will do init():
        me.aicontact = AIContact.new(me.prop_ai, me.type, me.model, me.callsign, me.pos_type, me.id);

        me.sign = sprintf("%s%04d",me.callsign,me.id);
        #me.signLookup = me.lookupCallsignRaw[me.sign];
        #if (me.signLookup == nil) {
        	me.signLookup = [me.aicontact];
        #} else {
        #	append(me.signLookup, me.aicontact);
        #}
        #me.lookupCallsignRaw[me.sign] = me.signLookup;
        
        me.updateVectorFrame(me.sign,me.signLookup);
        
        me.nextReadTreeFrame();
	},
	
	nextReadTreeFrame: func {
		me.vector_raw_index += 1;
        if (me.vector_raw_index < size(me.vector_raw)) {
        	var mt = maketimer(0,func me.readTreeFrame());
        	mt.singleShot = 1;
        	mt.start();
        } else {
        	me.updateVector();
        	me.scanInProgress = 0;
        }
    },
	
	determineType: func (prop_name, ordnance, alt_ft, model, speed_kt) {
		# determine type. Unsure if this should be done here, or in Radar.
	    #   For here: PRO better performance. CON might change in between calls to reread tree, and dont have doppler to determine air from ground.
        if (prop_name == "carrier") {
        	return MARINE;
        } elsif (prop_name == "aircraft" or prop_name == "Mig-28") {
        	return AIR;
        } elsif (ordnance != nil) {
        	return ORDNANCE;
        } elsif (me.name_prop == "groundvehicle") {
        	return SURFACE;
        } elsif (model != nil and contains(knownSurface, model)) {
			return MARINE;
		} elsif (model != nil and contains(knownShips, model)) {
			return SURFACE;
        } elsif (speed_kt != nil and speed_kt > 60) {
        	return AIR;# to be determined later by doppler in Radar
        } elsif (alt_ft < 3.0) {
        	return MARINE;
        }
        return SURFACE;
	},

	remove_suffix: func(s, x) {
	      me.len = size(x);
	      if (substr(s, -me.len) == x)
	          return substr(s, 0, size(s) - me.len);
	      return s;
	},
	
	updateVectorFrame: func (callsignKey, callsignsRaw) {
		me.callsigns    = me.lookupCallsign[callsignKey];
		if (me.callsigns != nil) {
			foreach(me.newContact; callsignsRaw) {
				me.oldContact = me.containsVectorContact(me.callsigns, me.newContact);
				if (me.oldContact != nil) {
					me.oldContact.update(me.newContact);
					me.newContact = me.oldContact;
				}
				append(me.vector_aicontacts, me.newContact);
				if (me.lookupCallsignNew[callsignKey]==nil) {
					me.lookupCallsignNew[callsignKey] = [me.newContact];
				} else {
					append(me.lookupCallsignNew[callsignKey], me.newContact);
				}
				me.newContact.init();
			}
		} else {
			me.lookupCallsignNew[callsignKey] = callsignsRaw;
			foreach(me.newContact; callsignsRaw) {
				append(me.vector_aicontacts, me.newContact);
				me.newContact.init();
			}
		}		
	},

	updateVector: func {
		me.lookupCallsign = me.lookupCallsignNew;
		#print("NR: update called "~size(me.vector_aicontacts));
		emesary.GlobalTransmitter.NotifyAll(me.AINotification.updateV(me.vector_aicontacts));
	},

	containsVectorContact: func (vec, item) {
		foreach(test; vec) {
			if (test.equals(item)) {
				return test;
			}
		}
		return nil;
	},
	del: func {
		call(func removelistener(me.l1),nil,nil,var err = []);
		call(func removelistener(me.l2),nil,nil,var err = []);
	},
};








Contact = {
# Attributes:
	getCoord: func {
	   	return geo.Coord.new();
	},
};



#   ██████  ██     ██ ███    ██ ███████ ██   ██ ██ ██████  
#  ██    ██ ██     ██ ████   ██ ██      ██   ██ ██ ██   ██ 
#  ██    ██ ██  █  ██ ██ ██  ██ ███████ ███████ ██ ██████  
#  ██    ██ ██ ███ ██ ██  ██ ██      ██ ██   ██ ██ ██      
#   ██████   ███ ███  ██   ████ ███████ ██   ██ ██ ██      
#                                                          
#                                                          
SelfContact = {
# Ownship info
# 
	new: func {
		var c = {parents: [SelfContact, Contact]};

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



#   ██████  ██████  ███    ██ ████████  █████   ██████ ████████ 
#  ██      ██    ██ ████   ██    ██    ██   ██ ██         ██    
#  ██      ██    ██ ██ ██  ██    ██    ███████ ██         ██    
#  ██      ██    ██ ██  ██ ██    ██    ██   ██ ██         ██    
#   ██████  ██████  ██   ████    ██    ██   ██  ██████    ██    
#                                                               
#                                                               
AIContact = {
# Attributes:
#   replaceNode() [in AI tree]
	new: func (prop, type, model, callsign, pos_type, ident) {
		var c = {parents: [AIContact, Contact]};

		# general:
		c.prop     = prop;
		c.type     = type;#TODO: this should be updated dynamically
		c.model    = model;
		c.callsign = callsign;
		c.pos_type = pos_type;
		c.needInit = 1;
		c.azi      = 0;
		c.visible  = 1;
		c.inClutter = 0;
		c.hiddenFromDoppler = 0;
		c.id = ident;
		c.bleps = [];
		c.lastRegisterWasTrack = 0;

		# active radar:
		c.blepTime = -1000;
		c.coordFrozen = geo.Coord.new();

    	return c;
	},

	init: func {
		if (me.needInit == 0) {
			# init is expensive. Avoid it if not needed.
			return;
		}
		me.needInit = 0;
		# read all properties and store them for fast lookup.
		me.pos     = me.prop.getNode("position");
		me.ori     = me.prop.getNode("orientation");
		me.vel     = me.prop.getNode("velocities");
		me.x       = me.pos.getNode("global-x");
    	me.y       = me.pos.getNode("global-y");
    	me.z       = me.pos.getNode("global-z");
    	me.alt     = me.pos.getNode("altitude-ft");
    	me.lat     = me.pos.getNode("latitude-deg");
    	me.lon     = me.pos.getNode("longitude-deg");
    	me.heading = me.ori.getNode("true-heading-deg");
    	me.pitch   = me.ori.getNode("pitch-deg");
    	me.roll    = me.ori.getNode("roll-deg");
    	me.speed   = me.vel.getNode("true-airspeed-kt");
    	me.tp      = me.prop.getNode("instrumentation/transponder/transmitted-id");
    	me.rdr     = me.prop.getNode("sim/multiplay/generic/int[2]");
    	    	
	},

	update: func (newC) {
		if (me.prop.getPath() != newC.prop.getPath()) {
			me.prop = newC.prop;
			me.needInit = 1;
		}
		me.type = newC.type;
		me.model = newC.model;
		me.callsign = newC.callsign;
	},

	equals: func (item) {
		if (item != nil and item.prop.getName() == me.prop.getName() and item.type == me.type and item.model == me.model and item.callsign == me.callsign) {
			return TRUE;
		}
		return FALSE;
	},

	getCoord: func {
		if (me.pos_type = ECEF) {
	    	me.coord = geo.Coord.new().set_xyz(me.x.getValue(), me.y.getValue(), me.z.getValue());
	    	return me.coord;
	    } else {
	    	if(me.alt == nil or me.lat == nil or me.lon == nil) {
		      	return geo.Coord.new();
		    }
		    me.coord = geo.Coord.new().set_latlon(me.lat.getValue(), me.lon.getValue(), me.alt.getValue()*FT2M);
		    return me.coord;
	    }	
	},

	getType: func {
		if (me.type == AIR and me.getSpeed() < 60) me.type = SURFACE;
		if (me.type == SURFACE and me.getSpeed() > 60) me.type = AIR;
		return me.type;
	},
	
	getCallsign: func {
		return me.callsign;
	},

	getDeviationPitch: func {
		me.getCoord();
		me.pitched = vector.Math.getPitch(self.getCoord(), me.coord);
		return me.pitched - self.getPitch();
	},

	getDeviationHeading: func {
		me.getCoord();
		return geo.normdeg180(self.getCoord().course_to(me.coord)-self.getHeading());
	},

	getRangeDirect: func {# meters
		me.getCoord();
		return self.getCoord().direct_distance_to(me.coord);
	},
	
	getRange: func {# meters
		me.getCoord();
		return self.getCoord().distance_to(me.coord);
	},

	getPitch: func {
		if (me.pitch == nil) {
			return 0;
		}
		return me.pitch.getValue();
	},

	getRoll: func {
		if (me.roll == nil) {
			return 0;
		}
		return me.roll.getValue();
	},

	getHeading: func {
		if (me.heading == nil) {
			return 0;
		}
		return me.heading.getValue();
	},

	getSpeed: func {
		if (me.speed == nil) {
			return 0;
		}
		return me.speed.getValue();
	},

	getBearing: func {
		return self.getCoord().course_to(me.getCoord());
	},

	getElevation: func {
		return vector.Math.getPitch(self.getCoord(), me.getCoord());
	},

	getDeviation: func {
		# optimized method that return both heading and pitch deviation, to limit property calls
		# returns [bearingDev, elevationDev, distDirect, coord]
		me.getCoord();
		me.acCoord = self.getCoord();
		me.globalToTarget = vector.Math.eulerToCartesian3X(-me.acCoord.course_to(me.coord), vector.Math.getPitch(me.acCoord, me.coord), 0);
		me.localToTarget = vector.Math.rollPitchYawVector(-self.getRoll(), -self.getPitch(), self.getHeading(), me.globalToTarget);
		me.euler = vector.Math.cartesianToEuler(me.localToTarget);

		return [geo.normdeg180(me.euler[0] ==nil?0:me.euler[0]), me.euler[1], me.acCoord.direct_distance_to(me.coord), me.coord];
	},

	isTransponderEnable: func {
		return me.tp != nil and me.tp.getValue() != nil and me.tp.getValue() != -9999;
	},

	isRadarEnable: func {
		if (me.rdr == nil or me.rdr.getValue() != 1) {
			return 1;
		}
		return 0;
	},

	isVisible: func {
		return me.visible;
	},

	setVisible: func (vis) {
		me.visible = vis;
	},
	
	isInClutter: func {
		return me.inClutter;
	},

	setInClutter: func (clut) {
		me.inClutter = clut;
	},
	
	isHiddenFromDoppler: func {
		return me.hiddenFromDoppler;
	},

	setHiddenFromDoppler: func (dopp) {
		me.hiddenFromDoppler = dopp;
	},

	getModel: func {
		return me.model;
	},

	#
	#
	#
	#        BLEP  methods:
	#
	#
	#

	blep: func (time, searchInfo, strength) {
		# searchInfo:               dist, groundtrack, deviations, speed, closing-rate, altitude
		# blep: time, rcs_strength, dist, heading, deviations vector, speed, closing-rate, altitude
		var newBlep = [];
		var value = 0;
		me.getCoord();
		var ownship = self.getCoord();
		append(newBlep, time);
		append(newBlep, strength);
		if (searchInfo[0]) {
			value = ownship.direct_distance_to(me.coord);
			append(newBlep, value);
		} else {
			append(newBlep, nil);
		}
		if (searchInfo[1]) {
			value = me.getHeading();
			append(newBlep, value);
			me.lastRegisterWasTrack = 1;
		} else {
			append(newBlep, nil);
			me.lastRegisterWasTrack = 0;
		}
		if (searchInfo[2]) {
			value = [me.getDeviationHeading(), me.getDeviationPitch(), me.getBearing(), me.getElevation()];
			append(newBlep, value);
		} else {
			append(newBlep, nil);
		}
		if (searchInfo[3]) {
			value = me.getSpeed();#kt
			append(newBlep, value);
		} else {
			append(newBlep, nil);
		}
		if (searchInfo[4]) {
			var bearing = ownship.course_to(me.coord);
			var rbearing = bearing+180;
			var ownship_spd = self.getSpeed() * math.cos( -(bearing - self.getHeading()) * D2R);
            var target_spd  = me.getSpeed()   * math.cos( -(rbearing - me.getHeading()) * D2R);
			value = ownship_spd + target_spd;
			append(newBlep, value);
		} else {
			append(newBlep, nil);
		}
		if (searchInfo[5]) {
			value = me.coord.alt()*M2FT;
			append(newBlep, value);
		} else {
			append(newBlep, nil);
		}
		append(me.bleps, newBlep);
	},

	getBleps: func {
		# get the frozen info needed for displays
		# blep: time, rcs_strength, dist, heading, deviations vector, speed, closing-rate, altitude
		return me.bleps;
	},

	setBleps: func (bleps_cleaned) {
		# call this after pruning the bleps
		me.bleps = bleps_cleaned;
	},

	hasTrackInfo: func {
		# convinience method
		if (size(me.bleps)) {
			if (me.bleps[size(me.bleps)-1][3] != nil) {
				return 1;
			}
		}
		return 0;
	},

	hadTrackInfo: func {
		# convinience method
		return me.lastRegisterWasTrack;
	},

	ignoreTrackInfo: func {
		# convinience method
		me.lastRegisterWasTrack = 0;
	},

	storeDeviation: func (dev) {
		# [bearingDev, elevationDev, distDirect, coord, heading, pitch, roll]
		# should really be a hash instead of vector?
		me.devStored = dev;
	},
	
	getDeviationStored: func {
		# get the frozen info needed for noseradar/radar
		return me.devStored;
	},

	storeThreat: func (threat) {
		# [bearing,heading,coord,transponder,radar,devheading]
		# should really be a hash instead of vector
		me.threatStored = threat;
	},
	
	getThreatStored: func {
		# get the frozen info needed for RWR
		return me.threatStored;
	},

	#
	# convinience methods for last registered blep:
	#

	getLastDirection: func {
		
		if (size(me.bleps)) {
			#if (me.bleps[size(me.bleps)-1][4] != nil) {
				return me.bleps[size(me.bleps)-1][4];
			#}
		}
		return nil;
	},

	getLastRangeDirect: func {
		if (size(me.bleps)) {
			#if (me.bleps[size(me.bleps)-1][4] != nil) {
				return me.bleps[size(me.bleps)-1][2];
			#}
		}
		return nil;
	},

	getLastAltitude: func {
		if (size(me.bleps)) {
			#if (me.bleps[size(me.bleps)-1][4] != nil) {
				return me.bleps[size(me.bleps)-1][7];
			#}
		}
		return nil;
	},

	getLastBlepTime: func {
		if (size(me.bleps)) {
			#if (me.bleps[size(me.bleps)-1][4] != nil) {
				return me.bleps[size(me.bleps)-1][0];
			#}
		}
		return -1000;
	},	





	# The following remaining methods is being deprecated:

	getDeviationPitchFrozen: func {
		me.pitched = vector.Math.getPitch(self.getCoord(), me.coordFrozen);
		return me.pitched - self.getPitch();
		#return me.devStored[1];
	},

	getElevationFrozen: func {
		return vector.Math.getPitch(self.getCoord(), me.coordFrozen);
	},

	getDeviationHeadingFrozen: func {#is really bearing, should be renamed.
		return self.getCoord().course_to(me.coordFrozen)-self.getHeading();
		#return me.devStored[0];
	},

	getCartesianInFoRFrozen: func {# TODO: this is broken, fix it or stop using this method..
		return [me.devStored[9], me.devStored[10]];
	},

	getHeadingFrozen: func (override=0) {
		if (me.azi or override) {
			#return me.headingFrozen;
			return me.devStored[4];
		} else {
			return nil;
		}
	},

	getPitchFrozen: func (override=0) {
		if (me.azi or override) {
			#return me.headingFrozen;
			return me.devStored[5];
		} else {
			return nil;
		}
	},

	getRollFrozen: func (override=0) {
		if (me.azi or override) {
			#return me.headingFrozen;
			return me.devStored[6];
		} else {
			return nil;
		}
	},

	getRangeDirectFrozen: func {# meters
		return self.getCoord().direct_distance_to(me.coordFrozen);
		#return me.devStored[2];
	},

	getRangeFrozen: func {# meters
		return self.getCoord().distance_to(me.coordFrozen);
		#return me.devStored[3];
	},

	getAltitudeFrozen: func {
		return me.devStored[11];
	},

};





###GPSContact:
# inherits from Contact
#
# Attributes:
#   coord

###RadarContact:
# inherits from AIContact
#
# Attributes:
#   isPainted()  [asks parent radar is it the one that is painted]
#   isDetected() [asks parent radar if it still is in limitedContactVector]

###LinkContact:
# inherits from AIContact
#
# Attributes:
#   isPainted()  [asks parent radar is it the one that is painted]
#   link to linking aircraft AIContact
#   isDetected() [asks parent radar if it still is in limitedContactVector]













Radar = {
# root radar class
#
# Attributes:
#   on/off
	enabled: TRUE,
};


#  ██████   █████  ██████  ████████ ██ ████████ ██  ██████  ███    ██ 
#  ██   ██ ██   ██ ██   ██    ██    ██    ██    ██ ██    ██ ████   ██ 
#  ██████  ███████ ██████     ██    ██    ██    ██ ██    ██ ██ ██  ██ 
#  ██      ██   ██ ██   ██    ██    ██    ██    ██ ██    ██ ██  ██ ██ 
#  ██      ██   ██ ██   ██    ██    ██    ██    ██  ██████  ██   ████ 
#                                                                     
#                                                                     
NoseRadar = {
	# I partition the sky into the field of regard and preserve the contacts in that field for it to be scanned by ActiveDiscRadar or similar
	new: func () {
		var nr = {parents: [NoseRadar, Radar]};

		nr.vector_aicontacts = [];
		nr.vector_aicontacts_for = [];

		nr.NoseRadarRecipient = emesary.Recipient.new("NoseRadarRecipient");
		nr.NoseRadarRecipient.radar = nr;
		nr.NoseRadarRecipient.Receive = func(notification) {
	        if (notification.NotificationType == "AINotification") {
	        	#printf("NoseRadar recv: %s", notification.NotificationType);
	            if (me.radar.enabled == 1) {
	    		    me.radar.vector_aicontacts = notification.vector;
	    	    }
	            return emesary.Transmitter.ReceiptStatus_OK;
	        } elsif (notification.NotificationType == "SliceNotification") {
	        	#printf("NoseRadar recv: %s", notification.NotificationType);
	            if (me.radar.enabled == 1) {
	    		    me.radar.scanFOR(notification.elev, notification.yaw, notification.elev_radius, notification.yaw_radius, notification.dist_m, notification.fa, notification.fg, notification.fs);
	    	    }
	            return emesary.Transmitter.ReceiptStatus_OK;
	        } elsif (notification.NotificationType == "ContactNotification") {
	        	#printf("NoseRadar recv: %s", notification.NotificationType);
	            if (me.radar.enabled == 1) {
	    		    me.radar.scanSingleContact(notification.vector[0]);
	    	    }
	            return emesary.Transmitter.ReceiptStatus_OK;
	        }
	        return emesary.Transmitter.ReceiptStatus_NotProcessed;
	    };
		emesary.GlobalTransmitter.Register(nr.NoseRadarRecipient);
		nr.FORNotification = VectorNotification.new("FORNotification");
		nr.FORNotification.updateV(nr.vector_aicontacts_for);
		#nr.timer.start();
		return nr;
	},

	scanFOR: func (elev, yaw, elev_radius, yaw_radius, dist_m, filter_air, filter_gnd, filter_sea) {
		if (!me.enabled) return;
		#iterate:
		# check direct distance
		# check field of regard
		# sort in bearing?
		# called on demand
		# TODO: vectorized field instead
		me.owncrd = geo.aircraft_position();

		me.unitX = vector.Math.eulerToCartesian3X(-yaw, elev, 0);
		me.unitZ = vector.Math.eulerToCartesian3Z(-yaw, elev, 0);
		me.unitY = vector.Math.eulerToCartesian3Y(-yaw, elev, 0);

		me.tmpVec = vector.Math.vectorToGeoVector(me.unitX, me.owncrd);
		me.unitX = vector.Math.normalize([me.tmpVec.x,me.tmpVec.y,me.tmpVec.z]);
		me.tmpVec = vector.Math.vectorToGeoVector(me.unitY, me.owncrd);
		me.unitY = vector.Math.normalize([me.tmpVec.x,me.tmpVec.y,me.tmpVec.z]);
		me.tmpVec = vector.Math.vectorToGeoVector(me.unitZ, me.owncrd);
		me.unitZ = vector.Math.normalize([me.tmpVec.x,me.tmpVec.y,me.tmpVec.z]);
		
		me.cc = [me.owncrd.x(),me.owncrd.y(),me.owncrd.z()];

		me.vector_aicontacts_for = [];
		foreach(contact ; me.vector_aicontacts) {
			var theType = contact.getType();
			if (filter_air and theType == AIR) continue;
			if (filter_gnd and theType == SURFACE) continue;
			if (filter_sea and theType == MARINE) continue;
			if (theType == ORDNANCE) continue;

			if (!contact.isVisible()) {  # moved to nose radar. TODO: WHy double it in discradar? hmm, dont matter so much, its lightning fast
				continue;
			}

			me.dev = contact.getDeviation();
			me.rng = contact.getRangeDirect();
			if (me.rng > dist_m) {
				continue;
			}
			me.crd = contact.getCoord();

			# Field of regard frustum test:
			me.vecToTarget = [me.crd.x()-me.cc[0],me.crd.y()-me.cc[1],me.crd.z()-me.cc[2]];
			me.pc_x = vector.Math.dotProduct(me.vecToTarget, me.unitX);
			me.pc_y = vector.Math.dotProduct(me.vecToTarget, me.unitY);
			me.pc_z = vector.Math.dotProduct(me.vecToTarget, me.unitZ);

			me.h = me.pc_x*2*math.tan(elev_radius*D2R);
			if (-me.h/2 > me.pc_z or me.pc_z > me.h/2) {
				#print("not Z in for");
				continue;
			}
			me.w = me.h * yaw_radius / elev_radius; # height x ratio
			if (-me.w/2 > me.pc_y or me.pc_y  >  me.w/2) {
				#print("not Y in for");
				continue;
			}
			# TODO: clean this up. Only what is needed for testing against instant FoV and RCS should be in here:
			#                       localdev, localpitch, range_m, coord, heading, pitch, roll, bearing, elevation, frustum_norm_y, frustum_norm_z, alt_ft
			contact.storeDeviation([me.dev[0],me.dev[1],me.rng,contact.getCoord(),contact.getHeading(), contact.getPitch(), contact.getRoll(), contact.getBearing(), contact.getElevation(), -me.pc_y/(me.w/2), me.pc_z/(me.h/2), me.crd.alt()*M2FT]);
			append(me.vector_aicontacts_for, contact);
		}		
		emesary.GlobalTransmitter.NotifyAll(me.FORNotification.updateV(me.vector_aicontacts_for));
		#print("In Field of Regard: "~size(me.vector_aicontacts_for));
	},

	scanSingleContact: func (contact) {# TODO: rework this method (If its even needed anymore)
		if (!me.enabled) return;
		# called on demand
		me.vector_aicontacts_for = [];
		me.dev = contact.getDeviation();
		me.rng = contact.getRangeDirect();
		contact.storeDeviation([me.dev[0],me.dev[1],me.rng,contact.getCoord(),contact.getHeading(), contact.getPitch(), contact.getRoll()]);#TODO: store approach velocity also
		append(me.vector_aicontacts_for, contact);

		emesary.GlobalTransmitter.NotifyAll(me.FORNotification.updateV(me.vector_aicontacts_for));
		#print("In Field of Regard: "~size(me.vector_aicontacts_for));
	},
	del: func {
        emesary.GlobalTransmitter.DeRegister(me.NoseRadarRecipient);
    },
};




#   ██████  ███    ███ ███    ██ ██ 
#  ██    ██ ████  ████ ████   ██ ██ 
#  ██    ██ ██ ████ ██ ██ ██  ██ ██ 
#  ██    ██ ██  ██  ██ ██  ██ ██ ██ 
#   ██████  ██      ██ ██   ████ ██ 
#                                   
#                                   
OmniRadar = {
	# I check the sky 360 deg for anything potentially detectable by a passive radar system.
	new: func (rate, max_dist_nm, tp_dist_nm) {
		var omni = {parents: [OmniRadar, Radar]};
		
		omni.max_dist_nm = max_dist_nm;
		omni.tp_dist_nm  =  tp_dist_nm;
		
		omni.vector_aicontacts = [];
		omni.vector_aicontacts_for = [];
		omni.timer          = maketimer(rate, omni, func omni.scan());

		omni.OmniRadarRecipient = emesary.Recipient.new("OmniRadarRecipient");
		omni.OmniRadarRecipient.radar = omni;
		omni.OmniRadarRecipient.Receive = func(notification) {
	        if (notification.NotificationType == "AINotification") {
	        	#printf("NoseRadar recv: %s", notification.NotificationType);
	            if (me.radar.enabled == 1) {
	    		    me.radar.vector_aicontacts = notification.vector;
	    	    }
	            return emesary.Transmitter.ReceiptStatus_OK;
	        }
	        return emesary.Transmitter.ReceiptStatus_NotProcessed;
	    };
		emesary.GlobalTransmitter.Register(omni.OmniRadarRecipient);
		omni.OmniNotification = VectorNotification.new("OmniNotification");
		omni.OmniNotification.updateV(omni.vector_aicontacts_for);
		omni.timer.start();
		return omni;
	},

	scan: func () {
		if (!enableRWR) return;
		me.vector_aicontacts_for = [];
		foreach(contact ; me.vector_aicontacts) {
			if (!contact.isVisible()) { # moved to omniradar
				continue;
			}
			me.ber = contact.getBearing();
			me.head = contact.getHeading();
			me.test = me.ber+180-me.head;
			me.tp = contact.isTransponderEnable();
			me.radar = contact.isRadarEnable();
            if ((math.abs(geo.normdeg180(me.test)) < 60 or (me.tp and contact.getRangeDirect()*M2NM < me.tp_dist_nm)) and contact.getRangeDirect()*M2NM < me.max_dist_nm) {
            	contact.storeThreat([me.ber,me.head,contact.getCoord(),me.tp,me.radar,contact.getDeviationHeading(),contact.getRangeDirect()*M2NM]);
				append(me.vector_aicontacts_for, contact);
				#printf("In omni Field: %s %d", contact.getModel(), contact.getRange()*M2NM);
			}
		}
		emesary.GlobalTransmitter.NotifyAll(me.OmniNotification.updateV(me.vector_aicontacts_for));
		#print("In omni Field: "~size(me.vector_aicontacts_for));
	},
	del: func {
        emesary.GlobalTransmitter.DeRegister(me.OmniRadarRecipient);
    },
};





#  ████████ ███████ ██████  ██████   █████  ██ ███    ██ 
#     ██    ██      ██   ██ ██   ██ ██   ██ ██ ████   ██ 
#     ██    █████   ██████  ██████  ███████ ██ ██ ██  ██ 
#     ██    ██      ██   ██ ██   ██ ██   ██ ██ ██  ██ ██ 
#     ██    ███████ ██   ██ ██   ██ ██   ██ ██ ██   ████ 
#                                                        
#                                                        
TerrainChecker = {
	new: func (rate, use_doppler, doppler_speed_kt=50) {
		var tc = {parents: [TerrainChecker]};

		tc.use_doppler = use_doppler;
		tc.doppler_speed_kt = doppler_speed_kt;
		tc.inClutter = 0;
		tc.vector_aicontacts = [];
		tc.timer          = maketimer(rate, tc, func tc.scan());

		tc.TerrainCheckerRecipient = emesary.Recipient.new("TerrainCheckerRecipient");
		tc.TerrainCheckerRecipient.radar = tc;
		tc.TerrainCheckerRecipient.Receive = func(notification) {
	        if (notification.NotificationType == "AINotification") {
	        	#printf("NoseRadar recv: %s", notification.NotificationType);
	    		me.radar.vector_aicontacts = notification.vector;
	    		me.radar.index = 0;
	            return emesary.Transmitter.ReceiptStatus_OK;
	        }
	        return emesary.Transmitter.ReceiptStatus_NotProcessed;
	    };
		emesary.GlobalTransmitter.Register(tc.TerrainCheckerRecipient);
		tc.index = 0;
		tc.timer.start();
		return tc;
	},

	scan: func () {
		#this loop is really fast. But we only check 1 contact per call
		if (me.index > size(me.vector_aicontacts)-1) {
			# will happen if there is no contacts
			me.index = 0;
			return;
		}
		me.contact = me.vector_aicontacts[me.index];
		me.terrResult = me.fastTerrainCheck(me.contact);
        me.contact.setVisible(me.terrResult > 0);
        me.inClutter = me.terrResult < 2;
        me.checkClutter(me.contact);
        me.index += 1;
        if (me.index > size(me.vector_aicontacts)-1) {
        	me.index = 0;
        }
	},
	
	checkClutter: func (contact) {
		contact.setInClutter(me.inClutter);
		me.tas = contact.prop.getNode("velocities/true-airspeed-kt");
		me.rang = contact.prop.getNode("radar/range-nm");
		if (!me.use_doppler or 
	        (me.tas != nil and me.tas.getValue() != nil
	         and me.rang != nil and me.rang.getValue() != nil
	         and math.atan2(me.tas.getValue(), me.rang.getValue()*1000) > 0.025)# if aircraft traverse speed seen from me is high
	        ) {
	      	contact.setHiddenFromDoppler(0);
	      	return;
	    }
	    
		me.dopplerCanDetect = 0;
	    if(!me.inClutter) {
	        me.dopplerCanDetect = 1;
	    } elsif (me.getTargetSpeedRelativeToClutter(contact) > me.doppler_speed_kt) {
	        me.dopplerCanDetect = 1;
	    }
	    contact.setHiddenFromDoppler(!me.dopplerCanDetect);
	},
		
	getTargetSpeedRelativeToClutter: func (contact) {
		me.vectorOwnshipSpeed   = self.getSpeedVector();
		me.vectorTargetSpeed    = vector.Math.product(contact.getSpeed()*KT2MPS, vector.Math.normalize(vector.Math.eulerToCartesian3X(-contact.getHeading(), contact.getPitch(), contact.getRoll())));
		me.vectorClutterSpeed   = vector.Math.product(-1, me.vectorOwnshipSpeed);
		me.vectorOfTargetSpeedRelativeToClutter = vector.Math.minus(me.vectorTargetSpeed, me.vectorClutterSpeed);
		me.vectorToTarget       = vector.Math.eulerToCartesian3X(-contact.getBearing(), contact.getDeviationPitch(), 0);
		me.vectorOfTargetSpeedRelativeToClutterSeenFromRadar = vector.Math.projVectorOnVector(me.vectorOfTargetSpeedRelativeToClutter, me.vectorToTarget);
		return vector.Math.magnitudeVector(me.vectorOfTargetSpeedRelativeToClutterSeenFromRadar)*MPS2KT;
	},
	
	fastTerrainCheck: func (contact) {
		me.myOwnPos = self.getCoord();
		me.targetCoord = contact.getCoord();
	    me.maxDist = me.myOwnPos.direct_distance_to(me.targetCoord);
	    
	    #call(func {
	    if (me.maxDist*0.001 > 3.57*(math.sqrt(math.max(0,me.myOwnPos.alt()))+math.sqrt(math.max(0,me.targetCoord.alt())))) {
	    	# behind earth curvature
	    	return 0;
	    }
	    #}, nil, nil, var err =[]);# The call check is to guard against bad alt numbers sent over MP, but maybe max(0 is enough..
	    if(me.myOwnPos.alt() > 8900 and me.targetCoord.alt() > 8900) {
			# both higher than mt. everest, so not need to check further. (in reality due to earth curvature this is not true, but what would be the odds..)
			return 2;
	    }
	    return me.slowTerrainCheck();
	},

	slowTerrainCheck: func () {
	    
		me.xyz = {"x":me.myOwnPos.x(),                  "y":me.myOwnPos.y(),                 "z":me.myOwnPos.z()};
		me.dir = {"x":me.targetCoord.x()-me.myOwnPos.x(),  "y":me.targetCoord.y()-me.myOwnPos.y(), "z":me.targetCoord.z()-me.myOwnPos.z()};

		# Check for terrain between own aircraft and other:
		me.v = get_cart_ground_intersection(me.xyz, me.dir);
		if (me.v == nil) {
			return 2;
			#printf("No terrain, planes has clear view of each other");
		} else {
			me.terrain = geo.Coord.new();
			me.terrain.set_latlon(me.v.lat, me.v.lon, me.v.elevation);
			
			me.terrainDist = me.myOwnPos.direct_distance_to(me.terrain);
			if (me.terrainDist < me.maxDist - 1) {
		 		#print("terrain found between the planes");
		 		return 0;
			} else {
		  		return 1;
		  		#print("The planes has clear view of each other, with clutter in background");
			}
		}
	},
	del: func {
        emesary.GlobalTransmitter.DeRegister(me.TerrainCheckerRecipient);
    },
};































#  ███    ███  ██████  ██████  ███████ ███████ 
#  ████  ████ ██    ██ ██   ██ ██      ██      
#  ██ ████ ██ ██    ██ ██   ██ █████   ███████ 
#  ██  ██  ██ ██    ██ ██   ██ ██           ██ 
#  ██      ██  ██████  ██████  ███████ ███████ 
#                                              
#                                              
var RadarMode = {
	azimuthTilt: 0,
	radar: nil,
	range: 40,
	minRange: 10,
	az: 60,
	bars: 4,
	lastTilt: nil,
	lastBars: nil,
	lastAz: nil,
	lastAzimuthTilt: nil,
	barHeight: 1,# multiple of instantFoV
	barPattern:  [ [[-1,0],[1,0]],
	               [[-1,-1],[1,-1],[1,1],[-1,1]],
	               [[-1,0],[1,0],[1,1.5],[-1,1.5],[-1,0],[1,0],[1,-1.5],[-1,-1.5]],
	               [[1,-3],[1,3],[-1,3],[-1,1],[1,1],[1,-1],[-1,-1],[-1,-3]] ],
	currentPattern: [],
	barPatternMin: [0,-1, -1.5, -3],
	barPatternMax: [0, 1,  1.5,  3],
	nextPatternNode: 0,
	scanPriorityEveryFrame: 0,
	timeToKeepBleps: 13,
	rootName: "CRM",
	shortName: "",
	longName: "",
	superMode: nil,
	minimumTimePerReturn: 1.25,
	rcsFactor: 0.9,
	lastFrameStart: -1,
	lastFrameDuration: 5,
	detectAIR: 1,
	detectSURFACE: 0,
	detectMARINE: 0,
	showAZ: func {
		return me.az != 60;
	},
	showBars: func {
		return 1;
	},
	setRange: func (range) {
		me.testMulti = 160/range;
		if (me.testMulti < 1 or me.testMulti > 16 or int(me.testMulti) != me.testMulti) {
			return 0;
		}
		me.range = math.min(me.maxRange, range);
		me.range = math.max(me.minRange, range);
		return range == me.range;
	},
	_increaseRange: func {
		me.range*=2;
		if (me.range>me.maxRange) {
			me.range*=0.5;
			return 0;
		}
		return 1;
	},
	_decreaseRange: func {
		me.range *= 0.5;
		if (me.range < me.minRange) {
			me.range *= 2;
			return 0;
		}
		return 1;
	},
	setDeviation: func (dev_tilt_deg) {
		if (me.az == 60) {
			dev_tilt_deg = 0;
		}
		me.azimuthTilt = dev_tilt_deg;
		if (me.azimuthTilt > me.radar.fieldOfRegardMaxAz-me.az) {
			me.azimuthTilt = me.radar.fieldOfRegardMaxAz-me.az;
		} elsif (me.azimuthTilt < -me.radar.fieldOfRegardMaxAz+me.az) {
			me.azimuthTilt = -me.radar.fieldOfRegardMaxAz+me.az;
		}
	},
	getDeviation: func {
		return me.azimuthTilt;
	},
	getBars: func {
		return me.bars;
	},
	getAz: func {
		return me.az;
	},
	getPriority: func {
		return me["priorityTarget"];
	},
	step: func (dt, tilt) {
		me.radar.horizonStabilized = 1;
		me.preStep();
		
		# figure out if we reach the gimbal limit, and if so, keep within it:
		me.min = me.barPatternMin[me.bars-1]*me.barHeight*me.radar.instantFoVradius+tilt;# This is the min/max we desire.
		me.max = me.barPatternMax[me.bars-1]*me.barHeight*me.radar.instantFoVradius+tilt;
 		me.actualMin = self.getPitch()-me.radar.fieldOfRegardMaxElev;
 		me.actualMax = self.getPitch()+me.radar.fieldOfRegardMaxElev;
 		if (me.min < me.actualMin) {
 			me.gimbalTiltOffset = me.actualMin-me.min;
 			#printf("offset %d  actualMin %d  desire %d  pitch %d  tilt %d",me.gimbalTiltOffset, me.actualMin,me.min,self.getPitch(),tilt);
 		} elsif (me.max > me.actualMax) {
 			me.gimbalTiltOffset = me.actualMax-me.max;
 			#printf("offset %d  actualMax %d  desire %d  pitch %d  tilt %d",me.gimbalTiltOffset, me.actualMax,me.max,self.getPitch(),tilt);
 		} else {
 			me.gimbalTiltOffset = 0;
 		}

		if (me.nextPatternNode == -1 and me.priorityTarget != nil) {
			me.localDir = vector.Math.eulerToCartesian3X(-me.priorityTarget.getDeviationHeadingFrozen(), me.priorityTarget.getDeviationPitchFrozen(), 0);
		} elsif (me.nextPatternNode == -1) {
			me.nextPatternNode == 0;
		} elsif (tilt != me.lastTilt or me.bars != me.lastBars or me.az != me.lastAz or me.azimuthTilt != me.lastAzimuthTilt or me.gimbalTiltOffset != 0) {
			# (re)calculate pattern as vectors.
			me.currentPattern = [];
			foreach (me.eulerNorm ; me.barPattern[me.bars-1]) {
				me.localDir = vector.Math.yawPitchVector(-me.eulerNorm[0]*me.az-me.azimuthTilt, me.eulerNorm[1]*me.radar.instantFoVradius*me.barHeight+tilt+me.gimbalTiltOffset, [1,0,0]);
				#print("Step sweep: ", -me.eulerNorm[0]*me.az-me.azimuthTilt);
				append(me.currentPattern, me.localDir);
			}
			me.lastTilt = tilt;
			me.lastBars = me.bars;
			me.lastAz = me.az;
			me.lastAzimuthTilt = me.azimuthTilt;
		}
		me.maxMove = math.min(me.radar.instantFoVradius*0.8, me.discSpeed_dps*dt);# 0.8 is because the FoV is round so we overlap em a bit
		me.currentPos = me.radar.positionDirection;
		me.angleToNextNode = vector.Math.angleBetweenVectors(me.currentPos, me.nextPatternNode == -1?me.localDir:me.currentPattern[me.nextPatternNode]);
		if (me.angleToNextNode < me.maxMove) {
			#print("resultpitch2 ",vector.Math.cartesianToEuler(me.currentPattern[me.nextPatternNode])[1]);
			me.radar.setAntennae(me.nextPatternNode == -1?me.localDir:me.currentPattern[me.nextPatternNode]);
			me.nextPatternNode += 1;
			if (me.nextPatternNode >= size(me.currentPattern)) {
				me.nextPatternNode = (me.scanPriorityEveryFrame and me.priorityTarget!=nil)?-1:0;
				me.frameCompleted();
			}
			return dt-me.angleToNextNode/me.discSpeed_dps;
		}
		me.newPos = vector.Math.rotateVectorTowardsVector(me.currentPos, me.nextPatternNode == -1?me.localDir:me.currentPattern[me.nextPatternNode], me.maxMove);
		me.radar.setAntennae(me.newPos);
		return 0;
	},
	frameCompleted: func {
		#print("frame ",me.radar.elapsed-me.lastFrameStart);
		if (me.lastFrameStart != -1) {
			me.lastFrameDuration = me.radar.elapsed - me.lastFrameStart;
			me.timeToKeepBleps = me.radar.framesToKeepBleps*me.lastFrameDuration;
		}
		me.lastFrameStart = me.radar.elapsed;
	},
	leaveMode: func {
		# Warning: In this method do not set anything on me.radar only on me.
		me.lastFrameStart = -1;
		me.timeToKeepBleps = 13;
	},
	enterMode: func {
		# Warning: This gets called BEFORE previous mode's leaveMode()
	},
	getRange: func {
		return me.range;
	},
	designatePriority: func (contact) {},
	cycleDesignate: func {},
	testContact: func (contact) {},
	prunedContact: func (c) {
	},
};#                                    END Radar Mode class



#  ██████  ██     ██ ███████ 
#  ██   ██ ██     ██ ██      
#  ██████  ██  █  ██ ███████ 
#  ██   ██ ██ ███ ██      ██ 
#  ██   ██  ███ ███  ███████ 
#                            
#                            
var F16RWSMode = {
	radar: nil,
	shortName: "RWS",
	longName: "Range While Search",
	superMode: nil,
	subMode: nil,
	maxRange: 160,
	discSpeed_dps: 65,#authentic for RWS
	rcsFactor: 0.9,
	new: func (subMode, radar = nil) {
		var mode = {parents: [F16RWSMode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		subMode.superMode = mode;
		subMode.shortName = mode.shortName;
		return mode;
	},
	cycleAZ: func {
		if (me.az == 10) me.az = 30;
		elsif (me.az == 30) {me.az = 60; me.azimuthTilt = 0;}
		elsif (me.az == 60) me.az = 10;
	},
	cycleBars: func {
		me.bars += 1;
		if (me.bars == 3) me.bars = 4;# 3 is only for TWS
		elsif (me.bars == 5) me.bars = 1;
		me.nextPatternNode = 0;
	},
	designate: func (designate_contact) {
		if (designate_contact == nil) return;
		me.radar.setCurrentMode(me.subMode, designate_contact);
		me.subMode.radar = me.radar;# find some smarter way of setting it.
	},
	undesignate: func {},
	designatePriority: func (contact) {
		me.designate(contact);
	},
	preStep: func {
		me.radar.tiltOverride = 0;
	},
	increaseRange: func {
		me._increaseRange();
	},
	decreaseRange: func {
		me._decreaseRange();
	},
	getSearchInfo: func (contact) {
		# searchInfo:               dist, groundtrack, deviations, speed, closing-rate, altitude
		return [1,0,1,0,0,1];
	},
};


#  ██      ██████  ███████ 
#  ██      ██   ██ ██      
#  ██      ██████  ███████ 
#  ██      ██   ██      ██ 
#  ███████ ██   ██ ███████ 
#                          
#                          
var F16LRSMode = {
	shortName: "LRS",
	longName: "Long Range Search",
	discSpeed_dps: 45,
	rcsFactor: 1,
	new: func (subMode, radar = nil) {
		var mode = {parents: [F16LRSMode, F16RWSMode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		subMode.superMode = mode;
		subMode.shortName = mode.shortName;
		return mode;
	},
};


#  ███████ ███████  █████  
#  ██      ██      ██   ██ 
#  ███████ █████   ███████ 
#       ██ ██      ██   ██ 
#  ███████ ███████ ██   ██ 
#                          
#                          
var F16SeaMode = {
	rootName: "SEA",
	shortName: "AUTO",
	longName: "Sea Navigation Mode",
	discSpeed_dps: 55,
	maxRange: 80,
	range: 20,
	rcsFactor: 1,
	detectAIR: 0,
	detectSURFACE: 0,
	detectMARINE: 1,
	new: func (subMode, radar = nil) {
		var mode = {parents: [F16SeaMode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		subMode.superMode = mode;
		subMode.shortName = mode.shortName;
		return mode;
	},
	preStep: func {
		me.radar.tiltOverride = 1;
		me.radar.tilt = -12;# TODO: find info on this
		if (me.az == 60) {
			me.azimuthTilt = 0;
		} elsif (me.azimuthTilt > me.radar.fieldOfRegardMaxAz-me.az) {
			me.azimuthTilt = me.radar.fieldOfRegardMaxAz-me.az;
		} elsif (me.azimuthTilt < -me.radar.fieldOfRegardMaxAz+me.az) {
			me.azimuthTilt = -me.radar.fieldOfRegardMaxAz+me.az;
		}
	},
	cycleAZ: func {
		if (me.az == 10) me.az = 30;
		elsif (me.az == 30) {me.az = 60; me.azimuthTilt = 0;}
		elsif (me.az == 60) me.az = 10;
	},
	cycleBars: func {
	},
	showBars: func {
		return 0;
	},
	increaseRange: func {
		me._increaseRange();
	},
	decreaseRange: func {
		me._decreaseRange();
	},
	getSearchInfo: func (contact) {
		# searchInfo:               dist, groundtrack, deviations, speed, closing-rate, altitude
		return [1,0,1,0,0,1];
	},
	designate: func (designate_contact) {
		if (designate_contact == nil) return;
		me.radar.setCurrentMode(me.subMode, designate_contact);
		me.subMode.radar = me.radar;# find some smarter way of setting it.
	},
	designatePriority: func (contact) {
	},
	enterMode: func {
		me.radar.purgeAllBleps();
	},
};


#  ██    ██ ███████ ██████  
#  ██    ██ ██      ██   ██ 
#  ██    ██ ███████ ██████  
#   ██  ██       ██ ██   ██ 
#    ████   ███████ ██   ██ 
#                           
#                           
var F16VSMode = {
	shortName: "VSR",
	longName: "Velocity Search",
	discSpeed_dps: 45,
	discSpeed_alert_dps: 45,
	discSpeed_confirm_dps: 100,
	maxScanIntervalForVelocity: 6,
	rcsFactor: 1.1,
	new: func (subMode, radar = nil) {
		var mode = {parents: [F16VSMode, F16LRSMode, F16RWSMode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		subMode.superMode = mode;
		subMode.shortName = mode.shortName;
		return mode;
	},
	frameCompleted: func {
		if (me.discSpeed_dps == me.discSpeed_alert_dps) {
			me.discSpeed_dps = me.discSpeed_confirm_dps;
		} elsif (me.discSpeed_dps == me.discSpeed_confirm_dps) {
			me.discSpeed_dps = me.discSpeed_alert_dps;
		}
	},
	designate: func (designate_contact) {
		if (designate_contact == nil) return;
		me.radar.setCurrentMode(me.subMode, designate_contact);
		me.subMode.radar = me.radar;# find some smarter way of setting it.
		me.radar.registerBlep(designate_contact, designate_contact.getDeviationStored());
	},
	designatePriority: func {
		# NOP
	},
	undesignate: func {
		# NOP
	},
	preStep: func {
		me.radar.tiltOverride = 0;
		if (me.az == 60) {
			me.azimuthTilt = 0;
		} elsif (me.azimuthTilt > me.radar.fieldOfRegardMaxAz-me.az) {
			me.azimuthTilt = me.radar.fieldOfRegardMaxAz-me.az;
		} elsif (me.azimuthTilt < -me.radar.fieldOfRegardMaxAz+me.az) {
			me.azimuthTilt = -me.radar.fieldOfRegardMaxAz+me.az;
		}
	},
	increaseRange: func {
		me._increaseRange();
	},
	decreaseRange: func {
		me._decreaseRange();
	},
	getSearchInfo: func (contact) {
		# searchInfo:               dist, groundtrack, deviations, speed, closing-rate, altitude
		#print(me.currentTracked,"   ",(me.radar.elapsed - contact.blepTime));
		if (((me.radar.elapsed - contact.getLastBlepTime()) < me.maxScanIntervalForVelocity)) {
			#print("VELOCITY");
			return [0,0,1,1,1,0];
		}
		#print("  EMPTY");
		return [0,0,0,0,0,0];
	},
};




#
#                        Soft track Modes
#




#  ████████ ██     ██ ███████ 
#     ██    ██     ██ ██      
#     ██    ██  █  ██ ███████ 
#     ██    ██ ███ ██      ██ 
#     ██     ███ ███  ███████ 
#                             
#                             
var F16TWSMode = {
	radar: nil,
	shortName: "TWS",
	longName: "Track While Scan",
	superMode: nil,
	subMode: nil,
	maxRange: 80,
	discSpeed_dps: 50, # source: https://www.youtube.com/watch?v=Aq5HXTGUHGI
	rcsFactor: 0.9,
	timeToKeepBleps: 13,# TODO
	maxScanIntervalForTrack: 6.5,# authentic for TWS
	priorityTarget: nil,
	currentTracked: 0,
	maxTracked: 10,
	az: 25,# slow scan, so default is 25 to get those double taps in there.
	bars: 3,# default is less due to need 2 scans of target to get groundtrack
	new: func (subMode, radar = nil) {
		var mode = {parents: [F16TWSMode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		subMode.superMode = mode;
		subMode.shortName = mode.shortName;
		return mode;
	},
	cycleAZ: func {
		if (me.az == 10) me.az = 25;
		elsif (me.az == 25) {me.az = 60; me.azimuthTilt = 0;}
		elsif (me.az == 60) me.az = 10;
	},
	cycleBars: func {
		me.bars += 1;
		if (me.bars == 5) me.bars = 2;# bars:1 not available in TWS
		me.nextPatternNode = 0;
	},
	designate: func (designate_contact) {
		if (designate_contact != nil and designate_contact.equals(me.priorityTarget)) {
			me.radar.setCurrentMode(me.subMode, designate_contact);
			me.subMode.radar = me.radar;# find some smarter way of setting it.
		} else {
			print("cycle ",designate_contact.callsign," equals: ",designate_contact.equals(me.priorityTarget));
			me.priorityTarget = designate_contact;
		}
	},
	designatePriority: func (contact) {
		me.priorityTarget = contact;
		#if (contact != nil) me.azimuthTilt = contact.getDeviationHeadingFrozen();# incase we are not in 60 degs az lets us center az on priority.
	},
	getPriority: func {
		return me.priorityTarget;
	},
	undesignate: func {
		me.priorityTarget = nil;
	},
	preStep: func {
		if (me.priorityTarget != nil) {
			me.prioRange_nm = me.priorityTarget.getLastRangeDirect()*M2NM;
			if (me.radar.elapsed - me.priorityTarget.getLastBlepTime() > me.maxScanIntervalForTrack) {
				me.priorityTarget = nil;
				me.radar.tiltOverride = 0;
				me.undesignate();
				return;
			}
			me.lastDev = me.priorityTarget.getLastDirection();
			if (me.lastDev != nil) {
				me.azimuthTilt = me.lastDev[2]-self.getHeading();
				me.radar.tiltOverride = 1;
				me.radar.tilt = me.lastDev[3];
			} else {
				
				me.priorityTarget = nil;
				me.radar.tiltOverride = 0;
				me.undesignate();
				return;
			}
			if (me.prioRange_nm < 0.40 * me.getRange()) {
				me._decreaseRange();
			} elsif (me.prioRange_nm > 0.90 * me.getRange()) {
				me._increaseRange();
			} elsif (me.prioRange_nm < 3) {
				# auto go to STT when target is very close
				me.designate(me.priorityTarget);
			}
		} else {
			me.radar.tiltOverride = 0;
			me.undesignate();
		}
		if (me.az == 60) {
			me.azimuthTilt = 0;
		} elsif (me.azimuthTilt > me.radar.fieldOfRegardMaxAz-me.az) {
			me.azimuthTilt = me.radar.fieldOfRegardMaxAz-me.az;
		} elsif (me.azimuthTilt < -me.radar.fieldOfRegardMaxAz+me.az) {
			me.azimuthTilt = -me.radar.fieldOfRegardMaxAz+me.az;
		}
	},
	frameCompleted: func {
		# NOP
	},
	enterMode: func {
		me.currentTracked = 0;
		foreach(c;me.radar.vector_aicontacts_bleps) {
			c.ignoreTrackInfo();# Kind of a hack to make it give out false info. Bypasses hadTrackInfo() but not hasTrackInfo().
		}
	},
	leaveMode: func {
		me.priorityTarget = nil;
		me.lastFrameStart = -1;
		me.timeToKeepBleps=13;
	},
	increaseRange: func {
		if (me.priorityTarget != nil) return 0;
		me._increaseRange();
	},
	decreaseRange: func {
		if (me.priorityTarget != nil) return 0;
		me._decreaseRange();
	},
	getSearchInfo: func (contact) {
		# searchInfo:               dist, groundtrack, deviations, speed, closing-rate, altitude
		#print(me.currentTracked,"   ",(me.radar.elapsed - contact.blepTime));
		if (me.currentTracked < me.maxTracked and ((me.radar.elapsed - contact.getLastBlepTime()) < me.maxScanIntervalForTrack)) {
			#print("  TWICE    ",me.radar.elapsed);
			#print(me.radar.containsVectorContact(me.radar.vector_aicontacts_bleps, contact),"   ",me.radar.elapsed - contact.blepTime);			
			if (!contact.hadTrackInfo()) me.currentTracked += 1;
			return [1,1,1,1,0,1];
		} elsif (contact.hadTrackInfo()) {
			me.currentTracked -= 1;
			me.currentTracked=math.max(0,me.currentTracked);
		}
		#print("  ONCE    ",me.currentTracked);
		return [1,0,1,0,0,1];
	},
	prunedContact: func (c) {
		if (c.hadTrackInfo()) {
			me.currentTracked -= 1;
			me.currentTracked=math.max(0,me.currentTracked);
		}
	},
	testContact: func (contact) {
		#if (me.radar.elapsed - contact.getLastBlepTime() > me.maxScanIntervalForTrack and contact.azi == 1) {
		#	contact.azi = 0;
		#	me.currentTracked -= 1;
		#}
	},
	cycleDesignate: func {
		if (!size(me.radar.vector_aicontacts_bleps)) {
			me.priorityTarget = nil;
			return;
		}
		if (me.priorityTarget == nil) {
			me.testIndex = -1;
		} else {
			me.testIndex = me.radar.vectorIndex(me.radar.vector_aicontacts_bleps, me.priorityTarget);
		}
		for(me.i = me.testIndex+1;me.i<size(me.radar.vector_aicontacts_bleps);me.i+=1) {
			if (me.radar.vector_aicontacts_bleps[me.i].hadTrackInfo()) {
				me.priorityTarget = me.radar.vector_aicontacts_bleps[me.i];
				return;
			}
		}
		for(me.i = 0;me.i<=me.testIndex;me.i+=1) {
			if (me.radar.vector_aicontacts_bleps[me.i].hadTrackInfo()) {
				me.priorityTarget = me.radar.vector_aicontacts_bleps[me.i];
				return;
			}
		}
	},
};



#  ██      ██████  ███████       ███████  █████  ███    ███ 
#  ██      ██   ██ ██            ██      ██   ██ ████  ████ 
#  ██      ██████  ███████ █████ ███████ ███████ ██ ████ ██ 
#  ██      ██   ██      ██            ██ ██   ██ ██  ██  ██ 
#  ███████ ██   ██ ███████       ███████ ██   ██ ██      ██ 
#                                                           
#                                                           
var F16LRSSAMMode = {
	shortName: "LRS",
	longName: "Long Range Search - Situational Awareness Mode",
	discSpeed_dps: 45,
	rcsFactor: 1,
	new: func (subMode = nil, radar = nil) {
		var mode = {parents: [F16LRSSAMMode, F16RWSSAMMode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		if (subMode != nil) {
			subMode.superMode = mode;
			subMode.radar = radar;
			subMode.shortName = mode.shortName;
		}
		return mode;
	},
	calcSAMwidth: func {
		return math.min(60,18 + 1.5*me.prioRange_nm - 0.02222222*me.prioRange_nm*me.prioRange_nm);
	},
};





#  ██████  ██     ██ ███████       ███████  █████  ███    ███ 
#  ██   ██ ██     ██ ██            ██      ██   ██ ████  ████ 
#  ██████  ██  █  ██ ███████ █████ ███████ ███████ ██ ████ ██ 
#  ██   ██ ██ ███ ██      ██            ██ ██   ██ ██  ██  ██ 
#  ██   ██  ███ ███  ███████       ███████ ██   ██ ██      ██ 
#                                                             
#                                                             
var F16RWSSAMMode = {
	radar: nil,
	shortName: "RWS",
	longName: "Range While Search - Situational Awareness Mode",
	superMode: nil,
	discSpeed_dps: 65,
	rcsFactor: 0.9,
	maxRange: 160,
	priorityTarget: nil,
	bars: 2,
	new: func (subMode = nil, radar = nil) {
		var mode = {parents: [F16RWSSAMMode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		if (subMode != nil) {
			subMode.superMode = mode;
			subMode.radar = radar;
			subMode.shortName = mode.shortName;
		}
		return mode;
	},
	calcSAMwidth: func {
		return math.min(60,18 + 2.066667*me.prioRange_nm - 0.02222222*me.prioRange_nm*me.prioRange_nm);
	},
	preStep: func {
		if (me.priorityTarget != nil) {
			# azimuth width is autocalculated in F16 AUTO-SAM:
			me.prioRange_nm = me.priorityTarget.getRangeDirect()*M2NM;
			me.az = me.calcSAMwidth();
			if (!me.radar.containsVectorContact(me.radar.vector_aicontacts_bleps, me.priorityTarget)) {
				me.priorityTarget = nil;
				me.radar.tiltOverride = 0;
				me.undesignate();
				return;
			}
			me.lastDev = me.priorityTarget.getLastDirection();
			if (me.lastDev != nil) {
				me.azimuthTilt = me.lastDev[2]-self.getHeading();
				me.radar.tiltOverride = 1;
				me.radar.tilt = me.lastDev[3];
			} else {
				
				me.priorityTarget = nil;
				me.radar.tiltOverride = 0;
				me.undesignate();
				return;
			}
			if (me.prioRange_nm < 0.40 * me.getRange()) {
				me._decreaseRange();
			} elsif (me.prioRange_nm > 0.90 * me.getRange()) {
				me._increaseRange();
			} elsif (me.prioRange_nm < 3) {
				# auto go to STT when target is very close
				me.designate(me.priorityTarget);
			}
		} else {
			me.radar.tiltOverride = 0;
			me.undesignate();
		}
		if (me.az == 60) {
			me.azimuthTilt = 0;
		} elsif (me.azimuthTilt > me.radar.fieldOfRegardMaxAz-me.az) {
			me.azimuthTilt = me.radar.fieldOfRegardMaxAz-me.az;
		} elsif (me.azimuthTilt < -me.radar.fieldOfRegardMaxAz+me.az) {
			me.azimuthTilt = -me.radar.fieldOfRegardMaxAz+me.az;
		}
	},
	undesignate: func {
		me.priorityTarget = nil;
		me.radar.setCurrentMode(me.superMode, nil);
	},
	designate: func (designate_contact) {
		if (designate_contact == nil) return;
		me.radar.setCurrentMode(me.subMode, designate_contact);
		me.subMode.radar = me.radar;# find some smarter way of setting it.
	},
	designatePriority: func (contact) {
		me.priorityTarget = contact;
	},
	cycleBars: func {
		me.bars += 1;
		if (me.bars == 3) me.bars = 4;# 3 is only for TWS
		elsif (me.bars == 5) me.bars = 1;
		me.nextPatternNode = 0;
	},
	cycleAZ: func {},
	increaseRange: func {# Range is auto-set in RWS-SAM
	},
	decreaseRange: func {# Range is auto-set in RWS-SAM
	},
	setRange: func {# Range is auto-set in RWS-SAM
	},
	leaveMode: func {
		me.priorityTarget = nil;
		me.lastFrameStart = -1;
		me.timeToKeepBleps = 13;
	},
	getSearchInfo: func (contact) {
		# searchInfo:               dist, groundtrack, deviations, speed, closing-rate, altitude
		if (me.priorityTarget != nil and contact.equals(me.priorityTarget)) {
			return [1,1,1,1,0,1];
		}
		return [1,0,1,0,0,1];
	},
};



#   █████   ██████ ███    ███ 
#  ██   ██ ██      ████  ████ 
#  ███████ ██      ██ ████ ██ 
#  ██   ██ ██      ██  ██  ██ 
#  ██   ██  ██████ ██      ██ 
#                             
#                             


var F16ACMMode = {#TODO
	radar: nil,
	rootName: "ACM",
	shortName: "STBY",
	longName: "Air Combat Mode Standby",
	superMode: nil,
	subMode: nil,
	range: 10,
	maxRange: 10,
	discSpeed_dps: 84.6,
	rcsFactor: 0.9,
	timeToKeepBleps: 1,
	bars: 1,
	az: 1,
	new: func (subMode, radar = nil) {
		var mode = {parents: [F16ACMMode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		mode.subMode.superMode = mode;
		mode.subMode.shortName = mode.shortName;
		return mode;
	},
	showBars: func {
		return 0;
	},
	setDeviation: func (dev_tilt_deg) {
	},
	cycleAZ: func {	},
	cycleBars: func { },
	designate: func (designate_contact) {
	},
	designatePriority: func (contact) {

	},
	getPriority: func {
		return nil;
	},
	undesignate: func {
	},
	preStep: func {
	},
	increaseRange: func {
		return 0;
	},
	decreaseRange: func {
		return 0;
	},
	getSearchInfo: func (contact) {
		# searchInfo:               dist, groundtrack, deviations, speed, closing-rate, altitude
		return nil;
	},
	testContact: func (contact) {
	},
	cycleDesignate: func {
	},
};

var F16ACM20Mode = {
	radar: nil,
	rootName: "ACM",
	shortName: "20",
	longName: "Air Combat Mode 30x20",
	superMode: nil,
	subMode: nil,
	range: 10,
	maxRange: 10,
	discSpeed_dps: 84.6,
	rcsFactor: 0.9,
	timeToKeepBleps: 1,# TODO
	bars: 4,
	az: 15,
	new: func (subMode, radar = nil) {
		var mode = {parents: [F16ACM20Mode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		mode.subMode.superMode = mode;
		mode.subMode.shortName = mode.shortName;
		return mode;
	},
	showBars: func {
		return 0;
	},
	setDeviation: func (dev_tilt_deg) {
	},
	cycleAZ: func {	},
	cycleBars: func { },
	designate: func (designate_contact) {
		if (designate_contact == nil) return;
		me.radar.setCurrentMode(me.subMode, designate_contact);
		me.subMode.radar = me.radar;
	},
	designatePriority: func (contact) {
	},
	getPriority: func {
		return nil;
	},
	undesignate: func {
	},
	preStep: func {
		me.radar.horizonStabilized = 0;
		me.radar.tilt = -3;
		me.radar.tiltOverride = 1;
	},
	increaseRange: func {
		return 0;
	},
	decreaseRange: func {
		return 0;
	},
	getSearchInfo: func (contact) {
		# searchInfo:               dist, groundtrack, deviations, speed, closing-rate, altitude
		me.designate(contact);
		return [1,1,1,1,1,1];
	},
	testContact: func (contact) {
	},
	cycleDesignate: func {
	},
};

var F16ACM60Mode = {
	radar: nil,
	rootName: "ACM",
	shortName: "60",
	longName: "Air Combat Mode 10x60",
	superMode: nil,
	subMode: nil,
	maxRange: 10,
	discSpeed_dps: 84.6,
	rcsFactor: 0.9,
	bars: 1,
	barHeight: 1.0/3.9,# multiple of instantFoV (in this case 1 deg)
	az: 5,
	barPattern:  [ [[-0.6,-5],[0.0,-5],[0.0, 51],[0.6,51],[0.6,-5],[0.0,-5],[0.0,51],[-0.6,51]], ],
	new: func (subMode, radar = nil) {
		var mode = {parents: [F16ACM60Mode, F16ACM20Mode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		mode.subMode.superMode = mode;
		mode.subMode.shortName = mode.shortName;
		return mode;
	},
	preStep: func {
		me.radar.horizonStabilized = 0;
		me.radar.tilt = 0;
		me.radar.tiltOverride = 1;
	},
};

var F16ACMBoreMode = {
	radar: nil,
	rootName: "ACM",
	shortName: "BORE",
	longName: "Air Combat Mode Bore",
	bars: 1,
	barHeight: 1.0,# multiple of instantFoV (in this case 1 deg)
	az: 0,
	barPattern:  [ [[0.0,-1]], ],
	new: func (subMode, radar = nil) {
		var mode = {parents: [F16ACMBoreMode, F16ACM20Mode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		mode.subMode.superMode = mode;
		mode.subMode.shortName = mode.shortName;
		return mode;
	},
	preStep: func {
		me.radar.horizonStabilized = 0;
		me.radar.tilt = 0;
		me.radar.tiltOverride = 1;
	},
	step: func (dt, tilt) {
		me.preStep();
		# (re)calculate pattern as vectors.
		me.localDir = vector.Math.yawPitchVector(0, -me.radar.instantFoVradius, [1,0,0]);
		me.maxMove = math.min(me.radar.instantFoVradius, me.discSpeed_dps*dt);
		me.currentPos = me.radar.positionDirection;
		me.angleToNextNode = vector.Math.angleBetweenVectors(me.currentPos, me.localDir);
		if (me.angleToNextNode < me.maxMove) {
			me.radar.setAntennae(me.localDir);
			return 0;
		}
		me.newPos = vector.Math.rotateVectorTowardsVector(me.currentPos, me.localDir, me.maxMove);
		me.radar.setAntennae(me.newPos);
		return 0;
	},
};




#  ███████ ████████ ████████ 
#  ██         ██       ██    
#  ███████    ██       ██    
#       ██    ██       ██    
#  ███████    ██       ██    
#                            
#                            
var F16STTMode = {
	radar: nil,
	shortName: "STT",
	longName: "Single Target Track",
	superMode: nil,
	discSpeed_dps: 80,
	rcsFactor: 1,
	maxRange: 160,
	priorityTarget: nil,
	az: 3.5,
	bars: 2,
	minimumTimePerReturn: 0.15,
	timeToKeepBleps: 5,
	new: func (radar = nil) {
		var mode = {parents: [F16STTMode, RadarMode]};
		mode.radar = radar;
		return mode;
	},
	showAZ: func {
		return 0;
	},
	showBars: func {
		return me.superMode.showBars();
	},
	getBars: func {
		return me.superMode.getBars();
	},
	getAz: func {
		return me.superMode.getAz();
	},
	preStep: func {
		if (me.priorityTarget != nil) {
			me.lastDev = me.priorityTarget.getLastDirection();
			if (me.lastDev != nil) {
				me.azimuthTilt = me.lastDev[2]-self.getHeading();
				me.radar.tiltOverride = 1;
				me.radar.tilt = me.lastDev[3];
			} else {				
				me.priorityTarget = nil;
				me.radar.tiltOverride = 0;
				me.undesignate();
				return;
			}
			if (!me.radar.containsVectorContact(me.radar.vector_aicontacts_bleps, me.priorityTarget)) {
				me.priorityTarget = nil;
				me.radar.tiltOverride = 0;
				me.undesignate();
				return;
			} elsif (me.azimuthTilt > me.radar.fieldOfRegardMaxAz-me.az) {
				me.azimuthTilt = me.radar.fieldOfRegardMaxAz-me.az;
			} elsif (me.azimuthTilt < -me.radar.fieldOfRegardMaxAz+me.az) {
				me.azimuthTilt = -me.radar.fieldOfRegardMaxAz+me.az;
			}
			if (me.priorityTarget.getRangeDirect()*M2NM < 0.40 * me.getRange()) {
				me._decreaseRange();
			}
			if (me.priorityTarget.getRangeDirect()*M2NM > 0.90 * me.getRange()) {
				me._increaseRange();
			}
		} else {
			me.radar.tiltOverride = 0;
			me.undesignate();
		}
	},
	designatePriority: func (prio) {
		me.priorityTarget = prio;
	},
	undesignate: func {
		me.radar.setCurrentMode(me.superMode, me.priorityTarget);
		me.priorityTarget = nil;
		#var log = caller(1); foreach (l;log) print(l);
	},
	designate: func {},
	cycleBars: func {},
	cycleAZ: func {},
	increaseRange: func {# Range is auto-set in STT
	},
	decreaseRange: func {# Range is auto-set in STT
	},
	setRange: func {# Range is auto-set in STT
	},
	frameCompleted: func {
		# Don't calc this in this class
	},
	leaveMode: func {
		me.priorityTarget = nil;
		me.lastFrameStart = -1;
		me.timeToKeepBleps = 13;
	},
	getSearchInfo: func (contact) {
		# searchInfo:               dist, groundtrack, deviations, speed, closing-rate, altitude
		if (me.priorityTarget != nil and contact.equals(me.priorityTarget)) {
			return [1,1,1,1,1,1];
		}
		return nil;
	},
};

var F16ACMSTTMode = {
	rootName: "ACM",
	shortName: "STT",
	longName: "Air Combat Mode - Single Target Track",
	new: func (radar = nil) {
		var mode = {parents: [F16ACMSTTMode, F16STTMode, RadarMode]};
		mode.radar = radar;
		return mode;
	},
};

var F16FTTMode = {
	rootName: "SEA",
	shortName: "FTT",
	longName: "Sea Navigation Mode - Fixed Target Track",
	maxRange: 80,
	detectAIR: 0,
	detectSURFACE: 0,
	detectMARINE: 1,
	new: func (radar = nil) {
		var mode = {parents: [F16FTTMode, F16STTMode, RadarMode]};
		mode.radar = radar;
		return mode;
	},
};


var FOR_ROUND  = 0;# TODO: be able to ask noseradar for round field of regard.
var FOR_SQUARE = 1;
















#   █████  ██████   ██████         ██████   █████  
#  ██   ██ ██   ██ ██             ██       ██   ██ 
#  ███████ ██████  ██   ███ █████ ███████   █████  
#  ██   ██ ██      ██    ██       ██    ██ ██   ██ 
#  ██   ██ ██       ██████         ██████   █████  
#                                                  
#                                                  
var APG68 = {
	fieldOfRegardType: FOR_SQUARE,
	fieldOfRegardMaxAz: 60,
	fieldOfRegardMaxElev: 60,
	currentMode: nil, # vector of cascading modes ending with current submode
	currentModeIndex: 0,
	rootMode: 0,# 0: CRM  1: ACM
	mainModes: [[],[],[]],
	instantFoVradius: 3.90,#average of horiz/vert radius
	rcsRefDistance: 70,
	rcsRefValue: 3.2,
	framesToKeepBleps: 3,
	tilt: 0,
	tiltKnob: 0,
	tiltOverride: 0,# when enabled by a mode: the mode can set the tilt, and it will not be read from property (TODO)
	maxTilt: 60,#TODO: Lower this a bit
	positionEuler: [0,0,0,0],# euler direction
	positionDirection: [1,0,0],# vector direction
	positionCart: [0,0,0,0],
	horizonStabilized: 1, # When true antennae ignore roll (and pitch until its high)
	vector_aicontacts_for: [],# vector of contacts found in field of regard
	vector_aicontacts_bleps: [],# vector of not timed out bleps
	timer: nil,
	timerSlow: nil,
	elapsed: getprop("sim/time/elapsed-sec"),
	lastElapsed: getprop("sim/time/elapsed-sec"),
	new: func (crm_modes, acm_modes, sea_modes) {
		var rdr = {parents: [APG68, Radar]};

		rdr.mainModes[0] = crm_modes;
		rdr.mainModes[1] = acm_modes;
		rdr.mainModes[2] = sea_modes;
		
		foreach (mode ; crm_modes) {
			# this needs to be set on submodes also...hmmm
			mode.radar = rdr;
		}
		foreach (mode ; acm_modes) {
			# this needs to be set on submodes also...hmmm
			mode.radar = rdr;
		}
		foreach (mode ; sea_modes) {
			# this needs to be set on submodes also...hmmm
			mode.radar = rdr;
		}

		rdr.setCurrentMode(rdr.mainModes[0][0], nil);

		rdr.SliceNotification = SliceNotification.new();
		rdr.ContactNotification = VectorNotification.new("ContactNotification");
		rdr.ActiveDiscRadarRecipient = emesary.Recipient.new("ActiveDiscRadarRecipient");
		rdr.ActiveDiscRadarRecipient.radar = rdr;
		rdr.ActiveDiscRadarRecipient.Receive = func(notification) {
	        if (notification.NotificationType == "FORNotification") {
	        	#printf("DiscRadar recv: %s", notification.NotificationType);
	            if (rdr.enabled == 1) {
	    		    rdr.vector_aicontacts_for = notification.vector;
	    		    rdr.purgeBleps();
	    		    #print("size(rdr.vector_aicontacts_for)=",size(rdr.vector_aicontacts_for));
	    	    }
	            return emesary.Transmitter.ReceiptStatus_OK;
	        }
	        return emesary.Transmitter.ReceiptStatus_NotProcessed;
	    };
		emesary.GlobalTransmitter.Register(rdr.ActiveDiscRadarRecipient);
		rdr.timer = maketimer(scanInterval, rdr, func rdr.loop());
		rdr.timerSlow = maketimer(0.75, rdr, func rdr.loopSlow());
		rdr.timerSlow.start();
		rdr.timer.start();
    	return rdr;
	},
	setTilt: func (tiltKnob) {
		if(math.abs(tiltKnob) <= me.maxTilt) {
			me.tiltKnob = tiltKnob;
		}
	},
	getTilt: func {# TODO: rename to tiltKnob
		return me.tiltKnob;
	},
	increaseRange: func {
		me.currentMode.increaseRange();
	},
	decreaseRange: func {
		me.currentMode.decreaseRange();
	},
	designate: func (designate_contact) {
		me.currentMode.designate(designate_contact);
	},
	designateRandom: func {
		if (size(me.vector_aicontacts_bleps)>0) {
			if (me.currentMode.shortName != "TWS") {
				me.designate(me.vector_aicontacts_bleps[size(me.vector_aicontacts_bleps)-1]);
			} else {
				if (me.currentMode.priorityTarget != nil) me.designate(me.currentMode.priorityTarget);
				else {
					foreach(c;me.vector_aicontacts_bleps) {
						if (c.hadTrackInfo() and getprop("sim/time/elapsed-sec")-c.getLastBlepTime() < F16TWSMode.maxScanIntervalForTrack) {
							me.designate(c);
						}
					}
				}
			}
		}
	},
	undesignate: func {
		me.currentMode.undesignate();
	},
	getPriorityTarget: func {
		return me.currentMode.getPriority();
	},
	cycleDesignate: func {
		me.currentMode.cycleDesignate();
	},
	cycleMode: func {
		me.currentModeIndex += 1;
		if (me.currentModeIndex >= size(me.mainModes[me.rootMode])) {
			me.currentModeIndex = 0;
		}
		me.newMode = me.mainModes[me.rootMode][me.currentModeIndex];
		me.newMode.setRange(me.currentMode.getRange());
		me.oldMode = me.currentMode;
		me.setCurrentMode(me.newMode, me.oldMode["priorityTarget"]);
		me.oldMode.leaveMode();
	},
	cycleRootMode: func {
		me.rootMode += 1;
		if (me.rootMode >= size(me.mainModes)) {
			me.rootMode = 0;
		}
		me.currentModeIndex = 0;
		me.newMode = me.mainModes[me.rootMode][me.currentModeIndex];
		#me.newMode.setRange(me.currentMode.getRange());
		me.oldMode = me.currentMode;
		me.setCurrentMode(me.newMode, me.oldMode["priorityTarget"]);
		me.oldMode.leaveMode();
	},
	cycleAZ: func {
		me.currentMode.cycleAZ();
	},
	showAZ: func {
		me.currentMode.showAZ();
	},
	cycleBars: func {
		me.currentMode.cycleBars();
	},
	setDeviation: func (dev_tilt_deg) {
		if (me.getAzimuthRadius() == me.fieldOfRegardMaxAz) {
			dev_tilt_deg = 0;
		}
		me.currentMode.setDeviation(dev_tilt_deg);
	},
	getDeviation: func {
		return me.currentMode.getDeviation();
	},
	getBars: func {
		return me.currentMode.getBars();
	},
	getAzimuthRadius: func {
		return me.currentMode.getAz();
	},
	getMode: func {
		return me.currentMode.shortName;
	},
	setCurrentMode: func (new_mode, priority = nil) {
		me.currentMode = new_mode;
		new_mode.radar = me;
		new_mode.designatePriority(priority);
		new_mode.enterMode();
	},
	getRange: func {
		return me.currentMode.getRange();
	},
	setAntennae: func (local_dir) {
		# remember to set horizonStabilized when calling this.
		me.eulerDir = vector.Math.cartesianToEuler(local_dir);
		me.eulerX = me.eulerDir[0]==nil?0:geo.normdeg180(me.eulerDir[0]);
		me.positionEuler = [me.eulerX,me.eulerDir[1],me.eulerX/me.fieldOfRegardMaxAz,me.eulerDir[1]/me.fieldOfRegardMaxElev];
		me.positionDirection = vector.Math.normalize(local_dir);
		me.posAZDeg = -90+R2D*math.acos(vector.Math.normalize(vector.Math.projVectorOnPlane([0,0,1],me.positionDirection))[1]);
		me.posElDeg = R2D*math.asin(vector.Math.normalize(vector.Math.projVectorOnPlane([0,1,0],me.positionDirection))[2]);
		me.positionCart = [me.posAZDeg/me.fieldOfRegardMaxAz, me.posElDeg/me.fieldOfRegardMaxElev,me.posAZDeg,me.posElDeg];
		#print("On sky: ",me.eulerDir[1], "  disc: ",me.posElDeg);
	},
	loop: func {
		if (me.enabled) {
			me.elapsed = getprop("sim/time/elapsed-sec");
			me.dt = me.elapsed - me.lastElapsed;
			me.lastElapsed = me.elapsed;
			if (!me.tiltOverride) {
				me.tilt = me.tiltKnob;
			}
			while (me.dt > 0) {
				# mode tells us how to move disc and to scan
				me.dt = me.currentMode.step(me.dt, me.tilt);# mode already knows where in pattern we are and AZ and bars.
				# we then step to the new position, and scan for each step
				me.scanFOV();
			}
		}
	},
	loopSlow: func {
		if (me.enabled) {
			emesary.GlobalTransmitter.NotifyAll(me.SliceNotification.slice(self.getPitch(), self.getHeading(), me.fieldOfRegardMaxElev, me.fieldOfRegardMaxAz, me.getRange()*NM2M, !me.currentMode.detectAIR, !me.currentMode.detectSURFACE, !me.currentMode.detectMARINE));
		}
	},
	scanFOV: func {
		foreach(contact ; me.vector_aicontacts_for) {
			if (me.elapsed - contact.getLastBlepTime() < me.currentMode.minimumTimePerReturn) continue;# To prevent double detecting in overlapping beams

			me.dev = contact.getDeviationStored();
			#print("Bearing ",me.dev[7],", Pitch ",me.dev[8]);
			if (me.horizonStabilized) {
				# ignore roll (and ignore pitch for now too, TODO)
				me.globalToTarget = vector.Math.eulerToCartesian3X(-me.dev[7],me.dev[8],0);
				me.localToTarget = vector.Math.rollPitchYawVector(0,0,self.getHeading(), me.globalToTarget);
			} else {
				me.localToTarget = vector.Math.eulerToCartesian3X(-me.dev[0],me.dev[1],0);
			}
			#print("ANT head ",me.positionX,", ANT elev ",me.positionY,", ANT tilt ", me.tilt);
			#print(vector.Math.format(me.localToTarget));
			me.beamDeviation = vector.Math.angleBetweenVectors(me.positionDirection, me.localToTarget);
			#print("me.beamDeviation ", me.beamDeviation);
			if (me.beamDeviation < me.instantFoVradius) {
				me.registerBlep(contact, me.dev);
				#print("REGISTER BLEP");

				# Return here, so that each instant FoV max gets 1 target:
				return;
			}
		}
	},
	registerBlep: func (contact, dev, doppler_check = 1) {
		if (!contact.isVisible()) return 0;
		if (doppler_check and contact.isHiddenFromDoppler()) return 0;
		me.maxDistVisible = me.currentMode.rcsFactor * me.targetRCSSignal(self.getCoord(), dev[3], contact.model, contact.getHeadingFrozen(1), contact.getPitchFrozen(1), contact.getRollFrozen(1),me.rcsRefDistance*NM2M,me.rcsRefValue);

		if (me.maxDistVisible > dev[2]) {
			me.extInfo = me.currentMode.getSearchInfo(contact);# if the scan gives heading info etc..
			if (me.extInfo == nil) {
				return 0;
			}
			contact.blep(me.elapsed, me.extInfo, me.maxDistVisible);
			if (!me.containsVectorContact(me.vector_aicontacts_bleps, contact)) {
				append(me.vector_aicontacts_bleps, contact);
			}
			return 1;
		}
		return 0;
	},
	purgeBleps: func {
		#ok, lets clean up old bleps:
		me.vector_aicontacts_bleps_tmp = [];
		me.elapsed = getprop("sim/time/elapsed-sec");
		foreach(contact ; me.vector_aicontacts_bleps) {
			me.bleps_cleaned = [];
			foreach (me.blep;contact.getBleps()) {
				if (me.elapsed - me.blep[0] < me.currentMode.timeToKeepBleps) {
					append(me.bleps_cleaned, me.blep);
				}	
			}
			contact.setBleps(me.bleps_cleaned);
			if (size(me.bleps_cleaned)) {
				append(me.vector_aicontacts_bleps_tmp, contact);
				me.currentMode.testContact(contact);# TODO: do this smarter
			} else {
				me.currentMode.prunedContact(contact);
			}
		}
		#print("Purged ", size(me.vector_aicontacts_bleps) - size(me.vector_aicontacts_bleps_tmp), " bleps   remains:",size(me.vector_aicontacts_bleps_tmp), " orig ",size(me.vector_aicontacts_bleps));
		me.vector_aicontacts_bleps = me.vector_aicontacts_bleps_tmp;
	},
	purgeAllBleps: func {
		#ok, lets clean up old bleps:
		foreach(contact ; me.vector_aicontacts_bleps) {
			contact.setBleps([]);
		}
		me.vector_aicontacts_bleps = [];
	},
	targetRCSSignal: func(aircraftCoord, targetCoord, targetModel, targetHeading, targetPitch, targetRoll, myRadarDistance_m = 74000, myRadarStrength_rcs = 3.2) {
		#
		# test method. Belongs in rcs.nas.
		#
	    #print(targetModel);
	    me.target_front_rcs = nil;
	    if ( contains(rcs.rcs_database,targetModel) ) {
	        me.target_front_rcs = rcs.rcs_database[targetModel];
	    } else {
	        #return 1;
	        me.target_front_rcs = 5;#rcs.rcs_database["default"];# hardcode defaults to 5 to test with KXTA target scenario. TODO: change.
	    }
	    me.target_rcs = rcs.getRCS(targetCoord, targetHeading, targetPitch, targetRoll, aircraftCoord, me.target_front_rcs);

	    # standard formula
	    return myRadarDistance_m/math.pow(myRadarStrength_rcs/me.target_rcs, 1/4);
	},
	
	containsVector: func (vec, item) {
		foreach(test; vec) {
			if (test == item) {
				return TRUE;
			}
		}
		return FALSE;
	},

	containsVectorContact: func (vec, item) {
		foreach(test; vec) {
			if (test.equals(item)) {
				return 1;
			}
		}
		return 0;
	},

	vectorIndex: func (vec, item) {
		me.i = 0;
		foreach(test; vec) {
			if (test == item) {
				return me.i;
			}
			me.i += 1;
		}
		return -1;
	},
	del: func {
        emesary.GlobalTransmitter.DeRegister(me.ActiveDiscRadarRecipient);
    },
};

var scanInterval = 0.05;
var rwsMode = F16RWSMode.new(F16RWSSAMMode.new(F16STTMode.new()));
var twsMode = F16TWSMode.new(F16STTMode.new());
var lrsMode = F16LRSMode.new(F16LRSSAMMode.new(F16STTMode.new()));
var vsrMode = F16VSMode.new(F16STTMode.new()); 
var acm20Mode = F16ACM20Mode.new(F16ACMSTTMode.new());
var acm60Mode = F16ACM60Mode.new(F16ACMSTTMode.new());
var acmBoreMode = F16ACMBoreMode.new(F16ACMSTTMode.new());
var seaMode = F16SeaMode.new(F16FTTMode.new()); 
var exampleRadar = APG68.new([rwsMode,twsMode,lrsMode,vsrMode],[acm20Mode,acm60Mode,acmBoreMode],[seaMode]);











































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
		me.geoVector = vector.Math.vectorToGeoVector(me.beamVectorFix, self.getCoord());
		return me.geoVector;
	},
	
	testForDistance: func {
		if (me.enabled) {
			me.selfPos = self.getCoord();
			me.pick = get_cart_ground_intersection({"x":me.selfPos.x(), "y":me.selfPos.y(), "z":me.selfPos.z()}, me.computeBeamVector());
	      	if (me.pick != nil) {
	  			me.terrain = geo.Coord.new();
				me.terrain.set_latlon(me.pick.lat, me.pick.lon, me.pick.elevation);
				me.terrainDist_m = me.selfPos.direct_distance_to(me.terrain);
				
				# test code:
				#geo.put_model("Aircraft/JA37/Models/Instruments/Radio/radio.ac", me.computeBeamVector()[1].lat(), me.computeBeamVector()[1].lon(),me.computeBeamVector()[1].alt());
				
				return me.terrainDist_m;
	  		}
	  	}
	  	return nil;
	},
};

var RWR = {
# inherits from Radar
# will check radar/transponder and ground occlusion.
# will sort according to threat level
# will detect launches (MLW) or (active) incoming missiles (MAW)
# loop (0.5 sec)
	new: func () {
		var rr = {parents: [RWR, Radar]};

		rr.vector_aicontacts = [];
		rr.vector_aicontacts_threats = [];
		#rr.timer          = maketimer(2, rr, func rr.scan());

		rr.RWRRecipient = emesary.Recipient.new("RWRRecipient");
		rr.RWRRecipient.radar = rr;
		rr.RWRRecipient.Receive = func(notification) {
	        if (notification.NotificationType == "OmniNotification") {
	        	#printf("RWR recv: %s", notification.NotificationType);
	            if (me.radar.enabled == 1) {
	    		    me.radar.vector_aicontacts = notification.vector;
	    		    me.radar.scan();
	    	    }
	            return emesary.Transmitter.ReceiptStatus_OK;
	        }
	        return emesary.Transmitter.ReceiptStatus_NotProcessed;
	    };
		emesary.GlobalTransmitter.Register(rr.RWRRecipient);
		#nr.FORNotification = VectorNotification.new("FORNotification");
		#nr.FORNotification.updateV(nr.vector_aicontacts_for);
		#rr.timer.start();
		return rr;
	},

	scan: func {
		# sort in threat?
		# run by notification
		# mock up code, ultra simple threat index, is just here cause rwr have special needs:
		# 1) It has almost no range restriction
		# 2) Its omnidirectional
		# 3) It might have to update fast (like 0.25 secs)
		# 4) To build a proper threat index it needs at least these properties read:
		#       model type
		#       class (AIR/SURFACE/MARINE)
		#       lock on myself
		#       missile launch
		#       transponder on/off
		#       bearing and heading
		#       IFF info
		#       ECM
		#       radar on/off
		me.vector_aicontacts_threats = [];
		foreach(contact ; me.vector_aicontacts) {
			me.t = contact.getThreatStored();#[bearing,heading,coord,transponder,radar,devBearing,dist_nm]
			#me.threatInv = contact.getRangeDirect()*M2NM;
			#me.threatInv = 55-contact.getSpeed()*0.1;
			me.threatInv = me.t[6];# this is not serious, just testing code
			append(me.vector_aicontacts_threats, [contact,me.threatInv]);# how about a setThreat on contact instead of this crap?
		}
	},
	del: func {
        emesary.GlobalTransmitter.DeRegister(me.RWRRecipient);
    },
};



###LinkRadar:
# inherits from Radar, represents a fighter-link/link16.
# Get contact name from other aircraft, and finds local RadarControl for it.
# no loop. emesary listener on aircraft for link.
#
# Attributes:
#   contact selection(s) of type LinkContact
#   imaginary hard/soft lock
#   link list of contacts of type LinkContact






#troubles:
# rescan of ai tree, how to equal same aircraft with new name (COMPARE: callsign, sign, name, model-name)
# doppler only in a2a mode
# 

# TODO: tons of features and tons of different designs to try. Like scanning a 360 azimuth without reversing direction when bar finished.




























#############################
# test code below this line #
#############################





var enable = 1;
var enableRWR = 1;
var enableRWRs = 1;




var clamp = func(v, min, max) { v < min ? min : v > max ? max : v }










#  ██████  ██████  ██ 
#  ██   ██ ██   ██ ██ 
#  ██████  ██████  ██ 
#  ██      ██      ██ 
#  ██      ██      ██ 
#                     
#                     
RadarViewPPI = {
# implements radar/RWR display on CRT/MFD
# also slew cursor to select contacts.
# fast loop
#
# Attributes:
#   link to Radar
#   link to FireControl
	new: func {
		me.window = canvas.Window.new([256, 256],"dialog")
				.set('x', 256)
				#.set('y', 350)
                .set('title', "Radar PPI");
		var root = me.window.getCanvas(1).createGroup();
		me.window.getCanvas(1).setColorBackground(0,0,0);
		me.rootCenter = root.createChild("group")
				.setTranslation(128,256);
		me.rootCenterBleps = root.createChild("group")
				.setTranslation(128,256);
		me.sweepDistance = 128/math.cos(30*D2R);
		me.sweep = me.rootCenter.createChild("path")
				.moveTo(0,0)
				.vert(-me.sweepDistance)
				.setStrokeLineWidth(2.5)
				.setColor(1,1,1);
		me.sweepA = me.rootCenter.createChild("path")
				.moveTo(0,0)
				.vert(-me.sweepDistance)
				.setStrokeLineWidth(1)
				.setColor(0.5,0.5,1);
		me.sweepB = me.rootCenter.createChild("path")
				.moveTo(0,0)
				.vert(-me.sweepDistance)
				.setStrokeLineWidth(1)
				.setColor(0.5,0.5,1);
		me.text = root.createChild("text")
	      .setAlignment("left-top")
      	  .setFontSize(10, 1.0)
	      .setColor(1, 1, 1);
	    me.text2 = root.createChild("text")
	      .setAlignment("left-top")
      	  .setFontSize(10, 1.0)
      	  .setTranslation(0,15)
	      .setColor(1, 1, 1);
	    me.text3 = root.createChild("text")
	      .setAlignment("left-top")
      	  .setFontSize(10, 1.0)
      	  .setTranslation(0,30)
	      .setColor(1, 1, 1);
	    me.text4 = root.createChild("text")
	      .setAlignment("left-top")
      	  .setFontSize(10, 1.0)
      	  .setTranslation(0,45)
	      .setColor(1, 1, 1);

	    me.blep = setsize([],200);
        for (var i = 0;i<200;i+=1) {
        	me.blep[i] = me.rootCenterBleps.createChild("path")
					.moveTo(0,0)
					.vert(2)
					.setStrokeLineWidth(2)
	      	  		.hide();
        }
        me.lock = setsize([],20);
        for (var i = 0;i<20;i+=1) {
        	me.lock[i] = me.rootCenterBleps.createChild("path")
						.moveTo(-5,-5)
							.vert(10)
							.horiz(10)
							.vert(-10)
							.horiz(-10)
							.moveTo(0,-5)
							.vert(-5)
							.setStrokeLineWidth(1)
	      	  		.hide();
        }
        	me.select = me.rootCenterBleps.createChild("path")
						.moveTo(-8, 0)
			            .arcSmallCW(8, 8, 0, 8*2, 0)
			            .arcSmallCW(8, 8, 0, -8*2, 0)
						.setColor([1,1,0])
						.setStrokeLineWidth(1)
	      	  		.hide();

		var mt = maketimer(scanInterval,func me.loop());
        mt.start();
		return me;
	},

	loop: func {
		if (!enable) {return;}
		me.sweep.setRotation(exampleRadar.positionCart[2]*D2R);
		me.sweep.update();
		if (exampleRadar.showAZ()) {
			me.sweepA.show();
			me.sweepB.show();
			me.sweepA.setRotation((exampleRadar.currentMode.azimuthTilt-exampleRadar.currentMode.az)*D2R);
			me.sweepB.setRotation((exampleRadar.currentMode.azimuthTilt+exampleRadar.currentMode.az)*D2R);
		} else {
			me.sweepA.hide();
			me.sweepB.hide();
		}
		me.elapsed = getprop("sim/time/elapsed-sec");
		#me.rootCenterBleps.removeAllChildren();
		me.i = 0;
		me.bug = 0;
		me.track = 0;
		me.ii = 0;
		foreach(contact; exampleRadar.vector_aicontacts_bleps) {
			foreach(me.bleppy; contact.getBleps()) {
				# blep: time, rcs_strength, dist, heading, deviations vector, speed, closing-rate, altitude
				if (me.elapsed - me.bleppy[0] < exampleRadar.currentMode.timeToKeepBleps and (me.bleppy[2] != nil or (me.bleppy[6] != nil and me.bleppy[6]>0))) {
					if (me.bleppy[6] != nil and exampleRadar.currentMode.longName == "Velocity Search") {
						me.distPixels = me.bleppy[6]*(me.sweepDistance/(1000));
					} elsif (me.bleppy[2] != nil) {
						me.distPixels = me.bleppy[2]*(me.sweepDistance/(exampleRadar.getRange()*NM2M));
					} else {
						continue;
					}
					
					me.color = math.pow(1-(me.elapsed - me.bleppy[0])/exampleRadar.currentMode.timeToKeepBleps, 2.2);
					me.blep[me.i].setColor(me.color,me.color,me.color);
					me.blep[me.i].setTranslation(-me.distPixels*math.cos(me.bleppy[4][0]*D2R+math.pi/2),-me.distPixels*math.sin(me.bleppy[4][0]*D2R+math.pi/2));
					me.blep[me.i].show();
					me.blep[me.i].update();
					me.i += 1;
					if (me.i > 199) break;
				}
			}
			me.sizeBleps = size(contact.getBleps());
			if (me.sizeBleps and me.ii < 20 and contact.hadTrackInfo()) {
				me.bleppy = contact.getBleps()[me.sizeBleps-1];
				if (me.bleppy[3] != nil) {
					me.rot = me.bleppy[3];
					me.rot = me.rot-self.getHeading();
					me.lock[me.ii].setRotation(me.rot*D2R);
					me.lock[me.ii].setColor([1,1,0]);
					me.lock[me.ii].setTranslation(-me.distPixels*math.cos(me.bleppy[4][0]*D2R+math.pi/2),-me.distPixels*math.sin(me.bleppy[4][0]*D2R+math.pi/2));
					me.lock[me.ii].show();
					me.lock[me.ii].update();
					me.ii += 1;
				}
			}
			if (contact.equals(exampleRadar.getPriorityTarget()) and me.sizeBleps) {
				me.bleppy = contact.getBleps()[me.sizeBleps-1];
				me.select.setTranslation(-me.distPixels*math.cos(me.bleppy[4][0]*D2R+math.pi/2),-me.distPixels*math.sin(me.bleppy[4][0]*D2R+math.pi/2));
				me.select.show();
				me.select.update();
				me.bug = 1;
			}
			if (me.i > 199) break;
		}
		for (;me.i<200;me.i+=1) {
			me.blep[me.i].hide();
		}
		for (;me.ii<20;me.ii+=1) {
			me.lock[me.ii].hide();
		}
		if (!me.bug) me.select.hide();
		if (exampleRadar.tiltOverride) {
			me.text.setText("Antennae elevation knob override");
		} else {
			me.text.setText(sprintf("Antennae elevation knob: %d degs", exampleRadar.getTilt()));
		}
		me.md = exampleRadar.currentMode.longName;
		me.text2.setText(me.md);
		me.prioName = exampleRadar.getPriorityTarget();
		if (me.prioName != nil) {
			me.text3.setText(sprintf("Priority: %s", me.prioName.callsign));
			if (me.prioName.getLastRangeDirect() != nil and me.prioName.getLastAltitude() != nil) {
				me.text4.setText(sprintf("Range: %2d  Angels: %2d", me.prioName.getLastRangeDirect()*M2NM, math.round(me.prioName.getLastAltitude()*0.001)));
			}
		} else {
			me.text3.setText("");
			me.text4.setText("");
		}
	},
	del: func {
		me.window.del();
        #emesary.GlobalTransmitter.DeRegister(f16_hmd);
    },
};


#  ██████        ███████  ██████  ██████  ██████  ███████ 
#  ██   ██       ██      ██      ██    ██ ██   ██ ██      
#  ██████  █████ ███████ ██      ██    ██ ██████  █████   
#  ██   ██            ██ ██      ██    ██ ██      ██      
#  ██████        ███████  ██████  ██████  ██      ███████ 
#                                                         
#                                                         
RadarViewBScope = {
# implements radar/RWR display on CRT/MFD
# also slew cursor to select contacts.
# fast loop
#
# Attributes:
#   link to Radar
#   link to FireControl
	new: func {
		me.window = canvas.Window.new([256, 256],"dialog")
				.set('x', 550)
                .set('title', "Radar B-Scope");
		var root = me.window.getCanvas(1).createGroup();
		me.window.getCanvas(1).setColorBackground(0,0,0);
		me.rootCenter = root.createChild("group")
				.setTranslation(128,256);
		me.rootCenterBleps = root.createChild("group")
				.setTranslation(128,256);
		me.sweepAz = me.rootCenter.createChild("path")
				.moveTo(0,0)
				.vert(-10)
				.moveTo(-5,-10)
				.horiz(10)
				.setStrokeLineWidth(2.5)
				.setColor(1,1,1);
		me.sweepBa = me.rootCenter.createChild("path")
				.moveTo(-128,-128)
				.horiz(10)
				.moveTo(-118,-123)
				.vert(-10)
				.setStrokeLineWidth(2.5)
				.setColor(1,1,1);
		me.sweepA = me.rootCenter.createChild("path")
				.moveTo(0,0)
				.vert(-256)
				.setStrokeLineWidth(1)
				.setColor(0.5,0.5,1);
		me.sweepB = me.rootCenter.createChild("path")
				.moveTo(0,0)
				.vert(-256)
				.setStrokeLineWidth(1)
				.setColor(0.5,0.5,1);
		
	    me.r = root.createChild("text")
	      .setAlignment("left-center")
      	  .setFontSize(10, 1.0)
      	  .setTranslation(10,50)
	      .setColor(1, 1, 1);
	    me.b = root.createChild("text")
	      .setAlignment("left-center")
      	  .setFontSize(10, 1.0)
      	  .setTranslation(10,100)
	      .setColor(1, 1, 1);
	    me.a = root.createChild("text")
	      .setAlignment("left-center")
      	  .setFontSize(10, 1.0)
      	  .setTranslation(10,150)
	      .setColor(1, 1, 1);
	    me.rootName = root.createChild("text")
	      .setAlignment("center-top")
      	  .setFontSize(10, 1.0)
      	  .setTranslation(1*256/6,10)
	      .setColor(1, 1, 1);
	    me.shortName = root.createChild("text")
	      .setAlignment("center-top")
      	  .setFontSize(10, 1.0)
      	  .setTranslation(2*256/6,10)
	      .setColor(1, 1, 1);

	    me.blep = setsize([],200);
        for (var i = 0;i<200;i+=1) {
        	me.blep[i] = me.rootCenterBleps.createChild("path")
					.moveTo(0,0)
					.vert(2)
					.setStrokeLineWidth(2)
	      	  		.hide();
        }
        me.lock = setsize([],20);
        me.lockv = setsize([],20);
        me.lockvl = setsize([],20);
        me.lockt = setsize([],20);
        me.locky = setsize([],20);
        for (var i = 0;i<20;i+=1) {
        	me.lock[i] = me.rootCenterBleps.createChild("group");
        	me.locky[i] = me.lock[i].createChild("path")
							.moveTo(-7,4)
							.horiz(14)
							.lineTo(0,-8)
							.lineTo(-7,4)
							.setStrokeLineWidth(1)
							.setColor([1,1,0]);
			me.lockv[i] = me.lock[i].createChild("group");
			me.lockvl[i] = me.lockv[i].createChild("path")
							.lineTo(0,-10)
							.setTranslation(0,-8)
							.setStrokeLineWidth(1)
							.setColor([1,1,0]);
			me.lockt[i] = me.lock[i].createChild("text")
							      .setAlignment("center-top")
						      	  .setFontSize(10, 1.0)
						      	  .setTranslation(0,10)
							      .setColor(1, 1, 1);
        }
        me.select = me.rootCenterBleps.createChild("path")
						.moveTo(-8, 0)
			            .arcSmallCW(8, 8, 0, 8*2, 0)
			            .arcSmallCW(8, 8, 0, -8*2, 0)
						.setColor([1,1,0])
						.setStrokeLineWidth(1);

		var mt = maketimer(scanInterval,func me.loop());
        mt.start();
		return me;
	},

	loop: func {
		if (!enable) {return;}
		me.sweepAz.setTranslation(128*exampleRadar.positionCart[0],0);
		me.sweepBa.setTranslation(0,-128*exampleRadar.positionCart[1]);
		me.sweepAz.update();
		me.sweepBa.update();
		if (exampleRadar.showAZ()) {
			me.sweepA.show();
			me.sweepB.show();
			me.sweepA.setTranslation(128*(exampleRadar.currentMode.azimuthTilt-exampleRadar.currentMode.az)/60,0);
			me.sweepB.setTranslation(128*(exampleRadar.currentMode.azimuthTilt+exampleRadar.currentMode.az)/60,0);
		} else {
			me.sweepA.hide();
			me.sweepB.hide();
		}
		me.elapsed = getprop("sim/time/elapsed-sec");
		me.i = 0;
		me.bug = 0;
		me.track = 0;
		me.ii = 0;
		foreach(contact; exampleRadar.vector_aicontacts_bleps) {
			foreach(me.bleppy; contact.getBleps()) {
				# blep: time, rcs_strength, dist, heading, deviations vector, speed, closing-rate, altitude
				if (me.elapsed - me.bleppy[0] < exampleRadar.currentMode.timeToKeepBleps and (me.bleppy[2] != nil or (me.bleppy[6] != nil and me.bleppy[6]>0))) {
					if (me.bleppy[6] != nil and exampleRadar.currentMode.longName == "Velocity Search") {
						me.distPixels = me.bleppy[6]*(256/(1000));
					} elsif (me.bleppy[2] != nil) {
						me.distPixels = me.bleppy[2]*(256/(exampleRadar.getRange()*NM2M));
					} else {
						continue;
					}
					me.color = math.pow(1-(me.elapsed - me.bleppy[0])/exampleRadar.currentMode.timeToKeepBleps, 2.2);
					me.blep[me.i].setColor(me.color,me.color,me.color);
					me.blep[me.i].setTranslation(128*me.bleppy[4][0]/60,-me.distPixels);
					me.blep[me.i].show();
					me.blep[me.i].update();
					me.i += 1;
					if (me.i > 199) break;
				}
			}
			me.sizeBleps = size(contact.getBleps());
			if (me.sizeBleps and me.ii < 20 and contact.hadTrackInfo()) {
				me.bleppy = contact.getBleps()[me.sizeBleps-1];
				if (me.bleppy[3] != nil and me.elapsed - me.bleppy[0] < exampleRadar.currentMode.timeToKeepBleps) {
					me.rot = 22.5*math.round((me.bleppy[3]-self.getHeading()-me.bleppy[4][0])/22.5);
					me.locky[me.ii].setRotation(me.rot*D2R);
					me.lock[me.ii].setTranslation(128*me.bleppy[4][0]/60,-me.distPixels);
					if (me.bleppy[5] != nil and me.bleppy[5] > 0) {
						me.lockvl[me.ii].setScale(1,me.bleppy[5]*0.0025);
						me.lockv[me.ii].setRotation(me.rot*D2R);
						me.lockv[me.ii].update();
						me.lockv[me.ii].show();
					} else {
						me.lockv[me.ii].hide();
					}
					if (me.bleppy[7] != nil) {
						me.lockt[me.ii].setText(""~math.round(me.bleppy[7]*0.001));
					} else {
						me.lockt[me.ii].setText("");
					}
					me.lock[me.ii].setVisible(exampleRadar.currentMode.longName != "Track While Scan" or (me.elapsed - me.bleppy[0] < exampleRadar.currentMode.maxScanIntervalForTrack) or (math.mod(me.elapsed,0.50)<0.25));
					me.lock[me.ii].update();
					me.ii += 1;
				}
			}
			if (contact.equals(exampleRadar.getPriorityTarget()) and me.sizeBleps) {
				me.bleppy = contact.getBleps()[me.sizeBleps-1];
				me.select.setTranslation(128*me.bleppy[4][0]/60,-me.distPixels);
				me.select.show();
				me.select.update();
				me.bug = 1;
			}
			if (me.i > 199) break;
		}
		for (;me.i<200;me.i+=1) {
			me.blep[me.i].hide();
		}
		for (;me.ii<20;me.ii+=1) {
			me.lock[me.ii].hide();
		}
		if (!me.bug) me.select.hide();
		
		var a = 0;
		if (exampleRadar.getAzimuthRadius() < 20) {
			a = 1;
		} elsif (exampleRadar.getAzimuthRadius() < 30) {
			a = 2;
		} elsif (exampleRadar.getAzimuthRadius() < 40) {
			a = 3;
		} elsif (exampleRadar.getAzimuthRadius() < 50) {
			a = 4;
		} elsif (exampleRadar.getAzimuthRadius() < 60) {
			a = 5;
		} elsif (exampleRadar.getAzimuthRadius() < 70) {
			a = 6;
		}
		if (exampleRadar.currentMode.showBars()) {
			var b = exampleRadar.getBars();
			me.b.setText("B"~b);
		} else {
			me.b.setText("");
		}
		me.a.setText("A"~a);
		me.r.setText(""~exampleRadar.getRange());
		me.rootName.setText(exampleRadar.currentMode.rootName);
		me.shortName.setText(exampleRadar.currentMode.shortName);
	},
	del: func {
		me.window.del();
        #emesary.GlobalTransmitter.DeRegister(f16_hmd);
    },
};


#   ██████       ███████  ██████  ██████  ██████  ███████ 
#  ██            ██      ██      ██    ██ ██   ██ ██      
#  ██      █████ ███████ ██      ██    ██ ██████  █████   
#  ██                 ██ ██      ██    ██ ██      ██      
#   ██████       ███████  ██████  ██████  ██      ███████ 
#                                                         
#                                                         
RadarViewCScope = {
# implements radar/RWR display on CRT/MFD
# also slew cursor to select contacts.
# fast loop
#
# Attributes:
#   link to Radar
#   link to FireControl
	new: func {
		me.window = canvas.Window.new([256, 256],"dialog")
				.set('x', 825)
                .set('title', "Radar C-Scope");
		var root = me.window.getCanvas(1).createGroup();
		me.window.getCanvas(1).setColorBackground(0,0,0);
		me.rootCenter = root.createChild("group")
				.setTranslation(128,256);
		me.rootCenter2 = root.createChild("group")
				.setTranslation(0,128);
		me.rootCenterBleps = root.createChild("group")
				.setTranslation(128,128);
		me.sweep = me.rootCenter.createChild("path")
				.moveTo(0,0)
				.vert(-20)
				.setStrokeLineWidth(2.5)
				.setColor(1,1,1);
		me.sweep2 = me.rootCenter2.createChild("path")
				.moveTo(0,0)
				.horiz(20)
				.setStrokeLineWidth(2.5)
				.setColor(1,1,1);
		
	    root.createChild("path")
	       .moveTo(0, 128)
           .arcSmallCW(128, 128, 0, 256, 0)
           .arcSmallCW(128, 128, 0, -256, 0)
           .setStrokeLineWidth(1)
           .setColor(1, 1, 1);

        me.blep = setsize([],200);
        for (var i = 0;i<200;i+=1) {
        	me.blep[i] = me.rootCenterBleps.createChild("path")
					.moveTo(0,0)
					.vert(2)
					.setStrokeLineWidth(2)
	      	  		.hide();
        }
        me.lock = setsize([],200);
        for (var i = 0;i<200;i+=1) {
        	me.lock[i] = me.rootCenterBleps.createChild("path")
						.moveTo(-5,-5)
						.vert(10)
						.horiz(10)
						.vert(-10)
						.horiz(-10)
						.setStrokeLineWidth(1)
	      	  		.hide();
        }
        me.select = setsize([],200);
        for (var i = 0;i<200;i+=1) {
        	me.select[i] = me.rootCenterBleps.createChild("path")
						.moveTo(-7,-7)
						.vert(14)
						.horiz(14)
						.vert(-14)
						.horiz(-14)
						.setColor([0.5,0,1])
						.setStrokeLineWidth(1)
	      	  		.hide();
        }
		

		var mt = maketimer(scanInterval,func me.loop());
        mt.start();
		return me;
	},

	loop: func {
		if (!enable) return;
		me.sweep.setTranslation(128*exampleRadar.positionCart[0],0);
		me.sweep2.setTranslation(0, -128*exampleRadar.positionCart[1]);
		me.sweep.update();
		me.sweep2.update();
		me.elapsed = getprop("sim/time/elapsed-sec");
		#me.rootCenterBleps.removeAllChildren();
		#me.rootCenterBleps.createChild("path")# thsi will show where the disc is pointed for debug purposes.
		#			.moveTo(0,0)
		#			.vert(2)
		#			.setStrokeLineWidth(2)
		#			.setColor(0.5,0.5,0.5)
		#			.setTranslation(128*exampleRadar.posH/60,-128*exampleRadar.posE/60)
		#			.update();
		me.i = 0;
		foreach(contact; exampleRadar.vector_aicontacts_bleps) {
			if (me.elapsed - contact.blepTime < exampleRadar.currentMode.timeToKeepBleps) {
				me.blep[me.i].setColor(1-(me.elapsed - contact.blepTime)/exampleRadar.currentMode.timeToKeepBleps,1-(me.elapsed - contact.blepTime)/exampleRadar.currentMode.timeToKeepBleps,1-(me.elapsed - contact.blepTime)/exampleRadar.currentMode.timeToKeepBleps);
				me.blep[me.i].setTranslation(128*contact.getDeviationHeadingFrozen()/60,-128*contact.getElevationFrozen()/60);
				me.blep[me.i].show();
				me.blep[me.i].update();
				if (0 and exampleRadar.containsVector(exampleRadar.locks, contact)) {
					me.lock[me.i].setColor(exampleRadar.lock == HARD?[1,0,0]:[1,1,0]);
					me.lock[me.i].setTranslation(128*contact.getDeviationHeadingFrozen()/60,-128*contact.getElevationFrozen()/60);
					me.lock[me.i].show();
					me.lock[me.i].update();
				} else {
					me.lock[me.i].hide();
				}
				if (0 and exampleRadar.containsVector(exampleRadar.follow, contact)) {
					me.select[me.i].setTranslation(128*getDeviationHeadingFrozen()/60,-128*contact.getElevationFrozen()/60);
					me.select[me.i].show();
					me.select[me.i].update();
				} else {
					me.select[me.i].hide();
				}
				me.i += 1;
				if (me.i > 199) break;
			}
		}
		for (;me.i<200;me.i+=1) {
			me.blep[me.i].hide();
			me.lock[me.i].hide();
			me.select[me.i].hide();
		}
	},
	del: func {
		me.window.del();
        #emesary.GlobalTransmitter.DeRegister(f16_hmd);
    },
};



#   █████        ███████  ██████  ██████  ██████  ███████ 
#  ██   ██       ██      ██      ██    ██ ██   ██ ██      
#  ███████ █████ ███████ ██      ██    ██ ██████  █████   
#  ██   ██            ██ ██      ██    ██ ██      ██      
#  ██   ██       ███████  ██████  ██████  ██      ███████ 
#                                                         
#                                                         
RadarViewAScope = {
# implements radar/RWR display on CRT/MFD
# also slew cursor to select contacts.
# fast loop
#
# Attributes:
#   link to Radar
#   link to FireControl
	new: func {
		
		me.window = canvas.Window.new([256, 256],"dialog")
				.set('x', 825)
				.set('y', 350)
                .set('title', "Radar A-Scope");
		var root = me.window.getCanvas(1).createGroup();
		me.window.getCanvas(1).setColorBackground(0,0,0);
		me.rootCenter = root.createChild("group")
				.setTranslation(0,250);
		me.line = [];
		for (var i = 0;i<256;i+=1) {
			append(me.line, me.rootCenter.createChild("path")
					.moveTo(0,0)
					.vert(300)
					.setStrokeLineWidth(1)
					.setColor(1,1,1));
		}
		me.values = setsize([], 256);
		var mt = maketimer(scanInterval,func me.loop());
        mt.start();
		return me;
	},

	loop: func {
		if (!enable) return;
		for (var i = 0;i<256;i+=1) {
			me.values[i] = 0;
		}
		me.elapsed = getprop("sim/time/elapsed-sec");
		foreach(contact; exampleRadar.vector_aicontacts_bleps) {
			if (me.elapsed - contact.blepTime < exampleRadar.currentMode.timeToKeepBleps) {
				me.range = contact.getRangeDirectFrozen();
				if (me.range==0) me.range=1;
				me.distPixels = 2/math.pow(me.range/contact.strength,2);
				me.index = int(256*(contact.getCartesianInFoRFrozen()[0]+1)*0.5);
				if (me.index<=255 and me.index>= 0) {
					me.values[me.index] += me.distPixels;
					if (me.index+1<=255)
						me.values[me.index+1] += me.distPixels*0.5;
					if (me.index+2<=255)
						me.values[me.index+2] += me.distPixels*0.25;
					if (me.index-1>=0)
						me.values[me.index-1] += me.distPixels*0.5;
					if (me.index-2>=0)
						me.values[me.index-2] += me.distPixels*0.25;
				}
			}
		}
		for (var i = 0;i<256;i+=1) {
			me.line[i].setTranslation(i,-clamp(me.values[i],0,256));
		}
		
	},
	del: func {
		me.window.del();
        #emesary.GlobalTransmitter.DeRegister(f16_hmd);
    },
};

RWRCanvas = {
	new: func (root, center, diameter) {
		var rwr = {parents: [RWRCanvas]};
		rwr.max_icons = 12;
		rwr.inner_radius = diameter/6;
		rwr.outer_radius = diameter/3;
		var font = int(0.039*diameter)+1;
		var colorG = [0,1,0];
		var colorLG = [0,0.5,0];
		rwr.fadeTime = 7;#seconds
		rwr.rootCenter = root.createChild("group")
				.setTranslation(center[0],center[1]);
		
	    root.createChild("path")
	       .moveTo(0, diameter/2)
           .arcSmallCW(diameter/2, diameter/2, 0, diameter, 0)
           .arcSmallCW(diameter/2, diameter/2, 0, -diameter, 0)
           .setStrokeLineWidth(1)
           .setColor(1, 1, 1);
        root.createChild("path")
	       .moveTo(diameter/2-rwr.inner_radius, diameter/2)
           .arcSmallCW(rwr.inner_radius, rwr.inner_radius, 0, rwr.inner_radius*2, 0)
           .arcSmallCW(rwr.inner_radius, rwr.inner_radius, 0, -rwr.inner_radius*2, 0)
           .setStrokeLineWidth(1)
           .setColor(colorLG);
        root.createChild("path")
	       .moveTo(diameter/2-rwr.outer_radius, diameter/2)
           .arcSmallCW(rwr.outer_radius, rwr.outer_radius, 0, rwr.outer_radius*2, 0)
           .arcSmallCW(rwr.outer_radius, rwr.outer_radius, 0, -rwr.outer_radius*2, 0)
           .setStrokeLineWidth(1)
           .setColor(colorLG);
        rwr.texts = setsize([],rwr.max_icons);
        for (var i = 0;i<rwr.max_icons;i+=1) {
        	rwr.texts[i] = rwr.rootCenter.createChild("text")
				.setText(int(rand()*21))
				.setAlignment("center-center")
				.setColor(colorG)
      	  		.setFontSize(font, 1.0)
      	  		.hide();

        }
        rwr.symbol_hat = setsize([],rwr.max_icons);
        for (var i = 0;i<rwr.max_icons;i+=1) {
        	rwr.symbol_hat[i] = rwr.rootCenter.createChild("path")
					.moveTo(0,-font)
					.lineTo(font*0.7,-font*0.7)
					.moveTo(0,-font)
					.lineTo(-font*0.7,-font*0.7)
					.setStrokeLineWidth(1)
					.setColor(colorG)
	      	  		.hide();
        }

 #       me.symbol_16_SAM = setsize([],max_icons);
#	    for (var i = 0;i<max_icons;i+=1) {
 #       	me.symbol_16_SAM[i] = me.rootCenter.createChild("path")
#					.moveTo(-11, 7)
#					.lineTo(-9, -7)
#					.moveTo(-9, -7)
#					.lineTo(-9, -4)
#					.moveTo(-9, -8)
#					.lineTo(-11, -4)
#					.setStrokeLineWidth(1)
#					.setColor(1,0,0)
#	      	  		.hide();
#        }
	    rwr.symbol_launch = setsize([],rwr.max_icons);
	    for (var i = 0;i<rwr.max_icons;i+=1) {
        	rwr.symbol_launch[i] = rwr.rootCenter.createChild("path")
					.moveTo(font*1.5, 0)
           			.arcSmallCW(font*1.5, font*1.5, 0, -font*3, 0)
           			.arcSmallCW(font*1.5, font*1.5, 0, font*3, 0)
					.setStrokeLineWidth(1)
					.setColor(colorG)
	      	  		.hide();
        }
        rwr.symbol_new = setsize([],rwr.max_icons);
	    for (var i = 0;i<rwr.max_icons;i+=1) {
        	rwr.symbol_new[i] = rwr.rootCenter.createChild("path")
					.moveTo(font*1.5, 0)
           			.arcSmallCCW(font*1.5, font*1.5, 0, -font*3, 0)
					.setStrokeLineWidth(1)
					.setColor(colorG)
	      	  		.hide();
        }
#        rwr.symbol_16_lethal = setsize([],max_icons);
#        for (var i = 0;i<max_icons;i+=1) {
#        	rwr.symbol_16_lethal[i] = rwr.rootCenter.createChild("path")
#					.moveTo(10, 10)
#					.lineTo(10, -10)
#					.lineTo(-10,-10)
#					.lineTo(-10,10)
#					.lineTo(10, 10)
#					.setStrokeLineWidth(1)
#					.setColor(1,0,0)
#	      	  		.hide();
#        }
        rwr.symbol_priority = rwr.rootCenter.createChild("path")
					.moveTo(0, font*1.5)
					.lineTo(font*1.5, 0)
					.lineTo(0,-font*1.5)
					.lineTo(-font*1.5,0)
					.lineTo(0, font*1.5)
					.setStrokeLineWidth(1)
					.setColor(colorG)
	      	  		.hide();
        
#        rwr.symbol_16_air = setsize([],max_icons);
#        for (var i = 0;i<max_icons;i+=1) {
 #       	rwr.symbol_16_air[i] = rwr.rootCenter.createChild("path")
#					.moveTo(15, 0)
#					.lineTo(0,-15)
#					.lineTo(-15,0)
#					.setStrokeLineWidth(1)
#					.setColor(1,0,0)
#	      	  		.hide();
#        }
		rwr.AIRCRAFT_VIGGEN = "37";
		rwr.AIRCRAFT_EAGLE = "15";
		rwr.AIRCRAFT_TOMCAT = "14";
		rwr.AIRCRAFT_BUK = "11";
		rwr.AIRCRAFT_MIG = "21";
		rwr.AIRCRAFT_MIRAGE = "20";
		rwr.AIRCRAFT_FALCON = "16";
		rwr.AIRCRAFT_FRIGATE = "SH";
		rwr.AIRCRAFT_VIGGEN   = "37";
        rwr.AIRCRAFT_EAGLE    = "15";
        rwr.AIRCRAFT_TOMCAT   = "14";
        rwr.ASSET_BUK         = "11";
        rwr.ASSET_GARGOYLE    = "20"; # Other namings for tracking and radar: BB, CS.
        rwr.AIRCRAFT_FAGOT    = "MG";
        rwr.AIRCRAFT_FISHBED  = "21";
        rwr.AIRCRAFT_FULCRUM  = "29";
        rwr.AIRCRAFT_FLANKER  = "27";
        rwr.AIRCRAFT_PAKFA    = "57";
        rwr.AIRCRAFT_MIRAGE   = "M2";
        rwr.AIRCRAFT_FALCON   = "16";
        rwr.AIRCRAFT_WARTHOG  = "10";
        rwr.ASSET_FRIGATE     = "SH";
        rwr.AIRCRAFT_SEARCH   = "S";
        rwr.AIRCRAFT_BLACKBIRD = "71";
        rwr.AIRCRAFT_TYPHOON  = "EF";
        rwr.AIRCRAFT_HORNET   = "18";
        rwr.AIRCRAFT_FLAGON   = "SU";
        rwr.SCENARIO_OPPONENT = "28";
        rwr.AIRCRAFT_JAGUAR   = "JA";
        rwr.AIRCRAFT_PHANTOM  = "F4";
        rwr.AIRCRAFT_SKYHAWK  = "A4";
        rwr.AIRCRAFT_TIGER    = "F5";
        rwr.AIRCRAFT_TONKA    = "TO";
        rwr.AIRCRAFT_RAFALE   = "RF";
        rwr.AIRCRAFT_HARRIER  = "HA";
        rwr.AIRCRAFT_HARRIERII = "AV";
        rwr.AIRCRAFT_GINA     = "91";
        rwr.AIRCRAFT_MB339    = "M3";
        rwr.AIRCRAFT_ALPHAJET = "AJ";
        rwr.AIRCRAFT_INTRUDER = "A6";
        rwr.AIRCRAFT_FROGFOOT = "25";
        rwr.AIRCRAFT_NIGHTHAWK = "17";
        rwr.AIRCRAFT_RAPTOR   = "22";
        rwr.AIRCRAFT_JSF      = "35";
        rwr.AIRCRAFT_GRIPEN   = "39";
        rwr.AIRCRAFT_MITTEN   = "Y1";
        rwr.AIRCRAFT_ALCA     = "LC";
        rwr.AIRCRAFT_SPRETNDRD = "ET";
        rwr.AIRCRAFT_UNKNOWN  = "U";
        rwr.AIRCRAFT_UFO      = "UK";
        rwr.ASSET_AI          = "AI";
        rwr.lookupType = {
        # OPRF fleet and related aircrafts:
                "f-14b":                    rwr.AIRCRAFT_TOMCAT,
                "F-14D":                    rwr.AIRCRAFT_TOMCAT,
                "F-15C":                    rwr.AIRCRAFT_EAGLE,
                "F-15D":                    rwr.AIRCRAFT_EAGLE,
                "F-16":                     rwr.AIRCRAFT_FALCON,
                "JA37-Viggen":              rwr.AIRCRAFT_VIGGEN,
                "AJ37-Viggen":              rwr.AIRCRAFT_VIGGEN,
                "AJS37-Viggen":             rwr.AIRCRAFT_VIGGEN,
                "JA37Di-Viggen":            rwr.AIRCRAFT_VIGGEN,
                "m2000-5":                  rwr.AIRCRAFT_MIRAGE,
                "m2000-5B":                 rwr.AIRCRAFT_MIRAGE,
                "MiG-21bis":                rwr.AIRCRAFT_FISHBED,
                "MiG-29":                   rwr.AIRCRAFT_FULCRUM,
                "SU-27":                    rwr.AIRCRAFT_FLANKER,
                "EC-137R":                  rwr.AIRCRAFT_SEARCH,
                "RC-137R":                  rwr.AIRCRAFT_SEARCH,
                "E-8R":                     rwr.AIRCRAFT_SEARCH,
                "EC-137D":                  rwr.AIRCRAFT_SEARCH,
                "gci":                      rwr.AIRCRAFT_SEARCH,
                "Blackbird-SR71A":          rwr.AIRCRAFT_BLACKBIRD,
                "Blackbird-SR71A-BigTail":  rwr.AIRCRAFT_BLACKBIRD,
                "Blackbird-SR71B":          rwr.AIRCRAFT_BLACKBIRD,
                "A-10":                     rwr.AIRCRAFT_WARTHOG,
                "A-10-model":               rwr.AIRCRAFT_WARTHOG,
                "Typhoon":                  rwr.AIRCRAFT_TYPHOON,
                "buk-m2":                   rwr.ASSET_BUK,
                "s-300":                    rwr.ASSET_GARGOYLE,
                "missile_frigate":          rwr.ASSET_FRIGATE,
                "frigate":                  rwr.ASSET_FRIGATE,
                "fleet":                    rwr.ASSET_FRIGATE,
                "Mig-28":                   rwr.SCENARIO_OPPONENT,
                "Jaguar-GR1":               rwr.AIRCRAFT_JAGUAR,
        # Other threatening aircrafts (FGAddon, FGUK, etc.):
                "AI":                       rwr.ASSET_AI,
                "SU-37":                    rwr.AIRCRAFT_FLANKER,
                "J-11A":                    rwr.AIRCRAFT_FLANKER,
                "T-50":                     rwr.AIRCRAFT_PAKFA,
                "MiG-21Bison":              rwr.AIRCRAFT_FISHBED,
                "Mig-29":                   rwr.AIRCRAFT_FULCRUM,
                "EF2000":                   rwr.AIRCRAFT_TYPHOON,
                "F-15C_Eagle":              rwr.AIRCRAFT_EAGLE,
                "F-15J_ADTW":               rwr.AIRCRAFT_EAGLE,
                "F-15DJ_ADTW":              rwr.AIRCRAFT_EAGLE,
                "f16":                      rwr.AIRCRAFT_FALCON,
                "F-16CJ":                   rwr.AIRCRAFT_FALCON,
                "FA-18C_Hornet":            rwr.AIRCRAFT_HORNET,
                "FA-18D_Hornet":            rwr.AIRCRAFT_HORNET,
                "f18":                      rwr.AIRCRAFT_HORNET,
                "A-10-modelB":              rwr.AIRCRAFT_WARTHOG,
                "Su-15":                    rwr.AIRCRAFT_FLAGON,
                "Jaguar-GR3":               rwr.AIRCRAFT_JAGUAR,
                "E3B":                      rwr.AIRCRAFT_SEARCH,
                "E-2C-Hawkeye":             rwr.AIRCRAFT_SEARCH,
                "onox-awacs":               rwr.AIRCRAFT_SEARCH,
                "u-2s":                     rwr.AIRCRAFT_SEARCH,
                "U-2S-model":               rwr.AIRCRAFT_SEARCH,
                "F-4S":                     rwr.AIRCRAFT_PHANTOM,
                "F-4EJ_ADTW":               rwr.AIRCRAFT_PHANTOM,
                "FGR2-Phantom":             rwr.AIRCRAFT_PHANTOM,
                "F4J":                      rwr.AIRCRAFT_PHANTOM,
                "F-4N":                     rwr.AIRCRAFT_PHANTOM,
                "a4f":                      rwr.AIRCRAFT_SKYHAWK,
                "A-4K":                     rwr.AIRCRAFT_SKYHAWK,
                "F-5E":                     rwr.AIRCRAFT_TIGER,
                "F-5E-TigerII":             rwr.AIRCRAFT_TIGER,
                "F-5ENinja":                rwr.AIRCRAFT_TIGER,
                "f-20A":                    rwr.AIRCRAFT_TIGER,
                "f-20C":                    rwr.AIRCRAFT_TIGER,
                "f-20prototype":            rwr.AIRCRAFT_TIGER,
                "f-20bmw":                  rwr.AIRCRAFT_TIGER,
                "f-20-dutchdemo":           rwr.AIRCRAFT_TIGER,
                "Tornado-GR4a":             rwr.AIRCRAFT_TONKA,
                "Tornado-IDS":              rwr.AIRCRAFT_TONKA,
                "Tornado-F3":               rwr.AIRCRAFT_TONKA,
                "brsq":                     rwr.AIRCRAFT_RAFALE,
                "Harrier-GR1":              rwr.AIRCRAFT_HARRIER,
                "Harrier-GR3":              rwr.AIRCRAFT_HARRIER,
                "Harrier-GR5":              rwr.AIRCRAFT_HARRIER,
                "Harrier-GR9":              rwr.AIRCRAFT_HARRIER,
                "AV-8B":                    rwr.AIRCRAFT_HARRIERII,
                "G91-R1B":                  rwr.AIRCRAFT_GINA,
                "G91":                      rwr.AIRCRAFT_GINA,
                "g91":                      rwr.AIRCRAFT_GINA,
                "mb339":                    rwr.AIRCRAFT_MB339,
                "mb339pan":                 rwr.AIRCRAFT_MB339,
                "alphajet":                 rwr.AIRCRAFT_ALPHAJET,
                "MiG-15bis":                rwr.AIRCRAFT_FAGOT,
                "Su-25":                    rwr.AIRCRAFT_FROGFOOT,
                "A-6E-model":               rwr.AIRCRAFT_INTRUDER,
                "F-117":                    rwr.AIRCRAFT_NIGHTHAWK,
                "F-22-Raptor":              rwr.AIRCRAFT_RAPTOR,
                "F-35A":                    rwr.AIRCRAFT_JSF,
                "F-35B":                    rwr.AIRCRAFT_JSF,
                "JAS-39C_Gripen":           rwr.AIRCRAFT_GRIPEN,
                "gripen":                   rwr.AIRCRAFT_GRIPEN,
                "Yak-130":                  rwr.AIRCRAFT_MITTEN,
                "L-159":                    rwr.AIRCRAFT_ALCA,
                "super-etendard":           rwr.AIRCRAFT_SPRETNDRD,
                "mp-nimitz":                rwr.ASSET_FRIGATE,
                "mp-eisenhower":            rwr.ASSET_FRIGATE,
                "mp-vinson":                rwr.ASSET_FRIGATE,
                "mp-clemenceau":            rwr.ASSET_FRIGATE,
                "ufo":                      rwr.AIRCRAFT_UFO,
                "bluebird-osg":             rwr.AIRCRAFT_UFO,
                "F-23C_BlackWidow-II":      rwr.AIRCRAFT_UFO,
        };
		rwr.shownList = [];
		return rwr;
	},
	update: func (list) {
		me.elapsed = getprop("sim/time/elapsed-sec");
		var sorter = func(a, b) {
		    if(a[1] < b[1]){
		        return -1; # A should before b in the returned vector
		    }elsif(a[1] == b[1]){
		        return 0; # A is equivalent to b 
		    }else{
		        return 1; # A should after b in the returned vector
		    }
		}
		var sortedlist = sort(list, sorter);
		var newList = [];
		me.i = 0;
		me.hat = 0;
		me.newt = 0;
		me.prioShow = 0;
		foreach(contact; sortedlist) {
			me.typ=me.lookupType[contact[0].getModel()];
			if (me.typ == nil) {
				me.typ = me.AIRCRAFT_UNKNOWN;
			}
			if (me.i > me.max_icons-1) {
				break;
			}
			me.threat = contact[1];#print(me.threat);
			if (me.threat < 5) {
				me.threat = me.inner_radius;# inner circle
			} elsif (me.threat < 30) {
				me.threat = me.outer_radius;# outer circle
			} else {
				continue;
			}
			me.dev = -contact[0].getThreatStored()[5]+90;
			me.x = math.cos(me.dev*D2R)*me.threat;
			me.y = -math.sin(me.dev*D2R)*me.threat;
			me.texts[me.i].setTranslation(me.x,me.y);
      	  	me.texts[me.i].show();
      	  	me.texts[me.i].setText(me.typ);
			if (me.i == 0) {
				me.symbol_priority.setTranslation(me.x,me.y);
	      	  	me.prioShow = 1;
			}
			if (!(me.typ == me.AIRCRAFT_BUK or me.typ == me.AIRCRAFT_FRIGATE)) {
				me.symbol_hat[me.hat].setTranslation(me.x,me.y);
	      	  	me.symbol_hat[me.hat].show();
				me.symbol_hat[me.hat].update();
				me.hat += 1;
			}
			var popup = me.elapsed;
			foreach(var old; me.shownList) {
				if(old[0].equals(contact[0])) {
					popup = old[1];
					break;
				}
			}
			if (popup > me.elapsed-me.fadeTime) {
				me.symbol_new[me.newt].setTranslation(me.x,me.y);
	      	  	me.symbol_new[me.newt].show();
				me.symbol_new[me.newt].update();
				me.newt += 1;
			}
			append(newList, [contact[0],popup]);
			me.i += 1;
		}
		me.symbol_priority.setVisible(me.prioShow);
		me.shownList = newList;
		for (;me.i<me.max_icons;me.i+=1) {
			me.texts[me.i].hide();
		}
		for (;me.hat<me.max_icons;me.hat+=1) {
			me.symbol_hat[me.hat].hide();
		}
		for (;me.newt<me.max_icons;me.newt+=1) {
			me.symbol_new[me.newt].hide();
		}
	},
	del: func {
	},
};

RWRView = {
	new: func {
		var diameter = 256;
		me.window = canvas.Window.new([diameter, diameter],"dialog")
				.set('x', 550)
				.set('y', 350)
                .set('title', "RWR");
		var root = me.window.getCanvas(1).createGroup();
		me.window.getCanvas(1).setColorBackground(0,0.2,0);
		me.rwr = RWRCanvas.new(root, [diameter/2,diameter/2], diameter);
		var mt = maketimer(1,func me.loop());
        mt.start();
		return me;
	},

	loop: func {
		if (!enableRWRs) return;
		
		
		me.rwr.update(exampleRWR.vector_aicontacts_threats);

		
	},
	del: func {
		me.rwr.del();
		me.window.del();
	},
};














var window = nil;
var buttonWindow = func {
	# a test gui for radar modes
	window = canvas.Window.new([200,525],"dialog").set('title',"Radar modes");
	var myCanvas = window.createCanvas().set("background", canvas.style.getColor("bg_color"));
	var root = myCanvas.createGroup();
	var myLayout0 = canvas.HBoxLayout.new();
	var myLayout = canvas.VBoxLayout.new();
	var myLayout2 = canvas.VBoxLayout.new();
	myCanvas.setLayout(myLayout0);
	myLayout0.addItem(myLayout);
	myLayout0.addItem(myLayout2);
#	var button0 = canvas.gui.widgets.Button.new(root, canvas.style, {})
#		.setText("RWS high")
#		.setFixedSize(75, 25);
#	button0.listen("clicked", func {
#		exampleRadar.rwsHigh();
#	});
#	myLayout.addItem(button0);
	var button0 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Master Mode")
		.setFixedSize(90, 25);
	button0.listen("clicked", func {
		exampleRadar.cycleRootMode();
	});
	myLayout.addItem(button0);
	var button1 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Mode")
		.setFixedSize(75, 25);
	button1.listen("clicked", func {
		exampleRadar.cycleMode();
	});
	myLayout.addItem(button1);
	var button5 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Left")
		.setFixedSize(75, 25);
	button5.listen("clicked", func {
		exampleRadar.setDeviation(exampleRadar.getDeviation()-10);
	});
	myLayout.addItem(button5);
	var button6 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Right")
		.setFixedSize(75, 25);
	button6.listen("clicked", func {
		exampleRadar.setDeviation(exampleRadar.getDeviation()+10);
	});
	myLayout.addItem(button6);
	var button7 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Range+")
		.setFixedSize(75, 20);
	button7.listen("clicked", func {
		exampleRadar.increaseRange();
	});
	myLayout.addItem(button7);
	var button8 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Range-")
		.setFixedSize(75, 20);
	button8.listen("clicked", func {
		exampleRadar.decreaseRange();
	});
	myLayout.addItem(button8);
	var button9 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Designate")
		.setFixedSize(75, 25);
	button9.listen("clicked", func {
		exampleRadar.designateRandom();
	});
	myLayout.addItem(button9);
	var button10 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Un-designate")
		.setFixedSize(90, 25);
	button10.listen("clicked", func {
		exampleRadar.undesignate();
	});
	myLayout.addItem(button10);
	var button11 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Cycle priority")
		.setFixedSize(90, 25);
	button11.listen("clicked", func {
		exampleRadar.cycleDesignate();
	});
	myLayout.addItem(button11);
	var button12 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Up")
		.setFixedSize(75, 25);
	button12.listen("clicked", func {
		exampleRadar.setTilt(exampleRadar.getTilt()+4);
	});
	myLayout.addItem(button12);
	var button13 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Down")
		.setFixedSize(75, 25);
	button13.listen("clicked", func {
		exampleRadar.setTilt(exampleRadar.getTilt()-4);
	});
	myLayout.addItem(button13);
	var button14 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Level")
		.setFixedSize(75, 25);
	button14.listen("clicked", func {
		exampleRadar.setTilt(0);
	});
	myLayout.addItem(button14);

	var button15b = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Bars")
		.setFixedSize(75, 25);
	button15b.listen("clicked", func {
		exampleRadar.cycleBars();
	});
	myLayout2.addItem(button15b);
	var button19 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Azimuth")
		.setFixedSize(75, 25);
	button19.listen("clicked", func {
		exampleRadar.cycleAZ();
	});
	myLayout2.addItem(button19);
	button23 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Scr ON")
		.setFixedSize(75, 20);
	button23.listen("clicked", func {
		enable = !enable;
		if (enable == 0) button23.setText("Scr OFF");
		else button23.setText("Scr ON");
	});
	myLayout2.addItem(button23);
	#button24 = canvas.gui.widgets.Button.new(root, canvas.style, {})
	#	.setText("RWRsc ON")
	#	.setFixedSize(75, 20);
	#button24.listen("clicked", func {
	#	enableRWRs = !enableRWRs;
	#	if (enableRWRs == 0) button24.setText("RWRsc OFF");
	#	else button24.setText("RWRsc ON");
	#});
	#myLayout2.addItem(button24);
	#button25 = canvas.gui.widgets.Button.new(root, canvas.style, {})
	#	.setText("RWR ON")
	#	.setFixedSize(75, 20);
	#button25.listen("clicked", func {
	#	enableRWR = !enableRWR;
	#	if (enableRWR == 0) button25.setText("RWR OFF");
	#	else button25.setText("RWR ON");
	#});
	#myLayout2.addItem(button25);
	button26 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("RDR ON")
		.setFixedSize(75, 20);
	button26.listen("clicked", func {
		exampleRadar.enabled = !exampleRadar.enabled;
		if (exampleRadar.enabled == 0) button26.setText("RDR OFF");
		else button26.setText("RDR ON");
	});
	myLayout2.addItem(button26);
	button27 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Nose ON")
		.setFixedSize(75, 20);
	button27.listen("clicked", func {
		nose.enabled = !nose.enabled;
		if (nose.enabled == 0) button27.setText("Nose OFF");
		else button27.setText("Nose ON");
	});
	myLayout2.addItem(button27);
	button28 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Parser ON")
		.setFixedSize(75, 20);
	button28.listen("clicked", func {
		baser.enabled = !baser.enabled;
		if (baser.enabled == 0) button28.setText("Parser OFF");
		else button28.setText("Parser ON");
	});
	myLayout2.addItem(button28);
};
var button23 = nil;
var button24 = nil;
var button25 = nil;
var button26 = nil;
var button27 = nil;
var button28 = nil;



var baser = nil;
var nose = nil;
var omni = nil;
var terrain = nil;
var exampleRWR   = nil;
var displayPPI = nil;
var displayB = nil;
var displayC = nil;
var displayA = nil;
var displayRWR = nil;



#var fix = FixedBeamRadar.new();
#fix.setBeamPitch(-2.5);
#settimer(func {print("beam: "~fix.testForDistance());},15);# will fail if no terrain found :)

var main = func (module) {
	baser = AIToNasal.new();
	nose = NoseRadar.new();
	omni = OmniRadar.new(0.25, 150, 55);
	terrain = TerrainChecker.new(0.10, 1, 60);
	displayPPI = RadarViewPPI.new();
	displayB = RadarViewBScope.new();
	#displayC = RadarViewCScope.new();
	#displayA = RadarViewAScope.new();
	#exampleRWR   = RWR.new();
	#displayRWR = RWRView.new();
    buttonWindow();
}

var unload = func {
    if (exampleRadar != nil) {
        exampleRadar.del();
        exampleRadar = nil;
    }
    if (nose != nil) {
        nose.del();
        nose = nil;
    }
    if (omni != nil) {
        omni.del();
        omni = nil;
    }
    if (displayRWR != nil) {
        displayRWR.del();
        displayRWR = nil;
    }
    if (displayPPI != nil) {
        displayPPI.del();
        displayPPI = nil;
    }
    if (displayB != nil) {
        displayB.del();
        displayB = nil;
    }
    if (displayA != nil) {
        displayA.del();
        displayA = nil;
    }
    if (displayC != nil) {
        displayC.del();
        displayC = nil;
    }
    if (terrain != nil) {
        terrain.del();
        terrain = nil;
    }
    if (exampleRWR != nil) {
        exampleRWR.del();
        exampleRWR = nil;
    }
    if (window != nil) {
        window.del();
        window = nil;
    }
    if (baser != nil) {
        baser.del();
        baser = nil;
    }
    AIToNasal = nil;
	NoseRadar = nil;
	OmniRadar = nil;
	TerrainChecker = nil;
	RWR = nil;
	RadarViewPPI = nil;
	RadarViewBScope = nil;
	RadarViewCScope = nil;
	RadarViewAScope = nil;
	RWRView = nil;
}

# BUGS:
#
# exampleRadar.positionCart vs. contact.getCartesianInFoRFrozen()  At least one is not correct! ACM60
#
# IMPROVEMENTS:
#
# Max roll before no longer roll stabilized CRM. (mig21 too)
# Cursor stuff
#
#
# FEATURES:
#
# isPainted in contacts
# inaccuracy in GM
# send spike
# subclass for missiles
# completelist for bombs
# GM modes