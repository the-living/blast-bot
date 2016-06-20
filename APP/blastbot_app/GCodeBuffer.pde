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
  void write( String code ){
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
  String sendNext () {
    String r = GCode.get(0);
    GCode.remove(0);
    
    //PULL CURRENT POSITION
    posx = parseNumber(r, "X", posx);
    posy = parseNumber(r, "Y", posy);
         
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
  boolean getEnd() {
    return GCode.size() <= 0;
  }
  
  //FLUSH BUFFER function
  //Clears buffer
  void flushBuffer(){
    for (int i = GCode.size() - 1; i >= 0; i--){
      GCode.remove(i);
    }
  }
  
  //SIZE function
  //Returns length of Buffer
  int size(){
    return GCode.size();
  }

}