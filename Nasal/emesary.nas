#---------------------------------------------------------------------------
 #
 #	Title                : EMESARY inter-object communication
 #
 #	File Type            : Implementation File
 #
 #	Description          : Provides generic inter-object communication. For an object to receive a message it
 #	                     : must first register with an instance of a Transmitter, and provide a Receive method
 #
 #	                     : To send a message use a Transmitter with an object. That's all there is to it.
 #  
 #  References           : http://chateau-logic.com/content/emesary-nasal-implementation-flightgear
 #                       : http://www.chateau-logic.com/content/class-based-inter-object-communication
 #                       : http://chateau-logic.com/content/emesary-efficient-inter-object-communication-using-interfaces-and-inheritance
 #                       : http://chateau-logic.com/content/c-wpf-application-plumbing-using-emesary
 #
 #	Author               : Richard Harrison (richard@zaretto.com)
 #
 #	Creation Date        : 29 January 2016
 #
 #	Version              : 4.8
 #
 #  Copyright © 2016 Richard Harrison           Released under GPL V2
 #
 #---------------------------------------------------------------------------
 # Classes in this file:
 # Transmitter
 # Notification
 # Recipient
 #---------------------------------------------------------------------------*/

var __emesaryUniqueId = 14; # 0-15 are reserved, this way the global transmitter will be 15.

# add registry so we can find a transmitter by name in genericEmesaryGlobalTransmitterTransmit 
var _transmitters = std.Hash.new({}, "transmitters");

var _registerTransmitter = func (key, t) {
    _transmitters.set(key, t);
}
var getTransmitter = func (key) {
    return _transmitters.get(key);
}

# Transmitters send notifications to all recipients that are registered.
var Transmitter =
{
    ReceiptStatus_OK : 0,          # Processing completed successfully
    ReceiptStatus_Fail : 1,        # Processing resulted in at least one failure
    ReceiptStatus_Abort : 2,       # Fatal error, stop processing any further recipients of this message. Implicitly failed.
    ReceiptStatus_Finished : 3,    # Definitive completion - do not send message to any further recipients
    ReceiptStatus_NotProcessed : 4,# Return value when method doesn't process a message.
    ReceiptStatus_Pending : 5,     # Message sent with indeterminate return status as processing underway
    ReceiptStatus_PendingFinished : 6,# Message definitively handled, status indeterminate. The message will not be sent any further

    # create a new transmitter. shouldn't need many of these
    # _ident:   string; name of the transmitter, used in debug messages
    new: func(_ident)
    {
        if (!isscalar(_ident)) {
            logprint(LOG_ALERT, "Transmitter.new: argument must be a scalar!")
        }
        __emesaryUniqueId += 1;
        var new_class = { 
            parents : [Transmitter],
            Recipients : [],
            Ident : _ident,
            Timestamp : nil,
            MaxMilliseconds : 1,
            UniqueId: __emesaryUniqueId,
        };
        _registerTransmitter(_ident, new_class);
        return new_class;
    },
    
    OverrunDetection: func(max_ms=0){
        if (isnum(max_ms) and max_ms) {
            if (me.Timestamp == nil)
                me.Timestamp = maketimestamp();
            me.MaxMilliseconds = max_ms;
            logprint(LOG_INFO, "Set overrun detection ",me.Ident, " to ", me.MaxMilliseconds);
            return 1;
        } else {
            # me.Timestamp = nil;
            me.MaxMilliseconds = 0;
            logprint(LOG_INFO, "Disable  overrun detection ",me.Ident);
            return 0;
        }
    },

    # Add a recipient to receive notifications from this transmitter
    Register: func (recipient)
    {
        # not inheriting from Recipient is maybe strange but will not crash
        if (!isa(recipient, Recipient))
        {
            logprint(LOG_INFO, "Transmitter.Register: argument is not a Recipient object");
        }
        # Warn if recipient doesn't have a Receive function - this is not an error because
        #a receive function could be added after the recipient has been registered - so it is
        # deprecated to do this.
        if (!isfunc(recipient["Receive"]))
        {
            logprint(DEV_ALERT, "Transmitter.Register: Error, argument has no Receive method!");
        }
        foreach (var r; me.Recipients)
        {
            if (r == recipient) {
                logprint(DEV_ALERT, "Transmitter.Register: Recipient already registered!");
                return 1;
            }
        }        
        append(me.Recipients, recipient);
        return 1;
    },
    
    DeleteAllRecipients: func
    {
        me.Recipients = [];
    },
    
    # Stops a recipient from receiving notifications from this transmitter.
    DeRegister: func(todelete_recipient)
    {
        var out_idx = 0;
        var element_deleted = 0;

        for (var idx = 0; idx < size(me.Recipients); idx += 1)
        {
            if (me.Recipients[idx] != todelete_recipient)
            {
                me.Recipients[out_idx] = me.Recipients[idx];
                out_idx = out_idx + 1;
            }
            else
                element_deleted = 1;
        }

        if (element_deleted)
            pop(me.Recipients);
    },

    RecipientCount: func
    {
        return size(me.Recipients);
    },

    PrintRecipients: func
    {
        print("Emesary: Recipient list for ",me.Ident,"(",me.UniqueId,")");
        for (var idx = 0; idx < size(me.Recipients); idx += 1)
            print("Emesary: Recipient[",idx,"] ",me.Recipients[idx].Ident," (",me.Recipients[idx].UniqueId,")");
    },

    # Notify all registered recipients. Stop when receipt status of abort or finished are received.
    # The receipt status from this method will be 
    #  - OK > message handled
    #  - Fail > message not handled. A status of Abort from a recipient will result in our status
    #           being fail as Abort means that the message was not and cannot be handled, and
    #           allows for usages such as access controls.
    # message:  hash; Notification passed to the Receive() method of registered recipients
    NotifyAll: func(message)
    {
        if (!isa(message, Notification))
        {
            logprint(DEV_ALERT, "Transmitter.NotifyAll: argument must be a Notification!");
            return Transmitter.ReceiptStatus_NotProcessed;
        }
        me._return_status = Transmitter.ReceiptStatus_NotProcessed;
        me.TimeTaken = 0;
        foreach (var recipient; me.Recipients)
        {
            if (recipient.RecipientActive)
            {
                me._rstat = nil;
                if (me.MaxMilliseconds > 0 and me.Timestamp != nil)
                  me.Timestamp.stamp();

                message.Timestamp = me.Timestamp;
                call(func {me._rstat = recipient.Receive(message);},nil,nil,nil,var err = []);
                
                if (size(err)){
                    foreach(var line; err) {
                        print(line);
                    }
                    logprint(LOG_ALERT, "Recipient ",recipient.Ident, 
                        " has been removed from transmitter (", me.Ident,
                        ") because of the above error");
                    me.DeRegister(recipient);
                    #need to break the foreach due to having modified what its iterating over.
                    return Transmitter.ReceiptStatus_Abort; 
                }
                if (me.Timestamp != nil) {
                    recipient.TimeTaken = me.Timestamp.elapsedUSec()/1000.0;
                    me.TimeTaken += recipient.TimeTaken;
                }

                if(me._rstat == Transmitter.ReceiptStatus_Fail)
                {
                    me._return_status = Transmitter.ReceiptStatus_Fail;
                }
                elsif(me._rstat == Transmitter.ReceiptStatus_Pending)
                {
                    me._return_status = Transmitter.ReceiptStatus_Pending;
                }
                elsif(me._rstat == Transmitter.ReceiptStatus_PendingFinished)
                {
                    return me._rstat;
                }
#               elsif(rstat == Transmitter.ReceiptStatus_NotProcessed)
#               {
#                   ;
#               }
                elsif(me._rstat == Transmitter.ReceiptStatus_OK)
                {
                    if (me._return_status == Transmitter.ReceiptStatus_NotProcessed)
                        me._return_status = me._rstat;
                }
                elsif(me._rstat == Transmitter.ReceiptStatus_Abort)
                {
                    # this is a final results, e.g. no more recipients will be
                    # notified but the result is returned as NotifyAll result.
                    return Transmitter.ReceiptStatus_Abort;
                }
                elsif(me._rstat == Transmitter.ReceiptStatus_Finished)
                {
                    # this is a final results, e.g. no more recipients will be
                    # notified but the result is returned as NotifyAll result.
                    return Transmitter.ReceiptStatus_OK;
                }
            }
        }
        if (me.MaxMilliseconds and me.TimeTaken > me.MaxMilliseconds) {
            logprint(LOG_WARN, sprintf("Overrun: %s ['%s'] %1.2fms max (%d)",
                me.Ident, message.NotificationType, me.TimeTaken, me.MaxMilliseconds));
            foreach (var recipient; me.Recipients) {
                if (recipient.TimeTaken) {
                  logprint(LOG_WARN, sprintf(" -- Recipient %25s %7.2f ms",
                    recipient.Ident, recipient.TimeTaken));
                }
            }
        }
        return me._return_status;
    },

    # Returns true if a return value from NotifyAll is to be considered a failure.
    IsFailed: func(receiptStatus)
    {
        # Failed is either Fail or Abort.
        # NotProcessed isn't a failure because it hasn't been processed.
        if (receiptStatus == Transmitter.ReceiptStatus_Fail or receiptStatus == Transmitter.ReceiptStatus_Abort)
            return 1;
        return 0;
    }
};

var QueuedTransmitter =
{
 new: func(_ident){
     var new_class = { parents:[QueuedTransmitter], base:emesary.Transmitter};
     new_class = emesary.Transmitter.new(_ident);
     new_class.baseNotifyAll = new_class.NotifyAll;
     new_class.Q = [];

     new_class.NotifyAll = func(message){
         append(me.Q, message);
         return emesary.Transmitter.ReceiptStatus_Pending;
     };

     new_class.Process = func {
         foreach (var m ; me.Q)
               me.baseNotifyAll(m);
                  me.Q = [];
                  return emesary.Transmitter.ReceiptStatus_PendingFinished;
              };
         new_class.size = func {
             return size(me.Q);
         }
           return new_class;
     }
};


#---------------------------------------------------------------------------
# Notification - base class 
# By convention a Notification has a type and a value. Derived classes can add 
# extra properties or methods.
# 
# NotificationType: Notification Type
# Ident:      Can be an ident, or for simple messages a value that needs transmitting.
# IsDistinct: non zero if this message supercedes previous messages of this type.
#             Distinct messages are usually sent often and self contained
#             (i.e. no relative state changes such as toggle value)
#             Messages that indicate an event (such as after a pilot action)
#             will usually be non-distinct. So an example would be gear/up down
#             or ATC acknowledgements that all need to be transmitted
# The IsDistinct is important for any messages that are bridged over MP as
# only the most recently sent distinct message will be transmitted over MP.
# Example: 
# position update, where only current position is relevant -> IsDistinct=1; 
# 0 = queue all messages for MP bridging 
# 1 = queue only latest message (replace any old message of same type+ident)
#        
var TypeIdUnspecified = 1;
var NotificationAutoTypeId = 1;
var Notification =
{
    new: func(_type, _ident, _typeid=0)
    {
        if (!isscalar(_type)) {
            logprint(DEV_ALERT, "Notification.new: _type must be a scalar!");
            return nil;
        }
        if (!isscalar(_ident) and _ident != nil) {
            logprint(DEV_ALERT, "Notification.new: _ident is not scalar but ", typeof(_ident));
            return nil;
        }
        
# typeID of 0 means that the notification does not have an assigned type ID
#           <0 means an automatic ID is required
#           >= 16 is a reserved ID
# normally the typeID should be unique across all of FlightGear.
# use of automatic ID's is really only for notifications that will never be bridged,
# or more accurate when bridged the type isn't going to be known fully.

        if (_typeid < 0) {
            if (_ident != nil){
                logprint(DEV_ALERT, "_typeid can only be omitted when registering class");
                return nil;
            }

            # IDs >= 16 are reserved; see http://wiki.flightgear.org/Emesary_Notifications
            if (NotificationAutoTypeId >= 16) {
                logprint(LOG_ALERT, "Notification: AutoTypeID limit exceeded: "~NotificationAutoTypeId);
                return nil;
            }
            NotificationAutoTypeId += 1;
            _typeid = NotificationAutoTypeId;
        }

        var new_class = { 
            parents: [Notification],
            NotificationType: _type,
            Ident: _ident,
            IsDistinct: 1,          #1: MP bridge only latest notification 
            FromIncomingBridge: 0,
            Callsign: nil,
            TypeId: _typeid,        # used in MP bridged
        };
        return new_class;
    },
    
    setType: func(_type) {
        if (!isscalar(_type)) {
            logprint(DEV_ALERT, "Notification.new: _type must be a scalar!");
            return nil;
        }
        me.NotificationType = _type;
        return me;
    },
    
    setIdent: func(_ident) {
        if (!isscalar(_ident)) {
            logprint(DEV_ALERT, "Notification.new: _ident is not scalar but ", typeof(_ident));
            return nil;
        }
        me.Ident = _ident;
        return me;
    },
    
    GetBridgeMessageNotificationTypeKey: func {
        return me.NotificationType~"."~me.Ident;
    },
};

#---------------------------------------------------------------------------
# Recipient - base class for receiving notifications.
#
# You have to implement the Receive method
# The Receive method must return a sensible ReceiptStatus_* code
var Recipient =
{
    new: func(_ident)
    {
        if (_ident == nil or _ident == "")
        {
            _ident = id(new_class);
            logprint(LOG_WARN, "Emesary Error: Ident required when creating a recipient, defaulting to ", _ident);
        }
        __emesaryUniqueId += 1;
        var new_class = {
            parents: [Recipient],
            Ident: _ident,
            RecipientActive: 1,
            UniqueId: __emesaryUniqueId,
        };
        return new_class;
    },
    
    Receive: func(notification)
    {
        logprint(DEV_ALERT, "Emesary Error: Receive function not implemented in recipient ", me.Ident);
        return Transmitter.ReceiptStatus_NotProcessed;
    },
    
    setReceive: func(f)
    {
        if (isfunc(f)) { me.Receive = f; }
        else { logprint(DEV_ALERT, "Recipient.addReceive: argument must be a function!"); }
        return me;
    },
};

#
# Instantiate a Global Transmitter, this is a convenience and a known starting point. 
# Generally most classes will use this transmitters, however other transmitters 
# can be created and merely use the global transmitter to discover each other.
var GlobalTransmitter =  Transmitter.new("GlobalTransmitter");

#
# Base method of transferring all numeric based values.
# Using the same techinque as base64 - except this is base248 because we can use a much wider range of characters.
#
var BinaryAsciiTransfer = 
{
    #excluded chars 32 (<space>), 33 (!), 35 (#), 36($), 126 (~), 127 (<del>)
    alphabet : 
         chr(1)~chr(2)~chr(3)~chr(4)~chr(5)~chr(6)~chr(7)~chr(8)
        ~chr(9)~chr(10)~chr(11)~chr(12)~chr(13)~chr(14)~chr(15)~chr(16)~chr(17)~chr(18)~chr(19)
        ~chr(20)~chr(21)~chr(22)~chr(23)~chr(24)~chr(25)~chr(26)~chr(27)~chr(28)~chr(29)
        ~chr(30)~chr(31)~chr(34)
        ~"%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}"
        ~chr(128)~chr(129)
        ~chr(130)~chr(131)~chr(132)~chr(133)~chr(134)~chr(135)~chr(136)~chr(137)~chr(138)~chr(139)
        ~chr(140)~chr(141)~chr(142)~chr(143)~chr(144)~chr(145)~chr(146)~chr(147)~chr(148)~chr(149)
        ~chr(150)~chr(151)~chr(152)~chr(153)~chr(154)~chr(155)~chr(156)~chr(157)~chr(158)~chr(159)
        ~chr(160)~chr(161)~chr(162)~chr(163)~chr(164)~chr(165)~chr(166)~chr(167)~chr(168)~chr(169)
        ~chr(170)~chr(171)~chr(172)~chr(173)~chr(174)~chr(175)~chr(176)~chr(177)~chr(178)~chr(179)
        ~chr(180)~chr(181)~chr(182)~chr(183)~chr(184)~chr(185)~chr(186)~chr(187)~chr(188)~chr(189)
        ~chr(190)~chr(191)~chr(192)~chr(193)~chr(194)~chr(195)~chr(196)~chr(197)~chr(198)~chr(199)
        ~chr(200)~chr(201)~chr(202)~chr(203)~chr(204)~chr(205)~chr(206)~chr(207)~chr(208)~chr(209)
        ~chr(210)~chr(211)~chr(212)~chr(213)~chr(214)~chr(215)~chr(216)~chr(217)~chr(218)~chr(219)
        ~chr(220)~chr(221)~chr(222)~chr(223)~chr(224)~chr(225)~chr(226)~chr(227)~chr(228)~chr(229)
        ~chr(230)~chr(231)~chr(232)~chr(233)~chr(234)~chr(235)~chr(236)~chr(237)~chr(238)~chr(239)
        ~chr(240)~chr(241)~chr(242)~chr(243)~chr(244)~chr(245)~chr(246)~chr(247)~chr(248)~chr(249)
        ~chr(250)~chr(251)~chr(252)~chr(253)~chr(254)~chr(255),
    # base248: powers of 2 (i.e. po2(x) = f(248 ^ x); 
    # 0 based list so the first item is really[1]; i.e. 124 which is 248/2 as po2 is the magnitude excluding sign
    po2: [1, 124, 30752, 7626496, 1891371008, 469060009984, 116326882476032, 28849066854055936], 

    _base: 248,
    spaces: "                                  ",
    empty_encoding: chr(1)~chr(1)~chr(1)~chr(1)~chr(1)~chr(1)~chr(1)~chr(1)~chr(1)~chr(1)~chr(1),
    encodeNumeric : func(_num,length,factor)
    {
		var num = int(_num / factor);

		var irange = int(BinaryAsciiTransfer.po2[length]);

		if (num < -irange) num = -irange;
		else if (num > irange) num = irange;

		num = int(num + irange);

        if (num == 0)
            return substr(BinaryAsciiTransfer.empty_encoding,0,length);
        var arr="";

        while (num > 0 and length > 0) {
            var num0 = num;
            num = int(num / BinaryAsciiTransfer._base);
            rem = num0-(num*BinaryAsciiTransfer._base);
            arr =substr(BinaryAsciiTransfer.alphabet, rem,1) ~ arr;
            length -= 1;
        }
        if (length>0)
            arr = substr(BinaryAsciiTransfer.spaces,0,length)~arr;
        return arr;
    },
    retval : {value:0, pos:0},
    decodeNumeric : func(str, length, factor, pos)
    {
		var irange = int(BinaryAsciiTransfer.po2[length]);
        var power = length-1;
        BinaryAsciiTransfer.retval.value = 0;
        BinaryAsciiTransfer.retval.pos = pos;

        while (length > 0 and power > 0) {
            var c = substr(str,BinaryAsciiTransfer.retval.pos,1);
            if (c != " ") break;
            power = power -1;
            length = length-1;
            BinaryAsciiTransfer.retval.pos = BinaryAsciiTransfer.retval.pos + 1;
        }
        while (length >= 0 and power >= 0) {
            var c = substr(str,BinaryAsciiTransfer.retval.pos,1);
            # spaces are used as padding so ignore them.
            if (c != " ") {
                var cc = find(c,BinaryAsciiTransfer.alphabet);
                if (cc < 0)
                  {
                      print("Emesary: BinaryAsciiTransfer.decodeNumeric: Bad encoding ");
                      return BinaryAsciiTransfer.retval;
                  }
               BinaryAsciiTransfer.retval.value += int(cc * math.exp(math.ln(BinaryAsciiTransfer._base) * power));
                power = power - 1;
            }
            length = length-1;
            BinaryAsciiTransfer.retval.pos = BinaryAsciiTransfer.retval.pos + 1;
        }
		BinaryAsciiTransfer.retval.value -= irange;
		BinaryAsciiTransfer.retval.value = BinaryAsciiTransfer.retval.value * factor;
        return BinaryAsciiTransfer.retval;
    },
    encodeInt : func(num,length){
        return me.encodeNumeric(num, length, 1.0);
    },
    decodeInt : func(str, length, pos){
        return me.decodeNumeric(str, length, 1.0, pos);
    }
};

var TransferString = 
{
    MaxLength:16,
#
# just to pack a valid range and keep the lower and very upper control codes for seperators
# that way we don't need to do anything special to encode the string.
    getalphanumericchar : func(v)
    {
        if (find(v,BinaryAsciiTransfer.alphabet) > 0)#"-./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_abcdefghijklmnopqrstuvwxyz") > 0)
          return v;
        return nil;
    },
    encode : func(v)
    {
        if (v==nil)
          return "0";
        var l = size(v);
        if (l > TransferString.MaxLength)
            l = TransferString.MaxLength;
        var rv = "";
        var actual_len = 0;
        for(var ii = 0; ii < l; ii = ii + 1)
        {
            ev = TransferString.getalphanumericchar(substr(v,ii,1));
            if (ev != nil) {
                rv = rv ~ ev;
                actual_len = actual_len + 1;
            }
        }
    
        rv = BinaryAsciiTransfer.encodeNumeric(l,1,1.0) ~ rv;
        return rv;
    },
    decode : func(v,pos)
    {
        var dv = BinaryAsciiTransfer.decodeNumeric(v,1,1.0,pos);
        var length = dv.value;
        if (length == 0){
            dv.value = "";
          return dv;
        }
        var rv = substr(v,dv.pos,length);
        dv.pos = dv.pos + length;
        dv.value = rv;
        return dv;
    }
};

#
# encode an int into a specified number of characters.
var TransferInt = 
{
    encode : func(v, length)
    {
        return BinaryAsciiTransfer.encodeNumeric(v,length, 1.0);
    },
    decode : func(v, length, pos)
    {
        return BinaryAsciiTransfer.decodeNumeric(v,length, 1.0, pos);
    }
};

var TransferFixedDouble = 
{
    encode : func(v, length, factor)
    {
        return BinaryAsciiTransfer.encodeNumeric(v, length, factor);
    },
    decode : func(v, length, factor, pos)
    {
        return BinaryAsciiTransfer.decodeNumeric(v, length, factor,  pos);
    }
};

var TransferNorm = 
{
    powers: [1,10.0, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0, 10000000.0, 100000000.0, 1000000000.0, 10000000000.0, 100000000000.0],

    encode : func(v, length)
    {
        return BinaryAsciiTransfer.encodeNumeric(int(v * BinaryAsciiTransfer.po2[length]),length, 1.0);
    },
    decode : func(v, length, pos)
    {
        dv = BinaryAsciiTransfer.decodeNumeric(v, length, 1.0, pos);
        dv.value = (dv.value/BinaryAsciiTransfer.po2[length]);
        return dv;
    }
};

var TransferByte = 
{
    encode : func(v)
    {
        return BinaryAsciiTransfer.encodeNumeric(v,1, 1.0);
    },
    decode : func(v, pos)
    {
        return BinaryAsciiTransfer.decodeNumeric(v, 1, 1.0, pos);
    }
};

var TransferCoord = 
{
# LatLon scaling; 
# 1 degree = 110574 meters; 
# requires 4 bytes for 1 meter resolution.
# permits 0.1 meter resolution.
    LatLonLength: 4,
    LatLonFactor: 0.000001, 
    AltLength: 3,

    encode : func(v)
    {
        return  BinaryAsciiTransfer.encodeNumeric(v.lat(), TransferCoord.LatLonLength, TransferCoord.LatLonFactor)
        ~ BinaryAsciiTransfer.encodeNumeric(v.lon(), TransferCoord.LatLonLength, TransferCoord.LatLonFactor) 
        ~ emesary.TransferInt.encode(v.alt(), TransferCoord.AltLength);
    },
    decode : func(v,pos)
    {
        var dv = BinaryAsciiTransfer.decodeNumeric(v, TransferCoord.LatLonLength, TransferCoord.LatLonFactor,   pos); 
        var lat = (dv.value);
        dv = BinaryAsciiTransfer.decodeNumeric(v, TransferCoord.LatLonLength, TransferCoord.LatLonFactor,   dv.pos);
        var lon = (dv.value);
        dv = emesary.TransferInt.decode(v, TransferCoord.AltLength, dv.pos); 
        var alt =dv.value;

        dv.value = geo.Coord.new().set_latlon(lat, lon).set_alt(alt);
        return dv;
    }
};

# genericEmesaryGlobalTransmitterTransmit  allowes to use the emesary.GlobalTransmitter via fgcommand
# which in turn allows using it in XML bindings, e.g.
#   <binding>
#       <command>emesary-transmit</command>
#       <type>cockpit-switch</type>
#       <ident>eicas-page-select</ident>
#       <page>hydraulic</page>
#   </binding>
#
var genericEmesaryGlobalTransmitterTransmit  = func(node)
{
    var transmitter = emesary.GlobalTransmitter;
    var t = node.getNode("transmitter",1).getValue();
    if (t != nil) {
        transmitter = emesary.getTransmitter(t);
        if (transmitter == nil) {
            logprint(LOG_WARN, "Invalid transmitter "~t);
            return;
        }
    }
    var type = node.getNode("type").getValue();
    if (type == nil) {
        logprint(LOG_WARN, "emesary-transmit requires a type");
        return;
    }
    var ident = node.getNode("ident").getValue();
    if (ident == nil) {
        logprint(LOG_WARN, "emesary-transmit requires an ident");
        return;
    }    
    var typeid = node.getNode("typeid",1).getValue() or 0;
    if (typeid == 0) { 
        typeid = TypeIdUnspecified;
        logprint(LOG_WARN, "emesary-transmit using generic typeid ", typeid);
    }
    
    var message = emesary.Notification.new(type, ident, typeid);
    node.removeChild("type");
    node.removeChild("id");
    node.removeChild("typeid");

    # add remaining nodes to the message hash
    var children = node.getValues();
    if (children != nil) {
        foreach (var key; keys(children)) {
            message[key] = children[key];
        }
    }
    transmitter.NotifyAll(message);
};

# Temporary bugfix -- FIXME
# removecommand("emesary-transmit"); #in case of reload
addcommand("emesary-transmit", genericEmesaryGlobalTransmitterTransmit);

#setprop("/sim/startup/terminal-ansi-colors",0);
#for(i=-1;i<=1;i+=0.1)
#print ("i ",i, " --> ", (TransferNorm.decode(TransferNorm.encode(i,2), 2,0)).value);
#debug.dump(TransferNorm.decode(TransferNorm.encode(-1,2), 2,0));
#debug.dump(TransferNorm.decode(TransferNorm.encode(0,2), 2,0));
#debug.dump(TransferNorm.decode(TransferNorm.encode(1,2), 2,0));
