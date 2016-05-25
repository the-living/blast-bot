//---------------------------------------------------------------------------
//
// ControlP5 UX Objects Setup
//
//---------------------------------------------------------------------------

void setupControls(){
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
  cP5.addBang("serial")
  .setPosition(500,850)
  .setSize(80, 25)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(0)
  .setFont(fontS)
  .setText("RECONNECT")
  ;
  
  //FILE CONTROLS
  cP5.addBang("refresh")
  .setPosition(650,55)
  .setSize(250, 35)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontM)
  .setText("REFRESH")
  ;
  
  cP5.addBang("pause")
  .setPosition(650, 780)
  .setSize(700, 110)
  .setTriggerEvent(Bang.RELEASE)
  .setColorForeground(pauseColor)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontL)
  .setText("PAUSE")
  ;
  
  cP5.addBang("run_l_clean")
  .setPosition(650,250)
  .setSize(700, 45)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontM)
  .setText("RUN L CLEANING")
  ;
  
  cP5.addBang("run_l_blast")
  .setPosition(650,300)
  .setSize(700, 45)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontL)
  .setText("RUN L BLASTING")
  ;
  
  cP5.addBang("run_r_clean")
  .setPosition(650,495)
  .setSize(700, 45)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontM)
  .setText("RUN R CLEANING")
  ;
  
  cP5.addBang("run_r_blast")
  .setPosition(650,545)
  .setSize(700, 45)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontL)
  .setText("RUN R BLASTING")
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

  //Send teleport signal
  cP5.addBang("teleport")
  .setPosition(400, 250)
  .setSize(200, 45)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontM)
  .setText("SET ORIGIN (0,0)")
  ;
  
  //TEST PATTERN
  //---------------------------------------------------------------------------

  //Send test pattern signal
  cP5.addBang("test_pattern")
  .setPosition(400, 300)
  .setSize(200, 45)
  .setTriggerEvent(Bang.RELEASE)
  //caption settings
  .getCaptionLabel()
  .align(ControlP5.CENTER, ControlP5.CENTER)
  .setColor(255)
  .setFont(fontM)
  .setText("RUN TEST PATTERN")
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