String fp;
String acdColor = "acd_2_hex.json";

String[] dxf;
String[] entity;
String[][] ent;

Boolean VERBOSE = false;

JSONObject json;
JSONObject colorSettings;
JSONObject colorACD;
boolean loaded = false;
int counter;

float padding = 100.0;

void setup(){
  size(1200,400);
  frameRate(10);
  
  //load DXF file line-by-line
  selectInput("Select DXF file to process:", "fileSelected"); 
  
  //load ACD color conversion table
  colorACD = loadJSONObject( acdColor );
  
  counter = 0;
}

void draw(){

  
  background(220);
  stroke(200);
  strokeWeight(1);
  for(int x = 100; x<=width-100; x+=10){
    line(x,0,x,height);
  }
  for(int y = 100; y<=height-100; y+=10){
    line(0,y,width,y);
  }
  noStroke();
  fill(20);
  rect(0,0,100,height);
  rect(0,0,width,100);
  rect(0,height-100,width,height);
  rect(width-100,0,width,height);
  noFill();
  
  
  if( !loaded && fp != null ){
    loadData( fp );
  } else if (loaded) {
    strokeWeight(5);
    displayGeo(json, counter);
    counter++;
  }
}

void mousePressed(){
  exit();
}

void fileSelected( File selection ){
  if( selection == null ){
    fp = "DXFs/test_loops_04.dxf";
  } else {
    fp = selection.getPath();
  }
}

void loadData( String filepath ){
  dxf = loadStrings( fp );
  
  //instantiate JSON object
  json = new JSONObject();
  colorSettings = new JSONObject();
  
  //extract geometry from DXF and load into JSON
  parseGeo( json, colorSettings, dxf );
  
  saveJSONObject( json, "data/geo.json" );
  saveJSONObject( colorSettings, "data/settings.json");
  
  genGCODE( json );
  
  loaded = true;
}
  
  