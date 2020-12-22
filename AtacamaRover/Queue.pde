import processing.serial.*; //<>//
import java.util.Iterator;


class Queue {

  PApplet sketch;
  Rover rover;
  Serial myPort;
  boolean newCommands;

  ArrayList<Byte> commandArray;

  Queue(PApplet sketch_, Rover rover_, String serial) {
    commandArray = new ArrayList<Byte>();
    newCommands = false;

    rover = rover_;
    sketch = sketch_;
    myPort = new Serial(sketch, serial, 115200);
  }
  void update() {
    if ( myPort.available() > 0) {  // If data is available,
      byte[] mainQueue = new byte[5];
      byte[] funcQueue = new byte[5];
      byte[] inBuffer = new byte[12];
      byte interesting = 16;
      inBuffer = myPort.readBytesUntil(interesting);
      if (inBuffer != null) {
        myPort.readBytes(inBuffer);
        if (inBuffer != null) {
          for (int i = 0; i < 5; i++) {
            mainQueue[i] = inBuffer[i];
          }
          for (int i = 0; i < 5; i++) {
            funcQueue[i] = inBuffer[i+6];
          }
          myPort.clear();
          parse(mainQueue, funcQueue);
          newCommands = true;
        }
      }
    }
  }
  void parse( byte[] mainQueue, byte[] funcQueue ) {
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

  boolean checkNext() {
    if (commandArray.isEmpty()) {
      return false;
    } else {
      return true;
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

  byte getNext() {
    byte tempByte;
    tempByte = commandArray.get(0); 
    return tempByte;
  }

  void complete() {
    if (!commandArray.isEmpty()) {
      commandArray.remove(0);
    }
  }

  boolean isValid(byte tempByte, boolean function) {

    if (tempByte == 102) {  // 'f' forward
      return true;
    } else if (tempByte == 98) { // 'b' back
      return true;
    } else if (tempByte == 114) { // 'r' right/clockwise
      return true;
    } else if (tempByte == 108) { // 'l' counterclockwise
      return true;
    } else if (tempByte == 115) { // 's' search
      return true;
    } else if (!function && tempByte ==  113) { // 'q' queue function
      return true;
    } else {
      return false;
    }
  }
  /*     The blocks use absolute directions, but steering is relative
   //      The arduino converts to relative commands and sends ascii characters 
   //      for (f)orward, (b)ack, (l)eft, (r)ight, (q)ueue function, (s)earch,
   //      and (e)rror
   */
}
