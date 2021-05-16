# Needs vector.nas
#
# Author: Nikolai V. Chr. (FPI location code adapted from Buccaneer aircraft)
#
# Version 1.07
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
		me.slanted       = me.hud3dXTop-me.hud3dXBottom > 0.01;
		
		#printf("HUD 3D. width=%.2f height=%.2f x_pos=%.2f",me.hud3dWidth,me.hud3dHeight,me.hud3dX);
		#printf("HUD canvas. width=%d height=%d pixelX/meter=%.1f",me.canvasWidth,me.canvasHeight,me.pixelPerMeterX);
		
		me.makeProperties_();
		#delete(me,"makeProperties_");
		me.reCalc(1);
	},
	
	reCalc: func (initialization = 0) {
		# if view position has moved and you dont use parallax, call this.
		# 
		if (me.slanted) {
			# TODO: do init here also
			me.length = math.sqrt(me.hud3dHeight*me.hud3dHeight+(me.hud3dXTop-me.hud3dXBottom)*(me.hud3dXTop-me.hud3dXBottom));
			me.slantAngle = math.acos((me.length*me.length+me.hud3dHeight*me.hud3dHeight-(me.hud3dXTop-me.hud3dXBottom)*(me.hud3dXTop-me.hud3dXBottom))/(2*me.length*me.hud3dHeight));			
			me.HorizTopToEye = me.input.viewX.getValue()-me.hud3dXTop;
			me.slantAngleOther = (180-90-me.slantAngle*R2D)*D2R;
			me.extendedHUDToOverEye = me.HorizTopToEye*math.sin(me.slantAngleOther)/math.sin(me.slantAngle)+(me.hud3dTop - me.input.viewZ.getValue());
			me.distanceToBore = me.extendedHUDToOverEye*math.sin(me.slantAngle)/math.sin(me.slantAngleOther);#used
			me.pixelPerMeterYSlant = me.canvasHeight/me.length;#used
			me.boreSlantedDownFromTopMeter =  (me.hud3dTop - me.input.viewZ.getValue())*math.sin(90*D2R)/math.sin(me.slantAngleOther);
			me.centerOffsetSlantedMeter = -1*(me.length*0.5-me.boreSlantedDownFromTopMeter);#used (distance from center origin up to bore [negative number])
			#printf("len=%.3fm angle=%.1fdeg angle2=%.1fdeg boredist=%.3fm borefromtop=%.3fm offset=%.3fm",me.length,me.slantAngle*R2D,me.slantAngleOther*R2D,me.distanceToBore,me.boreSlantedDownFromTopMeter,me.centerOffsetSlantedMeter);
		}
			if (initialization) {
				# calc Y offset from HUD canvas center origin.
				me.centerOffset = -1 * (me.canvasHeight/2 - ((me.hud3dTop - me.input.view0Z.getValue())*me.pixelPerMeterY));#TODO: use originCanvas?
			} elsif (!me.parallax) {
				# calc Y offset from HUD canvas center origin.
				me.centerOffset = -1 * (me.canvasHeight/2 - ((me.hud3dTop - me.input.viewZ.getValue())*me.pixelPerMeterY));
			}
		
	},
	
	hudX3d: func (y) {
		# hud 3D X pos for slanted HUDs. y is pixelPos from bore.
		# only does this for x as Y is less affected by slanting.
		return me.extrapolate(y/me.pixelPerMeterYSlant,-me.boreSlantedDownFromTopMeter,me.length-me.boreSlantedDownFromTopMeter,me.hud3dXTop,me.hud3dXBottom);
	},
	
	getVertDistSlanted: func (pitch) {
		# pixels down from bore on slanted HUD
		me.slantDistMeter = me.distanceToBore*math.sin(-pitch*D2R)/math.sin((180+pitch-me.slantAngle*R2D-90)*D2R);
		
		return me.pixelPerMeterYSlant*me.slantDistMeter;
	},
	
	getVertDistSlantedFromCenter: func (pitch) {
		# pixels down from center origin on slanted HUD
		me.slantDistMeter = me.centerOffsetSlantedMeter+(me.distanceToBore*math.sin(-pitch*D2R)/math.sin((180+pitch-me.slantAngle*R2D-90)*D2R));
		return me.pixelPerMeterYSlant*me.slantDistMeter;
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
	
	getBorePosSlanted: func {
		# returns bore pos in canvas from center origin
		return [0,me.centerOffsetSlantedMeter*me.pixelPerMeterYSlant];
	},
	
	getPosFromCoord: func (gpsCoord, aircraft = nil) {
		# return pos in canvas from center origin
		if (aircraft== nil) {
			me.crft = geo.viewer_position();
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

	    me.pos = me.getCenterPosFromDegs(me.dir_x,-me.dir_y);
	    
	    return [me.pos[0], me.pos[1], me.dir_x,-me.dir_y];
	},
	
	getPosFromDegs:  func (yaw_deg, pitch_deg) {
		# return pos from bore
		
		if (yaw_deg > 89) yaw_deg = 89;
		if (yaw_deg < -89) yaw_deg = -89;
		if (pitch_deg < -89) pitch_deg = -89;
		if (pitch_deg > 89) pitch_deg = 89;
		
		var y = 0;
		var x = 0;
		if (me.slanted) {
			y =  me.getVertDistSlanted(pitch_deg);
			x =  me.pixelPerMeterX*((me.input.viewX.getValue() - me.hudX3d(y)) * math.tan(yaw_deg*D2R));
		} else {
			y = -me.pixelPerMeterY*((me.input.viewX.getValue() - me.hud3dX) * math.tan(pitch_deg*D2R));
			x =  me.pixelPerMeterX*((me.input.viewX.getValue() - me.hud3dX) * math.tan(yaw_deg*D2R));
		}
		return [x,y];
	},
	
	getCenterPosFromDegs:  func (yaw_deg, pitch_deg) {
		# return pos from center origin
		
		if (yaw_deg > 89) yaw_deg = 89;
		if (yaw_deg < -89) yaw_deg = -89;
		if (pitch_deg < -89) pitch_deg = -89;
		if (pitch_deg > 89) pitch_deg = 89;
		
		if (me.slanted) {
			var y = me.getVertDistSlanted(pitch_deg);
			var x =  me.pixelPerMeterX*((me.input.viewX.getValue() - me.hudX3d(y)) * math.tan(yaw_deg*D2R));
			return [x,y+me.centerOffsetSlantedMeter*me.pixelPerMeterYSlant];
		} else {
			var y = -me.pixelPerMeterY*((me.input.viewX.getValue() - me.hud3dX) * math.tan(pitch_deg*D2R));
			var x =  me.pixelPerMeterX*((me.input.viewX.getValue() - me.hud3dX) * math.tan(yaw_deg*D2R));
			return [x,y+me.centerOffset];
		}
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
            return [me.pipAng,me.ll];# notice is radians
        }
        return [0,0];
	},
	
	getPolarFromCenterPos: func (x,y) {
		y -= me.centerOffset;
		return me.getPolarFromBorePos(x,y);
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

	    me.pos = me.getCenterPosFromDegs(me.dir_x,-me.dir_y);
	    
	    me.pos_x = me.clamp(me.pos[0],   clampXmin, clampXmax);
	    me.pos_y = me.clamp(me.pos[1],   clampYmin, clampYmax);

	    return [me.pos_x, me.pos_y];
	},
	
	getFlightPathIndicatorPosWind: func (clampXmin=-1000,clampYmin=-1000,clampXmax=1000,clampYmax=1000) {
		# return pos from canvas center origin
		# notice that this does not give real flightpath location, since wind factors in.
		me.dir_y  = me.input.alpha.getValue();
	    me.dir_x  = me.input.beta.getValue();
	    
	    if (me.dir_x==nil or me.dir_y==nil) {
			me.pos_x = 0;
	    	me.pos_y = 0;		    
		} else{
			me.pos = me.getCenterPosFromDegs(me.dir_x,-me.dir_y);
		    
		    me.pos_x = me.clamp(me.pos[0],   clampXmin, clampXmax);
		    me.pos_y = me.clamp(me.pos[1],   clampYmin, clampYmax);
		}
	    return [me.pos_x, me.pos_y];
	},
	
	getStaticHorizon: func (averagePoint_deg = 7.5) {
		# get translation and rotation for horizon line, static means not centered around FPI.
		# return a vector of 3: translation of main horizon group, rotation of main horizon groups transform, translation of sub horizon group (wherein the line (and pitch ladder) is drawn).
		
		me.rot = -me.input.roll.getValue() * D2R;
    
	    return [[0,me.getCenterOffset()],me.rot,[0, me.getPixelPerDegreeAvg(averagePoint_deg)*me.input.pitch.getValue()]];
	},
	
	getCenterOffset: func {
		if (me.slanted) {
			return me.centerOffsetSlantedMeter*me.pixelPerMeterYSlant;
		} else {
			return me.centerOffset;
		}
	},
	
	getDynamicHorizon: func (averagePoint_deg = 7.5, xMin=1,xMax=1,yMin=1,yMax=1,drift=1, drift_fix=0.0) {
		# get translation and rotation for horizon line, dynamic means centered around FPI.
		# the min max values are faction from center to edge of hud to restrict ladder movement.
		# should be called after getFlightPathIndicatorPos/getFlightPathIndicatorPosWind.
		# return a vector of 3: translation of main horizon group, rotation of main horizon groups transform in radians, translation of sub horizon group (wherein the line (and pitch ladder) is drawn).
		
		me.rot = -me.input.roll.getValue() * D2R;

		me.pos_x_clamp = drift?me.clamp(me.pos_x, -xMin*me.canvasWidth*0.5,xMax*me.canvasWidth*0.5):0;
		me.pos_y_clamp = drift?me.clamp(me.pos_y, -yMin*me.canvasHeight*0.5,yMax*me.canvasHeight*0.5):drift_fix*me.canvasHeight;

	    # now figure out how much we move horizon group laterally, to keep FPI in middle of it.
	    me.pos_y_rel = me.pos_y_clamp - me.getCenterOffset();
	    me.fpi_polar = me.clamp(math.sqrt(me.pos_x_clamp*me.pos_x_clamp+me.pos_y_rel*me.pos_y_rel),0.0001,10000);
	    me.inv_angle = me.clamp(-me.pos_y_rel/me.fpi_polar,-1,1);
	    me.fpi_angle = math.acos(me.inv_angle);
	    if (me.pos_x_clamp < 0) {
	      me.fpi_angle *= -1;
	    }
	    me.fpi_pos_rel_x    = math.sin(me.fpi_angle-me.rot)*me.fpi_polar;
	    
	    return [[0,me.getCenterOffset()],me.rot,[me.fpi_pos_rel_x, me.getPixelPerDegreeAvg(averagePoint_deg)*me.input.pitch.getValue()]];
	},
	
	getPixelPerDegreeAvg: func (averagePoint_deg = 7.5) {
		# return average value, not exact unless parameter match what you multiply it with.
		# the parameter is distance from bore. Typically if the result are to be multiplied on multiple values, use halfway between center and edge of HUD.
		# not slant compatiple yet
		
		if (averagePoint_deg == 0) {
			averagePoint_deg = 0.001;
		}
		return 0.5*(me.pixelPerMeterX+me.pixelPerMeterY)*(((me.input.viewX.getValue() - me.hud3dX) * math.tan(averagePoint_deg*D2R))/averagePoint_deg);
	},
	
	getPixelPerDegreeXAvg: func (averagePoint_deg = 7.5) {
		# return average value, not exact unless parameter match what you multiply it with.
		# the parameter is distance from bore. Typically if the result are to be multiplied on multiple values, use halfway between center and edge of HUD.
		# not slant compatiple yet
		
		if (averagePoint_deg == 0) {
			averagePoint_deg = 0.001;
		}
		return me.pixelPerMeterX*(((me.input.viewX.getValue() - me.hud3dX) * math.tan(averagePoint_deg*D2R))/averagePoint_deg);
	},
	
	getPixelPerDegreeYAvg: func (averagePoint_deg = 7.5) {
		# return average value, not exact unless parameter match what you multiply it with.
		# the parameter is distance from bore. Typically if the result are to be multiplied on multiple values, use halfway between center and edge of HUD.
		# not slant compatiple yet
		
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