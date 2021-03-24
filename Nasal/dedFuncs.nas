# Classes
var Button = {
	new: func(btnText = "-99", routerVec = nil, actionVec = nil, To9 = 0) {
		var button = {parents: [Button]};
		button.routerVec = routerVec;
		button.actionVec = actionVec;
		button.btnText = btnText;
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
		if (me.To9 or me.btnText == "0") {
			if (size(dataEntryDisplay.page.vector) != 0) {
				dataEntryDisplay.page.vector[dataEntryDisplay.page.selectedIndex()].append(me.btnText);
				return;
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
					if (size(dataEntryDisplay.page.vector) != 0) {
						if (dataEntryDisplay.page.vector[dataEntryDisplay.page.selectedIndex()].lastText2 != "") {
							dataEntryDisplay.page.vector[dataEntryDisplay.page.selectedIndex()].recallStatus = 0;
							dataEntryDisplay.page.vector[dataEntryDisplay.page.selectedIndex()].text = dataEntryDisplay.page.vector[dataEntryDisplay.page.selectedIndex()].lastText2;
							dataEntryDisplay.page.vector[dataEntryDisplay.page.selectedIndex()].lastText1 = "";
							dataEntryDisplay.page.vector[dataEntryDisplay.page.selectedIndex()].lastText2 = "";
						}
					}
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
		# this is an ugly hack
		if (dataEntryDisplay.page == pLIST or dataEntryDisplay.page == pMISC) { return -1; }

		if (dataEntryDisplay.page == me.page or me.page == nil) {
			call(me.funcCallback, nil, dataEntryDisplay.page);
			return 1;
		}
		return -1;
	},
};

var EditableField = {
	new: func(prop, stringFormat, maxSize, checkValue = nil) {
		var editableField = {parents: [EditableField]};
		editableField.text = getprop(prop);
		editableField.prop = prop;
		editableField.maxSize = maxSize;
		editableField.stringFormat = stringFormat;
		editableField.lastText1 = "";
		editableField.lastText2 = "";
		editableField.recallStatus = 0;
		editableField.selected = 0;
		editableField.listener = nil;
		editableField.checkValue = checkValue;
		editableField.init();
		return editableField;
	},
	init: func() {
		if (me.listener == nil) {
			me.listener = setlistener(me.prop, func() {
				me.setText(getprop(me.prop));
			}, 0, 0);
		}
	},
	append: func(letter) {
		# check decimal
		var numBeforeDecimal = -99;
		var numDecimalPlaces = -99;
		if (find(".", me.stringFormat) != -1) {
			var string = split(".", me.stringFormat);
			numBeforeDecimal = num(right(string[0], 1)) - num(left(string[1], 1)) - 1;
			numDecimalPlaces = num(left(string[1], 1));
		}
		if (me.lastText2 == "") {
			me.lastText2 = me.text;
			me.text = "";
		}
		if (size(""~me.text) == me.maxSize) { return; }
		me.lastText1 = me.text;
		if (size(""~me.text) == numBeforeDecimal) {
			me.text ~= ".";
		}
		me.text ~= letter;
	},
	recall: func() {
		if (me.recallStatus == 0) {
			if (me.lastText1 != "") {
				me.text = me.lastText1;
				me.recallStatus = 1;
			}
		} else {
			if (me.lastText2 != "") {
				me.recallStatus = 0;
				me.text = me.lastText2;
				me.lastText1 = "";
				me.lastText2 = "";
			}
		}
	},
	enter: func() {
		if (me.checkValue != nil) {
			if (me.checkValue(me.text) != 0) {
				return;
			}
		}
		me.recallStatus = 0;
		me.lastText1 = "";
		me.lastText2 = "";
		setprop(me.prop, me.text);
	},
	getText: func() {
		if (me.selected) {
			if (me.lastText1 == "" and me.lastText2 == "" and me.recallStatus == 0) {
				return sprintf("*" ~ me.stringFormat ~ "*", me.text);
			} else {
				return sprintf(utf8.chstr("0xFB4F") ~ me.stringFormat ~ utf8.chstr("0xFB4F"), me.text);
			}
		} else {
			return sprintf(" " ~ me.stringFormat ~ " ", me.text);
		}
	},
	setText: func(text) {
		me.recallStatus = 0;
		me.lastText1 = "";
		me.lastText2 = "";
		me.text = text;
	},
};

var toggleableField = {
	new: func(valuesVector, prop) {
		var tF = {parents: [toggleableField]};
		tF.valuesVector = valuesVector;
		tF.value = "";
		tF.index = 0;
		tF.prop = prop;
		tF.selected = 0;
		tF.text = "";
		tF.lastText1 = "";
		tF.lastText2 = "";
		tF.recallStatus = 0;
		tF.listener = nil;
		tF.init();
		return tF;
	},
	init: func() {
		if (me.listener == nil) {
			me.listener = setlistener(me.prop, func() {
				me.updateText();
			}, 0, 0);
		}
		
		for (var i = 0; i < size(me.valuesVector); i = i + 1) {
			if (getprop(me.prop) == me.valuesVector[i]) {
				me.value = me.valuesVector[i];
				me.index = i;
			}
		}
	},
	append: func(letter) {
		if (letter != "0") { return; }
		me.index += 1;
		if (me.index >= size(me.valuesVector)) {
			me.index = 0;
		}
		setprop(me.prop, me.valuesVector[me.index]);
	},
	recall: func() {
		return;
	},
	enter: func() {
		return;
	},
	getText: func() {
		if (me.selected) {
			return "*" ~ me.value ~ "*";
		} else {
			return " " ~ me.value ~ " ";
		}
	},
	updateText: func() {
		me.value = me.valuesVector[me.index];
	},
};

var EditableFieldPage = {
	new: func(number, vector = nil) {
		var efp = {parents: [EditableFieldPage]};
		if (vector == nil) {
			efp.vector = [];
		} else {
			efp.vector = vector;
		}
		efp.number = number;
		efp.index = 0;
		efp.init();
		return efp;
	},
	init: func() {
		if (size(me.vector) != 0) {
			me.vector[0].selected = 1;
		}
	},
	getNext: func() {
		if (size(me.vector) < 2) { return; }
		me.vector[me.index].selected = 0;
		me.index += 1;
		if (me.index == size(me.vector)) {
			me.index = 0;
		}
		me.vector[me.index].selected = 1;
	},
	getPrev: func() {
		if (size(me.vector) < 2) { return; }
		me.vector[me.index].selected = 0;
		me.index -= 1;
		if (me.index == -1) {
			me.index = size(me.vector) - 1;
		}
		me.vector[me.index].selected = 1;
	},
	append: func(letter) {
		if (size(me.vector) == 0) { return; }
		me.vector[me.index].append(letter);
	},
	enter: func() {
		if (size(me.vector) == 0) { return; }
		me.vector[me.index].enter();
	},
	recall: func() {
		if (size(me.vector) == 0) { return; }
		me.vector[me.index].recall();
	},
	getText: func(index) {
		if (size(me.vector) == 0) { return; }
		return me.vector[index].getText();
	},
	isSelected: func(index) {
		if (size(me.vector) == 0) { return; }
		return me.vector[index].selected;
	},
	selectedIndex: func() {
		return me.index;
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

var toggleableTransponder = {
	new: func(valuesVector, prop) {
		var tF = {parents: [toggleableTransponder]};
		tF.valuesVector = valuesVector;
		tF.value = "";
		tF.index = 0;
		tF.prop = prop;
		tF.selected = 0;
		tF.text = "";
		tF.lastText1 = "";
		tF.lastText2 = "";
		tF.recallStatus = 0;
		tF.listener = nil;
		tF.init();
		return tF;
	},
	init: func() {
		if (me.listener == nil) {
			me.listener = setlistener(me.prop, func() {
				me.updateText();
			}, 0, 0);
		}
		
		for (var i = 0; i < size(me.valuesVector); i = i + 1) {
			if (getprop(me.prop) == me.valuesVector[i]) {
				me.value = me.valuesVector[i];
				me.index = i;
			}
		}
	},
	append: func(letter) {
		if (letter != "0") { return; }
		me.index += 1;
		if (me.index >= size(me.valuesVector)) {
			me.index = 0;
		}
		setprop(me.prop, me.valuesVector[me.index]);
	},
	recall: func() {
		return;
	},
	enter: func() {
		return;
	},
	getText: func() {
		me.stat = "OFF";
		if (me.value == 1) {
			me.stat = "STBY";
		} elsif (me.value == 2) {
			me.stat = "TEST";
		} elsif (me.value == 3) {
			me.stat = "GND";
		} elsif (me.value == 4) {
			me.stat = "ON";
		} elsif (me.value == 5) {
			me.stat = "ALT";
		}
		if (me.selected) {
			return "*" ~ me.stat ~ "*";
		} else {
			return " " ~ me.stat ~ " ";
		}
	},
	updateText: func() {
		me.value = me.valuesVector[me.index];
	},
};

var toggleableIff = {
	new: func(valuesVector, prop) {
		var tF = {parents: [toggleableIff]};
		tF.valuesVector = valuesVector;
		tF.value = "";
		tF.index = 0;
		tF.prop = prop;
		tF.selected = 0;
		tF.text = "";
		tF.lastText1 = "";
		tF.lastText2 = "";
		tF.recallStatus = 0;
		tF.listener = nil;
		tF.init();
		return tF;
	},
	init: func() {
		if (me.listener == nil) {
			me.listener = setlistener(me.prop, func() {
				me.updateText();
			}, 0, 0);
		}

		for (var i = 0; i < size(me.valuesVector); i = i + 1) {
			if (getprop(me.prop) == me.valuesVector[i]) {
				me.value = me.valuesVector[i];
				me.index = i;
			}
		}
	},
	append: func(letter) {
		if (letter != "0") { return; }
		me.index += 1;
		if (me.index >= size(me.valuesVector)) {
			me.index = 0;
		}
		setprop(me.prop, me.valuesVector[me.index]);
	},
	recall: func() {
		return;
	},
	enter: func() {
		return;
	},
	getText: func() {
		me.stat = "OFF";
		if (me.value == 1) {
			me.stat = "ON";
		}
		if (me.selected) {
			return "*" ~ me.stat ~ "*";
		} else {
			return " " ~ me.stat ~ " ";
		}
	},
	updateText: func() {
		me.value = me.valuesVector[me.index];
	},
};

var checkValueTransponderCode = func(text) {
	var codeDigits = split("", text);

	for (var i = 0; i < 4; i = i + 1) {
		var codeDigit = pop(codeDigits);
		if (codeDigit > 7) {
			return -1;
		}
	}

	return 0;
}

var checkValueLaserCode = func(text) {
	var codeDigits = split("", text);

	for (var i = 0; i < 4; i = i + 1) {
		var codeDigit = pop(codeDigits);
		if (i == 0 and codeDigit > 2) {
			return -1;
		}
		if (codeDigit < 1 or codeDigit > 8) {
			return -1;
		}
	}

	return 0;
}

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