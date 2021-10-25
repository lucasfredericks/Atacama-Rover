class Rover { //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>//
  Serial myPort;
  PApplet sketch;
  Hexgrid hexgrid;
  Queue queue;
  PImage icon;
  float heading = 0;
  float targetHeading = 0;
  float dist = 0;
  PVector destination;
  PVector location;
  boolean inBounds;
  //boolean ready;
  float turnMOE = 10;     // margin of error for turning. Given in degrees and converted to radians in constructor
  String command;
  String lastCommandStr;
  float cmdMagnitude; //if the rover is moving forward, this is given in mm. If it's turning, it is in radians
  Se3_F64 roverToCamera;
  

  int watchdog;
  long handshakeTimer;

  //status variables
  boolean handshake;   // tracks acknowldgement from rover

  Rover(Hexgrid hexgrid_, PApplet sketch_, String serial) {
    sketch = sketch_;
    hexgrid = hexgrid_;
    destination = new PVector();
    myPort = new Serial(sketch, serial, 9600);
    location = new PVector(0, 0);
    turnMOE = radians(turnMOE);
    handshake = true;
    watchdog = 11; //set watchdog high, so nothing will happen until the rover is located at least once
    String path = sketchPath() + "/data/icons/rover_arrow.png";
    icon= loadImage(path);
  }
  void initQueue(Queue queue_) {
    queue = queue_;
  }
  void resetVars() {
    println("reset rover vars");
    stop_();
    handshake = true;
    handshakeTimer = millis();
  }

  void run() {

    watchdog++;

    while (myPort.available()>0) {

      int inByte = myPort.read();
      if (inByte == 'r') {
        if (!handshake) {
          print("handshake");
          handshake = true;
          handshakeTimer=millis();
        }
      }
    }
  }
  //float compareDistances(PVector roverDest) {
  //  float distTraveled = abs(PVector.dist(moveStartLocation, location));
  //  float turnDistToTravel = abs(PVector.dist(moveStartLocation, roverDest));
  //  float distCompare =turnDistToTravel - distTraveled; //negative number means it has gone too far

  //  return distCompare;
  //}

  void setDestHeading(RoverCommand currentCmd) {

    destination = currentCmd.getXY();
    //println("destination: " + destination);
    float dy = destination.y - location.y;
    float dx = destination.x - location.x;
    targetHeading = (atan2(dy, dx)+.5*PI);
    targetHeading = normalizeRadians(targetHeading);
    //println("set destination heading");
  }

  void setFinalHeading(RoverCommand currentCmd) {
    if (currentCmd.cmdByte == 'a' || currentCmd.cmdByte == 'd' || currentCmd.cmdByte == 's') { //only reorient 
      targetHeading = currentCmd.getRadianDir();
      targetHeading = normalizeRadians(targetHeading);
    } else {
      targetHeading = heading;
      println("set final heading");
    }
  }

  void updateLocation(FiducialFound f) {
    roverToCamera=f.getFiducialToCamera();
    DMatrixRMaj rMatrix = f.getFiducialToCamera().getR();
    double[] euler;
    euler = ConvertRotation3D_F64.matrixToEuler(rMatrix, EulerType.XYZ, (double[])null);
    heading = (float) euler[2]; // - .5*PI;
    heading = normalizeRadians(heading);
    location.set((float)f.getImageLocation().x, (float)f.getImageLocation().y);
    //rover.location = location;
    queue.location = location;
    PVector hexID = hexgrid.pixelToKey(location);
    if (hexgrid.checkHex(hexID)) {
      drive();
    }
  }


  void drive() {
    watchdog = 0;
    //if (queue.checkNew()) { //if the user has pressed the button, stop the current command
    //  //resetVars();
    //}
    setCommand();
    if (handshake && (millis()-handshakeTimer > 500)) {
      sendCommand();
    }
  }
  
  void clearCommand(){
    
  }

  void setCommand() {
    
    RoverCommand currentCmd = null;
    if (queue.checkQueue()) {             //if there are executable commands in the queue
      currentCmd = queue.getCurrentCmd(); // sets currentcmd to commandlist<0> 
      if (currentCmd.inBounds == false) { //if currentcmd is oob
        do {                              //advance the queue until one is inbounds or there are no more commands
          queue.commandComplete(); 
          currentCmd = null; 
          if (queue.checkQueue()) {
            currentCmd = queue.getCurrentCmd(); //set to
          }
        } while (currentCmd != null && currentCmd.inBounds == false);
      }
    }
    if (currentCmd == null) {
      command = "stop";
    } else if (currentCmd.scan) {
      queue.scan();
      currentCmd.scan = false;
    } else {
      setDestHeading(currentCmd);
      boolean turnBool = true; //boolean variables for wayfinding while driving
      boolean driveBool = true;
      float pxdist = PVector.dist(location, destination);
      //println("location = " + location + ", destination = " + destination + ", distance = " + pxdist);
      //set drive/turn variables
      dist = (float) getDistance(currentCmd);

      if (pxdist >= hexSize/2) { //5 cm
        queue.checkCt = 0;
        setDestHeading(currentCmd);
      } else {
        driveBool = false;
        queue.checkCt = 0;
        setFinalHeading(currentCmd);
      }
      float ldelta = heading - targetHeading;
      float rdelta = targetHeading - heading;
      ldelta = abs(normalizeRadians(ldelta));
      rdelta = abs(normalizeRadians(rdelta));

      if (min(ldelta, rdelta)>turnMOE) { 
        turnBool = true;
      } else { 
        turnBool = false;
      }

      if (turnBool) {
        if (abs(ldelta)<abs(rdelta)) {
          command = "left";
          cmdMagnitude = ldelta;
        } else {
          command = "right";
          cmdMagnitude = rdelta;
        }
      } else if (driveBool) {
        command = "forward";
        cmdMagnitude = dist;
      } else {
        println("move complete");
        currentCmd = null;
        queue.commandComplete();
      }
    }
  }

  double getDistance(RoverCommand currentCmd) {
    
    double dist = currentCmd.getDist(roverToCamera);
    return dist;
  }

  float normalizeRadians(float theta) {
    while (theta < 0 || theta > TWO_PI) {
      if (theta < 0) {
        theta += TWO_PI;
      }
      if (theta > TWO_PI) {
        theta -= TWO_PI;
      }
    }
    return theta;
  }

  void sendCommand() {
    byte commandByte = ' ';     //invalid command will default to 'stop'

    if (command == "stop") {
      commandByte = ' ';
    } else if (command == "left") {
      commandByte = 'a';
    } else if (command == "right") {
      commandByte = 'd';
    } else if (command == "forward") {
      commandByte = 'w';
    }

    String cmdString = commandByte + "," + cmdMagnitude;
    if (!cmdString.equals(lastCommandStr)) {
      myPort.write(cmdString + '\n');
      println("command (noByte): " + cmdString);
      lastCommandStr = cmdString;
      handshake = false;
    }
  }

  void sendCommand(byte commandByte) {

    if (commandByte == 'a' || commandByte == 'd' || commandByte == 'w' || commandByte == ' ') {
      String cmdString = commandByte + "," + cmdMagnitude;
      if (!cmdString.equals(lastCommandStr)) {
        myPort.write(cmdString + '\n');
        lastCommandStr = cmdString;
        println("command (byte): " + cmdString);
        handshake = false;
      }
    }
  }
  void stop_() {
    //myPort.write("0,0" + '\n');
    println("stop");
    command = "stop";
    cmdMagnitude = 0;
    sendCommand();
  }

  void displayHeading(PGraphics buffer) {
    buffer.beginDraw();
    buffer.pushMatrix();
    buffer.translate(location.x * camScale, location.y * camScale);
    buffer.strokeWeight(4);
    buffer.fill(255);
    buffer.stroke(0);
    buffer.rotate(heading);
    buffer.imageMode(CENTER);
    buffer.image(icon, 0, 0, 45,60);
    //buffer.beginShape();
    //buffer.vertex(0, 20);
    //buffer.vertex(20, 30);
    //buffer.vertex(0, -30);
    //buffer.vertex(-20, 30);
    //buffer.endShape(CLOSE);
    //buffer.stroke(255, 0, 0);
    //buffer.line(0, 0, 0, - 50);
    buffer.popMatrix();
    buffer.endDraw();
  }
}
