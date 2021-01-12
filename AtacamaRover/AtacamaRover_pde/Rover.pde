class Rover { //<>// //<>// //<>// //<>// //<>// //<>//
  Serial myPort;
  PApplet sketch;
  HexGrid hexGrid;
  Queue queue;
  DMatrixRMaj rMatrix;
  double[] euler;
  float heading = 0;
  float destinationHeading = 0;
  float ldelta = 0;
  float rdelta = 0;
  float dist = 0;
  PVector destination;
  PVector location;
  PVector startLoc;
  boolean inBounds;
  float turnMOE = 60;   // margin of error for turning in degrees
  float nudgeMOE = 10;
  String command;
  String lastCommand;

  int watchDog = 0;


  int checkCt;

  //status variables
  boolean done, handshake, ready;

  Rover(HexGrid hexGrid_, PApplet sketch_, String serial, String queueSerial) {
    sketch = sketch_;
    hexGrid = hexGrid_;
    rMatrix = new DMatrixRMaj();
    location = new PVector();
    destination = new PVector();
    startLoc = new PVector();
    euler = new double[2];
    myPort = new Serial(sketch, serial, 9600);
    destination = new PVector(width/2, height/2);
    queue = new Queue(sketch, this, queueSerial);
    turnMOE = radians(turnMOE);
    nudgeMOE = radians(nudgeMOE);
    handshake = true;
    command = "stop";
  }

  void resetVars() {
    command = "stop";
    ready = true;
    checkCt = 0;
    handshake = true;
  }

  void run() {

    queue.update();
    if (queue.checkNew()) { //if the user has pressed the button, stop the current command
      resetVars();
    }
    if (ready) {
      if (queue.checkNext()) {
        setDriveParams(queue.getNext());
      }
    }
    if (!ready) {
      drive();
    }
    if (watchDog > 5) {
      command = "stop";
      myPort.write(' ');
      //println("watchdog");
    } else {
      sendCommand();
    }
    if (myPort.available()>0) {
      handshake = true;
    }
    watchDog++;
    displayHeading();
  }
  void setDriveParams(Hexagon h) {
    destination.set(h.getXY());
    ready = false;
    startLoc.set(location);
    dist =  PVector.dist(location, destination);
    float dy = destination.y - location.y;
    float dx = destination.x - location.x;
    destinationHeading = (atan2(dy, dx)+.5*PI);
    while (destinationHeading < 0 || destinationHeading > TWO_PI) {
      if (destinationHeading < 0) {
        destinationHeading += TWO_PI;
      }
      if (destinationHeading > TWO_PI) {
        destinationHeading -= TWO_PI;
      }
    }
  }
  void setDriveParams(float heading_){
    ready = false;
    startLoc.set(location);
    dist =  0;
    destinationHeading = heading_;
    while (destinationHeading < 0 || destinationHeading > TWO_PI) {
      if (destinationHeading < 0) {
        destinationHeading += TWO_PI;
      }
      if (destinationHeading > TWO_PI) {
        destinationHeading -= TWO_PI;
      }
    }
  }
  void drive() {
    boolean turnBool = false;
    boolean nudgeTurnBool = false;
    boolean driveBool = false;
    boolean nudgeDriveBool = false;
    float distTraveled = PVector.dist(location, startLoc);



    if (min(abs(ldelta), abs(rdelta))>turnMOE) { //<>//
      nudgeTurnBool = false;
      turnBool = true;
    } else if (min(abs(ldelta), abs(rdelta))>nudgeMOE) {
      nudgeTurnBool = true;
      turnBool = true;
    } else { 
      nudgeTurnBool = false;
      turnBool = false;
    }
    if (abs(distTraveled) <= abs(dist)-hexSize) {
      driveBool = true;
      nudgeDriveBool = false;
    } else if (abs(distTraveled) <= abs(dist)-hexSize/2) {
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
      resetVars();
      queue.turnComplete();
    }
  }

  void updateLocation(FiducialFound f) {
    watchDog = 0;
    rMatrix.set(f.getFiducialToCamera().getR());
    //detector.render(sketch, f);
    euler = ConvertRotation3D_F64.matrixToEuler(rMatrix, EulerType.XYZ, (double[])null);
    heading = (float) euler[2]; // - .5*PI;
    while (heading < 0 || heading > TWO_PI) {
      if (heading < 0) {
        heading+= TWO_PI;
      }
      if (heading > TWO_PI) {
        heading -= TWO_PI;
      }
    }
    ldelta = heading - destinationHeading;
    rdelta = destinationHeading - heading;
    if (ldelta < 0) {
      ldelta += TWO_PI;
    }
    if (rdelta < 0) {
      rdelta += TWO_PI;
    }
    location.set((float)f.getImageLocation().x, (float)f.getImageLocation().y);
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
handshake = true;
    if (handshake) {
      handshake = false;
      myPort.write(commandByte);
      lastCommand = command;
      //println(command);
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
    rotate(destinationHeading);
    stroke(0, 255, 0);
    line(0, 0, 0, -50);
    popMatrix();
    popMatrix();
    //float a = (atan2(dy, dx));
    //if (a < 0) {
    //  a+= TWO_PI;
  }
}
