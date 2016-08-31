//---------------------------------------------------------------------------
//
// ControlP5 UX Objects Behavior
//
//---------------------------------------------------------------------------

//CONTROLP5 INTERFACE CONTROLS
//Functions are handled via triggering "events"
void controlEvent( ControlEvent theEvent ) {

  if ( theEvent.isController() ) {

    //MANUAL GCODE ENTRY
    //--------------------------------------------------------------------------
    if ( theEvent.getName().equals("cmd_entry") ) {

      //pull value from text entry box
      String cmd = cP5.get(Textfield.class, "cmd_entry").getText();
      if( !override ){
        GB.write( cmd );
      } else {
        interrupt.write( cmd );
      }
    }

    //RESET ORIGIN
    //--------------------------------------------------------------------------
    if ( theEvent.getName().equals("teleport") ) {
      String cmd = gcodeTeleportOrigin();
      if( !override ){
        GB.write( cmd );
      } else {
        interrupt.write( cmd );
      }
      //reset position VARIABLES
      posx = 0;
      posy = 0;
    }

    //RUN TEST PATTERN
    //--------------------------------------------------------------------------
    //if ( theEvent.getName().equals("test_pattern") ) {

    //  String lines[] = loadStrings("toRun.txt");
    //  for (int i = 0; i < lines.length; i++) {
    //    GB.write( lines[i] );
    //  }
      
    //}
    
    //SERIAL Handling
    //--------------------------------------------------------------------------
    //REFRESH
    if( theEvent.getName().equals("serial") ){
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
    if( theEvent.getName().equals("clear") ){
      GB.flushBuffer();
      lastx = 0.0;
      lasty = 0.0;
    }
    
    
    //REFRESH
    if( theEvent.getName().equals("refresh") ){
       checkFiles();
    }
    
    //PAUSE
    if( theEvent.getName().equals("pause") ){
       
       if( !paused ){
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
      
      if( override ){
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



    

    // SPRAYER COMMANDS
    //--------------------------------------------------------------------------
    // ENABLE BLAST
    if ( theEvent.getName().equals("blast_on") ) {
      String cmd = gcodeBlastOn();
      if( !override ){
        GB.write( cmd );
      } else {
        interrupt.write( cmd );
      }
    }
    // DISABLE BLAST
    if ( theEvent.getName().equals("blast_off") ) {
      String cmd = gcodeBlastOff();
      if( !override ){
        GB.write( cmd );
      } else {
        interrupt.write( cmd );
      }
    }
    
    // ENABLE AIR
    if ( theEvent.getName().equals("air_on") ) {
      String cmd = gcodeAirOn();
      if( !override ){
        GB.write( cmd );
      } else {
        interrupt.write( cmd );
      }
    }
    // DISABLE AIR
    if ( theEvent.getName().equals("air_off") ) {
      String cmd = gcodeAirOff();
      if( !override ){
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
      String cmd = gcodeLine(posx, posy, false);
      GB.write( cmd );
    }
    
    // X+100 MOVE
    if ( theEvent.getName().equals("x_100") ) {
      String cmd = "G00 X" + (posx + 100) + " F50.0";
      if( !override ){
        GB.write( cmd );
      } else {
        interrupt.write( cmd );
      }
    }

    // X+10 MOVE
    if ( theEvent.getName().equals("x_10") ) {
      String cmd = "G00 X" + (posx + 10) + " F50.0";
      if( !override ){
        GB.write( cmd );
      } else {
        interrupt.write( cmd );
      }
    }

    // X-100 MOVE
    if ( theEvent.getName().equals("x_-100") ) {
      String cmd = "G00 X" + (posx - 100) + " F50.0";
      if( !override ){
        GB.write( cmd );
      } else {
        interrupt.write( cmd );
      }
    }

    // X-10 MOVE
    if ( theEvent.getName().equals("x_-10") ) {
      String cmd = "G00 X" + (posx - 10) + " F50.0";
      if( !override ){
        GB.write( cmd );
      } else {
        interrupt.write( cmd );
      }
    }
    // Y+100 MOVE
    if ( theEvent.getName().equals("y_100") ) {
      String cmd = "G00 Y" + (posy + 100) + " F50.0";
      if( !override ){
        GB.write( cmd );
      } else {
        interrupt.write( cmd );
      }
    }

    // Y+10 MOVE
    if ( theEvent.getName().equals("y_10") ) {
      String cmd = "G00 Y" + (posy + 10) + " F50.0";
      if( !override ){
        GB.write( cmd );
      } else {
        interrupt.write( cmd );
      }
    }

    // Y-100 MOVE
    if ( theEvent.getName().equals("y_-100") ) {
      String cmd = "G00 Y" + (posy - 100) + " F50.0";
      if( !override ){
        GB.write( cmd );
      } else {
        interrupt.write( cmd );
      }
    }

    // Y-10 MOVE
    if ( theEvent.getName().equals("y_-10") ) {
      String cmd = "G00 Y" + (posy - 10) + " F50.0";
      if( !override ){
        GB.write( cmd );
      } else {
        interrupt.write( cmd );
      }
    }
  }
}