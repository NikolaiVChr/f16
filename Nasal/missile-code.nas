#########################################################################################
#######
####### Guided/Cruise missiles, rockets and dumb/glide/guided bombs code for Flightgear.
#######
####### License: GPL 2.0
#######
####### Authors:
#######  Alexis Bory, Fabien Barbier, Richard Harrison, Justin Nicholson, Nikolai V. Chr., Axel Paccalin, Colin Geniet
#######
####### The file vector.nas needs to be available in namespace 'vector'.
#######
####### In addition, some code is derived from work by:
#######  David Culp, Vivian Meazza, M. Franz
#######
#########################################################################################

# Some notes about making weapons:
#
# Firstly make sure you read the comments (line 300+) below for the properties.
# For laser/gps guided gravity bombs make sure to set the max G very low, like 0.5G, to simulate them slowly adjusting to hit the target.
# Remember for air to air missiles the speed quoted in literature is normally the speed above the launch platform. I usually fly at the typical max usage
#   regime for that missile, so for example for AIM-7 it would be at 40000 ft,
#   there I make sure it can reach approx the max relative speed. For older missiles the max speed quoted is sometimes absolute speed though, so beware.
#   If it quotes aerodynamic speed then its the absolute speed. Speeds quoted in in unofficial sources can be any of them,
#   but if its around mach 5 for A/A its a good bet its absolute, only very few A/A missiles are likely hypersonic. (among othe reasons due to heat or fuel limitations)
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
# Set DEBUG_STATS and/or DEBUG_FLIGHT to true to check how the missile works during flight, when you are designing a weapon.
#
#
# Usage:
#
# To create a weapon call AIM.new(pylon, type, description, midFlightFunction). The pylon is an integer from 0 or higher. When its launched it will read the pylon position in
#   controls/armament/station[pylon+1]/offsets, where the position properties must be x-m, y-m and z-m. The type is just a string, the description is a string
#   that is exposed in its radar properties under AI/models during flight. The function is for changing target, guidance or guidance-law during flight.
# The mid flight function will be called often during flight with 1 parameter. The param is a hash like {time_s, dist_m, mach, weapon_position}, where the latter is a geo.Coord.
#   It expects you to return a hash with any or none of these {guidance, guidanceLaw, target, remote_yaw, remote_pitch}.
# The model that is loaded and shown is located in the aircraft folder at the value of property payload/armament/models in a subfolder with same name as type.
#   Inside the subfolder the xml file is called [lowercase type]-[pylon].xml
# To start making the missile try to get a lock, call start(), the missile will then keep trying to get a lock on 'contact'.
#   'contact' can be set to nil at any time or changed. To stop the search, just call stop(). To resume the search you again have call start().
# To release the munition at a target call release(), normally do this after the missile has set its own status to MISSILE_LOCK.
# When using weapons without target, call releaseAtNothing() instead of release(), search() does not need to have been called beforehand.
#   To then find out where it hit the ground check the impact report in AI/models. The impact report will contain warhead weight, but that will be zero if
#   the weapon did not have time to arm before hitting ground.
# To drop the munition, without arming it nor igniting its engine, call eject().
# Remote guidance requires the use of midFlightFunction (see below) to transmit guidance parameters, in the remote_yaw and remote_pitch fields of the output.
#
#
# Limitations:
#
# The weapons use a simplified flight model that does not have AoA or sideslip. Mass balance, rotational inertia, wind is also not implemented. They also do not roll due to aerodynmic effects.
# If you fire a weapon and have HoT enabled in flightgear, they likely will not hit very precise.
# The weapons are highly dependent on framerate, so low frame rate will make them hit imprecise.
# The drag curves are tailored for sizable munitions, so it does not work well will bullet or cannon sized munition, submodels are better suited for that.
# Inertial guidance does not account for drift and does not auto dead reckon the target if you want that you have to update the Target accordingly.
#
#
# Future features:
#
# ECM disturbance of getting radar lock.
# Lock on jam. (advanced feature)
# After FG gets HLA: stop using MP chat for hit messages.
# Allow firing only if certain conditions are met. Like not being inverted when firing ejected weapons.
# Sub munitions that have their own guidance/FDM. (advanced)
# GPS guided munitions could have waypoints added.
# Specify terminal manouvres and preferred impact aspect.
# Drag coeff reduction due to exhaust plume. This actually matters quite a bit.
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

var fox2_unique_id = -100; # each missile needs to have a unique numeric ID

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
var POINT = 4;

var PATTERN_CIRCLE = 0;
var PATTERN_ROSETTE = 1;
var PATTERN_DOUBLE_D = 2;

# set these to print stuff to console:
var DEBUG_STATS            = 0;#most basic stuff
var DEBUG_FLIGHT           = 0;#for creating missiles sometimes good to have this on to see how it flies.

# set these to debug the code:
var DEBUG_STATS_DETAILS    = 0;
var DEBUG_GUIDANCE         = 0;
var DEBUG_GUIDANCE_DETAILS = 0;
var DEBUG_FLIGHT_DETAILS   = 0;
var DEBUG_SEARCH           = 0;
var DEBUG_CODE             = 0;

var g_fps        = 9.80665 * M2FT;
var SLUGS2LBM = 32.1740485564;
var LBM2SLUGS = 1/SLUGS2LBM;
var slugs_to_lbm = SLUGS2LBM;# since various aircraft use this from outside missile, leaving it for backwards compat.

var first_in_air = FALSE;# first missile is in the air, other missiles should not write to MP.
var first_in_air_max_sec = 30;

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

var wingedGuideFactor = 0.1;

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
# The variable contactPoint is for now only used by F-16 target pod.
#
var contact = nil;
var contactPoint = nil;
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
# get_altitude()
# get_Pitch()
# get_Speed()
# get_heading()
# get_uBody()
# get_vBody()
# get_wBody()
# getFlareNode()  - Used for flares.
# getChaffNode()  - Used for chaff.
# isPainted()     - Tells if this target is still being radar tracked by the launch platform, only used in semi-radar guided missiles.
# isLaserPainted()     - Tells if this target is still being tracked by the launch platform, only used by laser guided ordnance.
# isRadiating(coord) - Tell if anti-radiation missile is hit by radiation from target. coord is the weapon position.
# isCommandActive()
# isVirtual()     - Tells if the target is just a position, and should not be considered for damage.
# get_closure_rate()  -  closure rate in kt

var AIM = {
	lowestETA: nil,
	#done
	new : func (p, type = "AIM-9L", sign = "Sidewinder", midFlightFunction = nil, nasalPosition = nil) {
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
		m.launchSoundProp  = AcModel.getNode("armament/"~m.type_lc~"/sound-fire-on-off",1);
        m.SwSoundVol        = AcModel.getNode("armament/"~m.type_lc~"/sound-volume",1);
        if (m.SwSoundOnOff.getValue() == nil) {
        	m.SwSoundOnOff.setBoolValue(0);
        }
        if (m.launchSoundProp.getValue() == nil) {
        	m.launchSoundProp.setBoolValue(0);
        }
        if (m.SwSoundVol.getValue() == nil) {
        	m.SwSoundVol.setDoubleValue(0);
        }
        m.tacview_support       = getprop("payload/armament/tacview");# set to false, unless using an aircraft that has tacview
        m.gnd_launch            = getprop("payload/armament/gnd-launch");#true to be a SAM or ship
        if (m.gnd_launch == nil) {
        	m.gnd_launch = 0;
        }
        if (m.tacview_support == nil) {
        	m.tacview_support = 0;
        }

		m.ID                = p;
		m.stationName       = AcModel.getNode("armament/station-name").getValue();
		if (m.nasalPosition == nil) {
			m.pylon_prop        = props.globals.getNode(AcModel.getNode("armament/pylon-stations").getValue()).getChild(m.stationName, p+AcModel.getNode("armament/pylon-offset").getValue());
		}
		m.Tgt               = nil;
		m.callsign          = "Unknown";
		m.direct_dist_m     = nil;
		m.speed_m           = -1;

		fox2_unique_id += 1;
		if (fox2_unique_id >100) fox2_unique_id = -100;
        m.unique_id = fox2_unique_id;
		m.nodeString = "payload/armament/"~m.type_lc~"/";

		if (m.tacview_support) {
			m.tacviewID = 11000 + int(math.floor(rand()*10000));
		}

		###############
		# Weapon specs:
		###############

		# name
		m.typeLong              = getprop(m.nodeString~"long-name");                  # Longer name of the weapon
		m.typeShort             = getprop(m.nodeString~"short-name");                 # Shorter name of the weapon
		m.typeID                = getprop(m.nodeString~"type-id");                    # ID that match damage type
		# detection and firing
		m.max_fire_range_nm     = getprop(m.nodeString~"max-fire-range-nm");          # max range that the FCS allows firing
		m.min_fire_range_nm     = getprop(m.nodeString~"min-fire-range-nm");          # it wont get solid lock before the target has this range
		m.fcs_fov               = getprop(m.nodeString~"FCS-field-deg") / 2;          # fire control system total field of view diameter for when searching and getting lock before launch.
		m.class                 = getprop(m.nodeString~"class");                      # put in letters here that represent the types the missile can fire at. A=air, M=marine, G=ground, P=point
        m.brevity               = getprop(m.nodeString~"fire-msg");                   # what the pilot will call out over the comm when he fires this weapon
        m.coolable              = getprop(m.nodeString~"coolable");                   # If the seeker supports being cooled. (AIM-9L or later supports)
        m.cool_time             = getprop(m.nodeString~"cool-time");                  # Time to cold the seeker from fully warm.
        m.cool_duration         = getprop(m.nodeString~"cool-duration");              # Typically 2.5 hours for cooling fluids. Much higher for electrical.
        m.warm_detect_range_nm  = getprop(m.nodeString~"warm-detect-range-nm");       # Current guidance mode detect range. (when warm)
        m.cold_detect_range_nm  = getprop(m.nodeString~"detect-range-nm");            # Current guidance mode default detect range. (when cold). This can differ from max-fire-range-nm in that some missiles can be fired at targets they cannot yet see.
        m.beam_width_deg        = getprop(m.nodeString~"seeker-beam-width-deg");      # Seeker detector instant field of view diameter
        m.ready_time            = getprop(m.nodeString~"ready-time");                 # time to get ready after standby mode.
        m.loal                  = getprop(m.nodeString~"lock-on-after-launch");       # bool. LOAL supported. For loal to work [optional]
        m.canSwitch             = getprop(m.nodeString~"auto-switch-target-allowed"); # bool. Can switch target at will if it loses lock [optional]
        m.standbyFlight         = getprop(m.nodeString~"prowl-flight");               # unguided/level/gyro-pitch/5/terrain-follow for LOAL and that stuff, when not locked onto stuff.
        m.switchTime            = getprop(m.nodeString~"switch-time-sec");            # auto switch of targets in flight: time to scan FoV. This should not be fast, some seconds or more.
        m.noCommonTarget        = getprop(m.nodeString~"no-common-target");           # bool. If true, target must be set directly on weapon and its not allowed to read 'contact' variable.
        m.radarOrigin           = getprop(m.nodeString~"FCS-at-origin");              # bool. If radar location is 0,0,0. If false use the 3 properties below also.
        m.radarX                = getprop(m.nodeString~"FCS-x");                      # Where in the aircraft (model xml coords) the radar is located.
		m.radarY                = getprop(m.nodeString~"FCS-y");                      #    This is handy for SAMs with radar on a mast.
		m.radarZ                = getprop(m.nodeString~"FCS-z");                      #    In future I will add direction to it also, for now its center gimbal is along -x axis.
		m.expand_min            = getprop(m.nodeString~"expand-min-fire-range");      # Bool. Default false. If min fire range should expand with closing rate. Mainly use this for A/A missiles.
		m.asc                   = getprop(m.nodeString~"attack-steering-cue-enabled");# Bool. ASC enabled.
		# navigation, guiding and seekerhead
		m.max_seeker_dev        = getprop(m.nodeString~"seeker-field-deg") / 2;       # missiles own seekers total FOV diameter.
		m.guidance              = getprop(m.nodeString~"guidance");                   # heat/radar/semi-radar/laser/gps/vision/unguided/level/gyro-pitch/radiation/inertial/remote/remote-stable/command/gps-altitude
		m.guidanceLaw           = getprop(m.nodeString~"navigation");                 # guidance-law: direct/OPN/PN/APN/PNxxyy/APNxxyy/LOS (use direct for pure pursuit, use PN for A/A missiles, use APN for modern SAM missiles PN for older, use PNxxyy/APNxxyy for surface to air where xx is degrees to aim above target, yy is seconds it will do that). GPN is APN for winged glidebombs.
		m.guidanceLawHorizInit  = getprop(m.nodeString~"navigation-init-pure-15");    # Bool. Guide in horizontal plane using pure pursuit until target with 15 deg of nose, before switching to <navigation>
		m.pro_constant          = getprop(m.nodeString~"proportionality-constant");   # Constant for how sensitive proportional navigation is to target speed/acc. Normally between 3-6. [optional]
		m.all_aspect            = getprop(m.nodeString~"all-aspect");                 # bool. set to false if missile only locks on reliably to rear of target aircraft
		m.angular_speed         = getprop(m.nodeString~"seeker-angular-speed-dps");   # only for heat/vision seeking missiles. Max angular speed that the target can move as seen from seeker, before seeker loses lock.
		m.sun_lock              = getprop(m.nodeString~"lock-on-sun-deg");            # only for heat seeking missiles. If it looks at sun within this angle, it will lose lock on target.
		m.loft_alt              = getprop(m.nodeString~"loft-altitude");              # if 0 then no snap up. Below 10000 then cruise altitude above ground. Above 10000 max altitude it will snap up to.
        m.follow                = getprop(m.nodeString~"terrain-follow");             # bool. used for anti-ship missiles that should be able to terrain follow instead of purely sea skimming.
        m.reaquire              = getprop(m.nodeString~"reaquire");                   # bool. If weapon will try to reaquire lock after losing it. [optional]
        m.maxPitch              = getprop(m.nodeString~"max-pitch-deg");              # After propulsion burnout it will not be able to steer up more than this. Useful for guided bombs. [optional]
        m.guidanceEnabled       = getprop(m.nodeString~"guidance-enabled");           # Boolean. If guidance will activate when launched. [optional]
        m.terminal_alt_factor   = getprop(m.nodeString~"terminal-alt-factor");        # Float. Cruise alt multiplied by this factor determines how much is rise up in terminal. Default: 2
        m.terminal_rise_time    = getprop(m.nodeString~"terminal-rise-time");         # Float. Seconds before reaching target that cruise missile will start to rise up. Default: 6
        m.terminal_dive_time    = getprop(m.nodeString~"terminal-dive-time");         # Float. Seconds before reaching target that cruise missile will start to dive down. Default: 4
        m.rosette_radius        = getprop(m.nodeString~"rosette-radius-deg");         # Float. Radius of uncaged rosette search pattern. If 0 then disabled.
		m.seam_support          = getprop(m.nodeString~"sw-expanded-acquisition-mode");# Bool. Default true. SEAM support. False for old heatseekers like AIM-9B/F/D/E and RB24. Supports then only static commandDir mode, uncage happens at firing. No radar slaving, no SEAM scan, no manual cage/uncage.
        m.oldPattern            = getprop(m.nodeString~"nutate-double-d-instead-of-circle"); # Bool. For old SEAM missiles like AIM-9G/H. (maybe J also, don't know).
        m.seeker_filter         = getprop(m.nodeString~"seeker-filter");              # Float: Ability to filter out background noise. Typically between 1 to 2 for IR.
		# engine
		m.force_lbf_1           = getprop(m.nodeString~"thrust-lbf-stage-1");         # stage 1 thrust [optional]
		m.force_lbf_2           = getprop(m.nodeString~"thrust-lbf-stage-2");         # stage 2 thrust [optional]
		m.force_lbf_3           = getprop(m.nodeString~"thrust-lbf-stage-3");         # stage 3 thrust [optional]
		m.stage_1_duration      = getprop(m.nodeString~"stage-1-duration-sec");       # stage 1 duration [optional]
		m.stage_gap_duration    = getprop(m.nodeString~"stage-gap-duration-sec");     # gap duration between stage 1 and 2 [optional]
		m.stage_2_duration      = getprop(m.nodeString~"stage-2-duration-sec");       # stage 2 duration [optional]
		m.stage_3_duration      = getprop(m.nodeString~"stage-3-duration-sec");       # stage 3 duration [optional]
		m.stage_1_jet           = getprop(m.nodeString~"stage-1-jet");                # Boolean. If stage 1 is a jet engine [optional]
		m.stage_2_jet           = getprop(m.nodeString~"stage-2-jet");                # Boolean. If stage 2 is a jet engine [optional]
		m.stage_3_jet           = getprop(m.nodeString~"stage-3-jet");                # Boolean. If stage 3 is a jet engine [optional]
		m.weight_fuel_lbm       = getprop(m.nodeString~"weight-fuel-lbm");            # fuel weight [optional]. If this property is not present, it won't lose weight as the fuel is used.
		m.vector_thrust         = getprop(m.nodeString~"vector-thrust");              # Boolean. This will make less drag due to high G turns while engine is running. [optional]
		m.engineEnabled         = getprop(m.nodeString~"engine-enabled");             # Boolean. If engine will start at all. [optional]
		# aerodynamic
		m.weight_launch_lbm     = getprop(m.nodeString~"weight-launch-lbs");          # total weight of armament, including fuel and warhead.
		m.Cd_base               = getprop(m.nodeString~"drag-coeff");                 # drag coefficient
		m.Cd_delta              = getprop(m.nodeString~"delta-drag-coeff-deploy");    # drag coefficient added by deployment
		m.ref_area_sqft         = getprop(m.nodeString~"cross-section-sqft");         # normally is crosssection area of munition (without fins)
		m.max_g                 = getprop(m.nodeString~"max-g");                      # max G-force the missile can pull at sealevel (if vector thrust enabled, this will be auto reduced at engine burnout)
		m.min_speed_for_guiding = getprop(m.nodeString~"min-speed-for-guiding-mach"); # minimum speed before the missile steers, before it reaches this speed it will fly ballistic.
		m.intoBore              = getprop(m.nodeString~"ignore-wind-at-release");     # Boolean. Default false. If true dropped weapons will ignore sideslip and AOA and start flying in aircraft bore direction. Will always be the case if ejector speed is non zero.
		m.lateralSpeed          = getprop(m.nodeString~"lateral-dps");                # Lateral speed in degrees per second. This is mostly for cosmetics.
		# detonation
		m.weight_whead_lbm      = getprop(m.nodeString~"weight-warhead-lbs");         # warhead total mass. Includes scapnel, expanding rods etc etc.
		m.arming_time           = getprop(m.nodeString~"arming-time-sec");            # time for weapon to arm
		m.selfdestruct_time     = getprop(m.nodeString~"self-destruct-time-sec");     # time before selfdestruct
		m.destruct_when_free    = getprop(m.nodeString~"self-destruct-at-lock-lost"); # selfdestruct if lose target. Mostly for man-in-the-loop weapons like some old command guided.
		m.reportDist            = getprop(m.nodeString~"max-report-distance");        # Interpolation hit: max distance from target it report it exploded, not passed. Trig hit: Distance where it will trigger.
		m.multiHit				= getprop(m.nodeString~"hit-everything-nearby");      # bool. Only works well for slow moving targets. Needs you to pass contacts to release().
		m.inert                 = getprop(m.nodeString~"inert");                      # bool. If the weapon is inert and will not detonate. [optional]
		# avionics sounds
		m.vol_search            = getprop(m.nodeString~"vol-search");                 # sound volume when searching
		m.vol_track             = getprop(m.nodeString~"vol-track");                  # sound volume when having lock
		# launching conditions
        m.rail                  = getprop(m.nodeString~"rail");                       # if the weapon is rail or tube fired set to true. If dropped 7ft before ignited set to false.
        m.rail_dist_m           = getprop(m.nodeString~"rail-length-m");              # length of tube/rail
        m.rail_forward          = getprop(m.nodeString~"rail-point-forward");         # true for rail, false for rail/tube with a pitch/heading-deviation
        m.rail_pitch_deg        = getprop(m.nodeString~"rail-pitch-deg");             # Only used when rail is not forward. 90 for vertical tube. Max 90, min -90.
        m.rail_head_deg         = getprop(m.nodeString~"rail-heading-deg");           # Only used when rail is not forward. 90 for vertical tube.
        m.drop_time             = getprop(m.nodeString~"drop-time");                  # Time to fall before stage 1 thrust starts.
        m.deploy_time           = getprop(m.nodeString~"deploy-time");                # Time to deploy wings etc. Time starts when drop ends or rail passed.
        m.no_pitch              = getprop(m.nodeString~"pitch-animation-disabled");   # Bool. Default false. Set to true for ejection seats.
        m.eject_speed           = getprop(m.nodeString~"ejector-speed-fps");          # Ordnance ejected by pylon with this speed. Default = 0. Optional. Ignored if on rail.
        m.guideWhileDrop        = getprop(m.nodeString~"guide-before-ignition");      # Can guide before engine ignition if speed is high enough.
        # counter-measures
        m.chaffResistance       = getprop(m.nodeString~"chaff-resistance");           # Float 0-1. Amount of resistance to chaff. Default 0.850. [optional]
        m.flareResistance       = getprop(m.nodeString~"flare-resistance");           # Float 0-1. Amount of resistance to flare. Default 0.850. [optional]
        # data-link to launch platform
        m.data                  = getprop(m.nodeString~"telemetry");                  # Boolean. Data link back to aircraft when missile is flying. [optional]
        m.dlz_enabled           = getprop(m.nodeString~"DLZ");                        # Supports dynamic launch zone info. For now only works with A/A. [optional]
        m.dlz_opt_alt           = getprop(m.nodeString~"DLZ-optimal-alt-feet");       # Minimum altitude required to hit the target at max range.
        m.dlz_opt_mach          = getprop(m.nodeString~"DLZ-optimal-closing-mach");   # Closing speed required to hit the target at max range at minimum altitude.
		# detailed drag settings
		m.Cd_plume              = getprop(m.nodeString~"exhaust-plume-parasitic-drag-factor"); # Default 1. For AIM-120, Naval Postgraduate School paper suggest around 0.6. It will reduce drag during burn.
		m.simple_drag           = getprop(m.nodeString~"simplified-induced-drag");        # bool. Default true. If enabled, the properties below wont be used:
		m.wing_aspect_ratio     = getprop(m.nodeString~"wing-aspect-ratio");          # span^2/wing_area. Default to 8
		m.wing_eff              = getprop(m.nodeString~"wing-efficiency-relative-to-an-elliptical-planform"); # Default to 0.85


        if (m.cold_detect_range_nm == nil) {
          # backwards compatibility
          m.cold_detect_range_nm = m.max_fire_range_nm;
        }
        m.detect_range_curr_nm = m.cold_detect_range_nm;

        if (m.max_seeker_dev == nil) {
        	m.max_seeker_dev = 15;
        }
        if (m.beam_width_deg == nil) {
          m.beam_width_deg = 4;
        }
        m.beam_width_deg *= 0.5;

		if (m.eject_speed == nil) {
          m.eject_speed = 0;
        }

        if (m.rail_forward == TRUE) {
        	m.rail_pitch_deg = 0;
        	m.rail_head_deg  = 0;
        }

        if (m.asc == nil) {
        	m.asc = 0;
        }

        if (m.wing_aspect_ratio == nil) {
        	m.wing_aspect_ratio = 8.0;
        }

        if (m.wing_eff == nil) {
        	m.wing_eff = 0.85;
        }

        if (m.expand_min == nil) {
        	m.expand_min = 0;
        }

        if (m.rail_head_deg == nil) {
        	m.rail_head_deg  = 0;
        }

        if (m.radarOrigin == nil) {
        	m.radarOrigin = 1;
        }

        if (m.guideWhileDrop == nil) {
        	m.guideWhileDrop = 0;
        }

        if (m.seam_support == nil) {
        	m.seam_support = 1;
        }

        if (m.rosette_radius == nil) {
        	m.rosette_radius = 7.5;
        }

        if (m.oldPattern == nil) {
        	m.oldPattern = 0;
        }

        if (m.seeker_filter == nil) {
        	m.seeker_filter = 0;
        }

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

        if (m.Cd_plume == nil) {
        	m.Cd_plume = 1.0;
        }

        if(m.canSwitch == nil) {
        	m.canSwitch = FALSE;
        }

        if(m.terminal_alt_factor == nil) {
        	m.terminal_alt_factor = 2;
        }

        if(m.terminal_rise_time == nil) {
        	m.terminal_rise_time = 6;
        }

        if(m.terminal_dive_time == nil) {
        	m.terminal_dive_time = 4;
        }

        if (m.weight_fuel_lbm == nil) {
			m.weight_fuel_lbm = 0;
		}
		if (m.data == nil) {
        	m.data = FALSE;
        }
        if (m.stage_1_jet == nil) {
        	m.stage_1_jet = 0;
        }
        if (m.stage_2_jet == nil) {
        	m.stage_2_jet = 0;
        }
        if (m.stage_3_jet == nil) {
        	m.stage_3_jet = 0;
        }
        if (m.vector_thrust == nil) {
        	m.vector_thrust = FALSE;
        }
        if (m.flareResistance == nil or !m.gnd_launch) {
        	m.flareResistance = 0.85;
        }
        if (m.chaffResistance == nil or !m.gnd_launch) {
        	m.chaffResistance = 0.85;
        }
        if (m.guidanceLaw == nil) {
			m.guidanceLaw = "PN";
		}
		if (m.guidanceLawHorizInit == nil) {
			m.guidanceLawHorizInit = 0;
		}
        if (m.pro_constant == nil) {
        	m.pro_constant = 3;
        }
        if (m.force_lbf_1 == nil) {
        	m.force_lbf_1 = 0;
        }
        if (m.force_lbf_2 == nil) {
        	m.force_lbf_2 = 0;
        }
        if (m.force_lbf_3 == nil) {
        	m.force_lbf_3 = 0;
        }
        if(m.stage_gap_duration == nil) {
			m.stage_gap_duration = 0;
		}
		if(m.stage_1_duration == nil) {
			m.stage_1_duration = 0;
		}
		if(m.stage_2_duration == nil) {
			m.stage_2_duration = 0;
		}
		if(m.stage_3_duration == nil) {
			m.stage_3_duration = 0;
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
			m.drop_time = 0.5;
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
		if(m.simple_drag == nil) {
			m.simple_drag = 1;
		}
		if(m.noCommonTarget == nil) {
			m.noCommonTarget = FALSE;
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
		m.ai.getNode("callsign", 1).setValue(sprintf("%s_%d", type, m.unique_id));
		m.ai.getNode("missile", 1).setBoolValue(1);


		var id_model = m.weapon_model ~ m.ID ~ ".xml";
		m.model.getNode("path", 1).setValue(id_model);
		m.model.getNode("enable-hot", 1).setBoolValue(0);# This is if people forget to set it in xml.
		m.model.getNode("name", 1).setValue(m.typeLong);# this helps in debugging.



		# Create the AI position and orientation properties.
		m.latN   = m.ai.getNode("position/latitude-deg", 1);
		m.lonN   = m.ai.getNode("position/longitude-deg", 1);
		m.altN   = m.ai.getNode("position/altitude-ft", 1);
		m.hdgN   = m.ai.getNode("orientation/true-heading-deg", 1);
		m.pitchN = m.ai.getNode("orientation/pitch-deg", 1);
		m.rollN  = m.ai.getNode("orientation/roll-deg", 1);

		m.mpLat          = getprop("payload/armament/MP-lat");# properties to be used for showing missile over MP.
		m.mpLon          = getprop("payload/armament/MP-lon");
		m.mpAlt          = getprop("payload/armament/MP-alt");
		m.mpAltft        = getprop("payload/armament/MP-alt-ft");#used for anim of S-300 camera view: Follow
		m.mpShow = FALSE;
		if (m.mpLat != nil and m.mpLon != nil and m.mpAlt != nil and m.mpAltft != nil) {
			m.mpLat          = props.globals.getNode(m.mpLat, FALSE);
			m.mpLon          = props.globals.getNode(m.mpLon, FALSE);
			m.mpAlt          = props.globals.getNode(m.mpAlt, FALSE);
			m.mpAltft        = props.globals.getNode(m.mpAltft, FALSE);
			if (m.mpLat != nil and m.mpLon != nil and m.mpAlt != nil and m.mpAltft != nil) {
				m.mpShow = TRUE;
			}
		}



		m.target_air = find("A", m.class)==-1?FALSE:TRUE;
		m.target_sea = find("M", m.class)==-1?FALSE:TRUE;#use M for marine, since S can be confused with surface.
		m.target_gnd = find("G", m.class)==-1?FALSE:TRUE;
		m.target_pnt = find("P", m.class)==-1?FALSE:TRUE;

		m.ac      = nil;

		m.coord               = geo.Coord.new().set_latlon(0, 0, 0);
		m.t_coord             = nil;



		#
		# Seekerhead
		#
        m.caged                 = TRUE;# if gyro is caged
        m.uncage_auto           = TRUE;# will uncage when lock achieved (if SEAM supported)
        m.command_dir_heading   = 0;# where seeker is commanded in slave mode to look
        m.command_dir_pitch     = 0;
        m.uncage_idle_heading   = rand()*(2*m.max_seeker_dev)-m.max_seeker_dev;
        m.uncage_idle_pitch     = rand()*(2*m.max_seeker_dev)-m.max_seeker_dev;
        m.contacts              = [];# contacts that should be considered to lock onto. In slave it will only lock to the first.
        m.warm                  = 1;# normalized warm/cold
        m.ready_standby_time    = 0;# time when started from standby
        m.cooling               = FALSE;
        m.slave_to_radar        = m.seam_support?1:0;
        m.seeker_last_time      = 0;
        m.seeker_elev           = 0;
        m.seeker_head           = 0;
        m.seam_scan             = 0;
        m.cooling_last_time     = 0;
        m.cool_total_time       = 0;

		#
		# Emesary damage system
		#
		m.noti_time = 1.5;#2xsend freq of emesary notifications
		m.last_noti = -2;

		#
		# Aerodynamics and propulsion
		#
		m.density_alt_diff   = 0;
		m.max_g_current      = m.max_g;
		m.old_speed_horz_fps = nil;
		m.old_speed_fps	     = 0;
		m.g                  = 0;
		m.limitGs            = FALSE;
		m.speed_down_fps  = nil;
		m.speed_east_fps  = nil;
		m.speed_north_fps = nil;
		m.speed_horizontal_fps = nil;
		m.alt_ft          = nil;
		m.pitch           = nil;
		m.hdg             = nil;
		m.thrust_lbf      =   0;
		m.myG             =   0;

		#
		# Simulation
		#
		m.last_dt            = 0;
		m.counter_last       = -2;
		m.counter            = 0;
		m.life_time          = 0;

		#
		# Fuse
		#
		m.crc_frames_look_back = 2;
		m.crc_coord    = [];
		m.crc_t_coord  = [];
		m.crc_range    = [];
		setsize(m.crc_coord,   m.crc_frames_look_back + 1);
		setsize(m.crc_t_coord, m.crc_frames_look_back + 1);
		setsize(m.crc_range,   m.crc_frames_look_back + 1);

		#
		# navigation and guidance
		#
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
		m.dive_token             = FALSE;
		m.raw_steer_signal_elev  = 0;
		m.raw_steer_signal_head  = 0;
		m.cruise_or_loft         = FALSE;
		m.curr_deviation_e       = 0;
		m.curr_deviation_h       = 0;
		m.track_signal_e         = 0;
		m.track_signal_h         = 0;
		m.remote_control_yaw     = 0;
		m.remote_control_pitch   = 0;
		m.prevTarget   = nil;
		m.prevGuidance = nil;
		m.keepPitch    = 0;
		m.horz_closing_rate_fps = -1;
		m.vert_closing_rate_fps = -1;
		m.usingTGPPoint = 0;
		m.rotate_token = 0;
		m.CREv = 0;
		m.CREh = 0;
		m.CREv_old = 0;
		m.CREh_old = 0;
		m.CRE_old_dt = 0.05;



		#
		# Terrain following
		#
		m.nextGroundElevation = 0; # next Ground Elevation
		m.nextGroundElevationMem = [-10000, -1];
		m.terrainStage = 0;

		#
		# Rail
		#
		m.rail_passed = FALSE;
		m.x = 0;
		m.y = 0;
		m.z = 0;
		m.rail_pos = 0;
		m.rail_speed_into_wind = 0;
		m.rail_passed_time = nil;
		m.deploy = 0;

		#
		# stats
		#
		m.maxFPS       = 0;
		m.maxMach      = 0;
		m.maxMach1     = 0;#stage 1
		m.maxMach2     = 0;#stage 2
		m.maxMach3     = 0;#stage 3
		m.maxMach4     = 0;#stage 3 end
		m.energyBleedKt = 0;

		#
		# Counter-measure response
		#
		m.flareLast = 0;
		m.flareTime = 0;
		m.flareLock = FALSE;
		m.chaffLast = 0;
		m.chaffTime = 0;
		m.chaffLock = FALSE;
		m.chaffLockTime = -1000;
		m.flarespeed_fps = nil;

		#
		# Telemetry
		#
		m.first = FALSE;

		#
		# these are used for limiting debugging spam
		#
		m.heatLostLock = FALSE;
		m.semiLostLock = FALSE;
		m.radLostLock  = FALSE;
		m.tooLowSpeed  = FALSE;
		m.tooLowSpeedPass = FALSE;
		m.tooLowSpeedTime  = -1;
		m.lostLOS      = FALSE;


		#
		# LOAL
		#
		m.newTargetAssigned = FALSE;
		m.switchIndex = 0;
		m.hasGuided = FALSE;
		m.fovLost = FALSE;
		m.maddog = FALSE;
		m.nextFovCheck = m.switchTime;
		m.observing = m.guidance;

		#
		# Sound
		#
		m.SwSoundOnOff.setBoolValue(FALSE);
		m.SwSoundVol.setDoubleValue(m.vol_search);
		m.pendingLaunchSound = -1;
		m.explodeSound = TRUE;




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
		if (me["frameLoop"] != nil) {
			me.frameLoop.stop();
			me.frameLoop = nil;
		}
		me.deleted = TRUE;
		thread.semup(me.frameToggle);
		if (me.first == TRUE) {
			me.resetFirst();
		}
		me.model.remove();
		me.ai.remove();
		if (me.status == MISSILE_FLYING) {
			delete(AIM.flying, me.flyID);
			if (me.tacview_support) {
				if (tacview.starttime) {
					thread.lock(tacview.mutexWrite);
					tacview.write("#" ~ (systime() - tacview.starttime)~"\n");
					tacview.write("0,Event=Destroyed|"~me.tacviewID~"\n");
					tacview.write("-"~me.tacviewID~"\n");
					thread.unlock(tacview.mutexWrite);
				}
			}
			if(getprop("payload/armament/msg")) {
				thread.lock(mutexTimer);
				#lat,lon,alt,rdar,typeID,typ,unique,thrustOn,callsign, heading, pitch, speed, is_deleted=0
				append(AIM.timerQueue, [AIM, AIM.notifyInFlight, [nil, -1, -1, 0, me.typeID, "delete()", me.unique_id, 0,"", 0, 0, 0, 1], -1]);
				thread.unlock(mutexTimer);
			}
		} else {
			delete(AIM.active, me.ID);
		}
		AIM.setETA(nil);
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
		if (me.eject_speed != 0 and !me.rail) {
			# add ejector speed down from belly:
			me.aircraft_vec = [me.ccrp_speed_north_fps,-me.ccrp_speed_east_fps,-me.ccrp_speed_down_fps];
			me.eject_vec    = me.myMath.normalize(me.myMath.eulerToCartesian3Z(-OurHdg.getValue(),OurPitch.getValue(),OurRoll.getValue()));
			me.eject_vec    = me.myMath.product(-me.eject_speed, me.eject_vec);
			me.init_rel_vec = me.myMath.plus(me.aircraft_vec, me.eject_vec);
			me.ccrp_speed_down_fps = -me.init_rel_vec[2];
			me.ccrp_speed_east_fps = -me.init_rel_vec[1];
			me.ccrp_speed_north_fps = me.init_rel_vec[0];
		}

        me.ccrp_t = 0.0;

        me.ccrp_altC = me.ccrp_agl;
        me.ccrp_vel_z = -me.ccrp_speed_down_fps*FT2M;#positive upwards
        me.ccrp_fps_z = -me.ccrp_speed_down_fps;
        me.ccrp_vel_x = math.sqrt(me.ccrp_speed_east_fps*me.ccrp_speed_east_fps+me.ccrp_speed_north_fps*me.ccrp_speed_north_fps)*FT2M;
        me.ccrp_fps_x = me.ccrp_vel_x * M2FT;

        me.ccrp_rs = me.rho_sndspeed(me.ccrp_dens-(me.ccrp_agl/2)*M2FT);
        me.ccrp_rho = me.ccrp_rs[0];
        me.ccrp_Cd = me.drag(me.ccrp_mach);
        me.ccrp_mass = me.weight_launch_lbm * LBM2SLUGS;
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
        me.ccrp_heading = geo.normdeg(math.atan2(me.ccrp_speed_east_fps,me.ccrp_speed_north_fps)*R2D);
        me.ccrpPos.apply_course_distance(me.ccrp_heading, me.ccrp_dist);

        #printf("Will fall %0.1f NM ahead of aircraft.", me.dist*M2NM);
        me.ccrp_elev = me.ccrp_alti-me.ccrp_agl;#faster
        me.ccrpPos.set_alt(me.ccrp_elev);

        me.ccrp_distCCRP = me.ccrpPos.distance_to(me.Tgt.get_Coord());
        return me.ccrp_distCCRP;
	},

	getCCIPadv: func (maxFallTime_sec, timeStep) {
		# for non flat areas. Lower falltime or higher timestep means using less CPU time.
		# returns nil for higher than maxFallTime_sec. Else a vector with [Coord, hasTimeToArm].
        me.ccip_altC = getprop("position/altitude-ft")*FT2M;
        me.ccip_dens = getprop("fdm/jsbsim/atmosphere/density-altitude");
        me.ccip_speed_down_fps = getprop("velocities/speed-down-fps");
        me.ccip_speed_east_fps = getprop("velocities/speed-east-fps");
        me.ccip_speed_north_fps = getprop("velocities/speed-north-fps");
		if (me.eject_speed != 0 and !me.rail) {
			# add ejector speed down from belly:
			me.aircraft_vec = [me.ccip_speed_north_fps,-me.ccip_speed_east_fps,-me.ccip_speed_down_fps];
			me.eject_vec    = me.myMath.normalize(me.myMath.eulerToCartesian3Z(-OurHdg.getValue(),OurPitch.getValue(),OurRoll.getValue()));
			me.eject_vec    = me.myMath.product(-me.eject_speed, me.eject_vec);
			me.init_rel_vec = me.myMath.plus(me.aircraft_vec, me.eject_vec);
			me.ccip_speed_down_fps = -me.init_rel_vec[2];
			me.ccip_speed_east_fps = -me.init_rel_vec[1];
			me.ccip_speed_north_fps = me.init_rel_vec[0];
		}

        me.ccip_t = 0.0;
        me.ccip_dt = timeStep;
        me.ccip_fps_z = -me.ccip_speed_down_fps;
        me.ccip_fps_x = math.sqrt(me.ccip_speed_east_fps*me.ccip_speed_east_fps+me.ccip_speed_north_fps*me.ccip_speed_north_fps);
        me.ccip_bomb = me;

        me.ccip_rs = me.ccip_bomb.rho_sndspeed(getprop("sim/flight-model") == "jsb"?me.ccip_dens:me.ccip_altC*M2FT);
        me.ccip_rho = me.ccip_rs[0];
        me.ccip_mass = me.ccip_bomb.weight_launch_lbm * LBM2SLUGS;

        me.ccipPos = geo.Coord.new(geo.aircraft_position());

        # we calc heading from composite speeds, due to alpha and beta might influence direction bombs will fall:
        if(me.ccip_fps_x == 0) return nil;
        me.ccip_heading = geo.normdeg(math.atan2(me.ccip_speed_east_fps,me.ccip_speed_north_fps)*R2D);
        #print();
        #printf("CCIP     %.1f", me.ccip_heading);
		me.ccip_pitch = math.atan2(me.ccip_fps_z, me.ccip_fps_x);
        while (me.ccip_t <= maxFallTime_sec) {
			me.ccip_t += me.ccip_dt;
			me.ccip_bomb.deploy = me.clamp(me.extrapolate(me.ccip_t, me.drop_time, me.drop_time+me.deploy_time,0,1),0,1);
			# Apply drag
			me.ccip_fps = math.sqrt(me.ccip_fps_x*me.ccip_fps_x+me.ccip_fps_z*me.ccip_fps_z);
			if (me.ccip_fps==0) return nil;
			me.ccip_q = 0.5 * me.ccip_rho * me.ccip_fps * me.ccip_fps;
			me.ccip_mach = me.ccip_fps / me.ccip_rs[1];
			me.ccip_Cd = me.ccip_bomb.drag(me.ccip_mach);
			me.ccip_deacc = (me.ccip_Cd * me.ccip_q * me.ccip_bomb.ref_area_sqft) / me.ccip_mass;
			me.ccip_fps -= me.ccip_deacc*me.ccip_dt;

			# new components and pitch
			me.ccip_fps_z = me.ccip_fps*math.sin(me.ccip_pitch);
			me.ccip_fps_x = me.ccip_fps*math.cos(me.ccip_pitch);
			me.ccip_fps_z -= g_fps * me.ccip_dt;
			me.ccip_pitch = math.atan2(me.ccip_fps_z, me.ccip_fps_x);

			# new position
			me.ccip_altC = me.ccip_altC + me.ccip_fps_z*me.ccip_dt*FT2M;
			me.ccip_dist = me.ccip_fps_x*me.ccip_dt*FT2M;
			me.ccip_oldPos = geo.Coord.new(me.ccipPos);
			me.ccipPos.apply_course_distance(me.ccip_heading, me.ccip_dist);
			me.ccipPos.set_alt(me.ccip_altC);

			# test terrain
			me.ccip_grnd = geo.elevation(me.ccipPos.lat(),me.ccipPos.lon());
			if (me.ccip_grnd != nil) {
				if (me.ccip_grnd > me.ccip_altC) {
					#return [me.ccipPos,me.arming_time<me.ccip_t];
					me.result = me.getTerrain(me.ccip_oldPos, me.ccipPos);
					if (me.result != nil) {
						return [me.result, me.arming_time<me.ccip_t, me.ccip_t];
					}
					return [me.ccipPos,me.arming_time<me.ccip_t, me.ccip_t];
					#var inter = me.extrapolate(me.ccip_grnd,me.ccip_altC,me.ccip_oldPos.alt(),0,1);
					#return [me.interpolate(me.ccipPos,me.ccip_oldPos,inter),me.arming_time<me.ccip_t];
				}
			} else {
				return nil;
			}
        }
        return nil;
	},

	getTerrain: func (from, to) {
		me.xyz = {"x":from.x(),                  "y":from.y(),                 "z":from.z()};
        me.dir = {"x":to.x()-from.x(),  "y":to.y()-from.y(), "z":to.z()-from.z()};
        me.v = get_cart_ground_intersection(me.xyz, me.dir);
        if (me.v != nil) {
            me.terrain = geo.Coord.new();
            me.terrain.set_latlon(me.v.lat, me.v.lon, me.v.elevation);
            return me.terrain;
        }
        return nil;
	},

	getCCIPsimple: func (maxFallTime_sec, timeStep) {
		#faster, but only works over level ground
		me.ccip_agl = getprop("position/altitude-agl-ft")*FT2M;
        me.ccip_alti = getprop("position/altitude-ft")*FT2M;
        me.ccip_roll = getprop("orientation/roll-deg");
        me.ccip_vel = getprop("velocities/groundspeed-kt")*0.5144;#m/s
        me.ccip_dens = getprop("fdm/jsbsim/atmosphere/density-altitude");
        me.ccip_mach = getprop("velocities/mach");
        me.ccip_speed_down_fps = getprop("velocities/speed-down-fps");
        me.ccip_speed_east_fps = getprop("velocities/speed-east-fps");
        me.ccip_speed_north_fps = getprop("velocities/speed-north-fps");
        if (me.eject_speed != 0 and !me.rail) {
			# add ejector speed down from belly:
			me.aircraft_vec = [me.ccip_speed_north_fps,-me.ccip_speed_east_fps,-me.ccip_speed_down_fps];
			me.eject_vec    = me.myMath.normalize(me.myMath.eulerToCartesian3Z(-OurHdg.getValue(),OurPitch.getValue(),OurRoll.getValue()));
			me.eject_vec    = me.myMath.product(-me.eject_speed, me.eject_vec);
			me.init_rel_vec = me.myMath.plus(me.aircraft_vec, me.eject_vec);
			me.ccip_speed_down_fps = -me.init_rel_vec[2];
			me.ccip_speed_east_fps = -me.init_rel_vec[1];
			me.ccip_speed_north_fps = me.init_rel_vec[0];
		}

        me.ccip_t = 0.0;
        me.ccip_dt = timeStep;
        me.ccip_altC = me.ccip_agl;
        me.vel_z = -me.ccip_speed_down_fps*FT2M;#positive upwards
        me.fps_z = -me.ccip_speed_down_fps;
        me.vel_x = math.sqrt(me.ccip_speed_east_fps*me.ccip_speed_east_fps+me.ccip_speed_north_fps*me.ccip_speed_north_fps)*FT2M;
        me.fps_x = me.ccip_vel_x * M2FT;
        me.ccip_bomb = me;

        me.ccip_rs = me.ccip_bomb.rho_sndspeed(me.ccip_dens-(me.ccip_agl/2)*M2FT);
        me.ccip_rho = me.ccip_rs[0];
        me.ccip_Cd = me.ccip_bomb.drag(me.ccip_mach);
        me.ccip_mass = me.ccip_bomb.weight_launch_lbm * LBM2SLUGS;
        me.ccip_q = 0.5 * me.ccip_rho * me.ccip_fps_z * me.ccip_fps_z;
        me.ccip_deacc = (me.ccip_Cd * me.ccip_q * me.ccip_bomb.ref_area_sqft) / me.ccip_mass;

        while (me.ccip_altC > 0 and me.ccip_t <= maxFallTime_sec) {#20 secs is max fall time
          me.ccip_t += me.ccip_dt;
          me.ccip_acc = -9.81 + me.ccip_deacc * FT2M;
          me.ccip_vel_z += me.ccip_acc * me.ccip_dt;
          me.ccip_altC = me.ccip_altC + me.ccip_vel_z*me.ccip_dt+0.5*me.ccip_acc*me.ccip_dt*me.ccip_dt;
        }
        #printf("predict fall time=%0.1f", t);

        if (me.ccip_t >= maxFallTime_sec) {
          return nil;
        }
        #t -= 0.75 * math.cos(pitch*D2R);            # fudge factor

        me.ccip_q = 0.5 * me.ccip_rho * me.ccip_fps_x * me.ccip_fps_x;
        me.ccip_deacc = (me.ccip_Cd * me.ccip_q * me.ccip_bomb.ref_area_sqft) / me.ccip_mass;
        me.ccip_acc = -me.ccip_deacc * FT2M;

        me.ccip_fps_x_final = me.ccip_t*me.ccip_acc+me.ccip_fps_x;# calc final horz speed
        me.ccip_fps_x_average = (me.ccip_fps_x-(me.ccip_fps_x-me.ccip_fps_x_final)*0.5);
        me.ccip_mach_average = me.ccip_fps_x_average / me.ccip_rs[1];

        me.ccip_Cd = me.ccip_bomb.drag(me.ccip_mach_average);
        me.ccip_q = 0.5 * me.ccip_rho * me.ccip_fps_x_average * me.ccip_fps_x_average;
        me.ccip_deacc = (me.ccip_Cd * me.ccip_q * me.ccip_bomb.ref_area_sqft) / me.ccip_mass;
        me.ccip_acc = -me.ccip_deacc * FT2M;
        me.ccip_dist = me.ccip_vel_x*me.ccip_t+0.5*me.ccip_acc*me.ccip_t*me.ccip_t;

        me.ccip_ac = geo.aircraft_position();
        me.ccipPos = geo.Coord.new(me.ccip_ac);

        # we calc heading from composite speeds, due to alpha and beta might influence direction bombs will fall:
        me.ccip_heading = geo.normdeg(math.atan2(me.ccip_speed_east_fps,me.ccip_speed_north_fps)*R2D);
        me.ccipPos.apply_course_distance(me.ccip_heading, me.ccip_dist);

        me.ccip_elev = me.ccip_alti-me.ccip_agl;#faster
        me.ccipPos.set_alt(me.ccip_elev);
        return [me.ccipPos,me.arming_time<me.ccip_t];
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
		#me.dlz_t_mach = contact.get_Speed()*KT2FPS/me.dlz_t_sound_fps;
		#me.dlz_o_mach = getprop("velocities/mach");
		me.contactCoord = contact.get_Coord();
		#me.vectorToEcho   = me.myMath.eulerToCartesian2(-contact.get_bearing(), me.myMath.getPitch(geo.aircraft_position(), me.contactCoord));
    	#me.vectorEchoNose = me.myMath.eulerToCartesian3X(-contact.get_heading(), contact.get_Pitch(), contact.get_Roll());
    	#me.angleToRear    = geo.normdeg180(me.myMath.angleBetweenVectors(me.vectorToEcho, me.vectorEchoNose));
    	#me.abso           = math.abs(me.angleToRear)-90;
    	#me.mach_factor    = math.sin(me.abso*D2R);
    	#me.dlz_CS         = me.mach_factor*me.dlz_t_mach+me.dlz_o_mach;#closing speed in mach (old version)

    	me.dlz_mid_rs = me.rho_sndspeed((me.dlz_t_alt+me.dlz_o_alt)*0.5);#get average speed of sound between us and target
		me.dlz_CS = KT2FPS * contact.get_closure_rate() / me.dlz_mid_rs[1];#approx closing speed in mach

	    me.min_fire_nm = me.getCurrentMinFireRange(contact);
    	me.dlz_opt   = me.clamp(me.max_fire_range_nm *0.3* (me.dlz_o_alt/me.dlz_opt_alt) + me.max_fire_range_nm *0.2* (me.dlz_t_alt/me.dlz_opt_alt) + me.max_fire_range_nm *0.5* (me.dlz_CS/me.dlz_opt_mach),me.min_fire_nm,me.max_fire_range_nm);
    	me.dlz_nez   = me.clamp(me.dlz_opt * (me.dlz_tG/45), me.min_fire_nm, me.dlz_opt);
    	me.printStatsDetails("Dynamic Launch Zone reported (NM): Maximum=%04.1f Optimistic=%04.1f NEZ=%04.1f Minimum=%04.1f",me.max_fire_range_nm,me.dlz_opt,me.dlz_nez,me.min_fire_nm);
    	return [me.max_fire_range_nm,me.dlz_opt,me.dlz_nez,me.min_fire_nm,geo.aircraft_position().direct_distance_to(me.contactCoord)*M2NM];
	},

	getCurrentMinFireRange: func (target) {
		if (target == nil or !me.expand_min) return me.min_fire_range_nm;
		me.closing_speed_fps = target.get_closure_rate()*KT2FPS;
		me.rs = me.rho_sndspeed(ourAlt.getValue());
		me.closing_speed_mach = me.closing_speed_fps / me.rs[1];
		return math.max(me.min_fire_range_nm * (1+2*me.closing_speed_mach),me.min_fire_range_nm); # Source: NAVWEPS OP 3353
	},

	getIdealFireSolution: func {
		#print("lock:",me.status == MISSILE_LOCK);
		#print("asc:",me.asc);
		if (me.status != MISSILE_LOCK or !me.asc) return nil;
		# do only call this for A/A missiles

		me.asc_av_spd_mps = 900;# should be per missile

		me.horiz_intercept = me.get_intercept(me.Tgt.get_bearing(), me.Tgt.get_range()*NM2M, me.Tgt.get_heading(), me.Tgt.get_Speed()*KT2MPS, me.asc_av_spd_mps, geo.aircraft_position(), OurHdg.getValue());
		# [me.timeToIntercept, me.interceptHeading, me.interceptCoord, me.interceptDist, me.interceptRelativeBearing
		if(me.horiz_intercept == nil) {
			#print("No aim120 intercept");
			return nil;
		}

		me.loft_cue = 0;
		if (me["dlz_opt"] != nil and me["dlz_nez"] != nil) {
			me.tgtRange = me.Tgt.get_range();
			me.loft_cue = me.map(me.Tgt.get_range(), me.dlz_nez, (me.dlz_opt+me.max_fire_range_nm)*0.5, 0, 15);
			me.loft_cue *= me.map(ourAlt.getValue(), 0, 40000, 3, 1);
		}

		# Do not find a relative bearing that is so great that radar loses track of target:
		me.maxBearing = me.fcs_fov - 10;# margin is 10 degrees
		me.relativeBearing = geo.normdeg180(me.horiz_intercept[1]-me.Tgt.get_bearing());
		if (me.relativeBearing > me.maxBearing) {
			me.horiz_intercept[1] = me.Tgt.get_bearing() + me.maxBearing;
		} elsif (me.relativeBearing < -me.maxBearing) {
			me.horiz_intercept[1] = me.Tgt.get_bearing() - me.maxBearing;
		}

		return [me.horiz_intercept[1], math.clamp(me.loft_cue, 0, 45)]; # attack-bearing, loft-cue
	},

	get_intercept: func (bearingToRunner, dist_m, runnerHeading, runnerSpeed, chaserSpeed, chaserCoord, chaserHeading) {
	    # from Leto
	    # needs: bearingToRunner_deg, dist_m, runnerHeading_deg, runnerSpeed_mps, chaserSpeed_mps, chaserCoord
	    #        dist_m > 0 and chaserSpeed > 0

	    if (dist_m < 500) {
	        return nil;
	    }

	    me.trigAngle = 90-bearingToRunner;
	    me.RunnerPosition = [dist_m*math.cos(me.trigAngle*D2R), dist_m*math.sin(me.trigAngle*D2R),0];
	    me.ChaserPosition = [0,0,0];

	    me.VectorFromRunner = vector.Math.minus(me.ChaserPosition, me.RunnerPosition);
	    me.runner_heading = 90-runnerHeading;
	    me.RunnerVelocity = [runnerSpeed*math.cos(me.runner_heading*D2R), runnerSpeed*math.sin(me.runner_heading*D2R),0];

	    me.a = chaserSpeed * chaserSpeed - runnerSpeed * runnerSpeed;
	    me.b = 2 * vector.Math.dotProduct(me.VectorFromRunner, me.RunnerVelocity);
	    me.c = -dist_m * dist_m;

	    if ((me.b*me.b-4*me.a*me.c)<0) {
	      # intercept not possible
	      return nil;
	    }

	    me.t1 = (-me.b+math.sqrt(me.b*me.b-4*me.a*me.c))/(2*me.a);
	    me.t2 = (-me.b-math.sqrt(me.b*me.b-4*me.a*me.c))/(2*me.a);

	    if (me.t1 < 0 and me.t2 < 0) {
	      # intercept not possible
	      return nil;
	    }

	    me.timeToIntercept = 0;
	    if (me.t1 > 0 and me.t2 > 0) {
	          me.timeToIntercept = math.min(me.t1, me.t2);
	    } else {
	          me.timeToIntercept = math.max(me.t1, me.t2);
	    }
	    me.InterceptPosition = vector.Math.plus(me.RunnerPosition, vector.Math.product(me.timeToIntercept, me.RunnerVelocity));

	    me.ChaserVelocity = vector.Math.product(1/me.timeToIntercept, vector.Math.minus(me.InterceptPosition, me.ChaserPosition));

	    me.interceptAngle = vector.Math.angleBetweenVectors([0,1,0], me.ChaserVelocity);
	    me.interceptHeading = geo.normdeg(me.ChaserVelocity[0]<0?-me.interceptAngle:me.interceptAngle);

	    me.interceptDist = chaserSpeed*me.timeToIntercept;

	    me.interceptCoord = geo.Coord.new(chaserCoord);
	    me.interceptCoord = me.interceptCoord.apply_course_distance(me.interceptHeading, me.interceptDist);
	    me.interceptRelativeBearing = geo.normdeg180(me.interceptHeading-chaserHeading);

	    return [me.timeToIntercept, me.interceptHeading, me.interceptCoord, me.interceptDist, me.interceptRelativeBearing];
	},

	setContacts: func (vect) {
		# sets a vector of contacts the weapons will try to lock onto
		# Before launch: for heatseekers in bore or unslaved mode
		# do NOT call this after launch
		# see also release(vect)
		if (me.status == MISSILE_FLYING) return;
		me.contacts = vect;
	},

	commandDir: func (heading_deg, pitch_deg) {
		# commands are relative to aircraft bore
		if (me.status == MISSILE_FLYING) return;
		if (vector.Math.angleBetweenVectors(vector.Math.eulerToCartesian2(-heading_deg, pitch_deg), [1,0,0]) <= me.fcs_fov) {
			me.command_dir_heading = heading_deg;
			me.command_dir_pitch = pitch_deg;
			me.slave_to_radar = FALSE;
		}
		me.printCode("Bore/dir command: heading %0.1f pitch %0.1f", heading_deg, pitch_deg);
	},

	commandRadar: func (idle_heading = 0, idle_elevation = 0) {
		# command that radar is looking at a target, slave to that.
		if (!me.seam_support or me.status == MISSILE_FLYING) return;
		if (me.status != MISSILE_LOCK) {
			me.command_dir_heading = idle_heading;
			me.command_dir_pitch   = idle_elevation;
		}
		me.slave_to_radar = TRUE;
		me.printCode("Slave radar command. Idle: heading %0.1f pitch %0.1f", idle_heading, idle_elevation);
	},

	isRadarSlaved: func {
		if (me.status == MISSILE_FLYING) return 0;
		return me.slave_to_radar;
	},

	setSEAMscan: func (xfov) {
		if (!me.seam_support or me.status == MISSILE_FLYING) return;
		me.seam_scan = xfov;
	},

	isSEAMscan: func {
		return me.seam_scan;
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
			#printf("start #%3d %s", me.ID, me.type);
		}
	},

	stop: func {
		if (me.status != MISSILE_FLYING) {
			me.status = MISSILE_STANDBY;
			#printf("stop  #%3d %s", me.ID, me.type);
		}
	},

	isCaged: func () {
		if (!me.seam_support) return me.status != MISSILE_FLYING;
		return me.caged;
	},

	isAutoUncage: func () {
		if (!me.seam_support) return 0;
		return me.uncage_auto;
	},

	setAutoUncage: func (auto) {
		if (!me.seam_support or me.status == MISSILE_FLYING) return;
		me.uncage_auto = auto;
		me.printCode("Cage auto: "~auto);
	},

	setCaged: func (cage) {
		if (!me.seam_support or me.status == MISSILE_FLYING) return;
		me.caged = cage;
		me.printCode("Cage: "~cage);
	},

	getSeekerInfo: func {
		if (me.status == MISSILE_FLYING or me.status == MISSILE_STANDBY) {
			return nil;
		}
		return [me.seeker_head, me.seeker_elev];
	},

	eject: func () {
		if (me.stage_1_duration == 0 or me.force_lbf_1 == 0) {
			me.pendingLaunchSound = 0;
		}
		me.stage_1_duration = 0;
		me.force_lbf_1      = 0;
		me.stage_2_duration = 0;
		me.force_lbf_2      = 0;
		me.stage_3_duration = 0;
		me.force_lbf_3      = 0;
		me.stage_gap_duration = 0;
		me.drop_time        = 10000;
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
		me.release = nil;# no calling this method twice
		me.elapsed_last = systime();
		me.status = MISSILE_FLYING;

		if (vect!= nil) {

			# sets a vector of contacts the weapons will try to lock onto
			# For LOAL weapons.
			# see also setContacts()
			me.contacts = vect;
		} else {
			me.contacts = [];
		}
		me.launchSoundProp.setBoolValue(FALSE);

		if (me.engineEnabled and me.stage_1_duration > 0 and me.force_lbf_1 > 0 and me.drop_time < 1.75) {
			me.pendingLaunchSound = me.drop_time;
		} elsif (me.drop_time != 10000 and (!me.engineEnabled or me.stage_1_duration == 0 or me.force_lbf_1 == 0)) {
			me.pendingLaunchSound = 0;
		}

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

		me.msl_hdg = ac_hdg;
		me.msl_pitch = ac_pitch;

		if (me.rail == TRUE) {
			if (me.rail_forward == FALSE) {
				me.position_on_rail = 0;
				#if (me.rail_pitch_deg == 90 and me.Tgt != nil) {
					# This only really works for surface launchers which is not rolled
				#	me.rail_head_deg = me.Tgt.get_bearing()-OurHdg.getValue();
				#}
				me.railvec = vector.Math.eulerToCartesian3X(-me.rail_head_deg, me.rail_pitch_deg,0);
				me.veccy = vector.Math.rollPitchYawVector(ac_roll,ac_pitch,-ac_hdg,me.railvec);
				me.carty = vector.Math.cartesianToEuler(me.veccy);
				me.msl_pitch = me.carty[1];
				me.defaultHeading = me.Tgt != nil?me.Tgt.get_bearing():0;#90 deg tubes align to target heading, else north
				me.msl_hdg   = (me.carty[0]==nil or (ac_roll == 0 and me.rail_pitch_deg == 90))?me.defaultHeading:me.carty[0];
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
			if (me.rail_forward == FALSE) {
				me.railBegin = [-me.x, -me.y, me.z];
				me.railEnd   = vector.Math.plus(me.railBegin, vector.Math.product(me.rail_dist_m, me.railvec));
			}
		}
		if (offsetMethod == TRUE and (me.rail == FALSE or me.rail_forward == TRUE)) {
			var pos = aircraftToCart({x:-me.x, y:me.y, z: -me.z});
			init_coord = geo.Coord.new();
			init_coord.set_xyz(pos.x, pos.y, pos.z);
		} else {
			init_coord = me.getGPS(me.x, me.y, me.z, ac_pitch, ac_hdg);
		}


		# Set submodel initial position:
		var mlat = init_coord.lat();
		var mlon = init_coord.lon();
		var malt = init_coord.alt() * M2FT;

		me.coord = geo.Coord.new(init_coord);
		# Get target position.
		if (me.Tgt != nil) {
			if (me.Tgt == contactPoint) {
				me.usingTGPPoint = 1;
			}
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
		me.speed_horizontal_fps = math.sqrt(me.speed_east_fps*me.speed_east_fps + me.speed_north_fps*me.speed_north_fps);
		if (me.rail == TRUE) {
			if (me.rail_forward == FALSE) {
					# TODO: add side wind here too since rail can now have heading offset too.
					me.u = noseAir.getValue();
					me.w = -belowAir.getValue();
					me.rail_speed_into_wind = me.u*math.cos(me.rail_pitch_deg*D2R)+me.w*math.sin(me.rail_pitch_deg*D2R);
			} else {
				# rail is pointing forward
				me.rail_speed_into_wind = noseAir.getValue();
				#printf("Rail: ac_fps=%d uBody_fps=%d", math.sqrt(me.speed_down_fps*me.speed_down_fps+math.pow(math.sqrt(me.speed_east_fps*me.speed_east_fps+me.speed_north_fps*me.speed_north_fps),2)), me.rail_speed_into_wind);
			}
		} elsif (me.intoBore == FALSE and me.eject_speed == 0) {
			# to prevent the missile to appear falling up, we need to sometimes pitch it into wind:
			#var t_spd = math.sqrt(me.speed_down_fps*me.speed_down_fps + h_spd*h_spd);
			var wind_pitch = math.atan2(-me.speed_down_fps, me.speed_horizontal_fps) * R2D;
			if (wind_pitch < me.msl_pitch) {
				# super hack, and might temporary as missile leaves launch platform look stupid:
				me.msl_pitch = wind_pitch;
				# this should really take place over a duration instead of instantanious.
			}
			if (me.speed_horizontal_fps != 0) {
				# will turn weapon into wind
				# (not sure this is a good idea..might lose lock immediatly if firing with a big AoA,
				# but then on other hand why would you do that, unless in dogfight, and there you use aim9 anyway,
				# which is always on rails, and dont have this issue)
				#
				# what if heavy cross wind and fires level. Then it can fly maybe 10 degs offbore, and will likely lose its lock.
				#
				msl_hdg = geo.normdeg(math.atan2(me.speed_east_fps,me.speed_north_fps)*R2D);
			}
		} elsif (me.eject_speed != 0) {
			# add ejector speed down from belly:
			if (me.force_lbf_1 > 0 and me.stage_1_duration > 0) {
				# for missiles
				#
				# So we cheat a bit and pretend the aircraft groundspeed is in its nose direction instead of into airstream.
				# We do this cause the missile has no alpha/beta and when firing in hard turn alpha can easy be 15+ degs,
				# so the missile would otherwise be pointed much further from target that the pilot intends.
				me.aircraft_vec = me.myMath.eulerToCartesian3X(-OurHdg.getValue(),OurPitch.getValue(),OurRoll.getValue());
				me.aircraft_vec = me.myMath.normalize(me.aircraft_vec);
				me.aircraft_fps = math.sqrt(math.pow(math.sqrt(math.pow(me.speed_north_fps,2)+math.pow(me.speed_east_fps,2)),2)+math.pow(me.speed_down_fps,2));
				me.aircraft_vec = me.myMath.product(me.aircraft_fps, me.aircraft_vec);
			} else {
				# for bombs
				me.aircraft_vec = [me.speed_north_fps,-me.speed_east_fps,-me.speed_down_fps];
			}
			me.eject_vec    = me.myMath.normalize(me.myMath.eulerToCartesian3Z(-OurHdg.getValue(),OurPitch.getValue(),OurRoll.getValue()));
			me.eject_vec    = me.myMath.product(-me.eject_speed, me.eject_vec);
			me.init_rel_vec = me.myMath.plus(me.aircraft_vec, me.eject_vec);
			me.speed_down_fps = -me.init_rel_vec[2];
			me.speed_east_fps = -me.init_rel_vec[1];
			me.speed_north_fps = me.init_rel_vec[0];
			me.msl_hdg   = geo.normdeg(math.atan2(me.speed_east_fps,me.speed_north_fps)*R2D);
			me.msl_pitch = math.atan2(-me.speed_down_fps, math.sqrt(me.speed_east_fps*me.speed_east_fps+me.speed_north_fps*me.speed_north_fps))*R2D;
		}

		me.alt_ft = malt;
		me.pitch = me.msl_pitch;
		me.hdg = me.msl_hdg;

		me.latN.setDoubleValue(mlat);
		me.lonN.setDoubleValue(mlon);
		me.altN.setDoubleValue(malt);
		me.hdgN.setDoubleValue(me.msl_hdg);
		me.pitchN.setDoubleValue(me.msl_pitch);
		me.rollN.setDoubleValue(0);

		me.keepPitch = me.pitch;

		if (getprop("sim/flight-model") == "jsb") {
			# currently not supported in Yasim
			me.density_alt_diff = getprop("fdm/jsbsim/atmosphere/density-altitude") - me.ac.alt()*M2FT;
		}

		# setup lofting and cruising
		me.snapUp = me.loft_alt > 10000;

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
		me.mass = me.weight_launch_lbm * LBM2SLUGS;

		# find the fuel consumption - lbm/sec
		var impulse1 = me.force_lbf_1 * me.stage_1_duration; # lbf*s
		var impulse2 = me.force_lbf_2 * me.stage_2_duration; # lbf*s
		var impulse3 = me.force_lbf_3 * me.stage_3_duration; # lbf*s
		me.impulseT = impulse1 + impulse2 + impulse3;                  # lbf*s
		me.fuel_per_impulse = me.weight_fuel_lbm / me.impulseT;# lbm/(lbf*s)
		me.fuel_per_sec_1  = me.stage_1_duration == 0?0:(me.fuel_per_impulse * impulse1) / me.stage_1_duration;# lbm/s
		me.fuel_per_sec_2  = me.stage_2_duration == 0?0:(me.fuel_per_impulse * impulse2) / me.stage_2_duration;# lbm/s
		me.fuel_per_sec_3  = me.stage_3_duration == 0?0:(me.fuel_per_impulse * impulse3) / me.stage_3_duration;# lbm/s

		me.printExtendedStats();


		# find the sun:
		var sun_x = getprop("ephemeris/sun/local/x");
		var sun_y = getprop("ephemeris/sun/local/y");# unit vector pointing to sun in geocentric coords
		var sun_z = getprop("ephemeris/sun/local/z");
		if (sun_x != nil) {
			me.sun_enabled = TRUE;
			me.sun = geo.Coord.new();
			me.sun.set_xyz(me.ac_init.x()+sun_x*2000000, me.ac_init.y()+sun_y*2000000, me.ac_init.z()+sun_z*2000000);#heat seeking missiles don't fly far, so setting it 2000Km away is fine.
			me.sun.alt();# TODO: once fixed in FG this line is no longer needed.
		} else {
			# old FG versions does not supply location of sun. So this feature gets disabled.
			me.sun_enabled = FALSE;
		}

		me.lock_on_sun = FALSE;

		loadNode.remove();

		# lets run the main flight loop in its own thread:
		var frameTrigger = func {
			thread.semup(me.frameToggle);
		}
		me.frameLoop = maketimer(0, frameTrigger);
		me.frameLoop.simulatedTime = 1;# Prevents paused sim from triggering update
		me.frameLoop.start();
		spawn(me.flight, me)();
#		me.ai.getNode("valid").setBoolValue(1); is now done at end of first flight update.
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
			classesSep = ", ";
		}
		if (me.target_pnt) {
			classes = classes~classesSep~"TGP point";
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
		if (me.guidanceLaw == "LOS") {
			nav = "Line-of-sight";
		} elsif (me.guidanceLaw == "direct") {
			nav = "Pure pursuit."
		} elsif (me.guidanceLaw == "OPN") {
			nav = "Original Proportional navigation. Proportionality constant is "~me.pro_constant;
		} elsif (me.guidanceLaw == "PN") {
			nav = "Proportional navigation. Proportionality constant is "~me.pro_constant;
		} elsif (me.guidanceLaw == "APN") {
			nav = "Augmented proportional navigation. Proportionality constant is "~me.pro_constant;
		} elsif (me.guidanceLaw == "GPN") {
			nav = "Augmented proportional navigation. Proportionality constant is "~me.pro_constant~" for lateral and "~(wingedGuideFactor*me.pro_constant)~" for longitudal";
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
		if (me.force_lbf_1 > 0 and me.stage_1_duration > 0 and me.force_lbf_2 > 0 and me.stage_2_duration > 0 and me.force_lbf_3 > 0 and me.stage_3_duration > 0) {
			stages = 3;
		} elsif (me.force_lbf_1 > 0 and me.stage_1_duration > 0 and me.force_lbf_2 > 0 and me.stage_2_duration > 0) {
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
		me.printStats("Damage ID is %d, notification ID is %d, unique ID is %d", me.typeID, me.typeID+21,me.unique_id);
		me.printStats("DETECTION AND FIRING:");
		me.printStats("Fire range %.1f-%.1f NM", me.min_fire_range_nm, me.max_fire_range_nm);
		if (me.expand_min) {
			me.printStats("Min fire range will expand with closing rate.");
		}
		me.printStats("Can be fired againts %s targets", classes);
		me.printStats("Pilot will call out %s when firing.",me.brevity);
		me.printStats("Launch platform detection field of view is +-%d degrees.",me.fcs_fov);
		if (me.guidance =="heat") {
			me.printStats("Seekerhead beam width is %.1f degrees radius.",me.beam_width_deg);
		}
		me.printStats("Weapons takes %.1f seconds to get ready.",me.ready_time);
		me.printStats("Cooling supported: %s",cooling);
		if (me.coolable) {
			me.printStats("Time to cool %.1f seconds. Can be kept cool for %d seconds.",me.cool_time,me.cool_duration);
			me.printStats("Max detect range when warm is %.1f NM, when cold %.1f NM.",me.warm_detect_range_nm, me.cold_detect_range_nm);
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
		if (me.radarOrigin) {
			me.printStats("Radar in launch vehicle is located inside vehicle at origin.");
		} else {
			me.printStats("Radar in launch vehicle is located inside vehicle coord system at position %.2f,%.2f,%.2f meters.", me.radarX, me.radarY, me.radarZ);
		}
		if (me.noCommonTarget) {
			me.printStats("This weapon can not use armament.contact as target, it must be set explicit [setContacts(contacts) or release(contacts)] instead.");
		}
		me.printStats("NAVIGATION AND GUIDANCE:");
		if (!me.guidanceEnabled) {
			me.printStats("All guidance has been disabled, the weapon will not guide.");
		} else {
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

			me.printStats("After propulsion ends, it will max steer up to %d degree pitch.",me.maxPitch);
			if(me.Tgt == nil) {
				me.printStats("Note: Ordnance was released with no lock or destination target.");
			}
			me.printStats("Seekerheads ability to filter out background noise is %.2f, where 0 is perfect and 3 is not so good.", me.seeker_filter);
			me.printStats("Exhaust plume will reduce drag by %d percent.", (1-me.Cd_plume)*100);
			if (me.rosette_radius > 0) {
				me.printStats("When uncaged and not tracking, seekerhead will do rosette pattern, with %.1f deg radius.", me.rosette_radius);
			} else {
				me.printStats("When uncaged and not tracking, seekerhead will not do anything useful.");
			}
			if (me.seam_support) {
				me.printStats("The missile support manual cage/uncage and radar slaving, and possibly auto-uncaging.");
				if (me.oldPattern) {
					me.printStats("If nutation is enabled, the seekerhead will do a double-D pattern.");
				} else {
					me.printStats("If nutation is enabled, the seekerhead will do a circle pattern.");
				}
			} else {
				me.printStats("The missile does not support manual cage/uncage or radar slaving.");
			}
		}
		if (stages > 0) {
			me.printStats("PROPULSION:");
			me.printStats("Stage 1: %d lbf for %.1f seconds. Is %s engine.", me.force_lbf_1, me.stage_1_duration, me.stage_1_jet?"jet":"rocket");
			if (stages > 1) {
				me.printStats("Stage 2: %d lbf for %.1f seconds. Is %s engine.", me.force_lbf_2, me.stage_2_duration, me.stage_2_jet?"jet":"rocket");
				if (me.stage_gap_duration > 0) {
					me.printStats("Stage 1 to 2 time gap: %.1f seconds.", me.stage_gap_duration);
				}
				if (stages > 2) {
					me.printStats("Stage 3: %d lbf for %.1f seconds. Is %s engine.", me.force_lbf_3, me.stage_3_duration, me.stage_3_jet?"jet":"rocket");
				}
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
		me.printStats("Will explode if target range is increasing and within %d meters of target.",me.reportDist);
		if (me.inert) {
			me.printStats("Warhead is inert though and will not detonate.");
		}
		if (me.simple_drag) {
			me.printStats("Simplified induced drag will be used to determine speed bleed due to G's");
		} else {
			me.printStats("To determine speed bleed due to G's wing aspect ratio is %.1f and wing effeciancy is %.2f.",me.wing_aspect_ratio,me.wing_eff);
		}
		me.printStats("LAUNCH CONDITIONS:");
		if (me.rail) {
			me.printStats("Weapon is fired from rail/tube of length %.1f meters.",me.rail_dist_m);
			if (me.rail_forward) {
				me.printStats("Launch direction is forward.");
			} else {
				me.printStats("Launch direction is %d degrees upward.", me.rail_pitch_deg);
				me.printStats("                and %d degrees right.", me.rail_head_deg);
			}
		} else {
			me.printStats("Weapon is dropped from launcher. Dropping for %.1f seconds.",me.drop_time);#todo
			me.printStats("After drop it takes %.1f seconds to deploy wings.",me.deploy_time);#todo
			if (me.guideWhileDrop) {
				me.printStats("In drop it will already start guiding if speed is high enough.");
			}
		}
		if (me.intoBore or me.eject_speed != 0) {
			me.printStats("Weapon will be unaffected by airstream when released.");
		} else {
			me.printStats("Weapon will be turn into airstream when released.");
		}
		if (!me.rail and me.eject_speed != 0) {
			me.printStats("Weapon will be ejected at %.1f feet/sec.",me.eject_speed);
		}
		if (me.guidance == "heat" or me.guidance == "radar" or me.guidance == "semi-radar") {
			me.printStats("COUNTER-MEASURES:");
			if (me.guidance == "radar" or me.guidance == "semi-radar") {
				me.printStats("Resistance to chaff is %d%%.",me.chaffResistance*100);
			} elsif (me.guidance == "heat") {
				me.printStats("Resistance to flares is %d%%.",me.flareResistance*100);
			}
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

	setNewTargetInFlight: func (tagt) {
		me.Tgt = tagt;
		me.callsign = tagt==nil?"Unknown":damage.processCallsign(me.Tgt.get_Callsign());
		me.printStatsDetails("Target set to %s", me.callsign);
		me.newTargetAssigned = tagt==nil?FALSE:TRUE;
		me.t_coord = tagt==nil?nil:me.Tgt.get_Coord();
		me.fovLost = FALSE;
		me.lostLOS = tagt==nil?TRUE:FALSE;# to do prowl flight something needs to be lost.
		me.radLostLock = FALSE;
		me.semiLostLock = FALSE;
		me.heatLostLock = FALSE;
		me.hasGuided = FALSE;
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
		me.counter += 1;#main counter for which number of loop we are in.

		if (me.pendingLaunchSound > -1 and me.life_time >= me.pendingLaunchSound and me.counter >= 5) {
			# For some reason, sound needs some time to see that the property is false, so we let counter go to 5 before we set it to true.
			me.launchSoundProp.setBoolValue(1);
			me.pendingLaunchSound = -1;
		}

		me.elapsed = systime();

		me.dt = (me.elapsed - me.elapsed_last)*speedUp.getValue();
		me.elapsed_last = me.elapsed;

		if(me.dt <= 0 or me.dt > 0.4) {
			# Negative can happen if OS adjust clock while we are flying.
			# Large dt can happen when pausing the sim or with heavy stuttering.
			continue;# back to while() loop and wait for semaphore up.
		}

		me.life_time += me.dt;

		me.handleMidFlightFunc();

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
				me.newTgt = me.contacts[me.switchIndex];
				if (!me.newLock(me.newTgt)) {
					me.Tgt = nil;
					me.callsign = "Unknown";
					me.newTargetAssigned = FALSE;
				} else {
					me.setNewTargetInFlight(me.newTgt);
				}
			}
		}

		if (me.prevGuidance != me.guidance) {
			me.keepPitch = me.pitch;
		}
		if (me.Tgt != nil and me.Tgt.isValid() == FALSE) {#TODO: verify that the following threaded code can handle invalid contact. As its read from property-tree, not mutex protected.
			if (!(me.canSwitch and me.reaquire)) {
				me.printStats(me.type~": Target went away, deleting missile.");
				#me.sendMessage(me.type~" missed "~me.callsign~": Target logged off.");
				thread.lock(mutexTimer);
				append(AIM.timerQueue, [me,me.del,[],0]);
				append(AIM.timerQueue, [me,me.log,[me.callsign~" logged off. Deleting "~me.typeLong],0]);
				thread.unlock(mutexTimer);
				AIM.setETA(nil);
				return;
			} else {
				me.Tgt = nil;
				me.callsign = "Unknown";
				me.newTargetAssigned = FALSE;
			}
		} elsif (me.Tgt != nil and me.Tgt.get_type() == POINT and me.guidance == "laser" and me.usingTGPPoint and contactPoint == nil) {
			# if laser illuminated lock is lost on a targetpod target:
			if (!(me.canSwitch and me.reaquire)) {
				me.Tgt = nil;
				me.guidance = "unguided";
				me.printStats("Guidance switched to %s",me.guidance);
			} else {
				me.Tgt = nil;
				me.callsign = "Unknown";
				me.newTargetAssigned = FALSE;
			}
		} elsif (me.Tgt == nil and me.guidance == "laser" and me.usingTGPPoint and contactPoint != nil) {
			# see if we can regain lock on new laser spot:
			if (me.newLock(contactPoint)) {
				me.setNewTargetInFlight(contactPoint);
				me.printStats("Laser lock switched to %s",me.callsign);
			} else {
				me.printStats("Laser spot ignored, could not lock on %s",me.settings.target.get_Callsign());
			}
		}

		if (me.rail == FALSE) {
			me.deploy = me.clamp(me.extrapolate(me.life_time, me.drop_time, me.drop_time+me.deploy_time,0,1),0,1);
		} elsif (me.rail_passed_time == nil and me.rail_passed == TRUE) {
			me.rail_passed_time = me.life_time;
			me.deploy = 0;
		} elsif (me.rail_passed_time != nil) {
			me.deploy = me.clamp(me.extrapolate(me.life_time, me.rail_passed_time, me.rail_passed_time+me.deploy_time,0,1),0,1);
		}
		me.deploy_prop.setDoubleValue(me.deploy);

		me.thrust_lbf = me.thrust();# pounds force (lbf)
		

		# Jmav remove the # from the line below for cruise missile adjustment:
		#me.printAlways("guiding=%d  time=%d:  mach=%.3f  alt=%d  %s",me.guiding, me.life_time, me.speed_m, me.alt_ft, me.observing);


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
		if (me.speed_m > me.maxMach2 and me.life_time > (me.drop_time + me.stage_1_duration) and me.life_time <= (me.drop_time + me.stage_1_duration + me.stage_gap_duration+me.stage_2_duration)) {
			me.maxMach2 = me.speed_m;
		}
		if (me.speed_m > me.maxMach3 and me.life_time > (me.drop_time + me.stage_1_duration + me.stage_gap_duration + me.stage_2_duration) and me.life_time <= (me.drop_time + me.stage_1_duration + me.stage_gap_duration+me.stage_2_duration+me.stage_3_duration)) {
			me.maxMach3 = me.speed_m;
		}
		if (me.maxMach4 == 0 and me.life_time > (me.drop_time + me.stage_1_duration + me.stage_gap_duration+me.stage_2_duration+me.stage_3_duration)) {
			me.maxMach4 = me.speed_m;
		}

		me.Cd = me.drag(me.speed_m,me.myG);

		me.speed_change_fps = me.speedChange(me.thrust_lbf, me.rho, me.Cd);


		if (me.last_dt != 0) {
			me.speed_change_fps = me.speed_change_fps + me.energyBleed(me.g, me.altN.getValue() + me.density_alt_diff);
		}



		###################
		#### Guidance.#####
		###################

		if(me.speed_m < me.min_speed_for_guiding) {
			# No guidance at low speed.
			# Still go through the guidance loop for sensor logic (need to check flares, LOS, etc.
			# to detect loss of lock), but the steering commands will be ignored.
			if (me.tooLowSpeed == FALSE) {
				me.printStats(me.type~": Not guiding (too low speed)");
			}
			me.tooLowSpeed = TRUE;
		} else {
			me.tooLowSpeed = FALSE;
		}

		if (me.guidance == "remote" or me.guidance == "remote-stable") {
			me.printGuide("Remote control");
			if (me.guidance == "remote-stable") {
				me.remoteControlStabilized();
			} else {
				me.remoteControl();
			}
			AIM.setETA(nil);
		    me.prevETA = nil;
		} elsif (me.Tgt != nil and me.t_coord !=nil and me.free == FALSE and me.guidance != "unguided"
			and (me.rail == FALSE or me.rail_passed == TRUE) and me.guidanceEnabled) {
				#
				# Here we figure out how to guide, navigate and steer.
				#
				if (me.guidance == "level") {
					me.level();
					AIM.setETA(nil);
			        me.prevETA = nil;
				} elsif (me.guidance == "gyro-pitch") {
					me.pitchGyro();
					AIM.setETA(nil);
			        me.prevETA = nil;
				} else {
					me.guide();
					if (!me.guiding) {
			            AIM.setETA(nil);
			            me.prevETA = nil;
			        }
				}
	            me.observing = me.guidance;
	    } elsif (me.guidance != "unguided" and (me.rail == FALSE or me.rail_passed == TRUE) and me.guidanceEnabled and me.free == FALSE and me.t_coord == nil
	    		and (me.newTargetAssigned or (me.canSwitch and (me.fovLost or me.lostLOS or me.radLostLock or me.semiLostLock or me.heatLostLock) or (me.loal and me.maddog)))) {
	    	# check for too low speed not performed on purpuse, difference between flying straight on A/P and making manouvres.
	    	if (me.observing != me.standbyFlight) {
            	me.keepPitch = me.pitch;
            }
            me.printGuide("Prowling");
	    	if (me.standbyFlight == "level") {
				me.level();
			} elsif (me.standbyFlight == "5") {
				me.level5();
			} elsif (me.standbyFlight == "gyro-pitch") {
				me.pitchGyro();
			} elsif (me.standbyFlight == "terrain-follow") {
				me.terrainFollow();
			} else {
				me.track_signal_e = 0;
				me.track_signal_h = 0;
			}
            me.observing = me.standbyFlight;
            AIM.setETA(nil);
            me.prevETA = nil;
		} else {
			me.observing = "unguided";
			me.track_signal_e = 0;
			me.track_signal_h = 0;
			me.printGuide("Unguided");
			#me.printGuideDetails(sprintf("not guiding %d %d %d %d %d",me.Tgt != nil,me.free == FALSE,me.guidance != "unguided",me.rail == FALSE,me.rail_passed == TRUE));
			AIM.setETA(nil);
			me.prevETA = nil;
		}

		if(me.tooLowSpeed) {
			# Guidance disabled due to low speed.
			me.track_signal_e = 0;
			me.track_signal_h = 0;
		} elsif (me.observing != "unguided") {
			me.limitG();
			if (me.track_signal_e > 0 and me.pitch+me.track_signal_e > me.maxPitch and me.thrust_lbf==0) {# super hack
				me.printGuideDetails("Prevented to pitch up to %.2f degs.", me.pitch+me.track_signal_e);
				me.adjst = 1-(me.pitch+me.track_signal_e - me.maxPitch)/45;
				if (me.adjst < 0) me.adjst = 0;
				me.track_signal_e *= me.adjst;
			}
			me.pitch      += me.track_signal_e;
			me.hdg        += me.track_signal_h;
			me.pitch       = math.max(-90, math.min(90, me.pitch));
			me.hdg         = geo.normdeg(me.hdg);
			me.printGuideDetails("%04.1f deg pitch    command done, new pitch: %04.1f deg", me.track_signal_e, me.pitch);
			me.printGuideDetails("%05.1f deg heading command done, new heading: %05.1f", me.last_track_h, me.hdg);
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

		if (me.rail == TRUE and me.rail_passed == FALSE) {
			# missile still on rail, lets calculate its speed relative to the wind coming in from the aircraft nose.
			me.rail_speed_into_wind = me.rail_speed_into_wind + me.speed_change_fps;
		} else {
			# gravity acc makes the weapon pitch down
			me.pitch = math.atan2(-me.speed_down_fps, me.speed_horizontal_fps ) * R2D;
		}


		if (me.rail == TRUE and me.rail_passed == FALSE) {
			me.u = noseAir.getValue();# airstream from nose
			#var v = getprop("velocities/vBody-fps");# airstream from side
			me.w = -belowAir.getValue();# airstream from below
			me.opposing_wind = me.u*math.cos(me.rail_pitch_deg*D2R)+me.w*math.sin(me.rail_pitch_deg*D2R);

			if (me.rail_forward == TRUE) {
				me.pitch = OurPitch.getValue();
				me.hdg = OurHdg.getValue();
			} else {
				me.railvec = me.myMath.eulerToCartesian3X(-me.rail_head_deg, me.rail_pitch_deg,0);
				me.veccy = me.myMath.rollPitchYawVector(OurRoll.getValue(),OurPitch.getValue(),-OurHdg.getValue(),me.railvec);
				me.carty = me.myMath.cartesianToEuler(me.veccy);
				me.defaultHeading = me.Tgt != nil?me.Tgt.get_bearing():0;#90 deg tubes align to target heading, else north
				me.pitch = me.carty[1];
				me.hdg   = me.carty[0]==nil?me.defaultHeading:me.carty[0];
			}

			me.speed_on_rail = math.max(me.rail_speed_into_wind - me.opposing_wind, 0);

			me.movement_on_rail = me.speed_on_rail * me.dt;

			me.rail_pos = me.rail_pos + me.movement_on_rail;
			if (me.rail_forward == TRUE) {
				me.x = me.x - (me.movement_on_rail * FT2M);# negative cause positive is rear in body coordinates
			} else {
				me.position_on_rail += math.max(0, me.movement_on_rail * FT2M);# only can move forward on rail.
				me.railPos = me.myMath.alongVector(me.railBegin, me.railEnd, me.rail_dist_m, me.position_on_rail);
			}
		}

		if (me.rail == FALSE or me.rail_passed == TRUE) {
			# missile not on rail, lets move it to next waypoint
			if (me.observing != "level" or me.speed_m < me.min_speed_for_guiding) {
				me.alt_ft = me.alt_ft - (me.speed_down_fps * me.dt);
			}
			me.dist_h_m = me.speed_horizontal_fps * me.dt * FT2M;
			#me.coord.apply_course_distance(me.hdg, me.dist_h_m);
			me.great = greatCircleMove(me.coord, me.hdg, me.dist_h_m*M2NM);
			me.coord.set_latlon(me.great.lat, me.great.lon, me.alt_ft * FT2M);
			#me.coord.set_alt(me.alt_ft * FT2M);
		} else {
			# missile on rail, lets move it on the rail
			if (me.rail_forward == TRUE) {
				var init_coord = nil;
				if (offsetMethod == TRUE) {
					me.geodPos = aircraftToCart({x:-me.x, y:me.y, z: -me.z});
					me.coord.set_xyz(me.geodPos.x, me.geodPos.y, me.geodPos.z);
				} else {
					me.coord = me.getGPS(me.x, me.y, me.z, OurPitch.getValue());
				}
			} else {
				me.coord = me.getGPS(-me.railPos[0], -me.railPos[1], me.railPos[2], OurPitch.getValue(), OurHdg.getValue());
			}
			me.alt_ft = me.coord.alt() * M2FT;
			# find its speed, for used in calc old speed
			me.speed_down_fps       = -math.sin(me.pitch * D2R) * me.rail_speed_into_wind;
			me.speed_horizontal_fps = math.cos(me.pitch * D2R) * me.rail_speed_into_wind;
			me.speed_north_fps      = math.cos(me.hdg * D2R) * me.speed_horizontal_fps;
			me.speed_east_fps       = math.sin(me.hdg * D2R) * me.speed_horizontal_fps;
			#printf("Rail: ms_after_fps=%d ac_fps=%d", math.sqrt(me.speed_down_fps*me.speed_down_fps+math.pow(math.sqrt(me.speed_east_fps*me.speed_east_fps+me.speed_north_fps*me.speed_north_fps),2)),math.sqrt(getprop("velocities/speed-down-fps")*getprop("velocities/speed-down-fps")+math.pow(math.sqrt(getprop("velocities/speed-east-fps")*getprop("velocities/speed-east-fps")+getprop("velocities/speed-north-fps")*getprop("velocities/speed-north-fps")),2)));
		}
		if (me.alt_ft > me.maxAlt) {
			me.maxAlt = me.alt_ft;
		}
		# Get target position.
		if (me.Tgt != nil and me.t_coord != nil) {
			if (me.flareLock == FALSE and me.chaffLock == FALSE) {
				me.t_coord = geo.Coord.new(me.Tgt.get_Coord());#in case multiple missiles use same Tgt we cannot rely on coords being different, so we extra create new.
				if (me.t_coord == nil or !me.t_coord.is_defined()) {
					# just to protect the multithreaded code for invalid pos.
					print("Missile target has undefined coord!");
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
				#me.t_coord.apply_course_distance(me.flare_hdg, me.flare_dist_h_m);
				me.great = greatCircleMove(me.t_coord, me.flare_hdg, me.flare_dist_h_m*M2NM);
				me.t_coord.set_latlon(me.great.lat, me.great.lon, me.flare_alt_ft * FT2M);
				#me.t_coord.set_alt(me.flare_alt_ft * FT2M);
			}
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
		if (!me.no_pitch or (me.rail == TRUE and me.rail_passed == FALSE)) {
			me.pitchN.setDoubleValue(me.pitch);
		} else {
			# for ejection seat
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
		#setprop("/logging/missile/altitude-ft", me.alt_ft);
		#setprop("/logging/missile/heading-deg", me.hdg);
		#setprop("/logging/missile/pitch-deg", me.pitch);


		if (me.tacview_support) {
			if (tacview.starttime and math.mod(me.counter, 3) == 0) {
				me.nme = me.type=="es"?"Parachutist":me.type;
				me.extra = me.type=="es"?"|0|0|0":"";
				thread.lock(tacview.mutexWrite);
				tacview.write("#" ~ (systime() - tacview.starttime)~"\n");
				tacview.write(me.tacviewID~",T="~me.coord.lon()~"|"~me.coord.lat()~"|"~(me.alt_ft*FT2M)~me.extra~",Name="~me.nme~",Parent="~tacview.myplaneID~"\n");#,Type=Weapon+Missile
				thread.unlock(tacview.mutexWrite);
			}
		}

		##############################
		#### Proximity detection.#####
		##############################
		if (me.rail == FALSE or me.rail_passed == TRUE) {
 			if ( me.free == FALSE ) {
				me.g = me.steering_speed_G(me.hdg, me.pitch, me.track_signal_e, me.track_signal_h, me.old_speed_fps, me.dt);
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
				me.printStats(" Absolute %.2f Mach in stage 1.", me.maxMach1);
				if (me.force_lbf_2 > 0) me.printStats(" Absolute %.2f Mach in stage 2.", me.maxMach2);
				if (me.force_lbf_3 > 0) me.printStats(" Absolute %.2f Mach in stage 3.", me.maxMach3);
				if (me.maxMach4 > 0) me.printStats(" Absolute %.2f mach propulsion end.", me.maxMach4);
				me.printStats(" Fired at %s from %.2f Mach, %5d ft at %3d NM distance. Flew %.1f NM.", me.callsign, me.startMach, me.startAlt, me.startDist * M2NM, me.ac_init.direct_distance_to(me.coord)*M2NM);
				# We exploded, and start the sound propagation towards the plane
				me.sndSpeed = me.sound_fps;
				me.sndDistance = 0;
				me.elapsed_last_snd = systime();
				if (me.explodeSound == TRUE) {
					thread.lock(mutexTimer);
					append(AIM.timerQueue, [me,me.sndPropagate,[],0]);
					thread.unlock(mutexTimer);
				} else {
					thread.lock(mutexTimer);
					append(AIM.timerQueue, [me,me.del,[],10]);
					thread.unlock(mutexTimer);
				}
				AIM.setETA(nil);
				return;
			}
		}

		if (me.Tgt == nil and me.rail == TRUE and me.rail_pitch_deg==90 and me.rail_passed == FALSE) {
			#for ejection seat to be oriented correct, wont be ran for missiles with target such as the frigate.

			# model of seat is loaded such that face is pointing in -Z FG coords.

			# Get the vector pointing up from aircraft
			var a = me.myMath.eulerToCartesian3Z(-OurHdg.getValue(), OurPitch.getValue(), OurRoll.getValue());
			#printf("HPR: %0.4f %0.4f %0.4f",OurHdg.getValue(),OurPitch.getValue(),OurRoll.getValue());
			#printf(" UP: %0.4f %0.4f %0.4f",a[0],a[1],a[2]);

			# get the pitch and heading of that vector
			var euler = me.myMath.cartesianToEuler(a);
			me.pitch = euler[1];
			me.pitchN.setDoubleValue(me.pitch);
			if (euler[0]!=nil) {
				me.hdg = euler[0];
			} else {
				# straight up or down
				me.hdg = OurHdg.getValue();
			}
			me.hdgN.setDoubleValue(me.hdg);

			# get vector pointing out from aircraft nose
			var nose = me.myMath.eulerToCartesian3X(-OurHdg.getValue(), OurPitch.getValue(), OurRoll.getValue());

			# get vector pointing perpendicular to seat travel direction (most upward possible)
			var face = me.myMath.eulerToCartesian3Z(-me.hdg, me.pitch, 0);

			# convert to angle pointing out from face if pilot turns head without nodding and looks downward
			face = me.myMath.product(-1,face);

			# get angle between face and aircraft-nose vectors
			var turnFace = me.myMath.angleBetweenVectors(face,nose);

			if (me.myMath.angleBetweenVectors(nose,me.myMath.product(-1,me.myMath.eulerToCartesian3Z(-me.hdg, me.pitch, turnFace)))>me.myMath.angleBetweenVectors(nose,me.myMath.product(-1,me.myMath.eulerToCartesian3Z(-me.hdg, me.pitch, -turnFace)))) {
				# if angle between aircraft nose and the face of pilot is greater than the roll of seat then the roll should be opposite
				#print("looking1 "~me.myMath.cartesianToEuler(me.myMath.product(-1,me.myMath.eulerToCartesian3Z(-me.hdg, me.pitch, turnFace)))[0]);
				turnFace *= -1;
				#print("turned face");
			} else {
				#turnFace *= -1;
			}

			# roll the seat so pilot faces forward
			me.rollN.setDoubleValue(turnFace);
			#print("looking2 "~me.myMath.cartesianToEuler(me.myMath.product(-1,me.myMath.eulerToCartesian3Z(-me.hdg, me.pitch, turnFace)))[0]);
			#printf("seat now at P:%d H:%d R:%d",me.pitch, me.hdg, turnFace);
		}
		if (me.rail_passed == FALSE and (me.rail == FALSE or me.rail_pos > me.rail_dist_m * M2FT)) {
			me.rail_passed = TRUE;
			me.printFlight("rail passed");
		}


		# consume fuel
		if (me.life_time > (me.drop_time + me.stage_1_duration + me.stage_gap_duration+me.stage_2_duration+me.stage_3_duration)) {
			me.weight_current = me.weight_launch_lbm - me.weight_fuel_lbm;
		} elsif (me.life_time > (me.drop_time + me.stage_1_duration+me.stage_gap_duration + me.stage_2_duration)) {
			me.weight_current = me.weight_current - me.fuel_per_sec_3 * me.dt;
		} elsif (me.life_time > (me.drop_time + me.stage_1_duration+me.stage_gap_duration)) {
			me.weight_current = me.weight_current - me.fuel_per_sec_2 * me.dt;
		} elsif (me.life_time > me.drop_time and me.life_time < (me.drop_time + me.stage_1_duration)) {
			me.weight_current = me.weight_current - me.fuel_per_sec_1 * me.dt;
		}

		me.mass = me.weight_current * LBM2SLUGS;

		# telemetry
		me.sendTelemetry();

        if (me.life_time - me.last_noti > me.noti_time and getprop("payload/armament/msg")) {
            # notify in flight using Emesary.
            me.last_noti = me.life_time;
        	thread.lock(mutexTimer);
        	var rdr = me.guidance=="radar";
			append(AIM.timerQueue, [AIM, AIM.notifyInFlight, [me.latN.getValue(), me.lonN.getValue(), me.altN.getValue()*FT2M,rdr,me.typeID,me.type,me.unique_id,me.thrust_lbf>0,(me.free or me.lostLOS or me.tooLowSpeed or me.flareLock or me.chaffLock)?"":me.callsign, me.hdg, me.pitch, me.new_speed_fps, 0], -1]);
			thread.unlock(mutexTimer);
        }

		me.last_dt = me.dt;

		me.prevGuidance = me.guidance;

		if (me.counter > -1 and !me.ai.getNode("valid").getBoolValue()) {
			# TODO: Why is this placed so late? Don't remember.
			me.ai.getNode("valid").setBoolValue(1);
			thread.lock(mutexTimer);
			append(AIM.timerQueue, [me, me.setModelAdded, [], -1]);
			thread.unlock(mutexTimer);
		}
		#############################################################################################################
		#
		#
		#
		#                                                              MAIN FLIGHT LOOP END
		#
		#
		#
		#############################################################################################################
	  }
	},

	handleMidFlightFunc: func {
		if(me.mfFunction != nil) {

			me.settings = me.mfFunction({   time_s:                 me.life_time,
                                            dist_m:                 me.dist_curr_direct,
                                            mach:                     me.speed_m,
                                            speed_fps:              me.old_speed_fps,
                                            weapon_position:         me.coord,
                                            guidance:                 me.guidance,
                                            seeker_detect_range:     me.detect_range_curr_nm,
                                            seeker_fov:             me.max_seeker_dev,
                                            weapon_pitch:             me.pitch,
                                            weapon_heading:         me.hdg,
                                            callsign:               me.callsign,
                                            deviation_deg:          me["fov_radial"],
                                            hasTarget:              me["Tgt"] != nil,
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
			if (me.settings["altitude"] != nil) {
				if (me.loft_alt != me.settings.altitude) me.printStats("Loft altitude switched to %d", me.settings.altitude);
				me.loft_alt = me.settings.altitude;
			}
			if (me.settings["altitude_at"] != nil) {
				# Altitude above target				
				me.settings.altitude_at+=me.Tgt.get_altitude();
				if (me.loft_alt != me.settings.altitude_at) me.printStats("Loft altitude switched to %d", me.settings.altitude_at);
				me.loft_alt = me.settings.altitude_at;
			}
			if (me.settings["class"] != nil) {
				me.class = me.settings.class;
				me.target_air = find("A", me.class)==-1?FALSE:TRUE;
				me.target_sea = find("M", me.class)==-1?FALSE:TRUE;
				me.target_gnd = find("G", me.class)==-1?FALSE:TRUE;
				me.target_pnt = find("P", me.class)==-1?FALSE:TRUE;
				me.printStats("Class switched to %s", me.class);
			}
			if (me.settings["target"] != nil) {
				if (me.settings.target == "nil") {
					me.setNewTargetInFlight(nil);
					me.printStats("Target removed");
				} elsif (me.newLock(me.settings.target)) {
					me.setNewTargetInFlight(me.settings.target);
					me.printStats("Target switched to %s",me.callsign);
				} else {
					me.printStats("Target switch ignored, could not lock on %s",me.settings.target.get_Callsign());
				}
			}
			if (contains(me.settings, "remote_yaw")) {
				me.remote_control_yaw = me.settings.remote_yaw;
			} else {
				me.remote_control_yaw = 0;
			}
			if (contains(me.settings, "remote_pitch")) {
				me.remote_control_pitch = me.settings.remote_pitch;
			} else {
				me.remote_control_pitch = 0;
			}
			if (me.settings["abort_midflight_function"] != nil) {
				me.mfFunction = nil;
			}
		}
	},

	sendTelemetry: func {
		if (me.data == TRUE) {

			me.eta = me.free == TRUE or me.vert_closing_rate_fps == -1?-1:(me["t_go"]!=nil?me.t_go:(me.dist_curr*M2FT)/me.vert_closing_rate_fps);
			if (me.eta < 0) me.eta = -1;
			me.hit = 50;# in percent
			if (me.life_time > me.drop_time+me.stage_1_duration + me.gnd_launch?(me.stage_2_duration + me.stage_gap_duration):0) {
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
				if (me.eta < 0) {
					# penalty if eta is incomputable
					me.hit -= 75;
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
			if (me.free == TRUE or (me.gnd_launch and (me.chaffLock or me.flareLock))) {
				# penalty for not longer guiding
				me.hit -= 75;
			}
			me.hit = int(me.clamp(me.hit, 0, 90));
			me.ai.getNode("ETA").setIntValue(me.eta);
			me.ai.getNode("hit").setIntValue(me.hit);

			if (me.gnd_launch) {
				setprop("sam/impact"~me.ID,me.eta);
				setprop("sam/hit"~me.ID,me.hit);
			}

			if (me["prevETA"] != nil) {
				if (me.prevETA < me.eta) {
					# reset the lowest eta to allow it to increase.
					AIM.setETA(nil);
				}
				AIM.setETA(me.eta, me["prevETA"]);
			}
			me.prevETA = me["eta"];
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

	drag: func (mach, N=nil) {
		# Nikolai V. Chr.: Made the drag calc more in line with big missiles as opposed to small bullets.
		#
		# The old equations were based on curves for a conventional shell/bullet (no boat-tail),
		# and derived from Davic Culps code in AIBallistic.
		me.Cd0 = 0;
		if (mach < 0.7) {
			me.Cd0 = (0.0125 * mach + 0.20) * 5 * (me.Cd_base+me.Cd_delta*me.deploy);
		} elsif (mach < 1.2 ) {
			me.Cd0 = (0.3742 * math.pow(mach, 2) - 0.252 * mach + 0.0021 + 0.2 ) * 5 * (me.Cd_base+me.Cd_delta*me.deploy);
		} else {
			if (1) {# me.simple_drag
				# https://www.desmos.com/calculator/77tfavmskq
                me.Cd0 = (0.2965 * math.pow(mach, -1.1506) + 0.2) * 5 * (me.Cd_base+me.Cd_delta*me.deploy);
            } else {
            	# https://www.desmos.com/calculator/nfu1cla7su
                me.Cd0 = (0.2965 * math.pow(mach, -2.1506) + 0.073766412) * 8 * (me.Cd_base+me.Cd_delta*me.deploy);
            }
		}

		if (!me.simple_drag) {
			if (me.vector_thrust and me.thrust_lbf>0) N=N*0.35;
			if (mach < 1.1) {
				me.Cdi = (me.Cd_base+me.Cd_delta*me.deploy)*N;# N = normal force in G
			} else {
				me.FN = N * me.mass * g_fps;# FN = normal force in LBF (me.mass is in slugs)
				me.CN  = 2*me.FN/(me.rho*me.old_speed_fps*me.old_speed_fps*me.ref_area_sqft);# Normal coefficient formula
				me.CL  = me.CN*math.cos(me.myG*1.5*D2R)-me.Cd0*math.sin(1.5*me.myG*D2R);# Lift coefficient formula (works best if G is kept under 60degs)
				me.Cdi = (me.CL*me.CL)/(math.pi*me.wing_eff*me.wing_aspect_ratio);#Induced drag formula
			}
			#me.printFlightDetails("At M%04.2f  %04.1fG  %06dft, Cdi is %06.1f%% of Cd0.", mach, N, me.alt_ft, 100*me.Cdi/me.Cd0);

			me.Cd0 = me["thrust_lbf"] != nil and me.thrust_lbf>0?me.Cd0*me.Cd_plume:me.Cd0;
		} else {
			me.Cdi = 0;# Cdi is done in another method
			me.Cd0 = me["thrust_lbf"] != nil and me.thrust_lbf>0?me.Cd0*me.Cd_plume:me.Cd0
		}

		return me.Cd0+me.Cdi;
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
		if (me.vector_thrust and me.thrust_lbf==0) max_g_sealevel=max_g_sealevel*0.666;
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
			if (me.life_time > (me.drop_time + me.stage_1_duration + me.stage_gap_duration + me.stage_2_duration + me.stage_3_duration)) {
				me.thrust_lbf = 0;
			} elsif (me.life_time > me.stage_1_duration + me.stage_gap_duration + me.drop_time + me.stage_2_duration) {
				me.thrust_lbf = me.getMilThrust(me.force_lbf_3, 3);
			} elsif (me.life_time > me.stage_1_duration + me.stage_gap_duration + me.drop_time) {
				me.thrust_lbf = me.getMilThrust(me.force_lbf_2, 2);
			} elsif (me.life_time > me.drop_time and me.life_time < me.drop_time+me.stage_1_duration) {
				me.thrust_lbf = me.getMilThrust(me.force_lbf_1, 1);
			}else {
				me.thrust_lbf = 0;
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

	getMilThrust: func (staticSealevel, stage) {
		if (stage == 1 and !me.stage_1_jet) return staticSealevel;# Its a rocket engine
		if (stage == 2 and !me.stage_2_jet) return staticSealevel;
		if (stage == 3 and !me.stage_3_jet) return staticSealevel;

		# Its a jet engine:
		me.staticLevel = staticSealevel*math.pow(0.75,me.alt_ft/10000);# for every 10000 ft reduce by 75%
		if (me.speed_m > 0.5) {
			me.lvl = me.staticLevel*me.extrapolate(me.speed_m, 0.5, 1.5, 0.9, 1.5);
		} elsif (me.speed_m > 0.2) {
			me.lvl = me.staticLevel*0.9;
		} else {
			me.lvl = me.staticLevel*me.extrapolate(me.speed_m, 0.0, 0.2, 1, 0.9);
		}
		return me.lvl;
	},

	speedChange: func (thrust_lbf, rho, Cd) {
		# Calculate speed change from last update.
		#
		# Acceleration = thrust/mass - drag/mass;

		me.acc = thrust_lbf / me.mass;
		me.q = 0.5 * rho * me.old_speed_fps * me.old_speed_fps;# dynamic pressure
		me.drag_acc = (Cd * me.q * me.ref_area_sqft) / me.mass;

		# get total new speed change (minus gravity)
		return me.acc*me.dt - me.drag_acc*me.dt;
	},

    energyBleed: func (gForce, altitude) {
    	if (!me.simple_drag) return 0;
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
        me.speedLoss = math.min(me.speedLoss, 0);
        me.energyBleedKt += me.speedLoss * FPS2KT;
        me.speedLoss = me.speedLoss*(me.thrust_lbf>0 and me.vector_thrust?0.333:1);# vector thrust will only bleed 1/3 of the calculated loss.
        return me.speedLoss;
    },

	bleed32800at0g: func () {
		me.loss_mps = 0 + ((me.last_dt - 0)/(15 - 0))*(-330 - 0);
		return me.loss_mps*M2FT;
	},

	bleed32800at25g: func () {
		me.loss_mps = 0 + ((me.last_dt - 0)/(3.5 - 0))*(-240 - 0);
		return me.loss_mps*M2FT;
	},

	bleed0at0g: func () {
		me.loss_mps = 0 + ((me.last_dt - 0)/(22 - 0))*(-950 - 0);
		return me.loss_mps*M2FT;
	},

	bleed0at25g: func () {
		me.loss_mps = 0 + ((me.last_dt - 0)/(7 - 0))*(-750 - 0);
		return me.loss_mps*M2FT;
	},

	setFirst: func() {
		if (me.smoke_prop.getValue() == TRUE and me.life_time < first_in_air_max_sec) {
			if (me.first == TRUE or first_in_air == FALSE) {
				# report position over MP for MP animation of smoke trail.
				me.first = TRUE;
				first_in_air = TRUE;
				if (me.mpShow == TRUE) {
					me.mpLat.setDoubleValue(me.coord.lat());
					me.mpLon.setDoubleValue(me.coord.lon());
					me.mpAlt.setDoubleValue(me.coord.alt());
					me.mpAltft.setDoubleValue(me.coord.alt()*M2FT);
				}
			}
		} elsif (me.first == TRUE and (me.life_time >= first_in_air_max_sec or me.life_time > me.drop_time + me.stage_1_duration + me.stage_gap_duration + me.stage_2_duration)) {
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
			me.mpAltft.setDoubleValue(0.0);
		}
	},

	limitG: func () {
		#
		# Here will be set the max angle of pitch and the max angle of heading to avoid G overload
		#
        me.myG = me.steering_speed_G(me.hdg, me.pitch, me.track_signal_e, me.track_signal_h, me.old_speed_fps, me.dt);

        if(me.myG > me.max_g_current)
        {
            me.MyCoef = me.overload_limiter(me.hdg, me.pitch, me.track_signal_e, me.track_signal_h, me.old_speed_fps, me.dt, me.max_g_current);

            me.track_signal_h =  me.MyCoef[0];
            me.track_signal_e =  me.MyCoef[1];

            me.myGnew = me.steering_speed_G(me.hdg, me.pitch, me.track_signal_e, me.track_signal_h, me.old_speed_fps, me.dt);
            #me.printFlight(sprintf("G2 %.2f", myG)~sprintf(" - Coeff %.2f", MyCoef));
            if (me.limitGs == FALSE) {
            	me.printFlight("%s: Missile pulling approx max G: %06.3f/%06.3f (%06.3f)", me.type, me.myGnew, me.max_g_current, me.myG);
            }
            me.myG = me.myGnew;
        }
        if (me.limitGs == TRUE and me.myG > me.max_g_current/2) {
        	# Save the horiz high performance maneuvering for later
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
		me.vectorToEcho   = me.myMath.eulerToCartesian2(-munition_coord.course_to(test_contact.get_Coord()), me.myMath.getPitch(munition_coord, test_contact.get_Coord()));
    	me.vectorEchoNose = me.myMath.eulerToCartesian3X(-test_contact.get_heading(), test_contact.get_Pitch(), test_contact.get_Roll());
    	me.angleToRear    = geo.normdeg180(me.myMath.angleBetweenVectors(me.vectorToEcho, me.vectorEchoNose));
    	#me.printGuideDetails(sprintf("Angle to rear %d degs.", math.abs(me.angleToRear));
    	return math.abs(me.angleToRear);
    },

    aspectToTop: func () {
    	# WIP: not used, and might never be
    	me.vectorEchoTop  = me.myMath.eulerToCartesian3Z(-echoHeading, echoPitch, echoRoll);
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

		me.curr_deviation_h = geo.normdeg180(me.curr_deviation_h);

		me.printFlightDetails("Elevation to target %05.2f degs, pitch deviation %05.2f degs, pitch %05.2f degs", me.t_elev_deg, me.curr_deviation_e, me.pitch);
		me.printFlightDetails("Bearing to target %06.2f degs, heading deviation %06.2f degs, heading %06.2f degs", me.t_course, me.curr_deviation_h, me.hdg);
		me.printFlightDetails("Altitude above launch platform = %07.1f ft", M2FT * (me.coord.alt()-me.ac.alt()));
		me.printFlightDetails("Altitude. Target %07.1f. Missile %07.1f. Atan2 %04.1f degs", me.t_coord.alt()*M2FT, me.coord.alt()*M2FT, math.atan2( me.t_coord.alt()-me.coord.alt(), me.dist_curr ) * R2D);



		if (math.abs(me.curr_deviation_h) < 15) {
			me.guidanceLawHorizInit = 0;
		}

		me.checkForLOS();

		me.checkForGuidance();

		me.checkForSun();

		me.checkForFlare();

		me.checkForChaff();

		me.canSeekerKeepUp();

		me.cruiseAndLoft();

		me.APN();# Proportional navigation

		#me.adjustToKeepLock();

		me.track_signal_e = me.raw_steer_signal_elev * !me.free * me.guiding;
		me.track_signal_h = me.raw_steer_signal_head * !me.free * me.guiding;

		me.printGuideDetails("%04.1f deg elevate command desired", me.track_signal_e);
		me.printGuideDetails("%05.1f deg heading command desired", me.track_signal_h);

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
		if (me.Tgt != nil and me.fovLost != TRUE and me.guidance == "heat" and me.flareLock == FALSE and (me.life_time-me.flareTime) > 1) {
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
						me.flareTime = me.life_time;
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
		if (me.Tgt != nil and me.fovLost != TRUE and (me.guidance == "radar" or me.guidance == "semi-radar" or me.guidance == "command") and me.chaffLock == FALSE and (me.life_time-me.chaffTime) > 1) {
			#
			# TODO: Use Richards Emissary for this.
			#
			me.chaffNode = me.Tgt.getChaffNode();#error
			if (me.chaffNode != nil) {
				me.chaffNumber = me.chaffNode.getValue();
				if (me.chaffNumber != nil and me.chaffNumber != 0) {
					if (me.chaffNumber != me.chaffLast) {# problem here is MP interpolates to new values. Hence the timer.
						# target has released a new chaff, lets check if it blinds us
						me.chaffLast = me.chaffNumber;
						me.chaffTime = me.life_time;
						me.aspectDeg = me.aspectToExhaust(me.coord, me.Tgt) / 180;# 0 = viewing engine, 1 = front
						me.redux = me.guidance == "semi-radar" or me.guidance == "command"?(me.gnd_launch?0.5:0.75):1;
						me.chaffChance = (1-me.chaffResistance)*me.redux;
						me.chaffLock = rand() < (me.chaffChance - (me.chaffChance * 0.5 * me.aspectDeg));# 50% less chance to be fooled if front aspect

						if (me.chaffLock == TRUE) {
							me.printStats(me.type~": Missile locked on chaff from "~me.callsign);
							me.flarespeed_fps = me.Tgt.get_Speed()*KT2FPS;
							me.flare_hdg      = me.Tgt.get_heading();
							me.flare_pitch    = me.Tgt.get_Pitch();
							me.chaffLockTime  = me.life_time;
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
		if (pickingMethod == TRUE and me.guidance != "gps" and me.guidance != "gps-altitude" and me.guidance != "unguided" and me.guidance != "inertial") {
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
		if(me.tooLowSpeed) {
			me.guiding = FALSE;
		} elsif ((me.guidance == "semi-radar" and me.is_painted(me.Tgt) == FALSE) or (me.guidance =="laser" and me.is_laser_painted(me.Tgt) == FALSE) ) {
			# if its semi-radar guided and the target is no longer painted
			me.guiding = FALSE;
			if (me.reaquire == TRUE) {
				if (me.semiLostLock == FALSE) {
					me.printStats(me.type~": Not guiding (lost radar reflection, trying to reaquire)");
				}
				me.semiLostLock = TRUE;
			} else {
				me.printStats(me.type~": Not guiding (lost radar reflection, gave up)");
				me.free = TRUE;
			}
		} elsif (me.guidance == "command" and (me.Tgt == nil or !me.Tgt.isCommandActive())) {
			# if its command guided and the control no longer sends commands
			me.guiding = FALSE;
			me.printStats(me.type~": Not guiding (no commands from controller)");
		} elsif (me.guidance == "radiation" and me.is_radiating_me(me.Tgt) == FALSE) {
			# if its radiation guided and the target is not illuminating us with radiation
			me.guiding = FALSE;
			if (me.reaquire == TRUE) {
				if (me.radLostLock == FALSE) {
					me.printStats(me.type~": Not guiding (lost radiation, trying to reaquire)");
				}
				me.radLostLock = TRUE;
			} else {
				me.printStats(me.type~": Not guiding (lost radiation, gave up)");
				me.free = TRUE;
			}
		} elsif ((me.dist_curr_direct*M2NM > me.detect_range_curr_nm or !me.FOV_check(me.hdg, me.pitch, me.curr_deviation_h, me.curr_deviation_e, me.max_seeker_dev, me.myMath)) and me.guidance != "gps" and me.guidance != "inertial" and me.guidance != "gps-altitude") {
			# target is not in missile seeker view anymore

			if (me.fovLost == FALSE and me.detect_range_curr_nm != 0) {
				me.normFOV = me.FOV_check_norm(me.hdg, me.pitch, me.curr_deviation_h, me.curr_deviation_e, me.max_seeker_dev, me.myMath);
				me.printStats(me.type~": "~me.callsign~" is not in seeker view. (%d%% in view, %d%% in range)", me.normFOV*100, 100*me.dist_curr_direct*M2NM / me.detect_range_curr_nm);#~me.viewLost);
			} elsif (me.fovLost == FALSE) {
				me.normFOV = me.FOV_check_norm(me.hdg, me.pitch, me.curr_deviation_h, me.curr_deviation_e, me.max_seeker_dev, me.myMath);
				me.printStats(me.type~": "~me.callsign~" is not in seeker view. (%d%% in view)", me.normFOV*100);#~me.viewLost);
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
		} elsif (me.life_time < me.drop_time and !me.guideWhileDrop) {
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
		if (me.speed_m >= me.min_speed_for_guiding) {
			me.tooLowSpeedPass = TRUE;
			if (me.tooLowSpeedTime == -1) {
				me.tooLowSpeedTime = me.life_time;
				me.normFOV = me.FOV_check_norm(me.hdg, me.pitch, me.curr_deviation_h, me.curr_deviation_e, me.max_seeker_dev, me.myMath);
				me.printStats(me.type~": Passed minimum speed for guiding after %.1f seconds. Target %d%% inside view.", me.life_time, me.normFOV*100);
			}
		}
		if (me.chaffLock and (me.guidance == "command" or me.guidance == "semi-radar") and (me.life_time - me.chaffLockTime) > (me.gnd_launch?4:6)) {
			me.chaffLock = 0;
			me.printStats(me.type~": Chaff dissipated, regained track.");
		}
	},

	adjustToKeepLock: func {
		if (me.guidance != "gps" and me.guidance != "inertial" and me.guidance != "gps-altitude") {
			if (!me.FOV_check(me.hdg, me.pitch, me.curr_deviation_h+me.raw_steer_signal_head, me.curr_deviation_e+me.raw_steer_signal_elev, me.max_seeker_dev, me.myMath) and me.fov_radial != 0) {
				# the commanded steer order will make the missile lose its lock, to prevent that we reduce the steering just enough so lock wont be lost.
				me.factorKeep = me.max_seeker_dev/me.fov_radial;
				me.raw_steer_signal_elev = (me.curr_deviation_e+me.raw_steer_signal_elev)*me.factorKeep-me.curr_deviation_e;
				me.raw_steer_signal_head = (me.curr_deviation_h+me.raw_steer_signal_head)*me.factorKeep-me.curr_deviation_h;
			}
		}
	},

	canSeekerKeepUp: func () {
		me.globalVectorToTarget = me.myMath.eulerToCartesian3X(-me.t_course, me.t_elev_deg, 0);
		me.localVectorTarget  = me.myMath.yawPitchVector(me.hdg, -me.pitch, me.globalVectorToTarget);
		if (me.counter == me.counter_last+1 and !me.newTargetAssigned and me["localVectorSeeker"] != nil and (me.guidance == "heat" or me.guidance == "vision") and me.prevGuidance == me.guidance and me.prevTarget == me.Tgt) {
			# calculate if the seeker can keep up with the angular change of the target
			#
			# missile own movement is subtracted from this change due to seeker being on gyroscope
			#
			if (!me.caged) {
				# Gyro is stabilized
				me.localVectorSeeker = me.myMath.yawPitchVector(me.last_track_h, -me.last_track_e, me.localVectorSeeker);
			}
			me.angleSeekerToTarget  = me.myMath.angleBetweenVectors(me.localVectorSeeker, me.localVectorTarget);
			me.deviation_per_sec = me.angleSeekerToTarget/me.dt;

			if (me.deviation_per_sec > me.angular_speed) {
				if (me.angleSeekerToTarget < me.beam_width_deg) {
					me.max_seekertrack    = me.angular_speed * me.dt;
					me.localVectorSeeker  = me.myMath.rotateVectorTowardsVector(me.localVectorSeeker, me.localVectorTarget, me.max_seekertrack);
					me.printStatsDetails("%s: %4.1f deg/s too fast angular change for seeker head. %5.2fnm to target. Target still in beam though: %4.2f/%4.2f degs.", me.type, me.deviation_per_sec, me.dist_curr_direct*M2NM, me.angleSeekerToTarget-me.max_seekertrack, me.beam_width_deg);
				} else {
					# lost lock due to angular speed limit could not keep target in beam
					me.printStats("%s: %4.1f deg/s too fast angular change for seeker head to keep target in beam. %5.2fnm to target.", me.type, me.deviation_per_sec, me.dist_curr_direct*M2NM);
					me.free = TRUE;
				}
			} else {
				me.localVectorSeeker  = me.localVectorTarget;
				me.printStatsDetails("%s: %4.1f deg/s fine     angular change for seeker head. %5.2fnm to target.", me.type, me.deviation_per_sec, me.dist_curr_direct*M2NM);
			}
		} else {
			me.localVectorSeeker  = me.localVectorTarget;
		}
		me.prevTarget = me.Tgt;
		me.counter_last = me.counter;# since we use dt as time passed since last we were in this function, we need to be sure only 1 loop has passed.
	},

	cruiseAndLoft: func () {
		#
		# cruise, loft, cruise-missile
		#
		if (me.guiding == FALSE) {
			return;
		}
		me.loft_angle = 15;# notice Shinobi used 26.5651 degs, but Raider1 found a source saying 10-20 degs.
		me.cruise_or_loft = FALSE;# If true then this method handles the vertical component of guiding.
		me.time_before_snap_up = me.drop_time * 3;
		me.limitGs = FALSE;

		if (me.loft_alt != 0 and me.guidance == "gps-altitude") {
			me.t_alt_delta_ft = me.loft_alt - me.alt_ft;
            if(me.t_alt_delta_ft < 0) {
                #me.printAlways("Moving down %5d ft  M%.2f %.2fNM",-me.t_alt_delta_ft, me.speed_m, me.dist_curr*M2NM);
                me.slope = me.clamp(me.t_alt_delta_ft / 300, -30, 0);# the lower the desired alt is, the steeper the slope, but not steeper than 30
                me.raw_steer_signal_elev = -me.pitch + me.clamp(math.atan2(me.t_alt_delta_ft, me.old_speed_fps * 15) * R2D, me.slope, 0);
            } elsif (me.speed_m > 0.6) {
            	#me.printAlways("Moving up   %5d ft  M%.2f %.2fNM", me.t_alt_delta_ft, me.speed_m, me.dist_curr*M2NM);
                me.raw_steer_signal_elev = -me.pitch + math.atan2(me.t_alt_delta_ft, me.old_speed_fps * 30) * R2D;
            } else {
            	me.raw_steer_signal_elev = 0;
            	#me.printAlways("   no move   M%.2f %.2fNM", me.speed_m, me.dist_curr*M2NM);
            }
			me.cruise_or_loft = 1;
        } elsif(me.loft_alt != 0 and me.snapUp == FALSE) {
        	# this is for Air to ground/sea cruise-missile (SCALP, Sea-Eagle, Taurus, Tomahawk, RB-15...)

        	var code = 1;# 0 = old, 1 = new, 2 = angle

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

	            # Do terrain following for air/ground missile (but not anti-ship), or if explicitly set with me.follow
	            if (me.follow or (me.Tgt != nil and (me.Tgt.get_type() == SURFACE or me.Tgt.get_type() == POINT))) {
	                # detect terrain for use in terrain following
	                me.nextGroundElevationMem[1] -= 1;
	                #First we need origin coordinates we transorfm it in xyz
	                xyz = {"x":me.coord.x(),                  "y":me.coord.y(),                 "z":me.coord.z()};

	                #Then we need the coordinate of the future point at let say 20 dt
	                me.geoPlus4 = me.nextGeoloc(me.coord.lat(), me.coord.lon(), me.hdg, me.old_speed_fps, 5);
	                me.geoAlt = geo.elevation(me.geoPlus4.lat(),me.geoPlus4.lon());
	                if (me.geoAlt != nil) {
	                    me.geoPlus4.set_alt(me.geoAlt);
	                }

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
	                        # Factor 0.95 to account for error in the two distance computations.
	                        # Otherwise falso positive obstacle detection occurs.
	                        if(me.coord.direct_distance_to(GroundIntersectCoord) > 0.95 * distance_Target){
	                            No_terrain = 1;
	                        }else{
	                            #Raising geoPlus4 altitude by 100 meters
	                            me.geoPlus4.set_alt(me.geoPlus4.alt()+altitude_step);
	                            #print("Alt too low :" ~ me.geoPlus4.alt() ~ "; Raising alt by 30 meters (100 feet)");
	                        }
	                    }

	                }
	                me.printGuideDetails("There was : " ~ howmany ~ " iteration of the ground loop");
	                me.nextGroundElevation = me.geoPlus4.alt();

	                me.Daground = me.nextGroundElevation * M2FT;
	            } else {
	                me.Daground = 0;# zero for sealevel in case target is ship. Don't shoot A/S missiles over terrain. :)
	            }

	            me.loft_alt_curr = me.loft_alt;
	            if (me.Tgt != nil and me.dist_curr < me.old_speed_fps * me.terminal_rise_time * FT2M and me.dist_curr > me.old_speed_fps * me.terminal_dive_time * FT2M) {
	            	# the missile lofts a bit at the end to avoid PN to slam it into ground before target is reached.
	            	# end here is between 2.5-4 seconds
	            	me.loft_alt_curr = me.loft_alt*me.terminal_alt_factor;
	            }
	            if (me.Tgt == nil or me.dist_curr > me.old_speed_fps * me.terminal_dive_time * FT2M) {# need to give the missile time to do final navigation
	                # Here we do the actual steering over terrain
	                me.t_alt_delta_ft = (me.loft_alt_curr + me.Daground - me.alt_ft);
	                me.printGuideDetails("var t_alt_delta_m : "~me.t_alt_delta_ft*FT2M);
	                if(me.loft_alt_curr + me.Daground > me.alt_ft) {
	                    me.printGuideDetails("Moving up");
	                    me.raw_steer_signal_elev = -me.pitch + math.atan2(me.t_alt_delta_ft, me.old_speed_fps * me.dt * 5) * R2D;
	                } else {
	                    me.printGuideDetails("Moving down");
	                    me.slope = me.clamp(me.t_alt_delta_ft / 300, -7.5, 0);# the lower the desired alt is, the steeper the slope, but not steeper than 7.5
	                    me.raw_steer_signal_elev = -me.pitch + me.clamp(math.atan2(me.t_alt_delta_ft, me.old_speed_fps * me.dt * 5) * R2D, me.slope, 0);
	                }
	                me.cruise_or_loft = TRUE;
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
	            if (me.dist_curr < me.old_speed_fps * me.terminal_rise_time * FT2M and me.dist_curr > me.old_speed_fps * me.terminal_dive_time * FT2M) {
	            	# the missile lofts a bit at the end to avoid APN to slam it into ground before target is reached.
	            	# end here is between 2.5-4 seconds
	            	me.loft_alt_curr = me.loft_alt*me.terminal_alt_factor;
	            }
	            if (me.dist_curr > me.old_speed_fps * me.terminal_dive_time * FT2M) {# need to give the missile time to do final navigation
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
	            }
	            if (me.cruise_or_loft == TRUE) {
	            	me.printGuideDetails(" pitch "~me.pitch~" + me.raw_steer_signal_elev "~me.raw_steer_signal_elev);
	            }
	        }
        #} elsif (me.rail == TRUE and me.rail_forward == FALSE and me.rotate_token == FALSE) {
			# tube launched missile turns towards target

		#	me.raw_steer_signal_elev = me.curr_deviation_e;
		#	me.printGuideDetails("Turning, desire "~me.t_elev_deg~" degs pitch.");
		#	me.cruise_or_loft = TRUE;
		#	me.limitGs = TRUE;
		#	if (math.abs(me.curr_deviation_e) < 20) {
		#		me.rotate_token = TRUE;
		#		me.printGuide("Is last turn, snap-up/PN takes it from here..")
		#	}
		} elsif (me.snapUp == TRUE and me.t_elev_deg > me.clamp(-50/me.speed_m,-30,-5) and me.dist_curr * M2NM > me.speed_m * 6
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
		         and me.t_elev_deg > me.clamp(-50/me.speed_m,-30,-5) and me.dist_curr * M2NM > me.speed_m * 5.5) {
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

	level5: func () {
        me.track_signal_e = (5-me.pitch) * !me.free;
        me.track_signal_h = 0;
        me.printGuide("Gyro keeping %04.1f deg pitch. Current is %04.1f deg.", 5, me.pitch);
	},

	pitchGyro: func () {
        me.track_signal_e = (me.keepPitch-me.pitch) * !me.free;
        me.track_signal_h = 0;
        me.printGuide("Gyro keeping %04.1f deg pitch. Current is %04.1f deg.", me.keepPitch, me.pitch);
	},

	# Terrain following as standby guidance mode.
	terrainFollow: func () {
		me.cruiseAndLoft();
		me.track_signal_e = me.raw_steer_signal_elev * !me.free;
		me.track_signal_h = me.raw_steer_signal_head * !me.free;
	},

	remoteControl: func () {
		me.track_signal_e = me.remote_control_pitch * me.dt * !me.free;
		me.track_signal_h = me.remote_control_yaw * me.dt * !me.free;
		me.printGuide("Remote input: %04.1f deg/s pitch, %04.1f deg/s yaw.",
		              me.remote_control_pitch, me.remote_control_yaw);
	},

	remoteControlStabilized: func () {
		me.keepPitch += me.remote_control_pitch * me.dt;
		me.track_signal_e = (me.keepPitch - me.pitch) * !me.free;
		me.track_signal_h = me.remote_control_yaw * me.dt * !me.free;
		me.printGuide("Remote input: %04.1f deg/s pitch, %04.1f deg/s yaw.",
		              me.remote_control_pitch, me.remote_control_yaw);
	},

	APN: func () {
		#
		# guidance laws
		#
		if (me.guiding == TRUE and me.free == FALSE and me.dist_last != nil and me.last_dt != 0 and me.newTargetAssigned==FALSE) {
			# augmented proportional navigation for heading #
			#################################################

			if (me.guidanceLaw == "direct" or (me.guidanceLaw == "LOS" and me.life_time < 4)) {
				# pure pursuit
				me.raw_steer_signal_head = me.curr_deviation_h;
				if (me.cruise_or_loft == FALSE) {
					me.raw_steer_signal_elev = me.curr_deviation_e;
					me.attitudePN = (math.atan2(-(me.speed_down_fps+g_fps * me.dt), me.speed_horizontal_fps ) - math.atan2(-me.speed_down_fps, me.speed_horizontal_fps )) * R2D;
		            me.gravComp = - me.attitudePN;
		            #printf("Gravity compensation %0.2f degs", me.gravComp);
		            me.raw_steer_signal_elev += me.gravComp;
				}
				return;
			} elsif (find("OPN", me.guidanceLaw)!=-1) {
				me.apn = -1;
				me.gpn = 1;
			} elsif (find("APN", me.guidanceLaw)!=-1) {
				me.apn = 1;
				me.gpn = 1;
			} elsif (find("GPN", me.guidanceLaw)!=-1) {
				me.apn = 1;
				me.gpn = wingedGuideFactor;
			} else {
				me.apn = 0;
				me.gpn = 1;
			}

			if (me["noise"]==nil or me["last"] == nil) {
				me.noise = 1;
				me.last = 0;
				me.next = 0.10;
				me.seed = rand()*me.seeker_filter;
			}
			if (me.life_time > 6) {
				me.noise = 1;
			} elsif (me.seeker_filter > 0 and me.guidance != "gps" and me.guidance != "gps-altitude" and me.life_time-me.last > me.next) {
				# PN noise.
				me.sign = me.seed>0.85?(rand()>0.75?-1:1):1;
				me.opnNoiseReduct = me.apn == -1?0.5:1;
				me.noise = (1+me.seeker_filter*me.opnNoiseReduct)*rand();
				me.noise = me.sign*(me.noise + 1);          # the noise factor
				me.last = me.life_time;
				me.next = me.seeker_filter*0.15*rand();# duration for this noise factor, till a new is computed.
			}

			me.horz_closing_rate_fps = ((me.dist_last - me.dist_curr)*M2FT)/me.dt+me.horz_closing_rate_fps;#clamped due to cruise missiles that can fly slower than target.
			me.horz_closing_rate_fps *= 0.5;# average over 2 frames
			me.printGuideDetails("Horz closing rate: %05d ft/sec", me.horz_closing_rate_fps);
			me.vert_closing_rate_fps = ((me.dist_direct_last - me.dist_curr_direct)*M2FT)/me.dt+me.vert_closing_rate_fps;
			me.vert_closing_rate_fps *= 0.5;
			me.printGuideDetails("Vert closing rate: %05d ft/sec", me.vert_closing_rate_fps);
			# Note: Since PN will steer opposite at negative closing rate, we will later use only the absolute magnitudes.
			# This is especially important before we really gain speed against a receding fast target.

			me.course_deviation = geo.normdeg180(me.t_course-me.last_t_course);

			me.line_of_sight_rate_rps = (D2R*me.course_deviation)/me.dt;#positive clockwise

			me.printGuideDetails("LOS rate: %06.4f rad/s", me.line_of_sight_rate_rps);

			me.t_velocity = me.myMath.getCartesianVelocity(-me.Tgt.get_heading(), me.Tgt.get_Pitch(), me.Tgt.get_Roll(), me.Tgt.get_uBody(), me.Tgt.get_vBody(), me.Tgt.get_wBody());

			if ((me.flareLock == FALSE and me.chaffLock == FALSE) or me.t_heading == nil) {
				me.euler = me.myMath.cartesianToEuler(me.t_velocity);
				if (me.euler[0] != nil) {
					me.t_heading        = me.euler[0];
				} else {
					me.t_heading        = me.Tgt.get_heading();
				}
				me.t_pitch          = me.euler[1];
				me.t_speed_fps      = me.myMath.magnitudeVector(me.t_velocity);#groundspeed
			} elsif (me.flarespeed_fps != nil) {
				me.t_speed_fps      = me.flarespeed_fps;#true airspeed
			}

			me.t_horz_speed_fps     = math.sqrt(me.t_velocity[0]*me.t_velocity[0]+me.t_velocity[1]*me.t_velocity[1]);
			me.t_LOS_norm_head_deg  = me.t_course + 90;#when looking at target this direction will be 90 deg right of target
			me.t_LOS_norm_speed_fps = math.cos((me.t_LOS_norm_head_deg - me.t_heading)*D2R)*me.t_horz_speed_fps;

			if (me.last_t_norm_speed == nil) {
				me.last_t_norm_speed = me.t_LOS_norm_speed_fps;
			}

			me.t_LOS_norm_acc_fps2  = (me.t_LOS_norm_speed_fps - me.last_t_norm_speed)/me.dt;

			me.last_t_norm_speed = me.t_LOS_norm_speed_fps;

			# time to go calc
			me.t_away_norm_speed_fps = math.cos((me.t_course - me.t_heading)*D2R)*me.t_horz_speed_fps;
			me.t_speed_vert_fps      = me.t_velocity[2];
			me.m_speed_vert_fps      = math.sin(me.pitch*D2R)*me.old_speed_horz_fps;
			me.t_pos_z               = (me.t_coord.alt()-me.coord.alt())*M2FT;
			me.Vt   = [me.t_away_norm_speed_fps,me.t_LOS_norm_speed_fps,me.t_speed_vert_fps];
			me.Vm   = [me.old_speed_horz_fps,0,me.m_speed_vert_fps];
			me.Pm   = [0,0,0];
			me.Pt   = [me.dist_curr*M2FT,0,me.t_pos_z];
			me.V_tm = me.myMath.minus(me.Vt,me.Vm);
			me.R_tm = me.myMath.minus(me.Pm,me.Pt);
			me.t_go = me.myMath.dotProduct(me.R_tm,me.R_tm)/me.myMath.dotProduct(me.R_tm, me.V_tm);
			#printf("time_to_go %.1f, closing %d",me.t_go,me.vert_closing_rate_fps);

			

			# Horizontal homing:
			if (me.guidanceLaw == "LOS") {
				
				me.K1 =    2.5;
				me.K2 =   10.0;

				me.R_m = me.ac_init.distance_to(me.coord)*M2FT;
	    		me.course_to_missile = me.ac_init.course_to(me.coord);
				me.course_to_target  = me.ac_init.course_to(me.t_coord);
				me.CREh_old_old = me.CREh_old;
				me.CREh_old = me.CREh;
				# cross range error:
				me.CREh = me.R_m*math.sin(me.clamp(geo.normdeg180(me.course_to_target - me.course_to_missile),-89,89)*D2R);
				me.CREh_dot = (me.CREh - me.CREh_old_old)/(me.dt+me.CRE_old_dt);
				me.acc_lateral_fps2 = me.K1*me.CREh_dot + me.K2*me.CREh;
				me.toBody = math.cos(geo.normdeg180(me.hdg-me.course_to_target)*D2R);
				if (me.toBody==0) me.toBody=0.0001;
				me.acc_lateral_fps2 /= me.toBody;
				me.velocity_vector_length_fps = me.clamp(me.old_speed_horz_fps, 0.0001, 1000000);
				me.commanded_lateral_vector_length_fps = me.acc_lateral_fps2*me.dt;
				me.raw_steer_signal_head  = R2D*me.commanded_lateral_vector_length_fps/me.velocity_vector_length_fps;
				#me.raw_steer_signal_head = me.curr_deviation_h;
			} elsif (me.apn == 1) {
				# APN (constant best at 5, but the higher value the more sensitive to noise)
				# Augmented proportional navigation. Takes target acc. into account. Invented for SAMs.
				me.toBody = math.cos(me.curr_deviation_h*D2R);#convert perpendicular LOS acc. to perpendicular body acc.
				if (me.toBody==0) me.toBody=0.00001;
				# acceleration perpendicular to instantaneous line of sight in feet/sec^2:
				me.acc_lateral_fps2 = me.pro_constant*me.line_of_sight_rate_rps*math.abs(me.horz_closing_rate_fps)+me.t_LOS_norm_acc_fps2*me.noise;# in some litterature the second pro_constant is replaced by t_go, but that will make the missile overcompensate.
				me.acc_lateral_fps2 /= me.toBody;
				#printf("vert acc = %.2f + %.2f G", me.pro_constant*me.line_of_sight_rate_up_rps*me.vert_closing_rate_fps/g_fps, (me.apn*me.pro_constant*me.t_LOS_elev_norm_acc/2)/g_fps);
				me.velocity_vector_length_fps = me.clamp(me.old_speed_horz_fps, 0.0001, 1000000);
				me.commanded_lateral_vector_length_fps = me.acc_lateral_fps2*me.dt;
				me.raw_steer_signal_head  = R2D*me.commanded_lateral_vector_length_fps/me.velocity_vector_length_fps;
			} elsif (me.apn == 0) {
				# PN (constant best at 3)
				# Generalized Proportional navigation.
				me.toBody = math.cos(me.curr_deviation_h*D2R);#convert perpendicular LOS acc. to perpendicular body acc.
				if (me.toBody==0) me.toBody=0.00001;
				me.acc_lateral_fps2     = me.pro_constant*me.line_of_sight_rate_rps*math.abs(me.horz_closing_rate_fps)*me.noise;
				me.acc_lateral_fps2 /= me.toBody;
				me.velocity_vector_length_fps = me.clamp(me.old_speed_horz_fps, 0.0001, 1000000);
				me.commanded_lateral_vector_length_fps = me.acc_lateral_fps2*me.dt;
				me.raw_steer_signal_head  = R2D*me.commanded_lateral_vector_length_fps/me.velocity_vector_length_fps;
			} else {
				# PN [invented during WWII by Luke Chia‐Liu Yuan]
				# Original Proportional navigation.
				# Rearranging the equations gives Pure proportional navigation, which show that this law
				# does not take missile alpha into account, and is therefore not very good in real life.
				me.radians_lateral_per_sec     = me.pro_constant*me.line_of_sight_rate_rps*me.noise;
				me.raw_steer_signal_head  = me.dt*me.radians_lateral_per_sec*R2D;
			}
			#printf("horz acc = %.1f + %.1f", proportionality_constant*line_of_sight_rate_rps*horz_closing_rate_fps, proportionality_constant*t_LOS_norm_acc/2);

			if (me.guidanceLawHorizInit) {
				# pure horiz pursuit
				me.raw_steer_signal_head = me.curr_deviation_h;
			}

			# now translate that sideways acc to an angle:



			#printf("Proportional lead: %0.1f deg horz", -(me.curr_deviation_h-me.raw_steer_signal_head));

			#me.print(sprintf("LOS-rate=%.2f rad/s - closing-rate=%.1f ft/s",line_of_sight_rate_rps,horz_closing_rate_fps));
			#me.print(sprintf("commanded-perpendicular-acceleration=%.1f ft/s^2", acc_lateral_fps2));
			#printf("horz leading by %.1f deg, commanding %.1f deg", me.curr_deviation_h, me.raw_steer_signal_head);

			if (me.cruise_or_loft == FALSE) {
				me.fixed_aim = nil;
				me.fixed_aim_time = nil;
				if (find("PN",me.guidanceLaw) != -1 and size(me.guidanceLaw) > 3) {
					me.extra = right(me.guidanceLaw, 4);
					me.fixed_aim = num(left(me.extra, 2));
					me.fixed_aim_time = num(right(me.extra, 2));
		        }
		        if (me.fixed_aim != nil and me.life_time < me.fixed_aim_time) {
		        	me.raw_steer_signal_elev = me.curr_deviation_e+me.fixed_aim;
					me.attitudePN = (math.atan2(-(me.speed_down_fps+g_fps * me.dt), me.speed_horizontal_fps ) - math.atan2(-me.speed_down_fps, me.speed_horizontal_fps )) * R2D;
		            me.gravComp = - me.attitudePN;
		            #printf("Gravity compensation %0.2f degs", me.gravComp);
		            me.raw_steer_signal_elev += me.gravComp;
				} else {
					# proportional navigation for elevation #
					#########################################
					#me.print(me.guidanceLaw~" in fully control");

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

					# Vertical homing:
					if (me.guidanceLaw == "LOS") {
			    		me.R_m = me.ac_init.direct_distance_to(me.coord)*M2FT;
			    		me.pitch_to_missile = me.myMath.getPitch(me.ac_init,me.coord);
						me.pitch_to_target  = me.myMath.getPitch(me.ac_init,me.t_coord);
						me.CREv_old_old = me.CREv_old;
						me.CREv_old = me.CREv;
						# Cross range error
						me.CREv = me.R_m*math.sin((me.pitch_to_target - me.pitch_to_missile)*D2R);
						me.CREv_dot = (me.CREv - me.CREv_old_old)/(me.dt+me.CRE_old_dt);
						me.acc_upwards_fps2 = me.K1*me.CREv_dot + me.K2*me.CREv;
						# Convert perpendicular LOS acc. to perpendicular body acc.
						me.toBody = math.cos((me.pitch - me.pitch_to_target)*D2R);
						if (me.toBody==0) me.toBody=0.00001;
						me.acc_upwards_fps2 /= me.toBody;
						# Apply the acc.
						me.velocity_vector_length_fps = me.clamp(me.old_speed_fps, 0.0001, 1000000);
						me.commanded_upwards_vector_length_fps = me.acc_upwards_fps2*me.dt;
						me.raw_steer_signal_elev  = R2D*me.commanded_upwards_vector_length_fps/me.velocity_vector_length_fps;
					} elsif (me.apn == 1) {
						# APN (constant best at 5, but the higher value the more sensitive to noise)
						# Augmented proportional navigation. Takes target acc. into account. Invented for SAMs.
						me.toBody = math.cos(me.curr_deviation_e*D2R);#convert perpendicular LOS acc. to perpendicular body acc.
						if (me.toBody==0) me.toBody=0.00001;
						me.acc_upwards_fps2 = me.gpn*me.pro_constant*me.line_of_sight_rate_up_rps*math.abs(me.vert_closing_rate_fps)+me.t_LOS_elev_norm_acc*me.noise;
						me.acc_upwards_fps2 /= me.toBody;
						#printf("vert acc = %.2f + %.2f G", me.pro_constant*me.line_of_sight_rate_up_rps*me.vert_closing_rate_fps/g_fps, (me.apn*me.pro_constant*me.t_LOS_elev_norm_acc/2)/g_fps);
						me.velocity_vector_length_fps = me.clamp(me.old_speed_fps, 0.0001, 1000000);
						me.commanded_upwards_vector_length_fps = me.acc_upwards_fps2*me.dt;
						me.raw_steer_signal_elev  = R2D*me.commanded_upwards_vector_length_fps/me.velocity_vector_length_fps;
					} elsif (me.apn == 0) {
						# PN (constant best at 3)
						# Generalized Proportional Navigation.
						me.toBody = math.cos(me.curr_deviation_e*D2R);#convert perpendicular LOS acc. to perpendicular body acc.
						if (me.toBody==0) me.toBody=0.00001;
						me.acc_upwards_fps2 = me.pro_constant*me.line_of_sight_rate_up_rps*math.abs(me.vert_closing_rate_fps)*me.noise;
						me.acc_upwards_fps2 /= me.toBody;
						me.velocity_vector_length_fps = me.clamp(me.old_speed_fps, 0.0001, 1000000);
						me.commanded_upwards_vector_length_fps = me.acc_upwards_fps2*me.dt;
						me.raw_steer_signal_elev  = R2D*me.commanded_upwards_vector_length_fps/me.velocity_vector_length_fps;
					} elsif (me.apn == -1) {
						# PN [invented during WWII by Luke Chia‐Liu Yuan]
						# Original Proportional navigation.
						# Rearranging the equations gives Pure proportional navigation, which show that this law
						# does not take missile alpha into account, and is therefore not very good in real life.
						me.radians_up_per_sec     = me.pro_constant*me.line_of_sight_rate_up_rps*me.noise;
						me.raw_steer_signal_elev  = me.dt*me.radians_up_per_sec*R2D;
					}

					# now compensate for the predicted gravity drop of attitude:
		            me.attitudePN = (math.atan2(-(me.speed_down_fps+g_fps * me.dt), me.speed_horizontal_fps ) - math.atan2(-me.speed_down_fps, me.speed_horizontal_fps )) * R2D;
		            me.gravComp = -me.attitudePN;
		            #printf("Gravity compensation %0.2f degs", me.gravComp);
		            me.raw_steer_signal_elev += me.gravComp;

					#printf("Proportional lead: %0.1f deg elev", -(me.curr_deviation_e-me.raw_steer_signal_elev));
				}
			}
			me.CRE_old_dt = me.dt;
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
		me.ground = geo.elevation(me.coord.lat(), me.coord.lon()) or 0;
		me.terrainImpact = 0;
		if(me.ground > me.coord.alt()) {
			me.event = "exploded";
			if(me.life_time < me.arming_time) {
				me.event = "landed disarmed";
				#thread.lock(mutexTimer);
				#append(AIM.timerQueue, [me,me.log,[me.typeLong~" landed disarmed."],0]);
				#thread.unlock(mutexTimer);
			}
			if (me.Tgt != nil and me.direct_dist_m == nil) {
				# maddog might go here
				me.Tgt = nil;
				#me.direct_dist_m = me.coord.direct_distance_to(me.Tgt.get_Coord());
			}
			if ((me.Tgt != nil and me.direct_dist_m != nil) or me.Tgt == nil) {
				me.terrainImpact = 1;
				#me.explode("Hit terrain.", me.coord, me.direct_dist_m, me.event);
				#return TRUE;
			}
		}

		if (me.Tgt != nil and me.t_coord != nil and me.guidance != "inertial") {
			# Maintain an array of the coordinates of the missile and the tgt in the last 3 frames.
			# (use xyz coord to avoid the strange behaviour of comparing geo coordinates).
			for (var i=me.crc_frames_look_back; i >= 0; i-=1){
				me.crc_coord[i]   = (i != 0) ? me.crc_coord[i-1]   : me.coord.xyz();
				me.crc_t_coord[i] = (i != 0) ? me.crc_t_coord[i-1] : me.t_coord.xyz();
				me.crc_range[i]   = (i != 0) ? me.crc_range[i-1]   : me.myMath.magnitudeVector(
																		 me.myMath.minus(me.crc_coord[0],
																						 me.crc_t_coord[0]));
			}

			if (me.crc_coord[1] == nil or me.crc_t_coord[1] == nil or me.crc_range[1] == nil) {
				if (me.terrainImpact) {
					me.coord.set_alt(me.ground);
					me.explode("Hit terrain.", me.coord, me.direct_dist_m, me.event);
					return TRUE;
				}
				return FALSE; # Wait for the buffer to fill at least once.
			}

			if (me.life_time > me.arming_time) {
				# Distance to target increase.
				if (me.crc_range[0] > me.crc_range[1] and me.crc_range[0] < 250) {
					# Compute the closest approach.
					me.subframeClosestRangeCoord();  # Provides `me.crc_closestRange` and `me.crc_missileCoord`.

					me.explode("Passed target.", me.crc_missileCoord, me.crc_closestRange);
					return TRUE;
				}
	            if (me.life_time > me.selfdestruct_time or (me.destruct_when_free == TRUE and me.free == TRUE)) {
					me.explode("Selfdestructed.", me.coord);
				    return TRUE;
				}
			}
			me.direct_dist_m = me.crc_range[0];
		} elsif (me.life_time > me.selfdestruct_time) {
			me.Tgt = nil; # make sure we dont in inertial mode with target go in and start checking distances.
			me.explode("Selfdestructed.", me.coord);
		    return TRUE;
		}
		if (me.terrainImpact) {
			me.coord.set_alt(me.ground);
			me.explode("Hit terrain.", me.coord, me.direct_dist_m, me.event);
			return TRUE;
		}
		return FALSE;
	},

	#! brief: Recursive function to compute the closest range in the past mfd frames.
	#! param fei: The frame to compute first (0: current frame, 1: previous frame, ...).
	#! param mfd: The maximum amount of frames available if needed.
	#! input me.crc_coord: The coordinates of the missile in the last frames.
	#! input me.crc_t_coord: The coordinates of the target in the last frames.
	#! output me.crc_missileCoord: The coordinates of the missile when it was the closest to the target in the mfd+1 last frames.
	#! output me.crc_closestRange: The range of the missile when it was the closest to the target in the mfd+1 last frames.
	subframeClosestRangeCoord : func(fei=0, mfd=nil) {
		# Handle default depth parameter (set it as me.crc_frames_look_back if default is needed).
		if (mfd == nil)
			mfd = me.crc_frames_look_back;

		# Prevent illegal parameter.
		if(mfd < 1)
			die("Argument exception: The mfd (Max Frames Depth) cannot be less than one.");
		if(fei < 0)
			die("Argument exception: The fei (Frames End Index) cannot be negative.");

		# Ensure the availability of the frame-end data.
		if(me.crc_coord[fei] == nil or me.crc_t_coord[fei] == nil)
			die("No coordinates available for the end of the frame.");

		# Indices for the coordinates at frame start (fsi) and frame end (fei);
		var fsi = fei + 1;

		# Buffers used for unprocessed result, set to the frame-end values in case of unavailable frame-start data;
		var missileCoord = me.crc_coord[fei];
		var targetCoord = me.crc_t_coord[fei];

		# Check for availability of the frame-start data
		if(me.crc_coord[fsi] != nil and me.crc_t_coord[fsi] != nil){
			# Get the origin coordinates and speed of the missile and it's target for the current frame.
			# The units are in m for distances and frames for time.
			var misCoord = me.crc_coord[fsi];
			var misSpeed = me.myMath.minus(me.crc_coord[fei], misCoord);
			var tgtCoord = me.crc_t_coord[fsi];
			var tgtSpeed = me.myMath.minus(me.crc_t_coord[fei], tgtCoord);

			# Compute when the closest distance happened in time.
			var t = call(func me.myMath.particleShortestDistTime(misCoord, misSpeed, tgtCoord, tgtSpeed), nil, var err = []);
			# If an error is thrown, this is probably due to a null differential speed.
			if (size(err)){
				t = 1;
				print(err[0]);
			}

			# If the time factor (in frames) is superior than 1, this mean that the missile is still closing.
			if (t > 1)
				t = 1; # Set it to 1 to prevent extrapolation (but it should still get closer).
			# If it is negative, the closest range happened at one of the previous frame:
			else if (t < 0)
				if (mfd > 1)  # If we can recursively compute the previous frame:
					return me.subframeClosestRangeCoord(fei+1, mfd-1);  # Return it's result instead, and stop here.
				else
					t = 0;  # Set it to 0 to prevent extrapolation.

			# Compute (interpolate) the position of the missile and it's target when their range is the closest.
			missileCoord = me.myMath.plus(misCoord, me.myMath.product(t, misSpeed));
			targetCoord  = me.myMath.plus(tgtCoord, me.myMath.product(t, tgtSpeed));
		}

		# Return the minimum distance between the missile and the tgt, and the position of the missile at that time.
		me.crc_closestRange = me.myMath.magnitudeVector(me.myMath.minus(targetCoord, missileCoord));
		me.crc_missileCoord = geo.Coord.new();
		me.crc_missileCoord.set_xyz(missileCoord[0], missileCoord[1], missileCoord[2]);
		me.crc_missileCoord.alt();# TODO: once fixed in FG this line is no longer needed.
	},

	log: func (str) {
		damage.damageLog.push(str);
	},

	notifyInFlight: func (lat,lon,alt,rdar,typeID,typ,unique,thrustOn,callsign, heading, pitch, speed, is_deleted=0) {
		## thrustON cannot be named 'thrust' as FG for some reason will then think its a function (probably fixed by the way call() now is used)
		var msg = notifications.ArmamentInFlightNotification.new("mfly", unique, is_deleted?damage.DESTROY:damage.MOVE, 21+typeID);
        if (lat != nil) {
        	msg.Position.set_latlon(lat,lon,alt);
        } else {
        	msg.Position.set_latlon(0,0,0);
        }
        msg.Flags = rdar;#bit #0
        if (thrustOn) {
        	msg.Flags = bits.set(msg.Flags, 1);#bit #1
        }
        msg.IsDistinct = !is_deleted;
        msg.RemoteCallsign = callsign;
        msg.UniqueIndex = ""~typeID~unique;
        msg.Pitch = pitch;
        msg.Heading = heading;
        msg.u_fps = speed;
        #msg.isValid();
        notifications.geoBridgedTransmitter.NotifyAll(msg);
#print("fox2.nas: transmit in flight");
#f14.debugRecipient.Receive(msg);
	},

	notifyCrater: func (lat,lon,alt,big,heading,static) {
		var uni = int(rand()*15000000);
		var msg = notifications.StaticNotification.new("stat", uni, 1, big);

        msg.Position.set_latlon(lat,lon,alt);
        msg.IsDistinct = 0;
        msg.Heading = heading;
        notifications.hitBridgedTransmitter.NotifyAll(msg);
#print("fox2.nas: transmit crater");
#f14.debugRecipient.Receive(msg);
		damage.statics["obj_"~uni] = [static, lat,lon,alt, heading,big];
	},

	notifyHit: func (RelativeAltitude, Distance, callsign, Bearing, reason, typeID, type, self) {
		var msg = notifications.ArmamentNotification.new("mhit", 4, 21+typeID);
        msg.RelativeAltitude = RelativeAltitude;
        msg.Bearing = Bearing;
        msg.Distance = Distance;
        msg.RemoteCallsign = callsign; # RJHTODO: maybe handle flares / chaff
        if (self) {
        	msg.Callsign = callsign;
        	msg.FromIncomingBridge = 1;
        	damage.damage_recipient.Receive(msg);
        }
        notifications.hitBridgedTransmitter.NotifyAll(msg);
        me.log(sprintf("You hit %s with %s at %.1f meters.",callsign, type, Distance));
#print("fox2.nas: transmit hit to ",callsign,"  reason:",reason);
#f14.debugRecipient.Receive(msg);
	},

	explode: func (reason, coordinates, range = nil, event = "exploded") {
		var hitGround = 0;
		if (reason == "Hit terrain.") {
			hitGround = 1;
		}
		if (me.lock_on_sun) {
			reason = "Locked onto sun.";
		} elsif (me.flareLock) {
			reason = "Locked onto flare.";
		} elsif (me.chaffLock) {
			reason = "Locked onto chaff.";
		}

		me.coord = coordinates;  # Set the current missile coordinates at the explosion point.

		if(getprop("payload/armament/msg")) {
			thread.lock(mutexTimer);
			append(AIM.timerQueue, [AIM, AIM.notifyInFlight, [me.coord.lat(), me.coord.lon(), me.coord.alt(),0,me.typeID,me.type,me.unique_id,0,"", me.hdg, me.pitch, 0, 0], -1]);
			thread.unlock(mutexTimer);
		}

		var wh_mass = (event == "exploded" and !me.inert) ? me.weight_whead_lbm : 0; #will report 0 mass if did not have time to arm

		thread.lock(mutexTimer);
		append(AIM.timerQueue, [me,impact_report,[coordinates, wh_mass, "munition", me.type, me.new_speed_fps*FT2M],0]);
		thread.unlock(mutexTimer);

		if (!me.inert) {
			var phrase = nil;
			var hitPrimaryTarget = 0;
			if (me.Tgt != nil and !me.Tgt.isVirtual()) {
				var tgtLabel = me.callsign;
				if(me.flareLock == TRUE)
					tgtLabel ~= "'s flare";
				elsif (me.chaffLock == TRUE)
					tgtLabel ~= "'s chaff";
				if (range != nil and range < me.reportDist) {
					phrase = sprintf(me.type ~ " " ~ event ~ ": %.1f meters from: " ~ tgtLabel, range);
					if (!me.flareLock and !me.chaffLock) {
						hitPrimaryTarget = 1;
					}
				} else {
					phrase = me.type ~ " missed " ~ me.callsign ~ ": " ~ reason;
				}
			} elsif (me.Tgt == nil) {
				phrase = sprintf(me.type ~ " " ~ event);
			}
			if (phrase != nil) {
				me.printStats("%s  time %.1f", phrase, me.life_time);
				if(getprop("payload/armament/msg") and hitPrimaryTarget and wh_mass > 0){
					thread.lock(mutexTimer);
					append(AIM.timerQueue, [AIM, AIM.notifyHit, [coordinates.alt() - me.t_coord.alt(),range,me.callsign,coordinates.course_to(me.t_coord),reason,me.typeID, me.typeLong, 0], -1]);
					thread.unlock(mutexTimer);
                } else {
	                thread.lock(mutexTimer);
	                append(AIM.timerQueue, [AIM, AIM.log, [phrase], 0]);
	                thread.unlock(mutexTimer);
	            }
			}
			if (me.multiHit and !me.multiExplosion(coordinates, event, wh_mass) and me.Tgt != nil and me.Tgt.isVirtual()) {
				phrase = sprintf(me.type~" "~event);
				me.printStats("%s  Reason: %s time %.1f", phrase, reason, me.life_time);
                thread.lock(mutexTimer);
                append(AIM.timerQueue, [AIM, AIM.log, [phrase], 0]);
                thread.unlock(mutexTimer);
			}
		}

		me.ai.getNode("valid", 1).setBoolValue(0);
		thread.lock(mutexTimer);
		append(AIM.timerQueue, [me, me.setModelRemoved, [], -1]);
		thread.unlock(mutexTimer);
		if (event == "exploded" and !me.inert and wh_mass > 0) {
			me.animate_explosion(hitGround);
			me.explodeSound = TRUE;
		} else {
			me.animate_dud();
			me.explodeSound = FALSE;
		}
		me.Tgt = nil;
	},

	multiExplosion: func (explode_coord, event, wh_mass) {
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

 				if(getprop("payload/armament/msg") and wh_mass > 0){
 					var cs = damage.processCallsign(me.testMe.get_Callsign());
 					var cc = me.testMe.get_Coord();
 					thread.lock(mutexTimer);
					append(AIM.timerQueue, [AIM, AIM.notifyHit, [explode_coord.alt() - cc.alt(),min_distance,cs,explode_coord.course_to(cc),"mhit1",me.typeID, me.typeLong,0], -1]);
					thread.unlock(mutexTimer);
				}

				me.sendout = 1;
			}
		}
		# Now check for hitting ourselves:
		var min_distance = geo.aircraft_position().direct_distance_to(explode_coord);
		if (min_distance < me.reportDist) {
			# hitting oneself :)
			var cs = damage.processCallsign(getprop("sim/multiplay/callsign"));
			var phrase = sprintf("%s %s: %.1f meters from: %s", me.type,event, min_distance, cs);# if we mention ourself then we need to explicit add ourself as author.
			me.printStats(phrase);
			if (wh_mass > 0) {
				thread.lock(mutexTimer);
				append(AIM.timerQueue, [AIM, AIM.notifyHit, [explode_coord.alt() - geo.aircraft_position().alt(),min_distance,cs,explode_coord.course_to(geo.aircraft_position()),"mhit2",me.typeID, me.typeLong, 1], -1]);
				thread.unlock(mutexTimer);
			}
			me.sendout = 1;
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
		#if (!start.is_defined()) print("start undefined:"); found the bug so these prints not needed anymore
		#if (!end.is_defined()) print("end undefined:");
		me.xx = (start.x()*(1-fraction)
			+end.x()*fraction);
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

	getContact: func {
		if (me.noCommonTarget) {
			return nil;
		}
		if (me.target_pnt and contactPoint != nil) {
			return contactPoint;
		} else {
			return contact;
		}
	},

	standby: func {
		# looping in standby mode
		if (deltaSec.getValue()==0) {
			settimer(func me.standby(), 0.5);
		}
		if(me.seam_support and me.uncage_auto) {
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
		if(me.seam_support and me.uncage_auto) {
			me.caged = TRUE;
		}
		if (me.status != MISSILE_STARTING) {
			me.standby();
			return;
		}
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
			me.detect_range_curr_nm = me.extrapolate(me.warm, 0, 1, me.cold_detect_range_nm, me.warm_detect_range_nm);
			me.detect_range_curr_nm *= me.seam_scan?0.65:1;#GR1F-16CJ-34-1-1 page 1-402
		} else {
			me.detect_range_curr_nm = (me.seam_scan?0.65:1)*me.max_fire_range_nm;#GR1F-16CJ-34-1-1 page 1-402
		}
	},

	checkForLock: func {
		# call this only before firing
		if (!(me.tagt.get_type() == AIR and me.tagt.get_Speed()<15) and ((me.guidance != "semi-radar" or me.is_painted(me.tagt) == TRUE) and (me.guidance !="laser" or me.is_laser_painted(me.tagt) == TRUE))
						and (me.guidance != "radiation" or me.is_radiating_aircraft(me.tagt) == TRUE)
					    and me.rng < me.max_fire_range_nm and me.rng > me.getCurrentMinFireRange(me.tagt) and me.FOV_check(OurHdg.getValue(),OurPitch.getValue(),me.total_horiz, me.total_elev, me.slave_to_radar or contactPoint==me.tagt?(me.guidance == "heat" or me.guidance == "vision"?math.min(me.max_seeker_dev, me.fcs_fov):me.fcs_fov):me.max_seeker_dev, vector.Math)
					    and (me.rng < me.detect_range_curr_nm or (me.guidance != "radar" and me.guidance != "semi-radar" and me.guidance != "heat" and me.guidance != "vision" and me.guidance != "heat" and me.guidance != "radiation"))
					    and (me.guidance != "heat" or (me.all_aspect == TRUE or me.rear_aspect(geo.aircraft_position(), me.tagt) == TRUE))
					    and me.checkForView()) {
			return TRUE;
		}
		#me.printSearch("Lock did fail %d %d %d %d %d %d %d %d %d",
		#							!(me.tagt.get_type() == AIR and me.tagt.get_Speed()<15),
		#							((me.guidance != "semi-radar" or me.is_painted(me.tagt) == TRUE) and (me.guidance !="laser" or me.is_laser_painted(me.tagt) == TRUE)),
		#							(me.guidance != "radiation" or me.is_radiating_aircraft(me.tagt) == TRUE),
		#							me.rng < me.max_fire_range_nm,
		#							me.rng > me.min_fire_range_nm,
		#							me.FOV_check(OurHdg.getValue(),OurPitch.getValue(),me.total_horiz, me.total_elev, me.slave_to_radar?math.min(me.max_seeker_dev, me.fcs_fov):me.max_seeker_dev, vector.Math),
		#							(me.rng < me.detect_range_curr_nm or (me.guidance != "radar" and me.guidance != "semi-radar" and me.guidance != "heat" and me.guidance != "vision" and me.guidance != "heat" and me.guidance != "radiation")),
		#							(me.guidance != "heat" or (me.all_aspect == TRUE or me.rear_aspect(geo.aircraft_position(), me.tagt) == TRUE)),
		#							me.checkForView());
		return FALSE;
	},

	checkForView: func {
		if (me.guidance != "gps" and me.guidance != "gps-altitude" and me.guidance != "inertial") {
			me.launchCoord = geo.aircraft_position();
			if (!me.radarOrigin) {
				me.geodPos = aircraftToCart({x:-me.radarX, y:me.radarY, z: -me.radarZ});
				me.launchCoord.set_xyz(me.geodPos.x, me.geodPos.y, me.geodPos.z);
			}

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

	checkForViewInFlight: func (tagt) {
		if (me.guidance != "gps" and me.guidance != "gps-altitude" and me.guidance != "inertial") {
			me.launchCoord = me.coord;
			me.potentialCoord = tagt.get_Coord();
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
	                or (me.slaveContact.get_type() == POINT and me.target_pnt == TRUE)
	                or (me.slaveContact.get_type() == MARINE and me.target_sea == TRUE))) {
			return TRUE;
		}
		#if(me.slaveContact != nil) printf("class failed %d %d %d",me.slaveContact.isValid() == TRUE,me.slaveContact.get_type() == AIR,me.target_air == TRUE);
		return FALSE;
	},

	newLock: func (tagt) {
		# for switching to new lock during flight.
		#reorder to gain performance
		me.newlockgained = 0;
		if (!tagt.isValid()) {
			me.printStatsDetails("Test: invalid contact. Rejected.");
			return 0;
		}
		me.printStatsDetails("Test starting on %s:",tagt.get_Callsign());
		me.newCoord           = tagt.get_Coord();
		if (me.coord.direct_distance_to(me.newCoord)*M2NM > me.detect_range_curr_nm) {
			me.printStatsDetails("Test: contact out of range. Rejected.");
			return 0;
		}
		me.newlockgained = me.checkForClassInFlight(tagt);
		if (!me.newlockgained) {me.printStatsDetails("Test: invalid type: %d. Rejected.",tagt.get_type());return 0;}
		if (me.guidance == "laser") {
			me.newlockgained = me.is_laser_painted(tagt);
			if (!me.newlockgained){me.printStatsDetails("Test: no laser lock. Rejected.");return 0;}
		} elsif (me.guidance == "semi-radar") {
			me.newlockgained = me.is_painted(tagt);
			if (!me.newlockgained) {me.printStatsDetails("Test: no radar paint. Rejected.");return 0;}
		} elsif (me.guidance == "radiation") {
			me.newlockgained = me.is_radiating_me(tagt);
			if (!me.newlockgained) {me.printStatsDetails("Test: not radiating me. Rejected.");return 0;}
		} elsif (me.guidance == "heat") {
			me.newlockgained = me.all_aspect == TRUE or me.rear_aspect(me.coord, tagt);
			if (!me.newlockgained) {me.printStatsDetails("Test: no view of heat source. Rejected.");return 0;}
		}
		if (me.guidance != "gps" and me.guidance != "inertial" and me.guidance != "gps-altitude") {
			me.new_elev_deg       = me.getPitch(me.coord, me.newCoord);
			me.new_course         = me.coord.course_to(me.newCoord);
			me.new_deviation_e    = me.new_elev_deg - me.pitch;
			me.new_deviation_h    = me.new_course - me.hdg;
			me.newlockgained      = me.FOV_check(me.hdg, me.pitch, me.new_deviation_h, me.new_deviation_e, me.max_seeker_dev, me.myMath);
			if (!me.newlockgained) {me.printStatsDetails("Test: not in FoV. Rejected.");return 0;}
		}
		me.newlockgained = me.checkForViewInFlight(tagt);
		if (!me.newlockgained) {me.printStatsDetails("Test: terrain obscurre contact. Rejected.");return 0;}
		else me.printStatsDetails("Test: contact approved.");
		return me.newlockgained;
	},

	checkForClassInFlight: func (tact) {
		# call this only after firing
		if(tact != nil and tact.isValid() == TRUE and
					(  (tact.get_type() == SURFACE and me.target_gnd == TRUE)
	                or (tact.get_type() == AIR and me.target_air == TRUE)
	                or (tact.get_type() == POINT and me.target_pnt == TRUE)
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
		} elsif ( me.status == MISSILE_STANDBY or me.status == MISSILE_STARTING) {
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
		if(me.seam_support and me.uncage_auto) {
			me.caged = TRUE;
		}
		me.coolingSyst();
		if (!me.caged) {
			me.slaveContacts = nil;
			if (size(me.contacts) == 0) {
				me.slaveContacts = [me.getContact()];
			} else {
				me.slaveContacts = me.contacts;
			}
			if (me.rosette_radius != 0 and me.guidance == "heat") {
				# Only here for backwards compat. Uncaged and untracking it will not do a pattern, it will be horizon stabilized (TODO).
				me.nutateSeeker(PATTERN_ROSETTE, me.command_dir_heading, me.command_dir_pitch, me.rosette_radius);
			} else {
				me.seeker_head_target = me.uncage_idle_heading+(rand()-0.5);
				me.seeker_elev_target = me.uncage_idle_pitch+(rand()-0.5);
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
						me.printSearch("uncaged-search ready for lock");

						me.convertGlobalToSeekerViewDirection(me.tagt.get_bearing(), me.tagt.getElevation(), OurHdg.getValue(), OurPitch.getValue(), OurRoll.getValue());
						me.testSeeker();
						if (me.inBeam) {
							me.printSearch("uncaged-search found a lock");
							me.goToLock();
							return;
						}
					}
				}
			}
			me.Tgt = nil;
			me.SwSoundVol.setDoubleValue(me.vol_search);
			me.SwSoundOnOff.setBoolValue(TRUE);
			settimer(func me.search(), 0.05);# this mode needs to be a bit faster.
			return;
		} elsif (me.slave_to_radar == TRUE) {
			me.slaveContact = nil;
			if (size(me.contacts) == 0) {
				me.slaveContact = me.getContact();
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
					me.convertGlobalToSeekerViewDirection(me.tagt.get_bearing(), me.tagt.getElevation(), OurHdg.getValue(), OurPitch.getValue(), OurRoll.getValue());
					if (me.seam_scan and me.guidance == "heat") {
						me.nutateSeeker(me.oldPattern?PATTERN_DOUBLE_D:PATTERN_CIRCLE, me.seeker_head_target, me.seeker_elev_target);
					} else {
						me.moveSeeker();
					}
					me.testSeeker();
					if (me.inBeam) {
						me.printSearch("rdr-slave-search found a lock");
						me.goToLock();
						return;
					}
				} else {
					# Radar locked, seekerhead nutates around a locked direction.
					me.convertGlobalToSeekerViewDirection(me.tagt.get_bearing(), me.tagt.getElevation(), OurHdg.getValue(), OurPitch.getValue(), OurRoll.getValue());
					if (me.seam_scan and me.guidance == "heat") {
						me.nutateSeeker(me.oldPattern?PATTERN_DOUBLE_D:PATTERN_CIRCLE, me.seeker_head_target, me.seeker_elev_target);
					} else {
						me.moveSeeker();
					}
					if (DEBUG_SEARCH) {
						# air target has speed
						# fox1 is painted
						# in range (max)
						# in range (min)
						# FOV
						# in range (detect)
						# Line of sight
						me.printSearch("Lock failed %d %d %d %d %d %d %d",
							!(me.tagt.get_type() == AIR and me.tagt.get_Speed()<15),
							(me.guidance != "semi-radar" or me.is_painted(me.tagt) == TRUE),
							me.rng < me.max_fire_range_nm,
							me.rng > me.getCurrentMinFireRange(me.tagt),
							me.FOV_check(OurHdg.getValue(),OurPitch.getValue(),me.total_horiz, me.total_elev, me.fcs_fov, vector.Math),
							me.rng < me.detect_range_curr_nm,
							me.checkForView());
					}
				}
			} else {
				# Radar slaved, no valid designation, seekerhead jitters around a idle direction.
				me.seeker_elev_target = me.command_dir_pitch+(rand()-0.5)*(me.seam_scan and me.guidance == "heat");
				me.seeker_head_target = me.command_dir_heading+(rand()-0.5)*(me.seam_scan and me.guidance == "heat");
				me.moveSeeker();
				if (DEBUG_SEARCH and me.slaveContact != nil) {
					var tpe = me.slaveContact.get_type();
					if (tpe==AIR) tpe="A";
					elsif (tpe==SURFACE) tpe="G";
					elsif (tpe==MARINE) tpe="M";
					elsif (tpe==POINT) tpe="P";
					else tpe ="?";
					me.printSearch("Class check failed: %s (weapon: %s)", tpe, me.class);
				}
			}
		} elsif (!me.slave_to_radar) {
			me.slaveContacts = nil;
			if (size(me.contacts) == 0) {
				me.slaveContacts = [me.getContact()];
			} else {
				me.slaveContacts = me.contacts;
			}
			if (!me.seam_scan or me.guidance != "heat") {
				me.seeker_elev_target = me.command_dir_pitch;
				me.seeker_head_target = me.command_dir_heading;
				me.moveSeeker();
			} else {
				me.nutateSeeker(me.oldPattern?PATTERN_DOUBLE_D:PATTERN_CIRCLE, me.command_dir_heading, me.command_dir_pitch);
			}
			foreach(me.slaveContact ; me.slaveContacts) {
				if (me.checkForClass()) {
					me.tagt = me.slaveContact;
					me.rng = me.tagt.get_range();

					# Check if in range and in the seeker FOV.
					me.total_elev  = deviation_normdeg(OurPitch.getValue(), me.tagt.getElevation()); # deg.
					me.total_horiz = deviation_normdeg(OurHdg.getValue(), me.tagt.get_bearing());    # deg.
					if (me.checkForLock()) {
						me.printSearch("bore/dir-search ready for lock");
						me.convertGlobalToSeekerViewDirection(me.tagt.get_bearing(), me.tagt.getElevation(), OurHdg.getValue(), OurPitch.getValue(), OurRoll.getValue());
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
		settimer(func me.search(), 0.05);
	},

	goToLock: func {
		me.status = MISSILE_LOCK;
		me.SwSoundOnOff.setBoolValue(TRUE);
		me.SwSoundVol.setDoubleValue(me.vol_track);

		me.Tgt = me.tagt;

        me.callsign = damage.processCallsign(me.Tgt.get_Callsign());

		settimer(func me.update_lock(), 0.1);
	},

	convertGlobalToSeekerViewDirection: func  (bearing, elevation, heading, pitch, roll) {
		me.target_x = math.cos(bearing*D2R)*math.cos(elevation*D2R);
        me.target_y = -math.sin(bearing*D2R)*math.cos(elevation*D2R);
        me.target_z = math.sin(elevation*D2R);
        me.target_vector = [me.target_x,me.target_y,me.target_z];
		me.rollLaunchvehicle  = vector.Math.rollMatrix(-roll);
        me.pitchLaunchvehicle = vector.Math.pitchMatrix(-pitch);
        me.yawLaunchvehicle   = vector.Math.yawMatrix(heading);
        me.rotation = vector.Math.multiplyMatrices(me.rollLaunchvehicle, vector.Math.multiplyMatrices(me.pitchLaunchvehicle, me.yawLaunchvehicle));
        me.target_vector_from_seekers_view = vector.Math.multiplyMatrixWithVector(me.rotation, me.target_vector);
        me.angles = vector.Math.cartesianToEuler(me.target_vector_from_seekers_view);

        me.seeker_head_target = me.angles[0]==nil?0:geo.normdeg180(me.angles[0]);
        me.seeker_elev_target = me.angles[1];
	},

	nutateSeeker: func (pattern, heading, pitch, radius = nil) {
		me.pattern_elapsed = systime();

		if (radius == nil and pattern == PATTERN_DOUBLE_D) radius = me.beam_width_deg;
		elsif (radius == nil and pattern == PATTERN_CIRCLE) radius = me.beam_width_deg*0.40;
		elsif (radius == nil and pattern == PATTERN_ROSETTE) radius = me.beam_width_deg*2.00;

		me.target_x = math.cos(heading*D2R)*math.cos(pitch*D2R);
        me.target_y = -math.sin(heading*D2R)*math.cos(pitch*D2R);
        me.target_z = math.sin(pitch*D2R);

        me.seeker_reset = [1,0,0];

        me.meridian_factor = math.abs(pitch)>85?1:math.cos(pitch*D2R);

		if (math.sqrt(math.pow((me.seeker_head-heading)*me.meridian_factor,2)+math.pow(me.seeker_elev-pitch,2))>radius*1.2) {
			me.seeker_head_target = heading;
			me.seeker_elev_target = pitch;
			me.moveSeeker();
		} elsif (vector.Math.angleBetweenVectors(me.seeker_reset, [me.target_x,me.target_y,me.target_z]) < (me.slave_to_radar?math.min(me.max_seeker_dev, me.fcs_fov):me.max_seeker_dev)) {
			# TODO: check for seeker FOV of pattern also instead of just center of pattern.
			# TODO: use proper high elevation math here too instead of feeble meridian factor.
			if (pattern == PATTERN_ROSETTE) {
				# rosette nutation
				me.freq1 = me.angular_speed*0.23/radius;
				me.freq2 = me.f1*0.4;
				me.seeker_head = 0.5*radius*(math.cos(me.freq1*math.pi*2*me.pattern_elapsed)+math.cos(me.freq2*math.pi*2*me.pattern_elapsed))/me.meridian_factor+heading;
				me.seeker_elev = 0.5*radius*(math.sin(me.freq1*math.pi*2*me.pattern_elapsed)-math.sin(me.freq2*math.pi*2*me.pattern_elapsed))+pitch;
			} elsif (pattern == PATTERN_CIRCLE) {
				# Standard nutation (CCW)
				me.freq = math.min(me.angular_speed/(2*math.pi*radius), 1.0);# source for 1 hz: NAVAIR 01 245FDB-1T
				me.seeker_head = radius*math.cos(me.freq*math.pi*2*me.pattern_elapsed)/me.meridian_factor+heading;
				me.seeker_elev =-radius*math.sin(me.freq*math.pi*2*me.pattern_elapsed)+pitch;
			} elsif (pattern == PATTERN_DOUBLE_D) {
				# Is used by older AIM-9G/AIM-9H. 4 hz. 2.5 deg radius.
				me.freq = 4.0;
				me.doubleDmod = math.mod(me.pattern_elapsed,4);
				if (me.doubleDmod >= 0 and me.doubleDmod < 1) {
					me.seeker_head = radius*math.cos(math.pi*me.doubleDmod)/me.meridian_factor+heading;
					me.seeker_elev =-radius*math.sin(math.pi*me.doubleDmod)+pitch;
				} elsif (me.doubleDmod >= 1 and me.doubleDmod < 2) {
					me.seeker_head = (2*radius*(me.doubleDmod-1)-radius)/me.meridian_factor+heading;
					me.seeker_elev = pitch;
				} elsif (me.doubleDmod >= 2 and me.doubleDmod < 3) {
					me.seeker_head = radius*math.cos(math.pi*(me.doubleDmod-2))/me.meridian_factor+heading;
					me.seeker_elev = radius*math.sin(math.pi*(me.doubleDmod-2))+pitch;
				} elsif (me.doubleDmod >= 3) {
					me.seeker_head = (2*radius*(me.doubleDmod-3)-radius)/me.meridian_factor+heading;
					me.seeker_elev = pitch;
				}
			}
		}
		me.computeSeekerPos();
	},

	moveSeeker: func {
		# Build unit vector components for seeker and target location in aircraft frame:
		me.target_x = math.cos(me.seeker_head_target*D2R)*math.cos(me.seeker_elev_target*D2R);
        me.target_y = -math.sin(me.seeker_head_target*D2R)*math.cos(me.seeker_elev_target*D2R);
        me.target_z = math.sin(me.seeker_elev_target*D2R);

        me.seeker_reset = [1,0,0];

		if (me.guidance != "heat" and me.guidance != "vision") {
			me.new_seeker_deviation = vector.Math.angleBetweenVectors(me.seeker_reset, [me.target_x,me.target_y,me.target_z]);
			if (me.new_seeker_deviation < (me.slave_to_radar?me.fcs_fov:me.max_seeker_dev)) {
				me.seeker_elev = me.seeker_elev_target;
				me.seeker_head = me.seeker_head_target;
			}
			me.computeSeekerPos();
			return;
		}
		me.seeker_elapsed = systime();
		if (me.seeker_last_time != 0) {
			me.seeker_time = me.seeker_elapsed - me.seeker_last_time;
			me.seeker_max_move = me.seeker_time*me.angular_speed;

			# Build unit vector components for seeker and target location in aircraft frame:
		    me.seeker_x = math.cos(me.seeker_head*D2R)*math.cos(me.seeker_elev*D2R);
	        me.seeker_y = -math.sin(me.seeker_head*D2R)*math.cos(me.seeker_elev*D2R);
	        me.seeker_z = math.sin(me.seeker_elev*D2R);

	        me.ideal_seeker_deviation = vector.Math.angleBetweenVectors([me.seeker_x,me.seeker_y,me.seeker_z],[me.target_x,me.target_y,me.target_z]);
	        me.ideal_total_seeker_deviation = vector.Math.angleBetweenVectors(me.seeker_reset, [me.target_x,me.target_y,me.target_z]);

	        if (me.ideal_seeker_deviation > me.seeker_max_move) {
				me.new_seeker_vector = vector.Math.rotateVectorTowardsVector([me.seeker_x,me.seeker_y,me.seeker_z],[me.target_x,me.target_y,me.target_z],me.seeker_max_move);
				me.new_seeker_deviation = vector.Math.angleBetweenVectors(me.seeker_reset, me.new_seeker_vector);

				if (me.new_seeker_deviation < me.max_seeker_dev) {
					me.new_seeker_pos = vector.Math.cartesianToEuler(me.new_seeker_vector);
					me.seeker_head = me.new_seeker_pos[0]==nil?0:geo.normdeg180(me.new_seeker_pos[0]);
					me.seeker_elev = me.new_seeker_pos[1];
				}
			} elsif (me.ideal_total_seeker_deviation < me.max_seeker_dev) {
				me.seeker_elev = me.seeker_elev_target;
				me.seeker_head = me.seeker_head_target;
			}
		}
		me.seeker_last_time = me.seeker_elapsed;
		me.computeSeekerPos();
	},

	testSeeker: func {
		me.inBeam = FALSE;

		# Build unit vector components for seeker and target location in aircraft frame:
		me.target_x = math.cos(me.seeker_head_target*D2R)*math.cos(me.seeker_elev_target*D2R);
        me.target_y = -math.sin(me.seeker_head_target*D2R)*math.cos(me.seeker_elev_target*D2R);
        me.target_z = math.sin(me.seeker_elev_target*D2R);

        me.seeker_x = math.cos(me.seeker_head*D2R)*math.cos(me.seeker_elev*D2R);
        me.seeker_y = -math.sin(me.seeker_head*D2R)*math.cos(me.seeker_elev*D2R);
        me.seeker_z = math.sin(me.seeker_elev*D2R);


		# we measure the geodesic angle between where seeker is pointing and where the target is.
		me.target_deviation = vector.Math.angleBetweenVectors([me.target_x,me.target_y,me.target_z],[me.seeker_x,me.seeker_y,me.seeker_z]);

		if (me.target_deviation < me.beam_width_deg) {
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
		} elsif ( me.status == MISSILE_STANDBY or me.status == MISSILE_STARTING) {
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
		} elsif (me.slave_to_radar and me.caged and me.getContact() != me.Tgt and !me.noCommonTarget) {
			me.printSearch("target switch");
			me.return_to_search();
			return;
		}
		me.printSearch("lock");
		# Time interval since lock time or last track loop.
		#if (me.status == MISSILE_LOCK) {
			# Status = locked. Get target position relative to our aircraft.

		#}

		#me.time = props.globals.getNode("/sim/time/elapsed-sec", 1).getValue();

		if(me.seam_support and me.uncage_auto) {
			me.caged = FALSE;
		}
		me.coolingSyst();
		me.computeSeekerPos();
		if (me.status != MISSILE_STANDBY ) {#TODO: should this also check for starting up?
			me.in_view = me.check_t_in_fov();

			if (me.in_view == FALSE) {
				me.printSearch("out of view");
				me.return_to_search();
				return;
			}

			if (!me.caged or me.slave_to_radar) {
				me.convertGlobalToSeekerViewDirection(me.Tgt.get_bearing(), me.Tgt.getElevation(), OurHdg.getValue(), OurPitch.getValue(), OurRoll.getValue());
				# Notice: seeker_xxxx_target is used both for denoting where seeker should move towards and where the target is. In this case its both:
				me.moveSeeker();
			} elsif (!me.slave_to_radar) {
				if (me.seam_scan and me.guidance == "heat") {
					me.nutateSeeker(PATTERN_CIRCLE, me.command_dir_heading, me.command_dir_pitch);
				} else {
					me.seeker_elev_target = me.command_dir_pitch;
					me.seeker_head_target = me.command_dir_heading;
					# Notice: seeker_xxxx_target is used both for denoting where seeker should move towards and where the target is. In this case its the former:
					me.moveSeeker();
				}
			}

			# Notice: seeker_xxxx_target is used both for denoting where seeker should move towards and where the target is. In this case its the latter:
			me.convertGlobalToSeekerViewDirection(me.Tgt.get_bearing(), me.Tgt.getElevation(), OurHdg.getValue(), OurPitch.getValue(), OurRoll.getValue());
			me.testSeeker();
			if (!me.inBeam or (me.guidance == "semi-radar" and !me.is_painted(me.Tgt))) {
				me.printSearch("out of beam or no beam for fox 1");
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
				me.slaveContact = me.getContact();
			} else {
				me.slaveContact = me.contacts[0];
			}
			if (me.slave_to_radar and (me.slaveContact == nil or (me.slaveContact.getUnique() != nil and me.Tgt.getUnique() != nil and me.slaveContact.getUnique() != me.Tgt.getUnique()))) {
				me.printSearch("oops ");
				me.return_to_search();
				return;
			}

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

	FOV_check: func (meHeading, mePitch, deviation_hori, deviation_elev, fov_radius, vect) {
		# we measure the geodesic angle between current attitude and the attitude to target. We pass vector math since this method is called both during multi-threading and not.
		me.meVector = vect.eulerToCartesian3X(-meHeading, mePitch, 0);
		me.itVector = vect.eulerToCartesian3X(-(meHeading+deviation_hori), mePitch+deviation_elev, 0);
		me.fov_radial = vect.angleBetweenVectors(me.meVector, me.itVector);
		#me.fov_radial = math.sqrt(math.pow(deviation_hori,2)+math.pow(deviation_elev,2));
		if (me.fov_radial <= fov_radius) {
			return TRUE;
		}
		# out of FOV
		#if (me.status==MISSILE_FLYING) printf("1: %.1f out of %.1f, deviation %.1f, %.1f", me.fov_radial, fov_radius, deviation_hori, deviation_elev);
		return FALSE;
	},

	FOV_check_norm: func (meHeading, mePitch, deviation_hori, deviation_elev, fov_radius,vect) {
		# we measure the geodesic angle between current attitude and the attitude to target.
		me.meVector = vect.eulerToCartesian3X(-meHeading, mePitch, 0);
		me.itVector = vect.eulerToCartesian3X(-(meHeading+deviation_hori), mePitch+deviation_elev, 0);
		me.fov_radial = vect.angleBetweenVectors(me.meVector, me.itVector);
		#me.fov_radial = math.sqrt(math.pow(deviation_hori,2)+math.pow(deviation_elev,2));
		if (fov_radius == 0) return -1;
		#if (me.status==MISSILE_FLYING) printf("2: %.1f out of %.1f, deviation %.1f, %.1f", me.fov_radial, fov_radius, deviation_hori, deviation_elev);
		return me.fov_radial/fov_radius;
	},

	check_t_in_fov: func {
		# called only before firing
		me.total_elev  = deviation_normdeg(OurPitch.getValue(), me.Tgt.getElevation()); # deg.
		me.total_horiz = deviation_normdeg(OurHdg.getValue(), me.Tgt.get_bearing());    # deg.
		# Check if in range and in the seeker FOV.
		if (me.FOV_check(OurHdg.getValue(),OurPitch.getValue(),me.total_horiz, me.total_elev, me.slave_to_radar?(me.guidance == "heat" or me.guidance == "vision"?math.min(me.max_seeker_dev, me.fcs_fov):me.fcs_fov):me.max_seeker_dev, vector.Math) and me.Tgt.get_range() < me.max_fire_range_nm and me.Tgt.get_range() > me.getCurrentMinFireRange(me.Tgt)
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

		var explode_water_path = path_base~"explode-water-id-" ~ me.ID;
		me.explode_water_prop = props.globals.initNode( explode_water_path, FALSE, "BOOL", TRUE);

		var explode_angle_path = path_base~"explode-angle";
		me.explode_angle_prop = props.globals.initNode( explode_angle_path, 0.0, "DOUBLE", TRUE);

		var explode_sound_path = "payload/armament/flags/explode-sound-on-" ~ me.ID;;
		me.explode_sound_prop = props.globals.initNode( explode_sound_path, FALSE, "BOOL", TRUE);

		var explode_sound_vol_path = "payload/armament/flags/explode-sound-vol-" ~ me.ID;;
		me.explode_sound_vol_prop = props.globals.initNode( explode_sound_vol_path, 0, "DOUBLE", TRUE);

		var deploy_path = path_base~"deploy-id-" ~ me.ID;
		me.deploy_prop = props.globals.initNode(deploy_path, 0, "DOUBLE", TRUE);
	},

	animate_explosion: func (hitGround) {
		#
		# a last position update to where the explosion happened:
		#
		me.latN.setDoubleValue(me.coord.lat());
		me.lonN.setDoubleValue(me.coord.lon());
		me.altN.setDoubleValue(me.coord.alt()*M2FT);
		me.pitchN.setDoubleValue(0);# this will make explosions from cluster bombs (like M90) align to ground 'sorta'.
		me.rollN.setDoubleValue(0);# this will make explosions from cluster bombs (like M90) align to ground 'sorta'.
		me.msl_prop.setBoolValue(FALSE);
		me.smoke_prop.setBoolValue(FALSE);
		var info = geodinfo(me.coord.lat(), me.coord.lon());

		if (hitGround) {
			if (info == nil) {
				me.explode_water_prop.setBoolValue(FALSE);
			} elsif (info[1] == nil) {
				#print ("Building hit!");
			} elsif (info[1].solid == 0) {
			 	me.explode_water_prop.setBoolValue(TRUE);
			} else {
				me.explode_water_prop.setBoolValue(FALSE);
			}
		} else {
			me.explode_water_prop.setBoolValue(FALSE);
		}

		#print (me.typeShort);

		me.explode_prop.setBoolValue(TRUE);
		me.explode_angle_prop.setDoubleValue((rand() - 0.5) * 50);
		thread.lock(mutexTimer);
		append(AIM.timerQueue, [me, func me.explode_prop.setBoolValue(FALSE), [], 0.5]);
		append(AIM.timerQueue, [me, func me.explode_smoke_prop.setBoolValue(TRUE), [], 0.5]);
		append(AIM.timerQueue, [me, func {me.explode_smoke_prop.setBoolValue(FALSE);if (me.first == TRUE and size(keys(AIM.flying))>1) {me.resetFirst();}}, [], 3]);
		thread.unlock(mutexTimer);
		if (info == nil or !hitGround or getprop("payload/armament/enable-craters") == nil or !getprop("payload/armament/enable-craters")) {return;};
		thread.lock(mutexTimer);
		append(AIM.timerQueue, [me, func {
		 	if (info[1] == nil) {
				#print ("Building hit..smoking");
		       	var static = geo.put_model(getprop("payload/armament/models") ~ "bomb_hit_smoke.xml", me.coord.lat(), me.coord.lon());
		       	if(getprop("payload/armament/msg") and info[0] != nil) {
		       		thread.lock(mutexTimer);
					append(AIM.timerQueue, [AIM, AIM.notifyCrater, [me.coord.lat(), me.coord.lon(), info[0], 2, 0, static], 0]);
					thread.unlock(mutexTimer);
				}
		    } else if ((info[1] != nil) and (info[1].solid == 1)) {
		        var crater_model = "";
		        var siz = -1;
		        if (me.weight_whead_lbm < 850 and (me.target_sea or me.target_gnd)) {
		          	crater_model = getprop("payload/armament/models") ~ "crater_small.xml";
		          	siz = 0;
					#print("small crater");
		        } elsif (me.target_sea or me.target_gnd) {
					#print("big crater");
					siz = 1;
		          	crater_model = getprop("payload/armament/models") ~ "crater_big.xml";
		        }

		       	if (crater_model != "" and me.weight_whead_lbm > 150) {
		            var static = geo.put_model(crater_model, me.coord.lat(), me.coord.lon());
					#print("put crater");
					if(getprop("payload/armament/msg") and info[0] != nil) {
						thread.lock(mutexTimer);
						append(AIM.timerQueue, [AIM, AIM.notifyCrater, [me.coord.lat(), me.coord.lon(),info[0],siz, 0, static], 0]);
						thread.unlock(mutexTimer);
					}
		        }
		    }
        }, [], 0.5]);
		thread.unlock(mutexTimer);
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
		if (me.elapsed_last_snd != 0) {
			dt = (elapsed - me.elapsed_last_snd) * speedUp.getValue();
		}
		me.elapsed_last_snd = elapsed;

		me.ac = geo.aircraft_position();
		var distance = me.coord.direct_distance_to(me.ac);

		me.sndDistance = me.sndDistance + (me.sndSpeed * dt) * FT2M;
		if(me.sndDistance > distance) {
			var volume = math.pow(math.e,(-.00025*(distance-1000)));
			me.printStats(me.type~": Explosion heard "~distance~"m vol:"~volume);
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

	steering_speed_G_old: func(meHeading, mePitch,steering_e_deg, steering_h_deg, s_fps, dt) {
		# Get G number from steering (e, h) in deg, speed in ft/s.
		me.meVector = me.myMath.eulerToCartesian3X(-meHeading, mePitch, 0);
		me.itVector = me.myMath.eulerToCartesian3X(-(meHeading+steering_h_deg), mePitch+steering_e_deg, 0);
		me.steer_deg = me.myMath.angleBetweenVectors(me.meVector, me.itVector);

		# next speed vector
		me.vector_next_x = math.cos(me.steer_deg*D2R)*s_fps;
		me.vector_next_y = math.sin(me.steer_deg*D2R)*s_fps;

		# present speed vector
		me.vector_now_x = s_fps;
		me.vector_now_y = 0;

		# Delta velocity: subtract the vectors from each other and get the magnitude
		me.dv = me.myMath.minus([me.vector_now_x,me.vector_now_y,0],[me.vector_next_x,me.vector_next_y,0]);
		me.dv = me.myMath.magnitudeVector(me.dv);

		# calculate g-force
		# dv/dt=a
		me.g = (me.dv/dt) / g_fps;

		return me.g;
	},

	steering_speed_G: func(meHeading, mePitch, steering_e_deg, steering_h_deg, s_fps, dt) {
		# Get G number from steering (e, h) in deg, speed in ft/s.
		me.meVector = me.myMath.eulerToCartesian3X(-meHeading, mePitch, 0);
		me.meVectorN= me.myMath.normalize(me.meVector);
		me.meVector = me.myMath.product(s_fps, me.meVectorN);#velocity vector now
		me.itVector = me.myMath.eulerToCartesian3X(-(meHeading+steering_h_deg), mePitch+steering_e_deg, 0);
		me.itVector = me.myMath.normalize(me.itVector);
		me.itVector = me.myMath.product(s_fps, me.itVector);#velocity vector if doing that steering

		# Delta lateral velocity
		me.dv = me.myMath.minus(me.itVector, me.meVector);
		me.dv = me.myMath.projVectorOnPlane(me.meVectorN, me.dv);
		me.dv = me.myMath.magnitudeVector(me.dv);

		# calculate g-force
		# dv/dt=a
		me.g = (me.dv/dt) / g_fps;

		return me.g;
	},

	overload_limiter: func(meHeading, mePitch, steering_e_deg, steering_h_deg, s_fps, dt, gMax) {
    	# The missile desires to rotate a certain amount
    	# This function will limit that steering to prevent it from exceeding the max G it should be able to do at this air density

    	if (gMax == 0 or (steering_e_deg == 0 and steering_h_deg == 0)) {
    		return [0,0];
    	}

		# Get G number from steering (e, h) in deg, speed in ft/s.
		me.meVector = me.myMath.eulerToCartesian3X(-meHeading, mePitch, 0);
		me.meVectorN= me.myMath.normalize(me.meVector);
		me.meVector = me.myMath.product(s_fps, me.meVectorN);#velocity vector now
		me.itVector = me.myMath.eulerToCartesian3X(-(meHeading+steering_h_deg), mePitch+steering_e_deg, 0);
		me.itVectorN= me.myMath.normalize(me.itVector);
		me.itVector = me.myMath.product(s_fps, me.itVectorN);#velocity vector if doing that steering

		# Delta lateral velocity
		me.dvAcc = me.myMath.minus(me.itVector, me.meVector);
		me.dv = me.myMath.projVectorOnPlane(me.meVectorN, me.dvAcc);
		me.dv = me.myMath.magnitudeVector(me.dv);

		# calculate g-force
		# dv/dt=a
		me.g_load = (me.dv/dt) / g_fps;

		me.exceed_g = gMax/me.g_load;

		if (me.exceed_g >= 1) {
			return [steering_h_deg, steering_e_deg];
		}

		# Now do something that works okay for small desired steerings, but fails for big steerings. Hence the 0.9 factor.
		me.dvAcc9 = me.myMath.product(me.exceed_g*0.9, me.dvAcc);
		me.itVector = me.myMath.plus(me.dvAcc9, me.meVector);

		me.euler = me.myMath.cartesianToEuler(me.itVector);

		if (me.euler[0] == nil) {
			me.euler[0] = meHeading;
		}

		return [geo.normdeg180(me.euler[0]-meHeading), me.euler[1]-mePitch];
	},

    max_G_Rotation_old: func(steering_e_deg, steering_h_deg, s_fps, dt, gMax) {
    	# The missile desires to rotate a certain amount
    	# This function will limit that steering to prevent it from exceeding the max G it should be able to do at this air density
		me.guess = 1;
		me.coef = 1;
		me.lastgoodguess = 1;

		for(var i=1;i<25;i+=1){
			me.coef = me.coef/2;
			me.new_g = me.steering_speed_G(me.hdg, me.pitch, steering_e_deg*me.guess, steering_h_deg*me.guess, s_fps, dt);
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
			me.p = 473.1 * math.pow( math.e , 1.73 - (0.000048 * altitude) );
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
			thread.lock(mutexTimer);
			append(AIM.timerQueue, [nil, printff, arg, -1]);
			thread.unlock(mutexTimer);
		}
	},

	printFlightDetails: func {
		if (DEBUG_FLIGHT_DETAILS) {
			thread.lock(mutexTimer);
			append(AIM.timerQueue, [nil, printff, arg, -1]);
			thread.unlock(mutexTimer);
		}
	},

	printStats: func {
		if (DEBUG_STATS) {
			thread.lock(mutexTimer);
			append(AIM.timerQueue, [nil, printff, arg, -1]);
			thread.unlock(mutexTimer);
		}
	},

	printStatsDetails: func {
		if (DEBUG_STATS_DETAILS) {
			thread.lock(mutexTimer);
			append(AIM.timerQueue, [nil, printff, arg, -1]);
			thread.unlock(mutexTimer);
		}
	},

	printGuide: func {
		if (DEBUG_GUIDANCE) {
			thread.lock(mutexTimer);
			append(AIM.timerQueue, [nil, printff, arg, -1]);
			thread.unlock(mutexTimer);
		}
	},

	printGuideDetails: func {
		if (DEBUG_GUIDANCE_DETAILS) {
			thread.lock(mutexTimer);
			append(AIM.timerQueue, [nil, printff, arg, -1]);
			thread.unlock(mutexTimer);
		}
	},

	printCode: func {
		if (DEBUG_CODE) {
			thread.lock(mutexTimer);
			append(AIM.timerQueue, [nil, printff, arg, -1]);
			thread.unlock(mutexTimer);
		}
	},

	printSearch: func {
		if (DEBUG_SEARCH) {
			thread.lock(mutexTimer);
			append(AIM.timerQueue, [nil, printff, arg, -1]);
			thread.unlock(mutexTimer);
		}
	},

	printAlways: func {
		thread.lock(mutexTimer);
		append(AIM.timerQueue, [nil, printff, arg, -1]);
		thread.unlock(mutexTimer);
	},

	timerLoop: func {
		thread.lock(mutexTimer);
		AIM.tq = AIM.timerQueue;
		AIM.timerQueue = [];
		thread.unlock(mutexTimer);
		foreach(var cmd; AIM.tq) {
			AIM.timerCall(cmd);
		}
	},

	timerCall: func (cmd) {
		if (cmd != nil) {
			if (cmd[3] == -1) {
				call(cmd[1], cmd[2], cmd[0], nil, var err = []);
				debug.printerror(err);
			} else {
				var code = "timer_"~rand();
				var tr = maketimer(cmd[3], cmd[0], func {call(cmd[1], cmd[2], cmd[0], nil, var err = []);debug.printerror(err);delete(AIM.timers, code);});
				tr.singleShot = 1;
				tr.start();
				AIM.timers[code] = tr;
			}
		}
	},

	pop_front: func (vector) {
		if (size(vector)==0) return [nil, vector];
		var new_vector = [];
		var first = 1;
		foreach (i;vector) {
			if (first) continue;
			append(new_vector, i);
		}
		return [vector[0],new_vector];
	},

	timers: {},

	timerQueue: [],

	active: {},
	flying: {},

	setETA: func (eta, prev = -1) {
		# Class method
		thread.lock(mutexETA);
		if (eta == -1 and prev == AIM.lowestETA) {
			AIM.lowestETA = nil;
		} elsif (eta == nil) {
			AIM.lowestETA = nil;
		} elsif (AIM.lowestETA == nil or eta < AIM.lowestETA and eta < 1800) {
			AIM.lowestETA = eta;
		}
		thread.unlock(mutexETA);
	},
	getETA: func {
		# Class method
		var retur = 0;
		thread.lock(mutexETA);
		retur = AIM.lowestETA;
		thread.unlock(mutexETA);
		return retur;
	},

	setModelAdded: func {
		setprop("ai/models/model-added", me.ai.getPath());
	},

	setModelRemoved: func {
		setprop("ai/models/model-removed", me.ai.getPath());
	},
};
var backtrace = func(desc = nil, dump_vars = 1, skip_level = 0, levels = 3) {
    var d = (desc == nil) ? "" : " '" ~ desc ~ "'";
    print("");
    print(_title("### backtrace" ~ d ~ " ###"));
    skip_level += 1;
    for (var i = skip_level; i<levels; i += 1) {
        if ((var v = caller(i)) == nil) return;
        print(_section(sprintf("#%-2d called from %s, line %s:", i - skip_level, v[2], v[3])));
        if (dump_vars) dump(v[0]);
    }
}

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
	impact.getNode("mass-slug", 1).setDoubleValue(mass * LBM2SLUGS);
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
	if (math.sin(dev_rad) == 0 or math.sin(elev_rad) == 0) return [0,0,0];
    if (math.cos(dev_rad) == 0 or math.cos(elev_rad) == 0) return [0,20,1];
	var clamped = 0;
	# Deviation length on the HUD (at level flight),
	# 0.6686m = distance eye <-> virtual HUD screen.
	var h_dev = eye_hud_m / ( math.sin(dev_rad) / math.cos(dev_rad) );
	var v_dev = eye_hud_m / ( math.sin(elev_rad) / math.cos(elev_rad) );
	# Angle between HUD center/top <-> HUD center/symbol position.
	# -90° left, 0° up, 90° right, +/- 180° down.
	var dev_deg =  math.atan2( h_dev, v_dev ) * R2D;
	# Correction with own a/c roll.
	var combined_dev_deg = dev_deg;
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
	var dev_norm = geo.normdeg180(target_bearing-our_heading);
	return dev_norm;
}

#
# this code make sure messages don't trigger the MP spam filter:

var spams = 0;
var spamList = [];
var mutexMsg = thread.newlock();
var mutexTimer = thread.newlock();
var mutexETA = thread.newlock();

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

var printff = func{
	var str = call(sprintf, arg,nil,nil,var err = []);#call to printf directly sometimes crashes FG
	debug.printerror(err);
	print(str);
}

spamLoop();
var timerLooper = maketimer(0, AIM, AIM.timerLoop);
timerLooper.start();
