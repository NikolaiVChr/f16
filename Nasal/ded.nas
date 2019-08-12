#var theInit = setlistener("ja37/supported/initialized", func {
#  if(getprop("ja37/supported/radar") == 1) {
#    removelistener(theInit);
#    callInit();
#  }
#}, 1, 0);
var line1 = nil;
var line2 = nil;
var line3 = nil;
var line4 = nil;
var line5 = nil;
var callInit = func {
  canvasded = canvas.new({
        "name": "DED",
        "size": [256, 128],
        "view": [256, 128],
        "mipmapping": 1
  });
      
  canvasded.addPlacement({"node": "poly.003", "texture": "canvas.png"});
  canvasded.setColorBackground(0.00, 0.10, 0.00, 1.00);

  dedGroup = canvasded.createGroup();
  dedGroup.show();
  var color = [1,1,0.7,1];
  line1 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("left-bottom-baseline")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("LINE 1            LINE 1")
        .setTranslation(55, 128*0.2);
  line2 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("left-bottom-baseline")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("LINE 2            LINE 2")
        .setTranslation(55, 128*0.3);
  line3 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("left-bottom-baseline")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("LINE 3            LINE 3")
        .setTranslation(55, 128*0.4);
  line4 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("left-bottom-baseline")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("LINE 4            LINE 4")
        .setTranslation(55, 128*0.5);
  line5 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(color)
        .setAlignment("left-bottom-baseline")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("LINE 5            LINE 5")
        .setTranslation(55, 128*0.6);
};

var pTACAN= 0;
var pALOW = 1;
var pSTPT = 2;
var pTIME = 3;
var pIFF  = 4;
var pCNI  = 5;
var pBINGO= 6;
var pMAGV = 7;
var pLINK = 8;
var pLASER= 9;
var pCM   = 10;
var pLIST = 100;#excluded from random

var page = int(rand()*10.99);#random page at startup
var comm = 0;

var text = ["","","","",""];

var scroll = 0;

var loop_ded = func {# one line is max 24 chars
    var no = getprop("autopilot/route-manager/current-wp")+1;
    if (no == 0) {
      no = "";
    } else {
      no = sprintf("%2d",no);
    }
    if (page == pSTPT) {
      var fp = flightplan();
      var TOS = "--:--:--";
      var lat = "";
      var lon = "";
      var alt = -1;
      if (fp != nil) {
        var wp = fp.currentWP();
        if (wp != nil) {
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
    } elsif (page == pTACAN) {
      var ilsOn  = (getprop("sim/model/f16/controls/navigation/instrument-mode-panel/mode/rotary-switch-knob") == 0 or getprop("sim/model/f16/controls/navigation/instrument-mode-panel/mode/rotary-switch-knob") == 3)?"ON ":"OFF";
      #var freq   = getprop("instrumentation/tacan/frequencies/selected-mhz");
      var freq   = getprop("instrumentation/nav[0]/frequencies/selected-mhz");
      var chan   = getprop("instrumentation/tacan/frequencies/selected-channel");
      var band   = getprop("instrumentation/tacan/frequencies/selected-channel[4]");
      #var course = getprop("instrumentation/tacan/in-range")?getprop("instrumentation/tacan/indicated-bearing-true-deg"):-1;
      var course = (getprop("instrumentation/nav[0]/in-range") and getprop("instrumentation/nav[0]/nav-loc"))?geo.normdeg(getprop("orientation/heading-deg")-getprop("orientation/heading-magnetic-deg")+getprop("instrumentation/nav[0]/heading-deg")):-1;
      if (course == -1) {
        course = "---.--";
      } else {
        course = sprintf("%06.2f\xc2\xb0",course);
      }
      text[0] = sprintf("    TCN REC      ILS %s",ilsOn);
      text[1] = sprintf("                        ");
      text[2] = sprintf("               CMD STRG ");
      text[3] = sprintf("CHAN    %03d FREQ %6.2f",chan,freq);
      text[4] = sprintf("BAND      %s CRS %s",band,course);
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
      if (sign != "" and (sign == getprop("link16/wingman-1") or sign == getprop("link16/wingman-2") or sign == getprop("link16/wingman-3") or sign == getprop("link16/wingman-4") or sign == getprop("link16/wingman-5") or sign == getprop("link16/wingman-6") or sign == getprop("link16/wingman-7"))) {
        friend = "WINGMAN";
      } elsif (sign != "") {
        friend = "NO CONN";
      }

      text[0] = sprintf("     IFF                ");
      text[1] = sprintf("                        ");
      text[2] = sprintf("PILOT   %s",sign);
      text[3] = sprintf("ID      %s",type);
      text[4] = sprintf("Link16  %s",friend);
    } elsif (page == pLINK) {
      text[0] = sprintf(" XMT 40 INTRAFLIGHT  %s ",no);
      
      var last = 0;
      if (getprop("link16/wingman-7")!="") last = 7;
      elsif (getprop("link16/wingman-6")!="") last = 6;
      elsif (getprop("link16/wingman-5")!="") last = 5;
      elsif (getprop("link16/wingman-4")!="") last = 4;
      elsif (getprop("link16/wingman-3")!="") last = 3;
      elsif (getprop("link16/wingman-2")!="") last = 2;
      elsif (getprop("link16/wingman-1")!="") last = 1;
      scroll += 0.25;
      if (scroll >= last-3) scroll = 0;
      var wingmen = [getprop("link16/wingman-1"),getprop("link16/wingman-2"),getprop("link16/wingman-3"),getprop("link16/wingman-4"),getprop("link16/wingman-5"),getprop("link16/wingman-6"),getprop("link16/wingman-7")];
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
      text[0] = sprintf("UHF    --    STPT %s",no);
      text[1] = sprintf(" COMM%d                   ",comm+1);
      text[2] = sprintf("VHF  %6.2f   %s",freq,time);
      text[3] = sprintf("                        ");
      text[4] = sprintf("                  T%s",t);
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
      var time   = getprop("/sim/time/gmt-string");
      text[0] = sprintf("        TIME      %s     ",no);
      text[1] = sprintf("  SYSTEM     %s",time);
      text[2] = sprintf("  HACK       00:00:00   ");
      text[3] = sprintf("  DELTA TOS  00:00:00   ");
      text[4] = sprintf("                        ");
    } elsif (page == pCM) {
      # this page is not authentic, but since the in cockpit display is defunc, pilot need to know these values so I put them into a DED page.
      var flares   = getprop("ai/submodels/submodel[0]/count");
      text[0] = sprintf("      CNTM       %s    ",no);
      text[1] = sprintf("  CHAFF     %3d",flares);
      text[2] = sprintf("  FLARE     %3d",flares);
      text[3] = sprintf("                        ");
      text[4] = sprintf("                        ");
    } elsif (page == pLIST) {
      text[0] = sprintf("        LIST      %s     ",no);
      text[1] = sprintf(" 1ILS  2ALOW 3MAGV COM1 ");
      text[2] = sprintf(" 4STPT 5DLNK 6TIME COM2 ");
      text[3] = sprintf(" 7BNGO 8LASR 9CNTM IFF  ");
      text[4] = sprintf("                   LIST ");
    }
    line1.setText(text[0]);
    line2.setText(text[1]);
    line3.setText(text[2]);
    line4.setText(text[3]);
    line5.setText(text[4]);
    settimer(loop_ded, 0.5);
};
callInit();
loop_ded();

var stpt = func {
  page = pSTPT;
}

var alow = func {
  page = pALOW;
}

var tacan = func {
  page = pTACAN;
}

var iff = func {
  page = pIFF;
}

var comm1 = func {
  comm = 0;
  page = pCNI;
}

var comm2 = func {
  comm = 1;
  page = pCNI;
}

var bingo = func {
  page = pBINGO;
}

var magv = func {
  page = pMAGV;
}

var link16 = func {
  page = pLINK;
}

var laser = func {
  page = pLASER;
}

var time = func {
  page = pTIME;
}

var list = func {
  page = pLIST;
}

var counter = func {
  page = pCM;
}

## these methods taken from JA37:
var convertDoubleToDegree = func (value) {
        var sign = value < 0 ? -1 : 1;
        var abs = math.abs(math.round(value * 1000000));
        var dec = math.fmod(abs,1000000) / 1000000;
        var deg = math.floor(abs / 1000000) * sign;
        var min = dec * 60;
        return [deg,min];
}
var convertDegreeToStringLat = func (lat) {
  lat = convertDoubleToDegree(lat);
  var s = "N";
  if (lat[0]<0) {
    s = "S";
  }
  return sprintf("%s %3d\xc2\xb0%06.3f´",s,math.abs(lat[0]),lat[1]);
}
var convertDegreeToStringLon = func (lon) {
  lon = convertDoubleToDegree(lon);
  var s = "E";
  if (lon[0]<0) {
    s = "W";
  }
  return sprintf("%s %3d\xc2\xb0%06.3f´",s,math.abs(lon[0]),lon[1]);
}
var convertDoubleToDegree37 = func (value) {
        var sign = value < 0 ? -1 : 1;
        var abs = math.abs(math.round(value * 1000000));
        var dec = math.fmod(abs,1000000) / 1000000;
        var deg = math.floor(abs / 1000000) * sign;
        var min = math.floor(dec * 60);
        var sec = math.round((dec - min / 60) * 3600);#TODO: unsure of this round()
        return [deg,min,sec];
}
var convertDegreeToStringLat37 = func (lat) {
  lat = convertDoubleToDegree(lat);
  var s = "N";
  if (lat[0]<0) {
    s = "S";
  }
  return sprintf("%02d %02d %02d%s",math.abs(lat[0]),lat[1],lat[2],s);
}
var convertDegreeToStringLon37 = func (lon) {
  lon = convertDoubleToDegree(lon);
  var s = "E";
  if (lon[0]<0) {
    s = "W";
  }
  return sprintf("%03d %02d %02d%s",math.abs(lon[0]),lon[1],lon[2],s);
}
var convertDegreeToDispStringLat = func (lat) {
  lat = convertDoubleToDegree(lat);

  return sprintf("%02d%02d%02d",lat[0],lat[1],lat[2]);
}
var convertDegreeToDispStringLon = func (lon) {
  lon = convertDoubleToDegree(lon);
  return sprintf("%03d%02d%02d",lon[0],lon[1],lon[2]);
}
var convertDegreeToDouble = func (hour, minute, second) {
  var d = hour+minute/60+second/3600;
  return d;
}
var myPosToString = func {
  print(convertDegreeToStringLat(getprop("position/latitude-deg"))~"  "~convertDegreeToStringLon(getprop("position/longitude-deg")));
}
var stringToLon = func (str) {
  var total = num(str);
  if (total==nil) {
    return nil;
  }
  var sign = 1;
  if (total<0) {
    str = substr(str,1);
    sign = -1;
  }
  var deg = num(substr(str,0,2));
  var min = num(substr(str,2,2));
  var sec = num(substr(str,4,2));
  if (size(str) == 7) {
    deg = num(substr(str,0,3));
    min = num(substr(str,3,2));
    sec = num(substr(str,5,2));
  } 
  if(deg <= 180 and min<60 and sec<60) {
    return convertDegreeToDouble(deg,min,sec)*sign;
  } else {
    return nil;
  }
}
var stringToLat = func (str) {
  var total = num(str);
  if (total==nil) {
    return nil;
  }
  var sign = 1;
  if (total<0) {
    str = substr(str,1);
    sign = -1;
  }
  var deg = num(substr(str,0,2));
  var min = num(substr(str,2,2));
  var sec = num(substr(str,4,2));
  if(deg <= 90 and min<60 and sec<60) {
    return convertDegreeToDouble(deg,min,sec)*sign;
  } else {
    return nil;
  }
}