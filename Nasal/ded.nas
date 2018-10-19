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
  canvasded.setColorBackground(0.00, 0.20, 0.00, 1.00);

  dedGroup = canvasded.createGroup();
  dedGroup.show();

  line1 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(1,1,0.7, 1)
        .setAlignment("left-bottom")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("LINE 1            LINE 1")
        .setTranslation(55, 128*0.2);
  line2 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(1,1,0.7, 1)
        .setAlignment("left-bottom")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("LINE 2            LINE 2")
        .setTranslation(55, 128*0.3);
  line3 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(1,1,0.7, 1)
        .setAlignment("left-bottom")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("LINE 3            LINE 3")
        .setTranslation(55, 128*0.4);
  line4 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(1,1,0.7, 1)
        .setAlignment("left-bottom")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("LINE 4            LINE 4")
        .setTranslation(55, 128*0.5);
  line5 = dedGroup.createChild("text")
        .setFontSize(13, 1)
        .setColor(1,1,0.7, 1)
        .setAlignment("left-bottom")
        .setFont("LiberationFonts/LiberationMono-Bold.ttf")
        .setText("LINE 5            LINE 5")
        .setTranslation(55, 128*0.6);
};

var pTACAN = 0;
var pALOW = 1;
var pSTPT = 2;
var pIFF  = 4;
var pCNI  = 5;

var page = pCNI;
var comm = 0;

var loop_ded = func {

    if (page == pSTPT) {
      var fp = flightplan();
      var no = getprop("autopilot/route-manager/current-wp")+1;
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
        }
      }
      line1.setText(sprintf("         STPT %02d   AUTO",no));
      line2.setText(sprintf("      LAT    %s",lat));
      line3.setText(sprintf("      LNG    %s",lon));
      line4.setText(sprintf("     ELEV    %5dFT",alt));
      line5.setText(sprintf("      TOS    %s","VOID"));
    } elsif (page == pTACAN) {
      var ilsOn  = "ON";
      var freq   = getprop("instrumentation/tacan/frequencies/selected-mhz");
      var chan   = getprop("instrumentation/tacan/frequencies/selected-channel");
      var band   = getprop("instrumentation/tacan/frequencies/selected-channel[4]");
      var course = getprop("instrumentation/tacan/in-range")?""~getprop("instrumentation/tacan/indicated-bearing-true-deg"):"";
      line1.setText(sprintf("     TCN  RC     ILS %s",ilsOn));
      line2.setText(sprintf("                        "));
      line3.setText(sprintf("               CMD STRG "));
      line4.setText(sprintf("CHAN    %03d FREQ %6.2f",chan,freq));
      line5.setText(sprintf("BAND      %s CRS %s",band,course));
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
      var friend = "NO CONN";
      if (sign != "" and (sign == getprop("link16/wingman-1") or sign == getprop("link16/wingman-2") or sign == getprop("link16/wingman-3") or sign == getprop("link16/wingman-4"))) {
        friend = "WINGMAN";
      }

      line1.setText(sprintf("     IFF                "));
      line2.setText(sprintf("                        "));
      line3.setText(sprintf("PILOT   %s",sign));
      line4.setText(sprintf("ID      %s",type));
      line5.setText(sprintf("Link16  %s",friend));
    } elsif (page == pALOW) {
      #signText.setText(ded);
    } elsif (page == pCNI) {
      var no = getprop("autopilot/route-manager/current-wp")+1;
      var freq   = getprop("instrumentation/comm["~comm~"]/frequencies/selected-mhz");
      var time   = getprop("/sim/time/gmt-string");
      var t      = getprop("instrumentation/tacan/display/channel");
      line1.setText(sprintf("UHF    --    STPT %02d",freq,no));
      line2.setText(sprintf(" COMM%d                   ",comm+1));
      line3.setText(sprintf("VHF  %6.2f   %s",freq,time));
      line4.setText(sprintf("                        "));
      line5.setText(sprintf("                  T%s",t));
    }
    settimer(loop_ded, 0.5);
};
callInit();
loop_ded();

var stpt = func {
  page = pSTPT;
}

var alow = func {
  #page = pALOW;
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

## these methods taken from JA37:
var convertDoubleToDegree = func (value) {
        var sign = value < 0 ? -1 : 1;
        var abs = math.abs(math.round(value * 1000000));
        var dec = math.fmod(abs,1000000) / 1000000;
        var deg = math.floor(abs / 1000000) * sign;
        var min = math.floor(dec * 60);
        var sec = math.round((dec - min / 60) * 3600);#TODO: unsure of this round()
        return [deg,min,sec];
}
var convertDegreeToStringLat = func (lat) {
  lat = convertDoubleToDegree(lat);
  var s = "N";
  if (lat[0]<0) {
    s = "S";
  }
  return sprintf("%02d %02d %02d%s",math.abs(lat[0]),lat[1],lat[2],s);
}
var convertDegreeToStringLon = func (lon) {
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