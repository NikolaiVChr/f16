var COLOR_YELLOW     = [1.00,1.00,0.00];
var COLOR_BLUE_LIGHT = [0.50,0.50,1.00];
var COLOR_SKY_LIGHT  = [0.30,0.30,1.00];
var COLOR_RED        = [1.00,0.00,0.00];
var COLOR_WHITE      = [1.00,1.00,1.00];
var COLOR_BROWN      = [0.71,0.40,0.11];
var COLOR_BROWN_DARK = [0.56,0.32,0.09];
var COLOR_GRAY       = [0.25,0.25,0.25,0.50];
var COLOR_GRAY_LIGHT = [0.75,0.75,0.75,0.50];
var COLOR_SKY_DARK   = [0.15,0.15,0.60];
var COLOR_BLACK      = [0.00,0.00,0.00];

var str = func (d) {return ""~d};

var MM2TEX = 2;
var texel_per_degree = 2*MM2TEX;
var KT2KMH = 1.85184;

# map setup

var tile_size = 256;

var type = "light_nolabels";

# index   = zoom level
# content = meter per pixel of tiles
#                   0                             5                               10                               15                      19
var meterPerPixel = [156412,78206,39103,19551,9776,4888,2444,1222,610.984,305.492,152.746,76.373,38.187,19.093,9.547,4.773,2.387,1.193,0.596,0.298];# at equator
var zoomsSEU      = [6, 7, 8, 9, 10, 13];# south europe
var zooms         = zoomsSEU;
var zoomLevels = [320, 160, 80, 40, 20, 2.5];
var zoom_init = 2;
var zoom_curr  = zoom_init;
var zoom = zooms[zoom_curr];
# display width = 0.3 meter
# 381 pixels = 0.300 meter   1270 pixels/meter = 1:1
# so at setting 800:1   1 meter = 800 meter    meter/pixel= 1270/800 = 1.58
#cos = 0.63
#print("200   = "~200000/1270);
#print("400   = "~400000/1270);
#print("800   = "~800000/1270);
#print("1.6   = "~1600000/1270);
#print("3.2   = "~3200000/1270);
#print("");
#for(i=0;i<20;i+=1) {
# print(i~"  ="~meterPerPixel[i]*math.cos(65*D2R)~" m/px");
#}

var M2TEX = 1/(meterPerPixel[zoom]*math.cos(getprop('/position/latitude-deg')*D2R));
var maps_base = getprop("/sim/fg-home") ~ '/cache/mapsCDU60';

# max zoom 18
# light_all,
# dark_all,
# light_nolabels,
# light_only_labels,
# dark_nolabels,
# dark_only_labels

var providers = {
    stamen_terrain_bg: {
                templateLoad: "https://stamen-tiles.a.ssl.fastly.net/terrain-background/{z}/{x}/{y}.png",
                templateStore: "/stamen-bg/{z}/{x}/{y}.png",
                attribution: "Map tiles by Stamen Design"},
    stamen_terrain_ln: {
                templateLoad: "https://stamen-tiles.a.ssl.fastly.net/terrain-lines/{z}/{x}/{y}.png",
                templateStore: "/stamen-ln/{z}/{x}/{y}.png",
                attribution: "Map tiles by Stamen Design"},
    arcgis_terrain: {
                templateLoad: "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}",
                templateStore: "/arcgis/{z}/{y}/{x}.jpg",
                attribution: ""},            
};

var zoom_provider = ["stamen_terrain_bg","stamen_terrain_bg","stamen_terrain_bg","stamen_terrain_bg","stamen_terrain_bg","arcgis_terrain"];

var makeUrl   = string.compileTemplate(providers[zoom_provider[zoom_curr]].templateLoad);
#var makeUrl   = string.compileTemplate('https://cartodb-basemaps-c.global.ssl.fastly.net/{type}/{z}/{x}/{y}.png');
#var makePath  = string.compileTemplate(maps_base ~ '/cartoL/{z}/{x}/{y}.png');
var makePath  = string.compileTemplate(maps_base ~ providers[zoom_provider[zoom_curr]].templateStore);
var num_tiles = [7, 7];# must be uneven, 7x7 will ensure we never see edge of map tiles when canvas is 1024px high.

var center_tile_offset = [(num_tiles[0] - 1) / 2,(num_tiles[1] - 1) / 2];#(width/tile_size)/2,(height/tile_size)/2];
#  (num_tiles[0] - 1) / 2,
#  (num_tiles[1] - 1) / 2
#];

##
# initialize the map by setting up
# a grid of raster images

var tiles = setsize([], num_tiles[0]);


var last_tile = [-1,-1];
var last_type = type;
var last_zoom = zoom;
var lastLiveMap = 1;#getprop("f16/displays/live-map");
var lastDay   = 1;

var CLEANMAP = 0;
var PLACES   = 1;

var COLOR_DAY   = "rgb(255,255,255)";#"rgb(128,128,128)";# color fill behind map which will modulate to make it darker.
var COLOR_NIGHT = "rgb(128,128,128)";

var vector_aicontacts_links = [];
var DLRecipient = emesary.Recipient.new("CDU-DLRecipient");
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


var lineWidth = {
    bullseye: 5,
    rangeRings: 8,
    ownship: 4,
    rangeArrows: 4,
    radarCone: 3,
    threatRings: 4,
    lines: 2,
    route: 3,
    pfd: 4,
    grid: 3,
    targets: 2,
    targetsDL: 3,
    gpsSpot: 5,
};

var font = {
    range: 30,
    pfdLadder: 20,
    pfdTapes: 20,
    attribution: 30,
    threatRings: 25,
    grid: 14,
    targets: 25,
    markpoints: 25,
};

var symbolSize = {
    contacts: 112,
    bullseye: 50,
    gpsSpot: 25,
    ownship: 30,
};

var layer_z = {
    # How things are layered on top of each other, higher numbers are on top of lower numbers.
    display: {
        map: 1,
        mapOverlay: 7,
        buttonSymbols: 9,
        pfd: 20,
        pfdSky: 19,
        ehsi: 20,
        attribution: 70,
    },
    map: {
        tiles: 1,
        targets: 11,
        markpoints: 10,
        lines_and_route: 8,
        threatRings: 4,
        grid: 2,
        gridText: 3,
    },
    mapOverlay: {
        ownship: 10,
        radarCone: 11,
        rangeRings: 7,
    },
};


var loopTimer = nil;
var loopTimerFast = nil;
var loopTimerVerySlow = nil;


#   ██████ ██████  ██    ██ 
#  ██      ██   ██ ██    ██ 
#  ██      ██   ██ ██    ██ 
#  ██      ██   ██ ██    ██ 
#   ██████ ██████   ██████  
#                           
#                           
var CDU = {

    init: func {
        me.canvasX = 1024;
        me.canvasY = 1024;
        me.cduCanvas = canvas.new({
              "name": "CDU",
              "size": [me.canvasX, me.canvasY],
              "view": [me.canvasX, me.canvasY],
              "mipmapping": 0,
              "additive-blend": 1,
        });
            
        me.placement = me.cduCanvas.addPlacement({"node": "cdu_canvas"});
        me.cduCanvas.setColorBackground(0.5, 0.5, 0.5, 1.00);

        me.root = me.cduCanvas.createGroup();
        me.root.set("font", "NotoMono-Regular.ttf");
        me.root.show();

        me.setupVariables();
        me.calcGeometry();
        me.calcZoomLevels();
        me.initMap();
        me.setupProperties();# before setup map
        me.setupMap();
        me.setupGrid();# after setupgrid
        me.setupFunctions();#before symbols
        me.setupSymbols();
        me.setupThreatRings();
        me.setupLines();
        me.setupMarkPoints();
        me.setupTargets();
        me.setupEHSI();
        me.setupPFD();
        me.setupAttr();
        
        me.setRangeInfo();
        me.loadedCDU = 1;

        loopTimer = maketimer(0.25, me, me.loop);
        loopTimer.start();
        loopTimerFast = maketimer(0.01, me, me.loopFast);
        loopTimerFast.start();
        loopTimerVerySlow = maketimer(3600, me, me.calcZoomLevels);
        loopTimerVerySlow.start();
        #me.loop();

        startDLListener();
        #print("CDU module started");
    },

    del: func {
        me.loadedCDU = 0;
        #if (loopTimer != nil) {
        #    loopTimer.stop();
        #    loopTimer = nil;
        #} else print("NO LOOP");
        if (me["cduCanvas"] != nil) {
            me.root.removeAllChildren();
            me.root.update();
            me.placement.remove();
            me.cduCanvas.del();
        }
        #else print("NO CDU CANVAS");
        #print("Deleted CDU module");
    },

    loop: func {
        if (!me.loadedCDU) {
            print("Unloaded CDU Looping");
            return;
        }
        if (me.day) {
            me.cduCanvas.setColorBackground(0.3, 0.3, 0.3, 1.0);
        } else {
            me.cduCanvas.setColorBackground(0.15, 0.15, 0.15, 1.0);
        }

        me.selfCoord = geo.aircraft_position();

        if (!me.showPFD and !me.showEHSI) {
            me.ownPosition = 0.60 * me.max_y;
        } else {
            me.ownPosition = me.defaultOwnPosition;
        }

        me.whereIsMap();
        me.updateMap();
        me.updateRadarCone();
        me.updateGrid();
        me.updateSymbols();
        me.updateThreatRings();
        me.updateLines();# after updateRadarCone
        me.updateRoute();# after updateLines
        me.updateMarkPoints();
        me.updateTargets();
        me.updateAttr();
        #print("CDU Looping ",me.loadedCDU);
    },

    loopFast: func {
        if (!me.loadedCDU) {
            print("Unloaded CDU Looping");
            return;
        }
        me.updatePFD();
        #print("CDU Looping ",me.loadedCDU);
    },

    setupVariables: func {
        me.mapShowPlaces = 1;
        me.mapSelfCentered = 1;
        me.day = 1;
        me.mapShowGrid = 0;
        me.showPFD = 1;
        me.showEHSI = 1;
    },

    calcGeometry: func {
        me.max_x = me.canvasX/1.25;
        me.max_y = me.canvasY;
        me.ehsiScale = 1/1.25;
        me.ehsiCanvas = 512;
        me.ehsiPosX = 0.5 * me.max_x;
        me.ehsiPosY = me.max_y-me.ehsiScale*me.ehsiCanvas;
        me.defaultOwnPosition = 0.65 * me.ehsiPosY;
        me.ownPosition = me.defaultOwnPosition;
    },

    calcZoomLevels: func {
        me.M2TEXinit = 1/(meterPerPixel[zoomsSEU[zoom_init]]*math.cos(getprop('/position/latitude-deg')*D2R));
        if (zoomLevels[zoom_init]*NM2M*me.M2TEXinit > me.defaultOwnPosition * 2) {
            #print("Reduce zoom x4");
            forindex (var zoomLvl ; zoomLevels) {
                zooms[zoomLvl] = zoomsSEU[zoomLvl]-2;
            }
        } elsif (zoomLevels[zoom_init]*NM2M*me.M2TEXinit > me.defaultOwnPosition) {
            #print("Reduce zoom x2");
            forindex (var zoomLvl ; zoomLevels) {
                zooms[zoomLvl] = zoomsSEU[zoomLvl]-1;
            }
        } elsif (zoomLevels[zoom_init]*NM2M*me.M2TEXinit < me.defaultOwnPosition * 0.5) {
            #print("Increase zoom x2");
            forindex (var zoomLvl ; zoomLevels) {
                zooms[zoomLvl] = zoomsSEU[zoomLvl]+1;
            }
        } elsif (zoomLevels[zoom_init]*NM2M*me.M2TEXinit < me.defaultOwnPosition * 0.25) {
            #print("Increase zoom x4");
            forindex (var zoomLvl ; zoomLevels) {
                zooms[zoomLvl] = zoomsSEU[zoomLvl]+2;
            }
        }
        me.M2TEXinit = 1/(meterPerPixel[zooms[zoom_init]]*math.cos(getprop('/position/latitude-deg')*D2R));
    },

    setupProperties: func {
        me.input = {
            alt_ft:               "instrumentation/altimeter/indicated-altitude-ft",
            alt_true_ft:          "position/altitude-ft",
            heading:              "instrumentation/heading-indicator/indicated-heading-deg",
            radarStandby:         "instrumentation/radar/radar-standby",
            rad_alt:              "instrumentation/radar-altimeter/radar-altitude-ft",
            rad_alt_ready:        "instrumentation/radar-altimeter/ready",
            rmActive:             "autopilot/route-manager/active",
            rmDist:               "autopilot/route-manager/wp/dist",
            rmId:                 "autopilot/route-manager/wp/id",
            rmBearing:            "autopilot/route-manager/wp/true-bearing-deg",
            RMCurrWaypoint:       "autopilot/route-manager/current-wp",
            roll:                 "instrumentation/attitude-indicator/indicated-roll-deg",
            timeElapsed:          "sim/time/elapsed-sec",
            headTrue:             "orientation/heading-deg",
            fpv_up:               "instrumentation/fpv/angle-up-deg",
            fpv_right:            "instrumentation/fpv/angle-right-deg",
            roll:                 "orientation/roll-deg",
            pitch:                "orientation/pitch-deg",
            radar_serv:           "instrumentation/radar/serviceable",
            nav0InRange:          "instrumentation/nav[0]/in-range",
            APLockHeading:        "autopilot/locks/heading",
            APTrueHeadingErr:     "autopilot/internal/true-heading-error-deg",
            APnav0HeadingErr:     "autopilot/internal/nav1-heading-error-deg",
            APHeadingBug:         "autopilot/settings/heading-bug-deg",
            RMActive:             "autopilot/route-manager/active",
            nav0Heading:          "instrumentation/nav[0]/heading-deg",
            ias:                  "instrumentation/airspeed-indicator/indicated-speed-kt",
            tas:                  "instrumentation/airspeed-indicator/true-speed-kt",
            wow0:                 "fdm/jsbsim/gear/unit[0]/WOW",
            wow1:                 "fdm/jsbsim/gear/unit[1]/WOW",
            wow2:                 "fdm/jsbsim/gear/unit[2]/WOW",
            gearsPos:             "gear/gear/position-norm",
            latitude:             "position/latitude-deg",
            longitude:            "position/longitude-deg",
            elevCmd:              "fdm/jsbsim/fcs/elevator-cmd-norm",
            ailCmd:               "fdm/jsbsim/fcs/aileron-cmd-norm",
            instrNorm:            "controls/lighting/instruments-norm",
            linker:               "sim/va"~"riant-id",
            datalink:             "/instrumentation/datalink/on",
            weight:               "fdm/jsbsim/inertia/weight-lbs",
            max_approach_alpha:   "fdm/jsbsim/systems/flight/approach-alpha-base",
            calibrated:           "fdm/jsbsim/velocities/vc-kts",
            mach:                 "instrumentation/airspeed-indicator/indicated-mach",
        };

        foreach(var name; keys(me.input)) {
            me.input[name] = props.globals.getNode(me.input[name], 1);
        }
    },


#  ███████ ██    ██ ███    ██  ██████ ████████ ██  ██████  ███    ██ ███████ 
#  ██      ██    ██ ████   ██ ██         ██    ██ ██    ██ ████   ██ ██      
#  █████   ██    ██ ██ ██  ██ ██         ██    ██ ██    ██ ██ ██  ██ ███████ 
#  ██      ██    ██ ██  ██ ██ ██         ██    ██ ██    ██ ██  ██ ██      ██ 
#  ██       ██████  ██   ████  ██████    ██    ██  ██████  ██   ████ ███████ 
#                                                                            
#                                                                            
    setupFunctions: func {
        me.buttonMap = {
            b1: {method: me.zoomOut, pos: [0,90]},
            b2: {method: me.zoomIn, pos: [0,210]},
            b8: {method: me.toggleDay, pos: [0,950]},
            b16: {method: me.toggleGrid, pos: [me.max_x,950]},
            b23: {method: me.togglePFD, pos: [800,me.max_y]},
            b25: {method: me.toggleEHSI, pos: [200,me.max_y]},
        };
    },

    buttonPress: func (button) {
        button = "b"~button;
        call(me.buttonMap[button].method, nil, me, me);
    },

    buttonRelease: func (button) {
        button = "b"~button;
        call(me.buttonMap[button].methodRelease, nil, me, me);
    },

    toggleDay: func {
        me.day = !me.day;
    },

    toggleGrid: func {
        me.mapShowGrid = !me.mapShowGrid;
    },

    togglePFD: func {
        me.showPFD = !me.showPFD;
    },

    toggleEHSI: func {
        me.showEHSI = !me.showEHSI;
    },

#   ██████  ██    ██ ███████ ██████  ██       █████  ██    ██ ███████ 
#  ██    ██ ██    ██ ██      ██   ██ ██      ██   ██  ██  ██  ██      
#  ██    ██ ██    ██ █████   ██████  ██      ███████   ████   ███████ 
#  ██    ██  ██  ██  ██      ██   ██ ██      ██   ██    ██         ██ 
#   ██████    ████   ███████ ██   ██ ███████ ██   ██    ██    ███████ 
#                                                                     
#                                                                     
    setupSymbols: func {
        # ownship symbol
        me.selfSymbol = me.rootCenter.createChild("path")
                .moveTo(0, 0)
                .vert(symbolSize.ownship)
               .moveTo(-symbolSize.ownship/3, symbolSize.ownship/3)
               .horiz(symbolSize.ownship*2/3)
               .moveTo(-symbolSize.ownship/6, symbolSize.ownship*2/3)
               .horiz(symbolSize.ownship/3)
              .setColor(COLOR_BLUE_LIGHT)
              .set("z-index", layer_z.mapOverlay.ownship)
              .setStrokeLineWidth(lineWidth.ownship);

        me.cone = me.rootCenter.createChild("group")
            .set("z-index",layer_z.mapOverlay.radarCone);#radar cone

        me.outerRadius  = zoomLevels[zoom_curr]*NM2M*M2TEX;
        #me.mediumRadius = me.outerRadius*0.6666;
        me.innerRadius  = me.outerRadius*0.5;
        #var innerTick    = 0.85*innerRadius*math.cos(45*D2R);
        #var outerTick    = 1.15*innerRadius*math.cos(45*D2R);

        me.rangeArrowUp = me.root.createChild("path")
            .lineTo(20,30)
            .lineTo(-20, 30)
            .lineTo(0,0)
            .setStrokeLineWidth(lineWidth.rangeArrows)
            .set("z-index",layer_z.display.buttonSymbols)
            .setColor(COLOR_YELLOW)
            .setTranslation(me.buttonMap.b1.pos[0]+40, me.buttonMap.b1.pos[1]-15);

        me.rangeText = me.root.createChild("text")
            .set("z-index",layer_z.display.buttonSymbols)
            .setColor(COLOR_YELLOW)
            .setFontSize(font.range, 1.0)
            .setAlignment("center-center")
            .setTranslation(me.buttonMap.b1.pos[0]+40, (me.buttonMap.b1.pos[1]+me.buttonMap.b2.pos[1])*0.5)
            .setFont("NotoMono-Regular.ttf");            

        me.rangeArrowDown = me.root.createChild("path")
            .lineTo(20,-30)
            .lineTo(-20, -30)
            .lineTo(0,0)
            .setStrokeLineWidth(lineWidth.rangeArrows)
            .set("z-index",layer_z.display.buttonSymbols)
            .setColor(COLOR_YELLOW)
            .setTranslation(me.buttonMap.b2.pos[0]+40, me.buttonMap.b2.pos[1]+15);

        me.conc = me.rootCenter.createChild("path")
            .moveTo(me.innerRadius,0)
            .arcSmallCW(me.innerRadius,me.innerRadius, 0, -me.innerRadius*2, 0)
            .arcSmallCW(me.innerRadius,me.innerRadius, 0,  me.innerRadius*2, 0)
            .moveTo(me.outerRadius,0)
            .arcSmallCW(me.outerRadius,me.outerRadius, 0, -me.outerRadius*2, 0)
            .arcSmallCW(me.outerRadius,me.outerRadius, 0,  me.outerRadius*2, 0)
            .moveTo(0,-me.innerRadius)#north
            .vert(-15)
            .lineTo(3,-me.innerRadius-15+2)
            .lineTo(0,-me.innerRadius-15+4)
            .moveTo(0,me.innerRadius-15)#south
            .vert(30)
            .moveTo(-me.innerRadius,0)#west
            .horiz(-15)
            .moveTo(me.innerRadius,0)#east
            .horiz(15)
            .setStrokeLineWidth(lineWidth.rangeRings)
            .set("z-index",layer_z.mapOverlay.rangeRings)
            .setColor(COLOR_GRAY);

        me.bullseye = me.mapCenter.createChild("path")
            .moveTo(-symbolSize.bullseye,0)
            .arcSmallCW(symbolSize.bullseye,symbolSize.bullseye, 0,  symbolSize.bullseye*2, 0)
            .arcSmallCW(symbolSize.bullseye,symbolSize.bullseye, 0, -symbolSize.bullseye*2, 0)
            .moveTo(-symbolSize.bullseye*3/5,0)
            .arcSmallCW(symbolSize.bullseye*3/5,symbolSize.bullseye*3/5, 0,  symbolSize.bullseye*3/5*2, 0)
            .arcSmallCW(symbolSize.bullseye*3/5,symbolSize.bullseye*3/5, 0, -symbolSize.bullseye*3/5*2, 0)
            .moveTo(-symbolSize.bullseye/5,0)
            .arcSmallCW(symbolSize.bullseye/5,symbolSize.bullseye/5, 0,  symbolSize.bullseye/5*2, 0)
            .arcSmallCW(symbolSize.bullseye/5,symbolSize.bullseye/5, 0, -symbolSize.bullseye/5*2, 0)
            .setStrokeLineWidth(lineWidth.bullseye)
            .setColor(COLOR_BLUE_LIGHT);

        me.gpsSpot = me.mapCenter.createChild("path")
            .moveTo(-symbolSize.gpsSpot,0)
            .arcSmallCW(symbolSize.gpsSpot,symbolSize.gpsSpot, 0,  symbolSize.gpsSpot*2, 0)
            .arcSmallCW(symbolSize.gpsSpot,symbolSize.gpsSpot, 0, -symbolSize.gpsSpot*2, 0)
            .moveTo(-symbolSize.gpsSpot*3/5,0)
            .arcSmallCW(symbolSize.gpsSpot*3/5,symbolSize.gpsSpot*3/5, 0,  symbolSize.gpsSpot*3/5*2, 0)
            .arcSmallCW(symbolSize.gpsSpot*3/5,symbolSize.gpsSpot*3/5, 0, -symbolSize.gpsSpot*3/5*2, 0)
            .setStrokeLineWidth(lineWidth.gpsSpot)
            .setColor(COLOR_BLACK);
    },

    updateSymbols: func {
        me.bullPt = steerpoints.getNumber(steerpoints.index_of_bullseye);
        me.bullOn = me.bullPt != nil;
        if (me.bullOn) {
            me.bullLat = me.bullPt.lat;
            me.bullLon = me.bullPt.lon;
            me.bullseye.setTranslation(me.laloToTexelMap(me.bullLat,me.bullLon));            
        }
        me.bullseye.setVisible(me.bullOn);

        me.gpsPt = steerpoints.getNumber(steerpoints.index_of_weapon_gps);
        me.bullOn = me.gpsPt != nil;
        if (me.bullOn) {
            me.gpsLat = me.gpsPt.lat;
            me.gpsLon = me.gpsPt.lon;
            me.gpsSpot.setTranslation(me.laloToTexelMap(me.gpsLat,me.gpsLon));            
        }
        me.gpsSpot.setVisible(me.bullOn);

        me.concScale = zoomLevels[zoom_init]*NM2M*me.M2TEXinit/me.outerRadius;
        me.conc.setScale(me.concScale);
        me.conc.setStrokeLineWidth(lineWidth.rangeRings/me.concScale);
        me.conc.setVisible(zoom_curr != 5);
        me.conc.setColor(me.day?COLOR_GRAY:COLOR_GRAY_LIGHT);
    },

    setupTargets: func {
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
                me.blepTriangle[i] = me.mapCenter.createChild("group")
                                .set("z-index",layer_z.map.targets);
                me.blepTriangleVel[i] = me.blepTriangle[i].createChild("group");
                me.blepTriangleText[i] = me.blepTriangle[i].createChild("text")
                                .setAlignment("center-top")
                                .setFontSize(font.targets, 1.0)
                                .setTranslation(0,symbolSize.contacts/5.5);
                me.blepTriangleVelLine[i] = me.blepTriangleVel[i].createChild("path")
                                .lineTo(0,-10)
                                .setTranslation(0,-symbolSize.contacts/7)
                                .setStrokeLineWidth(lineWidth.targets);
                me.blepTrianglePaths[i] = me.blepTriangle[i].createChild("path")
                                .moveTo(-symbolSize.contacts/8,symbolSize.contacts/14)
                                .horiz(symbolSize.contacts/4)
                                .lineTo(0,-symbolSize.contacts/7)
                                .lineTo(-symbolSize.contacts/8,symbolSize.contacts/14)
                                .set("z-index",10)
                                .setStrokeLineWidth(lineWidth.targets);
                me.lnk[i] = me.mapCenter.createChild("path")
                                .moveTo(-symbolSize.contacts/10,-symbolSize.contacts/10)
                                .vert(symbolSize.contacts/5)
                                .horiz(symbolSize.contacts/5)
                                .vert(-symbolSize.contacts/5)
                                .horiz(-symbolSize.contacts/5)
                                .moveTo(0,-symbolSize.contacts/10)
                                .vert(-symbolSize.contacts/10)
                                .hide()
                                .set("z-index",layer_z.map.targets)
                                .setStrokeLineWidth(lineWidth.targetsDL);
                me.lnkT[i] = me.mapCenter.createChild("text")
                                .setAlignment("center-bottom")
                                .set("z-index",layer_z.map.targets)
                                .setFontSize(font.targets, 1.0);
                me.lnkTA[i] = me.mapCenter.createChild("text")
                                .setAlignment("center-top")
                                .set("z-index",layer_z.map.targets)
                                .setFontSize(font.targets, 1.0);
        }
        me.selection = me.mapCenter.createChild("path")
                .moveTo(-symbolSize.contacts/7, 0)
                .arcSmallCW(symbolSize.contacts/7, symbolSize.contacts/7, 0, (symbolSize.contacts/7)*2, 0)
                .arcSmallCW(symbolSize.contacts/7, symbolSize.contacts/7, 0, -(symbolSize.contacts/7)*2, 0)
                .setColor(COLOR_YELLOW)
                .set("z-index",layer_z.map.targets)
                .setStrokeLineWidth(2);
    },

    updateTargets: func {
        me.i = 0;#triangles
        me.ii = 0;#dlink
        me.selected = 0;

        me.rando = rand();
        me.rdrprio = radar_system.apg68Radar.getPriorityTarget();
        me.selfHeading = radar_system.self.getHeading();

        if (radar_system.datalink_power.getBoolValue()) {
            #printf("%d DLs",size(vector_aicontacts_links));
            foreach(contact; vector_aicontacts_links) {
                me.blue = contact.blue;
                me.blueIndex = contact.blueIndex;
                me.paintBlep(contact);
                contact.rando = me.rando;
            }
        }
        if (radar_system.apg68Radar.enabled) {
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
        me.color = me.blue == 1?COLOR_BLUE_LIGHT:(me.blue == 2?COLOR_RED:COLOR_YELLOW);
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


        #me.distPixels = (me.c_rng/me.rdrrng)*me.rdrRangePixels;
        #    if (me.blue) print("through ",me.desig," LoS:",!contact.get_behind_terrain());


        me.rot = 22.5*math.round( geo.normdeg((me.c_hea))/22.5 )*D2R;#Show rotation in increments of 22.5 deg
        #me.trans = [me.distPixels*math.sin(me.c_rbe*D2R),-me.distPixels*math.cos(me.c_rbe*D2R)];
        me.transCoord = contact.getCoord();
        me.trans = me.laloToTexelMap(me.transCoord.lat(),me.transCoord.lon());

        if (me.blue != 1 and me.i < me.maxB) {
            me.blepTrianglePaths[me.i].setColor(me.color);
            me.blepTriangle[me.i].setTranslation(me.trans);
            me.blepTriangle[me.i].show();
            me.blepTrianglePaths[me.i].setRotation(me.rot);
            me.blepTriangleVel[me.i].setRotation(me.rot);
            me.blepTriangleVelLine[me.i].setScale(1,me.c_spd*0.0045);
            me.blepTriangleVelLine[me.i].setColor(me.color);
            me.lockAlt = sprintf("%02d", math.round(me.c_alt*0.001));
            me.blepTriangleText[me.i].setText(me.lockAlt);
            me.blepTriangleText[me.i].setColor(me.color);
            me.i += 1;
            if (me.blue == 2 and me.ii < me.maxB) {
                me.lnkT[me.ii].setColor(me.color);
                me.lnkT[me.ii].setTranslation(me.trans[0],me.trans[1]-symbolSize.contacts/4.5);
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
            #me.lnkT[me.ii].setRotation(me.selfHeading*D2R);
            #me.lnkTA[me.ii].setRotation(me.selfHeading*D2R);
            me.lnkT[me.ii].setColor(me.color);
            me.lnkTA[me.ii].setColor(me.color);
            me.lnkT[me.ii].setTranslation(me.trans[0],me.trans[1]-symbolSize.contacts/4.5);
            me.lnkTA[me.ii].setTranslation(me.trans[0],me.trans[1]+symbolSize.contacts/5.5);
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

    setupAttr: func {
        me.attrText = me.root.createChild("text")
            .set("z-index",layer_z.display.attribution)
            .setColor(COLOR_WHITE)
            .setFontSize(font.attribution, 1.0)
            .setText("")
            .setAlignment("center-center")
            .setTranslation(me.max_x*0.5,me.max_y*0.5)
            .setFont("NotoMono-Regular.ttf");
    },

    updateAttr: func {
        # every once in a while display attribution for 4 seconds.
        me.attrText.setText(providers[zoom_provider[zoom_curr]].attribution);
        me.attrText.setVisible(math.mod(int(me.input.timeElapsed.getValue()*0.25), 120) == 0)
    },

    setupMarkPoints: func {
        me.mark = setsize([],steerpoints.number_of_markpoints_own+steerpoints.number_of_markpoints_dlnk);
        for (var no = 0; no < steerpoints.number_of_markpoints_own+steerpoints.number_of_markpoints_dlnk; no += 1) {
            me.mark[no] = me.mapCenter.createChild("text")
                    .setAlignment("center-center")
                    .setColor(no<5?COLOR_RED:COLOR_BROWN)
                    .setText("X")
                    .set("z-index",layer_z.map.markpoints)
                    .setFontSize(font.markpoints, 1.0);
        }
    },

    updateMarkPoints: func {
        for (var mi = 0; mi < steerpoints.number_of_markpoints_own+steerpoints.number_of_markpoints_dlnk; mi+=1) {
            var mkpt = nil;
            if (mi<steerpoints.number_of_markpoints_own) {
                mkpt = steerpoints.getNumber(steerpoints.index_of_markpoints_own+mi);
            } else {
                mkpt = steerpoints.getNumber(steerpoints.index_of_markpoints_dlnk+mi-5);
            }
            if (mkpt == nil) {
                me.mark[mi].hide();
            } else {                
                me.markPos = me.laloToTexelMap(mkpt.lat, mkpt.lon);
                #printf("Showing mark #%d at %d,%d",mi,me.markPos[0],me.markPos[1]);
                me.mark[mi].setTranslation(me.markPos);
                me.mark[mi].show();
            }
        }
    },

    setupLines: func {
        # Used by lines and route
        me.linesGroup = me.mapCenter.createChild("group").set("z-index",layer_z.map.lines_and_route);
    },

    updateLines: func {
        me.linesGroup.removeAllChildren();
        for (var u = 0;u<2;u+=1) {
            if (steerpoints.lines[u] != nil) {
                # lines
                me.plan = steerpoints.lines[u];
                me.planSize = me.plan.getPlanSize();
                me.stptPrevPos = nil;
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
                    
                    me.stptPos = me.laloToTexelMap(me.wp.lat,me.wp.lon);
                    if (me.stptPrevPos != nil and u == 0) {
                        me.linesGroup.createChild("path")
                            .moveTo(me.stptPos)
                            .lineTo(me.stptPrevPos)
                            .setStrokeLineWidth(lineWidth.lines)
                            .set("z-index",4)
                            .setColor(COLOR_WHITE)
                            .update();
                    } else if (me.stptPrevPos != nil and u == 1) {
                        me.linesGroup.createChild("path")
                            .moveTo(me.stptPos)
                            .lineTo(me.stptPrevPos)
                            .setStrokeLineWidth(lineWidth.lines)
                            .setStrokeDashArray([10, 10])
                            .set("z-index",4)
                            .setColor(COLOR_WHITE)
                            .update();
                    }
                    me.stptPrevPos = me.stptPos;
                }
            }
        }
    },

    updateRoute: func {
        if (steerpoints.isRouteActive()) {
            me.plan = flightplan();
            me.planSize = me.plan.getPlanSize();
            me.stptPrevPos = nil;
            for (me.j = 0; me.j < me.planSize;me.j+=1) {
                me.wp = me.plan.getWP(me.j);
                me.stptPos = me.laloToTexelMap(me.wp.lat,me.wp.lon);
                me.wp = me.linesGroup.createChild("path")
                    .moveTo(me.stptPos[0]-8,me.stptPos[1])
                    .arcSmallCW(8,8, 0, 8*2, 0)
                    .arcSmallCW(8,8, 0,-8*2, 0)
                    .setStrokeLineWidth(lineWidth.route)
                    .set("z-index",6)
                    .setColor(COLOR_WHITE)
                    .update();
                if (me.plan.current == me.j) {
                    me.wp.setColorFill(COLOR_WHITE);
                }
                if (me.stptPrevPos != nil) {
                    me.linesGroup.createChild("path")
                        .moveTo(me.stptPos)
                        .lineTo(me.stptPrevPos)
                        .setStrokeLineWidth(lineWidth.route)
                        .set("z-index",6)
                        .setColor(COLOR_WHITE)
                        .update();
                }
                me.stptPrevPos = me.stptPos;
            }
        }
    },

    zoomIn: func() {
        #if (ti.active == 0) return;
        zoom_curr += 1;
        if (zoom_curr >= size(zooms)) {
            zoom_curr = size(zooms)-1;
            return;
            zoom_curr = 0;
        }
        zoom = zooms[zoom_curr];
        M2TEX = 1/(meterPerPixel[zoom]*math.cos(getprop('/position/latitude-deg')*D2R));
        me.setRangeInfo();
        me.changeProvider();
    },

    zoomOut: func() {
        #if (ti.active == 0) return;
        zoom_curr -= 1;
        if (zoom_curr < 0) {
            zoom_curr = 0;
            return;
            zoom_curr = 4;
        }
        zoom = zooms[zoom_curr];
        M2TEX = 1/(meterPerPixel[zoom]*math.cos(getprop('/position/latitude-deg')*D2R));
        me.setRangeInfo();
        me.changeProvider();
    },

    changeProvider: func {
        makeUrl   = string.compileTemplate(providers[zoom_provider[zoom_curr]].templateLoad);
        makePath  = string.compileTemplate(maps_base ~ providers[zoom_provider[zoom_curr]].templateStore);
    },

    setRangeInfo: func  {
        me.range = zoomLevels[zoom_curr];#(me.outerRadius/M2TEX)*M2NM;
        me.rangeText.setText(sprintf("%d", me.range));#print(sprintf("Map range %5.1f NM", me.range));
        me.rangeArrowDown.setVisible(zoom_curr < size(zoomLevels)-1);
        me.rangeArrowUp.setVisible(zoom_curr > 0);
    },

    updateRadarCone: func {
        me.cone.removeAllChildren();
        if (radar_system.apg68Radar.enabled) {
            if (radar_system.apg68Radar.showAZinHSD()) {

                me.rdrrng = radar_system.apg68Radar.getRange();
                me.rdrRangePixels = (me.rdrrng*NM2M)*M2TEX;
                me.az = radar_system.apg68Radar.currentMode.az;
                

                me.radarX1 =  me.rdrRangePixels*math.cos((90-me.az-radar_system.apg68Radar.getDeviation())*D2R);
                me.radarY1 = -me.rdrRangePixels*math.sin((90-me.az-radar_system.apg68Radar.getDeviation())*D2R);
                me.radarX2 =  me.rdrRangePixels*math.cos((90+me.az-radar_system.apg68Radar.getDeviation())*D2R);
                me.radarY2 = -me.rdrRangePixels*math.sin((90+me.az-radar_system.apg68Radar.getDeviation())*D2R);
                me.cone.createChild("path")
                            .moveTo(0,0)
                            .lineTo(me.radarX1,me.radarY1)#right
                            .moveTo(0,0)
                            .lineTo(me.radarX2,me.radarY2)#left
                            .arcSmallCW(me.rdrRangePixels,me.rdrRangePixels, 0, me.radarX1-me.radarX2, me.radarY1-me.radarY2)
                            .setStrokeLineWidth(lineWidth.radarCone)
                            .setColor(COLOR_BLUE_LIGHT)
                            .update();
            }
        }
    },

    laloToTexel: func (la, lo) {
        me.coord = geo.Coord.new();
        me.coord.set_latlon(la, lo);
        me.coordSelf = geo.Coord.new();#TODO: dont create this every time method is called
        me.coordSelf.set_latlon(me.lat_own, me.lon_own);
        me.angle = (me.coordSelf.course_to(me.coord)-me.input.heading.getValue())*D2R;
        me.pos_xx        = -me.coordSelf.distance_to(me.coord)*M2TEX * math.cos(me.angle + math.pi/2);
        me.pos_yy        = -me.coordSelf.distance_to(me.coord)*M2TEX * math.sin(me.angle + math.pi/2);
        return [me.pos_xx, me.pos_yy];#relative to rootCenter
    },
    
    laloToTexelMap: func (la, lo) {
        me.coord = geo.Coord.new();
        me.coord.set_latlon(la, lo);
        me.coordSelf = geo.Coord.new();#TODO: dont create this every time method is called
        me.coordSelf.set_latlon(me.lat, me.lon);
        me.angle = (me.coordSelf.course_to(me.coord))*D2R;
        me.pos_xx        = -me.coordSelf.distance_to(me.coord)*M2TEX * math.cos(me.angle + math.pi/2);
        me.pos_yy        = -me.coordSelf.distance_to(me.coord)*M2TEX * math.sin(me.angle + math.pi/2);
        return [me.pos_xx, me.pos_yy];#relative to mapCenter
    },

    TexelToLaLoMap: func (x,y) {#relative to map center
        x /= M2TEX;
        y /= M2TEX;
        me.mDist  = math.sqrt(x*x+y*y);
        if (me.mDist == 0) {
            return [me.lat, me.lon];
        }
        me.acosInput = clamp(x/me.mDist,-1,1);
        if (y<0) {
            me.texAngle = math.acos(me.acosInput);#unit circle on TI
        } else {
            me.texAngle = -math.acos(me.acosInput);
        }
        #printf("%d degs %0.1f NM", me.texAngle*R2D, me.mDist*M2NM);
        me.texAngle  = -me.texAngle*R2D+90;#convert from unit circle to heading circle, 0=up on display
        me.headAngle = me.input.heading.getValue()+me.texAngle;#bearing
        #printf("%d bearing   %d rel bearing", me.headAngle, me.texAngle);
        me.coordSelf = geo.Coord.new();#TODO: dont create this every time method is called
        me.coordSelf.set_latlon(me.lat, me.lon);
        me.coordSelf.apply_course_distance(me.headAngle, me.mDist);

        return [me.coordSelf.lat(), me.coordSelf.lon()];
    },

    setupThreatRings: func {
        me.threat_c = [];
        me.threat_t = [];
        for (var g = 0; g < steerpoints.number_of_threat_circles; g+=1) {
            append(me.threat_c, me.mapCenter.createChild("path")
                .moveTo(-50,0)
                .arcSmallCW(50,50, 0,  50*2, 0)
                .arcSmallCW(50,50, 0, -50*2, 0)
                .setStrokeLineWidth(lineWidth.threatRings)
                .set("z-index",layer_z.map.threatRings)
                .hide());
            append(me.threat_t, me.mapCenter.createChild("text")
                .setAlignment("center-center")
                .set("z-index",layer_z.map.threatRings)
                .setFontSize(font.threatRings, 1.0));
        }
    },

    updateThreatRings: func {
        for (var l = 0; l<steerpoints.number_of_threat_circles;l+=1) {
            # threat rings
            me.ci = me.threat_c[l];
            me.cit = me.threat_t[l];

            me.cnu = steerpoints.getNumber(300+l);
            if (me.cnu == nil) {
                me.ci.hide();
                me.cit.hide();
                #print("Ignoring ", 300+l);
                continue;
            }
            me.la = me.cnu.lat;
            me.lo = me.cnu.lon;
            me.ra = me.cnu.radius;
            me.ty = me.cnu.type;
            
            
            if (me.la != nil and me.lo != nil and me.ra != nil and me.ra > 0) {
                me.wpC = geo.Coord.new();
                me.wpC.set_latlon(me.la,me.lo);
                me.legDistance = me.selfCoord.distance_to(me.wpC)*M2NM;
                me.ringPos = me.laloToTexelMap(me.la,me.lo);
                me.ci.setTranslation(me.ringPos);
                me.ringScale = M2TEX*me.ra*NM2M/50;
                me.ci.setScale(me.ringScale);
                me.ci.setStrokeLineWidth(lineWidth.threatRings/me.ringScale);
                me.co = me.ra > me.legDistance?COLOR_RED:COLOR_YELLOW;
                #print("Painting ", 300+l," in ", me.ra > me.legDistance?"red":"yellow");
                me.ci.setColor(me.co);
                me.ci.show();
                me.cit.setText(me.ty);
                me.cit.setTranslation(me.ringPos);
                me.cit.setColor(me.co);
                me.cit.show();
            } else {
                me.ci.hide();
                me.cit.hide();
            }
        }
    },

#  ██ ███    ██ ███████ ████████ ██████  ██    ██ ███    ███ ███████ ███    ██ ████████ ███████ 
#  ██ ████   ██ ██         ██    ██   ██ ██    ██ ████  ████ ██      ████   ██    ██    ██      
#  ██ ██ ██  ██ ███████    ██    ██████  ██    ██ ██ ████ ██ █████   ██ ██  ██    ██    ███████ 
#  ██ ██  ██ ██      ██    ██    ██   ██ ██    ██ ██  ██  ██ ██      ██  ██ ██    ██         ██ 
#  ██ ██   ████ ███████    ██    ██   ██  ██████  ██      ██ ███████ ██   ████    ██    ███████ 
#                                                                                               
#                                                                                               
    setupPFD: func {
        me.pfdRoot = me.root.createChild("group")
            .set("z-index", layer_z.display.pfd)
            .set("clip", sprintf("rect(%dpx, %dpx, %dpx, %dpx)",me.ehsiPosY,me.ehsiPosX,me.max_y,0))#top,right,bottom,left
            .setTranslation(me.ehsiPosX*0.5, me.ehsiPosY+(me.max_y-me.ehsiPosY)*0.5);
        me.pfdGround = me.pfdRoot.createChild("path")
            .moveTo(-me.max_x, 0)
            .horiz(me.max_x*2)
            .vert(me.max_y)
            .horiz(-me.max_x*2)
            .vert(-me.max_y)
            .setColorFill(COLOR_BROWN)
            .setColor(COLOR_YELLOW)
            .set("z-index", 20)
            .setStrokeLineWidth(lineWidth.pfd);
        me.ladderStep = (me.max_y-me.ehsiPosY)/6;# 10 degs
        me.ladderWidth = me.ehsiPosX*0.15;
        if(me.input.linker.getValue()!=3*2) settimer(4, unload);
        me.pfdLadderGroup = me.pfdRoot.createChild("group")
            .set("z-index", 20);
        me.pfdLadder = me.pfdLadderGroup.createChild("path")
            .moveTo(-me.ladderWidth, me.ladderStep)
            .horiz(me.ladderWidth*2)
            .moveTo(-me.ladderWidth, me.ladderStep*2)
            .horiz(me.ladderWidth*2)
            .moveTo(-me.ladderWidth, me.ladderStep*3)
            .horiz(me.ladderWidth*2)
            .moveTo(-me.ladderWidth, me.ladderStep*4)
            .horiz(me.ladderWidth*2)
            .moveTo(-me.ladderWidth, me.ladderStep*5)
            .horiz(me.ladderWidth*2)
            .moveTo(-me.ladderWidth, me.ladderStep*6)
            .horiz(me.ladderWidth*2)
            .moveTo(-me.ladderWidth, me.ladderStep*7)
            .horiz(me.ladderWidth*2)
            .moveTo(-me.ladderWidth, me.ladderStep*8)
            .horiz(me.ladderWidth*2)
            .moveTo(-me.ladderWidth, me.ladderStep*9)
            .horiz(me.ladderWidth*2)
            .moveTo(-me.ladderWidth, -me.ladderStep)
            .horiz(me.ladderWidth*2)
            .moveTo(-me.ladderWidth, -me.ladderStep*2)
            .horiz(me.ladderWidth*2)
            .moveTo(-me.ladderWidth, -me.ladderStep*3)
            .horiz(me.ladderWidth*2)
            .moveTo(-me.ladderWidth, -me.ladderStep*4)
            .horiz(me.ladderWidth*2)
            .moveTo(-me.ladderWidth, -me.ladderStep*5)
            .horiz(me.ladderWidth*2)
            .moveTo(-me.ladderWidth, -me.ladderStep*6)
            .horiz(me.ladderWidth*2)
            .moveTo(-me.ladderWidth, -me.ladderStep*7)
            .horiz(me.ladderWidth*2)
            .moveTo(-me.ladderWidth, -me.ladderStep*8)
            .horiz(me.ladderWidth*2)
            .moveTo(-me.ladderWidth, -me.ladderStep*9)
            .horiz(me.ladderWidth*2)
            .setColor(1,1,0)
            .setStrokeLineWidth(lineWidth.pfd);
        for(me.ladderI = -9;me.ladderI<10;me.ladderI+=1) {
            if (me.ladderI == 0) continue;
            me.pfdLadderGroup.createChild("text")
                .setColor(COLOR_YELLOW)
                .setFontSize(font.pfdLadder, 1.0)
                .setAlignment("right-center")
                .setTranslation(-me.ladderWidth, me.ladderStep*me.ladderI)
                .setText((-me.ladderI*10)~" ");
            me.pfdLadderGroup.createChild("text")
                .setColor(COLOR_YELLOW)
                .setFontSize(font.pfdLadder, 1.0)
                .setAlignment("left-center")
                .setTranslation(me.ladderWidth, me.ladderStep*me.ladderI)
                .setText(" "~(-me.ladderI*10));
        }

        me.pfdSpeed = me.pfdRoot.createChild("text")
                .setColor(COLOR_YELLOW)
                .setFontSize(font.pfdTapes, 1.0)
                .setAlignment("left-center")
                .setTranslation(-me.ehsiPosX*0.5, 0)
                .setText("425\nM0.94");
        me.pfdAlt = me.pfdRoot.createChild("text")
                .setColor(COLOR_YELLOW)
                .setFontSize(font.pfdTapes, 1.0)
                .setAlignment("right-center")
                .setTranslation(me.ehsiPosX*0.5, 0)
                .setText("18000");

        me.pfdSky = me.root.createChild("path")
            .horiz(me.ehsiPosX)
            .vert(me.ehsiPosX)
            .horiz(-me.ehsiPosX)
            .vert(-me.ehsiPosX)
            .setColorFill(COLOR_SKY_LIGHT)
            .setColor(COLOR_SKY_LIGHT)
            .setStrokeLineWidth(1)
            .set("z-index", layer_z.display.pfdSky)
            .setTranslation(0,me.ehsiPosY);
    },

    updatePFD: func {
        me.pfdRoot.setRotation(-me.input.roll.getValue()*D2R);
        me.pfdGround.setTranslation(0, 0.5*(me.max_y-me.ehsiPosY)*math.clamp(me.input.pitch.getValue()/30, -3, 3));
        me.pfdLadderGroup.setTranslation(0, 0.5*(me.max_y-me.ehsiPosY)*math.clamp(me.input.pitch.getValue()/30, -3, 3));
        me.pfdSpeed.setText(sprintf(" %3d KCAS\n  M%.2f", me.input.calibrated.getValue(), me.input.mach.getValue()));
        me.pfdAlt.setText(sprintf("%5d FT ", me.input.alt_ft.getValue()));
        #if (me.day != lastDay) {
            if (me.day) {
                me.pfdSky.setColorFill(COLOR_SKY_LIGHT).setColor(COLOR_SKY_LIGHT);
                me.pfdGround.setColorFill(COLOR_BROWN);
            } else {
                me.pfdSky.setColorFill(COLOR_SKY_DARK).setColor(COLOR_SKY_DARK);
                me.pfdGround.setColorFill(COLOR_BROWN_DARK);
            }
        #}
        me.EHSI.setVisible(me.showEHSI);
        me.pfdRoot.setVisible(me.showPFD);
        me.pfdSky.setVisible(me.showPFD);
    },

    setupEHSI: func {
        me.EHSI = me.root.createChild("image")
            .set("src", "canvas://by-index/texture[3]")
            .setTranslation(me.ehsiPosX,me.ehsiPosY)
            .setScale(me.ehsiScale)
            .set("z-index", layer_z.display.ehsi);
    },

#   ██████  ██████  ██ ██████  
#  ██       ██   ██ ██ ██   ██ 
#  ██   ███ ██████  ██ ██   ██ 
#  ██    ██ ██   ██ ██ ██   ██ 
#   ██████  ██   ██ ██ ██████  
#                              
#                              
    setupGrid: func {
        me.gridGroup = me.mapCenter.createChild("group")
            .set("z-index", layer_z.map.grid);
        me.gridGroupText = me.mapCenter.createChild("group")
            .set("z-index", layer_z.map.gridText);
        me.last_lat = 0;
        me.last_lon = 0;
        me.last_range = 0;
        me.last_result = 0;
        me.gridTextO = [];
        me.gridTextA = [];
        me.gridTextMaxA = -1;
        me.gridTextMaxO = -1;
    },

    updateGrid: func {
        #line finding algorithm taken from $fgdata mapstructure:
        var lines = [];
        if (!me.mapShowGrid) {
            me.gridGroup.hide();
            me.gridGroupText.hide();
            return;
        }
        if (zoomLevels[zoom_curr] == 320) {
            me.gridGroup.hide();
            me.gridGroupText.hide();
            return;
        } elsif (zoomLevels[zoom_curr] == 160) {
            me.granularity_lon = 2;
            me.granularity_lat = 2;
        } elsif (zoomLevels[zoom_curr] == 80) {
            me.granularity_lon = 1;
            me.granularity_lat = 1;
        } elsif (zoomLevels[zoom_curr] == 40) {
            me.granularity_lon = 0.5;
            me.granularity_lat = 0.5;
        } elsif (zoomLevels[zoom_curr] == 20) {
            me.granularity_lon = 0.25;
            me.granularity_lat = 0.25;
        } else {
            me.gridGroup.hide();
            me.gridGroupText.hide();
            return;
        }
        
        var delta_lon = me.granularity_lon;
        var delta_lat = me.granularity_lat;

        # Find the nearest lat/lon line to the map position.  If we were just displaying
        # integer lat/lon lines, this would just be rounding.
        
        var lat = delta_lat * math.round(me.lat / delta_lat);
        var lon = delta_lon * math.round(me.lon / delta_lon);
        
        var range = 0.75*me.max_y*M2NM/M2TEX;#simplified
        #printf("grid range=%d %.3f %.3f",range,me.lat,me.lon);

        # Return early if no significant change in lat/lon/range - implies no additional
        # grid lines required
        if ((lat == me.last_lat) and (lon == me.last_lon) and (range == me.last_range)) {
            lines = me.last_result;
        } else {

            # Determine number of degrees of lat/lon we need to display based on range
            # 60nm = 1 degree latitude, degree range for longitude is dependent on latitude.
            var lon_range = 1;
            call(func{lon_range = geo.Coord.new().set_latlon(lat,lon,me.input.alt_ft.getValue()*FT2M).apply_course_distance(90.0, range*NM2M).lon() - lon;},nil, var err=[]);
            #courseAndDistance
            if (size(err)) {
                #printf("fail lon %.7f  lat %.7f  ft %.2f  ft %.2f",lon,lat,me.input.alt_ft.getValue(),range*NM2M);
                # typically this fail close to poles. Floating point exception in geo asin.
            }
            var lat_range = range/60.0;

            lon_range = delta_lon * math.ceil(lon_range / delta_lon);
            lat_range = delta_lat * math.ceil(lat_range / delta_lat);

            lon_range = math.clamp(lon_range,delta_lon,250);
            lat_range = math.clamp(lat_range,delta_lat,250);
            
            #printf("range lon %f  lat %f",lon_range,lat_range);
            for (var x = (lon - lon_range); x <= (lon + lon_range); x += delta_lon) {
                var coords = [];
                if (x>180) {
                #   x-=360;
                    continue;
                } elsif (x<-180) {
                #   x+=360;
                    continue;
                }
                # We could do a simple line from start to finish, but depending on projection,
                # the line may not be straight.
                for (var y = (lat - lat_range); y <= (lat + lat_range); y +=  delta_lat) {
                    append(coords, {lon:x, lat:y});
                }
                var ddLon = math.round(math.fmod(abs(x), 1.0) * 60.0);
                append(lines, {
                    id: x,
                    type: "lon",
                    text1: sprintf("%4d",int(x)),
                    text2: ddLon==0?"":ddLon~"",
                    path: coords,
                    equals: func(o){
                        return (me.id == o.id and me.type == o.type); # We only display one line of each lat/lon
                    }
                });
            }
            
            # Lines of latitude
            for (var y = (lat - lat_range); y <= (lat + lat_range); y += delta_lat) {
                var coords = [];
                if (y>90 or y<-90) continue;
                # We could do a simple line from start to finish, but depending on projection,
                # the line may not be straight.
                for (var x = (lon - lon_range); x <= (lon + lon_range); x += delta_lon) {
                    append(coords, {lon:x, lat:y});
                }

                var ddLat = math.round(math.fmod(abs(y), 1.0) * 60.0);
                append(lines, {
                    id: y,
                    type: "lat",
                    text: str(int(y))~(ddLat==0?"   ":" "~ddLat),
                    path: coords,
                    equals: func(o){
                        return (me.id == o.id and me.type == o.type); # We only display one line of each lat/lon
                    }
                });
            }
#printf("range %d  lines %d",range, size(lines));
        }
        me.last_result = lines;
        me.last_lat = lat;
        me.last_lon = lon;
        me.last_range = range;
        
        
        me.gridGroup.removeAllChildren();
        #me.gridGroupText.removeAllChildren();
        me.gridTextNoA = 0;
        me.gridTextNoO = 0;
        me.gridH = me.max_y*0.80;
        foreach (var line;lines) {
            var skip = 1;
            me.posi1 = [];
            foreach (var coord;line.path) {
                if (!skip) {
                    me.posi2 = me.laloToTexelMap(coord.lat,coord.lon);
                    me.aline.lineTo(me.posi2);
                    if (line.type=="lon") {
                        var arrow = [(me.posi1[0]*4+me.posi2[0])/5,(me.posi1[1]*4+me.posi2[1])/5];
                        me.aline.moveTo(arrow);
                        me.aline.lineTo(arrow[0]-7,arrow[1]+10);
                        me.aline.moveTo(arrow);
                        me.aline.lineTo(arrow[0]+7,arrow[1]+10);
                        me.aline.moveTo(me.posi2);
                        if (me.posi2[0]<me.gridH and me.posi2[0]>-me.gridH and me.posi2[1]<me.gridH and me.posi2[1]>-me.gridH) {
                            # sadly when zoomed in alot it draws too many crossings, this condition should help
                            me.setGridTextO(line.text1,[me.posi2[0]-20,me.posi2[1]+5]);
                            if (line.text2 != "") {
                                me.setGridTextO(line.text2,[me.posi2[0]+12,me.posi2[1]+5]);
                            }
                        }
                    } else {
                        me.posi3 = [(me.posi1[0]+me.posi2[0])*0.5, (me.posi1[1]+me.posi2[1])*0.5-5];
                        if (me.posi3[0]<me.gridH and me.posi3[0]>-me.gridH and me.posi3[1]<me.gridH and me.posi3[1]>-me.gridH) {
                            # sadly when zoomed in alot it draws too many crossings, this condition should help
                            me.setGridTextA(line.text,me.posi3);
                        }
                    }
                    me.posi1=me.posi2;
                } else {
                    me.posi1 = me.laloToTexelMap(coord.lat,coord.lon);
                    me.aline = me.gridGroup.createChild("path")
                        .moveTo(me.posi1)
                        .setStrokeLineWidth(lineWidth.grid)
                        .setColor(COLOR_YELLOW);
                }
                skip = 0;
            }
        }
        for (me.jjjj = me.gridTextNoO;me.jjjj<=me.gridTextMaxO;me.jjjj+=1) {
            me.gridTextO[me.jjjj].hide();
        }
        for (me.kkkk = me.gridTextNoA;me.kkkk<=me.gridTextMaxA;me.kkkk+=1) {
            me.gridTextA[me.kkkk].hide();
        }
        me.gridGroupText.update();
        me.gridGroup.update();
        me.gridGroupText.show();
        me.gridGroup.show();
    },

    setGridTextO: func (text, pos) {
        if (me.gridTextNoO > me.gridTextMaxO) {
                append(me.gridTextO,me.gridGroupText.createChild("text")
                        .setText(text)
                        .setColor(COLOR_YELLOW)
                        .setAlignment("center-top")
                        .setTranslation(pos)
                        .setFontSize(font.grid, 1));
            me.gridTextMaxO += 1;   
        } else {
            me.gridTextO[me.gridTextNoO].setText(text).setTranslation(pos);
        }
        me.gridTextO[me.gridTextNoO].show();
        me.gridTextNoO += 1;
    },
    
    setGridTextA: func (text, pos) {
        if (me.gridTextNoA > me.gridTextMaxA) {
                append(me.gridTextA,me.gridGroupText.createChild("text")
                        .setText(text)
                        .setColor(COLOR_YELLOW)
                        .setAlignment("center-bottom")
                        .setTranslation(pos)
                        .setFontSize(font.grid, 1));
            me.gridTextMaxA += 1;   
        } else {
            me.gridTextA[me.gridTextNoA].setText(text).setTranslation(pos);
        }
        me.gridTextA[me.gridTextNoA].show();
        me.gridTextNoA += 1;
    },

#  ███    ███  █████  ██████  
#  ████  ████ ██   ██ ██   ██ 
#  ██ ████ ██ ███████ ██████  
#  ██  ██  ██ ██   ██ ██      
#  ██      ██ ██   ██ ██      
#                             
#                             
    initMap: func {
        # map groups
        me.mapCentrum = me.root.createChild("group")
            .set("z-index", layer_z.display.map)
            .setTranslation(me.max_x*0.5,me.max_y*0.5);
        me.mapCenter = me.mapCentrum.createChild("group");
        me.mapRot = me.mapCenter.createTransform();
        me.mapFinal = me.mapCenter.createChild("group")
            .set("z-index",  layer_z.map.tiles);
        me.rootCenter = me.root.createChild("group")
            .setTranslation(me.max_x/2,me.max_y/2)
            .set("z-index",  layer_z.display.mapOverlay);
    },

    updateMapNames: func {
        if (me.mapShowPlaces) {
            type = "light_all";
            makePath = string.compileTemplate(maps_base ~ '/cartoLN/{z}/{x}/{y}.png');
        } else {
            type = "light_nolabels";
            makePath = string.compileTemplate(maps_base ~ '/cartoL/{z}/{x}/{y}.png');
        }
    },

    setupMap: func {
        me.mapFinal.removeAllChildren();
        for(var x = 0; x < num_tiles[0]; x += 1) {
            tiles[x] = setsize([], num_tiles[1]);
            for(var y = 0; y < num_tiles[1]; y += 1) {
                tiles[x][y] = me.mapFinal.createChild("image", "map-tile").set("z-index", 15);
                if (me.day == 1) {
                    #tiles[x][y].set("fill", COLOR_DAY);
                } else {
                    #tiles[x][y].set("fill", COLOR_NIGHT);
                }
            }
        }
    },

    whereIsMap: func {
        # update the map position
        me.lat_own = me.input.latitude.getValue();
        me.lon_own = me.input.longitude.getValue();
        if (me.mapSelfCentered) {
            # get current position
            me.lat = me.lat_own;
            me.lon = me.lon_own;# TODO: USE GPS/INS here.
        }       
        M2TEX = 1/(meterPerPixel[zoom]*math.cos(me.lat*D2R));
    },

    updateMap: func {
        # update the map
        if (lastDay != me.day)  {
            me.setupMap();
        }
        me.rootCenterY = me.ownPosition;#me.canvasY*0.875-(me.canvasY*0.875)*me.ownPosition;
        if (!me.mapSelfCentered) {
            me.lat_wp   = me.input.latitude.getValue();
            me.lon_wp   = me.input.longitude.getValue();
            me.tempReal = me.laloToTexel(me.lat,me.lon);
            me.rootCenter.setTranslation(me.max_x/2-me.tempReal[0], me.rootCenterY-me.tempReal[1]);
            #me.rootCenterTranslation = [width/2-me.tempReal[0], me.rootCenterY-me.tempReal[1]];
        } else {
            me.tempReal = [0,0];
            me.rootCenter.setTranslation(me.max_x/2, me.rootCenterY);
            #me.rootCenterTranslation = [width/2, me.rootCenterY];
        }
        me.mapCentrum.setTranslation(me.max_x/2, me.rootCenterY);

        me.n = math.pow(2, zoom);
        me.center_tile_float = [
            me.n * ((me.lon + 180) / 360),
            (1 - math.ln(math.tan(me.lat * D2R) + 1 / math.cos(me.lat * D2R)) / math.pi) / 2 * me.n
        ];
        # center_tile_offset[1]
        me.center_tile_int = [int(me.center_tile_float[0]), int(me.center_tile_float[1])];

        me.center_tile_fraction_x = me.center_tile_float[0] - me.center_tile_int[0];
        me.center_tile_fraction_y = me.center_tile_float[1] - me.center_tile_int[1];
#printf("centertile: %d,%d fraction %.2f,%.2f",me.center_tile_int[0],me.center_tile_int[1],me.center_tile_fraction_x,me.center_tile_fraction_y);
        me.tile_offset = [int(num_tiles[0]/2), int(num_tiles[1]/2)];

        # 3x3 example: (same for both canvas-tiles and map-tiles)
        #  *************************
        #  * -1,-1 *  0,-1 *  1,-1 *
        #  *************************
        #  * -1, 0 *  0, 0 *  1, 0 *
        #  *************************
        #  * -1, 1 *  0, 1 *  1, 1 *
        #  *************************
        #

        for(var xxx = 0; xxx < num_tiles[0]; xxx += 1) {
            for(var yyy = 0; yyy < num_tiles[1]; yyy += 1) {
                tiles[xxx][yyy].setTranslation(-int((me.center_tile_fraction_x - xxx+me.tile_offset[0]) * tile_size), -int((me.center_tile_fraction_y - yyy+me.tile_offset[1]) * tile_size));
            }
        }

        me.liveMap = 1;# TODO: Read from property if allow internet access
        me.zoomed = zoom != last_zoom;
        if(me.center_tile_int[0] != last_tile[0] or me.center_tile_int[1] != last_tile[1] or type != last_type or me.zoomed or me.liveMap != lastLiveMap or lastDay != me.day)  {
            for(var x = 0; x < num_tiles[0]; x += 1) {
                for(var y = 0; y < num_tiles[1]; y += 1) {
                    # inside here we use 'var' instead of 'me.' due to generator function, should be able to remember it.
                    var xx = me.center_tile_int[0] + x - me.tile_offset[0];
                    if (xx < 0) {
                        # when close to crossing 180 longitude meridian line, make sure we see the tiles on the positive side of the line.
                        xx = me.n + xx;#print(xx~" from "~(xx-me.n));
                    } elsif (xx >= me.n) {
                        # when close to crossing 180 longitude meridian line, make sure we dont double load the tiles on the negative side of the line.
                        xx = xx - me.n;#print(xx~" from "~(xx+me.n));
                    }
                    var pos = {
                        z: zoom,
                        x: xx,
                        y: me.center_tile_int[1] + y - me.tile_offset[1],
                        type: type
                    };

                    (func {# generator function
                        var img_path = makePath(pos);
                        var tile = tiles[x][y];
                        logprint(LOG_DEBUG, 'showing ' ~ img_path);
                        if( io.stat(img_path) == nil and me.liveMap == 1) { # image not found, save in $FG_HOME
                            var img_url = makeUrl(pos);
                            logprint(LOG_DEBUG, 'requesting ' ~ img_url);
                            http.save(img_url, img_path)
                                .done(func(r) {
                                    logprint(LOG_DEBUG, 'received image ' ~ img_path~" " ~ r.status ~ " " ~ r.reason);
                                    logprint(LOG_DEBUG, ""~(io.stat(img_path) != nil));
                                    tile.set("src", img_path);# this sometimes fails with: 'Cannot find image file' if use me. instead of var.
                                    tile.update();
                                    })
                              #.done(func {logprint(LOG_DEBUG, 'received image ' ~ img_path); tile.set("src", img_path);})
                              .fail(func (r) {logprint(LOG_INFO, 'Failed to get image ' ~ img_path ~ ' ' ~ r.status ~ ': ' ~ r.reason);
                                            tile.set("src", "Aircraft/f16/Nasal/CDU/emptyTile.png");
                                            tile.update();
                                            });
                        } elsif (io.stat(img_path) != nil) {# cached image found, reusing
                            logprint(LOG_DEBUG, 'loading ' ~ img_path);
                            tile.set("src", img_path);
                            tile.update();
                        } else {
                            # internet not allowed, so noise tile shown
                            tile.set("src", "Aircraft/f16/Nasal/CDU/noiseTile.png");
                            tile.update();
                        }
                    })();
                }
            }

        last_tile = me.center_tile_int;
        last_type = type;
        last_zoom = zoom;
        lastLiveMap = me.liveMap;
        lastDay = me.day;
        }

        me.mapCenter.setRotation(-me.input.heading.getValue()*D2R);
        #switched to direct rotation to try and solve issue with approach line not updating fast.
        me.mapCenter.update();
    },
};

var reinit_listener = setlistener("/sim/signals/reinit", func {CDU.calcZoomLevels();});

var looper = nil;
var main = func (module) {
    looper = maketimer(2, CDU, CDU.init);
    looper.singleShot = 1;
    looper.start();
}

var initCDU = func {
    CDU.init();
    initCDU = nil;
    main = nil;
}

var unload = func {
    if (CDU != nil) {
        CDU.del();
    }
    foreach(var key ; keys(f16_CDU)) {
        #print("Deleting ",key);
        f16_CDU[key] = nil;
    }    
}