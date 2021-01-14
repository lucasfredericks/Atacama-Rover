class Rover { //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>//
  Serial myPort;
  PApplet sketch;
  HexGrid hexGrid;
  Queue queue;
  DMatrixRMaj rMatrix;
  double[] euler;
  float heading = 0;
  float targetHeading = 0;
  float dist = 0;
  PVector destination;
  PVector location;
  boolean inBounds;
  float turnMOE = 60;   // margin of error for turning in degrees
  float nudgeMOE = 10;
  String command;
  String lastCommand;


  int watchDog = 0;


  int checkCt;

  //status variables
  boolean handshake; // tracks acknowldgement from rover

  Rover(HexGrid hexGrid_, PApplet sketch_, String serial, String queueSerial) {
    sketch = sketch_;
    hexGrid = hexGrid_;
    rMatrix = new DMatrixRMaj();
    location = new PVector();
    destination = new PVector();
    euler = new double[2];
    myPort = new Serial(sketch, serial, 9600);
    destination = new PVector(.5*width, .5*height);
    location = new PVector();
    queue = new Queue(sketch, this, queueSerial);
    turnMOE = radians(turnMOE);
    nudgeMOE = radians(nudgeMOE);
    handshake = true;
  }

  void resetVars() {
    command = "stop";
    checkCt = 0;
    handshake = true;
  }

  void run() {

    queue.update();
    if (queue.checkNew()) { //if the user has pressed the button, stop the current command
      resetVars();
    }
    if (watchDog > 5) {
      command = "stop";
      myPort.write(' ');
      println("watchdog");
    } else if (handshake) {
      handshake = false;
      sendCommand();
    }
    if (myPort.available()>0) {
      handshake = true;
    }
    watchDog++;
    displayHeading();
  }

  void updateLocation(FiducialFound f) {
    watchDog = 0;
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
      println(dist);

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
      if (dist >= 2*hexSize) { //coarse driving
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
        }
        else{checkCt++;}
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
    byte commandByte = ' ';         //invalid command will default to 'stop'
    if (command == "nright") {
      commandByte = 'D';         //nudge right
    } else if (command == "nleft") {
      commandByte = 'A';         //nudge left
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
  void displayHeading() {
    pushMatrix();
    translate(location.x, location.y);
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
}
//line(pixelLocation.x, pixelLocation.y, dy, dx);
