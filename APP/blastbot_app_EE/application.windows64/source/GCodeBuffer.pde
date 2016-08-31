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
  
  void formatLineTime() {

  ArrayList<Float> time = new ArrayList<Float>();
  int timeTotal = 0;

  PVector pos = new PVector( posx, posy );

  for ( int i = 0; i < GCode.size(); i++ ) {
    String cmd = GCode.get(i);
    
    int gType = int( parseNumber(cmd, "G", -1) );
    if (gType != -1) {
      
      float duration = 0.0;
      switch(gType) {
      case 0:
      case 1:

        float x_ = parseNumber(cmd, "X", pos.x);
        float y_ = parseNumber(cmd, "Y", pos.y);
        PVector newPos = new PVector( x_, y_ );

        float f_ = parseNumber(cmd, "F", 20.0);

        float dx = newPos.x - pos.x;
        float dy = newPos.y - pos.y;

        float l = sqrt(dx*dx + dy*dy);
        

        if ( l == 0 ) {
          time.add(0.0);
          break;
        }
        f_ = min( f_, determineFeedrate( dx, dy, f_) );
        
        duration = int(l / f_);
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
        duration = int(parseNumber( cmd, "P", 0 )/1000.0);
        time.add( duration );
        timeTotal += duration;
        break;
      }
    } else {
      time.add( 0.0 );
    }
  }

  //loop back through and add timestamps
  for ( int i = 0; i < GCode.size(); i++) {
    //decimate total time
    timeTotal -= time.get(i);
    
    //generate formatted timestamp (mm:ss)
    String timeStamp = nf( int(timeTotal/60), 2) + ":" + nf( int(timeTotal%60), 2);
    
    //pull command from buffer
    String cmd = GCode.get(i);
    
    //add line number and timestamp
    cmd = "N" + nf(i, 2) + " " + cmd + " *" + timeStamp;
    
    //reload into buffer
    GCode.set(i, cmd);
  }
}

}