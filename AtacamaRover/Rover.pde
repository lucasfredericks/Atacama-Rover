class Rover { //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>//
  Serial myPort;
  PApplet sketch;
  Hexgrid hexgrid;
  Queue queue;
  DMatrixRMaj rMatrix;
  double[] euler;
  float heading = 0;
  float targetHeading = 0;
  float dist = 0;
  PVector destination;
  PVector location;
  boolean inBounds;
  float turnMOE = 60;     // margin of error for turning in degrees
  float nudgeMOE = 10;
  String command;
  String lastCommand;


  int watchdog;


  int checkCt;

  //status variables
  boolean handshake;   // tracks acknowldgement from rover

  Rover(Hexgrid hexgrid_, PApplet sketch_, String serial) {
    sketch = sketch_;
    hexgrid = hexgrid_;
    rMatrix = new DMatrixRMaj();
    location = new PVector();
    destination = new PVector();
    euler = new double[2];
    myPort = new Serial(sketch, serial, 9600);
    destination = new PVector(.5*width, .5*height);
    location = new PVector();
    turnMOE = radians(turnMOE);
    nudgeMOE = radians(nudgeMOE);
    handshake = true;
    watchdog = 6; //set watchdog high, so nothing will happen until the rover is located at least once
  }
  void initQueue(Queue queue_) {
    queue = queue_;
  }
  void resetVars() {
    command = "stop";
    checkCt = 0;
    handshake = true;
  }

  void run() {

    if (watchdog <= 5) {

      if (queue.checkNew()) { //if the user has pressed the button, stop the current command
        resetVars();
      }
      watchdog++;
      //displayHeading();
    } else {
      command = "stop";
    }    
    if (myPort.available()>0) {
      handshake = true;
    }
    if (handshake) {
      handshake = false;
      sendCommand();
    }
  }

  PVector getLocation() {
    return location;
  }

  void updateLocation(FiducialFound f) {
    watchdog = 0;
    rMatrix.set(f.getFiducialToCamera().getR());
    //detector.render(sketch, f);
    euler = ConvertRotation3D_F64.matrixToEuler(rMatrix, EulerType.XYZ, (double[])null);
    heading = (float) euler[2]; // - .5*PI;
    heading = normalizeRadians(heading);


    location.set((float)f.getImageLocation().x, (float)f.getImageLocation().y);
    queue.updateLocation(location);
    drive();
  }
  void drive() {
    boolean turnBool = false; //boolean variables for wayfinding while driving (not about status of the current rovercommand)
    boolean nudgeTurnBool = false;
    boolean driveBool = false;
    boolean nudgeDriveBool = false;

    if (queue.isActiveCommand()) {
      targetHeading = queue.getHeading(); //
      targetHeading = normalizeRadians(targetHeading);
      float ldelta = heading - targetHeading;
      float rdelta = targetHeading - heading;
      ldelta = normalizeRadians(ldelta);
      rdelta = normalizeRadians(rdelta);

      destination = queue.getDestination();
      dist = queue.compareDistances(destination);
      //println(dist);

      //set drive/turn variables
      if (min(abs(ldelta), abs(rdelta))>turnMOE) { //do coarse turning first
        nudgeTurnBool = false;
        turnBool = true;
      } else if (min(abs(ldelta), abs(rdelta))>nudgeMOE) { //otherwise do fine turning
        nudgeTurnBool = true;
        turnBool = true;
      } else { //otherwise the rover is facing in the correct direction
        nudgeTurnBool = false;
        turnBool = false;
      }
      if (dist >= hexSize) { //coarse driving
        driveBool = true;
        nudgeDriveBool = false;
      } else if (dist >= hexSize/4) { //fine driving
        driveBool = false;
        nudgeDriveBool = true;
      }

      if (nudgeTurnBool) {
        if (abs(ldelta)<abs(rdelta)) {
          command = "nleft";
        } else {
          command = "nright";
        }
      } else if (turnBool) {
        if (abs(ldelta)<abs(rdelta)) {
          command = "left";
        } else {
          command = "right";
        }
      } else if (nudgeDriveBool) {
        command = "nforward";
      } else if (driveBool) {
        command = "forward";
      } else {
        if (checkCt > 0) {
          queue.moveComplete();
          resetVars();
        } else {
          checkCt++;
        }
      }
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
    if (command == "nright") {
      commandByte = 'D'; //nudge right
    } else if (command == "nleft") {
      commandByte = 'A'; //nudge left
    } else if (command == "stop") {
      commandByte = ' ';
    } else if (command == "left") {
      commandByte = 'a';
    } else if (command == "right") {
      commandByte = 'd';
    } else if (command == "forward") {
      commandByte = 'w';
    } else if (command == "nforward") {
      commandByte = 'W';
    }

    if (commandByte == 'W'||commandByte == 'A'||commandByte == 'S'||commandByte == 'D'|| command!= lastCommand) {
      myPort.write(commandByte);
      lastCommand = command;
      println(command);
    }
  }
  void displayHeading(PGraphics buffer) {
    buffer.beginDraw();
    buffer.pushMatrix();
    buffer.translate(location.x*camScale, location.y*camScale);
    buffer.strokeWeight(2);
    buffer.fill(255, 0, 0);
    buffer.textSize(24);
    buffer.pushMatrix();
    buffer.rotate(heading);
    buffer.stroke(255, 0, 0);
    buffer.line(0, 0, 0, -50);
    buffer.popMatrix();
    buffer.pushMatrix();
    buffer.rotate(targetHeading);
    buffer.stroke(0, 255, 0);
    buffer.line(0, 0, 0, -50);
    buffer.popMatrix();
    buffer.noStroke();
    buffer.ellipse(0, 0, 10, 10);
    buffer.popMatrix();
    buffer.endDraw();
    //float a = (atan2(dy, dx));
    //if (a < 0) {
    //  a+= TWO_PI;
  }
}
//line(pixelLocation.x, pixelLocation.y, dy, dx);
