 #
# F-16 Steerpoint/route/mark/bulls-eye system.
#
var lines = [nil,nil];

var desired_tos = {};

var number_of_threat_circles  = 15;
var number_of_generic         = 10;
var number_of_markpoints_own  = 5;
var number_of_markpoints_dlnk = 5;

var index_of_threat_circles   = 300;
var index_of_generic          = 350;
var index_of_markpoints_own   = 400;
var index_of_markpoints_dlnk  = 450;
var index_of_weapon_gps       = 500;
var index_of_bullseye         = 555;
var index_of_lines_1          = 100;
var index_of_lines_1          = 200;

var stpt300 = setsize([],number_of_threat_circles);#Threat circles
var stpt350 = setsize([],10);#Generic
var stpt400 = setsize([],5);#Markpoints Own
var stpt450 = setsize([],5);#Markpoints DL
var stpt500 = setsize([],1);#Weapon
var stpt555 = setsize([],1);#Bullseye
var current = nil;#Current STPT number, nil for route/nothing.

var colorRed = 0;
var colorYellow = 1;
var colorGreen = 2;

var autoMode = 1;# if change this then also change f16/ded/stpt-auto

var STPT = {
	# stored in the above vectors for non-route steerpoints
	lon: 0,
	lat: 0,
	alt: 0,
	type: "   ",
	radius: 10,
	color: colorYellow,
	
	new: func {
		var n = {parents: [STPT]};
		return n;
	},

	copy: func {
		var cp = STPT.new();
		cp.lat = me.lat;
		cp.lon = me.lon;
		cp.alt = me.alt;
		cp.type = me.type;
		cp.radius = me.radius;
		cp.color = me.color;
		return cp;
	},
};



var getCurrentNumber = func {
	# Get current steerpoint. The first is #1. Return 0 for no current steerpoint.
	if (current != nil) {
		return current;
	} elsif (isRouteActive()) {
		var fp = flightplan();
		return fp.current + 1;
	}
	return 0;
}

var getLastNumber = func {
	# Get the steerpoint # for the final steerpoint in current route or for non-route get the current.
	if (current != nil) {
		return current;
	} elsif (isRouteActive()) {
		var fp = flightplan();
		return fp.getPlanSize();
	}
	return 0;
}

var getNumber = func (number) {
	# Return a specific steerpoint, nil if none
	if (!_isOccupiedNumber(number)) {
		return nil;
	}
	if (number == 555) {
		return stpt555[0];
	}
	if (number == 500) {
		return stpt500[0];
	}
	if (number >= 450) {
		return stpt450[number-450];
	}
	if (number >= 400) {
		return stpt400[number-400];
	}
	if (number >= 350) {
		return stpt350[number-350];
	}
	if (number >= 300) {
		return stpt300[number-300];
	}
	if (number >= 200 and lines[1] != nil) {
		var fp = lines[1];
		var leg = fp.getWP(number-200);
		var new = STPT.new();
		new.lat = leg.lat;
		new.lon = leg.lon;
		if (leg.alt_cstr != nil) {
			new.alt = leg.alt_cstr;
		}
		return new;
	}
	if (number >= 100 and lines[0] != nil) {
		var fp = lines[0];
		var leg = fp.getWP(number-100);
		var new = STPT.new();
		new.lat = leg.lat;
		new.lon = leg.lon;
		if (leg.alt_cstr != nil) {
			new.alt = leg.alt_cstr;
		}
		return new;
	}
	if (number < 100 and isRouteActive()) {
		var fp = flightplan();
		var leg = fp.getWP(number-1);
		var new = STPT.new();
		new.lat = leg.lat;
		new.lon = leg.lon;
		if (leg.alt_cstr != nil) {
			new.alt = leg.alt_cstr;
		}
		return new;
	}
	return nil;
}

var setNumber = func (number, stpt) {
	# Store a non-route steerpoint in memory
	if (!_isValidNumber(number)) {
		return 0;
	}
	if (number == 555) {
		stpt555[0] = stpt;
		return 1;
	}
	if (number == 500) {
		stpt500[0] = stpt;
		return 1;
	}
	if (number >= 450) {
		stpt450[number-450] = stpt;
		return 1;
	}
	if (number >= 400) {
		stpt400[number-400] = stpt;
		return 1;
	}
	if (number >= 350) {
		stpt350[number-350] = stpt;
		return 1;
	}
	if (number >= 300) {
		stpt300[number-300] = stpt;
		return 1;
	}
	if (number < 300) {
		return 0;
	}
	return 0;
}

var getCurrentDirection = func {
	# Get directions to current steerpoint or [nil,nil] for none.
	if (getCurrentNumber() != 0) {
		var cc = getCurrentCoord();
		return [geo.aircraft_position().course_to(cc), vector.Math.getPitch(geo.aircraft_position(), cc)];
	} else {
		return [nil, nil];
	}
}

var getCurrentDirectionForHUD = func {
	# Get directions to current steerpoint or [nil,nil] for none.
	if (getCurrentNumber() != 0) {
		var cc = getCurrentCoordForHUD();
		return [geo.aircraft_position().course_to(cc), vector.Math.getPitch(geo.aircraft_position(), cc)];
	} else {
		return [nil, nil];
	}
}

var getCurrentRange = func {
	# Return range in nm to current steerpoint.
	if (getCurrentNumber() == 0) return nil;
	var s = getCurrentCoord();	
	return s.distance_to(geo.aircraft_position())*M2NM;
}

var getCurrentGroundPitch = func {
	#if (getCurrentNumber() != 0) {
		var gCoord = getCurrentGroundCoord();
		if (gCoord != nil) {
			return vector.Math.getPitch(geo.aircraft_position(), gCoord);
		}
	#}
	return nil;
}

var getCurrentSlantRange = func {
	# Return slant range in nm to current steerpoint.
	if (getCurrentNumber() == 0) return nil;
	var s = getCurrentCoord();	
	return s.direct_distance_to(geo.aircraft_position())*M2NM;
}

var getCurrentETA = func {
	# Return seconds till current steerpoint.
	if (getCurrentNumber() == 0) return nil;
	var gs = getprop("velocities/groundspeed-kt")*KT2MPS;
	if (gs == 0) return nil;
	if (current == nil) {
		return getprop("autopilot/route-manager/wp/eta-seconds");
	}
	var range = getCurrentRange()*NM2M;
	return range/gs;
}

var getCurrentCoord = func {
	# returns current steerpoint as geo.Coord
	var s = getNumber(getCurrentNumber());
	if (s == nil) return nil;
	return stpt2coord(s);
}

var getCurrentCoordForHUD = func {
	# returns current steerpoint as geo.Coord
	var s = getNumber(getCurrentNumber());
	return stpt2coordGrounded(s);
}

var getCurrentGroundCoord = func {
	# returns current steerpoint as geo.Coord
	var s = getNumber(getCurrentNumber());
	if (s == nil) return nil;
	var elev = geo.elevation(s.lat, s.lon);
	if (elev == nil) {
		if (s.alt != nil) {
			elev = s.alt * FT2M;
		} else {
			return nil;
		}
	}
	var p = geo.Coord.new();
    p.set_latlon(s.lat, s.lon, elev);
	
	return p;
}

var setCurrentNumber = func (number) {
	# Set current steerpoint number.
	if (number < 100 and isRouteActive() and number > 0) {
		var fp = flightplan();
		if (fp.getPlanSize() >= number) {
			fp.current = number - 1;
			current = nil;
			print("Switching active steerpoint to #"~number);
			return 1;
		}
	} elsif (_isOccupiedNumber(number)) {
		current = number;
		print("Switching active steerpoint to #"~number);
		return 1;
	}
	return 0;
}

var getCurrent = func {
	# return current steerpoint or nil
	return getNumber(getCurrentNumber());
}

var getLastRange = func {
	# Get nm range to final steerpoint in current route or to current steerpoint for non-route.
	if (getCurrentNumber() == 0) return nil;
	if (current == nil) {
		var fp = flightplan();
		var dist_nm = steerpoints.getCurrentRange();
		var stnum = getCurrentNumber();
		for (var index = stnum; index < fp.getPlanSize(); index+=1) {
			dist_nm += fp.getWP(index).leg_distance;
		}
		return dist_nm;
	} else {
		return steerpoints.getCurrentRange();
	}
}

var getNumberRange = func (number) {
	# Get range to specific steerpoint
	if (getCurrentNumber() == 0) return nil;
	if (current == nil and number >= getCurrentNumber()) {
		var dist_nm = steerpoints.getCurrentRange();
		var stnum = getCurrentNumber();
		for (var index = stnum; index < number-1; index+=1) {
			dist_nm += flightplan().getWP(index).leg_distance;
		}
		return dist_nm;
	} elsif (number == getCurrentNumber()) {
		return steerpoints.getCurrentRange();
	}
	return nil;
}

var getLast = func {
	# Return final steerpoint
	if (getCurrentNumber() == 0) return nil;
	return getNumber(getLastNumber());
}

var getRequiredSpeed = func (number) {
    # Get required groundspeed in kts for TOS on specific steerpoint
    if (getCurrentNumber() == 0) return nil;
    var range = getNumberRange(number)*NM2M;
    var des_tos = _getNumberDesiredTOS(number);
    #var des_tos = getprop("f16/ded/crus-des-tos");
    if (des_tos == nil) {
       des_tos = 0;
    }
    # Subtract current time from TOS to get relative time
    #if (des_tos > addSeconds(0, getprop("sim/time/utc/hour"),getprop("sim/time/utc/minute"),getprop("sim/time/utc/second"))) {
        # Desired TOS is in the past, this shouldn't really matter, since we have a min of 70kts
    #}
    var cur_sec = (((getprop("sim/time/utc/hour")*60)+getprop("sim/time/utc/minute"))*60)+getprop("sim/time/utc/second")+math.fmod(getprop("sim/time/steady-clock-sec"), 1);
    #var tos_sec = addSeconds(des_tos, -getprop("sim/time/utc/hour"),-getprop("sim/time/utc/minute"),-getprop("sim/time/utc/second"));
    #tos_sec = (((tos_sec[1]*60)+tos_sec[2])*60)+tos_sec[3];

    # MLU M1: if STPT not reached in time, airspeed caret remains at max
    if (cur_sec > des_tos) {
        return 1700;
    }
    var tos_sec = des_tos - cur_sec;
    var req_spd = range / tos_sec / KT2MPS;
    # As per MLU M1, the speed is limited between 70kts and 1700kts
    return math.max(math.min(req_spd, 1700), 70);
}

var getLastETA = func {
	# Get time in seconds till final steerpoint
	if (getCurrentNumber() == 0) return nil;
	var gs = getprop("velocities/groundspeed-kt")*KT2MPS;
	if (gs == 0) return nil;
	var range = getLastRange()*NM2M;
	return range/gs;
}

var getNumberETA = func (number) {
	# Get time in seconds till specific steerpoint
	if (getCurrentNumber() == 0) return nil;
	var gs = getprop("velocities/groundspeed-kt")*KT2MPS;
	if (gs == 0) return nil;
	var range = getNumberRange(number)*NM2M;
	return range/gs;
}

var setNumberDesiredTOS = func (number, tos) {
    if (tos == -1) {
        tos = nil;
    }
    desired_tos[number] = tos;
    return;
}

var _getNumberDesiredTOS = func (number) {
    if (getCurrentNumber() == 0) return nil;
    return desired_tos[number];
}

var serializeTOS = func (number) {
    var result = _getNumberDesiredTOS(number);
    if (result == nil) {
        result = -1;
    }
    return result;
}

var getNumberDesiredTOS = func (number) {
    # Get string with desired time over steerpoint for specific steerpoint
    var val = _getNumberDesiredTOS(number);
	return _getTOS(val);
}

var getNumberTOS = func (number) {
	# Get string with time on station for specific steerpoint
	if (getCurrentNumber() == 0) return nil;
	var eta = getNumberETA(number);
	return _getTOS(eta);
}

var _getCurrentDesiredTOS = func {
    return _getNumberDesiredTOS(getCurrentNumber());
}

var getCurrentDesiredTOS = func {
	# Get string with desired time over steerpoint for current steerpoint
	return getNumberDesiredTOS(getCurrentNumber());
}

var setCurrentDesiredTOS = func (tos) {
	# Get string with desired time over steerpoint for current steerpoint
	return setNumberDesiredTOS(getCurrentNumber(), tos);
}

var getCurrentRequiredSpeed = func {
    return getRequiredSpeed(getCurrentNumber());
}

var getAbsoluteTOS = func (eta) {
    return _getTOS(eta, 1);
}

var getCurrentTOS = func {
	# Get string with time on station for current steerpoint
	var eta = getCurrentETA();
	return _getTOS(eta);
}

var getLastTOS = func {
	# Get string with time on station for final steerpoint
	var eta = getLastETA();
	return _getTOS(eta);
}

var _getTOS = func (eta, absolute = 0) {
	# Get string with time on station for a specific time in seconds
	# eta is allowed to be nil
	# if absolute the eta is assumed to be an exact time, otherwise eta is assumed to be relative to current time
	var TOS = "--:--:--";
	if (getCurrentNumber() == 0) return TOS;

	if (eta == nil or eta>3600*24 or eta == -1) {
		return TOS;
	} else {
	    if (!absolute) {
            var hour   = getprop("sim/time/utc/hour");
            var minute = getprop("sim/time/utc/minute");
            var second = getprop("sim/time/utc/second");
        } else {
            var hour   = 0;
            var minute = 0;
            var second = 0;
        }
        var final = addSeconds(eta,second,minute,hour);

		TOS = sprintf("%02d:%02d:%02d",final[1],final[2],final[3]);
	}      
	return TOS;
}

var addSeconds = func (add_secs, secs, mins, hours) {
	# Add some seconds to 24 hr clock

	# the baseline:
	var d = 0;
	var h = hours;
	var m = mins;
	var s = secs;

	# the added:
	var H = int(add_secs/3600);
    var S = add_secs-H*3600;
    var M = int(S/60);
    S = S-M*60;

    s += S;
    var addOver = 0;
	while (s > 59) {
		addOver += 1;
		s -= 60;
	}

	m += M+addOver;
	addOver = 0;
	while (m > 59) {
		addOver += 1;
		m -= 60;
	}

	h += H+addOver;
	while (h > 23) {
		addOver += 1;
		h -= 24;
	}

	d = addOver;

    return [d,h,m,s];
}

var next = func {
	# Advance steerpoint
	if (current != nil) return;
	var active = isRouteActive();
    var wp = getprop("autopilot/route-manager/current-wp");
    var max = getprop("autopilot/route-manager/route/num");
  
    if (active) {
		wp += 1;
		if (wp>max-1) {
			wp = 0;
		}
		setprop("autopilot/route-manager/current-wp", wp);
	}
}

var prev = func {
	# Decrease steerpoint
	if (current != nil) return;
	var active = isRouteActive();
    var wp = getprop("autopilot/route-manager/current-wp");
    var max = getprop("autopilot/route-manager/route/num");
  
    if (active) {
		wp -= 1;
		if (wp<0) {
			wp = max-1;
		}
		setprop("autopilot/route-manager/current-wp", wp);
    }
}

var copy = func (from, to) {
	# Copy steerpoint. Cannot copy TO route or lines steerpoints.
	var fStpt = getNumber(from);
	if (fStpt != nil and _isValidNumber(to)) {
		var tStpt = fStpt.copy();
		setNumber(to, tStpt);
		print("Copying steerpoint #"~from~" to #"~to);
	} else {
		print("STPT copy unsuccesful.");
	}
}

var sendCurrent = func {
	# Send current steerpoint over DLNK
	return send(getCurrentNumber());
}

var stpt2coord = func (stpt) {
	# Convert steerpoint to geo.Coord
	var p = geo.Coord.new();
    p.set_latlon(stpt.lat, stpt.lon, stpt.alt*FT2M);
    return p;
}

var stpt2coordGrounded = func (stpt) {
	# Convert steerpoint to geo.Coord but not lower than ground
	var p = geo.Coord.new();
	var elev = stpt.alt*FT2M;
	if (elev <= 0) {
		elev = geo.elevation(stpt.lat, stpt.lon);
		if (elev == nil) {
			elev = 0;
		}
	}
    p.set_latlon(stpt.lat, stpt.lon, elev);
    return p;
}

var send = func (number) {
	# Send specific steerpoint over DLNK
	var s = getNumber(number);
	if (s != nil and sending == nil) {
		var p = stpt2coord(s);
	    sending = p;
	    datalink.send_data({"point": sending});
	    settimer(func {sending = nil;},7);
	    print("Sending steerpoint to #"~number~" to DLNK.");
	    return 1;
	}
	return 0;
}

var markOFLY = func {
	# Create an OLFY markpoint
	var mark = STPT.new();
	mark.lat = getprop("/position/latitude-deg");
	mark.lon = getprop("/position/longitude-deg");
	mark.alt = getprop("/position/altitude-ft");
	addOwnMark(mark);
}

var markTGP = func (coord) {
	# Create a TGP markpoint
	var mark = STPT.new();
	mark.lat = coord.lat();
	mark.lon = coord.lon();
	mark.alt = coord.alt()*M2FT;
	return addOwnMark(mark);
}

var ownMarkIndex = 4;

var addOwnMark = func (mark) {
	# Store a mark
	ownMarkIndex += 1;
	if (ownMarkIndex > 4) ownMarkIndex = 0;
	stpt400[ownMarkIndex] = mark;	
	return ownMarkIndex+400;
}

var dlMarkIndex = 4;

var addDLMark = func (mark) {
	# STore a DLNK mark
	dlMarkIndex += 1;
	if (dlMarkIndex > 4) dlMarkIndex = 0;
	stpt450[dlMarkIndex] = mark;	
	return dlMarkIndex+450;
}

var applyToWPN = func {
	# Apply WPN steerpoint to current weapon
	var lat = getprop("f16/avionics/gps-lat");
	var lon = getprop("f16/avionics/gps-lon");
	var alt = getprop("f16/avionics/gps-alt")*FT2M;
	if (lat < 90 and lat > -90 and lon < 180 and lon > -180 and pylons.fcs != nil) {
		var wp = pylons.fcs.getSelectedWeapon();
		if (wp != nil and wp.parents[0] == armament.AIM and wp.target_pnt == 1 and wp.guidance=="gps") {
			var coord = geo.Coord.new();
			coord.set_latlon(lat,lon,alt);
			var spot = radar_system.ContactTGP.new("GPS-Spot",coord,0);
			armament.contactPoint = spot;
			tgp.gps = 1;
			if (getprop("f16/stores/tgp-mounted") and 0) {
				tgp.flir_updater.click_coord_cam = armament.contactPoint.get_Coord();
				callsign = armament.contactPoint.getUnique();
                setprop("/aircraft/flir/target/auto-track", 1);
                flir_updater.offsetP = 0;
                flir_updater.offsetH = 0;
				setprop("f16/avionics/tgp-lock", 1);
			}
			wp.setContacts([spot]);
		}
	}
}

var _isValidNumber = func (number) {
	# Is the number a valid possible steerpoint number?
	if (number >= 300 and number < 300+number_of_threat_circles) {
		return 1;
	} elsif (number >= 350 and number <= 359) {
		return 1;
	} elsif (number >= 400 and number <= 404) {
		return 1;
	} elsif (number >= 450 and number <= 454) {
		return 1;
	} elsif (number == 500) {
		return 1;
	} elsif (number == 555) {
		return 1;
	} elsif (number >= 1 and number < 300) {
		return 1;
	}
	return 0;
}

var _isOccupiedNumber = func (number) {
	# Is a steerpoint stored at this memory address?
	if (!_isValidNumber(number)) {
		return 0;
	}
	if (number == 555) {
		return stpt555[0] != nil;
	}
	if (number == 500) {
		return stpt500[0] != nil;
	}
	if (number >= 450) {
		return stpt450[number-450] != nil;
	}
	if (number >= 400) {
		return stpt400[number-400] != nil;
	}
	if (number >= 350) {
		return stpt350[number-350] != nil;
	}
	if (number >= 300) {
		return stpt300[number-300] != nil;
	}
	if (number < 300 and number >= 200 and lines[1] != nil) {
		var fp = lines[1];
		return fp.getPlanSize() > number-200;
	}
	if (number < 200 and number >= 100 and lines[0] != nil) {
		var fp = lines[0];
		return fp.getPlanSize() > number-100;
	}
	if (number < 100 and number > 0 and isRouteActive()) {
		var fp = flightplan();
		return fp.getPlanSize() > number-1;
	}
	return 0;
}



var isRouteActive = func {
	return getprop("autopilot/route-manager/active") and getprop("f16/avionics/power-mmc") and getprop("autopilot/route-manager/current-wp") != nil and getprop("autopilot/route-manager/current-wp") > -1 and getprop("autopilot/route-manager/route/num") != nil and getprop("autopilot/route-manager/current-wp") < getprop("autopilot/route-manager/route/num");
}


var data = nil;
var sending = nil;
var dlink_loop = func {
  if (getprop("instrumentation/datalink/data") != 0) return;
  foreach(contact; f16.vector_aicontacts_links) {
    if (contact.isVisible()) {
      data = datalink.get_data(contact.get_Callsign());
      if (data != nil  and data.on_link()) {
        var p = data.point();
        if (p != nil) {
          sending = nil;
          var mrk = STPT.new();
          mrk.lat = p.lat();
          mrk.lon = p.lon();
          mrk.alt = p.alt()*M2FT;
          var no = addDLMark(mrk);
          
          setprop("instrumentation/datalink/data",no);
          
          settimer(func {setprop("instrumentation/datalink/data",0);}, 10);
          return;
        }
      }
    }
  }
}

var dlnk_timer = maketimer(3.5, dlink_loop);
dlnk_timer.start();




var loadLine = func  (no,path) {
    printf("Attempting to load route %s to act as lines %d in HSD.", path, no);
  
    call(func {lines[no] = createFlightplan(path);}, nil, var err = []);
    if (size(err) or lines[no] == nil) {
        print(err[0]);
        setprop("f16/preplanning-status", err[0]);
        gui.showDialog("loadfail");
    } else {
    	setprop("f16/preplanning-status", "HSD lines loaded");
    }
};

var EMPTY_ALT = -99999;

var serialize = func() {
	var ret = "";
	var iter = 0;
	if (lines[0] != nil) {
		for (var s = 0; s < lines[0].getPlanSize() and s < 100; s+=1) {
			var key = lines[0].getWP(s);
		  	ret = ret~sprintf("LINE,%d,%.6f,%.6f|",s+100,key.lat,key.lon);
	  	}
	}
	if (lines[1] != nil) {
		for (var s = 0; s < lines[1].getPlanSize() and s < 100; s+=1) {
			var key = lines[1].getWP(s);
		  	ret = ret~sprintf("LINE,%d,%.6f,%.6f|",s+200,key.lat,key.lon);
	  	}
	}
	if (flightplan() != nil) {
		var plan = flightplan();
		for (var s = 0; s < plan.getPlanSize(); s+=1) {
			var key = plan.getWP(s);
		  	ret = ret~sprintf("PLAN,%d,%.6f,%.6f,%d,%d|",s+0,key.lat,key.lon,(key.alt_cstr_type!=nil and key.alt_cstr != nil)?key.alt_cstr:EMPTY_ALT,serializeTOS(s+1));
	  	}
	}
  foreach(key;stpt300) {
  	if (key == nil) {
		ret = ret~sprintf("STPT,%d,nil|",iter+300);
  	} else {
    	ret = ret~sprintf("STPT,%d,%.6f,%.6f,%d,%d,%d,%s,%d|",iter+300,key.lat,key.lon,key.alt,key.radius,key.color,key.type,serializeTOS(iter+300));
    }
    iter += 1;
  }
  iter = 0;
  foreach(key;stpt350) {
  	if (key == nil) {
  		ret = ret~sprintf("STPT,%d,nil|",iter+350);
  	} else {
    	ret = ret~sprintf("STPT,%d,%.6f,%.6f,%d,%d,%d,%s,%d|",iter+350,key.lat,key.lon,key.alt,key.radius,key.color,key.type,serializeTOS(iter+350));
    }
    iter += 1;
  }
  iter = 0;
  foreach(key;stpt400) {
  	if (key == nil) {
  		ret = ret~sprintf("STPT,%d,nil|",iter+400);
  	} else {
    	ret = ret~sprintf("STPT,%d,%.6f,%.6f,%d,%d,%d,%s,%d|",iter+400,key.lat,key.lon,key.alt,key.radius,key.color,key.type,serializeTOS(iter+400));
    }
    iter += 1;
  }
  iter = 0;
  foreach(key;stpt450) {
  	if (key == nil) {
  		ret = ret~sprintf("STPT,%d,nil|",iter+450);
  	} else {
    	ret = ret~sprintf("STPT,%d,%.6f,%.6f,%d,%d,%d,%s,%d|",iter+450,key.lat,key.lon,key.alt,key.radius,key.color,key.type,serializeTOS(iter+450));
    }
    iter += 1;
  }
  iter = 0;
  foreach(key;stpt500) {
  	if (key == nil) {
  		ret = ret~sprintf("STPT,%d,nil|",iter+500);
  	} else {
    	ret = ret~sprintf("STPT,%d,%.6f,%.6f,%d,%d,%d,%s,%d|",iter+500,key.lat,key.lon,key.alt,key.radius,key.color,key.type,serializeTOS(iter+500));
    }
    iter += 1;
  }
  iter = 0;
  foreach(key;stpt555) {
  	if (key == nil) {
  		ret = ret~sprintf("STPT,%d,nil|",iter+555);
  	} else {
    	ret = ret~sprintf("STPT,%d,%.6f,%.6f,%d,%d,%d,%s,%d|",iter+555,key.lat,key.lon,key.alt,key.radius,key.color,key.type,serializeTOS(iter+555));
    }
    iter += 1;
  }
  ret = ret~sprintf("IFF,%d|",getprop("instrumentation/iff/channel-selection"));
  ret = ret~sprintf("DATALINK,%d|",getprop("instrumentation/datalink/channel"));
  ret = ret~sprintf("COM1,%.2f|",getprop("instrumentation/comm[0]/frequencies/selected-mhz"));
  ret = ret~sprintf("COM1S,%.2f|",getprop("instrumentation/comm[0]/frequencies/standby-mhz"));
  ret = ret~sprintf("COM2,%.2f|",getprop("instrumentation/comm[1]/frequencies/selected-mhz"));
  ret = ret~sprintf("COM2S,%.2f|",getprop("instrumentation/comm[1]/frequencies/standby-mhz"));
  ret = ret~sprintf("ALOW,%d|",getprop("f16/settings/cara-alow"));
  ret = ret~sprintf("BINGO,%d|",getprop("f16/settings/bingo"));
  ret = ret~sprintf("SQUAWK,%04d|",getprop("instrumentation/transponder/id-code"));
  return ret;
}

var unserialize = func(m) {
  var stpts = split("|",m);
  var planned = nil;

  # clear memory:
  lines = [nil,nil];
  stpt300 = setsize([],number_of_threat_circles);#Threat circles
  stpt350 = setsize([],10);#Generic
  stpt400 = setsize([],5);#Markpoints Own
  stpt450 = setsize([],5);#Markpoints DL
  stpt500 = setsize([],1);#Weapon
  stpt555 = setsize([],1);#Bullseye
  ded.dataEntryDisplay.page = ded.pCNI;
  current = nil;

  foreach(item;stpts) {
    #if (size(item)>4) {#why is this chekc even here???!
      var items = split(",", item);
      var key = items[0];
      
      if (key == "PLAN") {
      	var number = num(items[1]);
      	if (planned == nil) planned = createFlightplan();
      	var plan = planned;
      	var wp = createWP(num(items[2]), num(items[3]), sprintf("STPT-%02d",number+1));
		plan.insertWP(wp, number);
		if (num(items[4]) != EMPTY_ALT) {
			var leg = plan.getWP(plan.getPlanSize()-1);
			leg.setAltitude(num(items[4]), "at");
		}
		if (size(items) > 5) { # TOS is supported
            setNumberDesiredTOS(number+1, num(items[5]));
        }
      } elsif (key == "LINE") {
      	var number = num(items[1]);
      	var no = number >= 200;
      	if (lines[no] == nil) {
      		lines[no] = createFlightplan();
      	}
      	var wp = createWP(num(items[2]), num(items[3]), ""~number);
      	number = no?number-200:number-100;
		lines[no].insertWP(wp, number);
      } elsif (key == "STPT") {
      	var newST = nil;
      	if (items[2]!="nil") {
      		newST = STPT.new();
      		newST.lat    = num(items[2]);
      		newST.lon    = num(items[3]);
      		newST.alt    = num(items[4]);
      		newST.radius = num(items[5]);
      		newST.color  = num(items[6]);
      		newST.type   =     items[7];
      	}
      	var number = num(items[1]);
      	if (number >= 555) {
      		stpt555[number-555] = newST;

      	} elsif (number >= 500) {
      		stpt500[number-500] = newST;

      	} elsif (number >= 450) {
      		stpt450[number-450] = newST;
      		dlMarkIndex = number-450;
      	} elsif (number >= 400) {
      		stpt400[number-400] = newST;
      		ownMarkIndex = number-400;
      	} elsif (number >= 350) {
      		stpt350[number-350] = newST;

      	} elsif (number >= 300) {
      		stpt300[number-300] = newST;
      	}
      	if (size(items) > 8) { # TOS is supported
            setNumberDesiredTOS(number, num(items[8]));
        }

      } elsif (key == "IFF") {
      	setprop("instrumentation/iff/channel-selection", num(items[1]));
      } elsif (key == "DATALINK") {
      	setprop("instrumentation/datalink/channel", num(items[1]));
      } elsif (key == "COM1") {
      	setprop("instrumentation/comm[0]/frequencies/selected-mhz", num(items[1]));
      } elsif (key == "COM1S") {
      	setprop("instrumentation/comm[0]/frequencies/standby-mhz", num(items[1]));
      } elsif (key == "COM2") {
      	setprop("instrumentation/comm[1]/frequencies/selected-mhz", num(items[1]));
      } elsif (key == "COM2S") {
      	setprop("instrumentation/comm[1]/frequencies/standby-mhz", num(items[1]));
      } elsif (key == "ALOW") {
      	setprop("f16/settings/cara-alow", num(items[1]));
      } elsif (key == "BINGO") {
      	setprop("f16/settings/bingo", num(items[1]));
      } elsif (key == "SQUAWK") {
      	setprop("instrumentation/transponder/id-code", num(items[1]));
      }
    #}
  }
  if (planned != nil) {
  	fgcommand("activate-flightplan", props.Node.new({"activate": 0}));
  	planned.activate();
  	fgcommand("activate-flightplan", props.Node.new({"activate": 1}));
  }
}

var saveSTPTs = func (path) {
    var text = serialize();
    var opn = nil;
    call(func{opn = io.open(path,"w");},nil, var err = []);
    if (size(err) or opn == nil) {
      print("error open file for writing STPTs");
      gui.showDialog("savefail");
      return 0;
    }
    call(func{var text = io.write(opn,text);},nil, var err = []);
    if (size(err)) {
      print("error writing file with STPTs");
      setprop("f16/preplanning-status", err[0]);
      io.close(opn);
      gui.showDialog("savefail");
      return 0;
    } else {
      io.close(opn);
      setprop("f16/preplanning-status", "DTC data saved");
      return 1;
    }
}

var loadSTPTs = func (path) {
    var text = nil;
    call(func{text=io.readfile(path);},nil, var err = []);
    if (size(err)) {
      print("Loading STPTs failed.");
      setprop("f16/preplanning-status", err[0]);
      gui.showDialog("loadfail");
    } elsif (text != nil) {
      unserialize(text);
      setprop("f16/preplanning-status", "DTC data loaded");
    }
}

setprop("sim/fg-home-export", getprop("sim/fg-home")~"/Export");