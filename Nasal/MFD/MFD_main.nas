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

        obj.menuLayer = svg.getElementById("layer2");
        obj.menuLayer.setColor(1,1,1);

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
        if(!me.vsd_on or notification.FrameCount == 0  or notification.FrameCount == 2)
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
        var has_seen_active = 0;
        foreach( u; awg_9.tgts_list ) 
        {
            designated = 0;
            if (u.get_display() == 0) {
                continue;
            }
            var callsign = "XX";
            if (u.Callsign != nil)
                callsign = u.Callsign.getValue();
            var model = "XX";
            if (u.ModelType != "")
                model = u.ModelType;
            if (target_idx < me.max_symbols or has_seen_active == 0)
            {
                if (target_idx < me.max_symbols)
                    tgt = me.tgt_symbols[target_idx];
                else
                    tgt = me.tgt_symbols[0];
                if (tgt != nil)
                {
#                    if (u.airbone and !designated)
#                    if (target_idx == 0)
#                    if (awg_9.nearest_u != nil and awg_9.nearest_u.Callsign != nil and u.Callsign.getValue() == awg_9.nearest_u.Callsign.getValue())
                    if (awg_9.active_u != nil and awg_9.active_u.Callsign != nil and u.Callsign.getValue() == awg_9.active_u.Callsign.getValue())
#if (u == awg_9.active_u)
                    {
                        has_seen_active = 1;
                        designated = 1;
                        #tgt.setVisible(0);
                        tgt = me.tgt_symbols[0];
#                    w2 = sprintf("%-4d", u.get_closure_rate());
#                    w3_22 = sprintf("%3d-%1.1f %.5s %.4s",u.get_bearing(), u.get_range(), callsign, model);
#                    var aspect = u.get_reciprocal_bearing()/10;
#                   w1 = sprintf("%4d %2d%s %2d %d", u.get_TAS(), aspect, aspect < 180 ? "r" : "l", u.get_heading(), u.get_altitude());
                    } elsif (target_idx >= me.max_symbols) {
                        continue;
                    }
                    #tgt.setVisible(u.get_display());
                    var xc = u.get_deviation(heading);
                    var yc = -u.get_total_elevation(pitch);
                    tgt.setVisible(1);
                    tgt.setTranslation (xc*1.55, yc*1.85);
                }
            }
            if (!designated)
                target_idx = target_idx+1;
        }
        if (awg_9.active_u != nil and awg_9.active_u.get_display()==1)
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
        if(!has_seen_active)
            me.tgt_symbols[0].hide();
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
        if (getprop("sim/variant-id") == 2) {
        dev_canvas.setColorBackground(0.0,0.0,0.052, 1);
        } else if (getprop("sim/variant-id") == 4) {
        dev_canvas.setColorBackground(0.0,0.0,0.052, 1);
        } else if (getprop("sim/variant-id") == 5) {
        dev_canvas.setColorBackground(0.0,0.0,0.052, 1);
        } else if (getprop("sim/variant-id") == 6) {
        dev_canvas.setColorBackground(0.0,0.0,0.052, 1);
        } else {
        dev_canvas.setColorBackground(0.002,0.1,0, 0);
        };
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

    setupRadar: func (svg, index) {
        svg.p_RDR = me.canvas.createGroup()
                .setTranslation(276*0.795,482)
                .set("font","LiberationFonts/LiberationMono-Regular.ttf");#552,482 , 0.795 is for UV map
        svg.maxB = 16;
        svg.index = index;
        svg.blep = setsize([],svg.maxB);
        svg.iff  = setsize([],svg.maxB);
        for (var i = 0;i<svg.maxB;i+=1) {
            svg.blep[i] = svg.p_RDR.createChild("path")
                    .moveTo(0,-3)
                    .vert(7)
                    .setStrokeLineWidth(7)
                    .setStrokeLineCap("butt")
                    .set("z-index",10)
                    .hide();
            svg.iff[i] = svg.p_RDR.createChild("text")
                    .setText("4")
                    .setAlignment("center-center")
                    .setColor(0,1,0)
                    .set("z-index",1)
                    .setFontSize(22, 1.0);
        }
        svg.rangUp = svg.p_RDR.createChild("path")
                    .moveTo(-276*0.795,-482*0.5-105-27.5)
                    .horiz(30)
                    .lineTo(-276*0.795+15,-482*0.5-105-27.5-15)
                    .lineTo(-276*0.795,-482*0.5-105-27.5)
                    .setStrokeLineWidth(2)
                    .set("z-index",1)
                    .setColor(1,1,1);
        svg.rang = svg.p_RDR.createChild("text")
                .setTranslation(-276*0.795, -482*0.5-105)
                .setAlignment("left-center")
                .setColor(1,1,1)
                .set("z-index",1)
                .setFontSize(20, 1.0);
        svg.rangDown = svg.p_RDR.createChild("path")
                    .moveTo(-276*0.795,-482*0.5-105+27.5)
                    .horiz(30)
                    .lineTo(-276*0.795+15,-482*0.5-105+27.5+15)
                    .lineTo(-276*0.795,-482*0.5-105+27.5)
                    .setStrokeLineWidth(2)
                    .set("z-index",1)
                    .setColor(1,1,1);
        svg.az = svg.p_RDR.createChild("text")
                .setTranslation(-276*0.795, -482*0.5-5)
                .setText("A4")
                .setAlignment("left-center")
                .setColor(1,1,1)
                .set("z-index",1)
                .setFontSize(20, 1.0);
        svg.bars = svg.p_RDR.createChild("text")
                .setTranslation(-276*0.795, -482*0.5+60)
                .setText("8B")
                .setAlignment("left-center")
                .setColor(1,1,1)
                .set("z-index",1)
                .setFontSize(20, 1.0);
        svg.mod = svg.p_RDR.createChild("text")
                .setTranslation(-276*0.795, -482*0.5+125)
                .setText("")
                .setAlignment("left-center")
                .setColor(1,1,1)
                .set("z-index",1)
                .setFontSize(20, 1.0);
        svg.ant_bottom = svg.p_RDR.createChild("path")
                    .moveTo(-276*0.795,0)
                    .vert(-10)
                    .moveTo(-276*0.795-10,-10)
                    .horiz(20)
                    .setStrokeLineWidth(1)
                    .set("z-index",1)
                    .setColor(0.5,0.5,1);
        svg.distl = svg.p_RDR.createChild("path")
                    .moveTo(-276*0.795+40,-482*0.25)
                    .horiz(20)
                    .moveTo(-276*0.795+40,-482*0.5)
                    .horiz(30)
                    .moveTo(-276*0.795+40,-482*0.75)
                    .horiz(20)
                    .moveTo(-276*0.795*0.5,0)
                    .vert(-20)
                    .moveTo(0,0)
                    .vert(-30)
                    .moveTo(276*0.795*0.5,0)
                    .vert(-20)
                    .setStrokeLineWidth(1)
                    .set("z-index",1)
                    .setColor(0.5,0.5,1);
        #svg.lock = setsize([],svg.maxB);
        #for (var i = 0;i<svg.maxB;i+=1) {
            svg.lock = svg.p_RDR.createChild("group")
            .set("z-index",1);
            svg.lockRot = svg.lock.createChild("path")
                            .moveTo(10,10)
                            .lineTo(0,-10)
                            .lineTo(-10,10)
                            .lineTo(10,10)
                            .moveTo(0,-10)
                            .vert(-10)
                            .setColor(1,1,0)
                            .set("z-index",20)
                            .setStrokeLineWidth(2);
            svg.lockAlt = svg.lock.createChild("text")
                .setTranslation(0, 25)
                .setText("20")
                .setAlignment("center-top")
                .setColor(1,1,1)
                .setFontSize(20, 1.0);
        svg.lockInfo = svg.p_RDR.createChild("text")
                .setTranslation(276*0.795*0.8, -482*0.9)
                .setAlignment("right-center")
                .setColor(1,1,1)
                .set("z-index",1)
                .setFontSize(20, 1.0);
        #}
        #svg.lockF = setsize([],3);
        #for (var i = 0;i<3;i+=1) {
            svg.lockFRot = svg.lock.createChild("path")
                            .moveTo(-10,-10)
                            .vert(20)
                            .horiz(20)
                            .vert(-20)
                            .horiz(-20)
                            .moveTo(0,-10)
                            .vert(-10)
                            .setColor(0.5,1,0.5)
                            .setStrokeLineWidth(2);
        #}
        svg.dlzX      = 276*0.795*0.75;
        svg.dlzY      =-482*0.25;
        svg.dlzWidth  =  20;
        svg.dlzHeight = 482*0.5;
        svg.dlzLW     =   2;
        svg.dlz      = svg.p_RDR.createChild("group")
                        .set("z-index",11)
                        .setTranslation(svg.dlzX, svg.dlzY);
        svg.dlz2     = svg.dlz.createChild("group");
        svg.dlzArrow = svg.dlz.createChild("path")
           .moveTo(0, 0)
           .lineTo( -10, 8)
           .moveTo(0, 0)
           .lineTo( -10, -8)
           .setColor(1,1,1)
           .set("z-index",1)
           .setStrokeLineWidth(svg.dlzLW);
        svg.az1 = svg.p_RDR.createChild("path")
           .moveTo(0, 0)
           .lineTo(0, -482)
           .setColor(0.5,0.5,1)
           .set("z-index",1)
           .setStrokeLineWidth(1);
        svg.az2 = svg.p_RDR.createChild("path")
           .moveTo(0, 0)
           .lineTo(0, -482)
           .setColor(0.5,0.5,1)
           .set("z-index",1)
           .setStrokeLineWidth(1);
        svg.horiz = svg.p_RDR.createChild("path")
           .moveTo(-276*0.795*0.5, -482*0.5)
           .vert(10)
           .moveTo(-276*0.795*0.5, -482*0.5)
           .horiz(276*0.795*0.4)
           .moveTo(276*0.795*0.5, -482*0.5)
           .vert(10)
           .moveTo(276*0.795*0.5, -482*0.5)
           .horiz(-276*0.795*0.4)
           .setCenter(0, -482*0.5)
           .setColor(0.5,0.5,1)
           .set("z-index",11)
           .setStrokeLineWidth(1);
        svg.silent = svg.p_RDR.createChild("text")
           .setTranslation(0, -482*0.25)
           .setAlignment("center-center")
           .setText("SILENT")
           .set("z-index",12)
           .setFontSize(15, 1.0)
           .setColor(1.0,1.0,0.5);
           
        svg.norm = svg.p_RDR.createChild("text")
                .setTranslation(276*0.795*0.0, -482*0.5-225)
                .setText("NORM")
                .setAlignment("center-top")
                .setColor(1,1,1)
                .set("z-index",1)
                .setFontSize(16, 1.0);
        svg.acm = svg.p_RDR.createChild("text")
                .setTranslation(276*0.795*-0.30, -482*0.5-225)
                .setText("ACM")
                .setAlignment("center-top")
                .setColor(1,1,1)
                .hide()
                .setFontSize(16, 1.0);
        svg.swap = svg.p_RDR.createChild("text")
                .setTranslation(276*0.795*0.30, -482*0.5+225)
                .setText("SWAP")
                .setAlignment("center-bottom")
                .setColor(1,1,1)
                .set("z-index",1)
                .setFontSize(13, 1.0); 
        svg.exp = svg.p_RDR.createChild("path")
                    .moveTo(-100,-100)
                    .vert(200)
                    .horiz(200)
                    .vert(-200)
                    .horiz(-200)
                    .setStrokeLineWidth(1.5)
                    .setColor(0.5,0.5,1)
                    .set("z-index",1)
                    .hide();
        
        svg.cursor = svg.p_RDR.createChild("path")
                    .moveTo(-8,-9)
                    .vert(18)
                    .moveTo(8,-9)
                    .vert(18)
                    .setStrokeLineWidth(1.5)
                    .setColor(1,1,1)
                    .set("z-index",1000);
        
        svg.bullseye = svg.p_RDR.createChild("path")
            .moveTo(-25,0)
            .arcSmallCW(25,25, 0,  25*2, 0)
            .arcSmallCW(25,25, 0, -25*2, 0)
            .moveTo(-15,0)
            .arcSmallCW(15,15, 0,  15*2, 0)
            .arcSmallCW(15,15, 0, -15*2, 0)
            .moveTo(-5,0)
            .arcSmallCW(5,5, 0,  5*2, 0)
            .arcSmallCW(5,5, 0, -5*2, 0)
            .setStrokeLineWidth(2)
            .set("z-index",1)
            .setColor(0.5,0.5,1);
        svg.bullOwnRing = svg.p_RDR.createChild("path")
            .moveTo(-15,0)
            .arcSmallCW(15,15, 0,  15*2, 0)
            .arcSmallCW(15,15, 0, -15*2, 0)
            .close()
            .moveTo(0,-18)
            .lineTo(8,-12.5)
            .moveTo(0,-18)
            .lineTo(-8,-12.5)
            .close()
            .setStrokeLineWidth(2)
            .setStrokeLineCap("round")
            .setTranslation(-190, -50)
            .set("z-index",1)
            .setColor(0.5,0.5,1);
        svg.bullOwnDist = svg.p_RDR.createChild("text")
                .setAlignment("center-center")
                .setColor(0.5,0.5,1)
                .setTranslation(-190, -50)
                .setText("12")
                .set("z-index",1)
                .setFontSize(18, 1.0);            
        svg.bullOwnDir = svg.p_RDR.createChild("text")
                .setAlignment("center-top")
                .setColor(0.5,0.5,1)
                .setTranslation(-190, -30)
                .setText("270")
                .set("z-index",1)
                .setFontSize(18, 1.0);
        svg.cursorLoc = svg.p_RDR.createChild("text")
                .setAlignment("left-bottom")
                .setColor(1,1,1)
                .setTranslation(-200, -75)
                .setText("12")
                .set("z-index",1)
                .setFontSize(18, 1.0);
        
        #svg.gmPicG = svg.p_RDR.createChild("group");
        #if (index == 0) {
            svg.gmPic = svg.p_RDR.createChild("image")
                .set("src", "Aircraft/f16/Nasal/MFD/gm.png")
                .setTranslation(-192,-384)
                .setScale(3,3)
                .set("z-index",0)
                .hide();
        #} else {
        #    svg.gmPic = svg.p_RDR.createChild("image")
        #        .set("src", "Aircraft/f16/Nasal/MFD/gm2.png")
        #        .setTranslation(-128,-286)
        #        .setScale(2,2)
        #        .set("z-index",5)
        #        .hide();
        #}
    },

    addRadar: func {
        var svg = {getElementById: func (id) {return me[id]},};
        me.setupRadar(svg, me.model_index);
        me.PFD.addRadarPage = func(svg, title, layer_id) {   
            var np = PFD_Page.new(svg, title, layer_id, me);
            append(me.pages, np);
            me.page_index[layer_id] = np;
            np.setVisible(0);
            return np;
        };
        me.p_RDR = me.PFD.addRadarPage(svg, "Radar", "p_RDR");
        me.p_RDR.root = svg;
        me.p_RDR.wdt = 552*0.795;
        me.p_RDR.fwd = 0;
        me.p_RDR.plc = 0;
        me.p_RDR.ppp = me.PFD;
        me.p_RDR.my = me;
        me.p_RDR.gmLine = 10;
        me.p_RDR.elapsed = 0;
        me.p_RDR.pressEXP = 0;
        me.p_RDR.gmMin = 0;
        me.p_RDR.gmMax = 1500;
        me.p_RDR.gmMintemp = 5000;
        me.p_RDR.gmMaxtemp = 300;
        me.p_RDR.notifyButton = func (eventi) {
            if (eventi != nil) {
                if (eventi == 0) {
                    awg_9.range_control(1);
                } elsif (eventi == 1) {
                    awg_9.range_control(-1);
                } elsif (eventi == 17) {
                    me.ppp.selectPage(me.my.p_SMS);
                } elsif (eventi == 15) {
                    me.ppp.selectPage(me.my.p_WPN);
                #} elsif (eventi == 18) {
                #    me.ppp.selectPage(me.my.pjitds_1);
                } elsif (eventi == 16) {
                    me.ppp.selectPage(me.my.p_HSD);
                } elsif (eventi == 12) {
                    me.pressEXP = 1;
                } elsif (eventi == 2) {
                    var az = getprop("instrumentation/radar/az-field");
                    if(az==120)
                        az = 15;
                    elsif(az==15)
                        az = 30;
                    elsif(az==30)
                        az = 60;
                    else
                        az = 120;
                    setprop("instrumentation/radar/az-field", az);
                } elsif (eventi == 3) {
                    var ho = getprop("instrumentation/radar/ho-field");
                    if(ho==120)
                        ho = 15;
                    elsif(ho==15 or ho == 20)
                        ho = 30;
                    elsif(ho==30)
                        ho = 60;
                    else
                        ho = 120;
                    setprop("instrumentation/radar/ho-field", ho);
                } elsif (eventi == 4) {
                    setprop("instrumentation/radar/mode-switch", 1);
                } elsif (eventi == 18) {
                    swap();
                }
            }

# Menu Id's
#  CRM
#   10  11  12  13  14
# 0                    5            
# 1                    6            
# 2                    7            
# 3                    8            
# 4                    9            
#   15  16  17  18  19
#  VSD HSD SMS SIT
        };
        me.p_RDR.update = func (noti) {
            me.modeSw = getprop("instrumentation/radar/mode-switch");
            if (me.modeSw == 1 and num(split(".", getprop("sim/version/flightgear"))[0]) >= 2020) {
                rdrMode = !rdrMode;
            }
            if (rdrMode) {
                me.root.mod.setText("GM");
                me.root.gmPic.show();
            } else {
                me.root.mod.setText("");
                me.root.gmPic.hide();
            }
            setprop("instrumentation/radar/mode-switch", 0);
            me.bullOn = getprop("f16/avionics/bulls-eye-defined");
            if (me.bullOn) {
                me.bullLat = getprop("f16/avionics/bulls-eye-lat");
                me.bullLon = getprop("f16/avionics/bulls-eye-lon");
                me.bullCoord = geo.Coord.new().set_latlon(me.bullLat,me.bullLon);
                me.ownCoord = geo.aircraft_position();
                me.bullDirToMe = me.bullCoord.course_to(me.ownCoord);
                me.meToBull = ((me.bullDirToMe+180)-noti.heading)*D2R;
                me.root.bullOwnRing.setRotation(me.meToBull);
                me.bullDistToMe = me.bullCoord.distance_to(me.ownCoord)*M2NM;
                me.distPixels = me.bullDistToMe*(482/awg_9.range_radar2);
                me.bullPos = [me.wdt*0.5*geo.normdeg180(me.meToBull*R2D)/60,-me.distPixels];
                
                me.bullDirToMe = sprintf("%03d", me.bullDirToMe);
                if (me.bullDistToMe > 100) {
                    me.bullDistToMe = "  ";
                } else {
                    me.bullDistToMe = sprintf("%02d", me.bullDistToMe);
                }
                me.root.bullOwnDir.setText(me.bullDirToMe);
                me.root.bullOwnDist.setText(me.bullDistToMe);
            }
            me.root.bullOwnRing.setVisible(me.bullOn);
            me.root.bullOwnDir.setVisible(me.bullOn);
            me.root.bullOwnDist.setVisible(me.bullOn);
            
            
            if (me.pressEXP) {
                me.pressEXP = 0;
                exp = !exp;
            }
            if (exp) {
                me.root.norm.setText("EXP");
                me.root.exp.setTranslation(cursor_pos);                
            } else {
                me.root.norm.setText("NORM");
            }
            me.root.exp.setVisible(exp);
            me.root.acm.setVisible(getprop("f16/avionics/dgft"));
            me.root.horiz.setRotation(-getprop("orientation/roll-deg")*D2R);
            me.time = getprop("sim/time/elapsed-sec");
            me.az = getprop("instrumentation/radar/az-field");
            if (getprop("sim/multiplay/generic/int[2]")!=1) {
                var plc = me.time*0.5/(me.az/120)-int(me.time*0.5/(me.az/120));
                if (plc<me.plc) {
                    me.fwd = !me.fwd;
                }
                me.plc = plc;
                if (!rdrMode) {
                    me.root.ant_bottom.setTranslation(me.wdt*0.5-(me.az/120)*me.wdt*0.5+(me.az/120)*me.wdt*math.abs(me.fwd-me.plc),0);
                } else {
                    me.root.ant_bottom.setTranslation(-192+me.gmLine*3+276*0.795,0);
                }
                me.root.silent.hide();
            } elsif (getprop("/f16/avionics/power-fcr-bit") == 2) {
                me.root.silent.setText("SILENT");
                me.root.silent.show();
            } elsif (getprop("/f16/avionics/power-fcr-bit") == 1) {
                me.fcrBITsecs = (1.0-getprop("/f16/avionics/power-fcr-warm"))*120;
                var mins = int(me.fcrBITsecs/60);
                var secs = me.fcrBITsecs-mins*60;
                me.root.silent.setText(sprintf("  BIT  %1d:%02d  ", mins, secs));
                me.root.silent.show();
            } elsif (getprop("/f16/avionics/power-fcr-bit") == 0) {
                me.root.silent.setText("  OFF  ");
                me.root.silent.show();
            }
            if (uv != nil and me.root.index == uv[2]) {
                if (systime()-uv[3] < 0.5) {
                    # the time check is to prevent click on other pages to carry over to CRM when that is selected.
                    cursor_destination = uv;
                }
                uv = nil;
            }
            me.exp_modi = exp?0.25:1;
            me.slew_x = getprop("controls/displays/cursor-slew-x")*me.exp_modi;
            me.slew_y = -getprop("controls/displays/cursor-slew-y")*me.exp_modi;
            
            #me.dt = math.min(noti.ElapsedSeconds - me.elapsed, 0.05);
            me.dt = noti.ElapsedSeconds - me.elapsed;
            
            if ((me.slew_x != 0 or me.slew_y != 0 or slew_c != 0) and (cursor_lock == -1 or cursor_lock == me.root.index) and getprop("/sim/current-view/name") != "TGP") {
                cursor_destination = nil;
                cursor_pos[0] += me.slew_x*125*me.dt;
                cursor_pos[1] -= me.slew_y*125*me.dt;
                cursor_pos[0] = math.clamp(cursor_pos[0], -552*0.5*0.795, 552*0.5*0.795);
                cursor_pos[1] = math.clamp(cursor_pos[1], -482, 0);
                cursor_click = (slew_c and !me.slew_c_last)?me.root.index:-1;
                cursor_lock = me.root.index;
            } elsif (cursor_lock == me.root.index or (me.slew_x == 0 or me.slew_y == 0 or slew_c == 0)) {
                cursor_lock = -1;
            }
            me.slew_c_last = slew_c;
            slew_c = 0;
            if (cursor_destination != nil and cursor_destination[2] == me.root.index) {
                me.slew = 100*me.dt;
                if (cursor_destination[0] > cursor_pos[0]) {
                    cursor_pos[0] += me.slew;
                    if (cursor_destination[0] < cursor_pos[0]) {
                        cursor_pos[0] = cursor_destination[0]
                    }
                } elsif (cursor_destination[0] < cursor_pos[0]) {
                    cursor_pos[0] -= me.slew;
                    if (cursor_destination[0] > cursor_pos[0]) {
                        cursor_pos[0] = cursor_destination[0]
                    }
                }
                if (cursor_destination[1] > cursor_pos[1]) {
                    cursor_pos[1] += me.slew;
                    if (cursor_destination[1] < cursor_pos[1]) {
                        cursor_pos[1] = cursor_destination[1]
                    }
                } elsif (cursor_destination[1] < cursor_pos[1]) {
                    cursor_pos[1] -= me.slew;
                    if (cursor_destination[1] > cursor_pos[1]) {
                        cursor_pos[1] = cursor_destination[1]
                    }
                }
                cursor_lock = me.root.index;
                if (cursor_destination[0] == cursor_pos[0] and cursor_destination[1] == cursor_pos[1]) {
                    cursor_click = me.root.index;
                }
            }
            me.elapsed = noti.ElapsedSeconds;
            me.root.cursor.setTranslation(cursor_pos);
            if (me.bullOn) {
                me.cursorDev   = cursor_pos[0]*60/(me.wdt*0.5);
                me.cursorDist  = -NM2M*cursor_pos[1]/(482/awg_9.range_radar2);
                me.ownCoord.apply_course_distance(noti.heading+me.cursorDev, me.cursorDist);
                me.cursorBullDist = me.ownCoord.distance_to(me.bullCoord);
                me.cursorBullCrs  = me.bullCoord.course_to(me.ownCoord);
                me.root.cursorLoc.setText(sprintf("%03d %03d",me.cursorBullCrs, me.cursorBullDist*M2NM));
            }
            me.root.cursorLoc.setVisible(me.bullOn);
            
            if (getprop("sim/multiplay/generic/int[2]")!=1 and rdrMode) {
                # GM mode
                me.linesFrame = 1;
                while (me.linesFrame > 0) {
                    me.gmLine += 1;
                    if (me.gmLine > 127) {
                        me.gmLine = 0;
                        me.gmMin = me.gmMintemp;
                        me.gmMax = me.gmMaxtemp;
                        if (me.gmMin == me.gmMax) {
                            me.gmMax += 1;
                        }
                        #printf("GM radar scanning from from %d to %d ft", me.gmMin*M2FT, me.gmMax*M2FT);
                        me.gmMintemp = 5000;
                        me.gmMaxtemp = 300;
                    }
                    me.gmCoord = geo.aircraft_position();
                    me.gmMe = geo.aircraft_position();
                    me.gmHead = getprop("orientation/heading-deg");
                    me.gmCoord.apply_course_distance(me.gmHead-90, NM2M*getprop("instrumentation/radar/radar2-range")*0.5);
                    me.gmCoord.apply_course_distance(me.gmHead+90, NM2M*getprop("instrumentation/radar/radar2-range")*me.gmLine/127);
                    for(me.gmi = 0; me.gmi < 128; me.gmi += 1) {
                        
                        if (math.abs(geo.normdeg180(me.gmMe.course_to(me.gmCoord)-me.gmHead)) < 60) {
                            me.gmEle = geo.elevation(me.gmCoord.lat(),me.gmCoord.lon());
                            if (me.gmEle == nil) {
                                me.gmEle = 0;
                                #print("nil");
                            }
                            if (me.gmEle > me.gmMaxtemp) {
                                me.gmMaxtemp = me.gmEle;
                            }
                            if (me.gmEle < me.gmMintemp) {
                                me.gmMintemp = me.gmEle;
                            }
                            me.gmColor = math.clamp((me.gmEle-me.gmMin)/(me.gmMax-me.gmMin),0,1);
                            #printf("GM %03d,%03d: %3d %.5f",me.gmLine,me.gmi,me.gmColor*127,me.gmColor);
                            #if (me.gmLine != 0)
                            #print(me.gmLine);
                            #me.root.gmPic.set("src", "Aircraft/f16/Nasal/MFD/gm.png");
                            #me.root.gmPic.setPixel(int(rand()*127), int(rand()*127), [me.gmColor,me.gmColor,me.gmColor,1]);
                            me.root.gmPic.setPixel(me.gmLine, me.gmi, [me.gmColor,me.gmColor,me.gmColor,1]);
                            
                            #me.root.gmPic.update();
                            #f16.f16_mfd.MFDl.p_RDR.root.gmPic.setPixel(50, 50, [1,0,0,1]);
                            #f16.f16_mfd.MFDl.p_RDR.root.gmPicG.update();
                        }
                        me.gmCoord.apply_course_distance(me.gmHead, NM2M*getprop("instrumentation/radar/radar2-range")/128);
                    }
                    me.linesFrame -= 1;
                }
                #me.root.gmPic.update();
                me.root.gmPic.dirtyPixels();
            }
            
            me.root.az1.setVisible(!rdrMode);
            me.root.az2.setVisible(!rdrMode);
            me.root.bars.setVisible(!rdrMode);
            me.root.az.setVisible(!rdrMode);
            if (noti.FrameCount != 1 and noti.FrameCount != 3)
                return;
            me.root.rang.setText(sprintf("%d",getprop("instrumentation/radar/radar2-range")));
            if (rdrMode) {
                me.root.dlz.hide();
                # hide radar echoes here also
                return;
            }
            me.i=0;
            
            me.ho = getprop("instrumentation/radar/ho-field");
            
            me.azt = "";
            me.hot = "";
            if (me.az==15) {
                me.azt = "A1";
            } elsif (me.az==30) {
                me.azt = "A2";
            } elsif (me.az==60) {
                me.azt = "A3";
            } else {
                me.azt = "A4";
            }
            me.root.az.setText(me.azt);
            if (me.ho==15) {
                me.hot = "2B";
            } elsif (me.ho==20) {
                me.hot = "3B";#DGFT mode
            } elsif (me.ho==30) {
                me.hot = "4B";
            } elsif (me.ho==60) {
                me.hot = "6B";
            } else {
                me.hot = "8B";
            }
            me.root.bars.setText(me.hot);
            me.root.az1.setTranslation(-(me.az/120)*me.wdt*0.5,0);
            me.root.az2.setTranslation((me.az/120)*me.wdt*0.5,0);
            me.root.lock.hide();
            me.root.lockInfo.hide();
            
            if (me.bullOn) {
                me.close = math.abs(cursor_pos[0] - me.bullPos[0]) < 25 and math.abs(cursor_pos[1] - me.bullPos[1]) < 25;
                if (me.close and exp) {
                    me.bullPos[0] = cursor_pos[0]+(me.bullPos[0] - cursor_pos[0])*4;
                    me.bullPos[1] = cursor_pos[1]+(me.bullPos[1] - cursor_pos[1])*4;
                } elsif (exp and math.abs(cursor_pos[0] - me.bullPos[0]) < 100 and math.abs(cursor_pos[1] - me.bullPos[1]) < 100) {
                    me.bullOn = 0;
                }
            }
            me.root.bullseye.setVisible(me.bullOn);
            if (me.bullOn) {
                me.root.bullseye.setTranslation(me.bullPos);
            }
            
            me.desig_new = nil;
            foreach(contact; awg_9.tgts_list) {
                if (contact.get_display() == 0) {
                    continue;
                }
                me.distPixels = contact.get_range()*(482/awg_9.range_radar2);
                if (me.distPixels > 485) {
                    continue;
                }
                me.cs = contact.get_Callsign();
                me.blue = getprop("f16/avionics/power-dl") and (me.cs == getprop("link16/wingman-1") or me.cs == getprop("link16/wingman-2") or me.cs == getprop("link16/wingman-3") or me.cs == getprop("link16/wingman-4") or me.cs == getprop("link16/wingman-5") or me.cs == getprop("link16/wingman-6") or me.cs == getprop("link16/wingman-7") or me.cs == getprop("link16/wingman-8") or me.cs == getprop("link16/wingman-9") or me.cs == getprop("link16/wingman-10") or me.cs == getprop("link16/wingman-11") or me.cs == getprop("link16/wingman-12"));
                me.iff = contact.getIff();
                me.echoPos = [me.wdt*0.5*geo.normdeg180(contact.get_relative_bearing())/60,-me.distPixels];
                me.close = math.abs(cursor_pos[0] - me.echoPos[0]) < 25 and math.abs(cursor_pos[1] - me.echoPos[1]) < 25;
                if (me.close and exp) {
                    me.echoPos[0] = cursor_pos[0]+(me.echoPos[0] - cursor_pos[0])*4;
                    me.echoPos[1] = cursor_pos[1]+(me.echoPos[1] - cursor_pos[1])*4;
                } elsif (exp and math.abs(cursor_pos[0] - me.echoPos[0]) < 100 and math.abs(cursor_pos[1] - me.echoPos[1]) < 100) {
                    continue;
                }
                if (me.i <= (me.root.maxB-1)) {
                    if (me.iff) {
                        me.root.iff[me.i].setTranslation(me.echoPos);
                        me.root.iff[me.i].show();
                        me.root.iff[me.i].update();
                        me.root.blep[me.i].hide();
                    } else {
                        me.root.blep[me.i].setColor(me.blue?[0.5,1,0.5]:[1,1,1]);
                        me.root.blep[me.i].setTranslation(me.echoPos);
                        me.root.blep[me.i].show();
                        me.root.blep[me.i].update();
                        me.root.iff[me.i].hide();
                        if (cursor_click == me.root.index) {
                            if (math.abs(cursor_pos[0] - me.echoPos[0]) < 10 and math.abs(cursor_pos[1] - me.echoPos[1]) < 11) {
                                me.desig_new = contact;
                            }
                        }
                    }
                }
                
                
                
                me.desig = contact==awg_9.active_u or (awg_9.active_u != nil and contact.get_Callsign() == awg_9.active_u.get_Callsign() and contact.ModelType==awg_9.active_u.ModelType);
                if (me.desig and !me.iff) {
                    me.rot = contact.get_heading();
                    if (me.rot == nil) {
                        #can happen in transition between TWS to RWS
                        #me.root.lock.hide();
                    } else {
                        me.lockAlt = sprintf("%02d", contact.get_altitude()*0.001);
                        me.lockInfo = sprintf("%4d   %+4d", contact.get_Speed(), contact.get_closure_rate());
                        me.root.lockAlt.setText(me.lockAlt);
                        me.root.lockInfo.setText(me.lockInfo);
                        me.root.lockInfo.show();
                        me.rot = me.rot-getprop("orientation/heading-deg")-geo.normdeg180(contact.get_relative_bearing());
                        me.root.lock.setTranslation(me.echoPos);
                        #if (cursor_lock == -1) {
                            #cursor_pos = [276*0.795*geo.normdeg180(contact.get_relative_bearing())/60,-me.distPixels];
                        #}
                        if (me.blue) {
                            me.root.lockFRot.setRotation(me.rot*D2R);
                            me.root.lockFRot.show();
                            me.root.lockRot.hide();
                            me.root.lockFRot.update();
                        } else {
                            me.root.lockRot.setRotation(me.rot*D2R);
                            me.root.lockRot.show();
                            me.root.lockFRot.hide();
                            me.root.lockRot.update();
                        }
                        me.root.lock.show();
                        me.root.lock.update();
                        if (me.i <= (me.root.maxB-1)) {
                            me.root.blep[me.i].hide();
                        }
                    }
                }
                me.i += 1;
                #if (me.i > (me.root.maxB-1)) {
                    #break;
                #}
            }
            if (cursor_click == me.root.index) {
                awg_9.designate(me.desig_new);
                cursor_destination = nil;
                cursor_click = -1;
            }
            for (;me.i<me.root.maxB;me.i+=1) {
                me.root.blep[me.i].hide();
                me.root.iff[me.i].hide();
            }
            me.root.dlzArray = pylons.getDLZ();
            #me.dlzArray =[10,8,6,2,9];#test
            if (me.root.dlzArray == nil or size(me.root.dlzArray) == 0) {
                    me.root.dlz.hide();
            } else {
                #printf("%d %d %d %d %d",me.root.dlzArray[0],me.root.dlzArray[1],me.root.dlzArray[2],me.root.dlzArray[3],me.root.dlzArray[4]);
                me.root.dlz2.removeAllChildren();
                me.root.dlzArrow.setTranslation(0,-me.root.dlzArray[4]/me.root.dlzArray[0]*me.root.dlzHeight);
                me.root.dlzGeom = me.root.dlz2.createChild("path")
                        .moveTo(0, -me.root.dlzArray[3]/me.root.dlzArray[0]*me.root.dlzHeight)
                        .lineTo(0, -me.root.dlzArray[2]/me.root.dlzArray[0]*me.root.dlzHeight)
                        .lineTo(me.root.dlzWidth, -me.root.dlzArray[2]/me.root.dlzArray[0]*me.root.dlzHeight)
                        .lineTo(me.root.dlzWidth, -me.root.dlzArray[3]/me.root.dlzArray[0]*me.root.dlzHeight)
                        .lineTo(0, -me.root.dlzArray[3]/me.root.dlzArray[0]*me.root.dlzHeight)
                        .lineTo(0, -me.root.dlzArray[1]/me.root.dlzArray[0]*me.root.dlzHeight)
                        .lineTo(me.root.dlzWidth, -me.root.dlzArray[1]/me.root.dlzArray[0]*me.root.dlzHeight)
                        .moveTo(0, -me.root.dlzHeight)
                        .lineTo(me.root.dlzWidth, -me.root.dlzHeight-3)
                        .lineTo(me.root.dlzWidth, -me.root.dlzHeight+3)
                        .lineTo(0, -me.root.dlzHeight)
                        .setStrokeLineWidth(me.root.dlzLW)
                        .setColor(1,1,1);
                me.root.dlz2.update();
                me.root.dlz.show();
            }
        };
    },

    setupSMS: func (svg) {
        svg.p_SMS = me.canvas.createGroup()
                .setTranslation(276*0.795,482)
                .set("font","LiberationFonts/LiberationMono-Regular.ttf");#552,482 , 0.795 is for UV map

        svg.cat = svg.p_SMS.createChild("text")
                .setTranslation(0, -482*0.5+100)
                .setText("CAT I")
                .setAlignment("center-center")
                .setColor(1,1,1)
                .setFontSize(20, 1.0);
        svg.p6 = svg.p_SMS.createChild("text")
                .setTranslation(276*0.795*0.55, -482*0.5-135)
                .setText("--------")
                .setAlignment("right-center")
                .setColor(1,1,1)
                .setFontSize(20, 1.0);
        svg.p7 = svg.p_SMS.createChild("text")
                .setTranslation(276*0.795*0.7, -482*0.5-70)
                .setText("--------")
                .setAlignment("right-center")
                .setColor(1,1,1)
                .setFontSize(20, 1.0);
        svg.p8 = svg.p_SMS.createChild("text")
                .setTranslation(276*0.795*0.85, -482*0.5-5)
                .setText("--------")
                .setAlignment("right-center")
                .setColor(1,1,1)
                .setFontSize(20, 1.0);
        svg.p9 = svg.p_SMS.createChild("text")
                .setTranslation(276*0.795, -482*0.5+60)
                .setText("--------")
                .setAlignment("right-center")
                .setColor(1,1,1)
                .setFontSize(20, 1.0);
        svg.p5 = svg.p_SMS.createChild("text")
                .setTranslation(0.0, -482*0.5-200)
                .setText("--------")
                .setAlignment("center-center")
                .setColor(1,1,1)
                .setFontSize(20, 1.0);
        svg.p4 = svg.p_SMS.createChild("text")
                .setTranslation(-276*0.795*0.55, -482*0.5-135)
                .setText("--------")
                .setAlignment("left-center")
                .setColor(1,1,1)
                .setFontSize(20, 1.0);
        svg.p3 = svg.p_SMS.createChild("text")
                .setTranslation(-276*0.795*0.7, -482*0.5-70)
                .setText("--------")
                .setAlignment("left-center")
                .setColor(1,1,1)
                .setFontSize(20, 1.0);
        svg.p2 = svg.p_SMS.createChild("text")
                .setTranslation(-276*0.795*0.85, -482*0.5-5)
                .setText("--------")
                .setAlignment("left-center")
                .setColor(1,1,1)
                .setFontSize(20, 1.0);
        svg.p1 = svg.p_SMS.createChild("text")
                .setTranslation(-276*0.795, -482*0.5+60)
                .setText("--------")
                .setAlignment("left-center")
                .setColor(1,1,1)
                .setFontSize(20, 1.0);
        
        #svg.drop = svg.p_SMS.createChild("text")
        #        .setTranslation(276*0.795*0.65, -482*0.5-225)
        #        .setText("CCRP")
        #        .setAlignment("center-top")
        #        .setColor(1,1,1)
        #        .setFontSize(16, 1.0);        
        
        svg.p1f = svg.p_SMS.createChild("path")
           .moveTo(-276*0.795, -482*0.5+75)
           .vert(-30)
           .horiz(130)
           .vert(30)
           .horiz(-130)
           .setColor(1,1,1)
           .setStrokeLineWidth(1)
           .hide();
        svg.p2f = svg.p_SMS.createChild("path")
           .moveTo(-276*0.795*0.85, -482*0.5+10)
           .vert(-30)
           .horiz(130)
           .vert(30)
           .horiz(-130)
           .setColor(1,1,1)
           .setStrokeLineWidth(1)
           .hide();
        svg.p3f = svg.p_SMS.createChild("path")
           .moveTo(-276*0.795*0.7, -482*0.5-55)
           .vert(-30)
           .horiz(130)
           .vert(30)
           .horiz(-130)
           .setColor(1,1,1)
           .setStrokeLineWidth(1)
           .hide();
        svg.p4f = svg.p_SMS.createChild("path")
           .moveTo(-276*0.795*0.55, -482*0.5-120)
           .vert(-30)
           .horiz(130)
           .vert(30)
           .horiz(-130)
           .setColor(1,1,1)
           .setStrokeLineWidth(1)
           .hide();
        svg.p5f = svg.p_SMS.createChild("path")
           .moveTo(-75, -482*0.5-185)
           .vert(-30)
           .horiz(130)
           .vert(30)
           .horiz(-130)
           .setColor(1,1,1)
           .setStrokeLineWidth(1)
           .hide();
        svg.p6f = svg.p_SMS.createChild("path")
           .moveTo(276*0.795*0.55, -482*0.5-120)
           .vert(-30)
           .horiz(-130)
           .vert(30)
           .horiz(130)
           .setColor(1,1,1)
           .setStrokeLineWidth(1)
           .hide();
        svg.p7f = svg.p_SMS.createChild("path")
           .moveTo(276*0.795*0.7, -482*0.5-55)
           .vert(-30)
           .horiz(-130)
           .vert(30)
           .horiz(130)
           .setColor(1,1,1)
           .setStrokeLineWidth(1)
           .hide();
        svg.p8f = svg.p_SMS.createChild("path")
           .moveTo(276*0.795*0.85, -482*0.5+10)
           .vert(-30)
           .horiz(-130)
           .vert(30)
           .horiz(130)
           .setColor(1,1,1)
           .setStrokeLineWidth(1)
           .hide();
        svg.p9f = svg.p_SMS.createChild("path")
           .moveTo(276*0.795, -482*0.5+75)
           .vert(-30)
           .horiz(-130)
           .vert(30)
           .horiz(130)
           .setColor(1,1,1)
           .setStrokeLineWidth(1)
           .hide();
        svg.jett = svg.p_SMS.createChild("text")
                .setTranslation(276*0.795, -482*0.5+125)
                .setText("J-S")
                .setAlignment("right-center")
                .setColor(1,1,1)
                .setFontSize(20, 1.0);
        svg.swap = svg.p_SMS.createChild("text")
                .setTranslation(276*0.795*0.30, -482*0.5+225)
                .setText("SWAP")
                .setAlignment("center-bottom")
                .setColor(1,1,1)
                .set("z-index",1)
                .setFontSize(13, 1.0);
    },

    addSMS: func {
        var svg = {getElementById: func (id) {return me[id]},};
        me.setupSMS(svg);
        me.PFD.addSMSPage = func(svg, title, layer_id) {   
            var np = PFD_Page.new(svg, title, layer_id, me);
            append(me.pages, np);
            me.page_index[layer_id] = np;
            np.setVisible(0);
            return np;
        };
        me.p_SMS = me.PFD.addSMSPage(svg, "SMS", "p_SMS");
        me.p_SMS.root = svg;
        me.p_SMS.wdt = 552*0.795;
        me.p_SMS.fwd = 0;
        me.p_SMS.plc = 0;
        me.p_SMS.ppp = me.PFD;
        me.p_SMS.my = me;
        me.p_SMS.notifyButton = func (eventi) {
            if (eventi != nil) {
                if (eventi == 10) {
                    me.ppp.selectPage(me.my.p_RDR);
                } elsif (eventi == 0) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    pylons.fcs.selectPylon(3);
                } elsif (eventi == 1) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    pylons.fcs.selectPylon(2);
                } elsif (eventi == 2) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    pylons.fcs.selectPylon(1);
                } elsif (eventi == 3) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    pylons.fcs.selectPylon(0);
                } elsif (eventi == 5) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    pylons.fcs.selectPylon(5);
                } elsif (eventi == 6) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    pylons.fcs.selectPylon(6);
                } elsif (eventi == 7) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    pylons.fcs.selectPylon(7);
                } elsif (eventi == 8) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    pylons.fcs.selectPylon(8);
                } elsif (eventi == 9) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    pylons.fcs.jettisonSelectedPylonContent();
                } elsif (eventi == 12) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    pylons.fcs.selectPylon(4);
                } elsif (eventi == 15) {
                    me.ppp.selectPage(me.my.p_WPN);
                #} elsif (eventi == 18) {
                #    me.ppp.selectPage(me.my.pjitds_1);
                } elsif (eventi == 14) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    pylons.fcs.setDropMode(!pylons.fcs.getDropMode());
                } elsif (eventi == 16) {
                    me.ppp.selectPage(me.my.p_HSD);
                } elsif (eventi == 18) {
                    swap();
                }
# Menu Id's
#  CRM
#   10  11  12  13  14
# 0                    5            
# 1                    6            
# 2                    7            
# 3                    8            
# 4                    9            
#   15  16  17  18  19
#  VSD HSD SMS SIT
            }
        };
        me.p_SMS.update = func (noti) {
            if (noti.FrameCount != 3)
                return;
            if (getprop("sim/variant-id") == 0) {
                return;
            }
            me.cat = pylons.fcs.getCategory();
            me.root.cat.setText(sprintf("CAT %s", me.cat==1?"I":(me.cat==2?"II":"III")));

            var sel = pylons.fcs.getSelectedPylonNumber();
            me.root.p1f.setVisible(sel==0);
            me.root.p2f.setVisible(sel==1);
            me.root.p3f.setVisible(sel==2);
            me.root.p4f.setVisible(sel==3);
            me.root.p5f.setVisible(sel==4);
            me.root.p6f.setVisible(sel==5);
            me.root.p7f.setVisible(sel==6);
            me.root.p8f.setVisible(sel==7);
            me.root.p9f.setVisible(sel==8);

            #var pT = "CCRP";
            #if (pylons.fcs != nil) {
            #    var nm = pylons.fcs.getDropMode();
            #    if (nm == 1) pT = "CCIP";
            #}
            #me.root.drop.setText(pT);

            var pT = "--------";
            if (pylons.pylon1 != nil) {
                var nm = pylons.pylon1.getCurrentShortName();
                if (nm != nil) pT = nm;
            }
            me.root.p1.setText(pT);

            pT = "--------";
            if (pylons.pylon2 != nil) {
                var nm = pylons.pylon2.getCurrentShortName();
                if (nm != nil) pT = nm;
            }
            me.root.p2.setText(pT);

            pT = "--------";
            if (pylons.pylon3 != nil) {
                var nm = pylons.pylon3.getCurrentShortName();
                if (nm != nil) pT = nm;
            }
            me.root.p3.setText(pT);

            pT = "--------";
            if (pylons.pylon4 != nil) {
                var nm = pylons.pylon4.getCurrentShortName();
                if (nm != nil) pT = nm;
            }
            me.root.p4.setText(pT);

            pT = "--------";
            if (pylons.pylon5 != nil) {
                var nm = pylons.pylon5.getCurrentShortName();
                if (nm != nil) pT = nm;
            }
            me.root.p5.setText(pT);

            pT = "--------";
            if (pylons.pylon6 != nil) {
                var nm = pylons.pylon6.getCurrentShortName();
                if (nm != nil) pT = nm;
            }
            me.root.p6.setText(pT);

            pT = "--------";
            if (pylons.pylon7 != nil) {
                var nm = pylons.pylon7.getCurrentShortName();
                if (nm != nil) pT = nm;
            }
            me.root.p7.setText(pT);

            pT = "--------";
            if (pylons.pylon8 != nil) {
                var nm = pylons.pylon8.getCurrentShortName();
                if (nm != nil) pT = nm;
            }
            me.root.p8.setText(pT);

            pT = "--------";
            if (pylons.pylon9 != nil) {
                var nm = pylons.pylon9.getCurrentShortName();
                if (nm != nil) pT = nm;
            }
            me.root.p9.setText(pT);
        };
    },
    
    setupWPN: func (svg) {
        svg.p_WPN = me.canvas.createGroup()
                .setTranslation(276*0.795,482)
                .set("font","LiberationFonts/LiberationMono-Regular.ttf");#552,482 , 0.795 is for UV map

        
        
        svg.drop = svg.p_WPN.createChild("text")
                .setTranslation(276*0.795*-0.30, -482*0.5-225)
                .setText("")
                .setAlignment("center-top")
                .setColor(1,1,1)
                .setFontSize(16, 1.0);    
                
        svg.pre = svg.p_WPN.createChild("text")
                .setTranslation(276*0.795*0.0, -482*0.5-225)
                .setText("")
                .setAlignment("center-top")
                .setColor(1,1,1)
                .setFontSize(16, 1.0);
                
        svg.eegs = svg.p_WPN.createChild("text")
                .setTranslation(276*0.795*0.325, -482*0.5-225)
                .setText("")
                .setAlignment("center-top")
                .setColor(1,1,1)
                .setFontSize(16, 1.0);       
        
        svg.weap = svg.p_WPN.createChild("text")
                .setTranslation(276*0.795, -482*0.5-135)
                .setText("")
                .setAlignment("right-center")
                .setColor(1,1,1)
                .setFontSize(20, 1.0);
                
        svg.ready = svg.p_WPN.createChild("text")
                .setTranslation(276*0.795, -482*0.5+0)
                .setText("")
                .setAlignment("right-center")
                .setColor(1,1,1)
                .setFontSize(20, 1.0);
                
        svg.ripple = svg.p_WPN.createChild("text")
                .setTranslation(276*0.795, -482*0.5+70)
                .setText("")
                .setAlignment("right-center")
                .setColor(1,1,1)
                .setFontSize(20, 1.0);
        
        svg.cool = svg.p_WPN.createChild("text")
                .setTranslation(276*0.795, -482*0.5+140)
                .setText("")
                .setAlignment("right-center")
                .setColor(1,1,1)
                .setFontSize(20, 1.0);
                
        svg.rangUpA = svg.p_WPN.createChild("path")
                    .moveTo(-276*0.795,-482*0.5-105-27.5)
                    .horiz(30)
                    .lineTo(-276*0.795+15,-482*0.5-105-27.5-15)
                    .lineTo(-276*0.795,-482*0.5-105-27.5)
                    .setStrokeLineWidth(2)
                    .hide()
                    .setColor(1,1,1);
        svg.rangA = svg.p_WPN.createChild("text")
                .setTranslation(-276*0.795, -482*0.5-105)
                .setAlignment("left-center")
                .setColor(1,1,1)
                .hide()
                .setFontSize(20, 1.0);
        svg.rangDownA = svg.p_WPN.createChild("path")
                    .moveTo(-276*0.795,-482*0.5-105+27.5)
                    .horiz(30)
                    .lineTo(-276*0.795+15,-482*0.5-105+27.5+15)
                    .lineTo(-276*0.795,-482*0.5-105+27.5)
                    .setStrokeLineWidth(2)
                    .hide()
                    .setColor(1,1,1);
                    
        svg.distUpA = svg.p_WPN.createChild("path")
                    .moveTo(-276*0.795,-482*0.5-105-27.5)
                    .horiz(30)
                    .lineTo(-276*0.795+15,-482*0.5-105-27.5-15)
                    .lineTo(-276*0.795,-482*0.5-105-27.5)
                    .setStrokeLineWidth(2)
                    .hide()
                    .setTranslation(0,140)
                    .setColor(1,1,1);
        svg.distA = svg.p_WPN.createChild("text")
                .setTranslation(-276*0.795, -482*0.5+35)
                .setAlignment("left-center")
                .setColor(1,1,1)
                .hide()
                .setFontSize(20, 1.0);
        svg.distDownA = svg.p_WPN.createChild("path")
                    .moveTo(-276*0.795,-482*0.5-105+27.5)
                    .horiz(30)
                    .lineTo(-276*0.795+15,-482*0.5-105+27.5+15)
                    .lineTo(-276*0.795,-482*0.5-105+27.5)
                    .setStrokeLineWidth(2)
                    .hide()
                    .setTranslation(0,140)
                    .setColor(1,1,1);         
        
                
        svg.coolFrame = svg.p_WPN.createChild("path")
           .moveTo(276*0.795, -482*0.5+140+12)
           .vert(-24)
           .horiz(-60)
           .vert(24)
           .horiz(60)
           .setColor(1,1,1)
           .setStrokeLineWidth(1)
           .hide();
           
        svg.swap = svg.p_WPN.createChild("text")
                .setTranslation(276*0.795*0.30, -482*0.5+225)
                .setText("SWAP")
                .setAlignment("center-bottom")
                .setColor(1,1,1)
                .set("z-index",1)
                .setFontSize(13, 1.0);
    },
    
    addWPN: func {
        var svg = {getElementById: func (id) {return me[id]},};
        me.setupWPN(svg);
        me.PFD.addWPNPage = func(svg, title, layer_id) {   
            var np = PFD_Page.new(svg, title, layer_id, me);
            append(me.pages, np);
            me.page_index[layer_id] = np;
            np.setVisible(0);
            return np;
        };
        me.p_WPN = me.PFD.addWPNPage(svg, "WPN", "p_WPN");
        me.p_WPN.root = svg;
        me.p_WPN.wdt = 552*0.795;
        me.p_WPN.fwd = 0;
        me.p_WPN.plc = 0;
        me.p_WPN.ppp = me.PFD;
        me.p_WPN.my = me;
        me.p_WPN.notifyButton = func (eventi) {
            if (eventi != nil) {
                if (eventi == 10) {
                    me.ppp.selectPage(me.my.p_RDR);
                } elsif (eventi == 5) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    pylons.fcs.cycleLoadedWeapon();
                } elsif (eventi == 0) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    if (me.wpnType == "fall") {
                        me.at = 1;
                    }
                } elsif (eventi == 1) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    if (me.wpnType == "fall") {
                        me.at = -1;
                    }
                } elsif (eventi == 2) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    if (me.wpnType == "fall") {
                        me.ar = 25;
                    }
                } elsif (eventi == 3) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    if (me.wpnType == "fall") {
                        me.ar = -25;
                    }
                } elsif (eventi == 8) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    if (me.wpnType == "fall") {
                        var rp = pylons.fcs.getRippleMode();
                        if (rp < 9) {
                            rp += 1;
                        } elsif (rp == 9) {
                            rp = 1;
                        }
                        pylons.fcs.setRippleMode(rp);
                    }
                } elsif (eventi == 9) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }                    
                    if (me.wpnType=="heat") {
                        me.cooling = !pylons.fcs.getSelectedWeapon().isCooling();
                        foreach(var snake;pylons.fcs.getAllOfType("AIM-9")) {
                            snake.setCooling(me.cooling);
                        }                        
                    } elsif (me.wpnType == "fall") {
                        if (getprop("controls/armament/dual")==1) {
                            setprop("controls/armament/dual",2);
                        } else {
                            setprop("controls/armament/dual",1);
                        }
                    }               
                } elsif (eventi == 17) {
                    me.ppp.selectPage(me.my.p_SMS);
                #} elsif (eventi == 18) {
                #    me.ppp.selectPage(me.my.pjitds_1);
                } elsif (eventi == 11) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    if (me.wpnType == "fall") {
                        pylons.fcs.setDropMode(!pylons.fcs.getDropMode());
                    }
                } elsif (eventi == 16) {
                    me.ppp.selectPage(me.my.p_HSD);
                } elsif (eventi == 18) {
                    swap();
                }
# Menu Id's
#  CRM
#   10  11  12  13  14
# 0                    5            
# 1                    6            
# 2                    7            
# 3                    8            
# 4                    9            
#   15  16  17  18  19
#  VSD HSD WPN SIT
            }
        };
        me.p_WPN.update = func (noti) {
            if (noti.FrameCount != 3)
                return;
            if (getprop("sim/variant-id") == 0) {
                return;
            }
            
            if (me["at"]== nil) {
                me.at = 0;
            }
            if (me["ar"]== nil) {
                me.ar = 0;
            }
            me.wpn = pylons.fcs.getSelectedWeapon();
            me.pylon = pylons.fcs.getSelectedPylon();
            
            me.wpnType = "";
            me.cool = "";
            me.eegs = "";
            me.ready = "";
            me.ripple = "";
            me.rippleDist = "";
            me.downAd = 0;
            me.upAd = 0;
            me.coolFrame = 0;
            me.downA = 0;
            me.upA = 0;
            me.armtimer = "";
            me.drop = "";
            me.showDist = 0;
            me.pre = "";
            if (me.wpn != nil and me.pylon != nil and me.wpn["typeShort"] != nil) {
                if (me.wpn.type == "MK-82" or me.wpn.type == "MK-83" or me.wpn.type == "MK-84" or me.wpn.type == "GBU-12" or me.wpn.type == "GBU-24" or me.wpn.type == "GBU-54" or me.wpn.type == "CBU-87" or me.wpn.type == "CBU-105" or me.wpn.type == "GBU-31" or me.wpn.type == "AGM-154A" or me.wpn.type == "B61-7" or me.wpn.type == "B61-12") {
                    me.wpnType ="fall";
                    var nm = pylons.fcs.getDropMode();
                    if (nm == 1) {me.drop = "CCIP";me.pre=armament.contact != nil and armament.contact.get_type() != armament.AIR?"PRE":"VIS";}
                    if (nm == 0) {me.drop = "CCRP";me.pre="PRE"}
                    var rp = pylons.fcs.getRippleMode();
                    var rpd = pylons.fcs.getRippleDist()*M2FT;
                    me.ripple = "RP "~rp;
                    if (rp > 1) {
                        me.showDist = 1;
                    }
                    rpd += me.ar;
                    if (rpd < 25) {
                        rpd = 25;
                    } elsif (rpd > 400) {
                        rpd = 400;
                    }
                    pylons.fcs.setRippleDist(FT2M * rpd);
                    me.downAd = rpd>25 and me.showDist;
                    me.upAd = rpd<400 and me.showDist;
                    
                    me.rippleDist = sprintf("RP %3d FT",math.round(rpd));
                    
                    me.eegs = "A-G";
                    me.wpn.arming_time += me.at;
                    if (me.wpn.arming_time < 0) {
                        me.wpn.arming_time = 0;
                    } elsif (me.wpn.arming_time > 20) {
                        me.wpn.arming_time = 20;
                    }
                    if (me.at != 0) {
                        foreach(var bomb;pylons.fcs.getAllOfType(me.wpn.type)) {
                            bomb.arming_time = me.wpn.arming_time;
                        }
                    }
                    me.armtime = me.wpn.arming_time;
                    me.downA = me.armtime>0;
                    me.upA = me.armtime<20;
                    me.armtimer = sprintf("AD %.2fSEC",me.armtime);#arming delay
                    me.cool = getprop("controls/armament/dual")==1?"SGL":"PAIR";
                    if (me.pylon.operableFunction != nil and !me.pylon.operableFunction()) {
                        me.ready = "FAIL";
                    } elsif (me.wpn.status < armament.MISSILE_STARTING) {
                        me.ready = "OFF";
                    } elsif (me.wpn.status == armament.MISSILE_STARTING) {
                        me.ready = "INIT";
                    } else {
                        me.ready = "RDY";
                    }
                } elsif (me.wpn.type == "AGM-65" or me.wpn.type == "AGM-84" or me.wpn.type == "AGM-119" or me.wpn.type == "AGM-158") {
                    me.wpnType ="ground";
                    me.eegs = "A-G";
                    if (me.pylon.operableFunction != nil and !me.pylon.operableFunction()) {
                        me.ready = "FAIL";
                    } elsif (me.wpn.status < armament.MISSILE_STARTING) {
                        me.ready = "OFF";
                    } elsif (me.wpn.status == armament.MISSILE_STARTING) {
                        me.ready = "INIT";
                    } else {
                        me.ready = "RDY";
                    }
                } elsif (me.wpn.type == "AGM-88") {
                    me.wpnType ="anti-rad";
                    me.eegs = "A-G";
                    me.drop = getprop("f16/stores/harm-mounted")?"HAD":"HAS";
                    if (me.pylon.operableFunction != nil and !me.pylon.operableFunction()) {
                        me.ready = "FAIL";
                    } elsif (me.wpn.status < armament.MISSILE_STARTING) {
                        me.ready = "OFF";
                    } elsif (me.wpn.status == armament.MISSILE_STARTING) {
                        me.ready = "INIT";
                    } else {
                        me.ready = "RDY";
                    }
                } elsif (me.wpn.type == "AIM-9") {
                    me.wpnType ="heat";
                    me.cool = me.wpn.getWarm()==0?"COOL":"WARM";
                    me.eegs = "A-A";
                    me.coolFrame = me.wpn.isCooling()==1?1:0;                    
                    me.drop = getprop("instrumentation/radar/radar-standby")==1?"BORE":"SLAV";
                    if (me.pylon.operableFunction != nil and !me.pylon.operableFunction()) {
                        me.ready = "FAIL";
                    } elsif (me.wpn.status < armament.MISSILE_STARTING) {
                        me.ready = "OFF";
                    } elsif (me.wpn.status == armament.MISSILE_STARTING) {
                        me.ready = "INIT";
                    } else {
                        me.ready = "RDY";
                    }
                } elsif (me.wpn.type == "AIM-120" or me.wpn.type == "AIM-7") {
                    me.wpnType ="air";
                    me.drop = "SLAV";
                    me.eegs = "A-A";
                    if (me.pylon.operableFunction != nil and !me.pylon.operableFunction()) {
                        me.ready = "FAIL";
                    } elsif (me.wpn.status < armament.MISSILE_STARTING) {
                        me.ready = "OFF";
                    } elsif (me.wpn.status == armament.MISSILE_STARTING) {
                        me.ready = "INIT";
                    } else {
                        me.ready = "RDY";
                    }
                } elsif (me.wpn.type == "20mm Cannon") {
                    me.wpnType ="gun";
                    me.eegs = "EEGS";
                    if (me.pylon.operableFunction != nil and !me.pylon.operableFunction()) {
                        me.ready = "FAIL";
                    } else {
                        me.ready = "RDY";
                    }
                } elsif (me.wpn.type == "LAU-68") {
                    me.wpnType ="rocket";
                    me.eegs = "A-G";
                    if (me.pylon.operableFunction != nil and !me.pylon.operableFunction()) {
                        me.ready = "FAIL";
                    } else {
                        me.ready = "RDY";
                    }
                } else {
                    print(me.wpn.type~" not supported in WPN page.");
                    me.wpnType ="void";
                }
                me.myammo = pylons.fcs.getAmmo();
                if (me.wpn.type == "20mm Cannon") {
                    if (me.myammo ==0) me.myammo = "0";
                    elsif (me.myammo <10) me.myammo = "1";
                    else me.myammo = ""~int(me.myammo*0.1);
                } elsif (me.myammo==1) {
                    me.myammo = "";
                } else {
                    me.myammo = ""~me.myammo;
                }
                me.root.weap.setText(me.myammo~me.wpn.typeShort);
                if (!getprop("controls/armament/master-arm")) {
                    me.ready = "";#TODO: ?
                }
            } else {
                me.root.weap.setText("");
            }
            me.root.pre.setText(me.pre);  
            me.root.drop.setText(me.drop);  
            me.root.cool.setText(me.cool);
            me.root.eegs.setText(me.eegs);
            me.root.ready.setText(me.ready);
            me.root.ripple.setText(me.ripple);
            me.root.coolFrame.setVisible(me.coolFrame);
            me.root.rangDownA.setVisible(me.downA);
            me.root.rangUpA.setVisible(me.upA);
            me.root.rangA.setText(me.armtimer);
            me.root.rangA.setVisible(me.upA or me.downA);
            
            me.root.distDownA.setVisible(me.downAd);
            me.root.distUpA.setVisible(me.upAd);
            me.root.distA.setText(me.rippleDist);
            me.root.distA.setVisible(me.showDist);
            me.at = 0;
            me.ar = 0;
        };
    },

    setupHSD: func (svg) {
        svg.p_HSD = me.canvas.createGroup()
                    .set("font","LiberationFonts/LiberationMono-Regular.ttf");
        svg.buttonView = svg.p_HSD.createChild("group")
                .setTranslation(276*0.795,482);
        svg.p_HSDc = svg.p_HSD.createChild("group")
                .setTranslation(276*0.795,482*0.75);#552,482 , 0.795 is for UV map
        svg.cone = svg.p_HSDc.createChild("group")
            .set("z-index",5);#radar cone

        svg.width  = 276*0.795*2;
        svg.height = 482;

        svg.outerRadius  = svg.height*0.75;
        svg.mediumRadius = svg.outerRadius*0.6666;
        svg.innerRadius  = svg.outerRadius*0.3333;
        #var innerTick    = 0.85*innerRadius*math.cos(45*D2R);
        #var outerTick    = 1.15*innerRadius*math.cos(45*D2R);
        

        svg.conc = svg.p_HSDc.createChild("path")
            .moveTo(svg.innerRadius,0)
            .arcSmallCW(svg.innerRadius,svg.innerRadius, 0, -svg.innerRadius*2, 0)
            .arcSmallCW(svg.innerRadius,svg.innerRadius, 0,  svg.innerRadius*2, 0)
            .moveTo(svg.mediumRadius,0)
            .arcSmallCW(svg.mediumRadius,svg.mediumRadius, 0, -svg.mediumRadius*2, 0)
            .arcSmallCW(svg.mediumRadius,svg.mediumRadius, 0,  svg.mediumRadius*2, 0)
            .moveTo(svg.outerRadius,0)
            .arcSmallCW(svg.outerRadius,svg.outerRadius, 0, -svg.outerRadius*2, 0)
            .arcSmallCW(svg.outerRadius,svg.outerRadius, 0,  svg.outerRadius*2, 0)
            .moveTo(0,-svg.innerRadius)#north
            .vert(-15)
            .lineTo(3,-svg.innerRadius-15+2)
            .lineTo(0,-svg.innerRadius-15+4)
            .moveTo(0,svg.innerRadius-15)#south
            .vert(30)
            .moveTo(-svg.innerRadius,0)#west
            .horiz(-15)
            .moveTo(svg.innerRadius,0)#east
            .horiz(15)
            .setStrokeLineWidth(1)
            .set("z-index",2)
            .setColor(1,1,1);





        svg.maxB = 16;
        svg.blep = setsize([],svg.maxB);
        for (var i = 0;i<svg.maxB;i+=1) {
            svg.blep[i] = svg.p_HSDc.createChild("path")
                    .moveTo(0,0)
                    .vert(4)
                    .setStrokeLineWidth(4)
                    .hide();
        }
        svg.rangUp = svg.buttonView.createChild("path")
                    .moveTo(-276*0.795,-482*0.5-105-27.5)
                    .horiz(30)
                    .lineTo(-276*0.795+15,-482*0.5-105-27.5-15)
                    .lineTo(-276*0.795,-482*0.5-105-27.5)
                    .setStrokeLineWidth(2)
                    .setColor(1,1,1);
        svg.rang = svg.buttonView.createChild("text")
                .setTranslation(-276*0.795, -482*0.5-105)
                .setAlignment("left-center")
                .setText("8")
                .setColor(1,1,1)
                .setFontSize(20, 1.0);
        svg.rangDown = svg.buttonView.createChild("path")
                    .moveTo(-276*0.795,-482*0.5-105+27.5)
                    .horiz(30)
                    .lineTo(-276*0.795+15,-482*0.5-105+27.5+15)
                    .lineTo(-276*0.795,-482*0.5-105+27.5)
                    .setStrokeLineWidth(2)
                    .setColor(1,1,1);

        svg.depcen = svg.buttonView.createChild("text")#DEP/CEN
                .setTranslation(-276*0.795, -482*0.5-5)
                .setText("DEP")
                .setAlignment("left-center")
                .setColor(1,1,1)
                .setFontSize(20, 1.0);
        svg.cpl = svg.buttonView.createChild("text")#CPL/DCPL
                .setTranslation(-276*0.795, -482*0.5+55)
                .setText("DCPL")
                .setAlignment("left-center")
                .setColor(1,1,1)
                .setFontSize(20, 1.0);
#        svg.bars = svg.p_HSDc.createChild("text")#
#                .setTranslation(-276*0.795, -482*0.5+60)
#                .setText("8B")
#                .setAlignment("left-center")
#                .setColor(1,1,1)
#                .setFontSize(20, 1.0);

        svg.lock = svg.p_HSDc.createChild("group")
                .hide();
        svg.lockRot = svg.lock.createChild("path")
                            .moveTo(10,10)
                            .lineTo(0,-10)
                            .lineTo(-10,10)
                            .lineTo(10,10)
                            .moveTo(0,-10)
                            .vert(-10)
                            .setColor(1,1,0)
                            .setStrokeLineWidth(2);
        svg.lockAlt = svg.lock.createChild("text")
                .setTranslation(0, 25)
                .setText("20")
                .setAlignment("center-top")
                .setColor(1,1,1)
                .setFontSize(20, 1.0);
        svg.lockInfo = svg.p_HSDc.createChild("text")
                .setTranslation(276*0.795*0.8, -482*0.9)
                .setAlignment("right-center")
                .setColor(1,1,1)
                .setFontSize(20, 1.0);
        svg.lockFRot = svg.lock.createChild("path")
                            .moveTo(-10,-10)
                            .vert(20)
                            .horiz(20)
                            .vert(-20)
                            .horiz(-20)
                            .moveTo(0,-10)
                            .vert(-10)
                            .setColor(0.5,1,0.5)
                            .setStrokeLineWidth(2);

        svg.myself = svg.p_HSDc.createChild("path")#own ship
           .moveTo(0, 0)
           .vert(30)
           .moveTo(-10, 10)
           .horiz(20)
           .moveTo(-5, 20)
           .horiz(10)
           .setColor(0.5,0.5,1)
           .setStrokeLineWidth(1);
#        svg.az2 = svg.p_HSDc.createChild("path")
#           .moveTo(0, 0)
#           .lineTo(0, -482)
#           .setColor(0.5,0.5,1)
#           .setStrokeLineWidth(1);


        
        
        svg.c1 = svg.p_HSDc.createChild("path")
            .moveTo(-50,0)
            .arcSmallCW(50,50, 0,  50*2, 0)
            .arcSmallCW(50,50, 0, -50*2, 0)
            .setStrokeLineWidth(1)
            .set("z-index",2)
            .hide()
            .setColor(1,0,0);
        svg.c2 = svg.p_HSDc.createChild("path")
            .moveTo(-50,0)
            .arcSmallCW(50,50, 0,  50*2, 0)
            .arcSmallCW(50,50, 0, -50*2, 0)
            .setStrokeLineWidth(1)
            .set("z-index",2)
            .hide()
            .setColor(1,0,0);
        svg.c3 = svg.p_HSDc.createChild("path")
            .moveTo(-50,0)
            .arcSmallCW(50,50, 0,  50*2, 0)
            .arcSmallCW(50,50, 0, -50*2, 0)
            .setStrokeLineWidth(1)
            .set("z-index",2)
            .hide()
            .setColor(1,1,0);
        svg.c4 = svg.p_HSDc.createChild("path")
            .moveTo(-50,0)
            .arcSmallCW(50,50, 0,  50*2, 0)
            .arcSmallCW(50,50, 0, -50*2, 0)
            .setStrokeLineWidth(1)
            .set("z-index",2)
            .hide()
            .setColor(0,1,0);
        
        svg.ct1 = svg.p_HSDc.createChild("text")
                .setAlignment("center-center")
                .setColor(1,0,0)
                .set("z-index",2)
                .setFontSize(15, 1.0);
        svg.ct2 = svg.p_HSDc.createChild("text")
                .setAlignment("center-center")
                .setColor(1,0,0)
                .set("z-index",2)
                .setFontSize(15, 1.0);
        svg.ct3 = svg.p_HSDc.createChild("text")
                .setAlignment("center-center")
                .setColor(1,1,0)
                .set("z-index",2)
                .setFontSize(15, 1.0);
        svg.ct4 = svg.p_HSDc.createChild("text")
                .setAlignment("center-center")
                .setColor(0,1,0)
                .set("z-index",2)
                .setFontSize(15, 1.0);        
        
        svg.bullseye = svg.p_HSDc.createChild("path")
            .moveTo(-25,0)
            .arcSmallCW(25,25, 0,  25*2, 0)
            .arcSmallCW(25,25, 0, -25*2, 0)
            .moveTo(-15,0)
            .arcSmallCW(15,15, 0,  15*2, 0)
            .arcSmallCW(15,15, 0, -15*2, 0)
            .moveTo(-5,0)
            .arcSmallCW(5,5, 0,  5*2, 0)
            .arcSmallCW(5,5, 0, -5*2, 0)
            .setStrokeLineWidth(2)
            .setColor(0.5,0.5,1);
        svg.bullOwnRing = svg.buttonView.createChild("path")
            .moveTo(-15,0)
            .arcSmallCW(15,15, 0,  15*2, 0)
            .arcSmallCW(15,15, 0, -15*2, 0)
            .close()
            .moveTo(0,-18)
            .lineTo(7,-13)
            .moveTo(0,-18)
            .lineTo(-7,-13)
            .close()
            .setStrokeLineWidth(2)
            .setTranslation(-190, -50)
            .setColor(0.5,0.5,1);
        svg.bullOwnDist = svg.buttonView.createChild("text")
                .setAlignment("center-center")
                .setColor(0.5,0.5,1)
                .setTranslation(-190, -50)
                .setText("12")
                .setFontSize(18, 1.0);            
        svg.bullOwnDir = svg.buttonView.createChild("text")
                .setAlignment("center-top")
                .setColor(0.5,0.5,1)
                .setTranslation(-190, -30)
                .setText("270")
                .setFontSize(18, 1.0);
                
        svg.swap = svg.buttonView.createChild("text")
                .setTranslation(276*0.795*0.30, -482*0.5+225)
                .setText("SWAP")
                .setAlignment("center-bottom")
                .setColor(1,1,1)
                .set("z-index",1)
                .setFontSize(13, 1.0);

        svg.centered = 0;
        svg.coupled = 0;
        svg.range_cen = 40;
        svg.range_dep = 32;
    },

    addHSD: func {
        var svg = {getElementById: func (id) {return me[id]},};
        me.setupHSD(svg);
        me.PFD.addHSDPage = func(svg, title, layer_id) {   
            var np = PFD_Page.new(svg, title, layer_id, me);
            append(me.pages, np);
            me.page_index[layer_id] = np;
            np.setVisible(0);
            return np;
        };
        me.p_HSD = me.PFD.addHSDPage(svg, "HSD", "p_HSD");
        me.p_HSD.root = svg;
        me.p_HSD.wdt = 552*0.795;
        me.p_HSD.fwd = 0;
        me.p_HSD.plc = 0;
        me.p_HSD.ppp = me.PFD;
        me.p_HSD.my = me;
        me.p_HSD.notifyButton = func (eventi) {
            if (eventi != nil) {
                if (eventi == 0) {
                    if (me.root.coupled) return;
                    if (me.root.centered) {
                        if (me.root.range_cen == 5)
                            me.root.range_cen =10
                        elsif (me.root.range_cen == 10)
                            me.root.range_cen =20
                        elsif (me.root.range_cen == 20)
                            me.root.range_cen =40
                        elsif (me.root.range_cen == 40)
                            me.root.range_cen =80
                        elsif (me.root.range_cen == 80)
                            me.root.range_cen =160
                        else
                            me.root.range_cen = 160;
                    } elsif (!me.root.centered) {
                        if (me.root.range_dep == 8)
                            me.root.range_dep =16
                        elsif (me.root.range_dep == 16)
                            me.root.range_dep =32
                        elsif (me.root.range_dep == 32)
                            me.root.range_dep =64
                        elsif (me.root.range_dep == 64)
                            me.root.range_dep =128
                        elsif (me.root.range_dep == 128)
                            me.root.range_dep =256
                        else
                            me.root.range_dep = 256;
                    }
                } elsif (eventi == 1) {
                    if (me.root.coupled) return;
                    if (me.root.centered) {
                        if (me.root.range_cen == 160)
                            me.root.range_cen =80
                        elsif (me.root.range_cen == 80)
                            me.root.range_cen =40
                        elsif (me.root.range_cen == 40)
                            me.root.range_cen =20
                        elsif (me.root.range_cen == 20)
                            me.root.range_cen =10
                        elsif (me.root.range_cen == 10)
                            me.root.range_cen =5
                        else
                            me.root.range_cen = 5;
                    } elsif (!me.root.centered) {
                        if (me.root.range_dep == 256)
                            me.root.range_dep =128
                        elsif (me.root.range_dep == 128)
                            me.root.range_dep =64
                        elsif (me.root.range_dep == 64)
                            me.root.range_dep =32
                        elsif (me.root.range_dep == 32)
                            me.root.range_dep =16
                        elsif (me.root.range_dep == 16)
                            me.root.range_dep =8
                        else
                            me.root.range_dep = 8;
                    }
                } elsif (eventi == 17) {
                    me.ppp.selectPage(me.my.p_SMS);
                } elsif (eventi == 15) {
                    me.ppp.selectPage(me.my.p_WPN);
                #} elsif (eventi == 18) {
                #    me.ppp.selectPage(me.my.pjitds_1);
                } elsif (eventi == 10) {
                    me.ppp.selectPage(me.my.p_RDR);
                } elsif (eventi == 2) {
                    me.root.centered = !me.root.centered;
                    me.root.depcen.setText(me.root.centered==1?"CEN":"DEP");
                } elsif (eventi == 3) {
                    me.root.coupled = !me.root.coupled;
                    me.root.cpl.setText(me.root.coupled==1?"CPL":"DCPL");
                } elsif (eventi == 18) {
                    swap();
                }
            }

# Menu Id's
#  CRM
#   10  11  12  13  14
# 0                    5            
# 1                    6            
# 2                    7            
# 3                    8            
# 4                    9            
#   15  16  17  18  19
#  VSD HSD SMS SIT
        };
        me.p_HSD.update = func (noti) {
            me.root.conc.setRotation(-getprop("orientation/heading-deg")*D2R);
            if (noti.FrameCount != 1 and noti.FrameCount != 3)
                return;
            if (me.root.coupled) {
                me.root.rangDown.hide();
                me.root.rangUp.hide();
                if (awg_9.range_radar2 == 5) {
                    me.root.range_cen = 5;
                    me.root.range_dep = 8;
                } elsif (awg_9.range_radar2 == 10) {
                    me.root.range_cen = 10;
                    me.root.range_dep = 16;
                } elsif (awg_9.range_radar2 == 20) {
                    me.root.range_cen = 20;
                    me.root.range_dep = 32;
                } elsif (awg_9.range_radar2 == 40) {
                    me.root.range_cen = 40;
                    me.root.range_dep = 64;
                } elsif (awg_9.range_radar2 == 80) {
                    me.root.range_cen = 80;
                    me.root.range_dep = 128;
                } elsif (awg_9.range_radar2 == 160) {
                    me.root.range_cen = 160;
                    me.root.range_dep = 256;
                }
            } else {
                me.root.rangDown.show();
                me.root.rangUp.show();
            }
            if (me.root.centered) {
                me.root.p_HSDc.setTranslation(276*0.795,482*0.50);
                me.root.rang.setText(""~me.root.range_cen);
            } else {
                me.root.p_HSDc.setTranslation(276*0.795,482*0.75);
                me.root.rang.setText(""~me.root.range_dep);
            }
            me.bullOn = getprop("f16/avionics/bulls-eye-defined");
            if (me.bullOn) {
                me.bullLat = getprop("f16/avionics/bulls-eye-lat");
                me.bullLon = getprop("f16/avionics/bulls-eye-lon");
                me.bullCoord = geo.Coord.new().set_latlon(me.bullLat,me.bullLon);
                me.ownCoord = geo.aircraft_position();
                me.bullDirToMe = me.bullCoord.course_to(me.ownCoord);
                me.meToBull = ((me.bullDirToMe+180)-noti.heading)*D2R;
                me.root.bullOwnRing.setRotation(me.meToBull);
                me.bullDistToMe = me.bullCoord.distance_to(me.ownCoord)*M2NM;
                if (me.root.centered) {
                    me.bullRangePixels = me.root.mediumRadius*(me.bullDistToMe/me.root.range_cen);
                } else {
                    me.bullRangePixels = me.root.outerRadius*(me.bullDistToMe/me.root.range_dep);
                }                
                me.legX = me.bullRangePixels*math.sin(me.meToBull);
                me.legY = -me.bullRangePixels*math.cos(me.meToBull);
                me.root.bullseye.setTranslation(me.legX,me.legY);
                if (me.bullDistToMe > 100) {
                    me.bullDistToMe = "  ";
                } else {
                    me.bullDistToMe = sprintf("%02d", me.bullDistToMe);
                }
                me.bullDirToMe = sprintf("%03d", me.bullDirToMe);
                me.root.bullOwnDir.setText(me.bullDirToMe);
                me.root.bullOwnDist.setText(me.bullDistToMe);
            }
            me.root.bullOwnRing.setVisible(me.bullOn);
            me.root.bullOwnDir.setVisible(me.bullOn);
            me.root.bullOwnDist.setVisible(me.bullOn);
            me.root.bullseye.setVisible(me.bullOn);
            me.i=0;
            me.root.lock.hide();
            me.root.lockInfo.hide();
            if (me.root.centered) {
                me.rdrRangePixels = me.root.mediumRadius*(awg_9.range_radar2/me.root.range_cen);
            } else {
                me.rdrRangePixels = me.root.outerRadius*(awg_9.range_radar2/me.root.range_dep);
            }
            me.az = getprop("instrumentation/radar/az-field");
            if (noti.FrameCount == 1) {
                me.root.cone.removeAllChildren();
                if (getprop("sim/multiplay/generic/int[2]") != 1) {
                    me.radarX = me.rdrRangePixels*math.cos((90-me.az*0.5)*D2R);
                    me.radarY = -me.rdrRangePixels*math.sin((90-me.az*0.5)*D2R);
                    me.cone = me.root.cone.createChild("path")
                        .moveTo(0,0)
                        .lineTo(me.radarX,me.radarY)
                        .moveTo(0,0)
                        .lineTo(-me.radarX,me.radarY)
                        .arcSmallCW(me.rdrRangePixels,me.rdrRangePixels, 0, me.radarX*2, 0)
                        .setStrokeLineWidth(1)
                        .set("z-index",5)
                        .setColor(0.5,0.5,1)
                        .update();
                }
                if (getprop("autopilot/route-manager/active") and getprop("f16/avionics/power-mmc")) {
                    me.plan = flightplan();
                    me.planSize = me.plan.getPlanSize();
                    me.prevX = nil;
                    me.prevY = nil;
                    for (me.j = 0; me.j < me.planSize;me.j+=1) {
                        me.wp = me.plan.getWP(me.j);
                        me.wpC = geo.Coord.new();
                        me.wpC.set_latlon(me.wp.lat,me.wp.lon);
                        me.legBearing = geo.aircraft_position().course_to(me.wpC)-getprop("orientation/heading-deg");#relative
                        me.legDistance = geo.aircraft_position().distance_to(me.wpC)*M2NM;
                        if (me.root.centered) {
                            me.legRangePixels = me.root.mediumRadius*(me.legDistance/me.root.range_cen);
                        } else {
                            me.legRangePixels = me.root.outerRadius*(me.legDistance/me.root.range_dep);
                        }
                        me.legX = me.legRangePixels*math.sin(me.legBearing*D2R);
                        me.legY = -me.legRangePixels*math.cos(me.legBearing*D2R);
                        me.wp = me.root.cone.createChild("path")
                            .moveTo(me.legX-5,me.legY)
                            .arcSmallCW(5,5, 0, 5*2, 0)
                            .arcSmallCW(5,5, 0,-5*2, 0)
                            .setStrokeLineWidth(1)
                            .set("z-index",4)
                            .setColor(1,1,1)
                            .update();
                        if (me.plan.current == me.j) {
                            me.wp.setColorFill(1,1,1);
                        }
                        if (me.prevX != nil) {
                            me.root.cone.createChild("path")
                                .moveTo(me.legX,me.legY)
                                .lineTo(me.prevX,me.prevY)
                                .setStrokeLineWidth(1)
                                .set("z-index",4)
                                .setColor(1,1,1)
                                .update();
                        }
                        me.prevX = me.legX;
                        me.prevY = me.legY;
                    }
                }
                
                for (var u = 0;u<2;u+=1) {
                    if (lines[u] != nil) {
                        # lines
                        me.plan = lines[u];
                        me.planSize = me.plan.getPlanSize();
                        me.prevX = nil;
                        me.prevY = nil;
                        for (me.j = 0; me.j <= me.planSize;me.j+=1) {
                            if (me.j == me.planSize) {
                                if (me.planSize > 2) {
                                    me.wp = me.plan.getWP(0);
                                } else {
                                    continue;
                                }
                            } else {
                                me.wp = me.plan.getWP(me.j);
                            }
                            me.wpC = geo.Coord.new();
                            me.wpC.set_latlon(me.wp.lat,me.wp.lon);
                            me.legBearing = geo.aircraft_position().course_to(me.wpC)-getprop("orientation/heading-deg");#relative
                            me.legDistance = geo.aircraft_position().distance_to(me.wpC)*M2NM;
                            if (me.root.centered) {
                                me.legRangePixels = me.root.mediumRadius*(me.legDistance/me.root.range_cen);;
                            } else {
                                me.legRangePixels = me.root.outerRadius*(me.legDistance/me.root.range_dep);;
                            }
                            me.legX = me.legRangePixels*math.sin(me.legBearing*D2R);
                            me.legY = -me.legRangePixels*math.cos(me.legBearing*D2R);
                            if (me.prevX != nil) {
                                me.root.cone.createChild("path")
                                    .moveTo(me.legX,me.legY)
                                    .lineTo(me.prevX,me.prevY)
                                    .setStrokeLineWidth(1)
                                    .setStrokeDashArray([10, 10])
                                    .set("z-index",4)
                                    .setColor(0.9,0.9,0.9)
                                    .update();
                            }
                            me.prevX = me.legX;
                            me.prevY = me.legY;
                        }
                    }
                }
                
                me.root.cone.update();
                
                for (var l = 1; l<=4;l+=1) {
                    # threat circles
                    me.la = getprop("f16/avionics/c"~l~"-lat");
                    me.lo = getprop("f16/avionics/c"~l~"-lon");
                    me.ra = getprop("f16/avionics/c"~l~"-rad");
                    me.ty = getprop("f16/avionics/c"~l~"-typ");
                    
                    if (l==1) {
                        me.ci = me.root.c1;
                        me.cit = me.root.ct1;
                    } elsif (l==2) {
                        me.ci = me.root.c2;
                        me.cit = me.root.ct2;
                    } elsif (l==3) {
                        me.ci = me.root.c3;
                        me.cit = me.root.ct3;
                    } elsif (l==4) {
                        me.ci = me.root.c4;
                        me.cit = me.root.ct4;
                    }
                    
                    if (me.la != nil and me.lo != nil and me.ra != nil and me.ra > 0) {
                        me.wpC = geo.Coord.new();
                        me.wpC.set_latlon(me.la,me.lo);
                        me.legBearing = geo.aircraft_position().course_to(me.wpC)-getprop("orientation/heading-deg");#relative
                        me.legDistance = geo.aircraft_position().distance_to(me.wpC)*M2NM;
                        me.legRadius  = me.ra;
                        if (me.root.centered) {
                            me.legRangePixels = me.root.mediumRadius*(me.legDistance/me.root.range_cen);
                            me.legScale = me.root.mediumRadius*(me.legRadius/me.root.range_cen)/50;
                        } else {
                            me.legRangePixels = me.root.outerRadius*(me.legDistance/me.root.range_dep);
                            me.legScale = me.root.outerRadius*(me.legRadius/me.root.range_dep)/50;
                        }
                        
                        me.legX = me.legRangePixels*math.sin(me.legBearing*D2R);
                        me.legY = -me.legRangePixels*math.cos(me.legBearing*D2R);
                        me.ci.setTranslation(me.legX,me.legY);
                        me.ci.setScale(me.legScale);
                        me.ci.setStrokeLineWidth(1/me.legScale);
                        me.ci.show();
                        me.cit.setText(me.ty);
                        me.cit.setTranslation(me.legX,me.legY);
                        me.cit.show();
                    } else {
                        me.ci.hide();
                        me.cit.hide();
                    }
                }
            }
            
            foreach(contact; awg_9.tgts_list) {
                me.cs = contact.get_Callsign();
                me.blue = getprop("f16/avionics/power-dl") and (me.cs == getprop("link16/wingman-1") or me.cs == getprop("link16/wingman-2") or me.cs == getprop("link16/wingman-3") or me.cs == getprop("link16/wingman-4") or me.cs == getprop("link16/wingman-5") or me.cs == getprop("link16/wingman-6") or me.cs == getprop("link16/wingman-7") or me.cs == getprop("link16/wingman-8") or me.cs == getprop("link16/wingman-9") or me.cs == getprop("link16/wingman-10") or me.cs == getprop("link16/wingman-11") or me.cs == getprop("link16/wingman-12"));
                me.desig = contact==awg_9.active_u or (awg_9.active_u != nil and contact.get_Callsign() == awg_9.active_u.get_Callsign() and contact.ModelType==awg_9.active_u.ModelType);
                if (contact.get_display() == 0 or !(me.desig or me.blue)) {
                    continue;
                }
                me.distPixels = (contact.get_range()/awg_9.range_radar2)*me.rdrRangePixels;

                me.root.blep[me.i].setColor(me.blue?[0,0,1]:[1,1,1]);
                me.root.blep[me.i].setTranslation(me.distPixels*math.sin(contact.get_relative_bearing()*D2R),-me.distPixels*math.cos(contact.get_relative_bearing()*D2R));
                me.root.blep[me.i].show();
                me.root.blep[me.i].update();
                if (me.desig) {
                    me.rot = contact.get_heading();
                    if (me.rot == nil) {
                        #can happen in transition between TWS to RWS
                        #me.root.lock.hide();
                    } else {
                        me.lockAlt = sprintf("%02d", contact.get_altitude()*0.001);
                        me.root.lockAlt.setText(me.lockAlt);
                        me.lockInfo = sprintf("%4d   %+4d", contact.get_Speed(), contact.get_closure_rate());
                        me.root.lockInfo.setText(me.lockInfo);
                        me.root.lockInfo.show();
                        me.rot = me.rot-getprop("orientation/heading-deg");
                        me.root.lock.setTranslation(me.distPixels*math.sin(contact.get_relative_bearing()*D2R),-me.distPixels*math.cos(contact.get_relative_bearing()*D2R));
                        
                        if (me.blue) {
                            me.root.lockFRot.setRotation(me.rot*D2R);
                            me.root.lockFRot.show();
                            me.root.lockRot.hide();
                            me.root.lockFRot.update();
                        } else {
                            me.root.lockRot.setRotation(me.rot*D2R);
                            me.root.lockRot.show();
                            me.root.lockFRot.hide();
                            me.root.lockRot.update();
                        }
                        me.root.lock.show();
                        me.root.lock.update();
                        me.root.blep[me.i].hide();
                    }
                }
                me.i += 1;
                if (me.i > (me.root.maxB-1)) {
                    break;
                }
            }
            for (;me.i<me.root.maxB;me.i+=1) {
                me.root.blep[me.i].hide();
            }
        };
    },

    addPages : func
    {   
        me.addRadar();
        me.addSMS();
        me.addHSD();
        me.addWPN();
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

        #if (me.model_element == "MFDimage1") {
        #    me.pjitds_1 =  PFD_NavDisplay.new(me.PFD,"Situation", "mfd-sit-1", "pjitds_1", "jtids_main");
        #} else {
        #    me.pjitds_1 =  PFD_NavDisplay.new(me.PFD,"Situation", "mfd-sit-2", "pjitds_1", "jtids_main");
        #}
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
                                #printf("%s: Button %d",me.designation, me.mfd_button_pushed);
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
        if (me.model_element == "MFDimage1") {
            me.PFD.selectPage(me.p_RDR);
        } else {
            if (getprop("sim/variant-id") == 0) {
                me.PFD.selectPage(me.p_HSD);
            } else {
                me.PFD.selectPage(me.p_SMS);
            }
        }
    },
    
    

    # Add the menus to each page. 
    setupMenus : func
    {
#
# Menu Id's
#  CRM
#   10  11  12  13  14
# 0                    5            
# 1                    6            
# 2                    7            
# 3                    8            
# 4                    9            
#   15  16  17  18  19
#  VSD HSD SMS SIT

        me.mfd_spin_reset_time = 0;

        #me.p1_1.addMenuItem(0, "ARMT", me.p1_2);
#        me.p1_1.addMenuItem(1, "VSD", me.p_VSD);
#        me.p1_1.addMenuItem(2, "SIT", me.pjitds_1);
        #me.p1_1.addMenuItem(3, "WPN", me.p1_2);
        #me.p1_1.addMenuItem(4, "DTM", me.p1_2);
#        me.p1_1.addMenuItem(10, "CRM", me.p_RDR);
#        me.p1_1.addMenuItem(11, "SMS", me.p_SMS);
#        me.p1_1.addMenuItem(12, "HSD", me.p_HSD);

        me.p_RDR.addMenuItem(17, "SMS", me.p_SMS);
        me.p_RDR.addMenuItem(15, "WPN", me.p_WPN);
        #me.p_RDR.addMenuItem(18, "SIT", me.pjitds_1);
        me.p_RDR.addMenuItem(16, "HSD", me.p_HSD);
        me.p_RDR.addMenuItem(19, "TGP", nil);

        me.p_HSD.addMenuItem(17, "SMS", me.p_SMS);
        me.p_HSD.addMenuItem(15, "WPN", me.p_WPN);
        #me.p_HSD.addMenuItem(18, "SIT", me.pjitds_1);
        me.p_HSD.addMenuItem(10, "CRM", me.p_RDR);
        me.p_HSD.addMenuItem(19, "TGP", nil);
        
        me.p_WPN.addMenuItem(17, "SMS", me.p_SMS);
        me.p_WPN.addMenuItem(10, "CRM", me.p_RDR);
        me.p_WPN.addMenuItem(19, "TGP", nil);
        me.p_WPN.addMenuItem(16, "HSD", me.p_HSD);

        #me.p_SMS.addMenuItem(18, "SIT", me.pjitds_1);
        me.p_SMS.addMenuItem(10, "CRM", me.p_RDR);
        me.p_SMS.addMenuItem(15, "WPN", me.p_WPN);
        me.p_SMS.addMenuItem(16, "HSD", me.p_HSD);
        me.p_SMS.addMenuItem(19, "TGP", nil);
#        me.p_SMS.addMenuItem(16, "TIM", me.p1_1);

#        me.p1_2.addMenuItem(0, "VSD", me.p_VSD);
        #me.p1_2.addMenuItem(1, "A/A", me.p1_3);
        #me.p1_2.addMenuItem(2, "A/G", me.p1_3);
        #me.p1_2.addMenuItem(3, "CBT JETT", me.p1_3);
        #me.p1_2.addMenuItem(4, "WPN LOAD", me.p1_3);
#        me.p1_2.addMenuItem(9, "M", me.p1_1);
#        me.p1_2.addMenuItem(10, "CRM", me.p_RDR);
#        me.p1_2.addMenuItem(12, "HSD", me.p_HSD);


 #       me.p1_3.addMenuItem(2, "SIT", me.pjitds_1);
        #me.p1_3.addMenuItem(3, "A/G", me.p1_3);
        #me.p1_3.addMenuItem(4, "2/2", me.p1_3);
        #me.p1_3.addMenuItem(8, "TM\nPWR", me.p1_3);
#        me.p1_3.addMenuItem(9, "M", me.p1_1);
        #me.p1_3.addMenuItem(10, "PYLON", me.p1_3);
        #me.p1_3.addMenuItem(12, "FUEL", me.p1_3);
        #me.p1_3.addMenuItem(14, "PYLON", me.p1_3);
        #me.p1_3.addMenuItem(15, "MODE S", me.p1_3);
 #       me.p1_3.addMenuItem(10, "CRM", me.p_RDR);
 #       me.p1_3.addMenuItem(12, "HSD", me.p_HSD);

#        me.pjitds_1.addMenuItem(9, "M", me.p1_1);
        #me.pjitds_1.addMenuItem(0, "ARMT", me.p1_2);
        #me.pjitds_1.addMenuItem(15, "VSD", me.p_VSD);
        #me.pjitds_1.addMenuItem(10, "CRM", me.p_RDR);
        #me.pjitds_1.addMenuItem(16, "HSD", me.p_HSD);
        #me.pjitds_1.addMenuItem(17, "SMS", me.p_SMS);
        #me.pjitds_1.addMenuItem(19, "TGP", nil);

        #me.p_VSD.addMenuItem(0, "ARMT", me.p1_2);
        #me.p_VSD.addMenuItem(18, "SIT", me.pjitds_1);
#        me.p_VSD.addMenuItem(4, "M", me.p1_1);
#        me.p_VSD.addMenuItem(9, "M", me.p1_1);
        #me.p_VSD.addMenuItem(10, "CRM", me.p_RDR);
        #me.p_VSD.addMenuItem(17, "SMS", me.p_SMS);
        #me.p_VSD.addMenuItem(16, "HSD", me.p_HSD);
        #me.p_VSD.addMenuItem(19, "TGP", nil);
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
var f16_mfd = F16MfdRecipient.new("F16-MFD");
#UpperMFD = f16_mfd.UpperMFD;
#LowerMFD = f16_mfd.LowerMFD;

#emesary.GlobalTransmitter.Register(f16_mfd);

var lines = [nil,nil];

var loadLine = func  (no,path) {
    printf("Attempting to load route %s to act as lines %d in HSD.", path, no);
  
    call(func {lines[no] = createFlightplan(path);}, nil, var err = []);
    if (size(err) or lines[no] == nil) {
        print(err[0]);
    }
};

var uv = nil;
var cursor_pos = [100,-100];
var cursor_click = -1;
var cursor_destination = nil;
var cursor_lock = -1;
var exp = 0;
var rdrMode = 0;

var slew_c = 0;

setlistener("controls/displays/cursor-click", func {if (getprop("controls/displays/cursor-click")) {slew_c = 1;}});

var setCursor = func (x, y, screen) {
    #552,482 , 0.795 is for UV map
    uv = [x*552-552*0.5*0.795,-y*486,screen, systime()];
    #printf("slew %d,%d on screen %d", uv[0],uv[1],uv[2]);
};

var swap = func {
    var left_page = f16_mfd.MFDl.PFD.current_page.title;
    var right_page = f16_mfd.MFDr.PFD.current_page.title;
    
    foreach(var page ; f16_mfd.MFDr.PFD.pages) {
        if (page.title == left_page) {
            f16_mfd.MFDr.PFD.selectPage(page);
        }
    }
    foreach(var page ; f16_mfd.MFDl.PFD.pages) {
        if (page.title == right_page) {
            f16_mfd.MFDl.PFD.selectPage(page);
        }
    }
};