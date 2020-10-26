 #---------------------------------------------------------------------------
 #
 #  Title                : EMESARY multiplayer bridge
 #
 #  File Type            : Implementation File
 #
 #  Description          : Bridges selected emesary notifications over MP
 #                       : To send a message use a Transmitter with an object. That's all there is to it.
 #  
 #  References           : http://chateau-logic.com/content/emesary-nasal-implementation-flightgear
 #
 #  Author               : Richard Harrison (richard@zaretto.com)
 #
 #  Creation Date        : 04 April 2016
 #
 #  Version              : 4.8
 #
 #  Copyright © 2016 Richard Harrison           Released under GPL V2
 #
 #---------------------------------------------------------------------------*/

 # Example of connecting an incoming and outgoing bridge (should reside inside an aircraft nasal file)
 # 
 # var routedNotifications = [notifications.TacticalNotification.new()];
 # var incomingBridge = emesary_mp_bridge.IncomingMPBridge.startMPBridge(routedNotifications);
 # var outgoingBridge = emesary_mp_bridge.OutgoingMPBridge.new("F-15mp",routedNotifications);
 #------------------------------------------------------------------
 #
# NOTES:
#        * Aircraft do not need to have both an incoming and outgoing bridge, but it is usual.
#
#        * Only the notifications specified will be routed via the bridge.
#
#        * Once routed a message will by default not be re-rerouted again by the outgoing bridge.
#
#        * Transmit frequency and message lifetime may need to be tuned.
#
#        * IsDistinct messages must be absolute and self contained as a later message will 
 #        supercede any earlier ones in the outgoing queue (possibly prior to receipt)
#
#        * Use the message type and ident to identify distinct messages
#
#        * The outgoing 'port' is a multiplay/emesary/bridge index, however any available string property
 #        can be used by specifying it in the construction of the incoming or outgoing bridge.
 #        NOTE: This should not often be changed as it different versions of FG or model will  
 #              have to use the same properties to be able to communicate
#
#        * multiplay/emesary/bridge-type is used to identify the bridge that is in use. This is to 
 #        protect against bridges being used for different purposes by different models.
#
#        * The bridge-type property should contain an ID that identifies the purpose
 #        and thereore the message set that the bridge will be using.
#
 #  - ! is used as a seperator between the elements that are used to send the 
 #       notification (typeid, sequence, notification)
 #  -   There is an extra ! at the start of the message that is used to indicate protocol version.
 #  - ; is used to seperate serialzied elemnts of the notification

 # General Notes
 #----------------------------------------------------------------------
 # Outgoing messages are sent in a scheduled manner, usually once per
 # second, and each message has a lifetime (to allow for propogation to
 # all clients over UDP). Clients will ignore messages that they have
 # already received (based on the sequence id).

 # The incoming bridge will usually be created part of the aircraft
 # model file; it is important to understand that each AI/MP model will
 # have an incoming bridge as each element in /ai/models needs its own
 # bridge to keep up with the incoming sequence id. This scheme may not
 # work properly as it relies on the model being loaded which may only
 # happen when visible so it may be necessary to track AI models in a
 # seperate instantiatable incoming bridge manager.
 #
 # The outgoing bridge would usually be created within the aircraft loading Nasal.
 var EmesaryMPBridgeDefaultPropertyIndex=19;

 var OutgoingMPBridge = 
   {
    SeperatorChar : "!",
    MessageEndChar : "~",
    StartMessageIndex : 11,
    DefaultMessageLifetimeSeconds : 10, 
  MPStringMaxLen: 128,

  new: func(_ident, _notifications_to_bridge=nil, _mpidx=19, _root="", _transmitter=nil, _propertybase="emesary/bridge")
    {
        if (_transmitter == nil)
          _transmitter = emesary.GlobalTransmitter;

        logprint(LOG_INFO, "OutgoingMPBridge created for "~_ident," mp=",_mpidx);
        var new_class = emesary.Recipient.new("OutgoingMPBridge "~_ident);


        if (_notifications_to_bridge == nil)
          new_class.NotificationsToBridge = [];
        else
          new_class.NotificationsToBridge = _notifications_to_bridge;

        new_class.NotificationsToBridge_Lookup = {};

        foreach (var n ; new_class.NotificationsToBridge) {
            logprint(LOG_INFO, "  ",_ident,"  outwards bridge[",n,"] notifications of type --> ",n.NotificationType, " Id ",n.TypeId);
            n.MessageIndex = OutgoingMPBridge.StartMessageIndex;
            new_class.NotificationsToBridge_Lookup[n.TypeId] = n;
        }
        new_class.MPout = "";
        new_class.MPidx = _mpidx;
        new_class.MessageLifeTime = 10; # seconds
        new_class.OutgoingList = [];
        new_class.Transmitter = _transmitter;
        new_class.TransmitRequired=0;
        new_class.MpVariable = _root~"sim/multiplay/"~_propertybase~"["~new_class.MPidx~"]";
        new_class.TransmitterActive = 0;
        new_class.TransmitFrequencySeconds = 1;
        new_class.trace = 0;
        new_class.MPStringMaxLen = OutgoingMPBridge.MPStringMaxLen;

        new_class.TransmitTimer = 
          maketimer(6, func
                    {
                        if (new_class.TransmitterActive)
                          new_class.Transmit();
                        else
                          new_class.TransmitEnd();

                        new_class.TransmitTimer.restart(new_class.TransmitFrequencySeconds);
                    });

        new_class.Delete = func
          {
              if (me.Transmitter != nil) {
                  me.Transmitter.DeRegister(me);
                  me.Transmitter = nil;
              }
          };
        new_class.AddMessage = func(m)
        {
            append(me.NotificationsToBridge, m);
                                };

        #-------------------------------------------
        # Receive override:
        new_class.Receive = func(notification)
          {
              if (notification.FromIncomingBridge)
                return emesary.Transmitter.ReceiptStatus_NotProcessed;

              #logprint(LOG_DEBUG, "Receive ",notification.NotificationType," ",notification.Ident);
              for (var idx = 0; idx < size(me.NotificationsToBridge); idx += 1) {
                  if (me.NotificationsToBridge[idx].NotificationType == notification.NotificationType) {
                      me.NotificationsToBridge[idx].MessageIndex += 1;
                      notification.MessageExpiryTime = systime()+me.MessageLifeTime;
                      notification.Expired = 0;
                      notification.BridgeMessageId = me.NotificationsToBridge[idx].MessageIndex;
                      notification.BridgeMessageNotificationTypeId = me.NotificationsToBridge[idx].TypeId;
                      #
                      # The message key is a composite of the type and ident to allow for multiple senders
                      # of the same message type.
                      #logprint(LOG_DEBUG, "Received ",notification.BridgeMessageNotificationTypeKey," expire=",notification.MessageExpiryTime);
                      me.AddToOutgoing(notification);
                      return emesary.Transmitter.ReceiptStatus_Pending;
                  }
              }
              return emesary.Transmitter.ReceiptStatus_NotProcessed;
          };

        new_class.AddToOutgoing = func(notification)
          {
              if (notification.IsDistinct) {
                  for (var idx = 0; idx < size(me.OutgoingList); idx += 1) {
                      if (me.trace)
                        logprint(LOG_DEBUG, "Compare [",idx,"] qId=",me.OutgoingList[idx].GetBridgeMessageNotificationTypeKey() ," noti --> ",notification.GetBridgeMessageNotificationTypeKey());
                      if (me.OutgoingList[idx].GetBridgeMessageNotificationTypeKey() == notification.GetBridgeMessageNotificationTypeKey()) {
                          if (me.trace)
                            logprint(LOG_DEBUG, "  --> Update ",me.OutgoingList[idx].GetBridgeMessageNotificationTypeKey() ," noti --> ",notification.GetBridgeMessageNotificationTypeKey());
                          me.OutgoingList[idx]= notification;
                          me.TransmitterActive = size(me.OutgoingList);
                          return;
                      }
                  }
              } else
                if (me.trace)
                  logprint(LOG_DEBUG, "Not distinct, adding always");
            
            if (me.trace)
              logprint(LOG_DEBUG, " --> Added ",notification.GetBridgeMessageNotificationTypeKey());
            append(me.OutgoingList, notification);
            me.TransmitterActive = size(me.OutgoingList);
        };
        new_class.Transmit = func
        {
            var outgoing = "";
            var cur_time=systime();
            var first_time = 1;
            me.OutgoingListNew = [];
            for (var idx = 0; idx < size(me.OutgoingList); idx += 1) {
                var sect = "";
                var notification = me.OutgoingList[idx];

                if (!notification.Expired and notification.MessageExpiryTime > cur_time) {
                    if (notification["sect"] == nil) {
                        # This is first time attempting to transmit this notification
                        var encval="";
                        
                        var eidx = 0;
                        notification.Expired = 0;

                        foreach(var p ; notification.bridgeProperties()) {
                            var nv = p.getValue();
                            encval = encval ~ nv;
                            eidx += 1;
                        }
                        #               !idx!typ!encv~
                        sect = sprintf("%s%s%s%s%s%s%s",
                                       OutgoingMPBridge.SeperatorChar, emesary.BinaryAsciiTransfer.encodeInt(notification.BridgeMessageId,4), 
                                       OutgoingMPBridge.SeperatorChar, emesary.BinaryAsciiTransfer.encodeInt(notification.BridgeMessageNotificationTypeId,1),
                                       OutgoingMPBridge.SeperatorChar, encval, OutgoingMPBridge.MessageEndChar);
                    } else {
                        # This notification has already been coded, but was previously not sent due to too little space.
                        sect = notification.sect;
                    }
                    if (size(outgoing) + size(sect) < me.MPStringMaxLen) {
                        outgoing = outgoing~sect;
                    } else {
                        if (first_time) {
                            logprint(LOG_ALERT, "Emesary: ERROR [",me.Ident,"] out of space for ",notification.NotificationType, " transmitted count=",idx, " queue size ",size(me.OutgoingList));
                            first_time = 0;
                        }
                        #notification.MessageExpiryTime = systime()+me.MessageLifeTime;
                        #break;
                        notification.sect = sect;
                        append(me.OutgoingListNew, notification);
                    }
                } else {
                    notification.Expired = 1;
                }
            }
            me.OutgoingList = me.OutgoingListNew;
            me.TransmitterActive = size(me.OutgoingList);
            setprop(me.MpVariable,outgoing);
        };
        new_class.TransmitEnd = func
        {
            if (getprop(me.MpVariable) != "") {
                setprop(me.MpVariable,"");
            }
        };
        new_class.Transmitter.Register(new_class);
        new_class.TransmitTimer.restart(new_class.TransmitFrequencySeconds);
        return new_class;
    },

   };


 #
 #
 # one of these for each model instantiated in the model XML - it will
 # route messages to 
 var IncomingMPBridge = 
   {
    trace : 0,
  new: func(_ident, _notifications_to_bridge=nil, _mpidx=19, _transmitter=nil, _propertybase="emesary/bridge")
    {
        if (_transmitter == nil)
          _transmitter = emesary.GlobalTransmitter;

        logprint(LOG_INFO, "IncomingMPBridge created for "~_ident," mp=",_mpidx, " using Transmitter ",_transmitter.Ident, " with property base sim/multiplayer/"~_propertybase);

        var new_class = emesary.Transmitter.new("IncominggMPBridge "~_ident);

        if (_notifications_to_bridge == nil)
          new_class.NotificationsToBridge = [];
        else
          new_class.NotificationsToBridge = _notifications_to_bridge;

        new_class.NotificationsToBridge_Lookup = {};

        foreach (var n ; new_class.NotificationsToBridge) {
            logprint(LOG_INFO, "  Incoming bridge notification type --> ",n.NotificationType);
            var new_n = {parents: [n]};
            new_n.IncomingMessageIndex = OutgoingMPBridge.StartMessageIndex;
            new_class.NotificationsToBridge_Lookup[n.TypeId] = new_n;
        }

        new_class.MPout = "";
        new_class.MPidx = _mpidx;
        new_class.MPpropertyBase = _propertybase;
        new_class.MessageLifeTime = OutgoingMPBridge.DefaultMessageLifetimeSeconds; # seconds
        new_class.OutgoingList = [];
        new_class.Transmitter = _transmitter;
        new_class.MpVariable = "";

        new_class.Connect = func(_root)
        {
            me.MpVariable = _root~"sim/multiplay/"~new_class.MPpropertyBase~"["~new_class.MPidx~"]";
            me.CallsignPath = _root~"callsign";
            me.PropertyRoot = _root;
            me.mp_listener = setlistener(me.MpVariable, func(v)
                        {
#logprint(LOG_DEBUG, "incoming ",getprop(me.CallsignPath)," -->",me.PropertyRoot," v=",v.getValue());
                            me.ProcessIncoming(v.getValue());
                        },0,0);
          };
        new_class.setprop = func(property, value){
            if (IncomingMPBridge.trace == 2)
              logprint(LOG_DEBUG, "setprop ",new_class.PropertyRoot~property," = ",value);
            setprop(new_class.PropertyRoot~property,value);
        };
        new_class.GetCallsign = func
          {
              return getprop(me.CallsignPath);
          };
        new_class.AddMessage = func(m)
        {
            append(me.NotificationsToBridge, m);
                                };

        new_class.Remove = func
        {
            logprint(LOG_INFO, "Emesary IncomingMPBridge Remove() ",me.Ident," Property: ",me.MpVariable);
            me.Transmitter.DeRegister(me);
            if (me["mp_listener"] != nil)
                removelistener(me.mp_listener);
            me.mp_listener = nil;
        };

        #-------------------------------------------
        # Receive override:
        new_class.ProcessIncoming = func(encoded_val)
          {
              if (encoded_val == "")
                return;

            if(right(encoded_val,1) != OutgoingMPBridge.MessageEndChar) 
              printf("Error: emesary.IncomingBridge.ProcessIncoming Missing endChar. From %s. Message=%s",me.GetCallsign(),encoded_val);

              var encoded_notifications = split(OutgoingMPBridge.MessageEndChar, encoded_val);
              for (var idx = 0; idx < size(encoded_notifications); idx += 1) {
                  if (encoded_notifications[idx] == "")
                    continue ;
                  # get the message parts
                  var encoded_notification = split(OutgoingMPBridge.SeperatorChar, encoded_notifications[idx]);
                  if (size(encoded_notification) < 4)
                    logprint(LOG_ALERT, "Error: emesary.IncomingBridge.ProcessIncoming bad msg ",encoded_notifications[idx]);
                  else {
                      var msg_idx = emesary.BinaryAsciiTransfer.decodeInt(encoded_notification[1],4,0).value;
                      var msg_type_id = emesary.BinaryAsciiTransfer.decodeInt(encoded_notification[2],1,0).value;
                      var bridged_notification = new_class.NotificationsToBridge_Lookup[msg_type_id];
                      if (bridged_notification == nil) {
                          logprint(LOG_ALERT, "Error: emesary.IncomingBridge.ProcessIncoming invalid type_id ",msg_type_id);
                      } else {
                          bridged_notification.FromIncomingBridge = 1;
                          bridged_notification.Callsign = me.GetCallsign();
                            if(IncomingMPBridge.trace>1)
                              logprint(LOG_DEBUG, "ProcessIncoming callsign=",bridged_notification.Callsign," ",me.PropertyRoot, " msg_type=",msg_type_id," idx=",msg_idx, " bridge_idx=",bridged_notification.IncomingMessageIndex);
                        if (msg_idx > bridged_notification.IncomingMessageIndex) {
                            if(IncomingMPBridge.trace==1)
                              logprint(LOG_DEBUG, "ProcessIncoming callsign=",bridged_notification.Callsign," ",me.PropertyRoot, " msg_type=",msg_type_id," idx=",msg_idx, " bridge_idx=",bridged_notification.IncomingMessageIndex);
                              var msg_body = encoded_notification[3];
                              if (IncomingMPBridge.trace > 2)
                                logprint(LOG_DEBUG, "received idx=",msg_idx," ",msg_type_id,":",bridged_notification.NotificationType);

                              # populate fields
                              var bridgedProperties = bridged_notification.bridgeProperties();
                              var msglen = size(msg_body);
                              if (IncomingMPBridge.trace > 2)
                                logprint(LOG_DEBUG, "Process ",msg_body," len=",msglen, " BPsize = ",size(bridgedProperties));
                              var pos = 0;
                              for (var bpi = 0; bpi < size(bridgedProperties); bpi += 1) {
                                  if (pos < msglen) {
                                      if (IncomingMPBridge.trace > 2)
                                        logprint(LOG_DEBUG, "dec: pos ",pos);
                                      var bp = bridgedProperties[bpi];
                                      dv = bp.setValue(msg_body, me, pos);
                                      if (IncomingMPBridge.trace > 2)
                                      logprint(LOG_DEBUG, " --> next pos ", dv.pos);

                                      if (dv.pos == pos or dv.pos > msglen)
                                        break;
                                      pos = dv.pos;
                                } else {
                                    logprint(LOG_ALERT, "Error: emesary.IncomingBridge.ProcessIncoming: [",bridged_notification.NotificationType,"] supplementary encoded value at position ",bpi);
                                    break;
                                }
                            }
                            # maybe extend the bridge to allow certain notifications to only be routed to a specific player;
                            # i.e. 
                            # (notification.Callsign == nil or notification.Callsign == getprop("/sim/multiplay/callsign"))

                            if (bridged_notification.Ident == "none")
                              bridged_notification.Ident = "mp-bridge";
                              
                            bridged_notification.IncomingMessageIndex = msg_idx;
                            me.Transmitter.NotifyAll(bridged_notification);
                        }
                    }
                }
            }
        }
        foreach (var n; new_class.NotificationsToBridge) {
            logprint(LOG_INFO, "IncomingBridge: ",n.NotificationType);
        }
        return new_class;
    },
    connectIncomingBridge : func(path, notification_list, mpidx, transmitter, _propertybase){
        var incomingBridge = emesary_mp_bridge.IncomingMPBridge.new(path, notification_list, mpidx, transmitter, _propertybase);
        
        incomingBridge.Connect(path~"/");
        if (me.incomingBridgeList[path] == nil) {
            me.incomingBridgeList[path] = [incomingBridge];
        } else {
            append(me.incomingBridgeList[path],incomingBridge);
        }
        return incomingBridge;
    },

    #
    # Each multiplayer object will have its own incoming bridge. This is necessary to allow message ID
    # tracking (as the bridge knows which messages have been already processed)
    # Whenever a client connects over MP a new bridge is instantiated
    startMPBridge : func(notification_list, mpidx=19, transmitter=nil, _propertybase="emesary/bridge") 
    {
        me.incomingBridgeList = {};

        #
        # Create bridge whenever a client connects
        #
        setlistener("/ai/models/model-added", func(v)
                    {
                        # Model added will be eg: /ai[0]/models[0]/multiplayer[0]
                        var path = v.getValue();

                        # Ensure we only handle multiplayer elements
                        if (find("/multiplayer",path) > 0) {
                            var callsign = getprop(path~"/callsign");
                            logprint(LOG_INFO, "Creating Emesary MPBridge for ",path);
                            if (callsign == "" or callsign == nil)
                              callsign = path;

                me.connectIncomingBridge(path, notification_list, mpidx, transmitter, _propertybase);
                        }
        });

        #
        # when a client disconnects remove the associated bridge.
        #
        setlistener("/ai/models/model-removed", func(v){
            var path = v.getValue();
            var bridges = me.incomingBridgeList[path];
            if (bridges != nil) {
                foreach(bridge;bridges) {
                    bridge.Remove();
#                   logprint(LOG_INFO, "Bridge removed for ",v.getValue());
            }
                me.incomingBridgeList[path] = nil;
        }
        });
    },
   };
