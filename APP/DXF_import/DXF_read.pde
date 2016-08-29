// - - - - - - - - - - - - - - - - - - - - - - - - - -
// DXF PARSING FUNCTIONS
// - - - - - - - - - - - - - - - - - - - - - - - - - -


// CUT SECTION
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Returns a subset of strings bounded by indicated
// start and end index
//
String[] cutSection( String[] dxfs, String startcut, String endcut ) {

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

  //ignore dataset before desired starting point
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

  //return results
  return subset( dxfs, 0, cutF-1 );
}

// PARSE GEOMETRY
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Extracts geometry objects from section of DXF text
// and saves them to JSON organized by layer
//
void parseGeo( JSONObject json, JSONObject settings, String[] dxf ) {

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

// PARSE VERTEX
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Extracts vertices from DXF data
//
JSONArray parseVertex( String[] ent) {
  JSONArray vert = new JSONArray();

  for ( int i = 0; i < ent.length-1; i++ ) {
    String val = ent[i+1].trim();
    switch( int(ent[i].trim()) ) {
    case 10:
      vert.setFloat(0, float(val));
      i++;
      break;
    case 20:
      vert.setFloat(1, float(val));
      i++;
      break;
    default:
      break;
    }
  }
  return vert;
}

// PARSE POLYLINE
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Extracts polyline attributes & vertices from DXF data
//
JSONObject parsePolyline( String[] ent) {
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

    switch( int( ent[i].trim() ) ) {
    case 8:
      layer = int( val );
      i++;
      break;
    case 62:
      geoColor = int( val );
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


// PARSE ARC
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Extracts arc attributes from DXF data
//
JSONObject parseArc( String[] ent ) {
  //create JSON object for return
  JSONObject geo = new JSONObject();
  //initialize geometry parameters
  String type = ent[1];
  JSONArray centerPt = new JSONArray();
  JSONArray endPts = new JSONArray();
  JSONArray p1 = new JSONArray();
  JSONArray p2 = new JSONArray();
  float radius = 0.0;
  float startAngle = 0.0;
  float endAngle = 0.0;
  int dir = 0;
  int layer = 0;
  int geoColor = 1;

  //loop through entity and extract parameters
  for ( int i = 0; i < ent.length-1; i++) {

    String val = ent[i+1].trim();

    switch( int( ent[i].trim() ) ) {
    case 8:
      layer = int( val );
      i++;
      break;
    case 62:
      geoColor = int( val );
      i++;
      break;
    case 10:
      centerPt.setFloat(0, float(val) );
      i++;
      break;
    case 20:
      centerPt.setFloat(1, float(val) );
      i++;
      break;
    case 40:
      radius = float( val );
      i++;
      break;
    case 50:
      startAngle = float( val );
      i++;
      break;
    case 51:
      endAngle = float( val );
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

// PARSE LINE
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Extracts line attributes from DXF data
//
JSONObject parseLine( String[] ent ) {
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

    switch( int( ent[i].trim() ) ) {
    case 8:
      layer = int( val );
      i++;
      break;
    case 62:
      geoColor = int( val );
      i++;
      break;
    case 10:
      p1.setFloat(0, float(val) );
      i++;
      break;
    case 11:
      p2.setFloat(0, float(val) );
      i++;
      break;
    case 20:
      p1.setFloat(1, float(val) );
      i++;
      break;
    case 21:
      p2.setFloat(1, float(val) );
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

// PARSE POINT
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Extracts point attributes from DXF data
//
JSONObject parsePoint( String[] ent ) {
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

    switch( int( ent[i].trim() ) ) {
    case 8:
      layer = int( ent[i+1] );
      i++;
      break;
    case 62:
      geoColor = int( val );
      i++;
      break;
    case 10:
      pt1.setFloat(0, float(val) );
      i++;
      break;
    case 20:
      pt1.setFloat(1, float(val) );
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

// SORT GEOMETRY
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Extracts geometry objects from JSON entities
// and organizes in layers by shortest path sequence
//

void sortGeo( JSONObject j ) { 

  JSONArray lastPt = new JSONArray();
  lastPt.setFloat(0, 0.0);
  lastPt.setFloat(1, 0.0);

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



FloatList checkDistances( JSONArray pt, JSONArray objs ) {
  FloatList dists = new FloatList();
  StringList types = new StringList();

  for (int i = 0; i < objs.size(); i++) {
    JSONObject obj = objs.getJSONObject(i);
    JSONArray pts = obj.getJSONArray("endPts");

    float d = getDist( pt, pts.getJSONArray(0) );

    if ( obj.getString("type").contains("POINT") && d < 0.001 ) {
      d = -10.0;
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

void colorInit( JSONObject j, JSONArray jList ){
  
  for(int i = 0; i < jList.size(); i++){
    String c = str( jList.getInt(i) );
    //println("c: " + c);
    JSONArray dispColor;
    Float moveFeed = 50.0;
    boolean moveBlast = false;
    Float dwellTime = 1000.0;
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

Float getDist( JSONArray p1, JSONArray p2 ) {
  return sqrt( pow(p1.getFloat(0)-p2.getFloat(0), 2) + pow(p1.getFloat(1)-p2.getFloat(1), 2) );
}