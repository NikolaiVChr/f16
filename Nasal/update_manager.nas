 #---------------------------------------------------------------------------
 #
 #	Title                : Property / object update manager
 #
 #	File Type            : Implementation File
 #
 #	Description          : Manage updates when a value has changed more than a predetermined amount.
 #
 #	Author               : Richard Harrison (richard@zaretto.com)
 #
 #	Creation Date        : 14 Juillet 2016
 #
 #	Version              : 1.0
 #
 #  Copyright (C) 2016 Richard Harrison           Released under GPL V2
 #
 #---------------------------------------------------------------------------*/

var PropertyUpdateManager =
{
    new : func(_propname, _delta, _changed_method)
    {
        var obj = {parents : [PropertyUpdateManager] };
        obj.propname = _propname;
        obj.delta = _delta;
        obj.curval = getprop(obj.propname);
        obj.lastval = obj.curval;
        obj.changed = _changed_method;
        obj.update = func(obj)
        {
            me.curval = getprop(me.propname);
            if (me.curval != nil)
            {
                if(me.lastval == nil or math.abs(me.lastval - me.curval) > me.delta)
                {
                    me.lastval = me.curval;
                    me.changed(me.curval);
                }
            }
        };
        obj.update();
        return obj;
    },
    newFromHashValue : func(_key, _delta, _changed_method)
    {
        var obj = {parents : [PropertyUpdateManager] };
        obj.hashkey = _key;
        obj.delta = _delta;
        obj.curval = nil;
        obj.lastval = nil;
        obj.changed = _changed_method;
        obj.update = func(obj)
        {
            me.curval = obj[me.hashkey];
            if (me.curval != nil)
            {
                if(me.lastval == nil or math.abs(me.lastval - me.curval) > me.delta)
                {
                    me.lastval = me.curval;
                    me.changed(me.curval);
                }
            }
        };
        return obj;
    },
};
