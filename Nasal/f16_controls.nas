################################################################################
#
#                        f16's CONTROLS SETTINGS
#
################################################################################
# The goal is to overwrite some controls in order of put it on a stick (and
# even perhaps multiplex command on stick...)

# Brakes
# Allow, on flight to put in the same button, the brakes and airbrakes, using
# defaults function, and put it on the joystick, and be able to accelerate and
# decelerate without put hand of the stick and search the keyboard.

# AirBrake handling.
var applyAirBrakes = func(v)
{
    setprop("/controls/flight/speedbrake", v);
}

# Brake handling.
var fullBrakeTime = 0.5;
var applyBrakes = func(v, which = 0)
{
    if(getprop("/controls/gear/gear-down") != 0)
    {
        if(which <= 0)
        {
            interpolate("/controls/gear/brake-left", v, fullBrakeTime);
        }
        if(which >= 0)
        {
            interpolate("/controls/gear/brake-right", v, fullBrakeTime);
        }
    }
    controls.applyAirBrakes(v);#also deploy speedbrakes when gears is down.
}