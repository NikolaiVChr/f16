
var loop_ded = func {# one line is max 24 chars
    
    if (page == pSTPT) {
       
    } elsif (page == pCRUS) {
      
    } elsif (page == pIFF) {
      
    } elsif (page == pLINK) {
      text[0] = sprintf(" XMT 40 INTRAFLIGHT  %s ",no);
      
      var last = 0;
      if (getprop("link16/wingman-12")!="") last = 12;
      elsif (getprop("link16/wingman-11")!="") last = 11;
      elsif (getprop("link16/wingman-10")!="") last = 10;
      elsif (getprop("link16/wingman-9")!="") last = 9;
      elsif (getprop("link16/wingman-8")!="") last = 8;
      elsif (getprop("link16/wingman-7")!="") last = 7;
      elsif (getprop("link16/wingman-6")!="") last = 6;
      elsif (getprop("link16/wingman-5")!="") last = 5;
      elsif (getprop("link16/wingman-4")!="") last = 4;
      elsif (getprop("link16/wingman-3")!="") last = 3;
      elsif (getprop("link16/wingman-2")!="") last = 2;
      elsif (getprop("link16/wingman-1")!="") last = 1;
      scroll += 0.25;
      if (scroll >= last-3) scroll = 0;
      var wingmen = [getprop("link16/wingman-1"),getprop("link16/wingman-2"),getprop("link16/wingman-3"),getprop("link16/wingman-4"),getprop("link16/wingman-5"),getprop("link16/wingman-6"),getprop("link16/wingman-7"),getprop("link16/wingman-8"),getprop("link16/wingman-9"),getprop("link16/wingman-10"),getprop("link16/wingman-11"),getprop("link16/wingman-12")];
      var used = subvec(wingmen,int(scroll),4);
      text[1] = sprintf("#%d %7s      COMM VHF",int(scroll+1),used[0]);
      text[2] = sprintf("#%d %7s      DATA 16K",int(scroll+2),used[1]);
      text[3] = sprintf("#%d %7s      OWN  #0 ",int(scroll+3),used[2]);
      text[4] = sprintf("#%d %7s      LAST #%d ",int(scroll+4),used[3],last);
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
      var amount = geo.normdeg180(getprop("orientation/heading-deg")-getprop("orientation/heading-magnetic-deg"));
      if (amount != nil) {
        var letter = "W";
        if (amount <0) {#no longer sure, this is correct..
          letter = "E";
          amount = math.abs(amount);
        }
        text[2] = sprintf("         %s %.1f\xc2\xb0",letter, amount);
      } else {
        text[2] = sprintf("         GPS OFFLINE");
      }
      text[0] = sprintf("       MAGV  AUTO   %s  ",no);
      text[1] = sprintf("                        ");
      text[3] = sprintf("                        ");
      text[4] = sprintf("                        ");
    } elsif (page == pLASER) {
      var code = getprop("f16/avionics/laser-code");
      var arm = getprop("controls/armament/laser-arm-dmd");
      text[0] = sprintf("         LASER      %s   ",no);
      text[1] = sprintf("   TGP CODE    %04d     ",code);
      text[2] = sprintf("   LST CODE    %04d     ",code);
      text[3] = sprintf("   A-G: CMBT  A-A: TRNG ");
      text[4] = sprintf("   LASER ST TIME  16 SEC");
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
    var active = getprop("autopilot/route-manager/active") and getprop("f16/avionics/power-mmc");
    var wp = getprop("autopilot/route-manager/current-wp");
    var max = getprop("autopilot/route-manager/route/num");
  
    if (active and wp != nil and wp > -1) {
      wp += 1;
      if (wp>max-1) {
        wp = 0;
      }
      setprop("autopilot/route-manager/current-wp", wp);
   }
 }
}

var cursorDown = func {
  sound.doubleClick();
  if (page == pTIME) {
	resetHack();
  } else {
    var active = getprop("autopilot/route-manager/active") and getprop("f16/avionics/power-mmc");
    var wp = getprop("autopilot/route-manager/current-wp");
    var max = getprop("autopilot/route-manager/route/num");
  
    if (active and wp != nil and wp > -1) {
      wp -= 1;
      if (wp<0) {
        wp = max-1;
      }
      setprop("autopilot/route-manager/current-wp", wp);
    }
  }
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