var symbolSize = {
	hsd: {
	    contact: 1,
	    bullseye: 1,
	    ownship: 1,
	    compasFlag: 16,
	    cursor: 16,
	    cursorGhostAir: 18,
	    cursorGhostGnd: 12,
	    steerpoint: 5,
	    contactVelocity: 0.0045,
	    markpoint: 18,
	},
	bullseye: {
		eye: 1,
		ref: 1,
	},
	tfr: {
		terrain: 20,
		tick: 15,
	},
	has: {
		cursor: 1,
		tick: 10,
		crossInner: 20,
	},
	fcr: {
		blep: 8,
		track: 1.0,
		iff: 8,
		dl: 10,
		gainGaugeVert: 65,
		gainGaugeHoriz: 20,
		caret: 14,
		tick: 1.0,
		designation: 16,
		interceptCross: 10,
		designationGM: 10,
		dlzWidth: 20,
		dlzArrow: 1.0,
		horizLine: 10,
		cursorAir: 9,
		cursorGMGap: 11,
		cursorGMtick: 5,
		cursorGMtickDist: 50,
		bullseye: 1.0,
		steerpoint: 1.0,
		contactVelocity: 0.0045,
	},
};

var margin = {
	device: {
		buttonText: 10,
		fillHeight: 1,
		outline: 1,
	},
	fcr: {
		trackText: 20,
		caretSide: 50,
		caretBottom: 50,
	},
	bullseye: {
		y: 50,
		x: 210,
		text: 20,
	},
	tfr: {
		sides: 20,
		bottom: 35,
	},
	has: {
		statusBox: 40,
		searchText: 45,
	},
};

var lineWidth = {
	device: {
		outline: 2,
		x: 3,
		soi: 2,
	},
	fcr: {
		dlz: 2,
		rangeRings: 2,
		track:2,
		iff: 3,
		dl: 3,
		gainGauge: 2,
		caret: 5,
		tick: 3,
		designation: 2,
		designationGM: 2,
		interceptCross: 2,
		azimuthLine: 2,
		horizLine: 3,
		exp: 2,
		cursorAir: 2,
		cursorGnd: 2,
		bullseye: 3,
		steerpoint: 1,
	},
	has: {
		cursor: 2,
		statusBox: 2,
		enclosure: 2,
		aim: 2,
	},
	tfr: {
		terrain: 1,
	},
	stations: {
		outline: 1.5,
	},
	bullseyeLayer: {
		eye: 2.5,
		ref: 2,
	},
	arrows: {
		triangle: 3,
	},
	hsd: {
	    bullseye: 3,
	    rangeRing: 2,
	    ownship: 2,
	    radarCone: 3,
	    threatRing: 3,
	    line: 2,
	    route: 2,
	    targetTrack: 2,
	    targetDL: 3,
	    designation: 2,
	    cursor: 2,
	    cursorGhost: 1.5,
	},
};


# OSB text
var colorText1 = [getprop("/sim/model/MFD-color/text1/red"), getprop("/sim/model/MFD-color/text1/green"), getprop("/sim/model/MFD-color/text1/blue")];

# Info text
var colorText2 = [getprop("/sim/model/MFD-color/text2/red"), getprop("/sim/model/MFD-color/text2/green"), getprop("/sim/model/MFD-color/text2/blue")];

# red threat circles
var colorCircle1 = [getprop("/sim/model/MFD-color/circle1/red"), getprop("/sim/model/MFD-color/circle1/green"), getprop("/sim/model/MFD-color/circle1/blue")];

# yellow threat circles
var colorCircle2 = [getprop("/sim/model/MFD-color/circle2/red"), getprop("/sim/model/MFD-color/circle2/green"), getprop("/sim/model/MFD-color/circle2/blue")];

# green threat circles
var colorCircle3 = [getprop("/sim/model/MFD-color/circle3/red"), getprop("/sim/model/MFD-color/circle3/green"), getprop("/sim/model/MFD-color/circle3/blue")];

# Not used
var colorDot1 = [getprop("/sim/model/MFD-color/dot1/red"), getprop("/sim/model/MFD-color/dot1/green"), getprop("/sim/model/MFD-color/dot1/blue")];

# White/green radar search targets
var colorDot2 = [getprop("/sim/model/MFD-color/dot2/red"), getprop("/sim/model/MFD-color/dot2/green"), getprop("/sim/model/MFD-color/dot2/blue")];

# Datalink wingman
var colorDot4 = [getprop("/sim/model/MFD-color/dot4/red"), getprop("/sim/model/MFD-color/dot4/green"), getprop("/sim/model/MFD-color/dot4/blue")];

# Bullseye and STPT symbol on FCR
var colorBullseye = [getprop("/sim/model/MFD-color/bullseye/red"), getprop("/sim/model/MFD-color/bullseye/green"), getprop("/sim/model/MFD-color/bullseye/blue")];

# Bulleye direction to ownship text
var colorBetxt = [getprop("/sim/model/MFD-color/betxt/red"), getprop("/sim/model/MFD-color/betxt/green"), getprop("/sim/model/MFD-color/betxt/blue")];

# Own ship in HSD
var colorLine1  = [getprop("/sim/model/MFD-color/line1/red"), getprop("/sim/model/MFD-color/line1/green"), getprop("/sim/model/MFD-color/line1/blue")];

# Horizon in FCR
var colorLine2  = [getprop("/sim/model/MFD-color/line2/red"), getprop("/sim/model/MFD-color/line2/green"), getprop("/sim/model/MFD-color/line2/blue")];

# Steerpoints, cursor and many other symbols
var colorLine3  = [getprop("/sim/model/MFD-color/line3/red"), getprop("/sim/model/MFD-color/line3/green"), getprop("/sim/model/MFD-color/line3/blue")];

# EXP square
var colorLine4  = [getprop("/sim/model/MFD-color/line4/red"), getprop("/sim/model/MFD-color/line4/green"), getprop("/sim/model/MFD-color/line4/blue")];

# Range rings in HSD
var colorLine5  = [getprop("/sim/model/MFD-color/line5/red"), getprop("/sim/model/MFD-color/line5/green"), getprop("/sim/model/MFD-color/line5/blue")];

# FCR range rings and steerpoint legs
var colorLines  = [getprop("/sim/model/MFD-color/lines/red"), getprop("/sim/model/MFD-color/lines/green"), getprop("/sim/model/MFD-color/lines/blue")];

# Not used
var colorLines2 = [getprop("/sim/model/MFD-color/lines2/red"), getprop("/sim/model/MFD-color/lines2/green"), getprop("/sim/model/MFD-color/lines2/blue")];


var colorCubeRed = [255,0,0];
var colorCubeGreen = [0,255,0];
var colorCubeCyan = [0,255,255];

var colorBackground = [0,0,0];
var variantID = getprop("sim/variant-id");
if (variantID == 2) {
    colorBackground = [0.01,0.01,0.07, 1];
} else if (variantID == 4) {
    colorBackground = [0.01,0.01,0.07, 1];
} else if (variantID == 5) {
    colorBackground = [0.01,0.01,0.07, 1];
} else if (variantID >= 6) {
    colorBackground = [0.01,0.01,0.07, 1];
} else {
    colorBackground = [0.005,0.1,0.005, 1];
}



var PUSHBUTTON   = 0;
var ROCKERSWITCH = 1;

var CursorHSD = 1;
var FACH3 = variantID == 4 or variantID >= 6;#MLU Tape M4.3

#  ██████  ███████ ██    ██ ██  ██████ ███████ 
#  ██   ██ ██      ██    ██ ██ ██      ██      
#  ██   ██ █████   ██    ██ ██ ██      █████   
#  ██   ██ ██       ██  ██  ██ ██      ██      
#  ██████  ███████   ████   ██  ██████ ███████ 
#                                              
#                                              

var DisplayDevice = {
	new: func (name, resolution, uvMap, node, texture) {
		var device = {parents : [DisplayDevice] };
		device.canvas = canvas.new({
                			"name": name,
                           	"size": resolution,
                            "view": resolution,
                    		"mipmapping": 1
                    	});
		device.resolution = resolution;
		device.canvas.addPlacement({"node": node, "texture": texture});
		device.controls = {master:{"device": device}};
		device.controlPositions = {};
		device.listeners = [];
		device.uvMap = uvMap;
		device.name = name;
		device.system = nil;
		device.addPullUpCue();
		device.new = func {return nil;};
		#device.timer = maketimer(0.25, device, device.loop);
		return device;
	},

	del: func {
		me.canvas.del();
		foreach(l ; me.listeners) {
			call(func removelistener(l),[],nil,nil,var err = []);
		}
		me.listeners = [];
		#call(func me.timer.stop(),[],nil,nil,err = []);
		#me.timer = nil;
		me.del = func {};
	},

	start: func {
		#me.timer.start();#timers dont really work in modules
		#me.start=func{};
	},

	loop: func {
		me.setSOI(me["aircraftSOI"] == f16.SOI);
		me.update(notifications.frameNotification);# TODO: emesary
	},

	setColorBackground: func (colorBackground) {
		me.canvas.setColorBackground(colorBackground);
	},

	addControls: func (type, prefix, from, to, property, positions) {
		if (contains(DisplayDevice, prefix)) {print("Illegal prefix");return;}
		me[prefix] = func (node) {
			me.tempActionValue = node.getValue();
			
			if (me.tempActionValue > 0) {
				#printDebug(me.name,": ",prefix, " action :", me.tempActionValue);
				me.cntlFeedback.setTranslation(me.controlPositions[prefix][me.tempActionValue-1]);
				me.cntlFeedback.setVisible(FACH3);
				me.cntlFeedback.update();
				#print("fb ON  ",me.controlPositions[prefix][me.tempActionValue-1][0],",",me.controlPositions[prefix][me.tempActionValue-1][1]);
				me.controlAction(type, prefix~(me.tempActionValue), me.tempActionValue);
			} else {
				me.cntlFeedback.hide();
				me.cntlFeedback.update();
				#print("fb OFF  ");
			}
		};
		me.controlPositions[prefix] = positions;
		for(var i = from; i <= to; i += 1) {
			me.controls[prefix~i] = {
				parents: [me.controls.master],
				name: prefix~i,
			};
		}
		if (me["controlGrp"] == nil) {
			me.controlGrp = me.canvas.createGroup()
								.set("z-index", 100)
								.set("font","LiberationFonts/LiberationMono-Regular.ttf");
		}
		me.controls.master.setControlText = func (text, positive = 1, outline = 0, rear = 0, blink = 0) {
			# rear is adjustment of the fill in x axis

			# store for later SWAP option
			me.contentText = text;
			me.contentPositive = positive;
			me.contentOutline = outline;

			if (text == nil or text == "") {
				me.letters.setVisible(0);
				me.outline.setVisible(0);
				me.fill.setVisible(0);
				#me.fill.setColor((!positive)?me.device.colorFront:me.device.colorBack);
				#me.fill.setColorFill((!positive)?me.device.colorFront:me.device.colorBack);
				return;
			}
			me.letters.setVisible(1);
			me.letters.setText(text);
			me.letters.setColor(positive?me.device.colorFront:me.device.colorBack);
			me.outline.setVisible(positive and outline);
			me.fill.setVisible(1);
			me.fill.setColor((!positive)?me.device.colorFront:me.device.colorBack);
			me.fill.setColorFill((!positive)?me.device.colorFront:me.device.colorBack);
			me.linebreak = find("\n", text) != -1?2:1;
			me.lettersCount = size(text);
			if (me.linebreak == 2) {
				me.split = split("\n", text);
				if (size(me.split)>1) me.lettersCount = math.max(size(me.split[0]),size(me.split[1]));
			}
			me.fill.setScale(me.lettersCount/4,me.linebreak);
			me.outline.setScale(1.05*me.lettersCount/4,me.linebreak);
		};
		append(me.listeners, setlistener(property, me[prefix],0,0));
	},

	resetControls: func {
		me.tempKeys = keys(me.controls);
		foreach(var key; me.tempKeys) {
			if (me.controls[key]["parents"]!= nil) me.controls[key].setControlText("");
		}
	},

	update: func (noti) {
		if (me.system.supportSOI()) {
			# Lines or text
			me.setSOI(me["aircraftSOI"] == f16.SOI);
		} else {
			# Neither
			me.setSOI(-1);
		}
		me.system.update(noti);
	},

	controlAction: func {},

	setDisplaySystem: func (system) {
		me.system = system;
		system.setDevice(me);
	},

	addControlText: func (prefix, controlName, pos, posIndex, alignmentH=0, alignmentV=0) {
		me.tempX = me.controlPositions[prefix][posIndex][0]+pos[0];
		me.tempY = me.controlPositions[prefix][posIndex][1]+pos[1];

		me.alignment  = alignmentH==0?"center-":(alignmentH==-1?"left-":"right-");
		me.alignment ~= alignmentV==0?"center":(alignmentV==-1?"top":"bottom");
		me.letterWidth  = 0.6 * me.fontSize;
		me.letterHeight = 0.8 * me.fontSize;
		me.myCenter = [me.tempX, me.tempY];
		me.controls[controlName].letters = me.controlGrp.createChild("text")
				.set("z-index", 10)
				.setAlignment(me.alignment)
				.setTranslation(me.tempX, me.tempY)
				.setFontSize(me.fontSize, 1)
				.setText(right(controlName,4))
				.setColor(me.colorFront);
		me.controls[controlName].outline = me.controlGrp.createChild("path")
				.set("z-index", 11)
				.setStrokeLineJoin("round") # "miter", "round" or "bevel"
				.moveTo(me.tempX-me.letterWidth*2*alignmentH-me.letterWidth*2-me.myCenter[0]-margin.device.outline, me.tempY-me.letterHeight*alignmentV*0.5-me.letterHeight*0.5-margin.device.outline-me.myCenter[1])
				.horiz(me.letterWidth*4+margin.device.outline*2)
				.vert(me.letterHeight*1.0+margin.device.outline*2)
				.horiz(-me.letterWidth*4-margin.device.outline*2)
				.vert(-me.letterHeight*1.0-margin.device.outline*2)
				.close()
				.setColor(me.colorFront)
				.hide()
				.setStrokeLineWidth(lineWidth.device.outline)
				.setTranslation(me.myCenter);
		me.controls[controlName].fill = me.controlGrp.createChild("path")
				.set("z-index", 9)
				.setStrokeLineJoin("round") # "miter", "round" or "bevel"
				.moveTo(me.tempX-me.letterWidth*2*alignmentH-me.letterWidth*2-me.myCenter[0], me.tempY-me.letterHeight*alignmentV*0.5-me.letterHeight*0.5-margin.device.fillHeight-me.myCenter[1])
				.horiz(me.letterWidth*4)
				.vert(me.letterHeight*1.0+margin.device.fillHeight)
				.horiz(-me.letterWidth*4)
				.vert(-me.letterHeight*1.0-margin.device.fillHeight)
				.close()
				.setColorFill(me.colorBack)
				.setColor(me.colorBack)
				.setStrokeLineWidth(lineWidth.device.outline)
				.setTranslation(me.myCenter);
	},

	addPullUpCue: func {
        me.pullup_cue = me.canvas.createGroup().set("z-index", 20000);
        me.pullup_cue.createChild("path")
           .moveTo(0, 0)
           .lineTo(me.uvMap[0]*me.resolution[0], me.uvMap[1]*me.resolution[1])
           .moveTo(0, me.uvMap[1]*me.resolution[1])
           .lineTo(me.uvMap[0]*me.resolution[0], 0)
           .setStrokeLineWidth(lineWidth.device.x)
           .setColor(colorCircle1);
    },

    pullUpCue: func (vis) {
    	me.pullup_cue.setVisible(vis and getprop("f16/avionics/power-mfd-bit")==3);
    },

    addControlFeedback: func {
    	me.feedbackRadius = 35;
    	me.cntlFeedback = me.controlGrp.createChild("path")
	            .moveTo(-me.feedbackRadius,0)
	            .arcSmallCW(me.feedbackRadius,me.feedbackRadius, 0,  me.feedbackRadius*2, 0)
	            .arcSmallCW(me.feedbackRadius,me.feedbackRadius, 0, -me.feedbackRadius*2, 0)
	            .close()
	            .setStrokeLineWidth(2)
	            .set("z-index",7)
	            .setColor(colorDot2[0],colorDot2[1],colorDot2[2],0.15)
	            .setColorFill(colorDot2[0],colorDot2[1],colorDot2[2],0.3)
	            .hide();
    },

	addSOILines: func () {
		me.tempMarginX = 11;
		me.tempMarginY = 10;
		me.soiLine = me.controlGrp.createChild("path")
				.set("z-index", 8)
				.moveTo(me.tempMarginX,me.tempMarginY)
				.horiz(me.uvMap[0]*me.resolution[0]-me.tempMarginX*2)
				.vert(me.resolution[1]-me.tempMarginY*2)
				.horiz(-me.uvMap[0]*me.resolution[0]+me.tempMarginX*2)
				.lineTo(me.tempMarginX,me.tempMarginY)
				.setColor(me.colorFront)
				.hide()
				.setStrokeLineWidth(lineWidth.device.soi);
		return me.soiLine;
	},

	addSOIText: func (info) {
		me.soiText = me.controlGrp.createChild("text")
				.set("z-index", 10)
				.setColor(me.colorFront)
				.setAlignment("center-center")
				.setTranslation(me.uvMap[0]*me.resolution[0]*0.5, me.uvMap[1]*me.resolution[1]*0.30)
				.setFontSize(me.fontSize)
				.setText(info);
		return me.soiText;
	},

	setSOI: func (soi) {
		# -1 will remove both text and square
		me.soiLine.setVisible(soi == 1);
		me.soiText.setVisible(soi == 0);
		me.soi = soi;
	},

	setF16SOI: func (no) {
		# What number f16 regards this device as
		me.aircraftSOI = no;
	},

	getSOIPrio: func {
		return me.system.getSOIPrio();
	},

	setControlTextColors: func (foreground, background) {
		me.colorFront = foreground;
		me.colorBack  = background;
	},

	initPage: func (page) {
		printDebug(me.name," init page ",page.name);
		if (page.needGroup) {
			me.tempGrp = me.canvas.createGroup()
							.set("z-index", 5)
							.set("font","LiberationFonts/LiberationMono-Regular.ttf")
							.hide();
			page.group = me.tempGrp;
		}
		page.device = me;
	},

	initLayer: func (layer) {
		printDebug(me.name," init layer ",layer.name);
		me.tempGrp = me.canvas.createGroup()
						.set("z-index", 200)
						.set("font","LiberationFonts/LiberationMono-Regular.ttf")
						.hide();
		layer.group = me.tempGrp;
		layer.device = me;
		layer.setup();
	},

	setSwapDevice: func (swapper) {
		me.swapWith = swapper;
	},

	swap: func {
		var myPageName = me.system.currPage.name;
		var otherPageName = me.swapWith.system.currPage.name;
		var mySoi = me.soi;
		var otherSoi = me.swapWith.soi;
		me.system.selectPage(otherPageName);
		me.swapWith.system.selectPage(myPageName);
		me.setSOI(otherSoi);
		me.swapWith.setSOI(mySoi);
		# The ==1 must be here below since soi can be -1 in the device:
		swapAircraftSOI(otherSoi == 1?me.aircraftSOI:mySoi==1?(me.swapWith.aircraftSOI):nil);
	},
};


#  ███████ ██    ██ ███████ ████████ ███████ ███    ███ 
#  ██       ██  ██  ██         ██    ██      ████  ████ 
#  ███████   ████   ███████    ██    █████   ██ ████ ██ 
#       ██    ██         ██    ██    ██      ██  ██  ██ 
#  ███████    ██    ███████    ██    ███████ ██      ██ 
#                                                       
#                                                       

var DisplaySystem = {
	new: func () {
		var system = {parents : [DisplaySystem] };
		system.new = func {return nil;};
		return system;
	},

	del: func {
		
	},

	setDevice: func (device) {
		me.device = device;
	},

	initDevice: func (propertyNum, controlPositions, fontSize) {
		me.device.addControls(PUSHBUTTON,  "OSB", 1, 20, "controls/MFD["~propertyNum~"]/button-pressed", controlPositions);
		#me.device.addControls(ROCKERSWITCH,"GAIN", 0, 1, "f16/avionics/mfd-"~(propertyNum?"r":"l")~"-gain", controlPositions);
		me.device.fontSize = fontSize;

		for (var i = 1; i <= 5; i+= 1) {
			me.device.addControlText("OSB", "OSB"~i, [margin.device.buttonText, 0], i-1,-1);
		}
		for (var i = 6; i <= 10; i+= 1) {
			me.device.addControlText("OSB", "OSB"~i, [-margin.device.buttonText, 0], i-1,1);
		}
		for (var i = 11; i <= 15; i+= 1) {
			me.device.addControlText("OSB", "OSB"~i, [0, margin.device.buttonText], i-1,0,-1);
		}
		for (var i = 16; i <= 20; i+= 1) {
			me.device.addControlText("OSB", "OSB"~i, [0, -margin.device.buttonText], i-1,0,1);
		}
		me.device.addSOILines();
		me.device.addSOIText("NOT SOI");
		me.device.setSOI(-1);
	},

	getSOIPrio: func {
		return me.currPage.supportSOI?me.currPage.soiPrio:-1;
	},

	initPage: func (pageName) {
		if (DisplaySystem[pageName] == nil) {print(pageName," does not exist");return;}
		me.tempPageInstance = DisplaySystem[pageName].new();
		me.device.initPage(me.tempPageInstance);
		me.pages[me.tempPageInstance.name] = me.tempPageInstance;
	},

	initLayer: func (layerName) {
		me.tempLayerInstance = DisplaySystem[layerName].new();
		me.device.initLayer(me.tempLayerInstance);
		me.layers[me.tempLayerInstance.name] = me.tempLayerInstance;
	},

	initPages: func () {
		me.pages = {};
		me.layers = {};

		me.initPage("PageFCRMode");
		me.initPage("PageMenu");
		me.initPage("PageSMSWPN");
		me.initPage("PageVoid");
		me.initPage("PageGrid");
		me.initPage("PageCube");
		me.initPage("PageDTE");
		me.initPage("PageFCR");
		me.initPage("PageFCRCNTL");
		me.initPage("PageHSD");
		me.initPage("PageHSDCNTL");
		me.initPage("PageHAS");
		me.initPage("PageReset");
		me.initPage("PageBlank");
		me.initPage("PageTest");
		me.initPage("PageRCCE");
		me.initPage("PageFLIR");
		me.initPage("PageTFR");
		me.initPage("PageSJ");
		me.initPage("PageTCN");
		me.initPage("PageSMSINV");
		#me.initPage("PageOSB");

		me.initLayer("SharedStations");
		me.initLayer("OSB1TO2ARROWS");
		me.initLayer("OSB3TO4ARROWS");
		me.initLayer("OSB4TO5ARROWS");
		me.initLayer("BULLSEYE");

#		me.device.doubleTimerRunning = nil;
		me.device.controlAction = func (type, controlName, propvalue) {
			me.tempLink = me.system.currPage.links[controlName];
			me.system.currPage.controlAction(controlName);
			if (me.tempLink != nil) {
#				if (me.doubleTimerRunning == nil) {
#					settimer(func me.controlActionDouble(), 0.25);
#					me.doubleTimerRunning = me.tempLink;
#					printDebug("Timer starting: ",me.doubleTimerRunning);
#				} elsif (me.doubleTimerRunning == me.tempLink) {
#					me.doubleTimerRunning = nil;
#					me.system.osbSelect = [me.tempLink, me.system.currPage];
#					me.system.selectPage("PageOSB");
#					printDebug("Doubleclick special");
#				} else {
#					me.doubleTimerRunning = nil;
					me.system.selectPage(me.tempLink);
#					printDebug("Timer interupted. Going to ",me.tempLink);
#				}
			}
		};

#		me.device.controlActionDouble = func {
#			printDebug("Timer ran: ",me.doubleTimerRunning);
#			if (me.doubleTimerRunning != nil) {
#				me.system.selectPage(me.doubleTimerRunning);
#				me.doubleTimerRunning = nil;
#			}
#		};

		append(me.device.listeners, setlistener("/f16/avionics/power-mfd-bit", func(node) {
            forcePages(node.getValue(), me);
        },0,0));
	},

	fetchLayer: func (layerName) {
		if (me.layers[layerName] == nil) {
			print("\n",me.device.name,": no such layer ",layerName);
			print("Available layers: ");
			foreach(var layer; keys(me.layers)) {
				print(layer);
			}
			print();
		}
		return me.layers[layerName];
	},

	supportSOI: func {
		return me.currPage.supportSOI;
	},

	update: func (noti) {
		me.currPage.update(noti);
		foreach(var layer; me.currPage.layers) {
			me.fetchLayer(layer).update(noti);
		}
	},

	selectPage: func (pageName) {
		if (me.pages[pageName] == nil) {print(me.device.name," page not found: ",pageName);return;}
		me.wasSOI = me.device.soi == 1;# The ==1 must be here since soi can be -1 in the device
		if (me["currPage"] != nil) {
			if(me.currPage.needGroup) me.currPage.group.hide();
			me.currPage.exit();
			foreach(var layer; me.currPage.layers) {
				me.fetchLayer(layer).group.hide();
			}
		}
		me.currPage = me.pages[pageName];
		if(me.currPage.needGroup) me.currPage.group.show();
		me.currPage.enter();
		#me.currPage.update(nil);
		foreach(var layer; me.currPage.layers) {
			me.fetchLayer(layer).group.show();
		}
		if (me.wasSOI and !me.currPage.supportSOI) f16.autoPrioritySOI();
	},

	PageOSB: {
		name: "PageOSB",
		isNew: 1,
		supportSOI: 0,
		needGroup: 1,
		new: func {
			me.instance = {parents:[DisplaySystem.PageOSB]};
			me.instance.group = nil;
			return me.instance;
		},
		setup: func {
			printDebug(me.name," on ",me.device.name," is being setup");
			me.pageText = me.group.createChild("text")
				.set("z-index", 10)
				.setColor(colorText1)
				.setAlignment("center-center")
				.setTranslation(displayWidthHalf, displayHeight*0.30)
				.setFontSize(me.device.fontSize)
				.setText("Select desired OSB");
		},
		enter: func {
			printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = 0;
			}
			me.device.resetControls();
			me.device.controls["OSB10"].setControlText("FCR");
			me.device.controls["OSB11"].setControlText("WPN");
			me.device.controls["OSB12"].setControlText("SMS");
			me.device.controls["OSB13"].setControlText("HSD");
			me.device.controls["OSB14"].setControlText("DTE");
			me.device.controls["OSB15"].setControlText("HAS");
			me.device.controls["OSB16"].setControlText("FCR\nMODE");
			me.device.controls["OSB17"].setControlText("MENU");
			me.device.controls["OSB19"].setControlText("CANCEL");
		},
		controlAction: func (controlName) {
			printDebug(me.name,": ",controlName," activated on ",me.device.name);
			if (controlName == "OSB19") {
				me.device.system.selectPage(me.device.system.osbSelect[1].name);
			} elsif (controlName == "OSB10") {
                me.device.system.osbSelect[1].links[me.device.system.osbSelect[0]] = "PageFCR";
                me.device.system.selectPage(me.device.system.osbSelect[1].name);
            } elsif (controlName == "OSB11") {
                me.device.system.osbSelect[1].links[me.device.system.osbSelect[0]] = "PageSMSWPN";
                me.device.system.selectPage(me.device.system.osbSelect[1].name);
            } elsif (controlName == "OSB12") {
                me.device.system.osbSelect[1].links[me.device.system.osbSelect[0]] = "PageSMSINV";
                me.device.system.selectPage(me.device.system.osbSelect[1].name);
            } elsif (controlName == "OSB13") {
                me.device.system.osbSelect[1].links[me.device.system.osbSelect[0]] = "PageHSD";
                me.device.system.selectPage(me.device.system.osbSelect[1].name);
            } elsif (controlName == "OSB14") {
                me.device.system.osbSelect[1].links[me.device.system.osbSelect[0]] = "PageDTE";
                me.device.system.selectPage(me.device.system.osbSelect[1].name);
            } elsif (controlName == "OSB15") {
                me.device.system.osbSelect[1].links[me.device.system.osbSelect[0]] = "PageHAS";
                me.device.system.selectPage(me.device.system.osbSelect[1].name);
            } elsif (controlName == "OSB16") {
                me.device.system.osbSelect[1].links[me.device.system.osbSelect[0]] = "PageFCRMode";
                me.device.system.selectPage(me.device.system.osbSelect[1].name);
            } elsif (controlName == "OSB17") {
                me.device.system.osbSelect[1].links[me.device.system.osbSelect[0]] = "PageMenu";
                me.device.system.selectPage(me.device.system.osbSelect[1].name);
            }
		},
		update: func (noti = nil) {			
		},
		exit: func {
			printDebug("Exit ",me.name~" on ",me.device.name);
		},
		links: {
		},
		layers: [],
	},

#  ██       █████  ██    ██ ███████ ██████      ███████ ████████  █████  
#  ██      ██   ██  ██  ██  ██      ██   ██     ██         ██    ██   ██ 
#  ██      ███████   ████   █████   ██████      ███████    ██    ███████ 
#  ██      ██   ██    ██    ██      ██   ██          ██    ██    ██   ██ 
#  ███████ ██   ██    ██    ███████ ██   ██     ███████    ██    ██   ██ 
#                                                                        
#                                                                        

	SharedStations: {
		name: "SharedStations",
		new: func {
			var layer = {parents:[DisplaySystem.SharedStations]};
			return layer;
		},
		setup: func {
			me.group.setTranslation(displayWidthHalf, displayHeight);
			me.sta      = setsize([], 9);# 9 stations
	        me.staFrame = setsize([], 9);
	        var staPosY = -displayHeight*0.20;
	        var staFont = 17;
	        var staStroke = lineWidth.stations.outline;
	        var staX = 7;
	        var staY = 9;
	        var staW = 15;
	        var staH = 19;
	        me.sta[0] = me.group.createChild("text")
	           .setTranslation(displayWidthHalf * -0.85, staPosY)
	           .setAlignment("center-center")
	           .setText("1")
	           .set("z-index",12)
	           .setFontSize(staFont, 1.0)
	           .hide()
	           .setColor(colorText1);
	        me.sta[1] = me.group.createChild("text")
	           .setTranslation(displayWidthHalf * -0.75, staPosY)
	           .setAlignment("center-center")
	           .setText("2")
	           .set("z-index",12)
	           .setFontSize(staFont, 1.0)
	           .hide()
	           .setColor(colorText1);
	        me.sta[2] = me.group.createChild("text")
	           .setTranslation(displayWidthHalf * -0.65, staPosY)
	           .setAlignment("center-center")
	           .setText("3")
	           .set("z-index",12)
	           .setFontSize(staFont, 1.0)
	           .hide()
	           .setColor(colorText1);
	        me.sta[3] = me.group.createChild("text")
	           .setTranslation(displayWidthHalf * -0.55, staPosY)
	           .setAlignment("center-center")
	           .setText("4")
	           .set("z-index",12)
	           .setFontSize(staFont, 1.0)
	           .hide()
	           .setColor(colorText1);
	        me.sta[4] = me.group.createChild("text")
	           .setTranslation(displayWidthHalf * 0.0, staPosY)
	           .setAlignment("center-center")
	           .setText("5")
	           .set("z-index",12)
	           .setFontSize(staFont, 1.0)
	           .hide()
	           .setColor(colorText1);
	        me.sta[5] = me.group.createChild("text")
	           .setTranslation(displayWidthHalf * 0.55, staPosY)
	           .setAlignment("center-center")
	           .setText("6")
	           .set("z-index",12)
	           .setFontSize(staFont, 1.0)
	           .hide()
	           .setColor(colorText1);
	        me.sta[6] = me.group.createChild("text")
	           .setTranslation(displayWidthHalf * 0.65, staPosY)
	           .setAlignment("center-center")
	           .setText("7")
	           .set("z-index",12)
	           .setFontSize(staFont, 1.0)
	           .hide()
	           .setColor(colorText1);
	        me.sta[7] = me.group.createChild("text")
	           .setTranslation(displayWidthHalf * 0.75, staPosY)
	           .setAlignment("center-center")
	           .setText("8")
	           .set("z-index",12)
	           .setFontSize(staFont, 1.0)
	           .hide()
	           .setColor(colorText1);
	        me.sta[8] = me.group.createChild("text")
	           .setTranslation(displayWidthHalf * 0.85, staPosY)
	           .setAlignment("center-center")
	           .setText("9")
	           .set("z-index",12)
	           .setFontSize(staFont, 1.0)
	           .hide()
	           .setColor(colorText1);
	        me.staFrame[0] = me.group.createChild("path")
	           .moveTo(displayWidthHalf * -0.85 + staX, staPosY+staY)
	           .vert(-staH)
	           .horiz(-staW)
	           .vert(staH)
	           .horiz(staW)
	           .setColor(colorText1)
	           .hide()
	           .setStrokeLineWidth(staStroke);
	        me.staFrame[1] = me.group.createChild("path")
	           .moveTo(displayWidthHalf * -0.75 + staX, staPosY+staY)
	           .vert(-staH)
	           .horiz(-staW)
	           .vert(staH)
	           .horiz(staW)
	           .setColor(colorText1)
	           .hide()
	           .setStrokeLineWidth(staStroke);
	        me.staFrame[2] = me.group.createChild("path")
	           .moveTo(displayWidthHalf * -0.65 + staX, staPosY+staY)
	           .vert(-staH)
	           .horiz(-staW)
	           .vert(staH)
	           .horiz(staW)
	           .setColor(colorText1)
	           .hide()
	           .setStrokeLineWidth(staStroke);
	        me.staFrame[3] = me.group.createChild("path")
	           .moveTo(displayWidthHalf * -0.55 + staX, staPosY+staY)
	           .vert(-staH)
	           .horiz(-staW)
	           .vert(staH)
	           .horiz(staW)
	           .setColor(colorText1)
	           .hide()
	           .setStrokeLineWidth(staStroke);
	        me.staFrame[4] = me.group.createChild("path")
	           .moveTo(displayWidthHalf * 0.0 + staX, staPosY+staY)
	           .vert(-staH)
	           .horiz(-staW)
	           .vert(staH)
	           .horiz(staW)
	           .setColor(colorText1)
	           .hide()
	           .setStrokeLineWidth(staStroke);
	        me.staFrame[5] = me.group.createChild("path")
	           .moveTo(displayWidthHalf * 0.55 + staX, staPosY+staY)
	           .vert(-staH)
	           .horiz(-staW)
	           .vert(staH)
	           .horiz(staW)
	           .setColor(colorText1)
	           .hide()
	           .setStrokeLineWidth(staStroke);
	        me.staFrame[6] = me.group.createChild("path")
	           .moveTo(displayWidthHalf * 0.65 + staX, staPosY+staY)
	           .vert(-staH)
	           .horiz(-staW)
	           .vert(staH)
	           .horiz(staW)
	           .setColor(colorText1)
	           .hide()
	           .setStrokeLineWidth(staStroke);
	        me.staFrame[7] = me.group.createChild("path")
	           .moveTo(displayWidthHalf * 0.75 + staX, staPosY+staY)
	           .vert(-staH)
	           .horiz(-staW)
	           .vert(staH)
	           .horiz(staW)
	           .setColor(colorText1)
	           .hide()
	           .setStrokeLineWidth(staStroke);
	        me.staFrame[8] = me.group.createChild("path")
	           .moveTo(displayWidthHalf * 0.85 + staX, staPosY+staY)
	           .vert(-staH)
	           .horiz(-staW)
	           .vert(staH)
	           .horiz(staW)
	           .setColor(colorText1)
	           .hide()
	           .setStrokeLineWidth(staStroke);
	    },
	    init: func (page, callback) {
	    	me.callback = callback;
	    	me.page = page;
	    },
	    update: func (noti = nil) {
	    	if (me["callback"] != nil and me["page"] != nil) {
	    		me.info = call(me.callback, [], me.page, var err = []);
		    	if(size(err)) {
					foreach(var i;err) {
			          print(i);
			        }
			        return;
				}
				me.indices = pylons.fcs.getStationIndecesForSelectedType(me.info[0]);
				me.offsetY  = me.info[1];
	    	} else {
	    		me.indices = pylons.fcs.getStationIndecesForSelectedType();
	    		me.offsetY = 0;
	    	} 	
	    	me.group.setTranslation(displayWidthHalf, displayHeight+me.offsetY);
            for (me.indi = 0; me.indi < 9; me.indi += 1) {
                me.sta[me.indi].setVisible(me.indices[me.indi] > -1);
                me.staFrame[me.indi].setVisible(me.indices[me.indi] == 1);
            }
	    },
	},

#  ██       █████  ██    ██ ███████ ██████      ██████  ██    ██ ██      ██      ███████ ███████ ██    ██ ███████ 
#  ██      ██   ██  ██  ██  ██      ██   ██     ██   ██ ██    ██ ██      ██      ██      ██       ██  ██  ██      
#  ██      ███████   ████   █████   ██████      ██████  ██    ██ ██      ██      ███████ █████     ████   █████   
#  ██      ██   ██    ██    ██      ██   ██     ██   ██ ██    ██ ██      ██           ██ ██         ██    ██      
#  ███████ ██   ██    ██    ███████ ██   ██     ██████   ██████  ███████ ███████ ███████ ███████    ██    ███████ 
#                                                                                                                 
#                                                                                                                 

	BULLSEYE: {
		name: "BULLSEYE",
		new: func {
			var layer = {parents:[DisplaySystem.BULLSEYE]};
			layer.offset = 0;
			return layer;
		},
		setup: func {
			me.group.setTranslation(displayWidthHalf,displayHeight);
			me.bullOwnRing = me.group.createChild("path")
	            .moveTo(-15*symbolSize.bullseye.eye,0)
	            .arcSmallCW(15*symbolSize.bullseye.eye,15*symbolSize.bullseye.eye, 0,  15*2*symbolSize.bullseye.eye, 0)
	            .arcSmallCW(15*symbolSize.bullseye.eye,15*symbolSize.bullseye.eye, 0, -15*2*symbolSize.bullseye.eye, 0)
	            .close()
	            .moveTo(0,-18*symbolSize.bullseye.eye)
	            .lineTo(8*symbolSize.bullseye.eye,-12.5*symbolSize.bullseye.eye)
	            .moveTo(0,-18*symbolSize.bullseye.eye)
	            .lineTo(-8*symbolSize.bullseye.eye,-12.5*symbolSize.bullseye.eye)
	            .close()
	            .setStrokeLineWidth(lineWidth.bullseyeLayer.eye)
	            .setStrokeLineCap("round")
	            .setTranslation(-margin.bullseye.x, -margin.bullseye.y)
	            .set("z-index",1)
	            .setColor(colorBullseye);
	        me.bullOwnDist = me.group.createChild("text")
	                .setAlignment("center-center")
	                .setColor(colorBullseye)
	                .setTranslation(-margin.bullseye.x, -margin.bullseye.y)
	                .setText("12")
	                .set("z-index",1)
	                .setFontSize(18, 1.0);
	        me.bullOwnDir = me.group.createChild("text")
	                .setAlignment("center-top")
	                .setColor(colorBullseye)
	                .setTranslation(-margin.bullseye.x, -margin.bullseye.y+margin.bullseye.text)
	                .setText("270")
	                .set("z-index",1)
	                .setFontSize(18, 1.0);
	        me.refW = me.group.createChild("path")
	            .moveTo(-30*symbolSize.bullseye.ref, -5*symbolSize.bullseye.ref)
	            .lineTo(-20*symbolSize.bullseye.ref, -5*symbolSize.bullseye.ref)
	            .lineTo(-10*symbolSize.bullseye.ref, 15*symbolSize.bullseye.ref)
	            .lineTo(  0*symbolSize.bullseye.ref, -5*symbolSize.bullseye.ref)
	            .lineTo( 10*symbolSize.bullseye.ref, 15*symbolSize.bullseye.ref)
	            .lineTo( 20*symbolSize.bullseye.ref, -5*symbolSize.bullseye.ref)
	            .lineTo( 30*symbolSize.bullseye.ref, -5*symbolSize.bullseye.ref)
	            .setStrokeLineWidth(lineWidth.bullseyeLayer.ref)
	            .setScale(0.9, 1)
	            .setTranslation(-margin.bullseye.x+5, -margin.bullseye.y)
	            .set("z-index",1)
	            .setColor(colorBullseye);
	        me.refLine = me.group.createChild("path")
	        	.moveTo(  0, -20*symbolSize.bullseye.ref)
	            .lineTo(  0,  30*symbolSize.bullseye.ref)
	            .setStrokeLineWidth(lineWidth.bullseyeLayer.ref)
	            .setTranslation(-margin.bullseye.x+5, -margin.bullseye.y)
	            .set("z-index",1)
	            .setColor(colorBullseye);
	    },
	    update: func (noti = nil) {
	    	#
            # Bulls-eye info
            #
            me.bullPt = steerpoints.getNumber(steerpoints.index_of_bullseye);
            me.bullOn = me.bullPt != nil;
            me.refOn = steerpoints.getCurrentNumber() > 0;
            if (pylons.fcs != nil) {
            	me.bullOn = me.bullOn and pylons.fcs.isAAMode();
        	}
            if (me.bullOn) {
                me.bullLat = me.bullPt.lat;
                me.bullLon = me.bullPt.lon;
                me.bullCoord = geo.Coord.new().set_latlon(me.bullLat,me.bullLon);
                me.ownCoord = geo.aircraft_position();
                me.bullDirToMe = me.bullCoord.course_to(me.ownCoord);
                me.meToBull = ((me.bullDirToMe+180)-noti.getproper("heading"))*D2R;
                me.bullOwnRing.setRotation(me.meToBull);
                me.bullDistToMe = me.bullCoord.distance_to(me.ownCoord)*M2NM;

                me.bullDirToMe = sprintf("%03d", me.bullDirToMe);
                if (me.bullDistToMe > 100) {
                    me.bullDistToMe = "  ";
                } else {
                    me.bullDistToMe = sprintf("%02d", me.bullDistToMe);
                }
                me.bullOwnDir.setText(me.bullDirToMe);
                me.bullOwnDist.setText(me.bullDistToMe);
            } elsif (me.refOn) {
            	me.dev = steerpoints.getCurrentDeviation();
            	me.refLine.setTranslation(-margin.bullseye.x+5+math.clamp(me.dev*0.5,-25*symbolSize.bullseye.ref,25*symbolSize.bullseye.ref), -margin.bullseye.y);
            }
            me.refLine.setVisible(!me.bullOn and me.refOn);
            me.refW.setVisible(!me.bullOn and me.refOn);
            me.bullOwnRing.setVisible(me.bullOn);
            me.bullOwnDir.setVisible(me.bullOn);
            me.bullOwnDist.setVisible(me.bullOn);
	    },
	},

#  ██       █████  ██    ██ ███████ ██████       █████  ██████  ██████   ██████  ██     ██ ███████ 
#  ██      ██   ██  ██  ██  ██      ██   ██     ██   ██ ██   ██ ██   ██ ██    ██ ██     ██ ██      
#  ██      ███████   ████   █████   ██████      ███████ ██████  ██████  ██    ██ ██  █  ██ ███████ 
#  ██      ██   ██    ██    ██      ██   ██     ██   ██ ██   ██ ██   ██ ██    ██ ██ ███ ██      ██ 
#  ███████ ██   ██    ██    ███████ ██   ██     ██   ██ ██   ██ ██   ██  ██████   ███ ███  ███████ 
#                                                                                                  
#                                                                                                  

	OSB1TO2ARROWS: {
		name: "OSB1TO2ARROWS",
		new: func {
			var layer = {parents:[DisplaySystem.OSB1TO2ARROWS]};
			layer.offset = 0;
			return layer;
		},
		setup: func {
			me.group.setTranslation(0, me.offset);
			me.leftMargin = 5;
			me.up = me.group.createChild("path")
						.set("z-index", 20)
						.setStrokeLineJoin("round") # "miter", "round" or "bevel"
	                    .moveTo(me.leftMargin,displayHeightHalf-105-27.5)
	                    .horiz(30)
	                    .lineTo(15+me.leftMargin,displayHeightHalf-105-27.5-15)
	                    .lineTo(me.leftMargin,displayHeightHalf-105-27.5)
	                    .close()
	                    .setStrokeLineWidth(lineWidth.arrows.triangle)
	                    .hide()
	                    .setColor(me.device.colorFront);
	        me.txt = me.group.createChild("text")
		        		.set("z-index", 20)
		                .setTranslation(me.leftMargin+me.device.fontSize*0.75, displayHeightHalf-105)
		                .setAlignment("center-center")
		                .setColor(me.device.colorFront)
		                .setFontSize(me.device.fontSize, 1.0);
	        me.down = me.group.createChild("path")
	        			.set("z-index", 20)
	        			.setStrokeLineJoin("round")
	                    .moveTo(me.leftMargin,displayHeightHalf-105+27.5)
	                    .horiz(30)
	                    .lineTo(me.leftMargin+15,displayHeightHalf-105+27.5+15)
	                    .lineTo(me.leftMargin,displayHeightHalf-105+27.5)
	                    .close()
	                    .setStrokeLineWidth(lineWidth.arrows.triangle)
	                    .hide()
	                    .setColor(me.device.colorFront);
	        me.plate = me.group.createChild("path")
	        			.set("z-index", 10)
	                    .moveTo(me.leftMargin,displayHeightHalf-105+27.5+15)
	                    .horiz(30)
	                    .vert(-85)
	                    .horiz(-30)
	                    .vert(85)
	                    .close()
	                    .setStrokeLineWidth(1)
	                    .setColorFill(me.device.colorBack)
	                    .setColor(me.device.colorBack);
	    },
	    init: func (page, callback) {
	    	me.callback = callback;
	    	me.page = page;
	    },
	    update: func (noti = nil) {
	    	if (me["callback"] == nil) {printDebug("Callback is nil");return;}
	    	if (me["page"] == nil) {printDebug("Callback context is nil");return;}
	    	me.info = call(me.callback, [], me.page, var err = []);
	    	if(size(err)) {
				foreach(var i;err) {
		          print(i);
		        }
		        return;
			}
	    	me.group.setVisible(me.info[0]);
	    	me.txt.setText(me.info[1]);
	    	me.down.setVisible(me.info[2]);
	    	me.up.setVisible(me.info[3]);
	    },
	},

	OSB3TO4ARROWS: {
		name: "OSB3TO4ARROWS",
		new: func {
			var layer = {parents:[DisplaySystem.OSB3TO4ARROWS, DisplaySystem.OSB1TO2ARROWS]};
			layer.offset = 140;
			return layer;
		},
	},

	OSB4TO5ARROWS: {
		name: "OSB4TO5ARROWS",
		new: func {
			var layer = {parents:[DisplaySystem.OSB4TO5ARROWS, DisplaySystem.OSB1TO2ARROWS]};
			layer.offset = 210;
			return layer;
		},
	},

#  ███████ ███    ███ ███████     ██     ██ ██████  ███    ██ 
#  ██      ████  ████ ██          ██     ██ ██   ██ ████   ██ 
#  ███████ ██ ████ ██ ███████     ██  █  ██ ██████  ██ ██  ██ 
#       ██ ██  ██  ██      ██     ██ ███ ██ ██      ██  ██ ██ 
#  ███████ ██      ██ ███████      ███ ███  ██      ██   ████ 
#                                                             
#                                                             

	PageSMSWPN: {
		name: "PageSMSWPN",
		isNew: 1,
		supportSOI: 0,
		needGroup: 0,
		new: func {
			me.instance = {parents:[DisplaySystem.PageSMSWPN]};
			me.instance.group = nil;
			return me.instance;
		},
		enter: func {
			printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = 0;
			}
			me.device.resetControls();
			me.device.controls["OSB11"].setControlText("FCR");
			me.device.controls["OSB16"].setControlText("SWAP");
            me.device.controls["OSB17"].setControlText("HSD");
            me.device.controls["OSB18"].setControlText("SMS");
            me.device.controls["OSB19"].setControlText("WPN", 0);
            me.device.controls["OSB20"].setControlText("TGP");
            me.device.system.fetchLayer("OSB1TO2ARROWS").init(me, me.getOSB1TO2ARROWS);
            me.device.system.fetchLayer("OSB4TO5ARROWS").init(me, me.getOSB4TO5ARROWS);
		},
		getOSB1TO2ARROWS: func {
			return [me.rangeVis, me.rangeText, me.showRangeDown, me.showRangeUp];
		},
        getOSB4TO5ARROWS: func {
			return [me.dist, me.distA, me.distDownA, me.distUpA];
		},
		controlAction: func (controlName) {
			printDebug(me.name,": ",controlName," activated on ",me.device.name);
			if (controlName == "OSB1") {
                if (variantID == 0) {
                    return;
                }
                if (me.wpnType == "fall") {
                    me.at = 1;
                }
            } elsif (controlName == "OSB2") {
                if (variantID == 0) {
                    return;
                }
                if (me.wpnType == "fall") {
                    me.at = -1;
                }
            } elsif (controlName == "OSB3") {
                if (variantID == 0) {
                    return;
                }
                if (me.wpnType == "heat") {
                    var auto = pylons.fcs.isAutocage();
                    auto = !auto;
                    pylons.fcs.setAutocage(auto);
                }
                me.wpn_ = pylons.fcs.getSelectedWeapon();
                if (me.wpn_ != nil and me.wpn_.type == "GBU-54") {
                    me.guide54 = me.wpn_.guidance;
                    if (me.guide54 == "gps") {
                        me.wpn_.guidance = "gps-laser";
                    } else {
                        me.wpn_.guidance = "gps";
                    }
                }
            } elsif (controlName == "OSB4") {
                if (variantID == 0) {
                    return;
                }
                if (me.wpnType == "fall") {
                    me.ar = 25;
                }                    
            } elsif (controlName == "OSB5") {
                if (variantID == 0) {
                    return;
                }
                if (me.wpnType == "fall") {
                    me.ar = -25;
                }
            } elsif (controlName == "OSB6") {
                if (variantID == 0) {
                    return;
                }
                pylons.fcs.cycleLoadedWeapon();
            } elsif (controlName == "OSB7") {
                if (variantID == 0) {
                    return;
                }
                me.wpn_ = pylons.fcs.getSelectedWeapon();
                if (me.wpn_ != nil and me.wpn_["powerOnRequired"] == 1) {
                    pylons.fcs.togglePowerOn();
                }
            } elsif (controlName == "OSB8") {
                if (variantID == 0) {
                    return;
                }
                if (me.wpnType == "fall") {
                    var rp = pylons.fcs.getRippleMode();
                    if (rp < 9) {
                        rp += 1;
                    } elsif (rp == 9) {
                        rp = 1;
                    }
                    pylons.fcs.setRippleMode(rp);
                } elsif (me.wpnType == "rocket") {
                    var rp = pylons.fcs.getRRippleMode();
                    if (rp < 28) {
                        rp += 1;
                    } elsif (rp == 28) {
                        rp = 1;
                    }
                    pylons.fcs.setRRippleMode(rp);
                }
            } elsif (controlName == "OSB9") {
                if (variantID == 0) {
                    return;
                }
                if (me.wpnType == "fall") {
                    if (getprop("controls/armament/dual")==1) {
                        setprop("controls/armament/dual",2);
                    } else {
                        setprop("controls/armament/dual",1);
                    }
                } elsif (me.wpnType=="heat") {
                    me.cooling = !pylons.fcs.getSelectedWeapon().isCooling();
                    foreach(var snake;pylons.fcs.getAllOfType("AIM-9L")) {
                        snake.setCooling(me.cooling);
                    }
                    foreach(var snake;pylons.fcs.getAllOfType("AIM-9M")) {
                        snake.setCooling(me.cooling);
                    }
                    foreach(var snake;pylons.fcs.getAllOfType("AIM-9X")) {
                        snake.setCooling(me.cooling);
                    }
                }
            } elsif (controlName == "OSB10") {
                if (variantID == 0) {
                    return;
                }
            } elsif (controlName == "OSB12") {
                if (variantID == 0) {
                    return;
                }
                if (me.wpnType == "fall") {
                    pylons.fcs.setDropMode(!pylons.fcs.getDropMode());
                } elsif (me.wpnType=="anti-rad") {
                    me.device.system.selectPage("PageHAS");
                }
            } elsif (controlName == "OSB13") {
                if (variantID == 0) {
                    return;
                }
                if (me.wpnType == "heat") {
                    pylons.fcs.toggleXfov();
                }
            } elsif (controlName == "OSB14") {
                if (variantID == 0) {
                    return;
                }
                if (me.wpnType == "gun") {
                    setprop("f16/avionics/strf", !getprop("f16/avionics/strf"));
                }
            } elsif (controlName == "OSB16") {
                me.device.swap();
            } elsif (controlName == "OSB20") {
                switchTGP();
            }
		},
		setup: func {
			printDebug(me.name," on ",me.device.name," is being setup");

			# Init vars used in layer callbacks:
	        me.rangeVis = 0;
	        me.rangeText = "";
	        me.showRangeDown = 0;
	        me.showRangeUp = 0;
	        me.distDownA = 0;
            me.distUpA = 0;
            me.distA = "";
            me.dist = 0;
		},
		update: func (noti) {
            if (noti.FrameCount != 3)
                return;
            if (variantID == 0) {
                return;
            }

			if (me["at"]== nil) {
                me.at = 0;
            }
            if (me["ar"]== nil) {
                me.ar = 0;
            }
            me.wpn = pylons.fcs.getSelectedWeapon();
            me.pylon = pylons.fcs.getSelectedPylon();

            me.wpnType = "";
            me.status = "";
            me.osb3 = "";
            me.osb5 = "";
            me.osb6 = "";
            me.osb8 = "";
            me.osb7 = "";
            me.osb9 = "";
            me.osb10 = "";
            me.osb12 = "";
            me.osb13 = "";
            me.osb14 = "";
            me.rippleDist = "";
            me.downAd = 0;
            me.upAd = 0;
            me.osb9Frame = 0;
            me.downA = 0;
            me.upA = 0;
            me.armtimer = "";            
            me.showDist = 0;

            if (me.wpn != nil and me.pylon != nil and me.wpn["typeShort"] != nil) {
                if (me.wpn.type == "MK-82" or me.wpn.type == "MK-82AIR" or me.wpn.type == "MK-83" or me.wpn.type == "MK-84" or me.wpn.type == "GBU-12" or me.wpn.type == "GBU-24"
                    or me.wpn.type == "GBU-54" or me.wpn.type == "CBU-87" or me.wpn.type == "CBU-105" or me.wpn.type == "GBU-31" or me.wpn.type == "B61-7" or me.wpn.type == "B61-12") {
                    me.wpnType ="fall";
                    var nm = pylons.fcs.getDropMode();
                    if (nm == fc.DROP_CCIP) {me.osb12 = "CCIP";me.osb13=armament.contact != nil and armament.contact.get_type() != armament.AIR?"PRE":"VIS";}
                    if (nm == fc.DROP_CCRP) {me.osb12 = "CCRP";me.osb13="PRE"}
                    var rp = pylons.fcs.getRippleMode();
                    var rpd = pylons.fcs.getRippleDist()*M2FT;
                    me.osb8 = "RP "~rp;
                    if (rp > 1) {
                        me.showDist = 1;
                    }
                    rpd += me.ar;
                    if (rpd < 25) {
                        rpd = 25;
                    } elsif (rpd > 400) {
                        rpd = 400;
                    }
                    pylons.fcs.setRippleDist(FT2M * rpd);
                    me.downAd = rpd>25 and me.showDist;
                    me.upAd = rpd<400 and me.showDist;
                    if (me.wpn.type == "GBU-54") {
                        if (me.wpn.guidance == "gps-laser") {
                            me.osb3 = "GPS-LASR";
                        } else {
                            me.osb3 = "GPS";
                        }
                    }
                    me.rippleDist = sprintf("RP %3d FT",math.round(rpd));

                    if (me.wpn.powerOnRequired) {
                        me.osb7 = me.wpn.isPowerOn()?"PWR\nON":"PWR\nOFF";
                    }

                    me.osb14 = "A-G";
                    me.wpn.arming_time += me.at;
                    if (me.wpn.arming_time < 0) {
                        me.wpn.arming_time = 0;
                    } elsif (me.wpn.arming_time > 20) {
                        me.wpn.arming_time = 20;
                    }
                    if (me.at != 0) {
                        foreach(var bomb;pylons.fcs.getAllOfType(me.wpn.type)) {
                            bomb.arming_time = me.wpn.arming_time;
                        }
                    }
                    me.armtime = me.wpn.arming_time;
                    me.downA = me.armtime>0;
                    me.upA = me.armtime<20;
                    me.armtimer = sprintf("AD %.2fSEC",me.armtime);#arming delay
                    me.osb9 = getprop("controls/armament/dual")==1?"SGL":"PAIR";
                    me.setWeaponStatus();
                } elsif (me.wpn.type == "AGM-65B" or me.wpn.type == "AGM-65D" or me.wpn.type == "AGM-84" or me.wpn.type == "AGM-119" or me.wpn.type == "AGM-158" or me.wpn.type == "AGM-154A") {
                    # Smart weapons that needs power on.
                    me.wpnType ="ground";
                    me.osb14 = "A-G";
                    me.osb7 = me.wpn.isPowerOn()?"PWR\nON":"PWR\nOFF";
                    me.setWeaponStatus();
                } elsif (me.wpn.type == "AGM-88") {
                    me.wpnType ="anti-rad";
                    me.osb14 = "A-G";
                    me.osb12 = "HAS";
                    me.osb7 = me.wpn.isPowerOn()?"PWR\nON":"PWR\nOFF";
                    me.setWeaponStatus();
                } elsif (me.wpn.type == "AIM-9L" or me.wpn.type == "AIM-9M" or me.wpn.type == "AIM-9X") {
                    me.wpnType ="heat";
                    me.osb9 = me.wpn.getWarm()==0?"COOL":"WARM";
                    me.osb14 = "A-A";
                    me.osb13 = pylons.fcs.isXfov()?"SCAN":"SPOT";
                    me.osb9Frame = me.wpn.isCooling()==1?1:0;
                    me.osb12 = pylons.bore>0?"BORE":"SLAV";
                    me.osb3 = pylons.fcs.isAutocage()?"TD":"BP";
                    me.setWeaponStatus();
                } elsif (me.wpn.type == "AIM-120" or me.wpn.type == "AIM-7") {
                    me.wpnType ="air";
                    me.osb12 = "SLAV";
                    me.osb14 = "A-A";
                    me.setWeaponStatus();
                } elsif (me.wpn.type == "20mm Cannon") {
                    me.wpnType ="gun";
                    me.osb14 = getprop("f16/avionics/strf")?"STRF":"EEGS";
                    if (me.pylon.operableFunction != nil and !me.pylon.operableFunction()) {
                        me.status = "MAL";
                    } else {
                        if (getprop("controls/armament/master-arm-switch") == pylons.ARM_SIM) me.status = "SIM";
                        else me.status = "RDY";
                    }
                } elsif (me.wpn.type == "LAU-68") {
                    me.wpnType ="rocket";
                    me.osb14 = "A-G";
                    var rp = pylons.fcs.getRRippleMode();
                    me.osb8 = "RP "~rp;
                    if (me.pylon.operableFunction != nil and !me.pylon.operableFunction()) {
                        me.status = "MAL";
                    } else {
                        if (getprop("controls/armament/master-arm-switch") == pylons.ARM_SIM) me.status = "SIM";
                        else me.status = "RDY";
                    }
                } else {
                    #printDebug(me.wpn.type~" not supported in WPN page.");
                    me.wpnType ="void";
                }
                me.myammo = pylons.fcs.getAmmo();
                if (me.wpn.type == "20mm Cannon") {
                    if (me.myammo ==0) me.myammo = "0";
                    elsif (me.myammo <10) me.myammo = "1";
                    else me.myammo = ""~int(me.myammo*0.1);
                #} elsif (me.myammo==1) {
                #    me.myammo = "";
                } else {
                    me.myammo = ""~me.myammo;
                }
                
                me.osb6 = sprintf("%4s   %7s",me.status,me.myammo~me.wpn.typeShort);
                if (0 and getprop("controls/armament/master-arm") != 1) {
                    me.osb8 = "";# What was this for??
                }
            } else {
                me.osb6 = "";
            }
            
            me.device.controls["OSB3"].setControlText(me.osb3);
            me.device.controls["OSB5"].setControlText(me.osb5);
            me.device.controls["OSB6"].setControlText(me.osb6);
            me.device.controls["OSB7"].setControlText(me.osb7);
            me.device.controls["OSB8"].setControlText(me.osb8);
            me.device.controls["OSB9"].setControlText(me.osb9, 1, me.osb9Frame);
            me.device.controls["OSB10"].setControlText(me.osb10);
            me.device.controls["OSB12"].setControlText(me.osb12);
            me.device.controls["OSB13"].setControlText(me.osb13);
            me.device.controls["OSB14"].setControlText(me.osb14);

            # send to layer:
            me.rangeVis = me.upA or me.downA;
            me.showRangeUp = me.upA;
            me.showRangeDown = me.downA;
            me.rangeText = me.armtimer;

            me.distDownA = me.downAd;
            me.distUpA = me.upAd;
            me.distA = me.rippleDist;
            me.dist = me.showDist;

            me.at = 0;
            me.ar = 0;
        },

		setWeaponStatus: func {
            # The order of these IF is delicate
            if (me.pylon.operableFunction != nil and !me.pylon.operableFunction()) {
                me.status = "MAL";
            } elsif (me.wpn.powerOnRequired and me.wpn.isPowerOn() and !me.wpn.hasPowerEnough()) {
                me.status = "MAL";
            } elsif (me.wpn.status < armament.MISSILE_STARTING or (me.wpn.powerOnRequired and !me.wpn.isPowerOn())) {
                me.status = "OFF";
            } elsif (me.wpn.powerOnRequired and me.wpn.status == armament.MISSILE_STARTING and me.wpn.hasPowerEnough()) {
                me.status = "NOT TIMED OUT";
            } elsif (me.wpn.status == armament.MISSILE_STARTING) {
                me.status = "INIT";
            } else {
                if (getprop("controls/armament/master-arm-switch") == pylons.ARM_SIM) me.status = "SIM";
                else me.status = "RDY";
            }
        },
        exit: func {
			printDebug("Exit ",me.name~" on ",me.device.name);
		},
		links: {
			"OSB11": "PageFCR",
			"OSB17": "PageHSD",
			"OSB18": "PageSMSINV",
			"OSB19": "PageMenu",
		},
        layers: ["SharedStations", "OSB1TO2ARROWS", "OSB4TO5ARROWS","BULLSEYE"],
    },

#  ███████  ██████ ██████      ███    ███  ██████  ██████  ███████ 
#  ██      ██      ██   ██     ████  ████ ██    ██ ██   ██ ██      
#  █████   ██      ██████      ██ ████ ██ ██    ██ ██   ██ █████   
#  ██      ██      ██   ██     ██  ██  ██ ██    ██ ██   ██ ██      
#  ██       ██████ ██   ██     ██      ██  ██████  ██████  ███████ 
#                                                                  
#                                                                  

	PageFCRMode: {
		name: "PageFCRMode",
		isNew: 1,
		supportSOI: 1,
		soiPrio: 9,
		needGroup: 0,
		new: func {
			me.instance = {parents:[DisplaySystem.PageFCRMode]};
			me.instance.group = nil;
			return me.instance;
		},
		setup: func {
			printDebug(me.name," on ",me.device.name," is being setup");
		},
		enter: func {
			if (me.device["DGFT"]) {me.device.system.selectPage("PageFCR");return;}# TODO: check it works
			printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = 0;
			}
			me.device.resetControls();
			me.device.controls["OSB1"].setControlText("CRM");
			me.device.controls["OSB2"].setControlText("ACM");
			me.device.controls["OSB3"].setControlText("SEA");
			me.device.controls["OSB4"].setControlText("GM");
			me.device.controls["OSB5"].setControlText("GMT");
			me.device.controls["OSB11"].setControlText("FCR", 0);
			me.device.controls["OSB18"].setControlText("SWAP");
		},
		controlAction: func (controlName) {
			printDebug(me.name,": ",controlName," activated on ",me.device.name);
			if (controlName == "OSB18") {
				me.device.swap();
			} elsif (controlName == "OSB1") {
                radar_system.apg68Radar.setRootMode(0);
            } elsif (controlName == "OSB2") {
                radar_system.apg68Radar.setRootMode(1,radar_system.apg68Radar.getPriorityTarget());
            } elsif (controlName == "OSB3") {
                radar_system.apg68Radar.setRootMode(2);
            } elsif (controlName == "OSB4") {
                radar_system.apg68Radar.setRootMode(3);
            } elsif (controlName == "OSB5") {
                radar_system.apg68Radar.setRootMode(4);
            }
		},
		update: func (noti = nil) {
			
		},
		exit: func {
			printDebug("Exit ",me.name~" on ",me.device.name);
		},
		links: {
			"OSB1":  "PageFCR",
			"OSB2":  "PageFCR",
			"OSB3":  "PageFCR",
			"OSB4":  "PageFCR",
			"OSB5":  "PageFCR",
			"OSB11": "PageMenu",
		},
		layers: ["BULLSEYE"],
	},

#  ██████  ████████ ███████ 
#  ██   ██    ██    ██      
#  ██   ██    ██    █████   
#  ██   ██    ██    ██      
#  ██████     ██    ███████ 
#                           
#                           

	PageDTE: {
		name: "PageDTE",
		isNew: 1,
		supportSOI: 0,		
		needGroup: 1,
		new: func {
			me.instance = {parents:[DisplaySystem.PageDTE]};
			me.instance.group = nil;
			return me.instance;
		},
		setup: func {
			printDebug(me.name," on ",me.device.name," is being setup");
			me.pageText = me.group.createChild("text")
				.set("z-index", 10)
				.setColor(colorText1)
				.setAlignment("center-center")
				.setTranslation(displayWidthHalf, displayHeightHalf)
				.setFontSize(me.device.fontSize)
				.setText("");
			var defaultDirInFileSelector = getprop("/sim/fg-home") ~ "/Export";
	        var load_stpts = func(path) {
	                        steerpoints.loadSTPTs(path.getValue());
	                    };
	        var save_stpts = func(path) {
	                        steerpoints.saveSTPTs(path.getValue());
	                    };
	        me.save_selector_dtc = gui.FileSelector.new(
	                      callback: save_stpts, title: "Save data cartridge", button: "Save",
	                      dir: defaultDirInFileSelector, dotfiles: 1, file: "mission-data.f16dtc", pattern: ["*.f16dtc"]);            
	        me.file_selector_dtc = gui.FileSelector.new(
	                      callback: load_stpts, title: "Load data cartridge", button: "Load",
	                      dir: defaultDirInFileSelector, dotfiles: 1, pattern: ["*.f16dtc"]);
		},
		enter: func {
			printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = 0;
			}
			me.device.resetControls();
			me.device.controls["OSB2"].setControlText("LOAD");
			me.device.controls["OSB4"].setControlText("SAVE");
			me.device.controls["OSB8"].setControlText("DTE", 0);
			me.device.controls["OSB16"].setControlText("SWAP");
		},
		controlAction: func (controlName) {
			printDebug(me.name,": ",controlName," activated on ",me.device.name);
			if (controlName == "OSB2") {#LOAD
                me.file_selector_dtc.open();
            } elsif (controlName == "OSB4") {#SAVE
                me.save_selector_dtc.open();
            } elsif (controlName == "OSB16") {
				me.device.swap();
            }
		},
		update: func (noti = nil) {
			if (steerpoints.dtcLast != nil) {
				me.pageText.setText("DTC ID\n"~steerpoints.dtcLast);
			} else {
				me.pageText.setText("");
			}
		},
		exit: func {
			printDebug("Exit ",me.name~" on ",me.device.name);
		},
		links: {
			"OSB8":  "PageMenu",
		},
		layers: ["BULLSEYE"],
	},

#  ███████  ██████ ██████       ██████ ███    ██ ████████ ██      
#  ██      ██      ██   ██     ██      ████   ██    ██    ██      
#  █████   ██      ██████      ██      ██ ██  ██    ██    ██      
#  ██      ██      ██   ██     ██      ██  ██ ██    ██    ██      
#  ██       ██████ ██   ██      ██████ ██   ████    ██    ███████ 
#                                                                 
#                                                                 

	PageFCRCNTL: {
		name: "PageFCRCNTL",
		isNew: 1,
		supportSOI: 1,
		soiPrio: 9,
		needGroup: 0,
		new: func {
			me.instance = {parents:[DisplaySystem.PageFCRCNTL]};
			me.instance.group = nil;
			return me.instance;
		},
		setup: func {
			printDebug(me.name," on ",me.device.name," is being setup");
			fcrBand = 0;
        	fcrChan = 2;
        	me.mtr = 112;
		},
		enter: func {
			printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = 0;
			}
			me.device.resetControls();
			me.device.controls["OSB15"].setControlText("CNTL", 0);
			me.device.controls["OSB16"].setControlText("SWAP");
		},
		controlAction: func (controlName) {
			printDebug(me.name,": ",controlName," activated on ",me.device.name);
			if (controlName == "OSB3") {
                radar_system.apg68Radar.targetHistory += 1;
                if (radar_system.apg68Radar.targetHistory > 4) {
                    radar_system.apg68Radar.targetHistory = 1;
                }
            } elsif (controlName == "OSB5") {
                radar_system.GMT_hi_lo = !radar_system.GMT_hi_lo;
            } elsif (controlName == "OSB6") {
                fcrChan += 1;
                if (fcrChan > 4) fcrChan = 1;
            } elsif (controlName == "OSB8") {
                fcrBand = !fcrBand;
            } elsif (controlName == "OSB16") {
                me.device.swap();
            }
		},
		update: func (noti = nil) {
			# GM(T) options from page 164/176 of MLU t1
            me.device.controls["OSB1"].setControlText("MTR\n"~me.mtr);
            me.device.controls["OSB2"].setControlText("ALT BLK\nOFF");
			me.device.controls["OSB3"].setControlText("TGT HIS\n"~radar_system.apg68Radar.targetHistory);
            me.device.controls["OSB4"].setControlText("LVL\n1");
            me.device.controls["OSB5"].setControlText("GMT SPD CUTOFF\n"~(radar_system.GMT_hi_lo?"Hi":"Lo"));
            me.device.controls["OSB6"].setControlText("CHAN\n"~fcrChan);
			me.device.controls["OSB7"].setControlText("MK INT\n2");
			if (fcrBand == 0) {
                me.device.controls["OSB8"].setControlText("BAND\nNARO");
            } else {
                me.device.controls["OSB8"].setControlText("BAND\nWIDE");
            }
			me.device.controls["OSB9"].setControlText("BCN DLY\n1.2");
			me.device.controls["OSB10"].setControlText("DCPL");
		},
		exit: func {
			printDebug("Exit ",me.name~" on ",me.device.name);
		},
		links: {
			"OSB15":  "PageFCR",
		},
		layers: ["BULLSEYE"],
	},

#  ██   ██ ███████ ██████       ██████ ███    ██ ████████ ██      
#  ██   ██ ██      ██   ██     ██      ████   ██    ██    ██      
#  ███████ ███████ ██   ██     ██      ██ ██  ██    ██    ██      
#  ██   ██      ██ ██   ██     ██      ██  ██ ██    ██    ██      
#  ██   ██ ███████ ██████       ██████ ██   ████    ██    ███████ 
#                                                                 
#                                                                 

	PageHSDCNTL: {
		name: "PageHSDCNTL",
		isNew: 1,
		supportSOI: CursorHSD,
		soiPrio: 7,
		needGroup: 0,
		new: func {
			me.instance = {parents:[DisplaySystem.PageHSDCNTL]};
			me.instance.group = nil;
			return me.instance;
		},
		setup: func {
			printDebug(me.name," on ",me.device.name," is being setup");
		},
		enter: func {
			printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = 0;
			}
			me.device.resetControls();
			me.device.controls["OSB15"].setControlText("CNTL",0);
		},
		controlAction: func (controlName) {
			printDebug(me.name,": ",controlName," activated on ",me.device.name);
			if (controlName == "OSB1") {
                hsdShowNAV1 = !hsdShowNAV1;
            } elsif (controlName == "OSB4") {
                hsdShowDLINK = !hsdShowDLINK;
            } elsif (controlName == "OSB6") {
                if (steerpoints.lines[0] != nil) steerpoints.linesShow[0] = !steerpoints.linesShow[0];
            } elsif (controlName == "OSB7") {
                if (steerpoints.lines[1] != nil) steerpoints.linesShow[1] = !steerpoints.linesShow[1];
            } elsif (controlName == "OSB8") {
                if (steerpoints.lines[2] != nil) steerpoints.linesShow[2] = !steerpoints.linesShow[2];
            } elsif (controlName == "OSB9") {
                if (steerpoints.lines[3] != nil) steerpoints.linesShow[3] = !steerpoints.linesShow[3];
            } elsif (controlName == "OSB10") {
            	hsdShowRINGS = !hsdShowRINGS;
            } elsif (controlName == "OSB11") {
            	hsdShowFCR = !hsdShowFCR;
            } elsif (controlName == "OSB12") {
				hsdShowPRE = !hsdShowPRE;
			}
		},
		update: func (noti = nil) {
			me.device.controls["OSB11"].setControlText("FCR",1,hsdShowFCR);
			me.device.controls["OSB12"].setControlText("PRE",1,hsdShowPRE);
			me.device.controls["OSB1"].setControlText("NAV1",1,hsdShowNAV1);
			me.device.controls["OSB4"].setControlText("DLNK",1,hsdShowDLINK);
			me.device.controls["OSB6"].setControlText((steerpoints.lines[0] != nil)?"LINE1":"",1,steerpoints.linesShow[0]);
            me.device.controls["OSB7"].setControlText((steerpoints.lines[1] != nil)?"LINE2":"",1,steerpoints.linesShow[1]);
            me.device.controls["OSB8"].setControlText((steerpoints.lines[2] != nil)?"LINE3":"",1,steerpoints.linesShow[2]);
            me.device.controls["OSB9"].setControlText((steerpoints.lines[3] != nil)?"LINE4":"",1,steerpoints.linesShow[3]);
            me.device.controls["OSB10"].setControlText("RINGS",1,hsdShowRINGS);
		},
		exit: func {
			printDebug("Exit ",me.name~" on ",me.device.name);
		},
		links: {
			"OSB15":  "PageHSD",
		},
		layers: ["BULLSEYE"],
	},

#  ██   ██ ███████ ██████  
#  ██   ██ ██      ██   ██ 
#  ███████ ███████ ██   ██ 
#  ██   ██      ██ ██   ██ 
#  ██   ██ ███████ ██████  
#                          
#                          

	PageHSD: {
		name: "PageHSD",
		isNew: 1,
		supportSOI: CursorHSD,
		soiPrio: 8,
		needGroup: 1,
		new: func {
			me.instance = {parents:[DisplaySystem.PageHSD]};
			me.instance.group = nil;
			return me.instance;
		},
		setup: func {
			printDebug(me.name," on ",me.device.name," is being setup");
			me.up = 0;
			me.rangeText = "";
			me.showRangeDown = 0;
			me.showRangeUp = 0;
			me.slew_c_last = 0;
			me.index = me.device.name == "RightMFD";
			me.concentricCenter = [displayWidthHalf,0.5*displayHeight];
			me.setupHSD();
		},
		setupHSD: func {

	        me.buttonView = me.group.createChild("group")
	                .setTranslation(displayWidth*0.5,displayHeight);
	        me.concentricGrp = me.group.createChild("group")
	                .setTranslation(displayWidth*0.5,displayHeight*0.75);#552,displayHeight , 0.795 is for UV map

	        me.cone = me.concentricGrp.createChild("group")
	            .set("z-index",5);#radar cone

	        me.outerRadius  = displayHeight *3/4;
	        me.mediumRadius = me.outerRadius*2/3;
	        me.innerRadius  = me.outerRadius*1/3;
	        #var innerTick    = 0.85*innerRadius*math.cos(45*D2R);
	        #var outerTick    = 1.15*innerRadius*math.cos(45*D2R);


	        me.conc = me.concentricGrp.createChild("path")
	            .moveTo(me.innerRadius,0)
	            .arcSmallCW(me.innerRadius,me.innerRadius, 0, -me.innerRadius*2, 0)
	            .arcSmallCW(me.innerRadius,me.innerRadius, 0,  me.innerRadius*2, 0)
	            .moveTo(me.mediumRadius,0)
	            .arcSmallCW(me.mediumRadius,me.mediumRadius, 0, -me.mediumRadius*2, 0)
	            .arcSmallCW(me.mediumRadius,me.mediumRadius, 0,  me.mediumRadius*2, 0)
	            .moveTo(me.outerRadius,0)
	            .arcSmallCW(me.outerRadius,me.outerRadius, 0, -me.outerRadius*2, 0)
	            .arcSmallCW(me.outerRadius,me.outerRadius, 0,  me.outerRadius*2, 0)
	            .moveTo(0,-me.innerRadius)#north
	            .vert(-symbolSize.hsd.compasFlag)
	            .lineTo(symbolSize.hsd.compasFlag/3,-me.innerRadius-symbolSize.hsd.compasFlag+symbolSize.hsd.compasFlag/6)
	            .lineTo(0,-me.innerRadius-symbolSize.hsd.compasFlag+symbolSize.hsd.compasFlag/3)
	            .moveTo(0,me.innerRadius-symbolSize.hsd.compasFlag)#south
	            .vert(symbolSize.hsd.compasFlag*2)
	            .moveTo(-me.innerRadius,0)#west
	            .horiz(-symbolSize.hsd.compasFlag)
	            .moveTo(me.innerRadius,0)#east
	            .horiz(symbolSize.hsd.compasFlag)
	            .setStrokeLineWidth(lineWidth.hsd.rangeRing)
	            .set("z-index",2)
	            .setColor(colorLine5);


	        me.cursorHSD = me.buttonView.createChild("path")
	                    .moveTo(0, 6)
	                    .vert(symbolSize.hsd.cursor)
	                    .moveTo(0, -symbolSize.hsd.cursor*0.4)
	                    .vert(-symbolSize.hsd.cursor)
	                    .moveTo(symbolSize.hsd.cursor*0.4,0)
	                    .horiz(symbolSize.hsd.cursor)
	                    .moveTo(-symbolSize.hsd.cursor*0.4,0)
	                    .horiz(-symbolSize.hsd.cursor)
	                    .setStrokeLineWidth(lineWidth.hsd.cursor)
	                    .setColor(colorLine3);
	        me.cursorGhost = me.concentricGrp.createChild("group").set("z-index",1000);
	        me.cursorAirGhost = me.cursorGhost.createChild("path")
	                    .moveTo(-symbolSize.hsd.cursorGhostAir*0.45,-symbolSize.hsd.cursorGhostAir/2)
	                    .vert(symbolSize.hsd.cursorGhostAir)
	                    .moveTo(symbolSize.hsd.cursorGhostAir*0.45,-symbolSize.hsd.cursorGhostAir/2)
	                    .vert(symbolSize.hsd.cursorGhostAir)
	                    .setStrokeLineWidth(lineWidth.hsd.cursorGhost)
	                    .setColor(colorLine3);
	        me.cursorGmGhost = me.cursorGhost.createChild("path")
	                    .moveTo(0, symbolSize.hsd.cursorGhostGnd*0.5)
	                    .vert(symbolSize.hsd.cursorGhostGnd)
	                    .moveTo(0, -symbolSize.hsd.cursorGhostGnd*0.5)
	                    .vert(-symbolSize.hsd.cursorGhostGnd)
	                    .moveTo(symbolSize.hsd.cursorGhostGnd*0.5,0)
	                    .horiz(symbolSize.hsd.cursorGhostGnd)
	                    .moveTo(-symbolSize.hsd.cursorGhostGnd*0.5,0)
	                    .horiz(-symbolSize.hsd.cursorGhostGnd)
	                    .setStrokeLineWidth(lineWidth.hsd.cursorGhost)
	                    .setColor(colorLine3);

	        me.maxB = 16;
	        me.blepTriangle = setsize([],me.maxB);
	        me.blepTriangleVel = setsize([],me.maxB);
	        me.blepTriangleText = setsize([],me.maxB);
	        me.blepTriangleVelLine = setsize([],me.maxB);
	        me.blepTrianglePaths = setsize([],me.maxB);
	        me.lnkTA= setsize([],me.maxB);
	        me.lnkT = setsize([],me.maxB);
	        me.lnk  = setsize([],me.maxB);
	        for (var i = 0;i<me.maxB;i+=1) {
	                me.blepTriangle[i] = me.concentricGrp.createChild("group")
	                                .set("z-index",11);
	                me.blepTriangleVel[i] = me.blepTriangle[i].createChild("group");
	                me.blepTriangleText[i] = me.blepTriangle[i].createChild("text")
	                                .setAlignment("center-top")
	                                .setFontSize(me.device.fontSize, 1.0)
	                                .setTranslation(0,symbolSize.hsd.contact*20)
	                                .setColor(1, 1, 1);
	                me.blepTriangleVelLine[i] = me.blepTriangleVel[i].createChild("path")
	                                .lineTo(0,symbolSize.hsd.contact*-10)
	                                .setTranslation(0,symbolSize.hsd.contact*-16)
	                                .setStrokeLineWidth(lineWidth.hsd.targetTrack)
	                                .setColor(colorCircle2);
	                me.blepTrianglePaths[i] = me.blepTriangle[i].createChild("path")
	                                .moveTo(symbolSize.hsd.contact*-14,symbolSize.hsd.contact*8)
	                                .horiz(symbolSize.hsd.contact*28)
	                                .lineTo(0,symbolSize.hsd.contact*-16)
	                                .lineTo(symbolSize.hsd.contact*-14,symbolSize.hsd.contact*8)
	                                .setColor(colorCircle2)
	                                .set("z-index",10)
	                                .setStrokeLineWidth(lineWidth.hsd.targetTrack);
	                me.lnk[i] = me.concentricGrp.createChild("path")
	                                .moveTo(symbolSize.hsd.contact*-10,symbolSize.hsd.contact*-10)
	                                .vert(symbolSize.hsd.contact*20)
	                                .horiz(symbolSize.hsd.contact*20)
	                                .vert(symbolSize.hsd.contact*-20)
	                                .horiz(symbolSize.hsd.contact*-20)
	                                .moveTo(0,symbolSize.hsd.contact*-10)
	                                .vert(symbolSize.hsd.contact*-10)
	                                .setColor(colorDot1)
	                                .hide()
	                                .set("z-index",11)
	                                .setStrokeLineWidth(lineWidth.hsd.targetDL);
	                me.lnkT[i] = me.concentricGrp.createChild("text")
	                                .setAlignment("center-bottom")
	                                .setColor(colorDot1)
	                                .set("z-index",1)
	                                .setFontSize(me.device.fontSize, 1.0);
	                me.lnkTA[i] = me.concentricGrp.createChild("text")
	                                .setAlignment("center-top")
	                                .setColor(colorDot1)
	                                .set("z-index",1)
	                                .setFontSize(me.device.fontSize, 1.0);
	        }
	        me.selection = me.concentricGrp.createChild("path")
	                .moveTo(symbolSize.hsd.contact*-16, 0)
	                .arcSmallCW(symbolSize.hsd.contact*16, symbolSize.hsd.contact*16, 0, symbolSize.hsd.contact*16*2, 0)
	                .arcSmallCW(symbolSize.hsd.contact*16, symbolSize.hsd.contact*16, 0, symbolSize.hsd.contact*-16*2, 0)
	                .setColor(colorDot1)
	                .set("z-index",12)
	                .setStrokeLineWidth(lineWidth.hsd.designation);

	        me.myself = me.concentricGrp.createChild("path")#own ship
	           .moveTo(0, 0)
	           .vert(symbolSize.hsd.ownship*30)
	           .moveTo(symbolSize.hsd.ownship*-10, symbolSize.hsd.ownship*10)
	           .horiz(symbolSize.hsd.ownship*20)
	           .moveTo(symbolSize.hsd.ownship*-5, symbolSize.hsd.ownship*20)
	           .horiz(symbolSize.hsd.ownship*10)
	           .setColor(colorLine1)
	           .setStrokeLineWidth(lineWidth.hsd.ownship);

	        me.threat_c = [];
	        me.threat_t = [];
	        for (var g = 0; g < steerpoints.number_of_threat_circles; g+=1) {
	            append(me.threat_c, me.concentricGrp.createChild("path")
	                .moveTo(-50,0)
	                .arcSmallCW(50,50, 0,  50*2, 0)
	                .arcSmallCW(50,50, 0, -50*2, 0)
	                .setStrokeLineWidth(lineWidth.hsd.threatRing)
	                .set("z-index",2)
	                .hide()
	                .setColor(colorCircle1));
	            append(me.threat_t, me.concentricGrp.createChild("text")
	                .setAlignment("center-center")
	                .setColor(colorCircle1)
	                .set("z-index",2)
	                .setFontSize(17, 1.0));
	        }

	        me.mark = setsize([],10);
	        for (var no = 0; no < 10; no += 1) {
	            me.mark[no] = me.concentricGrp.createChild("text")
	                    .setAlignment("center-center")
	                    .setColor(no<5?colorText2:colorCircle2)
	                    .setText("X")
	                    .set("z-index",2)
	                    .setFontSize(symbolSize.hsd.markpoint, 1.0);
	        }

	        me.bullseye = me.concentricGrp.createChild("path")
	            .moveTo(symbolSize.hsd.bullseye*-25,0)
	            .arcSmallCW(symbolSize.hsd.bullseye*25,symbolSize.hsd.bullseye*25, 0,  symbolSize.hsd.bullseye*25*2, 0)
	            .arcSmallCW(symbolSize.hsd.bullseye*25,symbolSize.hsd.bullseye*25, 0, symbolSize.hsd.bullseye*-25*2, 0)
	            .moveTo(symbolSize.hsd.bullseye*-15,0)
	            .arcSmallCW(symbolSize.hsd.bullseye*15,symbolSize.hsd.bullseye*15, 0,  symbolSize.hsd.bullseye*15*2, 0)
	            .arcSmallCW(symbolSize.hsd.bullseye*15,symbolSize.hsd.bullseye*15, 0, symbolSize.hsd.bullseye*-15*2, 0)
	            .moveTo(symbolSize.hsd.bullseye*-5,0)
	            .arcSmallCW(symbolSize.hsd.bullseye*5,symbolSize.hsd.bullseye*5, 0,  symbolSize.hsd.bullseye*5*2, 0)
	            .arcSmallCW(symbolSize.hsd.bullseye*5,symbolSize.hsd.bullseye*5, 0, symbolSize.hsd.bullseye*-5*2, 0)
	            .setStrokeLineWidth(lineWidth.hsd.bullseye)
	            .setColor(colorBullseye);
	        me.cursorLoc = me.buttonView.createChild("text")
	                .setAlignment("left-bottom")
	                .setColor(colorBetxt)
	                .setTranslation(-displayWidthHalf*0.95, -displayHeight*0.15)
	                .setText("12")
	                .set("z-index",1)
	                .setFontSize(18, 1.0);
	    },

	    # Static members
	    HSD_centered: 0,
	    HSD_coupled: 0,
	    HSD_range_cen: 40,
	    HSD_range_dep: 32,

	    set_HSD_centered: func(centered) DisplaySystem.PageHSD.HSD_centered = centered,
	    set_HSD_coupled: func(coupled) DisplaySystem.PageHSD.HSD_coupled = coupled,
	    set_HSD_range_cen: func(range_cen) DisplaySystem.PageHSD.HSD_range_cen = range_cen,
	    set_HSD_range_dep: func(range_dep) DisplaySystem.PageHSD.HSD_range_dep = range_dep,

	    get_HSD_centered: func DisplaySystem.PageHSD.HSD_centered,
	    get_HSD_coupled: func DisplaySystem.PageHSD.HSD_coupled,
	    get_HSD_range_cen: func DisplaySystem.PageHSD.HSD_range_cen,
	    get_HSD_range_dep: func DisplaySystem.PageHSD.HSD_range_dep,
		enter: func {
			printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = 0;
			}
			me.device.resetControls();
			me.device.controls["OSB11"].setControlText("FCR");
			me.device.controls["OSB12"].setControlText(me.get_HSD_centered()?"CEN":"DEP");
            me.device.controls["OSB13"].setControlText(me.get_HSD_coupled()?"CPL":"DCPL");
            me.device.controls["OSB15"].setControlText("CNTL");
			me.device.controls["OSB16"].setControlText("SWAP");
			me.device.controls["OSB17"].setControlText("HSD", 0);
			me.device.controls["OSB18"].setControlText("SMS");
			me.device.controls["OSB19"].setControlText("WPN");
			me.device.controls["OSB20"].setControlText("TGP");
			me.device.system.fetchLayer("OSB1TO2ARROWS").init(me, me.getOSB1TO2ARROWS);
		},
		getOSB1TO2ARROWS: func {
			return [1, me.rangeText, me.showRangeDown, me.showRangeUp];
		},
		controlAction: func (controlName) {
			printDebug(me.name,": ",controlName," activated on ",me.device.name);
			if (controlName == "OSB1") {
                if (me.get_HSD_coupled()) return;
                if (me.get_HSD_centered()) {
                    if (me.get_HSD_range_cen() == 5)
                        me.set_HSD_range_cen(10)
                    elsif (me.get_HSD_range_cen() == 10)
                        me.set_HSD_range_cen(20)
                    elsif (me.get_HSD_range_cen() == 20)
                        me.set_HSD_range_cen(40)
                    elsif (me.get_HSD_range_cen() == 40)
                        me.set_HSD_range_cen(80)
                    elsif (me.get_HSD_range_cen() == 80)
                        me.set_HSD_range_cen(160)
                    else
                        me.set_HSD_range_cen(160);
                } elsif (!me.get_HSD_centered()) {
                    if (me.get_HSD_range_dep() == 8)
                        me.set_HSD_range_dep(16)
                    elsif (me.get_HSD_range_dep() == 16)
                        me.set_HSD_range_dep(32)
                    elsif (me.get_HSD_range_dep() == 32)
                        me.set_HSD_range_dep(64)
                    elsif (me.get_HSD_range_dep() == 64)
                        me.set_HSD_range_dep(128)
                    elsif (me.get_HSD_range_dep() == 128)
                        me.set_HSD_range_dep(256)
                    else
                        me.set_HSD_range_dep(256);
                }
            } elsif (controlName == "OSB2") {
                if (me.get_HSD_coupled()) return;
                if (me.get_HSD_centered()) {
                    if (me.get_HSD_range_cen() == 160)
                        me.set_HSD_range_cen(80)
                    elsif (me.get_HSD_range_cen() == 80)
                        me.set_HSD_range_cen(40)
                    elsif (me.get_HSD_range_cen() == 40)
                        me.set_HSD_range_cen(20)
                    elsif (me.get_HSD_range_cen() == 20)
                        me.set_HSD_range_cen(10)
                    elsif (me.get_HSD_range_cen() == 10)
                        me.set_HSD_range_cen(5)
                    else
                        me.set_HSD_range_cen(5);
                } elsif (!me.get_HSD_centered()) {
                    if (me.get_HSD_range_dep() == 256)
                        me.set_HSD_range_dep(128)
                    elsif (me.get_HSD_range_dep() == 128)
                        me.set_HSD_range_dep(64)
                    elsif (me.get_HSD_range_dep() == 64)
                        me.set_HSD_range_dep(32)
                    elsif (me.get_HSD_range_dep() == 32)
                        me.set_HSD_range_dep(16)
                    elsif (me.get_HSD_range_dep() == 16)
                        me.set_HSD_range_dep(8)
                    else
                        me.set_HSD_range_dep(8);
                }
            } elsif (controlName == "OSB10") {
                cursor_pos_hsd = [0, me.concentricCenter[1]-displayHeight];
            } elsif (controlName == "OSB12") {
                me.set_HSD_centered(!me.get_HSD_centered());
            } elsif (controlName == "OSB13") {
                me.set_HSD_coupled(!me.get_HSD_coupled());
            } elsif (controlName == "OSB16") {
            	me.device.swap();
            } elsif (controlName == "OSB20") {
                switchTGP();
            }
		},
		updateCursor: func (noti) {
            if (me.IMSOI) {
                # Get controls from pilots cursor hat:
	            me.slew_x = getprop("controls/displays/target-management-switch-x[" ~ me.index ~ "]");
	            me.slew_y = -getprop("controls/displays/target-management-switch-y[" ~ me.index ~ "]");

            	if (noti.getproper("viewName") != "TGP") {
	                f16.resetSlew();
	            }
            	# Move cursor and record clicks
                if ((me.slew_x != 0 or me.slew_y != 0 or slew_c != 0) and (cursor_lock == -1 or cursor_lock == me.index) and noti.getproper("viewName") != "TGP") {
                    cursor_pos_hsd[0] += me.slew_x*175;
                    cursor_pos_hsd[1] -= me.slew_y*175;
                    cursor_pos_hsd[0] = math.clamp(cursor_pos_hsd[0], -displayWidthHalf, displayWidthHalf);

                    if (cursor_pos_hsd[1] <= -displayHeight) {
                    	me.resetC = 0;
                    	if (me.get_HSD_centered()) {
                    		me.rng = me.get_HSD_range_cen()*2;
                    		if (me.rng > 160) me.rng = 160;
                    		else me.resetC = 1;
                    		me.set_HSD_range_cen(me.rng);
                    	} else {
                    		me.rng = me.get_HSD_range_dep()*2;
                    		if (me.rng > 256) me.rng = 256;
                    		else me.resetC = 1;
                    		me.set_HSD_range_dep(me.rng);
                    	}
                    	me.set_HSD_coupled(0);
                    	if (me.resetC) cursor_pos_hsd[1] = me.concentricCenter[1]*0.5-displayHeight;
                    }
                    if (cursor_pos_hsd[1] >= 0) {
                    	me.resetC = 0;
                    	if (me.get_HSD_centered()) {
                    		me.rng = me.get_HSD_range_cen()*0.5;
                    		if (me.rng < 5) me.rng = 5;
                    		else me.resetC = 1;
                    		me.set_HSD_range_cen(me.rng);
                    	} else {
                    		me.rng = me.get_HSD_range_dep()*0.5;
                    		if (me.rng < 8) me.rng = 8;
                    		else me.resetC = 1;
                    		me.set_HSD_range_dep(me.rng);
                    	}
                    	me.set_HSD_coupled(0);
                    	if (me.resetC) cursor_pos_hsd[1] = me.concentricCenter[1]+0.5*(displayHeight-me.concentricCenter[1])-displayHeight;
                    }
                    cursor_pos_hsd[1] = math.clamp(cursor_pos_hsd[1], -displayHeight, 0);
                    cursor_click = (slew_c and !me.slew_c_last)?me.index:-1;
                    cursor_lock = me.index;
                } elsif (cursor_lock == me.index or (me.slew_x == 0 or me.slew_y == 0 or slew_c == 0)) {
                    cursor_lock = -1;
                }

                me.slew_c_last = slew_c;
                slew_c = 0;
                me.cursorHSD.setTranslation(cursor_pos_hsd);
                me.hsdCursorFromOwnship = [cursor_pos_hsd[0], cursor_pos_hsd[1]+(displayHeight-me.concentricCenter[1])];
                me.pixelsFromOwnshipToTop = me.concentricCenter[1];
                me.pixelsCursor = math.sqrt(me.hsdCursorFromOwnship[0]*me.hsdCursorFromOwnship[0]+me.hsdCursorFromOwnship[1]*me.hsdCursorFromOwnship[1]);
                if (me.get_HSD_centered()) {
	                me.range = me.get_HSD_range_cen();
	            } else {
	                me.range = me.get_HSD_range_dep();
	            }

                me.cursorDev   = -math.atan2(-me.hsdCursorFromOwnship[0], -me.hsdCursorFromOwnship[1])*R2D;
                me.cursorDist  = NM2M*(me.range*me.pixelsCursor/me.pixelsFromOwnshipToTop);
                #printf("HSD Cursor  dist %.2f nm  dev %.1f deg",me.cursorDist*M2NM,me.cursorDev);
                #printf("  %d %.3f    %d   %d,%d",me.range,me.pixelsCursor,me.pixelsFromOwnshipToTop,me.hsdCursorFromOwnship[0],me.hsdCursorFromOwnship[1]);
                me.device.controls["OSB10"].setControlText("C\nZ");
            } else {
            	me.device.controls["OSB10"].setControlText("");
            }
           	me.hsdCursorclick = me.IMSOI and cursor_click == me.index;
            me.cursorHSD.setVisible(me.IMSOI);

            # Cursor clicking will select points in this priority order:
            #
            # Bullseye
            # Steerpoints
            # Linepoints
            # Markpoints
            # Pre-planned threats
		},
		update: func (noti = nil) {
			me.conc.setRotation(-radar_system.self.getHeading()*D2R);
            if (noti.FrameCount != 1 and noti.FrameCount != 3)
                return;

            me.IMSOI = me.device.soi == 1;
            if (!me.IMSOI and (me.device.swapWith.soi != 1 or me.device.swapWith.system.currPage.name != me.name)) cursor_pos_hsd = [0, me.concentricCenter[1]-displayHeight];# what a hack :(
            me.updateCursor(noti);
            me.rdrrng = radar_system.apg68Radar.getRange();
            me.rdrprio = radar_system.apg68Radar.getPriorityTarget();
            me.selfCoord = geo.aircraft_position();
            me.selfHeading = radar_system.self.getHeading();
            me.device.controls["OSB12"].setControlText(me.get_HSD_centered()?"CEN":"DEP");
            me.device.controls["OSB13"].setControlText(me.get_HSD_coupled()?"CPL":"DCPL");
            if (me.get_HSD_coupled()) {

                if (me.rdrrng == 5) {
                    me.set_HSD_range_cen(5);
                    me.set_HSD_range_dep(8);
                } elsif (me.rdrrng == 10) {
                    me.set_HSD_range_cen(10);
                    me.set_HSD_range_dep(16);
                } elsif (me.rdrrng == 20) {
                    me.set_HSD_range_cen(20);
                    me.set_HSD_range_dep(32);
                } elsif (me.rdrrng == 40) {
                    me.set_HSD_range_cen(40);
                    me.set_HSD_range_dep(64);
                } elsif (me.rdrrng == 80) {
                    me.set_HSD_range_cen(80);
                    me.set_HSD_range_dep(128);
                } elsif (me.rdrrng == 160) {
                    me.set_HSD_range_cen(160);
                    me.set_HSD_range_dep(256);
                }
                me.showRangeUp = 0;
                me.showRangeDown = 0;
            } else {
                if (me.get_HSD_centered() and me.get_HSD_range_cen() == 160) {
                    me.showRangeUp = 0;
                } elsif (!me.get_HSD_centered() and me.get_HSD_range_dep() == 256) {
                    me.showRangeUp = 0;
                } else {
                    me.showRangeUp = 1;
                }

                if (me.get_HSD_centered() and me.get_HSD_range_cen() == 5) {
                    me.showRangeDown = 0;
                } elsif (!me.get_HSD_centered() and me.get_HSD_range_dep() == 8) {
                    me.showRangeDown = 0;
                } else {
                    me.showRangeDown = 1;
                }
            }
            if (me.get_HSD_centered()) {
                me.concentricGrp.setTranslation(displayWidthHalf,0.5*displayHeight);
                me.rangeText = ""~me.get_HSD_range_cen();
                me.concentricCenter = [displayWidthHalf,0.5*displayHeight];
            } else {
                me.concentricGrp.setTranslation(displayWidthHalf,0.75*displayHeight);
                me.rangeText = ""~me.get_HSD_range_dep();
                me.concentricCenter = [displayWidthHalf,0.75*displayHeight];
            }

            me.conc.setVisible(hsdShowRINGS);

            me.bullPt = steerpoints.getNumber(steerpoints.index_of_bullseye);
            me.bullOn = me.bullPt != nil;
            if (me.bullOn) {
                me.bullLat = me.bullPt.lat;
                me.bullLon = me.bullPt.lon;
                me.bullCoord = geo.Coord.new().set_latlon(me.bullLat,me.bullLon);
                me.bullDirToMe = me.bullCoord.course_to(me.selfCoord);
                me.meToBull = ((me.bullDirToMe+180)-noti.getproper("heading"))*D2R;
                me.bullDistToMe = me.bullCoord.distance_to(me.selfCoord)*M2NM;
                if (me.get_HSD_centered()) {
                    me.bullRangePixels = me.mediumRadius*(me.bullDistToMe/me.get_HSD_range_cen());
                } else {
                    me.bullRangePixels = me.outerRadius*(me.bullDistToMe/me.get_HSD_range_dep());
                }
                me.legX = me.bullRangePixels*math.sin(me.meToBull);
                me.legY = -me.bullRangePixels*math.cos(me.meToBull);
                me.bullseye.setTranslation(me.legX,me.legY);

                if (me.IMSOI) {
                	me.cursorCoord = geo.aircraft_position();
	                if (me.cursorDist > 0) {
	                	me.cursorCoord.apply_course_distance(noti.getproper("heading")+me.cursorDev, me.cursorDist);	                
	                }
	                me.cursorBullDist = me.cursorCoord.distance_to(me.bullCoord);
	                me.cursorBullCrs  = me.bullCoord.course_to(me.cursorCoord);
	                me.cursorLoc.setText(sprintf("%03d %03d",me.cursorBullCrs, me.cursorBullDist*M2NM));

	                if (me.hsdCursorclick) {
                    	me.distFromCursor = math.sqrt(math.pow(me.hsdCursorFromOwnship[0]-me.legX,2)+math.pow(me.hsdCursorFromOwnship[1]-me.legY,2));
                    	if (me.distFromCursor < 12) {# bullseye
                    		me.hsdCursorclick = 0;
                    		steerpoints.setCurrentNumber(steerpoints.index_of_bullseye);
                    	}
                    }
	            }
            }
            me.cursorLoc.setVisible(me.IMSOI and me.bullOn);
            me.bullseye.setVisible(me.bullOn);

            if (me.get_HSD_centered()) {
                me.rdrRangePixels = me.mediumRadius*(me.rdrrng/me.get_HSD_range_cen());
            } else {
                me.rdrRangePixels = me.outerRadius*(me.rdrrng/me.get_HSD_range_dep());
            }
            me.az = radar_system.apg68Radar.currentMode.az;
            if (noti.FrameCount == 1) {
                me.cone.removeAllChildren();
                if (radar_system.apg68Radar.enabled and hsdShowFCR) {
                    if (radar_system.apg68Radar.showAZinHSD()) {
                        me.radarX1 =  me.rdrRangePixels*math.cos((90-me.az-radar_system.apg68Radar.getDeviation())*D2R);
                        me.radarY1 = -me.rdrRangePixels*math.sin((90-me.az-radar_system.apg68Radar.getDeviation())*D2R);
                        me.radarX2 =  me.rdrRangePixels*math.cos((90+me.az-radar_system.apg68Radar.getDeviation())*D2R);
                        me.radarY2 = -me.rdrRangePixels*math.sin((90+me.az-radar_system.apg68Radar.getDeviation())*D2R);
                        me.radarcone = me.cone.createChild("path")
                                    .moveTo(0,0)
                                    .lineTo(me.radarX1,me.radarY1)#right
                                    .moveTo(0,0)
                                    .lineTo(me.radarX2,me.radarY2)#left
                                    .arcSmallCW(me.rdrRangePixels,me.rdrRangePixels, 0, me.radarX1-me.radarX2, me.radarY1-me.radarY2)
                                    .setStrokeLineWidth(lineWidth.hsd.radarCone)
                                    .set("z-index",5)
                                    .setColor(colorLine1)
                                    .update();
                    }
                }
                if (steerpoints.isRouteActive() and hsdShowNAV1) {
                    me.plan = flightplan();
                    me.planSize = me.plan.getPlanSize();
                    me.prevX = nil;
                    me.prevY = nil;
                    me.closestDistFromCursor = 10000;
                    me.closestSteerpointToCursor = -1;
                    for (me.j = 0; me.j < me.planSize;me.j+=1) {
                        me.wp = me.plan.getWP(me.j);
                        if (me.wp.lat == 0 and me.wp.lon == 0) continue;# Ignore SIDs that have no GPS position
                        me.wpC = geo.Coord.new();
                        me.wpC.set_latlon(me.wp.lat,me.wp.lon);
                        me.legBearing = me.selfCoord.course_to(me.wpC)-me.selfHeading;#relative
                        me.legDistance = me.selfCoord.distance_to(me.wpC)*M2NM;
                        if (me.get_HSD_centered()) {
                            me.legRangePixels = me.mediumRadius*(me.legDistance/me.get_HSD_range_cen());
                        } else {
                            me.legRangePixels = me.outerRadius*(me.legDistance/me.get_HSD_range_dep());
                        }
                        me.legX = me.legRangePixels*math.sin(me.legBearing*D2R);
                        me.legY = -me.legRangePixels*math.cos(me.legBearing*D2R);
                        #if (me.j == 1) {
                            #printDebug();
                            #printf("Dist=%d bear=%d rangePix=%d   %d,%d",me.legDistance*M2NM,me.legBearing,me.legRangePixels,me.legX,me.legY);
                            #printf("%.3f, %.3f",me.wp.lat,me.wp.lon);
                            #printf("%.3f, %.3f",me.wp.wp_lat,me.wp.wp_lon);
                        #}
                        me.wp = me.cone.createChild("path")
                            .moveTo(me.legX-symbolSize.hsd.steerpoint,me.legY)
                            .arcSmallCW(symbolSize.hsd.steerpoint,symbolSize.hsd.steerpoint, 0, symbolSize.hsd.steerpoint*2, 0)
                            .arcSmallCW(symbolSize.hsd.steerpoint,symbolSize.hsd.steerpoint, 0,-symbolSize.hsd.steerpoint*2, 0)
                            .setStrokeLineWidth(lineWidth.hsd.route)
                            .set("z-index",4)
                            .setColor(colorLine3)
                            .update();
                        if (me.plan.current == me.j) {
                            me.wp.setColorFill(colorLine3);
                        }
                        if (me.prevX != nil) {
                            me.cone.createChild("path")
                                .moveTo(me.legX,me.legY)
                                .lineTo(me.prevX,me.prevY)
                                .setStrokeLineWidth(lineWidth.hsd.route)
                                .set("z-index",4)
                                .setColor(colorLine3)
                                .update();
                        }
                        me.prevX = me.legX;
                        me.prevY = me.legY;

                        if (me.hsdCursorclick) {
                        	me.distFromCursor = math.sqrt(math.pow(me.hsdCursorFromOwnship[0]-me.legX,2)+math.pow(me.hsdCursorFromOwnship[1]-me.legY,2));
                        	if (me.distFromCursor < 11) {# steerpoints
                        		if (me.distFromCursor < me.closestDistFromCursor) {
                        			me.closestDistFromCursor = me.distFromCursor;
                        			me.closestSteerpointToCursor = me.j+1;
                        		}
                        	}
                        }
                    }
                    if (me.closestDistFromCursor < 1000) {
                        me.hsdCursorclick = 0;
                        steerpoints.setCurrentNumber(me.closestSteerpointToCursor);
                    }
                }

                for (var u = 0;u<4;u+=1) {
                    if (steerpoints.lines[u] != nil and steerpoints.linesShow[u]) {
                        # lines
                        me.plan = steerpoints.lines[u];
                        me.planSize = me.plan.getPlanSize();
                        me.prevX = nil;
                        me.prevY = nil;
                        for (me.j = 0; me.j <= me.planSize;me.j+=1) {
                            if (me.j == me.planSize) {
                                if (me.planSize > 2) {
                                    me.wp = me.plan.getWP(0);
                                } else {
                                    continue;
                                }
                            } else {
                                me.wp = me.plan.getWP(me.j);
                            }

                            me.wpC = geo.Coord.new();
                            me.wpC.set_latlon(me.wp.lat,me.wp.lon);
                            me.legBearing = me.selfCoord.course_to(me.wpC)-me.selfHeading;#relative
                            me.legDistance = me.selfCoord.distance_to(me.wpC)*M2NM;
                            if (me.get_HSD_centered()) {
                                me.legRangePixels = me.mediumRadius*(me.legDistance/me.get_HSD_range_cen());;
                            } else {
                                me.legRangePixels = me.outerRadius*(me.legDistance/me.get_HSD_range_dep());;
                            }
                            me.legX = me.legRangePixels*math.sin(me.legBearing*D2R);
                            me.legY = -me.legRangePixels*math.cos(me.legBearing*D2R);
                            if (me.prevX != nil and u == 0) {
                                me.cone.createChild("path")
                                    .moveTo(me.legX,me.legY)
                                    .lineTo(me.prevX,me.prevY)
                                    .setStrokeLineWidth(lineWidth.hsd.line)
                                    .setStrokeDashArray([10, 10])
                                    .set("z-index",4)
                                    .setColor(colorLines[0]*0.70,colorLines[1]*0.70,colorLines[2]*0.70)
                                    .update();
                            } else if (me.prevX != nil and u > 0) {
                                me.cone.createChild("path")
                                    .moveTo(me.legX,me.legY)
                                    .lineTo(me.prevX,me.prevY)
                                    .setStrokeLineWidth(lineWidth.hsd.line)
                                    .setStrokeDashArray([10, 10])
                                    .set("z-index",4)
                                    .setColor(colorLines[0]*0.70,colorLines[1]*0.70,colorLines[2]*0.70)
                                    .update();
                            }
                            me.prevX = me.legX;
                            me.prevY = me.legY;

                            if (me.hsdCursorclick) {
	                        	me.distFromCursor = math.sqrt(math.pow(me.hsdCursorFromOwnship[0]-me.legX,2)+math.pow(me.hsdCursorFromOwnship[1]-me.legY,2));
	                        	if (me.distFromCursor < 11) {#lines
	                        		me.hsdCursorclick = 0;
	                        		me.mkNumber = me.j + steerpoints.index_of_lines[u];
	                        		steerpoints.setCurrentNumber(me.mkNumber);
	                        	}
	                        }
                        }
                    }
                }

                me.cone.update();

                for (var mi = 0; mi < 10; mi+=1) {
                    var mkpt = nil;
                    if (mi<5) {
                    	me.mkNumber = 400+mi
                        
                    } else {
                        me.mkNumber = 450+mi-5;
                    }
                    mkpt = steerpoints.getNumber(me.mkNumber);
                    if (mkpt == nil) {
                        me.mark[mi].hide();
                    } else {
                        me.wpC = geo.Coord.new();
                        me.wpC.set_latlon(mkpt.lat, mkpt.lon);
                        me.legBearing = me.selfCoord.course_to(me.wpC)-me.selfHeading;#relative
                        me.legDistance = me.selfCoord.distance_to(me.wpC)*M2NM;

                        if (me.get_HSD_centered()) {
                            me.legRangePixels = me.mediumRadius*(me.legDistance/me.get_HSD_range_cen());
                        } else {
                            me.legRangePixels = me.outerRadius*(me.legDistance/me.get_HSD_range_dep());
                        }

                        me.legX = me.legRangePixels*math.sin(me.legBearing*D2R);
                        me.legY = -me.legRangePixels*math.cos(me.legBearing*D2R);
                        me.mark[mi].setTranslation(me.legX,me.legY);
                        me.mark[mi].show();
                        if (me.hsdCursorclick) {
                        	me.distFromCursor = math.sqrt(math.pow(me.hsdCursorFromOwnship[0]-me.legX,2)+math.pow(me.hsdCursorFromOwnship[1]-me.legY,2));
                        	if (me.distFromCursor < 11) {# markpoints
                        		me.hsdCursorclick = 0;
                        		steerpoints.setCurrentNumber(me.mkNumber);
                        	}
                        }
                    }
                }
                #printDebug("");printDebug("");printDebug("");
                for (var l = 0; l<steerpoints.number_of_threat_circles;l+=1) {
                    # threat circles
                    me.ci = me.threat_c[l];
                    me.cit = me.threat_t[l];
					me.mkNumber = 300+l;
                    me.cnu = steerpoints.getNumber(me.mkNumber);
                    if (me.cnu == nil or !hsdShowPRE) {
                        me.ci.hide();
                        me.cit.hide();
                        #printDebug("Ignoring ", 300+l);
                        continue;
                    }
                    me.la = me.cnu.lat;
                    me.lo = me.cnu.lon;
                    me.ra = me.cnu.radius;
                    me.ty = me.cnu.type;
                    
                    
                    if (me.la != nil and me.lo != nil and me.ra != nil and me.ra > 0) {
                        me.wpC = geo.Coord.new();
                        me.wpC.set_latlon(me.la,me.lo);
                        me.legBearing = me.selfCoord.course_to(me.wpC)-me.selfHeading;#relative
                        me.legDistance = me.selfCoord.distance_to(me.wpC)*M2NM;
                        me.legRadius  = me.ra;
                        if (me.get_HSD_centered()) {
                            me.legRangePixels = me.mediumRadius*(me.legDistance/me.get_HSD_range_cen());
                            me.legScale = me.mediumRadius*(me.legRadius/me.get_HSD_range_cen())/50;
                        } else {
                            me.legRangePixels = me.outerRadius*(me.legDistance/me.get_HSD_range_dep());
                            me.legScale = me.outerRadius*(me.legRadius/me.get_HSD_range_dep())/50;
                        }

                        me.legX = me.legRangePixels*math.sin(me.legBearing*D2R);
                        me.legY = -me.legRangePixels*math.cos(me.legBearing*D2R);
                        me.ci.setTranslation(me.legX,me.legY);
                        me.ci.setScale(me.legScale);
                        me.ci.setStrokeLineWidth(lineWidth.hsd.threatRing/me.legScale);
                        me.co = me.ra > me.legDistance?colorCircle1:colorCircle2;
                        #printDebug("Painting ", 300+l," in ", me.ra > me.legDistance?"red":"yellow");
                        me.ci.setColor(me.co);
                        me.ci.show();
                        me.cit.setText(me.ty);
                        me.cit.setTranslation(me.legX,me.legY);
                        me.cit.setColor(me.co);
                        me.cit.show();

                        if (me.hsdCursorclick) {
                        	me.distFromCursor = math.sqrt(math.pow(me.hsdCursorFromOwnship[0]-me.legX,2)+math.pow(me.hsdCursorFromOwnship[1]-me.legY,2));
                        	if (me.distFromCursor < 14) {# pre-planned threats
                        		me.hsdCursorclick = 0;
                        		steerpoints.setCurrentNumber(me.mkNumber);
                        	}
                        }
                    } else {
                        me.ci.hide();
                        me.cit.hide();
                    }
                }
            }
            if (cursorFCRgps != nil and me.device.soi != 1 and hsdShowFCR) {
            	me.bearing = cursorFCRgps[0];
                if (me.get_HSD_centered()) {
                    me.rangePixels = me.mediumRadius*(cursorFCRgps[1]/me.get_HSD_range_cen());
                } else {
                    me.rangePixels = me.outerRadius*(cursorFCRgps[1]/me.get_HSD_range_dep());
                }

                me.legX = me.rangePixels*math.sin(me.bearing*D2R);
                me.legY = -me.rangePixels*math.cos(me.bearing*D2R);
            	me.cursorGhost.setTranslation(me.legX, me.legY);
            	me.cursorAirGhost.setVisible(cursorFCRair);
            	me.cursorGmGhost.setVisible(!cursorFCRair);
            	me.cursorGhost.show();
            } else {
            	me.cursorGhost.hide();
            }


#  ██   ██ ███████ ██████      ██████   █████  ██████   █████  ██████ 
#  ██   ██ ██      ██   ██     ██   ██ ██   ██ ██   ██ ██   ██ ██   ██ 
#  ███████ ███████ ██   ██     ██████  ███████ ██   ██ ███████ ██████  
#  ██   ██      ██ ██   ██     ██   ██ ██   ██ ██   ██ ██   ██ ██   ██ 
#  ██   ██ ███████ ██████      ██   ██ ██   ██ ██████  ██   ██ ██   ██ 
#                                                                      
#
            if (noti.FrameCount == 3 and me.up == 1) {
                me.i = 0;#triangles
                me.ii = 0;#dlink
                me.selected = 0;

                me.rando = rand();

                if (radar_system.datalink_power.getBoolValue() and hsdShowDLINK) {
                    foreach(contact; vector_aicontacts_links) {
                        me.blue = contact.blue;
                        me.blueIndex = contact.blueIndex;
                        me.paintBlep(contact);
                        contact.rando = me.rando;
                    }
                }
                if (radar_system.apg68Radar.enabled and hsdShowFCR) {
                    foreach(contact; radar_system.apg68Radar.getActiveBleps()) {
                        if (contact["rando"] == me.rando) continue;

                        me.blue = 0;
                        me.blueIndex = -1;

                        me.paintBlep(contact);
                    }
                }

                for (;me.i<me.maxB;me.i+=1) {
                    me.blepTriangle[me.i].hide();
                }
                for (;me.ii<me.maxB;me.ii+=1) {
                    me.lnk[me.ii].hide();
                    me.lnkT[me.ii].hide();
                    me.lnkTA[me.ii].hide();
                }
                me.selection.setVisible(me.selected);
            }
            if (noti.FrameCount == 3) me.up = !me.up;

            if (cursor_click == me.index) {
            	cursor_click = -1;
            }
        },
        paintBlep: func (contact) {
            if (!contact.isVisible() and me.blue != 2) {
                return;
            }
            me.desig = contact.equals(me.rdrprio);
            me.hasTrack = contact.hasTrackInfo();
            if (!me.hasTrack and me.blue == 0) {
                return;
            }
            me.color = me.blue == 1?colorDot4:(me.blue == 2?colorCircle1:colorCircle2);
            if (me.blue != 0) {
                me.c_rng = contact.getRange()*M2NM;
                me.c_rbe = contact.getDeviationHeading();
                me.c_hea = contact.getHeading();
                me.c_alt = contact.get_altitude();
                me.c_spd = contact.getSpeed();
            } else {
                me.lastBlep = contact.getLastBlep();

                me.c_rng = me.lastBlep.getRangeNow()*M2NM;
                me.c_rbe = me.lastBlep.getAZDeviation();
                me.c_hea = me.lastBlep.getHeading();
                me.c_alt = me.lastBlep.getAltitude();
                me.c_spd = me.lastBlep.getSpeed();
            }


            me.distPixels = (me.c_rng/me.rdrrng)*me.rdrRangePixels;
            #    if (me.blue) printDebug("through ",me.desig," LoS:",!contact.get_behind_terrain());


            me.rot = 22.5*math.round( geo.normdeg((me.c_hea-me.selfHeading))/22.5 )*D2R;#Show rotation in increments of 22.5 deg
            me.trans = [me.distPixels*math.sin(me.c_rbe*D2R),-me.distPixels*math.cos(me.c_rbe*D2R)];

            if (me.blue != 1 and me.i < me.maxB) {
                me.blepTrianglePaths[me.i].setColor(me.color);
                me.blepTriangle[me.i].setTranslation(me.trans);
                me.blepTriangle[me.i].show();
                me.blepTrianglePaths[me.i].setRotation(me.rot);
                me.blepTriangleVel[me.i].setRotation(me.rot);
                me.blepTriangleVelLine[me.i].setScale(1,me.c_spd*symbolSize.hsd.contactVelocity);
                me.blepTriangleVelLine[me.i].setColor(me.color);
                me.lockAlt = sprintf("%02d", math.round(me.c_alt*0.001));
                me.blepTriangleText[me.i].setText(me.lockAlt);
                me.i += 1;
                if (me.blue == 2 and me.ii < me.maxB) {
                    me.lnkT[me.ii].setColor(me.color);
                    me.lnkT[me.ii].setTranslation(me.trans[0],me.trans[1]-symbolSize.hsd.contact*25);
                    me.lnkT[me.ii].setText(""~me.blueIndex);
                    me.lnk[me.ii].hide();
                    me.lnkT[me.ii].show();
                    me.lnkTA[me.ii].hide();
                    me.ii += 1;
                }
            } elsif (me.blue == 1 and me.ii < me.maxB) {
                me.lnk[me.ii].setColor(me.color);
                me.lnk[me.ii].setTranslation(me.trans);
                me.lnk[me.ii].setRotation(me.rot);
                me.lnkT[me.ii].setColor(me.color);
                me.lnkTA[me.ii].setColor(me.color);
                me.lnkT[me.ii].setTranslation(me.trans[0],me.trans[1]-symbolSize.hsd.contact*25);
                me.lnkTA[me.ii].setTranslation(me.trans[0],me.trans[1]+symbolSize.hsd.contact*20);
                me.lnkT[me.ii].setText(""~me.blueIndex);
                me.lnkTA[me.ii].setText(sprintf("%02d", math.round(me.c_alt*0.001)));
                me.lnk[me.ii].show();
                me.lnkTA[me.ii].show();
                me.lnkT[me.ii].show();
                me.ii += 1;
            }

            if (me.desig) {
                me.selection.setTranslation(me.trans);
                me.selection.setColor(me.color);
                me.selected = 1;
            }
        },
		exit: func {
			printDebug("Exit ",me.name~" on ",me.device.name);
		},
		links: {
			"OSB11":  "PageFCR",
			"OSB15":  "PageHSDCNTL",
			"OSB17":  "PageMenu",
			"OSB18":  "PageSMSINV",
			"OSB19":  "PageSMSWPN",
		},
		layers: ["OSB1TO2ARROWS","BULLSEYE"],
	},

#  ███████ ███    ███ ███████     ██ ███    ██ ██    ██ 
#  ██      ████  ████ ██          ██ ████   ██ ██    ██ 
#  ███████ ██ ████ ██ ███████     ██ ██ ██  ██ ██    ██ 
#       ██ ██  ██  ██      ██     ██ ██  ██ ██  ██  ██  
#  ███████ ██      ██ ███████     ██ ██   ████   ████   
#                                                       
#                                                       

	PageSMSINV: {
		name: "PageSMSINV",
		isNew: 1,
		supportSOI: 0,
		needGroup: 1,
		new: func {
			me.instance = {parents:[DisplaySystem.PageSMSINV]};
			me.instance.group = nil;
			return me.instance;
		},
		setup: func {
			printDebug(me.name," on ",me.device.name," is being setup");
			me.setupSMS();
		},
		setupSMS: func {
			me.groupInv = me.group;
	        me.groupInv.setTranslation(0.515*displayWidth, displayHeight);
	        

	        me.cat = me.groupInv.createChild("text")
	                .setTranslation(0, -displayHeightHalf+100)
	                .setText("CAT I")
	                .setAlignment("center-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);

	        me.gun = me.groupInv.createChild("text")
	                .setTranslation(-displayWidthHalf*0.95, -displayHeightHalf-155)
	                .setText("-----")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);
	        me.gun2 = me.groupInv.createChild("text")
	                .setTranslation(-displayWidthHalf*0.95, -displayHeightHalf-130)
	                .setText("-----")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);

	        me.p6 = me.groupInv.createChild("text")
	                .setTranslation(displayWidthHalf*0.10, -displayHeightHalf-90)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);
	        me.p6l1 = me.groupInv.createChild("text")
	                .setTranslation(displayWidthHalf*0.10, -displayHeightHalf-65)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);
	        me.p6l2 = me.groupInv.createChild("text")
	                .setTranslation(displayWidthHalf*0.10, -displayHeightHalf-40)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);

	        me.p7 = me.groupInv.createChild("text")
	                .setTranslation(displayWidthHalf*0.37, -displayHeightHalf-15)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);
	        me.p7l1 = me.groupInv.createChild("text")
	                .setTranslation(displayWidthHalf*0.37, -displayHeightHalf+10)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);
	        me.p7l2 = me.groupInv.createChild("text")
	                .setTranslation(displayWidthHalf*0.37, -displayHeightHalf+35)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);

	        me.p8 = me.groupInv.createChild("text")
	                .setTranslation(displayWidthHalf*0.52, -displayHeightHalf+60)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);
	        me.p8l1 = me.groupInv.createChild("text")
	                .setTranslation(displayWidthHalf*0.52, -displayHeightHalf+85)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);

	        me.p9 = me.groupInv.createChild("text")
	                .setTranslation(displayWidthHalf*0.52, -displayHeightHalf+125)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);
	        me.p9l1 = me.groupInv.createChild("text")
	                .setTranslation(displayWidthHalf*0.52, -displayHeightHalf+150)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);

	        me.p5 = me.groupInv.createChild("text")
	                .setTranslation(-displayWidthHalf*0.20, -displayHeightHalf-190)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);
	        me.p5l1 = me.groupInv.createChild("text")
	                .setTranslation(-displayWidthHalf*0.20, -displayHeightHalf-165)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);
	        me.p5l2 = me.groupInv.createChild("text")
	                .setTranslation(-displayWidthHalf*0.20, -displayHeightHalf-140)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);

	        me.p4 = me.groupInv.createChild("text")
	                .setTranslation(-displayWidthHalf*0.51, -displayHeightHalf-90)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);
	        me.p4l1 = me.groupInv.createChild("text")
	                .setTranslation(-displayWidthHalf*0.51, -displayHeightHalf-65)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);
	        me.p4l2 = me.groupInv.createChild("text")
	                .setTranslation(-displayWidthHalf*0.51, -displayHeightHalf-40)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);

	        me.p3 = me.groupInv.createChild("text")
	                .setTranslation(-displayWidthHalf*0.8, -displayHeightHalf-15)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);
	        me.p3l1 = me.groupInv.createChild("text")
	                .setTranslation(-displayWidthHalf*0.8, -displayHeightHalf+10)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);
	        me.p3l2 = me.groupInv.createChild("text")
	                .setTranslation(-displayWidthHalf*0.8, -displayHeightHalf+35)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);

	        me.p2 = me.groupInv.createChild("text")
	                .setTranslation(-displayWidthHalf*0.95, -displayHeightHalf+60)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);
	        me.p2l1 = me.groupInv.createChild("text")
	                .setTranslation(-displayWidthHalf*0.95, -displayHeightHalf+85)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);

	        me.p1 = me.groupInv.createChild("text")
	                .setTranslation(-displayWidthHalf*0.95, -displayHeightHalf+125)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);
	        me.p1l1 = me.groupInv.createChild("text")
	                .setTranslation(-displayWidthHalf*0.95, -displayHeightHalf+150)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);

	        me.p1f = me.groupInv.createChild("path")
	           .moveTo(-displayWidthHalf*0.97, -displayHeightHalf+115)
	           .vert(50)
	           .horiz(100)
	           .vert(-50)
	           .horiz(-100)
	           .setColor(colorText1)
	           .setStrokeLineWidth(2)
	           .hide();
	        me.p2f = me.groupInv.createChild("path")
	           .moveTo(-displayWidthHalf*0.96, -displayHeightHalf+50)
	           .vert(50)
	           .horiz(100)
	           .vert(-50)
	           .horiz(-100)
	           .setColor(colorText1)
	           .setStrokeLineWidth(2)
	           .hide();
	        me.p3f = me.groupInv.createChild("path")
	           .moveTo(-displayWidthHalf*0.81, -displayHeightHalf-25)
	           .vert(70)
	           .horiz(100)
	           .vert(-70)
	           .horiz(-100)
	           .setColor(colorText1)
	           .setStrokeLineWidth(2)
	           .hide();
	        me.p4f = me.groupInv.createChild("path")
	           .moveTo(-displayWidthHalf*0.52, -displayHeightHalf-100)
	           .vert(70)
	           .horiz(100)
	           .vert(-70)
	           .horiz(-100)
	           .setColor(colorText1)
	           .setStrokeLineWidth(2)
	           .hide();
	        me.p5f = me.groupInv.createChild("path")
	           .moveTo(-displayWidthHalf*0.21, -displayHeightHalf-200)
	           .vert(70)
	           .horiz(100)
	           .vert(-70)
	           .horiz(-100)
	           .setColor(colorText1)
	           .setStrokeLineWidth(2)
	           .hide();
	        me.p6f = me.groupInv.createChild("path")
	           .moveTo(displayWidthHalf*0.09, -displayHeightHalf-100)
	           .vert(70)
	           .horiz(100)
	           .vert(-70)
	           .horiz(-100)
	           .setColor(colorText1)
	           .setStrokeLineWidth(2)
	           .hide();
	        me.p7f = me.groupInv.createChild("path")
	           .moveTo(displayWidthHalf*0.36, -displayHeightHalf-25)
	           .vert(70)
	           .horiz(100)
	           .vert(-70)
	           .horiz(-100)
	           .setColor(colorText1)
	           .setStrokeLineWidth(2)
	           .hide();
	        me.p8f = me.groupInv.createChild("path")
	           .moveTo(displayWidthHalf*0.5, -displayHeightHalf+50)
	           .vert(50)
	           .horiz(100)
	           .vert(-50)
	           .horiz(-100)
	           .setColor(colorText1)
	           .setStrokeLineWidth(2)
	           .hide();
	        me.p9f = me.groupInv.createChild("path")
	           .moveTo(displayWidthHalf*0.5, -displayHeightHalf+115)
	           .vert(50)
	           .horiz(100)
	           .vert(-50)
	           .horiz(-100)
	           .setColor(colorText1)
	           .setStrokeLineWidth(2)
	           .hide();
	        me.pGunf = me.groupInv.createChild("path")
	           .moveTo(-displayWidthHalf*0.97, -displayHeight+88)
	           .vert(50)
	           .horiz(75)
	           .vert(-50)
	           .horiz(-75)
	           .setColor(colorText1)
	           .setStrokeLineWidth(2)
	           .hide();
	    },
		enter: func {
			printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = 0;
			}
			me.device.resetControls();
			me.device.controls["OSB6"].setControlText("S-J");
			me.device.controls["OSB11"].setControlText("FCR");
			me.device.controls["OSB16"].setControlText("SWAP");
			me.device.controls["OSB17"].setControlText("HSD");
			me.device.controls["OSB18"].setControlText("SMS", 0);
			me.device.controls["OSB19"].setControlText("WPN");
			me.device.controls["OSB20"].setControlText("TGP");
		},
		selectPylon: func (sta) {
			if (variantID == 0) {
                return;
            }
            pylons.fcs.selectPylon(sta);
		},
		controlAction: func (controlName) {
			printDebug(me.name,": ",controlName," activated on ",me.device.name);
			if (controlName == "OSB1") {
                me.selectPylon(9);
            } elsif (controlName == "OSB2") {
                me.selectPylon(3);
            } elsif (controlName == "OSB3") {
                me.selectPylon(2);
            } elsif (controlName == "OSB4") {
                me.selectPylon(1);
            } elsif (controlName == "OSB5") {
                me.selectPylon(0);
            } elsif (controlName == "OSB7") {
                me.selectPylon(5);
            } elsif (controlName == "OSB8") {
                me.selectPylon(6);
            } elsif (controlName == "OSB9") {
                me.selectPylon(7);
            } elsif (controlName == "OSB10") {
                me.selectPylon(8);
            } elsif (controlName == "OSB13") {
                me.selectPylon(4);
            } elsif (controlName == "OSB16") {
                me.device.swap();
            } elsif (controlName == "OSB20") {
                switchTGP();
            }
		},
		update: func (noti = nil) {
			if (noti.FrameCount != 3)
                return;
            if (variantID == 0) {
                return;
            }

            me.catNumber = pylons.fcs.getCategory();
            me.cat.setText(sprintf("CAT %s", me.catNumber==1?"I":(me.catNumber==2?"II":"III")));

            var sel = pylons.fcs.getSelectedPylonNumber();
            me.p1f.setVisible(sel==0);
            me.p2f.setVisible(sel==1);
            me.p3f.setVisible(sel==2);
            me.p4f.setVisible(sel==3);
            me.p5f.setVisible(sel==4);
            me.p6f.setVisible(sel==5);
            me.p7f.setVisible(sel==6);
            me.p8f.setVisible(sel==7);
            me.p9f.setVisible(sel==8);
            me.pGunf.setVisible(sel==9);

            var gunAmmo = "-----";
            if (getprop("sim/model/f16/wingmounts") != 0) {
                gunAmmo = pylons.pylonI.getAmmo("20mm Cannon");
                if (gunAmmo ==0) gunAmmo = "0";
                elsif (gunAmmo <10) gunAmmo = "1";
                else gunAmmo = ""~int(gunAmmo*0.1);
            }
            me.gun.setText(gunAmmo~"GUN");
            if (variantID == 0 or variantID == 1 or variantID == 3) {
                me.gun2.setText("M56");
            } else {
                me.gun2.setText("PGU28");
            }

            me.setTextOnStation([me.p1, me.p1l1], pylons.pylon1);
            me.setTextOnStation([me.p2, me.p2l1], pylons.pylon2);
            me.setTextOnStation([me.p3, me.p3l1, me.p3l2], pylons.pylon3);
            me.setTextOnStation([me.p4, me.p4l1, me.p4l2], pylons.pylon4);
            me.setTextOnStation([me.p5, me.p5l1, me.p5l2], pylons.pylon5);
            me.setTextOnStation([me.p6, me.p6l1, me.p6l2], pylons.pylon6);
            me.setTextOnStation([me.p7, me.p7l1, me.p7l2], pylons.pylon7);
            me.setTextOnStation([me.p8, me.p8l1], pylons.pylon8);
            me.setTextOnStation([me.p9, me.p9l1], pylons.pylon9);
        },
		setTextOnStation: func (lines, pylon) {
            # no check for pylon 1 and 9 if you enter both rack and pylon for them, this method will fail. So take care.
            if (pylon == nil) {
                lines[0].setText("--------");
                lines[1].setText("--------");
                if (size(lines) == 3) {
                    lines[2].setText("--------");
                }
                return;
            }
            me.curr = 0;
            me.pylName = pylon.getCurrentPylon();
            if (me.pylName != nil) {
                lines[me.curr].setText(me.pylName);
                me.curr += 1;
            }
            me.rackName = pylon.getCurrentRack();
            if (me.rackName != nil) {
                lines[me.curr].setText(me.rackName);
                me.curr += 1;
            }
            me.weapName = pylon.getCurrentSMSName();
            if (me.weapName != nil) {
                lines[me.curr].setText(me.weapName);
                me.curr += 1;
            }
            for (var i = me.curr ; i < size(lines); i += 1) {
                lines[i].setText("--------");
            }
        },
		exit: func {
			printDebug("Exit ",me.name~" on ",me.device.name);
		},
		links: {
			"OSB6":  "PageSJ",
			"OSB11": "PageFCR",
			"OSB17": "PageHSD",
			"OSB18": "PageMenu",
			"OSB19": "PageSMSWPN",
		},
		layers: ["BULLSEYE"],
	},

#  ███████            ██ 
#  ██                 ██ 
#  ███████ █████      ██ 
#       ██       ██   ██ 
#  ███████        █████  
#                        
#                        

	PageSJ: {
		name: "PageSJ",
		isNew: 1,
		supportSOI: 0,
		needGroup: 1,
		new: func {
			me.instance = {parents:[DisplaySystem.PageSJ]};
			me.instance.group = nil;
			return me.instance;
		},
		setup: func {
			printDebug(me.name," on ",me.device.name," is being setup");
			me.setupSJ();
		},
		setupSJ: func {

	        me.group.setTranslation(0.515*displayWidth, displayHeight);

	        me.p6 = me.group.createChild("text")
	                .setTranslation(displayWidthHalf*0.10, -displayHeightHalf-90)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);
	        me.p6l1 = me.group.createChild("text")
	                .setTranslation(displayWidthHalf*0.10, -displayHeightHalf-65)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);
	        me.p6l2 = me.group.createChild("text")
	                .setTranslation(displayWidthHalf*0.10, -displayHeightHalf-40)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);

	        me.p7 = me.group.createChild("text")
	                .setTranslation(displayWidthHalf*0.37, -displayHeightHalf-15)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);
	        me.p7l1 = me.group.createChild("text")
	                .setTranslation(displayWidthHalf*0.37, -displayHeightHalf+10)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);
	        me.p7l2 = me.group.createChild("text")
	                .setTranslation(displayWidthHalf*0.37, -displayHeightHalf+35)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);

	        me.p5 = me.group.createChild("text")
	                .setTranslation(-displayWidthHalf*0.20, -displayHeightHalf-190)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);
	        me.p5l1 = me.group.createChild("text")
	                .setTranslation(-displayWidthHalf*0.20, -displayHeightHalf-165)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);
	        me.p5l2 = me.group.createChild("text")
	                .setTranslation(-displayWidthHalf*0.20, -displayHeightHalf-140)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);

	        me.p4 = me.group.createChild("text")
	                .setTranslation(-displayWidthHalf*0.51, -displayHeightHalf-90)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);
	        me.p4l1 = me.group.createChild("text")
	                .setTranslation(-displayWidthHalf*0.51, -displayHeightHalf-65)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);
	        me.p4l2 = me.group.createChild("text")
	                .setTranslation(-displayWidthHalf*0.51, -displayHeightHalf-40)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);

	        me.p3 = me.group.createChild("text")
	                .setTranslation(-displayWidthHalf*0.8, -displayHeightHalf-15)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);
	        me.p3l1 = me.group.createChild("text")
	                .setTranslation(-displayWidthHalf*0.8, -displayHeightHalf+10)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);
	        me.p3l2 = me.group.createChild("text")
	                .setTranslation(-displayWidthHalf*0.8, -displayHeightHalf+35)
	                .setText("--------")
	                .setAlignment("left-center")
	                .setColor(colorText1)
	                .setFontSize(me.device.fontSize, 1.0);


	        me.p3f = me.group.createChild("path")
	           .moveTo(-displayWidthHalf*0.81, -displayHeightHalf-25)
	           .vert(70)
	           .horiz(100)
	           .vert(-70)
	           .horiz(-100)
	           .setColor(colorText1)
	           .setStrokeLineWidth(2)
	           .hide();
	        me.p4f = me.group.createChild("path")
	           .moveTo(-displayWidthHalf*0.52, -displayHeightHalf-100)
	           .vert(70)
	           .horiz(100)
	           .vert(-70)
	           .horiz(-100)
	           .setColor(colorText1)
	           .setStrokeLineWidth(2)
	           .hide();
	        me.p5f = me.group.createChild("path")
	           .moveTo(-displayWidthHalf*0.21, -displayHeightHalf-200)
	           .vert(70)
	           .horiz(100)
	           .vert(-70)
	           .horiz(-100)
	           .setColor(colorText1)
	           .setStrokeLineWidth(2)
	           .hide();
	        me.p6f = me.group.createChild("path")
	           .moveTo(displayWidthHalf*0.09, -displayHeightHalf-100)
	           .vert(70)
	           .horiz(100)
	           .vert(-70)
	           .horiz(-100)
	           .setColor(colorText1)
	           .setStrokeLineWidth(2)
	           .hide();
	        me.p7f = me.group.createChild("path")
	           .moveTo(displayWidthHalf*0.36, -displayHeightHalf-25)
	           .vert(70)
	           .horiz(100)
	           .vert(-70)
	           .horiz(-100)
	           .setColor(colorText1)
	           .setStrokeLineWidth(2)
	           .hide();
	    },
		enter: func {
			printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = 0;
			}
			me.device.resetControls();
			me.device.controls["OSB6"].setControlText("S-J", 0);
			me.device.controls["OSB16"].setControlText("SWAP");
			screen.log.write("Click trigger to jettison selected stores",1,1,0.75);
		},
		selectPylon: func (sta) {
			if (variantID == 0) {
                return;
            }
            pylons.fcs.toggleStationForSJ(sta);
		},
		controlAction: func (controlName) {
			printDebug(me.name,": ",controlName," activated on ",me.device.name);
			if (controlName == "OSB2") {
                me.selectPylon(3);
            } elsif (controlName == "OSB3") {
                me.selectPylon(2);
            } elsif (controlName == "OSB6") {
                pylons.fcs.clearStationForSJ();
            } elsif (controlName == "OSB7") {
                me.selectPylon(5);
            } elsif (controlName == "OSB8") {
                me.selectPylon(6);
            } elsif (controlName == "OSB13") {
                me.selectPylon(4);
            } elsif (controlName == "OSB16") {
                me.device.swap();
            }
		},
		update: func (noti = nil) {
			if (noti.FrameCount != 3)
                return;
            if (variantID == 0) {
                return;
            }

            me.p3f.setVisible(pylons.fcs.isSelectStationForSJ(2));
            me.p4f.setVisible(pylons.fcs.isSelectStationForSJ(3));
            me.p5f.setVisible(pylons.fcs.isSelectStationForSJ(4));
            me.p6f.setVisible(pylons.fcs.isSelectStationForSJ(5));
            me.p7f.setVisible(pylons.fcs.isSelectStationForSJ(6));

            me.setTextOnStation([me.p3, me.p3l1, me.p3l2], pylons.pylon3);
            me.setTextOnStation([me.p4, me.p4l1, me.p4l2], pylons.pylon4);
            me.setTextOnStation([me.p5, me.p5l1, me.p5l2], pylons.pylon5);
            me.setTextOnStation([me.p6, me.p6l1, me.p6l2], pylons.pylon6);
            me.setTextOnStation([me.p7, me.p7l1, me.p7l2], pylons.pylon7);
        },
		setTextOnStation: func (lines, pylon) {
            # no check for pylon 1 and 9 if you enter both rack and pylon for them, this method will fail. So take care.
            if (pylon == nil) {
                lines[0].setText("--------");
                lines[1].setText("--------");
                if (size(lines) == 3) {
                    lines[2].setText("--------");
                }
                return;
            }
            me.curr = 0;
            me.pylName = pylon.getCurrentPylon();
            if (me.pylName != nil) {
                lines[me.curr].setText(me.pylName);
                me.curr += 1;
            }
            me.rackName = pylon.getCurrentRack();
            if (me.rackName != nil) {
                lines[me.curr].setText(me.rackName);
                me.curr += 1;
            }
            me.weapName = pylon.getCurrentSMSName();
            if (me.weapName != nil) {
                lines[me.curr].setText(me.weapName);
                me.curr += 1;
            }
            for (var i = me.curr ; i < size(lines); i += 1) {
                lines[i].setText("--------");
            }
        },
		exit: func {
			printDebug("Exit ",me.name~" on ",me.device.name);
		},
		links: {
			"OSB6": "PageSMSINV",
		},
		layers: ["BULLSEYE"],
	},

#  ██████   █████  ██████   █████  ██████  
#  ██   ██ ██   ██ ██   ██ ██   ██ ██   ██ 
#  ██████  ███████ ██   ██ ███████ ██████  
#  ██   ██ ██   ██ ██   ██ ██   ██ ██   ██ 
#  ██   ██ ██   ██ ██████  ██   ██ ██   ██ 
#                                          
#                                          

	PageFCR: {
		name: "PageFCR",
		isNew: 1,
		supportSOI: 1,
		needGroup: 1,
		soiPrio: 10,
		new: func {
			me.instance = {parents:[DisplaySystem.PageFCR]};
			me.instance.group = nil;
			return me.instance;
		},
		setup: func {
			printDebug(me.name," on ",me.device.name," is being setup");
			me.setupRadar(me.device.name=="LeftMFD"?0:1);
			me.model_index = me.device.name=="LeftMFD"?0:1;

			# Init vars used in layer callbacks:
	        me.rangeVis = 0;
	        me.rangeText = "";
	        me.showRangeDown = 0;
	        me.showRangeUp = 0;

	        me.wdt = displayWidth;
	        me.fwd = 0;
	        me.plc = 0;
	        me.gmLine = 64;
	        me.elapsed = 0;
	        me.pressEXP = 0;
	        me.gmMin = 0;
	        me.gmMax = 1500;
	        me.gmMintemp = 5000;
	        me.gmMaxtemp = 300;
	        me.rdrModeHDGM = 0;
	        me.beamSpot = geo.Coord.new();
	        me.terrain = geo.Coord.new();
	        me.gmColor = 0;
	        me.slew_c_last = slew_c;
		},
		setupRadar: func (index) {

	        me.p_RDR = me.group.createChild("group")
	                .setTranslation(displayWidthHalf,displayHeight)
	                .set("z-index",2)
	                .set("font","LiberationFonts/LiberationMono-Regular.ttf");#552,displayHeight , 0.795 is for UV map
	        me.p_RDR_image = me.group.createChild("group")
	                .setTranslation(displayWidthHalf,displayHeight)
	                .set("z-index",0)
	                .hide()
	                .set("font","LiberationFonts/LiberationMono-Regular.ttf");#552,displayHeight , 0.795 is for UV map

	        me.maxB = 150;
	        me.maxT =  15;
	        me.index = index;
	        me.blep = setsize([],me.maxB);
	        me.blepTriangle = setsize([],me.maxT);
	        me.blepTriangleVel = setsize([],me.maxT);
	        me.blepTriangleVelLine = setsize([],me.maxT);
	        me.blepTriangleText = setsize([],me.maxT);
	        me.blepTrianglePaths = setsize([],me.maxT);
	        me.lnk = setsize([],me.maxT);
	        me.lnkT = setsize([],me.maxT+1);
	        me.lnkTA = setsize([],me.maxT+1);
	        me.iff  = setsize([],me.maxT);# friendly IFF response
	        me.iffU = setsize([],me.maxT);# unknown IFF response
	        for (var i = 0;i<me.maxB;i+=1) {
	                me.blep[i] = me.p_RDR.createChild("path")
	                        .moveTo(0,-symbolSize.fcr.blep*0.5)
	                        .vert(symbolSize.fcr.blep)
	                        .setStrokeLineWidth(symbolSize.fcr.blep)
	                        .setStrokeLineCap("butt")
	                        .set("z-index",10)
	                        .hide();
	        }
	        for (var i = 0;i<me.maxT;i+=1) {
	                me.blepTriangle[i] = me.p_RDR.createChild("group")
	                                .set("z-index",11);
	                me.blepTriangleVel[i] = me.blepTriangle[i].createChild("group");
	                me.blepTriangleText[i] = me.blepTriangle[i].createChild("text")
	                                .setAlignment("center-top")
	                                .setFontSize(me.device.fontSize, 1.0)
	                                .setTranslation(0,margin.fcr.trackText)
	                                .setColor(1, 1, 1);
	                me.blepTriangleVelLine[i] = me.blepTriangleVel[i].createChild("path")
	                                .lineTo(0,-10)# don't change
	                                .setTranslation(0,-16*symbolSize.fcr.track)
	                                .setStrokeLineWidth(lineWidth.fcr.track)
	                                .setColor(colorCircle2);
	                me.blepTrianglePaths[i] = me.blepTriangle[i].createChild("path")
	                                .moveTo(-14*symbolSize.fcr.track,8*symbolSize.fcr.track)
	                                .horiz(28*symbolSize.fcr.track)
	                                .lineTo(0,-16*symbolSize.fcr.track)
	                                .lineTo(-14*symbolSize.fcr.track,8*symbolSize.fcr.track)
	                                .setColor(colorCircle2)
	                                .set("z-index",10)
	                                .setStrokeLineWidth(lineWidth.fcr.track);
	                me.iff[i] = me.p_RDR.createChild("path")
	                                .moveTo(-symbolSize.fcr.iff,0)
	                                .arcSmallCW(symbolSize.fcr.iff,symbolSize.fcr.iff, 0,  symbolSize.fcr.iff*2, 0)
	                                .arcSmallCW(symbolSize.fcr.iff,symbolSize.fcr.iff, 0, -symbolSize.fcr.iff*2, 0)
	                                .setColor(colorCircle3)
	                                .hide()
	                                .set("z-index",12)
	                                .setStrokeLineWidth(lineWidth.fcr.iff);
	                me.iffU[i] = me.p_RDR.createChild("path")
	                                .moveTo(-symbolSize.fcr.iff,-symbolSize.fcr.iff)
	                                .vert(symbolSize.fcr.iff*2)
	                                .horiz(symbolSize.fcr.iff*2)
	                                .vert(-symbolSize.fcr.iff*2)
	                                .horiz(-symbolSize.fcr.iff*2)
	                                .setColor(colorCircle2)
	                                .hide()
	                                .set("z-index",12)
	                                .setStrokeLineWidth(lineWidth.fcr.iff);
	                me.lnk[i] = me.p_RDR.createChild("path")
	                                .moveTo(-symbolSize.fcr.dl,-symbolSize.fcr.dl)
	                                .vert(2*symbolSize.fcr.dl)
	                                .horiz(2*symbolSize.fcr.dl)
	                                .vert(-2*symbolSize.fcr.dl)
	                                .horiz(-2*symbolSize.fcr.dl)
	                                .moveTo(0,-symbolSize.fcr.dl)
	                                .vert(-symbolSize.fcr.dl)
	                                .setColor(colorDot1)
	                                .hide()
	                                .set("z-index",11)
	                                .setStrokeLineWidth(lineWidth.fcr.dl);

	            me.lnkT[i] = me.p_RDR.createChild("text")
	                .setAlignment("center-bottom")
	                .setColor(colorDot1)
	                .set("z-index",1)
	                .setFontSize(me.device.fontSize, 1.0);
	            me.lnkTA[i] = me.p_RDR.createChild("text")
	                                .setAlignment("center-top")
	                                .setFontSize(me.device.fontSize, 1.0);
	        }
	        me.gainGauge = me.p_RDR.createChild("path")
	                    .moveTo(-displayWidth*0.5*0.85,-displayHeight*0.95)
	                    .horiz(-symbolSize.fcr.gainGaugeHoriz)
	                    .vert(symbolSize.fcr.gainGaugeVert)
	                    .horiz(symbolSize.fcr.gainGaugeHoriz)
	                    .setStrokeLineWidth(lineWidth.fcr.gainGauge)
	                    .set("z-index",1)
	                    .setColor(colorText1);
	        me.gainGaugePointer = me.p_RDR.createChild("path")
	                    .lineTo(symbolSize.fcr.gainGaugeHoriz*0.5,-symbolSize.fcr.gainGaugeHoriz*0.5)
	                    .moveTo(0,0)
	                    .lineTo(symbolSize.fcr.gainGaugeHoriz*0.5, symbolSize.fcr.gainGaugeHoriz*0.5)
	                    .setStrokeLineWidth(lineWidth.fcr.gainGauge)
	                    .set("z-index",1)
	                    .setColor(colorText1);

	        var antSideBuffer = margin.fcr.caretSide;
	        var antBottomBuffer = margin.fcr.caretBottom;
	        me.ant_bottom = me.p_RDR.createChild("path")
	                    .moveTo(0,-antBottomBuffer+symbolSize.fcr.caret)
	                    .vert(-symbolSize.fcr.caret)
	                    .moveTo(-symbolSize.fcr.caret*0.5,-antBottomBuffer)
	                    .horiz(symbolSize.fcr.caret)
	                    .setStrokeLineWidth(lineWidth.fcr.caret)
	                    .set("z-index",1)
	                    .setColor(colorLine1);
	        me.ant_side = me.p_RDR.createChild("path")
	                    .moveTo(-displayWidthHalf+antSideBuffer,-displayHeight*0.5)
	                    .horiz(-symbolSize.fcr.caret)
	                    .moveTo(-displayWidthHalf+antSideBuffer,-displayHeight*0.5-symbolSize.fcr.caret*0.5)
	                    .vert(symbolSize.fcr.caret)
	                    .setStrokeLineWidth(lineWidth.fcr.caret)
	                    .set("z-index",1)
	                    .setColor(colorLine1);
	        if (variantID < 2 or variantID == 3) {
	        	# distance ticks
	            me.distl = me.p_RDR.createChild("path")
	                        .moveTo(-displayWidthHalf+antSideBuffer,-displayHeight*0.25)
	                        .horiz(15*symbolSize.fcr.tick)
	                        .moveTo(-displayWidthHalf+antSideBuffer,-displayHeight*0.5)
	                        .horiz(25*symbolSize.fcr.tick)
	                        .moveTo(-displayWidthHalf+antSideBuffer,-displayHeight*0.75)
	                        .horiz(15*symbolSize.fcr.tick)
	                        .moveTo(-displayWidthHalf*0.5,-antBottomBuffer)
	                        .vert(-15*symbolSize.fcr.tick)
	                        .moveTo(0,-antBottomBuffer)
	                        .vert(-25*symbolSize.fcr.tick)
	                        .moveTo(displayWidthHalf*0.5,-antBottomBuffer)
	                        .vert(-15*symbolSize.fcr.tick)
	                        .setStrokeLineWidth(lineWidth.fcr.tick)
	                        .set("z-index",1)
	                        .setColor(colorLine1);
	        } else {
	            me.distl = me.p_RDR.createChild("path")
	                    .moveTo(-displayWidthHalf+antSideBuffer,-displayHeight*0.25)
	                    .horiz(12.5*symbolSize.fcr.tick)
	                    .moveTo(-displayWidthHalf+antSideBuffer,-displayHeight*0.3333)
	                    .horiz(12.5*symbolSize.fcr.tick)
	                    .moveTo(-displayWidthHalf+antSideBuffer,-displayHeight*0.4166)
	                    .horiz(12.5*symbolSize.fcr.tick)
	                    .moveTo(-displayWidthHalf+antSideBuffer,-displayHeight*0.5)
	                    .horiz(20.0*symbolSize.fcr.tick)
	                    .moveTo(-displayWidthHalf+antSideBuffer,-displayHeight*0.5833)
	                    .horiz(12.5*symbolSize.fcr.tick)
	                    .moveTo(-displayWidthHalf+antSideBuffer,-displayHeight*0.6666)
	                    .horiz(12.5*symbolSize.fcr.tick)
	                    .moveTo(-displayWidthHalf+antSideBuffer,-displayHeight*0.75)
	                    .horiz(12.5*symbolSize.fcr.tick)
	                    .moveTo(-displayWidthHalf*0.5,-antBottomBuffer)
	                    .vert(-12.5*symbolSize.fcr.tick)
	                    .moveTo(-displayWidthHalf*0.3333,-antBottomBuffer)
	                    .vert(-12.5*symbolSize.fcr.tick)
	                    .moveTo(-displayWidthHalf*0.1666,-antBottomBuffer)
	                    .vert(-12.5*symbolSize.fcr.tick)
	                    .moveTo(0,-antBottomBuffer)
	                    .vert(-20.0*symbolSize.fcr.tick)
	                    .moveTo(displayWidthHalf*0.3333,-antBottomBuffer)
	                    .vert(-12.5*symbolSize.fcr.tick)
	                    .moveTo(displayWidthHalf*0.1666,-antBottomBuffer)
	                    .vert(-12.5*symbolSize.fcr.tick)
	                    .moveTo(displayWidthHalf*0.5,-antBottomBuffer)
	                    .vert(-12.5*symbolSize.fcr.tick)
	                    .setStrokeLineWidth(lineWidth.fcr.tick)
	                    .set("z-index",1)
	                    .setColor(colorLine1);
	        }

	        me.selection = me.p_RDR.createChild("group")
	                .set("z-index",12);
	        me.selectionPath = me.selection.createChild("path")
	                .moveTo(-symbolSize.fcr.designation, 0)
	                .arcSmallCW(symbolSize.fcr.designation, symbolSize.fcr.designation, 0, symbolSize.fcr.designation*2, 0)
	                .arcSmallCW(symbolSize.fcr.designation, symbolSize.fcr.designation, 0, -symbolSize.fcr.designation*2, 0)
	                .setColor(colorDot1)
	                .setStrokeLineWidth(lineWidth.fcr.designation);

	        me.lockInfoCanvas = me.p_RDR.createChild("text")
	                .setTranslation(0, -displayHeight*0.9)
	                .setAlignment("center-center")
	                .setColor(colorLine3)
	                .set("z-index",1)
	                .setFontSize(me.device.fontSize, 1.0);

	        me.interceptCross = me.p_RDR.createChild("path")
	                            .moveTo(symbolSize.fcr.interceptCross,0)
	                            .lineTo(-symbolSize.fcr.interceptCross,0)
	                            .moveTo(0,-symbolSize.fcr.interceptCross)
	                            .vert(2*symbolSize.fcr.interceptCross)
	                            .setColor(colorCircle2)
	                            .set("z-index",14)
	                            .setStrokeLineWidth(lineWidth.fcr.interceptCross);

	        me.lockGM = me.p_RDR.createChild("path")
	                            .moveTo(symbolSize.fcr.designationGM,0)
	                            .lineTo(0,symbolSize.fcr.designationGM)
	                            .lineTo(-symbolSize.fcr.designationGM,0)
	                            .lineTo(0,-symbolSize.fcr.designationGM)
	                            .lineTo(symbolSize.fcr.designationGM,0)
	                            .setColorFill(colorCircle2)
	                            .setColor(colorCircle2)
	                            .set("z-index",20)
	                            .setStrokeLineWidth(lineWidth.fcr.designationGM);

	        me.dlzX      = displayWidthHalf*0.75;
	        me.dlzY      =-displayHeight*0.25;
	        me.dlzWidth  =  symbolSize.fcr.dlzWidth;
	        me.dlzHeight = displayHeight*0.5;
	        me.dlzLW     =   lineWidth.fcr.dlz;
	        me.dlz      = me.p_RDR.createChild("group")
	                        .set("z-index",11)
	                        .setTranslation(me.dlzX, me.dlzY);
	        me.dlz2     = me.dlz.createChild("group");
	        me.dlzArrow = me.dlz.createChild("path")
	           .moveTo(0, 0)
	           .lineTo( -10*symbolSize.fcr.dlzArrow, 8*symbolSize.fcr.dlzArrow)
	           .moveTo(0, 0)
	           .lineTo( -10*symbolSize.fcr.dlzArrow, -8*symbolSize.fcr.dlzArrow)
	           .setColor(colorLine3)
	           .set("z-index",1)
	           .setStrokeLineWidth(me.dlzLW);
	        me.az1 = me.p_RDR.createChild("path")
	           .moveTo(0, 0)
	           .lineTo(0, -displayHeight)
	           .setColor(colorLine1)
	           .set("z-index",13)
	           .setStrokeLineWidth(lineWidth.fcr.azimuthLine);
	        me.az2 = me.p_RDR.createChild("path")
	           .moveTo(0, 0)
	           .lineTo(0, -displayHeight)
	           .setColor(colorLine1)
	           .set("z-index",13)
	           .setStrokeLineWidth(lineWidth.fcr.azimuthLine);
	        me.horiz = me.p_RDR.createChild("path")
	           .moveTo(-displayWidthHalf*0.5, -displayHeight*0.5)
	           .vert(symbolSize.fcr.horizLine)
	           .moveTo(-displayWidthHalf*0.5, -displayHeight*0.5)
	           .horiz(displayWidthHalf*0.4)
	           .moveTo(displayWidthHalf*0.5, -displayHeight*0.5)
	           .vert(symbolSize.fcr.horizLine)
	           .moveTo(displayWidthHalf*0.5, -displayHeight*0.5)
	           .horiz(-displayWidthHalf*0.4)
	           .setCenter(0, -displayHeight*0.5)
	           .setColor(colorLine2)
	           .set("z-index",15)
	           .setStrokeLineWidth(lineWidth.fcr.horizLine);
	        me.silent = me.p_RDR.createChild("text")
	           .setTranslation(0, -displayHeight*0.25)
	           .setAlignment("center-center")
	           .setText("SILENT")
	           .set("z-index",16)
	           .setFontSize(18, 1.0)
	           .setColor(colorText2);
	        me.bitText = me.p_RDR.createChild("text")
	           .setTranslation(0, -displayHeight*0.75)
	           .setAlignment("center-center")
	           .setText("    VERSION C021-IPOO-MRO3258674  ")
	           .set("z-index",16)
	           .setFontSize(18, 1.0)
	           .setColor(colorText2);

	        me.exp = me.p_RDR.createChild("path")
	            .moveTo(-100,-100)
	            .vert(200)
	            .horiz(200)
	            .vert(-200)
	            .horiz(-200)
	            .setStrokeLineWidth(lineWidth.fcr.exp)
	            .setColor(colorLine4)
	            .set("z-index",1)
	            .hide();

	        me.cursor = me.p_RDR.createChild("group").set("z-index",1000);
	        me.cursorAir = me.cursor.createChild("path")
	                    .moveTo(-symbolSize.fcr.cursorAir,-symbolSize.fcr.cursorAir)
	                    .vert(2*symbolSize.fcr.cursorAir)
	                    .moveTo(symbolSize.fcr.cursorAir,-symbolSize.fcr.cursorAir)
	                    .vert(2*symbolSize.fcr.cursorAir)
	                    .setStrokeLineWidth(lineWidth.fcr.cursorAir)
	                    .setColor(colorLine3);
	        me.cursorGm = me.cursor.createChild("path")
	                    .moveTo(0, symbolSize.fcr.cursorGMGap)
	                    .vert(500)
	                    .moveTo(0, -symbolSize.fcr.cursorGMGap)
	                    .vert(-500)
	                    .moveTo(symbolSize.fcr.cursorGMGap,0)
	                    .horiz(500)
	                    .moveTo(-symbolSize.fcr.cursorGMGap,0)
	                    .horiz(-500)
	                    .setStrokeLineWidth(lineWidth.fcr.cursorGnd)
	                    .setColor(colorLine3);
	        me.cursorGmTicks = me.cursor.createChild("path")
	                    .moveTo(symbolSize.fcr.cursorGMtickDist, symbolSize.fcr.cursorGMtick)
	                    .vert(-symbolSize.fcr.cursorGMtick*2)
	                    .moveTo(-symbolSize.fcr.cursorGMtickDist, symbolSize.fcr.cursorGMtick)
	                    .vert(-symbolSize.fcr.cursorGMtick*2)
	                    .moveTo(symbolSize.fcr.cursorGMtick,symbolSize.fcr.cursorGMtickDist)
	                    .horiz(-symbolSize.fcr.cursorGMtick*2)
	                    .moveTo(symbolSize.fcr.cursorGMtick,-symbolSize.fcr.cursorGMtickDist)
	                    .horiz(-symbolSize.fcr.cursorGMtick*2)
	                    .setStrokeLineWidth(lineWidth.fcr.cursorGnd)
	                    .setColor(colorLine3);
	        me.cursor_1 = me.cursor.createChild("text")
	                .setTranslation(10,-5)
	                .setText("37")
	                .setAlignment("left-bottom")
	                .setColor(colorLine3)
	                .setFontSize(18, 1.0);
	        me.cursor_2 = me.cursor.createChild("text")
	                .setTranslation(10, 5)
	                .setText("12")
	                .setAlignment("left-top")
	                .setColor(colorLine3)
	                .setFontSize(18, 1.0);

	        me.bullseye = me.p_RDR.createChild("path")
	            .moveTo(-25*symbolSize.fcr.bullseye,0)
	            .arcSmallCW(25*symbolSize.fcr.bullseye,25*symbolSize.fcr.bullseye, 0,  25*2*symbolSize.fcr.bullseye, 0)
	            .arcSmallCW(25*symbolSize.fcr.bullseye,25*symbolSize.fcr.bullseye, 0, -25*2*symbolSize.fcr.bullseye, 0)
	            .moveTo(-15*symbolSize.fcr.bullseye,0)
	            .arcSmallCW(15*symbolSize.fcr.bullseye,15*symbolSize.fcr.bullseye, 0,  15*2*symbolSize.fcr.bullseye, 0)
	            .arcSmallCW(15*symbolSize.fcr.bullseye,15*symbolSize.fcr.bullseye, 0, -15*2*symbolSize.fcr.bullseye, 0)
	            .moveTo(-5*symbolSize.fcr.bullseye,0)
	            .arcSmallCW(5*symbolSize.fcr.bullseye,5*symbolSize.fcr.bullseye, 0,  5*2*symbolSize.fcr.bullseye, 0)
	            .arcSmallCW(5*symbolSize.fcr.bullseye,5*symbolSize.fcr.bullseye, 0, -5*2*symbolSize.fcr.bullseye, 0)
	            .setStrokeLineWidth(lineWidth.fcr.bullseye)
	            .set("z-index",1)
	            .setColor(colorBullseye);
	        me.steerpoint = me.p_RDR.createChild("path")
	            .moveTo(12*symbolSize.fcr.steerpoint,8*symbolSize.fcr.steerpoint)
	            .horiz(-24*symbolSize.fcr.steerpoint)
	            .vert(-8*symbolSize.fcr.steerpoint)
	            .horiz(8*symbolSize.fcr.steerpoint)
	            .vert(-8*symbolSize.fcr.steerpoint)
	            .horiz(8*symbolSize.fcr.steerpoint)
	            .vert(8*symbolSize.fcr.steerpoint)
	            .horiz(8*symbolSize.fcr.steerpoint)
	            .vert(8*symbolSize.fcr.steerpoint)
	            .setColorFill(colorBullseye)
	            .setStrokeLineWidth(lineWidth.fcr.steerpoint)
	            .set("z-index",1)
	            .setColor(colorBullseye);
	        
	        me.cursorLoc = me.p_RDR.createChild("text")
	                .setAlignment("left-bottom")
	                .setColor(colorBetxt)
	                .setTranslation(-displayWidthHalf*0.95, -displayHeight*0.15)
	                .setText("12")
	                .set("z-index",1)
	                .setFontSize(18, 1.0);

	        # canvas: displayWidth,displayHeight
	        me.cosi = math.cos(30*D2R);
	        me.sinu = math.sin(30*D2R);
	        me.rangeRingLow = me.p_RDR.createChild("path")
	            .moveTo(-displayWidth*0.25*me.cosi,-displayHeight*0.25*me.sinu)
	            .arcSmallCW(displayWidth*0.25,displayHeight*0.25, 0, displayWidth*0.25*me.cosi*2, 0)
	            .setStrokeLineWidth(lineWidth.fcr.rangeRings)
	            .set("z-index",1)
	            .setColor(colorLines);
	        me.rangeRingMid = me.p_RDR.createChild("path")
	            .moveTo(-displayWidth*0.5*me.cosi,-displayHeight*0.5*me.sinu)
	            .arcSmallCW(displayWidth*0.5,displayHeight*0.5, 0, displayWidth*0.5*me.cosi*2, 0)
	            .setStrokeLineWidth(lineWidth.fcr.rangeRings)
	            .set("z-index",1)
	            .setColor(colorLines);
	        me.rangeRingHigh = me.p_RDR.createChild("path")
	            .moveTo(-displayWidth*0.75*me.cosi,-displayHeight*0.75*me.sinu)
	            .arcSmallCW(displayWidth*0.75,displayHeight*0.75, 0, displayWidth*0.75*me.cosi*2, 0)
	            .setStrokeLineWidth(lineWidth.fcr.rangeRings)
	            .set("z-index",1)
	            .setColor(colorLines);
	    },
		enter: func {
			printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = 0;
			}
			me.device.resetControls();						
			me.device.controls["OSB6"].setControlText("CONT");
			me.device.controls["OSB9"].setControlText("C\nZ");
			me.device.controls["OSB15"].setControlText("CNTL");
			me.device.controls["OSB16"].setControlText("SWAP");
			me.device.controls["OSB17"].setControlText("HSD");
			me.device.controls["OSB18"].setControlText("SMS");
			me.device.controls["OSB19"].setControlText("WPN");
			me.device.controls["OSB20"].setControlText("TGP");
			me.device.system.fetchLayer("OSB1TO2ARROWS").init(me, me.getOSB1TO2ARROWS);
		},
		getOSB1TO2ARROWS: func {
			return [me.rangeVis, me.rangeText, me.showRangeDown, me.showRangeUp];
		},
		controlAction: func (controlName) {
			printDebug(me.name,": ",controlName," activated on ",me.device.name);
			if (controlName == "OSB1") {
				if (fcrFrz) return;
                radar_system.apg68Radar.increaseRange();
            } elsif (controlName == "OSB2") {
            	if (fcrFrz) return;
                radar_system.apg68Radar.decreaseRange();
            } elsif (controlName == "OSB7") {
                #fcrFrz = !fcrFrz;
            } elsif (controlName == "OSB13") {
            	if (fcrFrz) return;
                me.pressEXP = 1;
            } elsif (controlName == "OSB12") {
            	if (fcrFrz) return;
                if (!radar_system.apg68Radar.currentMode.detectAIR) {
                    radar_system.apg68Radar.currentMode.toggleAuto();
                } else {
                    radar_system.apg68Radar.cycleMode();
                }
            } elsif (controlName == "OSB3") {
            	if (fcrFrz) return;
                radar_system.apg68Radar.cycleAZ();
            } elsif (controlName == "OSB4") {
            	if (fcrFrz) return;
                radar_system.apg68Radar.cycleBars();
            } elsif (controlName == "OSB9") {
            	if (fcrFrz) return;
                cursorZero();
            } elsif (controlName == "OSB10") {
            	if (fcrFrz) return;
                #if (rdrMode != RADAR_MODE_GM) return;
                #setprop("instrumentation/radar/mode-hd-switch", me.model_index);
            } elsif (controlName == "OSB16") {
				me.device.swap();
            } elsif (controlName == "OSB20") {
                switchTGP();
            }
		},
		update: func (noti) {
            me.p_RDR_image.setVisible(radar_system.apg68Radar.enabled and radar_system.apg68Radar.currentMode.mapper);
            me.DGFT = noti.getproper("dgft");
            me.device.DGFT = me.DGFT;
            me.IMSOI = me.device.soi == 1;
			
            me.modeSw = noti.getproper("rdrMode");

            setprop("instrumentation/radar/mode-switch", 0);

            me.modeSwHD = noti.getproper("rdrHD");

            me.device.controls["OSB6"].setControlText("CONT", 1, size(datalink.get_connected_indices()));
            me.device.controls["OSB12"].setControlText(radar_system.apg68Radar.currentMode.shortName);
            me.device.controls["OSB11"].setControlText(radar_system.apg68Radar.currentMode.rootName, 0);

            #
            # GM range rings
            #
            if (!radar_system.apg68Radar.currentMode.detectAIR and !exp) {
                me.rangeRingHigh.setVisible(radar_system.apg68Radar.getRange()>10);
                me.rangeRingMid.setVisible(radar_system.apg68Radar.getRange()>5);
                me.rangeRingLow.setVisible(radar_system.apg68Radar.getRange()>10);
            } else {
                me.rangeRingHigh.hide();
                me.rangeRingMid.hide();
                me.rangeRingLow.hide();
            }

            #
            # Bulls-eye info on FCR
            #
            me.bullPt = steerpoints.getNumber(steerpoints.index_of_bullseye);
            me.bullOn = me.bullPt != nil;
            if (me.bullOn) {
                me.bullLat = me.bullPt.lat;
                me.bullLon = me.bullPt.lon;
                me.bullCoord = geo.Coord.new().set_latlon(me.bullLat,me.bullLon);
                me.ownCoord = geo.aircraft_position();
                me.bullDirToMe = me.bullCoord.course_to(me.ownCoord);
                me.meToBull = ((me.bullDirToMe+180)-noti.getproper("heading"))*D2R;
                me.bullDistToMe = me.bullCoord.distance_to(me.ownCoord)*M2NM;
                me.distPixels = me.bullDistToMe*(displayHeight/radar_system.apg68Radar.getRange());
                me.bullPos = me.calcPos(me.wdt, geo.normdeg180(me.meToBull*R2D), me.distPixels);
            }

            #me.device.controls["OSB7"].setControlText("FRZ", 1, fcrFrz);

            if (fcrFrz) return;

            if (systime() - iff.last_interogate < 3.5) {
                # IFF ongoing
                me.device.controls["OSB5"].setControlText("M4",1,0);
            } else {
                me.device.controls["OSB5"].setControlText("M",1,0);
            }
            me.showExp = 0;
            if (me.DGFT or !radar_system.apg68Radar.currentMode.EXPsupport or (radar_system.apg68Radar.getPriorityTarget() != nil and radar_system.apg68Radar.currentMode.EXPfixedAim)) {
                exp = 0;
            } elsif (me.pressEXP) {
                me.pressEXP = 0;
                exp = !exp;
                me.showExp = 1;
            } else {
                me.showExp = 1;
            }            
            if (exp and radar_system.apg68Radar.currentMode.longName == radar_system.gmMode.longName) {
                me.cursorDev   = -math.atan2(-cursor_pos[0]/(displayHeight), -cursor_pos[1]/displayHeight)*R2D;
                me.cursorDist  = (math.sqrt(cursor_pos[0]*cursor_pos[0]+cursor_pos[1]*cursor_pos[1])/(displayHeight/radar_system.apg68Radar.getRange()));
                radar_system.apg68Radar.currentMode.setExp(1);
                radar_system.apg68Radar.currentMode.setExpPosition(me.cursorDev, me.cursorDist);
            } elsif (radar_system.apg68Radar.currentMode.longName == radar_system.gmMode.longName) {
                radar_system.apg68Radar.currentMode.setExp(0);
            }
            if (exp) {
                me.device.controls["OSB13"].setControlText(me.showExp?"EXP":"");
                me.exp.setTranslation(cursor_pos);
            } else {
                me.device.controls["OSB13"].setControlText(me.showExp?"NORM":"");
            }
            me.exp_zoom = exp;# should really be the only variable for this
            me.exp.setVisible(exp and !radar_system.apg68Radar.currentMode.EXPfixedAim);
#            me.acm.setVisible(1);
            me.horiz.setRotation(-radar_system.self.getRoll()*D2R);
            me.horiz.setTranslation(0, -displayHeightHalf*math.clamp(radar_system.self.getPitch()/60,-1,1));# As per manual

            if (radar_system.apg68Radar.currentMode.longName == radar_system.vsMode.longName) {
                me.distl.setScale(-1,1);
            } else {
                me.distl.setScale( 1,1);
            }
            me.distl.show();

            if (radar_system.apg68Radar.enabled) {
                if (1) {
                    # radar carets

                    me.caretPosition = radar_system.apg68Radar.getCaretPosition();
                    me.ant_bottom.setTranslation(me.caretPosition[0]*me.wdt*0.5,0);
                    me.ant_side.setTranslation(0,-me.caretPosition[1]*displayHeight*0.5);

                    me.ant_bottom.show();
                    me.ant_side.show();
                } else {
                    me.ant_bottom.hide();
                    me.ant_side.hide();
                }
                me.silent.hide();
            } elsif (noti.getproper("fcrBit") == 2) {
                me.silent.setText("SILENT");
                me.silent.setVisible(!getprop("/fdm/jsbsim/gear/unit[0]/WOW") or !getprop("instrumentation/radar/radar-enable"));
            } elsif (noti.getproper("fcrBit") == 1) {
                me.fcrBITsecs = (1.0-noti.getproper("fcrWarm"))*120;
                me.silent.setText(sprintf("  BIT TIME REMAINING IS %-3d SEC", me.fcrBITsecs));
                me.silent.show();
            } elsif (noti.getproper("fcrBit") == 0) {
                me.silent.setText("  OFF  ");
                me.silent.show();
            }

            if (noti.getproper("fcrBit") == 1) {
                me.silent.setTranslation(0, -displayHeight*0.825);
                me.bitText.show();
            } else {
                me.silent.setTranslation(0, -displayHeight*0.25);
                me.bitText.hide();
            }

            me.exp_modi = exp?(radar_system.apg68Radar.currentMode.EXPfixedAim?0.20:0.25):1.00;# slow down cursor movement when in zoom mode

            # Get controls from pilots cursor hat:
            me.slew_x = getprop("controls/displays/target-management-switch-x[" ~ me.model_index ~ "]")*me.exp_modi;
            me.slew_y = -getprop("controls/displays/target-management-switch-y[" ~ me.model_index ~ "]")*me.exp_modi;

            if (noti.getproper("viewName") != "TGP" and me.IMSOI) {
                f16.resetSlew();
            }

            #me.dt = math.min(noti.getproper("elapsed") - me.elapsed, 0.05);
            me.dt = noti.getproper("elapsed") - me.elapsed;

            if (me.IMSOI) {
            	# Move cursor and record clicks
                if ((me.slew_x != 0 or me.slew_y != 0 or slew_c != 0) and (cursor_lock == -1 or cursor_lock == me.index) and noti.getproper("viewName") != "TGP") {
                    cursor_pos[0] += me.slew_x*175;
                    cursor_pos[1] -= me.slew_y*175;
                    cursor_pos[0] = math.clamp(cursor_pos[0], -displayWidthHalf, displayWidthHalf);
                    cursor_pos[1] = math.clamp(cursor_pos[1], -displayHeight, 0);
                    cursor_click = (slew_c and !me.slew_c_last)?me.index:-1;
                    cursor_lock = me.index;
                } elsif (cursor_lock == me.index or (me.slew_x == 0 or me.slew_y == 0 or slew_c == 0)) {
                    cursor_lock = -1;
                }

                me.slew_c_last = slew_c;
                slew_c = 0;
            }

            me.elapsed = noti.getproper("elapsed");

            # Send cursor pos to radar system
            if (radar_system.apg68Radar.currentMode.detectAIR) {
                radar_system.apg68Radar.setCursorDeviation(cursor_pos[0]*60/(me.wdt*0.5));

                if (radar_system.apg68Radar.setCursorDistance(-cursor_pos[1]/(displayHeight/radar_system.apg68Radar.getRange()))) {
                    # the cursor was Y centered due to changing range
                    cursor_pos[1] = -displayHeight*0.5;
                    radar_system.apg68Radar.setCursorDistance(-cursor_pos[1]/(displayHeight/radar_system.apg68Radar.getRange()))
                }
            } else {
                radar_system.apg68Radar.setCursorDeviation(-math.atan2(-cursor_pos[0]/(displayHeight), -cursor_pos[1]/displayHeight)*R2D);

                # The real range not used since its only for giving cursor limits (not used in GM) and we want linear switching range:
                #  if (radar_system.apg68Radar.setCursorDistance((math.sqrt(cursor_pos[0]*cursor_pos[0]+cursor_pos[1]*cursor_pos[1])/(displayHeight/radar_system.apg68Radar.getRange())))) {
                if (radar_system.apg68Radar.setCursorDistance(-cursor_pos[1]/(displayHeight/radar_system.apg68Radar.getRange()))) {
                    # the cursor was Y centered due to changing range
                    cursor_pos[1] = -displayHeight*0.5;
                    radar_system.apg68Radar.setCursorDistance(-cursor_pos[1]/(displayHeight/radar_system.apg68Radar.getRange()))
                }
            }
            me.fixedEXPwidth = nil;
            var pixelPerNM = nil;

            # Paint cursor
            if (!exp or !radar_system.apg68Radar.currentMode.EXPfixedAim) {
                me.cursor.setTranslation(cursor_pos);
            } else {
                me.cursor.setTranslation([0,-displayHeight*0.5]);
                me.fixedEXPwidth = radar_system.apg68Radar.currentMode.getEXPsize();
                pixelPerNM = displayHeight/radar_system.apg68Radar.getRange();
            }
            me.alimits = radar_system.apg68Radar.getCursorAltitudeLimits();
            if (me.alimits != nil and radar_system.apg68Radar.currentMode.detectAIR) {
                me.cursor_1.setText(sprintf("% 2d",math.round(me.alimits[0]*0.001)));
                me.cursor_2.setText(sprintf("% 2d",math.round(me.alimits[1]*0.001)));
                if (me.alimits[0] >= 0) {
                    me.cursor_1.setColor(colorLine3);
                } else {
                    me.cursor_1.setColor(colorCircle1);
                }
                if (me.alimits[1] >= 0) {
                    me.cursor_2.setColor(colorLine3);
                } else {
                    me.cursor_2.setColor(colorCircle1);
                }
            } else {
                me.cursor_1.setText("");
                me.cursor_2.setText("");
            }
            me.cursorAir.setVisible(radar_system.apg68Radar.currentMode.detectAIR);
            me.cursorGm.setVisible(!radar_system.apg68Radar.currentMode.detectAIR);
            me.cursorGmTicks.setVisible(!radar_system.apg68Radar.currentMode.detectAIR and !exp);

            if (radar_system.apg68Radar.currentMode.detectAIR) {
            	# Find cursor position for bullseye location from cursor
                me.cursorDev   = cursor_pos[0]*60/(me.wdt*0.5);
                me.cursorDist  = -cursor_pos[1]/(displayHeight/radar_system.apg68Radar.getRange());
                cursorFCRair = 1;
            } else {
            	# Find cursor position for bullseye location from GM cursor
                # TODO: verify this is correct:
                me.cursorDev   = -math.atan2(-cursor_pos[0]/(displayHeight), -cursor_pos[1]/displayHeight)*R2D;
                me.cursorDist  = (math.sqrt(cursor_pos[0]*cursor_pos[0]+cursor_pos[1]*cursor_pos[1])/(displayHeight/radar_system.apg68Radar.getRange()));
                cursorFCRair = 0;
            }
            cursorFCRgps = [me.cursorDev, me.cursorDist];# Used by HSD also
            if (me.bullOn) {
                me.ownCoord.apply_course_distance(noti.getproper("heading")+me.cursorDev, me.cursorDist);
                me.cursorBullDist = me.ownCoord.distance_to(me.bullCoord);
                me.cursorBullCrs  = me.bullCoord.course_to(me.ownCoord);
                me.cursorLoc.setText(sprintf("%03d %03d",me.cursorBullCrs, me.cursorBullDist*M2NM));
            }
            me.cursorLoc.setVisible(me.bullOn);



            me.az1.setVisible(radar_system.apg68Radar.showAZ());
            me.az2.setVisible(radar_system.apg68Radar.showAZ());
            me.device.controls["OSB4"].setControlText(radar_system.apg68Radar.currentMode.showBars()?(radar_system.apg68Radar.getBars()~"\nB"):"",1,0);
            if (noti.FrameCount != 1 and noti.FrameCount != 3)
                return;
            me.rangeText = sprintf("%d",radar_system.apg68Radar.getRange());
            me.rangeVis  = radar_system.apg68Radar.currentMode.longName != radar_system.vsMode.longName;
            me.i=0;

            var a = 0;
            if (radar_system.apg68Radar.getAzimuthRadius() < 20) {
                a = 1;
            } elsif (radar_system.apg68Radar.getAzimuthRadius() < 30) {
                a = 2;
            } elsif (radar_system.apg68Radar.getAzimuthRadius() < 40) {
                a = 3;
            } elsif (radar_system.apg68Radar.getAzimuthRadius() < 50) {
                a = 4;
            } elsif (radar_system.apg68Radar.getAzimuthRadius() < 60) {
                a = 5;
            } elsif (radar_system.apg68Radar.getAzimuthRadius() < 70) {
                a = 6;
            }

            me.device.controls["OSB3"].setControlText("A\n"~a,1,0);

            if (radar_system.apg68Radar.currentMode.detectAIR) {
                me.az1.setTranslation((radar_system.apg68Radar.currentMode.azimuthTilt-radar_system.apg68Radar.currentMode.az)*me.wdt*0.5/60,0);
                me.az2.setTranslation((radar_system.apg68Radar.currentMode.azimuthTilt+radar_system.apg68Radar.currentMode.az)*me.wdt*0.5/60,0);
                me.az1.setRotation(0);
                me.az2.setRotation(0);
            } else {
                me.az1.setTranslation(0, 0);
                me.az2.setTranslation(0, 0);
                var angle2 = D2R*(radar_system.apg68Radar.currentMode.azimuthTilt+radar_system.apg68Radar.currentMode.az);
                var angle1 = D2R*(radar_system.apg68Radar.currentMode.azimuthTilt-radar_system.apg68Radar.currentMode.az);
                me.az1.setRotation(angle2);
                me.az2.setRotation(angle1);
            }
            #me.lock.hide();
            #me.lockGM.hide();


            # The distance in pixels from cursor that stuff should be zoomed
            if (me.fixedEXPwidth != nil) {
                me.closeDef = pixelPerNM*me.fixedEXPwidth*0.5;
            } else {
                me.closeDef = 25; # pixels radius
            }

            #
            # Bulls-eye position on FCR
            #
            if (me.bullOn) {
                me.bullPos = me.calcEXPPos(me.bullPos);
                if (me.bullPos == nil) {
                    me.bullOn = 0;
                }
            }
            me.bullseye.setVisible(me.bullOn);
            if (me.bullOn) {
                me.bullseye.setTranslation(me.bullPos);
            }

            #
            # Current steerpoint on FCR
            #
            if (steerpoints.getCurrentNumber() != 0) {
                me.wpC = steerpoints.getCurrentCoord();
                if (me.wpC == nil) {
                    printf("Error occured in FCR steerpoint system: STPT:%d WAYP:%d NUM:%d - please report this error to F16 devs:",steerpoints.getCurrentNumber(),noti.getproper("currentWP"),noti.getproper("maxWP"));
                }
                me.legBearing = geo.normdeg180(geo.aircraft_position().course_to(me.wpC)-noti.getproper("heading"));#relative
                me.legDistance = geo.aircraft_position().distance_to(me.wpC)*M2NM;
                me.distPixels = me.legDistance*(displayHeight/radar_system.apg68Radar.getRange());
                me.steerPos = me.calcPos(me.wdt, me.legBearing, me.distPixels);
                var vis = 1;
                me.steerPos = me.calcEXPPos(me.steerPos);
                if (me.steerPos == nil) {
                    vis = 0;
                } else {
                    me.steerpoint.setTranslation(me.steerPos);
                }
                me.steerpoint.setVisible(vis);
            } else {
                me.steerpoint.setVisible(0);
            }



#  ██████   █████  ██████   █████  ██████      ██████  ██      ███████ ██████  ███████ 
#  ██   ██ ██   ██ ██   ██ ██   ██ ██   ██     ██   ██ ██      ██      ██   ██ ██      
#  ██████  ███████ ██   ██ ███████ ██████      ██████  ██      █████   ██████  ███████ 
#  ██   ██ ██   ██ ██   ██ ██   ██ ██   ██     ██   ██ ██      ██      ██           ██ 
#  ██   ██ ██   ██ ██████  ██   ██ ██   ██     ██████  ███████ ███████ ██      ███████ 
#                                                                                      
#
            me.desig_new = nil;
            #me.gm_echoPos = {};
            me.ijk = 0;
            me.intercept = nil;
            me.showDLT = 0;
            me.prio = radar_system.apg68Radar.getPriorityTarget();
            me.tracks = [];
            me.elapsed = noti.getproper("elapsed");
            me.selectShow = 0;
            me.selectShowGM = 0;
            me.lockInfo = 0;
            me.i = 0;
            me.ii = 0;
            me.iii = 0;
            me.iiii = 0;

            me.randoo = rand();

            if (radar_system.datalink_power.getBoolValue() and radar_system.apg68Radar.currentMode.longName != radar_system.vsMode.longName and radar_system.apg68Radar.currentMode["painter"] != 1) {
                foreach(contact; vector_aicontacts_links) {
                    if (contact["blue"] != 1) continue;
                    me.paintDL(contact, noti);
                    contact.randoo = me.randoo;
                }
            }
            if (radar_system.apg68Radar.enabled) {
                if (!radar_system.apg68Radar.currentMode.painter) {
                    #me.wind = getprop("environment/wind-speed-kt");
                    #me.chaffLifetime = math.max(0, me.wind==0?25:25*(1-me.wind/50));
                    foreach(var chaff; radar_system.apg68Radar.getActiveChaff()) {
                        me.paintChaff(chaff);
                    }
                }
                foreach(contact; radar_system.apg68Radar.getActiveBleps()) {
                    if (contact["randoo"] == me.randoo) continue;

                    me.paintRdr(contact);
                    contact.randoo = me.randoo;
                }
            }
            if (radar_system.datalink_power.getBoolValue() and radar_system.apg68Radar.currentMode.longName != radar_system.vsMode.longName and !radar_system.apg68Radar.currentMode.painter) {
                foreach(contact; vector_aicontacts_links) {
                    me.paintRdr(contact);
                    contact.randoo = me.randoo;
                }
            }

            me.selection.setVisible(me.selectShow);
            me.selection.update();
            me.lockGM.setVisible(me.selectShowGM);
            me.lockGM.update();
            me.lockInfoCanvas.setVisible(me.lockInfo);
            for (;me.i < me.maxB;me.i+=1) {
                me.blep[me.i].hide();
            }
            for (;me.ii < me.maxT;me.ii+=1) {
                me.blepTriangle[me.ii].hide();
            }
            for (;me.iii < me.maxT;me.iii+=1) {
                me.lnk[me.iii].hide();
                me.lnkT[me.iii].hide();
                me.lnkTA[me.iii].hide();
            }
            for (;me.iiii < me.maxT;me.iiii+=1) {
                me.iff[me.iiii].hide();
                me.iffU[me.iiii].hide();
            }
            #
            # Intercept steering point for designated target
            #
            if (radar_system.apg68Radar.getPriorityTarget() != nil) {
                me.lastHead = radar_system.apg68Radar.getPriorityTarget().getLastHeading();
                if (me.lastHead != nil and radar_system.apg68Radar.getPriorityTarget().getType() == radar_system.AIR) {
                    # we cheat a bit here with getting current properties:
                    me.intercept = get_intercept(radar_system.apg68Radar.getPriorityTarget().get_bearing(),
                     radar_system.apg68Radar.getPriorityTarget().get_range()*NM2M, me.lastHead,
                      radar_system.apg68Radar.getPriorityTarget().get_Speed()*KT2MPS,
                       noti.getproper("groundspeed_kt")*KT2MPS, geo.aircraft_position(), radar_system.self.getHeading());
                }
            }
            if (me.intercept != nil) {
                me.interceptCoord = me.intercept[2];
                me.interceptDist = me.intercept[3];
                me.distPixels = me.interceptDist*M2NM*(displayHeight/radar_system.apg68Radar.getRange());
                me.echoPos = [me.wdt*0.5*geo.normdeg180(me.intercept[4])/60,-me.distPixels];
                me.interceptCross.setTranslation(me.echoPos);
                me.interceptCross.setVisible(1);
            } else {
                me.interceptCross.setVisible(0);
            }
            if (cursor_click == me.index) {
                if (me.desig_new == nil) {
                    radar_system.apg68Radar.undesignate();
                } else {
                    radar_system.apg68Radar.designate(me.desig_new);
                }
                cursor_click = -1;
            }


            #
            # The dynamic launch zone indicator on FCR
            #
            me.dlzArray = pylons.getDLZ();
            #me.dlzArray =[10,8,6,2,9];#test
            if (me.dlzArray == nil or size(me.dlzArray) == 0) {
                    me.dlz.hide();
            } else {
                #printf("%d %d %d %d %d",me.dlzArray[0],me.dlzArray[1],me.dlzArray[2],me.dlzArray[3],me.dlzArray[4]);
                me.dlz2.removeAllChildren();
                me.dlzArrow.setTranslation(0,-me.dlzArray[4]/me.dlzArray[0]*me.dlzHeight);
                me.dlzGeom = me.dlz2.createChild("path")
                        .moveTo(me.dlzWidth, 0)
                        .horiz(-me.dlzWidth)
                        .lineTo(0, -me.dlzArray[3]/me.dlzArray[0]*me.dlzHeight)
                        .moveTo(0, -me.dlzArray[3]/me.dlzArray[0]*me.dlzHeight)
                        .lineTo(0, -me.dlzArray[2]/me.dlzArray[0]*me.dlzHeight)
                        .lineTo(me.dlzWidth, -me.dlzArray[2]/me.dlzArray[0]*me.dlzHeight)
                        .lineTo(me.dlzWidth, -me.dlzArray[3]/me.dlzArray[0]*me.dlzHeight)
                        .lineTo(0, -me.dlzArray[3]/me.dlzArray[0]*me.dlzHeight)
                        .lineTo(0, -me.dlzArray[1]/me.dlzArray[0]*me.dlzHeight)
                        .lineTo(me.dlzWidth, -me.dlzArray[1]/me.dlzArray[0]*me.dlzHeight)
                        .moveTo(0, -me.dlzHeight)
                        .lineTo(me.dlzWidth, -me.dlzHeight-3)
                        .lineTo(me.dlzWidth, -me.dlzHeight+3)
                        .lineTo(0, -me.dlzHeight)
                        .setStrokeLineWidth(me.dlzLW)
                        .setColor(colorLine3);
                me.dlz2.update();
                me.dlz.show();
            }

            if (radar_system.apg68Radar.getRange() == radar_system.apg68Radar.currentMode.minRange or !radar_system.apg68Radar.currentMode.showRangeOptions()) {
                me.showRangeDown = 0;
            } else {
                me.showRangeDown = 1;
            }

            if (radar_system.apg68Radar.getRange() == radar_system.apg68Radar.currentMode.maxRange or !radar_system.apg68Radar.currentMode.showRangeOptions()) {
                me.showRangeUp = 0;
            } else {
                me.showRangeUp = 1;
            }

            if (radar_system.apg68Radar.currentMode.mapper) {
                if (me["gmImage"] == nil) {
                    #setprop("a",0.8732);
                    var sized = 64;# size of image
                    var scaled = displayWidth/sized;
                    me.gmImage = me.p_RDR_image.createChild("image")
                        .set("src", "Aircraft/f16/Nasal/MFD/gmSD0.png")# index is due to else the two MFD will share the underlying image and both write to it.
                        .setTranslation(-displayWidth*0.5,-displayHeight)
                        #.setCenter(sized*0.5, -sized)
                        .setScale(scaled,scaled)
                        .set("z-index",0);#TODO: lower than GM text background

                    me.mono = (variantID<2 or variantID ==3)?0.4:1;
                    me.gainNode = me.model_index?props.globals.getNode("f16/avionics/mfd-l-gain",0):props.globals.getNode("f16/avionics/mfd-l-gain",0);
                    radar_system.mapper.setImage(me.gmImage, sized*0.5, 0, sized, me.mono, me.gainNode);
                }
                #me.gmImage.setScale(8*1.078125*getprop("a"),8*0.9414).setTranslation(-552*0.5*getprop("a"),-displayHeight);

                me.gainGaugePointer.setTranslation(-displayWidth*0.5*0.85-symbolSize.fcr.gainGaugeHoriz,me.interpolate(me.gainNode.getValue(), 1.0, 2.5,-displayHeight*0.95+symbolSize.fcr.gainGaugeHoriz*0.5,-displayHeight*0.95-symbolSize.fcr.gainGaugeHoriz*0.5+symbolSize.fcr.gainGaugeVert));
                me.gainGaugePointer.show();
                me.gainGauge.show();
                me.gmImage.show();
            } elsif (me["gmImage"] != nil) {
                me.gmImage.hide();
                me.gainGaugePointer.hide();
                me.gainGauge.hide();
            } else {
                me.gainGaugePointer.hide();
                me.gainGauge.hide();
            }
        },
        interpolate: func (x, x1, x2, y1, y2) {
            return math.clamp(y1 + ((x - x1) / (x2 - x1)) * (y2 - y1),math.min(y1,y2),math.max(y1,y2));
        },


#  ██████   █████  ██ ███    ██ ████████     ██████  ██████  ██████      ██████  ██      ███████ ██████  ███████ 
#  ██   ██ ██   ██ ██ ████   ██    ██        ██   ██ ██   ██ ██   ██     ██   ██ ██      ██      ██   ██ ██      
#  ██████  ███████ ██ ██ ██  ██    ██        ██████  ██   ██ ██████      ██████  ██      █████   ██████  ███████ 
#  ██      ██   ██ ██ ██  ██ ██    ██        ██   ██ ██   ██ ██   ██     ██   ██ ██      ██      ██           ██ 
#  ██      ██   ██ ██ ██   ████    ██        ██   ██ ██████  ██   ██     ██████  ███████ ███████ ██      ███████ 
#                                                                                                                
#
        paintDL: func (contact, noti) {
            if (contact.blue != 1) return;
            if (contact["iff"] != nil) {
                if (contact.iff > 0 and me.elapsed-contact.iff < 3.5) {
                    me.iffState = 1;
                } elsif (contact.iff < 0 and me.elapsed+contact.iff < 3.5) {
                    me.iffState = -1;
                } else {
                    me.iffState = 0;
                }
            } else {
                me.iffState = 0;
            }

            me.blueBearing = geo.normdeg180(contact.getDeviationHeading());
            if (me.iffState == 0 and contact.isVisible() and contact.getRange()*M2NM < 80 and me.iii < me.maxT and math.abs(me.blueBearing) < 60) {
                me.distPixels = contact.get_range()*(displayHeight/(radar_system.apg68Radar.getRange()));
                me.echoPos = me.calcPos(me.wdt, geo.normdeg180(me.blueBearing), me.distPixels);
                me.echoPos = me.calcEXPPos(me.echoPos);
                if (me.echoPos == nil) {
                    return;
                }
                me.lnkT[me.iii].setColor(colorDot4);
                me.lnkT[me.iii].setTranslation(me.echoPos[0],me.echoPos[1]-25);
                me.lnkT[me.iii].setText(""~contact.blueIndex);
                me.lnkT[me.iii].show();
                me.lnkTA[me.iii].setColor(colorDot4);
                me.lnkTA[me.iii].setTranslation(me.echoPos[0],me.echoPos[1]+20);
                me.lnkTA[me.iii].setText(""~math.round(contact.getAltitude()*0.001));
                me.lnkTA[me.iii].show();
                me.lnk[me.iii].setColor(colorDot4);
                me.lnk[me.iii].setTranslation(me.echoPos);
                me.lnk[me.iii].setRotation(D2R*22.5*math.round( geo.normdeg(contact.get_heading()-noti.getproper("heading")-me.blueBearing)/22.5 ));#Show rotation in increments of 22.5 deg
                me.lnk[me.iii].show();
                me.lnk[me.iii].update();
                if (contact.equalsFast(radar_system.apg68Radar.getPriorityTarget())) {
                    me.selectShow = contact.getType() == radar_system.AIR;
                    me.selectShowGM = !me.selectShow;
                    me.selection.setTranslation(me.echoPos);
                    me.selection.setColor(colorDot4);
                    me.lockGM.setTranslation(me.echoPos);
                    me.lockGM.setColor(colorDot4);
                    me.printInfo(contact);
                }
                me.calcClick(contact, me.echoPos);
                me.iii += 1;
            } elsif (me.iffState != 0 and contact.isVisible() and me.iiii < me.maxT and math.abs(me.blueBearing) < 60) {
                me.distPixels = contact.get_range()*(displayHeight/(radar_system.apg68Radar.getRange()));
                me.echoPos = me.calcPos(me.wdt, geo.normdeg180(me.blueBearing), me.distPixels);
                me.echoPos = me.calcEXPPos(me.echoPos);
                if (me.echoPos == nil) {
                    return;
                }
                me.path = me.iffState == -1?me.iffU[me.iiii]:me.iff[me.iiii];
                me.pathHide = me.iffState == 1?me.iffU[me.iiii]:me.iff[me.iiii];
                me.pathHide.hide();
                me.path.setTranslation(me.echoPos[0],me.echoPos[1]-18);
                me.path.show();

                me.iiii += 1;
            }
        },
        calcPos: func (width, dev, distPixels) {
            if (radar_system.apg68Radar.currentMode.detectAIR) {
                # B-Scope
                me.echoPosition = [width*0.5*dev/60,-distPixels];
            } else {
                # PPI-Scope
                me.echoPosition = [(displayWidth)*(distPixels/displayHeight)*math.sin(D2R*dev), -distPixels*math.cos(D2R*dev)];
            }
            return me.echoPosition;
        },
        calcEXPPos: func (itemPos) {
            # Calculate the position taking EXP zoom into account
            var returnPos = itemPos;
            var cursorCentre = [0,-displayHeight*0.5];
            me.close = math.abs(cursor_pos[0] - itemPos[0]) < me.closeDef and math.abs(cursor_pos[1] - itemPos[1]) < me.closeDef;
            if (me.close and me.exp_zoom) {
                if (me.fixedEXPwidth != nil) {
                    # EXP with fixed cursor
                    returnPos[0] = cursorCentre[0]+math.abs(cursorCentre[1])*(itemPos[0] - cursor_pos[0])/me.closeDef;
                    returnPos[1] = cursorCentre[1]+math.abs(cursorCentre[1])*(itemPos[1] - cursor_pos[1])/me.closeDef;
                } else {
                    # EXP with moving cursor
                    returnPos[0] = cursor_pos[0]+(itemPos[0] - cursor_pos[0])*4;
                    returnPos[1] = cursor_pos[1]+(itemPos[1] - cursor_pos[1])*4;
                }
            } elsif (me.exp_zoom and (me.fixedEXPwidth != nil or math.abs(cursor_pos[0] - itemPos[0]) < 100 and math.abs(cursor_pos[1] - itemPos[1]) < 100)) {
            	# The 100 pixels here is the radius of the EXP square
                returnPos = nil;
            }
            return returnPos;
        },
        calcClick: func (contact, echoPos) {
            if (cursor_click == me.index) {
                var cursor_posi = !me.exp_zoom or me.fixedEXPwidth == nil?cursor_pos:[0,-displayHeight*0.5];
                if (math.abs(cursor_posi[0] - echoPos[0]) < 10 and math.abs(cursor_posi[1] - echoPos[1]) < 11) {
                    me.desig_new = contact;
                }
            }
        },
        printInfo: func (contact) {
            if (contact.getLastHeading() != nil) {
                me.azimuth = math.round(geo.normdeg180(contact.get_bearing()-contact.getLastHeading())*0.1)*10;
                if (me.azimuth == 180 or me.azimuth == 0) {
                    me.azSide = " ";
                } else {
                    me.azSide = me.azimuth > 0 ?"L":"R";
                }
                me.azimuth = sprintf("%3d%s", math.abs(me.azimuth), me.azSide);
                me.magn = geo.normdeg(contact.getLastHeading()+radar_system.self.getHeadingMag()-radar_system.self.getHeading());
                me.heady = sprintf("%3d", int(me.magn/10)*10);
            } else {
                me.azimuth = "    ";
                me.heady = "   ";
            }
            if (contact.getLastClosureRate() != 0) {
                me.clos = sprintf("%+4dK",math.round(contact.getLastClosureRate()*0.1)*10);
            } else {
                me.clos = "      ";
            }

            me.lockInfoText = sprintf("%s    %s          %4d   %s", me.azimuth, me.heady, contact.get_Speed(), me.clos);

            me.lockInfoCanvas.setText(me.lockInfoText);
            me.lockInfo = 1;
        },
        paintRdr: func (contact) {
            if (contact["iff"] != nil) {
                if (contact.iff > 0 and me.elapsed-contact.iff < 3.5) {
                    me.iffState = 1;
                } elsif (contact.iff < 0 and me.elapsed+contact.iff < 3.5) {
                    me.iffState = -1;
                } else {
                    me.iffState = 0;
                }
            } else {
                me.iffState = 0;
            }
            me.bleps = contact.getBleps();
            foreach(me.bleppy ; me.bleps) {
                if (me.i < me.maxB and me.elapsed - me.bleppy.getBlepTime() < radar_system.apg68Radar.currentMode.timeToFadeBleps and me.bleppy.getDirection() != nil and (radar_system.apg68Radar.currentMode.longName != radar_system.vsMode.longName or (me.bleppy.getClosureRate() != nil and me.bleppy.getClosureRate()>0))) {
                    if (me.bleppy.getClosureRate() != nil and radar_system.apg68Radar.currentMode.longName == radar_system.vsMode.longName) {
                        me.distPixels = math.min(950, me.bleppy.getClosureRate())*(displayHeight/(1000));
                    } else {
                        me.distPixels = me.bleppy.getRangeNow()*(displayHeight/(radar_system.apg68Radar.getRange()*NM2M));
                    }
                    me.echoPos = me.calcPos(me.wdt, geo.normdeg180(me.bleppy.getAZDeviation()), me.distPixels);
                    me.echoPos = me.calcEXPPos(me.echoPos);
                    if (me.echoPos == nil) {
                        continue;
                    }
                    me.color = math.pow(1-(me.elapsed - me.bleppy.getBlepTime())/radar_system.apg68Radar.currentMode.timeToFadeBleps, 2.2);
                    me.blep[me.i].setTranslation(me.echoPos);
                    me.blep[me.i].setColor(colorDot2[0]*me.color+colorBackground[0]*(1-me.color), colorDot2[1]*me.color+colorBackground[1]*(1-me.color), colorDot2[2]*me.color+colorBackground[2]*(1-me.color));
                    me.blep[me.i].show();
                    me.blep[me.i].update();
                    if (contact.equalsFast(radar_system.apg68Radar.getPriorityTarget()) and me.bleppy == me.bleps[-1]) {
                        me.selectShowTemp = radar_system.apg68Radar.currentMode.longName != radar_system.twsMode.longName or (me.elapsed - contact.getLastBlepTime() < radar_system.F16TWSMode.timeToBlinkTracks) or (math.mod(me.elapsed,0.50)<0.25);
                        me.selectShow = me.selectShowTemp and contact.getType() == radar_system.AIR;
                        me.selectShowGM = me.selectShowTemp and contact.getType() != radar_system.AIR;
                        me.selection.setTranslation(me.echoPos);
                        me.selection.setColor(colorCircle2);
                        me.lockGM.setTranslation(me.echoPos);
                        me.lockGM.setColor(colorCircle2);
                        me.printInfo(contact);
                        me.lockInfo = 1;
                    }
                    if (me.elapsed - me.bleppy.getBlepTime() < radar_system.apg68Radar.currentMode.timeToFadeBleps) {
                        me.calcClick(contact, me.echoPos);
                    }
                    me.i += 1;
                }
            }
            me.sizeBleps = size(me.bleps);
            if (contact["blue"] != 1 and me.ii < me.maxT and ((me.sizeBleps and contact.hadTrackInfo()) or contact["blue"] == 2) and me.iffState == 0 and radar_system.apg68Radar.currentMode.longName != radar_system.vsMode.longName) {
                # Paint bleps with tracks
                if (contact["blue"] != 2) me.bleppy = me.bleps[-1];
                if (contact["blue"] == 2 or (me.bleppy.hasTrackInfo() and me.elapsed - me.bleppy.getBlepTime() < radar_system.apg68Radar.timeToKeepBleps)) {
                    me.color = contact["blue"] == 2?colorCircle1:colorCircle2;
                    if (contact["blue"] == 2) {
                        me.c_heading    = contact.getHeading();
                        me.c_devheading = contact.getDeviationHeading();
                        me.c_speed      = contact.getSpeed();
                        me.c_alt        = contact.getAltitude();
                        me.distPixels   = contact.getRange()*(displayHeight/(radar_system.apg68Radar.getRange()*NM2M));
                    } else {
                        me.c_heading    = me.bleppy.getHeading();
                        me.c_devheading = me.bleppy.getAZDeviation();
                        me.c_speed      = me.bleppy.getSpeed();
                        me.c_alt        = me.bleppy.getAltitude();
                        me.distPixels   = me.bleppy.getRangeNow()*(displayHeight/(radar_system.apg68Radar.getRange()*NM2M));
                    }
                    me.rot = 22.5*math.round((me.c_heading-radar_system.self.getHeading()-me.c_devheading)/22.5);
                    me.blepTrianglePaths[me.ii].setRotation(me.rot*D2R);
                    me.blepTrianglePaths[me.ii].setColor(me.color);
                    me.echoPos = me.calcPos(me.wdt, geo.normdeg180(me.c_devheading), me.distPixels);
                    me.echoPos = me.calcEXPPos(me.echoPos);
                    if (me.echoPos == nil) {
                        return;
                    }
                    if (contact["blue"] == 2 and me.iii < me.maxT) {
                        me.lnkT[me.iii].setColor(me.color);
                        me.lnkT[me.iii].setTranslation(me.echoPos[0],me.echoPos[1]-25);
                        me.lnkT[me.iii].setText(""~contact.blueIndex);
                        me.lnkT[me.iii].show();
                        me.iii += 1;
                    }
                    me.blepTriangle[me.ii].setTranslation(me.echoPos);
                    if (me.c_speed != nil and me.c_speed > 0) {
                        me.blepTriangleVelLine[me.ii].setScale(1,me.c_speed*symbolSize.fcr.contactVelocity);
                        me.blepTriangleVelLine[me.ii].setColor(me.color);
                        me.blepTriangleVel[me.ii].setRotation(me.rot*D2R);
                        me.blepTriangleVel[me.ii].update();
                        me.blepTriangleVel[me.ii].show();
                    } else {
                        me.blepTriangleVel[me.ii].hide();
                    }
                    if (me.c_alt != nil) {
                        me.blepTriangleText[me.ii].setText(""~math.round(me.c_alt*0.001));
                        me.blepTriangleText[me.ii].setColor(me.color);
                    } else {
                        me.blepTriangleText[me.ii].setText("");
                    }
                    me.blinkShow = radar_system.apg68Radar.currentMode.longName != radar_system.twsMode.longName or (me.elapsed - contact.getLastBlepTime() < radar_system.F16TWSMode.timeToBlinkTracks) or (math.mod(me.elapsed,0.50)<0.25);
                    if (contact.equalsFast(radar_system.apg68Radar.getPriorityTarget())) {
                        me.selectShow = me.blinkShow and contact.getType() == radar_system.AIR;
                        me.selectShowGM = me.blinkShow and contact.getType() != radar_system.AIR;
                        me.blepTriangle[me.ii].setVisible(me.selectShow);
                        me.selection.setTranslation(me.echoPos);
                        me.selection.setColor(me.color);
                        me.lockGM.setTranslation(me.echoPos);
                        me.lockGM.setColor(me.color);
                        me.printInfo(contact);
                        me.lockInfo = 1;
                    }
                    me.blepTriangle[me.ii].setVisible(me.blinkShow and contact.getType() == radar_system.AIR);
                    me.blepTriangle[me.ii].update();
                    me.calcClick(contact, me.echoPos);

                    me.ii += 1;
                }
            } elsif (me.iffState != 0 and contact["blue"] != 1 and contact.isVisible() and me.iiii < me.maxT and me.sizeBleps and radar_system.apg68Radar.currentMode.longName != radar_system.vsMode.longName) {
                # Paint IFF symbols
                me.bleppy = me.bleps[-1];
                if (me.elapsed - me.bleppy.getBlepTime() < radar_system.apg68Radar.timeToKeepBleps) {
                    me.echoPos = me.calcPos(me.wdt, geo.normdeg180(me.bleppy.getAZDeviation()), me.distPixels);
                    me.echoPos = me.calcEXPPos(me.echoPos);
                    if (me.echoPos == nil) {
                        return;
                    }
                    me.path = me.iffState == -1?me.iffU[me.iiii]:me.iff[me.iiii];
                    me.pathHide = me.iffState == 1?me.iffU[me.iiii]:me.iff[me.iiii];
                    me.pathHide.hide();
                    me.path.setTranslation(me.echoPos[0],me.echoPos[1]-18);
                    me.path.show();
                    me.iiii += 1;
                }
            }
        },
        paintChaff: func (chaff) {
            #if (me.chaffLifetime == 0) return;
            if (me.i < me.maxB and radar_system.apg68Radar.currentMode.longName != radar_system.vsMode.longName) {
                me.distPixels = chaff.meters*(displayHeight/(radar_system.apg68Radar.getRange()*NM2M));

                me.echoPos = me.calcPos(me.wdt, geo.normdeg180(chaff.bearing - radar_system.self.getHeading()), me.distPixels);
                me.echoPos = me.calcEXPPos(me.echoPos);
                if (me.echoPos == nil) {
                    return;
                }
                #me.color = math.pow(math.max(0, rand()-(me.elapsed - chaff.seenTime)/me.chaffLifetime), 2.2);
                me.color = math.pow(math.max(0, 0.8-(me.elapsed - chaff.seenTime)/radar_system.apg68Radar.currentMode.timeToFadeBleps), 2.2);

                if (chaff["rand1"] == nil) {
                    chaff.rand1 = rand();
                    chaff.rand2 = rand();
                    chaff.rand3 = rand();
                    chaff.rand4 = rand();
                }
                me.echoPos1 = [me.echoPos[0]+chaff.rand1*8-4, me.echoPos[1]-chaff.rand2*3];
                me.blep[me.i].setTranslation(me.echoPos1);
                me.blep[me.i].setColor(colorDot2[0]*me.color+colorBackground[0]*(1-me.color), colorDot2[1]*me.color+colorBackground[1]*(1-me.color), colorDot2[2]*me.color+colorBackground[2]*(1-me.color));
                me.blep[me.i].show();
                me.blep[me.i].update();

                me.i += 1;
                if (me.i < me.maxB) {
                    me.echoPos2 = [me.echoPos[0]+chaff.rand3*8-4, me.echoPos[1]-chaff.rand4*3];
                    me.blep[me.i].setTranslation(me.echoPos2);
                    me.blep[me.i].setColor(colorDot2[0]*me.color+colorBackground[0]*(1-me.color), colorDot2[1]*me.color+colorBackground[1]*(1-me.color), colorDot2[2]*me.color+colorBackground[2]*(1-me.color));
                    me.blep[me.i].show();
                    me.blep[me.i].update();

                    me.i += 1;
                }
            }
        },
		exit: func {
			printDebug("Exit ",me.name~" on ",me.device.name);
			if (me["p_RDR_image"] != nil) me.p_RDR_image.hide();
			cursorFCRgps = nil;
		},
		links: {
			"OSB11": "PageFCRMode",
			"OSB15": "PageFCRCNTL",
			"OSB17": "PageHSD",
			"OSB18": "PageSMSINV",
			"OSB19": "PageSMSWPN",
		},
		layers: ["OSB1TO2ARROWS", "BULLSEYE"],
	},

#  ███████ ██      ██ ██████  
#  ██      ██      ██ ██   ██ 
#  █████   ██      ██ ██████  
#  ██      ██      ██ ██   ██ 
#  ██      ███████ ██ ██   ██ 
#                             
#                             

	PageFLIR: {
		name: "PageFLIR",
		isNew: 1,
		supportSOI: 0,
		needGroup: 1,
		new: func {
			me.instance = {parents:[DisplaySystem.PageFLIR]};
			me.instance.group = nil;
			return me.instance;
		},
		setup: func {
			printDebug(me.name," on ",me.device.name," is being setup");
			me.flirPicHD = radar_system.FlirSensor.setup(me.group, me.device.name=="LeftMFD"?0:1);
            me.flirPicHD.setScale(displayWidth/radar_system.flirImageReso, displayHeight/radar_system.flirImageReso);
            if (flirMode == -2) {
            	if (getprop("f16/stores/nav-mounted")!=1 or getprop("f16/avionics/power-left-hdpt")!=1) {
					flirMode = -1;
				} else {
					flirMode = 0;
				}
			}
            me.bhot = 1;
		},
		enter: func {
			printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = 0;
			}
			me.device.resetControls();
			me.device.controls["OSB5"].setControlText("FLIR",0);
			me.device.controls["OSB10"].setControlText("BGST");
			me.device.controls["OSB11"].setControlText("FCR");
			me.device.controls["OSB17"].setControlText(variantID==1 or variantID==3?"GREEN":"GRAY");
			me.device.controls["OSB16"].setControlText("SWAP");
		},
		controlAction: func (controlName) {
			printDebug(me.name,": ",controlName," activated on ",me.device.name);
			if (controlName == "OSB6") {
                me.bhot = !me.bhot;
            } elsif (controlName == "OSB1") {
                flirMode = 1;
            } elsif (controlName == "OSB3") {
                flirMode = 0;
            } elsif (controlName == "OSB15") {
                flirMode = -1;
            } elsif (controlName == "OSB16") {
                me.device.swap();
            }
		},
		update: func (noti = nil) {
			if (getprop("f16/stores/nav-mounted")!=1 or getprop("f16/avionics/power-left-hdpt")!=1) {
				flirMode = -1;
			}
			me.device.controls["OSB6"].setControlText(me.bhot?"BHOT":"WHOT",1,0);
			if (flirMode == 1) {
				me.caraOn = getprop("f16/avionics/cara-on");
				if (me.caraOn) {
					me.cara   = getprop("position/altitude-agl-ft");
					me.device.controls["OSB9"].setControlText(int(me.cara)~"",1,1);
				} else {
					me.device.controls["OSB9"].setControlText("",1,0);
				}
				if (noti.getproper("headingMag") != nil)
					me.device.controls["OSB13"].setControlText(""~int(noti.getproper("headingMag")),1,1);
				else
					me.device.controls["OSB13"].setControlText("",1,1);
				if (noti.getproper("calibrated") != nil)
					me.device.controls["OSB4"].setControlText(""~int(noti.getproper("calibrated")),1,1);
				else
					me.device.controls["OSB4"].setControlText("",1,1);
				me.device.controls["OSB1"].setControlText("OPER",1,1);
				me.device.controls["OSB15"].setControlText("OFF",1,0);
				me.device.controls["OSB3"].setControlText("STBY",1,0);

				radar_system.FlirSensor.scan(noti, me.bhot);
				me.flirPicHD.dirtyPixels();
	            me.flirPicHD.show();
            } elsif (flirMode == 0) {
            	me.device.controls["OSB13"].setControlText("",1,1);
				me.device.controls["OSB4"].setControlText("",1,1);
            	me.device.controls["OSB1"].setControlText("OPER",1,0);
            	me.device.controls["OSB15"].setControlText("OFF",1,0);
            	me.device.controls["OSB3"].setControlText("STBY",1,1);
            	me.device.controls["OSB9"].setControlText("",1,0);
            	me.flirPicHD.hide();
        	} else {
        		me.device.controls["OSB13"].setControlText("",1,1);
				me.device.controls["OSB4"].setControlText("",1,1);
        		me.device.controls["OSB1"].setControlText("OPER",1,0);
        		me.device.controls["OSB15"].setControlText("OFF",1,1);
        		me.device.controls["OSB3"].setControlText("STBY",1,0);
        		me.device.controls["OSB9"].setControlText("",1,0);
        		me.flirPicHD.hide();
        	}
		},
		exit: func {
			printDebug("Exit ",me.name~" on ",me.device.name);
			me.flirPicHD.hide();
		},
		links: {
			"OSB5": "PageMenu",
			"OSB11": "PageFCR",
		},
		layers: ["BULLSEYE"],
	},

#  ████████ ███████ ██████  
#     ██    ██      ██   ██ 
#     ██    █████   ██████  
#     ██    ██      ██   ██ 
#     ██    ██      ██   ██ 
#                           
#                           

	PageTFR: {
		name: "PageTFR",
		isNew: 1,
		supportSOI: 0,
		needGroup: 1,
		new: func {
			me.instance = {parents:[DisplaySystem.PageTFR]};
			me.instance.group = nil;
			return me.instance;
		},
		setup: func {
			printDebug(me.name," on ",me.device.name," is being setup");
			
		},
		enter: func {
			printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = 0;
			}
			me.device.resetControls();
			me.device.controls["OSB4"].setControlText("TFR",0);
			me.device.controls["OSB11"].setControlText("FCR");
			me.device.controls["OSB11"].setControlText("FCR");
			me.device.controls["OSB16"].setControlText("SWAP");
		},
		controlAction: func (controlName) {
			printDebug(me.name,": ",controlName," activated on ",me.device.name);
			if (controlName == "OSB1") {
                tfrMode = 1;
                setprop("f16/fcs/adv-mode-sel", 1);
            } elsif (controlName == "OSB2") {
                #tfrMode = 2;
            } elsif (controlName == "OSB3") {
                #tfrMode = 3;
            } elsif (controlName == "OSB5") {
                #tfrMode = 4;
            } elsif (controlName == "OSB6") {
                setprop("autopilot/settings/tf-minimums", 1000);
            } elsif (controlName == "OSB7") {
                setprop("autopilot/settings/tf-minimums", 500);
            } elsif (controlName == "OSB8") {
                setprop("autopilot/settings/tf-minimums", 300);
            } elsif (controlName == "OSB9") {
                setprop("autopilot/settings/tf-minimums", 200);
            } elsif (controlName == "OSB10") {
                setprop("autopilot/settings/tf-minimums", 100);
            } elsif (controlName == "OSB12") {
                var tfrSmooth = getprop("f16/fcs/adv-mode-smooth");
                if (tfrSmooth == 1) {
                	tfrSmooth = 5;
                }
                if (tfrSmooth == 5) {
                	tfrSmooth = 10;
                }
                if (tfrSmooth == 10) {
                	tfrSmooth = 1;
                }
                setprop("f16/fcs/adv-mode-smooth", tfrSmooth);
            } elsif (controlName == "OSB14") {
                var tfrRequest = getprop("f16/fcs/adv-mode-sel");
                tfrRequest = !tfrRequest;
                setprop("f16/fcs/adv-mode-sel", 0);
            } elsif (controlName == "OSB15") {
                tfrFreq += 1;
                if (tfrFreq > 8) {
                	tfrFreq = 1;
                }
            } elsif (controlName == "OSB16") {
                me.device.swap();
            }
		},
		update: func (noti = nil) {
			me.clearance = getprop("autopilot/settings/tf-minimums");
			me.enable = getprop("f16/fcs/adv-mode");
			me.mal = getprop("instrumentation/tfs/malfunction");
			me.smooth = getprop("f16/fcs/adv-mode-smooth");# 1 to 10

			if (getprop("f16/stores/nav-mounted")!=1 or getprop("f16/avionics/power-left-hdpt")!=1) {
				me.enable = 0;
			}
			if (me.enable and !me.mal) {
				me.myAlt = noti.getproper("altitude_ft")*FT2M;
				me.group.removeAllChildren();
				me.linu = me.group.createChild("path")
					.moveTo(0,displayHeight*0.5)
					.horiz(displayWidth)
					.moveTo(margin.tfr.sides,displayHeight*0.5+0.5*displayHeight*(me.myAlt-tfr_current_terr)/1500)
					.vert(symbolSize.tfr.terrain)
					.moveTo(displayWidth-margin.tfr.sides,displayHeight*0.5+0.5*displayHeight*(me.myAlt-tfr_target_altitude_m)/1500)
					.vert(symbolSize.tfr.terrain)
					.moveTo(margin.tfr.sides,displayHeight-margin.tfr.bottom)
					.horiz(displayWidth-margin.tfr.sides*2)
					.moveTo(displayWidth-margin.tfr.sides,displayHeight-margin.tfr.bottom)
					.vert(-symbolSize.tfr.tick)
					.moveTo(margin.tfr.sides,displayHeight-margin.tfr.bottom)
					.vert(-symbolSize.tfr.tick)
					.moveTo(margin.tfr.sides+(displayWidth-margin.tfr.sides*2)*0.2,displayHeight-margin.tfr.bottom)
					.vert(-symbolSize.tfr.tick)
					.moveTo(margin.tfr.sides+(displayWidth-margin.tfr.sides*2)*0.4,displayHeight-margin.tfr.bottom)
					.vert(-symbolSize.tfr.tick)
					.moveTo(margin.tfr.sides+(displayWidth-margin.tfr.sides*2)*0.6,displayHeight-margin.tfr.bottom)
					.vert(-symbolSize.tfr.tick)
					.moveTo(margin.tfr.sides+(displayWidth-margin.tfr.sides*2)*0.8,displayHeight-margin.tfr.bottom)
					.vert(-symbolSize.tfr.tick)
					.setStrokeLineWidth(lineWidth.tfr.terrain)
					.setColor(colorDot2);
				for (var i = 1;i<50; i+=1) {
					me.m = me.extrapolate(i, 0, 50, me.myAlt-tfr_current_terr, me.myAlt-tfr_target_altitude_m)*(0.9+0.2*rand());
					me.d = me.extrapolate(i, 0, 50, margin.tfr.sides, displayWidth-margin.tfr.sides);
					me.linu.moveTo(me.d,displayHeight*0.5+0.5*displayHeight*(me.m/1500))
						.vert(symbolSize.tfr.terrain);
				}
			}
			if (me.smooth == 1) me.device.controls["OSB12"].setControlText("HARD");
			if (me.smooth == 5) me.device.controls["OSB12"].setControlText("SOFT");
			if (me.smooth == 10) me.device.controls["OSB12"].setControlText("SMTH");
			me.device.controls["OSB1"].setControlText("NORM",1,me.enable and (!me.mal or math.mod(int(8*(systime()-int(systime()))),2)>0));
			me.device.controls["OSB2"].setControlText("LPI",1,tfrMode == 2);
			me.device.controls["OSB3"].setControlText("STBY",1,tfrMode == 3);
			me.device.controls["OSB5"].setControlText("WX",1,tfrMode == 4);
			me.device.controls["OSB14"].setControlText("OFF",1,!me.enable);
			me.device.controls["OSB15"].setControlText("CHN "~tfrFreq);
			me.device.controls["OSB6"].setControlText("1000",1,me.clearance >= 1000);
			me.device.controls["OSB7"].setControlText("500",1,me.clearance >= 500 and me.clearance < 1000);
			me.device.controls["OSB8"].setControlText("300",1,me.clearance >= 300 and me.clearance < 500);
			me.device.controls["OSB9"].setControlText("200",1,me.clearance >= 200 and me.clearance < 300);
			me.device.controls["OSB10"].setControlText("VLC",1,me.clearance < 200);
		},
		extrapolate: func (x, x1, x2, y1, y2) {
            return y1 + ((x - x1) / (x2 - x1)) * (y2 - y1);
        },
		exit: func {
			printDebug("Exit ",me.name~" on ",me.device.name);
			me.group.removeAllChildren();
		},
		links: {
			"OSB4": "PageMenu",
			"OSB11": "PageFCR",
		},
		layers: ["BULLSEYE"],
	},

#  ███████ ████████  █████  ██████  ████████ ██    ██ ██████  
#  ██         ██    ██   ██ ██   ██    ██    ██    ██ ██   ██ 
#  ███████    ██    ███████ ██████     ██    ██    ██ ██████  
#       ██    ██    ██   ██ ██   ██    ██    ██    ██ ██      
#  ███████    ██    ██   ██ ██   ██    ██     ██████  ██      
#                                                             
#                                                             

	PageVoid: {
		name: "PageVoid",
		isNew: 1,
		supportSOI: 0,
		needGroup: 0,
		new: func {
			me.instance = {parents:[DisplaySystem.PageVoid]};
			me.instance.group = nil;
			return me.instance;
		},
		setup: func {
			printDebug(me.name," on ",me.device.name," is being setup");
		},
		enter: func {
			printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = 0;
			}
			me.device.resetControls();
			me.device.pullUpCue(0);
		},
		controlAction: func (controlName) {
			printDebug(me.name,": ",controlName," activated on ",me.device.name);
		},
		update: func (noti = nil) {
			
		},
		exit: func {
			printDebug("Exit ",me.name~" on ",me.device.name);
		},
		links: {
		},
		layers: [],
	},

	PageGrid: {
		name: "PageGrid",
		isNew: 1,
		supportSOI: 0,
		needGroup: 1,
		new: func {
			me.instance = {parents:[DisplaySystem.PageGrid]};
			me.instance.group = nil;
			return me.instance;
		},
		setup: func {
			printDebug(me.name," on ",me.device.name," is being setup");
			me.setupGrid();
		},
		setupGrid: func () {
			me.group.setScale(1.16, 1.06);
	        me.cross = me.group.createChild("path")
	           .moveTo(1*0.795, 1)
	           .lineTo(550*0.795, 480)
	           .moveTo(550*0.795, 1)
	           .lineTo(1*0.795, 480)
	           .setColor(colorLines);

	        me.div = me.group.createChild("path")
	           .moveTo((1+(550/2))*0.795, 1)
	           .lineTo((1+(550/2))*0.795, 1+480)
	           .moveTo(1, 1+(480/2))
	           .lineTo(550*0.795, 1+(480/2))
	           .setColor(colorLines);

	        me.block = me.group.createChild("path")
	            .moveTo((552/2+30)*0.795, 0)
	            .lineTo(550*0.795, (displayHeight/2-30))
	            .moveTo(550*0.795, (displayHeight/2+30))
	            .lineTo((552/2+30)*0.795, displayHeight)
	            .moveTo((552/2-30)*0.795, displayHeight)
	            .lineTo(0, (displayHeight/2+30))
	            .moveTo(0, (displayHeight/2-30))
	            .lineTo((552/2-30)*0.795, 0)
	            .setColor(colorLines);

	        me.box = me.group.createChild("path")
	            .moveTo((552/3)*0.795, displayHeight/3)
	            .lineTo((552/3)*0.795, displayHeight*2/3)
	            .lineTo((552*2/3)*0.795, displayHeight*2/3)
	            .lineTo((552*2/3)*0.795, displayHeight/3)
	            .lineTo((552/3)*0.795, displayHeight/3)
	            .setColor(colorLines);
	    },
		enter: func {
			printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = 0;
			}
			me.device.resetControls();
			me.device.pullUpCue(0);
		},
		controlAction: func (controlName) {
			printDebug(me.name,": ",controlName," activated on ",me.device.name);
		},
		update: func (noti = nil) {
			
		},
		exit: func {
			printDebug("Exit ",me.name~" on ",me.device.name);
		},
		links: {
		},
		layers: [],
	},

	PageCube: {
		name: "PageCube",
		isNew: 1,
		supportSOI: 0,
		needGroup: 1,
		new: func {
			me.instance = {parents:[DisplaySystem.PageCube]};
			me.instance.group = nil;
			return me.instance;
		},
		setup: func {
			printDebug(me.name," on ",me.device.name," is being setup");
			me.setupCube();
		},
		setupCube: func () {
			me.group.setScale(1.16, 1.06);
	        me.lbl = me.group.createChild("path")
	            .rect(0,0,175,20)
	            .setTranslation((552/2-110)*0.795, 10-3)
	            .setColorFill(colorCubeCyan);

	        me.txt = me.group.createChild("text")
	            .setTranslation((552/2)*0.795, 10)
	            .setText("BUILT-IN TEST")
	            .setAlignment("center-top")
	            .setFontSize(22, 1.0)
	            .setColor(colorBackground);

	        me.rf = me.group.createChild("path")
	            .moveTo((552/2)*0.795, displayHeight/2)
	            .lineTo((552/2)*0.795, displayHeight/2-100)
	            .lineTo((552/2+100)*0.795, displayHeight/2-100+50)
	            .lineTo((552/2+100)*0.795, displayHeight/2+50)
	            .lineTo((552/2)*0.795, displayHeight/2)
	            .setColorFill(colorCubeCyan);

	        me.lf = me.group.createChild("path")
	            .moveTo((552/2)*0.795, displayHeight/2)
	            .lineTo((552/2)*0.795, displayHeight/2-100)
	            .lineTo((552/2-100)*0.795, displayHeight/2-100+50)
	            .lineTo((552/2-100)*0.795, displayHeight/2+50)
	            .lineTo((552/2)*0.795, displayHeight/2)
	            .setColorFill(colorCubeRed);

	        me.bf = me.group.createChild("path")
	            .moveTo((552/2)*0.795, displayHeight/2)
	            .lineTo((552/2+100)*0.795, displayHeight/2+50)
	            .lineTo((552/2)*0.795, displayHeight/2+100)
	            .lineTo((552/2-100)*0.795, displayHeight/2+50)
	            .lineTo((552/2)*0.795, displayHeight/2)
	            .setColorFill(colorCubeGreen);
	    },
		enter: func {
			printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = 0;
			}
			me.device.resetControls();
			me.device.pullUpCue(0);
		},
		controlAction: func (controlName) {
			printDebug(me.name,": ",controlName," activated on ",me.device.name);
		},
		update: func (noti = nil) {
			
		},
		exit: func {
			printDebug("Exit ",me.name~" on ",me.device.name);
		},
		links: {
		},
		layers: [],
	},

#  ██   ██  █████  ███████ 
#  ██   ██ ██   ██ ██      
#  ███████ ███████ ███████ 
#  ██   ██ ██   ██      ██ 
#  ██   ██ ██   ██ ███████ 
#                          
#                          

	PageHAS: {
		name: "PageHAS",
		isNew: 1,
		supportSOI: 1,
		needGroup: 1,
		soiPrio: 5,
		new: func {
			me.instance = {parents:[DisplaySystem.PageHAS]};
			me.instance.group = nil;
			return me.instance;
		},
		setup: func {
			printDebug(me.name," on ",me.device.name," is being setup");
			me.elapsed = 0;
	        me.slew_c_last = slew_c;
	        me.wdt = displayWidth;
	        me.items = [];
	        me.iter = -1;
	        me.sensor = radar_system.f16_radSensor;
	        me.model_index = me.device.name=="LeftMFD"?0:1;
	        me.setupHARM(me.device.name=="LeftMFD"?0:1);
		},
		setupHARM: func (index) {
	        me.buttonView = me.group.createChild("group")
	                .setTranslation(displayWidthHalf,displayHeight);
	        me.groupRdr = me.group.createChild("group")
	                .setTranslation(displayWidthHalf, 0);#552,displayHeight , 0.795 is for UV map
	        me.groupCursor = me.group.createChild("group")
	                .setTranslation(displayWidthHalf, displayHeight);#552,displayHeight , 0.795 is for UV map

	        me.width  = displayWidthHalf*2;
	        me.height = displayHeight;
	        me.index = index;
	        me.maxB = 5;
	        me.rdrTxt = setsize([],me.maxB);
	        for (var i = 0;i<me.maxB;i+=1) {
	                me.rdrTxt[i] = me.groupRdr.createChild("text")
	                        .setAlignment("center-center")
	                        .setFontSize(me.device.fontSize, 1.0)
	                        .setColor(colorText1);
	        }
	        
	        me.cursor = me.groupCursor.createChild("path")
	                    .moveTo(-8*symbolSize.has.cursor,-9*symbolSize.has.cursor)
	                    .vert(18*symbolSize.has.cursor)
	                    .moveTo(8*symbolSize.has.cursor,-9*symbolSize.has.cursor)
	                    .vert(18*symbolSize.has.cursor)
	                    .setStrokeLineWidth(lineWidth.has.cursor)
	                    .setColor(colorLine3);

	        var fieldH = me.height * 0.60;
	        var fieldW = me.width  * 0.70;

	        me.fieldH = fieldH;
	        me.fieldW = fieldW;
	        me.fieldX = -fieldW * 0.5;
	        me.fieldY = me.height * 0.25;
	        me.fieldDiag = math.sqrt(me.fieldX*me.fieldX+me.fieldX*me.fieldX);
	        me.detectedThreatStatusBox = me.groupRdr.createChild("path")
	                .moveTo(-fieldW*0.5, margin.has.statusBox)
	                .horiz(fieldW)
	                .vert(me.height * 0.10)
	                .horiz(-fieldW)
	                .vert(-me.height * 0.10)
	                .setColor(colorLine1)
	                .set("z-index",12)
	                .setStrokeLineWidth(lineWidth.has.statusBox);
	        me.detectedThreatStatusBoxText = me.groupRdr.createChild("text")
	                        .setAlignment("left-center")
	                        .setTranslation(-fieldW*0.5, margin.has.statusBox+me.height * 0.10*0.5)
	                        .setFontSize(me.device.fontSize, 1.0)
	                        .setColor(colorText1);
	        me.dashBox = me.groupRdr.createChild("path")
	                .moveTo(-fieldW * 0.5, me.height * 0.25)
	                .horiz(fieldW)
	                .vert(fieldH)
	                .horiz(-fieldW)
	                .vert(-fieldH)
	                .setColor(colorCircle1)
	                .setStrokeDashArray([20,20])
	                .set("z-index",12)
	                .setStrokeLineWidth(lineWidth.has.enclosure);

	        me.handoffGrp = me.groupRdr.createChild("group");
	        me.handoffRot = me.handoffGrp.createTransform().setTranslation(0, me.fieldY + me.fieldH*0.5);;
	        me.handoffTxt = me.handoffGrp.createChild("text")
	                        .setAlignment("center-center")
	                        .setFontSize(me.device.fontSize, 1.0)
	                        .setColor(colorText1);

	        me.searchText = me.groupRdr.createChild("text")
	                        .setAlignment("center-top")
	                        .setTranslation(0, margin.has.searchText+me.height * 0.10)
	                        .setFontSize(me.device.fontSize, 1.0)
	                        .setColor(colorText2);

	        me.crossY = me.groupRdr.createChild("path")
	                .moveTo(0, me.fieldY)
	                .vert(fieldH)
	                .setColor(colorLine3)
	                .set("z-index",20)
	                .setStrokeLineWidth(lineWidth.has.aim);
	        me.crossX = me.groupRdr.createChild("path")
	                .moveTo(-fieldW * 0.5, me.fieldY + fieldH * 0.25)
	                .horiz(fieldW)
	                .setColor(colorLine3)
	                .set("z-index",20)
	                .setStrokeLineWidth(lineWidth.has.aim);
	        me.crossX1 = me.groupRdr.createChild("path")
	                .moveTo(0, symbolSize.has.tick*0.5)
	                .vert(-symbolSize.has.tick)
	                .setColor(colorLine3)
	                .set("z-index",20)
	                .setStrokeLineWidth(lineWidth.has.aim);
	        me.crossX2 = me.groupRdr.createChild("path")
	                .moveTo(0, symbolSize.has.tick*0.5)
	                .vert(-symbolSize.has.tick)
	                .setColor(colorLine3)
	                .set("z-index",20)
	                .setStrokeLineWidth(lineWidth.has.aim);
	        me.crossX3 = me.groupRdr.createChild("path")
	                .moveTo(0, symbolSize.has.tick*0.5)
	                .vert(-symbolSize.has.tick)
	                .setColor(colorLine3)
	                .set("z-index",20)
	                .setStrokeLineWidth(lineWidth.has.aim);
	        me.crossX4 = me.groupRdr.createChild("path")
	                .moveTo(0, symbolSize.has.tick*0.5)
	                .vert(-symbolSize.has.tick)
	                .setColor(colorLine3)
	                .set("z-index",20)
	                .setStrokeLineWidth(lineWidth.has.aim);
	        me.crossX5 = me.groupRdr.createChild("path")
	                .moveTo(0, symbolSize.has.tick*0.5)
	                .vert(-symbolSize.has.tick)
	                .setColor(colorLine3)
	                .set("z-index",20)
	                .setStrokeLineWidth(lineWidth.has.aim);
	        me.crossX6 = me.groupRdr.createChild("path")
	                .moveTo(0, symbolSize.has.tick*0.5)
	                .vert(-symbolSize.has.tick)
	                .setColor(colorLine3)
	                .set("z-index",20)
	                .setStrokeLineWidth(lineWidth.has.aim);
	        me.crossY1 = me.groupRdr.createChild("path")
	                .moveTo(-symbolSize.has.tick*0.5, 0)
	                .horiz(symbolSize.has.tick)
	                .setColor(colorLine3)
	                .set("z-index",20)
	                .setStrokeLineWidth(lineWidth.has.aim);
	        me.crossY2 = me.groupRdr.createChild("path")
	                .moveTo(-symbolSize.has.tick*0.5, 0)
	                .horiz(symbolSize.has.tick)
	                .setColor(colorLine3)
	                .set("z-index",20)
	                .setStrokeLineWidth(lineWidth.has.aim);
	        me.crossY3 = me.groupRdr.createChild("path")
	                .moveTo(-symbolSize.has.tick*0.5, 0)
	                .horiz(symbolSize.has.tick)
	                .setColor(colorLine3)
	                .set("z-index",20)
	                .setStrokeLineWidth(lineWidth.has.aim);
	        me.cross = me.groupRdr.createChild("path")
	                .moveTo(symbolSize.has.crossInner, 0)
	                .horiz(fieldW * 0.5-symbolSize.has.crossInner)
	                .moveTo(-symbolSize.has.crossInner, 0)
	                .horiz(-fieldW * 0.5+symbolSize.has.crossInner)
	                .moveTo(0, symbolSize.has.crossInner)
	                .vert(fieldH * 0.5-symbolSize.has.crossInner)
	                .moveTo(0, -symbolSize.has.crossInner)
	                .vert(-fieldH * 0.5+symbolSize.has.crossInner)
	                .setColor(colorLine3)
	                .set("z-index",20)
	                .setStrokeLineWidth(lineWidth.has.aim);
	        me.osbShow = [0,0,0,0,0];
        },
		enter: func {
			printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = 0;
			}
			me.device.resetControls();
			me.device.controls["OSB7"].setControlText("RS");
			me.device.controls["OSB11"].setControlText("HAS",0);
			me.device.controls["OSB15"].setControlText("UFC");
			me.device.controls["OSB16"].setControlText("SWAP");
			me.device.controls["OSB17"].setControlText("HSD");
			me.device.controls["OSB18"].setControlText("SMS");
			me.device.controls["OSB19"].setControlText("WPN");
			me.device.controls["OSB20"].setControlText("TGP");
			me.device.system.fetchLayer("SharedStations").init(me, me.getType);
		},
		getType: func {
			return ["AGM-88", 50];
		},
		controlAction: func (controlName) {
			printDebug(me.name,": ",controlName," activated on ",me.device.name);
			if (controlName == "OSB1" or controlName == "OSB2" or controlName == "OSB3" or controlName == "OSB4" or controlName == "OSB5") {
                if (me.sensor.handoffTarget != nil and me.sensor.handoffTarget["tblIdx"] == num(right(controlName,1))-1) {
                    me.sensor.handoffTarget = nil;
                }
            } elsif (controlName == "OSB7") {
                me.sensor.reset();
                me.sensor.searchCounter += 1;
            } elsif (controlName == "OSB12") {
                me.sensor.currtable += 1;
                if (me.sensor.currtable > 2) me.sensor.currtable = 0;
                me.sensor.handoffTarget = nil;
            } elsif (controlName == "OSB13") {
                me.sensor.fov_desired += 1;
                if (me.sensor.fov_desired > 3) me.sensor.fov_desired = 0;
            } elsif (controlName == "OSB15") {
                ded.dataEntryDisplay.harmTablePage = me.sensor.currtable;
                ded.dataEntryDisplay.page = ded.pHARM;
            } elsif (controlName == "OSB16") {
                me.device.swap();
            } elsif (controlName == "OSB20") {
                switchTGP();
            }
		},
		update: func (noti = nil) {
            if (noti.FrameCount != 1 and noti.FrameCount != 3)
                return;
            #printDebug("\nHAD update:\n=======");

            me.harmSelected = 0;
            if (pylons.fcs != nil) {
                me.radWeap = pylons.fcs.getSelectedWeapon();
                if (me.radWeap != nil) {
                    if (me.radWeap["guidance"] == "radiation" and me.radWeap.getStatus() >= armament.MISSILE_SEARCH) {
                        me.sensor.maxArea = me.fieldW * me.fieldH;
                        if (me.sensor.fov_desired == 1) {
                            me.sensor.area = me.sensor.maxArea*0.25;
                            me.sensor.x    = [-15, 15];
                            me.sensor.y    = [-10, 10];#todo: something of here, decide proper
                        } elsif (me.sensor.fov_desired == 2) {
                            me.sensor.area = me.sensor.maxArea*0.5;
                            me.sensor.x    = [-30, 0];
                            me.sensor.y    = [-30, 10];
                        } elsif (me.sensor.fov_desired == 3) {
                            me.sensor.area = me.sensor.maxArea*0.5;
                            me.sensor.x    = [0, 30];
                            me.sensor.y    = [-30, 10];
                        } else {
                            me.sensor.area = me.sensor.maxArea;
                            me.sensor.x    = [-30, 30];
                            me.sensor.y    = [-30, 10];
                        }
                        me.sensor.table = me.sensor.tables[me.sensor.currtable];
                        me.sensor.range = me.radWeap.max_fire_range_nm;
                        if (me.sensor.fov != me.sensor.fov_desired) {
                            me.sensor.fov = me.sensor.fov_desired;
                            me.sensor.reset();
                            me.sensor.searchCounter = 0;
                        }
                        me.sensor.setEnabled(me.sensor.handoffTarget == nil);
                        me.harmSelected = 1;
                    } else {
                        me.sensor.setEnabled(0);
                    }
                } else {
                    me.sensor.setEnabled(0);
                }
            } else {
                me.sensor.setEnabled(0);
                return;
            }

            #CURSOR

            me.IMSOI = me.device.soi == 1;

            me.slew_x = getprop("controls/displays/target-management-switch-x[" ~ me.model_index ~ "]");
            me.slew_y = -getprop("controls/displays/target-management-switch-y[" ~ me.model_index ~ "]");

            if (noti.getproper("viewName") != "TGP" and me.IMSOI) {
                f16.resetSlew();
            }

            if (me.IMSOI) {
                if ((me.slew_x != 0 or me.slew_y != 0 or slew_c != 0) and (cursor_lock == -1 or cursor_lock == me.index) and noti.getproper("viewName") != "TGP" and me.sensor.handoffTarget == nil) {
                    cursor_destination = nil;
                    cursor_posHAS[0] += me.slew_x*175;
                    cursor_posHAS[1] -= me.slew_y*175;
                    cursor_posHAS[0] = math.clamp(cursor_posHAS[0], -displayWidthHalf, displayWidthHalf);
                    cursor_posHAS[1] = math.clamp(cursor_posHAS[1], -displayHeight, 0);
                    cursor_click = (slew_c and !me.slew_c_last)?me.index:-1;
                    cursor_lock = me.index;
                } elsif (cursor_lock == me.index or (me.slew_x == 0 or me.slew_y == 0 or slew_c == 0)) {
                    cursor_lock = -1;
                }
            
                me.slew_c_last = slew_c;
                slew_c = 0;
            }
            me.elapsed = noti.getproper("elapsed");
            me.cursor.setTranslation(cursor_posHAS);
            me.cursor.setVisible(me.sensor.handoffTarget == nil);
            if (0 and cursor_click==0) printDebug(cursor_posHAS[0],", ",cursor_posHAS[1]+displayHeight, "  click: ", cursor_click);

            
            
            me.device.controls["OSB12"].setControlText("TBL"~(me.sensor.currtable + 1));
            
            if (me.sensor.fov_desired == 1) {
                me.fovTxt = "CTR";
                me.crossX.setTranslation(0,me.fieldH*0.25); 
                me.crossY.setTranslation(0,0);
                me.crossX1.setTranslation(me.fieldX+20*me.fieldW/6, me.fieldY+me.fieldH*0.5); 
                me.crossX2.setTranslation(me.fieldX+20*me.fieldW/6, me.fieldY+me.fieldH*0.5); 
                me.crossX3.setTranslation(me.fieldX+1*me.fieldW/6, me.fieldY+me.fieldH*0.5); 
                me.crossX4.setTranslation(me.fieldX+5*me.fieldW/6, me.fieldY+me.fieldH*0.5); 
                me.crossX5.setTranslation(me.fieldX+20*me.fieldW/6, me.fieldY+me.fieldH*0.5); 
                me.crossX6.setTranslation(me.fieldX+20*me.fieldW/6, me.fieldY+me.fieldH*0.5); 
                me.crossY1.setTranslation(0, me.fieldY+me.fieldH*0.5+2*me.fieldH*0.75/3);
                me.crossY2.setTranslation(0, me.fieldY+me.fieldH*0.5+4*me.fieldH*0.75/3);
                me.crossY3.setTranslation(0, me.fieldY+me.fieldH*0.5+6*me.fieldH*0.75/3);
            } elsif (me.sensor.fov_desired == 2) {
                me.fovTxt = "LEFT";
                me.crossX.setTranslation(0,0); 
                me.crossY.setTranslation(-me.fieldX,0);
                me.crossX1.setTranslation(me.fieldX,                    me.fieldY+me.fieldH*0.25); 
                me.crossX2.setTranslation(me.fieldX+2*me.fieldW/6, me.fieldY+me.fieldH*0.25); 
                me.crossX3.setTranslation(me.fieldX+4*me.fieldW/6, me.fieldY+me.fieldH*0.25); 
                me.crossX4.setTranslation(me.fieldX+6*me.fieldW/6, me.fieldY+me.fieldH*0.25); 
                me.crossX5.setTranslation(me.fieldX+8*me.fieldW/6, me.fieldY+me.fieldH*0.25); 
                me.crossX6.setTranslation(me.fieldX+10*me.fieldW/6, me.fieldY+me.fieldH*0.25); 
                me.crossY1.setTranslation(-me.fieldX, me.fieldY+me.fieldH*0.25+1*me.fieldH*0.75/3);
                me.crossY2.setTranslation(-me.fieldX, me.fieldY+me.fieldH*0.25+2*me.fieldH*0.75/3);
                me.crossY3.setTranslation(-me.fieldX, me.fieldY+me.fieldH*0.25+3*me.fieldH*0.75/3);
            } elsif (me.sensor.fov_desired == 3) {
                me.fovTxt = "RGHT";
                me.crossX.setTranslation(0,0); 
                me.crossY.setTranslation(me.fieldX,0);
                me.crossX1.setTranslation(me.fieldX,                    me.fieldY+me.fieldH*0.25); 
                me.crossX2.setTranslation(me.fieldX+2*me.fieldW/6, me.fieldY+me.fieldH*0.25); 
                me.crossX3.setTranslation(me.fieldX+4*me.fieldW/6, me.fieldY+me.fieldH*0.25); 
                me.crossX4.setTranslation(me.fieldX+6*me.fieldW/6, me.fieldY+me.fieldH*0.25); 
                me.crossX5.setTranslation(me.fieldX+8*me.fieldW/6, me.fieldY+me.fieldH*0.25); 
                me.crossX6.setTranslation(me.fieldX+10*me.fieldW/6, me.fieldY+me.fieldH*0.25); 
                me.crossY1.setTranslation(me.fieldX, me.fieldY+me.fieldH*0.25+1*me.fieldH*0.75/3);
                me.crossY2.setTranslation(me.fieldX, me.fieldY+me.fieldH*0.25+2*me.fieldH*0.75/3);
                me.crossY3.setTranslation(me.fieldX, me.fieldY+me.fieldH*0.25+3*me.fieldH*0.75/3);
            } else {
                me.fovTxt = "WIDE";
                me.crossX.setTranslation(0,0); 
                me.crossY.setTranslation(0,0);
                me.crossX1.setTranslation(me.fieldX, me.fieldY+me.fieldH*0.25); 
                me.crossX2.setTranslation(me.fieldX+1*me.fieldW/6, me.fieldY+me.fieldH*0.25); 
                me.crossX3.setTranslation(me.fieldX+2*me.fieldW/6, me.fieldY+me.fieldH*0.25); 
                me.crossX4.setTranslation(me.fieldX+3*me.fieldW/6, me.fieldY+me.fieldH*0.25); 
                me.crossX5.setTranslation(me.fieldX+4*me.fieldW/6, me.fieldY+me.fieldH*0.25); 
                me.crossX6.setTranslation(me.fieldX+5*me.fieldW/6, me.fieldY+me.fieldH*0.25); 
                me.crossY1.setTranslation(0, me.fieldY+me.fieldH*0.25+1*me.fieldH*0.75/3);
                me.crossY2.setTranslation(0, me.fieldY+me.fieldH*0.25+2*me.fieldH*0.75/3);
                me.crossY3.setTranslation(0, me.fieldY+me.fieldH*0.25+3*me.fieldH*0.75/3);
            }
            me.device.controls["OSB13"].setControlText(me.fovTxt);

            if (me.sensor.enabled) {
                me.cycleTimeLeft = math.max(0,me.sensor.dura-(me.elapsed-me.sensor.searchStart));
                me.searchText.setText(sprintf("%d:%02d   SCT-%d",(me.cycleTimeLeft)/60, math.mod(me.cycleTimeLeft,60),me.sensor.searchCounter));
                me.searchText.show();
            } else {
                me.searchText.hide();
            }

            me.items = me.sensor.vector_aicontacts_seen;
            me.iter = size(me.items)-1;

            if (me.harmSelected and me.sensor.handoffTarget != nil and me.radWeap.status < armament.MISSILE_LOCK) {
                # This makes sure we go from handover back to search when missile loses lock
                if (me.elapsed-me.sensor.handoffTime > 1) {
                    # It had time to get lock, but failed or masterarm was off
                    me.radWeap.setContacts([]);
                    me.sensor.handoffTarget = nil;
                }
            } elsif (!me.harmSelected) {
                me.sensor.handoffTarget = nil;
            }

            if (noti.FrameCount == 1 and me.sensor.handoffTarget == nil) {
                for (me.jj = 0; me.jj < 5;me.jj += 1) {
                	me.osbShow[me.jj] = 1;
                }
            }

            if (me.sensor.handoffTarget != nil) {
                # Handoff
                me.dataPos = [me.extrapolate(me.sensor.handoffTarget.get_bearing()-radar_system.self.getHeading(), -30, 30, -me.fieldW*0.5, me.fieldW*0.5), me.extrapolate(me.sensor.handoffTarget.getElevation()-radar_system.self.getPitch(), -30, 30, me.fieldW*0.5, -me.fieldW*0.5)];
                if (math.sqrt(me.dataPos[0]*me.dataPos[0]+me.dataPos[1]*me.dataPos[1]) < me.fieldDiag) {
                    me.rot = radar_system.self.getRoll()*D2R;
                    me.handoffRot.setRotation(-me.rot);
                    me.handoffTxt.setTranslation(me.dataPos);
                    me.handoffTxt.setRotation(me.rot);
                    me.handoffTxt.setText(me.sensor.handoffTarget.mdl~me.sensor.handoffTarget.radiSpike);
                    me.handoffTxt.show();
                } else {
                    me.handoffTxt.hide();
                }
                me.cross.setTranslation(0, me.fieldY + me.fieldH*0.5);
                me.rdrTxt[0].hide();
                me.rdrTxt[1].hide();
                me.rdrTxt[2].hide();
                me.rdrTxt[3].hide();
                me.rdrTxt[4].hide();
                me.crossX.hide();
                me.crossY.hide();
                me.crossX1.hide();
                me.crossX2.hide(); 
                me.crossX3.hide();
                me.crossX4.hide();
                me.crossX5.hide();
                me.crossX6.hide();
                me.crossY1.hide();
                me.crossY2.hide();
                me.crossY2.hide();
                #me.dashBox.hide();
                me.cross.show();

                for (me.jj = 0; me.jj < 5;me.jj += 1) {
                    if (me.sensor.handoffTarget["tblIdx"] == me.jj) {
                        me.osbShow[me.jj] = 0;
                    } else {
                        me.osbShow[me.jj] = 1;
                    }
                }

                if (cursor_click == me.index) {
                    me.sensor.handoffTarget = nil;
                    cursor_click = -1;
                    # not needed anymore due to last lines in method:
                    #if (me.radWeap != nil and me.radWeap["guidance"] == "radiation") {
                    #    me.radWeap.setContacts([]);
                    #    me.radWeap.clearTgt();
                    #}
                } elsif (me.harmSelected) {
                    me.radWeap.setContacts([me.sensor.handoffTarget]);
                }
            } elsif (me.sensor.enabled) {
                # Search
                me.crossX.show();
                me.crossY.show();
                me.crossX1.show();
                me.crossX2.show(); 
                me.crossX3.show();
                me.crossX4.show();
                me.crossX5.show();
                me.crossX6.show();
                me.crossY1.show();
                me.crossY2.show();
                me.crossY2.show();
                #me.dashBox.show();
                me.cross.hide();
                me.handoffTxt.hide();
                me.topLine = "   ";
                me.topCheck = [0,0,0,0,0];
                me.clickableItems = [];
                for (me.txt_count = 0; me.txt_count < 5; me.txt_count += 1) {
                    me.check = !(me.txt_count > me.iter);
                    me.checkFresh = me.check and me.items[me.txt_count].discover < me.elapsed-me.sensor.searchStart and me.items[me.txt_count].discoverSCT==me.sensor.searchCounter;
                    me.checkFading = me.check and me.items[me.txt_count]["discoverSCTShown"] == me.sensor.searchCounter-1;
                    #if (me.check) printDebug(" fresh ",me.checkFresh,", fading ",me.checkFading, ", timetoshow ", me.items[me.txt_count].discover);
                    #if (me.check) printDebug("  time ",me.items[me.txt_count].discover > systime()-me.sensor.searchStart,",  shown ",me.items[me.txt_count].discoverSCT," now",me.sensor.searchCounter);
                    if (!me.check or (!me.checkFresh and !me.checkFading) ) {
                        me.rdrTxt[me.txt_count].hide();
                        continue;
                    }
                    me.data = me.items[me.txt_count];
                    append(me.clickableItems, me.data);
                    if (me.checkFresh) {
                        me.data.discoverShown = me.data.discover;
                        me.data.discoverSCTShown = me.data.discoverSCT;
                    }
                    me.dataPos = [me.extrapolate(me.data.pos[0], me.sensor.x[0], me.sensor.x[1], me.fieldX, me.fieldX + me.fieldW), me.extrapolate(me.data.pos[1], me.sensor.y[0], me.sensor.y[1], me.fieldY + me.fieldH, me.fieldY)];
                    me.data.xyPos = me.dataPos;
                    me.rdrTxt[me.txt_count].setText(me.data.mdl~me.data.radiSpike);
                    me.rdrTxt[me.txt_count].setTranslation(me.dataPos);
                    me.rdrTxt[me.txt_count].show();
                    if (!me.topCheck[me.data.tblIdx]) {
                        me.topLine ~= me.data.mdl~"   ";
                        me.topCheck[me.data.tblIdx] = 1;
                    }
                }
                me.detectedThreatStatusBoxText.setText(me.topLine);
                if (cursor_click == me.index) {
                    me.handoffTarget = me.click(me.clickableItems);
                    if (me.handoffTarget != nil) {
                        me.sensor.handoffTime = me.elapsed;
                        me.sensor.handoffTarget = me.handoffTarget;
                        #printDebug("MFD: Clicked handoff on ",!cursor_click?"LEFT":"RIGHT");#TODO: need right display
                    }
                    cursor_click = -1;
                } elsif(cursor_click != -1) {
                    #printDebug("MFD: Failed click. It was ",!cursor_click?"LEFT":"RIGHT");#TODO: need right display
                }
            } else {
                # Not searching
                me.crossX.show();
                me.crossY.show();
                me.crossX1.show();
                me.crossX2.show(); 
                me.crossX3.show();
                me.crossX4.show();
                me.crossX5.show();
                me.crossX6.show();
                me.crossY1.show();
                me.crossY2.show();
                me.crossY2.show();
                #me.dashBox.show();
                me.cross.hide();
                me.handoffTxt.hide();
                me.topLine = "   ";
                me.topCheck = [0,0,0,0,0];
                me.detectedThreatStatusBoxText.setText(me.topLine);

                for (me.txt_count = 0; me.txt_count < 5; me.txt_count += 1) {
                    me.rdrTxt[me.txt_count].hide();
                }

                if (cursor_click == me.index) {
                    cursor_click = -1;
                }
            }

            if (me.sensor.handoffTarget == nil and me.harmSelected) {
                me.radWeap.clearTgt();
                me.radWeap.setContacts([]);
            }
            for (me.jj = 0; me.jj < 5;me.jj += 1) {
            	var osb = "OSB"~(me.jj+1);
                if (size(me.sensor.tables[me.sensor.currtable])>me.jj) {
                    me.device.controls[osb].setControlText(me.sensor.tables[me.sensor.currtable][me.jj], me.osbShow[me.jj]);
                } else {
                	me.device.controls[osb].setControlText("");
                }
            }
        },
        click: func (items) {
            me.clostestItem = nil;
            me.clostestDist = 10000;

            foreach(me.citem; items) {
                if (me.citem["xyPos"] == nil) continue;
                me.xx = math.abs(me.citem.xyPos[0]-cursor_posHAS[0]);
                me.yy = math.abs(me.citem.xyPos[1]-(cursor_posHAS[1] + displayHeight));
                me.cdist = math.sqrt(me.xx*me.xx+me.yy*me.yy);
                if (me.cdist < me.clostestDist) {
                    me.clostestDist = me.cdist;
                    me.clostestItem = me.citem;
                }
            }
            if (me.clostestDist < 20) {
                return me.clostestItem;
            }
        },
        interpolate: func (x, x1, x2, y1, y2) {
            return math.clamp(y1 + ((x - x1) / (x2 - x1)) * (y2 - y1),math.min(y1,y2),math.max(y1,y2));
        },
        extrapolate: func (x, x1, x2, y1, y2) {
            return y1 + ((x - x1) / (x2 - x1)) * (y2 - y1);
        },
		exit: func {
			printDebug("Exit ",me.name~" on ",me.device.name);
		},
		links: {
			"OSB11": "PageMenu",
			"OSB19": "PageSMSWPN",
			"OSB18": "PageSMSINV",
			"OSB17": "PageHSD",
		},
		layers: ["SharedStations"],
	},

#  ███    ███ ███████ ███    ██ ██    ██ 
#  ████  ████ ██      ████   ██ ██    ██ 
#  ██ ████ ██ █████   ██ ██  ██ ██    ██ 
#  ██  ██  ██ ██      ██  ██ ██ ██    ██ 
#  ██      ██ ███████ ██   ████  ██████  
#                                        
#                                        

	PageMenu: {
		name: "PageMenu",
		isNew: 1,
		supportSOI: 0,
		needGroup: 0,
		new: func {
			me.instance = {parents:[DisplaySystem.PageMenu]};
			me.instance.group = nil;
			return me.instance;
		},
		setup: func {
			printDebug(me.name," on ",me.device.name," is being setup");
		},
		enter: func {
			printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = 0;
			}
			me.device.resetControls();
			me.device.controls["OSB1"].setControlText("FCR");
			me.device.controls["OSB2"].setControlText("TGP");
			me.device.controls["OSB3"].setControlText("WPN");
			me.device.controls["OSB4"].setControlText("TFR");
			me.device.controls["OSB5"].setControlText("FLIR");
			me.device.controls["OSB6"].setControlText("SMS");
			me.device.controls["OSB7"].setControlText("HSD");
			me.device.controls["OSB8"].setControlText("DTE");
			me.device.controls["OSB9"].setControlText("TEST");
			me.device.controls["OSB10"].setControlText("FLCS");
			me.device.controls["OSB11"].setControlText("BLANK");
			me.device.controls["OSB12"].setControlText("HAS");
			me.device.controls["OSB14"].setControlText("RCCE");
			me.device.controls["OSB15"].setControlText("RESET\n MENU");
			me.device.controls["OSB16"].setControlText("SWAP");
			me.device.controls["OSB19"].setControlText("DCLT");#in mlu 1 this is on osb 20
			me.device.controls["OSB20"].setControlText("TCN");
		},
		controlAction: func (controlName) {
			printDebug(me.name,": ",controlName," activated on ",me.device.name);
			if (controlName == "OSB16") {
				me.device.swap();
			} elsif (controlName == "OSB2") {
                switchTGP();
            }
		},
		update: func (noti = nil) {
			
		},
		exit: func {
			printDebug("Exit ",me.name~" on ",me.device.name);
		},
		links: {
			"OSB1":  "PageFCR",
			"OSB3":  "PageSMSWPN",
			"OSB4":  "PageTFR",
			"OSB5":  "PageFLIR",
			"OSB6":  "PageSMSINV",
			"OSB7":  "PageHSD",
			"OSB8":  "PageDTE",
			"OSB9":  "PageTest",
			"OSB11": "PageBlank",
			"OSB12": "PageHAS",
			"OSB14": "PageRCCE",
			"OSB15": "PageReset",
			"OSB20": "PageTCN",
		},
		layers: ["BULLSEYE"],
	},

#  ██████   ██████  ██████ ███████ 
#  ██   ██ ██      ██      ██      
#  ██████  ██      ██      █████   
#  ██   ██ ██      ██      ██      
#  ██   ██  ██████  ██████ ███████ 
#                                  
#                                  

	PageRCCE: {
		name: "PageRCCE",
		isNew: 1,
		supportSOI: 0,
		needGroup: 0,
		new: func {
			me.instance = {parents:[DisplaySystem.PageRCCE]};
			me.instance.group = nil;
			return me.instance;
		},
		setup: func {
			printDebug(me.name," on ",me.device.name," is being setup");
		},
		enter: func {
			printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = 0;
			}
			me.device.resetControls();
			me.device.controls["OSB1"].setControlText("PRI\n18");
			me.device.controls["OSB2"].setControlText("LAS");
			me.device.controls["OSB3"].setControlText("FWD");
			me.device.controls["OSB6"].setControlText("SEC\n17");
			me.device.controls["OSB7"].setControlText("IRLS");
			me.device.controls["OSB8"].setControlText("VT");
			me.device.controls["OSB11"].setControlText("STBY");
			me.device.controls["OSB14"].setControlText("FRZ");
			me.device.controls["OSB15"].setControlText("TEST");
			me.device.controls["OSB16"].setControlText("SWAP");
			me.device.controls["OSB18"].setControlText("SMS");
			me.device.controls["OSB19"].setControlText("RCCE",0);
			me.device.controls["OSB20"].setControlText("DCLT");
			#TODO: Menu items that come from the pod, should only show in update() when pod mounted when we get one.
		},
		controlAction: func (controlName) {
			printDebug(me.name,": ",controlName," activated on ",me.device.name);
            if (controlName == "OSB16") {
                me.device.swap();
            }
		},
		update: func (noti = nil) {			
		},
		exit: func {
			printDebug("Exit ",me.name~" on ",me.device.name);
		},
		links: {
			"OSB19": "PageMenu",
			"OSB18": "PageSMSINV",
		},
		layers: [],
	},

#  ██████  ██       █████  ███    ██ ██   ██ 
#  ██   ██ ██      ██   ██ ████   ██ ██  ██  
#  ██████  ██      ███████ ██ ██  ██ █████   
#  ██   ██ ██      ██   ██ ██  ██ ██ ██  ██  
#  ██████  ███████ ██   ██ ██   ████ ██   ██ 
#                                            
#                                            

	PageBlank: {
		name: "PageBlank",
		isNew: 1,
		supportSOI: 0,
		needGroup: 1,
		new: func {
			me.instance = {parents:[DisplaySystem.PageBlank]};
			me.instance.group = nil;
			return me.instance;
		},
		setup: func {
			printDebug(me.name," on ",me.device.name," is being setup");
			me.pageText = me.group.createChild("text")
				.set("z-index", 10)
				.setColor(colorText1)
				.setAlignment("center-center")
				.setTranslation(displayWidthHalf, displayHeightHalf)
				.setFontSize(me.device.fontSize)
				.setText("BLANK");
		},
		enter: func {
			printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = 0;
			}
			me.device.resetControls();
			me.device.controls["OSB16"].setControlText("SWAP");
			me.device.controls["OSB17"].setControlText("FCR");
			me.device.controls["OSB18"].setControlText("SMS");
		},
		controlAction: func (controlName) {
			printDebug(me.name,": ",controlName," activated on ",me.device.name);
            if (controlName == "OSB16") {
                me.device.swap();
            }
		},
		update: func (noti = nil) {			
		},
		exit: func {
			printDebug("Exit ",me.name~" on ",me.device.name);
		},
		links: {
			"OSB17": "PageFCR",
			"OSB18": "PageSMSINV",
		},
		layers: [],
	},

#  ████████  ██████ ███    ██ 
#     ██    ██      ████   ██ 
#     ██    ██      ██ ██  ██ 
#     ██    ██      ██  ██ ██ 
#     ██     ██████ ██   ████ 
#                             
#                             

	PageTCN: {
		name: "PageTCN",
		isNew: 1,
		supportSOI: 0,
		needGroup: 1,
		new: func {
			me.instance = {parents:[DisplaySystem.PageTCN]};
			me.instance.group = nil;
			return me.instance;
		},
		setup: func {
			printDebug(me.name," on ",me.device.name," is being setup");
			me.pageText = me.group.createChild("text")
				.set("z-index", 10)
				.setColor(colorText1)
				.setAlignment("center-center")
				.setTranslation(displayWidthHalf, displayHeightHalf)
				.setFontSize(me.device.fontSize)
				.setText("BLANK");
		},
		enter: func {
			printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = 0;
			}
			me.device.resetControls();
			me.device.controls["OSB11"].setControlText("FCR");
			me.device.controls["OSB16"].setControlText("SWAP");
			me.device.controls["OSB20"].setControlText("TCN",0);
		},
		controlAction: func (controlName) {
			printDebug(me.name,": ",controlName," activated on ",me.device.name);
            if (controlName == "OSB16") {
                me.device.swap();
            }
		},
		update: func (noti = nil) {
			me.pageText.setText("MODE\n"~ehsi.modeText);
			me.mode       = getprop("sim/model/f16/controls/navigation/instrument-mode-panel/mode/rotary-switch-knob");
			me.device.controls["OSB1"].setControlText("CH\n"~getprop("instrumentation/tacan/frequencies/selected-channel")~getprop("instrumentation/tacan/frequencies/selected-channel[4]"));
			me.device.controls["OSB3"].setControlText(ded.dataEntryDisplay.tacanMode);
			if (me.mode != 0 and me.mode != 1) {
				me.range = "OFF";
			} else {
				me.range = getprop("instrumentation/tacan/in-range")?"IN RNG":"OUT OF RNG";
			}
			me.device.controls["OSB5"].setControlText("STATUS\n"~me.range);
		},
		exit: func {
			printDebug("Exit ",me.name~" on ",me.device.name);
		},
		links: {
			"OSB11": "PageFCR",
			"OSB20": "PageMenu",
		},
		layers: ["BULLSEYE"],
	},

#  ████████ ███████ ███████ ████████ 
#     ██    ██      ██         ██    
#     ██    █████   ███████    ██    
#     ██    ██           ██    ██    
#     ██    ███████ ███████    ██    
#                                    
#                                    

	PageTest: {
		name: "PageTest",
		isNew: 1,
		supportSOI: 0,
		needGroup: 1,
		new: func {
			me.instance = {parents:[DisplaySystem.PageTest]};
			me.instance.group = nil;
			return me.instance;
		},
		setup: func {
			printDebug(me.name," on ",me.device.name," is being setup");
			me.pageText = me.group.createChild("text")
				.set("z-index", 10)
				.setColor(colorText1)
				.setAlignment("left-center")
				.setTranslation(displayWidth*0.6, displayHeight*0.8)
				.setFontSize(me.device.fontSize)
				.setText("BBRAM OFPID\nSUROM OFPID");
			me.mfdsGreyTest = me.group.createChild("path")
				.set("z-index", 5)
				.setColor(colorDot2[0]*0.5,colorDot2[1]*0.5,colorDot2[2]*0.5)
				.moveTo(- displayWidth, - displayHeight)
				.lineTo(displayWidth*2, displayHeight*2)
				.setStrokeLineWidth(displayHeight*2)
				.hide();
			me.testMFDS = 0;
		},
		enter: func {
			printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = 0;
			}
			me.device.resetControls();
			me.device.controls["OSB16"].setControlText("SWAP");
			me.device.controls["OSB9"].setControlText("TEST",0);
		},
		controlAction: func (controlName) {
			printDebug(me.name,": ",controlName," activated on ",me.device.name);
			if (controlName == "OSB6") {
				me.testMFDS = !me.testMFDS;
            } elsif (controlName == "OSB16") {
                me.device.swap();
            }
		},
		update: func (noti = nil) {
			me.device.controls["OSB6"].setControlText("MFDS",1,me.testMFDS);
			me.mfdsGreyTest.setVisible(me.testMFDS);
			me.pageText.setVisible(me.testMFDS);
		},
		exit: func {
			printDebug("Exit ",me.name~" on ",me.device.name);
		},
		links: {
			"OSB9": "PageMenu",
		},
		layers: [],
	},

#  ██████  ███████ ███████ ███████ ████████ 
#  ██   ██ ██      ██      ██         ██    
#  ██████  █████   ███████ █████      ██    
#  ██   ██ ██           ██ ██         ██    
#  ██   ██ ███████ ███████ ███████    ██    
#                                           
#                                           

	PageReset: {
		name: "PageReset",
		isNew: 1,
		supportSOI: 0,
		needGroup: 0,
		new: func {
			me.instance = {parents:[DisplaySystem.PageReset]};
			me.instance.group = nil;
			return me.instance;
		},
		setup: func {
			printDebug(me.name," on ",me.device.name," is being setup");
		},
		enter: func {
			printDebug("Enter ",me.name~" on ",me.device.name);
			if (me.isNew) {
				me.setup();
				me.isNew = 0;
			}
			me.device.resetControls();
			me.device.controls["OSB1"].setControlText("MSMD\nRESET");
			me.device.controls["OSB2"].setControlText("PROC DCLT\nRESET");
			me.device.controls["OSB3"].setControlText("NVIS\nOVRD");
			me.device.controls["OSB6"].setControlText("SBC DAY\nRESET");
			me.device.controls["OSB7"].setControlText("SBC NIGHT\nRESET");
			me.device.controls["OSB8"].setControlText("SBC DFLT\nRESET");
			me.device.controls["OSB9"].setControlText("SBC DAY\nSET");
			me.device.controls["OSB10"].setControlText("SBC NIGHT\nSET");
			me.device.controls["OSB11"].setControlText("BLANK");
			me.device.controls["OSB15"].setControlText("RESET\n MENU", 0);
			me.device.controls["OSB16"].setControlText("SWAP");
			me.device.controls["OSB17"].setControlText("FCR");
			me.device.controls["OSB19"].setControlText("DTE");
			me.device.controls["OSB20"].setControlText("DCLT");
		},
		controlAction: func (controlName) {
			printDebug(me.name,": ",controlName," activated on ",me.device.name);
			if (controlName == "OSB16") {
				me.device.swap();
			}
		},
		update: func (noti = nil) {
			
		},
		exit: func {
			printDebug("Exit ",me.name~" on ",me.device.name);
		},
		links: {
			"OSB11":  "PageBlank",
			"OSB15":  "PageMenu",
			"OSB17":  "PageFCR",
			"OSB19":  "PageDTE",
		},
		layers: ["BULLSEYE"],
	},

#  ███████ ███    ██ ██████       ██████  ███████     ██████   █████   ██████  ███████ ███████ 
#  ██      ████   ██ ██   ██     ██    ██ ██          ██   ██ ██   ██ ██       ██      ██      
#  █████   ██ ██  ██ ██   ██     ██    ██ █████       ██████  ███████ ██   ███ █████   ███████ 
#  ██      ██  ██ ██ ██   ██     ██    ██ ██          ██      ██   ██ ██    ██ ██           ██ 
#  ███████ ██   ████ ██████       ██████  ██          ██      ██   ██  ██████  ███████ ███████ 
#                                                                                              
#                                                                                              

};

var flyupTime = 0;
var flyupVis = 0;
updateFlyup = func(notification=nil) {
    #if (me.current_page != nil) {
        flyupTime = getprop("instrumentation/radar/time-till-crash");
        if (flyupTime != nil and flyupTime > 0 and flyupTime < 8) {
            flyupVis = math.mod(getprop("sim/time/elapsed-sec"), 0.50) < 0.25;
        } else {
            flyupVis = 0;
        }
        leftMFD.pullUpCue(flyupVis);
        rightMFD.pullUpCue(flyupVis);
    #}
}

# Cursor stuff
var cursor_pos = [100,-100];
var cursor_posHAS = [0,-256];
var cursor_pos_hsd = [0, -50];
var cursor_click = -1;
var cursor_lock = -1;
var exp = 0;
var slew_c = 0;
var cursorFCRgps = nil;
var cursorFCRair = 1;


setlistener("controls/displays/cursor-click", func (node) {if (node.getValue()) {slew_c = 1;}},0,0);

var cursorZero = func {
    cursor_pos = [0,-256];
}
cursorZero();

var hsdShowNAV1 = 1;
var hsdShowDLINK = 1;
var hsdShowRINGS = 1;
var hsdShowPRE = 1;
var hsdShowFCR = 1;

var fcrFrz = 0;
var fcrBand = 0;
var fcrChan = 2;

var flirMode = -2;
var tfrMode  =  1;
var tfrFreq  =  1;
var tfr_current_terr = 1000;
var tfr_range_m = 1000;
var tfr_target_altitude_m = 0;

var leftMFD = nil;
var rightMFD = nil;

var swapAircraftSOI = func (soi) {
	if (soi != nil) {
		f16.SOI = soi;
	}
}

var F16MfdRecipient =
{
    new: func(_ident)
    {
        var new_class = emesary.Recipient.new(_ident~".MFD2");

        new_class.Receive = func(notification)
        {
            if (notification == nil)
            {
                print("bad notification nil");
                return emesary.Transmitter.ReceiptStatus_NotProcessed;
            }

            if (notification.NotificationType == "FrameNotification16")
            {
            	updateFlyup(notification);
                leftMFD.update(notification);
                rightMFD.update(notification);
                return emesary.Transmitter.ReceiptStatus_OK;
            }
            return emesary.Transmitter.ReceiptStatus_NotProcessed;
        };
        new_class.del = func {
        	emesary.GlobalTransmitter.DeRegister(me);
        };
        return new_class;
    },
};
var f16_mfd = nil;

var vector_aicontacts_links = [];
var DLRecipient = emesary.Recipient.new("DLRecipient");
var startDLListener = func {
    DLRecipient.radar = radar_system.dlnkRadar;
    DLRecipient.Receive = func(notification) {
        if (notification.NotificationType == "DatalinkNotification") {
            #printf("DL recv: %s", notification.NotificationType);
            if (me.radar.enabled == 1) {
                vector_aicontacts_links = notification.vector;
            }
            return emesary.Transmitter.ReceiptStatus_OK;
        }
        return emesary.Transmitter.ReceiptStatus_NotProcessed;
    };
    emesary.GlobalTransmitter.Register(DLRecipient);
}

var switchTGP = func {
	if(getprop("f16/stores/tgp-mounted") and !getprop("/fdm/jsbsim/gear/unit[0]/WOW")) {
        screen.log.write("Click BACK to get back to cockpit view",1,1,1);
    	view.setViewByIndex(105);
    }
}

var get_intercept = func(bearingToRunner, dist_m, runnerHeading, runnerSpeed, chaserSpeed, chaserCoord, chaserHeading) {
    # from Leto
    # needs: bearingToRunner_deg, dist_m, runnerHeading_deg, runnerSpeed_mps, chaserSpeed_mps, chaserCoord
    #        dist_m > 0 and chaserSpeed > 0

    if (dist_m < 500) {
        return nil;
    }

    var trigAngle = 90-bearingToRunner;
    var RunnerPosition = [dist_m*math.cos(trigAngle*D2R), dist_m*math.sin(trigAngle*D2R),0];
    var ChaserPosition = [0,0,0];

    var VectorFromRunner = vector.Math.minus(ChaserPosition, RunnerPosition);
    var runner_heading = 90-runnerHeading;
    var RunnerVelocity = [runnerSpeed*math.cos(runner_heading*D2R), runnerSpeed*math.sin(runner_heading*D2R),0];

    var a = chaserSpeed * chaserSpeed - runnerSpeed * runnerSpeed;
    var b = 2 * vector.Math.dotProduct(VectorFromRunner, RunnerVelocity);
    var c = -dist_m * dist_m;
    
    if (a == 0) a = 1000;# Otherwise same speeds will produce no intercept even though possible.
    var dd = b*b-4*a*c;
    if (dd<0) {
      # intercept not possible
      return nil;
    }

    var t1 = (-b+math.sqrt(dd))/(2*a);
    var t2 = (-b-math.sqrt(dd))/(2*a);

    if (t1 < 0 and t2 < 0) {
      # intercept not possible
      return nil;
    }

    var timeToIntercept = 0;
    if (t1 > 0 and t2 > 0) {
          timeToIntercept = math.min(t1, t2);
    } else {
          timeToIntercept = math.max(t1, t2);
    }
    var InterceptPosition = vector.Math.plus(RunnerPosition, vector.Math.product(timeToIntercept, RunnerVelocity));

    var ChaserVelocity = vector.Math.product(1/timeToIntercept, vector.Math.minus(InterceptPosition, ChaserPosition));

    var interceptAngle = vector.Math.angleBetweenVectors([0,1,0], ChaserVelocity);
    var interceptHeading = geo.normdeg(ChaserVelocity[0]<0?-interceptAngle:interceptAngle);

    var interceptDist = chaserSpeed*timeToIntercept;

    var interceptCoord = geo.Coord.new(chaserCoord);
    interceptCoord = interceptCoord.apply_course_distance(interceptHeading, interceptDist);
    var interceptRelativeBearing = geo.normdeg180(interceptHeading-chaserHeading);

    return [timeToIntercept, interceptHeading, interceptCoord, interceptDist, interceptRelativeBearing];
}

var displayWidth     = 512;#552 * 0.795;
var displayHeight    = 512;#482 * 1;
var displayWidthHalf = displayWidth  *  0.5;
var displayHeightHalf= displayHeight  *  0.5;

var forcePages = func (v, system) {
	if (v == 0) {
        system.selectPage("PageVoid");
    } elsif (v == 1) {
        system.selectPage("PageGrid");
    } elsif (v == 2) {
        system.selectPage("PageCube");
    } elsif (v == 3) {
        if (system.device.name == "LeftMFD") {
            system.selectPage("PageFCR");
        } else {
            system.selectPage("PageHSD");
        }
    }
}

var main = func (module) {
	# TEST CODE:
	var height = 512;#482;
	var width  = 512;#552;

	leftMFD = DisplayDevice.new("LeftMFD", [width,height], [1, 1], "MFDimage1", "tranbg.png");
	leftMFD.setColorBackground(colorBackground);#todo fix

	rightMFD = DisplayDevice.new("RightMFD", [width,height], [1, 1], "MFDimage2", "tranbg.png");
	rightMFD.setColorBackground(colorBackground);

	leftMFD.setControlTextColors(colorText1, colorBackground);
	rightMFD.setControlTextColors(colorText1, colorBackground);

	width *= 1;#0.795;

	var osbPositions = [
		[0, 1.5*height/7],
		[0, 2.5*height/7],
		[0, 3.5*height/7],
		[0, 4.5*height/7],
		[0, 5.5*height/7],

		[width, 1.5*height/7],
		[width, 2.5*height/7],
		[width, 3.5*height/7],
		[width, 4.5*height/7],
		[width, 5.5*height/7],

		[1.35*width/7, 0],
		[2.4*width/7, 0],
		[3.5*width/7, 0],
		[4.6*width/7, 0],
		[5.65*width/7, 0],

		[1.35*width/7, height],
		[2.4*width/7, height],
		[3.5*width/7, height],
		[4.6*width/7, height],
		[5.65*width/7, height],
	];



	leftMFD.setSwapDevice(rightMFD);
	rightMFD.setSwapDevice(leftMFD);

	var mfdSystem1 = DisplaySystem.new();
	var mfdSystem2 = DisplaySystem.new();

	leftMFD.setDisplaySystem(mfdSystem1);
	rightMFD.setDisplaySystem(mfdSystem2);

	mfdSystem1.initDevice(0, osbPositions, 20);
	mfdSystem2.initDevice(1, osbPositions, 20);

	leftMFD.addControlFeedback();
	rightMFD.addControlFeedback();

	mfdSystem1.initPages();
	mfdSystem2.initPages();

	leftMFD.setF16SOI(2);
	rightMFD.setF16SOI(3);

	#theMaster = leftMFD.controls.master;

	forcePages(getprop("/f16/avionics/power-mfd-bit"), mfdSystem1);
	forcePages(getprop("/f16/avionics/power-mfd-bit"), mfdSystem2);

	f16_mfd = F16MfdRecipient.new("F16-MFD2");
	emesary.GlobalTransmitter.Register(f16_mfd);
}

#var theMaster = nil;

var unload = func {
	if (leftMFD != nil) {
		leftMFD.del();
		leftMFD = nil;
	}
	if (rightMFD != nil) {
		rightMFD.del();
		rightMFD = nil;
	}
	DisplayDevice = nil;
	DisplaySystem = nil;
	f16_mfd.del();
}

var debugDisplays = 0;
var printDebug = func {if (debugDisplays) {call(print,arg,nil,nil,var err = []); if(size(err)) print (err[0]);}};
var printfDebug = func {if (debugDisplays) {var str = call(sprintf,arg,nil,nil,var err = []);if(size(err))print (err[0]);else print (str);}};
# Note calling printf directly with call() will sometimes crash the sim, so we call sprintf instead.


main(nil);# disable this line if running as module

#TODO:
#      rockerbuttons as controls
#      crash from GM when ran as module
#      HSDCNTL/FCRCNTL/MENU/FCRMENU should be an overlay
#      HSD: MSG page with max 9 lines of 15 chars. MLU1 page 35.
#      HSD: OSB8 FRZ freeze
#      FCR: OVRD
#      TGP and HUD-FLIR not work on mac
#      More FLIR info at 1-249 (265) of dash-34
#      More TFR 1-333 (349) + 1-242 (258)
#      Aircraft Ref. Symbol and steering bars: dash-34 (new) 1-77
#      MLU 4.3:To provide feedback that an OSB has actually been depressed,
#        the display surface near a specific OSB flashes momentarily when the OSB is depressed.
#      FLIR: 21x28 degs
#      Lookup tables for z-index, symbol sizes, font sizes, line thickness
#          Done: Device, HSD, bullseye, arrows, (sms-inv, sms-sj,) tfr, grid, cube, flir, has, fcr
#          Todo: z-index, font sizes
#          Issues: SMS INV/S-J still pixel based
#                  6% x 16% larger resolution might make some symbols appear smaller.