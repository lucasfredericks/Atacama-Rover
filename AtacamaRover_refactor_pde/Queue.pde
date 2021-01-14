import processing.serial.*; //<>//
import java.util.Iterator;


class Queue {

  PApplet sketch;
  Rover rover;
  Serial myPort;
  boolean newCommands;

  ArrayList<Byte> commandArray;
  ArrayList<Hexagon> hexDestList;
  float[] cardHtoTheta = {0, 60, 120, 180, 240, 300};

  Queue(PApplet sketch_, Rover rover_, String serial) {
    commandArray = new ArrayList<Byte>();
    hexDestList = new ArrayList<Hexagon>();
    newCommands = false;

    rover = rover_;
    sketch = sketch_;
    myPort = new Serial(sketch, serial, 115200);
  }
  void update() {
    if ( myPort.available() > 0) { // If data is available,
      byte[] mainQueue = new byte[5];
      byte[] funcQueue = new byte[5];
      byte[] inBuffer = new byte[12];
      byte interesting = 16; //endByte
      inBuffer = myPort.readBytesUntil(interesting);
      if (inBuffer != null) {
        myPort.readBytes(inBuffer);

        for (int i = 0; i < 5; i++) {
          mainQueue[i] = inBuffer[i];
        }
        for (int i = 0; i < 5; i++) {
          funcQueue[i] = inBuffer[i+6];
        }
        myPort.clear();
        parseCodingBlocks(mainQueue, funcQueue);
        parseCommandList();
        newCommands = true;
      }
    }
  }
  void parseCodingBlocks( byte[] mainQueue, byte[] funcQueue ) {
    boolean function = false;
    int cmdCount = 0;
    int funcCount = 0;
    byte tempByte;

    commandArray.clear();

    while (cmdCount < 5) {
      if (!function) {
        tempByte = mainQueue[cmdCount];
        if (tempByte == 113) //"function"
          function = true;
        else if (isValid(tempByte, function)) {
          commandArray.add(tempByte);
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
              commandArray.add(tempByte);
            }
            funcCount++;
          }
        }
        function = false;
        funcCount = 0;
        cmdCount++;
      }
    }
  }
  void parseCommandList() {

    PVector lastXY = rover.location;
    int cardinalHeading = roundHeading(rover.heading);
    Hexagon hexLoc = hexGrid.pixelToHex((int)lastXY.x, (int)lastXY.y);
    PVector hexKey = new PVector();
    hexKey.set(hexLoc.getKey());
    boolean drive = false;
    hexDestList.clear();
    for (byte cmd : commandArray) {
      if (cmd == 119) { // 'w' forward
        drive = true;
      } else if (cmd == 97) { // 'a' counterclockwise
        drive = false;
        cardinalHeading -= 1;
      } else if (cmd == 115) { // 's' back
        drive = true;
        cardinalHeading += 3;
      } else if (cmd == 100) { // 'd' right/clockwise
        drive = true;
        cardinalHeading += 1;
      }

      while (cardinalHeading < 0 || cardinalHeading >= 6) {
        if (cardinalHeading<0) {
          cardinalHeading +=6;
        }
        if (cardinalHeading >= 6) {
          cardinalHeading-=6;
        }
      }
      hexKey.add(hexGrid.neighbors[cardinalHeading]);
      Hexagon h = hexGrid.getHex(hexKey);
      if (drive) {
        hexDestList.add(h);
        drive = false;
        //} else {
        //  //println("drive");
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
  boolean checkNext() {
    if (hexDestList.isEmpty()) {
      //println("empty");
      return false;
    } else {
      return true;
    }
  }

  void turnComplete() {
    if (!hexDestList.isEmpty()) {
      hexDestList.remove(0);
    }
  }

  boolean checkNew() {
    if (newCommands) {
      newCommands = false;
      return true;
    } else {
      return false;
    }
  }

  Hexagon getNext() {
    Hexagon destination = hexDestList.get(0);
    return destination;
  }

  void complete() {
    if (!hexDestList.isEmpty()) {
      commandArray.remove(0);
    }
  }

  boolean isValid(byte tempByte, boolean function) {

    if (tempByte == 119) {        // 'w' forward
      return true;
    } else if (tempByte ==97) {   // 'a' counterclockwise
      return true;
    } else if (tempByte == 115) { // 's' back
      return true;
    } else if (tempByte == 100) { // 'd' right/clockwise
      return true;
    } else if (tempByte == 101) { // 'e' scan for life
      return true;
    } else if (!function && tempByte ==  113) {// 'q' queue function
      return true;
    } else {
      return false;
    }
  }
}
