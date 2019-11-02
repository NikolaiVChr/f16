EHSI = {
    new: func (ident, root, center, diameter) {
        var ehsi = {parents: [EHSI]};
                        
        ehsi.fontCompass       = int(0.045*diameter);
        ehsi.fontCompassAspect = 1.0;
        ehsi.font       = int(0.065*diameter);
        ehsi.fontAspect = 1.0;
        
        var colorW  = [1,1,1];
        var colorB  = [0,0,0];
        var colorR  = [1,0,0];
        var colorLB = [0.6,0.6,1];
        var colorLY = [1,1,0.65];
        
        ehsi.rootCenter = root.createChild("group")
                .setTranslation(center[0],center[1])
                .set("font", "LiberationFonts/LiberationMono-Regular.ttf");
        ehsi.compassMainGroup = ehsi.rootCenter.createChild("group").set("z-index",1);
        ehsi.compassGroup = ehsi.compassMainGroup.createChild("group").set("z-index",1);
        ehsi.arrowGroup = ehsi.compassMainGroup.createChild("group").set("z-index",10);
        ehsi.arrowOuterGroup = ehsi.rootCenter.createChild("group").set("z-index",10);
        
        ehsi.compassRadius = 0.32*diameter;
        ehsi.tickRadius = 0.42*diameter;
        ehsi.tickRadiusOuter = 0.475*diameter;
        ehsi.tick_short = 0.04*diameter;
        ehsi.tick_long  = 0.06*diameter;
        ehsi.tick_outer  = ehsi.tick_short;
        ehsi.cdiMaxMovement = ehsi.tickRadius*0.5;
        ehsi.cdiDotRadius = ehsi.tick_short*0.25;
        ehsi.ownshipSize = ehsi.tick_short;
        ehsi.toFromWidth = ehsi.cdiMaxMovement*0.5-ehsi.cdiDotRadius*2;
        
        ehsi.txtCRS = ehsi.rootCenter.createChild("text")
                .setText("123")
                .setAlignment("right-top")
                .setColor(colorW)
                .setTranslation(diameter*0.475,-diameter*0.475)
                .setFontSize(ehsi.font, ehsi.fontAspect);
        ehsi.txtCRS2 = ehsi.rootCenter.createChild("text")
                .setText("CRS")
                .setAlignment("right-top")
                .setColor(colorW)
                .setTranslation(diameter*0.475,-diameter*0.425)
                .setFontSize(ehsi.fontCompass, ehsi.fontCompassAspect);
        ehsi.txtDist = ehsi.rootCenter.createChild("text")
                .setText("DME")
                .setAlignment("left-top")
                .setColor(colorW)
                .setTranslation(-diameter*0.475,-diameter*0.475)
                .setFontSize(ehsi.font, ehsi.fontAspect);
        ehsi.txtDistMinor = ehsi.rootCenter.createChild("text")
                .setText("+")
                .setAlignment("left-top")
                .setColor(colorB)
                .setTranslation(-diameter*0.390+ehsi.font*0.5,-diameter*0.475)
                .set("z-index",10)
                .setFontSize(ehsi.font, ehsi.fontAspect);
        ehsi.txtDist2 = ehsi.rootCenter.createChild("text")
                .setText("NM")
                .setAlignment("left-top")
                .setColor(colorW)
                .setTranslation(-diameter*0.475,-diameter*0.425)
                .setFontSize(ehsi.fontCompass, ehsi.fontCompassAspect);
        ehsi.txtNote = ehsi.rootCenter.createChild("text")
                .setText("Mode")
                .setAlignment("center-bottom")
                .setColor(colorW)
                .setTranslation(0,0)
                .set("z-index",100)
                .setFontSize(ehsi.font, ehsi.fontAspect);
        ehsi.distMinor = ehsi.rootCenter.createChild("path")
           .moveTo(-diameter*0.410+ehsi.font*0.5*1.6666,-diameter*0.475)
           .horiz(ehsi.font*0.5)
           .vert(ehsi.font*0.75)
           .horiz(-ehsi.font*0.5)
           .close()
           .setColor(colorW)
           .setColorFill(colorW)
           .set("z-index",5)
           .setStrokeLineWidth(1);
        ehsi.distCover = ehsi.rootCenter.createChild("path")
           .moveTo(-diameter*0.475,-diameter*0.45-ehsi.font*0.125)
           .horiz(ehsi.font*2.5)
           .vert(ehsi.font*0.25)
           .horiz(-ehsi.font*2.5)
           .close()
           .setColor(colorR)
           .setColorFill(colorR)
           .set("z-index",15)
           .setStrokeLineWidth(1);
        ehsi.txtModeL = ehsi.rootCenter.createChild("text")
                .setText("PL.")
                .setAlignment("center-bottom")
                .setColor(colorW)
                .setTranslation(-diameter*0.175,diameter*0.475)
                .setFontSize(ehsi.fontCompass, ehsi.fontCompassAspect);
        ehsi.txtModeR = ehsi.rootCenter.createChild("text")
                .setText("TC.")
                .setAlignment("center-bottom")
                .setColor(colorW)
                .setTranslation(diameter*0.175,diameter*0.475)
                .setFontSize(ehsi.fontCompass, ehsi.fontCompassAspect);
                
        ehsi.txtKnobR = ehsi.rootCenter.createChild("text")
                .setText("    S\n  R\nC")
                .setAlignment("center-center")
                .setColor(colorW)
                .setTranslation(-(ehsi.tickRadiusOuter)*math.cos(135*D2R), (ehsi.tickRadiusOuter)*math.sin(135*D2R))
                .setFontSize(ehsi.fontCompass, ehsi.fontCompassAspect);
        
        ehsi.txtKnobL = ehsi.rootCenter.createChild("text")
                .setText("H\n  D\n    G")
                .setAlignment("center-center")
                .setColor(colorW)
                .setTranslation((ehsi.tickRadiusOuter)*math.cos(225*D2R)-ehsi.font*0.75, -(ehsi.tickRadiusOuter)*math.sin(225*D2R))
                .setFontSize(ehsi.fontCompass, ehsi.fontCompassAspect);
        
        ehsi.ownship = ehsi.rootCenter.createChild("path")
           .moveTo(0, -ehsi.ownshipSize*0.5)
           .vert(ehsi.ownshipSize*2.5)
           .moveTo(-ehsi.ownshipSize, 0)
           .horiz(ehsi.ownshipSize*2)
           .moveTo(-ehsi.ownshipSize*0.5, ehsi.ownshipSize*1.5)
           .horiz(ehsi.ownshipSize)
           .setColor(colorW)
           .set("z-index",50)
           .setStrokeLineWidth(1.5);
           
        ehsi.cdiInvalid = ehsi.arrowGroup.createChild("path")
           .moveTo(-ehsi.cdiMaxMovement,-ehsi.toFromWidth)
           .horiz(ehsi.toFromWidth*2)
           .vert(-ehsi.toFromWidth)
           .horiz(-ehsi.toFromWidth*2)
           .close()
           .setColor(colorR)
           .setColorFill(colorR)
           .set("z-index",4)
           .setStrokeLineWidth(1);
        
        ehsi.to = ehsi.arrowGroup.createChild("path")
           .moveTo(ehsi.cdiMaxMovement*0.5+ehsi.cdiDotRadius,-ehsi.toFromWidth*0.5)
           .horiz(ehsi.toFromWidth)
           .lineTo(ehsi.cdiMaxMovement*0.5+ehsi.cdiDotRadius+ehsi.toFromWidth*0.5,-ehsi.toFromWidth*1.0)
           .close()
           .setColor(colorW)
           .setColorFill(colorW)
           .set("z-index",4)
           .setStrokeLineWidth(1);
           
        ehsi.from = ehsi.arrowGroup.createChild("path")
           .moveTo(ehsi.cdiMaxMovement*0.5+ehsi.cdiDotRadius, ehsi.toFromWidth*0.5)
           .horiz(ehsi.toFromWidth)
           .lineTo(ehsi.cdiMaxMovement*0.5+ehsi.cdiDotRadius+ehsi.toFromWidth*0.5,ehsi.toFromWidth*1.0)
           .close()
           .setColor(colorW)
           .setColorFill(colorW)
           .set("z-index",4)
           .setStrokeLineWidth(1);
           
        ehsi.captBars = ehsi.compassMainGroup.createChild("path")
           .moveTo(1, -(ehsi.tickRadius+ehsi.tick_short*0.3333))
           .vert(ehsi.tick_short*0.6666)
           .horiz(ehsi.tick_short*0.6666)
           .vert(-ehsi.tick_short*0.6666)
           .horiz(-ehsi.tick_short*0.6666)
           .close()
           .moveTo(-1, -(ehsi.tickRadius+ehsi.tick_short*0.3333))
           .vert(ehsi.tick_short*0.6666)
           .horiz(-ehsi.tick_short*0.6666)
           .vert(-ehsi.tick_short*0.6666)
           .horiz(ehsi.tick_short*0.6666)
           .close()
           .setColor(colorLY)
           .setColorFill(colorLY)
           .set("z-index",8)
           .setStrokeLineWidth(1);
        
        ehsi.cdiDots = ehsi.arrowGroup.createChild("path")
           .moveTo(ehsi.cdiMaxMovement*0.5-ehsi.cdiDotRadius,0)
           .arcSmallCW(ehsi.cdiDotRadius, ehsi.cdiDotRadius, 0, ehsi.cdiDotRadius*2, 0)
           .arcSmallCW(ehsi.cdiDotRadius, ehsi.cdiDotRadius, 0, -ehsi.cdiDotRadius*2, 0)
           .close()
           .moveTo(ehsi.cdiMaxMovement*1-ehsi.cdiDotRadius,0)
           .arcSmallCW(ehsi.cdiDotRadius, ehsi.cdiDotRadius, 0, ehsi.cdiDotRadius*2, 0)
           .arcSmallCW(ehsi.cdiDotRadius, ehsi.cdiDotRadius, 0, -ehsi.cdiDotRadius*2, 0)
           .close()
           .moveTo(-ehsi.cdiMaxMovement*0.5-ehsi.cdiDotRadius,0)
           .arcSmallCW(ehsi.cdiDotRadius, ehsi.cdiDotRadius, 0, ehsi.cdiDotRadius*2, 0)
           .arcSmallCW(ehsi.cdiDotRadius, ehsi.cdiDotRadius, 0, -ehsi.cdiDotRadius*2, 0)
           .close()
           .moveTo(-ehsi.cdiMaxMovement*1-ehsi.cdiDotRadius,0)
           .arcSmallCW(ehsi.cdiDotRadius, ehsi.cdiDotRadius, 0, ehsi.cdiDotRadius*2, 0)
           .arcSmallCW(ehsi.cdiDotRadius, ehsi.cdiDotRadius, 0, -ehsi.cdiDotRadius*2, 0)
           .close()
           .setStrokeLineWidth(1)
           .setColorFill(colorW)
           .setColor(colorW)
           .set("z-index",4);
        
        ehsi.arrowInnerHead = ehsi.arrowGroup.createChild("path")
                .moveTo(0, -(ehsi.tickRadius-ehsi.tick_long))
                .lineTo(ehsi.tick_long*0.5,-(ehsi.tickRadius-ehsi.tick_long-ehsi.tick_long*1.5))
                .horiz(-ehsi.tick_long*0.45)
                .vert(ehsi.tick_long)
                .horiz(-ehsi.tick_long*0.10)
                .vert(-ehsi.tick_long)
                .horiz(-ehsi.tick_long*0.45)
                .close()
                .setColor(colorLB)
                .setColorFill(colorLB)
                .set("z-index",6)
                .setStrokeLineWidth(1);
        ehsi.arrowInnerSolid = ehsi.arrowGroup.createChild("path")
                .moveTo(ehsi.tick_long*0.05, ehsi.tickRadius-ehsi.tick_long*3.5)
                .horiz(-ehsi.tick_long*0.10)
                .vert(2*(-ehsi.tickRadius+ehsi.tick_long*3.5))
                .horiz(ehsi.tick_long*0.10)
                .close()
                .setColor(colorLB)
                .setColorFill(colorLB)
                .set("z-index",6)
                .setStrokeLineWidth(1);
        var segment = 2*(-ehsi.tickRadius+ehsi.tick_long*3.5)/11;
        ehsi.arrowInnerSegment = ehsi.arrowGroup.createChild("path")
                .moveTo(ehsi.tick_long*0.05, ehsi.tickRadius-ehsi.tick_long*3.5)
                .horiz(-ehsi.tick_long*0.10)
                .vert(segment)
                .horiz(ehsi.tick_long*0.10)
                .close()
                .moveTo(ehsi.tick_long*0.05, ehsi.tickRadius-ehsi.tick_long*3.5+segment*2)
                .horiz(-ehsi.tick_long*0.10)
                .vert(segment)
                .horiz(ehsi.tick_long*0.10)
                .close()
                .moveTo(ehsi.tick_long*0.05, ehsi.tickRadius-ehsi.tick_long*3.5+segment*4)
                .horiz(-ehsi.tick_long*0.10)
                .vert(segment)
                .horiz(ehsi.tick_long*0.10)
                .close()
                .moveTo(ehsi.tick_long*0.05, ehsi.tickRadius-ehsi.tick_long*3.5+segment*6)
                .horiz(-ehsi.tick_long*0.10)
                .vert(segment)
                .horiz(ehsi.tick_long*0.10)
                .close()
                .moveTo(ehsi.tick_long*0.05, ehsi.tickRadius-ehsi.tick_long*3.5+segment*8)
                .horiz(-ehsi.tick_long*0.10)
                .vert(segment)
                .horiz(ehsi.tick_long*0.10)
                .close()
                .moveTo(ehsi.tick_long*0.05, ehsi.tickRadius-ehsi.tick_long*3.5+segment*10)
                .horiz(-ehsi.tick_long*0.10)
                .vert(segment)
                .horiz(ehsi.tick_long*0.10)
                .close()
                .setColor(colorLB)
                .setColorFill(colorLB)
                .set("z-index",6)
                .setStrokeLineWidth(1);
        ehsi.arrowInnerTail = ehsi.arrowGroup.createChild("path")
                .moveTo(ehsi.tick_long*0.05, ehsi.tickRadius-ehsi.tick_long)
                .horiz(-ehsi.tick_long*0.10)
                .vert(-ehsi.tick_long*2.5)
                .horiz(ehsi.tick_long*0.10)
                .close()
                .setColor(colorLB)
                .setColorFill(colorLB)
                .set("z-index",6)
                .setStrokeLineWidth(1);
                
        ehsi.arrowOuterHead = ehsi.arrowOuterGroup.createChild("path")
                .moveTo(0, -(ehsi.tickRadius))
                .lineTo(ehsi.tick_short*0.5,-(ehsi.tickRadius-ehsi.tick_short))
                .horiz(-ehsi.tick_short*0.45)
                .vert(ehsi.tick_short)
                .horiz(-ehsi.tick_short*0.10)
                .vert(-ehsi.tick_short)
                .horiz(-ehsi.tick_short*0.45)
                .close()
                .setColor(colorLB)
                .setColorFill(colorLB)
                .setStrokeLineWidth(1);
        ehsi.arrowOuterTail = ehsi.arrowOuterGroup.createChild("path")
                .moveTo(ehsi.tick_short*0.05, ehsi.tickRadius+ehsi.tick_short)
                .horiz(-ehsi.tick_short*0.10)
                .vert(-ehsi.tick_short*2)
                .horiz(ehsi.tick_short*0.10)
                .close()
                .setColor(colorLB)
                .setColorFill(colorLB)
                .setStrokeLineWidth(1);
        
        
        ehsi.c0 = ehsi.compassGroup.createChild("text")
                .setText("N")
                .setAlignment("center-center")
                .setColor(colorW)
                .setTranslation(ehsi.compassRadius*math.cos(-90*D2R), ehsi.compassRadius*math.sin(-90*D2R))
                .setRotation(0)
                .setFontSize(ehsi.fontCompass, ehsi.fontCompassAspect);
        ehsi.c3 = ehsi.compassGroup.createChild("text")
                .setText("3")
                .setAlignment("center-center")
                .setColor(colorW)
                .setTranslation(ehsi.compassRadius*math.cos(-60*D2R), ehsi.compassRadius*math.sin(-60*D2R))
                .setRotation(30*D2R)
                .setFontSize(ehsi.fontCompass, ehsi.fontCompassAspect);
        ehsi.c6 = ehsi.compassGroup.createChild("text")
                .setText("6")
                .setAlignment("center-center")
                .setColor(colorW)
                .setTranslation(ehsi.compassRadius*math.cos(-30*D2R), ehsi.compassRadius*math.sin(-30*D2R))
                .setRotation(60*D2R)
                .setFontSize(ehsi.fontCompass, ehsi.fontCompassAspect);
        ehsi.c9 = ehsi.compassGroup.createChild("text")
                .setText("E")
                .setAlignment("center-center")
                .setColor(colorW)
                .setTranslation(ehsi.compassRadius*math.cos(0*D2R), ehsi.compassRadius*math.sin(0*D2R))
                .setRotation(90*D2R)
                .setFontSize(ehsi.fontCompass, ehsi.fontCompassAspect);
        ehsi.c12 = ehsi.compassGroup.createChild("text")
                .setText("12")
                .setAlignment("center-center")
                .setColor(colorW)
                .setTranslation(ehsi.compassRadius*math.cos(30*D2R), ehsi.compassRadius*math.sin(30*D2R))
                .setRotation(110*D2R)
                .setFontSize(ehsi.fontCompass, ehsi.fontCompassAspect);
        ehsi.c15 = ehsi.compassGroup.createChild("text")
                .setText("15")
                .setAlignment("center-center")
                .setColor(colorW)
                .setTranslation(ehsi.compassRadius*math.cos(60*D2R), ehsi.compassRadius*math.sin(60*D2R))
                .setRotation(140*D2R)
                .setFontSize(ehsi.fontCompass, ehsi.fontCompassAspect);
        ehsi.c18 = ehsi.compassGroup.createChild("text")
                .setText("S")
                .setAlignment("center-center")
                .setColor(colorW)
                .setTranslation(ehsi.compassRadius*math.cos(90*D2R), ehsi.compassRadius*math.sin(90*D2R))
                .setRotation(180*D2R)
                .setFontSize(ehsi.fontCompass, ehsi.fontCompassAspect);
        ehsi.c21 = ehsi.compassGroup.createChild("text")
                .setText("21")
                .setAlignment("center-center")
                .setColor(colorW)
                .setTranslation(ehsi.compassRadius*math.cos(120*D2R), ehsi.compassRadius*math.sin(120*D2R))
                .setRotation(210*D2R)
                .setFontSize(ehsi.fontCompass, ehsi.fontCompassAspect);
        ehsi.c24 = ehsi.compassGroup.createChild("text")
                .setText("24")
                .setAlignment("center-center")
                .setColor(colorW)
                .setTranslation(ehsi.compassRadius*math.cos(150*D2R), ehsi.compassRadius*math.sin(150*D2R))
                .setRotation(240*D2R)
                .setFontSize(ehsi.fontCompass, ehsi.fontCompassAspect);
        ehsi.c27 = ehsi.compassGroup.createChild("text")
                .setText("W")
                .setAlignment("center-center")
                .setColor(colorW)
                .setTranslation(ehsi.compassRadius*math.cos(180*D2R), ehsi.compassRadius*math.sin(180*D2R))
                .setRotation(270*D2R)
                .setFontSize(ehsi.fontCompass, ehsi.fontCompassAspect);
        ehsi.c30 = ehsi.compassGroup.createChild("text")
                .setText("30")
                .setAlignment("center-center")
                .setColor(colorW)
                .setTranslation(ehsi.compassRadius*math.cos(210*D2R), ehsi.compassRadius*math.sin(210*D2R))
                .setRotation(300*D2R)
                .setFontSize(ehsi.fontCompass, ehsi.fontCompassAspect);
        ehsi.c33 = ehsi.compassGroup.createChild("text")
                .setText("33")
                .setAlignment("center-center")
                .setColor(colorW)
                .setTranslation(ehsi.compassRadius*math.cos(240*D2R), ehsi.compassRadius*math.sin(240*D2R))
                .setRotation(330*D2R)
                .setFontSize(ehsi.fontCompass, ehsi.fontCompassAspect);
        ehsi.tick_shortlines = ehsi.compassGroup.createChild("path")
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(5*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(5*D2R))
                .lineTo(ehsi.tickRadius*math.cos(5*D2R), ehsi.tickRadius*math.sin(5*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(15*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(15*D2R))
                .lineTo(ehsi.tickRadius*math.cos(15*D2R), ehsi.tickRadius*math.sin(15*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(25*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(25*D2R))
                .lineTo(ehsi.tickRadius*math.cos(25*D2R), ehsi.tickRadius*math.sin(25*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(35*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(35*D2R))
                .lineTo(ehsi.tickRadius*math.cos(35*D2R), ehsi.tickRadius*math.sin(35*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(45*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(45*D2R))
                .lineTo(ehsi.tickRadius*math.cos(45*D2R), ehsi.tickRadius*math.sin(45*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(55*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(55*D2R))
                .lineTo(ehsi.tickRadius*math.cos(55*D2R), ehsi.tickRadius*math.sin(55*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(65*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(65*D2R))
                .lineTo(ehsi.tickRadius*math.cos(65*D2R), ehsi.tickRadius*math.sin(65*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(75*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(75*D2R))
                .lineTo(ehsi.tickRadius*math.cos(75*D2R), ehsi.tickRadius*math.sin(75*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(85*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(85*D2R))
                .lineTo(ehsi.tickRadius*math.cos(85*D2R), ehsi.tickRadius*math.sin(85*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(95*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(95*D2R))
                .lineTo(ehsi.tickRadius*math.cos(95*D2R), ehsi.tickRadius*math.sin(95*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(105*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(105*D2R))
                .lineTo(ehsi.tickRadius*math.cos(105*D2R), ehsi.tickRadius*math.sin(105*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(115*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(115*D2R))
                .lineTo(ehsi.tickRadius*math.cos(115*D2R), ehsi.tickRadius*math.sin(115*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(125*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(125*D2R))
                .lineTo(ehsi.tickRadius*math.cos(125*D2R), ehsi.tickRadius*math.sin(125*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(135*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(135*D2R))
                .lineTo(ehsi.tickRadius*math.cos(135*D2R), ehsi.tickRadius*math.sin(135*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(145*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(145*D2R))
                .lineTo(ehsi.tickRadius*math.cos(145*D2R), ehsi.tickRadius*math.sin(145*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(155*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(155*D2R))
                .lineTo(ehsi.tickRadius*math.cos(155*D2R), ehsi.tickRadius*math.sin(155*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(165*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(165*D2R))
                .lineTo(ehsi.tickRadius*math.cos(165*D2R), ehsi.tickRadius*math.sin(165*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(175*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(175*D2R))
                .lineTo(ehsi.tickRadius*math.cos(175*D2R), ehsi.tickRadius*math.sin(175*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(185*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(185*D2R))
                .lineTo(ehsi.tickRadius*math.cos(185*D2R), ehsi.tickRadius*math.sin(185*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(195*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(195*D2R))
                .lineTo(ehsi.tickRadius*math.cos(195*D2R), ehsi.tickRadius*math.sin(195*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(205*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(205*D2R))
                .lineTo(ehsi.tickRadius*math.cos(205*D2R), ehsi.tickRadius*math.sin(205*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(215*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(215*D2R))
                .lineTo(ehsi.tickRadius*math.cos(215*D2R), ehsi.tickRadius*math.sin(215*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(225*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(225*D2R))
                .lineTo(ehsi.tickRadius*math.cos(225*D2R), ehsi.tickRadius*math.sin(225*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(235*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(235*D2R))
                .lineTo(ehsi.tickRadius*math.cos(235*D2R), ehsi.tickRadius*math.sin(235*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(245*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(245*D2R))
                .lineTo(ehsi.tickRadius*math.cos(245*D2R), ehsi.tickRadius*math.sin(245*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(255*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(255*D2R))
                .lineTo(ehsi.tickRadius*math.cos(255*D2R), ehsi.tickRadius*math.sin(255*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(265*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(265*D2R))
                .lineTo(ehsi.tickRadius*math.cos(265*D2R), ehsi.tickRadius*math.sin(265*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(275*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(275*D2R))
                .lineTo(ehsi.tickRadius*math.cos(275*D2R), ehsi.tickRadius*math.sin(275*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(285*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(285*D2R))
                .lineTo(ehsi.tickRadius*math.cos(285*D2R), ehsi.tickRadius*math.sin(285*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(295*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(295*D2R))
                .lineTo(ehsi.tickRadius*math.cos(295*D2R), ehsi.tickRadius*math.sin(295*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(305*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(305*D2R))
                .lineTo(ehsi.tickRadius*math.cos(305*D2R), ehsi.tickRadius*math.sin(305*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(315*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(315*D2R))
                .lineTo(ehsi.tickRadius*math.cos(315*D2R), ehsi.tickRadius*math.sin(315*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(325*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(325*D2R))
                .lineTo(ehsi.tickRadius*math.cos(325*D2R), ehsi.tickRadius*math.sin(325*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(335*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(335*D2R))
                .lineTo(ehsi.tickRadius*math.cos(335*D2R), ehsi.tickRadius*math.sin(335*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(345*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(345*D2R))
                .lineTo(ehsi.tickRadius*math.cos(345*D2R), ehsi.tickRadius*math.sin(345*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_short)*math.cos(355*D2R), (ehsi.tickRadius-ehsi.tick_short)*math.sin(355*D2R))
                .lineTo(ehsi.tickRadius*math.cos(355*D2R), ehsi.tickRadius*math.sin(355*D2R))
                .setColor(colorW)
                .setStrokeLineWidth(1.5);
                
        ehsi.tick_longlines1 = ehsi.compassGroup.createChild("path")
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(10*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(10*D2R))
                .lineTo(ehsi.tickRadius*math.cos(10*D2R), ehsi.tickRadius*math.sin(10*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(20*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(20*D2R))
                .lineTo(ehsi.tickRadius*math.cos(20*D2R), ehsi.tickRadius*math.sin(20*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(40*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(40*D2R))
                .lineTo(ehsi.tickRadius*math.cos(40*D2R), ehsi.tickRadius*math.sin(40*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(50*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(50*D2R))
                .lineTo(ehsi.tickRadius*math.cos(50*D2R), ehsi.tickRadius*math.sin(50*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(70*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(70*D2R))
                .lineTo(ehsi.tickRadius*math.cos(70*D2R), ehsi.tickRadius*math.sin(70*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(80*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(80*D2R))
                .lineTo(ehsi.tickRadius*math.cos(80*D2R), ehsi.tickRadius*math.sin(80*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(100*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(100*D2R))
                .lineTo(ehsi.tickRadius*math.cos(100*D2R), ehsi.tickRadius*math.sin(100*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(110*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(110*D2R))
                .lineTo(ehsi.tickRadius*math.cos(110*D2R), ehsi.tickRadius*math.sin(110*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(130*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(130*D2R))
                .lineTo(ehsi.tickRadius*math.cos(130*D2R), ehsi.tickRadius*math.sin(130*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(140*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(140*D2R))
                .lineTo(ehsi.tickRadius*math.cos(140*D2R), ehsi.tickRadius*math.sin(140*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(160*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(160*D2R))
                .lineTo(ehsi.tickRadius*math.cos(160*D2R), ehsi.tickRadius*math.sin(160*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(170*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(170*D2R))
                .lineTo(ehsi.tickRadius*math.cos(170*D2R), ehsi.tickRadius*math.sin(170*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(190*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(190*D2R))
                .lineTo(ehsi.tickRadius*math.cos(190*D2R), ehsi.tickRadius*math.sin(190*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(200*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(200*D2R))
                .lineTo(ehsi.tickRadius*math.cos(200*D2R), ehsi.tickRadius*math.sin(200*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(220*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(220*D2R))
                .lineTo(ehsi.tickRadius*math.cos(220*D2R), ehsi.tickRadius*math.sin(220*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(230*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(230*D2R))
                .lineTo(ehsi.tickRadius*math.cos(230*D2R), ehsi.tickRadius*math.sin(230*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(250*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(250*D2R))
                .lineTo(ehsi.tickRadius*math.cos(250*D2R), ehsi.tickRadius*math.sin(250*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(260*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(260*D2R))
                .lineTo(ehsi.tickRadius*math.cos(260*D2R), ehsi.tickRadius*math.sin(260*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(280*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(280*D2R))
                .lineTo(ehsi.tickRadius*math.cos(280*D2R), ehsi.tickRadius*math.sin(280*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(290*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(290*D2R))
                .lineTo(ehsi.tickRadius*math.cos(290*D2R), ehsi.tickRadius*math.sin(290*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(310*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(310*D2R))
                .lineTo(ehsi.tickRadius*math.cos(310*D2R), ehsi.tickRadius*math.sin(310*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(320*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(320*D2R))
                .lineTo(ehsi.tickRadius*math.cos(320*D2R), ehsi.tickRadius*math.sin(320*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(340*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(340*D2R))
                .lineTo(ehsi.tickRadius*math.cos(340*D2R), ehsi.tickRadius*math.sin(340*D2R))
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(350*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(350*D2R))
                .lineTo(ehsi.tickRadius*math.cos(350*D2R), ehsi.tickRadius*math.sin(350*D2R))
                .setColor(colorW)
                .setStrokeLineWidth(1.5);
        ehsi.tick_longlines2 = ehsi.compassGroup.createChild("path")
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(0*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(0*D2R))
                .lineTo(ehsi.tickRadius*math.cos(0*D2R), ehsi.tickRadius*math.sin(0*D2R))
                
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(30*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(30*D2R))
                .lineTo(ehsi.tickRadius*math.cos(30*D2R), ehsi.tickRadius*math.sin(30*D2R))
                
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(60*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(60*D2R))
                .lineTo(ehsi.tickRadius*math.cos(60*D2R), ehsi.tickRadius*math.sin(60*D2R))
                
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(90*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(90*D2R))
                .lineTo(ehsi.tickRadius*math.cos(90*D2R), ehsi.tickRadius*math.sin(90*D2R))
                
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(120*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(120*D2R))
                .lineTo(ehsi.tickRadius*math.cos(120*D2R), ehsi.tickRadius*math.sin(120*D2R))
                
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(150*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(150*D2R))
                .lineTo(ehsi.tickRadius*math.cos(150*D2R), ehsi.tickRadius*math.sin(150*D2R))
                
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(180*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(180*D2R))
                .lineTo(ehsi.tickRadius*math.cos(180*D2R), ehsi.tickRadius*math.sin(180*D2R))
                
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(210*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(210*D2R))
                .lineTo(ehsi.tickRadius*math.cos(210*D2R), ehsi.tickRadius*math.sin(210*D2R))
                
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(240*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(240*D2R))
                .lineTo(ehsi.tickRadius*math.cos(240*D2R), ehsi.tickRadius*math.sin(240*D2R))
                
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(270*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(270*D2R))
                .lineTo(ehsi.tickRadius*math.cos(270*D2R), ehsi.tickRadius*math.sin(270*D2R))
                
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(300*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(300*D2R))
                .lineTo(ehsi.tickRadius*math.cos(300*D2R), ehsi.tickRadius*math.sin(300*D2R))
                
                .moveTo((ehsi.tickRadius-ehsi.tick_long)*math.cos(330*D2R), (ehsi.tickRadius-ehsi.tick_long)*math.sin(330*D2R))
                .lineTo(ehsi.tickRadius*math.cos(330*D2R), ehsi.tickRadius*math.sin(330*D2R))
                .setColor(colorW)
                .setStrokeLineWidth(1.5);
                
        ehsi.tick_outerlines = ehsi.rootCenter.createChild("path")
                .moveTo((ehsi.tickRadiusOuter-ehsi.tick_outer)*math.cos(0*D2R), (ehsi.tickRadiusOuter-ehsi.tick_outer)*math.sin(0*D2R))
                .lineTo(ehsi.tickRadiusOuter*math.cos(0*D2R), ehsi.tickRadiusOuter*math.sin(0*D2R))
                
                .moveTo((ehsi.tickRadiusOuter-ehsi.tick_outer)*math.cos(45*D2R), (ehsi.tickRadiusOuter-ehsi.tick_outer)*math.sin(45*D2R))
                .lineTo(ehsi.tickRadiusOuter*math.cos(45*D2R), ehsi.tickRadiusOuter*math.sin(45*D2R))
                
                .moveTo((ehsi.tickRadiusOuter-ehsi.tick_outer)*math.cos(90*D2R), (ehsi.tickRadiusOuter-ehsi.tick_outer)*math.sin(90*D2R))
                .lineTo(ehsi.tickRadiusOuter*math.cos(90*D2R), ehsi.tickRadiusOuter*math.sin(90*D2R))
                
                .moveTo((ehsi.tickRadiusOuter-ehsi.tick_outer)*math.cos(135*D2R), (ehsi.tickRadiusOuter-ehsi.tick_outer)*math.sin(135*D2R))
                .lineTo(ehsi.tickRadiusOuter*math.cos(135*D2R), ehsi.tickRadiusOuter*math.sin(135*D2R))
                
                .moveTo((ehsi.tickRadiusOuter-ehsi.tick_outer)*math.cos(180*D2R), (ehsi.tickRadiusOuter-ehsi.tick_outer)*math.sin(180*D2R))
                .lineTo(ehsi.tickRadiusOuter*math.cos(180*D2R), ehsi.tickRadiusOuter*math.sin(180*D2R))
                
                .moveTo((ehsi.tickRadiusOuter-ehsi.tick_outer)*math.cos(225*D2R), (ehsi.tickRadiusOuter-ehsi.tick_outer)*math.sin(225*D2R))
                .lineTo(ehsi.tickRadiusOuter*math.cos(225*D2R), ehsi.tickRadiusOuter*math.sin(225*D2R))
                
                .moveTo((ehsi.tickRadiusOuter-ehsi.tick_outer)*math.cos(270*D2R), (ehsi.tickRadiusOuter-ehsi.tick_outer)*math.sin(270*D2R))
                .lineTo(ehsi.tickRadiusOuter*math.cos(270*D2R), ehsi.tickRadiusOuter*math.sin(270*D2R))
                
                .moveTo((ehsi.tickRadiusOuter-ehsi.tick_outer)*math.cos(315*D2R), (ehsi.tickRadiusOuter-ehsi.tick_outer)*math.sin(315*D2R))
                .lineTo(ehsi.tickRadiusOuter*math.cos(315*D2R), ehsi.tickRadiusOuter*math.sin(315*D2R))
                .setColor(colorW)
                .setStrokeLineWidth(3);
        
        ehsi.ilsDevOld = 0;
        ehsi.ilsOld = 0;
        ehsi.modeOld = -1;
        ehsi.modeTime = 0;
        return ehsi;
    },
    update: func () {
        me.headingMag = getprop("orientation/heading-magnetic-deg");
        me.heading    = getprop("orientation/heading-deg");
        me.mode       = getprop("sim/model/f16/controls/navigation/instrument-mode-panel/mode/rotary-switch-knob");
        me.elec       = getprop("fdm/jsbsim/elec/bus/emergency-ac-2")>100;
        me.tacanInRange = getprop("instrumentation/tacan/in-range");
        me.tacanBearingRel = getprop("instrumentation/tacan/bearing-relative-deg");
        me.tacanBearingTrue = getprop("instrumentation/tacan/indicated-bearing-true-deg");
        me.navInRange   = getprop("autopilot/route-manager/current-wp") != -1;
        me.navBearingTrue = getprop("autopilot/route-manager/wp/bearing-deg");
        me.vorInRange  = getprop("instrumentation/nav[0]/in-range") and !getprop("instrumentation/nav[0]/nav-loc");
        me.vorBearingTrue = getprop("instrumentation/nav[0]/heading-deg");
        me.vorCDI = getprop("instrumentation/nav[0]/heading-needle-deflection-norm");
        me.vorTo = getprop("instrumentation/nav[0]/to-flag");
        me.vorFrom = getprop("instrumentation/nav[0]/from-flag");
        me.captHeading = getprop("instrumentation/heading-indicator-fg/offset-deg");
        me.dist = getprop("f16/avionics/hsi-dist");
        me.ilsDev      = getprop("instrumentation/nav[0]/heading-needle-deflection-norm");
        me.ilsInRange  = getprop("instrumentation/nav[0]/in-range");
        me.crsILS = getprop("f16/crs-ils");
        me.crsNonILS = getprop("f16/crs-non-ils");
        me.adfBearingRel = getprop("instrumentation/adf/indicated-bearing-deg");
        me.adfInRange = getprop("instrumentation/adf/in-range");
        
        
        me.ils        = me.mode == 0 or me.mode == 3 or me.mode == 5;
        me.tacan      = me.mode == 0 or me.mode == 1;
        me.nav        = me.mode == 2 or me.mode == 3;
        me.vor        = me.mode == 4 or me.mode == 5;
        
        if (!me.elec) {
            settimer(func me.update(),0.2);
            return;
        }
        
        if (me.mode != me.modeOld) {
            me.modeTime = systime();
        }
        
        if (me.ilsOld != me.ils and me.ils) {
            setprop("instrumentation/nav[0]/radials/selected-deg", me.crsILS);
        } elsif (me.ilsOld != me.ils and !me.ils) {
            setprop("instrumentation/nav[0]/radials/selected-deg", me.crsNonILS);
        }
        me.selectCRS = getprop("instrumentation/nav[0]/radials/selected-deg");
        
        # Text
        me.textModeLeft  = me.ils?"PLS":"";
        me.textModeRight = me.tacan?"TCN":(me.vor?"VOR":"NAV");
        
        if (systime()-me.modeTime > 1) {
            me.txtNote.hide();
        } else {
            if (me.mode==0) me.textModeNote = "PLS/TACAN";
            elsif (me.mode==1) me.textModeNote = "TACAN";
            elsif (me.mode==2) me.textModeNote = "NAV";
            elsif (me.mode==3) me.textModeNote = "PLS/NAV";
            elsif (me.mode==4) me.textModeNote = "VOR";
            elsif (me.mode==5) me.textModeNote = "PLS/VOR";
            me.txtNote.setText(me.textModeNote);
            me.txtNote.show();
        }
        
        me.textCRS       = sprintf("%03d",me.selectCRS);
        
        if (me.dist != nil and me.dist != -1) {
            me.textDist      = sprintf("%03d",me.dist);
            me.textDistMinor = sprintf("%1d",(me.dist-int(me.dist))*10);
                
            me.txtDist.setText(me.textDist);
            me.txtDistMinor.setText(me.textDistMinor);
            me.distCover.hide();
        } else {
            me.txtDist.setText("000");
            me.txtDistMinor.setText("0");
            me.distCover.show();
        }
        
        me.txtCRS.setText(me.textCRS);
        me.txtModeL.setText(me.textModeLeft);
        me.txtModeR.setText(me.textModeRight);
        
        #Bearing and TO-FROM
        if (me.tacan and me.tacanInRange) {
            me.arrowOuterGroup.setRotation(me.tacanBearingRel*D2R);
            me.tacanRadial = me.tacanBearingRel+me.headingMag+180;#the radial I am on
            me.tacanDiff   = geo.normdeg180(me.selectCRS-me.tacanRadial);
            me.tacanDiffAbs= math.abs(me.tacanDiff);
            if (me.tacanDiffAbs <= 90) {
                # we are close to selected CRS radial, so we are FROM
                me.to.setVisible(0);
                me.from.setVisible(!me.ils);
            } else {
                # we are far from selected CRS radial, so we are TO
                me.to.setVisible(!me.ils);
                me.from.setVisible(0);
            }
            me.arrowOuterGroup.show();
        } elsif (me.nav and me.navInRange) {
            me.navBearingRel = geo.normdeg180(me.navBearingTrue-me.heading);
            me.navRadial = me.navBearingRel+me.headingMag+180;
            me.navDiff   = geo.normdeg180(me.selectCRS-me.navRadial);
            me.navDiffAbs= math.abs(me.navDiff);
            
            me.arrowOuterGroup.setRotation(me.navBearingRel*D2R);
            me.to.setVisible(0);
            me.from.setVisible(0);
            me.arrowOuterGroup.show();
        } elsif (me.vor and me.vorInRange) {
            me.vorBearingRel = geo.normdeg180(me.vorBearingTrue-me.heading);            
            me.arrowOuterGroup.setRotation(me.vorBearingRel*D2R);
            me.to.setVisible(me.vorTo);
            me.from.setVisible(me.vorFrom);
            me.arrowOuterGroup.show();
        } elsif (me.vor and me.adfInRange) {
            me.arrowOuterGroup.setRotation(me.adfBearingRel*D2R);# TODO: Am I sure this is relative bearing??
            me.to.setVisible(0);
            me.from.setVisible(0);
            me.arrowOuterGroup.show();
        } else {
            me.arrowOuterGroup.hide();
            me.to.setVisible(0);
            me.from.setVisible(0);
        }
        
        # CDI
        if (me.ilsDev == nil) {
            me.ilsDev = me.ilsDevOld;
        }
        if (me.ils and me.ilsInRange) {
            me.arrowInnerSolid.setTranslation(me.cdiMaxMovement*me.ilsDev,0);
            me.arrowInnerSegment.setTranslation(me.cdiMaxMovement*me.ilsDev,0);
            me.arrowInnerSolid.show();
            me.arrowInnerSegment.hide();
            me.cdiInvalid.hide();
        } elsif (me.tacan and me.tacanInRange and !me.ils) {
            if (me.tacanDiffAbs > 90) {
                me.dev = -math.min(10,math.max(-10, geo.normdeg180(me.tacanDiff+180)))*0.1;# 10 degs is full CDI
            } else {
                me.dev = math.min(10,math.max(-10, geo.normdeg180(me.tacanDiff)))*0.1;
            }
            me.arrowInnerSolid.setTranslation(me.cdiMaxMovement*me.dev,0);
            me.arrowInnerSegment.setTranslation(me.cdiMaxMovement*me.dev,0);
            me.arrowInnerSolid.show();
            me.arrowInnerSegment.hide();
            me.cdiInvalid.hide();
        } elsif (me.nav and me.navInRange and !me.ils) {
            if (me.navDiffAbs > 90) {
                me.dev = -math.min(10,math.max(-10, geo.normdeg180(me.navDiff+180)))*0.1;# 10 degs is full CDI
            } else {
                me.dev = math.min(10,math.max(-10, geo.normdeg180(me.navDiff)))*0.1;
            }
            me.arrowInnerSolid.setTranslation(me.cdiMaxMovement*me.dev,0);
            me.arrowInnerSegment.setTranslation(me.cdiMaxMovement*me.dev,0);
            me.arrowInnerSolid.show();
            me.arrowInnerSegment.hide();
            me.cdiInvalid.hide();
        } elsif (me.vor and me.vorInRange and !me.ils and !me.adfInRange) {
            me.arrowInnerSolid.setTranslation(me.cdiMaxMovement*me.vorCDI,0);
            me.arrowInnerSegment.setTranslation(me.cdiMaxMovement*me.vorCDI,0);
            me.arrowInnerSolid.show();
            me.arrowInnerSegment.hide();
            me.cdiInvalid.hide();
        } else {
            me.arrowInnerSolid.hide();
            me.arrowInnerSegment.show();
            me.cdiInvalid.show();
        }
        
        # heading
        me.compassMainGroup.setRotation(-me.headingMag*D2R);
        # CRS arrow
        me.arrowGroup.setRotation(me.selectCRS*D2R);
        # Capt bars
        me.captBars.setRotation(me.captHeading*D2R);                
        
        # store selected CRS
        if (me.ils) {
            setprop("f16/crs-ils", me.selectCRS);
        } else {
            setprop("f16/crs-non-ils", me.selectCRS);
        }
                
        me.ilsDevOld = me.ilsDev;
        me.ilsOld    = me.ils;
        me.modeOld = me.mode;
        settimer(func me.update(),0.2);
    },
};

#TODO:
# confirm correctness
# VOR only in export variants of F-16?
# BRT can be set by CRS knob (hold in for 2 secs), inactivity for 2 secs reverts to CRS

var diam = 512;
var cv = canvas.new({
                     "name": "F16 EHSI",
                     "size": [diam,diam], 
                     "view": [diam,diam],
                     "mipmapping": 1
                    });

cv.addPlacement({"node": "EHSI-Display", "texture":"ehsi-display.png"});
cv.setColorBackground(0, 0, 0);
var root = cv.createGroup();
var ehsi = nil;
var init = func {
    var variant = getprop("sim/variant-id");
    if (variant != 0 and variant != 1 and variant != 3) {
        ehsi = EHSI.new("EHSI", root, [diam/2,diam/2],diam);
        ehsi.update();
    } else {
        props.globals.getNode("f16/crs-ils").alias(props.globals.getNode("instrumentation/nav[0]/radials/selected-deg"));    
    }
}