# Chronograph #############

# One button elapsed counter 

var chrono_onoff = props.globals.getNode("instrumentation/clock/chronometer-on",1);
var reset_state = props.globals.getNode("instrumentation/clock/reset-state",1);
var elapsed_sec = props.globals.getNode("instrumentation/clock/elapsed-sec", 1);
var indicated_sec = props.globals.getNode("instrumentation/clock/indicated-sec");

aircraft.data.add("/instrumentation/clock/offset-sec");

chrono_onoff.setBoolValue( 0 );
reset_state.setBoolValue( 1 );
elapsed_sec.setValue( 0 );
var offset = 0;

var click = func {
	var on = chrono_onoff.getBoolValue();
	var reset = reset_state.getBoolValue();
	if ( ! on ) {
		if ( ! reset ) {
			# Had been former started and stoped, now, has to be reset.
			offset = 0;
			elapsed_sec.setValue( 0 );
			reset_state.setBoolValue( 1 );
		} else {
			# Is not started but allready reset, start it.
			chrono_onoff.setBoolValue( 1 );
			reset_state.setBoolValue( 0 );
			offset = indicated_sec.getValue();
		}
	} else {
		# Stop it.
		chrono_onoff.setBoolValue( 0 );
		reset_state.setBoolValue( 0 );
	}
}

var update_chrono = func {
	var on = chrono_onoff.getBoolValue();
	if ( on ) {
		var i_sec = indicated_sec.getValue();
		var e_sec = i_sec - offset;
		elapsed_sec.setValue( e_sec );
	}
}

# Uncomment the following if update_chrono() has to be launched standalone.
# Otherwise launch update_chrono() from a centralized loop which save some
# CPU cycles.

### We don't have a central loop for the F-16 yet.
### FIXME
var chrono_loop = func {
	update_chrono();
        settimer(chrono_loop, 0.1);
}
settimer(chrono_loop, 0.5);
