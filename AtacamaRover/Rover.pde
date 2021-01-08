class Rover { //<>// //<>// //<>// //<>//
  Serial myPort;
  PApplet sketch;
  HexGrid hexGrid;
  Queue queue;
  DMatrixRMaj rMatrix;
  PVector pixelLocation;
  double[] euler;
  float heading = 0;
  float targetHeading = 0;
  PVector pixelDest;
  PVector startLoc;
  boolean inBounds;
  Hexagon hexLoc;
  Hexagon lastHex;
  Hexagon hexDest;
  int cardinalHeading;
  int turnMOE = 10; // margin of error for turning in degrees
  String command;
  String lastCommand;
  long nudgeTimer;
  int nudgeTimeout = 100;

  int watchDog = 0;


  int checkCt;

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

  void resetVars() {
    command = "stop";
    turning = false;
    driving = false;
    ready = true;
    checkCt = 0;
  }

  void run() {

    queue.update();
    if (queue.checkNew()) { //if the user has pressed the button, stop the current command
      resetVars();
    }
    if (watchDog > 5) {
      command = "stop";
      println("watchdog");
    } else {
      if (ready) {
        if (turning) {
          turn();
        } else if (driving) {
          drive();
        } else if (queue.checkNext()) {
          byte command_ = queue.getNext();
          parseCommand(command_);
          ready = true;
        }
      }
    }
    if (command!=lastCommand) {
      sendCommand();
    }
    watchDog++;
    displayHeading();
  }

  void updateLocation(FiducialFound f) {
    watchDog = 0;
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
    hexLoc = hexGrid.pixelToHex((int)pixelLocation.x, (int)pixelLocation.y);
    if (lastHex != hexLoc) {
      hexGrid.occupyHex(this, hexLoc, lastHex);
      lastHex = hexLoc;
    }

    checkProgress();
  }
  void nudge() {
    float ldelta;
    float rdelta;
    //if (!reverse) { 
    ldelta = heading - targetHeading;
    rdelta = targetHeading - heading;
    //} else {
    //  ldelta = targetHeading - heading; //invert steering when in reverse;
    //  rdelta = heading - targetHeading;
    //}
    if (millis() - nudgeTimer > nudgeTimeout) {
      nudgeTimer = millis();

      if (ldelta < 0) {
        ldelta += TWO_PI;
      }
      if (rdelta < 0) {
        rdelta += TWO_PI;
      }
      if (ldelta < rdelta) {
        command = "nleft";
      } else if (rdelta > ldelta) {
        command = "nright";
      }
      checkCt++; //<>//
      println(checkCt);
    }
  }

  void turn() {
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
      command = "left";
    } else {
      command = "right";
    }
    ready = false;
  }
  void checkProgress() {
    float nudgeMOE = radians(5);
    if (turning) {
      float delta = targetHeading - heading;
      //println("delta = " + degrees(delta));
      //if (delta < 0) {
      //  delta += TWO_PI;
      //}
      if (abs(delta) < radians(turnMOE)) {
        command = "stop";
        if (abs(delta) > radians(nudgeMOE) || checkCt <=5) {
          nudge();
        } else {
          turning = false;
          ready = true;
          checkCt = 0;
          if (!driving) {
            resetVars();
            queue.complete();
          }
        }
      }
    } else if (driving) {
      float dist =  PVector.dist(pixelLocation, startLoc);  
      float targetDist = PVector.dist(startLoc, pixelDest);
      //println("dist: " + dist);
      //println("targetDist: " +targetDist);
      if (abs(dist) >= abs(targetDist)-5) {
        command = "stop";
        queue.complete();
        resetVars();
      }
    }
  }

  void drive() {
    if (reverse) {
      command = "back";
    } else {
      command = "forward";
    }
    ready = false;
  }

  void parseCommand(byte command_) {
    hexLoc = hexGrid.pixelToHex((int)pixelLocation.x, (int)pixelLocation.y);
    Hexagon[] neighbors = hexGrid.getNeighbors(hexLoc);
    int dest;
    turning = true; // Each command starts with an alignment turn
    // convert relative commands to absolute
    if (command_ == 102) {  // 'f' forward
      dest = cardinalHeading;
      if (checkDestination(neighbors[dest])) {
        driving = true;
        reverse = false;
        setDestination(neighbors[dest]);
      }
    } else if (command_ == 98) { // 'b' back
      dest = cardinalHeading + 3;
      if (dest > 5) {
        dest -= 6;
      }
      if (checkDestination(neighbors[dest])) {
        driving = true;
        reverse = true; // flip turning directions
        //dest = cardinalHeading;
        setDestination(neighbors[dest]);
      }
    } else if (command_ == 114) { // 'r' right/clockwise

      dest = cardinalHeading + 1;
      if (dest > 5) {
        dest -= 6;
      }
      driving = false;
      reverse = false;
      setDestination(neighbors[dest]);
    } else if (command_ == 108) { // 'l' counterclockwise
      dest = cardinalHeading -1;
      if (dest < 0) {
        dest += 6;
      }
      driving = false;
      reverse = false;
      setDestination(neighbors[dest]);
    }
  }

  boolean checkDestination(Hexagon h) {

    if (h != null && h.inBounds) {
      return true;
    } else {
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
      if (reverse) {
        a += PI;
      }
      while (a < 0 || a > TWO_PI) {
        if (a < 0) {
          a+= TWO_PI;
        }
        if (a > TWO_PI) {
          a -= TWO_PI;
        }
      }
      targetHeading = a;
    } else {
    }
  }


  void sendCommand() {
    byte commandByte = ' '; //invalid command will default to 'stop'
    if (command == "nright") {
      commandByte = 'd'; //nudge right
    } else if (command == "nleft") {
      commandByte = 'a'; //nudge left
    } else if (command != lastCommand) {

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
    }

    println(command);
    myPort.write(commandByte);

    lastCommand = command;
  }

  //void sendCommand(String cmnd) {
  //  byte commandByte = ' '; //invalid command will default to 'stop'
  //  if (command == "stop") {
  //    commandByte = ' ';
  //  } else if (cmnd == "left") {
  //    commandByte = 'l';
  //  } else if (cmnd == "right") {
  //    commandByte = 'r';
  //  } else if (cmnd == "forward") {
  //    commandByte = 'f';
  //  } else if (cmnd == "back") {
  //    commandByte = 'b';
  //  }
  //  lastCommand = cmnd;
  //}


  //void sendCommand(byte command) { //if the command is  a byte, send it to the rover
  //  myPort.write(command);
  //  println(command);
  //}

  void displayHeading() {
    pushMatrix();
    translate(pixelLocation.x, pixelLocation.y);
    strokeWeight(2);
    fill(255, 0, 0);
    textSize(24);
    pushMatrix();
    rotate(heading);
    stroke(255, 0, 0);
    line(0, 0, 0, -50);
    popMatrix();
    pushMatrix();
    rotate(targetHeading);  
    stroke(0, 255, 0);
    line(0, 0, 0, -50);
    popMatrix();
    popMatrix();
    //float a = (atan2(dy, dx));
    //if (a < 0) {
    //  a+= TWO_PI;
  }
  //line(pixelLocation.x, pixelLocation.y, dy, dx);
}
