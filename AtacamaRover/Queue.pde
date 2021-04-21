import processing.serial.*; //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>//
import java.util.Iterator;
import boofcv.processing.*;
PGraphics GUI;

class Queue {

  PApplet sketch;
  CardList cardList;
  Rover rover;
  Serial myPort;
  Hexgrid hexgrid;
  Hexagon scanDest;
  boolean newCommands;
  RoverCommand currentCommand;
  float destinationHeading;
  float commandTotalDistance = 0;
  int checkCt = 0;
  PVector location;
  Se3_F64 roverToCamera;
  PVector moveStartLocation;

  ArrayList<Byte> byteList;
  ArrayList<RoverCommand> commandList;


  Queue(PApplet sketch_, CardList cardList_, Hexgrid hexgrid_, String serial, PGraphics GUI_) {
    cardList = cardList_;
    hexgrid = hexgrid_;
    byteList = new ArrayList<Byte>();
    commandList = new ArrayList<RoverCommand>();
    newCommands = false;
    sketch = sketch_;
    GUI = GUI_;
    myPort = new Serial(sketch, serial, 115200);
    moveStartLocation = new PVector();
    pickScanDest();
    location = new PVector(camWidth/2, camHeight/2);
  }

  void initRover(Rover rover_) {
    rover = rover_;
  }

  void update() {

    if ( myPort.available() > 0) { // If data is available,
      byte[] mainQueue = new byte[5];
      byte[] funcQueue = new byte[5];
      byte[] inBuffer = new byte[12];
      byte interesting = 16; //endByte
      inBuffer = myPort.readBytesUntil(interesting);
      myPort.clear();
      //println(inBuffer);
      if (inBuffer == null || inBuffer.length != 12) { //throw out junk
        return;
      } 
      boolean execute;
      for (int i = 0; i < 5; i++) {
        mainQueue[i] = inBuffer[i];
        funcQueue[i] = inBuffer[i+6];
        parseCodingBlocks(mainQueue, funcQueue);
      }
      //println("parsing queue into byte list");
      if (inBuffer[5] == 'n') {//if the user has pressed the button


        execute = true;
        println("button");
        myPort.write('r'); // tell the control board to turn button red
        //println("button red");
        if (isExecutableCommand()) { //check if the rover is currently driving
          println("the rover is driving");
          myPort.write('g'); //tell the control board the rover is stopping
          //println("button green");
          rover.sendCommand((byte)' ');
          println("stopping the rover");
          initClearCommandList();
          commandList.clear();
          println("clearing queue");
          return;
        } 
        if (byteList.isEmpty()) { //
          println("new queue is empty. Stopping rover, resetting vars");
          myPort.write('g');
          //println("button green");
          //rover.stop();
          initClearCommandList();
          commandList.clear();
          return;
        }
        //myPort.write('r');
        //println("button red");
        newCommands=true;
        println("data in -- execute");
      } else { //if the user has not pressed the button
        if (isExecutableCommand()) {//if the rover is driving, ignore new commands
          return;
        } else {
          execute = false;
          newCommands=false;
          //println("data in -- no execute");
          myPort.write('g'); //tell the reader board that the rover is stopped
          //println("button green");
        }
      }

      parseCommandList(execute);
      //println("parsing");
    }
    nextCommand();
    updateGUI();
    //println(commandList);
    //println("command list length: " + commandList.size());
  }

  void pickScanDest() {
    Hexagon h;
    Object[] keys = hexgrid.allHexes.keySet().toArray();
    do {
      Object randHexKey = keys[new Random().nextInt(keys.length)];
      h = hexgrid.getHex((PVector)randHexKey);
    } while (!h.inBounds && h!= scanDest);
    scanDest = h;
  }
  void parseCodingBlocks( byte[] mainQueue, byte[] funcQueue ) {
    boolean function = false;
    int cmdCount = 0;
    int funcCount = 0;
    byte tempByte;

    byteList.clear();

    while (cmdCount < 5) {
      if (!function) {
        tempByte = mainQueue[cmdCount];
        if (tempByte == 113) { //"function"
          //println("Function");
          function = true;
        } else if (isValid(tempByte, function)) {
          byteList.add(tempByte);
        }
        if (!function) {
          cmdCount++;
        }
      }
      if (function) {
        while (funcCount < 5) {
          tempByte = funcQueue[funcCount];
          if (isValid(tempByte, function)) {
            { //ignore recursive functions and invalid commands
              byteList.add(tempByte);
            }
          }
          funcCount++;
        }
        function = false;
        funcCount = 0;
        cmdCount++;
      }
    }
  }
  void initClearCommandList() {
    for (RoverCommand rc : commandList) {
      rc.h.fillin = false;
    }
  }
  void parseCommandList(boolean execute) { //freezes when rover is not in eligible hex
    initClearCommandList();
    commandList.clear();
    //println(byteList);
    //if (rover.watchdog <= 5) {
    if (true) {
      PVector lastXY = rover.location;
      int cardinalHeading = roundHeading(rover.heading);
      //Hexagon hexLoc = hexgrid.pixelToHex((int)lastXY.x, (int)lastXY.y);
      PVector hexKey =hexgrid.pixelToKey(lastXY);
      for (byte cmd : byteList) {
        PVector lastKey = hexKey.copy();
        String iconName = "";
        boolean drive = false;
        boolean scan = false;
        boolean execute_ = execute;
        if (cmd == 119) { // 'w' forward
          drive = true;
          iconName = "forward.jpg";
        } else if (cmd == 97) { // 'a' counterclockwise
          drive = false;
          iconName = "counterclockwise.jpg";
          cardinalHeading -= 1;
        } else if (cmd == 115) { // 's' back
          iconName = "uturn.jpg";
          drive = false;
          cardinalHeading += 3;
        } else if (cmd == 100) { // 'd' right/clockwise
          iconName = "clockwise.jpg";
          drive = false;
          cardinalHeading += 1;
        } else if (cmd==101) { // 'e' scan for life
          iconName = "scan.jpg";
          drive = false;
          scan = true;
        }
        while (cardinalHeading < 0 || cardinalHeading >= 6) {
          if (cardinalHeading < 0) {
            cardinalHeading += 6;
          }
          if (cardinalHeading >=6) {
            cardinalHeading -= 6;
          }
        }
        if (drive) {

          hexKey.add(hexgrid.neighbors[cardinalHeading]);
        }
        if (hexgrid.checkHex(hexKey)) {
          Hexagon h = hexgrid.getHex(hexKey);
          RoverCommand rc = new RoverCommand(h, cardinalHeading, drive, scan, iconName, execute_);
          commandList.add(rc);
          //println("new command added " + execute_);
        }
        //Hexagon h_, int cardinalDir_, boolean drive_, boolean scan_, String iconName

        //}
      }
    }
  }
  int roundHeading(float heading_) {
    int cHeading = 0;
    if (degrees(heading_) > 330 || degrees(heading_) <= 30 ) { //refactor this into radians probably
      cHeading = 0;
    } else if (degrees(heading_) >  30 && degrees(heading_) <= 90 ) {
      cHeading = 1;
    } else if (degrees(heading_) >  90 && degrees(heading_) <= 150) {
      cHeading = 2;
    } else if (degrees(heading_) > 150 && degrees(heading_) <= 210) {
      cHeading = 3;
    } else if (degrees(heading_) > 210 && degrees(heading_) <= 270) {
      cHeading = 4;
    } else if (degrees(heading_) > 270 && degrees(heading_) <= 330) {
      cHeading = 5;
    }
    return (int) cHeading;
  }

  void updateGUI() {
    GUI.beginDraw();
    GUI.background(0, 255, 255);
    GUI.pushMatrix();
    GUI.translate(50, GUI.height*.5);
    GUI.imageMode(CENTER);
    for (RoverCommand rc : commandList) {
      PImage icon = rc.getIcon();
      GUI.image(icon, 0, 0, 50, 50);
      GUI.translate(75, 0);
    }
    GUI.popMatrix();
    GUI.endDraw();
  }

  void drawHexes(PGraphics buffer) {
    buffer.beginDraw();
    for (RoverCommand rc : commandList) {
      if (rc.execute) {
        Hexagon h = rc.getHex();
        h.drawHexFill(buffer);
      }
    }
    scanDest.blinkHex(buffer);
    buffer.endDraw();
  }

  float cardDirToRadians(int cardD) {
    float[] cardHtoTheta = {0, 60, 120, 180, 240, 300};
    while (cardD < 0 || cardD >= 6) {
      if (cardD < 0) {
        cardD += 6;
      }
      if (cardD >= 6) {
        cardD -= 6;
      }
    }
    return cardHtoTheta[cardD];
  }

  boolean checkNext() {
    if (commandList.isEmpty()) {
      myPort.write('g');
      println("empty");
      return false;
    } else {
      return true;
    }
  }

  boolean checkNew() {
    if (newCommands) {
      newCommands = false;
      nextCommand();
      return true;
    } else {
      return false;
    }
  }
  boolean isActiveCommand() {
    return(!commandList.isEmpty());
    //check whether there is a command underway
  }

  boolean isExecutableCommand() { //return true if the queue is executable
    if (isActiveCommand()) {
      RoverCommand rc = commandList.get(0);
      if (rc == null) {
        return false;
      } else if (rc.execute) {
        return true;
      }
    }
    return false;
  }
  boolean areAnyCommandsExecutable() {

    for (RoverCommand rc : commandList) {
      if (rc.execute) {
        return true;
      }
    }
    return false;
  }
  float getHeading() {
    if (currentCommand.driveStatus()) {
      if (checkCt < 1) { //only calculate the heading 4x bc the angles get extreme when close to the destination
        //if (true) {
        PVector destination = currentCommand.getXY();
        float dy = destination.y - location.y;
        float dx = destination.x - location.x;
        moveStartLocation.set(location);
        destinationHeading = (atan2(dy, dx)+.5*PI);
        while (destinationHeading < 0 || destinationHeading > TWO_PI) {
          if (destinationHeading < 0) {
            destinationHeading += TWO_PI;
          }
          if (destinationHeading > TWO_PI) {
            destinationHeading -= TWO_PI;
          }
        }
        checkCt++;
      }
    } else if (currentCommand.reorientStatus()) { //if drive portion is complete, check for reorientation turns
      destinationHeading = currentCommand.getRadianDir();
      checkCt = 0;
      moveStartLocation.set(location); //set the destination to the rover's current position
    } else {
      destinationHeading = rover.heading;
    }
    return destinationHeading;
  }

  float compareDistances(PVector roverDest) {
    float distTraveled = abs(PVector.dist(moveStartLocation, location));
    float turnDistToTravel = abs(PVector.dist(moveStartLocation, roverDest));
    float distCompare =turnDistToTravel - distTraveled; //negative number means it has gone too far

    return distCompare;
  }



  void updateLocation(FiducialFound f) {
    roverToCamera=f.getFiducialToCamera();
    DMatrixRMaj rMatrix = f.getFiducialToCamera().getR();
    double[] euler;
    euler = ConvertRotation3D_F64.matrixToEuler(rMatrix, EulerType.XYZ, (double[])null);
    float heading = (float) euler[2]; // - .5*PI;
    while (heading < 0 || heading > TWO_PI) {
      if (heading < 0) {
        heading+= TWO_PI;
      }
      if (heading > TWO_PI) {
        heading -= TWO_PI;
      }
    }
    rover.heading = heading;
    location.set((float)f.getImageLocation().x, (float)f.getImageLocation().y);
    rover.location = location;
    PVector hexID = hexgrid.pixelToKey(location);
    if (hexgrid.checkHex(hexID)) {
      rover.drive();
    }
  }
  PVector getDestination() {
    if (currentCommand.driveStatus()) {
      PVector destination = currentCommand.getXY();
      return destination;
    } else {
      return location;
    }
  }
  double getDistance() {
    //Vector3D_F64 translation = roverToCamera.getT();
    double dist = currentCommand.h.getDist(roverToCamera);
    return dist;
  }

  boolean driveStatus() {
    return currentCommand.driveStatus();
  }
  boolean reorientStatus() {
    return currentCommand.reorientStatus();
  }
  void moveComplete() {
    if (currentCommand.scan) {

      if (cardList.scan(currentCommand.getHex(), scanDest)) {
        pickScanDest();
      }
      commandComplete();
    } else if (currentCommand.moveComplete()) {
      commandComplete();
    }
  }


  void commandComplete() {
    checkCt = 0;
    println("command complete");
    if (!commandList.isEmpty()) {
      commandList.remove(0);
      println("removing last command");
    }
    nextCommand();
  }
  void nextCommand() {
    if (!commandList.isEmpty()) {
      currentCommand = commandList.get(0);
      //println("setting next command");
      if (isExecutableCommand()) {
        myPort.write('r');
        //println("button red");
      }
    } else {
      myPort.write('g');
      //println("button green");
      currentCommand = null;
      //println("cc null");
    }
  }

  boolean isValid(byte tempByte, boolean function) {

    if (tempByte == 119) {    // 'w' forward
      return true;
    } else if (tempByte ==97) { // 'a' counterclockwise
      return true;
    } else if (tempByte == 115) { // 's' back
      return true;
    } else if (tempByte == 100) { // 'd' right/clockwise
      return true;
    } else if (tempByte == 101) { // 'e' scan for life
      return true;
    } else if (tempByte == 32) { // ' ' for stop
      //rover.stop();
      return false;
    } else if (!function && tempByte ==  113) {// 'q' queue function ignores recursive functions
      return true;
    } else {
      return false;
    }
  }
}
