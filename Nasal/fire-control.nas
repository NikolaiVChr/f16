#a better fire-control system:
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
var RIPPLE_INTERVAL_METERS = 0;
var RIPPLE_INTERVAL_SECONDS = 1;
var DROP_CCRP = 0;
var DROP_CCIP = 1;
var GUN_STRF = 0;
var GUN_EEGS = 1;
var FireControl = {
	new: func (pylons, pylonOrder, typeOrder) {
		var fc = {parents:[FireControl]};
		fc.pylons = pylons;
		foreach(pyl;pylons) {
			pyl.setPylonListener(fc);
		}
		fc.selected = nil;        # vector [pylonNumber, weaponNumber]
		fc.selectedAdd = nil;     # vector of above kind of vectors
		fc.pylonOrder=pylonOrder; # vector with order the pylons should select/fire weapons from
		fc.typeOrder=typeOrder;   # vector with order the types should be selected in
		fc.selectedType = nil;    # string with current selected type
		fc.triggerTime = 0;       # a timer for firing maddog
		fc.gunTriggerTime = 0;    # a timer for how often to use gun brevity
		fc.ripple = 1;            # ripple setting, from 1 to x.
		fc.rippleR = 1;           # ripple setting for submodels, from 1 to x. Seperate from fc.ripple due to allowing different max count.
		fc.rippleDist = 150*FT2M; # ripple setting, in meters.
		fc.rippleDelay = 2.0;     # ripple setting, in seconds.
		fc.rippleInterval = RIPPLE_INTERVAL_METERS;
		fc.isRippling = 0;        # is in ripple progress
		fc.WeaponNotification = VectorNotification.new("WeaponNotification");
		fc.setupMFDObservers();
		fc.dropMode = 0;          # 0=ccrp, 1 = ccip
		fc.changeListener = nil;
		setlistener("controls/armament/trigger",func{fc.trigger();fc.updateDual()},nil,0);
		#setlistener("controls/armament/master-arm",func{fc.updateCurrent()},nil,0);
		setlistener(masterArmSwitch,func{fc.masterArmSwitch()},nil,0);
		setlistener("controls/armament/dual",func{fc.updateDual()},nil,0);
		setlistener("sim/signals/reinit",func{fc.updateMass()},nil,0);
		return fc;
	},

	updateMass: func {
		# JSBSim seems to reset all properties under fdm/jsbsim/inertia at reinit, so we need to repopulate them.
		foreach (var p;me.pylons) {
			p.calculateMass();
			p.calculateFDM();
		}
	},

	cage: func (cageIt) {
		foreach (var p;me.pylons) {
			var ws = p.getWeapons();
			foreach (var w;ws) {
				if (w != nil and w.parents[0] == armament.AIM and (w.guidance == "heat" and w.target_air)) {# or w.guidance=="vision"
					w.setCaged(cageIt);
				}
			}
		}
	},

	isCaged: func () {
		foreach (var p;me.pylons) {
			var ws = p.getWeapons();
			foreach (var w;ws) {
				if (w != nil and w.parents[0] == armament.AIM and (w.guidance == "heat" and w.target_air)) {# or w.guidance=="vision"
					return w.isCaged();
				}
			}
		}
		return 1;
	},

	toggleCage: func () {
		var c = 0;
		foreach (var p;me.pylons) {
			var ws = p.getWeapons();
			foreach (var w;ws) {
				if (w != nil and w.parents[0] == armament.AIM and (w.guidance == "heat" and w.target_air)) {# or w.guidance=="vision"
					c = w.isCaged()?1:-1;
					break;
				}
			}
			if (c != 0) break;
		}
		if (c != 0) me.cage(c==-1?1:0);
	},

	setAutocage: func (auto) {
		foreach (var p;me.pylons) {
			var ws = p.getWeapons();
			foreach (var w;ws) {
				if (w != nil and w.parents[0] == armament.AIM and (w.guidance == "heat" and w.target_air)) {# or w.guidance=="vision"
					w.setAutoUncage(auto);
				}
			}
		}
	},

	isAutocage: func () {
		foreach (var p;me.pylons) {
			var ws = p.getWeapons();
			foreach (var w;ws) {
				if (w != nil and w.parents[0] == armament.AIM and (w.guidance == "heat" and w.target_air)) {# or w.guidance=="vision"
					return w.isAutoUncage();
				}
			}
		}
		return 1;
	},

	setXfov: func (xfov) {
		foreach (var p;me.pylons) {
			var ws = p.getWeapons();
			foreach (var w;ws) {
				if (w != nil and w.parents[0] == armament.AIM and (w.guidance == "heat" and w.target_air)) {# or w.guidance=="vision"
					w.setSEAMscan(xfov);
				}
			}
		}
	},

	isXfov: func () {
		foreach (var p;me.pylons) {
			var ws = p.getWeapons();
			foreach (var w;ws) {
				if (w != nil and w.parents[0] == armament.AIM and (w.guidance == "heat" and w.target_air)) {# or w.guidance=="vision"
					return w.isSEAMscan();
				}
			}
		}
		return 0;
	},

	toggleXfov: func () {
		var x = 0;
		foreach (var p;me.pylons) {
			var ws = p.getWeapons();
			foreach (var w;ws) {
				if (w != nil and w.parents[0] == armament.AIM and (w.guidance == "heat" and w.target_air)) {# or w.guidance=="vision"
					x = w.isSEAMscan()?1:-1;
					break;
				}
			}
			if (x != 0) break;
		}
		if (x != 0) me.setXfov(x==-1?1:0);
	},
	
	getDropMode: func {
		#0=ccrp, 1 = ccip
		me.dropMode;
	},
	
	setDropMode: func (mode) {
		#0=ccrp, 1 = ccip
		me.dropMode = mode;
	},
	
	getRippleMode: func {
		me.ripple;
	},
	
	setRippleMode: func (ripple) {
		if (ripple >= 1) {
			me.ripple = int(ripple);
		}
	},

	getRRippleMode: func {
		me.rippleR;
	},
	
	setRRippleMode: func (rippleR) {
		if (rippleR >= 1) {
			me.rippleR = int(rippleR);
		}
	},

	setRippleIntervalType: func (type) {
		if (type == RIPPLE_INTERVAL_METERS) {
			me.rippleInterval = type;
		} elsif (type == RIPPLE_INTERVAL_SECONDS) {
			me.rippleInterval = type;
		}
	},
	
	getRippleDist: func {
		# meters
		me.rippleDist;
	},
	
	setRippleDist: func (rippleDist) {
		# meters
		if (rippleDist >= 0) {
			me.rippleDist = rippleDist;
		}
	},

	getRippleDelay: func {
		me.rippleDelay;
	},
	
	setRippleDelay: func (rippleDelay) {
		if (rippleDelay >= 0) {
			me.rippleDelay = rippleDelay;
		}
	},
	
	getSelectedType: func {
		return me.selectedType;
	},

	togglePowerOn: func () {
		me.myType = me.getSelectedType();
		if (me.myType == nil) return;
		me.myWeaps = me.getAllOfType(me.myType);
		me.currPow = 0;
		if (me.myWeaps != nil and size(me.myWeaps) and me.myWeaps[0].parents[0] == armament.AIM) {
			me.currPow = me.myWeaps[0].isPowerOn();
			foreach (me.myWeap ; me.myWeaps) {
				me.myWeap.setPowerOn(!me.currPow);
			}
		}
	},

	getCategory: func {
		# get loadout CAT (not to be confused with FBW CAT setting)
		me.cat = 1;
		foreach (pyl;me.pylons) {
			if (pyl.getCategory()>me.cat) {
				me.cat = pyl.getCategory();
			}
		}
		return me.cat;
	},

	setChangeListener: func (l) {
		# install a listener in this station that get called when an armament.AIM weapon is released or selected pylon changed.
		me.changeListener = l;
	},

	setupMFDObservers: func {
		me.FireControlRecipient = emesary.Recipient.new("FireControlRecipient");
		me.FireControlRecipient.Receive = func(notification) {
	        if (notification.NotificationType == "WeaponRequestNotification") {
	        	#printfDebug("FireControlRecipient recv: %s", notification.NotificationType);
	        	if (me.selected != nil) {
					me.WeaponNotification.updateV(me.pylons[me.selected[0]].getWeapons()[me.selected[1]]);
					emesary.GlobalTransmitter.NotifyAll(me.WeaponNotification);
				}
	            return emesary.Transmitter.ReceiptStatus_OK;
	        } elsif (notification.NotificationType == "WeaponCommandNotification") {
	        	#printfDebug("FireControlRecipient recv: %s", notification.NotificationType);
	            if (notification.cooling == 1) {
	    		    #toggle all heatseekers to cool
	    	    }
	    	    if (notification.bore == 1) {
	    		    #toggle all heatseekers to bore
	    	    }
	    	    if (notification.slave == 1) {
	    		    #toggle all heatseekers to slave
	    	    }
	    	    # etc etc
	            return emesary.Transmitter.ReceiptStatus_OK;
	        } elsif (notification.NotificationType == "CycleWeaponNotification") {
	        	#printfDebug("FireControlRecipient recv: %s", notification.NotificationType);
	        	me.cycleWeapon();
	            return emesary.Transmitter.ReceiptStatus_OK;
	        }
	        return emesary.Transmitter.ReceiptStatus_NotProcessed;
	    };
		emesary.GlobalTransmitter.Register(me.FireControlRecipient);
	},

	cycleWeapon: func {
		# it will cycle to next weapon type, even if that one is empty.
		me.triggerTime = 0;
		me.stopCurrent();
		me.selWeapType = me.selectedType;
		if (me.selWeapType == nil) {
			me.selectedType = me.typeOrder[0];
			if (me.nextWeapon(me.typeOrder[0]) != nil) {
				printfDebug("FC: Selected first weapon: %s on pylon %d position %d",me.selectedType,me.selected[0],me.selected[1]);
			} else {
				printfDebug("FC: Selected first weapon: %s, but none is loaded.", me.selectedType);
			}
		} else {
			me.selType = me.selectedType;
			printfDebug("Already selected %s",me.selType);
			me.selTypeIndex = me.vectorIndex(me.typeOrder, me.selType);
			me.selTypeIndex += 1;
			if (me.selTypeIndex >= size(me.typeOrder)) {
				me.selTypeIndex = 0;
			}
			me.selectedType = me.typeOrder[me.selTypeIndex];
			me.selType = me.selectedType;
			printfDebug(" Now selecting %s",me.selType);
			me.wp = me.nextWeapon(me.selType);
			if (me.wp != nil) {			
				printfDebug("FC: Selected next weapon type: %s on pylon %d position %d",me.selectedType,me.selected[0],me.selected[1]);
			} else {
				printfDebug("FC: Selected next weapon type: %s, but none is loaded.", me.selectedType);
			}
		}
		screen.log.write("Selected "~me.selectedType, 0.5, 0.5, 1);
	},

	cycleLoadedWeapon: func {
		# it will cycle to next weapon type that is not empty.
		me.triggerTime = 0;
		me.stopCurrent();
		me.selWeapType = me.selectedType;
		if (me.selWeapType == nil) {
			me.selTypeIndex = -1;
			me.cont = size(me.typeOrder);
		} else {
			me.selType = me.selectedType;
			printfDebug("Already selected %s",me.selType);
			me.selTypeIndex = me.vectorIndex(me.typeOrder, me.selType);
			me.cont = me.selTypeIndex;
		}
		me.selTypeIndex += 1;
		while (me.selTypeIndex != me.cont) {
			if (me.selTypeIndex >= size(me.typeOrder)) {
				me.selTypeIndex = 0;
			}
			me.selectedType = me.typeOrder[me.selTypeIndex];
			me.selType = me.selectedType;
			printfDebug(" Now selecting %s",me.selType);
			me.wp = me.nextWeapon(me.selType);
			if (me.wp != nil) {			
				printfDebug("FC: Selected next weapon type: %s on pylon %d position %d",me.selectedType,me.selected[0],me.selected[1]);
				screen.log.write("Selected "~me.selectedType, 0.5, 0.5, 1);
				return;
			}
			me.selTypeIndex += 1;
		}		
		me.selected = nil;
		me.selectedAdd = nil;
		me.selectedType = nil;
		screen.log.write("Selected nothing", 0.5, 0.5, 1);
		if (me.changeListener != nil) me.changeListener();
	},

	cycleBackLoadedWeapon: func {
		# it will cycle to prev weapon type that is not empty.
		me.triggerTime = 0;
		me.stopCurrent();
		me.selWeapType = me.selectedType;
		if (me.selWeapType == nil) {
			me.selTypeIndex = -1;
			me.cont = size(me.typeOrder);
		} else {
			me.selType = me.selectedType;
			printfDebug("Already selected %s",me.selType);
			me.selTypeIndex = me.vectorIndex(me.typeOrder, me.selType);
			me.cont = me.selTypeIndex;
		}
		me.selTypeIndex -= 1;
		while (me.selTypeIndex != me.cont) {
			if (me.selTypeIndex < 0) {
				me.selTypeIndex = size(me.typeOrder)-1;
			}
			me.selectedType = me.typeOrder[me.selTypeIndex];
			me.selType = me.selectedType;
			printfDebug(" Now selecting %s",me.selType);
			me.wp = me.nextWeapon(me.selType);
			if (me.wp != nil) {			
				printfDebug("FC: Selected prev weapon type: %s on pylon %d position %d",me.selectedType,me.selected[0],me.selected[1]);
				screen.log.write("Selected "~me.selectedType, 0.5, 0.5, 1);
				return;
			}
			me.selTypeIndex -= 1;
		}		
		me.selected = nil;
		me.selectedAdd = nil;
		me.selectedType = nil;
		screen.log.write("Selected nothing", 0.5, 0.5, 1);
		if (me.changeListener != nil) me.changeListener();
	},

	cycleStation: func {
		if (me.selectedType != nil) {
			me.stopCurrent();
			me.nextWeapon(me.selectedType);
		}
	},

	_isSelectedWeapon: func {
		# tests if current selection is a fireable weapon
		if (me.selectedType != nil) {
			if (find(" ", me.selectedType) != -1) {
				return 0;
			}
			me.first = left(me.selectedType,1);
			if (me.first == "0" or me.first == "1" or me.first == "2" or me.first == "3" or me.first == "4" or me.first == "5" or me.first == "6" or me.first == "7" or me.first == "8" or me.first == "9") {
				return 0;
			}
			if (getprop("payload/armament/"~string.lc(me.selectedType)~"/class") != nil) {
				return 1;
			}
		}
		return 0;
	},

	cycleAG: func {
		# will stop current weapon and select next A-G weapon and start it.
		# horrible programming though, but since its called seldom and in no loop, it will do for now.
		me.stopCurrent();
		if (!me._isSelectedWeapon()) {
			me.selected = nil;
			me.selectedAdd = nil;
			me.selectedType = nil;
		}
		if (me.selectedType == nil) {
			foreach (me.typeTest;me.typeOrder) {
				me.first = left(me.typeTest,1);
				if (me.first == "0" or me.first == "1" or me.first == "2" or me.first == "3" or me.first == "4" or me.first == "5" or me.first == "6" or me.first == "7" or me.first == "8" or me.first == "9") {
					continue;
				}
				me.class = getprop("payload/armament/"~string.lc(me.typeTest)~"/class");
				if (me.typeTest == defaultRocket) me.class = "G";
				if (me.class != nil) {
					me.isAG = find("G", me.class)!=-1 or find("M", me.class)!=-1 or find("P", me.class)!=-1;
					if (me.isAG) {
						me.selType = me.nextWeapon(me.typeTest);
						if (me.selType != nil) {
							#me.updateCurrent();
							me.selectedType = me.selType.type;
							screen.log.write("Selected "~me.selectedType, 0.5, 0.5, 1);
							return;
						}
					}
				}
			}
		} else {
			me.hasSeen = 0;
			foreach (me.typeTest;me.typeOrder) {
				me.first = left(me.typeTest,1);
				if (me.first == "0" or me.first == "1" or me.first == "2" or me.first == "3" or me.first == "4" or me.first == "5" or me.first == "6" or me.first == "7" or me.first == "8" or me.first == "9") {
					continue;
				}
				if (!me.hasSeen) {
					if (me.typeTest == me.selectedType) {
						me.hasSeen = 1;
					} 
					continue;
				}
				me.class = getprop("payload/armament/"~string.lc(me.typeTest)~"/class");
				if (me.typeTest == defaultRocket) me.class = "G";
				if (me.class != nil) {
					me.isAG = find("G", me.class)!=-1 or find("M", me.class)!=-1 or find("P", me.class)!=-1;
					if (me.isAG) {
						me.selType = me.nextWeapon(me.typeTest);
						if (me.selType != nil) {
							#me.updateCurrent();
							me.selectedType = me.selType.type;
							screen.log.write("Selected "~me.selectedType, 0.5, 0.5, 1);
							return;
						}
					}
				}
			}
			if (me.hasSeen) {
				foreach (me.typeTest;me.typeOrder) {
					me.first = left(me.typeTest,1);
					if (me.first == "0" or me.first == "1" or me.first == "2" or me.first == "3" or me.first == "4" or me.first == "5" or me.first == "6" or me.first == "7" or me.first == "8" or me.first == "9") {
						continue;
					}
					if (me.typeTest == me.selectedType) {
						me.selType = me.nextWeapon(me.typeTest);
						if (me.selType != nil and ((me.selType.parents[0] == armament.AIM and (me.selType.target_gnd == 1 or me.selType.target_sea==1)) or me.typeTest == defaultRocket)) {
							#me.updateCurrent();
							me.selectedType = me.selType.type;
							screen.log.write("Selected "~me.selectedType, 0.5, 0.5, 1);
							return;
						} else {
							me.selectedType = nil;
							me.selectedAdd = nil;
							me.selected = nil;
							screen.log.write("Selected nothing", 0.5, 0.5, 1);
						}
						return;
					}
					me.class = getprop("payload/armament/"~string.lc(me.typeTest)~"/class");
					if (me.typeTest == defaultRocket) me.class = "G";
					if (me.class != nil) {
						me.isAG = find("G", me.class)!=-1 or find("M", me.class)!=-1 or find("P", me.class)!=-1;
						if (me.isAG) {
							me.selType = me.nextWeapon(me.typeTest);
							if (me.selType != nil) {
								me.selectedType = me.selType.type;
								#me.updateCurrent();
								screen.log.write("Selected "~me.selectedType, 0.5, 0.5, 1);
								return;
							}
						}
					}
				}
			}
		}
		if (me.selectedType != nil) {
			me.stopCurrent();
		}
		
		me.selectedType = defaultCannon;
		me.nextWeapon(me.selectedType);
		
		me.selectedAdd = nil;
		me.updateDual();
	},

	isAAMode: func {
		if (me.selectedType != nil) {
			if (me.selectedType == defaultRocket) {
				return 0;
			}
			if (me.selectedType == defaultCannon) {
				return !getprop("f16/avionics/strf");
			}
			me.waa = me.getSelectedWeapon();
			if (me.waa != nil and me.waa["parents"][0] == armament.AIM) {
				return me.waa.target_air;
			} elsif (me.selectedType == "CATM-9L" or me.selectedType == "CATM-120B" or me.selectedType == "AN-T-17") {
				# Dummy A-A weapons
				return 1;
			} 
			return 0;
		}
		return 0;
	},

	cycleAA: func {
		# will stop current weapon and select next A-A weapon and start it.
		me.stopCurrent();
		if (!me._isSelectedWeapon()) {
			me.selected = nil;
			me.selectedAdd = nil;
			me.selectedType = nil;
		}
		if (me.selectedType == nil) {
			foreach (me.typeTest;me.typeOrder) {
				me.first = left(me.typeTest,1);
				if (me.first == "0" or me.first == "1" or me.first == "2" or me.first == "3" or me.first == "4" or me.first == "5" or me.first == "6" or me.first == "7" or me.first == "8" or me.first == "9") {
					continue;
				}
				me.class = getprop("payload/armament/"~string.lc(me.typeTest)~"/class");
				if (me.class != nil) {
					me.isAG = find("A", me.class)!=-1;
					if (me.isAG) {
						me.selType = me.nextWeapon(me.typeTest);
						if (me.selType != nil) {
							me.selectedType = me.selType.type;
							#me.updateCurrent();
							screen.log.write("Selected "~me.selectedType, 0.5, 0.5, 1);
							return;
						}
					}
				}
			}
		} else {
			me.hasSeen = 0;
			foreach (me.typeTest;me.typeOrder) {
				me.first = left(me.typeTest,1);
				if (me.first == "0" or me.first == "1" or me.first == "2" or me.first == "3" or me.first == "4" or me.first == "5" or me.first == "6" or me.first == "7" or me.first == "8" or me.first == "9") {
					continue;
				}
				if (!me.hasSeen) {
					if (me.typeTest == me.selectedType) {
						me.hasSeen = 1;
					} 
					continue;
				}
				me.class = getprop("payload/armament/"~string.lc(me.typeTest)~"/class");
				if (me.class != nil) {
					me.isAG = find("A", me.class)!=-1;
					if (me.isAG) {
						me.selType = me.nextWeapon(me.typeTest);
						if (me.selType != nil) {
							me.selectedType = me.selType.type;
							#me.updateCurrent();
							screen.log.write("Selected "~me.selectedType, 0.5, 0.5, 1);
							return;
						}
					}
				}
			}
			if (me.hasSeen) {
				foreach (me.typeTest;me.typeOrder) {
					me.first = left(me.typeTest,1);
					if (me.first == "0" or me.first == "1" or me.first == "2" or me.first == "3" or me.first == "4" or me.first == "5" or me.first == "6" or me.first == "7" or me.first == "8" or me.first == "9") {
						continue;
					}
					if (me.typeTest == me.selectedType) {
						me.selType = me.nextWeapon(me.typeTest);
						if (me.selType != nil and me.selType.parents[0] == armament.AIM and me.selType.target_air==1) {
							#me.updateCurrent();
							me.selectedType = me.selType.type;
							screen.log.write("Selected "~me.selectedType, 0.5, 0.5, 1);
							return;
						} else {
							me.selectedType = nil;
							me.selected = nil;
							me.selectedAdd = nil;
							screen.log.write("Selected nothing", 0.5, 0.5, 1);
						}
						return;
					}
					me.class = getprop("payload/armament/"~string.lc(me.typeTest)~"/class");
					if (me.class != nil) {
						me.isAG = find("A", me.class)!=-1;
						if (me.isAG) {
							me.selType = me.nextWeapon(me.typeTest);
							if (me.selType != nil) {
								me.selectedType = me.selType.type;
								#me.updateCurrent();
								screen.log.write("Selected "~me.selectedType, 0.5, 0.5, 1);
								return;
							}
						}
					}
				}
			}
		}
		if (me.selectedType != nil) {
			me.stopCurrent();
		}
		
		me.selectedType = defaultCannon;
		me.nextWeapon(me.selectedType);
		
		me.selectedAdd = nil;
		if (me.changeListener != nil) me.changeListener();
	},

	updateAll: func {
		# called from the stations when they change.
		if (me.selectedType != nil) {
			screen.log.write("Fire-control: deselecting "~me.selectedType, 1, 0.5, 0.5);
		}
		me.noWeapon();
	},

	getSelectedWeapon: func {
		# return selected weapon or nil
		if (me.selected == nil) {
			return nil;
		}
		if (me.selected[1] > size(me.pylons[me.selected[0]].getWeapons())-1) {
			return nil;
		}
		return me.pylons[me.selected[0]].getWeapons()[me.selected[1]];
	},

	weaponHot: func {
		if (me.getSelectedWeapon() == nil) {
			return 0;
		}
		if (me.getSelectedPylon().operableFunction != nil and !me.getSelectedPylon().operableFunction()) {
			return 0;
		}
		if (me.getSelectedPylon().activeFunction != nil and !me.getSelectedPylon().activeFunction()) {
			return 0;
		}
		return me.getSelectedPylon().getAmmo() > 0;
	},
	
	_getSpecificWeapon: func (p, w) {
		# return specific weapon or nil
		if (w < 0 or w > size(me.pylons[p].getWeapons())-1) {
			return nil;
		}
		return me.pylons[p].getWeapons()[w];
	},
	
	getSelectedWeapons: func {
		# return selected weapons or nil
		if (me.selected == nil) {
			return nil;
		}
		if (me.selected[1] > size(me.pylons[me.selected[0]].getWeapons())-1) {
			return nil;
		}
		me.sw = [];
		if (me.pylons[me.selected[0]].getWeapons()[me.selected[1]] != nil) {
			append(me.sw, me.pylons[me.selected[0]].getWeapons()[me.selected[1]]);
		}
		if (me.selectedAdd != nil) {
			foreach(me.sweap ; me.selectedAdd) {
				if (me.sweap[1] > size(me.pylons[me.sweap[0]].getWeapons())-1) {
					continue;
				}
				if (me.pylons[me.sweap[0]].getWeapons()[me.sweap[1]] != nil) {
					append(me.sw, me.pylons[me.sweap[0]].getWeapons()[me.sweap[1]]);
				}
			}
		}
		return me.sw;
	},
	
	getSelectedDualWeapons: func {
		# return selected dual weapons or nil
		if (me.selected == nil) {
			return nil;
		}
		if (me.selected[1] > size(me.pylons[me.selected[0]].getWeapons())-1) {
			return nil;
		}
		me.sw = [];
		if (me.selectedAdd != nil) {
			foreach(me.sweap ; me.selectedAdd) {
				if (me.sweap[1] > size(me.pylons[me.sweap[0]].getWeapons())-1) {
					continue;
				}
				if (me.pylons[me.sweap[0]].getWeapons()[me.sweap[1]] != nil) {
					append(me.sw, me.pylons[me.sweap[0]].getWeapons()[me.sweap[1]]);
				}
			}
		}
		return me.sw;
	},

	getSelectedPylon: func {
		# return selected pylon or nil
		if (me.selected == nil) {
			return nil;
		}
		return me.pylons[me.selected[0]];
	},

	isLock: func {
		# returns if current weapon has lock
		me.wpn = me.getSelectedWeapon();
		if (me.wpn != nil and me.wpn.parents[0] == armament.AIM and me.wpn.status==armament.MISSILE_LOCK) {
			return 1;
		}
		return 0;
	},

	jettisonSelectedPylonContent: func {
		# jettison selected pylon
		if (me.selected == nil) {
			printDebug("Nothing to jettison");
			return nil;
		}
		if (!me.pylons[me.selected[0]].isOperable()) {
			printDebug("Jettison not working");
			return nil;
		}
		me.stopCurrent();
		me.pylons[me.selected[0]].jettisonAll();
		me.selected = nil;
		me.selectedAdd = nil;
		if (me.selectedType != nil) {
			me.nextWeapon(me.selectedType);
		}
		if (me.changeListener != nil) me.changeListener();
	},

	toggleStationForSJ: func (number) {
		me.activateSJ();
		me.sjSelect[number] = !me.sjSelect[number];
	},

	activateSJ: func {
		if (me["sjSelect"] == nil) {
			me.sjSelect = setsize([], size(me.pylons));
			for(var i=0;i<size(me.pylons);i+=1) {
				me.sjSelect[i] = 0;
			}
		}
	},

	isSelectStationForSJ: func (number) {
		me.activateSJ();
		return me.sjSelect[number];
	},

	clearStationForSJ: func {
		me.sjSelect = nil;
	},

	jettisonSJContent: func {
		# jettison S-J pylon
		if (getprop("controls/armament/master-arm-switch") != pylons.ARM_ARM or getprop("fdm/jsbsim/elec/bus/emergency-dc-1") < 20 or !(getprop("f16/avionics/gnd-jett") or !getprop("gear/gear[0]/wow"))) {
			me.clearStationForSJ();
			return nil;
		}
		if (me["sjSelect"] == nil) {
			printDebug("Nothing to jettison");
			return nil;
		}
		for(var i=0;i<size(me.pylons);i+=1) {
			if(me.sjSelect[i]) {

				if (!me.pylons[i].isOperable()) {
					printDebug("Jettison not working for station "~(i+1));
					continue;
				}
				if (me.selected != nil and me.selected[0] == i) {
					me.stopCurrent();
				}
				me.pylons[i].jettisonAll();
				if (me.selected != nil and me.selected[0] == i) {
					me.selected = nil;
					me.selectedAdd = nil;
					if (me.selectedType != nil) {
						me.nextWeapon(me.selectedType);
					}
				}
			}
		}
		me.clearStationForSJ();
		if (me.changeListener != nil) me.changeListener();
	},

	jettisonAll: func {
		# jettison all stations
		foreach (pyl;me.pylons) {
			if (!pyl.isOperable()) {
				continue;
			}
			pyl.jettisonAll();
		}
		if (me.changeListener != nil) me.changeListener();
	},

	jettisonFuelAndAG: func (exclude = nil) {
		# jettison all fuel and A/G stations.
		foreach (pyl;me.pylons) {
			me.myWeaps = pyl.getWeapons();
			if (me.myWeaps != nil and size(me.myWeaps)>0) {
				if (me.myWeaps[0] != nil and me.myWeaps[0].parents[0] == armament.AIM and me.myWeaps[0].target_air == 1) {
					continue;
				}
			}
			if (exclude!=nil and me.vectorIndex(exclude, pyl.id) != -1) {
				# excluded
				continue;
			}
			if (!pyl.isOperable()) {
				continue;
			}
			pyl.jettisonAll();
		}
		if (me.changeListener != nil) me.changeListener();
	},
	
	jettisonSpecificPylons: func (list, also_heat) {
		# jettison commanded pylons
		foreach (pyl;me.pylons) {
			if (list !=nil and me.vectorIndex(list, pyl.id) != -1) {
				if (!also_heat) {
					me.myWeaps = pyl.getWeapons();
					if (me.myWeaps != nil and size(me.myWeaps)>0) {
						if (me.myWeaps[0] != nil and me.myWeaps[0].parents[0] == armament.AIM and me.myWeaps[0].guidance == "heat") {
							continue;
						}
					}
				}
				if (!pyl.isOperable()) {
					continue;
				}
				pyl.jettisonAll();
			}			
		}
		if (me.changeListener != nil) me.changeListener();
	},
	
	jettisonAllButHeat: func (exclude = nil) {
		# jettison all but heat seekers.
		foreach (pyl;me.pylons) {
			me.myWeaps = pyl.getWeapons();
			if (me.myWeaps != nil and size(me.myWeaps)>0) {
				if (me.myWeaps[0] != nil and me.myWeaps[0].parents[0] == armament.AIM and me.myWeaps[0].guidance == "heat") {
					continue;
				}
			}
			if (exclude!=nil and me.vectorIndex(exclude, pyl.id) != -1) {
				# excluded
				continue;
			}
			pyl.jettisonAll();
		}
		if (me.changeListener != nil) me.changeListener();
	},

	jettisonFuel: func {
		# jettison all fuel stations
		foreach (pyl;me.pylons) {
			me.myWeaps = pyl.getWeapons();
			if (me.myWeaps != nil and size(me.myWeaps)>0) {
				if (me.myWeaps[0] != nil and me.myWeaps[0].parents[0] == armament.AIM) {
					continue;
				}
			}
			pyl.jettisonAll();
		}
		if (me.changeListener != nil) me.changeListener();
	},

	getSelectedPylonNumber: func {
		# return selected pylon index or nil
		if (me.selected == nil) {
			return nil;
		}
		return me.selected[0];
	},
	
	selectWeapon: func (w) {
		me.stopCurrent();
		me.selectedType = w;
		var nw = me.nextWeapon(w);
		return nw;
	},
	
	selectNothing: func {
		me.stopCurrent();
		me.selectedType = nil;
		me.selected = nil;
		if (me.changeListener != nil) me.changeListener();
	},
	
	selectPylon: func (p, w=nil) {
		# select a specified pylon
		# will stop previous weapon, will start next.
		me.triggerTime = 0;
		if (size(me.pylons) > p) {
			me.ws = me.pylons[p].getWeapons();
			if (me.ws != nil and w != nil and size(me.ws) > w and me.ws[w] != nil) {
				me.stopCurrent();
				me.selected = [p, w];
				me.selectedType = me.ws[w].type;
				me.updateDual();
				if (me.changeListener != nil) me.changeListener();
				return;
			} elsif (me.ws != nil and w == nil and size(me.ws) > 0) {
				w = 0;
				foreach(me.wp;me.ws) {
					if (me.wp != nil) {
						me.stopCurrent();
						me.selected = [p, w];
						me.selectedType = me.ws[w].type;
						me.updateDual();
						if (me.changeListener != nil) me.changeListener();
						return;
					}
					w+=1;
				}
			}
		}
		printDebug("manually select pylon failed");
	},

	trigger: func {
		# trigger pressed down should go here, this will fire weapon
		# cannon is fired in another way, but this method will print the brevity.
		if (me["sjSelect"] != nil) {
			me.jettisonSJContent();
			return;
		}
        setprop("payload/armament/releasedCCRP", 0);
		printfDebug("trigger called %d %d %d",getprop("controls/armament/master-arm"),getprop("controls/armament/trigger"),me.selected != nil);
		if (me.getSelectedPylon() == nil or !me.getSelectedPylon().isActive()) return;
		if (me.isRippling) return;
		if (getprop("controls/armament/master-arm") == 1 and getprop("controls/armament/trigger") > 0 and me.selected != nil) {
			printDebug("trigger propagating");
			me.aim = me.getSelectedWeapon();
			#printfDebug(" to %d",me.aim != nil);
			if (me.aim != nil and me.aim.parents[0] == armament.AIM and me.aim.status != armament.MISSILE_LOCK and me.aim.guidance!="unguided" and !me.aim.loal) {
				me.guidanceEnabled = 0;
			} else {
				me.guidanceEnabled = 1;
			}
			if (me.aim != nil and me.aim.parents[0] == armament.AIM and (me.aim.status == armament.MISSILE_LOCK or me.aim.guidance=="unguided" or me.aim.loal or !me.guidanceEnabled)) {
			    if (me.getDropMode() == DROP_CCRP and containsVector(CCIP_CCRP, me.aim.type) and me.aim.status == armament.MISSILE_LOCK) {
			    	# CCRP
			        me.distCCRP = getprop("payload/armament/distCCRP");
			        me.distCCRPLast = me.distCCRP;
			        if (me.distCCRP == -1 or me.distCCRPLast == -1 or me.distCCRP >= 500 or me.distCCRP < me.distCCRPLast) {
			            printDebug("CCRP: Trigger was pressed, waiting for launch parameters");
                        if (me["distCCRPListen"] == nil) me.distCCRPListen = setlistener("payload/armament/distCCRP", func (distCCRP) {
                            me.distCCRPLast = me.distCCRP;
                            
                            me.distCCRP = distCCRP.getValue();

                            if (me.distCCRP != -1 and me.distCCRPLast != -1 and me.distCCRP < 500 and me.distCCRP >= me.distCCRPLast) {
                                printDebug("CCRP: Launch parameters met, re-run the trigger function");
                                me.cancelCCRPListener();
                                me.trigger();                                
                                setprop("payload/armament/releasedCCRP", 1);
                            }
                        });
                        return;  # The listener will call this function again when we are ready
                    }
			    }
				me.aim = me.fireAIM(me.selected[0],me.selected[1], me.guidanceEnabled);
				if (me.selectedAdd != nil) {
					# Fire dual weapons
					foreach(me.seldual ; me.selectedAdd) {
						me.fireAIM(me.seldual[0],me.seldual[1], me.guidanceEnabled);
					}
				}
				me.nextWeapon(me.selectedType);
				
				# start ripple if set
				me.idx = me.vectorIndex(dualWeapons,me.selectedType);
				if (me.idx != -1) {
					# gravity assisted munition dropping.
					setprop("payload/armament/gravity-dropping", 1);
					if (me.ripple > 1) {
						me.isRippling = 1;
						me.rippleThis = 2;
						me.rippleFireStart();
					} else {
						# gravity assisted munition finished dropping.
						setprop("payload/armament/gravity-dropping", 0);
					}
				}
				
				me.triggerTime = 0;
			} elsif (me.aim != nil and me.aim.parents[0] == armament.AIM and me.aim.loal) {
				me.triggerTime = getprop("sim/time/elapsed-sec");
				settimer(func me.triggerHold(me.aim), 1.5);
			} elsif (me.aim != nil and me.aim.parents[0] == stations.SubModelWeapon and (me.aim.operableFunction == nil or me.aim.operableFunction()) and me.aim.getAmmo()>0) {
				if (getprop("sim/time/elapsed-sec")>me.gunTriggerTime+10 or me.aim.alternate) {
					# only say guns guns every 10 seconds.
					#armament.AIM.sendMessage(me.aim.brevity);
					
					me.gunTriggerTime = getprop("sim/time/elapsed-sec");
				}
				damage.damageLog.push(me.aim.type~" fired");
				if (me.rippleR > 1) {
					me.isRipplingRockets = 1;
					me.rippleRocketFireStart();
				}
				me.triggerTime = 0;
			}
		} elsif (getprop("controls/armament/trigger") < 1) {
			# trigger was released, we reset triggertimer and if alternating submodelweapon we stop it and switch to next and start that
			me.triggerTime = 0;
			me.aim = me.getSelectedWeapon();
			if (me.aim != nil and me.aim.parents[0] == stations.SubModelWeapon) {
				me.isRipplingRockets = 0;
				if (me.aim.alternate) {
					me.stopCurrent();
					me.nextWeapon(me.selectedType);
				}
			}
			me.cancelCCRPListener();
		} else {
			me.cancelCCRPListener();
		}
	},
	
	fireAIM: func (p,w,g) {
		# fire a weapon (that is a missile-code instance)
		printDebug("fireAIM called. pylon="~p~" weapon="~w~" guide="~g);
		me.aim = me._getSpecificWeapon(p,w);
		if (!g) me.aim.guidanceEnabled = 0;
		me.lockedfire = me.aim.status == armament.MISSILE_LOCK;
		me.aim = me.pylons[p].fireWeapon(w, getCompleteRadarTargetsList());
		if (me.aim != nil) {
			var add = "";
			if (me.lockedfire and me.aim.guidance != "unguided") {
				add = " at: "~me.aim.callsign;
			}
			#me.aim.sendMessage(me.aim.brevity~add);
			damage.damageLog.push(me.aim.brevity~add);
		}
		if (me.changeListener != nil) me.changeListener();
		return me.aim;
	},

	rippleRocketFireStart: func {
		# First has been fired, now start system to fire the ripple ones.
		if (me.getSelectedWeapon() != nil) {
			me.rippleTime  = getprop("sim/time/elapsed-sec");
			me.rippleThis  = 1;# One has already been released
			me.rippleCount = 0;
			setprop("payload/armament/rockets-rippling", 1);
			me.rippleRocketTest();
		}
	},

	rippleRocketTest: func {
		# test for if we should fire ripple rockets.
		me.rippleCount += 1;
		if (me.isRipplingRockets and getprop("sim/time/elapsed-sec") > me.rippleTime + 0.75) {
			me.rocket = me.getSelectedWeapon();
			if (me.rocket != nil and me.rocket.parents[0] == stations.SubModelWeapon) {
				if (me.aim.alternate) {
					me.stopCurrent();
					me.nextWeapon(me.selectedType);
				} else {
					me.rocket.stop();
					me.rocket.start();
				}
				me.rippleThis += 1;
				me.rippleTime  = getprop("sim/time/elapsed-sec");
				if (me.rippleThis >= me.rippleR or me.getSelectedWeapon() == nil) {
					me.isRipplingRockets = 0;
					printDebug("Finished ripple");
					setprop("payload/armament/rockets-rippling", 0);
					return;
				}
			} else {
				me.isRipplingRockets = 0;
				printDebug("Aborted ripple");
				setprop("payload/armament/rockets-rippling", 0);
				return;
			}
		}
		var delayTimer = 0.025;
		if (me.rippleCount > 30/delayTimer) {
			# after 30 seconds if its not finished rippling, cancel it. Might happen if the aircraft is still.
			me.isRipplingRockets = 0;
			printDebug("Cancelled ripple");
			setprop("payload/armament/rockets-rippling", 0);
			return;
		}
		settimer(func me.rippleRocketTest(), delayTimer);
	},
	
	rippleFireStart: func {
		# First has been fired, now start system to fire the ripple ones.
		if (me.getSelectedWeapon() != nil) {
			me.rippleCoord = geo.aircraft_position();
			me.rippleTime  = getprop("sim/time/elapsed-sec");
			me.rippleCount = 0;
			me.rippleTest();
		}
	},
	
	rippleTest: func {
		# test for distance if we should fire ripple bombs. And do so if distance is great enough.
		me.rippleCount += 1;
		if (me.rippleInterval == RIPPLE_INTERVAL_METERS and geo.aircraft_position().distance_to(me.rippleCoord) > me.rippleDist*(me.rippleThis-1) or
			me.rippleInterval == RIPPLE_INTERVAL_SECONDS and getprop("sim/time/elapsed-sec") > me.rippleTime + me.rippleDelay*(me.rippleThis-1)
			) {
			me.aim = me.getSelectedWeapon();
			if (me.aim != nil and me.aim.parents[0] == armament.AIM and (me.aim.status == armament.MISSILE_LOCK or me.aim.guidance=="unguided" or me.getDropMode() == DROP_CCIP)) {
				me.fireAIM(me.selected[0],me.selected[1],me.guidanceEnabled);
				if (me.selectedAdd != nil) {
					foreach(me.seldual ; me.selectedAdd) {
						me.fireAIM(me.seldual[0],me.seldual[1],me.guidanceEnabled);
					}
				}
				me.nextWeapon(me.selectedType);
				me.rippleThis += 1;
				if (me.rippleThis > me.ripple or me.getSelectedWeapon() == nil) {
					me.isRippling = 0;
					# gravity assisted munition finished dropping.
					setprop("payload/armament/gravity-dropping", 0);
					screen.log.write("Finished ripple", 0.5, 0.5, 1);
					return;
				}
			}
		}
		var delayTimer = me.rippleInterval == RIPPLE_INTERVAL_METERS?0.25:0.025;
		if (me.rippleCount > 7.5/delayTimer) {
			# after 7.5 seconds if its not finished rippling, cancel it. Might happen if the aircraft is still.
			me.isRippling = 0;
			setprop("payload/armament/gravity-dropping", 0);
			screen.log.write("Cancelled ripple", 0.5, 0.5, 1);
			return;
		}
		settimer(func me.rippleTest(), delayTimer);
	},

	triggerHold: func (aimer) {
		# will fire weapon even with no lock
		if (me.triggerTime == 0 or me.getSelectedWeapon() == nil or me.getSelectedWeapon().parents[0] != armament.AIM or me.triggerTime + 1.5 > getprop("sim/time/elapsed-sec")) {
			return;
		}
		aimer = me.pylons[me.selected[0]].fireWeapon(me.selected[1], getCompleteRadarTargetsList());
		if (aimer != nil) {
			#aimer.sendMessage(aimer.brevity~" Maddog released");
			damage.damageLog.push(aimer.brevity~" Maddog released");
			me.aimNext = me.nextWeapon(me.selectedType);
			if (me.aimNext != nil) {
				me.aimNext.start();
			}
			if (me.changeListener != nil) me.changeListener();
		}
		return;
	},

	masterArmSwitch: func () {
		if (getprop("controls/armament/master-arm-switch") == pylons.ARM_ARM) {
			setprop("controls/armament/master-arm", 1);
		} else {
			setprop("controls/armament/master-arm", 0);
			me.cancelCCRPListener();
		}
		me.updateCurrent();
	},

	cancelCCRPListener: func {
		if (me["distCCRPListen"] != nil) {
            printDebug("CCRP: Masterarm/Trigger is off or no weapon, cancel the listener");
            removelistener(me.distCCRPListen);
            me.distCCRPListen = nil;
        }
	},

	updateCurrent: func {
		# will start/stop current weapons depending on masterarm
		# will also update mass (for cannon mainly)
		if (getprop("controls/armament/master-arm-switch")!=pylons.ARM_OFF and me.selected != nil) {
			me.sweaps = me.getSelectedWeapons();
			if (me.sweaps != nil) {
				foreach(me.sweap ; me.sweaps) {
					me.sweap.start();
#					print("starting a weapon");
				}
			}
		} elsif (getprop("controls/armament/master-arm-switch")==pylons.ARM_OFF and me.selected != nil) {
			me.sweaps = me.getSelectedWeapons();
			if (me.sweaps != nil) {
				foreach(me.sweap ; me.sweaps) {
					me.sweap.stop();
				}
			}
		}
		if (me.selected == nil) {
			return;
		}
		printDebug("FC: Masterarm "~getprop("controls/armament/master-arm-switch"));
		
		me.pylons[me.selected[0]].calculateMass();#kind of a hack to get cannon ammo changed.
	},
	
	updateDual: func (type = nil) {
		# will stop all current weapons, and select single and pair weapons and start em all.
		# But only if CCRP trigger is not being held. Else the CCRP line will blink when trigger pulled,
		# as the weapons(s) will restart init sequence and lose lock.
		if (me["distCCRPListen"] != nil) return;
		me.duality = getprop("controls/armament/dual");
		me.sweaps = me.getSelectedWeapons();
		if (me.sweaps != nil) {
			foreach(me.sweap ; me.sweaps) {
				me.sweap.stop();
			}
		}
		me.selectedAdd = nil;
		if (me.selected != nil) {
			if (type == nil) type = me.selectedType;
			me.idx = me.vectorIndex(dualWeapons,type);
			if (me.idx != -1 and me.duality > 1) {
				me.selectDualWeapons(type, me.duality);
			}
			me.updateCurrent();
			if (me.changeListener != nil) me.changeListener();
			return;
		}
	},
	
	selectDualWeapons: func (type, duality) {
		# will select additional weapon of same type if dual is supported for the type and dual is greater than 'single'
		# will NOT start them
		me.selectedAdd = [];
		me.listofduals = [me.getSelectedWeapon()];
		if (me.selected == nil) {
			me.selectedAdd = nil;
			return;
		} else {
			me.pylon = me.selected[0];
		}
#		print("single: "~me.pylon);
		for (me.ij=2;me.ij<=duality;me.ij+=1) {
			printDebug("");
			printfDebug("Start find next dual weapon of type %s, starting from pylon %d", type, me.pylon);
			me.indexWeapon = -1;
			me.index = me.vectorIndex(me.pylonOrder, me.pylon);
			for(me.i=0;me.i<size(me.pylonOrder);me.i+=1) {
				#printDebug("me.i="~me.i);
				me.index += 1;
				if (me.index >= size(me.pylonOrder)) {
					me.index = 0;
				}
				me.pylon = me.pylonOrder[me.index];
				if (!me.pylons[me.pylon].isActive()) {
					continue;
				}
#				print("testing: "~me.pylon);
				printfDebug(" Testing pylon %d", me.pylon);
				# now we try to select a weapon but make sure it start looking for current index on pylon higher than already included:
				me.current = nil;
				if (me.pylon == me.selected[0]) {
					me.current = me.selected[1];
				}
				foreach(me.add ; me.selectedAdd) {
					if (me.add[0] = me.pylon) {
						me.current = me.add[1];
					}
				}
				me.indexWeapon = me._getNextWeapon(me.pylons[me.pylon], type, me.current);
				me.testweapon = me._getSpecificWeapon(me.pylon,me.indexWeapon);
				if (me.testweapon != nil and me.vectorIndex(me.listofduals,me.testweapon) == -1) {
					# we found a weapon and its not already included
					append(me.selectedAdd, [me.pylon, me.indexWeapon]);
					append(me.listofduals, me.testweapon);
					printDebug(" Another dual weapon found");
#					print("found: "~me.pylon);
					break;
				}
			}
		}
#		print("duals found "~size(me.selectedAdd));
	},

	nextWeapon: func (type) {
		# find next weapon of type. Will select and start it. Will not select weapons on inactive pylons.
		# will NOT stop previous weapon
		# will NOT set selectedType
		if (me.selected == nil) {
			me.pylon = me.pylonOrder[size(me.pylonOrder)-1];
		} else {
			me.pylon = me.selected[0];
		}
		printDebug("");
		printfDebug("Start find next weapon of type %s, starting from pylon %d", type, me.pylon);
		me.indexWeapon = -1;
		me.index = me.vectorIndex(me.pylonOrder, me.pylon);
		for(me.i=0;me.i<size(me.pylonOrder);me.i+=1) {
			#printDebug("me.i="~me.i);
			me.index += 1;
			if (me.index >= size(me.pylonOrder)) {
				me.index = 0;
			}
			me.pylon = me.pylonOrder[me.index];
			if (!me.pylons[me.pylon].isActive()) {
				continue;
			}
			printfDebug(" Testing pylon %d", me.pylon);
			me.indexWeapon = me._getNextWeapon(me.pylons[me.pylon], type, nil);
			if (me.indexWeapon != -1) {
				me.selected = [me.pylon, me.indexWeapon];
				printDebug(" Next weapon found");
				me.updateDual(type);
				#me.updateCurrent();#TODO: think a bit more about this
				me.wap = me.pylons[me.pylon].getWeapons()[me.indexWeapon];
				#me.selectedType = me.wap.type;
				if (me.changeListener != nil) me.changeListener();
				return me.wap;
			}
		}
		printDebug(" Next weapon not found");
		me.selected = nil;
		me.selectedAdd = nil;
		if (me.changeListener != nil) me.changeListener();
		return nil;
	},

	_getNextWeapon: func (pylon, type, current) {
		# get next weapon on a specific pylon.
		# will return the index of the weapon inside pylon.
		# returns -1 when not found
		if (pylon.currentSet != nil and pylon.currentSet["fireOrder"] != nil and size(pylon.currentSet.fireOrder) > 0) {
			printDebug("  getting next weapon");
			if (current == nil) {
				current = pylon.currentSet.fireOrder[size(pylon.currentSet.fireOrder)-1];
			}
			me.fireIndex = me.vectorIndex(pylon.currentSet.fireOrder, current);
			for(me.j=0;me.j<size(pylon.currentSet.fireOrder);me.j+=1) {
				#printDebug("me.j="~me.j);
				me.fireIndex += 1;
				if (me.fireIndex >= size(pylon.currentSet.fireOrder)) {
					me.fireIndex = 0;
				}
				if (pylon.getWeapons()[pylon.currentSet.fireOrder[me.fireIndex]] != nil) {
					if (pylon.getWeapons()[pylon.currentSet.fireOrder[me.fireIndex]].type == type and (pylon.getWeapons()[pylon.currentSet.fireOrder[me.fireIndex]].parents[0] != stations.SubModelWeapon or pylon.getWeapons()[pylon.currentSet.fireOrder[me.fireIndex]].getAmmo() > 0)) {
						return pylon.currentSet.fireOrder[me.fireIndex];
					}
				}
			}
		}
		#printfDebug("  %d %d %d",pylon.currentSet != nil,pylon.currentSet["fireOrder"] != nil,size(pylon.currentSet.fireOrder) > 0);
		return -1;
	},

	getAmmo: func {
		# return ammo count of currently selected type
		me.count = 0;
		foreach (var p;me.pylons) {
			me.count += p.getAmmo(me.selectedType);
		}
		return me.count;
	},

	getAmmoOfType: func (type) {
		# return ammo count of type
		me.count = 0;
		foreach (var p;me.pylons) {
			me.count += p.getAmmo(type);
		}
		return me.count;
	},
	
	getAllAmmo: func (type = nil) {
        # return ammo count of all pylons in a vector
        me.ammoVector = [];
        foreach (var p;me.pylons) {
            append(me.ammoVector, p.getAmmo(type));
        }
        return me.ammoVector;
    },
	
	getActiveAmmo: func {
		# return ammo count of currently selected type that are on active pylons
		me.count = 0;
		foreach (var p;me.pylons) {
			if (p.isActive()) {
				me.count += p.getAmmo(me.selectedType);
			}
		}
		return me.count;
	},

	vectorIndex: func (vec, item) {
		# returns index of item in vector, -1 if nothing.
		me.m = 0;
		foreach(test; vec) {
			if (test == item) {
				return me.m;
			}
			me.m += 1;
		}
		return -1;
	},

	stopCurrent: func {
		# stops current weapons, but does not deselect it.
		me.selWeap = me.getSelectedWeapons();
		if (me.selWeap == nil) {
			return;
		}
		foreach(me.sWeap ; me.selWeap) {
			if (me.sWeap != nil) {
				me.sWeap.stop();
			}
		}
	},

	noWeapon: func {
		# stops and deselects
		me.stopCurrent();
		me.selected = nil;
		me.selectedAdd = nil;
		me.selectedType = nil;
		printDebug("FC: nothing selected");
		if (me.changeListener != nil) me.changeListener();
	},

	setPoint: func (c) {
		# don't remember this, don't think its used anymore
		me.ag = me.getSelectedWeapon();
		if (me.ag != nil and me.ag["target_pnt"] == 1) {
			if (c == nil) {
				print("agm65 nil");
				me.ag.setContacts([]);
			} else {
				print("agm65 xfer");
				me.tgp_point = radar_system.ContactTGP.new("TGP-Spot",c);
				me.ag.setContacts([me.tgp_point]);
			}
		}
	},
	
	getAllOfType: func (typ) {
		# return vector with all weapons of certain type
		me.typVec = [];
		
		foreach(pyl;me.pylons) {
			foreach(me.pylweap ; pyl.getWeapons()) {
				if (me.pylweap != nil and me.pylweap.type == typ) {
					append(me.typVec, me.pylweap);
				}
			}
		}
		return me.typVec;
	},

	getStationIndecesForSelectedType: func (typeOnly = nil) {
		# return vector with all weapons of certain type
		if (typeOnly == nil) typeOnly = me.selectedType;
		me.same = typeOnly == me.selectedType;
		me.indices = [];
		for (var i = 0; i < size(me.pylons);i +=1) {
			me.pylo = me.pylons[i];
			me.value = -1;
			if (me.selected != nil and i == me.selected[0] and me.same) {
				me.value = 1;
			} elsif (typeOnly != nil and me.same) {
				foreach(me.pylweap ; me.pylo.getWeapons()) {
					if (me.pylweap != nil and me.pylweap.type == typeOnly) {
						me.value = 0;
						break;
					}
				}
			}
			append(me.indices, me.value);
		}
		
		return me.indices;
	},
};

var debugFC = 0;
var printDebug = func (msg) {if (debugFC) print(msg);};
var printfDebug = func {if (debugFC) {var str = call(sprintf,arg,nil,nil,var err = []);if(size(err))print(err[0]);else print (str);}};
# Note calling printf directly with call() will sometimes crash the sim, so we call sprintf instead.

var containsVector = func (vec, item) {
    foreach(test; vec) {
        if (test == item) {
            return 1;
        }
    }
    return 0;
}

var ccrpTrgt = nil;

getCCRPTarget = func {
	# HUD uses this
	return ccrpTrgt;
}

var ccrp_loop = func () {
    var selW = pylons.fcs.getSelectedWeapon();

    # Exit if master switch off, no selected weapon, ccip, not A/G bomb, or not locked on a target
    if (getprop(masterArmSwitch) == pylons.ARM_OFF or
        	selW == nil or pylons.fcs.getDropMode() != DROP_CCRP or
            !containsVector(CCIP_CCRP, selW.type) or selW.status != armament.MISSILE_LOCK) {
    	ccrpTrgt = nil;
        setprop("payload/armament/distCCRP", -1);
        return;
    }
    ccrpTrgt = armament.contactPoint;
    var prio = radar_system.apg68Radar.getPriorityTarget();
    if (ccrpTrgt == nil and prio != nil
    		and (prio.getType() == armament.SURFACE or prio.getType() == armament.MARINE)) {
        ccrpTrgt = prio;
    } elsif (ccrpTrgt == nil) {
        printDebug("CCRP: tgt not found");
        setprop("payload/armament/distCCRP", -1);
        return;
    }
    if (selW.guidance == "unguided") {
    	# TODO: Scour manual to see if unguided can be dropped with CCRP. Also remove lock requirement if they can.
        var dt = 0.1;
        var maxFallTime = 20;
    } else {
        var agl = (getprop("position/altitude-ft")-ccrpTrgt.get_altitude())*FT2M;
        var dt = agl*0.000025;#4000 ft = ~0.1
        if (dt < 0.1) dt = 0.1;
        var maxFallTime = 45;
    }
    var distCCRP = selW.getCCRP(maxFallTime,dt);
    if (distCCRP == nil) {
        distCCRP = -1;
    }
    setprop("payload/armament/distCCRP", distCCRP);
}
if (debugFC) screen.property_display.add("payload/armament/distCCRP");
if (debugFC) screen.property_display.add("payload/armament/gravity-dropping");

var ccrp_loopTimer = maketimer(0.1, ccrp_loop);
ccrp_loopTimer.simulatedTime = 1;
ccrp_loopTimer.start();


# This is non-generic methods, please edit it to fit your radar/weapon setup:

# List of weapons that can be CCIP/CCRP dropped:
var CCIP_CCRP = ["MK-82","MK-82AIR","MK-83","MK-84","GBU-12","GBU-24","GBU-54","CBU-87","CBU-105","GBU-31","B61-7","B61-12"];
# List of weapons that can be ripple/dual dropped:
var dualWeapons = ["MK-82","MK-82AIR","MK-83","MK-84","GBU-12","GBU-24","GBU-54","CBU-87","CBU-105","GBU-31","B61-7","B61-12","AGM-154A"];
var defaultCannon = "20mm Cannon";
var defaultRocket = "LAU-68";
var getCompleteRadarTargetsList = func {
	# A list of all MP/AI aircraft/ships/surface-targets around the aircraft, including those that is outside radar line of sight etc..
	return radar_system.getCompleteList();
}
var masterArmSwitch = "controls/armament/master-arm-switch";