 #---------------------------------------------------------------------------
 #
 #	Title                : Radar simulation.
 #
 #	File Type            : Implementation File
 #
 #	Description          : A not very complex simulation of an AA or AG radar
 #                       : loosely based on the AN/APG-63 but doesn't use any sort of 
 #                       : actual radar beam processing instead
 #                       : elements of this are simulated in a different manner, e.g. terrain visibily, RCS
 #                       : be invoked in a controlled manner.
 #                       : RWR (Radar Warning Receiver) is computed in the radar loop for better performance
 #                       : AWG-9 Radar computes the nearest target for AIM-9.
 #                       : (F-14) Optionally provides the 'tuned carrier' tacan channel support for ARA-63 emulation
 #                       :
 #                       : This version is based on Richard's optimised, partioned version from the F-15 as of 09/2017
 #                       : the list of targets is only rebuilt when models are added and removed; which improves performance
 #                       : considerably. Also the update of the list is partitioned to minimise performance impact.
 #
 #	Authors              : Alexis Bory (original, F-14)
 #                       : Richard Harrison (richard@zaretto.com), modified F-14, base version for all of this (F-15)
 #                       : Fabien Barber
 #                       : Nikolai V. Chr
 #                       : Justin Nicholson
 #
 #	Date                 : 4 June 2018
 #
 #	Version              : 2.8b
 #
 #  Released under GPL V2
 #
 #---------------------------------------------------------------------------*/

var TRUE =1;
var FALSE=0;
var missiles_visible_on_radar = 0;

var AIR = 0;
var MARINE = 1;
var SURFACE = 2;
var ORDNANCE = 3;

var knownShips = {
    "missile_frigate":       nil,
    "frigate":       nil,
    "USS-LakeChamplain":     nil,
    "USS-NORMANDY":     nil,
    "USS-OliverPerry":     nil,
    "USS-SanAntonio":     nil,
};

var knownSurface = {
    "buk-m2":       nil,
    "depot":       nil,
    "truck":     nil,
    "tower":     nil,
};

var this_model = "f16";
var ownship_pos = geo.Coord.new();
var cockpitNotifier = nil;
var radar_ranges = [5,10,20,40,50,100,200];

#var this_model = "f15";
#var this_model = "f-14b";

var ElapsedSec        = props.globals.getNode("sim/time/elapsed-sec");
var SwpFac            = props.globals.getNode("sim/model/"~this_model~"/instrumentation/awg-9/sweep-factor", 1);
var DisplayRdr        = props.globals.getNode("sim/model/"~this_model~"/instrumentation/radar-awg-9/display-rdr",1);
var HudTgtHDisplay    = props.globals.getNode("sim/model/"~this_model~"/instrumentation/radar-awg-9/hud/target-display", 1);
var HudTgt            = props.globals.getNode("sim/model/"~this_model~"/instrumentation/radar-awg-9/hud/target", 1);
var HudTgtTDev        = props.globals.getNode("sim/model/"~this_model~"/instrumentation/radar-awg-9/hud/target-total-deviation", 1);
var HudTgtTDeg        = props.globals.getNode("sim/model/"~this_model~"/instrumentation/radar-awg-9/hud/target-total-angle", 1);
var HudTgtClosureRate = props.globals.getNode("sim/model/"~this_model~"/instrumentation/radar-awg-9/hud/closure-rate", 1);
var HudTgtDistance = props.globals.getNode("sim/model/"~this_model~"/instrumentation/radar-awg-9/hud/distance", 1);
var AzField           = props.globals.getNode("instrumentation/radar/az-field", 1);
var HoField           = props.globals.getNode("instrumentation/radar/ho-field", 1);
var RangeRadar2       = props.globals.getNode("instrumentation/radar/radar2-range",1);
var RadarStandby      = props.globals.getNode("instrumentation/radar/radar-standby",1);
var RadarStandbyMP    = props.globals.getNode("sim/multiplay/generic/int[2]",1);
var OurAlt            = props.globals.getNode("position/altitude-ft",1);
var OurHdg            = props.globals.getNode("orientation/heading-deg",1);
var OurRoll           = props.globals.getNode("orientation/roll-deg",1);
var OurPitch          = props.globals.getNode("orientation/pitch-deg",1);
var OurIAS            = props.globals.getNode("fdm/jsbsim/velocities/vtrue-kts",1);
var EcmOn             = props.globals.getNode("instrumentation/ecm/on-off", 1);
var WcsMode           = props.globals.getNode("sim/model/"~this_model~"/instrumentation/radar-awg-9/wcs-mode",1);
var SWTgtRange        = props.globals.getNode("sim/model/"~this_model~"/systems/armament/aim9/target-range-nm",1);
var RadarServicable   = props.globals.getNode("instrumentation/radar/serviceable",1);
var SelectTargetCommand =props.globals.getNode("sim/model/"~this_model~"/instrumentation/radar-awg-9/select-target",1);
var LaserArm          = props.globals.getNode("controls/armament/laser-arm-dmd",1);
var RefStrenght       = props.globals.getNode("instrumentation/radar/ref-strength",1);
var RefRange          = props.globals.getNode("instrumentation/radar/ref-range",1);
var LimitedSelect     = props.globals.getNode("instrumentation/radar/limited-select",1);


var myRadarStrength_rcs = getprop("instrumentation/radar/ref-strength");
var myRadarRange_rcs = getprop("instrumentation/radar/ref-range");

#var awg9_trace = 0;
var wcs_mode_pd_srch = 1;
var wcs_mode_pd_stt = 2;
var wcs_mode_pulse_srch = 3;
var wcs_mode_pulse_stt = 4;
var wcs_mode_rws = 5;
var wcs_mode_tws_auto = 6;
var wcs_mode_tws_man = 7;
var wcs_current_mode = wcs_mode_pulse_srch;

var completeList = [];

SelectTargetCommand.setIntValue(0);

# variables for the partioned scanning.
# - instead of building the entire list of potential returns (tgts_list) each frame
#   the list is only built when the something changes in the ai/models, by 
#   listening to the model-added and model-removed properties.
# - to improve the peformance further the visibility check is only performed every 10 seconds. This may seem slow but I don't think it
#   is unrealistic , especially during a hard turn; but realistically it will take a certain amount of time for the real radar to 
#   stabilise the returns. I don't have figures for this but it seems plausible that even when lined up with a return it could take
#   a good few seconds for the processing to find it. 
#   TODO: possibly reduce the scan_visibility_check_interval to a lower value
# - also once built the list of potential returns only has a chunk updated each frame, based on the scan_partition_size
#   so with a lot of targets it could take a number of seconds to update all of these, however it should be a reasonable optimisation

var scan_tgt_idx = 0;
var scan_hidden_by_rcs = 0;
var scan_hidden_by_radar_mode = 0;
var scan_hidden_by_terrain = 0;
var scan_visible_count = 0;

var scan_id = 0;
var scan_update_visibility = 1;
var scan_next_tgt_check = ElapsedSec.getValue() + 2;
var scan_update_tgt_list = 1;
var ScanPartitionSize = props.globals.getNode("instrumentation/radar/scan_partition_size", 1);
var ScanVisibilityCheckInterval = props.globals.getNode("instrumentation/radar/scan_partition_size", 1);
var ScanId = props.globals.getNode("instrumentation/radar/scan_id", 1);
var ScanTgtUpdateCount = props.globals.getNode("instrumentation/radar/scan_tgt_update", 1);
var ScanTgtCount = props.globals.getNode("instrumentation/radar/scan_tgt_count", 1);
var ScanTgtHiddenRCS = props.globals.getNode("instrumentation/radar/scan_tgt_hidden_rcs", 1);
var ScanTgtHiddenTERRAIN = props.globals.getNode("instrumentation/radar/scan_tgt_hidden_terrain", 1);
var ScanTgtVisible = props.globals.getNode("instrumentation/radar/scan_tgt_visible", 1);
ScanTgtUpdateCount.setIntValue(0);

ScanVisibilityCheckInterval.setIntValue(12); # seconds
ScanPartitionSize.setIntValue(10); # size of partition to run per frame.

# Azimuth field quadrants.
# 120 means +/-60, as seen in the diagram below.
#  _______________________________________
# |                   |                  |
# |               _.--+---.              |
# |           ,-''   0|    `--.          |
# |         ,'        |        `.        |
# |        /          |          \       |
# |    -60/'-.        |         _,\+60   |
# |      /    `-.     |     ,.-'   \     |
# |     ; -90    `-._ |_.-''      90     |
#....................::F..................
# |     :             |             ;    |
# |      \       TC   |            /     |
# |       \           |           /      |
# |        \          |          /       |
# |         `.   -180 | +180   ,'        |
# |           '--.    |    _.-'          |
# |               `---+--''              |
# |                   |                  |
#  `''''''''''''''''''|'''''''''''''''''''

# local variables related to the simulation of the radar.
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

var use_tews          = 1;#skips the TEWS code to save performance if 0

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
var stby = 0;

var cycle_range    = getprop("instrumentation/radar/cycle-range");# if range should be cycled or only go up/down.

var setupRanges = func {
    var rdrNode = props.globals.getNode("instrumentation/radar",0);
    var rangeNodes = rdrNode.getChildren("ranges");
    if (rangeNodes != nil and size(rangeNodes) > 0) {
        radar_ranges = [];
        foreach(rNode ; rangeNodes) {
            append(radar_ranges, rNode.getNode("entry").getValue());
        }
    }
};
setupRanges();

var versionString = getprop("sim/version/flightgear");
var version = split(".", versionString);
var major = num(version[0]);
var minor = num(version[1]);
var pica  = num(version[2]);
var pickingMethod = 0;
if ((major == 2017 and minor == 2 and pica >= 1) or (major == 2017 and minor > 2) or major > 2017) {
    pickingMethod = 1;
}
tgts_list = [];
completeList = [];

#
#
# use listeners to define when to update the radar return list.
setlistener("/ai/models/model-added", func(v){
    if (!scan_update_tgt_list) {
        scan_update_tgt_list = 1;
    }
});

setlistener("/ai/models/model-removed", func(v){
    if (!scan_update_tgt_list) {
        scan_update_tgt_list = 1;
    }
});

init = func() {
	var our_ac_name = getprop("sim/aircraft");
    # map variants to the base
    if(our_ac_name == "f-14a") our_ac_name = "f-14b";
    if(our_ac_name == "f15d") our_ac_name = "f15c";
	if (our_ac_name == "f-14b-bs") { we_are_bs = 1; }
	if (our_ac_name == "f15-bs") we_are_bs = 1;
    if (find("F-16", our_ac_name) != -1) { we_are_bs = 0; use_tews = 0; }

	my_radarcorr = radardist.my_maxrange( our_ac_name ); # in kilometers
}

# Radar main processing entry point
# Run at 20hz - invoked from main loop in instruments.nas
var rdr_loop = func(notification) {
if (notification["ownship_pos"] == nil)
  {
print("Radar: disabled as no ownship position");
return;
}

#    if (noti.FrameCount != 0) {
#        return;
#    }
#    if (doRWR) {
#        selectCheck();# for it to be responsive have to do this more often than running radar code.
#    }
	var display_rdr = DisplayRdr.getBoolValue();

	if ( display_rdr and RadarServicable.getValue() == 1) {
        ownship_pos = notification.ownship_pos;
		az_scan(notification);
		our_radar_stanby = RadarStandby.getValue();
		if ( we_are_bs == 0) {
			RadarStandbyMP.setIntValue(our_radar_stanby); # Tell over MP if
			# our radar is scaning or is in stanby. Don't if we are a back-seater.
		}
	} elsif ( size(tgts_list) > 0 ) {
		foreach( u; tgts_list ) {
			u.set_display(0);
		}
        armament.contact = nil;
	}
}

var sweep_frame_inc = 0.2;
var az_scan = func(notification) {
    cnt += sweep_frame_inc;

	# Antena az scan. Angular speed is constant but angle covered varies (120 or 60 deg ATM).
	var fld_frac = az_fld / 120;                    # the screen (and the max scan angle) covers 120 deg, but we may use less (az_fld).
	var fswp_spd = swp_spd / fld_frac;              # So the duration (fswp_spd) of a complete scan will depend on the fraction we use.
    var rwr_done = 0;
	swp_fac = math.sin(cnt * fswp_spd) * fld_frac;  # Build a sinusoude, each step based on a counter incremented by the main UPDATE_PERIOD
	SwpFac.setValue(swp_fac);                       # Update this value on the property tree so we can use it for the sweep line animation.
	swp_deg = az_fld / 2 * swp_fac;                 # Now get the actual deviation of the antenae in deg,
	swp_dir = swp_deg < swp_deg_last ? 0 : 1;       # and the direction.
	#if ( az_fld == nil ) { az_fld = 74 } # commented 20110911 if really needed it shouls had been on top of the func.
	l_az_fld = - az_fld / 2;
	r_az_fld = az_fld / 2;

	var fading_speed = 0.015;   # Used for the screen animation, dots get bright when the sweep line goes over, then fade.

    notification.tgt_list = tgts_list;
    notification.completeList = completeList;

	our_true_heading = OurHdg.getValue();
	our_alt = OurAlt.getValue();

    var radar_active = 1;
    var radar_mode = getprop("instrumentation/radar/radar-mode");
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

    range_radar2 = RangeRadar2.getValue();
    
    if (1==1 or swp_dir != swp_dir_last)
    {
		# Antena scan direction change (at max: more or less every 2 seconds). Reads the whole MP_list.
		# TODO: Visual glitch on the screen: the sweep line jumps when changing az scan field.

		az_fld = AzField.getValue();
		if ( range_radar2 == 0 ) { range_radar2 = 0.00000001 }

		# Reset nearest_range score
		nearest_u = tmp_nearest_u;
		nearest_rng = tmp_nearest_rng;
		tmp_nearest_rng = nil;
		tmp_nearest_u = nil;

        if (scan_update_tgt_list)
        {
            scan_update_tgt_list=0;
            tgts_list = [];
            var raw_list = Mp.getChildren();
            var carrier_located = 0;

            if (active_u == nil or active_u.Callsign == nil or active_u.Callsign.getValue() == nil or active_u.Callsign.getValue() != active_u_callsign)
            {
                if (active_u != nil)
                    active_u = nil;
                armament.contact = active_u;
            }

            foreach( var c; raw_list )
            {
                var type = c.getName();

                if (c.getNode("valid") == nil or !c.getNode("valid").getValue()) {
                    continue;
                }
                var ordnance = 1;
                if (c.getNode("missile") == nil or !c.getNode("missile").getValue()) {
                    # a little superflous atm. since the typecheck below will filter out ordnance. Their type look like: aim-9 or agm-88 etc etc.
                    ordnance = 0;
                }
                if (type == "multiplayer" or type == "tanker" or type == "aircraft" or type == "carrier"
                    or type == "ship" or type == "groundvehicle") 
                {
                    #var new_tgt = Target.new(c);# Richard, what is this for? Its important that every target that goes into completelist gets the setClass() called..
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
                    if (ordnance) {
                        u.setClass(ORDNANCE);
                    } elsif (type == "tanker" or type == "aircraft") {
                        u.setClass(AIR);
                    } elsif (type=="carrier") {
                        u.setClass(MARINE);
                    } elsif (type=="groundvehicle") {
                        u.setClass(SURFACE);
                    } else {
                        # multiplayer or ship:
                        var mdl = u.get_model();
                        if (contains(knownSurface,mdl)) {
                            u.setClass(SURFACE);
                        } elsif (contains(knownShips,mdl)) {
                            u.setClass(MARINE);
                        } elsif (u.get_altitude() < 5) {
                            u.setClass(MARINE);
                        } elsif (u.get_Speed() < 60) {
                            u.setClass(SURFACE);
                        }
                        # notice the default class is set to AIR
                    }
                    append(tgts_list, u);
                }
            }
            scan_tgt_idx = 0;
            scan_update_visibility = 1;
            ScanTgtUpdateCount.setIntValue(ScanTgtUpdateCount.getValue()+1);
            ScanTgtCount.setIntValue(size(tgts_list));
            tgts_list = sort (tgts_list, func (a,b) {a.get_range()-b.get_range()});
			completeList = tgts_list;

        }
    }
    var idx = 0;

    notification.tgt_list = tgts_list;
    notification.completeList = completeList;

    notification.active_u = active_u;
    u_ecm_signal      = 0;
    u_ecm_signal_norm = 0;
    u_radar_standby   = 0;
    u_ecm_type_num    = 0;
    
    if (scan_tgt_idx >= size(tgts_list)) {
        scan_tgt_idx = 0;
        scan_id += 1;
        ScanId.setIntValue(scan_id);

        if (scan_update_visibility) {
            scan_update_visibility = 0;
        } else if (ElapsedSec.getValue() > scan_next_tgt_check) {
            scan_next_tgt_check = ElapsedSec.getValue()  + ScanVisibilityCheckInterval.getValue();
            scan_update_visibility = 1;
        }

        #
        # clear the values ready for the new scan
        u_ecm_signal      = 0;
        u_ecm_signal_norm = 0;
        u_radar_standby   = 0;
        u_ecm_type_num    = 0;
    }

    scan_tgt_end = scan_tgt_idx + ScanPartitionSize.getValue();

    if (scan_tgt_end >= size(tgts_list))
    {
        scan_tgt_end = size(tgts_list);
    }
    var silentChanged = RadarStandby.getValue() != stby;# we keep track of silent mode, to make sure there is no delay for the pilot to see, when radar is turned on/off.
    stby = RadarStandby.getValue();
    for (;scan_tgt_idx < scan_tgt_end; scan_tgt_idx += 1) {

        u = tgts_list[scan_tgt_idx];

		var u_display = 0;
		var u_fading = u.get_fading() - fading_speed;
        var u_rng = u.get_range();
        ecm_on = EcmOn.getValue();

        if (scan_update_visibility or silentChanged) {

            # check for visible by radar taking into account RCS, based on AWG-9 = 89NM for 3.2 rcs (guesstimate)
            # also then check to see if behind terrain.
            # - this test is more costly than the RCS check so perform that first.
            # for both of these tests the result is to set the target as not visible.
            # and simply continue with the rest of the loop.
            # we don't check our radar range here because the scan update visibility is
            # called infrequently so the list must not take into account something that may
           # change between invocations of the update.
            u.set_behind_terrain(0);
#var msg = "";
#pickingMethod = 0;
#var v1 = TerrainManager.IsVisible(u.propNode,notification);
#pickingMethod = 1;
#var v2 = TerrainManager.IsVisible(u.propNode,notification);
            if (rcs.isInRadarRange(u, myRadarRange_rcs, myRadarStrength_rcs) == 0) {
                u.set_display(0);
                u.set_visible(0);
                scan_hidden_by_rcs += 1;
#msg = "out of rcs range";
            } else if (TerrainManager.IsVisible(u.propNode,notification) == 0) {
#msg = "behind terrain";
                u.set_behind_terrain(1);
                u.set_display(0);
                u.set_visible(0);
                scan_hidden_by_terrain += 1;
            } else {
#msg = "visible";
                scan_visible_count = scan_visible_count+1;
                u.set_visible(1);
                if (u_rng != nil and (u_rng > range_radar2))
                  u.set_display(0);
                else {
                  if (radar_mode == 2) {
#msg = msg ~ " in stby";
                      u.set_display(!u.get_rdr_standby());
                  }
                  if (radar_mode < 2) {
                    u.set_display(!RadarStandby.getValue());## Richard this hack by me you probably wanna clean up, had to make it for now to get f16 to behave.
                    #printf("Hiding %d %s", !RadarStandby.getValue(), u.get_Callsign());
                  } else {
#msg = "radar not transmitting";
                      u.set_display(0);
                  }
              }
            }
#if(awg9_trace)
#    print("UPDS: ",u.Callsign.getValue(),", ", msg, "vis= ",u.get_visible(), " dis=",u.get_display(), " rng=",u_rng, " rr=",range_radar2);
        }
#        else {
#
#            if (u_rng != nil and (u_rng > range_radar2)) {
#                tgts_list[scan_tgt_idx].set_display(0);
## still need to test for RWR warning indication even if outside of the radar range
#                if ( !rwr_done and ecm_on and tgts_list[scan_tgt_idx].get_rdr_standby() == 0) {
#                    rwr_done = rwr_warning_indication(tgts_list[scan_tgt_idx]); 
#                }
#                break;
#            }
#        }
# end of scan update visibility

# if target within radar range, and not acting (i.e. a RIO/backseat/copilot)
        if (u_rng != nil and (u_rng < range_radar2  and u.not_acting == 0 )) {
            u.get_deviation(our_true_heading);
            u.get_total_elevation(OurPitch.getValue());

            if (rcs.isInRadarRange(u, myRadarRange_rcs, myRadarStrength_rcs) == 0) {
#                if(awg9_trace)
#                  print(scan_tgt_idx,";",u.get_Callsign()," not visible by rcs");
                u.set_display(0);
                u.set_visible(0);
            }
            else{
#                if(awg9_trace)
#                  print(scan_tgt_idx,";",u.get_Callsign()," visible by rcs+++++++++++++++++++");
                u.set_visible(!u.get_behind_terrain());
            }
#
#
#
#
#
#0;MP1 within  azimuth 49.52579977807609 field=-60->60
#1;MP2 within  azimuth 126.4171942282486 field=-60->60
#1;MP2 within  azimuth -130.0592982116802 field=-60->60  (s->w quadrant)
#0;MP1 within  azimuth 164.2283073827575 field=-60->60
            if (radar_mode < 2 and math.abs(u.deviationA) < az_fld/2 and math.abs(u.deviationE) < HoField.getValue()/2) {#richard, I had to fix 2 bugs here.
                u.set_display(u.get_visible() and !RadarStandby.getValue() and u.get_type() != ORDNANCE);
#                if(awg9_trace)
#                  print(scan_tgt_idx,";",u.get_Callsign()," within  azimuth ",u.deviation," field=",l_az_fld,"->",r_az_fld);
            }
            else {
#                if(awg9_trace)
#                  print(scan_tgt_idx,";",u.get_Callsign()," out of azimuth ",u.deviation," field=",l_az_fld,"->",r_az_fld);
                u.set_display(0);
            }
        } else {
            u.set_display(0);#richard, I added this line.
        }

# RWR 
        compute_rwr(radar_mode, u, u_rng);
        # Test if target has a radar. Compute if we are illuminated. This propery used by ECM
        # over MP, should be standardized, like "ai/models/multiplayer[0]/radar/radar-standby".
        if ( !rwr_done and ecm_on and u.get_rdr_standby() == 0) {
           rwr_done = rwr_warning_indication(u);             # TODO: override display when alert.
        }

        #
        # if not displayed then we can continue to the next in the list.
        if (!u.get_display())
          continue;

        if ( u_fading < 0 ) {
            u_fading = 0;
        }

        if (u.get_display() == 1) #( swp_dir and swp_deg_last < u.deviation and u.deviation <= swp_deg )
          #or ( ! swp_dir and swp_deg <= u.deviation and u.deviation < swp_deg_last ))
          {
              u.get_bearing();
              u.get_heading();
              var horizon = u.get_horizon( our_alt );
              var u_rng = u.get_range();

              #Leto: commented out for OPRF due to that list not being up to date, and plane has no doppler effect, so should see targets below horizon:
              #if ( u_rng < horizon and radardist.radis(u.string, my_radarcorr))  
              if (1==1) {

                  # Compute mp position in our DDD display. (Bearing/horizontal + Range/Vertical).
                  u.set_relative_bearing( ddd_screen_width / az_fld * u.deviationA );
                  var factor_range_radar = 0.0657 / range_radar2; # 0.0657m : length of the distance range on the DDD screen.
                  u.set_ddd_draw_range_nm( factor_range_radar * u_rng );
                  u_fading = 1;
                  u_display = 1;

                  # Compute mp position in our TID display. (PPI like display, normaly targets are displayed only when locked.)
                  factor_range_radar = 0.15 / range_radar2; # 0.15m : length of the radius range on the TID screen.
                  u.set_tid_draw_range_nm( factor_range_radar * u_rng );

                  # Compute first digit of mp altitude rounded to nearest thousand. (labels).
                  u.set_rounded_alt( rounding1000( u.get_altitude() ) / 1000 );

                  # Compute closure rate in Kts.
                  u.get_closure_rate();

                  #
                  # ensure that the currently selected target
                  # remains the active one.
                  var callsign="**";

                  if (u.Callsign != nil)
                    callsign=u.Callsign.getValue();

                  if (u.airbone) {
                      if (active_u_callsign != nil and u.Callsign != nil and u.Callsign.getValue() == active_u_callsign) {
                          active_u = u; armament.contact = active_u;
                      }
                  }
                  idx=idx+1;
                  # Check if u = nearest echo.
                  if ( u_rng != 0 and (tmp_nearest_rng == nil or u_rng < tmp_nearest_rng)) {
                      if (u.airbone) {
                          tmp_nearest_u = u;
                          tmp_nearest_rng = u_rng;
                      }
                  }
              }
          }
        u.set_fading(u_fading);

        if (active_u != nil) {
            tmp_nearest_u = active_u;
        }
    }


    # if this is true then we have finished a complete scan; so 
    # update anything that requires this.
    if (scan_tgt_idx >= size(tgts_list)) {

        if (scan_update_visibility) {
            #
            # put some stats in the property tree.
            ScanTgtHiddenRCS.setIntValue(scan_hidden_by_rcs);
            ScanTgtHiddenTERRAIN.setIntValue(scan_hidden_by_terrain);
            ScanTgtVisible.setIntValue(scan_visible_count);

            scan_hidden_by_rcs = 0;
            scan_hidden_by_terrain = 0;
            scan_visible_count = 0;
            scan_hidden_by_radar_mode = 0;
        }

        # Summarize ECM alerts.
        # - this logic is to avoid the ECM alert flashing
        if ( ecm_alert1 == 0 and ecm_alert1_last == 0 ) { 
            EcmAlert1.setBoolValue(0)
        }
        if ( ecm_alert2 == 0 and ecm_alert1_last == 0 ) { 
            EcmAlert2.setBoolValue(0) 
        }
        ecm_alert1_last = ecm_alert1; # And avoid alert blinking at each loop.
        ecm_alert2_last = ecm_alert2;
        ecm_alert1 = 0;
        ecm_alert2 = 0;
    }
    selectCheck();

	swp_deg_last = swp_deg;
	swp_dir_last = swp_dir;

    # finally ensure that the active target is still in the targets list.
    if (!containsV(tgts_list, active_u)) {
        active_u = nil; armament.contact = active_u;
    }
}

#setprop("sim/mul"~"tiplay/gen"~"eric/strin"~"g[14]", "o"~""~"7");

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

var selectCheck = func {
    #
    #
    # next / previous target selection. 
    if (LimitedSelect.getValue()) {selectCheckLimited(); return;}# I could not get your selectcheck to behave like I liked. So I made a more restrictive check. And made a property that decide which check to use.
    var tgt_cmd = SelectTargetCommand.getValue();
    SelectTargetCommand.setIntValue(0);

    if (tgt_cmd != nil)
    {
        if (tgt_cmd > 0)
            sel_next_target=1;
        else if (tgt_cmd < 0)
            sel_prev_target=1;
    }

    if (sel_prev_target)
    {
        var dist  = 0;
        if (active_u != nil)
            dist = active_u.get_range();

        var prv=nil;

        foreach (var u; tgts_list) 
        {
            if(u.Callsign.getValue() == active_u_callsign)
                break;

            if(u.get_display() == 1)
            {
                prv = u;
            }
        }

        if (prv == nil)
        {
            var passed = 0;
            foreach (var u; tgts_list) 
            {
                if(passed == 1 and u.get_display() == 1)
                    prv = u;
                if(u.Callsign.getValue() == active_u_callsign)
                    passed = 1;
            }
        }

        if (prv != nil)
        {
            active_u = nearest_u = tmp_nearest_u = prv; armament.contact = active_u;

            if (tmp_nearest_u.Callsign != nil)
                active_u_callsign = tmp_nearest_u.Callsign.getValue();
            else
                active_u_callsign = nil;
                
        }
        sel_prev_target =0;
    }
    else if (sel_next_target)
    {
        var dist  = 0;

        if (active_u != nil)
        {
            dist = active_u.get_range();
        }

        var nxt=nil;
        var passed = 0;
        foreach (var u; tgts_list) 
        {
            if(u.Callsign.getValue() == active_u_callsign)
            {
                passed = 1;
                continue;
            }

            if((passed == 1 or dist == 0) and u.get_display() == 1)
            {
                nxt = u;
                break;
            }
        }
        if (nxt == nil)
        {
            foreach (var u; tgts_list) 
            {
                if(u.Callsign.getValue() == active_u_callsign)
                {
                    continue;
                }

                if(u.get_display() == 1)
                {
                    nxt = u;
                    break;
                }
            }

        }

        if (nxt != nil)
        {
            active_u = nearest_u = tmp_nearest_u = nxt; armament.contact = active_u;
            if (tmp_nearest_u.Callsign != nil)
                active_u_callsign = tmp_nearest_u.Callsign.getValue();
            else
                active_u_callsign = nil;
        }
        sel_next_target =0;
    }
}

var selectCheck = func {
    var tgt_cmd = SelectTargetCommand.getValue();
    SelectTargetCommand.setIntValue(0);
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

        var sorted_dist = sort (awg_9.tgts_list, func (a,b) {a.get_range()-b.get_range()});#richard is this needed, or is the list guarenteed to be sorted by distance already?
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
}

var TerrainManager = {
#
    # returns true if the node (position) is visible taking into accoun terrain
    IsVisible: func(node, fn) {

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

    # There is no terrain on earth that can be between these altitudes
    # so shortcut the whole thing and return now.
    if(fn.altitude_ft > 8900 and SelectCoord.alt() > 8900){
        return 1;
    }

        
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
#if(awg9_trace)
#print("active_u ",wcs_mode, active_u.get_range()," Display", active_u.get_display(), "dev ",active_u.deviation," ",l_az_fld," ",r_az_fld);
		if (wcs_current_mode == wcs_mode_tws_auto
			and active_u.get_display()
			and active_u.deviationA > l_az_fld
			and active_u.deviationA < r_az_fld) {
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
Diamond_Blinker = aircraft.light.new("sim/model/"~this_model~"/lighting/hud-diamond-switch", [0.1, 0.1]);
setprop("sim/model/"~this_model~"/lighting/hud-diamond-switch/enabled", 1);

#
#
# Map of known names to radardist names.
# radardist should be updated.
var ac_map = {"C-137R" : "707",
              "C-137R-PAX" : "707",
              "E-8R" : "707",
              "EC-137R" : "707",
              "KC-137R" : "707",
              "KC-137R-RT" : "707",
              "KC135" : "707",
              "RC-137R" : "707",
              "MiG-21MF-75" : "MiG-21",
              "MiG-21bis" : "MiG-21",
              "MiG-21bis-AI" : "MiG-21",
              "MiG-21bis-Wingman" : "MiG-21",
              "Blackbird-SR71A" : "SR71-Blackbird",
              "Blackbird-SR71B" : "SR71-Blackbird",
              "Tornado-GR4" : "Tornado",
              "ac130" : "c310",
              "c130" : "c310",
              "c130k" : "c310",
              "kc130" : "c310",
              "F-15D" : "f15c",
              "F-15C" : "f15c", 
              "AJ37-Viggen" : "mirage2000",
              "AJS37-Viggen" : "mirage2000",
              "JA37Di-Viggen" : "mirage2000",
              "Typhoon" : "mirage2000"
             };

# ECM: Radar Warning Receiver
# control the lights that indicate radar warning, the F-14 has two lights, the F-15 one light
# other aircraft may or not have this function; or instead of lights maybe a warning tone.
rwr_warning_indication = func(u) {
#
# get the aircraft type using radardist method that extracts from the model using
# the path.
# then remove the .xml and additionally support extra craft using the ac_map mapping defined above.
# this will then give us the maximum range.
# although we will use our own RCS method to 
    if (!use_tews) {
        return;
    }
	var u_name = radardist.get_aircraft_name(u.string);
    u_name = string.truncateAt(u_name, ".xml");
    u_name = ac_map[u_name] or u_name;
	var u_maxrange = radardist.my_maxrange(u_name); # in kilometer, 0 is unknown or no radar.
	var horizon = u.get_horizon( our_alt );
	var u_rng = u.get_range();
	var u_carrier = u.check_carrier_type();
    var u_az_field = (u.get_az_field()/2.0)*1.2;
	if ( u_maxrange > 0  and u_rng < horizon ) {
#print("RWR: ",u_name, " rng=",u_rng, "u_maxrange=",u_maxrange, " horizon=",horizon, " az=",u_az_field);
		var our_deviation_deg = deviation_normdeg(u.get_heading(), u.get_reciprocal_bearing());

		if ( our_deviation_deg < 0 ) { our_deviation_deg *= -1 }
#print("     our_deviation_deg=",our_deviation_deg, " u_carrier=",u_carrier);
		if ( our_deviation_deg < u_az_field or u_carrier == 1 ) {
			u_ecm_signal = (((-our_deviation_deg/20)+2.5)*(!u_carrier )) + (-u_rng/20) + 2.6 + (u_carrier*1.8);
			u_ecm_type_num = radardist.get_ecm_type_num(u_name);
#print("     u_ecm_signal=",u_ecm_signal," u_ecm_type_num=",u_ecm_type_num);
		}
	}
#else print("RWR: out of range");
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
	
#print("     u_ecm_signal=",u_ecm_signal," u_ecm_type_num=",u_ecm_type_num);

    u.EcmSignal.setValue(u_ecm_signal);
	u.EcmSignal.setValue(u_ecm_signal);
	u.EcmSignalNorm.setIntValue(u_ecm_signal_norm);
	u.EcmTypeNum.setIntValue(u_ecm_type_num);
    return u_ecm_signal != 0;
}


# Utilities.
var deviation_normdeg = func(our_heading, target_bearing) {
	var dev_norm = target_bearing-our_heading;
    dev_norm=geo.normdeg180(dev_norm);
	return dev_norm;
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
	RadarStandby.setBoolValue(!RadarStandby.getBoolValue());
}

var range_control = func(n) {#richard there was 2 of this method, I kinda deleted the unused one of them, not sure I should have done that if you kept it for some reason. Sorry, was maybe a bit too fast there.

#    if ( pilot_lock and ! we_are_bs ) { return }

    var range_radar = RangeRadar2.getValue();
    newri = 0;
    forindex(ri; radar_ranges){
        if (radar_ranges[ri] == range_radar) {
            newri = ri + n;
            break;
          }
    }
    if (newri == nil) newri = 0; # fallback to first in range

    if (newri < 0) {
      if (!cycle_range) {return;}
      newri = size(radar_ranges) - 1;
    } elsif (newri >= size(radar_ranges)) {
      if (!cycle_range) {return;}
      newri = 0;
    }

    RangeRadar2.setValue(radar_ranges[newri]);

    #print("new range ",newri, " ", radar_ranges[newri]);
    if (cockpitNotifier != nil)
      cockpitNotifier.notify_value(cockpitNotifier.set_radar_range, range_radar);
}

wcs_mode_sel = func(mode) {
#	if ( pilot_lock and ! we_are_bs ) { return }
setprop("sim/model/f-14b/instrumentation/radar-awg-9/wcs-mode", mode);
wcs_current_mode == mode;
	if ( mode == wcs_mode_pulse_srch ) {
		AzField.setValue(120);
		ddd_screen_width = 0.0844;
	} else {
		AzField.setValue(60);
		ddd_screen_width = 0.0422;
	}
}

wcs_mode_toggle = func() {
	# Temporarely toggles between the first 2 available modes.
	#foreach (var n; props.globals.getNode("sim/model/f-14b/instrumentation/radar-awg-9/wcs-mode").getChildren()) {
#	if ( pilot_lock and ! we_are_bs ) { return }
	if ( wcs_current_mode == wcs_mode_pulse_srch ) {
        wcs_current_mode = wcs_mode_tws_auto;
		AzField.setValue(60);
		ddd_screen_width = 0.0422;
	}
    else #if ( wcs_current_mode == wcs_mode_tws_auto )
    {
        wcs_current_mode = wcs_mode_pulse_srch;
		AzField.setValue(120);
		ddd_screen_width = 0.0844;
	}
    setprop("sim/model/f-14b/instrumentation/radar-awg-9/wcs-mode", wcs_current_mode);
}


wcs_mode_update = func() {
	if ( WcsMode.getValue() ==  wcs_mode_tws_auto) {
		wcs_current_mode = wcs_mode_tws_auto;
		AzField.setValue(60);
		ddd_screen_width = 0.0422;
	}
    else #if ( WcsMode.getNode("pulse-srch").getBoolValue() ) 
    {
        wcs_current_mode = wcs_mode_pulse_srch;
		AzField.setValue(120);
		ddd_screen_width = 0.0844;
	}
    setprop("sim/model/f-14b/instrumentation/radar-awg-9/wcs-mode", wcs_current_mode);
}

# Target class
# ---------------------------------------------------------------------
var Target = {
	new : func (c) {
		var obj = { parents : [Target]};
        obj.propNode = c;
		obj.RdrProp = c.getNode("radar");
		obj.Heading = c.getNode("orientation/true-heading-deg");
        obj.pitch   = c.getNode("orientation/pitch-deg");
        obj.roll   = c.getNode("orientation/roll-deg");
		obj.Alt = c.getNode("position/altitude-ft");
		obj.AcType = c.getNode("sim/model/ac-type");
		obj.type = c.getName();
		obj.Valid = c.getNode("valid");
		obj.Callsign = c.getNode("callsign");
        obj.name = c.getNode("name");
        obj.TAS = c.getNode("velocities/true-airspeed-kt");
        obj.TransponderId = c.getNode("instrumentation/transponder/transmitted-id");

        
        
        obj.Model = c.getNode("model-short");
        var model_short = c.getNode("sim/model/path");
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
        } elsif (c.getNode("type") != nil) {
            # not all have a path property
            obj.ModelType = c.getNode("type").getValue();
            if (obj.ModelType == nil) {
                # not all have a type property
                obj.ModelType = "";
            }
        } else {
            obj.ModelType = "";
        }

        # let us make callsign a static variable:
        if (obj.Callsign == nil or obj.Callsign.getValue() == "")
        {
            if (obj.name == nil or obj.name.getValue() == "") {
                obj.myCallsign = obj.ModelType;# last resort. 
            } else {
                obj.myCallsign = obj.name.getValue();# for AI ships.
            }
        } else {
            obj.myCallsign = obj.Callsign.getValue();
        }

        #just so I dont have to change all your code that rely on Target.Callsign directly Richard, I simply replace it:
        obj.Callsign = c.getNode("compositeCallsign",1);
        obj.Callsign.setValue(obj.myCallsign);

        obj.unique = obj.myCallsign~c.getPath();# should be very unique, callsign might not be enough. Path by itself is not enough either, as paths gets reused.


        obj.class = AIR;
        

		obj.index = c.getIndex();
		obj.string = "ai/models/" ~ obj.type ~ "[" ~ obj.index ~ "]";
		obj.shortstring = obj.type ~ "[" ~ obj.index ~ "]";
        obj.TgTCoord  = geo.Coord.new();
        if (c.getNode("position/latitude-deg") != nil and c.getNode("position/longitude-deg") != nil) {
            obj.lat = c.getNode("position/latitude-deg");
            obj.lon = c.getNode("position/longitude-deg");
        } else {
            obj.lat = nil;
            obj.lon = nil;
        }
        if (c.getNode("position/global-x") != nil)
        {
            obj.x = c.getNode("position/global-x");
            obj.y = c.getNode("position/global-y");
            obj.z = c.getNode("position/global-z");
            } else {
                obj.x = nil;
        }

        if (obj.type == "multiplayer" or obj.type == "tanker" or obj.type == "aircraft" and obj.RdrProp != nil) 
            obj.airbone = 1;
        else
            obj.airbone = 0;
		
		# Remote back-seaters shall not emit and shall be invisible. FIXME: This is going to be handled by radardist ASAP.
		obj.not_acting = 0;
		var Remote_Bs_String = c.getNode("sim/multiplay/generic/string[1]");
		if ( Remote_Bs_String != nil ) {
			var rbs = Remote_Bs_String.getValue();
			if ( rbs != nil ) {
				var l = split(";", rbs);
				if ( size(l) > 0 ) {
					if ( l[0] == "f15-bs" or l[0] == "f-14b-bs" ) {
						obj.not_acting = 1;
					}
				}
			}
		}

		# Local back-seater has a different radar-awg-9 folder and shall not see its pilot's aircraft.
		obj.InstrTgts = props.globals.getNode("sim/model/"~this_model~"/instrumentation/radar-awg-9/targets", 1);
#		var bs = getprop("sim/aircraft");
#		if ( bs == "f16-bs" or bs == "f15-bs" or bs == "f-14b-bs") {
        if (we_are_bs) {
			if  ( BS_instruments.Pilot != nil ) {
				# Use a different radar-awg-9 folder.
				obj.InstrTgts = BS_instruments.Pilot.getNode("sim/model/"~this_model~"/instrumentation/radar-awg-9/targets", 1);
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
            obj.Visible        = obj.TgtsFiles.getNode("visible", 1);
            obj.Behind_terrain = obj.TgtsFiles.getNode("behind-terrain", 1);
            obj.RWRVisible     = obj.TgtsFiles.getNode("rwr-visible", 1);
            obj.Fading         = obj.TgtsFiles.getNode("ddd-echo-fading", 1);
            obj.DddDrawRangeNm = obj.TgtsFiles.getNode("ddd-draw-range-nm", 1);
            obj.TidDrawRangeNm = obj.TgtsFiles.getNode("tid-draw-range-nm", 1);
            obj.RoundedAlt     = obj.TgtsFiles.getNode("rounded-alt-ft", 1);
            obj.TimeLast       = obj.TgtsFiles.getNode("closure-last-time", 1);
            obj.RangeLast      = obj.TgtsFiles.getNode("closure-last-range-nm", 1);
            obj.ClosureRate    = obj.TgtsFiles.getNode("closure-rate-kts", 1);
            obj.Visible.setBoolValue(0);
            obj.Display.setBoolValue(0);
        }
		obj.TimeLast.setValue(ElapsedSec.getValue());
        var cur_range = obj.get_range();
        if (cur_range != nil and obj.RangeLast != nil)
		    obj.RangeLast.setValue(obj.get_range());
		# Radar emission status for other users of radar2.nas.
		obj.RadarStandby = c.getNode("sim/multiplay/generic/int[2]");

		obj.deviationA = nil;
        obj.deviationE = nil;
        obj.elevation = nil;

		return obj;
	},
#
# radar azimuth
    get_az_field : func {
        return 60.0;
    },
	get_heading : func {
		var n = me.Heading.getValue();
        if (n != nil)
		    me.BHeading.setValue(n);
		return n;	},
	get_bearing : func {
        var n = nil;
        if (me.Bearing != nil and me.Bearing.getValue() != 0) {# will always be 0 for AI carriers
            n = me.Bearing.getValue();
        }
        if(n == nil) {
            # AI/MP has no radar properties
            n = me.get_bearing_from_Coord(geo.aircraft_position());
        }
        me.BBearing.setValue(n);
        return n;
	},
    get_bearing_from_Coord: func(MyAircraftCoord){
        var myBearing = 0;
        if(me.get_Coord().is_defined()) {
            myBearing = MyAircraftCoord.course_to(me.get_Coord());
        }
        return myBearing;
    },
	set_relative_bearing : func(n) {
		me.RelBearing.setValue(n);
	},
	get_relative_bearing : func() {
        return geo.normdeg180(me.get_bearing()-getprop("orientation/heading-deg"));
	},
	get_reciprocal_bearing : func {
		return geo.normdeg(me.get_bearing() + 180);
	},
	get_deviation : func(true_heading_ref) {
		me.deviationA =  deviation_normdeg(true_heading_ref, me.get_bearing());
		return me.deviationA;
	},
	get_altitude : func {
		return me.Alt.getValue();
	},
	get_total_elevation : func(own_pitch) {#richard, this method was sharing a variable with get_deviation and that variable was accesed different places which led to wrong value being used, I fixed that.
		me.deviationE =  deviation_normdeg(own_pitch, me.getElevation());
		return me.deviationE;
	},
	get_range : func {
        #
        # range on carriers (and possibly other items) is always 0 so recalc.
        if (me.Range == nil or me.Range.getValue() == 0)
        {
            var tgt_pos = me.get_Coord();
#                print("Recalc range - ",tgt_pos.distance_to(geo.aircraft_position()));
            if (tgt_pos != nil) {
                return tgt_pos.distance_to(geo.aircraft_position()) * M2NM; # distance in NM
            }
            if (me.Range != nil)
                return me.Range.getValue();
        }
        if (me.Range == nil)
            return 0;
        else
            return me.Range.getValue();
	},
    get_slant_range : func {
        #
        # range on carriers (and possibly other items) is always 0 so recalc.
        return me.get_Coord().direct_distance_to(geo.aircraft_position()) * M2NM; # distance in NM
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
        if (s == nil or s != 1) 
            return 0;
		}
		return s;
	},
	get_transponder : func {
        if (me.TransponderId != nil) 
            return me.TransponderId.getValue();
        return nil;
		},
	get_display : func() {
		return me.Display.getValue();
	},
	set_display : func(n) {
		me.Display.setBoolValue(n);
	},
	get_visible : func() {
		return me.Visible.getValue();
	},
	set_visible : func(n) {
		me.Visible.setBoolValue(n);
	},
	get_behind_terrain : func() {
		return me.Behind_terrain.getValue();
	},
	set_behind_terrain : func(n) {
		me.Behind_terrain.setBoolValue(n);
	},
	get_RWR_visible : func() {
		return me.RWRVisible.getValue();
	},
	set_RWR_visible : func(n) {
		me.RWRVisible.setBoolValue(n);
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
        if (me.x != nil)
        {
            var x = me.x.getValue();
            var y = me.y.getValue();
            var z = me.z.getValue();

            me.TgTCoord.set_xyz(x, y, z);
        } elsif (me.lat != nil) {
            me.TgTCoord.set_latlon(me.lat.getValue(), me.lon.getValue(), me.Alt.getValue() * FT2M);
        } else {
            return nil;#hopefully wont happen
        }
        return geo.Coord.new(me.TgTCoord);#best to pass a copy
    },

	get_closure_rate : func() {
        #
        # calc closure using trig as the elapsed time method is not really accurate enough and jitters considerably
        if (me.TAS != nil)
        {
            var tas = me.TAS.getValue();
            var our_hdg = OurHdg.getValue();
            if(our_hdg != nil)
            {
                var myCoord = me.get_Coord();
                var bearing = 0;
                if(myCoord.is_defined())
                {
                    bearing = ownship_pos.course_to(myCoord);
                    bearing_ = myCoord.course_to(ownship_pos);
                }
                var vtrue_kts = OurIAS.getValue();
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
    isValid: func () {
      var valid = me.Valid.getValue();
      if (valid == nil) {
        valid = FALSE;
      }
      return valid;
    },
    getUnique: func {
        return me.unique;
    },
	get_bearing: func(){
        var n = nil;
        if (me.Bearing != nil and me.Bearing.getValue() != 0) {# will always be 0 for AI carriers
            n = me.Bearing.getValue();
        }
        if(n == nil) {
            # AI/MP has no radar properties
            n = me.get_bearing_from_Coord(geo.aircraft_position());
        }
        return n;
    },
    get_bearing_from_Coord: func(MyAircraftCoord){
        var myBearing = 0;
        if(me.get_Coord().is_defined()) {
            myBearing = MyAircraftCoord.course_to(me.get_Coord());
        }
        return myBearing;
    },
    setClass: func(cl){me.class=cl},
    get_type: func{me.class},
    isPainted: func{
        #if (active_u !=nil) printf("%s %s %d", active_u.getUnique(), me.getUnique(), me.get_display());
        if (active_u != nil and active_u.getUnique() == me.getUnique() and me.get_display() == 1) {            
            return 1;
        } else {
            return 0;
        }
    },
    isLaserPainted: func{
        if (LaserArm.getValue() != 1) {
            return 0;
        }
        if (active_u != nil and active_u.getUnique() == me.getUnique()) {
            return 1;
        } else {
            return 0;
        }
    },
    getFlareNode: func {
        return me.propNode.getNode("rotors/main/blade[3]/flap-deg");
    },
    getChaffNode: func () {
      return me.propNode.getNode("rotors/main/blade[3]/position-deg");
    },
    getElevation: func() {
        me.elevation = vector.Math.getPitch(geo.aircraft_position(), me.get_Coord());
        return me.elevation;
#        var e = 0;
#        e = me.Elevation.getValue();
#        if(e == nil or e == 0) {
#            # AI/MP has no radar properties
#            var self = geo.aircraft_position();
#            me.get_Coord();
#            if (me.coord != nil){
#                var angleInv = armament.AIM.clamp(self.distance_to(me.coord)/self.direct_distance_to(me.coord), -1, 1);
#                e = (self.alt()>me.coord.alt()?-1:1)*math.acos(angleInv)*R2D;
#            }
#        }
        return e;
    },
    get_Callsign: func{
        return me.myCallsign;# callsigns are probably not dynamic, so its defined at Target creation.
        if (me.Callsign == nil or me.Callsign.getValue() == "") {
            if (me.name == nil or me.name.getValue() == "") {
                return me.get_model();
            }
            return me.name.getValue();# for AI ships.
        }
        return me.Callsign.getValue();
    },
    get_Pitch: func(){
        var n = me.pitch.getValue();
        return n;
    },
    get_Roll: func(){
        var n = me.roll.getValue();
        return n;
    },
    get_Speed: func(){
        return me.get_TAS();
    },
    get_model: func {
        return me.ModelType;
    },
    isRadiating: func (coord) {
        me.rn = me.get_range();
        if (me.get_model() != "buk-m2" and me.get_model() != "missile_frigate" or me.get_type()==MARINE) {
            me.bearingR = coord.course_to(me.get_Coord());
            me.headingR = me.get_heading();
            me.inv_bearingR =  me.bearingR+180;
            me.deviationRd = me.inv_bearingR - me.headingR;
        } else {
            me.deviationRd = 0;
        }
        me.rdrAct = me.propNode.getNode("sim/multiplay/generic/int[2]");
        if (me.rn < 70 and ((me.rdrAct != nil and me.rdrAct.getValue()!=1) or me.rdrAct == nil) and math.abs(geo.normdeg180(me.deviationRd)) < 60) {
            # our radar is active and pointed at coord.
            return 1;
        }
        return 0;
    },
    isVirtual: func {
        # used by missile-code
        return FALSE;
    },
	list : [],
};

# Notes:

# HUD field of view = 2 * math.atan2( 0.0764, 0.7186) * globals.R2D; # ~ 12.1375°
# where 0.071 : virtual screen half width, 0.7186 : distance eye -> screen
dump_tgt = func (u){
    print(scan_tgt_idx, " callsign ", u.get_Callsign(), " range ",u.get_range(), " display ", u.get_display(), " visible ",u.get_visible(), 
          " ddd-relative-bearing=", u.RelBearing,
          " ddd-echo-fading=", u.Fading,
          " ddd-draw-range-nm=",u.DddDrawRangeNm,
          " tid-draw-range-nm=",u.TidDrawRangeNm);
}

dump_tgt_list = func {
    for (scan_tgt_idx=0;scan_tgt_idx < size(tgts_list); scan_tgt_idx += 1) {
        var u = tgts_list[scan_tgt_idx];
        dump_tgt(u);
    }
}



#
# This is the emesary recipient that will update the Radar when a FrameNotification is
# received.

var RadarRecipient = 
{
    new: func(_ident)
    {
        var new_class = emesary.Recipient.new(_ident~".RADAR");

        new_class.Receive = func(notification)
          {
              rdr_loop(notification);
              return emesary.Transmitter.ReceiptStatus_OK;
          }
        return new_class;
    },
};

var aircraft_radar = RadarRecipient.new(this_model);
emesary.GlobalTransmitter.Register(aircraft_radar );


#
# this is RWR for TEWS display for the F-15. For a less advanced EW system
# this method would probably just look at their radar.
var compute_rwr = func(radar_mode, u, u_rng){
    #
    # Decide if this mp item is a valid return (and within range).
    # - our radar switched on
    # - their radar switched on
    # - their transponder switched on 
    var their_radar_standby = u.get_rdr_standby();
    var their_transponder_id = u.get_transponder();
    var emitting = 0;
#    var em_by = "";
    # TEWS will see transpoders that are turned on; according to some
    # using the inverse square law and an estimated power of 200 watts
    # and an assumed high gain antenna the estimate is that the maximum
    # distance the transponder/IFF would be distinct enough is 61.18357nm
    if (their_transponder_id != nil and their_transponder_id > 0 and u_rng < 61.18357) {
        emitting = 1;
#em_by = em_by ~ "xpdr ";
    }
    # modes below 2 are on / emerg so they will show up on rwr
#F-15 radar modes;
# mode 3 = off
# mode 2 = stby
# mode 1 = opr
# mode 0 = emerg
    if (radar_mode < 2 and !u.get_behind_terrain()) {
        # in this sense it is actually us that is illuminating them, but for TEWS this is fine.
        var horizon = u.get_horizon( our_alt );
        var u_az_field = az_fld/2.0;
#print ("u_rng=",u_rng," horizon=",horizon);
         if (  u_rng < horizon ) {
            var our_deviation_deg = deviation_normdeg(u.get_heading(), u.get_bearing());
#print("     our_deviation_deg=",our_deviation_deg);
            
            if ( our_deviation_deg < 0 ) { our_deviation_deg *= -1 }
            if ( our_deviation_deg < u_az_field) {
#                em_by = em_by ~ "my_rdr ";
                emitting = 1; 
            }
        }
    }
    if (their_radar_standby != nil and their_radar_standby == 0){
      emitting = 1;
#em_by = em_by ~ "their_rdr ";
  }

#    print("TEWS: ",u.Callsign.getValue()," range ",u_rng, " by ", em_by, " our_mode=",radar_mode, " their_mode=",their_radar_standby, " their_transponder_id=",their_transponder_id, " emitting = ",emitting, " vis=",u.get_visible());

    u.set_RWR_visible(emitting and u.get_visible());
}