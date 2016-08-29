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

void serialConnect() {
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

float parseNumber(String s, String C, float f) {
  int index = s.indexOf(C);

  if ( index == -1 ) {
    return f;
  }

  int endIndex = s.indexOf(" ", index);

  if ( endIndex == -1 ) {
    endIndex = s.length();
  }  

  val = s.substring( index+1, endIndex );

  return float(val);
}

String parseString( String s, String C, String d) {
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

void moveOff() {
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

void moveOn() {
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


float determineFeedrate( float dx, float dy, float f ) {
  float vec = sqrt( dx*dx + dy*dy );
  float vx = min( 300.0, f * dx / vec );
  float vy = min( 80.0, f * dy / vec );
  return sqrt( vx*vx + vy*vy);
}

void updateBoardDims(){
    
    bHeight = Float.parseFloat( cP5.get(Textfield.class, "board_height").getText() );
    bWidth = Float.parseFloat( cP5.get(Textfield.class, "board_width").getText() );
    spacing = Float.parseFloat( cP5.get(Textfield.class, "blast_spacing").getText() );
    speed = Float.parseFloat( cP5.get(Textfield.class, "blast_speed").getText() );
    
}