var FrameNotification = 
{
    new: func(_rate)
    {
        var new_class = emesary.Notification.new("FrameNotification", _rate);
        new_class.Rate = _rate;
        new_class.FrameRate = 60;
        new_class.FrameCount = 0;
        new_class.ElapsedSeconds = 0;
        return new_class;
    }
    ,
        };
#    
var frameNotification = FrameNotification.new(1);
#    
var rtExec_loop = func
{
    var frame_rate = getprop("/sim/frame-rate");
    var elapsed_seconds = getprop("/sim/time/elapsed-sec");
    #
    # you can put commonly accessed properties inside the message to improve performance.
    #
    frameNotification.FrameRate = frame_rate;
    frameNotification.ElapsedSeconds = elapsed_seconds;
    #         frameNotification.CurrentIAS = getprop("velocities/airspeed-kt");
    #         frameNotification.CurrentMach = getprop("velocities/mach");
    #         frameNotification.CurrentAlt = getprop("position/altitude-ft");
    frameNotification.wow = getprop("gear/gear[1]/wow") or getprop("gear/gear[2]/wow");
    #         frameNotification.Alpha = getprop("orientation/alpha-indicated-deg");
    #         frameNotification.Throttle = getprop("controls/engines/engine/throttle");
    #         frameNotification.e_trim = getprop("controls/flight/elevator-trim");
    #         frameNotification.deltaT = getprop ("sim/time/delta-sec");
    #         frameNotification.current_aileron = getprop("surface-positions/left-aileron-pos-norm");
    #         frameNotification.currentG = getprop ("accelerations/pilot-gdamped");
    frameNotification.engine_n2 = getprop("engines/engine[0]/n2");
    frameNotification.brake_parking = getprop("controls/gear/brake-parking");
    frameNotification.gear_down = getprop("controls/gear/gear-down");

    frameNotification.view_internal = getprop("sim/current-view/internal");
    frameNotification.mach = getprop("instrumentation/airspeed-indicator/indicated-mach");
    frameNotification.IAS = getprop("velocities/airspeed-kt");
    frameNotification.Nz = -getprop("accelerations/pilot/z-accel-fps_sec")/getprop("fdm/jsbsim/accelerations/gravity-ft_sec2");
    frameNotification.WOW = getprop ("gear/gear[1]/wow") or getprop ("gear/gear[2]/wow");
#    frameNotification.alpha = getprop("orientation/alpha-indicated-deg");
    frameNotification.alpha = getprop("fdm/jsbsim/aero/alpha-deg");
    frameNotification.flap_pos_deg = getprop("/fdm/jsbsim/fcs/flap-pos-deg");
    frameNotification.beta = getprop("orientation/side-slip-deg");
    frameNotification.altitude_ft =  getprop ("position/altitude-ft");
    frameNotification.heading =  getprop("orientation/heading-deg");
    frameNotification.mach = getprop ("velocities/mach");
    frameNotification.measured_altitude = getprop("instrumentation/altimeter/indicated-altitude-ft");
    frameNotification.pitch =  getprop ("orientation/pitch-deg");
    frameNotification.roll =  getprop ("orientation/roll-deg");
#    frameNotification.yaw =  getprop ("instrumentation/slip-skid-ball/indicated-slip-skid");
    frameNotification.yaw =  getprop ("fdm/jsbsim/aero/beta-deg");
    frameNotification.baro =  getprop ("instrumentation/altimeter/setting-hpa");
    frameNotification.speed = getprop("fdm/jsbsim/velocities/vt-fps");
    frameNotification.v = getprop("fdm/jsbsim/velocities/v-fps");
    frameNotification.w = getprop("fdm/jsbsim/velocities/w-fps");
    frameNotification.range_rate = "0";
    frameNotification.target_display = getprop("sim/model/f16/instrumentation/radar-awg-9/hud/target-display");
    frameNotification.radar_range = getprop("instrumentation/radar/radar2-range");
    frameNotification.vc_kts = getprop("fdm/jsbsim/velocities/vc-kts");
    frameNotification.weapon_mode = getprop("sim/model/f16/controls/armament/weapon-selector");
    frameNotification.groundspeed_kt = getprop("velocities/groundspeed-kt");
    frameNotification.gmt_string = getprop("sim/time/gmt-string");
    frameNotification.gmt = getprop("sim/time/gmt");
    frameNotification.gun_rounds = getprop("sim/model/f16/systems/gun/rounds");
    frameNotification.symbol_reject = getprop("controls/HUD/sym-rej");

    if (getprop("autopilot/route-manager/active")) {
        var rng = getprop("autopilot/route-manager/wp/dist");
        var eta_s = getprop("autopilot/route-manager/wp/eta-seconds");
        if (rng != nil) {
            frameNotification.hud_window5 = sprintf("%2d MIN",rng);
            frameNotification.nav_range = sprintf("N %4.1f", rng);
        } else {
            frameNotification.hud_window5 = "XXX";
            frameNotification.nav_range = "N XXX";
        }

        if (eta_s != nil)
          frameNotification.hud_window5 = sprintf("%2d MIN",eta_s/60);
        else
          frameNotification.hud_window5 = "XX MIN";
    } else {
        frameNotification.nav_range = "";
        frameNotification.hud_window5 = "";
    }


    frameNotification.roll_rad = 0.0;

    frameNotification.VV_x = frameNotification.beta*10; # adjust for view
    frameNotification.VV_y = frameNotification.alpha*10; # adjust for view

    #    
    if (frameNotification.FrameCount >= 4) {
        frameNotification.FrameCount = 0;
    }
    emesary.GlobalTransmitter.NotifyAll(frameNotification);
    #    
    frameNotification.FrameCount = frameNotification.FrameCount + 1;
    #    
    execTimer.restart(0);
}

var execTimer = maketimer(1, rtExec_loop);
execTimer.start();
