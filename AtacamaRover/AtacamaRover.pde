import boofcv.processing.*; //<>//
import processing.video.*;
import java.util.*;
import org.ejml.*;
import java.io.*;
import boofcv.struct.calib.*;
import boofcv.io.calibration.CalibrationIO;
import boofcv.alg.geo.PerspectiveOps;
import georegression.*;

Capture cam;
CVThread cvThread;
//SimpleFiducial detector;

Hexgrid hexgrid;
Governor governor1;

int rover1ID = 6; // the fiducial binary identifier for rover 1

int hexSize = 50;
int camWidth = 640;
int camHeight = 480;  
int camBufferWidth = 1280;
int camBufferHeight = 960;
float camScale;
color bg = color(0, 0, 0, 0);
color hover = color(255);
PGraphics gridOutlines;
Se3_F64 worldToCamera;
double lambda = 150; // fiducial width is defined as 1. lambda coefficient converts arbitrary world units to mm
double roverHeight = 25;
//double zscale;
CameraPinholeBrown intrinsic;
PGraphics arenaMask;

void setup() {
  frameRate(30);
  noSmooth();
  camScale = float(camBufferWidth)/float(camWidth);

  //cardList = new CardList();
  String filePath = sketchPath() + "/data";
  intrinsic = CalibrationIO.load(new File(filePath, "intrinsic.yaml"));
  cam = new Capture(this, camWidth, camHeight, "pipeline: ksvideosrc device-index=0 ! video/x-raw,width=640,height=480");
  cam.start();
  cvThread = new CVThread(intrinsic);
  cvThread.start();
  worldToCamera = new Se3_F64();
  initArena();

  printArray(Capture.list());
  surface.setSize(1920, 1080); //have to do this manually for detector to work
  fullScreen(2);// specifying renderer here appears to break the detector



  int readerPort1 = 1;
  int roverPort1 = 0;
  governor1 = new Governor(this, hexgrid, roverPort1, readerPort1);
  gridOutlines = createGraphics(camBufferWidth, camBufferHeight);
  hexgrid.drawOutlines(gridOutlines);
}

void initArena() {
  println("waiting for cv thread");
  while (true) {
    if (cam.available()) {
      cam.read();
    }
    if (cvThread.dataFlag) {
      //println("fiducials found");
      List<FiducialFound> found = cvThread.getFiducials();
      for ( FiducialFound f : found ) {
        println(f.getId());
        //heptagon interior angle: 128.571 ~= .9 radians
        if ((int)f.getId()==1234) {
          println("arena found");
          Arena arena = new Arena();
          worldToCamera.set(f.getFiducialToCamera());
          Point3D_F64 [] rwcorners = new Point3D_F64[7];
          Point2D_F64 [] pxCorners = new Point2D_F64[7];
          for (int i = 0; i < 7; i++) {
            float theta = i*.9;
            rwcorners[i] = new Point3D_F64(150*cos(theta)/lambda, 150*sin(theta)/lambda, roverHeight/lambda);
            pxCorners[i] = new Point2D_F64(0, 0);
            SePointOps_F64.transform(worldToCamera, rwcorners[i], rwcorners[i]);
            PerspectiveOps.convertNormToPixel(intrinsic, rwcorners[i].x/rwcorners[i].z, rwcorners[i].y/rwcorners[i].z, pxCorners[i]);
            ellipse((float)pxCorners[i].x, (float)pxCorners[i].y, 20, 20);
          }
          arenaMask = arena.init(pxCorners);
          hexgrid = new Hexgrid(hexSize, arenaMask, worldToCamera);
          return;
        }
      }
    }
  }
}

void draw() {

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
        governor1.updateRoverLocation(f);
        //detector.render(this, f);
      }
    }
    governor1.run();
  }
  ////canvas.beginDraw();
  image(cam, 0, 0, camBufferWidth, camBufferHeight);
  //image(arenaMask, 0, 0, camBufferWidth, camBufferHeight);
  //hexgrid.drawOutlines(gridOutlines);
  image(gridOutlines, 0, 0);
  image(governor1.displayHUD(), 0, 0);
  pushMatrix();
  String stats = ("framerate: " + int(frameRate) + ",  CV latency: " + cvThread.latencyRatio);
  textSize(15);
  fill(0);
  translate(20, height-20);
  text(stats, 0, 0);
  popMatrix();
  //image(arenaMask, 0, 0);
}
