
var loop_ded = func {# one line is max 24 chars
    
    if (page == pSTPT) {
      var fp = flightplan();
      var TOS = "--:--:--";
      var lat = "";
      var lon = "";
      var alt = -1;
      if (fp != nil) {
        var wp = fp.currentWP();
        if (wp != nil and getprop("f16/avionics/power-mmc")) {
          lat = convertDegreeToStringLat(wp.lat);
          lon = convertDegreeToStringLon(wp.lon);
          alt = wp.alt_cstr;
          if (alt == nil) {
            alt = -1;
          }
          var hour   = getprop("sim/time/utc/hour"); 
          var minute = getprop("sim/time/utc/minute");
          var second = getprop("sim/time/utc/second");
          var eta    = getprop("autopilot/route-manager/wp/eta");
          if (eta == nil or getprop("autopilot/route-manager/wp/eta-seconds")>3600*24) {
            #
          } elsif (getprop("autopilot/route-manager/wp/eta-seconds")>3600) {
            eta = split(":",eta);
            minute += num(eta[1]);
            var addOver = 0;
            if (minute > 59) {
              addOver = 1;
              minute -= 60;
            }
            hour += num(eta[0])+addOver;
            while (hour > 23) {
              hour -= 24;
            }
            TOS = sprintf("%02d:%02d:%02d",hour,minute,second);
          } else {
            eta = split(":",eta);
            second += num(eta[1]);
            var addOver = 0;
            if (second > 59) {
              addOver = 1;
              second -= 60;
            }
            minute += num(eta[0])+addOver;
            addOver = 0;
            if (minute > 59) {
              addOver = 1;
              minute -= 60;
            }
            hour += addOver;
            while (hour > 23) {
              hour -= 24;
            }
            TOS = sprintf("%02d:%02d:%02d",hour,minute,second);   
          }          
        }
      }
      
      text[0] = sprintf("         STPT %s    AUTO",no);
      text[1] = sprintf("      LAT  %s",lat);
      text[2] = sprintf("      LNG  %s",lon);
      text[3] = sprintf("     ELEV  % 5dFT",alt);
      text[4] = sprintf("      TOS  %s",TOS);
    } elsif (page == pCRUS) {
      var fuel   = "";
      var fp = flightplan();
      var maxS = "";
      if (fp != nil) {
        var max = fp.getPlanSize();
        if (max > 0) {
          maxS =""~max;
          var ete    = getprop("autopilot/route-manager/ete");
          if (ete != nil and ete > 0) {
            var pph = getprop("engines/engine[0]/fuel-flow_pph");
            if (pph == nil) pph = 0;
            fuel = sprintf("% 6dLBS",pph*(ete/3600));
            if (size(fuel)>9) {
              fuel = "999999LBS";
            }
          }
        }
      }
      var windkts = getprop("environment/wind-speed-kt");
      var winddir = getprop("environment/wind-from-heading-deg");
      if (windkts == nil or winddir == nil) {
        windkts = -1;
        winddir = -1;
      }
      windkts = sprintf("% 3dKTS",getprop("environment/wind-speed-kt"));
      winddir = sprintf("%03d\xc2\xb0",getprop("environment/wind-from-heading-deg"));
      text[0] = sprintf("     CRUS  RNG  ",no);
      text[1] = sprintf("     STPT  %s  ",maxS);
      text[2] = sprintf("     FUEL %s",fuel);#fuel used to get to last steerpoint at current fuel consumption.
      text[3] = sprintf("                        ");
      text[4] = sprintf("     WIND  %s %s",winddir,windkts);
    } elsif (page == pTACAN) {
      var ilsOn  = (getprop("sim/model/f16/controls/navigation/instrument-mode-panel/mode/rotary-switch-knob") == 0 or getprop("sim/model/f16/controls/navigation/instrument-mode-panel/mode/rotary-switch-knob") == 3)?"ON ":"OFF";
      #var freq   = getprop("instrumentation/tacan/frequencies/selected-mhz");
      var freq   = getprop("instrumentation/nav[0]/frequencies/selected-mhz");
      var chan   = getprop("instrumentation/tacan/frequencies/selected-channel");
      var band   = getprop("instrumentation/tacan/frequencies/selected-channel[4]");
      #var course = getprop("instrumentation/tacan/in-range")?getprop("instrumentation/tacan/indicated-bearing-true-deg"):-1;
      #var course = (getprop("instrumentation/nav[0]/in-range") and getprop("instrumentation/nav[0]/nav-loc"))?geo.normdeg(getprop("orientation/heading-deg")-getprop("orientation/heading-magnetic-deg")+getprop("instrumentation/nav[0]/heading-deg")):-1;
      #if (course == -1) {
      #  course = "---.--";
      #} else {
      var course = sprintf("%03.0f\xc2\xb0",getprop("f16/crs-ils"));
      #}
	  var ident = getprop("instrumentation/tacan/ident");
      var inrng = getprop("instrumentation/tacan/in-range");	
	  
      text[0] = sprintf("TCN REC          ILS %s",ilsOn);
      text[1] = sprintf("                        ");
	  if (!inrng or ident == nil or ident == "") {
          text[2] = sprintf("            CMD STRG ", ident);
	  } else {
          text[2] = sprintf("BCN     %s CMD STRG ", ident);
	  }
      text[3] = sprintf("CHAN    %-3d FRQ  %6.2f",chan,freq);
      text[4] = sprintf("BAND    %s   CRS  %s",band,course);
    } elsif (page == pIFF) {
      var target = awg_9.active_u;
      var sign = "";
      if (target != nil) {
        sign = target.get_Callsign();
      }
      var type = "";
      if (target != nil) {
        type = target.get_model();
      }
      var friend = "";
      if (getprop("f16/avionics/power-dl") and sign != "" and (sign == getprop("link16/wingman-1") or sign == getprop("link16/wingman-2") or sign == getprop("link16/wingman-3") or sign == getprop("link16/wingman-4") or sign == getprop("link16/wingman-5") or sign == getprop("link16/wingman-6") or sign == getprop("link16/wingman-7") or sign == getprop("link16/wingman-8") or sign == getprop("link16/wingman-9") or sign == getprop("link16/wingman-10") or sign == getprop("link16/wingman-11") or sign == getprop("link16/wingman-12"))) {
        friend = "WINGMAN";
      } elsif (sign != "") {
        friend = "NO CONN";
      }
      #if (type != "") {
      #  friend  = getprop("instrumentation/iff/response")?"M4":"UNKWN";
      #} else {
      #  friend = "";
      #}
      var iffcode = getprop("instrumentation/iff/channel-selection");
      var pond   = getprop("instrumentation/transponder/inputs/knob-mode")==0?0:1;
      if (pond) pond = sprintf("%04d",getprop("instrumentation/transponder/id-code"));
      else pond = "----";
      text[0] = sprintf("IFF   ON   MAN          ");
      text[1] = sprintf("M3     %s             ", pond);
      text[2] = sprintf("M4     %04d             ", iffcode);
      text[3] = sprintf("PILOT   %s",sign);
      text[4] = sprintf("TYPE    %s",type);
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
    } elsif (page == pALOW) {
      var alow = getprop("f16/settings/cara-alow");
      var floor = getprop("f16/settings/msl-floor");
      text[0] = sprintf("         ALOW       %s  ",no);
      text[1] = sprintf("                        ");
      text[2] = sprintf("   CARA ALOW %5dFT    ",alow);
      text[3] = sprintf("   MSL FLOOR %5dFT    ",floor);
      text[4] = sprintf("TF ADV (MSL)  8500FT    ");
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
      var total = getprop("consumables/fuel/total-fuel-lbs");
      var bingo = getprop("f16/settings/bingo");
      text[0] = sprintf("        BINGO       %s  ",no);
      text[1] = sprintf("                        ");
      text[2] = sprintf("    SET    %5dLBS      ",bingo);
      text[3] = sprintf("  TOTAL    %5dLBS      ",total);
      text[4] = sprintf("                        ");
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
      var time = getprop("/sim/time/gmt-string");
	  var hackHour = int(getprop("f16/avionics/hack/elapsed-time-sec") / 3600);
	  var hackMin = int((getprop("f16/avionics/hack/elapsed-time-sec") - (hackHour * 3600)) / 60);
	  var hackSec = int(getprop("f16/avionics/hack/elapsed-time-sec") - (hackHour * 3600) - (hackMin * 60));
	  var hackTime = sprintf("%02.0f", hackHour) ~ ":" ~ sprintf("%02.0f", hackMin) ~ ":" ~ sprintf("%02.0f", hackSec);
	  var date = sprintf("%02.0f", getprop("/sim/time/utc/month")) ~ "/" ~ sprintf("%02.0f", getprop("/sim/time/utc/day")) ~ "/" ~ right(sprintf("%s", getprop("/sim/time/utc/year")), 2);
      text[0] = sprintf("          TIME      %s  ",no);
	  if (getprop("f16/avionics/power-gps") and getprop("sim/variant-id") != 1 and getprop("sim/variant-id") != 3) {
        text[1] = sprintf("GPS SYSTEM      %s",time);
	  } else {
        text[1] = sprintf("    SYSTEM      %s",time);
	  }
      text[2] = sprintf("      HACK      %s", hackTime);
      text[3] = sprintf(" DELTA TOS      00:00:00   ");
	  if (getprop("sim/variant-id") != 1 and getprop("sim/variant-id") != 3) {
        text[4] = sprintf("  MM/DD/YY      %s", date);
	  } else {
	    text[4] = sprintf("                          ");
	  }
    } elsif (page == pCM) {
      # this page is not authentic, but since the in cockpit display is defunc, pilot need to know these values so I put them into a DED page.
      var flares   = getprop("ai/submodels/submodel[0]/count");
      text[0] = sprintf("      CMDS       %s    ",no);
      text[1] = sprintf("  CHAFF     %3d",flares);
      text[2] = sprintf("  FLARE     %3d",flares);
      text[3] = sprintf("                        ");
      text[4] = sprintf("                        ");
    } elsif (page == pFACK) {
      
      var fails = fail.getList();
      var last = size(fails);
      scrollF += 0.25;
      if (scrollF >= last-2) scrollF = 0;     
      var used = subvec(fails,int(scrollF),3);
      text[0] = sprintf("       F-ACK     %s     ",no);
      text[1] = sprintf("                        ");
      if (size(used)>0) text[2] = sprintf(" %s ",used[0]);
      else text[2] = "";
      if (size(used)>1) text[3] = sprintf(" %s ",used[1]);
      else text[3] = "";
      if (size(used)>2) text[4] = sprintf(" %s ",used[2]);
      else text[4] = "";
    } elsif (page == pLIST) {
      text[0] = sprintf("           LIST      12 ");
      text[1] = sprintf(" 1DEST 2BNGO 3VIP RINTG ");
      text[2] = sprintf(" 4NAV  5MAN  6INS EDLNK ");
      text[3] = sprintf(" 7EWS  8MODE 9VRP OMISC ");
      text[4] = sprintf("                        ");
    } elsif (page == pMISC) {
      text[0] = sprintf("           MISC      12 ");
      text[1] = sprintf(" 1CORR 2MAGV 3OFP R     ");
      text[2] = sprintf(" 4INSM 5LASR 6GPS E     ");
      text[3] = sprintf(" 7DRNG 8BULL 9WPT OHARM ");
      text[4] = sprintf("                        ");
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