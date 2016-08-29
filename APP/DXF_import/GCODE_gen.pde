// - - - - - - - - - - - - - - - - - - - - - - - - - -
// GCODE GENERATING FUNCTIONS
// - - - - - - - - - - - - - - - - - - - - - - - - - -
  
  
// GENERATE GCODE
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Convert JSON of geometry to GCODE commands
//
void genGCODE( JSONObject json ){
  StringList GCODE = new StringList();
  
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
        GCODE.append( code.get(k) );
      }
    }
  }
  
  //save GCODE to text file
  saveStrings("gcode.txt", GCODE.array() );
}

// GENERATE POINT
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Convert JSON point to G04 or G05 Command
//
StringList genPoint( JSONObject pt ){  
  StringList code = new StringList();
  Float feed = 50.0;
  
  JSONArray pos = pt.getJSONArray("endPts").getJSONArray(0);
  if( pt.getInt("connectLine") == 1 ){
    code.append( "G00 X"+floatFormat(pos.getFloat(0),3) + " Y"+floatFormat(pos.getFloat(1),3) + " F" + floatFormat(feed,3) );
  }
  if( pt.getInt("color") == 7 ){
    code.append( "G04 P5000.0" );
  } else {
    code.append( "G05 P3000.0" );
  }
  return code;
}

// GENERATE LINE
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Convert JSON line to G00 or G01 Command
//
StringList genLine( JSONObject ln ){
  StringList code = new StringList();
  
  int dir = ln.getInt("dir");
  int type;
  Float feed;
  
  switch( ln.getInt("color") ){
    case 7:
      type = 0;
      feed = 50.0;
      break;
    case 1:
      type = 1;
      feed = 10.0;
      break;
    case 2:
      type = 1;
      feed = 25.0;
      break;
    default:
      type = 0;
      feed = 50.0;
      break;
  }
  
  JSONArray p1 = ln.getJSONArray( "endPts" ).getJSONArray( dir );
  JSONArray p2 = ln.getJSONArray( "endPts" ).getJSONArray( abs(1-dir) );
  
  if( ln.getInt("connectLine") == 1){
    code.append( "G0"+type + " X"+floatFormat(p1.getFloat(0),3) + " Y"+floatFormat(p1.getFloat(1),3) + " F"+floatFormat(feed,2) );
  }
  
  code.append( "G0"+type + " X"+floatFormat(p2.getFloat(0),3) + " Y"+floatFormat(p2.getFloat(1),3) + " F"+floatFormat(feed,2) );
  
  return code;

}

// GENERATE ARC
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Convert JSON arc to G02 or G03 Command
//
StringList genArc( JSONObject arc ){
  StringList code = new StringList();
  
  int dir = arc.getInt("dir");
  int type;
  Float feed;
  
  switch( arc.getInt("color") ){
    case 7:
      feed = 50.0;
      break;
    case 1:
      feed = 10.0;
      break;
    case 2:
      feed = 25.0;
      break;
    default:
      feed = 50.0;
      break;
  }
  
  JSONArray cp = arc.getJSONArray("centerPt");
  JSONArray p1 = arc.getJSONArray( "endPts" ).getJSONArray( dir );
  JSONArray p2 = arc.getJSONArray( "endPts" ).getJSONArray( abs(1-dir) );
  
  if( dir == 0 ){
    type = 3;
  } else {
    type = 2;
  }
  
  if( arc.getInt("connectLine") == 1){
    code.append( "G0"+type + " X"+floatFormat(p1.getFloat(0),3) + " Y"+floatFormat(p1.getFloat(1),3) + " F"+floatFormat(feed,2) );
  }
  
  code.append( "G0"+type + " I"+floatFormat(cp.getFloat(0),3) + " J"+floatFormat(cp.getFloat(1),3) + " X"+floatFormat(p2.getFloat(0),3) + " Y"+floatFormat(p2.getFloat(1),3) + " F"+floatFormat(feed,3) );
  
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
  int type;
  Float feed;
  
  switch( pl.getInt("color") ){
    case 7:
      feed = 50.0;
      type = 0;
      break;
    case 1:
      feed = 10.0;
      type = 1;
      break;
    case 2:
      feed = 25.0;
      type = 1;
      break;
    default:
      feed = 50.0;
      type = 0;
      break;
  }
  
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
    code.append( "G0"+type + " X"+floatFormat(pts.get(0).x,3) + " Y"+floatFormat(pts.get(0).y,3) + " F"+floatFormat(feed,2) );
  }
  
  for( int i = 1; i < pts.size(); i++ ){
    code.append( "G0"+type + " X"+floatFormat(pts.get(i).x,3) + " Y"+floatFormat(pts.get(i).y,3) + " F"+floatFormat(feed,3) );
  }
  
  return code;
}