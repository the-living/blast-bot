// /////////////////////////////////////////////////////////////////////////////
//
// brush-bot Drawing Robot | The Living | 2016
//
// /////////////////////////////////////////////////////////////////////////////
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

//------------------------------------------------------------------------------
// VARIABLES
//------------------------------------------------------------------------------

//initialize Serial connection
// https://processing.org/reference/libraries/serial/Serial.html
Serial myPort; //create a serial port object

//communication buffers
String val; //create a buffer to hold RX data from serial port
ArrayList<String> lastVal;
String lastSent = "";
GCodeBuffer GB; //buffer for TX GCode Commands
int lineCount = 0; //index to keep track of multi-line commands

//initialize UX objects
ControlP5 cP5; //controlP5 object
PFont fontL, fontM, fontS; //controller fonts

// plotter dimensions
// all distances are measured relative to the calibration point of the plotter
// (normally, this is located in the center of the drawing)
// measurement is in millimeters
float limit_top = 585.0; //top edge
float limit_bottom = -585.0; //bottom edge
float limit_right = 570.0; // right edge
float limit_left = -570.0; // left edge
float draw_speed = 20.0;
float fast_speed = 0.0;

//plotter position
float posx, posy;

//array for issuing individual motor commands
boolean[] motors = new boolean[4];

//Strings for displaying board names
String boardName;
boolean L_blast = false;
boolean R_blast = false;
boolean L_clean = false;
boolean R_clean = false;

PShape Lboard_svg;
PShape Rboard_svg;


//------------------------------------------------------------------------------
// SETUP
//------------------------------------------------------------------------------
void setup() {

  //Processing 2/3 compatibility
  settings();

  background(mainColor);

  lastVal = new ArrayList<String>();

  //SERIAL CONNECTION
  String portName = Serial.list()[0];
  myPort = new Serial(this, portName, 115200);

  //GCODE BUFFER - ArrayList for TX commands
  GB = new GCodeBuffer();

  //INITIALIZE MOTOR CONTROL ARRAY
  motors[0] = false; //x-axis
  motors[1] = false; //y-axis

  //INITIALIZE PLOTTER position
  posx = 0;
  posy = 0;

  //UX FONTS
  fontL = loadFont("Roboto-28.vlw");
  fontM = loadFont("Roboto-18.vlw");
  fontS = loadFont("Roboto-12.vlw");
  //INITIALIZE UX
  cP5 = new ControlP5(this);
  setupControls();
  
  
  checkFiles();
  //SET DEFAULT FONT
  //textFont(fontM);
}

//------------------------------------------------------------------------------
// SETTINGS
//------------------------------------------------------------------------------
void settings() {

  size(1380, 900);
}

//------------------------------------------------------------------------------
// DRAW
//------------------------------------------------------------------------------
void draw() {

  //checkFiles();

  //fill(mainColor);
  //rect(0,820,height,820);
  background(mainColor);

  fill(255);
  rect(810, 0, width, height);

  fill(0);
  textFont( fontL, 50 );
  text(boardName, 850, 90);
  
  float scalar = 500.0 / Lboard_svg.width;
  shape(Lboard_svg, 850, 265, Lboard_svg.width*scalar, Lboard_svg.height*scalar);
  if (R_clean) {
    shape(Rboard_svg, 1350, 485, Rboard_svg.width*scalar, Rboard_svg.height*scalar);
  }

  fill(0);
  rect(0, 600, 800, 300);

  noFill();
  rect(25, 25, 550, 550);

  //TX-RX over Serial port
  serialRun();
  stroke(255);
  line(0, 700, 800, 700);
  noStroke();
  
  textFont(fontM, 22);
  fill(0,255,0);
  text(lastSent, 50, 730);
  
  fill(255, 0, 0);
  for ( int i = 0; i < lastVal.size(); i++ ) {
    text(lastVal.get(i), 50, 760+i*28);
  }
}

//Serial Port Communication
//Checks if serial port has available data
//if data is a "READY" signal from the Arduino
//checks if commands are available to send
//ifso, commands are written to serial port
void serialRun() {

  if (myPort.available() > 0) {
    val = myPort.readString();

    //Arduino firmware signals readiness with a ">"
    if (val.equals("\n> ") ) {
      //println( val );
      lastSent="";
      //Check if the GCodeBuffer contains commands
      if ( GB.size() > 0 ) {
        String s = GB.sendNext();
        myPort.write(s);
        //Echo command to debug panel
        println("sent: " + s);
        lastSent = s;
      }
    } else {
      println( "recieved: " + val );

      if (val.length() > 0 && val != " ") {
        String[] temp = split(val, "\n");
        lastVal.clear();
        for (int i = 0; i < temp.length; i++) {
          if (temp[i].length() > 1) {
            lastVal.add(temp[i]);
          }
        }
      }
    }
  }
}