import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import boofcv.processing.*; 
import processing.video.*; 
import java.util.*; 
import org.ejml.*; 
import java.io.*; 
import boofcv.struct.calib.*; 
import boofcv.io.calibration.CalibrationIO; 
import processing.serial.*; 
import java.util.Iterator; 

import org.ejml.*; 
import org.ejml.interfaces.*; 
import org.ejml.interfaces.decomposition.*; 
import org.ejml.interfaces.linsol.*; 
import org.ejml.sparse.*; 
import org.ejml.ops.*; 
import org.ejml.concurrency.*; 
import org.ejml.data.*; 
import pabeles.concurrency.*; 
import georegression.misc.*; 
import georegression.misc.test.*; 
import georegression.*; 
import georegression.transform.*; 
import georegression.transform.twist.*; 
import georegression.transform.affine.*; 
import georegression.transform.homography.*; 
import georegression.transform.se.*; 
import georegression.geometry.*; 
import georegression.geometry.algs.*; 
import georegression.struct.curve.*; 
import georegression.struct.*; 
import georegression.struct.point.*; 
import georegression.struct.line.*; 
import georegression.struct.so.*; 
import georegression.struct.affine.*; 
import georegression.struct.trig.*; 
import georegression.struct.homography.*; 
import georegression.struct.se.*; 
import georegression.struct.shapes.*; 
import georegression.struct.plane.*; 
import georegression.metric.*; 
import georegression.metric.alg.*; 
import georegression.fitting.cylinder.*; 
import georegression.fitting.line.*; 
import georegression.fitting.*; 
import georegression.fitting.curves.*; 
import georegression.fitting.affine.*; 
import georegression.fitting.sphere.*; 
import georegression.fitting.homography.*; 
import georegression.fitting.se.*; 
import georegression.fitting.plane.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class AtacamaRover extends PApplet {








Arena arena;
int arenaCorners = 5;

Capture cam;
SimpleFiducial detector;


Rover rover1;
int rover1ID = 6; // the fiducial binary identifier for rover 1

HexGrid hexGrid;
int hexSize = 100;

int bg = color(0, 0, 0, 0);
int hover = color(255);



public void setup() {
  frameRate(30);
  String[] cameras = Capture.list();
  println(Capture.list());
  cam = new Capture(this, 1280, 720, cameras[0]);
  cam.start();

  surface.setSize(cam.width, cam.height);
  //frameRate(30);

  Serial[] myPorts = new Serial[4];  // Create a list of objects from Serial class
  int[] dataIn = new int[4];         // a list to hold data from the serial ports

  //Serial port identifiers
  int readerPort1 = 1;
  int roverPort1 = 0;
  String reader1portName = Serial.list()[readerPort1];
  String rover1portName = Serial.list()[roverPort1];
  detector = Boof.fiducialSquareBinaryRobust(0.1f);
  //String filePath = ("D:\\Documents\\GitHub\\Atacama-Rover\\AtacamaRover\\data");
  //String filePath = ("C:\\Users\\lfredericks\\Documents\\GitHub\\Atacama-Rover\\AtacamaRover\\data");
  String filePath = ("C:\\Users\\Lucas\\Documents\\GitHub\\Atacama-Rover\\AtacamaRover\\data");
  CameraPinholeBrown intrinsic = CalibrationIO.load(new File(filePath, "intrinsic.yaml"));
  detector.setIntrinsic(intrinsic);
  //detector.guessCrappyIntrinsic(cam.width, cam.height);
  arena = new Arena();

  hexGrid = new HexGrid(hexSize);


  rover1 = new Rover(hexGrid, this, rover1portName, reader1portName);
}

public void draw() {

  //println(frameRate);
  if (frameCount%120==0) {
   // println(frameRate);
  }
  if (cam.available() == true) {
    cam.read();


    List<FiducialFound> found = detector.detect(cam);
    for ( FiducialFound f : found ) {

      //println(f.getImageLocation());

      //  println("ID             "+f.getId());
      //  println("image location "+f.getImageLocation());
      //  println("world location "+f.getFiducialToCamera().getT());

      int xpos = (int) f.getImageLocation().x;
      int ypos = (int) f.getImageLocation().y;
      //println(f.getFiducialToCamera().getR());
      int ident = (int) f.getId() - 1;
      if (ident >= 0 && ident < arenaCorners) {
        hexGrid.setCorners(ident, xpos, ypos);
      } else if (ident == rover1ID-1) {
        rover1.updateLocation(f);
        //detector.render(this, f);
      }

      //detector.render(this, f);
    }

    image(cam, 0, 0);
    //arena.drawCorners();
    hexGrid.update();

    rover1.run();
    //rover1.debug();


    hexGrid.display();
    fill(0, 255, 0);
    ellipse(rover1.pixelLocation.x, rover1.pixelLocation.y, 10, 10);

    fill(255, 0, 0);
    ellipse(constrain(rover1.pixelDest.x, 0, width), constrain(rover1.pixelDest.y, 0, height), 20, 20);
  }
}


//Hexagon axial_to_cube(Hexagon h){
//  int x = h.hexQ;
//  int z = h.hexR;
//  int y = -x-z;

//}
class Arena { //<>//
  PVector[] corners;
  PGraphics arenaMask;

  Arena() {
    corners = new PVector[arenaCorners];
    for (int i = 0; i < arenaCorners; i++) {
      corners[i] = new PVector(0, 0);
    }
    arenaMask = createGraphics(width, height);
  }
  public void setCorners(int ident, int x, int y) {
    corners[ident].set(x, y);
  }

  public void drawCorners() {
    stroke(255, 0, 0);
    strokeWeight(8);
    for (int i = 0; i < arenaCorners; i++) {
      int xpos = (int) corners[i].x;
      int ypos = (int) corners[i].y;
      point(xpos, ypos);
    }
  }

  public void drawMask() {
    arenaMask.beginDraw();
    arenaMask.fill(0);
    arenaMask.stroke(0);
    arenaMask.strokeWeight(1);
    arenaMask.background(255);
    arenaMask.beginShape();
    PVector startPoint = new PVector(0, 0);
    for (int i = 0; i < arenaCorners; i++) {
      int x = (int) corners[i].x;
      int y = (int) corners[i].y;
      if (i == 0) {
        startPoint.x = x;
        startPoint.y = y;
      }
      arenaMask.vertex(x, y);
    }
    arenaMask.vertex(startPoint.x, startPoint.y);
    arenaMask.endShape();
    arenaMask.endDraw();
  }

  public void drawEdges() {
    noFill();
    beginShape();
    PVector startPoint = new PVector(0, 0);
    for (int i = 0; i < 5; i++) {
      int x = (int) corners[i].x;
      int y = (int) corners[i].y;
      if (i == 0) {
        startPoint.x = x;
        startPoint.y = y;
      }
      vertex(x, y);
    }
    vertex(startPoint.x, startPoint.y);
    endShape();
  }

  public void interpolateHexes() {
    PVector cornerA = new PVector();
    PVector cornerB = new PVector();
    for (int i = 0; i < arenaCorners; i++) {
      cornerA = (corners[i].copy());
      if (i == arenaCorners-1) {
        cornerB = (corners[0].copy());
      } else {
        cornerB = (corners[i+1].copy());
      }
      float d = PVector.dist(cornerA, cornerB);
      int n = PApplet.parseInt(d/hexSize);
      for (int j = 0; j <= n; j++) {
        PVector middle = new PVector();
        middle = PVector.lerp(cornerA, cornerB, 1/d*hexSize*j);
        //point(middle.x, middle.y);
        int x = (int) middle.x;
        int y = (int) middle.y;
        Hexagon h = hexGrid.pixelToHex(x, y);
        if (h != null) {
          h.setState(false);
        }
      }

      //get start vector
      //get end vector
      //find distance
      //find the hex distance between the two points
      //evenly sample n + 1 points between point A and point B each point will be A + (B-A) * 1.0/N * i
      //pixelToHex
      //mark hex OOB
    }
  }
}
class Corner {
  int ident;
  int x;
  int y;

  
  Corner(int ident_){
    ident = ident_;
    x = 0;
    y = 0;
  }
  public void setPosition(int x_, int y_){
    x = x_;
    y = y_;
  }
  
}
class Hexagon { //<>//
  float size;
  int pixelX, pixelY;
  int hexQ, hexR; //q for "column" = x axis, r for "row" = z axis
  boolean inBounds;
  boolean changed;
  PVector id;
  boolean occupied = false;
  Rover occupant;

  Hexagon(int hexQ_, int hexR_, int size_) {
    hexQ = hexQ_;
    hexR = hexR_;
    int hexX = hexQ;
    int hexZ = hexR;
    int hexY = -hexX - hexZ;

    size = size_;
    PVector pixelxy = new PVector();
    pixelxy = hexToPixel(hexQ, hexR);
    pixelX = PApplet.parseInt(pixelxy.x);
    pixelY = PApplet.parseInt(pixelxy.y);
    id = new PVector(hexX, hexY, hexZ);
    inBounds = true;
    changed = true;
  }

  public PVector getID() {
    return(id);
  }

  public void drawHex() {
    //if (inBounds) {
    pushMatrix();
    translate(pixelX, pixelY);
    if (this.occupied) {
      fill(255,100);
    } else {
      noFill();
    }
    strokeWeight(1);
    stroke(255);
    beginShape();
    for (int i = 0; i <= 360; i +=60) {
      float theta = radians(i);
      float cornerX = size * cos(theta);
      float cornerY = size * sin(theta);
      vertex(cornerX, cornerY);
    }
    endShape();

    //      strokeWeight(2);
    //      stroke(0);
    //      fill(0);
    //      String ID = ("(" + hexQ + ", " + hexY + ", " + hexR + ")");
    //      textSize(8);
    //      textAlign(CENTER, CENTER);
    //      text(ID, 0, 0);
    popMatrix();
    //}
  }

  public void setState(boolean on) {
    inBounds = on;
    changed = true;
  }

  public void occupy(Rover rover) {
    occupied = true;
    occupant = rover;
  }
  public void vacate() {
    occupied = false; 
    occupant = null;
  }

  public boolean checkMask() {
    boolean mask; // true means the hex will be inbounds
    if (pixelY <= 0 || pixelY >= height || pixelX <= 0 || pixelX >= width) {
      mask = false;
    } else {
      int val = arena.arenaMask.get(pixelX, pixelY);
      if (val != -1) {
        mask = true;
      } else {
        mask = false;
      }
    }
    //return(mask);
    return(true);
  }

  public void updateHashMaps() {
    if (changed) {
      if (inBounds && !hexGrid.activeHexes.containsKey(id)) { //if newly in bounds, add to activeHexes hashmap
        hexGrid.activeHexes.put(id, this);
      } else if (!inBounds && hexGrid.activeHexes.containsKey(id)) //if newly oob, remove from activeHexes hashmap
      { 
        hexGrid.activeHexes.remove(id);
      }
    }
    changed = false;
  }

  public PVector hexToPixel(int q, int r) {
    PVector temp = new PVector(0, 0);
    temp.x = hexSize * (3.f/2 * q);
    temp.y = hexSize * (sqrt(3)/2 * q + sqrt(3) * r);
    return(temp);
  }
}
/* //<>// //<>// //<>//
Hex grid calculations are based on the excellent interactive Hexagonal Grids guide
 from Amit Patel at Red Blob Games (https://www.redblobgames.com/grids/hexagons)

 There is also an implementation guide, which I did not see until I had done a lot of things the ugly way.
 If there is time, I will refactor this class into something resembling their much more elegant version.
 https://www.redblobgames.com/grids/hexagons/implementation.html
 */
class HexGrid {
  HashMap<PVector, Hexagon> activeHexes;
  HashMap<PVector, Hexagon> allHexes;
  Arena arena;
  PVector[] neighbors;
  int qMin = -1; //the q axis corresponds to the x axis on the screen. Higher values are further right
  int qMax = 30;
  int rMin = -13; //the r axis is 30 degrees counterclockwise to the q/x axis. Higher values are down and to the left
  int rMax = 13;
  int hexSize;
  Hexagon r1Hex;



  HexGrid(int hexSize_) {

    arena = new Arena();

    neighbors = new PVector[6];  //pre-compute the 3D transformations to return adjacent hexes in 2D grid
    neighbors[0] = new PVector(0, 1, -1); // N
    neighbors[1] = new PVector(1, 0, -1); // NE
    neighbors[2] = new PVector(1, -1, 0); // SE
    neighbors[3] = new PVector(0, -1, 1); // S
    neighbors[4] = new PVector(-1, 0, 1); // SW
    neighbors[5] = new PVector(-1, 1, 0); // NW

    hexSize = hexSize_;

    allHexes = new HashMap<PVector, Hexagon>();
    activeHexes = new HashMap<PVector, Hexagon>();
    for (int q = qMin; q <= qMax; q++) {
      for (int r = rMin; r <= rMax; r++) {
        int y = -q - r;
        PVector loc = (hexToPixel(q, r));
        if (loc.x > -hexSize && loc.x < width+hexSize && loc.y > 0-hexSize && loc.y < height+hexSize) {
          PVector hexID = new PVector(q, y, r);
          Hexagon h = new Hexagon(q, r, hexSize);
          allHexes.put(hexID, h);
        }
      }
    }
  }

  public void update() {
    //arena.drawEdges();
    //arena.drawMask();
    //arena.arenaMask.loadPixels();
    for (Map.Entry<PVector, Hexagon> me : allHexes.entrySet()) {
      Hexagon h = me.getValue();
      //boolean status = h.checkMask();
      //boolean status = true; //debug
      h.setState(true);
    }
    //arena.interpolateHexes(); // find the hexes that lie along the lines between arena corners and mark them out of bounds
    for (Map.Entry<PVector, Hexagon> me : allHexes.entrySet()) {
      Hexagon h = me.getValue();
      h.updateHashMaps();
    }
  }

  public void display() {
    for (Map.Entry<PVector, Hexagon> me : activeHexes.entrySet()) {
      Hexagon h = me.getValue();
      if (h.inBounds) {
        h.drawHex();
      }
    }
  }

  public void setCorners(int ident, int x, int y) {
    arena.setCorners(ident, x, y);
  }

  public void occupyHex(Rover rover, Hexagon newHex, Hexagon lastHex) {

    newHex.occupy(rover);
    if (lastHex != null) {
      lastHex.vacate();
    }
  }

  public Hexagon getHex(PVector hexKey) { //hashmap lookup to return hexagon from PVector key
    Hexagon h = allHexes.get(hexKey);
    return(h);
  }

  public Hexagon getHex(Point2D_F64 hexKey_) { //hashmap lookup to return hexagon from PVector key
    PVector hexKey = new PVector((float)hexKey_.x, (float)hexKey_.y);
    Hexagon h = allHexes.get(hexKey);
    return(h);
  }

  public Hexagon pixelToHex(int xPixel, int yPixel) { //find which hex a specified pixel lies in
    PVector hexID = new PVector();
    hexID.x = (2.f/3*xPixel)/hexSize;
    hexID.z = (-1.f/3 * xPixel + sqrt(3)/3 * yPixel)/hexSize;
    hexID.y = (-hexID.x - hexID.z);
    hexID = cubeRound(hexID);
    Hexagon h = allHexes.get(hexID);
    return h;
  }

  public Hexagon[] getNeighbors(Hexagon h) { //return an array of the 6 neighbor cells. If the neighbor is out of bounds, its array location will be null
    Hexagon[] neighborList = new Hexagon[6];
    PVector hexID = h.getID();
    for (int i = 0; i < 6; i++) {
      PVector neighborID = hexID.copy();
      neighborID = neighborID.add(neighbors[i]);
      Hexagon neighbor = getHex(neighborID);
      if (neighbor == null) {
        neighborList[i] = null;
      } else {
        neighborList[i] = neighbor;
      }
    }
    return(neighborList);
  }

  public Hexagon[] getNeighbors(PVector hexID) { //overloaded method to accept a pvector key instead of a Hexagon object
    Hexagon[] neighborList = new Hexagon[6];
    for (int i = 0; i < 6; i++) {
      PVector neighborID = hexID.copy();
      neighborID = neighborID.add(neighbors[i]);
      Hexagon neighbor = getHex(neighborID);
      if (neighbor == null) {
        neighborList[i] = null;
      } else {
        neighborList[i] = neighbor;
      }
    }
    return(neighborList);
  }

  public PVector hexToPixel(int q, int r) {
    PVector temp = new PVector(0, 0);
    temp.x = hexSize * (3.f/2 * q);
    temp.y = hexSize * (sqrt(3)/2 * q + sqrt(3) * r);
    return(temp);
  }

  public PVector cubeRound(PVector hexID) {
    int rx = round(hexID.x);
    int ry = round(hexID.y);
    int rz = round(hexID.z);

    float xdiff = abs(rx - hexID.x);
    float ydiff = abs(ry - hexID.y);
    float zdiff = abs(rz - hexID.z);

    if (xdiff > ydiff && xdiff > zdiff) {
      rx = -ry-rz;
    } else if (ydiff > zdiff) {
      ry = -rx-rz;
    } else {
      rz = -rx-ry;
    }
    PVector rHexID = new PVector(rx, ry, rz);
    return(rHexID);
  }
}
 //<>//



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
  public void update() {
    if ( myPort.available() > 0) {  // If data is available,
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
        parse(mainQueue, funcQueue);
        newCommands = true;
      }
    }
  }
  public void parse( byte[] mainQueue, byte[] funcQueue ) {
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

  public boolean checkNext() {
    if (commandArray.isEmpty()) {
      return false;
    } else {
      return true;
    }
  }

  public boolean checkNew() {
    if (newCommands) {
      newCommands = false;
      return true;
    } else {
      return false;
    }
  }

  public byte getNext() {
    byte tempByte;
    tempByte = commandArray.get(0); 
    return tempByte;
  }

  public void complete() {
    if (!commandArray.isEmpty()) {
      commandArray.remove(0);
    }
  }

  public boolean isValid(byte tempByte, boolean function) {

    if (tempByte == 119) {  // 'w' forward
      return true;
    } else if (tempByte == 115) { // 's' back
      return true;
    } else if (tempByte == 100) { // 'd' right/clockwise
      return true;
    } else if (tempByte ==97) { // 'a' counterclockwise
      return true;
    } else if (tempByte == 101) { // 'e' scan for life
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
class Rover { //<>// //<>// //<>// //<>//
  Serial myPort;
  PApplet sketch;
  HexGrid hexGrid;
  Queue queue;
  DMatrixRMaj rMatrix;
  PVector pixelLocation;
  double[] euler;
  float heading = 0;
  float targetHeading = 0;
  PVector pixelDest;
  PVector startLoc;
  boolean inBounds;
  Hexagon hexLoc;
  Hexagon lastHex;
  Hexagon hexDest;
  int cardinalHeading;
  int turnMOE = 10; // margin of error for turning in degrees
  String command;
  String lastCommand;
  long nudgeTimer;
  int nudgeTimeout = 100;

  int watchDog = 0;


  int checkCt;

  //status variables
  boolean driving, turning, ready, reverse;

  Rover(HexGrid hexGrid_, PApplet sketch_, String serial, String queueSerial) {
    sketch = sketch_;
    hexGrid = hexGrid_;
    rMatrix = new DMatrixRMaj();
    pixelLocation = new PVector();
    euler = new double[2];
    myPort = new Serial(sketch, serial, 9600);
    pixelDest = new PVector();
    startLoc = new PVector();
    queue = new Queue(sketch, this, queueSerial);
  }

  public void resetVars() {
    command = "stop";
    turning = false;
    driving = false;
    ready = true;
    checkCt = 0;
  }

  public void run() {

    queue.update();
    if (queue.checkNew()) { //if the user has pressed the button, stop the current command
      resetVars();
    }
    if (watchDog > 5) {
      command = "stop";
      println("watchdog");
    } else {
      if (ready) {
        if (turning) {
          turn();
        } else if (driving) {
          drive();
        } else if (queue.checkNext()) {
          byte command_ = queue.getNext();
          parseCommand(command_);
          ready = true;
        }
      }
    }
    if (command!=lastCommand) {
      sendCommand();
    }
    watchDog++;
    displayHeading();
  }

  public void updateLocation(FiducialFound f) {
    watchDog = 0;
    rMatrix.set(f.getFiducialToCamera().getR());
    //detector.render(sketch, f);
    euler = ConvertRotation3D_F64.matrixToEuler(rMatrix, EulerType.XYZ, (double[])null);
    heading = (float) euler[2];  // - .5*PI;
    while (heading < 0 || heading > TWO_PI) {
      if (heading < 0) {
        heading+= TWO_PI;
      }
      if (heading > TWO_PI) {
        heading -= TWO_PI;
      }
    }
    if (degrees(heading) > 330 || degrees(heading) <= 30 ) { //refactor this into radians probably 
      cardinalHeading = 0;
    } else if (degrees(heading) >  30 && degrees(heading) <= 90 ) {
      cardinalHeading = 1;
    } else if (degrees(heading) >  90 && degrees(heading) <= 150) {
      cardinalHeading = 2;
    } else if (degrees(heading) > 150 && degrees(heading) <= 210) {
      cardinalHeading = 3;
    } else if (degrees(heading) > 210 && degrees(heading) <= 270) {
      cardinalHeading = 4;
    } else if (degrees(heading) > 270 && degrees(heading) <= 330) {
      cardinalHeading = 5;
    }

    pixelLocation.set((float)f.getImageLocation().x, (float)f.getImageLocation().y);   
    hexLoc = hexGrid.pixelToHex((int)pixelLocation.x, (int)pixelLocation.y);
    if (lastHex != hexLoc) {
      hexGrid.occupyHex(this, hexLoc, lastHex);
      lastHex = hexLoc;
    }

    checkProgress();
  }
  public void nudge() {
    float ldelta;
    float rdelta;
    //if (!reverse) { 
    ldelta = heading - targetHeading;
    rdelta = targetHeading - heading;
    //} else {
    //  ldelta = targetHeading - heading; //invert steering when in reverse;
    //  rdelta = heading - targetHeading;
    //}
    if (millis() - nudgeTimer > nudgeTimeout) {
      nudgeTimer = millis();

      if (ldelta < 0) {
        ldelta += TWO_PI;
      }
      if (rdelta < 0) {
        rdelta += TWO_PI;
      }
      if (ldelta < rdelta) {
        command = "nleft";
      } else if (rdelta > ldelta) {
        command = "nright";
      }
      checkCt++; //<>//
      println(checkCt);
    }
  }

  public void turn() {
    float ldelta;
    float rdelta;
    //if (!reverse) { 
    ldelta = heading - targetHeading;
    rdelta = targetHeading - heading;
    //} else {
    //  ldelta = targetHeading - heading; //invert steering when in reverse;
    //  rdelta = heading - targetHeading;
    //}

    if (ldelta < 0) {
      ldelta += TWO_PI;
    }
    if (rdelta < 0) {
      rdelta += TWO_PI;
    }
    if (ldelta < rdelta) {
      command = "left";
    } else {
      command = "right";
    }
    ready = false;
  }
  public void checkProgress() {
    float nudgeMOE = radians(5);
    if (turning) {
      float delta = targetHeading - heading;
      //println("delta = " + degrees(delta));
      //if (delta < 0) {
      //  delta += TWO_PI;
      //}
      if (abs(delta) < radians(turnMOE)) {
        command = "stop";
        if (abs(delta) > radians(nudgeMOE) || checkCt <=5) {
          nudge();
        } else {
          turning = false;
          ready = true;
          checkCt = 0;
          if (!driving) {
            resetVars();
            queue.complete();
          }
        }
      }
    } else if (driving) {
      float dist =  PVector.dist(pixelLocation, startLoc);  
      float targetDist = PVector.dist(startLoc, pixelDest);
      //println("dist: " + dist);
      //println("targetDist: " +targetDist);
      if (abs(dist) >= abs(targetDist)-5) {
        command = "stop";
        queue.complete();
        resetVars();
      }
    }
  }

  public void drive() {
    if (reverse) {
      command = "back";
    } else {
      command = "forward";
    }
    ready = false;
  }

  public void parseCommand(byte command_) {
    hexLoc = hexGrid.pixelToHex((int)pixelLocation.x, (int)pixelLocation.y);
    Hexagon[] neighbors = hexGrid.getNeighbors(hexLoc);
    int dest;
    turning = true; // Each command starts with an alignment turn
    // convert relative commands to absolute
    if (command_ == 102) {  // 'f' forward
      dest = cardinalHeading;
      if (checkDestination(neighbors[dest])) {
        driving = true;
        reverse = false;
        setDestination(neighbors[dest]);
      }
    } else if (command_ == 98) { // 'b' back
      dest = cardinalHeading + 3;
      if (dest > 5) {
        dest -= 6;
      }
      if (checkDestination(neighbors[dest])) {
        driving = true;
        reverse = true; // flip turning directions
        //dest = cardinalHeading;
        setDestination(neighbors[dest]);
      }
    } else if (command_ == 114) { // 'r' right/clockwise

      dest = cardinalHeading + 1;
      if (dest > 5) {
        dest -= 6;
      }
      driving = false;
      reverse = false;
      setDestination(neighbors[dest]);
    } else if (command_ == 108) { // 'l' counterclockwise
      dest = cardinalHeading -1;
      if (dest < 0) {
        dest += 6;
      }
      driving = false;
      reverse = false;
      setDestination(neighbors[dest]);
    }
  }

  public boolean checkDestination(Hexagon h) {

    if (h != null && h.inBounds) {
      return true;
    } else {
      resetVars();
      return false;
    }
  }
  public void setDestination(Hexagon h) {
    startLoc.set(pixelLocation.x, pixelLocation.y);
    if (hexGrid.getHex(h.id)!= null) {
      hexDest = hexGrid.getHex(h.id);
      pixelDest.set(hexDest.pixelX, hexDest.pixelY);
      //float dy = pixelLocation.y - pixelDest.y;
      //float dx = pixelLocation.x - pixelDest.x;
      float dy = pixelDest.y - pixelLocation.y;
      float dx = pixelDest.x - pixelLocation.x;
      float a = (atan2(dy, dx)+.5f*PI);
      if (reverse) {
        a += PI;
      }
      while (a < 0 || a > TWO_PI) {
        if (a < 0) {
          a+= TWO_PI;
        }
        if (a > TWO_PI) {
          a -= TWO_PI;
        }
      }
      targetHeading = a;
    } else {
    }
  }


  public void sendCommand() {
    byte commandByte = ' '; //invalid command will default to 'stop'
    if (command == "nright") {
      commandByte = 'd'; //nudge right
    } else if (command == "nleft") {
      commandByte = 'a'; //nudge left
    } else if (command != lastCommand) {

      if (command == "stop") {
        commandByte = ' ';
      } else if (command == "left") {
        commandByte = 'l';
      } else if (command == "right") {
        commandByte = 'r';
      } else if (command == "forward") {
        commandByte = 'f';
      } else if (command == "back") {
        commandByte = 'b';
      }
    }

    println(command);
    myPort.write(commandByte);

    lastCommand = command;
  }

  //void sendCommand(String cmnd) {
  //  byte commandByte = ' '; //invalid command will default to 'stop'
  //  if (command == "stop") {
  //    commandByte = ' ';
  //  } else if (cmnd == "left") {
  //    commandByte = 'l';
  //  } else if (cmnd == "right") {
  //    commandByte = 'r';
  //  } else if (cmnd == "forward") {
  //    commandByte = 'f';
  //  } else if (cmnd == "back") {
  //    commandByte = 'b';
  //  }
  //  lastCommand = cmnd;
  //}


  //void sendCommand(byte command) { //if the command is  a byte, send it to the rover
  //  myPort.write(command);
  //  println(command);
  //}

  public void displayHeading() {
    pushMatrix();
    translate(pixelLocation.x, pixelLocation.y);
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
  //line(pixelLocation.x, pixelLocation.y, dy, dx);
}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "AtacamaRover" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
