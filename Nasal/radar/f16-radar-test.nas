


#############################
# test code below this line #
#############################





var enableTests = 1;
var enableRWR = 1;
var enableRWRs = 1;




var clamp = func(v, min, max) { v < min ? min : v > max ? max : v }










#  ██████  ██████  ██ 
#  ██   ██ ██   ██ ██ 
#  ██████  ██████  ██ 
#  ██      ██      ██ 
#  ██      ██      ██ 
#                     
#                     
RadarViewPPI = {
# implements radar/RWR display on CRT/MFD
# also slew cursor to select contacts.
# fast loop
#
# Attributes:
#   link to Radar
#   link to FireControl
	new: func {
		me.window = canvas.Window.new([256, 256],"dialog")
				.set('x', 256)
				#.set('y', 350)
                .set('title', "Radar PPI");
		var root = me.window.getCanvas(1).createGroup();
		me.window.getCanvas(1).setColorBackground(0,0,0);
		me.rootCenter = root.createChild("group")
				.setTranslation(128,256);
		me.rootCenterBleps = root.createChild("group")
				.setTranslation(128,256);
		me.sweepDistance = 128/math.cos(30*D2R);
		me.sweep = me.rootCenter.createChild("path")
				.moveTo(0,0)
				.vert(-me.sweepDistance)
				.setStrokeLineWidth(2.5)
				.setColor(1,1,1);
		me.sweepA = me.rootCenter.createChild("path")
				.moveTo(0,0)
				.vert(-me.sweepDistance)
				.setStrokeLineWidth(1)
				.setColor(0.5,0.5,1);
		me.sweepB = me.rootCenter.createChild("path")
				.moveTo(0,0)
				.vert(-me.sweepDistance)
				.setStrokeLineWidth(1)
				.setColor(0.5,0.5,1);
		me.text = root.createChild("text")
	      .setAlignment("left-top")
      	  .setFontSize(10, 1.0)
	      .setColor(1, 1, 1);
	    me.text2 = root.createChild("text")
	      .setAlignment("left-top")
      	  .setFontSize(10, 1.0)
      	  .setTranslation(0,15)
	      .setColor(1, 1, 1);
	    me.text3 = root.createChild("text")
	      .setAlignment("left-top")
      	  .setFontSize(10, 1.0)
      	  .setTranslation(0,30)
	      .setColor(1, 1, 1);
	    me.text4 = root.createChild("text")
	      .setAlignment("left-top")
      	  .setFontSize(10, 1.0)
      	  .setTranslation(0,45)
	      .setColor(1, 1, 1);
	    me.text5 = root.createChild("text")
	      .setAlignment("left-top")
      	  .setFontSize(10, 1.0)
      	  .setTranslation(0,60)
	      .setColor(1, 1, 1);
	    me.text6 = root.createChild("text")
	      .setAlignment("left-top")
      	  .setFontSize(10, 1.0)
      	  .setTranslation(0,75)
	      .setColor(1, 1, 1);

	    me.blep = setsize([],200);
        for (var i = 0;i<200;i+=1) {
        	me.blep[i] = me.rootCenterBleps.createChild("path")
					.moveTo(0,0)
					.vert(2)
					.setStrokeLineWidth(2)
	      	  		.hide();
        }
        me.lock = setsize([],20);
        for (var i = 0;i<20;i+=1) {
        	me.lock[i] = me.rootCenterBleps.createChild("path")
						.moveTo(-5,-5)
							.vert(10)
							.horiz(10)
							.vert(-10)
							.horiz(-10)
							.moveTo(0,-5)
							.vert(-5)
							.setStrokeLineWidth(1)
	      	  		.hide();
        }
        	me.select = me.rootCenterBleps.createChild("path")
						.moveTo(-8, 0)
			            .arcSmallCW(8, 8, 0, 8*2, 0)
			            .arcSmallCW(8, 8, 0, -8*2, 0)
						.setColor([1,1,0])
						.setStrokeLineWidth(1)
	      	  		.hide();

		var mt = maketimer(scanInterval,func me.loop());
        mt.start();
		return me;
	},

	loop: func {
		if (!enableTests) {return;}
		me.sweep.setRotation(apg68Radar.positionCart[2]*D2R);
		me.sweep.update();
		if (apg68Radar.showAZ()) {
			me.sweepA.show();
			me.sweepB.show();
			me.sweepA.setRotation((apg68Radar.currentMode.azimuthTilt-apg68Radar.currentMode.az)*D2R);
			me.sweepB.setRotation((apg68Radar.currentMode.azimuthTilt+apg68Radar.currentMode.az)*D2R);
		} else {
			me.sweepA.hide();
			me.sweepB.hide();
		}
		me.elapsed = getprop("sim/time/elapsed-sec");
		#me.rootCenterBleps.removeAllChildren();
		me.i = 0;
		me.bug = 0;
		me.track = 0;
		me.ii = 0;
		foreach(contact; apg68Radar.vector_aicontacts_bleps) {
			foreach(me.bleppy; contact.getBleps()) {
				# blep: time, rcs_strength, dist, heading, deviations vector, speed, closing-rate, altitude
				if (me.elapsed - me.bleppy[0] < apg68Radar.currentMode.timeToKeepBleps and (me.bleppy[2] != nil or (me.bleppy[6] != nil and me.bleppy[6]>0))) {
					if (me.bleppy[6] != nil and apg68Radar.currentMode.longName == "Velocity Search") {
						me.distPixels = me.bleppy[6]*(me.sweepDistance/(1000));
					} elsif (me.bleppy[2] != nil) {
						me.distPixels = me.bleppy[2]*(me.sweepDistance/(apg68Radar.getRange()*NM2M));
					} else {
						continue;
					}
					
					me.color = math.pow(1-(me.elapsed - me.bleppy[0])/apg68Radar.currentMode.timeToKeepBleps, 2.2);
					me.blep[me.i].setColor(me.color,me.color,me.color);
					me.blep[me.i].setTranslation(-me.distPixels*math.cos(me.bleppy[4][0]*D2R+math.pi/2),-me.distPixels*math.sin(me.bleppy[4][0]*D2R+math.pi/2));
					me.blep[me.i].show();
					me.blep[me.i].update();
					me.i += 1;
					if (me.i > 199) break;
				}
			}
			me.sizeBleps = size(contact.getBleps());
			if (me.sizeBleps and me.ii < 20 and contact.hadTrackInfo()) {
				me.bleppy = contact.getBleps()[me.sizeBleps-1];
				if (me.bleppy[3] != nil) {
					me.rot = me.bleppy[3];
					me.rot = me.rot-self.getHeading();
					me.lock[me.ii].setRotation(me.rot*D2R);
					me.lock[me.ii].setColor([1,1,0]);
					me.lock[me.ii].setTranslation(-me.distPixels*math.cos(me.bleppy[4][0]*D2R+math.pi/2),-me.distPixels*math.sin(me.bleppy[4][0]*D2R+math.pi/2));
					me.lock[me.ii].show();
					me.lock[me.ii].update();
					me.ii += 1;
				}
			}
			if (contact.equals(apg68Radar.getPriorityTarget()) and me.sizeBleps) {
				me.bleppy = contact.getBleps()[me.sizeBleps-1];
				me.select.setTranslation(-me.distPixels*math.cos(me.bleppy[4][0]*D2R+math.pi/2),-me.distPixels*math.sin(me.bleppy[4][0]*D2R+math.pi/2));
				me.select.show();
				me.select.update();
				me.bug = 1;
			}
			if (me.i > 199) break;
		}
		for (;me.i<200;me.i+=1) {
			me.blep[me.i].hide();
		}
		for (;me.ii<20;me.ii+=1) {
			me.lock[me.ii].hide();
		}
		if (!me.bug) me.select.hide();
		if (apg68Radar.tiltOverride) {
			me.text.setText("Antennae elevation knob override");
		} else {
			me.text.setText(sprintf("Antennae elevation knob: %d degs", apg68Radar.getTilt()));
		}
		me.md = apg68Radar.currentMode.longName;
		me.text2.setText(me.md);
		me.prioName = apg68Radar.getPriorityTarget();
		if (me.prioName != nil) {
			me.text3.setText(sprintf("Priority: %s", me.prioName.callsign));
			if (me.prioName.getLastRangeDirect() != nil and me.prioName.getLastAltitude() != nil) {
				me.text4.setText(sprintf("Range: %2d  Angels: %2d", me.prioName.getLastRangeDirect()*M2NM, math.round(me.prioName.getLastAltitude()*0.001)));
			}
		} else {
			me.text3.setText("");
			me.text4.setText("");
		}
		me.text5.setText("Frame time "~sprintf("%.1f",math.round(10*apg68Radar.currentMode.lastFrameDuration)*0.1)~" seconds");
		if (apg68Radar.currentMode.longName == "Track While Scan") {
			me.text6.setText("Tracking " ~size(apg68Radar.currentMode.currentTracked));
		} elsif (apg68Radar.currentMode.shortName != "STT" and apg68Radar.currentMode.shortName != "FTT") {
			me.text6.setText("Target history " ~ apg68Radar.targetHistory);
		} else {
			me.text6.setText("");
		}
	},
	del: func {
		me.window.del();
        #emesary.GlobalTransmitter.DeRegister(f16_hmd);
    },
};


#  ██████        ███████  ██████  ██████  ██████  ███████ 
#  ██   ██       ██      ██      ██    ██ ██   ██ ██      
#  ██████  █████ ███████ ██      ██    ██ ██████  █████   
#  ██   ██            ██ ██      ██    ██ ██      ██      
#  ██████        ███████  ██████  ██████  ██      ███████ 
#                                                         
#                                                         
RadarViewBScope = {
# implements radar/RWR display on CRT/MFD
# also slew cursor to select contacts.
# fast loop
#
# Attributes:
#   link to Radar
#   link to FireControl
	new: func {
		me.window = canvas.Window.new([256, 256],"dialog")
				.set('x', 550)
                .set('title', "Radar B-Scope");
		var root = me.window.getCanvas(1).createGroup();
		me.window.getCanvas(1).setColorBackground(0,0,0);
		me.rootCenter = root.createChild("group")
				.setTranslation(128,256);
		me.rootCenterBleps = root.createChild("group")
				.setTranslation(128,256);
		me.cursor = me.rootCenter.createChild("path")
				.moveTo(-5,-5)
				.vert(10)
				.moveTo(5,-5)
				.vert(10)
				.setStrokeLineWidth(1)
				.setColor(1,1,1);
		me.sweepAz = me.rootCenter.createChild("path")
				.moveTo(0,0)
				.vert(-10)
				.moveTo(-5,-10)
				.horiz(10)
				.setStrokeLineWidth(2.5)
				.setColor(1,1,1);
		me.sweepBa = me.rootCenter.createChild("path")
				.moveTo(-128,-128)
				.horiz(10)
				.moveTo(-118,-123)
				.vert(-10)
				.setStrokeLineWidth(2.5)
				.setColor(1,1,1);
		me.sweepA = me.rootCenter.createChild("path")
				.moveTo(0,0)
				.vert(-256)
				.setStrokeLineWidth(1)
				.setColor(0.5,0.5,1);
		me.sweepB = me.rootCenter.createChild("path")
				.moveTo(0,0)
				.vert(-256)
				.setStrokeLineWidth(1)
				.setColor(0.5,0.5,1);
		
	    me.r = root.createChild("text")
	      .setAlignment("left-center")
      	  .setFontSize(10, 1.0)
      	  .setTranslation(10,50)
	      .setColor(1, 1, 1);
	    me.b = root.createChild("text")
	      .setAlignment("left-center")
      	  .setFontSize(10, 1.0)
      	  .setTranslation(10,100)
	      .setColor(1, 1, 1);
	    me.a = root.createChild("text")
	      .setAlignment("left-center")
      	  .setFontSize(10, 1.0)
      	  .setTranslation(10,150)
	      .setColor(1, 1, 1);
	    me.rootName = root.createChild("text")
	      .setAlignment("center-top")
      	  .setFontSize(10, 1.0)
      	  .setTranslation(1*256/6,10)
	      .setColor(1, 1, 1);
	    me.shortName = root.createChild("text")
	      .setAlignment("center-top")
      	  .setFontSize(10, 1.0)
      	  .setTranslation(2*256/6,10)
	      .setColor(1, 1, 1);

	    me.blep = setsize([],200);
        for (var i = 0;i<200;i+=1) {
        	me.blep[i] = me.rootCenterBleps.createChild("path")
					.moveTo(0,-1)
					.vert(3)
					.setStrokeLineWidth(3)
					.setStrokeLineCap("butt")
	      	  		.hide();
        }
        me.lock = setsize([],20);
        me.lockv = setsize([],20);
        me.lockvl = setsize([],20);
        me.lockt = setsize([],20);
        me.locky = setsize([],20);
        for (var i = 0;i<20;i+=1) {
        	me.lock[i] = me.rootCenterBleps.createChild("group");
        	me.locky[i] = me.lock[i].createChild("path")
							.moveTo(-7,4)
							.horiz(14)
							.lineTo(0,-8)
							.lineTo(-7,4)
							.setStrokeLineWidth(1)
							.setColor([1,1,0]);
			me.lockv[i] = me.lock[i].createChild("group");
			me.lockvl[i] = me.lockv[i].createChild("path")
							.lineTo(0,-10)
							.setTranslation(0,-8)
							.setStrokeLineWidth(1)
							.setColor([1,1,0]);
			me.lockt[i] = me.lock[i].createChild("text")
							      .setAlignment("center-top")
						      	  .setFontSize(10, 1.0)
						      	  .setTranslation(0,10)
							      .setColor(1, 1, 1);
        }
        me.select = me.rootCenterBleps.createChild("path")
						.moveTo(-8, 0)
			            .arcSmallCW(8, 8, 0, 8*2, 0)
			            .arcSmallCW(8, 8, 0, -8*2, 0)
						.setColor([1,1,0])
						.setStrokeLineWidth(1);

		var mt = maketimer(scanInterval,func me.loop());
        mt.start();
		return me;
	},

	loop: func {
		if (!enableTests) {return;}
		me.cursor.setTranslation(128*apg68Radar.getCursorDeviation()/60,-128);
		me.sweepAz.setTranslation(128*apg68Radar.positionCart[0],0);
		me.sweepBa.setTranslation(0,-128*apg68Radar.positionCart[1]);
		me.sweepAz.update();
		me.sweepBa.update();
		if (apg68Radar.showAZ()) {
			me.sweepA.show();
			me.sweepB.show();
			me.sweepA.setTranslation(128*(apg68Radar.currentMode.azimuthTilt-apg68Radar.currentMode.az)/60,0);
			me.sweepB.setTranslation(128*(apg68Radar.currentMode.azimuthTilt+apg68Radar.currentMode.az)/60,0);
		} else {
			me.sweepA.hide();
			me.sweepB.hide();
		}
		me.elapsed = getprop("sim/time/elapsed-sec");
		me.i = 0;
		me.bug = 0;
		me.track = 0;
		me.ii = 0;
		foreach(contact; apg68Radar.vector_aicontacts_bleps) {
			foreach(me.bleppy; contact.getBleps()) {
				# blep: time, rcs_strength, dist, heading, deviations vector, speed, closing-rate, altitude
				if (me.elapsed - me.bleppy[0] < apg68Radar.currentMode.timeToKeepBleps and (me.bleppy[2] != nil or (me.bleppy[6] != nil and me.bleppy[6]>0))) {
					if (me.bleppy[6] != nil and apg68Radar.currentMode.longName == "Velocity Search") {
						me.distPixels = me.bleppy[6]*(256/(1000));
					} elsif (me.bleppy[2] != nil) {
						me.distPixels = me.bleppy[2]*(256/(apg68Radar.getRange()*NM2M));
					} else {
						continue;
					}
					me.color = math.pow(1-(me.elapsed - me.bleppy[0])/apg68Radar.currentMode.timeToKeepBleps, 2.2);
					me.blep[me.i].setColor(me.color,me.color,me.color);
					me.blep[me.i].setTranslation(128*me.bleppy[4][0]/60,-me.distPixels);
					me.blep[me.i].show();
					me.blep[me.i].update();
					me.i += 1;
					if (me.i > 199) break;
				}
			}
			me.sizeBleps = size(contact.getBleps());
			if (me.sizeBleps and me.ii < 20 and contact.hadTrackInfo()) {
				me.bleppy = contact.getBleps()[me.sizeBleps-1];
				if (me.bleppy[3] != nil and me.elapsed - me.bleppy[0] < apg68Radar.currentMode.timeToKeepBleps) {
					me.rot = 22.5*math.round((me.bleppy[3]-self.getHeading()-me.bleppy[4][0])/22.5);
					me.locky[me.ii].setRotation(me.rot*D2R);
					me.lock[me.ii].setTranslation(128*me.bleppy[4][0]/60,-me.distPixels);
					if (me.bleppy[5] != nil and me.bleppy[5] > 0) {
						me.lockvl[me.ii].setScale(1,me.bleppy[5]*0.0025);
						me.lockv[me.ii].setRotation(me.rot*D2R);
						me.lockv[me.ii].update();
						me.lockv[me.ii].show();
					} else {
						me.lockv[me.ii].hide();
					}
					if (me.bleppy[7] != nil) {
						me.lockt[me.ii].setText(""~math.round(me.bleppy[7]*0.001));
					} else {
						me.lockt[me.ii].setText("");
					}
					me.lock[me.ii].setVisible(apg68Radar.currentMode.longName != "Track While Scan" or (me.elapsed - me.bleppy[0] < apg68Radar.currentMode.maxScanIntervalForTrack));
					me.lock[me.ii].update();
					me.ii += 1;
				}
			}
			if (contact.equals(apg68Radar.getPriorityTarget()) and me.sizeBleps) {
				me.bleppy = contact.getBleps()[me.sizeBleps-1];
				me.select.setTranslation(128*me.bleppy[4][0]/60,-me.distPixels);
				me.select.setVisible(apg68Radar.currentMode.longName != "Track While Scan" or (me.elapsed - me.bleppy[0] < 8) or (math.mod(me.elapsed,0.50)<0.25));
				me.select.update();
				me.bug = 1;
			}
			if (me.i > 199) break;
		}
		for (;me.i<200;me.i+=1) {
			me.blep[me.i].hide();
		}
		for (;me.ii<20;me.ii+=1) {
			me.lock[me.ii].hide();
		}
		if (!me.bug) me.select.hide();
		
		var a = 0;
		if (apg68Radar.getAzimuthRadius() < 20) {
			a = 1;
		} elsif (apg68Radar.getAzimuthRadius() < 30) {
			a = 2;
		} elsif (apg68Radar.getAzimuthRadius() < 40) {
			a = 3;
		} elsif (apg68Radar.getAzimuthRadius() < 50) {
			a = 4;
		} elsif (apg68Radar.getAzimuthRadius() < 60) {
			a = 5;
		} elsif (apg68Radar.getAzimuthRadius() < 70) {
			a = 6;
		}
		if (apg68Radar.currentMode.showBars()) {
			var b = apg68Radar.getBars();
			me.b.setText("B"~b);
		} else {
			me.b.setText("");
		}
		me.a.setText("A"~a);
		me.r.setText(""~apg68Radar.getRange());
		me.rootName.setText(apg68Radar.currentMode.rootName);
		me.shortName.setText(apg68Radar.currentMode.shortName);
	},
	del: func {
		me.window.del();
        #emesary.GlobalTransmitter.DeRegister(f16_hmd);
    },
};


#   ██████       ███████  ██████  ██████  ██████  ███████ 
#  ██            ██      ██      ██    ██ ██   ██ ██      
#  ██      █████ ███████ ██      ██    ██ ██████  █████   
#  ██                 ██ ██      ██    ██ ██      ██      
#   ██████       ███████  ██████  ██████  ██      ███████ 
#                                                         
#                                                         
RadarViewCScope = {
# implements radar/RWR display on CRT/MFD
# also slew cursor to select contacts.
# fast loop
#
# Attributes:
#   link to Radar
#   link to FireControl
	new: func {
		me.window = canvas.Window.new([256, 256],"dialog")
				.set('x', 825)
                .set('title', "Radar C-Scope");
		var root = me.window.getCanvas(1).createGroup();
		me.window.getCanvas(1).setColorBackground(0,0,0);
		me.rootCenter = root.createChild("group")
				.setTranslation(128,256);
		me.rootCenter2 = root.createChild("group")
				.setTranslation(0,128);
		me.rootCenterBleps = root.createChild("group")
				.setTranslation(128,128);
		me.sweep = me.rootCenter.createChild("path")
				.moveTo(0,0)
				.vert(-20)
				.setStrokeLineWidth(2.5)
				.setColor(1,1,1);
		me.sweep2 = me.rootCenter2.createChild("path")
				.moveTo(0,0)
				.horiz(20)
				.setStrokeLineWidth(2.5)
				.setColor(1,1,1);
		
	    root.createChild("path")
	       .moveTo(0, 128)
           .arcSmallCW(128, 128, 0, 256, 0)
           .arcSmallCW(128, 128, 0, -256, 0)
           .setStrokeLineWidth(1)
           .setColor(1, 1, 1);

        me.blep = setsize([],200);
        for (var i = 0;i<200;i+=1) {
        	me.blep[i] = me.rootCenterBleps.createChild("path")
					.moveTo(0,0)
					.vert(2)
					.setStrokeLineWidth(2)
	      	  		.hide();
        }
        me.lock = setsize([],200);
        for (var i = 0;i<200;i+=1) {
        	me.lock[i] = me.rootCenterBleps.createChild("path")
						.moveTo(-5,-5)
						.vert(10)
						.horiz(10)
						.vert(-10)
						.horiz(-10)
						.setStrokeLineWidth(1)
	      	  		.hide();
        }
        me.select = setsize([],200);
        for (var i = 0;i<200;i+=1) {
        	me.select[i] = me.rootCenterBleps.createChild("path")
						.moveTo(-7,-7)
						.vert(14)
						.horiz(14)
						.vert(-14)
						.horiz(-14)
						.setColor([0.5,0,1])
						.setStrokeLineWidth(1)
	      	  		.hide();
        }
		

		var mt = maketimer(scanInterval,func me.loop());
        mt.start();
		return me;
	},

	loop: func {
		if (!enableTests) return;
		me.sweep.setTranslation(128*apg68Radar.positionCart[0],0);
		me.sweep2.setTranslation(0, -128*apg68Radar.positionCart[1]);
		me.sweep.update();
		me.sweep2.update();
		me.elapsed = getprop("sim/time/elapsed-sec");
		#me.rootCenterBleps.removeAllChildren();
		#me.rootCenterBleps.createChild("path")# thsi will show where the disc is pointed for debug purposes.
		#			.moveTo(0,0)
		#			.vert(2)
		#			.setStrokeLineWidth(2)
		#			.setColor(0.5,0.5,0.5)
		#			.setTranslation(128*apg68Radar.posH/60,-128*apg68Radar.posE/60)
		#			.update();
		me.i = 0;
		foreach(contact; apg68Radar.vector_aicontacts_bleps) {
			if (me.elapsed - contact.blepTime < apg68Radar.currentMode.timeToKeepBleps) {
				me.blep[me.i].setColor(1-(me.elapsed - contact.blepTime)/apg68Radar.currentMode.timeToKeepBleps,1-(me.elapsed - contact.blepTime)/apg68Radar.currentMode.timeToKeepBleps,1-(me.elapsed - contact.blepTime)/apg68Radar.currentMode.timeToKeepBleps);
				me.blep[me.i].setTranslation(128*contact.getDeviationHeadingFrozen()/60,-128*contact.getElevationFrozen()/60);
				me.blep[me.i].show();
				me.blep[me.i].update();
				if (0 and apg68Radar.containsVector(apg68Radar.locks, contact)) {
					me.lock[me.i].setColor(apg68Radar.lock == HARD?[1,0,0]:[1,1,0]);
					me.lock[me.i].setTranslation(128*contact.getDeviationHeadingFrozen()/60,-128*contact.getElevationFrozen()/60);
					me.lock[me.i].show();
					me.lock[me.i].update();
				} else {
					me.lock[me.i].hide();
				}
				if (0 and apg68Radar.containsVector(apg68Radar.follow, contact)) {
					me.select[me.i].setTranslation(128*getDeviationHeadingFrozen()/60,-128*contact.getElevationFrozen()/60);
					me.select[me.i].show();
					me.select[me.i].update();
				} else {
					me.select[me.i].hide();
				}
				me.i += 1;
				if (me.i > 199) break;
			}
		}
		for (;me.i<200;me.i+=1) {
			me.blep[me.i].hide();
			me.lock[me.i].hide();
			me.select[me.i].hide();
		}
	},
	del: func {
		me.window.del();
        #emesary.GlobalTransmitter.DeRegister(f16_hmd);
    },
};



#   █████        ███████  ██████  ██████  ██████  ███████ 
#  ██   ██       ██      ██      ██    ██ ██   ██ ██      
#  ███████ █████ ███████ ██      ██    ██ ██████  █████   
#  ██   ██            ██ ██      ██    ██ ██      ██      
#  ██   ██       ███████  ██████  ██████  ██      ███████ 
#                                                         
#                                                         
RadarViewAScope = {
# implements radar/RWR display on CRT/MFD
# also slew cursor to select contacts.
# fast loop
#
# Attributes:
#   link to Radar
#   link to FireControl
	new: func {
		
		me.window = canvas.Window.new([256, 256],"dialog")
				.set('x', 825)
				.set('y', 350)
                .set('title', "Radar A-Scope");
		var root = me.window.getCanvas(1).createGroup();
		me.window.getCanvas(1).setColorBackground(0,0,0);
		me.rootCenter = root.createChild("group")
				.setTranslation(0,250);
		me.line = [];
		for (var i = 0;i<256;i+=1) {
			append(me.line, me.rootCenter.createChild("path")
					.moveTo(0,0)
					.vert(300)
					.setStrokeLineWidth(1)
					.setColor(1,1,1));
		}
		me.values = setsize([], 256);
		var mt = maketimer(scanInterval,func me.loop());
        mt.start();
		return me;
	},

	loop: func {
		if (!enableTests) return;
		for (var i = 0;i<256;i+=1) {
			me.values[i] = 0;
		}
		me.elapsed = getprop("sim/time/elapsed-sec");
		foreach(contact; apg68Radar.vector_aicontacts_bleps) {
			if (me.elapsed - contact.blepTime < apg68Radar.currentMode.timeToKeepBleps) {
				me.range = contact.getRangeDirectFrozen();
				if (me.range==0) me.range=1;
				me.distPixels = 2/math.pow(me.range/contact.strength,2);
				me.index = int(256*(contact.getCartesianInFoRFrozen()[0]+1)*0.5);
				if (me.index<=255 and me.index>= 0) {
					me.values[me.index] += me.distPixels;
					if (me.index+1<=255)
						me.values[me.index+1] += me.distPixels*0.5;
					if (me.index+2<=255)
						me.values[me.index+2] += me.distPixels*0.25;
					if (me.index-1>=0)
						me.values[me.index-1] += me.distPixels*0.5;
					if (me.index-2>=0)
						me.values[me.index-2] += me.distPixels*0.25;
				}
			}
		}
		for (var i = 0;i<256;i+=1) {
			me.line[i].setTranslation(i,-clamp(me.values[i],0,256));
		}
		
	},
	del: func {
		me.window.del();
        #emesary.GlobalTransmitter.DeRegister(f16_hmd);
    },
};

RWRCanvas = {
	new: func (root, center, diameter) {
		var rwr = {parents: [RWRCanvas]};
		rwr.max_icons = 12;
		rwr.inner_radius = diameter/6;
		rwr.outer_radius = diameter/3;
		var font = int(0.039*diameter)+1;
		var colorG = [0,1,0];
		var colorLG = [0,0.5,0];
		rwr.fadeTime = 7;#seconds
		rwr.rootCenter = root.createChild("group")
				.setTranslation(center[0],center[1]);
		
	    root.createChild("path")
	       .moveTo(0, diameter/2)
           .arcSmallCW(diameter/2, diameter/2, 0, diameter, 0)
           .arcSmallCW(diameter/2, diameter/2, 0, -diameter, 0)
           .setStrokeLineWidth(1)
           .setColor(1, 1, 1);
        root.createChild("path")
	       .moveTo(diameter/2-rwr.inner_radius, diameter/2)
           .arcSmallCW(rwr.inner_radius, rwr.inner_radius, 0, rwr.inner_radius*2, 0)
           .arcSmallCW(rwr.inner_radius, rwr.inner_radius, 0, -rwr.inner_radius*2, 0)
           .setStrokeLineWidth(1)
           .setColor(colorLG);
        root.createChild("path")
	       .moveTo(diameter/2-rwr.outer_radius, diameter/2)
           .arcSmallCW(rwr.outer_radius, rwr.outer_radius, 0, rwr.outer_radius*2, 0)
           .arcSmallCW(rwr.outer_radius, rwr.outer_radius, 0, -rwr.outer_radius*2, 0)
           .setStrokeLineWidth(1)
           .setColor(colorLG);
        rwr.texts = setsize([],rwr.max_icons);
        for (var i = 0;i<rwr.max_icons;i+=1) {
        	rwr.texts[i] = rwr.rootCenter.createChild("text")
				.setText(int(rand()*21))
				.setAlignment("center-center")
				.setColor(colorG)
      	  		.setFontSize(font, 1.0)
      	  		.hide();

        }
        rwr.symbol_hat = setsize([],rwr.max_icons);
        for (var i = 0;i<rwr.max_icons;i+=1) {
        	rwr.symbol_hat[i] = rwr.rootCenter.createChild("path")
					.moveTo(0,-font)
					.lineTo(font*0.7,-font*0.7)
					.moveTo(0,-font)
					.lineTo(-font*0.7,-font*0.7)
					.setStrokeLineWidth(1)
					.setColor(colorG)
	      	  		.hide();
        }

 #       me.symbol_16_SAM = setsize([],max_icons);
#	    for (var i = 0;i<max_icons;i+=1) {
 #       	me.symbol_16_SAM[i] = me.rootCenter.createChild("path")
#					.moveTo(-11, 7)
#					.lineTo(-9, -7)
#					.moveTo(-9, -7)
#					.lineTo(-9, -4)
#					.moveTo(-9, -8)
#					.lineTo(-11, -4)
#					.setStrokeLineWidth(1)
#					.setColor(1,0,0)
#	      	  		.hide();
#        }
	    rwr.symbol_launch = setsize([],rwr.max_icons);
	    for (var i = 0;i<rwr.max_icons;i+=1) {
        	rwr.symbol_launch[i] = rwr.rootCenter.createChild("path")
					.moveTo(font*1.5, 0)
           			.arcSmallCW(font*1.5, font*1.5, 0, -font*3, 0)
           			.arcSmallCW(font*1.5, font*1.5, 0, font*3, 0)
					.setStrokeLineWidth(1)
					.setColor(colorG)
	      	  		.hide();
        }
        rwr.symbol_new = setsize([],rwr.max_icons);
	    for (var i = 0;i<rwr.max_icons;i+=1) {
        	rwr.symbol_new[i] = rwr.rootCenter.createChild("path")
					.moveTo(font*1.5, 0)
           			.arcSmallCCW(font*1.5, font*1.5, 0, -font*3, 0)
					.setStrokeLineWidth(1)
					.setColor(colorG)
	      	  		.hide();
        }
#        rwr.symbol_16_lethal = setsize([],max_icons);
#        for (var i = 0;i<max_icons;i+=1) {
#        	rwr.symbol_16_lethal[i] = rwr.rootCenter.createChild("path")
#					.moveTo(10, 10)
#					.lineTo(10, -10)
#					.lineTo(-10,-10)
#					.lineTo(-10,10)
#					.lineTo(10, 10)
#					.setStrokeLineWidth(1)
#					.setColor(1,0,0)
#	      	  		.hide();
#        }
        rwr.symbol_priority = rwr.rootCenter.createChild("path")
					.moveTo(0, font*1.5)
					.lineTo(font*1.5, 0)
					.lineTo(0,-font*1.5)
					.lineTo(-font*1.5,0)
					.lineTo(0, font*1.5)
					.setStrokeLineWidth(1)
					.setColor(colorG)
	      	  		.hide();
        
#        rwr.symbol_16_air = setsize([],max_icons);
#        for (var i = 0;i<max_icons;i+=1) {
 #       	rwr.symbol_16_air[i] = rwr.rootCenter.createChild("path")
#					.moveTo(15, 0)
#					.lineTo(0,-15)
#					.lineTo(-15,0)
#					.setStrokeLineWidth(1)
#					.setColor(1,0,0)
#	      	  		.hide();
#        }
		rwr.AIRCRAFT_VIGGEN = "37";
		rwr.AIRCRAFT_EAGLE = "15";
		rwr.AIRCRAFT_TOMCAT = "14";
		rwr.AIRCRAFT_BUK = "11";
		rwr.AIRCRAFT_MIG = "21";
		rwr.AIRCRAFT_MIRAGE = "20";
		rwr.AIRCRAFT_FALCON = "16";
		rwr.AIRCRAFT_FRIGATE = "SH";
		rwr.AIRCRAFT_VIGGEN   = "37";
        rwr.AIRCRAFT_EAGLE    = "15";
        rwr.AIRCRAFT_TOMCAT   = "14";
        rwr.ASSET_BUK         = "11";
        rwr.ASSET_GARGOYLE    = "20"; # Other namings for tracking and radar: BB, CS.
        rwr.AIRCRAFT_FAGOT    = "MG";
        rwr.AIRCRAFT_FISHBED  = "21";
        rwr.AIRCRAFT_FULCRUM  = "29";
        rwr.AIRCRAFT_FLANKER  = "27";
        rwr.AIRCRAFT_PAKFA    = "57";
        rwr.AIRCRAFT_MIRAGE   = "M2";
        rwr.AIRCRAFT_FALCON   = "16";
        rwr.AIRCRAFT_WARTHOG  = "10";
        rwr.ASSET_FRIGATE     = "SH";
        rwr.AIRCRAFT_SEARCH   = "S";
        rwr.AIRCRAFT_BLACKBIRD = "71";
        rwr.AIRCRAFT_TYPHOON  = "EF";
        rwr.AIRCRAFT_HORNET   = "18";
        rwr.AIRCRAFT_FLAGON   = "SU";
        rwr.SCENARIO_OPPONENT = "28";
        rwr.AIRCRAFT_JAGUAR   = "JA";
        rwr.AIRCRAFT_PHANTOM  = "F4";
        rwr.AIRCRAFT_SKYHAWK  = "A4";
        rwr.AIRCRAFT_TIGER    = "F5";
        rwr.AIRCRAFT_TONKA    = "TO";
        rwr.AIRCRAFT_RAFALE   = "RF";
        rwr.AIRCRAFT_HARRIER  = "HA";
        rwr.AIRCRAFT_HARRIERII = "AV";
        rwr.AIRCRAFT_GINA     = "91";
        rwr.AIRCRAFT_MB339    = "M3";
        rwr.AIRCRAFT_ALPHAJET = "AJ";
        rwr.AIRCRAFT_INTRUDER = "A6";
        rwr.AIRCRAFT_FROGFOOT = "25";
        rwr.AIRCRAFT_NIGHTHAWK = "17";
        rwr.AIRCRAFT_RAPTOR   = "22";
        rwr.AIRCRAFT_JSF      = "35";
        rwr.AIRCRAFT_GRIPEN   = "39";
        rwr.AIRCRAFT_MITTEN   = "Y1";
        rwr.AIRCRAFT_ALCA     = "LC";
        rwr.AIRCRAFT_SPRETNDRD = "ET";
        rwr.AIRCRAFT_UNKNOWN  = "U";
        rwr.AIRCRAFT_UFO      = "UK";
        rwr.ASSET_AI          = "AI";
        rwr.lookupType = {
        # OPRF fleet and related aircrafts:
                "f-14b":                    rwr.AIRCRAFT_TOMCAT,
                "F-14D":                    rwr.AIRCRAFT_TOMCAT,
                "F-15C":                    rwr.AIRCRAFT_EAGLE,
                "F-15D":                    rwr.AIRCRAFT_EAGLE,
                "F-16":                     rwr.AIRCRAFT_FALCON,
                "JA37-Viggen":              rwr.AIRCRAFT_VIGGEN,
                "AJ37-Viggen":              rwr.AIRCRAFT_VIGGEN,
                "AJS37-Viggen":             rwr.AIRCRAFT_VIGGEN,
                "JA37Di-Viggen":            rwr.AIRCRAFT_VIGGEN,
                "m2000-5":                  rwr.AIRCRAFT_MIRAGE,
                "m2000-5B":                 rwr.AIRCRAFT_MIRAGE,
                "MiG-21bis":                rwr.AIRCRAFT_FISHBED,
                "MiG-29":                   rwr.AIRCRAFT_FULCRUM,
                "SU-27":                    rwr.AIRCRAFT_FLANKER,
                "EC-137R":                  rwr.AIRCRAFT_SEARCH,
                "RC-137R":                  rwr.AIRCRAFT_SEARCH,
                "E-8R":                     rwr.AIRCRAFT_SEARCH,
                "EC-137D":                  rwr.AIRCRAFT_SEARCH,
                "gci":                      rwr.AIRCRAFT_SEARCH,
                "Blackbird-SR71A":          rwr.AIRCRAFT_BLACKBIRD,
                "Blackbird-SR71A-BigTail":  rwr.AIRCRAFT_BLACKBIRD,
                "Blackbird-SR71B":          rwr.AIRCRAFT_BLACKBIRD,
                "A-10":                     rwr.AIRCRAFT_WARTHOG,
                "A-10-model":               rwr.AIRCRAFT_WARTHOG,
                "Typhoon":                  rwr.AIRCRAFT_TYPHOON,
                "buk-m2":                   rwr.ASSET_BUK,
                "s-300":                    rwr.ASSET_GARGOYLE,
                "missile_frigate":          rwr.ASSET_FRIGATE,
                "frigate":                  rwr.ASSET_FRIGATE,
                "fleet":                    rwr.ASSET_FRIGATE,
                "Mig-28":                   rwr.SCENARIO_OPPONENT,
                "Jaguar-GR1":               rwr.AIRCRAFT_JAGUAR,
        # Other threatening aircrafts (FGAddon, FGUK, etc.):
                "AI":                       rwr.ASSET_AI,
                "SU-37":                    rwr.AIRCRAFT_FLANKER,
                "J-11A":                    rwr.AIRCRAFT_FLANKER,
                "T-50":                     rwr.AIRCRAFT_PAKFA,
                "MiG-21Bison":              rwr.AIRCRAFT_FISHBED,
                "Mig-29":                   rwr.AIRCRAFT_FULCRUM,
                "EF2000":                   rwr.AIRCRAFT_TYPHOON,
                "F-15C_Eagle":              rwr.AIRCRAFT_EAGLE,
                "F-15J_ADTW":               rwr.AIRCRAFT_EAGLE,
                "F-15DJ_ADTW":              rwr.AIRCRAFT_EAGLE,
                "f16":                      rwr.AIRCRAFT_FALCON,
                "F-16CJ":                   rwr.AIRCRAFT_FALCON,
                "FA-18C_Hornet":            rwr.AIRCRAFT_HORNET,
                "FA-18D_Hornet":            rwr.AIRCRAFT_HORNET,
                "f18":                      rwr.AIRCRAFT_HORNET,
                "A-10-modelB":              rwr.AIRCRAFT_WARTHOG,
                "Su-15":                    rwr.AIRCRAFT_FLAGON,
                "Jaguar-GR3":               rwr.AIRCRAFT_JAGUAR,
                "E3B":                      rwr.AIRCRAFT_SEARCH,
                "E-2C-Hawkeye":             rwr.AIRCRAFT_SEARCH,
                "onox-awacs":               rwr.AIRCRAFT_SEARCH,
                "u-2s":                     rwr.AIRCRAFT_SEARCH,
                "U-2S-model":               rwr.AIRCRAFT_SEARCH,
                "F-4S":                     rwr.AIRCRAFT_PHANTOM,
                "F-4EJ_ADTW":               rwr.AIRCRAFT_PHANTOM,
                "FGR2-Phantom":             rwr.AIRCRAFT_PHANTOM,
                "F4J":                      rwr.AIRCRAFT_PHANTOM,
                "F-4N":                     rwr.AIRCRAFT_PHANTOM,
                "a4f":                      rwr.AIRCRAFT_SKYHAWK,
                "A-4K":                     rwr.AIRCRAFT_SKYHAWK,
                "F-5E":                     rwr.AIRCRAFT_TIGER,
                "F-5E-TigerII":             rwr.AIRCRAFT_TIGER,
                "F-5ENinja":                rwr.AIRCRAFT_TIGER,
                "f-20A":                    rwr.AIRCRAFT_TIGER,
                "f-20C":                    rwr.AIRCRAFT_TIGER,
                "f-20prototype":            rwr.AIRCRAFT_TIGER,
                "f-20bmw":                  rwr.AIRCRAFT_TIGER,
                "f-20-dutchdemo":           rwr.AIRCRAFT_TIGER,
                "Tornado-GR4a":             rwr.AIRCRAFT_TONKA,
                "Tornado-IDS":              rwr.AIRCRAFT_TONKA,
                "Tornado-F3":               rwr.AIRCRAFT_TONKA,
                "brsq":                     rwr.AIRCRAFT_RAFALE,
                "Harrier-GR1":              rwr.AIRCRAFT_HARRIER,
                "Harrier-GR3":              rwr.AIRCRAFT_HARRIER,
                "Harrier-GR5":              rwr.AIRCRAFT_HARRIER,
                "Harrier-GR9":              rwr.AIRCRAFT_HARRIER,
                "AV-8B":                    rwr.AIRCRAFT_HARRIERII,
                "G91-R1B":                  rwr.AIRCRAFT_GINA,
                "G91":                      rwr.AIRCRAFT_GINA,
                "g91":                      rwr.AIRCRAFT_GINA,
                "mb339":                    rwr.AIRCRAFT_MB339,
                "mb339pan":                 rwr.AIRCRAFT_MB339,
                "alphajet":                 rwr.AIRCRAFT_ALPHAJET,
                "MiG-15bis":                rwr.AIRCRAFT_FAGOT,
                "Su-25":                    rwr.AIRCRAFT_FROGFOOT,
                "A-6E-model":               rwr.AIRCRAFT_INTRUDER,
                "F-117":                    rwr.AIRCRAFT_NIGHTHAWK,
                "F-22-Raptor":              rwr.AIRCRAFT_RAPTOR,
                "F-35A":                    rwr.AIRCRAFT_JSF,
                "F-35B":                    rwr.AIRCRAFT_JSF,
                "JAS-39C_Gripen":           rwr.AIRCRAFT_GRIPEN,
                "gripen":                   rwr.AIRCRAFT_GRIPEN,
                "Yak-130":                  rwr.AIRCRAFT_MITTEN,
                "L-159":                    rwr.AIRCRAFT_ALCA,
                "super-etendard":           rwr.AIRCRAFT_SPRETNDRD,
                "mp-nimitz":                rwr.ASSET_FRIGATE,
                "mp-eisenhower":            rwr.ASSET_FRIGATE,
                "mp-vinson":                rwr.ASSET_FRIGATE,
                "mp-clemenceau":            rwr.ASSET_FRIGATE,
                "ufo":                      rwr.AIRCRAFT_UFO,
                "bluebird-osg":             rwr.AIRCRAFT_UFO,
                "F-23C_BlackWidow-II":      rwr.AIRCRAFT_UFO,
        };
		rwr.shownList = [];
		return rwr;
	},
	update: func (list) {
		me.elapsed = getprop("sim/time/elapsed-sec");
		var sorter = func(a, b) {
		    if(a[1] < b[1]){
		        return -1; # A should before b in the returned vector
		    }elsif(a[1] == b[1]){
		        return 0; # A is equivalent to b 
		    }else{
		        return 1; # A should after b in the returned vector
		    }
		}
		var sortedlist = sort(list, sorter);
		var newList = [];
		me.i = 0;
		me.hat = 0;
		me.newt = 0;
		me.prioShow = 0;
		foreach(contact; sortedlist) {
			me.typ=me.lookupType[contact[0].getModel()];
			if (me.typ == nil) {
				me.typ = me.AIRCRAFT_UNKNOWN;
			}
			if (me.i > me.max_icons-1) {
				break;
			}
			me.threat = contact[1];#print(me.threat);
			if (me.threat < 5) {
				me.threat = me.inner_radius;# inner circle
			} elsif (me.threat < 30) {
				me.threat = me.outer_radius;# outer circle
			} else {
				continue;
			}
			me.dev = -contact[0].getThreatStored()[5]+90;
			me.x = math.cos(me.dev*D2R)*me.threat;
			me.y = -math.sin(me.dev*D2R)*me.threat;
			me.texts[me.i].setTranslation(me.x,me.y);
      	  	me.texts[me.i].show();
      	  	me.texts[me.i].setText(me.typ);
			if (me.i == 0) {
				me.symbol_priority.setTranslation(me.x,me.y);
	      	  	me.prioShow = 1;
			}
			if (!(me.typ == me.AIRCRAFT_BUK or me.typ == me.AIRCRAFT_FRIGATE)) {
				me.symbol_hat[me.hat].setTranslation(me.x,me.y);
	      	  	me.symbol_hat[me.hat].show();
				me.symbol_hat[me.hat].update();
				me.hat += 1;
			}
			var popup = me.elapsed;
			foreach(var old; me.shownList) {
				if(old[0].equals(contact[0])) {
					popup = old[1];
					break;
				}
			}
			if (popup > me.elapsed-me.fadeTime) {
				me.symbol_new[me.newt].setTranslation(me.x,me.y);
	      	  	me.symbol_new[me.newt].show();
				me.symbol_new[me.newt].update();
				me.newt += 1;
			}
			append(newList, [contact[0],popup]);
			me.i += 1;
		}
		me.symbol_priority.setVisible(me.prioShow);
		me.shownList = newList;
		for (;me.i<me.max_icons;me.i+=1) {
			me.texts[me.i].hide();
		}
		for (;me.hat<me.max_icons;me.hat+=1) {
			me.symbol_hat[me.hat].hide();
		}
		for (;me.newt<me.max_icons;me.newt+=1) {
			me.symbol_new[me.newt].hide();
		}
	},
	del: func {
	},
};

RWRView = {
	new: func {
		var diameter = 256;
		me.window = canvas.Window.new([diameter, diameter],"dialog")
				.set('x', 550)
				.set('y', 350)
                .set('title', "RWR");
		var root = me.window.getCanvas(1).createGroup();
		me.window.getCanvas(1).setColorBackground(0,0.2,0);
		me.rwr = RWRCanvas.new(root, [diameter/2,diameter/2], diameter);
		var mt = maketimer(1,func me.loop());
        mt.start();
		return me;
	},

	loop: func {
		if (!enableRWRs) return;
		
		
		me.rwr.update(exampleRWR.vector_aicontacts_threats);

		
	},
	del: func {
		me.rwr.del();
		me.window.del();
	},
};














var window = nil;
var buttonWindow = func {
	# a test gui for radar modes
	window = canvas.Window.new([200,525],"dialog").set('title',"Radar modes");
	var myCanvas = window.createCanvas().set("background", canvas.style.getColor("bg_color"));
	var root = myCanvas.createGroup();
	var myLayout0 = canvas.HBoxLayout.new();
	var myLayout = canvas.VBoxLayout.new();
	var myLayout2 = canvas.VBoxLayout.new();
	myCanvas.setLayout(myLayout0);
	myLayout0.addItem(myLayout);
	myLayout0.addItem(myLayout2);
#	var button0 = canvas.gui.widgets.Button.new(root, canvas.style, {})
#		.setText("RWS high")
#		.setFixedSize(75, 25);
#	button0.listen("clicked", func {
#		apg68Radar.rwsHigh();
#	});
#	myLayout.addItem(button0);
	var button0 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Master Mode")
		.setFixedSize(90, 25);
	button0.listen("clicked", func {
		apg68Radar.cycleRootMode();
	});
	myLayout.addItem(button0);
	var button1 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Mode")
		.setFixedSize(75, 25);
	button1.listen("clicked", func {
		apg68Radar.cycleMode();
	});
	myLayout.addItem(button1);
	var button5 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Left")
		.setFixedSize(75, 25);
	button5.listen("clicked", func {
		apg68Radar.setCursorDeviation(apg68Radar.getCursorDeviation()-10);
	});
	myLayout.addItem(button5);
	var button6 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Right")
		.setFixedSize(75, 25);
	button6.listen("clicked", func {
		apg68Radar.setCursorDeviation(apg68Radar.getCursorDeviation()+10);
	});
	myLayout.addItem(button6);
	var button7 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Range+")
		.setFixedSize(75, 20);
	button7.listen("clicked", func {
		apg68Radar.increaseRange();
	});
	myLayout.addItem(button7);
	var button8 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Range-")
		.setFixedSize(75, 20);
	button8.listen("clicked", func {
		apg68Radar.decreaseRange();
	});
	myLayout.addItem(button8);
	var button9 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Designate")
		.setFixedSize(75, 25);
	button9.listen("clicked", func {
		apg68Radar.designateRandom();
	});
	myLayout.addItem(button9);
	var button10 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Un-designate")
		.setFixedSize(90, 25);
	button10.listen("clicked", func {
		apg68Radar.undesignate();
	});
	myLayout.addItem(button10);
	var button11 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Cycle priority")
		.setFixedSize(90, 25);
	button11.listen("clicked", func {
		apg68Radar.cycleDesignate();
	});
	myLayout.addItem(button11);
	var button12 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Up")
		.setFixedSize(75, 25);
	button12.listen("clicked", func {
		antennae_knob_prop.setDoubleValue(antennae_knob_prop.getValue()+0.05);
	});
	myLayout.addItem(button12);
	var button13 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Down")
		.setFixedSize(75, 25);
	button13.listen("clicked", func {
		antennae_knob_prop.setDoubleValue(antennae_knob_prop.getValue()-0.05);
	});
	myLayout.addItem(button13);
	var button14 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Level")
		.setFixedSize(75, 25);
	button14.listen("clicked", func {
		antennae_knob_prop.setDoubleValue(0);
	});
	myLayout.addItem(button14);

	var button15b = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Bars")
		.setFixedSize(75, 25);
	button15b.listen("clicked", func {
		apg68Radar.cycleBars();
	});
	myLayout2.addItem(button15b);
	var button19 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Azimuth")
		.setFixedSize(75, 25);
	button19.listen("clicked", func {
		apg68Radar.cycleAZ();
	});
	myLayout2.addItem(button19);
	button23 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Scr ON")
		.setFixedSize(75, 20);
	button23.listen("clicked", func {
		enableTests = !enableTests;
		if (enableTests == 0) button23.setText("Scr OFF");
		else button23.setText("Scr ON");
	});
	myLayout2.addItem(button23);
	#button24 = canvas.gui.widgets.Button.new(root, canvas.style, {})
	#	.setText("RWRsc ON")
	#	.setFixedSize(75, 20);
	#button24.listen("clicked", func {
	#	enableRWRs = !enableRWRs;
	#	if (enableRWRs == 0) button24.setText("RWRsc OFF");
	#	else button24.setText("RWRsc ON");
	#});
	#myLayout2.addItem(button24);
	#button25 = canvas.gui.widgets.Button.new(root, canvas.style, {})
	#	.setText("RWR ON")
	#	.setFixedSize(75, 20);
	#button25.listen("clicked", func {
	#	enableRWR = !enableRWR;
	#	if (enableRWR == 0) button25.setText("RWR OFF");
	#	else button25.setText("RWR ON");
	#});
	#myLayout2.addItem(button25);
	button26 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("RDR ON")
		.setFixedSize(75, 20);
	button26.listen("clicked", func {
		apg68Radar.enabled = !apg68Radar.enabled;
		if (apg68Radar.enabled == 0) button26.setText("RDR OFF");
		else button26.setText("RDR ON");
	});
	myLayout2.addItem(button26);
	button27 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Nose ON")
		.setFixedSize(75, 20);
	button27.listen("clicked", func {
		nose.enabled = !nose.enabled;
		if (nose.enabled == 0) button27.setText("Nose OFF");
		else button27.setText("Nose ON");
	});
	myLayout2.addItem(button27);
	button28 = canvas.gui.widgets.Button.new(root, canvas.style, {})
		.setText("Parser ON")
		.setFixedSize(75, 20);
	button28.listen("clicked", func {
		baser.enabled = !baser.enabled;
		if (baser.enabled == 0) button28.setText("Parser OFF");
		else button28.setText("Parser ON");
	});
	myLayout2.addItem(button28);
};
var button23 = nil;
var button24 = nil;
var button25 = nil;
var button26 = nil;
var button27 = nil;
var button28 = nil;




var exampleRWR   = nil;
var displayPPI = nil;
var displayB = nil;
var displayC = nil;
var displayA = nil;
var displayRWR = nil;



#var fix = FixedBeamRadar.new();
#fix.setBeamPitch(-2.5);
#settimer(func {print("beam: "~fix.testForDistance());},15);# will fail if no terrain found :)

var main = func (module) {
	displayPPI = RadarViewPPI.new();
	displayB = RadarViewBScope.new();
	#displayC = RadarViewCScope.new();
	#displayA = RadarViewAScope.new();
	#exampleRWR   = RWR.new();
	#displayRWR = RWRView.new();
    #buttonWindow();
}

var unload = func {
    if (apg68Radar != nil) {
        apg68Radar.del();
        apg68Radar = nil;
    }
    if (nose != nil) {
        nose.del();
        nose = nil;
    }
    if (omni != nil) {
        omni.del();
        omni = nil;
    }
    if (displayRWR != nil) {
        displayRWR.del();
        displayRWR = nil;
    }
    if (displayPPI != nil) {
        displayPPI.del();
        displayPPI = nil;
    }
    if (displayB != nil) {
        displayB.del();
        displayB = nil;
    }
    if (displayA != nil) {
        displayA.del();
        displayA = nil;
    }
    if (displayC != nil) {
        displayC.del();
        displayC = nil;
    }
    if (terrain != nil) {
        terrain.del();
        terrain = nil;
    }
    if (exampleRWR != nil) {
        exampleRWR.del();
        exampleRWR = nil;
    }
    if (window != nil) {
        window.del();
        window = nil;
    }
    if (baser != nil) {
        baser.del();
        baser = nil;
    }
    AIToNasal = nil;
	NoseRadar = nil;
	OmniRadar = nil;
	TerrainChecker = nil;
	RWR = nil;
	RadarViewPPI = nil;
	RadarViewBScope = nil;
	RadarViewCScope = nil;
	RadarViewAScope = nil;
	RWRView = nil;
}

main(nil);




