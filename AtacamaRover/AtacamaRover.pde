import boofcv.processing.*;
import processing.video.*;
import java.util.*;
import org.ejml.*;
import java.io.*;
import boofcv.struct.calib.*;
import boofcv.io.calibration.CalibrationIO;
Hexgrid hexgrid;
Arena arena;
int arenaCorners = 5;
Governor governor1;

CardList cardList;


Capture cam;
SimpleFiducial detector;


int rover1ID = 6; // the fiducial binary identifier for rover 1

int hexSize = 50;
int camWidth = 960;
int camHeight = 720;
int camBufferWidth = 1280;
int camBufferHeight = 960;
float camScale;
color bg = color(0, 0, 0, 0);
color hover = color(255);



void setup() {
  frameRate(30);
  //noSmooth();
  smooth(2);
  //background(0);
  //fullScreen(P3D ,2);
  camScale = float(camBufferWidth)/float(camWidth);
  cardList = new CardList();
  printArray(Capture.list());
  cam = new Capture(this, camWidth, camHeight, "pipeline: ksvideosrc device-index=0 ! video/x-raw,width=960,height=720");
  cam.start();
  
  surface.setSize(1920, 1080); //have to do this manually for detector to work
  fullScreen(2);


  //frameRate(30);

  detector = Boof.fiducialSquareBinaryRobust(0.1);
  String filePath = sketchPath() + "/data";
  CameraPinholeBrown intrinsic = CalibrationIO.load(new File(filePath, "intrinsic.yaml"));
  //detector.setIntrinsic(intrinsic);
  detector.guessCrappyIntrinsic(cam.width, cam.height);
  arena = new Arena();
  hexgrid = new Hexgrid(hexSize);
  int readerPort1 = 1;
  int roverPort1 = 0;
  governor1 = new Governor(this, hexgrid, roverPort1, readerPort1);
}

void draw() {

  //println(frameRate);
  if (frameCount%120==0) {
    println("framerate: " + frameRate);
  }

  if (cam.available() == true) {
    cam.read();
    //governor1.run();
    //canvas.beginDraw();
    //image(cam, 0, 0,camBufferWidth, camBufferHeight);
    //image(governor1.displayHUD(), 0, 0);

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
        arena.setCorners(ident, xpos, ypos);
      } else if (ident == rover1ID-1) {
        governor1.updateRoverLocation(f); //<>//
        //detector.render(this, f);
      }


      //detector.render(this, f);
    }
    governor1.run();
    ////canvas.beginDraw();
    image(cam, 0, 0,camBufferWidth, camBufferHeight);
    image(governor1.displayHUD(), 0, 0);
    //canvas.pushMatrix();
    //canvas.translate(roverLocation.x, roverLocation.y);
    //canvas.fill(0, 255, 0);
    //canvas.ellipse(roverLocation.x, roverLocation.y, 10, 10);
    //canvas.popMatrix();
    //canvas.endDraw();


    //rover marker
    /*
    //display overhead camera
     image(canvas, 0, 0, 1280, 960);
     stroke(255);
     strokeWeight(4);
     noFill();
     rect(0, 0, 1280, 960);
     
     //display card
     noFill();
     pushMatrix()
     translate(1280, 0);
     image(cardList.run(), 0, 0, 640, 960);
     rect(0, 0, 640, 960);
     popMatrix();
     
     //display queue
     pushMatrix();
     translate(0, 960);
     fill(0, 255, 255);
     rect(0, 0, 1920, 120);
     popMatrix();
     */


    //fill(255, 0, 0);
    //ellipse(constrain(rover1.destination.x, 0, width), constrain(rover1.destination.y, 0, height), 20, 20);
  }
}
