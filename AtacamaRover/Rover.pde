class Rover { //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>//
  Serial myPort;
  PApplet sketch;
  Hexgrid hexgrid;
  Queue queue;
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
  float cmdMagnitude; //if the rover is moving forward, this is given in cm. If it's turning, it is in radians

  int watchdog;
  long handshakeTimer;

  //status variables
  boolean handshake;   // tracks acknowldgement from rover

  Rover(Hexgrid hexgrid_, PApplet sketch_, String serial) {
    sketch = sketch_;
    hexgrid = hexgrid_;
    //rMatrix = new DMatrixRMaj();
    //location = new PVector();
    destination = new PVector();
    myPort = new Serial(sketch, serial, 9600);
    //destination = new PVector(.5*width, .5*height);
    location = new PVector(0, 0);
    turnMOE = radians(turnMOE);
    //nudgeMOE = radians(nudgeMOE);
    //ready = true;
    handshake = true;
    watchdog = 11; //set watchdog high, so nothing will happen until the rover is located at least once
  }
  void initQueue(Queue queue_) {
    queue = queue_;
  }
  void resetVars() {
    //command = "stop";
    println("reset rover vars");
    //cmdMagnitude = 0;
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


  void drive() {
    watchdog = 0;
    if (queue.checkNew()) { //if the user has pressed the button, stop the current command
      //stop();
      resetVars();
    }
    //println("handshake: " + handshake);
    //stop();
    setCommand();
    if (handshake && (millis()-handshakeTimer > 1000)) {
      sendCommand();
      handshake = false;
    }
  }

  void setCommand() {
    //println("Set command");
    if (queue.areAnyCommandsExecutable()) {
      while (!queue.isExecutableCommand()) {
        println("queue 0 not executable");
        queue.commandComplete();
      }
      queue.nextCommand(); // sets commandlist<0> to current command
      //println("drive");
      boolean turnBool = false; //boolean variables for wayfinding while driving (not about status of the current rovercommand)
      //boolean nudgeTurnBool = false;
      boolean driveBool = false;
      //boolean nudgeDriveBool = false;
      destination = queue.getDestination();
      float pxdist = PVector.dist(location, destination);
      //set drive/turn variables
      dist = (float) queue.getDistance();

      if (pxdist >= hexSize/2) { //5 cm
        driveBool = true;
        turnBool = true;
        queue.checkCt = 0;
      } else {
        driveBool = false;
        //println("within target distance");
      }
      targetHeading = queue.getHeading(); //
      targetHeading = normalizeRadians(targetHeading);
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
        queue.moveComplete();
      }
    } else {
      command = "stop";
    }
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

    if (commandByte == 'a' || commandByte == 'd' || commandByte == 'w' || commandByte == ' ') {
      String cmdString = commandByte + "," + cmdMagnitude;
      if (!cmdString.equals(lastCommandStr)) {
        myPort.write(cmdString + '\n');
        println("command (noByte): " + cmdString);
        lastCommandStr = cmdString;
      }
    }
  }
  void sendCommand(byte commandByte) {

    if (commandByte == 'a' || commandByte == 'd' || commandByte == 'w' || commandByte == ' ') {
      String cmdString = commandByte + "," + cmdMagnitude;
      if (!cmdString.equals(lastCommandStr)) {
        myPort.write(cmdString + '\n');
        lastCommandStr = cmdString;
        println("command (byte): " + cmdString);
      }
    }
  }
  void stop() {
    //myPort.write("0,0" + '\n');
    println("stop");
    command = "stop";
    cmdMagnitude = 0;
  }

  void displayHeading(PGraphics buffer) {
    buffer.beginDraw();
    buffer.pushMatrix();
    buffer.translate(location.x * camScale, location.y * camScale);
    buffer.strokeWeight(2);
    buffer.fill(255, 0, 0);
    buffer.textSize(24);
    buffer.pushMatrix();
    buffer.rotate(heading);
    buffer.stroke(255, 0, 0);
    buffer.line(0, 0, 0, - 50);
    buffer.popMatrix();
    buffer.pushMatrix();
    buffer.rotate(targetHeading);
    buffer.stroke(0, 255, 0);
    buffer.line(0, 0, 0, - 50);
    buffer.popMatrix();
    buffer.noStroke();
    buffer.ellipse(0, 0, 10, 10);
    buffer.popMatrix();
    if (queue.isExecutableCommand()) {
      buffer.pushMatrix();
      PVector destination = queue.getDestination();
      buffer.translate(destination.x*camScale, destination.y*camScale);
      buffer.stroke(255, 0, 0);
      buffer.ellipse(0, 0, 10, 10);
      buffer.popMatrix();
    }
    buffer.endDraw();
  }
}
//line(pixelLocation.x, pixelLocation.y, dy, dx);
