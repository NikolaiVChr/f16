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

var Station = {
# pylon or fixed mounted weapon on the aircraft
	new: func (name, id, position, sets, guiID, pointmassNode, operableFunction = nil) {
		var p = {parents:[Station]};
		p.id = id;
		p.name = name;
		p.position = position;
		p.sets = sets;
		p.guiID = guiID;
		p.node_pointMass = pointmassNode;
		p.operableFunction = operableFunction;
		p.weapons = [];#when weapons are fired/jettisoned, they turn to nil, the vector size must stay same as fire-order dictates.
		p.changingGui = 0;
		p.launcherDA=0;
		p.launcherMass=0;
		p.guiListener = nil;
		p.currentName = nil;	
		p.currentSet = nil;
		p.myListener = nil;#will be called when a stations loadout changes from outside.
		p.AIMListener = nil;#will be called when a weapon is fired. argument=the weapon
		return p;
	},

	setAIMListener: func (f) {
		me.AIMListener = f;
	},

	getCategory: func {
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
		return me.currentName;
	},

	loadSet: func (set) {
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
					me.aim = armament.AIM.new(me.id*100+me.i, me.weaponName, "", nil, me.position);
					if (me.aim == -1) {
						print("Pylon could not create "~me.weaponName);
						me.aim = nil;
					}
					append(me.weapons, me.aim);
				} else {
					#print("Added submodel or fuel tank to Pylon");
					me.weaponName.mount();
					append(me.weapons, me.weaponName);
				}
			}
			me.launcherMass = set.launcherMass;
			me.launcherJettisonable = set.launcherJettisonable;
			me.currentSet   = set;
		} else {
			me.launcherMass = 0;
			me.launcherJettisonable = 0;
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
	},

	setPylonListener: func (ml) {
		me.myListener = ml;
	},

	calculateMass: func {
		# do mass
		me.totalMass = 0;
		me.singleName = "";#this is hack to show stores locally
		foreach(me.weapon;me.weapons) {
			if (me.weapon != nil) {
				me.totalMass += me.weapon.weight_launch_lbm;
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
	},

	getWeapons: func {
		return me.weapons;
	},

	fireWeapon: func (index) {
		if (index >= size(me.weapons) or index < 0) {
			print("Pylon recieved illegal fire operation. No such weapon.");
		} elsif (me.weapons[index] == nil) {
			print("Pylon received illegal fire operation. Already fired.");
		} elsif (me.operableFunction != nil and !me.operableFunction()) {
			print("Pylon could not fire weapon, its inoperable.");
		} elsif (me.weapons[index].parents[0] == armament.AIM) {
			me.bye = me.weapons[index];
			me.bye.release();
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

	getAmmo: func {
		me.ammo = [];
		foreach(me.weapon ; me.getWeapons()) {
			if (me.weapon != nil and me.weapon.parents[0] == armament.AIM) {
				append(me.ammo, 1);
			} elsif (me.weapon != nil and me.weapon.parents[0] == SubModelWeapon) {
				append(me.ammo, me.weapon.getAmmo());
			} else {
				append(me.ammo, 0);
			}
		}
		return me.ammo;
	},

	getAmmo: func (type) {
		me.ammo = 0;
		foreach(me.weapon ; me.getWeapons()) {
			if (me.weapon != nil and me.weapon.parents[0] == armament.AIM and me.weapon.type == type) {
				me.ammo += 1;
			} elsif (me.weapon != nil and me.weapon.parents[0] == SubModelWeapon and me.weapon.type == type) {
				me.ammo += me.weapon.getAmmo();
			}
		}
		return me.ammo;
	},

	findSetFromName: func (name) {
		foreach (me.set; me.sets) {
			if (me.set.name == name) {
				return me.set;
			}
		}
		return nil;
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

	setGUI: func {},
	initGUI: func {},
	jettisonAll: func {},
	jettisonLauncher: func {},
	getCurrentShortName: func {},
};

var InternalStation = {
# simulates a fixed station, for example a cannon mounted inside the aircraft
# inherits from Station
	new: func (name, id, sets, pointmassNode, operableFunction = nil) {
		var s = Station.new(name, id, [0,0,0], sets, nil, pointmassNode, operableFunction);
		s.parents = [InternalStation, Station];

		# these should not be called in parent.new(), as they are empty there.
		s.initGUI();
		s.loadSet(sets[0]);
		return s;
	}
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
	new: func (name, id, position, sets, guiID, pointmassNode, dragareaNode, operableFunction = nil) {
		var p = Station.new(name, id, position, sets, guiID, pointmassNode, operableFunction);
		p.parents = [Pylon, Station];
		p.node_dragaera = dragareaNode;

		# these should not be called in parent.new(), as they are empty there.
		p.initGUI();
		p.loadSet(sets[0]);
		return p;
	},

	guiChanged: func {
		#print("GUI changed");
		if(!me.changingGui) {
			me.desiredSet = getprop("payload/weight["~me.guiID~"]/selected");
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
		me.guiNode = props.globals.getNode("payload/weight["~me.guiID~"]",1);
		me.guiNode.removeAllChildren();
		me.guiNode.initNode("name",me.name,"STRING");
		me.guiNode.initNode("selected","","STRING");
		me.guiNode.initNode("weight-lb",0,"DOUBLE");
		me.i = 0;
		foreach(set ; me.sets) {
			me.guiNode.initNode("opt["~me.i~"]/name",set.name,"STRING");
			me.i += 1;
		}
		me.guiListener = setlistener("payload/weight["~me.guiID~"]/selected", func me.guiChanged());
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
		setprop("payload/weight["~me.guiID~"]/selected", me.nameGUI);
		setprop("payload/weight["~me.guiID~"]/weight-lb", me.node_pointMass.getValue());
		me.changingGui = 0;
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

	jettisonAll: func {
		# drops everything.
		me.tempWeapons = [];
		foreach(me.weapon ; me.getWeapons()) {
			if (me.weapon != nil) {
				me.weapon.eject();
			}
			append(me.tempWeapons, nil);
		}
		me.jettisonLauncher();
		me.weapons = me.tempWeapons;
		me.calculateMass();
		me.calculateFDM();
		me.setGUI();
	},

	jettisonLauncher: func {
		if (me.launcherJettisonable) {
			me.launcherMass = 0;
			me.launcherDA   = 0;
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
	new: func (name, munitionMass, maxAmmo, submodelNumber, tracerSubModelNumbers, trigger, jettisonable, operableFunction=nil) {
		var s = {parents:[SubModelWeapon]};
		s.type = name;
		s.typeLong = name;
		s.typeShort = name;
		s.submodelNumber = submodelNumber;
		s.tracerSubModelNumbers = tracerSubModelNumbers;
		s.operableFunction = operableFunction;
		s.maxAmmo = maxAmmo;
		s.munitionMass = munitionMass;
		s.jettisonable = jettisonable;
		s.weight_launch_lbm = 0;
		s.trigger = trigger;
		s.triggerNode = nil;
		s.active = 0;
		s.timer = maketimer(0.3, s, func s.loop());
		

		# these 2 needs to be here and be 0
		s.Cd_base = 0;
		s.ref_area_sqft = 0;

		return s;
	},

	loop: func {
		me.ammo = me.getAmmo();#print("ammo "~me.ammo);
		for(me.i = 0;me.i<size(me.tracerSubModelNumbers);me.i+=1) {
			setprop("ai/submodels/submodel["~me.tracerSubModelNumbers[me.i]~"]/count",me.ammo>0?-1:0);
		}
		me.weight_launch_lbm = me.munitionMass*me.ammo;

		#not sure how smart it is to do this all the time, but..:
		if (me.operableFunction != nil and !me.operableFunction()) {
			#print("gun missing hydraulics");
			me.trigger.unalias();
			me.trigger.setBoolValue(0);
		} else {
			if (me.active) {
				me.trigger.alias(me.triggerNode);
			} else {
				me.trigger.unalias();
				me.trigger.setBoolValue(0);
			}
		}
	},

	start: func (triggerNode = nil) {
		print("starting gun");
		if (triggerNode==nil) {
			triggerNode=props.globals.getNode("controls/armament/trigger");
		}
		# not sure if this is smart
		me.active = 1;
		me.triggerNode = triggerNode;
	},

	stop: func {
		print("stopping gun");
		# not sure if this is smart
		me.active = 0;
	},

	mount: func {
		me.reloadAmmo();
		me.timer.start();
		me.loop();
	},

	eject: func {
		if (me.jettisonable) {
			s.timer.stop();
			me.trigger.unalias();
			me.trigger.setBoolValue(0);
		}
	},

	del: func {
		s.timer.stop();
		me.trigger.unalias();
		me.trigger.setBoolValue(0);
	},

	getAmmo: func {
		# return ammo count
		return getprop("ai/submodels/submodel["~me.submodelNumber~"]/count");
	},

	reloadAmmo: func {
		setprop("ai/submodels/submodel["~me.submodelNumber~"]/count", me.maxAmmo);
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

		# these 3 needs to be here and be 0
		s.Cd_base = 0;
		s.ref_area_sqft = 0;
		s.weight_launch_lbm = 0;
		return s;
	},

	mount: func {
		# set capacity in fuel tank
		setprop("/consumables/fuel/tank["~me.fuelTankNumber~"]/capacity-gal_us", me.capacity);
		setprop("/consumables/fuel/tank["~me.fuelTankNumber~"]/level-gal_us", me.capacity);
		setprop("/consumables/fuel/tank["~me.fuelTankNumber~"]/selected", 1);
		setprop("/consumables/fuel/tank["~me.fuelTankNumber~"]/name", me.typeLong);
		setprop(me.modelPath, 1);
	},

	eject: func {
		# spill out all the fuel?
		setprop("/consumables/fuel/tank["~me.fuelTankNumber~"]/capacity-gal_us", 0);
		setprop("/consumables/fuel/tank["~me.fuelTankNumber~"]/level-norm", 0);
		setprop("/consumables/fuel/tank["~me.fuelTankNumber~"]/selected", 0);
		setprop("/consumables/fuel/tank["~me.fuelTankNumber~"]/name", "Not attached");
		setprop(me.modelPath, 0);
	},

	del: func {
		# delete all the fuel
		setprop("/consumables/fuel/tank["~me.fuelTankNumber~"]/capacity-gal_us", 0);
		setprop("/consumables/fuel/tank["~me.fuelTankNumber~"]/level-norm", 0);
		setprop("/consumables/fuel/tank["~me.fuelTankNumber~"]/selected", 0);
		setprop("/consumables/fuel/tank["~me.fuelTankNumber~"]/name", "Not attached");
		setprop(me.modelPath, 0);
	},

	getAmmo: func {
		# return 0
		return 0;
	},

	start: func {},
	stop: func {},
};

var Smoker = {
# Implements a external fuel tank.
#  no loop, but lots of listeners.
#
# Attributes:
#  fuel tank number
	new: func (name, short, model_path) {
		var s = {parents:[Smoker]};
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

	mount: func {
		# set capacity in fuel tank
		setprop(me.modelPath, 1);
	},

	eject: func {
		# spill out all the fuel?
		setprop(me.modelPath, 0);
	},

	del: func {
		# delete all the fuel
		setprop(me.modelPath, 0);
	},

	getAmmo: func {
		# return 0
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

	mount: func {
		
	},

	eject: func {
		# spill out all the fuel?
		
	},

	del: func {
		# delete all the fuel
		
	},

	getAmmo: func {
		# return 0
		return 0;
	},

	start: func {},
	stop: func {},
};