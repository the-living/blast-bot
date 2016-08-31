void renderConsole(){
  //RIGHT BOARD CONSOLE
  fill(255);
  rect(610, 0, width, height);

  fill(0);
  textFont( fontL, 50 );
  text("BOARD BLASTER", 650, 45);

  //SVG preview of board
  float scalar = 0.25;
  
  rectMode(CORNERS);
  stroke(0);
  strokeWeight(2);
  noFill();
  if (metric){
    rect(650, 550, 650+(bWidth*scalar), 550-(bHeight*scalar));
  } else {
    rect(650, 550, 650+(bWidth*mm2in*scalar), 550-(bHeight*mm2in*scalar));
  }
  
  rectMode(CORNER);
  
  //visualize blast nozzle position
  stroke(0);
  fill(color(255, 222, 23, 200));
  float nozzleX = 650 + posx*scalar;
  float nozzleY = 550 - posy*scalar;

  strokeWeight(3);
  ellipse(nozzleX, nozzleY, 10, 10);
  noFill();
  strokeWeight(0.5);
  ellipse(nozzleX, nozzleY, 20, 20);
  
  //CURRENT PASS INFO
  stroke(0);
  line(650, 610, 1350, 610);
  textFont( fontL, 24);
  fill(0);
  String pos = "( X: " + posx + "   Y: " + posy + " )";
  text(pos, 650, 600);
  textFont( fontM, 24);
  text("LINE NUMBER: " + lineNum, 650, 640);
  text("TIME LEFT: " + timeLeft, 650, 670);

  //JOG CONTROLLER OUTLINE
  noFill();
  stroke(255);
  rect(25, 25, 350, 350);

  //CONSOLE AREA (BLACK)
  fill(0);
  noStroke();
  rect(0, 400, 600, 500);
  
  //TX-RX over Serial port
  stroke(255);
  line(0, 500, 600, 500);
  noStroke();
}

void checkConnection(){
  //CHECK CONNECTION STATUS
  //if disconnected, check for available connections
  //if connected, check for signals from Arduino
  if (!connected){
    serialConnect();
    fill(pauseColor);
    textFont( fontS, 18);
    text("NOT CONNECTED",25,775);
  } else {
    serialRun();
    fill(resumeColor);
    textFont( fontS, 18);
    text("CONNECTED ON " + port, 25, 775);
  }

  //PRINT OUT LAST SENT CODE IN GREEN
  textFont(fontM, 22);
  fill(0, 255, 0);
  text(lastSent, 25, 530);

  //PRINT OUT LAST RECIEVED CODE IN RED
  fill(255, 0, 0);
  for ( int i = 0; i < lastVal.size(); i++ ) {
    text(lastVal.get(i), 25, 560+i*28);
  } 
}