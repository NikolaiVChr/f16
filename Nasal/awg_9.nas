#
# F-16 Radar routines. based on the F-15
# ---------------------------
# RWR (Radar Warning Receiver) is computed in the radar loop for better performance
# AWG-9 Radar computes the nearest target for AIM-9.
# ---------------------------
# Richard Harrison (rjh@zaretto.com) 2014-11-23. Based on F-14b by xii
# - 2015-07 : Modified to have target selection - nearest_u is retained
#             however active_u is the currently active target which mostly
#             should be the same as nearest_u - but use active_u instead in 
#             most of the code. nearest_u is kept for compatibility.
# 
var TRUE =1;
var FALSE=0;

var ElapsedSec        = props.globals.getNode("sim/time/elapsed-sec");
var SwpFac            = props.globals.getNode("sim/model/f16/instrumentation/radar-awg-9/sweep-factor", 1);
var DisplayRdr        = props.globals.getNode("sim/model/f16/instrumentation/radar-awg-9/display-rdr",1);
var HudTgtHDisplay    = props.globals.getNode("sim/model/f16/instrumentation/radar-awg-9/hud/target-display", 1);
var HudTgt            = props.globals.getNode("sim/model/f16/instrumentation/radar-awg-9/hud/target", 1);
var HudTgtTDev        = props.globals.getNode("sim/model/f16/instrumentation/radar-awg-9/hud/target-total-deviation", 1);
var HudTgtTDeg        = props.globals.getNode("sim/model/f16/instrumentation/radar-awg-9/hud/target-total-angle", 1);
var HudTgtClosureRate = props.globals.getNode("sim/model/f16/instrumentation/radar-awg-9/hud/closure-rate", 1);
var HudTgtDistance = props.globals.getNode("sim/model/f16/instrumentation/radar-awg-9/hud/distance", 1);
var AzField           = props.globals.getNode("instrumentation/radar/az-field", 1);
var RangeRadar2       = props.globals.getNode("instrumentation/radar/radar2-range",1);
var RadarStandby      = props.globals.getNode("sim/multiplay/generic/int[17]",1);
var OurAlt            = props.globals.getNode("position/altitude-ft",1);
var OurHdg            = props.globals.getNode("orientation/heading-deg",1);
var OurRoll           = props.globals.getNode("orientation/roll-deg",1);
var OurPitch          = props.globals.getNode("orientation/pitch-deg",1);
var EcmOn             = props.globals.getNode("instrumentation/ecm/on-off", 1);
var WcsMode           = props.globals.getNode("sim/model/f16/instrumentation/radar-awg-9/wcs-mode",1);
var SWTgtRange        = props.globals.getNode("sim/model/f16/systems/armament/aim9/target-range-nm",1);


var az_fld            = AzField.getValue();
var l_az_fld          = 0;
var r_az_fld          = 0;
var swp_fac           = nil;    # Scan azimuth deviation, normalized (-1 --> 1).
var swp_deg           = nil;    # Scan azimuth deviation, in degree.
var swp_deg_last      = 0;      # Used to get sweep direction.
var swp_spd           = 0.5; 
var swp_dir           = nil;    # Sweep direction, 0 to left, 1 to right.
var swp_dir_last      = 0;
var ddd_screen_width  = 0.0844; # 0.0844m : length of the max azimuth range on the DDD screen.
var range_radar2      = 0;
var my_radarcorr      = 0;
var our_radar_stanby  = 0;
var wcs_mode          = "pulse-srch";
var tmp_nearest_rng   = nil;
var tmp_nearest_u     = nil;
var nearest_rng       = 0;
var nearest_u         = nil;
var active_u = nil;
var active_u_callsign = nil; # currently active callsign
var our_true_heading  = 0;
var our_alt           = 0;

var Mp = props.globals.getNode("ai/models");
var mp_i              = 0;
var mp_count          = 0;
var mp_list           = [];
var tgts_list         = [];
var cnt               = 0;
# Dual-control vars: 
var we_are_bs         = 0;
var pilot_lock        = 0;

# ECM warnings.
var EcmAlert1 = props.globals.getNode("instrumentation/ecm/alert-type1", 1);
var EcmAlert2 = props.globals.getNode("instrumentation/ecm/alert-type2", 1);
var ecm_alert1        = 0;
var ecm_alert2        = 0;
var ecm_alert1_last   = 0;
var ecm_alert2_last   = 0;
var u_ecm_signal      = 0;
var u_ecm_signal_norm = 0;
var u_radar_standby   = 0;
var u_ecm_type_num    = 0;
var FD_TAN3DEG = 0.052407779283; # tan(3)
var sel_next_target = 0;
var sel_prev_target = 0;

init = func() {
	var our_ac_name = getprop("sim/aircraft");
our_ac_name = "f16c";
	my_radarcorr = radardist.my_maxrange( our_ac_name ); # in kilometers
#print("ac ",our_ac_name," my_radarcorr ",my_radarcorr);
#	if (our_ac_name == "f16-bs") { we_are_bs = 1; }
	}

var counting = 1;
var az_scan = func() {
    counting += 1;
    if (counting == 5) counting = 1;
    var doRWR = counting == 1;

    l_az_fld = - az_fld / 2;
    r_az_fld = az_fld / 2;
	our_true_heading = OurHdg.getValue();
	our_alt = OurAlt.getValue();
    var radar_active = !getprop("sim/multiplay/generic/int[2]");
    var radar_mode = nil;#getprop("sim/multiplay/generic/int[17]");
    if (radar_mode == nil)
      radar_mode = 0;
    if (radar_mode >= 3)
      radar_active = 0;
#
#
# The radar sweep is simulated such that when the scan limit is reached it is reversed
# and the mp list is rescanned. This means the contents of the radar list will be 
# simulated in a realistic way - the target acquisition based on what's in the MP list will
# be ok; the values (distance etc) will be read from the target list so these will be accurate
# which isn't quite how radar works but it will be good enough for us.

    if (1==1)
    {
#print("Sweep ",active_u, active_u_callsign);
		# Antena scan direction change (at max: more or less every 2 seconds). Reads the whole MP_list.
		# TODO: Visual glitch on the screen: the sweep line jumps when changing az scan field.

		range_radar2 = RangeRadar2.getValue();
		if ( range_radar2 == 0 ) { range_radar2 = 0.00000001 }

		# Reset nearest_range score
		nearest_u = tmp_nearest_u;
		nearest_rng = tmp_nearest_rng;
		tmp_nearest_rng = nil;
		tmp_nearest_u = nil;

		tgts_list = [];
        rwrList = [];
		var raw_list = Mp.getChildren();

        if (active_u == nil or active_u.Callsign == nil or active_u.Callsign.getValue() == nil or active_u.Callsign.getValue() != active_u_callsign)
        {
            if (active_u != nil) {
                #print("active_u callsign ",active_u.Callsign.getValue());
                #print("active_u ",active_u);
                #print("active_u_callsign ",active_u_callsign);
                #print("Active callsign becomes inactive");
                active_u = nil;
                armament.contact = active_u;
            }
        }
        if (radar_active == 0) {
            active_u = nil;
            armament.contact = active_u;
        }
        completeList = [];
		foreach( var c; raw_list )
        {
			# FIXME: At that time a multiplayer node may have been deleted while still
			# existing as a displayable target in the radar targets nodes.
			var type = c.getName();

            if (c.getNode("valid") == nil or !c.getNode("valid").getValue() or c.getNode("position") == nil) {#position check is to avoid cannon impacts
				continue;
			}
			var HaveRadarNode = c.getNode("radar");

            
            if(!isVisibleByTerrain.do(c)) {
                continue;
            }
            var u = Target.new(c);

            if (active_u != nil and u.get_Callsign() == active_u.get_Callsign()) {
                # replace selection with new, so it can be proper checked for still being visible to radar
                active_u = u;
                armament.contact = active_u;
            }

            u_ecm_signal      = 0;
            u_ecm_signal_norm = 0;
            u_radar_standby   = 0;
            u_ecm_type_num    = 0;
            var u_rng = u.get_range();

            #if (doRWR == 1 and u_rng != nil and u_rng < 150 and (type == "multiplayer" or type == "tanker" or type == "aircraft" or type=="carrier" or type=="groundvehicle" or type=="ship")) 
            #{
            #    rwrNew(u);
            #}
            append(completeList,u);
            if (!radar_active)
              continue;
            if (u_rng != nil and (u_rng < range_radar2  and u.not_acting == 0 ) and rcs.inRadarRange(u, 70, 3.2))#APG68/66
            {
#
# Decide if this mp item is a valid return (and within range).
# - our radar switched on
# - their radar switched on
# - their transponder switched on 

                var visible = 0;
                var their_radar_mode = 0;
                var their_radar_node = nil;#c.getNode("multiplay/generic/int[17]");
                if (their_radar_node != nil and their_radar_node.getValue() != nil)
                  their_radar_mode = their_radar_node.getValue();

                if (radar_mode < 2 or their_radar_mode == nil or their_radar_mode < 2) # either radar on and they're visible
                    visible = 1;
                else if (radar_mode == 2 and (their_radar_mode == nil or their_radar_mode < 2)) # in standby we still see them if their radar is one
                    visible = 1;

#                print("Visi: our_mode=",radar_mode, " their_mode=",their_radar_mode, " visl=",visible);

                if (!visible)
                    continue;

                if (c.getNode("callsign") == nil)
                    continue;

                u.get_deviation(our_true_heading);

                if (u.deviation > l_az_fld  and  u.deviation < r_az_fld )
                {
                    u.set_display(1);
                }
                else
                {
                    u.set_display(0);
                }
#                if (type == "multiplayer" or type == "tanker" or type == "aircraft" and HaveRadarNode != nil) 
                if (type == "multiplayer" or type == "tanker" or type == "aircraft" or type=="carrier" or type=="groundvehicle" or type=="ship") 
                {
                    append(tgts_list, u);
                    ecm_on = EcmOn.getValue();
                    # Test if target has a radar. Compute if we are illuminated. This propery used by ECM
                    # over MP, should be standardized, like "ai/models/multiplayer[0]/radar/radar-standby".
#printf("RWR test ",c.getNode("callsign"), " =",their_radar_mode);
                    if (their_radar_mode < 2 or (ecm_on and u.get_rdr_standby() == 0))
                      {
#printf(" ** RWR on ",c.getNode("callsign"), " =",their_radar_mode);
                        #rwr(u);	# TODO: override display when alert.
                    }
                }
            } else {
                u.set_display(0);
            }
		}
        
		# Summarize ECM alerts.
		if ( ecm_alert1 == 0 and ecm_alert1_last == 0 ) { EcmAlert1.setBoolValue(0) }
		if ( ecm_alert2 == 0 and ecm_alert1_last == 0 ) { EcmAlert2.setBoolValue(0) }
		ecm_alert1_last = ecm_alert1; # And avoid alert blinking at each loop.
		ecm_alert2_last = ecm_alert2;
		ecm_alert1 = 0;
		ecm_alert2 = 0;
	}

#    print("2:nearest u set  ",active_u_callsign);
    var tgt_cmd = getprop("sim/model/f16/instrumentation/radar-awg-9/select-target");
    setprop("sim/model/f16/instrumentation/radar-awg-9/select-target",0);
    if (tgt_cmd != nil)
    {
        if (tgt_cmd > 0)
            awg_9.sel_next_target=1;
        else if (tgt_cmd < 0)
            awg_9.sel_prev_target=1;
    }

    if (awg_9.sel_prev_target)
    {
        var dist  = 0;
        if (awg_9.active_u != nil)
        {
            dist = awg_9.active_u.get_range();
        }
#        print("Sel prev target:");

        var sorted_dist = sort (awg_9.tgts_list, func (a,b) {a.get_range()-b.get_range()});
        var prv=nil;
        foreach (var u; sorted_dist) 
        {
#            printf("TGT:: %5.2f (%5.2f) : %s ",u.get_range(), dist, u.Callsign.getValue());
            if(u.Callsign.getValue() == active_u_callsign and prv != nil)
            {
#                if (prv != nil)
#                    print("Located prev: ",prv.Callsign.getValue(), prv.get_range());
#                else
#                    print("first in list");
                break;
            }
            if(u.get_display() == 0) {
                continue;
            }
            prv = u;
        }
        if (prv == nil and 1==0)
        {
            var idx = size(sorted_dist)-1;
            if (idx > 0)
            {
                prv = sorted_dist[idx];
#                print("Using last in list ",idx," = ",prv.Callsign.getValue(), prv.get_range());
            }
        }

        if (prv != nil)
        {
            active_u = nearest_u = tmp_nearest_u = prv;
            armament.contact = active_u;
            if (tmp_nearest_u.Callsign != nil)
                active_u_callsign = tmp_nearest_u.Callsign.getValue();
            else
                active_u_callsign = nil;
                
#            printf("prv: %s %3.1f", prv.Callsign.getValue(), prv.get_range());
        }
        awg_9.sel_prev_target =0;
    }
    else if (awg_9.sel_next_target)
    {
        var dist  = 0;
        if (awg_9.active_u != nil)
        {
            dist = awg_9.active_u.get_range();
        }
#        print("Sel next target: dist=",dist);

        var sorted_dist = sort (awg_9.tgts_list, func (a,b) {a.get_range()-b.get_range()});
        var nxt=nil;
        foreach (var u; sorted_dist) 
        {
#            printf("TGT:: %5.2f (%5.2f) : %s ",u.get_range(), dist, u.Callsign.getValue());
            if(nxt == nil and u.get_display()) {
                nxt = u;
            }
            if(u.Callsign.getValue() == active_u_callsign)
            {
#                print("Skipping active target ",active_u_callsign);
                continue;
}
            if(u.get_range() > dist and u.get_display())
            {
                nxt = u;
#                print("Located next ",nxt.Callsign.getValue(), nxt.get_range());
                break;
            }
        }
        if (nxt == nil and 1==0)
        {
            if(size(sorted_dist)>0)
                nxt = sorted_dist[0];
        }

        if (nxt != nil)
        {
            active_u = nearest_u = tmp_nearest_u = nxt;armament.contact = active_u;
            if (tmp_nearest_u.Callsign != nil)
                active_u_callsign = tmp_nearest_u.Callsign.getValue();
            else
                active_u_callsign = nil;
                
#            printf("nxt: %s %3.1f", nxt.Callsign.getValue(), nxt.get_range());
        }
        awg_9.sel_next_target =0;
    }

    cnt += 0.05;

    if (!containsV(tgts_list, active_u)) {
        active_u = nil;
        armament.contact = active_u;
        #active_u_callsign = nil;
    }
    if(rwrs.rwr != nil and doRWR == 1) {
        rwrNew();
        rwrs.rwr.update(rwrList);
    }
}

setprop("sim/mul"~"tiplay/gen"~"eric/strin"~"g[14]", "op"~"r"~"f16");

var containsV = func (vector, content) {
    if (content == nil) {
        return 0;
    }
    foreach(var vari; vector) {
        if (vari.string == content.string) {
            return 1;
        }
    }
    return 0;
}

#
# The following 1 methods is from Mirage 2000-5
#
var isVisibleByTerrain = {
    do: func(node) {
        #
        # This is quite a performance hit; so let's disable for now. 

            var SelectCoord = geo.Coord.new();
            var x = nil;
            var y = nil;
            var z = nil;
            call(func {
                x = node.getNode("position/global-x").getValue();
                y = node.getNode("position/global-y").getValue();
                z = node.getNode("position/global-z").getValue(); },
                nil, var err = []);
            if(x == nil or y == nil or z == nil) {
                return 1;
            }
            var SelectCoord = geo.Coord.new().set_xyz(x, y, z);

            me.myOwnPos = geo.aircraft_position();
            if(me.myOwnPos.alt() > 8900 and SelectCoord.alt() > 8900) {
              # both higher than mt. everest, so not need to check.
              return TRUE;
            }
              me.xyz = {"x":me.myOwnPos.x(),                  "y":me.myOwnPos.y(),                 "z":me.myOwnPos.z()};
              me.dir = {"x":SelectCoord.x()-me.myOwnPos.x(),  "y":SelectCoord.y()-me.myOwnPos.y(), "z":SelectCoord.z()-me.myOwnPos.z()};

              # Check for terrain between own aircraft and other:
              me.v = get_cart_ground_intersection(me.xyz, me.dir);
              if (me.v == nil) {
                return TRUE;
                #printf("No terrain, planes has clear view of each other");
              } else {
               me.terrain = geo.Coord.new();
               me.terrain.set_latlon(me.v.lat, me.v.lon, me.v.elevation);
               me.maxDist = me.myOwnPos.direct_distance_to(SelectCoord)-1;
               me.terrainDist = me.myOwnPos.direct_distance_to(me.terrain);
               if (me.terrainDist < me.maxDist) {
                 #print("terrain found between the planes");
                 return FALSE;
               } else {
                  return TRUE;
                  #print("The planes has clear view of each other");
               }
              }
            
            return TRUE;
    },
};


var hud_nearest_tgt = func() {
	# Computes nearest_u position in the HUD
	if ( active_u != nil ) {
		SWTgtRange.setValue(active_u.get_range());
		var our_pitch = OurPitch.getValue();
		#var u_dev_deg = (90 - active_u.get_deviation(our_true_heading));
		#var u_elev_deg = (90 - active_u.get_total_elevation(our_pitch));
		var u_dev_rad = (90 - active_u.get_deviation(our_true_heading)) * D2R;
		var u_elev_rad = (90 - active_u.get_total_elevation(our_pitch)) * D2R;
#print("active_u ",wcs_mode, active_u.get_range()," Display", active_u.get_display(), "dev ",active_u.deviation," ",l_az_fld," ",r_az_fld);
		if (
			wcs_mode == "tws-auto"
			and active_u.get_display()
			and active_u.deviation > l_az_fld
			and active_u.deviation < r_az_fld
		) {
			var devs = aircraft.develev_to_devroll(u_dev_rad, u_elev_rad);
			var combined_dev_deg = devs[0];
			var combined_dev_length =  devs[1];
			var clamped = devs[2];
			if ( clamped ) {
				Diamond_Blinker.blink();
			} else {
				Diamond_Blinker.cont();
			}

			# Clamp closure rate from -200 to +1,000 Kts.
			var cr = active_u.ClosureRate.getValue();

			if (cr != nil)
            {
                if (cr < -200) 
                    cr = 200;
                else if (cr > 1000) 
                    cr = 1000;
    			HudTgtClosureRate.setValue(cr);
            }

			HudTgtTDeg.setValue(combined_dev_deg);
			HudTgtTDev.setValue(combined_dev_length);
			HudTgtHDisplay.setBoolValue(1);
            HudTgtDistance.setValue(active_u.get_range());

			var u_target = active_u.type ~ "[" ~ active_u.index ~ "]";

            var callsign = active_u.Callsign.getValue();
            var model = "";

            if (active_u.Model != nil)
                model = active_u.Model.getValue();

            var target_id = "";
            if(callsign != nil)
                target_id = callsign;
            else
                target_id = u_target;
            if (model != nil and model != "")
                target_id = target_id ~ " " ~ model;

            HudTgt.setValue(target_id);
			return;
		}
	}
	SWTgtRange.setValue(0);
	HudTgtClosureRate.setValue(0);
	HudTgtTDeg.setValue(0);
	HudTgtTDev.setValue(0);
	HudTgtHDisplay.setBoolValue(0);
}
# HUD clamped target blinker
Diamond_Blinker = aircraft.light.new("sim/model/f16/lighting/hud-diamond-switch", [0.1, 0.1]);
setprop("sim/model/f16/lighting/hud-diamond-switch/enabled", 1);


# ECM: Radar Warning Receiver
rwr = func(u) {
	var u_name = radardist.get_aircraft_name(u.string);
	var u_maxrange = radardist.my_maxrange(u_name); # in kilometer, 0 is unknown or no radar.
	var horizon = u.get_horizon( our_alt );
	var u_rng = u.get_range();
	var u_carrier = u.check_carrier_type();
	if ( u_maxrange > 0  and u_rng < horizon ) {
		# Test if we are in its radar field (hard coded 74°) or if we have a MPcarrier.
		# Compute the signal strength.
		var our_deviation_deg = deviation_normdeg(u.get_heading(), u.get_reciprocal_bearing());
		if ( our_deviation_deg < 0 ) { our_deviation_deg *= -1 }
		if ( our_deviation_deg < 37 or u_carrier == 1 ) {
			u_ecm_signal = (((-our_deviation_deg/20)+2.5)*(!u_carrier )) + (-u_rng/20) + 2.6 + (u_carrier*1.8);
			u_ecm_type_num = radardist.get_ecm_type_num(u_name);
		}
	}
	# Compute global threat situation for undiscriminant warning lights
	# and discrete (normalized) definition of threat strength.
	if ( u_ecm_signal > 1 and u_ecm_signal < 3 ) {
		EcmAlert1.setBoolValue(1);
		ecm_alert1 = 1;
		u_ecm_signal_norm = 2;
	} elsif ( u_ecm_signal >= 3 ) {
		EcmAlert2.setBoolValue(1);
		ecm_alert2 = 1;
		u_ecm_signal_norm = 1;
	}
    #
    # Set these again once the lights are done as need these for the RWR display.
    u_ecm_signal = (-u_rng/20) + 2.6;
    u_ecm_type_num = radardist.get_ecm_type_num(u_name);
	
    u.EcmSignal.setValue(u_ecm_signal);
	u.EcmSignal.setValue(u_ecm_signal);
	u.EcmSignalNorm.setIntValue(u_ecm_signal_norm);
	u.EcmTypeNum.setIntValue(u_ecm_type_num);
}


# Utilities.
var deviation_normdeg = func(our_heading, target_bearing) {
	var dev_norm = our_heading - target_bearing;
	while (dev_norm < -180) dev_norm += 360;
	while (dev_norm > 180) dev_norm -= 360;
	return(dev_norm);
}



var rounding1000 = func(n) {
	var a = int( n / 1000 );
	var l = ( a + 0.5 ) * 1000;
	n = (n >= l) ? ((a + 1) * 1000) : (a * 1000);
	return( n );
}

# Controls
# ---------------------------------------------------------------------
var toggle_radar_standby = func() {
	if ( pilot_lock and ! we_are_bs ) { return }
    var nv = RadarStandby.getIntValue() + 1;
    if (nv > 3) nv = 0;
	RadarStandby.setBoolValue(nv);
}

var range_control = func(n) {
	# 1(+), -1(-), 5, 10, 20, 50, 100, 200
	if ( pilot_lock and ! we_are_bs ) { return }
	var range_radar = RangeRadar2.getValue();
	if ( n == 1 ) {
		if ( range_radar == 10 ) { range_radar = 20 }
		elsif ( range_radar == 20 ) { range_radar = 40 }
		elsif ( range_radar == 40 ) { range_radar = 80 }
		elsif ( range_radar == 80 ) { range_radar = 160 }
	} elsif (n == -1 ) {
		if ( range_radar == 160 ) { range_radar = 80 }
		elsif ( range_radar == 80 ) { range_radar = 40 }
		elsif ( range_radar == 40 ) { range_radar = 20 }
		elsif ( range_radar == 20 ) { range_radar = 10 }
	} elsif (n == 10 ) { range_radar = 10 }
	elsif (n == 20 ) { range_radar = 20 }
	elsif (n == 40 ) { range_radar = 40 }
	elsif (n == 80 ) { range_radar = 80 }
	elsif (n == 160 ) { range_radar = 160 }
	RangeRadar2.setValue(range_radar);
    screen.log.write("Radar range "~range_radar~" NM", 0.5, 0.5, 1);
}

wcs_mode_sel = func(mode) {
	if ( pilot_lock and ! we_are_bs ) { return }
	foreach (var n; props.globals.getNode("sim/model/f16/instrumentation/radar-awg-9/wcs-mode").getChildren()) {
		n.setBoolValue(n.getName() == mode);
		wcs_mode = mode;
	}
	if ( wcs_mode == "pulse-srch" ) {
		AzField.setValue(120);
		ddd_screen_width = 0.0844;
	} else {
		AzField.setValue(60);
		ddd_screen_width = 0.0422;
	}
}

wcs_mode_toggle = func() {
	# Temporarely toggles between the first 2 available modes.
	#foreach (var n; props.globals.getNode("sim/model/f16/instrumentation/radar-awg-9/wcs-mode").getChildren()) {
	if ( pilot_lock and ! we_are_bs ) { return }
	foreach (var n; WcsMode.getChildren()) {
		if ( n.getBoolValue() ) { wcs_mode = n.getName() }
	}
	if ( wcs_mode == "pulse-srch" ) {
		WcsMode.getNode("pulse-srch").setBoolValue(0);
		WcsMode.getNode("tws-auto").setBoolValue(1);
		wcs_mode = "tws-auto";
		AzField.setValue(60);
		ddd_screen_width = 0.0422;
	} elsif ( wcs_mode == "tws-auto" ) {
		WcsMode.getNode("pulse-srch").setBoolValue(1);
		WcsMode.getNode("tws-auto").setBoolValue(0);
		wcs_mode = "pulse-srch";
		AzField.setValue(120);
		ddd_screen_width = 0.0844;
	}
}

wcs_mode_update = func() {
	# Used on pilot's side when WcsMode is updated by the back-seater.
	foreach (var n; WcsMode.getChildren()) {
		if ( n.getBoolValue() ) { wcs_mode = n.getName() }
	}
	if ( WcsMode.getNode("tws-auto").getBoolValue() ) {
		wcs_mode = "tws-auto";
		AzField.setValue(60);
		ddd_screen_width = 0.0422;
	} elsif ( WcsMode.getNode("pulse-srch").getBoolValue() ) {
		wcs_mode = "pulse-srch";
		AzField.setValue(120);
		ddd_screen_width = 0.0844;
	}

}


# Target class
# ---------------------------------------------------------------------
var Target = {
	new : func (c) {
		var obj = { parents : [Target]};
		obj.RdrProp = c.getNode("radar");
		obj.Heading = c.getNode("orientation/true-heading-deg");
        obj.ptch = c.getNode("orientation/pitch-deg");
        obj.rll = c.getNode("orientation/roll-deg");
		obj.Alt = c.getNode("position/altitude-ft");
		obj.AcType = c.getNode("sim/model/ac-type");
		obj.type = c.getName();
		obj.Valid = c.getNode("valid");
		obj.Callsign = c.getNode("callsign");
        obj.TAS = c.getNode("velocities/true-airspeed-kt");

        if (obj.Callsign == nil or obj.Callsign.getValue() == "")
        {
            var signNode = c.getNode("sign");
            if (signNode != nil)
                obj.Callsign = signNode;
        }


        obj.Model = c.getNode("model-short");
        var model_short = c.getNode("sim/model/path");
        if(model_short != nil)
        {
            var model_short_val = model_short.getValue();
            if (model_short_val != nil and model_short_val != "")
            {
                var u = split("/", model_short_val); # give array
                var s = size(u); # how many elements in array
                var o = u[s-1];	 # the last element
                var m = size(o); # how long is this string in the last element
                var e = m - 4;   # - 4 chars .xml
                obj.ModelType = substr(o, 0, e); # the string without .xml
            } else {
                obj.ModelType = "";
            }
        } elsif (c.getNode("type") != nil) {
            obj.ModelType = c.getNode("type").getValue();
            if (obj.ModelType == nil) {obj.ModelType = "";}
        } else {
            obj.ModelType = "";
        }

		obj.index = c.getIndex();
		obj.string = "ai/models/" ~ obj.type ~ "[" ~ obj.index ~ "]";
		obj.shortstring = obj.type ~ "[" ~ obj.index ~ "]";
        obj.propNode = c;
        obj.TgTCoord  = geo.Coord.new();
        if (c.getNode("position/latitude-deg") != nil and c.getNode("position/longitude-deg") != nil) {
            obj.lat = c.getNode("position/latitude-deg");
            obj.lon = c.getNode("position/longitude-deg");
        } else {
            obj.lat = nil;
            if (c.getNode("position/global-x") != nil)
            {
                obj.x = me.propNode.getNode("position/global-x");
                obj.y = me.propNode.getNode("position/global-y");
                obj.z = me.propNode.getNode("position/global-z");
            } else {
                obj.x = nil;
            }
        }
 
        if (obj.type == "multiplayer" or obj.type == "tanker" or obj.type == "aircraft" and obj.RdrProp != nil) 
            obj.airbone = 1;
        else
            obj.airbone = 0;
#        var pos = geo.Coord.new(); # FIXME: all of these should be instance variables
#        obj.Position.set_latlon( lat,lon);

#		obj.Callsign = getprop(obj.string~"/callsign");
#print("callsign ",obj.Callsign.getValue());
		
		# Remote back-seaters shall not emit and shall be invisible. FIXME: This is going to be handled by radardist ASAP.
		obj.not_acting = 0;
		var Remote_Bs_String = c.getNode("sim/multiplay/generic/string[1]");
		if ( Remote_Bs_String != nil ) {
			var rbs = Remote_Bs_String.getValue();
			if ( rbs != nil ) {
				var l = split(";", rbs);
				if ( size(l) > 0 ) {
					if ( l[0] == "f16-bs" ) {
						obj.not_acting = 1;
					}
				}
			}
		}

		# Local back-seater has a different radar-awg-9 folder and shall not see its pilot's aircraft.
		var bs = getprop("sim/aircraft");
		obj.InstrTgts = props.globals.getNode("sim/model/f16/instrumentation/radar-awg-9/targets", 1);
		if ( bs == "f16-bs") {
			if  ( BS_instruments.Pilot != nil ) {
				# Use a different radar-awg-9 folder.
				obj.InstrTgts = BS_instruments.Pilot.getNode("sim/model/f16/instrumentation/radar-awg-9/targets", 1);
				# Do not see our pilot's aircraft.
				var target_callsign = obj.Callsign.getValue();
				var p_callsign = BS_instruments.Pilot.getNode("callsign").getValue();
				if ( target_callsign == p_callsign ) {
					obj.not_acting = 1;
				}
			}
		}	

		obj.TgtsFiles = obj.InstrTgts.getNode(obj.shortstring, 1);
        if (obj.RdrProp != nil)
		{
            obj.Range          = obj.RdrProp.getNode("range-nm");
            obj.Bearing        = obj.RdrProp.getNode("bearing-deg");
            obj.Elevation      = obj.RdrProp.getNode("elevation-deg");
            obj.TotalElevation = obj.RdrProp.getNode("total-elevation-deg", 1);
        }
        else
        {
            obj.Range          = nil;
            obj.Bearing        = nil;
            obj.Elevation      = nil;
            obj.TotalElevation = nil;
        }

        if (obj.TgtsFiles != nil)
        {
            obj.BBearing       = obj.TgtsFiles.getNode("bearing-deg", 1);
            obj.BHeading       = obj.TgtsFiles.getNode("true-heading-deg", 1);
            obj.RangeScore     = obj.TgtsFiles.getNode("range-score", 1);
            obj.RelBearing     = obj.TgtsFiles.getNode("ddd-relative-bearing", 1);
            obj.Carrier        = obj.TgtsFiles.getNode("carrier", 1);
            obj.EcmSignal      = obj.TgtsFiles.getNode("ecm-signal", 1);
            obj.EcmSignalNorm  = obj.TgtsFiles.getNode("ecm-signal-norm", 1);
            obj.EcmTypeNum     = obj.TgtsFiles.getNode("ecm_type_num", 1);
            obj.Display        = obj.TgtsFiles.getNode("display", 1);
            obj.Display.setValue(0);
            obj.Fading         = obj.TgtsFiles.getNode("ddd-echo-fading", 1);
            obj.DddDrawRangeNm = obj.TgtsFiles.getNode("ddd-draw-range-nm", 1);
            obj.TidDrawRangeNm = obj.TgtsFiles.getNode("tid-draw-range-nm", 1);
            obj.RoundedAlt     = obj.TgtsFiles.getNode("rounded-alt-ft", 1);
            obj.TimeLast       = obj.TgtsFiles.getNode("closure-last-time", 1);
            obj.RangeLast      = obj.TgtsFiles.getNode("closure-last-range-nm", 1);
            obj.ClosureRate    = obj.TgtsFiles.getNode("closure-rate-kts", 1);
        }
		obj.TimeLast.setValue(ElapsedSec.getValue());
        var cur_range = obj.get_range();
        if (cur_range != nil and obj.RangeLast != nil)
		    obj.RangeLast.setValue(obj.get_range());
		# Radar emission status for other users of radar2.nas.
		obj.RadarStandby = c.getNode("sim/multiplay/generic/int[2]");

		obj.deviation = nil;

        obj.Model = c.getNode("model-short");
        var model_short = c.getNode("sim/model/path");
        if(model_short != nil)
        {
            var model_short_val = model_short.getValue();
            if (model_short_val != nil and model_short_val != "")
            {
                var u = split("/", model_short_val); # give array
                var s = size(u); # how many elements in array
                var o = u[s-1];  # the last element
                var m = size(o); # how long is this string in the last element
                var e = m - 4;   # - 4 chars .xml
                obj.ModelType = substr(o, 0, e); # the string without .xml
            }
            else
                obj.ModelType = "";
        }

		return obj;
	},
    isValid: func{return me.Valid.getValue();},
    getUnique: func{return me.get_Callsign();},
    get_Callsign: func{
        if (me.Callsign == nil) {
            return me.get_model();
        }
        return me.Callsign.getValue();
    },
    getElevation: func{return me.Elevation.getValue();},
    getFlareNode: func () {
      return me.propNode.getNode("rotors/main/blade[3]/flap-deg");
    },

    getChaffNode: func () {
      return me.propNode.getNode("rotors/main/blade[3]/position-deg");
    },
    get_type: func{return 0;},
    isPainted: func{return 1;},
    get_Pitch: func{return me.ptch.getValue();},
    get_Roll: func{return me.rll.getValue();},
    get_Speed: func{return me.get_TAS();},
    get_model: func {
        return me.ModelType;
    },
	get_heading : func {
		var n = me.Heading.getValue();
        if (n != nil)
		    me.BHeading.setValue(n);
		return n;	},
	get_bearing: func(){
        var n = nil;
        if (me.Bearing != nil) {
            n = me.Bearing.getValue();
        }
        if(n == nil) {
            # AI/MP has no radar properties
            n = me.get_bearing_from_Coord(geo.aircraft_position());
        }
        return n;
    },
    get_bearing_from_Coord: func(MyAircraftCoord){
        me.get_Coord();
        var myBearing = 0;
        if(me.coord.is_defined()) {
            myBearing = MyAircraftCoord.course_to(me.coord);
        }
        return myBearing;
    },
	set_relative_bearing : func(n) {
		me.RelBearing.setValue(n);
	},
	get_relative_bearing : func() {
        return me.get_bearing()-getprop("orientation/heading-deg");
		return me.RelBearing.getValue();
	},
	get_reciprocal_bearing : func {
		return geo.normdeg(me.get_bearing() + 180);
	},
	get_deviation : func(true_heading_ref) {
		me.deviation =  - deviation_normdeg(true_heading_ref, me.get_bearing());
		return me.deviation;
	},
	get_altitude : func {
		return me.Alt.getValue();
	},
	get_total_elevation : func(own_pitch) {
		me.deviation =  - deviation_normdeg(own_pitch, me.Elevation.getValue());
		me.TotalElevation.setValue(me.deviation);
		return me.deviation;
	},
	get_range : func {
        #
        # range on carriers (and possibly other items) is always 0 so recalc.
        if (me.Range == nil or me.Range.getValue() == 0)
        {
            if (me.propNode.getNode("position/global-x") != nil)
            {
                var x = me.propNode.getNode("position/global-x").getValue();
                var y = me.propNode.getNode("position/global-y").getValue();
                var z = me.propNode.getNode("position/global-z").getValue();

                var tgt_pos = geo.Coord.new().set_xyz(x, y, z);
#                print("Recalc range - ",tgt_pos.distance_to(geo.aircraft_position()));
                return tgt_pos.distance_to(geo.aircraft_position()) * 0.000539957; # distance in NM
            }
            if (me.Range != nil)
                return me.Range.getValue();
        }
        if (me.Range == nil)
            return 0;
        else
            return me.Range.getValue();
	},
	get_horizon : func(own_alt) {
		var tgt_alt = me.get_altitude();
		if ( tgt_alt != nil ) {
			if ( own_alt < 0 ) { own_alt = 0.001 }
			if ( debug.isnan(tgt_alt)) {
				print("####### nan ########");
				return(0);
			}
			if ( tgt_alt < 0 ) { tgt_alt = 0.001 }
			return radardist.radar_horizon( own_alt, tgt_alt );
		}
			return(0);
	},
	check_carrier_type : func {
		var type = "none";
		var carrier = 0;
		if ( me.AcType != nil ) { type = me.AcType.getValue() }
		if ( type == "MP-Nimitz" or type == "MP-Eisenhower" or type == "MP-Vinson" ) { carrier = 1 }
		me.Carrier.setBoolValue(carrier);
		return carrier;
	},
	get_rdr_standby : func {
		# FIXME: this one shouldn't be part of Target
		var s = 0;
		if ( me.RadarStandby != nil ) {
			s = me.RadarStandby.getValue();
			if (s == nil) { s = 0 } elsif (s != 1) { s = 0 }
		}
		return s;
	},
	get_display : func() {
		return me.Display.getValue();
	},
	set_display : func(n) {
		me.Display.setBoolValue(n);
	},
	get_fading : func() {
		var fading = me.Fading.getValue(); 
		if ( fading == nil ) { fading = 0 }
		return fading;
	},
	set_fading : func(n) {
		me.Fading.setValue(n);
	},
	set_ddd_draw_range_nm : func(n) {
		me.DddDrawRangeNm.setValue(n);
	},
	set_hud_draw_horiz_dev : func(n) {
		me.HudDrawHorizDev.setValue(n);
	},
	set_tid_draw_range_nm : func(n) {
		me.TidDrawRangeNm.setValue(n);
	},
	set_rounded_alt : func(n) {
		me.RoundedAlt.setValue(n);
	},
    get_TAS: func(){
        if (me.TAS != nil)
        {
            return me.TAS.getValue();
        }
        return 0;
    },
    get_Coord: func(){
        if (me.lat != nil) {
            me.TgTCoord.set_latlon(me.lat.getValue(), me.lon.getValue(), me.Alt.getValue() * FT2M);
        } else {
            if (me.x != nil)
            {
                var x = me.x.getValue();
                var y = me.y.getValue();
                var z = me.z.getValue();

                me.TgTCoord.set_xyz(x, y, z);
            } else {
                return nil;#hopefully wont happen
            }
        }
        return geo.Coord.new(me.TgTCoord);#best to pass a copy
    },

	get_closure_rate : func() {
        #
        # calc closure using trig as the elapsed time method is not really accurate enough and jitters considerably
        if (me.TAS != nil)
        {
            var tas = me.TAS.getValue();
            var our_hdg = getprop("orientation/heading-deg");
            if(our_hdg != nil)
            {
                var myCoord = me.get_Coord();
                var bearing = 0;
                if(myCoord.is_defined())
                {
                    bearing = geo.aircraft_position().course_to(myCoord);
                    bearing_ = myCoord.course_to(geo.aircraft_position());
                }
                var vtrue_kts = getprop("fdm/jsbsim/velocities/vtrue-kts");
                if (vtrue_kts != nil)
                {
                    #
                    # Closure rate is a doppler thing. see figure 4 http://www.tscm.com/doppler.pdf
                    # closing velocity = OwnshipVelocity * cos(target_bearing) + TargetVelocity*cos(ownship_bearing);
                    var vec_ownship = vtrue_kts * math.cos( -(bearing - our_hdg) * D2R);
                    var vec_target = tas * math.cos( -(bearing_ - me.get_heading()) * D2R);
                    return vec_ownship+vec_target;
                }
            }
        }
        else
            print("NO TAS ",me.type," ",u.get_range(),u.Model, u.Callsign.getValue());
        return 0;
#
# this is the old way of calculating closure; it's wrong because this isn't what it actually is in
# radar terms.
		var dt = ElapsedSec.getValue() - me.TimeLast.getValue();
		var rng = me.Range.getValue();
		var lrng = me.RangeLast.getValue();
		if ( debug.isnan(rng) or debug.isnan(lrng)) {
			print("####### get_closure_rate(): rng or lrng = nan ########");
			me.ClosureRate.setValue(0);
			me.RangeLast.setValue(0);
			return(0);
		}
		var t_distance = lrng - rng;
		var	cr = (dt > 0) ? t_distance/dt*3600 : 0;
		me.ClosureRate.setValue(cr);
		me.RangeLast.setValue(rng);
		return(cr);
	},
	list : [],
};

# Notes:

# HUD field of view = 2 * math.atan2( 0.0764, 0.7186) * globals.R2D; # ~ 12.1375°
# where 0.071 : virtual screen half width, 0.7186 : distance eye -> screen

#
# This is the emesary recipient that will update the Radar when a FrameNotification is
# received.

var F16RadarRecipient = 
{
    new: func(_ident)
    {
        var new_class = emesary.Recipient.new(_ident~".RADAR");

        new_class.Receive = func(notification)
        {
            if (notification == nil)
            {
                print("bad notification nil");
                return emesary.Transmitter.ReceiptStatus_NotProcessed;
            }

            if (notification.NotificationType == "FrameNotification")
            {
                # Main loop ###############
                # Done each 0.05 sec. Called from instruments.nas
                var display_rdr = DisplayRdr.getBoolValue();
                if ( display_rdr )
                {
                    az_scan();
                    our_radar_stanby = RadarStandby.getValue();
                    #print ("Display radar ",our_radar_stanby, we_are_bs);
                    if ( we_are_bs == 0)
                    {
                        # RadarStandbyMP.setIntValue(our_radar_stanby); # Tell over MP if
                        # our radar is scaning or is in stanby. Don't if we are a back-seater.
                    }
                }
                elsif ( size(tgts_list) > 0 )
                {
                    foreach ( u; tgts_list )
                      {
                        u.set_display(0);
                    }
                }
                return emesary.Transmitter.ReceiptStatus_OK;
            }
            return emesary.Transmitter.ReceiptStatus_NotProcessed;
        };
        return new_class;
    },
};

f16_radar = F16RadarRecipient.new("F16-RADAR");

emesary.GlobalTransmitter.Register(f16_radar);

completeList = [];
rwrList = [];

var rwrNew = func () {
    foreach(u;completeList) {
        if (getprop("link16/wingman-1")==u.get_Callsign() or getprop("link16/wingman-2")==u.get_Callsign() or getprop("link16/wingman-3")==u.get_Callsign()) {
            return;
        }
        var bearing = geo.aircraft_position().course_to(u.get_Coord());
        var trAct = u.propNode.getNode("instrumentation/transponder/transmitted-id");
        var show = 0;
        var heading = u.get_heading();  
        var inv_bearing =  bearing+180;
        var deviation = inv_bearing - heading;
        var dev = math.abs(geo.normdeg180(deviation));
        if (u.get_display()) {
            show = 1;#in radar cone
        } elsif(u.get_model()=="AI" and u.get_range() < 55) {
            show = 1;#non MP always has transponder on.
        } elsif (trAct != nil and trAct.getValue() != -9999 and u.get_range() < 55) {
          # transponder on
          show = 1;
        } else {
          var rdrAct = u.propNode.getNode("sim/multiplay/generic/int[2]");
          if (((rdrAct != nil and rdrAct.getValue()!=1) or rdrAct == nil) and math.abs(geo.normdeg180(deviation)) < 60) {
              # we detect its radar is pointed at us and active
              show = 1;
          }
        }
        if (show == 1) {
            var threat = 0;
            if (u.get_model() != "missile_frigate" and u.get_model() != "buk-m2") {
                threat += ((180-dev)/180)*0.30;
                var spd = (60-u.get_Speed())/60;
                threat -= spd>0?spd:0;
            } elsif (u.get_model == "missile_frigate") {
                threat += 0.30;
            } else {
                threat += 0.30;
            }
            var danger = u.get_model() == "missile_frigate"?75:(u.get_model() == "buk-m2"?35:50);
            threat += ((danger-u.get_range())/danger)>0?((danger-u.get_range())/danger)*0.60:0;
            var clo = u.get_closure_rate();
            threat += clo>0?(clo/500)*0.10:0;
            if (threat > 1) threat = 1;
            #printf("%s threat:%.2f range:%d dev:%d", u.get_Callsign(),threat,u.get_range(),dev);
            append(rwrList,[u,threat]);
        } else {
            #printf("%s ----", u.get_Callsign());
        }
    }
}