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
		fc.rippleDist = 150*FT2M; # ripple setting, in meters.
		fc.isRippling = 0;        # is in ripple progress
		fc.WeaponNotification = VectorNotification.new("WeaponNotification");
		fc.setupMFDObservers();
		fc.dropMode = 0;          # 0=ccrp, 1 = ccip
		setlistener("controls/armament/trigger",func{fc.trigger();fc.updateDual()},nil,0);
		setlistener("controls/armament/master-arm",func{fc.updateCurrent()},nil,0);
		setlistener("controls/armament/dual",func{fc.updateDual()},nil,0);
		return fc;
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
	
	getRippleDist: func {
		me.rippleDist;
	},
	
	setRippleDist: func (rippleDist) {
		if (rippleDist >= 0) {
			me.rippleDist = rippleDist;
		}
	},
	
	getSelectedType: func {
		return me.selectedType;
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
				if (me.class != nil) {
					me.isAG = find("G", me.class)!=-1 or find("M", me.class)!=-1;
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
				if (me.class != nil) {
					me.isAG = find("G", me.class)!=-1 or find("M", me.class)!=-1;
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
						if (me.selType != nil and me.selType.parents[0] == armament.AIM and (me.selType.target_gnd == 1 or me.selType.target_sea==1)) {
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
					if (me.class != nil) {
						me.isAG = find("G", me.class)!=-1 or find("M", me.class)!=-1;
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
			screen.log.write("Deselected "~me.selectedType, 0.5, 0.5, 1);
		} else {
			screen.log.write("Selected nothing", 0.5, 0.5, 1);
		}
		me.selectedType = nil;
		me.selected = nil;
		me.selectedAdd = nil;
		me.updateDual();
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
			screen.log.write("Deselected "~me.selectedType, 0.5, 0.5, 1);
		} else {
			screen.log.write("Selected nothing", 0.5, 0.5, 1);
		}
		me.selectedType = nil;
		me.selected = nil;
		me.selectedAdd = nil;
	},

	updateAll: func {
		# called from the stations when they change.
		if (me.selectedType != nil) {
			screen.log.write("Fire-control: deselecting "~me.selectedType, 0.5, 0.5, 1);
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
		me.stopCurrent();
		me.pylons[me.selected[0]].jettisonAll();
		me.selected = nil;
		me.selectedAdd = nil;
		if (me.selectedType != nil) {
			me.nextWeapon(me.selectedType);
		}
	},

	jettisonAll: func {
		# jettison all stations
		foreach (pyl;me.pylons) {
			pyl.jettisonAll();
		}
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
			pyl.jettisonAll();
		}
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
				pyl.jettisonAll();
			}			
		}
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
		return me.nextWeapon(w);
	},
	
	selectNothing: func {
		me.stopCurrent();
		me.selectedType = nil;
		me.selected = nil;
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
				return;
			} elsif (me.ws != nil and w == nil and size(me.ws) > 0) {
				w = 0;
				foreach(me.wp;me.ws) {
					if (me.wp != nil) {
						me.stopCurrent();
						me.selected = [p, w];
						me.selectedType = me.ws[w].type;
						me.updateDual();
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
		printfDebug("trigger called %d %d %d",getprop("controls/armament/master-arm"),getprop("controls/armament/trigger"),me.selected != nil);
		if (me.getSelectedPylon() == nil or !me.getSelectedPylon().isActive()) return;
		if (me.isRippling) return;
		if (getprop("controls/armament/master-arm") == 1 and getprop("controls/armament/trigger") > 0 and me.selected != nil) {
			printDebug("trigger propagating");
			me.aim = me.getSelectedWeapon();
			#printfDebug(" to %d",me.aim != nil);
			if (me.aim != nil and me.aim.parents[0] == armament.AIM and (me.aim.status == armament.MISSILE_LOCK or me.aim.guidance=="unguided")) {
				me.aim = me.fireAIM(me.selected[0],me.selected[1]);
				if (me.selectedAdd != nil) {
					foreach(me.seldual ; me.selectedAdd) {
						me.fireAIM(me.seldual[0],me.seldual[1]);
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
					armament.AIM.sendMessage(me.aim.brevity);
					me.gunTriggerTime = getprop("sim/time/elapsed-sec");
				}
				me.triggerTime = 0;
			}
		} elsif (getprop("controls/armament/trigger") < 1) {
			# trigger was released, we reset triggertimer and if alternating submodelweapon we stop it and switch to next and start that
			me.triggerTime = 0;
			me.aim = me.getSelectedWeapon();
			if (me.aim != nil and me.aim.parents[0] == stations.SubModelWeapon) {
				if (me.aim.alternate) {
					me.stopCurrent();
					me.nextWeapon(me.selectedType);
				}
			}
		}
	},
	
	fireAIM: func (p,w) {
		# fire a weapon (that is a missile-code instance)
		me.aim = me._getSpecificWeapon(p,w);
		me.lockedfire = me.aim.status == armament.MISSILE_LOCK;
		me.aim = me.pylons[p].fireWeapon(w, getCompleteRadarTargetsList());
		if (me.aim != nil) {
			var add = "";
			if (me.lockedfire and me.aim.guidance != "unguided") {
				add = " at: "~me.aim.callsign;
			}
			me.aim.sendMessage(me.aim.brevity~add);
		}
		return me.aim;
	},
	
	rippleFireStart: func {
		# First has been fired, now start system to fire the ripple ones.
		if (me.getSelectedWeapon() != nil) {
			me.rippleCoord = geo.aircraft_position();
			me.rippleCount = 0;
			me.rippleTest();
		}
	},
	
	rippleTest: func {
		# test for distance if we should fire ripple bombs. And do so if distance is great enough.
		me.rippleCount += 1;
		if (geo.aircraft_position().distance_to(me.rippleCoord) > me.rippleDist*(me.rippleThis-1)) {
			me.aim = me.getSelectedWeapon();
			if (me.aim != nil and me.aim.parents[0] == armament.AIM and (me.aim.status == armament.MISSILE_LOCK or me.aim.guidance=="unguided")) {
				me.fireAIM(me.selected[0],me.selected[1]);
				if (me.selectedAdd != nil) {
					foreach(me.seldual ; me.selectedAdd) {
						me.fireAIM(me.seldual[0],me.seldual[1]);
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
		if (me.rippleCount > 30) {
			# after 7.5 seconds if its not finished rippling, cancel it. Might happen if the aircraft is still.
			me.isRippling = 0;
			setprop("payload/armament/gravity-dropping", 0);
			screen.log.write("Cancelled ripple", 0.5, 0.5, 1);
			return;
		}
		settimer(func me.rippleTest(), 0.25);
	},

	triggerHold: func (aimer) {
		# will fire weapon even with no lock
		if (me.triggerTime == 0 or me.getSelectedWeapon() == nil or me.getSelectedWeapon().parents[0] != armament.AIM or me.triggerTime + 1.5 > getprop("sim/time/elapsed-sec")) {
			return;
		}
		aimer = me.pylons[me.selected[0]].fireWeapon(me.selected[1], getCompleteRadarTargetsList());
		if (aimer != nil) {
			aimer.sendMessage(aimer.brevity~" Maddog released");
			me.aimNext = me.nextWeapon(me.selectedType);
			if (me.aimNext != nil) {
				me.aimNext.start();
			}
		}
		return;
	},

	updateCurrent: func {
		# will start/stop current weapons depending on masterarm
		# will also update mass (for cannon mainly)
		if (getprop("controls/armament/master-arm")==1 and me.selected != nil) {
			me.sweaps = me.getSelectedWeapons();
			if (me.sweaps != nil) {
				foreach(me.sweap ; me.sweaps) {
					me.sweap.start();
#					print("starting a weapon");
				}
			}
		} elsif (getprop("controls/armament/master-arm")==0 and me.selected != nil) {
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
		printDebug("FC: Masterarm "~getprop("controls/armament/master-arm"));
		
		me.pylons[me.selected[0]].calculateMass();#kind of a hack to get cannon ammo changed.
	},
	
	updateDual: func (type = nil) {
		# will stop all current weapons, and select single and pair weapons and start em all.
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
				return me.wap;
			}
		}
		printDebug(" Next weapon not found");
		me.selected = nil;
		me.selectedAdd = nil;
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
		foreach (p;me.pylons) {
			me.count += p.getAmmo(me.selectedType);
		}
		return me.count;
	},
	
	getAllAmmo: func (type = nil) {
        # return ammo count of all pylons in a vector
        me.ammoVector = [];
        foreach (p;me.pylons) {
            append(me.ammoVector, p.getAmmo(type));
        }
        return me.ammoVector;
    },
	
	getActiveAmmo: func {
		# return ammo count of currently selected type that are on active pylons
		me.count = 0;
		foreach (p;me.pylons) {
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
				me.tgp_point = ContactTGP.new("TGP-Spot",c);
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
};

var debug = 0;
var printDebug = func (msg) {if (debug == 1) print(msg);};
var printfDebug = func {if (debug == 1) call(printf,arg);};


# This is non-generic methods, please edit it to fit your radar setup:
var dualWeapons = ["MK-82","MK-83","MK-84","GBU-12","GBU-24","GBU-54","CBU-87","CBU-105","GBU-31","AGM-154A","B61-7","B61-12"];
var getCompleteRadarTargetsList = func {
	# A list of all MP/AI aircraft/ships/surface-targets around the aircraft.
	return awg_9.completeList;
}

var ContactTGP = {
  new: func(callsign, coord, laser = 1) {
    var obj             = { parents : [ContactTGP]};# in real OO class this should inherit from Contact, but in nasal it does not need to
    obj.coord           = geo.Coord.new(coord);
    obj.coord.set_alt(coord.alt()+1);#avoid z fighting
    obj.callsign        = callsign;
    obj.unique          = rand();
    
    obj.tacobj = {parents: [tacview.tacobj]};
    obj.tacobj.tacviewID = right((obj.unique~""),5);
    obj.tacobj.valid = 1;
    
    obj.laser = laser;
    return obj;
  },

  isValid: func () {
    return 1;
  },

  isVirtual: func () {
    return 1;
  },

  isPainted: func () {
    return 0;
  },

  isLaserPainted: func{
    return getprop("controls/armament/laser-arm-dmd") and me.laser;
  },

  isRadiating: func (c) {
  	return 0;
  },

  getUnique: func () {
    return me.unique;
  },

  getElevation: func() {
      #var e = 0;
      var self = geo.aircraft_position();
      #var angleInv = ja37.clamp(self.distance_to(me.coord)/self.direct_distance_to(me.coord), -1, 1);
      #e = (self.alt()>me.coord.alt()?-1:1)*math.acos(angleInv)*R2D;
      return vector.Math.getPitch(self, me.coord);
  },

  getFlareNode: func () {
    return nil;
  },

  getChaffNode: func () {
    return nil;
  },

  get_Coord: func(inaccurate = 1){
      return me.coord;
  },

  getETA: func {
      return nil;
    },

	getHitChance: func {
	  return nil;
	},

  get_Callsign: func(){
      return me.callsign;
  },

  get_model: func(){
      return "TGP spot";
  },

  get_Speed: func(){
      # return true airspeed
      return 0;
  },
  
  get_uBody: func {
      return 0;
	},    
	get_vBody: func {
	  return 0;
	},    
	get_wBody: func {
	  return 0;
	},

  get_Longitude: func(){
      var n = me.coord.lon();
      return n;
  },

  get_Latitude: func(){
      var n = me.coord.lat();
      return n;
  },

  get_Pitch: func(){
      return 0;
  },

  get_Roll: func(){
      return 0;
  },

  get_heading : func(){
      return 0;
  },

  get_bearing: func(){
      var n = me.get_bearing_from_Coord(geo.aircraft_position());
      return n;
  },
  
  get_relative_bearing : func() {
        return geo.normdeg180(me.get_bearing()-getprop("orientation/heading-deg"));
	},

  get_altitude: func(){
      #Return Alt in feet
      return me.coord.alt()*M2FT;
  },
  
  get_Longitude: func {
        return me.coord.lon()*M2FT;
	},
	get_Latitude: func {
	    return me.coord.lat();
	},

  get_range: func() {
      var r = me.coord.direct_distance_to(geo.aircraft_position()) * M2NM;
      return r;
  },

  get_type: func () {
    return armament.POINT;
  },

  get_bearing_from_Coord: func(MyAircraftCoord){
      var myBearing = 0;
      if(me.coord.is_defined()) {
          myBearing = MyAircraftCoord.course_to(me.coord);
      }
      return myBearing;
  },
};