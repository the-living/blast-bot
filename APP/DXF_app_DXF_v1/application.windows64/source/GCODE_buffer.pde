//------------------------------------------------------------------------------
// GCODE BUFFER CLASS
//------------------------------------------------------------------------------
// Object for storing and retrieving GCODE commands to pass to
// Arduino. Commands are added and removed on a FIFO basis

class GCODEbuffer {

  StringList GCode = new StringList();
  String time_estimate;

  GCODEbuffer() {
    //initialize as blank object
    time_estimate = "0:00:00";
  }

  //WRITE
  //Write a command to the buffer
  void write( String code ) {
    String gcode;

    gcode = code;

    GCode.append( gcode );
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
    posx = parseNumber(r, "X", posx);
    posy = parseNumber(r, "Y", posy);

    int startIndex = 0;
    if ( r.charAt(0) == 'N' ) startIndex = r.indexOf(" ")+1;
    int endIndex = r.indexOf(" *");
    if ( endIndex == -1 ) endIndex = r.length();
    return r.substring(startIndex, endIndex) + "\n";
  }

  //GET END
  //Checks if buffer is empty
  boolean getEnd() {
    return GCode.size() <= 0;
  }
  
  //GET ITEM
  String get(int i){
    return GCode.get(i);
  }
  
  //DUPLICATE BUFFER
  //Clears all data in buffer
  void copyBuffer(GCODEbuffer g) {
    flushBuffer();
    for ( int i = 0; i < g.size(); i++ ) {
      write( g.get(i) );
    }
  }
  
  //FLUSH BUFFER
  //Clears all data in buffer
  void flushBuffer() {
    for ( int i = GCode.size()-1; i >= 0; i-- ) {
      GCode.remove(i);
    }
  }

  //SIZE
  //Returns size of GCode Buffer
  int size() {
    return GCode.size();
  }

  //FORMAT LINE TIME
  //Format contents of buffer to add line numbers
  //and time estimates
  void formatLineTime() {
    ArrayList<Float> time = new ArrayList<Float>();
    float timeTotal = 0;

    PVector pos = new PVector( 0, 0 );

    for ( int i = 0; i < GCode.size(); i++ ) {
      String cmd = GCode.get(i);

      int gType = int( parseNumber(cmd, "G", -1) );
      if (gType != -1) {

        float duration = 0.0;
        float x_,y_,f_,cx,cy;
        PVector newPos;
        switch(gType) {
        case 0:
        case 1:

          x_ = parseNumber(cmd, "X", pos.x);
          y_ = parseNumber(cmd, "Y", pos.y);
          f_ = parseNumber(cmd, "F", defaultSpeed);     
          
          newPos = new PVector(x_,y_);
          
          duration = calcLineTime( newPos, pos, f_ );
          
          time.add(duration);
          timeTotal += duration;
          pos = newPos;
          break;
        case 2: 
        case 3:
          
          cx = parseNumber(cmd, "I", 0.0);
          cy = parseNumber(cmd, "J", 0.0);
          x_ = parseNumber(cmd, "X", pos.x);
          y_ = parseNumber(cmd, "Y", pos.y);
          f_ = parseNumber(cmd, "F", defaultSpeed);
          
          float dx1 = pos.x - cx;
          float dy1 = pos.y - cy;
          float dx2 = x_ - cx;
          float dy2 = y_ - cy;
          float rad = sqrt( dx1*dx1 + dy1*dy1 );
          
          float angle1 = atan3(dy1,dx1);
          float angle2 = atan3(dy2,dx2);
          float theta = angle2 - angle1;
          
          if(gType == 3 && theta < 0) angle2 += TWO_PI;
          if(gType == 2 && theta > 0) angle1 += TWO_PI;
          
          theta = angle2-angle1;
          
          float l = abs(theta)*rad;
          int segments = int(ceil(l));
          
          newPos = new PVector();
          for( int k = 0; k < segments; k++ ){
            float scale = float(k) / float(segments);
            float angle3 = (theta*scale) + angle1;
            newPos = new PVector( cx + cos(angle3)*rad, cy + sin(angle3)*rad);            
            duration += calcLineTime( newPos, pos, f_ ) ;
            pos = newPos;
          }
          
          time.add( duration );
          timeTotal += duration;
          break;
        case 4:
        case 5:
          duration = parseNumber( cmd, "P", 0 )/1000.0;
          time.add( duration );
          timeTotal += duration;
          break;
        }
      } else {
        time.add( 0.0 );
      }
      
    }
    time_estimate = nf( int(timeTotal/3600),2)+":"+nf(int((timeTotal%3600)/60),2)+":"+nf(int(timeTotal%60),2);
    
    //loop back through and add timestamps
    for ( int i = 0; i < GCode.size(); i++) {
      //decimate total time
      timeTotal -= time.get(i);

      //generate formatted timestamp (mm:ss)
      String timeStamp = nf( int(timeTotal/60), 2) + ":" + nf( int(timeTotal%60), 2);

      //pull command from buffer
      String cmd = GCode.get(i);
      
      //Strip any existing line numbers and timestamps
      int startIndex = 0;
      if ( cmd.charAt(0) == 'N' ) startIndex = cmd.indexOf(" ")+1;
      int endIndex = cmd.indexOf(" *");
      if ( endIndex == -1 ) endIndex = cmd.length();

      cmd = cmd.substring(startIndex, endIndex);

      //add line number and timestamp
      cmd = "N" + nf(i, 2) + " " + cmd + " *" + timeStamp;

      //reload into buffer
      GCode.set(i, cmd);
    }
  }
}