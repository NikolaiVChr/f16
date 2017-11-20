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

var pylons = [pylon1,pylon2,pylon3,pylon4,pylon5,pylon6,pylon7,pylon8,pylon9,pylonI];
var fcs = fc.FireControl.new(pylons, [9,0,8,1,7,2,6,3,5,4], ["20mm Cannon","AIM-9","AIM-120","GBU-12"]);
print("** Pylon & fire control system started. **");