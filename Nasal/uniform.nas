# Author: NIkolai V. Chr.
#
# Makes a uniform matrix for aircraft space for vertex/fragment shaders.

var heading         = props.globals.getNode("orientation/heading-deg", 0);
var pitch           = props.globals.getNode("orientation/pitch-deg", 0);
var roll            = props.globals.getNode("orientation/roll-deg", 0);
var lon             = props.globals.getNode("position/longitude-deg", 0);
var lat             = props.globals.getNode("position/latitude-deg", 0);
var a               = props.globals.getNode("rendering/aircraft/mat4-0", 1);
var b               = props.globals.getNode("rendering/aircraft/mat4-1", 1);
var c               = props.globals.getNode("rendering/aircraft/mat4-2", 1);
var d               = props.globals.getNode("rendering/aircraft/mat4-3", 1);
var e               = props.globals.getNode("rendering/aircraft/mat4-4", 1);
var f               = props.globals.getNode("rendering/aircraft/mat4-5", 1);
var g               = props.globals.getNode("rendering/aircraft/mat4-6", 1);
var h               = props.globals.getNode("rendering/aircraft/mat4-7", 1);
var i               = props.globals.getNode("rendering/aircraft/mat4-8", 1);
var j               = props.globals.getNode("rendering/aircraft/mat4-9", 1);
var k               = props.globals.getNode("rendering/aircraft/mat4-10", 1);
var l               = props.globals.getNode("rendering/aircraft/mat4-11", 1);
var m               = props.globals.getNode("rendering/aircraft/mat4-12", 1);
var n               = props.globals.getNode("rendering/aircraft/mat4-13", 1);
var o               = props.globals.getNode("rendering/aircraft/mat4-14", 1);
var p               = props.globals.getNode("rendering/aircraft/mat4-15", 1);

var uniform = {
	loop: func {
		me.ownship = geo.aircraft_position();
		me.heading = heading.getValue();
		me.pitch   = pitch.getValue();
		me.roll    = roll.getValue();
		me.lon     = lon.getValue();
		me.lat     = lat.getValue();
		
		#me.rollM  = vector.Math.rollMatrix(me.roll);
        #me.pitchM = vector.Math.pitchMatrix(me.pitch);
        #me.yawM   = vector.Math.yawMatrix(-me.heading);
        
        #me.rotation = vector.Math.multiplyMatrices(me.yawM, vector.Math.multiplyMatrices(me.pitchM, me.rollM));
        
        me.latRad = 90-me.lat;
        me.lonRad = me.lon;
        me.rotZ = vector.Math.zMatrix(-me.lonRad);
        me.rotY = vector.Math.yMatrix(-me.latRad);
        #me.rotZ2 = vector.Math.yawMatrix(180);
        
        #me.rotGeo = vector.Math.multiplyMatrices(me.rotY,me.rotZ );
        me.rotGeo = me.rotY;
        
        #me.rotationGeo1 = vector.Math.yawMatrix(-me.lon+(me.lat>0?180:0));
        #me.rotationGeo1 = vector.Math.yawMatrix(-me.lon+(me.lat>0?180:0));
        
        me.rotation = vector.Math.rotationMatrix3to4(me.rotGeo);
        
        me.translation = [1,0,0,0,
        				  0,1,0,0,
        				  0,0,1,math.sqrt(me.ownship.z()*me.ownship.z()+me.ownship.y()*me.ownship.y()+me.ownship.x()*me.ownship.x()),
        				  0,0,0,1];
        				  
        #me.transformation = vector.Math.multiplyMatrices4(me.translation, me.rotation);
        me.transformation = vector.Math.multiplyMatrices4(me.rotation, me.translation);
        #me.transformation = me.rotation;
        
        a.setDoubleValue(me.transformation[0]);
        b.setDoubleValue(me.transformation[1]);
        c.setDoubleValue(me.transformation[2]);
        d.setDoubleValue(me.transformation[3]);
        e.setDoubleValue(me.transformation[4]);
        f.setDoubleValue(me.transformation[5]);
        g.setDoubleValue(me.transformation[6]);
        h.setDoubleValue(me.transformation[7]);
        i.setDoubleValue(me.transformation[8]);
        j.setDoubleValue(me.transformation[9]);
        k.setDoubleValue(me.transformation[10]);
        l.setDoubleValue(me.transformation[11]);
        m.setDoubleValue(me.transformation[12]);
        n.setDoubleValue(me.transformation[13]);
        o.setDoubleValue(me.transformation[14]);
        p.setDoubleValue(me.transformation[15]);
        #printf("%d %d %d",geo.aircraft_position().x(),geo.aircraft_position().y(),geo.aircraft_position().z());
        settimer(func me.loop(),0);
	},
};

var init = setlistener("/sim/signals/fdm-initialized", func() {
  removelistener(init); # only call once
  uniform.loop();
});

# GEO coords:
# lat,lon (0,0)  = +X (africa)
# lat,lon (0,90) = +Z (northpole)
# lat,lon (90,0) = +Y (thailand)
# That means if +Z is up, +X is forwd, +Y is left

# -lat = +lon=yaw right
# +lat = +lon=yaw right+180