print("*** LOADING AI_list.nas ... ***");
# Autonomous singleton class that monitors AI object,
# maintains data in various structures, and raises signal
# "/sim/signals/ai-updated" whenever an aircraft
# joined or left. Available data containers are:
#
#   ai.AImodel.data:        hash, key := /ai/models/~ path
#   ai.AImodel.callsign     hash, key := callsign
#   ai.AImodel.list         vector, sorted alphabetically (ASCII, case insensitive)
#
# All of them contain hash entries of this form:
#
# {
#    callsign: "BiMaus", or 5H1N0B1 ;)
#    root: "/ai/models/multiplayer[4]",            # root property
#    node: {...},        # root property as props.Node hash
#    sort: "bimaus",     # callsign in lower case (for sorting)
# }

var AImodel = {
    new: func() {
        var m = { parents: [AImodel] };
        m.data = {};
        m.callsign = {};
        m.list = {};
        
        # return our new object
        return m;
    },

    init: func() {
        #me.L = [];
        #append(me.L, setlistener("ai/models/model-added", func(n) {
            # Defer update() to the next convenient time to allow the
            # new MP entry to become fully initialized.
            #settimer(func me.update(), 0);
        #}));
        #append(me.L, setlistener("ai/models/model-removed", func(n) {
            # Defer update() to the next convenient time to allow the
            # old MP entry to become fully deactivated.
            #settimer(func me.update(), 0);
        #}));
        me.update();
    },
    update: func(n = nil) {
        var changedNode = props.globals.getNode(n, 1);
        me.data = {};
        me.callsign = {};
        #print("UPDATE AI LIST");
        foreach(var n ; props.globals.getNode("ai/models", 1).getChildren())
        {
            #print(n.getName());
            
            if((var valid = n.getNode("valid")) == nil or (!valid.getValue()))
            {
                continue;
            }
            var myName = string.replace(n.getPath(), "/ai/models/", "");
            #print( string.replace(n.getPath(),"/ai/models/",""));

            var root = n.getPath();

            var data = {
                node: n,
                callsign: myName,
                root: root,
                sort: string.lc(myName)
            };
            me.data[root] = data;
            me.callsign[myName] = data;
        }
        #print(size(me.data));
        me.list = sort(values(me.data), func(a, b) cmp(a.sort, b.sort));
        
        if(size(me.data) > 0)
        {
            #print(me.list[1]);
            setprop("ai/models/num-ai", size(me.list));
            setprop("sim/signals/ai-updated", 1);
        }
        settimer(func(){ me.update() }, 0.5);
    },
    get_list: func(){
        return me.list;
    },

    remove_suffix: func(s, x) {
        var len = size(x);
        if(substr(s, -len) == x)
        {
            return substr(s, 0, size(s) - len);
        }
        return s;
    },
};
