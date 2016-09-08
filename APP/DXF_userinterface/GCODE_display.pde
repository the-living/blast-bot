//------------------------------------------------------------------------------
// JSON/GCODE Display
//------------------------------------------------------------------------------
// Functions for rendering JSON and GCODE geo to screen

// RENDER JSON GEO
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Render geometry from JSON file to preview window
void renderJSONgeo( JSONObject json ) {
  
  preview = new PShape();

  JSONArray layerList = json.getJSONArray("layerList");
  JSONObject layers = json.getJSONObject("layers");

  for (int l = 0; l < layerList.size(); l++) {
    JSONObject layer = layers.getJSONObject( str( layerList.getInt( l ) ) );
    for ( int e = 1; e <= layer.getInt("geoCount"); e++ ) {
      JSONObject geo = layer.getJSONObject( str(e) );
      
      int colorIndex = geo.getInt("color");
      JSONArray c_ = colorSettings.getJSONObject("colors").getJSONObject(str(colorIndex)).getJSONArray("display_color");
      color c = color(c_.getInt(0), c_.getInt(1), c_.getInt(2));
      
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
void renderGCODE( GCODEbuffer code, int step ) {

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
    
    int type = int( parseNumber( line, "G", -1 ) );
    color c;
    
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
void addPoint(JSONObject pt, color c ) {
  PShape p;
  
  JSONArray loc = pt.getJSONArray("endPts").getJSONArray(0);
  float x = loc.getFloat(0);
  float y = loc.getFloat(1);
  
  strokeWeight(4);
  stroke(c);
  noFill();
  p = createShape(POINT, origin.x+x*scalar, origin.y-y*scalar);

  preview.addChild( p );
}

// ADD LINE TO PREVIEW
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Add Line PSHAPE object to Preview PSHAPE
void addLine( JSONObject ln, color c ) {
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
void addArc( JSONObject arc, color c ) {
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
void addPolyline( JSONObject pl, color c ) {
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
void renderGcodePoint( String code, PVector lastPt ){
  strokeWeight(6);
  point( origin.x+lastPt.x*scalar, origin.y-lastPt.y*scalar );
}

// RENDER GCODE LINE
// - - - - - - - - - - - - - - - - - - - - - - - - - -
// Render line from G00 or G01 command
void renderGcodeLine( String code, PVector lastPt ){
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
void renderGcodeArc( String code, PVector lastPt ){
  int dir = int( parseNumber(code, "G", -1) );
  
  float cx = parseNumber(code, "I", 0.0);
  float cy = parseNumber(code, "J", 0.0);
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