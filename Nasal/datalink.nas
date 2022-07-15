#### Datalink

# Copyright 2020-2021 Colin Geniet.
# Licensed under the GNU General Public License 2.0 or any later version.


#### Usage

### Generalities
#
# The datalink protocol consists of a core protocol which implements a notion
# of datalink channel, and extensions which allow transmitting actual data.

### Core protocol usage:
#
# Define the following properties (must be defined at nasal loading time).
# * Mandatory
#   /instrumentation/datalink/power_prop                path to property indicating if datalink is on
#   /instrumentation/datalink/channel_prop              path to property containing datalink channel
#   (the channel property can contain anything, and is transmitted/compared as a string).
# * Optional
#   /instrumentation/datalink/receive_period = 1        receiving loop update rate
#
# Optional: Re-define the function
#   datalink.can_transmit(callsign, mp_prop, mp_index)
#
# This function should return 'true' when the given aircraft is able to transmit over datalink to us.
# For instance, it can be used to check line of sight and maximum range.
# The default implementation always returns true (always able to transmit).
# Arguments are callsign, property node /ai/models/multiplayer[i], index of the former node.
#
#
# API:
# - get_data(callsign)
#     Returns all datalink information about 'callsign' as an object, or nil if there is none.
#     This object must not be modified.
#     It contains the following methods:
#       callsign(): The aircraft callsign (same as the argument of get_data()).
#       index():    The aircraft index in /ai/models/multiplayer[i].
#       on_link():  Returns a bool indicating whether 'callsign' is connected to this aircraft through datalink.
#
#     Extensions can define other methods in this object.
#
# - get_connected_callsigns() / get_connected_indices()
#     Returns a vector containing all callsigns, resp. indices
#     in /ai/models/multiplayer[i], of aircrafts connected on datalink.
#     Both vectors use the same order, i.e. get_connected_callsigns()[i]
#     and get_connected_indices()[i] correspond to the same aircraft.
#     Furthermore this order is stable (the relative order of two aircrafts
#     does not change as long as neither disconnects from multiplayer).
#
# - get_all_callsigns()
#     Returns a vector containing all callsigns of aircraft with any associated data.
#     There is no guarantee on the order of callsigns.
#
# - send_data(data, timeout=nil)
#     Send data on the datalink. 'data' is a hash of the form
#       {
#           <extension_name>: <extension_data>,
#           ...
#       }
#     If 'timeout' is set, clear_data() will be called after this delay.
#     Data sent with send_data() is deleted at the next call of send_data(), or by clear_data().
#
# - clear_data()
#     Clear data transmitted by this aircraft.
#
# Important note:
# After a send_data(), and until the next send_data() or clear_data(),
# the datalink behaves as if you are continuously sending the same data.
# Thus, it is important to
#   1. either call send_data() regularly
#   2. or set the timeout argument of send_data()

### Extensions

### Aircraft contacts (extension name: "contacts")
#
# This extension allows to simulate an aircraft transmitting information about
# another aircraft (typically one tracked on radar). The position data is not
# actually transmitted (since everyone can access it from simulator internals).
#
## Receiving data
# This extension adds the following methods to the result of get_data("A"):
#       tracked():          A bool indicating that some aircraft "B" connected on datalink
#                           is transmitting information about aircraft "A".
#       iff():              One of IFF_UNKNOWN, IFF_HOSTILE, IFF_FRIENDLY, or nil if tracked() is false.
#                           Indicates the result of IFF interrogation of "A" by "B"
#                           IFF_UNKNOWN means that e.g. no IFF interrogation was performed.
#       tracked_by():       The callsign of the transmitting aircraft ("A"), or nil if tracked() is false.
#       tracked_by_index(): The index of the transmitting aircraft, or nil if tracked() is false.
#                           The index refers to property nodes /ai/models/multiplayer[i].
#       is_known():         Equivalent to (on_link() or tracked()).
#                           Indicates if the position of this aircraft is supposed to be known
#                           (i.e. whether or not it should be displayed on a HSD or whatever).
#       is_friendly():      Equivalent to (on_link() or iff() == IFF_FRIENDLY).
#       is_hostile():       Equivalent to (!on_link() and iff() == IFF_HOSTILE).
#
## Sending data
# usage: send_data({ contacts: <contacts>, ...}, ...)
# where <contacts> is a vector of hashes of the form { callsign: <callsign>, [iff: <iff>,] }.
# <callsign> is the multiplayer callsign of the tracked aircraft.
# <iff> (optional) is one of IFF_UNKNOWN, IFF_HOSTILE, IFF_FRIENDLY

### Datalink identifier (extension name: "identifier")
#
# This extension allows each aircraft on datalink to transmit a personal
# identifier, e.g. the number of the aircraft in a flight.
#
## Receiving data
# This extension adds the method identifier() to the result of get_data(),
# which returns the identifier, or nil if there is none).
#
## Sending data
# Set the identifier with send_data({"identifier": <identifier>, ...});
# The identifier must be a string. It must not contain '!'.

### Coordinate transmission (extension name: "point")
#
# This extension allows each aircraft to broadcast a coordinate (geo.Coord object).
#
## Receiving data
# This extension adds the method point() to the result of get_data(),
# which results the transmitted geo.Coord object, or nil if there is none.
#
## Sending data
# Transmit a geo.Coord object <coord> with send_data({"point": <coord>, ...});


#### Protocol:
#
# Data is transmitted on MP generic string[7], with the following format:
#   <channel>(!<data>)+
#
# <channel> is a hash of the datalink channel. See hash_channel() and check_channel_hash().
# Each <data> block corresponds to data sent by an extension.
# It starts with a prefix uniquely defining the extension.
# The rest of the block can contain any character (including non-ascii) except '!'.
#
# Remark: '!' as separator is specifically chosen to allow encoding with emesary.Transfer<type>.
#
# The current extension prefixes are the following:
#   contacts:   C
#   identifier: I
#   point:      P

#### Extensions API
#
# Creating a new extension is done with
#   register_extension(name, prefix, object, encode, decode)
# name                      the extension name, used as key in the 'data' argument of send_data().
# prefix                    the protocol prefix.
# class                     contact class parent.
#   A class from which all contact objects will inherit.
#   It must have an init() method, which is called whenever a contact is created.
#
# encode(data)              extension encoding function.
#   Must return the encoding of the extension data (i.e. <data> when calling
#   send_data({name: <data>})) into a string, which may use any character except '!'.
#   The extension prefix must not be part of the encoded string.
#
# decode(aircrafts_data, callsign, index, string)      extension decoding function.
#   'aircrafts_data' is a hash from callsigns to contact objects (see below).
#   'callsign' is the callsign of the aircraft which transmitted this data.
#   'index' is the index of the aircraft which transmitted this data.
#   'string' is the data encoded by encode() and transmitted through datalink.

#   Each contact in 'data' inherits from the core 'Contact' class, and the extension 'class'.
#   decode() is expected to modify 'aircrafts_data', by possibly editing
#   existing contacts and adding new ones.  It should be careful when
#   overwriting existing data in these contacts, including its own: decode()
#   will be called several time on the same 'aircrafts_data' (once for each
#   transmitting aircraft).
#   The modified 'aircrafts_data' hash must be returned.
#
# decode() may use the following helper functions:
#   add_if_missing(aircrafts_data, callsign):
#     Create a new contact object for 'callsign' and add it to 'aircrafts_data',
#     unless an entry for 'callsign' already exists. Returns the modified hash.



#### Version and changelog
# current: v1.1.0, minimum compatible: v1.0.0
#
## v1.1.0:
# Allow external transmission restrictions
# Make transmitting contact IFF optional
# Ensure personal identifier has no '!'
# '\n' is redundant for printf()
# Fix separator character in documentation
# Fix error when sending unknown extension
#
## v1.0.1:
# Add is_known(), is_friendly(), is_hostile() helpers to extension "contacts".
#
## v1.0.0: Initial version
# - Core protocol for datalink channel.
# - Extensions "contacts", "identifier", and "point".



### Parameters
#
# Remark: most parameters need to be the same on all aircrafts.

# Index of multiplayer string used to transmit datalink info.
# Must be the same for all aircrafts.
var mp_string = 7;
var mp_path = "sim/multiplay/generic/string["~mp_string~"]";

var channel_hash_period = 600;

var receive_period = getprop("/instrumentation/datalink/receive_period") or 1;

# Should be overwitten to add transmission restrictions.
var can_transmit = func(contact, mp_prop, mp_index) {
    return 1;
}

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



#### Core protocol implementation

### Channel hash (based on iff.nas)
#
# Channel is hashed with current time (rounded to 10min) and own callsign.

var clean_callsign = func(callsign) {
    return damage.processCallsign(callsign);
}

var my_callsign = func {
    return clean_callsign(input.callsign.getValue());
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

var parse_hexadecimal = func(str) {
    var res = 0;
    for (var i=0; i<size(str); i+=1) {
        res *= 10;
        var c = str[i];
        if (c >= 48 and c < 58) {
            # digit
            res += c - 48;
        } elsif (c >= 65 and c < 71) {
            # upper case letter
            res += c - 55;
        } elsif (c >= 97 and c < 103) {
            # lower case letter
            res += c - 87;
        }
    }
    return res;
}

var _hash_channel = func(time, callsign, channel) {
    # 5 hex digits (2^20) fit in 3 chars for emesary int encoding.
    var hash = parse_hexadecimal(left(md5(time ~ callsign ~ channel), 5));
    return emesary.TransferInt.encode(hash, 3);
}

# Hash channel (when sending).
var encode_channel = func(channel) {
    return _hash_channel(get_time(), my_callsign(), channel);
}

# Check that the hash transmitted by aircraft 'callsign' is correct for 'channel'.
var check_channel = func(hash, callsign, channel) {
    return hash == _hash_channel(get_time(), callsign, channel)
        or hash == _hash_channel(get_prev_time(), callsign, channel)
        or hash == _hash_channel(get_next_time(), callsign, channel);
}

### Contact object
var Contact = {
    new: func(callsign) {
        var c = {
            # contact_parents is the list of all classes from which contacts inherit (for extensions).
            parents: contact_parents,
            _callsign: callsign,
        };
        # Initialize all inherited classes.
        foreach (var class; contact_parents) {
            call(class.init, [], c, nil, nil);
        }
        return c;
    },
    init: func { me._on_link = 0; },

    callsign: func { return me._callsign; },
    index: func { return callsign_to_index[me._callsign]; },
    on_link: func { return me._on_link; },
    set_on_link: func(b) { me._on_link = b; },
};

### Extensions
var extensions = {};
var extension_prefixes = {};
var max_prefix_length = 0;
var contact_parents = [Contact];

var register_extension = func(name, prefix, class, encode, decode) {
    if (contains(extensions, name)) {
        printf("Datalink: double registration of extension '%s'. Skipping.", name);
        return -1;
    }
    if (contains(extension_prefixes, prefix)) {
        printf("Datalink: double registration of extension prefix '%s'. Skipping.", name);
        return -1;
    }
    extensions[name] = { prefix: prefix, encode: encode, decode: decode, };
    extension_prefixes[prefix] = name;
    max_prefix_length = math.max(max_prefix_length, size(prefix));
    append(contact_parents, class);

    return 0;
}


var data_separator = "!";


### Transmission

var clear_data = func {
    send_data({});
}

var clear_timer = maketimer(1, clear_data);
clear_timer.singleShot = 1;

# Send data through datalink.
#
# timeout: if set, sent data will be cleared after this time (other aircrafts
# won't receive it anymore). Useful if 'send_data' is not called often.
var send_data = func(data, timeout=nil) {
    if (!input.power.getBoolValue()) {
        last_data = {};
        input.mp.setValue("");
        return;
    }

    # First encode channel
    var str = encode_channel(input.channel.getValue());

    # Then all extensions
    last_data = data;
    foreach(var ext; keys(data)) {
        # Skip missing extensions with a warning
        if (!contains(extensions, ext)) {
            printf("Warning: unknown datalink extension %s in send_data().", ext);
            continue;
        }
        str = str ~ data_separator ~ extensions[ext].prefix ~ extensions[ext].encode(data[ext]);
    }

    input.mp.setValue(str);

    if (timeout != nil) {
        clear_timer.restart(timeout);
    }
}

# Used internally to update the channel/identifier while keeping the same data.
# Does not touch timeout.
var last_data = {};
var resend_data = func {
    send_data(last_data);
}

# Very slow timer to ensure the channel hash is updated regularly.
# Only relevant if you never call send_data();
var hash_update_timer = maketimer(channel_hash_period/2, resend_data);
hash_update_timer.start();


### Receiving

# callsign to data hash
var aircrafts_data = {};
# List of callsigns / indices connected on datalink (index is for /ai/models/multiplayer[i]).
var connected_callsigns = [];
var connected_indices = [];

# Maintain callsign to multiplayer index hash
# (doesn't cost much since we already iterate over MP models).
var callsign_to_index = {};


var get_data = func(callsign) {
    return aircrafts_data[callsign];
}

var get_connected_callsigns = func {
    return connected_callsigns;
}

var get_connected_indices = func {
    return connected_indices;
}

var get_all_callsigns = func {
    return keys(aircrafts_data);
}

# Helper for modifying aircrafts_data.
var add_if_missing = func(aircrafts_data, callsign) {
    if (!contains(aircrafts_data, callsign)) {
        aircrafts_data[callsign] = Contact.new(callsign);
    }
    return aircrafts_data;
}

var receive_loop = func {
    var my_channel = input.channel.getValue();

    aircrafts_data = {};
    connected_callsigns = [];
    connected_indices = [];

    var mp_models = input.models.getChildren("multiplayer");
    foreach(var mp; mp_models) {
        var idx = mp.getIndex();
        if (!mp.getValue("valid")) continue;
        var callsign = mp.getValue("callsign");
        if (callsign == nil) continue;

        callsign_to_index[callsign] = idx;

        var data = mp.getValue(mp_path);
        if (data == nil) continue;

        # Split channel part and data part
        var tokens = split(data_separator, data);

        # Check channel
        if (!check_channel(tokens[0], callsign, my_channel)) continue;

        # We check this _after_ the channel. Checking the channel is quite cheap,
        # and we don't know how slow this function is, it might have a get_cart_ground_intersection()
        if (!can_transmit(callsign, mp, idx)) continue;

        # Add to list of connected aircrafts.
        append(connected_callsigns, callsign);
        append(connected_indices, idx);
        # Add to data
        aircrafts_data = add_if_missing(aircrafts_data, callsign);
        aircrafts_data[callsign].set_on_link(1);

        # Parse extensions data
        for (var i=1; i<size(tokens); i+=1) {
            var extension = nil;
            # Identify extension prefix.  This is not very clever code, but
            # realistically it doesn't matter since prefixes are very short.
            var len = 1;
            for (; len <= max_prefix_length; len += 1) {
                if (len > size(tokens)) break;
                var prefix = left(tokens[i], len);
                if (contains(extension_prefixes, prefix)) {
                    extension = extension_prefixes[prefix];
                    break;
                }
            }
            # Unknown extension, skip
            if (extension == nil) continue;
            # Remove prefix
            var data = substr(tokens[i], len);
            # Decode
            aircrafts_data = extensions[extension].decode(aircrafts_data, callsign, data);
        }
    }
}

var receive_timer = maketimer(receive_period, receive_loop);


# Start / stop listener
setlistener(input.power, func (node) {
    if (node.getBoolValue()) {
        receive_timer.start();
        resend_data();  # Sets channel/identifier
    } else {
        receive_timer.stop();
        aircrafts_data = {};
        clear_data();
    }
}, 1, 0);

# Listener to resend data so as to update the channel.
setlistener(input.channel, resend_data);



#### Extensions

## Identifier

var ContactIdentifier = {
    init: func {
        me._identifier = nil;
    },
    set_identifier: func(ident) {
        me._identifier = ident;
    },
    identifier: func {
        return me._identifier;
    },
};

var encode_identifier = func(ident) {
    # Force string conversion
    ident = ""~ident;

    if (find("!", ident) >= 0) {
        printf("Datalink: Identifier is not allowed to contain '!': %s.", ident);
        return "";
    } else {
        return ident;
    }
}

var decode_identifier = func(aircrafts_data, callsign, str) {
    aircrafts_data = add_if_missing(aircrafts_data, callsign);
    aircrafts_data[callsign].set_identifier(str);
    return aircrafts_data;
}

register_extension("identifier", "I", ContactIdentifier, encode_identifier, decode_identifier);



## Contacts

# IFF status transmitted over datalink.
var IFF_UNKNOWN = 0;      # Unknown status
var IFF_HOSTILE = 1;      # Considered hostile (no response to IFF).
var IFF_FRIENDLY = 2;     # Friendly, because positive IFF identification.
#   This is also the priority order for IFF reports in case of conflicts:
#   e.g. a contact will be reported as friendly if anyone on datalink reports it as friendly.

var ContactTracked = {
    init: func {
        me._tracked_by = nil;
        me._iff = IFF_UNKNOWN;
    },
    set_tracked_by: func(callsign) {
        me._tracked_by = callsign;
    },
    set_iff: func(iff) {
        # Priority order on IFF values (friendly, then hostile, then no data).
        me._iff = math.max(me._iff, iff);
    },
    tracked: func {
        return me._tracked_by != nil;
    },
    tracked_by: func {
        return me._tracked_by;
    },
    tracked_by_index: func {
        return (me._tracked_by != nil) ? callsign_to_index[me._tracked_by] : nil;
    },
    iff: func {
        return me._iff;
    },
    is_known: func {
        return me.on_link() or me.tracked();
    },
    is_friendly: func {
        return me.on_link() or me.iff() == IFF_FRIENDLY;
    },
    is_hostile: func {
        return !me.on_link() and me.iff() == IFF_HOSTILE;
    },
};

# Contact encoding: callsign + bits
# callsign: the callsign encoded with emesary.TransferString
# bits: bitfield |xxxxxxff| (left is most significant)
#   f: IFF, x: unused
#   encoded with emesary.TransferByte
# Additional values may be appended for extensions.

var encode_contact = func(contact) {
    # Encode bitfield
    var bits = contact["iff"] != nil ? contact.iff : IFF_UNKNOWN;

    return emesary.TransferString.encode(clean_callsign(contact.callsign))
        ~ emesary.TransferByte.encode(bits);
}

var decode_contact = func(str) {
    var res = {};
    var dv = emesary.TransferString.decode(str, 0);
    res.callsign = dv.value;
    dv = emesary.TransferByte.decode(str, dv.pos);
    var bits = dv.value;
    res.iff = math.mod(bits, 4);
    return res;
}

# Special character, won't be used by emesary encoding.
var contacts_separator = "#";

var encode_contacts = func(contacts) {
    var str = "";
    foreach (var contact; contacts) {
        str = str~encode_contact(contact)~contacts_separator;
    }
    return str;
}

var decode_contacts = func(aircrafts_data, callsign, str) {
    var contacts = split(contacts_separator, str);
    foreach (var contact; contacts) {
        if (contact == "") continue;
        var res = decode_contact(contact);
        aircrafts_data = add_if_missing(aircrafts_data, res.callsign);
        aircrafts_data[res.callsign].set_iff(res.iff);
        aircrafts_data[res.callsign].set_tracked_by(callsign);
    }
    return aircrafts_data;
}

register_extension("contacts", "C", ContactTracked, encode_contacts, decode_contacts);



## Coordinate

var ContactPoint = {
    init: func {
        me._point = nil;
    },
    set_point: func(point) {
        me._point = point;
    },
    point: func {
        return me._point;
    },
};

var encode_point = func(coord) {
    return emesary.TransferCoord.encode(coord);
}

var decode_point = func(aircrafts_data, callsign, str) {
    var coord = emesary.TransferCoord.decode(str, 0).value;
    aircrafts_data = add_if_missing(aircrafts_data, callsign);
    aircrafts_data[callsign].set_point(coord);
    return aircrafts_data;
}

register_extension("point", "P", ContactPoint, encode_point, decode_point);