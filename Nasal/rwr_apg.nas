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
        notification.rwrList16 = [];
        notification.rwrList = [];
        if (notification["completeList"] == nil) return;
        foreach(me.u;notification.completeList) {
            me.cs = me.u.get_Callsign();
            me.rn = me.u.get_range();
            me.l16 = 0;
            if (notification.link16_wingman_1 == me.cs or notification.link16_wingman_2 == me.cs or notification.link16_wingman_3 == me.cs or me.rn > 150) {
                me.l16 = 1;
            }
            me.bearing = geo.aircraft_position().course_to(me.u.get_Coord());
            me.trAct = me.u.propNode.getNode("instrumentation/transponder/transmitted-id");
            me.show = 0;
            me.heading = me.u.get_heading();  
            me.inv_bearing =  me.bearing+180;
            me.deviation = me.inv_bearing - me.heading;
            me.dev = math.abs(geo.normdeg180(me.deviation));
            if (me.u.get_display()) {
                me.show = 1;#in radar cone
            } elsif(me.u.get_model()=="AI" and me.rn < 55) {
                me.show = 1;#non MP always has transponder on.
            } elsif (me.trAct != nil and me.trAct.getValue() != -9999 and me.rn < 55) {
              # transponder on
              me.show = 1;
            } else {
              me.rdrAct = me.u.propNode.getNode("sim/multiplay/generic/int[2]");
              if (((me.rdrAct != nil and me.rdrAct.getValue()!=1) or me.rdrAct == nil) and math.abs(geo.normdeg180(me.deviation)) < 60) {
                  # we detect its radar is pointed at us and active
                  me.show = 1;
              }
            }
            if (me.show == 1) {
                me.threat = 0;
                if (me.u.get_model() != "missile_frigate" and me.u.get_model() != "buk-m2") {
                    me.threat += ((180-me.dev)/180)*0.30;
                    me.spd = (60-me.u.get_Speed())/60;
                    me.threat -= me.spd>0?me.spd:0;
                } elsif (me.u.get_model == "missile_frigate") {
                    me.threat += 0.30;
                } else {
                    me.threat += 0.30;
                }
                me.danger = me.u.get_model() == "missile_frigate"?75:(me.u.get_model() == "buk-m2"?35:50);
                me.threat += ((me.danger-me.rn)/me.danger)>0?((me.danger-me.rn)/me.danger)*0.60:0;
                me.clo = me.u.get_closure_rate();
                me.threat += me.clo>0?(me.clo/500)*0.10:0;
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
    },
};

subsystem = SubSystem_RWR_APG.new("SubSystem_RWR_APG");

