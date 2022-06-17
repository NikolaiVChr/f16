#print("*** LOADING terrain_follow.nas ... ***");

# Terrain following radar

# Parameters:
# instrumentation/tfs/delay-sec: the TFS will look ahead to the
#                                position at which the plane will be
#                                in this amount of time given its
#                                current speed.
#
# Output:
# instrumentation/tfs/malfunction:          set to 1 if the ground was not found
# instrumentation/tfs/ground-altitude-ft:   measured ground altitude
#
# Note: in case of malfunction, the radar will keep reporting the last
# known altitude or 0 if that was negative (there is an issue when
# over deep sea that causes the last reported ground altitude to be a
# large negative value).



#This is done for detecting a terrain between aircraft and target. Since 2017.2.1, a new method allow to do the same, faster, and with more precision. (See isNotBehindTerrain function)
var versionString = getprop("sim/version/flightgear");
var version = split(".", versionString);
var major = num(version[0]);
var minor = num(version[1]);
var pica  = num(version[2]);
var pickingMethod = 0;
if ((major == 2017 and minor == 2 and pica >= 1) or (major == 2017 and minor > 2) or major > 2017) {
    pickingMethod = 1;
}
setprop("/instrumentation/tfs/ground-altitude-ft",0);


var xyz = nil;
var dir = nil;
var v = nil;
var distance_Target = nil;
var terrain = geo.Coord.new();
var My_pos = geo.Coord.new();
var minim_delay = 8;
var maximum_delay = 15;



setprop ("instrumentation/tfs/delay-sec", 4);
setprop ("instrumentation/tfs/delay-big-sec", minim_delay);

var tfs_radar = func(){
    var delay_sec = getprop("instrumentation/tfs/delay-big-sec");
    var myAltitude = tfs_radar_calculation(delay_sec);

    setprop("/instrumentation/tfs/ground-altitude-ft",myAltitude);
}

var long_view_avoiding = func(){

    #Minimum delay 8, maximum 15
    var myAltitude = tfs_radar_calculation(20) * FT2M;
    var myAircraft = geo.aircraft_position();

    var diff_future = myAltitude - myAircraft.alt();

    #140 meter/ seconds => max climb rate
    var delay_sec = math.min(math.max(((diff_future)/140),minim_delay),maximum_delay);

    #print("Future Altitude:" ~ myAltitude ~";myAircraft:"~ myAircraft.alt() ~";myAltitude - myAircraft.alt():"~ diff_future ~" delay:"~ delay_sec);
    getprop("instrumentation/tfs/delay-big-sec",delay_sec)

}



var tfs_radar_calculation = func(delay_sec) {


    var speed_kt  = getprop("velocities/groundspeed-kt");
    var range_m   = (speed_kt * 1852 / 3600) * delay_sec;

    var speed_east_fps = getprop("velocities/speed-east-fps");
    var speed_north_fps = getprop("velocities/speed-north-fps");
    var h_spd = math.sqrt(speed_east_fps*speed_east_fps + speed_north_fps*speed_north_fps);
    var hdg_deg = nil;
    if (h_spd <= 0) {
      hdg_deg = getprop ("orientation/heading-deg");
    } else {
      #hdg_deg = math.asin(speed_east_fps/h_spd)*R2D;
      #if (speed_north_fps < 0) {
      #  if (hdg_deg >= 0) {
      #    hdg_deg = 180-hdg_deg;
      #  } else {
      #    hdg_deg = -180-hdg_deg;
      #  }
      #}
      #hdg_deg = geo.normdeg(hdg_deg);
      hdg_deg = geo.normdeg(math.atan2(speed_east_fps,speed_north_fps)*R2D);
    }

    #var lat_deg = getprop ("position/latitude-deg");
    #var lon_deg = getprop ("position/longitude-deg");

    var current_pos = geo.aircraft_position();
    var current_terr = geo.elevation(current_pos.lat(), current_pos.lon());
    if (current_terr == nil) {
      return TF_malfunction();
    }
    My_pos.set_latlon(current_pos.lat(), current_pos.lon(), current_terr+1);
    #var current_pos = geo.Coord.new().set_latlon (lat_deg, lon_deg);
    #print("My_pos alt :"~ My_pos.alt());


    var target_pos = current_pos.apply_course_distance (hdg_deg, range_m);
    var target_altitude_m = geo.elevation (target_pos.lat(), target_pos.lon());

    if (target_altitude_m == nil) {
      return TF_malfunction();
    }
    #print("target_pos alt :"~ target_altitude_m);

    # Avoid an issue when altitude-m is not set
    var altitude_m = getprop ("position/altitude-ft") * FT2M;
    if(altitude_m == nil)
    {
        altitude_m = target_altitude_m+1;
    }


    if((target_altitude_m == nil)
        or (altitude_m - target_altitude_m > 2000))
    {
      return TF_malfunction();
    }
    else
    {
        #If there is terrain between target alt, we increase it by 100 feet. until there is no more terrain
        target_pos.set_alt(target_altitude_m+1);
        #print("Aircraft Altitude : " ~ getprop ("position/altitude-ft") * FT2M);

        var Mylittlealt = highest_altitude(My_pos,target_pos);
        #print("Actual ground alt : " ~ My_pos.alt() ~ " and Ahead " ~ delay_sec ~ " sec:" ~ target_pos.alt());
        #print("highest_altitude : " ~ Mylittlealt);
        setprop("instrumentation/tfs/malfunction", 0);

        #Same code, 6 meters left
        current_pos = geo.aircraft_position();
        current_pos.apply_course_distance (hdg_deg-90, 6);
        My_pos.set_latlon(current_pos.lat(), current_pos.lon(), geo.elevation(current_pos.lat(), current_pos.lon())+1);
        target_pos = current_pos.apply_course_distance (hdg_deg, range_m);
        target_pos.set_alt(geo.elevation (target_pos.lat(), target_pos.lon())+1);
        var MyAltLeft = highest_altitude(My_pos,target_pos);

        #Same code, 6 meters right
        current_pos = geo.aircraft_position();
        current_pos.apply_course_distance (hdg_deg+90, 6);
        My_pos.set_latlon(current_pos.lat(), current_pos.lon(), geo.elevation(current_pos.lat(), current_pos.lon())+1);
        target_pos = current_pos.apply_course_distance (hdg_deg, range_m);
        target_pos.set_alt(geo.elevation (target_pos.lat(), target_pos.lon())+1);
        var MyAltRight = highest_altitude(My_pos,target_pos);

        #print("Mylittlealt:"~ Mylittlealt ~"; MyAltLeft:" ~ MyAltLeft ~ "; MyAltRight:" ~MyAltRight);
        Mylittlealt = math.max(Mylittlealt,MyAltLeft,MyAltRight);
        #print("Final:"~ Mylittlealt);


        return ((Mylittlealt) * M2FT);

    }

    #settimer (tfs_radar, 0.1);
}
#settimer (tfs_radar, 0.1);

var check_terrain_avoiding = func(coord){
  if(pickingMethod != 1){return 1;}
  #We check that there is no terrain between our aircraft and our futur target altitude
  myPos = geo.aircraft_position();

  if(myPos == nil){return 1;}
  var Altitude = myPos.alt() - 40;
  #We took took down the aircraft by 30
  if(Altitude > geo.elevation(myPos.lat(), myPos.lon())){
      myPos.set_alt(myPos.alt()-30);
  }

  xyz = {"x":myPos.x(),                  "y":myPos.y(),                 "z":myPos.z()};
  dir = {"x":coord.x()-myPos.x(),  "y":coord.y()-myPos.y(), "z":coord.z()-myPos.z()};

  distance_Target = myPos.direct_distance_to(coord);

  # Check for terrain between own aircraft and other:
  v = get_cart_ground_intersection(xyz, dir);
  if(v == nil){return 1;}

  terrain.set_latlon(v.lat, v.lon, v.elevation);
  if(myPos.direct_distance_to(terrain)>distance_Target){
      return 1;
  }else{return 0;}

}

#Return the highest point between 2 coords
var highest_altitude = func(backward, forward){
  #print("Bitocul");
  var MyBack = geo.Coord.new();
  var MyFor = geo.Coord.new();

  var myCheck = 0;

  #print("Bitocul x toto");
  #The max altitude between those 2
  var elevation = math.max(backward.alt(), forward.alt());

  #print("Bitocul x tata" ~ elevation);
  #The step will be the way to find the best alt
  var step = 1000;

  #print("Bitocul x tutu");

  MyBack.set_latlon(backward.lat(), backward.lon(), elevation);
  MyFor.set_latlon(forward.lat(), forward.lon(), elevation);

  #print("Bitocul x prime");
  #Avoid entering in the loop if one of those point is already the max
  myCheck = double_terrain_check(MyBack,MyFor);
  if(myCheck == nil){
    #print("One of these point is the highest, alt:"~ elevation);
    return elevation
  }

  #var i is a security check. maybe we should replace this loop by a for/to
  var i = 0;
  var lastAbove = elevation;
  #print("Launching the while");
  while(myCheck != 1 and i < 15){
    i = i + 1;
    #print("in the while");
    if(myCheck == 0){
      #0 means under the highest point
      # Need to raise elevation
      elevation = elevation + step;
    }elsif(myCheck == nil){
      #nil means too high
      #Need to low the elevation, but decresing the step
      step = step / 2;
      lastAbove = elevation;
      elevation = elevation - step;
    }else{
      return elevation;
    }

    MyBack.set_alt(elevation);
    MyFor.set_alt(elevation);

    myCheck = double_terrain_check(MyBack,MyFor);
  }
  return lastAbove;


}


var double_terrain_check = func(backward,forward){
  #This will call 2 time "terrain_detection_between" and if non nil will measure distance between point.
  #We can supose that a a double terrain cross < a 2 meters, on from the other is "a single point and max altitude"

  #print("Bitocul x3");
  var Firstpoint = terrain_detection_between(backward,forward);
  var Secondpoint = terrain_detection_between(forward,backward);

  #print("Bitocul x4");

  if(Firstpoint == nil and Secondpoint == nil){
    #print("Above highest point, alt:"~backward.alt());
    return nil;
  }
  if (Firstpoint == nil or Secondpoint == nil) {
    # one of them is nil
    return 0;
  }
  var terrainFirst = geo.Coord.new();
  var terrainSecond = geo.Coord.new();

  terrainFirst.set_latlon(Firstpoint.lat, Firstpoint.lon, Firstpoint.elevation);
  terrainSecond.set_latlon(Secondpoint.lat, Secondpoint.lon, Secondpoint.elevation);

  if(terrainFirst.direct_distance_to(terrainSecond)< 1){
    #Same point
    #print("Same point, alt:" ~backward.alt());
    return 1;
  }else{
    #Under highest point
    #print("Under highest point, alt:"~backward.alt());
    return 0;
  }

}

#This will exclude any terrain detection that could be found "outside" of between the 2 coord
#Will return nil if there is no terrain
#Else it will return the coordinates
var terrain_detection_between = func(backward, forward){
  #Measure the distance between the 2 object
  var distance_Target = backward.direct_distance_to(forward);
  var terrain = geo.Coord.new();


  #get_cart_ground_intersection Stuff
  xyz = {"x":backward.x(),                  "y":backward.y(),                 "z":backward.z()};
  dir = {"x":forward.x()-backward.x(),  "y":forward.y()-backward.y(), "z":forward.z()-backward.z()};
  v = get_cart_ground_intersection(xyz, dir);
  if(v == nil){
    return v;
  }

  #Check if the terrain is indeed between the 2 points
  terrain.set_latlon(v.lat, v.lon, v.elevation);
  if(backward.direct_distance_to(terrain)>distance_Target){
      return nil;
  }else{
    return v;
  }
}

var TF_malfunction = func(){
  setprop("instrumentation/tfs/malfunction", 1);
  settimer(reset_TF_malfunction, 5.0);
  return math.max (0, getprop ("instrumentation/tfs/ground-altitude-ft"));
}


var reset_TF_malfunction = func(){
  setprop("instrumentation/tfs/malfunction", 0);
}

