//------------------------------------------------------------------------------
// UX FUNCTIONS
//------------------------------------------------------------------------------
// Functions that control UX behavior

// CONTROLP5 INTERFACE CONTROLS
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Functions are handled via triggering "events"
void controlEvent( ControlEvent theEvent ) {
  if ( theEvent.isController() ) {

    String eventName = theEvent.getName();

    switch( eventName ) {

      //PREVIEW AREA COMMANDS
    case "start":
      running = !running;
      if(running) GB.copyBuffer(loader);
      else GB.flushBuffer();
      paused = false;
      break;
    case "pause":
      paused = !paused;
      break;
    case "reset":
      running = false;
      paused = false;
      GB.flushBuffer();
      break;
    case "preview":
      togglePreview();
      break;

      //MANUAL CONTROL COMMANDS
    case "y+100":
      relativeMove(0, 100);
      break;
    case "y+10":
      relativeMove(0, 10);
      break;
    case "y-10":
      relativeMove(0, -10);
      break;
    case "y-100":
      relativeMove(0, -100);
      break;
    case "x+100":
      relativeMove(100, 0);
      break;
    case "x+10":
      relativeMove(10, 0);
      break;
    case "x-10":
      relativeMove(-10, 0);
      break;
    case "x-100":
      relativeMove(-100, 0);
      break;
    case "home":
      relativeMove(-posx, -posy);
      break;
    case "blastOff":
      interrupt.write( gcodeBlastOff() );
      break;
    case "blastOn":
      interrupt.write( gcodeBlastOn() );
      break;
    case "airOff":
      interrupt.write( gcodeAirOff() );
      break;
    case "airOn":
      interrupt.write( gcodeAirOn() );
      break;
    case "override":
      toggleOverride();
      break;
    case "origin":
      interrupt.write( gcodeTeleportTo(0, 0) );
      break;
    case "cmdEntry":
      manualEntry();
      break;

      //FILE SETTING COMMANDS
    case "load":
      selectInput("Select DXF file: ", "fileSelection");
      break;
    case "process":
      processFile();
      break;
    case "moveSpeed":
      break;
    case "moveBlast":
      break;
    case "dwellTime":
      break;
    case "dwellBlast":
      break;
    case "update":
      updateColorSettings();
      break;

    default:
      break;
    }
    
    if( eventName.contains("color_") ){
      println("COLOR HIT: " + eventName);
      int startIndex = eventName.indexOf("_");
      selectedColor = int( eventName.substring(startIndex+1, eventName.length()) );
      loadColorSettings();
    }
  }
}

// MANUAL ENTRY
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Issues manually entered command to run immediately
void manualEntry() {
  String cmd = cP5.get(Textfield.class, "cmdEntry").getText();
  interrupt.write( cmd );
}

// OVERRIDE TOGGLE
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Enables/disables manual override
void toggleOverride() {
  override = !override;
  Toggle toggle = cP5.get(Toggle.class, "override");

  if (override) {
    toggle.setColorForeground(green)
      .setColorActive(green)
      .getCaptionLabel().setText("OVERRIDE ON");
  } else {
    toggle.setColorForeground(white)
      .setColorActive(blue)
      .getCaptionLabel().setText("OVERRIDE OFF");
  }
}

// RELATIVE MOVE
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Generates a move command relative to current position
// using directional move buttons
void relativeMove( float x, float y ) {
  posx += x;
  posy += y;
  String code = gcodeLine( posx, posy, defaultSpeed, false );
  interrupt.write( code );
}

// FILE LOADING
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Opens dialogue for importing file to run
void fileSelection(File selection) {
  if ( selection != null ) {
    fullPath = selection.getPath();
    int breakPos = fullPath.lastIndexOf('\\');
    currentPath = fullPath.substring(breakPos+1);
    
    loaded = true;
    geoCount = 0;
    timeLeft = "0:00:00";
  } else {
    loaded = false;
  }
  GB.flushBuffer();
  processed = false;
  checkFiles();
}

// CHECK FILES
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Verifies loaded files to ensure they are the correct
// type, and ifso enables processing
void checkFiles() {
  String filetype = currentPath.substring( currentPath.length()-3, currentPath.length()).toLowerCase();
  if ( filetype.contains("svg") || filetype.contains("dxf") ) {
    loaded = true;
  } else {
    loaded = false;
    processed = false;
  }

  if (loaded) {
      colorLoaded = false;
      
      String[] fileData = loadStrings( fullPath );
      geojson = new JSONObject();
      colorSettings = new JSONObject();
      
      if ( filetype.contains("svg")){
        //ADD SVG PARSING HERE
        println("SVG importing not currently supported");
        return;
      } else if(filetype.contains("dxf")){
        
        parseDXF( geojson, colorSettings, fileData );
        
      } else {
        println("ERROR IMPORTING FILE");
      }
      
      saveJSONObject( geojson, "data/geo.json" );
      saveJSONObject( colorSettings, "data/settings.json" );
      
      renderJSONgeo( geojson );
      
      clearColors();
      generateColors();
      selectedColor = colors.get(0);
      loadColorSettings();
      colorLoaded = true;
    }
}

// PROCESS FILE
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Runs generation of GCODE from JSON
void processFile(){
  if( geojson == null ) return;
  
  genGCODE(geojson, loader);
  geoCount = loader.size();
  processed = true;
  if(loader.size() > 0) loader.formatLineTime();
}

// LOCK BUTTON
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Allows setting of button lock and changing color
void lockButton(Bang button, boolean lock, color c, color t){
  button.setLock(lock)
  .setColorForeground(c)
  .getCaptionLabel().setColor(t);
}

// RELABEL BUTTON
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Allows relabeling of button and changing color
void relabelButton(Bang button, String newlabel){
  button.getCaptionLabel().setText(newlabel);
}

// RECOLOR BUTTON
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Allows recoloring of button default & active (hover) colors
void recolorButton(Bang button, color c1, color c2){
  button.setColorForeground(c1)
  .setColorActive(c2);
}

// CHECK BUTTON STATUS
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Enables/disables buttons based on current state
void checkStatus(){
  Bang start = cP5.get(Bang.class, "start");
  Bang pause = cP5.get(Bang.class, "pause");
  
  Bang preview = cP5.get(Bang.class, "preview");
  Bang load = cP5.get(Bang.class, "load");
  Bang process = cP5.get(Bang.class, "process");
  Bang update = cP5.get(Bang.class, "update");
  
  if(!loaded){
    lockButton(start, true, grey,charcoal);
    lockButton(pause, true, grey,charcoal);
    lockButton(preview, true, grey,charcoal);
    lockButton(process, true, grey,charcoal);
    lockButton(update,true,grey,charcoal);
  } else if(loaded && !processed){
    lockButton(start, true, grey,charcoal);
    lockButton(pause, true, grey,charcoal);
    lockButton(preview, true, grey,charcoal);
    lockButton(process, false, black,white);
    relabelButton(process, "PROCESS FILE");
    recolorButton(process, black, blue);
    lockButton(update,false,black,white);
  }
  
  if(processed){
    lockButton(start,false,green,white);
    lockButton(preview,false,white,black);
    relabelButton(process, "REPROCESS FILE");
    recolorButton(process, blue, charcoal);
  }
  
  if(runPreview){
    lockButton(start,true,grey,charcoal);
    lockButton(load, true, grey, charcoal);
    lockButton(process, true, grey, charcoal);
    lockButton(update, true, grey, charcoal);
    recolorButton(preview, red, blue);
    relabelButton(preview, "END PREVIEW");
  } else if( running && !paused ){
    lockButton(start, false, red, white);
    relabelButton(start, "STOP");
    lockButton(pause, false, blue, black);
    recolorButton(pause, white, blue);
    relabelButton(pause,"PAUSE");
    lockButton(preview,true,grey,charcoal);
    lockButton(load,true,grey,charcoal);
    lockButton(process,true,grey,charcoal);
    lockButton(update,true,grey,charcoal);
  } else if(running && paused){
    lockButton(pause, false, blue, white);
    relabelButton(pause,"UNPAUSE");
    recolorButton(pause,blue,charcoal);
    lockButton(start, false, red, white);
    relabelButton(start, "RESET");
  }else if( loaded && processed ) {
    lockButton(start,false,green,white);
    relabelButton(start,"START");
    lockButton(pause,true, grey, charcoal);
    relabelButton(pause,"PAUSE");
    lockButton(preview,false,white,black);
    lockButton(load,false,black,white);
    lockButton(process,false,black,white);
    lockButton(update,false,black,white);
  }
  
  
}

// TOGGLE PREVIEW
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Turns on/off preview mode
void togglePreview(){
  runPreview = !runPreview;
  Bang preview = cP5.get(Bang.class, "preview");
  
  if(runPreview){
    preview.setColorForeground(red)
    .getCaptionLabel().setText("END PREVIEW");
  } else {
    preview.setColorForeground(black)
    .getCaptionLabel().setText("RUN PREVIEW");
    posx = 0;
    posy = 0;
  }
}

void loadColorSettings(){
  Textfield m_feed = cP5.get(Textfield.class, "moveSpeed");
  Toggle m_blast = cP5.get(Toggle.class, "moveBlast");
  Textfield d_time = cP5.get(Textfield.class, "dwellTime");
  Toggle d_blast = cP5.get(Toggle.class, "dwellBlast");
  
  JSONObject c_ = colorSettings.getJSONObject("colors").getJSONObject( str(selectedColor) );
  
  m_feed.setText( str( c_.getFloat("move_feed") ) );
  m_blast.setState( c_.getBoolean("move_blast") );
  d_time.setText( str( c_.getFloat("dwell_time") ) );
  d_blast.setState( c_.getBoolean("dwell_blast") );
  
}

void updateColorSettings(){
  Textfield m_feed = cP5.get(Textfield.class, "moveSpeed");
  Toggle m_blast = cP5.get(Toggle.class, "moveBlast");
  Textfield d_time = cP5.get(Textfield.class, "dwellTime");
  Toggle d_blast = cP5.get(Toggle.class, "dwellBlast");
  
  JSONObject c_ = colorSettings.getJSONObject("colors").getJSONObject( str(selectedColor) );
  
  c_.setFloat( "move_feed", float(m_feed.getText()) );
  c_.setBoolean( "move_blast", m_blast.getState() );
  c_.setFloat( "dwell_time", float(d_time.getText()) );
  c_.setBoolean( "dwell_blast", d_blast.getState() );
  
  saveJSONObject( colorSettings, "data/settings.json" );
  
}