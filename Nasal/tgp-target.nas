#print("*** LOADING missile_GroundTargeting.nas ... ***");
################################################################################
#
#     from:                m2005-5's ADDING GROUND TARGET
#
################################################################################

var dt       = 0;
var isFiring = 0;
var myGroundTarget = nil;
var Mp = props.globals.getNode("ai/models");
var MyActualview = props.globals.getNode("/sim/current-view/view-number");

var listOfGroundOrShipVehicleModels = {
                                        "ZSU-23-4M":1,
                                        "S-75":1,
                                        "buk-m2":1, 
                                        "s-300":1,
                                        "MIM104D":1,
                                        "depot":1
                                        "struct":1,
                                        "point":1,
                                        "rig":1,
                                        "truck":1, 
                                        "tower":1, 
                                        "germansemidetached1":1,
                                        "frigate":1, "missile_frigate":1, 
                                        "USS-LakeChamplain":1, 
                                        "USS-NORMANDY":1, 
                                        "USS-OliverPerry":1, 
                                        "USS-SanAntonio":1,
                                        "ship":1,
                                        "carrier":1,
                                        "aircraft":1,
                                        "multiplayer":1,
                                      };

#The function that create the ground target object when the dialog box is pressed
var targetingGround = func()
{
    if(myGroundTarget == nil){
      myGroundTarget = ground_target.new();
      myGroundTarget.init();
    }
    
    #Each time the ground target button is pressed, the life go to 900 and the AI following flag go to
    myGroundTarget.following = 0;
    myGroundTarget.life_time = 900;
    
    if( geo.elevation(myGroundTarget.lat.getValue(), myGroundTarget.long.getValue(),10000) == nil){
      var oldView = view_GPS_target(myGroundTarget);
      
      
      var timer = maketimer(10,func(){
        setprop("/sim/current-view/view-number", oldView);
      });
      timer.singleShot = 1; # timer will only be run once
      timer.start();
    }
    
}

# Function called when "focus on target" button is pressed.
var focus_onTarget = func(){
  if(myGroundTarget!= nil){
    mirage2000.flir_updater.click_coord_cam = myGroundTarget.coord;
    #print_coordinates("click_coord_cam before focus",mirage2000.flir_updater.click_coord_cam);
    #print_coordinates("myGroundTarget",myGroundTarget.coord);
  }
}

var follow_AI_MP=func(){
    if(myGroundTarget!= nil){
    if(myGroundTarget.following == 0){
        myGroundTarget.following = 1;
        myGroundTarget.targetedPath = nil;
        print("Following an AI target");
        logger.screen.green("Following an AI target");
    }
    else{
        myGroundTarget.following = 0;
        myGroundTarget.targetedPath = nil;
        print("Stop following an AI target");
        logger.screen.red("Stop following an AI target");
    }
  }
}


# this object create an AI object where is the last click
var ground_target = {
    new: func()
    {
        var m = { parents : [ground_target]};
        m.coord = geo.Coord.new();
        
        # Find the next index for "models/model" and create property node.
        # Find the next index for "ai/models/aircraft" and create property node.
        # (M. Franz, see Nasal/tanker.nas)
        var n = props.globals.getNode("models", 1);
        for(var i = 0 ; 1 ; i += 1)
        {
            if(n.getChild("model", i, 0) == nil)
            {
                break;
            }
        }
        m.model = n.getChild("model", i, 1);
        var n = props.globals.getNode("ai/models", 1);
        for(var i = 0 ; 1 ; i += 1)
        {
            if(n.getChild("aircraft", i, 0) == nil)
            {
                break;
            }
        }
        m.ai = n.getChild("aircraft", i, 1);
        m.ai.getNode("valid", 1).setBoolValue(1);
        
        #We will replace it by a light that will modelize the laser spot
        m.id_model = "Aircraft/Mirage-2000/Models/lights/WhiteLight_LaserSpot.xml";
        #m.id_model = "Models/Military/humvee-pickup-odrab-low-poly.xml";
        #m.model.getNode("path", 1).setValue(m.id_model);
        #m.life_time = 0;
        
        m.life_time = 900;
        
        m.id = m.ai.getNode("id", 1);
        m.callsign = m.ai.getNode("callsign", 1);
        
        #coordinate tree
        m.lat = m.ai.getNode("position/latitude-deg", 1);
        m.long = m.ai.getNode("position/longitude-deg", 1);
        m.alt = m.ai.getNode("position/altitude-ft", 1);
        
        #Orientation tree
        m.hdgN   = m.ai.getNode("orientation/true-heading-deg", 1);
        m.pitchN = m.ai.getNode("orientation/pitch-deg", 1);
        m.rollN  = m.ai.getNode("orientation/roll-deg", 1);
        
        #Radar Stuff
        m.radarRangeNM = m.ai.getNode("radar/range-nm", 1);
        m.radarbearingdeg = m.ai.getNode("radar/bearing-deg", 1);
        m.radarInRange = m.ai.getNode("radar/in-range", 1);
        m.elevN = m.ai.getNode("radar/elevation-deg", 1);
        m.hOffsetN = m.ai.getNode("radar/h-offset", 1);
        m.vOffsetN = m.ai.getNode("radar/v-offset", 1);
        
        # Speed
        m.ktasN = m.ai.getNode("velocities/true-airspeed-kt", 1);
        m.vertN = m.ai.getNode("velocities/vertical-speed-fps", 1);
        
        #Data comming from the dialog box
        m.dialog_lat = props.globals.getNode("/sim/dialog/groundtTargeting/target-latitude-deg");
        m.dialog_lon = props.globals.getNode("/sim/dialog/groundtTargeting/target-longitude-deg");
        
        m.coord.set_latlon(m.dialog_lat.getValue(),m.dialog_lon.getValue());    
        var tempAlt = geo.elevation(m.dialog_lat.getValue(), m.dialog_lon.getValue(),10000);
        
        m.alt.setValue(tempAlt==nil?0:tempAlt);
        
        m.following = 0;
        m.TargetedPath = nil;
        
        #AI/mp target Name
        m.AI_MP_targetName = "";
        m.AI_MP_targetCoord = geo.Coord.new();
        
        #Distance for closest AI/MP
        m.minDist = 3000;
        
        return m;
    },
    del: func()
    {
        me.model.remove();
        me.ai.remove();
        del_target();
        
    },
    init: func()
    {
        if(me.dialog_lat.getValue()==nil){
          return;
        }
        
        #We take the coordinates from dialog box
        me.coord.set_latlon(me.dialog_lat.getValue(),me.dialog_lon.getValue());   
        #me.coord.dump();
        
        
        var tempLat = me.coord.lat();
        var tempLon = me.coord.lon();
        
        var test = geo.elevation(tempLat, tempLon,10000);
        test = test ==nil?0:test;
        me.coord.set_alt(test);
        
        #printf("Init Altitude test =%f",test);
        
        var tempAlt = me.coord.alt();
          
        
        #print("Init tempLat:" ~ tempLat ~ "tempLon:" ~ tempLon ~ "tempAlt:" ~ tempAlt);
        
        # there must be value in it
        me.lat.setValue(tempLat);
        me.long.setValue(tempLon);
        me.alt.setValue(tempAlt*M2FT);
        
        me.callsign.setValue("GROUND_TARGET");
        me.id.setValue(-2);
        me.hdgN.setValue(0);
        me.pitchN.setValue(0);
        me.rollN.setValue(0);
        me.radarRangeNM.setValue(10);
        me.radarbearingdeg.setValue(0);
        me.radarInRange.setBoolValue(1);
        me.elevN.setValue(0);
        me.hOffsetN.setValue(0);
        me.vOffsetN.setValue(0);
        me.ktasN.setValue(0);
        me.vertN.setValue(0);
        
        # put value in model
        # beware : No absolute value here but the way to find the property
        me.model.getNode("path", 1).setValue(me.id_model);
        me.model.getNode("latitude-deg-prop", 1).setValue(me.lat.getPath());
        me.model.getNode("longitude-deg-prop", 1).setValue(me.long.getPath());
        me.model.getNode("elevation-ft-prop", 1).setValue(me.alt.getPath());
        me.model.getNode("heading-deg-prop", 1).setValue(me.hdgN.getPath());
        me.model.getNode("pitch-deg-prop", 1).setValue(me.pitchN.getPath());
        me.model.getNode("roll-deg-prop", 1).setValue(me.rollN.getPath());
        me.model.getNode("load", 1).remove();
        
        me.update();
        settimer(func(){ me.del(); }, me.life_time);
    },
    update: func()
    {
        if(me.dialog_lat.getValue()==nil){
          return;
        }
        
        # update me.coord : Could be a selectionnable option. The goal is to be able to select multiple ground target
        
        
        me.coord.set_lat(me.dialog_lat.getValue());
        me.coord.set_lon(me.dialog_lon.getValue());   
        

        var tempGeo = geo.elevation(me.coord.lat(),me.coord.lon());
        if(tempGeo != nil and tempGeo!=0){
          me.coord.set_alt(tempGeo);
          #print("============================= ALT UPDATED =================================");
        }
        
        #me.coord.dump();
        var test = geo.elevation(me.coord.lat(),me.coord.lon());
        #printf("Update Altitude test =%f",test);
        #printf("Update Altitude zero =%f", me.coord.alt()+0.1);
     
        # update Position of the Object
        var tempLat = me.coord.lat();
        var tempLon = me.coord.lon();
        var tempAlt = me.coord.alt()+0.1;
        me.lat.setValue(tempLat);
        me.long.setValue(tempLon);
        me.alt.setValue(tempAlt*M2FT);
        
        var test = geo.elevation(me.lat.getValue(), me.long.getValue(),10000);
        #printf("Update Altitude test2 =%f",test);
        
        # update Distance to aircaft
        me.ac = geo.aircraft_position();
        var alt = me.coord.alt();
        me.distance = me.ac.distance_to(me.coord);
        
        # update bearing
        me.bearing = me.ac.course_to(me.coord);
        
        # update Radar Stuff
        var dalt = alt - me.ac.alt();
        var ac_hdg = getprop("/orientation/heading-deg");
        var ac_pitch = getprop("/orientation/pitch-deg");
        var ac_contact_dist = getprop("/systems/refuel/contact-radius-m");
        var elev = math.atan2(dalt, me.distance) * R2D;
        
        me.radarRangeNM.setValue(me.distance * M2NM);
        me.radarbearingdeg.setValue(me.bearing);
        me.elevN.setDoubleValue(elev);
        me.hOffsetN.setDoubleValue(view.normdeg(me.bearing - ac_hdg));
        me.vOffsetN.setDoubleValue(view.normdeg(elev - ac_pitch));
        
        if(me.following==1){me.focus_on_closest_AI_MP();}
        
        if(MyActualview.getValue() == 10){
          gui.popupTip(sprintf("Distance to target (nm): %.1f", me.radarRangeNM.getValue()));
        }

        settimer(func(){ me.update(); }, 0);
    },
    
    focus_on_closest_AI_MP: func(){
        #In order to make it follow AI/MP target each time we click on the button
        me.TargetedPath = nil;
    
        #Distance variable and closest_c in order to select the contact object
        #The first limitation is to limit in an AI/MP in a circle around target
        var closest_Distance = me.minDist;
        var tempDistance = 0;
        var type = nil;
        var raw_list = nil;
        var c = nil;
        var C_Alt = nil;
        var C_lat = nil;
        var C_lon = nil;
        var Ccoord = geo.Coord.new();
        var Check_Alt = 0;
        var ClosestCoord = geo.Coord.new();
        var index = nil;
        var path = nil;
        var name = "";
        
#         
        #Going to the AI/MP tree
        raw_list = Mp.getChildren();
        foreach(c ; raw_list)
        {
            type = c.getName();
            index = c.getIndex();
            path = c.getPath();

            
            #print("Index:"~index);
            #print("Path:"~path); 
            
            #Looking if the AI MP is valid
            if(! c.getNode("valid", 1).getValue())
            {
                continue;
            }
            #Looking if it fits with the vehicule type (ground) that is at the beguining of this file
            if(listOfGroundOrShipVehicleModels[type] ==1){
              C_Alt = c.getNode("position/altitude-ft");
              C_lat = c.getNode("position/latitude-deg");
              C_lon = c.getNode("position/longitude-deg");
              
              #Eliminate itself
              if(c.getNode("callsign", 1).getValue()=="GROUND_TARGET")
              {
                continue;
              }
                
              if(C_Alt!=nil){
                  
                  
                Ccoord.set_latlon(C_lat.getValue(),C_lon.getValue(),C_Alt.getValue()*FT2M);
                
                #Calculate ground altitude (to allow the following to lock on a rolling aircraft) in meters
                Check_Alt = geo.elevation(Ccoord.lat(),Ccoord.lon(),10000);
                Check_Alt = (Check_Alt != nil and Ccoord.alt() != nil)?(abs(Ccoord.alt() - Check_Alt)<50):0;
                

                
                #Calculate distance
                tempDistance = me.coord.direct_distance_to(Ccoord);
                
                  #Updating coordinates
                  if(tempDistance<closest_Distance and Check_Alt){
                    #print(type ~ " : Distance:"~tempDistance);
                    closest_Distance = tempDistance;
                    ClosestCoord.set(Ccoord);
                    me.AI_MP_targetName = c.getName();
                    me.AI_MP_targetCoord.set(Ccoord);
                    
                #If we have a defined path, that mean we have locked a target. This is disabled for now
                  }elsif(me.TargetedPath == path ){
                    closest_Distance = tempDistance;
                    ClosestCoord.set(Ccoord);
                  }
              }
            }
        }
        
        if(closest_Distance<me.minDist-1){
          me.setCoord(ClosestCoord);
          #print("Name:"~me.AI_MP_targetName);
        }
    
    },
    setCoord:func(new_coord){
      me.coord.set(new_coord);
      # there must be value in it
      me.lat.setValue(me.coord.lat());
      me.long.setValue(me.coord.lon());
      me.alt.setValue(me.coord.alt()*M2FT);
      
      me.dialog_lat.setValue(me.coord.lat());
      me.dialog_lon.setValue(me.coord.lon());
    },
};

var sniping = func(){
  var coord = geo.click_position();
  
  setprop("/sim/dialog/groundtTargeting/target-latitude-deg",coord.lat());
  setprop("/sim/dialog/groundtTargeting/target-longitude-deg",coord.lon());
  #setprop("/sim/dialog/groundtTargeting/target-alt-feet",coord.alt()*M2FT);
  
  gui.dialog_update("Ground_Targeting");

}

#In order to have the right terrain elevation, we have to load the tile.
#For that, we focus the view on the target
var view_GPS_target = func(target)
{

    # We select the missile name
    var targetName = string.replace(target.ai.getPath(), "/ai/models/", "");

    # We memorize the initial view number
    var actualView = getprop("/sim/current-view/view-number");

    # We recreate the data vector to feed the missile_view_handler  
    var data = { node: target.ai, callsign: targetName, root: target.ai.getPath()};

    # We activate the AI view (on this aircraft it is the number 9)
    setprop("/sim/current-view/view-number",9);

    # We feed the handler
    view.missile_view_handler.setup(data);
    
    return actualView;

}

var del_target = func(){
  myGroundTarget = nil;
}

var print_coordinates = func(name,coord){
 print(name ~ " lat: " ~   coord.lat() ~ "; lon:" ~ coord.lat()~ "; alt:" ~ coord.alt());
}
