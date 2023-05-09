###############################################
#
# Station management system
#
# Design authors: Richard, 5H1N0B1, Leto, Pinto
#
# Initial implementation: Leto
#
# License: GPL 2
#
###############################################

var fdm = getprop("/sim/flight-model");
var baseGui = fdm=="jsb"?"payload":"sim";

var Station = {
# pylon or fixed mounted weapon on the aircraft
	new: func (name, id, position, sets, guiID, pointmassNode, operableFunction = nil, activeFunction = nil) {
		var p = {parents:[Station]};
		p.id = id;
		p.name = name;
		p.position = position;
		p.sets = sets;
		p.guiID = guiID;#can be nil when should not show up in GUI dialog.
		p.node_pointMass = pointmassNode;
		p.operableFunction = operableFunction;
		p.activeFunction = activeFunction; # for F14, if a pylon is set active or not
		p.weapons = [];#when weapons are fired/jettisoned, they turn to nil, the vector size must stay same as fire-order dictates.
		p.changingGui = 0;
		p.launcherDA=0;
		p.launcherMass=0;
		p.launcherJettisoned=1;
		p.forceRail = 0;
		p.guiListener = nil;
		p.currentName = nil;	
		p.currentSet = nil;
		p.myListener = nil;#will be called when a stations loadout changes from outside.
		p.AIMListener = nil;#will be called when a weapon is fired. argument=the weapon
		p.JettListener = nil;#will be called when a weapon is fired. argument=the weapon
		return p;
	},

	setAIMListener: func (f) {
		# install a listener in this station that get called when an armament.AIM weapon is released (not jettisoned). The listener should have 1 argument: the AIM weapon.
		me.AIMListener = f;
	},

	setJettListener: func (f) {
		# install a listener in this station that get called when an armament.AIM weapon is jettisoned. The listener should have 1 argument: the AIM weapon.
		me.JettListener = f;
	},

	getCategory: func {
		# Get current category for this station. This is a concept, where category is a number and the higher the number,
		# the more restrictions on the flight envelope should be applied. In U.S. this is from 1 (no restrictions) to 3 (restrictions, typically limits on G during rolling).
		if (me.currentSet != nil and me.currentSet["category"] != nil) {
			foreach(me.weapon ; me.weapons) {
				if (me.weapon != nil) {
					return me.currentSet["category"];
				}
			}			
		}
		return 1;
	},

	getCurrentName: func {
		# Get name of this station.
		return me.currentName;
	},
	
	isActive: func {
		# Returns if is active. This is for example used in F-14, where stations be individually enabled or disabled.
		if (me.activeFunction != nil) {
			return me.activeFunction();
		}
		return 1;
	},

	loadSet: func (set) {
		# This will load a set (which is a hash) onto the station.
		# If any of the stores in the set is armament.AIM weapons, they will be created.
		# After loading it will update mass for the station, update the payload GUI and set the FDM properties for drag, yaw and mass.
		foreach(me.weapon ; me.weapons) {
			if (me.weapon != nil) {
				me.weapon.del();
			}
		}
		me.weapons = [];
		if (set != nil) {
			#printf("Pylon %d loading set %s", me.id, set.name);
			for(me.i = 0; me.i < size(set.content);me.i+=1) {
				me.weaponName = set.content[me.i];
				if (typeof(me.weaponName) == "scalar") {
					#print("attempting to create weapon id="~(me.id*100+me.i));
					var mf = nil;
					if (me.weaponName == "AGM-154A") {
						mf = func (struct) {
							if (struct.dist_m != -1 and struct.dist_m*M2NM < 4) {
								return {"guidanceLaw":"direct","abort_midflight_function":1};
							}
							return {};
						};
					} elsif (me.weaponName == "AGM-158") {
						mf = func (struct) {
							if (struct.dist_m != -1 and struct.speed_fps != 0) {
								if (M2NM*struct.dist_m < 1.75 and struct.guidanceLaw == "direct-alt") {
									# start terminal diving
									return {"altitude":0,"guidanceLaw":"direct"};
								}
								if (M2FT*struct.dist_m/struct.speed_fps < 8 and struct.guidance == "gps") {
									# 8s before impact switch to IR, authentic value
									return {"guidance":"heat","guidanceLaw":"APN","altitude":0,"class":"GM","target":"closest","abort_midflight_function":1};
								}
								if (struct.dist_m*M2NM > 10) {
									# 22000 ft above sealevel, authentic value
									return {"altitude": 22000};
								}
								if (M2NM*struct.dist_m > 1.75 and struct.hasTarget) {
									# Lower altitude to 5000 ft above target
									return {"altitude_at": 5000};
								}
							}
							return {};
						};
					} elsif (me.weaponName == "AIM-54") {
						mf = func (struct) {
							if (struct.dist_m != -1 and struct.dist_m*M2NM < 11 and struct.guidance == "sample") {
								return {"guidance":"radar","guidanceLaw":"PN","abort_midflight_function":1};
							}
							return {};
						};
					} elsif (me.weaponName == "AIM-120") {
						mf = func (struct) {
							if (struct.dist_m != -1 and struct.dist_m*M2NM < 10 and struct.guidance == "sample") {
								screen.log.write("AIM-120: Pitbull", 1,1,0);
								return {"guidance":"radar","abort_midflight_function":1};
							}
							return {};
						};
					} elsif (me.weaponName == "MICA-EM") {
						mf = func (struct) {
							if (struct.guidance == "inertial" and !struct.hasTarget) {
								return {"guidance":"radar","abort_midflight_function":1};
							}
							if (struct.dist_m != -1 and struct.dist_m*M2NM < 12 and struct.guidance == "inertial" and struct.deviation_deg != nil and struct.deviation_deg < 70) {
								screen.log.write("MICA-EM: Pitbull", 1,1,0);
								return {"guidance":"radar","abort_midflight_function":1};
							}
							return {};
						};
					} elsif (me.weaponName == "MICA-IR") {
						mf = func (struct) {
							if (struct.guidance == "inertial" and !struct.hasTarget) {
								return {"guidance":"heat","abort_midflight_function":1};
							}
							if (struct.dist_m != -1 and struct.dist_m*M2NM < 12 and struct.guidance == "inertial" and struct.deviation_deg != nil and struct.deviation_deg < 70) {
								return {"guidance":"heat","abort_midflight_function":1};
							}
							return {};
						};
					} elsif (me.weaponName == "AGM-84") {
						mf = func (struct) {
							if (struct.dist_m != -1 and struct.dist_m*M2NM < 5 and struct.guidance == "inertial") {
								return {"guidance":"radar","abort_midflight_function":1};
							}
							return {};
						};
					} elsif (me.weaponName == "AIM-9X") {
						mf = func (struct) {
							if (struct.deviation_deg != nil) {
								if (struct.deviation_deg > 70) {
									return {"navigation":"direct"};
								} elsif (struct.deviation_deg < 70) {
									return {"navigation":"OPN", "guidance":"heat"};
								} elsif (struct.deviation_deg < 55) {
									return {"navigation":"OPN", "guidance":"heat", "abort_midflight_function":1};
								}
							}
							return {};
						};
					};

					me.aim = armament.AIM.new(me.id*100+me.i, me.weaponName, "", mf, me.position);
					if (me.aim == -1) {
						print("Pylon could not create "~me.weaponName);
						me.aim = nil;
					}
					if (me.forceRail) {
						me.aim.rail = 1;
						me.aim.drop_time = 0;
					}
					append(me.weapons, me.aim);
				} else {
					#print("Added submodel or fuel tank to Pylon");
					me.weaponName.mount(me);
					append(me.weapons, me.weaponName);
				}
			}
			me.launcherMass = set.launcherMass;
			me.launcherJettisonable = set.launcherJettisonable;
			me.weaponJettisonable = set["weaponJettisonable"];
			if (me.weaponJettisonable == nil) {
				me.weaponJettisonable = 1;
			}
			me.launcherJettisoned = 0;
			me.currentSet   = set;
		} else {
			me.launcherMass = 0;
			me.launcherJettisonable = 0;
			me.launcherJettisoned = 1;
			me.weaponJettisonable = 1;
			me.currentSet = nil;
		}
		me.loadingSet(set);
		me.calculateMass();
		me.calculateFDM();
		me.setGUI();
		if(me.myListener != nil) {
			me.myListener.updateAll();
		}
	},

	loadingSet: func (set) {
		# Override this function. Gets called after a set is loaded, but before any mass, fdm, gui settings is applied.
	},

	setPylonListener: func (ml) {
		# Installs a listener. The listener should implement the method updateAll() which will be called only when set is changed.
		# Warning: is not called when stores are released, jettisoned or likewise.
		me.myListener = ml;
	},
	
	getMass: func {
		# Return a vector with launcher/rack/pylon/tube mass and the combined mass of all stores mounted.
		if (me["weaponsMass"] == nil) me.weaponsMass = 0;
		return [me.weaponsMass, me.launcherMass];
	},

	calculateMass: func {
		# Calc the masses of this station.
		# Is also sets the 3D model properties used to display the stores. (optional system)
		me.totalMass = 0;
		me.weaponsMass = 0;
		me.singleName = "";#this is hack to show stores locally
		foreach(me.weapon;me.weapons) {
			if (me.weapon != nil) {
				me.totalMass += me.weapon.weight_launch_lbm;
				me.weaponsMass += me.weapon.weight_launch_lbm;
				me.singleName = me.weapon.type;#this is hack to show stores locally
			}
		}
		me.totalMass += me.launcherMass;
		me.node_pointMass.setDoubleValue(me.totalMass);

		#this is hack to show stores locally:
		me.counter = 0;
		foreach(me.actuals;me.weapons) {
			if (me.actuals != nil) {
				me.counter += 1;
			}
		}
		setprop("payload/armament/station/id-"~me.id~"-type", me.singleName);
		setprop("payload/armament/station/id-"~me.id~"-count", me.counter);
		if (me.currentSet != nil) {
			setprop("payload/armament/station/id-"~me.id~"-set", me.currentSet.name);
		} else {
			setprop("payload/armament/station/id-"~me.id~"-set", "Empty");
		}
	},

	calculateFDM: func {
		# Override this and calculate yaw, drag and mass properties for FDM.
	},

	getWeapons: func {
		# Returns a vector with all current stores. Elements in vector might be nil, meaning they have been jettisoned/released.
		return me.weapons;
	},

	fireWeapon: func (index, contacts=nil) {
		# Release a weapon.
		if (index >= size(me.weapons) or index < 0) {
			print("Pylon recieved illegal fire operation. No such weapon.");
		} elsif (me.weapons[index] == nil) {
			print("Pylon received illegal fire operation. Already fired.");
		} elsif (me.operableFunction != nil and !me.operableFunction()) {
			print("Pylon could not fire weapon, its inoperable.");
		} elsif (me.weapons[index].parents[0] == armament.AIM) {
			me.bye = me.weapons[index];
			me.bye.release(contacts);
			me.weapons[index] = nil;
			me.calculateMass();
			me.calculateFDM();
			me.setGUI();
			if (me.AIMListener != nil) {
				me.AIMListener(me.bye);
			}
			return me.bye;
		} else {
			print("Pylon could not fire weapon, its a submodel or fuel tank, use another method.");
		}
		return nil;
	},

	getAmmo: func (type = nil) {
		# Get total ammo for this station. For missiles/bombs this is typically the numbers, for cannon submodel weapons it is the shell count.
		me.ammo = 0;
		foreach(me.weapon ; me.getWeapons()) {
			if (me.weapon != nil and me.weapon.parents[0] == armament.AIM and (type == nil or me.weapon.type == type)) {
				me.ammo += 1;
			} elsif (me.weapon != nil and me.weapon.parents[0] == SubModelWeapon and (type == nil or me.weapon.type == type)) {
				me.ammo += me.weapon.getAmmo();
			}
		}
		return me.ammo;
	},

	findSetFromName: func (name) {
		# Return a set from the (optionally loaded) list of possible sets that can be mounted. Return nil, if its not in the list.
		foreach (me.set; me.sets) {
			if (me.set.name == name) {
				return me.set;
			}
		}
		return nil;
	},

	vectorIndex: func (vec, item) {
		# Internal used method, do not call me from outside.
		me.i = 0;
		foreach(test; vec) {
			if (test == item) {
				return me.i;
			}
			me.i += 1;
		}
		return -1;
	},

	# Methods to override:
	setGUI: func {}, # Write to the payload GUI or any other GUI info on this station.
	initGUI: func {},# Create the gui properties for this station.
	jettisonAll: func {},# Jettison all stores on this station that are jettisonable.
	jettisonLauncher: func {},# Jettison the launcher/rack/tube if it can be jettisoned.
	getCurrentShortName: func {},# Get shortened name for this station.
	getCurrentSMSName: func {},# Get short name for this station. Called from displays in the aircraft.
	getCurrentPylon: func {},# Get the name of the pylon (the part of station attached to the aircraft).
	getCurrentRack: func {},# Get the name of the rack/launcher (the part of station between the weapon and the pylon).
};

var InternalStation = {
# simulates a fixed internal station, for example a for cannon mounted inside the aircraft
# inherits from Station
	new: func (name, id, sets, pointmassNode, operableFunction = nil) {
		var s = Station.new(name, id, [0,0,0], sets, nil, pointmassNode, operableFunction, nil);
		s.parents = [InternalStation, Station];

		# these should not be called in parent.new(), as they are empty there.
		s.initGUI();
		s.loadSet(sets[0]);
		return s;
	}
};

var FixedStation = {
# simulates a fixed station, for example for CFT tanks
# inherits from Station
	new: func (name, id, sets, pointmassNode, dragareaNode, operableFunction = nil) {
		var s = Station.new(name, id, [0,0,0], sets, nil, pointmassNode, operableFunction, nil);
		s.parents = [FixedStation, Station];

		s.node_dragaera = dragareaNode;
		# these should not be called in parent.new(), as they are empty there.
		s.initGUI();
		s.loadSet(sets[0]);
		return s;
	},

	loadingSet: func (set) {
		# override this method to set custom attributes, before calculateFDM is ran after a set is loaded.
		if (set != nil) {
			me.launcherDA   = set.launcherDragArea;
		} else {
			me.launcherDA   = 0;
		}
	},

	calculateFDM: func {
		# override this method to set custom FDM attributes.
		# do dragarea
		me.totalDA = 0;
		foreach(me.weapon;me.weapons) {
			if (me.weapon != nil) {
				me.totalDA += me.weapon.Cd_base*me.weapon.ref_area_sqft;
			}
		}
		me.totalDA += me.launcherDA;
		me.node_dragaera.setDoubleValue(me.totalDA);
	},
};

var Pylon = {
# inherits from station
# Implements a pylon.
#  missiles/bombs/rockets and methods to give them commands.
#  sets jsbsim/yasim point mass and drag. Mass is combined of all missile-code instances + launcher mass. Same with drag.
#  interacts with GUI payload dialog  ("2 x AIM9L", "1 x GBU-82"), auto-adjusts the name when munitions is fired/jettisoned.
#  should be able to hold missile-code arms.
#  handle propeties to show the correct models in 3D and over MP.
#  electricity and other conditions..use operableFunction
#  no loop, but lots of listeners.
#
# Attributes:
#   missile-code instance(s) [each with a unique id number that corresponds to a 3D position]
#   pylon id number
#   jsb pointmass id number
#   GUI payload id number
#   shared position for 3D release (from xml?)
#   possible sets that can be loaded ("2 x AIM9L", "1 x GBU-82") At loadtime, this can be many, so store in Nasal :(
	new: func (name, id, position, sets, guiID, pointmassNode, dragareaNode, operableFunction = nil, activeFunction = nil) {
		var p = Station.new(name, id, position, sets, guiID, pointmassNode, operableFunction, activeFunction);
		p.parents = [Pylon, Station];
		p.node_dragaera = dragareaNode;
		
		# these should not be called in parent.new(), as they are empty there.
		p.initGUI();
		p.loadSet(sets[0]);
		return p;
	},

	guiChanged: func {
		# Called when the GUI for this station has changed (typically by user interaction to mount another set)
		if(!me.changingGui) {
			me.desiredSet = getprop(baseGui~"/weight["~me.guiID~"]/selected");
			if (me.desiredSet != me.currentName) {
				me.set = me.findSetFromName(me.desiredSet);
				if (me.set != nil) {
					#print("GUI wants set: "~me.set.name);
					me.loadSet(me.set);
				} else {
					#print("GUI wants unknown set. Thats okay.");
				}
			}
			if(me.myListener != nil) {
				me.myListener.updateAll();
			}
		}
	},

	initGUI: func {
		if (me.guiListener != nil) {
			removelistener(me.guiListener);
		}
		me.changingGui = 1;
		me.guiNode = props.globals.getNode(baseGui~"/weight["~me.guiID~"]",1);
		me.guiNode.removeAllChildren();
		me.guiNode.initNode("name",me.name,"STRING");
		me.guiNode.initNode("selected","","STRING");
		me.guiNode.initNode("weight-lb",0,"DOUBLE");
		me.i = 0;
		foreach(set ; me.sets) {
			me.guiNode.initNode("opt["~me.i~"]/name",set.name,"STRING");

			# ensure that gals is set in the option for fuel tanks - as this is required
			# to make the payload dialog auto reload the tank after it is mounted 
			# because the payload dialog requires /consumables/fuel/tank[#]/capacity-gal_us to
			# be present and non zero
			me.guiNode.initNode("opt["~me.i~"]/lbs",0,"DOUBLE");
			if (size(set.content) == 1) {
				if (typeof(set.content[0]) != "scalar"){
					if (set.content[0]["capacity"] != nil)
						me.guiNode.initNode("opt["~me.i~"]/gals",set.content[0]["capacity"],"DOUBLE");
				}
			}
			set.opt = me.i;
			me.i += 1;
		}
		me.calculateSetMassForOpt();
		me.guiListener = setlistener(baseGui~"/weight["~me.guiID~"]/selected", func me.guiChanged());
		me.changingGui = 0;
	},
	
	calculateSetMassForOpt: func {
		# do mass calc for OPT in dialog, this must be done due to fuel and payload dialog changed recently.
		# only if gui name dont match OPT, OPT will not be forced upon us.
		foreach(set ; me.sets) {
			me.totalMass = 0;		
			foreach(me.weapon;set.content) {
				if (typeof(me.weapon) == "scalar") {
					me.totalMass += getprop("payload/armament/"~string.lc(me.weapon)~"/weight-launch-lbs");
				} else {
					me.totalMass += me.weapon.weight_launch_lbm;
				}
			}
			me.totalMass += set.launcherMass;
			me.guiNode.getNode("opt["~set.opt~"]/lbs").setDoubleValue(me.totalMass);
		}
	},

	setGUI: func {
		me.nameGUI = "";
		if (me.currentSet.showLongTypeInsteadOfCount) {
			foreach(me.wapny;me.weapons) {
				if (me.wapny != nil) {
					me.nameGUI = me.wapny.typeLong;
				}
			}
		} else {
			me.calcName = {};
			foreach(me.weapon;me.weapons) {
				if(me.weapon != nil) {
					me.type = me.weapon.type;
					if (me.calcName[me.type]==nil) {
						me.calcName[me.type]=1;
					} else {
						me.calcName[me.type] += 1;
					}
				}
			}
			foreach(key;keys(me.calcName)) {
				me.nameGUI = me.nameGUI~", "~me.calcName[key]~" x "~key;
			}
			me.nameGUI = right(me.nameGUI, size(me.nameGUI)-2);#remove initial comma
		}
		if(me.nameGUI == "" and me.currentSet != nil and size(me.currentSet.content)!=0) {
			me.nameGUI = "Released";
		} elsif (me.nameGUI == "" and me.currentSet != nil and size(me.currentSet.content)==0) {
			me.nameGUI = me.currentSet.name;
		}
		me.changingGui = 1;
		me.currentName = me.nameGUI;
		setprop(baseGui~"/weight["~me.guiID~"]/selected", me.nameGUI);
		setprop(baseGui~"/weight["~me.guiID~"]/weight-lb", me.node_pointMass.getValue());

		me.changingGui = 0;
	},
	
	getCurrentPylon: func {
		me.nameP = nil;
		if(me.currentSet != nil and me.currentSet["pylon"] != nil) {
			me.nameP = me.currentSet.pylon;
		}
		return me.nameP;
	},
	
	getCurrentRack: func {
		me.nameR = nil;
		if(me.currentSet != nil and me.currentSet["rack"] != nil and me.launcherJettisoned == 0) {
			me.nameR = me.currentSet.rack;
		}
		return me.nameR;
	},

	getCurrentShortName: func {
		me.nameS = "";
		if (me.currentSet.showLongTypeInsteadOfCount) {
			foreach(me.wapny;me.weapons) {
				if (me.wapny != nil) {
					me.nameS = me.wapny.typeShort;
				}
			}
		} else {
			me.calcName = {};
			foreach(me.weapon;me.weapons) {
				if(me.weapon != nil) {
					me.type = me.weapon.typeShort;
					if (me.calcName[me.type]==nil) {
						me.calcName[me.type]=1;
					} else {
						me.calcName[me.type] += 1;
					}
				}
			}
			foreach(key;keys(me.calcName)) {
				me.nameS = me.nameS~", "~me.calcName[key]~"x"~key;
			}
			me.nameS = right(me.nameS, size(me.nameS)-2);#remove initial comma
		}
		if(me.nameS == "" and me.currentSet != nil and size(me.currentSet.content)!=0) {
			me.nameS = nil;
		} elsif (me.nameS == "" and me.currentSet != nil and size(me.currentSet.content)==0) {
			me.nameS = me.currentSet.name;
		}
		if(me.nameS == "" or me.nameS == "Empty") {
			me.nameS = nil;
		}
		return me.nameS;
	},
	
	getCurrentSMSName: func {
		me.nameS = "";
		if (me.currentSet.showLongTypeInsteadOfCount) {
			foreach(me.wapny;me.weapons) {
				if (me.wapny != nil) {
					if (me.wapny.typeShort != nil) {
						me.nameS = "1 "~me.wapny.typeShort;
					} else {
						me.nameS = "1 "~me.wapny.type;
					}
				}
			}
		} else {
			me.calcName = {};
			foreach(me.weapon;me.weapons) {
				if(me.weapon != nil) {
					me.type = me.weapon.typeShort;
					if (me.calcName[me.type] == nil) {
						me.calcName[me.type] = 1;
					} else {
						me.calcName[me.type] += 1;
					}
				}
			}
			foreach(key;keys(me.calcName)) {
				me.nameS = me.nameS~", "~me.calcName[key]~" "~key;
			}
			me.nameS = right(me.nameS, size(me.nameS)-2);#remove initial comma
		}
		if(me.nameS == "" and me.currentSet != nil and size(me.currentSet.content) != 0) {
			# all launched or jettisoned
			me.nameS = nil;
		} elsif (me.nameS == "" and me.currentSet != nil and size(me.currentSet.content) == 0) {
			# No launchable weapons
			me.nameS = me.currentSet.name;
		}
		if(me.nameS == "" or me.nameS == "Empty") {
			me.nameS = nil;
		}
		return me.nameS;
	},

	jettisonAll: func {
		# drops everything.
		if (me.weaponJettisonable) {
			me.tempWeapons = [];
		
			foreach(me.weapon ; me.getWeapons()) {
				if (me.weapon != nil) {
					me.weapon.eject();
					if (me.JettListener != nil) {
						me.JettListener(me.weapon);
					}
				}
				append(me.tempWeapons, nil);
			}
			me.jettisonLauncher();
			me.weapons = me.tempWeapons;
			me.calculateMass();
			me.calculateFDM();
			me.setGUI();
		}
	},

	jettisonLauncher: func {
		if (me.launcherJettisonable) {
			me.launcherMass = 0;
			me.launcherDA   = 0;
			me.launcherJettisoned = 1;
		}
	},
	
	loadingSet: func (set) {
		# override this method to set custom attributes, before calculateFDM is ran after a set is loaded.
		if (set != nil) {
			me.launcherDA   = set.launcherDragArea;
		} else {
			me.launcherDA   = 0;
		}
	},

	calculateFDM: func {
		# override this method to set custom FDM attributes.
		# do dragarea
		me.totalDA = 0;
		foreach(me.weapon;me.weapons) {
			if (me.weapon != nil) {
				me.totalDA += me.weapon.Cd_base*me.weapon.ref_area_sqft;
			}
		}
		me.totalDA += me.launcherDA;
		me.node_dragaera.setDoubleValue(me.totalDA);
	},

};

var WPylon = {
# inherits from station. Is a station that cannot hold droptanks. And it will not write to GUI or FDM directly.
#                        Droptanks on this kind of station must be implemented in a parallel system.
#                        It will however read from GUI if it is required to change set.
#                        The GUI properties must be present and initialized.
#						 The first set in the set list MUST be a set containing no stores.
# Implements a pylon.
#  missiles/bombs/rockets and methods to give them commands.
#  sets jsbsim/yasim point mass and drag. Mass is combined of all missile-code instances + launcher mass. Same with drag.
#  interacts with GUI payload dialog  ("2 x AIM9L", "1 x GBU-82"), auto-adjusts the name when munitions is fired/jettisoned.
#  should be able to hold missile-code arms.
#  handle propeties to show the correct models in 3D and over MP.
#  electricity and other conditions..use operableFunction
#  no loop, but lots of listeners.
#
# Attributes:
#   missile-code instance(s) [each with a unique id number that corresponds to a 3D position]
#   pylon id number
#   jsb pointmass id number
#   GUI payload id number
#   shared position for 3D release (from xml?)
#   possible sets that can be loaded ("2 x AIM9L", "1 x GBU-82") At loadtime, this can be many, so store in Nasal :(
	new: func (name, id, position, sets, guiID, pointmassNode, dragareaNode, operableFunction = nil, activeFunction = nil) {
		var p = Station.new(name, id, position, sets, guiID, pointmassNode, operableFunction, activeFunction);
		p.parents = [WPylon, Station];
		p.node_dragaera = dragareaNode;
		
		# these should not be called in parent.new(), as they are empty there.
		p.initGUI();
		p.loadSet(sets[0]);
		return p;
	},

	guiChanged: func {
		# Called when the GUI for this station has changed (typically by user interaction to mount another set)
		if(!me.changingGui) {
			me.desiredSet = getprop(baseGui~"/weight["~me.guiID~"]/selected");
			if (me.desiredSet != me.currentName) {
				me.set = me.findSetFromName(me.desiredSet);
				if (me.set != nil) {
					#print("GUI wants set: "~me.set.name);
					me.loadSet(me.set);
				} else {
					#print("GUI wants unknown set. Thats okay.");
					me.loadSet(me.sets[0]);
				}
			}
			if(me.myListener != nil) {
				me.myListener.updateAll();
			}
		}
	},

	initGUI: func {
		if (me.guiListener != nil) {
			removelistener(me.guiListener);
		}
		me.guiNode = props.globals.getNode(baseGui~"/weight["~me.guiID~"]");
		me.i = 0;
		me.guiListener = setlistener(baseGui~"/weight["~me.guiID~"]/selected", func me.guiChanged());
	},
	
	setGUI: func {
	},
	
	getCurrentPylon: func {
		me.nameP = nil;
		if(me.currentSet != nil and me.currentSet["pylon"] != nil) {
			me.nameP = me.currentSet.pylon;
		}
		return me.nameP;
	},
	
	getCurrentRack: func {
		me.nameR = nil;
		if(me.currentSet != nil and me.currentSet["rack"] != nil and me.launcherJettisoned == 0) {
			me.nameR = me.currentSet.rack;
		}
		return me.nameR;
	},

	getCurrentShortName: func {
		me.nameS = "";
		if (me.currentSet.showLongTypeInsteadOfCount) {
			foreach(me.wapny;me.weapons) {
				if (me.wapny != nil) {
					me.nameS = me.wapny.typeShort;
				}
			}
		} else {
			me.calcName = {};
			foreach(me.weapon;me.weapons) {
				if(me.weapon != nil) {
					me.type = me.weapon.typeShort;
					if (me.calcName[me.type]==nil) {
						me.calcName[me.type]=1;
					} else {
						me.calcName[me.type] += 1;
					}
				}
			}
			foreach(key;keys(me.calcName)) {
				me.nameS = me.nameS~", "~me.calcName[key]~"x"~key;
			}
			me.nameS = right(me.nameS, size(me.nameS)-2);#remove initial comma
		}
		if(me.nameS == "" and me.currentSet != nil and size(me.currentSet.content)!=0) {
			me.nameS = nil;
		} elsif (me.nameS == "" and me.currentSet != nil and size(me.currentSet.content)==0) {
			me.nameS = me.currentSet.name;
		}
		if(me.nameS == "" or me.nameS == "Empty") {
			me.nameS = nil;
		}
		return me.nameS;
	},
	
	getCurrentSMSName: func {
		me.nameS = "";
		if (me.currentSet.showLongTypeInsteadOfCount) {
			foreach(me.wapny;me.weapons) {
				if (me.wapny != nil) {
					me.nameS = me.wapny.typeShort;
				}
			}
		} else {
			me.calcName = {};
			foreach(me.weapon;me.weapons) {
				if(me.weapon != nil) {
					me.type = me.weapon.typeShort;
					if (me.calcName[me.type]==nil) {
						me.calcName[me.type]=1;
					} else {
						me.calcName[me.type] += 1;
					}
				}
			}
			foreach(key;keys(me.calcName)) {
				me.nameS = me.nameS~", "~me.calcName[key]~" "~key;
			}
			me.nameS = right(me.nameS, size(me.nameS)-2);#remove initial comma
		}
		if(me.nameS == "" and me.currentSet != nil and size(me.currentSet.content)!=0) {
			me.nameS = nil;
		} elsif (me.nameS == "" and me.currentSet != nil and size(me.currentSet.content)==0) {
			me.nameS = me.currentSet.name;
		}
		if(me.nameS == "" or me.nameS == "Empty") {
			me.nameS = nil;
		}
		return me.nameS;
	},

	jettisonAll: func {
		# drops everything.
		if (me.weaponJettisonable) {
			me.tempWeapons = [];
		
			foreach(me.weapon ; me.getWeapons()) {
				if (me.weapon != nil) {
					me.weapon.eject();
					if (me.JettListener != nil) {
						me.JettListener(me.weapon);
					}
				}
				append(me.tempWeapons, nil);
			}
			me.jettisonLauncher();
			me.weapons = me.tempWeapons;
			me.calculateMass();
			me.calculateFDM();
			me.setGUI();
		}
	},

	jettisonLauncher: func {
		if (me.launcherJettisonable) {
			me.launcherMass = 0;
			me.launcherDA   = 0;
			me.launcherJettisoned = 1;
		}
	},
	
	loadingSet: func (set) {
		# override this method to set custom attributes, before calculateFDM is ran after a set is loaded.
		if (set != nil) {
			me.launcherDA   = set.launcherDragArea;
		} else {
			me.launcherDA   = 0;
		}
	},

	calculateFDM: func {
		# override this method to set custom FDM attributes.
		# do dragarea
		me.totalDA = 0;
		foreach(me.weapon;me.weapons) {
			if (me.weapon != nil) {
				me.totalDA += me.weapon.Cd_base*me.weapon.ref_area_sqft;
			}
		}
		me.totalDA += me.launcherDA;
		me.node_dragaera.setDoubleValue(me.totalDA);
	},
};

var SubModelWeapon = {
# Implements a fixed/attachable submodel station.
#  cannon/rockets and methods to give them commands.
#  should be able to hold submodels
#  handle tracers, infinite ammo when loaded, else zero.
#  no loop, but lots of listeners.
#
# Attributes:
#  drag, weight, submodel(s)
	new: func (name, munitionMass, maxAmmo, subModelNumbers, tracerSubModelNumbers, trigger, jettisonable, operableFunction=nil, alternate = 0) {
		var s = {parents:[SubModelWeapon]};
		s.type = name;
		s.typeLong = name;
		s.typeShort = name;
		s.subModelNumbers = subModelNumbers;
		s.tracerSubModelNumbers = tracerSubModelNumbers;
		s.operableFunction = operableFunction;
		s.maxAmmo = maxAmmo;
		s.munitionMass = munitionMass;
		s.jettisonable = jettisonable;
		s.weight_launch_lbm = 0;
		s.trigger = trigger;
		s.triggerNode = nil;
		s.active = 0;
		s.alternate = alternate;
		s.timer = nil;
		s.neverRan = 1;

		# these 2 needs to be here and be 0
		s.Cd_base = 0;
		s.ref_area_sqft = 0;

		
		return s;
	},

	loop: func {
		if (me.timer == nil) {settimer(func me.loop(), 0.5);return;}#bug in maketimer makes this loop need to run all the time :(
		me.ammo = me.getAmmo();#print("ammo "~me.ammo);
		for(me.i = 0;me.i<size(me.tracerSubModelNumbers);me.i+=1) {
			setprop("ai/submodels/submodel["~me.tracerSubModelNumbers[me.i]~"]/count",me.ammo>0?-1:0);
		}
		me.weight_launch_lbm = me.munitionMass*me.ammo;

		#not sure how smart it is to do this all the time, but..:
		if (me.active and (me.operableFunction == nil or me.operableFunction())) {
			if (me.trigger.getAliasTarget() == nil or me.trigger.getAliasTarget().getPath() != me.triggerNode.getPath()) {
				me.trigger.alias(me.triggerNode);
			}
		} else {
			if (me.trigger.getAliasTarget() != nil) {
				me.trigger.unalias();
			}
			me.trigger.setBoolValue(0);
		}
		settimer(func me.loop(), 0.1);
	},

	start: func (triggerNode = nil) {
		#print("starting gun");
		if (triggerNode==nil) {
			triggerNode=props.globals.getNode("controls/armament/trigger");
		}
		# not sure if this is smart
		me.active = 1;
		me.triggerNode = triggerNode;
	},

	stop: func {
		#print("stopping gun");
		# not sure if this is smart
		me.active = 0;
	},

	mount: func(pylon) {
		me.reloadAmmo();
		#if (me.timer != nil and me.timer.isRunning) me.timer.stop();
		#me.timer = nil;
		me.timer = 1;#maketimer(0.1, me, func me.loop());
		#me.timer.restart(0.1);
		#me.timer.start();

		if (me.neverRan) me.loop();
		me.neverRan = 0;		
	},

	eject: func {
		if (me.jettisonable) {
			#if (me.timer != nil and me.timer.isRunning) me.timer.stop();
			me.timer = nil;
			me.trigger.unalias();
			me.trigger.setBoolValue(0);
		}
	},

	del: func {
		#if (me.timer != nil and me.timer.isRunning) me.timer.stop();
		me.timer = nil;
		me.trigger.unalias();
		me.trigger.setBoolValue(0);
	},

	getAmmo: func () {
		# return ammo count
		var ammo = 0;
		for(me.i = 0;me.i<size(me.subModelNumbers);me.i+=1) {
			ammo += getprop("ai/submodels/submodel["~me.subModelNumbers[me.i]~"]/count");
		}
		return ammo;
	},

	reloadAmmo: func {
		for(me.i = 0;me.i<size(me.subModelNumbers);me.i+=1) {
			setprop("ai/submodels/submodel["~me.subModelNumbers[me.i]~"]/count", me.maxAmmo);
		}
	},
};

var FuelTank = {
# Implements a external fuel tank.
#  no loop, but lots of listeners.
#
# Attributes:
#  fuel tank number
	new: func (name, short, fuelTankNumber, capacity_gal, model_path) {
		var s = {parents:[FuelTank]};
		s.type = name;
		s.typeLong = name;
		s.typeShort = short;
		s.capacity = capacity_gal;
		s.fuelTankNumber = fuelTankNumber;
		s.modelPath = model_path;
		s.baseProperty = "/consumables/fuel/tank["~s.fuelTankNumber~"]/";
		# these 3 needs to be here and be 0
		s.Cd_base = 0;
		s.ref_area_sqft = 0;
		s.weight_launch_lbm = 0;
		return s;
	},

	mount: func(pylon) {
#		print(pylon.name);
		if (pylon.guiID != nil) {
			me.guiNode = props.globals.getNode(baseGui~"/weight["~pylon.guiID~"]",1);
			me.guiNode.initNode("tank",me.fuelTankNumber,"DOUBLE");
		}		

		# set capacity in fuel tank
		if (fdm == "jsb") {
			setprop("fdm/jsbsim/propulsion/tank["~me.fuelTankNumber~"]/external-flow-rate-pps", 0);
		}
		me.setv("capacity-gal_us", me.capacity);
		me.setv("level-gal_us", me.capacity);
		me.setv("selected", 1);
		me.setv("name", me.typeLong);
		setprop(me.modelPath, 1);
		setprop("sim/gui/dialogs/payload-reload",!getprop("sim/gui/dialogs/payload-reload"));
	},

	eject: func {
		# spill out all the fuel?
		#me.guiNode = props.globals.getNode(baseGui~"/weight["~pylon.guiID~"]",1);
		me.setv("capacity-gal_us", 0);
		me.setv("level-norm", 0);
		me.setv("selected", 0);
		me.setv("name", "Not attached");
		setprop(me.modelPath, 0);
		setprop("sim/gui/dialogs/payload-reload",!getprop("sim/gui/dialogs/payload-reload"));
		if (fdm == "jsb") {
			setprop("fdm/jsbsim/propulsion/tank["~me.fuelTankNumber~"]/external-flow-rate-pps", -1000);
		}
	},
	setv: func(p,v) {
    	#print(me.type," -> set ",me.baseProperty,p," = ",v);
		setprop(me.baseProperty~p,v);
	},
	del: func {
		# delete all the fuel
		me.setv("capacity-gal_us", 0);
		me.setv("level-norm", 0);
		me.setv("selected", 0);
		me.setv("name", "Not attached");
		setprop(me.modelPath, 0);
		setprop("sim/gui/dialogs/payload-reload",!getprop("sim/gui/dialogs/payload-reload"));
		if (fdm == "jsb") {
			setprop("fdm/jsbsim/propulsion/tank["~me.fuelTankNumber~"]/external-flow-rate-pps", -1000);
		}
	},

	getAmmo: func {
		# return 0
		return 0;
	},

	start: func {},
	stop: func {},
};

var Submodel = {
# Implements a generic model, e.g., smoker or pod.
#  no loop, but lots of listeners.
#
	new: func (name, short, model_path) {
		var s = {parents:[Submodel]};
		s.type = name;
		s.typeLong = name;
		s.typeShort = short;
		s.modelPath = model_path;

		# these 3 needs to be here and be 0
		s.Cd_base = 0;
		s.ref_area_sqft = 0;
		s.weight_launch_lbm = 0;
		return s;
	},

	mount: func(pylon) {
		setprop(me.modelPath, 1);
	},

	eject: func {
		setprop(me.modelPath, 0);
	},

	del: func {
		setprop(me.modelPath, 0);
	},

	getAmmo: func {
		return 0;
	},

	start: func {},
	stop: func {},
};

var Dummy = {
# Implements a non functional item.
#
	new: func (name, short) {
		var s = {parents:[Dummy]};
		s.type = name;
		s.typeLong = name;
		s.typeShort = short;

		# these 3 needs to be here and be 0
		s.Cd_base = 0;
		s.ref_area_sqft = 0;
		s.weight_launch_lbm = 0;
		return s;
	},

	mount: func(pylon) {},

	eject: func {},

	del: func {},

	getAmmo: func {
		return 0;
	},

	start: func {},
	stop: func {},
};
