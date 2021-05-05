#### Datalink

# Copyright 2020 Colin Geniet.
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
# * Optional (requires same change for other aircrafts).
#   /instrumentation/datalink/channel_mp_string = 7     index of MP string indicating channel
#   /instrumentation/datalink/data_mp_string = 8        index of MP string transmitting data
#
# API:
# - get_contact(callsign)
#     Returns datalink information about callsign as a hash { iff, on_link },
#     or nil if no information is present. Hash members:
#       iff:        one of IFF_UNKNOWN, IFF_HOSTILE, IFF_FRIENDLY
#       on_link:    (bool) indicates if 'callsign' is itself on the datalink.
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
#   It does not actually transmit contact information (except for IFF),
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


### Properties

var channel_mp_string = getprop("/instrumentation/datalink/channel_mp_string") or 7;
var data_mp_string = getprop("/instrumentation/datalink/channel_mp_string") or 8;
var receive_period = getprop("/instrumentation/datalink/receive_period") or 1;

var channel_mp_path = "sim/multiplay/generic/string["~channel_mp_string~"]";
var data_mp_path = "sim/multiplay/generic/string["~data_mp_string~"]";

var input = {
    power:      getprop("/instrumentation/datalink/power_prop"),
    channel:    getprop("/instrumentation/datalink/channel_prop"),
    channel_mp: channel_mp_path,
    data_mp:    data_mp_path,
    models:     "/ai/models",
};

foreach (var name; keys(input)) {
    input[name] = props.globals.getNode(input[name], 1);
}


### String encoding: 'hash|iff'.
# iff is the character 'a'+iff (with ascii encoding).
#
# Callsigns are transmitted as MD5 hashes cut to length 4.
var hash = func(callsign) {
    # Note: callsign is cut to length 7, to only use the part sent over MP.
    if (size(callsign) > 7) callsign = left(callsign, 7);
    return left(md5(callsign), 4);
}

var encode_contact = func(callsign, iff=nil) {
    if (iff == nil) iff = IFF_UNKNOWN;
    return hash(callsign)~chr(97+iff);
}

var decode_contact = func(str) {
    if (size(str) < 4) return nil;

    var contact = { hash: substr(str, 0, 4) };

    if (size(str) >= 5) {
        contact.iff = str[4] - 97;
    } else {
        contact.iff = IFF_UNKNOWN;
    }

    return contact;
}


### Transmission

var clear_data = func {
    input.data_mp.setValue("");
}

var clear_timer = maketimer(1, clear_data);
clear_timer.singleShot = 1;

# Send a list of contact objects via datalink.
#
# timeout: if set, sent data will be cleared after this time (other aircrafts
# won't receive it anymore). Useful if 'send_data' is not called often.
var send_data = func(contacts, timeout=nil) {
    if (!input.power.getBoolValue()) {
        clear_data();
        return;
    }

    var data = "";
    foreach(var contact; contacts) {
        data = data ~ encode_contact(contact.callsign, contact["iff"]) ~ ":";
    }
    input.data_mp.setValue(data);

    if (timeout != nil) {
        clear_timer.restart(timeout);
    }
}


### Receiving loop.
var contacts = {};

var get_contact = func(callsign) {
    return contacts[hash(callsign)];
}

# Add a contact to the table of datalink contacts.
var add_contact = func(hash, iff, on_link) {
    if (!contains(contacts, hash)) {
        contacts[hash] = {
            iff: iff,
            on_link: on_link,
        };
    } else {
        # Already in the table of contacts.
        # In that case, check if the fields 'iff' and 'on_link' need to be changed (upgraded).
        contacts[hash].iff = math.max(contacts[hash].iff, iff);
        contacts[hash].on_link = math.max(contacts[hash].iff, on_link);
    }
}

var receive_loop = func {
    contacts = {};

    foreach(var mp; input.models.getChildren("multiplayer")) {
        if (!mp.getValue("valid")) continue;

        var channel = mp.getValue(channel_mp_path);
        var callsign = mp.getValue("callsign");
        if (callsign == nil or channel == nil or channel != input.channel.getValue()) continue;

        # First add the aircraft on datalink itself.
        add_contact(hash(callsign), IFF_UNKNOWN, 1);

        # Then decode what it's transmitting.
        var data = mp.getValue(data_mp_path);
        if (data == nil or data == "") continue;

        foreach (var token; split(":", data)) {
            var contact = decode_contact(token);
            if (contact != nil) add_contact(contact.hash, contact.iff, 0);
        }
    }
}

var receive_timer = maketimer(receive_period, receive_loop);

setlistener(input.power, func (node) {
    if (node.getBoolValue()) {
        receive_timer.start();
        input.channel_mp.alias(input.channel);
    } else {
        receive_timer.stop();
        contacts = {};
        input.channel_mp.unalias();
        input.channel_mp.setValue("");
        clear_data();
    }
}, 1, 0);
