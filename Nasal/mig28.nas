# License: GPL 2.0
# Author: Nikolai V. Chr.
var TopGun = {
	# To start, type in nasal console: mig28.start(difficulty);
	# To stop, type in nasal console: mig28.stop();
	# Training floor is 10000ft, ceiling is 40000ft.
	# Collision is enabled.
	# Do not do this in mountainous or high ground areas. Best is flat and elevation below 5000ft above sealevel.
	# The mig-28 instructor will only fight you with cannon.
	# Do not pause the sim, that might mess up the mig-28.
	# There must be scenery and if you fly away from the mig28 so he get outside where there is scenery he will reset.
	# He will also reset if he stalls or hit the ground.
	new: func (heading) {
		var obj = {parents: [TopGun]};
		obj.startHeading = heading;
		return obj;
	},
	enabled: 0,
	startHeading: 0,
	start: func {
		if (me.enabled) {
			print("TopGun: Already started, try stop() before starting again.");
			return;
		}
		me.enabled = 1;
		var model = getprop("sim/model/path");
		var n = props.globals.getNode("models", 1);
		var i = 0;
		for (i = 0; 1==1; i += 1) {
			if (n.getChild("model", i, 0) == nil) {
				break;
			}
		}
		me.model = n.getChild("model", i, 1);
		
		n = props.globals.getNode("ai/models", 1);
		for (i = 0; 1==1; i += 1) {
			if (n.getChild("mig28", i, 0) == nil) {
				break;
			}
		}
		me.ai = n.getChild("mig28", i, 1);
		me.ai.getNode("valid", 1).setBoolValue(0);
		me.ai.getNode("name", 1).setValue("No-name");
		me.ai.getNode("sign", 1).setValue("Bandit");
		me.ai.getNode("type", 1).setValue("mig28");
		me.ai.getNode("callsign", 1).setValue(me.callsign);
		#me.ai.getNode("sim/multiplay/generic/bool[2]",1).setBoolValue(0);#damage smoke
		#me.ai.getNode("sim/multiplay/generic/bool[40]",1).setBoolValue(1);
		#me.ai.getNode("sim/multiplay/generic/bool[41]",1).setBoolValue(1);#lights
		#me.ai.getNode("sim/multiplay/generic/bool[42]",1).setBoolValue(1);
		#me.ai.getNode("sim/multiplay/generic/bool[43]",1).setBoolValue(1);
		#me.ai.getNode("sim/multiplay/generic/bool[44]",1).setBoolValue(1);
		#me.ai.getNode("gear/gear[0]/position-norm",1).setDoubleValue(0);#gear
		#me.ai.getNode("gear/gear[1]/position-norm",1).setDoubleValue(0);#gear
		#me.ai.getNode("gear/gear[1]/position-norm",1).setDoubleValue(0);#gear
		#me.ai.getNode("sim/multiplay/generic/bool[39]",1).setDoubleValue(1);#aug
		#me.ai.getNode("sim/multiplay/generic/float[0]",1).setDoubleValue(1);#nozzle
		
		me.ai.getNode("sim/multiplay/generic/int[2]",1).setBoolValue(0);#radar standby
		me.model.getNode("path", 1).setValue(model);

		me.nodeLat   = me.ai.getNode("position/latitude-deg", 1);
		me.nodeLon   = me.ai.getNode("position/longitude-deg", 1);
		me.nodeAlt   = me.ai.getNode("position/altitude-ft", 1);
		me.nodeHeading   = me.ai.getNode("orientation/true-heading-deg", 1);
		me.nodePitch = me.ai.getNode("orientation/pitch-deg", 1);
		me.nodeRoll  = me.ai.getNode("orientation/roll-deg", 1);

		me.a16Coord = geo.aircraft_position();

		me.nodeLat.setDoubleValue(me.a16Coord.lat());
		me.nodeLon.setDoubleValue(me.a16Coord.lon());
		me.nodeAlt.setDoubleValue(25000);
		me.nodeHeading.setDoubleValue(me.startHeading);
		me.nodePitch.setDoubleValue(0);
		me.nodeRoll.setDoubleValue(0);

		me.model.getNode("latitude-deg-prop", 1).setValue(me.nodeLat.getPath());
		me.model.getNode("longitude-deg-prop", 1).setValue(me.nodeLon.getPath());
		me.model.getNode("elevation-ft-prop", 1).setValue(me.nodeAlt.getPath());
		me.model.getNode("heading-deg-prop", 1).setValue(me.nodeHeading.getPath());
		me.model.getNode("pitch-deg-prop", 1).setValue(me.nodePitch.getPath());
		me.model.getNode("roll-deg-prop", 1).setValue(me.nodeRoll.getPath());
		me.loadNode = me.model.getNode("load", 1);
		
		print("TopGun: starting");
		screen.log.write(me.callsign~": Hello.", 1.0, 1.0, 0.0);
		settimer(func {me.spwn();}, 2);
	},

	stop: func {
		if (me.enabled) {
			me.ai.getNode("valid", 1).setBoolValue(0);
			me.model.remove();
			me.ai.remove();
			screen.log.write(me.callsign~": I am returning to base, later.", 1.0, 1.0, 0.0);
			print("TopGun: stopped.");
			setprop("ai/models/model-removed", me.ai.getPath());
		}
		me.enabled = 0;
	},

	spwn: func {
		me.ai.getNode("valid").setBoolValue(1);
		
		me.reset();
		if (me.callsign == "Lt.Endo") {
			screen.log.write(me.callsign~": I will go easy on you, try to stay on my six. Have fun.", 1.0, 1.0, 0.0);
		} elsif (me.callsign == "Cpt.Cas") {
			screen.log.write(me.callsign~": Nice weather for a fair fight, lets go.", 1.0, 1.0, 0.0);
		} elsif (me.callsign == "Maj.Rap") {
			screen.log.write(me.callsign~": Lets do this, don't make any mistakes.", 1.0, 1.0, 0.0);
		} elsif (me.callsign == "Maj.Cas") {
			screen.log.write(me.callsign~": Fight is on!", 1.0, 1.0, 0.0);
		} elsif (me.callsign == "Cpt.Rap") {
			screen.log.write(me.callsign~": Lets do this.", 1.0, 1.0, 0.0);
		}
		settimer(func {me.apply();me.loadNode.setBoolValue(1);setprop("ai/models/model-added", me.ai.getPath());print("TopGun: "~me.callsign~" spawned");}, 0.05);
	},

	decide: func {
		if (me.enabled == 0) {
			print("TopGun: interupted training session.");
			return;
		}
		me.elapsed = systime();
		me.dt = me.elapsed - me.elapsed_last;
		me.elapsed_last = me.elapsed;
		me.random = rand();
		if (me.elapsed - me.decisionTime > me.keepDecisionTime) {
			if (me.alt < 12000*FT2M and me.GStoKIAS(me.speed*MPS2KT) < 275) {
				# low speed at low alt, need to fly straight for 3 secs to get some speed
				me.think = GO_AHEAD;
				me.thrust = 1;
				me.keepDecisionTime = 3;
				me.decided();
			} elsif (me.alt > 38000*FT2M and me.GStoKIAS(me.speed*MPS2KT) > 700) {
				# high speed at high alt, need to turn hard for 3 secs to bleed some speed
				me.think = me.random>0.5?GO_LEFT:GO_RIGHT;
				me.thrust = -0.1;#speedbrakes enabled
				me.keepDecisionTime = 3;
				me.decided();
			} elsif (me.alt < 10000*FT2M) {
				# below training floor, go up for 2 secs
				me.think = GO_UP;
				me.thrust = 1;
				me.keepDecisionTime = 2;
				me.decided();
			} elsif (me.alt > 40000*FT2M) {
				# above training ceiling go down for 2 secs
				me.think = GO_DOWN;
				me.thrust = 0;
				me.keepDecisionTime = 2;
				me.decided();
			} elsif (me.GStoKIAS(me.speed*MPS2KT) < 250) {
				# too low speed, go down for 3 secs
				me.think = GO_DOWN;
				me.thrust = 1;
				me.keepDecisionTime = 3;
				me.decided();
			} elsif (me.GStoKIAS(me.speed*MPS2KT) > 750) {
				# too high speed, go up for 3 secs
				me.think = GO_UP;
				me.thrust = 0;
				me.keepDecisionTime = 3;
				me.decided();
			} else {
				# here comes reaction to a16
				me.a16Coord = geo.aircraft_position();
				if(me.a16Coord.alt()*M2FT < 7000 and me.elapsed - me.warnTime > 15) {
					screen.log.write(me.callsign~": Stay above 10000 feet.", 1.0, 1.0, 0.0);
					me.warnTime = me.elapsed;
				}
				if(me.a16Coord.alt()*M2FT > 43000 and me.elapsed - me.warnTime > 15) {
					screen.log.write(me.callsign~": Stay below 40000 feet.", 1.0, 1.0, 0.0);
					me.warnTime = me.elapsed;
				}
				me.a16Pitch = vector.Math.getPitch(me.coord,me.a16Coord);
				me.a16Elev  = me.a16Pitch-me.pitch;
				me.a16Bearing = me.coord.course_to(me.a16Coord);
				me.a16ClockLast = me.a16Clock;
				me.a16Clock = geo.normdeg180(me.a16Bearing-me.heading);
				me.hisBearing = me.a16Coord.course_to(me.coord);
				me.hisClock = geo.normdeg180(me.hisBearing-getprop("orientation/heading-deg"));
				me.dist_nm = me.a16Coord.direct_distance_to(me.coord)*M2NM;
				if ((math.abs(me.hisClock) < 20 or math.abs(me.hisClock) > 140) and math.abs(me.a16Elev)<7 and math.abs(me.a16Clock) < 7) {
					# has aim on the f16, slow down a bit and keep that aim
					me.think = GO_AIM;
					#if (me.speed*MPS2KT > 650) {
					#	me.thrust = 0.25;
					#} elsif (me.speed*MPS2KT > 525) {
					#	me.thrust = 0.5;
					#} elsif (me.speed*MPS2KT > 400) {
					#	me.thrust = 0.75;
					#} else {
						me.thrust = 1;
					#}
					me.thrust = math.min(1.0,me.thrust*me.dist_nm/2.0);
					if (me.elapsed - me.sightTime > 3 and me.dist_nm < 2) {
						screen.log.write(me.callsign~": Hey! I have you in my gunsight..", 1.0, 1.0, 0.0);
						me.sightTime = me.elapsed;
					}
				} elsif (math.abs(me.a16Clock) > 140 and math.abs(me.a16Pitch)<15 and math.abs(me.hisClock) < 20 and me.dist_nm < 2.5) {
					# f16 has aim on mig28, do some scissors to not be hit
					if (me.think != GO_SCISSOR) {
						me.aimTime = me.elapsed;
					}
					me.think = GO_SCISSOR;
					me.thrust = -0.1; #speedbrakes
				} else {
					if (me.think==GO_AIM and math.abs(me.rollTarget) > 70 and math.abs(me.a16ClockLast)>math.abs(me.a16Clock) and me.elapsed - me.aimTime > 15 and me.dist_nm < 2.5) {# been in turn fight for 15 secs+ and not gaining aspect
						me.bad += 1;
					} else {
						me.bad = 0;
					}
					if (me.bad > 60) {
						# turn fight going bad, break circle
						if (me.alt*M2FT < 25000) {
							if (me.think != GO_BREAK_UP) {
								me.aimTime = me.elapsed;
							}
							me.think = GO_BREAK_UP;
							me.thrust = 1;
						} else {
							if (me.think != GO_BREAK_DOWN) {
								me.aimTime = me.elapsed;
							}
							me.think = GO_BREAK_DOWN;
							me.thrust = 0.75;
						}
						me.bad = 0;
					} elsif ((me.think != GO_BREAK_UP or me.elapsed - me.aimTime > 5) and (me.think != GO_BREAK_DOWN or me.elapsed - me.aimTime > 4)) {# don't interupt break-up unless 5 secs has passed
						# turn fight to try and get f16 in sight
						if (me.think != GO_AIM) {
							me.aimTime = me.elapsed;
						}
						me.think = GO_AIM;
						if (me.GStoKIAS(me.speed*MPS2KT) > 650) {
							me.thrust = 0.25;
						} elsif (me.GStoKIAS(me.speed*MPS2KT) > 525) {
							me.thrust = 0.5;
						} elsif (me.GStoKIAS(me.speed*MPS2KT) > 450) {
							me.thrust = 0.75;
						} else {
							me.thrust = 1;
						}
					}					
				}
				me.keepDecisionTime = 0.15;
				me.decided();
			}
		}
		me.move();
	},

	decided: func {
		if(me.think == GO_AHEAD)me.prt="straight";
		if(me.think==GO_LEFT)me.prt="left";
		if(me.think==GO_RIGHT)me.prt="right";
		if(me.think==GO_UP)me.prt="up";
		if(me.think==GO_DOWN)me.prt="down";
		if(me.think==GO_AIM)me.prt="chase";
		if(me.think==GO_SCISSOR)me.prt="scissor";
		if(me.think==GO_BREAK_UP)me.prt="break up the circle";
		if(me.think==GO_BREAK_DOWN)me.prt="break down the circle";
		#printf("Deciding to go %s. Speed %d KIAS/M%.2f at %d ft. Roll %d, pitch %d. Thrust %.1f%%. %.1f NM.",me.prt,me.GStoKIAS(me.speed*MPS2KT),me.mach,me.alt*M2FT,me.roll,me.pitch,me.thrust*100, me.dist_nm);
		me.decisionTime = me.elapsed;
	},

	move: func {
		if (me.think == GO_AHEAD) {
			me.rollTarget = 0;
			me.pitchTarget = 0;
			me.step();
		} elsif (me.think == GO_LEFT) {
			me.rollTarget = -MAX_ROLL;
			me.pitchTarget = 0;
			me.step();
		} elsif (me.think == GO_RIGHT) {
			me.rollTarget =  MAX_ROLL;
			me.pitchTarget = 0;
			me.step();
		} elsif (me.think == GO_UP) {
			me.rollTarget = 0;
			me.pitchTarget = 45;
			me.step();
		} elsif (me.think == GO_DOWN) {
			me.rollTarget = 0;
			me.pitchTarget = -30;
			me.step();
		} elsif (me.think == GO_AIM) {
			me.rollTarget = math.max(-1,math.min(1,me.a16Clock/(30-(1-me.Gf)*15)))*MAX_ROLL;
			me.pitchTarget = me.a16Pitch;
			me.step();
		} elsif (me.think == GO_BREAK_UP) {
			me.rollTarget = math.max(-1,math.min(1,-me.a16Clock/15))*MAX_ROLL;
			me.pitchTarget = 50;
			me.step();
		} elsif (me.think == GO_BREAK_DOWN) {
			me.rollTarget = math.max(-1,math.min(1,-me.a16Clock/15))*MAX_ROLL;
			me.pitchTarget = -35;
			me.step();
		} elsif (me.think == GO_SCISSOR) {
			if (me.roll != MAX_ROLL and me.scissorTarget == MAX_ROLL) {
				me.rollTarget = MAX_ROLL;
			} elsif (me.roll != -MAX_ROLL and me.scissorTarget == -MAX_ROLL) {
				me.rollTarget = -MAX_ROLL;
			} elsif (math.abs(me.roll)==MAX_ROLL and me.elapsed - me.aimTime > 2) {
				me.scissorTarget = -me.scissorTarget;
				me.aimTime = me.elapsed;
			}
			me.pitchTarget = 0;
			me.step();
		}
		me.apply();
	},

	reset: func () {
		me.speed = 400*KT2MPS;
		me.mach = 1.0;
		me.heading = me.startHeading;
		me.coord = geo.Coord.new(geo.aircraft_position());
		me.lat = me.coord.lat();
		me.lon = me.coord.lon();
		me.alt = me.coord.alt()+5000*FT2M;
		me.coord.set_alt(me.alt);
		me.roll = 0;
		me.pitch = 0;
		me.think = GO_AHEAD;
		me.thrust = 0.5;
		me.elapsed = systime();
		me.elapsed_last = systime()-0.025;
		me.dt = 0.025;
		me.decisionTime = systime();
		me.aimTime = systime();
		me.rollTarget = me.roll;
		me.pitchTarget = me.pitch;
		me.scissorTarget = -MAX_ROLL;
		me.a16Clock = 0;
		me.keepDecisionTime = 0;
		me.sightTime = 0;
		me.warnTime = 0;
		me.dist_nm = 0;
		me.turnStack = 0;
		me.Gf = 0;

		print("TopGun: deciding to RESET!");
	},

	step: func () {
		if(me.rollTarget>me.roll) {
			me.roll += MAX_ROLL_SPEED*me.dt;
			if (me.roll > me.rollTarget) {
				me.roll = me.rollTarget;
			}
		} elsif(me.rollTarget<me.roll) {
			me.roll -= MAX_ROLL_SPEED*me.dt;
			if (me.roll < me.rollTarget) {
				me.roll = me.rollTarget;
			}
		}
		if(me.pitchTarget>me.pitch) {
			me.pitch += MAX_PITCH_UP_SPEED*me.dt;
			if (me.pitch > me.pitchTarget) {
				me.pitch = me.pitchTarget;
			}
		} elsif(me.pitchTarget<me.pitch) {
			me.pitch -= MAX_PITCH_DOWN_SPEED*me.dt;
			if (me.pitch < me.pitchTarget) {
				me.pitch = me.pitchTarget;
			}
		}
		me.rollNorm = me.roll/MAX_ROLL;
		me.mach = me.machNow(me.speed*M2FT, me.alt*M2FT);
		me.turn = me.turnMax(me.mach,me.alt*M2FT);
		me.Gf        = math.min(1, me.extrapolate(me.turn[1], 3, 9, 1, math.max(0.11,(ENDURANCE*4.5*0.75)/math.max(0.00001,me.turnStack))));
		me.G         = me.Gf*me.turn[1];
		me.turnSpeed = me.Gf*me.turn[0];
		#printf("max turn %.1f  max G %.1f  stack %.1f  turn %.1f  G %.1f", me.turn[0],me.turn[1],me.turnStack,me.rollNorm*(me.rollNorm<0?-1:1)*me.turnSpeed,me.rollNorm*(me.rollNorm<0?-1:1)*me.G*0.8888+1);
		me.turnStack += (me.rollNorm*(me.rollNorm<0?-1:1)*me.G-4.5)*me.dt;
		me.turnStack = math.max(0,me.turnStack);
		me.heading = geo.normdeg(me.heading+me.rollNorm*me.turnSpeed*me.dt);
		me.speedHorz = math.cos(me.pitch*D2R)*me.speed;
		me.upFrac = math.sin(me.pitch*D2R);
		me.speedUp   = me.upFrac*me.speed;
		me.coord.apply_course_distance(me.heading, me.speedHorz*me.dt);
		me.alt += me.speedUp*me.dt;
		me.coord.set_alt(me.alt);
		me.lat = me.coord.lat();
		me.lon = me.coord.lon();
		me.turnNorm = me.rollNorm*me.turnSpeed/MAX_TURN_SPEED;

		me.deacc      = me.deaccMax();
		me.bleed      = me.extrapolate(me.turnNorm*(me.turnNorm<0?-1:1), 0, 1, 0, me.deacc*BLEED_FACTOR); # turn bleed (guess)
		me.gravity    = 9.80665*me.upFrac;                                                       # gravity acc/deacc (sorta real)
		me.acc        = me.extrapolate(me.thrust, 0, 1, -me.deaccMax(), me.accMax());            # acc (real)
		

		me.speed += (-me.gravity+me.acc-me.bleed)*me.dt; # the aircraft in level flight is unaffected by gravity drop.

		me.ground = geo.elevation(me.lat,me.lon);
		#printf("Max turn is %.1f deg/sec at this speed/altitude. Doing %.1f deg/sec at mach %.1f.", me.turnSpeed, me.rollNorm*me.turnSpeed,me.mach);
		if (me.GStoKIAS(me.speed) < (150*KT2MPS) or me.ground == nil or me.ground > me.alt) {
			print("spd "~me.GStoKIAS(me.speed*MPS2KT));
			print("agl "~(me.ground == nil?"nil":(""~(me.alt-me.ground)*M2FT)));
			me.reset();
		}
	},

	apply: func {
		me.nodeLat.setDoubleValue(me.lat);
		me.nodeLon.setDoubleValue(me.lon);
		me.nodeAlt.setDoubleValue(me.alt*M2FT);
		me.nodeHeading.setDoubleValue(me.heading);
		me.nodePitch.setDoubleValue(me.pitch);
		me.nodeRoll.setDoubleValue(me.roll);
		me.ai.getNode("velocities/true-airspeed-kt",1).setDoubleValue(me.speed*MPS2KT);
		me.ai.getNode("instrumentation/transponder/transmitted-id",1).setIntValue(num_t);
		me.a16Coord = geo.aircraft_position();
		me.ai.getNode("radar/bearing-deg", 1).setDoubleValue(me.a16Coord.course_to(me.coord));
		me.ai.getNode("radar/elevation-deg", 1).setDoubleValue(vector.Math.getPitch(me.a16Coord, me.coord));
		me.ai.getNode("radar/range-nm", 1).setDoubleValue(me.a16Coord.distance_to(me.coord)*M2NM);
		me.ai.getNode("velocities/vertical-speed-fps",1).setDoubleValue(me.speed*M2FT*math.sin(me.pitch*D2R));
		me.ai.getNode("rotors/main/blade[3]/position-deg", 1 ).setDoubleValue(rand());#chaff
		me.ai.getNode("rotors/main/blade[3]/flap-deg", 1 ).setDoubleValue(rand());#flares
		settimer(func {me.decide();}, 0.025);
	},

	machNow: func (speed, altitude) {
		me.T = 0;
		if (altitude < 36152) {
			# curve fits for the troposphere
			me.T = 59 - 0.00356 * altitude;
		} elsif ( 36152 < altitude and altitude < 82345 ) {
			# lower stratosphere
			me.T = -70;
		} else {
			# upper stratosphere
			me.T = -205.05 + (0.00164 * altitude);
		}

		# calculate the speed of sound at altitude
		me.snd_speed = math.sqrt( 1.4 * 1716 * (me.T + 459.7));

		return speed/me.snd_speed;
	},

	turnMax: func (mach, altitude) {
		# degs / sec , drag index 50
		# taken from Greek F-16 block 52 supplemental manual.
		if (mach>0.8) {
			me.a10 = me.extrapolate(mach, 0.8, 1.3, MAX_TURN_SPEED, 12);
			me.g10 = 9;
		} else {
			me.a10 = me.extrapolate(mach, 0.2, 0.8, 6, MAX_TURN_SPEED);
			me.g10 = me.extrapolate(mach, 0.2, 0.8, 3, 9);
		}
		if (mach>1) {
			me.a20 = me.extrapolate(mach, 1, 1.5, 16, 10);
			me.g20 = 9;
		} else {
			me.a20 = me.extrapolate(mach, 0, 1, 4, 16);
			me.g20 = me.extrapolate(mach, 0, 1, 3, 9);
		}
		if (mach>1.1) {
			me.a30 = me.extrapolate(mach, 1.1, 1.7, 12.5, 9);
			me.g30 = 9;
		} else {
			me.a30 = me.extrapolate(mach, 0.5, 1.1, 6, 12.5);
			me.g30 = me.extrapolate(mach, 0.5, 1.1, 3, 9);
		}
		if (mach>1.1) {
			me.a40 = me.extrapolate(mach, 1.1, 1.8, 8, 6);
			me.g40 = 9;
		} else {
			me.a40 = me.extrapolate(mach, 0.6, 1.1, 4, 8);
			me.g40 = me.extrapolate(mach, 0.6, 1.1, 3, 9);
		}
		if (altitude < 20000) {
			return [me.extrapolate(altitude, 10000, 20000, me.a10, me.a20), me.extrapolate(altitude, 10000, 20000, me.g10, me.g20)];
		} elsif (altitude < 30000) {
			return [me.extrapolate(altitude, 20000, 30000, me.a20, me.a30), me.extrapolate(altitude, 20000, 30000, me.g20, me.g30)];
		} elsif (altitude < 40000) {
			return [me.extrapolate(altitude, 30000, 40000, me.a30, me.a40), me.extrapolate(altitude, 30000, 40000, me.g30, me.g40)];
		} else {
			return [me.a40,me.g40]
		}
	},

	accMax: func {
		# mps / sec , drag index 50, 24000 lbm
		# taken from Greek F-16 block 52 supplemental manual.
		#
		# 10000:
		# 650 16 10 8 4 3 4 4 3 4 4 200
		# 
		# 20000
		# 650 34 15 11 9 8 5 6 6 6 7 200
		# 
		# 30000
		# 600 38 21 17 14 14 11 10 11 12 200
		#
		# 40000
		# 500 47 34 29 27 29 21 26 200
		me.kias = me.GStoKIAS(me.speed*MPS2KT);
		me.a10 = 0;
		if (me.kias > 650) {
			me.a10 = 16;
		} elsif (me.kias > 600) {
			me.a10 = 10;
		} elsif (me.kias > 550) {
			me.a10 = 8;
		} elsif (me.kias > 500) {
			me.a10 = 4;
		} elsif (me.kias > 450) {
			me.a10 = 3;
		} elsif (me.kias > 400) {
			me.a10 = 4;
		} elsif (me.kias > 350) {
			me.a10 = 4;
		} elsif (me.kias > 300) {
			me.a10 = 3;
		} elsif (me.kias > 250) {
			me.a10 = 4;
		} else {
			me.a10 = 4;
		}
		me.a10 = me.KIAStoGS(50)*KT2MPS/me.a10;

		me.a20 = 0;
		if (me.kias > 650) {
			me.a20 = me.KIAStoGS(50)*KT2MPS/34;
		} elsif (me.kias > 600) {
			me.a20 = me.KIAStoGS(50)*KT2MPS/15;
		} elsif (me.kias > 550) {
			me.a20 = me.KIAStoGS(50)*KT2MPS/11;
		} elsif (me.kias > 500) {
			me.a20 = me.KIAStoGS(50)*KT2MPS/9;
		} elsif (me.kias > 450) {
			me.a20 = me.KIAStoGS(50)*KT2MPS/8;
		} elsif (me.kias > 400) {
			me.a20 = me.KIAStoGS(50)*KT2MPS/5;
		} elsif (me.kias > 350) {
			me.a20 = me.KIAStoGS(50)*KT2MPS/6;
		} elsif (me.kias > 300) {
			me.a20 = me.KIAStoGS(50)*KT2MPS/6;
		} elsif (me.kias > 250) {
			me.a20 = me.KIAStoGS(50)*KT2MPS/6;
		} else {
			me.a20 = me.KIAStoGS(50)*KT2MPS/7;
		}

		me.a30 = 0;
		if (me.kias > 600) {
			me.a30 = me.KIAStoGS(50)*KT2MPS/38;
		} elsif (me.kias > 550) {
			me.a30 = me.KIAStoGS(50)*KT2MPS/21;
		} elsif (me.kias > 500) {
			me.a30 = me.KIAStoGS(50)*KT2MPS/17;
		} elsif (me.kias > 450) {
			me.a30 = me.KIAStoGS(50)*KT2MPS/14;
		} elsif (me.kias > 400) {
			me.a30 = me.KIAStoGS(50)*KT2MPS/14;
		} elsif (me.kias > 350) {
			me.a30 = me.KIAStoGS(50)*KT2MPS/11;
		} elsif (me.kias > 300) {
			me.a30 = me.KIAStoGS(50)*KT2MPS/10;
		} elsif (me.kias > 250) {
			me.a30 = me.KIAStoGS(50)*KT2MPS/11;
		} else {
			me.a30 = me.KIAStoGS(50)*KT2MPS/12;
		}

		me.a40 = 0;
		if (me.kias > 500) {
			me.a40 = me.KIAStoGS(50)*KT2MPS/47;
		} elsif (me.kias > 450) {
			me.a40 = me.KIAStoGS(50)*KT2MPS/34;
		} elsif (me.kias > 400) {
			me.a40 = me.KIAStoGS(50)*KT2MPS/29;
		} elsif (me.kias > 350) {
			me.a40 = me.KIAStoGS(50)*KT2MPS/27;
		} elsif (me.kias > 300) {
			me.a40 = me.KIAStoGS(50)*KT2MPS/29;
		} elsif (me.kias > 250) {
			me.a40 = me.KIAStoGS(50)*KT2MPS/21;
		} else {
			me.a40 = me.KIAStoGS(50)*KT2MPS/26;
		}

		
		if (me.alt*M2FT > 30000) {
			return me.extrapolate(me.alt*M2FT, 30000, 40000, me.a30, me.a40);
		} elsif (me.alt*M2FT > 20000) {
			return me.extrapolate(me.alt*M2FT, 20000, 30000, me.a20, me.a30);
		} else {
			return me.extrapolate(me.alt*M2FT, 10000, 20000, me.a10, me.a20);
		}
	},

	deaccMax: func {
		# mps / sec , drag index 50
		# taken from Greek F-16 block 52 supplemental manual.
		#
		# 20000:
		# 1.6M - 1.4M : 9s 1000-850 16.66 kt/sec
		# 1.4 - 1.2 : 12s   850-725 10.41
		# 1.2 - 1.0 : 12s   725-600 10.41
		# 1.0 - 0.8 : 30s   600-500  3.33
		# 0.8 - 0.6 : 48s   500-375  2.60

		# 30000:
		# 1.8M - 1.1M : 66s 1050-650  6.06
		# 1.1 - 0.8 : 78s    650-450  2.56

		# 40000:
		# 1.8M - 1.4M : 30s 1050-800  8.33
		# 1.4 - 1.0 : 60s    800-575  3.75
		# 1.0 - 0.8 : 60s    575-450  2.08

		me.a20 = 0;
		if (me.mach > 1.4) {
			me.a20 = 16.66*KT2MPS;
		} elsif (me.mach > 1.2) {
			me.a20 = 10.41*KT2MPS;
		} elsif (me.mach > 1.0) {
			me.a20 = 10.41*KT2MPS;
		} elsif (me.mach > 0.8) {
			me.a20 = 3.33*KT2MPS;
		} else {
			me.a20 = 2.60*KT2MPS;
		}
		me.a30 = 0;
		if (me.mach > 1.1) {
			me.a30 = 6.06*KT2MPS;
		} else {
			me.a30 = 2.56*KT2MPS;
		}
		me.a40 = 0;
		if (me.mach > 1.4) {
			me.a40 = 8.33*KT2MPS;
		} elsif (me.mach > 1.0) {
			me.a40 = 3.75*KT2MPS;
		} else {
			me.a40 = 2.08*KT2MPS;
		}
		if (me.alt*M2FT > 30000) {
			return me.extrapolate(me.alt*M2FT, 30000, 40000, me.a30, me.a40);
		} else {
			return me.extrapolate(me.alt*M2FT, 20000, 30000, me.a20, me.a30);
		}
	},

	KIAStoGS: func (kias) {
		return (0.02*(M2FT*me.alt*0.001)+1)*kias;
	},

	GStoKIAS: func (gs) {
		return gs/(0.02*(M2FT*me.alt*0.001)+1);
	},

	extrapolate: func (x, x1, x2, y1, y2) {
    	return y1 + ((x - x1) / (x2 - x1)) * (y2 - y1);
	},
};

var GO_AHEAD   = 0;
var GO_LEFT    = 1;
var GO_RIGHT   = 2;
var GO_UP      = 3;
var GO_DOWN    = 4;
var GO_IMMEL   = 5;
var GO_SPLIT_S = 6;
var GO_AIM     = 7;
var GO_SCISSOR = 8;
var GO_BREAK_UP = 9;
var GO_BREAK_DOWN = 10;

var MAX_ROLL = 80;
var MAX_ROLL_SPEED = 180;
var MAX_PITCH_UP_SPEED = 15;
var MAX_PITCH_DOWN_SPEED = 5;
var MAX_TURN_SPEED = 18;#do not mess with this number unless porting the system to another aircraft.

var BLEED_FACTOR = 1.0;
var num_t = "0000";
var ENDURANCE = 10;

var tg1 = TopGun.new(0);
var tg2 = TopGun.new(180);

var start = func (diff = 1) {
	if (diff < 1 or diff > 5) {
		print("Difficulty goes from 1 (easy), 2 (normal), 3 (hard), 4 (veteran) to 5 (master), try again.");
		return;
	}
	print("Difficulty set to: "~diff);
	if (diff == 1) {
		MAX_ROLL_SPEED = 25;
		BLEED_FACTOR = 1.2;
		num_t = "0000";
		ENDURANCE = 10;
		tg1.callsign = "Lt.Endo";
		tg1.start();
	} elsif (diff == 2) {
		MAX_ROLL_SPEED = 25;
		BLEED_FACTOR = 1.0;
		num_t = "0000";
		ENDURANCE = 15;
		tg1.callsign = "Cpt.Cas";
		tg1.start();
	} elsif (diff == 3) {
		MAX_ROLL_SPEED = 30;
		BLEED_FACTOR = 0.9;
		num_t = "-9999";
		ENDURANCE = 20;
		tg1.callsign = "Maj.Rap";
		tg1.start();
	} elsif (diff == 4) {
		MAX_ROLL_SPEED = 25;
		BLEED_FACTOR = 1.0;
		num_t = "0000";
		ENDURANCE = 10;
		tg1.callsign = "Cpt.Rap";
		tg2.callsign = "Cpt.Cas";
		tg1.start();
		tg2.start();
	} elsif (diff == 5) {
		MAX_ROLL_SPEED = 30;
		BLEED_FACTOR = 1.0;
		num_t = "-9999";
		ENDURANCE = 15;
		tg1.callsign = "Cpt.Rap";
		tg2.callsign = "Maj.Cas";
		tg1.start();
		tg2.start();
	}
}

var stop = func {
	tg1.stop();
	tg2.stop();
}


# TODO:
#  make him switch on and off his radar in hard mode.
#  lower floor
#  make him respect blackout and redout.
#  make hits affect mig28
#  make mig28 fire fox2/fox3
