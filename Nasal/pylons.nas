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
var pylon10 = nil;
var pylon11 = nil;

var cannon = stations.SubModelWeapon.new("20mm Cannon", 0.254, 511, 2, [1,3], props.globals.getNode("fdm/jsbsim/fcs/guntrigger",1), 0, func{return getprop("fdm/jsbsim/systems/hydraulics/sysb-psi")>=2000 and getprop("payload/armament/fire-control/serviceable");});
var fuelTankCenter = stations.FuelTank.new("Center 300 Gal Tank", "TK300", 4, 300, "sim/model/f16/ventraltank");
var fuelTank370Left = stations.FuelTank.new("Left 370 Gal Tank", "TK370", 3, 370, "sim/model/f16/wingtankL");
var fuelTank370Right = stations.FuelTank.new("Right 370 Gal Tank", "TK370", 2, 370, "sim/model/f16/wingtankR");
var fuelTank600Left = stations.FuelTank.new("Left 600 Gal Tank", "TK600", 3, 600, "sim/model/f16/wingtankL6");
var fuelTank600Right = stations.FuelTank.new("Right 600 Gal Tank", "TK600", 2, 600, "sim/model/f16/wingtankR6");
var smokewinderRed1 = stations.Smoker.new("Smokewinder Red", "SmokeR", "sim/model/f16/smokewinderR1");
var smokewinderGreen1 = stations.Smoker.new("Smokewinder Green", "SmokeG", "sim/model/f16/smokewinderG1");
var smokewinderBlue1 = stations.Smoker.new("Smokewinder Blue", "SmokeB", "sim/model/f16/smokewinderB1");
var smokewinderRed9 = stations.Smoker.new("Smokewinder Red", "SmokeR", "sim/model/f16/smokewinderR9");
var smokewinderGreen9 = stations.Smoker.new("Smokewinder Green", "SmokeG", "sim/model/f16/smokewinderG9");
var smokewinderBlue9 = stations.Smoker.new("Smokewinder Blue", "SmokeB", "sim/model/f16/smokewinderB9");
var smokewinderWhite1 = stations.Smoker.new("Smokewinder White", "SmokeW", "sim/model/f16/smokewinderW1");
var smokewinderWhite9 = stations.Smoker.new("Smokewinder White", "SmokeW", "sim/model/f16/smokewinderW9");
var tgp = stations.Smoker.new("AN/AAQ-33 Sniper ATP", "AAQ-33", "f16/stores/tgp-mounted");
var tgp2 = stations.Smoker.new("AN/AAQ-14 LANTIRN Target Pod", "AAQ-14", "f16/stores/tgp-mounted");
var tgp3 = stations.Smoker.new("AN/AAQ-13 LANTIRN Nav Pod", "AAQ-13", "f16/stores/nav-mounted");
var dummy = stations.Dummy.new("AN-T-17", nil);
var dummy2 = stations.Dummy.new("CATM-9L", nil);# nil for shortname makes them not show up in MFD SMS page. If shortname is nil it MUST have showLongTypeInsteadOfCount: 1
var dummy3 = stations.Dummy.new("AN/ALQ-131 ECM Pod", "AL131");
var dummy4 = stations.Dummy.new("MXU-648 Cargopod", "TRVL");
var pylonSets = {
	empty: {name: "Empty", content: [], fireOrder: [], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},
	a: {name: "3 x AGM-65", content: ["AGM-65", "AGM-65", "AGM-65"], fireOrder: [0,1,2], launcherDragArea: 0, launcherMass: 10, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 2},
	b: {name: "1 x AGM-84", content: ["AGM-84"], fireOrder: [0], launcherDragArea: 0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    b2: {name: "1 x AGM-88", content: ["AGM-88"], fireOrder: [0], launcherDragArea: 0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
	c: {name: "3 x MK-82", content: ["MK-82","MK-82","MK-82"], fireOrder: [0,1,2], launcherDragArea: 0.005, launcherMass: 10, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 2},
    c3: {name: "1 x GBU-31", content: ["GBU-31"], fireOrder: [0], launcherDragArea: 0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    c4: {name: "1 x GBU-24", content: ["GBU-24"], fireOrder: [0], launcherDragArea: 0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    c5: {name: "1 x MK-84", content: ["MK-84"], fireOrder: [0], launcherDragArea: 0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    d: {name: "2 x MK-83", content: ["MK-83","MK-83"], fireOrder: [0,1], launcherDragArea: 0.005, launcherMass: 10, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 2},
	e: {name: "20mm Cannon", content: [cannon], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	f: {name: "300 Gal Fuel tank", content: [fuelTankCenter], fireOrder: [0], launcherDragArea: 0.18, launcherMass: 392, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1, category: 1},
	f2: {name: "AN/ALQ-131 ECM Pod", content: [dummy3], fireOrder: [], launcherDragArea: 0.18, launcherMass: 410, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1, category: 1},
    f3: {name: "MXU-648 Cargopod", content: [dummy4], fireOrder: [], launcherDragArea: 0.18, launcherMass: 104, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1, category: 1},
	g: {name: "1 x AIM-9", content: ["AIM-9"], fireOrder: [0], launcherDragArea: -0.0785, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},#wingtip
	h: {name: "1 x AIM-120", content: ["AIM-120"], fireOrder: [0], launcherDragArea: -0.025, launcherMass: 10, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},#non wingtip
	i: {name: "3 x GBU-12", content: ["GBU-12","GBU-12", "GBU-12"], fireOrder: [0,1,2], launcherDragArea: 0.005, launcherMass: 10, launcherJettisonable: 1, showLongTypeInsteadOfCount: 0, category: 2},
	j: {name: "2 x GBU-12", content: ["GBU-12", "GBU-12"], fireOrder: [0,1], launcherDragArea: 0.005, launcherMass: 10, launcherJettisonable: 1, showLongTypeInsteadOfCount: 0, category: 2},
	k: {name: "AN-T-17", content: [dummy], fireOrder: [], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	k2: {name: "CATM-9L", content: [dummy2], fireOrder: [], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	l: {name: "370 Gal Fuel tank", content: [fuelTank370Left], fireOrder: [0], launcherDragArea: 0.35, launcherMass: 531, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1, category: 2},
	m: {name: "370 Gal Fuel tank", content: [fuelTank370Right], fireOrder: [0], launcherDragArea: 0.35, launcherMass: 531, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1, category: 2},
	o: {name: "600 Gal Fuel tank", content: [fuelTank600Left], fireOrder: [0], launcherDragArea: 0.30, launcherMass: 399, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 3},
	p: {name: "600 Gal Fuel tank", content: [fuelTank600Right], fireOrder: [0], launcherDragArea: 0.30, launcherMass: 399, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 3},
	q: {name: "1 x AIM-9", content: ["AIM-9"], fireOrder: [0], launcherDragArea: -0.025, launcherMass: 10, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},#non wingtip
	r: {name: "1 x AIM-120", content: ["AIM-120"], fireOrder: [0], launcherDragArea: -0.05, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},#wingtip
	q7: {name: "1 x AIM-7", content: ["AIM-7"], fireOrder: [0], launcherDragArea: -0.025, launcherMass: 10, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},#non wingtip
	s: {name: "Smokewinder Red", content: [smokewinderRed1], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	t: {name: "Smokewinder Green", content: [smokewinderGreen1], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	u: {name: "Smokewinder Blue", content: [smokewinderBlue1], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	v: {name: "Smokewinder Red", content: [smokewinderRed9], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	w: {name: "Smokewinder Green", content: [smokewinderGreen9], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	x: {name: "Smokewinder Blue", content: [smokewinderBlue9], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	w1: {name: "Smokewinder White", content: [smokewinderWhite1], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	w9: {name: "Smokewinder White", content: [smokewinderWhite9], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    tgp: {name: "AN/AAQ-33 Sniper ATP", content: [tgp], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 446, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    tgp2: {name: "AN/AAQ-14 LANTIRN Target Pod", content: [tgp2], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 470, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    tgp3: {name: "AN/AAQ-13 LANTIRN Nav Pod", content: [tgp3], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 470, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
};

if (getprop("sim/model/f16/wingmounts") != 0) {
	# all variants except YF-16 gets store options:

	# source for fuel tanks content, fuel type, jettisonable and drag: TO. GR1F-16CJ-1-1

	# sets
	var pylon120set = [pylonSets.empty, pylonSets.q, pylonSets.h, pylonSets.k];
	var wingtipSet1  = [pylonSets.k,pylonSets.k2,     pylonSets.g, pylonSets.r,pylonSets.s,pylonSets.t,pylonSets.u,pylonSets.w1];# wingtips are normally not empty, so AN-T-17 dummy aim9 is loaded instead.
	var wingtipSet9  = [pylonSets.k,pylonSets.k2,     pylonSets.g, pylonSets.r,pylonSets.v,pylonSets.w,pylonSets.x,pylonSets.w9];# wingtips are normally not empty, so AN-T-17 dummy aim9 is loaded instead.
	var pylon9mix   = [pylonSets.empty, pylonSets.q, pylonSets.i, pylonSets.h, pylonSets.q7, pylonSets.a, pylonSets.b, pylonSets.c, pylonSets.b2, pylonSets.c3, pylonSets.f3, pylonSets.c4, pylonSets.d, pylonSets.c5];
	var pylon12setL = [pylonSets.empty, pylonSets.j, pylonSets.l, pylonSets.o, pylonSets.c, pylonSets.c3, pylonSets.c4, pylonSets.b2, pylonSets.d, pylonSets.c5];
	var pylon12setR = [pylonSets.empty, pylonSets.j, pylonSets.m, pylonSets.p, pylonSets.c, pylonSets.c3, pylonSets.c4, pylonSets.b2, pylonSets.d, pylonSets.c5];
    var fuselageset = [pylonSets.empty, pylonSets.tgp, pylonSets.tgp2, pylonSets.tgp3];

	# pylons
	pylon1 = stations.Pylon.new("Left Wingtip Pylon",     0, [0.082,-4.79412, 0.01109], wingtipSet1, 0, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[1]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[1]",1),func{return getprop("payload/armament/fire-control/serviceable")});
	pylon2 = stations.Pylon.new("Left Outer Wing Pylon",  1, [0.082,-3.95167,-0.25696], pylon120set, 1, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[2]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[2]",1),func{return getprop("payload/armament/fire-control/serviceable")});
	pylon3 = stations.Pylon.new("Left Wing Pylon",        2, [0.082,-2.88034,-0.25696], pylon9mix, 2, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[3]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[3]",1),func{return getprop("payload/armament/fire-control/serviceable")});
	pylon4 = stations.Pylon.new("Left Inner Wing Pylon",  3, [0.082,-1.62889,-0.25696], pylon12setL, 3, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[4]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[4]",1),func{return getprop("payload/armament/fire-control/serviceable")});
	pylon5 = stations.Pylon.new("Center Pylon",           4, [0.082, 0,      -0.83778], [pylonSets.empty, pylonSets.f,pylonSets.f2, pylonSets.f3], 4, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[5]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[5]",1),func{return getprop("payload/armament/fire-control/serviceable")});
	pylon6 = stations.Pylon.new("Right Inner Wing Pylon", 5, [0.082, 1.62889,-0.25696], pylon12setR, 5, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[6]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[6]",1),func{return getprop("payload/armament/fire-control/serviceable")});
	pylon7 = stations.Pylon.new("Right Wing Pylon",       6, [0.082, 2.88034,-0.25696], pylon9mix, 6, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[7]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[7]",1),func{return getprop("payload/armament/fire-control/serviceable")});
	pylon8 = stations.Pylon.new("Right Outer Wing Pylon", 7, [0.082, 3.95167,-0.25696], pylon120set, 7, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[8]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[8]",1),func{return getprop("payload/armament/fire-control/serviceable")});
	pylon9 = stations.Pylon.new("Right Wingtip Pylon",    8, [0.082, 4.79412, 0.01109], wingtipSet9, 8, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[9]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[9]",1),func{return getprop("payload/armament/fire-control/serviceable")});
    pylon10= stations.Pylon.new("Right Fuselage Pylon",  10, [0.082, 4.79412, 0.01109], fuselageset, 9, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[30]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[30]",1),func{return 1;});
	pylonI = stations.InternalStation.new("Internal gun mount", 9, [pylonSets.e], props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[10]",1));
	pylon11= stations.Pylon.new("Left Fuselage Pylon",   11, [0,0,0], fuselageset, 10, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[31]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[31]",1),func{return 1;});

    var pylons = [pylon1,pylon2,pylon3,pylon4,pylon5,pylon6,pylon7,pylon8,pylon9,pylonI,pylon10,pylon11];

	fcs = fc.FireControl.new(pylons, [9,0,8,1,7,2,6,3,5,4], ["20mm Cannon","AIM-9","AIM-120","AIM-7","AGM-65","GBU-12","AGM-84","MK-82","AGM-88", "GBU-31", "GBU-24", "MK-83", "MK-84"]);

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
	# YF-16 only get wingtip aim9 dummies plus smoke:

	# sets
	var wingtipSet1yf  = [pylonSets.k,pylonSets.k2, pylonSets.s,pylonSets.t,pylonSets.u];# wingtips are normally not empty, so AN-T-17 dummy aim9 is loaded instead.
	var wingtipSet9yf  = [pylonSets.k,pylonSets.k2, pylonSets.v,pylonSets.w,pylonSets.x];# wingtips are normally not empty, so AN-T-17 dummy aim9 is loaded instead.

	# pylons
	pylon1 = stations.Pylon.new("Left Wingtip Pylon", 0, [0,0,0], wingtipSet1yf, 0, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[1]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[1]",1));
	pylon9 = stations.Pylon.new("Right Wingtip Pylon", 8, [0,0,0], wingtipSet9yf, 1, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[9]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[9]",1));
}
#print("** Pylon & fire control system started. **");
var getDLZ = func {
    if (fcs != nil and getprop("controls/armament/master-arm") == 1) {
        var w = fcs.getSelectedWeapon();
        if (w!=nil and w.parents[0] == armament.AIM) {
            var result = w.getDLZ(1);
            if (result != nil and size(result) == 5 and result[4]<result[0]*1.5 and armament.contact != nil and armament.contact.get_display()) {
                #target is within 150% of max weapon fire range.
        	    return result;
            }
        }
    }
    return nil;
}

# Air patrol
var a2a_patrol = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.g);
        pylon2.loadSet(pylonSets.h);
        pylon3.loadSet(pylonSets.q7);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.f);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.q7);
        pylon8.loadSet(pylonSets.h);
        pylon9.loadSet(pylonSets.g);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Air superiority
var a2a_super = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
    	pylon1.loadSet(pylonSets.h);
        pylon2.loadSet(pylonSets.h);
        pylon3.loadSet(pylonSets.h);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.f);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.h);
        pylon8.loadSet(pylonSets.h);
        pylon9.loadSet(pylonSets.h);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# CAP
var a2a_cap = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.g);
        pylon2.loadSet(pylonSets.h);
        pylon3.loadSet(pylonSets.h);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.f);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.h);
        pylon8.loadSet(pylonSets.h);
        pylon9.loadSet(pylonSets.g);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# CAP (extended loiter)
var a2a_capext = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.g);
        pylon2.loadSet(pylonSets.h);
        pylon3.loadSet(pylonSets.h);
        pylon4.loadSet(pylonSets.l);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.m);
        pylon7.loadSet(pylonSets.h);
        pylon8.loadSet(pylonSets.h);
        pylon9.loadSet(pylonSets.g);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}
# CAS: 2 3XMK82 and 2 AGM65
var a2g_cas = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.g);
        pylon2.loadSet(pylonSets.h);
        pylon3.loadSet(pylonSets.a);
        pylon4.loadSet(pylonSets.c);
        pylon5.loadSet(pylonSets.f);
        pylon6.loadSet(pylonSets.c);
        pylon7.loadSet(pylonSets.a);
        pylon8.loadSet(pylonSets.h);
        pylon9.loadSet(pylonSets.g);
        pylon10.loadSet(pylonSets.tgp2);
        pylon11.loadSet(pylonSets.tgp3);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# CAS (extended loiter): 2 3XAGM-65
var a2g_casext = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.g);
        pylon2.loadSet(pylonSets.h);
        pylon3.loadSet(pylonSets.a);
        pylon4.loadSet(pylonSets.l);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.m);
        pylon7.loadSet(pylonSets.a);
        pylon8.loadSet(pylonSets.h);
        pylon9.loadSet(pylonSets.g);
        pylon10.loadSet(pylonSets.tgp2);
        pylon11.loadSet(pylonSets.tgp3);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Air strike : 2 3XGBU and 2 2XMK83
var a2g_mix = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.g);
        pylon2.loadSet(pylonSets.h);
        pylon3.loadSet(pylonSets.i);
        pylon4.loadSet(pylonSets.d);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.d);
        pylon7.loadSet(pylonSets.i);
        pylon8.loadSet(pylonSets.h);
        pylon9.loadSet(pylonSets.g);
        pylon10.loadSet(pylonSets.tgp2);
        pylon11.loadSet(pylonSets.tgp3);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Guided A/G 1 : 2 GBU-24 and 2 2XGBU
var a2g_guided1 = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.g);
        pylon2.loadSet(pylonSets.h);
        pylon3.loadSet(pylonSets.c4);
        pylon4.loadSet(pylonSets.j);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.j);
        pylon7.loadSet(pylonSets.c4);
        pylon8.loadSet(pylonSets.h);
        pylon9.loadSet(pylonSets.g);
        pylon10.loadSet(pylonSets.tgp2);
        pylon11.loadSet(pylonSets.tgp3);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Guided A/G 2 : 2 JDAM and 2 3XGBU
var a2g_guided2 = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.g);
        pylon2.loadSet(pylonSets.h);
        pylon3.loadSet(pylonSets.i);
        pylon4.loadSet(pylonSets.c3);
        pylon5.loadSet(pylonSets.f);
        pylon6.loadSet(pylonSets.c3);
        pylon7.loadSet(pylonSets.i);
        pylon8.loadSet(pylonSets.h);
        pylon9.loadSet(pylonSets.g);
        pylon10.loadSet(pylonSets.tgp2);
        pylon11.loadSet(pylonSets.tgp3);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Anti-ship: 2 2XGBU and 2 AGM84
var a2s_antiship = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.g);
        pylon2.loadSet(pylonSets.h);
        pylon3.loadSet(pylonSets.b);
        pylon4.loadSet(pylonSets.c3);
        pylon5.loadSet(pylonSets.f);
        pylon6.loadSet(pylonSets.c3);
        pylon7.loadSet(pylonSets.b);
        pylon8.loadSet(pylonSets.h);
        pylon9.loadSet(pylonSets.g);
        pylon10.loadSet(pylonSets.tgp2);
        pylon11.loadSet(pylonSets.tgp3);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Ferry configuration: 3 droptanks
var a2a_ferry = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.g);
        pylon2.loadSet(pylonSets.h);
        pylon3.loadSet(pylonSets.empty);
        pylon4.loadSet(pylonSets.l);
        pylon5.loadSet(pylonSets.f);
        pylon6.loadSet(pylonSets.m);
        pylon7.loadSet(pylonSets.empty);
        pylon8.loadSet(pylonSets.h);
        pylon9.loadSet(pylonSets.g);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Ferry configuration w/ cargo: 2 droptanks, 2 cargopods
var a2a_ferrycargo = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.h);
        pylon2.loadSet(pylonSets.g);
        pylon3.loadSet(pylonSets.f3);
        pylon4.loadSet(pylonSets.o);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.p);
        pylon7.loadSet(pylonSets.f3);
        pylon8.loadSet(pylonSets.g);
        pylon9.loadSet(pylonSets.h);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# SEAD: 2 AGM88 and ECM pod
var a2g_sead = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.h);
        pylon2.loadSet(pylonSets.g);
        pylon3.loadSet(pylonSets.b2);
        pylon4.loadSet(pylonSets.l);
        pylon5.loadSet(pylonSets.f2);
        pylon6.loadSet(pylonSets.m);
        pylon7.loadSet(pylonSets.b2);
        pylon8.loadSet(pylonSets.g);
        pylon9.loadSet(pylonSets.h);
        pylon10.loadSet(pylonSets.tgp2);
        pylon11.loadSet(pylonSets.tgp3);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# OCA: 4 AA missiles and 2 3x AGM65
var a2g_oca = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.g);
        pylon2.loadSet(pylonSets.h);
        pylon3.loadSet(pylonSets.a);
        pylon4.loadSet(pylonSets.b2);
        pylon5.loadSet(pylonSets.f);
        pylon6.loadSet(pylonSets.b2);
        pylon7.loadSet(pylonSets.a);
        pylon8.loadSet(pylonSets.h);
        pylon9.loadSet(pylonSets.g);
        pylon10.loadSet(pylonSets.tgp2);
        pylon11.loadSet(pylonSets.tgp3);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Peacetime training configuration
var a2a_training = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.k2);
        pylon2.loadSet(pylonSets.k);
        pylon3.loadSet(pylonSets.empty);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.empty);
        pylon8.loadSet(pylonSets.k);
        pylon9.loadSet(pylonSets.k2);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Clean configuration
var clean = func {
    if (fcs != nil and getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        pylon1.loadSet(pylonSets.k);# F16 never has nothing on wingtips unless its fired off, its aerodynamics is designed to work better with something there.
        pylon2.loadSet(pylonSets.empty);
        pylon3.loadSet(pylonSets.empty);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.empty);
        pylon8.loadSet(pylonSets.empty);
        pylon9.loadSet(pylonSets.k);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

var bore_loop = func {
    #enables firing of aim9 without radar.
    bore = 0;
    if (fcs != nil) {
        var standby = getprop("instrumentation/radar/radar-standby");
        var aim = fcs.getSelectedWeapon();
        if (aim != nil and aim.type == "AIM-9") {
            if (standby == 1) {
                #aim.setBore(1);
                aim.setContacts(awg_9.completeList);
                aim.commandDir(0,-3.5);# the real is bored to -6 deg below real bore
                bore = 1;
            } else {
                aim.commandRadar();
                aim.setContacts([]);
            }
        }
    }
    settimer(bore_loop, 0.5);
};
var bore = 0;
if (fcs!=nil) {
    bore_loop();
}
