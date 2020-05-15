# original Author: pinto
# Modified by: Nikolai V. Chr.

var load_knee_l = func(path) {
    path = path.getValue();
    if (io.stat(path) == nil){
        return;
    }
    var vi = io.open(path,'r');
    var data = split("\n",string.replace(io.readfile(path),"\r",""));
    
    
    leftK.update_text(data);
}

var load_knee_r = func(path) {
    path = path.getValue();
    if (io.stat(path) == nil){
        return;
    }
    var vi = io.open(path,'r');
    var data = split("\n",string.replace(io.readfile(path),"\r",""));

    
    rightK.update_text(data);
}

var get_knee_file_gui_l = func() {
    var file_selector = gui.FileSelector.new(dir: getprop("/sim/fg-home"), callback: load_knee_l, title: "Select Left Kneeboard Config File", button: "Load");
    file_selector.open();
    file_selector.close();
}

var get_knee_file_gui_r = func() {
    var file_selector = gui.FileSelector.new(dir: getprop("/sim/fg-home"), callback: load_knee_r, title: "Select Right Kneeboard Config File", button: "Load");
    file_selector.open();
    file_selector.close();
}

var knee_paper = {

    canvas_settings: {
        "name": "kneepaper",
        "size": [2048, 2048],
        "view": [2048, 2048],
        "mipmapping": 1
    },
    
    new: func(placement) {
        var m = {parents: [knee_paper]};
        m.paper = canvas.new(knee_paper.canvas_settings);
        m.paper.addPlacement(placement);

        m.paper.setColorBackground(1,1,1,1);

        

        m.notes = m.paper.createGroup();


        return m;
    },

    update_text: func(data) {
        me.notes.removeAllChildren();
        
        me.fs = 40;
        me.color = [0.1,0.1,0.1];

        me.curr_x = 225;
        me.curr_y = 225;
        me.x_line = 1480-me.curr_x*2;
        me.y_line = 2048-me.curr_y*2;
        me.y_delta = 45;
        me.x_margin = 15;
        me.center_margin = me.x_line*0.5;
        
        me.notes.createChild("path")
                    .moveTo(me.curr_x,me.curr_y)
                    .vert(me.y_line)
                    .horiz(me.x_line)
                    .vert(-me.y_line)
                    .horiz(-me.x_line)
                    .setColor(me.color)
                    .setStrokeLineWidth(3);
        foreach (var datum; data) {
            if (left(datum,1) == "#") { continue; }
            me.curr_y += me.y_delta;
            if (datum == "-") { 
                me.notes.createChild("path")
                    .moveTo(me.curr_x,me.curr_y)
                    .horiz(me.x_line)
                    .setColor(me.color)
                    .setStrokeLineWidth(1);
                continue;
            } elsif (datum == "=") { 
                me.notes.createChild("path")
                    .moveTo(me.curr_x,me.curr_y)
                    .horiz(me.x_line)
                    .setColor(me.color)
                    .setStrokeLineWidth(3);
                continue;
            } elsif (datum == "") {
                continue;
            } elsif (find("|",datum) != -1) {
                me.notes.createChild("path")
                    .moveTo(me.curr_x+me.center_margin,me.curr_y-me.y_delta)
                    .vert(me.y_delta*2)
                    .setColor(me.color)
                    .setStrokeLineWidth(1);
                me.notes.createChild("text")
                    .setTranslation(me.curr_x+me.x_margin+me.center_margin,me.curr_y)
                    .setAlignment("left-center")
                    .setFont("helvetica_bold.txf")
                    .setFontSize(me.fs)
                    .setText(right(datum,size(datum)-find("|",datum)))
                    .setColor(me.color);
                datum = left(datum,find("|",datum));
            }
            me.notes.createChild("text")
                .setTranslation(me.curr_x+me.x_margin,me.curr_y)
                .setAlignment("left-center")
                .setFont("helvetica_bold.txf")
                .setFontSize(me.fs)
                .setText(datum)
                .setColor(me.color);
        }
    }
};



var leftK = nil;
var rightK = nil;

var init = setlistener("/sim/signals/fdm-initialized", func() {
  removelistener(init); # only call once
  leftK = knee_paper.new({"node": "paper", "texture": "kneeboard.png"});
  rightK = knee_paper.new({"node": "paper-r", "texture": "kneeboard.png"});
});