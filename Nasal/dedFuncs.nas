# Classes
var Button = {
	new: func(routerVec = nil, specificAction = nil) {
		var button = {parents: [Button]};
		button.routerVec = routerVec;
		button.specificAction = specificAction;
		return button;
	},
	doAction: func() {
		sound.doubleClick();
		if (me.routerVec != nil) {
			foreach (var router; me.routerVec) {
				router.run();
			}
		}
		if (me.specificAction != nil) {
			me.specificAction.run();
		}
	},
};

var Router = {
	new: func(start, finish) {
		var router = {parents: [Router]};
		router.start = start;
		router.finish = finish;
		return router;
	},
	run: func() {
		if (dataEntryDisplay.page == me.start) {
			dataEntryDisplay.page = me.finish;
		}
	},
};

var Action = {
	new: func(page, funcCallback) {
		var action = {parents: [Action]};
		action.page = page;
		action.funcCallback = funcCallback;
		return action;
	},
	run: func() {
		if (dataEntryDisplay.page == me.page) {
			call(me.funcCallback);
		}
	},
};

# Functions
var toggleHack = func() {
	if (dataEntryDisplay.chrono.running) {
		dataEntryDisplay.chrono.stop();
	} else {
		dataEntryDisplay.chrono.start();
	}
};

var resetHack = func() {
	dataEntryDisplay.chrono.stop();
	dataEntryDisplay.chrono.reset();
};