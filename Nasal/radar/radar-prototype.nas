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
#
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

var GEO = 0;
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
        new_class.slice = func (elev, yaw, elev_radius, yaw_radius, dist_m) {
	    	me.elev = elev;
	    	me.yaw = yaw;
	    	me.elev_radius = elev_radius;
	    	me.yaw_radius = yaw_radius;
	    	me.dist_m = dist_m;
	    	return me;
	    };
        return new_class;
    },
};

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
	new: func {
		me.prop_AIModels = props.globals.getNode("ai/models");
		me.vector_aicontacts = [];
		me.scanInProgress = 0;
		me.startOver = 0;
		me.lookupCallsign = {};
		me.AINotification = VectorNotification.new("AINotification");
		me.AINotification.updateV(me.vector_aicontacts);

		setlistener("/ai/models/model-added", func me.callReadTree());
		setlistener("/ai/models/model-removed", func me.callReadTree());
		me.loop = maketimer(300, me, func me.callReadTree());
		me.loop.start();
	},

	callReadTree: func {
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
	    	me.pos_type = GEO;
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
        	settimer(func me.readTreeFrame(),0);
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
        } elsif (ordnance != nil) {
        	return ORDNANCE;
        } elsif (me.name_prop == "groundvehicle") {
        	return SURFACE;
        } elsif (alt_ft < 3.0) {
        	return MARINE;
        } elsif (model != nil and contains(knownShips, model)) {
			return MARINE;
        } elsif (speed_kt != nil and speed_kt < 75) {
        	return nil;# to be determined later by doppler in Radar
        }
        return AIR;
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
};








Contact = {
# Attributes:
	getCoord: func {
	   	return geo.Coord.new();
	},
};


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

		# active radar:
		c.blepTime = 0;
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
		if (item.prop.getName() == me.prop.getName() and item.type == me.type and item.model == me.model and item.callsign == me.callsign) {
			return TRUE;
		}
		return FALSE;
	},

	getCoord: func {
		if (me.pos_type = GEO) {
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
		return [geo.normdeg180(me.acCoord.course_to(me.coord)-self.getHeading()), vector.Math.getPitch(me.acCoord, me.coord) - self.getPitch(),me.acCoord.direct_distance_to(me.coord),me.coord];
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

	storeDeviation: func (dev) {
		# [bearingDev, elevationDev, distDirect, coord, heading, pitch, roll]
		# should really be a hash instead of vector
		me.devStored = dev;
	},
	
	getDeviationStored: func {
		# get the frozen info needed for radar
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

	blep: func (time, azimuth, strength, lock) {
		me.blepTime = time;
		#me.headingFrozen = me.getHeading();
		me.azi = azimuth;# If azimuth is available (only lock and TWS gives it)
		me.strength = strength;#rcs
		#if (lock) {
		#	me.d = me.getDeviation();
		#	me.storeDeviation([me.d[0], me.d[1], me.d[2], me.coord, me.getHeading(), me.getPitch(), me.getRoll()]);
		#}
		me.coordFrozen = me.devStored[3]; #me.getCoord(); this is just cause Im am too lazy to change methods.
	},

	# in the radars, only call methods below this line:

	isInfoExtended: func {
		# If this contact is either locked or picked up by TWS (at medium range), return true.
		#
		# extended means the following should be available to display in cockpit: (beside the deviation angles and range)
		# heading, velocity, pitch
		#
		return me.azi;
	},

	getDeviationPitchFrozen: func {
		me.pitched = vector.Math.getPitch(self.getCoord(), me.coordFrozen);
		return me.pitched - self.getPitch();
		#return me.devStored[1];
	},

	getDeviationHeadingFrozen: func {#is really bearing, should be renamed.
		return self.getCoord().course_to(me.coordFrozen)-self.getHeading();
		#return me.devStored[0];
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

	getModel: func {
		return me.model;
	}
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

NoseRadar = {
	# I partition the sky into the field of regard and preserve the contacts in that field for it to be scanned by ActiveDiscRadar or similar
	new: func (range_m, radius, rate) {
		var nr = {parents: [NoseRadar, Radar]};

		nr.forRadius_deg  = radius;
		nr.forDist_m      = range_m;#range setting
		nr.vector_aicontacts = [];
		nr.vector_aicontacts_for = [];
		#nr.timer          = maketimer(rate, nr, func nr.scanFOR());

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
	    		    me.radar.scanFOR(notification.elev, notification.yaw, notification.elev_radius, notification.yaw_radius, notification.dist_m);
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

	scanFOR: func (elev, yaw, elev_radius, yaw_radius, dist_m) {
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
			if (!contact.isVisible()) {  # moved to nose radar
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

			contact.storeDeviation([me.dev[0],me.dev[1],me.rng,contact.getCoord(),contact.getHeading(), contact.getPitch(), contact.getRoll(), contact.getBearing(), contact.getElevation()]);
			append(me.vector_aicontacts_for, contact);
		}		
		emesary.GlobalTransmitter.NotifyAll(me.FORNotification.updateV(me.vector_aicontacts_for));
		#print("In Field of Regard: "~size(me.vector_aicontacts_for));
	},

	scanSingleContact: func (contact) {
		# called on demand
		me.vector_aicontacts_for = [];
		me.dev = contact.getDeviation();
		me.rng = contact.getRangeDirect();
		contact.storeDeviation([me.dev[0],me.dev[1],me.rng,contact.getCoord(),contact.getHeading(), contact.getPitch(), contact.getRoll()]);#TODO: store approach velocity also
		append(me.vector_aicontacts_for, contact);

		emesary.GlobalTransmitter.NotifyAll(me.FORNotification.updateV(me.vector_aicontacts_for));
		#print("In Field of Regard: "~size(me.vector_aicontacts_for));
	},
};



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
};




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
};




var NONE = 0;
var SOFT = 1;#TWS mode only. Gives so much info that some missiles like Amraam can actually be fired. Unlike real lock, opponent wont know he is locked. Shorter range than real lock.
var HARD = 2;#real lock. Opponent RWR will go off. Sparrow missile needs this kind of lock.

var max_soft_locks = 8;
var time_to_keep_bleps = 6;# ActiveDiscRadar keeps the bleps for this duration
var time_to_fadeout_bleps = 5;# Used by the display that draws the bleps
var time_till_lose_lock_hard = 1.0;
var time_till_lose_lock_soft = 4.5;
var sam_radius_deg = 15;# in SAM mode it will scan the sky +- this number of degrees.
var myRadarDistance_m = 74000;
var myRadarStrength_rcs = 3.2;
var ext_info_rcs_factor = 0.65;# in TWS ext info only given if the signal times this factor is visible
var max_lock_range_nm = 40;

#air scan modes:
var TRACK_WHILE_SCAN = 2;# Gives velocity, angle, azimuth and range. Multiple soft locks. Short range. Fast.
#var SINGLE_TARGET_TRACK = 4;# focus on a contact. hard lock. Good for identification. Mid range.
var RANGE_WHILE_SEARCH = 1;# Gives range/angle info. Long range. Narrow bars.
#var SITUATION_AWARENESS_MODE = 3;# submode of RWS/TWS. A contact can be followed/selected while scan still being done that can show other bleps nearby.
#var VELOCITY_SEARCH = 0;# gives positive closure rate. Long range.



var ActiveDiscRadar = {
# inherits from Radar
# will check range, field of view/regard, ground occlusion and FCS.
# will also scan a field. And move that scan field as appropiate for scan mode.
# do not use directly, inherit and instance it.
# fast loop
#
# Attributes:
#   contact selection(s) of type Contact
#   soft/hard lock
#   painted (is the hard lock) of type Contact
	new: func () {
		var ar = {parents: [ActiveDiscRadar, Radar]};
		ar.timer          = maketimer(1, ar, func ar.loop());
		ar.lock           = NONE;# NONE, SOFT, HARD
		ar.locks          = [];# vector of current locks
		ar.follow         = [];# main SAM lock
		ar.vector_aicontacts_for = [];# vector of contacts found in field of regard
		ar.vector_aicontacts_bleps = [];# vector of not timed out bleps
		ar.scanMode       = RANGE_WHILE_SEARCH;
		ar.scanType       = AIR;# not used yet
		ar.directionX     = 1;# 1 for left to right, -1 for right to left current antenea movement
		ar.patternBar     = 0;# current bar index being scanned
		ar.barOffset      = 0;# offset all bars up or down.

		# these should be init in the actual radar:
		ar.discSpeed_dps  = 1;# radar disc movement speed
		ar.fovRadius_deg  = 1;# radius of square that the radar can detect where its currently pointed.
		ar.calcLoop();
		ar.calcBars();
		ar.pattern        = [-1,1,[0]];# bar field left, bar field right, vector of bars 0=-4 7=+4
		ar.pattern_move   = [-1,1,[0]];# temp pattern to move on when lock/SAM
		ar.forDist_m      = 1;#current radar range setting.
		
		
		ar.posE           = ar.bars[ar.pattern[2][ar.patternBar]];# current disc position vertical
		ar.posH           = ar.pattern[0];# current disc position horizontal

		ar.lockX = 1;# for hard locks these are 1 or -1 depending on where in relation to the lock thats being scanned.
		ar.lockY = 1;
		ar.posHLast = ar.posH;
		ar.skipLoop = 0;

		# emesary
		ar.SliceNotification = SliceNotification.new();
		ar.ContactNotification = VectorNotification.new("ContactNotification");
		ar.ActiveDiscRadarRecipient = emesary.Recipient.new("ActiveDiscRadarRecipient");
		ar.ActiveDiscRadarRecipient.radar = ar;
		ar.ActiveDiscRadarRecipient.Receive = func(notification) {
	        if (notification.NotificationType == "FORNotification") {
	        	#printf("DiscRadar recv: %s", notification.NotificationType);
	            if (me.radar.enabled == 1) {
	    		    me.radar.vector_aicontacts_for = notification.vector;
	    		    me.radar.forWasScanned();
	    	    }
	            return emesary.Transmitter.ReceiptStatus_OK;
	        }
	        return emesary.Transmitter.ReceiptStatus_NotProcessed;
	    };
		emesary.GlobalTransmitter.Register(ar.ActiveDiscRadarRecipient);
		ar.timer.start();
    	return ar;
	},

	calcBars: func {
		# must be called each time fovRadius_deg is changed.
		# the elevation bars is stacked on top of each other. from bar -4 to bar +8.
		# override this method for radar with different number of bars.
		me.bars           = [-me.fovRadius_deg*7,-me.fovRadius_deg*5,-me.fovRadius_deg*3,-me.fovRadius_deg,me.fovRadius_deg,me.fovRadius_deg*3,me.fovRadius_deg*5,me.fovRadius_deg*7];
	},

	calcLoop: func {
		# must be called each time fovRadius_deg or discSpeed_dps is changed.
		# to simplify and for performance, we move the disc one beam width in each loop,
		# therefore the loop time must be calibrated to that.
		# If FPS is so low it cannot keep up, it will start scanning 2 beam widths at a time.
		# this also means the time to scan a bar migth vary a bit depending on framerate. Is this acceptable?
		# Maybe not, but can always build a smarter system that scan beamwidth*X, where X depend on FPS.
		
		# 1 second to do 1 bar:
		me.loopSpeed      = 1/(me.discSpeed_dps/(me.fovRadius_deg*2));
		me.timer.restart(me.loopSpeed);
		#print("loop: "~me.loopSpeed);
	},

	loop: func {
		if (!me.skipLoop and me.enabled) {#skipping loop while we wait for notification from NoseRadar. (I know its synchronious now, but it might change)
			#me.calcPattern();# must tell if pattern was changed  commented, as I dont remember what this line was supposed to do.
			me.moveDisc();
			me.scanFOV();
			if (me.lock == HARD) {
				me.purgeLock(time_till_lose_lock_hard);
			} else {
				me.purgeLocks(time_till_lose_lock_soft);
			}
		}
	},

	forWasScanned: func {
		# this method was originally called every time a full scan of all bars was done, now its every time we receive a new bar to scan from NoseRadar.
		#ok, lets clean up old bleps:
		me.vector_aicontacts_bleps_tmp = [];
		me.elapsed = getprop("sim/time/elapsed-sec");
		foreach(contact ; me.vector_aicontacts_bleps) {
			if (me.elapsed - contact.blepTime < time_to_keep_bleps) {
				append(me.vector_aicontacts_bleps_tmp, contact);
			}
		}
		me.vector_aicontacts_bleps = me.vector_aicontacts_bleps_tmp;
		if (size(me.follow) > 0 and !me.containsVector(me.vector_aicontacts_bleps, me.follow[0])) {
			# clean up old follow/SAM that hasn't been detected for a while.
			me.follow = [];
		}
		me.skipLoop = 0;
		me.scanFOV();#since we already have moved radar disc to new bar, we need this extra scan otherwise the disc will move and we will miss the start of the bar.
		# it also mean that as long as notifications is sent and recieved synhronious from NoseRadar, scanFov will be called twice for no reason,
		# since the first time there will be nothing to detect.
	},

	purgeLocks: func (time) {
		me.locks_tmp = [];
		me.elapsed = getprop("sim/time/elapsed-sec");
		foreach(contact ; me.locks) {
			if (me.elapsed - contact.blepTime < time and contact.isInfoExtended() == 1) {
				append(me.locks_tmp, contact);
			}
		}
		me.locks = me.locks_tmp;
		if (size(me.locks) == 0) {
			me.lock = NONE;
		}
		if (size(me.follow) > 0 and !me.containsVector(me.vector_aicontacts_bleps, me.follow[0])) {
			me.follow = [];
		}
	},

	purgeLock: func (time) {
		if (size(me.locks) == 1) {
			me.elapsed = getprop("sim/time/elapsed-sec");
			if (me.elapsed - me.locks[0].blepTime > time) {
				me.locks = [];
				me.lock = NONE;
				me.follow = [];
			} elsif (me.locks[0].getRangeDirect()*M2NM > max_lock_range_nm) {
				me.locks = [];
				me.lock = NONE;
			}
		} elsif (size(me.locks) == 0) {
			me.lock = NONE;
		}
	},
	
	moveDisc: func {
		# move the FOV inside the FOR
		#me.acPitch = getprop("orientation/pitch-deg");
		me.reset = 0;
		me.step = 1;
		me.pattern_move = [me.pattern[0],me.pattern[1],me.pattern[2]];# we move on a temp pattern, so we can revert to normal scan mode, after lock/follow.
		if (size(me.follow) > 0 and me.lock != HARD) {
			# scan follows selection (SAM)
			me.pattern_move[0] = me.follow[0].getDeviationHeadingFrozen()-sam_radius_deg;
			me.pattern_move[1] = me.follow[0].getDeviationHeadingFrozen()+sam_radius_deg;
			if (me.pattern_move[0] < -me.forRadius_deg) {
				me.pattern_move[0] = -me.forRadius_deg;
			}
			if (me.pattern_move[1] > me.forRadius_deg) {
				me.pattern_move[1] = me.forRadius_deg;
			}
		}
		if (me.lock != HARD) {
			# Normal scan
			me.reverted = 0;
			if (getprop("sim/time/delta-sec") > me.loopSpeed*1.5) {
				# hack for slow FPS
				me.step = 2;
			}		
			me.posH_new  = me.posH+me.directionX*me.fovRadius_deg*2*me.step;
			me.polarDist = math.sqrt(me.posH_new*me.posH_new+me.posE*me.posE);
			if (me.polarDist > me.forRadius_deg or (me.directionX==1 and me.posH_new > me.pattern_move[1]) or (me.directionX==-1 and me.posH_new < me.pattern_move[0])) {
				me.patternBar +=1;
				me.checkBarValid();
				me.nextBar();
				me.skipLoop = 1;
				emesary.GlobalTransmitter.NotifyAll(me.SliceNotification.slice(me.posE-me.fovRadius_deg,me.posE+me.fovRadius_deg, me.pattern_move[0],me.pattern_move[1],me.forDist_m));
			} else {
				me.posH = me.posH_new;
			}
		} else {
			# lock scan
			me.posH_n = me.locks[0].getDeviationHeadingFrozen()+me.lockX*me.fovRadius_deg*0.5;
			me.posE_n = me.locks[0].getDeviationPitchFrozen()+me.lockY*me.fovRadius_deg*0.5;
			if (me.forRadius_deg >= math.sqrt(me.posH_n*me.posH_n+me.posE_n*me.posE_n)) {
				me.posH = me.posH_n;
				me.posE = me.posE_n;
			}
			me.lockX *= -1;
			if (me.lockX == -1) {
				me.lockY *= -1;
				me.sendLockNotification();
			}
		}
		#printf("scanning %04.1f, %04.1f", me.posH, me.posE);
	},

	sendLockNotification: func {
		# this will update the lock unless its deviation angle rate is very very high, in which case we might lose the lock.
		emesary.GlobalTransmitter.NotifyAll(me.ContactNotification.updateV(me.locks));
		#emesary.GlobalTransmitter.NotifyAll(me.SliceNotification.slice(me.locks[0].getDeviationPitchFrozen()-me.fovRadius_deg*1.5,me.locks[0].getDeviationPitchFrozen()+me.fovRadius_deg*1.5, me.locks[0].getDeviationHeadingFrozen()-me.fovRadius_deg*1.5,me.locks[0].getDeviationHeadingFrozen()+me.fovRadius_deg*1.5,me.forDist_m));
	},

	checkBarValid: func {
		if (me.patternBar > size(me.pattern_move[2])-1) {
			me.patternBar = 0;
			me.reset = 1;# not used anymore
		}
	},

	nextBar: func {
		me.directionX *= -1;
		me.reverted = !me.reverted;
		me.posE = me.bars[me.pattern_move[2][me.patternBar]]+me.barOffset*me.fovRadius_deg*2;
		if (me.directionX == 1) {
			me.posH = me.pattern_move[0]+me.fovRadius_deg;
		} else {
			me.posH = me.pattern_move[1]-me.fovRadius_deg;
		}
		me.polarDist = math.sqrt(me.posH*me.posH+me.posE*me.posE);
		if (me.polarDist > me.forRadius_deg) {
			me.posH = -math.cos(math.asin(clamp(me.posE/me.pattern_move[1],-1,1)))*me.pattern_move[1]*me.directionX+me.directionX*me.fovRadius_deg;# disc set at beginning of new bar.
			if (me.posH < me.pattern_move[0] or me.posH > me.pattern_move[1]) {
				# we are so high or low on the circle and the bar is so small that there is no room to do this bar, so we skip to next.
				me.patternBar +=1;
				me.checkBarValid();
				me.nextBar();
			}
		}
	},

	scanFOV: func {
		#iterate:
		# check sensor field of view
		# check Terrain
		# check Doppler
		# due to FG Nasal update rate, we consider FOV square.
		# only detect 1 contact, even if more are present.
		foreach(contact ; me.vector_aicontacts_for) {
			me.dev = contact.getDeviationStored();
			me.contactPosH = me.dev[0];
			me.contactPosE = me.dev[1];
			if (me.contactPosE < me.posE+me.fovRadius_deg and me.contactPosE > me.posE-me.fovRadius_deg and (me.lock != HARD or me.forDist_m > me.dev[2])) {# since we don't get updates from NoseRadar while having lock, we need to check the range.
				# in correct elevation for detection
				me.doDouble = me.step == 2 and me.reverted == 0 and me.lock != HARD;
				if (!me.doDouble and me.contactPosH < me.posH+me.fovRadius_deg and me.contactPosH > me.posH-me.fovRadius_deg) {
					# detected
					if (me.registerBlep(contact)) {#print("detect-1 "~contact.callsign);
						break;# for AESA radar we should not break
					}
				} elsif (me.doDouble and me.directionX == 1 and me.contactPosH < me.posH+me.fovRadius_deg and me.contactPosH > me.posHLast+me.fovRadius_deg) {
					# detected
					if (me.registerBlep(contact)) {#print("detect-2 "~contact.callsign);
						break;# for AESA radar we should not break
					}
				} elsif (me.doDouble and me.directionX == -1 and me.contactPosH < me.posHLast-me.fovRadius_deg and me.contactPosH > me.posH-me.fovRadius_deg) {
					# detected
					if (me.registerBlep(contact)) {#print("detect-2 "~contact.callsign);
						break;# for AESA radar we should not break
					}
				}
			}
		}
		me.posHLast = me.posH;
	},

	registerBlep: func (contact) {
		me.strength = me.targetRCSSignal(self.getCoord(), me.dev[3], contact.model, contact.getHeadingFrozen(1), contact.getPitchFrozen(1), contact.getRollFrozen(1),myRadarDistance_m,myRadarStrength_rcs);
		#TODO: check Terrain, Doppler here.
		if (me.strength > me.dev[2]) {
			me.extInfo = (me.scanMode == TRACK_WHILE_SCAN and me.strength*ext_info_rcs_factor > me.dev[2] and size(me.locks)<max_soft_locks) or me.lock == HARD;
			contact.blep(getprop("sim/time/elapsed-sec"), me.extInfo, me.strength, me.lock==HARD);
			if (me.lock != HARD) {
				if (!me.containsVector(me.vector_aicontacts_bleps, contact)) {
					append(me.vector_aicontacts_bleps, contact);
				}
				if (me.extInfo and !me.containsVector(me.locks, contact)) {
					append(me.locks, contact);
					me.lock = SOFT;
				}
			}
			return 1;
		}
		return 0;
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
};



var RadarMode = {
	radar: nil,
	shortName: "",
	longName: "",
	superMode: nil,
	increaseRange: func {},
	decreaseRange: func {},
	setRange: func {},
	getRange: func {},
	leaveMode: func {},
};

var F16TWSMode = {
	radar: nil,
	shortName: "TWS",
	longName: "",
	superMode: nil,
	discSpeed_dps: 100,
	increaseRange: func {},
	decreaseRange: func {},
	setRange: func {},
	getRange: func {},
	leaveMode: func {},
};

var F16RWSMode = {
	radar: nil,
	shortName: "RWS",
	longName: "Range While Search",
	superMode: nil,
	maxRange: 160,
	minRange: 10,
	range: 40,
	az: 60,
	bars: 4,
	lastTilt: nil,
	lastBars: nil,
	lastAz: nil,
	discSpeed_dps: 100,
	barHeight: 1,# multiple of instantFoV
	bar1Pattern: [[-1,0],[1,0]],
	bar2Pattern: [[-1,-0.5],[1,-0.5],[1,0.5],[-1,0.5]],
	bar3Pattern: [[-1,0],[1,0],[1,1],[-1,1],[-1,0],[1,0],[1,-1],[-1,-1]],
	bar4Pattern: [[1,-1.5],[1,1.5],[-1,1.5],[-1,0.5],[1,0.5],[1,-0.5],[-1,-0.5],[-1,-1.5]],
	currentPattern: [],
	nextPatternNode: 0,
	new: func (radar = nil) {
		var mode = {parents: [F16RWSMode, RadarMode]};
		mode.radar = radar;
		return mode;
	},
	increaseRange: func {
		me.range*=2;
		if (me.range>me.maxRange) {
			me.range*=0.5;
			return 0;
		}
		return 1;
	},
	decreaseRange: func {
		me.range *= 0.5;
		if (me.range < me.minRange) {
			me.range *= 2;
			return 0;
		}
		return 1;
	},
	setRange: func (range) {
		me.testMulti = 160/range;
		if (me.testMulti < 1 or me.testMulti > 16 or int(me.testMulti) != me.testMulti) {
			return 0;
		}
		me.range = range;
		return 1;
	},
	getRange: func {
		return me.range;
	},
	cycleAZ: func {
		if (me.az == 10) me.az = 30;
		elsif (me.az == 30) me.az = 60;
		elsif (me.az == 60) me.az = 10;
	},
	cycleBars: func {
		me.bars += 1;
		if (me.bars == 5) me.bars = 1;
		me.nextPatternNode = 0;
	},
	leaveMode: func {
		return 0;
	},
	step: func (dt, tilt) {
		if (tilt != me.lastTilt or me.bars != me.lastBars or me.az != me.lastAz) {
			# (re)calculate pattern as vectors.
			me.currentPattern = [];
			if (me.bars == 1) {
				foreach (var eulerNorm ; me.bar1Pattern) {
					me.localDir = vector.Math.eulerToCartesian3X(eulerNorm[0]*me.az, eulerNorm[1]*me.radar.instantFoVradius*me.barHeight, 0);
					me.localDir = vector.Math.pitchVector(tilt, me.localDir);
					append(me.currentPattern, me.localDir);
				}
			} elsif (me.bars == 2) {
				foreach (var eulerNorm ; me.bar2Pattern) {
					me.localDir = vector.Math.eulerToCartesian3X(eulerNorm[0]*me.az, eulerNorm[1]*me.radar.instantFoVradius*me.barHeight, 0);
					me.localDir = vector.Math.pitchVector(tilt, me.localDir);
					append(me.currentPattern, me.localDir);
				}
			}elsif (me.bars == 3) {
				foreach (var eulerNorm ; me.bar3Pattern) {
					me.localDir = vector.Math.eulerToCartesian3X(eulerNorm[0]*me.az, eulerNorm[1]*me.radar.instantFoVradius*me.barHeight, 0);
					me.localDir = vector.Math.pitchVector(tilt, me.localDir);
					append(me.currentPattern, me.localDir);
				}
			}elsif (me.bars == 4) {
				foreach (var eulerNorm ; me.bar4Pattern) {
					me.localDir = vector.Math.eulerToCartesian3X(eulerNorm[0]*me.az, eulerNorm[1]*me.radar.instantFoVradius*me.barHeight, 0);
					me.localDir = vector.Math.pitchVector(tilt, me.localDir);
					append(me.currentPattern, me.localDir);
				}
			}
			me.lastTilt = tilt;
			me.lastBars = me.bars;
			me.lastAz = me.az;
		}
		me.maxMove = math.min(me.radar.instantFoVradius, me.discSpeed_dps*dt);
		me.currentPos = me.radar.positionDirection;
		me.angleToNextNode = vector.Math.angleBetweenVectors(me.currentPos, me.currentPattern[me.nextPatternNode]);
		if (me.angleToNextNode < me.maxMove) {
			me.radar.setAntennae(me.currentPattern[me.nextPatternNode]);
			me.nextPatternNode += 1;
			if (me.nextPatternNode >= size(me.currentPattern)) {
				me.nextPatternNode = 0;
			}
			return dt-me.angleToNextNode/me.discSpeed_dps;
		}
		me.newPos = vector.Math.rotateVectorTowardsVector(me.currentPos, me.currentPattern[me.nextPatternNode], me.maxMove);
		me.radar.setAntennae(me.newPos);
		return 0;
	},
};

var F16SAMMode = {
	radar: nil,
	shortName: "SAM",
	longName: "",
	superMode: nil,
	discSpeed_dps: 100,
	increaseRange: func {},
	decreaseRange: func {},
	setRange: func {},
	getRange: func {},
	leaveMode: func {},
};

var F16STTMode = {
	radar: nil,
	shortName: "STT",
	longName: "",
	superMode: nil,
	discSpeed_dps: 100,
	increaseRange: func {},
	decreaseRange: func {},
	setRange: func (range_nm) {},
	getRange: func {},
	leaveMode: func {},
};

var FOR_ROUND  = 0;
var FOR_SQUARE = 1;

var APG68 = {
	fieldOfRegardType: FOR_SQUARE,
	currentMode: nil, # vector of cascading modes ending with current submode
	mainModes: [],
	instantFoVradius: 3.6,
	rcsRefDistance: 70,
	rcsRefValue: 3.2,
	tilt: 0,
	maxTilt: 50,
	maxTilt: -50,
	positionX: 0,# euler direction
	positionY: 0,
	positionDirection: [1,0,0],# vector direction
	vector_aicontacts_for: [],# vector of contacts found in field of regard
	vector_aicontacts_bleps: [],# vector of not timed out bleps
	timer: nil,
	timerSlow: nil,
	lastElapsed: getprop("sim/time/elapsed-sec"),
	new: func (main_modes, current_mode) {
		var rdr = {parents: [APG68, Radar]};

		rdr.mainModes = main_modes;
		rdr.currentMode = current_mode;

		foreach (mode ; main_modes) {
			# this needs to be set on submodes also...hmmm
			mode.radar = rdr;
		}

		rdr.SliceNotification = SliceNotification.new();
		rdr.ContactNotification = VectorNotification.new("ContactNotification");
		rdr.ActiveDiscRadarRecipient = emesary.Recipient.new("ActiveDiscRadarRecipient");
		rdr.ActiveDiscRadarRecipient.radar = rdr;
		rdr.ActiveDiscRadarRecipient.Receive = func(notification) {
	        if (notification.NotificationType == "FORNotification") {
	        	#printf("DiscRadar recv: %s", notification.NotificationType);
	            if (rdr.enabled == 1) {
	    		    rdr.vector_aicontacts_for = notification.vector;
	    		    #me.forWasScanned();
	    		    #print("size(rdr.vector_aicontacts_for)=",size(rdr.vector_aicontacts_for));
	    	    }
	            return emesary.Transmitter.ReceiptStatus_OK;
	        }
	        return emesary.Transmitter.ReceiptStatus_NotProcessed;
	    };
		emesary.GlobalTransmitter.Register(rdr.ActiveDiscRadarRecipient);
		rdr.timer = maketimer(0.05, rdr, func rdr.loop());
		rdr.timerSlow = maketimer(0.25, rdr, func rdr.loopSlow());
		rdr.timerSlow.start();
		rdr.timer.start();
    	return rdr;
	},
	increaseRange: func {
		me.currentMode.increaseRange();
	},
	decreaseRange: func {
		me.currentMode.decreaseRange();
	},
	designate: func (designate_contact) {},
	undesignate: func {},
	cycleDesignate: func {},
	cycleMode: func {},
	cycleAZ: func {
		me.currentMode.cycleAZ();
	},
	cycleBars: func {
		me.currentMode.cycleBars();
	},
	setElevation: func (tilt_deg) {
		if (tilt_deg > me.maxTilt or tilt_deg < me.minTilt) {
			return 0;
		}
		me.tilt = tilt_deg;
		return 1;
	},
	getElevation: func {
		return me.tilt;
	},
	getBars: func {
		return me.currentMode.bars;
	},
	getAzimuthRadius: func {
		return me.currentMode.az;
	},
	getMode: func {
		return me.currentMode.shortName;
	},
	getRange: func {
		return me.currentMode.getRange();
	},
	loop: func {
		if (me.enabled) {
			me.elapsed = getprop("sim/time/elapsed-sec");
			me.dt = me.elapsed - me.lastElapsed;
			me.lastElapsed = me.elapsed;
			while (me.dt > 0) {
				# mode tells us how to move disc and to scan
				me.dt = me.currentMode.step(me.dt, me.tilt);# mode already knows where in pattern we are and AZ and bars.
				# we then step to the new position, and scan for each step
				me.scanFOV();
			}
		}
	},
	loopSlow: func {
		emesary.GlobalTransmitter.NotifyAll(me.SliceNotification.slice(self.getPitch(), self.getHeading(), 60, 60, me.getRange()*NM2M));
	},
	setAntennae: func (x, y) {
		me.positionX = x;
		me.positionY = y;
		me.positionDirection = vector.Math.eulerToCartesian3X(-x, y, 0);
	},
	setAntennae: func (dir) {
		me.eulerDir = vector.Math.cartesianToEuler(dir);
		me.positionX = me.eulerDir[0]==nil?0:geo.normdeg180(me.eulerDir[0]);
		me.positionY = me.eulerDir[1];
		me.positionDirection = dir;
	},
	scanFOV: func {
		foreach(contact ; me.vector_aicontacts_for) {
			me.dev = contact.getDeviationStored();
			#print("Bearing ",me.dev[7],", Pitch ",me.dev[8]);
			me.globalToTarget = vector.Math.eulerToCartesian3X(-me.dev[7],me.dev[8],0);
			me.localToTarget = vector.Math.rollPitchYawVector(-self.getRoll(),-self.getPitch(),self.getHeading(), me.globalToTarget);
			#print("ANT head ",me.positionX,", ANT elev ",me.positionY,", ANT tilt ", me.tilt);
			#print(vector.Math.format(me.localToTarget));
			me.beamDeviation = vector.Math.angleBetweenVectors(me.positionDirection, me.localToTarget);
			#print("me.beamDeviation ", me.beamDeviation);
			if (me.beamDeviation < me.instantFoVradius) {
				me.registerBlep(contact);
				print("REGISTER BLEP");
			}
		}
	},
	registerBlep: func (contact) {
		me.strength = me.targetRCSSignal(self.getCoord(), me.dev[3], contact.model, contact.getHeadingFrozen(1), contact.getPitchFrozen(1), contact.getRollFrozen(1),myRadarDistance_m,myRadarStrength_rcs);
		#TODO: check Terrain, Doppler here.
		if (me.strength > me.dev[2]) {
			me.extInfo = 0;# if the scan gives heading info etc..
			contact.blep(getprop("sim/time/elapsed-sec"), me.extInfo, me.strength, 0);
			if (!me.containsVector(me.vector_aicontacts_bleps, contact)) {
				append(me.vector_aicontacts_bleps, contact);
			}
			return 1;
		}
		return 0;
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
};

var rwsMode = F16RWSMode.new();
var exampleRadar = APG68.new([rwsMode], rwsMode);


















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









RadarViewPPI = {
# implements radar/RWR display on CRT/MFD
# also slew cursor to select contacts.
# fast loop
#
# Attributes:
#   link to Radar
#   link to FireControl
	new: func {
		var window = canvas.Window.new([256, 256],"dialog")
				.set('x', 256)
				.set('y', 350)
                .set('title', "Radar PPI");
		var root = window.getCanvas(1).createGroup();
		window.getCanvas(1).setColorBackground(0,0,0);
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
      	  .setFontSize(12, 1.0)
	      .setColor(1, 1, 1);
	    me.text2 = root.createChild("text")
	      .setAlignment("left-top")
      	  .setFontSize(12, 1.0)
      	  .setTranslation(0,15)
	      .setColor(1, 1, 1);
	    me.text3 = root.createChild("text")
	      .setAlignment("left-top")
      	  .setFontSize(12, 1.0)
      	  .setTranslation(0,30)
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
							.moveTo(0,-5)
							.vert(-5)
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

		me.loop();
	},

	loop: func {
		if (!enable) {settimer(func me.loop(), 0.3); return;}
		me.sweep.setRotation(exampleRadar.positionX*D2R);
		if (0 and exampleRadar.lock!=HARD) {
			me.sweepA.show();
			me.sweepB.show();
			me.sweepA.setRotation(exampleRadar.pattern_move[0]*D2R);
			me.sweepB.setRotation(exampleRadar.pattern_move[1]*D2R);
		} else {
			me.sweepA.hide();
			me.sweepB.hide();
		}
		me.elapsed = getprop("sim/time/elapsed-sec");
		#me.rootCenterBleps.removeAllChildren();
		me.i = 0;
		foreach(contact; exampleRadar.vector_aicontacts_bleps) {
			if (me.elapsed - contact.blepTime < 5) {
				me.distPixels = contact.getRangeFrozen()*(me.sweepDistance/(exampleRadar.getRange()*NM2M));

				me.blep[me.i].setColor(1-(me.elapsed - contact.blepTime)/time_to_fadeout_bleps,1-(me.elapsed - contact.blepTime)/time_to_fadeout_bleps,1-(me.elapsed - contact.blepTime)/time_to_fadeout_bleps);
				me.blep[me.i].setTranslation(-me.distPixels*math.cos(contact.getDeviationHeadingFrozen()*D2R+math.pi/2),-me.distPixels*math.sin(contact.getDeviationHeadingFrozen()*D2R+math.pi/2));
				me.blep[me.i].show();
				me.blep[me.i].update();
					
				if (0 and exampleRadar.containsVector(exampleRadar.locks, contact)) {
					me.rot = contact.getHeadingFrozen();
					if (me.rot == nil) {
						#can happen in transition between TWS to RWS
						me.lock[me.i].hide();
					} else {
						me.rot = me.rot-getprop("orientation/heading-deg");
						me.lock[me.i].setRotation(me.rot*D2R);
						me.lock[me.i].setColor(exampleRadar.lock == HARD?[1,0,0]:[1,1,0]);
						me.lock[me.i].setTranslation(-me.distPixels*math.cos(contact.getDeviationHeadingFrozen()*D2R+math.pi/2),-me.distPixels*math.sin(contact.getDeviationHeadingFrozen()*D2R+math.pi/2));
						me.lock[me.i].show();
						me.lock[me.i].update();
					}
				} else {
					me.lock[me.i].hide();
				}
				if (0 and exampleRadar.containsVector(exampleRadar.follow, contact)) {
					me.select[me.i].setTranslation(-me.distPixels*math.cos(contact.getDeviationHeadingFrozen()*D2R+math.pi/2),-me.distPixels*math.sin(contact.getDeviationHeadingFrozen()*D2R+math.pi/2));
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
		if (0 and exampleRadar.patternBar<size(exampleRadar.pattern[2])) {
			# the if is due to just after changing bars and before radar loop has run, patternBar can be out of bounds of pattern.
			me.text.setText(sprintf("Bar %+d    Range %d NM", exampleRadar.pattern[2][exampleRadar.patternBar]<4?exampleRadar.pattern[2][exampleRadar.patternBar]-4:exampleRadar.pattern[2][exampleRadar.patternBar]-3,exampleRadar.forDist_m*M2NM));
		}
		me.text.setText(sprintf("           Range %d NM", exampleRadar.getRange()));
		me.md = exampleRadar.getMode();
		if (0 and size(exampleRadar.follow) > 0 and exampleRadar.lock != HARD) {
			me.md = me.md~"-SAM";
		}
		#me.text2.setText(sprintf("Lock=%d (%s)  %s", size(exampleRadar.locks), exampleRadar.lock==NONE?"NONE":exampleRadar.lock==SOFT?"SOFT":"HARD",me.md));
		#me.text3.setText(sprintf("Select: %s", size(exampleRadar.follow)>0?exampleRadar.follow[0].callsign:""));
		settimer(func me.loop(), 0.05);
	},
};

RadarViewBScope = {
# implements radar/RWR display on CRT/MFD
# also slew cursor to select contacts.
# fast loop
#
# Attributes:
#   link to Radar
#   link to FireControl
	new: func {
		var window = canvas.Window.new([256, 256],"dialog")
				.set('x', 550)
                .set('title', "Radar B-Scope");
		var root = window.getCanvas(1).createGroup();
		window.getCanvas(1).setColorBackground(0,0,0);
		me.rootCenter = root.createChild("group")
				.setTranslation(128,256);
		me.rootCenterBleps = root.createChild("group")
				.setTranslation(128,256);
		me.sweep = me.rootCenter.createChild("path")
				.moveTo(0,0)
				.vert(-256)
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
		
	    me.b = root.createChild("text")
	      .setAlignment("left-center")
      	  .setFontSize(10, 1.0)
      	  .setTranslation(0,100)
	      .setColor(1, 1, 1);
	    me.a = root.createChild("text")
	      .setAlignment("left-center")
      	  .setFontSize(10, 1.0)
      	  .setTranslation(0,150)
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
							.moveTo(0,-5)
							.vert(-5)
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

		me.loop();
	},

	loop: func {
		if (!enable) {settimer(func me.loop(), 0.3); return;}
		me.sweep.setTranslation(128*exampleRadar.positionX/60,0);
		if (0 and exampleRadar.lock!=HARD) {
			me.sweepA.show();
			me.sweepB.show();
			me.sweepA.setTranslation(128*exampleRadar.pattern_move[0]/60,0);
			me.sweepB.setTranslation(128*exampleRadar.pattern_move[1]/60,0);
		} else {
			me.sweepA.hide();
			me.sweepB.hide();
		}
		me.elapsed = getprop("sim/time/elapsed-sec");
		#me.rootCenterBleps.removeAllChildren();
		me.i=0;
		foreach(contact; exampleRadar.vector_aicontacts_bleps) {
			if (me.elapsed - contact.blepTime < 5) {
				me.distPixels = contact.getRangeFrozen()*(256/exampleRadar.getRange()*NM2M);

				me.blep[me.i].setColor(1-(me.elapsed - contact.blepTime)/time_to_fadeout_bleps,1-(me.elapsed - contact.blepTime)/time_to_fadeout_bleps,1-(me.elapsed - contact.blepTime)/time_to_fadeout_bleps);
				me.blep[me.i].setTranslation(128*contact.getDeviationHeadingFrozen()/60,-me.distPixels);
				me.blep[me.i].show();
				me.blep[me.i].update();
				if (0 and exampleRadar.containsVector(exampleRadar.locks, contact)) {
					me.rot = contact.getHeadingFrozen();
					if (me.rot == nil) {
						#can happen in transition between TWS to RWS
						me.lock[me.i].hide();
					} else {
						me.rot = me.rot-getprop("orientation/heading-deg")-contact.getDeviationHeadingFrozen();
						me.lock[me.i].setRotation(me.rot*D2R);
						me.lock[me.i].setColor(exampleRadar.lock == HARD?[1,0,0]:[1,1,0]);
						me.lock[me.i].setTranslation(128*contact.getDeviationHeadingFrozen()/60,-me.distPixels);
						me.lock[me.i].show();
						me.lock[me.i].update();
					}
				} else {
					me.lock[me.i].hide();
				}
				if (0 and exampleRadar.containsVector(exampleRadar.follow, contact)) {
					me.select[me.i].setTranslation(128*contact.getDeviationHeadingFrozen()/60,-me.distPixels);
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
		
		var a = 0;
		if (exampleRadar.getAzimuthRadius() == 10) {
			a = 1;
		} elsif (exampleRadar.getAzimuthRadius() == 25) {
			a = 2;
		} elsif (exampleRadar.getAzimuthRadius() == 30) {
			a = 3;
		} elsif (exampleRadar.getAzimuthRadius() == 60) {
			a = 6;
		}
		var b = exampleRadar.getBars();
		me.b.setText("B"~b);
		me.a.setText("A"~a);
		settimer(func me.loop(), 0.05);
	},
};

RadarViewCScope = {
# implements radar/RWR display on CRT/MFD
# also slew cursor to select contacts.
# fast loop
#
# Attributes:
#   link to Radar
#   link to FireControl
	new: func {
		var window = canvas.Window.new([256, 256],"dialog")
				.set('x', 825)
                .set('title', "Radar C-Scope");
		var root = window.getCanvas(1).createGroup();
		window.getCanvas(1).setColorBackground(0,0,0);
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
		

		me.loop();
	},

	loop: func {
		if (!enable) {settimer(func me.loop(), 0.3); return;}
		me.sweep.setTranslation(128*exampleRadar.positionX/60,0);
		me.sweep2.setTranslation(0, -128*(exampleRadar.positionY)/60);
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
			if (me.elapsed - contact.blepTime < 5) {
				me.blep[me.i].setColor(1-(me.elapsed - contact.blepTime)/time_to_fadeout_bleps,1-(me.elapsed - contact.blepTime)/time_to_fadeout_bleps,1-(me.elapsed - contact.blepTime)/time_to_fadeout_bleps);
				me.blep[me.i].setTranslation(128*contact.getDeviationHeadingFrozen()/60,-128*contact.getDeviationPitchFrozen()/60);
				me.blep[me.i].show();
				me.blep[me.i].update();
				if (0 and exampleRadar.containsVector(exampleRadar.locks, contact)) {
					me.lock[me.i].setColor(exampleRadar.lock == HARD?[1,0,0]:[1,1,0]);
					me.lock[me.i].setTranslation(128*contact.getDeviationHeadingFrozen()/60,-128*contact.getDeviationPitchFrozen()/60);
					me.lock[me.i].show();
					me.lock[me.i].update();
				} else {
					me.lock[me.i].hide();
				}
				if (0 and exampleRadar.containsVector(exampleRadar.follow, contact)) {
					me.select[me.i].setTranslation(128*contact.getDeviationHeadingFrozen()/60,-128*contact.getDeviationPitchFrozen()/60);
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
		

		settimer(func me.loop(), 0.05);
	},
};


RadarViewAScope = {
# implements radar/RWR display on CRT/MFD
# also slew cursor to select contacts.
# fast loop
#
# Attributes:
#   link to Radar
#   link to FireControl
	new: func {
		
		var window = canvas.Window.new([256, 256],"dialog")
				.set('x', 825)
				.set('y', 350)
                .set('title', "Radar A-Scope");
		var root = window.getCanvas(1).createGroup();
		window.getCanvas(1).setColorBackground(0,0,0);
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
		me.loop();
	},

	loop: func {
		if (!enable) {settimer(func me.loop(), 0.3); return;}
		for (var i = 0;i<256;i+=1) {
			me.values[i] = 0;
		}
		me.elapsed = getprop("sim/time/elapsed-sec");
		foreach(contact; exampleRadar.vector_aicontacts_bleps) {
			if (me.elapsed - contact.blepTime < 5) {
				me.range = contact.getRangeDirectFrozen();
				if (me.range==0) me.range=1;
				me.distPixels = 2/math.pow(me.range/contact.strength,2);
				me.index = int(256*(contact.getDeviationHeadingFrozen()+60)/120);
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
		settimer(func me.loop(), exampleRadar.loopSpeed);
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
};

RWRView = {
	new: func {
		var diameter = 256;
		var window = canvas.Window.new([diameter, diameter],"dialog")
				.set('x', 550)
				.set('y', 350)
                .set('title', "RWR");
		var root = window.getCanvas(1).createGroup();
		window.getCanvas(1).setColorBackground(0,0.2,0);
		me.rwr = RWRCanvas.new(root, [diameter/2,diameter/2], diameter);
		me.loop();
	},

	loop: func {
		if (!enableRWRs) {settimer(func me.loop(), 0.3); return;}
		
		
		me.rwr.update(exampleRWR.vector_aicontacts_threats);

		settimer(func me.loop(), 1);
	},
};


ExampleRadar = {
# test radar
	new: func () {
		var vr = ActiveDiscRadar.new();
		append(vr.parents, ExampleRadar);
		vr.discSpeed_dps  = 120;
		vr.fovRadius_deg  = 3.6;
		vr.calcLoop();
		vr.calcBars();
		vr.pattern        = [-60,60,[1,2,3,4,5,6]];#6/8 bars
		vr.forDist_m      = 32*NM2M;#range setting
		vr.forRadius_deg  = 60;
		vr.posE           = vr.bars[vr.pattern[2][vr.patternBar]];
		vr.posH           = vr.pattern[0];
    	return vr;
	},

	more: func {
		#test method
		me.forDist_m      *= 2;
	},

	less: func {
		#test method
		me.forDist_m      *= 0.5;
	},

	rwsHigh: func {
		#test method
		me.pattern        = [-60,60,[4,5,6,7]];#4/8 bars
		me.directionX     = 1;
		me.patternBar     = 0;
		me.posE           = me.bars[me.pattern[2][me.patternBar]];
		me.posH           = me.pattern[0];
		me.scanMode       = RANGE_WHILE_SEARCH;
		me.discSpeed_dps  = 120;
		me.lock = NONE;
		me.locks = [];
		me.calcLoop();
		me.follow = [];
	},

	rws120: func {
		#test method
		me.pattern        = [-60,60,[1,2,3,4,5,6]];#6/8 bars
		me.directionX     = 1;
		me.patternBar     = 0;
		me.posE           = me.bars[me.pattern[2][me.patternBar]];
		me.posH           = me.pattern[0];
		me.scanMode       = RANGE_WHILE_SEARCH;
		me.discSpeed_dps  = 120;
		me.lock = NONE;
		me.locks = [];
		me.calcLoop();
		#me.follow = [];
	},

	sam: func {
		#test method
		if (size(me.follow)>0 and me.lock != HARD) {
			# toggle SAM off
			me.follow = [];
		} elsif(me.lock == HARD) {
			if (size(me.locks) > 0) {
				me.follow = [me.locks[0]];
				if(me.scanMode == TRACK_WHILE_SCAN) {
					me.lock = SOFT;
				} else {
					me.lock = NONE;
					me.locks = [];
				}				
			}
		} elsif(me.scanMode == RANGE_WHILE_SEARCH) {
			if (size(me.vector_aicontacts_bleps) > 0) {
				me.lock = NONE;
				me.locks = [];
				me.follow = [me.vector_aicontacts_bleps[0]];
			}
		} elsif(me.scanMode == TRACK_WHILE_SCAN) {
			if (size(me.locks) > 0) {
				me.lock = SOFT;
				me.follow = [me.locks[0]];
			}
		}		 
	},

	next: func {
		if (size(me.follow) == 1 and size(me.locks) > 0 and me.lock != HARD) {
			me.index = me.vectorIndex(me.locks, me.follow[0]);
			if (me.index == -1) {
				me.follow = [me.locks[0]];
			} else {
				if (me.index+1 > size(me.locks)-1) {
					me.follow = [];
				} else {
					me.follow = [me.locks[me.index+1]];
				}
			}
		} elsif (size(me.follow) == 1 and size(me.vector_aicontacts_bleps) > 0) {
			me.index = me.vectorIndex(me.vector_aicontacts_bleps, me.follow[0]);
			if (me.index == -1) {
				me.follow = [me.vector_aicontacts_bleps[0]];
			} else {
				if (me.index+1 > size(me.vector_aicontacts_bleps)-1) {
					me.follow = [];
				} else {
					me.follow = [me.vector_aicontacts_bleps[me.index+1]];
				}
			}
		}
	},

	tws15: func {
		#test method
		me.pattern        = [-7.5,7.5,[1,2,3,4,5,6]];#6/8 bars
		me.directionX     = 1;
		me.patternBar     = 0;
		me.posE           = me.bars[me.pattern[2][me.patternBar]];
		me.posH           = me.pattern[0];
		me.scanMode       = TRACK_WHILE_SCAN;
		me.discSpeed_dps  = 60;
		me.calcLoop();
		me.lock = NONE;
		#me.follow = [];
	},

	tws30: func {
		#test method
		me.pattern        = [-15,15,[2,3,4,5]];#4/8 bars
		me.directionX     = 1;
		me.patternBar     = 0;
		me.posE           = me.bars[me.pattern[2][me.patternBar]];
		me.posH           = me.pattern[0];
		me.scanMode       = TRACK_WHILE_SCAN;
		me.discSpeed_dps  = 60;
		me.calcLoop();
		me.lock = NONE;
		#me.follow = [];
	},

	tws60: func {
		#test method
		me.pattern        = [-30,30,[3,4]];#2/8 bars
		me.directionX     = 1;
		me.patternBar     = 0;
		me.posE           = me.bars[me.pattern[2][me.patternBar]];
		me.posH           = me.pattern[0];
		me.scanMode       = TRACK_WHILE_SCAN;
		me.discSpeed_dps  = 60;
		me.calcLoop();
		me.lock = NONE;
		#me.follow = [];
	},

	b1: func {
		me.pattern[2] = [4];
	},

	b2: func {
		me.pattern[2] = [3,4];
	},

	b4: func {
		me.pattern[2] = [2,3,4,5];
	},

	b6: func {
		me.pattern[2] = [1,2,3,4,5,6];
	},

	b8: func {
		me.pattern[2] = [0,1,2,3,4,5,6,7];
	},

	a2: func {
		me.pattern[0] = -15;
		me.pattern[1] =  15;
	},

	a3: func {
		me.pattern[0] = -30;
		me.pattern[1] =  30;
	},

	a4: func {
		me.pattern[0] = -60;
		me.pattern[1] =  60;
	},

	a1: func {
		me.pattern[0] = -7.5;
		me.pattern[1] =  7.5;
	},

	left: func {
		#test method
		var zero = me.pattern[0]-15;
		if (zero >= -me.forRadius_deg) {
			me.pattern[0] = zero;
			me.pattern[1] = me.pattern[1]-15;
		}
	},

	right: func {
		#test method
		var one = me.pattern[1]+15;
		if (one <= me.forRadius_deg) {
			me.pattern[1] = one;
			me.pattern[0] = me.pattern[0]+15;
		}
	},

	up: func {
		#test method
		me.barOffset += 1;
		if (me.barOffset > 4) {
			me.barOffset = 4;
		}
	},

	down: func {
		#test method
		me.barOffset -= 1;
		if (me.barOffset < -4) {
			me.barOffset = -4;
		}
	},

	level: func {
		#test method
		me.barOffset = 0;
	},

	lockRandom: func {
		#test method

		# hard lock
		if (size(me.follow)>0) {
			# choose same lock as being followed with SAM
			if (me.follow[0].getRangeDirectFrozen() < max_lock_range_nm*NM2M) {
				me.locks = [me.follow[0]];
				me.lock = HARD;
				me.vector_aicontacts_for = [me.follow[0]];
				#me.devLock = lck.getDeviation();#since we have no cursor we need to cheat a bit here.
				#me.posH = me.devLock[0];
				#me.posE = me.devLock[1];
				me.sendLockNotificationInit();
				#me.scanFOV();# this call migth not be neccesary..
			}
		} elsif (size(me.vector_aicontacts_bleps)>0) {
			# random chosen lock in range
			foreach (lck ; me.vector_aicontacts_bleps) {
				if (lck.getRangeDirectFrozen() < max_lock_range_nm*NM2M) {
					me.locks = [lck];
					me.follow = [lck];
					me.lock = HARD;
					me.vector_aicontacts_for = [lck];
					#me.devLock = lck.getDeviation();
					#me.posH = me.devLock[0];
					#me.posE = me.devLock[1];
					me.sendLockNotificationInit();
					#me.scanFOV();# this call migth not be neccesary..
					break;
				}
			}
		}
	},

	sendLockNotificationInit: func {
		# this will update the lock if it hasn't moved too much since we last detected it.
		emesary.GlobalTransmitter.NotifyAll(me.SliceNotification.slice(me.locks[0].getDeviationPitchFrozen()-me.fovRadius_deg*5,me.locks[0].getDeviationPitchFrozen()+me.fovRadius_deg*5, me.locks[0].getDeviationHeadingFrozen()-me.fovRadius_deg*5,me.locks[0].getDeviationHeadingFrozen()+me.fovRadius_deg*5,me.forDist_m));
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
	var button1 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Mode")
		.setFixedSize(75, 25);
	button1.listen("clicked", func {
		exampleRadar.cycleMode();
	});
	myLayout.addItem(button1);
	var button5 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("?Left")
		.setFixedSize(75, 25);
	button5.listen("clicked", func {
		exampleRadar.left();
	});
	myLayout.addItem(button5);
	var button6 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("?Right")
		.setFixedSize(75, 25);
	button6.listen("clicked", func {
		exampleRadar.right();
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
		.setText("?Lock")
		.setFixedSize(75, 25);
	button9.listen("clicked", func {
		exampleRadar.lockRandom();
	});
	myLayout.addItem(button9);
	var button10 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("?Select|SAM")
		.setFixedSize(75, 25);
	button10.listen("clicked", func {
		exampleRadar.sam();
	});
	myLayout.addItem(button10);
	var button11 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("?Next")
		.setFixedSize(75, 25);
	button11.listen("clicked", func {
		exampleRadar.next();
	});
	myLayout.addItem(button11);
	var button12 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Up")
		.setFixedSize(75, 25);
	button12.listen("clicked", func {
		exampleRadar.tilt += 4;
	});
	myLayout.addItem(button12);
	var button13 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Down")
		.setFixedSize(75, 25);
	button13.listen("clicked", func {
		exampleRadar.tilt -= 4;
	});
	myLayout.addItem(button13);
	var button14 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Level")
		.setFixedSize(75, 25);
	button14.listen("clicked", func {
		exampleRadar.tilt = 0;
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
	button24 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("RWRsc ON")
		.setFixedSize(75, 20);
	button24.listen("clicked", func {
		enableRWRs = !enableRWRs;
		if (enableRWRs == 0) button24.setText("RWRsc OFF");
		else button24.setText("RWRsc ON");
	});
	myLayout2.addItem(button24);
	button25 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("RWR ON")
		.setFixedSize(75, 20);
	button25.listen("clicked", func {
		enableRWR = !enableRWR;
		if (enableRWR == 0) button25.setText("RWR OFF");
		else button25.setText("RWR ON");
	});
	myLayout2.addItem(button25);
	button26 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("RDR ON")
		.setFixedSize(75, 20);
	button26.listen("clicked", func {
		exampleRadar.enabled = !exampleRadar.enabled;
		if (exampleRadar.enabled == 0) button26.setText("RDR OFF");
		else button26.setText("RDR ON");
	});
	myLayout2.addItem(button26);
};
var button23 = nil;
var button24 = nil;
var button25 = nil;
var button26 = nil;
AIToNasal.new();
var nose = NoseRadar.new(15000,60,5);
var omni = OmniRadar.new(0.25, 150, 55);
var terrain = TerrainChecker.new(0.10, 1, 60);
#var exampleRadar = ExampleRadar.new();
var exampleRWR   = RWR.new();
RadarViewPPI.new();
RadarViewBScope.new();
RadarViewCScope.new();
#RadarViewAScope.new();
RWRView.new();
buttonWindow();


#var fix = FixedBeamRadar.new();
#fix.setBeamPitch(-2.5);
#settimer(func {print("beam: "~fix.testForDistance());},15);# will fail if no terrain found :)