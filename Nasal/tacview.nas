# Copyright by Justin Nicholson (aka Pinto)
# Released under the GNU General Public License version 2.0
#
# Authors: Pinto, Nikolai V. Chr., Colin Geniet

# Short installation instructions:
# - Add and load this file in the 'tacview' namespace.
# - Adjust the four parameters just below.
# - Set property /payload/d-config/tacview_supported=1
# - Ensure the radar code sets 'tacobj' fields properly.
#   In Nikolai/Richard generic 'radar-system.nas',
#   this simply requires setting 'enable_tacobject=1'.
# - Add some way to start/stop recording.

### Parameters to adjust (example values from the F-16)

# Aircraft type string for tacview
var tacview_ac_type = getprop("sim/variant-id") < 3 ? "F-16A" : "F-16C";
# Aircraft type as inserted in the output file name
var filename_ac_type = "f16";

# Function returning an array of "contact" objects, containing all aicrafts tacview is to show.
# A contact object must
# - implement the API specified by missile-code.nas
# - have a getModel() method, which will be used as aircraft type designator in tacview.
# - contain a field 'tacobj', which must be an instance of the 'tacobj' class below,
#   and have the 'tacviewID' and 'valid' fields set appropriately.
#
var get_contacts_list = func {
    return radar_system.getCompleteList();
}

# Function returning the focused/locked aircraft, as a "contact" object (or nil).
var get_primary_contact = func {
    return radar_system.apg68Radar.getPriorityTarget();
}

# Radar range. May return nil if n/a
var get_radar_range_nm = func {
    return radar_system.apg68Radar.getRange();
}

### End of parameters


var main_update_rate = 0.3;
var write_rate = 10;

var outstr = "";

var timestamp = "";
var output_file = "";
var f = "";
var myplaneID = int(rand()*10000);
var starttime = 0;
var writetime = 0;

var seen_ids = [];

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

var input = {
    mp_host:    "sim/multiplay/txhost",
    radar:      "sim/multiplay/generic/int[2]",
    fuel:       "consumables/fuel/total-fuel-lbs",
    gear:       "gear/gear[0]/position-norm",
    lat:        "position/latitude-deg",
    lon:        "position/longitude-deg",
    alt:        "position/altitude-ft",
    roll:       "orientation/roll-deg",
    pitch:      "orientation/pitch-deg",
    heading:    "orientation/heading-deg",
    tas:        "fdm/jsbsim/velocities/vtrue-kts",
    cas:        "velocities/airspeed-kt",
    mach:       "velocities/mach",
    aoa:        "orientation/alpha-deg",
    gforce:     "accelerations/pilot-g",
};

foreach (var name; keys(input)) {
    input[name] = props.globals.getNode(input[name], 1);
}


var startwrite = func() {
    if (starttime)
        return;

    timestamp = getprop("/sim/time/utc/year") ~ "-" ~ getprop("/sim/time/utc/month") ~ "-" ~ getprop("/sim/time/utc/day") ~ "T";
    timestamp = timestamp ~ getprop("/sim/time/utc/hour") ~ ":" ~ getprop("/sim/time/utc/minute") ~ ":" ~ getprop("/sim/time/utc/second") ~ "Z";
    var filetimestamp = string.replace(timestamp,":","-");
    output_file = getprop("/sim/fg-home") ~ "/Export/tacview-" ~ filename_ac_type ~ "-" ~ filetimestamp ~ ".acmi";
    # create the file
    f = io.open(output_file, "w");
    io.close(f);
    var color = ",Color=Blue";
    if (left(getprop("sim/multiplay/callsign"),5)=="OPFOR") {
        color=",Color=Red";
    }
    var meta = sprintf(",DataSource=FlightGear %s,DataRecorder=%s v%s", getprop("sim/version/flightgear"), getprop("sim/description"), getprop("sim/aircraft-version"));
    thread.lock(mutexWrite);
    write("FileType=text/acmi/tacview\nFileVersion=2.1\n");
    write("0,ReferenceTime=" ~ timestamp ~ meta ~ "\n#0\n");
    write(myplaneID ~ ",T=" ~ getLon() ~ "|" ~ getLat() ~ "|" ~ getAlt() ~ "|" ~ getRoll() ~ "|" ~ getPitch() ~ "|" ~ getHeading() ~ ",Name="~tacview_ac_type~",CallSign="~getprop("/sim/multiplay/callsign")~color~"\n"); #
    thread.unlock(mutexWrite);
    starttime = systime();
    setprop("/sim/screen/black","Starting Tacview recording");
    main_timer.start();
}

var stopwrite = func() {
    main_timer.stop();
    setprop("/sim/screen/black","Stopping Tacview recording");
    writetofile();
    starttime = 0;
    seen_ids = [];
    explo_arr = [];
    explosion_timeout_loop(1);
}

var mainloop = func() {
    if (!starttime) {
        main_timer.stop();
        return;
    }
    if (systime() - writetime > write_rate) {
        writetofile();
    }
    thread.lock(mutexWrite);
    write("#" ~ (systime() - starttime)~"\n");
    thread.unlock(mutexWrite);
    writeMyPlanePos();
    writeMyPlaneAttributes();
    foreach (var cx; get_contacts_list()) {
        if(cx.get_type() == armament.ORDNANCE) {
            continue;
        }
        if (cx["prop"] != nil and cx.prop.getName() == "multiplayer" and input.mp_host.getValue() == "mpserver.opredflag.com") {
            continue;
        }
        var color = ",Color=Blue";
        if (left(cx.get_Callsign(),5)=="OPFOR" or left(cx.get_Callsign(),4)=="OPFR") {
            color=",Color=Red";
        }
        thread.lock(mutexWrite);
        if (find_in_array(seen_ids, cx.tacobj.tacviewID) == -1) {
            append(seen_ids, cx.tacobj.tacviewID);
            var model_is = cx.getModel();
            if (model_is=="Mig-28") {
                model_is = tacview_ac_type;
                color=",Color=Red";
            }
            write(cx.tacobj.tacviewID ~ ",Name="~ model_is~ ",CallSign=" ~ cx.get_Callsign() ~color~"\n")
        }
        if (cx.tacobj.valid) {
            var cxC = cx.getCoord();
            lon = cxC.lon();
            lat = cxC.lat();
            alt = cxC.alt();
            roll = cx.get_Roll();
            pitch = cx.get_Pitch();
            heading = cx.get_heading();
            speed = cx.get_Speed()*KT2MPS;

            write(cx.tacobj.tacviewID ~ ",T=");
            if (lon != cx.tacobj.lon) {
                write(sprintf("%.6f",lon));
                cx.tacobj.lon = lon;
            }
            write("|");
            if (lat != cx.tacobj.lat) {
                write(sprintf("%.6f",lat));
                cx.tacobj.lat = lat;
            }
            write("|");
            if (alt != cx.tacobj.alt) {
                write(sprintf("%.1f",alt));
                cx.tacobj.alt = alt;
            }
            write("|");
            if (roll != cx.tacobj.roll) {
                write(sprintf("%.1f",roll));
                cx.tacobj.roll = roll;
            }
            write("|");
            if (pitch != cx.tacobj.pitch) {
                write(sprintf("%.1f",pitch));
                cx.tacobj.pitch = pitch;
            }
            write("|");
            if (heading != cx.tacobj.heading) {
                write(sprintf("%.1f",heading));
                cx.tacobj.heading = heading;
            }
            if (speed != cx.tacobj.speed) {
                write(sprintf(",TAS=%.1f",speed));
                cx.tacobj.speed = speed;
            }
            write("\n");
        }
        thread.unlock(mutexWrite);
    }
    explosion_timeout_loop();
}

var main_timer = maketimer(main_update_rate, mainloop);


var writeMyPlanePos = func() {
    thread.lock(mutexWrite);
    write(myplaneID ~ ",T=" ~ getLon() ~ "|" ~ getLat() ~ "|" ~ getAlt() ~ "|" ~ getRoll() ~ "|" ~ getPitch() ~ "|" ~ getHeading() ~ "\n");
    thread.unlock(mutexWrite);
}

var writeMyPlaneAttributes = func() {
    var tgt = "";
    var contact = get_primary_contact();
    if (contact != nil) {
        tgt= ",FocusedTarget="~contact.tacobj.tacviewID;
    }
    var rmode = ",RadarMode=1";
    if (input.radar.getBoolValue()) {
        rmode = ",RadarMode=0";
    }
    var rrange = get_radar_range_nm();
    if (rrange != nil) {
        rrange = sprintf(",RadarRange=%.0f", get_radar_range_nm()*NM2M);
    } else {
        rrange = "";
    }
    var fuel = sprintf(",FuelWeight=%.0f", input.fuel.getValue());
    var gear = sprintf(",LandingGear=%.2f", input.gear.getValue());
    var tas = getTas();
    if (tas != nil) {
        tas = ",TAS="~tas;
    } else {
        tas = "";
    }
    var str = myplaneID ~ fuel~rmode~rrange~gear~tas~",CAS="~getCas()~",Mach="~getMach()~",AOA="~getAoA()~",HDG="~getHeading()~tgt~",VerticalGForce="~getG()~"\n";#",Throttle="~getThrottle()~",Afterburner="~getAfterburner()~
    thread.lock(mutexWrite);
    write(str);
    thread.unlock(mutexWrite);
}

var explo = {
    tacviewID: 0,
    time: 0,
};

var explo_arr = [];

# needs threadlocked before calling
var writeExplosion = func(lat,lon,altm,rad) {
    var e = {parents:[explo]};
    e.tacviewID = 21000 + int(math.floor(rand()*20000));
    e.time = systime();
    append(explo_arr, e);
    write("#" ~ (systime() - starttime)~"\n");
    write(e.tacviewID ~",T="~lon~"|"~lat~"|"~altm~",Radius="~rad~",Type=Explosion\n");
}

var explosion_timeout_loop = func(all = 0) {
    foreach(var e; explo_arr) {
        if (e.time) {
            if (systime() - e.time > 15 or all) {
                thread.lock(mutexWrite);
                write("#" ~ (systime() - starttime)~"\n");
                write("-"~e.tacviewID);
                thread.unlock(mutexWrite);
                e.time = 0;
            }
        }
    }
}

var write = func(str) {
    outstr = outstr ~ str;
}

var writetofile = func() {
    if (outstr == "") {
        return;
    }
    writetime = systime();
    f = io.open(output_file, "a");
    io.write(f, outstr);
    io.close(f);
    outstr = "";
}

var getLat = func() {
    return input.lat.getValue();
}

var getLon = func() {
    return input.lon.getValue();
}

var getAlt = func() {
    return sprintf("%.2f", input.alt.getValue() * FT2M);
}

var getRoll = func() {
    return sprintf("%.2f", input.roll.getValue());
}

var getPitch = func() {
    return sprintf("%.2f", input.pitch.getValue());
}

var getHeading = func() {
    return sprintf("%.2f", input.heading.getValue());
}

var getTas = func() {
    var tas = input.tas.getValue();
    if (tas != nil)
        return sprintf("%.1f", tas * KT2MPS);
    else
        return nil;
}

var getCas = func() {
    return sprintf("%.1f", input.cas.getValue() * KT2MPS);
}

var getMach = func() {
    return sprintf("%.3f", input.mach.getValue());
}

var getAoA = func() {
    return sprintf("%.2f", input.aoa.getValue());
}

var getG = func() {
    return sprintf("%.2f", input.gforce.getValue());
}

#var getThrottle = func() {
#    return sprintf("%.2f", getprop("velocities/thrust");
#}

#var getAfterburner = func() {
#    return getprop("velocities/thrust")>0.61*0.61;
#}

var find_in_array = func(arr,val) {
    forindex(var i; arr) {
        if ( arr[i] == val ) {
            return i;
        }
    }
    return -1;
}

#setlistener("/controls/armament/pickle", func() {
#    if (!starttime) {
#        return;
#    }
#    thread.lock(mutexWrite);
#    write("#" ~ (systime() - starttime)~"\n");
#    write("0,Event=Message|"~ myplaneID ~ "|Pickle, selection at " ~ (getprop("controls/armament/pylon-knob") + 1) ~ "\n");
#    thread.unlock(mutexWrite);
#},0,0);

setlistener("/controls/armament/trigger", func(p) {
    if (!starttime) {
        return;
    }
    thread.lock(mutexWrite);
    if (p.getValue()) {
        write("#" ~ (systime() - starttime)~"\n");
        write("0,Event=Message|"~ myplaneID ~ "|Trigger pressed.\n");
    } else {
        write("#" ~ (systime() - starttime)~"\n");
        write("0,Event=Message|"~ myplaneID ~ "|Trigger released.\n");
    }
    thread.unlock(mutexWrite);
},0,0);

setlistener("/sim/multiplay/chat-history", func(p) {
    if (!starttime) {
        return;
    }
    var hist_vector = split("\n",p.getValue());
    if (size(hist_vector) > 0) {
        var last = hist_vector[size(hist_vector)-1];
        last = string.replace(last,",",chr(92)~chr(44));#"\x5C"~"\x2C"
        thread.lock(mutexWrite);
        write("#" ~ (systime() - tacview.starttime)~"\n");
        write("0,Event=Message|Chat ["~last~"]\n");
        thread.unlock(mutexWrite);
    }
},0,0);


var msg = func (txt) {
    if (!starttime) {
        return;
    }
    thread.lock(mutexWrite);
    write("#" ~ (systime() - tacview.starttime)~"\n");
    write("0,Event=Message|"~myplaneID~"|AI ["~txt~"]\n");
    thread.unlock(mutexWrite);
}

setlistener("damage/sounds/explode-on", func(p) {
    if (!starttime) {
        return;
    }

    if (p.getValue()) {
        thread.lock(mutexWrite);
        write("#" ~ (systime() - tacview.starttime)~"\n");
        write("0,Event=Destroyed|"~myplaneID~"\n");
        thread.unlock(mutexWrite);
    }
},0,0);
