import boofcv.processing.*; //<>//
import processing.video.*;
import java.util.*;
import org.ejml.*;
import java.io.*;
import boofcv.struct.calib.*;
import boofcv.io.calibration.CalibrationIO;

Capture cam;
CVThread cvThread;
//SimpleFiducial detector;

Hexgrid hexgrid;
Arena arena;
int arenaCorners = 5;
Governor governor1;




int rover1ID = 6; // the fiducial binary identifier for rover 1

int hexSize = 120;
int camWidth = 1280;
int camHeight = 960;  
int camBufferWidth = 1280;
int camBufferHeight = 960;
float camScale;
color bg = color(0, 0, 0, 0);
color hover = color(255);
PGraphics gridOutlines;


void setup() {
  frameRate(30);
  noSmooth();

  //cardList = new CardList();
  cam = new Capture(this, camWidth, camHeight);
  cam.start();
  cvThread = new CVThread();
  cvThread.start();
  printArray(Capture.list());
  surface.setSize(1920, 1080); //have to do this manually for detector to work
  fullScreen(2);// specifying renderer here appears to break the detector

  //cam = new Capture(this, camWidth, camHeight, "pipeline: ksvideosrc device-index=0 ! video/x-raw,width=1920,height=1080");
  camScale = float(camBufferWidth)/float(camWidth);


  //frameRate(30);


  arena = new Arena();
  hexgrid = new Hexgrid(hexSize);
  int readerPort1 = 1;
  int roverPort1 = 0;
  governor1 = new Governor(this, hexgrid, roverPort1, readerPort1);
  gridOutlines = createGraphics(camBufferWidth, camBufferHeight);
  hexgrid.drawOutlines(gridOutlines);
}

void draw() {

  //println(frameRate);
  //if (frameCount%60 ==0) {
  //  println("framerate: " + frameRate);
  //}

  if (cam.available() == true) {
    cam.read();
    if (cvThread.dataFlag) {

      List<FiducialFound> found = cvThread.getFiducials();
      for ( FiducialFound f : found ) {
        //println(f);
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
          governor1.updateRoverLocation(f);
          //detector.render(this, f);
        }
      }
      governor1.run();
    }
    ////canvas.beginDraw();
    image(cam, 0, 0, camBufferWidth, camBufferHeight);
    image(gridOutlines, 0, 0);
    image(governor1.displayHUD(), 0, 0);
    pushMatrix();
    String stats = ("framerate: " + int(frameRate) + ",  CV latency: " + cvThread.latencyRatio);
    textSize(15);
    fill(0);
    translate(20,height-20);
    text(stats,0,0);
    popMatrix();
  }
  //image(cameraFeed,0,0);
}
