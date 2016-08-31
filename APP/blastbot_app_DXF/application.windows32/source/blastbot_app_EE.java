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

public class blastbot_app_EE extends PApplet {

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
float mm2in = 25.4f;

//initialize UX objects
ControlP5 cP5; //controlP5 object
PFont fontL, fontM, fontS; //controller fonts


//plotter position
float posx, posy, lastx, lasty = 0.0f;
float lastf = 50.0f;

//board settings
float bHeight, bWidth, spacing, speed;

//array for issuing individual motor commands
boolean[] motors = new boolean[2];


//------------------------------------------------------------------------------
// SETUP
//------------------------------------------------------------------------------
public void setup() {

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
public void settings() {

  size(1380, 800);
}

//------------------------------------------------------------------------------
// DRAW
//------------------------------------------------------------------------------
public void draw() {

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
  float scalar = 0.25f;
  
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
  strokeWeight(0.5f);
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
public void serialRun() {

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
    
    if (code.charAt(0) == '$'){
      currentPath = code.substring(3,code.indexOf("*")-3);
    } else {
    
      gcode = code;
      
      GCode.add(gcode);
    }
  }
  
  //SEND NEXT function
  //Returns next available command as String
  //on FIFO basis and removes it from the buffer
  public String sendNext () {
    String r = GCode.get(0);
    GCode.remove(0);
    
    //PULL CURRENT POSITION
    posx = parseNumber(r, "X", posx);
    posy = parseNumber(r, "Y", posy);
    lastf = parseNumber(r, "F", lastf);
         
    //PULL LINE NUMBER
    lineNum = parseString(r, "N", lineNum);
    timeLeft = parseString(r, "*", timeLeft);
    
    int startIndex = 0;
    if ( r.charAt(0) == 'N' ) startIndex = r.indexOf(" ")+1;
    int endIndex = r.indexOf(" *");
    if( endIndex == -1 ) endIndex = r.length();

    return r.substring(startIndex, endIndex) + "\n";
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
  
  public void formatLineTime() {

  ArrayList<Float> time = new ArrayList<Float>();
  int timeTotal = 0;

  PVector pos = new PVector( posx, posy );

  for ( int i = 0; i < GCode.size(); i++ ) {
    String cmd = GCode.get(i);
    
    int gType = PApplet.parseInt( parseNumber(cmd, "G", -1) );
    if (gType != -1) {
      
      float duration = 0.0f;
      switch(gType) {
      case 0:
      case 1:

        float x_ = parseNumber(cmd, "X", pos.x);
        float y_ = parseNumber(cmd, "Y", pos.y);
        PVector newPos = new PVector( x_, y_ );

        float f_ = parseNumber(cmd, "F", 20.0f);

        float dx = newPos.x - pos.x;
        float dy = newPos.y - pos.y;

        float l = sqrt(dx*dx + dy*dy);
        

        if ( l == 0 ) {
          time.add(0.0f);
          break;
        }
        f_ = min( f_, determineFeedrate( dx, dy, f_) );
        
        duration = PApplet.parseInt(l / f_);
        time.add(duration);
        timeTotal += duration;
        

        pos = newPos;
        break;

      case 2: 
        break;
      case 3: 
        break;
      case 4:
      case 5:
        duration = PApplet.parseInt(parseNumber( cmd, "P", 0 )/1000.0f);
        time.add( duration );
        timeTotal += duration;
        break;
      }
    } else {
      time.add( 0.0f );
    }
  }

  //loop back through and add timestamps
  for ( int i = 0; i < GCode.size(); i++) {
    //decimate total time
    timeTotal -= time.get(i);
    
    //generate formatted timestamp (mm:ss)
    String timeStamp = nf( PApplet.parseInt(timeTotal/60), 2) + ":" + nf( PApplet.parseInt(timeTotal%60), 2);
    
    //pull command from buffer
    String cmd = GCode.get(i);
    
    //add line number and timestamp
    cmd = "N" + nf(i, 2) + " " + cmd + " *" + timeStamp;
    
    //reload into buffer
    GCode.set(i, cmd);
  }
}

}
//G00/G01 - LINE COMMAND
public String gcodeLine(float x, float y, float f, boolean spray){
  if( spray ) return "G01 X" + str(x) + " Y" + str(y) + " F" + str(f);
  else return "G00 X" + str(x) + " Y" + str(y) + " F" + str(f);
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
public void genBlastPass(float bWidth, float bHeight, float spacing, float speed){
  String cmd;
  
  println("Width: "+bWidth);
  println("Height: "+bHeight);
  println("Spacing: "+spacing);
  println("Speed: "+speed);
  
  //determine number of passes from spacing and height
  int passes = PApplet.parseInt( ceil( bHeight / spacing) + 1 );
  
  println("Passes: "+passes);
  
  //determine starting height
  float startH = ((passes * spacing) - bHeight)/-2.0f;
  
  //starting position
  PVector pos = new PVector( 0, startH - spacing);
  
  println("Starting Position: ( "+pos.x+", "+pos.y+" )");
  
  //move vectors
  PVector moveV = new PVector( 0, spacing);
  PVector moveH = new PVector (bWidth, 0);
  
  //move off board
  cmd = "G00 X0 F" + str(speed);
  GB.write( cmd );
  
  cmd = "G00 Y-50 F" + str(speed);
  GB.write( cmd );
  
  //start blast stream
  cmd = gcodeDwell( 8000 );
  GB.write( cmd );
  
  //move to start point
  cmd = gcodeLine( pos.x, pos.y, speed, true );
  GB.write( cmd );
  
  //blast to second point
  pos.add( moveV );
  cmd = gcodeLine( pos.x, pos.y, speed*2.0f, true );
  GB.write( cmd );
  
  for( int i = 0; i < (passes); i++){
    //check if even or odd pass
    if (i%2 == 0){
      //move to the right
      pos.add( moveH );
    } else {
      //move to the left
      pos.sub( moveH );
    }
    
    //blast horizontally
    cmd = gcodeLine( pos.x, pos.y, speed, true );
    GB.write( cmd );
    
    //blast vertically
    pos.add( moveV );
    cmd = gcodeLine( pos.x, pos.y, speed*2.0f, true );
    GB.write( cmd );
  }
  
  //move blast above board 
  if (pos.y < bHeight + 50.0f){
    pos.y += 50.0f;
  }
  
  cmd = gcodeLine( pos.x, pos.y, speed*2.0f, false );
  GB.write( cmd );
  
  //wait for blast stream to stop
  cmd = gcodePause( 6000 );
  GB.write( cmd );
  
  //move back to origin
  cmd = "G00 X0 F" + speed;
  GB.write( cmd );
  
  cmd = "G00 Y0 F" + speed;
  GB.write( cmd );
  
  
  //run GCODE formatter to add line numbers and time
  GB.formatLineTime();
  
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
      if ( !override ) {
        GB.write( cmd );
      } else {
        interrupt.write( cmd );
      }
    }

    //RESET ORIGIN
    //--------------------------------------------------------------------------
    if ( theEvent.getName().equals("teleport") ) {
      String cmd = gcodeTeleportOrigin();
      if ( !override ) {
        GB.write( cmd );
      } else {
        interrupt.write( cmd );
      }
      //reset position VARIABLES
      posx = 0;
      posy = 0;
    }

    //RUN BLAST PATTERN
    //--------------------------------------------------------------------------
    //UNIT CHANGE (MM <--> IN)
  if ( theEvent.getName().equals("metric") ) {
    metric = !metric;
    updateBoardDims();

    if ( metric ) {
      cP5.get(Toggle.class, "metric").getCaptionLabel().setText("METRIC (MM)");
      
    } else {
      cP5.get(Toggle.class, "metric").getCaptionLabel().setText("IMPERIAL (IN)");
    }
  }

  //SERIAL Handling
  //--------------------------------------------------------------------------
  //REFRESH
  if ( theEvent.getName().equals("serial") ) {
    lastx = posx;
    lasty = posy;

    myPort.clear();
    myPort.stop(); 
    serialConnect();

    String cmd = "M100 X" + lastx + " Y" + lasty;
    interrupt.write(cmd);
    cmd = "D30";
    interrupt.write(cmd);
    moveOff();
    moveOn();
  }

  //GCODE File Handling
  //--------------------------------------------------------------------------
  //CLEAR BUFFER
  if ( theEvent.getName().equals("clear") ) {
    GB.flushBuffer();
    lastx = 0.0f;
    lasty = 0.0f;
  }


  //PAUSE
  if ( theEvent.getName().equals("pause") ) {

    if ( !paused ) {
      //change button to RESUME
      cP5.get(Bang.class, "pause").setColorForeground(resumeColor);
      cP5.get(Bang.class, "pause").getCaptionLabel().setText("RESUME");
      //stop sending GCODE
      moveOff();
      paused = !paused;
    } else {
      cP5.get(Bang.class, "pause").setColorForeground(pauseColor);
      cP5.get(Bang.class, "pause").getCaptionLabel().setText("PAUSE");

      moveOn();
      paused = !paused;
    }
  }

  // OVERRIDE
  if ( theEvent.getName().equals("override") ) {
    override = !override;

    if ( override ) {
      //change button to ENABLED
      cP5.get(Toggle.class, "override").setColorForeground(resumeColor);
      cP5.get(Toggle.class, "override").setColorActive(resumeColor);
      cP5.get(Toggle.class, "override").getCaptionLabel().setText("OVERRIDE ON");
    } else {
      cP5.get(Toggle.class, "override").setColorForeground(fgColor);
      cP5.get(Toggle.class, "override").setColorBackground(bgColor);
      cP5.get(Toggle.class, "override").setColorActive(fgColor);
      cP5.get(Toggle.class, "override").getCaptionLabel().setText("OVERRIDE OFF");
    }
  }

  // SPRAYER COMMANDS
  //--------------------------------------------------------------------------
  //RUN L BLAST
  if ( theEvent.getName().equals("run_blasting") ) {
    //set up unit conversion
    float scalar;
    if (!metric){
      scalar = mm2in;
    } else {
      scalar = 1.0f;
    }
    
    //pull values from text fields
    updateBoardDims();
    
    genBlastPass( min( 1980, (bWidth*scalar+100.0f) ), bHeight*scalar, spacing*scalar, speed*scalar );
    
  }

  // SPRAYER COMMANDS
  //--------------------------------------------------------------------------
  // ENABLE BLAST
  if ( theEvent.getName().equals("blast_on") ) {
    String cmd = gcodeBlastOn();
    if ( !override ) {
      GB.write( cmd );
    } else {
      interrupt.write( cmd );
    }
  }
  // DISABLE BLAST
  if ( theEvent.getName().equals("blast_off") ) {
    String cmd = gcodeBlastOff();
    if ( !override ) {
      GB.write( cmd );
    } else {
      interrupt.write( cmd );
    }
  }

  // ENABLE AIR
  if ( theEvent.getName().equals("air_on") ) {
    String cmd = gcodeAirOn();
    if ( !override ) {
      GB.write( cmd );
    } else {
      interrupt.write( cmd );
    }
  }
  // DISABLE AIR
  if ( theEvent.getName().equals("air_off") ) {
    String cmd = gcodeAirOff();
    if ( !override ) {
      GB.write( cmd );
    } else {
      interrupt.write( cmd );
    }
  }

  // AXIAL MOVE COMMANDS
  //--------------------------------------------------------------------------
  // GO HOME
  if ( theEvent.getName().equals("go_home") ) {
    posx = 0;
    posy = 0;
    String cmd = gcodeLine(posx, posy, 50.0f, false);
    GB.write( cmd );
  }

  // X+100 MOVE
  if ( theEvent.getName().equals("x_100") ) {
    String cmd = "G00 X" + (posx + 100) + " F50.0";
    if ( !override ) {
      GB.write( cmd );
    } else {
      interrupt.write( cmd );
    }
  }

  // X+10 MOVE
  if ( theEvent.getName().equals("x_10") ) {
    String cmd = "G00 X" + (posx + 10) + " F50.0";
    if ( !override ) {
      GB.write( cmd );
    } else {
      interrupt.write( cmd );
    }
  }

  // X-100 MOVE
  if ( theEvent.getName().equals("x_-100") ) {
    String cmd = "G00 X" + (posx - 100) + " F50.0";
    if ( !override ) {
      GB.write( cmd );
    } else {
      interrupt.write( cmd );
    }
  }

  // X-10 MOVE
  if ( theEvent.getName().equals("x_-10") ) {
    String cmd = "G00 X" + (posx - 10) + " F50.0";
    if ( !override ) {
      GB.write( cmd );
    } else {
      interrupt.write( cmd );
    }
  }
  // Y+100 MOVE
  if ( theEvent.getName().equals("y_100") ) {
    String cmd = "G00 Y" + (posy + 100) + " F50.0";
    if ( !override ) {
      GB.write( cmd );
    } else {
      interrupt.write( cmd );
    }
  }

  // Y+10 MOVE
  if ( theEvent.getName().equals("y_10") ) {
    String cmd = "G00 Y" + (posy + 10) + " F50.0";
    if ( !override ) {
      GB.write( cmd );
    } else {
      interrupt.write( cmd );
    }
  }

  // Y-100 MOVE
  if ( theEvent.getName().equals("y_-100") ) {
    String cmd = "G00 Y" + (posy - 100) + " F50.0";
    if ( !override ) {
      GB.write( cmd );
    } else {
      interrupt.write( cmd );
    }
  }

  // Y-10 MOVE
  if ( theEvent.getName().equals("y_-10") ) {
    String cmd = "G00 Y" + (posy - 10) + " F50.0";
    if ( !override ) {
      GB.write( cmd );
    } else {
      interrupt.write( cmd );
    }
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
  .setPosition( 25, 420 )
  .setSize( 550, 50 )
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
  //FILE CONTROLS
  cP5.addBang("serial")
  .setPosition(480,750)
  .setSize(100, 25)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(0)
  .setFont(fontS)
  .setText("RECONNECT")
  ;
  
    //FILE CONTROLS
  cP5.addBang("clear")
  .setPosition(480,720)
  .setSize(100, 25)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(0)
  .setFont(fontS)
  .setText("CLEAR BUFFER")
  ;
  
  cP5.addBang("pause")
  .setPosition(650, 680)
  .setSize(700, 100)
  .setTriggerEvent(Bang.RELEASE)
  .setColorForeground(pauseColor)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontL)
  .setText("PAUSE")
  ;
  
  //BLAST PASS SETTINGS
  //---------------------------------------------------------------------------
  cP5.addTextfield("board_height")
  .setPosition( 650, 150 )
  .setSize( 340, 50 )
  .setFont( fontL )
  .setFocus( true )
  .setColor( color(0) )
  .setAutoClear( false )
  .setValue( "100.0" )
  //caption settings
  .getCaptionLabel()
  .setColor(0)
  .setFont(fontM)
  .alignX(ControlP5.LEFT)
  .setText("BOARD HEIGHT")
  ;
  
  cP5.addTextfield("board_width")
  .setPosition( 1000, 150 )
  .setSize( 350, 50 )
  .setFont( fontL )
  .setFocus( true )
  .setColor( color(0) )
  .setAutoClear( false )
  .setValue( "100.0" )
  //caption settings
  .getCaptionLabel()
  .setColor(0)
  .setFont(fontM)
  .alignX(ControlP5.LEFT)
  .setText("BOARD WIDTH")
  ;
  
    cP5.addTextfield("blast_spacing")
  .setPosition( 650, 250 )
  .setSize( 340, 50 )
  .setFont( fontL )
  .setFocus( true )
  .setColor( color(0) )
  .setAutoClear( false )
  .setValue( "20.0" )
  //caption settings
  .getCaptionLabel()
  .setColor(0)
  .setFont(fontM)
  .alignX(ControlP5.LEFT)
  .setText("BLAST SPACING")
  ;
  
  cP5.addTextfield("blast_speed")
  .setPosition( 1000, 250 )
  .setSize( 350, 50 )
  .setFont( fontL )
  .setFocus( true )
  .setColor( color(0) )
  .setAutoClear( false )
  .setValue( "25.0" )
  //caption settings
  .getCaptionLabel()
  .setColor(0)
  .setFont(fontM)
  .alignX(ControlP5.LEFT)
  .setText("BLAST SPEED (UNIT/S)")
  ;
  
  //TOGGLE METRIC/IMPERIAL MODE
  cP5.addToggle("metric")
  .setPosition(650, 80)
  .setSize(340, 45)
  .setColorForeground(fgColor)
  .setColorBackground(fgColor)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontM)
  .setText("METRIC (MM)")
  ;
  
  cP5.addBang("run_blasting")
  .setPosition(650,350)
  .setSize(700, 45)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontL)
  .setText("RUN BLASTING")
  ;

  //SPRAYER ENABLE/DISABLE
  //---------------------------------------------------------------------------
  //DISABLE BUTTON
  //Turns off blast
  cP5.addBang("blast_off")
  .setPosition(400, 50)
  .setSize(95, 95)
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
  .setPosition(500, 50)
  .setSize(95, 95)
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
  .setPosition(400, 150)
  .setSize(95, 50)
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
  .setPosition(500, 150)
  .setSize(95, 50)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("AIR ON")
  ;

  //TELEPORT
  //---------------------------------------------------------------------------
  
  //TOGGLE OVERRIDE MODE
  cP5.addToggle("override")
  .setPosition(400, 280)
  .setSize(200, 45)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(0)
  .setFont(fontM)
  .setText("OVERRIDE OFF")
  ;
  
  //Send teleport signal
  cP5.addBang("teleport")
  .setPosition(400, 330)
  .setSize(200, 45)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontM)
  .setText("SET ORIGIN (0,0)")
  ;
  

  //AXIAL MOVE COMMANDS
  //---------------------------------------------------------------------------

  //GO HOME
  cP5.addBang("go_home")
  .setPosition(165,165)
  .setSize(70,70)
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
  .setPosition(300, 175)
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
  .setPosition(245, 175)
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
  .setPosition(50, 175)
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
  .setPosition(105, 175)
  .setSize(50, 50)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("X -10")
  ;

  //Y +100 BUTTON
  cP5.addBang("y_100")
  .setPosition(175, 50)
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
  .setPosition(175, 105)
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
  .setPosition(175,300)
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
  .setPosition(175, 245)
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

public void serialConnect() {
  String[] ports = Serial.list();

  if ( ports.length > 0 ) {
    port = ports[0];
    myPort = new Serial(this, port, 115200);
    connected = true;
    cP5.get(Bang.class, "serial").setColorForeground(color(255));
    cP5.get(Bang.class, "clear").setColorForeground(color(255));
  } else {
    connected = false;
    cP5.get(Bang.class, "serial").setColorForeground(color(255));
    cP5.get(Bang.class, "clear").setColorForeground(color(255));
  }
}

public float parseNumber(String s, String C, float f) {
  int index = s.indexOf(C);

  if ( index == -1 ) {
    return f;
  }

  int endIndex = s.indexOf(" ", index);

  if ( endIndex == -1 ) {
    endIndex = s.length();
  }  

  val = s.substring( index+1, endIndex );

  return PApplet.parseFloat(val);
}

public String parseString( String s, String C, String d) {
  int index = s.indexOf(C);

  if ( index == -1 ) {
    return d;
  }

  int endIndex = s.indexOf(" ", index);

  if ( endIndex == -1 ) {
    endIndex = s.length();
  }  

  val = s.substring( index+1, endIndex );

  return val;
}

public void moveOff() {
  //Move below board
  lastx = posx;
  lasty = posy;

  String s = "G00 Y-50.0 F300.0";
  interrupt.write(s);

  //Pause for 6 seconds to allow blast to stop
  s = "G04 P6000.0";
  interrupt.write(s);

  //Move home
  s = "G00 X0 F300.0";
  interrupt.write(s);
  s = "G00 X0 Y0 F300.0";
  interrupt.write(s);
}

public void moveOn() {
  //check if at last position
  if (posx == lastx && posy == lasty) {
    return;
  }

  //return to below last position
  String s = "G00 Y-50 F300.0";
  interrupt.write(s);
  s = "G00 X"+lastx+" F300.0";
  interrupt.write(s);

  //start blast stream
  s = "G05 P8000.0";
  interrupt.write(s);

  //move up to last position
  s = "G01 Y"+lasty+" F300.0";
  interrupt.write(s);
}


public float determineFeedrate( float dx, float dy, float f ) {
  float vec = sqrt( dx*dx + dy*dy );
  float vx = min( 300.0f, f * dx / vec );
  float vy = min( 80.0f, f * dy / vec );
  return sqrt( vx*vx + vy*vy);
}

public void updateBoardDims(){
    
    bHeight = Float.parseFloat( cP5.get(Textfield.class, "board_height").getText() );
    bWidth = Float.parseFloat( cP5.get(Textfield.class, "board_width").getText() );
    spacing = Float.parseFloat( cP5.get(Textfield.class, "blast_spacing").getText() );
    speed = Float.parseFloat( cP5.get(Textfield.class, "blast_speed").getText() );
    
}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "blastbot_app_EE" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
