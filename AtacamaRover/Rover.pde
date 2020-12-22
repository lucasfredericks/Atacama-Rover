class Rover { //<>// //<>//
  Serial myPort;
  PApplet sketch;
  HexGrid hexGrid;
  Queue queue;
  DMatrixRMaj rMatrix;
  PVector pixelLocation;
  double[] euler;
  float heading;
  float targetHeading;
  PVector pixelDest;
  PVector startLoc;
  boolean inBounds;
  Hexagon hexLoc;
  Hexagon hexDest;
  int cardinalHeading;

  //status variables
  boolean driving, turning, ready, reverse;

  Rover(HexGrid hexGrid_, PApplet sketch_, String serial, String queueSerial) {
    sketch = sketch_;
    hexGrid = hexGrid_;
    rMatrix = new DMatrixRMaj();
    pixelLocation = new PVector();
    euler = new double[2];
    myPort = new Serial(sketch, serial, 9600);
    pixelDest = new PVector();
    startLoc = new PVector();
    queue = new Queue(sketch, this, queueSerial);
  }

  void debug() {
    parseCommand((byte) 'f');
    displayHeading();
  }
  void resetVars() {
    sendCommand("stop");
    turning = false;
    driving = false;
    ready = true;
  }

  void run() {

    queue.update();
    if (queue.checkNew()) { //if the user has pressed the button, stop the current command
      resetVars();
    }
    if (ready) {
      if (turning) {
        turn();
      } else if (driving) {
        drive();
      } else if (queue.checkNext()) {
        byte command = queue.getNext();
        parseCommand(command);
        ready = true;
      }
    } else {
      checkProgress();
    }
    displayHeading();
    colorHex();
  }


  void colorHex() {
    if (hexLoc != null) {
      color fillIn = (255);
      hexLoc.drawHex(fillIn, 200);
    }
  }

  void checkProgress() {
    if (turning) {
      //println("targetHeading = " + degrees(targetHeading));
      //println("heading = " + degrees(heading));
      float delta = targetHeading - heading;
      //println("delta = " + degrees(delta));
      if (delta < 0) {
        delta += TWO_PI;
      }
      if (delta < radians(15)) {
        sendCommand("stop");
        turning = false;
        ready = true;
        if (!driving) {
          resetVars();
          queue.complete();
        }
      }
    } else if (driving) {
      float dist =  PVector.dist(pixelLocation, startLoc);  
      float targetDist = PVector.dist(startLoc, pixelDest);
      //println("dist: " + dist);
      //println("targetDist: " +targetDist);
      if (abs(dist) >= abs(targetDist)-20) {
        sendCommand("stop");
        queue.complete();
        resetVars();
      }
    }
  }

  void updateLocation(FiducialFound f) {
    rMatrix.set(f.getFiducialToCamera().getR());
    //detector.render(sketch, f);
    euler = ConvertRotation3D_F64.matrixToEuler(rMatrix, EulerType.XYZ, (double[])null);
    heading = (float) euler[2];  // - .5*PI;
    while (heading < 0 || heading > TWO_PI) {
      if (heading < 0) {
        heading+= TWO_PI;
      }
      if (heading > TWO_PI) {
        heading -= TWO_PI;
      }
    }
    if (degrees(heading) > 330 || degrees(heading) <= 30 ) { //refactor this into radians probably 
      cardinalHeading = 0;
    } else if (degrees(heading) >  30 && degrees(heading) <= 90 ) {
      cardinalHeading = 1;
    } else if (degrees(heading) >  90 && degrees(heading) <= 150) {
      cardinalHeading = 2;
    } else if (degrees(heading) > 150 && degrees(heading) <= 210) {
      cardinalHeading = 3;
    } else if (degrees(heading) > 210 && degrees(heading) <= 270) {
      cardinalHeading = 4;
    } else if (degrees(heading) > 270 && degrees(heading) <= 330) {
      cardinalHeading = 5;
    }

    pixelLocation.set((float)f.getImageLocation().x, (float)f.getImageLocation().y);    
    hexLoc = hexGrid.getHex(pixelLocation);


    //if (hexGrid.getHex(pixelLocation) != null) {
    //  hexLoc = hexGrid.getHex(pixelLocation);
    //}
  }

  void turn() {
    byte command;
    float ldelta;
    float rdelta;
    //if (!reverse) { 
    ldelta = heading - targetHeading;
    rdelta = targetHeading - heading;
    //} else {
    //  ldelta = targetHeading - heading; //invert steering when in reverse;
    //  rdelta = heading - targetHeading;
    //}

    if (ldelta < 0) {
      ldelta += TWO_PI;
    }
    if (rdelta < 0) {
      rdelta += TWO_PI;
    }
    if (ldelta < rdelta) {
      command = 'l';
    } else {
      command = 'r';
    }
    sendCommand(command);
    ready = false;
  }

  void drive() {
    if (reverse) {
      sendCommand((byte) 'b');
    } else {
      sendCommand((byte) 'f');
    }
    ready = false;
  }

  void parseCommand(byte command) {
    hexLoc = hexGrid.pixelToHex((int)pixelLocation.x, (int)pixelLocation.y);
    Hexagon[] neighbors = hexGrid.getNeighbors(hexLoc);
    int dest;
    turning = true; // Each command starts with an alignment turn
    // convert relative commands to absolute
    if (command == 102) {  // 'f' forward
      dest = cardinalHeading;
      if (checkDestination(neighbors[dest])) {
        driving = true;
        reverse = false;
        setDestination(neighbors[dest]);
      }
    } else if (command == 98) { // 'b' back
      dest = cardinalHeading + 3;
      if (dest > 5) {
        dest -= 6;
      }
      if (checkDestination(neighbors[cardinalHeading])) {
        driving = true;
        reverse = true; // flip turning directions
        dest = cardinalHeading;
        setDestination(neighbors[dest]);
      }
    } else if (command == 114) { // 'r' right/clockwise

      dest = cardinalHeading + 1;
      if (dest > 5) {
        dest -= 6;
      }
      if (checkDestination(neighbors[dest])) {
        driving = false;
        reverse = false;
        setDestination(neighbors[dest]);
      }
    } else if (command == 108) { // 'l' counterclockwise
      dest = cardinalHeading -1;
      if (dest < 0) {
        dest += 6;
      }
      if (checkDestination(neighbors[dest])) {
        driving = false;
        reverse = false;
        setDestination(neighbors[dest]);
      }
    }
  }

  boolean checkDestination(Hexagon h) {

    if (h != null && h.inBounds) {
      return true;
    } else {
      sendCommand("stop");
      resetVars();
      return false;
    }
  }
  void setDestination(Hexagon h) {
    startLoc.set(pixelLocation.x, pixelLocation.y);
    if (hexGrid.getHex(h.id)!= null) {
      hexDest = hexGrid.getHex(h.id);
      pixelDest.set(hexDest.pixelX, hexDest.pixelY);
      //float dy = pixelLocation.y - pixelDest.y;
      //float dx = pixelLocation.x - pixelDest.x;
      float dy = pixelDest.y - pixelLocation.y;
      float dx = pixelDest.x - pixelLocation.x;
      float a = (atan2(dy, dx)+.5*PI);
      while (a < 0 || a > TWO_PI) {
        if (a < 0) {
          a+= TWO_PI;
        }
        if (a > TWO_PI) {
          a -= TWO_PI;
        }
      }
      targetHeading = a;
    }
    else{
      
    }
  }


  void sendCommand(String command) {
    byte commandByte = ' '; //invalid command will default to 'stop'
    if (command == "stop") {
      commandByte = ' ';
    } else if (command == "left") {
      commandByte = 'l';
    } else if (command == "right") {
      commandByte = 'r';
    } else if (command == "forward") {
      commandByte = 'f';
    } else if (command == "back") {
      commandByte = 'b';
    }
    println(commandByte);
    myPort.write(commandByte);
  }

  void sendCommand(byte command) { //if the command is  a byte, send it to the rover
    myPort.write(command);
    println(command);
  }

  void displayHeading() {
    pushMatrix();
    translate(pixelLocation.x, pixelLocation.y);
    strokeWeight(2);
    fill(255, 0, 0);
    textSize(24);
    pushMatrix();
    rotate(heading);
    stroke(255, 0, 0);
    line(0, 0, 0, 50);
    popMatrix();
    pushMatrix();
    rotate(targetHeading);  
    stroke(0, 255, 0);
    line(0, 0, 0, 50);
    popMatrix();
    popMatrix();
    //float a = (atan2(dy, dx));
    //if (a < 0) {
    //  a+= TWO_PI;
  }
  //line(pixelLocation.x, pixelLocation.y, dy, dx);
}
