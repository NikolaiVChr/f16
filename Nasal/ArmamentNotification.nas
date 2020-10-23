#
#
# Use to transmit events that happen at a specific place; can be used to make 
# models that are simulated locally (e.g. tankers) appear on other player's MP sessions.
var ArmamentNotification_Id = 19;

var ArmamentNotification = 
{
# new:
# _ident - the identifier for the notification. not bridged.
# _name - name of the notification, bridged.
# _kind - created, moved, deleted, impact (see notifications.nas)
# _secondary_kind - This is the entity on which the activity is being performed. See below for predefined types.
##
    new: func(_ident="none", _kind=0, _secondary_kind=0)
    {
        var new_class = emesary.Notification.new("ArmamentNotification", _ident, ArmamentNotification_Id);

        new_class.Kind = _kind;
        new_class.SecondaryKind = _secondary_kind;
        new_class.RelativeAltitude = 0;
        new_class.IsDistinct = 0;
        new_class.Distance = 0;
        new_class.Bearing = 0;
        new_class.RemoteCallsign = ""; # associated remote callsign.

        new_class.bridgeProperties = func
        {
            return 
            [ 
             {
            getValue:func{return emesary.TransferByte.encode(new_class.Kind);},
            setValue:func(v,root,pos){var dv=emesary.TransferByte.decode(v,pos);new_class.Kind=dv.value;return dv}, 
             },
             {
            getValue:func{return emesary.TransferByte.encode(new_class.SecondaryKind);},
            setValue:func(v,root,pos){var dv=emesary.TransferByte.decode(v,pos);new_class.SecondaryKind=dv.value;return dv}, 
             },
             {
            getValue:func{return emesary.TransferFixedDouble.encode(new_class.RelativeAltitude,2,1/10);},
            setValue:func(v,root,pos){var dv=emesary.TransferFixedDouble.decode(v,2,1/10,pos);new_class.RelativeAltitude=dv.value;return dv}, 
             },
             {
            getValue:func{return emesary.TransferFixedDouble.encode(new_class.Distance,2,1/10);},
            setValue:func(v,root,pos){var dv=emesary.TransferFixedDouble.decode(v,2,1/10,pos);new_class.Distance=dv.value;return dv}, 
             },
             {
            getValue:func{return emesary.TransferFixedDouble.encode(geo.normdeg180(new_class.Bearing),1,1.54);},
            setValue:func(v,root,pos){var dv=emesary.TransferFixedDouble.decode(v,1,1.54,pos);new_class.Bearing=geo.normdeg(dv.value);return dv}, 
             },
             {
            getValue:func{return emesary.TransferString.encode(new_class.RemoteCallsign);},
            setValue:func(v,root,pos){var dv=emesary.TransferString.decode(v,pos);new_class.RemoteCallsign=dv.value;return dv}, 
             },
            ];
          };
        return new_class;
    },
};

var ArmamentInFlightNotification_Id = 21;
var ArmamentInFlightNotification =
{
# new:
# _ident - the identifier for the notification. not bridged.
# _name - name of the notification, bridged.
# _kind - created, moved, deleted (see below). This is the activity that the  notification represents, called kind to avoid confusion with notification type.
# _secondary_kind - This is the entity on which the activity is being performed. See below for predefined types.
#
# UniqueIdentity - an identity that is unique to the sending instance of FG. Can be combined with the callsign to create an MP unique ID.
##
    new: func(_ident="none", _unique=0, _kind=0, _secondary_kind=0)
    {
        var new_class = emesary.Notification.new("ArmamentInFlightNotification", _ident, ArmamentInFlightNotification_Id);

        new_class.Kind = _kind;
        new_class.SecondaryKind = _secondary_kind;
        new_class.Position = geo.aircraft_position();
        new_class.UniqueIndex = 0;

        new_class.Heading = 360;
        new_class.Pitch = 90;
        new_class.u_fps = 0;
        new_class.IsDistinct = 0;
        new_class.Callsign = nil; # populated automatically by the incoming bridge when routed
        new_class.RemoteCallsign = ""; # associated remote callsign.
        new_class.Flags = 0; # 8 bits for whatever.
        new_class.UniqueIdentity = _unique;

        new_class.GetBridgeMessageNotificationTypeKey = func {
            return new_class.NotificationType~"."~new_class.Ident~"."~new_class.UniqueIndex;
        };
        new_class.bridgeProperties = func
        {
            return
            [
             {
            getValue:func{return emesary.TransferCoord.encode(new_class.Position);},
            setValue:func(v,root,pos){var dv=emesary.TransferCoord.decode(v, pos);new_class.Position=dv.value;return dv},
             },
             {
            getValue:func{return emesary.TransferByte.encode(new_class.Kind);},
            setValue:func(v,root,pos){var dv=emesary.TransferByte.decode(v,pos);new_class.Kind=dv.value;return dv},
             },
             {
            getValue:func{return emesary.TransferByte.encode(new_class.SecondaryKind);},
            setValue:func(v,root,pos){var dv=emesary.TransferByte.decode(v,pos);new_class.SecondaryKind=dv.value;return dv},
             },
             {
              #0..6696 fps (3967kts), mach 6.1 (SL) - factor 0.03703
            getValue:func{return emesary.TransferFixedDouble.encode(new_class.u_fps-3348,1,1/0.03703);},
            setValue:func(v,root,pos){var dv=emesary.TransferFixedDouble.decode(v,1,1/0.03703,pos);new_class.u_fps=dv.value+3348;return dv},
             },
             {
            getValue:func{return emesary.TransferFixedDouble.encode(geo.normdeg180(new_class.Heading),1,1.54);},#1.0/0.65
            setValue:func(v,root,pos){var dv=emesary.TransferFixedDouble.decode(v,1,1.54,pos);new_class.Heading=geo.normdeg(dv.value);return dv},
             },
             {
            getValue:func{return emesary.TransferFixedDouble.encode(new_class.Pitch, 1, 1/1.38);},
            setValue:func(v,root,pos){var dv=emesary.TransferFixedDouble.decode(v,1, 1/1.38, pos);new_class.Pitch=dv.value;return dv},
             },
             {
            getValue:func{return emesary.TransferString.encode(new_class.RemoteCallsign);},
            setValue:func(v,root,pos){var dv=emesary.TransferString.decode(v,pos);new_class.RemoteCallsign=dv.value;return dv},
             },
             {
            getValue:func{return emesary.TransferByte.encode(new_class.Flags);},
            setValue:func(v,root,pos){var dv=emesary.TransferByte.decode(v,pos);new_class.Flags=dv.value;return dv},
             },
             {
            getValue:func{return emesary.TransferByte.encode(new_class.UniqueIdentity);},
            setValue:func(v,root,pos){var dv=emesary.TransferByte.decode(v,pos);new_class.UniqueIdentity=dv.value;return dv},
             },

            ];
          };
        return new_class;
    },
};



var StaticNotification_Id = 25;
var StaticNotification =
{
# new:
# _ident - the identifier for the notification. not bridged.
# _kind - created, moved, deleted (see below). This is the activity that the  notification represents, called kind to avoid confusion with notification type.
# _secondary_kind - This is the entity on which the activity is being performed. See below for predefined types.
#
# UniqueIdentity - an identity that is unique to the sending instance of FG. Can be combined with the callsign to create an MP unique ID.
##
    new: func(_ident="stat", _unique=0, _kind=0, _secondary_kind=0)
    {
        var new_class = emesary.Notification.new("StaticNotification", _ident, StaticNotification_Id);
                                                       # _ident -> "stat"
        new_class.UniqueIdentity = _unique;            # random from 0 to 15000000 that identifies each static object
        new_class.Kind = _kind;                        # 1=create, 2=move, 3=delete, 4=request_all
        new_class.SecondaryKind = _secondary_kind;     # 0 = small crater, 1 = big crater, 2 = smoke
        new_class.IsDistinct = 0;                      # keep it 0
        new_class.Callsign = nil;                      # populated automatically by the incoming bridge when routed
        
        new_class.Position = geo.aircraft_position();  # position
        new_class.Heading = 360;                       # heading
        new_class.Flags1 = 0;                          # 7 bits for whatever.
        new_class.Flags2 = 0;                          # 7 bits for whatever.        

        new_class.GetBridgeMessageNotificationTypeKey = func {
            return new_class.NotificationType~"."~new_class.Ident~"."~new_class.UniqueIdentity;
        };
        new_class.bridgeProperties = func
        {
            return
            [
             {
            getValue:func{return emesary.TransferCoord.encode(new_class.Position);},
            setValue:func(v,root,pos){var dv=emesary.TransferCoord.decode(v, pos);new_class.Position=dv.value;return dv},
             },
             {
            getValue:func{return emesary.TransferByte.encode(new_class.Kind);},
            setValue:func(v,root,pos){var dv=emesary.TransferByte.decode(v,pos);new_class.Kind=dv.value;return dv},
             },
             {
            getValue:func{return emesary.TransferByte.encode(new_class.SecondaryKind);},
            setValue:func(v,root,pos){var dv=emesary.TransferByte.decode(v,pos);new_class.SecondaryKind=dv.value;return dv},
             },
             {
            getValue:func{return emesary.TransferFixedDouble.encode(geo.normdeg180(new_class.Heading),1,1.54);},#1.0/0.65
            setValue:func(v,root,pos){var dv=emesary.TransferFixedDouble.decode(v,1,1.54,pos);new_class.Heading=geo.normdeg(dv.value);return dv},
             },
             {
            getValue:func{return emesary.TransferByte.encode(new_class.Flags1);},
            setValue:func(v,root,pos){var dv=emesary.TransferByte.decode(v,pos);new_class.Flags1=dv.value;return dv},
             },
             {
            getValue:func{return emesary.TransferByte.encode(new_class.Flags2);},
            setValue:func(v,root,pos){var dv=emesary.TransferByte.decode(v,pos);new_class.Flags2=dv.value;return dv},
             },
             {
            getValue:func{return emesary.TransferInt.encode(new_class.UniqueIdentity,3);},
            setValue:func(v,root,pos){var dv=emesary.TransferInt.decode(v,3,pos);new_class.UniqueIdentity=dv.value;return dv},
             },
            ];
          };
        return new_class;
    },
};

var ObjectInFlightNotification_Id = 22;
var ObjectInFlightNotification =
{
# new:
# _ident - the identifier for the notification. not bridged.
# _name - name of the notification, bridged.
# _kind - created, moved, deleted (see below). This is the activity that the  notification represents, called kind to avoid confusion with notification type.
# _secondary_kind - This is the entity on which the activity is being performed. See below for predefined types.
#
# UniqueIdentity - an identity that is unique to the sending instance of FG. Can be combined with the callsign to create an MP unique ID.
##
    new: func(_ident="none", _unique=0, _kind=0, _secondary_kind=0)
    {
        var new_class = emesary.Notification.new("ObjectInFlightNotification", _ident, ObjectInFlightNotification_Id);

        new_class.Kind = _kind;
        new_class.SecondaryKind = _secondary_kind;
        new_class.Position = geo.aircraft_position();
        new_class.UniqueIndex = 0;

        new_class.Heading = 360;
        new_class.Pitch = 90;
        new_class.u_fps = 0;
        new_class.IsDistinct = 1;
        new_class.Callsign = nil; # populated automatically by the incoming bridge when routed
        new_class.RemoteCallsign = ""; # associated remote callsign.
        new_class.Flags = 0; # 8 bits for whatever.
        new_class.UniqueIdentity = _unique;

        new_class.GetBridgeMessageNotificationTypeKey = func {
            return new_class.NotificationType~"."~new_class.Ident~"."~new_class.UniqueIndex;
        };
        new_class.bridgeProperties = func
        {
            return
            [
             {
            getValue:func{return emesary.TransferCoord.encode(new_class.Position);},
            setValue:func(v,root,pos){var dv=emesary.TransferCoord.decode(v, pos);new_class.Position=dv.value;return dv},
             },
             {
            getValue:func{return emesary.TransferByte.encode(new_class.Kind);},
            setValue:func(v,root,pos){var dv=emesary.TransferByte.decode(v,pos);new_class.Kind=dv.value;return dv},
             },
             {
            getValue:func{return emesary.TransferByte.encode(new_class.SecondaryKind);},
            setValue:func(v,root,pos){var dv=emesary.TransferByte.decode(v,pos);new_class.SecondaryKind=dv.value;return dv},
             },
             {
              #0..6696 fps (3967kts), mach 6.1 (SL) - factor 0.03703
            getValue:func{return emesary.TransferFixedDouble.encode(new_class.u_fps-3348,1,1/0.03703);},
            setValue:func(v,root,pos){var dv=emesary.TransferFixedDouble.decode(v,1,1/0.03703,pos);new_class.u_fps=dv.value+3348;return dv},
             },
             {
            getValue:func{return emesary.TransferFixedDouble.encode(geo.normdeg180(new_class.Heading),1,1.54);},#1.0/0.65
            setValue:func(v,root,pos){var dv=emesary.TransferFixedDouble.decode(v,1,1.54,pos);new_class.Heading=geo.normdeg(dv.value);return dv},
             },
             {
            getValue:func{return emesary.TransferFixedDouble.encode(new_class.Pitch, 1, 1/1.38);},
            setValue:func(v,root,pos){var dv=emesary.TransferFixedDouble.decode(v,1, 1/1.38, pos);new_class.Pitch=dv.value;return dv},
             },
             {
            getValue:func{return emesary.TransferString.encode(new_class.RemoteCallsign);},
            setValue:func(v,root,pos){var dv=emesary.TransferString.decode(v,pos);new_class.RemoteCallsign=dv.value;return dv},
             },
             {
            getValue:func{return emesary.TransferByte.encode(new_class.Flags);},
            setValue:func(v,root,pos){var dv=emesary.TransferByte.decode(v,pos);new_class.Flags=dv.value;return dv},
             },
             {
            getValue:func{return emesary.TransferByte.encode(new_class.UniqueIdentity);},
            setValue:func(v,root,pos){var dv=emesary.TransferByte.decode(v,pos);new_class.UniqueIdentity=dv.value;return dv},
             },

            ];
          };
        return new_class;
    },
};