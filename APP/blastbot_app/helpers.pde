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

void serialConnect(){
  String[] ports = Serial.list();
  
  if( ports.length > 0 ){
    port = ports[0];
    myPort = new Serial(this, port, 115200);
    connected = true;
    cP5.get(Bang.class, "serial").setColorForeground(color(255));
  } else {
    connected = false;
    cP5.get(Bang.class, "serial").setColorForeground(color(255));
  }
  
}

float parseNumber(String s, String C, float f){
  int index = s.indexOf(C);
  
  if( index == -1 ){
    return f;
  }
  
  int endIndex = s.indexOf(" ", index);
  
  if( endIndex == -1 ){
    endIndex = s.length();
  }  
  
  val = s.substring( index+1, endIndex );
  
  return float(val);
}

String parseString( String s, String C, String d){
  int index = s.indexOf(C);
  
  if( index == -1 ){
    return d;
  }
  
  int endIndex = s.indexOf(" ", index);
  
  if( endIndex == -1 ){
    endIndex = s.length();
  }  
  
  val = s.substring( index+1, endIndex );
  
  return val;
}

void moveOff(){
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

void moveOn(){
  //return to below last position
  String s = "G00 Y-50 F300.0";
  interrupt.write(s);
  s = "G00 X"+lastx+" F300.0";
  interrupt.write(s);
  
  //start blast stream
  s = "G05 P3000.0";
  interrupt.write(s);
  
  //move up to last position
  s = "G01 Y"+lasty+" F300.0";
  interrupt.write(s);
}

void checkFiles(){
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