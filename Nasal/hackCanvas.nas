#
# Author: Nikolai V. Chr.
#
# Backwards compatible with older Fgs.
# Notice all these methods return me so they can be chained.
#
# This file should be loaded before any canvas use.
#
# Result: On Viggen get 25% more FPS. From 12 to 15.
#
# Inspired from what Thorsten did with setTextUpdate()
#
# Notice: Might not be forward compatible.

if(getprop("sim/version/flightgear")=="3.2.0") {
    setprop("old",1);
}

canvas.Text._lastText = canvas.Text["_lastText"];
canvas.Text.setText = func (text)
  {
      if (text == me._lastText) {return me;}
      me._lastText = text;
      me.set("text", typeof(text) == 'scalar' ? text : "");
  };
canvas.Element._lastVisible = nil;
canvas.Element.show = func ()
  {
      if (1 == me._lastVisible) {return me;}
      me._lastVisible = 1;
      me.setBool("visible", 1);
    };
canvas.Element.hide = func ()
  {
      if (0 == me._lastVisible) {return me;}
      me._lastVisible = 0;
      me.setBool("visible", 0);
};
canvas.Element.setVisible = func (vis) {
      if (vis == me._lastVisible) {return me;}
      me._lastVisible = vis;
      me.setBool("visible", vis);
};