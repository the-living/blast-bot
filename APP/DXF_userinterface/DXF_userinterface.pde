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
import controlP5.*;
import processing.serial.*;

//------------------------------------------------------------------------------
// GLOBAL VARIABLES
//------------------------------------------------------------------------------

//UI Variables
ControlP5 cP5;
PFont font24, font18, font16i, font14, font12;
color black, white, grey, charcoal, green, red, blue;
PVector origin;

//File Variables
String currentPath;
String fullPath;
Boolean loaded;
Boolean processed;

//Command Variables
GCODEbuffer GB;
GCODEbuffer interrupt;
StringList lastVal;
String lastSent;
String timeLeft;
int geoCount;
int lastGeo;

//Operation Variables
float posx, posy, lastx, lasty;
float lastf;
Boolean paused;
Boolean override;

//Serial Variables
Serial myPort;
Boolean connected;
String port;


//------------------------------------------------------------------------------
// SETUP
//------------------------------------------------------------------------------
void setup(){
  settings();

  initVariables();
  initFonts();
  initColors();
  setupControls();

}

//------------------------------------------------------------------------------
// DRAW LOOP
//------------------------------------------------------------------------------
void draw(){
  displayUI();
  displayStats();
}

//------------------------------------------------------------------------------
// APP SETTINGS
//------------------------------------------------------------------------------
void settings(){
  size(1200,800);
}

void initVariables(){
  origin = new PVector(25,250);
  currentPath = "No file loaded.";
  loaded = false;
  processed = false;
  lastVal = new StringList("...");
  lastSent = "...";
  timeLeft = "0:00:00";
  geoCount = 0;
  lastGeo = 0;
  posx = 0.0;
  posy = 0.0;
  lastx = 0.0;
  lasty = 0.0;
  lastf = 25.0;
  paused = false;
  override = false;
  connected = false;
}