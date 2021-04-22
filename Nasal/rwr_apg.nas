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
               link16_wingman_1: "link16/wingman-1",
               link16_wingman_2: "link16/wingman-2",
               link16_wingman_3: "link16/wingman-3",
               link16_wingman_4: "link16/wingman-4",
               link16_wingman_5: "link16/wingman-5",
               link16_wingman_6: "link16/wingman-6",
               link16_wingman_7: "link16/wingman-7",
               link16_wingman_8: "link16/wingman-8",
               link16_wingman_9: "link16/wingman-9",
               link16_wingman_10: "link16/wingman-10",
               link16_wingman_11: "link16/wingman-11",
               link16_wingman_12: "link16/wingman-12",
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
    update : func(notification) {
            #printf("clist %d", size(notification.completeList));
            if (!getprop("instrumentation/rwr/serviceable") or getprop("f16/avionics/power-ufc-warm") != 1 or getprop("f16/avionics/ew-rwr-switch") != 1) {
                setprop("sound/rwr-lck", 0);
                return;
            }
            notification.rwrList16 = [];
            notification.rwrList = [];
            me.fct = 10*2.0;
            if (notification["completeList"] == nil) return;
            me.myCallsign = getprop("sim/multiplay/callsign");
            me.myCallsign = size(me.myCallsign) < 8 ? me.myCallsign : left(me.myCallsign,7);
            me.act_lck = 0;
            foreach(me.u;notification.completeList) {
                me.cs = me.u.get_Callsign();
                me.rn = me.u.get_range();
                me.lck = me.u.propNode.getNode("sim/multiplay/generic/string[6]");
                if (me.lck != nil and me.lck.getValue() != nil and me.lck.getValue() != "" and size(""~me.lck.getValue())==4 and left(md5(me.myCallsign),4) == me.lck.getValue()) {
                    me.act_lck = 1;
                }
                me.l16 = 0;
                if (notification.link16_wingman_1 == me.cs or notification.link16_wingman_2 == me.cs or notification.link16_wingman_3 == me.cs or notification.link16_wingman_4 == me.cs or notification.link16_wingman_5 == me.cs or notification.link16_wingman_6 == me.cs or notification.link16_wingman_7 == me.cs or notification.link16_wingman_8 == me.cs or notification.link16_wingman_9 == me.cs or notification.link16_wingman_10 == me.cs or notification.link16_wingman_11 == me.cs or notification.link16_wingman_12 == me.cs or me.rn > 150) {
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
                    me.threat = 0;
                    if (me.u.get_model() != "missile_frigate" and me.u.get_model() != "buk-m2" and me.u.get_model() != "MIM104D" and me.u.get_model() != "s-300" and me.u.get_model() != "fleet") {
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
                        me.danger = 75
                    } elsif (me.u.get_model() == "buk-m2" or me.u.get_model() == "MIM104D") {
                        me.danger = 35;
                    } elsif (me.u.get_model() == "MIM104D") {
                        me.danger = 35;
                    } elsif (me.u.get_model() == "ZSU-23-4M") {
                        me.danger = 10;
                    }
                    me.threat += ((me.danger-me.rn)/me.danger)>0?((me.danger-me.rn)/me.danger)*0.60:0;# if inside danger zone then add threat, the closer the more.
                    me.clo = me.u.get_closure_rate();
                    me.threat += me.clo>0?(me.clo/500)*0.10:0;# more closing speed means more threat.
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
    },
};

subsystem = SubSystem_RWR_APG.new("SubSystem_RWR_APG");

