// /////////////////////////////////////////////////////////////////////////////
//
// blast-bot Sandblasting Robot | The Living | 2016
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

  //INITIALIZE PLOTTER position

  //UX FONTS
  fontL = loadFont("Roboto-28.vlw");
  fontM = loadFont("Roboto-18.vlw");
  fontS = loadFont("Roboto-12.vlw");
  //INITIALIZE UX
  cP5 = new ControlP5(this);
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

  //fill(mainColor);
  //rect(0,820,height,820);
  background(mainColor);

  //RIGHT BOARD CONSOLE
  fill(255);
  rect(610, 0, width, height);

  fill(0);
  textFont( fontL, 50 );
  text("BOARD BLASTER", 650, 45);

  //SVG preview of board
  float scalar = 0.25;
  
  rectMode(CORNERS);
  stroke(0);
  strokeWeight(2);
  noFill();
  if (metric){
    rect(650, 550, 650+(bWidth*scalar), 550-(bHeight*scalar));
  } else {
    rect(650, 550, 650+(bWidth*mm2in*scalar), 550-(bHeight*mm2in*scalar));
  }
  
  rectMode(CORNER);
  
  
  //visualize blast nozzle position
  stroke(0);
  fill(color(255, 222, 23, 200));
  float nozzleX = 650 + posx*scalar;
  float nozzleY = 550 - posy*scalar;

  strokeWeight(3);
  ellipse(nozzleX, nozzleY, 10, 10);
  noFill();
  strokeWeight(0.5);
  ellipse(nozzleX, nozzleY, 20, 20);
  
  
  //CURRENT PASS INFO
  stroke(0);
  line(650, 610, 1350, 610);
  textFont( fontL, 24);
  fill(0);
  String pos = "( X: " + posx + "   Y: " + posy + " )";
  text(pos, 650, 600);
  textFont( fontM, 24);
  text("LINE NUMBER: " + lineNum, 650, 640);
  text("TIME LEFT: " + timeLeft, 650, 670);

  //JOG CONTROLLER OUTLINE
  noFill();
  stroke(255);
  rect(25, 25, 350, 350);

  //CONSOLE AREA (BLACK)
  fill(0);
  noStroke();
  rect(0, 400, 600, 500);
  
  if (!connected){
    serialConnect();
    fill(pauseColor);
    textFont( fontS, 18);
    text("NOT CONNECTED",25,775);
  } else {
    serialRun();
    fill(resumeColor);
    textFont( fontS, 18);
    text("CONNECTED ON " + port, 25, 775);
  }

  //TX-RX over Serial port
  stroke(255);
  line(0, 500, 600, 500);
  noStroke();

  //PRINT OUT LAST SENT CODE IN GREEN
  textFont(fontM, 22);
  fill(0, 255, 0);
  text(lastSent, 25, 530);

  //PRINT OUT LAST RECIEVED CODE IN RED
  fill(255, 0, 0);
  for ( int i = 0; i < lastVal.size(); i++ ) {
    text(lastVal.get(i), 25, 560+i*28);
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

      lastSent="";

      //Check if paused
      if (!paused) {
        if ( interrupt.size() > 0 ) {
          String s = interrupt.sendNext();
          myPort.write(s);
          println("sent: " + s);
          lastSent = s;
        }
        //check if commands are available
        else if ( GB.size() > 0 ) {
          String s = GB.sendNext();
          myPort.write(s);
          //Echo command to debug panel
          println("sent: " + s);
          lastSent = s;
        } else {
          //currentPath = "";
          timeLeft = "";
          lineNum = "";
        }
      } else {
        //check if interrupt commands are available
        if ( interrupt.size() > 0 ) {
          String s = interrupt.sendNext();
          myPort.write(s);
          //Echo command to debug panel
          //println("sent: " + s);
          lastSent = s;
        }
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