#
# Flightgear radar system using Richard's and OPRF radar-mafia's radar designs.
#
# In Richards design, the class called RadarSystem is being represented as AIToNasal, NoseRadar, OmniRadar & TerrainChecker classes.
#                     the class called AircraftRadar is represented as ActiveDiscRadar & RWR.
#                     the class called AIContact does allow for direct reading of contact properties, but this is forbidden outside RadarSystem. Except for Missile-code.
#
# Development changelog:
# v0:   Nov  2017 - Richard shared his design document
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
# v9.1 Jan 6th 2022 - Many kinks ironed out.
# v10.0 Jan 17th 2022 - Chaff handling. Re-coded antennae movement code. Code cleanup.
#
# 
# Properties is only being read in the modules that represent RadarSystem.
#
#
# People that have contributed to this:
#   Alexis Bory
#   Richard Harrison
#   Fabien Barber
#   Nikolai V. Chr
#   Justin Nicholson
#   Colin Geniet
#
#
# Also notice that most comments at start of classes are old and not updated.
#
# Needs rcs.nas, missile-code.nas and vector.nas.
# Optionally datalink.nas and iff.nas
#
# GPL 2.0


var AIR = 0;
var MARINE = 1;
var SURFACE = 2;
var ORDNANCE = 3;
var POINT    = 4;
var TERRASUNK = 5; # Terrain not loaded underneath this (low altitude), most likely a MARINE, but might be a SURFACE.

var ECEF = 0;
var GPS = 1;


var emptyCoord = geo.Coord.new().set_xyz(0,0,0);


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
        	# Direction the aircraft is pointing
	    	me.elev = elev;
	    	me.yaw = yaw;

	    	# Radius and depth of the slice (its round)
	    	me.elev_radius = elev_radius;
	    	me.yaw_radius = yaw_radius;
	    	me.dist_m = dist_m;

	    	# Filter air/ground/sea contacts
	    	me.fa = fa;
	    	me.fg = fg;
	    	me.fs = fs;
	    	return me;
	    };
        return new_class;
    },
};

var RequestFullNotification = {
	max_range: 40,
    new: func() {
        var new_class = emesary.Notification.new("RequestFullNotification", rand());

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
var AIToNasal = {
	# convert AI property tree to Nasal vector
	# will send notification when some is updated
	# listeners for adding/removing AI nodes.
	# very slow loop (5 min)
	# updates AIContacts, does not replace them. (yes will make slower, but solves many issues. Can divide workload over frames.)
	#
	# Attributes:
	#   fullContactVector of AIContacts
	#   index keys for fast locating: callsign, model-path??
	enabled: 1,
	new: func {
		me.prop_AIModels = props.globals.getNode("ai/models");
		me.vector_aicontacts = [];
		me.vector_aicontacts_last = [];
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
		#
		# This method is called when contacts come into or out of existence.
		# If a scan of /ai/models is in progress it is started again from start.
		# If no scan is in progress, one is started.
		#
		if(!me.enabled) return;# TODO: If disabled it is going to miss out on new contacts, maybe do force scan when enabled again?
		#print("NR: listenr called");
		if (!me.scanInProgress) {
			me.scanInProgress = 1;
			me.readTree();
		} else {
			me.startOver = 1;
		}
	},
	
	readTree: func {
		#
		# Reset knowledge of contacts.
		# Start scanning of first contact in property tree.
		# If no contacts, then send out empty vector notifications to subscribers.
		#
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
		#
		# Scan a single contact from property tree.
		# Called once per frame until scan is finished.
		#
		if (me.startOver) {
			me.readTree();
			return;
		}
		
		me.prop_ai = me.vector_raw[me.vector_raw_index];
		me.prop_valid = me.prop_ai.getNode("valid");
		if (me.prop_valid == nil or !me.prop_valid.getValue() or me.prop_ai.getNode("impact") != nil or me.prop_ai.getName() == "ballistic" or me.prop_ai.getName() == "munition") {
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
	    		# No valid position data found, giving up.
		      	me.nextReadTreeFrame();
		      	return;
			}
		    me.pos_type = GPS;
		    me.aircraftPos = geo.Coord.new().set_latlon(me.lat.getValue(), me.lon.getValue(), me.alt.getValue()*FT2M);
	    } else {
	    	me.pos_type = ECEF;
	    	me.aircraftPos = geo.Coord.new().set_xyz(me.x.getValue(), me.y.getValue(), me.z.getValue());
	    	me.aircraftPos.alt();# TODO: once fixed in FG this line is no longer needed.
	    }
	    
	    
        
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
        me.ainame = me.prop_ai.getNode("name");
        if (me.ainame == nil) {
        	me.ainame = "";
        } else {
        	me.ainame = me.ainame.getValue();
        }
        me.subid = me.prop_ai.getNode("subID");
        if (me.subid == nil) {
        	me.subid = "0";
        } else {
        	me.subid = me.subid.getValue();
        }
        me.aitype = me.prop_ai.getNode("type");
        if (me.aitype == nil) {
        	me.aitype = "";
        } else {
        	me.aitype = me.aitype.getValue();
        	if (me.model == "") {
        		me.model = me.aitype;
        	}
        }
        me.sign = me.prop_ai.getNode("sign");
        if (me.sign == nil) {
        	me.sign = "";
        } else {
        	me.sign = me.sign.getValue();
        }
        #AIcontact needs 2 calls to work. new() [cheap] and init() [expensive]. Only new is called here, updateVector will do init():
        me.aicontact = AIContact.new(me.prop_ai, me.model, me.callsign, me.pos_type, me.id, me.ainame, me.subid, me.aitype, me.sign);

        me.usign = sprintf("%s%04d",me.callsign,me.id);
        me.usignLookup = [me.aicontact];
        
        me.updateVectorFrame(me.usign,me.usignLookup);
        
        me.nextReadTreeFrame();
	},
	
	nextReadTreeFrame: func {
		#
		# Schedule to read next contact from property tree.
		# If no one left to schedule, then send out all found to subscribers.
		#
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

	remove_suffix: func(s, x) {
		#
		# Remove suffix 'x' from string 's' if present.
		#
		me.len = size(x);
		if (substr(s, -me.len) == x)
			return substr(s, 0, size(s) - me.len);
		return s;
	},
	
	updateVectorFrame: func (callsignKey, callsignsRaw) {
		me.callsigns    = me.lookupCallsign[callsignKey];
		if (me.callsigns != nil) {
			# Seems like a previous scan knew about contacts with this lookup key.
			# Lets go through these new contacts, and for those we knew about we update
			# the old contact with the new info just in case it has changed.
			# Then we call init() on all of them.
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
		#
		# We finished a scan of property tree contacts.
		# Lets notify our subscribers about them.
		#
		me.lookupCallsign = me.lookupCallsignNew;
		#print("NR: update called "~size(me.vector_aicontacts));
		emesary.GlobalTransmitter.NotifyAll(me.AINotification.updateV(me.vector_aicontacts));
		me.vector_aicontacts_last = me.vector_aicontacts;
	},

	containsVectorContact: func (vec, item) {
		#
		# Test if a contact 'item' exist in vector 'vec',
		# if yes then return the existing contact.
		#
		foreach(test; vec) {
			if (test.equals(item)) {
				return test;
			}
		}
		return nil;
	},

	del: func {
		#
		# Shut this class down neatly.
		#
		call(func removelistener(me.l1),nil,nil,var err = []);
		call(func removelistener(me.l2),nil,nil,var err = []);
	},
};








var Contact = {
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
var SelfContact = {
	#
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
    	me.acHeadingMag = props.globals.getNode("orientation/heading-magnetic-deg");
    	me.acPitch    = props.globals.getNode("orientation/pitch-deg");
    	me.acRoll     = props.globals.getNode("orientation/roll-deg");
    	me.acalt      = props.globals.getNode("position/altitude-ft");
    	me.aclat      = props.globals.getNode("position/latitude-deg");
    	me.aclon      = props.globals.getNode("position/longitude-deg");
    	me.acgns      = props.globals.getNode("velocities/groundspeed-kt");
    	me.acdns      = props.globals.getNode("velocities/speed-down-fps");
    	me.aceas      = props.globals.getNode("velocities/speed-east-fps");
    	me.acnos      = props.globals.getNode("velocities/speed-north-fps");
    	me.acCallsign = props.globals.getNode("sim/multiplay/callsign");
	},

	getCallsign: func {
		return me.acCallsign.getValue();
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

	getHeadingMag: func {
		return me.acHeadingMag.getValue();
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

	getAltitude: func {
		return me.acalt.getValue();
	},
};

var self = SelfContact.new();





#   ██████ ██   ██  █████  ███████ ███████ 
#  ██      ██   ██ ██   ██ ██      ██      
#  ██      ███████ ███████ █████   █████   
#  ██      ██   ██ ██   ██ ██      ██      
#   ██████ ██   ██ ██   ██ ██      ██      
#                                          
#                                          
var Chaff = {
	seenTime: 0,
	releaseTime: 0,
	meters: 0,
	bearing: 0,
	pitch: 0,
};








#  ██████  ███████ ██    ██ ██  █████  ████████ ██  ██████  ███    ██ 
#  ██   ██ ██      ██    ██ ██ ██   ██    ██    ██ ██    ██ ████   ██ 
#  ██   ██ █████   ██    ██ ██ ███████    ██    ██ ██    ██ ██ ██  ██ 
#  ██   ██ ██       ██  ██  ██ ██   ██    ██    ██ ██    ██ ██  ██ ██ 
#  ██████  ███████   ████   ██ ██   ██    ██    ██  ██████  ██   ████ 
#                                                                     
#                                                                     
var Deviation = {
	#
	# This is read by the main radar beam to test if it picks it up.
	#
	azimuthLocal: 0,   # Used for radar beam when not horizon stabilized
	elevationLocal: 0, # Used for radar beam when not horizon stabilized
	rangeDirect_m: 0,  # Used for RCS and chaff
	coord: nil,        # Used for RCS
	heading: 0,        # Used for RCS
	pitch: 0,          # Used for RCS
	roll: 0,           # Used for RCS
	bearing: 0,        # Used for radar beam
	elevationGlobal: 0,# Used for radar beam
	#frustum_norm_y: 0,
	#frustum_norm_z: 0,
	#alt_ft: 0,
	speed_kt: 0,       # Used by GMT mode
	#closureSpeed: 0,
};





#  ██████  ██      ███████ ██████  
#  ██   ██ ██      ██      ██   ██ 
#  ██████  ██      █████   ██████  
#  ██   ██ ██      ██      ██      
#  ██████  ███████ ███████ ██      
#                                  
#                                  
var Blep = {
	#
	# Methods might return nil if the radar mode that found it does not support detection of that property.
	#
	new: func (valueVector) {
		var b = {parents: [Blep]};
		b.values = valueVector;
		return b;
	},

	hasTrackInfo: func {
		return me.values[3] != nil;
	},

	hasSTT: func {
		return me.values[9];
	},

	getAZDeviation: func {
		# Get azimuth deviation to the blep from my current position/orientation
		me.blepCoord = me.getCoord();
		me.blepHeading = self.getCoord().course_to(me.blepCoord);
		return geo.normdeg180(me.blepHeading-self.getHeading());
	},

	getElevDeviation: func {
		# Get elevation deviation to the blep from my current position/orientation
		me.blepCoord = me.getCoord();
		me.blepPitch = vector.Math.getPitch(self.getCoord(), me.blepCoord);
		return me.blepPitch - self.getPitch();
	},

	getElev: func {
		# Get elevation to the blep from my current position/orientation
		me.blepCoord = me.getCoord();
		me.blepPitch = vector.Math.getPitch(self.getCoord(), me.blepCoord);
		return me.blepPitch;
	},

	getRangeNow: func {
		# Get range to the blep from my current position
		# Meters
		me.blepRange = self.getCoord().distance_to(me.getCoord());
		return me.blepRange;
	},

	getHeading: func {
		return me.values[3];
	},

	getStrength: func {
		# Distance in m where it would have been max detectable due to RCS
		return me.values[1];
	},

	getSpeed: func {
		return me.values[5];
	},	

	getDirection: func {
		# Deprecated
		return me.values[4];
	},

	getRangeDirect: func {
		# Get range to the blep from detection position
		# Meters
		return me.values[2];
	},

	getAltitude: func {
		# Feet
		return me.values[7];
	},

	getCoord: func {
		return me.values[8];
	},

	getBlepTime: func {
		return me.values[0];
	},

	getClosureRate: func {
		me.clr = me.values[6];
		return me.clr==nil?0:me.clr;
	},
};


#   ██████  ██████  ███    ██ ████████  █████   ██████ ████████ 
#  ██      ██    ██ ████   ██    ██    ██   ██ ██         ██    
#  ██      ██    ██ ██ ██  ██    ██    ███████ ██         ██    
#  ██      ██    ██ ██  ██ ██    ██    ██   ██ ██         ██    
#   ██████  ██████  ██   ████    ██    ██   ██  ██████    ██    
#                                                               
#                                                               
var AIContact = {
# Attributes:
#   replaceNode() [in AI tree]
	new: func (prop, model, callsign, pos_type, ident, ainame, subid, aitype, sign) {
		var c = {parents: [AIContact, Contact]};

		# general:
		c.prop     = prop;
		c.model    = model;
		c.callsign = callsign;
		c.pos_type = pos_type;
		c.needInit = 1;
		c.visible  = 1;
		c.inClutter = 0;
		c.hiddenFromDoppler = 0;
		c.hiddenFromMono = 0;
		c.id = ident;
		c.ainame = ainame;
		c.subid = subid;
		c.aitype = aitype;
		c.sign = sign;
		c.bleps = [];
		c.lastRegisterWasTrack = 0;
		c.virt = nil;
		c.virtTGP = nil;
		c.iff = 0;

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
		me.miss    = me.prop.getNode("missile");
		me.valid   = me.prop.getNode("valid");
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
    	me.uBody   = me.vel.getNode("uBody-fps");
    	me.vBody   = me.vel.getNode("vBody-fps");
    	me.wBody   = me.vel.getNode("wBody-fps");
    	me.tp      = me.prop.getNode("instrumentation/transponder/transmitted-id");
    	me.rdr     = me.prop.getNode("sim/multiplay/generic/int[2]");
    	me.str6    = me.prop.getNode("sim/multiplay/generic/string[6]");
    	call(func {me.dlinkNode = me.prop.getNode(datalink.mp_path)},nil,nil,var err = []);# call method because radar might be used in aircraft without datalink

	    me.type    = me.determineType(me.prop.getName(), me.miss, me.getCoord().alt()*M2FT, me.model, me.speed==nil?nil:me.speed.getValue());
	    me.carrier = me.determineCarrier(me.prop.getName(), me.model);

	    #print((me.getCoord().alt()*M2FT)~": "~me.get_Callsign()~" / "~me.model~" is type "~me.type);

	    if (enable_tacobject) {
		    me.tacobj = {parents: [tacview.tacobj]};
	        me.tacobj.tacviewID = left(md5(me.getUnique()),5);
	        me.tacobj.valid = 1;
	    }
	},

	update: func (newC) {
		if (me.prop.getPath() != newC.prop.getPath()) {
			me.prop = newC.prop;
			me.needInit = 1;
			print("hmm "~newC.callsign);# TODO: find out why I made this print() and why it outputs for AIM-120 (might have to do with pausing)
		}
		me.model = newC.model;
		me.callsign = newC.callsign;
	},

	equals: func (item) {
		if (item != nil and item.callsign == me.callsign and item.model == me.model and item.ainame == me.ainame and item.sign == me.sign and item.aitype == me.aitype and item.subid == me.subid) {
			return 1;
		}
		return 0;
	},

	equalsFast: func (item) {
		# same instance or same virtual
		if (item == nil) {
			return 0;
		}
		if (item == me or item == me.virt or item == me.virtTGP) {
			return 1;
		}
		return 0;
	},

	determineCarrier: func (prop_name, model) {
		if (prop_name == "carrier") {
			return 1;
		}
		if (isKnownCarrier(model)) {
			return 1;
		}
		return 0;
	},

	determineType: func (prop_name, ordnance, alt_ft, model, speed_kt) {
		# determine type. Only done at init. getType() will check if AIR has landed or taken off and will change it accordingly.
	    # 
        if (prop_name == "carrier") {
        	return MARINE;
        } elsif (prop_name == "aircraft" or prop_name == "Mig-28") {
        	return AIR;
        } elsif (ordnance != nil) {
        	return ORDNANCE;
        } elsif (prop_name == "groundvehicle") {
        	return SURFACE;
        } elsif (model != nil and isKnownSurface(model)) {
			return SURFACE;
		} elsif (model != nil and isKnownShip(model)) {
			return MARINE;
		} elsif (model != nil and isKnownHeli(model) and speed_kt != nil and speed_kt > 10) {
			return AIR;
        } elsif (speed_kt != nil and speed_kt > 60) {
        	return AIR;# can later switch from AIR to SURFACE or opposite
        }
        if(alt_ft < 5.0) {
	        me.getCoord();
	        me.geod = geodinfo(me.coord.lat(),me.coord.lon());
        	if (me.geod == nil) {
        		return TERRASUNK;
        	} elsif (me.geod[1] != nil and !me.geod[1].solid) {# if geod[1] is nil, its a building.
        		return MARINE;
        	}
        }
        return SURFACE;
	},

	getCoord: func {
		if (me.pos_type == ECEF) {
	    	me.coord = geo.Coord.new().set_xyz(me.x.getValue(), me.y.getValue(), me.z.getValue());
	    	me.coord.alt();# TODO: once fixed in FG this line is no longer needed.
	    } else {
	    	if(me.alt == nil or me.lat == nil or me.lon == nil) {
		      	me.coord = emptyCoord;
		      	print("RadarSystem getCoord() returning center of earth! :(");
		      	return me.coord;
		    }
		    me.coord = geo.Coord.new().set_latlon(me.lat.getValue(), me.lon.getValue(), me.alt.getValue()*FT2M);
	    }
	    return me.coord;
	},

	getNearbyVirtualContact: func (spheric_dist_m) {
		# This is for inaccurate radar locking of surface targets with TGP.
		if (me.virt != nil) return me.virt;
		me.virt = {parents: [me, AIContact, Contact]};
		me.getCoord();
		me.coord.set_xyz(me.coord.x()+rand()*spheric_dist_m*2-spheric_dist_m,me.coord.y()+rand()*spheric_dist_m*2-spheric_dist_m,me.coord.z()+rand()*spheric_dist_m*2-spheric_dist_m);
		me.virt.elevpick = geo.elevation(me.coord.lat(),me.coord.lon());
		if (spheric_dist_m != 0 and me.virt.elevpick != nil) me.coord.set_alt(me.virt.elevpick);# TODO: Not convinced this is the place for the 1m offset since both missiles and radar subtract 1m from targetdistance, but for slanted picking with undulations its still good idea to not place it at the base.
		me.virt.coord = me.coord;
		me.virt.getNearbyVirtualTGPContact = func {
			return me.parents[0].getNearbyVirtualTGPContact();
		};
		me.virt.getNearbyVirtualContact = func (d) {
			return me.parents[0].getNearbyVirtualContact(d);
		};
		me.virt.getCoord = func {
			return me.coord;
		};
		me.virt.isVirtual = func {
			return 1;
		};
		me.virt.getType = func {
			return POINT;
		};
		#me.virt.callsign = me.get_Callsign();
		return me.virt;
	},

	getNearbyVirtualTGPContact: func () {
		# Dont remember why the TGP prefers a virtual target when it IR LOCK a target (which it will follow). But it does.
		if (me.virtTGP != nil) return me.virtTGP;
		me.virtTGP = {parents: [me, AIContact, Contact]};
		#me.virtTGP.getCoord = func {
		#	me.parents[0].getCoord();
		#	me.coord.set_alt(me.coord.alt()+0.0);
		#	return me.coord;
		#};
		me.virtTGP.getNearbyVirtualTGPContact = func {
			return me.parents[0].getNearbyVirtualTGPContact();
		};
		me.virtTGP.getNearbyVirtualContact = func (d) {
			return me.parents[0].getNearbyVirtualContact(d);
		};
		me.virtTGP.isVirtual = func {
			return 1;
		};
		me.virtTGP.getType = func {
			return POINT;
		};
		me.virtTGP.callsign = "On "~me.get_Callsign();
		return me.virtTGP;
	},

	getType: func {
		if(me.type == TERRASUNK) {
			me.type = me.determineType(me.prop.getName(), me.miss, me.getCoord().alt()*M2FT, me.model, me.speed==nil?nil:me.speed.getValue());
		}
		if (me.type == AIR and (me.getSpeed() < 60 and !(isKnownHeli(me.model) and me.get_Speed() > 10))) me.type = SURFACE;
		elsif (me.type != ORDNANCE and me.getSpeed() > 60) me.type = AIR;
		elsif (me.type == SURFACE and me.get_Speed() > 10 and isKnownHeli(me.model)) me.type = AIR;
		return me.type;
	},

	isCarrier: func {
		return me.carrier;
	},
	
	getCallsign: func {
		return me.callsign;
	},

	getDeviationPitch: func {
		# This is an instant perfect result, so don't call this outside the radar system.
		me.getCoord();
		me.pitched = vector.Math.getPitch(self.getCoord(), me.coord);
		return me.pitched - self.getPitch();
	},

	getDeviationHeading: func {
		# This is an instant perfect result, so don't call this outside the radar system.
		me.getCoord();
		return geo.normdeg180(self.getCoord().course_to(me.coord)-self.getHeading());
	},

	getRangeDirect: func {# meters
		# This is an instant perfect result, so don't call this outside the radar system.
		me.getCoord();
		return self.getCoord().direct_distance_to(me.coord);
	},
	
	getRange: func {# meters
		# This is an instant perfect result, so don't call this outside the radar system.
		me.getCoord();
		return self.getCoord().distance_to(me.coord);
	},

	getPitch: func {
		# This is an instant perfect result, so don't call this outside the radar system.
		if (me.pitch == nil) {
			return 0;
		}
		return me.pitch.getValue();
	},

	getRoll: func {
		# This is an instant perfect result, so don't call this outside the radar system.
		if (me.roll == nil) {
			return 0;
		}
		return me.roll.getValue();
	},

	getAltitude: func {
		# This is an instant perfect result, so don't call this outside the radar system.
		if (me.alt == nil) {
			return 0;
		}
		return me.alt.getValue();
	},

	getHeading: func {
		# This is an instant perfect result, so don't call this outside the radar system.
		if (me.heading == nil) {
			return 0;
		}
		return me.heading.getValue();
	},

	getSpeed: func {
		# This is an instant perfect result, so don't call this outside the radar system.
		if (me.speed == nil) {
			return 0;
		}
		return me.speed.getValue();
	},

	getBearing: func {
		# This is an instant perfect result, so don't call this outside the radar system.
		return self.getCoord().course_to(me.getCoord());
	},

	getElevation: func {
		# This is an instant perfect result, so don't call this outside the radar system.
		return vector.Math.getPitch(self.getCoord(), me.getCoord());
	},

	getDeviation: func {
		# This is an instant perfect result, so don't call this outside the radar system.
		# optimized method that return both heading and pitch deviation as seen from pilot, to limit property calls
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

	isSpikingMe: func {
		if (me.str6 != nil and me.str6.getValue() != nil and me.str6.getValue() != "" and size(""~me.str6.getValue())==4 and left(md5(self.getCallsign()),4) == me.str6.getValue()) {
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
	
	isHiddenFromDoppler: func (dopplerRadar = 1) {
		return me.getType() == AIR and (dopplerRadar?me.hiddenFromDoppler:me.hiddenFromMono);
	},

	setHiddenFromDoppler: func (dopp, mono) {
		me.hiddenFromDoppler = dopp;
		me.hiddenFromMono = mono;
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

	blep: func (time, searchInfo, strength, stt) {
		# Don't call this outside the radar system.
		# searchInfo:               dist, groundtrack, deviations, speed, closing-rate, altitude
		# blep: time, rcs_strength, dist, heading, deviations vector, speed, closing-rate, altitude, coord, stt
		var newArray = [];
		var value = 0;
		me.getCoord();
		var ownship = self.getCoord();
		append(newArray, time);#0 time this blep was detected
		append(newArray, strength);#1
		if (searchInfo[0]) {
			value = ownship.direct_distance_to(me.coord);
			append(newArray, value);#2 dist in m
		} else {
			append(newArray, nil);#2
		}
		if (searchInfo[1]) {
			value = me.getHeading();
			append(newArray, value);#3 heading
			me.lastRegisterWasTrack = 1;
		} else {
			append(newArray, nil);#3
			me.lastRegisterWasTrack = 0;
		}
		if (searchInfo[2]) {
			value = [me.getDeviationHeading(), me.getDeviationPitch(), me.getBearing(), me.getElevation()];
			append(newArray, value);#4 deviations and absolutes
		} else {
			append(newArray, nil);#4
		}
		if (searchInfo[3]) {
			value = me.getSpeed();#kt
			append(newArray, value);#5 speed kt
		} else {
			append(newArray, nil);#5
		}
		if (searchInfo[4]) {
			#var bearing = ownship.course_to(me.coord);
			#var rbearing = bearing+180;
			#var ownship_spd = self.getSpeed() * math.cos( -(bearing - self.getHeading()) * D2R);
            #var target_spd  = me.getSpeed()   * math.cos( -(rbearing - me.getHeading()) * D2R);
			#value = ownship_spd + target_spd;
			append(newArray, me.getClosureRate());#6 closure-rate
		} else {
			append(newArray, nil);#6
		}
		if (searchInfo[5]) {
			value = me.coord.alt()*M2FT;
			append(newArray, value);#7 alt in ft
		} else {
			append(newArray, nil);#7
		}
		append(newArray, me.coord);#8 coord
		append(newArray, stt);#9 if was detected in a STT or FTT mode.
		append(me.bleps, Blep.new(newArray));
	},

	getBleps: func {
		# get the frozen info needed for displays
		# blep: time, rcs_strength, dist, heading, deviations vector, speed, closing-rate, altitude
		return me.bleps;
	},

	getLastBlep: func {
		# get the frozen info needed for displays
		#
		if (!size(me.bleps)) return nil;
		return me.bleps[size(me.bleps)-1];
	},

	setBleps: func (bleps_cleaned) {
		# call this after pruning the bleps
		me.bleps = bleps_cleaned;
	},

	hasTrackInfo: func {
		# convinience method
		if (size(me.bleps)) {
			if (me.bleps[size(me.bleps)-1].hasTrackInfo()) {
				return 1;
			}
		}
		return 0;
	},

	hasSTT: func {
		# convinience method
		if (size(me.bleps)) {
			return me.bleps[size(me.bleps)-1].hasSTT();
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
		# get the frozen info needed for main radar
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

	getLastHeading: func {
		if (size(me.bleps)) {
			return me.bleps[size(me.bleps)-1].getHeading();
		}
		return nil;
	},	

	getLastSpeed: func {
		if (size(me.bleps)) {
			return me.bleps[size(me.bleps)-1].getSpeed();
		}
		return nil;
	},	

	getLastDirection: func {
		# Deprecated
		if (size(me.bleps)) {
			return me.bleps[size(me.bleps)-1].getDirection();
		}
		return nil;
	},

	getLastAZDeviation: func {
		if (size(me.bleps)) {
			return me.bleps[size(me.bleps)-1].getAZDeviation();
		}
		return nil;
	},

	getLastElevDeviation: func {
		if (size(me.bleps)) {
			return me.bleps[size(me.bleps)-1].getElevDeviation();
		}
		return nil;
	},

	getLastElev: func {
		if (size(me.bleps)) {
			return me.bleps[size(me.bleps)-1].getElev();
		}
		return nil;
	},

	getLastRangeDirect: func {
		if (size(me.bleps)) {
				return me.bleps[size(me.bleps)-1].getRangeDirect();
		}
		return nil;
	},

	getLastAltitude: func {
		if (size(me.bleps)) {
				return me.bleps[size(me.bleps)-1].getAltitude();
		}
		return nil;
	},

	getLastCoord: func {
		if (size(me.bleps)) {
			return me.bleps[size(me.bleps)-1].getCoord();
		}
		return nil;
	},

	getLastBlepTime: func {
		if (size(me.bleps)) {
				return me.bleps[size(me.bleps)-1].getBlepTime();
		}
		return -1000;
	},

	getLastClosureRate: func {
		if (size(me.bleps)) {
				me.clr = me.bleps[size(me.bleps)-1].getClosureRate();
				return me.clr==nil?0:me.clr;
		}
		return 0;
	},

	getClosureRate: func {
		# This is an instant perfect result, so don't call this outside the radar system.
		# used in RWR. TODO: rework so this doesn't have to be called.		
		me.selfCo = self.getCoord();

		# Get contact velocity and direction to contact in geo centered coordinate system, so we get earth curvature factored in  (This can mean some tens of knots difference at 100+ nm, is this really needed?)
		me.velocityOfContact = vector.Math.vectorToGeoVector(vector.Math.getCartesianVelocity(me.get_heading(), me.get_Pitch(), me.get_Roll(), me.get_uBody(), me.get_vBody(), me.get_wBody()), me.selfCo).vector;
		me.vectorToContact   = [me.selfCo.x() - me.getCoord().x(), me.selfCo.y() - me.coord.y(), me.selfCo.z() - me.coord.z()];

		# Get ownship velocity and direction to ownship in geo centered coordinate system
		me.velocityOfOwnship = vector.Math.vectorToGeoVector(self.getSpeedVector(), self.getCoord()).vector;
		me.vectorToOwnship = vector.Math.product(-1, me.vectorToContact);

		me.contactVelocityTowardsOwnship = vector.Math.projVectorOnVector(me.velocityOfContact, me.vectorToOwnship);
		me.ownshipVelocityTowardsContact = vector.Math.projVectorOnVector(me.velocityOfOwnship, me.vectorToContact);

		return MPS2KT*(vector.Math.magnitudeVector(me.contactVelocityTowardsOwnship)+vector.Math.magnitudeVector(me.ownshipVelocityTowardsContact));
	},


#  ██     ██ ███████  █████  ██████   ██████  ███    ██     ███    ███ ███████ ████████ ██   ██  ██████  ██████  ███████ 
#  ██     ██ ██      ██   ██ ██   ██ ██    ██ ████   ██     ████  ████ ██         ██    ██   ██ ██    ██ ██   ██ ██      
#  ██  █  ██ █████   ███████ ██████  ██    ██ ██ ██  ██     ██ ████ ██ █████      ██    ███████ ██    ██ ██   ██ ███████ 
#  ██ ███ ██ ██      ██   ██ ██      ██    ██ ██  ██ ██     ██  ██  ██ ██         ██    ██   ██ ██    ██ ██   ██      ██ 
#   ███ ███  ███████ ██   ██ ██       ██████  ██   ████     ██      ██ ███████    ██    ██   ██  ██████  ██████  ███████ 
#                                                                                                                        
#                                                                                                                        

	get_type: func {
		me.getType();
	},
	getUnique: func {
		return me.callsign ~ me.model ~ me.ainame ~ me.sign ~ me.aitype ~ me.subid ~ me.prop.getName();
	},
	isValid: func {
		if (!me.valid.getValue() and me["dlinkNode"] != nil) {
			# This will make sure when a MP pilot switches aircraft type that the new does not inherit the datalink setting from the prev. type
			me.dlinkNode.clearValue();
		}
		me.valid.getValue();
	},
	get_bearing: func {
		me.getBearing();
	},
	get_Callsign: func {
		if (me.callsign != "") {
			return me.callsign;
		}
		if (me.ainame != "") {
			return me.ainame;
		}
		if (me.model != "") {
			return me.model;
		}
		return me.aitype;
	},
	get_range: func {
		me.getRange()*M2NM;
	},
	get_Coord: func {
		return me.getCoord();
	},
	get_Pitch: func {
		me.getPitch();
	},
	get_altitude: func {
		me.alt.getValue();
	},
	get_Speed: func {
		me.getSpeed();
	},
	get_heading: func {
		me.getHeading();
	},
	get_Roll: func {
		return me.getRoll();
	},
	get_uBody: func {
		var body = nil;
		if (me.uBody != nil) {
			body = me.uBody.getValue();
		}
		if(body == nil) {
			body = me.get_Speed()*KT2FPS;
		}
		return body;
	},
	get_vBody: func {
		if (me.vBody == nil) return 0;
		me.vB = me.vBody.getValue();
		if (me.vB == nil) return 0;
		return me.vB;
	},
	get_wBody: func {
		if (me.wBody == nil) return 0;
		me.wB = me.wBody.getValue();
		if (me.wB == nil) return 0;
		return me.wB;
	},
	getFlareNode: func {
		if (me["flareProp"] == nil) {
			me.flareProp = me.prop.getNode(flareProp, 0);
		}
		return me.flareProp;
	},
	getChaffNode: func {
		if (me["chaffProp"] == nil) {
			me.chaffProp = me.prop.getNode(chaffProp, 0);
		}
		return me.chaffProp;
	},
	isPainted: func {
		# Only when single-target-track
		return me.hasSTT() and elapsedProp.getValue() - me.getLastBlepTime() < 0.75;
	},
	isLaserPainted: func {
		if (!laserOn.getValue()) return 0;
		if (me.getType() == POINT) return 1;
		return me.isPainted();
	},
	isRadiating: func (coord) {
		me.rn = coord.direct_distance_to(me.get_Coord()) * M2NM;
        if (!isOmniRadiating(me.model)) {
            me.bearingR = me.coord.course_to(coord);
            me.headingR = me.get_heading();
            me.deviationRd = me.bearingR - me.headingR;
        } else {
            me.deviationRd = 0;
        }
        if (me.rn < getRadarRange(me.model) and ((me.rdr != nil and me.rdr.getValue()!=1) or me.rdr == nil) and math.abs(geo.normdeg180(me.deviationRd)) < getRadarFieldRadius(me.model)) {
            # our radar is active and pointed at coord.
            return 1;
        }
        return 0;
	},
	isVirtual: func {
		return 0;
	},
	get_closure_rate: func {
		me.getClosureRate();
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













var Radar = {
	# root radar class
	#
	# Attributes:
	#   on/off
	enabled: 1,
};


#  ██████   █████  ██████  ████████ ██ ████████ ██  ██████  ███    ██ 
#  ██   ██ ██   ██ ██   ██    ██    ██    ██    ██ ██    ██ ████   ██ 
#  ██████  ███████ ██████     ██    ██    ██    ██ ██    ██ ██ ██  ██ 
#  ██      ██   ██ ██   ██    ██    ██    ██    ██ ██    ██ ██  ██ ██ 
#  ██      ██   ██ ██   ██    ██    ██    ██    ██  ██████  ██   ████ 
#                                                                     
#                                                                     
var NoseRadar = {
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
			if (filter_sea and theType == TERRASUNK) continue;
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
			me.contactDev = {
				parents: [Deviation],
				azimuthLocal: me.dev[0],
				elevationLocal: me.dev[1],
				rangeDirect_m: me.rng,
				coord: contact.getCoord(),
				heading: contact.getHeading(),
				pitch: contact.getPitch(),
				roll: contact.getRoll(),
				bearing: contact.getBearing(),
				elevationGlobal: contact.getElevation(),
				#frustum_norm_y: -me.pc_y/(me.w/2),
				#frustum_norm_z: me.pc_z/(me.h/2),
				#alt_ft: me.crd.alt()*M2FT,
				speed_kt: contact.getSpeed(),
				#closureSpeed: contact.getClosureRate(),
			};
			contact.storeDeviation(me.contactDev);
			append(me.vector_aicontacts_for, contact);
		}		
		emesary.GlobalTransmitter.NotifyAll(me.FORNotification.updateV(me.vector_aicontacts_for));
		#print("In Field of Regard: "~size(me.vector_aicontacts_for));
	},

	scanSingleContact: func (contact) {
		if (!me.enabled) return;
		if (contact == nil) {return;}
		# called on demand
		
		if (!contact.isVisible()) {  # moved to nose radar. TODO: WHy double it in discradar? hmm, dont matter so much, its lightning fast
			emesary.GlobalTransmitter.NotifyAll(me.FORNotification.updateV([]));
			return;
		}
		me.vector_aicontacts_for = [];
		me.dev = contact.getDeviation();
		me.rng = contact.getRangeDirect();
		me.crd = contact.getCoord();
		me.contactDev = {
			parents: [Deviation],
			azimuthLocal: me.dev[0],
			elevationLocal: me.dev[1],
			rangeDirect_m: me.rng,
			coord: me.crd,
			heading: contact.getHeading(),
			pitch: contact.getPitch(),
			roll: contact.getRoll(),
			bearing: contact.getBearing(),
			elevationGlobal: contact.getElevation(),
			#frustum_norm_y: 0,
			#frustum_norm_z: 0,
			#alt_ft: me.crd.alt()*M2FT,
			speed_kt: contact.getSpeed(),
			#closureSpeed: contact.getClosureRate(),
		};
		contact.storeDeviation(me.contactDev);
		append(me.vector_aicontacts_for, contact);

		emesary.GlobalTransmitter.NotifyAll(me.FORNotification.updateV(me.vector_aicontacts_for));
		#print("In Field of Regard: "~size(me.vector_aicontacts_for));
	},

	del: func {
        emesary.GlobalTransmitter.DeRegister(me.NoseRadarRecipient);
    },
};


var SimplerNoseRadar = {
	# I partition the sky into the field of regard and preserve the contacts in that field for it to be scanned by ActiveDiscRadar or similar
	#
	# Does the same as NoseRadar, but ignore elevations and stuff. Simpler, faster.
	new: func () {
		var nr = {parents: [SimplerNoseRadar, Radar]};

		nr.vector_aicontacts = [];
		nr.vector_aicontacts_for = [];

		nr.NoseRadarRecipient = emesary.Recipient.new("SimplerNoseRadarRecipient");
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
	    		    me.radar.scanFOR(notification.yaw_radius, notification.dist_m, notification.fa, notification.fg, notification.fs);
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

	scanFOR: func (yaw_radius, dist_m, filter_air, filter_gnd, filter_sea) {
		if (!me.enabled) return;
		#iterate:
		# check direct distance
		# check field of regard
		# sort in bearing?
		# called on demand
		# TODO: vectorized field instead
		me.owncrd = geo.aircraft_position();

		me.vector_aicontacts_for = [];
		foreach(contact ; me.vector_aicontacts) {
			var theType = contact.getType();
			if (filter_air and theType == AIR) continue;
			if (filter_gnd and theType == SURFACE) continue;
			if (filter_sea and theType == MARINE) continue;
			if (filter_sea and theType == TERRASUNK) continue;
			if (theType == ORDNANCE) continue;

			if (!contact.isVisible()) {  # moved to nose radar. TODO: WHy double it in discradar? hmm, dont matter so much, its lightning fast
				continue;
			}

			me.rng = contact.getRangeDirect();
			if (me.rng > dist_m) {
				continue;
			}
			me.crd = contact.getCoord();

			if (math.abs(contact.getDeviationHeading()) > yaw_radius) {
				continue;
			}

			me.dev = contact.getDeviation();

			# TODO: clean this up. Only what is needed for testing against instant FoV and RCS should be in here:
			me.contactDev = {
				parents: [Deviation],
				azimuthLocal: me.dev[0],
				elevationLocal: me.dev[1],
				rangeDirect_m: me.rng,
				coord: me.crd,
				heading: contact.getHeading(),
				pitch: contact.getPitch(),
				roll: contact.getRoll(),
				bearing: contact.getBearing(),
				elevationGlobal: contact.getElevation(),
				#frustum_norm_y: 0,
				#frustum_norm_z: 0,
				#alt_ft: me.crd.alt()*M2FT,
				speed_kt: contact.getSpeed(),
				#closureSpeed: contact.getClosureRate(),
			};
			contact.storeDeviation(me.contactDev);
			append(me.vector_aicontacts_for, contact);
		}		
		emesary.GlobalTransmitter.NotifyAll(me.FORNotification.updateV(me.vector_aicontacts_for));
		#print("In Field of Regard: "~size(me.vector_aicontacts_for));
	},

	scanSingleContact: func (contact) {
		if (!me.enabled) return;
		if (contact == nil) {return;}
		# called on demand
		
		if (!contact.isVisible()) {  # moved to nose radar. TODO: Why double it in discradar? hmm, dont matter so much, its lightning fast
			emesary.GlobalTransmitter.NotifyAll(me.FORNotification.updateV([]));
			return;
		}
		me.vector_aicontacts_for = [];
		me.dev = contact.getDeviation();
		me.rng = contact.getRangeDirect();
		me.crd = contact.getCoord();
		me.contactDev = {
			parents: [Deviation],
			azimuthLocal: me.dev[0],
			elevationLocal: me.dev[1],
			rangeDirect_m: me.rng,
			coord: me.crd,
			heading: contact.getHeading(),
			pitch: contact.getPitch(),
			roll: contact.getRoll(),
			bearing: contact.getBearing(),
			elevationGlobal: contact.getElevation(),
			#frustum_norm_y: 0,
			#frustum_norm_z: 0,
			#alt_ft: me.crd.alt()*M2FT,
			speed_kt: contact.getSpeed(),
			#closureSpeed: contact.getClosureRate(),
		};
		contact.storeDeviation(me.contactDev);
		append(me.vector_aicontacts_for, contact);

		emesary.GlobalTransmitter.NotifyAll(me.FORNotification.updateV(me.vector_aicontacts_for));
		#print("In Field of Regard: "~size(me.vector_aicontacts_for));
	},

	del: func {
        emesary.GlobalTransmitter.DeRegister(me.NoseRadarRecipient);
    },
};



#  ██████   ██████   ██████      ██████   █████  ██████   █████  ██████  
#       ██ ██       ██  ████     ██   ██ ██   ██ ██   ██ ██   ██ ██   ██ 
#   █████  ███████  ██ ██ ██     ██████  ███████ ██   ██ ███████ ██████  
#       ██ ██    ██ ████  ██     ██   ██ ██   ██ ██   ██ ██   ██ ██   ██ 
#  ██████   ██████   ██████      ██   ██ ██   ██ ██████  ██   ██ ██   ██ 
#                                                                        
#                                                                        
var FullRadar = {
	# 360 degree coverage air radar, for use by SAMs and other surface radars.
	new: func () {
		var nr = {parents: [FullRadar, Radar]};

		nr.vector_aicontacts = [];
		nr.vector_aicontacts_for = [];

		nr.FullRadarRecipient = emesary.Recipient.new("FullRadarRecipient");
		nr.FullRadarRecipient.radar = nr;
		nr.FullRadarRecipient.Receive = func(notification) {
	        if (notification.NotificationType == "AINotification") {
	        	#printf("NoseRadar recv: %s", notification.NotificationType);
	            if (me.radar.enabled == 1) {
	    		    me.radar.vector_aicontacts = notification.vector;
	    	    }
	            return emesary.Transmitter.ReceiptStatus_OK;
	        } elsif (notification.NotificationType == "RequestFullNotification") {
	        	#printf("NoseRadar recv: %s", notification.NotificationType);
	            if (me.radar.enabled == 1) {
	    		    me.radar.scanFOR(notification.max_range);
	    	    }
	            return emesary.Transmitter.ReceiptStatus_OK;
	        } elsif (notification.NotificationType == "Contact360Notification") {
	        	#printf("FullRadar recv: %s", notification.NotificationType);
	            if (me.radar.enabled == 1) {
	    		    me.radar.scanSingleContact(notification.vector[0]);
	    	    }
	            return emesary.Transmitter.ReceiptStatus_OK;
	        }
	        return emesary.Transmitter.ReceiptStatus_NotProcessed;
	    };
		emesary.GlobalTransmitter.Register(nr.FullRadarRecipient);
		nr.FORNotification = VectorNotification.new("FORNotification");
		nr.FullNotification = VectorNotification.new("FullNotification");
		nr.FullNotification.updateV(nr.vector_aicontacts_for);
		#nr.timer.start();
		return nr;
	},

	scanFOR: func (max_range) {
		if (!me.enabled) return;
		#iterate:
		# check direct distance
		# called on demand
		# TODO: vectorized field instead

		me.vector_aicontacts_for = [];
		foreach(contact ; me.vector_aicontacts) {
			var theType = contact.getType();

			if (theType == SURFACE) continue;
			if (theType == MARINE) continue;
			if (theType == TERRASUNK) continue;
			if (theType == ORDNANCE) continue;

			me.rng = contact.getRangeDirect();

			if (me.rng * M2NM > max_range) {
				continue;
			}

			if (!contact.isVisible()) {
				continue;
			}

			me.dev = contact.getDeviation();
			

			me.crd = contact.getCoord();

			# TODO: clean this up. Only what is needed for testing against instant FoV and RCS should be in here:
			me.contactDev = {
				parents: [Deviation],
				azimuthLocal: me.dev[0],
				elevationLocal: me.dev[1],
				rangeDirect_m: me.rng,
				coord: me.crd,
				heading: contact.getHeading(),
				pitch: contact.getPitch(),
				roll: contact.getRoll(),
				bearing: contact.getBearing(),
				elevationGlobal: contact.getElevation(),
				#frustum_norm_y: 0,
				#frustum_norm_z: 0,
				#alt_ft: me.crd.alt()*M2FT,
				speed_kt: contact.getSpeed(),
				#closureSpeed: contact.getClosureRate(),
			};
			contact.storeDeviation(me.contactDev);
			append(me.vector_aicontacts_for, contact);
		}		
		emesary.GlobalTransmitter.NotifyAll(me.FullNotification.updateV(me.vector_aicontacts_for));
		#print("In Field of Regard: "~size(me.vector_aicontacts_for));
	},

	scanSingleContact: func (contact) {# TODO: rework this method (If its even needed anymore)
		if (!me.enabled) return;
		# called on demand
		var theType = contact.getType();

		if (theType == SURFACE or theType == MARINE or theType == TERRASUNK or theType == ORDNANCE) {
			emesary.GlobalTransmitter.NotifyAll(me.FORNotification.updateV([]));
			return;
		}

		if (!contact.isVisible()) {  # moved to nose radar. TODO: WHy double it in discradar? hmm, dont matter so much, its lightning fast
			emesary.GlobalTransmitter.NotifyAll(me.FORNotification.updateV([]));
			return;
		}

		me.vector_aicontacts_for = [];
		me.dev = contact.getDeviation();
		me.rng = contact.getRangeDirect();
		me.crd = contact.getCoord();
		me.contactDev = {
			parents: [Deviation],
			azimuthLocal: me.dev[0],
			elevationLocal: me.dev[1],
			rangeDirect_m: me.rng,
			coord: me.crd,
			heading: contact.getHeading(),
			pitch: contact.getPitch(),
			roll: contact.getRoll(),
			bearing: contact.getBearing(),
			elevationGlobal: contact.getElevation(),
			#frustum_norm_y: 0,
			#frustum_norm_z: 0,
			#alt_ft: me.crd.alt()*M2FT,
			speed_kt: contact.getSpeed(),
			#closureSpeed: contact.getClosureRate(),
		};
		contact.storeDeviation(me.contactDev);
		append(me.vector_aicontacts_for, contact);

		emesary.GlobalTransmitter.NotifyAll(me.FORNotification.updateV(me.vector_aicontacts_for));
		#print("In Field of Regard: "~size(me.vector_aicontacts_for));
	},

	del: func {
        emesary.GlobalTransmitter.DeRegister(me.FullRadarRecipient);
    },
};



#   ██████  ███    ███ ███    ██ ██ 
#  ██    ██ ████  ████ ████   ██ ██ 
#  ██    ██ ██ ████ ██ ██ ██  ██ ██ 
#  ██    ██ ██  ██  ██ ██  ██ ██ ██ 
#   ██████  ██      ██ ██   ████ ██ 
#                                   
#                                   
var OmniRadar = {
	# I check the sky 360 deg for anything potentially detectable by a passive radar system.
	new: func (rate, max_dist_nm, tp_dist_nm) {
		var omni = {parents: [OmniRadar, Radar]};
		
		omni.max_dist_nm = max_dist_nm;
		omni.tp_dist_nm  =  tp_dist_nm;#transponder detect distance
		
		omni.vector_aicontacts = [];
		omni.vector_aicontacts_for = [];
		omni.timer          = maketimer(rate, omni, func omni.scan());

		omni.OmniRadarRecipient = emesary.Recipient.new("OmniRadarRecipient");
		omni.OmniRadarRecipient.radar = omni;
		omni.OmniRadarRecipient.Receive = func(notification) {
	        if (notification.NotificationType == "AINotification") {
	        	#printf("OmniRadar recv: %s", notification.NotificationType);
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
		if (!me.enabled) return;
		me.vector_aicontacts_for = [];
		foreach(contact ; me.vector_aicontacts) {
			if (!contact.isVisible()) {
				# This is expensive as hell, so don't run OmniRadar with too high rate.
				continue;
			}
			me.ber = contact.getBearing();
			me.head = contact.getHeading();
			me.test = me.ber+180-me.head;
			me.tp = contact.isTransponderEnable();
			me.radar = contact.isRadarEnable();
			me.spiking = contact.isSpikingMe();
            if ((me.radar and math.abs(geo.normdeg180(me.test)) < getRadarFieldRadius(contact.getModel()) or (me.tp and contact.getRangeDirect()*M2NM < me.tp_dist_nm) or me.spiking) and contact.getRangeDirect()*M2NM < me.max_dist_nm) {
            	contact.storeThreat([me.ber,me.head,contact.getCoord(),me.tp,me.radar,contact.getDeviationHeading(),contact.getRangeDirect()*M2NM, contact.getCallsign(), contact.getSpeed(), contact.getClosureRate(), me.spiking]);
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
var TerrainChecker = {
	#
	# Everything here is CPU expensive.
	#
	new: func (rate, doppler_speed_kt=30) {
		var tc = {parents: [TerrainChecker]};

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
	    
		me.dopplerCanDetect = 0;
	    if(contact.getType() != AIR or !me.inClutter) {
	    	# Either no clutter behind or is not an air target so ground/sea radar needs to be able to see it.
	        me.dopplerCanDetect = 1;
	    } elsif (me.getTargetSpeedRelativeToClutter(contact) > me.doppler_speed_kt) {
	        me.dopplerCanDetect = 1;
	    }
	    contact.setHiddenFromDoppler(!me.dopplerCanDetect, me.inClutter);
	},
		
	getTargetSpeedRelativeToClutter: func (contact) {
		#
		# Seen from aircraft the terrain clutter is moving with a certain velocity vector depending on aircraft position, attitude and speed.
		# Same with any contact.
		# Here we see how the velocity of the contact moves in relation to the velocity of the terrain.
		# If it moves faster than me.doppler_speed_kt seen from the angle of the nose radar, then a doppler radar can see it. Else it just looks like clutter.
		#
		# Get contact velocity vector in relation to terrain
		me.vectorOfTargetSpeedRelativeToClutter = vector.Math.getCartesianVelocity(contact.get_heading(), contact.get_Pitch(), contact.get_Roll(), contact.get_uBody(), contact.get_vBody(), contact.get_wBody());

		# Convert it to earth centered coordinate system, so we get proper earth curvature into effect
		me.vectorOfTargetSpeedRelativeToClutter = vector.Math.vectorToGeoVector(me.vectorOfTargetSpeedRelativeToClutter, contact.getCoord()).vector;

		# Seen from the contact the clutter is not factored in
		# In other words, we ignore our own speed, pretend the clutter is still seen from us, and thus the contacts velocity in relation to clutter is just
		# the contacts velocity vector.

		# Vector from aircraft to contact
		me.vectorToTarget = vector.Math.eulerToCartesian3X(-contact.getBearing(), vector.Math.getPitch(self.getCoord(), contact.coord), 0);

		# Convert it to earth centered coordinate system
		me.vectorToTarget = vector.Math.vectorToGeoVector(me.vectorToTarget, self.getCoord()).vector;

		# Now lets look at the resulting vector and see how it looks from the radars point of view, as in how much velocity is pointed towards us.
		me.vectorOfTargetSpeedRelativeToClutterSeenFromRadar = vector.Math.projVectorOnVector(me.vectorOfTargetSpeedRelativeToClutter, me.vectorToTarget);
		# Doppler radars only dicern velocity as in closing rate of contact compared to closing rate of terrain, so we see how much velocity contact has towards us in relation to the clutter.
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







#  ███████  ██████ ███    ███ 
#  ██      ██      ████  ████ 
#  █████   ██      ██ ████ ██ 
#  ██      ██      ██  ██  ██ 
#  ███████  ██████ ██      ██ 
#                             
#                             
var ECMChecker = {
	#
	# Passive ECM only for now.
	# Does not detect own chaffs
	#
	new: func (rate, number_of_contacts_per_update) {
		var ecm = {parents: [ECMChecker]};

		ecm.maxCheck = number_of_contacts_per_update;
		ecm.vector_aicontacts = [];
		ecm.timer          = maketimer(rate, ecm, func ecm.scan());

		ecm.ChaffReleaseNotification = VectorNotification.new("ChaffReleaseNotification");
		ecm.ECMCheckerRecipient = emesary.Recipient.new("ECMCheckerRecipient");
		ecm.ECMCheckerRecipient.radar = ecm;
		ecm.ECMCheckerRecipient.Receive = func(notification) {
	        if (notification.NotificationType == "AINotification") {
	        	#printf("ECMRadar recv: %s", notification.NotificationType);
	    		me.radar.vector_aicontacts = notification.vector;
	    		me.radar.index = 0;
	            return emesary.Transmitter.ReceiptStatus_OK;
	        }
	        return emesary.Transmitter.ReceiptStatus_NotProcessed;
	    };
		emesary.GlobalTransmitter.Register(ecm.ECMCheckerRecipient);
		ecm.index = 0;
		ecm.timer.start();
		return ecm;
	},

	scan: func {
		me.myChaffs = [];
		me.elapsed = elapsedProp.getValue();
		for (me.i = 0; me.i < 3; me.i+=1) {
			me.scanOne();
			if (me.index == 0) break;
		}
		if (size(me.myChaffs)) {
			emesary.GlobalTransmitter.NotifyAll(me.ChaffReleaseNotification.updateV(me.myChaffs));
		}
	},

	scanOne: func () {
		# We only check a couple of aircraft per call
		if (me.index > size(me.vector_aicontacts)-1) {
			me.index = 0;
			return;
		}
		me.contact = me.vector_aicontacts[me.index];
		if (me.contact.isVisible()) {
			me.chaff = me.checkChaff(me.contact);
			if (me.chaff != nil) {
				append(me.myChaffs, me.chaff);
			}
		}

        me.index += 1;
        if (me.index > size(me.vector_aicontacts)-1) {
        	me.index = 0;
        }
	},
	
	checkChaff: func (contact) {
		me.node = contact.getChaffNode();
		if (me.node != nil and (contact["oldChaffTime"] == nil or me.elapsed - contact.oldChaffTime > 1)) {
			me.newValue = me.node.getValue();
			if (me.newValue != 0 and me.newValue != contact["oldChaffValue"]) {
				me.meters = contact.getRange();
				me.bearing = contact.getBearing();
				me.pitch = contact.getElevation();
				contact.oldChaffTime = me.elapsed;
				contact.oldChaffValue = me.newValue;

				return {parents: [Chaff], releaseTime: me.elapsed, meters: me.meters, bearing: me.bearing, pitch: me.pitch};
			}
		}
		return nil;
	},
	
	del: func {
        emesary.GlobalTransmitter.DeRegister(me.ECMCheckerRecipient);
    },
};






#  ███████ ██ ██   ██ ███████ ██████      ██████  ███████  █████  ███    ███ 
#  ██      ██  ██ ██  ██      ██   ██     ██   ██ ██      ██   ██ ████  ████ 
#  █████   ██   ███   █████   ██   ██     ██████  █████   ███████ ██ ████ ██ 
#  ██      ██  ██ ██  ██      ██   ██     ██   ██ ██      ██   ██ ██  ██  ██ 
#  ██      ██ ██   ██ ███████ ██████      ██████  ███████ ██   ██ ██      ██ 
#                                                                            
#                                                                            
var FixedBeamRadar = {

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






#   ██████  ██    ██ ███████ ██████  ██ ██████  ███████ ███████ 
#  ██    ██ ██    ██ ██      ██   ██ ██ ██   ██ ██      ██      
#  ██    ██ ██    ██ █████   ██████  ██ ██   ██ █████   ███████ 
#  ██    ██  ██  ██  ██      ██   ██ ██ ██   ██ ██           ██ 
#   ██████    ████   ███████ ██   ██ ██ ██████  ███████ ███████ 
#                                                               
#                                                               
var flareProp = "rotors/main/blade[3]/flap-deg";
var chaffProp = "rotors/main/blade[3]/position-deg";
var laserOn = nil;# set this to a prop
var sttSend = props.globals.getNode("sim/multiplay/generic/string[6]", 1);
var stbySend = props.globals.getNode("sim/multiplay/generic/int[2]", 1);
var elapsedProp = props.globals.getNode("sim/time/elapsed-sec", 0);
var enable_tacobject = 0;

var isOmniRadiating = func (model) {
	# Override this method in your aircraft to do this in another way
	# Return 1 if this contacts radar is not constricted to a cone.
	return model == "gci" or model == "S-75" or model == "buk-m2" or model == "MIM104D" or model == "missile_frigate" or model == "fleet" or model == "s-300" or model == "ZSU-23-4M";
}

var getRadarFieldRadius = func (model) {
	# Override this method in your aircraft to do this in another way
	return 60;
}

var getRadarRange = func (model) {
	# Override this method in your aircraft to do this in another way
	# Distance in nm that antiradiation weapons can home in on the the radiation.
	return 70;
}

var isKnownShip = func (model) {
	contains(knownShips, model);
}

var isKnownSurface = func (model) {
	contains(knownSurface, model);
}

var isKnownHeli = func (model) {
	contains(knownHelis, model);
}

var isKnownCarrier = func (model) {
	contains(knownCarriers, model);
}

var knownCarriers = {
	"mp-clemenceau": nil,
	"mp-eisenhower": nil,
	"mp-nimitz": nil,
	"mp-vinson": nil,
};

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

var knownHelis = {
    "SH-60J":                  nil,
    "UH-60J":                     nil,
    "uh1":                     nil,
    "212-TwinHuey":              nil,
    "412-Griffin":               nil,
    "ch53e":                     nil,
    "Mil-Mi-8":                  nil,
    "CH47":                     nil,
    "mi24":                     nil,
    "tigre":                     nil,
    "uh60_Blackhawk":             nil,
    "AH-1W":                       nil,
    "WAH-64_Apache":               nil,
    "rah-66":                      nil,
    "Gazelle":                     nil,
    "Westland_Gazelle":          nil,
    "AS532-Cougar":               nil,
    "Westland_SeaKing-HAR3":      nil,
    "Lynx-HMA8":                  nil,
    "Lynx_Wildcat":               nil,
    "Merlin-HM1":             nil,
    "OH-58D":                   nil,
};


# BUGS:
#
#
# IMPROVEMENTS:
#
# Max roll before no longer roll stabilized CRM. (mig21 too)
# Noseradar: round slice
# Noseradar: rotate FoR to avoid the factor. (beware of performance)
# Noseradar: purge storedDeviation of unneeded stuff once I know more about what Mig21 requires.
#
# FEATURES:
#
# Cloud/rain/snow interference. (for clouds will only really work with 3D clouds, as their positions is in property-tree, then can give them radius depending on type and do intersect test.)
# Use geodinfo to check clutter amount for GM radar. If static no need to check again.
#
# STEAL:
#
# Check out Mig-21 handling of contacts.
#