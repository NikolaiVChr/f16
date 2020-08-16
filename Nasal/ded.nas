var pTACAN = 0;
var pALOW  = 1;
var pSTPT  = 2;
var pTIME  = 3;
var pIFF   = 4;
var pCNI   = 5;
var pBINGO = 6;
var pMAGV  = 7;
var pLINK  = 8;
var pLASER = 9;
var pCM    = 10;
var pCRUS  = 11;
var pFACK  = 12;
var pLIST  = 100; # excluded from random
var pMISC  = 101; # excluded from random

var Actions = {
	Time: {
		toggleHackAction: Action.new(pTIME, toggleHack),
		resetHackAction: Action.new(pTIME, resetHack),
	},
};

var Routers = {
	tacanRouter: Router.new(nil, pTACAN),
	List: {
		bingoRouter: Router.new(pLIST, pBINGO),
	},
	Misc: {
		magvRouter: Router.new(pMISC, pMAGV),
	},
};

var RouterVectors = {
	button1: [Routers.tacanRouter],
	button2: [Routers.List.bingoRouter, Routers.Misc.magvRouter],
};

var Buttons = {
	button1: Button.new(routerVec: RouterVectors.button1),
	button2: Button.new(routerVec: RouterVectors.button2),
	button3: Button.new(),
	button4: Button.new(),
	button5: Button.new(),
	button6: Button.new(),
	button7: Button.new(),
	button8: Button.new(),
	button9: Button.new(),
	button0: Button.new(),
	buttoncomm1: Button.new(),
	buttoncomm2: Button.new(),
	buttoniff: Button.new(),
	buttonlist: Button.new(),
	buttonup: Button.new(),
	buttondown: Button.new(),
};

var dataEntryDisplay = {
	line1: nil,
	line2: nil,
	line3: nil,
	line4: nil,
	line5: nil,
	canvasNode: nil,
	canvasGroup: nil,
	chrono: aircraft.timer.new("f16/avionics/hack/elapsed-time-sec", 1, 0),
	comm: 0,
	text: ["","","","",""],
	scroll: 0,
	scrollF: 0,
	page: int(rand()*11.99),
	init: func() {
		me.canvasNode = canvas.new({
			"name": "DED",
			"size": [256, 128],
			"view": [256, 128],
			"mipmapping": 0
		});
		  
		me.canvasNode.addPlacement({"node": "poly.003", "texture": "canvas.png"});
		if (getprop("sim/variant-id") == 2) {
			me.canvasNode.setColorBackground(0.00, 0.04, 0.01, 1.00);
		} else if (getprop("sim/variant-id") == 4) {
			me.canvasNode.setColorBackground(0.00, 0.04, 0.01, 1.00);
		} else if (getprop("sim/variant-id") == 5) {
			me.canvasNode.setColorBackground(0.00, 0.04, 0.01, 1.00);
		} else if (getprop("sim/variant-id") == 6) {
			me.canvasNode.setColorBackground(0.00, 0.04, 0.01, 1.00);
		} else {
			me.canvasNode.setColorBackground(0.01, 0.075, 0.00, 1.00);
		}

		me.canvasGroup = me.canvasNode.createGroup();
		me.canvasGroup.show();

		me.line1 = me.createText(0.2);
		me.line2 = me.createText(0.3);
		me.line3 = me.createText(0.4);
		me.line4 = me.createText(0.5);
		me.line5 = me.createText(0.6);
		#me.update();
	},
	
	createText: func(translationOffset) {
		var obj = me.canvasGroup.createChild("text")
			.setFontSize(13, 1)
			.setColor(0.45,0.98,0.06)
			.setAlignment("left-bottom-baseline")
			.setFont("LiberationFonts/LiberationMono-Bold.ttf")
			.setText("LINE                LINE")
			.setTranslation(50, 128*translationOffset);
		return obj;
	},
	
	no: "",
	update: func() {
		me.no = getprop("autopilot/route-manager/current-wp") + 1;
		if (me.no == 0) {
		  me.no = "";
		} else {
		  me.no = sprintf("%2d",me.no);
		}
		
		if (me.page == pTACAN) {
			var ilsOn  = (getprop("sim/model/f16/controls/navigation/instrument-mode-panel/mode/rotary-switch-knob") == 0 or getprop("sim/model/f16/controls/navigation/instrument-mode-panel/mode/rotary-switch-knob") == 3)?"ON ":"OFF";
			var ident = getprop("instrumentation/tacan/ident");
			var inrng = getprop("instrumentation/tacan/in-range");	
			  
			me.text[0] = sprintf("TCN REC          ILS %s",ilsOn);
			me.text[1] = sprintf("                        ");
			if (!inrng or ident == nil or ident == "") {
				me.text[2] = sprintf("            CMD STRG ", ident);
			} else {
				me.text[2] = sprintf("BCN     %s CMD STRG ", ident);
			}
			me.text[3] = sprintf("CHAN    %-3d FRQ  %6.2f",getprop("instrumentation/tacan/frequencies/selected-channel"),getprop("instrumentation/nav[0]/frequencies/selected-mhz"));
			me.text[4] = sprintf("BAND    %s   CRS  %03.0f\xc2\xb0",getprop("instrumentation/tacan/frequencies/selected-channel[4]"),getprop("f16/crs-ils"));
		}
		
		me.line1.setText(me.text[0]);
		me.line2.setText(me.text[1]);
		me.line3.setText(me.text[2]);
		me.line4.setText(me.text[3]);
		me.line5.setText(me.text[4]);
		
		settimer(func() { me.update(); }, 0.5);
	}
};