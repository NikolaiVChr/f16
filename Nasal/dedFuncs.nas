# Classes
var Button = {
	new: func(routerVec = nil, actionVec = nil, To9 = 0) {
		var button = {parents: [Button]};
		button.routerVec = routerVec;
		button.actionVec = actionVec;
		button.To9 = To9;
		return button;
	},
	doAction: func() {
		sound.doubleClick();
		if (me.To9) {
			if (dataEntryDisplay.page == pMARK or dataEntryDisplay.page == pFIX or dataEntryDisplay.page == pACAL) {
				if (dataEntryDisplay.page == pMARK and dataEntryDisplay.markModeSelected) {
					if (dataEntryDisplay.markMode == "OFLY") {
						dataEntryDisplay.markMode = "FCR";
					} elsif (dataEntryDisplay.markMode == "FCR") {
						dataEntryDisplay.markMode = "HUD";
					} else {
						dataEntryDisplay.markMode = "OFLY";
					}
					return;
				}
				
				if (dataEntryDisplay.page == pFIX and dataEntryDisplay.fixTakingModeSelected) {
					if (dataEntryDisplay.fixTakingMode == "OFLY") {
						dataEntryDisplay.fixTakingMode = "FCR";
					} elsif (dataEntryDisplay.fixTakingMode == "FCR") {
						dataEntryDisplay.fixTakingMode = "HUD";
					} else {
						dataEntryDisplay.fixTakingMode = "OFLY";
					}
					return;
				}
				
				if (dataEntryDisplay.page == pACAL and dataEntryDisplay.acalModeSelected) {
					if (dataEntryDisplay.acalMode == "GPS") {
						dataEntryDisplay.acalMode = "DTS";
					} elsif (dataEntryDisplay.acalMode == "DTS") {
						dataEntryDisplay.acalMode = "BOTH";
					} else {
						dataEntryDisplay.acalMode = "GPS";
					}
					return;
				}
			}
		}
		if (me.actionVec != nil) {
			foreach (var action; me.actionVec) {
				if (action.run() != -1) {
					return;
				}
			}
		}
		if (me.routerVec != nil) {
			foreach (var router; me.routerVec) {
				if (router.run() != -1) {
					return;
				}
			}
		}
	},
};

var Action = {
	new: func(page, funcCallback) {
		var action = {parents: [Action]};
		action.page = page;
		action.funcCallback = funcCallback;
		return action;
	},
	run: func() {
		if (dataEntryDisplay.page == me.page or me.page == nil) {
			call(me.funcCallback);
			return 1;
		}
		return -1;
	},
};

var Router = {
	new: func(start, finish) {
		var router = {parents: [Router]};
		router.start = start;
		router.finish = finish;
		return router;
	},
	run: func() {
		if (dataEntryDisplay.page == me.start or me.start == nil) {
			dataEntryDisplay.page = me.finish;
			return 1;
		}
		return -1;
	},
};

# Functions
var toggleHack = func() {
	if (dataEntryDisplay.chrono.running) {
		dataEntryDisplay.chrono.stop();
	} else {
		dataEntryDisplay.chrono.start();
	}
};

var resetHack = func() {
	dataEntryDisplay.chrono.stop();
	dataEntryDisplay.chrono.reset();
};

var modeSelMark = func() { dataEntryDisplay.markModeSelected = !dataEntryDisplay.markModeSelected; };
var modeSelFix = func() { dataEntryDisplay.fixTakingModeSelected = !dataEntryDisplay.fixTakingModeSelected; };
var modeSelAcal = func() { dataEntryDisplay.acalModeSelected = !dataEntryDisplay.acalModeSelected; };

var toggleTACANBand = func() {
	if (getprop("instrumentation/tacan/frequencies/selected-channel[4]") == "X") {
		setprop("instrumentation/tacan/frequencies/selected-channel[4]", "Y");
	} else {
		setprop("instrumentation/tacan/frequencies/selected-channel[4]", "X");
	}
};

var toggleTACANMode = func() {
	if (dataEntryDisplay.tacanMode == "REC    ") {
		dataEntryDisplay.tacanMode = "T/R    ";
		setprop("f16/avionics/tacan-receive-only", 0);
	} elsif (dataEntryDisplay.tacanMode == "T/R    ") {
		dataEntryDisplay.tacanMode = "A/A REC";
		setprop("f16/avionics/tacan-receive-only", 1);
	} elsif (dataEntryDisplay.tacanMode == "A/A REC") {
		dataEntryDisplay.tacanMode = "A/A T/R";
		setprop("f16/avionics/tacan-receive-only", 0);
	} else {
		dataEntryDisplay.tacanMode = "REC    ";
		setprop("f16/avionics/tacan-receive-only", 1);
	}
};

var modeSelBull = func() { dataEntryDisplay.bullMode = !dataEntryDisplay.bullMode; };

var stptNext = func() {
	var active = getprop("autopilot/route-manager/active") and getprop("f16/avionics/power-mmc");
    var wp = getprop("autopilot/route-manager/current-wp");
    var max = getprop("autopilot/route-manager/route/num");
  
    if (active and wp != nil and wp > -1) {
		wp += 1;
		if (wp>max-1) {
			wp = 0;
		}
		setprop("autopilot/route-manager/current-wp", wp);
	}
};

var stptLast = func() {
	var active = getprop("autopilot/route-manager/active") and getprop("f16/avionics/power-mmc");
    var wp = getprop("autopilot/route-manager/current-wp");
    var max = getprop("autopilot/route-manager/route/num");
  
    if (active and wp != nil and wp > -1) {
		wp -= 1;
		if (wp<0) {
			wp = max-1;
		}
		setprop("autopilot/route-manager/current-wp", wp);
    }
};

## these methods taken from JA37:
var convertDoubleToDegree = func (value) {
        var sign = value < 0 ? -1 : 1;
        var abs = math.abs(math.round(value * 1000000));
        var dec = math.fmod(abs,1000000) / 1000000;
        var deg = math.floor(abs / 1000000) * sign;
        var min = dec * 60;
        return [deg,min];
}
var convertDegreeToStringLat = func (lat) {
  lat = convertDoubleToDegree(lat);
  var s = "N";
  if (lat[0]<0) {
    s = "S";
  }
  return sprintf("%s %3d\xc2\xb0%06.3f´",s,math.abs(lat[0]),lat[1]);
}
var convertDegreeToStringLon = func (lon) {
  lon = convertDoubleToDegree(lon);
  var s = "E";
  if (lon[0]<0) {
    s = "W";
  }
  return sprintf("%s %3d\xc2\xb0%06.3f´",s,math.abs(lon[0]),lon[1]);
}
var convertDoubleToDegree37 = func (value) {
        var sign = value < 0 ? -1 : 1;
        var abs = math.abs(math.round(value * 1000000));
        var dec = math.fmod(abs,1000000) / 1000000;
        var deg = math.floor(abs / 1000000) * sign;
        var min = math.floor(dec * 60);
        var sec = math.round((dec - min / 60) * 3600);#TODO: unsure of this round()
        return [deg,min,sec];
}
var convertDegreeToStringLat37 = func (lat) {
  lat = convertDoubleToDegree(lat);
  var s = "N";
  if (lat[0]<0) {
    s = "S";
  }
  return sprintf("%02d %02d %02d%s",math.abs(lat[0]),lat[1],lat[2],s);
}
var convertDegreeToStringLon37 = func (lon) {
  lon = convertDoubleToDegree(lon);
  var s = "E";
  if (lon[0]<0) {
    s = "W";
  }
  return sprintf("%03d %02d %02d%s",math.abs(lon[0]),lon[1],lon[2],s);
}
var convertDegreeToDispStringLat = func (lat) {
  lat = convertDoubleToDegree(lat);

  return sprintf("%02d%02d%02d",lat[0],lat[1],lat[2]);
}
var convertDegreeToDispStringLon = func (lon) {
  lon = convertDoubleToDegree(lon);
  return sprintf("%03d%02d%02d",lon[0],lon[1],lon[2]);
}
var convertDegreeToDouble = func (hour, minute, second) {
  var d = hour+minute/60+second/3600;
  return d;
}
var myPosToString = func {
  print(convertDegreeToStringLat(getprop("position/latitude-deg"))~"  "~convertDegreeToStringLon(getprop("position/longitude-deg")));
}
var stringToLon = func (str) {
  var total = num(str);
  if (total==nil) {
    return nil;
  }
  var sign = 1;
  if (total<0) {
    str = substr(str,1);
    sign = -1;
  }
  var deg = num(substr(str,0,2));
  var min = num(substr(str,2,2));
  var sec = num(substr(str,4,2));
  if (size(str) == 7) {
    deg = num(substr(str,0,3));
    min = num(substr(str,3,2));
    sec = num(substr(str,5,2));
  } 
  if(deg <= 180 and min<60 and sec<60) {
    return convertDegreeToDouble(deg,min,sec)*sign;
  } else {
    return nil;
  }
}
var stringToLat = func (str) {
  var total = num(str);
  if (total==nil) {
    return nil;
  }
  var sign = 1;
  if (total<0) {
    str = substr(str,1);
    sign = -1;
  }
  var deg = num(substr(str,0,2));
  var min = num(substr(str,2,2));
  var sec = num(substr(str,4,2));
  if(deg <= 90 and min<60 and sec<60) {
    return convertDegreeToDouble(deg,min,sec)*sign;
  } else {
    return nil;
  }
}