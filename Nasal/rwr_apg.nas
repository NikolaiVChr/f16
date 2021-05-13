 #---------------------------------------------------------------------------
 #
 #	Title                : RWR APG simulation
 #
 #	File Type            : Implementation File
 #
 #	Description          : 

 #	Authors              : Nikolai V. Chr
 #
 #	Date                 : 
 #
 #	Version              : 
 #
 #  Released under GPL V2
 #
 #---------------------------------------------------------------------------*/

var SubSystem_RWR_APG = {
	new : func (_ident){
        #print("RWR_APG: init");
        var obj = { parents: [SubSystem_RWR_APG]};
        input = {
               link16_wingman_4: "link16/wingman-4",
        };

        foreach (var name; keys(input)) {
            emesary.GlobalTransmitter.NotifyAll(notifications.FrameNotificationAddProperty.new(_ident, name, input[name]));
        }

        #
        # recipient that will be registered on the global transmitter and connect this
        # subsystem to allow subsystem notifications to be received
        obj.recipient = emesary.Recipient.new(_ident~".Subsystem");
        obj.recipient.RWR_APG = obj;

        obj.recipient.Receive = func(notification)
        {
            if (notification.NotificationType == "FrameNotification")
            {
                me.RWR_APG.update(notification);
                return emesary.Transmitter.ReceiptStatus_OK;
            }
            return emesary.Transmitter.ReceiptStatus_NotProcessed;
        };
        emesary.GlobalTransmitter.Register(obj.recipient);

		return obj;
	},
    heatDefense: 0,
    update : func(notification) {
            #printf("clist %d", size(notification.completeList));
            if (!getprop("instrumentation/rwr/serviceable") or getprop("f16/avionics/power-ufc-warm") != 1 or getprop("f16/avionics/ew-rwr-switch") != 1) {
                setprop("sound/rwr-lck", 0);
                setprop("ai/submodels/submodel[0]/flare-auto-release-cmd", 0);
                return;
            }
            notification.rwrList16 = [];
            notification.rwrList = [];
            me.fct = 10*2.0;
            if (notification["completeList"] == nil) return;
            me.myCallsign = getprop("sim/multiplay/callsign");
            me.myCallsign = size(me.myCallsign) < 8 ? me.myCallsign : left(me.myCallsign,7);
            me.act_lck = 0;
            me.autoFlare = 0;
            me.closestThreat = 0;
            me.elapsed = getprop("sim/time/elapsed-sec");
            foreach(me.u;notification.completeList) {
                me.cs = me.u.get_Callsign();
                me.rn = me.u.get_range();
                me.lck = me.u.propNode.getNode("sim/multiplay/generic/string[6]");
                if (me.lck != nil and me.lck.getValue() != nil and me.lck.getValue() != "" and size(""~me.lck.getValue())==4 and left(md5(me.myCallsign),4) == me.lck.getValue()) {
                    me.act_lck = 1;
                }
                me.l16 = 0;
                me.lnk16 = datalink.get_data(me.cs);
                if ((me.lnk16 != nil and me.lnk16.on_link() == 1) or me.rn > 150) {
                    me.l16 = 1;
                }
                me.bearing = geo.aircraft_position().course_to(me.u.get_Coord());
                me.trAct = me.u.propNode.getNode("instrumentation/transponder/transmitted-id");
                me.show = 0;
                me.heading = me.u.get_heading();  
                me.inv_bearing =  me.bearing+180;#bearing from target to me
                me.deviation = me.inv_bearing - me.heading;# bearing deviation from target to me
                me.dev = math.abs(geo.normdeg180(me.deviation));# my degrees from opponents nose
                if (me.u.get_behind_terrain()) {
                    me.show = 0;#behind terrain (does this terrain check happen often enough??)
                } elsif (me.u.get_display()) {
                    me.show = 1;#in radar cone
                } elsif(me.u.get_model()=="AI" and me.rn < 55) {
                    me.show = 1;#non MP always has transponder on.
                } elsif (me.trAct != nil and me.trAct.getValue() != nil and me.trAct.getValue() != -9999 and me.rn < 55) {
                  # transponder on
                  me.show = 1;
                } elsif (me.rn < 7.5 * me.fct) {
                  me.rdrAct = me.u.propNode.getNode("sim/multiplay/generic/int[2]");
                  if (((me.rdrAct != nil and me.rdrAct.getValue()!=1) or me.rdrAct == nil) and math.abs(geo.normdeg180(me.deviation)) < 60) {
                      # we detect its radar is pointed at us and active
                      me.show = 1;
                  }
                }
                #TODO: check if this is needed:
                #me.show = me.show and awg_9.TerrainManager.IsVisible(me.u.propNode,notification);# seems awg_9 uses isbehindterrain for non terrain stuff, so we need to repeat check here.
                if (me.show == 1) {
                    if (me.dev < 30 and me.rn < 7) {
                        # he is in position to fire heatseeker at me
                        me.heatDefenseNow = me.elapsed + me.rn*1.5;
                        if (me.heatDefenseNow > me.heatDefense) {
                            me.heatDefense = me.heatDefenseNow;
                        }
                    }
                    me.threat = 0;
                    if (me.u.get_model() != "missile_frigate" and me.u.get_model() != "S-75" and me.u.get_model() != "buk-m2" and me.u.get_model() != "MIM104D" and me.u.get_model() != "s-300" and me.u.get_model() != "fleet" and me.u.get_model() != "ZSU-23-4M") {
                        me.threat += ((180-me.dev)/180)*0.30;# most threat if I am in front of his nose
                        me.spd = (60-me.u.get_Speed())/60;
                        me.threat -= me.spd>0?me.spd:0;# if his speed is lower than 60kt then give him minus threat else positive
                    } elsif (me.u.get_model == "missile_frigate" or me.u.get_model() == "fleet") {
                        me.threat += 0.30;
                    } else {
                        me.threat += 0.30;
                    }
                    me.danger = 50;# within this range he is most dangerous
                    if (me.u.get_model() == "missile_frigate" or me.u.get_model() == "fleet" or me.u.get_model() == "s-300") {
                        me.danger = 80;
                    } elsif (me.u.get_model() == "buk-m2" or me.u.get_model() == "S-75") {
                        me.danger = 35;
                    } elsif (me.u.get_model() == "MIM104D") {
                        me.danger = 45;
                    } elsif (me.u.get_model() == "ZSU-23-4M") {
                        me.danger = 7.5;
                    }
                    me.threat += ((me.danger-me.rn)/me.danger)>0?((me.danger-me.rn)/me.danger)*0.60:0;# if inside danger zone then add threat, the closer the more.
                    me.clo = me.u.get_closure_rate();
                    me.threat += me.clo>0?(me.clo/500)*0.10:0;# more closing speed means more threat.
                    if (me.threat > me.closestThreat) me.closestThreat = me.threat;
                    if (me.threat > 1) me.threat = 1;
                    if (me.threat <= 0) continue;
    #                printf("%s threat:%.2f range:%d dev:%d", me.u.get_Callsign(),me.threat,me.u.get_range(),me.deviation);
                    if (!me.l16) {
                        append(notification.rwrList,[me.u,me.threat]);
                    } else {
                        append(notification.rwrList16,[me.u,me.threat]);
                    }
                } else {
    #                printf("%s ----", me.u.get_Callsign());
                }
            }
            setprop("sound/rwr-lck", me.act_lck);

            me.launchClose = getprop("payload/armament/MLW-launcher") != "";
            me.incoming = getprop("payload/armament/MAW-active") or me.heatDefense > me.elapsed;
            me.spike = getprop("payload/armament/spike");
            me.autoFlare = me.spike?math.max(me.closestThreat*0.35,0.05):0;

            #print("spike: ",me.spike,"  incoming: ",me.incoming, "  launch: ",me.launchClose,"  spikeResult:", me.autoFlare,"  aggresive:",me.launchClose * 0.85 + me.incoming * 0.85,"  total:",me.launchClose * 0.85 + me.incoming * 0.85+me.autoFlare);

            me.autoFlare += me.launchClose * 0.85 + me.incoming * 0.85;

            me.autoFlare *= 0.1 * 2 * !getprop("gear/gear[0]/wow");#0.1 being the update rate for flare dropping code.

            setprop("ai/submodels/submodel[0]/flare-auto-release-cmd", me.autoFlare * (getprop("ai/submodels/submodel[0]/count")>0));
            if (me.autoFlare > 0.80 and rand()>0.99 and getprop("ai/submodels/submodel[0]/count") < 1) {
                setprop("ai/submodels/submodel[0]/flare-release-out-snd", 1);
            }
    },
};

subsystem = SubSystem_RWR_APG.new("SubSystem_RWR_APG");

