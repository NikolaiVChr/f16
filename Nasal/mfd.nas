# Generic Page switching cockpit display device.
# ---------------------------
# Richard Harrison: 2015-10-17 : rjh@zaretto.com
# ---------------------------
# I'm calling this a PFD as in Programmable Function Display.
# ---------------------------
# documentation: see http://wiki.flightgear.org/Canvas_MFD_Framework
# See FGAddon/Aircraft/F-15/Nasal/MPCD/MPCD_main.nas for an example usage
# ---------------------------
# This is but a straightforwards wrapper to provide the core logic that page switching displays require.
# Examples of Page switching displays
# * MFD
# * PFD
# * FMCS
# * F-15 MPCD

#
# Menu Item. There is a list of these for each page changing button per display page
# Parameters:
# menu_id   : page change event id for this menu item. e.g. button number
# title      : Title Text (for display on the device)
# page       : Instance of page usually returned from PFD.addPage
# callbackfn : Function to call when menu item is selected
# displayfn  : Function to call when the menu item is displayed.  Used to enable
#              highlighting of menu items, for example.
var PFD_MenuItem =
{
    new : func (menu_id, title, page, callbackfn=nil, displayfn=nil)
    {
        var obj = {parents : [PFD_MenuItem] };
        obj.page = page;
        obj.menu_id = menu_id;
        obj.callbackfn = callbackfn;
        obj.displayfn = displayfn;
        obj.title = title;
        return obj;
    },
        };

#
#
# Create a new PFD Page
# - related svg
# - Title: Page title
# - SVG element for the page
# - Device to attach the page to

var PFD_Page =
{
    new : func (svg, title, layer_id, device)
    {
        var obj = {parents : [PFD_Page] };
        obj.title = title;
        obj.device = device;
        obj.layer_id = layer_id;
        obj.menus = [];
        obj.svg = svg.getElementById(layer_id);
        if(obj.svg == nil)
            printf("PFD_Device: Error loading %s: svg layer %s ",title, layer_id);

        return obj;
    },

    #
    # Makes a page visible.
    # It is the responsibility of the caller to manage the visibility of pages - i.e. to
    # make a page that is currenty visible not visible before making a new page visible,
    # however more than one page could be visible - but only one set of menu buttons can be active
    # so if two pages are visible (e.g. an overlay) then when the overlay removed it would be necessary
    # to call setVisible on the base page to ensure that the menus are setup
    setVisible : func(vis)
    {
        if(me.svg != nil)
            me.svg.setVisible(vis);

        if (vis)
            me.ondisplay();
        else
            me.offdisplay();
    },

    # Standard callback for buttons, causing the appropriate page to be displayed
    std_callbackfn : func (device, me, mi)
    {
      device.selectPage(mi.page);
    },

    # Standard display function for buttons, displaying the text and making visible
    std_displayfn : func(svg_element, menuitem)
    {
      svg_element.setText(menuitem.title);
      svg_element.setVisible(1);
      #me.buttons[mi.menu_id].setText(mi.title);
      #me.buttons[mi.menu_id].setVisible(1);
    },

    #
    # Perform action when button is pushed
    notifyButton : func(button_id)
    {        foreach(var mi; me.menus)
             {
                 if (mi.menu_id == button_id)
                 {
                     if (mi.callbackfn != nil) mi.callbackfn(me.device, me, mi);
                     break;
                 }
             }
    },

    #
    # Add an item to a menu
    # Params:
    #  menu button id (that is set in controls/PFD/button-pressed by the model)
    #  title of the menu for the label
    #  page that will be selected when pressed
    #
    # The corresponding menu for the selected page will automatically be loaded
    addMenuItem : func(menu_id, title, page, callbackfn=nil, displayfn=nil)
    {
        if (callbackfn == nil) callbackfn = me.std_callbackfn;
        if (displayfn == nil) displayfn = me.std_displayfn;
        var nm = PFD_MenuItem.new(menu_id, title, page, callbackfn, displayfn);
        append(me.menus, nm);
        return nm;
    },

    #
    # Clear all items from the menu.  Use-case is where they may be a hierarchy
    # of menus within the same page.
    #
    clearMenu : func()
    {
      me.menus = [];
    },

    # base method for update; this can be overridden per page instance to provide update of the
    # elements on display (e.g. to display updated properties)
    update : func(notification=nil)
    {
    },

    #
    # notify the page that it is being displayed. use to load any static framework or perform one
    # time initialisation
    ondisplay : func
    {
    },

    #
    # notify the page that it is going off display; use to clean up any created elements or perform
    # any other required functions
    offdisplay : func
    {
    },
};


#
# Container device for pages.
var PFD_Device =
{
# - svg is the page elements from the svg.
# - num_menu_buttons is the Number of menu buttons; starting from the bottom left then right, then top, then left.
# - button prefix (e.g MI_) is the prefix of the labels in the SVG for the menu boxes.
# - _canvas is the canvas group.
# - designation (optional) is used for Emesary designation
#NOTE:
# This does not actually create the canvas elements, or parse the SVG, that would typically be done in
# a higher level class that contains an instance of this class.
# see: http://wiki.flightgear.org/Canvas_MFD_Framework
    new : func(svg, num_menu_buttons, button_prefix, _canvas, designation="MFD")
    {
        var obj = {parents : [PFD_Device] };
        obj.svg = svg;
        obj.canvas = _canvas;
        obj.current_page = nil;
        obj.pages = [];
        obj.page_index = {};
        obj.buttons = setsize([], num_menu_buttons);
        obj.transmitter = nil;

        # change after creation if required
        obj.device_id = 1;
        obj.designation = designation;

        for(var idx = 0; idx < num_menu_buttons; idx += 1)
        {
            var label_name = sprintf(button_prefix~"%d",idx);
            var msvg = obj.svg.getElementById(label_name);
            if (msvg == nil)
                printf("PFD_Device: Failed to load  %s",label_name);
            else
            {
                obj.buttons[idx] = msvg;
                obj.buttons[idx].setText(sprintf("M%d",idx));
            }
        }
        obj.Recipient = nil;
        return obj;
    },
    #
    # instead of using the direct call method this allows the use of Emesary (via a specified or default global transmitter)
    # example to notify that a softkey has been used. The "1" in the line below is the device ID
    # var notification = notifications.PFDEventNotification.new(me.designation, me.DeviceId, notifications.PFDEventNotification.SoftKeyPushed, me.mpcd_button_pushed);
    # emesary.GlobalTransmitter.NotifyAll(notification);
    # - currently supported is
    # 1. setting menu text directly (after page has been loaded)
    #    notifications.PFDEventNotification.new(me.designation, 1, notifications.PFDEventNotification.ChangeMenuText, [{ Id: 1, Text: "NNN"}]);
    # 2. SoftKey selection.
    #
    # the device ID must match this device ID (to allow for multiple devices).
    RegisterWithEmesary : func(transmitter = nil){
        if (transmitter == nil)
          transmitter = emesary.GlobalTransmitter;

        if (me.Recipient == nil){
            me.Recipient = emesary.Recipient.new("PFD_"~me.designation);
            var pfd_obj = me;
            me.Recipient.Receive = func(notification)
              {
                  if (notification.Device_Id == pfd_obj.device_id
                      and notification.NotificationType == notifications.PFDEventNotification.DefaultType) {
                      if (notification.Event_Id == notifications.PFDEventNotification.SoftKeyPushed
                          and notification.EventParameter != nil)
                        {
                            #printf("Button pressed " ~ notification.EventParameter);
                            pfd_obj.notifyButton(notification.EventParameter);
                        }
                      else if (notification.Event_Id == notifications.PFDEventNotification.ChangeMenuText
                          and notification.EventParameter != nil)
                        {
                            foreach(var eventMenu; notification.EventParameter) {
                                #printf("Menu Text changed : " ~ eventMenu.Text);
                                foreach (var mi ; pfd_obj.current_page.menus) {
                                    if (pfd_obj.buttons[eventMenu.Id] != nil) {
                                        pfd_obj.buttons[eventMenu.Id].setText(eventMenu.Text);
                                    }
                                    else
                                      printf("PFD_device: Menu for button not found. Menu ID '%s'",mi.menu_id);
                                }
                            }
                        }
                      return emesary.Transmitter.ReceiptStatus_OK;
                  }
                  return emesary.Transmitter.ReceiptStatus_NotProcessed;
              };
            transmitter.Register(me.Recipient);
            me.transmitter = transmitter;
        }
    },
    DeRegisterWithEmesary : func(transmitter = nil){
        # remove registration from transmitter; but keep the recipient once it is created.
        if (me.transmitter != nil)
          me.transmitter.DeRegister(me.Recipient);
        me.transmitter = nil;
    },
    #
    # called when a button is pushed - connecting the property to this method is implemented in the outer class
    notifyButton : func(button_id)
    {
        #
        # by convention the buttons we have are 0 based; however externally 0 is used
        # to indicate no button pushed.
        if (button_id > 0)
        {
            button_id = button_id - 1;
            if (me.current_page != nil)
            {
                me.current_page.notifyButton(button_id);
                if(button_id==19 and getprop("f16/stores/tgp-mounted") and !getprop("gear/gear/wow")) {
                    screen.log.write("Click BACK to get back to cockpit view",1,1,1);
                    setprop("sim/current-view/view-number",12);
                }

            }
            else
                printf("PFD_Device: Could not locate page for button ",button_id);
        }
    },
    #
    #
    # add a page to the device.
    # - page title.
    # - svg element id
    addPage : func(title, layer_id)
    {
        var np = PFD_Page.new(me.svg, title, layer_id, me);
        append(me.pages, np);
        me.page_index[layer_id] = np;
        np.setVisible(0);
        return np;
    },
    #
    # Get a named page
    #
    getPage : func(title)
    {
      foreach(var p; me.pages) {
        if (p.title == title) return p;
      }

      return nil;
    },
    #
    # manage the update of the currently selected page
    update : func(notification=nil)
    {
        if (me.current_page != nil)
            me.current_page.update(notification);
    },
    #
    # Change to display the selected page.
    # - the page object method controls the visibility
    selectPage : func(p)
    {
        if (p==nil) {return;}
        if (me.current_page == p) return;

        if (me.current_page != nil)
            me.current_page.setVisible(0);
        if (me.buttons != nil)
        {
            foreach(var mb ; me.buttons)
                if (mb != nil)
                    mb.setVisible(0);

            foreach(var mi ; p.menus)
            {
                if (me.buttons[mi.menu_id] != nil)
                {
                  mi.displayfn(me.buttons[mi.menu_id], mi);
                }
                else
                    printf("PFD_device: Menu for button not found. Menu ID '%s'",mi.menu_id);
            }
        }
        p.setVisible(1);
        me.current_page = p;
    },

    # Return the current selected page.
    getCurrentPage : func()
    {
      return me.current_page;
    },

    #
    # ensure that the menus are display correctly for the current page.
    updateMenus : func
    {
        foreach(var mb ; me.buttons)
          if (mb != nil)
            mb.setVisible(0);

        if (me.current_page == nil) return;

        foreach(var mi ; me.current_page.menus)
        {
            if (me.buttons[mi.menu_id] != nil)
            {
                mi.displayfn(me.buttons[mi.menu_id], mi);
            }
            else
                printf("No corresponding item '%s'",mi.menu_id);
        }
    },
};

var PFD_NavDisplay =
{
#
# Instantiate parameters:
# 1. pfd_device (instance of PFD_Device)
# 2. instrument display ident (e.g. mfd-map, or mfd-map-left mfd-map-right for multiple displays)
#    (this is used to map to the property tree)
# 3. layer_id: main layer  in the SVG
# 4. nd_group_ident : group (usually within the main layer) to place the NavDisplay
# 5. switches - used to connect the property tree to the nav display. see the canvas nav display
#    documentation
    new : func (pfd_device, title, instrument_ident, layer_id, nd_group_ident, switches=nil, map_style="Boeing")
    {
        var obj = pfd_device.addPage(title, layer_id);

        # if no switches given then use a default set.
        if (switches != nil)
            obj.switches = switches;
        else
            obj.switches = {
                'toggle_range':         { path: '/inputs/range-nm',    value: 40,    type: 'INT' },
                'toggle_weather':       { path: '/inputs/wxr',         value: 0,     type: 'BOOL' },
                'toggle_airports':      { path: '/inputs/arpt',        value: 1,     type: 'BOOL' },
                'toggle_stations':      { path: '/inputs/sta',         value: 0,     type: 'BOOL' },
                'toggle_waypoints':     { path: '/inputs/wpt',         value: 0,     type: 'BOOL' },
                'toggle_position':      { path: '/inputs/pos',         value: 0,     type: 'BOOL' },
                'toggle_data':          { path: '/inputs/data',        value: 1,     type: 'BOOL' },
                'toggle_terrain':       { path: '/inputs/terr',        value: 0,     type: 'BOOL' },
                'toggle_traffic':       { path: '/inputs/tfc',         value: 0,     type: 'BOOL' },
                'toggle_centered':      { path: '/inputs/nd-centered', value: 1,     type: 'BOOL' },
                'toggle_lh_vor_adf':    { path: '/inputs/lh-vor-adf',  value: 1,     type: 'INT' },
                'toggle_rh_vor_adf':    { path: '/inputs/rh-vor-adf',  value: 1,     type: 'INT' },
                'toggle_display_mode':  { path: '/mfd/display-mode',   value: 'MAP', type: 'STRING' },
                'toggle_display_type':  { path: '/mfd/display-type',   value: 'LCD', type: 'STRING' },
                'toggle_true_north':    { path: '/mfd/true-north',     value: 0,     type: 'BOOL' },
                'toggle_rangearc':      { path: '/mfd/rangearc',       value: 0,     type: 'BOOL' },
                'toggle_track_heading': { path: '/hdg-trk-selected',   value: 1,     type: 'BOOL' },
            };

        obj.nd_initialised = 0;
        obj.nd_placeholder_ident = nd_group_ident;
        obj.nd_ident = instrument_ident;
        obj.pfd_device = pfd_device;

        obj.nd_init = func
        {
            me.ND = canvas.NavDisplay;
            if (!me.nd_initialised)
            {
                me.nd_initialised = 1;

                me.NDCpt = me.ND.new("instrumentation/"~me.nd_ident, me.switches,map_style);

                me.group = me.pfd_device.svg.getElementById(me.nd_placeholder_ident);
                me.group.setScale(0.39,0.45);
                me.group.setTranslation(45,0);
                call(me.NDCpt.newMFD, [me.group, pfd_device.canvas], me.NDCpt,me.NDCpt,var err = []);
                if (size(err)>0) {
                    print(err[0]);
                }
            }
            me.NDCpt.windShown = 0;
            me.NDCpt.update();
        };
        #
        # Method overrides
        #-----------------------------------------------
        # Called when the page goes on display - need to delay initialization of the NavDisplay until later (it fails
        # if done too early).
        # NOTE: This causes a display "wobble" the first time on display as resizing happens. I've seen similar things
        #       happen on real avionics (when switched on) so it's not necessarily unrealistic -)
        obj.ondisplay = func
        {
            if (!me.nd_initialised)
                me.nd_init();
            #2018.2 - manage the timer so that the nav display is only updated when visibile
            me.NDCpt.onDisplay();
        };
        obj.offdisplay = func
        {
            #2018.2 - manage the timer so that the nav display is only updated when visibile
            if (me.nd_initialised)
              me.NDCpt.offDisplay();
        };
        #
        # most updates performed by the canvas nav display directly.
        obj.update = func
        {
        };
        return obj;
    },
};
