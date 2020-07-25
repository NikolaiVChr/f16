#
# Install: Include this code into an aircraft to make it damagable. (remember to add it to the -set file)
#
# Authors: Nikolai V. Chr. and Pinto (with improvement by Onox)
#
#


############################ Config ######################################################################################
var full_damage_dist_m = 1.5;# Can vary from aircraft to aircraft depending on how many failure modes it has.
                           # Many modes (like Viggen) ought to have lower number like zero.
                           # Few modes (like F-14) ought to have larger number such as 3.
                           # For assets this should be average radius of the asset.
var use_hitpoints_instead_of_failure_modes_bool = 0;# mainly used by assets that don't have failure modes.
var hp_max = 80;# given a direct hit, how much pounds of warhead is needed to kill. Only used if hitpoints is enabled.
var hitable_by_air_munitions = 1;   # if anti-air can do damage
var hitable_by_cannon = 1;          # if cannon can do damage
var hitable_by_ground_munitions = 1;# if anti-ground/marine can do damage
var is_fleet = 0;  # Is really 7 ships, 3 of which has offensive missiles.
##########################################################################################################################

##
## TODO:
##      Move all to emesary
##      


var TRUE  = 1;
var FALSE = 0;

var hp = hp_max;
setprop("sam/damage", math.max(0,100*hp/hp_max));#used in HUD

var cannon_types = {
    #
    # 0.20 means a direct hit will disable 20% of the failure modes on average.
    # or, 0.20 also means a direct hit can do 20 hitpoints damage.
    #
    " M70 rocket hit":        0.250, #135mm
    " S-5 rocket hit":        0.200, # 55mm
    " M55 cannon shell hit":  0.100, # 30mm
    " KCA cannon shell hit":  0.100, # 30mm
    " Gun Splash On ":        0.100, # 30mm
    " GSh-30 hit":            0.100, # 30mm
    " GAU-8/A hit":           0.100, # 30mm
    " Mk3Z hit":              0.100, # 30mm Jaguar
    " BK27 cannon hit":       0.070, # 27mm
    " GSh-23 hit":            0.065, # 23mm
    " M61A1 shell hit":       0.050, # 20mm
    " 50 BMG hit":            0.015, # 12.7mm (non-explosive)    
    " 7.62 hit":              0.005, # 7.62mm (non-explosive)
    " Hydra-70 hit":          0.250, # F-16
    " SNEB hit":              0.250, # Jaguar   
};    

# lbs of warheads is explosive+fragmentation+fuse, so total warhead mass.

var warhead_lbs = {
    # Anti-ground/marine warheads (sorted alphabetically)
    "AGM-65":              126.00,
    "AGM-84":              488.00,
    "AGM-88":              146.00,
    "AGM65":               200.00,
    "AGM-119":             264.50,
    "AGM-154A":            493.00,
    "AGM-158":            1000.00,
    "ALARM":               450.00,
    "AM39-Exocet":         364.00, 
    "AS-37-Martel":        330.00, 
    "AS30L":               529.00,
    "BL755":               100.00,# 800lb bomblet warhead. Mix of armour piecing and HE. 100 due to need to be able to kill buk-m2.    
    "CBU-87":              100.00,# bomblet warhead. Mix of armour piecing and HE. 100 due to need to be able to kill buk-m2.    
    "CBU-105":             100.00,# bomblet warhead. Mix of armour piecing and HE. 100 due to need to be able to kill buk-m2.    
    "Exocet":              364.00,
    "FAB-100":              92.59,
    "FAB-250":             202.85,
    "FAB-500":             564.38,
    "GBU-12":              190.00,
    "GBU-24":              945.00,
    "GBU-31":              945.00,
    "GBU-54":              190.00,
    "GBU12":               190.00,
    "GBU16":               450.00,
    "HVAR":                  7.50,#P51
    "KAB-500":             564.38,
    "Kh-25MP":             197.53,
    "Kh-66":               244.71,
    "LAU-68":               10.00,
    "M71":                 200.00,
    "M71R":                200.00,
    "M90":                  10.00,# bomblet warhead. x3 of real mass.
    "MK-82":               192.00,
    "MK-83":               445.00,
    "MK-83HD":             445.00,
    "MK-84":               945.00,
    "OFAB-100":             92.59,
    "RB-04E":              661.00,
    "RB-05A":              353.00,
    "RB-15F":              440.92,
    "RB-75":               126.00,
    "RN-14T":              800.00, #fictional, thermobaeric replacement for the RN-24 nuclear bomb
    "RN-18T":             1200.00, #fictional, thermobaeric replacement for the RN-28 nuclear bomb
    "RS-2US":               28.66,
    "S-21":                245.00,
    "S-24":                271.00,
    "SCALP":               992.00,
    "Sea Eagle":           505.00,
    "SeaEagle":            505.00,
    "STORMSHADOW":         850.00,
    "ZB-250":              236.99,
    "ZB-500":              473.99,
};

var warhead_air_lbs = {
    # Anti-air warheads (sorted alphabetically)
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
    "KN-06":               315.00,
    "M317":                145.00,
    "Magic-2":              27.00, 
    "Majic":                26.45,
    "Matra MICA":           30.00,
    "Matra R550 Magic 2":   27.00,
    "MATRA-R530":           55.00,
    "MatraMica":            30.00,
    "MatraMicaIR":          30.00,
    "MatraR550Magic2":      27.00,
    "Meteor":               55.00,
    "MICA-EM":              30.00, 
    "MICA-IR":              30.00, 
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
    "RB-05A":              353.00,
    "RB-24":                20.80,
    "RB-24J":               20.80,
    "RB-71":                88.00,
    "RB-74":                20.80,
    "RB-99":                44.00,
    "S530D":                66.00,
    "S48N6":               330.00,# 48N6 from S-300pmu
};

var cluster = {
    # cluster munition list
    "M90": nil,
    "CBU-87": nil,
    "CBU-105": nil,
    "BL755": nil,
};

var fireMsgs = {
  
    # F14
    " FOX3 at":       nil, # radar
    " FOX2 at":       nil, # heat
    " FOX1 at":       nil, # semi-radar

    # Generic
    " Fox 1 at":      nil, # semi-radar
    " Fox 2 at":      nil, # heat
    " Fox 3 at":      nil, # radar
    " Greyhound at":  nil, # cruise missile
    " Bombs away at": nil, # bombs
    " Bruiser at":    nil, # anti-ship
    " Rifle at":      nil, # TV guided
    " Sniper at":     nil, # anti-radiation

    # SAM, fleet and missile frigate
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
      }
      if (contains(fireMsgs, last_vector[1]) or m2000 == TRUE) {
        # air2air being fired
        warn(last_vector,m2000,callsign,author);
      } elsif (getprop("payload/armament/msg")) {
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

              if (contains(cluster, type)) {
                # cluster munition
                var lbs = warhead_lbs[type];
                var maxDist = maxDamageDistFromWarhead(lbs);
                var distance = math.max(0,rand()*5-full_damage_dist_m);#being 0 to 5 meters from a bomblet on average.
                var diff = math.max(0, maxDist-distance);
                diff = diff * diff;
                var probability = diff / (maxDist*maxDist);
                if (use_hitpoints_instead_of_failure_modes_bool) {
                  var hpDist = maxDamageDistFromWarhead(hp_max);
                  probability = (maxDist/hpDist)*probability;
                }
                var failed = fail_systems(probability, hp_max);
                var percent = 100 * probability;
                printf("Took %.1f%% damage from %s clusterbomb at %0.1f meters from bomblet. %s systems was hit", percent,type,distance,failed);
                nearby_explosion();
                return;
              }

              distance = math.max(distance-full_damage_dist_m, 0);
              
              var maxDist = 0;# distance where the explosion dont hurt us anymore
              var lbs = 0;
              
              if (hitable_by_ground_munitions and contains(warhead_lbs, type)) {
                lbs = warhead_lbs[type];
                maxDist = maxDamageDistFromWarhead(lbs);#3*sqrt(lbs)
              } elsif (hitable_by_air_munitions and contains(warhead_air_lbs, type)) {
                lbs = warhead_air_lbs[type];
                maxDist = maxDamageDistFromWarhead(lbs);
              } else {
                return;
              }
              
              var diff = maxDist-distance;
              if (diff < 0) {
                diff = 0;
              }
              diff = diff * diff;
                            
              var probability = diff / (maxDist*maxDist);
              
              if (use_hitpoints_instead_of_failure_modes_bool) {
                var hpDist = maxDamageDistFromWarhead(hp_max);
                probability = (maxDist/hpDist)*probability;
              }

              var failed = fail_systems(probability, hp_max);
              var percent = 100 * probability;
              printf("Took %.1f%% damage from %s missile at %0.1f meters. %s systems was hit", percent,type,dist,failed);
              nearby_explosion();
              
              ####
              # I don't remember all the considerations that went into our original warhead damage model.
              # But looking at the formula it looks like they all do 100% damage at 0 meter hit,
              # and warhead size is only used to determine the decrease of damage with distance increase.
              # It sorta gets the job done though, so I am hesitant to advocate that warheads above a certain
              # size should give 100% damage for some distance, and that warheads smaller than certain size should
              # not give 100% damage even on direct hit.
              # Anyway, for hitpoint based assets, this is now the case. Maybe we should consider to also do something
              # similar for failure mode based aircraft. ~Nikolai
              ####
              
              ## example 1: ##
              # 300 lbs warhead, 50 meters distance
              # maxDist=52
              # diff = 52-50 = 2
              # diff^2 = 4
              # prob = 4/2700 = 0.15%
              
              ## example 2: ##
              # 300 lbs warhead, 25 meters distance
              # maxDist=52
              # diff = 52-25 = 27
              # diff^2 = 729
              # prob = 729/2700 = 27%
            }
          }
        } elsif (hitable_by_cannon and cannon_types[last_vector[1]] != nil) {
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
  # Calc at what distance the warhead will do zero damage every time.
  var dist = 3*math.sqrt(lbs);
  return dist;
}

var fail_systems = func (probability, factor = 100) {#this factor needs tuning after all asset hitpoints have been evaluated.
    if (is_fleet) {
      return fail_fleet_systems(probability, factor);
    } elsif (use_hitpoints_instead_of_failure_modes_bool) {
      hp -= factor * probability*(0.75+rand()*0.25);# from 75 to 100% damage
      printf("HP: %d/%d", hp, hp_max);
      setprop("sam/damage", math.max(0,100*hp/hp_max));#used in HUD
      if ( hp < 0 ) {
        setprop("/carrier/sunk/",1);#we are dead
        setprop("/sim/multiplay/generic/int[2]",1);#radar off
        setprop("/sim/multiplay/generic/int[0]",1);#smoke on
        setprop("/sim/messages/copilot", getprop("sim/multiplay/callsign")~" dead.");
      }
      return -1;
    } else {
      var failure_modes = FailureMgr._failmgr.failure_modes;
      var mode_list = keys(failure_modes);
      var failed = 0;
      foreach(var failure_mode_id; mode_list) {
        #print(failure_mode_id);
          if (rand() < probability) {
              FailureMgr.set_failure_level(failure_mode_id, 1);
              failed += 1;
              if (failure_mode_id == "Engines/engine") {
                # fail UH1 yasim:
                setprop("sim/model/uh1/state",0);
                setprop("controls/engines/engine/magnetos", 0);
                #set a listener so that if a restart is attempted, it'll fail.
                yasim_list = setlistener("sim/model/uh1/state",func {setprop("sim/model/uh1/state",0);});
              }
          }
      }
      if (rand() < probability) {
          # fail UH1 yasim:
          setprop("sim/model/uh1/state",0);
          setprop("controls/engines/engine/magnetos", 0);
          #set a listener so that if a restart is attempted, it'll fail.
          if (yasim_list == nil) {
            yasim_list = setlistener("sim/model/uh1/state",func {setprop("sim/model/uh1/state",0);});
          }
      }
      return failed;
    }
};
var yasim_list = nil;

var repairYasim = func {
  if (yasim_list != nil) {
    removelistener(yasim_list);
    yasim_list = nil;
  }
  setprop("sim/crashed", 0);
  var failure_modes = FailureMgr._failmgr.failure_modes;
  var mode_list = keys(failure_modes);

    foreach(var failure_mode_id; mode_list) {
      FailureMgr.set_failure_level(failure_mode_id, 0);
    }
}

setlistener("/sim/signals/reinit", repairYasim);

hp_f = [hp_max,hp_max,hp_max,hp_max,hp_max,hp_max,hp_max];

var fail_fleet_systems = func (probability, factor) {
  var no = 7;
  while (no > 6 or hp_f[no] < 0) {
    no = int(rand()*7);
    if (hp_f[no] < 0) {
      if (rand() > 0.9) {
        armament.defeatSpamFilter("You shot one of our already sinking ships, you are just mean.");
        hp_f[no] -= factor * probability*(0.75+rand()*0.25);# from 75 to 100% damage
        print("HP["~no~"]: " ~ hp_f[no] ~ "/" ~ hp_max);
        return;
      }
    }
  }
  hp_f[no] -= factor * probability*(0.75+rand()*0.25);# from 75 to 100% damage
  printf("HP[%d]: %d/%d", no, hp_f[no], hp_max);
  #setprop("sam/damage", math.max(0,100*hp/hp_max));#used in HUD
  if ( hp_f[no] < 0 ) {
    setprop("/sim/multiplay/generic/bool["~(no+40)~"]",1);
    armament.defeatSpamFilter("So you sank one of our ships, we will get you for that!");
    if (!getprop("/carrier/disabled") and hp_f[0]<0 and hp_f[1]<0 and hp_f[2]<0) {
      setprop("/carrier/disabled",1);
      armament.defeatSpamFilter("Captain our offensive capability is crippled!");
    }
    if (hp_f[0]<0 and hp_f[1]<0 and hp_f[2]<0 and hp_f[3]<0 and hp_f[4]<0 and hp_f[5]<0 and hp_f[6]<0) {
      setprop("/carrier/sunk",1);
      setprop("/sim/multiplay/generic/int[2]",1);#radar off
      setprop("/sim/messages/copilot", getprop("sim/multiplay/callsign")~" dead.");
      armament.defeatSpamFilter("S.O.S. Heeelp");
    } else {
      armament.defeatSpamFilter("This is not over yet..");
    }    
  }
  return -1;
};

var warn = func (last_vector,m2000,callsign,author) {
  if (size(last_vector) > 2 or m2000 == TRUE) {
    #print("Missile launch detected at"~last_vector[2]~" from "~author);
    if (m2000 == TRUE or last_vector[2] == " "~callsign) {
      # its being fired at me
      #print("Incoming!");
      var enemy = getCallsign(author);
      var sam = size(last_vector) > 2 and last_vector[1] == " Bird away at"?1:0;
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
          setLaunch(author, sam);
          return;
        }
      }
    }
  }
}

var playIncomingSound = func (clock) {
  setprop("sound/incoming"~clock, 1);
  settimer(func {stopIncomingSound(clock);},3);
}

var stopIncomingSound = func (clock) {
  setprop("sound/incoming"~clock, 0);
}

var setLaunch = func (c,s) {
  setprop("sound/rwr-launch-sam", s);
  setprop("sound/rwr-launch", c);
  settimer(func {stopLaunch();},7);
}

var stopLaunch = func () {
  setprop("sound/rwr-launch", "");
  setprop("sound/rwr-launch-sam", 0);
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

var callsign_struct = {};
var getCallsign = func (callsign) {
  var node = callsign_struct[callsign];
  return node;
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
  settimer(processCallsigns, 5);
}

processCallsigns();

setlistener("/sim/multiplay/chat-history", incoming_listener, 0, 0);

# prevent flooding the pilots screen with failure modes that fail when getting hit.
setprop("/sim/failure-manager/display-on-screen", FALSE);

var re_init = func {
  # repair the aircraft at relocation to another airport.

  var failure_modes = FailureMgr._failmgr.failure_modes;
  var mode_list = keys(failure_modes);

  foreach(var failure_mode_id; mode_list) {
    FailureMgr.set_failure_level(failure_mode_id, 0);
  }
}

#setlistener("/sim/signals/reinit", re_init, 0, 0);
