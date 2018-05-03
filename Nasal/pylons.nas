var TRUE=1;
var FALSE=0;

var fcs = nil;
var pylon1 = nil;
var pylon2 = nil;
var pylon3 = nil;
var pylon4 = nil;
var pylon5 = nil;
var pylon6 = nil;
var pylon7 = nil;
var pylon8 = nil;
var pylon9 = nil;
var pylonI = nil;

var cannon = stations.SubModelWeapon.new("20mm Cannon", 0.254, 511, 2, [1,3], props.globals.getNode("fdm/jsbsim/fcs/guntrigger",1), 0, func{return getprop("fdm/jsbsim/systems/hydraulics/sysb-psi")>=2000 and getprop("payload/armament/fire-control/serviceable");});
var fuelTankCenter = stations.FuelTank.new("Center 300 Gal Tank", "300Gal", 4, 300, "sim/model/f16/ventraltank");
var fuelTank370Left = stations.FuelTank.new("Left 370 Gal Tank", "370Gal", 3, 370, "sim/model/f16/wingtankL");
var fuelTank370Right = stations.FuelTank.new("Right 370 Gal Tank", "300Gal", 2, 370, "sim/model/f16/wingtankR");
var fuelTank600Left = stations.FuelTank.new("Left 600 Gal Tank", "600Gal", 3, 600, "sim/model/f16/wingtankL");
var fuelTank600Right = stations.FuelTank.new("Right 600 Gal Tank", "600Gal", 2, 600, "sim/model/f16/wingtankR");
var smokewinderRed1 = stations.Smoker.new("Smokewinder Red", "Smoke R", "sim/model/f16/smokewinderR1");
var smokewinderGreen1 = stations.Smoker.new("Smokewinder Green", "Smoke G", "sim/model/f16/smokewinderG1");
var smokewinderBlue1 = stations.Smoker.new("Smokewinder Blue", "Smoke B", "sim/model/f16/smokewinderB1");
var smokewinderRed9 = stations.Smoker.new("Smokewinder Red", "Smoke R", "sim/model/f16/smokewinderR9");
var smokewinderGreen9 = stations.Smoker.new("Smokewinder Green", "Smoke G", "sim/model/f16/smokewinderG9");
var smokewinderBlue9 = stations.Smoker.new("Smokewinder Blue", "Smoke B", "sim/model/f16/smokewinderB9");
var smokewinderWhite1 = stations.Smoker.new("Smokewinder White", "Smoke W", "sim/model/f16/smokewinderW1");
var smokewinderWhite9 = stations.Smoker.new("Smokewinder White", "Smoke W", "sim/model/f16/smokewinderW9");
var dummy = stations.Dummy.new("AN-T-17", nil);
var dummy2 = stations.Dummy.new("CATM-9L", nil);
var dummy3 = stations.Dummy.new("AN/ALQ-131 ECM Pod", "ALQ-131");
var pylonSets = {
	empty: {name: "Empty", content: [], fireOrder: [], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},
	a: {name: "1 x AGM-65", content: ["AGM-65"], fireOrder: [0], launcherDragArea: 0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
	b: {name: "1 x AGM-84", content: ["AGM-84"], fireOrder: [0], launcherDragArea: 0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
	e: {name: "20mm Cannon", content: [cannon], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	f: {name: "300 Gal Fuel tank", content: [fuelTankCenter], fireOrder: [0], launcherDragArea: 0.18, launcherMass: 392, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1, category: 1},
	f2: {name: "AN/ALQ-131 ECM Pod", content: [dummy3], fireOrder: [0], launcherDragArea: 0.18, launcherMass: 100, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1, category: 1},
	g: {name: "1 x AIM-9", content: ["AIM-9"], fireOrder: [0], launcherDragArea: -0.0785, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},#wingtip
	h: {name: "1 x AIM-120", content: ["AIM-120"], fireOrder: [0], launcherDragArea: -0.025, launcherMass: 10, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},#non wingtip
	i: {name: "3 x GBU-12", content: ["GBU-12","GBU-12", "GBU-12"], fireOrder: [0,1,2], launcherDragArea: -0.025, launcherMass: 10, launcherJettisonable: 1, showLongTypeInsteadOfCount: 0, category: 2},
	j: {name: "2 x GBU-12", content: ["GBU-12", "GBU-12"], fireOrder: [0,1], launcherDragArea: -0.025, launcherMass: 10, launcherJettisonable: 1, showLongTypeInsteadOfCount: 0, category: 2},
	k: {name: "1 x AN-T-17", content: [dummy], fireOrder: [], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	k2: {name: "1 x CATM-9L", content: [dummy2], fireOrder: [], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	l: {name: "370 Gal Fuel tank", content: [fuelTank370Left], fireOrder: [0], launcherDragArea: 0.35, launcherMass: 531, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1, category: 2},
	m: {name: "370 Gal Fuel tank", content: [fuelTank370Right], fireOrder: [0], launcherDragArea: 0.35, launcherMass: 531, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1, category: 2},
	o: {name: "600 Gal Fuel tank", content: [fuelTank600Left], fireOrder: [0], launcherDragArea: 0.30, launcherMass: 399, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 3},
	p: {name: "600 Gal Fuel tank", content: [fuelTank600Right], fireOrder: [0], launcherDragArea: 0.30, launcherMass: 399, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 3},
	q: {name: "1 x AIM-9", content: ["AIM-9"], fireOrder: [0], launcherDragArea: -0.025, launcherMass: 10, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},#non wingtip
	r: {name: "1 x AIM-120", content: ["AIM-120"], fireOrder: [0], launcherDragArea: -0.05, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},#wingtip
	q7: {name: "1 x AIM-7", content: ["AIM-7"], fireOrder: [0], launcherDragArea: -0.025, launcherMass: 10, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},#non wingtip
	s: {name: "1 x Smokewinder Red", content: [smokewinderRed1], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},
	t: {name: "1 x Smokewinder Green", content: [smokewinderGreen1], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},
	u: {name: "1 x Smokewinder Blue", content: [smokewinderBlue1], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},
	v: {name: "1 x Smokewinder Red", content: [smokewinderRed9], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},
	w: {name: "1 x Smokewinder Green", content: [smokewinderGreen9], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},
	x: {name: "1 x Smokewinder Blue", content: [smokewinderBlue9], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},
	w1: {name: "1 x Smokewinder White", content: [smokewinderWhite1], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},
	w9: {name: "1 x Smokewinder White", content: [smokewinderWhite9], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},
};

if (getprop("sim/model/f16/wingmounts") != 0) {
	# all variants except YF-16 gets store options:

	# source for fuel tanks content, fuel type, jettisonable and drag: TO. GR1F-16CJ-1-1

	# sets
	var pylon120set = [pylonSets.empty, pylonSets.q, pylonSets.h, pylonSets.k];
	var wingtipSet1  = [pylonSets.k,pylonSets.k2,     pylonSets.g, pylonSets.r,pylonSets.s,pylonSets.t,pylonSets.u,pylonSets.w1];# wingtips are normally not empty, so AN-T-17 dummy aim9 is loaded instead.
	var wingtipSet9  = [pylonSets.k,pylonSets.k2,     pylonSets.g, pylonSets.r,pylonSets.v,pylonSets.w,pylonSets.x,pylonSets.w9];# wingtips are normally not empty, so AN-T-17 dummy aim9 is loaded instead.
	var pylon9mix   = [pylonSets.empty, pylonSets.q, pylonSets.i, pylonSets.h, pylonSets.q7, pylonSets.a, pylonSets.b];
	var pylon12setL = [pylonSets.empty, pylonSets.j, pylonSets.l, pylonSets.o];
	var pylon12setR = [pylonSets.empty, pylonSets.j, pylonSets.m, pylonSets.p];

	# pylons
	pylon1 = stations.Pylon.new("Left Wingtip Pylon", 0, [0,0,0], wingtipSet1, 0, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[1]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[1]",1),func{return getprop("payload/armament/fire-control/serviceable")});
	pylon2 = stations.Pylon.new("Left Outer Wing Pylon", 1, [0,0,0], pylon120set, 1, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[2]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[2]",1),func{return getprop("payload/armament/fire-control/serviceable")});
	pylon3 = stations.Pylon.new("Left Wing Pylon", 2, [0,0,0], pylon9mix, 2, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[3]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[3]",1),func{return getprop("payload/armament/fire-control/serviceable")});
	pylon4 = stations.Pylon.new("Left Inner Wing Pylon", 3, [0,0,0], pylon12setL, 3, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[4]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[4]",1),func{return getprop("payload/armament/fire-control/serviceable")});
	pylon5 = stations.Pylon.new("Center Pylon", 4, [0,0,0], [pylonSets.empty, pylonSets.f,pylonSets.f2], 4, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[5]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[5]",1),func{return getprop("payload/armament/fire-control/serviceable")});
	pylon6 = stations.Pylon.new("Right Inner Wing Pylon", 5, [0,0,0], pylon12setR, 5, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[6]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[6]",1),func{return getprop("payload/armament/fire-control/serviceable")});
	pylon7 = stations.Pylon.new("Right Wing Pylon", 6, [0,0,0], pylon9mix, 6, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[7]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[7]",1),func{return getprop("payload/armament/fire-control/serviceable")});
	pylon8 = stations.Pylon.new("Right Outer Wing Pylon", 7, [0,0,0], pylon120set, 7, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[8]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[8]",1),func{return getprop("payload/armament/fire-control/serviceable")});
	pylon9 = stations.Pylon.new("Right Wingtip Pylon", 8, [0,0,0], wingtipSet9, 8, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[9]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[9]",1),func{return getprop("payload/armament/fire-control/serviceable")});
	pylonI = stations.InternalStation.new("Internal gun mount", 9, [pylonSets.e], props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[10]",1));

	var pylons = [pylon1,pylon2,pylon3,pylon4,pylon5,pylon6,pylon7,pylon8,pylon9,pylonI];

	fcs = fc.FireControl.new(pylons, [9,0,8,1,7,2,6,3,5,4], ["20mm Cannon","AIM-9","AIM-120","AIM-7","AGM-65","GBU-12","AGM-84"]);

	var aimListener = func (obj) {
		#If auto focus on missile is activated the we call the function
        if(getprop("/controls/armament/automissileview"))# and !getprop("payload/armament/msg")
        {
          view.view_firing_missile(obj);
        } 
    };
    pylon1.setAIMListener(aimListener);
    pylon2.setAIMListener(aimListener);
    pylon3.setAIMListener(aimListener);
    pylon4.setAIMListener(aimListener);
    pylon5.setAIMListener(aimListener);
    pylon6.setAIMListener(aimListener);
    pylon7.setAIMListener(aimListener);
    pylon8.setAIMListener(aimListener);
    pylon9.setAIMListener(aimListener);

} else {
	# YF-16 only get wingtip aim9 dummies:

	# sets
	var wingtipSet1yf  = [pylonSets.k,pylonSets.k2];# wingtips are normally not empty, so AN-T-17 dummy aim9 is loaded instead.
	var wingtipSet9yf  = [pylonSets.k,pylonSets.k2];# wingtips are normally not empty, so AN-T-17 dummy aim9 is loaded instead.

	# pylons
	pylon1 = stations.Pylon.new("Left Wingtip Pylon", 0, [0,0,0], wingtipSet1yf, 0, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[1]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[1]",1));
	pylon9 = stations.Pylon.new("Right Wingtip Pylon", 8, [0,0,0], wingtipSet9yf, 1, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[9]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[9]",1));
}
#print("** Pylon & fire control system started. **");
var getDLZ = func {
    if (fcs != nil and getprop("controls/armament/master-arm") == 1) {
        var w = fcs.getSelectedWeapon();
        if (w!=nil and w.parents[0] == armament.AIM) {
        	return w.getDLZ();
        }
    }
    return nil;
}

#Air patrol configuration
var a2a_patrol = func {
    if (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.g);
        pylon2.loadSet(pylonSets.h);
        pylon3.loadSet(pylonSets.q7);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.f);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.q7);
        pylon8.loadSet(pylonSets.h);
        pylon9.loadSet(pylonSets.g);
    } else {
      screen.log.write("Please land before changing payload.");
    }
}

# Air superiority configuration
var a2a_super = func {
    if (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
    	pylon1.loadSet(pylonSets.g);
        pylon2.loadSet(pylonSets.h);
        pylon3.loadSet(pylonSets.h);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.f);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.h);
        pylon8.loadSet(pylonSets.h);
        pylon9.loadSet(pylonSets.g);
    } else {
      screen.log.write("Please land before changing payload.");
    }
}

# Standoff configuration
var a2a_standoff = func {
    if (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        setprop("payload/weight[0]/selected", "1 x AIM-120");
        setprop("payload/weight[1]/selected", "1 x AIM-9");
        setprop("payload/weight[2]/selected", "Empty");
        pylon4.loadSet(pylonSets.l);
        setprop("payload/weight[4]/selected", "AN/ALQ-131 ECM Pod");
        pylon6.loadSet(pylonSets.m);
        setprop("payload/weight[6]/selected", "Empty");
        setprop("payload/weight[7]/selected", "1 x AIM-9");
        setprop("payload/weight[8]/selected", "1 x AIM-120");
    } else {
      screen.log.write("Please land before changing payload.");
    }
}
# Standart configuration for bombing : 2 2XGBU and 2 AGM65
var a2g_standard = func {
    if (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        setprop("payload/weight[0]/selected", "1 x AIM-9");
        setprop("payload/weight[1]/selected", "1 x AIM-120");
        setprop("payload/weight[2]/selected", "1 x AGM-65");
        setprop("payload/weight[3]/selected", "2 x GBU-12");
        setprop("payload/weight[4]/selected", "Empty");
        setprop("payload/weight[5]/selected", "2 x GBU-12");
        setprop("payload/weight[6]/selected", "1 x AGM-65");
        setprop("payload/weight[7]/selected", "1 x AIM-120");
        setprop("payload/weight[8]/selected", "1 x AIM-9");
    } else {
      screen.log.write("Please land before changing payload.");
    }
}
