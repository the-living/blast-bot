void displayGeo( JSONObject json, int step ){
  
  step = min( step, json.getInt("entityCount") );
    
  JSONArray layerList = json.getJSONArray("layerList");
  JSONObject layers = json.getJSONObject("layers");
  JSONArray objs = new JSONArray();
  
  for(int l = 0; l < layerList.size(); l++){
    if( objs.size() >= step ) break;
    JSONObject layer = layers.getJSONObject( str( layerList.getInt( l ) ) );
    int entCount = layer.getInt("geoCount");
    for( int e = 1; e <= entCount; e++ ){
      if( objs.size() >= step ) break;
      
      objs.append( layer.getJSONObject( str(e) ) );
    }
  }
  
  for( int i = 0; i < objs.size(); i++ ){
    JSONObject geo = objs.getJSONObject(i);
      switch( geo.getString("type") ){
        case "POINT":
          renderPoint( geo );
          break;
        case "LINE":
          renderLine( geo );
          break;
        case "ARC":
          renderArc( geo );
          break;
        case "POLYLINE":
          renderPolyline( geo );
          break;
        default:
          break;
        
      }
    }
  //do something
}

void renderPoint( JSONObject pt ){
  JSONArray loc = pt.getJSONArray("endPts").getJSONArray(0);
  float x = loc.getFloat(0) + padding;
  float y = loc.getFloat(1) + padding;
  
  int colorIndex = pt.getInt("color");
  JSONArray c_ = colorSettings.getJSONObject("colors").getJSONObject(str(colorIndex)).getJSONArray("display_color");
  color c = color(c_.getInt(0),c_.getInt(1),c_.getInt(2));
  
  stroke(c);
  point(x,height-y);
  
}

void renderLine( JSONObject ln ){
  JSONArray p1 = ln.getJSONArray("endPts").getJSONArray(0);
  JSONArray p2 = ln.getJSONArray("endPts").getJSONArray(1);
  float x1 = p1.getFloat(0) + padding;
  float y1 = p1.getFloat(1) + padding;
  float x2 = p2.getFloat(0) + padding;
  float y2 = p2.getFloat(1) + padding;
  
  int colorIndex = ln.getInt("color");
  JSONArray c_ = colorSettings.getJSONObject("colors").getJSONObject(str(colorIndex)).getJSONArray("display_color");
  color c = color(c_.getInt(0),c_.getInt(1),c_.getInt(2));
  
  stroke( c );
  line(x1,height-y1, x2, height-y2); 
}

void renderArc( JSONObject arc ){
  JSONArray cp = arc.getJSONArray("centerPt");
  float cx = cp.getFloat(0) + padding;
  float cy = cp.getFloat(1) + padding;
  float r = arc.getFloat("radius")*2;
  float SA = 360-arc.getFloat("startAngle");
  float EA = 360-arc.getFloat("endAngle");
  
  if( EA > SA ){
    SA += 360;
  }
  
  int colorIndex = arc.getInt("color");
  JSONArray c_ = colorSettings.getJSONObject("colors").getJSONObject(str(colorIndex)).getJSONArray("display_color");
  color c = color(c_.getInt(0),c_.getInt(1),c_.getInt(2));
  
  stroke( c );
  arc( cx, height-cy, r, r, radians(EA), radians(SA) );
}

void renderPolyline( JSONObject pl ){
  JSONArray pts = pl.getJSONArray("endPts");
  
  int colorIndex = pl.getInt("color");
  JSONArray c_ = colorSettings.getJSONObject("colors").getJSONObject(str(colorIndex)).getJSONArray("display_color");
  color c = color(c_.getInt(0),c_.getInt(1),c_.getInt(2));
  
  for( int i = 0; i < pts.size()-1; i++){
    JSONArray p1 = pts.getJSONArray(i);
    JSONArray p2 = pts.getJSONArray(i+1);
    
    float x1 = p1.getFloat(0) + padding;
    float y1 = p1.getFloat(1) + padding;
    float x2 = p2.getFloat(0) + padding;
    float y2 = p2.getFloat(1) + padding;
    
    stroke( c );
    line(x1,height-y1,x2,height-y2);
  }
}
    
    