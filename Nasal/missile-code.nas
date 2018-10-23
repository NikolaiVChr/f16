#########################################################################################
#######	
####### Guided/Cruise missiles, rockets and dumb/glide/guided bombs code for Flightgear.
#######
####### License: GPL 2.0
#######
####### Authors:
#######  Alexis Bory, Fabien Barbier, Richard Harrison, Justin Nicholson, Nikolai V. Chr.
####### 
####### The file vector.nas needs to be available in namespace 'vector'.
#######
####### In addition, some code is derived from work by:
#######  David Culp, Vivian Meazza, M. Franz
#######
#########################################################################################

# Some notes about making weapons:
#
# Firstly make sure you read the comments (line 240+) below for the properties.
# For laser/gps guided gravity bombs make sure to set the max G very low, like 0.5G, to simulate them slowly adjusting to hit the target.
# Remember for air to air missiles the speed quoted in literature is normally the speed above the launch platform. I usually fly at the typical max usage
#   regime for that missile, so for example for AIM-7 it would be at 40000 ft,
#   there I make sure it can reach approx the max relative speed. For older missiles the max speed quoted is sometimes absolute speed though, so beware.
#   If it quotes aerodynamic speed then its the absolute speed. Speeds quoted in in unofficial sources can be any of them,
#   but if its around mach 5 for A/A its a good bet its absolute, only very few A/A missiles are likely hypersonic. (probably due to heat or fuel limitations)
# If you cannot find fuel weight in literature, you probably wont go far off with a value that is 1/4 to 1/3 of total launch weight for a A/A missile.
# Stage durations is allowed to be 0, so can thrust values. If there is no second stage, instead of just setting stage 2 thrust to 0,
#   set stage 2 duration to 0 also. For unpowered munitions, set all thrusts to 0.
# For very low sea skimming missiles, be sure to set terrain following to false, you cannot have it both ways.
#   Since if it goes very low (below 100ft), it cannot navigate terrain reliable.
# The property terrain following only goes into effect, if a cruise altitude is set below 10000ft and not set to 0.
#   Cruise missiles against ground targets will always terrain follow, no matter that property.
# If literature quotes a max distance for a weapon, its a good bet it is under the condition that the target
#   is approaching the launch platform with high speed and does not evade, and also if the launch platform is an aircraft,
#   that it also is approaching the target with high speed. In other words, high closing rate. For example the AIM-7, which can hit bombers out at 32 NM,
#   will often have to be within 3 NM of an escaping target to hit it (source). Missiles typically have significantly less range against an evading
#   or escaping target than what is commonly believed. I typically fly at 40000 ft at mach 2, approach a target flying head-on with same speed and altitude,
#   to test max range. Its typically drag that I adjust for that.
# When you test missiles against aircraft, be sure to do it with a framerate of 25+, else they will not hit very good, especially high speed missiles like
#   Amraam or Phoenix. Also notice they generally not hit so close against Scenario/AI objects compared to MP aircraft due to the way these are updated.
# Laser and semi-radar guided munitions need the target to be painted to keep lock. Notice gps guided munition that are all aspect will never lose lock,
#   whether they can 'see' the target or not. Anti-radiation missiles will need the target to send radiation towards the missile.
# Remotely controlled guidance is not implemented, but the way it flies can be simulated by setting direct navigation with semi-radar or laser guidance.
# Set DEBUG_STATS and/or DEBUG_FLIGHT to true to check how the missile works during flight, when you are designing a weapon.
# 
#
# Usage:
#
# To create a weapon call AIM.new(pylon, type, description, midFlightFunction). The pylon is an integer from 0 or higher. When its launched it will read the pylon position in
#   controls/armament/station[pylon+1]/offsets, where the position properties must be x-m, y-m and z-m. The type is just a string, the description is a string
#   that is exposed in its radar properties under AI/models during flight. The function is for changing target, guidance or guidance-law during flight.
# The mid flight function will be called often during flight with 1 parameter. The param is a hash like {time_s, dist_m, mach, weapon_position}, where the latter is a geo.Coord.
#   It expects you to return a hash with any or none of these {guidance, guidanceLaw, target}.
# The model that is loaded and shown is located in the aircraft folder at the value of property payload/armament/models in a subfolder with same name as type.
#   Inside the subfolder the xml file is called [lowercase type]-[pylon].xml
# To start making the missile try to get a lock, call start(), the missile will then keep trying to get a lock on 'contact'.
#   'contact' can be set to nil at any time or changed. To stop the search, just call stop(). To resume the search you again have call start().
# To release the munition at a target call release(), normally do this after the missile has set its own status to MISSILE_LOCK.
# When using weapons without target, call releaseAtNothing() instead of release(), search() does not need to have been called beforehand.
#   To then find out where it hit the ground check the impact report in AI/models. The impact report will contain warhead weight, but that will be zero if
#   the weapon did not have time to arm before hitting ground.
# To drop the munition, without arming it nor igniting its engine, call eject().
# 
#
# Limitations:
# 
# The weapons use a simplified flight model that does not have AoA or sideslip. Mass balance, rotational inertia, wind is also not implemented. They also do not roll.
# If you fire a weapon and have HoT enabled in flightgear, they likely will not hit very precise.
# The weapons are highly dependent on framerate, so low frame rate will make them hit imprecise.
# APN does not take target sideslip and AoA into account when considering the targets acceleration. It assumes the target flies in the direction its pointed.
# The drag curves are tailored for sizable munitions, so it does not work well will bullet or cannon sized munition, submodels are better suited for that.
# Inertial guidance does not account for drift.
#
#
# Future features:
#
# ECM disturbance of getting radar lock.
# Lock on jam. (advanced feature)
# After FG gets HLA: stop using MP chat for hit messages.
# Allow firing only if certain conditions are met. Like not being inverted when firing ejected weapons.
# Remote controlled guidance (advanced feature and probably not very practical in FG..yet)
# Ground launched rails/tubes that rotate towards target before firing.
# Sub munitions that have their own guidance/FDM. (advanced)
# GPS guided munitions could have waypoints added.
# Specify terminal manouvres and preferred impact aspect.
# Consider to average the closing speed in proportional navigation. So get it between second last positions and current, instead of last to current.
# Drag coeff reduction due to exhaust plume.
# Proportional navigation should use vector math instead decomposition horizontal/vertical navigation.
# Bleeding speed due to high G turning should depend on drag-area, with AIM-120s as reference. (that would mean recalibrate all cruise-missiles so they don't crash)
# Max-g should be seperated into max structural G that it will never exceed, and max-g for certain mach. Should still depend also on altitude of course. This way it needs a certain speed to perform certain G.
# Real rocket thrust does not necesarily cutoff instantly. Make an optional fadeout. (use the aim-9 new variant paper page as guide)
# Support for seeker FOV that is smaller than FCS FOV. (ASRAAM)
# Introduce battery time. Beyond this time it wont steer.
# Anti-rad: So if the target source goes dark, it deploys a parachute and “loiters”. If it re-detects target, it releases the parachute and fires the second motor
#
# Please report bugs and features to Nikolai V. Chr. | ForumUser: Necolatis | Callsign: Leto

var AcModel        = props.globals.getNode("payload");
var OurHdg         = props.globals.getNode("orientation/heading-deg");
var OurRoll        = props.globals.getNode("orientation/roll-deg");
var OurPitch       = props.globals.getNode("orientation/pitch-deg");
var OurAlpha       = props.globals.getNode("orientation/alpha-deg");
var OurBeta        = props.globals.getNode("orientation/side-slip-deg");
var ourAlt         = props.globals.getNode("position/altitude-ft");
var deltaSec       = props.globals.getNode("sim/time/delta-sec");
var speedUp        = props.globals.getNode("sim/speed-up");
var noseAir        = props.globals.getNode("velocities/uBody-fps");
var belowAir       = props.globals.getNode("velocities/wBody-fps");
var HudReticleDev  = props.globals.getNode("payload/armament/hud/reticle-total-deviation", 1);#polar coords
var HudReticleDeg  = props.globals.getNode("payload/armament/hud/reticle-total-angle", 1);
var update_loop_time = 0.000;

var SIM_TIME = 0;
var REAL_TIME = 1;

var TRUE = 1;
var FALSE = 0;

# enables the AIM-9 aiming reticle (F-14) - doesn't require the radar to be in TWS
var use_fg_default_hud = getprop("payload/armament/use-fg-default-hud");
if (use_fg_default_hud == nil) {
	use_fg_default_hud = FALSE;
}

var MISSILE_STANDBY  = -1;
var MISSILE_STARTING = -0.5;
var MISSILE_SEARCH   = 0;
var MISSILE_LOCK     = 1;
var MISSILE_FLYING   = 2;

var AIR = 0;
var MARINE = 1;
var SURFACE = 2;
var ORDNANCE = 3;

# set these to print stuff to console:
var DEBUG_STATS            = 0;#most basic stuff
var DEBUG_FLIGHT           = 0;#for creating missiles sometimes good to have this on to see how it flies.

# set these to debug the code:
var DEBUG_STATS_DETAILS    = FALSE;
var DEBUG_GUIDANCE         = FALSE;
var DEBUG_GUIDANCE_DETAILS = FALSE;
var DEBUG_FLIGHT_DETAILS   = 0;
var DEBUG_SEARCH           = 0;
var DEBUG_CODE             = FALSE;

var g_fps        = 9.80665 * M2FT;
var slugs_to_lbm = 32.1740485564;
var const_e      = 2.71828183;

var first_in_air = FALSE;# first missile is in the air, other missiles should not write to MP.

var versionString = getprop("sim/version/flightgear");
var version = split(".", versionString);
var major = num(version[0]);
var minor = num(version[1]);
var pica  = num(version[2]);
var pickingMethod = FALSE;
if ((major == 2017 and minor == 2 and pica >= 1) or (major == 2017 and minor > 2) or major > 2017) {
	pickingMethod = TRUE;
}
var offsetMethod = FALSE;
if ((major == 2017 and minor == 2 and pica >= 1) or (major == 2017 and minor > 2) or major > 2017) {
	offsetMethod = TRUE;
}

var spawn = func(c, context) return func {thread.newthread(func {
	call(c, nil, context, context, var err = []);
	if(size(err)) {
		print("multi-threading error:");
		foreach(var i;err) {
          print(i);
        }
	}
})};

#
# The radar will make sure to keep this variable updated.
# Whatever is targeted and ready to be fired upon, should be set here. (or set it directly on the missile using AIM.contacts[0])
#
var contact = nil;
#
# Contact should implement the following interface:
#
# get_type()      - (AIR, MARINE, SURFACE or ORDNANCE)
# getUnique()     - Used when comparing 2 targets to each other and determining if they are the same target.
# isValid()       - If this target is valid
# getElevation()
# get_bearing()
# get_Callsign()
# get_range()
# get_Coord()
# get_Latitude()
# get_Longitude()
# get_altitude()
# get_Pitch()
# get_Speed()
# get_heading()
# getFlareNode()  - Used for flares.
# getChaffNode()  - Used for chaff.
# isPainted()     - Tells if this target is still being radar tracked by the launch platform, only used in semi-radar guided missiles.
# isLaserPainted()     - Tells if this target is still being tracked by the launch platform, only used by laser guided ordnance.
# isRadiating(coord) - Tell if anti-radiation missile is hit by radiation from target. coord is the weapon position.
# isVirtual()     - Tells if the target is just a position, and should not be considered for damage.

var AIM = {
	#done
	new : func (p, type = "AIM-9", sign = "Sidewinder", midFlightFunction = nil, nasalPosition = nil) {
		if(AIM.active[p] != nil) {
			#do not make new missile logic if one exist for this pylon.
			return -1;
		} elsif (AcModel.getNode("armament/"~string.lc(type)~"/") == nil) {
			# missiletype does not exist
			return -1;
		}
		var m = { parents : [AIM]};
		# Args: p = Pylon.

		m.mfFunction = midFlightFunction;
		m.nasalPosition = nasalPosition;

		m.type_lc = string.lc(type);
		m.type = type;

		m.deleted = FALSE;

		m.status            = MISSILE_STANDBY; # -1 = stand-by, 0 = searching, 1 = locked, 2 = fired.
		m.free              = 0; # 0 = status fired with lock, 1 = status fired but having lost lock.
		m.prop              = AcModel.getNode("armament/"~m.type_lc~"/").getChild("msl", 0, 1);
		m.SwSoundOnOff      = AcModel.getNode("armament/"~m.type_lc~"/sound-on-off",1);
		m.SwSoundFireOnOff  = AcModel.getNode("armament/"~m.type_lc~"/sound-fire-on-off",1);
        m.SwSoundVol        = AcModel.getNode("armament/"~m.type_lc~"/sound-volume",1);
        if (m.SwSoundOnOff.getValue() == nil) {
        	m.SwSoundOnOff.setBoolValue(0);
        }
        if (m.SwSoundFireOnOff.getValue() == nil) {
        	m.SwSoundFireOnOff.setBoolValue(0);
        }
        if (m.SwSoundVol.getValue() == nil) {
        	m.SwSoundVol.setDoubleValue(0);
        }
        m.useHitInterpolation   = getprop("payload/armament/hit-interpolation");#false to use 5H1N0B1 trigonometry, true to use Leto interpolation.
        m.useSingleFile   = nil;#getprop("payload/armament/one-xml-per-type");#disabled.
        if (m.useSingleFile == nil) {
        	m.useSingleFile = FALSE;
        }
		m.PylonIndex        = m.prop.getNode("pylon-index", 1).setValue(p);
		m.ID                = p;
		m.stationName       = AcModel.getNode("armament/station-name").getValue();
		if (m.nasalPosition == nil) {
			m.pylon_prop        = props.globals.getNode(AcModel.getNode("armament/pylon-stations").getValue()).getChild(m.stationName, p+AcModel.getNode("armament/pylon-offset").getValue());
		}
		m.Tgt               = nil;
		m.callsign          = "Unknown";
		m.direct_dist_m     = nil;
		m.speed_m           = -1;

		m.nodeString = "payload/armament/"~m.type_lc~"/";

		###############
		# Weapon specs:
		###############

		# name
		m.typeLong              = getprop(m.nodeString~"long-name");                  # Longer name of the weapon
		m.typeShort             = getprop(m.nodeString~"short-name");                 # Shorter name of the weapon
		# detection and firing
		m.max_fire_range_nm     = getprop(m.nodeString~"max-fire-range-nm");          # max range that the FCS allows firing
		m.min_fire_range_nm     = getprop(m.nodeString~"min-fire-range-nm");          # it wont get solid lock before the target has this range
		m.fcs_fov               = getprop(m.nodeString~"FCS-field-deg") / 2;          # fire control system total field of view diameter for when searching and getting lock before launch.
		m.class                 = getprop(m.nodeString~"class");                      # put in letters here that represent the types the missile can fire at. A=air, M=marine, G=ground
        m.brevity               = getprop(m.nodeString~"fire-msg");                   # what the pilot will call out over the comm when he fires this weapon
        m.coolable              = getprop(m.nodeString~"coolable");                   # If the seeker supports being cooled. (AIM-9L or later supports)
        m.cool_time             = getprop(m.nodeString~"cool-time");                  # Time to cold the seeker from fully warm.
        m.cool_duration         = getprop(m.nodeString~"cool-duration");              # Typically 2.5 hours for cooling fluids. Much higher for electrical.
        m.warm_detect_range_nm  = getprop(m.nodeString~"warm-detect-range-nm");       # Current guidance mode detect range. (when warm)
        m.detect_range_nm       = getprop(m.nodeString~"detect-range-nm");            # Current guidance mode default detect range. (when cold). This can differ from max-fire-range-nm in that some missiles can be fired at targets they cannot yet see.
        m.beam_width_deg        = getprop(m.nodeString~"seeker-beam-width-deg");      # Seeker detector field of view diameter
        m.ready_time            = getprop(m.nodeString~"ready-time");                 # time to get ready after standby mode.
        m.loal                  = getprop(m.nodeString~"lock-on-after-launch");       # bool. LOAL supported. For loal to work [optional]
        m.canSwitch             = getprop(m.nodeString~"auto-switch-target-allowed"); # bool. Can switch target at will if it loses lock [optional]
        m.standbyFlight         = getprop(m.nodeString~"prowl-flight");               # unguided/level/gyro-pitch for LOAL and that stuff, when not locked onto stuff.
        m.switchTime            = getprop(m.nodeString~"switch-time-sec");            # auto switch of targets in flight: time to scan FoV.
		# navigation, guiding and seekerhead
		m.max_seeker_dev        = getprop(m.nodeString~"seeker-field-deg") / 2;       # missiles own seekers total FOV diameter.
		m.guidance              = getprop(m.nodeString~"guidance");                   # heat/radar/semi-radar/laser/gps/vision/unguided/level/gyro-pitch/radiation/inertial
		m.guidanceLaw           = getprop(m.nodeString~"navigation");                 # guidance-law: direct/PN/APN/PNxxyy/APNxxyy (use direct for gravity bombs, use PN for very old missiles, use APN for modern missiles, use PNxxyy/APNxxyy for surface to air where xx is degrees to aim above target, yy is seconds it will do that)
		m.pro_constant          = getprop(m.nodeString~"proportionality-constant");   # Constant for how sensitive proportional navigation is to target speed/acc. Normally between 3-6. [optional]
		m.all_aspect            = getprop(m.nodeString~"all-aspect");                 # bool. set to false if missile only locks on reliably to rear of target aircraft
		m.angular_speed         = getprop(m.nodeString~"seeker-angular-speed-dps");   # only for heat/vision seeking missiles. Max angular speed that the target can move as seen from seeker, before seeker loses lock.
		m.sun_lock              = getprop(m.nodeString~"lock-on-sun-deg");            # only for heat seeking missiles. If it looks at sun within this angle, it will lose lock on target.
		m.loft_alt              = getprop(m.nodeString~"loft-altitude");              # if 0 then no snap up. Below 10000 then cruise altitude above ground. Above 10000 max altitude it will snap up to.
        m.follow                = getprop(m.nodeString~"terrain-follow");             # bool. used for anti-ship missiles that should be able to terrain follow instead of purely sea skimming.
        m.reaquire              = getprop(m.nodeString~"reaquire");                   # bool. If weapon will try to reaquire lock after losing it. [optional]
        m.maxPitch              = getprop(m.nodeString~"max-pitch-deg");              # After propulsion it will not be able to steer up more than this. [optional]
        m.guidanceEnabled       = getprop(m.nodeString~"guidance-enabled");             # Boolean. If guidance will activate when launched. [optional]
		# engine
		m.force_lbf_1           = getprop(m.nodeString~"thrust-lbf-stage-1");         # stage 1 thrust [optional]
		m.force_lbf_2           = getprop(m.nodeString~"thrust-lbf-stage-2");         # stage 2 thrust [optional]
		m.stage_1_duration      = getprop(m.nodeString~"stage-1-duration-sec");       # stage 1 duration [optional]
		m.stage_2_duration      = getprop(m.nodeString~"stage-2-duration-sec");       # stage 2 duration [optional]
		m.weight_fuel_lbm       = getprop(m.nodeString~"weight-fuel-lbm");            # fuel weight [optional]. If this property is not present, it won't lose weight as the fuel is used.
		m.vector_thrust         = getprop(m.nodeString~"vector-thrust");              # Boolean. [optional]
		m.engineEnabled         = getprop(m.nodeString~"engine-enabled");             # Boolean. If engine will start when launched. [optional]
		# aerodynamic
		m.weight_launch_lbm     = getprop(m.nodeString~"weight-launch-lbs");          # total weight of armament, including fuel and warhead.
		m.Cd_base               = getprop(m.nodeString~"drag-coeff");                 # drag coefficient
		m.Cd_delta              = getprop(m.nodeString~"delta-drag-coeff-deploy");    # drag coefficient added by deployment
		m.ref_area_sqft         = getprop(m.nodeString~"cross-section-sqft");         # normally is crosssection area of munition (without fins)
		m.max_g                 = getprop(m.nodeString~"max-g");                      # max G-force the missile can pull at sealevel
		m.min_speed_for_guiding = getprop(m.nodeString~"min-speed-for-guiding-mach"); # minimum speed before the missile steers, before it reaches this speed it will fly ballistic.
		m.intoBore              = getprop(m.nodeString~"ignore-wind-at-release");     # Boolean. If true dropped weapons will ignore sideslip and AOA and start flying in aircraft bore direction.
		m.lateralSpeed          = getprop(m.nodeString~"lateral-dps");                # Lateral speed in degrees per second. This is mostly for cosmetics.
		# detonation
		m.weight_whead_lbm      = getprop(m.nodeString~"weight-warhead-lbs");         # warhead weight
		m.arming_time           = getprop(m.nodeString~"arming-time-sec");            # time for weapon to arm
		m.selfdestruct_time     = getprop(m.nodeString~"self-destruct-time-sec");     # time before selfdestruct
		m.destruct_when_free    = getprop(m.nodeString~"self-destruct-at-lock-lost"); # selfdestruct if lose target
		m.reportDist            = getprop(m.nodeString~"max-report-distance");        # Interpolation hit: max distance from target it report it exploded, not passed. Trig hit: Distance where it will trigger.
		m.multiHit				= getprop(m.nodeString~"hit-everything-nearby");      # bool. Only works well for slow moving targets. Needs you to pass contacts to release().
		m.inert                 = getprop(m.nodeString~"inert");                      # bool. If the weapon is inert and will not detonate. [optional]
		m.triggerAlgorithm      = getprop(m.nodeString~"trigger-algorithm");          # proximity or passing. [optional, if left out "payload/armament/hit-interpolation" will be used]
		# avionics sounds
		m.vol_search            = getprop(m.nodeString~"vol-search");                 # sound volume when searcing
		m.vol_track             = getprop(m.nodeString~"vol-track");                  # sound volume when having lock
		#m.vol_track_weak        = getprop(m.nodeString~"vol-track-weak");             # sound volume before getting solid lock
		# launching conditions
        m.rail                  = getprop(m.nodeString~"rail");                       # if the weapon is rail or tube fired set to true. If dropped 7ft before ignited set to false.
        m.rail_dist_m           = getprop(m.nodeString~"rail-length-m");              # length of tube/rail
        m.rail_forward          = getprop(m.nodeString~"rail-point-forward");         # true for rail, false for rail/tube with a pitch
        m.rail_pitch_deg        = getprop(m.nodeString~"rail-pitch-deg");             # Only used when rail is not forward. 90 for vertical tube.
        m.drop_time             = getprop(m.nodeString~"drop-time");                  # Time to fall before stage 1 thrust starts.
        m.deploy_time           = getprop(m.nodeString~"deploy-time");                # Time to deploy wings etc. Time starts when drop ends or rail passed.
        m.no_pitch              = getprop(m.nodeString~"pitch-animation-disabled");   # bool
        # counter-measures
        m.chaffResistance       = getprop(m.nodeString~"chaff-resistance");           # Float 0-1. Amount of resistance to chaff. Default 0.950. [optional]
        m.flareResistance       = getprop(m.nodeString~"flare-resistance");           # Float 0-1. Amount of resistance to flare. Default 0.950. [optional]
        # data-link to launch platform
        m.data                  = getprop(m.nodeString~"telemetry");                  # Boolean. Data link back to aircraft when missile is flying. [optional]
        m.dlz_enabled           = getprop(m.nodeString~"DLZ");                        # Supports dynamic launch zone info. For now only works with A/A. [optional]
        m.dlz_opt_alt           = getprop(m.nodeString~"DLZ-optimal-alt-feet");       # Minimum altitude required to hit the target at max range.
        m.dlz_opt_mach          = getprop(m.nodeString~"DLZ-optimal-closing-mach");   # Closing speed required to hit the target at max range at minimum altitude.
		

        
        m.mode_slave            = TRUE;# if slaved to command seeker directions from radar/helmet/cursor
        m.mode_bore             = FALSE;# if locked to bore locks only
        m.caged                 = TRUE;# if gyro is caged
        m.uncage_auto           = TRUE;# will uncage when lock achieved
        m.seeker_dir_heading    = 0;# where seeker is looking (before release)
        m.seeker_dir_pitch      = 0;
        m.command_dir_heading   = 0;# where seeker is commanded in slave mode to look
        m.command_dir_pitch     = 0;
        m.contacts              = [];# contacts that should be considered to lock onto. In slave it will only lock to the first.
        m.warm                  = 1;# normalized warm/cold
        m.ready_standby_time    = 0;# time when started from standby
        m.cooling               = FALSE;
        m.command_tgt           = TRUE;
        m.patternDirY           = 1;
        m.patternDirX           = 1;
        m.pattern_last_time     = 0;
        m.seeker_last_time      = 0;
        m.seeker_elev           = 0;
        m.seeker_head           = 0;
        m.cooling_last_time     = 0;
        m.cool_total_time       = 0;
        m.patternPitchUp        = 2.5;
		m.patternPitchDown      = -15;
		m.patternYaw            = 8.5;

		if (m.triggerAlgorithm == "proximity") {
			m.useHitInterpolation = FALSE;
		} elsif (m.triggerAlgorithm == "passing") {
			m.useHitInterpolation = TRUE;
		}
        if (m.detect_range_nm == nil) {
          # backwards compatibility
          m.detect_range_nm = m.max_fire_range_nm;
        }
        if (m.max_seeker_dev == nil) {
        	m.max_seeker_dev = 15;
        }
        if (m.beam_width_deg == nil) {
          m.beam_width_deg = 4;
        } 
        m.beam_width_deg *= 0.5;
        m.detect_range_curr_nm  = m.detect_range_nm;

        if (m.ready_time == nil) {
        	m.ready_time = 0;
        }
        if (m.coolable == nil) {
        	m.coolable = FALSE;
        }
        if (m.intoBore == nil) {
        	m.intoBore = FALSE;
        }

        if (m.lateralSpeed == nil) {
        	m.lateralSpeed = 0;
        }

        if(m.maxPitch == nil) {
        	m.maxPitch = 90;
        }

        if(m.loal == nil) {
        	m.loal = FALSE;
        }

        if(m.Cd_delta == nil) {
        	m.Cd_delta = 0;
        }

        if(m.canSwitch == nil) {
        	m.canSwitch = FALSE;
        }
        
        # three variables used for trigonometry hit calc:
		m.vApproch       = 1;
        m.tpsApproch     = 0;
        m.usedChance     = FALSE;

        if (m.weight_fuel_lbm == nil) {
			m.weight_fuel_lbm = 0;
		}
		if (m.data == nil) {
        	m.data = FALSE;
        }
        if (m.vector_thrust == nil) {
        	m.vector_thrust = FALSE;
        }
        if (m.flareResistance == nil) {
        	m.flareResistance = 0.95;
        }
        if (m.chaffResistance == nil) {
        	m.chaffResistance = 0.95;
        }
        if (m.pro_constant == nil) {
        	m.pro_constant = 3;
        }
        if (m.force_lbf_1 == nil or m.force_lbf_1 == 0) {
        	m.force_lbf_1 = 0;
        	m.stage_1_duration = 0;
        }
        if (m.force_lbf_2 == nil or m.force_lbf_2 == 0) {
        	m.force_lbf_2 = 0;
        	m.stage_2_duration = 0;
        }
        if (m.guidanceLaw == nil) {
			m.guidanceLaw = "APN";
		}
		if (m.destruct_when_free == nil) {
			m.destruct_when_free = FALSE;
		}
		if (m.reaquire == nil) {
			if (m.guidance == "semi-radar" or m.guidance == "laser" or m.guidance == "heat" or m.guidance == "vision") {
				m.reaquire = TRUE;
			} else {
				m.reaquire = FALSE;
			}
		}
		if (m.rail == TRUE) {
			# drop distance in time
			m.drop_time = 0;
		} elsif (m.drop_time == nil) {
			m.drop_time = math.sqrt(2*7/g_fps);# time to fall 7 ft to clear aircraft
		}
		if (m.deploy_time == nil) {
			m.deploy_time = 0.3;
		}
		if(m.typeLong == nil) {
			m.typeLong = m.type;
		}
		if(m.typeShort == nil) {
			m.typeShort = m.type;
		}
		if (m.standbyFlight == nil) {
			m.standbyFlight = "unguided";
		}
		if(m.switchTime == nil) {
			m.switchTime = m.beam_width_deg*m.max_seeker_dev*0.05;
		}
		if(m.multiHit == nil) {
			m.multiHit = FALSE;
		}
		if(m.inert == nil) {
			m.inert = FALSE;
		}
		if(m.engineEnabled == nil) {
			m.engineEnabled = TRUE;
		}
		if(m.guidanceEnabled == nil) {
			m.guidanceEnabled = TRUE;
		}
		if (m.no_pitch == nil) {
        	m.no_pitch = 0;
        }

        m.useModelCase          = getprop("payload/armament/modelsUseCase");
        m.useModelUpperCase     = getprop("payload/armament/modelsUpperCase");
        m.weapon_model_type     = type;
        if (m.useModelCase == TRUE) {
        	if (m.useModelUpperCase == TRUE) {
        		m.weapon_model_type     = string.uc(type);
    		} else {
    			m.weapon_model_type     = m.type_lc;
    		}
        }
		m.weapon_model          = getprop("payload/armament/models")~m.weapon_model_type~"/"~m.type_lc~"-";
		m.weapon_model2          = getprop("payload/armament/models")~m.weapon_model_type~"/"~m.type_lc;

		m.mpLat          = getprop("payload/armament/MP-lat");# properties to be used for showing missile over MP.
		m.mpLon          = getprop("payload/armament/MP-lon");
		m.mpAlt          = getprop("payload/armament/MP-alt");
		m.mpShow = FALSE;
		if (m.mpLat != nil and m.mpLon != nil and m.mpAlt != nil) {
			m.mpLat          = props.globals.getNode(m.mpLat, FALSE);
			m.mpLon          = props.globals.getNode(m.mpLon, FALSE);
			m.mpAlt          = props.globals.getNode(m.mpAlt, FALSE);
			if (m.mpLat != nil and m.mpLon != nil and m.mpAlt != nil) {
				m.mpShow = TRUE;
			}
		}

		m.elapsed_last          = 0;

		m.target_air = find("A", m.class)==-1?FALSE:TRUE;
		m.target_sea = find("M", m.class)==-1?FALSE:TRUE;#use M for marine, since S can be confused with surface.
		m.target_gnd = find("G", m.class)==-1?FALSE:TRUE;

		# Find the next index for "models/model" and create property node.
		# Find the next index for "ai/models/aim-9" and create property node.
		# (M. Franz, see Nasal/tanker.nas)
		var n = props.globals.getNode("models", 1);
		var i = 0;
		for (i = 0; 1==1; i += 1) {
			if (n.getChild("model", i, 0) == nil) {
				break;
			}
		}
		m.model = n.getChild("model", i, 1);
		
		n = props.globals.getNode("ai/models", 1);
		for (i = 0; 1==1; i += 1) {
			if (n.getChild(m.type_lc, i, 0) == nil) {
				break;
			}
		}
		m.ai = n.getChild(m.type_lc, i, 1);
		if(m.data == TRUE) {
			m.ai.getNode("ETA", 1).setIntValue(-1);
			m.ai.getNode("hit", 1).setIntValue(-1);
		}
		m.ai.getNode("valid", 1).setBoolValue(0);
		m.ai.getNode("name", 1).setValue(type);
		m.ai.getNode("sign", 1).setValue(sign);
		m.ai.getNode("callsign", 1).setValue(type);
		m.ai.getNode("missile", 1).setBoolValue(1);
		#m.model.getNode("collision", 1).setBoolValue(0);
		#m.model.getNode("impact", 1).setBoolValue(0);
		if (m.useSingleFile == FALSE) {
			var id_model = m.weapon_model ~ m.ID ~ ".xml";
			m.model.getNode("path", 1).setValue(id_model);
		} else {
			var id_model = m.weapon_model2~".xml";
			m.model.getNode("path", 1).setValue(id_model);
			print("Attempting to load "~id_model);
		}
		m.life_time = 0;

		# Create the AI position and orientation properties.
		m.latN   = m.ai.getNode("position/latitude-deg", 1);
		m.lonN   = m.ai.getNode("position/longitude-deg", 1);
		m.altN   = m.ai.getNode("position/altitude-ft", 1);
		m.hdgN   = m.ai.getNode("orientation/true-heading-deg", 1);
		m.pitchN = m.ai.getNode("orientation/pitch-deg", 1);
		m.rollN  = m.ai.getNode("orientation/roll-deg", 1);

		m.ac      = nil;

		m.coord               = geo.Coord.new().set_latlon(0, 0, 0);
		m.last_coord          = nil;
		m.before_last_coord   = nil;
		m.t_coord             = nil;
		m.last_t_coord        = m.t_coord;
		m.before_last_t_coord = nil;

		m.speed_down_fps  = nil;
		m.speed_east_fps  = nil;
		m.speed_north_fps = nil;
		m.alt_ft          = nil;
		m.pitch           = nil;
		m.hdg             = nil;

		# Nikolai V. Chr.
		# The more variables here instead of declared locally, the better for performance.
		# Due to garbage collector.
		#


		m.density_alt_diff   = 0;
		m.max_g_current      = m.max_g;
		m.old_speed_horz_fps = nil;
		m.paused             = 0;
		m.old_speed_fps	     = 0;
		m.dt                 = 0;
		m.g                  = 0;
		m.limitGs            = FALSE;

		# navigation and guidance
		m.last_deviation_e       = nil;
		m.last_deviation_h       = nil;
		m.last_track_e           = 0;
		m.last_track_h           = 0;
		m.guiding                = TRUE;
		m.t_alt                  = 0;
		m.dist_curr              = 0;
		m.dist_curr_direct       = -1;
		m.t_elev_deg             = 0;
		m.t_course               = 0;
		m.t_heading              = nil;
		m.t_pitch                = nil;
		m.t_speed_fps            = nil;
		m.dist_last              = nil;
		m.dist_direct_last       = nil;
		m.last_t_course          = nil;
		m.last_t_elev_deg        = nil;
		m.last_cruise_or_loft    = FALSE;
		m.last_t_norm_speed      = nil;
		m.last_t_elev_norm_speed = nil;
		m.last_dt                = 0;
		m.dive_token             = FALSE;
		m.raw_steer_signal_elev  = 0;
		m.raw_steer_signal_head  = 0;
		m.cruise_or_loft         = FALSE;
		m.curr_deviation_e       = 0;
		m.curr_deviation_h       = 0;
		m.track_signal_e         = 0;
		m.track_signal_h         = 0;

		# cruise-missiles
		m.nextGroundElevation = 0; # next Ground Elevation
		m.nextGroundElevationMem = [-10000, -1];
		m.terrainStage = 0;

		#rail
		m.rail_passed = FALSE;
		m.x = 0;
		m.y = 0;
		m.z = 0;
		m.rail_pos = 0;
		m.rail_speed_into_wind = 0;
		m.rail_passed_time = nil;
		m.deploy = 0;

		# stats
		m.maxFPS       = 0;
		m.maxMach      = 0;
		m.maxMach1     = 0;#stage 1
		m.maxMach2     = 0;#stage 2
		m.maxMach3     = 0;#stage 2 end
		m.energyBleedKt = 0;

		m.flareLast = 0;
		m.flareTime = 0;
		m.flareLock = FALSE;
		m.chaffLast = 0;
		m.chaffTime = 0;
		m.chaffLock = FALSE;
		m.flarespeed_fps = nil;
		
		m.explodeSound = TRUE;
		m.first = FALSE;

		# these 4 is used for limiting spam to console:
		m.heatLostLock = FALSE;
		m.semiLostLock = FALSE;
		m.radLostLock  = FALSE;
		m.tooLowSpeed  = FALSE;
		m.lostLOS      = FALSE;

		m.prevTarget   = nil;
		m.prevGuidance = nil;
		m.keepPitch    = 0;

		# LOAL
		m.newTargetAssigned = FALSE;
		m.switchIndex = 0;
		m.hasGuided = FALSE;
		m.fovLost = FALSE;
		m.maddog = FALSE;
		m.nextFovCheck = m.switchTime;
		m.observing = m.guidance;

		m.SwSoundOnOff.setBoolValue(FALSE);
		#m.SwSoundFireOnOff.setBoolValue(FALSE);
		m.SwSoundVol.setDoubleValue(m.vol_search);
		#me.trackWeak = 1;
		m.pendingSound = -1;

		m.horz_closing_rate_fps = -1;

		m.standby();# these loops will run until released or deleted.

		#for multithreading
		m.frameToggle = thread.newsem();
		m.myMath = {parents:[vector.Math],};#personal vector library, to avoid using a mutex on it.

		return AIM.active[m.ID] = m;
	},
	
	del: func {
		# can be called at any time, before or during flight.
		#
		# stop semaphore counting up, and escape flight loop if its running.
		#
		# Note: Must never be called from the flight loop thread.
		#
		me.printCode("deleted weapon");
		me.deleted = TRUE;
		thread.semup(me.frameToggle);
		if (me.first == TRUE) {
			me.resetFirst();
		}
		me.model.remove();
		me.ai.remove();
		if (me.status == MISSILE_FLYING) {
			delete(AIM.flying, me.flyID);
		} else {
			delete(AIM.active, me.ID);
		}
		me.SwSoundVol.setDoubleValue(0);
	},

	getCCRP: func (maxFallTime_sec, timeStep) {
		# returns distance in meters to ideal release time.
		#
		# maxFallTime_sec: maximum allowed predicted falltime. Higher value will make method take more CPU time.
		# timeStep: Fidelity of prediction. Lower value will increase CPU consumption.
		#
		# Assumptions:
		#  Ordnance do not have propulsion
		#  Ordnance has very limited steering
		if (me.status != MISSILE_LOCK or me.Tgt == nil) {
			return nil;
		}
        me.ccrp_agl = (getprop("position/altitude-ft")-me.Tgt.get_altitude())*FT2M;
        #me.agl = getprop("position/altitude-agl-ft")*FT2M;
        me.ccrp_alti = getprop("position/altitude-ft")*FT2M;
        me.ccrp_roll = getprop("orientation/roll-deg");
        me.ccrp_vel = getprop("velocities/groundspeed-kt")*0.5144;#m/s
        me.ccrp_dens = getprop("sim/flight-model") == "jsb"?getprop("fdm/jsbsim/atmosphere/density-altitude"):getprop("position/altitude-ft");
        me.ccrp_mach = getprop("velocities/mach");
        me.ccrp_speed_down_fps = getprop("velocities/speed-down-fps");
		me.ccrp_speed_east_fps = getprop("velocities/speed-east-fps");
		me.ccrp_speed_north_fps = getprop("velocities/speed-north-fps");

        me.ccrp_t = 0.0;
        
        me.ccrp_altC = me.ccrp_agl;
        me.ccrp_vel_z = -me.ccrp_speed_down_fps*FT2M;#positive upwards
        me.ccrp_fps_z = -me.ccrp_speed_down_fps;
        me.ccrp_vel_x = math.sqrt(me.ccrp_speed_east_fps*me.ccrp_speed_east_fps+me.ccrp_speed_north_fps*me.ccrp_speed_north_fps)*FT2M;
        me.ccrp_fps_x = me.ccrp_vel_x * M2FT;

        me.ccrp_rs = me.rho_sndspeed(me.ccrp_dens-(me.ccrp_agl/2)*M2FT);
        me.ccrp_rho = me.ccrp_rs[0];
        me.ccrp_Cd = me.drag(me.ccrp_mach);
        me.ccrp_mass = me.weight_launch_lbm / slugs_to_lbm;
        me.ccrp_q = 0.5 * me.ccrp_rho * me.ccrp_fps_z * me.ccrp_fps_z;
        me.ccrp_deacc = (me.ccrp_Cd * me.ccrp_q * me.ref_area_sqft) / me.ccrp_mass;

        while (me.ccrp_altC > 0 and me.ccrp_t <= maxFallTime_sec) {
          me.ccrp_t += timeStep;
          me.ccrp_acc = -9.81 + me.ccrp_deacc * FT2M;
          me.ccrp_vel_z += me.ccrp_acc * timeStep;
          me.ccrp_altC = me.ccrp_altC + me.ccrp_vel_z*timeStep+0.5*me.ccrp_acc*timeStep*timeStep;
        }
        #printf("predict fall time=%0.1f", me.t);

        if (me.ccrp_t >= maxFallTime_sec) {
            return nil;
        }

        me.ccrp_q = 0.5 * me.ccrp_rho * me.ccrp_fps_x * me.ccrp_fps_x;
        me.ccrp_deacc = (me.ccrp_Cd * me.ccrp_q * me.ref_area_sqft) / me.ccrp_mass;
        me.ccrp_acc = -me.ccrp_deacc * FT2M;
        
        me.ccrp_fps_x_final = me.ccrp_t*me.ccrp_acc+me.ccrp_fps_x;# calc final horz speed
        me.ccrp_fps_x_average = (me.ccrp_fps_x-(me.ccrp_fps_x-me.ccrp_fps_x_final)*0.5);
        me.ccrp_mach_average = me.ccrp_fps_x_average / me.ccrp_rs[1];
        
        me.ccrp_Cd = me.drag(me.ccrp_mach_average);
        me.ccrp_q = 0.5 * me.ccrp_rho * me.ccrp_fps_x_average * me.ccrp_fps_x_average;
        me.ccrp_deacc = (me.ccrp_Cd * me.ccrp_q * me.ref_area_sqft) / me.ccrp_mass;
        me.ccrp_acc = -me.ccrp_deacc * FT2M;
        me.ccrp_dist = me.ccrp_vel_x*me.ccrp_t+0.5*me.ccrp_acc*me.ccrp_t*me.ccrp_t;

        me.ccrp_ac = geo.aircraft_position();
        me.ccrpPos = geo.Coord.new(me.ccrp_ac);

        # we calc heading from composite speeds, due to alpha and beta might influence direction bombs will fall:
        me.ccrp_vectorMag = math.sqrt(me.ccrp_speed_east_fps*me.ccrp_speed_east_fps+me.ccrp_speed_north_fps*me.ccrp_speed_north_fps);
        if (me.ccrp_vectorMag == 0) {
            me.ccrp_vectorMag = 0.0001;
        }
        me.ccrp_heading = -math.asin(me.ccrp_speed_north_fps/me.ccrp_vectorMag)*R2D+90;#divide by vector mag, to get normalized unit vector length
        if (me.ccrp_speed_east_fps/me.ccrp_vectorMag < 0) {
          me.ccrp_heading = -me.ccrp_heading;
          while (me.ccrp_heading > 360) {
            me.ccrp_heading -= 360;
          }
          while (me.ccrp_heading < 0) {
            me.ccrp_heading += 360;
          }
        }
        me.ccrpPos.apply_course_distance(me.ccrp_heading, me.ccrp_dist);
        #var elev = geo.elevation(ac.lat(), ac.lon());
        #printf("Will fall %0.1f NM ahead of aircraft.", me.dist*M2NM);
        me.ccrp_elev = me.ccrp_alti-me.ccrp_agl;#faster
        me.ccrpPos.set_alt(me.ccrp_elev);
        
        me.ccrp_distCCRP = me.ccrpPos.distance_to(me.Tgt.get_Coord());
        return me.ccrp_distCCRP;
	},

	getDLZ: func (ignoreLock = 0) {
		# call this only before release/eject
		if (me.dlz_enabled != TRUE) {
			return nil;
		} elsif (contact == nil or (me.status != MISSILE_LOCK and !ignoreLock)) {
			return [];
		}
		me.dlz_t_alt = contact.get_altitude();
		me.dlz_o_alt = ourAlt.getValue();
		me.dlz_t_rs = me.rho_sndspeed(me.dlz_t_alt);
		me.dlz_t_rho = me.dlz_t_rs[0];
		me.dlz_t_sound_fps = me.dlz_t_rs[1];
		me.dlz_tG    = me.maxG(me.dlz_t_rho, me.max_g);
		me.dlz_t_mach = contact.get_Speed()*KT2FPS/me.dlz_t_sound_fps;
		me.dlz_o_mach = getprop("velocities/mach");
		me.contactCoord = contact.get_Coord();
		me.vectorToEcho   = me.myMath.eulerToCartesian2(contact.get_bearing(), me.myMath.getPitch(geo.aircraft_position(), me.contactCoord));
    	me.vectorEchoNose = me.myMath.eulerToCartesian3X(contact.get_heading(), contact.get_Pitch(), contact.get_Roll());
    	me.angleToRear    = geo.normdeg180(me.myMath.angleBetweenVectors(me.vectorToEcho, me.vectorEchoNose));
    	me.abso           = math.abs(me.angleToRear)-90;
    	me.mach_factor    = math.sin(me.abso*D2R);
    	
    	me.dlz_CS         = me.mach_factor*me.dlz_t_mach+me.dlz_o_mach;

    	me.dlz_opt   = me.clamp(me.max_fire_range_nm *0.3* (me.dlz_o_alt/me.dlz_opt_alt) + me.max_fire_range_nm *0.2* (me.dlz_t_alt/me.dlz_opt_alt) + me.max_fire_range_nm *0.5* (me.dlz_CS/me.dlz_opt_mach),me.min_fire_range_nm,me.max_fire_range_nm);
    	me.dlz_nez   = me.clamp(me.dlz_opt * (me.dlz_tG/45), me.min_fire_range_nm, me.dlz_opt);
    	me.printStatsDetails("Dynamic Launch Zone reported (NM): Maximum=%04.1f Optimistic=%04.1f NEZ=%04.1f Minimum=%04.1f",me.max_fire_range_nm,me.dlz_opt,me.dlz_nez,me.min_fire_range_nm);
    	return [me.max_fire_range_nm,me.dlz_opt,me.dlz_nez,me.min_fire_range_nm,geo.aircraft_position().direct_distance_to(me.contactCoord)*M2NM];
	},

	setContacts: func (vect) {
		# sets a vector of contacts the weapons will try to lock onto
		# Before launch: for heatseekers in bore or unslaved mode
		# do NOT call this after launch
		# see also release(vect)
		me.contacts = vect;
	},

	commandDir: func (heading_deg, pitch_deg) {
		# commands are relative to aircraft bore
		if (me.status == MISSILE_FLYING or me.mode_slave == FALSE) return;
		me.command_dir_heading = heading_deg;
		me.command_dir_pitch = pitch_deg;
		me.command_tgt = FALSE;
		me.printCode("Slave command: heading %0.1f pitch %0.1f", heading_deg, pitch_deg);
	},

	commandRadar: func () {
		# command that radar is looking at a target, slave to that.
		if (me.status == MISSILE_FLYING or me.mode_slave == FALSE) return;
		me.command_dir_heading = nil;
		me.command_dir_pitch   = nil;
		me.command_tgt = TRUE;
		me.printCode("Slave command cheat");
	},

	getWarm: func () {
		return me.warm;
	},

	setCooling: func (cooling) {
		if (me.status == MISSILE_FLYING) return;
		if (me.cooling != cooling) {
			me.printCode("Cooling commanded: "~cooling);
			me.cooling = cooling;
			me.cooling_last_time = 0;
			#var time = getprop("sim/time/elapsed-sec");
		}
	},

	isCooling: func () {
		return me.cooling;
	},

	start: func {
		if (me.status == MISSILE_STANDBY) {
			me.status = MISSILE_STARTING;
			me.ready_standby_time = getprop("sim/time/elapsed-sec");
			if (me.ready_standby_time == 0) me.ready_standby_time = 0.001;
		}
	},

	stop: func {
		if (me.status != MISSILE_FLYING) {
			me.status = MISSILE_STANDBY;
		}
	},

	setSlave: func (slave) {
		if (me.status == MISSILE_FLYING) return;
		if (slave == TRUE and me.mode_bore == TRUE) {
			me.mode_bore = FALSE;
			me.printCode("Bore waivered");
		}
		me.mode_slave = slave;
		me.printCode("Slave: "~slave);
	},

	setBore: func (bore) {
		if (me.status == MISSILE_FLYING) return;
		if (bore == TRUE and me.mode_slave == TRUE) {
			me.mode_slave = FALSE;
			me.printCode("Slave waivered");
		}
		me.mode_bore  = bore;
		me.printCode("Bore: "~bore);
	},

	isBore: func () {
		return me.mode_bore;
	},

	isSlave: func () {
		return me.mode_slave;
	},

	isCaged: func () {
		return me.caged;
	},

	isAutoUncage: func () {
		return me.uncage_auto;
	},

	setAutoUncage: func (auto) {
		if (me.status == MISSILE_FLYING) return;
		me.uncage_auto = auto;
		me.printCode("Cage auto: "~auto);
	},

	setCaged: func (cage) {
		if (me.status == MISSILE_FLYING) return;
		me.caged = cage;
		me.printCode("Cage: "~cage);
	},

	setUncagedPattern: func (yaw, pitchUp, pitchDown) {
		if (me.status == MISSILE_FLYING) return;
		me.patternYaw       = yaw;
		me.patternPitchUp   = pitchUp;
		me.patternPitchDown = pitchDown;
	},

	getSeekerInfo: func {
		if (me.status == MISSILE_FLYING or me.status == MISSILE_STANDBY) {
			return nil;
		}
		return [me.seeker_head, me.seeker_elev];
	},

	eject: func () {
		me.stage_1_duration = 0;
		me.force_lbf_1      = 0;
		me.stage_2_duration = 0;
		me.force_lbf_2      = 0;
		me.inert            = TRUE;
		me.engineEnabled    = FALSE;
		me.guidanceEnabled  = FALSE;
		me.rail             = FALSE;
		me.releaseAtNothing();
	},

	releaseAtNothing: func() {
		me.Tgt = nil;
		me.release();
	},

	release: func(vect=nil) {
		# Release missile/bomb from its pylon/rail/tube and send it away.
		#
		if (vect!= nil) {
			
			# sets a vector of contacts the weapons will try to lock onto
			# For LOAL weapons.
			# see also setContacts()
			me.contacts = vect;
		} else {
			me.contacts = [];
		}
		if(!me.engineEnabled) {
			me.SwSoundFireOnOff.setBoolValue(FALSE);
			me.pendingSound = -1;
		} else {
			me.SwSoundFireOnOff.setBoolValue(FALSE);
			me.pendingSound = 2;
		}
		me.status = MISSILE_FLYING;
		me.flyID = rand();
		AIM.flying[me.flyID] = me;
		delete(AIM.active, me.ID);
		me.animation_flags_props();

		# Get the A/C position and orientation values.
		me.ac = geo.aircraft_position();
		me.ac_init = geo.Coord.new(me.ac);
		var ac_roll = OurRoll.getValue();# positive is banking right
		var ac_pitch = OurPitch.getValue();
		var ac_hdg   = OurHdg.getValue();

		if (me.rail == TRUE) {
			if (me.rail_forward == FALSE) {
				ac_pitch = ac_pitch + me.rail_pitch_deg;
			}
		}

		# Compute missile initial position relative to A/C center
		if (me.nasalPosition == nil) {
			me.x = me.pylon_prop.getNode("offsets/x-m").getValue();
			me.y = me.pylon_prop.getNode("offsets/y-m").getValue();
			me.z = me.pylon_prop.getNode("offsets/z-m").getValue();
		} else {
			me.x = me.nasalPosition[0];
			me.y = me.nasalPosition[1];
			me.z = me.nasalPosition[2];
		}
		var init_coord = nil;
		if (me.rail == TRUE) {
			if (me.rail_forward == FALSE and me.rail_pitch_deg != 90) {
				# polar pylon coords:
				me.rail_dist_origin = math.sqrt(me.x*me.x+me.z*me.z);
				if(me.rail_dist_origin==0){
					me.x = 0.0;
					me.z = 0.0;
				} else {
					me.rail_origin_angle_rad = math.acos(me.clamp(me.x/me.rail_dist_origin,-1,1))*(me.z<0?-1:1);
					# since we cheat by rotating entire launcher, we must calculate new pylon positions after the rotation:
					me.x = me.rail_dist_origin*math.cos(me.rail_origin_angle_rad+me.rail_pitch_deg*D2R);
					me.z = me.rail_dist_origin*math.sin(me.rail_origin_angle_rad+me.rail_pitch_deg*D2R);
				}
			}
		}
		if (offsetMethod == TRUE and (me.rail == FALSE or me.rail_forward == TRUE)) {
			var pos = aircraftToCart({x:-me.x, y:me.y, z: -me.z});
			init_coord = geo.Coord.new();
			init_coord.set_xyz(pos.x, pos.y, pos.z);
		} else {
			init_coord = me.getGPS(me.x, me.y, me.z, ac_pitch);
		}	


		# Set submodel initial position:
		var mlat = init_coord.lat();
		var mlon = init_coord.lon();
		var malt = init_coord.alt() * M2FT;
		me.latN.setDoubleValue(mlat);
		me.lonN.setDoubleValue(mlon);
		me.altN.setDoubleValue(malt);
		me.hdgN.setDoubleValue(ac_hdg);

		me.pitchN.setDoubleValue(ac_pitch);
		me.rollN.setDoubleValue(0);

		me.coord = geo.Coord.new(init_coord);
		# Get target position.
		if (me.Tgt != nil) {
			me.t_coord = me.Tgt.get_Coord();
			me.maddog = FALSE;
			me.newTargetAssigned = TRUE;
		} else {
			me.maddog = TRUE;
		}

		me.model.getNode("latitude-deg-prop", 1).setValue(me.latN.getPath());
		me.model.getNode("longitude-deg-prop", 1).setValue(me.lonN.getPath());
		me.model.getNode("elevation-ft-prop", 1).setValue(me.altN.getPath());
		me.model.getNode("heading-deg-prop", 1).setValue(me.hdgN.getPath());
		me.model.getNode("pitch-deg-prop", 1).setValue(me.pitchN.getPath());
		me.model.getNode("roll-deg-prop", 1).setValue(me.rollN.getPath());
		var loadNode = me.model.getNode("load", 1);
		loadNode.setBoolValue(1);

		# Get initial velocity vector (aircraft):
		me.speed_down_fps = getprop("velocities/speed-down-fps");
		me.speed_east_fps = getprop("velocities/speed-east-fps");
		me.speed_north_fps = getprop("velocities/speed-north-fps");
		if (me.rail == TRUE) {
			if (me.rail_forward == FALSE) {
				if (me.rail_pitch_deg == 90) {
					# rail is actually a tube pointing upward
					me.rail_speed_into_wind = -getprop("velocities/wBody-fps");# wind from below
				} else {
					#does not account for incoming airstream, yet.
					me.rail_speed_into_wind = 0;
				}
			} else {
				# rail is pointing forward
				me.rail_speed_into_wind = getprop("velocities/uBody-fps");# wind from nose
			}
		} elsif (me.intoBore == FALSE) {
			# to prevent the missile from falling up, we need to sometimes pitch it into wind:
			var h_spd = math.sqrt(me.speed_east_fps*me.speed_east_fps + me.speed_north_fps*me.speed_north_fps);
			#var t_spd = math.sqrt(me.speed_down_fps*me.speed_down_fps + h_spd*h_spd);
			var wind_pitch = math.atan2(-me.speed_down_fps, h_spd) * R2D;
			if (wind_pitch < ac_pitch) {
				# super hack, and might temporary as missile leaves launch platform look stupid:
				ac_pitch = wind_pitch;
				# this should really take place over a duration instead of instantanious.
			}
			if (h_spd != 0) {
				# will turn weapon into wind
				# (not sure this is a good idea..might lose lock immediatly if firing with a big AoA,
				# but then on other hand why would you do that, unless in dogfight, and there you use aim9 anyway,
				# which is always on rails, and dont have this issue)
				#
				# what if heavy cross wind and fires level. Then it can fly maybe 10 degs offbore, and will likely lose its lock.
				#
				ac_hdg = math.asin(me.speed_east_fps/h_spd)*R2D;
				if (me.speed_north_fps < 0) {
					if (ac_hdg >= 0) {
						ac_hdg = 180-ac_hdg;
					} else {
						ac_hdg = -180-ac_hdg;
					}
				}
				ac_hdg = geo.normdeg(ac_hdg);
			}
		}

		me.alt_ft = malt;
		me.pitch = ac_pitch;
		me.hdg = ac_hdg;

		me.keepPitch = me.pitch;

		if (getprop("sim/flight-model") == "jsb") {
			# currently not supported in Yasim
			me.density_alt_diff = getprop("fdm/jsbsim/atmosphere/density-altitude") - me.ac.alt()*M2FT;
		}

		# setup lofting and cruising
		me.snapUp = me.loft_alt > 10000;
		me.rotate_token = FALSE;
		#if (me.Tgt != nil and me.snapUp == TRUE) {
			#var dst = me.coord.distance_to(me.Tgt.get_Coord()) * M2NM;
			#
			#f(x) = y1 + ((x - x1) / (x2 - x1)) * (y2 - y1)
#				me.loft_alt = me.loft_alt - ((me.max_fire_range_nm - 10) - (dst - 10))*500; original code
#				me.loft_alt = 0+((dst-38)/(me.max_fire_range_nm-38))*(me.loft_alt-36000);   originally for phoenix missile
#			me.loft_alt = 0+((dst-10)/(me.max_fire_range_nm-10))*(me.loft_alt-0);           also doesn't really work
#			me.loft_alt = me.clamp(me.loft_alt, 0, 200000);
			#me.printGuide(sprintf("Loft to max %5d ft.", me.loft_alt));
		#}


		me.SwSoundVol.setDoubleValue(0);
		#me.trackWeak = 1;
		if (use_fg_default_hud) {
		  settimer(func { HudReticleDeg.setValue(0) }, 2);
		  interpolate(HudReticleDev, 0, 2);
		}

		me.startMach = getprop("velocities/mach");
		me.startFPS = getprop("velocities/groundspeed-kt")*KT2FPS;
		me.startAlt  = getprop("position/altitude-ft");
		me.startDist = -1;
		me.maxAlt = me.startAlt;
		if (me.Tgt != nil) {
			me.startDist = me.ac_init.direct_distance_to(me.Tgt.get_Coord());
		}
		me.printStats("Launch %s at %s.", me.type, me.callsign);

		me.weight_current = me.weight_launch_lbm;
		me.mass = me.weight_launch_lbm / slugs_to_lbm;

		# find the fuel consumption - lbm/sec
		var impulse1 = me.force_lbf_1 * me.stage_1_duration; # lbf*s
		var impulse2 = me.force_lbf_2 * me.stage_2_duration; # lbf*s
		me.impulseT = impulse1 + impulse2;                  # lbf*s
		me.fuel_per_impulse = me.weight_fuel_lbm / me.impulseT;# lbm/(lbf*s)
		me.fuel_per_sec_1  = (me.fuel_per_impulse * impulse1) / me.stage_1_duration;# lbm/s
		me.fuel_per_sec_2  = (me.fuel_per_impulse * impulse2) / me.stage_2_duration;# lbm/s

		me.printExtendedStats();


		# find the sun:
		var sun_x = getprop("ephemeris/sun/local/x");
		var sun_y = getprop("ephemeris/sun/local/y");# unit vector pointing to sun in geocentric coords
		var sun_z = getprop("ephemeris/sun/local/z");
		if (sun_x != nil) {
			me.sun_enabled = TRUE;
			me.sun = geo.Coord.new();
			me.sun.set_xyz(me.ac_init.x()+sun_x*2000000, me.ac_init.y()+sun_y*2000000, me.ac_init.z()+sun_z*2000000);#heat seeking missiles don't fly far, so setting it 2000Km away is fine.
		} else {
			# old FG versions does not supply location of sun. So this feature gets disabled.
			me.sun_enabled = FALSE;
		}

		me.lock_on_sun = FALSE;

		loadNode.remove();

		# lets run the main flight loop in its own thread:
		var frameTrigger = func {
			thread.semup(me.frameToggle);
			if (me.deleted == FALSE) {
				settimer(frameTrigger, 0);
			}
		}
		settimer(frameTrigger, 0);
		spawn(me.flight, me)();
#		me.ai.getNode("valid").setBoolValue(1);
	},

	################################################## DO NOT EXTERNALLY CALL ANYTHING BELOW THIS LINE ###################################

	printExtendedStats: func {
		if (!DEBUG_STATS) return;

		var classes = "";
		var classesSep = "";
		if (me.target_air) {
			classes = classes~"Airborne";
			classesSep = ", ";
		}
		if (me.target_gnd) {
			classes = classes~classesSep~"Ground";
			classesSep = ", ";
		}
		if (me.target_sea) {
			classes = classes~classesSep~"Ship";
		}
		var cooling = me.coolable?"YES":"NO";
		var rea = me.reaquire?"YES":"NO";
		var asp = "";
		if (me.guidance=="heat") {
			if (!me.all_aspect) {
				asp = "Rear aspect only.";
			} else {
				asp = "All aspect.";
			}
		}
		var nav = "";
		var nav2 = "";
		if (me.guidanceLaw == "direct") {
			nav = "Pure pursuit."
		} elsif (me.guidanceLaw == "PN") {
			nav = "Proportional navigation. Proportionality constant is "~me.pro_constant;
		} elsif (me.guidanceLaw == "APN") {
			nav = "Augmented proportional navigation. Proportionality constant is "~me.pro_constant;
		} elsif (left(me.guidanceLaw,2) == "PN") {
			nav = "Proportional navigation. Proportionality constant is "~me.pro_constant;
			var xxyy = right(me.guidanceLaw,4);
			var yy = right(xxyy,2);
			var xx = left(xxyy,2);
			nav2 = sprintf("Before PN it will aim %d degrees above target for %d seconds.",xx,yy);
		} elsif (left(me.guidanceLaw,3) == "APN") {
			nav = "Augmented proportional navigation. Proportionality constant is "~me.pro_constant;
			var xxyy = right(me.guidanceLaw,4);
			var yy = right(xxyy,2);
			var xx = left(xxyy,2);
			nav2 = sprintf("Before APN it will aim %d degrees above target for %d seconds.",xx,yy);
		}
		var stages = 0;
		if (me.force_lbf_1 > 0 and me.stage_1_duration > 0 and me.force_lbf_2 > 0 and me.stage_2_duration > 0) {
			stages = 2;
		} elsif (me.force_lbf_1 > 0 and me.stage_1_duration > 0) {
			stages = 1;
		}
		var vector = "No vectored thrust.";
		if (me.vector_thrust) {
			vector = "Vectored thrust."
		}

		
		me.printStats("****************************************************");
		me.printStats("Stats for %s", me.typeLong);
		me.printStats("DETECTION AND FIRING:");
		me.printStats("Fire range %.1f-%.1f NM", me.min_fire_range_nm, me.max_fire_range_nm);
		me.printStats("Can be fired againts %s targets", classes);
		me.printStats("Pilot will call out %s when firing.",me.brevity);
		me.printStats("Launch platform detection field of view is +-%d degrees.",me.fcs_fov);
		if (me.guidance =="heat") {
			me.printStats("Seekerhead beam width is %.1f degrees diameter.",me.beam_width_deg);
		}
		me.printStats("Weapons takes %.1f seconds to get ready.",me.ready_time);
		me.printStats("Cooling supported: %s",cooling);
		if (me.coolable) {
			me.printStats("Time to cool %.1f seconds. Can be kept cool for %d seconds.",me.cool_time,me.cool_duration);
			me.printStats("Max detect range when warm is %.1f NM, when cold %.1f NM.",me.warm_detect_range_nm, me.detect_range_nm);
			me.printStats("Current temperature is %d%%, which means seeker detection range of %.1f NM.", me.warm*100, me.detect_range_curr_nm);
		}
		if (me.maddog) {
			me.printStats("Has currently no lock on anything.");
		}
		if (me.loal) {
			me.printStats("Lock on after launch supported if fired without lock.");
		} else {
			me.printStats("Lock on after launch disabled.");
		}
		if (me.canSwitch and me.reaquire) {
			me.printStats("Can switch target mid-flight by itself. Number of targets to choose from: "~size(me.contacts));
		} else {
			me.printStats("Will not switch target mid-flight by itself.");
		}
		if (me.loal or (me.canSwitch and me.reaquire)) {
			me.printStats("Takes %.1f seconds to scan FoV, while flying, for new target.", me.switchTime);
		}
		me.printStats("NAVIGATION AND GUIDANCE:");
		me.printStats("Weapon field of view is +-%d degrees.",me.max_seeker_dev);
		me.printStats("Is %s guided. %s",me.guidance,asp);
		if (me.loal or (me.canSwitch and me.reaquire)) {
			me.printStats("When looking for target it is navigating by %s.", me.standbyFlight);
		}
		me.printStats("Guidance law: %s",nav);
		if (nav2 != "") {
			me.printStats(nav2);
		}
		me.printStats("Will attempt to reaquire target if its lost: %s",rea);
		if (me.guidance=="heat" or me.guidance=="vision") {
			me.printStats("Seeker is able to track targets moving in its FoV at %.1f degrees per second.",me.angular_speed);
		}
		if (me.guidance=="heat") {
			me.printStats("Seeker will lock on sun if it is within %.1f degrees.",me.sun_lock);
		}
		if (me.loft_alt>10000) {
			me.printStats("Weapon will max snap up to %d feet altitude.",me.loft_alt);
		} elsif (me.loft_alt<10000 and me.loft_alt!=0) {
			if (me.target_sea) {
				if (me.follow) {
					me.printStats("Weapon will follow terrain keeping %d AGL feet.",me.loft_alt);
				} else {
					me.printStats("Weapon will sea skim at %d AGL feet.",me.loft_alt);
				}
			} else {
				me.printStats("Weapon will follow terrain keeping %d AGL feet.",me.loft_alt);
			}
		} else {
			me.printStats("Weapon will not snap up, follow terrain or sea skim.");
		}
		if (!me.guidanceEnabled) {
			me.printStats("All guidance has been disabled, the weapon will not guide.");
		}
		me.printStats("After propulsion ends, it will max steer up to %d degree pitch.",me.maxPitch);
		if(me.Tgt == nil) {
			me.printStats("Note: Ordnance was released with no lock or destination target.");
		}
		if (stages > 0) {
			me.printStats("PROPULSION:");
			me.printStats("Stage 1: %d lbf for %.1f seconds.", me.force_lbf_1, me.stage_1_duration);
			if (stages > 1) {
				me.printStats("Stage 2: %d lbf for %.1f seconds.", me.force_lbf_2, me.stage_2_duration);
			}
			me.printStats("%s",vector);
			if (!me.weight_fuel_lbm) {
				me.printStats("Fuel system not simulated.");
			} else {
				me.printStats("Total fuel %d lbm.",me.weight_fuel_lbm);
				me.printStats("Specific Impulse is %.2f (lbf*s)/lbm. Total impulse: %.2f lbf*s.", 1/me.fuel_per_impulse, me.impulseT);
				# see how much energy/fuel the missile have. For solid fuel rockets, it is normally 200-280. Lower for smokeless, higher for smoke.
				if (me.weight_fuel_lbm > me.weight_launch_lbm) {
					me.printStats("ERROR: More fuel mass than entire weapon, please correct.");
				} else {
					me.printStats("Fuel is %.1f%% of weapons mass.", 100*me.weight_fuel_lbm/me.weight_launch_lbm);
				}
				if (1/me.fuel_per_impulse > 400) {
					me.printStats("WARNING: If this is rocket engine, it has way too much thrust.");
				} elsif (1/me.fuel_per_impulse > 350) {
					me.printStats("WARNING: If this is rocket engine, it most likely has too much thrust per fuel.");
				} elsif (1/me.fuel_per_impulse > 280) {
					me.printStats("If this is rocket engine, it has a very high thrust.");
				} elsif (1/me.fuel_per_impulse > 250) {
					me.printStats("If this is rocket engine, it is probably not smokeless.");
				} elsif (1/me.fuel_per_impulse > 200) {
					me.printStats("If this is rocket engine, it is probably smokeless.");
				} else {
					me.printStats("WARNING: If this is rocket engine, it probably has too little thrust.");
				}
			}
			if (!me.engineEnabled) {
				me.printStats("Engine is disabled and will not start/ignite.");
			}
		}

		me.printStats("AERODYNAMICS:");
		me.printStats("Full weight is %d lbm.", me.weight_launch_lbm);
		me.printStats("Drag coefficient is %.2f. Reference area is %.2f square feet.", me.Cd_base,me.ref_area_sqft);
		me.printStats("Total drag-area is %.3f. Use this number to compare with other weapons for drag estimation.",me.Cd_base*me.ref_area_sqft);
		me.printStats("Maximum structural g-force is %.1f",me.max_g);
		me.printStats("Minimum speed for steering is %.1f mach.",me.min_speed_for_guiding);
		me.printStats("Weapon will roll clockwise with %.1f degrees per second.", me.lateralSpeed);
		me.printStats("WARHEAD:");
		me.printStats("Warhead total weight is %.1f lbm.",me.weight_whead_lbm);
		me.printStats("Arming time is %.1f seconds.",me.arming_time);
		me.printStats("Will selfdestruct after %d seconds.",me.selfdestruct_time);
		if (me.multiHit) {
			me.printStats("When detonating, will hit everything nearby. Number of contacts to consider: %d", size(me.contacts));
		} else {
			me.printStats("When detonating, will only hit single target.");
		}
		if (me.destruct_when_free) {
			me.printStats("Will selfdestruct if loses lock.");
		}
		if (me.useHitInterpolation) {
			me.printStats("Will explode by proximity: %d meters from target.",me.reportDist);
		} else {
			me.printStats("Will explode as soon as within %d meters of target.",me.reportDist);
		}
		if (me.inert) {
			me.printStats("Warhead is inert though and will not detonate.");
		}
		me.printStats("LAUNCH CONDITIONS:");
		if (me.rail) {
			me.printStats("Weapon is fired from rail/tube of length %.1f meters.",me.rail_dist_m);
			if (me.rail_forward) {
				me.printStats("Launch direction is forward.");
			} else {
				me.printStats("Launch direction is %d degrees upward.", me.rail_pitch_deg);
			}
		} else {
			me.printStats("Weapon is dropped from launcher. Dropping for %.1f seconds.",me.drop_time);#todo
			me.printStats("After drop it takes %.1f seconds to deploy wings.",me.deploy_time);#todo
		}
		if (me.guidance == "heat" or me.guidance == "radar" or me.guidance == "semi-radar") {
			me.printStats("COUNTER-MEASURES:");
			if (me.guidance == "radar" or me.guidance == "semi-radar") {
				me.printStats("Resistance to chaff is %d%%.",me.chaffResistance*100);
			} elsif (me.guidance == "heat") {
				me.printStats("Resistance to flares is %d%%.",me.flareResistance*100);
			}
		}
		if (me.intoBore) {
			me.printStats("Weapon will be unaffected by wind when released.");
		} else {
			me.printStats("Weapon will be turn into airstream when released.");
		}
		me.printStats("MISC:");
		if (me.data) {
			me.printStats("Will transmit telemetry data back to launch platform.");
		} else {
			me.printStats("Has no data connection to launch platform when launched.");
		}
		if (me.dlz_enabled) {
			me.printStats("Dynamic launch zone support enabled.");
			me.printStats("Missile will likely hit when fired at max range when closing speed is %.2f mach at %d feet.", me.dlz_opt_mach, me.dlz_opt_alt);
		} else {
			me.printStats("Dynamic launch zone support disabled.");
		}
		me.printStats("****************************************************");
	},

	flight: func {

		while(1==1) {
			if(me.deleted == TRUE) {
				return;
			}
			thread.semdown(me.frameToggle);
			if(me.deleted == TRUE) {
				return;
			}
		#############################################################################################################
		#
		#
		#
		#                                                              MAIN FLIGHT LOOP
		#
		#
		#
		#############################################################################################################
		me.pendingSound -= 1;
		if(me.pendingSound == 0) {
			me.SwSoundFireOnOff.setBoolValue(TRUE);
		}
		if(me.mfFunction != nil) {
			#me.settings = me.mfFunction({time_s: me.life_time, dist_m: me.dist_curr_direct, mach: me.speed_m, weapon_position: me.coord});
			me.settings = me.mfFunction({   time_s:                 me.life_time, 
                                            dist_m:                 me.dist_curr_direct, 
                                            mach:                     me.speed_m, 
                                            weapon_position:         me.coord, 
                                            guidance:                 me.guidance, 
                                            seeker_detect_range:     me.detect_range_curr_nm, 
                                            seeker_fov:             me.max_seeker_dev, 
                                            weapon_pitch:             me.pitch, 
                                            weapon_heading:         me.hdg,
                                        });
			if (me.settings["guidance"] != nil) {
				me.guidance = me.settings.guidance;
				me.printStats("Guidance switched to %s",me.guidance);
				me.printExtendedStats();
			}
			if (me.settings["guidanceLaw"] != nil) {
				me.guidanceLaw = me.settings.guidanceLaw;
				me.printStats("Guidance law switched to %s", me.guidanceLaw);
			}
			if (me.settings["target"] != nil) {
				me.Tgt = me.settings.target;
				me.callsign = me.Tgt.get_Callsign();
				me.newTargetAssigned = TRUE;
				me.t_coord = nil;
				me.printStats("Target switched to %s",me.callsign);
			}
		}

		if (me.hasGuided and me.maddog) {
			me.maddog = FALSE;
			me.printStats("Maddog stage over, guided at "~me.callsign);
		}
		
		if (me.guidanceEnabled and me.free == FALSE and !me.newTargetAssigned and (me.canSwitch or (me.loal and me.maddog)) and size(me.contacts) > 0 and (me.dist_curr_direct==-1 or me.dist_curr_direct>me.reportDist)) {
			# me.reaquire must also be enabled for me.canSwitch to work
			
			if (me.Tgt==nil or me.hasGuided == FALSE or (me.canSwitch and (me.fovLost or me.lostLOS or me.radLostLock or me.semiLostLock or me.heatLostLock)) and me.life_time > me.nextFovCheck) {
				# test next contact
				me.numberContacts = size(me.contacts);
				me.switchIndex += 1;
				if (me.switchIndex >= me.numberContacts) {
					me.switchIndex = 0;
					me.nextFovCheck = me.nextFovCheck+me.switchTime;
				}
				me.Tgt = me.contacts[me.switchIndex];
				me.callsign = me.Tgt.get_Callsign();
				me.newTargetAssigned = TRUE;
				me.t_coord = nil;
				me.fovLost = FALSE;
				me.lostLOS = FALSE;
				me.radLostLock = FALSE;
				me.semiLostLock = FALSE;
				me.heatLostLock = FALSE;
				me.hasGuided = FALSE;
				if (!me.checkForClassInFlight(me.Tgt)) {
					me.Tgt = nil;
					me.callsign = "Unknown";
					me.newTargetAssigned = FALSE;
				}
			}
		}

		if (me.prevGuidance != me.guidance) {
			me.keepPitch = me.pitch;
		}
		if (me.Tgt != nil and me.Tgt.isValid() == FALSE) {#TODO: verify that the following threaded code can handle invalid contact. As its read from property-tree, not mutex protected.
			if (me.newTargetAssigned) {
				me.Tgt=nil;
				me.t_coord=nil;
			} else {
				me.printStats(me.type~": Target went away, deleting missile.");
				me.sendMessage(me.type~" missed "~me.callsign~": Target logged off.");
				settimer(func me.del(),0);
				return;
			}
		}
		me.dt = deltaSec.getValue();#TODO: time since last time nasal timers were called
		if (me.dt == 0) {
			#FG is likely paused
			me.paused = 1;
			continue;
		}
		#if just called from release() then dt is almost 0 (cannot be zero as we use it to divide with)
		# It can also not be too small, then the missile will lag behind aircraft and seem to be fired from behind the aircraft.
		#dt = dt/2;
		me.elapsed = systime();
		if (me.paused == 1) {
			# sim has been unpaused lets make sure dt becomes very small to let elapsed time catch up.
			me.paused = 0;
			me.elapsed_last = me.elapsed-0.02;
		}
		me.init_launch = 0;
		if (me.elapsed_last != 0) {
			#if (getprop("sim/speed-up") == 1) {
				me.dt = (me.elapsed - me.elapsed_last)*speedUp.getValue();
			#} else {
			#	dt = getprop("sim/time/delta-sec")*getprop("sim/speed-up");
			#}
			me.init_launch = 1;
			if(me.dt <= 0) {
				# to prevent pow floating point error in line:cdm = 0.2965 * math.pow(me.speed_m, -1.1506) + me.cd;
				# could happen if the OS adjusts the clock backwards
				me.dt = 0.00001;
			}
		}
		
		#if (me.dt < 0.025) {
			# dont update too fast..
		#	continue;
		#}
		me.elapsed_last = me.elapsed;
		me.life_time += me.dt;

		if (me.rail == FALSE) {
			me.deploy_prop.setValue(me.clamp(me.extrapolate(me.life_time, me.drop_time, me.drop_time+me.deploy_time,0,1),0,1));
			me.deploy = me.deploy_prop.getValue();
		} elsif (me.rail_passed_time == nil and me.rail_passed == TRUE) {
			me.rail_passed_time = me.life_time;
			me.deploy_prop.setValue(0);
		} elsif (me.rail_passed_time != nil) {
			me.deploy_prop.setValue(me.clamp(me.extrapolate(me.life_time, me.rail_passed_time, me.rail_passed_time+me.deploy_time,0,1),0,1));
			me.deploy = me.deploy_prop.getValue();
		}
		#if(me.life_time > 8) {# todo: make this duration configurable
			#me.SwSoundFireOnOff.setBoolValue(FALSE);
		#}

		me.thrust_lbf = me.thrust();# pounds force (lbf)

		
		# Get total old speed, thats what we will use in next loop.
		me.old_speed_horz_fps = math.sqrt((me.speed_east_fps*me.speed_east_fps)+(me.speed_north_fps*me.speed_north_fps));
		me.old_speed_fps = math.sqrt((me.old_speed_horz_fps*me.old_speed_horz_fps)+(me.speed_down_fps*me.speed_down_fps));

		me.setRadarProperties(me.old_speed_fps);

		

		# Get air density and speed of sound (fps):
		me.rs = me.rho_sndspeed(me.altN.getValue() + me.density_alt_diff);
		me.rho = me.rs[0];
		me.sound_fps = me.rs[1];

		me.max_g_current = me.maxG(me.rho, me.max_g);

		me.speed_m = me.old_speed_fps / me.sound_fps;

		if (me.old_speed_fps > me.maxFPS) {
			me.maxFPS = me.old_speed_fps;
		}
		if (me.speed_m > me.maxMach) {
			me.maxMach = me.speed_m;
		}
		if (me.speed_m > me.maxMach1 and me.life_time > me.drop_time and me.life_time <= (me.drop_time + me.stage_1_duration)) {
			me.maxMach1 = me.speed_m;
		}
		if (me.speed_m > me.maxMach2 and me.life_time > (me.drop_time + me.stage_1_duration) and me.life_time <= (me.drop_time + me.stage_1_duration + me.stage_2_duration)) {
			me.maxMach2 = me.speed_m;
		}
		if (me.maxMach3 == 0 and me.life_time > (me.drop_time + me.stage_1_duration + me.stage_2_duration)) {
			me.maxMach3 = me.speed_m;
		}

		me.Cd = me.drag(me.speed_m);

		me.speed_change_fps = me.speedChange(me.thrust_lbf, me.rho, me.Cd);
		

		if (me.last_dt != 0) {
			me.speed_change_fps = me.speed_change_fps + me.energyBleed(me.g, me.altN.getValue() + me.density_alt_diff);
		}

		# Get target position.
		#if (me.Tgt != nil) {
#			me.t_coord = me.Tgt.get_Coord();
		#}

		###################
		#### Guidance.#####
		###################
		if (me.Tgt != nil and me.t_coord !=nil and me.free == FALSE and me.guidance != "unguided"
			and (me.rail == FALSE or me.rail_passed == TRUE) and me.guidanceEnabled) {
				#
				# Here we figure out how to guide, navigate and steer.
				#
				if (me.guidance == "level") {
					me.level();
				} elsif (me.guidance == "gyro-pitch") {
					me.pitchGyro();
				} else {
					me.guide();
				}
				me.limitG();
				
				if (me.track_signal_e > 0 and me.pitch+me.track_signal_e > me.maxPitch and me.thrust_lbf==0) {# super hack
	            	me.printGuideDetails("Prevented to pitch up to %.2f degs.", me.pitch+me.track_signal_e);
	            	me.adjst = 1-(me.pitch+me.track_signal_e - me.maxPitch)/45;
	            	if (me.adjst < 0) me.adjst = 0;
	            	me.track_signal_e *= me.adjst;
	            }
	            me.pitch      += me.track_signal_e;
            	me.hdg        += me.track_signal_h;
	            me.printGuideDetails("%04.1f deg elevation command done, new pitch: %04.1f deg", me.track_signal_e, me.pitch);
	            me.printGuideDetails("%05.1f deg bearing command done, new heading: %05.1f", me.last_track_h, me.hdg);
	            me.observing = me.guidance;
	    } elsif (me.guidance != "unguided" and (me.rail == FALSE or me.rail_passed == TRUE) and me.guidanceEnabled and me.free == FALSE and me.t_coord == nil
	    		and (me.newTargetAssigned or (me.canSwitch and (me.fovLost or me.lostLOS or me.radLostLock or me.semiLostLock or me.heatLostLock) or (me.loal and me.maddog)))) {
	    	# check for too low speed not performed on purpuse, difference between flying straight on A/P and making manouvres.
	    	if (me.observing != me.standbyFlight) {
            	me.keepPitch = me.pitch;
            }
	    	if (me.standbyFlight == "level") {
				me.level();
			} elsif (me.standbyFlight == "gyro-pitch") {
				me.pitchGyro();
			} else {
				me.track_signal_e = 0;
				me.track_signal_h = 0;
			}
			me.pitch      += me.track_signal_e;
           	me.hdg        += me.track_signal_h;
            me.printGuideDetails("%04.1f deg elevation command done, new pitch: %04.1f deg", me.track_signal_e, me.pitch);
            me.printGuideDetails("%05.1f deg bearing command done, new heading: %05.1f", me.last_track_h, me.hdg);
            me.observing = me.standbyFlight;
		} else {
			me.observing = "unguided";
			me.track_signal_e = 0;
			me.track_signal_h = 0;
			#me.printGuideDetails(sprintf("not guiding %d %d %d %d %d",me.Tgt != nil,me.free == FALSE,me.guidance != "unguided",me.rail == FALSE,me.rail_passed == TRUE));
		}
       	me.last_track_e = me.track_signal_e;
		me.last_track_h = me.track_signal_h;

		me.new_speed_fps        = me.speed_change_fps + me.old_speed_fps;
		if (me.new_speed_fps < 0) {
			# drag and bleed can theoretically make the speed less than 0, this will prevent that from happening.
			me.new_speed_fps = 0.001;
		}

		# Break speed change down total speed to North, East and Down components.
		me.speed_down_fps       = -math.sin(me.pitch * D2R) * me.new_speed_fps;
		me.speed_horizontal_fps = math.cos(me.pitch * D2R) * me.new_speed_fps;
		me.speed_north_fps      = math.cos(me.hdg * D2R) * me.speed_horizontal_fps;
		me.speed_east_fps       = math.sin(me.hdg * D2R) * me.speed_horizontal_fps;
		me.speed_down_fps      += g_fps * me.dt;

		#printf("Mach down %.2f", me.speed_down_fps / me.sound_fps);

		if (me.rail == TRUE and me.rail_passed == FALSE) {
			# missile still on rail, lets calculate its speed relative to the wind coming in from the aircraft nose.
			me.rail_speed_into_wind = me.rail_speed_into_wind + me.speed_change_fps;
		} elsif (me.observing != "gyro-pitch" or me.speed_m < me.min_speed_for_guiding) {
			# gravity acc makes the weapon pitch down			
			me.pitch = math.atan2(-me.speed_down_fps, me.speed_horizontal_fps ) * R2D;
		}

		
		if (me.rail == TRUE and me.rail_passed == FALSE) {
			me.u = noseAir.getValue();# airstream from nose
			#var v = getprop("velocities/vBody-fps");# airstream from side
			me.w = belowAir.getValue();# airstream from below

			if (me.rail_forward == TRUE) {
				me.pitch = OurPitch.getValue();
				me.opposing_wind = me.u;
				me.hdg = OurHdg.getValue();
			} else {
				me.pitch = OurPitch.getValue() + me.rail_pitch_deg;
				if (me.rail_pitch_deg == 90) {
					me.opposing_wind = -me.w;
				} else {
					# no incoming airstream if not vertical tube
					me.opposing_wind = 0;
				}
				if (me.Tgt != nil) {
					me.hdg = me.Tgt.get_bearing();
				} else {
					me.hdg = OurHdg.getValue();
				}
			}			

			me.speed_on_rail = me.clamp(me.rail_speed_into_wind - me.opposing_wind, 0, 1000000);
			me.movement_on_rail = me.speed_on_rail * me.dt;
			
			me.rail_pos = me.rail_pos + me.movement_on_rail;
			if (me.rail_forward == TRUE) {
				me.x = me.x - (me.movement_on_rail * FT2M);# negative cause positive is rear in body coordinates
			} elsif (me.rail_pitch_deg == 90) {
				me.z = me.z + (me.movement_on_rail * FT2M);# positive cause positive is up in body coordinates
			} else {
				me.x = me.x - (me.movement_on_rail * FT2M);
			}
		}

		if (me.rail == FALSE or me.rail_passed == TRUE) {
			# missile not on rail, lets move it to next waypoint
			if (me.observing != "level" or me.speed_m < me.min_speed_for_guiding) {
				me.alt_ft = me.alt_ft - (me.speed_down_fps * me.dt);
			}
			me.dist_h_m = me.speed_horizontal_fps * me.dt * FT2M;
			me.coord.apply_course_distance(me.hdg, me.dist_h_m);
			me.coord.set_alt(me.alt_ft * FT2M);
		} else {
			# missile on rail, lets move it on the rail
			if (me.rail_pitch_deg == 90 or me.rail_forward == TRUE) {
				var init_coord = nil;
				if (offsetMethod == TRUE) {
					me.geodPos = aircraftToCart({x:-me.x, y:me.y, z: -me.z});
					me.coord.set_xyz(me.geodPos.x, me.geodPos.y, me.geodPos.z);
				} else {
					me.coord = me.getGPS(me.x, me.y, me.z, OurPitch.getValue());
				}				
			} else {
				# kind of a hack, but work for static launcher
				me.coord = me.getGPS(me.x, me.y, me.z, OurPitch.getValue()+me.rail_pitch_deg);
			}
			me.alt_ft = me.coord.alt() * M2FT;
			# find its speed, for used in calc old speed
			me.speed_down_fps       = -math.sin(me.pitch * D2R) * me.rail_speed_into_wind;
			me.speed_horizontal_fps = math.cos(me.pitch * D2R) * me.rail_speed_into_wind;
			me.speed_north_fps      = math.cos(me.hdg * D2R) * me.speed_horizontal_fps;
			me.speed_east_fps       = math.sin(me.hdg * D2R) * me.speed_horizontal_fps;
		}
		if (me.alt_ft > me.maxAlt) {
			me.maxAlt = me.alt_ft;
		}
		# Get target position.
		if (me.Tgt != nil and me.t_coord != nil) {
			if (me.flareLock == FALSE and me.chaffLock == FALSE) {
				me.t_coord = me.Tgt.get_Coord();
				if (me.t_coord == nil) {
					# just to protect the multithreaded code for invalid pos.
					me.Tgt = nil;
				}
			} else {
				# we are chasing a flare, lets update the flares position.
				if (me.flareLock == TRUE) {
					me.flarespeed_fps = me.flarespeed_fps - (25 * me.dt);#flare deacc. 15 kt per second.
				} else {
					me.flarespeed_fps = me.flarespeed_fps - (50 * me.dt);#chaff deacc. 30 kt per second.
				}
				if (me.flarespeed_fps < 0) {
					me.flarespeed_fps = 0;
				}
				me.flare_speed_down_fps       = -math.sin(me.flare_pitch * D2R) * me.flarespeed_fps;
				me.flare_speed_horizontal_fps = math.cos(me.flare_pitch * D2R) * me.flarespeed_fps;
				me.flare_alt_ft = me.t_coord.alt()*M2FT - (me.flare_speed_down_fps * me.dt);
				me.flare_dist_h_m = me.flare_speed_horizontal_fps * me.dt * FT2M;
				me.t_coord.apply_course_distance(me.flare_hdg, me.flare_dist_h_m);
				me.t_coord.set_alt(me.flare_alt_ft * FT2M);
			}
		}
		# record coords so we can give the latest nearest position for impact.
		me.before_last_coord   = geo.Coord.new(me.last_coord);
		me.last_coord          = geo.Coord.new(me.coord);
		if (me.Tgt != nil) {
			me.before_last_t_coord = geo.Coord.new(me.last_t_coord);
			me.last_t_coord        = geo.Coord.new(me.t_coord);
		}

		# performance logging:
		#
		#var q = 0.5 * rho * me.old_speed_fps * me.old_speed_fps;
		#setprop("logging/missile/dist-nm", me.ac_init.distance_to(me.coord)*M2NM);
		#setprop("logging/missile/alt-m", me.alt_ft * FT2M);
		#setprop("logging/missile/speed-m", me.speed_m*1000);
		#setprop("logging/missile/drag-lbf", Cd * q * me.ref_area_sqft);
		#setprop("logging/missile/thrust-lbf", thrust_lbf);

		me.setFirst();

		me.printFlight("Pitch %.2f degs.", me.pitch);

		me.latN.setDoubleValue(me.coord.lat());
		me.lonN.setDoubleValue(me.coord.lon());
		me.altN.setDoubleValue(me.alt_ft);
		if (!no_pitch or (me.rail == TRUE and me.rail_passed == FALSE)) {
			me.pitchN.setDoubleValue(me.pitch);
		} else {
			me.uprighter = me.pitchN.getValue();
			if (me.uprighter<89.92) {
				me.uprighter += (90-me.uprighter)*me.dt*0.1;
			} elsif (me.uprighter>90.08) {
				me.uprighter -= (me.uprighter-90)*me.dt*0.1;
			} else {
				me.uprighter = 90.0;
			}
			me.pitchN.setDoubleValue(me.uprighter);
		}
		me.hdgN.setDoubleValue(me.hdg);
		me.rollN.setDoubleValue(me.rollN.getValue()+me.lateralSpeed*me.dt);

		# log missiles to unicsv for visualizing flightpath in Google Earth
		#
		#setprop("/logging/missile/latitude-deg", me.coord.lat());
		#setprop("/logging/missile/longitude-deg", me.coord.lon());
		#setprop("/logging/missile/altitude-ft", alt_ft);
		#setprop("/logging/missile/t-latitude-deg", me.t_coord.lat());
		#setprop("/logging/missile/t-longitude-deg", me.t_coord.lon());
		#setprop("/logging/missile/t-altitude-ft", me.t_coord.alt()*M2FT);

		##############################
		#### Proximity detection.#####
		##############################
		if (me.rail == FALSE or me.rail_passed == TRUE) {
 			if ( me.free == FALSE ) {
 				# check if the missile overloaded with G force.
				me.g = me.steering_speed_G(me.track_signal_e, me.track_signal_h, me.old_speed_fps, me.dt);

				if ( me.g > me.max_g_current and me.init_launch != 0) {
					me.free = TRUE;
					me.printStats("%s: Missile attempted to pull too many G, it broke.", me.type);
				}
			} else {
				me.g = 0;
			}

			me.exploded = me.proximity_detection();

			#
			# check stats while flying:
			#
			me.printFlight("Mach %04.2f , time %05.1f s , thrust %05.1f lbf , G-force %05.2f", me.speed_m, me.life_time, me.thrust_lbf, me.g);
			me.printFlight("Alt %07.1f ft , direct distance to target %04.1f NM", me.alt_ft, (me.Tgt!=nil and me.direct_dist_m!=nil)?me.direct_dist_m*M2NM:-1);			
			
			if (me.exploded == TRUE) {
				me.printStats("%s max absolute %.2f Mach. Max relative %.2f Mach. Max alt %6d ft. Terminal %.2f mach.", me.type, me.maxMach, me.maxMach-me.startMach, me.maxAlt, me.speed_m);
				me.printStats("%s max relative %d ft/s.", me.type, me.maxFPS-me.startFPS);
				me.printStats(" Absolute %.2f Mach in stage 1. Absolute %.2f Mach in stage 2. Absolute %.2f mach propulsion end.", me.maxMach1, me.maxMach2, me.maxMach3);
				me.printStats(" Fired at %s from %.2f Mach, %5d ft at %3d NM distance. Flew %.1f NM.", me.callsign, me.startMach, me.startAlt, me.startDist * M2NM, me.ac_init.direct_distance_to(me.coord)*M2NM);
				# We exploded, and start the sound propagation towards the plane
				me.sndSpeed = me.sound_fps;
				me.sndDistance = 0;
				me.elapsed_last = systime();
				if (me.explodeSound == TRUE) {
					me.sndPropagate();
				} else {
					settimer( func me.del(), 10);
				}
				return;
			}
		} else {
			me.g = 0;
		}

		if (me.Tgt == nil and me.rail == TRUE and me.rail_pitch_deg==90 and me.rail_passed == FALSE) {
			#for ejection seat to be oriented correct, wont be ran for missiles with target such as the frigate.
			var a = me.myMath.eulerToCartesian3Z(-OurHdg.getValue(), OurPitch.getValue(), OurRoll.getValue());
			#printf("%0.4f %0.4f %0.4f",OurHdg.getValue(),OurPitch.getValue(),OurRoll.getValue());
			#printf("%0.4f %0.4f %0.4f",a[0],a[1],a[2]);
			var euler = me.myMath.cartesianToEuler(a);
			
			me.pitch = euler[1];
			me.pitchN.setDoubleValue(me.pitch);
			if (euler[0]!=nil) {
				me.hdg = euler[0];
			} else {
				me.hdg = OurHdg.getValue();
			}
			me.hdgN.setDoubleValue(me.hdg);
			var nose = me.myMath.eulerToCartesian3X(-OurHdg.getValue(), OurPitch.getValue(), OurRoll.getValue());
			var face = me.myMath.eulerToCartesian3Z(-me.hdg, me.pitch, 0);
			face = me.myMath.product(-1,face);
			var turnFace = me.myMath.angleBetweenVectors(face,nose);
			if (me.myMath.angleBetweenVectors(nose,me.myMath.product(-1,me.myMath.eulerToCartesian3Z(-me.hdg, me.pitch, turnFace)))>turnFace) {
				turnFace *= -1;
			}
			me.rollN.setDoubleValue(turnFace);

			#printf("seat now at P:%d H:%d R:%d",me.pitch,me.hdg,me.rollN.getValue());
		}
		if (me.rail_passed == FALSE and (me.rail == FALSE or me.rail_pos > me.rail_dist_m * M2FT)) {
			me.rail_passed = TRUE;
			me.printFlight("rail passed");
		}


		# consume fuel
		if (me.life_time > (me.drop_time + me.stage_1_duration + me.stage_2_duration)) {
			me.weight_current = me.weight_launch_lbm - me.weight_fuel_lbm;
		} elsif (me.life_time > (me.drop_time + me.stage_1_duration)) {
			me.weight_current = me.weight_current - me.fuel_per_sec_2 * me.dt;
		} elsif (me.life_time > me.drop_time) {
			me.weight_current = me.weight_current - me.fuel_per_sec_1 * me.dt;
		}
		#printf("weight %0.1f", me.weight_current);
		me.mass = me.weight_current / slugs_to_lbm;

		# telemetry
		if (me.data == TRUE) {
			me.eta = me.free == TRUE or me.horz_closing_rate_fps == -1?-1:(me.dist_curr*M2FT)/me.horz_closing_rate_fps;
			me.hit = 50;# in percent
			if (me.life_time > me.drop_time+me.stage_1_duration) {
				# little less optimistic after reaching topspeed
				if (me.selfdestruct_time-me.life_time < me.eta) {
					# reduce alot if eta later than lifespan
					me.hit -= 75;
				} elsif (me.eta != -1 and (me.selfdestruct_time-me.life_time) != 0) {
					# if its hitting late in life, then reduce
					me.hit -= (me.eta / (me.selfdestruct_time-me.life_time)) * 25;
				}
				if (me.eta > 0) {
					# penalty if eta is high
					me.hit -= me.clamp(40*me.eta/(me.life_time*0.85), 0, 40);
				}
			}
			if (me.curr_deviation_h != nil and me.dist_curr > 50) {
				# penalty for target being off-bore
				me.hit -= math.abs(me.curr_deviation_h)/2.5;
			}
			if (me.guiding == TRUE and me.t_speed_fps != nil and me.old_speed_fps > me.t_speed_fps and me.t_speed_fps != 0) {
				# bonus for traveling faster than target
				me.hit += me.clamp((me.old_speed_fps / me.t_speed_fps)*15,-25,50);
			}			
			if (me.free == TRUE) {
				# penalty for not longer guiding
				me.hit -= 75;
			}
			me.hit = int(me.clamp(me.hit, 0, 90));
			me.ai.getNode("ETA").setIntValue(me.eta);
			me.ai.getNode("hit").setIntValue(me.hit);
		}

		me.last_dt = me.dt;
		me.prevTarget = me.Tgt;
		me.prevGuidance = me.guidance;
		#spawn(me.flight, me)();#, update_loop_time, SIM_TIME);
		#me.flight(); cannot keep calling itself: call stack error
		if (me.init_launch == 0) {
			me.ai.getNode("valid").setBoolValue(1);
		}
		#thread.unlock(frameToggle);
	  }
	},

	getGPS: func(x, y, z, pitch, head=nil, roll=nil) {
		#
		# get Coord from body position. x,y,z must be in meters.
		# derived from Vivian's code in AIModel/submodel.cxx.
		#
		me.ac = geo.aircraft_position();

		if(x == 0 and y==0 and z==0) {
			return geo.Coord.new(me.ac);
		}
		if (roll == nil) {
			me.ac_roll = OurRoll.getValue();
		} else {
			me.ac_roll = roll;
		}
		me.ac_pitch = pitch;
		
		if (head == nil) {
			me.ac_hdg   = OurHdg.getValue();
		} else {
			me.ac_hdg = head;
		}

		me.in    = [0,0,0];
		me.trans = [[0,0,0],[0,0,0],[0,0,0]];
		me.out   = [0,0,0];

		me.in[0] =  -x * M2FT;
		me.in[1] =   y * M2FT;
		me.in[2] =   z * M2FT;
		# Pre-process trig functions:
		me.cosRx = math.cos(-me.ac_roll * D2R);
		me.sinRx = math.sin(-me.ac_roll * D2R);
		me.cosRy = math.cos(-me.ac_pitch * D2R);
		me.sinRy = math.sin(-me.ac_pitch * D2R);
		me.cosRz = math.cos(me.ac_hdg * D2R);
		me.sinRz = math.sin(me.ac_hdg * D2R);
		# Set up the transform matrix:
		me.trans[0][0] =  me.cosRy * me.cosRz;
		me.trans[0][1] =  -1 * me.cosRx * me.sinRz + me.sinRx * me.sinRy * me.cosRz ;
		me.trans[0][2] =  me.sinRx * me.sinRz + me.cosRx * me.sinRy * me.cosRz;
		me.trans[1][0] =  me.cosRy * me.sinRz;
		me.trans[1][1] =  me.cosRx * me.cosRz + me.sinRx * me.sinRy * me.sinRz;
		me.trans[1][2] =  -1 * me.sinRx * me.cosRx + me.cosRx * me.sinRy * me.sinRz;
		me.trans[2][0] =  -1 * me.sinRy;
		me.trans[2][1] =  me.sinRx * me.cosRy;
		me.trans[2][2] =  me.cosRx * me.cosRy;
		# Multiply the input and transform matrices:
		me.out[0] = me.in[0] * me.trans[0][0] + me.in[1] * me.trans[0][1] + me.in[2] * me.trans[0][2];
		me.out[1] = me.in[0] * me.trans[1][0] + me.in[1] * me.trans[1][1] + me.in[2] * me.trans[1][2];
		me.out[2] = me.in[0] * me.trans[2][0] + me.in[1] * me.trans[2][1] + me.in[2] * me.trans[2][2];
		# Convert ft to degrees of latitude:
		me.out[0] = me.out[0] / (366468.96 - 3717.12 * math.cos(me.ac.lat() * D2R));
		# Convert ft to degrees of longitude:
		me.out[1] = me.out[1] / (365228.16 * math.cos(me.ac.lat() * D2R));
		# Set submodel initial position:
		me.mlat = me.ac.lat() + me.out[0];
		me.mlon = me.ac.lon() + me.out[1];
		me.malt = (me.ac.alt() * M2FT) + me.out[2];
		
		me.c = geo.Coord.new();
		me.c.set_latlon(me.mlat, me.mlon, me.malt * FT2M);

		return me.c;
	},

	drag: func (mach) {
		# Nikolai V. Chr.: Made the drag calc more in line with big missiles as opposed to small bullets.
		# 
		# The old equations were based on curves for a conventional shell/bullet (no boat-tail),
		# and derived from Davic Culps code in AIBallistic.
		me.Cd = 0;
		if (mach < 0.7) {
			me.Cd = (0.0125 * mach + 0.20) * 5 * (me.Cd_base+me.Cd_delta*me.deploy);
		} elsif (mach < 1.2 ) {
			me.Cd = (0.3742 * math.pow(mach, 2) - 0.252 * mach + 0.0021 + 0.2 ) * 5 * (me.Cd_base+me.Cd_delta*me.deploy);
		} else {
			me.Cd = (0.2965 * math.pow(mach, -1.1506) + 0.2) * 5 * (me.Cd_base+me.Cd_delta*me.deploy);
		}

		return me.Cd;
	},

	maxG: func (rho, max_g_sealevel) {
		# Nikolai V. Chr.: A function to determine max G-force depending on air density.
		#
		# density for 0ft and 50kft:
		#print("0:"~rho_sndspeed(0)[0]);       = 0.0023769
		#print("50k:"~rho_sndspeed(50000)[0]); = 0.00036159
		#
		# Fact: An aim-9j can do 22G at sealevel, 13G at 50Kft
		# 13G = 22G * 0.5909
		#
		# extra/inter-polation:
		# f(x) = y1 + ((x - x1) / (x2 - x1)) * (y2 - y1)
		# calculate its performance at current air density:
		return me.clamp(max_g_sealevel+((rho-0.0023769)/(0.00036159-0.0023769))*(max_g_sealevel*0.5909-max_g_sealevel),0.25,100);
	},

	extrapolate: func (x, x1, x2, y1, y2) {
    	return y1 + ((x - x1) / (x2 - x1)) * (y2 - y1);
	},

	thrust: func () {
		# Determine the thrust at this moment.
		#
		# If dropped, then ignited after fall time of what is the equivalent of 7ft.
		# If the rocket is 2 stage, then ignite the second stage when 1st has burned out.
		#
		me.thrust_lbf = 0;# pounds force (lbf)
		if (me.engineEnabled) {
			if (me.life_time > (me.drop_time + me.stage_1_duration + me.stage_2_duration)) {
				me.thrust_lbf = 0;
			} elsif (me.life_time > me.stage_1_duration + me.drop_time) {
				me.thrust_lbf = me.force_lbf_2;
			} elsif (me.life_time > me.drop_time) {
				me.thrust_lbf = me.force_lbf_1;
			}
		}
		
		#me.force_cutoff_s = 0;# seen charts of real (aim9m) that thrust dont stop instantly, but fades out. This term would say hwo long it takes to fade out. Need to rework fuel consumption first. Maybe in future.
		#if (me.life_time > (me.drop_time + me.stage_1_duration + me.stage_2_duration-me.force_cutoff_s) and me.life_time < (me.drop_time + me.stage_1_duration + me.stage_2_duration)) {
		#	me.thrust_lbf = me.extrapolate(me.life_time - (me.drop_time + me.stage_1_duration + me.stage_2_duration - me.force_cutoff_s),0,me.force_cutoff_s,me.thrust_lbf,0);
		#}
		
		if (me.thrust_lbf < 1) {
			me.smoke_prop.setBoolValue(0);
		} else {
			me.smoke_prop.setBoolValue(1);
		}
		return me.thrust_lbf;
	},

	speedChange: func (thrust_lbf, rho, Cd) {
		# Calculate speed change from last update.
		#
		# Acceleration = thrust/mass - drag/mass;
		
		me.acc = thrust_lbf / me.mass;
		me.q = 0.5 * rho * me.old_speed_fps * me.old_speed_fps;# dynamic pressure
		me.drag_acc = (me.Cd * me.q * me.ref_area_sqft) / me.mass;

		# get total new speed change (minus gravity)
		return me.acc*me.dt - me.drag_acc*me.dt;
	},

    energyBleed: func (gForce, altitude) {
        # Bleed of energy from pulling Gs.
        # This is very inaccurate, but better than nothing.
        #
        # First we get the speedloss due to normal drag:
        me.b300 = me.bleed32800at0g();
        me.b000 = me.bleed0at0g();
        #
        # We then subtract the normal drag from the loss due to G and normal drag.
        me.b325 = me.bleed32800at25g()-me.b300;
        me.b025 = me.bleed0at25g()-me.b000;
        me.b300 = 0;
        me.b000 = 0;
        #
        # We now find what the speedloss will be at sealevel and 32800 ft.
        me.speedLoss32800 = me.b300 + ((gForce-0)/(25-0))*(me.b325 - me.b300);
        me.speedLoss0 = me.b000 + ((gForce-0)/(25-0))*(me.b025 - me.b000);
        #
        # We then inter/extra-polate that to the currect density-altitude.
        me.speedLoss = me.speedLoss0 + ((altitude-0)/(32800-0))*(me.speedLoss32800-me.speedLoss0);
        #
        # For good measure the result is clamped to below zero.
        me.speedLoss = me.clamp(me.speedLoss, -100000, 0);
        me.energyBleedKt += me.speedLoss * FPS2KT;
        me.speedLoss = me.speedLoss-me.vector_thrust*me.speedLoss*0.66*(me.thrust_lbf==0?0:1);# vector thrust will only bleed 1/3 of the calculated loss.
        return me.speedLoss;
    },

	bleed32800at0g: func () {
		me.loss_fps = 0 + ((me.last_dt - 0)/(15 - 0))*(-330 - 0);
		return me.loss_fps*M2FT;
	},

	bleed32800at25g: func () {
		me.loss_fps = 0 + ((me.last_dt - 0)/(3.5 - 0))*(-240 - 0);
		return me.loss_fps*M2FT;
	},

	bleed0at0g: func () {
		me.loss_fps = 0 + ((me.last_dt - 0)/(22 - 0))*(-950 - 0);
		return me.loss_fps*M2FT;
	},

	bleed0at25g: func () {
		me.loss_fps = 0 + ((me.last_dt - 0)/(7 - 0))*(-750 - 0);
		return me.loss_fps*M2FT;
	},	

	setFirst: func() {
		if (me.smoke_prop.getValue() == TRUE) {
			if (me.first == TRUE or first_in_air == FALSE) {
				# report position over MP for MP animation of smoke trail.
				me.first = TRUE;
				first_in_air = TRUE;
				if (me.mpShow == TRUE) {
					me.mpLat.setDoubleValue(me.coord.lat());
					me.mpLon.setDoubleValue(me.coord.lon());
					me.mpAlt.setDoubleValue(me.coord.alt());
				}
			}
		} elsif (me.first == TRUE and me.life_time > me.drop_time + me.stage_1_duration + me.stage_2_duration) {
			# this weapon was reporting its position over MP, but now its fuel has used up. So allow for another to do that.
			me.resetFirst();
		}
	},

	resetFirst: func() {
		first_in_air = FALSE;
		me.first = FALSE;
		if (me.mpShow == TRUE) {
			me.mpLat.setDoubleValue(0.0);
			me.mpLon.setDoubleValue(0.0);
			me.mpAlt.setDoubleValue(0.0);
		}
	},

	limitG: func () {
		#
		# Here will be set the max angle of pitch and the max angle of heading to avoid G overload
		#
        me.myG = me.steering_speed_G(me.track_signal_e, me.track_signal_h, me.old_speed_fps, me.dt);
        if(me.max_g_current < me.myG)
        {
            me.MyCoef = me.max_G_Rotation(me.track_signal_e, me.track_signal_h, me.old_speed_fps, me.dt, me.max_g_current);
            me.track_signal_e =  me.track_signal_e * me.MyCoef;
            me.track_signal_h =  me.track_signal_h * me.MyCoef;
            #me.printFlight(sprintf("G1 %.2f", myG));
            me.myG = me.steering_speed_G(me.track_signal_e, me.track_signal_h, me.old_speed_fps, me.dt);
            #me.printFlight(sprintf("G2 %.2f", myG)~sprintf(" - Coeff %.2f", MyCoef));
            if (me.limitGs == FALSE) {
            	me.printFlight("%s: Missile pulling almost max G: %04.1f G", me.type, me.myG);
            }
        }
        if (me.limitGs == TRUE and me.myG > me.max_g_current/2) {
        	# Save the high performance manouving for later
        	me.track_signal_e = me.track_signal_e /2;
        }
	},

	setRadarProperties: func (new_speed_fps) {
		#
		# Set missile radar properties for use in selection view, radar and HUD.
		#
		me.self = geo.aircraft_position();
		me.ai.getNode("radar/bearing-deg", 1).setDoubleValue(me.self.course_to(me.coord));
		me.ai.getNode("radar/elevation-deg", 1).setDoubleValue(me.getPitch(me.self, me.coord));
		me.ai.getNode("radar/range-nm", 1).setDoubleValue(me.self.distance_to(me.coord)*M2NM);
		me.ai.getNode("velocities/true-airspeed-kt",1).setDoubleValue(new_speed_fps * FPS2KT);
		me.ai.getNode("velocities/vertical-speed-fps",1).setDoubleValue(-me.speed_down_fps);
	},

	rear_aspect: func (munition_coord, test_contact) {
		#
		# If is heat-seeking rear-aspect-only missile, check if it has good view on engine(s) and can keep lock.
		#
		me.offset = me.aspectToExhaust(munition_coord, test_contact);

		if (me.offset < 45) {
			# clear view of engine heat, keep the lock
			me.rearAspect = 1;
		} else {
			# the greater angle away from clear engine view the greater chance of losing lock.
			me.offset_away = me.offset - 45;
			me.probability = me.offset_away/135;
			me.probability = me.probability*2.5;# The higher the factor, the less chance to keep lock.
			me.rearAspect = rand() > me.probability;
		}

		me.printGuideDetails("Heatseeker deviation from full rear-aspect: "~sprintf("%05.1f", me.offset)~" deg, keep IR lock on engine: "~me.rearAspect);

		return me.rearAspect;# 1: keep lock, 0: lose lock
	},

	aspectToExhaust: func (munition_coord, test_contact) {
		# return angle to viewing rear of target
		me.vectorToEcho   = me.myMath.eulerToCartesian2(munition_coord.course_to(test_contact.get_Coord()), me.myMath.getPitch(munition_coord, test_contact.get_Coord()));
    	me.vectorEchoNose = me.myMath.eulerToCartesian3X(test_contact.get_heading(), test_contact.get_Pitch(), test_contact.get_Roll());
    	me.angleToRear    = geo.normdeg180(me.myMath.angleBetweenVectors(me.vectorToEcho, me.vectorEchoNose));
    	#me.printGuideDetails(sprintf("Angle to rear %d degs.", math.abs(me.angleToRear));
    	return math.abs(me.angleToRear);
    },

    aspectToTop: func () {
    	# WIP: not used, and might never be
    	me.vectorEchoTop  = me.myMath.eulerToCartesian3Z(echoHeading, echoPitch, echoRoll);
    	me.view2D         = me.myMath.projVectorOnPlane(me.vectorEchoTop, me.vectorToEcho);
		me.angleToNose    = geo.normdeg180(me.myMath.angleBetweenVectors(me.vectorEchoNose, me.view2D)+180);
		me.angleToBelly   = geo.normdeg180(me.myMath.angleBetweenVectors(me.vectorEchoTop, me.vectorToEcho));
	},

	guide: func() {
		#
		# navigation and guidance
		#
		
		me.raw_steer_signal_elev = 0;
		me.raw_steer_signal_head = 0;

		me.guiding = TRUE;

		# Calculate current target elevation and azimut deviation.
		me.t_alt            = me.t_coord.alt()*M2FT;
		#var t_alt_delta_m   = (me.t_alt - me.alt_ft) * FT2M;
		me.dist_curr        = me.coord.distance_to(me.t_coord);
		me.dist_curr_direct = me.coord.direct_distance_to(me.t_coord);
		me.dist_curr_hypo   = math.sqrt(me.dist_curr_direct*me.dist_curr_direct+math.pow(me.t_coord.alt()-me.coord.alt(),2));
		me.t_elev_deg       = me.getPitch(me.coord, me.t_coord);
		me.t_course         = me.coord.course_to(me.t_coord);
		me.curr_deviation_e = me.t_elev_deg - me.pitch;
		me.curr_deviation_h = me.t_course - me.hdg;

		#var (t_course, me.dist_curr) = courseAndDistance(me.coord, me.t_coord);
		#me.dist_curr = me.dist_curr * NM2M;	

		me.printFlightDetails("Elevation to target %05.2f degs, pitch deviation %05.2f degs, pitch %05.2f degs", me.t_elev_deg, me.curr_deviation_e, me.pitch);
		me.printFlightDetails("Bearing to target %06.2f degs, heading deviation %06.2f degs, heading %06.2f degs", me.t_course, me.curr_deviation_h, me.hdg);
		me.printFlightDetails("Altitude above launch platform = %07.1f ft", M2FT * (me.coord.alt()-me.ac.alt()));
		me.printFlightDetails("Altitude. Target %07.1f. Missile %07.1f. Atan2 %04.1f degs", me.t_coord.alt()*M2FT, me.coord.alt()*M2FT, math.atan2( me.t_coord.alt()-me.coord.alt(), me.dist_curr ) * R2D);

		me.curr_deviation_h = geo.normdeg180(me.curr_deviation_h);

		me.checkForLOS();

		me.checkForGuidance();

		me.checkForSun();

		me.checkForFlare();

		me.checkForChaff();

		me.canSeekerKeepUp();

		me.cruiseAndLoft();

		me.APN();# Proportional navigation

		me.adjustToKeepLock();

		me.track_signal_e = me.raw_steer_signal_elev * !me.free * me.guiding;
		me.track_signal_h = me.raw_steer_signal_head * !me.free * me.guiding;

		me.printGuide("%04.1f deg elevate command desired", me.track_signal_e);
		me.printGuide("%05.1f deg heading command desired", me.track_signal_h);

		# record some variables for next loop:
		me.dist_last           = me.dist_curr;
		me.dist_direct_last    = me.dist_curr_direct;
		me.dist_last_hypo      = me.dist_curr_hypo;
		me.last_t_course       = me.t_course;
		me.last_t_elev_deg     = me.t_elev_deg;
		me.last_cruise_or_loft = me.cruise_or_loft;

		if (!(me.fovLost or me.lostLOS or me.radLostLock or me.semiLostLock or me.heatLostLock)) {
			# me.tooLowSpeed not included in check on purpose
			me.hasGuided = TRUE;
		}
		me.newTargetAssigned=FALSE;
	},

	checkForFlare: func () {
		#
		# Check for being fooled by flare.
		#
		if (me.fovLost != TRUE and me.guidance == "heat" and me.flareLock == FALSE and (getprop("sim/time/elapsed-sec")-me.flareTime) > 1) {
			# the fov check is for loal missiles that should not lock onto flares from aircraft not in view.
			#
			# TODO: Use Richards Emissary for this.
			#
			me.flareNode = me.Tgt.getFlareNode();
			if (me.flareNode != nil) {
				me.flareNumber = me.flareNode.getValue();
				if (me.flareNumber != nil and me.flareNumber != 0) {
					if (me.flareNumber != me.flareLast) {
						# target has released a new flare, lets check if it fools us
						me.flareTime = getprop("sim/time/elapsed-sec");
						me.flareLast = me.flareNumber;
						me.aspectDeg = me.aspectToExhaust(me.coord, me.Tgt) / 180;
						me.flareLock = rand() < (1-me.flareResistance + ((1-me.flareResistance) * 0.5 * me.aspectDeg));# 50% extra chance to be fooled if front aspect
						if (me.flareLock == TRUE) {
							# fooled by the flare
							me.printStats(me.type~": Missile locked on flare from "~me.callsign);
							me.flarespeed_fps = me.Tgt.get_Speed()*KT2FPS;
							me.flare_hdg      = me.Tgt.get_heading();
							me.flare_pitch    = me.Tgt.get_Pitch();
						} else {
							me.printStats(me.type~": Missile ignored flare from "~me.callsign);
						}
					}
				}
			}
		}
	},

	checkForChaff: func () {
		#
		# Check for being fooled by chaff.
		#
		if (me.fovLost != TRUE and (me.guidance == "radar" or me.guidance == "semi-radar") and me.chaffLock == FALSE and (getprop("sim/time/elapsed-sec")-me.chaffTime) > 1) {
			#
			# TODO: Use Richards Emissary for this.
			#
			me.chaffNode = me.Tgt.getChaffNode();
			if (me.chaffNode != nil) {
				me.chaffNumber = me.chaffNode.getValue();
				if (me.chaffNumber != nil and me.chaffNumber != 0) {
					if (me.chaffNumber != me.chaffLast) {# problem here is MP interpolates to new values. Hence the timer.
						# target has released a new chaff, lets check if it blinds us
						me.chaffLast = me.chaffNumber;
						me.chaffTime = getprop("sim/time/elapsed-sec");
						#me.aspectNorm = math.abs(geo.normdeg180(me.aspectToExhaust() * 2))/180;# 0 = viewing engine or front, 1 = viewing side, belly or top.
						
						# chance to lock on chaff when viewing engine or nose, less if viewing other aspects
						#me.chaffLock = rand() > (me.chaffResistance + (1-me.chaffResistance) * 0.5 * me.aspectNorm);

						me.chaffLock = rand() > me.chaffResistance;

						if (me.chaffLock == TRUE) {
							me.printStats(me.type~": Missile locked on chaff from "~me.callsign);
							me.flarespeed_fps = me.Tgt.get_Speed()*KT2FPS;
							me.flare_hdg      = me.Tgt.get_heading();
							me.flare_pitch    = me.Tgt.get_Pitch();
						} else {
							me.printStats(me.type~": Missile ignored chaff from "~me.callsign);
						}
					}
				}
			}
		}
	},

	checkForSun: func () {
		if (me.fovLost != TRUE and me.guidance == "heat" and me.sun_enabled == TRUE and getprop("/rendering/scene/diffuse/red") > 0.6) {
			# test for heat seeker locked on to sun
			me.sun_dev_e = me.getPitch(me.coord, me.sun) - me.pitch;
			me.sun_dev_h = me.coord.course_to(me.sun) - me.hdg;
			me.sun_dev_h = geo.normdeg180(me.sun_dev_h);
			# now we check if the sun is behind the target, which is the direction the gyro seeker is pointed at:
			me.sun_dev = math.sqrt((me.sun_dev_e-me.curr_deviation_e)*(me.sun_dev_e-me.curr_deviation_e)+(me.sun_dev_h-me.curr_deviation_h)*(me.sun_dev_h-me.curr_deviation_h));
			if (me.sun_dev < me.sun_lock) {
				me.printStats(me.type~": Locked onto sun, lost target. ");
				me.lock_on_sun = TRUE;
				me.free = TRUE;
			}
		}
	},

	checkForLOS: func () {
		if (pickingMethod == TRUE and me.guidance != "gps" and me.guidance != "unguided" and me.guidance != "inertial") {
			me.xyz          = {"x":me.coord.x(),                  "y":me.coord.y(),                 "z":me.coord.z()};
		    me.directionLOS = {"x":me.t_coord.x()-me.coord.x(),   "y":me.t_coord.y()-me.coord.y(),  "z":me.t_coord.z()-me.coord.z()};

			# Check for terrain between own weapon and target:
			me.terrainGeod = get_cart_ground_intersection(me.xyz, me.directionLOS);
			if (me.terrainGeod == nil) {
				me.lostLOS = FALSE;
				return;
			} else {
				me.terrain = geo.Coord.new();
				me.terrain.set_latlon(me.terrainGeod.lat, me.terrainGeod.lon, me.terrainGeod.elevation);
				me.maxDist = me.coord.direct_distance_to(me.t_coord)-1;#-1 is to avoid z-fighting distance
				me.terrainDist = me.coord.direct_distance_to(me.terrain);
				if (me.terrainDist >= me.maxDist) {
					me.lostLOS = FALSE;
					return;
				}
			}
			if (me.reaquire == TRUE) {
				if (me.lostLOS == FALSE) {
					me.printStats(me.type~": Not guiding (lost line of sight, trying to reaquire)");
				}
				me.lostLOS = TRUE;
				me.guiding = FALSE;
				return;
			} else {
				if (me.lostLOS == FALSE) {
					me.printStats(me.type~": Gave up (lost line of sight)");
				}
				me.lostLOS = TRUE;
				me.free = TRUE;
				return;
			}
		}
		me.lostLOS = FALSE;
	},

	checkForGuidance: func () {
		if(me.speed_m < me.min_speed_for_guiding) {
			# it doesn't guide at lower speeds
			me.guiding = FALSE;
			if (me.tooLowSpeed == FALSE) {
				me.printStats(me.type~": Not guiding (too low speed)");
			}
			me.tooLowSpeed = TRUE;
		} elsif ((me.guidance == "semi-radar" and me.is_painted(me.Tgt) == FALSE) or (me.guidance =="laser" and me.is_laser_painted(me.Tgt) == FALSE) ) {
			# if its semi-radar guided and the target is no longer painted
			me.guiding = FALSE;
			if (me.reaquire == TRUE) {
				if (me.semiLostLock == FALSE) {
					me.printStats(me.type~": Not guiding (lost radar reflection, trying to reaquire)");
				}
				me.semiLostLock = TRUE;
			} else {
				me.free = TRUE;
			}			
		} elsif (me.guidance == "radiation" and me.is_radiating_me(me.Tgt) == FALSE) {
			# if its radiation guided and the target is not illuminating us with radiation
			me.guiding = FALSE;
			if (me.reaquire == TRUE) {
				if (me.radLostLock == FALSE) {
					me.printStats(me.type~": Not guiding (lost radiation, trying to reaquire)");
				}
				me.radLostLock = TRUE;
			} else {
				me.free = TRUE;
			}			
		} elsif ((me.dist_curr_direct*M2NM > me.detect_range_curr_nm or !me.FOV_check(me.curr_deviation_h, me.curr_deviation_e, me.max_seeker_dev)) and me.guidance != "gps" and me.guidance != "inertial") {
			# target is not in missile seeker view anymore
			#if (me.curr_deviation_e > me.max_seeker_dev) {
			#	me.viewLost = "Target is above seeker view.";
			#} elsif (me.curr_deviation_e < (-1 * me.max_seeker_dev)) {
			#	me.viewLost = "Target is below seeker view. "~(me.dist_curr*M2NM)~" NM and "~((me.coord.alt()-me.t_coord.alt())*M2FT)~" ft diff.";
			#} elsif (me.curr_deviation_h > me.max_seeker_dev) {
			#	me.viewLost = "Target is right of seeker view.";
			#} else {
			#	me.viewLost = "Target is left of seeker view.";
			#}
			if (me.fovLost == FALSE) {
				me.printStats(me.type~": "~me.callsign~" is not in seeker view.");#~me.viewLost);
			}
			if (me.reaquire == FALSE) {
				me.free = TRUE;
			} else {
				me.fovLost = TRUE;
				me.guiding = FALSE;
			}
		} elsif (me.all_aspect == FALSE and me.rear_aspect(me.coord, me.Tgt) == FALSE) {
			me.guiding = FALSE;
           	if (me.heatLostLock == FALSE) {
        		me.printStats(me.type~": Missile lost heat lock, attempting to reaquire..");
        	}
        	me.heatLostLock = TRUE;
		} elsif (me.life_time < me.drop_time) {
			me.guiding = FALSE;
		} elsif (me.semiLostLock == TRUE) {
			me.printStats(me.type~": Reaquired reflection.");
			me.semiLostLock = FALSE;
		} elsif (me.radLostLock == TRUE) {
			me.printStats(me.type~": Reaquired radiation.");
			me.radLostLock = FALSE;
		} elsif (me.heatLostLock == TRUE) {
	       	me.printStats(me.type~": Regained heat lock.");
	       	me.heatLostLock = FALSE;
	    } elsif (me.tooLowSpeed == TRUE) {
			me.printStats(me.type~": Gained speed and started guiding.");
			me.tooLowSpeed = FALSE;
		} elsif (me.fovLost == TRUE) {
			me.printStats(me.type~": Regained view of target.");
			me.fovLost = FALSE;
		} elsif (me.loal and me.maddog) {
			me.printStats(me.type~": "~me.callsign~" is potential target. ("~me.Tgt.get_type()~","~me.class~")");
		}
	},

	adjustToKeepLock: func {
		if (me.guidance != "gps" and me.guidance != "inertial") {
			if (!me.FOV_check(me.curr_deviation_h+me.raw_steer_signal_head, me.curr_deviation_e+me.raw_steer_signal_elev, me.max_seeker_dev) and me.fov_radial != 0) {
				# the commanded steer order will make the missile lose its lock, to prevent that we reduce the steering just enough so lock wont be lost.
				me.factorKeep = me.max_seeker_dev/me.fov_radial;
				me.raw_steer_signal_elev = (me.curr_deviation_e+me.raw_steer_signal_elev)*me.factorKeep-me.curr_deviation_e;
				me.raw_steer_signal_head = (me.curr_deviation_h+me.raw_steer_signal_head)*me.factorKeep-me.curr_deviation_h;
			}
		}
	},

	canSeekerKeepUp: func () {
		if (!me.newTargetAssigned and me.last_deviation_e != nil and (me.guidance == "heat" or me.guidance == "vision") and me.prevGuidance == me.guidance and me.prevTarget == me.Tgt) {
			# calculate if the seeker can keep up with the angular change of the target
			#
			# missile own movement is subtracted from this change due to seeker being on gyroscope
			#
			if (me.caged == FALSE) {
				me.dve_dist = me.curr_deviation_e - me.last_deviation_e + me.last_track_e;
				me.dvh_dist = me.curr_deviation_h - me.last_deviation_h + me.last_track_h;
			} else {
				me.dve_dist = me.curr_deviation_e - me.last_deviation_e;
				me.dvh_dist = me.curr_deviation_h - me.last_deviation_h;
			}
			me.deviation_per_sec = math.sqrt(me.dve_dist*me.dve_dist+me.dvh_dist*me.dvh_dist)/me.dt;

			if (me.deviation_per_sec > me.angular_speed) {
				# lost lock due to angular speed limit
				me.printStats("%s: %.1f deg/s too fast angular change for seeker head.", me.type, me.deviation_per_sec);
				me.free = TRUE;
			}
		}
		me.last_deviation_e = me.curr_deviation_e;
		me.last_deviation_h = me.curr_deviation_h;
	},

	cruiseAndLoft: func () {
		#
		# cruise, loft, cruise-missile
		#
		if (me.guiding == FALSE) {
			return;
		}
		me.loft_angle = 15;# notice Shinobi used 26.5651 degs, but Raider1 found a source saying 10-20 degs.
		me.cruise_or_loft = FALSE;
		me.time_before_snap_up = me.drop_time * 3;
		me.limitGs = FALSE;
		
        if(me.loft_alt != 0 and me.snapUp == FALSE) {
        	# this is for Air to ground/sea cruise-missile (SCALP, Sea-Eagle, Taurus, Tomahawk, RB-15...)

        	var code = 0;# 0 = old, 1 = new, 2 = angle

			if (code == 2) {# angle code
				me.terrainStage += 1;# only 1 terrain check in each stage.
				if (me.terrainStage > 5) {
					me.terrainStage = 0;
				}
				if (me.terrainStage == 0) {
					# down
					me.terrainUnder = geo.elevation(me.coord.lat(),me.coord.lon());
				} elsif (me.terrainStage == 1) {
					# level
					me.geoPlus = me.nextGeoloc(me.coord.lat(), me.coord.lon(), me.hdg, me.old_speed_fps, 5, me.coord.alt());

					xyz = {"x":me.coord.x(),                  "y":me.coord.y(),                 "z":me.coord.z()};
					dir = {"x":me.geoPlus.x()-me.coord.x(),  "y":me.geoPlus.y()-me.coord.y(), "z":me.geoPlus.z()-me.coord.z()};
					me.groundIntersectResult = get_cart_ground_intersection(xyz, dir);
	                if(me.groundIntersectResult == nil) {
	                    me.terrainLevel = 1000000;
	                } else {
	                    GroundIntersectCoord.set_latlon(me.groundIntersectResult.lat, me.groundIntersectResult.lon, me.groundIntersectResult.elevation);
	                    me.terrainLevel = me.coord.direct_distance_to(me.groundIntersectCoord);
	                }
				} elsif (me.terrainStage == 2) {
					# negative angle
					me.geoPlus = me.nextGeoloc(me.coord.lat(), me.coord.lon(), me.hdg, me.old_speed_fps, 5, me.coord.alt());

					xyz = {"x":me.coord.x(),                  "y":me.coord.y(),                 "z":me.coord.z()};
					dir = {"x":me.geoPlus.x()-me.coord.x(),  "y":me.geoPlus.y()-me.coord.y(), "z":me.geoPlus.z()-me.coord.z()};
					me.groundIntersectResult = get_cart_ground_intersection(xyz, dir);
	                if(me.groundIntersectResult == nil) {
	                    me.terrainLevel = 1000000;
	                } else {
	                    GroundIntersectCoord.set_latlon(me.groundIntersectResult.lat, me.groundIntersectResult.lon, me.groundIntersectResult.elevation);
	                    me.terrainLevel = me.coord.direct_distance_to(me.groundIntersectCoord);
	                }
				}

        	} elsif (code == 1) {# Shinobi's new code
        		        		#Variable declaration
	            var No_terrain = 0;
	            var distance_Target = 0;
	            var xyz = nil;
	            var dir = nil;
	            var GroundIntersectCoord = geo.Coord.new();
	            var howmany = 0;
	            var altitude_step = 30;
	            
	        	# detect terrain for use in terrain following
	        	me.nextGroundElevationMem[1] -= 1;
	            #First we need origin coordinates we transorfm it in xyz        
	            xyz = {"x":me.coord.x(),                  "y":me.coord.y(),                 "z":me.coord.z()};
	            
	            #Then we need the coordinate of the future point at let say 20 dt
	            me.geoPlus4 = me.nextGeoloc(me.coord.lat(), me.coord.lon(), me.hdg, me.old_speed_fps, 5);
	            me.geoPlus4.set_alt(geo.elevation(me.geoPlus4.lat(),me.geoPlus4.lon()));
	            
	            #Loop
	            while(No_terrain != 1){
	                howmany = howmany + 1;
	                #We finalize the vector
	                dir = {"x":me.geoPlus4.x()-me.coord.x(),  "y":me.geoPlus4.y()-me.coord.y(), "z":me.geoPlus4.z()-me.coord.z()};
	                #We measure distance to be sure that the ground intersection is closer than geoPlus4 
	                distance_Target = me.coord.direct_distance_to(me.geoPlus4);
	                # Check for terrain between own aircraft and other:
	                GroundIntersectResult = get_cart_ground_intersection(xyz, dir);
	                if(GroundIntersectResult == nil){
	                    No_terrain = 1;
	                #Checking if the distance to the intersection is before or after geoPlus4
	                }else{
	                    GroundIntersectCoord.set_latlon(GroundIntersectResult.lat, GroundIntersectResult.lon, GroundIntersectResult.elevation);
	                    if(me.coord.direct_distance_to(GroundIntersectCoord)>distance_Target){
	                        No_terrain = 1;
	                    }else{
	                        #Raising geoPlus4 altitude by 100 meters
	                        me.geoPlus4.set_alt(me.geoPlus4.alt()+altitude_step);
	                        #print("Alt too low :" ~ me.geoPlus4.alt() ~ "; Raising alt by 30 meters (100 feet)");
	                    }
	                }
	                
	            }
	            #print("There was : " ~ howmany ~ " iteration of the ground loop");
	            me.nextGroundElevation = me.geoPlus4.alt();
	            

	            me.Daground = 0;# zero for sealevel in case target is ship. Don't shoot A/S missiles over terrain. :)
	            if(me.Tgt.get_type() == SURFACE or me.follow == TRUE) {
	                me.Daground = me.nextGroundElevation * M2FT;
	            }
	            me.loft_alt_curr = me.loft_alt;
	            if (me.dist_curr < me.old_speed_fps * 6 * FT2M and me.dist_curr > me.old_speed_fps * 4 * FT2M) {
	            	# the missile lofts a bit at the end to avoid APN to slam it into ground before target is reached.
	            	# end here is between 2.5-4 seconds
	            	me.loft_alt_curr = me.loft_alt*2;
	            }
	            if (me.dist_curr > me.old_speed_fps * 4 * FT2M) {# need to give the missile time to do final navigation
	                # it's 1 or 2 seconds for this kinds of missiles...
	                me.t_alt_delta_ft = (me.loft_alt_curr + me.Daground - me.alt_ft);
	                me.printGuideDetails("var t_alt_delta_m : "~me.t_alt_delta_ft*FT2M);
	                if(me.loft_alt_curr + me.Daground > me.alt_ft) {
	                    # 200 is for a very short reaction to terrain
	                    me.printGuideDetails("Moving up");
	                    me.raw_steer_signal_elev = -me.pitch + math.atan2(me.t_alt_delta_ft, me.old_speed_fps * me.dt * 5) * R2D;
	                } else {
	                    # that means a dive angle of 22.5° (a bit less 
	                    # coz me.alt is in feet) (I let this alt in feet on purpose (more this figure is low, more the future pitch is high)
	                    me.printGuideDetails("Moving down");
	                    me.slope = me.clamp(me.t_alt_delta_ft / 300, -7.5, 0);# the lower the desired alt is, the steeper the slope.
	                    me.raw_steer_signal_elev = -me.pitch + me.clamp(math.atan2(me.t_alt_delta_ft, me.old_speed_fps * me.dt * 5) * R2D, me.slope, 0);
	                }
	                me.cruise_or_loft = TRUE;
	            } elsif (me.dist_curr > 500) {
	                # we put 9 feets up the target to avoid ground at the
	                # last minute...
	                me.printGuideDetails("less than 1000 m to target");
	                #me.raw_steer_signal_elev = -me.pitch + math.atan2(t_alt_delta_m + 100, me.dist_curr) * R2D;
	                #me.cruise_or_loft = 1;
	            } else {
	            	me.printGuideDetails("less than 500 m to target");
	            }
	            if (me.cruise_or_loft == TRUE) {
	            	me.printGuideDetails(" pitch "~me.pitch~" + me.raw_steer_signal_elev "~me.raw_steer_signal_elev);
	            }
        	} else {#Older code
	        	# detect terrain for use in terrain following
	        	me.nextGroundElevationMem[1] -= 1;
	            me.geoPlus2 = me.nextGeoloc(me.coord.lat(), me.coord.lon(), me.hdg, me.old_speed_fps, me.dt*5);
	            me.geoPlus3 = me.nextGeoloc(me.coord.lat(), me.coord.lon(), me.hdg, me.old_speed_fps, me.dt*10);
	            me.geoPlus4 = me.nextGeoloc(me.coord.lat(), me.coord.lon(), me.hdg, me.old_speed_fps, me.dt*20);
	            me.e1 = geo.elevation(me.coord.lat(), me.coord.lon());# This is done, to make sure is does not decline before it has passed obstacle.
	            me.e2 = geo.elevation(me.geoPlus2.lat(), me.geoPlus2.lon());# This is the main one.
	            me.e3 = geo.elevation(me.geoPlus3.lat(), me.geoPlus3.lon());# This is an extra, just in case there is an high cliff it needs longer time to climb.
	            me.e4 = geo.elevation(me.geoPlus4.lat(), me.geoPlus4.lon());
				if (me.e1 != nil) {
	            	me.nextGroundElevation = me.e1;
	            } else {
	            	me.printFlight(me.type~": nil terrain, blame terrasync! Cruise-missile keeping altitude.");
	            }
	            if (me.e2 != nil and me.e2 > me.nextGroundElevation) {
	            	me.nextGroundElevation = me.e2;
	            	if (me.e2 > me.nextGroundElevationMem[0] or me.nextGroundElevationMem[1] < 0) {
	            		me.nextGroundElevationMem[0] = me.e2;
	            		me.nextGroundElevationMem[1] = 5;
	            	}
	            }
	            if (me.nextGroundElevationMem[0] > me.nextGroundElevation) {
	            	me.nextGroundElevation = me.nextGroundElevationMem[0];
	            }
	            if (me.e3 != nil and me.e3 > me.nextGroundElevation) {
	            	me.nextGroundElevation = me.e3;
	            }
	            if (me.e4 != nil and me.e4 > me.nextGroundElevation) {
	            	me.nextGroundElevation = me.e4;
	            }

	            me.Daground = 0;# zero for sealevel in case target is ship. Don't shoot A/S missiles over terrain. :)
	            if(me.Tgt.get_type() == SURFACE or me.follow == TRUE) {
	                me.Daground = me.nextGroundElevation * M2FT;
	            }
	            me.loft_alt_curr = me.loft_alt;
	            if (me.dist_curr < me.old_speed_fps * 6 * FT2M and me.dist_curr > me.old_speed_fps * 4 * FT2M) {
	            	# the missile lofts a bit at the end to avoid APN to slam it into ground before target is reached.
	            	# end here is between 2.5-4 seconds
	            	me.loft_alt_curr = me.loft_alt*2;
	            }
	            if (me.dist_curr > me.old_speed_fps * 4 * FT2M) {# need to give the missile time to do final navigation
	                # it's 1 or 2 seconds for this kinds of missiles...
	                me.t_alt_delta_ft = (me.loft_alt_curr + me.Daground - me.alt_ft);
	                me.printGuideDetails("var t_alt_delta_m : "~me.t_alt_delta_ft*FT2M);
	                if(me.loft_alt_curr + me.Daground > me.alt_ft) {
	                    # 200 is for a very short reaction to terrain
	                    me.printGuideDetails("Moving up");
	                    me.raw_steer_signal_elev = -me.pitch + math.atan2(me.t_alt_delta_ft, me.old_speed_fps * me.dt * 5) * R2D;
	                } else {
	                    # that means a dive angle of 22.5° (a bit less 
	                    # coz me.alt is in feet) (I let this alt in feet on purpose (more this figure is low, more the future pitch is high)
	                    me.printGuideDetails("Moving down");
	                    me.slope = me.clamp(me.t_alt_delta_ft / 300, -7.5, 0);# the lower the desired alt is, the steeper the slope.
	                    me.raw_steer_signal_elev = -me.pitch + me.clamp(math.atan2(me.t_alt_delta_ft, me.old_speed_fps * me.dt * 5) * R2D, me.slope, 0);
	                }
	                me.cruise_or_loft = TRUE;
	            } elsif (me.dist_curr > 500) {
	                # we put 9 feets up the target to avoid ground at the
	                # last minute...
	                me.printGuideDetails("less than 1000 m to target");
	                #me.raw_steer_signal_elev = -me.pitch + math.atan2(t_alt_delta_m + 100, me.dist_curr) * R2D;
	                #me.cruise_or_loft = 1;
	            } else {
	            	me.printGuideDetails("less than 500 m to target");
	            }
	            if (me.cruise_or_loft == TRUE) {
	            	me.printGuideDetails(" pitch "~me.pitch~" + me.raw_steer_signal_elev "~me.raw_steer_signal_elev);
	            }
	        }
        } elsif (me.rail == TRUE and me.rail_forward == FALSE and me.rotate_token == FALSE) {
			# tube launched missile turns towards target

			me.raw_steer_signal_elev = me.curr_deviation_e;
			me.printGuideDetails("Turning, desire "~me.t_elev_deg~" degs pitch.");
			me.cruise_or_loft = TRUE;
			me.limitGs = TRUE;
			if (math.abs(me.curr_deviation_e) < 20) {
				me.rotate_token = TRUE;
				me.printGuide("Is last turn, snap-up/PN takes it from here..")
			}
		} elsif (me.snapUp == TRUE and me.t_elev_deg > me.clamp(-80/me.speed_m,-30,-5) and me.dist_curr * M2NM > me.speed_m * 3
			 and me.t_elev_deg < me.loft_angle #and me.t_elev_deg > -7.5
			 and me.dive_token == FALSE) {
			# lofting: due to target is more than 10 miles out and we havent reached 
			# our desired cruising alt, and the elevation to target is less than lofting angle.
			# The -7.5 limit, is so the seeker don't lose track of target when lofting.
			if (me.life_time < me.time_before_snap_up and me.coord.alt() * M2FT < me.loft_alt) {
				me.printGuide("preparing for lofting");
				me.cruise_or_loft = TRUE;
			} elsif (me.coord.alt() * M2FT < me.loft_alt) {
				me.raw_steer_signal_elev = -me.pitch + me.loft_angle;
				me.limitGs = TRUE;
				me.printGuide("Lofting %04.1f degs, dev is %04.1f", me.loft_angle, me.raw_steer_signal_elev);
			} else {
				me.dive_token = TRUE;
				me.printGuide("Stopped lofting");
			}
			me.cruise_or_loft = TRUE;
		} elsif (me.snapUp == TRUE and me.coord.alt() > me.t_coord.alt() and me.last_cruise_or_loft == TRUE
		         and me.t_elev_deg > me.clamp(-80/me.speed_m,-30,-5) and me.dist_curr * M2NM > me.speed_m * 3) {
			# cruising: keeping altitude since target is below and more than -45 degs down

			me.ratio = (g_fps * me.dt)/me.old_speed_fps;
            me.attitude = 0;

            if (me.ratio < 1 and me.ratio > -1) {
                me.attitude = math.asin(me.ratio)*R2D;
            }

			me.raw_steer_signal_elev = -me.pitch + me.attitude;
			me.printGuideDetails("Cruising, desire "~me.attitude~" degs pitch.");
			me.cruise_or_loft = TRUE;
			me.limitGs = TRUE;
			me.dive_token = TRUE;
		} elsif (me.last_cruise_or_loft == TRUE and math.abs(me.curr_deviation_e) > 25 and me.life_time > me.time_before_snap_up) {
			# after cruising, point the missile in the general direction of the target, before PN starts guiding.
			me.printGuide("Rotating toward target");
			me.raw_steer_signal_elev = me.curr_deviation_e;
			me.cruise_or_loft = TRUE;
			#me.limitGs = TRUE;

			# TODO: this needs to be worked on.
		}
	},

	level: func () {
		me.attitudePN = math.atan2(-(me.speed_down_fps+g_fps * me.dt), me.speed_horizontal_fps ) * R2D;
        me.gravComp = me.pitch - me.attitudePN;
        #printf("Gravity compensation %0.2f degs", me.gravComp);
        me.track_signal_e = me.gravComp * !me.free;
        me.track_signal_h = 0;
        me.printGuide("Trying to keep current %04.1f deg pitch.", me.pitch);
	},

	pitchGyro: func () {
        me.track_signal_e = (me.keepPitch-me.pitch) * !me.free;
        me.track_signal_h = 0;
        me.printGuide("Gyro keeping %04.1f deg pitch. Current is %04.1f deg.", me.keepPitch, me.pitch);
	},

	APN: func () {
		#
		# augmented proportional navigation
		#
		if (me.guiding == TRUE and me.free == FALSE and me.dist_last != nil and me.last_dt != 0 and me.newTargetAssigned==FALSE) {
			# augmented proportional navigation for heading #
			#################################################

			if (me.guidanceLaw == "direct") {
				# pure pursuit 
				me.raw_steer_signal_head = me.curr_deviation_h;
				if (me.cruise_or_loft == FALSE) {
					me.raw_steer_signal_elev = me.curr_deviation_e;
					me.attitudePN = math.atan2(-(me.speed_down_fps+g_fps * me.dt), me.speed_horizontal_fps ) * R2D;
		            me.gravComp = me.pitch - me.attitudePN;
		            #printf("Gravity compensation %0.2f degs", me.gravComp);
		            me.raw_steer_signal_elev += me.gravComp;
				}
				return;
			} elsif (find("APN", me.guidanceLaw)) {
				me.apn = 1;
			} else {
				me.apn = 0;
			}
			if ((me.dist_direct_last - me.dist_curr_direct) < 0) {
				# might happen if missile is cannot catch up to target. It might still be accelerating or it has lost too much speed.
				# PN needs closing rate to be positive to give meaningful steering commands. So we fly straight and hope for better closing rate.
				me.raw_steer_signal_head = 0;
				if (me.cruise_or_loft == FALSE) {
					me.raw_steer_signal_elev = 0;
					me.attitudePN = math.atan2(-(me.speed_down_fps+g_fps * me.dt), me.speed_horizontal_fps ) * R2D;
			        me.gravComp = me.pitch - me.attitudePN;
			        #printf("Gravity compensation %0.2f degs", me.gravComp);
			        me.printGuide("Negative closing rate, doing pure pursuit.");
			        me.raw_steer_signal_elev += me.gravComp;
			    }
		        return;
			}

			me.horz_closing_rate_fps = me.clamp(((me.dist_last - me.dist_curr)*M2FT)/me.dt, 0, 1000000);#clamped due to cruise missiles that can fly slower than target.
			me.printGuideDetails("Horz closing rate: %05d ft/sec", me.horz_closing_rate_fps);

			me.c_dv = geo.normdeg180(me.t_course-me.last_t_course);
			
			me.line_of_sight_rate_rps = (D2R*me.c_dv)/me.dt;#positive clockwise

			me.printGuideDetails("LOS rate: %06.4f rad/s", me.line_of_sight_rate_rps);

			#if (me.before_last_t_coord != nil) {
			#	var t_heading = me.before_last_t_coord.course_to(me.t_coord);
			#	var t_dist   = me.before_last_t_coord.distance_to(me.t_coord);
			#	var t_dist_dir   = me.before_last_t_coord.direct_distance_to(me.t_coord);
			#	var t_climb      = me.t_coord.alt() - me.before_last_t_coord.alt();
			#	var t_horz_speed = (t_dist*M2FT)/(me.dt+me.last_dt);
			#	var t_speed      = (t_dist_dir*M2FT)/(me.dt+me.last_dt);
			#} else {
			#	var t_heading = me.last_t_coord.course_to(me.t_coord);
			#	var t_dist   = me.last_t_coord.distance_to(me.t_coord);
			#	var t_dist_dir   = me.last_t_coord.direct_distance_to(me.t_coord);
			#	var t_climb      = me.t_coord.alt() - me.last_t_coord.alt();
			#	var t_horz_speed = (t_dist*M2FT)/me.dt;
			#	var t_speed      = (t_dist_dir*M2FT)/me.dt;
			#}
			
			#var t_pitch      = math.atan2(t_climb,t_dist)*R2D;
			
			# calculate target acc as normal to LOS line:
			if ((me.flareLock == FALSE and me.chaffLock == FALSE) or me.t_heading == nil) {
				me.t_heading        = me.Tgt.get_heading();
				me.t_pitch          = me.Tgt.get_Pitch();
				me.t_speed_fps      = me.Tgt.get_Speed()*KT2FPS;#true airspeed
			} elsif (me.flarespeed_fps != nil) {
				me.t_speed_fps      = me.flarespeed_fps;#true airspeed
			}

			#if (me.last_t_coord.direct_distance_to(me.t_coord) != 0) {
			#	# taking sideslip and AoA into consideration:
			#	me.t_heading    = me.last_t_coord.course_to(me.t_coord);
			#	me.t_climb      = me.t_coord.alt() - me.last_t_coord.alt();
			#	me.t_dist       = me.last_t_coord.distance_to(me.t_coord);
			#	me.t_pitch      = math.atan2(me.t_climb, me.t_dist) * R2D;
			#} elsif (me.Tgt.get_Speed() > 25) {
				# target position was not updated since last loop.
				# to avoid confusing the navigation, we just fly
				# straight.
				#print("not updated");
			#	return;
			#}


			
			me.t_horz_speed_fps     = math.abs(math.cos(me.t_pitch*D2R)*me.t_speed_fps);#flawed due to AoA is not taken into account, but dont have that info.
			me.t_LOS_norm_head_deg  = me.t_course + 90;#when looking at target this direction will be 90 deg right of target
			me.t_LOS_norm_speed_fps = math.cos((me.t_LOS_norm_head_deg - me.t_heading)*D2R)*me.t_horz_speed_fps;

			if (me.last_t_norm_speed == nil) {
				me.last_t_norm_speed = me.t_LOS_norm_speed_fps;
			}

			me.t_LOS_norm_acc_fps2  = (me.t_LOS_norm_speed_fps - me.last_t_norm_speed)/me.dt;

			me.last_t_norm_speed = me.t_LOS_norm_speed_fps;

			# acceleration perpendicular to instantaneous line of sight in feet/sec^2
			me.acc_lateral_fps2 = me.pro_constant*me.line_of_sight_rate_rps*me.horz_closing_rate_fps+me.apn*me.pro_constant*me.t_LOS_norm_acc_fps2/2;
			#printf("horz acc = %.1f + %.1f", proportionality_constant*line_of_sight_rate_rps*horz_closing_rate_fps, proportionality_constant*t_LOS_norm_acc/2);

			# now translate that sideways acc to an angle:
			me.velocity_vector_length_fps = me.clamp(me.old_speed_horz_fps, 0.0001, 1000000);
			me.commanded_lateral_vector_length_fps = me.acc_lateral_fps2*me.dt;

			#isosceles triangle:
			me.raw_steer_signal_head = math.asin(me.clamp((me.commanded_lateral_vector_length_fps*0.5)/me.velocity_vector_length_fps,-1,1))*R2D*2;
			#me.raw_steer_signal_head = math.atan2(me.commanded_lateral_vector_length_fps, me.velocity_vector_length_fps)*R2D; # flawed, its not a right triangle

			#printf("Proportional lead: %0.1f deg horz", -(me.curr_deviation_h-me.raw_steer_signal_head));

			#me.print(sprintf("LOS-rate=%.2f rad/s - closing-rate=%.1f ft/s",line_of_sight_rate_rps,horz_closing_rate_fps));
			#me.print(sprintf("commanded-perpendicular-acceleration=%.1f ft/s^2", acc_lateral_fps2));
			#printf("horz leading by %.1f deg, commanding %.1f deg", me.curr_deviation_h, me.raw_steer_signal_head);

			if (me.cruise_or_loft == FALSE) {# and me.last_cruise_or_loft == FALSE
				me.fixed_aim = nil;
				me.fixed_aim_time = nil;
				if (find("PN",me.guidanceLaw) != -1 and size(me.guidanceLaw) > 3) {
					me.extra = right(me.guidanceLaw, 4);
					me.fixed_aim = num(left(me.extra, 2));
					me.fixed_aim_time = num(right(me.extra, 2));
		        }
		        if (me.fixed_aim != nil and me.life_time < me.fixed_aim_time) {
		        	me.raw_steer_signal_elev = me.curr_deviation_e+me.fixed_aim;
					me.attitudePN = math.atan2(-(me.speed_down_fps+g_fps * me.dt), me.speed_horizontal_fps ) * R2D;
		            me.gravComp = me.pitch - me.attitudePN;
		            #printf("Gravity compensation %0.2f degs", me.gravComp);
		            me.raw_steer_signal_elev += me.gravComp;
				} else {
					# augmented proportional navigation for elevation #
					###################################################
					#me.print(me.guidanceLaw~" in fully control");
					me.vert_closing_rate_fps = me.clamp(((me.dist_direct_last - me.dist_curr_direct)*M2FT)/me.dt, 0.0, 1000000);
					me.printGuideDetails("Vert closing rate: %05d ft/sec", me.vert_closing_rate_fps);
					me.line_of_sight_rate_up_rps = (D2R*(me.t_elev_deg-me.last_t_elev_deg))/me.dt;

					# calculate target acc as normal to LOS line: (up acc is positive)
					me.t_approach_bearing             = me.t_course + 180;
					

					# used to do this with trigonometry, but vector math is simpler to understand: (they give same result though)
					me.t_LOS_elev_norm_speed     = me.scalarProj(me.t_heading,me.t_pitch,me.t_speed_fps,me.t_approach_bearing,me.t_elev_deg*-1 +90);

					if (me.last_t_elev_norm_speed == nil) {
						me.last_t_elev_norm_speed = me.t_LOS_elev_norm_speed;
					}

					me.t_LOS_elev_norm_acc            = (me.t_LOS_elev_norm_speed - me.last_t_elev_norm_speed)/me.dt;
					me.last_t_elev_norm_speed          = me.t_LOS_elev_norm_speed;
					#printf("Target acc. perpendicular to LOS (positive up): %.1f G.", me.t_LOS_elev_norm_acc/g_fps);

					me.acc_upwards_fps2 = me.pro_constant*me.line_of_sight_rate_up_rps*me.vert_closing_rate_fps+me.apn*me.pro_constant*me.t_LOS_elev_norm_acc/2;
					#printf("vert acc = %.2f + %.2f G", me.pro_constant*me.line_of_sight_rate_up_rps*me.vert_closing_rate_fps/g_fps, (me.apn*me.pro_constant*me.t_LOS_elev_norm_acc/2)/g_fps);
					me.velocity_vector_length_fps = me.clamp(me.old_speed_fps, 0.0001, 1000000);
					me.commanded_upwards_vector_length_fps = me.acc_upwards_fps2*me.dt;

					me.raw_steer_signal_elev = math.asin(me.clamp((me.commanded_upwards_vector_length_fps*0.5)/me.velocity_vector_length_fps,-1,1))*R2D*2;
					#me.raw_steer_signal_elev = math.atan2(me.commanded_upwards_vector_length_fps, me.velocity_vector_length_fps)*R2D;

					# now compensate for the predicted gravity drop of attitude:				
		            me.attitudePN = math.atan2(-(me.speed_down_fps+g_fps * me.dt), me.speed_horizontal_fps ) * R2D;
		            me.gravComp = me.pitch - me.attitudePN;
		            #printf("Gravity compensation %0.2f degs", me.gravComp);
		            me.raw_steer_signal_elev += me.gravComp;

					#printf("Proportional lead: %0.1f deg elev", -(me.curr_deviation_e-me.raw_steer_signal_elev));
				}
			}
		}
	},

	scalarProj: func (head, pitch, magn, projHead, projPitch) {
		head      = head*D2R;
		pitch     = pitch*D2R;
		projHead  = projHead*D2R;
		projPitch = projPitch*D2R;

		# Convert the 2 polar vectors to cartesian:

		# velocity vector of target
		me.ax = magn * math.cos(pitch) * math.cos(-head);#north
		me.ay = magn * math.cos(pitch) * math.sin(-head);#west
		me.az = magn * math.sin(pitch);                  #up

		# vector pointing from target perpendicular to LOS
		me.bx = 1 * math.cos(projPitch) * math.cos(-projHead);# north
		me.by = 1 * math.cos(projPitch) * math.sin(-projHead);# west
		me.bz = 1 * math.sin(projPitch);                      # up

		# the dot product is the scalar projection. And represent the target velocity perpendicular to LOS
		me.result = (me.ax * me.bx + me.ay * me.by + me.az * me.bz)/1;
		return me.result;
	},

	map: func (value, leftMin, leftMax, rightMin, rightMax) {
	    # Figure out how 'wide' each range is
	    var leftSpan = leftMax - leftMin;
	    var rightSpan = rightMax - rightMin;

	    # Convert the left range into a 0-1 range (float)
	    var valueScaled = (value - leftMin) / leftSpan;

	    # Convert the 0-1 range into a value in the right range.
	    return rightMin + (valueScaled * rightSpan);
	},

	proximity_detection: func {

		####Ground interaction
        me.ground = geo.elevation(me.coord.lat(), me.coord.lon());
        if(me.ground != nil) {
            if(me.ground > me.coord.alt()) {
            	me.event = "exploded";
            	if(me.life_time < me.arming_time) {
                	me.event = "landed disarmed";
            	}
            	if (me.Tgt != nil and me.direct_dist_m == nil) {
            		# maddog might go here
            		me.Tgt = nil;
            		#me.direct_dist_m = me.coord.direct_distance_to(me.Tgt.get_Coord());
            	}
            	if ((me.Tgt != nil and me.direct_dist_m != nil) or me.Tgt == nil) {
            		me.explode("Hit terrain.", me.event);
            		return TRUE;
            	}
            }
        }

		if (me.Tgt != nil and me.t_coord != nil and me.guidance != "inertial") {
			# Get current direct distance.
			me.cur_dir_dist_m = me.coord.direct_distance_to(me.t_coord);
			if (me.useHitInterpolation == TRUE) { # use Nikolai V. Chr. interpolation
				if ( me.direct_dist_m != nil and me.life_time > me.arming_time) {
					#me.print("distance to target_m = "~cur_dir_dist_m~" prev_distance to target_m = "~me.direct_dist_m);
					if ( me.cur_dir_dist_m > me.direct_dist_m and me.cur_dir_dist_m < 250) {
						#me.print("passed target");
						# Distance to target increase, trigger explosion.
						me.explode("Passed target.");
						return TRUE;
					}
					if (me.life_time > me.selfdestruct_time or (me.destruct_when_free == TRUE and me.free == TRUE)) {
						me.explode("Selfdestructed.");
					    return TRUE;
					}
				}
			} else { # use Fabien Barbier trigonometry
				var BC = me.cur_dir_dist_m;
		        var AC = me.direct_dist_m;
		        if(me.last_coord != nil)
		        {
		            var AB = me.last_coord.direct_distance_to(me.coord);
			        # 
			        #  A_______C'______ B
			        #   \      |      /     We have a system  :   x²   = CB² - C'B²
			        #    \     |     /                            C'B  = AB  - AC'
			        #     \    |x   /                             AC'² = A'C² + x²
			        #      \   |   /
			        #       \  |  /        Then, if I made no mistake : x² = BC² - ((BC²-AC²+AB²)/(2AB))²
			        #        \ | /
			        #         \|/
			        #          C
			        # C is the target. A is the last missile positioin and B tha actual. 
			        # For very high speed (more than 1000 m /seconds) we need to know if,
			        # between the position A and the position B, the distance x to the 
			        # target is enough short to proxiimity detection.
			        
			        # get current direct distance.			        
			        if(me.direct_dist_m != nil)
			        {
			            var x2 = BC * BC - (((BC * BC - AC * AC + AB * AB) / (2 * AB)) * ((BC * BC - AC * AC + AB * AB) / (2 * AB)));
			            if(BC * BC - x2 < AB * AB)
			            {
			                # this is to check if AC' < AB
			                if(x2 > 0)
			                {
			                    me.cur_dir_dist_m = math.sqrt(x2);
			                }
			            }
			            
			            if(me.tpsApproch == 0)
			            {
			                me.tpsApproch = props.globals.getNode("/sim/time/elapsed-sec", 1).getValue();
			            }
			            else
			            {
			                me.vApproch = (me.direct_dist_m-me.cur_dir_dist_m) / (props.globals.getNode("/sim/time/elapsed-sec", 1).getValue() - me.tpsApproch);
			                me.tpsApproch = props.globals.getNode("/sim/time/elapsed-sec", 1).getValue();
			            }
			            
			            if(me.usedChance == FALSE and me.cur_dir_dist_m > me.direct_dist_m and me.direct_dist_m < me.reportDist * 2 and me.life_time > me.arming_time)
			            {
			                if(me.direct_dist_m < me.reportDist)
			                {
			                    # distance to target increase, trigger explosion.
			                    me.explodeTrig("In range.");
			                    return TRUE;
			                } else {
		                        # you don't have a second chance. Missile missed
		                        me.free = 1;
		                        me.usedChance = TRUE;
		                        return FALSE;
			                }
			            }
			            if (me.life_time > me.selfdestruct_time or (me.destruct_when_free == TRUE and me.free == TRUE)) {
							me.explode("Selfdestructed.");
						    return TRUE;
						}
			        }
				}
			}
			me.direct_dist_m = me.cur_dir_dist_m;
		} elsif (me.life_time > me.selfdestruct_time) {
			me.explode("Selfdestructed.");
		    return TRUE;
		}
		return FALSE;
	},

	explode: func (reason, event = "exploded") {

		if (me.lock_on_sun == TRUE) {
			reason = "Locked onto sun.";
		} elsif (me.flareLock == TRUE) {
			reason = "Locked onto flare.";
		} elsif (me.chaffLock == TRUE) {
			reason = "Locked onto chaff.";
		}
		
		var explosion_coord = me.last_coord;
		if (me.Tgt != nil) {
			var min_distance = me.direct_dist_m;
			
			for (var i = 0.00; i <= 1; i += 0.025) {
				var t_coord = me.interpolate(me.last_t_coord, me.t_coord, i);#todo: nil in numric inside this
				var coord = me.interpolate(me.last_coord, me.coord, i);
				var dist = coord.direct_distance_to(t_coord);
				if (dist < min_distance) {
					min_distance = dist;
					explosion_coord = coord;
				}
			}
			if (me.before_last_coord != nil and me.before_last_t_coord != nil) {
				for (var i = 0.00; i <= 1; i += 0.025) {
					var t_coord = me.interpolate(me.before_last_t_coord, me.last_t_coord, i);
					var coord = me.interpolate(me.before_last_coord, me.last_coord, i);
					var dist = coord.direct_distance_to(t_coord);
					if (dist < min_distance) {
						min_distance = dist;
						explosion_coord = coord;
					}
				}
			}
		}
		me.coord = explosion_coord;

		var wh_mass = (event == "exploded" and !me.inert)?me.weight_whead_lbm:0;#will report 0 mass if did not have time to arm
		settimer(func {impact_report(me.coord, wh_mass, "munition", me.type, me.new_speed_fps*FT2M);},0);# method sent back to main nasal thread.

		if (me.Tgt != nil and !me.Tgt.isVirtual() and !me.inert) {
			var phrase = sprintf( me.type~" "~event~": %.1f", min_distance) ~ " meters from: " ~ (me.flareLock == FALSE?(me.chaffLock == FALSE?me.callsign:(me.callsign ~ "'s chaff")):me.callsign ~ "'s flare");
			me.printStats("%s  Reason: %s time %.1f", phrase, reason, me.life_time);
			if (min_distance < me.reportDist) {
				me.sendMessage(phrase);
			} else {
				me.sendMessage(me.type~" missed "~me.callsign~": "~reason);
			}
		} elsif(!me.inert and me.Tgt == nil) {
			var phrase = sprintf(me.type~" "~event);
			me.printStats("%s  Reason: %s time %.1f", phrase, reason, me.life_time);
			me.sendMessage(phrase);
		}
		if (me.multiHit and !me.inert) {
			if (!me.multiExplosion(me.coord, event) and me.Tgt != nil and me.Tgt.isVirtual()) {
				var phrase = sprintf(me.type~" "~event);
				me.printStats("%s  Reason: %s time %.1f", phrase, reason, me.life_time);
				me.sendMessage(phrase);
			}
		}
		
		me.ai.getNode("valid", 1).setBoolValue(0);
		if (event == "exploded" and !me.inert) {
			me.animate_explosion();
			me.explodeSound = TRUE;
		} else {
			me.animate_dud();
			me.explodeSound = FALSE;
		}
		me.Tgt = nil;
	},

	explodeTrig: func (reason, event = "exploded") {
		# get missile relative position to the target at last frame.
		# this method is not called at terrain impact (always explode() instead)
        var t_bearing_deg = me.last_t_coord.course_to(me.last_coord);
        var t_delta_alt_m = me.last_coord.alt() - me.last_t_coord.alt();
        var new_t_alt_m = me.t_coord.alt() + t_delta_alt_m;
        var t_dist_m  = math.sqrt(math.abs((me.direct_dist_m * me.direct_dist_m)-(t_delta_alt_m * t_delta_alt_m)));
        # create impact coords from this previous relative position
        # applied to target current coord.
        me.t_coord.apply_course_distance(t_bearing_deg, t_dist_m);
        me.t_coord.set_alt(new_t_alt_m);
        var wh_mass = (event == "exploded" and !me.inert)?me.weight_whead_lbm:0;#will report 0 mass if did not have time to arm
        settimer(func{impact_report(me.t_coord, wh_mass, "munition", me.type, me.new_speed_fps*FT2M);},0);# method sent back to main nasal thread.

		if (me.lock_on_sun == TRUE) {
			reason = "Locked onto sun.";
		} elsif (me.flareLock == TRUE) {
			reason = "Locked onto flare.";
		} elsif (me.chaffLock == TRUE) {
			reason = "Locked onto chaff.";
		}
		
		if (me.Tgt != nil and !me.Tgt.isVirtual() and !me.inert) {
			var phrase = sprintf( me.type~" "~event~": %.1f", me.direct_dist_m) ~ " meters from: " ~ (me.flareLock == FALSE?(me.chaffLock == FALSE?me.callsign:(me.callsign ~ "'s chaff")):me.callsign ~ "'s flare");
			me.printStats("%s  Reason: %s time %.1f", phrase, reason, me.life_time);
			me.sendMessage(phrase);
		}
		if (me.multiHit and !me.inert) {
			if (!me.multiExplosion(me.t_coord, event) and me.Tgt != nil and me.Tgt.isVirtual()) {
				var phrase = sprintf(me.type~" "~event);
				me.printStats("%s  Reason: %s time %.1f", phrase, reason, me.life_time);
				me.sendMessage(phrase);
			}
		}
		
		me.ai.getNode("valid", 1).setBoolValue(0);
		if (event == "exploded" and !me.inert) {
			me.animate_explosion();
			me.explodeSound = TRUE;
		} else {
			me.animate_dud();
			me.explodeSound = FALSE;
		}
		me.Tgt = nil;
	},

	multiExplosion: func (explode_coord, event) {
		# hit everything that is nearby except for target itself.
		me.sendout = 0;
		foreach (me.testMe;me.contacts) {
			if (!me.testMe.isValid() or me.testMe.isVirtual() or me.testMe.get_type() == ORDNANCE) {
				continue;
			}
			var min_distance = me.testMe.get_Coord().direct_distance_to(explode_coord);
			if (min_distance < me.reportDist and (me.Tgt == nil or me.testMe.getUnique() != me.Tgt.getUnique())) {
				var phrase = sprintf("%s %s: %.1f meters from: %s", me.type,event, min_distance, me.testMe.get_Callsign());
				me.printStats(phrase);
				me.sendMessage(phrase);
				me.sendout = 1;
			}
		}
		return me.sendout;
	},

	sendMessage: func (str) {
		if (getprop("payload/armament/msg")) {
			defeatSpamFilter(str);
		} else {
			setprop("/sim/messages/atc", str);
		}
	},

	interpolate: func (start, end, fraction) {
		me.xx = (start.x()*(1-fraction)+end.x()*fraction);
		me.yy = (start.y()*(1-fraction)+end.y()*fraction);
		me.zz = (start.z()*(1-fraction)+end.z()*fraction);

		me.cc = geo.Coord.new();
		me.cc.set_xyz(me.xx,me.yy,me.zz);

		return me.cc;
	},

	getPitch: func (coord1, coord2) {
		#pitch from coord1 to coord2 in degrees (takes curvature of earth into effect.)
		return me.myMath.getPitch(coord1, coord2);
	},

	getPitch2: func (coord1, coord2) {
		#pitch from coord1 to coord2 in degrees (assumes earth is flat)
		me.flat_dist = coord1.distance_to(coord2);
		me.flat_alt  = coord2.alt()-coord1.alt();
		return math.atan2(me.flat_alt, me.flat_dist)*R2D;
	},

	###################################################################
	#  non-multi-threaded         loops for before flying. autostarted.
	###################################################################

	standby: func {
		# looping in standby mode
		if (deltaSec.getValue()==0) {
			settimer(func me.standby(), 0.5);
		}
		if(me.uncage_auto) {
			me.caged = TRUE;
		}
		if (me.deleted == TRUE or me.status == MISSILE_FLYING) return;
		if (me.status == MISSILE_STARTING) {
			me.printCode("Starting up missile");
			me.startup();
			return;
		}
		me.coolingSyst();
		me.reset_seeker();
		#print(me.type~" standby "~me.ID);

		settimer(func me.standby(), deltaSec.getValue()==0?0.5:0.25);
	},

	startup: func {
		# looping in starting mode
		#print("startup");
		if (deltaSec.getValue()==0) {
			settimer(func me.startup(), 0.5);
		}
		if(me.uncage_auto) {
			me.caged = TRUE;
		}
		if (me.status != MISSILE_STARTING) me.standby();
		if (me.ready_standby_time != 0 and getprop("sim/time/elapsed-sec") > (me.ready_standby_time+me.ready_time)) {
			me.status = MISSILE_SEARCH;
			me.search();
			return;
		}
		#print("Starting up");
		me.coolingSyst();
		me.reset_seeker();
		settimer(func me.startup(), deltaSec.getValue()==0?0.5:0.25);
	},

	coolingSyst: func {
		if (me.coolable == TRUE and me.status != MISSILE_FLYING) {
			me.cool_elapsed = getprop("sim/time/elapsed-sec");
			if (me.cooling_last_time != 0) {
				me.cool_delta_time = me.cool_elapsed - me.cooling_last_time;
				if (me.cooling == TRUE) {
					me.cool_total_time += me.cool_delta_time;
					if (me.cool_total_time > me.cool_duration) {
						me.cooling = FALSE;
					} else {
						me.cool_curr_time = me.cool_delta_time+me.extrapolate(me.warm, 1, 0, 0, me.cool_time);
						me.warm = me.clamp(me.extrapolate(me.cool_curr_time, 0, me.cool_time, 1, 0),0,1);
					}
				}
				if (me.cooling == FALSE) {
					me.cool_curr_time = me.cool_delta_time+me.extrapolate(me.warm, 0, 1, 0, me.cool_time*3);#takes longer to warm than to cool down
					me.warm = me.clamp(me.extrapolate(me.cool_curr_time, 0, me.cool_time*3, 0, 1),0,1);
				}
			}
			me.cooling_last_time = me.cool_elapsed;
			me.detect_range_curr_nm = me.extrapolate(me.warm, 0, 1, me.detect_range_nm, me.warm_detect_range_nm);
		}
	},

	checkForLock: func {
		# call this only before firing
		if ((me.class!="A" or me.tagt.get_Speed()>15) and ((me.guidance != "semi-radar" or me.is_painted(me.tagt) == TRUE) and (me.guidance !="laser" or me.is_laser_painted(me.tagt) == TRUE))
						and (me.guidance != "radiation" or me.is_radiating_aircraft(me.tagt) == TRUE)
					    and me.rng < me.max_fire_range_nm and me.rng > me.min_fire_range_nm and me.FOV_check(me.total_horiz, me.total_elev, me.fcs_fov)
					    and (me.rng < me.detect_range_curr_nm or (me.guidance != "radar" and me.guidance != "semi-radar" and me.guidance != "heat" and me.guidance != "vision" and me.guidance != "heat" and me.guidance != "radiation"))
					    and (me.guidance != "heat" or (me.all_aspect == TRUE or me.rear_aspect(geo.aircraft_position(), me.tagt) == TRUE))
					    and me.checkForView()) {
			return TRUE;
		}
		return FALSE;
	},

	checkForView: func {
		if (me.guidance != "gps" and me.guidance != "inertial") {
			me.launchCoord = geo.aircraft_position();
			me.potentialCoord = me.tagt.get_Coord();
			me.xyz          = {"x":me.launchCoord.x(),                  "y":me.launchCoord.y(),                 "z":me.launchCoord.z()};
		    me.directionLOS = {"x":me.potentialCoord.x()-me.launchCoord.x(),   "y":me.potentialCoord.y()-me.launchCoord.y(),  "z":me.potentialCoord.z()-me.launchCoord.z()};

			# Check for terrain between own weapon and target:
			me.terrainGeod = get_cart_ground_intersection(me.xyz, me.directionLOS);
			if (me.terrainGeod == nil) {
				return TRUE;
			} else {
				me.terrain = geo.Coord.new();
				me.terrain.set_latlon(me.terrainGeod.lat, me.terrainGeod.lon, me.terrainGeod.elevation);
				me.maxDist = me.launchCoord.direct_distance_to(me.potentialCoord)-1;#-1 is to avoid z-fighting distance
				me.terrainDist = me.launchCoord.direct_distance_to(me.terrain);
				if (me.terrainDist >= me.maxDist) {
					return TRUE;
				}
			}
			return FALSE;
		}
		return TRUE;
	},

	checkForClass: func {
		# call this only before firing
		if(me.slaveContact != nil and me.slaveContact.isValid() == TRUE and
					(  (me.slaveContact.get_type() == SURFACE and me.target_gnd == TRUE)
	                or (me.slaveContact.get_type() == AIR and me.target_air == TRUE)
	                or (me.slaveContact.get_type() == MARINE and me.target_sea == TRUE))) {
			return TRUE;
		}
		return FALSE;
	},

	checkForClassInFlight: func (tact) {
		# call this only after firing
		if(tact != nil and tact.isValid() == TRUE and
					(  (tact.get_type() == SURFACE and me.target_gnd == TRUE)
	                or (tact.get_type() == AIR and me.target_air == TRUE)
	                or (tact.get_type() == MARINE and me.target_sea == TRUE))) {
			return TRUE;
		}
		return FALSE;
	},

	search: func {
		# looping in search mode
		if (deltaSec.getValue()==0) {
			settimer(func me.search(), 0.5);
		}
		if (me.deleted == TRUE) {
			return;
		} elsif ( me.status == MISSILE_FLYING ) {
			me.SwSoundVol.setDoubleValue(0);
			me.SwSoundOnOff.setBoolValue(FALSE);
			return;
		} elsif ( me.status == MISSILE_STANDBY ) {
			# Stand by.
			me.SwSoundVol.setDoubleValue(0);
			me.SwSoundOnOff.setBoolValue(FALSE);
			#me.trackWeak = 1;
			me.standby();
			return;
		} elsif ( me.status == MISSILE_LOCK) {
			# Locked.
			me.printSearch("in search loop, but locked!");
			me.return_to_search();
			return;
		}



		me.printSearch("searching");
		# search.
		if(me.uncage_auto) {
			me.caged = TRUE;
		}
		if (me.caged == FALSE) {
			me.slaveContacts = nil;
			if (size(me.contacts) == 0) {
				me.slaveContacts = [contact];
			} else {
				me.slaveContacts = me.contacts;
			}
			me.moveSeekerInHUDPattern();
			foreach(me.slaveContact ; me.slaveContacts) {
				if (me.checkForClass()) {
					me.tagt = me.slaveContact;
					me.rng = me.tagt.get_range();
					me.total_elev  = deviation_normdeg(OurPitch.getValue(), me.tagt.getElevation()); # deg.
					me.total_horiz = deviation_normdeg(OurHdg.getValue(), me.tagt.get_bearing());    # deg.
					
					# Check if in range and in the seeker FOV.
					if (me.checkForLock()) {
						me.printSearch("pattern-search ready for lock");
						
						me.seeker_elev_target = -me.total_elev;
						me.seeker_head_target = -me.total_horiz;
						me.rotateTarget();
						me.testSeeker();
						if (me.inBeam) {
							me.printSearch("pattern-search found a lock");
							me.goToLock();
							return;
						}
					}
				}
			}
			me.Tgt = nil;
			me.SwSoundVol.setDoubleValue(me.vol_search);
			me.SwSoundOnOff.setBoolValue(TRUE);
			me.coolingSyst();
			settimer(func me.search(), 0.05);# this mode needs to be a bit faster.
			return;
		} elsif (me.mode_slave == TRUE and me.command_tgt == TRUE) {
			me.slaveContact = nil;
			if (size(me.contacts) == 0) {
				me.slaveContact = contact;
			} else {
				me.slaveContact = me.contacts[0];
			}
			if (me.checkForClass()) {
				me.printSearch("search found suitable contact");
				me.tagt = me.slaveContact;
				me.rng = me.tagt.get_range();
				me.total_elev  = deviation_normdeg(OurPitch.getValue(), me.tagt.getElevation()); # deg.
				me.total_horiz = deviation_normdeg(OurHdg.getValue(), me.tagt.get_bearing());    # deg.
				
				# Check if in range and in the seeker FOV.
				if (me.checkForLock()) {
					me.printSearch("rdr-slave-search ready for lock");
					if (me.caged) {
						me.seeker_elev_target = -me.total_elev;
						me.seeker_head_target = -me.total_horiz;
						me.rotateTarget();
						me.moveSeeker();
					}
					me.seeker_elev_target = -me.total_elev;
					me.seeker_head_target = -me.total_horiz;
					me.rotateTarget();
					me.testSeeker();
					if (me.inBeam) {
						me.printSearch("rdr-slave-search found a lock");
						me.goToLock();
						return;
					}
				}
			}
		} elsif (me.mode_slave == FALSE) {
			me.slaveContacts = nil;
			if (size(me.contacts) == 0) {
				me.slaveContacts = [contact];
			} else {
				me.slaveContacts = me.contacts;
			}
			if (me.mode_bore == TRUE) {
				me.seeker_elev_target = 0;
				me.seeker_head_target = 0;
				me.moveSeeker();
			}
			foreach(me.slaveContact ; me.slaveContacts) {
				if (me.checkForClass()) {
					me.tagt = me.slaveContact;
					me.rng = me.tagt.get_range();
					me.total_elev  = deviation_normdeg(OurPitch.getValue(), me.tagt.getElevation()); # deg.
					me.total_horiz = deviation_normdeg(OurHdg.getValue(), me.tagt.get_bearing());    # deg.
					
					# Check if in range and in the seeker FOV.
					if (me.checkForLock()) {
						me.printSearch("bore-search ready for lock");
						me.seeker_elev_target = -me.total_elev;
						me.seeker_head_target = -me.total_horiz;
						me.rotateTarget();
						me.testSeeker();
						if (me.inBeam) {
							me.printSearch("bore-search found a lock");
							me.goToLock();
							return;
						}
					}
				}
			}
		} elsif (me.mode_slave == TRUE and me.command_tgt == FALSE) {
			me.slaveContacts = nil;
			if (size(me.contacts) == 0) {
				me.slaveContacts = [contact];
			} else {
				me.slaveContacts = me.contacts;
			}
			if (me.caged) {
				me.seeker_elev_target = me.command_dir_pitch;
				me.seeker_head_target = me.command_dir_heading;
				me.moveSeeker();
			}
			foreach(me.slaveContact ; me.slaveContacts) {
				if (me.checkForClass()) {
					me.tagt = me.slaveContact;
					me.rng = me.tagt.get_range();
					me.total_elev  = deviation_normdeg(OurPitch.getValue(), me.tagt.getElevation()); # deg.
					me.total_horiz = deviation_normdeg(OurHdg.getValue(), me.tagt.get_bearing());    # deg.
					
					# Check if in range and in the seeker FOV.
					if (me.checkForLock()) {
						me.printSearch("dir-search ready for lock");
						me.seeker_elev_target = -me.total_elev;
						me.seeker_head_target = -me.total_horiz;
						me.rotateTarget();
						me.testSeeker();
						if (me.inBeam) {
							me.printSearch("dir-search found a lock");
							me.goToLock();
							return;
						}
					}
				}
			}
		}
		me.Tgt = nil;
		me.SwSoundVol.setDoubleValue(me.vol_search);
		me.SwSoundOnOff.setBoolValue(TRUE);
		me.coolingSyst();
		settimer(func me.search(), 0.1);
	},

	goToLock: func {
		me.status = MISSILE_LOCK;
		me.SwSoundOnOff.setBoolValue(TRUE);
		me.SwSoundVol.setDoubleValue(me.vol_track);

		me.Tgt = me.tagt;

        me.callsign = me.Tgt.get_Callsign();

		settimer(func me.update_lock(), 0.1);
	},

	rotateTarget: func {
		var polar_dist  = math.sqrt(me.seeker_elev_target*me.seeker_elev_target+me.seeker_head_target*me.seeker_head_target);
		if (polar_dist == 0) return;
		var polar_angle = math.asin(me.seeker_elev_target/polar_dist)*R2D;
		if (me.seeker_head_target<0) {
			polar_angle = 180 - polar_angle;
		}
		var roll = OurRoll.getValue();
		polar_angle += roll;
		me.seeker_head_target = polar_dist*math.cos(polar_angle*D2R);
		me.seeker_elev_target = polar_dist*math.sin(polar_angle*D2R);
	},

	moveSeekerInFullPattern: func {
		me.pattern_elapsed = getprop("sim/time/elapsed-sec");
		if (me.pattern_last_time != 0) {
			me.pattern_time = me.pattern_elapsed - me.pattern_last_time;

			me.pattern_max_move = me.pattern_time*me.angular_speed;
			me.pattern_move = me.clamp(me.beam_width_deg*1.75, 0, me.pattern_max_move);
			me.seeker_head_n = me.seeker_head+me.pattern_move*me.patternDirX;
			if (math.sqrt(me.seeker_elev*me.seeker_elev+me.seeker_head_n*me.seeker_head_n) > me.max_seeker_dev) {
				me.patternDirX *= -1;
				#print("dir change");
				me.seeker_elev_n -= me.pattern_move*me.patternDirY;
				if (me.seeker_elev_n < -me.max_seeker_dev) {
					#print("from top");
					me.patternDirY *= -1;
					me.seeker_elev += me.pattern_move*me.patternDirY;
					#me.seeker_elev = me.max_seeker_dev-me.beam_width_deg*0.5;
				} else {
					me.seeker_elev = me.seeker_elev_n;
				}
			} else {
				me.seeker_head = me.seeker_head_n;
			}
			me.computeSeekerPos();
		}
		me.pattern_last_time = me.pattern_elapsed;
	},

	moveSeekerInHUDPattern: func {
		me.pattern_elapsed = getprop("sim/time/elapsed-sec");
		if (me.seeker_elev < me.patternPitchDown or me.seeker_elev > me.patternPitchUp or math.abs(me.seeker_head) > me.patternYaw) {
			me.reset_seeker();
		} elsif (me.pattern_last_time != 0) {
			me.pattern_time = me.pattern_elapsed - me.pattern_last_time;

			me.pattern_max_move = me.pattern_time*me.angular_speed;
			me.pattern_move = me.clamp(me.beam_width_deg*1.75, 0, me.pattern_max_move);
			me.seeker_head_n = me.seeker_head+me.pattern_move*me.patternDirX;
			if (math.abs(me.seeker_head_n) > me.patternYaw) {
				me.patternDirX *= -1;
				#print("dir change");
				me.seeker_elev_n = me.seeker_elev+me.pattern_move*me.patternDirY;
				if (me.seeker_elev_n < me.patternPitchDown or me.seeker_elev_n > me.patternPitchUp) {
					#print("from top");
					me.patternDirY *= -1;
					me.seeker_elev += me.pattern_move*me.patternDirY;
				} else {
					me.seeker_elev = me.seeker_elev_n;
				}
			} else {
				me.seeker_head = me.seeker_head_n;
			}
			me.computeSeekerPos();
		}
		me.pattern_last_time = me.pattern_elapsed;
	},

	moveSeeker: func {
		if (me.guidance != "heat" and me.guidance != "vision") {
			me.seeker_elev = me.seeker_elev_target;
			me.seeker_head = me.seeker_head_target;
			me.computeSeekerPos();
			return;
		}
		me.seeker_elapsed = getprop("sim/time/elapsed-sec");
		if (me.seeker_last_time != 0) {
			me.seeker_time = me.seeker_elapsed - me.seeker_last_time;
			me.seeker_elev_delta = me.seeker_elev_target - me.seeker_elev;
			me.seeker_head_delta = me.seeker_head_target - me.seeker_head;
			me.seeker_delta = me.clamp(math.sqrt(me.seeker_elev_delta*me.seeker_elev_delta+me.seeker_head_delta*me.seeker_head_delta),0.000001, 100000);
			me.seeker_max_move = me.seeker_time*me.angular_speed;
			me.seeker_reduce = me.clamp(me.seeker_max_move/me.seeker_delta,0,1);
			me.seeker_elev_delta *= me.seeker_reduce;
			me.seeker_head_delta *= me.seeker_reduce;
			me.seeker_elev_n = me.seeker_elev+me.seeker_elev_delta;
			me.seeker_head_n = me.seeker_head+me.seeker_head_delta;

			if (math.sqrt(me.seeker_elev_n*me.seeker_elev_n+me.seeker_head_n*me.seeker_head_n) < me.max_seeker_dev) {
				me.seeker_head = me.seeker_head_n;
				me.seeker_elev = me.seeker_elev_n;
				#me.printSearch("seeker moved");
			}
		}
		me.seeker_last_time = me.seeker_elapsed;
		me.computeSeekerPos();
	},

	testSeeker: func {
		me.inBeam = FALSE;
		me.seeker_elev_delta = me.seeker_elev_target - me.seeker_elev;
		me.seeker_head_delta = me.seeker_head_target - me.seeker_head;
		me.seeker_delta = me.clamp(math.sqrt(me.seeker_elev_delta*me.seeker_elev_delta+me.seeker_head_delta*me.seeker_head_delta),0.000001, 100000);

		me.printSearch("seeker to target %.1f degs. Beam radius %.1f degs.", me.seeker_delta, me.beam_width_deg);
		if (me.seeker_delta < me.beam_width_deg) {
			me.inBeam = TRUE;
			#me.printSearch("in beam");
		}
	},

	computeSeekerPos: func {
		# Compute HUD diamond position.
		if ( use_fg_default_hud == TRUE) {
			var h_rad = (90 - me.seeker_head) * D2R;
			var e_rad = (90 - me.seeker_elev) * D2R; 
			var devs = develev_to_devroll(h_rad, e_rad);
			var combined_dev_deg = devs[0];
			var combined_dev_length =  devs[1];
			var clamped = devs[2];
			if ( clamped and me.status == MISSILE_LOCK) {
				SW_reticle_Blinker.blink();
			} else {
				SW_reticle_Blinker.cont();
			}
			HudReticleDeg.setDoubleValue(combined_dev_deg);
			HudReticleDev.setDoubleValue(combined_dev_length);
		}
	},

	update_lock: func() {
		#
		# Missile locked on target
		#
		if (deltaSec.getValue()==0) {
			settimer(func me.update_lock(), 0.5);
		}
		if (me.status == MISSILE_FLYING) {
			return;
		}
		if (me.Tgt == nil) {
			me.printSearch("search commanded 1");
			me.return_to_search();
			return;
		}
		if (me.status == MISSILE_SEARCH) {
			# Status = searching.
			me.printSearch("search commanded 2");
			me.return_to_search();
			return;
		} elsif ( me.status == MISSILE_STANDBY ) {
			# Status = stand-by.
			me.reset_seeker();
			me.SwSoundOnOff.setBoolValue(FALSE);
			me.SwSoundVol.setDoubleValue(0);
			#me.trackWeak = 1;
			me.standby();
			return;
		} elsif (!me.Tgt.isValid()) {
			# Lost of lock due to target disapearing:
			# return to search mode.
			me.printSearch("invalid");
			me.return_to_search();
			return;
		} elsif (me.deleted == TRUE) {
			return;
		}
		me.printSearch("lock");
		# Time interval since lock time or last track loop.
		#if (me.status == MISSILE_LOCK) {		
			# Status = locked. Get target position relative to our aircraft.
			
		#}

		#me.time = props.globals.getNode("/sim/time/elapsed-sec", 1).getValue();

		if(me.uncage_auto) {
			me.caged = FALSE;
		}

		me.computeSeekerPos();
		if (me.status != MISSILE_STANDBY ) {
			me.in_view = me.check_t_in_fov();
			
			if (me.in_view == FALSE) {
				me.printSearch("out of view");
				me.return_to_search();
				return;
			}

			me.curr_deviation_e = - deviation_normdeg(OurPitch.getValue(), me.Tgt.getElevation());
			me.curr_deviation_h = - deviation_normdeg(OurHdg.getValue(), me.Tgt.get_bearing());
			if (!me.caged) {
				me.seeker_elev_target = me.curr_deviation_e;
				me.seeker_head_target = me.curr_deviation_h;
				me.rotateTarget();
				me.moveSeeker();
			}			
			me.seeker_elev_target = me.curr_deviation_e;
			me.seeker_head_target = me.curr_deviation_h;
			me.rotateTarget();
			me.testSeeker();
			if (!me.inBeam) {
				me.printSearch("out of beam");
				me.status = MISSILE_SEARCH;
				me.Tgt = nil;
				me.SwSoundOnOff.setBoolValue(TRUE);
				me.SwSoundVol.setDoubleValue(me.vol_search);
				settimer(func me.search(), 0.1);
				return;
			}

			me.dist = geo.aircraft_position().direct_distance_to(me.Tgt.get_Coord());

			me.SwSoundOnOff.setBoolValue(TRUE);
			me.SwSoundVol.setDoubleValue(me.vol_track);

			me.slaveContact = nil;
			if (size(me.contacts) == 0) {
				me.slaveContact = contact;
			} else {
				me.slaveContact = me.contacts[0];
			}
			if ((me.mode_bore == FALSE and me.mode_slave == TRUE and me.command_tgt == TRUE) and (me.slaveContact == nil or (me.slaveContact.getUnique() != nil and me.Tgt.getUnique() != nil and me.slaveContact.getUnique() != me.Tgt.getUnique()))) {
				me.printSearch("oops ");
				me.return_to_search();
				return;
			}
			me.coolingSyst();
			settimer(func me.update_lock(), deltaSec.getValue()==0?0.5:0.1);
			return;
		}
		me.standby();
		return;
	},

	return_to_search: func {
		me.status = MISSILE_SEARCH;
		me.Tgt = nil;
		me.SwSoundOnOff.setBoolValue(TRUE);
		me.SwSoundVol.setDoubleValue(me.vol_search);
		#me.trackWeak = 1;
		me.reset_seeker();
		settimer(func me.search(), 0.1);
	},

	###################################################################
	#                         end loops for before flying.
	###################################################################

	FOV_check: func (deviation_hori, deviation_elev, fov_radius) {
		me.fov_radial = math.sqrt(math.pow(deviation_hori,2)+math.pow(deviation_elev,2));
		if (me.fov_radial <= fov_radius) {
			return TRUE;
		}
		# out of FOV
		return FALSE;
	},

	check_t_in_fov: func {
		# called only before firing
		me.total_elev  = deviation_normdeg(OurPitch.getValue(), me.Tgt.getElevation()); # deg.
		me.total_horiz = deviation_normdeg(OurHdg.getValue(), me.Tgt.get_bearing());    # deg.
		# Check if in range and in the seeker FOV.
		if (me.FOV_check(me.total_horiz, me.total_elev, me.fcs_fov) and me.Tgt.get_range() < me.max_fire_range_nm and me.Tgt.get_range() > me.min_fire_range_nm
			and (me.Tgt.get_range() < me.detect_range_curr_nm or (me.guidance != "radar" and me.guidance != "semi-radar" and me.guidance != "heat" and me.guidance != "vision" and me.guidance != "heat" and me.guidance != "radiation"))) {
			return TRUE;
		}
		# Target out of FOV or range while still not launched, return to search loop.
		return FALSE;
	},

	is_painted: func (target) {
		if(target != nil) {
			me.hasPaint = target.isPainted();
			if(me.hasPaint != nil and me.hasPaint == TRUE) {
				return TRUE;
			}
		}
		return FALSE;
	},

	is_laser_painted: func (target) {
		if(target != nil) {
			me.hasPaint = target.isLaserPainted();
			if(me.hasPaint != nil and me.hasPaint == TRUE) {
				return TRUE;
			}
		}
		return FALSE;
	},

	is_radiating_me: func (target) {
		if(target != nil) {
			me.seeMe = target.isRadiating(me.coord);
			if (me.seeMe != nil and me.seeMe == TRUE) {
				return TRUE;
			}
		}
		return FALSE;
	},

	is_radiating_aircraft: func (target) {
		if(target != nil) {
			me.seeMe = target.isRadiating(geo.aircraft_position());
			if (me.seeMe != nil and me.seeMe == TRUE) {
				return TRUE;
			}
		}
		return FALSE;
	},

	reset_seeker: func {
		#me.printSearch("Reset seeker");
		me.seeker_elev_target = 0;
		me.seeker_head_target = 0;
		me.moveSeeker();
	},

	clamp_min_max: func (v, mm) {
		if ( v < -mm ) {
			v = -mm;
		} elsif ( v > mm ) {
			v = mm;
		}
		return(v);
	},

	clamp: func(v, min, max) { v < min ? min : v > max ? max : v },

	animation_flags_props: func {
		# Create animation flags properties.
		var path_base = "payload/armament/"~me.type_lc~"/flags/";

		var msl_path = path_base~"msl-id-" ~ me.ID;
		me.msl_prop = props.globals.initNode( msl_path, TRUE, "BOOL", TRUE);
		me.msl_prop.setBoolValue(TRUE);# this is cause it might already exist, and so need to force value

		var smoke_path = path_base~"smoke-id-" ~ me.ID;
		me.smoke_prop = props.globals.initNode( smoke_path, FALSE, "BOOL", TRUE);

		var explode_path = path_base~"explode-id-" ~ me.ID;
		me.explode_prop = props.globals.initNode( explode_path, FALSE, "BOOL", TRUE);

		var explode_smoke_path = path_base~"explode-smoke-id-" ~ me.ID;
		me.explode_smoke_prop = props.globals.initNode( explode_smoke_path, FALSE, "BOOL", TRUE);

		var explode_sound_path = "payload/armament/flags/explode-sound-on-" ~ me.ID;;
		me.explode_sound_prop = props.globals.initNode( explode_sound_path, FALSE, "BOOL", TRUE);

		var explode_sound_vol_path = "payload/armament/flags/explode-sound-vol-" ~ me.ID;;
		me.explode_sound_vol_prop = props.globals.initNode( explode_sound_vol_path, 0, "DOUBLE", TRUE);

		var deploy_path = path_base~"deploy-id-" ~ me.ID;
		me.deploy_prop = props.globals.initNode(deploy_path, 0, "DOUBLE", TRUE);
	},

	animate_explosion: func {
		#
		# a last position update to where the explosion happened:
		#
		me.latN.setDoubleValue(me.coord.lat());
		me.lonN.setDoubleValue(me.coord.lon());
		me.altN.setDoubleValue(me.coord.alt()*M2FT);
		me.pitchN.setDoubleValue(0);# this will make explosions from cluster bombs (like M90) align to ground 'sorta'.
		me.msl_prop.setBoolValue(FALSE);
		me.smoke_prop.setBoolValue(FALSE);
		me.explode_prop.setBoolValue(TRUE);
		settimer( func me.explode_prop.setBoolValue(FALSE), 0.5 );
		settimer( func me.explode_smoke_prop.setBoolValue(TRUE), 0.5 );
		settimer( func me.explode_smoke_prop.setBoolValue(FALSE), 3 );
	},

	animate_dud: func {
		#
		# a last position update to where the impact happened:
		#
		me.latN.setDoubleValue(me.coord.lat());
		me.lonN.setDoubleValue(me.coord.lon());
		me.altN.setDoubleValue(me.coord.alt()*M2FT);
		#me.pitchN.setDoubleValue(0); uncomment this to let it lie flat on ground, instead of sticking its nose in it.
		me.smoke_prop.setBoolValue(FALSE);
	},

	sndPropagate: func {
		var dt = deltaSec.getValue();
		if (dt == 0) {
			#FG is likely paused
			settimer(func me.sndPropagate(), 0.01);
			return;
		}
		#dt = update_loop_time;
		var elapsed = systime();
		if (me.elapsed_last != 0) {
			dt = (elapsed - me.elapsed_last) * speedUp.getValue();
		}
		me.elapsed_last = elapsed;

		me.ac = geo.aircraft_position();
		var distance = me.coord.direct_distance_to(me.ac);

		me.sndDistance = me.sndDistance + (me.sndSpeed * dt) * FT2M;
		if(me.sndDistance > distance) {
			var volume = math.pow(2.71828,(-.00025*(distance-1000)));
			me.printStats("explosion heard "~distance~"m vol:"~volume);
			me.explode_sound_vol_prop.setDoubleValue(volume);
			me.explode_sound_prop.setBoolValue(1);
			settimer( func me.explode_sound_prop.setBoolValue(0), 3);
			settimer( func me.del(), 4);
			return;
		} elsif (me.sndDistance > 5000) {
			settimer(func { me.del(); }, 4 );
			return;#TODO: I added this return recently, but not sure why it wasn't there..
		} else {
			settimer(func me.sndPropagate(), 0.05);
			return;
		}
	},

	steering_speed_G: func(steering_e_deg, steering_h_deg, s_fps, dt) {
		# Get G number from steering (e, h) in deg, speed in ft/s.
		me.steer_deg = math.sqrt((steering_e_deg*steering_e_deg) + (steering_h_deg*steering_h_deg));

		# next speed vector
		me.vector_next_x = math.cos(me.steer_deg*D2R)*s_fps;
		me.vector_next_y = math.sin(me.steer_deg*D2R)*s_fps;
		
		# present speed vector
		me.vector_now_x = s_fps;
		me.vector_now_y = 0;

		# subtract the vectors from each other
		me.dv = math.sqrt((me.vector_now_x - me.vector_next_x)*(me.vector_now_x - me.vector_next_x)+(me.vector_now_y - me.vector_next_y)*(me.vector_now_y - me.vector_next_y));

		# calculate g-force
		# dv/dt=a
		me.g = (me.dv/dt) / g_fps;

		return me.g;
	},

    max_G_Rotation: func(steering_e_deg, steering_h_deg, s_fps, dt, gMax) {
		me.guess = 1;
		me.coef = 1;
		me.lastgoodguess = 1;

		for(var i=1;i<25;i+=1){
			me.coef = me.coef/2;
			me.new_g = me.steering_speed_G(steering_e_deg*me.guess, steering_h_deg*me.guess, s_fps, dt);
			if (me.new_g < gMax) {
				me.lastgoodguess = me.guess;
				me.guess = me.guess + me.coef;
			} else {
				me.guess = me.guess - me.coef;
			}
		}
		return me.lastgoodguess;
	},

	nextGeoloc: func(lat, lon, heading, speed, dt, alt=100) {
	    # lng & lat & heading, in degree, speed in fps
	    # this function should send back the futures lng lat
	    me.distanceN = speed * dt * FT2M; # should be a distance in meters
	    #me.print("distance ", distance);
	    # much simpler than trigo
	    me.NextGeo = geo.Coord.new().set_latlon(lat, lon, alt);
	    me.NextGeo.apply_course_distance(heading, me.distanceN);
	    return me.NextGeo;
	},

	rho_sndspeed: func(altitude) {
		# Calculate density of air: rho
		# at altitude (ft), using standard atmosphere,
		# standard temperature T and pressure p.

		me.T = 0;
		me.p = 0;
		if (altitude < 36152) {
			# curve fits for the troposphere
			me.T = 59 - 0.00356 * altitude;
			me.p = 2116 * math.pow( ((me.T + 459.7) / 518.6) , 5.256);
		} elsif ( 36152 < altitude and altitude < 82345 ) {
			# lower stratosphere
			me.T = -70;
			me.p = 473.1 * math.pow( const_e , 1.73 - (0.000048 * altitude) );
		} else {
			# upper stratosphere
			me.T = -205.05 + (0.00164 * altitude);
			me.p = 51.97 * math.pow( ((me.T + 459.7) / 389.98) , -11.388);
		}

		me.rho = me.p / (1718 * (me.T + 459.7));

		# calculate the speed of sound at altitude
		# a = sqrt ( g * R * (T + 459.7))
		# where:
		# snd_speed in feet/s,
		# g = specific heat ratio, which is usually equal to 1.4
		# R = specific gas constant, which equals 1716 ft-lb/slug/R

		me.snd_speed = math.sqrt( 1.4 * 1716 * (me.T + 459.7));
		return [me.rho, me.snd_speed];

	},

	printFlight: func {
		if (DEBUG_FLIGHT) {
			call(printf,arg, var err = []);
		}
	},

	printFlightDetails: func {
		if (DEBUG_FLIGHT_DETAILS) {
			call(printf,arg);
		}
	},

	printStats: func {
		if (DEBUG_STATS) {
			call(printf,arg, var err = []);
		}
	},

	printStatsDetails: func {
		if (DEBUG_STATS_DETAILS) {
			call(printf,arg);
		}
	},

	printGuide: func {
		if (DEBUG_GUIDANCE) {
			call(printf,arg);
		}
	},

	printGuideDetails: func {
		if (DEBUG_GUIDANCE_DETAILS) {
			call(printf,arg);
		}
	},

	printCode: func {
		if (DEBUG_CODE) {
			call(printf,arg);
		}
	},

	printSearch: func {
		if (DEBUG_SEARCH) {
			call(printf,arg);
		}
	},

	active: {},
	flying: {},
};


# Create impact report.

#altitde-agl-ft DOUBLE
#impact
#	elevation-m DOUBLE
#	heading-deg DOUBLE
#	latitude-deg DOUBLE
#	longitude-deg DOUBLE
#	pitch-deg DOUBLE
#	roll-deg DOUBLE
#	speed-mps DOUBLE
#	type STRING
# valid "true" BOOL
var impact_report = func(pos, mass, string, name, speed_mps) {
	# Find the next index for "ai/models/model-impact" and create property node.
	var n = props.globals.getNode("ai/models", 1);
	for (var i = 0; 1; i += 1)
		if (n.getChild(string, i, 0) == nil)
			break;
	var impact = n.getChild(string, i, 1);

	impact.getNode("impact/elevation-m", 1).setDoubleValue(pos.alt());
	impact.getNode("impact/latitude-deg", 1).setDoubleValue(pos.lat());
	impact.getNode("impact/longitude-deg", 1).setDoubleValue(pos.lon());
	impact.getNode("warhead-lbm", 1).setDoubleValue(mass);
	impact.getNode("mass-slug", 1).setDoubleValue(mass/slugs_to_lbm);
	impact.getNode("impact/speed-mps", 1).setDoubleValue(speed_mps);
	#impact.getNode("speed-mps", 1).setValue(speed_mps);
	impact.getNode("valid", 1).setBoolValue(1);
	impact.getNode("impact/type", 1).setValue("something");#"terrain"
	impact.getNode("name", 1).setValue(name);

	var impact_str = "/ai/models/" ~ string ~ "[" ~ i ~ "]";
	setprop("ai/models/model-impact", impact_str);
}

# HUD clamped target blinker
SW_reticle_Blinker = aircraft.light.new("payload/armament/hud/hud-sw-reticle-switch", [0.1, 0.1]);
setprop("payload/armament/hud/hud-sw-reticle-switch/enabled", 1);





var eye_hud_m          = 0.6;#pilot: -3.30  hud: -3.9
var hud_radius_m       = 0.100;

#was in hud
var develev_to_devroll = func(dev_rad, elev_rad) {
	var clamped = 0;
	# Deviation length on the HUD (at level flight),
	# 0.6686m = distance eye <-> virtual HUD screen.
	var h_dev = eye_hud_m / ( math.sin(dev_rad) / math.cos(dev_rad) );
	var v_dev = eye_hud_m / ( math.sin(elev_rad) / math.cos(elev_rad) );
	# Angle between HUD center/top <-> HUD center/symbol position.
	# -90° left, 0° up, 90° right, +/- 180° down. 
	var dev_deg =  math.atan2( h_dev, v_dev ) * R2D;
	# Correction with own a/c roll.
	var combined_dev_deg = dev_deg - OurRoll.getValue();
	# Lenght HUD center <-> symbol pos on the HUD:
	var combined_dev_length = math.sqrt((h_dev*h_dev)+(v_dev*v_dev));
	# clamp and squeeze the top of the display area so the symbol follow the egg shaped HUD limits.
	var abs_combined_dev_deg = math.abs( combined_dev_deg );
	var clamp = hud_radius_m;
	if ( abs_combined_dev_deg >= 0 and abs_combined_dev_deg < 90 ) {
		var coef = ( 90 - abs_combined_dev_deg ) * 0.00075;
		if ( coef > 0.050 ) { coef = 0.050 }
		clamp -= coef; 
	}
	if ( combined_dev_length > clamp ) {
		combined_dev_length = clamp;
		clamped = 1;
	}
	var v = [combined_dev_deg, combined_dev_length, clamped];
	return(v);
}

#was in radar
var deviation_normdeg = func(our_heading, target_bearing) {
	var dev_norm = geo.normdeg180(our_heading - target_bearing);
	return dev_norm;
}

#
# this code make sure messages don't trigger the MP spam filter:

var spams = 0;
var spamList = [];
var mutexMsg = thread.newlock();

var defeatSpamFilter = func (str) {
  thread.lock(mutexMsg);
  spams += 1;
  if (spams == 15) {
    spams = 1;
  }
  str = str~":";
  for (var i = 1; i <= spams; i+=1) {
    str = str~".";
  }
  var myCallsign = getprop("sim/multiplay/callsign");
  if (myCallsign != nil and find(myCallsign, str) != -1) {
  	str = myCallsign~": "~str;
  }
  var newList = [str];
  for (var i = 0; i < size(spamList); i += 1) {
    append(newList, spamList[i]);
  }
  spamList = newList;
  thread.unlock(mutexMsg);
}

var spamLoop = func {
  thread.lock(mutexMsg);
  var spam = pop(spamList);
  thread.unlock(mutexMsg);
  if (spam != nil) {
    setprop("/sim/multiplay/chat", spam);
  }
  settimer(spamLoop, 1.20);
}

spamLoop();