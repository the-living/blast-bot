//------------------------------------------------------------------------------
// UX FUNCTIONS
//------------------------------------------------------------------------------
// Functions that control UX behavior

//CONTROLP5 INTERFACE CONTROLS
//Functions are handled via triggering "events"
void controlEvent( ControlEvent theEvent ) {
  if ( theEvent.isController() ) {

    String eventName = theEvent.getName();

    switch( eventName ) {

      //PREVIEW AREA COMMANDS
    case "start":
      println("START triggered");
      break;
    case "pause":
      println("PAUSE triggered");
      break;
    case "reset":
      println("RESET triggered");
      break;
    case "preview":
      println("PREVIEW triggered");
      break;

      //MANUAL CONTROL COMMANDS
    case "y+100":
      relativeMove(0,100);
      break;
    case "y+10":
      relativeMove(0,10);
      break;
    case "y-10":
      relativeMove(0,-10);
      break;
    case "y-100":
      relativeMove(0,-100);
      break;
    case "x+100":
      println("X+100 triggered");
      break;
    case "x+10":
      println("X+10 triggered");
      break;
    case "x-10":
      println("X-10 triggered");
      break;
    case "x-100":
      println("X-100 triggered");
      break;
    case "home":
      println("GO HOME triggered");
      break;
    case "blastOff":
      println("BLAST OFF triggered");
      break;
    case "blastOn":
      println("BLAST ON triggered");
      break;
    case "airOff":
      println("AIR OFF triggered");
      break;
    case "airOn":
      println("AIR ON triggered");
      break;
    case "override":
      println("OVERRIDE toggled");
      break;
    case "origin":
      println("SET ORIGIN triggered");
      break;
    case "cmdEntry":
      println("MANUAL COMMAND entered");
      break;

      //FILE SETTING COMMANDS
    case "load":
      //println("LOAD FILE triggered");
      selectInput("Select DXF file: ", "fileSelection");
      break;
    case "process":
      println("PROCESS FILE triggered");
      break;
    case "timeCalc":
      println("RECALCULATE TIME triggered");
      break;
    case "moveSpeed":
      println("MOVE SPEED entered");
      break;
    case "moveBlast":
      println("MOVE BLAST toggled");
      break;
    case "dwellTime":
      println("DWELL TIME entered");
      break;
    case "dwellBlast":
      println("DWELL BLAST toggled");
      break;
    case "update":
      println("UPDATE SETTINGS triggered");
      break;

    default:
      break;
    }
  }
}

void relativeMove( float x, float y ){
  //send move command relative to current position
}

void fileSelection(File selection) {
  if ( selection != null ) {
    fullPath = selection.getPath();
    int breakPos = fullPath.lastIndexOf('\\');
    currentPath = fullPath.substring(breakPos+1);
    loaded = true;
    processed = false;
  }
}