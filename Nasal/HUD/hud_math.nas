# Needs vector.nas
#
# Author: Nikolai V. Chr. (FPI location code adapted from Buccaneer aircraft)
#
# Version 1.05
#
# License: GPL 2.0
	
var HudMath = {
	
	init: func (acHudUpperLeft, acHudLowerRight, canvasSize, uvUpperLeft_norm, uvLowerRight_norm, parallax) {
		# acHudUpperLeft, acHudLowerRight: vectors of size 3 that indicates HUD position in 3D world.
		# canvasSize: vector of size 2 that indicates size of canvas.
		# uvUpperLeft_norm, uvLowerRight_norm: normalized UV coordinates of the canvas texture.
		# parallax: If the whole canvas is set to move with head as if focused on infinity.
		#
		# Assumptions is that HUD canvas is vertical aligned and centered in the Y axis. (will though to some degree work with slanted HUDs)
		# Also assumed that UV ratio is not stretched. So that every texel is perfect square formed. (see above)
		# Another assumption is that aircraft bore line is parallel with 3D X axis.
		
		# statics
		me.hud3dWidth    = acHudLowerRight[1]-acHudUpperLeft[1];
		me.hud3dHeight   = acHudUpperLeft[2]-acHudLowerRight[2];
		me.hud3dTop      = acHudUpperLeft[2];
		me.hud3dX        = (acHudUpperLeft[0]+acHudLowerRight[0])*0.5;#average due to slanted HUDs
		me.hud3dXTop     = acHudUpperLeft[0];
		me.hud3dXBottom  = acHudLowerRight[0];
		me.canvasWidth   = (uvLowerRight_norm[0]-uvUpperLeft_norm[0])*canvasSize[0]; 
		me.canvasHeight  = (uvUpperLeft_norm[1]-uvLowerRight_norm[1])*canvasSize[1];
		me.pixelPerMeterY= me.canvasHeight / me.hud3dHeight;# for x and y seperate because some HUDs are slanted
		me.pixelPerMeterX= me.canvasWidth / me.hud3dWidth;
		me.parallax      = parallax;
		me.originCanvas  = [uvUpperLeft_norm[0]*canvasSize[0],(1-uvUpperLeft_norm[1])*canvasSize[1]];
		
		#printf("HUD 3D. width=%.2f height=%.2f x_pos=%.2f",me.hud3dWidth,me.hud3dHeight,me.hud3dX);
		#printf("HUD canvas. width=%d height=%d pixelX/meter=%.1f",me.canvasWidth,me.canvasHeight,me.pixelPerMeterX);
		
		me.makeProperties_();
		delete(me,"makeProperties_");
		me.reCalc(1);
	},
	
	reCalc: func (initialization = 0) {
		# if view position has moved and you dont use parallax, call this.
		# 
		if (initialization) {
			# calc Y offset from HUD canvas center origin.
			me.centerOffset = -1 * (me.canvasHeight/2 - ((me.hud3dTop - me.input.view0Z.getValue())*me.pixelPerMeterY));#TODO: use originCanvas?
		} elsif (!me.parallax) {
			# calc Y offset from HUD canvas center origin.
			me.centerOffset = -1 * (me.canvasHeight/2 - ((me.hud3dTop - me.input.viewZ.getValue())*me.pixelPerMeterY));
		}
	},
	
	getCenterOrigin: func {
		# returns center origin in canvas from origin (0,0)
		#
		# most methods in the library assumes that your root group has been moved to this position.
		return [me.originCanvas[0]+me.canvasWidth*0.5,me.originCanvas[1]+me.canvasHeight*0.5];
	},
	
	getBorePos: func {
		# returns bore pos in canvas from center origin
		return [0,me.centerOffset];
	},	
	
	getPosFromCoord: func (gpsCoord, aircraft = nil) {
		# return pos in canvas from center origin
		if (aircraft== nil) {
			me.crft = geo.aircraft_position();
		} else {
			me.crft = aircraft;
		}
		me.ptch = vector.Math.getPitch(me.crft,gpsCoord);
	    me.dst  = me.crft.direct_distance_to(gpsCoord);
	    me.brng = me.crft.course_to(gpsCoord);
	    me.hrz  = math.cos(me.ptch*D2R)*me.dst;

	    me.vel_gz = -math.sin(me.ptch*D2R)*me.dst;
	    me.vel_gx = math.cos(me.brng*D2R) *me.hrz;
	    me.vel_gy = math.sin(me.brng*D2R) *me.hrz;
	    

	    me.yaw   = me.input.hdgTrue.getValue() * D2R;
	    me.roll  = me.input.roll.getValue()    * D2R;
	    me.pitch = me.input.pitch.getValue()   * D2R;

	    me.sy = math.sin(me.yaw);   me.cy = math.cos(me.yaw);
	    me.sr = math.sin(me.roll);  me.cr = math.cos(me.roll);
	    me.sp = math.sin(me.pitch); me.cp = math.cos(me.pitch);
	 
	    me.vel_bx = me.vel_gx * me.cy * me.cp
	               + me.vel_gy * me.sy * me.cp
	               + me.vel_gz * -me.sp;
	    me.vel_by = me.vel_gx * (me.cy * me.sp * me.sr - me.sy * me.cr)
	               + me.vel_gy * (me.sy * me.sp * me.sr + me.cy * me.cr)
	               + me.vel_gz * me.cp * me.sr;
	    me.vel_bz = me.vel_gx * (me.cy * me.sp * me.cr + me.sy * me.sr)
	               + me.vel_gy * (me.sy * me.sp * me.cr - me.cy * me.sr)
	               + me.vel_gz * me.cp * me.cr;
	 
	    me.dir_y  = math.atan2(me.round0_(me.vel_bz), math.max(me.vel_bx, 0.001)) * R2D;
	    me.dir_x  = math.atan2(me.round0_(me.vel_by), math.max(me.vel_bx, 0.001)) * R2D;

	    me.pos = me.getPosFromDegs(me.dir_x,-me.dir_y);
	    
	    me.pos_xx = me.pos[0];# cannot be named pos_x as that is assumed to be FPI position.
	    me.pos_yy = me.pos[1]+me.centerOffset;

	    return [me.pos_xx, me.pos_yy];
	},
	
	getPosFromDegs:  func (yaw_deg, pitch_deg) {
		# return pos from bore
		var y = -me.pixelPerMeterY*((me.input.viewX.getValue() - me.hud3dX) * math.tan(pitch_deg*D2R));
		var x =  me.pixelPerMeterX*((me.input.viewX.getValue() - me.hudX3d(y)) * math.tan(yaw_deg*D2R));
		return [x,y];
	},
	
	getCenterPosFromDegs:  func (yaw_deg, pitch_deg) {
		# return pos from center origin
		var y = -me.pixelPerMeterY*((me.input.viewX.getValue() - me.hud3dX) * math.tan(pitch_deg*D2R));
		var x =  me.pixelPerMeterX*((me.input.viewX.getValue() - me.hudX3d(y)) * math.tan(yaw_deg*D2R));
		return [x,y+me.centerOffset];
	},
	
	isCanvasPosClamped: func (x,y) {
		if (x>me.originCanvas[0]+me.canvasWidth or x<me.originCanvas[0] or y >me.originCanvas[1]+me.canvasHeight or y<me.originCanvas[1]) {
			return 1;
		}
		return 0;
	},
	
	isCenterPosClamped: func (x,y) {
		x += me.getCenterOrigin()[0];
		y += me.getCenterOrigin()[1];
		
		return me.isCanvasPosClamped(x,y);
	},
	
	getPosFromPolar:  func (meter, angle_deg) {
		# return pos from center origin (not tested)
		me.xxx =  me.pixelPerMeterX * meter * math.sin(angle_deg*D2R);
        me.yyy = -me.pixelPerMeterY * meter * math.cos(angle_deg*D2R);
        return [me.xxx, me.yyy+me.centerOffset];
	},
	
	getPolarFromBorePos: func (x,y) {
		me.ll = math.sqrt(x*x+y*y);
        if (me.ll != 0) {
        	me.pipAng = math.atan2(x,-y);
            #me.pipAng = math.acos(x/me.ll);
            #if (y < 0) {
            #    me.pipAng *= -1;
            #}
            return [me.pipAng,me.ll];# notice is radians
        }
        return [0,0];
	},
	
	getPolarFromCenterPos: func (x,y) {
		y -= me.centerOffset;
		return me.getPolarFromBorePos(x,y);
	},
	
	#getEyeToHudDistance: func {
	#	return me.input.viewX.getValue() - me.hud3dX;
	#},
	
	hudX3d: func (y) {
		# hud 3D X pos for slanted HUDs
		# only does this for x as Y is less affected by slanting.
		return me.extrapolate(y+me.centerOffset,-me.canvasHeight*0.5,me.canvasHeight*0.5,me.hud3dXTop,me.hud3dXBottom);
	},
	
	getFlightPathIndicatorPos: func (clampXmin=-1000,clampYmin=-1000,clampXmax=1000,clampYmax=1000) {
		# return pos from canvas center origin
		# notice that this gives real flightpath location, not influenced by wind. (use the wind for yasim, as there is an issue with that somehow)
		me.vel_gx = me.input.speed_n.getValue();
	    me.vel_gy = me.input.speed_e.getValue();
	    me.vel_gz = me.input.speed_d.getValue();

	    me.yaw = me.input.hdgTrue.getValue() * D2R;
	    me.roll = me.input.roll.getValue() * D2R;
	    me.pitch = me.input.pitch.getValue() * D2R;

	    if (math.sqrt(me.vel_gx *me.vel_gx+me.vel_gy*me.vel_gy+me.vel_gz*me.vel_gz)<15) {
	      # we are pretty much still, point the vector along axis.
	      me.vel_gx = math.cos(me.yaw)*1;
	      me.vel_gy = math.sin(me.yaw)*1;
	      me.vel_gz = 0;
	    }
	 
	    me.sy = math.sin(me.yaw);   me.cy = math.cos(me.yaw);
	    me.sr = math.sin(me.roll);  me.cr = math.cos(me.roll);
	    me.sp = math.sin(me.pitch); me.cp = math.cos(me.pitch);
	 
	    me.vel_bx = me.vel_gx * me.cy * me.cp
	               + me.vel_gy * me.sy * me.cp
	               + me.vel_gz * -me.sp;
	    me.vel_by = me.vel_gx * (me.cy * me.sp * me.sr - me.sy * me.cr)
	               + me.vel_gy * (me.sy * me.sp * me.sr + me.cy * me.cr)
	               + me.vel_gz * me.cp * me.sr;
	    me.vel_bz = me.vel_gx * (me.cy * me.sp * me.cr + me.sy * me.sr)
	               + me.vel_gy * (me.sy * me.sp * me.cr - me.cy * me.sr)
	               + me.vel_gz * me.cp * me.cr;
	 
	    me.dir_y  = math.atan2(me.round0_(me.vel_bz), math.max(me.vel_bx, 0.001)) * R2D;
	    me.dir_x  = math.atan2(me.round0_(me.vel_by), math.max(me.vel_bx, 0.001)) * R2D;

	    me.pos = me.getPosFromDegs(me.dir_x,-me.dir_y);
	    
	    me.pos_x = me.clamp(me.pos[0],                   clampXmin, clampXmax);
	    me.pos_y = me.clamp(me.pos[1]+me.centerOffset,   clampYmin, clampYmax);

	    return [me.pos_x, me.pos_y];
	},
	
	getFlightPathIndicatorPosWind: func (clampXmin=-1000,clampYmin=-1000,clampXmax=1000,clampYmax=1000) {
		# return pos from canvas center origin
		# notice that this does not give real flightpath location, since wind factors in.
		me.dir_y  = me.input.alpha.getValue();
	    me.dir_x  = me.input.beta.getValue();
	    
	    me.pos = me.getPosFromDegs(me.dir_x,-me.dir_y);
	    
	    me.pos_x = me.clamp(me.pos[0],                   clampXmin, clampXmax);
	    me.pos_y = me.clamp(me.pos[1]+me.centerOffset,   clampYmin, clampYmax);

	    return [me.pos_x, me.pos_y];
	},
	
	getStaticHorizon: func (averagePoint_deg = 7.5) {
		# get translation and rotation for horizon line, static means not centered around FPI.
		# return a vector of 3: translation of main horizon group, rotation of main horizon groups transform, translation of sub horizon group (wherein the line (and pitch ladder) is drawn).
		
		me.rot = -me.input.roll.getValue() * D2R;
    
	    return [[0,me.centerOffset],me.rot,[0, me.getPixelPerDegreeAvg(averagePoint_deg)*me.input.pitch.getValue()]];
	},
	
	getDynamicHorizon: func (averagePoint_deg = 7.5) {
		# get translation and rotation for horizon line, dynamic means centered around FPI.
		# should be called after getFlightPathIndicatorPos/getFlightPathIndicatorPosWind.
		# return a vector of 3: translation of main horizon group, rotation of main horizon groups transform in radians, translation of sub horizon group (wherein the line (and pitch ladder) is drawn).
		
		me.rot = -me.input.roll.getValue() * D2R;

	    # now figure out how much we move horizon group laterally, to keep FPI in middle of it.
	    me.pos_y_rel = me.pos_y - me.centerOffset;
	    me.fpi_polar = me.clamp(math.sqrt(me.pos_x*me.pos_x+me.pos_y_rel*me.pos_y_rel),0.0001,10000);
	    me.inv_angle = me.clamp(-me.pos_y_rel/me.fpi_polar,-1,1);
	    me.fpi_angle = math.acos(me.inv_angle);
	    if (me.pos_x < 0) {
	      me.fpi_angle *= -1;
	    }
	    me.fpi_pos_rel_x    = math.sin(me.fpi_angle-me.rot)*me.fpi_polar;
	    
	    return [[0,me.centerOffset],me.rot,[me.fpi_pos_rel_x, me.getPixelPerDegreeAvg(averagePoint_deg)*me.input.pitch.getValue()]];
	},
	
	getPixelPerDegreeAvg: func (averagePoint_deg = 7.5) {
		# return average value, not exact unless parameter match what you multiply it with.
		# the parameter is distance from bore. Typically if the result are to be multiplied on multiple values, use halfway between center and edge of HUD.
		if (averagePoint_deg == 0) {
			averagePoint_deg = 0.001;
		}
		return 0.5*(me.pixelPerMeterX+me.pixelPerMeterY)*(((me.input.viewX.getValue() - me.hud3dX) * math.tan(averagePoint_deg*D2R))/averagePoint_deg);
	},
	
	getPixelPerDegreeXAvg: func (averagePoint_deg = 7.5) {
		# return average value, not exact unless parameter match what you multiply it with.
		# the parameter is distance from bore. Typically if the result are to be multiplied on multiple values, use halfway between center and edge of HUD.
		if (averagePoint_deg == 0) {
			averagePoint_deg = 0.001;
		}
		return me.pixelPerMeterX*(((me.input.viewX.getValue() - me.hud3dX) * math.tan(averagePoint_deg*D2R))/averagePoint_deg);
	},
	
	getPixelPerDegreeYAvg: func (averagePoint_deg = 7.5) {
		# return average value, not exact unless parameter match what you multiply it with.
		# the parameter is distance from bore. Typically if the result are to be multiplied on multiple values, use halfway between center and edge of HUD.
		if (averagePoint_deg == 0) {
			averagePoint_deg = 0.001;
		}
		return me.pixelPerMeterY*(((me.input.viewX.getValue() - me.hud3dX) * math.tan(averagePoint_deg*D2R))/averagePoint_deg);
	},
	
	round0_: func(x) {
		return math.abs(x) > 0.01 ? x : 0;
	},
	
	clamp: func(v, min, max) {
		return v < min ? min : v > max ? max : v;
	},
	
	extrapolate: func (x, x1, x2, y1, y2) {
    	return y1 + ((x - x1) / (x2 - x1)) * (y2 - y1);
	},
	
	makeProperties_: func {
		me.input = {
	        alpha:            "orientation/alpha-deg",
	        beta:             "orientation/side-slip-deg",
	        hdg:              "orientation/heading-magnetic-deg",
	        hdgTrue:          "orientation/heading-deg",
	        pitch:            "orientation/pitch-deg",
	        roll:             "orientation/roll-deg",
	        speed_d:          "velocities/speed-down-fps",
	        speed_e:          "velocities/speed-east-fps",
	        speed_n:          "velocities/speed-north-fps",
	        viewNumber:       "sim/current-view/view-number",
	        view0Z:           "sim/view[0]/config/y-offset-m",
	        view0X:           "sim/view[0]/config/z-offset-m",
	        viewZ:            "sim/current-view/y-offset-m",
	        viewX:            "sim/current-view/z-offset-m",
      	};
   
      	foreach(var name; keys(me.input)) {
        	me.input[name] = props.globals.getNode(me.input[name], 1);
      	}
	},
};