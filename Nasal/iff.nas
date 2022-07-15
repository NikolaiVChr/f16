# IFF system
# turns a channel number into an iff md5 hash
#
# gplv2 by pinto aka justin nicholson
#
# installation instructions:
#
# load this nasal file at the bottom of your set file like normal.
# in your set file, under <instrumentation> <iff>
#
# <power_prop type="string">
# required. property path to whatever property your want to use to power on or off this iff module.
# the power property should be a bool, 0 for off, 1 for on.
# <channel_prop type="string">
# required. property path to whatever property your using to keep track of your iff channel selection.
# channels can be ints, strings, or floats.
# <iff_mp_string type="int">
# optional, default 4. the generic mp property to send and recieve hashes on. /ai/models/multiplayer[x]/generic/string[iff_mp_string]
# <iff_hash_length type="int">
# optional, default 3. how long the hash string should be. recommended 3 or 4, 1 or 2 are not recommended due to hash collisions. 3 has 46,656 possible combinations.
# <iff_unique_id type="string">
# optional, default "". if you'd like to only have your planes match with a certain subset, set iff_unique_id to "NATO" or "WARSAW" or whatever you'd like.
# <iff_refresh_rate type="int">
# optional, default 120. how quickly the hash will change. this needs to be an int, and synced with other planes.
#
#
# to use:
#
# interrogate(tgt)
# tgt should be a node pointing to the targets /ai/models/multiplayer[x] root
# returns 1 if a match, otherwise 0.
#

var iff_refresh_rate = getprop("/instrumentation/iff/iff_refresh_rate") or 120;
var iff_unique_id = getprop("/instrumentation/iff/iff_unique_id") or "";
var iff_hash_length = getprop("/instrumentation/iff/iff_hash_length") or 3;
var iff_mp_string = getprop("/instrumentation/iff/iff_mp_string") or 4;

var node = {
	power:			props.globals.getNode(getprop("/instrumentation/iff/power_prop")),
	channel:		props.globals.getNode(getprop("/instrumentation/iff/channel_prop")),
	#hash:				props.globals.getNode("/sim/multiplay/generic/string["~iff_mp_string~"]"),
	hash:				props.globals.initNode("/sim/multiplay/generic/string["~iff_mp_string~"]","AAA","STRING"),
	callsign:		props.globals.getNode("/sim/multiplay/callsign"),
};

var iff_hash = {
	new: func() {
		var m = {parents:[iff_hash]};
		m.int_systime = int(systime());
		m.update_time = int(math.mod(m.int_systime,iff_refresh_rate));
		m.time = m.int_systime - m.update_time; # time used in hash
		m.timer = maketimer(iff_refresh_rate - m.update_time,func(){m.loop()});
		m.callsign = node.callsign.getValue();
		return m;
	},

	loop: func() {
		if (node.power.getBoolValue()) {
			if (me.timer.isRunning == 0) {
				me.timer.start();
			}
			me.int_systime = int(systime());
			me.update_time = int(math.mod(me.int_systime,iff_refresh_rate));
			me.time = me.int_systime - me.update_time;
			node.hash.setValue(_calculate_hash(me.time, node.callsign.getValue(), node.channel.getValue()));
		} else {
			me.timer.stop();
			node.hash.setValue("");
		}
	},
};

var hash1 = "";
var hash2 = "";
var check_hash = "";
var last_interogate = 0;

var interrogate = func(tgt) {
	if ( tgt.getChild("callsign") == nil or tgt.getNode("sim/multiplay/generic/string["~iff_mp_string~"]") == nil ) {
		return 0;
	}
	var cs = tgt.getChild("callsign").getValue();
	cs = size(cs) < 8?cs:left(cs, 7);
	hash1 = _calculate_hash(int(systime()) - int(math.mod(int(systime()),iff_refresh_rate)), cs,node.channel.getValue());
	hash2 = _calculate_hash(int(systime()) - int(math.mod(int(systime()),iff_refresh_rate)) - iff_refresh_rate, cs,node.channel.getValue());
	check_hash = tgt.getNode("sim/multiplay/generic/string["~iff_mp_string~"]").getValue();
	#print("hash1 " ~ hash1);
	#print("hash2 " ~ hash2);
	#print("check_hash " ~ check_hash);
	if ( hash1 == check_hash or hash2 == check_hash ) {
		return 1;
	} else {
		return 0;
	}
}

var _calculate_hash = func(time, callsign, channel) {
	#print("time|" ~ time ~ "|");
	#print("callsign|" ~ callsign ~ "|");
	#print("channel|" ~ channel ~ "|");
	#print("hash|"~left(md5(time ~ callsign ~ channel ~ iff_unique_id),iff_hash_length)~"|");
	callsign = size(callsign) < 8?callsign:left(callsign, 7);
	return left(md5(time ~ callsign ~ channel ~ iff_unique_id),iff_hash_length);
}

var new_hashing = iff_hash.new();
new_hashing.loop();
setlistener(node.channel,func(){new_hashing.loop();},nil,0);
setlistener(node.power,func(){new_hashing.loop();},nil,0);
setlistener(node.callsign,func(){new_hashing.loop();},nil,0);
