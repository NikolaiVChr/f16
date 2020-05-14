# original Author: pinto
# Modified by: Nikolai V. Chr.

var load_knee = func(path) {
    path = path.getValue();
    if (io.stat(path) == nil){
        return;
    }
    var mode = -1;
    var index = 0;
    var vi = io.open(path,'r');
    var data = split("\n",string.replace(io.readfile(path),"\r",""));

    # clear out old settings

    for (var i = 0; i < 20; i = i + 1) {
        setprop("/instrumentation/vor-knee/preset["~i~"]",0);
        setprop("/instrumentation/vor-knee/ident["~i~"]","");
        setprop("/instrumentation/adf-knee/preset["~i~"]",0);
        setprop("/instrumentation/adf-knee/ident["~i~"]","");
        setprop("/instrumentation/comm-knee/preset["~i~"]",0);
        setprop("/instrumentation/comm-knee/ident["~i~"]","");
        setprop("/instrumentation/ils-knee/preset["~i~"]",0);
        setprop("/instrumentation/ils-knee/ident["~i~"]","");
    }

    foreach (var datum; data){
        if (left(datum,1) == "#") { continue; }
        if (datum == "nav") { 
            mode = 0;
            index = 0;
            continue;
        } elsif (datum == "adf") { 
            mode = 1;
            index = 0;
            continue;
        } elsif (datum == "comm") { 
            mode = 2;
            index = 0;
            continue;
        } elsif (datum == "ils") {
            mode = 3;
            index = 0;
            continue;
        }
        if (datum == "") { continue; }
        if (mode == -1) { continue; }
        if ( ((mode == 0 or mode == 2 or mode == 3) and index > 19) or (mode == 1 and index > 8) ) {continue;}

        var ident = "";
        if ( size(split(" ",datum)) > 1 ) {
            ident = split(" ",datum)[1];
            datum = split(" ",datum)[0];
        }

        if (mode == 0) {
            setprop("/instrumentation/vor-knee/preset["~index~"]",datum);
            setprop("/instrumentation/vor-knee/ident["~index~"]",ident);
        } elsif (mode == 1) {
            setprop("/instrumentation/adf-knee/preset["~index~"]",datum);
            setprop("/instrumentation/adf-knee/ident["~index~"]",ident);
        } elsif (mode == 2) {
            setprop("/instrumentation/comm-knee/preset["~index~"]",datum);
            setprop("/instrumentation/comm-knee/ident["~index~"]",ident);
        } elsif (mode == 3) {
            setprop("/instrumentation/ils-knee/preset["~index~"]",datum);
            setprop("/instrumentation/ils-knee/ident["~index~"]",ident);
        }
        index = index + 1;

    }
    knee_canvas.rp.update_text();
    knee.update_nav_knee();
    #debug.dump(data);
}

var get_knee_file_gui = func() {
    var file_selector = gui.FileSelector.new(dir: getprop("/sim/fg-home"), callback: load_knee, title: "Select Kneeboard Config File", button: "Load");
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
        m.paper.addPlacement({"node": "boardLeft", "texture": "leftknee.png"});

        m.paper.setColorBackground(1,1,1,1);

        m.fs = 65;
        m.dR = 0.1;
        m.dG = 0.1;
        m.dB = 0.1;

        m.start_x = 225;
        m.start_y = 150;
        m.x_delta = 230;
        m.y_delta = 93;

        m.notes = m.paper.createGroup();

        for (var i = 0; i < 20; i = i + 1) {
            m.notes.createChild("text")
                .setTranslation(65,m.start_y + (i * m.y_delta))
                .setAlignment("center-top")
                .setFont("helvetica_bold.txf")
                .setFontSize(m.fs)
                .setColor(m.dR,m.dG,m.dB)
                .setText(i+1);
        }

        m.vor_text = [];
        m.ils_text = [];
        m.comm_text = [];
        m.adf_text = [];

        for (var i = 0; i < 20; i = i + 1) {
            append(m.vor_text, m.notes.createChild("text")
                            .setTranslation(225,m.start_y + (i * m.y_delta))
                            .setAlignment("center-top")
                            .setFont("helvetica_bold.txf")
                            .setFontSize(m.fs)
                            .setColor(m.dR,m.dG,m.dB));
            append(m.ils_text, m.notes.createChild("text")
                            .setTranslation(225 + 230,m.start_y + (i * m.y_delta))
                            .setAlignment("center-top")
                            .setFont("helvetica_bold.txf")
                            .setFontSize(m.fs)
                            .setColor(m.dR,m.dG,m.dB));
            append(m.comm_text, m.notes.createChild("text")
                            .setTranslation(225 + 230 + 230,m.start_y + (i * m.y_delta))
                            .setAlignment("center-top")
                            .setFont("helvetica_bold.txf")
                            .setFontSize(m.fs)
                            .setColor(m.dR,m.dG,m.dB));
            if ( i > 8 )  { continue; }
            append(m.adf_text, m.notes.createChild("text")
                            .setTranslation(225 + 230 + 230 + 230,m.start_y + (i * m.y_delta))
                            .setAlignment("center-top")
                            .setFont("helvetica_bold.txf")
                            .setFontSize(m.fs)
                            .setColor(m.dR,m.dG,m.dB));
        }

        return m;
    },

    update_text: func() {

        for ( var i = 0; i < 20; i = i + 1 ) {
            me.vor_text[i].setText(getprop("/instrumentation/vor-knee/ident["~i~"]"));
            me.ils_text[i].setText(getprop("/instrumentation/ils-knee/ident["~i~"]"));
            me.comm_text[i].setText(getprop("/instrumentation/comm-knee/ident["~i~"]"));
            if ( i > 8 )  { continue; }
            me.adf_text[i].setText(getprop("/instrumentation/adf-knee/ident["~i~"]"));
        }
            #<path>/instrumentation/comm-knee/ident[15]</path>
            #<path>/instrumentation/adf-knee/ident[4]</path>
            #<path>/instrumentation/ils-knee/ident[11]</path>
            #<path>/instrumentation/vor-knee/ident[15]</path>
    }
};



var rp = 0;

var init = setlistener("/sim/signals/fdm-initialized", func() {
  removelistener(init); # only call once
  rp = knee_paper.new({"node": "paper_canvas"});
});