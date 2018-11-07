# (c) 2018 pinto

# GCI/AWACS DESIGN DOC
# 
# possible requests from pilots to AEW:
# 
# PICTURE - full tactical picture
# BOGEY DOPE - BRAA of nearest target
# CUTOFF - vector to nearest target
# 
# The requesting plane has 3 boolean mp properties, one for each request.
# The requestor plane sets 1 property. Setting another property should overwrite
# the original request.
# 
# The AEW has a list of enemy planes. It monitors all non-enemy planes for the
# boolean properties to be set. If it detects a boolean, it will respond using
# a multiplay/generic/string[0-10] with the information needed. It may send
# multiple strings at a rate of approximately 1 string per second.
# 
# String will always be a vector of size 7 after being split() with ':'. Format will be:
# 
# for PICTURE
# requestor-callsign:unique-message-id:2:bearing:range:altitude:[BLUFOR=0|OPFOR=1]
# repeat for all contacts/groups of contacts
# 
# for BOGEY DOPE
# requestor-callsign:unique-message-id:3:bearing:range:altitude:aspect
# 
# for CUTOFF
# requestor-callsign:unique-message-id:4:vector-heading:range:altitude:aspect
# 
# for no info available to send:
# requestor-callsign:unique-message-id:1:n:n:n:n
# 
# for when all info is sent:
# requestor-callsign:unique-message-id:0:d:d:d:d
# 
# The receiving aircraft will then parse these messages. Upon all messages read,
# the receiving aircraft will set the boolean property to 0.

var picture_prop = props.globals.getNode("/instrumentation/gci/picture");
var bogeydope_prop = props.globals.getNode("/instrumentation/gci/bogeydope");
var cutoff_prop = props.globals.getNode("/instrumentation/gci/cutoff");

# time in seconds to wait for a GCI response, before setting gci_prop to false.
var max_listen_time = 10;

# update rate in seconds
var update_rate = 1;

# mp models to check for gci BRAA messages
var gci_models = [
    "gci",
];

# used variables
var iter = 0;
var last_msg_id = -1;
var model = "";
var dist = 99999999;
var cs_node = props.globals.getNode("/sim/multiplay/callsign");
var ids = [];
var msgdata = [];
var timer_ct = 0;

# find the closest AEW
var aew_cx = nil;
var find_aew_cx = func() {
    if (picture_prop.getValue() or bogeydope_prop.getValue() or cutoff_prop.getValue()) {
        # dont want to wipe this if we are in the middle of a request.
        return;
    }
    #print('searching for aew');
    aew_cx = nil;
    ids = [];
    dist = 99999999; # twice the diameter of earth
    foreach (var mp; props.globals.getNode("/ai/models").getChildren("multiplayer")) {
        #print('checking ' ~ mp.getNode("callsign").getValue());
        model = remove_suffix(remove_suffix(split(".", split("/", mp.getNode("sim/model/path").getValue())[-1])[0], "-model"), "-anim");
        #print("is it " ~ model);
        if (find_match(model,gci_models) == 0) { continue; }
        dist_to = geo.aircraft_position().distance_to(geo.Coord.new().set_latlon(mp.getNode("position/latitude-deg").getValue(),mp.getNode("position/longitude-deg").getValue()));
        if (dist_to < dist) {
            dist = dist_to;
            aew_cx = mp;
            for (var i = 0; i <= 10; i = i + 1) {
                var msg = getprop(aew_cx.getPath() ~ "/sim/multiplay/generic/string["~i~"]");
                if (msg == "") { continue; }
                if (msg == nil) { continue; }
                msgdata = split(":",msg);
                if (msgdata[0] == cs_node.getValue()) {
                    append(ids,msgdata[1]);
                }
            }
            #print('aew_cx found');
        }
    }
}

# check AEW properties for messages
var counter = 0;
var check_messages = func() {
    #debug.dump(ids);
    if (aew_cx == nil) { return; }
    #print('checking messages');
    msgdata = [];
    for (var i = 0; i <= 10; i = i + 1) {
        var msg = getprop(aew_cx.getPath() ~ "/sim/multiplay/generic/string["~i~"]");
        if (msg == "") { continue; }
        if (msg == nil) { continue; }
        msgdata = split(":",msg);
        #debug.dump(msgdata);
        if (msgdata[0] != cs_node.getValue()) {
            continue;
        } elsif (find_match(msgdata[1],ids)) {
            msgdata = [];
            continue;
        } else {
            append(msgdata,aew_cx.getNode("callsign").getValue());
            append(ids,msgdata[1]);
            parse_msg(msgdata);
            counter = 0;
            break;
        }
    }
    if (picture_prop.getValue() or bogeydope_prop.getValue() or cutoff_prop.getValue()) {
        counter = counter + 1;
    } else {
        counter = 0;
    }
    if (counter == max_listen_time) {
        screen.log.write("No contact from GCI.", 1.0, 0.2, 0.2);
        picture_prop.setValue(0);
        bogeydope_prop.setValue(0);
        cutoff_prop.setValue(0);
    }
}

var parse_msg = func(msg) {
    # msg should be a vector in the form of: 
    # destination callsign, id, type of message, bearing (degrees), range (meters), altitude (feet), aspect (degrees), sender callsign
    # type of message:
    # 0 - message completed sending
    # 1 - no info to report
    # 2 - picture
    # 3 - bogey dope
    # 4 - cutoff
    # if the gci couldnt find anybody, it will send a 'null' string for [2] through [5]
    # altitude is rounded to the nearest 100.
    if (size(msg) != 8) {
        print("AEW code received invalid message: " ~ debug.dump(msg));
        return; # message is invalid
    }
    
    var output = msg[0] ~ ", " ~ msg[7] ~ ", ";
    
    #debug.dump(msg);

    if (msg[2] == 0) {
        if (picture_prop.getValue()) {
            output = output ~ "all information sent, over.";
        } else {
            output = "";
        }
        picture_prop.setValue(0);
        bogeydope_prop.setValue(0);
        cutoff_prop.setValue(0);
    } elsif (msg[2] == 1) {
        output = output ~ "skies are clear, over.";
        picture_prop.setValue(0);
        bogeydope_prop.setValue(0);
        cutoff_prop.setValue(0);
    } elsif (msg[2] == 2) {
        # PICTURE message
        # 3:bearing, 4:range, 5:altitude, 6:blufor=0/opfor=1
        output = msg[6] ? output ~ "OPFOR is " : output ~ "BLUFOR is ";
        output = output ~ msg[3] ~ " at " ~ int(math.round(msg[4],1000))*M2NM ~ "nm, ";
        output = output ~ "altitude " ~ int(math.round(msg[5] * FT2M,100))*M2FT ~ "ft.";
    } elsif (msg[2] == 3) {
        # DOPE BOGEY message
        # 3:bearing, 4:range, 5:altitude, 6:aspect
        output = output ~ "bandit " ~ msg[3] ~ " at " ~ int(math.round(int(msg[4]),1000))*M2NM ~ "nm, ";
        output = output ~ "altitude " ~ int(math.round(msg[5] * FT2M,100))*M2FT ~ "ft, ";
        msg[6] = math.abs(msg[6]);
        if (msg[6] > 110) {
            output = output ~ "dragging.";
        } elsif (msg[6] > 70) {
            output = output ~ "beaming";
        } elsif (msg[6] > 30) {
            output = output ~ "flanking";
        } else {
            output = output ~ "hot";
        }
        picture_prop.setValue(0);
        bogeydope_prop.setValue(0);
        cutoff_prop.setValue(0);
    } elsif (msg[2] == 4) {
        # cutoff vector
        #requestor-callsign:unique-message-id:4:vector-heading:time:altitude:aspect
        #debug.dump(msg);
        output = output ~ "fly " ~ msg[3] ~ " at altitude " ~ int(math.round(msg[5] * FT2M,100))*M2FT ~ "ft, ";
        #print(output);
        output = output ~ "ETA " ~ int(msg[4]) ~ "s, ";
        #print(output);
        msg[6] = math.abs(msg[6]);
        if (msg[6] > 110) {
            output = output ~ "dragging.";
        } elsif (msg[6] > 70) {
            output = output ~ "beaming";
        } elsif (msg[6] > 30) {
            output = output ~ "flanking";
        } else {
            output = output ~ "hot";
        }
        #print(output);
        picture_prop.setValue(0);
        bogeydope_prop.setValue(0);
        cutoff_prop.setValue(0);
    } else {
        picture_prop.setValue(0);
        bogeydope_prop.setValue(0);
        cutoff_prop.setValue(0);
    }
    
    if (output != "") {
        screen.log.write(output, 1.0, 0.2, 0.2);
    }
}

var main_loop = func() {
    if (iter == 1) {
        find_aew_cx();
    }
    check_messages();
    iter = iter > 10 ? 0 : iter + 1;
    settimer(func() { main_loop(); }, update_rate);
}

main_loop();

var find_match = func(val,vec) {
    if (size(vec) == 0) {
        return 0;
    }
    foreach (var a; vec) {
        #print(a);
        if (a == val) { return 1; }
    }
    return 0;
}

var remove_suffix = func(s, x) {
    var len = size(x);
    if (substr(s, -len) == x)
        return substr(s, 0, size(s) - len);
    return s;
}