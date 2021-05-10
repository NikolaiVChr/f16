
var stpt300 = setsize([],6);#Threat circles
var stpt350 = setsize([],10);#Generic
var stpt400 = setsize([],5);#Markpoints Own
var stpt450 = setsize([],5);#Markpoints DL
var stpt500 = setsize([],1);#Weapon
var stpt555 = setsize([],1);#Bullseye
var current = nil;#Current STPT number, nil for route/nothing.

var STPT = {# for non-route steerpoints
	lon: 0,
	lat: 0,
	alt: 0,
	type: "   ",
	radius: 10,
	color: 0,
	
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

var colorRed = 0;
var colorYellow = 1;
var colorGreen = 2;

var getCurrentNumber = func {
	if (current != nil) {
		return current;
	} elsif (isRouteActive()) {
		var fp = flightplan();
		return fp.current + 1;
	}
	return 0;
}

var getCurrent = func {
	return getNumber(current);
}

var getNumber = func (number) {
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
	if (number < 100 and isRouteActive()) {
		return 0;
	}
	return 0;
}

var getCurrentDirection = func {
	if (getCurrentNumber() != 0) {
		return [geo.aircraft_position().course_to(getCurrentCoord()), vector.Math.getPitch(geo.aircraft_position(), getCurrentCoord())];
	} else {
		return [nil, nil];
	}
}

var getCurrentRange = func {
	if (getCurrentNumber() == 0) return nil;
	var s = getCurrentCoord();	
	return s.distance_to(geo.aircraft_position())*M2NM;
}

var getCurrentETA = func {
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
	var s = getNumber(getCurrentNumber());
	if (s == nil) return nil;
	return stpt2coord(s);
}

var setCurrentNumber = func (number) {
	if (number < 100 and isRouteActive() and number > 0) {
		var fp = flightplan();
		if (fp.getPlanSize() >= number) {
			fp.current = number - 1;
			current = nil;
			return 1;
		}
	} elsif (_isOccupiedNumber(number)) {
		current = number;
		return 1;
	}
	return 0;
}

var next = func {
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
	var fStpt = getNumber(from);
	if (fStpt != nil and _isValidNumber(to)) {
		var tStpt = fStpt.copy();
		setNumber(to, tStpt);
	} else {
		print("STPT copy unsuccesful.");
	}
}

var sendCurrent = func {
	return send(getCurrentNumber());
}

var stpt2coord = func (stpt) {
	var p = geo.Coord.new();
    p.set_latlon(stpt.lat, stpt.lon, stpt.alt*FT2M);
    return p;
}

var send = func (number) {
	var s = getNumber(number);
	if (s != nil and sending == nil) {
		var p = stpt2coord(s);
	    sending = p;
	    datalink.send_data({"point": sending});
	    settimer(func {sending = nil;},7);
	    return 1;
	}
	return 0;
}

var markOFLY = func {
	var mark = STPT.new();
	mark.lat = getprop("/position/latitude-deg");
	mark.lon = getprop("/position/longitude-deg");
	mark.alt = getprop("/position/altitude-ft");
	addOwnMark(mark);
}

var ownMarkIndex = 4;

var addOwnMark = func (mark) {
	ownMarkIndex += 1;
	if (ownMarkIndex > 4) ownMarkIndex = 0;
	stpt400[ownMarkIndex] = mark;	
	return ownMarkIndex+400;
}

var dlMarkIndex = 4;

var addDLMark = func (mark) {
	dlMarkIndex += 1;
	if (dlMarkIndex > 4) dlMarkIndex = 0;
	stpt450[dlMarkIndex] = mark;	
	return dlMarkIndex+450;
}

var applyToWPN = func {
	var lat = getprop("f16/avionics/gps-lat");
	var lon = getprop("f16/avionics/gps-lon");
	var alt = getprop("f16/avionics/gps-alt")*FT2M;
	if (lat < 90 and lat > -90 and lon < 180 and lon > -180 and pylons.fcs != nil) {
		var wp = pylons.fcs.getSelectedWeapon();
		if (wp != nil and wp.parents[0] == armament.AIM and wp.target_pnt == 1 and wp.guidance=="gps") {
			var coord = geo.Coord.new();
			coord.set_latlon(lat,lon,alt);
			var spot = fc.ContactTGP.new("GPS-Spot",coord,0);
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
	if (number >= 300 and number <= 305) {
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
	} elsif (number >= 1 and number < 100) {
		return 1;
	}
	return 0;
}

var _isOccupiedNumber = func (number) {
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
	if (number < 100 and number > 0 and isRouteActive()) {
		var fp = flightplan();
		return fp.getPlanSize() > number-1;
	}
	return 0;
}



var isRouteActive = func {
	return getprop("autopilot/route-manager/active") and getprop("f16/avionics/power-mmc") and getprop("autopilot/route-manager/current-wp") != nil and getprop("autopilot/route-manager/current-wp") > -1;
}


var data = nil;
var sending = nil;
var dlink_loop = func {
  if (getprop("instrumentation/datalink/data") != 0) return;
  foreach(contact; awg_9.tgts_list) {
    if (!contact.get_behind_terrain() and contact.get_range() < 80) {
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
