#print("*** LOADING MissileView.nas ... ***");
var missile_view_handler = {
  init: func(node) {
    me.viewN = node;
    me.current = nil;
    me.legendN = props.globals.initNode("/sim/current-view/missile-view", "");
    me.dialog = props.Node.new({ "dialog-name": "missile-view" });
    me.listener = nil;
  },
  start: func {
    me.listener = setlistener("/sim/signals/ai-updated", func me._update_(), 1);
    me.reset();
    fgcommand("dialog-show", me.dialog);
  },
  stop: func {
    fgcommand("dialog-close", me.dialog);
    if (me.listener!=nil)
    {
      removelistener(me.listener);
      me.listener=nil;
    }
  },
  reset: func {
    me.select(0);
  },
  find: func(callsign) {
    forindex (var i; me.list)
      if (me.list[i].callsign == callsign)
        return i;
    return nil;
  },
  select: func(which, by_callsign=0) {
    if (by_callsign or num(which) == nil)
      which = me.find(which) or 0;  # turn callsign into index

    me.setup(me.list[which]);
  },
  next: func(step) {
    #ai.model.update();
    me._update_();
    var i = me.find(me.current);
    i = i == nil ? 0 : math.mod(i + step, size(me.list));
    me.setup(me.list[i]);
  },
  _update_: func {
    var self = { callsign: getprop("/sim/multiplay/callsign"), model:,
        node: props.globals, root: '/' };
    #ai.myModel.update();
    me.list = [self] ~ myModel.get_list();
    if (!me.find(me.current))
      me.select(0);
  },
  setup: func(data) {
    if (data.root == '/') {
      var zoffset = getprop("/sim/chase-distance-m");
      var ident = '[' ~ data.callsign ~ ']';
    } else {
      var zoffset = 70;
      #var ident = '"' ~ data.callsign ~ '" (' ~ data.model ~ ')';
      var ident = '"' ~ data.callsign ~ '"';
    }

    me.current = data.callsign;
    me.legendN.setValue(ident);
    setprop("/sim/current-view/z-offset-m", zoffset);
    setprop("/sim/current-view/heading-offset-deg", 110);
    setprop("/sim/current-view/pitch-offset-deg", 30);
    
    #print(me.current);

    me.viewN.getNode("config").setValues({
      "eye-lat-deg-path": data.root ~ "/position/latitude-deg",
      "eye-lon-deg-path": data.root ~ "/position/longitude-deg",
      "eye-alt-ft-path": data.root ~ "/position/altitude-ft",
      "eye-heading-deg-path": data.root ~ "/orientation/true-heading-deg",
      "target-lat-deg-path": data.root ~ "/position/latitude-deg",
      "target-lon-deg-path": data.root ~ "/position/longitude-deg",
      "target-alt-ft-path": data.root ~ "/position/altitude-ft",
      "target-heading-deg-path": data.root ~ "/orientation/true-heading-deg",
      "target-pitch-deg-path": data.root ~ "/orientation/pitch-deg",
      "target-roll-deg-path": data.root ~ "/orientation/roll-deg",
      "heading-offset-deg":180
    });
  },
};

var myModel = ai.AImodel.new();
myModel.init();

view.manager.register("Missile View",missile_view_handler);


var view_firing_missile = func(myMissile)
{

    # We select the missile name
    var myMissileName = string.replace(myMissile.ai.getPath(), "/ai/models/", "");

    # We memorize the initial view number
    var actualView = getprop("/sim/current-view/view-number");

    # We recreate the data vector to feed the missile_view_handler  
    var data = { node: myMissile.ai, callsign: myMissileName, root: myMissile.ai.getPath()};

    # We activate the AI view (on this aircraft it is the number 8)
    setprop("/sim/current-view/view-number",8);

    # We feed the handler
    view.missile_view_handler.setup(data);
}
