var dialog = nil;
var sized = [512, 512];
var position = [100, 100];


##############################
#####  Setup Viper style BEGIN
##############################

var gui_dir = getprop("/sim/fg-root") ~ "/Nasal/canvas/";
var loadGUIFile = func(file) io.load_nasal(gui_dir ~ file, "viper");

loadGUIFile("gui/Style.nas");
loadGUIFile("gui/styles/DefaultStyle.nas");
#loadGUIFile("gui.nas");

OurStyle = {
  new: func(name, name_icon_theme)
  {
    var root_node = props.globals.getNode("/sim/gui/canvas", 1)
                                 .addChild("style");
    var gui_path = getprop("/sim/aircraft-dir") ~ "/gui";
    var style_path = gui_path ~ "/styles/" ~ name;

    var icn_path = getprop("/sim/fg-root") ~ "/gui/styles/AmbianceClassic";

    var m = {
      parents: [OurStyle],
      _path: style_path,
      _dir_icons: getprop("/sim/fg-root") ~ "/gui/icons/" ~ name_icon_theme,
      _node: io.read_properties(style_path ~ "/style.xml", root_node),
      _colors: {}
    };

    # parse theme colors
    var comp_names = ["red", "green", "blue", "alpha"];
    var colors = m._node.getChild("colors");
    if( colors != nil )
    {
      foreach(var color; colors.getChildren())
      {
        var str = "rgba(";
        for(var i = 0; i < size(comp_names); i += 1)
        {
          if( i > 0 )
            str ~= ",";
          var val = color.getValue(comp_names[i]);
          if( val == nil )
            val = 1;
          if( i < 3 )
            str ~= int(val * 255 + 0.5);
          else
            str ~= int(val * 100) / 100;
        }
        m._colors[ color.getName() ] = str ~ ")";
      }
    }

    m._dir_decoration =
      icn_path ~ "/" ~ (m._node.getValue("folders/decoration") or "decoration");
    m._dir_widgets =
      icn_path ~ "/" ~ (m._node.getValue("folders/widgets") or "widgets");



    return m;
  },
  getColor: func(name, def = "#00ffff")
  {
    return me._colors[name] or def;
  }
};
viper.DefaultStyle.widgets["scroll-area"].new = func(parent, cfg)
  {
    me._root = parent.createChild("group", "scroll-area");

    me._bg     = me._root.createChild("path", "background")
                         .set("fill", "#e0e0e0");
    me.content = me._root.createChild("group", "scroll-content")
                         .set("clip-frame", canvas.Element.PARENT);
    me.vert  = me._newScroll(me._root, "vert");
    me.horiz = me._newScroll(me._root, "horiz");
};
viper.DefaultStyle.new = func(name, name_icon_theme)
  {
    return {
      parents: [ OurStyle.new(name, name_icon_theme),
                 viper.DefaultStyle ]
    };
};

var viperStyle = viper.DefaultStyle.new("ViperModern", "Humanity");

#viper.style = viperStyle;# Sets the viper style on the window itself

##############################
#####  Setup Viper style END
##############################


var diag = {
	init: func (dir) {
		var sortprop = nil;
		me.dir = resolvepath(dir) ~ "/";
		me.mpprop = "sim/model/livery/file";
		var relpath = func(p) substr(p, p[0] == `/`);
        me.nameprop = relpath("sim/model/livery/name");
        me.ownerprop = relpath("sim/model/livery/owner");
        me.pilotprop = relpath("sim/model/livery/pilot");
        me.schemeprop = relpath("sim/model/livery/scheme");
        me.engineprop = relpath("sim/model/livery/block");
        me.squadprop = relpath("sim/model/livery/squad");
        me.serialprop = relpath("sim/model/livery/serial");
        me.yearprop = relpath("sim/model/livery/year");
        me.cftprop = relpath("sim/model/f16/cft");
        me.chuteprop = relpath("sim/model/f16/dragchute");
        me.sortprop = relpath(sortprop or me.nameprop);
        if (me.mpprop != nil) {
            aircraft.data.add(me.nameprop);
            aircraft.data.add(me.mpprop);
        }
        me.reinit();
	},
	rescan: func {
		if (dialog != nil) {
			#print("  Rescan closes dialog:");
			dialog.del();
		}
		me.clearOwner();
        me.data = [];
        var files = directory(me.dir);
        if (size(files)) {
            foreach (var file; files) {
                if (substr(file, -4) != ".xml")
                    continue;
                var n = io.read_properties(me.dir ~ file);
                var name = n.getNode(me.nameprop, 1).getValue();
                var index = n.getNode(me.sortprop, 1).getValue();
                var owner = n.getNode(me.ownerprop, 1).getValue();
                var pilot = n.getNode(me.pilotprop, 1).getValue() or "";
                var scheme = n.getNode(me.schemeprop, 1).getValue() or "Two-tone gray";
                var engine = n.getNode(me.engineprop, 1).getValue();
                var squad = n.getNode(me.squadprop, 1).getValue() or "";
                var serial = n.getNode(me.serialprop, 1).getValue() or substr(file, 0, size(file) - 4);
                var year = n.getNode(me.yearprop, 1).getValue() or "";
                var cft = n.getNode(me.cftprop, 1).getValue() or 0;
                var chute = n.getNode(me.chuteprop, 1).getValue() or 0;

                if (name == nil or index == nil or owner == nil)
                    continue;
                append(me.data, [name, index, substr(file, 0, size(file) - 4), me.dir ~ file, owner, pilot, scheme, engine, squad, serial, year, chute, cft]);
                me.addOwner(owner);
            }
            me.data = sort(me.data, func(a, b) num(a[1]) == nil or num(b[1]) == nil
                    ? cmp(a[1], b[1]) : a[1] - b[1]);
        }
    },
    addOwner: func (owner) {
    	if (me.owners[owner] == nil) {
    		me.owners[owner] = [];
    	}
    },
    clearOwner: func {
    	me.owners = {};
    },
    reinit: func {
        me.rescan();
        me.current = -1;
        if (me.mpprop != nil)
        	if(!me.selectByFile(getprop(me.mpprop) or ""))# filenames change less often, so start by trying that
        		me.select(getprop(me.nameprop) or "");#filename didn't work, try name
    },
    set: func(index) {
        var last = me.current;
        me.current = math.mod(index, size(me.data));
        io.read_properties(me.data[me.current][3], props.globals);
        if (last != me.current and me["callback"] != nil)
            call(me.callback, [me.current] ~ me.data[me.current], me);
        if (me.mpprop != nil)
            setprop(me.mpprop, me.data[me.current][2]);
    },
    selectByFile: func(filename) {
        forindex (var i; me.data) {
            if (me.data[i][2] == filename) {
                me.set(i);
                return 1;
            }
        }
        return 0;
    },
    select: func(name) {
        forindex (var i; me.data) {
            if (me.data[i][0] == name) {
                me.set(i);
                return;
            }
        }
    },
    next: func {
        me.set(me.current + 1);
    },
    previous: func {
        me.set(me.current - 1);
    },
	toggle: func {
		if (dialog == nil) {
			#print("  Menu opens dialog:");
			dialog = canvas.Window.new(sized,"window","f16_livery_dialog", 1)
						.set("title", "Livery selection")
						.setPosition(position)
						.set("resize", 0);
			#me.canvas = dialog.createCanvas();
			me.rooty = dialog.getCanvas(1).createGroup();
			dialog.getCanvas().setColorBackground(viperStyle.getColor("bg_color_contrast"));
		 	
			me.vboxMain = canvas.VBoxLayout.new();
		 	me.hbox = canvas.HBoxLayout.new();	
		 	me.vboxForces = canvas.VBoxLayout.new();
			var vboxLivs = canvas.VBoxLayout.new();
			#me.vboxLivs.minimumSize([250,25]);
			#me.vboxLivs.maximumSize([250,256]);
			
			me.area = canvas.gui.widgets.ScrollArea.new(me.rooty, viperStyle, {});
			me._area_content = me.area.getContent();
			me.area.setLayout(vboxLivs);

			me.hbox.addItem(me.vboxForces);
			me.hbox.addItem(me.area, 1);# 1 means stretch
			me.vboxMain.addItem(me.hbox);


			# Add info labels:
			var height = 15;
            me.infoLivery = canvas.gui.widgets.Label.new(me.rooty, viperStyle, {"wordWrap": 0})
                    .setFixedSize(400,height)
                    .setText("");
            me.infoYear = canvas.gui.widgets.Label.new(me.rooty, viperStyle, {"wordWrap": 0})
                    .setFixedSize(50,height)
                    .setText("");
            
            me.infoEngine = canvas.gui.widgets.Label.new(me.rooty, viperStyle, {"wordWrap": 0})
                    .setFixedSize(250,height)
                    .setText("");
			me.infoSerial = canvas.gui.widgets.Label.new(me.rooty, viperStyle, {"wordWrap": 0})
                    .setFixedSize(150,height)
                    .setText("");

            me.infoOwner = canvas.gui.widgets.Label.new(me.rooty, viperStyle, {"wordWrap": 0})
                    .setFixedSize(150,height)
                    .setText("");            
            me.infoSquad = canvas.gui.widgets.Label.new(me.rooty, viperStyle, {"wordWrap": 0})
                    .setFixedSize(250,height)
                    .setText("");

            me.infoScheme = canvas.gui.widgets.Label.new(me.rooty, viperStyle, {"wordWrap": 0})
                    .setFixedSize(250,height)
                    .setText("");
            me.infoPilot = canvas.gui.widgets.Label.new(me.rooty, viperStyle, {"wordWrap": 0})
                    .setFixedSize(150,height)
                    .setText("");

            me.infoCft = canvas.gui.widgets.Label.new(me.rooty, viperStyle, {"wordWrap": 0})
                    .setFixedSize(250,height)
                    .setText("");
            me.infoChute = canvas.gui.widgets.Label.new(me.rooty, viperStyle, {"wordWrap": 0})
                    .setFixedSize(150,height)
                    .setText("");


            #livery    year
			#block     serial
			#airforce  sqn  
			#scheme    pilot
			#chute     cft

            me.hbox1 = canvas.HBoxLayout.new();
            me.hbox2 = canvas.HBoxLayout.new();
            me.hbox3 = canvas.HBoxLayout.new();
            me.hbox4 = canvas.HBoxLayout.new();
            me.hbox5 = canvas.HBoxLayout.new();
            me.vboxMain.addItem(me.hbox1);
            me.vboxMain.addItem(me.hbox2);
            me.vboxMain.addItem(me.hbox3);
            me.vboxMain.addItem(me.hbox4);
            me.vboxMain.addItem(me.hbox5);
            me.vboxMain.addSpacing(5);

            me.hbox1.addItem(me.infoLivery);
            me.hbox1.addItem(me.infoYear);

            me.hbox2.addItem(me.infoEngine);
            me.hbox2.addItem(me.infoSerial);

            
            me.hbox3.addItem(me.infoSquad);
            me.hbox3.addItem(me.infoOwner);

            me.hbox4.addItem(me.infoScheme);
            me.hbox4.addItem(me.infoPilot);

            me.hbox5.addItem(me.infoCft);
            me.hbox5.addItem(me.infoChute);
            

            # TODO: Refresh button that calls me.reinit()

	    	dialog.setLayout(me.vboxMain);


			

			var idx = 0;
			foreach (var livery ; me.data) {
				me.makeLiveryButton(livery, idx, vboxLivs);
			    idx+=1;
		    }
			vboxLivs.addStretch(1);

			foreach (var airforce ; keys(me.owners)) {
				me.makeForceButton(airforce);
	        }
			me.vboxForces.addStretch(1);

			dialog.del = func {
				#print("Closing livery dialog neatly");
				#sized = dialog.getSize();
				position[0] = dialog.get("tf/t[0]");
				position[1] = dialog.get("tf/t[1]");
				call(canvas.Window.del, [], dialog);
				dialog = nil;
				me.activeOwnerButton = nil;
				me.activeLiveryButton = nil;

				# bah:
				me.rooty = nil;
				me.vboxMain = nil;
			 	me.hbox = nil;
			 	me.vboxForces = nil;
				me.area = nil;
				me._area_content = nil;
				me.infoOwner = nil;
	            me.infoLivery = nil;
	            me.infoScheme = nil;
	            me.infoPilot = nil;
	            me.infoSerial = nil;
	            me.infoSquad = nil;
	            me.infoEngine = nil;
	            me.infoYear = nil;
	            me.infoCft = nil;
	            me.infoChute = nil;
	            me.hbox1 = nil;
	            me.hbox2 = nil;
	            me.hbox3 = nil;
	            me.hbox4 = nil;
	            me.hbox5 = nil;
			}
		} else {
			#print("  Menu closes dialog:");
			dialog.del();
		}
	},
	makeLiveryButton: func (livery, idx, vboxLivs) {
		var newB = canvas.gui.widgets.Button.new(me._area_content, viperStyle, {"flat": 0})
	                                    .setCheckable(1)
	                                    .setFixedSize(375,25)
	                                    .setText(livery[0]);
	        
        if (me.current == idx) {
	    	newB.setChecked(1);
	    	me.activeLiveryButton = newB;
	    	me.setInfoText(livery);
	    }
	    
        newB.listen("toggled", func (e) {
        	#print(idx, " Set ",livery[0],", ",livery[1],", ",livery[2],", ",livery[3],", ",livery[4]);
        	if(e.detail.checked) {
	        	me.set(idx);
	        	if (me["activeLiveryButton"] != nil) me.activeLiveryButton.setChecked(0);
	        	me.activeLiveryButton = newB;
	        	me.setInfoText(livery);
	        }
	    });
	    vboxLivs.addItem(newB);
	    #print("Making livery button ",livery[0]," for ",livery[4]);
	    append(me.owners[livery[4]], newB);	
	    newB.setVisible(0);
	},
	setInfoText: func (livery) {
		#   0     1        2       3     4      5       6     7         8     9      10     11    12
		# name, index, filename, path, owner, pilot, scheme, engine, squad, serial, year, chute, cft

		me.infoLivery.setText("Livery: "~livery[0]);
		me.infoYear.setText(livery[10]);
    	me.infoOwner.setText( "Airforce: "~livery[4]);
    	me.infoScheme.setText("Scheme: "~livery[6]);
    	me.infoSquad.setText( "Squadron: "~livery[8]);
    	me.infoSerial.setText("Serial: "~livery[9]);
    	if (livery[7] != nil) me.infoEngine.setText("Block: "~livery[7]);
    	else me.infoEngine.setText(" ");
    	if (livery[5] != "") me.infoPilot.setText( "Pilot: "~livery[5]);
    	else me.infoPilot.setText(" ");
    	me.infoCft.setText(sprintf("Conformal fuel tanks: %s", livery[12]?"Yes":"No "));
    	me.infoChute.setText(sprintf("Dragchute: %s", livery[11]?"Yes":"No "));
	},
	makeForceButton: func (airforce) {
		#print("Making button for ", airforce);
		var newF = canvas.gui.widgets.Button.new(me.rooty, viperStyle, {"flat": 0})
                    .setCheckable(1)
                    .setChecked(0)
                    .setFixedSize(100,25)
                    .setText(airforce);

        me.vboxForces.addItem(newF);
        
        newF.listen("toggled", func (e) {
        	#print("Toggle ", airforce);
        	if(e.detail.checked) {
        		foreach (me.livButton ; me.owners[airforce]) {
        			me.livButton.setVisible(1);
        		}
        		if (me["activeOwnerButton"] != nil) me.activeOwnerButton.setChecked(0);
	        	me.activeOwnerButton = newF;
		    } else {
		    	foreach (me.force ; keys(me.owners)) {
		    		if (me.force != airforce) {
		    			foreach (me.livButton ; me.owners[airforce]) {
		    				me.livButton.setVisible(0);
		    			}
		    		}
		    	}
		    }
	    });
	    if (me.current != -1 and me.data[me.current][4] == airforce) {
	    	newF.setChecked(1);
	    	me.activeOwnerButton = newF;
	    } else {
	    	newF.setChecked(0);
	    }
	},
};

diag.init(getprop("sim/model/livery/folder"));
#diag.toggle();