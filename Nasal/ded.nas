var pTACAN = 0;
var pALOW  = 1;
var pFACK  = 2;
var pSTPT  = 3;
var pCRUS  = 4;
var pTIME  = 5;
var pMARK  = 6;
var pFIX   = 7;
var pACAL  = 8;

var pLIST  = 100; # excluded from random
var pDEST  = 9;
var pBINGO = 10;
var pVIP   = 11;
var pNAV   = 12;
var pMAN   = 13;
var pINS   = 14;
var pEWS   = 15;
var pMODE  = 16;
var pVRP   = 17;
var pINTG  = 18;
var pDLNK  = 19;

var pMISC  = 201; # excluded from random
var pCORR  = 20;
var pMAGV  = 21;
var pOFP   = 22;
var pINSM  = 23;
var pLASR  = 24;
var pGPS   = 25;
var pDRNG  = 26;
var pBULL  = 27;
var pWPT   = 28;
var pHARM  = 29;

var pCNI   = 30;
var pCOMM1 = 31;
var pCOMM2 = 32;
var pIFF   = 33;

var Actions = {
	Tacan: {
		mSel: Action.new(pTACAN, toggleTACANBand),
	},
	Time: {
		toggleHack: Action.new(pTIME, toggleHack),
		resetHack: Action.new(pTIME, resetHack),
	},
	Mark: {
		mSel: Action.new(pMARK, modeSelMark),
	},	
	Fix: {
		mSel: Action.new(pFIX, modeSelFix),
	},	
	Acal: {
		mSel: Action.new(pACAL, modeSelAcal),
	},	
};

var Routers = {
	tacanRouter: Router.new(pCNI, pTACAN),
	alowRouter: Router.new(pCNI, pALOW),
	fackRouter: Router.new(pCNI, pFACK),
	stptRouter: Router.new(pCNI, pSTPT),
	crusRouter: Router.new(pCNI, pCRUS),
	timeRouter: Router.new(pCNI, pTIME),
	fixRouter: Router.new(pCNI, pFIX),
	markRouter: Router.new(pCNI, pMARK),
	acalRouter: Router.new(pCNI, pACAL),
	List: {
		destRouter: Router.new(pLIST, pDEST),
		bingoRouter: Router.new(pLIST, pBINGO),
		navRouter: Router.new(pLIST, pNAV),
		manRouter: Router.new(pLIST, pMAN),
		insRouter: Router.new(pLIST, pINS),
		ewsRouter: Router.new(pLIST, pEWS),
		dlnkRouter: Router.new(pLIST, pDLNK),
		modeRouter: Router.new(pLIST, pMODE),
		miscRouter: Router.new(pLIST, pMISC),
	},
	Misc: {
		magvRouter: Router.new(pMISC, pMAGV),
	},
	comm1Router: Router.new(nil, pCOMM1),
	comm2Router: Router.new(nil, pCOMM2),
	iffRouter: Router.new(nil, pIFF),
	listRouter: Router.new(nil, pLIST),
};

var RouterVectors = {
	button1: [Routers.List.destRouter, Routers.tacanRouter],
	button2: [Routers.List.bingoRouter, Routers.Misc.magvRouter,Routers.alowRouter],
	button3: [Routers.fackRouter],
	button4: [Routers.List.navRouter, Routers.stptRouter],
	button5: [Routers.List.manRouter, Routers.crusRouter],
	button6: [Routers.List.insRouter, Routers.timeRouter],
	button7: [Routers.List.ewsRouter, Routers.markRouter],
	button8: [Routers.List.modeRouter, Routers.fixRouter],
	button9: [Routers.acalRouter],
	button0: [Routers.List.miscRouter],
	buttonComm1: [Routers.comm1Router],
	buttonComm2: [Routers.comm2Router],
	buttonIFF: [Routers.iffRouter],
	buttonList: [Routers.listRouter],
	buttonEnter: [Routers.List.dlnkRouter],
};

var ActionVectors = {
	button1: [],
	button2: [],
	button3: [],
	button4: [],
	button5: [],
	button6: [],
	button7: [],
	button8: [],
	button9: [],
	button0: [Actions.Tacan.mSel,Actions.Mark.mSel,Actions.Fix.mSel,Actions.Acal.mSel],
	buttonup: [Actions.Time.toggleHack],
	buttondown: [Actions.Time.resetHack],
};

var Buttons = {
	button1: Button.new(routerVec: RouterVectors.button1, To9: 1),
	button2: Button.new(routerVec: RouterVectors.button2, To9: 1),
	button3: Button.new(routerVec: RouterVectors.button3, To9: 1),
	button4: Button.new(routerVec: RouterVectors.button4, To9: 1),
	button5: Button.new(routerVec: RouterVectors.button5, To9: 1),
	button6: Button.new(routerVec: RouterVectors.button6, To9: 1),
	button7: Button.new(routerVec: RouterVectors.button7, To9: 1),
	button8: Button.new(routerVec: RouterVectors.button8, To9: 1),
	button9: Button.new(routerVec: RouterVectors.button9, To9: 1),
	button0: Button.new(actionVec: ActionVectors.button0, routerVec: RouterVectors.button0),
	buttoncomm1: Button.new(routerVec: RouterVectors.buttonComm1),
	buttoncomm2: Button.new(routerVec: RouterVectors.buttonComm2),
	buttoniff: Button.new(routerVec: RouterVectors.buttonIFF),
	buttonlist: Button.new(routerVec: RouterVectors.buttonList),
	buttonup: Button.new(actionVec: ActionVectors.buttonup),
	buttondown: Button.new(actionVec: ActionVectors.buttondown),
	entr: Button.new(routerVec: RouterVectors.buttonEnter),
	rcl: Button.new(),
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
	page: 30,
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
			me.updateTacan();
		} elsif (me.page == pALOW) {
			me.updateAlow();
		} elsif (me.page == pFACK) {
			me.updateFack();
		} elsif (me.page == pSTPT) {
			me.updateStpt();
		} elsif (me.page == pCRUS) {
			me.updateCrus();
		} elsif (me.page == pTIME) {
			me.updateTime();
		} elsif (me.page == pMARK) {
			me.updateMark();
		}  elsif (me.page == pFIX) {
			me.updateFix();
		} elsif (me.page == pACAL) {
			me.updateAcal();
		} elsif (me.page == pLIST) {
			me.updateList();
		} elsif (me.page == pDEST) {
			me.updateDest();
		} elsif (me.page == pBINGO) {
			me.updateBingo();
		} elsif (me.page == pNAV) {
			me.updateNav();
		} elsif (me.page == pMAN) {
			me.updateMan();
		} elsif (me.page == pINS) {
			me.updateINS();
		} elsif (me.page == pEWS) {
			me.updateEWS();
		} elsif (me.page == pMODE) {
			me.updateMode();
		} elsif (me.page == pINTG) {
			me.updateIntg();
		} elsif (me.page == pDLNK) {
			me.updateDlnk();
		} elsif (me.page == pMISC) {
			me.updateMisc();
		} elsif (me.page == pCNI) {
			me.updateCNI();
		} elsif (me.page == pIFF) {
			me.updateIFF();
		}
		
		me.line1.setText(me.text[0]);
		me.line2.setText(me.text[1]);
		me.line3.setText(me.text[2]);
		me.line4.setText(me.text[3]);
		me.line5.setText(me.text[4]);
		
		settimer(func() { me.update(); }, 0.5);
	},
	
	tacanMode: "REC    ",
	updateTacan: func() {
		var ilsOn  = (getprop("sim/model/f16/controls/navigation/instrument-mode-panel/mode/rotary-switch-knob") == 0 or getprop("sim/model/f16/controls/navigation/instrument-mode-panel/mode/rotary-switch-knob") == 3)?"ON ":"OFF";
		var ident = getprop("instrumentation/tacan/ident");
		var inrng = getprop("instrumentation/tacan/in-range");	
		  
		me.text[0] = sprintf("TCN %s  ILS %s",me.tacanMode,ilsOn);
		me.text[1] = sprintf("                        ");
		if (!inrng or ident == nil or ident == "") {
			me.text[2] = sprintf("               CMD STRG ", ident);
		} else {
			me.text[2] = sprintf("BCN %s        CMD STRG ", ident);
		}
		
		me.text[3] = sprintf("CHAN %-3d    FRQ  %6.2f",getprop("instrumentation/tacan/frequencies/selected-channel"),getprop("instrumentation/nav[0]/frequencies/selected-mhz"));
		me.text[4] = sprintf("BAND %s(0)   CRS  %03.0f\xc2\xb0",getprop("instrumentation/tacan/frequencies/selected-channel[4]"),getprop("f16/crs-ils"));
	},
	
	updateAlow: func() {
		me.text[0] = sprintf("         ALOW       %s  ",me.no);
		me.text[1] = sprintf("                        ");
		me.text[2] = sprintf("   CARA ALOW %5dFT    ", getprop("f16/settings/cara-alow"));
		me.text[3] = sprintf("   MSL FLOOR %5dFT    ", getprop("f16/settings/msl-floor"));
		me.text[4] = sprintf("TF ADV (MSL)   400FT    ");
	},	
	
	updateFack: func() {
		var fails = fail.getList();
		var last = size(fails);
		me.scrollF += 0.25;
		if (me.scrollF >= last-2) me.scrollF = 0;     
		var used = subvec(fails,int(me.scrollF),3);
		me.text[0] = sprintf("       F-ACK     %s     ",me.no);
		me.text[1] = sprintf("                        ");
		if (size(used)>0) me.text[2] = sprintf(" %s ",used[0]);
		else me.text[2] = "";
		if (size(used)>1) me.text[3] = sprintf(" %s ",used[1]);
		else me.text[3] = "";
		if (size(used)>2) me.text[4] = sprintf(" %s ",used[2]);
		else me.text[4] = "";
	},
	
	updateStpt: func() {
		var fp = flightplan();
		var TOS = "--:--:--";
		var lat = "";
		var lon = "";
		var alt = -1;
		if (fp != nil) {
			var wp = fp.currentWP();
			if (wp != nil and getprop("f16/avionics/power-mmc")) {
				lat = convertDegreeToStringLat(wp.lat);
				lon = convertDegreeToStringLon(wp.lon);
				alt = wp.alt_cstr;
				if (alt == nil) {
					alt = -1;
				}
				var hour   = getprop("sim/time/utc/hour"); 
				var minute = getprop("sim/time/utc/minute");
				var second = getprop("sim/time/utc/second");
				var eta    = getprop("autopilot/route-manager/wp/eta");
				if (eta == nil or getprop("autopilot/route-manager/wp/eta-seconds")>3600*24) {
					#
				} elsif (getprop("autopilot/route-manager/wp/eta-seconds")>3600) {
					eta = split(":",eta);
					minute += num(eta[1]);
					var addOver = 0;
					if (minute > 59) {
						addOver = 1;
						minute -= 60;
					}
					hour += num(eta[0])+addOver;
					while (hour > 23) {
						hour -= 24;
					}
					TOS = sprintf("%02d:%02d:%02d",hour,minute,second);
				} else {
					eta = split(":",eta);
					second += num(eta[1]);
					var addOver = 0;
					if (second > 59) {
						addOver = 1;
						second -= 60;
					}
					minute += num(eta[0])+addOver;
					addOver = 0;
					if (minute > 59) {
						addOver = 1;
						minute -= 60;
					}
					hour += addOver;
					while (hour > 23) {
						hour -= 24;
					}
					TOS = sprintf("%02d:%02d:%02d",hour,minute,second);   
				}          
			}
		}
      
		me.text[0] = sprintf("         STPT %s    AUTO",me.no);
		me.text[1] = sprintf("      LAT  %s",lat);
		me.text[2] = sprintf("      LNG  %s",lon);
		me.text[3] = sprintf("     ELEV  % 5dFT",alt);
		me.text[4] = sprintf("      TOS  %s",TOS);
	},
	
	updateCrus: func() {
		var fuel   = "";
		var fp = flightplan();
		var maxS = "";
		if (fp != nil) {
			var max = fp.getPlanSize();
			if (max > 0) {
				maxS =""~max;
				var ete = getprop("autopilot/route-manager/ete");
				if (ete != nil and ete > 0) {
					var pph = getprop("engines/engine[0]/fuel-flow_pph");
					if (pph == nil) pph = 0;
					fuel = sprintf("% 6dLBS",pph*(ete/3600));
					if (size(fuel)>9) {
						fuel = "999999LBS";
					}
				}
			}
		}
		var windkts = getprop("environment/wind-speed-kt");
		var winddir = getprop("environment/wind-from-heading-deg");
		if (windkts == nil or winddir == nil) {
			windkts = -1;
			winddir = -1;
		}
		windkts = sprintf("% 3dKTS",getprop("environment/wind-speed-kt"));
		winddir = sprintf("%03d\xc2\xb0",getprop("environment/wind-from-heading-deg"));
		me.text[0] = sprintf("     CRUS  RNG  ",me.no);
		me.text[1] = sprintf("     STPT  %s  ",maxS);
		me.text[2] = sprintf("     FUEL %s",fuel);#fuel used to get to last steerpoint at current fuel consumption.
		me.text[3] = sprintf("                        ");
		me.text[4] = sprintf("     WIND  %s %s",winddir,windkts);
	},
	
	updateTime: func() {
		var time = getprop("/sim/time/gmt-string");
		var hackHour = int(getprop("f16/avionics/hack/elapsed-time-sec") / 3600);
		var hackMin = int((getprop("f16/avionics/hack/elapsed-time-sec") - (hackHour * 3600)) / 60);
		var hackSec = int(getprop("f16/avionics/hack/elapsed-time-sec") - (hackHour * 3600) - (hackMin * 60));
		var hackTime = sprintf("%02.0f", hackHour) ~ ":" ~ sprintf("%02.0f", hackMin) ~ ":" ~ sprintf("%02.0f", hackSec);
		var date = sprintf("%02.0f", getprop("/sim/time/utc/month")) ~ "/" ~ sprintf("%02.0f", getprop("/sim/time/utc/day")) ~ "/" ~ right(sprintf("%s", getprop("/sim/time/utc/year")), 2);
		me.text[0] = sprintf("          TIME      %s  ",me.no);
		if (getprop("f16/avionics/power-gps") and getprop("sim/variant-id") != 1 and getprop("sim/variant-id") != 3) {
			me.text[1] = sprintf("GPS SYSTEM      %s",time);
		} else {
			me.text[1] = sprintf("    SYSTEM      %s",time);
		}
		me.text[2] = sprintf("      HACK      %s", hackTime);
		me.text[3] = sprintf(" DELTA TOS      00:00:00   ");
		if (getprop("sim/variant-id") != 1 and getprop("sim/variant-id") != 3) {
			me.text[4] = sprintf("  MM/DD/YY      %s", date);
		} else {
			me.text[4] = sprintf("                          ");
		}
	},
	
	# the Mark page is supposed to be for creating steerpoints 26 --> 30. Until we have a list of 30 steerpoints, 
	# we will make this show current position since that is what it does anyway
	markMode: "OFLY",
	markModeSelected: 1,
	updateMark: func() {
		lat = convertDegreeToStringLat(getprop("/position/latitude-deg"));
		lon = convertDegreeToStringLon(getprop("/position/latitude-deg"));
		alt = getprop("/position/altitude-ft") - getprop("/position/altitude-agl-ft");
		if (me.markModeSelected) {
			me.text[0] = sprintf("         MARK *%s*    %s",me.markMode,me.no);
		} else {
			me.text[0] = sprintf("         MARK  %s     %s",me.markMode,me.no);
		}
		me.text[1] = sprintf("      LAT  %s",lat);
		me.text[2] = sprintf("      LNG  %s",lon);
		me.text[3] = sprintf("     ELEV  % 5dFT",alt);
		me.text[4] = sprintf("                 ");
	},
	
	fixTakingMode: "OFLY",
	fixTakingModeSelected: 1,
	updateFix: func() {
		if (me.fixTakingModeSelected) {
			me.text[0] = sprintf("          FIX  *%s*", me.fixTakingMode);
		} else {
			me.text[0] = sprintf("          FIX   %s", me.fixTakingMode);
		}
		me.text[1] = sprintf("     STPT   %s", me.no);
		me.text[2] = sprintf("    DELTA       0NM", );
		me.text[3] = sprintf("SYS ACCUR     HIGH");
		me.text[4] = sprintf("GPS ACCUR     HIGH");
	},
	
	acalMode: "GPS",
	acalModeSelected: 1,
	updateAcal: func() {
		if (me.acalModeSelected) {
			me.text[0] = sprintf(" ACAL    *%s* %s", me.acalMode, me.no);
		} else {
			me.text[0] = sprintf(" ACAL     %s  %s", me.acalMode, me.no);
		}
		me.text[1] = sprintf("          AUTO");
		me.text[2] = sprintf("                 ");
		me.text[3] = sprintf("                 ");
		me.text[4] = sprintf("                 ");
	},
	
	updateList: func() {
		me.text[0] = sprintf("           LIST      12 ");
		me.text[1] = sprintf(" 1DEST 2BNGO 3VIP RINTG ");
		me.text[2] = sprintf(" 4NAV  5MAN  6INS EDLNK ");
		me.text[3] = sprintf(" 7EWS  8MODE 9VRP OMISC ");
		me.text[4] = sprintf("                        ");
	},
	
	updateDest: func() {
		var fp = flightplan();
		var TOS = "--:--:--";
		var lat = "";
		var lon = "";
		var alt = -1;
		if (fp != nil) {
			var wp = fp.destination;
			if (wp != nil and getprop("f16/avionics/power-mmc")) {
				lat = convertDegreeToStringLat(wp.lat);
				lon = convertDegreeToStringLon(wp.lon);
				alt = wp.elevation * M2FT;
				var hour   = getprop("sim/time/utc/hour"); 
				var minute = getprop("sim/time/utc/minute");
				var second = getprop("sim/time/utc/second");
				var eta    = getprop("autopilot/route-manager/wp/eta");
				if (eta == nil or getprop("autopilot/route-manager/wp/eta-seconds")>3600*24) {
					#
				} elsif (getprop("autopilot/route-manager/wp/eta-seconds")>3600) {
					eta = split(":",eta);
					minute += num(eta[1]);
					var addOver = 0;
					if (minute > 59) {
						addOver = 1;
						minute -= 60;
					}
					hour += num(eta[0])+addOver;
					while (hour > 23) {
						hour -= 24;
					}
					TOS = sprintf("%02d:%02d:%02d",hour,minute,second);
				} else {
					eta = split(":",eta);
					second += num(eta[1]);
					var addOver = 0;
					if (second > 59) {
						addOver = 1;
						second -= 60;
					}
					minute += num(eta[0])+addOver;
					addOver = 0;
					if (minute > 59) {
						addOver = 1;
						minute -= 60;
					}
					hour += addOver;
					while (hour > 23) {
						hour -= 24;
					}
					TOS = sprintf("%02d:%02d:%02d",hour,minute,second);   
				}          
			}
		}
      
		me.text[0] = sprintf("         DEST  DIR  %s",me.no);
		me.text[1] = sprintf("      LAT  %s",lat);
		me.text[2] = sprintf("      LNG  %s",lon);
		me.text[3] = sprintf("     ELEV  % 5dFT",alt);
		me.text[4] = sprintf("      TOS  %s",TOS);
	},
	
	updateBingo: func() {
		var bingo = getprop("f16/settings/bingo");
		me.text[0] = sprintf("        BINGO       %s  ",me.no);
		me.text[1] = sprintf("                        ");
		me.text[2] = sprintf("    SET    %5dLBS      ",bingo);
		me.text[3] = sprintf("  TOTAL    %5dLBS      ",getprop("consumables/fuel/total-fuel-lbs"));
		me.text[4] = sprintf("                        ");
	},
	
	updateNav: func() {
		var days = 31 - getprop("/sim/time/utc/day");
		me.text[0] = sprintf("    NAV STATUS        %s",me.no);
		me.text[1] = sprintf("SYS ACCUR     HIGH");
		me.text[2] = sprintf("GPS ACCUR     HIGH");
		me.text[3] = sprintf("MSN DUR       %s  DAYS", days);
		me.text[4] = sprintf("KEYS          VERIFIED");
	},
	
	updateMan: func() {
		me.text[0] = sprintf("      MAN        %s",me.no);
		me.text[1] = sprintf("WSPAN     30FT");
		me.text[2] = sprintf("      MBAL    ");
		me.text[3] = sprintf("RNG      2000FT  ");
		me.text[4] = sprintf("TOF      5.4SEC ");
	},
	
	updateINS: func() {
		lat = convertDegreeToStringLat(getprop("position/latitude-deg"));
		lon = convertDegreeToStringLon(getprop("position/longitude-deg"));
		me.text[0] = sprintf("  INS   10.2/10  %s",me.no);
		me.text[1] = sprintf("  LAT  %s",lat);
		me.text[2] = sprintf("  LNG  %s",lon);
		me.text[3] = sprintf("  SALT  %5dFT",getprop("position/altitude-ft"));
		me.text[3] = sprintf("THDG %5.1f\xc2\xb0     G/S %3d",getprop("orientation/true-heading-deg"),getprop("velocities/groundspeed-kt"));
	},
	
	updateEWS: func() {
		var flares = getprop("ai/submodels/submodel[0]/count");
		var jammer = getprop("f16/avionics/ew-jmr-switch") ? " ON" : "OFF";
		me.text[0] = sprintf("        EWS CONTROLS  %s",me.no);
		me.text[1] = sprintf(" CH %3d     REQJAM   %s", flares, jammer);
		me.text[2] = sprintf(" FL %3d     FDBK      ON", flares);
		me.text[3] = sprintf(" MODE %s  REQCTR    ON", getprop("f16/avionics/ew-mode-knob") == 1 ? "MAN " : "OFF ");
		me.text[4] = sprintf("            BINGO     ON");
	},
	
	updateMode: func() {
		me.text[0] = sprintf("        MODE *NAV*     %s",me.no);
		me.text[1] = sprintf("                        ");
		me.text[2] = sprintf("                        ");
		me.text[3] = sprintf("                        ");
		me.text[4] = sprintf("                        ");
	},
	
	updateIntg: func() {
	
	},
	
	updateDlnk: func() {
		me.text[0] = sprintf("        DLNK           %s",me.no);
		if (getprop("f16/avionics/power-dl")) {
			var last = 0;
			if (getprop("link16/wingman-12")!="") last = 12;
			elsif (getprop("link16/wingman-11")!="") last = 11;
			elsif (getprop("link16/wingman-10")!="") last = 10;
			elsif (getprop("link16/wingman-9")!="") last = 9;
			elsif (getprop("link16/wingman-8")!="") last = 8;
			elsif (getprop("link16/wingman-7")!="") last = 7;
			elsif (getprop("link16/wingman-6")!="") last = 6;
			elsif (getprop("link16/wingman-5")!="") last = 5;
			elsif (getprop("link16/wingman-4")!="") last = 4;
			elsif (getprop("link16/wingman-3")!="") last = 3;
			elsif (getprop("link16/wingman-2")!="") last = 2;
			elsif (getprop("link16/wingman-1")!="") last = 1;
			scroll += 0.25;
			if (scroll >= last-3) scroll = 0;
			var wingmen = [getprop("link16/wingman-1"),getprop("link16/wingman-2"),getprop("link16/wingman-3"),getprop("link16/wingman-4"),getprop("link16/wingman-5"),getprop("link16/wingman-6"),getprop("link16/wingman-7"),getprop("link16/wingman-8"),getprop("link16/wingman-9"),getprop("link16/wingman-10"),getprop("link16/wingman-11"),getprop("link16/wingman-12")];
			var used = subvec(wingmen,int(scroll),4);
			me.text[1] = sprintf("#%d %7s      COMM VHF",int(scroll+1),used[0]);
			me.text[2] = sprintf("#%d %7s      DATA 16K",int(scroll+2),used[1]);
			me.text[3] = sprintf("#%d %7s      OWN  #0 ",int(scroll+3),used[2]);
			me.text[4] = sprintf("#%d %7s      LAST #%d ",int(scroll+4),used[3],last);
		} else {
			me.text[1] = sprintf("  NO DLINK DATA ");
			me.text[2] = sprintf("                        ");
			me.text[3] = sprintf("                        ");
			me.text[4] = sprintf("                        ");
		}
	},
	
	updateMisc: func() {
		me.text[0] = sprintf("           MISC      %s ", me.no);
		me.text[1] = sprintf(" 1CORR 2MAGV 3OFP R     ");
		me.text[2] = sprintf(" 4INSM 5LASR 6GPS E     ");
		me.text[3] = sprintf(" 7DRNG 8BULL 9WPT OHARM ");
		me.text[4] = sprintf("                        ");
	},
	
	updateCNI: func() {
		winddir = sprintf("%03d\xc2\xb0",getprop("environment/wind-from-heading-deg"));
		windkts = sprintf("%03d",getprop("environment/wind-speed-kt"));
		me.text[0] = sprintf("UHF   242.10    STPT %s ", me.no);
		me.text[1] = sprintf("                %s %s", winddir, windkts);
		me.text[2] = sprintf("VHF   10        %s", getprop("/sim/time/gmt-string"));
		if (me.chrono.running) {
			var hackHour = int(getprop("f16/avionics/hack/elapsed-time-sec") / 3600);
			var hackMin = int((getprop("f16/avionics/hack/elapsed-time-sec") - (hackHour * 3600)) / 60);
			var hackSec = int(getprop("f16/avionics/hack/elapsed-time-sec") - (hackHour * 3600) - (hackMin * 60));
			var hackTime = sprintf("%02.0f", hackHour) ~ ":" ~ sprintf("%02.0f", hackMin) ~ ":" ~ sprintf("%02.0f", hackSec);
			me.text[3] = sprintf("                %s", hackTime);
		} else {
			me.text[3] = sprintf(" ");
		}
		me.text[4] = sprintf("M1 3C4 M4 %04d     T%03.0f%s",getprop("instrumentation/transponder/id-code"), getprop("instrumentation/tacan/frequencies/selected-channel"), getprop("instrumentation/tacan/frequencies/selected-channel[4]"));
	},
	
	updateComm1: func() {
	
	},
	
	updateComm2: func() {
	
	},
	
	updateIFF: func() {
		var target = awg_9.active_u;
		var sign = "";
		var type = "";
		var friend = "";
		if (target != nil) {
			sign = target.get_Callsign();
			type = target.get_model();
		}
		if (getprop("f16/avionics/power-dl") and sign != "" and (sign == getprop("link16/wingman-1") or sign == getprop("link16/wingman-2") or sign == getprop("link16/wingman-3") or sign == getprop("link16/wingman-4") or sign == getprop("link16/wingman-5") or sign == getprop("link16/wingman-6") or sign == getprop("link16/wingman-7") or sign == getprop("link16/wingman-8") or sign == getprop("link16/wingman-9") or sign == getprop("link16/wingman-10") or sign == getprop("link16/wingman-11") or sign == getprop("link16/wingman-12"))) {
			friend = "WINGMAN";
		} elsif (sign != "") {
			friend = "NO CONN";
		}
		var iffcode = getprop("instrumentation/iff/channel-selection");
		var pond   = getprop("instrumentation/transponder/inputs/knob-mode")==0?0:1;
		if (pond) pond = sprintf("%04d",getprop("instrumentation/transponder/id-code"));
		else pond = "----";
		me.text[0] = sprintf("IFF   ON   MAN          ");
		me.text[1] = sprintf("M3     %s             ", pond);
		me.text[2] = sprintf("M4     %04d             ", iffcode);
		me.text[3] = sprintf("PILOT   %s",sign);
		me.text[4] = sprintf("TYPE    %s",type);
	},
};

setlistener("f16/avionics/rtn-seq", func() {
	if (getprop("f16/avionics/rtn-seq") == -1) {
		dataEntryDisplay.page = pCNI;
	} elsif (getprop("f16/avionics/rtn-seq") == 1) {
		if (dataEntryDisplay.page == pTACAN) {
			toggleTACANMode();
			return;
		}
		
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
}, 0, 0);