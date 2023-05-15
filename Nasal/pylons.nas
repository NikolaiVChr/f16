var ARM_SIM = -1;
var ARM_OFF = 0;# these 3 are needed by fire-control.
var ARM_ARM = 1;

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

var block = getprop("/sim/variant-id");
var cannon = stations.SubModelWeapon.new("20mm Cannon", 0.254, 510, [2], [1,3], props.globals.getNode("fdm/jsbsim/fcs/guntrigger",1), 0, func{return getprop("fdm/jsbsim/elec/bus/emergency-dc-2")>=20 and getprop("fdm/jsbsim/elec/bus/emergency-ac-2")>=100 and getprop("fdm/jsbsim/systems/hydraulics/sysb-psi")>=2000 and getprop("payload/armament/fire-control/serviceable") and getprop("controls/armament/master-arm") == 1;},0);
cannon.typeShort = "GUN";
cannon.brevity = "Guns guns";
var hyd70lh3 = stations.SubModelWeapon.new("LAU-68", 23.6, 7, [4], [], props.globals.getNode("fdm/jsbsim/fcs/hydra3ltrigger",1), 1, func{return getprop("payload/armament/fire-control/serviceable") and getprop("controls/armament/master-arm") == 1;},1);
hyd70lh3.typeShort = "M151";
hyd70lh3.brevity = "Rockets away";
var hyd70rh3 = stations.SubModelWeapon.new("LAU-68", 23.6, 7, [5], [], props.globals.getNode("fdm/jsbsim/fcs/hydra3rtrigger",1), 1, func{return getprop("payload/armament/fire-control/serviceable") and getprop("controls/armament/master-arm") == 1;},1);
hyd70rh3.typeShort = "M151";
hyd70rh3.brevity = "Rockets away";
var hyd70lh7 = stations.SubModelWeapon.new("LAU-68", 23.6, 7, [6], [], props.globals.getNode("fdm/jsbsim/fcs/hydra7ltrigger",1), 1, func{return getprop("payload/armament/fire-control/serviceable") and getprop("controls/armament/master-arm") == 1;},1);
hyd70lh7.typeShort = "M151";
hyd70lh7.brevity = "Rockets away";
var hyd70rh7 = stations.SubModelWeapon.new("LAU-68", 23.6, 7, [7], [], props.globals.getNode("fdm/jsbsim/fcs/hydra7rtrigger",1), 1, func{return getprop("payload/armament/fire-control/serviceable") and getprop("controls/armament/master-arm") == 1;},1);
hyd70rh7.typeShort = "M151";
hyd70rh7.brevity = "Rockets away";
var fuelTankCFT = nil;
if (getprop("sim/variant-id")>=5) {
	fuelTankCFT = stations.FuelTank.new("Conformant Fuel Tanks", "CFT450", 9, 450, "sim/model/f16/cft-tanks-3d");
	fuelTankCFT.del();
}
var fuelTankCenter = stations.FuelTank.new("Center 300 Gal Tank", "TK300", 8, 300, "sim/model/f16/ventraltank");
var fuelTank370Left = stations.FuelTank.new("Left 370 Gal Tank", "TK370", 6, 370, "sim/model/f16/wingtankL");
var fuelTank370Right = stations.FuelTank.new("Right 370 Gal Tank", "TK370", 7, 370, "sim/model/f16/wingtankR");
var fuelTank600Left = stations.FuelTank.new("Left 600 Gal Tank", "TK600", 6, 600, "sim/model/f16/wingtankL6");
var fuelTank600Right = stations.FuelTank.new("Right 600 Gal Tank", "TK600", 7, 600, "sim/model/f16/wingtankR6");
var smokewinderRed1 = stations.Submodel.new("Smokewinder Red", "SMOKE-R", "sim/model/f16/smokewinderR1");
var smokewinderGreen1 = stations.Submodel.new("Smokewinder Green", "SMOKE-G", "sim/model/f16/smokewinderG1");
var smokewinderBlue1 = stations.Submodel.new("Smokewinder Blue", "SMOKE-B", "sim/model/f16/smokewinderB1");
var smokewinderRed9 = stations.Submodel.new("Smokewinder Red", "SMOKE-R", "sim/model/f16/smokewinderR9");
var smokewinderGreen9 = stations.Submodel.new("Smokewinder Green", "SMOKE-G", "sim/model/f16/smokewinderG9");
var smokewinderBlue9 = stations.Submodel.new("Smokewinder Blue", "SMOKE-B", "sim/model/f16/smokewinderB9");
var smokewinderWhite1 = stations.Submodel.new("Smokewinder White", "SMOKE-W", "sim/model/f16/smokewinderW1");
var smokewinderWhite9 = stations.Submodel.new("Smokewinder White", "SMOKE-W", "sim/model/f16/smokewinderW9");
var atp = stations.Submodel.new("AN/AAQ-33 Sniper ATP", "AAQ-33", "f16/stores/tgp-mounted");
var ifts = stations.Submodel.new("AN/AAQ-32 Internal FLIR Targeting System", "AAQ-32", "f16/stores/tgp-mounted");
var tgp = stations.Submodel.new("AN/AAQ-14 LANTIRN Target Pod", "AAQ-14", "f16/stores/tgp-mounted");
var nav = stations.Submodel.new("AN/AAQ-13 LANTIRN Nav Pod", "AAQ-13", "f16/stores/nav-mounted");
var lite = stations.Submodel.new("AN/AAQ-28 LITENING Advanced Targeting", "AAQ-28", "f16/stores/tgp-mounted");
var irst = stations.Submodel.new("Legion Pod (IRST)", "IRST", "f16/stores/irst-mounted");
var harm = stations.Submodel.new("AN/ASQ-213 HARM TS Pod", "ASQ-213", "f16/stores/harm-mounted");
var acmi = stations.Submodel.new("AN/ASQ-T50(V)2 ACMI Pod", "ACMI", "f16/stores/acmi-mounted");
var ecm131 = stations.Submodel.new("AN/ALQ-131(V) ECM Pod", "AL131", "f16/stores/ecm-mounted");
var ecm184 = stations.Submodel.new("AN/ALQ-184(V) ECM Pod", "AL184", "f16/stores/ecm-mounted");
var ecm188 = stations.Submodel.new("AN/ALQ-188(V) EAT Pod", "AL188", "f16/stores/ecm-mounted");
var catm9 = stations.Dummy.new("CATM-9L", "CATM");
var ant17 = stations.Dummy.new("AN-T-17", nil);# nil for shortname makes them not show up in MFD SMS page. If shortname is nil it MUST have showLongTypeInsteadOfCount: 1
var catm120 = stations.Dummy.new("CATM-120B", "CATM");
var crgpd = stations.Dummy.new("MXU-648 Cargopod", "TRVL");

# LAU-68 will be converted to LAU-131 which is USAF std.

#
# Dragarea for launchers
#
# AIM-9WT should be -0.07865    (to cancel out the dragarea from missile-code, since F-16 aero has that included)
# AIM-120WT should be -0.08217  (to cancel out the dragarea from missile-code, since F-16 aero has that included)
# dummy AIM-9WT should be 0     (F-16 aero has that already included)
# dummy AIM-120WT should be 0   (F-16 aero has that already included)
#
# No other dragareas should be negative or zero!
# Except for the wingtips, dragarea for weapons (missile-code) is for launcher and rack only.
# Except for the wingtips, dragarea for non-weapons is for launcher, rack and the non-weapon.
#
# To give an idea of dragarea numbers:
#
# A/A missile:     0.05 to 0.10  (small and okay good aero shape)
# Clean aircraft: 14.67          (big and somewhat good aerodynamic shape)
# MK-84:           0.224         (medium size and very good aerodynamic shape)
#
var pylonSets = {
    empty:     {name: "Empty", pylon: nil, rack: nil, content: [], fireOrder: [], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},
    mau:       {name: "--------", pylon: "1 MAU", rack: nil, content: [], fireOrder: [], launcherDragArea: 0.05, launcherMass: 220, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},
    mm20:      {name: "20mm Cannon", content: [cannon], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    hyd70h3:   {name: "2 x M151", pylon: "1 MAU", rack: "2 L68", content: [hyd70lh3,hyd70rh3], fireOrder: [0,1], launcherDragArea: 0.14, launcherMass: 625.0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    hyd70h7:   {name: "2 x M151", pylon: "1 MAU", rack: "2 L68", content: [hyd70lh7,hyd70rh7], fireOrder: [0,1], launcherDragArea: 0.14, launcherMass: 625.0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    a65b:      {name: "3 x AGM-65B", pylon: "1 MAU", rack: "1 L88", content: ["AGM-65B", "AGM-65B", "AGM-65B"], fireOrder: [0,1,2], launcherDragArea: 0.075, launcherMass: 689, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    a65d:      {name: "1 x AGM-65D", pylon: "1 MAU", rack: "1 L117", content: ["AGM-65D"], fireOrder: [0], launcherDragArea: 0.06, launcherMass: 345, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    a84:       {name: "1 x AGM-84", pylon: "1 MAU", rack: nil, content: ["AGM-84"], fireOrder: [0], launcherDragArea: 0.05, launcherMass: 220, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    a88:       {name: "1 x AGM-88", pylon: "1 MAU", rack: "1 L118", content: ["AGM-88"], fireOrder: [0], launcherDragArea: 0.06, launcherMass: 340, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    a119:      {name: "1 x AGM-119", pylon: "1 MAU", rack: "1 BR14", content: ["AGM-119"], fireOrder: [0], launcherDragArea: 0.06, launcherMass: 234, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    a158:      {name: "1 x AGM-158", pylon: "1 MAU", rack: nil, content: ["AGM-158"], fireOrder: [0], launcherDragArea: 0.05, launcherMass: 220, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    a154:      {name: "1 x AGM-154A", pylon: "1 MAU", rack: nil, content: ["AGM-154A"], fireOrder: [0], launcherDragArea: 0.05, launcherMass: 200, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    b617:      {name: "1 x B61-7", pylon: "1 MAU", rack: nil, content: ["B61-7"], fireOrder: [0], launcherDragArea: 0.05, launcherMass:220, launcherJettisonable: 0, weaponJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    b6112:     {name: "1 x B61-12", pylon: "1 MAU", rack: nil, content: ["B61-12"], fireOrder: [0], launcherDragArea: 0.05, launcherMass: 220, launcherJettisonable: 0, weaponJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    g54x2:     {name: "2 x GBU-54", pylon: "1 MAU", rack: "1 BR57", content: ["GBU-54","GBU-54"], fireOrder: [0,1], launcherDragArea: 0.075, launcherMass: 470, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    g54:       {name: "1 x GBU-54", pylon: "1 MAU", rack: nil, content: ["GBU-54"], fireOrder: [0], launcherDragArea: 0.05, launcherMass: 220, launcherJettisonable: 1, showLongTypeInsteadOfCount: 0, category: 3},
    g31:       {name: "1 x GBU-31", pylon: "1 MAU", rack: nil, content: ["GBU-31"], fireOrder: [0], launcherDragArea: 0.05, launcherMass: 220, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    g24:       {name: "1 x GBU-24", pylon: "1 MAU", rack: nil, content: ["GBU-24"], fireOrder: [0], launcherDragArea: 0.05, launcherMass: 220, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    g12x3:     {name: "3 x GBU-12", pylon: "1 MAU", rack: "1 TER", content: ["GBU-12","GBU-12", "GBU-12"], fireOrder: [0,1,2], launcherDragArea: 0.075, launcherMass: 313, launcherJettisonable: 1, showLongTypeInsteadOfCount: 0, category: 3},
    g12x2:     {name: "2 x GBU-12", pylon: "1 MAU", rack: "1 TER", content: ["GBU-12", "GBU-12"], fireOrder: [0,1], launcherDragArea: 0.075, launcherMass: 313, launcherJettisonable: 1, showLongTypeInsteadOfCount: 0, category: 3},
    g12:       {name: "1 x GBU-12", pylon: "1 MAU", rack: nil, content: ["GBU-12"], fireOrder: [0], launcherDragArea: 0.05, launcherMass: 220, launcherJettisonable: 1, showLongTypeInsteadOfCount: 0, category: 3},
    m82:       {name: "3 x MK-82", pylon: "1 MAU", rack: "1 TER", content: ["MK-82","MK-82","MK-82"], fireOrder: [0,1,2], launcherDragArea: 0.075, launcherMass: 313, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    m82x1:     {name: "1 x MK-82", pylon: "1 MAU", rack: nil, content: ["MK-82"], fireOrder: [0], launcherDragArea: 0.05, launcherMass: 220, launcherJettisonable: 1, showLongTypeInsteadOfCount: 0, category: 3},
    m82air:    {name: "3 x MK-82AIR", pylon: "1 MAU", rack: "1 TER", content: ["MK-82AIR","MK-82AIR","MK-82AIR"], fireOrder: [0,1,2], launcherDragArea: 0.075, launcherMass: 313, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    m84:       {name: "1 x MK-84", pylon: "1 MAU", rack: nil, content: ["MK-84"], fireOrder: [0], launcherDragArea: 0.05, launcherMass: 220, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    m83:       {name: "2 x MK-83",  pylon: "1 MAU", rack: "1 BR57", content: ["MK-83","MK-83"], fireOrder: [0,1], launcherDragArea: 0.075, launcherMass: 470, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    c87:       {name: "2 x CBU-87", pylon: "1 MAU", rack: "1 TER", content: ["CBU-87","CBU-87"], fireOrder: [0,1], launcherDragArea: 0.075, launcherMass: 313, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    c105:      {name: "1 x CBU-105", pylon: "1 MAU", rack: nil, content: ["CBU-105"], fireOrder: [0], launcherDragArea: 0.05, launcherMass: 220, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    c105x2:    {name: "2 x CBU-105", pylon: "1 MAU", rack: "1 BR57", content: ["CBU-105","CBU-105"], fireOrder: [0,1], launcherDragArea: 0.075, launcherMass: 470, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    dumb1:     {name: "CATM-9L", pylon: "1 MRL", content: [catm9], fireOrder: [], launcherDragArea: 0.07865, launcherMass: 275, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    dumb1WT:   {name: "CATM-9L", pylon: "1 MRLW", content: [catm9], fireOrder: [], launcherDragArea: 0, launcherMass: 275, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    dumb2:     {name: "AN-T-17", pylon: "1 MRL", rack: nil, content: [ant17], fireOrder: [], launcherDragArea: 0.07865, launcherMass: 275, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    dumb2WT:   {name: "AN-T-17", pylon: "1 MRLW", rack: nil, content: [ant17], fireOrder: [], launcherDragArea: 0, launcherMass: 275, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    dumb3WT:   {name: "CATM-120B", pylon: "1 MRLW", content: [catm120], fireOrder: [], launcherDragArea: 0, launcherMass: 380, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    smokeRL:   {name: "Smokewinder Red", pylon: "1 MRLW", content: [smokewinderRed1], fireOrder: [0], launcherDragArea: 0, launcherMass: 293, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    smokeGL:   {name: "Smokewinder Green", pylon: "1 MRLW", content: [smokewinderGreen1], fireOrder: [0], launcherDragArea: 0, launcherMass: 293, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    smokeBL:   {name: "Smokewinder Blue", pylon: "1 MRLW", content: [smokewinderBlue1], fireOrder: [0], launcherDragArea: 0, launcherMass: 293, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    smokeRR:   {name: "Smokewinder Red", pylon: "1 MRLW", content: [smokewinderRed9], fireOrder: [0], launcherDragArea: 0, launcherMass: 293, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    smokeGR:   {name: "Smokewinder Green", pylon: "1 MRLW", content: [smokewinderGreen9], fireOrder: [0], launcherDragArea: 0, launcherMass: 293, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    smokeBR:   {name: "Smokewinder Blue", pylon: "1 MRLW", content: [smokewinderBlue9], fireOrder: [0], launcherDragArea: 0, launcherMass: 293, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    smokeWL:   {name: "Smokewinder White", pylon: "1 MRLW",  content: [smokewinderWhite1], fireOrder: [0], launcherDragArea: 0, launcherMass: 293, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    smokeWR:   {name: "Smokewinder White", pylon: "1 MRLW", content: [smokewinderWhite9], fireOrder: [0], launcherDragArea: 0, launcherMass: 293, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    fuel30:    {name: fuelTankCenter.type, pylon: "1 MAU", rack: nil, content: [fuelTankCenter], fireOrder: [0], launcherDragArea: 0.50, launcherMass: 462, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1, category: 1},
    fuel37L:   {name: fuelTank370Left.type, pylon: "1 MAU", rack: nil, content: [fuelTank370Left], fireOrder: [0], launcherDragArea: 0.70, launcherMass: 751, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1, category: 2},
    fuel37R:   {name: fuelTank370Right.type, pylon: "1 MAU", rack: nil, content: [fuelTank370Right], fireOrder: [0], launcherDragArea: 0.70, launcherMass: 751, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1, category: 2},
    fuel60L:   {name: fuelTank600Left.type, pylon: "1 MAU", rack: nil, content: [fuelTank600Left], fireOrder: [0], launcherDragArea: 1.00, launcherMass: 675, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 3},
    fuel60R:   {name: fuelTank600Right.type, pylon: "1 MAU", rack: nil, content: [fuelTank600Right], fireOrder: [0], launcherDragArea: 1.00, launcherMass: 675, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 3},
    aim9lWT:   {name: "1 x AIM-9L", pylon: "1 MRLW", content: ["AIM-9L"], fireOrder: [0], launcherDragArea: -0.07865, launcherMass: 90, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},#wingtip
    aim9mWT:   {name: "1 x AIM-9M", pylon: "1 MRLW", content: ["AIM-9M"], fireOrder: [0], launcherDragArea: -0.07865, launcherMass: 90, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},#wingtip
    aim9xWT:   {name: "1 x AIM-9X", pylon: "1 MRLW", content: ["AIM-9X"], fireOrder: [0], launcherDragArea: -0.07865, launcherMass: 90, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},#wingtip
    aim9l:     {name: "1 x AIM-9L", pylon: "1 MRL", content: ["AIM-9L"], fireOrder: [0], launcherDragArea: 0.025, launcherMass: 90, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},#non wingtip
    aim9m:     {name: "1 x AIM-9M", pylon: "1 MRL", content: ["AIM-9M"], fireOrder: [0], launcherDragArea: 0.025, launcherMass: 90, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},#non wingtip
    aim9x:     {name: "1 x AIM-9X", pylon: "1 MRL", content: ["AIM-9X"], fireOrder: [0], launcherDragArea: 0.025, launcherMass: 90, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},#non wingtip
    aim120:    {name: "1 x AIM-120", pylon: "1 MRL", content: ["AIM-120"], fireOrder: [0], launcherDragArea: 0.025, launcherMass: 90, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},#non wingtip
    aim120WT:  {name: "1 x AIM-120", pylon: "1 MRLW", content: ["AIM-120"], fireOrder: [0], launcherDragArea: -0.08217, launcherMass: 90, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},#wingtip
    aim7:      {name: "1 x AIM-7", pylon: "1 LNCH", content: ["AIM-7"], fireOrder: [0], launcherDragArea: 0.025, launcherMass: 52, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},#Real launcher: 16S1501
    podEcm131: {name: "AN/ALQ-131(V) ECM Pod", pylon: "1 MAU", rack: nil, content: [ecm131], fireOrder: [0], launcherDragArea: 0.16, launcherMass: 480, launcherJettisonable: 0, weaponJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 2},
    podEcm184: {name: "AN/ALQ-184(V) ECM Pod", pylon: "1 MAU", rack: nil, content: [ecm184], fireOrder: [0], launcherDragArea: 0.1, launcherMass: 705, launcherJettisonable: 0, weaponJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 2},
    podEcm188: {name: "AN/ALQ-188(V) EAT Pod", pylon: "1 MAU", rack: nil, content: [ecm188], fireOrder: [0], launcherDragArea: 0.08, launcherMass: 355, launcherJettisonable: 0, weaponJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 2},
    podTrvl:   {name: "MXU-648 Cargopod", pylon: "1 MAU", rack: nil, content: [crgpd], fireOrder: [], launcherDragArea: 0.20, launcherMass: 324, launcherJettisonable: 1, weaponJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 2},
    podSAtp:   {name: "AN/AAQ-33 Sniper ATP", content: [atp], fireOrder: [0], launcherDragArea: 0.06, launcherMass: 446, launcherJettisonable: 0, weaponJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    podSifts:  {name: "AN/AAQ-32 Internal FLIR Targeting System", content: [ifts], fireOrder: [0], launcherDragArea: 0.06, launcherMass: 0, launcherJettisonable: 0, weaponJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    podLTgp:   {name: "AN/AAQ-14 LANTIRN Target Pod", content: [tgp], fireOrder: [0], launcherDragArea: 0.07, launcherMass: 530, launcherJettisonable: 0, weaponJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    podLNav:   {name: "AN/AAQ-13 LANTIRN Nav Pod", content: [nav], fireOrder: [0], launcherDragArea: 0.1, launcherMass: 451.1, launcherJettisonable: 0, weaponJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    podLite:   {name: "AN/AAQ-28 LITENING Advanced Targeting", content: [lite], fireOrder: [0], launcherDragArea: 0.08, launcherMass: 460, launcherJettisonable: 0, weaponJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    podIrst:   {name: "Legion Pod (IRST)", content: [irst], fireOrder: [0], launcherDragArea: 0.08, launcherMass: 500, launcherJettisonable: 0, weaponJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1}, #mass guess based on available data
    podHarm:   {name: "AN/ASQ-213 HARM TS Pod", content: [harm], fireOrder: [0], launcherDragArea: 0.03, launcherMass: 100, launcherJettisonable: 0, weaponJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    podACMI:   {name: "AN/ASQ-T50(V)2 ACMI Pod", pylon: "1 MRL", content: [acmi], fireOrder: [0], launcherDragArea: 0.025, launcherMass: 234, launcherJettisonable: 0, weaponJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    podACMIWT: {name: "AN/ASQ-T50(V)2 ACMI Pod", pylon: "1 MRLW", content: [acmi], fireOrder: [0], launcherDragArea: 0, launcherMass: 234, launcherJettisonable: 0, weaponJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
};

if (getprop("sim/variant-id")>=5) {
	pylonSets.cft450 = {name: fuelTankCFT.type, pylon: "Hardmount", rack: nil, content: [fuelTankCFT], fireOrder: [0], launcherDragArea: 0.40, launcherMass: 486, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1};
}

if (getprop("sim/model/f16/wingmounts") != 0) {
	# all variants except YF-16 get store options:

	# source for fuel tanks content, fuel type, jettisonable and drag: TO. GR1F-16CJ-1-1

	# sets. The first in the list is the default. Earlier in the list means higher up in dropdown menu.
	var pylon2set = nil;
	var pylon8set = nil;
	var pylon1set = nil;
	var pylon9set = nil;
	var pylon3set = nil;
	var pylon7set = nil;
	var pylon4set = nil;
	var pylon6set = nil;
	var pylon5set = nil;
	var fuselageRset = nil;
	var fuselageLset = nil;
	var pylonCFT = nil;

	# HTS can be carried on both left and right side.
	# Sniper, LITENING, IRST only on right

	if (block == 1) {
		pylon2set = [pylonSets.empty, pylonSets.aim9l, pylonSets.dumb1, pylonSets.podACMI];
		pylon8set = [pylonSets.empty, pylonSets.aim9l, pylonSets.dumb1, pylonSets.podACMI];
		pylon1set = [pylonSets.dumb1WT, pylonSets.dumb2WT, pylonSets.aim9lWT, pylonSets.podACMIWT, pylonSets.smokeRL, pylonSets.smokeGL, pylonSets.smokeBL, pylonSets.smokeWL];# wingtips are normally not empty, so CATM-9L dummy is loaded instead.
		pylon9set = [pylonSets.dumb1WT, pylonSets.dumb2WT, pylonSets.aim9lWT, pylonSets.podACMIWT, pylonSets.smokeRR, pylonSets.smokeGR, pylonSets.smokeBR, pylonSets.smokeWR];# wingtips are normally not empty, so CATM-9L dummy is loaded instead.
		pylon3set = [pylonSets.empty, pylonSets.m84, pylonSets.m82air, pylonSets.m82, pylonSets.m82x1, pylonSets.aim9l];
		pylon7set = [pylonSets.empty, pylonSets.m84, pylonSets.m82air, pylonSets.m82, pylonSets.m82x1, pylonSets.aim9l];
		pylon4set = [pylonSets.empty, pylonSets.m82air, pylonSets.m82, pylonSets.m82x1, pylonSets.m84, pylonSets.fuel60L, pylonSets.fuel37L];
		pylon6set = [pylonSets.empty, pylonSets.m82air, pylonSets.m82, pylonSets.m82x1, pylonSets.m84, pylonSets.fuel60R, pylonSets.fuel37R];
		pylon5set = [pylonSets.empty, pylonSets.podTrvl, pylonSets.podEcm131, pylonSets.fuel30];

		fuselageRset = [pylonSets.empty];
		fuselageLset = [pylonSets.empty];

	} elsif (block == 2) {
		pylon2set = [pylonSets.empty, pylonSets.aim9l, pylonSets.aim9m, pylonSets.aim9x, pylonSets.aim120, pylonSets.dumb1, pylonSets.podACMI];
		pylon8set = [pylonSets.empty, pylonSets.aim9l, pylonSets.aim9m, pylonSets.aim9x, pylonSets.aim120, pylonSets.dumb1, pylonSets.podACMI];
		pylon1set = [pylonSets.dumb1WT, pylonSets.dumb2WT ,pylonSets.dumb3WT, pylonSets.aim9lWT, pylonSets.aim9mWT, pylonSets.aim9xWT, pylonSets.aim120WT, pylonSets.podACMIWT, pylonSets.smokeRL, pylonSets.smokeGL, pylonSets.smokeBL, pylonSets.smokeWL];# wingtips are normally not empty, so CATM-9L dummy is loaded instead.
		pylon9set = [pylonSets.dumb1WT, pylonSets.dumb2WT, pylonSets.dumb3WT, pylonSets.aim9lWT, pylonSets.aim9mWT, pylonSets.aim9xWT, pylonSets.aim120WT, pylonSets.podACMIWT, pylonSets.smokeRR, pylonSets.smokeGR, pylonSets.smokeBR, pylonSets.smokeWR];# wingtips are normally not empty, so CATM-9L dummy is loaded instead.
		pylon3set = [pylonSets.empty, pylonSets.hyd70h3, pylonSets.a154, pylonSets.a119, pylonSets.a88, pylonSets.a84, pylonSets.a65b, pylonSets.a65d, pylonSets.c87, pylonSets.c105, pylonSets.g31, pylonSets.g24, pylonSets.g12, pylonSets.m84, pylonSets.m82air, pylonSets.m82, pylonSets.m82x1, pylonSets.aim7, pylonSets.aim9l, pylonSets.aim9m, pylonSets.aim9x, pylonSets.aim120];
		pylon7set = [pylonSets.empty, pylonSets.hyd70h7, pylonSets.a154, pylonSets.a119, pylonSets.a88, pylonSets.a84, pylonSets.a65b, pylonSets.a65d, pylonSets.c87, pylonSets.c105, pylonSets.g31, pylonSets.g24, pylonSets.g12, pylonSets.m84, pylonSets.m82air, pylonSets.m82, pylonSets.m82x1, pylonSets.aim7, pylonSets.aim9l, pylonSets.aim9m, pylonSets.aim9x, pylonSets.aim120];
		pylon4set = [pylonSets.empty, pylonSets.g12x3, pylonSets.m82air, pylonSets.m82, pylonSets.m82x1, pylonSets.a154, pylonSets.a119, pylonSets.g31, pylonSets.g24, pylonSets.c87, pylonSets.c105, pylonSets.m84, pylonSets.fuel60L, pylonSets.fuel37L];
		pylon6set = [pylonSets.empty, pylonSets.g12x3, pylonSets.m82air, pylonSets.m82, pylonSets.m82x1, pylonSets.a154, pylonSets.a119, pylonSets.g31, pylonSets.g24, pylonSets.c87, pylonSets.c105, pylonSets.m84, pylonSets.fuel60R, pylonSets.fuel37R];
		pylon5set = [pylonSets.empty, pylonSets.b617, pylonSets.podTrvl, pylonSets.podEcm184, pylonSets.podEcm131, pylonSets.fuel30];

		fuselageRset = [pylonSets.empty, pylonSets.podHarm, pylonSets.podSAtp, pylonSets.podLite, pylonSets.podLTgp];
		fuselageLset = [pylonSets.empty, pylonSets.podHarm, pylonSets.podLNav];

	} elsif (block == 3) {
		pylon2set = [pylonSets.empty, pylonSets.aim9l, pylonSets.aim9m, pylonSets.aim120, pylonSets.dumb1, pylonSets.podACMI];
		pylon8set = [pylonSets.empty, pylonSets.aim9l, pylonSets.aim9m, pylonSets.aim120, pylonSets.dumb1, pylonSets.podACMI];
		pylon1set = [pylonSets.dumb1WT, pylonSets.dumb2WT, pylonSets.dumb3WT, pylonSets.aim9lWT, pylonSets.aim9mWT, pylonSets.aim120WT, pylonSets.podACMIWT, pylonSets.smokeRL, pylonSets.smokeGL, pylonSets.smokeBL, pylonSets.smokeWL];# wingtips are normally not empty, so CATM-9L dummy is loaded instead.
		pylon9set = [pylonSets.dumb1WT, pylonSets.dumb2WT, pylonSets.dumb3WT, pylonSets.aim9lWT, pylonSets.aim9mWT, pylonSets.aim120WT, pylonSets.podACMIWT, pylonSets.smokeRR, pylonSets.smokeGR, pylonSets.smokeBR, pylonSets.smokeWR];# wingtips are normally not empty, so CATM-9L dummy is loaded instead.
		pylon3set = [pylonSets.empty, pylonSets.podEcm188, pylonSets.hyd70h3, pylonSets.a88, pylonSets.a84, pylonSets.a65b, pylonSets.a65d, pylonSets.c87, pylonSets.g12x2, pylonSets.m84, pylonSets.m82air, pylonSets.m82, pylonSets.m82x1, pylonSets.aim7, pylonSets.aim9l, pylonSets.aim9m, pylonSets.aim120];
		pylon7set = [pylonSets.empty, pylonSets.podEcm188, pylonSets.hyd70h7, pylonSets.a88, pylonSets.a84, pylonSets.a65b, pylonSets.a65d, pylonSets.c87, pylonSets.g12x2, pylonSets.m84, pylonSets.m82air, pylonSets.m82, pylonSets.m82x1, pylonSets.aim7, pylonSets.aim9l, pylonSets.aim9m, pylonSets.aim120];
		pylon4set = [pylonSets.empty, pylonSets.g12x3, pylonSets.m82air, pylonSets.m82, pylonSets.m82x1, pylonSets.c87, pylonSets.m84, pylonSets.fuel60L, pylonSets.fuel37L];
		pylon6set = [pylonSets.empty, pylonSets.g12x3, pylonSets.m82air, pylonSets.m82, pylonSets.m82x1, pylonSets.c87, pylonSets.m84, pylonSets.fuel60R, pylonSets.fuel37R];
		pylon5set = [pylonSets.empty, pylonSets.b617, pylonSets.podTrvl, pylonSets.podEcm188, pylonSets.podEcm131, pylonSets.fuel30];

		fuselageRset = [pylonSets.empty, pylonSets.podLTgp];
		fuselageLset = [pylonSets.empty, pylonSets.podLNav];

	} elsif (block == 4) {
		pylon2set = [pylonSets.empty, pylonSets.aim9l, pylonSets.aim9m, pylonSets.aim9x, pylonSets.aim120, pylonSets.dumb1, pylonSets.podACMI];
		pylon8set = [pylonSets.empty, pylonSets.aim9l, pylonSets.aim9m, pylonSets.aim9x, pylonSets.aim120, pylonSets.dumb1, pylonSets.podACMI];
		pylon1set = [pylonSets.dumb1WT, pylonSets.dumb2WT, pylonSets.dumb3WT, pylonSets.aim9lWT, pylonSets.aim9mWT, pylonSets.aim9xWT, pylonSets.aim120WT, pylonSets.podACMIWT, pylonSets.smokeRL, pylonSets.smokeGL, pylonSets.smokeBL, pylonSets.smokeWL];# wingtips are normally not empty, so CATM-9L dummy is loaded instead.
		pylon9set = [pylonSets.dumb1WT, pylonSets.dumb2WT, pylonSets.dumb3WT, pylonSets.aim9lWT, pylonSets.aim9mWT, pylonSets.aim9xWT, pylonSets.aim120WT, pylonSets.podACMIWT, pylonSets.smokeRR, pylonSets.smokeGR, pylonSets.smokeBR, pylonSets.smokeWR];# wingtips are normally not empty, so CATM-9L dummy is loaded instead.
		pylon3set = [pylonSets.empty, pylonSets.hyd70h3, pylonSets.a158, pylonSets.a154, pylonSets.a88, pylonSets.a84, pylonSets.a65b, pylonSets.a65d, pylonSets.c87, pylonSets.c105, pylonSets.g54x2, pylonSets.g54, pylonSets.g31, pylonSets.g24, pylonSets.g12x2, pylonSets.m84, pylonSets.m82air, pylonSets.m82, pylonSets.m82x1, pylonSets.aim7, pylonSets.aim9l, pylonSets.aim9m, pylonSets.aim9x, pylonSets.aim120];
		pylon7set = [pylonSets.empty, pylonSets.hyd70h7, pylonSets.a158, pylonSets.a154, pylonSets.a88, pylonSets.a84, pylonSets.a65b, pylonSets.a65d, pylonSets.c87, pylonSets.c105, pylonSets.g54x2, pylonSets.g54, pylonSets.g31, pylonSets.g24, pylonSets.g12x2, pylonSets.m84, pylonSets.m82air, pylonSets.m82, pylonSets.m82x1, pylonSets.aim7, pylonSets.aim9l, pylonSets.aim9m, pylonSets.aim9x, pylonSets.aim120];
		pylon4set = [pylonSets.empty, pylonSets.g12x3, pylonSets.m82air, pylonSets.m82, pylonSets.m82x1, pylonSets.a154, pylonSets.g54x2, pylonSets.g31, pylonSets.g24, pylonSets.c87, pylonSets.c105, pylonSets.m84, pylonSets.fuel60L, pylonSets.fuel37L];
		pylon6set = [pylonSets.empty, pylonSets.g12x3, pylonSets.m82air, pylonSets.m82, pylonSets.m82x1, pylonSets.a154, pylonSets.g54x2, pylonSets.g31, pylonSets.g24, pylonSets.c87, pylonSets.c105, pylonSets.m84, pylonSets.fuel60R, pylonSets.fuel37R];
		pylon5set = [pylonSets.empty, pylonSets.b6112, pylonSets.b617, pylonSets.podTrvl, pylonSets.podEcm188, pylonSets.podEcm184, pylonSets.podEcm131, pylonSets.fuel30];

		fuselageRset = [pylonSets.empty, pylonSets.podIrst, pylonSets.podHarm, pylonSets.podSAtp, pylonSets.podLite, pylonSets.podLTgp];
        fuselageLset = [pylonSets.empty, pylonSets.podHarm, pylonSets.podLNav];

	} elsif (block == 5) {
		pylon2set = [pylonSets.empty, pylonSets.aim9l, pylonSets.aim9m, pylonSets.aim9x, pylonSets.aim120, pylonSets.dumb1, pylonSets.podACMI];
		pylon8set = [pylonSets.empty, pylonSets.aim9l, pylonSets.aim9m, pylonSets.aim9x, pylonSets.aim120, pylonSets.dumb1, pylonSets.podACMI];
		pylon1set = [pylonSets.dumb1WT, pylonSets.dumb2WT, pylonSets.dumb3WT, pylonSets.aim9lWT, pylonSets.aim9mWT, pylonSets.aim9xWT, pylonSets.aim120WT, pylonSets.podACMIWT, pylonSets.smokeRL, pylonSets.smokeGL, pylonSets.smokeBL, pylonSets.smokeWL];# wingtips are normally not empty, so CATM-9L dummy is loaded instead.
		pylon9set = [pylonSets.dumb1WT, pylonSets.dumb2WT, pylonSets.dumb3WT, pylonSets.aim9lWT, pylonSets.aim9mWT, pylonSets.aim9xWT, pylonSets.aim120WT, pylonSets.podACMIWT, pylonSets.smokeRR, pylonSets.smokeGR, pylonSets.smokeBR, pylonSets.smokeWR];# wingtips are normally not empty, so CATM-9L dummy is loaded instead.
		pylon3set = [pylonSets.empty, pylonSets.hyd70h3, pylonSets.a158, pylonSets.a154, pylonSets.a88, pylonSets.a84, pylonSets.a65b, pylonSets.a65d, pylonSets.c87, pylonSets.c105, pylonSets.g54x2, pylonSets.g54, pylonSets.g31, pylonSets.g24, pylonSets.g12x2, pylonSets.m84, pylonSets.m82air, pylonSets.m82, pylonSets.m82x1, pylonSets.aim7, pylonSets.aim9l, pylonSets.aim9m, pylonSets.aim9x, pylonSets.aim120];
		pylon7set = [pylonSets.empty, pylonSets.hyd70h7, pylonSets.a158, pylonSets.a154, pylonSets.a88, pylonSets.a84, pylonSets.a65b, pylonSets.a65d, pylonSets.c87, pylonSets.c105, pylonSets.g54x2, pylonSets.g54, pylonSets.g31, pylonSets.g24, pylonSets.g12x2, pylonSets.m84, pylonSets.m82air, pylonSets.m82, pylonSets.m82x1, pylonSets.aim7, pylonSets.aim9l, pylonSets.aim9m, pylonSets.aim9x, pylonSets.aim120];
		pylon4set = [pylonSets.empty, pylonSets.g12x3, pylonSets.m82air, pylonSets.m82, pylonSets.m82x1, pylonSets.a154, pylonSets.g54x2, pylonSets.g31, pylonSets.g24, pylonSets.c87, pylonSets.c105, pylonSets.m84, pylonSets.fuel60L, pylonSets.fuel37L];
		pylon6set = [pylonSets.empty, pylonSets.g12x3, pylonSets.m82air, pylonSets.m82, pylonSets.m82x1, pylonSets.a154, pylonSets.g54x2, pylonSets.g31, pylonSets.g24, pylonSets.c87, pylonSets.c105, pylonSets.m84, pylonSets.fuel60R, pylonSets.fuel37R];
		pylon5set = [pylonSets.empty, pylonSets.b6112, pylonSets.b617, pylonSets.podTrvl, pylonSets.podEcm188, pylonSets.podEcm184, pylonSets.podEcm131, pylonSets.fuel30];

		fuselageRset = [pylonSets.empty, pylonSets.podIrst, pylonSets.podHarm, pylonSets.podSAtp, pylonSets.podLite, pylonSets.podLTgp];
	 	fuselageLset = [pylonSets.empty, pylonSets.podHarm, pylonSets.podLNav];

	 } elsif (block == 6) {
		pylon2set = [pylonSets.empty, pylonSets.aim9m, pylonSets.aim9x, pylonSets.aim120, pylonSets.dumb1, pylonSets.podACMI];
		pylon8set = [pylonSets.empty, pylonSets.aim9m, pylonSets.aim9x, pylonSets.aim120, pylonSets.dumb1, pylonSets.podACMI];
		pylon1set = [pylonSets.dumb1WT, pylonSets.dumb2WT, pylonSets.dumb3WT, pylonSets.aim9mWT, pylonSets.aim9xWT, pylonSets.aim120WT, pylonSets.podACMIWT, pylonSets.smokeRL, pylonSets.smokeGL, pylonSets.smokeBL, pylonSets.smokeWL];# wingtips are normally not empty, so CATM-9L dummy is loaded instead.
		pylon9set = [pylonSets.dumb1WT, pylonSets.dumb2WT, pylonSets.dumb3WT, pylonSets.aim9mWT, pylonSets.aim9xWT, pylonSets.aim120WT, pylonSets.podACMIWT, pylonSets.smokeRR, pylonSets.smokeGR, pylonSets.smokeBR, pylonSets.smokeWR];# wingtips are normally not empty, so CATM-9L dummy is loaded instead.
		pylon3set = [pylonSets.empty, pylonSets.hyd70h3, pylonSets.a154, pylonSets.a88, pylonSets.a84, pylonSets.a65d, pylonSets.c87, pylonSets.c105, pylonSets.g54x2, pylonSets.g31, pylonSets.g24, pylonSets.g12x2, pylonSets.m84, pylonSets.m82air, pylonSets.m82, pylonSets.aim9m, pylonSets.aim9x, pylonSets.aim120];
		pylon7set = [pylonSets.empty, pylonSets.hyd70h7, pylonSets.a154, pylonSets.a88, pylonSets.a84, pylonSets.a65d, pylonSets.c87, pylonSets.c105, pylonSets.g54x2, pylonSets.g31, pylonSets.g24, pylonSets.g12x2, pylonSets.m84, pylonSets.m82air, pylonSets.m82, pylonSets.aim9m, pylonSets.aim9x, pylonSets.aim120];
		pylon4set = [pylonSets.empty, pylonSets.g12x3, pylonSets.m82air, pylonSets.m82, pylonSets.a154, pylonSets.g54x2, pylonSets.g31, pylonSets.g24, pylonSets.c87, pylonSets.c105, pylonSets.m84, pylonSets.fuel60L, pylonSets.fuel37L];
		pylon6set = [pylonSets.empty, pylonSets.g12x3, pylonSets.m82air, pylonSets.m82, pylonSets.a154, pylonSets.g54x2, pylonSets.g31, pylonSets.g24, pylonSets.c87, pylonSets.c105, pylonSets.m84, pylonSets.fuel60R, pylonSets.fuel37R];
		pylon5set = [pylonSets.empty, pylonSets.podTrvl, pylonSets.podEcm184, pylonSets.podEcm131, pylonSets.fuel30];

		fuselageRset = [pylonSets.empty];
	 	fuselageLset = [pylonSets.podSifts];
	 }

	# pylons
	pylon1  = stations.Pylon.new("Left Wingtip Pylon",     0, [0.082,-4.79412, 0.01109], pylon1set, 0, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[1]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[1]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/elec/bus/ess-dc")>20;},func{return getprop("f16/avionics/power-st-sta");});
	pylon2  = stations.Pylon.new("Left Outer Wing Pylon",  1, [0.082,-3.95167,-0.25696], pylon2set, 1, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[2]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[2]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/elec/bus/ess-dc")>20;},func{return getprop("f16/avionics/power-st-sta");});
	pylon3  = stations.Pylon.new("Left Wing Pylon",        2, [0.082,-2.88034,-0.25696], pylon3set, 2, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[3]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[3]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/elec/bus/ess-dc")>20 and getprop("payload/sta[2]/serviceable");},func{return getprop("f16/avionics/power-st-sta");});
	pylon4  = stations.Pylon.new("Left Inner Wing Pylon",  3, [0.082,-1.62889,-0.25696], pylon4set, 3, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[4]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[4]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/elec/bus/ess-dc")>20 and getprop("payload/sta[3]/serviceable");},func{return getprop("f16/avionics/power-st-sta");});
	pylon11 = stations.Pylon.new("Left Fuselage Pylon",   11, [0,0,0]                  , fuselageLset, 4, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[11]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[11]",1),func{return 1;},func{return 1;});
	pylon5  = stations.Pylon.new("Center Pylon",           4, [0.082, 0,      -0.83778], pylon5set, 5, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[5]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[5]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/elec/bus/ess-dc")>20;},func{return getprop("f16/avionics/power-st-sta");});
	pylon10 = stations.Pylon.new("Right Fuselage Pylon",  10, [0,0,0]                  , fuselageRset, 6, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[12]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[12]",1),func{return 1;},func{return 1;});
	pylon6  = stations.Pylon.new("Right Inner Wing Pylon", 5, [0.082, 1.62889,-0.25696], pylon6set, 7, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[6]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[6]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/elec/bus/ess-dc")>20 and getprop("payload/sta[5]/serviceable");},func{return getprop("f16/avionics/power-st-sta");});
	pylon7  = stations.Pylon.new("Right Wing Pylon",       6, [0.082, 2.88034,-0.25696], pylon7set, 8, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[7]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[7]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/elec/bus/ess-dc")>20 and getprop("payload/sta[6]/serviceable");},func{return getprop("f16/avionics/power-st-sta");});
	pylon8  = stations.Pylon.new("Right Outer Wing Pylon", 7, [0.082, 3.95167,-0.25696], pylon8set, 9, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[8]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[8]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/elec/bus/ess-dc")>20;},func{return getprop("f16/avionics/power-st-sta");});
	pylon9  = stations.Pylon.new("Right Wingtip Pylon",    8, [0.082, 4.79412, 0.01109], pylon9set,10, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[9]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[9]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/elec/bus/ess-dc")>20;},func{return getprop("f16/avionics/power-st-sta");});
	pylonI  = stations.InternalStation.new("Internal gun mount", 9, [pylonSets.mm20], props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[10]",1));
	pylonCFT = stations.FixedStation.new("Conformal Fuel Mount",    12, [pylonSets.empty],props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[13]",1), props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[13]",1));

	pylon1.forceRail = 1;# set the missiles mounted on this pylon on a rail.
	pylon2.forceRail = 1;
	pylon8.forceRail = 1;
	pylon9.forceRail = 1;

    var pylons = [pylon1,pylon2,pylon3,pylon4,pylon5,pylon6,pylon7,pylon8,pylon9,pylonI,pylon10,pylon11];

    # The order in this line is the order key 'w' will cycle through the weapons:
	fcs = fc.FireControl.new(pylons, [9,0,8,1,7,2,6,3,5,4], ["20mm Cannon","LAU-68","AIM-9L","AIM-9M","AIM-9X","AIM-120","AIM-7","MK-82","MK-82AIR","MK-83","MK-84","GBU-12","GBU-24","GBU-31","GBU-54","AGM-65B","AGM-65D","AGM-84","AGM-88","AGM-119","AGM-154A","AGM-158","CBU-87","CBU-105"]);

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
	var wingtipSet1yf  = [pylonSets.dumb1WT, pylonSets.dumb2WT, pylonSets.smokeRL, pylonSets.smokeGL, pylonSets.smokeBL, pylonSets.smokeWL, pylonSets.empty];# wingtips are normally not empty, so CATM-9L dummy aim9 is loaded instead.
	var wingtipSet9yf  = [pylonSets.dumb1WT, pylonSets.dumb2WT, pylonSets.smokeRR, pylonSets.smokeGR, pylonSets.smokeBR, pylonSets.smokeWR, pylonSets.empty];# wingtips are normally not empty, so CATM-9L dummy aim9 is loaded instead.

	# pylons
	pylon1 = stations.Pylon.new("Left Wingtip Pylon", 0, [0,0,0], wingtipSet1yf, 0, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[1]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[1]",1));
	pylon9 = stations.Pylon.new("Right Wingtip Pylon", 8, [0,0,0], wingtipSet9yf, 1, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[9]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[9]",1));
}


#print("** Pylon & fire control system started. **");

##########################################################
#################        DLZ             #################
##########################################################


var getDLZ = func {
    if (fcs != nil and getprop("controls/armament/master-arm-switch") != 0) {
        var w = fcs.getSelectedWeapon();
        if (w!=nil and w.parents[0] == armament.AIM) {
            var result = w.getDLZ(1);
            if (result != nil and size(result) == 5 and result[4]<result[0]*1.5 and armament.contact != nil and armament.contact.isVisible()) {
                #target is within 150% of max weapon fire range.
        	    return result;
            }
        }
    }
    return nil;
}

##########################################################
#################        CFT             #################
##########################################################

var cftMounted = 0;

var detectCFT = func {
	removelistener(cftListener);
	var cft = props.getNode("sim/model/f16/cft");
	mountCFT(cft);
	setlistener("sim/model/f16/cft", mountCFT);
};

var mountCFT = func (mounted) {
	var cft = mounted.getBoolValue();
	if (cft and !cftMounted) {
		#print("Mounting CFT");
		pylonCFT.loadSet(pylonSets.cft450);
		#fuelTankCFT.mount(pylonCFT);
		cftMounted = 1;
	} elsif (!cft and cftMounted) {
		#print("Taking off CFT");
		pylonCFT.loadSet(pylonSets.empty);
		#fuelTankCFT.del();
		cftMounted = 0;
	}
};

var cftListener = setlistener("sim/signals/fdm-initialized", detectCFT);

##########################################################
################# COMMON FOR ALL PRESETS #################
##########################################################

# reload cannon only
var cannon_load = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# refill tanks
var refuel = func {
	if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
		damage.damageLog.push("All tank refueled");
		setprop("consumables/fuel/tank[0]/level-norm", 1);
		setprop("consumables/fuel/tank[1]/level-norm", 1);
		setprop("consumables/fuel/tank[2]/level-norm", 1);
		setprop("consumables/fuel/tank[3]/level-norm", 1);
		setprop("consumables/fuel/tank[4]/level-norm", 1);
		setprop("consumables/fuel/tank[5]/level-norm", 1);
		if (getprop("consumables/fuel/tank[6]/name") != "Not attached") setprop("consumables/fuel/tank[6]/level-norm", 1);
		if (getprop("consumables/fuel/tank[7]/name") != "Not attached") setprop("consumables/fuel/tank[7]/level-norm", 1);
		if (getprop("consumables/fuel/tank[8]/name") != "Not attached") setprop("consumables/fuel/tank[8]/level-norm", 1);
		if (getprop("consumables/fuel/tank[9]/name") != "Not attached" and block >= 5) setprop("consumables/fuel/tank[9]/level-norm", 1);
	} else {
      screen.log.write(f16.msgC);
    }
}

# Default configuration
var default = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Default loadout mounted");
        pylon1.loadSet(pylonSets.dumb1WT);# F16 never has nothing on wingtips unless its fired off, its aerodynamics is designed to work better with something there.
        pylon2.loadSet(pylonSets.empty);
        pylon3.loadSet(pylonSets.empty);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.empty);
        pylon8.loadSet(pylonSets.empty);
        pylon9.loadSet(pylonSets.dumb1WT);
        if (block == 6) {
        	pylon10.loadSet(pylonSets.empty);
        	pylon11.loadSet(pylonSets.podSAtp);
        } else {
        	pylon10.loadSet(pylonSets.empty);
        	pylon11.loadSet(pylonSets.empty);
        }
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Clean configuration
var clean = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Clean loadout mounted");
        pylon1.loadSet(pylonSets.empty);
        pylon2.loadSet(pylonSets.empty);
        pylon3.loadSet(pylonSets.empty);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.empty);
        pylon8.loadSet(pylonSets.empty);
        pylon9.loadSet(pylonSets.empty);
        if (block == 6) {
        	pylon10.loadSet(pylonSets.empty);
        	pylon11.loadSet(pylonSets.podSAtp);
        } else {
        	pylon10.loadSet(pylonSets.empty);
        	pylon11.loadSet(pylonSets.empty);
        }
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Airshow configuration (Smokewinder white)
var airshow = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Airshow loadout mounted");
        pylon1.loadSet(pylonSets.smokeWL);
        pylon2.loadSet(pylonSets.empty);
        pylon3.loadSet(pylonSets.empty);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.empty);
        pylon8.loadSet(pylonSets.empty);
        pylon9.loadSet(pylonSets.smokeWR);
        if (block == 6) {
        	pylon10.loadSet(pylonSets.empty);
        	pylon11.loadSet(pylonSets.podSAtp);
        } else {
        	pylon10.loadSet(pylonSets.empty);
        	pylon11.loadSet(pylonSets.empty);
        }
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

############################################
################ COMMON A/A ################
############################################

# CAP (AIM-9, AIM-120)
var a2a_cap = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Combat air patrol loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9m);
        pylon3.loadSet(pylonSets.aim120);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.aim120);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# CAP (AIM-9, AIM-120, 2 bags)
var a2a_capext = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Combat air patrol (ext. range) loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9m);
        pylon3.loadSet(pylonSets.aim120);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.aim120);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Air Superiority (AIM-120, 1 bag)
var a2a_super = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Air superiority loadout mounted");
    	pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.aim120);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.aim120);
        pylon8.loadSet(pylonSets.aim120);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Air Superiority (AIM-120, 2 bags)
var a2a_superer = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Air superiority (ext. range) loadout mounted");
    	pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.aim120);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.aim120);
        pylon8.loadSet(pylonSets.aim120);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# DCA (AIM-9, AIM-120)
var a2a_dca = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Defensive counter-air loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9m);
        pylon3.loadSet(pylonSets.aim9m);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.aim9m);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Ferry configuration 1 (3 bags, TRVL)
var ferry1 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Ferry (3 bags) loadout mounted");
        pylon1.loadSet(pylonSets.dumb2WT);
        pylon2.loadSet(pylonSets.empty);
        pylon3.loadSet(pylonSets.podTrvl);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.podTrvl);
        pylon8.loadSet(pylonSets.empty);
        pylon9.loadSet(pylonSets.dumb2WT);
        if (block == 6) {
        	pylon10.loadSet(pylonSets.empty);
        	pylon11.loadSet(pylonSets.podSAtp);
        } else {
        	pylon10.loadSet(pylonSets.empty);
        	pylon11.loadSet(pylonSets.empty);
        }
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Ferry configuration 2 (2 bags XL, TRVL)
var ferry2 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Ferry (2 bags XL) loadout mounted");
        pylon1.loadSet(pylonSets.dumb2WT);
        pylon2.loadSet(pylonSets.empty);
        pylon3.loadSet(pylonSets.podTrvl);
        pylon4.loadSet(pylonSets.fuel60L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel60R);
        pylon7.loadSet(pylonSets.podTrvl);
        pylon8.loadSet(pylonSets.empty);
        pylon9.loadSet(pylonSets.dumb2WT);
        if (block == 6) {
        	pylon10.loadSet(pylonSets.empty);
        	pylon11.loadSet(pylonSets.podSAtp);
        } else {
        	pylon10.loadSet(pylonSets.empty);
        	pylon11.loadSet(pylonSets.empty);
        }
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

############################################
################ COMMON A/G ################
############################################

# CAS (1x AGM-65D, 2 bags)
var a2g_caslt = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Close air support (light) loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9l);
        pylon3.loadSet(pylonSets.a65d);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.a65d);
        pylon8.loadSet(pylonSets.aim9l);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podLTgp);
        pylon11.loadSet(pylonSets.podLNav);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# CAS (3x AGM-65B, 2 bags)
var a2g_cas = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Close air support (heavy) loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9l);
        pylon3.loadSet(pylonSets.a65b);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.a65b);
        pylon8.loadSet(pylonSets.aim9l);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podLTgp);
        pylon11.loadSet(pylonSets.podLNav);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G Unguided 1: (MK-82)
var a2g_mk1 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G Unguided (light) loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9l);
        pylon3.loadSet(pylonSets.m82);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.m82);
        pylon8.loadSet(pylonSets.aim9l);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G Unguided Retarded: (MK-82AIR)
var a2g_mkair = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G Unguided retarded loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9l);
        pylon3.loadSet(pylonSets.m82air);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.m82air);
        pylon8.loadSet(pylonSets.aim9l);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G Unguided 2 (MK-84)
var a2g_mk2 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G Unguided (heavy) loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9l);
        pylon3.loadSet(pylonSets.m84);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.m84);
        pylon8.loadSet(pylonSets.aim9l);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G CEM (CBU-87)
var a2g_cem = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G Cluster CEM loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9l);
        pylon3.loadSet(pylonSets.c87);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.c87);
        pylon8.loadSet(pylonSets.aim9l);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G Hydra 70 (LAU-68)
var a2g_hyd70 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G M151 rockets loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9l);
        pylon3.loadSet(pylonSets.hyd70h3);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.hyd70h7);
        pylon8.loadSet(pylonSets.aim9l);
        pylon9.loadSet(pylonSets.aim120WT);
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
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G LGB light loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9l);
        pylon3.loadSet(pylonSets.g12x2);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.g12x2);
        pylon8.loadSet(pylonSets.aim9l);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podLTgp);
        pylon11.loadSet(pylonSets.podLNav);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G LBG Strike 2 (GBU-24)
var a2g_lgb2 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G LGB heavy loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9l);
        pylon3.loadSet(pylonSets.g24);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.g24);
        pylon8.loadSet(pylonSets.aim9l);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podLTgp);
        pylon11.loadSet(pylonSets.podLNav);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# SEAD "Wild Weasel" (AGM-88, 184 ECM pod)
var a2g_sead = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G SEAD Wild Weasel loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.a88);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.podEcm184);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.a88);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        if (block == 6) {
        	pylon10.loadSet(pylonSets.empty);
        	pylon11.loadSet(pylonSets.podSAtp);
        } else {
        	pylon10.loadSet(pylonSets.podSAtp);
            pylon11.loadSet(pylonSets.podHarm);
        }
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# SEAD/DEAD (GBU-12, ECM, HTS, 2 bags)
var a2g_dead = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G DEAD LGB loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9m);
        pylon3.loadSet(pylonSets.g12);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.podEcm131);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.g12);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        if (block == 6) {
        	pylon10.loadSet(pylonSets.empty);
        	pylon11.loadSet(pylonSets.podSAtp);
        } else {
        	pylon10.loadSet(pylonSets.podSAtp);
            pylon11.loadSet(pylonSets.podHarm);
        }
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G GPS Strike (GBU-31)
var a2g_gps = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G GPS (JDAM) loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9l);
        pylon3.loadSet(pylonSets.g31);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.g31);
        pylon8.loadSet(pylonSets.aim9l);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podLite);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G LGB + GPS Strike (GBU-12, GBU-31)
var a2g_lgbgps = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G LGB + GPS heavy loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9l);
        pylon3.loadSet(pylonSets.g31);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.g12x2);
        pylon8.loadSet(pylonSets.aim9l);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podLite);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G LGB + GPS Strike (GBU-12, GBU-54)
var a2g_lgbgps2 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G LGB + GPS light loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9l);
        pylon3.loadSet(pylonSets.g54x2);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.g12x2);
        pylon8.loadSet(pylonSets.aim9l);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podLite);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/S Anti-Ship ER (AGM-84D)
var a2s_antiship = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G Anti-ship loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9l);
        pylon3.loadSet(pylonSets.a84);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.a84);
        pylon8.loadSet(pylonSets.aim9l);
        pylon9.loadSet(pylonSets.aim120WT);
        if (block == 6) {
        	pylon10.loadSet(pylonSets.empty);
        	pylon11.loadSet(pylonSets.podSAtp);
        } else {
        	pylon10.loadSet(pylonSets.podLite);
            pylon11.loadSet(pylonSets.empty);
        }
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G Strategic Unguided (B61-7)
var a2g_strat = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G Strategic unguided loadout mounted");
        pylon1.loadSet(pylonSets.dumb3WT);
        pylon2.loadSet(pylonSets.dumb1);
        pylon3.loadSet(pylonSets.b617);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.podEcm131);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.b617);
        pylon8.loadSet(pylonSets.dumb1);
        pylon9.loadSet(pylonSets.dumb3WT);
        pylon10.loadSet(pylonSets.podLTgp);
        pylon11.loadSet(pylonSets.podLNav);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

############################################
################# BLOCK 10 #################
############################################

# Air Defense (AIM-9)
var b10_a2a_adf = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Air defense loadout mounted");
        pylon1.loadSet(pylonSets.aim9lWT);
        pylon2.loadSet(pylonSets.aim9l);
        pylon3.loadSet(pylonSets.aim9l);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.aim9l);
        pylon8.loadSet(pylonSets.aim9l);
        pylon9.loadSet(pylonSets.aim9lWT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Air Defense (AIM-9, 2 bags)
var b10_a2a_adfer = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Air defense (ext. range) loadout mounted");
        pylon1.loadSet(pylonSets.aim9lWT);
        pylon2.loadSet(pylonSets.aim9l);
        pylon3.loadSet(pylonSets.aim9l);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.aim9l);
        pylon8.loadSet(pylonSets.aim9l);
        pylon9.loadSet(pylonSets.aim9lWT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Strike Light (MK-82, AIM-9, 1 bag)
var b10_a2g_strike1 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G Unguided (light) loadout mounted");
        pylon1.loadSet(pylonSets.aim9lWT);
        pylon2.loadSet(pylonSets.empty);
        pylon3.loadSet(pylonSets.m82);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.m82);
        pylon8.loadSet(pylonSets.empty);
        pylon9.loadSet(pylonSets.aim9lWT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Strike Retarded (MK-82AIR, AIM-9, 1 bag)
var b10_a2g_strikeair = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G Unguided retarded loadout mounted");
        pylon1.loadSet(pylonSets.aim9lWT);
        pylon2.loadSet(pylonSets.empty);
        pylon3.loadSet(pylonSets.m82air);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.m82air);
        pylon8.loadSet(pylonSets.empty);
        pylon9.loadSet(pylonSets.aim9lWT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Strike Heavy (MK-84, AIM-9, 1 bag)
var b10_a2g_strike2 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G Unguided (heavy) loadout mounted");
        pylon1.loadSet(pylonSets.aim9lWT);
        pylon2.loadSet(pylonSets.empty);
        pylon3.loadSet(pylonSets.m84);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.m84);
        pylon8.loadSet(pylonSets.empty);
        pylon9.loadSet(pylonSets.aim9lWT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/A training
var b10_train_aa = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Air to air training loadout mounted");
        pylon1.loadSet(pylonSets.dumb2WT);
        pylon2.loadSet(pylonSets.empty);
        pylon3.loadSet(pylonSets.empty);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.empty);
        pylon8.loadSet(pylonSets.empty);
        pylon9.loadSet(pylonSets.podACMIWT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G training (2 bags)
var b10_train_ag = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Air to ground training loadout mounted");
        pylon1.loadSet(pylonSets.dumb2WT);
        pylon2.loadSet(pylonSets.empty);
        pylon3.loadSet(pylonSets.mau);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.mau);
        pylon8.loadSet(pylonSets.empty);
        pylon9.loadSet(pylonSets.dumb2WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

############################################
################# BLOCK 20 #################
############################################

# Air Defense (AIM-9, AIM-7)
var b20_a2a_adf = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Air defense loadout mounted");
        pylon1.loadSet(pylonSets.aim9mWT);
        pylon2.loadSet(pylonSets.aim9m);
        pylon3.loadSet(pylonSets.aim7);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.aim7);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim9mWT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Air Defense (AIM-9, AIM-7)
var b20_a2a_adfer = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        damage.damageLog.push("Air defense (ext. range) loadout mounted");
        pylon1.loadSet(pylonSets.aim9mWT);
        pylon2.loadSet(pylonSets.aim9m);
        pylon3.loadSet(pylonSets.aim7);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.aim7);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim9mWT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# QRA (AIM-9, AIM-120, 2 bags)
var b20_a2a_qra = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Quick reaction alert loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9m);
        pylon3.loadSet(pylonSets.empty);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.empty);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G SFW (CBU-105)
var b20_a2g_sfw = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        damage.damageLog.push("A/G Cluster SFW (WCMD) loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9l);
        pylon3.loadSet(pylonSets.c105);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.c105);
        pylon8.loadSet(pylonSets.aim9l);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podLite);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G LGB + GPS Strike (GBU-12, GBU-54)
var b20_a2g_lgbgps = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G LGB + GPS light loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9l);
        pylon3.loadSet(pylonSets.g12);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.g54);
        pylon8.loadSet(pylonSets.aim9l);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podSAtp);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# SEAD (AGM-88, 184 ECM pod)
var b20_a2g_sead = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G SEAD loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9m);
        pylon3.loadSet(pylonSets.a88);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.podEcm184);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.a88);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podHarm);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# DEAD (CBU-105, ECM, HTS, 2 bags)
var b20_a2g_dead = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        damage.damageLog.push("A/G DEAD SFW loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9m);
        pylon3.loadSet(pylonSets.c105);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.podEcm184);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.c105);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podSAtp);
        pylon11.loadSet(pylonSets.podHarm);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/S Anti-Ship (AGM-84)
var b20_a2s_antiship = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G Anti-ship loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9l);
        pylon3.loadSet(pylonSets.a84);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.a84);
        pylon8.loadSet(pylonSets.aim9l);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/S Anti-Ship (AGM-84, 184 ECM pod)
var b20_a2s_antishiper = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G Anti-ship (ext. range) loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9l);
        pylon3.loadSet(pylonSets.a84);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.podEcm184);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.a84);
        pylon8.loadSet(pylonSets.aim9l);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/S Anti-Ship (AGM-119)
var a2s_antiship2 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G Anti-ship Penguin loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9l);
        pylon3.loadSet(pylonSets.a119);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.a119);
        pylon8.loadSet(pylonSets.aim9l);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podSAtp);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/S Anti-Ship (AGM-119)
var a2s_antiship2er = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        damage.damageLog.push("A/G Anti-ship Penguin (ext. range) loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9l);
        pylon3.loadSet(pylonSets.a119);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.a119);
        pylon8.loadSet(pylonSets.aim9l);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podSAtp);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Peacetime training configuration 1
var b20_train_aa = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Air to air training loadout mounted");
        pylon1.loadSet(pylonSets.dumb3WT);
        pylon2.loadSet(pylonSets.dumb1);
        pylon3.loadSet(pylonSets.empty);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.empty);
        pylon8.loadSet(pylonSets.dumb1);
        pylon9.loadSet(pylonSets.dumb3WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Peacetime training configuration 2
var b20_train_ag = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Air to ground training loadout mounted");
        pylon1.loadSet(pylonSets.dumb2WT);
        pylon2.loadSet(pylonSets.dumb1);
        pylon3.loadSet(pylonSets.mau);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.podEcm131);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.mau);
        pylon8.loadSet(pylonSets.dumb1);
        pylon9.loadSet(pylonSets.dumb2WT);
        pylon10.loadSet(pylonSets.podLite);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

############################################
################# BLOCK 30 #################
############################################

# SEAD "Wild Weasel" (AGM-88, 131 ECM pod)
var b30_a2g_sead = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G SEAD loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9m);
        pylon3.loadSet(pylonSets.a88);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.podEcm131);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.a88);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# SEAD/DEAD (CBU-87, ECM, 2 bags)
var b30_a2g_dead = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G DEAD CEM loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9m);
        pylon3.loadSet(pylonSets.c87);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.podEcm131);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.c87);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podLTgp);
        pylon11.loadSet(pylonSets.podLNav);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

var b30_a2s_antiship = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G Anti-ship (ext. range) loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9l);
        pylon3.loadSet(pylonSets.a84);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.a84);
        pylon8.loadSet(pylonSets.aim9l);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Peacetime training configuration 1
var b30_train_aa = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Air to air training loadout mounted");
        pylon1.loadSet(pylonSets.dumb2WT);
        pylon2.loadSet(pylonSets.dumb1);
        pylon3.loadSet(pylonSets.empty);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.empty);
        pylon8.loadSet(pylonSets.podACMI);
        pylon9.loadSet(pylonSets.dumb2WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Peacetime training configuration
var b30_train_ag = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Air to ground training loadout mounted");
        pylon1.loadSet(pylonSets.dumb3WT);
        pylon2.loadSet(pylonSets.dumb1);
        pylon3.loadSet(pylonSets.mau);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.podEcm131);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.mau);
        pylon8.loadSet(pylonSets.podACMI);
        pylon9.loadSet(pylonSets.dumb3WT);
        pylon10.loadSet(pylonSets.podLTgp);
        pylon11.loadSet(pylonSets.podLNav);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/A Aggressor 1
var b30_agrs1_aa = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Aggressor training loadout mounted");
        pylon1.loadSet(pylonSets.dumb1WT);
        pylon2.loadSet(pylonSets.empty);
        pylon3.loadSet(pylonSets.empty);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.podEcm188);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.empty);
        pylon8.loadSet(pylonSets.empty);
        pylon9.loadSet(pylonSets.podACMIWT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/A Aggressor 2
var b30_agrs2_aa = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Aggressor training loadout mounted");
        pylon1.loadSet(pylonSets.dumb3WT);
        pylon2.loadSet(pylonSets.podACMI);
        pylon3.loadSet(pylonSets.mau);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.podEcm188);
        pylon8.loadSet(pylonSets.dumb1);
        pylon9.loadSet(pylonSets.dumb3WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/A Aggressor 3
var b30_agrs3_aa = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Aggressor training loadout mounted");
        pylon1.loadSet(pylonSets.dumb3WT);
        pylon2.loadSet(pylonSets.dumb1);
        pylon3.loadSet(pylonSets.empty);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.podEcm188);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.empty);
        pylon8.loadSet(pylonSets.podACMI);
        pylon9.loadSet(pylonSets.dumb3WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}


############################################
################ BLOCK 40/50 ###############
############################################

# CAP (AIM-9, AIM-120, 2 bags)
var b40_a2a_capext = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Combat air patrol (ext. range) loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.aim120);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.aim120);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        if (block == 5) {
            pylon10.loadSet(pylonSets.podSAtp);
            pylon11.loadSet(pylonSets.podHarm);
        } else {
            pylon10.loadSet(pylonSets.podSAtp);
            pylon11.loadSet(pylonSets.empty);
        }
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Air Superiority (AIM-120, 2 bags)
var b40_a2a_superer = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Air superiority (ext. range) loadout mounted");
    	pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.aim120);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.aim120);
        pylon8.loadSet(pylonSets.aim120);
        pylon9.loadSet(pylonSets.aim120WT);
        if (block == 5) {
            pylon10.loadSet(pylonSets.podSAtp);
            pylon11.loadSet(pylonSets.podHarm);
        } else {
            pylon10.loadSet(pylonSets.podSAtp);
            pylon11.loadSet(pylonSets.empty);
        }
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Air Policing (AIM-9, AIM-120, 2 bags)
var b50_a2a_ap = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Air policing loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.empty);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.podEcm131);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.empty);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        if (block == 5) {
            pylon10.loadSet(pylonSets.podSAtp);
            pylon11.loadSet(pylonSets.podHarm);
        } else {
            pylon10.loadSet(pylonSets.podSAtp);
            pylon11.loadSet(pylonSets.empty);
        }
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# AIM-9x Testing (AIM-9)
var a9x_testing = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("AIM-9X Testing loadout mounted");
        pylon1.loadSet(pylonSets.aim9xWT);
        pylon2.loadSet(pylonSets.aim9x);
        pylon3.loadSet(pylonSets.aim9x);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.aim9x);
        pylon8.loadSet(pylonSets.aim9x);
        pylon9.loadSet(pylonSets.aim9xWT);
        if (block == 5) {
            pylon10.loadSet(pylonSets.podLite);
            pylon11.loadSet(pylonSets.podLNav);
        } else {
            pylon10.loadSet(pylonSets.podLite);
            pylon11.loadSet(pylonSets.empty);
        }
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G SFW (CBU-105)
var b40_a2g_sfw = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G Cluster SFW (WCMD) loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9l);
        pylon3.loadSet(pylonSets.c105x2);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.c105x2);
        pylon8.loadSet(pylonSets.aim9l);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podLite);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G GPS Strike (GBU-54)
var b40_a2g_gpslsr = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G GPS (L-JDAM) loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9l);
        pylon3.loadSet(pylonSets.g54x2);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.g54x2);
        pylon8.loadSet(pylonSets.aim9l);
        pylon9.loadSet(pylonSets.aim120WT);
        if (block == 5) {
            pylon10.loadSet(pylonSets.podSAtp);
            pylon11.loadSet(pylonSets.podHarm);
        } else {
            pylon10.loadSet(pylonSets.podSAtp);
            pylon11.loadSet(pylonSets.empty);
        }
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Combat Patrol (AIM-120, AIM-9, GBU-54, 2 bags)
var b50_a2g_cp = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        damage.damageLog.push("Combat Patrol loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.g54);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.g54);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        if (block == 5) {
            pylon10.loadSet(pylonSets.podSAtp);
            pylon11.loadSet(pylonSets.podHarm);
        } else {
            pylon10.loadSet(pylonSets.podSAtp);
            pylon11.loadSet(pylonSets.empty);
        }
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}


# SEAD "Wild Weasel" (AGM-88, 131 ECM pod)
var b50_a2g_sead1 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        damage.damageLog.push("A/G SEAD Wild Weasel loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.a88);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.podEcm131);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.a88);
        pylon8.loadSet(pylonSets.aim120);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podSAtp);
        pylon11.loadSet(pylonSets.podHarm);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

var b50_a2g_sead2 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G SEAD dual loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9m);
        pylon3.loadSet(pylonSets.a88);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.podEcm184);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.a65d);
        pylon8.loadSet(pylonSets.aim120);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podSAtp);
        pylon11.loadSet(pylonSets.podHarm);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# SEAD/DEAD (GBU-54, ECM, HTS, 2 bags)
var b50_a2g_sdead = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G SEAD/DEAD loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.a88);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.podEcm184);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.g54x2);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podSAtp);
        pylon11.loadSet(pylonSets.podHarm);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# DEAD (CBU-105, ECM, HTS, 2 bags)
var b50_a2g_dead1 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G DEAD SFW loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.c105);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.podEcm184);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.c105);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podSAtp);
        pylon11.loadSet(pylonSets.podHarm);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# DEAD (GBU-12, ECM, HTS, 2 bags)
var b50_a2g_dead2 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G DEAD LGB loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.g12);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.podEcm184);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.g12);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podSAtp);
        pylon11.loadSet(pylonSets.podHarm);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# CAS (1x AGM-65D, 2 bags)
var b40_a2g_caslt = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Close air support (light) loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9l);
        pylon3.loadSet(pylonSets.a65d);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.a65d);
        pylon8.loadSet(pylonSets.aim9l);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podLite);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# CAS Mix (GBU-54, Hydra, 2 bags)
var b40_a2g_casmix = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Close air support (mixed) loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.empty);
        pylon3.loadSet(pylonSets.g54x2);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.hyd70h7);
        pylon8.loadSet(pylonSets.aim9l);
        pylon9.loadSet(pylonSets.aim120WT);
        if (block == 5) {
            pylon10.loadSet(pylonSets.podSAtp);
            pylon11.loadSet(pylonSets.podHarm);
        } else {
            pylon10.loadSet(pylonSets.podSAtp);
            pylon11.loadSet(pylonSets.empty);
        }
        f16.reloadCannon();
        f16.reloadHydras();
    } else {
      screen.log.write(f16.msgB);
    }
}

# CAS Dual (GBU-12, AGM-65D)
var b40_a2g_casduo = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Close air support (dual) loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.empty);
        pylon3.loadSet(pylonSets.g12);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.a65d);
        pylon8.loadSet(pylonSets.empty);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podSAtp);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G Stand-off Strike mode 1 (AGM-154A)
var a2g_jsow = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G Stand-off (JSOW) loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9l);
        pylon3.loadSet(pylonSets.a154);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.podEcm184);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.a154);
        pylon8.loadSet(pylonSets.aim9l);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.podSAtp);
        pylon11.loadSet(pylonSets.podHarm);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G Stand-off Strike mode 2 (AGM-158)
var a2g_jassm = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G Stand-off (JASSM) loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9l);
        pylon3.loadSet(pylonSets.a158);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.podEcm131);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.a158);
        pylon8.loadSet(pylonSets.aim9l);
        pylon9.loadSet(pylonSets.aim120WT);
        if (block == 5) {
            pylon10.loadSet(pylonSets.podSAtp);
            pylon11.loadSet(pylonSets.podHarm);
        } else {
            pylon10.loadSet(pylonSets.podSAtp);
            pylon11.loadSet(pylonSets.empty);
        }
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G Tactical Guided Strike (B61-12)
var b50_a2g_tact = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Tactical test and evaluation loadout mounted");
        pylon1.loadSet(pylonSets.dumb3WT);
        pylon2.loadSet(pylonSets.podACMI);
        pylon3.loadSet(pylonSets.b6112);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.podEcm184);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.b6112);
        pylon8.loadSet(pylonSets.dumb1);
        pylon9.loadSet(pylonSets.dumb3WT);
        pylon10.loadSet(pylonSets.podSAtp);
        pylon11.loadSet(pylonSets.podHarm);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Peacetime training configuration 1
var b40_train_aa = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Air to air training loadout mounted");
        pylon1.loadSet(pylonSets.dumb3WT);
        pylon2.loadSet(pylonSets.podACMI);
        pylon3.loadSet(pylonSets.empty);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.empty);
        pylon8.loadSet(pylonSets.dumb1);
        pylon9.loadSet(pylonSets.dumb3WT);
        if (block == 5) {
            pylon10.loadSet(pylonSets.empty);
            pylon11.loadSet(pylonSets.podHarm);
        } else {
            pylon10.loadSet(pylonSets.empty);
            pylon11.loadSet(pylonSets.empty);
        }
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Aggressor training configuration
var b40_train_agrs = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Aggressor training loadout mounted");
        pylon1.loadSet(pylonSets.dumb3WT);
        pylon2.loadSet(pylonSets.podACMI);
        pylon3.loadSet(pylonSets.mau);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.podEcm188);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.mau);
        pylon8.loadSet(pylonSets.dumb1);
        pylon9.loadSet(pylonSets.dumb3WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Peacetime training configuration 2
var b40_train_ag = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Air to ground training loadout mounted");
        pylon1.loadSet(pylonSets.dumb3WT);
        pylon2.loadSet(pylonSets.podACMI);
        pylon3.loadSet(pylonSets.mau);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.podEcm131);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.mau);
        pylon8.loadSet(pylonSets.dumb1);
        pylon9.loadSet(pylonSets.dumb3WT);
        pylon10.loadSet(pylonSets.podSAtp);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Peacetime training configuration 2
var b50_train_ag = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Air to ground training loadout mounted");
        pylon1.loadSet(pylonSets.dumb3WT);
        pylon2.loadSet(pylonSets.podACMI);
        pylon3.loadSet(pylonSets.mau);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.podEcm184);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.mau);
        pylon8.loadSet(pylonSets.dumb1);
        pylon9.loadSet(pylonSets.dumb3WT);
        pylon10.loadSet(pylonSets.podSAtp);
        pylon11.loadSet(pylonSets.podHarm);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Legion Pod Test & Evaluation
var b40_testev = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        damage.damageLog.push("IRST test and evaluation loadout mounted");
        pylon1.loadSet(pylonSets.dumb3WT);
        pylon2.loadSet(pylonSets.dumb1);
        pylon3.loadSet(pylonSets.mau);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.mau);
        pylon8.loadSet(pylonSets.podACMI);
        pylon9.loadSet(pylonSets.dumb3WT);
        pylon10.loadSet(pylonSets.podIrst);
        pylon11.loadSet(pylonSets.empty);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Legion Pod Test & Evaluation
var b50_testev = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("IRST test and evaluation loadout mounted");
        pylon1.loadSet(pylonSets.dumb3WT);
        pylon2.loadSet(pylonSets.dumb1);
        pylon3.loadSet(pylonSets.empty);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.empty);
        pylon8.loadSet(pylonSets.podACMI);
        pylon9.loadSet(pylonSets.dumb3WT);
        pylon10.loadSet(pylonSets.podIrst);
        pylon11.loadSet(pylonSets.podHarm);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

############################################
################# BLOCK 60 #################
############################################

# Peacetime training configuration 1
var b60_train_aa = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Air to air training loadout mounted");
        pylon1.loadSet(pylonSets.dumb3WT);
        pylon2.loadSet(pylonSets.podACMI);
        pylon3.loadSet(pylonSets.empty);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.empty);
        pylon8.loadSet(pylonSets.dumb1);
        pylon9.loadSet(pylonSets.dumb3WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.podSAtp);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Peacetime training configuration 2
var b60_train_ag = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Air to ground training loadout mounted");
        pylon1.loadSet(pylonSets.dumb3WT);
        pylon2.loadSet(pylonSets.podACMI);
        pylon3.loadSet(pylonSets.mau);
        pylon4.loadSet(pylonSets.mau);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.mau);
        pylon7.loadSet(pylonSets.mau);
        pylon8.loadSet(pylonSets.dumb1);
        pylon9.loadSet(pylonSets.dumb3WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.podSAtp);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# CAP (AIM-9, AIM-120)
var b60_a2a_cap = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Combat air patrol loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.aim9m);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.aim9m);
        pylon8.loadSet(pylonSets.aim120);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.podSAtp);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# CAP (AIM-9, AIM-120, 2 bags)
var b60_a2a_capext = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Combat air patrol (ext. range) loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.aim9m);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.aim9m);
        pylon8.loadSet(pylonSets.aim120);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.podSAtp);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Air Superiority (AIM-120)
var b60_a2a_super = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Air superiority loadout mounted");
    	pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.aim120);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.aim120);
        pylon8.loadSet(pylonSets.aim120);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.podSAtp);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Air Superiority (AIM-120, 1 bag)
var b60_a2a_superer = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Air superiority (ext. range) loadout mounted");
    	pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.aim120);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.aim120);
        pylon8.loadSet(pylonSets.aim120);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.podSAtp);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# Air Superiority (AIM-120, 2 bags)
var b60_a2a_superer2 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Air superiority (ext. range) loadout mounted");
    	pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim120);
        pylon3.loadSet(pylonSets.aim120);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.aim120);
        pylon8.loadSet(pylonSets.aim120);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.podSAtp);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# DCA (AIM-9, AIM-120)
var b60_a2a_dca = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Defensive counter-air loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9m);
        pylon3.loadSet(pylonSets.aim9m);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.aim9m);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.podSAtp);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G Unguided 1: (MK-82)
var b60_a2g_mk1 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G Unguided (light) loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9m);
        pylon3.loadSet(pylonSets.m82);
        pylon4.loadSet(pylonSets.m82);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.m82);
        pylon7.loadSet(pylonSets.m82);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.podSAtp);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G Unguided 2 (MK-84)
var b60_a2g_mk2 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G Unguided (heavy) loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9m);
        pylon3.loadSet(pylonSets.m84);
        pylon4.loadSet(pylonSets.m84);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.m84);
        pylon7.loadSet(pylonSets.m84);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.podSAtp);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G Unguided Retarded: (MK-82AIR)
var b60_a2g_mkair = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G Unguided retarded loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9m);
        pylon3.loadSet(pylonSets.m82air);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.m82air);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.podSAtp);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G CEM (CBU-87)
var b60_a2g_cem = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G Cluster CEM loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9m);
        pylon3.loadSet(pylonSets.c87);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.c87);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.podSAtp);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G LGB Strike 1 (GBU-12)
var b60_a2g_lgb1 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G LGB light loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9m);
        pylon3.loadSet(pylonSets.g12x2);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.g12x2);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.podSAtp);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G LBG Strike 2 (GBU-24)
var b60_a2g_lgb2 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G LGB heavy loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9m);
        pylon3.loadSet(pylonSets.g24);
        pylon4.loadSet(pylonSets.g24);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.g24);
        pylon7.loadSet(pylonSets.g24);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.podSAtp);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G GPS Strike (GBU-31)
var b60_a2g_gps = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G GPS (JDAM) loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9m);
        pylon3.loadSet(pylonSets.g31);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.g31);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.podSAtp);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G GPS Strike (GBU-54)
var b60_a2g_gpslsr = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G GPS (L-JDAM) loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9m);
        pylon3.loadSet(pylonSets.g54x2);
        pylon4.loadSet(pylonSets.fuel37L);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.fuel37R);
        pylon7.loadSet(pylonSets.g54x2);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.podSAtp);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

var b60_a2g_sfw = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G Cluster SFW (WCMD) loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9m);
        pylon3.loadSet(pylonSets.c105);
        pylon4.loadSet(pylonSets.c105);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.c105);
        pylon7.loadSet(pylonSets.c105);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.podSAtp);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# CAS (1x AGM-65D, 2 bags)
var b60_a2g_cas = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("Close air support loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9m);
        pylon3.loadSet(pylonSets.a65d);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.a65d);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.podSAtp);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G Hydra 70 (LAU-68)
var b60_a2g_hyd70 = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G M151 rockets loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9m);
        pylon3.loadSet(pylonSets.hyd70h3);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.hyd70h7);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.podSAtp);
        f16.reloadCannon();
        f16.reloadHydras();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/S Anti-Ship ER (AGM-84D)
var b60_a2s_antiship = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G Anti-ship loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9m);
        pylon3.loadSet(pylonSets.a84);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.a84);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.podSAtp);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

# A/G Stand-off Strike mode 1 (AGM-154A)
var b60_a2g_jsow = func {
    if (fcs != nil and (getprop("payload/armament/msg") == 0 or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
    	damage.damageLog.push("A/G Stand-off (JSOW) loadout mounted");
        pylon1.loadSet(pylonSets.aim120WT);
        pylon2.loadSet(pylonSets.aim9m);
        pylon3.loadSet(pylonSets.a154);
        pylon4.loadSet(pylonSets.a154);
        pylon5.loadSet(pylonSets.fuel30);
        pylon6.loadSet(pylonSets.a154);
        pylon7.loadSet(pylonSets.a154);
        pylon8.loadSet(pylonSets.aim9m);
        pylon9.loadSet(pylonSets.aim120WT);
        pylon10.loadSet(pylonSets.empty);
        pylon11.loadSet(pylonSets.podSAtp);
        f16.reloadCannon();
    } else {
      screen.log.write(f16.msgB);
    }
}

var bore_loop = func {
    #enables firing of aim9 without radar.
    bore = 0;
    if (fcs != nil and getprop("controls/armament/master-arm-switch") != 0) {
        var standby = getprop("instrumentation/radar/radar-standby");
        var aim = fcs.getSelectedWeapon();
        if (aim != nil and (aim.type == "AIM-9L" or aim.type == "AIM-9M" or aim.type == "AIM-9X")) {
        	var hmd_active = getprop("payload/armament/hmd-active");

        	if (hmd_active==1 and aim.status < 1 and radar_system.apg68Radar.getPriorityTarget() == nil) {
        		aim.setContacts(radar_system.getCompleteList());
        		var h = -geo.normdeg180(getprop("sim/current-view/heading-offset-deg"));
                var p = getprop("sim/current-view/pitch-offset-deg");
        		if (1 or math.sqrt(h*h+p*p) < aim.fcs_fov) {
                	aim.commandDir(h,p);
                	bore = 2;
            	} else {
            		if (standby != 1) {
		                aim.commandRadar(0,-4);
		                aim.setContacts([]);
		            } else {
		            	aim.setContacts(radar_system.getCompleteList());
		                aim.commandDir(0,-4);# the real is bored to -6 deg below real bore
		                bore = 1;
		            }
            	}
            } elsif (standby == 1) {
                #aim.setBore(1);
                aim.setContacts(radar_system.getCompleteList());
                aim.commandDir(0,-4);# the real is bored to -6 deg below real bore
                bore = 1;
            } elsif (radar_system.apg68Radar.getPriorityTarget() != nil and aim.status == armament.MISSILE_LOCK and aim.Tgt.getUnique() != radar_system.apg68Radar.getPriorityTarget().getUnique()) {
            	# stop tracking target with IR and start try to lock up radar target
            	aim.commandRadar(0,-4);
                aim.setContacts([]);
                aim.Tgt = nil;
            } elsif (aim.status != armament.MISSILE_LOCK) {
                aim.commandRadar(0,-4);
                aim.setContacts([]);
            }
        }
    }
    #if (fcs.isXfov()) {# growl type 1 and 2
    #	setprop("payload/armament/growl-type", 0);
    #} else {
    #	setprop("payload/armament/growl-type", 1);
    #}
};
var bore = 0;
var bore_loop_timer = maketimer(0.1, bore_loop);
if (fcs!=nil) {
    bore_loop_timer.start();
}
