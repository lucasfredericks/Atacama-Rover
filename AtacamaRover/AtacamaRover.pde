import boofcv.processing.*;
import processing.video.*;
import java.util.*;
import org.ejml.*;

Arena arena;
int arenaCorners = 5;

Capture cam;
SimpleFiducial detector;


Rover rover1;
int rover1ID = 6; // the fiducial binary identifier for rover 1

HexGrid hexGrid;
int hexSize = 120;

color bg = color(0, 0, 0, 0);
color hover = color(255);



void setup() {
  initializeCamera(1920, 1080);
  surface.setSize(cam.width, cam.height);
  fullScreen(1);

  Serial[] myPorts = new Serial[4];  // Create a list of objects from Serial class
  int[] dataIn = new int[4];         // a list to hold data from the serial ports

  //Serial port identifiers
  int readerPort1 = 1;
  int roverPort1 = 2;
  String reader1portName = Serial.list()[readerPort1];
  String rover1portName = Serial.list()[roverPort1];

  detector = Boof.fiducialSquareBinaryRobust(0.1);
  detector.guessCrappyIntrinsic(cam.width, cam.height);
  arena = new Arena();

  hexGrid = new HexGrid(hexSize);


  rover1 = new Rover(hexGrid, this, rover1portName, reader1portName);
}

void draw() {
  background(135);

  //println(frameRate);

  if (cam.available() == true) {
    cam.read();
    image(cam, 0, 0);

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


    //arena.drawCorners();
    hexGrid.update();
    hexGrid.display();

    rover1.run();
    //rover1.debug();
    fill(0, 255, 0);
    ellipse(rover1.pixelLocation.x, rover1.pixelLocation.y, 10, 10);
    
    fill(255, 0, 0);
    ellipse(constrain(rover1.pixelDest.x,0, width), constrain(rover1.pixelDest.y,0,height), 20, 20);
  }
}


//Hexagon axial_to_cube(Hexagon h){
//  int x = h.hexQ;
//  int z = h.hexR;
//  int y = -x-z;

//}



void initializeCamera( int desiredWidth, int desiredHeight ) {
  String[] cameras = Capture.list();

  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    cam = new Capture(this, desiredWidth, desiredHeight);
    cam.start();
  }
}
