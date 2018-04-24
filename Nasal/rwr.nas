RWRCanvas = {
    new: func (root, center, diameter) {
        var rwr = {parents: [RWRCanvas]};
        rwr.max_icons = 12;
        rwr.inner_radius = diameter/6;
        rwr.outer_radius = diameter/3;
        var font = int(0.08*diameter);
        var colorG = [0.3,1,0.3];
        var colorLG = [0,0.5,0];
        rwr.fadeTime = 7;#seconds
        rwr.rootCenter = root.createChild("group")
                .setTranslation(center[0],center[1]);
        
        root.createChild("path")
           .moveTo(0, diameter/2)
           .arcSmallCW(diameter/2, diameter/2, 0, diameter, 0)
           .arcSmallCW(diameter/2, diameter/2, 0, -diameter, 0)
           .setStrokeLineWidth(1)
           .setColor(1, 1, 1);
        root.createChild("path")
           .moveTo(diameter/2-rwr.inner_radius, diameter/2)
           .arcSmallCW(rwr.inner_radius, rwr.inner_radius, 0, rwr.inner_radius*2, 0)
           .arcSmallCW(rwr.inner_radius, rwr.inner_radius, 0, -rwr.inner_radius*2, 0)
           .setStrokeLineWidth(1)
           .setColor(colorLG);
        root.createChild("path")
           .moveTo(diameter/2-rwr.outer_radius, diameter/2)
           .arcSmallCW(rwr.outer_radius, rwr.outer_radius, 0, rwr.outer_radius*2, 0)
           .arcSmallCW(rwr.outer_radius, rwr.outer_radius, 0, -rwr.outer_radius*2, 0)
           .setStrokeLineWidth(1)
           .setColor(colorLG);
        rwr.texts = setsize([],rwr.max_icons);
        for (var i = 0;i<rwr.max_icons;i+=1) {
            rwr.texts[i] = rwr.rootCenter.createChild("text")
                .setText("00")
                .setAlignment("center-center")
                .setColor(colorG)
                .setFontSize(font, 1.0)
                .hide();

        }
        rwr.symbol_hat = setsize([],rwr.max_icons);
        for (var i = 0;i<rwr.max_icons;i+=1) {
            rwr.symbol_hat[i] = rwr.rootCenter.createChild("path")
                    .moveTo(0,-font)
                    .lineTo(font*0.7,-font*0.5)
                    .moveTo(0,-font)
                    .lineTo(-font*0.7,-font*0.5)
                    .setStrokeLineWidth(1)
                    .setColor(colorG)
                    .hide();
        }

 #       me.symbol_16_SAM = setsize([],max_icons);
#       for (var i = 0;i<max_icons;i+=1) {
 #          me.symbol_16_SAM[i] = me.rootCenter.createChild("path")
#                   .moveTo(-11, 7)
#                   .lineTo(-9, -7)
#                   .moveTo(-9, -7)
#                   .lineTo(-9, -4)
#                   .moveTo(-9, -8)
#                   .lineTo(-11, -4)
#                   .setStrokeLineWidth(1)
#                   .setColor(1,0,0)
#                   .hide();
#        }
        rwr.symbol_launch = setsize([],rwr.max_icons);
        for (var i = 0;i<rwr.max_icons;i+=1) {
            rwr.symbol_launch[i] = rwr.rootCenter.createChild("path")
                    .moveTo(font*1.2, 0)
                    .arcSmallCW(font*1.2, font*1.2, 0, -font*2.4, 0)
                    .arcSmallCW(font*1.2, font*1.2, 0, font*2.4, 0)
                    .setStrokeLineWidth(1)
                    .setColor(colorG)
                    .hide();
        }
        rwr.symbol_new = setsize([],rwr.max_icons);
        for (var i = 0;i<rwr.max_icons;i+=1) {
            rwr.symbol_new[i] = rwr.rootCenter.createChild("path")
                    .moveTo(font*1.2, 0)
                    .arcSmallCCW(font*1.2, font*1.2, 0, -font*2.4, 0)
                    .setStrokeLineWidth(1)
                    .setColor(colorG)
                    .hide();
        }
#        rwr.symbol_16_lethal = setsize([],max_icons);
#        for (var i = 0;i<max_icons;i+=1) {
#           rwr.symbol_16_lethal[i] = rwr.rootCenter.createChild("path")
#                   .moveTo(10, 10)
#                   .lineTo(10, -10)
#                   .lineTo(-10,-10)
#                   .lineTo(-10,10)
#                   .lineTo(10, 10)
#                   .setStrokeLineWidth(1)
#                   .setColor(1,0,0)
#                   .hide();
#        }
        rwr.symbol_priority = rwr.rootCenter.createChild("path")
                    .moveTo(0, font*1.2)
                    .lineTo(font*1.2, 0)
                    .lineTo(0,-font*1.2)
                    .lineTo(-font*1.2,0)
                    .lineTo(0, font*1.2)
                    .setStrokeLineWidth(1)
                    .setColor(colorG)
                    .hide();
        
#        rwr.symbol_16_air = setsize([],max_icons);
#        for (var i = 0;i<max_icons;i+=1) {
 #          rwr.symbol_16_air[i] = rwr.rootCenter.createChild("path")
#                   .moveTo(15, 0)
#                   .lineTo(0,-15)
#                   .lineTo(-15,0)
#                   .setStrokeLineWidth(1)
#                   .setColor(1,0,0)
#                   .hide();
#        }
        rwr.AIRCRAFT_VIGGEN = "37";
        rwr.AIRCRAFT_EAGLE = "15";
        rwr.AIRCRAFT_TOMCAT = "14";
        rwr.AIRCRAFT_BUK = "11";
        rwr.AIRCRAFT_MIG = "21";
        rwr.AIRCRAFT_MIRAGE = "20";
        rwr.AIRCRAFT_FALCON = "16";
        rwr.AIRCRAFT_FRIGATE = "SH";
        rwr.AIRCRAFT_UNKNOWN = "00";
        rwr.AIRCRAFT_AI = "AI";
        rwr.lookupType = {
                "f-14b":                    rwr.AIRCRAFT_TOMCAT,     #guess
                "F-14D":                    rwr.AIRCRAFT_TOMCAT,     #guess
                "F-15C":                    rwr.AIRCRAFT_EAGLE,     #low end of sources
                "F-15D":                    rwr.AIRCRAFT_EAGLE,     #low end of sources
                "F-16":                     rwr.AIRCRAFT_FALCON,      #guess
                "JA37-Viggen":              rwr.AIRCRAFT_VIGGEN,      #guess
                "AJ37-Viggen":              rwr.AIRCRAFT_VIGGEN,      #guess
                "AJS37-Viggen":             rwr.AIRCRAFT_VIGGEN,      #guess
                "JA37Di-Viggen":            rwr.AIRCRAFT_VIGGEN,      #guess
                "m2000-5":                  rwr.AIRCRAFT_MIRAGE,
                "m2000-5B":                 rwr.AIRCRAFT_MIRAGE,
                "MiG-21bis":                rwr.AIRCRAFT_MIG,
                "buk-m2":                   rwr.AIRCRAFT_BUK,      #estimated with blender
                "missile_frigate":          rwr.AIRCRAFT_FRIGATE,    #estimated with blender
                "AI":                       rwr.AIRCRAFT_AI,
        };
        rwr.shownList = [];
        return rwr;
    },
    update: func (list) {
        #printf("list %d", size(list));
        me.elapsed = getprop("sim/time/elapsed-sec");
        var sorter = func(a, b) {
            if(a[1] > b[1]){
                return -1; # A should before b in the returned vector
            }elsif(a[1] == b[1]){
                return 0; # A is equivalent to b 
            }else{
                return 1; # A should after b in the returned vector
            }
        }
        var sortedlist = sort(list, sorter);
        var newList = [];
        me.i = 0;
        me.hat = 0;
        me.newt = 0;
        me.prio = 0;
        me.launch = 0;
        var newsound = 0;
        foreach(contact; sortedlist) {
            me.typ=me.lookupType[contact[0].get_model()];
            if (me.i > me.max_icons-1) {
                break;
            }
            if (me.typ == nil) {
                continue;
            }
            #print("show "~me.i~" "~me.typ~" "~contact[0].get_model()~"  "~contact[1]);
            me.threat = contact[1];#print(me.threat);
            
            if (me.threat > 0.5) {
                me.threat = me.inner_radius;# inner circle
            } elsif (me.threat > 0) {
                me.threat = me.outer_radius;# outer circle
            } else {
                continue;
            }
            me.dev = -geo.normdeg180(contact[0].get_bearing()-getprop("orientation/heading-deg"))+90;
            me.x = math.cos(me.dev*D2R)*me.threat;
            me.y = -math.sin(me.dev*D2R)*me.threat;
            me.texts[me.i].setTranslation(me.x,me.y);
            me.texts[me.i].setText(me.typ);
            me.texts[me.i].show();
            if (me.prio == 0 and me.typ != me.AIRCRAFT_AI) {# 
                me.symbol_priority.setTranslation(me.x,me.y);
                me.symbol_priority.show();
                me.prio = 1;
            }
            if (!(me.typ == me.AIRCRAFT_BUK or me.typ == me.AIRCRAFT_FRIGATE or me.typ == me.AIRCRAFT_AI)) {
                me.symbol_hat[me.hat].setTranslation(me.x,me.y);
                me.symbol_hat[me.hat].show();
                me.hat += 1;
            }
            if (contact[0].get_Callsign()==getprop("sound/rwr-launch") and 10*(me.elapsed-int(me.elapsed))>5) {#blink 2Hz
                me.symbol_launch[me.launch].setTranslation(me.x,me.y);
                me.symbol_launch[me.launch].show();
                me.launch += 1;
            }
            var popup = me.elapsed;
            foreach(var old; me.shownList) {
                if(old[0].getUnique()==contact[0].getUnique()) {
                    popup = old[1];
                    break;
                }
            }
            if (popup == me.elapsed) {
                newsound = 1;
            }
            if (popup > me.elapsed-me.fadeTime) {
                me.symbol_new[me.newt].setTranslation(me.x,me.y);
                me.symbol_new[me.newt].show();
                me.symbol_new[me.newt].update();
                me.newt += 1;
            }
            #printf("display %s %d",contact[0].get_Callsign(), me.threat);
            append(newList, [contact[0],popup]);
            me.i += 1;
        }
        me.shownList = newList;
        if (newsound == 1) setprop("sound/rwr-new", !getprop("sound/rwr-new"));
        for (;me.i<me.max_icons;me.i+=1) {
            me.texts[me.i].hide();
        }
        for (;me.hat<me.max_icons;me.hat+=1) {
            me.symbol_hat[me.hat].hide();
        }
        for (;me.newt<me.max_icons;me.newt+=1) {
            me.symbol_new[me.newt].hide();
        }
        for (;me.launch<me.max_icons;me.launch+=1) {
            me.symbol_launch[me.launch].hide();
        }
        if (me.prio == 0) {
            me.symbol_priority.hide();
        }
    },
};

var rwr = nil;
var main_init_listener = setlistener("sim/signals/fdm-initialized", func {
  if (getprop("sim/signals/fdm-initialized") == 1) {
     var diam = 256;
    var cv = canvas.new({
        "name": "F16 RWR",
        "size": [diam,diam], 
        "view": [diam,diam],
        "mipmapping": 1
    });  

    cv.addPlacement({"node": "bkg", "texture":"rwr-bkg.png"});
    cv.setColorBackground(0, 0.35, 0);
    var root = cv.createGroup();
    rwr = RWRCanvas.new(root, [diam/2,diam/2],diam);
     removelistener(main_init_listener);
  }
 }, 0, 0);