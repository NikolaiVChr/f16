var cannon = stations.SubModelWeapon.new("20mm Cannon", 0.5, 500, 2, [1,3], props.globals.getNode("fdm/jsbsim/fcs/guntrigger",1), 0, func{return getprop("fdm/jsbsim/systems/hydraulics/sysb-psi")>=2000;});
var fuelTankCenter = stations.FuelTank.new("Center 300 Gal Tank", 4, 300);
var fuelTank370Left = stations.FuelTank.new("Left 370 Gal Tank", 3, 370);
var fuelTank370Right = stations.FuelTank.new("Right 370 Gal Tank", 2, 370);
var fuelTank600Left = stations.FuelTank.new("Left 600 Gal Tank", 3, 600);
var fuelTank600Right = stations.FuelTank.new("Right 600 Gal Tank", 2, 600);
var pylonSets = {
	empty: {name: "Empty", content: [], fireOrder: [], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0},
	e: {name: "20mm Cannon", content: [cannon], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1},
	f: {name: "300 Gal Fuel tank", content: [fuelTankCenter], fireOrder: [0], launcherDragArea: 0.18, launcherMass: 392, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1},
	g: {name: "1 x AIM-9", content: ["AIM-9"], fireOrder: [0], launcherDragArea: -0.0785, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0},
	h: {name: "1 x AIM-120", content: ["AIM-120"], fireOrder: [0], launcherDragArea: -0.025, launcherMass: 10, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0},
	i: {name: "3 x GBU-12", content: ["GBU-12","GBU-12", "GBU-12"], fireOrder: [0,1,2], launcherDragArea: -0.025, launcherMass: 10, launcherJettisonable: 1, showLongTypeInsteadOfCount: 0},
	j: {name: "2 x GBU-12", content: ["GBU-12", "GBU-12"], fireOrder: [0,1], launcherDragArea: -0.025, launcherMass: 10, launcherJettisonable: 1, showLongTypeInsteadOfCount: 0},
	k: {name: "1 x AN-T-17", content: [], fireOrder: [], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0},
	l: {name: "370 Gal Fuel tank", content: [fuelTank370Left], fireOrder: [0], launcherDragArea: 0.35, launcherMass: 531, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1},
	m: {name: "370 Gal Fuel tank", content: [fuelTank370Right], fireOrder: [0], launcherDragArea: 0.35, launcherMass: 531, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1},
	o: {name: "600 Gal Fuel tank", content: [fuelTank600Left], fireOrder: [0], launcherDragArea: 0.30, launcherMass: 399, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1},
	p: {name: "600 Gal Fuel tank", content: [fuelTank600Right], fireOrder: [0], launcherDragArea: 0.30, launcherMass: 399, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1},
};

# source for fuel tanks content, fuel type, jettisonable and drag: schema of F16 loadouts, not sure where it comes from.

# sets
var pylon120set   = [pylonSets.empty, pylonSets.g, pylonSets.h];
var wingtipSet = [pylonSets.k, pylonSets.g];# wingtips are normally not empty, so AN-T-17 dummy aim9 is loaded instead.
var pylon9mix = [pylonSets.empty, pylonSets.g,pylonSets.i];
var pylon12setL = [pylonSets.empty, pylonSets.j,pylonSets.l,pylonSets.o];
var pylon12setR = [pylonSets.empty, pylonSets.j,pylonSets.m,pylonSets.p];

# pylons
var pylon1 = stations.Pylon.new("Left Wingtip Pylon", 0, [0,0,0], wingtipSet, 0, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[1]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[1]",1));
var pylon2 = stations.Pylon.new("Left Outer Wing Pylon", 1, [0,0,0], pylon120set, 1, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[2]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[2]",1));
var pylon3 = stations.Pylon.new("Left Wing Pylon", 2, [0,0,0], pylon9mix, 2, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[3]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[3]",1));
var pylon4 = stations.Pylon.new("Left Inner Wing Pylon", 3, [0,0,0], pylon12setL, 3, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[4]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[4]",1));
var pylon5 = stations.Pylon.new("Center Pylon", 4, [0,0,0], [pylonSets.empty, pylonSets.f], 4, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[5]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[5]",1));
var pylon6 = stations.Pylon.new("Right Inner Wing Pylon", 5, [0,0,0], pylon12setR, 5, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[6]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[6]",1));
var pylon7 = stations.Pylon.new("Right Wing Pylon", 6, [0,0,0], pylon9mix, 6, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[7]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[7]",1));
var pylon8 = stations.Pylon.new("Right Outer Wing Pylon", 7, [0,0,0], pylon120set, 7, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[8]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[8]",1));
var pylon9 = stations.Pylon.new("Right Wingtip Pylon", 8, [0,0,0], wingtipSet, 8, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[9]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[9]",1));
var pylonI = stations.InternalStation.new("Internal gun mount", 9, [pylonSets.e], props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[10]",1));

# a hacky fire-control system:
var thepylons = [pylon1,pylon9,pylon2,pylon8,pylon3,pylon7,pylon4,pylon6];
var starter = func {
	var started = 0;
	foreach(p;thepylons) {
		var w =p.getWeapons();
		if (size (w)>0 and w[0]!=nil) {
			if (started == 0) {
				w[0].start();
				started = 1;
			} else {
				w[0].stop();
			}
		}
	}
	settimer(func {starter();}, 1);
};
#setlistener("controls/armament/trigger",func{
#	if (getprop("controls/armament/trigger") == 1) {
#		foreach(p;thepylons) {
#			var aim = p.fireWeapon(0);
#			if (aim == nil) {
#				aim = p.fireWeapon(1);
#				if (aim == nil) {
#					aim = p.fireWeapon(2);
#				}
#			}
#			if (aim != nil) {
#				aim.sendMessage(aim.brevity);# non-oprf message
#				return;
#			}
#		}
#	}
#});
#starter();
print("** Pylon system started. **");

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
		setlistener("controls/armament/trigger",func{fc.trigger()});
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
		screen.log.write("Selected "~me.selectedType, 0.5, 0.5, 0.5);
	},

	getSelectedWeapon: func {
		if (me.selected == nil) {
			return nil;
		}
		return me.pylons[me.selected[0]].getWeapons()[me.selected[1]];
	},

	trigger: func {
		printf("trigger called %d %d %d",getprop("controls/armament/master-arm"),getprop("controls/armament/trigger"),me.selected != nil);
		if (getprop("controls/armament/master-arm") == 1 and getprop("controls/armament/trigger") > 0 and me.selected != nil) {
			print("trigger propagating");
			me.aim = me.getSelectedWeapon();
			#printf(" to %d",me.aim != nil);
			if (me.aim != nil and me.aim.parents[0] == armament.AIM) {
				me.aim = me.pylons[me.selected[0]].fireWeapon(me.selected[1]);
				me.aim.sendMessage(me.aim.brevity);# non-oprf message for now
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
	},

	nextWeapon: func (type) {
		if (me.selected == nil) {
			me.pylon = me.pylonOrder[size(me.pylonOrder)-1];
		} else {
			me.pylon = me.selected[0];
		}
		print();
		printf("Start find next wepon of type %s, starting from pylon %d", type, me.pylon);
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
var pylons = [pylon1,pylon2,pylon3,pylon4,pylon5,pylon6,pylon7,pylon8,pylon9,pylonI];
var fcs = FireControl.new(pylons, [9,0,8,1,7,2,6,3,5,4], ["20mm Cannon","AIM-9","AIM-120","GBU-12"]);