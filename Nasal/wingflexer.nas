# wingflexer.nas - A simple wing flex model.
#
# Copyright (C) 2014 Thomas Albrecht
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

#
#   -->
#    g
#       +-----+            +-----+
#  <--- | m_w |---/\/\/\---|     |
#       +-----+            +-----+
# Lift   wing     spring   fuselage
# force  mass
#
# We integrate
#
#      ..    k       d   .   0.5*F_L       ..
# 0 = -z  + --- z + ---- z - ------- - g - z_f
#           m_w     m_w       m_w
#
# where
#
# z :        deflection
# k :        wing stiffness
# d :        damping
# m_w = m_dw + fuel_frac * m_fuel
#            Total wing mass. Because the fuel is distributed over the wing, we use
#            a fraction of the fuel mass in the calculation.
# 0.5*F_L :  lift force/2 (we look at one wing only)
# ..
# z_f :      acceleration of the frame of reference (fuselage)
#
# and write the deflection (z + z_ofs) in meters to /sim/model/wing-flex/z-m.
# The offset z_ofs is calculated automatically and ensures that the dry wing
# (which still has a non-zero mass) creates neutral deflection.
#
# Discretisation by first order finite differences:
#
# z_0 - 2 z_1 + z_2    k         d  (z_0 - z_1)   1/2 F_L       ..
# ----------------- + --- z_1 + --- ----------- - ------- - g - z_f = 0
#      dt^2           m_w       m_w     dt          m_w
#
# It is convenient to divide k and d by a (constant) reference mass:
#
# K = k / m_dw
# D = d / m_dw
#
# To adapt this to your aircraft, you need m_w, K, D.
# How to estimate these?
#
# 1. Assume a dry wing mass m_dw. Research the wing fuel mass m_fuel.
#
# 2. Obtain estimates of
#    - the deflection z_flight in level flight, e.g by comparing photos
#      of the real aircraft on ground and in air,
#    - the wing's eigenfrequency, perhaps from videos of the wing's oscillation in
#      turbulence,
#    - the deflection with full and empty tanks while sitting on the ground.
#
# 3. Compute K to match in flight deflection with full tanks:
#    K = g * (m_ac / 2 - (fuel_frac * m_fuel)) / (z_in_flight / z_fac) / m_dw
#
#    where
#      m_ac : aircraft mass
#      g    : 9.81 m/s^2
#      z_fac: scaling factor for the deflection, start with 1.
#
# 4. Compute the eigenfrequency of this system for full and empty wing tanks:
#    f_full  = sqrt(K * m_dw / (m_dw + fuel_frac * m_fuel)) / (2 pi)
#    f_empty = sqrt(K) / (2 pi)
#
# Ideally we want our model to match the eigenfrequency, the deflection
# while sitting on the ground with full or empty tanks, and the deflection
# during a hard landing. Getting real-world data for the latter is difficult.
#
# There's a python script wingflexer.py which assists you in tuning the parameters.
#
# Here are some relations:
# - a lower wing mass increases the eigenfrequency, and weakens the touchdown bounce
# - a higher stiffness K reduces the deflection and increases the eigenfrequency
#
# The 787 is known for its very flexible wings; the deflection in
# unaccelerated flight is quoted as z = 3 m. One wing tank of FG's 787-8 holds
# 23,000 kg of fuel. Because the fuel is distributed over the wing, we use a
# fraction of the fuel mass in the calculation: fuel_frac = 0.75. For the same reason
# we don't use the true wing mass, but rather something that makes our model look
# plausible.
#
# So assuming a wing mass of 12000 kg, we get K=25.9 and f_empty = 0.5 Hz.
# That frequency might be a bit low, videos of a 777 wing in turbulence show about
# 2-3 Hz. (I didn't research 787 videos).
#
# To increase it, we could either reduce m_dw or increase K. A lower m_dw results
# in a rather weak bounce on touchdown which might look odd. A higher K reduces
# the deflection z_flight, but we can simply scale the animation to account for
# that. We'll multiply the deflection z by a factor z_fac to get an angle for the
# <rotate> animation later on anyway. So repeat 3. and 4. using e.g. z_fac = 10.
# Now K = 259 and f_empty=2.6 Hz. While our model spring now only deflects
# to 0.3 m instead of 3 m, the animation scale factor will make sure the wing
# bends to 3 m. This way, we can match both eigenfrequency and observed deflection,
# and still get a realistic bounce on touch down. Finally, adjust D such that an
# impulse is damped out after about one or two oscillations; D = 12 seems to work
# OK in our example.
#
# It's difficult to get real-world data on the deflection during touchdown.
# Touchdown at more than 10 ft/s is considered a hard landing. There's a video of
# a hard landing of an A346 (http://avherald.com/h?article=471e70e9), showing the
# wings bend perhaps 1 m. But I couldn't find any data for the acceleration over
# time during a hard landing.
#
# To assist you in tuning parameters for the touchdown bounce we can give our
# wing mass the touchdown vertical speed via /sim/model/wing-flex/sink-rate_fps.
#
# Our model outputs the deflection in meters, but the <rotate> animation expects an
# angle. It is up to you calculate an appropriate factor, depending on your wing
# span and number of segments in the animation. Also don't forget to include z_fac.
#
# To use this with your JSBSim aircraft, use
#
#   io.include("Aircraft/Generic/wingflexer.nas");
#   WingFlexer.new(1, K, D, mass_dry_wing_kg,
#       fuel_fraction, fuel_node_left, fuel_node_right);
#
# with apropriate parameters.
#
# Yasim does not write the lift to the property tree. But you can create a helper
# function which computes the lift as
#   lift_force_lbs = aircraft_weight_lbs * load_factor - total_weight_on_wheels_lbs
# and write lift_force_lbs to /fdm/jsbsim/forces/fbz-aero-lbs (or another location
# passed to WingFlexer.new() as lift_node).
#
# TODO
# - write Yasim helper
# - perhaps use analytical solution of ODE
# - input for fuselage acceleration should rather be acceleration at CG -- find property

io.include("Aircraft/Generic/updateloop.nas");

var WingFlexer = {
    parents: [Updatable], 

    # FIXME: these defaults make the 787-8 wing flex look realistic, which is certainly not
    #        the most generic airliner wing. Once someone obtains a set of parameters for e.g.
    #        the 777, use them here.

    new: func(enable = 1, K=259., D=12., mass_dry_wing_kg = 12000., fuel_fraction = 0.75,
              fuel_node_left = "consumables/fuel/tank/level-kg",
              fuel_node_right = "consumables/fuel/tank[1]/level-kg",
              node = "sim/model/wing-flex/", lift_node = "fdm/jsbsim/forces/fbz-aero-lbs") {
        var m = { parents: [WingFlexer] };
        m.node = node;
        m.m_dw = mass_dry_wing_kg;
        m.k = K * m.m_dw;
        m.d = D * m.m_dw;
        m.fuel_frac_on_2 = fuel_fraction / 2.; # so we don't have to divide each frame
        m.fuel_node_left = fuel_node_left;
        m.fuel_node_right = fuel_node_right;
        m.lift_node = lift_node;
        m.loop = UpdateLoop.new(components: [m], enable: enable);
        return m;
    },

    reset: func {

        me.z  = 0.;
        me.z1 = 0.;
        me.z2 = 0.;

        setprop(me.node ~ "z-m", 0.);
        setprop(me.node ~ "mass-wing-kg", me.m_dw);
        setprop(me.node ~ "K", me.k/me.m_dw);
        setprop(me.node ~ "D", me.d/me.m_dw);
        setprop(me.node ~ "fuel-fac", me.fuel_frac_on_2 * 2);
        setprop(me.node ~ "sink-rate_fps", 0.);
        me.g_on_2_times_LB2KG = getprop("/environment/gravitational-acceleration-mps2") / 2. * globals.LB2KG;
        me.calc_z_ofs();

        setlistener(me.node ~ "mass-wing-kg", func(the_node) {
            me.m_dw = the_node.getValue();
            me.calc_z_ofs();
        }, 0, 0);
        setlistener(me.node ~ "K", func(the_node) {
            me.k = the_node.getValue() * me.m_dw;
            me.calc_z_ofs();
        }, 0, 0);
        setlistener(me.node ~ "D", func(the_node) { me.d = the_node.getValue() * me.m_dw; }, 0, 0);
        setlistener(me.node ~ "fuel-fac", func(the_node) { me.fuel_frac_on_2 = the_node.getValue() / 2.; }, 0, 0);

        # The following helped me getting wing flex look OK. It's no longer
        # needed once you get the parameters right, so it's disabled by default.
        # Look for DEV to re-enable.
        # Include z-fac here, so you don't have to adjust the animation .xml
#        setprop(me.node ~ "z-fac", 3.);
#        me.last_dt = 1/30.;
#        me.max_z = 0.;
#        setlistener(me.node ~ "sink-rate_fps", func(the_node) {
#            var dz = me.last_dt * the_node.getValue() * globals.FT2M;
#            me.z0 = me.z1 - dz;
#            me.z2 = me.z1 + dz;
#            me.max_z = 0.;
#        }, 1, 0);
    },

    calc_z_ofs: func() {
        print ("wingflex: calc z_ofs");
        me.z_ofs = getprop("/environment/gravitational-acceleration-mps2") * me.m_dw / me.k;
    },

    update: func(dt) {
        # limit time step to avoid numerical instability
        if (dt > 0.2) dt = 0.2;

        # DEV:
#        me.last_dt = dt;

        # fuselage z (up) acceleration in m/s^2
        # we get -g in unaccelerated flight, and large negative numbers on touchdown
        var a_f = getprop("accelerations/pilot/z-accel-fps_sec") * globals.FT2M;

        # lift force. Convert to N and use 1/2 (one wing only)
        var F_l = getprop(me.lift_node) * me.g_on_2_times_LB2KG;

        # compute total mass of one wing, using the average fuel mass in both wing tanks.
        # The averaging factor 0.5 is lumped into fuel_frac_on_2
        me.m = me.m_dw + me.fuel_frac_on_2 * (getprop(me.fuel_node_left) + getprop(me.fuel_node_right));

        # integrate discretised equation of motion
        # reverse sign of F_l because z in JSBsim body coordinate system points down
        me.z = (2.*me.z1 - me.z2 + dt * ((me.d * me.z1 + dt * (-F_l - me.k * me.z1))/me.m + dt *
                                         a_f)) / (1. + me.d * dt / me.m);
        me.z2 = me.z1;
        me.z1 = me.z;

        me.z += me.z_ofs;

        # output to property
        setprop(me.node ~ "z-m", me.z);

        # DEV: scale output and log max deflection
#        var z_fac = getprop(me.node ~ "z-fac");
#        if (me.z * z_fac < me.max_z) me.max_z = me.z * z_fac;
#        print (sprintf(" z %4.2f max %4.2f m %7.1f", me.z * z_fac, me.max_z, me.m));
#        setprop(me.node ~ "z-m", me.z * z_fac);
    },

    enable: func { me.loop.enable() },
    disable: func { me.loop.disable() },
};



