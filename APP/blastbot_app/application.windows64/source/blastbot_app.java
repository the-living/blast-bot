import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import controlP5.*; 
import processing.serial.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class blastbot_app extends PApplet {

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


// Default Serial library
// https://processing.org/reference/libraries/serial/


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
float limit_top = 585.0f; //top edge
float limit_bottom = -585.0f; //bottom edge
float limit_right = 570.0f; // right edge
float limit_left = -570.0f; // left edge
float draw_speed = 20.0f;
float fast_speed = 0.0f;

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
public void setup() {

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
public void settings() {

  size(1380, 900);
}

//------------------------------------------------------------------------------
// DRAW
//------------------------------------------------------------------------------
public void draw() {

  //checkFiles();

  //fill(mainColor);
  //rect(0,820,height,820);
  background(mainColor);

  fill(255);
  rect(810, 0, width, height);

  fill(0);
  textFont( fontL, 50 );
  text(boardName, 850, 90);
  
  float scalar = 500.0f / Lboard_svg.width;
  shape(Lboard_svg, 850, 215, Lboard_svg.width*scalar, Lboard_svg.height*scalar);

  if (!R_blast) {
    shape(Rboard_svg, 850, 415, -Rboard_svg.width*scalar, Rboard_svg.height*scalar);
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
public void serialRun() {

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
//GCODE BUFFER CLASS
//ArrayList object containing GCODE commands to be
//passed to Arduino. Functions allow for commands to
//be added and extracted on a FIFO (First in, First out) basis

class GCodeBuffer {
  
  ArrayList<String> GCode = new ArrayList<String>();
  
  //Initializer
  GCodeBuffer(){
    
  }
  
  //WRITE function
  //for adding GCode command to buffer
  public void write( String code ){
    String gcode;
    
    //***NOTE***//
    //Line numbers and checksums have been disabled for
    //single-pass testing
    
    //Generate Line Number
    //String ln = "N" + str( GCode.size());
    //gcode = ln + " " + code;
    
    //String cs = generateChecksum(gcode);
    //gcode += cs;
    
    gcode = code + "\n";
    
    GCode.add(gcode);
  }
  
  //SEND NEXT function
  //Returns next available command as String
  //on FIFO basis and removes it from the buffer
  public String sendNext () {
    String r = GCode.get(0);
    GCode.remove(0);
    
    return r;
  }
  
  //GET END function
  //Returns whether buffer is empty
  public boolean getEnd() {
    return GCode.size() <= 0;
  }
  
  //FLUSH BUFFER function
  //Clears buffer
  public void flushBuffer(){
    for (int i = GCode.size() - 1; i >= 0; i--){
      GCode.remove(i);
    }
  }
  
  //SIZE function
  //Returns length of Buffer
  public int size(){
    return GCode.size();
  }

}
//G00/G01 - LINE COMMAND
public String gcodeLine(float x, float y, boolean spray){
  if( spray ) return "G01 X" + str(x) + " Y" + str(y);
  else return "G00 X" + str(x) + " Y" + str(y);
}

//G02/G03 - ARC COMMANDS
public String gcodeArc(float cx, float cy, float x, float y, boolean dir){
  //clockwise
  if( dir ) return "G02 I" + str(cx) + " J" + str(cy) + " X" + str(x) + " Y" + str(y);
  else return "G03 I" + str(cx) + " J" + str(cy) + " X" + str(x) + " Y" + str(y);
}

//G04 - PAUSE COMMAND
public String gcodePause( int time ){
  return "G04 P" + str(time);
}

//G05 - DWELL COMMAND
public String gcodeDwell( int time ){
  return "G05 P" + str(time);
}

//M00 - DISABLE ALL MOTORS COMMAND
public String gcodeRelativeMove(int x_step, int y_step){
  return "M00 X" + x_step + " Y" + y_step;
}

//M10-M20 FORWARD JOG MOTOR
public String gcodeMotorForward( int motor, int dist ){
  switch( motor ){
    case 1: return "M10 S" + dist; //Motor X
    case 2: return "M20 S" + dist; //Motor Y
    default: return "";
  }
}

//M11-M21 BACKWARD JOG MOTOR
public String gcodeMotorBackward( int motor, int dist ){
  switch( motor ){
    case 1: return "M11 S" + dist; //Motor X
    case 2: return "M21 S" + dist; //Motor Y
    default: return "";
  }
}

//M15-M25-M35-M45 STEP MOTOR +1
public String gcodeStepForward( int motor ){
  switch( motor ){
    case 1: return "M15"; //Motor X
    case 2: return "M25"; //Motor Y
    default: return "";
  }
}

//M16-M26-M36-M46 ENABLE MOTOR
public String gcodeStepBackward( int motor ){
  switch( motor ){
    case 1: return "M16"; //Motor 1
    case 2: return "M26"; //Motor 2
    case 3: return "M36"; //Motor 3
    case 4: return "M46"; //Motor 4
    default: return "";
  }
}

//M50 BLAST ON
public String gcodeBlastOn(){
  return "M50";
}

//M51 BLAST OFF
public String gcodeBlastOff(){
  return "M51";
}

//M60 AIR ON
public String gcodeAirOn(){
  return "M60";
}

//M61 AIR OFF
public String gcodeAirOff(){
  return "M61";
}



//M100 Teleport
public String gcodeTeleportOrigin(){
  return "M100";
}

public String gcodeTeleportTo( float x, float y ){
  return "M100 X" + str(x) + " Y" + str(y);
}

public String gcodeSpeedSetting( float s ){
  return "D10 S" + str(s);
}
//---------------------------------------------------------------------------
//
// ControlP5 UX Objects Behavior
//
//---------------------------------------------------------------------------

//CONTROLP5 INTERFACE CONTROLS
//Functions are handled via triggering "events"
public void controlEvent( ControlEvent theEvent ) {

  if ( theEvent.isController() ) {

    //MANUAL GCODE ENTRY
    //--------------------------------------------------------------------------
    if ( theEvent.getName().equals("cmd_entry") ) {

      //pull value from text entry box
      String cmd = cP5.get(Textfield.class, "cmd_entry").getText();
      GB.write( cmd );
    }

    //RESET ORIGIN
    //--------------------------------------------------------------------------
    if ( theEvent.getName().equals("teleport") ) {
      String cmd = gcodeTeleportOrigin();
      GB.write( cmd );
      //reset position VARIABLES
      posx = 0;
      posy = 0;
    }

    //RUN TEST PATTERN
    //--------------------------------------------------------------------------
    if ( theEvent.getName().equals("test_pattern") ) {

      String lines[] = loadStrings("toRun.txt");
      for (int i = 0; i < lines.length; i++) {
        GB.write( lines[i] );
      }
      
    }
    
    //GCODE File Handling
    //--------------------------------------------------------------------------
    //REFRESH
    if( theEvent.getName().equals("refresh") ){
       checkFiles();
    }
    
    //RUN L CLEAN
    if ( theEvent.getName().equals("run_l_clean") ) {

      String lines[] = loadStrings("L_CLEAN.txt");
      for (int i = 0; i < lines.length; i++) {
        GB.write( lines[i] );
      }
      
    }
    
    //RUN L BLAST
    if ( theEvent.getName().equals("run_l_blast") ) {

      String lines[] = loadStrings("L_BLAST.txt");
      for (int i = 0; i < lines.length; i++) {
        GB.write( lines[i] );
      }
      
    }
    
    //RUN R CLEAN
    if ( theEvent.getName().equals("run_r_clean") ) {

      String lines[] = loadStrings("R_CLEAN.txt");
      for (int i = 0; i < lines.length; i++) {
        GB.write( lines[i] );
      }
      
    }
    
    //RUN R BLAST
    if ( theEvent.getName().equals("run_r_blast") ) {

      String lines[] = loadStrings("R_BLAST.txt");
      for (int i = 0; i < lines.length; i++) {
        GB.write( lines[i] );
      }
      
    }



    // JOGGING
    //--------------------------------------------------------------------------
    //FORWARD JOG
    if ( theEvent.getName().equals("jog_forward") ) {
      //update motor selection array
      motors[0] = cP5.get( Toggle.class, "x").getState();
      motors[1] = cP5.get( Toggle.class, "y").getState();

      for ( int i = 0; i < motors.length; i++ ) {
        if ( motors[i] ) {
          String cmd = gcodeMotorForward( i + 1, 1 );
          GB.write( cmd );
        }
      }
    }

    //BACKWARD JOG
    if ( theEvent.getName().equals("jog_backward") ) {
      //update motor selection array
      motors[0] = cP5.get( Toggle.class, "x").getState();
      motors[1] = cP5.get( Toggle.class, "y").getState();

      for ( int i = 0; i < motors.length; i++ ) {
        if ( motors[i] ) {
          String cmd = gcodeMotorBackward( i + 1, 1 );
          GB.write( cmd );
        }
      }
    }

    //FORWARD JOG
    if ( theEvent.getName().equals("jog_forward_ff") ) {
      //update motor selection array
      motors[0] = cP5.get( Toggle.class, "x").getState();
      motors[1] = cP5.get( Toggle.class, "y").getState();

      for ( int i = 0; i < motors.length; i++ ) {
        if ( motors[i] ) {
          String cmd = gcodeMotorForward( i + 1, 5 );
          GB.write( cmd );
        }
      }
    }

    //BACKWARD JOG
    if ( theEvent.getName().equals("jog_backward_ff") ) {
      //update motor selection array
      motors[0] = cP5.get( Toggle.class, "x").getState();
      motors[1] = cP5.get( Toggle.class, "y").getState();

      for ( int i = 0; i < motors.length; i++ ) {
        if ( motors[i] ) {
          String cmd = gcodeMotorBackward( i + 1, 5 );
          GB.write( cmd );
        }
      }
    }


    // MOTOR ENABLING
    //--------------------------------------------------------------------------
    //DISENGAGE MOTOR(S)
    if ( theEvent.getName().equals("step_f") ) {
      //update motor selection array
      motors[0] = cP5.get( Toggle.class, "x").getState();
      motors[1] = cP5.get( Toggle.class, "y").getState();

      for ( int i = 0; i < motors.length; i++ ) {
        if ( motors[i] ) {
          String cmd = gcodeStepForward( i + 1 );
          GB.write( cmd );
        }
      }
    }

    //ENGAGE MOTOR(S)
    if ( theEvent.getName().equals("step_b") ) {
      //update motor selection array
      motors[0] = cP5.get( Toggle.class, "x").getState();
      motors[1] = cP5.get( Toggle.class, "y").getState();

      for ( int i = 0; i < motors.length; i++ ) {
        if ( motors[i] ) {
          String cmd = gcodeStepBackward( i + 1 );
          GB.write( cmd );
        }
      }
    }

    // SPRAYER COMMANDS
    //--------------------------------------------------------------------------
    // ENABLE BLAST
    if ( theEvent.getName().equals("blast_on") ) {
      String cmd = gcodeBlastOn();
      GB.write( cmd );
    }
    // DISABLE BLAST
    if ( theEvent.getName().equals("blast_off") ) {
      String cmd = gcodeBlastOff();
      GB.write( cmd );
    }
    
    // ENABLE AIR
    if ( theEvent.getName().equals("air_on") ) {
      String cmd = gcodeAirOn();
      GB.write( cmd );
    }
    // DISABLE AIR
    if ( theEvent.getName().equals("air_off") ) {
      String cmd = gcodeAirOff();
      GB.write( cmd );
    }
    
    // SPEED COMMANDS
    //--------------------------------------------------------------------------
    // FAST MODE
    if ( theEvent.getName().equals("fast_mode") ) {
      String cmd;
      
      if( cP5.get(Toggle.class, "fast_mode").getValue()==1 ){
        cmd = gcodeSpeedSetting( fast_speed );
      } else{
        cmd = gcodeSpeedSetting( draw_speed );
      }
      
      GB.write( cmd );
    }

    // AXIAL MOVE COMMANDS
    //--------------------------------------------------------------------------
    // GO HOME
    if ( theEvent.getName().equals("go_home") ) {
      posx = 0;
      posy = 0;
      String cmd = gcodeLine(posx, posy, false);
      GB.write( cmd );
    }
    
    // X+100 MOVE
    if ( theEvent.getName().equals("x_100") ) {
      //posx += 100;
      //String cmd = gcodeLine(posx, posy, false);
      String cmd = gcodeRelativeMove(100, 0);
      GB.write( cmd );
    }

    // X+10 MOVE
    if ( theEvent.getName().equals("x_10") ) {
      //posx += 10;
      //String cmd = gcodeLine(posx, posy, false);
      String cmd = gcodeRelativeMove(10, 0);
      GB.write( cmd );
    }

    // X-100 MOVE
    if ( theEvent.getName().equals("x_-100") ) {
      //posx -= 100;
      //String cmd = gcodeLine(posx, posy, false);
      String cmd = gcodeRelativeMove(-100, 0);
      GB.write( cmd );
    }

    // X-10 MOVE
    if ( theEvent.getName().equals("x_-10") ) {
      //posx -= 10;
      //String cmd = gcodeLine(posx, posy, false);
      String cmd = gcodeRelativeMove(-10, 0);
      GB.write( cmd );
    }
    // Y+100 MOVE
    if ( theEvent.getName().equals("y_100") ) {
      //posy += 100;
      //String cmd = gcodeLine(posx, posy, false);
      String cmd = gcodeRelativeMove(0, 100);
      GB.write( cmd );
    }

    // Y+10 MOVE
    if ( theEvent.getName().equals("y_10") ) {
      //posy += 10;
      //String cmd = gcodeLine(posx, posy, false);
      String cmd = gcodeRelativeMove(0, 10);
      GB.write( cmd );
    }

    // Y-100 MOVE
    if ( theEvent.getName().equals("y_-100") ) {
      //posy -= 100;
      //generate G00 command to position X+100
      //String cmd = gcodeLine(posx, posy, false);
      String cmd = gcodeRelativeMove(0, -100);
      GB.write( cmd );
    }

    // Y-10 MOVE
    if ( theEvent.getName().equals("y_-10") ) {
      //posy -= 10;
      //generate G00 command to position X+100
      //String cmd = gcodeLine(posx, posy, false);
      String cmd = gcodeRelativeMove(0, -10);
      GB.write( cmd );
    }
  }
}
//---------------------------------------------------------------------------
//
// ControlP5 UX Objects Setup
//
//---------------------------------------------------------------------------

public void setupControls(){
  //global control panel settings
  cP5.setFont( fontS );
  cP5.setColorForeground( fgColor );
  cP5.setColorBackground( bgColor );
  cP5.setColorValueLabel( bgColor );
  cP5.setColorCaptionLabel( bgColor );
  cP5.setColorActive( activeColor );

  //MANUAL COMMAND ENTRY
  //---------------------------------------------------------------------------
  //Issues typed out GCODE command
  cP5.addTextfield("cmd_entry")
  .setPosition( 50, 620 )
  .setSize( 700, 50 )
  .setFont( fontL )
  .setFocus( true )
  .setColor( color(0) )
  .setAutoClear( true )
  //caption settings
  .getCaptionLabel()
  .setColor(255)
  .setFont(fontM)
  .alignX(ControlP5.LEFT)
  .setText("Manual GCODE Entry")
  ;
  
  //FILE CONTROLS
  cP5.addBang("refresh")
  .setPosition(850,100)
  .setSize(250, 25)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontM)
  .setText("REFRESH")
  ;
  
  cP5.addBang("run_l_clean")
  .setPosition(850,225)
  .setSize(500, 45)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontM)
  .setText("RUN L CLEANING")
  ;
  
  cP5.addBang("run_l_blast")
  .setPosition(850,275)
  .setSize(500, 45)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontL)
  .setText("RUN L BLASTING")
  ;
  
  cP5.addBang("run_r_clean")
  .setPosition(850,425)
  .setSize(500, 45)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontM)
  .setText("RUN R CLEANING")
  ;
  
  cP5.addBang("run_r_blast")
  .setPosition(850,475)
  .setSize(500, 45)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontL)
  .setText("RUN R BLASTING")
  ;

  //MOTOR TOGGLES
  //---------------------------------------------------------------------------
  //X-AXIS TOGGLE - Top-Left
  cP5.addToggle("x")
  .setPosition(50, 50)
  .setSize(50, 50)
  //caption settings
  .getCaptionLabel()
  .alignX(ControlP5.LEFT)
  .setColor(0)
  .setFont(fontM)
  .setText("X")
  ;
  //Y-AXIS TOGGLE - Top-Right
  cP5.addToggle("y")
  .setPosition(500, 50)
  .setSize(50, 50)
  //caption settings
  .getCaptionLabel()
  .alignX(ControlP5.RIGHT)
  .setColor(0)
  .setFont(fontM)
  .setText("Y")
  ;

  //MOTOR JOGGING
  //---------------------------------------------------------------------------
  //JOG FORWARD BUTTON
  //Send jog forward signal to all selected motors
  cP5.addBang("jog_forward")
  .setPosition(600, 50)
  .setSize(95, 45)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontM)
  .setText("F")
  ;

  //JOG BACKWARD BUTTON
  //Send jog backward signal to all selected motors
  cP5.addBang("jog_backward")
  .setPosition(600, 100)
  .setSize(95, 45)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontM)
  .setText("RW")
  ;
  
  //JOG FORWARD BUTTON
  //Send jog forward signal to all selected motors
  cP5.addBang("jog_forward_ff")
  .setPosition(700, 50)
  .setSize(95, 45)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontM)
  .setText("FF")
  ;

  //JOG BACKWARD BUTTON
  //Send jog backward signal to all selected motors
  cP5.addBang("jog_backward_ff")
  .setPosition(700, 100)
  .setSize(95, 45)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontM)
  .setText("FRW")
  ;

  //MOTOR ENABLE/DISABLE
  //---------------------------------------------------------------------------
  //DISABLE BUTTON
  //Send disengage signal to all selected motors
  cP5.addBang("step_f")
  .setPosition(600, 200)
  .setSize(98, 50)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("STEP+")
  ;

  //ENABLE BUTTON
  //Send engage signal to all selected motors
  cP5.addBang("step_b")
  .setPosition(702, 200)
  .setSize(98, 50)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("STEP-")
  ;

  //SPRAYER ENABLE/DISABLE
  //---------------------------------------------------------------------------
  //DISABLE BUTTON
  //Turns off blast
  cP5.addBang("blast_off")
  .setPosition(600, 275)
  .setSize(98, 50)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("BLAST OFF")
  ;

  //ENABLE BUTTON
  //Turns on sprayer
  cP5.addBang("blast_on")
  .setPosition(702, 275)
  .setSize(98, 50)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("BLAST ON")
  ;
  //DISABLE BUTTON
  //Turns off sprayer
  cP5.addBang("air_off")
  .setPosition(600, 330)
  .setSize(98, 50)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("AIR OFF")
  ;

  //ENABLE BUTTON
  //Turns on sprayer
  cP5.addBang("air_on")
  .setPosition(702, 330)
  .setSize(98, 50)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("AIR ON")
  ;

  //INITIAL SPOOL UP
  //---------------------------------------------------------------------------

  //Send teleport signal
  cP5.addToggle("fast_mode")
  .setPosition(600, 400)
  .setSize(200, 45)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(0)
  .setFont(fontM)
  .setText("FAST MODE")
  ;

  //TELEPORT
  //---------------------------------------------------------------------------

  //Send teleport signal
  cP5.addBang("teleport")
  .setPosition(600, 450)
  .setSize(200, 45)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontM)
  .setText("SET ORIGIN (0,0)")
  ;
  
  //TEST PATTERN
  //---------------------------------------------------------------------------

  //Send test pattern signal
  cP5.addBang("test_pattern")
  .setPosition(600, 500)
  .setSize(200, 45)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontM)
  .setText("RUN TEST PATTERN")
  ;

  //AXIAL MOVE COMMANDS
  //---------------------------------------------------------------------------

  //GO HOME
  cP5.addBang("go_home")
  .setPosition(250,250)
  .setSize(100,100)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("GO HOME")
  ;
  
  //X +100 BUTTON
  cP5.addBang("x_100")
  .setPosition(500, 275)
  .setSize(50, 50)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("X +100")
  ;

  //X +10 BUTTON
  cP5.addBang("x_10")
  .setPosition(445, 275)
  .setSize(50, 50)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("X +10")
  ;

  //X -100 BUTTON
  cP5.addBang("x_-100")
  .setPosition(50, 275)
  .setSize(50, 50)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("X -100")
  ;

  //X -10 BUTTON
  cP5.addBang("x_-10")
  .setPosition(105, 275)
  .setSize(50, 50)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("X -10")
  ;

  //X +100 BUTTON
  cP5.addBang("y_100")
  .setPosition(275, 50)
  .setSize(50, 50)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("Y +100")
  ;

  //Y +10 BUTTON
  cP5.addBang("y_10")
  .setPosition(275, 105)
  .setSize(50, 50)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("Y +10")
  ;

  //Y -100 BUTTON
  cP5.addBang("y_-100")
  .setPosition(275,500)
  .setSize(50, 50)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("Y -100")
  ;

  //Y -10 BUTTON
  cP5.addBang("y_-10")
  .setPosition(275, 445)
  .setSize(50, 50)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("Y -10")
  ;
}
//CHECKSUM GENERATOR
//Used to ensure no data loss in transfer
//when issuing multiple commands
protected String generateChecksum(String line) {
  byte checksum=0;
  for ( int i=0; i<line.length (); ++i ) {
    checksum ^= line.charAt(i);
  }
  return "*"+((int)checksum);
}

public void checkFiles(){
  //load board name
  boardName = loadStrings("LOADED_BOARD.txt")[0].substring(3);
  
  String[] temp;
  //check L-BLAST FILE
  temp = loadStrings("L_BLAST.txt");
  L_blast = temp.length > 3;
  cP5.get(Bang.class, "run_l_blast").setLock(!L_blast);
  if( !L_blast ){
    cP5.get(Bang.class, "run_l_blast").setColorForeground(lockColor);
    cP5.get(Bang.class, "run_l_blast").setColorActive(lockColor);
  } else {
    cP5.get(Bang.class, "run_l_blast").setColorForeground(fgColor);
    cP5.get(Bang.class, "run_l_blast").setColorActive(activeColor);
  }
  
  //check R-BLAST FILE
  temp = loadStrings("R_BLAST.txt");
  R_blast = temp.length > 3;
  cP5.get(Bang.class, "run_r_blast").setLock(!R_blast);
  if( !R_blast ){
    cP5.get(Bang.class, "run_r_blast").setColorForeground(lockColor);
    cP5.get(Bang.class, "run_r_blast").setColorActive(lockColor);
  } else {
    cP5.get(Bang.class, "run_r_blast").setColorForeground(fgColor);
    cP5.get(Bang.class, "run_r_blast").setColorActive(activeColor);
  }

  //check L-CLEAN FILE
  temp = loadStrings("L_CLEAN.txt");
  L_clean = temp.length > 3;
  cP5.get(Bang.class, "run_l_clean").setLock(!L_clean);
  if( !L_clean ){
    cP5.get(Bang.class, "run_l_clean").setColorForeground(lockColor);
    cP5.get(Bang.class, "run_l_clean").setColorActive(lockColor);
  } else {
    cP5.get(Bang.class, "run_l_clean").setColorForeground(fgColor);
    cP5.get(Bang.class, "run_l_clean").setColorActive(activeColor);
  }
  
  //check R-CLEAN FILE
  temp = loadStrings("R_CLEAN.txt");
  R_clean = temp.length > 3;
  cP5.get(Bang.class, "run_r_clean").setLock(!R_clean);
  if( !R_clean ){
    cP5.get(Bang.class, "run_r_clean").setColorForeground(lockColor);
    cP5.get(Bang.class, "run_r_clean").setColorActive(lockColor);
  } else {
    cP5.get(Bang.class, "run_r_clean").setColorForeground(fgColor);
    cP5.get(Bang.class, "run_r_clean").setColorActive(activeColor);
  }
  
  //update SVGS
  Lboard_svg = loadShape("svgOut_L.svg");
  Rboard_svg = loadShape("svgOut_R.svg");
}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "blastbot_app" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
