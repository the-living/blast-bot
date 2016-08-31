// /////////////////////////////////////////////////////////////////////////////
//
// blast-bot Sandblasting Robot | The Living | 2016
// v.1 2016.08.30
//
// /////////////////////////////////////////////////////////////////////////////
// 
// UI Setup
//
// /////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// EXTERNAL DEPENDENCIES
//------------------------------------------------------------------------------
// ControlP5 library
// http://www.sojamo.de/libraries/controlP5/
import controlP5.*;

//UI Variables
ControlP5 cP5;
PFont font24, font18, font16i, font14, font12;
color black, white, grey, charcoal, green, red, blue;
PVector origin = new PVector(25,250);

//File Variables
String currentPath = "TEST.DXF";
StringList lastVal = new StringList("TEST RX");
String lastSent = "G00 X0 Y0 F1.0";
String timeLeft = "0:00:00";
int geoCount = 0;
int lastGeo = 0;

//Operation Variables
float posx, posy, lastx, lasty = 0.0;
float lastf = 50.0;

void setup(){
  settings();
  
  initFonts();
  initColors();
  setupControls();
  
}

void draw(){
  displayUI();
  displayStats();
  
  
}

void settings(){
  size(1200,800);
}