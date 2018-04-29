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
		fc.selected = nil;
		fc.pylonOrder=pylonOrder;
		fc.typeOrder=typeOrder;
		fc.selectedType = nil;
		fc.WeaponNotification = VectorNotification.new("WeaponNotification");
		fc.setupMFDObservers();
		setlistener("controls/armament/trigger",func{fc.trigger();fc.updateCurrent()});
		setlistener("controls/armament/master-arm",func{fc.updateCurrent()});
		return fc;
	},

	setupMFDObservers: func {
		me.FireControlRecipient = emesary.Recipient.new("FireControlRecipient");
		me.FireControlRecipient.Receive = func(notification) {
	        if (notification.NotificationType == "WeaponRequestNotification") {
	        	#printf("FireControlRecipient recv: %s", notification.NotificationType);
	        	if (me.selected != nil) {
					me.WeaponNotification.updateV(me.pylons[me.selected[0]].getWeapons()[me.selected[1]]);
					emesary.GlobalTransmitter.NotifyAll(me.WeaponNotification);
				}
	            return emesary.Transmitter.ReceiptStatus_OK;
	        } elsif (notification.NotificationType == "WeaponCommandNotification") {
	        	#printf("FireControlRecipient recv: %s", notification.NotificationType);
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
	        	#printf("FireControlRecipient recv: %s", notification.NotificationType);
	        	me.cycleWeapon();
	            return emesary.Transmitter.ReceiptStatus_OK;
	        }
	        return emesary.Transmitter.ReceiptStatus_NotProcessed;
	    };
		emesary.GlobalTransmitter.Register(me.FireControlRecipient);
	},

	cycleWeapon: func {
		# it will cycle to next weapon type, even if that one is empty. (maybe add option if it should skip empty types)
		me.stopCurrent();
		me.selWeapType = me.selectedType;
		if (me.selWeapType == nil) {
			me.selectedType = me.typeOrder[0];
			if (me.nextWeapon(me.typeOrder[0]) != nil) {			
				printf("FC: Selected first weapon: %s on pylon %d position %d",me.selectedType,me.selected[0],me.selected[1]);
			} else {
				printf("FC: Selected first weapon: %s, but none is loaded.", me.selectedType);
			}
		} else {
			me.selType = me.selectedType;
			printf("Already selected %s",me.selType);
			me.selTypeIndex = me.vectorIndex(me.typeOrder, me.selType);
			me.selTypeIndex += 1;
			if (me.selTypeIndex >= size(me.typeOrder)) {
				me.selTypeIndex = 0;
			}
			me.selectedType = me.typeOrder[me.selTypeIndex];
			me.selType = me.selectedType;
			printf(" Now selecting %s",me.selType);
			me.wp = me.nextWeapon(me.selType);
			if (me.wp != nil) {			
				printf("FC: Selected next weapon type: %s on pylon %d position %d",me.selectedType,me.selected[0],me.selected[1]);
			} else {
				printf("FC: Selected next weapon type: %s, but none is loaded.", me.selectedType);
			}
		}
		screen.log.write("Selected "~me.selectedType, 0.5, 0.5, 1);
	},

	getSelectedWeapon: func {
		if (me.selected == nil) {
			return nil;
		}
		return me.pylons[me.selected[0]].getWeapons()[me.selected[1]];
	},

	getSelectedPylon: func {
		if (me.selected == nil) {
			return nil;
		}
		return me.pylons[me.selected[0]];
	},

	getSelectedPylonNumber: func {
		if (me.selected == nil) {
			return nil;
		}
		return me.selected[0];
	},

	selectPylon: func (p, w=nil) {
		if (size(me.pylons) > p) {
			me.ws = me.pylons[p].getWeapons();
			if (me.ws != nil and w != nil and size(me.ws) > w and me.ws[w] != nil) {
				me.stopCurrent();
				me.selected = [p, w];
				me.updateCurrent();
				return;
			} elsif (me.ws != nil and w == nil and size(me.ws) > 0) {
				w = 0;
				foreach(me.wp;me.ws) {
					if (me.wp != nil) {
						me.stopCurrent();
						me.selected = [p, w];
						me.updateCurrent();
						return;
					}
					w+=1;
				}
			}
		}
		print("manually select pylon failed");
	},

	trigger: func {
		printf("trigger called %d %d %d",getprop("controls/armament/master-arm"),getprop("controls/armament/trigger"),me.selected != nil);
		if (getprop("controls/armament/master-arm") == 1 and getprop("controls/armament/trigger") > 0 and me.selected != nil) {
			print("trigger propagating");
			me.aim = me.getSelectedWeapon();
			#printf(" to %d",me.aim != nil);
			if (me.aim != nil and me.aim.parents[0] == armament.AIM and me.aim.status == armament.MISSILE_LOCK) {
				me.aim = me.pylons[me.selected[0]].fireWeapon(me.selected[1]);
				me.aim.sendMessage(me.aim.brevity~" at: "~me.aim.callsign);
				me.aimNext = me.nextWeapon(me.selectedType);
				if (me.aimNext != nil) {
					me.aimNext.start();
				}
				return;
			} elsif (me.aim != nil and me.aim.parents[0] == stations.SubModelWeapon) {
				armament.AIM.sendMessage("Guns guns");
			}
		}
	},

	updateCurrent: func {
		if (getprop("controls/armament/master-arm")==1 and me.selected != nil) {
			me.getSelectedWeapon().start();
		} elsif (getprop("controls/armament/master-arm")==0 and me.selected != nil) {
			me.getSelectedWeapon().stop();
		}
		print("FC: Masterarm "~getprop("controls/armament/master-arm"));
		if (me.selected == nil) {
			return;
		}
		me.pylons[me.selected[0]].calculateMass();#kind of a hack to get cannon ammo changed.
	},

	nextWeapon: func (type) {
		if (me.selected == nil) {
			me.pylon = me.pylonOrder[size(me.pylonOrder)-1];
		} else {
			me.pylon = me.selected[0];
		}
		print();
		printf("Start find next weapon of type %s, starting from pylon %d", type, me.pylon);
		me.indexWeapon = -1;
		me.index = me.vectorIndex(me.pylonOrder, me.pylon);
		for(me.i=0;me.i<size(me.pylonOrder);me.i+=1) {
			#print("me.i="~me.i);
			me.index += 1;
			if (me.index >= size(me.pylonOrder)) {
				me.index = 0;
			}
			me.pylon = me.pylonOrder[me.index];
			printf(" Testing pylon %d", me.pylon);
			me.indexWeapon = me._getNextWeapon(me.pylons[me.pylon], type, nil);
			if (me.indexWeapon != -1) {
				me.selected = [me.pylon, me.indexWeapon];
				print(" Next weapon found");
				me.updateCurrent();#TODO: think a bit more about this
				return me.pylons[me.pylon].getWeapons()[me.indexWeapon];
			}
		}
		print(" Next weapon not found");
		me.selected = nil;
		return nil;
	},

	_getNextWeapon: func (pylon, type, current) {
		# get next weapon on a specific pylon.
		if (pylon.currentSet != nil and pylon.currentSet["fireOrder"] != nil and size(pylon.currentSet.fireOrder) > 0) {
			print("  getting next weapon");
			if (current == nil) {
				current = pylon.currentSet.fireOrder[size(pylon.currentSet.fireOrder)-1];
			}
			me.fireIndex = me.vectorIndex(pylon.currentSet.fireOrder, current);
			for(me.j=0;me.j<size(pylon.currentSet.fireOrder);me.j+=1) {
				#print("me.j="~me.j);
				me.fireIndex += 1;
				if (me.fireIndex >= size(pylon.currentSet.fireOrder)) {
					me.fireIndex = 0;
				}
				if (pylon.getWeapons()[pylon.currentSet.fireOrder[me.fireIndex]] != nil) {
					if (pylon.getWeapons()[pylon.currentSet.fireOrder[me.fireIndex]].type == type) {
						return pylon.currentSet.fireOrder[me.fireIndex];
					}
				}
			}
		}
		#printf("  %d %d %d",pylon.currentSet != nil,pylon.currentSet["fireOrder"] != nil,size(pylon.currentSet.fireOrder) > 0);
		return -1;
	},

	getAmmo: func {
		me.count = 0;
		foreach (p;me.pylons) {
			me.count += p.getAmmo(me.selectedType);
		}
		return me.count;
	},

	vectorIndex: func (vec, item) {
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
		me.selWeap = me.getSelectedWeapon();
		if (me.selWeap != nil) {
			me.selWeap.stop();
		}
	},

	noWeapon: func {
		me.stopCurrent();
		me.selected = nil;
		me.selectedType = nil;
		print("FC: nothing selected");
	},
};

