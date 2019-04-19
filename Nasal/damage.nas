#
# Install: Include this code into an aircraft to make it damagable. (remember to add it to the -set file)
#
# Author: Nikolai V. Chr. (with some improvement by Onox and Pinto)
#
#


var clamp = func(v, min, max) { v < min ? min : v > max ? max : v }

var TRUE  = 1;
var FALSE = 0;


var cannon_types = {
    " M70 rocket hit":        0.25, #135mm
    " M55 cannon shell hit":  0.10, # 30mm
    " KCA cannon shell hit":  0.10, # 30mm
    " Gun Splash On ":        0.10, # 30mm
    " M61A1 shell hit":       0.05, # 20mm
    " GAU-8/A hit":           0.10, # 30mm
    " BK27 cannon hit":       0.07, # 27mm
    " GSh-30 hit":            0.10, # 30mm
    " GSh-23 hit":            0.065,# 23mm
    " 7.62 hit":              0.005,# 7.62mm
    " 50 BMG hit":            0.015,# 12.7mm
    " S-5 rocket hit":        0.20, #55mm
};
    
    
    
var warhead_lbs = {
    "AGM-65":              126.00,
    "AGM-84":              488.00,
    "AGM-88":              146.00,
    "AGM65":               200.00,
    "AGM-154A":            493.00,
    "AGM-158":            1000.00,
    "aim-120":              44.00,
    "AIM-120":              44.00,
    "AIM-54":              135.00,
    "aim-7":                88.00,
    "AIM-7":                88.00,
    "aim-9":                20.80,
    "AIM-9":                20.80,
    "AIM120":               44.00,
    "AIM132":               22.05,
    "AIM9":                 20.80,
    "ALARM":               450.00,
    "AM39-Exocet":         364.00, 
    "AS-37-Martel":        330.00, 
    "AS30L":               529.00,
    "CBU-87":			   128.00,
    "Exocet":              364.00,
    "FAB-100":              92.59,
    "FAB-250":             202.85,
    "FAB-500":             564.38,
    "GBU-12":              190.00,
    "GBU-24":              945.00,
    "GBU-31":              945.00,
    "GBU-54":              192.00,
    "GBU12":               190.00,
    "GBU16":               450.00,
    "HVAR":                  7.50,#P51
    "KAB-500":             564.38,
    "KH-25MP":             197.53,
    "Kh-66":               244.71,
    "KN-06":               315.00,
    "LAU-68":               10.00,
    "M317":                145.00,
    "M71":                 200.00,
    "M71R":                200.00,
    "M90":                 500.00,
    "Magic-2":              27.00, 
    "Matra MICA":           30.00,
    "Matra R550 Magic 2":   27.00,
    "MATRA-R530":           55.00,
    "MatraMica":            30.00,
    "MatraMicaIR":          30.00,
    "MatraR550Magic2":      27.00,
    "Meteor":               55.00,
    "MICA-EM":              30.00, 
    "MICA-IR":              30.00, 
    "MK-82":               192.00,
    "MK-83":               445.00,
    "MK-84":               945.00,
    "OFAB-100":             92.59,
    "R-13M":                16.31,
    "R-27R1":               85.98,
    "R-27T1":               85.98,
    "R-3R":                 16.31,
    "R-3S":                 16.31,
    "R-55":                 20.06,
    "R-60":                  6.60,
    "R-60M":                 7.70,
    "R-73E":                16.31,
    "R-77":                 49.60,
    "R74":                  16.00,
    "RB-04E":              661.00,
    "RB-05A":              353.00,
    "RB-15F":              440.92,
    "RB-24":                20.80,
    "RB-24J":               20.80,
    "RB-71":                88.00,
    "RB-74":                20.80,
    "RB-75":               126.00,
    "RB-99":                44.00,
    "RN-14T":              800.00, #fictional, thermobaeric replacement for the RN-24 nuclear bomb
    "RN-18T":             1200.00, #fictional, thermobaeric replacement for the RN-28 nuclear bomb
    "RS-2US":               28.66,
    "S-21":                245.00,
    "S-24":                271.00,
    "S530D":                66.00, 
    "SCALP":               992.00,
    "Sea Eagle":           505.00,
    "SeaEagle":            505.00,
    "STORMSHADOW":         850.00,
    "ZB-250":              236.99,
    "ZB-500":              473.99,
};

var fireMsgs = {
  
    # F14
    " FOX3 at":       nil, # radar
    " FOX2 at":       nil, # heat
    " FOX1 at":       nil, # semi-radar

    # Viggen
    " Fox 1 at":      nil, # semi-radar
    " Fox 2 at":      nil, # heat
    " Fox 3 at":      nil, # radar
    " Greyhound at":  nil, # cruise missile
    " Bombs away at": nil, # bombs
    " Bruiser at":    nil, # anti-ship
    " Rifle at":      nil, # TV guided
    " Sniper at":     nil, # anti-radiation

    # SAM and missile frigate
    " Bird away at":  nil, # G/A

    # F15
    " aim7 at":       nil,
    " aim9 at":       nil,
    " aim120 at":     nil,
};

var incoming_listener = func {
  var history = getprop("/sim/multiplay/chat-history");
  var hist_vector = split("\n", history);
  if (size(hist_vector) > 0) {
    var last = hist_vector[size(hist_vector)-1];
    var last_vector = split(":", last);
    var author = last_vector[0];
    var callsign = getprop("sim/multiplay/callsign");
    callsign = size(callsign) < 8 ? callsign : left(callsign,7);
    if (size(last_vector) > 1 and author != callsign) {
      # not myself
      #print("not me");
      var m2000 = FALSE;
      if (find(" at " ~ callsign ~ ". Release ", last_vector[1]) != -1) {
        # a m2000 is firing at us
        m2000 = TRUE;
      } elsif (find(" Maddog released", last_vector[1]) != -1) {
        m2000 = TRUE;
      }
      if (contains(fireMsgs, last_vector[1]) or m2000 == TRUE) {
        # air2air being fired
        if (size(last_vector) > 2 or m2000 == TRUE) {
          #print("Missile launch detected at"~last_vector[2]~" from "~author);
          if (m2000 == TRUE or last_vector[2] == " "~callsign) {
            # its being fired at me
            #print("Incoming!");
            var enemy = getCallsign(author);
            if (enemy != nil) {
              #print("enemy identified");
              var bearingNode = enemy.getNode("radar/bearing-deg");
              if (bearingNode != nil) {
                #print("bearing to enemy found");
                var bearing = bearingNode.getValue();
                var heading = getprop("orientation/heading-deg");
                var clock = bearing - heading;
                while(clock < 0) {
                  clock = clock + 360;
                }
                while(clock > 360) {
                  clock = clock - 360;
                }
                #print("incoming from "~clock);
                if (clock >= 345 or clock < 15) {
                  playIncomingSound("12");
                } elsif (clock >= 15 and clock < 45) {
                  playIncomingSound("1");
                } elsif (clock >= 45 and clock < 75) {
                  playIncomingSound("2");
                } elsif (clock >= 75 and clock < 105) {
                  playIncomingSound("3");
                } elsif (clock >= 105 and clock < 135) {
                  playIncomingSound("4");
                } elsif (clock >= 135 and clock < 165) {
                  playIncomingSound("5");
                } elsif (clock >= 165 and clock < 195) {
                  playIncomingSound("6");
                } elsif (clock >= 195 and clock < 225) {
                  playIncomingSound("7");
                } elsif (clock >= 225 and clock < 255) {
                  playIncomingSound("8");
                } elsif (clock >= 255 and clock < 285) {
                  playIncomingSound("9");
                } elsif (clock >= 285 and clock < 315) {
                  playIncomingSound("10");
                } elsif (clock >= 315 and clock < 345) {
                  playIncomingSound("11");
                } else {
                  playIncomingSound("");
                }
                setLaunch(author);
                return;
              }
            }
          }
        }
      } elsif (getprop("payload/armament/msg")) { # mirage: getprop("/controls/armament/mp-messaging")
        # latest version of failure manager and taking damage enabled
        #print("damage enabled");
        var last1 = split(" ", last_vector[1]);
        if(size(last1) > 2 and last1[size(last1)-1] == "exploded" ) {
          #print("missile hitting someone");
          if (size(last_vector) > 3 and last_vector[3] == " "~callsign) {
            #print("that someone is me!");
            var type = last1[1];
            if (type == "Matra" or type == "Sea") {
              for (var i = 2; i < size(last1)-1; i += 1) {
                type = type~" "~last1[i];
              }
            }
            var number = split(" ", last_vector[2]);
            var distance = num(number[1]);
            #print(type~"|");
            if(distance != nil) {
              var dist = distance;

              if (type == "M90") {
                var prob = rand()*0.5;
                var failed = fail_systems(prob);
                var percent = 100 * prob;
                printf("Took %.1f%% damage from %s clusterbombs at %0.1f meters. %s systems was hit", percent,type,dist,failed);
                nearby_explosion();
                return;
              }

              distance = clamp(distance-3, 0, 1000000);
              var maxDist = 0;

              if (contains(warhead_lbs, type)) {
                maxDist = maxDamageDistFromWarhead(warhead_lbs[type]);
              } else {
                return;
              }

              var diff = maxDist-distance;
              if (diff < 0) {
                diff = 0;
              }
              
              diff = diff * diff;
              
              var probability = diff / (maxDist*maxDist);

              var failed = fail_systems(probability);
              var percent = 100 * probability;
              printf("Took %.1f%% damage from %s missile at %0.1f meters. %s systems was hit", percent,type,dist,failed);
              nearby_explosion();
            }
          } 
        } elsif (cannon_types[last_vector[1]] != nil) {
          if (size(last_vector) > 2 and last_vector[2] == " "~callsign) {
            if (size(last_vector) < 4) {
              # msg is either missing number of hits, or has no trailing dots from spam filter.
              print('"'~last~'"   is not a legal hit message, tell the shooter to upgrade his OPRF plane :)');
              return;
            }
            var last3 = split(" ", last_vector[3]);
            if(size(last3) > 2 and size(last3[2]) > 2 and last3[2] == "hits" ) {
              var probability = cannon_types[last_vector[1]];
              var hit_count = num(last3[1]);
              if (hit_count != nil) {
                var damaged_sys = 0;
                for (var i = 1; i <= hit_count; i = i + 1) {
                  var failed = fail_systems(probability);
                  damaged_sys = damaged_sys + failed;
                }

                printf("Took %.1f%% x %2d damage from cannon! %s systems was hit.", probability*100, hit_count, damaged_sys);
                nearby_explosion();
              }
            } else {
              var probability = cannon_types[last_vector[1]];
              #print("probability: " ~ probability);
              
              var failed = fail_systems(probability * 3);# Old messages is assumed to be 3 hits
              printf("Took %.1f%% x 3 damage from cannon! %s systems was hit.", probability*100, failed);
              nearby_explosion();
            }
          }
        }
      }
    }
  }
}

var maxDamageDistFromWarhead = func (lbs) {
  # very simple
  var dist = 3*math.sqrt(lbs);

  return dist;
}

var fail_systems = func (probability) {
    var failure_modes = FailureMgr._failmgr.failure_modes;
    var mode_list = keys(failure_modes);
    var failed = 0;
    foreach(var failure_mode_id; mode_list) {
        if (rand() < probability) {
            FailureMgr.set_failure_level(failure_mode_id, 1);
            failed += 1;
        }
    }
    return failed;
};

var playIncomingSound = func (clock) {
  setprop("sound/incoming"~clock, 1);
  settimer(func {stopIncomingSound(clock);},3);
}

var stopIncomingSound = func (clock) {
  setprop("sound/incoming"~clock, 0);
}

var setLaunch = func (e) {
  setprop("sound/rwr-launch", e);
  settimer(func {stopLaunch();},7);
}

var stopLaunch = func () {
  setprop("sound/rwr-launch", "");
}

var callsign_struct = {};
var getCallsign = func (callsign) {
  var node = callsign_struct[callsign];
  return node;
}

var nearby_explosion = func {
  setprop("damage/sounds/nearby-explode-on", 0);
  settimer(nearby_explosion_a, 0);
}

var nearby_explosion_a = func {
  setprop("damage/sounds/nearby-explode-on", 1);
  settimer(nearby_explosion_b, 0.5);
}

var nearby_explosion_b = func {
  setprop("damage/sounds/nearby-explode-on", 0);
}

var processCallsigns = func () {
  callsign_struct = {};
  var players = props.globals.getNode("ai/models").getChildren();
  foreach (var player; players) {
    if(player.getChild("valid") != nil and player.getChild("valid").getValue() == TRUE and player.getChild("callsign") != nil and player.getChild("callsign").getValue() != "" and player.getChild("callsign").getValue() != nil) {
      var callsign = player.getChild("callsign").getValue();
      callsign_struct[callsign] = player;
    }
  }
  settimer(processCallsigns, 1.5);
}

processCallsigns();

setlistener("/sim/multiplay/chat-history", incoming_listener, 0, 0);

setprop("/sim/failure-manager/display-on-screen", FALSE);

var re_init = func {
  # repair the aircraft

  var failure_modes = FailureMgr._failmgr.failure_modes;
  var mode_list = keys(failure_modes);

  foreach(var failure_mode_id; mode_list) {
    FailureMgr.set_failure_level(failure_mode_id, 0);
  }
}

#setlistener("/sim/signals/reinit", re_init, 0, 0);