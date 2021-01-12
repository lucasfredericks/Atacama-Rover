class Rover { //<>// //<>// //<>// //<>// //<>// //<>//
  Serial myPort;
  PApplet sketch;
  HexGrid hexGrid;
  Queue queue;
  DMatrixRMaj rMatrix;
  double[] euler;
  float heading = 0;
  float targetHeading = 0;
  float ldelta = 0;
  float rdelta = 0;
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
  boolean done, handshake, ready;

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
    ready = true;
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
    } else {
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
    while (heading < 0 || heading > TWO_PI) {
      if (heading < 0) {
        heading+= TWO_PI;
      }
      if (heading > TWO_PI) {
        heading -= TWO_PI;
      }
    }


    location.set((float)f.getImageLocation().x, (float)f.getImageLocation().y);
    dist =  PVector.dist(location, destination);
    float dy = destination.y - location.y;
    float dx = destination.x - location.x;
    float destHeading = (atan2(dy, dx)+.5*PI);
    while (destHeading < 0 || destHeading > TWO_PI) {
      if (destHeading < 0) {
        destHeading += TWO_PI;
      }
      if (destHeading > TWO_PI) {
        destHeading -= TWO_PI;
      }
    }
    ldelta = heading - destHeading;
    rdelta = destHeading - heading;
    if (ldelta < 0) {
      ldelta += TWO_PI;
    }
    if (rdelta < 0) {
      rdelta += TWO_PI;
    }
    drive();
  }
  void drive(float orientation, float distance) {
    boolean turnBool = false;
    boolean nudgeTurnBool = false;
    boolean driveBool = false;
    boolean nudgeDriveBool = false;

    if (ready) {
      if (queue.checkNext()) {
        destination = hexGrid.getXY(queue.getNext());
        ready = false;
        //println(destination);
      }
    }

    if (min(abs(ldelta), abs(rdelta))>turnMOE) {
      nudgeTurnBool = false;
      turnBool = true;
    } else if (min(abs(ldelta), abs(rdelta))>nudgeMOE) {
      nudgeTurnBool = true;
      turnBool = true;
    } else { 
      nudgeTurnBool = false;
      turnBool = false;
    }
    if (abs(dist) >= hexSize) {
      driveBool = true;
      nudgeDriveBool = false;
    } else if (abs(dist) >= hexSize/4) {
      driveBool = false;
      nudgeDriveBool = true;
    }
    if (!ready) {
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
      }
    }
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
