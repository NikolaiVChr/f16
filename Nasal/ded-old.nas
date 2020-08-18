
var loop_ded = func {# one line is max 24 chars
    
    if (page == pSTPT) {
       
    } elsif (page == pCRUS) {
      
    } elsif (page == pIFF) {
      
    } elsif (page == pLINK) {
      
      
    } elsif (page == pCNI) {
      var freq   = getprop("instrumentation/comm["~comm~"]/frequencies/selected-mhz");
      var time   = getprop("/sim/time/gmt-string");
      var t      = getprop("instrumentation/tacan/display/channel");
      var pond   = getprop("instrumentation/transponder/inputs/knob-mode")==0?0:1;
      if (pond) pond = sprintf("%04d",getprop("instrumentation/transponder/id-code"));
      else pond = "----";
      var off = "   ";
      if (getprop("instrumentation/comm["~comm~"]/volume") == 0) {
        off = "OFF";
      }
      text[0] = sprintf("UHF    --    STPT %s",no);
      text[1] = sprintf(" COMM%d  %s              ",comm+1,off);
      text[2] = sprintf("VHF  %6.2f   %s",freq,time);
      text[3] = sprintf("                        ");
      text[4] = sprintf("M34   %s    MAN  T%s",pond,t);
    } elsif (page == pBINGO) {
     
    } elsif (page == pMAGV) {
     
    } elsif (page == pLASER) {
      
    } elsif (page == pTIME) {
      
    } elsif (page == pCM) {
    
    } elsif (page == pLIST) {
      
    } elsif (page == pMISC) {
      
    }
};

var cursorUp = func {
  sound.doubleClick();
  if (page == pTIME) {
	toggleHack();
  } else {
   
 }
}

var cursorDown = func {
  sound.doubleClick();
  if (page == pTIME) {
	resetHack();
  } else {
    
}

var stpt = func {
  sound.doubleClick();
  page = pSTPT;
}

var tacan = func {
  sound.doubleClick();
  page = pTACAN;
}

var iff = func {
  sound.doubleClick();
  page = pIFF;
}

var comm1 = func {
  sound.doubleClick();
  comm = 0;
  page = pCNI;
}

var comm2 = func {
  sound.doubleClick();
  comm = 1;
  page = pCNI;
}

var button0 = func {
  sound.doubleClick();
  if (page == pLIST) {
    page = pMISC;
  }
}

var button2 = func {
  sound.doubleClick();
  if (page == pLIST) {
    page = pBINGO;
  } elsif (page == pMISC) {
    page = pMAGV;
  } else {
    page = pALOW;
  }
}

var rcl = func {
  sound.doubleClick();
  page = pMAGV;
}

var f_ack = func {
  sound.doubleClick();
  page = pFACK;
}

var link16 = func {
  sound.doubleClick();
  page = pLINK;
}

var laser = func {
  sound.doubleClick();
  page = pLASER;
}

var time = func {
  sound.doubleClick();
  page = pTIME;
}

var list = func {
  sound.doubleClick();
  page = pLIST;
}

var counter = func {
  sound.doubleClick();
  page = pCM;
}

var cruise = func {
  sound.doubleClick();
  page = pCRUS;
}