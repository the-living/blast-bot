// /////////////////////////////////////////////////////////////////////////////
//
// blast-bot Sandblasting Robot | The Living | 2016
// v.1 2016.08.30
//
// /////////////////////////////////////////////////////////////////////////////
// 
// Imports and processes DXF files for CNC blasting
//
// Sample GCode Format
// N00 G01 X100.0 F50.0*4
// N- : indicates line number of command (for multiple commands)
// G- : indicates type of action to be performed
// X- : input for the G01 command - the X-position to move to
// *n : checksum value for confirming valid data (only for commands w/ line numbers)
// /////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// EXTERNAL DEPENDENCIES
//------------------------------------------------------------------------------
// ControlP5 library
// http://www.sojamo.de/libraries/controlP5/
import controlP5.*;

// Default Serial library
// https://processing.org/reference/libraries/serial/
import processing.serial.*;

//------------------------------------------------------------------------------
// CONSTANTS
//------------------------------------------------------------------------------

//UI COLORS (Buttons & Sliders)
int mainColor = color(200); //background color
int bgColor = color(255); //UX background color
int fgColor = color(0); //UX foreground color
int activeColor = color(80, 150, 225); //UX hover color
int lockColor = color(120, 120, 120); //UX inactive color
int pauseColor = color(237, 28, 36);
int resumeColor = color(0, 161, 75);

//------------------------------------------------------------------------------
// VARIABLES
//------------------------------------------------------------------------------

//initialize Serial connection
// https://processing.org/reference/libraries/serial/Serial.html
Serial myPort; //create a serial port object
boolean connected = false;
String port;


//communication buffers
String val; //create a buffer to hold RX data from serial port
ArrayList<String> lastVal;
String lastSent = "";
String currentPath = "";
String timeLeft = "";
String lineNum = "";
GCodeBuffer GB; //buffer for TX GCode Commands
GCodeBuffer interrupt; //buffer for interrupt GCode commands
int lineCount = 0; //index to keep track of multi-line commands

Boolean paused = false;
Boolean override = false;

Boolean metric = true;
float mm2in = 25.4;

//initialize UX objects
ControlP5 cP5; //controlP5 object
PFont fontL, fontM, fontS; //controller fonts


//plotter position
float posx, posy, lastx, lasty = 0.0;
float lastf = 50.0;

//board settings
float bHeight, bWidth, spacing, speed;

//array for issuing individual motor commands
boolean[] motors = new boolean[2];


//------------------------------------------------------------------------------
// SETUP
//------------------------------------------------------------------------------
void setup() {

  //Processing 2/3 compatibility
  settings();

  background(mainColor);

  lastVal = new ArrayList<String>();

  //GCODE BUFFER - ArrayList for TX commands
  GB = new GCodeBuffer();
  interrupt = new GCodeBuffer();

  //INITIALIZE MOTOR CONTROL ARRAY
  motors[0] = false; //x-axis
  motors[1] = false; //y-axis

  setupControls();
  
  //update board dimensions
  updateBoardDims();
  
  //SERIAL CONNECTION
  serialConnect();

}

//------------------------------------------------------------------------------
// SETTINGS
//------------------------------------------------------------------------------
void settings() {

  size(1380, 800);
}

//------------------------------------------------------------------------------
// DRAW
//------------------------------------------------------------------------------
void draw() {

  background(mainColor);
  
  renderConsole();
  monitorConnection();
  
}