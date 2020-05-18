# This file is from the implementation in l0k1/MiG-21bis

# unify mp lookups, databases, etc into one file that can be distributed to the
# radar, rwr, payloads, etc as needed. minimize the amount of property lookups
# to once per loop.

# also contain information specific to aircraft models, such as rcs.

# master list of all valid contacts.
var cx_master_list = [];

# radar contact classes/types
var AIR = 0;
var MARINE = 1;
var SURFACE = 2;
var ORDNANCE = 3;

var TRUE = 1;
var FALSE = 0;

# var aircraft_arch = {
#     name: "",               # only required part
#     rcs: 200.0,             # frontal rcs
    
#     rwr_strength: 0.0,      # distance at which the rwr will start to pick it up (nautical miles)
#     rwr_bearing: 0.0,       # how many degrees left/right the radar scans
#     rwr_pitch: 0.0,         # how many degrees up/down the radar scans
#     rwr_pattern: "sssssnnnnn",    # unique scan pattern for the aircrafts radar n=no sound, s=sound.
#     rwr_pattern_time: 1.0,  # how long it takes to loop the pattern (1-3 secs recommended)
#     class: AIR,             # what type of model it is. 
#     _rwr_index: 0,          # used in rwr code
#     _rwr_last_update: 0     # time when last updated, used to figure out where in the pattern we are.
# };

# var aircraft_lookup = {
#     "default":          {parents: [aircraft_arch]},
#     "F-14b":            {parents: [aircraft_arch], rcs: 12,  rwr_strength: 200, rwr_bearing: 65,  rwr_pitch: 65, class: AIR,},
#     "F-15C":            {parents: [aircraft_arch], rcs: 10,  rwr_strength: 150, rwr_bearing: 65,  rwr_pitch: 65, class: AIR,},
#     "F-15D":            {parents: [aircraft_arch], rcs: 11,  rwr_strength: 150, rwr_bearing: 65,  rwr_pitch: 65, class: AIR,},
#     "F-16":             {parents: [aircraft_arch], rcs: 2,   rwr_strength: 100, rwr_bearing: 60,  rwr_pitch: 60, class: AIR,rwr_pattern: "snsnsnssssnnnn"},
#     "JA37-Viggen":      {parents: [aircraft_arch], rcs: 3,   rwr_strength: 150, rwr_bearing: 70,  rwr_pitch: 70, class: AIR,},
#     "AJ37-Viggen":      {parents: [aircraft_arch], rcs: 3,   rwr_strength: 150, rwr_bearing: 70,  rwr_pitch: 70, class: AIR,},
#     "AJS37-Viggen":     {parents: [aircraft_arch], rcs: 3,   rwr_strength: 150, rwr_bearing: 70,  rwr_pitch: 70, class: AIR,},
#     "JA37Di-Viggen":    {parents: [aircraft_arch], rcs: 3,   rwr_strength: 150, rwr_bearing: 70,  rwr_pitch: 70, class: AIR,},
#     "m2000-5":          {parents: [aircraft_arch], rcs: 1,   rwr_strength: 200, rwr_bearing: 70,  rwr_pitch: 70, class: AIR,},
#     "m2000-5B":         {parents: [aircraft_arch], rcs: 1,   rwr_strength: 200, rwr_bearing: 70,  rwr_pitch: 70, class: AIR,},
#     "MiG-21bis":        {parents: [aircraft_arch], rcs: 3.5, rwr_strength: 75,  rwr_bearing: 35,  rwr_pitch: 35, class: AIR,},
#     "MiG-21MF-75":      {parents: [aircraft_arch], rcs: 3.5, rwr_strength: 75,  rwr_bearing: 35,  rwr_pitch: 35, class: AIR,},
#     "Typhoon":          {parents: [aircraft_arch], rcs: 0.5, rwr_strength: 200, rwr_bearing: 70,  rwr_pitch: 70, class: AIR,},
#     "707":              {parents: [aircraft_arch], rcs: 100, rwr_strength: 20,  rwr_bearing: 180, rwr_pitch: 90, class: AIR,},
#     "707-TT":           {parents: [aircraft_arch], rcs: 100, rwr_strength: 20,  rwr_bearing: 180, rwr_pitch: 90, class: AIR,},
#     "EC-137D":          {parents: [aircraft_arch], rcs: 110, rwr_strength: 400, rwr_bearing: 180, rwr_pitch: 90, class: AIR,},
#     "B-1B":             {parents: [aircraft_arch], rcs: 10,  rwr_strength: 25,  rwr_bearing: 90,  rwr_pitch: 90, class: AIR,},
#     "RC-137R":          {parents: [aircraft_arch], rcs: 110, rwr_strength: 400, rwr_bearing: 180, rwr_pitch: 90, class: AIR,},
#     "EC-137R":          {parents: [aircraft_arch], rcs: 110, rwr_strength: 400, rwr_bearing: 180, rwr_pitch: 90, class: AIR,rwr_pattern: "sssssnnsnn"},
#     "QF-4E":            {parents: [aircraft_arch], rcs: 6,   rwr_strength: 100, rwr_bearing: 70,  rwr_pitch: 70, class: AIR,},
#     "buk-m2":           {parents: [aircraft_arch], rcs: 7,   rwr_strength: 75,  rwr_bearing: 180, rwr_pitch: 90, class: SURFACE,rwr_pattern: "snsnnssssn"},
#     "missile_frigate":  {parents: [aircraft_arch], rcs: 450, rwr_strength: 120, rwr_bearing: 180, rwr_pitch: 90, class: MARINE,},
#     "frigate":          {parents: [aircraft_arch], rcs: 450, rwr_strength: 75,  rwr_bearing: 180, rwr_pitch: 90, class: MARINE,},
#     "fleet":            {parents: [aircraft_arch], rcs: 900, rwr_strength: 120, rwr_bearing: 180, rwr_pitch: 90, class: MARINE,},
#     "Blackbird-SR71A":  {parents: [aircraft_arch], rcs: 0.25, class: AIR,},
#     "Blackbird-SR71B":  {parents: [aircraft_arch], rcs: 0.30, class: AIR,},
#     "Blackbird-SR71A-BigTail":  {parents: [aircraft_arch], rcs: 0.30, class: AIR,},
#     "ch53e":            {parents: [aircraft_arch], rcs: 20, class: AIR,},
#     "MQ-9":             {parents: [aircraft_arch], rcs: 1, class: AIR,},
#     "KC-137R":          {parents: [aircraft_arch], rcs: 100, class: AIR,},
#     "KC-137R-RT":       {parents: [aircraft_arch], rcs: 100, class: AIR,},
#     "A-10":             {parents: [aircraft_arch], rcs: 23.5, class: AIR,},
#     "KC-10A":           {parents: [aircraft_arch], rcs: 100, class: AIR,},
#     "C-137R":           {parents: [aircraft_arch], rcs: 100, class: AIR,},
#     "c130":             {parents: [aircraft_arch], rcs: 100, class: AIR,},
#     "SH-60J":           {parents: [aircraft_arch], rcs: 30, class: AIR,},
#     "UH-60J":           {parents: [aircraft_arch], rcs: 30, class: AIR,},
#     "uh1":              {parents: [aircraft_arch], rcs: 30, class: AIR,},
#     "212-TwinHuey":     {parents: [aircraft_arch], rcs: 25, class: AIR,},
#     "412-Griffin":      {parents: [aircraft_arch], rcs: 25, class: AIR,},
#     "depot":            {parents: [aircraft_arch], rcs: 170, class: SURFACE,},
#     "truck":            {parents: [aircraft_arch], rcs: 1.5, class: SURFACE,},
#     "tower":            {parents: [aircraft_arch], rcs: 60, class: SURFACE,},
# };

var Contact = {
    # reqd by guided-missiles.nas:
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

    new: func(c, class) {
        var obj             = { parents : [Contact]};
        # obj.rdrProp         = c.getNode("radar");
        obj.oriProp         = c.getNode("orientation");
        obj.velProp         = c.getNode("velocities");
        obj.posProp         = c.getNode("position");
        obj.heading         = obj.oriProp.getNode("true-heading-deg");
        obj.alt             = obj.posProp.getNode("altitude-ft");
        obj.lat             = obj.posProp.getNode("latitude-deg");
        obj.lon             = obj.posProp.getNode("longitude-deg");

        obj.x             = obj.posProp.getNode("global-x");
        obj.y             = obj.posProp.getNode("global-y");
        obj.z             = obj.posProp.getNode("global-z");
        #As it is a geo.Coord object, we have to update lat/lon/alt ->and alt is in meters
        obj.coord = geo.Coord.new();
        if (obj.x == nil or obj.x.getValue() == nil) {
          obj.coord.set_latlon(obj.lat.getValue(), obj.lon.getValue(), obj.alt.getValue() * FT2M);
        } else {
          obj.coord.set_xyz(obj.x.getValue(), obj.y.getValue(), obj.z.getValue());
        }
        obj.pitch           = obj.oriProp.getNode("pitch-deg");
        obj.roll            = obj.oriProp.getNode("roll-deg");
        obj.speed           = obj.velProp.getNode("true-airspeed-kt");
        obj.vSpeed          = obj.velProp.getNode("vertical-speed-fps");
        obj.callsign        = c.getNode("callsign", 1);
        obj.shorter         = c.getNode("model-shorter");
        obj.orig_callsign   = obj.callsign.getValue();
        obj.name            = c.getNode("name");
        obj.sign            = c.getNode("sign",1);
        obj.valid           = c.getNode("valid");
        obj.painted         = c.getNode("painted");
        obj.unique          = c.getNode("unique");
        obj.validTree       = 0;

        obj.eta             = c.getNode("ETA");
        obj.hit             = c.getNode("hit");

        #obj.transponderID   = c.getNode("instrumentation/transponder/transmitted-id");

        obj.acType          = c.getNode("sim/model/ac-type");
        obj.rdrAct          = c.getNode("sim/multiplay/generic/int[2]");
        obj.type            = c.getName();
        obj.index           = c.getIndex();
        obj.string          = "ai/models/" ~ obj.type ~ "[" ~ obj.index ~ "]";
        obj.shortString     = obj.type ~ "[" ~ obj.index ~ "]";

        # obj.range           = obj.rdrProp.getNode("range-nm");
        # obj.bearing         = obj.rdrProp.getNode("bearing-deg");
        # #obj.elevation       = obj.rdrProp.getNode("elevation-deg"); this is computes in C++ using atan, so does not take curvature of earth into account.

        obj.deviation       = nil;

        obj.node            = c;
        obj.class           = class;

        obj.polar           = [0,0,0];
        obj.cartesian       = [0,0];
        
        # if (c.getNode("type").getValue() == "Mig-28" or c.getNode("type").getValue() == "F-16" ) {
        #     obj.info = aircraft_lookup["F-16"];
        #     obj.name = "trainer";
        # } else if (contains(aircraft_lookup,obj.get_model2())) {
        #     obj.info = aircraft_lookup[obj.get_model2()];
        # } else {
        #     obj.info = aircraft_lookup["default"];
        # }

        obj.tacobj = {parents: [tacview.tacobj]};
        obj.tacobj.tacviewID = 1000 + int(math.floor(rand()*10000));
        obj.tacobj.valid = 1;
        
        return obj;
    },

    getETA: func {
      if (me.eta != nil) {
        return me.eta.getValue();
      }
      return nil;
    },

    getHitChance: func {
      if (me.hit != nil) {
        return me.hit.getValue();
      }
      return nil;
    },

    isValid: func () {
      var valid = me.valid.getValue();
      if (valid == nil) {
        valid = FALSE;
      }
      if (me.callsign.getValue() != me.orig_callsign) {
        valid = FALSE;
      }
      return valid;
    },

    isVirtual: func {
      return 0;
    },

    isRadarActive: func {
      if (me.rdrAct == nil) {
        return TRUE;
      }
      if (me.rdrAct.getValue() == nil) {
        return TRUE;
      } elsif (me.rdrAct.getValue() < 0 or me.rdrAct.getValue() > 1) {
        return TRUE;
      }
      return 1 - me.rdrAct.getValue();
    },

    isPainted: func () {
      if (me.painted == nil) {
        me.painted = me.node.getNode("painted");
      }
      if (me.painted == nil) {
        return nil;
      }
      var p = me.painted.getValue();
      return p;
    },

    getUnique: func () {
      if (me.unique == nil) {
        me.unique = me.node.getNode("unique");
      }
      if (me.unique == nil) {
        return nil;
      }
      var u = me.unique.getValue();
      return u;
    },

    getElevation: func() {
        return vector.Math.getPitch(geo.aircraft_position(), me.coord);
    },

    getNode: func () {
      return me.node;
    },

    getFlareNode: func () {
      return me.node.getNode("rotors/main/blade[3]/flap-deg");
    },

    getChaffNode: func () {
      return me.node.getNode("rotors/main/blade[3]/position-deg");
    },
    
    isRadiating: func (check_coord) {
      
      # check if radar is on

      #print("for " ~ me.callsign.getValue());
      
      if (me.isRadarActive() == 0) {
        #print("its false");
        return FALSE;
      }
      
      # check if there's terrain in between
      
      me.get_Coord();

      # Check for terrain between own coord and target
      var gcgi = get_cart_ground_intersection({"x":me.coord.x(),"y":me.coord.y(),"z":me.coord.z()}, {"x":check_coord.x()-me.coord.x(),  "y":check_coord.y()-me.coord.y(), "z":check_coord.z()-me.coord.z()});
      if (gcgi == nil) {
        #print("No terrain, planes has clear view of each other");
      } else {
       if (me.coord.direct_distance_to(geo.Coord.new().set_latlon(gcgi.lat, gcgi.lon, gcgi.elevation)) < me.coord.direct_distance_to(check_coord)) {
         #print("terrain found between the planes");
         return FALSE;
       } else {
          #print("The planes has clear view of each other");
       }
      }
      
      # check if they're in the radar cone
      
      return TRUE;

      var pols = me.get_polar();
      if ( !contains(rwr.rwr_database,me.get_model()) ) {
        var model_info = rwr.rwr_database("default");
      } else {
        var model_info = rwr.rwr_database[me.get_model()];
      }

      if(math.abs(pols[2]) < model_info[1] * D2R and math.abs(pols[1]) < model_info[0] and pols[0] < model_info[2]) {
        return TRUE;
        #print("the target is radiating");
      }
      
      return FALSE;
      
    },

    remove: func(){
        if(me.validTree != 0){
          me.validTree.setBoolValue(0);
        }
    },

    get_Coord: func(){
        if (me.x != nil and me.x.getValue() != nil) {
          me.coord.set_xyz(me.x.getValue(), me.y.getValue(), me.z.getValue());
        } else {
          me.coord.set_latlon(me.lat.getValue(), me.lon.getValue(), me.alt.getValue() * FT2M);
        }
        var TgTCoord  = geo.Coord.new(me.coord);
        return TgTCoord;
    },

    get_Callsign: func(){
        var n = me.callsign.getValue();
        if(n != "" and n != nil) {
            return n;
        }
        if (me.name == nil) {
          me.name = me.getNode().getNode("name");
        }
        if (me.name == nil) {
          n = "";
        } else {
          n = me.name.getValue();
        }
        if(n != "" and n != nil) {
            return n;
        }
        n = me.sign.getValue();
        if(n != "" and n != nil) {
            return n;
        }
        return "UFO";
    },

    get_model: func(){
        var n = "";
        if (me.shorter == nil) {
          me.shorter = me.node.getNode("model-shorter");
        }
        if (me.shorter != nil) {
          n = me.shorter.getValue();
        }
        if(n != "" and n != nil) {
            return n;
        }
        n = me.sign.getValue();
        if(n != "" and n != nil) {
            return n;
        }
        if (me.name == nil) {
          me.name = me.getNode().getNode("name");
        }
        if (me.name == nil) {
          n = "";
        } else {
          n = me.name.getValue();
        }
        if(n != "" and n != nil) {
            return n;
        }
        return me.get_Callsign();
    },

    get_model2: func() {
      if (me.node.getNode('sim/model/path') != nil) {
        me.mname = split(".", split("/", me.node.getNode('sim/model/path').getValue())[-1])[0];
        me.mname = me.remove_suffix(me.mname, "-model");
        me.mname = me.remove_suffix(me.mname, "-anim");
        return me.mname;
      } else {
        return me.get_Callsign();
      }
    },

    remove_suffix: func(s, x) {
      me.len = size(x);
      if (substr(s, -me.len) == x)
        return substr(s, 0, size(s) - me.len);
      return s;
    },

    get_Speed: func(){
        # return true airspeed
        var n = me.speed.getValue();
        return n;
    },

    get_Longitude: func(){
        var n = me.lon.getValue();
        return n;
    },

    get_Latitude: func(){
        var n = me.lat.getValue();
        return n;
    },

    get_Pitch: func(){
        var n = me.pitch.getValue();
        return n;
    },

    get_Roll: func(){
        var n = me.roll.getValue();
        return n;
    },

    get_heading : func(){
        var n = me.heading.getValue();
        if(n == nil)
        {
            n = 0;
        }
        return n;
    },

    get_bearing: func(){
        var n = 0;
        n = me.bearing.getValue();
        if(n == nil or n == 0) {
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

    get_reciprocal_bearing: func(){
        return geo.normdeg(me.get_bearing() + 180);
    },

    get_deviation: func(true_heading_ref, coord){
        me.deviation =  - deviation_normdeg(true_heading_ref, me.get_bearing_from_Coord(coord));
        return me.deviation;
    },

    get_altitude: func(){
        #Return Alt in feet
        return me.alt.getValue();
    },

    get_Elevation_from_Coord: func(MyAircraftCoord) {
        #me.get_Coord();
        #var value = (me.coord.alt() - MyAircraftCoord.alt()) / me.coord.direct_distance_to(MyAircraftCoord);
        #if (math.abs(value) > 1) {
          # warning this else will fail if logged in as observer and see aircraft on other side of globe
        #  return 0;
        #}
        #var myPitch = math.asin(value) * R2D;
        return vector.Math.getPitch(me.get_Coord(), MyAircraftCoord);
    },

    get_total_elevation_from_Coord: func(own_pitch, MyAircraftCoord){
        var myTotalElevation =  - deviation_normdeg(own_pitch, me.get_Elevation_from_Coord(MyAircraftCoord));
        return myTotalElevation;
    },
    
    get_total_elevation: func(own_pitch) {
        me.deviation =  - deviation_normdeg(own_pitch, me.getElevation());
        return me.deviation;
    },

    get_range: func() {
        var r = 0;
        if(me.range == nil or me.range.getValue() == nil or me.range.getValue() == 0) {
            # AI/MP has no radar properties
            me.get_Coord();
            r = me.coord.direct_distance_to(geo.aircraft_position()) * M2NM;
        } else {
          r = me.range.getValue();
        }
        return r;
    },

    get_range_from_Coord: func(MyAircraftCoord) {
        var myCoord = me.get_Coord();
        var myDistance = 0;
        if(myCoord.is_defined()) {
            myDistance = MyAircraftCoord.direct_distance_to(myCoord) * M2NM;
        }
        return myDistance;
    },

    get_type: func () {
      return me.class;
    },

    get_cartesian: func() {
      me.get_Coord();
      me.crft = geo.aircraft_position();
      me.ptch = vector.Math.getPitch(me.crft,me.coord);
      me.dst  = me.crft.direct_distance_to(me.coord);
      me.brng = me.crft.course_to(me.coord);
      me.hrz  = math.cos(me.ptch*D2R)*me.dst;

      me.vel_gz = -math.sin(me.ptch*D2R)*me.dst;
      me.vel_gx = math.cos(me.brng*D2R) *me.hrz;
      me.vel_gy = math.sin(me.brng*D2R) *me.hrz;
      

      me.yaw   = input.hdgReal.getValue() * D2R;
      me.myroll= input.roll.getValue()    * D2R;
      me.mypitch= input.pitch.getValue()   * D2R;

      #printf("heading %.1f bearing %.1f pitch %.1f north %.1f east %.1f down %.1f", input.hdgReal.getValue(), me.brng, me.ptch, me.vel_gx, me.vel_gy, me.vel_gz);

      me.sy = math.sin(me.yaw);   me.cy = math.cos(me.yaw);
      me.sr = math.sin(me.myroll);  me.cr = math.cos(me.myroll);
      me.sp = math.sin(me.mypitch); me.cp = math.cos(me.mypitch);
   
      me.vel_bx = me.vel_gx * me.cy * me.cp
                 + me.vel_gy * me.sy * me.cp
                 + me.vel_gz * -me.sp;
      me.vel_by = me.vel_gx * (me.cy * me.sp * me.sr - me.sy * me.cr)
                 + me.vel_gy * (me.sy * me.sp * me.sr + me.cy * me.cr)
                 + me.vel_gz * me.cp * me.sr;
      me.vel_bz = me.vel_gx * (me.cy * me.sp * me.cr + me.sy * me.sr)
                 + me.vel_gy * (me.sy * me.sp * me.cr - me.cy * me.sr)
                 + me.vel_gz * me.cp * me.cr;
   
      me.dir_y  = math.atan2(round0(me.vel_bz), math.max(me.vel_bx, 0.001)) * R2D;
      me.dir_x  = math.atan2(round0(me.vel_by), math.max(me.vel_bx, 0.001)) * R2D;

      var hud_pos_x = canvas_HUD.pixelPerDegreeX * me.dir_x;
      var hud_pos_y = canvas_HUD.centerOffset + canvas_HUD.pixelPerDegreeY * me.dir_y;

      return [hud_pos_x, hud_pos_y];
    },

    get_polar: func() {
      me.get_Coord();
      var aircraftAlt = me.coord.alt();

      var self      =  geo.aircraft_position();
      var myPitch   =  input.pitch.getValue()*D2R;
      var myRoll    =  0;#input.roll.getValue()*deg2rads;  Ignore roll, since a real radar does that
      var myAlt     =  self.alt();
      var myHeading =  input.hdgReal.getValue();
      var distance  =  self.distance_to(me.coord);

      var yg_rad = vector.Math.getPitch(self, me.coord)*D2R-myPitch;#math.atan2(aircraftAlt-myAlt, distance) - myPitch; 
      var xg_rad = (self.course_to(me.coord) - myHeading) * deg2rads;
      
      while (xg_rad > math.pi) {
        xg_rad = xg_rad - 2*math.pi;
      }
      while (xg_rad < -math.pi) {
        xg_rad = xg_rad + 2*math.pi;
      }
      while (yg_rad > math.pi) {
        yg_rad = yg_rad - 2*math.pi;
      }
      while (yg_rad < -math.pi) {
        yg_rad = yg_rad + 2*math.pi;
      }

      #aircraft angle
      var ya_rad = xg_rad * math.sin(myRoll) + yg_rad * math.cos(myRoll);
      var xa_rad = xg_rad * math.cos(myRoll) - yg_rad * math.sin(myRoll);
      var xa_rad_corr = xg_rad;

      while (xa_rad_corr < -math.pi) {
        xa_rad_corr = xa_rad_corr + 2*math.pi;
      }
      while (xa_rad_corr > math.pi) {
        xa_rad_corr = xa_rad_corr - 2*math.pi;
      }
      while (xa_rad < -math.pi) {
        xa_rad = xa_rad + 2*math.pi;
      }
      while (xa_rad > math.pi) {
        xa_rad = xa_rad - 2*math.pi;
      }
      while (ya_rad > math.pi) {
        ya_rad = ya_rad - 2*math.pi;
      }
      while (ya_rad < -math.pi) {
        ya_rad = ya_rad + 2*math.pi;
      }

      var distanceRadar = distance;#/math.cos(myPitch);

      return [distanceRadar, xa_rad, ya_rad, xa_rad_corr];
    },
};

var matching = 0;

var update_cx_master_list = func() {

  # get a list of all possible contact nodes into a vector
  temp = [];
  foreach(var mp; props.globals.getNode("/ai/models").getChildren("multiplayer")){
    if (mp.getNode("valid") != nil) {
      if (mp.getNode("valid").getValue() == 1) {
        append(temp,mp);
      }
    }
  }
  foreach(var mp; props.globals.getNode("/ai/models").getChildren("aircraft")){
    if (mp.getNode("valid").getValue() == 1) {
      append(temp,mp);
    }
  }

  foreach(var mp; props.globals.getNode("/ai/models").getChildren("tanker")){
    if (mp.getNode("valid").getValue() == 1) {
      append(temp,mp);
    }
  }

  foreach(var mp; props.globals.getNode("/ai/models").getChildren("ship")){
    if (mp.getNode("valid").getValue() == 1) {
      append(temp,mp);
    }
  }

  foreach(var mp; props.globals.getNode("/ai/models").getChildren("groundvehicle")){
    if (mp.getNode("valid").getValue() == 1) {
      append(temp,mp);
    }
  }

  foreach(var mp; props.globals.getNode("/ai/models").getChildren("Mig-28")){
    if (mp.getNode("valid").getValue() == 1) {
      append(temp,mp);
    }
  }

  # clean out cx_master_list
  foreach(var cx; cx_master_list) {
    if (cx.isValid() == 0) {
      #print("removing");
      if (tacview.starttime) {
        thread.lock(mutexWrite);
        tacview.write("#" ~ (systime() - tacview.starttime)~"\n");
        tacview.write("0,Event=LeftArea|"~cx.tacobj.tacviewID~"|\n");
        tacview.write("-"~cx.tacobj.tacviewID~"\n");
        thread.unlock(mutexWrite);
      }
      cx_master_list = remove_from_array(cx_master_list, cx);
    }
  }

  # loop through master list looking for new nodes
  foreach(var mp; temp) {
    matching = 0;
    foreach(var cx; cx_master_list) {
      if ( mp.getPath() == cx.getNode().getPath() ) {
        matching = 1;
        break;
      }
    }
    if (matching == 0) {
      append(cx_master_list,Contact.new(mp,0));
    }
  }

  settimer(func() {
    update_cx_master_list();
  },3);
}
update_cx_master_list();

var remove_from_array = func(arr, item) {
  # get index of item
  forindex (var index; arr) {
    if ( arr[index] == item ) {
      return subvec(arr, 0, index) ~ subvec(arr, index + 1);
    }
  }
}