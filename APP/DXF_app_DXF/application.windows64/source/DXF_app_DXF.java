import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import controlP5.*; 
import processing.serial.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class DXF_app_DXF extends PApplet {

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// blast-bot Sandblasting Robot | The Living | 2016                           //
// v.1 2016.08.30                                                             //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// UI Setup                                                                   //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// EXTERNAL DEPENDENCIES
//------------------------------------------------------------------------------



//------------------------------------------------------------------------------
// GLOBAL VARIABLES
//------------------------------------------------------------------------------

//UI Variables
ControlP5 cP5;
PFont font24, font18, font16i, font14, font12;
int black, white, grey, charcoal, green, red, blue;
PVector origin;
PShape preview;
float scalar = 0.5f;

//File Variables
String currentPath;
String fullPath;
Boolean loaded;
Boolean processed;
JSONObject geojson;

//Color Setting Variables
JSONObject colorSettings;
JSONObject colorACD;
IntList colors;
Boolean colorLoaded;
String acdColor = "acd_2_hex.json";
int selectedColor;

//Command Variables
GCODEbuffer loader;
GCODEbuffer GB;
GCODEbuffer interrupt;

String timeLeft;
int geoCount;
int lastGeo;
String lineNum;

//Operation Variables
float posx, posy;
float lastf;
Boolean runPreview;
Boolean running;
Boolean paused;
Boolean override;
Float defaultSpeed;

//Serial Variables
Serial myPort;
String val;
StringList lastVal;
String lastSent;
Boolean connected;
String port;

//DEBUG
Boolean VERBOSE = false;


//------------------------------------------------------------------------------
// SETUP
//------------------------------------------------------------------------------
public void setup() {
  settings();

  initVariables();
  initFonts();
  initColors();
  setupControls();

  //load ACD color conversion table
  colorACD = loadJSONObject( acdColor );

  //selectInput("Select DXF file: ", "fileSelection");

  serialConnect();
  checkFiles();
}

//------------------------------------------------------------------------------
// DRAW LOOP
//------------------------------------------------------------------------------
public void draw() {
  displayUI();
  displayStats();

  checkStatus();
  monitorConnection();

  if ( preview != null && runPreview == false ) {
    preview.enableStyle();
    shape( preview, 0, 0);
    lastGeo = 0;
  } else if ( runPreview == true ) {
    lastGeo = min(lastGeo, geoCount);
    posx = 0;
    posy = 0;

    renderGCODE( loader, lastGeo );
    if (lastGeo < geoCount) {
      if (geoCount < 1000) {
        if (frameCount % 20 == 0) {
          lastGeo++;
        }
      } else {
        lastGeo++;
      }
    }
  }

  renderNozzle();
}

//------------------------------------------------------------------------------
// APP SETTINGS
//------------------------------------------------------------------------------
public void settings() {
  size(1200, 800);
}

public void initVariables() {
  origin = new PVector(25, 250);
  currentPath = "No file loaded.";
  loaded = false;
  colorLoaded = false;
  processed = false;

  loader = new GCODEbuffer();
  GB = new GCODEbuffer();
  interrupt = new GCODEbuffer();

  lastVal = new StringList("...");
  lastSent = "...";
  timeLeft = "0:00:00";
  geoCount = 0;
  lastGeo = 0;
  posx = 0.0f;
  posy = 0.0f;
  lastf = 25.0f;
  defaultSpeed = 25.0f;
  runPreview = false;
  running = false;
  paused = false;
  override = false;
  connected = false;
}
//------------------------------------------------------------------------------
// DXF Parser
//------------------------------------------------------------------------------
// Methods for extracting data from DXF files


// PARSE DXF GEOMETRY
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Extracts geometry objects from section of DXF text
// and saves them to JSON organized by layer
//
public void parseDXF( JSONObject json, JSONObject settings, String[] dxf ) {
  String[] entity;
  String[][] ent;
  
  //Isolate section of DXF file containing Geo
  dxf = cutSection( dxf, "ENTITIES", "ENDSEC" );

  //Count number of geo items
  int numEntities = 0;
  for ( int i = 0; i < dxf.length; i++ ) {
    if ( dxf[i].contains(" 0") ) {
      numEntities++;
    }
  }

  //concatenate strings for chunking into invidual geo
  String joindxf;
  joindxf = join( dxf, "~" );

  //split concatenated string by geo start marker
  entity = split( joindxf, " 0" );

  //add each geo to ent array and split attributes
  if(VERBOSE) println(numEntities + " found.");
  
  ent = new String[numEntities + 1][];
  JSONArray values = new JSONArray();

  IntList layers = new IntList();
  IntList colors = new IntList();

  Boolean openPolyline = false;
  JSONObject geo = new JSONObject();
  JSONArray vert = new JSONArray();
  int vertCount = 0;

  for ( int i = 0; i <= numEntities; i++) {
    ent[i] = split( entity[i], "~" );

    if ( ent[i].length > 1 ) {
      
      switch( ent[i][1] ) {
      case "ARC":
        if(VERBOSE) println("ARC found!");
        geo = parseArc( ent[i] );
        break;
      case "LINE":
        if(VERBOSE) println("LINE found!");
        geo = parseLine( ent[i] );
        break;
      case "POINT":
        if(VERBOSE) println("POINT found!");
        geo = parsePoint( ent[i] );
        break;
      case "POLYLINE":
        if(VERBOSE) println("POLYLINE found!");
        openPolyline = true;
        geo = parsePolyline( ent[i]);
        break;
      case "VERTEX":
        if(VERBOSE) println("VERTEX found!");
        vert = parseVertex( ent[i]);
        break;
      case "SEQEND":
        if(VERBOSE) println("ENDSEQ found!");
        openPolyline = false;
        vertCount = 0;
        break;
      default:
        continue;
      }      
      if (openPolyline == true) {
        if( vert.size() > 0 ){
          geo.getJSONArray("endPts").append(vert);
          vertCount++;
          geo.setInt("vertCount", vertCount);
        }
      } else {
        if (VERBOSE) {
          println( geo.getString("type") + " added!" );
        }
        values.append(geo);

        //compile list of layers & colors
        int l = geo.getInt("layer");
        if ( layers.hasValue( l ) == false ) {
          layers.append( l );
        }
        int c = geo.getInt("color");
        if ( colors.hasValue( c ) == false ) {
          colors.append( c );
        }
      }
    }
  }

  //add geo to JSON
  json.setJSONArray("ENTITIES", values);
  json.setInt( "entityCount", values.size() );

  //sort layer & color lists
  layers.sort();
  colors.sort();

  //add layers list to JSON
  JSONObject layerObj = new JSONObject();
  JSONArray layerList = new JSONArray();
  for ( int i = 0; i < layers.size(); i++ ) {
    layerList.setInt(i, layers.get(i));
    layerObj.setJSONObject( str(layers.get(i)), new JSONObject() );
  }
  json.setJSONObject("layers", layerObj);
  json.setJSONArray("layerList", layerList);

  //add colors list to JSON
  JSONObject colorObj = new JSONObject();
  JSONArray colorList = new JSONArray();
  for ( int i = 0; i < colors.size(); i++ ) {
    colorList.setInt(i, colors.get(i));
    colorObj.setJSONObject( str( colors.get(i) ), new JSONObject() );
  }
  
  colorInit( colorObj, colorList );

  settings.setJSONObject("colors", colorObj);
  settings.setJSONArray("colorList", colorList);

  sortGeo( json );
  if( json.getJSONArray("ENTITIES").size() == 0 ){
    json.remove("ENTITIES");
  }
}

// CUT SECTION
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Returns a subset of strings bounded by indicated
// start and end index
//
public String[] cutSection( String[] dxfs, String startcut, String endcut ) {

  //Loop through DXF strings to find starting point
  int cutS = -1;
  for ( int i = 0; i < dxfs.length; i++) {
    if ( dxfs[i].contains( startcut ) ) {
      cutS = i;
    }
  }

  //Report error if section not found
  if ( cutS == -1) {
    println( "SECTION " + startcut + " NOT FOUND." );
  }

  //Ignore dataset before desired starting point
  dxfs = subset( dxfs, cutS + 1 );

  //Loop through DXF strings to find ending point
  int cutF = -1;
  for ( int i = 0; i < dxfs.length; i++ ) {
    if ( dxfs[i].contains( endcut ) ) {
      cutF = i;
      break;
    }
  }

  //Report error if end not found
  if ( cutF == -1 ) {
    println( "SECTION NOT TERMINATED at " + endcut + ".");
  }

  return subset( dxfs, 0, cutF-1 );
}

// SORT GEOMETRY
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Extracts geometry objects from JSON entities
// and organizes in layers by shortest path sequence
//

public void sortGeo( JSONObject j ) { 

  JSONArray lastPt = new JSONArray();
  lastPt.setFloat(0, 0.0f);
  lastPt.setFloat(1, 0.0f);

  //iterate through layers in JSON
  JSONObject l = j.getJSONObject("layers");
  JSONArray ll = j.getJSONArray("layerList");
  JSONArray e = j.getJSONArray("ENTITIES");

  for ( int i = 0; i < ll.size(); i++ ) {

    int currentLayer = ll.getInt(i);
    JSONObject layer = l.getJSONObject( str(i) );

    JSONArray layerObj = new JSONArray();

    //iterate backwards through remaining geo entities
    //and if in current layer, copy to "layerObj" array
    //and remove from queue
    for ( int k = e.size()-1; k >= 0; k-- ) {
      if ( e.isNull(k) ) {
        continue;
      }
      JSONObject ent = e.getJSONObject(k);

      if ( ent.getInt("layer") == currentLayer ) {
        layerObj.setJSONObject( layerObj.size(), ent );
        e.remove(k);
      }
    }

    layer.setInt("geoCount", layerObj.size());
    layer.setJSONArray("entities", layerObj);

    int counter = 0;
    while ( counter < 10000 && layerObj.size() > 0 ) {
      counter++;

      FloatList dists = checkDistances( lastPt, layerObj );
      int objPos = dists.index( dists.min() );

      JSONObject nextObj = layerObj.getJSONObject(objPos);
      if( dists.min() <= 0 ){
        nextObj.setInt("connectLine", 0);
      } else {
        nextObj.setInt("connectLine", 1);
      }
      
      layerObj.remove(objPos);

      layer.setJSONObject( str(counter), nextObj );

      JSONArray pts = nextObj.getJSONArray("endPts");
      if ( nextObj.getInt("dir") == 0 ) {
        lastPt = pts.getJSONArray( pts.size()-1 );
      } else {
        lastPt = pts.getJSONArray( 0 );
      }
    }

    if ( layerObj.size() == 0 ) {
      layer.remove("entities");
    }
  }
}

// INITIALIZE COLOR SETTINGS
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Initializes JSON of color settings
public void colorInit( JSONObject j, JSONArray jList ){
  
  for(int i = 0; i < jList.size(); i++){
    String c = str( jList.getInt(i) );
    //println("c: " + c);
    JSONArray dispColor;
    Float moveFeed = 50.0f;
    boolean moveBlast = false;
    Float dwellTime = 1000.0f;
    boolean dwellBlast = false;
    
    if( !colorACD.isNull(c) ){
      dispColor = colorACD.getJSONArray(c);
    } else {
      dispColor = colorACD.getJSONArray("0");
    }
    
    JSONObject geoColor = j.getJSONObject(c);
    
    geoColor.setJSONArray("display_color", dispColor);
    geoColor.setBoolean("move_blast", moveBlast);
    geoColor.setBoolean("dwell_blast", dwellBlast);
    geoColor.setFloat("move_feed", moveFeed);
    geoColor.setFloat("dwell_time", dwellTime);
  }
}

// CHECK DISTANCES
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Measures distance from given start point to all objects
// in JSON Array, and returns a list of distances
public FloatList checkDistances( JSONArray pt, JSONArray objs ) {
  FloatList dists = new FloatList();
  StringList types = new StringList();

  for (int i = 0; i < objs.size(); i++) {
    JSONObject obj = objs.getJSONObject(i);
    JSONArray pts = obj.getJSONArray("endPts");

    float d = getDist( pt, pts.getJSONArray(0) );

    if ( obj.getString("type").contains("POINT") && d < 0.001f ) {
      d = -10.0f;
    }

    obj.setInt("dir", 0);

    if ( pts.size() > 1 ) {
      float d1 = getDist( pt, pts.getJSONArray( pts.size()-1 ) );
      if ( d1 < d ) {
        obj.setInt("dir", 1);
        d = d1;
      }
    }
    dists.append( d );
    types.append( obj.getString("type") );
  }

  if (VERBOSE) {
    println( types );
    println( dists );
  }
  return dists;
}

// GET DISTANCES
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Method for measuring distance between points formatted
// as JSONArray objects
public Float getDist( JSONArray p1, JSONArray p2 ) {
  return sqrt( pow(p1.getFloat(0)-p2.getFloat(0), 2) + pow(p1.getFloat(1)-p2.getFloat(1), 2) );
}

// PARSE POINT
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Extracts point attributes from DXF data
//
public JSONObject parsePoint( String[] ent ) {
  //create JSON object for return
  JSONObject geo = new JSONObject();
  //initialize geometry parameters
  String type = ent[1];
  JSONArray endPts = new JSONArray();
  JSONArray pt1 = new JSONArray();
  int dir = 0;
  int layer = 0;
  int geoColor = 0;

  //loop through entity and extract parameters
  for ( int i = 0; i < ent.length-1; i++) {

    String val = ent[i+1].trim();

    switch( PApplet.parseInt( ent[i].trim() ) ) {
    case 8:
      layer = PApplet.parseInt( ent[i+1] );
      i++;
      break;
    case 62:
      geoColor = PApplet.parseInt( val );
      i++;
      break;
    case 10:
      pt1.setFloat(0, PApplet.parseFloat(val) );
      i++;
      break;
    case 20:
      pt1.setFloat(1, PApplet.parseFloat(val) );
      i++;
      break;
    default:
      break;
    }
  }

  endPts.setJSONArray(0, pt1);

  //add parameters to JSON object
  geo.setString("type", type);
  geo.setInt("layer", layer);
  geo.setInt("color", geoColor);
  geo.setJSONArray("endPts", endPts);

  return geo;
}

// PARSE LINE
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Extracts line attributes from DXF data
//
public JSONObject parseLine( String[] ent ) {
  //create JSON object for return
  JSONObject geo = new JSONObject();
  //initialize geometry parameters
  String type = ent[1];
  JSONArray p1 = new JSONArray();
  JSONArray p2 = new JSONArray();
  JSONArray endPts = new JSONArray();
  int layer = 0;
  int geoColor = 0;

  //loop through entity and extract parameters
  for ( int i = 0; i < ent.length-1; i++) {

    String val = ent[i+1].trim();

    switch( PApplet.parseInt( ent[i].trim() ) ) {
    case 8:
      layer = PApplet.parseInt( val );
      i++;
      break;
    case 62:
      geoColor = PApplet.parseInt( val );
      i++;
      break;
    case 10:
      p1.setFloat(0, PApplet.parseFloat(val) );
      i++;
      break;
    case 11:
      p2.setFloat(0, PApplet.parseFloat(val) );
      i++;
      break;
    case 20:
      p1.setFloat(1, PApplet.parseFloat(val) );
      i++;
      break;
    case 21:
      p2.setFloat(1, PApplet.parseFloat(val) );
      i++;
      break;
    default:
      break;
    }
  }

  endPts.setJSONArray(0, p1);
  endPts.setJSONArray(1, p2);

  //add parameters to JSON object
  geo.setString("type", type);
  geo.setInt("layer", layer);
  geo.setInt("color", geoColor);
  geo.setJSONArray("endPts", endPts);
  geo.setInt("dir", 0);

  return geo;
}

// PARSE ARC
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Extracts arc attributes from DXF data
//
public JSONObject parseArc( String[] ent ) {
  //create JSON object for return
  JSONObject geo = new JSONObject();
  //initialize geometry parameters
  String type = ent[1];
  JSONArray centerPt = new JSONArray();
  JSONArray endPts = new JSONArray();
  JSONArray p1 = new JSONArray();
  JSONArray p2 = new JSONArray();
  float radius = 0.0f;
  float startAngle = 0.0f;
  float endAngle = 0.0f;
  int dir = 0;
  int layer = 0;
  int geoColor = 1;

  //loop through entity and extract parameters
  for ( int i = 0; i < ent.length-1; i++) {

    String val = ent[i+1].trim();

    switch( PApplet.parseInt( ent[i].trim() ) ) {
    case 8:
      layer = PApplet.parseInt( val );
      i++;
      break;
    case 62:
      geoColor = PApplet.parseInt( val );
      i++;
      break;
    case 10:
      centerPt.setFloat(0, PApplet.parseFloat(val) );
      i++;
      break;
    case 20:
      centerPt.setFloat(1, PApplet.parseFloat(val) );
      i++;
      break;
    case 40:
      radius = PApplet.parseFloat( val );
      i++;
      break;
    case 50:
      startAngle = PApplet.parseFloat( val );
      i++;
      break;
    case 51:
      endAngle = PApplet.parseFloat( val );
      i++;
      break;
    default:
      break;
    }
  }

  //calculate end points
  p1.setFloat(0, cos( radians(startAngle) ) * radius + centerPt.getFloat(0));
  p1.setFloat(1, sin( radians(startAngle) ) * radius + centerPt.getFloat(1));

  p2.setFloat(0, cos( radians(endAngle) ) * radius + centerPt.getFloat(0));
  p2.setFloat(1, sin( radians(endAngle) ) * radius + centerPt.getFloat(1));

  endPts.setJSONArray(0, p1);
  endPts.setJSONArray(1, p2);


  //add parameters to JSON object
  geo.setString("type", type);
  geo.setInt("layer", layer);
  geo.setInt("color", geoColor);
  geo.setJSONArray("centerPt", centerPt);
  geo.setJSONArray("endPts", endPts);
  geo.setInt("dir", dir);
  geo.setFloat("radius", radius);
  geo.setFloat("startAngle", startAngle);
  geo.setFloat("endAngle", endAngle);

  return geo;
}

// PARSE POLYLINE
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Extracts polyline attributes & vertices from DXF data
//
public JSONObject parsePolyline( String[] ent) {
  JSONObject geo = new JSONObject();
  //initialize geo parameters
  String type = ent[1];
  JSONArray endPts = new JSONArray();
  int vertCount = 0;
  int dir = 0;
  int layer = 0;
  int geoColor = 0;


  for ( int i = 0; i < ent.length-1; i++ ) {

    String val = ent[i+1].trim();

    switch( PApplet.parseInt( ent[i].trim() ) ) {
    case 8:
      layer = PApplet.parseInt( val );
      i++;
      break;
    case 62:
      geoColor = PApplet.parseInt( val );
      i++;
      break;
    default:
      break;
    }
  }

  geo.setString("type", type);
  geo.setInt("layer", layer);
  geo.setInt("color", geoColor);
  geo.setJSONArray("endPts", endPts);
  geo.setInt("vertCount", vertCount);
  geo.setInt("dir", dir);

  return geo;
}

// PARSE VERTEX
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Extracts vertices from DXF data
//
public JSONArray parseVertex( String[] ent) {
  JSONArray vert = new JSONArray();

  for ( int i = 0; i < ent.length-1; i++ ) {
    String val = ent[i+1].trim();
    switch( PApplet.parseInt(ent[i].trim()) ) {
    case 10:
      vert.setFloat(0, PApplet.parseFloat(val));
      i++;
      break;
    case 20:
      vert.setFloat(1, PApplet.parseFloat(val));
      i++;
      break;
    default:
      break;
    }
  }
  return vert;
}
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
  public void write( String code ) {
    String gcode;

    gcode = code;

    GCode.append( gcode );
  }

  //SEND NEXT
  //Returns next available command to pass to Arduino
  public String sendNext() {
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
  public boolean getEnd() {
    return GCode.size() <= 0;
  }
  
  //GET ITEM
  public String get(int i){
    return GCode.get(i);
  }
  
  //DUPLICATE BUFFER
  //Clears all data in buffer
  public void copyBuffer(GCODEbuffer g) {
    flushBuffer();
    for ( int i = 0; i < g.size(); i++ ) {
      write( g.get(i) );
    }
  }
  
  //FLUSH BUFFER
  //Clears all data in buffer
  public void flushBuffer() {
    for ( int i = GCode.size()-1; i >= 0; i-- ) {
      GCode.remove(i);
    }
  }

  //SIZE
  //Returns size of GCode Buffer
  public int size() {
    return GCode.size();
  }

  //FORMAT LINE TIME
  //Format contents of buffer to add line numbers
  //and time estimates
  public void formatLineTime() {
    ArrayList<Float> time = new ArrayList<Float>();
    float timeTotal = 0;

    PVector pos = new PVector( 0, 0 );

    for ( int i = 0; i < GCode.size(); i++ ) {
      String cmd = GCode.get(i);

      int gType = PApplet.parseInt( parseNumber(cmd, "G", -1) );
      if (gType != -1) {

        float duration = 0.0f;
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
          
          cx = parseNumber(cmd, "I", 0.0f);
          cy = parseNumber(cmd, "J", 0.0f);
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
          int segments = PApplet.parseInt(ceil(l));
          
          newPos = new PVector();
          for( int k = 0; k < segments; k++ ){
            float scale = PApplet.parseFloat(k) / PApplet.parseFloat(segments);
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
          duration = parseNumber( cmd, "P", 0 )/1000.0f;
          time.add( duration );
          timeTotal += duration;
          break;
        }
      } else {
        time.add( 0.0f );
      }
      
    }
    time_estimate = nf( PApplet.parseInt(timeTotal/3600),2)+":"+nf(PApplet.parseInt((timeTotal%3600)/60),2)+":"+nf(PApplet.parseInt(timeTotal%60),2);
    
    //loop back through and add timestamps
    for ( int i = 0; i < GCode.size(); i++) {
      //decimate total time
      timeTotal -= time.get(i);

      //generate formatted timestamp (mm:ss)
      String timeStamp = nf( PApplet.parseInt(timeTotal/60), 2) + ":" + nf( PApplet.parseInt(timeTotal%60), 2);

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
//------------------------------------------------------------------------------
// GCODE Commands
//------------------------------------------------------------------------------
// Functions that generate GCODE commands

// G00/G01 - LINE COMMAND
public String gcodeLine(float x, float y, float f, boolean spray){
  if( spray ) return "G01 X"+str(x) + " Y"+str(y) + " F"+str(f);
  else return "G00 X"+str(x) + " Y"+str(y) + " F"+str(f);
}

// G02/G03 - ARC COMMANDS
public String gcodeArc(float cx, float cy, float x, float y, float f, boolean dir){
  //clockwise = 2 ... counterclockwise = 3
  if( dir ) return "G02 I"+str(cx) + " J"+str(cy) + " X"+str(x) + " Y"+str(y) + " F"+str(f);
  else return "G03 I" + str(cx) + " J" + str(cy) + " X" + str(x) + " Y" + str(y) + " F"+str(f);
}

// G04/G05 - PAUSE/DWELL COMMAND
public String gcodeDwell( float time, boolean spray ){
  if(spray){
    return "G05 P" + str(time);
  } else {
    return "G04 P" + str(time);
  }
}

//M50 BLAST ON
public String gcodeBlastOn(){
  return "M50";
}

//M51 BLAST OFF
public String gcodeBlastOff(){
  return "M51";
}

//M60 AIR ON
public String gcodeAirOn(){
  return "M60";
}

//M61 AIR OFF
public String gcodeAirOff(){
  return "M61";
}

public String gcodeTeleportTo( float x, float y ){
  return "M100 X" + str(x) + " Y" + str(y);
}
//------------------------------------------------------------------------------
// JSON/GCODE Display
//------------------------------------------------------------------------------
// Functions for rendering JSON and GCODE geo to screen

// RENDER JSON GEO
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Render geometry from JSON file to preview window
public void renderJSONgeo( JSONObject json ) {
  
  preview = new PShape();

  JSONArray layerList = json.getJSONArray("layerList");
  JSONObject layers = json.getJSONObject("layers");

  for (int l = 0; l < layerList.size(); l++) {
    JSONObject layer = layers.getJSONObject( str( layerList.getInt( l ) ) );
    for ( int e = 1; e <= layer.getInt("geoCount"); e++ ) {
      JSONObject geo = layer.getJSONObject( str(e) );
      
      int colorIndex = geo.getInt("color");
      JSONArray c_ = colorSettings.getJSONObject("colors").getJSONObject(str(colorIndex)).getJSONArray("display_color");
      int c = color(c_.getInt(0), c_.getInt(1), c_.getInt(2));
      
      switch( geo.getString("type") ) {
        case "POINT":
          addPoint(geo, c );
          break;
        case "LINE":
          addLine(geo, c );
          break;
        case "ARC":
          addArc(geo, c );
          break;
        case "POLYLINE":
          addPolyline(geo, c );
          break;
        default:
          break;
      }
    }
  }
}

// RENDER GCODE GEO
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Render geometry from GCODE to preview window up to
// a given command index (to allow for scrubbing)
public void renderGCODE( GCODEbuffer code, int step ) {

  step = min( step, code.size() );
  
  PVector lastPt = new PVector(0,0);
  StringList objs = new StringList();

  for (int i = 0; i < code.size(); i++) {
    if ( objs.size() >= step ) break;
    
    objs.append( code.get(i) );
  }

  for ( int i = 0; i < objs.size(); i++ ) {
    String line = objs.get(i);
    
    //Strip any existing line numbers and timestamps
    int startIndex = 0;
    if ( line.charAt(0) == 'N' ) startIndex = line.indexOf(" ")+1;
    int endIndex = line.indexOf(" *");
    if ( endIndex == -1 ) endIndex = line.length();

    lastSent = line.substring(startIndex, endIndex);
    
    int type = PApplet.parseInt( parseNumber( line, "G", -1 ) );
    int c;
    
    if( type == 0 || type == 4 ){
      c = blue;
    } else {
      c = red;
    }
    
    stroke(c);
    noFill();
    
    switch( type ) {
    case 0:
    case 1:
      renderGcodeLine( line, lastPt );
      break;
    case 2:
    case 3:
      renderGcodeArc( line, lastPt );
      break;
    case 4:
    case 5:
      renderGcodePoint( line, lastPt );
      break;
    default:
      break;
    }
  }
}


// ADD POINT TO PREVIEW
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Add Point PSHAPE object to Preview PSHAPE
public void addPoint(JSONObject pt, int c ) {
  PShape p;
  
  JSONArray loc = pt.getJSONArray("endPts").getJSONArray(0);
  float x = loc.getFloat(0);
  float y = loc.getFloat(1);
  
  strokeWeight(8);
  stroke(c);
  noFill();
  p = createShape(POINT, origin.x+x*scalar, origin.y-y*scalar);

  preview.addChild( p );
}

// ADD LINE TO PREVIEW
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Add Line PSHAPE object to Preview PSHAPE
public void addLine( JSONObject ln, int c ) {
  PShape l;
  
  JSONArray p1 = ln.getJSONArray("endPts").getJSONArray(0);
  JSONArray p2 = ln.getJSONArray("endPts").getJSONArray(1);
  float x1 = p1.getFloat(0);
  float y1 = p1.getFloat(1);
  float x2 = p2.getFloat(0);
  float y2 = p2.getFloat(1);
  
  strokeWeight(2);
  stroke(c);
  noFill();
  l = createShape(LINE, origin.x+x1*scalar, origin.y-y1*scalar, origin.x+x2*scalar, origin.y-y2*scalar);

  preview.addChild( l );
}

// ADD ARC TO PREVIEW
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Add Arc PSHAPE object to Preview PSHAPE
public void addArc( JSONObject arc, int c ) {
  PShape a;
  
  JSONArray cp = arc.getJSONArray("centerPt");
  float cx = cp.getFloat(0);
  float cy = cp.getFloat(1);
  float r = arc.getFloat("radius");
  float SA = 360-arc.getFloat("startAngle");
  float EA = 360-arc.getFloat("endAngle");

  if ( EA > SA ) {
    SA += 360;
  }
  
  strokeWeight(2);
  stroke(c);
  noFill();
  a = createShape(ARC, origin.x+cx*scalar, origin.y-cy*scalar, r*2*scalar, r*2*scalar, radians(EA), radians(SA));

  preview.addChild( a );
}

// ADD POLYLINE TO PREVIEW
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Add Polyline PSHAPE object to Preview PSHAPE
public void addPolyline( JSONObject pl, int c ) {
  PShape poly = createShape();
  
  JSONArray pts = pl.getJSONArray("endPts");
  poly.beginShape();
  poly.strokeWeight(2);
  poly.stroke(c);
  poly.noFill();
  
  for ( int i = 0; i < pts.size(); i++) {
    JSONArray p = pts.getJSONArray(i);

    float x = p.getFloat(0);
    float y = p.getFloat(1);

    poly.vertex(origin.x+x*scalar, origin.y-y*scalar);
  }
  
  poly.endShape();
  preview.addChild(poly);
}

// RENDER GCODE POINT
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Render point from G04 or G05 command
public void renderGcodePoint( String code, PVector lastPt ){
  strokeWeight(8);
  point( origin.x+lastPt.x*scalar, origin.y-lastPt.y*scalar );
}

// RENDER GCODE LINE
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Render line from G00 or G01 command
public void renderGcodeLine( String code, PVector lastPt ){
  float x1 = lastPt.x;
  float y1 = lastPt.y;
  
  float x2 = parseNumber(code, "X", lastPt.x);
  float y2 = parseNumber(code, "Y", lastPt.y);
  

  strokeWeight(3);
  line(origin.x+x1*scalar,origin.y-y1*scalar,origin.x+x2*scalar,origin.y-y2*scalar);
  
  lastPt.x = x2;
  lastPt.y = y2;
}

// RENDER GCODE ARC
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Render arc from G02 or G03 command
public void renderGcodeArc( String code, PVector lastPt ){
  int dir = PApplet.parseInt( parseNumber(code, "G", -1) );
  
  float cx = parseNumber(code, "I", 0.0f);
  float cy = parseNumber(code, "J", 0.0f);
  float x = parseNumber(code, "X", lastPt.x);
  float y = parseNumber(code, "Y", lastPt.y);
  
  float dx2 = lastPt.x - cx;
  float dy2 = lastPt.y - cy;
  float dx1 = x - cx;
  float dy1 = y - cy;
  
  float r = sqrt( pow(dx1,2) + pow(dy1,2) );
  
  float SA = TWO_PI - atan2(dy1, dx1);
  float EA = TWO_PI - atan2(dy2, dx2);
  
  if( dir == 3 && SA > EA){
    EA += TWO_PI;
  } else if( dir == 2 && EA > SA){
    SA += TWO_PI;
  }
  
  strokeWeight(3);
  if( dir == 2){
    arc( origin.x+cx*scalar, origin.y-cy*scalar, r*2*scalar, r*2*scalar, EA, SA );
  } else {
    arc( origin.x+cx*scalar, origin.y-cy*scalar, r*2*scalar, r*2*scalar, SA, EA );
  }
  
  lastPt.x = x;
  lastPt.y = y;
}
//------------------------------------------------------------------------------
// GCODE Generator
//------------------------------------------------------------------------------
// Functions for converting JSON formatted geo to
// GCODE commands


// GENERATE GCODE
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Convert JSON of geometry to GCODE commands
//
public void genGCODE( JSONObject json, GCODEbuffer GCODE ){
  
  if (GCODE.size() > 0) GCODE.flushBuffer();
  
  if( json.isNull("layers") == true ) return;
  
  JSONObject layers = json.getJSONObject("layers");
  JSONArray layerList = json.getJSONArray("layerList");
  
  for(int i = 0; i < layerList.size(); i++){
    
    JSONObject layer = layers.getJSONObject( str(layerList.getInt(i)) );
    int geoCount = layer.getInt("geoCount");
    
    for( int j = 0; j < geoCount; j++ ){
      JSONObject geo = layer.getJSONObject( str(j+1) );
      StringList code;
      switch(geo.getString("type")){
        case "POINT":
          code = genPoint(geo);
          if(VERBOSE) println("Dwell GCODE output");
          break;
        case "LINE":
          code = genLine(geo);
          if(VERBOSE) println("Line GCODE output");
          break;
        case "ARC":
          code = genArc(geo);
          if(VERBOSE) println("Arc GCODE output");
          break;
        case "POLYLINE":
          code = genPolyline(geo);
          if(VERBOSE) println("Polyline GCODE output");
          break;          
        default:
          code = new StringList();
          if(VERBOSE) println("No Geo found");
          break;
      }
      
      for(int k = 0; k < code.size(); k++){
        if( code.get(k) != null ) GCODE.write( code.get(k) );
        
      }
    }
  }

  //Save GCODE to text
  saveStrings("data/gcode.txt", GCODE.GCode.array() );
} 

// GENERATE POINT
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Convert JSON point to G04 or G05 Command
public StringList genPoint( JSONObject pt ){  
  StringList code = new StringList();
  JSONArray pos = pt.getJSONArray("endPts").getJSONArray(0);
  
  int c = pt.getInt("color");
  JSONObject c_settings = colorSettings.getJSONObject("colors").getJSONObject(str(c));
  float p = c_settings.getFloat("dwell_time");
  boolean b = c_settings.getBoolean("dwell_blast");
  
  if( pt.getInt("connectLine") == 1 ){
    code.append( gcodeLine(pos.getFloat(0), pos.getFloat(1), defaultSpeed, false) );
    //code.append( gcodeLine(floatFormat(pos.getFloat(0),3), floatFormat(pos.getFloat(1),3), floatFormat(defaultSpeed,3), false) );
  }
  
  code.append( gcodeDwell(p, b) );
  
  return code;
}

// GENERATE LINE
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Convert JSON line to G00 or G01 Command
public StringList genLine( JSONObject ln ){
  StringList code = new StringList();
  int dir = ln.getInt("dir");
  
  int c = ln.getInt("color");
  JSONObject c_settings = colorSettings.getJSONObject("colors").getJSONObject(str(c));
  float feed = c_settings.getFloat("move_feed");
  boolean type = c_settings.getBoolean("move_blast");
  
  JSONArray p1 = ln.getJSONArray( "endPts" ).getJSONArray( dir );
  JSONArray p2 = ln.getJSONArray( "endPts" ).getJSONArray( abs(1-dir) );
  if( ln.getInt("connectLine") == 1){
    code.append( gcodeLine(p1.getFloat(0), p1.getFloat(1), defaultSpeed, false) );
    //code.append( gcodeLine(floatFormat(p1.getFloat(0),3), floatFormat(p1.getFloat(1),3), floatFormat(defaultSpeed,3), false) );
  }
  code.append( gcodeLine(p2.getFloat(0), p2.getFloat(1), feed, type) );
  //code.append( gcodeLine(floatFormat(p2.getFloat(0),3), floatFormat(p2.getFloat(1),3), floatFormat(feed,3), type) );
  return code;
}

// GENERATE ARC
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Convert JSON arc to G02 or G03 Command
//
public StringList genArc( JSONObject arc ){
  StringList code = new StringList();
  int dir = arc.getInt("dir");
  
  int c = arc.getInt("color");
  JSONObject c_settings = colorSettings.getJSONObject("colors").getJSONObject(str(c));
  float feed = c_settings.getFloat("move_feed");
  
  JSONArray cp = arc.getJSONArray("centerPt");
  JSONArray p1 = arc.getJSONArray( "endPts" ).getJSONArray( dir );
  JSONArray p2 = arc.getJSONArray( "endPts" ).getJSONArray( abs(1-dir) );

  if( arc.getInt("connectLine") == 1){
    code.append( gcodeLine(p1.getFloat(0), p1.getFloat(1), defaultSpeed, false) );
    //code.append( gcodeLine(floatFormat(p1.getFloat(0),3), floatFormat(p1.getFloat(1),3), floatFormat(defaultSpeed,3), false) );
  }
  code.append( gcodeArc(cp.getFloat(0), cp.getFloat(1), p2.getFloat(0), p2.getFloat(1), feed, dir==1) );
  //code.append( gcodeArc(floatFormat(cp.getFloat(0),3), floatFormat(cp.getFloat(1),3), floatFormat(p2.getFloat(0),3), floatFormat(p2.getFloat(1),3), floatFormat(feed,3), dir==1) );
  return code;
}

// GENERATE POLYLINE
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Convert JSON polyline into series of G00 or G01 Command
//
public StringList genPolyline( JSONObject pl ){
  StringList code = new StringList();
  ArrayList<PVector> pts = new ArrayList<PVector>();
  
  int dir = pl.getInt("dir");
  
  int c = pl.getInt("color");
  JSONObject c_settings = colorSettings.getJSONObject("colors").getJSONObject(str(c));
  float feed = c_settings.getFloat("move_feed");
  boolean type = c_settings.getBoolean("move_blast");
  
  for( int i = 0; i < pl.getJSONArray("endPts").size(); i++ ){
    JSONArray pt = pl.getJSONArray("endPts").getJSONArray(i);
    PVector v = new PVector( pt.getFloat(0), pt.getFloat(1));
    pts.add( v );
  }
  
  if(dir == 1){
    ArrayList<PVector> revList = new ArrayList<PVector>();
    for(int i = pts.size()-1; i > 0; i--){
      revList.add( pts.get(i) );
    }
    pts = revList;
  }
  
  if( pl.getInt("connectLine") == 1){
    code.append(gcodeLine(pts.get(0).x, pts.get(0).y, defaultSpeed, false));
    //code.append(gcodeLine(floatFormat(pts.get(0).x,3), floatFormat(pts.get(0).y,3), defaultSpeed, false));
  }
  
  for( int i = 1; i < pts.size(); i++ ){
    code.append(gcodeLine(pts.get(i).x, pts.get(i).y, feed, type));
    //code.append(gcodeLine(floatFormat(pts.get(i).x,3), floatFormat(pts.get(i).y,3), floatFormat(feed,3), type));
  }
  
  return code;
}
//------------------------------------------------------------------------------
// UX FUNCTIONS
//------------------------------------------------------------------------------
// Functions that control UX behavior

// CONTROLP5 INTERFACE CONTROLS
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Functions are handled via triggering "events"
public void controlEvent( ControlEvent theEvent ) {
  if ( theEvent.isController() ) {

    String eventName = theEvent.getName();

    switch( eventName ) {

      //PREVIEW AREA COMMANDS
    case "start":
      running = !running;
      if(running) GB.copyBuffer(loader);
      else GB.flushBuffer();
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
      selectedColor = PApplet.parseInt( eventName.substring(startIndex+1, eventName.length()) );
      loadColorSettings();
    }
  }
}

// MANUAL ENTRY
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Issues manually entered command to run immediately
public void manualEntry() {
  String cmd = cP5.get(Textfield.class, "cmdEntry").getText();
  interrupt.write( cmd );
}

// OVERRIDE TOGGLE
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Enables/disables manual override
public void toggleOverride() {
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
public void relativeMove( float x, float y ) {
  posx += x;
  posy += y;
  String code = gcodeLine( posx, posy, defaultSpeed, false );
  interrupt.write( code );
}

// FILE LOADING
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Opens dialogue for importing file to run
public void fileSelection(File selection) {
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
public void checkFiles() {
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
public void processFile(){
  if( geojson == null ) return;
  
  genGCODE(geojson, loader);
  geoCount = loader.size();
  processed = true;
  if(loader.size() > 0) loader.formatLineTime();
}

// LOCK BUTTON
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Allows setting of button lock and changing color
public void lockButton(Bang button, boolean lock, int c, int t){
  button.setLock(lock)
  .setColorForeground(c)
  .getCaptionLabel().setColor(t);
}

// RELABEL BUTTON
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Allows relabeling of button and changing color
public void relabelButton(Bang button, String newlabel){
  button.getCaptionLabel().setText(newlabel);
}

// RECOLOR BUTTON
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Allows recoloring of button default & active (hover) colors
public void recolorButton(Bang button, int c1, int c2){
  button.setColorForeground(c1)
  .setColorActive(c2);
}

// CHECK BUTTON STATUS
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Enables/disables buttons based on current state
public void checkStatus(){
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
    lockButton(preview,false,white,black);
    lockButton(load,false,black,white);
    lockButton(process,false,black,white);
    lockButton(update,false,black,white);
  }
  
  
}

// TOGGLE PREVIEW
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Turns on/off preview mode
public void togglePreview(){
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

public void loadColorSettings(){
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

public void updateColorSettings(){
  Textfield m_feed = cP5.get(Textfield.class, "moveSpeed");
  Toggle m_blast = cP5.get(Toggle.class, "moveBlast");
  Textfield d_time = cP5.get(Textfield.class, "dwellTime");
  Toggle d_blast = cP5.get(Toggle.class, "dwellBlast");
  
  JSONObject c_ = colorSettings.getJSONObject("colors").getJSONObject( str(selectedColor) );
  
  c_.setFloat( "move_feed", PApplet.parseFloat(m_feed.getText()) );
  c_.setBoolean( "move_blast", m_blast.getState() );
  c_.setFloat( "dwell_time", PApplet.parseFloat(d_time.getText()) );
  c_.setBoolean( "dwell_blast", d_blast.getState() );
  
  saveJSONObject( colorSettings, "data/settings.json" );
  
}
//------------------------------------------------------------------------------
// UX Interface
//------------------------------------------------------------------------------
// Functions for generating US


//DISPLAY UI
//----------------------------------------
//Draws user non-cP5 interface elements
public void displayUI() {
  background(0);

  //SETUP PREVIEW AREA
  //canvas area
  noStroke();
  fill(220);
  rect(25, 50, 1000, 200);
  //draw grid
  noFill();
  stroke(200);
  strokeWeight(1);
  for (int x = 10; x < 1000; x+=10) {
    line(x+25, 50, x+25, 250);
  }
  for (int y = 10; y < 200; y+=10) {
    line(25, y+50, 1025, y+50);
  }
  //frame canvas
  rect(25, 50, 1000, 200);

  //SETUP MANUAL CONTROL AREA
  //background
  noStroke();
  fill(220);
  rect(0, 325, 600, 475);
  //manual entry area
  fill(0);
  rect(0, 700, 590, 100);
  //button frame
  stroke(charcoal);
  strokeWeight(2);
  noFill();
  rect(15, 365, 320, 320);
  //label
  fill(black);
  textFont(font24, 24);
  text("MANUAL CONTROLS", 15, 355);

  //SETUP FILE SETTING AREA
  //background
  noStroke();
  fill(white);
  rect(600, 325, 600, 475);
  //labels
  fill(black);
  textFont(font24, 24);
  text("FILE SELECTION", 615, 355);
  text("SPEED SETTINGS", 615, 520);
  textFont(font16i, 16);
  text("CURRENT FILE", 795, 385);
  text("STEP COUNT", 795, 450);
  text("TIME ESTIMATE", 925, 450);
  text("G00", 795, 560);
  text("G01", 795, 580);
  text("G02", 795, 600);
  text("G03", 795, 620);
  text("G04", 795, 670);
  text("G05", 795, 690);

  //divider lines
  noFill();
  stroke(grey);
  strokeWeight(2);
  line(610, 365, 1190, 365);
  line(795, 430, 1190, 430);
  line(610, 530, 1190, 530);
  line(785, 540, 785, 790);
  line(795, 640, 1190, 640);
}

//RENDER NOZZLE POSITION
//----------------------------------------
//Draws nozzle position in the preview pane
public void renderNozzle(){
  stroke(white);
  fill(white,50);
  strokeWeight(3);
  ellipse(origin.x+(posx*scalar), origin.y-(posy*scalar),10,10);
  noFill();
  strokeWeight(0.5f);
  ellipse(origin.x+(posx*scalar), origin.y-(posy*scalar),20,20);
}

//DISPLAY STATS
//----------------------------------------
//Draws dynamic text elements elements
public void displayStats(){
  //PREVIEW AREA
  //Current Position
  String pos = "( "+posx+", "+posy+" )";
  fill(white);
  textFont(font24,24);
  text(pos,25,290);
  
  //TX Command
  fill(green);
  text(lastSent, 40+textWidth(pos), 290);
  
  //Preview Position / Time Left
  if(runPreview){
    pos = lastGeo + "/" + geoCount;
  } else if(running) {
    pos = timeLeft;
  } else {
    pos ="";
  }
  fill(white);
  textAlign(RIGHT);
  text(pos,815,290);
  textAlign(LEFT);
  
  //SERIAL Status
  String status;
  textFont(font18,18);
  if(!connected){
    status = "NOT CONNECTED";
    fill(red);
    text(status,25,45);
  } else {
    status = "CONNECTED ON " + port;
    fill(green);
    text(status, 25, 45);
  }
  
  //RX Value
  fill(red);
  textFont(font18,18);
  float x_ = 40.0f + textWidth(status);
  for ( int i = 0; i < lastVal.size(); i++ ) {
    text(lastVal.get(i), x_, 45);
    x_ += textWidth(lastVal.get(i));
    x_ += 15;
  }
  
  //FILE SETTINGS AREA
  //Current File
  String[] pathSegments = currentPath.split("/");
  String path = pathSegments[ pathSegments.length - 1];
  fill(black);
  textFont(font18,18);
  text(path,795,420);
  
  //Geo Count
  text(geoCount,795,480);
  
  //Time Estimate
  text(loader.time_estimate,925,480);
  
  //COLOR BORDERS
  PVector colorPos = new PVector(614,539);
  noFill();
  //stroke(black);
  //strokeWeight(1);
  
  if( colorLoaded ){
    int buttonSize, buttonSpacing, rowLength;
    if(colors.size() < 12){
      buttonSize = 50;
      buttonSpacing = 55;
      rowLength = 3;
    } else{
      buttonSize = 36;
      buttonSpacing = 41;
      rowLength = 4;
    }
    
    for(int i = 0; i < colors.size(); i++){
      if( selectedColor == colors.get(i) ){
        stroke(blue);
        strokeWeight(2);
      } else {
        stroke(black);
        strokeWeight(1);
      }
      rect(colorPos.x + buttonSpacing*(i%rowLength), colorPos.y + buttonSpacing*floor(i/rowLength), buttonSize+1, buttonSize+1);
    }
  }
  
}

public void initFonts() {
  font24 = loadFont("Roboto-Regular-24.vlw");
  font18 = loadFont("Roboto-Regular-18.vlw");
  font16i = loadFont("Roboto-Italic-16.vlw");
  font14 = loadFont("Roboto-Regular-14.vlw");
  font12 = loadFont("Roboto-Regular-12.vlw");
}

public void initColors() {
  black = color(0);
  white = color(255);
  grey = color(220);
  charcoal = color(100);
  red = color(237, 28, 36);
  green = color(57, 181, 74);
  blue = color(80, 150, 225);
}

public void setupControls() {
  //Initialize CP5 UX
  cP5 = new ControlP5(this);

  //global control panel settings
  cP5.setFont( font12 );
  cP5.setColorForeground( black );
  cP5.setColorBackground( white );
  cP5.setColorValueLabel( white );
  cP5.setColorCaptionLabel( white );
  cP5.setColorActive( blue );
  
  //SETUP PREVIEW AREA CONTROLS
  //---------------------------
  //START button
  cP5.addBang("start")
  .setPosition(1045,50)
  .setSize(140, 95)
  .setTriggerEvent(Bang.RELEASE)
  .setColorForeground(green)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(white)
  .setFont(font24)
  .setText("START")
  ;
  //PAUSE button
  cP5.addBang("pause")
  .setPosition(1045,155)
  .setSize(140, 95)
  .setTriggerEvent(Bang.RELEASE)
  .setColorForeground(red)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(white)
  .setFont(font24)
  .setText("PAUSE")
  ;
  //RUN PREVIEW button
  cP5.addBang("preview")
  .setPosition(825,260)
  .setSize(200, 40)
  .setTriggerEvent(Bang.RELEASE)
  .setColorForeground(white)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(black)
  .setFont(font18)
  .setText("RUN PREVIEW")
  ;
  
  //SETUP MANUAL CONTROLS
  //---------------------------
  //Y+100 button
  cP5.addBang("y+100")
  .setPosition(150,375)
  .setSize(50,50)
  .setTriggerEvent(Bang.RELEASE)
  .setColorForeground(black)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(white)
  .setFont(font12)
  .setText("Y+100")
  ;
  //Y+10 button
  cP5.addBang("y+10")
  .setPosition(150,430)
  .setSize(50,50)
  .setTriggerEvent(Bang.RELEASE)
  .setColorForeground(black)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(white)
  .setFont(font12)
  .setText("Y+10")
  ;
  //Y-100 button
  cP5.addBang("y-100")
  .setPosition(150,625)
  .setSize(50,50)
  .setTriggerEvent(Bang.RELEASE)
  .setColorForeground(black)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(white)
  .setFont(font12)
  .setText("Y-100")
  ;
  //Y-10 button
  cP5.addBang("y-10")
  .setPosition(150,570)
  .setSize(50,50)
  .setTriggerEvent(Bang.RELEASE)
  .setColorForeground(black)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(white)
  .setFont(font12)
  .setText("Y-10")
  ;
  //X-100 button
  cP5.addBang("x-100")
  .setPosition(25,500)
  .setSize(50,50)
  .setTriggerEvent(Bang.RELEASE)
  .setColorForeground(black)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(white)
  .setFont(font12)
  .setText("X-100")
  ;
  //X-10 button
  cP5.addBang("x-10")
  .setPosition(80,500)
  .setSize(50,50)
  .setTriggerEvent(Bang.RELEASE)
  .setColorForeground(black)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(white)
  .setFont(font12)
  .setText("X-10")
  ;
  //X+100 button
  cP5.addBang("x+100")
  .setPosition(275,500)
  .setSize(50,50)
  .setTriggerEvent(Bang.RELEASE)
  .setColorForeground(black)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(white)
  .setFont(font12)
  .setText("X+100")
  ;
  //X+10 button
  cP5.addBang("x+10")
  .setPosition(220,500)
  .setSize(50,50)
  .setTriggerEvent(Bang.RELEASE)
  .setColorForeground(black)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(white)
  .setFont(font12)
  .setText("X+10")
  ;
  
  //GO HOME button
  cP5.addBang("home")
  .setPosition(140,490)
  .setSize(70,70)
  .setTriggerEvent(Bang.RELEASE)
  .setColorForeground(black)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(white)
  .setFont(font12)
  .setText("GO HOME")
  ;
  //BLAST OFF button
  cP5.addBang("blastOff")
  .setPosition(347,375)
  .setSize(120,105)
  .setTriggerEvent(Bang.RELEASE)
  .setColorForeground(black)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(white)
  .setFont(font14)
  .setText("BLAST OFF")
  ;
  //BLAST ON button
  cP5.addBang("blastOn")
  .setPosition(470,375)
  .setSize(120,105)
  .setTriggerEvent(Bang.RELEASE)
  .setColorForeground(black)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(white)
  .setFont(font14)
  .setText("BLAST ON")
  ;
  //AIR OFF button
  cP5.addBang("airOff")
  .setPosition(347,500)
  .setSize(120,50)
  .setTriggerEvent(Bang.RELEASE)
  .setColorForeground(black)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(white)
  .setFont(font14)
  .setText("AIR OFF")
  ;
  //AIR ON button
  cP5.addBang("airOn")
  .setPosition(470,500)
  .setSize(120,50)
  .setTriggerEvent(Bang.RELEASE)
  .setColorForeground(black)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(white)
  .setFont(font14)
  .setText("AIR ON")
  ;
  
  //SET ORIGIN button
  cP5.addBang("origin")
  .setPosition(347,625)
  .setSize(245,50)
  .setTriggerEvent(Bang.RELEASE)
  .setColorForeground(black)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(white)
  .setFont(font14)
  .setText("SET ORIGIN (0,0)")
  ;
  
  //MANUAL ENTRY field
  cP5.addTextfield("cmdEntry")
  .setPosition( 15, 715 )
  .setSize( 560, 50 )
  .setFont( font24 )
  .setFocus( true )
  .setColor( black )
  .setAutoClear( true )
  //caption settings
  .getCaptionLabel()
  .setColor(white)
  .setFont(font14)
  .alignX(ControlP5.LEFT)
  .setText("MANUAL GCODE ENTRY")
  ;
  
  //SETUP FILE SELECTION CONTROLS
  //---------------------------
  //LOAD FILE button
  cP5.addBang("load")
  .setPosition(615,375)
  .setSize(160,50)
  .setTriggerEvent(Bang.RELEASE)
  .setColorForeground(black)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(white)
  .setFont(font12)
  .setText("LOAD FILE")
  ;
  //PROCESS FILE button
  cP5.addBang("process")
  .setPosition(615,430)
  .setSize(160,50)
  .setTriggerEvent(Bang.RELEASE)
  .setColorForeground(black)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(white)
  .setFont(font12)
  .setText("PROCESS FILE")
  ;
  
  //MOVE SPEED field
  cP5.addTextfield("moveSpeed")
  .setPosition( 850, 540 )
  .setSize( 250, 50 )
  .setFont( font24 )
  .setFocus( true )
  .setColor( black )
  .setAutoClear( false )
  //caption settings
  .getCaptionLabel()
  .setColor(black)
  .setFont(font14)
  .alignX(ControlP5.LEFT)
  .setText("MOVE SPEED (mm/s)")
  ;
  //MOVE BLAST toggle
  cP5.addToggle("moveBlast")
  .setPosition(1110, 540)
  .setSize(50,50)
  .setColorForeground(blue)
  .setColorBackground(grey)
  .setColorActive(black)
  //caption settings
  .getCaptionLabel()
  .alignX(ControlP5.LEFT)
  .setColor(black)
  .setFont(font14)
  .setText("BLAST")
  ;
  //DWELL TIME field
  cP5.addTextfield("dwellTime")
  .setPosition( 850, 650 )
  .setSize( 250, 50 )
  .setFont( font24 )
  .setFocus( true )
  .setColor( black )
  .setAutoClear( false )
  //caption settings
  .getCaptionLabel()
  .setColor(black)
  .setFont(font14)
  .alignX(ControlP5.LEFT)
  .setText("DWELL TIME (s)")
  ;
  //DWELL BLAST toggle
  cP5.addToggle("dwellBlast")
  .setPosition(1110, 650)
  .setSize(50,50)
  .setColorForeground(blue)
  .setColorBackground(grey)
  .setColorActive(black)
  //caption settings
  .getCaptionLabel()
  .alignX(ControlP5.LEFT)
  .setColor(black)
  .setFont(font14)
  .setText("BLAST")
  ;
  //UPDATE SETTINGS button
  cP5.addBang("update")
  .setPosition(850,740)
  .setSize(250,50)
  .setTriggerEvent(Bang.RELEASE)
  .setColorForeground(black)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(white)
  .setFont(font14)
  .setText("UPDATE SETTINGS")
  ;
}

public void generateColors(){
  colors = new IntList();
  
  PVector colorPos = new PVector(615,540);
  
  JSONArray cList = colorSettings.getJSONArray("colorList");
  
  int buttonSize, buttonSpacing, rowLength;
  if(cList.size() < 12){
    buttonSize = 50;
    buttonSpacing = 55;
    rowLength = 3;
  } else{
    buttonSize = 36;
    buttonSpacing = 41;
    rowLength = 4;
  }
  
  for(int i = 0; i < cList.size(); i++){
    int c_index = cList.getInt(i);
    colors.append( c_index );
    JSONArray c_ = colorSettings.getJSONObject("colors").getJSONObject(str( c_index )).getJSONArray("display_color");
    int c = color(c_.getInt(0), c_.getInt(1), c_.getInt(2));
    String label = "color_" + str(c_index);
    
    
    
    
    cP5.addBang(label)
    .setPosition(colorPos.x + buttonSpacing*(i%rowLength), colorPos.y + buttonSpacing*floor(i/rowLength))
    .setSize(buttonSize,buttonSize)
    .setTriggerEvent(Bang.RELEASE)
    .setColorForeground(c)
    .getCaptionLabel()
    .setText("")
    ;
  }
}

public void clearColors(){
  if( colors == null ) return;
  
  for(int i = colors.size()-1; i>=0; i--){
    cP5.remove( "color_"+colors.get(i) );
  }
}
    
//------------------------------------------------------------------------------
// FORMATTING FUNCTIONS
//------------------------------------------------------------------------------
// Functions for formatting and parsing values

// FLOAT FORMAT
//----------------------------------------
// Returns a given float with a specified
// number of decimal places
public float floatFormat( float f, int digits ){
  return round(f * pow(10,digits)) / pow(10, digits);
}

// FLOAT FORMAT (FROM STRING)
//----------------------------------------
// Returns a given string as a float with
// a specified number of decimal places
public float floatFormatS( String s, int digits ){
  return round( PApplet.parseFloat(s) * pow(10,digits)) / pow(10, digits);
}

// PARSE NUMBER FROM STRING
//----------------------------------------
// Searches a string for an identifier code
// and returns associated value as a float
public float parseNumber(String s, String C, float f) {
  int index = s.indexOf(C);

  if ( index == -1 ) {
    return f;
  }

  int endIndex = s.indexOf(" ", index);

  if ( endIndex == -1 ) {
    endIndex = s.length();
  }  

  String val = s.substring( index+1, endIndex );

  return PApplet.parseFloat(val);
}

// PARSE STRING FROM STRING
//----------------------------------------
// Searches a string for an identifier code
// and returns associated value as a string
public String parseString( String s, String C, String d) {
  int index = s.indexOf(C);

  if ( index == -1 ) {
    return d;
  }

  int endIndex = s.indexOf(" ", index);

  if ( endIndex == -1 ) {
    endIndex = s.length();
  }  

  String val = s.substring( index+1, endIndex );

  return val;
}
//------------------------------------------------------------------------------
// MACHINE FUNCTIONS
//------------------------------------------------------------------------------
// Functions for emulating or interfacing with robot

// DETERMINE FEEDRATE
//----------------------------------------
// Calculate actual feedrate from given command
// based on known machine limits (from firmware)
public float determineFeedrate( float dx, float dy, float f ) {
  //speed limits hard-coded into machine firmware
  float max_x_vel = 300.0f;
  float max_y_vel = 80.0f;
  
  float vec = sqrt( dx*dx + dy*dy );
  float vx = min( max_x_vel, f * dx / vec );
  float vy = min( max_y_vel, f * dy / vec );
  
  return sqrt( vx*vx + vy*vy);
}

//ATAN3
//----------------------------------------
// Return angle from a given dx/dy
public float atan3( float dy, float dx ){
  float a = atan2(dy,dx);
  if( a < 0 ) a += TWO_PI;
  return a;
}

// CALCULATE MOVE TIME
//----------------------------------------
// Calculate time it would take to move to
// a given point at a given speed
public float calcLineTime(PVector newPt, PVector lastPt, float f_){
  float duration;
  
  float dx = newPt.x - lastPt.x;
  float dy = newPt.y - lastPt.y;
  float l = sqrt(dx*dx + dy*dy);
  
  if( l == 0 ){
    duration = 0.0f;
    //println("TOO SHORT");
  } else{
    f_ = min(f_, determineFeedrate( dx, dy, f_ ) );
    duration = l / f_;
    //println("l/f: " + l + "/" + f_);
  }
  return duration;
}
//------------------------------------------------------------------------------
// SERIAL FUNCTIONS
//------------------------------------------------------------------------------
// Functions for communicating over the serial port

// MONITOR CONNECTIONS
//----------------------------------------
// Checks connection status
public void monitorConnection(){
  if(!connected) serialConnect();
  else serialRun();
}

// SERIAL CONNECT
//----------------------------------------
// Searches through available serial ports
// and connects if one is available
public void serialConnect() {
  String[] ports = Serial.list();

  if ( ports.length > 0 ) {
    port = ports[0];
    myPort = new Serial(this, port, 115200);
    connected = true;
  } else {
    connected = false;
  }
}


// SERIAL RUN
//----------------------------------------
// Issues commands to serial port if port is
// available and if there is data to send
public void serialRun() {

  if (myPort.available() > 0) {
    val = myPort.readString();

    //Arduino firmware signals readiness with a ">"
    if (val.equals("\n> ") ) {

      lastSent="";

      //Check if paused
      if (!paused) {
        if ( interrupt.size() > 0 ) {
          String s = interrupt.sendNext();
          myPort.write(s);
          println("sent: " + s);
          lastSent = s;
        }
        //check if commands are available
        else if (running && GB.size() > 0 ) {
          String s = GB.sendNext();
          myPort.write(s);
          //Echo command to debug panel
          println("sent: " + s);
          lastSent = s;
        } else {
          //currentPath = "";
          timeLeft = "";
          lineNum = "";
          running = false;
        }
      } else {
        //check if interrupt commands are available
        if ( interrupt.size() > 0 ) {
          String s = interrupt.sendNext();
          myPort.write(s);
          lastSent = s;
        }
      }
    } else {
      println( "recieved: " + val );

      if (val.length() > 0 && val != " ") {
        String[] temp = split(val, "\n");
        lastVal.clear();
        for (int i = 0; i < temp.length; i++) {
          if (temp[i].length() > 1) {
            lastVal.append(temp[i]);
          }
        }
      }
    }
  }
}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "DXF_app_DXF" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
