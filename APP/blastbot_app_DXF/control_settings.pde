//---------------------------------------------------------------------------
//
// ControlP5 UX Objects Setup
//
//---------------------------------------------------------------------------

void setupControls(){

  //INITIALIZE UX
  cP5 = new ControlP5(this);

  //Initialize fonts
  fontL = loadFont("Roboto-28.vlw");
  fontM = loadFont("Roboto-18.vlw");
  fontS = loadFont("Roboto-12.vlw");
  
  //global control panel settings
  cP5.setFont( fontS );
  cP5.setColorForeground( fgColor );
  cP5.setColorBackground( bgColor );
  cP5.setColorValueLabel( bgColor );
  cP5.setColorCaptionLabel( bgColor );
  cP5.setColorActive( activeColor );

  //MANUAL COMMAND ENTRY
  //---------------------------------------------------------------------------
  //Issues typed out GCODE command
  cP5.addTextfield("cmd_entry")
  .setPosition( 25, 420 )
  .setSize( 550, 50 )
  .setFont( fontL )
  .setFocus( true )
  .setColor( color(0) )
  .setAutoClear( true )
  //caption settings
  .getCaptionLabel()
  .setColor(255)
  .setFont(fontM)
  .alignX(ControlP5.LEFT)
  .setText("Manual GCODE Entry")
  ;
  
  //FILE CONTROLS
  //FILE CONTROLS
  cP5.addBang("serial")
  .setPosition(480,750)
  .setSize(100, 25)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(0)
  .setFont(fontS)
  .setText("RECONNECT")
  ;
  
    //FILE CONTROLS
  cP5.addBang("clear")
  .setPosition(480,720)
  .setSize(100, 25)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(0)
  .setFont(fontS)
  .setText("CLEAR BUFFER")
  ;
  
  cP5.addBang("pause")
  .setPosition(650, 680)
  .setSize(700, 100)
  .setTriggerEvent(Bang.RELEASE)
  .setColorForeground(pauseColor)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontL)
  .setText("PAUSE")
  ;
  
  //BLAST PASS SETTINGS
  //---------------------------------------------------------------------------
  cP5.addTextfield("board_height")
  .setPosition( 650, 150 )
  .setSize( 340, 50 )
  .setFont( fontL )
  .setFocus( true )
  .setColor( color(0) )
  .setAutoClear( false )
  .setValue( "100.0" )
  //caption settings
  .getCaptionLabel()
  .setColor(0)
  .setFont(fontM)
  .alignX(ControlP5.LEFT)
  .setText("BOARD HEIGHT")
  ;
  
  cP5.addTextfield("board_width")
  .setPosition( 1000, 150 )
  .setSize( 350, 50 )
  .setFont( fontL )
  .setFocus( true )
  .setColor( color(0) )
  .setAutoClear( false )
  .setValue( "100.0" )
  //caption settings
  .getCaptionLabel()
  .setColor(0)
  .setFont(fontM)
  .alignX(ControlP5.LEFT)
  .setText("BOARD WIDTH")
  ;
  
    cP5.addTextfield("blast_spacing")
  .setPosition( 650, 250 )
  .setSize( 340, 50 )
  .setFont( fontL )
  .setFocus( true )
  .setColor( color(0) )
  .setAutoClear( false )
  .setValue( "20.0" )
  //caption settings
  .getCaptionLabel()
  .setColor(0)
  .setFont(fontM)
  .alignX(ControlP5.LEFT)
  .setText("BLAST SPACING")
  ;
  
  cP5.addTextfield("blast_speed")
  .setPosition( 1000, 250 )
  .setSize( 350, 50 )
  .setFont( fontL )
  .setFocus( true )
  .setColor( color(0) )
  .setAutoClear( false )
  .setValue( "25.0" )
  //caption settings
  .getCaptionLabel()
  .setColor(0)
  .setFont(fontM)
  .alignX(ControlP5.LEFT)
  .setText("BLAST SPEED (UNIT/S)")
  ;
  
  //TOGGLE METRIC/IMPERIAL MODE
  cP5.addToggle("metric")
  .setPosition(650, 80)
  .setSize(340, 45)
  .setColorForeground(fgColor)
  .setColorBackground(fgColor)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontM)
  .setText("METRIC (MM)")
  ;
  
  cP5.addBang("run_blasting")
  .setPosition(650,350)
  .setSize(700, 45)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontL)
  .setText("RUN BLASTING")
  ;

  //SPRAYER ENABLE/DISABLE
  //---------------------------------------------------------------------------
  //DISABLE BUTTON
  //Turns off blast
  cP5.addBang("blast_off")
  .setPosition(400, 50)
  .setSize(95, 95)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("BLAST OFF")
  ;

  //ENABLE BUTTON
  //Turns on sprayer
  cP5.addBang("blast_on")
  .setPosition(500, 50)
  .setSize(95, 95)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("BLAST ON")
  ;
  //DISABLE BUTTON
  //Turns off sprayer
  cP5.addBang("air_off")
  .setPosition(400, 150)
  .setSize(95, 50)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("AIR OFF")
  ;

  //ENABLE BUTTON
  //Turns on sprayer
  cP5.addBang("air_on")
  .setPosition(500, 150)
  .setSize(95, 50)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("AIR ON")
  ;

  //TELEPORT
  //---------------------------------------------------------------------------
  
  //TOGGLE OVERRIDE MODE
  cP5.addToggle("override")
  .setPosition(400, 280)
  .setSize(200, 45)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(0)
  .setFont(fontM)
  .setText("OVERRIDE OFF")
  ;
  
  //Send teleport signal
  cP5.addBang("teleport")
  .setPosition(400, 330)
  .setSize(200, 45)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontM)
  .setText("SET ORIGIN (0,0)")
  ;
  

  //AXIAL MOVE COMMANDS
  //---------------------------------------------------------------------------

  //GO HOME
  cP5.addBang("go_home")
  .setPosition(165,165)
  .setSize(70,70)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("GO HOME")
  ;
  
  //X +100 BUTTON
  cP5.addBang("x_100")
  .setPosition(300, 175)
  .setSize(50, 50)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("X +100")
  ;

  //X +10 BUTTON
  cP5.addBang("x_10")
  .setPosition(245, 175)
  .setSize(50, 50)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("X +10")
  ;

  //X -100 BUTTON
  cP5.addBang("x_-100")
  .setPosition(50, 175)
  .setSize(50, 50)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("X -100")
  ;

  //X -10 BUTTON
  cP5.addBang("x_-10")
  .setPosition(105, 175)
  .setSize(50, 50)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("X -10")
  ;

  //Y +100 BUTTON
  cP5.addBang("y_100")
  .setPosition(175, 50)
  .setSize(50, 50)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("Y +100")
  ;

  //Y +10 BUTTON
  cP5.addBang("y_10")
  .setPosition(175, 105)
  .setSize(50, 50)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("Y +10")
  ;

  //Y -100 BUTTON
  cP5.addBang("y_-100")
  .setPosition(175,300)
  .setSize(50, 50)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("Y -100")
  ;

  //Y -10 BUTTON
  cP5.addBang("y_-10")
  .setPosition(175, 245)
  .setSize(50, 50)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontS)
  .setText("Y -10")
  ;
}