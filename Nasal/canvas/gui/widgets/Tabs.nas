# A panel tabs widget
#
# Contributors: Nikolai V. Chr. (Necolatis)
#
gui.widgets.Tabs = {
  new: func(parent, style, cfg)
  {
    var m = gui.Widget.new(gui.widgets.Tabs);

    m._cfg = Config.new(cfg);
    m._focus_policy = m.NoFocus;

    var w = {
      parents: [TabsFactory],
      _style: style,
    };
    call(TabsFactory.new, [parent, m._cfg], w, var err = []);

    if(size(err)) {
      foreach(var error; err) {
        print(error);
      }
    }

    m._setView(w);

    return m;
  },

  # should button widths be uniform?
  # should each tab have an id?
  addTab: func(layoutItem, title, buttonSize) {
    me._view.addTab(layoutItem, title, buttonSize);
  },

  selectTab: func(title) {
    me._view.selectTab(title);
  }
};

TabsFactory = {
  new: func(parent, cfg)
  {
    me._root = parent.createChild("group", "tab-panel");

    me._vbox = VBoxLayout.new();
    me._vbox.setCanvas(me._root.getCanvas());                           #hack 1

    me._tab_bar = HBoxLayout.new();
    me._tab_bar.addStretch(1);
    me._tab_bar.addStretch(1);

    me._vbox.addItem(me._tab_bar);

    me._tabs = [];
    return me;
  },

  addTab: func(layoutItem, title, buttonSize) {
    var tab_button = gui.widgets.Button.new(me._root, me._style, {})
                                    .setCheckable(1)
                                    .setChecked(0)
                                    .setFixedSize(buttonSize,25)
                                    .setText(title);
    
    tab_button.listen("toggled", func (e) {
      if( e.detail.checked ) {
        me.selectTab(title);
      }
    });

    me._tab_bar.insertItem(me._tab_bar.count()-1, tab_button, 0);
    me._vbox.addItem(layoutItem, 1);
    append(me._tabs, {ident: title, panel: layoutItem, button: tab_button});
    if(size(me._tabs) == 1) {
      tab_button.setChecked(1);
    } else {
      layoutItem.setVisible(0);
    }
  },

  selectTab: func (title) {
    foreach(var tab; me._tabs) {
      if(tab.ident == title) {
        tab.panel.setVisible(1);
      } else {
        tab.button.setChecked(0);
        tab.panel.setVisible(0);
      }
    }
  },

  setSize: func(model, w, h)
  {
    me._vbox.setGeometry([0,0,w,h]);
    return me;
  },

  update: func(model)
  {
    if(me._vbox.getParent() == nil) {
      me._vbox.setParent(model);                      #hack 2
    }
    
    me._root.update();
  },  
};