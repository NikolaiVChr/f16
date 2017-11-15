var pylonSets = {
	empty: {name: "Empty", content: [], fireOrder: [], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0},
	g: {name: "1 x AIM-9", content: ["AIM-9"], fireOrder: [0], launcherDragArea: 0.05, launcherMass: 10, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0},
	h: {name: "1 x AIM-120", content: ["AIM-120"], fireOrder: [0], launcherDragArea: 0.05, launcherMass: 10, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0},
	i: {name: "3 x GBU-12", content: ["GBU-12","GBU-12", "GBU-12"], fireOrder: [0,1,2], launcherDragArea: 0.05, launcherMass: 10, launcherJettisonable: 1, showLongTypeInsteadOfCount: 0},
	j: {name: "2 x GBU-12", content: ["GBU-12", "GBU-12"], fireOrder: [0,1], launcherDragArea: 0.05, launcherMass: 10, launcherJettisonable: 1, showLongTypeInsteadOfCount: 0},
};

# sets
var pylon120set   = [pylonSets.empty, pylonSets.g, pylonSets.h];
var pylon9set = [pylonSets.empty, pylonSets.g];
var pylon9mix = [pylonSets.empty, pylonSets.g,pylonSets.i];
var pylon12set = [pylonSets.empty, pylonSets.j];

# pylons
var pylon1 = stations.Pylon.new("Left Wingtip Pylon", 0, [0,0,0], pylon9set, 0, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[1]",1),props.globals.getNode("alpha/dragareaL",1));
var pylon2 = stations.Pylon.new("Left Outer Wing Pylon", 1, [0,0,0], pylon120set, 1, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[2]",1),props.globals.getNode("alpha/dragareaL",1));
var pylon3 = stations.Pylon.new("Left Wing Pylon", 2, [0,0,0], pylon9mix, 2, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[3]",1),props.globals.getNode("alpha/dragareaL",1));
var pylon4 = stations.Pylon.new("Left Inner Wing Pylon", 3, [0,0,0], pylon12set, 3, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[4]",1),props.globals.getNode("alpha/dragareaL",1));
var pylon5 = stations.Pylon.new("Center Pylon", 4, [0,0,0], [pylonSets.empty], 4, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[5]",1),props.globals.getNode("alpha/dragareaL",1));
var pylon6 = stations.Pylon.new("Left Inner Wing Pylon", 5, [0,0,0], pylon12set, 5, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[6]",1),props.globals.getNode("alpha/dragareaL",1));
var pylon7 = stations.Pylon.new("Left Wing Pylon", 6, [0,0,0], pylon9mix, 6, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[7]",1),props.globals.getNode("alpha/dragareaL",1));
var pylon8 = stations.Pylon.new("Left Outer Wing Pylon", 7, [0,0,0], pylon120set, 7, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[8]",1),props.globals.getNode("alpha/dragareaL",1));
var pylon9 = stations.Pylon.new("Left Wingtip Pylon", 8, [0,0,0], pylon9set, 8, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[9]",1),props.globals.getNode("alpha/dragareaL",1));


# a hacky fire-control system:
var pylons = [pylon1,pylon9,pylon2,pylon8,pylon3,pylon7,pylon4,pylon6];
var starter = func {
	var started = 0;
	foreach(p;pylons) {
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
setlistener("controls/armament/trigger",func{
	if (getprop("controls/armament/trigger") == 1) {
		foreach(p;pylons) {
			var aim = p.fireWeapon(0);
			if (aim == nil) {
				aim = p.fireWeapon(1);
				if (aim == nil) {
					aim = p.fireWeapon(2);
				}
			}
			if (aim != nil) {
				aim.sendMessage(aim.brevity);# non-oprf message
				return;
			}
		}
	}
});
starter();