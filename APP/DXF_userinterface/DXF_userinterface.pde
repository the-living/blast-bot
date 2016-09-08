////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// blast-bot Sandblasting Robot | The Living | 2016                           //
// v.1 2016.08.30                                                             //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// UI Setup                                                                   //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

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
PShape preview;
float scalar = 0.5;

//File Variables
String currentPath;
String fullPath;
Boolean loaded;
Boolean processed;
JSONObject geojson;

//Color Setting Variables
JSONObject colorSettings;
JSONObject colorACD;
IntList colors;
Boolean colorLoaded;
String acdColor = "acd_2_hex.json";
int selectedColor;

//Command Variables
GCODEbuffer loader;
GCODEbuffer GB;
GCODEbuffer interrupt;

String timeLeft;
int geoCount;
int lastGeo;
String lineNum;

//Operation Variables
float posx, posy;
float lastf;
Boolean runPreview;
Boolean running;
Boolean paused;
Boolean override;
Float defaultSpeed;

//Serial Variables
Serial myPort;
String val;
StringList lastVal;
String lastSent;
Boolean connected;
String port;

//DEBUG
Boolean VERBOSE = false;


//------------------------------------------------------------------------------
// SETUP
//------------------------------------------------------------------------------
void setup() {
  settings();

  initVariables();
  initFonts();
  initColors();
  setupControls();

  //load ACD color conversion table
  colorACD = loadJSONObject( acdColor );

  //selectInput("Select DXF file: ", "fileSelection");

  serialConnect();
  checkFiles();
}

//------------------------------------------------------------------------------
// DRAW LOOP
//------------------------------------------------------------------------------
void draw() {
  displayUI();
  displayStats();

  checkStatus();
  monitorConnection();

  if ( preview != null && runPreview == false ) {
    preview.enableStyle();
    shape( preview, 0, 0);
    lastGeo = 0;
  } else if ( runPreview == true ) {
    lastGeo = min(lastGeo, geoCount);
    posx = 0;
    posy = 0;

    renderGCODE( loader, lastGeo );
    if (lastGeo < geoCount) {
      if (geoCount < 1000) {
        if (frameCount % 20 == 0) {
          lastGeo++;
        }
      } else {
        lastGeo++;
      }
    }
  }

  renderNozzle();
}

//------------------------------------------------------------------------------
// APP SETTINGS
//------------------------------------------------------------------------------
void settings() {
  size(1200, 800);
}

void initVariables() {
  origin = new PVector(25, 250);
  currentPath = "No file loaded.";
  loaded = false;
  colorLoaded = false;
  processed = false;

  loader = new GCODEbuffer();
  GB = new GCODEbuffer();
  interrupt = new GCODEbuffer();

  lastVal = new StringList("...");
  lastSent = "...";
  timeLeft = "0:00:00";
  geoCount = 0;
  lastGeo = 0;
  posx = 0.0;
  posy = 0.0;
  lastf = 25.0;
  defaultSpeed = 25.0;
  runPreview = false;
  running = false;
  paused = false;
  override = false;
  connected = false;
}