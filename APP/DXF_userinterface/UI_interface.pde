//------------------------------------------------------------------------------
// UX Interface
//------------------------------------------------------------------------------
// Functions for generating US


//DISPLAY UI
//----------------------------------------
//Draws user non-cP5 interface elements
void displayUI() {
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
void renderNozzle(){
  stroke(white);
  fill(white,50);
  strokeWeight(3);
  ellipse(origin.x+(posx*scalar), origin.y-(posy*scalar),10,10);
  noFill();
  strokeWeight(0.5);
  ellipse(origin.x+(posx*scalar), origin.y-(posy*scalar),20,20);
}

//DISPLAY STATS
//----------------------------------------
//Draws dynamic text elements elements
void displayStats(){
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
  float x_ = 40.0 + textWidth(status);
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
    for(int i = 0; i < colors.size(); i++){
      if( selectedColor == colors.get(i) ){
        stroke(blue);
        strokeWeight(2);
      } else {
        stroke(black);
        strokeWeight(1);
      }
      rect(colorPos.x + 55*(i%3), colorPos.y + 55*floor(i/3), 51, 51);
    }
  }
  
}

void initFonts() {
  font24 = loadFont("Roboto-Regular-24.vlw");
  font18 = loadFont("Roboto-Regular-18.vlw");
  font16i = loadFont("Roboto-Italic-16.vlw");
  font14 = loadFont("Roboto-Regular-14.vlw");
  font12 = loadFont("Roboto-Regular-12.vlw");
}

void initColors() {
  black = color(0);
  white = color(255);
  grey = color(220);
  charcoal = color(200);
  red = color(237, 28, 36);
  green = color(57, 181, 74);
  blue = color(80, 150, 225);
}

void setupControls() {
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
  //RESET button
  cP5.addBang("reset")
  .setPosition(1045,260)
  .setSize(140, 40)
  .setTriggerEvent(Bang.RELEASE)
  .setColorForeground(white)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(black)
  .setFont(font18)
  .setText("RESET")
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
  
  //OVERIDE button
  cP5.addToggle("override")
  .setPosition(347,570)
  .setSize(245,50)
  .setColorForeground(white)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(black)
  .setFont(font14)
  .setText("OVERRIDE OFF")
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

void generateColors(){
  colors = new IntList();
  
  PVector colorPos = new PVector(615,540);
  
  JSONArray cList = colorSettings.getJSONArray("colorList");
  for(int i = 0; i < cList.size(); i++){
    int c_index = cList.getInt(i);
    colors.append( c_index );
    JSONArray c_ = colorSettings.getJSONObject("colors").getJSONObject(str( c_index )).getJSONArray("display_color");
    color c = color(c_.getInt(0), c_.getInt(1), c_.getInt(2));
    String label = "color_" + str(c_index);

    cP5.addBang(label)
    .setPosition(colorPos.x + 55*(i%3), colorPos.y + 55*floor(i/3))
    .setSize(50,50)
    .setTriggerEvent(Bang.RELEASE)
    .setColorForeground(c)
    .getCaptionLabel()
    .setText("")
    ;
  }
}

void clearColors(){
  if( colors == null ) return;
  
  for(int i = colors.size()-1; i>=0; i--){
    cP5.remove( "color_"+colors.get(i) );
  }
}
    