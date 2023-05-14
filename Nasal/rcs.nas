#
# Radar Cross-section calculation for radars
# 
# Main author: Pinto
#
# License: GPL 2
#
# The file vector.nas needs to be available in namespace 'vector'.
#

var test = func (echoHeading, echoPitch, echoRoll, bearing, frontRCS) {
  var myCoord = geo.aircraft_position();
  var echoCoord = geo.Coord.new(myCoord);
  echoCoord.apply_course_distance(bearing, 1000);#1km away
  echoCoord.set_alt(echoCoord.alt()+1000);#1km higher than me
  print("RCS final: "~getRCS(echoCoord, echoHeading, echoPitch, echoRoll, myCoord, frontRCS));
};

var rcs_database = {
	#REVISION: 2022/12/11
    "YF-16":                    5,      #higher because earlier blocks had larger RCS
    "F-16CJ":                   2,      #average
    "f16":                      2,      #average
    "jaguar":                   6,      #guess
    "KC135":                    100,    #guess
    "onox-tanker":              100,    #guess
    "A-6E":                     9,      #average
    "EF2000":                   0.5,
    "brsq":                     1.5,    #average (multiple sources)
    "FA-18C_Hornet":            3.5,    #later Blocks have 1
    "FA-18D_Hornet":            3.5,
    "FA-18":                    3.5,
    "FA-18E_CVW5":              1.0,
    "F-5E-TigerII":             4,      #close to actual
    "F-5ENinja":                4,      #close to actual
    "f-20A":                    2.5,    #low end of sources
    "f-20C":                    2.5,
    "f-20prototype":            2.5,
    "f-20bmw":                  2.5,
    "f-20-dutchdemo":           2.5,
    "t38talon":                 4,
    "F-4C":                     7,     #average
    "F-4D":                     7,     #average
    "F-4E":                     7,     #average
    "F-4EJ":                    7,     #average
    "F-4EJ_ADTW":               7,     #average
    "F-4F":                     7,     #average
    "F-4J":                     7,     #average
    "F4J":                      7,     #average
    "F-4N":                     7,     #average
    "F-4S":                     7,     #average
    "FGR2":                     7,     #average
    "FGR2-Phantom":             7,     #average
    "F-111C":                   11,
    "daVinci_F-111G":           11,
    "MiG-15bis":                6,     #guess
    "MiG-21Bison":              3.5,
    "MiG-25":                   9,     #average
    "Mig-29":                   6,     #guess
    "Su-15":                    6.5,   #guess
    "Su-25":                    7,     #guess
    "Su-34":                    8,     #should be less
    "SU-37":                    6,     #wild guess
    "J-11A":                    15,    #same as Su-27
    "tu95":                     20,    #average
    "Tu-95MR":                  20,    #average
    "Tu-160-Blackjack":         15,
    "G91-R1B":                  6,     #guess
    "mb339":                    4,     #guess
    "mb339pan":                 4,     #guess
    "alphajet":                 4.5,   #average
    "E-2C-Hawkeye":             22,    #average
    "c-2a":                     20,    #average
    "ac130":                    32,    #average
    "C130J":                    32,    #average
    "c130k":                    32,    #average
    "kc130":                    32,    #average
    "XB-70":                    21,    #average
    # Helis:
    "uh60_Blackhawk":           4,      #average
    "AH-1W":                    4,      #average
    "WAH-64_Apache":            5,      #average
    "rah-66":                   1,      #wild guess
    "Gazelle":                  1.5,    #guess
    "Westland_Gazelle":         1.5,    #guess
    "AS532-Cougar":             3,      #guess
    "Westland_SeaKing-HAR3":    3.5,    #average
    "Lynx-HMA8":                1,      #average
    "Lynx_Wildcat":             1,      #average
    "Merlin-HM1":               5,      #average
    "OH-58D":                   0.5,    #average
    #Stealth
    "b2-spirit":                0.0001,  #actual: 0.0001
    "B-2A":                     0.0001,  #actual: 0.0001
    "F-22-Raptor":				0.0001,	 #actual: 0.0001
    "F-35A":					0.0015,
    "F-35B":					0.0015,
    "F-35C":                    0.0015,
    "daVinci_F-35A":            0.0015,
    "daVinci_F-35B":            0.0015,
    "F-117":                    0.003,
    "T-50":                     0.5,    #low end of sources
    "u-2s":                     0.01,
    "U-2S-model":               0.01,
};

var prevVisible = {};
var lastUpdateTime = {};

var timeNode = props.globals.getNode("sim/time/elapsed-sec");


# For 'inRadarRange', decide if the previous RCS test result can be result, or if a new test should be done.
# If the previous test is more than 'max_refresh_sec' old (resp. less than 'min_refresh_sec'),
# then a new test is always (resp. never) done.
# In between these two values, a test is done with probability 'refresh_prob'.
var refreshRequired = func (contact, min_refresh_sec, max_refresh_sec, refresh_prob) {
    var callsign = contact.get_Callsign();
    if (callsign == nil or !contains(lastUpdateTime, callsign)) return 1;

    var update_age = timeNode.getValue() - lastUpdateTime[callsign];
    if (update_age < min_refresh_sec) return 0;
    elsif (update_age > max_refresh_sec) return 1;
    else return (rand() < refresh_prob);
}

var inRadarRange = func (contact, myRadarDistance_nm, myRadarStrength_rcs,
                         min_refresh_sec=1, max_refresh_sec=10, refresh_prob=0.05) {
    if (refreshRequired(contact, min_refresh_sec, max_refresh_sec, refresh_prob)) {
        return isInRadarRange(contact, myRadarDistance_nm, myRadarStrength_rcs);
    } else {
        return wasInRadarRange(contact, myRadarDistance_nm, myRadarStrength_rcs);
    }
}

var wasInRadarRange = func (contact, myRadarDistance_nm, myRadarStrength_rcs) {
    var sign = contact.get_Callsign();
    if (sign != nil and contains(prevVisible, sign)) {
        return prevVisible[sign];
    } else {
        return isInRadarRange(contact, myRadarDistance_nm, myRadarStrength_rcs);
    }
}

var isInRadarRange = func (contact, myRadarDistance_nm, myRadarStrength_rcs) {
    if (contact != nil and contact.get_Coord() != nil) {
        var value = 1;
        call(func {value = targetRCSSignal(contact.get_Coord(), contact.getModel(), contact.get_heading(), contact.get_Pitch(), contact.get_Roll(), geo.aircraft_position(), myRadarDistance_nm*NM2M, myRadarStrength_rcs)},nil, var err = []);
        if (size(err)) {
            foreach(line;err) {
                print(line);
            }
            # open radar for one will make this happen.
            return value;
        }
        var callsign = contact.get_Callsign();
        prevVisible[callsign] = value;
        lastUpdateTime[callsign] = timeNode.getValue();
        return value;
    }
    return 0;
};

#most detection ranges are for a target that has an rcs of 5m^2, so leave that at default if not specified by source material

var targetRCSSignal = func(targetCoord, targetModel, targetHeading, targetPitch, targetRoll, myCoord, myRadarDistance_m, myRadarStrength_rcs = 5) {
    #print(targetModel);
    var target_front_rcs = nil;
    if ( contains(rcs_oprf_database,targetModel) ) {
        target_front_rcs = rcs_oprf_database[targetModel];
    } elsif ( contains(rcs_database,targetModel) ) {
        target_front_rcs = rcs_database[targetModel];
    } else {
        return 1;
        target_front_rcs = rcs_database["default"];
    }
    #print(target_front_rcs," RCS from ", targetModel, " m:", myRadarDistance_m, " rcs:",myRadarStrength_rcs);
    var target_rcs = getRCS(targetCoord, targetHeading, targetPitch, targetRoll, myCoord, target_front_rcs);
    var target_distance = myCoord.direct_distance_to(targetCoord);

    # standard formula
    var currMaxDist = myRadarDistance_m/math.pow(myRadarStrength_rcs/target_rcs, 1/4);
    return currMaxDist > target_distance;
}

var getRCS = func (echoCoord, echoHeading, echoPitch, echoRoll, myCoord, frontRCS) {
    var sideRCSFactor  = 2.50;
    var rearRCSFactor  = 1.75;
    var bellyRCSFactor = 3.50;
    #first we calculate the 2D RCS:
    var vectorToEcho   = vector.Math.eulerToCartesian2(myCoord.course_to(echoCoord), vector.Math.getPitch(myCoord,echoCoord));
    var vectorEchoNose = vector.Math.eulerToCartesian3X(echoHeading, echoPitch, echoRoll);
    var vectorEchoTop  = vector.Math.eulerToCartesian3Z(echoHeading, echoPitch, echoRoll);
    var view2D         = vector.Math.projVectorOnPlane(vectorEchoTop,vectorToEcho);
    #print("top  "~vector.Math.format(vectorEchoTop));
    #print("nose "~vector.Math.format(vectorEchoNose));
    #print("view "~vector.Math.format(vectorToEcho));
    #print("view2D "~vector.Math.format(view2D));
    var angleToNose    = geo.normdeg180(vector.Math.angleBetweenVectors(vectorEchoNose, view2D)+180);
    #print("horz aspect "~angleToNose);
    var horzRCS = 0;
    if (math.abs(angleToNose) <= 90) {
      horzRCS = extrapolate(math.abs(angleToNose), 0, 90, frontRCS, sideRCSFactor*frontRCS);
    } else {
      horzRCS = extrapolate(math.abs(angleToNose), 90, 180, sideRCSFactor*frontRCS, rearRCSFactor*frontRCS);
    }
    #print("RCS horz "~horzRCS);
    #next we calculate the 3D RCS:
    var angleToBelly    = geo.normdeg180(vector.Math.angleBetweenVectors(vectorEchoTop, vectorToEcho));
    #print("angle to belly "~angleToBelly);
    var realRCS = 0;
    if (math.abs(angleToBelly) <= 90) {
      realRCS = extrapolate(math.abs(angleToBelly),  0,  90, bellyRCSFactor*frontRCS, horzRCS);
    } else {
      realRCS = extrapolate(math.abs(angleToBelly), 90, 180, horzRCS, bellyRCSFactor*frontRCS);
    }
    return realRCS;
};

var extrapolate = func (x, x1, x2, y1, y2) {
    return y1 + ((x - x1) / (x2 - x1)) * (y2 - y1);
};

var getAspect = func (echoCoord, myCoord, echoHeading) {# ended up not using this
    # angle 0 deg = view of front
    var course = echoCoord.course_to(myCoord);
    var heading_offset = course - echoHeading;
    return geo.normdeg180(heading_offset);
};