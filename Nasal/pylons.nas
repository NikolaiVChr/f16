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

var cannon = stations.SubModelWeapon.new("20mm Cannon", 0.254, 511, [2], [1,3], props.globals.getNode("fdm/jsbsim/fcs/guntrigger",1), 0, func{return getprop("fdm/jsbsim/elec/bus/emergency-dc-2")>=20 and getprop("fdm/jsbsim/elec/bus/emergency-ac-2")>=100 and getprop("fdm/jsbsim/systems/hydraulics/sysb-psi")>=2000 and getprop("payload/armament/fire-control/serviceable");},0);
cannon.typeShort = "GUN";
cannon.brevity = "Guns guns";
var hyd70lh3 = stations.SubModelWeapon.new("LAU-68", 23.6, 7, [4], [], props.globals.getNode("fdm/jsbsim/fcs/hydra3ltrigger",1), 1, func{return getprop("payload/armament/fire-control/serviceable");},1);
hyd70lh3.typeShort = "LAU-68";
hyd70lh3.brevity = "Rockets away";
var hyd70rh3 = stations.SubModelWeapon.new("LAU-68", 23.6, 7, [5], [], props.globals.getNode("fdm/jsbsim/fcs/hydra3rtrigger",1), 1, func{return getprop("payload/armament/fire-control/serviceable");},1);
hyd70rh3.typeShort = "LAU-68";
hyd70rh3.brevity = "Rockets away";
var hyd70lh7 = stations.SubModelWeapon.new("LAU-68", 23.6, 7, [6], [], props.globals.getNode("fdm/jsbsim/fcs/hydra7ltrigger",1), 1, func{return getprop("payload/armament/fire-control/serviceable");},1);
hyd70lh7.typeShort = "LAU-68";
hyd70lh7.brevity = "Rockets away";
var hyd70rh7 = stations.SubModelWeapon.new("LAU-68", 23.6, 7, [7], [], props.globals.getNode("fdm/jsbsim/fcs/hydra7rtrigger",1), 1, func{return getprop("payload/armament/fire-control/serviceable");},1);
hyd70rh7.typeShort = "LAU-68";
hyd70rh7.brevity = "Rockets away";
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
var atp = stations.Smoker.new("AN/AAQ-33 Sniper ATP", "AAQ-33", "f16/stores/tgp-mounted");
var tgp = stations.Smoker.new("AN/AAQ-14 LANTIRN Target Pod", "AAQ-14", "f16/stores/tgp-mounted");
var nav = stations.Smoker.new("AN/AAQ-13 LANTIRN Nav Pod", "AAQ-13", "f16/stores/nav-mounted");
var lite = stations.Smoker.new("AN/AAQ-28 LITENING Advanced Targeting", "AAQ-28", "f16/stores/tgp-mounted");
var irst = stations.Smoker.new("Legion Pod IRST", "IRST", "f16/stores/irst-mounted");
var harm = stations.Smoker.new("AN/ASQ-213 HARM TS Pod", "ASQ-213", "f16/stores/harm-mounted");
var acmi = stations.Smoker.new("AN/ASQ-T50(V)1 ACMI Pod", "ACMI", "f16/stores/acmi-mounted");
var ecm131 = stations.Smoker.new("AN/ALQ-131(V) ECM Pod", "AL131", "f16/stores/ecm-mounted");
var ecm184 = stations.Smoker.new("AN/ALQ-184(V) ECM Pod", "AL184", "f16/stores/ecm-mounted");
var catm9 = stations.Dummy.new("CATM-9L", nil);
var ant17 = stations.Dummy.new("AN-T-17", nil);# nil for shortname makes them not show up in MFD SMS page. If shortname is nil it MUST have showLongTypeInsteadOfCount: 1
var catm120 = stations.Dummy.new("CATM-120B", nil);
var crgpd = stations.Dummy.new("MXU-648 Cargopod", "TRVL");

var pylonSets = {
	empty: {name: "Empty", content: [], fireOrder: [], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},
	mm20:  {name: "20mm Cannon", content: [cannon], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	hyd70h3:  {name: "2 x LAU-68", content: [hyd70lh3,hyd70rh3], fireOrder: [0,1], launcherDragArea: 0.007, launcherMass: 405.0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 2},
	hyd70h7:  {name: "2 x LAU-68", content: [hyd70lh7,hyd70rh7], fireOrder: [0,1], launcherDragArea: 0.007, launcherMass: 405.0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 2},
	a65x3:  {name: "3 x AGM-65", content: ["AGM-65", "AGM-65", "AGM-65"], fireOrder: [0,1,2], launcherDragArea: 0.005, launcherMass: 10, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 2},
	a65:  {name: "1 x AGM-65", content: ["AGM-65"], fireOrder: [0], launcherDragArea: 0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 2},
	a84:  {name: "1 x AGM-84", content: ["AGM-84"], fireOrder: [0], launcherDragArea: 0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    a88: {name: "1 x AGM-88", content: ["AGM-88"], fireOrder: [0], launcherDragArea: 0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    a119:  {name: "1 x AGM-119", content: ["AGM-119"], fireOrder: [0], launcherDragArea: 0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    a158: {name: "1 x AGM-158", content: ["AGM-158"], fireOrder: [0], launcherDragArea: 0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    a154: {name: "1 x AGM-154A", content: ["AGM-154A"], fireOrder: [0], launcherDragArea: 0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    b617: {name: "1 x B61-7", content: ["B61-7"], fireOrder: [0], launcherDragArea: 0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    b6112: {name: "1 x B61-12", content: ["B61-12"], fireOrder: [0], launcherDragArea: 0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    g54: {name: "2 x GBU-54", content: ["GBU-54","GBU-54"], fireOrder: [0,1], launcherDragArea: 0.005, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 2},
    g31: {name: "1 x GBU-31", content: ["GBU-31"], fireOrder: [0], launcherDragArea: 0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    g24: {name: "1 x GBU-24", content: ["GBU-24"], fireOrder: [0], launcherDragArea: 0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    g12x3:  {name: "3 x GBU-12", content: ["GBU-12","GBU-12", "GBU-12"], fireOrder: [0,1,2], launcherDragArea: 0.005, launcherMass: 10, launcherJettisonable: 1, showLongTypeInsteadOfCount: 0, category: 2},
	g12x2:  {name: "2 x GBU-12", content: ["GBU-12", "GBU-12"], fireOrder: [0,1], launcherDragArea: 0.005, launcherMass: 10, launcherJettisonable: 1, showLongTypeInsteadOfCount: 0, category: 2},
	m82:  {name: "3 x MK-82", content: ["MK-82","MK-82","MK-82"], fireOrder: [0,1,2], launcherDragArea: 0.005, launcherMass: 10, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 2},
    m84: {name: "1 x MK-84", content: ["MK-84"], fireOrder: [0], launcherDragArea: 0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    m83:  {name: "2 x MK-83", content: ["MK-83","MK-83"], fireOrder: [0,1], launcherDragArea: 0.005, launcherMass: 10, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 2},
    c87:  {name: "2 x CBU-87", content: ["CBU-87","CBU-87"], fireOrder: [0,1], launcherDragArea: 0.005, launcherMass: 10, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 2},
    c105:  {name: "2 x CBU-105", content: ["CBU-105","CBU-105"], fireOrder: [0,1], launcherDragArea: 0.005, launcherMass: 10, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 2},
	dumb1:  {name: "CATM-9L", content: [catm9], fireOrder: [], launcherDragArea: -0.025, launcherMass: 185, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	dumb2: {name: "AN-T-17", content: [ant17], fireOrder: [], launcherDragArea: -0.02, launcherMass: 185, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	dumb3:  {name: "CATM-120B", content: [catm120], fireOrder: [], launcherDragArea: -0.025, launcherMass: 290, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	smokeRL: {name: "Smokewinder Red", content: [smokewinderRed1], fireOrder: [0], launcherDragArea: -0.05, launcherMass: 203, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	smokeGL: {name: "Smokewinder Green", content: [smokewinderGreen1], fireOrder: [0], launcherDragArea: -0.05, launcherMass: 203, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	smokeBL: {name: "Smokewinder Blue", content: [smokewinderBlue1], fireOrder: [0], launcherDragArea: -0.05, launcherMass: 203, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	smokeRR: {name: "Smokewinder Red", content: [smokewinderRed9], fireOrder: [0], launcherDragArea: -0.05, launcherMass: 203, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	smokeGR: {name: "Smokewinder Green", content: [smokewinderGreen9], fireOrder: [0], launcherDragArea: -0.05, launcherMass: 203, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	smokeBR: {name: "Smokewinder Blue", content: [smokewinderBlue9], fireOrder: [0], launcherDragArea: -0.05, launcherMass: 203, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	smokeWL: {name: "Smokewinder White", content: [smokewinderWhite1], fireOrder: [0], launcherDragArea: -0.05, launcherMass: 203, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	smokeWR: {name: "Smokewinder White", content: [smokewinderWhite9], fireOrder: [0], launcherDragArea: -0.05, launcherMass: 203, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	fuel30:  {name: fuelTankCenter.type, content: [fuelTankCenter], fireOrder: [0], launcherDragArea: 0.18, launcherMass: 392, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1, category: 1},
	fuel37L: {name: fuelTank370Left.type, content: [fuelTank370Left], fireOrder: [0], launcherDragArea: 0.35, launcherMass: 531, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1, category: 2},
	fuel37R: {name: fuelTank370Right.type, content: [fuelTank370Right], fireOrder: [0], launcherDragArea: 0.35, launcherMass: 531, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1, category: 2},
	fuel60L: {name: fuelTank600Left.type, content: [fuelTank600Left], fireOrder: [0], launcherDragArea: 0.40, launcherMass: 399, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 3},
	fuel60R: {name: fuelTank600Right.type, content: [fuelTank600Right], fireOrder: [0], launcherDragArea: 0.40, launcherMass: 399, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 3},
	aim9WT:  {name: "1 x AIM-9",   content: ["AIM-9"], fireOrder: [0], launcherDragArea: -0.0785, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},#wingtip
	aim9:    {name: "1 x AIM-9",   content: ["AIM-9"], fireOrder: [0], launcherDragArea: -0.025, launcherMass: 10, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},#non wingtip
	aim120:  {name: "1 x AIM-120", content: ["AIM-120"], fireOrder: [0], launcherDragArea: -0.025, launcherMass: 10, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},#non wingtip
	aim120WT:{name: "1 x AIM-120", content: ["AIM-120"], fireOrder: [0], launcherDragArea: -0.05, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},#wingtip
	aim7:    {name: "1 x AIM-7",   content: ["AIM-7"], fireOrder: [0], launcherDragArea: -0.025, launcherMass: 10, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},
	podEcm131: {name: "AN/ALQ-131(V) ECM Pod", content: [ecm131], fireOrder: [0], launcherDragArea: 0.16, launcherMass: 410, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 2},
	podEcm184: {name: "AN/ALQ-184(V) ECM Pod", content: [ecm184], fireOrder: [0], launcherDragArea: 0.1, launcherMass: 635, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 2},
    podTrvl: {name: "MXU-648 Cargopod", content: [crgpd], fireOrder: [], launcherDragArea: 0.14, launcherMass: 104, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1, category: 2},
    podSAtp: {name: "AN/AAQ-33 Sniper ATP", content: [atp], fireOrder: [0], launcherDragArea: 0.06, launcherMass: 446, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    podLTgp: {name: "AN/AAQ-14 LANTIRN Target Pod", content: [tgp], fireOrder: [0], launcherDragArea: 0.07, launcherMass: 530, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    podLNav:  {name: "AN/AAQ-13 LANTIRN Nav Pod", content: [nav], fireOrder: [0], launcherDragArea: 0.1, launcherMass: 451.1, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    podLite: {name: "AN/AAQ-28 LITENING Advanced Targeting", content: [lite], fireOrder: [0], launcherDragArea: 0.08, launcherMass: 460, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    podIrst: {name: "Legion Pod IRST", content: [irst], fireOrder: [0], launcherDragArea: 0.08, launcherMass: 500, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1}, #mass guess based on available data
    podHarm: {name: "AN/ASQ-213 HARM TS Pod", content: [harm], fireOrder: [0], launcherDragArea: 0.03, launcherMass: 100, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    podACMI: {name: "AN/ASQ-T50(V)1 ACMI Pod", content: [acmi], fireOrder: [0], launcherDragArea: -0.015, launcherMass: 138, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
};

if (getprop("sim/model/f16/wingmounts") != 0) {
	# all variants except YF-16 get store options:

	# source for fuel tanks content, fuel type, jettisonable and drag: TO. GR1F-16CJ-1-1

	# sets. The first in the list is the default. Earlier in the list means higher up in dropdown menu.
	var pylon2set = [pylonSets.empty, pylonSets.aim9, pylonSets.aim120, pylonSets.dumb1, pylonSets.podACMI];
	var pylon8set = [pylonSets.empty, pylonSets.aim9, pylonSets.aim120, pylonSets.dumb1, pylonSets.podACMI];
	var pylon1set = [pylonSets.dumb1,pylonSets.dumb2,pylonSets.dumb3, pylonSets.aim9WT, pylonSets.aim120WT,pylonSets.smokeRL,pylonSets.smokeGL,pylonSets.smokeBL,pylonSets.smokeWL];# wingtips are normally not empty, so CATM-9L dummy aim9 is loaded instead.
	var pylon9set = [pylonSets.dumb1,pylonSets.dumb2,pylonSets.dumb3, pylonSets.aim9WT, pylonSets.aim120WT,pylonSets.smokeRR,pylonSets.smokeGR,pylonSets.smokeBR,pylonSets.smokeWR];# wingtips are normally not empty, so CATM-9L dummy aim9 is loaded instead.
	var pylon3set = [pylonSets.empty, pylonSets.b617, pylonSets.b6112, pylonSets.podTrvl, pylonSets.hyd70h3, pylonSets.a154, pylonSets.a119, pylonSets.a158, pylonSets.a88, pylonSets.a84, pylonSets.a65x3, pylonSets.a65, pylonSets.c87, pylonSets.c105, pylonSets.g54, pylonSets.g31, pylonSets.g24, pylonSets.g12x3, pylonSets.m84, pylonSets.m83, pylonSets.m82, pylonSets.aim9, pylonSets.aim7, pylonSets.aim120];
	var pylon7set = [pylonSets.empty, pylonSets.b617, pylonSets.b6112, pylonSets.podTrvl, pylonSets.hyd70h7, pylonSets.a154, pylonSets.a119, pylonSets.a158, pylonSets.a88, pylonSets.a84, pylonSets.a65x3, pylonSets.a65, pylonSets.c87, pylonSets.c105, pylonSets.g54, pylonSets.g31, pylonSets.g24, pylonSets.g12x3, pylonSets.m84, pylonSets.m83, pylonSets.m82, pylonSets.aim9, pylonSets.aim7, pylonSets.aim120];
	var pylon4set = [pylonSets.empty, pylonSets.g12x2, pylonSets.fuel37L, pylonSets.fuel60L, pylonSets.m82, pylonSets.a119, pylonSets.a154, pylonSets.g54, pylonSets.g31, pylonSets.g24, pylonSets.a88, pylonSets.m83, pylonSets.c87, pylonSets.c105, pylonSets.m84];
	var pylon6set = [pylonSets.empty, pylonSets.g12x2, pylonSets.fuel37R, pylonSets.fuel60R, pylonSets.m82, pylonSets.a119, pylonSets.a154, pylonSets.g54, pylonSets.g31, pylonSets.g24, pylonSets.a88, pylonSets.m83, pylonSets.c87, pylonSets.c105, pylonSets.m84];
	var pylon5set = [pylonSets.empty, pylonSets.fuel30,pylonSets.podEcm131, pylonSets.podEcm184, pylonSets.podTrvl, pylonSets.b617, pylonSets.b6112];

	# TODO JMav16: Added these to quick payload select dialog: pylonSets.b617, pylonSets.b6112   (but I suggest dont keep them in above lines, too many weapons there now)

	# HTS can be carried on both left and right side.
	# Sniper, LITENING, IRST only on right	
    var fuselageRset = [pylonSets.empty, pylonSets.podSAtp, pylonSets.podLTgp, pylonSets.podLite, pylonSets.podIrst, pylonSets.podHarm];
    var fuselageLset = [pylonSets.empty, pylonSets.podLNav, pylonSets.podHarm];

	# pylons
	pylon1 = stations.Pylon.new("Left Wingtip Pylon",     0, [0.082,-4.79412, 0.01109], pylon1set, 0, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[1]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[1]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/elec/bus/ess-dc")>20;},func{return getprop("f16/avionics/power-st-sta");});
	pylon2 = stations.Pylon.new("Left Outer Wing Pylon",  1, [0.082,-3.95167,-0.25696], pylon2set, 1, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[2]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[2]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/elec/bus/ess-dc")>20;},func{return getprop("f16/avionics/power-st-sta");});
	pylon3 = stations.Pylon.new("Left Wing Pylon",        2, [0.082,-2.88034,-0.25696], pylon3set, 2, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[3]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[3]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/elec/bus/ess-dc")>20;},func{return getprop("f16/avionics/power-st-sta");});
	pylon4 = stations.Pylon.new("Left Inner Wing Pylon",  3, [0.082,-1.62889,-0.25696], pylon4set, 3, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[4]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[4]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/elec/bus/ess-dc")>20;},func{return getprop("f16/avionics/power-st-sta");});
	pylon11= stations.Pylon.new("Left Fuselage Pylon",   11, [0,0,0]                  , fuselageLset, 4, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[11]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[11]",1),func{return 1;},func{return 1;});
	pylon5 = stations.Pylon.new("Center Pylon",           4, [0.082, 0,      -0.83778], pylon5set, 5, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[5]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[5]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/elec/bus/ess-dc")>20;},func{return getprop("f16/avionics/power-st-sta");});
	pylon10= stations.Pylon.new("Right Fuselage Pylon",  10, [0,0,0]                  , fuselageRset, 6, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[12]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[12]",1),func{return 1;},func{return 1;});
	pylon6 = stations.Pylon.new("Right Inner Wing Pylon", 5, [0.082, 1.62889,-0.25696], pylon6set, 7, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[6]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[6]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/elec/bus/ess-dc")>20;},func{return getprop("f16/avionics/power-st-sta");});
	pylon7 = stations.Pylon.new("Right Wing Pylon",       6, [0.082, 2.88034,-0.25696], pylon7set, 8, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[7]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[7]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/elec/bus/ess-dc")>20;},func{return getprop("f16/avionics/power-st-sta");});
	pylon8 = stations.Pylon.new("Right Outer Wing Pylon", 7, [0.082, 3.95167,-0.25696], pylon8set, 9, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[8]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[8]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/elec/bus/ess-dc")>20;},func{return getprop("f16/avionics/power-st-sta");});
	pylon9 = stations.Pylon.new("Right Wingtip Pylon",    8, [0.082, 4.79412, 0.01109], pylon9set,10, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[9]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[9]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/elec/bus/ess-dc")>20;},func{return getprop("f16/avionics/power-st-sta");});
	pylonI = stations.InternalStation.new("Internal gun mount", 9, [pylonSets.mm20], props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[10]",1));
	
	pylon1.forceRail = 1;# set the missiles mounted on this pylon on a rail.
	pylon9.forceRail = 1;

    var pylons = [pylon1,pylon2,pylon3,pylon4,pylon5,pylon6,pylon7,pylon8,pylon9,pylonI,pylon10,pylon11];

    # The order in this line is the order key 'w' will cycle through the weapons:
	fcs = fc.FireControl.new(pylons, [9,0,8,1,7,2,6,3,5,4], ["20mm Cannon","LAU-68","AIM-9","AIM-120","AIM-7","AGM-65","GBU-12","AGM-84","MK-82","AGM-88","GBU-31","GBU-24","MK-83","MK-84","AGM-158","CBU-87","CBU-105","AGM-154A","GBU-54","AGM-119"]);

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
	var wingtipSet1yf  = [pylonSets.dumb1,pylonSets.dumb2,pylonSets.dumb3, pylonSets.smokeRL,pylonSets.smokeGL,pylonSets.smokeBL,pylonSets.smokeWL];# wingtips are normally not empty, so CATM-9L dummy aim9 is loaded instead.
	var wingtipSet9yf  = [pylonSets.dumb1,pylonSets.dumb2,pylonSets.dumb3, pylonSets.smokeRR,pylonSets.smokeGR,pylonSets.smokeBR,pylonSets.smokeWR];# wingtips are normally not empty, so CATM-9L dummy aim9 is loaded instead.

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

# reload cannon only
var cannon_load = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Standard Air patrol (AIM-9, AIM-120, AIM-7)
var a2a_patrol = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim9WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.aim7);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.aim7);
        pylon8.loadSet(pylonSets.aim120);
        pylon9.loadSet(pylonSets.aim9WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Air Superiority (AIM-120)
var a2a_super = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.aim120);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.aim120);
        pylon8.loadSet(pylonSets.aim120);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podIrst);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# CAP (AIM-9, AIM-120)
var a2a_cap = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim9WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.aim120);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.aim120);
        pylon8.loadSet(pylonSets.aim120);
        pylon9.loadSet(pylonSets.aim9WT);
        pylon10.loadSet(pylonSets.podIrst);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# CAP (Extended loiter)
var a2a_capext = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim9WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.aim120);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.aim120);
        pylon8.loadSet(pylonSets.aim120);
        pylon9.loadSet(pylonSets.aim9WT);
        pylon10.loadSet(pylonSets.podIrst);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# NFZ (AIM-120, AIM-7, AIM-9, ECM)
var a2a_nfz = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.aim7);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.podEcm131);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.aim7);
        pylon8.loadSet(pylonSets.aim9);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podIrst);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# D/CAP (AIM-9, AIM-120)
var a2a_dcap = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9);
        pylon3.loadSet(pylonSets.aim9);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.aim9);
        pylon8.loadSet(pylonSets.aim9);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# CAS (AGM-65, MK-82)
var a2g_cas = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9);
        pylon3.loadSet(pylonSets.a65);
        pylon4.loadSet(pylonSets.m82);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.m82);
        pylon7.loadSet(pylonSets.a65);
        pylon8.loadSet(pylonSets.aim9);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podLTgp);
        pylon11.loadSet(pylonSets.podLNav);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# CAS (Extended loiter)
var a2g_casext = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9);
        pylon3.loadSet(pylonSets.a65x3);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.a65x3);
        pylon8.loadSet(pylonSets.aim9);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podLTgp);
        pylon11.loadSet(pylonSets.podLNav);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# OCA (MK-82, CBU-87)
var a2g_oca = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim9WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.m82);
        pylon4.loadSet(pylonSets.c87);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.c87);
        pylon7.loadSet(pylonSets.m82);
        pylon8.loadSet(pylonSets.aim120);
        pylon9.loadSet(pylonSets.aim9WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G Unguided 1: (MK-82, MK-84)
var a2g_mk1 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim9WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.m82);
        pylon4.loadSet(pylonSets.m84);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.m84);
        pylon7.loadSet(pylonSets.m82);
        pylon8.loadSet(pylonSets.aim120);
        pylon9.loadSet(pylonSets.aim9WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G Unguided 2 (MK-83, MK-84)
var a2g_mk2 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim9WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.m83);
        pylon4.loadSet(pylonSets.m84);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.m84);
        pylon7.loadSet(pylonSets.m83);
        pylon8.loadSet(pylonSets.aim120);
        pylon9.loadSet(pylonSets.aim9WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G CEM (CBU-87)
var a2g_cem = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim9WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.c87);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.c87);
        pylon8.loadSet(pylonSets.aim120);
        pylon9.loadSet(pylonSets.aim9WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G SFW (CBU-105)
var a2g_sfw = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim9WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.c105);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.c105);
        pylon8.loadSet(pylonSets.aim120);
        pylon9.loadSet(pylonSets.aim9WT);
        pylon10.loadSet(pylonSets.podLite);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G Hydra 70 (LAU-68)
var a2g_hyd70 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim9WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.hyd70h3);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.hyd70h7);
        pylon8.loadSet(pylonSets.aim120);
        pylon9.loadSet(pylonSets.aim9WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
        f16.reloadHydras();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G LGB Strike 1 (GBU-12)
var a2g_lgb1 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim9WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.g12x3);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.g12x3);
        pylon8.loadSet(pylonSets.aim120);
        pylon9.loadSet(pylonSets.aim9WT);
        pylon10.loadSet(pylonSets.podLTgp);
        pylon11.loadSet(pylonSets.podLNav);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G LBG Strike 2 (GBU-12, GBU-24)
var a2g_lgb2 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim9WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.g24);
        pylon4.loadSet(pylonSets.g12x2);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.g12x2);
        pylon7.loadSet(pylonSets.g24);
        pylon8.loadSet(pylonSets.aim120);
        pylon9.loadSet(pylonSets.aim9WT);
        pylon10.loadSet(pylonSets.podLTgp);
        pylon11.loadSet(pylonSets.podLNav);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G GPS Strike 1 (GBU-54)
var a2g_gps1 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim9WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.g54);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.g54);
        pylon8.loadSet(pylonSets.aim120);
        pylon9.loadSet(pylonSets.aim9WT);
        pylon10.loadSet(pylonSets.podLite);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G GPS Strike 2 (GBU-54, GBU-31)
var a2g_gps2 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim9WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.g54);
        pylon4.loadSet(pylonSets.g31);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.g31);
        pylon7.loadSet(pylonSets.g54);
        pylon8.loadSet(pylonSets.aim120);
        pylon9.loadSet(pylonSets.aim9WT);
        pylon10.loadSet(pylonSets.podLite);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G GPS Joint Strike (GBU-31, AGM-154A)
var a2g_jgps = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9);
        pylon3.loadSet(pylonSets.g31);
        pylon4.loadSet(pylonSets.a154);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.a154);
        pylon7.loadSet(pylonSets.g31);
        pylon8.loadSet(pylonSets.aim9);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podLite);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/S Anti-Ship (AGM-84, MK-84)
var a2s_antiship = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9);
        pylon3.loadSet(pylonSets.a84);
        pylon4.loadSet(pylonSets.m84);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.m84);
        pylon7.loadSet(pylonSets.a84);
        pylon8.loadSet(pylonSets.aim9);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podLTgp);
        pylon11.loadSet(pylonSets.podLNav);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/S Anti-Ship (AGM-119)
var a2s_antiship2 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9);
        pylon3.loadSet(pylonSets.a119);
        pylon4.loadSet(pylonSets.a119);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.a119);
        pylon7.loadSet(pylonSets.a119);
        pylon8.loadSet(pylonSets.aim9);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podSAtp);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# SEAD "Wild Weasel" (AGM-88, 184 ECM pod)
var a2g_sead = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.a88);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.podEcm184);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.a88);
        pylon8.loadSet(pylonSets.aim9);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podSAtp);
        pylon11.loadSet(pylonSets.podHarm);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# SEAD/DEAD (AGM-65, AGM-88)
var a2g_dead1 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.a65);
        pylon4.loadSet(pylonSets.a88);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.a88);
        pylon7.loadSet(pylonSets.a65);
        pylon8.loadSet(pylonSets.aim9);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podSAtp);
        pylon11.loadSet(pylonSets.podHarm);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# SEAD/DEAD (CBU-87, AGM-88)
var a2g_dead2 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9);
        pylon3.loadSet(pylonSets.a88);
        pylon4.loadSet(pylonSets.c87);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.c87);
        pylon7.loadSet(pylonSets.a88);
        pylon8.loadSet(pylonSets.aim9);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podHarm);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# SEAD ER (AGM-88, AGM-154A)
var a2g_seader = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.a88);
        pylon4.loadSet(pylonSets.a154);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.a154);
        pylon7.loadSet(pylonSets.a88);
        pylon8.loadSet(pylonSets.aim9);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podLite);
        pylon11.loadSet(pylonSets.podHarm);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G Stand-off Strike mode 1 (AGM-154A)
var a2g_jsow = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9);
        pylon3.loadSet(pylonSets.a154);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.podEcm184);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.a154);
        pylon8.loadSet(pylonSets.aim9);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podLite);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G Stand-off Strike mode 2 (AGM-158)
var a2g_jassm = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9);
        pylon3.loadSet(pylonSets.a158);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.a158);
        pylon8.loadSet(pylonSets.aim9);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podSAtp);
        pylon11.loadSet(pylonSets.podHarm);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Counter A2/AD (AGM-84, AGM-88)
var a2g_ca2ad = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9);
        pylon3.loadSet(pylonSets.a84);
        pylon4.loadSet(pylonSets.a88);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.a88);
        pylon7.loadSet(pylonSets.a84);
        pylon8.loadSet(pylonSets.aim120);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podSAtp);
        pylon11.loadSet(pylonSets.podHarm);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Ferry configuration 1 (2x 370gal, 300gal, MXU-648)
var ferrycargo1 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.dumb2);
        pylon2.loadSet(pylonSets.dumb1);
        pylon3.loadSet(pylonSets.podTrvl);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.podTrvl);
        pylon8.loadSet(pylonSets.dumb1);
        pylon9.loadSet(pylonSets.dumb2);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Ferry configuration 2 (2x 600gal, MXU-648)
var ferrycargo2 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.dumb3);
        pylon2.loadSet(pylonSets.dumb1);
        pylon3.loadSet(pylonSets.podTrvl);
        pylon4.loadSet(pylonSets.fuel60L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel60R);
        pylon7.loadSet(pylonSets.podTrvl);
        pylon8.loadSet(pylonSets.dumb1);
        pylon9.loadSet(pylonSets.dumb3);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Peacetime training configuration 1
var train1 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.dumb2);
        pylon2.loadSet(pylonSets.dumb1);
        pylon3.loadSet(pylonSets.empty);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.empty);
        pylon8.loadSet(pylonSets.podACMI);
        pylon9.loadSet(pylonSets.dumb2);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Peacetime training configuration 2
var train2 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.dumb3);
        pylon2.loadSet(pylonSets.podACMI);
        pylon3.loadSet(pylonSets.empty);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.podEcm131);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.empty);
        pylon8.loadSet(pylonSets.dumb1);
        pylon9.loadSet(pylonSets.dumb3);
        pylon10.loadSet(pylonSets.podSAtp);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Airshow configuration (Smokewinder white)
var airshow = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.smokeWL);
        pylon2.loadSet(pylonSets.empty);
        pylon3.loadSet(pylonSets.empty);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.empty);
        pylon8.loadSet(pylonSets.empty);
        pylon9.loadSet(pylonSets.smokeWR);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

var refuel = func {
	if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
		setprop("consumables/fuel/tank[0]/level-norm", 1);
		setprop("consumables/fuel/tank[1]/level-norm", 1);
		if (getprop("consumables/fuel/tank[2]/name") != "Not attached") setprop("consumables/fuel/tank[2]/level-norm", 1);
		if (getprop("consumables/fuel/tank[3]/name") != "Not attached") setprop("consumables/fuel/tank[3]/level-norm", 1);
		if (getprop("consumables/fuel/tank[4]/name") != "Not attached") setprop("consumables/fuel/tank[4]/level-norm", 1);
		setprop("consumables/fuel/tank[5]/level-norm", 1);
		setprop("consumables/fuel/tank[6]/level-norm", 1);
	} else {
      screen.log.write(f16.msgC);
    }
}
# Clean configuration
var clean = func {
    if (fcs != nil and (getprop("payload/armament/msg") == FALSE or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.dumb1);# F16 never has nothing on wingtips unless its fired off, its aerodynamics is designed to work better with something there.
        pylon2.loadSet(pylonSets.empty);
        pylon3.loadSet(pylonSets.empty);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.empty);
        pylon8.loadSet(pylonSets.empty);
        pylon9.loadSet(pylonSets.dumb1);
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
