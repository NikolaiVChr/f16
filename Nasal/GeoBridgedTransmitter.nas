# Emesary bridged transmitter for armament notifications.
# 
# Richard Harrison 2017
#
# NOTES:
# 1.The incoming bridges that is defined here will apply to all models that 
#   are loaded over MP; it is better to create the bridges here rather than in the model.xml
#   So given that we don't want a bridge on all MP models only those that are on OPRF
#   aircraft that want to receive notifications we will create the incoming bridge here
#   and thus only an OPRF model will receive notifications from another OPRF model.
#
# 2. The Emesary MP bridge requires two sides; the outgoing and incoming. 
#    - The outgoing aircraft will forwards all received notifications via MP;
#      and these will be received by a similarly equipped craft.
#    - The receiving aircraft will receive all notifications from other MP craft via
#      the globalTransmitter - which is bridged via property #18 /sim/multiplay/emesary/bridge[18]
#------------------------------------------------------------------------------------------

# Setup the bridge
# armament notification 24 bytes
# geoEventNotification - 34 bytes + the length of the RemoteCallsign and Name fields.
#NOTE: due to bug in Emesary MP Bridge (fixed in 2019.2 after 24/3/2020) we can only
#      reliably send one message type per bridge - so for the maximum compatibility
#      we will use two bridges.
#      If at some point in the future we target 2019.2 as a min ver we can use a single
#      bridge and setup the notification list to contain all of the armament hit/flying notifications
#i.e. change to [notifications.ArmamentInFlightNotification.new(nil), notifications.ArmamentNotification.new(nil)];
var geoRoutedNotifications = [notifications.ArmamentInFlightNotification.new()];
var geoBridgedTransmitter = emesary.Transmitter.new("geoOutgoingBridge");
var geooutgoingBridge = emesary_mp_bridge.OutgoingMPBridge.new("f16mp.geo",geoRoutedNotifications, 18, "", geoBridgedTransmitter);

# bridge should be tuned to be around 90% of the packet size full.
geooutgoingBridge.TransmitFrequencySeconds = 0.75;
geooutgoingBridge.MPStringMaxLen = 150;
emesary_mp_bridge.IncomingMPBridge.startMPBridge(geoRoutedNotifications, 18, emesary.GlobalTransmitter);


#----- bridge hit (armament) notifications
var hitRoutedNotifications = [notifications.ArmamentNotification.new(),notifications.StaticNotification.new()];
var hitBridgedTransmitter = emesary.Transmitter.new("armamentNotificationBridge");
var hitoutgoingBridge = emesary_mp_bridge.OutgoingMPBridge.new("f16mp.hit",hitRoutedNotifications, 19, "", hitBridgedTransmitter);
hitoutgoingBridge.TransmitFrequencySeconds = 1.5;
hitoutgoingBridge.MPStringMaxLen = 180;
emesary_mp_bridge.IncomingMPBridge.startMPBridge(hitRoutedNotifications, 19, emesary.GlobalTransmitter);

#----- bridge object notifications
var objectRoutedNotifications = [notifications.ObjectInFlightNotification.new()];
var objectBridgedTransmitter = emesary.Transmitter.new("objectNotificationBridge");
var objectoutgoingBridge = emesary_mp_bridge.OutgoingMPBridge.new("f16mp.object",objectRoutedNotifications, 17, "", objectBridgedTransmitter);
objectoutgoingBridge.TransmitFrequencySeconds = 0.75;
objectoutgoingBridge.MPStringMaxLen = 180;
emesary_mp_bridge.IncomingMPBridge.startMPBridge(objectRoutedNotifications, 17, emesary.GlobalTransmitter);

#
# debug all messages - this can be removed when testing isn't required.
var debugRecipient = emesary.Recipient.new("Debug");
debugRecipient.Receive = func(notification)
{
    if (notification.NotificationType != "FrameNotification")  {
        print ("recv(0): type=",notification.NotificationType, " fromIncoming=",notification.FromIncomingBridge);

        if (notification.NotificationType == "ArmamentInFlightNotification") {
            print("recv(1): ",notification.NotificationType, " ", notification.Ident);
            debug.dump(notification);

        } else if (notification.NotificationType == "ArmamentNotification") {
            if (notification.FromIncomingBridge) {
                print("recv(2): ",notification.NotificationType, " ", notification.Ident,
                      " Kind=",notification.Kind,
                      " SecondaryKind=",notification.SecondaryKind,
                      " RelativeAltitude=",notification.RelativeAltitude,
                      " Distance=",notification.Distance,
                      " Bearing=",notification.Bearing,
                      " RemoteCallsign=",notification.RemoteCallsign);
                debug.dump(notification);
            }
        }
    }
    return emesary.Transmitter.ReceiptStatus_NotProcessed; # we're not processing it, just looking
}
# uncomment next line to activate debug recipient.
#emesary.GlobalTransmitter.Register(debugRecipient);

