void displayGeo( JSONObject json, int step ) {

  step = min( step, json.getInt("entityCount") );

  JSONArray layerList = json.getJSONArray("layerList");
  JSONObject layers = json.getJSONObject("layers");
  JSONArray objs = new JSONArray();

  for (int l = 0; l < layerList.size(); l++) {
    if ( objs.size() >= step ) break;
    JSONObject layer = layers.getJSONObject( str( layerList.getInt( l ) ) );
    int entCount = layer.getInt("geoCount");
    for ( int e = 1; e <= entCount; e++ ) {
      if ( objs.size() >= step ) break;

      objs.append( layer.getJSONObject( str(e) ) );
    }
  }

  for ( int i = 0; i < objs.size(); i++ ) {
    JSONObject geo = objs.getJSONObject(i);
    
    int colorIndex = geo.getInt("color");
    JSONArray c_ = colorSettings.getJSONObject("colors").getJSONObject(str(colorIndex)).getJSONArray("display_color");
    color c = color(c_.getInt(0), c_.getInt(1), c_.getInt(2));
    
    switch( geo.getString("type") ) {
    case "POINT":
      renderPoint( geo, c );
      break;
    case "LINE":
      renderLine( geo, c );
      break;
    case "ARC":
      renderArc( geo, c );
      break;
    case "POLYLINE":
      renderPolyline( geo, c );
      break;
    default:
      break;
    }
  }
}

void displayGCODE( StringList code, int step ) {

  step = min( step, code.size() );
  
  PVector lastPt = new PVector(0,0);

  StringList objs = new StringList();

  for (int i = 0; i < code.size(); i++) {
    if ( objs.size() >= step ) break;
    
    objs.append( code.get(i) );
  }

  for ( int i = 0; i < objs.size(); i++ ) {
    String line = objs.get(i);
    
    if(VERBOSE) println(line);
    
    Float feed = parseNumber( line, "F", -1 );
    int type = int( parseNumber( line, "G", -1 ) );
    color c;
    
    if( type == 0 || type == 4 ){
      c = color(255,255,0);
    } else {
      c = color(255,0,0);
    }
    
    switch( type ) {
    case 0:
    case 1:
      renderGcodeLine( line, c, lastPt );
      break;
    case 2:
    case 3:
      renderGcodeArc( line, c, lastPt );
      break;
    case 4:
    case 5:
      renderGcodePoint( line, c, lastPt );
      break;
    default:
      break;
    }
  }
  
  stroke(255);
  strokeWeight(1);
  ellipseMode(CENTER);
  ellipse(lastPt.x+padding,height-(lastPt.y+padding),20,20);
}


void renderPoint( JSONObject pt, color c ) {
  JSONArray loc = pt.getJSONArray("endPts").getJSONArray(0);
  float x = loc.getFloat(0) + padding;
  float y = loc.getFloat(1) + padding;

  stroke(c);
  point(x, height-y);
}

void renderLine( JSONObject ln, color c ) {
  JSONArray p1 = ln.getJSONArray("endPts").getJSONArray(0);
  JSONArray p2 = ln.getJSONArray("endPts").getJSONArray(1);
  float x1 = p1.getFloat(0) + padding;
  float y1 = p1.getFloat(1) + padding;
  float x2 = p2.getFloat(0) + padding;
  float y2 = p2.getFloat(1) + padding;

  stroke( c );
  line(x1, height-y1, x2, height-y2);
}

void renderArc( JSONObject arc, color c ) {
  JSONArray cp = arc.getJSONArray("centerPt");
  float cx = cp.getFloat(0) + padding;
  float cy = cp.getFloat(1) + padding;
  float r = arc.getFloat("radius")*2;
  float SA = 360-arc.getFloat("startAngle");
  float EA = 360-arc.getFloat("endAngle");

  if ( EA > SA ) {
    SA += 360;
  }

  stroke( c );
  arc( cx, height-cy, r, r, radians(EA), radians(SA) );
}

void renderPolyline( JSONObject pl, color c ) {
  JSONArray pts = pl.getJSONArray("endPts");

  for ( int i = 0; i < pts.size()-1; i++) {
    JSONArray p1 = pts.getJSONArray(i);
    JSONArray p2 = pts.getJSONArray(i+1);

    float x1 = p1.getFloat(0) + padding;
    float y1 = p1.getFloat(1) + padding;
    float x2 = p2.getFloat(0) + padding;
    float y2 = p2.getFloat(1) + padding;

    stroke( c );
    line(x1, height-y1, x2, height-y2);
  }
}

void renderGcodePoint( String code, color c, PVector lastPt ){
  
  stroke( c );
  point( lastPt.x+padding, height-lastPt.y+padding );
  
}

void renderGcodeLine( String code, color c, PVector lastPt ){
  float x1 = lastPt.x + padding;
  float y1 = lastPt.y + padding;
  
  float x2 = parseNumber(code, "X", lastPt.x) + padding;
  float y2 = parseNumber(code, "Y", lastPt.y) + padding;
  
  stroke(c);
  line(x1,height-y1,x2,height-y2);
  
  lastPt.x = x2 - padding;
  lastPt.y = y2 - padding;
}

void renderGcodeArc( String code, color c, PVector lastPt ){
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
  
  stroke(c);
  if( dir == 2){
    arc( cx+padding, height - (cy+padding), r*2, r*2, EA, SA );
  } else {
    arc( cx+padding, height - (cy+padding), r*2, r*2, SA, EA );
  }
  
  lastPt.x = x;
  lastPt.y = y;
}