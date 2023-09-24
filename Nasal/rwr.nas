RWRCanvas = {
    new: func (_ident, root, center, diameter) {
        var rwr = {parents: [RWRCanvas]};
        var block = getprop("sim/variant-id");
        rwr.max_icons = block==0 or block==1 or block==3?12:16;# Page 209 of MLU tape 1
        var radius = diameter/2;
        rwr.inner_radius = radius*0.30;# field where inner IDs are placed
        rwr.outer_radius = radius*0.65;# field where outer IDs are placed

        rwr.sep1_radius = radius*0.300;
        rwr.sep2_radius = radius*0.525;
        rwr.sep3_radius = radius*0.775;

        rwr.circle_radius_full = radius*0.974;
        rwr.circle_radius_big = radius*0.5;
        rwr.circle_radius_small = radius*0.125;
        var tick_long = radius*0.25;
        var tick_full = radius-rwr.circle_radius_small;
        var tick_short = tick_long*0.5;
        var font = int(0.08*diameter);
        var colorG = [0.3,1,0.3];
        var colorLG = [0.16,0.8,0.13];
        var colorBG = [0.4,0.48,0.4];
        rwr.stroke = 2;
        rwr.fadeTime = 7;#seconds
        rwr.rootCenter = root.createChild("group")
                .setTranslation(center[0],center[1])
                .set("font","B612/B612Mono-Bold.ttf");
        
#        root.createChild("path")
#           .moveTo(0, diameter/2)
#           .arcSmallCW(diameter/2, diameter/2, 0, diameter, 0)
#           .arcSmallCW(diameter/2, diameter/2, 0, -diameter, 0)
#           .setStrokeLineWidth(rwr.stroke*1.8)
#           .setColor(1, 1, 1);
        root.createChild("path")# inner circle
           .moveTo(diameter/2-rwr.circle_radius_small, diameter/2)
           .arcSmallCW(rwr.circle_radius_small, rwr.circle_radius_small, 0, rwr.circle_radius_small*2, 0)
           .arcSmallCW(rwr.circle_radius_small, rwr.circle_radius_small, 0, -rwr.circle_radius_small*2, 0)
           .setStrokeLineWidth(rwr.stroke*1.8)
           .setColor(colorBG);
        root.createChild("path")# outer circle
           .moveTo(diameter/2-rwr.circle_radius_big, diameter/2)
           .arcSmallCW(rwr.circle_radius_big, rwr.circle_radius_big, 0, rwr.circle_radius_big*2, 0)
           .arcSmallCW(rwr.circle_radius_big, rwr.circle_radius_big, 0, -rwr.circle_radius_big*2, 0)
           .setStrokeLineWidth(rwr.stroke*1.8)
           .setColor(colorBG);
        root.createChild("path")# full circle
           .moveTo(diameter/2-rwr.circle_radius_full, diameter/2)
           .arcSmallCW(rwr.circle_radius_full, rwr.circle_radius_full, 0, rwr.circle_radius_full*2, 0)
           .arcSmallCW(rwr.circle_radius_full, rwr.circle_radius_full, 0, -rwr.circle_radius_full*2, 0)
           .setStrokeLineWidth(rwr.stroke*1.8)
           .setColor(colorBG);
        root.createChild("path")#middle cross
           .moveTo(diameter/2-rwr.circle_radius_small, diameter/2)
           .horiz(rwr.circle_radius_small/2)
           .moveTo(diameter/2+rwr.circle_radius_small, diameter/2)
           .horiz(-rwr.circle_radius_small/2)
           .moveTo(diameter/2, diameter/2-rwr.circle_radius_small)
           .vert(rwr.circle_radius_small*0.5)
           .moveTo(diameter/2, diameter/2+rwr.circle_radius_small)
           .vert(-rwr.circle_radius_small*0.5)
           .setStrokeLineWidth(rwr.stroke*2.1)
           .setColor(colorLG);
        rwr.noisebar = root.createChild("path")#middle cross moving tick
           .moveTo(diameter/2+rwr.circle_radius_small*0.5, diameter/2)
           .vert(-rwr.circle_radius_small*0.25)
           .setStrokeLineWidth(rwr.stroke*2.1)
           .setColor(colorLG);
        root.createChild("path")# 4 main ticks
           .moveTo(0,diameter*0.5)
           .horiz(tick_full)
           .moveTo(diameter,diameter*0.5)
           .horiz(-tick_full)
           .moveTo(diameter*0.5,0)
           .vert(tick_full)
           .moveTo(diameter*0.5,diameter)
           .vert(-tick_full)
           .setStrokeLineWidth(rwr.stroke*1.8)
           .setColor(colorBG);
        rwr.rootCenter.createChild("path")# minor ticks
           .moveTo(radius*math.cos(30*D2R),radius*math.sin(-30*D2R))
           .lineTo((radius-tick_short)*math.cos(30*D2R),(radius-tick_short)*math.sin(-30*D2R))
           .moveTo(radius*math.cos(15*D2R),radius*math.sin(-15*D2R))
           .lineTo((radius-tick_short)*math.cos(15*D2R),(radius-tick_short)*math.sin(-15*D2R))
           .moveTo(radius*math.cos(45*D2R),radius*math.sin(-45*D2R))
           .lineTo((radius-tick_long)*math.cos(45*D2R),(radius-tick_long)*math.sin(-45*D2R))
           .moveTo(radius*math.cos(60*D2R),radius*math.sin(-60*D2R))
           .lineTo((radius-tick_short)*math.cos(60*D2R),(radius-tick_short)*math.sin(-60*D2R))
           .moveTo(radius*math.cos(75*D2R),radius*math.sin(-75*D2R))
           .lineTo((radius-tick_short)*math.cos(75*D2R),(radius-tick_short)*math.sin(-75*D2R))
           
           .moveTo(radius*math.cos(30*D2R),radius*math.sin(30*D2R))
           .lineTo((radius-tick_short)*math.cos(30*D2R),(radius-tick_short)*math.sin(30*D2R))
           .moveTo(radius*math.cos(15*D2R),radius*math.sin(15*D2R))
           .lineTo((radius-tick_short)*math.cos(15*D2R),(radius-tick_short)*math.sin(15*D2R))
           .moveTo(radius*math.cos(45*D2R),radius*math.sin(45*D2R))
           .lineTo((radius-tick_long)*math.cos(45*D2R),(radius-tick_long)*math.sin(45*D2R))
           .moveTo(radius*math.cos(60*D2R),radius*math.sin(60*D2R))
           .lineTo((radius-tick_short)*math.cos(60*D2R),(radius-tick_short)*math.sin(60*D2R))
           .moveTo(radius*math.cos(75*D2R),radius*math.sin(75*D2R))
           .lineTo((radius-tick_short)*math.cos(75*D2R),(radius-tick_short)*math.sin(75*D2R))

           .moveTo(-radius*math.cos(30*D2R),radius*math.sin(-30*D2R))
           .lineTo(-(radius-tick_short)*math.cos(30*D2R),(radius-tick_short)*math.sin(-30*D2R))
           .moveTo(-radius*math.cos(15*D2R),radius*math.sin(-15*D2R))
           .lineTo(-(radius-tick_short)*math.cos(15*D2R),(radius-tick_short)*math.sin(-15*D2R))
           .moveTo(-radius*math.cos(45*D2R),radius*math.sin(-45*D2R))
           .lineTo(-(radius-tick_long)*math.cos(45*D2R),(radius-tick_long)*math.sin(-45*D2R))
           .moveTo(-radius*math.cos(60*D2R),radius*math.sin(-60*D2R))
           .lineTo(-(radius-tick_short)*math.cos(60*D2R),(radius-tick_short)*math.sin(-60*D2R))
           .moveTo(-radius*math.cos(75*D2R),radius*math.sin(-75*D2R))
           .lineTo(-(radius-tick_short)*math.cos(75*D2R),(radius-tick_short)*math.sin(-75*D2R))
           
           .moveTo(-radius*math.cos(30*D2R),radius*math.sin(30*D2R))
           .lineTo(-(radius-tick_short)*math.cos(30*D2R),(radius-tick_short)*math.sin(30*D2R))
           .moveTo(-radius*math.cos(15*D2R),radius*math.sin(15*D2R))
           .lineTo(-(radius-tick_short)*math.cos(15*D2R),(radius-tick_short)*math.sin(15*D2R))
           .moveTo(-radius*math.cos(45*D2R),radius*math.sin(45*D2R))
           .lineTo(-(radius-tick_long)*math.cos(45*D2R),(radius-tick_long)*math.sin(45*D2R))
           .moveTo(-radius*math.cos(60*D2R),radius*math.sin(60*D2R))
           .lineTo(-(radius-tick_short)*math.cos(60*D2R),(radius-tick_short)*math.sin(60*D2R))
           .moveTo(-radius*math.cos(75*D2R),radius*math.sin(75*D2R))
           .lineTo(-(radius-tick_short)*math.cos(75*D2R),(radius-tick_short)*math.sin(75*D2R))
           .setStrokeLineWidth(rwr.stroke*1.8)
           .setColor(colorBG);
        rwr.texts = setsize([],rwr.max_icons);# aircraft ID
        for (var i = 0;i<rwr.max_icons;i+=1) {
            rwr.texts[i] = rwr.rootCenter.createChild("text")
                .setText("00")
                .setAlignment("center-center")
                .setColor(colorG)
                .setFontSize(font, 1)
                .hide();

        }
        rwr.symbol_hat = setsize([],rwr.max_icons);# airborne symbol over ID
        for (var i = 0;i<rwr.max_icons;i+=1) {
            rwr.symbol_hat[i] = rwr.rootCenter.createChild("path")
                    .moveTo(0,-font)
                    .lineTo(font*0.7,-font*0.5)
                    .moveTo(0,-font)
                    .lineTo(-font*0.7,-font*0.5)
                    .setStrokeLineWidth(rwr.stroke*1.2)
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
#                   .setStrokeLineWidth(rwr.stroke*1)
#                   .setColor(1,0,0)
#                   .hide();
#        }
        rwr.symbol_launch = setsize([],rwr.max_icons);
        for (var i = 0;i<rwr.max_icons;i+=1) {
            rwr.symbol_launch[i] = rwr.rootCenter.createChild("path")
                    .moveTo(font*1.2, 0)
                    .arcSmallCW(font*1.2, font*1.2, 0, -font*2.4, 0)
                    .arcSmallCW(font*1.2, font*1.2, 0, font*2.4, 0)
                    .setStrokeLineWidth(rwr.stroke*1.2)
                    .setColor(colorG)
                    .hide();
        }
        rwr.symbol_new = setsize([],rwr.max_icons);
        for (var i = 0;i<rwr.max_icons;i+=1) {
            rwr.symbol_new[i] = rwr.rootCenter.createChild("path")
                    .moveTo(font*1.2, 0)
                    .arcSmallCCW(font*1.2, font*1.2, 0, -font*2.4, 0)
                    .setStrokeLineWidth(rwr.stroke*1.2)
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
#                   .setStrokeLineWidth(rwr.stroke*1)
#                   .setColor(1,0,0)
#                   .hide();
#        }
        rwr.symbol_priority = rwr.rootCenter.createChild("path")
                    .moveTo(0, font*1.2)
                    .lineTo(font*1.2, 0)
                    .lineTo(0,-font*1.2)
                    .lineTo(-font*1.2,0)
                    .lineTo(0, font*1.2)
                    .setStrokeLineWidth(rwr.stroke*1.2)
                    .setColor(colorG)
                    .hide();
        rwr.symbol_maw = rwr.rootCenter.createChild("path")
                    .moveTo(0,-font*1.2)
                    .lineTo(font*0.2, -font*1.0)
                    .vert(font*2)
                    .horiz(-font*0.4)
                    .vert(-font*2)
                    .lineTo(0,-font*1.2)
                    .setStrokeLineWidth(rwr.stroke*1.2)
                    .setColor(colorG)
                    .hide();
                    
        
#        rwr.symbol_16_air = setsize([],max_icons);
#        for (var i = 0;i<max_icons;i+=1) {
#           rwr.symbol_16_air[i] = rwr.rootCenter.createChild("path")
#                   .moveTo(15, 0)
#                   .lineTo(0,-15)
#                   .lineTo(-15,0)
#                   .setStrokeLineWidth(rwr.stroke*1)
#                   .setColor(1,0,0)
#                   .hide();
#        }

        rwr.AIRCRAFT_UNKNOWN  = "U";
        rwr.ASSET_AI          = "AI";
        rwr.AIRCRAFT_SEARCH   = "S";
        
        rwr.shownList = [];
        #
        # recipient that will be registered on the global transmitter and connect this
        # subsystem to allow subsystem notifications to be received
        rwr.recipient = emesary.Recipient.new(_ident);
        rwr.recipient.parent_obj = rwr;

        rwr.recipient.Receive = func(notification)
        {
            if (notification.NotificationType == "FrameNotification" and notification.FrameCount == 2)
            {
                me.parent_obj.update(radar_system.f16_rwr.vector_aicontacts_threats, "normal");
                return emesary.Transmitter.ReceiptStatus_OK;
            }
            return emesary.Transmitter.ReceiptStatus_NotProcessed;
        };
        emesary.GlobalTransmitter.Register(rwr.recipient);
        
        rwr.noiseup = 10;
        return rwr;
    },
    assignSepSpot: func {
        # me.dev        angle_deg
        # me.sep_spots  0 to 2  45, 20, 15
        # me.threat     0 to 2
        # me.sep_angles 
        # return   me.dev,  me.threat
        me.newdev = me.dev;
        me.assignIdealSepSpot();
        me.plus = me.sep_angles[me.threat];
        me.dir  = 0;
        me.count = 1;
        while(me.sep_spots[me.threat][me.spot] and me.count < size(me.sep_spots[me.threat])) {

            if (me.dir == 0) me.dir = 1;
            elsif (me.dir > 0) me.dir = -me.dir;
            elsif (me.dir < 0) me.dir = -me.dir+1;

            #printf("%2s: Spot %d taken. Trying %d direction.",me.typ, me.spot, me.dir);

            me.newdev = me.dev + me.plus * me.dir;

            me.assignIdealSepSpot();
            me.count += 1;
        }

        me.sep_spots[me.threat][me.spot] += 1;

        # finished assigning spot
        #printf("%2s: Spot %d assigned. Ring=%d",me.typ, me.spot, me.threat);
        me.dev = me.spot * me.plus;
        if (me.threat == 0) {
            me.threat = me.sep1_radius;
        } elsif (me.threat == 1) {
            me.threat = me.sep2_radius;
        } elsif (me.threat == 2) {
            me.threat = me.sep3_radius;
        }
    },
    assignIdealSepSpot: func {
        me.spot = math.round(geo.normdeg(me.newdev)/me.sep_angles[me.threat]);
        if (me.spot >= size(me.sep_spots[me.threat])) me.spot = 0;
    },
    update: func (list, type) {
        if (me.noiseup == 10) {
            me.noisebar.setTranslation(0,me.circle_radius_small*0.25);
        } elsif (me.noiseup == 1) {
            me.noisebar.setTranslation(0,0);
        }
        me.noiseup += 1;
        if (me.noiseup > 20) me.noiseup = 1;
#        printf("list %d type %s", size(list), type);
        me.sep = getprop("f16/ews/rwr-separate");
        me.showUnknowns = getprop("f16/ews/rwr-show-unknowns");
        me.pri5 = getprop("f16/ews/rwr-show-priority-only");
        me.elapsed = getprop("sim/time/elapsed-sec");
        me.semiCallsign = getprop("payload/armament/MAW-semiactive-callsign");
        me.launchCallsign = getprop("sound/rwr-launch");
        if (me.launchCallsign == "" or me.launchCallsign == nil) {
            me.launchCallsign = "-........-";
        }
        if (me.semiCallsign == "" or me.semiCallsign == nil) {
            me.semiCallsign = "-........-";
        }
        var sorter = func(a, b) {
            if(a[1] > b[1]){
                return -1; # A should before b in the returned vector
            }elsif(a[1] == b[1]){
                return 0; # A is equivalent to b 
            }else{
                return 1; # A should after b in the returned vector
            }
        }
        

        #list ~= test_list;# Uncomment this line to test the RWR display.

        me.sortedlist = sort(list, sorter);

        me.sep_spots = [[0,0,0,0,0,0,0,0],#45 degs  8
                        [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],# 20 degs  18
                        [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]];# 15 degs  24
        me.sep_angles = [45,20,15];

        me.newList = [];
        me.i = 0;
        me.prio = 0;
        me.newsound = 0;
        me.priCount = 0;
        me.priFlash = 0;# Flash the PRI light
        me.unkFlash = 0;# Flash the UNK light
        foreach(me.contact; me.sortedlist) {
            me.dbEntry = radar_system.getDBEntry(me.contact[0].getModel());
            me.typ = me.dbEntry.rwrCode;
            if (me.i > me.max_icons-1) {
                break;
            }
            if (me.typ == nil) {
                me.typ = me.AIRCRAFT_UNKNOWN;
                if (!me.showUnknowns) {
                  me.unkFlash = 1;
                  continue;
                }
            }
            if (me.typ == me.ASSET_AI) {
                if (!me.showUnknowns) {
                  #me.unkFlash = 1; # We don't flash for AI, that would just be distracting
                  continue;
                }
            }
            #print("show "~me.i~" "~me.typ~" "~contact[0].getModel()~"  "~contact[1]);

            if (me.contact[0].get_range() > 150) {
                continue;
            }

            me.threat = me.contact[1];#print(me.threat);

            if (me.threat <= 0) {
                continue;
            }

            if (me.pri5 and me.priCount >= 5) {
                me.priFlash = 1;
                continue;
            }
            me.priCount += 1;

            

            if (!me.sep) {
            
                if (me.threat > 0.5 and me.typ != me.AIRCRAFT_UNKNOWN and me.typ != me.AIRCRAFT_SEARCH) {
                    me.threat = me.inner_radius;# inner circle
                } else {
                    me.threat = me.outer_radius;# outer circle
                }
            
                me.dev = -me.contact[2]+90;
            } else {
                me.dev = -me.contact[2]+90;

                if (me.threat > 0.5 and me.typ != me.AIRCRAFT_UNKNOWN and me.typ != me.AIRCRAFT_SEARCH) {
                    me.threat = 0;
                } elsif (me.threat > 0.25) {
                    me.threat = 1;
                } else {
                    me.threat = 2;
                }
                me.assignSepSpot();
            }




            me.x = math.cos(me.dev*D2R)*me.threat;
            me.y = -math.sin(me.dev*D2R)*me.threat;
            me.texts[me.i].setTranslation(me.x,me.y);
            me.texts[me.i].setText(me.typ);
            me.texts[me.i].show();
            
            if (me.prio == 0 and me.typ != me.ASSET_AI and me.typ != me.AIRCRAFT_UNKNOWN and me.typ != me.AIRCRAFT_SEARCH) {# 
                me.symbol_priority.setTranslation(me.x,me.y);
                me.symbol_priority.show();
                me.prio = 1;
            }
            if (me.contact[0].getType() == armament.AIR) {
                #air-borne
                me.symbol_hat[me.i].setTranslation(me.x,me.y);
                me.symbol_hat[me.i].show();
            } else {
                me.symbol_hat[me.i].hide();
            }
            if ((me.contact[0].get_Callsign()==me.launchCallsign or me.contact[0].get_Callsign()==me.semiCallsign) and 5*(me.elapsed-int(me.elapsed))>2.5) {#blink 4Hz
                me.symbol_launch[me.i].setTranslation(me.x,me.y);
                me.symbol_launch[me.i].show();
            } else {
                me.symbol_launch[me.i].hide();
            }
            me.popupNew = me.elapsed;
            foreach(me.old; me.shownList) {
                if(me.contact[0]["test"] == 1 or me.old[0]["test"] == 1) {
                    # this is just to handle the test cases if you uncomment them
                    if (me.old[0].get_Callsign() == me.contact[0].get_Callsign()) {
                      me.popupNew = me.old[1];
                      break;
                    }
                } elsif(me.contact[0].equals(me.old[0])) {
                    me.popupNew = me.old[1];
                    break;
                }
            }
            if (me.popupNew == me.elapsed) {
                me.newsound = 1;
            }
            if (me.popupNew > me.elapsed-me.fadeTime) {
                me.symbol_new[me.i].setTranslation(me.x,me.y);
                me.symbol_new[me.i].show();
                me.symbol_new[me.i].update();
            } else {
                me.symbol_new[me.i].hide();
            }
            #printf("display %s %d",contact[0].get_Callsign(), me.threat);
            append(me.newList, [me.contact[0],me.popupNew]);
            me.i += 1;
        }
        me.shownList = me.newList;
        for (;me.i<me.max_icons;me.i+=1) {
            me.texts[me.i].hide();
            me.symbol_hat[me.i].hide();
            me.symbol_new[me.i].hide();
            me.symbol_launch[me.i].hide();
        }
        if (me.prio == 0) {
            me.symbol_priority.hide();
        }
        if (me.newsound == 1) setprop("sound/rwr-new", !getprop("sound/rwr-new"));
        setprop("f16/ews/rwr-pri", me.pri5 and (!me.priFlash or math.mod(me.noiseup, 5) < 2.5));        # PRI light 
        setprop("f16/ews/rwr-unk", me.showUnknowns or (me.unkFlash and math.mod(me.noiseup, 5) < 2.5)); # UNK light
        
        if (getprop("payload/armament/MAW-active")) {
          me.mawdegs = getprop("payload/armament/MAW-bearing");
          me.dev = -geo.normdeg180(me.mawdegs-getprop("orientation/heading-deg"))+90;
          me.x = math.cos(me.dev*D2R)*(me.inner_radius+me.outer_radius)*0.5;
          me.y = -math.sin(me.dev*D2R)*(me.inner_radius+me.outer_radius)*0.5;
          me.symbol_maw.setRotation(-(me.dev+90)*D2R);
          me.symbol_maw.setTranslation(me.x, me.y);
          me.symbol_maw.show();
        } else {
          me.symbol_maw.hide();
        }
    },
};
var test_equals = func {
    return it.get_Callsign()==me.get_Callsign() and it.getModel()==me.getModel();
};
var test_list = [
            [{test:1,getModel:func{return "buk-m2";}, get_range:func{return 30;}, get_Speed:func{return 65;}, get_Callsign:func{return "j";},equals:test_equals}, 0.45, -0],
            [{test:1,getModel:func{return "s-300";}, get_range:func{return 30;}, get_Speed:func{return 65;}, get_Callsign:func{return "i";},equals:test_equals}, 0.45, -5],
            [{test:1,getModel:func{return "A-50";}, get_range:func{return 30;}, get_Speed:func{return 65;}, get_Callsign:func{return "h";},equals:test_equals}, 0.45, -15],
            [{test:1,getModel:func{return "s-200";}, get_range:func{return 30;}, get_Speed:func{return 65;}, get_Callsign:func{return "g";},equals:test_equals}, 0.20, -25],
            [{test:1,getModel:func{return "S-75";}, get_range:func{return 30;}, get_Speed:func{return 65;}, get_Callsign:func{return "f";},equals:test_equals}, 0.20, -30],
            [{test:1,getModel:func{return "MIM104D";}, get_range:func{return 30;}, get_Speed:func{return 65;}, get_Callsign:func{return "e";},equals:test_equals}, 0.20, -30],
            [{test:1,getModel:func{return "fleet";}, get_range:func{return 30;}, get_Speed:func{return 65;}, get_Callsign:func{return "d";},equals:test_equals}, 0.20, -25],
            [{test:1,getModel:func{return "SA-6";}, get_range:func{return 30;}, get_Speed:func{return 65;}, get_Callsign:func{return "c";},equals:test_equals}, 0.20, -30],
            [{test:1,getModel:func{return "missile_frigate";}, get_range:func{return 30;}, get_Speed:func{return 65;}, get_Callsign:func{return "b";},equals:test_equals}, 0.20, -30],
            [{test:1,getModel:func{return "theUFO";}, get_range:func{return 30;}, get_Speed:func{return 65;}, get_Callsign:func{return "a";},equals:test_equals}, 0.20, -100],# This one will show up as unknown
            [{test:1,getModel:func{return "s-300";}, get_range:func{return 30;}, get_Speed:func{return 65;}, get_Callsign:func{return "k";},equals:test_equals}, 0.70, 180],
            [{test:1,getModel:func{return "s-300";}, get_range:func{return 30;}, get_Speed:func{return 65;}, get_Callsign:func{return "l";},equals:test_equals}, 0.75, 180],
            [{test:1,getModel:func{return "AI";}, get_range:func{return 30;}, get_Speed:func{return 65;}, get_Callsign:func{return "m";},equals:test_equals}, 0.01, 100],
];


var diam = 512;
var cv = canvas.new({
                     "name": "F16 RWR",
                     "size": [diam,diam], 
                     "view": [diam,diam],
                     "mipmapping": 1
                    });  

cv.addPlacement({"node": "bkg", "texture":"rwr-bkg.png"});
if (getprop("sim/variant-id") == 2) {
cv.setColorBackground(0, 0.0625, 0);
} else if (getprop("sim/variant-id") == 4) {
cv.setColorBackground(0, 0.0625, 0);
} else if (getprop("sim/variant-id") == 5) {
cv.setColorBackground(0, 0.0625, 0);
} else if (getprop("sim/variant-id") == 6) {
cv.setColorBackground(0, 0.0625, 0);
} else {
cv.setColorBackground(0.01, 0.105, 0);
};
var root = cv.createGroup();
var rwr = RWRCanvas.new("RWRCanvas", root, [diam/2,diam/2],diam);

