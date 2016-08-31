//SERIAL PORT COMMUNICATION
//Checks if serial port has available data
//if data is a "READY" signal from the Arduino
//checks if commands are available to send
//ifso, commands are written to serial port
void serialRun() {

  if (myPort.available() > 0) {
    val = myPort.readString();

    //Arduino firmware signals readiness with a ">"
    if (val.equals("\n> ") ) {

      lastSent="";

      //Check if paused
      if (!paused) {
        if ( interrupt.size() > 0 ) {
          String s = interrupt.sendNext();
          myPort.write(s);
          println("sent: " + s);
          lastSent = s;
        }
        //check if commands are available
        else if ( GB.size() > 0 ) {
          String s = GB.sendNext();
          myPort.write(s);
          //Echo command to debug panel
          println("sent: " + s);
          lastSent = s;
        } else {
          //currentPath = "";
          timeLeft = "";
          lineNum = "";
        }
      } else {
        //check if interrupt commands are available
        if ( interrupt.size() > 0 ) {
          String s = interrupt.sendNext();
          myPort.write(s);
          lastSent = s;
        }
      }
    } else {
      println( "recieved: " + val );

      if (val.length() > 0 && val != " ") {
        String[] temp = split(val, "\n");
        lastVal.clear();
        for (int i = 0; i < temp.length; i++) {
          if (temp[i].length() > 1) {
            lastVal.add(temp[i]);
          }
        }
      }
    }
  }
}

void serialConnect() {
  //SEARCH FOR OPEN SERIAL PORT
  String[] ports = Serial.list();

  if ( ports.length > 0 ) {
    port = ports[0];
    myPort = new Serial(this, port, 115200);
    connected = true;
    cP5.get(Bang.class, "serial").setColorForeground(color(255));
    cP5.get(Bang.class, "clear").setColorForeground(color(255));
  } else {
    connected = false;
    cP5.get(Bang.class, "serial").setColorForeground(color(255));
    cP5.get(Bang.class, "clear").setColorForeground(color(255));
  }
}