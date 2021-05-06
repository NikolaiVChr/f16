#### Datalink

# Copyright 2020-2021 Colin Geniet.
# Licensed under the GNU General Public License 2.0 or any later version.


# Usage:
#
# Define the following properties (must be defined at nasal loading time).
# * Mandatory
#   /instrumentation/datalink/power_prop                path to property indicating if datalink is on
#   /instrumentation/datalink/channel_prop              path to property containing datalink channel
#   (the channel property can contain anything, and is transmitted/compared as a string).
# * Optional
#   /instrumentation/datalink/receive_period = 1        receiving loop update rate
#   /instrumentation/datalink/identifier_prop           path to optional property containing an aircraft identifier
#   (Identifier is intended to help distinguish between aircrafts connected on the same datalink channel.
#    It could e.g. correspond to a 'wingman number'. It can contain anything and is transmitted as a string.).
#
# API:
# - is_known(callsign), is_connected(callsign), is_friendly(callsign)
#     Simplified datalink information about callsign.
#     is_known(callsign): Indicates that either 1. callsign is connected on datalink,
#                         or 2. someone is transmitting info on callsign on datalink.
#                         (in short, callsign should be displayed)
#     is_connected(callsign): Indicates that callsign is connected on your datalink channel.
#     is_friendly(callsign): Indicates that callsign should be considered as friendly based on datalink info alone,
#                            meaning 1. callsign is connected on datalink or 2. someone on datalink identified callsign as friendly.
#                            This does NOT send an IFF query to 'callsign', this must be done separately if required.
#
# - get_contact(callsign)
#     Returns datalink information about callsign as a hash { iff, on_link, identifier },
#     or nil if no information is present.
#       iff:        one of IFF_UNKNOWN, IFF_HOSTILE, IFF_FRIENDLY
#       on_link:    (bool) indicates if 'callsign' is itself on the datalink.
#       identifier: (string) the identifier transmitted by this aircraft (nil if not transmitted).
#       from_callsign:  callsign of the aircraft which transmitted this contact on datalink, or nil
#       from_index:     index in /ai/models/multiplayer[i] of the aircraft which transmitted this contact on datalink, or nil
#       from_ident:     datalink identifier of the aircraft which transmitted this contact on datalink, or nil
#
#   To summarize, if aircraft A calls get_contact() on aircraft B, the following is returned:
#   1. If A and B are on same datalink channel:
#       on_link=1, identifier possibly set,
#       iff=IFF_UNKNOWN and from_callsign=from_index=from_ident=nil unless point 2 also applies.
#   2. If aircrafts A and C are on the same datalink channel, and C is transmitting info about B:
#       iff=<whatever IFF status C is transmitting for B>,
#       from_callsign=<callsign of C>, from_index=<index of C in /ai/models>, from_ident=<identifier of C>
#       on_link=0 and identifier=nil, unless point 1 also applies.
#   3. Otherwise (B is not on datalink, and no third aircraft on datalink is transmitting info on B),
#      get_contact() returns nil.
#
# - get_connected_callsigns() / get_connected_indices()
#     Returns a vector containing all callsigns, resp. indices in /ai/models/multiplayer[i],
#     of aircrafts connected on datalink (but not other aircraft whose information is sent on datalink).
#     Both vectors use the same indices, i.e. get_connected_callsigns()[i] and get_connected_indices()[i]
#     correspond to the same aircraft.
#
#
# - send_data(contacts, timeout=nil)
#     Send a list of contact objects on datalink.
#     'contacts' must be a vector of hashes of the form { callsign, iff }.
#     In the contacts 'iff' is optional, and should be one of IFF_UNKNOWN, IFF_HOSTILE, IFF_FRIENDLY.
#     After 'timeout' (if set), 'clear_data()' is called.
#
# - clear_data()
#     Clear data transmitted by this aircraft.
#
# Notes:
# - The datalink only indicates to other aircrafts that this aircraft is tracking some contact.
#   It does not actually transmit contact information (except for identifier/IFF),
#   since other aircrafts internally can access it.
# - After a 'send_data(contacts)', and until the next 'send_data()' or 'clear_data()',
#   the datalink behaves as if you are continuously sending information on 'contacts'.
#   Thus, it is important to update 'send_data()' regularly, or to set the 'timeout' argument.

# IFF status transmitted over datalink.
var IFF_UNKNOWN = 0;      # Unknown status
var IFF_HOSTILE = 1;      # Considered hostile (no response to IFF).
var IFF_FRIENDLY = 2;     # Friendly, because positive IFF identification.
#   This is also the priority order for IFF reports in case of conflicts:
#   e.g. a contact will be reported as friendly if anyone on datalink reports it as friendly.


### Parameters
#
# Remark: most parameters need to be the same on all aircrafts.

# Index of multiplayer string used to transmit datalink info.
# Must be the same for all aircrafts.
var mp_string = 7;
var mp_path = "sim/multiplay/generic/string["~mp_string~"]";

var channel_hash_period = 600;
var channel_hash_length = 3;
var callsign_hash_length = 4;

var receive_period = getprop("/instrumentation/datalink/receive_period") or 1;

### Properties

var input = {
    power:      getprop("/instrumentation/datalink/power_prop"),
    channel:    getprop("/instrumentation/datalink/channel_prop"),
    ident:      getprop("/instrumentation/datalink/identifier_prop"),
    mp:         mp_path,
    models:     "/ai/models",
    callsign:   "/sim/multiplay/callsign",
};

foreach (var name; keys(input)) {
    if (input[name] != nil) {
        input[name] = props.globals.getNode(input[name], 1);
    }
}


### String encoding of a contact information: 'hash + iff' (no separator)
# iff is the character 'a'+iff (with ascii encoding).
#
# Callsigns are transmitted as MD5 hashes cut to length 'callsign_hash_length'.

var hash_callsign = func(callsign) {
    # Note: callsign is cut to length 7, to only use the part sent over MP.
    if (size(callsign) > 7) callsign = left(callsign, 7);
    return left(md5(callsign), callsign_hash_length);
}

var encode_contact = func(callsign, iff=nil) {
    if (iff == nil) iff = IFF_UNKNOWN;
    return hash_callsign(callsign)~chr(97+iff);
}

var decode_contact = func(str) {
    if (size(str) < callsign_hash_length) return nil;

    var contact = { hash: substr(str, 0, callsign_hash_length) };

    if (size(str) >= callsign_hash_length+1) {
        contact.iff = str[callsign_hash_length] - 97;
    } else {
        contact.iff = IFF_UNKNOWN;
    }

    return contact;
}


### Channel hash (based on iff.nas)
#
# Channel is hashed with current time (rounded to 10min) and own callsign.

var my_callsign = func {
    var callsign = input.callsign.getValue();
    # Cut to length 7, only use the part sent over MP.
    if (size(callsign) > 7) callsign = left(callsign, 7);
    return callsign;
}

# Time, rounded to 'channel_hash_period'. This is used to hash channel.
var get_time = func {
    return int(math.floor(systime() / channel_hash_period) * channel_hash_period);
}

# Previous / next time (with channel_hash_period interval).
# This is used to give a bit of margin on the time check.
# (will work if system clocks are coordinated within 10min).
var get_prev_time = func { return get_time() - channel_hash_period; }
var get_next_time = func { return get_time() + channel_hash_period; }

var _hash_channel = func(time, callsign, channel) {
    return left(md5(time ~ callsign ~ channel), channel_hash_length)
}

# Hash channel (when sending).
var hash_channel = func(channel) {
    return _hash_channel(get_time(), my_callsign(), channel);
}

# Check that the hash transmitted by aircraft 'callsign' is correct for 'channel'.
var check_channel_hash = func(hash, callsign, channel) {
    return hash == _hash_channel(get_time(), callsign, channel)
        or hash == _hash_channel(get_prev_time(), callsign, channel)
        or hash == _hash_channel(get_next_time(), callsign, channel);
}



### Transmission
#
# The format of the MP sring content is
# channel[:identifier]#contact1:contact2:...contactn:
# where
# - ':','#' are literal separators
# - channel, hashed by hash_channel() (use check_channel_hash() to test value).
# - identifier (optional) is the literal content of identifier_prop.
# - contact1 ... contactn is the list of transmitted contacts, encoded with encode_contact().

var clear_data = func {
    send_data([]);
}

var clear_timer = maketimer(1, clear_data);
clear_timer.singleShot = 1;

# Send a list of contact objects via datalink.
#
# timeout: if set, sent data will be cleared after this time (other aircrafts
# won't receive it anymore). Useful if 'send_data' is not called often.
var last_contacts = [];

var send_data = func(contacts, timeout=nil) {
    if (!input.power.getBoolValue()) {
        last_contacts = [];
        input.mp.setValue("");
        return;
    }

    # First encode channel and identifier.
    var data = hash_channel(input.channel.getValue());
    if (input.ident != nil) {
        data = data ~ ":" ~ input.ident.getValue();
    }

    # Contacts
    last_contacts = contacts;
    data = data~'#';
    foreach(var contact; contacts) {
        data = data ~ encode_contact(contact.callsign, contact["iff"]) ~ ":";
    }
    input.mp.setValue(data);

    if (timeout != nil) {
        clear_timer.restart(timeout);
    }
}

# Used internally to update the channel/identifier while keeping the same contacts info.
# Does not touch timeout.
var resend_data = func {
    send_data(last_contacts);
}

# Very slow timer to ensure the channel hash is updated regularly.
# Only relevant if you never call send_data();
var hash_update_timer = maketimer(channel_hash_period/2, resend_data);
hash_update_timer.start();



### Receiving loop.

# Contacts information (hash)
var contacts = {};
# List of callsigns / indices connected on datalink (index is for /ai/models/multiplayer[i]).
var connected_callsigns = [];
var connected_indices = [];

var get_contact = func(callsign) {
    return contacts[hash_callsign(callsign)];
}

# Simplified API
var is_known = func(callsign) {
    return get_contact(callsign) != nil;
}

var is_connected = func(callsign) {
    var data = get_contact(callsign);
    return data != nil and data.on_link;
}

var is_friendly = func(callsign) {
    var data = get_contact(callsign);
    return data != nil and (data.on_link or data.iff == IFF_FRIENDLY);
}



var get_connected_callsigns = func {
    return connected_callsigns;
}

var get_connected_indices = func {
    return connected_indices;
}

# Add a contact to the table of datalink contacts.
var add_contact = func(hash, iff, on_link, identifier, from_callsign, from_index, from_ident) {
    if (!contains(contacts, hash)) {
        contacts[hash] = {
            iff: iff,
            on_link: on_link,
            identifier: identifier,
            from_callsign: from_callsign,
            from_index: from_index,
            from_ident: from_ident,
        };
    } else {
        # Already in the table of contacts.
        # In that case, check if the fields 'iff', 'on_link', 'identifier' need to be changed (upgraded).
        contacts[hash].iff = math.max(contacts[hash].iff, iff);
        contacts[hash].on_link = math.max(contacts[hash].iff, on_link);
        if (contacts[hash].identifier == nil) {
            contacts[hash].identifier = identifier;
        }
        if (contacts[hash].from_callsign == nil) {
            contacts[hash].from_callsign = from_callsign;
            contacts[hash].from_index = from_index;
            contacts[hash].from_ident = from_ident;
        }
    }
}

var receive_loop = func {
    var my_channel = input.channel.getValue();

    contacts = {};
    connected_callsigns = [];
    connected_indices = [];

    var mp_models = input.models.getChildren("multiplayer");
    forindex(var idx; mp_models) {
        var mp = mp_models[idx];
        if (!mp.getValue("valid")) continue;

        var data = mp.getValue(mp_path);
        var callsign = mp.getValue("callsign");
        if (callsign == nil or data == nil) continue;

        # Split channel part and data part
        var tokens = split("#", data);
        if (size(tokens) != 2) continue;

        var channel = tokens[0];
        var contacts = tokens[1];

        # Check channel
        var tokens = split(":", channel);
        if (size(tokens) < 1) continue;
        channel = tokens[0];

        if (!check_channel_hash(channel, callsign, my_channel)) continue;

        # Add to list of connected aircrafts.
        append(connected_callsigns, callsign);
        append(connected_indices, idx);

        # Optional datalink identifier
        var identifier = (size(tokens) >= 2) ? tokens[1] : nil;

        # First add the aircraft on datalink itself.
        add_contact(hash_callsign(callsign), IFF_UNKNOWN, 1, identifier, nil, nil, nil);

        # Then decode what it's transmitting.
        foreach (var token; split(":", contacts)) {
            var contact = decode_contact(token);
            if (contact != nil) add_contact(contact.hash, contact.iff, 0, nil, callsign, idx, identifier);
        }
    }
}

var receive_timer = maketimer(receive_period, receive_loop);

setlistener(input.power, func (node) {
    if (node.getBoolValue()) {
        receive_timer.start();
        resend_data();  # Sets channel/identifier
    } else {
        receive_timer.stop();
        contacts = {};
        clear_data();
    }
}, 1, 0);

setlistener(input.channel, resend_data);
if (input.ident != nil) setlistener(input.ident, resend_data);
