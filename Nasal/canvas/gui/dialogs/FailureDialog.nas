# A failure panel dialog
#
# Contributors: Nikolai V. Chr. (Necolatis)
#
var FailureDialog = {
  new: func
  {
    var m = {
      parents: [FailureDialog],
      _dialog: canvas.Window.new([600,500], "dialog")
                         .set("title", "Failure Manager")
                         .set("resize", 1),
    };

    m._dialog.getCanvas(1)
          .set("background", canvas.style.getColor("bg_color"));
    m._root = m._dialog.getCanvas().createGroup();

    m._vbox = HBoxLayout.new();
    m._dialog.setLayout(m._vbox);
    
    #io.include("Nasal/canvas/gui/widgets/Failure.nas"); #is now loaded inside gui.nas

    m._panel = gui.widgets.Failure.new(m._root, style, {});
    m._vbox.addItem(m._panel);

    return m;
  },
};

FailureDialog.new();

#MessageBox.warning(
#  "Experimental Feature...",
#  "The Failure Dialog is only a preview and not yet in a stable state!",
#  func(sel)
#  {
#    if( sel != MessageBox.Ok )
#      return;
#
#    var fd = FailureDialog.new();
#  },
#  MessageBox.Ok | MessageBox.Cancel | MessageBox.DontShowAgain
#);