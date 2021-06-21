
#  ███████        ██  ██████      ██████  ██     ██ ██████  
#  ██            ███ ██           ██   ██ ██     ██ ██   ██ 
#  █████   █████  ██ ███████      ██████  ██  █  ██ ██████  
#  ██             ██ ██    ██     ██   ██ ██ ███ ██ ██   ██ 
#  ██             ██  ██████      ██   ██  ███ ███  ██   ██ 
#                                                           
#                                                           
var RWR = {
	# inherits from Radar
	# will check radar/transponder and ground occlusion.
	# will sort according to threat level
	new: func () {
		var rr = {parents: [RWR, Radar]};

		rr.vector_aicontacts = [];
		rr.vector_aicontacts_threats = [];
		#rr.timer          = maketimer(2, rr, func rr.scan());

		rr.RWRRecipient = emesary.Recipient.new("RWRRecipient");
		rr.RWRRecipient.radar = rr;
		rr.RWRRecipient.Receive = func(notification) {
	        if (notification.NotificationType == "OmniNotification") {
	        	#printf("RWR recv: %s", notification.NotificationType);
	            if (me.radar.enabled == 1) {
	    		    me.radar.vector_aicontacts = notification.vector;
	    		    me.radar.scan();
	    	    }
	            return emesary.Transmitter.ReceiptStatus_OK;
	        }
	        return emesary.Transmitter.ReceiptStatus_NotProcessed;
	    };
		emesary.GlobalTransmitter.Register(rr.RWRRecipient);
		#nr.FORNotification = VectorNotification.new("FORNotification");
		#nr.FORNotification.updateV(nr.vector_aicontacts_for);
		#rr.timer.start();
		return rr;
	},
	heatDefense: 0,
	scan: func {
		# sort in threat?
		# run by notification
		# mock up code, ultra simple threat index, is just here cause rwr have special needs:
		# 1) It has almost no range restriction
		# 2) Its omnidirectional
		# 3) It might have to update fast (like 0.25 secs)
		# 4) To build a proper threat index it needs at least these properties read:
		#       model type
		#       class (AIR/SURFACE/MARINE)
		#       lock on myself
		#       missile launch
		#       transponder on/off
		#       bearing and heading
		#       IFF info
		#       ECM
		#       radar on/off
		if (!getprop("instrumentation/rwr/serviceable") or getprop("f16/avionics/power-ufc-warm") != 1 or getprop("f16/avionics/ew-rwr-switch") != 1) {
            setprop("sound/rwr-lck", 0);
            setprop("ai/submodels/submodel[0]/flare-auto-release-cmd", 0);
            return;
        }
        me.vector_aicontacts_threats = [];
		me.fct = 10*2.0;
        me.myCallsign = self.getCallsign();
        me.myCallsign = size(me.myCallsign) < 8 ? me.myCallsign : left(me.myCallsign,7);
        me.act_lck = 0;
        me.autoFlare = 0;
        me.closestThreat = 0;
        me.elapsed = elapsedProp.getValue();
        foreach(me.u ; me.vector_aicontacts) {
        	#contact.storeThreat([me.ber,me.head,contact.getCoord(),me.tp,me.radar,contact.getDeviationHeading(),contact.getRangeDirect()*M2NM, contact.getCallsign()]);
        	me.threatDB = me.u.getThreatStored();
            me.cs = me.threatDB[7];
            me.rn = me.threatDB[6];
            me.lnk16 = me.cs==nil?nil:datalink.get_data(me.cs);
            if ((me.lnk16 != nil and me.lnk16.on_link() == 1) or me.rn > 150) {
                continue;
            }
            me.bearing = me.threatDB[0];
            me.trAct = me.threatDB[3];
            me.show = 1;
            me.heading = me.threatDB[1];
            me.inv_bearing =  me.bearing+180;#bearing from target to me
            me.deviation = me.inv_bearing - me.heading;# bearing deviation from target to me
            me.dev = math.abs(geo.normdeg180(me.deviation));# my degrees from opponents nose
            
            if (me.show == 1) {
                if (me.dev < 30 and me.rn < 7 and me.threatDB[8] > 60) {
                    # he is in position to fire heatseeker at me
                    me.heatDefenseNow = me.elapsed + me.rn*1.5;
                    if (me.heatDefenseNow > me.heatDefense) {
                        me.heatDefense = me.heatDefenseNow;
                    }
                }
                me.threat = 0;
                if (me.u.getModel() != "missile_frigate" and me.u.getModel() != "S-75" and me.u.getModel() != "buk-m2" and me.u.getModel() != "MIM104D" and me.u.getModel() != "s-300" and me.u.getModel() != "fleet" and me.u.getModel() != "ZSU-23-4M") {
                    me.threat += ((180-me.dev)/180)*0.30;# most threat if I am in front of his nose
                    me.spd = (60-me.threatDB[8])/60;
                    me.threat -= me.spd>0?me.spd:0;# if his speed is lower than 60kt then give him minus threat else positive
                } elsif (me.u.getModel == "missile_frigate" or me.u.getModel() == "fleet") {
                    me.threat += 0.30;
                } else {
                    me.threat += 0.30;
                }
                me.danger = 50;# within this range he is most dangerous
                if (me.u.getModel() == "missile_frigate" or me.u.getModel() == "fleet" or me.u.getModel() == "s-300") {
                    me.danger = 80;
                } elsif (me.u.getModel() == "buk-m2" or me.u.getModel() == "S-75") {
                    me.danger = 35;
                } elsif (me.u.getModel() == "MIM104D") {
                    me.danger = 45;
                } elsif (me.u.getModel() == "ZSU-23-4M") {
                    me.danger = 7.5;
                }
                me.threat += ((me.danger-me.rn)/me.danger)>0?((me.danger-me.rn)/me.danger)*0.60:0;# if inside danger zone then add threat, the closer the more.
                me.threat += me.threatDB[9]>0?(me.threatDB[9]/500)*0.10:0;# more closing speed means more threat.
                if (me.threat > me.closestThreat) me.closestThreat = me.threat;
                if (me.threat > 1) me.threat = 1;
                if (me.threat <= 0) continue;
#                printf("%s threat:%.2f range:%d dev:%d", me.u.get_Callsign(),me.threat,me.u.get_range(),me.deviation);
                append(me.vector_aicontacts_threats,[me.u,me.threat, me.threatDB[5]]);
            } else {
#                printf("%s ----", me.u.get_Callsign());
            }
        }

        me.launchClose = getprop("payload/armament/MLW-launcher") != "";
        me.incoming = getprop("payload/armament/MAW-active") or me.heatDefense > me.elapsed;
        me.spike = getprop("payload/armament/spike")*(getprop("ai/submodels/submodel[0]/count")>15);
        me.autoFlare = me.spike?math.max(me.closestThreat*0.25,0.05):0;

        #print("spike: ",me.spike,"  incoming: ",me.incoming, "  launch: ",me.launchClose,"  spikeResult:", me.autoFlare,"  aggresive:",me.launchClose * 0.85 + me.incoming * 0.85,"  total:",me.launchClose * 0.85 + me.incoming * 0.85+me.autoFlare);

        me.autoFlare += me.launchClose * 0.85 + me.incoming * 0.85;

        me.autoFlare *= 0.1 * 2.5 * !getprop("gear/gear[0]/wow");#0.1 being the update rate for flare dropping code.

        setprop("ai/submodels/submodel[0]/flare-auto-release-cmd", me.autoFlare * (getprop("ai/submodels/submodel[0]/count")>0));
        if (me.autoFlare > 0.80 and rand()>0.99 and getprop("ai/submodels/submodel[0]/count") < 1) {
            setprop("ai/submodels/submodel[0]/flare-release-out-snd", 1);
        }
	},
	del: func {
        emesary.GlobalTransmitter.DeRegister(me.RWRRecipient);
    },
};



#  ██████   █████  ████████  █████  ██      ██ ███    ██ ██   ██ 
#  ██   ██ ██   ██    ██    ██   ██ ██      ██ ████   ██ ██  ██  
#  ██   ██ ███████    ██    ███████ ██      ██ ██ ██  ██ █████   
#  ██   ██ ██   ██    ██    ██   ██ ██      ██ ██  ██ ██ ██  ██  
#  ██████  ██   ██    ██    ██   ██ ███████ ██ ██   ████ ██   ██ 
#                                                                
#                                                                
DatalinkRadar = {
	# I check the sky 360 deg for anything on datalink
	# This class is only semi generic!
	new: func (rate, max_dist_nm) {
		var dlnk = {parents: [DatalinkRadar, Radar]};
		
		dlnk.max_dist_nm = max_dist_nm;
		dlnk.index = 0;
		dlnk.vector_aicontacts = [];
		dlnk.vector_aicontacts_for = [];
		dlnk.timer          = maketimer(rate, dlnk, func dlnk.scan());

		dlnk.DatalinkRadarRecipient = emesary.Recipient.new("DatalinkRadarRecipient");
		dlnk.DatalinkRadarRecipient.radar = dlnk;
		dlnk.DatalinkRadarRecipient.Receive = func(notification) {
	        if (notification.NotificationType == "AINotification") {
	        	#printf("NoseRadar recv: %s", notification.NotificationType);
	            if (me.radar.enabled == 1) {
	    		    me.radar.vector_aicontacts = notification.vector;
	    		    me.radar.index = 0;
	    	    }
	            return emesary.Transmitter.ReceiptStatus_OK;
	        }
	        return emesary.Transmitter.ReceiptStatus_NotProcessed;
	    };
		emesary.GlobalTransmitter.Register(dlnk.DatalinkRadarRecipient);
		dlnk.DatalinkNotification = VectorNotification.new("DatalinkNotification");
		dlnk.DatalinkNotification.updateV(dlnk.vector_aicontacts_for);
		dlnk.timer.start();
		return omni;
	},

	scan: func () {
		if (!me.enabled) return;
		
		#this loop is really fast. But we only check 1 contact per call
		if (me.index >= size(me.vector_aicontacts)) {
			# will happen if there is no contacts
			me.index = 0;
			return;
		}
		me.contact = me.vector_aicontacts[me.index];
		me.wasBlue = me.contact["blue"];
		if (me.wasBlue == nil) me.wasBlue = 0;

		if (me.contact.getRangeDirect()*M2NM > me.max_dist_nm) {me.index += 1;return;}
		me.cs = me.contact.get_Callsign();

        me.lnk = datalink.get_data(me.cs);
        if (me.lnk != nil and me.lnk.on_link() == 1) {
            me.blue = 1;
            me.blueIndex = me.lnk.index()+1;
        } elsif (me.cs == getprop("link16/wingman-4")) {
            me.blue = 1;
            me.blueIndex = 2;
        } else {
        	me.blue = 0;
            me.blueIndex = -1;
        }
        if (!me.blue and me.lnk != nil and me.lnk.tracked() == 1) {
            me.blue = 2;
            me.blueIndex = me.lnk.tracked_by_index()+1;
        }

        if (me.blue ==1 or me.blue ==2) {
        	me.contact.blue = me.blue;
        	me.contact.blueIndex = me.blueIndex;
			if (!apg68Radar.containsVectorContact(me.vector_aicontacts_for, me.contact)) {
				append(me.vector_aicontacts_for, me.contact);
				emesary.GlobalTransmitter.NotifyAll(me.DatalinkNotification.updateV(me.vector_aicontacts_for));
			}
		} elsif (me.wasBlue > 0) {
			me.contact.blue = me.blue;
			me.new_vector_aicontacts_for = [];
			foreach (me.c ; me.vector_aicontacts_for) {
				if (!me.c.equals(me.contact)) {
					append(me.new_vector_aicontacts_for, me.contact);
				}
			}
			me.vector_aicontacts_for = me.new_vector_aicontacts_for;
		}
		me.index += 1;
        if (me.index > size(me.vector_aicontacts)-1) {
        	me.index = 0;
        	emesary.GlobalTransmitter.NotifyAll(me.DatalinkNotification.updateV(me.vector_aicontacts_for));
        } else {
        }
	},
	del: func {
        emesary.GlobalTransmitter.DeRegister(me.DatalinkRadarRecipient);
    },
};








var FOR_ROUND  = 0;# TODO: be able to ask noseradar for round field of regard.
var FOR_SQUARE = 1;


#   █████  ██████   ██████         ██████   █████  
#  ██   ██ ██   ██ ██             ██       ██   ██ 
#  ███████ ██████  ██   ███ █████ ███████   █████  
#  ██   ██ ██      ██    ██       ██    ██ ██   ██ 
#  ██   ██ ██       ██████         ██████   █████  
#                                                  
#                                                  
var APG68 = {
	fieldOfRegardType: FOR_SQUARE,
	fieldOfRegardMaxAz: 60,
	fieldOfRegardMaxElev: 60,
	currentMode: nil, # vector of cascading modes ending with current submode
	currentModeIndex: 0,
	rootMode: 0,# 0: CRM  1: ACM 2: SEA 3: GM 4: GMT
	mainModes: nil,
	instantFoVradius: 3.90*0.5,#average of horiz/vert radius
	rcsRefDistance: 70,
	rcsRefValue: 3.2,
	targetHistory: 3,# Not used in TWS
	tilt: 0,
	tiltOverride: 0,# when enabled by a mode: the mode can set the tilt, and it will not be read from property (TODO)
	maxTilt: 60,#TODO: Lower this a bit
	positionEuler: [0,0,0,0],# euler direction
	positionDirection: [1,0,0],# vector direction
	positionCart: [0,0,0,0],
	horizonStabilized: 1, # When true antennae ignore roll (and pitch until its high)
	vector_aicontacts_for: [],# vector of contacts found in field of regard
	vector_aicontacts_bleps: [],# vector of not timed out bleps
	timer: nil,
	timerMedium: nil,
	timerSlow: nil,
	elapsed: elapsedProp.getValue(),
	lastElapsed: elapsedProp.getValue(),
	new: func (mainModes) {
		var rdr = {parents: [APG68, Radar]};

		rdr.mainModes = mainModes;
		
		foreach (modes ; mainModes) {
			foreach (mode ; modes) {
				# this needs to be set on submodes also...hmmm
				mode.radar = rdr;
			}
		}

		rdr.setCurrentMode(rdr.mainModes[0][0], nil);

		rdr.SliceNotification = SliceNotification.new();
		rdr.ContactNotification = VectorNotification.new("ContactNotification");
		rdr.ActiveDiscRadarRecipient = emesary.Recipient.new("ActiveDiscRadarRecipient");
		rdr.ActiveDiscRadarRecipient.radar = rdr;
		rdr.ActiveDiscRadarRecipient.Receive = func(notification) {
	        if (notification.NotificationType == "FORNotification") {
	        	#printf("DiscRadar recv: %s", notification.NotificationType);
	            if (rdr.enabled == 1) {
	    		    rdr.vector_aicontacts_for = notification.vector;
	    		    rdr.purgeBleps();
	    		    #print("size(rdr.vector_aicontacts_for)=",size(rdr.vector_aicontacts_for));
	    	    }
	            return emesary.Transmitter.ReceiptStatus_OK;
	        }
	        return emesary.Transmitter.ReceiptStatus_NotProcessed;
	    };
		emesary.GlobalTransmitter.Register(rdr.ActiveDiscRadarRecipient);
		rdr.timer = maketimer(scanInterval, rdr, func rdr.loop());
		rdr.timerSlow = maketimer(0.75, rdr, func rdr.loopSlow());
		rdr.timerMedium = maketimer(0.25, rdr, func rdr.loopMedium());
		rdr.timerMedium.start();
		rdr.timerSlow.start();
		rdr.timer.start();
    	return rdr;
	},
	getTilt: func {# TODO: rename to tiltKnob
		return antennae_knob_prop.getValue()*60;
	},
	increaseRange: func {
		me.currentMode.increaseRange();
	},
	decreaseRange: func {
		me.currentMode.decreaseRange();
	},
	designate: func (designate_contact) {
		me.currentMode.designate(designate_contact);
	},
	designateRandom: func {
		if (size(me.vector_aicontacts_bleps)>0) {
			if (me.currentMode.shortName != "TWS") {
				me.designate(me.vector_aicontacts_bleps[size(me.vector_aicontacts_bleps)-1]);
			} else {
				if (me.currentMode.priorityTarget != nil) {
					me.designate(me.currentMode.priorityTarget);
					return;
				} else {
					foreach(c;me.vector_aicontacts_bleps) {
						if (c.hadTrackInfo() and elapsedProp.getValue()-c.getLastBlepTime() < F16TWSMode.maxScanIntervalForTrack) {
							me.designate(c);
							return;
						}
					}
				}
				me.designate(me.vector_aicontacts_bleps[size(me.vector_aicontacts_bleps)-1]);
			}
		}
	},
	undesignate: func {
		me.currentMode.undesignate();
	},
	getPriorityTarget: func {
		if (!me.enabled) return nil;
		return me.currentMode.getPriority();
	},
	cycleDesignate: func {
		me.currentMode.cycleDesignate();
	},
	cycleMode: func {
		me.currentModeIndex += 1;
		if (me.currentModeIndex >= size(me.mainModes[me.rootMode])) {
			me.currentModeIndex = 0;
		}
		me.newMode = me.mainModes[me.rootMode][me.currentModeIndex];
		me.newMode.setRange(me.currentMode.getRange());
		me.oldMode = me.currentMode;
		me.setCurrentMode(me.newMode, me.oldMode["priorityTarget"]);
		me.oldMode.leaveMode();
	},
	cycleRootMode: func {
		me.rootMode += 1;
		if (me.rootMode >= size(me.mainModes)) {
			me.rootMode = 0;
		}
		me.currentModeIndex = 0;
		me.newMode = me.mainModes[me.rootMode][me.currentModeIndex];
		#me.newMode.setRange(me.currentMode.getRange());
		me.oldMode = me.currentMode;
		me.setCurrentMode(me.newMode, me.oldMode["priorityTarget"]);
		me.oldMode.leaveMode();
	},
	cycleAZ: func {
		me.currentMode.cycleAZ();
	},
	showAZ: func {
		me.currentMode.showAZ();
	},
	cycleBars: func {
		me.currentMode.cycleBars();
	},
	setDeviation: func (dev_tilt_deg) {
		if (me.getAzimuthRadius() == me.fieldOfRegardMaxAz) {
			dev_tilt_deg = 0;
		}
		me.currentMode.setDeviation(dev_tilt_deg);
	},
	getDeviation: func {
		return me.currentMode.getDeviation();
	},
	setCursorDeviation: func (cursor_az) {
		return me.currentMode.setCursorDeviation(cursor_az);
	},
	getCursorDeviation: func {
		return me.currentMode.getCursorDeviation();
	},
	setCursorDistance: func (nm) {
		# Return if the cursor should be distance zeroed.
		if (nm < me.getRange()*0.05) {
			return me.decreaseRange();
		} elsif (nm > me.getRange()*0.95) {
			return me.increaseRange();
		}
		me.currentMode.setCursorDistance(nm);
		return 0;
	},
	getCursorAltitudeLimits: func {
		return me.currentMode.getCursorAltitudeLimits();
	},	
	getBars: func {
		return me.currentMode.getBars();
	},
	getAzimuthRadius: func {
		return me.currentMode.getAz();
	},
	getMode: func {
		return me.currentMode.shortName;
	},
	setCurrentMode: func (new_mode, priority = nil) {
		me.currentMode = new_mode;
		new_mode.radar = me;
		#new_mode.setCursorDeviation(me.currentMode.getCursorDeviation()); # no need since submodes don't overwrite this
		new_mode.designatePriority(priority);
		new_mode.enterMode();
	},
	setRootMode: func (mode_number, priority = nil) {
		me.rootMode = mode_number;
		if (me.rootMode >= size(me.mainModes)) {
			me.rootMode = 0;
		}
		me.currentModeIndex = 0;
		me.newMode = me.mainModes[me.rootMode][me.currentModeIndex];
		#me.newMode.setRange(me.currentMode.getRange());
		me.oldMode = me.currentMode;
		me.setCurrentMode(me.newMode, priority);
		me.oldMode.leaveMode();
	},
	getRange: func {
		return me.currentMode.getRange();
	},
	setAntennae: func (local_dir) {
		# remember to set horizonStabilized when calling this.
		me.eulerDir = vector.Math.cartesianToEuler(local_dir);
		me.eulerX = me.eulerDir[0]==nil?0:geo.normdeg180(me.eulerDir[0]);
		me.positionEuler = [me.eulerX,me.eulerDir[1],me.eulerX/me.fieldOfRegardMaxAz,me.eulerDir[1]/me.fieldOfRegardMaxElev];
		me.positionDirection = vector.Math.normalize(local_dir);
		me.posAZDeg = -90+R2D*math.acos(vector.Math.normalize(vector.Math.projVectorOnPlane([0,0,1],me.positionDirection))[1]);
		me.posElDeg = R2D*math.asin(vector.Math.normalize(vector.Math.projVectorOnPlane([0,1,0],me.positionDirection))[2]);
		me.positionCart = [me.posAZDeg/me.fieldOfRegardMaxAz, me.posElDeg/me.fieldOfRegardMaxElev,me.posAZDeg,me.posElDeg];
		#print("On sky: ",me.eulerDir[1], "  disc: ",me.posElDeg);
	},
	loop: func {
		me.enabled = getprop("/f16/avionics/power-fcr-bit") == 2 and !getprop("instrumentation/radar/radar-standby");
		if (me.enabled) {
			me.elapsed = elapsedProp.getValue();
			me.dt = me.elapsed - me.lastElapsed;
			me.lastElapsed = me.elapsed;
			if (!me.tiltOverride) {
				me.tilt = antennae_knob_prop.getValue()*60;
			}
			while (me.dt > 0.001) {
				# mode tells us how to move disc and to scan
				me.dt = me.currentMode.step(me.dt, me.tilt);# mode already knows where in pattern we are and AZ and bars.
				# we then step to the new position, and scan for each step
				me.scanFOV();
			}
		}
	},
	loopMedium: func {
		if (me.enabled) {
			me.focus = me.getPriorityTarget();
			if (me.focus != nil and me.focus.callsign != "") {
				if (me.currentMode["painter"] == 1) sttSend.setValue(left(md5(me.focus.callsign), 4));
				else sttSend.setValue("");
				if (steerpoints.sending == nil) {
			        datalink.send_data({"contacts":[{"callsign":me.focus.callsign,"iff":0}]});
			    }
			} else {
				sttSend.setValue("");
				if (steerpoints.sending == nil) {
		            datalink.clear_data();
		        }
			}
			armament.contact = me.focus;
			stbySend.setIntValue(0);
		} else {
			armament.contact = nil;
			sttSend.setValue("");
			stbySend.setIntValue(1);
			if (steerpoints.sending == nil) {
	            datalink.clear_data();
	        }
		}
	},

	loopSlow: func {
		if (me.enabled) {
			# 1.414 = cos(45 degs)
			emesary.GlobalTransmitter.NotifyAll(me.SliceNotification.slice(self.getPitch(), self.getHeading(), me.fieldOfRegardMaxElev*1.414, me.fieldOfRegardMaxAz*1.414, me.getRange()*NM2M, !me.currentMode.detectAIR, !me.currentMode.detectSURFACE, !me.currentMode.detectMARINE));
		}
	},
	scanFOV: func {
		me.doIFF = getprop("instrumentation/radar/iff");
    	setprop("instrumentation/radar/iff",0);
		foreach(contact ; me.vector_aicontacts_for) {
			if (me.doIFF == 1) {
	            me.iffr = iff.interrogate(contact.prop);
	            if (me.iffr) {
	                u.iff = me.elapsed;
	            } else {
	                u.iff = -me.elapsed;
	            }
	        }
			if (me.elapsed - contact.getLastBlepTime() < me.currentMode.minimumTimePerReturn) continue;# To prevent double detecting in overlapping beams

			me.dev = contact.getDeviationStored();
			#print("Bearing ",me.dev[7],", Pitch ",me.dev[8]);
			if (me.horizonStabilized) {
				# ignore roll (and ignore pitch for now too, TODO)
				me.globalToTarget = vector.Math.eulerToCartesian3X(-me.dev[7],me.dev[8],0);
				me.localToTarget = vector.Math.rollPitchYawVector(0,0,self.getHeading(), me.globalToTarget);
			} else {
				me.localToTarget = vector.Math.eulerToCartesian3X(-me.dev[0],me.dev[1],0);
			}
			#print("ANT head ",me.positionX,", ANT elev ",me.positionY,", ANT tilt ", me.tilt);
			#print(vector.Math.format(me.localToTarget));
			me.beamDeviation = vector.Math.angleBetweenVectors(me.positionDirection, me.localToTarget);
			#print("me.beamDeviation ", me.beamDeviation);
			if (me.beamDeviation < me.instantFoVradius) {
				me.registerBlep(contact, me.dev);
				#print("REGISTER BLEP");

				# Return here, so that each instant FoV max gets 1 target:
				return;
			}
		}
	},
	registerBlep: func (contact, dev, doppler_check = 1) {
		if (!contact.isVisible()) return 0;
		if (doppler_check and contact.isHiddenFromDoppler()) return 0;
		me.maxDistVisible = me.currentMode.rcsFactor * me.targetRCSSignal(self.getCoord(), dev[3], contact.model, dev[4], dev[5], dev[6],me.rcsRefDistance*NM2M,me.rcsRefValue);

		if (me.maxDistVisible > dev[2]) {
			me.extInfo = me.currentMode.getSearchInfo(contact);# if the scan gives heading info etc..
			if (me.extInfo == nil) {
				return 0;
			}
			contact.blep(me.elapsed, me.extInfo, me.maxDistVisible);
			if (!me.containsVectorContact(me.vector_aicontacts_bleps, contact)) {
				append(me.vector_aicontacts_bleps, contact);
			}
			return 1;
		}
		return 0;
	},
	purgeBleps: func {
		#ok, lets clean up old bleps:
		me.vector_aicontacts_bleps_tmp = [];
		me.elapsed = elapsedProp.getValue();
		foreach(contact ; me.vector_aicontacts_bleps) {
			me.bleps_cleaned = [];
			foreach (me.blep;contact.getBleps()) {
				if (me.elapsed - me.blep[0] < me.currentMode.timeToKeepBleps) {
					append(me.bleps_cleaned, me.blep);
				}	
			}
			contact.setBleps(me.bleps_cleaned);
			if (size(me.bleps_cleaned)) {
				append(me.vector_aicontacts_bleps_tmp, contact);
				me.currentMode.testContact(contact);# TODO: do this smarter
			} else {
				me.currentMode.prunedContact(contact);
			}
		}
		#print("Purged ", size(me.vector_aicontacts_bleps) - size(me.vector_aicontacts_bleps_tmp), " bleps   remains:",size(me.vector_aicontacts_bleps_tmp), " orig ",size(me.vector_aicontacts_bleps));
		me.vector_aicontacts_bleps = me.vector_aicontacts_bleps_tmp;
	},
	purgeAllBleps: func {
		#ok, lets clean up old bleps:
		foreach(contact ; me.vector_aicontacts_bleps) {
			contact.setBleps([]);
		}
		me.vector_aicontacts_bleps = [];
	},
	targetRCSSignal: func(aircraftCoord, targetCoord, targetModel, targetHeading, targetPitch, targetRoll, myRadarDistance_m = 74000, myRadarStrength_rcs = 3.2) {
		#
		# test method. Belongs in rcs.nas.
		#
	    #print(targetModel);
	    me.target_front_rcs = nil;
	    if ( contains(rcs.rcs_oprf_database,targetModel) ) {
	        me.target_front_rcs = rcs.rcs_oprf_database[targetModel];
	    } elsif ( contains(rcs.rcs_database,targetModel) ) {
	        me.target_front_rcs = rcs.rcs_database[targetModel];
	    } else {
	        #return 1;
	        me.target_front_rcs = rcs.rcs_oprf_database["default"];
	    }	    
	    me.target_rcs = rcs.getRCS(targetCoord, targetHeading, targetPitch, targetRoll, aircraftCoord, me.target_front_rcs);

	    # standard formula
	    return myRadarDistance_m/math.pow(myRadarStrength_rcs/me.target_rcs, 1/4);
	},
	getActiveBleps: func {
		return me.vector_aicontacts_bleps;
	},
	containsVector: func (vec, item) {
		foreach(test; vec) {
			if (test == item) {
				return TRUE;
			}
		}
		return FALSE;
	},

	containsVectorContact: func (vec, item) {
		foreach(test; vec) {
			if (test.equals(item)) {
				return 1;
			}
		}
		return 0;
	},

	vectorIndex: func (vec, item) {
		me.i = 0;
		foreach(test; vec) {
			if (test == item) {
				return me.i;
			}
			me.i += 1;
		}
		return -1;
	},
	del: func {
        emesary.GlobalTransmitter.DeRegister(me.ActiveDiscRadarRecipient);
    },
};










#  ███    ███  ██████  ██████  ███████ ███████ 
#  ████  ████ ██    ██ ██   ██ ██      ██      
#  ██ ████ ██ ██    ██ ██   ██ █████   ███████ 
#  ██  ██  ██ ██    ██ ██   ██ ██           ██ 
#  ██      ██  ██████  ██████  ███████ ███████ 
#                                              
#                                              
var RadarMode = {
	azimuthTilt: 0,
	radar: nil,
	range: 40,
	minRange: 5, # MLU T1
	az: 60,
	bars: 4,
	lastTilt: nil,
	lastBars: nil,
	lastAz: nil,
	lastAzimuthTilt: nil,
	barHeight: 0.95,# multiple of instantFoV
	barPattern:  [ [[-1,0],[1,0]],
	               [[-1,-1],[1,-1],[1,1],[-1,1]],
	               [[-1,0],[1,0],[1,1.5],[-1,1.5],[-1,0],[1,0],[1,-1.5],[-1,-1.5]],
	               [[1,-3],[1,3],[-1,3],[-1,1],[1,1],[1,-1],[-1,-1],[-1,-3]] ],
	currentPattern: [],
	barPatternMin: [0,-1, -1.5, -3],
	barPatternMax: [0, 1,  1.5,  3],
	nextPatternNode: 0,
	scanPriorityEveryFrame: 0,
	timeToKeepBleps: 13,
	rootName: "CRM",
	shortName: "",
	longName: "",
	superMode: nil,
	minimumTimePerReturn: 1.25,
	rcsFactor: 0.9,
	lastFrameStart: -1,
	lastFrameDuration: 5,
	detectAIR: 1,
	detectSURFACE: 0,
	detectMARINE: 0,
	cursorAz: 0,
	cursorNm: 20,
	upperAngle: 10,
	lowerAngle: 10,
	EXPsupport: 0,#if support zoom
	EXPsearch: 1,# if zoom should include search targets
	showAZ: func {
		return 1;#me.az != 60; # hmm, does the blue lines at edge of b-scope look messy? If this return false, then they are also not shown in PPI.
	},
	showBars: func {
		return 1;
	},
	showRangeOptions: func {
		return 1;
	},
	setCursorDeviation: func (cursor_az) {
		me.cursorAz = cursor_az;
	},
	getCursorDeviation: func {
		return me.cursorAz;
	},
	setCursorDistance: func (nm) {
		me.cursorNm = nm;
	},
	getCursorAltitudeLimits: func {
		me.vectorToDist = [math.cos(me.upperAngle*D2R), 0, math.sin(me.upperAngle*D2R)];
		me.selfC = self.getCoord();
		me.geo = vector.Math.vectorToGeoVector(me.vectorToDist, me.selfC);
		me.geo = vector.Math.product(me.cursorNm*NM2M, vector.Math.normalize([me.geo.x,me.geo.y,me.geo.z]));
		me.up = geo.Coord.new();
		me.up.set_xyz(me.selfC.x()+me.geo[0],me.selfC.y()+me.geo[1],me.selfC.z()+me.geo[2]);
		me.vectorToDist = [math.cos(me.lowerAngle*D2R), 0, math.sin(me.lowerAngle*D2R)];
		me.geo = vector.Math.vectorToGeoVector(me.vectorToDist, me.selfC);
		me.geo = vector.Math.product(me.cursorNm*NM2M, vector.Math.normalize([me.geo.x,me.geo.y,me.geo.z]));
		me.down = geo.Coord.new();
		me.down.set_xyz(me.selfC.x()+me.geo[0],me.selfC.y()+me.geo[1],me.selfC.z()+me.geo[2]);
		return [me.up.alt()*M2FT, me.down.alt()*M2FT];
	},
	setRange: func (range) {
		me.testMulti = 160/range;
		if (int(me.testMulti) != me.testMulti) {#me.testMulti < 1 or me.testMulti > 32 or 
			return 0;
		}
		me.range = math.min(me.maxRange, range);
		me.range = math.max(me.minRange, range);
		return range == me.range;
	},
	_increaseRange: func {
		me.range*=2;
		if (me.range>me.maxRange) {
			me.range*=0.5;
			return 0;
		}
		return 1;
	},
	_decreaseRange: func {
		me.range *= 0.5;
		if (me.range < me.minRange) {
			me.range *= 2;
			return 0;
		}
		return 1;
	},
	setDeviation: func (dev_tilt_deg) {
		if (me.az == 60) {
			dev_tilt_deg = 0;
		}
		me.azimuthTilt = dev_tilt_deg;
		if (me.azimuthTilt > me.radar.fieldOfRegardMaxAz-me.az) {
			me.azimuthTilt = me.radar.fieldOfRegardMaxAz-me.az;
		} elsif (me.azimuthTilt < -me.radar.fieldOfRegardMaxAz+me.az) {
			me.azimuthTilt = -me.radar.fieldOfRegardMaxAz+me.az;
		}
	},
	getDeviation: func {
		return me.azimuthTilt;
	},
	getBars: func {
		return me.bars;
	},
	getAz: func {
		return me.az;
	},
	getPriority: func {
		return me["priorityTarget"];
	},
	step: func (dt, tilt) {
		me.radar.horizonStabilized = 1;
		me.preStep();
		
		# figure out if we reach the gimbal limit, and if so, keep all bars within it:
		me.min = me.barPatternMin[me.bars-1]*me.barHeight*me.radar.instantFoVradius+tilt;# This is the min/max we desire.
		me.max = me.barPatternMax[me.bars-1]*me.barHeight*me.radar.instantFoVradius+tilt;
 		me.actualMin = self.getPitch()-me.radar.fieldOfRegardMaxElev;
 		me.actualMax = self.getPitch()+me.radar.fieldOfRegardMaxElev;
 		if (me.min < me.actualMin) {
 			me.gimbalTiltOffset = me.actualMin-me.min;
 			#printf("offset %d  actualMin %d  desire %d  pitch %d  tilt %d",me.gimbalTiltOffset, me.actualMin,me.min,self.getPitch(),tilt);
 		} elsif (me.max > me.actualMax) {
 			me.gimbalTiltOffset = me.actualMax-me.max;
 			#printf("offset %d  actualMax %d  desire %d  pitch %d  tilt %d",me.gimbalTiltOffset, me.actualMax,me.max,self.getPitch(),tilt);
 		} else {
 			me.gimbalTiltOffset = 0;
 		}
 		me.azimuthTiltIntern = me.azimuthTilt;
		if (me.nextPatternNode == -1 and me.priorityTarget != nil) {
			me.lastDev = me.priorityTarget.getLastDirection();
			if (me.lastDev != nil) {
				me.azimuthTiltIntern = me.lastDev[2]-self.getHeading();
				me.radar.tiltOverride = 1;
				me.radar.tilt = me.lastDev[3];
				me.localDir = vector.Math.yawPitchVector(-me.azimuthTiltIntern, me.radar.tilt, [1,0,0]);
			} else {
				me.priorityTarget = nil;
				me.radar.tiltOverride = 0;
				me.undesignate();
				me.nextPatternNode == 0;
			}			
		} elsif (me.nextPatternNode == -1) {
			me.nextPatternNode == 0;
		} elsif (tilt != me.lastTilt or me.bars != me.lastBars or me.az != me.lastAz or me.azimuthTiltIntern != me.lastAzimuthTilt or me.gimbalTiltOffset != 0) {
			# (re)calculate pattern as vectors.
			me.currentPattern = [];
			foreach (me.eulerNorm ; me.barPattern[me.bars-1]) {
				me.localDir = vector.Math.yawPitchVector(-me.eulerNorm[0]*me.az-me.azimuthTiltIntern, me.eulerNorm[1]*me.radar.instantFoVradius*me.barHeight+tilt+me.gimbalTiltOffset, [1,0,0]);
				#print("Step sweep: ", -me.eulerNorm[0]*me.az-me.azimuthTilt);
				append(me.currentPattern, me.localDir);
			}
			me.upperAngle = me.max+me.gimbalTiltOffset;
			me.lowerAngle = me.min+me.gimbalTiltOffset;
			me.lastTilt = tilt;
			me.lastBars = me.bars;
			me.lastAz = me.az;
			me.lastAzimuthTilt = me.azimuthTiltIntern;
		}
		me.maxMove = math.min(me.radar.instantFoVradius*1.25, me.discSpeed_dps*dt);# 1.25 is because the FoV is round so we overlap em a bit
		me.currentPos = me.radar.positionDirection;
		me.angleToNextNode = vector.Math.angleBetweenVectors(me.currentPos, me.nextPatternNode == -1?me.localDir:me.currentPattern[me.nextPatternNode]);
		if (me.angleToNextNode < me.maxMove) {
			#print("resultpitch2 ",vector.Math.cartesianToEuler(me.currentPattern[me.nextPatternNode])[1]);
			me.radar.setAntennae(me.nextPatternNode == -1?me.localDir:me.currentPattern[me.nextPatternNode]);
			me.nextPatternNode += 1;
			if (me.nextPatternNode >= size(me.currentPattern)) {
				me.nextPatternNode = (me.scanPriorityEveryFrame and me.priorityTarget!=nil)?-1:0;
				me.frameCompleted();
			}
			return dt-me.angleToNextNode/me.discSpeed_dps;
		}
		me.newPos = vector.Math.rotateVectorTowardsVector(me.currentPos, me.nextPatternNode == -1?me.localDir:me.currentPattern[me.nextPatternNode], me.maxMove);
		me.radar.setAntennae(me.newPos);
		return dt-me.maxMove/me.discSpeed_dps;# The 0.001 is for presicion errors.
	},
	frameCompleted: func {
		#print("frame ",me.radar.elapsed-me.lastFrameStart);
		if (me.lastFrameStart != -1) {
			me.lastFrameDuration = me.radar.elapsed - me.lastFrameStart;
			me.timeToKeepBleps = me.radar.targetHistory*me.lastFrameDuration;
		}
		me.lastFrameStart = me.radar.elapsed;
	},
	leaveMode: func {
		# Warning: In this method do not set anything on me.radar only on me.
		me.lastFrameStart = -1;
		me.timeToKeepBleps = 13;
	},
	enterMode: func {
		# Warning: This gets called BEFORE previous mode's leaveMode()
	},
	getRange: func {
		return me.range;
	},
	designatePriority: func (contact) {},
	cycleDesignate: func {},
	testContact: func (contact) {},
	prunedContact: func (c) {
	},
};#                                    END Radar Mode class



#  ██████  ██     ██ ███████ 
#  ██   ██ ██     ██ ██      
#  ██████  ██  █  ██ ███████ 
#  ██   ██ ██ ███ ██      ██ 
#  ██   ██  ███ ███  ███████ 
#                            
#                            
var F16RWSMode = {
	radar: nil,
	shortName: "RWS",
	longName: "Range While Search",
	superMode: nil,
	subMode: nil,
	maxRange: 160,
	discSpeed_dps: 65,#authentic for RWS
	rcsFactor: 0.9,
	EXPsupport: 1,#if support zoom
	EXPsearch: 1,# if zoom should include search targets
	new: func (subMode, radar = nil) {
		var mode = {parents: [F16RWSMode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		subMode.superMode = mode;
		subMode.shortName = mode.shortName;
		return mode;
	},
	cycleAZ: func {
		if (me.az == 10) me.az = 30;
		elsif (me.az == 30) {me.az = 60; me.azimuthTilt = 0;}
		elsif (me.az == 60) me.az = 10;
	},
	cycleBars: func {
		me.bars += 1;
		if (me.bars == 3) me.bars = 4;# 3 is only for TWS
		elsif (me.bars == 5) me.bars = 1;
		me.nextPatternNode = 0;
	},
	designate: func (designate_contact) {
		if (designate_contact == nil) return;
		me.radar.setCurrentMode(me.subMode, designate_contact);
		me.subMode.radar = me.radar;# find some smarter way of setting it.
	},
	undesignate: func {},
	designatePriority: func (contact) {
		me.designate(contact);
	},
	preStep: func {
		me.radar.tiltOverride = 0;
		var dev_tilt_deg = me.cursorAz;
		if (me.az == 60) {
			dev_tilt_deg = 0;
		}
		me.azimuthTilt = dev_tilt_deg;
		if (me.azimuthTilt > me.radar.fieldOfRegardMaxAz-me.az) {
			me.azimuthTilt = me.radar.fieldOfRegardMaxAz-me.az;
		} elsif (me.azimuthTilt < -me.radar.fieldOfRegardMaxAz+me.az) {
			me.azimuthTilt = -me.radar.fieldOfRegardMaxAz+me.az;
		}
	},
	increaseRange: func {
		me._increaseRange();
	},
	decreaseRange: func {
		me._decreaseRange();
	},
	getSearchInfo: func (contact) {
		# searchInfo:               dist, groundtrack, deviations, speed, closing-rate, altitude
		return [1,0,1,0,0,1];
	},
};


#  ██      ██████  ███████ 
#  ██      ██   ██ ██      
#  ██      ██████  ███████ 
#  ██      ██   ██      ██ 
#  ███████ ██   ██ ███████ 
#                          
#                          
var F16LRSMode = {
	shortName: "LRS",
	longName: "Long Range Search",
	range: 160,
	discSpeed_dps: 45,
	rcsFactor: 1,
	new: func (subMode, radar = nil) {
		var mode = {parents: [F16LRSMode, F16RWSMode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		subMode.superMode = mode;
		subMode.shortName = mode.shortName;
		return mode;
	},
};


#  ███████ ███████  █████  
#  ██      ██      ██   ██ 
#  ███████ █████   ███████ 
#       ██ ██      ██   ██ 
#  ███████ ███████ ██   ██ 
#                          
#                          
var F16SeaMode = {
	rootName: "SEA",
	shortName: "MAN",
	longName: "Sea Navigation Mode",
	discSpeed_dps: 55,
	maxRange: 80,
	range: 20,
	bars: 4,
	rcsFactor: 1,
	detectAIR: 0,
	detectSURFACE: 0,
	detectMARINE: 1,
	new: func (subMode, radar = nil) {
		var mode = {parents: [F16SeaMode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		subMode.superMode = mode;
		subMode.shortName = mode.shortName;
		subMode.rootName = mode.rootName;
		return mode;
	},
	preStep: func {
		me.radar.tiltOverride = 1;
		me.radar.tilt = -10;# TODO: find info on this
		var dev_tilt_deg = me.cursorAz;
		if (me.az == 60) {
			dev_tilt_deg = 0;
		}
		me.azimuthTilt = dev_tilt_deg;
		if (me.azimuthTilt > me.radar.fieldOfRegardMaxAz-me.az) {
			me.azimuthTilt = me.radar.fieldOfRegardMaxAz-me.az;
		} elsif (me.azimuthTilt < -me.radar.fieldOfRegardMaxAz+me.az) {
			me.azimuthTilt = -me.radar.fieldOfRegardMaxAz+me.az;
		}
	},
	cycleAZ: func {
		if (me.az == 10) me.az = 30;
		elsif (me.az == 30) {me.az = 60; me.azimuthTilt = 0;}
		elsif (me.az == 60) me.az = 10;
	},
	cycleBars: func {
	},
	showBars: func {
		return 0;
	},
	increaseRange: func {
		me._increaseRange();
	},
	decreaseRange: func {
		me._decreaseRange();
	},
	getSearchInfo: func (contact) {
		# searchInfo:               dist, groundtrack, deviations, speed, closing-rate, altitude
		return [1,0,1,0,0,1];
	},
	designate: func (designate_contact) {
		if (designate_contact == nil) return;
		me.radar.setCurrentMode(me.subMode, designate_contact);
		me.subMode.radar = me.radar;# find some smarter way of setting it.
	},
	designatePriority: func (contact) {
	},
	enterMode: func {
		me.radar.purgeAllBleps();
	},
};


#   ██████  ███    ███ 
#  ██       ████  ████ 
#  ██   ███ ██ ████ ██ 
#  ██    ██ ██  ██  ██ 
#   ██████  ██      ██ 
#                      
#                      
var F16GMMode = {
	rootName: "GM",
	shortName: "MAN",
	longName: "Ground Map",
	detectAIR: 0,
	detectSURFACE: 1,
	detectMARINE: 0,
	new: func (subMode, radar = nil) {
		var mode = {parents: [F16GMMode, F16SeaMode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		subMode.superMode = mode;
		subMode.shortName = mode.shortName;
		subMode.rootName = mode.rootName;
		return mode;
	},
};


#   ██████  ███    ███ ████████ 
#  ██       ████  ████    ██    
#  ██   ███ ██ ████ ██    ██    
#  ██    ██ ██  ██  ██    ██    
#   ██████  ██      ██    ██    
#                               
#                               
var F16GMTMode = {
	rootName: "GMT",
	shortName: "MAN",
	longName: "Ground Moving Target",
	maxRange: 40,
	new: func (subMode, radar = nil) {
		var mode = {parents: [F16GMTMode, F16GMMode, F16SeaMode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		subMode.superMode = mode;
		subMode.shortName = mode.shortName;
		subMode.rootName = mode.rootName;
		return mode;
	},
	getSearchInfo: func (contact) {
		# searchInfo:               dist, groundtrack, deviations, speed, closing-rate, altitude
		me.devGMT = contact.getDeviationStored();
		if (me.devGMT[12] < 10) return nil;# A gain knob decide this. (should it be radial speed instead?)
		return [1,0,1,1,0,1];
	},
};


#  ██    ██ ███████ ██████  
#  ██    ██ ██      ██   ██ 
#  ██    ██ ███████ ██████  
#   ██  ██       ██ ██   ██ 
#    ████   ███████ ██   ██ 
#                           
#                           
var F16VSMode = {
	shortName: "VSR",
	longName: "Velocity Search",
	range: 160,
	discSpeed_dps: 45,
	discSpeed_alert_dps: 45,
	discSpeed_confirm_dps: 100,
	maxScanIntervalForVelocity: 12,
	rcsFactor: 1.15,
	new: func (subMode, radar = nil) {
		var mode = {parents: [F16VSMode, F16LRSMode, F16RWSMode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		subMode.superMode = mode;
		subMode.shortName = mode.shortName;
		return mode;
	},
	frameCompleted: func {
		if (me.lastFrameStart != -1 and me.discSpeed_dps == me.discSpeed_alert_dps) {
			# Its max around 11.5 secs for alert scan
			me.lastFrameDuration = me.radar.elapsed - me.lastFrameStart;
			me.timeToKeepBleps = me.radar.targetHistory*me.lastFrameDuration;
		}
		me.lastFrameStart = me.radar.elapsed;
		if (me.discSpeed_dps == me.discSpeed_alert_dps) {
			me.discSpeed_dps = me.discSpeed_confirm_dps;
		} elsif (me.discSpeed_dps == me.discSpeed_confirm_dps) {
			me.discSpeed_dps = me.discSpeed_alert_dps;
		}
	},
	designate: func (designate_contact) {
		if (designate_contact == nil) return;
		me.radar.setCurrentMode(me.subMode, designate_contact);
		me.subMode.radar = me.radar;# find some smarter way of setting it.
		me.radar.registerBlep(designate_contact, designate_contact.getDeviationStored());
	},
	designatePriority: func {
		# NOP
	},
	undesignate: func {
		# NOP
	},
	preStep: func {
		me.radar.tiltOverride = 0;
		var dev_tilt_deg = me.cursorAz;
		if (me.az == 60) {
			dev_tilt_deg = 0;
		}
		me.azimuthTilt = dev_tilt_deg;
		if (me.azimuthTilt > me.radar.fieldOfRegardMaxAz-me.az) {
			me.azimuthTilt = me.radar.fieldOfRegardMaxAz-me.az;
		} elsif (me.azimuthTilt < -me.radar.fieldOfRegardMaxAz+me.az) {
			me.azimuthTilt = -me.radar.fieldOfRegardMaxAz+me.az;
		}
	},
	increaseRange: func {
		me._increaseRange();
	},
	decreaseRange: func {
		me._decreaseRange();
	},
	getSearchInfo: func (contact) {
		# searchInfo:               dist, groundtrack, deviations, speed, closing-rate, altitude
		#print(me.currentTracked,"   ",(me.radar.elapsed - contact.blepTime));
		if (((me.radar.elapsed - contact.getLastBlepTime()) < me.maxScanIntervalForVelocity) and contact.getLastClosureRate() > 0) {
			#print("VELOCITY");
			return [0,0,1,1,1,0];
		}
		#print("  EMPTY");
		return [0,0,0,0,1,0];
	},
	getCursorAltitudeLimits: func {
		return nil;
	},
};







#  ████████ ██     ██ ███████ 
#     ██    ██     ██ ██      
#     ██    ██  █  ██ ███████ 
#     ██    ██ ███ ██      ██ 
#     ██     ███ ███  ███████ 
#                             
#                             
var F16TWSMode = {
	radar: nil,
	shortName: "TWS",
	longName: "Track While Scan",
	superMode: nil,
	subMode: nil,
	maxRange: 80,
	discSpeed_dps: 50, # source: https://www.youtube.com/watch?v=Aq5HXTGUHGI
	rcsFactor: 0.9,
	timeToKeepBleps: 13,# TODO
	maxScanIntervalForTrack: 6.5,# authentic for TWS
	priorityTarget: nil,
	currentTracked: [],
	maxTracked: 10,
	az: 25,# slow scan, so default is 25 to get those double taps in there.
	bars: 3,# default is less due to need 2 scans of target to get groundtrack
	EXPsupport: 1,#if support zoom
	EXPsearch: 0,# if zoom should include search targets
	new: func (subMode, radar = nil) {
		var mode = {parents: [F16TWSMode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		subMode.superMode = mode;
		subMode.shortName = mode.shortName;
		return mode;
	},
	cycleAZ: func {
		if (me.az == 10) {
			me.az = 25;
		} elsif (me.az == 25 and me.priorityTarget == nil) {
			me.az = 60;
			me.azimuthTilt = 0;
		} elsif (me.az == 25) {
			me.az = 10;
		} elsif (me.az == 60) {
			me.az = 10;
		}
	},
	cycleBars: func {
		me.bars += 1;
		if (me.bars == 5) me.bars = 2;# bars:1 not available in TWS
		me.nextPatternNode = 0;
	},
	designate: func (designate_contact) {
		if (designate_contact != nil) {
			me.radar.setCurrentMode(me.subMode, designate_contact);
			me.subMode.radar = me.radar;# find some smarter way of setting it.
		} else {
			me.priorityTarget = nil;
		}
	},
	designatePriority: func (contact) {
		me.priorityTarget = contact;
		if (contact != nil and me.az == 60) {
			# With a target of interest (TOI), AZ is not allowed to be 60
			me.az = 25;
		}
	},
	getPriority: func {
		return me.priorityTarget;
	},
	undesignate: func {
		me.priorityTarget = nil;
	},
	preStep: func {
	 	me.azimuthTilt = me.cursorAz;
		if (me.priorityTarget != nil) {
			me.prioRange_nm = me.priorityTarget.getLastRangeDirect()*M2NM;#TODO: nil exception here
			if (me.radar.elapsed - me.priorityTarget.getLastBlepTime() > me.timeToKeepBleps) {
				me.priorityTarget = nil;
				me.radar.tiltOverride = 0;
				me.undesignate();
				return;
			}
			me.lastDev = me.priorityTarget.getLastDirection();
			if (me.lastDev != nil) {
				me.centerTilt = me.lastDev[2]-self.getHeading();
				if (me.centerTilt > me.azimuthTilt+me.az) {
					me.azimuthTilt = me.centerTilt-me.az;
				} elsif (me.centerTilt < me.azimuthTilt-me.az) {
					me.azimuthTilt = me.centerTilt+me.az;
				}
				me.radar.tiltOverride = 1;
				me.radar.tilt = me.lastDev[3];
			} else {
				
				me.priorityTarget = nil;
				me.radar.tiltOverride = 0;
				me.undesignate();
				return;
			}
			if (me.prioRange_nm < 0.40 * me.getRange()) {
				me._decreaseRange();
			} elsif (me.prioRange_nm > 0.90 * me.getRange()) {
				me._increaseRange();
			} elsif (me.prioRange_nm < 3) {
				# auto go to STT when target is very close
				me.designate(me.priorityTarget);
			}
		} else {
			me.radar.tiltOverride = 0;
			me.undesignate();
		}
		if (me.az == 60) {
			me.azimuthTilt = 0;
		} elsif (me.azimuthTilt > me.radar.fieldOfRegardMaxAz-me.az) {
			me.azimuthTilt = me.radar.fieldOfRegardMaxAz-me.az;
		} elsif (me.azimuthTilt < -me.radar.fieldOfRegardMaxAz+me.az) {
			me.azimuthTilt = -me.radar.fieldOfRegardMaxAz+me.az;
		}
	},
	frameCompleted: func {
		if (me.lastFrameStart != -1) {
			me.lastFrameDuration = me.radar.elapsed - me.lastFrameStart;
		}
		me.lastFrameStart = me.radar.elapsed;
	},
	enterMode: func {
		me.currentTracked = [];
		foreach(c;me.radar.vector_aicontacts_bleps) {
			c.ignoreTrackInfo();# Kind of a hack to make it give out false info. Bypasses hadTrackInfo() but not hasTrackInfo().
		}
	},
	leaveMode: func {
		me.priorityTarget = nil;
		me.lastFrameStart = -1;
		me.timeToKeepBleps=13;
	},
	increaseRange: func {
		if (me.priorityTarget != nil) return 0;
		me._increaseRange();
	},
	decreaseRange: func {
		if (me.priorityTarget != nil) return 0;
		me._decreaseRange();
	},
	showRangeOptions: func {
		if (me.priorityTarget != nil) return 0;
		return 1;
	},
	getSearchInfo: func (contact) {
		# searchInfo:               dist, groundtrack, deviations, speed, closing-rate, altitude
		#print(me.currentTracked,"   ",(me.radar.elapsed - contact.blepTime));
		if (size(me.currentTracked) < me.maxTracked and ((me.radar.elapsed - contact.getLastBlepTime()) < me.maxScanIntervalForTrack)) {
			#print("  TWICE    ",me.radar.elapsed);
			#print(me.radar.containsVectorContact(me.radar.vector_aicontacts_bleps, contact),"   ",me.radar.elapsed - contact.blepTime);			
			if (!me.radar.containsVectorContact(me.currentTracked, contact)) append(me.currentTracked, contact);
			return [1,1,1,1,1,1];
		} elsif (me.radar.containsVectorContact(me.currentTracked, contact)) {
			me.tmp = [];
			foreach (me.cc ; me.currentTracked) {
				if(!me.cc.equals(contact)) {
					append(me.tmp, me.cc);
				}
			}
			me.currentTracked = me.tmp;
		}
		#print("  ONCE    ",me.currentTracked);
		return [1,0,1,0,0,1];
	},
	prunedContact: func (c) {
		if (c.equals(me.priorityTarget)) {
			me.priorityTarget = nil;# this might have fixed the nil exception
		}
		if (c.hadTrackInfo()) {
			me.del = me.radar.containsVectorContact(me.currentTracked, c);
			if (me.del) {
				me.tmp = [];
				foreach (me.cc ; me.currentTracked) {
					if(!me.cc.equals(c)) {
						append(me.tmp, me.cc);
					}
				}
				me.currentTracked = me.tmp;
			}
		}
	},
	testContact: func (contact) {
		#if (me.radar.elapsed - contact.getLastBlepTime() > me.maxScanIntervalForTrack and contact.azi == 1) {
		#	contact.azi = 0;
		#	me.currentTracked -= 1;
		#}
	},
	cycleDesignate: func {
		if (!size(me.radar.vector_aicontacts_bleps)) {
			me.priorityTarget = nil;
			return;
		}
		if (me.priorityTarget == nil) {
			me.testIndex = -1;
		} else {
			me.testIndex = me.radar.vectorIndex(me.radar.vector_aicontacts_bleps, me.priorityTarget);
		}
		for(me.i = me.testIndex+1;me.i<size(me.radar.vector_aicontacts_bleps);me.i+=1) {
			#if (me.radar.vector_aicontacts_bleps[me.i].hadTrackInfo()) {
				me.priorityTarget = me.radar.vector_aicontacts_bleps[me.i];
				return;
			#}
		}
		for(me.i = 0;me.i<=me.testIndex;me.i+=1) {
			#if (me.radar.vector_aicontacts_bleps[me.i].hadTrackInfo()) {
				me.priorityTarget = me.radar.vector_aicontacts_bleps[me.i];
				return;
			#}
		}
	},
};




#  ██████  ██     ██ ███████       ███████  █████  ███    ███ 
#  ██   ██ ██     ██ ██            ██      ██   ██ ████  ████ 
#  ██████  ██  █  ██ ███████ █████ ███████ ███████ ██ ████ ██ 
#  ██   ██ ██ ███ ██      ██            ██ ██   ██ ██  ██  ██ 
#  ██   ██  ███ ███  ███████       ███████ ██   ██ ██      ██ 
#                                                             
#                                                             
var F16RWSSAMMode = {
	radar: nil,
	shortName: "RWS",
	longName: "Range While Search - Situational Awareness Mode",
	superMode: nil,
	discSpeed_dps: 65,
	rcsFactor: 0.9,
	maxRange: 160,
	priorityTarget: nil,
	bars: 2,
	new: func (subMode = nil, radar = nil) {
		var mode = {parents: [F16RWSSAMMode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		if (subMode != nil) {
			subMode.superMode = mode;
			subMode.radar = radar;
			subMode.shortName = mode.shortName;
		}
		return mode;
	},
	calcSAMwidth: func {
		if (me.prioRange_nm<30) return math.min(60,18 + 2.066667*me.prioRange_nm - 0.02222222*me.prioRange_nm*me.prioRange_nm);
		else return 60;
	},
	preStep: func {
		me.azimuthTilt = me.cursorAz;
		if (me.priorityTarget != nil) {
			# azimuth width is autocalculated in F16 AUTO-SAM:
			me.prioRange_nm = me.priorityTarget.getRangeDirect()*M2NM;
			me.az = me.calcSAMwidth();
			if (!me.radar.containsVectorContact(me.radar.vector_aicontacts_bleps, me.priorityTarget)) {
				me.priorityTarget = nil;
				me.radar.tiltOverride = 0;
				me.undesignate();
				return;
			}
			me.lastDev = me.priorityTarget.getLastDirection();
			if (me.lastDev != nil) {
				if (math.abs(me.azimuthTilt - (me.lastDev[2]-self.getHeading())) > me.az) {
					me.scanPriorityEveryFrame = 1;
				} else {
					me.scanPriorityEveryFrame = 0;
				}
				me.radar.tiltOverride = 1;
				me.radar.tilt = me.lastDev[3];
			} else {
				
				me.priorityTarget = nil;
				me.radar.tiltOverride = 0;
				me.undesignate();
				return;
			}
			if (me.prioRange_nm < 0.40 * me.getRange()) {
				me._decreaseRange();
			} elsif (me.prioRange_nm > 0.90 * me.getRange()) {
				me._increaseRange();
			} elsif (me.prioRange_nm < 3) {
				# auto go to STT when target is very close
				me.designate(me.priorityTarget);
			}
		} else {
			me.radar.tiltOverride = 0;
			me.scanPriorityEveryFrame = 0;
			me.undesignate();
		}
		if (me.az == 60) {
			me.azimuthTilt = 0;
		} elsif (me.azimuthTilt > me.radar.fieldOfRegardMaxAz-me.az) {
			me.azimuthTilt = me.radar.fieldOfRegardMaxAz-me.az;
		} elsif (me.azimuthTilt < -me.radar.fieldOfRegardMaxAz+me.az) {
			me.azimuthTilt = -me.radar.fieldOfRegardMaxAz+me.az;
		}
	},
	undesignate: func {
		me.priorityTarget = nil;
		me.radar.setCurrentMode(me.superMode, nil);
	},
	designate: func (designate_contact) {
		if (designate_contact == nil) return;
		if (designate_contact.equals(me.priorityTarget)) {
			me.radar.setCurrentMode(me.subMode, designate_contact);
			me.subMode.radar = me.radar;# find some smarter way of setting it.
		} else {
			me.priorityTarget = designate_contact;
		}
	},
	designatePriority: func (contact) {
		me.priorityTarget = contact;
	},
	cycleBars: func {
		me.bars += 1;
		if (me.bars == 3) me.bars = 4;# 3 is only for TWS
		elsif (me.bars == 5) me.bars = 1;
		me.nextPatternNode = 0;
	},
	cycleAZ: func {},
	increaseRange: func {# Range is auto-set in RWS-SAM
		return 0;
	},
	decreaseRange: func {# Range is auto-set in RWS-SAM
		return 0;
	},
	setRange: func {# Range is auto-set in RWS-SAM
	},
	leaveMode: func {
		me.priorityTarget = nil;
		me.lastFrameStart = -1;
		me.timeToKeepBleps = 13;
	},
	getSearchInfo: func (contact) {
		# searchInfo:               dist, groundtrack, deviations, speed, closing-rate, altitude
		if (me.priorityTarget != nil and contact.equals(me.priorityTarget)) {
			return [1,1,1,1,1,1];
		}
		return [1,0,1,0,0,1];
	},
	showRangeOptions: func {
		return 0;
	},
};


#  ██      ██████  ███████       ███████  █████  ███    ███ 
#  ██      ██   ██ ██            ██      ██   ██ ████  ████ 
#  ██      ██████  ███████ █████ ███████ ███████ ██ ████ ██ 
#  ██      ██   ██      ██            ██ ██   ██ ██  ██  ██ 
#  ███████ ██   ██ ███████       ███████ ██   ██ ██      ██ 
#                                                           
#                                                           
var F16LRSSAMMode = {
	shortName: "LRS",
	longName: "Long Range Search - Situational Awareness Mode",
	discSpeed_dps: 45,
	rcsFactor: 1,
	new: func (subMode = nil, radar = nil) {
		var mode = {parents: [F16LRSSAMMode, F16RWSSAMMode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		if (subMode != nil) {
			subMode.superMode = mode;
			subMode.radar = radar;
			subMode.shortName = mode.shortName;
		}
		return mode;
	},
	calcSAMwidth: func {
		if (me.prioRange_nm<42) return math.min(60,18 + 1.4*me.prioRange_nm - 0.01*me.prioRange_nm*me.prioRange_nm);
		else return 60;
	},
};



#   █████   ██████ ███    ███ 
#  ██   ██ ██      ████  ████ 
#  ███████ ██      ██ ████ ██ 
#  ██   ██ ██      ██  ██  ██ 
#  ██   ██  ██████ ██      ██ 
#                             
#                             
var F16ACMMode = {#TODO
	radar: nil,
	rootName: "ACM",
	shortName: "STBY",
	longName: "Air Combat Mode Standby",
	superMode: nil,
	subMode: nil,
	range: 10,
	maxRange: 10,
	discSpeed_dps: 84.6,
	rcsFactor: 0.9,
	timeToKeepBleps: 1,
	bars: 1,
	az: 1,
	new: func (subMode, radar = nil) {
		var mode = {parents: [F16ACMMode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		mode.subMode.superMode = mode;
		mode.subMode.shortName = mode.shortName;
		return mode;
	},
	showBars: func {
		return 0;
	},
	setDeviation: func (dev_tilt_deg) {
	},
	cycleAZ: func {	},
	cycleBars: func { },
	designate: func (designate_contact) {
	},
	designatePriority: func (contact) {

	},
	getPriority: func {
		return nil;
	},
	undesignate: func {
	},
	preStep: func {
	},
	increaseRange: func {
		return 0;
	},
	decreaseRange: func {
		return 0;
	},
	getSearchInfo: func (contact) {
		# searchInfo:               dist, groundtrack, deviations, speed, closing-rate, altitude
		return nil;
	},
	testContact: func (contact) {
	},
	cycleDesignate: func {
	},
};

var F16ACM20Mode = {
	radar: nil,
	rootName: "ACM",
	shortName: "20",
	longName: "Air Combat Mode 30x20",
	superMode: nil,
	subMode: nil,
	range: 10,
	maxRange: 10,
	discSpeed_dps: 84.6,
	rcsFactor: 0.9,
	timeToKeepBleps: 1,# TODO
	bars: 4,
	az: 15,
	new: func (subMode, radar = nil) {
		var mode = {parents: [F16ACM20Mode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		mode.subMode.superMode = mode;
		mode.subMode.shortName = mode.shortName;
		return mode;
	},
	showBars: func {
		return 0;
	},
	setDeviation: func (dev_tilt_deg) {
	},
	cycleAZ: func {	},
	cycleBars: func { },
	designate: func (designate_contact) {
		if (designate_contact == nil) return;
		me.radar.setCurrentMode(me.subMode, designate_contact);
		me.subMode.radar = me.radar;
	},
	designatePriority: func (contact) {
	},
	getPriority: func {
		return nil;
	},
	undesignate: func {
	},
	preStep: func {
		me.radar.horizonStabilized = 0;
		me.radar.tilt = -3;
		me.radar.tiltOverride = 1;
	},
	increaseRange: func {
		return 0;
	},
	decreaseRange: func {
		return 0;
	},
	getSearchInfo: func (contact) {
		# searchInfo:               dist, groundtrack, deviations, speed, closing-rate, altitude
		me.designate(contact);
		return [1,1,1,1,1,1];
	},
	testContact: func (contact) {
	},
	cycleDesignate: func {
	},
};

var F16ACM60Mode = {
	radar: nil,
	rootName: "ACM",
	shortName: "60",
	longName: "Air Combat Mode 10x60",
	superMode: nil,
	subMode: nil,
	maxRange: 10,
	discSpeed_dps: 84.6,
	rcsFactor: 0.9,
	bars: 1,
	barHeight: 1.0/APG68.instantFoVradius,# multiple of instantFoV (in this case 1 deg)
	az: 5,
	barPattern:  [ [[-0.6,-5],[0.0,-5],[0.0, 51],[0.6,51],[0.6,-5],[0.0,-5],[0.0,51],[-0.6,51]], ],
	new: func (subMode, radar = nil) {
		var mode = {parents: [F16ACM60Mode, F16ACM20Mode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		mode.subMode.superMode = mode;
		mode.subMode.shortName = mode.shortName;
		return mode;
	},
	preStep: func {
		me.radar.horizonStabilized = 0;
		me.radar.tilt = 0;
		me.radar.tiltOverride = 1;
	},
};

var F16ACMBoreMode = {
	radar: nil,
	rootName: "ACM",
	shortName: "BORE",
	longName: "Air Combat Mode Bore",
	bars: 1,
	barHeight: 1.0,# multiple of instantFoV (in this case 1 deg)
	az: 0,
	barPattern:  [ [[0.0,-1]], ],
	new: func (subMode, radar = nil) {
		var mode = {parents: [F16ACMBoreMode, F16ACM20Mode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		mode.subMode.superMode = mode;
		mode.subMode.shortName = mode.shortName;
		return mode;
	},
	preStep: func {
		me.radar.horizonStabilized = 0;
		me.radar.tilt = 0;
		me.radar.tiltOverride = 1;
	},
	step: func (dt, tilt) {
		me.preStep();
		# (re)calculate pattern as vectors.
		me.localDir = vector.Math.yawPitchVector(0, -me.radar.instantFoVradius, [1,0,0]);
		me.maxMove = math.min(me.radar.instantFoVradius, me.discSpeed_dps*dt);
		me.currentPos = me.radar.positionDirection;
		me.angleToNextNode = vector.Math.angleBetweenVectors(me.currentPos, me.localDir);
		if (me.angleToNextNode < me.maxMove) {
			me.radar.setAntennae(me.localDir);
			me.lastFrameDuration = 0;
			return 0;
		}
		me.newPos = vector.Math.rotateVectorTowardsVector(me.currentPos, me.localDir, me.maxMove);
		me.radar.setAntennae(me.newPos);
		return 0;
	},
};




#  ███████ ████████ ████████ 
#  ██         ██       ██    
#  ███████    ██       ██    
#       ██    ██       ██    
#  ███████    ██       ██    
#                            
#                            
var F16STTMode = {
	radar: nil,
	shortName: "STT",
	longName: "Single Target Track",
	superMode: nil,
	discSpeed_dps: 80,
	rcsFactor: 1,
	maxRange: 160,
	priorityTarget: nil,
	az: APG68.instantFoVradius,
	bars: 2,
	minimumTimePerReturn: 0.20,
	timeToKeepBleps: 7,
	painter: 1,
	new: func (radar = nil) {
		var mode = {parents: [F16STTMode, RadarMode]};
		mode.radar = radar;
		return mode;
	},
	showAZ: func {
		return 0;
	},
	showBars: func {
		return me.superMode.showBars();
	},
	showRangeOptions: func {
		return 0;
	},
	getBars: func {
		return me.superMode.getBars();
	},
	getAz: func {
		return me.superMode.getAz();
	},
	preStep: func {
		if (me.priorityTarget != nil) {
			me.lastDev = me.priorityTarget.getLastDirection();
			if (me.lastDev != nil) {
				me.azimuthTilt = me.lastDev[2]-self.getHeading();
				me.radar.tiltOverride = 1;
				me.radar.tilt = me.lastDev[3];
			} else {				
				me.priorityTarget = nil;
				me.radar.tiltOverride = 0;
				me.undesignate();
				return;
			}
			if (!me.radar.containsVectorContact(me.radar.vector_aicontacts_bleps, me.priorityTarget)) {
				me.priorityTarget = nil;
				me.radar.tiltOverride = 0;
				me.undesignate();
				return;
			} elsif (me.azimuthTilt > me.radar.fieldOfRegardMaxAz-me.az) {
				me.azimuthTilt = me.radar.fieldOfRegardMaxAz-me.az;
			} elsif (me.azimuthTilt < -me.radar.fieldOfRegardMaxAz+me.az) {
				me.azimuthTilt = -me.radar.fieldOfRegardMaxAz+me.az;
			}
			if (me.priorityTarget.getRangeDirect()*M2NM < 0.40 * me.getRange()) {
				me._decreaseRange();
			}
			if (me.priorityTarget.getRangeDirect()*M2NM > 0.90 * me.getRange()) {
				me._increaseRange();
			}
		} else {
			me.radar.tiltOverride = 0;
			me.undesignate();
		}
	},
	designatePriority: func (prio) {
		me.priorityTarget = prio;
	},
	undesignate: func {
		me.radar.setCurrentMode(me.superMode, me.priorityTarget);
		me.priorityTarget = nil;
		#var log = caller(1); foreach (l;log) print(l);
	},
	designate: func {},
	cycleBars: func {},
	cycleAZ: func {},
	increaseRange: func {# Range is auto-set in STT
		return 0;
	},
	decreaseRange: func {# Range is auto-set in STT
		return 0;
	},
	setRange: func {# Range is auto-set in STT
	},
	frameCompleted: func {
		if (me.lastFrameStart != -1) {
			me.lastFrameDuration = me.radar.elapsed - me.lastFrameStart;
		}
		me.lastFrameStart = me.radar.elapsed;
	},
	leaveMode: func {
		me.priorityTarget = nil;
		me.lastFrameStart = -1;
		me.timeToKeepBleps = 13;
	},
	getSearchInfo: func (contact) {
		# searchInfo:               dist, groundtrack, deviations, speed, closing-rate, altitude
		if (me.priorityTarget != nil and contact.equals(me.priorityTarget)) {
			return [1,1,1,1,1,1];
		}
		return nil;
	},
	getCursorAltitudeLimits: func {
		return nil;
	},
};

var F16ACMSTTMode = {
	rootName: "ACM",
	shortName: "STT",
	longName: "Air Combat Mode - Single Target Track",
	new: func (radar = nil) {
		var mode = {parents: [F16ACMSTTMode, F16STTMode, RadarMode]};
		mode.radar = radar;
		return mode;
	},
};

var F16MultiSTTMode = {
	rootName: "CRM",
	shortName: "STT",
	longName: "Multisearch - Single Target Track",
	new: func (radar = nil) {
		var mode = {parents: [F16MultiSTTMode, F16STTMode, RadarMode]};
		mode.radar = radar;
		return mode;
	},
	undesignate: func {
		if (me.priorityTarget != nil and me.priorityTarget.getRangeDirect()*M2NM < 3) {
			me.priorityTarget = nil;
		}
		me.radar.setCurrentMode(me.superMode, me.priorityTarget);
		me.priorityTarget = nil;
		#var log = caller(1); foreach (l;log) print(l);
	},
};


#  ███████ ████████ ████████ 
#  ██         ██       ██    
#  █████      ██       ██    
#  ██         ██       ██    
#  ██         ██       ██    
#                            
#                            
var F16FTTMode = {
	rootName: "",
	shortName: "FTT",
	longName: "Fixed Target Track",
	maxRange: 80,
	detectAIR: 0,
	detectSURFACE: 0,
	detectMARINE: 1,
	new: func (radar = nil) {
		var mode = {parents: [F16FTTMode, F16STTMode, RadarMode]};
		mode.radar = radar;
		return mode;
	},
};

var F16GMFTTMode = {
	new: func (radar = nil) {
		var mode = {parents: [F16GMFTTMode, F16FTTMode, F16STTMode, RadarMode]};
		mode.radar = radar;
		return mode;
	},
	getPriority: func {
		if (me.priorityTarget == nil or (rand() > 0.95 and me.priorityTarget.getSpeed() < 11)) {
			return me.priorityTarget;
		} else {
			return me.priorityTarget.getNearbyVirtualContact(60);
		}
	},
};

var F16GMTFTTMode = {
	new: func (radar = nil) {
		var mode = {parents: [F16GMTFTTMode, F16FTTMode, F16STTMode, RadarMode]};
		mode.radar = radar;
		return mode;
	},
};


















var scanInterval = 0.05;# 20hz for main radar


laserOn = props.globals.getNode("controls/armament/laser-arm-dmd",1);#don't put 'var' keyword in front of this.
var datalink_power = props.globals.getNode("instrumentation/datalink/power",0);
enable_tacobject = 1;
var antennae_knob_prop = props.globals.getNode("controls/radar/antennae-knob",0);


# start generic radar system
var baser = AIToNasal.new();
var partitioner = NoseRadar.new();
var omni = OmniRadar.new(1.0, 150, 55);
var terrain = TerrainChecker.new(0.10, 1, 60);# 0.05 or 0.10 is fine here
var dlnkRadar = DatalinkRadar.new(0.03, 90);# 3 seconds because cannot be too slow for DLINK targets

# start specific radar system
var rwsMode = F16RWSMode.new(F16RWSSAMMode.new(F16MultiSTTMode.new()));
var twsMode = F16TWSMode.new(F16MultiSTTMode.new());
var lrsMode = F16LRSMode.new(F16LRSSAMMode.new(F16MultiSTTMode.new()));
var vsrMode = F16VSMode.new(F16STTMode.new()); 
var acm20Mode = F16ACM20Mode.new(F16ACMSTTMode.new());
var acm60Mode = F16ACM60Mode.new(F16ACMSTTMode.new());
var acmBoreMode = F16ACMBoreMode.new(F16ACMSTTMode.new());
var seaMode = F16SeaMode.new(F16FTTMode.new()); 
var gmMode = F16GMMode.new(F16GMFTTMode.new());
var gmtMode = F16GMTMode.new(F16GMTFTTMode.new());
var apg68Radar = APG68.new([[rwsMode,twsMode,lrsMode,vsrMode],[acm20Mode,acm60Mode,acmBoreMode],[seaMode],[gmMode],[gmtMode]]);
var f16_rwr = RWR.new();




var getCompleteList = func {
	return partitioner.vector_aicontacts;# Important not to use parser data here, as that one gets rebuilt from time to time. Hence we use partitioner instead.
}





# BUGS:
#   HSD radar arc CW vs. CCW
#
# TODO:
#   GM tilt angles (needs serious thinking)
#   Clicking A-G should set GM
#   VSR switch speed at each bar instead of each frame
#
