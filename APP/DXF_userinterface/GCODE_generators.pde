//------------------------------------------------------------------------------
// GCODE GENERATORS
//------------------------------------------------------------------------------
// Functions that generate GCODE commands

//G00/G01 - LINE COMMAND
String gcodeLine(float x, float y, boolean spray){
  if( spray ) return "G01 X" + str(x) + " Y" + str(y);
  else return "G00 X" + str(x) + " Y" + str(y);
}

//G02/G03 - ARC COMMANDS
String gcodeArc(float cx, float cy, float x, float y, boolean dir){
  //clockwise = 2 ... counterclockwise = 3
  if( dir ) return "G02 I" + str(cx) + " J" + str(cy) + " X" + str(x) + " Y" + str(y);
  else return "G03 I" + str(cx) + " J" + str(cy) + " X" + str(x) + " Y" + str(y);
}

//G04 - PAUSE COMMAND
String gcodePause( int time ){
  return "G04 P" + str(time);
}

//G05 - DWELL COMMAND
String gcodeDwell( int time ){
  return "G05 P" + str(time);
}

//M50 BLAST ON
String gcodeBlastOn(){
  return "M50";
}

//M51 BLAST OFF
String gcodeBlastOff(){
  return "M51";
}

//M60 AIR ON
String gcodeAirOn(){
  return "M60";
}

//M61 AIR OFF
String gcodeAirOff(){
  return "M61";
}

}String gcodeTeleportTo( float x, float y ){
  return "M100 X" + str(x) + " Y" + str(y);
}