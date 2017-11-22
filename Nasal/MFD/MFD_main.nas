# F-16 Canvas MFD
# Based on F-15, using generic MFD device from FGData.
# ---------------------------
# Richard Harrison: 2016-09-12 : rjh@zaretto.com
# ---------------------------

#for debug: setprop ("/sim/startup/terminal-ansi-colors",0);

var MFD_Station =
{
	new : func (svg, ident)
    {
		var obj = {parents : [MFD_Station] };

        obj.status = svg.getElementById("PACS_L_"~ident);
        if (obj.status == nil)
            print("Failed to load PACS_L_"~ident);

        obj.label = svg.getElementById("PACS_V_"~ident);
        if (obj.label == nil)
            print("Failed to load PACS_V_"~ident);

        obj.selected = svg.getElementById("PACS_R_"~ident);
        if (obj.selected == nil)
            print("Failed to load PACS_R_"~ident);

        obj.selected1 = svg.getElementById("PACS_R1_"~ident);
        if (obj.selected1 == nil)
            print("Failed to load PACS_R1_"~ident);

        obj.prop = "payload/weight["~ident~"]";
        obj.ident = ident;

#        setlistener(obj.prop~"/selected", func(v)
#                    {
    #                    obj.update();
#                    });
        setlistener("sim/model/f16/controls/armament/weapons-updated", func
                    {
                        obj.update();
                    });

        return obj;
    },

    update: func(notification)
    {
        var weapon_mode = notification.weapon_mode;
        var na = getprop(me.prop~"/selected");
        var sel = 0;
        var mode = "STBY";
        var sel_node = "sim/model/f16/systems/external-loads/station["~me.ident~"]/selected";
        var master_arm=getprop("sim/model/f16/controls/armament/master-arm-switch");

        if (na != nil and na != "none")
        {
            if (na == "AIM-9")
            {
                na = "9L";
                if (weapon_mode == 1)
                {
                    sel = getprop(sel_node);
                    if (sel and master_arm)
                        mode = "RDY";
                }
                else mode = "SRM";
            }
            elsif (na == "AIM-120") 
            {
                na = "120A";
                if (weapon_mode == 2)
                {
                    sel = getprop(sel_node);
                    if (sel and master_arm)
                        mode = "RDY";
                }
                else mode = "MRM";
            }
            elsif (na == "AIM-7") 
            {
                na = "7M";
                if (weapon_mode == 2)
                {
                    sel = getprop(sel_node);
                    if (sel and master_arm)
                        mode = "RDY";
                }
                else mode = "MRM";
            }
            me.status.setText(mode);
            me.label.setText(na);

            me.selected1.setVisible(sel);
            if (mode == "RDY")
            {
                me.selected.setVisible(sel);
                me.status.setColor(0,1,0);
            }
            else
            {
                me.selected.setVisible(0);
                me.status.setColor(1,1,1);
            }
        }
        else
        {
            me.status.setText("");
            me.label.setText("");
            me.selected.setVisible(0);
            me.selected1.setVisible(0);
        }
    },
};
# aircraft.f16_mfd.MFD.canvas._node.setValues({
#                            "name": "F-15 HUD",
#                            "size": [1024,1024], 
#                            "view": [572,512],                       
#                            "mipmapping": 1  
#   });
#         aircraft.f16_mfd.MFD.PFDsvg.setTranslation (0.0, 17.0);
var PFD_VSD =
{
#
# Instantiate parameters:
# 1. pfd_device (instance of PFD_Device)
# 2. instrument display ident (e.g. mfd-map, or mfd-map-left mfd-map-right for multiple displays)
#    (this is used to map to the property tree)
# 3. layer_id: main layer  in the SVG
# 4. nd_group_ident : group (usually within the main layer) to place the NavDisplay
# 5. switches - used to connect the property tree to the nav display. see the canvas nav display
#    documentation
	new : func (pfd_device, title, instrument_ident, layer_id)
    {
		var obj = pfd_device.addPage(title, layer_id);

        obj.pfd_device = pfd_device;

        obj.window1 = obj.svg.getElementById("window-1");
        obj.window1.setFont("condensed.txf").setFontSize(12, 1.2);
        obj.window2 = obj.svg.getElementById("window-2");
        obj.window2.setFont("condensed.txf").setFontSize(12, 1.2);
        obj.window3 = obj.svg.getElementById("window-3");
        obj.window3.setFont("condensed.txf").setFontSize(12, 1.2);
        obj.window4 = obj.svg.getElementById("window-4");
        obj.window4.setFont("condensed.txf").setFontSize(12, 1.2);
        obj.acue = obj.svg.getElementById("ACUE");
        obj.acue.setFont("condensed.txf").setFontSize(12, 1.2);
        obj.acue.setText ("A");
        obj.acue.setVisible(0);
        obj.ecue = obj.svg.getElementById("ECUE");
        obj.ecue.setFont("condensed.txf").setFontSize(12, 1.2);
        obj.ecue.setText ("E");
        obj.ecue.setVisible(0);
        obj.morhcue = obj.svg.getElementById("MORHCUE");
        obj.morhcue.setFont("condensed.txf").setFontSize(12, 1.2);
        obj.morhcue.setText ("mh");
        obj.morhcue.setVisible(0);
        obj.max_symbols = 10;
        obj.tgt_symbols =  setsize([], obj.max_symbols);
        obj.horizon_line = obj.svg.getElementById("horizon_line");
        obj.nofire_cross =  obj.svg.getElementById("nofire_cross");
        obj.target_circle = obj.svg.getElementById("target_circle");
        for (var i = 0; i < obj.max_symbols; i += 1)
        {
            var name = "target_friendly_"~i;
            var tgt = obj.svg.getElementById(name);
            if (tgt != nil)
            {
                obj.tgt_symbols[i] = tgt;
                tgt.setVisible(0);
            }
        }

        obj.vsd_on = 1;
        #
        # Method overrides
        #-----------------------------------------------
        # Called when the page goes on display - need to delay initialization of the NavDisplay until later (it fails
        # if done too early).
        # NOTE: This causes a display "wobble" the first time on display as resizing happens. I've seen similar things
        #       happen on real avionics (when switched on) so it's not necessarily unrealistic -)
        obj.ondisplay = func
        {
        };

        obj.update = func(notification)
        {
        if(!me.vsd_on)
            return;

        var pitch = notification.pitch;
        var roll = notification.roll;
        var alt = notification.altitude_ft;
        var roll_rad = -roll*3.14159/180.0;
        var heading = notification.heading;
        var pitch_offset = 12;
        var pitch_factor = 1.98;


        me.horizon_line.setTranslation (0.0, pitch * pitch_factor+pitch_offset);                                           
        me.horizon_line.setRotation (roll_rad);

        if (notification.target_display)
        {   
#       window3.setText (sprintf("%s: %3.1f", getprop("sim/model/f15/instrumentation/radar-awg-9/hud/target"), getprop("sim/model/f15/instrumentation/radar-awg-9/hud/distance")));
            me.nofire_cross.setVisible(1);
            me.target_circle.setVisible(1);
        }
        else
        {
#       window3.setText ("");
            me.nofire_cross.setVisible(0);
            me.target_circle.setVisible(0);
        }
        var w1 = "     VS BST   MEM  ";

        var target_idx=1;
        me.window4.setText (sprintf("%3d", notification.radar_range));
        var w3_22="";
        var w3_7 = sprintf("T %d",notification.vc_kts);
        var w2 = "";
        var designated = 0;
        foreach( u; awg_9.tgts_list ) 
        {
            var callsign = "XX";
            if (u.Callsign != nil)
                callsign = u.Callsign.getValue();
            var model = "XX";
            if (u.ModelType != "")
                model = u.ModelType;
            if (target_idx < me.max_symbols)
            {
                tgt = me.tgt_symbols[target_idx];
                if (tgt != nil)
                {
#                    if (u.airbone and !designated)
#                    if (target_idx == 0)
#                    if (awg_9.nearest_u != nil and awg_9.nearest_u.Callsign != nil and u.Callsign.getValue() == awg_9.nearest_u.Callsign.getValue())
                    if (awg_9.active_u != nil and awg_9.active_u.Callsign != nil and u.Callsign.getValue() == awg_9.active_u.Callsign.getValue())
#if (u == awg_9.active_u)
                    {
                        designated = 1;
                        tgt.setVisible(0);
                        tgt = me.tgt_symbols[0];
#                    w2 = sprintf("%-4d", u.get_closure_rate());
#                    w3_22 = sprintf("%3d-%1.1f %.5s %.4s",u.get_bearing(), u.get_range(), callsign, model);
#                    var aspect = u.get_reciprocal_bearing()/10;
#                   w1 = sprintf("%4d %2d%s %2d %d", u.get_TAS(), aspect, aspect < 180 ? "r" : "l", u.get_heading(), u.get_altitude());
                    }
                    tgt.setVisible(u.get_display());
                    var xc = u.get_deviation(heading);
                    var yc = -u.get_total_elevation(pitch);
                    tgt.setVisible(1);
                    tgt.setTranslation (xc, yc);
                }
            }
            if (!designated)
                target_idx = target_idx+1;
        }
        if (awg_9.active_u != nil)
        {
            if (awg_9.active_u.Callsign != nil)
                callsign = awg_9.active_u.Callsign.getValue();

            var model = "XX";
            if (awg_9.active_u.ModelType != "")
                model = awg_9.active_u.ModelType;

            w2 = sprintf("%-4d", awg_9.active_u.get_closure_rate());
            w3_22 = sprintf("%3d-%1.1f %.5s %.4s",awg_9.active_u.get_bearing(), awg_9.active_u.get_range(), callsign, model);
            var aspect = awg_9.active_u.get_reciprocal_bearing()/10;
            w1 = sprintf("%4d %2d%s %2d %d", awg_9.active_u.get_TAS(), aspect, aspect < 180 ? "r" : "l", awg_9.active_u.get_heading(), awg_9.active_u.get_altitude());
        }
        me.window1.setText(w1);
        me.window2.setText(w2);
#    window3.setText(sprintf("G%3.0f %3s-%4s%s %s %s",
        me.window3.setText(sprintf("G%3.0f %s %s",
                                   notification.groundspeed_kt,
                                   w3_7 , 
                                   w3_22));
        for(var nv = target_idx; nv < me.max_symbols;nv += 1)
        {
            tgt = me.tgt_symbols[nv];
            if (tgt != nil)
            {
                tgt.setVisible(0);
            }
        }
        };        
        return obj;
    },
};

var MFD_Device =
{
#
# create new MFD device. This is the main interface (from our code) to the MFD device
# Each MFD device will contain the underlying PFD device object, the SVG, and the canvas
# Parameters
# - designation - Flightdeck Legend for this
# - model_element - name of the 3d model element that is to be used for drawing
# - model_index - index of the device
    new : func(designation, model_element, model_index=0)
    {
        var obj = {parents : [MFD_Device] };
        obj.designation = designation;
        obj.model_element = model_element;
        var dev_canvas= canvas.new({
                "name": designation,
                           "size": [512,512], 
                            "view": [552,482],                       
                    "mipmapping": 1     
                    });                          

        obj.canvas = dev_canvas;
        dev_canvas.addPlacement({"node": model_element});
        dev_canvas.setColorBackground(0.002,0.09,0, 0);
# Create a group for the parsed elements
        obj.PFDsvg = dev_canvas.createGroup();
        var pres = canvas.parsesvg(obj.PFDsvg, "Nasal/MFD/MFD.svg");
# Parse an SVG file and add the parsed elements to the given group
        #printf("MFD : %s Load SVG %s",designation,pres);
        obj.PFDsvg.setTranslation (-20.0, 0);
#
# create the object that will control all of this
        obj.num_menu_buttons = 20;
        obj.PFD = PFD_Device.new(obj.PFDsvg, obj.num_menu_buttons, "MI_", dev_canvas);
        obj.PFD._canvas = dev_canvas;
        obj.PFD.designation = designation;
        obj.mfd_device_status = 1;
        obj.model_index = model_index; # numeric index (1 to 9, left to right) used to connect the buttons in the cockpit to the display

        obj.addPages();
        return obj;
    },

    setupRadar: func (svg) {
        svg.p_RDR = me.canvas.createGroup()
                .setTranslation(276*0.795,512);#552,482 , 0.795 is for UV map
        
        svg.blep = setsize([],200);
        for (var i = 0;i<200;i+=1) {
            svg.blep[i] = svg.p_RDR.createChild("path")
                    .moveTo(0,0)
                    .vert(4)
                    .setStrokeLineWidth(4)
                    .hide();
        }
        svg.lock = setsize([],200);
        for (var i = 0;i<200;i+=1) {
            svg.lock[i] = svg.p_RDR.createChild("path")
                        .moveTo(-10,-10)
                            .vert(20)
                            .horiz(20)
                            .vert(-20)
                            .horiz(-20)
                            .moveTo(0,-10)
                            .vert(-10)
                            .setStrokeLineWidth(2)
                    .hide();
        }
    },

    addRadar: func {
        var svg = {getElementById: func (id) {return me[id]},};
        me.setupRadar(svg);
        me.PFD.addRadarPage = func(svg, title, layer_id) {   
            var np = PFD_Page.new(svg, title, layer_id, me);
            append(me.pages, np);
            me.page_index[layer_id] = np;
            np.setVisible(0);
            return np;
        };        
        me.p_RDR = me.PFD.addRadarPage(svg, "Radar", "p_RDR");
        me.p_RDR.root = svg;
        me.p_RDR.update = func {
            me.i=0;
            foreach(contact; awg_9.tgts_list) {
                me.distPixels = contact.get_range()*(482/awg_9.range_radar2);

                me.root.blep[me.i].setColor(1,1,1);
                me.root.blep[me.i].setTranslation(276*0.795*geo.normdeg180(contact.get_relative_bearing())/60,-me.distPixels);
                me.root.blep[me.i].show();
                me.root.blep[me.i].update();
                if (contact==awg_9.active_u or (awg_9.active_u != nil and contact.get_Callsign() == awg_9.active_u.get_Callsign() and contact.ModelType==awg_9.active_u.ModelType)) {
                    me.rot = contact.get_heading();
                    if (me.rot == nil) {
                        #can happen in transition between TWS to RWS
                        me.root.lock[me.i].hide();
                    } else {
                        me.rot = me.rot-getprop("orientation/heading-deg")-geo.normdeg180(contact.get_relative_bearing());
                        me.root.lock[me.i].setRotation(me.rot*D2R);
                        me.root.lock[me.i].setColor([1,1,0]);
                        me.root.lock[me.i].setTranslation(276*0.795*geo.normdeg180(contact.get_relative_bearing())/60,-me.distPixels);
                        me.root.lock[me.i].show();
                        me.root.lock[me.i].update();
                    }
                } else {
                    me.root.lock[me.i].hide();
                }
                me.i += 1;
                if (me.i > 199) break;
            }
            for (;me.i<200;me.i+=1) {
                me.root.blep[me.i].hide();
                me.root.lock[me.i].hide();
            }
        };
    },

    addPages : func
    {   
        me.addRadar();
        me.p1_1 = me.PFD.addPage("Aircraft Menu", "p1_1");

        me.p1_1.update = func(notification)
        {
            var sec = getprop("instrumentation/clock/indicated-sec");
            me.page1_1.time.setText(getprop("sim/time/gmt-string")~"Z");
            var cdt = getprop("sim/time/gmt");

            if (cdt != nil)
                me.page1_1.date.setText(substr(cdt,5,2)~"/"~substr(cdt,8,2)~"/"~substr(cdt,2,2)~"Z");
        };

        me.p1_1 = me.PFD.addPage("Aircraft Menu", "p1_1");
        me.p1_2 = me.PFD.addPage("Top Level PACS Menu", "p1_2");
        me.p1_3 = me.PFD.addPage("PACS Menu", "p1_3");
        me.p_VSD = PFD_VSD.new(me.PFD,"VSD", "VSD0", "p_VSD");

        me.p1_3.S0 = MFD_Station.new(me.PFDsvg, 0);
        #1 droptank
        me.p1_3.S2 = MFD_Station.new(me.PFDsvg, 2);
        me.p1_3.S3 = MFD_Station.new(me.PFDsvg, 3);
        me.p1_3.S4 = MFD_Station.new(me.PFDsvg, 4);
        #5 droptank
        me.p1_3.S6 = MFD_Station.new(me.PFDsvg, 6);
        me.p1_3.S7 = MFD_Station.new(me.PFDsvg, 7);
        me.p1_3.S8 = MFD_Station.new(me.PFDsvg, 8);
        #9 droptank
        me.p1_3.S10 = MFD_Station.new(me.PFDsvg, 10);

        me.pjitds_1 =  PFD_NavDisplay.new(me.PFD,"Situation", "mfd-sit", "pjitds_1", "jtids_main");
        # use the radar range as the ND range.

        me.p_spin_recovery = me.PFD.addPage("Spin recovery", "p_spin_recovery");
        me.p_spin_recovery.cur_page = nil;

        me.p1_1.date = me.PFDsvg.getElementById("p1_1_date");
        me.p1_1.time = me.PFDsvg.getElementById("p1_1_time");

        me.p_spin_recovery.p_spin_cas = me.PFDsvg.getElementById("p_spin_cas");
        me.p_spin_recovery.p_spin_alt = me.PFDsvg.getElementById("p_spin_alt");
        me.p_spin_recovery.p_spin_alpha = me.PFDsvg.getElementById("p_spin_alpha");
        me.p_spin_recovery.p_spin_stick_left  = me.PFDsvg.getElementById("p_spin_stick_left");
        me.p_spin_recovery.p_spin_stick_right  = me.PFDsvg.getElementById("p_spin_stick_right");
        me.p_spin_recovery.update = func
        {
            me.p_spin_alpha.setText(sprintf("%d", getprop ("orientation/alpha-indicated-deg")));
            me.p_spin_alt.setText(sprintf("%5d", getprop ("instrumentation/altimeter/indicated-altitude-ft")));
            me.p_spin_cas.setText(sprintf("%3d", getprop ("instrumentation/airspeed-indicator/indicated-speed-kt")));

            if (math.abs(getprop("fdm/jsbsim/velocities/r-rad_sec")) > 0.52631578947368421052631578947368 
                or math.abs(getprop("fdm/jsbsim/velocities/p-rad_sec")) > 0.022)
            {
                me.p_spin_stick_left.setVisible(1);
                me.p_spin_stick_right.setVisible(0);
            }
            else
            {
                me.p_spin_stick_left.setVisible(0);
                me.p_spin_stick_right.setVisible(1);
            }
        };

        #
        # Page 1 is the time display
        me.p1_1.update = func(notification)
        {
            me.time.setText(notification.gmt_string~"Z");
            var cdt = notification.gmt;

            if (cdt != nil)
                me.date.setText(substr(cdt,5,2)~"/"~substr(cdt,8,2)~"/"~substr(cdt,2,2)~"Z");
        };

        #
        # armament page gun rounds is implemented a little differently as the menu item (1) changes to show
        # the contents of the magazine.
        me.p1_3.gun_rounds = me.p1_3.addMenuItem(1, sprintf("HIGH\n%dM",getprop("sim/model/f16/systems/gun/rounds")), me.p1_3);

        setlistener("sim/model/f16/systems/gun/rounds", func(v)
                    {
                        if (v != nil) {
                            me.p1_3.gun_rounds.title = sprintf("HIGH\n%dM",v.getValue());
                            me.PFD.updateMenus();
                        }
                    }
            );
        me.PFD.selectPage(me.p1_1);
        me.mfd_button_pushed = 0;
        # Connect the buttons - using the provided model index to get the right ones from the model binding
        setlistener("controls/MFD["~me.model_index~"]/button-pressed", func(v)
                    {
                        if (v != nil) {
                            if (v.getValue())
                                me.mfd_button_pushed = v.getValue();
                            else {
                                printf("%s: Button %d",me.designation, me.mfd_button_pushed);
                                me.PFD.notifyButton(me.mfd_button_pushed);
                                me.mfd_button_pushed = 0;
                            }
                        }
                    }
            );

        # Set listener on the PFD mode button; this could be an on off switch or by convention
        # it will also act as brightness; so 0 is off and anything greater is brightness.
        # ranges are not pre-defined; it is probably sensible to use 0..10 as an brightness rather
        # than 0..1 as a floating value; but that's just my view.
        setlistener("controls/MFD["~me.model_index~"]/mode", func(v)
                    {
                        if (v != nil) {
                            me.mfd_device_status = v.getValue();
                            print("MFD Mode ",me.designation," ",me.mfd_device_status);
                            if (!me.mfd_device_status)
                                me.PFDsvg.setVisible(0);
                            else
                                me.PFDsvg.setVisible(1);
                        }
                    }
            );

#
# Connect the radar range to the nav display range. 
        var range_val = getprop("instrumentation/radar/radar2-range");
        if (range_val == nil)
          range_val=50;

        setprop("instrumentation/mfd-sit/inputs/range-nm", range_val);
        setlistener("instrumentation/radar/radar2-range", 
            func(v)
            {
                setprop("instrumentation/mfd-sit/inputs/range-nm", v.getValue());
            });
#
# Mode switch is day/night/off. we just do on/off
        setlistener("controls/MFD["~me.model_index~"]/mode", func(v)
            {
                if (v != nil)
                {
                    me.PFD.mfd_mode = v.getValue();
#    if (!mfd_mode)
#        me.MFDcanvas.setVisible(0);
#    else
#        mr.MFDcanvas.setVisible(1);
                }
            });

        me.mfd_button_pushed = 0;
        me.setupMenus();
        me.PFD.selectPage(me.p1_1);
    },

    # Add the menus to each page. 
    setupMenus : func
    {
#
# Menu Id's
# 0           5            
# 1           6            
# 2           7            
# 3           8            
# 4           9            
#
# Top: 10 11 12 13 14 
# Bot: 15 16 17 18 19
        me.mfd_spin_reset_time = 0;

        me.p1_1.addMenuItem(0, "ARMT", me.p1_2);
        me.p1_1.addMenuItem(1, "VSD", me.p_VSD);
        me.p1_1.addMenuItem(2, "SIT", me.pjitds_1);
        me.p1_1.addMenuItem(3, "WPN", me.p1_2);
        me.p1_1.addMenuItem(4, "DTM", me.p1_2);
        me.p1_1.addMenuItem(10, "RDR", me.p_RDR);

        me.p_RDR.addMenuItem(10, "TIM", me.p1_1);

        me.p1_2.addMenuItem(0, "VSD", me.p_VSD);
        me.p1_2.addMenuItem(1, "A/A", me.p1_3);
        me.p1_2.addMenuItem(2, "A/G", me.p1_3);
        me.p1_2.addMenuItem(3, "CBT JETT", me.p1_3);
        me.p1_2.addMenuItem(4, "WPN LOAD", me.p1_3);
        me.p1_2.addMenuItem(9, "M", me.p1_1);
        me.p1_2.addMenuItem(10, "RDR", me.p_RDR);


        me.p1_3.addMenuItem(2, "SIT", me.pjitds_1);
        me.p1_3.addMenuItem(3, "A/G", me.p1_3);
        me.p1_3.addMenuItem(4, "2/2", me.p1_3);
        me.p1_3.addMenuItem(8, "TM\nPWR", me.p1_3);
        me.p1_3.addMenuItem(9, "M", me.p1_1);
        me.p1_3.addMenuItem(10, "PYLON", me.p1_3);
        me.p1_3.addMenuItem(12, "FUEL", me.p1_3);
        me.p1_3.addMenuItem(14, "PYLON", me.p1_3);
        me.p1_3.addMenuItem(15, "MODE S", me.p1_3);
        me.p1_3.addMenuItem(10, "RDR", me.p_RDR);

        me.pjitds_1.addMenuItem(9, "M", me.p1_1);
        me.pjitds_1.addMenuItem(0, "ARMT", me.p1_2);
        me.pjitds_1.addMenuItem(1, "VSD", me.p_VSD);
        me.pjitds_1.addMenuItem(10, "RDR", me.p_RDR);

        me.p_VSD.addMenuItem(0, "ARMT", me.p1_2);
        me.p_VSD.addMenuItem(1, "SIT", me.pjitds_1);
        me.p_VSD.addMenuItem(4, "M", me.p1_1);
        me.p_VSD.addMenuItem(9, "M", me.p1_1);
        me.p_VSD.addMenuItem(10, "RDR", me.p_RDR);
    },

    update : func(notification)
    {
    # see if spin recovery page needs to be displayed.
    # it is displayed automatically and will remain for 5 seconds.
    # this page provides (sort of) guidance on how to recover from a spin
    # which is identified by the yar rate.
#         if (!notification.wow and math.abs(getprop("fdm/jsbsim/velocities/r-rad_sec")) > 0.52631578947368421052631578947368)
#         {
#             if (me.PFD.current_page != me.p_spin_recovery)
#             {
#                 me.p_spin_recovery.cur_page = me.PFD.current_page;
#                 me.PFD.selectPage(me.p_spin_recovery);
#             }
#             me.mfd_spin_reset_time = getprop("instrumentation/clock/indicated-sec") + 5;
#         } 
#         else
#         {
#             if (me.mfd_spin_reset_time > 0 and getprop("instrumentation/clock/indicated-sec") > me.mfd_spin_reset_time)
#             {
#                 me.mfd_spin_reset_time = 0;
#                 if (me.p_spin_recovery.cur_page != nil)
#                 {
#                     me.PFD.selectPage(me.p_spin_recovery.cur_page);
#                     me.p_spin_recovery.cur_page = nil;
#                 }
#             }
#         }

        if (me.mfd_device_status)
            me.PFD.update(notification);
    },
};




var F16MfdRecipient = 
{
    new: func(_ident)
    {
        var new_class = emesary.Recipient.new(_ident~".MFD");
        new_class.MFDl =  MFD_Device.new("F16-MFD", "MFDimage1",0);
        new_class.MFDr =  MFD_Device.new("F16-MFD", "MFDimage2",1);

        new_class.Receive = func(notification)
        {
            if (notification == nil)
            {
                print("bad notification nil");
                return emesary.Transmitter.ReceiptStatus_NotProcessed;
            }

            if (notification.NotificationType == "FrameNotification")
            {
                me.MFDl.update(notification);
                me.MFDr.update(notification);
                return emesary.Transmitter.ReceiptStatus_OK;
            }
            return emesary.Transmitter.ReceiptStatus_NotProcessed;
        };
        return new_class;
    },
};
#
#
# temporary code (2016.3.x) until MFD_Generic.nas is updated in FGData (2016.4.x)
PFD_Device.update = func(notification=nil)
    {
        if (me.current_page != nil)
            me.current_page.update(notification);
    };

#F16MfdRecipient.new("BAe-F16b-MFD");
f16_mfd = F16MfdRecipient.new("F16-MFD");
#UpperMFD = f16_mfd.UpperMFD;
#LowerMFD = f16_mfd.LowerMFD;

emesary.GlobalTransmitter.Register(f16_mfd);
