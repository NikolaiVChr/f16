##
# Nasal Namespace Browsing window using Canvas.
# Debug -> Nasal Namespace Browser
#


var _dbg_level = "debug";

# N.B. copied from nextgen.nas, should be removed
# when gen is added to FG_ROOT/Nasal
var keycmp = func(a,b) {
    if (num(a) == nil)
        if (num(b) == nil) cmp(a,b);
        else 1;
    else
        if (num(b) == nil) -1;
        else a-b;
};
var denied_symbols = [
    "", "func", "if", "else", "var",
    "elsif", "foreach", "for",
    "forindex", "while", "nil",
    "return", "break", "continue",
];
var issym = func(string) {
    foreach (var d; denied_symbols)
        if (string == d) return 0;
    var sz = size(string);
    var s = string[0];
    if ((s < `a` or s > `z`) and
        (s < `A` or s > `Z`) and
        (s != `_`)) return 0;
    for (var i=1; i<sz; i+=1)
        if (((s=string[i]) != `_`) and
            (s < `a` or s > `z`) and
            (s < `A` or s > `Z`) and
            (s < `0` or s > `9`)) return 0;
    return 1;
};
var internsymbol = func(symbol) {
    assert("argument not a symbol", issym, symbol);
    var get_interned = compile("""
        keys({"~symbol~":})[0]
    """);
    return get_interned();
};
var isinterned = func(symbol)
    return (id(symbol) == id(internsymbol(symbol)));
var role = func(a) {
    if (num(a) == nil) {
        if (issym(a) and isinterned(a)) return 'symbol';
        else return 'string';
    } else {
        return (call(id, [a], []) == nil ? 'number' : 'string');
    }
};

# For displaying a key based on its role()
var actions = {
	'symbol': func(k) k,
	'string': func(k) debug.string(k, 0),
	'number': func(k) k,
};

var __display_error = 1;

var typeval = {
	'hash':   0,
	'vector': 1,
	'func':   2,
	'scalar': 3,
	'ghost':  4,
	'nil':    5,
};
var reduce = func(v,f) {
	var ret = [];
	foreach (var i; v)
		append(ret, f(i));
	return ret;
}

var CanvasBrowser = {
	instances: [],
	current_instance: nil,
	keys: [
		"ESC",         "Exit/close this dialog",
		"Ctrl-d",      "Same as ESC",
		"Ctrl-v",      "Insert text (at the end of the current line)",
		"Ctrl-c",      "Copy the current line of text",
		"Ctrl-x",      "Copy and delete the current line of text",
		"Up",          "Previous line in history",
		"Down",        "Next line in history",
		"Left",         nil,
		"Right",        nil,
		"Shift+Left",   nil,
		"Shift+Right",  nil,
	],
	translations: {
		"bad-result": "[Error: cannot display output]",
		"key-not-mapped": "[Not Implemented]",
		"help": "Welcome to the Nasal REPL Interpreter. Press any key to "
		        "exit this message, ESC to exit the dialog (at any time "
		        "afterwards), and type away to test code :).\n\nNote: "
		        "this dialog will capture nearly all key-presses, so don't "
		        "try to fly with the keyboard while this is open!"
		        "\n\nImportant keys:",
	},
	styles: {
		"canvas-default": {
			size: [450, 500],
			separate_lines: 1,
			window_style: "default",
			padding: 5,
			max_output_chars: 87,
			colors: {
				text: [0.8,0.86,0.8],
				text_fill: nil,
				background: [0.8,0.83,0.83],
				error: [1,0.2,0.1],
				types: {
					'scalar': [0.4,0.0,0.6],
					'func':   [0.0,0.0,0.5],
					'hash':   [0.9,0.0,0.1],
					'vector': [0.0,0.7,0.0],
					'ghost':  [1.0,0.3,0.0],
					'nil':    [0.2,0.2,0.2],
				},
				string_factor: 0.7, # for non-interned, non-number keys the color is reduced
			},
			alignment: "left-baseline",
			line_height: 1.25,
			font_size: 14,
			#font_file: "LiberationFonts/LiberationMono-Regular.ttf",
			font_file: "LiberationFonts/LiberationSans-Regular.ttf",
			font_aspect_ratio: 1,
			font_max_width: nil,
			update_time: 0.6,
			#font_max_width: 588,
		},
	},
	new: func(name="<canvas-repl>", style="canvas-default") {
		if (typeof(style) == 'scalar') {
			style = CanvasBrowser.styles[style];
		}
		if (typeof(style) != 'hash') die("bad style");
		var m = {
			parents: [CanvasBrowser, style],
			name: name,
			listeners: [], timer: nil,
			window: canvas.Window.new(style.size, style.window_style, "Nasal-browser-"~name),
			root: globals, scroll: 0,
			history: [], edit_msg: "[shift+click to edit]",
			editing: nil, edit_pad: nil,
			last: nil, children: [],
			items: {},
			sub_window: nil,
			cmp: CanvasBrowser.cmp_name,
			fn_arg_cache: nil,
			display_func_args: 0,
		};
		m.window.set("title", "Nasal Namespace Browser");
		#debug.dump(m.window._node);
		m.window.del = func() {
			delete(me, "del");
			me.del(); # inherited canvas.Window.del();
			m.window = nil;
			m.del();
		};
		if (m.window_style != nil) m.window.setBool("resize", 1);
		m.canvas = m.window.createCanvas()
		                   .setColorBackground(m.colors.background);
		m.root_el = m.canvas.createGroup("content");
		m.vbox = canvas.VBoxLayout.new();
		m.window.setLayout(m.vbox);
		m.tab_bar = canvas.HBoxLayout.new();
		m.vbox.addItem(m.tab_bar);


		m.back = canvas.gui.widgets
		        .Button.new(m.root_el, canvas.style, {})
		               .setText("Back").setEnabled(0);
		m.back.listen("clicked", func(e) {
			if (!size(m.history)) return;
			m.root = pop(m.history);
			m.scroll.scrollTo(0,0);
			m.editing = nil;
			m.update();
		});
		m.tab_bar.addItem(m.back);
		m.refresh = canvas.gui.widgets
		           .Button.new(m.root_el, canvas.style, {})
		                  .setText("Refresh");
		m.refresh.listen("clicked", func m.update());
		m.tab_bar.addItem(m.refresh);
		m.options = canvas.gui.widgets
		           .Button.new(m.root_el, canvas.style, {})
		                  .setText("Options");
		m.options.listen("clicked", func m.open_options());
		m.tab_bar.addItem(m.options);
		m.timing = canvas.gui.widgets
		          .Label.new(m.root_el, canvas.style, {})
		                .setText("Time taken to refresh: xxxms");
		m.tab_bar.addItem(m.timing);
		m.tab_bar.addStretch(1);

		m.scroll = canvas.gui.widgets
		          .ScrollArea.new(m.root_el, canvas.style, {});
		m.scroll.setColorBackground(m.colors.background);
		m.vbox.addItem(m.scroll, 1);
		m.group = m.scroll.getContent();
		m.body = m.group;

		m.editing_node = canvas.gui.widgets.Label.new(m.root_el, canvas.style, {})
			.setText(m.edit_msg);
		m.vbox.addItem(m.editing_node);
		# XXX: keyboard hack, needs proper GUI-integrated design
		append(m.listeners, setlistener("/devices/status/keyboard/event", func(event) {
			if (!event.getNode("pressed").getValue())
				return;
			var key = (var keyN = event.getNode("key", 1)).getValue();
			if (key == nil or key == -1) return;
			if (m.handle_key(key, event.getNode("modifier").getValues()))
				keyN.setValue(-1);           # drop key event
		}));
		if (m.update_time != nil)
		{ m.timer = maketimer(m.update_time, m, m.update); m.timer.start() }
		m.searcher = geo.PositionedSearch.new(me.get_children, me.onAdded, me.onRemoved, m);
		m.searcher._equals = func(a,b) a.id == b.id;
		m.update();
		append(CanvasBrowser.instances, m);
		return m;
	},
	del: func() {
		if (me.sub_window != nil)
		{ me.sub_window.del(); me.sub_window = nil }
		if (me.window != nil)
		{ me.window.del(); me.window = nil }
		if (me.timer != nil)
		{ me.timer.stop(); me.timer = nil }
		foreach (var l; me.listeners)
			removelistener(l);
		setsize(me.listeners, 0);
		forindex (var i; CanvasBrowser.instances)
			if (CanvasBrowser.instances[i] == me) {
				CanvasBrowser.instances[i] = CanvasBrowser.instances[-1];
				pop(CanvasBrowser.instances);
				break;
			}
		return nil;
	},
	cmp_name: func(a,b) keycmp(a.id, b.id),
	cmp_type_name: func(a,b) {
		keycmp(typeval[typeof(a.value)], typeval[typeof(b.value)])
		 or keycmp(a.id, b.id)
	},
	_childbykey: func(k) {
		return {
			id: k, value: me.root[k], parent: me.root,
		};
	},
	get_children: func() {
		me.children = [];
		var has_arg = 0;
		if (typeof(me.root) == 'hash') {
			foreach (var k; keys(me.root))
				if ((!has_arg or k != "arg") and k != "__gcsave") {
					append(me.children, me._childbykey(k));
					if (k == "arg") has_arg = 1;
				}
		} elsif (typeof(me.root) == 'vector') {
			forindex (var k; me.root)
				append(me.children, me._childbykey(k));
			#debug.dump(me.children);
		}
		return me.children = sort(me.children, me.cmp);
	},
	color: func(child) {
		var ret = me.colors.types[typeof(child.value)];
		if (role(child.id)=='string'
		    and me.colors.string_factor != nil
		    and me.colors.string_factor != 1)
			forindex (var i; ret~=[]) # copy color
				ret[i] = math.min(1, me.colors.string_factor*ret[i]);
		return ret;
	},
	onAdded: func(child) {
		var el = me.body.createChild("text", "key "~child.id)
			.setAlignment(me.alignment)
			.setFontSize(me.font_size, me.font_aspect_ratio)
			.setFont(me.font_file)
			.setDouble("line-height", me.line_height);
		el.addEventListener("click", func(e) {
			delete(caller(0)[0], "me"); # just in case
			var child = me.latest_child(child);
			me.move_root(child, e.shiftKey);
		});
		me.items[child.id] = el;
	},
	onRemoved: func(child) me.items[child.id].del(),
	update: func() {
		#debug.dump(me.text.getTransformedBounds());
		var t = systime();
		me.searcher.update();
		var spacing = me.line_height * me.font_size;
		var y = -spacing;
		foreach (var child; me.children) {
			me.items[child.id]
				.setText(me.display(child.id,child.value))
				.setTranslation(0, (y+=spacing))
				.setColor(me.color(child));
		}
		me.group.update(); # re-render so scrolling is accurate
		me.scroll.update();
		if (size(me.history))
			me.back.setText("Back ("~size(me.history)~")").setEnabled(1);
		else me.back.setText("Back").setEnabled(0);
		if (typeof(me.editing) == 'hash') {
			var key = actions[role(me.editing.id)](me.editing.id);
			me.editing = me.latest_child(me.editing);
			me.editing_node.setText("[key "~key~"]: me[k]="~me.edit_pad);
		} elsif (typeof(me.editing) == 'vector') {
			var sz = size(me.editing)-1;
			if (sz > 9) sz = chr(`a`+sz-10);
			me.editing_node.setText("closure 0-"~sz~"?");
		} else me.editing_node.setText(me.edit_msg);
		var t = systime()-t;
		t *= 1000;
		printlog("debug", "NasalBrowser.update() took "~int(t)~"ms");
		me.timing.setText("Time taken to refresh: "~int(t)~"ms");
	},
	latest_child: func(child) {
		# Grab the latest value, not what we have here:
		foreach (var c; me.children)
			if (c.id == child.id) return c;
		return child;
	},
	move_root: func {
		if (size(arg)) var child = arg[0];
		if (size(arg) == 1) arg ~= [0];
		if (!size(arg)) {
			if (!size(me.history)) return else
			me.root = pop(me.history);
		} elsif (arg[1]) {
			me.editing = child;
			if (typeof(child.value) == 'scalar')
				me.edit_pad = debug.string(child.value, 0);
			else me.edit_pad = "";
			me.edit_msg = "";
			return me.update();
		} elsif (typeof(child.value) == 'hash' or typeof(child.value) == 'vector') {
			append(me.history, me.root);
			me.root = child.value;
		} elsif (typeof(child.value) == 'func') {
			me.editing = []; var lvl = -1;
			while ((var cl = closure(child.value,lvl+=1)) != nil)
				append(me.editing, cl);
			if (size(me.editing)) {
				me.edit_pad = nil;
				me.edit_msg = "";
				return me.update();
			}
		} else return;
		me.scroll.scrollTo(0,0);
		me.editing = nil;
		me.edit_pad = nil;
		me.edit_msg = "";
		me.update();
	},
	handle_key: func(key, modifiers) {
		var modifier_str = "";
		foreach (var m; keys(modifiers)) {
			if (modifiers[m])
				modifier_str ~= substr(m,0,1);
		}
		if (!contains({"s":,"c":,"":}, modifier_str)) {
			return 0; # had extra modifiers, reject this event

		} elsif (key == 27) {  # escape -> cancel
			printlog(_dbg_level, "esc");
			if (me.editing != nil) {
				me.edit_pad = me.editing = nil;
				me.update();
			} else me.del();
			return 1;

		} elsif (typeof(me.editing) == 'vector') {
			# Take a decimal/hexidecimal/base36 number
			if (key >= `0` and key <= `9`) var val = key-`0`;
			elsif (key >= `a` and key <= `z`) var val = key-`a`+10;
			elsif (key >= `A` and key <= `A`) var val = key-`A`+10;
			else return 0;
			var k = {value:me.editing[0]};
			me.move_root(k);

		} elsif (me.editing == nil) {
			return 0; # don't care about other events when not editing

		} elsif (key == `\n` or key == `\r`) {
			printlog(_dbg_level, "return (key: "~key~", shift: "~modifiers.shift~")");
			me.editing = me.latest_child(me.editing);
			me.edit_msg = "";
			var c = call(func compile("me[k]="~me.edit_pad, "<nasal browser editing>"), nil, var err=[]);
			if (size(err)) {
				me.edit_msg = "syntax error, see console";
				debug.printerror(err);
			} else {
				bind(c, globals);
				call(c, nil, me.editing.parent, {k:me.editing.id}, err);
				if (size(err)) {
					me.edit_msg = "runtime error, see console";
					debug.printerror(err);
				}
			}
			me.editing = nil; me.edit_pad = "";

		} elsif (key == 8) {               # backspace
			printlog(_dbg_level, "back");
			if (size(me.edit_pad))
				me.edit_pad = substr(me.edit_pad, 0, size(me.edit_pad)-1);

		} elsif (!string.isprint(key)) {
			printlog(_dbg_level, "other key: "~key);
			return 0;                  # pass other funny events

		} else {
			printlog(_dbg_level, "key: "~key~" (`"~chr(key)~"`)");
			me.edit_pad ~= chr(key);
		}

		me.update();
		return 1;
	},
	gettranslation: func(k) me.translations[k] or "[Error: no translation for key "~k~"]",
	open_options: func() {
		if (me.sub_window != nil) me.sub_window.del();
		me.sub_window = me.OptionsWindow.new(me);
	},
	OptionsWindow: {
		new: func(parent) {
			var m = {
				parents: [CanvasBrowser.OptionsWindow],
				listeners: [], timer: nil,
				window: canvas.Window.new([300,300], "default", "Nasal-browser-options-"~parent.name),
				parent: parent,
			};
			m.window.del = func() {
				delete(me, "del");
				me.del(); # inherited canvas.Window.del();
				m.window = nil;
				m.del();
			};

			m.canvas = m.window.createCanvas()
			                   .setColorBackground(parent.colors.background);
			m.root_el = m.canvas.createGroup("root");
			m.scroll = canvas.gui.widgets
			          .ScrollArea.new(m.root_el, canvas.style, {});
			m.group = m.scroll.getContent();

			m.vbox = canvas.VBoxLayout.new();
			m.scroll.setLayout(m.vbox);

			m.layout = canvas.HBoxLayout.new();
			m.layout.addItem(m.scroll);
			m.window.setLayout(m.layout);

			var opts = [];
			append(opts, [
				"Sort by type",
				func(e) {
					parent.cmp = e.detail.checked ? parent.cmp_type_name : parent.cmp_name;
					parent.scroll.scrollTo(0,0);
					parent.update();
				},
				parent.cmp == parent.cmp_type_name
			]);
			if (contains(globals.debug, "decompile")) { # requires extended-nasal binary
				append(opts, [
					"Show function arguments (experimental)",
					func(e) {
						parent.display_func_args = e.detail.checked;
						parent.update();
					},
					parent.display_func_args
				]);
				append(opts, [
					"Cache function arguments (warning: may leak memory)",
					func(e) {
						parent.fn_arg_cache = e.detail.checked ? {} : nil;
						parent.update();
					},
					parent.fn_arg_cache != nil
				]);
			}

			foreach (var opt; opts) {
				var option = canvas.gui.widgets
				            .CheckBox.new(m.group, canvas.style, {"wordWrap":1})
				                     .setText(opt[0]);
				option.setChecked(opt[2]);
				option.listen("toggled", opt[1]);
				m.vbox.addItem(option, 0);
			}
			m.vbox.addStretch(1);
			m.update();

			return m;
		},
		update: func {
			me.group.update();
			me.scroll.update();
		},
		del: func() {
			if (me.window != nil)
			{ me.window.del(); me.window = nil }
			if (me.parent != nil)
			{ me.parent.sub_window = nil; me.parent = nil }
			return nil;
		},
	},
	display: func(k,variable,sep=" = ") {
		k = actions[role(k)](k);
		var t = typeof(variable);
		if (t == 'scalar') {
			call(func size(variable), nil, var err = []);
			if (size(err))
				k~sep~variable;
			else k~sep~"'"~variable~"'";
		}
		elsif (t == 'hash')
			k~sep~"{size "~size(variable)~"}/";
		elsif (t == 'vector')
			k~sep~"[size "~size(variable)~"]/";
		elsif (t == 'nil')
			k~sep~"nil";
		elsif (t == 'ghost')
			k~sep~"<ghost/"~ghosttype(variable)~">";
		elsif (t == 'func' and me.display_func_args) {
			var i = id(variable);
			if (me.fn_arg_cache != nil and contains(me.fn_arg_cache, i))
				return k~sep~me.fn_arg_cache[i];
			var ret = call(func() {
				var s = func() (r?", ":"");
				var repr = func(v)
					v == nil ? 'nil' :
					role(v) == 'string' ?
						debug.string(v, 0) : v;
				var d = debug.decompile(variable);
				var r = "";
				foreach  (var a; d.arg_syms) r~=s()~a;
				forindex (var i; d.opt_arg_syms) r~=s()~d.opt_arg_syms[i]~"="~repr(d.opt_arg_vals[i]);
				if (d.rest_arg_sym != nil) r~=s()~d.rest_arg_sym ~ "...";
				return "("~r~")";
			}, nil, var err=[]);
			if (size(err) and err[0] == "decompile argument not a code object!")
				return k~sep~"<internal func>";
			elsif (size(err) and __display_error) {
				debug.printerror(err);
				__display_error = 0;
			}
			if (ret) k~sep~(
				me.fn_arg_cache != nil ? (me.fn_arg_cache[i] = "<func"~ret~">")
				: "<func"~ret~">"
			);
			else k~sep~"<func>";
		} else k~sep~"<"~t~">";
	},
};

var make_window = func CanvasBrowser.new();

var reload = func() io.load_nasal(getprop("/sim/fg-root")~"/Nasal/nasal_browser.nas");

if (!getprop("/sim/signals/fdm-initialized")) settimer(make_window, 0.5);