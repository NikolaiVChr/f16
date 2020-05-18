# This file is from the implementation in l0k1/MiG-21bis

var main_update_rate = 0.3;
var write_rate = 10;

var outstr = "";

var timestamp = "";
var output_file = "";
var f = "";
var myplaneID = 999;
var starttime = 0;
var writetime = 0;

seen_ids = [];

var tacobj = {
    tacviewID: 0,
    lat: 0,
    lon: 0,
    alt: 0,
    roll: 0,
    pitch: 0,
    heading: 0,
    speed: -1,
    valid: 0,
};

var lat = 0;
var lon = 0;
var alt = 0;
var roll = 0;
var pitch = 0;
var heading = 0;
var speed = 0;
var mutexWrite = thread.newlock();

var startwrite = func() {
    timestamp = getprop("/sim/time/utc/year") ~ "-" ~ getprop("/sim/time/utc/month") ~ "-" ~ getprop("/sim/time/utc/day") ~ "T";
    timestamp = timestamp ~ getprop("/sim/time/utc/hour") ~ ":" ~ getprop("/sim/time/utc/minute") ~ ":" ~ getprop("/sim/time/utc/second") ~ "Z";
    filetimestamp = string.replace(timestamp,":","-");
    output_file = getprop("/sim/fg-home") ~ "/Export/tacview-" ~ filetimestamp ~ ".acmi";
    # create the file
    f = io.open(output_file, "w+");
    io.close(f);
    thread.lock(mutexWrite);
    write("FileType=text/acmi/tacview\nFileVersion=2.1\n");
    write("0,ReferenceTime=" ~ timestamp ~ "\n#0\n");
    write(myplaneID ~ ",T=" ~ getLon() ~ "|" ~ getLat() ~ "|" ~ getAlt() ~ "|" ~ getRoll() ~ "|" ~ getPitch() ~ "|" ~ getHeading() ~ ",Name=MiG-29_9-12,CallSign="~getprop("/sim/multiplay/callsign")~"\n"); #
    thread.unlock(mutexWrite);
    starttime = systime();
    setprop("/sim/screen/black","Starting tacview recording");
    settimer(func(){mainloop();}, main_update_rate);
}

var stopwrite = func() {
    setprop("/sim/screen/black","Stopping tacview recording");
    writetofile();
    starttime = 0;
}

var mainloop = func() {
    if (!starttime) {
        return;
    }
    settimer(func(){mainloop();}, main_update_rate);
    if (systime() - writetime > write_rate) {
        writetofile();
    }
    thread.lock(mutexWrite);
    write("#" ~ (systime() - starttime)~"\n");
    writeMyPlanePos();
    # writeMyPlaneAttributes();
    thread.unlock(mutexWrite);
    foreach (var cx; mpdb.cx_master_list) {
        thread.lock(mutexWrite);
        if (find_in_array(seen_ids, cx.tacobj.tacviewID) == -1) {
            append(seen_ids, cx.tacobj.tacviewID);
            write(cx.tacobj.tacviewID ~ ",Name="~cx.get_model2() ~ ",CallSign=" ~ cx.get_Callsign() ~"\n")
        }
        if (cx.tacobj.valid) {
            lon = cx.get_Longitude();
            lat = cx.get_Latitude();
            alt = cx.get_altitude() * FT2M;
            roll = cx.get_Roll();
            pitch = cx.get_Pitch();
            heading = cx.get_heading();
            speed = cx.get_Speed()*KT2MPS;
            
            write(cx.tacobj.tacviewID ~ ",T=");
            if (lon != cx.tacobj.lon) {
                write(lon);
                cx.tacobj.lon = lon;
            }
            write("|");
            if (lat != cx.tacobj.lat) {
                write(lat);
                cx.tacobj.lat = lat;
            }
            write("|");
            if (alt != cx.tacobj.alt) {
                write(alt);
                cx.tacobj.alt = alt;
            }
            write("|");
            if (roll != cx.tacobj.roll) {
                write(roll);
                cx.tacobj.roll = roll;
            }
            write("|");
            if (pitch != cx.tacobj.pitch) {
                write(pitch);
                cx.tacobj.pitch = pitch;
            }
            write("|");
            if (heading != cx.tacobj.heading) {
                write(heading);
                cx.tacobj.heading = heading;
            }
            if (speed != cx.tacobj.speed) {
                write(",TAS="~speed);
                cx.tacobj.speed = speed;
            }
            write("\n");
        }
        thread.unlock(mutexWrite);
    }
}

var writeMyPlanePos = func() {
    thread.lock(mutexWrite);
    write(myplaneID ~ ",T=" ~ getLon() ~ "|" ~ getLat() ~ "|" ~ getAlt() ~ "|" ~ getRoll() ~ "|" ~ getPitch() ~ "|" ~ getHeading() ~ "\n");
    thread.unlock(mutexWrite);
}

# var writeMyPlaneAttributes = func() {
#     thread.lock(mutexWrite);
#     write(myplaneID ~ ",TAS="~getTas()~",MACH="~getMach()~",AOA="~getAoA()~",HDG="~getHeading()~",Throttle="~getThrottle()~",Afterburner="~getAfterburner()~"\n");
#     thread.unlock(mutexWrite);
# }


var write = func(str) {
    outstr = outstr ~ str;
}

var writetofile = func() {
    if (outstr == "") {
        return;
    }
    writetime = systime();
    f = io.open(output_file, "a+");
    io.write(f, outstr);
    io.close(f);
    outstr = "";
}

var getLat = func() {
    return getprop("/position/latitude-deg");
}

var getLon = func() {
    return getprop("/position/longitude-deg");
}

var getAlt = func() {
    return rounder(getprop("/position/altitude-ft") * FT2M,0.01);
}

var getRoll = func() {
    return rounder(getprop("/orientation/roll-deg"),0.01);
}

var getPitch = func() {
    return rounder(getprop("/orientation/pitch-deg"),0.01);
}

var getHeading = func() {
    return rounder(getprop("/orientation/heading-deg"),0.01);
}

# var getTas = func() {
#     return rounder(getprop("/velocities/tas-kt") * KT2MPS,1.0);
# }

# var getMach = func() {
#     return rounder(getprop("/velocities/mach"),0.001);
# }

# var getAoA = func() {
#     return rounder(getprop("/orientation/alpha-deg"),0.01);
# }

# var getThrottle = func() {
#     return rounder(getprop("/fdm/jsbsim/fcs/throttle-cmd-norm"),0.01);
# }

# var getAfterburner = func() {
#     return getprop("/fdm/jsbsim/fcs/aug-active");
# }

var rounder = func(x, p) {
    v = math.mod(x, p);
    if ( v <= (p * 0.5) ) {
        x = x - v;
    } else {
        x = (x + p) - v;
    }
}

var find_in_array = func(arr,val) {
    forindex(var i; arr) {
        if ( arr[i] == val ) {
            return i;
        }
    }
    return -1;
}

# setlistener("/controls/armament/pickle", func() {
#     if (!starttime) {
#         return;
#     }
#     thread.lock(mutexWrite);
#     write("#" ~ (systime() - starttime)~"\n");
#     write("0,Event=Message|"~ myplaneID ~ "|Pickle, selection at " ~ (getprop("controls/armament/pylon-knob") + 1) ~ "\n");
#     thread.unlock(mutexWrite);
# },0,0);

# setlistener("/controls/armament/trigger", func(p) {
#     if (!starttime) {
#         return;
#     }
#     thread.lock(mutexWrite);
#     if (p.getValue()) {
#         write("#" ~ (systime() - starttime)~"\n");
#         write("0,Event=Message|"~ myplaneID ~ "|Trigger pressed.\n");
#     } else {
#         write("#" ~ (systime() - starttime)~"\n");
#         write("0,Event=Message|"~ myplaneID ~ "|Trigger released.\n");
#     }
#     thread.unlock(mutexWrite);
# },0,0);

setlistener("/sim/multiplay/chat-history", func(p) {
    if (!starttime) {
        return;
    }
    var hist_vector = split("\n",p.getValue());
    if (size(hist_vector) > 0) {
        var last = hist_vector[size(hist_vector)-1];
        thread.lock(mutexWrite);
        write("#" ~ (systime() - tacview.starttime)~"\n");
        write("0,Event=Message|Chat ["~hist_vector[size(hist_vector)-1]~"]\n");
        thread.unlock(mutexWrite);
    }
},0,0);