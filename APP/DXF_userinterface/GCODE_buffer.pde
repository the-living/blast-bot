//------------------------------------------------------------------------------
// GCODE BUFFER CLASS
//------------------------------------------------------------------------------
// Object for storing and retrieving GCODE commands to pass to
// Arduino. Commands are added and removed on a FIFO basis

class GCODEbuffer {
  
  StringList Gcode = new StringList();
  
  GCODEbuffer(){
  //initialize as blank object  
  }
  
  //WRITE
  //Write a command to the buffer
  void write( String code ){
    String gcode;
    
    gcode = code;
    
    GCode.add( gcode );
  }
  
  //SEND NEXT
  //Returns next available command to pass to Arduino
  String sendNext() {
    String r = GCode.get(0);
    GCode.remove(0);
    
    //parse metadata
    lineNum = parseString(r, "N", lineNum);
    timeLeft = parseString(r, "*", timeLeft);
    
    //extract final position of command
    posx = parseNumber(r,"X",posx);
    posy = parseNumber(r,"Y",posy);
    
    int startIndex = 0;
    