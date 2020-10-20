
gui.showHelpDialog = func(path, toggle=0) {
    var node = props.globals.getNode(path);
    if (path == "/sim/help" and size(node.getChildren()) < 4) {
        node = node.getChild("common");
    }

    var name = node.getNode("title", 1).getValue();
    if (name == nil) {
        name = getprop("/sim/description");
        if (name == nil) {
            name = getprop("/sim/aircraft");
        }
    }
    var toggle = toggle > 0;
    var dialog = gui.dialog;
    if (toggle and contains(dialog, name)) {
        fgcommand("dialog-close", props.Node.new({ "dialog-name": name }));
        delete(dialog, name);
        return;
    }

    dialog[name] = gui.Widget.new();
    dialog[name].set("layout", "vbox");
    dialog[name].set("default-padding", 0);
    dialog[name].set("name", name);

    # title bar
    var titlebar = dialog[name].addChild("group");
    titlebar.set("layout", "hbox");
    titlebar.addChild("empty").set("stretch", 1);
    titlebar.addChild("text").set("label", name);
    titlebar.addChild("empty").set("stretch", 1);

    var w = titlebar.addChild("button");
    w.set("pref-width", 16);
    w.set("pref-height", 16);
    w.set("legend", "");
    w.set("default", 1);
    w.set("key", "esc");
    w.setBinding("nasal", "delete(gui.dialog, \"" ~ name ~ "\")");
    w.setBinding("dialog-close");

    dialog[name].addChild("hrule");

    # key list
    var keylist = dialog[name].addChild("group");
    keylist.set("layout", "table");
    keylist.set("default-padding", 2);
    var keydefs = node.getChildren("key");
    var n = size(keydefs);
    var row = var col = 0;
    foreach (var key; keydefs) {
        if (n >= 60 and row >= n / 3 or n >= 16 and row >= n / 2) {
            col += 1;
            row = 0;
        }

        var w = keylist.addChild("text");
        w.set("row", row);
        w.set("col", 2 * col);
        w.set("halign", "right");
        w.set("label", " " ~ key.getNode("name").getValue());

        w = keylist.addChild("text");
        w.set("row", row);
        w.set("col", 2 * col + 1);
        w.set("halign", "left");
        w.set("label", "... " ~ key.getNode("desc").getValue() ~ "  ");
        row += 1;
    }

    # separate lines
    var lines = node.getChildren("line");
    if (size(lines)) {
        if (size(keydefs)) {
            dialog[name].addChild("empty").set("pref-height", 4);
            dialog[name].addChild("hrule");
            dialog[name].addChild("empty").set("pref-height", 4);
        }

        var g = dialog[name].addChild("group");
        g.set("layout", "vbox");
        g.set("default-padding", 1);
        foreach (var lin; lines) {
            foreach (var l; split("\n", lin.getValue())) {
                var w = g.addChild("text");
                w.set("halign", "left");
                w.set("label", " " ~ l ~ " ");
            }
        }
    }
    if (path=="/sim/help") {
        # subject buttons
        dialog[name].addChild("hrule");
        var tabbar = dialog[name].addChild("group");
        tabbar.set("layout", "hbox");
        tabbar.set("default-padding", 3);
        tabbar.addChild("empty").set("stretch", 1);

        var w1 = tabbar.addChild("button");
        w1.set("pref-width", 64);
        w1.set("pref-height", 16);
        w1.set("legend", "Flying");
        w1.set("default", 1);
        w1.set("key", "esc");
        #"delete(gui.dialog, \"" ~ name ~ "\")"
        w1.setBinding("nasal", "setprop('sim/help/text', getprop('sim/help/text-1'))");
        #tabbar.addChild("empty").set("stretch", 1);

        var w2 = tabbar.addChild("button");
        w2.set("pref-width", 64);
        w2.set("pref-height", 16);
        w2.set("legend", "HUD");
        w2.set("default", 1);
        w2.set("key", "esc");
        w2.setBinding("nasal", "setprop('sim/help/text', getprop('sim/help/text-2'))");
        #tabbar.addChild("empty").set("stretch", 1);

        var w3 = tabbar.addChild("button");
        w3.set("pref-width", 64);
        w3.set("pref-height", 16);
        w3.set("legend", "RWR");
        w3.set("default", 1);
        w3.set("key", "esc");
        w3.setBinding("nasal", "setprop('sim/help/text', getprop('sim/help/text-3'))");
        #tabbar.addChild("empty").set("stretch", 1);
        
        var w4 = tabbar.addChild("button");
        w4.set("pref-width", 64);
        w4.set("pref-height", 16);
        w4.set("legend", "Displays");
        w4.set("default", 1);
        w4.set("key", "esc");
        w4.setBinding("nasal", "setprop('sim/help/text', getprop('sim/help/text-4'))");
        #tabbar.addChild("empty").set("stretch", 1);
        
        var w5 = tabbar.addChild("button");
        w5.set("pref-width", 64);
        w5.set("pref-height", 16);
        w5.set("legend", "A/P");
        w5.set("default", 1);
        w5.set("key", "esc");
        w5.setBinding("nasal", "setprop('sim/help/text', getprop('sim/help/text-5'))");
        #tabbar.addChild("empty").set("stretch", 1);
        
        var w6 = tabbar.addChild("button");
        w6.set("pref-width", 64);
        w6.set("pref-height", 16);
        w6.set("legend", "WEAP");
        w6.set("default", 1);
        w6.set("key", "esc");
        w6.setBinding("nasal", "setprop('sim/help/text', getprop('sim/help/text-6'))");
        #tabbar.addChild("empty").set("stretch", 1);
        
        var w7 = tabbar.addChild("button");
        w7.set("pref-width", 64);
        w7.set("pref-height", 16);
        w7.set("legend", "Controls");
        w7.set("default", 1);
        w7.set("key", "esc");
        w7.setBinding("nasal", "setprop('sim/help/text', getprop('sim/help/text-7'))");
        #tabbar.addChild("empty").set("stretch", 1);
        
        var w8 = tabbar.addChild("button");
        w8.set("pref-width", 64);
        w8.set("pref-height", 16);
        w8.set("legend", "Scenario");
        w8.set("default", 1);
        w8.set("key", "esc");
        w8.setBinding("nasal", "setprop('sim/help/text', getprop('sim/help/text-8'))");
        #tabbar.addChild("empty").set("stretch", 1);
        
        var w9 = tabbar.addChild("button");
        w9.set("pref-width", 64);
        w9.set("pref-height", 16);
        w9.set("legend", "DED");
        w9.set("default", 1);
        w9.set("key", "esc");
        w9.setBinding("nasal", "setprop('sim/help/text', getprop('sim/help/text-9'))");
        #tabbar.addChild("empty").set("stretch", 1);
        
        var w10 = tabbar.addChild("button");
        w10.set("pref-width", 64);
        w10.set("pref-height", 16);
        w10.set("legend", "Dogfight");
        w10.set("default", 1);
        w10.set("key", "esc");
        w10.setBinding("nasal", "setprop('sim/help/text', getprop('sim/help/text-10'))");
        #tabbar.addChild("empty").set("stretch", 1);
        
        var w11 = tabbar.addChild("button");
        w11.set("pref-width", 64);
        w11.set("pref-height", 16);
        w11.set("legend", "Failures");
        w11.set("default", 1);
        w11.set("key", "esc");
        w11.setBinding("nasal", "setprop('sim/help/text', getprop('sim/help/text-11'))");
        #tabbar.addChild("empty").set("stretch", 1);
      
        var w12 = tabbar.addChild("button");
        w12.set("pref-width", 64);
        w12.set("pref-height", 16);
        w12.set("legend", "Variants");
        w12.set("default", 1);
        w12.set("key", "esc");
        w12.setBinding("nasal", "setprop('sim/help/text', getprop('sim/help/text-12'))");
        tabbar.addChild("empty").set("stretch", 1);
    }
 
    # scrollable text area
    if (node.getNode("text") != nil) {
        dialog[name].set("resizable", 1);
        dialog[name].addChild("empty").set("pref-height", 10);

        var width = [640, 800, 1152][col];
        var height = gui.screenHProp.getValue() - (100 + (size(keydefs) / (col + 1) + size(lines)) * 28);
        if (height < 200) {
            height = 200;
        }

        var w = dialog[name].addChild("textbox");
        w.set("padding", 4);
        w.set("halign", "fill");
        w.set("valign", "fill");
        w.set("stretch", "true");
        w.set("slider", 20);
        w.set("pref-width", width);
        w.set("pref-height", height);
        w.set("editable", 0);
        w.set("live", 1);
        w.set("property", node.getPath() ~ "/text");
        w.setFont("FIXED_8x13");
    } else {
        dialog[name].addChild("empty").set("pref-height", 8);
    }

    fgcommand("dialog-new", dialog[name].prop());
    gui.showDialog(name);
}
