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
  float commandTotalDistance = 0;
  int checkCt = 0;
  PVector location;

  PVector moveStartLocation;

  //ArrayList<Byte> byteList;
  CommandList commandList;

  //queue = new Queue(sketch, cardList, hexgrid, queuePortName, queueGUI);

  Queue(PApplet sketch_, CardList cardList_, Hexgrid hexgrid_, String serial, PGraphics GUI_, CommandList commandList_) {
    println("queue init start");
    cardList = cardList_;
    hexgrid = hexgrid_;
    //    byteList = new ArrayList<Byte>();
    newCommands = false;
    sketch = sketch_;
    GUI = GUI_;
    myPort = new Serial(sketch, serial, 115200);
    println("queue Serial init");
    moveStartLocation = new PVector();
    Object[] keys = hexgrid.allHexes.keySet().toArray();
    Object randHexKey = keys[new Random().nextInt(keys.length)];
    scanDest = hexgrid.getHex((PVector)randHexKey);
    location = new PVector(camWidth/2, camHeight/2);
    commandList = commandList_;    
    println("queue init complete");
  }

  void initRover(Rover rover_) {
    rover = rover_;
  }

  void update() {

    if ( myPort.available() > 0) { // If data is available,

      byte[] inBuffer = new byte[12];
      byte interesting = 16; //endByte
      inBuffer = myPort.readBytesUntil(interesting);
      myPort.clear();
      //println(inBuffer);
      if (inBuffer == null || inBuffer.length != 12) { //throw out junk
        return;
      } 
      byte[] mainQueue = new byte[5];
      byte[] funcQueue = new byte[5];
      boolean execute;
      for (int i = 0; i < 5; i++) {
        mainQueue[i] = inBuffer[i];
        funcQueue[i] = inBuffer[i+6];
      }
      //println("parsing queue into byte list");
      if (inBuffer[5] == 'n') {//if the user has pressed the button
        println("executable command received");
        newCommands = true;
        if (commandList.isExecutableCommand()) { //if the rover is already moving
          execute = false; //the first button press will cancel current execution.
        } else {
          execute = true;
        }
      } else { //if the user has not pressed the button, the arduino will send periodic updates anyway
        newCommands = false;
        if (commandList.isExecutableCommand()) { //if the rover is driving and the user hasn't pressed the button,
          return;
        } else {
          execute = false;
        }
      }
      int cardinalHeading = roundHeading(rover.heading); //calculate the command list from the rover's starting position and heading
      PVector hexKey = hexgrid.pixelToKey(rover.location);
      commandList.createList(mainQueue, funcQueue, hexKey, cardinalHeading, execute);
    }

    setButtonColor();
    updateGUI();
  }

  void setButtonColor() {
    if (commandList.isExecutableCommand()) {
      myPort.write('r'); //button red
    } else {
      myPort.write('g'); //button green
    }
  }
  
  void scan(){
    Hexagon h = hexgrid.pixelToHex(rover.location);
    if(cardList.scan(h, scanDest)){
      pickScanDest();
    }
    
  }

  void pickScanDest() {
    Hexagon h;
    Object[] keys = hexgrid.allHexes.keySet().toArray();
    do {
      Object randHexKey = keys[new Random().nextInt(keys.length)];
      h = hexgrid.getHex((PVector)randHexKey);
    } while (h!= scanDest);
    scanDest = h;
    println("pick scan dest complete");
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
    //GUI.background(0, 255, 255);
    GUI.clear();
    GUI.pushMatrix();
    GUI.translate(0, GUI.height/2);
    GUI.imageMode(CENTER);
    GUI.rectMode(CENTER);
    GUI.fill(#0098be);
    ArrayList<RoverCommand> commands = commandList.getRCList();
    for (RoverCommand rc : commands) {
      GUI.translate(115, 0);
      GUI.pushMatrix();
      PImage icon = rc.getIcon();
      if (rc.function) {
        GUI.rect(0, 0, 100, 100, 10);
      }
      //GUI.rotate(rc.radianDir);
      GUI.image(icon, 0, 0, 80, 80);
      GUI.popMatrix();
    }
    GUI.popMatrix();
    GUI.endDraw();
  }

  void drawHexes(PGraphics buffer) {
    buffer.beginDraw();
    commandList.drawHexes(buffer);
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

  RoverCommand getCurrentCmd() {
    return commandList.getCurrentCmd();
  }
  

  boolean checkQueue() {
    if (commandList.isEmpty() || commandList.isExecutableCommand() == false) {
      return false;
    } else {
      return true;
    }
  }

  boolean checkInBounds() {
    if (commandList.isEmpty() || commandList.isInBounds() == false) {
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


  void commandComplete() {
    checkCt = 0;
    println("command complete");
    commandList.commandComplete(); //deletes current cmd
  }
  //void nextCommand() {
  //  if (!commandList.isEmpty()) {
  //    currentCommand = commandList.get(0);
  //    //println("setting next command");
  //    if (isExecutableCommand()) {
  //      myPort.write('r');
  //      //println("button red");
  //    }
  //  } else {
  //    myPort.write('g');
  //    //println("button green");
  //    currentCommand = null;
  //    //println("cc null");
  //  }
  //}
}
