class CommandList {
  ArrayList<RoverCommand> commands;
  Hexgrid hexgrid;

  CommandList(Hexgrid hexgrid_) {
    commands = new ArrayList<RoverCommand>();
    hexgrid = hexgrid_;
  }

  ArrayList<BytePlus> parseRawCmds(byte[] mainQueue, byte[] funcQueue) {
    boolean function = false;
    int cmdCount = 0;
    int funcCount = 0;
    byte tempByte;
    ArrayList<BytePlus> byteList = new ArrayList<BytePlus>();
    while (cmdCount < 5) {
      if (!function) {
        tempByte = mainQueue[cmdCount];
        if (tempByte == 113) { //"function"
          //println("Function");
          function = true;
        } else if (isValid(tempByte, function)) {
          BytePlus bp = new BytePlus(tempByte, function);
          byteList.add(bp);
        }
        if (!function) {
          cmdCount++;
          //RoverCommand(Hexgrid hexgrid_, PVector hexKey_, int cardinalDir_, boolean drive_, boolean scan_, byte cmd, boolean execute_) {
        }
      }
      if (function) {
        while (funcCount < 5) {
          tempByte = funcQueue[funcCount];
          if (isValid(tempByte, function)) {
            BytePlus bp = new BytePlus(tempByte, function);
            byteList.add(bp);
          }
          funcCount++;
        }
        function = false;
        funcCount = 0;
        cmdCount++;
      }
    }
    return byteList;
  }

  void createList(byte[] mainQueue, byte[] funcQueue, PVector hexKey, int cardinalHeading, boolean execute) {
    ArrayList<BytePlus> byteList = parseRawCmds(mainQueue, funcQueue);
    commands.clear();
    boolean drive = false;
    clearList();
    for (BytePlus bp : byteList) {
      if (bp.cmd == 119) { // 'w' forward
        drive = true;
      } else if (bp.cmd == 97) { // 'a' counterclockwise
        drive = false;
        cardinalHeading -= 1;
      } else if (bp.cmd == 115) { // 's' back
        drive = false;
        cardinalHeading += 3;
      } else if (bp.cmd == 100) { // 'd' right/clockwise
        drive = false;
        cardinalHeading += 1;
      } else if (bp.cmd==101) { // 'e' scan for life
        drive = false;
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

      RoverCommand rc = new RoverCommand(hexgrid, hexKey, cardinalHeading, bp.cmd, bp.function, execute);
      commands.add(rc);
    }
  }
  void clearList() {
    commands.clear();
  }
  void initClearCommandList() {
    for (RoverCommand rc : commands) {
      rc.fillin = false;
    }
  }
  //for (byte cmd : byteList) {
  //  

  //  //}
  //}
  boolean isActiveCommand() {
    return(!commands.isEmpty());
    //check whether there is a command underway
  }

  boolean isExecutableCommand() { //return true if the queue is executable
    if (isActiveCommand()) {
      RoverCommand rc = commands.get(0);
      if (rc == null) {
        return false;
      } else if (rc.execute) {
        return true;
      }
    }
    return false;
  }

  //boolean areAnyCommandsExecutable() {

  //  for (RoverCommand rc : commands) {
  //    if (rc.execute) {
  //      return true;
  //    }
  //  }
  //  return false;
  //}
  boolean isValid(byte tempByte, boolean function) {

    if (tempByte == 119) {    // 'w' forward
      return true;
    } else if (tempByte ==  97) { // 'a' counterclockwise
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
  boolean isEmpty() {
    if (commands.isEmpty()) {
      return true;
    } else {
      return false;
    }
  }
  class BytePlus { 
    byte cmd;
    boolean function;
    BytePlus(byte cmd_, boolean function_) {
      cmd = cmd_;
      function = function_;
    }
  }
}  
