# original Author: pinto
# Modified by: Nikolai V. Chr.

var load_knee_l = func(path) {
    path = path.getValue();
    if (io.stat(path) == nil){
        return;
    }
    var vi = io.open(path,'r');
    var data = split("\n",string.replace(io.readfile(path),"\r",""));
    
    
    leftK.update_text(path,data);
    
    if (file_selector_l != nil) {
        #file_selector_l.close();
    }
}

var load_knee_r = func(path) {
    path = path.getValue();
    if (io.stat(path) == nil){
        return;
    }
    var vi = io.open(path,'r');
    var data = split("\n",string.replace(io.readfile(path),"\r",""));

    
    rightK.update_text(path,data);
    
    if (file_selector_r != nil) {
        #file_selector_r.close();
    }
}

var file_selector_r = nil;
var file_selector_l = nil;

var get_knee_file_gui_l = func() {
    if (file_selector_l == nil) {
        file_selector_l = gui.FileSelector.new(dir: getprop("/sim/fg-home") ~ "/Export", callback: load_knee_l, title: "Select Left Kneeboard Config File", button: "Load", pattern: ["*.knee"]);
    }
    file_selector_l.open();
}

var get_knee_file_gui_r = func() {
    if (file_selector_r == nil) {
        file_selector_r = gui.FileSelector.new(dir: getprop("/sim/fg-home") ~ "/Export", callback: load_knee_r, title: "Select Right Kneeboard Config File", button: "Load", pattern: ["*.knee"]);
    }
    file_selector_r.open();
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

    update_text: func(path, data) {
        # 0.0847m x 0.2286m
        # 3" 1/3 x 9"
        me.notes.removeAllChildren();
        
        me.fs = 40;
        me.color = [0.1,0.1,0.1];

        me.start_x = 150;
        me.start_y = 175;
        me.curr_x = me.start_x;
        me.curr_y = me.start_y;
        me.x_line = 1280-me.curr_x*2;
        me.y_line = 2048-me.curr_y*2;
        me.y_delta = 45;
        me.x_margin = 15;
        me.center_margin = me.x_line*0.5;
        
        foreach (var datum; data) {
            if (left(datum,1) == "#") { continue; }
            me.curr_y += me.y_delta;
            me.font = "Helvetica.txf";
            if (left(datum,1) == "+") {    
                me.font = "helvetica_bold.txf";
                datum = right(datum,size(datum)-1);
            }
            if (datum == "-") { 
                me.notes.createChild("path")
                    .moveTo(me.curr_x,me.curr_y)
                    .horiz(me.x_line)
                    .setColor(me.color)
                    .set("z-index",10)
                    .setStrokeLineWidth(1);
                continue;
            } elsif (datum == "=") { 
                me.notes.createChild("path")
                    .moveTo(me.curr_x,me.curr_y)
                    .horiz(me.x_line)
                    .setColor(me.color)
                    .set("z-index",10)
                    .setStrokeLineWidth(3);
                continue;
            } elsif (datum == "*") { 
                me.notes.createChild("path")
                    .moveTo(me.start_x,me.start_y)
                    .vert(me.y_line)
                    .horiz(me.x_line)
                    .vert(-me.y_line)
                    .horiz(-me.x_line)
                    .setColor(me.color)
                    .set("z-index",10)
                    .setStrokeLineWidth(3);
                me.curr_y -= me.y_delta;
                continue;
            } elsif (datum == "") {
                continue;
            } elsif (left(datum,1) == "!") {
                var p = split("/",path);
                p[size(p)-1] = "";
                var img = "";
                foreach(var pp;p) {
                    img = img ~ pp ~"/";
                }
                #print(img~right(datum,size(datum)-1));
                me.notes.createChild("image")
                    .set("src", img~right(datum,size(datum)-1))
                    .set("z-index",1);
                me.curr_y -= me.y_delta;
                continue;
            } elsif (find("|",datum) != -1) {
                me.notes.createChild("path")
                    .moveTo(me.curr_x+me.center_margin,me.curr_y-me.y_delta)
                    .vert(me.y_delta*2)
                    .setColor(me.color)
                    .set("z-index",10)
                    .setStrokeLineWidth(1);
                me.notes.createChild("text")
                    .setTranslation(me.curr_x+me.x_margin+me.center_margin,me.curr_y)
                    .setAlignment("left-center")
                    .setFont(me.font)
                    .setFontSize(me.fs)
                    .setText(right(datum,size(datum)-find("|",datum)-1))
                    .set("z-index",10)
                    .setColor(me.color);
                datum = left(datum,find("|",datum));
            }
            me.notes.createChild("text")
                .setTranslation(me.curr_x+me.x_margin,me.curr_y)
                .setAlignment("left-center")
                .setFont(me.font)
                .setFontSize(me.fs)
                .setText(datum)
                .set("z-index",10)
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