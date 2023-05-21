# F-16 Canvas MFD
# Based on F-15, using generic MFD device from FGData.
# ---------------------------
# Richard Harrison: 2016-09-12 : rjh@zaretto.com
# ---------------------------

#for debug: setprop ("/sim/startup/terminal-ansi-colors",0);

# OBS text
var colorText1 = [getprop("/sim/model/MFD-color/text1/red"), getprop("/sim/model/MFD-color/text1/green"), getprop("/sim/model/MFD-color/text1/blue")];

# Info text
var colorText2 = [getprop("/sim/model/MFD-color/text2/red"), getprop("/sim/model/MFD-color/text2/green"), getprop("/sim/model/MFD-color/text2/blue")];

# red threat circles
var colorCircle1 = [getprop("/sim/model/MFD-color/circle1/red"), getprop("/sim/model/MFD-color/circle1/green"), getprop("/sim/model/MFD-color/circle1/blue")];

# yellow threat circles
var colorCircle2 = [getprop("/sim/model/MFD-color/circle2/red"), getprop("/sim/model/MFD-color/circle2/green"), getprop("/sim/model/MFD-color/circle2/blue")];

# green threat circles
var colorCircle3 = [getprop("/sim/model/MFD-color/circle3/red"), getprop("/sim/model/MFD-color/circle3/green"), getprop("/sim/model/MFD-color/circle3/blue")];

# Not used
var colorDot1 = [getprop("/sim/model/MFD-color/dot1/red"), getprop("/sim/model/MFD-color/dot1/green"), getprop("/sim/model/MFD-color/dot1/blue")];

# White/green radar search targets
var colorDot2 = [getprop("/sim/model/MFD-color/dot2/red"), getprop("/sim/model/MFD-color/dot2/green"), getprop("/sim/model/MFD-color/dot2/blue")];

# Datalink wingman
var colorDot4 = [getprop("/sim/model/MFD-color/dot4/red"), getprop("/sim/model/MFD-color/dot4/green"), getprop("/sim/model/MFD-color/dot4/blue")];

# Bullseye and STPT symbol on FCR
var colorBullseye = [getprop("/sim/model/MFD-color/bullseye/red"), getprop("/sim/model/MFD-color/bullseye/green"), getprop("/sim/model/MFD-color/bullseye/blue")];

# Bulleye direction to ownship text
var colorBetxt = [getprop("/sim/model/MFD-color/betxt/red"), getprop("/sim/model/MFD-color/betxt/green"), getprop("/sim/model/MFD-color/betxt/blue")];

var colorLine1  = [getprop("/sim/model/MFD-color/line1/red"), getprop("/sim/model/MFD-color/line1/green"), getprop("/sim/model/MFD-color/line1/blue")];
var colorLine2  = [getprop("/sim/model/MFD-color/line2/red"), getprop("/sim/model/MFD-color/line2/green"), getprop("/sim/model/MFD-color/line2/blue")];
var colorLine3  = [getprop("/sim/model/MFD-color/line3/red"), getprop("/sim/model/MFD-color/line3/green"), getprop("/sim/model/MFD-color/line3/blue")];
var colorLine4  = [getprop("/sim/model/MFD-color/line4/red"), getprop("/sim/model/MFD-color/line4/green"), getprop("/sim/model/MFD-color/line4/blue")];
var colorLine5  = [getprop("/sim/model/MFD-color/line5/red"), getprop("/sim/model/MFD-color/line5/green"), getprop("/sim/model/MFD-color/line5/blue")];
var colorLines  = [getprop("/sim/model/MFD-color/lines/red"), getprop("/sim/model/MFD-color/lines/green"), getprop("/sim/model/MFD-color/lines/blue")];
var colorLines2 = [getprop("/sim/model/MFD-color/lines2/red"), getprop("/sim/model/MFD-color/lines2/green"), getprop("/sim/model/MFD-color/lines2/blue")];


var colorCubeRed = [255,0,0];
var colorCubeGreen = [0,255,0];
var colorCubeCyan = [0,255,255];

var colorBackground = [0,0,0];
if (getprop("sim/variant-id") == 2) {
    colorBackground = [0.01,0.01,0.07, 1];
} else if (getprop("sim/variant-id") == 4) {
    colorBackground = [0.01,0.01,0.07, 1];
} else if (getprop("sim/variant-id") == 5) {
    colorBackground = [0.01,0.01,0.07, 1];
} else if (getprop("sim/variant-id") == 6) {
    colorBackground = [0.01,0.01,0.07, 1];
} else {
    colorBackground = [0.005,0.1,0.005, 1];
}

var slew_c = 0;

var pullup_cue_0 = nil;
var pullup_cue_1 = nil;
var bottomImages = [nil,nil];

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
        dev_canvas.setColorBackground(colorBackground);

        if (model_index == 0) {
            pullup_cue_0 = obj.canvas.createGroup().set("z-index", 20000);
            pullup_cue_0.createChild("path")
               .moveTo(0, 0)
               .lineTo(552*0.795, 482)
               .moveTo(0, 482)
               .lineTo(552*0.795, 0)
               .setStrokeLineWidth(3)
               .setColor(colorLines2);
        } elsif (model_index == 1) {
            pullup_cue_1 = obj.canvas.createGroup().set("z-index", 20000);
            pullup_cue_1.createChild("path")
               .moveTo(0, 0)
               .lineTo(552*0.795, 482)
               .moveTo(0, 482)
               .lineTo(552*0.795, 0)
               .setStrokeLineWidth(3)
               .setColor(colorLines2);
        }

        # Create a group for the parsed elements
        obj.PFDsvg = dev_canvas.createGroup();
        var pres = canvas.parsesvg(obj.PFDsvg, "Nasal/MFD/MFD.svg");
        obj.PFDsvg.set("z-index",1000);

        me.get_element(obj.PFDsvg, "layer2").setColor(colorText1);
        var selectionBoxGroup = dev_canvas.createGroup().set("z-index",1);
        obj.selectionBox = selectionBoxGroup.createChild("path")
            .rect(0,0,35,20)
            .setColorFill(colorText1)
            .show();
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

    setFontSizeMFDEdgeButton: func(index, size) {
        me.PFD.buttons[index].setFontSize(size);
    },

    setTextMFDEdgeButton: func(index, text) {
        me.PFD.buttons[index].setText(text);
    },

    get_element : func(svg, id) {
        var el = svg.getElementById(id);
        if (el == nil)
        {
            print("Failed to locate ",id," in SVG");
            return el;
        }
        var clip_el = svg.getElementById(id ~ "_clip");
        if (clip_el != nil)
        {
            clip_el.setVisible(0);
            var tran_rect = clip_el.getTransformedBounds();

            var clip_rect = sprintf("rect(%d,%d, %d,%d)",
                                   tran_rect[1], # 0 ys
                                   tran_rect[2],  # 1 xe
                                   tran_rect[3], # 2 ye
                                   tran_rect[0]); #3 xs
#            print(id," using clip element ",clip_rect, " trans(",tran_rect[0],",",tran_rect[1],"  ",tran_rect[2],",",tran_rect[3],")");
#   see line 621 of simgear/canvas/CanvasElement.cxx
#   not sure why the coordinates are in this order but are top,right,bottom,left (ys, xe, ye, xs)
            el.set("clip", clip_rect);
            el.set("clip-frame", canvas.Element.PARENT);
        }
        return el;
    },


#  ██    ██  ██████  ██ ██████ 
#  ██    ██ ██    ██ ██ ██   ██ 
#  ██    ██ ██    ██ ██ ██   ██ 
#   ██  ██  ██    ██ ██ ██   ██ 
#    ████    ██████  ██ ██████  
#                              
#
    setupVoid: func (svg) {
        svg.p_VOID = me.canvas.createGroup()
            .set("z-index",0);

        # ehm, Void, so nothing's here
    },

    addVoid: func {
        var svg = {getElementById: func (id) {return me[id]},};
        me.setupVoid(svg);
        me.PFD.addVoidPage = func(svg, title, layer_id) {
            var np = PFD_Page.new(svg, title, layer_id, me);
            append(me.pages, np);
            me.page_index[layer_id] = np;
            np.setVisible(0);
            return np;
        };
        me.p_VOID = me.PFD.addVoidPage(svg, "VOID", "p_VOID");
        me.p_VOID.model_index = me.model_index;
        me.p_VOID.root = svg;
        me.p_VOID.ppp = me.PFD;
        me.p_VOID.my = me;
    },


#   ██████  ██████  ██ ██████ 
#  ██       ██   ██ ██ ██   ██ 
#  ██   ███ ██████  ██ ██   ██ 
#  ██    ██ ██   ██ ██ ██   ██ 
#   ██████  ██   ██ ██ ██████  
#                             
#
    setupGrid: func (svg) {
        svg.p_GRID = me.canvas.createGroup()
            .set("z-index",0);

        svg.cross = svg.p_GRID.createChild("path")
           .moveTo(1*0.795, 1)
           .lineTo(550*0.795, 480)
           .moveTo(550*0.795, 1)
           .lineTo(1*0.795, 480)
           .setColor(colorLines);

        svg.div = svg.p_GRID.createChild("path")
           .moveTo((1+(550/2))*0.795, 1)
           .lineTo((1+(550/2))*0.795, 1+480)
           .moveTo(1, 1+(480/2))
           .lineTo(550*0.795, 1+(480/2))
           .setColor(colorLines);

        svg.block = svg.p_GRID.createChild("path")
            .moveTo((552/2+30)*0.795, 0)
            .lineTo(550*0.795, (482/2-30))
            .moveTo(550*0.795, (482/2+30))
            .lineTo((552/2+30)*0.795, 482)
            .moveTo((552/2-30)*0.795, 482)
            .lineTo(0, (482/2+30))
            .moveTo(0, (482/2-30))
            .lineTo((552/2-30)*0.795, 0)
            .setColor(colorLines);

        svg.box = svg.p_GRID.createChild("path")
            .moveTo((552/3)*0.795, 482/3)
            .lineTo((552/3)*0.795, 482*2/3)
            .lineTo((552*2/3)*0.795, 482*2/3)
            .lineTo((552*2/3)*0.795, 482/3)
            .lineTo((552/3)*0.795, 482/3)
            .setColor(colorLines);
    },

    addGrid: func {
        var svg = {getElementById: func (id) {return me[id]},};
        me.setupGrid(svg);
        me.PFD.addGridPage = func(svg, title, layer_id) {
            var np = PFD_Page.new(svg, title, layer_id, me);
            append(me.pages, np);
            me.page_index[layer_id] = np;
            np.setVisible(0);
            return np;
        };
        me.p_GRID = me.PFD.addGridPage(svg, "GRID", "p_GRID");
        me.p_GRID.model_index = me.model_index;
        me.p_GRID.root = svg;
        me.p_GRID.ppp = me.PFD;
        me.p_GRID.my = me;
    },


#   ██████ ██    ██ ██████  ███████ 
#  ██      ██    ██ ██   ██ ██      
#  ██      ██    ██ ██████  █████ 
#  ██      ██    ██ ██   ██ ██    
#   ██████  ██████  ██████  ███████ 
#                                   
#
    setupCube: func (svg) {
        svg.p_CUBE = me.canvas.createGroup()
            .set("z-index",0)
            .set("font","LiberationFonts/LiberationMono-Regular.ttf");

        svg.lbl = svg.p_CUBE.createChild("path")
            .rect(0,0,175,20)
            .setTranslation((552/2-110)*0.795, 10-3)
            .setColorFill(colorCubeCyan);

        svg.txt = svg.p_CUBE.createChild("text")
            .setTranslation((552/2)*0.795, 10)
            .setText("BUILT-IN TEST")
            .setAlignment("center-top")
            .setFontSize(22, 1.0)
            .setColor(colorBackground);

        svg.rf = svg.p_CUBE.createChild("path")
            .moveTo((552/2)*0.795, 482/2)
            .lineTo((552/2)*0.795, 482/2-100)
            .lineTo((552/2+100)*0.795, 482/2-100+50)
            .lineTo((552/2+100)*0.795, 482/2+50)
            .lineTo((552/2)*0.795, 482/2)
            .setColorFill(colorCubeCyan);

        svg.lf = svg.p_CUBE.createChild("path")
            .moveTo((552/2)*0.795, 482/2)
            .lineTo((552/2)*0.795, 482/2-100)
            .lineTo((552/2-100)*0.795, 482/2-100+50)
            .lineTo((552/2-100)*0.795, 482/2+50)
            .lineTo((552/2)*0.795, 482/2)
            .setColorFill(colorCubeRed);

        svg.bf = svg.p_CUBE.createChild("path")
            .moveTo((552/2)*0.795, 482/2)
            .lineTo((552/2+100)*0.795, 482/2+50)
            .lineTo((552/2)*0.795, 482/2+100)
            .lineTo((552/2-100)*0.795, 482/2+50)
            .lineTo((552/2)*0.795, 482/2)
            .setColorFill(colorCubeGreen);
    },

    addCube: func {
        var svg = {getElementById: func (id) {return me[id]},};
        me.setupCube(svg);
        me.PFD.addCubePage = func(svg, title, layer_id) {
            var np = PFD_Page.new(svg, title, layer_id, me);
            append(me.pages, np);
            me.page_index[layer_id] = np;
            np.setVisible(0);
            return np;
        };
        me.p_CUBE = me.PFD.addCubePage(svg, "CUBE", "p_CUBE");
        me.p_CUBE.model_index = me.model_index;
        me.p_CUBE.root = svg;
        me.p_CUBE.ppp = me.PFD;
        me.p_CUBE.my = me;
    },


#  ██████   █████  ██████   █████  ██████      ███████ ███████ ████████ ██    ██ ██████ 
#  ██   ██ ██   ██ ██   ██ ██   ██ ██   ██     ██      ██         ██    ██    ██ ██   ██ 
#  ██████  ███████ ██   ██ ███████ ██████      ███████ █████      ██    ██    ██ ██████  
#  ██   ██ ██   ██ ██   ██ ██   ██ ██   ██          ██ ██         ██    ██    ██ ██     
#  ██   ██ ██   ██ ██████  ██   ██ ██   ██     ███████ ███████    ██     ██████  ██ 
#                                                                                   
#
    setupRadar: func (svg, index) {
        svg.p_RDR = me.canvas.createGroup()
                .setTranslation(276*0.795,482)
                .set("z-index",2)
                .set("font","LiberationFonts/LiberationMono-Regular.ttf");#552,482 , 0.795 is for UV map
        svg.p_RDR_image = me.canvas.createGroup()
                .setTranslation(276*0.795,482)
                .set("z-index",0)
                .set("font","LiberationFonts/LiberationMono-Regular.ttf");#552,482 , 0.795 is for UV map
        bottomImages[index] = svg.p_RDR_image;
        svg.maxB = 150;
        svg.maxT =  15;
        svg.index = index;
        svg.blep = setsize([],svg.maxB);
        svg.blepTriangle = setsize([],svg.maxT);
        svg.blepTriangleVel = setsize([],svg.maxT);
        svg.blepTriangleVelLine = setsize([],svg.maxT);
        svg.blepTriangleText = setsize([],svg.maxT);
        svg.blepTrianglePaths = setsize([],svg.maxT);
        svg.lnk = setsize([],svg.maxT);
        svg.lnkT = setsize([],svg.maxT+1);
        svg.lnkTA = setsize([],svg.maxT+1);
        svg.iff  = setsize([],svg.maxT);# friendly IFF response
        svg.iffU = setsize([],svg.maxT);# unknown IFF response
        for (var i = 0;i<svg.maxB;i+=1) {
                svg.blep[i] = svg.p_RDR.createChild("path")
                        .moveTo(0,-3)
                        .vert(7)
                        .setStrokeLineWidth(7)
                        .setStrokeLineCap("butt")
                        .set("z-index",10)
                        .hide();
        }
        for (var i = 0;i<svg.maxT;i+=1) {
                svg.blepTriangle[i] = svg.p_RDR.createChild("group")
                                .set("z-index",11);
                svg.blepTriangleVel[i] = svg.blepTriangle[i].createChild("group");
                svg.blepTriangleText[i] = svg.blepTriangle[i].createChild("text")
                                .setAlignment("center-top")
                                .setFontSize(20, 1.0)
                                .setTranslation(0,20)
                                .setColor(1, 1, 1);
                svg.blepTriangleVelLine[i] = svg.blepTriangleVel[i].createChild("path")
                                .lineTo(0,-10)
                                .setTranslation(0,-16)
                                .setStrokeLineWidth(2)
                                .setColor(colorCircle2);
                svg.blepTrianglePaths[i] = svg.blepTriangle[i].createChild("path")
                                .moveTo(-14,8)
                                .horiz(28)
                                .lineTo(0,-16)
                                .lineTo(-14,8)
                                .setColor(colorCircle2)
                                .set("z-index",10)
                                .setStrokeLineWidth(2);
                svg.iff[i] = svg.p_RDR.createChild("path")
                                .moveTo(-8,0)
                                .arcSmallCW(8,8, 0,  8*2, 0)
                                .arcSmallCW(8,8, 0, -8*2, 0)
                                .setColor(colorCircle3)
                                .hide()
                                .set("z-index",12)
                                .setStrokeLineWidth(3);
                svg.iffU[i] = svg.p_RDR.createChild("path")
                                .moveTo(-8,-8)
                                .vert(16)
                                .horiz(16)
                                .vert(-16)
                                .horiz(-16)
                                .setColor(colorCircle2)
                                .hide()
                                .set("z-index",12)
                                .setStrokeLineWidth(3);
                svg.lnk[i] = svg.p_RDR.createChild("path")
                                .moveTo(-10,-10)
                                .vert(20)
                                .horiz(20)
                                .vert(-20)
                                .horiz(-20)
                                .moveTo(0,-10)
                                .vert(-10)
                                .setColor(colorDot1)
                                .hide()
                                .set("z-index",11)
                                .setStrokeLineWidth(3);

            svg.lnkT[i] = svg.p_RDR.createChild("text")
                .setAlignment("center-bottom")
                .setColor(colorDot1)
                .set("z-index",1)
                .setFontSize(20, 1.0);
            svg.lnkTA[i] = svg.p_RDR.createChild("text")
                                .setAlignment("center-top")
                                .setFontSize(20, 1.0);
        }
        svg.gainGauge = svg.p_RDR.createChild("path")
                    .moveTo(-552*0.5*0.65,-482*0.95)
                    .horiz(-20)
                    .vert(65)
                    .horiz(20)
                    .setStrokeLineWidth(3)
                    .set("z-index",1)
                    .setColor(colorText1);
        svg.gainGaugePointer = svg.p_RDR.createChild("path")
                    .setTranslation(-552*0.5*0.65-20,-482*0.95+10)
                    .lineTo(10,-10)
                    .moveTo(0,0)
                    .lineTo(10, 10)
                    .setStrokeLineWidth(3)
                    .set("z-index",1)
                    .setColor(colorText1);
        svg.rangUp = svg.p_RDR.createChild("path")
                    .moveTo(-276*0.775,-482*0.5-95-20.5)
                    .horiz(30)
                    .lineTo(-276*0.775+15,-482*0.5-95-20.5-20)
                    .lineTo(-276*0.775,-482*0.5-95-20.5)
                    .setStrokeLineWidth(3)
                    .set("z-index",1)
                    .setColor(colorText1);
        svg.rang = svg.p_RDR.createChild("text")
                .setTranslation(-276*0.770, -482*0.5-95)
                .setAlignment("left-center")
                .setColor(colorText1)
                .set("z-index",1)
                .setFontSize(20, 1.0);
        svg.rangDown = svg.p_RDR.createChild("path")
                    .moveTo(-276*0.775,-482*0.5-95+20.5)
                    .horiz(30)
                    .lineTo(-276*0.775+15,-482*0.5-95+20.5+20)
                    .lineTo(-276*0.775,-482*0.5-95+20.5)
                    .setStrokeLineWidth(3)
                    .set("z-index",1)
                    .setColor(colorText1);


        svg.ant_bottom = svg.p_RDR.createChild("path")
                    .moveTo(-276*0.795,-25)
                    .vert(-13)
                    .moveTo(-276*0.795-8,-38)
                    .horiz(15)
                    .setStrokeLineWidth(5)
                    .set("z-index",1)
                    .setColor(colorLine1);
        svg.ant_side = svg.p_RDR.createChild("path")
                    .moveTo(-276*0.795+40,-482*0.5)
                    .horiz(-13)
                    .moveTo(-276*0.795+40,-482*0.5-7)
                    .vert(14)
                    .setStrokeLineWidth(5)
                    .set("z-index",1)
                    .setColor(colorLine1);
        var vari = getprop("sim/variant-id");
        if (vari < 2 or vari == 3) {
            svg.distl = svg.p_RDR.createChild("path")
                        .moveTo(-276*0.795+40,-482*0.25)
                        .horiz(15)
                        .moveTo(-276*0.795+40,-482*0.5)
                        .horiz(25)
                        .moveTo(-276*0.795+40,-482*0.75)
                        .horiz(15)
                        .moveTo(-276*0.795*0.5,-40)
                        .vert(-15)
                        .moveTo(0,-40)
                        .vert(-25)
                        .moveTo(276*0.795*0.5,-40)
                        .vert(-15)
                        .setStrokeLineWidth(3)
                        .set("z-index",1)
                        .setColor(colorLine1);
        } else {
            svg.distl = svg.p_RDR.createChild("path")
                    .moveTo(-276*0.795+40,-482*0.25)
                    .horiz(12.5)
                    .moveTo(-276*0.795+40,-482*0.3333)
                    .horiz(12.5)
                    .moveTo(-276*0.795+40,-482*0.4166)
                    .horiz(12.5)
                    .moveTo(-276*0.795+40,-482*0.5)
                    .horiz(20.0)
                    .moveTo(-276*0.795+40,-482*0.5833)
                    .horiz(12.5)
                    .moveTo(-276*0.795+40,-482*0.6666)
                    .horiz(12.5)
                    .moveTo(-276*0.795+40,-482*0.75)
                    .horiz(12.5)
                    .moveTo(-276*0.795*0.5,-40)
                    .vert(-12.5)
                    .moveTo(-276*0.795*0.3333,-40)
                    .vert(-12.5)
                    .moveTo(-276*0.795*0.1666,-40)
                    .vert(-12.5)
                    .moveTo(0,-40)
                    .vert(-20.0)
                    .moveTo(276*0.795*0.3333,-40)
                    .vert(-12.5)
                    .moveTo(276*0.795*0.1666,-40)
                    .vert(-12.5)
                    .moveTo(276*0.795*0.5,-40)
                    .vert(-12.5)
                    .setStrokeLineWidth(3)
                    .set("z-index",1)
                    .setColor(colorLine1);
        }

        svg.selection = svg.p_RDR.createChild("group")
                .set("z-index",12);
        svg.selectionPath = svg.selection.createChild("path")
                .moveTo(-16, 0)
                .arcSmallCW(16, 16, 0, 16*2, 0)
                .arcSmallCW(16, 16, 0, -16*2, 0)
                .setColor(colorDot1)
                .setStrokeLineWidth(2);

        svg.lockInfo = svg.p_RDR.createChild("text")
                .setTranslation(276*0.795*0.85, -482*0.9)
                .setAlignment("right-center")
                .setColor(colorLine3)
                .set("z-index",1)
                .setFontSize(20, 1.0);

        svg.interceptCross = svg.p_RDR.createChild("path")
                            .moveTo(10,0)
                            .lineTo(-10,0)
                            .moveTo(0,-10)
                            .vert(20)
                            .setColor(colorCircle2)
                            .set("z-index",14)
                            .setStrokeLineWidth(2);

        svg.lockGM = svg.p_RDR.createChild("path")
                            .moveTo(10,0)
                            .lineTo(0,10)
                            .lineTo(-10,0)
                            .lineTo(0,-10)
                            .lineTo(10,0)
                            .setColorFill(colorCircle2)
                            .setColor(colorCircle2)
                            .set("z-index",20)
                            .setStrokeLineWidth(2);

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
           .setColor(colorLine3)
           .set("z-index",1)
           .setStrokeLineWidth(svg.dlzLW);
        svg.az1 = svg.p_RDR.createChild("path")
           .moveTo(0, 0)
           .lineTo(0, -482)
           .setColor(colorLine1)
           .set("z-index",13)
           .setStrokeLineWidth(2);
        svg.az2 = svg.p_RDR.createChild("path")
           .moveTo(0, 0)
           .lineTo(0, -482)
           .setColor(colorLine1)
           .set("z-index",13)
           .setStrokeLineWidth(2);
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
           .setColor(colorLine2)
           .set("z-index",15)
           .setStrokeLineWidth(3);
        svg.silent = svg.p_RDR.createChild("text")
           .setTranslation(0, -482*0.25)
           .setAlignment("center-center")
           .setText("SILENT")
           .set("z-index",16)
           .setFontSize(18, 1.0)
           .setColor(colorText2);
        svg.bitText = svg.p_RDR.createChild("text")
           .setTranslation(0, -482*0.75)
           .setAlignment("center-center")
           .setText("    VERSION C021-IPOO-MRO3258674  ")
           .set("z-index",16)
           .setFontSize(18, 1.0)
           .setColor(colorText2);

		svg.notSOI = svg.p_RDR.createChild("text")
           .setTranslation(0, -482*0.55)
           .setAlignment("center-center")
           .setText("NOT SOI")
           .set("z-index",16)
		   .hide()
           .setFontSize(18, 1.0)
           .setColor(colorText2);
        svg.exp = svg.p_RDR.createChild("path")
            .moveTo(-100,-100)
            .vert(200)
            .horiz(200)
            .vert(-200)
            .horiz(-200)
            .setStrokeLineWidth(2.0)
            .setColor(colorLine4)
            .set("z-index",1)
            .hide();


        # OBS 13
        svg.norm = svg.p_RDR.createChild("text")
                .setTranslation(276*0.795*0.0, -482*0.5-225)
                .setText("NORM")
                .setAlignment("center-top")
                .setColor(colorText1)
                .set("z-index",1)
                .setFontSize(18, 1.0);
        # OBS 12
        svg.acm = svg.p_RDR.createChild("text")
                .setTranslation(276*0.795*-0.30, -482*0.5-225)
                .setText("ACM")
                .setAlignment("center-top")
                .setColor(colorText1)
                .hide()
                .setFontSize(18, 1.0);
        # OBS 9
        svg.cz = svg.p_RDR.createChild("text")
                .setTranslation(276*0.775, -482*0.5+55+10)
                .setText("C\nZ")
                .setAlignment("right-center")
                .setColor(colorText1)
                .set("z-index",1)
                .setFontSize(20, 1.0);
        # OBS 10
        svg.hd = svg.p_RDR.createChild("text")
                .setTranslation(276*0.775, -482*0.5+125+10)
                .setText("H\nD")
                .setAlignment("right-center")
                .setColor(colorText1)
                .set("z-index",1)
                .setFontSize(20, 1.0);
        # OBS 4
        svg.bars = svg.p_RDR.createChild("text")
                .setTranslation(-276*0.775, -482*0.5+75)
                .setText("8B")
                .setAlignment("left-center")
                .setColor(colorText1)
                .set("z-index",1)
                .setFontSize(20, 1.0);
        # OBS 3
        svg.az = svg.p_RDR.createChild("text")
                .setTranslation(-276*0.775, -482*0.5+10)
                .setText("A4")
                .setAlignment("left-center")
                .setColor(colorText1)
                .set("z-index",1)
                .setFontSize(20, 1.0);
        # OBS 8
        svg.sp = svg.p_RDR.createChild("text")
                .setTranslation(276*0.775, -482*0.5+10)
                .setText("S\nP")
                .setAlignment("right-center")
                .setColor(colorText1)
                .set("z-index",1)
                .setFontSize(20, 1.0);
        # OBS 11
        svg.mod = svg.p_RDR.createChild("text")
                .setTranslation(276*0.795*-0.71, -482*0.5-215)
                .setText("CRM")
                .setAlignment("top-center")
                .setColor(colorText1)
                .set("z-index",20000)
                .setFontSize(20, 1.0);
        # OBS 5
        svg.M  = svg.p_RDR.createChild("text")
                .setTranslation(-276*0.795+10, -482*0.5+125+10)
                .setText("M")
                .setAlignment("left-center")
                .setColor(colorText1)
                .set("z-index",2)
                .setFontSize(20, 1.0);
        svg.modBox = svg.p_RDR.createChild("path")
                .setTranslation(-276*0.795, -482*0.5+125)
                .moveTo(5,0)
                .horiz(35)
                .vert(20)
                .horiz(-35)
                .vert(-20)
                .setColorFill(colorText1)
                .setColor(colorText1)
                .set("z-index",1);

        svg.cursor = svg.p_RDR.createChild("group").set("z-index",1000);
        svg.cursorAir = svg.cursor.createChild("path")
                    .moveTo(-8,-9)
                    .vert(18)
                    .moveTo(8,-9)
                    .vert(18)
                    .setStrokeLineWidth(2.0)
                    .setColor(colorLine3);
        svg.cursorGm = svg.cursor.createChild("path")
                    .moveTo(0, 11)
                    .vert(500)
                    .moveTo(0, -11)
                    .vert(-500)
                    .moveTo(11,0)
                    .horiz(500)
                    .moveTo(-11,0)
                    .horiz(-500)
                    .setStrokeLineWidth(2.0)
                    .setColor(colorLine3);
        svg.cursorGmTicks = svg.cursor.createChild("path")
                    .moveTo(50, 5)
                    .vert(-10)
                    .moveTo(-50, 5)
                    .vert(-10)
                    .moveTo(5,50)
                    .horiz(-10)
                    .moveTo(5,-50)
                    .horiz(-10)
                    .setStrokeLineWidth(2.0)
                    .setColor(colorLine3);
        svg.cursor_1 = svg.cursor.createChild("text")
                .setTranslation(10,-5)
                .setText("37")
                .setAlignment("left-bottom")
                .setColor(colorLine3)
                .setFontSize(18, 1.0);
        svg.cursor_2 = svg.cursor.createChild("text")
                .setTranslation(10, 5)
                .setText("12")
                .setAlignment("left-top")
                .setColor(colorLine3)
                .setFontSize(18, 1.0);

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
            .setStrokeLineWidth(3)
            .set("z-index",1)
            .setColor(colorBullseye);
        svg.steerpoint = svg.p_RDR.createChild("path")
            .moveTo(12,8)
            .horiz(-24)
            .vert(-8)
            .horiz(8)
            .vert(-8)
            .horiz(8)
            .vert(8)
            .horiz(8)
            .vert(8)
            .setColorFill(colorBullseye)
            .setStrokeLineWidth(1)
            .set("z-index",1)
            .setColor(colorBullseye);
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
            .setStrokeLineWidth(2.5)
            .setStrokeLineCap("round")
            .setTranslation(-190, -50)
            .set("z-index",1)
            .setColor(colorBullseye);
        svg.bullOwnDist = svg.p_RDR.createChild("text")
                .setAlignment("center-center")
                .setColor(colorBullseye)
                .setTranslation(-190, -50)
                .setText("12")
                .set("z-index",1)
                .setFontSize(18, 1.0);
        svg.bullOwnDir = svg.p_RDR.createChild("text")
                .setAlignment("center-top")
                .setColor(colorBullseye)
                .setTranslation(-190, -30)
                .setText("270")
                .set("z-index",1)
                .setFontSize(18, 1.0);
        svg.cursorLoc = svg.p_RDR.createChild("text")
                .setAlignment("left-bottom")
                .setColor(colorBetxt)
                .setTranslation(-200, -75)
                .setText("12")
                .set("z-index",1)
                .setFontSize(18, 1.0);

        # canvas: 552*0.795,482
        svg.rangeRingLow = svg.p_RDR.createChild("path")
            .moveTo(-552*0.795*0.25,0)
            .arcSmallCW(552*0.795*0.25,482*0.25, 0,  552*0.795*0.5, 0)
            .arcSmallCW(552*0.795*0.25,482*0.25, 0, -552*0.795*0.5, 0)
            .setStrokeLineWidth(2)
            .set("z-index",1)
            .setColor(colorLines);
        svg.rangeRingMid = svg.p_RDR.createChild("path")
            .moveTo(-552*0.795*0.5,0)
            .arcSmallCW(552*0.795*0.5,482*0.5, 0,  552*0.795, 0)
            .arcSmallCW(552*0.795*0.5,482*0.5, 0, -552*0.795, 0)
            .setStrokeLineWidth(2)
            .set("z-index",1)
            .setColor(colorLines);
        svg.rangeRingHigh = svg.p_RDR.createChild("path")
            .moveTo(-552*0.795*0.75,0)
            .arcSmallCW(552*0.795*0.75,482*0.75, 0,  552*0.795*1.5, 0)
            .arcSmallCW(552*0.795*0.75,482*0.75, 0, -552*0.795*1.5, 0)
            .setStrokeLineWidth(2)
            .set("z-index",1)
            .setColor(colorLines);
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
        me.p_RDR.model_index = me.model_index;
        me.p_RDR.root = svg;
        me.p_RDR.wdt = 552*0.795;
        me.p_RDR.fwd = 0;
        me.p_RDR.plc = 0;
        me.p_RDR.ppp = me.PFD;
        me.p_RDR.my = me;
        me.p_RDR.gmLine = 64;
        me.p_RDR.elapsed = 0;
        me.p_RDR.pressEXP = 0;
        me.p_RDR.gmMin = 0;
        me.p_RDR.gmMax = 1500;
        me.p_RDR.gmMintemp = 5000;
        me.p_RDR.gmMaxtemp = 300;
        me.p_RDR.rdrModeHDGM = 0;
        me.p_RDR.beamSpot = geo.Coord.new();
        me.p_RDR.terrain = geo.Coord.new();
        me.p_RDR.gmColor = 0;
        me.p_RDR.selectionBox = me.selectionBox;
        me.p_RDR.setSelectionColor = me.setSelectionColor;
        me.p_RDR.resetColor = me.resetColor;
        me.p_RDR.setSelection = me.setSelection;
        me.p_RDR.slew_c_last = slew_c;
        me.p_RDR.notifyButton = func (eventi) {
            if (eventi != nil) {
                if (eventi == 0) {
                    radar_system.apg68Radar.increaseRange();
                } elsif (eventi == 1) {
                    radar_system.apg68Radar.decreaseRange();
                } elsif (eventi == 10) {
                    if (me["DGFT"]) return;
                    me.ppp.selectPage(me.my.r_LIST);
                    me.resetColor(me.ppp.buttons[10]);
                    me.selectionBox.hide();
                } elsif (eventi == 4) {
                    #me.ppp.selectPage(me.my.rm_LIST);
                    #me.resetColor(me.ppp.buttons[4]);
                    #me.selectionBox.hide();
                } elsif (eventi == 17) {
                    me.ppp.selectPage(me.my.p_SMS);
                    me.setSelection(me.ppp.buttons[10], me.ppp.buttons[17], 17);
                } elsif (eventi == 18) {
                    me.ppp.selectPage(me.my.p_WPN);
                    me.setSelection(me.ppp.buttons[10], me.ppp.buttons[18], 18);
                #} elsif (eventi == 18) {
                #    me.ppp.selectPage(me.my.pjitds_1);
                } elsif (eventi == 16) {
                    me.ppp.selectPage(me.my.p_HSD);
                    me.setSelection(me.ppp.buttons[10], me.ppp.buttons[16], 16);
                } elsif (eventi == 13) {
                    me.ppp.selectPage(me.my.rm_LIST);
                    me.setSelection(me.ppp.buttons[10], me.ppp.buttons[13], 13);
                } elsif (eventi == 12) {
                    me.pressEXP = 1;
                } elsif (eventi == 11) {
                    if (!radar_system.apg68Radar.currentMode.detectAIR) {
                        radar_system.apg68Radar.currentMode.toggleAuto();
                    } else {
                        radar_system.apg68Radar.cycleMode();
                    }
                } elsif (eventi == 2) {
                    radar_system.apg68Radar.cycleAZ();
                } elsif (eventi == 3) {
                    radar_system.apg68Radar.cycleBars();
                } elsif (eventi == 8) {
                    cursorZero();
                } elsif (eventi == 9) {
                    #if (rdrMode != RADAR_MODE_GM) return;
                    #setprop("instrumentation/radar/mode-hd-switch", me.model_index);
                } elsif (eventi == 15) {
                    swap();
                } elsif (eventi == 19) {
                    if(getprop("f16/stores/tgp-mounted") and !getprop("/fdm/jsbsim/gear/unit[0]/WOW")) {
                        screen.log.write("Click BACK to get back to cockpit view",1,1,1);
                        switchTGP();
                    }
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


#  ██████   █████  ██████   █████  ██████      ██    ██ ██████  ██████   █████  ████████ ███████ 
#  ██   ██ ██   ██ ██   ██ ██   ██ ██   ██     ██    ██ ██   ██ ██   ██ ██   ██    ██    ██      
#  ██████  ███████ ██   ██ ███████ ██████      ██    ██ ██████  ██   ██ ███████    ██    █████ 
#  ██   ██ ██   ██ ██   ██ ██   ██ ██   ██     ██    ██ ██      ██   ██ ██   ██    ██    ██    
#  ██   ██ ██   ██ ██████  ██   ██ ██   ██      ██████  ██      ██████  ██   ██    ██    ███████ 
#                                                                                                
#
        me.p_RDR.update = func (noti) {

            me.root.p_RDR_image.setVisible(radar_system.apg68Radar.enabled);
            me.DGFT = noti.getproper("dgft");
            me.IMSOI = 0;
			if (f16.SOI == 3 and me.model_index == 1) {
				me.root.notSOI.hide();
                me.IMSOI = 1;
			} elsif (f16.SOI == 2 and me.model_index == 0) {
				me.root.notSOI.hide();
                me.IMSOI = 1;
			} else {
				me.root.notSOI.show();
			}

            me.modeSw = noti.getproper("rdrMode");

            setprop("instrumentation/radar/mode-switch", 0);

            me.modeSwHD = noti.getproper("rdrHD");


            me.root.acm.setText(radar_system.apg68Radar.currentMode.shortName);
            me.root.acm.setColor(colorText1);
            me.root.mod.setText(radar_system.apg68Radar.currentMode.rootName);
            me.root.mod.setColor(0,0,0);
            me.root.modBox.hide();
            me.root.hd.hide();

            #
            # GM range rings
            #
            if (!radar_system.apg68Radar.currentMode.detectAIR and !exp) {
                #me.root.sp.show();
                me.root.sp.hide();
                me.root.rangeRingHigh.setVisible(radar_system.apg68Radar.getRange()>10);
                me.root.rangeRingMid.setVisible(radar_system.apg68Radar.getRange()>5);
                me.root.rangeRingLow.setVisible(radar_system.apg68Radar.getRange()>10);
            } else {
                me.root.sp.hide();
                me.root.rangeRingHigh.hide();
                me.root.rangeRingMid.hide();
                me.root.rangeRingLow.hide();
            }

            #
            # Bulls-eye info on FCR
            #
            me.bullPt = steerpoints.getNumber(555);
            me.bullOn = me.bullPt != nil;
            if (me.bullOn) {
                me.bullLat = me.bullPt.lat;
                me.bullLon = me.bullPt.lon;
                me.bullCoord = geo.Coord.new().set_latlon(me.bullLat,me.bullLon);
                me.ownCoord = geo.aircraft_position();
                me.bullDirToMe = me.bullCoord.course_to(me.ownCoord);
                me.meToBull = ((me.bullDirToMe+180)-noti.getproper("heading"))*D2R;
                me.root.bullOwnRing.setRotation(me.meToBull);
                me.bullDistToMe = me.bullCoord.distance_to(me.ownCoord)*M2NM;
                me.distPixels = me.bullDistToMe*(482/radar_system.apg68Radar.getRange());
                me.bullPos = me.calcPos(me.wdt, geo.normdeg180(me.meToBull*R2D), me.distPixels);

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

            if (systime() - iff.last_interogate < 3.5) {
                # IFF ongoing
                me.root.M.setText("M4");
            } else {
                me.root.M.setText("M");
            }

            if (me.DGFT or !radar_system.apg68Radar.currentMode.EXPsupport or (radar_system.apg68Radar.getPriorityTarget() != nil and radar_system.apg68Radar.currentMode.EXPfixedAim)) {
                exp = 0;
                me.root.norm.hide();
            } elsif (me.pressEXP) {
                me.pressEXP = 0;
                exp = !exp;
                me.root.norm.show();
            } else {
                me.root.norm.show();
            }
            if (exp and radar_system.apg68Radar.currentMode.longName == radar_system.gmMode.longName) {
                me.cursorDev   = -math.atan2(-cursor_pos[0]/(482), -cursor_pos[1]/482)*R2D;
                me.cursorDist  = (math.sqrt(cursor_pos[0]*cursor_pos[0]+cursor_pos[1]*cursor_pos[1])/(482/radar_system.apg68Radar.getRange()));
                radar_system.apg68Radar.currentMode.setExp(1);
                radar_system.apg68Radar.currentMode.setExpPosition(me.cursorDev, me.cursorDist);
            } elsif (radar_system.apg68Radar.currentMode.longName == radar_system.gmMode.longName) {
                radar_system.apg68Radar.currentMode.setExp(0);
            }
            if (exp) {
                me.root.norm.setText("EXP");
                me.root.exp.setTranslation(cursor_pos);
            } else {
                me.root.norm.setText("NORM");
            }
            me.exp_zoom = exp;# should really be the only variable for this
            me.root.exp.setVisible(exp and !radar_system.apg68Radar.currentMode.EXPfixedAim);
            me.root.acm.setVisible(1);
            me.root.horiz.setRotation(-radar_system.self.getRoll()*D2R);

            if (radar_system.apg68Radar.currentMode.longName == radar_system.vsMode.longName) {
                me.root.distl.setScale(-1,1);
            } else {
                me.root.distl.setScale( 1,1);
            }
            me.root.distl.show();

            if (radar_system.apg68Radar.enabled) {
                if (1) {
                    # radar carets

                    me.caretPosition = radar_system.apg68Radar.getCaretPosition();
                    me.root.ant_bottom.setTranslation(me.wdt*0.5+me.caretPosition[0]*me.wdt*0.5,0);
                    me.root.ant_side.setTranslation(0,-me.caretPosition[1]*482*0.5);

                    me.root.ant_bottom.show();
                    me.root.ant_side.show();
                } else {
                    me.root.ant_bottom.hide();
                    me.root.ant_side.hide();
                }
                me.root.silent.hide();
            } elsif (noti.getproper("fcrBit") == 2) {
                me.root.silent.setText("SILENT");
                me.root.silent.setVisible(!getprop("/fdm/jsbsim/gear/unit[0]/WOW") or !getprop("instrumentation/radar/radar-enable"));
            } elsif (noti.getproper("fcrBit") == 1) {
                me.fcrBITsecs = (1.0-noti.getproper("fcrWarm"))*120;
                me.root.silent.setText(sprintf("  BIT TIME REMAINING IS %-3d SEC", me.fcrBITsecs));
                me.root.silent.show();
            } elsif (noti.getproper("fcrBit") == 0) {
                me.root.silent.setText("  OFF  ");
                me.root.silent.show();
            }

            if (noti.getproper("fcrBit") == 1) {
                me.root.silent.setTranslation(0, -482*0.825);
                me.root.bitText.show();
            } else {
                me.root.silent.setTranslation(0, -482*0.25);
                me.root.bitText.hide();
            }

            # This is old cursor system for clicking in 3D
            #if (uv != nil and me.root.index == uv[2]) {
            #    if (systime()-uv[3] < 0.5) {
            #        # the time check is to prevent click on other pages to carry over to CRM when that is selected.
            #        cursor_destination = uv;
            #    }
            #    uv = nil;
            #}

            me.exp_modi = exp?(radar_system.apg68Radar.currentMode.EXPfixedAim?0.20:0.25):1.00;# slow down cursor movement when in zoom mode

            me.slew_x = getprop("controls/displays/target-management-switch-x[" ~ me.model_index ~ "]")*me.exp_modi;
            me.slew_y = -getprop("controls/displays/target-management-switch-y[" ~ me.model_index ~ "]")*me.exp_modi;

            if (noti.getproper("viewName") != "TGP" and me.IMSOI) {
                f16.resetSlew();
            }

            #me.dt = math.min(noti.getproper("elapsed") - me.elapsed, 0.05);
            me.dt = noti.getproper("elapsed") - me.elapsed;

            if ((me.slew_x != 0 or me.slew_y != 0 or slew_c != 0) and (cursor_lock == -1 or cursor_lock == me.root.index) and noti.getproper("viewName") != "TGP") {
                cursor_destination = nil;
                cursor_pos[0] += me.slew_x*175;
                cursor_pos[1] -= me.slew_y*175;
                cursor_pos[0] = math.clamp(cursor_pos[0], -552*0.5*0.795, 552*0.5*0.795);
                cursor_pos[1] = math.clamp(cursor_pos[1], -482, 0);
                cursor_click = (slew_c and !me.slew_c_last)?me.root.index:-1;
                cursor_lock = me.root.index;
            } elsif (cursor_lock == me.root.index or (me.slew_x == 0 or me.slew_y == 0 or slew_c == 0)) {
                cursor_lock = -1;
            }
            me.slew_c_last = slew_c;
            slew_c = 0;

            # This is old cursor system for clicking in 3D, part 2
            #if (cursor_destination != nil and cursor_destination[2] == me.root.index) {
            #    me.slew = 100*me.dt;
            #    if (cursor_destination[0] > cursor_pos[0]) {
            #        cursor_pos[0] += me.slew;
            #        if (cursor_destination[0] < cursor_pos[0]) {
            #            cursor_pos[0] = cursor_destination[0]
            #        }
            #    } elsif (cursor_destination[0] < cursor_pos[0]) {
            #        cursor_pos[0] -= me.slew;
            #        if (cursor_destination[0] > cursor_pos[0]) {
            #            cursor_pos[0] = cursor_destination[0]
            #        }
            #    }
            #    if (cursor_destination[1] > cursor_pos[1]) {
            #        cursor_pos[1] += me.slew;
            #        if (cursor_destination[1] < cursor_pos[1]) {
            #            cursor_pos[1] = cursor_destination[1]
            #        }
            #    } elsif (cursor_destination[1] < cursor_pos[1]) {
            #        cursor_pos[1] -= me.slew;
            #        if (cursor_destination[1] > cursor_pos[1]) {
            #            cursor_pos[1] = cursor_destination[1]
            #        }
            #    }
            #    cursor_lock = me.root.index;
            #    if (cursor_destination[0] == cursor_pos[0] and cursor_destination[1] == cursor_pos[1]) {
            #        cursor_click = me.root.index;
            #    }
            #}
            me.elapsed = noti.getproper("elapsed");

            if (radar_system.apg68Radar.currentMode.detectAIR) {
                radar_system.apg68Radar.setCursorDeviation(cursor_pos[0]*60/(me.wdt*0.5));

                if (radar_system.apg68Radar.setCursorDistance(-cursor_pos[1]/(482/radar_system.apg68Radar.getRange()))) {
                    # the cursor was Y centered due to changing range
                    cursor_pos[1] = -482*0.5;
                    radar_system.apg68Radar.setCursorDistance(-cursor_pos[1]/(482/radar_system.apg68Radar.getRange()))
                }
            } else {
                radar_system.apg68Radar.setCursorDeviation(-math.atan2(-cursor_pos[0]/(482), -cursor_pos[1]/482)*R2D);

                # The real range not used since its only for giving cursor limits (not used in GM) and we want linear switching range:
                #  if (radar_system.apg68Radar.setCursorDistance((math.sqrt(cursor_pos[0]*cursor_pos[0]+cursor_pos[1]*cursor_pos[1])/(482/radar_system.apg68Radar.getRange())))) {
                if (radar_system.apg68Radar.setCursorDistance(-cursor_pos[1]/(482/radar_system.apg68Radar.getRange()))) {
                    # the cursor was Y centered due to changing range
                    cursor_pos[1] = -482*0.5;
                    radar_system.apg68Radar.setCursorDistance(-cursor_pos[1]/(482/radar_system.apg68Radar.getRange()))
                }
            }
            me.fixedEXPwidth = nil;
            var pixelPerNM = nil;

            if (!exp or !radar_system.apg68Radar.currentMode.EXPfixedAim) {
                me.root.cursor.setTranslation(cursor_pos);
            } else {
                me.root.cursor.setTranslation([0,-241]);
                me.fixedEXPwidth = radar_system.apg68Radar.currentMode.getEXPsize();
                pixelPerNM = 482/radar_system.apg68Radar.getRange();
            }
            me.alimits = radar_system.apg68Radar.getCursorAltitudeLimits();
            if (me.alimits != nil and radar_system.apg68Radar.currentMode.detectAIR) {
                me.root.cursor_1.setText(sprintf("% 2d",math.round(me.alimits[0]*0.001)));
                me.root.cursor_2.setText(sprintf("% 2d",math.round(me.alimits[1]*0.001)));
                if (me.alimits[0] >= 0) {
                    me.root.cursor_1.setColor(colorLine3);
                } else {
                    me.root.cursor_1.setColor(colorCircle1);
                }
                if (me.alimits[1] >= 0) {
                    me.root.cursor_2.setColor(colorLine3);
                } else {
                    me.root.cursor_2.setColor(colorCircle1);
                }
            } else {
                me.root.cursor_1.setText("");
                me.root.cursor_2.setText("");
            }
            me.root.cursorAir.setVisible(radar_system.apg68Radar.currentMode.detectAIR);
            me.root.cursorGm.setVisible(!radar_system.apg68Radar.currentMode.detectAIR);
            me.root.cursorGmTicks.setVisible(!radar_system.apg68Radar.currentMode.detectAIR and !exp);

            if (me.bullOn) {
                if (radar_system.apg68Radar.currentMode.detectAIR) {
                    me.cursorDev   = cursor_pos[0]*60/(me.wdt*0.5);
                    me.cursorDist  = -NM2M*cursor_pos[1]/(482/radar_system.apg68Radar.getRange());
                } else {
                    # TODO: verify this is correct:
                    me.cursorDev   = -math.atan2(-cursor_pos[0]/(482), -cursor_pos[1]/482)*R2D;
                    me.cursorDist  = NM2M*(math.sqrt(cursor_pos[0]*cursor_pos[0]+cursor_pos[1]*cursor_pos[1])/(482/radar_system.apg68Radar.getRange()));
                }
                me.ownCoord.apply_course_distance(noti.getproper("heading")+me.cursorDev, me.cursorDist);
                me.cursorBullDist = me.ownCoord.distance_to(me.bullCoord);
                me.cursorBullCrs  = me.bullCoord.course_to(me.ownCoord);
                me.root.cursorLoc.setText(sprintf("%03d %03d",me.cursorBullCrs, me.cursorBullDist*M2NM));
            }
            me.root.cursorLoc.setVisible(me.bullOn);



            me.root.az1.setVisible(radar_system.apg68Radar.showAZ());
            me.root.az2.setVisible(radar_system.apg68Radar.showAZ());
            me.root.bars.setVisible(radar_system.apg68Radar.currentMode.showBars());
            me.root.az.setVisible(1);
            if (noti.FrameCount != 1 and noti.FrameCount != 3)
                return;
            me.root.rang.setText(sprintf("%d",radar_system.apg68Radar.getRange()));
            me.root.rang.setVisible(radar_system.apg68Radar.currentMode.longName != radar_system.vsMode.longName);
            me.i=0;

            var a = 0;
            if (radar_system.apg68Radar.getAzimuthRadius() < 20) {
                a = 1;
            } elsif (radar_system.apg68Radar.getAzimuthRadius() < 30) {
                a = 2;
            } elsif (radar_system.apg68Radar.getAzimuthRadius() < 40) {
                a = 3;
            } elsif (radar_system.apg68Radar.getAzimuthRadius() < 50) {
                a = 4;
            } elsif (radar_system.apg68Radar.getAzimuthRadius() < 60) {
                a = 5;
            } elsif (radar_system.apg68Radar.getAzimuthRadius() < 70) {
                a = 6;
            }
            me.root.az.setText("A"~a);
            #if (radar_system.apg68Radar.showBars()) {
                me.root.bars.setText(radar_system.apg68Radar.getBars()~"B");
            #} else {
            #    me.root.bars.setText("");
            #}
            if (radar_system.apg68Radar.currentMode.detectAIR) {
                me.root.az1.setTranslation((radar_system.apg68Radar.currentMode.azimuthTilt-radar_system.apg68Radar.currentMode.az)*me.wdt*0.5/60,0);
                me.root.az2.setTranslation((radar_system.apg68Radar.currentMode.azimuthTilt+radar_system.apg68Radar.currentMode.az)*me.wdt*0.5/60,0);
                me.root.az1.setRotation(0);
                me.root.az2.setRotation(0);
            } else {
                me.root.az1.setTranslation(0, 0);
                me.root.az2.setTranslation(0, 0);
                var angle2 = D2R*(radar_system.apg68Radar.currentMode.azimuthTilt+radar_system.apg68Radar.currentMode.az);
                var angle1 = D2R*(radar_system.apg68Radar.currentMode.azimuthTilt-radar_system.apg68Radar.currentMode.az);
                me.root.az1.setRotation(angle2);
                me.root.az2.setRotation(angle1);
            }
            #me.root.lock.hide();
            #me.root.lockGM.hide();


            # The distance in pixels from cursor that stuff should be zoomed
            if (me.fixedEXPwidth != nil) {
                me.closeDef = pixelPerNM*me.fixedEXPwidth*0.5;
            } else {
                me.closeDef = 25; # pixels
            }

            #
            # Bulls-eye position on FCR
            #
            if (me.bullOn) {
                me.bullPos = me.calcEXPPos(me.bullPos);
                if (me.bullPos == nil) {
                    me.bullOn = 0;
                }
            }
            me.root.bullseye.setVisible(me.bullOn);
            if (me.bullOn) {
                me.root.bullseye.setTranslation(me.bullPos);
            }

            #
            # Current steerpoint on FCR
            #
            if (steerpoints.getCurrentNumber() != 0) {
                me.wpC = steerpoints.getCurrentCoord();
                if (me.wpC == nil) {
                    printf("Error occured in FCR steerpoint system: STPT:%d WAYP:%d NUM:%d - please report this error to F16 devs:",steerpoints.getCurrentNumber(),noti.getproper("currentWP"),noti.getproper("maxWP"));
                }
                me.legBearing = geo.normdeg180(geo.aircraft_position().course_to(me.wpC)-noti.getproper("heading"));#relative
                me.legDistance = geo.aircraft_position().distance_to(me.wpC)*M2NM;
                me.distPixels = me.legDistance*(482/radar_system.apg68Radar.getRange());
                me.steerPos = me.calcPos(me.wdt, me.legBearing, me.distPixels);
                var vis = 1;
                me.steerPos = me.calcEXPPos(me.steerPos);
                if (me.steerPos == nil) {
                    vis = 0;
                } else {
                    me.root.steerpoint.setTranslation(me.steerPos);
                }
                me.root.steerpoint.setVisible(vis);
            } else {
                me.root.steerpoint.setVisible(0);
            }



#  ██████   █████  ██████   █████  ██████      ██████  ██      ███████ ██████  ███████ 
#  ██   ██ ██   ██ ██   ██ ██   ██ ██   ██     ██   ██ ██      ██      ██   ██ ██      
#  ██████  ███████ ██   ██ ███████ ██████      ██████  ██      █████   ██████  ███████ 
#  ██   ██ ██   ██ ██   ██ ██   ██ ██   ██     ██   ██ ██      ██      ██           ██ 
#  ██   ██ ██   ██ ██████  ██   ██ ██   ██     ██████  ███████ ███████ ██      ███████ 
#                                                                                      
#
            me.desig_new = nil;
            #me.gm_echoPos = {};
            me.ijk = 0;
            me.intercept = nil;
            me.showDLT = 0;
            me.prio = radar_system.apg68Radar.getPriorityTarget();
            me.tracks = [];
            me.elapsed = noti.getproper("elapsed");
            me.selectShow = 0;
            me.selectShowGM = 0;
            me.lockInfo = 0;
            me.i = 0;
            me.ii = 0;
            me.iii = 0;
            me.iiii = 0;

            me.randoo = rand();

            if (radar_system.datalink_power.getBoolValue() and radar_system.apg68Radar.currentMode.longName != radar_system.vsMode.longName and radar_system.apg68Radar.currentMode["painter"] != 1) {
                foreach(contact; vector_aicontacts_links) {
                    if (contact["blue"] != 1) continue;
                    me.paintDL(contact, noti);
                    contact.randoo = me.randoo;
                }
            }
            if (radar_system.apg68Radar.enabled) {
                if (!radar_system.apg68Radar.currentMode.painter) {
                    #me.wind = getprop("environment/wind-speed-kt");
                    #me.chaffLifetime = math.max(0, me.wind==0?25:25*(1-me.wind/50));
                    foreach(var chaff; radar_system.apg68Radar.getActiveChaff()) {
                        me.paintChaff(chaff);
                    }
                }
                foreach(contact; radar_system.apg68Radar.getActiveBleps()) {
                    if (contact["randoo"] == me.randoo) continue;

                    me.paintRdr(contact);
                    contact.randoo = me.randoo;
                }
            }
            if (radar_system.datalink_power.getBoolValue() and radar_system.apg68Radar.currentMode.longName != radar_system.vsMode.longName and !radar_system.apg68Radar.currentMode.painter) {
                foreach(contact; vector_aicontacts_links) {
                    me.paintRdr(contact);
                    contact.randoo = me.randoo;
                }
            }

            me.root.selection.setVisible(me.selectShow);
            me.root.selection.update();
            me.root.lockGM.setVisible(me.selectShowGM);
            me.root.lockGM.update();
            me.root.lockInfo.setVisible(me.lockInfo);
            for (;me.i < me.root.maxB;me.i+=1) {
                me.root.blep[me.i].hide();
            }
            for (;me.ii < me.root.maxT;me.ii+=1) {
                me.root.blepTriangle[me.ii].hide();
            }
            for (;me.iii < me.root.maxT;me.iii+=1) {
                me.root.lnk[me.iii].hide();
                me.root.lnkT[me.iii].hide();
                me.root.lnkTA[me.iii].hide();
            }
            for (;me.iiii < me.root.maxT;me.iiii+=1) {
                me.root.iff[me.iiii].hide();
                me.root.iffU[me.iiii].hide();
            }
            #
            # Intercept steering point for designated target
            #
            if (radar_system.apg68Radar.getPriorityTarget() != nil) {
                me.lastHead = radar_system.apg68Radar.getPriorityTarget().getLastHeading();
                if (me.lastHead != nil and radar_system.apg68Radar.getPriorityTarget().getType() == radar_system.AIR) {
                    # we cheat a bit here with getting current properties:
                    me.intercept = get_intercept(radar_system.apg68Radar.getPriorityTarget().get_bearing(),
                     radar_system.apg68Radar.getPriorityTarget().get_range()*NM2M, me.lastHead,
                      radar_system.apg68Radar.getPriorityTarget().get_Speed()*KT2MPS,
                       noti.getproper("groundspeed_kt")*KT2MPS, geo.aircraft_position(), radar_system.self.getHeading());
                }
            }
            if (me.intercept != nil) {
                me.interceptCoord = me.intercept[2];
                me.interceptDist = me.intercept[3];
                me.distPixels = me.interceptDist*M2NM*(482/radar_system.apg68Radar.getRange());
                me.echoPos = [me.wdt*0.5*geo.normdeg180(me.intercept[4])/60,-me.distPixels];
                me.root.interceptCross.setTranslation(me.echoPos);
                me.root.interceptCross.setVisible(1);
            } else {
                me.root.interceptCross.setVisible(0);
            }
            if (cursor_click == me.root.index) {
                if (me.desig_new == nil) {
                    radar_system.apg68Radar.undesignate();
                } else {
                    radar_system.apg68Radar.designate(me.desig_new);
                }
                cursor_destination = nil;
                cursor_click = -1;
            }


            #
            # The dynamic launch zone indicator on FCR
            #
            me.root.dlzArray = pylons.getDLZ();
            #me.dlzArray =[10,8,6,2,9];#test
            if (me.root.dlzArray == nil or size(me.root.dlzArray) == 0) {
                    me.root.dlz.hide();
            } else {
                #printf("%d %d %d %d %d",me.root.dlzArray[0],me.root.dlzArray[1],me.root.dlzArray[2],me.root.dlzArray[3],me.root.dlzArray[4]);
                me.root.dlz2.removeAllChildren();
                me.root.dlzArrow.setTranslation(0,-me.root.dlzArray[4]/me.root.dlzArray[0]*me.root.dlzHeight);
                me.root.dlzGeom = me.root.dlz2.createChild("path")
                        .moveTo(me.root.dlzWidth, 0)
                        .horiz(-me.root.dlzWidth)
                        .lineTo(0, -me.root.dlzArray[3]/me.root.dlzArray[0]*me.root.dlzHeight)
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
                        .setColor(colorLine3);
                me.root.dlz2.update();
                me.root.dlz.show();
            }

            if (radar_system.apg68Radar.getRange() == radar_system.apg68Radar.currentMode.minRange or !radar_system.apg68Radar.currentMode.showRangeOptions()) {
                me.root.rangDown.hide();
            } else {
                me.root.rangDown.show();
            }

            if (radar_system.apg68Radar.getRange() == radar_system.apg68Radar.currentMode.maxRange or !radar_system.apg68Radar.currentMode.showRangeOptions()) {
                me.root.rangUp.hide();
            } else {
                me.root.rangUp.show();
            }

            if (radar_system.apg68Radar.currentMode.mapper) {
                if (me["gmImage"] == nil) {
                    #setprop("a",0.8732);
                    var sized = 64;
                    var scaled = 512/sized;
                    me.gmImage = me.root.p_RDR_image.createChild("image")
                        .set("src", "Aircraft/f16/Nasal/MFD/gmSD0.png")# index is due to else the two MFD will share the underlying image and both write to it.
                        .setTranslation(-552*0.5*0.8732,-482)# canvas: 552,482
                        .setCenter(sized*0.5, -sized)# the 0.8732 factor is due to angles not drawn correct due to uneven coordinate system. TODO: fix.
                        .setScale(scaled*1.078125*0.8732,scaled*0.9414)
                        #.setTranslation(-512*0.5,-512)
                        #.setScale(8,8)
                        .set("z-index",0);#TODO: lower than GM text background
                    var vari = noti.getproper("variantID");
                    me.mono = (vari<2 or vari ==3)?0.4:1;
                    me.gainNode = me.model_index?props.globals.getNode("f16/avionics/mfd-l-gain",0):props.globals.getNode("f16/avionics/mfd-l-gain",0);
                    radar_system.mapper.setImage(me.gmImage, sized*0.5, 0, sized, me.mono, me.gainNode);
                }
                #me.gmImage.setScale(8*1.078125*getprop("a"),8*0.9414).setTranslation(-552*0.5*getprop("a"),-482);

                me.root.gainGaugePointer.setTranslation(-552*0.5*0.65-20,me.interpolate(me.gainNode.getValue(), 1.0, 2.5,-482*0.95+10,-482*0.95-10+65));
                me.root.gainGaugePointer.show();
                me.root.gainGauge.show();
                me.gmImage.show();
            } elsif (me["gmImage"] != nil) {
                me.gmImage.hide();
                me.root.gainGaugePointer.hide();
                me.root.gainGauge.hide();
            } else {
                me.root.gainGaugePointer.hide();
                me.root.gainGauge.hide();
            }
        };
        me.p_RDR.interpolate = func (x, x1, x2, y1, y2) {
            return math.clamp(y1 + ((x - x1) / (x2 - x1)) * (y2 - y1),y1,y2);
        };


#  ██████   █████  ██ ███    ██ ████████     ██████  ██████  ██████      ██████  ██      ███████ ██████  ███████ 
#  ██   ██ ██   ██ ██ ████   ██    ██        ██   ██ ██   ██ ██   ██     ██   ██ ██      ██      ██   ██ ██      
#  ██████  ███████ ██ ██ ██  ██    ██        ██████  ██   ██ ██████      ██████  ██      █████   ██████  ███████ 
#  ██      ██   ██ ██ ██  ██ ██    ██        ██   ██ ██   ██ ██   ██     ██   ██ ██      ██      ██           ██ 
#  ██      ██   ██ ██ ██   ████    ██        ██   ██ ██████  ██   ██     ██████  ███████ ███████ ██      ███████ 
#                                                                                                                
#
        me.p_RDR.paintDL = func (contact, noti) {
            if (contact.blue != 1) return;
            if (contact["iff"] != nil) {
                if (contact.iff > 0 and me.elapsed-contact.iff < 3.5) {
                    me.iff = 1;
                } elsif (contact.iff < 0 and me.elapsed+contact.iff < 3.5) {
                    me.iff = -1;
                } else {
                    me.iff = 0;
                }
            } else {
                me.iff = 0;
            }

            me.blueBearing = geo.normdeg180(contact.getDeviationHeading());
            if (me.iff == 0 and contact.isVisible() and contact.getRange()*M2NM < 80 and me.iii < me.root.maxT and math.abs(me.blueBearing) < 60) {
                me.distPixels = contact.get_range()*(482/(radar_system.apg68Radar.getRange()));
                me.echoPos = me.calcPos(me.wdt, geo.normdeg180(me.blueBearing), me.distPixels);
                me.echoPos = me.calcEXPPos(me.echoPos);
                if (me.echoPos == nil) {
                    return;
                }
                me.root.lnkT[me.iii].setColor(colorDot4);
                me.root.lnkT[me.iii].setTranslation(me.echoPos[0],me.echoPos[1]-25);
                me.root.lnkT[me.iii].setText(""~contact.blueIndex);
                me.root.lnkT[me.iii].show();
                me.root.lnkTA[me.iii].setColor(colorDot4);
                me.root.lnkTA[me.iii].setTranslation(me.echoPos[0],me.echoPos[1]+20);
                me.root.lnkTA[me.iii].setText(""~math.round(contact.getAltitude()*0.001));
                me.root.lnkTA[me.iii].show();
                me.root.lnk[me.iii].setColor(colorDot4);
                me.root.lnk[me.iii].setTranslation(me.echoPos);
                me.root.lnk[me.iii].setRotation(D2R*22.5*math.round( geo.normdeg(contact.get_heading()-noti.getproper("heading")-me.blueBearing)/22.5 ));#Show rotation in increments of 22.5 deg
                me.root.lnk[me.iii].show();
                me.root.lnk[me.iii].update();
                if (contact.equalsFast(radar_system.apg68Radar.getPriorityTarget())) {
                    me.selectShow = contact.getType() == radar_system.AIR;
                    me.selectShowGM = !me.selectShow;
                    me.root.selection.setTranslation(me.echoPos);
                    me.root.selection.setColor(colorDot4);
                    me.root.lockGM.setTranslation(me.echoPos);
                    me.root.lockGM.setColor(colorDot4);
                    me.printInfo(contact);
                }
                me.calcClick(contact, me.echoPos);
                me.iii += 1;
            } elsif (me.iff != 0 and contact.isVisible() and me.iiii < me.root.maxT and math.abs(me.blueBearing) < 60) {
                me.distPixels = contact.get_range()*(482/(radar_system.apg68Radar.getRange()));
                me.echoPos = me.calcPos(me.wdt, geo.normdeg180(me.blueBearing), me.distPixels);
                me.echoPos = me.calcEXPPos(me.echoPos);
                if (me.echoPos == nil) {
                    return;
                }
                me.path = me.iff == -1?me.root.iffU[me.iiii]:me.root.iff[me.iiii];
                me.pathHide = me.iff == 1?me.root.iffU[me.iiii]:me.root.iff[me.iiii];
                me.pathHide.hide();
                me.path.setTranslation(me.echoPos[0],me.echoPos[1]-18);
                me.path.show();

                me.iiii += 1;
            }
        };
        me.p_RDR.calcPos = func (width, dev, distPixels) {
            if (radar_system.apg68Radar.currentMode.detectAIR) {
                # B-Scope
                me.echoPosition = [width*0.5*dev/60,-distPixels];
            } else {
                # PPI-Scope
                me.echoPosition = [(552*0.795)*(distPixels/482)*math.sin(D2R*dev), -distPixels*math.cos(D2R*dev)];
            }
            return me.echoPosition;
        };
        me.p_RDR.calcEXPPos = func (itemPos) {
            # Calculate the position taking EXP zoom into account
            var returnPos = itemPos;
            var cursorCentre = [0,-241];
            me.close = math.abs(cursor_pos[0] - itemPos[0]) < me.closeDef and math.abs(cursor_pos[1] - itemPos[1]) < me.closeDef;
            if (me.close and me.exp_zoom) {
                if (me.fixedEXPwidth != nil) {
                    # EXP with fixed cursor
                    returnPos[0] = cursorCentre[0]+math.abs(cursorCentre[1])*(itemPos[0] - cursor_pos[0])/me.closeDef;
                    returnPos[1] = cursorCentre[1]+math.abs(cursorCentre[1])*(itemPos[1] - cursor_pos[1])/me.closeDef;
                } else {
                    # EXP with moving cursor
                    returnPos[0] = cursor_pos[0]+(itemPos[0] - cursor_pos[0])*4;
                    returnPos[1] = cursor_pos[1]+(itemPos[1] - cursor_pos[1])*4;
                }
            } elsif (me.exp_zoom and (me.fixedEXPwidth != nil or math.abs(cursor_pos[0] - itemPos[0]) < 100 and math.abs(cursor_pos[1] - itemPos[1]) < 100)) {
                returnPos = nil;
            }
            return returnPos;
        };
        me.p_RDR.calcClick = func (contact, echoPos) {
            if (cursor_click == me.root.index) {
                var cursor_posi = !me.exp_zoom or me.fixedEXPwidth == nil?cursor_pos:[0,-241];
                if (math.abs(cursor_posi[0] - echoPos[0]) < 10 and math.abs(cursor_posi[1] - echoPos[1]) < 11) {
                    me.desig_new = contact;
                }
            }
        };
        me.p_RDR.printInfo = func (contact) {
            if (contact.getLastHeading() != nil) {
                me.azimuth = math.round(geo.normdeg180(contact.get_bearing()-contact.getLastHeading())*0.1)*10;
                if (me.azimuth == 180 or me.azimuth == 0) {
                    me.azSide = " ";
                } else {
                    me.azSide = me.azimuth > 0 ?"L":"R";
                }
                me.azimuth = sprintf("%3d%s", math.abs(me.azimuth), me.azSide);
                me.magn = geo.normdeg(contact.getLastHeading()+radar_system.self.getHeadingMag()-radar_system.self.getHeading());
                me.heady = sprintf("%3d", int(me.magn/10)*10);
            } else {
                me.azimuth = "    ";
                me.heady = "   ";
            }
            if (contact.getLastClosureRate() != 0) {
                me.clos = sprintf("%+4dK",math.round(contact.getLastClosureRate()*0.1)*10);
            } else {
                me.clos = "      ";
            }

            me.lockInfoText = sprintf("%s     %s        %4d   %s", me.azimuth, me.heady, contact.get_Speed(), me.clos);

            me.root.lockInfo.setText(me.lockInfoText);
            me.lockInfo = 1;
        };
        me.p_RDR.paintRdr = func (contact) {
            if (contact["iff"] != nil) {
                if (contact.iff > 0 and me.elapsed-contact.iff < 3.5) {
                    me.iff = 1;
                } elsif (contact.iff < 0 and me.elapsed+contact.iff < 3.5) {
                    me.iff = -1;
                } else {
                    me.iff = 0;
                }
            } else {
                me.iff = 0;
            }
            me.bleps = contact.getBleps();
            foreach(me.bleppy ; me.bleps) {
                if (me.i < me.root.maxB and me.elapsed - me.bleppy.getBlepTime() < radar_system.apg68Radar.currentMode.timeToFadeBleps and me.bleppy.getDirection() != nil and (radar_system.apg68Radar.currentMode.longName != radar_system.vsMode.longName or (me.bleppy.getClosureRate() != nil and me.bleppy.getClosureRate()>0))) {
                    if (me.bleppy.getClosureRate() != nil and radar_system.apg68Radar.currentMode.longName == radar_system.vsMode.longName) {
                        me.distPixels = math.min(950, me.bleppy.getClosureRate())*(482/(1000));
                    } else {
                        me.distPixels = me.bleppy.getRangeNow()*(482/(radar_system.apg68Radar.getRange()*NM2M));
                    }
                    me.echoPos = me.calcPos(me.wdt, geo.normdeg180(me.bleppy.getAZDeviation()), me.distPixels);
                    me.echoPos = me.calcEXPPos(me.echoPos);
                    if (me.echoPos == nil) {
                        continue;
                    }
                    me.color = math.pow(1-(me.elapsed - me.bleppy.getBlepTime())/radar_system.apg68Radar.currentMode.timeToFadeBleps, 2.2);
                    me.root.blep[me.i].setTranslation(me.echoPos);
                    me.root.blep[me.i].setColor(colorDot2[0]*me.color+colorBackground[0]*(1-me.color), colorDot2[1]*me.color+colorBackground[1]*(1-me.color), colorDot2[2]*me.color+colorBackground[2]*(1-me.color));
                    me.root.blep[me.i].show();
                    me.root.blep[me.i].update();
                    if (contact.equalsFast(radar_system.apg68Radar.getPriorityTarget()) and me.bleppy == me.bleps[size(me.bleps)-1]) {
                        me.selectShowTemp = radar_system.apg68Radar.currentMode.longName != radar_system.twsMode.longName or (me.elapsed - contact.getLastBlepTime() < radar_system.F16TWSMode.timeToBlinkTracks) or (math.mod(me.elapsed,0.50)<0.25);
                        me.selectShow = me.selectShowTemp and contact.getType() == radar_system.AIR;
                        me.selectShowGM = me.selectShowTemp and contact.getType() != radar_system.AIR;
                        me.root.selection.setTranslation(me.echoPos);
                        me.root.selection.setColor(colorCircle2);
                        me.root.lockGM.setTranslation(me.echoPos);
                        me.root.lockGM.setColor(colorCircle2);
                        me.printInfo(contact);
                        me.lockInfo = 1;
                    }
                    if (me.elapsed - me.bleppy.getBlepTime() < radar_system.apg68Radar.currentMode.timeToFadeBleps) {
                        me.calcClick(contact, me.echoPos);
                    }
                    me.i += 1;
                }
            }
            me.sizeBleps = size(me.bleps);
            if (contact["blue"] != 1 and me.ii < me.root.maxT and ((me.sizeBleps and contact.hadTrackInfo()) or contact["blue"] == 2) and me.iff == 0 and radar_system.apg68Radar.currentMode.longName != radar_system.vsMode.longName) {
                # Paint bleps with tracks
                if (contact["blue"] != 2) me.bleppy = me.bleps[me.sizeBleps-1];
                if (contact["blue"] == 2 or (me.bleppy.hasTrackInfo() and me.elapsed - me.bleppy.getBlepTime() < radar_system.apg68Radar.timeToKeepBleps)) {
                    me.color = contact["blue"] == 2?colorCircle1:colorCircle2;
                    if (contact["blue"] == 2) {
                        me.c_heading    = contact.getHeading();
                        me.c_devheading = contact.getDeviationHeading();
                        me.c_speed      = contact.getSpeed();
                        me.c_alt        = contact.getAltitude();
                        me.distPixels   = contact.getRange()*(482/(radar_system.apg68Radar.getRange()*NM2M));
                    } else {
                        me.c_heading    = me.bleppy.getHeading();
                        me.c_devheading = me.bleppy.getAZDeviation();
                        me.c_speed      = me.bleppy.getSpeed();
                        me.c_alt        = me.bleppy.getAltitude();
                        me.distPixels   = me.bleppy.getRangeNow()*(482/(radar_system.apg68Radar.getRange()*NM2M));
                    }
                    me.rot = 22.5*math.round((me.c_heading-radar_system.self.getHeading()-me.c_devheading)/22.5);
                    me.root.blepTrianglePaths[me.ii].setRotation(me.rot*D2R);
                    me.root.blepTrianglePaths[me.ii].setColor(me.color);
                    me.echoPos = me.calcPos(me.wdt, geo.normdeg180(me.c_devheading), me.distPixels);
                    me.echoPos = me.calcEXPPos(me.echoPos);
                    if (me.echoPos == nil) {
                        return;
                    }
                    if (contact["blue"] == 2 and me.iii < me.root.maxT) {
                        me.root.lnkT[me.iii].setColor(me.color);
                        me.root.lnkT[me.iii].setTranslation(me.echoPos[0],me.echoPos[1]-25);
                        me.root.lnkT[me.iii].setText(""~contact.blueIndex);
                        me.root.lnkT[me.iii].show();
                        me.iii += 1;
                    }
                    me.root.blepTriangle[me.ii].setTranslation(me.echoPos);
                    if (me.c_speed != nil and me.c_speed > 0) {
                        me.root.blepTriangleVelLine[me.ii].setScale(1,me.c_speed*0.0045);
                        me.root.blepTriangleVelLine[me.ii].setColor(me.color);
                        me.root.blepTriangleVel[me.ii].setRotation(me.rot*D2R);
                        me.root.blepTriangleVel[me.ii].update();
                        me.root.blepTriangleVel[me.ii].show();
                    } else {
                        me.root.blepTriangleVel[me.ii].hide();
                    }
                    if (me.c_alt != nil) {
                        me.root.blepTriangleText[me.ii].setText(""~math.round(me.c_alt*0.001));
                        me.root.blepTriangleText[me.ii].setColor(me.color);
                    } else {
                        me.root.blepTriangleText[me.ii].setText("");
                    }
                    me.blinkShow = radar_system.apg68Radar.currentMode.longName != radar_system.twsMode.longName or (me.elapsed - contact.getLastBlepTime() < radar_system.F16TWSMode.timeToBlinkTracks) or (math.mod(me.elapsed,0.50)<0.25);
                    if (contact.equalsFast(radar_system.apg68Radar.getPriorityTarget())) {
                        me.selectShow = me.blinkShow and contact.getType() == radar_system.AIR;
                        me.selectShowGM = me.blinkShow and contact.getType() != radar_system.AIR;
                        me.root.blepTriangle[me.ii].setVisible(me.selectShow);
                        me.root.selection.setTranslation(me.echoPos);
                        me.root.selection.setColor(me.color);
                        me.root.lockGM.setTranslation(me.echoPos);
                        me.root.lockGM.setColor(me.color);
                        me.printInfo(contact);
                        me.lockInfo = 1;
                    }
                    me.root.blepTriangle[me.ii].setVisible(me.blinkShow and contact.getType() == radar_system.AIR);
                    me.root.blepTriangle[me.ii].update();
                    me.calcClick(contact, me.echoPos);

                    me.ii += 1;
                }
            } elsif (me.iff != 0 and contact["blue"] != 1 and contact.isVisible() and me.iiii < me.root.maxT and me.sizeBleps and radar_system.apg68Radar.currentMode.longName != radar_system.vsMode.longName) {
                # Paint IFF symbols
                me.bleppy = me.bleps[me.sizeBleps-1];
                if (me.elapsed - me.bleppy.getBlepTime() < radar_system.apg68Radar.timeToKeepBleps) {
                    me.echoPos = me.calcPos(me.wdt, geo.normdeg180(me.bleppy.getAZDeviation()), me.distPixels);
                    me.echoPos = me.calcEXPPos(me.echoPos);
                    if (me.echoPos == nil) {
                        return;
                    }
                    me.path = me.iff == -1?me.root.iffU[me.iiii]:me.root.iff[me.iiii];
                    me.pathHide = me.iff == 1?me.root.iffU[me.iiii]:me.root.iff[me.iiii];
                    me.pathHide.hide();
                    me.path.setTranslation(me.echoPos[0],me.echoPos[1]-18);
                    me.path.show();
                    me.iiii += 1;
                }
            }
        };
        me.p_RDR.paintChaff = func (chaff) {
            #if (me.chaffLifetime == 0) return;
            if (me.i < me.root.maxB and radar_system.apg68Radar.currentMode.longName != radar_system.vsMode.longName) {
                me.distPixels = chaff.meters*(482/(radar_system.apg68Radar.getRange()*NM2M));

                me.echoPos = me.calcPos(me.wdt, geo.normdeg180(chaff.bearing - radar_system.self.getHeading()), me.distPixels);
                me.echoPos = me.calcEXPPos(me.echoPos);
                if (me.echoPos == nil) {
                    return;
                }
                #me.color = math.pow(math.max(0, rand()-(me.elapsed - chaff.seenTime)/me.chaffLifetime), 2.2);
                me.color = math.pow(math.max(0, 0.8-(me.elapsed - chaff.seenTime)/radar_system.apg68Radar.currentMode.timeToFadeBleps), 2.2);

                if (chaff["rand1"] == nil) {
                    chaff.rand1 = rand();
                    chaff.rand2 = rand();
                    chaff.rand3 = rand();
                    chaff.rand4 = rand();
                }
                me.echoPos1 = [me.echoPos[0]+chaff.rand1*8-4, me.echoPos[1]-chaff.rand2*3];
                me.root.blep[me.i].setTranslation(me.echoPos1);
                me.root.blep[me.i].setColor(colorDot2[0]*me.color+colorBackground[0]*(1-me.color), colorDot2[1]*me.color+colorBackground[1]*(1-me.color), colorDot2[2]*me.color+colorBackground[2]*(1-me.color));
                me.root.blep[me.i].show();
                me.root.blep[me.i].update();

                me.i += 1;
                if (me.i < me.root.maxB) {
                    me.echoPos2 = [me.echoPos[0]+chaff.rand3*8-4, me.echoPos[1]-chaff.rand4*3];
                    me.root.blep[me.i].setTranslation(me.echoPos2);
                    me.root.blep[me.i].setColor(colorDot2[0]*me.color+colorBackground[0]*(1-me.color), colorDot2[1]*me.color+colorBackground[1]*(1-me.color), colorDot2[2]*me.color+colorBackground[2]*(1-me.color));
                    me.root.blep[me.i].show();
                    me.root.blep[me.i].update();

                    me.i += 1;
                }
            }
        };
    },

#  ██      ██ ███████ ████████ 
#  ██      ██ ██         ██    
#  ██      ██ ███████    ██    
#  ██      ██      ██    ██    
#  ███████ ██ ███████    ██    
#                              
#                              
    setupList: func(svg) {
        svg.p_LIST = me.canvas.createGroup()
            .set("z-index",2)
            .setTranslation(276*0.795,482)
            .set("font","LiberationFonts/LiberationMono-Regular.ttf");#552,482 , 0.795 is for UV map
    },
    addList: func {
        var svg = {getElementById: func (id) {return me[id]},};
        me.setupList(svg);
        me.PFD.addListPage = func(svg, title, layer_id) {
            var np = PFD_Page.new(svg, title, layer_id, me);
            append(me.pages, np);
            me.page_index[layer_id] = np;
            np.setVisible(0);
            return np;
        };
        me.p_LIST = me.PFD.addListPage(svg, "LIST", "p_LIST");
        me.p_LIST.model_index = me.model_index;
        me.p_LIST.root = svg;
        me.p_LIST.wdt = 552*0.795;
        me.p_LIST.fwd = 0;
        me.p_LIST.plc = 0;
        me.p_LIST.ppp = me.PFD;
        me.p_LIST.my = me;
        me.p_LIST.selectionBox = me.selectionBox;
        me.p_LIST.setSelectionColor = me.setSelectionColor;
        me.p_LIST.resetColor = me.resetColor;
        me.p_LIST.setSelection = me.setSelection;
        me.p_LIST.notifyButton = func (eventi) {
            if (eventi != nil) {

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
                if (eventi == 0) {
                    me.ppp.selectPage(me.my.p_RDR);
                    me.selectionBox.show();
                    me.setSelection(nil, me.ppp.buttons[10], 10);
                } elsif (eventi == 1) {
                    if(getprop("f16/stores/tgp-mounted") and !getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
                        screen.log.write("Click BACK to get back to cockpit view",1,1,1);
                        switchTGP();
                    }
                } elsif (eventi == 2) {
                    me.ppp.selectPage(me.my.p_WPN);
                    me.selectionBox.show();
                    me.setSelection(nil, me.ppp.buttons[18], 18);
                } elsif (eventi == 5) {
                    me.ppp.selectPage(me.my.p_SMS);
                    me.selectionBox.show();
                    me.setSelection(nil, me.ppp.buttons[17], 17);
                } elsif (eventi == 6) {
                    me.ppp.selectPage(me.my.p_HSD);
                    me.selectionBox.show();
                    me.setSelection(nil, me.ppp.buttons[16], 16);
                } elsif (eventi == 7) {
                    me.ppp.selectPage(me.my.p_DTE);
                    me.selectionBox.show();
                    me.setSelection(nil, me.ppp.buttons[7], 7);
                } elsif (eventi == 11) {
                    me.ppp.selectPage(me.my.p_HARM);
                    me.selectionBox.show();
                    me.setSelection(nil, me.ppp.buttons[10], 10);
                } elsif (eventi == 15) {
                    swap();
                }
            }
        };
        me.p_LIST.update = func (noti) {
            if (bottomImages[me.model_index] != nil) bottomImages[me.model_index].hide();
        };
    },

#  ██████  ████████ ███████ 
#  ██   ██    ██    ██      
#  ██   ██    ██    █████   
#  ██   ██    ██    ██      
#  ██████     ██    ███████ 
#                           
#                           
    setupDTE: func(svg) {
        svg.p_DTE = me.canvas.createGroup()
            .set("z-index",2)
            .setTranslation(276*0.795,482)
            .set("font","LiberationFonts/LiberationMono-Regular.ttf");#552,482 , 0.795 is for UV map


    },
    addDTE: func {
        var svg = {getElementById: func (id) {return me[id]},};
        me.setupDTE(svg);
        me.PFD.addRListPage = func(svg, title, layer_id) {
            var np = PFD_Page.new(svg, title, layer_id, me);
            append(me.pages, np);
            me.page_index[layer_id] = np;
            np.setVisible(0);
            return np;
        };
        me.p_DTE = me.PFD.addListPage(svg, "DTE", "p_DTE");
        me.p_DTE.model_index = me.model_index;
        me.p_DTE.root = svg;
        me.p_DTE.wdt = 552*0.795;
        me.p_DTE.fwd = 0;
        me.p_DTE.plc = 0;
        me.p_DTE.ppp = me.PFD;
        me.p_DTE.my = me;
        me.p_DTE.selectionBox = me.selectionBox;
        me.p_DTE.setSelectionColor = me.setSelectionColor;
        me.p_DTE.resetColor = me.resetColor;
        me.p_DTE.setSelection = me.setSelection;
        var defaultDirInFileSelector = getprop("/sim/fg-home") ~ "/Export";
        var load_stpts = func(path) {
                        steerpoints.loadSTPTs(path.getValue());
                    };
        var save_stpts = func(path) {
                        steerpoints.saveSTPTs(path.getValue());
                    };
        me.p_DTE.save_selector_dtc = gui.FileSelector.new(
                      callback: save_stpts, title: "Save data cartridge", button: "Save",
                      dir: defaultDirInFileSelector, dotfiles: 1, file: "mission-data.f16dtc", pattern: ["*.f16dtc"]);            
        me.p_DTE.file_selector_dtc = gui.FileSelector.new(
                      callback: load_stpts, title: "Load data cartridge", button: "Load",
                      dir: defaultDirInFileSelector, dotfiles: 1, pattern: ["*.f16dtc"]);
        me.p_DTE.notifyButton = func (eventi) {
            if (eventi != nil) {

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
                if (eventi == 7) {
                    me.ppp.selectPage(me.my.p_LIST);
                    me.resetColor(me.ppp.buttons[7]);
                    me.selectionBox.hide();
                } elsif (eventi == 1) {#LOAD
                    me.file_selector_dtc.open();
                    #file_selector_dtc.del();
                } elsif (eventi == 3) {#SAVE
                    me.save_selector_dtc.open();
                    #save_selector_dtc.del();
                } elsif (eventi == 15) {
                    swap();
                }
            }
        };
        me.p_DTE.update = func (noti) {
            if (bottomImages[me.model_index] != nil) bottomImages[me.model_index].hide();
        };
    },

#  ██████   █████  ██████   █████  ██████      ███    ███  ██████  ██████  ███████     ██      ██ ███████ ████████ 
#  ██   ██ ██   ██ ██   ██ ██   ██ ██   ██     ████  ████ ██    ██ ██   ██ ██          ██      ██ ██         ██    
#  ██████  ███████ ██   ██ ███████ ██████      ██ ████ ██ ██    ██ ██   ██ █████       ██      ██ ███████    ██ 
#  ██   ██ ██   ██ ██   ██ ██   ██ ██   ██     ██  ██  ██ ██    ██ ██   ██ ██          ██      ██      ██    ██ 
#  ██   ██ ██   ██ ██████  ██   ██ ██   ██     ██      ██  ██████  ██████  ███████     ███████ ██ ███████    ██ 
#                                                                                                               
#
    setupRList: func(svg) {
        svg.r_LIST = me.canvas.createGroup()
            .set("z-index",2)
            .setTranslation(276*0.795,482)
            .set("font","LiberationFonts/LiberationMono-Regular.ttf");#552,482 , 0.795 is for UV map


    },
    addRList: func {
        var svg = {getElementById: func (id) {return me[id]},};
        me.setupRList(svg);
        me.PFD.addRListPage = func(svg, title, layer_id) {
            var np = PFD_Page.new(svg, title, layer_id, me);
            append(me.pages, np);
            me.page_index[layer_id] = np;
            np.setVisible(0);
            return np;
        };
        me.r_LIST = me.PFD.addListPage(svg, "Radar Mode", "r_LIST");
        me.r_LIST.model_index = me.model_index;
        me.r_LIST.root = svg;
        me.r_LIST.wdt = 552*0.795;
        me.r_LIST.fwd = 0;
        me.r_LIST.plc = 0;
        me.r_LIST.ppp = me.PFD;
        me.r_LIST.my = me;
        me.r_LIST.selectionBox = me.selectionBox;
        me.r_LIST.setSelectionColor = me.setSelectionColor;
        me.r_LIST.resetColor = me.resetColor;
        me.r_LIST.setSelection = me.setSelection;
        me.r_LIST.notifyButton = func (eventi) {
            if (eventi != nil) {

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
                if (eventi == 0) {
                    radar_system.apg68Radar.setRootMode(0);
                    me.ppp.selectPage(me.my.p_RDR);
                    me.selectionBox.show();
                    me.setSelection(nil, me.ppp.buttons[10], 10);
                } elsif (eventi == 1) {
                    radar_system.apg68Radar.setRootMode(1,radar_system.apg68Radar.getPriorityTarget());
                    me.ppp.selectPage(me.my.p_RDR);
                    me.selectionBox.show();
                    me.setSelection(nil, me.ppp.buttons[10], 10);
                } elsif (eventi == 2) {
                    radar_system.apg68Radar.setRootMode(2);
                    me.ppp.selectPage(me.my.p_RDR);
                    me.selectionBox.show();
                    me.setSelection(nil, me.ppp.buttons[10], 10);
                } elsif (eventi == 3) {
                    radar_system.apg68Radar.setRootMode(3);
                    me.ppp.selectPage(me.my.p_RDR);
                    me.selectionBox.show();
                    me.setSelection(nil, me.ppp.buttons[10], 10);
                } elsif (eventi == 4) {
                    radar_system.apg68Radar.setRootMode(4);
                    me.ppp.selectPage(me.my.p_RDR);
                    me.selectionBox.show();
                    me.setSelection(nil, me.ppp.buttons[10], 10);
                } elsif (eventi == 15) {
                    swap();
                }
            }
        };
        me.r_LIST.update = func (noti) {
            if (bottomImages[me.model_index] != nil) bottomImages[me.model_index].hide();
        };
    },



#   ██████ ███    ██ ████████ ██          ██████   █████   ██████  ███████ 
#  ██      ████   ██    ██    ██          ██   ██ ██   ██ ██       ██      
#  ██      ██ ██  ██    ██    ██          ██████  ███████ ██   ███ █████ 
#  ██      ██  ██ ██    ██    ██          ██      ██   ██ ██    ██ ██    
#   ██████ ██   ████    ██    ███████     ██      ██   ██  ██████  ███████ 
#                                                                          
#
    setupRMList: func(svg) {
        svg.rm_LIST = me.canvas.createGroup()
            .set("z-index",2)
            .setTranslation(276*0.795,482)
            .set("font","LiberationFonts/LiberationMono-Regular.ttf");#552,482 , 0.795 is for UV map

        svg.tgtHis = svg.rm_LIST.createChild("text")
                .setTranslation(-276*0.775, -482*0.5+10)
                .setText("TGT HIS 3")
                .setAlignment("left-center")
                .setColor(colorText1)
                .set("z-index",1)
                .setFontSize(20, 1.0);

        # OBS 6
        svg.obs6 = svg.rm_LIST.createChild("text")
                .setTranslation(276*0.795, -482*0.5-135)
                .setText("OBS 6")
                .setAlignment("right-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);
        # OBS 8
        svg.obs8 = svg.rm_LIST.createChild("text")
                .setTranslation(276*0.775, -482*0.5+10)
                .setText("OBS 8")
                .setAlignment("right-center")
                .setColor(colorText1)
                .set("z-index",1)
                .setFontSize(20, 1.0);
        return;
        svg.rm_LIST.M = svg.rm_LIST.createChild("text")
                .setTranslation(-276*0.775, -482*0.5+75)
                .setText("FCR")
                .setAlignment("left-center")
                .setColor(colorText1)
                .set("z-index",1)
                .setFontSize(20, 1.0);
    },
    addRMList: func {
        var svg = {getElementById: func (id) {return me[id]},};
        me.setupRMList(svg);
        me.PFD.addRListPage = func(svg, title, layer_id) {
            var np = PFD_Page.new(svg, title, layer_id, me);
            append(me.pages, np);
            me.page_index[layer_id] = np;
            np.setVisible(0);
            return np;
        };
        me.rm_LIST = me.PFD.addListPage(svg, "Radar CNTL", "rm_LIST");
        me.rm_LIST.model_index = me.model_index;
        me.rm_LIST.root = svg;
        me.rm_LIST.wdt = 552*0.795;
        me.rm_LIST.fwd = 0;
        me.rm_LIST.plc = 0;
        me.rm_LIST.ppp = me.PFD;
        me.rm_LIST.my = me;
        me.rm_LIST.band = 0;
        me.rm_LIST.chan = 2;
        me.rm_LIST.selectionBox = me.selectionBox;
        me.rm_LIST.setSelectionColor = me.setSelectionColor;
        me.rm_LIST.resetColor = me.resetColor;
        me.rm_LIST.setSelection = me.setSelection;
        me.rm_LIST.notifyButton = func (eventi) {
            if (eventi != nil) {

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
                if (eventi == 2) {
                    radar_system.apg68Radar.targetHistory += 1;
                    if (radar_system.apg68Radar.targetHistory > 4) {
                        radar_system.apg68Radar.targetHistory = 1;
                    }
                } elsif (eventi == 5) {
                    me.chan += 1;
                    if (me.chan > 4) me.chan = 1;
                } elsif (eventi == 7) {
                    me.band = !me.band;
                } elsif (eventi == 13) {
                    me.ppp.selectPage(me.my.p_RDR);
                    me.setSelection(me.ppp.buttons[13], me.ppp.buttons[10], 10);
                    me.selectionBox.show();
                } elsif (eventi == 15) {
                    swap();
                }
            }
        };
        me.rm_LIST.update = func (noti) {
            if (bottomImages[me.model_index] != nil) bottomImages[me.model_index].hide();
            me.root.tgtHis.setText("TGT HIS\n"~radar_system.apg68Radar.targetHistory);
            if (me.band == 0) {
                me.root.obs8.setText("BAND\nNARO");
            } else {
                me.root.obs8.setText("BAND\nWIDE");
            }
            me.root.obs6.setText("CHAN\n"~me.chan);
        };
    },


#  ███████ ███    ███ ███████     ███████ ███████ ████████ ██    ██ ██████ 
#  ██      ████  ████ ██          ██      ██         ██    ██    ██ ██   ██ 
#  ███████ ██ ████ ██ ███████     ███████ █████      ██    ██    ██ ██████  
#       ██ ██  ██  ██      ██          ██ ██         ██    ██    ██ ██     
#  ███████ ██      ██ ███████     ███████ ███████    ██     ██████  ██ 
#                                                                      
#
    setupSMS: func (svg) {
        svg.p_SMS = me.canvas.createGroup()
                .set("z-index",2)
                .setTranslation(276*0.795,482)
                .set("font","LiberationFonts/LiberationMono-Regular.ttf");#552,482 , 0.795 is for UV map

        svg.cat = svg.p_SMS.createChild("text")
                .setTranslation(0, -482*0.5+100)
                .setText("CAT I")
                .setAlignment("center-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);

        svg.gun = svg.p_SMS.createChild("text")
                .setTranslation(-276*0.795*0.95, -482*0.5-155)
                .setText("-----")
                .setAlignment("left-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);
        svg.gun2 = svg.p_SMS.createChild("text")
                .setTranslation(-276*0.795*0.95, -482*0.5-130)
                .setText("-----")
                .setAlignment("left-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);

        svg.p6 = svg.p_SMS.createChild("text")
                .setTranslation(276*0.795*0.08, -482*0.5-90)
                .setText("--------")
                .setAlignment("left-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);
        svg.p6l1 = svg.p_SMS.createChild("text")
                .setTranslation(276*0.795*0.08, -482*0.5-65)
                .setText("--------")
                .setAlignment("left-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);
        svg.p6l2 = svg.p_SMS.createChild("text")
                .setTranslation(276*0.795*0.08, -482*0.5-40)
                .setText("--------")
                .setAlignment("left-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);

        svg.p7 = svg.p_SMS.createChild("text")
                .setTranslation(276*0.795*0.37, -482*0.5-15)
                .setText("--------")
                .setAlignment("left-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);
        svg.p7l1 = svg.p_SMS.createChild("text")
                .setTranslation(276*0.795*0.37, -482*0.5+10)
                .setText("--------")
                .setAlignment("left-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);
        svg.p7l2 = svg.p_SMS.createChild("text")
                .setTranslation(276*0.795*0.37, -482*0.5+35)
                .setText("--------")
                .setAlignment("left-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);

        svg.p8 = svg.p_SMS.createChild("text")
                .setTranslation(276*0.795*0.52, -482*0.5+60)
                .setText("--------")
                .setAlignment("left-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);
        svg.p8l1 = svg.p_SMS.createChild("text")
                .setTranslation(276*0.795*0.52, -482*0.5+85)
                .setText("--------")
                .setAlignment("left-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);

        svg.p9 = svg.p_SMS.createChild("text")
                .setTranslation(276*0.795*0.52, -482*0.5+125)
                .setText("--------")
                .setAlignment("left-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);
        svg.p9l1 = svg.p_SMS.createChild("text")
                .setTranslation(276*0.795*0.52, -482*0.5+150)
                .setText("--------")
                .setAlignment("left-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);

        svg.p5 = svg.p_SMS.createChild("text")
                .setTranslation(-276*0.795*0.20, -482*0.5-190)
                .setText("--------")
                .setAlignment("left-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);
        svg.p5l1 = svg.p_SMS.createChild("text")
                .setTranslation(-276*0.795*0.20, -482*0.5-165)
                .setText("--------")
                .setAlignment("left-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);
        svg.p5l2 = svg.p_SMS.createChild("text")
                .setTranslation(-276*0.795*0.20, -482*0.5-140)
                .setText("--------")
                .setAlignment("left-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);

        svg.p4 = svg.p_SMS.createChild("text")
                .setTranslation(-276*0.795*0.51, -482*0.5-90)
                .setText("--------")
                .setAlignment("left-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);
        svg.p4l1 = svg.p_SMS.createChild("text")
                .setTranslation(-276*0.795*0.51, -482*0.5-65)
                .setText("--------")
                .setAlignment("left-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);
        svg.p4l2 = svg.p_SMS.createChild("text")
                .setTranslation(-276*0.795*0.51, -482*0.5-40)
                .setText("--------")
                .setAlignment("left-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);

        svg.p3 = svg.p_SMS.createChild("text")
                .setTranslation(-276*0.795*0.8, -482*0.5-15)
                .setText("--------")
                .setAlignment("left-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);
        svg.p3l1 = svg.p_SMS.createChild("text")
                .setTranslation(-276*0.795*0.8, -482*0.5+10)
                .setText("--------")
                .setAlignment("left-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);
        svg.p3l2 = svg.p_SMS.createChild("text")
                .setTranslation(-276*0.795*0.8, -482*0.5+35)
                .setText("--------")
                .setAlignment("left-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);

        svg.p2 = svg.p_SMS.createChild("text")
                .setTranslation(-276*0.795*0.95, -482*0.5+60)
                .setText("--------")
                .setAlignment("left-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);
        svg.p2l1 = svg.p_SMS.createChild("text")
                .setTranslation(-276*0.795*0.95, -482*0.5+85)
                .setText("--------")
                .setAlignment("left-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);

        svg.p1 = svg.p_SMS.createChild("text")
                .setTranslation(-276*0.795*0.95, -482*0.5+125)
                .setText("--------")
                .setAlignment("left-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);
        svg.p1l1 = svg.p_SMS.createChild("text")
                .setTranslation(-276*0.795*0.95, -482*0.5+150)
                .setText("--------")
                .setAlignment("left-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);

        #svg.drop = svg.p_SMS.createChild("text")
        #        .setTranslation(276*0.795*0.65, -482*0.5-225)
        #        .setText("CCRP")
        #        .setAlignment("center-top")
        #        .setColor(colorText1)
        #        .setFontSize(16, 1.0);

        svg.p1f = svg.p_SMS.createChild("path")
           .moveTo(-276*0.795*0.97, -482*0.5+115)
           .vert(50)
           .horiz(100)
           .vert(-50)
           .horiz(-100)
           .setColor(colorText1)
           .setStrokeLineWidth(2)
           .hide();
        svg.p2f = svg.p_SMS.createChild("path")
           .moveTo(-276*0.795*0.97, -482*0.5+50)
           .vert(50)
           .horiz(100)
           .vert(-50)
           .horiz(-100)
           .setColor(colorText1)
           .setStrokeLineWidth(2)
           .hide();
        svg.p3f = svg.p_SMS.createChild("path")
           .moveTo(-276*0.795*0.82, -482*0.5-25)
           .vert(70)
           .horiz(100)
           .vert(-70)
           .horiz(-100)
           .setColor(colorText1)
           .setStrokeLineWidth(2)
           .hide();
        svg.p4f = svg.p_SMS.createChild("path")
           .moveTo(-276*0.795*0.57, -482*0.5-100)
           .vert(70)
           .horiz(100)
           .vert(-70)
           .horiz(-100)
           .setColor(colorText1)
           .setStrokeLineWidth(2)
           .hide();
        svg.p5f = svg.p_SMS.createChild("path")
           .moveTo(-276*0.795*0.18, -482*0.5-200)
           .vert(70)
           .horiz(100)
           .vert(-70)
           .horiz(-100)
           .setColor(colorText1)
           .setStrokeLineWidth(2)
           .hide();
        svg.p6f = svg.p_SMS.createChild("path")
           .moveTo(0, -482*0.5-100)
           .vert(70)
           .horiz(100)
           .vert(-70)
           .horiz(-100)
           .setColor(colorText1)
           .setStrokeLineWidth(2)
           .hide();
        svg.p7f = svg.p_SMS.createChild("path")
           .moveTo(276*0.795*0.35, -482*0.5-25)
           .vert(70)
           .horiz(100)
           .vert(-70)
           .horiz(-100)
           .setColor(colorText1)
           .setStrokeLineWidth(2)
           .hide();
        svg.p8f = svg.p_SMS.createChild("path")
           .moveTo(276*0.795*0.5, -482*0.5+50)
           .vert(50)
           .horiz(100)
           .vert(-50)
           .horiz(-100)
           .setColor(colorText1)
           .setStrokeLineWidth(2)
           .hide();
        svg.p9f = svg.p_SMS.createChild("path")
           .moveTo(276*0.795*0.5, -482*0.5+115)
           .vert(50)
           .horiz(100)
           .vert(-50)
           .horiz(-100)
           .setColor(colorText1)
           .setStrokeLineWidth(2)
           .hide();
        svg.jett = svg.p_SMS.createChild("text")
                .setTranslation(276*0.795*0.95, -482*0.5-145)
                .setText("S-J")
                .setAlignment("right-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);
		svg.notSOI = svg.p_SMS.createChild("text")
           .setTranslation(0, -482*0.55)
           .setAlignment("center-center")
           .setText("NOT SOI")
           .set("z-index",12)
		   .hide()
           .setFontSize(18, 1.0)
           .setColor(colorText2);
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
        me.p_SMS.model_index = me.model_index;
        me.p_SMS.root = svg;
        me.p_SMS.wdt = 552*0.795;
        me.p_SMS.fwd = 0;
        me.p_SMS.plc = 0;
        me.p_SMS.ppp = me.PFD;
        me.p_SMS.my = me;
        me.p_SMS.selectionBox = me.selectionBox;
        me.p_SMS.setSelectionColor = me.setSelectionColor;
        me.p_SMS.resetColor = me.resetColor;
        me.p_SMS.setSelection = me.setSelection;
        me.p_SMS.notifyButton = func (eventi) {
            if (eventi != nil) {
                if (eventi == 10) {
                    me.ppp.selectPage(me.my.p_RDR);
                    me.setSelection(me.ppp.buttons[17], me.ppp.buttons[10], 10);
                } elsif (eventi == 1) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    pylons.fcs.selectPylon(3);
                } elsif (eventi == 2) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    pylons.fcs.selectPylon(2);
                } elsif (eventi == 3) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    pylons.fcs.selectPylon(1);
                } elsif (eventi == 4) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    pylons.fcs.selectPylon(0);
                } elsif (eventi == 5) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    pylons.fcs.jettisonSelectedPylonContent();
                } elsif (eventi == 6) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    pylons.fcs.selectPylon(5);
                } elsif (eventi == 7) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    pylons.fcs.selectPylon(6);
                } elsif (eventi == 8) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    pylons.fcs.selectPylon(7);
                } elsif (eventi == 9) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    pylons.fcs.selectPylon(8);
                } elsif (eventi == 12) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    pylons.fcs.selectPylon(4);
                } elsif (eventi == 17) {
                    me.ppp.selectPage(me.my.p_LIST);
                    me.resetColor(me.ppp.buttons[17]);
                    me.selectionBox.hide();
                } elsif (eventi == 18) {
                    me.ppp.selectPage(me.my.p_WPN);
                    me.setSelection(me.ppp.buttons[17], me.ppp.buttons[18], 18);
                #} elsif (eventi == 18) {
                #    me.ppp.selectPage(me.my.pjitds_1);
                } elsif (eventi == 14) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    pylons.fcs.setDropMode(!pylons.fcs.getDropMode());
                } elsif (eventi == 16) {
                    me.ppp.selectPage(me.my.p_HSD);
                    me.setSelection(me.ppp.buttons[17], me.ppp.buttons[16], 16);
                } elsif (eventi == 15) {
                    swap();
                } elsif (eventi == 19) {
                    if(getprop("f16/stores/tgp-mounted") and !getprop("/fdm/jsbsim/gear/unit[0]/WOW")) {
                        screen.log.write("Click BACK to get back to cockpit view",1,1,1);
                        switchTGP();
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
            }
        };
        me.p_SMS.update = func (noti) {
            if (bottomImages[me.model_index] != nil) bottomImages[me.model_index].hide();
            if (noti.FrameCount != 3)
                return;
            if (getprop("sim/variant-id") == 0) {
                return;
            }
			if (f16.SOI == 3 and me.model_index == 1) {
                me.root.notSOI.hide();
            } elsif (f16.SOI == 2 and me.model_index == 0) {
                me.root.notSOI.hide();
            } else {
                me.root.notSOI.show();
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

            var gunAmmo = "-----";
            if (getprop("sim/model/f16/wingmounts") != 0) {
                gunAmmo = pylons.pylonI.getAmmo("20mm Cannon");
                if (gunAmmo ==0) gunAmmo = "0";
                elsif (gunAmmo <10) gunAmmo = "1";
                else gunAmmo = ""~int(gunAmmo*0.1);
            }
            me.root.gun.setText(gunAmmo~"GUN");
            if (noti.getproper("variantID") == 0 or noti.getproper("variantID") == 1 or noti.getproper("variantID") == 3) {
                me.root.gun2.setText("M56");
            } else {
                me.root.gun2.setText("PGU28");
            }

            me.setTextOnStation([me.root.p1, me.root.p1l1], pylons.pylon1);
            me.setTextOnStation([me.root.p2, me.root.p2l1], pylons.pylon2);
            me.setTextOnStation([me.root.p3, me.root.p3l1, me.root.p3l2], pylons.pylon3);
            me.setTextOnStation([me.root.p4, me.root.p4l1, me.root.p4l2], pylons.pylon4);
            me.setTextOnStation([me.root.p5, me.root.p5l1, me.root.p5l2], pylons.pylon5);
            me.setTextOnStation([me.root.p6, me.root.p6l1, me.root.p6l2], pylons.pylon6);
            me.setTextOnStation([me.root.p7, me.root.p7l1, me.root.p7l2], pylons.pylon7);
            me.setTextOnStation([me.root.p8, me.root.p8l1], pylons.pylon8);
            me.setTextOnStation([me.root.p9, me.root.p9l1], pylons.pylon9);
        };
        me.p_SMS.setTextOnStation = func (lines, pylon) {
            # no check for pylon 1 and 9 if you enter both rack and pylon for them, this method will fail. So take care.
            if (pylon == nil) {
                lines[0].setText("--------");
                lines[1].setText("--------");
                if (size(lines) == 3) {
                    lines[2].setText("--------");
                }
                return;
            }
            me.curr = 0;
            me.pylName = pylon.getCurrentPylon();
            if (me.pylName != nil) {
                lines[me.curr].setText(me.pylName);
                me.curr += 1;
            }
            me.rackName = pylon.getCurrentRack();
            if (me.rackName != nil) {
                lines[me.curr].setText(me.rackName);
                me.curr += 1;
            }
            me.weapName = pylon.getCurrentSMSName();
            if (me.weapName != nil) {
                lines[me.curr].setText(me.weapName);
                me.curr += 1;
            }
            for (var i = me.curr ; i < size(lines); i += 1) {
                lines[i].setText("--------");
            }
        };
    },


#  ██     ██ ██████  ███    ██     ███████ ███████ ████████ ██    ██ ██████ 
#  ██     ██ ██   ██ ████   ██     ██      ██         ██    ██    ██ ██   ██ 
#  ██  █  ██ ██████  ██ ██  ██     ███████ █████      ██    ██    ██ ██████  
#  ██ ███ ██ ██      ██  ██ ██          ██ ██         ██    ██    ██ ██     
#   ███ ███  ██      ██   ████     ███████ ███████    ██     ██████  ██ 
#                                                                       
#
    setupWPN: func (svg) {
        svg.p_WPN = me.canvas.createGroup()
                .set("z-index",2)
                .setTranslation(276*0.795,482)
                .set("font","LiberationFonts/LiberationMono-Regular.ttf");#552,482 , 0.795 is for UV map



        svg.drop = svg.p_WPN.createChild("text")
                .setTranslation(276*0.795*-0.30, -482*0.5-225)
                .setText("")
                .setAlignment("center-top")
                .setColor(colorText1)
                .setFontSize(18, 1.0);

        svg.pre = svg.p_WPN.createChild("text")
                .setTranslation(276*0.795*0.0, -482*0.5-225)
                .setText("")
                .setAlignment("center-top")
                .setColor(colorText1)
                .setFontSize(18, 1.0);

        svg.eegs = svg.p_WPN.createChild("text")
                .setTranslation(276*0.795*0.325, -482*0.5-225)
                .setText("")
                .setAlignment("center-top")
                .setColor(colorText1)
                .setFontSize(18, 1.0);
        # OBS 6
        svg.weap = svg.p_WPN.createChild("text")
                .setTranslation(276*0.795, -482*0.5-135)
                .setText("")
                .setAlignment("right-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);

        # OBS 7
        svg.obs7 = svg.p_WPN.createChild("text")
                .setTranslation(276*0.795, -482*0.5-67.5)
                .setText("")
                .setAlignment("right-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);

        # OBS 8
        svg.ready = svg.p_WPN.createChild("text")
                .setTranslation(276*0.795, -482*0.5+0)
                .setText("")
                .setAlignment("right-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);

        #svg.td_bp = svg.p_WPN.createChild("text")
        #        .setTranslation(276*0.795, -482*0.5+35)
        #        .setText("TD")
        #        .setAlignment("right-center")
        #        .setColor(colorText1)
        #        .setFontSize(20, 1.0);

        svg.ripple = svg.p_WPN.createChild("text")
                .setTranslation(276*0.795, -482*0.5+70)
                .setText("")
                .setAlignment("right-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);

        svg.cool = svg.p_WPN.createChild("text")
                .setTranslation(276*0.795, -482*0.5+140)
                .setText("")
                .setAlignment("right-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);

        svg.rangUpA = svg.p_WPN.createChild("path")
                    .moveTo(-276*0.795,-482*0.5-105-27.5)
                    .horiz(30)
                    .lineTo(-276*0.795+15,-482*0.5-105-27.5-15)
                    .lineTo(-276*0.795,-482*0.5-105-27.5)
                    .setStrokeLineWidth(3)
                    .hide()
                    .setColor(colorText1);
        svg.rangA = svg.p_WPN.createChild("text")
                .setTranslation(-276*0.795, -482*0.5-105)
                .setAlignment("left-center")
                .setColor(colorText1)
                .hide()
                .setFontSize(20, 1.0);
        svg.rangDownA = svg.p_WPN.createChild("path")
                    .moveTo(-276*0.795,-482*0.5-105+27.5)
                    .horiz(30)
                    .lineTo(-276*0.795+15,-482*0.5-105+27.5+15)
                    .lineTo(-276*0.795,-482*0.5-105+27.5)
                    .setStrokeLineWidth(3)
                    .hide()
                    .setColor(colorText1);

        svg.distUpA = svg.p_WPN.createChild("path")
                    .moveTo(-276*0.795,-482*0.5-105-27.5)
                    .horiz(30)
                    .lineTo(-276*0.795+15,-482*0.5-105-27.5-15)
                    .lineTo(-276*0.795,-482*0.5-105-27.5)
                    .setStrokeLineWidth(3)
                    .hide()
                    .setTranslation(0,140)
                    .setColor(colorText1);
        svg.distA = svg.p_WPN.createChild("text")
                .setTranslation(-276*0.795, -482*0.5+35)
                .setAlignment("left-center")
                .setColor(colorText1)
                .hide()
                .setFontSize(20, 1.0);
        svg.distDownA = svg.p_WPN.createChild("path")
                    .moveTo(-276*0.795,-482*0.5-105+27.5)
                    .horiz(30)
                    .lineTo(-276*0.795+15,-482*0.5-105+27.5+15)
                    .lineTo(-276*0.795,-482*0.5-105+27.5)
                    .setStrokeLineWidth(3)
                    .hide()
                    .setTranslation(0,140)
                    .setColor(colorText1);
		svg.notSOI = svg.p_WPN.createChild("text")
           .setTranslation(0, -482*0.55)
           .setAlignment("center-center")
           .setText("NOT SOI")
           .set("z-index",12)
		   .hide()
           .setFontSize(18, 1.0)
           .setColor(colorText2);


        svg.coolFrame = svg.p_WPN.createChild("path")
           .moveTo(276*0.795, -482*0.5+140+12)
           .vert(-24)
           .horiz(-60)
           .vert(24)
           .horiz(60)
           .setColor(colorText1)
           .setStrokeLineWidth(2)
           .hide();
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
        me.p_WPN.model_index = me.model_index;
        me.p_WPN.root = svg;
        me.p_WPN.wdt = 552*0.795;
        me.p_WPN.fwd = 0;
        me.p_WPN.plc = 0;
        me.p_WPN.ppp = me.PFD;
        me.p_WPN.my = me;
        me.p_WPN.selectionBox = me.selectionBox;
        me.p_WPN.setSelectionColor = me.setSelectionColor;
        me.p_WPN.resetColor = me.resetColor;
        me.p_WPN.setSelection = me.setSelection;
        me.p_WPN.notifyButton = func (eventi) {
            if (eventi != nil) {
                if (eventi == 10) {
                    me.ppp.selectPage(me.my.p_RDR);
                    me.setSelection(me.ppp.buttons[18], me.ppp.buttons[10], 10);
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
                    } elsif (me.wpnType == "heat") {
                        var auto = pylons.fcs.isAutocage();
                        auto = !auto;
                        pylons.fcs.setAutocage(auto);
                    }
                } elsif (eventi == 9) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    if (me.wpnType=="heat") {
                        me.cooling = !pylons.fcs.getSelectedWeapon().isCooling();
                        foreach(var snake;pylons.fcs.getAllOfType("AIM-9L")) {
                            snake.setCooling(me.cooling);
                        }
                        foreach(var snake;pylons.fcs.getAllOfType("AIM-9M")) {
                            snake.setCooling(me.cooling);
                        }
                        foreach(var snake;pylons.fcs.getAllOfType("AIM-9X")) {
                            snake.setCooling(me.cooling);
                        }
                    } elsif (me.wpnType == "fall") {
                        if (getprop("controls/armament/dual")==1) {
                            setprop("controls/armament/dual",2);
                        } else {
                            setprop("controls/armament/dual",1);
                        }
                    }
                } elsif (eventi == 6) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    me.wpn54 = pylons.fcs.getSelectedWeapon();
                    if (me.wpn54 != nil and me.wpn54.type == "GBU-54") {
                        me.guide54 = me.wpn54.guidance;
                        if (me.guide54 == "gps") {
                            me.wpn54.guidance = "gps-laser";
                        } else {
                            me.wpn54.guidance = "gps";
                        }
                    }
                    if (me.wpn54 != nil and me.wpn54["powerOnRequired"] == 1) {
                        pylons.fcs.togglePowerOn();
                    }
                } elsif (eventi == 17) {
                    me.ppp.selectPage(me.my.p_SMS);
                    me.setSelection(me.ppp.buttons[18], me.ppp.buttons[17], 17);
                #} elsif (eventi == 18) {
                #    me.ppp.selectPage(me.my.pjitds_1);

                } elsif (eventi == 18) {
                    me.ppp.selectPage(me.my.p_LIST);
                    me.resetColor(me.ppp.buttons[18]);
                    me.selectionBox.hide();
                } elsif (eventi == 11) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    if (me.wpnType == "fall") {
                        pylons.fcs.setDropMode(!pylons.fcs.getDropMode());
                    } elsif (me.wpnType=="anti-rad") {
                        me.ppp.selectPage(me.my.p_HARM);
                        me.selectionBox.show();
                        me.setSelection(me.ppp.buttons[18], me.ppp.buttons[10], 10);
                    }
                } elsif (eventi == 12) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    if (me.wpnType == "heat") {
                        pylons.fcs.toggleXfov();
                    }
                } elsif (eventi == 13) {
                    if (getprop("sim/variant-id") == 0) {
                        return;
                    }
                    if (me.wpnType == "gun") {
                        setprop("f16/avionics/strf", !getprop("f16/avionics/strf"));
                    }
                } elsif (eventi == 16) {
                    me.ppp.selectPage(me.my.p_HSD);
                    me.setSelection(me.ppp.buttons[18], me.ppp.buttons[16], 16);
                } elsif (eventi == 15) {
                    swap();
                } elsif (eventi == 19) {
                    if(getprop("f16/stores/tgp-mounted") and !getprop("/fdm/jsbsim/gear/unit[0]/WOW")) {
                        screen.log.write("Click BACK to get back to cockpit view",1,1,1);
                        switchTGP();
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
#  VSD HSD WPN SIT
            }
        };
        me.p_WPN.update = func (noti) {
            if (bottomImages[me.model_index] != nil) bottomImages[me.model_index].hide();
            if (noti.FrameCount != 3)
                return;
            if (getprop("sim/variant-id") == 0) {
                return;
            }

			if (f16.SOI == 3 and me.model_index == 1) {
                me.root.notSOI.hide();
            } elsif (f16.SOI == 2 and me.model_index == 0) {
                me.root.notSOI.hide();
            } else {
                me.root.notSOI.show();
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
            me.obs7 = "";
            me.downAd = 0;
            me.upAd = 0;
            me.coolFrame = 0;
            me.downA = 0;
            me.upA = 0;
            me.armtimer = "";
            me.drop = "";
            me.showDist = 0;
            me.pre = "";
            #me.td_bp = "TD";
            if (me.wpn != nil and me.pylon != nil and me.wpn["typeShort"] != nil) {
                if (me.wpn.type == "MK-82" or me.wpn.type == "MK-82AIR" or me.wpn.type == "MK-83" or me.wpn.type == "MK-84" or me.wpn.type == "GBU-12" or me.wpn.type == "GBU-24" or me.wpn.type == "GBU-54" or me.wpn.type == "CBU-87" or me.wpn.type == "CBU-105" or me.wpn.type == "GBU-31" or me.wpn.type == "AGM-154A" or me.wpn.type == "B61-7" or me.wpn.type == "B61-12") {
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
                    if (me.wpn.type == "GBU-54") {
                        if (me.wpn.guidance == "gps-laser") {
                            me.obs7 = "GPS-LASR";
                        } else {
                            me.obs7 = "GPS";
                        }
                    }
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
                        me.ready = "MAL";
                    } elsif (me.wpn.status < armament.MISSILE_STARTING) {
                        me.ready = "OFF";
                    } elsif (me.wpn.status == armament.MISSILE_STARTING) {
                        me.ready = "INIT";
                    } else {
                        me.ready = "RDY";
                    }
                } elsif (me.wpn.type == "AGM-84" or me.wpn.type == "AGM-119" or me.wpn.type == "AGM-158") {
                    me.wpnType ="ground";
                    me.eegs = "A-G";
                    if (me.pylon.operableFunction != nil and !me.pylon.operableFunction()) {
                        me.ready = "MAL";
                    } elsif (me.wpn.status < armament.MISSILE_STARTING) {
                        me.ready = "OFF";
                    } elsif (me.wpn.status == armament.MISSILE_STARTING) {
                        me.ready = "INIT";
                    } else {
                        me.ready = "RDY";
                    }
                } elsif (me.wpn.type == "AGM-65B" or me.wpn.type == "AGM-65D") {
                    me.wpnType ="ground";
                    me.eegs = "A-G";
                    me.obs7 = me.wpn.isPowerOn()?"PWR ON":"PWR OFF";
                    if (me.pylon.operableFunction != nil and !me.pylon.operableFunction()) {
                        me.ready = "MAL";
                    } elsif (me.wpn.status < armament.MISSILE_STARTING) {
                        me.ready = "OFF";
                    } elsif (me.wpn.status == armament.MISSILE_STARTING and me.wpn["powerOn"]) {
                        me.ready = "INIT";
                    } elsif (me.wpn.status == armament.MISSILE_STARTING) {
                        me.ready = "OFF";
                    } else {
                        me.ready = "RDY";
                    }
                } elsif (me.wpn.type == "AGM-88") {
                    me.wpnType ="anti-rad";
                    me.eegs = "A-G";
                    me.drop = "HAS";#getprop("f16/stores/harm-mounted")?"HAS":"HAS";
                    me.obs7 = me.wpn.isPowerOn()?"PWR ON":"PWR OFF";
                    if (me.pylon.operableFunction != nil and !me.pylon.operableFunction()) {
                        me.ready = "MAL";
                    } elsif (me.wpn.status < armament.MISSILE_STARTING) {
                        me.ready = "OFF";
                    } elsif (me.wpn.status == armament.MISSILE_STARTING and me.wpn["powerOn"]) {
                        me.ready = "INIT";
                    } elsif (me.wpn.status == armament.MISSILE_STARTING) {
                        me.ready = "OFF";
                    } else {
                        me.ready = "RDY";
                    }
                } elsif (me.wpn.type == "AIM-9L" or me.wpn.type == "AIM-9M" or me.wpn.type == "AIM-9X") {
                    me.wpnType ="heat";
                    me.cool = me.wpn.getWarm()==0?"COOL":"WARM";
                    me.eegs = "A-A";
                    me.pre = pylons.fcs.isXfov()?"SCAN":"SPOT";
                    me.coolFrame = me.wpn.isCooling()==1?1:0;
                    me.drop = pylons.bore>0?"BORE":"SLAV";
                    me.ripple = pylons.fcs.isAutocage()?"TD":"BP";
                    if (me.pylon.operableFunction != nil and !me.pylon.operableFunction()) {
                        me.ready = "MAL";
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
                        me.ready = "MAL";
                    } elsif (me.wpn.status < armament.MISSILE_STARTING) {
                        me.ready = "OFF";
                    } elsif (me.wpn.status == armament.MISSILE_STARTING) {
                        me.ready = "INIT";
                    } else {
                        me.ready = "RDY";
                    }
                } elsif (me.wpn.type == "20mm Cannon") {
                    me.wpnType ="gun";
                    me.eegs = getprop("f16/avionics/strf")?"STRF":"EEGS";
                    if (me.pylon.operableFunction != nil and !me.pylon.operableFunction()) {
                        me.ready = "MAL";
                    } else {
                        me.ready = "RDY";
                    }
                } elsif (me.wpn.type == "LAU-68") {
                    me.wpnType ="rocket";
                    me.eegs = "A-G";
                    if (me.pylon.operableFunction != nil and !me.pylon.operableFunction()) {
                        me.ready = "MAL";
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
                #} elsif (me.myammo==1) {
                #    me.myammo = "";
                } else {
                    me.myammo = ""~me.myammo;
                }
                me.root.weap.setText(me.myammo~me.wpn.typeShort);
                if (getprop("controls/armament/master-arm") != 1) {
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
            me.root.obs7.setText(me.obs7);
            me.root.ripple.setText(me.ripple);
            me.root.coolFrame.setVisible(me.coolFrame);
            me.root.rangDownA.setVisible(me.downA);
            me.root.rangUpA.setVisible(me.upA);
            me.root.rangA.setText(me.armtimer);
            me.root.rangA.setVisible(me.upA or me.downA);
            #me.root.td_bp.setText(me.td_bp);
            #me.root.td_bp.setVisible(me.wpnType=="heat");

            me.root.distDownA.setVisible(me.downAd);
            me.root.distUpA.setVisible(me.upAd);
            me.root.distA.setText(me.rippleDist);
            me.root.distA.setVisible(me.showDist);
            me.at = 0;
            me.ar = 0;
        };
    },


#  ██   ██ ███████ ██████      ███████ ███████ ████████ ██    ██ ██████ 
#  ██   ██ ██      ██   ██     ██      ██         ██    ██    ██ ██   ██ 
#  ███████ ███████ ██   ██     ███████ █████      ██    ██    ██ ██████  
#  ██   ██      ██ ██   ██          ██ ██         ██    ██    ██ ██     
#  ██   ██ ███████ ██████      ███████ ███████    ██     ██████  ██ 
#                                                                   
#
    setupHSD: func (svg) {
        svg.p_HSD = me.canvas.createGroup()
                    .set("z-index",2)
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
            .setStrokeLineWidth(2)
            .set("z-index",2)
            .setColor(colorLine5);





        svg.maxB = 16;
        svg.blepTriangle = setsize([],svg.maxB);
        svg.blepTriangleVel = setsize([],svg.maxB);
        svg.blepTriangleText = setsize([],svg.maxB);
        svg.blepTriangleVelLine = setsize([],svg.maxB);
        svg.blepTrianglePaths = setsize([],svg.maxB);
        svg.lnkTA= setsize([],svg.maxB);
        svg.lnkT = setsize([],svg.maxB);
        svg.lnk  = setsize([],svg.maxB);
        for (var i = 0;i<svg.maxB;i+=1) {
                svg.blepTriangle[i] = svg.p_HSDc.createChild("group")
                                .set("z-index",11);
                svg.blepTriangleVel[i] = svg.blepTriangle[i].createChild("group");
                svg.blepTriangleText[i] = svg.blepTriangle[i].createChild("text")
                                .setAlignment("center-top")
                                .setFontSize(20, 1.0)
                                .setTranslation(0,20)
                                .setColor(1, 1, 1);
                svg.blepTriangleVelLine[i] = svg.blepTriangleVel[i].createChild("path")
                                .lineTo(0,-10)
                                .setTranslation(0,-16)
                                .setStrokeLineWidth(2)
                                .setColor(colorCircle2);
                svg.blepTrianglePaths[i] = svg.blepTriangle[i].createChild("path")
                                .moveTo(-14,8)
                                .horiz(28)
                                .lineTo(0,-16)
                                .lineTo(-14,8)
                                .setColor(colorCircle2)
                                .set("z-index",10)
                                .setStrokeLineWidth(2);
                svg.lnk[i] = svg.p_HSDc.createChild("path")
                                .moveTo(-10,-10)
                                .vert(20)
                                .horiz(20)
                                .vert(-20)
                                .horiz(-20)
                                .moveTo(0,-10)
                                .vert(-10)
                                .setColor(colorDot1)
                                .hide()
                                .set("z-index",11)
                                .setStrokeLineWidth(3);
                svg.lnkT[i] = svg.p_HSDc.createChild("text")
                                .setAlignment("center-bottom")
                                .setColor(colorDot1)
                                .set("z-index",1)
                                .setFontSize(20, 1.0);
                svg.lnkTA[i] = svg.p_HSDc.createChild("text")
                                .setAlignment("center-top")
                                .setColor(colorDot1)
                                .set("z-index",1)
                                .setFontSize(20, 1.0);
        }
        svg.selection = svg.p_HSDc.createChild("path")
                .moveTo(-16, 0)
                .arcSmallCW(16, 16, 0, 16*2, 0)
                .arcSmallCW(16, 16, 0, -16*2, 0)
                .setColor(colorDot1)
                .set("z-index",12)
                .setStrokeLineWidth(2);
        svg.rangUp = svg.buttonView.createChild("path")
                    .moveTo(-276*0.795,-482*0.5-105-27.5)
                    .horiz(30)
                    .lineTo(-276*0.795+15,-482*0.5-105-27.5-15)
                    .lineTo(-276*0.795,-482*0.5-105-27.5)
                    .setStrokeLineWidth(3)
                    .setColor(colorText1);
        svg.rang = svg.buttonView.createChild("text")
                .setTranslation(-276*0.795, -482*0.5-105)
                .setAlignment("left-center")
                .setText("8")
                .setColor(colorText1)
                .setFontSize(20, 1.0);
        svg.rangDown = svg.buttonView.createChild("path")
                    .moveTo(-276*0.795,-482*0.5-105+27.5)
                    .horiz(30)
                    .lineTo(-276*0.795+15,-482*0.5-105+27.5+15)
                    .lineTo(-276*0.795,-482*0.5-105+27.5)
                    .setStrokeLineWidth(3)
                    .setColor(colorText1);

        svg.depcen = svg.buttonView.createChild("text")#DEP/CEN
                .setTranslation(-276*0.795, -482*0.5-5)
                .setText("DEP")
                .setAlignment("left-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);
        svg.cpl = svg.buttonView.createChild("text")#CPL/DCPL
                .setTranslation(-276*0.795, -482*0.5+55)
                .setText("DCPL")
                .setAlignment("left-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);

        svg.myself = svg.p_HSDc.createChild("path")#own ship
           .moveTo(0, 0)
           .vert(30)
           .moveTo(-10, 10)
           .horiz(20)
           .moveTo(-5, 20)
           .horiz(10)
           .setColor(colorLine1)
           .setStrokeLineWidth(2);

        svg.threat_c = [];
        svg.threat_t = [];
        for (var g = 0; g < steerpoints.number_of_threat_circles; g+=1) {
            append(svg.threat_c, svg.p_HSDc.createChild("path")
                .moveTo(-50,0)
                .arcSmallCW(50,50, 0,  50*2, 0)
                .arcSmallCW(50,50, 0, -50*2, 0)
                .setStrokeLineWidth(3)
                .set("z-index",2)
                .hide()
                .setColor(colorCircle1));
            append(svg.threat_t, svg.p_HSDc.createChild("text")
                .setAlignment("center-center")
                .setColor(colorCircle1)
                .set("z-index",2)
                .setFontSize(15, 1.0));
        }

        svg.mark = setsize([],10);
        for (var no = 0; no < 10; no += 1) {
            svg.mark[no] = svg.p_HSDc.createChild("text")
                    .setAlignment("center-center")
                    .setColor(no<5?colorText2:colorCircle2)
                    .setText("X")
                    .set("z-index",2)
                    .setFontSize(18, 1.0);
        }

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
            .setStrokeLineWidth(3)
            .setColor(colorBullseye);
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
            .setStrokeLineWidth(2.5)
            .setTranslation(-190, -50)
            .setColor(colorBullseye);
        svg.bullOwnDist = svg.buttonView.createChild("text")
                .setAlignment("center-center")
                .setColor(colorBullseye)
                .setTranslation(-190, -50)
                .setText("12")
                .setFontSize(18, 1.0);
        svg.bullOwnDir = svg.buttonView.createChild("text")
                .setAlignment("center-top")
                .setColor(colorBullseye)
                .setTranslation(-190, -30)
                .setText("270")
                .setFontSize(18, 1.0);
		svg.notSOI = svg.buttonView.createChild("text")
           .setTranslation(0, -482*0.55)
           .setAlignment("center-center")
           .setText("NOT SOI")
           .set("z-index",12)
		   .hide()
           .setFontSize(18, 1.0)
           .setColor(colorText2);
    },

    HSD_centered: 0,
    HSD_coupled: 0,
    HSD_range_cen: 40,
    HSD_range_dep: 32,

    set_HSD_centered: func(centered) MFD_Device.HSD_centered = centered,
    set_HSD_coupled: func(coupled) MFD_Device.HSD_coupled = coupled,
    set_HSD_range_cen: func(range_cen) MFD_Device.HSD_range_cen = range_cen,
    set_HSD_range_dep: func(range_dep) MFD_Device.HSD_range_dep = range_dep,

    get_HSD_centered: func MFD_Device.HSD_centered,
    get_HSD_coupled: func MFD_Device.HSD_coupled,
    get_HSD_range_cen: func MFD_Device.HSD_range_cen,
    get_HSD_range_dep: func MFD_Device.HSD_range_dep,

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
        me.p_HSD.model_index = me.model_index;
        me.p_HSD.root = svg;
        me.p_HSD.wdt = 552*0.795;
        me.p_HSD.fwd = 0;
        me.p_HSD.plc = 0;
        me.p_HSD.ppp = me.PFD;
        me.p_HSD.my = me;
        me.p_HSD.up = 0;
        me.p_HSD.selectionBox = me.selectionBox;
        me.p_HSD.setSelectionColor = me.setSelectionColor;
        me.p_HSD.resetColor = me.resetColor;
        me.p_HSD.setSelection = me.setSelection;
        me.p_HSD.notifyButton = func (eventi) {
            if (eventi != nil) {
                if (eventi == 0) {
                    if (MFD_Device.get_HSD_coupled()) return;
                    if (MFD_Device.get_HSD_centered()) {
                        if (MFD_Device.get_HSD_range_cen() == 5)
                            MFD_Device.set_HSD_range_cen(10)
                        elsif (MFD_Device.get_HSD_range_cen() == 10)
                            MFD_Device.set_HSD_range_cen(20)
                        elsif (MFD_Device.get_HSD_range_cen() == 20)
                            MFD_Device.set_HSD_range_cen(40)
                        elsif (MFD_Device.get_HSD_range_cen() == 40)
                            MFD_Device.set_HSD_range_cen(80)
                        elsif (MFD_Device.get_HSD_range_cen() == 80)
                            MFD_Device.set_HSD_range_cen(160)
                        else
                            MFD_Device.set_HSD_range_cen(160);
                    } elsif (!MFD_Device.get_HSD_centered()) {
                        if (MFD_Device.get_HSD_range_dep() == 8)
                            MFD_Device.set_HSD_range_dep(16)
                        elsif (MFD_Device.get_HSD_range_dep() == 16)
                            MFD_Device.set_HSD_range_dep(32)
                        elsif (MFD_Device.get_HSD_range_dep() == 32)
                            MFD_Device.set_HSD_range_dep(64)
                        elsif (MFD_Device.get_HSD_range_dep() == 64)
                            MFD_Device.set_HSD_range_dep(128)
                        elsif (MFD_Device.get_HSD_range_dep() == 128)
                            MFD_Device.set_HSD_range_dep(256)
                        else
                            MFD_Device.set_HSD_range_dep(256);
                    }
                } elsif (eventi == 1) {
                    if (MFD_Device.get_HSD_coupled()) return;
                    if (MFD_Device.get_HSD_centered()) {
                        if (MFD_Device.get_HSD_range_cen() == 160)
                            MFD_Device.set_HSD_range_cen(80)
                        elsif (MFD_Device.get_HSD_range_cen() == 80)
                            MFD_Device.set_HSD_range_cen(40)
                        elsif (MFD_Device.get_HSD_range_cen() == 40)
                            MFD_Device.set_HSD_range_cen(20)
                        elsif (MFD_Device.get_HSD_range_cen() == 20)
                            MFD_Device.set_HSD_range_cen(10)
                        elsif (MFD_Device.get_HSD_range_cen() == 10)
                            MFD_Device.set_HSD_range_cen(5)
                        else
                            MFD_Device.set_HSD_range_cen(5);
                    } elsif (!MFD_Device.get_HSD_centered()) {
                        if (MFD_Device.get_HSD_range_dep() == 256)
                            MFD_Device.set_HSD_range_dep(128)
                        elsif (MFD_Device.get_HSD_range_dep() == 128)
                            MFD_Device.set_HSD_range_dep(64)
                        elsif (MFD_Device.get_HSD_range_dep() == 64)
                            MFD_Device.set_HSD_range_dep(32)
                        elsif (MFD_Device.get_HSD_range_dep() == 32)
                            MFD_Device.set_HSD_range_dep(16)
                        elsif (MFD_Device.get_HSD_range_dep() == 16)
                            MFD_Device.set_HSD_range_dep(8)
                        else
                            MFD_Device.set_HSD_range_dep(8);
                    }
                } elsif (eventi == 17) {
                    me.ppp.selectPage(me.my.p_SMS);
                    me.setSelection(me.ppp.buttons[16], me.ppp.buttons[17], 17);
                } elsif (eventi == 16) {
                    me.ppp.selectPage(me.my.p_LIST);
                    me.resetColor(me.ppp.buttons[16]);
                    me.selectionBox.hide();
                } elsif (eventi == 18) {
                    me.ppp.selectPage(me.my.p_WPN);
                    me.setSelection(me.ppp.buttons[16], me.ppp.buttons[18], 18);
                #} elsif (eventi == 18) {
                #    me.ppp.selectPage(me.my.pjitds_1);
                } elsif (eventi == 10) {
                    me.ppp.selectPage(me.my.p_RDR);
                    me.setSelection(me.ppp.buttons[16], me.ppp.buttons[10], 10);
                } elsif (eventi == 2) {
                    MFD_Device.set_HSD_centered(!MFD_Device.get_HSD_centered());
                    me.root.depcen.setText(MFD_Device.get_HSD_centered()==1?"CEN":"DEP");
                } elsif (eventi == 3) {
                    MFD_Device.set_HSD_coupled(!MFD_Device.get_HSD_coupled());
                    me.root.cpl.setText(MFD_Device.get_HSD_coupled()==1?"CPL":"DCPL");
                } elsif (eventi == 15) {
                    swap();
                } elsif (eventi == 19) {
                    if(getprop("f16/stores/tgp-mounted") and !getprop("/fdm/jsbsim/gear/unit[0]/WOW")) {
                        screen.log.write("Click BACK to get back to cockpit view",1,1,1);
                        switchTGP();
                    }
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

#  ██   ██ ███████ ██████      ██    ██ ██████  ██████   █████  ████████ ███████ 
#  ██   ██ ██      ██   ██     ██    ██ ██   ██ ██   ██ ██   ██    ██    ██      
#  ███████ ███████ ██   ██     ██    ██ ██████  ██   ██ ███████    ██    █████ 
#  ██   ██      ██ ██   ██     ██    ██ ██      ██   ██ ██   ██    ██    ██    
#  ██   ██ ███████ ██████       ██████  ██      ██████  ██   ██    ██    ███████ 
#                                                                                
#
        me.p_HSD.update = func (noti) {
            if (bottomImages[me.model_index] != nil) bottomImages[me.model_index].hide();
            me.root.conc.setRotation(-radar_system.self.getHeading()*D2R);
            if (noti.FrameCount != 1 and noti.FrameCount != 3)
                return;

			if (f16.SOI == 3 and me.model_index == 1) {
                me.root.notSOI.hide();
            } elsif (f16.SOI == 2 and me.model_index == 0) {
                me.root.notSOI.hide();
            } else {
                me.root.notSOI.show();
            }
            me.rdrrng = radar_system.apg68Radar.getRange();
            me.rdrprio = radar_system.apg68Radar.getPriorityTarget();
            me.selfCoord = geo.aircraft_position();
            me.selfHeading = radar_system.self.getHeading();
            if (MFD_Device.get_HSD_coupled()) {
                me.root.rangDown.hide();
                me.root.rangUp.hide();

                if (me.rdrrng == 5) {
                    MFD_Device.set_HSD_range_cen(5);
                    MFD_Device.set_HSD_range_dep(8);
                } elsif (me.rdrrng == 10) {
                    MFD_Device.set_HSD_range_cen(10);
                    MFD_Device.set_HSD_range_dep(16);
                } elsif (me.rdrrng == 20) {
                    MFD_Device.set_HSD_range_cen(20);
                    MFD_Device.set_HSD_range_dep(32);
                } elsif (me.rdrrng == 40) {
                    MFD_Device.set_HSD_range_cen(40);
                    MFD_Device.set_HSD_range_dep(64);
                } elsif (me.rdrrng == 80) {
                    MFD_Device.set_HSD_range_cen(80);
                    MFD_Device.set_HSD_range_dep(128);
                } elsif (me.rdrrng == 160) {
                    MFD_Device.set_HSD_range_cen(160);
                    MFD_Device.set_HSD_range_dep(256);
                }
            } else {
                if (MFD_Device.get_HSD_centered() and MFD_Device.get_HSD_range_cen() == 160) {
                    me.root.rangUp.hide();
                } elsif (!MFD_Device.get_HSD_centered() and MFD_Device.get_HSD_range_dep() == 256) {
                    me.root.rangUp.hide();
                } else {
                    me.root.rangUp.show();
                }

                if (MFD_Device.get_HSD_centered() and MFD_Device.get_HSD_range_cen() == 5) {
                    me.root.rangDown.hide();
                } elsif (!MFD_Device.get_HSD_centered() and MFD_Device.get_HSD_range_dep() == 8) {
                    me.root.rangDown.hide();
                } else {
                    me.root.rangDown.show();
                }
            }
            if (MFD_Device.get_HSD_centered()) {
                me.root.p_HSDc.setTranslation(276*0.795,482*0.50);
                me.root.rang.setText(""~MFD_Device.get_HSD_range_cen());
            } else {
                me.root.p_HSDc.setTranslation(276*0.795,482*0.75);
                me.root.rang.setText(""~MFD_Device.get_HSD_range_dep());
            }

            me.bullPt = steerpoints.getNumber(555);
            me.bullOn = me.bullPt != nil;
            if (me.bullOn) {
                me.bullLat = me.bullPt.lat;
                me.bullLon = me.bullPt.lon;
                me.bullCoord = geo.Coord.new().set_latlon(me.bullLat,me.bullLon);
                me.bullDirToMe = me.bullCoord.course_to(me.selfCoord);
                me.meToBull = ((me.bullDirToMe+180)-noti.getproper("heading"))*D2R;
                me.root.bullOwnRing.setRotation(me.meToBull);
                me.bullDistToMe = me.bullCoord.distance_to(me.selfCoord)*M2NM;
                if (MFD_Device.get_HSD_centered()) {
                    me.bullRangePixels = me.root.mediumRadius*(me.bullDistToMe/MFD_Device.get_HSD_range_cen());
                } else {
                    me.bullRangePixels = me.root.outerRadius*(me.bullDistToMe/MFD_Device.get_HSD_range_dep());
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

            if (MFD_Device.get_HSD_centered()) {
                me.rdrRangePixels = me.root.mediumRadius*(me.rdrrng/MFD_Device.get_HSD_range_cen());
            } else {
                me.rdrRangePixels = me.root.outerRadius*(me.rdrrng/MFD_Device.get_HSD_range_dep());
            }
            me.az = radar_system.apg68Radar.currentMode.az;
            if (noti.FrameCount == 1) {
                me.root.cone.removeAllChildren();
                if (radar_system.apg68Radar.enabled) {
                    if (radar_system.apg68Radar.showAZinHSD()) {
                        me.radarX1 =  me.rdrRangePixels*math.cos((90-me.az-radar_system.apg68Radar.getDeviation())*D2R);
                        me.radarY1 = -me.rdrRangePixels*math.sin((90-me.az-radar_system.apg68Radar.getDeviation())*D2R);
                        me.radarX2 =  me.rdrRangePixels*math.cos((90+me.az-radar_system.apg68Radar.getDeviation())*D2R);
                        me.radarY2 = -me.rdrRangePixels*math.sin((90+me.az-radar_system.apg68Radar.getDeviation())*D2R);
                        me.cone = me.root.cone.createChild("path")
                                    .moveTo(0,0)
                                    .lineTo(me.radarX1,me.radarY1)#right
                                    .moveTo(0,0)
                                    .lineTo(me.radarX2,me.radarY2)#left
                                    .arcSmallCW(me.rdrRangePixels,me.rdrRangePixels, 0, me.radarX1-me.radarX2, me.radarY1-me.radarY2)
                                    .setStrokeLineWidth(2)
                                    .set("z-index",5)
                                    .setColor(colorLine1)
                                    .update();
                    }
                }
                if (steerpoints.isRouteActive()) {
                    me.plan = flightplan();
                    me.planSize = me.plan.getPlanSize();
                    me.prevX = nil;
                    me.prevY = nil;
                    for (me.j = 0; me.j < me.planSize;me.j+=1) {
                        me.wp = me.plan.getWP(me.j);
                        me.wpC = geo.Coord.new();
                        me.wpC.set_latlon(me.wp.lat,me.wp.lon);
                        me.legBearing = me.selfCoord.course_to(me.wpC)-me.selfHeading;#relative
                        me.legDistance = me.selfCoord.distance_to(me.wpC)*M2NM;
                        if (MFD_Device.get_HSD_centered()) {
                            me.legRangePixels = me.root.mediumRadius*(me.legDistance/MFD_Device.get_HSD_range_cen());
                        } else {
                            me.legRangePixels = me.root.outerRadius*(me.legDistance/MFD_Device.get_HSD_range_dep());
                        }
                        me.legX = me.legRangePixels*math.sin(me.legBearing*D2R);
                        me.legY = -me.legRangePixels*math.cos(me.legBearing*D2R);
                        me.wp = me.root.cone.createChild("path")
                            .moveTo(me.legX-5,me.legY)
                            .arcSmallCW(5,5, 0, 5*2, 0)
                            .arcSmallCW(5,5, 0,-5*2, 0)
                            .setStrokeLineWidth(2)
                            .set("z-index",4)
                            .setColor(colorLine3)
                            .update();
                        if (me.plan.current == me.j) {
                            me.wp.setColorFill(colorLine3);
                        }
                        if (me.prevX != nil) {
                            me.root.cone.createChild("path")
                                .moveTo(me.legX,me.legY)
                                .lineTo(me.prevX,me.prevY)
                                .setStrokeLineWidth(2)
                                .set("z-index",4)
                                .setColor(colorLine3)
                                .update();
                        }
                        me.prevX = me.legX;
                        me.prevY = me.legY;
                    }
                }

                for (var u = 0;u<2;u+=1) {
                    if (steerpoints.lines[u] != nil) {
                        # lines
                        me.plan = steerpoints.lines[u];
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
                            me.legBearing = me.selfCoord.course_to(me.wpC)-me.selfHeading;#relative
                            me.legDistance = me.selfCoord.distance_to(me.wpC)*M2NM;
                            if (MFD_Device.get_HSD_centered()) {
                                me.legRangePixels = me.root.mediumRadius*(me.legDistance/MFD_Device.get_HSD_range_cen());;
                            } else {
                                me.legRangePixels = me.root.outerRadius*(me.legDistance/MFD_Device.get_HSD_range_dep());;
                            }
                            me.legX = me.legRangePixels*math.sin(me.legBearing*D2R);
                            me.legY = -me.legRangePixels*math.cos(me.legBearing*D2R);
                            if (me.prevX != nil and u == 0) {
                                me.root.cone.createChild("path")
                                    .moveTo(me.legX,me.legY)
                                    .lineTo(me.prevX,me.prevY)
                                    .setStrokeLineWidth(2)
                                    .set("z-index",4)
                                    .setColor(colorLines)
                                    .update();
                            } else if (me.prevX != nil and u == 1) {
                                me.root.cone.createChild("path")
                                    .moveTo(me.legX,me.legY)
                                    .lineTo(me.prevX,me.prevY)
                                    .setStrokeLineWidth(2)
                                    .setStrokeDashArray([10, 10])
                                    .set("z-index",4)
                                    .setColor(colorLines)
                                    .update();
                            }
                            me.prevX = me.legX;
                            me.prevY = me.legY;
                        }
                    }
                }

                me.root.cone.update();

                for (var mi = 0; mi < 10; mi+=1) {
                    var mkpt = nil;
                    if (mi<5) {
                        mkpt = steerpoints.getNumber(400+mi);
                    } else {
                        mkpt = steerpoints.getNumber(450+mi-5);
                    }
                    if (mkpt == nil) {
                        me.root.mark[mi].hide();
                    } else {
                        me.wpC = geo.Coord.new();
                        me.wpC.set_latlon(mkpt.lat, mkpt.lon);
                        me.legBearing = me.selfCoord.course_to(me.wpC)-me.selfHeading;#relative
                        me.legDistance = me.selfCoord.distance_to(me.wpC)*M2NM;

                        if (MFD_Device.get_HSD_centered()) {
                            me.legRangePixels = me.root.mediumRadius*(me.legDistance/MFD_Device.get_HSD_range_cen());
                        } else {
                            me.legRangePixels = me.root.outerRadius*(me.legDistance/MFD_Device.get_HSD_range_dep());
                        }

                        me.legX = me.legRangePixels*math.sin(me.legBearing*D2R);
                        me.legY = -me.legRangePixels*math.cos(me.legBearing*D2R);
                        me.root.mark[mi].setTranslation(me.legX,me.legY);
                        me.root.mark[mi].show();
                    }
                }
                #print("");print("");print("");
                for (var l = 0; l<steerpoints.number_of_threat_circles;l+=1) {
                    # threat circles
                    me.ci = me.root.threat_c[l];
                    me.cit = me.root.threat_t[l];

                    me.cnu = steerpoints.getNumber(300+l);
                    if (me.cnu == nil) {
                        me.ci.hide();
                        me.cit.hide();
                        #print("Ignoring ", 300+l);
                        continue;
                    }
                    me.la = me.cnu.lat;
                    me.lo = me.cnu.lon;
                    me.ra = me.cnu.radius;
                    me.ty = me.cnu.type;
                    
                    
                    if (me.la != nil and me.lo != nil and me.ra != nil and me.ra > 0) {
                        me.wpC = geo.Coord.new();
                        me.wpC.set_latlon(me.la,me.lo);
                        me.legBearing = me.selfCoord.course_to(me.wpC)-me.selfHeading;#relative
                        me.legDistance = me.selfCoord.distance_to(me.wpC)*M2NM;
                        me.legRadius  = me.ra;
                        if (MFD_Device.get_HSD_centered()) {
                            me.legRangePixels = me.root.mediumRadius*(me.legDistance/MFD_Device.get_HSD_range_cen());
                            me.legScale = me.root.mediumRadius*(me.legRadius/MFD_Device.get_HSD_range_cen())/50;
                        } else {
                            me.legRangePixels = me.root.outerRadius*(me.legDistance/MFD_Device.get_HSD_range_dep());
                            me.legScale = me.root.outerRadius*(me.legRadius/MFD_Device.get_HSD_range_dep())/50;
                        }

                        me.legX = me.legRangePixels*math.sin(me.legBearing*D2R);
                        me.legY = -me.legRangePixels*math.cos(me.legBearing*D2R);
                        me.ci.setTranslation(me.legX,me.legY);
                        me.ci.setScale(me.legScale);
                        me.ci.setStrokeLineWidth(1/me.legScale);
                        me.co = me.ra > me.legDistance?colorCircle1:colorCircle2;
                        #print("Painting ", 300+l," in ", me.ra > me.legDistance?"red":"yellow");
                        me.ci.setColor(me.co);
                        me.ci.show();
                        me.cit.setText(me.ty);
                        me.cit.setTranslation(me.legX,me.legY);
                        me.cit.setColor(me.co);
                        me.cit.show();
                    } else {
                        me.ci.hide();
                        me.cit.hide();
                    }
                }
            }


#  ██   ██ ███████ ██████      ██████   █████  ██████   █████  ██████ 
#  ██   ██ ██      ██   ██     ██   ██ ██   ██ ██   ██ ██   ██ ██   ██ 
#  ███████ ███████ ██   ██     ██████  ███████ ██   ██ ███████ ██████  
#  ██   ██      ██ ██   ██     ██   ██ ██   ██ ██   ██ ██   ██ ██   ██ 
#  ██   ██ ███████ ██████      ██   ██ ██   ██ ██████  ██   ██ ██   ██ 
#                                                                      
#
            if (noti.FrameCount == 3 and me.up == 1) {
                me.i = 0;#triangles
                me.ii = 0;#dlink
                me.selected = 0;

                me.rando = rand();

                if (radar_system.datalink_power.getBoolValue()) {
                    foreach(contact; vector_aicontacts_links) {
                        me.blue = contact.blue;
                        me.blueIndex = contact.blueIndex;
                        me.paintBlep(contact);
                        contact.rando = me.rando;
                    }
                }
                if (radar_system.apg68Radar.enabled) {
                    foreach(contact; radar_system.apg68Radar.getActiveBleps()) {
                        if (contact["rando"] == me.rando) continue;

                        me.blue = 0;
                        me.blueIndex = -1;

                        me.paintBlep(contact);
                    }
                }

                for (;me.i<me.root.maxB;me.i+=1) {
                    me.root.blepTriangle[me.i].hide();
                }
                for (;me.ii<me.root.maxB;me.ii+=1) {
                    me.root.lnk[me.ii].hide();
                    me.root.lnkT[me.ii].hide();
                    me.root.lnkTA[me.ii].hide();
                }
                me.root.selection.setVisible(me.selected);
            }
            if (noti.FrameCount == 3) me.up = !me.up;
        };
        me.p_HSD.paintBlep = func (contact) {
            if (!contact.isVisible() and me.blue != 2) {
                return;
            }
            me.desig = contact.equals(me.rdrprio);
            me.hasTrack = contact.hasTrackInfo();
            if (!me.hasTrack and me.blue == 0) {
                return;
            }
            me.color = me.blue == 1?colorDot4:(me.blue == 2?colorCircle1:colorCircle2);
            if (me.blue != 0) {
                me.c_rng = contact.getRange()*M2NM;
                me.c_rbe = contact.getDeviationHeading();
                me.c_hea = contact.getHeading();
                me.c_alt = contact.get_altitude();
                me.c_spd = contact.getSpeed();
            } else {
                me.lastBlep = contact.getLastBlep();

                me.c_rng = me.lastBlep.getRangeNow()*M2NM;
                me.c_rbe = me.lastBlep.getAZDeviation();
                me.c_hea = me.lastBlep.getHeading();
                me.c_alt = me.lastBlep.getAltitude();
                me.c_spd = me.lastBlep.getSpeed();
            }


            me.distPixels = (me.c_rng/me.rdrrng)*me.rdrRangePixels;
            #    if (me.blue) print("through ",me.desig," LoS:",!contact.get_behind_terrain());


            me.rot = 22.5*math.round( geo.normdeg((me.c_hea-me.selfHeading))/22.5 )*D2R;#Show rotation in increments of 22.5 deg
            me.trans = [me.distPixels*math.sin(me.c_rbe*D2R),-me.distPixels*math.cos(me.c_rbe*D2R)];

            if (me.blue != 1 and me.i < me.root.maxB) {
                me.root.blepTrianglePaths[me.i].setColor(me.color);
                me.root.blepTriangle[me.i].setTranslation(me.trans);
                me.root.blepTriangle[me.i].show();
                me.root.blepTrianglePaths[me.i].setRotation(me.rot);
                me.root.blepTriangleVel[me.i].setRotation(me.rot);
                me.root.blepTriangleVelLine[me.i].setScale(1,me.c_spd*0.0045);
                me.root.blepTriangleVelLine[me.i].setColor(me.color);
                me.lockAlt = sprintf("%02d", math.round(me.c_alt*0.001));
                me.root.blepTriangleText[me.i].setText(me.lockAlt);
                me.i += 1;
                if (me.blue == 2 and me.ii < me.root.maxB) {
                    me.root.lnkT[me.ii].setColor(me.color);
                    me.root.lnkT[me.ii].setTranslation(me.trans[0],me.trans[1]-25);
                    me.root.lnkT[me.ii].setText(""~me.blueIndex);
                    me.root.lnk[me.ii].hide();
                    me.root.lnkT[me.ii].show();
                    me.root.lnkTA[me.ii].hide();
                    me.ii += 1;
                }
            } elsif (me.blue == 1 and me.ii < me.root.maxB) {
                me.root.lnk[me.ii].setColor(me.color);
                me.root.lnk[me.ii].setTranslation(me.trans);
                me.root.lnk[me.ii].setRotation(me.rot);
                me.root.lnkT[me.ii].setColor(me.color);
                me.root.lnkTA[me.ii].setColor(me.color);
                me.root.lnkT[me.ii].setTranslation(me.trans[0],me.trans[1]-25);
                me.root.lnkTA[me.ii].setTranslation(me.trans[0],me.trans[1]+20);
                me.root.lnkT[me.ii].setText(""~me.blueIndex);
                me.root.lnkTA[me.ii].setText(sprintf("%02d", math.round(me.c_alt*0.001)));
                me.root.lnk[me.ii].show();
                me.root.lnkTA[me.ii].show();
                me.root.lnkT[me.ii].show();
                me.ii += 1;
            }

            if (me.desig) {
                me.root.selection.setTranslation(me.trans);
                me.root.selection.setColor(me.color);
                me.selected = 1;
            }
        };
    },

#  ██   ██  █████  ███████     ███████ ███████ ████████ ██    ██ ██████  
#  ██   ██ ██   ██ ██          ██      ██         ██    ██    ██ ██   ██ 
#  ███████ ███████ ███████     ███████ █████      ██    ██    ██ ██████  
#  ██   ██ ██   ██      ██          ██ ██         ██    ██    ██ ██      
#  ██   ██ ██   ██ ███████     ███████ ███████    ██     ██████  ██      
#                                                                        
#                                                          
    setupHARM: func (svg, index) {
        svg.p_HARM = me.canvas.createGroup()
                    .set("z-index",2)
                    .set("font","LiberationFonts/LiberationMono-Regular.ttf");
        svg.buttonView = svg.p_HARM.createChild("group")
                .setTranslation(276*0.795,482);
        svg.groupRdr = svg.p_HARM.createChild("group")
                .setTranslation(276*0.795, 0);#552,482 , 0.795 is for UV map
        svg.groupCursor = svg.p_HARM.createChild("group")
                .setTranslation(276*0.795, 482);#552,482 , 0.795 is for UV map

        svg.width  = 276*0.795*2;
        svg.height = 482;
        svg.index = index;
        svg.maxB = 5;
        svg.rdrTxt = setsize([],svg.maxB);
        for (var i = 0;i<svg.maxB;i+=1) {
                svg.rdrTxt[i] = svg.groupRdr.createChild("text")
                        .setAlignment("center-center")
                        .setFontSize(20, 1.0)
                        .setColor(colorText1);
        }
        svg.cursor = svg.groupCursor.createChild("path")
                    .moveTo(-8,-9)
                    .vert(18)
                    .moveTo(8,-9)
                    .vert(18)
                    .setStrokeLineWidth(2.0)
                    .setColor(colorLine3);

        var fieldH = svg.height * 0.60;
        var fieldW = svg.width * 0.666;
        svg.fieldH = fieldH;
        svg.fieldW = fieldW;
        svg.fieldX = -fieldW * 0.5;
        svg.fieldY = svg.height * 0.25;
        svg.topBox = svg.groupRdr.createChild("path")
                .moveTo(-fieldW*0.5, 40)
                .horiz(fieldW)
                .vert(svg.height * 0.10)
                .horiz(-fieldW)
                .vert(-svg.height * 0.10)
                .setColor(colorLine1)
                .set("z-index",12)
                .setStrokeLineWidth(2);
        svg.topBoxText = svg.groupRdr.createChild("text")
                        .setAlignment("left-center")
                        .setTranslation(-fieldW*0.5, 40+svg.height * 0.10*0.5)
                        .setFontSize(20, 1.0)
                        .setColor(colorText1);
        svg.dashBox = svg.groupRdr.createChild("path")
                .moveTo(-fieldW * 0.5, svg.height * 0.25)
                .horiz(fieldW)
                .vert(fieldH)
                .horiz(-fieldW)
                .vert(-fieldH)
                .setColor(colorCircle1)
                .setStrokeDashArray([20,20])
                .set("z-index",12)
                .setStrokeLineWidth(2);

        svg.searchText = svg.groupRdr.createChild("text")
                        .setAlignment("center-top")
                        .setTranslation(0, 40+svg.height * 0.10+5)
                        .setFontSize(20, 1.0)
                        .setColor(colorText2);

        svg.crossY = svg.groupRdr.createChild("path")
                .moveTo(0, svg.fieldY)
                .vert(fieldH)
                .setColor(colorLine3)
                .set("z-index",20)
                .setStrokeLineWidth(2);
        svg.crossX = svg.groupRdr.createChild("path")
                .moveTo(-fieldW * 0.5, svg.fieldY + fieldH * 0.25)
                .horiz(fieldW)
                .setColor(colorLine3)
                .set("z-index",20)
                .setStrokeLineWidth(2);
        svg.crossX1 = svg.groupRdr.createChild("path")
                .moveTo(0, 5)
                .vert(-10)
                .setColor(colorLine3)
                .set("z-index",20)
                .setStrokeLineWidth(2);
        svg.crossX2 = svg.groupRdr.createChild("path")
                .moveTo(0, 5)
                .vert(-10)
                .setColor(colorLine3)
                .set("z-index",20)
                .setStrokeLineWidth(2);
        svg.crossX3 = svg.groupRdr.createChild("path")
                .moveTo(0, 5)
                .vert(-10)
                .setColor(colorLine3)
                .set("z-index",20)
                .setStrokeLineWidth(2);
        svg.crossX4 = svg.groupRdr.createChild("path")
                .moveTo(0, 5)
                .vert(-10)
                .setColor(colorLine3)
                .set("z-index",20)
                .setStrokeLineWidth(2);
        svg.crossX5 = svg.groupRdr.createChild("path")
                .moveTo(0, 5)
                .vert(-10)
                .setColor(colorLine3)
                .set("z-index",20)
                .setStrokeLineWidth(2);
        svg.crossX6 = svg.groupRdr.createChild("path")
                .moveTo(0, 5)
                .vert(-10)
                .setColor(colorLine3)
                .set("z-index",20)
                .setStrokeLineWidth(2);
        svg.crossY1 = svg.groupRdr.createChild("path")
                .moveTo(-5, 0)
                .horiz(10)
                .setColor(colorLine3)
                .set("z-index",20)
                .setStrokeLineWidth(2);
        svg.crossY2 = svg.groupRdr.createChild("path")
                .moveTo(-5, 0)
                .horiz(10)
                .setColor(colorLine3)
                .set("z-index",20)
                .setStrokeLineWidth(2);
        svg.crossY3 = svg.groupRdr.createChild("path")
                .moveTo(-5, 0)
                .horiz(10)
                .setColor(colorLine3)
                .set("z-index",20)
                .setStrokeLineWidth(2);
        svg.cross = svg.groupRdr.createChild("path")
                .moveTo(20, 0)
                .horiz(fieldW * 0.5-20)
                .moveTo(-20, 0)
                .horiz(-fieldW * 0.5+20)
                .moveTo(0, 20)
                .vert(fieldH * 0.5-20)
                .moveTo(0, -20)
                .vert(-fieldH * 0.5+20)
                .setColor(colorLine3)
                .set("z-index",20)
                .setStrokeLineWidth(2);


        # BUTTONS
        var leftButtonsMax = 5;
        svg.obsL = [];
        svg.obsLb = [];
        var initY = -125;
        for (var i = 0;i<leftButtonsMax;i+=1) {
            append(svg.obsL, svg.buttonView.createChild("text")
                .setTranslation(-276*0.795, -482*0.5+initY)
                .setText(" P")
                .setAlignment("left-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0));
            append(svg.obsLb, svg.buttonView.createChild("text")
                .setTranslation(-276*0.795, -482*0.5+initY)
                .setText(" P")
                .setAlignment("left-center")
                .setColor(colorBackground)
                .setColorFill(colorText1)
                .setDrawMode(canvas.Text.TEXT + canvas.Text.FILLEDBOUNDINGBOX)#This does only work before first text element update so cannot be properly changed in loops
                .setFontSize(20, 1.0));
            initY += 60;
        }
        svg.obs7 = svg.buttonView.createChild("text")
                .setTranslation(276*0.775, -482*0.5-65)
                .setText("RS")
                .setAlignment("right-center")
                .setColor(colorText1)
                .setFontSize(20, 1.0);
        svg.obs10 = svg.buttonView.createChild("text")
                .setTranslation(276*0.775, -482*0.5+125+10)
                .setText("")
                .setAlignment("right-center")
                .setColor(colorText1)
                .set("z-index",1)
                .setFontSize(20, 1.0);
        #svg.obs11 = svg.buttonView.createChild("text")
        #        .setTranslation(276*0.795*-0.71, -482*0.5-215)
        #        .setText("HAS")
        #        .setAlignment("center-top")
        #        .setColor(colorText1)
        #        .set("z-index",20000)
        #        .setFontSize(20, 1.0);
        svg.obs12 = svg.buttonView.createChild("text")
                .setTranslation(276*0.795*-0.30, -482*0.5-225)
                .setText("TBL1")
                .setAlignment("center-top")
                .setColor(colorText1)
                .setFontSize(18, 1.0);
        svg.obs13 = svg.buttonView.createChild("text")
                .setTranslation(276*0.795*0.0, -482*0.5-225)
                .setText("WIDE")
                .setAlignment("center-top")
                .setColor(colorText1)
                .set("z-index",1)
                .setFontSize(18, 1.0);
        svg.obs15 = svg.buttonView.createChild("text")
                .setTranslation(276*0.795*0.60, -482*0.5-225)
                .setText("UFC")
                .setAlignment("center-top")
                .setColor(colorText1)
                .set("z-index",1)
                .setFontSize(18, 1.0);
        
        
        
        svg.notSOI = svg.buttonView.createChild("text")
           .setTranslation(0, -482*0.55)
           .setAlignment("center-center")
           .setText("NOT SOI")
           .set("z-index",12)
           .setFontSize(18, 1.0)
           .setColor(colorText2);
    },

    addHARM: func {
        var svg = {getElementById: func (id) {return me[id]},};
        me.setupHARM(svg, me.model_index);
        me.PFD.addHARMPage = func(svg, title, layer_id) {
            var np = PFD_Page.new(svg, title, layer_id, me);
            append(me.pages, np);
            me.page_index[layer_id] = np;
            np.setVisible(0);
            return np;
        };
        me.p_HARM = me.PFD.addHARMPage(svg, "HAS", "p_HARM");
        me.p_HARM.model_index = me.model_index;
        me.p_HARM.root = svg;
        me.p_HARM.elapsed = 0;
        me.p_HARM.slew_c_last = slew_c;
        me.p_HARM.wdt = 552*0.795;
        me.p_HARM.ppp = me.PFD;
        me.p_HARM.my = me;
        me.p_HARM.items = [];
        me.p_HARM.iter = -1;
        me.p_HARM.sensor = radar_system.f16_radSensor;
        me.p_HARM.selectionBox = me.selectionBox;
        me.p_HARM.setSelectionColor = me.setSelectionColor;
        me.p_HARM.resetColor = me.resetColor;
        me.p_HARM.setSelection = me.setSelection;
        me.p_HARM.notifyButton = func (eventi) {
            if (eventi != nil) {
                if (eventi >= 0 and eventi < 5) {
                    if (me.sensor.handoffTarget != nil and me.sensor.handoffTarget["tblIdx"] == eventi) {
                        me.sensor.handoffTarget = nil;
                    }
                } elsif (eventi == 6) {                    
                    me.sensor.reset();
                    me.sensor.searchCounter += 1;
                } elsif (eventi == 10) {
                    me.ppp.selectPage(me.my.p_LIST);
                    me.resetColor(me.ppp.buttons[10]);
                    me.selectionBox.hide();
                } elsif (eventi == 11) {
                    me.sensor.currtable += 1;
                    if (me.sensor.currtable > 2) me.sensor.currtable = 0;
                    me.sensor.handoffTarget = nil;
                } elsif (eventi == 12) {
                    me.sensor.fov_desired += 1;
                    if (me.sensor.fov_desired > 3) me.sensor.fov_desired = 0;
                } elsif (eventi == 14) {
                    ded.dataEntryDisplay.harmTablePage = me.sensor.currtable;
                    ded.dataEntryDisplay.page = ded.pHARM;
                } elsif (eventi == 15) {
                    swap();
                } elsif (eventi == 16) {
                    me.ppp.selectPage(me.my.p_HSD);
                    me.setSelection(me.ppp.buttons[10], me.ppp.buttons[16], 16);
                } elsif (eventi == 17) {
                    me.ppp.selectPage(me.my.p_SMS);
                    me.setSelection(me.ppp.buttons[10], me.ppp.buttons[17], 17);
                } elsif (eventi == 18) {                    
                    me.ppp.selectPage(me.my.p_WPN);
                    me.setSelection(me.ppp.buttons[10], me.ppp.buttons[18], 18);
                } elsif (eventi == 19) {
                    if(getprop("f16/stores/tgp-mounted") and !getprop("/fdm/jsbsim/gear/unit[0]/WOW")) {
                        screen.log.write("Click BACK to get back to cockpit view",1,1,1);
                        switchTGP();
                    }
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


#  ██   ██  █████  ███████     ██    ██ ██████  ██████   █████  ████████ ███████ 
#  ██   ██ ██   ██ ██          ██    ██ ██   ██ ██   ██ ██   ██    ██    ██      
#  ███████ ███████ ███████     ██    ██ ██████  ██   ██ ███████    ██    █████   
#  ██   ██ ██   ██      ██     ██    ██ ██      ██   ██ ██   ██    ██    ██      
#  ██   ██ ██   ██ ███████      ██████  ██      ██████  ██   ██    ██    ███████ 
#                                                                                
#                                                                                
        me.p_HARM.update = func (noti) {
            if (bottomImages[me.model_index] != nil) bottomImages[me.model_index].hide();
            if (noti.FrameCount != 1 and noti.FrameCount != 3)
                return;
            #print("\nHAD update:\n=======");

            # make sure it can maddog
            # filters for table
            # when having 2 HAS displays, sensor might get table confused, and check for other issues.
            # test
            me.harmSelected = 0;
            if (pylons.fcs != nil) {
                me.radWeap = pylons.fcs.getSelectedWeapon();
                if (me.radWeap != nil) {
                    if (me.radWeap["guidance"] == "radiation" and me.radWeap.getStatus() >= armament.MISSILE_SEARCH) {
                        me.sensor.maxArea = me.root.fieldW * me.root.fieldH;
                        if (me.sensor.fov_desired == 1) {
                            me.sensor.area = me.sensor.maxArea*0.25;
                            me.sensor.x    = [-15, 15];
                            me.sensor.y    = [-10, 10];#todo: something of here, decide proper
                        } elsif (me.sensor.fov_desired == 2) {
                            me.sensor.area = me.sensor.maxArea*0.5;
                            me.sensor.x    = [-30, 0];
                            me.sensor.y    = [-30, 10];
                        } elsif (me.sensor.fov_desired == 3) {
                            me.sensor.area = me.sensor.maxArea*0.5;
                            me.sensor.x    = [0, 30];
                            me.sensor.y    = [-30, 10];
                        } else {
                            me.sensor.area = me.sensor.maxArea;
                            me.sensor.x    = [-30, 30];
                            me.sensor.y    = [-30, 10];
                        }
                        me.sensor.table = me.sensor.tables[me.sensor.currtable];
                        me.sensor.range = me.radWeap.max_fire_range_nm;
                        if (me.sensor.fov != me.sensor.fov_desired) {
                            me.sensor.fov = me.sensor.fov_desired;
                            me.sensor.reset();
                        }
                        me.sensor.setEnabled(me.sensor.handoffTarget == nil);
                        me.harmSelected = 1;
                    } else {
                        me.sensor.setEnabled(0);
                    }
                } else {
                    me.sensor.setEnabled(0);
                }
            } else {
                me.sensor.setEnabled(0);
                return;
            }

            #CURSOR

            me.IMSOI = 0;
            if (f16.SOI == 3 and me.model_index == 1) {
                me.root.notSOI.hide();
                me.IMSOI = 1;
            } elsif (f16.SOI == 2 and me.model_index == 0) {
                me.root.notSOI.hide();
                me.IMSOI = 1;
            } else {
                me.root.notSOI.show();
            }

            me.slew_x = getprop("controls/displays/target-management-switch-x[" ~ me.model_index ~ "]");
            me.slew_y = -getprop("controls/displays/target-management-switch-y[" ~ me.model_index ~ "]");

            if (noti.getproper("viewName") != "TGP" and me.IMSOI) {
                f16.resetSlew();
            }

            me.dt = noti.getproper("elapsed") - me.elapsed;

            if ((me.slew_x != 0 or me.slew_y != 0 or slew_c != 0) and (cursor_lock == -1 or cursor_lock == me.root.index) and noti.getproper("viewName") != "TGP" and me.sensor.handoffTarget == nil) {
                cursor_destination = nil;
                cursor_posHAS[0] += me.slew_x*175;
                cursor_posHAS[1] -= me.slew_y*175;
                cursor_posHAS[0] = math.clamp(cursor_posHAS[0], -552*0.5*0.795, 552*0.5*0.795);
                cursor_posHAS[1] = math.clamp(cursor_posHAS[1], -482, 0);
                cursor_click = (slew_c and !me.slew_c_last)?me.root.index:-1;
                cursor_lock = me.root.index;
            } elsif (cursor_lock == me.root.index or (me.slew_x == 0 or me.slew_y == 0 or slew_c == 0)) {
                cursor_lock = -1;
            }
            me.slew_c_last = slew_c;
            slew_c = 0;
            
            me.elapsed = noti.getproper("elapsed");
            me.root.cursor.setTranslation(cursor_posHAS);
            me.root.cursor.setVisible(me.sensor.handoffTarget == nil);
            if (0 and cursor_click==0) print(cursor_posHAS[0],", ",cursor_posHAS[1]+482, "  click: ", cursor_click);

            
            
            me.root.obs12.setText("TBL"~(me.sensor.currtable + 1));
            
            if (me.sensor.fov_desired == 1) {
                me.fovTxt = "CTR";
                me.root.crossX.setTranslation(0,me.root.fieldH*0.25); 
                me.root.crossY.setTranslation(0,0);
                me.root.crossX1.setTranslation(me.root.fieldX+20*me.root.fieldW/6, me.root.fieldY+me.root.fieldH*0.5); 
                me.root.crossX2.setTranslation(me.root.fieldX+20*me.root.fieldW/6, me.root.fieldY+me.root.fieldH*0.5); 
                me.root.crossX3.setTranslation(me.root.fieldX+1*me.root.fieldW/6, me.root.fieldY+me.root.fieldH*0.5); 
                me.root.crossX4.setTranslation(me.root.fieldX+5*me.root.fieldW/6, me.root.fieldY+me.root.fieldH*0.5); 
                me.root.crossX5.setTranslation(me.root.fieldX+20*me.root.fieldW/6, me.root.fieldY+me.root.fieldH*0.5); 
                me.root.crossX6.setTranslation(me.root.fieldX+20*me.root.fieldW/6, me.root.fieldY+me.root.fieldH*0.5); 
                me.root.crossY1.setTranslation(0, me.root.fieldY+me.root.fieldH*0.5+2*me.root.fieldH*0.75/3);
                me.root.crossY2.setTranslation(0, me.root.fieldY+me.root.fieldH*0.5+4*me.root.fieldH*0.75/3);
                me.root.crossY3.setTranslation(0, me.root.fieldY+me.root.fieldH*0.5+6*me.root.fieldH*0.75/3);
            } elsif (me.sensor.fov_desired == 2) {
                me.fovTxt = "LEFT";
                me.root.crossX.setTranslation(0,0); 
                me.root.crossY.setTranslation(-me.root.fieldX,0);
                me.root.crossX1.setTranslation(me.root.fieldX,                    me.root.fieldY+me.root.fieldH*0.25); 
                me.root.crossX2.setTranslation(me.root.fieldX+2*me.root.fieldW/6, me.root.fieldY+me.root.fieldH*0.25); 
                me.root.crossX3.setTranslation(me.root.fieldX+4*me.root.fieldW/6, me.root.fieldY+me.root.fieldH*0.25); 
                me.root.crossX4.setTranslation(me.root.fieldX+6*me.root.fieldW/6, me.root.fieldY+me.root.fieldH*0.25); 
                me.root.crossX5.setTranslation(me.root.fieldX+8*me.root.fieldW/6, me.root.fieldY+me.root.fieldH*0.25); 
                me.root.crossX6.setTranslation(me.root.fieldX+10*me.root.fieldW/6, me.root.fieldY+me.root.fieldH*0.25); 
                me.root.crossY1.setTranslation(-me.root.fieldX, me.root.fieldY+me.root.fieldH*0.25+1*me.root.fieldH*0.75/3);
                me.root.crossY2.setTranslation(-me.root.fieldX, me.root.fieldY+me.root.fieldH*0.25+2*me.root.fieldH*0.75/3);
                me.root.crossY3.setTranslation(-me.root.fieldX, me.root.fieldY+me.root.fieldH*0.25+3*me.root.fieldH*0.75/3);
            } elsif (me.sensor.fov_desired == 3) {
                me.fovTxt = "RGHT";
                me.root.crossX.setTranslation(0,0); 
                me.root.crossY.setTranslation(me.root.fieldX,0);
                me.root.crossX1.setTranslation(me.root.fieldX,                    me.root.fieldY+me.root.fieldH*0.25); 
                me.root.crossX2.setTranslation(me.root.fieldX+2*me.root.fieldW/6, me.root.fieldY+me.root.fieldH*0.25); 
                me.root.crossX3.setTranslation(me.root.fieldX+4*me.root.fieldW/6, me.root.fieldY+me.root.fieldH*0.25); 
                me.root.crossX4.setTranslation(me.root.fieldX+6*me.root.fieldW/6, me.root.fieldY+me.root.fieldH*0.25); 
                me.root.crossX5.setTranslation(me.root.fieldX+8*me.root.fieldW/6, me.root.fieldY+me.root.fieldH*0.25); 
                me.root.crossX6.setTranslation(me.root.fieldX+10*me.root.fieldW/6, me.root.fieldY+me.root.fieldH*0.25); 
                me.root.crossY1.setTranslation(me.root.fieldX, me.root.fieldY+me.root.fieldH*0.25+1*me.root.fieldH*0.75/3);
                me.root.crossY2.setTranslation(me.root.fieldX, me.root.fieldY+me.root.fieldH*0.25+2*me.root.fieldH*0.75/3);
                me.root.crossY3.setTranslation(me.root.fieldX, me.root.fieldY+me.root.fieldH*0.25+3*me.root.fieldH*0.75/3);
            } else {
                me.fovTxt = "WIDE";
                me.root.crossX.setTranslation(0,0); 
                me.root.crossY.setTranslation(0,0);
                me.root.crossX1.setTranslation(me.root.fieldX, me.root.fieldY+me.root.fieldH*0.25); 
                me.root.crossX2.setTranslation(me.root.fieldX+1*me.root.fieldW/6, me.root.fieldY+me.root.fieldH*0.25); 
                me.root.crossX3.setTranslation(me.root.fieldX+2*me.root.fieldW/6, me.root.fieldY+me.root.fieldH*0.25); 
                me.root.crossX4.setTranslation(me.root.fieldX+3*me.root.fieldW/6, me.root.fieldY+me.root.fieldH*0.25); 
                me.root.crossX5.setTranslation(me.root.fieldX+4*me.root.fieldW/6, me.root.fieldY+me.root.fieldH*0.25); 
                me.root.crossX6.setTranslation(me.root.fieldX+5*me.root.fieldW/6, me.root.fieldY+me.root.fieldH*0.25); 
                me.root.crossY1.setTranslation(0, me.root.fieldY+me.root.fieldH*0.25+1*me.root.fieldH*0.75/3);
                me.root.crossY2.setTranslation(0, me.root.fieldY+me.root.fieldH*0.25+2*me.root.fieldH*0.75/3);
                me.root.crossY3.setTranslation(0, me.root.fieldY+me.root.fieldH*0.25+3*me.root.fieldH*0.75/3);
            }
            me.root.obs13.setText(me.fovTxt);

            for (me.jj = 0; me.jj < 5;me.jj += 1) {
                if (size(me.sensor.tables[me.sensor.currtable])>me.jj) {
                    me.root.obsL[me.jj].setText(me.sensor.tables[me.sensor.currtable][me.jj]);
                    me.root.obsLb[me.jj].setText(me.sensor.tables[me.sensor.currtable][me.jj]);
                } else {
                    me.root.obsL[me.jj].setText("");
                }
            }
            if (me.sensor.enabled) {
                me.cycleTimeLeft = math.max(0,me.sensor.dura-(systime()-me.sensor.searchStart));
                me.root.searchText.setText(sprintf("%d:%02d   SCT-%d",(me.cycleTimeLeft)/60, math.mod(me.cycleTimeLeft,60),me.sensor.searchCounter));
                me.root.searchText.show();
            } else {
                me.root.searchText.hide();
            }

            me.items = me.sensor.vector_aicontacts_seen;
            me.iter = size(me.items)-1;

            if (me.harmSelected and me.sensor.handoffTarget != nil and me.radWeap.status < armament.MISSILE_LOCK) {
                # This makes sure we go from handover back to search when missile loses lock
                if (systime()-me.sensor.handoffTime > 1) {
                    # It had time to get lock, but failed or masterarm was off
                    me.radWeap.setContacts([]);
                    me.sensor.handoffTarget = nil;
                }
            } elsif (!me.harmSelected) {
                me.sensor.handoffTarget = nil;
            }

            if (noti.FrameCount == 1 and me.sensor.handoffTarget == nil) {
                for (me.jj = 0; me.jj < 5;me.jj += 1) {
                    me.root.obsL[me.jj].show();
                    me.root.obsLb[me.jj].hide();
                }
            }

            if (me.sensor.handoffTarget != nil) {
                #me.handoffTarget
                me.root.rdrTxt[0].setText(me.sensor.handoffTarget.mdl~me.sensor.handoffTarget.radiSpike);
                me.root.rdrTxt[0].setTranslation(0, me.root.fieldY + me.root.fieldH*0.5);
                me.root.cross.setTranslation(0, me.root.fieldY + me.root.fieldH*0.5);
                me.root.rdrTxt[1].hide();
                me.root.rdrTxt[2].hide();
                me.root.rdrTxt[3].hide();
                me.root.rdrTxt[4].hide();
                me.root.crossX.hide();
                me.root.crossY.hide();
                me.root.crossX1.hide();
                me.root.crossX2.hide(); 
                me.root.crossX3.hide();
                me.root.crossX4.hide();
                me.root.crossX5.hide();
                me.root.crossX6.hide();
                me.root.crossY1.hide();
                me.root.crossY2.hide();
                me.root.crossY2.hide();
                #me.root.dashBox.hide();
                me.root.cross.show();

                for (me.jj = 0; me.jj < 5;me.jj += 1) {
                    if (me.sensor.handoffTarget["tblIdx"] == me.jj) {
                        me.root.obsL[me.jj].hide();
                        me.root.obsLb[me.jj].show();
                    }
                }

                if (cursor_click == me.root.index) {
                    me.sensor.handoffTarget = nil;
                    cursor_click = -1;
                    # not needed anymore due to last lines in method:
                    #if (me.radWeap != nil and me.radWeap["guidance"] == "radiation") {
                    #    me.radWeap.setContacts([]);
                    #    me.radWeap.clearTgt();
                    #}
                } elsif (me.harmSelected) {
                    me.radWeap.setContacts([me.sensor.handoffTarget]);
                }
            } elsif (me.sensor.enabled) {
                me.root.crossX.show();
                me.root.crossY.show();
                me.root.crossX1.show();
                me.root.crossX2.show(); 
                me.root.crossX3.show();
                me.root.crossX4.show();
                me.root.crossX5.show();
                me.root.crossX6.show();
                me.root.crossY1.show();
                me.root.crossY2.show();
                me.root.crossY2.show();
                #me.root.dashBox.show();
                me.root.cross.hide();
                me.topLine = "   ";
                me.topCheck = [0,0,0,0,0];
                me.clickableItems = [];
                for (me.txt_count = 0; me.txt_count < 5; me.txt_count += 1) {
                    me.check = !(me.txt_count > me.iter);
                    me.checkFresh = me.check and me.items[me.txt_count].discover < systime()-me.sensor.searchStart and me.items[me.txt_count].discoverSCT==me.sensor.searchCounter;
                    me.checkFading = me.check and me.items[me.txt_count]["discoverSCTShown"] == me.sensor.searchCounter-1;
                    #if (me.check) print(" fresh ",me.checkFresh,", fading ",me.checkFading, ", timetoshow ", me.items[me.txt_count].discover);
                    #if (me.check) print("  time ",me.items[me.txt_count].discover > systime()-me.sensor.searchStart,",  shown ",me.items[me.txt_count].discoverSCT," now",me.sensor.searchCounter);
                    if (!me.check or (!me.checkFresh and !me.checkFading) ) {
                        me.root.rdrTxt[me.txt_count].hide();
                        continue;
                    }
                    me.root.rdrTxt[me.txt_count].show();
                    me.data = me.items[me.txt_count];
                    append(me.clickableItems, me.data);
                    if (me.checkFresh) {
                        me.data.discoverShown = me.data.discover;
                        me.data.discoverSCTShown = me.data.discoverSCT;
                    }
                    me.dataPos = [me.extrapolate(me.data.pos[0], me.sensor.x[0], me.sensor.x[1], me.root.fieldX, me.root.fieldX + me.root.fieldW), me.extrapolate(me.data.pos[1], me.sensor.y[0], me.sensor.y[1], me.root.fieldY + me.root.fieldH, me.root.fieldY)];
                    me.data.xyPos = me.dataPos;
                    me.root.rdrTxt[me.txt_count].setText(me.data.mdl~me.data.radiSpike);
                    me.root.rdrTxt[me.txt_count].setTranslation(me.dataPos);
                    if (!me.topCheck[me.data.tblIdx]) {
                        me.topLine ~= me.data.mdl~"   ";
                        me.topCheck[me.data.tblIdx] = 1;
                    }
                }
                me.root.topBoxText.setText(me.topLine);
                if (cursor_click == me.root.index) {
                    me.handoffTarget = me.click(me.clickableItems);
                    if (me.handoffTarget != nil) {
                        me.sensor.handoffTime = systime();
                        me.sensor.handoffTarget = me.handoffTarget;
                    }
                    cursor_click = -1;
                }
            } else {
                me.root.crossX.show();
                me.root.crossY.show();
                me.root.crossX1.show();
                me.root.crossX2.show(); 
                me.root.crossX3.show();
                me.root.crossX4.show();
                me.root.crossX5.show();
                me.root.crossX6.show();
                me.root.crossY1.show();
                me.root.crossY2.show();
                me.root.crossY2.show();
                #me.root.dashBox.show();
                me.root.cross.hide();
                me.topLine = "   ";
                me.topCheck = [0,0,0,0,0];
                me.root.topBoxText.setText(me.topLine);

                for (me.txt_count = 0; me.txt_count < 5; me.txt_count += 1) {
                    me.root.rdrTxt[me.txt_count].hide();
                }

                if (cursor_click == me.root.index) {
                    cursor_click = -1;
                }
            }

            if (me.sensor.handoffTarget == nil and me.harmSelected) {
                me.radWeap.clearTgt();
                me.radWeap.setContacts([]);
            }
        };
        me.p_HARM.click = func (items) {
            me.clostestItem = nil;
            me.clostestDist = 10000;

            foreach(me.citem; items) {
                if (me.citem["xyPos"] == nil) continue;
                me.xx = math.abs(me.citem.xyPos[0]-cursor_posHAS[0]);
                me.yy = math.abs(me.citem.xyPos[1]-(cursor_posHAS[1] + 482));
                me.cdist = math.sqrt(me.xx*me.xx+me.yy*me.yy);
                if (me.cdist < me.clostestDist) {
                    me.clostestDist = me.cdist;
                    me.clostestItem = me.citem;
                }
            }
            if (me.clostestDist < 20) {
                return me.clostestItem;
            }
        };
        me.p_HARM.interpolate = func (x, x1, x2, y1, y2) {
            return math.clamp(y1 + ((x - x1) / (x2 - x1)) * (y2 - y1),y1,y2);
        };
        me.p_HARM.extrapolate = func (x, x1, x2, y1, y2) {
            return y1 + ((x - x1) / (x2 - x1)) * (y2 - y1);
        };        
    },


#   █████  ██████  ██████      ██████   █████   ██████  ███████ ███████ 
#  ██   ██ ██   ██ ██   ██     ██   ██ ██   ██ ██       ██      ██      
#  ███████ ██   ██ ██   ██     ██████  ███████ ██   ███ █████   ███████ 
#  ██   ██ ██   ██ ██   ██     ██      ██   ██ ██    ██ ██           ██ 
#  ██   ██ ██████  ██████      ██      ██   ██  ██████  ███████ ███████ 
#                                                                       
#
    addPages : func
    {
        me.addVoid();
        me.addGrid();
        me.addCube();
        me.addRadar();
        me.addSMS();
        me.addHSD();
        me.addWPN();
        me.addList();
        me.addRList();
        me.addRMList();
        me.addDTE();
        me.addHARM();

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



        me.mfd_button_pushed = 0;
        me.setupMenus();
        setlistener("/f16/avionics/power-mfd-bit", func(node) {
            if (node.getValue() == 0) {
                me.PFD.selectPage(me.p_VOID);
                me.selectionBox.hide();
            } elsif (node.getValue() == 1) {
                me.PFD.selectPage(me.p_GRID);
                me.selectionBox.hide();
            } elsif (node.getValue() == 2) {
                me.PFD.selectPage(me.p_CUBE);
                me.selectionBox.hide();
            } elsif (node.getValue() == 3) {
                if (me.model_index == 0) {
                    me.PFD.selectPage(me.p_RDR);
                    me.setSelection(nil, me.PFD.buttons[10], 10);
                } else {
                    me.PFD.selectPage(me.p_HSD);
                    me.setSelection(me.PFD.buttons[10], me.PFD.buttons[16], 16);
                }
                me.selectionBox.show();
            }
        }, 1, 0);
    },

    setSelectionColor : func(text) {
        text.setColor(colorBackground);
    },

    resetColor: func(text) {
        if (text != nil) {
            text.setColor(colorText1);
        }
    },
	resetColorAll: func() {
		foreach (var button; me.PFD.buttons) {
			me.resetColor(button);
		}
	},

    #Update this when adding new buttons or changing button order/positions.
    setSelection: func(curPage, nextPage, nextPageIndex) {
        if (nextPageIndex == 10) {
            me.selectionBox.setTranslation(65,7);
            me.selectionBox.setScale(1,1);
        } else if (nextPageIndex == 13) {
            me.selectionBox.setTranslation(272,7);
            me.selectionBox.setScale(1.43,1);#CTNL is 4 letters
        } else if (nextPageIndex == 16) {
            me.selectionBox.setTranslation(135,450);
            me.selectionBox.setScale(1,1);
        } else if (nextPageIndex == 17) {
             me.selectionBox.setTranslation(208,450);
             me.selectionBox.setScale(1,1);
        } else if (nextPageIndex == 18) {
            me.selectionBox.setTranslation(272,450);
            me.selectionBox.setScale(1,1);
        } else if (nextPageIndex == 7) {
            me.selectionBox.setTranslation(383,219);#dte
            me.selectionBox.setScale(1,1);
        } else {
            print("Make sure buttons are correctly set in setSelection() in MFD_main.nas");
            return;
        }
        me.setSelectionColor(nextPage);
        me.resetColor(curPage);
    },


#  ███    ███ ███████ ███    ██ ██    ██ ███████ 
#  ████  ████ ██      ████   ██ ██    ██ ██      
#  ██ ████ ██ █████   ██ ██  ██ ██    ██ ███████ 
#  ██  ██  ██ ██      ██  ██ ██ ██    ██      ██ 
#  ██      ██ ███████ ██   ████  ██████  ███████ 
#                                                
#
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

        #me.p_RDR.addMenuItem(18, "SIT", me.pjitds_1);
        me.p_RDR.addMenuItem(13, "CNTL", me.rm_LIST); #selectionColored
        me.p_RDR.addMenuItem(10, "", me.r_LIST); #selectionColored
        me.p_RDR.addMenuItem(15, "SWAP", nil);
        me.p_RDR.addMenuItem(16, "HSD", me.p_HSD);
        me.p_RDR.addMenuItem(17, "SMS", me.p_SMS);
        me.p_RDR.addMenuItem(18, "WPN", me.p_WPN);
        me.p_RDR.addMenuItem(19, "TGP", nil);

        #me.p_HSD.addMenuItem(18, "SIT", me.pjitds_1);
        me.p_HSD.addMenuItem(10, "FCR", me.p_RDR);
        me.p_HSD.addMenuItem(15, "SWAP", nil);
        me.p_HSD.addMenuItem(16, "HSD", me.p_LIST); #selectionColored
        me.p_HSD.addMenuItem(17, "SMS", me.p_SMS);
        me.p_HSD.addMenuItem(18, "WPN", me.p_WPN);
        me.p_HSD.addMenuItem(19, "TGP", nil);

        me.p_HARM.addMenuItem(10, "HAS", me.p_LIST); #selectionColored
        me.p_HARM.addMenuItem(15, "SWAP", nil);
        me.p_HARM.addMenuItem(16, "HSD", me.p_HSD);
        me.p_HARM.addMenuItem(17, "SMS", me.p_SMS);
        me.p_HARM.addMenuItem(18, "WPN", me.p_WPN);
        me.p_HARM.addMenuItem(19, "TGP", nil);

        me.p_WPN.addMenuItem(10, "FCR", me.p_RDR);
        me.p_WPN.addMenuItem(15, "SWAP", nil);
        me.p_WPN.addMenuItem(16, "HSD", me.p_HSD);
        me.p_WPN.addMenuItem(17, "SMS", me.p_SMS);
        me.p_WPN.addMenuItem(18, "WPN", me.p_LIST); #selectionColored
        me.p_WPN.addMenuItem(19, "TGP", nil);

        #me.p_SMS.addMenuItem(18, "SIT", me.pjitds_1);
        me.p_SMS.addMenuItem(10, "FCR", me.p_RDR);
        me.p_SMS.addMenuItem(15, "SWAP", nil);
        me.p_SMS.addMenuItem(16, "HSD", me.p_HSD);
        me.p_SMS.addMenuItem(17, "SMS", me.p_LIST); #selectionColored
        me.p_SMS.addMenuItem(18, "WPN", me.p_WPN);
        me.p_SMS.addMenuItem(19, "TGP", nil);

        #  CRM
#   10  11  12  13  14
# 0                    5
# 1                    6
# 2                    7
# 3                    8
# 4                    9
#   15  16  17  18  19
#  VSD HSD SMS SIT

        me.p_LIST.addMenuItem(10, "BLANK", nil);
        me.p_LIST.addMenuItem(11, "HAS", me.p_HARM);
        me.p_LIST.addMenuItem(13, "RCCE", nil);
        me.p_LIST.addMenuItem(14, "RESET\n MENU", nil);
        me.p_LIST.addMenuItem(15, "SWAP", nil);
        me.p_LIST.addMenuItem(19, "TCN", nil);
        me.p_LIST.addMenuItem(0, "FCR", me.p_RDR);
        me.p_LIST.addMenuItem(1, "TGP", nil);
        me.p_LIST.addMenuItem(2, "WPN", me.p_WPN);
        me.p_LIST.addMenuItem(3, "TFR", nil);
        me.p_LIST.addMenuItem(4, "FLIR", nil);
        me.p_LIST.addMenuItem(5, "SMS", me.p_SMS);
        me.p_LIST.addMenuItem(6, "HSD", me.p_HSD);
        me.p_LIST.addMenuItem(7, "DTE", me.p_DTE);
        me.p_LIST.addMenuItem(8, "TEST", nil);
        me.p_LIST.addMenuItem(9, "FLCS", nil);

        me.r_LIST.addMenuItem(0, "CRM", nil);
        me.r_LIST.addMenuItem(1, "ACM", nil);
        me.r_LIST.addMenuItem(2, "SEA", nil);
        me.r_LIST.addMenuItem(3, "GM", nil);
        me.r_LIST.addMenuItem(4, "GMT", nil);

        me.p_DTE.addMenuItem(1, "LOAD", nil);
        me.p_DTE.addMenuItem(3, "SAVE", nil);
        me.p_DTE.addMenuItem(7, "DTE", me.p_LIST);
        me.p_DTE.addMenuItem(15, "SWAP", nil);

        me.rm_LIST.addMenuItem(13, "CNTL", me.p_RDR);



        me.setFontSizeMFDEdgeButton(0, 18);
        me.setFontSizeMFDEdgeButton(1, 18);
        me.setFontSizeMFDEdgeButton(2, 18);
        me.setFontSizeMFDEdgeButton(3, 18);
        me.setFontSizeMFDEdgeButton(4, 18);
        me.setFontSizeMFDEdgeButton(5, 18);
        me.setFontSizeMFDEdgeButton(6, 18);
        me.setFontSizeMFDEdgeButton(7, 18);
        me.setFontSizeMFDEdgeButton(8, 18);
        me.setFontSizeMFDEdgeButton(9, 18);
        me.setFontSizeMFDEdgeButton(10, 18);
        me.setFontSizeMFDEdgeButton(11, 18);
        me.setFontSizeMFDEdgeButton(12, 18);
        me.setFontSizeMFDEdgeButton(13, 18);
        me.setFontSizeMFDEdgeButton(14, 18);
        me.setFontSizeMFDEdgeButton(15, 18);
        me.setFontSizeMFDEdgeButton(16, 18);
        me.setFontSizeMFDEdgeButton(17, 18);
        me.setFontSizeMFDEdgeButton(18, 18);
        me.setFontSizeMFDEdgeButton(19, 18);
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
var flyupTime = 0;
var flyupVis = 0;
PFD_Device.update = func(notification=nil)
    {
        if (me.current_page != nil) {
            me.current_page.update(notification);
            flyupTime = getprop("instrumentation/radar/time-till-crash");
            if (me.current_page != "GRID" and me.current_page != "CUBE" and me.current_page != "VOID" and flyupTime != nil and flyupTime > 0 and flyupTime < 8) {
                flyupVis = math.mod(getprop("sim/time/elapsed-sec"), 0.50) < 0.25;
            } else {
                flyupVis = 0;
            }
            pullup_cue_0.setVisible(flyupVis);
            pullup_cue_1.setVisible(flyupVis);
        }
    };

#F16MfdRecipient.new("BAe-F16b-MFD");
var f16_mfd = nil;
var startupMFD = func {
    f16_mfd = F16MfdRecipient.new("F16-MFD");
}
#UpperMFD = f16_mfd.UpperMFD;
#LowerMFD = f16_mfd.LowerMFD;

#emesary.GlobalTransmitter.Register(f16_mfd);


# This is old cursor system for clicking in 3D, part 3
var uv = nil;
var cursor_destination = nil;

# Cursor stuff
var cursor_pos = [100,-100];
var cursor_posHAS = [0,-241];
var cursor_click = -1;
var cursor_lock = -1;
var exp = 0;



setlistener("controls/displays/cursor-click", func {if (getprop("controls/displays/cursor-click")) {slew_c = 1;}});

var cursorZero = func {
    cursor_pos = [0,-241];
}
cursorZero();

var setCursor = func (x, y, screen) {
    #552,482 , 0.795 is for UV map
    uv = [x*552-552*0.5*0.795,-y*486,screen, systime()];
    #printf("slew %d,%d on screen %d", uv[0],uv[1],uv[2]);
};

#update this when adding a new button/updating button order
var getMenuButton = func (pageName) {
    if (pageName == "Radar") {
        return 10;
    } else if (pageName == "SMS") {
        return 17;
    } else if (pageName == "HSD") {
        return 16;
    } else if (pageName == "WPN") {
        return 18;
    } elsif (pageName == "LIST") {
        return nil;
    } elsif (pageName == "VOID") {
        return nil;
    } elsif (pageName == "GRID") {
        return nil;
    } elsif (pageName == "CUBE") {
        return nil;
    } elsif (pageName == "DTE") {
        return 7;
    } elsif (pageName == "HAS") {
        return nil;#HARM
    } else {
        print("Make sure button assignment is set correctly in getMenuButton() in MFD_main.nas");
        return nil;
    }
};

var swap = func {
    var left_page = f16_mfd.MFDl.PFD.current_page.title;
    var right_page = f16_mfd.MFDr.PFD.current_page.title;
    var left_button = getMenuButton(left_page);
    var right_button = getMenuButton(right_page);

    foreach(var page ; f16_mfd.MFDr.PFD.pages) {
        if (page.title == left_page) {
            f16_mfd.MFDr.PFD.selectPage(page);
			break;
        }
    }
    foreach(var page ; f16_mfd.MFDl.PFD.pages) {
        if (page.title == right_page) {
            f16_mfd.MFDl.PFD.selectPage(page);
			break;
        }
    }
    if (f16.SOI == 2) {
        f16.SOI = 3;
    } elsif (f16.SOI == 3) {
        f16.SOI = 2;
    }

	if (right_page == "LIST") { # right page was list
		f16_mfd.MFDl.selectionBox.hide();
		f16_mfd.MFDl.resetColorAll();
		if (left_page != "LIST") {
			f16_mfd.MFDr.selectionBox.show();
			f16_mfd.MFDr.setSelection(nil, f16_mfd.MFDr.PFD.buttons[left_button], left_button);
		}
	} elsif (left_page == "LIST") {
		f16_mfd.MFDr.selectionBox.hide();
		f16_mfd.MFDr.resetColorAll();
		if (right_page != "LIST") {
			f16_mfd.MFDl.selectionBox.show();
			f16_mfd.MFDl.setSelection(nil, f16_mfd.MFDl.PFD.buttons[right_button], right_button);
		}
	}

    if (left_button != nil and right_button != nil) {
        f16_mfd.MFDl.setSelection(f16_mfd.MFDl.PFD.buttons[left_button], f16_mfd.MFDl.PFD.buttons[right_button], right_button);
        f16_mfd.MFDr.setSelection(f16_mfd.MFDr.PFD.buttons[right_button], f16_mfd.MFDr.PFD.buttons[left_button], left_button);
    }
};

var get_intercept = func(bearingToRunner, dist_m, runnerHeading, runnerSpeed, chaserSpeed, chaserCoord, chaserHeading) {
    # from Leto
    # needs: bearingToRunner_deg, dist_m, runnerHeading_deg, runnerSpeed_mps, chaserSpeed_mps, chaserCoord
    #        dist_m > 0 and chaserSpeed > 0

    if (dist_m < 500) {
        return nil;
    }

    var trigAngle = 90-bearingToRunner;
    var RunnerPosition = [dist_m*math.cos(trigAngle*D2R), dist_m*math.sin(trigAngle*D2R),0];
    var ChaserPosition = [0,0,0];

    var VectorFromRunner = vector.Math.minus(ChaserPosition, RunnerPosition);
    var runner_heading = 90-runnerHeading;
    var RunnerVelocity = [runnerSpeed*math.cos(runner_heading*D2R), runnerSpeed*math.sin(runner_heading*D2R),0];

    var a = chaserSpeed * chaserSpeed - runnerSpeed * runnerSpeed;
    var b = 2 * vector.Math.dotProduct(VectorFromRunner, RunnerVelocity);
    var c = -dist_m * dist_m;

    if ((b*b-4*a*c)<0) {
      # intercept not possible
      return nil;
    }

    var t1 = (-b+math.sqrt(b*b-4*a*c))/(2*a);
    var t2 = (-b-math.sqrt(b*b-4*a*c))/(2*a);

    if (t1 < 0 and t2 < 0) {
      # intercept not possible
      return nil;
    }

    var timeToIntercept = 0;
    if (t1 > 0 and t2 > 0) {
          timeToIntercept = math.min(t1, t2);
    } else {
          timeToIntercept = math.max(t1, t2);
    }
    var InterceptPosition = vector.Math.plus(RunnerPosition, vector.Math.product(timeToIntercept, RunnerVelocity));

    var ChaserVelocity = vector.Math.product(1/timeToIntercept, vector.Math.minus(InterceptPosition, ChaserPosition));

    var interceptAngle = vector.Math.angleBetweenVectors([0,1,0], ChaserVelocity);
    var interceptHeading = geo.normdeg(ChaserVelocity[0]<0?-interceptAngle:interceptAngle);

    var interceptDist = chaserSpeed*timeToIntercept;

    var interceptCoord = geo.Coord.new(chaserCoord);
    interceptCoord = interceptCoord.apply_course_distance(interceptHeading, interceptDist);
    var interceptRelativeBearing = geo.normdeg180(interceptHeading-chaserHeading);

    return [timeToIntercept, interceptHeading, interceptCoord, interceptDist, interceptRelativeBearing];
}

var switchTGP = func {
    view.setViewByIndex(105);
}

var vector_aicontacts_links = [];
var DLRecipient = emesary.Recipient.new("DLRecipient");
var startDLListener = func {
    DLRecipient.radar = radar_system.dlnkRadar;
    DLRecipient.Receive = func(notification) {
        if (notification.NotificationType == "DatalinkNotification") {
            #printf("DL recv: %s", notification.NotificationType);
            if (me.radar.enabled == 1) {
                vector_aicontacts_links = notification.vector;
            }
            return emesary.Transmitter.ReceiptStatus_OK;
        }
        return emesary.Transmitter.ReceiptStatus_NotProcessed;
    };
    emesary.GlobalTransmitter.Register(DLRecipient);
}