# A failure panel widget
#
# Contributors: Nikolai V. Chr. (Necolatis)
#
gui.widgets.Failure = {
  new: func(parent, style, cfg)
  {
    var m = gui.Widget.new(gui.widgets.Failure);

    m._cfg = Config.new(cfg);
    m._focus_policy = m.NoFocus;

    var w = {
      parents: [FailureFactory],
      _style: style,
    };
    call(FailureFactory.new, [parent, m._cfg], w, var err = []);

    if(size(err)) {
      foreach(var error; err) {
        print(error);
      }
    }

    m._setView(w);

    return m;
  },

  onRemove: func
  {
    if( me._view != nil )
    {
      # the following 3 lines is only difference from parent Widget destructor:
      if (me._view._handle != nil) {
        FailureMgr.events["trigger-fired"].unsubscribe(me._view._handle);
      }
      me._view._root.del();
      me._view = nil;
    }

    if( me._focused )
      me.getCanvas()._focused_widget = nil;
  },
};

FailureFactory = {
  new: func(parent, cfg)
  {
    me._root = parent.createChild("group", "failure-panel");

    me._vbox = VBoxLayout.new();
    me._vbox.setCanvas(me._root.getCanvas());

    #top part
    me._tabs = gui.widgets.Tabs.new(me._root, me._style, {});
    me._tabs.addTab(me._createListPage(), "Failures", 75);
    me._tabs.addTab(me._createRandomPage(), "Global", 75);
    me._tabs.addTab(me._createLogPage(), "Log", 75);
    me._vbox.addItem(me._tabs, 1);

    # Bottom part
    me._display_checkbox = gui.widgets.Button.new(me._root, me._style, {}).setCheckable(1);
    me._display_checkbox.setFixedSize(75,25);
    if (getprop("/sim/failure-manager/display-on-screen") == 1) {
      me._display_checkbox.setChecked(1);
      me._display_checkbox.setText("Enabled");
    } else {
      me._display_checkbox.setChecked(0);
      me._display_checkbox.setText("Disabled");
    }
    me._display_checkbox.listen("toggled", func (e) {
      if( !e.detail.checked ) {
        me._display_checkbox.setText("Disabled");
        setprop("/sim/failure-manager/display-on-screen", 0);
      } else {
        me._display_checkbox.setText("Enabled");
        setprop("/sim/failure-manager/display-on-screen", 1);
      }
    });
    me._display_label = gui.widgets.Label.new(me._root, me._style, {wordWrap: 0}).setText("Display failure messages on screen:");
    var hbox = HBoxLayout.new();
    hbox.addStretch(1);
    hbox.addItem(me._display_label);
    hbox.addItem(me._display_checkbox);
    hbox.addStretch(1);
    me._vbox.addItem(hbox);
    me._vbox.setSpacing(0);

    return me;
  },

  # Reset the size of the content area, e.g. on window resize.
  #
  #
  setSize: func(model, w, h)
  {
    me._vbox.setGeometry([0,0,w,h]);
    return me;
  },

  update: func(model)
  {
    if(me._vbox.getParent() == nil) {
      me._vbox.setParent(model);
    }
    
    me._root.update();
  },

  # protected:

  _roundabout: func(x) {
    var y = x - int(x);

    return y < 0.5 ? int(x) : 1 + int(x) ;
  },

  _createListPage: func () {
    me._scroll = gui.widgets.ScrollArea.new(me._root, me._style, {size: [96, 128]})
                                       .move(20, 100);
    me._refreshButton = gui.widgets.Button.new(me._root, me._style, {})
                                    .setCheckable(0)
                                    .setFixedSize(75,25)
                                    .setText("Refresh");
    me._repairAllButton = gui.widgets.Button.new(me._root, me._style, {})
                                    .setCheckable(0)
                                    .setFixedSize(75,25)
                                    .setText("Repair all");
    me._disableAllButton = gui.widgets.Button.new(me._root, me._style, {})
                                    .setCheckable(0)
                                    .setFixedSize(150,25)
                                    .setText("Remove all triggers");
    me._refreshButton.listen("clicked", func (e) {
        me._update();
    });
    me._repairAllButton.listen("clicked", func (e) {
        me._repairAll();
    });
    me._disableAllButton.listen("clicked", func (e) {
        me._disableAll();
    });

    me._scroll_content =
    me._scroll.getContent()
            .set("font", "LiberationFonts/LiberationSans-Bold.ttf")
            .set("character-size", 16)
            .set("alignment", "left-center");

    me._list = VBoxLayout.new();
    me._scroll.setLayout(me._list);

    me._listBoxButtons = HBoxLayout.new();
    me._listBoxButtons.addItem(me._refreshButton);
    me._listBoxButtons.addItem(me._repairAllButton);
    me._listBoxButtons.addItem(me._disableAllButton);

    me._listBox = VBoxLayout.new();
    me._listBox.addItem(me._scroll, 1);
    me._listBox.addItem(me._listBoxButtons);

    me._populateList();

    me._handle = FailureMgr.events["trigger-fired"].subscribe(func {call(me._update, nil, me, me)});# Hope this can be done with scope

    return me._listBox;
  },

  _createRandomPage: func () {
    me._random = VBoxLayout.new();
    var labelTitle = gui.widgets.Label.new(me._root, me._style, {wordWrap: 0});
    labelTitle.setText("Configure MTBF/MCBF for all default systems and instruments.");
    me._random.addItem(labelTitle);
    me._labelInfo = gui.widgets.Label.new(me._root, me._style, {wordWrap: 0});
    
    var buttonsHbox = HBoxLayout.new();
    var buttonsMtbf = VBoxLayout.new();
    var buttonsMcbf = VBoxLayout.new();

    buttonsHbox.addItem(buttonsMtbf);
    buttonsHbox.addItem(buttonsMcbf);
    me._random.addItem(buttonsHbox);
    me._random.addItem(me._labelInfo);

    # type 0:mtbf  1:mcbf
    var globalHash = [{type: 0, title: "1 minute",   value:    60},
                      {type: 0, title: "5 minutes",  value:   300},
                      {type: 0, title: "10 minutes", value:   600},
                      {type: 0, title: "30 minutes", value:  1800},
                      {type: 0, title: "1 hour",     value:  3600},
                      {type: 0, title: "6 hours",    value: 21600},
                      {type: 0, title: "24 hours",   value: 86400},
                      {type: 0, title: "Disable",    value:     0},
                      {type: 1, title: "5 cycles",   value:     5},
                      {type: 1, title: "10 cycles",  value:    10},
                      {type: 1, title: "20 cycles",  value:    20},
                      {type: 1, title: "50 cycles",  value:    50},
                      {type: 1, title: "100 cycles", value:   100},
                      {type: 1, title: "200 cycles", value:   200},
                      {type: 1, title: "500 cycles", value:   500},
                      {type: 1, title: "Disable",    value:     0}];

    foreach (var entry; globalHash) {
      var button = gui.widgets.Button.new(me._root, style, {}).setCheckable(0);
      button.setText(entry.title);
      button.setFixedSize(100, 25);
      if(entry.type == 0) {
        (func {
            var value = entry.value;
            var title = entry.title;
            button.listen("clicked", func (e) {
              setprop("/sim/failure-manager/global-mtbf", value);
              compat_failure_modes.apply_global_mtbf(value);
              me._labelInfo.setText("Global MTBF set to "~title~".");
              me._update();
            });
        })();
        
        buttonsMtbf.addItem(button);
      } else {
        (func {
            var value = entry.value;
            var title = entry.title;
            button.listen("clicked", func (e) {
              setprop("/sim/failure-manager/global-mcbf", value);
              compat_failure_modes.apply_global_mcbf(value);
              me._labelInfo.setText("Global MCBF set to "~title~".");
              me._update();
            });
        })();
        buttonsMcbf.addItem(button);
      }
    }

    return me._random;    
  },

  _createLogPage: func () {
    var buffer = FailureMgr.get_log_buffer();
    var str = "";
    foreach(entry; buffer) {
      str = str~entry.time~" "~entry.message~"\n";
    }


    me._logPage = VBoxLayout.new();
    
    me._logScroll = gui.widgets.ScrollArea.new(me._root, me._style, {size: [96, 128]});
    me._logContent = me._logScroll.getContent()
            .set("font", "LiberationFonts/LiberationSans-Bold.ttf")
            .set("character-size", 16)
            .set("alignment", "left-top");
    
    me._labelLog = gui.widgets.Label.new(me._logContent, me._style, {wordWrap: 1})
                          .setText(str);
    me._logPage.addItem(me._labelLog);


    me._logScroll.setLayout(me._logPage);

    me._refreshButton2 = gui.widgets.Button.new(me._root, me._style, {})
                                    .setCheckable(0)
                                    .setFixedSize(75,25)
                                    .setText("Refresh");
    me._refreshButton2.listen("clicked", func (e) {
        me._update();
    });

    me._logBoxButtons = HBoxLayout.new();
    me._logBoxButtons.addItem(me._refreshButton2);

    me._logBox = VBoxLayout.new();
    me._logBox.addItem(me._logScroll, 1);
    me._logBox.addItem(me._logBoxButtons);

    return me._logBox;
  },

  # iterate through all failure components and display each of them
  _populateList: func()
  {
    # grab failure modes from the failure manager
    var failure_modes = FailureMgr._failmgr.failure_modes; # hash with the failure modes
    var mode_list = keys(failure_modes);#values()?
    me._entryUpdateVector = [];
    # build entries
    # an entry is {string mode_description, string mode_failure_level, string trigger_description, bool trigger_active, string trigger_type [MCBF|MTBF|COSTUM], float trigger_value}

    foreach(var failure_mode_id; mode_list) {
      me._addEntry (failure_modes[failure_mode_id], failure_mode_id);
    }
  },

  _disableAll: func()
  {
    # grab failure modes from the failure manager
    var failure_modes = FailureMgr._failmgr.failure_modes; # hash with the failure modes
    var mode_list = keys(failure_modes);#values()?

    # build entries
    # an entry is {string mode_description, string mode_failure_level, string trigger_description, bool trigger_active, string trigger_type [MCBF|MTBF|COSTUM], float trigger_value}
    foreach(var failure_mode_id; mode_list) {
      var trigger = failure_modes[failure_mode_id].trigger;
      if(me._isTriggerCustom(trigger) == 0) { # do not remove custom triggers
        FailureMgr.set_trigger(failure_mode_id, nil);
      }
    }
    me._update();
  },

  _isTriggerCustom: func(trigger) {
    if(trigger != nil
      and trigger.type != "mcbf"
      and trigger.type != "mtbf"
      and trigger.type != "waypoint"
      and trigger.type != "altitude"
      and trigger.type != "timeout"
      ) {
      return 1;
    } else {
      return 0;
    }
  },

  _repairAll: func()
  {
    # grab failure modes from the failure manager
    var failure_modes = FailureMgr._failmgr.failure_modes; # hash with the failure modes
    var mode_list = keys(failure_modes);#values()?

    # build entries
    # an entry is {string mode_description, string mode_failure_level, string trigger_description, bool trigger_active, string trigger_type [MCBF|MTBF|COSTUM], float trigger_value}
    foreach(var failure_mode_id; mode_list) {
      FailureMgr.set_failure_level(failure_mode_id, 0);
    }
    me._update();
  },

  #set text color depending on failure level
  _setLevelColor: func (level, item) {
    # orange for semi failed
    var r = 1.0;
    var g = 0.5;
    var b = 0;
    if(level == 1) {
      # red for failed
      r = 1;
      g = 0;
      b = 0;
    } elsif (level == 0) {
      # green for healthy
      r = 0;
      g = 0.5;
      b = 0;
    }
    item._view._text.setColor(r,g,b);
  },

  # update text description of trigger and the fired button
  _updateTriggerDescription: func (label, button, trigger) {
    var trigger_description = trigger == nil?"No trigger!":trigger.to_str();
    label.setText(trigger_description);
    me._updateButtonFired(button, trigger);
  },

  # update text description of the fired button
  _updateButtonFired: func (button, trigger) {
    if(trigger == nil or trigger.armed == 0) {
      button.setText("Inactive");
    } else {
      button.setText("Active");
    }
  },

  # display manipulation items for altitude trigger
  _triggerAltitudeBox: func (label, trigger, button, path) {
    var alt_item = HBoxLayout.new();
    var min_buttons_item = VBoxLayout.new();
    var max_buttons_item = VBoxLayout.new();
    var ftMinLabel = gui.widgets.Label.new(me._scroll_content, me._style, {}).setFixedSize(40, 30);
    var ftMaxLabel = gui.widgets.Label.new(me._scroll_content, me._style, {}).setFixedSize(40, 30);

    var input_min = trigger.params["min-altitude-ft"];
    var input_max = trigger.params["max-altitude-ft"];
    

    
    ###########################################
    ### edit min field  #######################

    var ftMinEdit = gui.widgets.LineEdit.new(me._scroll_content, me._style, {}).setFixedSize(70, 30);

    me._updateInput(ftMinEdit, ftMinLabel, input_min, "feet");

    ftMinEdit.listen("focus-out", func
    {
      # edit input
      newInput = num(ftMinEdit.text());
      if(newInput != input_min) {
        input_min = newInput>input_max?input_max-1:newInput;
        trigger = me._updateFtTrigger(label, ftMinEdit, ftMinLabel, trigger, input_min, "min-altitude-ft", button, path);
      }
    });

    ###########################################
    ### plus min ft button ####################
    var buttonFtMinPlus = gui.widgets.Button.new(me._scroll_content, me._style, {})
                              .setText("+")
                              .setFixedSize(25, 15);
    min_buttons_item.addItem(buttonFtMinPlus);

    buttonFtMinPlus.listen("clicked", func
    {
      # increase input
      input_min += 100;
      input_min = input_min>input_max?input_max-1:input_min;
      trigger = me._updateFtTrigger(label, ftMinEdit, ftMinLabel, trigger, input_min, "min-altitude-ft", button, path);
    });
    ###########################################
    ### minus min ft button #####################
    var buttonFtMinMinus = gui.widgets.Button.new(me._scroll_content, me._style, {})
                              .setText("-")
                              .setFixedSize(25, 15);
                              
    min_buttons_item.addItem(buttonFtMinMinus);

    buttonFtMinMinus.listen("clicked", func
    {
      # decrease input
      input_min -= 100;
      if(input_min < 0) {
        input_min = 0;
      }
      trigger = me._updateFtTrigger(label, ftMinEdit, ftMinLabel, trigger, input_min, "min-altitude-ft", button, path);
    });
    ###########################################
    ### edit max field  #######################

    var ftMaxEdit = gui.widgets.LineEdit.new(me._scroll_content, me._style, {}).setFixedSize(70, 30);

    me._updateInput(ftMaxEdit, ftMaxLabel, input_max, "feet");

    ftMaxEdit.listen("focus-out", func
    {
      # edit input
      newInput = num(ftMaxEdit.text());
      if(newInput != input_max) {
        input_max = newInput<input_min?input_min+1:newInput;
        trigger = me._updateFtTrigger(label, ftMaxEdit, ftMaxLabel, trigger, input_max, "max-altitude-ft", button, path);
      }
    });    
    ###########################################    
    ### plus max ft button #####################
    var buttonFtMaxPlus = gui.widgets.Button.new(me._scroll_content, me._style, {})
                              .setText("+")
                              .setFixedSize(25, 15);
    max_buttons_item.addItem(buttonFtMaxPlus);

    buttonFtMaxPlus.listen("clicked", func
    {
      # increase input
      input_max += 100;
      trigger = me._updateFtTrigger(label, ftMaxEdit, ftMaxLabel, trigger, input_max, "max-altitude-ft", button, path);
    });
    ###########################################
    ### minus max ft button #####################
    var buttonFtMaxMinus = gui.widgets.Button.new(me._scroll_content, me._style, {})
                              .setText("-")
                              .setFixedSize(25, 15);
                              
    max_buttons_item.addItem(buttonFtMaxMinus);

    buttonFtMaxMinus.listen("clicked", func
    {
      # decrease input
      input_max -= 100;
      if(input_max < 1) {
        input_max = 1;
      }
      input_max = input_max<input_min?input_min+1:input_max;
      trigger = me._updateFtTrigger(label, ftMaxEdit, ftMaxLabel, trigger, input_max, "max-altitude-ft", button, path);
    });
    ###########################################

    alt_item.addItem(ftMinEdit);
    alt_item.addItem(ftMinLabel);
    alt_item.addItem(min_buttons_item);
    alt_item.addStretch(1);
    alt_item.addItem(ftMaxEdit);
    alt_item.addItem(ftMaxLabel);
    alt_item.addItem(max_buttons_item);
    alt_item.addStretch(1);
    alt_item.addStretch(1);

    return [alt_item, min_buttons_item, max_buttons_item];
  },

  # display manipulation items for MCBF trigger
  _triggerCyclesBox: func (label, trigger, button, path, property) {
    var cycle_item = HBoxLayout.new();
    var cycle_buttons_item = VBoxLayout.new();
    var cycleLabel = gui.widgets.Label.new(me._scroll_content, me._style, {}).setFixedSize(50, 30);

    var input = trigger.params["mcbf"];
    

                                                                         
    ###########################################
    ### edit field  ###########################

    var cycleEdit = gui.widgets.LineEdit.new(me._scroll_content, me._style, {}).setFixedSize(60, 30);

    me._updateInput(cycleEdit, cycleLabel, input, "cycles");


    cycleEdit.listen("focus-out", func
    {
      # edit input
      newInput = num(cycleEdit.text());
      if(newInput != input) {
        input = newInput;
        trigger = me._updateMCBFTrigger(trigger, label, cycleEdit, cycleLabel, input, button, path, property);
      }
    });
    ###########################################
    ### plus min ft button ####################
    var buttonCyclePlus = gui.widgets.Button.new(me._scroll_content, me._style, {})
                              .setText("+")
                              .setFixedSize(25, 15);
    cycle_buttons_item.addItem(buttonCyclePlus);

    buttonCyclePlus.listen("clicked", func
    {
      # increase input
      input += 10;
      trigger = me._updateMCBFTrigger(trigger, label, cycleEdit, cycleLabel, input, button, path, property);
    });
    ###########################################
    ### minus min ft button #####################
    var buttonCycleMinus = gui.widgets.Button.new(me._scroll_content, me._style, {})
                              .setText("-")
                              .setFixedSize(25, 15);
                              
    cycle_buttons_item.addItem(buttonCycleMinus);

    buttonCycleMinus.listen("clicked", func
    {
      # decrease input
      input -= 10;
      if(input < 1) {
        input = 1;
      }
      trigger = me._updateMCBFTrigger(trigger, label, cycleEdit, cycleLabel, input, button, path, property);
    });
    ###########################################    

    cycle_item.addItem(cycleEdit);
    cycle_item.addItem(cycleLabel);
    cycle_item.addItem(cycle_buttons_item);
    cycle_item.addStretch(1);
    cycle_item.addStretch(1);
    cycle_item.addStretch(1);

    return [cycle_item, cycle_buttons_item, cycle_buttons_item];
  },

  # display manipulation items for Waypoint trigger
  _triggerWaypointBox: func (label, trigger, button, path) {
    var way_item = HBoxLayout.new();
    var way_buttons_item = VBoxLayout.new();
    var wayLabel = gui.widgets.Label.new(me._scroll_content, me._style, {}).setFixedSize(50, 30);
    var distLabel = gui.widgets.Label.new(me._scroll_content, me._style, {}).setFixedSize(30, 30);

    var input_lat = trigger.params["latitude-deg"];
    var input_lon = trigger.params["longitude-deg"];
    var input_dist = trigger.params["distance-nm"];
    var input_icao = "????";
                                                                         
    ###########################################
    ### ICAO edit field  ###########################

    var wayEdit = gui.widgets.LineEdit.new(me._scroll_content, me._style, {}).setFixedSize(60, 30);

    me._updateInput(wayEdit, wayLabel, input_icao, "Airport");


    wayEdit.listen("focus-out", func
    {
      # edit ICAO input
      newInput = wayEdit.text();
      if(newInput != input_icao) {
        input_icao = newInput;
        trigger = me._updateWaypointTrigger(label, wayEdit, wayLabel, input_dist, input_icao, button, path);
      }
    });
    ###########################################
    ### Distance edit field  ##################

    var distEdit = gui.widgets.LineEdit.new(me._scroll_content, me._style, {}).setFixedSize(60, 30);

    me._updateInput(distEdit, distLabel, input_dist, "nm");


    distEdit.listen("focus-out", func
    {
      # edit distance input
      newInput = num(distEdit.text());
      if(newInput != input_dist) {
        input_dist = newInput;
        trigger = me._updateWaypointTrigger(label, wayEdit, wayLabel, input_dist, input_icao, button, path);
      }
    });  
 

    way_item.addItem(distEdit);
    way_item.addItem(distLabel);
    way_item.addItem(wayEdit);
    way_item.addItem(wayLabel);
    way_item.addStretch(1);
    way_item.addStretch(1);
    way_item.addStretch(1);

    return [way_item, way_item, way_item];
  },  

  _updateWaypointTrigger: func (labelDesc, editInputICAO, labelInputICAO, input_dist, input_icao, button, path) {
    var trigger = nil;

    #airport = findAirportsByICAO(input_icao);
    airport = airportinfo(input_icao);
    if (airport != nil) {
      trigger = compat_failure_modes.WaypointTrigger.new(airport.lat, airport.lon, input_dist);
      
      FailureMgr.set_trigger(path, trigger);

      me._updateTriggerDescription(labelDesc, button, trigger);
    } else {
      input_icao = "XXXX";
      FailureMgr.set_trigger(path, nil);
      me._updateTriggerDescription(labelDesc, button, nil);
    }
    me._updateInput(editInputICAO, labelInputICAO, input_icao, "Airport");
    return trigger;
  }, 

  _updateTimeTrigger: func (trigger, labelDesc, editInput, labelInput, path, input, unit, unitText, type, button) {
    if(type == "mtbf") {
      trigger.set_param("mtbf", input * unit);
    } elsif (type == "timeout") {
      trigger.set_param("timeout-sec", input * unit);
    }
    trigger.arm();
    trigger.disarm();
    me._updateTriggerDescription(labelDesc, button, trigger);
    me._updateInput(editInput, labelInput, input, unitText);
    return trigger;
  },

  _updateFtTrigger: func (labelDesc, editInput, labelInput, trigger, input, type, button, path) {
    if(type == "max-altitude-ft") {
      trigger.set_param("max-altitude-ft", input);
    } elsif (type == "min-altitude-ft") {
      trigger.set_param("min-altitude-ft", input);
    }
    trigger.arm();
    trigger.disarm();
    me._updateTriggerDescription(labelDesc, button, trigger);
    me._updateInput(editInput, labelInput, input, "feet");
    return trigger;
  },  

  _updateMCBFTrigger: func (trigger, labelDesc, editInput, labelInput, input, button, path, property) {
    trigger.set_param("mcbf", input);
    trigger.arm();
    trigger.disarm();
    me._updateTriggerDescription(labelDesc, button, trigger);
    me._updateInput(editInput, labelInput, input, "cycles");
    return trigger;
  }, 

  _updateInput: func (edit, label, input, unitText) {
    label.setText(unitText);
    edit.setText(""~input);
  },  

  # display manipulation items for MTBF trigger
  _triggerMtbfBox: func (label, trigger, button, path) {
    var value = trigger.params["mtbf"];
    return me._triggerTimeBox(label, trigger, value, "mtbf", button, path);
  },

  # display manipulation items for timeout trigger
  _triggerTimeoutBox: func (label, trigger, button, path) {
    var value = trigger.params["timeout-sec"];
    return me._triggerTimeBox(label, trigger, value, "timeout", button, path);
  },

  # display manipulation items for any time dependent trigger
  _triggerTimeBox: func (label, trigger, value, type, button, path) {
    var time_item = HBoxLayout.new();
    var time_buttons_item = VBoxLayout.new();
    var timeLabel = gui.widgets.Label.new(me._scroll_content, me._style, {}).setFixedSize(50, 30);

    var unit = nil;
    var unitText = nil;
    var input = nil;

    
    # change unit
    if (value < 60) {
      unit = 1;
      unitText = "secs";
      input = me._roundabout(value);
    } elsif (value < 3600) {
      unit = 60;
      unitText = "mins";
      input = me._roundabout(value / 60);
    } elsif(value < 86400) {
      unit = 3600;
      unitText = "hours";
      input = me._roundabout(value / 3600);
    } else {
      unit = 86400;
      unitText = "days";
      input = me._roundabout(value / 86400);
    }

    ###########################################
    ### edit field  ###########################

    var timeEdit = gui.widgets.LineEdit.new(me._scroll_content, me._style, {}).setFixedSize(60, 30);

    me._updateInput(timeEdit, timeLabel, input, unitText);

    timeEdit.listen("focus-out", func
    {
      # edit input
      newInput = num(timeEdit.text());
      if(newInput != input) {
        input = newInput;
        trigger = me._updateTimeTrigger(trigger, label, timeEdit, timeLabel, path, input, unit, unitText, type, button);
      }
    });

    ### unit button #####################
    var buttonUnit = gui.widgets.Button.new(me._scroll_content, me._style, {})
                              .setText("Units")
                              .setFixedSize(45, 20);

    buttonUnit.listen("clicked", func
    {
      
      # change unit
      if(unit == 1) {
        unit = 60;
        unitText = "mins";
      } elsif(unit == 60) {
        unit = 3600;
        unitText = "hours";
      } elsif(unit == 3600) {
        unit = 86400;
        unitText = "days";
      } elsif(unit == 86400) {
        unit = 1;
        unitText = "secs";
      }
      trigger = me._updateTimeTrigger(trigger, label, timeEdit, timeLabel, path, input, unit, unitText, type, button);
    });
    ###########################################
    ### plus time button #####################
    var buttonTimePlus = gui.widgets.Button.new(me._scroll_content, me._style, {})
                              .setText("+")
                              .setFixedSize(25, 15);
    time_buttons_item.addItem(buttonTimePlus);

    buttonTimePlus.listen("clicked", func
    {
      # increase input
      input += 1;
      trigger = me._updateTimeTrigger(trigger, label, timeEdit, timeLabel, path, input, unit, unitText, type, button);
    });
    ###########################################
    ### minus time button #####################
    var buttonTimeMinus = gui.widgets.Button.new(me._scroll_content, me._style, {})
                              .setText("-")
                              .setFixedSize(25, 15);
                              
    time_buttons_item.addItem(buttonTimeMinus);

    buttonTimeMinus.listen("clicked", func
    {
      # increase input
      input -= 1;
      if(input < 1) {
        input = 1;
      }
      trigger = me._updateTimeTrigger(trigger, label, timeEdit, timeLabel, path, input, unit, unitText, type, button);
    });
    ###########################################    

    time_item.addItem(timeEdit);
    time_item.addItem(timeLabel);
    time_item.addItem(time_buttons_item);
    time_item.addItem(buttonUnit);
    time_item.addStretch(1);
    time_item.addStretch(1);
    time_item.addStretch(1);

    return [time_item, time_buttons_item, time_buttons_item];
  },  

  # remove a manipulation items for a trigger
  _removeTriggerBox: func (triggerBox, bottom_item) {
    if(triggerBox != nil) {
      bottom_item.removeItem(triggerBox[0]);
      triggerBox[0].clear();#TODO: remove if bug fixed.
      triggerBox[1].clear();
      triggerBox[2].clear();
    }
  },

  # update all components, since they might have changed from outside
  _update: func () {
    foreach (var entryUpdate ; me._entryUpdateVector) {
      entryUpdate();
    }
    var buffer = FailureMgr.get_log_buffer();
    var str = "";
    foreach(entry; buffer) {
      str = str~entry.time~" "~entry.message~"\n";
    }
    me._labelLog.setText(str);
  },

  _addEntry: func (failure_mode, path) {
    var update_in_progress = 0;
    var entry = VBoxLayout.new();
    var top_item = HBoxLayout.new();
    var middle_item = HBoxLayout.new();
    var bottom_item = HBoxLayout.new();
    var triggerBox = nil;
    entry.addItem(top_item);
    entry.addItem(middle_item);
    entry.addItem(bottom_item);
    entry.addSpacing(20);
    var level = failure_mode.mode.get_failure_level();
    var buttonFired = gui.widgets.Button.new(me._scroll_content, me._style, {})
                              .setFixedSize(60, 20);    
    var mode_description = failure_mode.mode.description;    
    var mode_fail_level_text = "Condition: ";
    var mode_fail_level_value = sprintf("%03.1f", ((1-level)*100))~"%";
    var trigger_label = gui.widgets.Label.new(me._scroll_content, me._style, {});
    me._updateTriggerDescription(trigger_label, buttonFired, failure_mode.trigger);
    ##################################
    ###  top (level and component) ###
    ##################################

    top_item.addItem(gui.widgets.Label.new(me._scroll_content, style, {})
                         .setText(mode_fail_level_text));

    var value_item = gui.widgets.Label.new(me._scroll_content, style, {})
                         .setText(mode_fail_level_value)
                         .setFixedSize(50, 30);
                         
    # I think I did this due to adding color to this label, so it does not get overwritten
    value_item._view.update = func;

    me._setLevelColor(level, value_item);
    top_item.addItem(value_item);
    
    var level_buttons_item = VBoxLayout.new();


    top_item.addItem(level_buttons_item);    

    var buttonLevelRepair = gui.widgets.Button.new(me._scroll_content, style, {})
                              .setText("Repair")
                              .setFixedSize(60, 25);
                              
    top_item.addItem(buttonLevelRepair);

    top_item.addItem(gui.widgets.Label.new(me._scroll_content, style, {})
                         .setText(mode_description));
                         #.set("character-size", 25));
    top_item.addStretch(1);

    
    ################################
    ###  middle (trigger choice) ###
    ################################
    var active_button = nil;

    #####################################
    ### MTBF button #####################
    var buttonMTBF = gui.widgets.Button.new(me._scroll_content, style, {}).setCheckable(1);
    middle_item.addItem(buttonMTBF);
    buttonMTBF.setText("MTBF");
    buttonMTBF.setFixedSize(75,25);
    buttonMTBF.listen("toggled", func (e)
    {
      if( !e.detail.checked ) {
        buttonMTBF.setEnabled(1);
        return;
      }
      if( active_button != nil )
        active_button.setChecked(0);
      active_button = buttonMTBF;
      buttonMTBF.setEnabled(0);
      var mtbfTrigger = nil;
      if (update_in_progress == 0) {
        mtbfTrigger = compat_failure_modes.MtbfTrigger.new(3600);        
        FailureMgr.set_trigger(path, mtbfTrigger);
      } else {
        mtbfTrigger = failure_mode.trigger;
      }
      me._updateTriggerDescription(trigger_label, buttonFired, mtbfTrigger);
      me._removeTriggerBox(triggerBox, bottom_item);
      triggerBox = me._triggerMtbfBox(trigger_label, mtbfTrigger, buttonFired, path);
      bottom_item.addItem(triggerBox[0]);
    });
    if(failure_mode.trigger != nil and failure_mode.trigger.type == "mtbf") {
      update_in_progress = 1;
      buttonMTBF.setChecked(1);
      update_in_progress = 0;
    }
    ######################################    
    ### Timeout button ###################
    var buttonTime = gui.widgets.Button.new(me._scroll_content, style, {}).setCheckable(1);
    middle_item.addItem(buttonTime);
    buttonTime.setText("Timeout");
    buttonTime.setFixedSize(75,25);
    buttonTime.listen("toggled", func (e)
    {
      if( !e.detail.checked ) {
        buttonTime.setEnabled(1);
        return;
      }
      if( active_button != nil )
        active_button.setChecked(0);
      active_button = buttonTime;
      buttonTime.setEnabled(0);
      var timeTrigger = nil;
      if (update_in_progress == 0) {
        timeTrigger = compat_failure_modes.TimeoutTrigger.new(3600);
        FailureMgr.set_trigger(path, timeTrigger);
      } else {
        timeTrigger = failure_mode.trigger;
      }
      me._updateTriggerDescription(trigger_label, buttonFired, timeTrigger);
      me._removeTriggerBox(triggerBox, bottom_item);
      triggerBox = me._triggerTimeoutBox(trigger_label, timeTrigger, buttonFired, path);
      bottom_item.addItem(triggerBox[0]);      
    });
    if(failure_mode.trigger != nil and failure_mode.trigger.type == "timeout") {
      update_in_progress = 1;
      buttonTime.setChecked(1);
      update_in_progress = 0;
    }
    #####################################
    ### Altitude button ###################
    var buttonAlt = gui.widgets.Button.new(me._scroll_content, style, {}).setCheckable(1);
    middle_item.addItem(buttonAlt);
    buttonAlt.setText("Altitude");
    buttonAlt.setFixedSize(75,25);
    buttonAlt.listen("toggled", func (e)
    {
      if( !e.detail.checked ) {
        buttonAlt.setEnabled(1);
        return;
      }
      if( active_button != nil )
        active_button.setChecked(0);
      active_button = buttonAlt;
      buttonAlt.setEnabled(0);
      var altTrigger = nil;
      if (update_in_progress == 0) {
        altTrigger = compat_failure_modes.AltitudeTrigger.new(5000, 10000);
        FailureMgr.set_trigger(path, altTrigger);
      } else {
        altTrigger = failure_mode.trigger;
      }
      me._updateTriggerDescription(trigger_label, buttonFired, altTrigger);
      me._removeTriggerBox(triggerBox, bottom_item);
      triggerBox = me._triggerAltitudeBox(trigger_label, altTrigger, buttonFired, path);
      bottom_item.addItem(triggerBox[0]);
    });    
    if(failure_mode.trigger != nil and failure_mode.trigger.type == "altitude") {
      update_in_progress = 1;
      buttonAlt.setChecked(1);
      update_in_progress = 0;
    }
    #####################################
    ### Waypoint button #################
    var buttonWay = gui.widgets.Button.new(me._scroll_content, style, {}).setCheckable(1);
    middle_item.addItem(buttonWay);
    buttonWay.setText("Waypoint");
    buttonWay.setFixedSize(75,25);
    buttonWay.listen("toggled", func (e)
    {
      if( !e.detail.checked ) {
        buttonWay.setEnabled(1);
        return;
      }
      if( active_button != nil )
        active_button.setChecked(0);
      active_button = buttonWay;
      buttonWay.setEnabled(0);
      var wayTrigger = nil;
      if (update_in_progress == 0) {
        wayTrigger = compat_failure_modes.WaypointTrigger.new(0, 0, 1);
        FailureMgr.set_trigger(path, wayTrigger);
      } else {
        wayTrigger = failure_mode.trigger;
      }
      me._updateTriggerDescription(trigger_label, buttonFired, wayTrigger);
      me._removeTriggerBox(triggerBox, bottom_item);
      triggerBox = me._triggerWaypointBox(trigger_label, wayTrigger, buttonFired, path);
      bottom_item.addItem(triggerBox[0]);
    });    
    if(failure_mode.trigger != nil and failure_mode.trigger.type == "waypoint") {
      update_in_progress = 1;
      buttonWay.setChecked(1);
      update_in_progress = 0;
    }    
    #####################################    
    ### MCBF button #####################
    var buttonMCBF = nil;
    var mcbf_property = nil;
    var mcbf_cycles = nil;
    if(failure_mode.trigger != nil
      and failure_mode.trigger.type == "mcbf") {
      mcbf_property = failure_mode.trigger.counter._property;
      mcbf_cycles = failure_mode.trigger.params["mcbf"];
    } else {
      foreach(var compat_mode; compat_failure_modes.compat_modes) {
        if(compat_mode.id == path and compat_mode.type == compat_failure_modes.MCBF) {
          if (contains(compat_mode, "mcbf_prop")) {
            mcbf_property = compat_mode.mcbf_prop;
          } else {
            mcbf_property = compat_mode.id;
          }
          mcbf_cycles = 100;
        }
      }
    }

    if(mcbf_property != nil) {
      buttonMCBF = gui.widgets.Button.new(me._scroll_content, style, {}).setCheckable(1);
            
      middle_item.addItem(buttonMCBF);
      buttonMCBF.setText("MCBF");
      buttonMCBF.setFixedSize(75,25);

      buttonMCBF.listen("toggled", func (e)
      {
        if( !e.detail.checked) {
          buttonMCBF.setEnabled(1);
          return;
        }
        if( active_button != nil)
          active_button.setChecked(0);
        active_button = buttonMCBF;
        buttonMCBF.setEnabled(0);
        var mcbfTrigger = nil;
        if (update_in_progress == 0) {
          mcbfTrigger = compat_failure_modes.McbfTrigger.new(mcbf_property, mcbf_cycles);
          FailureMgr.set_trigger(path, mcbfTrigger);
        } else {
          mcbfTrigger = failure_mode.trigger;
        }
        me._updateTriggerDescription(trigger_label, buttonFired, mcbfTrigger);
        me._removeTriggerBox(triggerBox, bottom_item);
        triggerBox = me._triggerCyclesBox(trigger_label, mcbfTrigger, buttonFired, path, mcbf_property);
        bottom_item.addItem(triggerBox[0]);
      });
      if(failure_mode.trigger != nil and failure_mode.trigger.type == "mcbf") {
        update_in_progress = 1;
        buttonMCBF.setChecked(1);
        update_in_progress = 0;
      }
    }
    #######################################
    ### Custom button #####################
    var buttonCustom = nil;
    if(me._isTriggerCustom(failure_mode.trigger) == 1) {
      buttonCustom = gui.widgets.Button.new(me._scroll_content, style, {}).setCheckable(1);
      var customTrigger = failure_mode.trigger;
      middle_item.addItem(buttonCustom);
      buttonCustom.setText("Custom");
      buttonCustom.setFixedSize(75,25);
      buttonCustom.setChecked(1);
      active_button = buttonCustom;
      buttonCustom.setEnabled(0);
      buttonCustom.listen("toggled", func (e)
      {
        if( !e.detail.checked) {
          buttonCustom.setEnabled(1);
          return;
        }
        if( active_button != nil and active_button != buttonCustom)
          active_button.setChecked(0);
        active_button = buttonCustom;
        buttonCustom.setEnabled(0);
        if (update_in_progress == 0) {
          FailureMgr.set_trigger(path, customTrigger);
        }
        me._updateTriggerDescription(trigger_label, buttonFired, customTrigger);
        me._removeTriggerBox(triggerBox, bottom_item);
        triggerBox = nil;
      });
    }
    #####################################    
    ### None button #####################
    var buttonNone = gui.widgets.Button.new(me._scroll_content, style, {}).setCheckable(1);
    middle_item.addItem(buttonNone);
    buttonNone.setText("None");
    buttonNone.setFixedSize(75,25);
    if(failure_mode.trigger == nil) {
      buttonNone.setChecked(1);
      active_button = buttonNone;
      buttonNone.setEnabled(0);
    }
    buttonNone.listen("toggled", func (e)
    {
      if( !e.detail.checked) {
        buttonNone.setEnabled(1);
        return;
      }
      if( active_button != nil and active_button != buttonNone)
        active_button.setChecked(0);
      active_button = buttonNone;
      buttonNone.setEnabled(0);
      if (update_in_progress == 0) {
        FailureMgr.set_trigger(path, nil);
      }
      me._updateTriggerDescription(trigger_label, buttonFired, nil);
      me._removeTriggerBox(triggerBox, bottom_item);
      triggerBox = nil;
    });
    ###########################################
    middle_item.addStretch(1);


    ###########################################
    ### minus level button #####################
    var buttonLevelMinus = gui.widgets.Button.new(me._scroll_content, style, {})
                              .setText("+")
                              .setFixedSize(25, 15);
                              
    level_buttons_item.addItem(buttonLevelMinus);

    buttonLevelMinus.listen("clicked", func
    {

      # decrease level
      level -= 1; # 0.05; enable this in future when gradient lvl become supported
      if(level < 0) {
        level = 0;
      }
      FailureMgr.set_failure_level(path, level);
      level = failure_mode.mode.get_failure_level();
      if (level == 1) {
        # actuator does not support gradient levels yet, so actuators will not allow to decrease in small amounts
        # therefore we do a bigger step and go all the way to 0.
        level = 0;
      }
      me._setLevelColor(level, value_item);
      value_item.setText(sprintf("%03.1f", ((1-level)*100))~"%");
    });
    ###########################################
    ### plus level button #####################
    var buttonLevelPlus = gui.widgets.Button.new(me._scroll_content, style, {})
                              .setText("-")
                              .setFixedSize(25, 15);
    level_buttons_item.addItem(buttonLevelPlus);

    buttonLevelPlus.listen("clicked", func
    {
      # increase level
      level += 1; # 0.05;  enable this in future when gradient lvl become supported
      if(level > 1) {
        level = 1;
      }
      FailureMgr.set_failure_level(path, level);
      level = failure_mode.mode.get_failure_level();
      me._setLevelColor(level, value_item);
      value_item.setText(sprintf("%03.1f", ((1-level)*100))~"%");
    });
    #############################################
    ### repair level button #####################
    

    buttonLevelRepair.listen("clicked", func
    {

      level = 0;
      FailureMgr.set_failure_level(path, level);
      me._setLevelColor(level, value_item);
      value_item.setText(sprintf("%03.1f", ((1-level)*100))~"%");
    });
    ###########################################
    

    #################################
    ###  bottom (trigger details) ###
    #################################
    
    buttonFired.listen("clicked", func
    {
      if(failure_mode.trigger != nil) {
        if(failure_mode.trigger.armed == 0) {
          failure_mode.trigger.arm();
        } else {
          failure_mode.trigger.disarm();
        }
        me._updateButtonFired(buttonFired, failure_mode.trigger);
      }
    });


    bottom_item.insertItem(0, buttonFired);
    bottom_item.insertItem(1, trigger_label);
    me._updateButtonFired(buttonFired, failure_mode.trigger);

    #################################
    #################################
    # update the entry to failure mode changed from outside.
    var updateMe = func () {
      update_in_progress = 1;

      # refresh failure level label
      level = failure_mode.mode.get_failure_level();
      me._setLevelColor(level, value_item);
      value_item.setText(sprintf("%03.1f", ((1-level)*100))~"%");
      
      if(failure_mode.trigger == nil) {
        buttonNone.setChecked(0);
        buttonNone.setChecked(1);
      } elsif(failure_mode.trigger.type == "mcbf") {
        if (buttonMCBF != nil) {
          buttonMCBF.setChecked(0);
          buttonMCBF.setChecked(1);
        }
      } elsif(failure_mode.trigger.type == "altitude") {
        buttonAlt.setChecked(0);
        buttonAlt.setChecked(1);
      } elsif(failure_mode.trigger.type == "timeout") {
        buttonTime.setChecked(0);
        buttonTime.setChecked(1);
      } elsif(failure_mode.trigger.type == "mtbf") {
        buttonMTBF.setChecked(0);
        buttonMTBF.setChecked(1);
      } elsif(failure_mode.trigger.type == "waypoint") {
        buttonWay.setChecked(0);
        buttonWay.setChecked(1);        
      } elsif (buttonCustom != nil) {
        buttonCustom.setChecked(0);
        buttonCustom.setChecked(1);
      }

      update_in_progress = 0;
      }
      append(me._entryUpdateVector, updateMe);
    me._list.addItem(entry);
  }
};