import processing.serial.*;  //<>//
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
  AStar pathFinder;
  boolean newCommands;
  float commandTotalDistance = 0;
  int checkCt = 0;
  //PVector location;

  //PVector moveStartLocation;

  //ArrayList<Byte> byteList;
  CommandList commandList;

  //queue = new Queue(sketch, cardList, hexgrid, queuePortName, queueGUI);

  Queue(PApplet sketch_, Hexgrid hexgrid_, String serial, PGraphics GUI_, CommandList commandList_) {
    println("queue init start");
    hexgrid = hexgrid_;
    cardList = new CardList(this);
    newCommands = false;
    sketch = sketch_;
    GUI = GUI_;
    myPort = new Serial(sketch, serial, 115200);
    println("queue Serial init");
    //moveStartLocation = new PVector();
    //location = new PVector(camWidth/2, camHeight/2);
    commandList = commandList_;    
    println("queue init complete");
  }

  boolean isTargetHex(Hexagon h_) {
    if (h_.getKey() == scanDest.getKey()) {
      return true;
    }
    return false;
  }
  boolean isTargetHex(PVector key_) {
    if (key_ == scanDest.getKey()) {
      return true;
    }
    return false;
  }

  void initRover(Rover rover_) {
    rover = rover_;
  }

  void update() {

    cardList.run();

    if (myPort.available() > 0) { // If data is available,

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
        funcQueue[i] = inBuffer[i + 6];
      }
      //println("parsing queue into byte list");
      if (inBuffer[5] == 'n') {//if the user has pressed the button
        println("button pressed");
        if (cardList.showCard) { //if the kiosk is displaying a photo, close the photo and clear the queue
          cardList.stopDisplayingCard();
          execute = false;
          commandList.clearList();
          setButtonColor();
          return;
        }
        newCommands = true;
        if (commandList.isExecutableCommand()) { //if the rover is already moving
          execute = false; //the first button press will cancel current execution.
          commandList.clearList();
          scan();
          return;
        } else {
          execute = true;
          commandList.clearList();
        }
      } else { //if the user has not pressed the button, the arduino will send periodic updates anyway
        newCommands = false;
        if (commandList.isExecutableCommand()) { //if the rover is driving and the user hasn't pressed the button,
          setButtonColor();
          updateGUI();
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

  void scan() {
    Hexagon h = hexgrid.pixelToHex(rover.location);
    if (cardList.scan(h, scanDest)) {
      cardList.lifeFound();
    }
  }

  void returnToArena() {
    commandList.clearList();
    PVector middle = new PVector(camWidth / 2, camHeight / 2);
    PVector tempDest = new PVector();
    PVector tempKey = new PVector();
    int i = 1;
    float dy;
    float dx;
    do {
      dy = lerp(rover.location.y, middle.y, i * .05); //linear interpolation towards center of arena
      dx = lerp(rover.location.x, middle.x, i * .05);
      tempDest.set(dx, dy);
      tempKey = hexgrid.pixelToKey(tempDest);
      i++;
    } while (hexgrid.allHexes.containsKey(tempKey) == false); //lerp until we find an inbounds hex
    //println("return trajectory found");
    float targetHeading = (atan2(tempDest.y, tempDest.x) +.5 * PI);
    targetHeading = hexgrid.normalizeRadians(targetHeading);
    int cardinalHeading = roundHeading(targetHeading);
    commandList.customCommand(tempKey, cardinalHeading);
    pickScanDest(tempKey);
  }


  void pickScanDest() {
    println("picking scan destination");

    scanDest = hexgrid.pickTarget(hexgrid.pixelToHex(rover.location));
    println("pick scan dest complete");
  }

  void pickScanDest(PVector tempKey) {
    if (hexgrid.inBounds(rover.location)) {
      scanDest = hexgrid.pickTarget(hexgrid.getHex(tempKey));
    }
  }


  int roundHeading(float heading_) {
    int cHeading = 0;
    if (degrees(heading_) > 330 || degrees(heading_) <= 30) { //refactor this into radians probably
      cHeading = 0;
    } else if (degrees(heading_) >  30 && degrees(heading_) <= 90) {
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
    return(int) cHeading;
  }

  void updateGUI() {

    int tileSize = 140;
    int margin = 20;
    int radius = 10;
    color fnCol = #cfdb4b;
    GUI.beginDraw();
    //GUI.background(0, 255, 255);
    GUI.clear();
    GUI.pushMatrix();
    GUI.translate(margin+tileSize/2, GUI.height / 2);
    GUI.imageMode(CENTER);
    GUI.rectMode(CENTER);
    GUI.fill(255);
    GUI.strokeWeight(10);

    ArrayList<RoverCommand> commands = commandList.getRCList();
    for (RoverCommand rc : commands) {
      GUI.pushMatrix();
      PImage icon = rc.getIcon();
      if (rc.function) {
        GUI.stroke(fnCol);
      } else {
        GUI.stroke(255);
      }
      GUI.rect(0, 0, tileSize, tileSize, radius);
      //GUI.rotate(rc.radianDir);
      GUI.image(icon, 0, 0, tileSize-margin, tileSize-margin);
      GUI.popMatrix();
      GUI.translate(margin + tileSize, 0);
    }
    GUI.popMatrix();
    GUI.endDraw();
  }

  void drawHexes(PGraphics buffer) {
    buffer.beginDraw();
    commandList.drawHexes(buffer);
    if (scanDest != null) {
      scanDest.blinkHex(buffer);
    }
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

  boolean cardBool() {
    if (cardList.showCard) {
      return true;
    } else {
      return false;
    }
  }

  PImage displayCard() {
    return cardList.displayCard();
  }

  boolean checkQueue() {
    if (commandList.isEmpty() || commandList.isExecutableCommand() == false) {
      return false;
    } else {
      return true;
    }
  }

  boolean checkInBounds() {
    if (commandList.isInBounds() == false) {
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
    //println("command complete");
    commandList.commandComplete(); //deletes current cmd
    //if(commandList.isEmpty()){

    //}
    if (checkQueue()==false) {
      scan();
    }
  }

  void endTurn(boolean inBounds) {
    commandList.clearList();
    if (inBounds == false) {
      cardList.hazard();
      scan();
    }
  }
}
