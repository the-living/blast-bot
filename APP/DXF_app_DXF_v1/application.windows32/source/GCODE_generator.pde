//------------------------------------------------------------------------------
// GCODE Generator
//------------------------------------------------------------------------------
// Functions for converting JSON formatted geo to
// GCODE commands


// GENERATE GCODE
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Convert JSON of geometry to GCODE commands
//
void genGCODE( JSONObject json, GCODEbuffer GCODE ){
  
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
StringList genPoint( JSONObject pt ){  
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
StringList genLine( JSONObject ln ){
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
StringList genArc( JSONObject arc ){
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
StringList genPolyline( JSONObject pl ){
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