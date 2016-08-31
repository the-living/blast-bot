void genBlastPass(float bWidth, float bHeight, float spacing, float speed){
  String cmd;
  
  println("Width: "+bWidth);
  println("Height: "+bHeight);
  println("Spacing: "+spacing);
  println("Speed: "+speed);
  
  //determine number of passes from spacing and height
  int passes = int( ceil( bHeight / spacing) + 1 );
  
  println("Passes: "+passes);
  
  //determine starting height
  float startH = ((passes * spacing) - bHeight)/-2.0;
  
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
  cmd = gcodeLine( pos.x, pos.y, speed*2.0, true );
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
    cmd = gcodeLine( pos.x, pos.y, speed*2.0, true );
    GB.write( cmd );
  }
  
  //move blast above board 
  if (pos.y < bHeight + 50.0){
    pos.y += 50.0;
  }
  
  cmd = gcodeLine( pos.x, pos.y, speed*2.0, false );
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