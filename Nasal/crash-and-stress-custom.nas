# use:
var crashCode = nil;
var crash_start = func {
	removelistener(lsnr);
	crashCode = CrashAndStress.new([0,1,2]);
	crashCode.start();
}

var lsnr = setlistener("sim/signals/fdm-initialized", crash_start);

# test:
var repair = func {
	crashCode.repair();
};

var exp = func {
	crashCode.abandon();
};

var eject = func {
	crashCode.eject();
};