import boofcv.processing.*;
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
Arena arena;

int rover1ID = 6; // the fiducial binary identifier for rover 1

int hexSize = 70;
int camWidth = 1600;
int camHeight = 1200;  
int camBufferWidth = 1080;
int camBufferHeight = 810;
int margin = 20;
float camScale;
color bg = color(0, 0, 0, 0);
color hover = color(255);
PGraphics gridOutlines;
Se3_F64 worldToCamera;
double lambda = 150; // fiducial width is defined as 1. lambda coefficient converts arbitrary world units to cm
double roverHeight = 25;
//double zscale;
CameraPinholeBrown intrinsic;
PGraphics arenaMask;

void setup() {
  noCursor();
  frameRate(30);
  noSmooth();
  camScale = float(camBufferWidth)/float(camWidth);

  //cardList = new CardList();
  String filePath = sketchPath() + "/data";
  intrinsic = CalibrationIO.load(new File(filePath, "intrinsic.yaml"));
  cam = new Capture(this, camWidth, camHeight, "pipeline: ksvideosrc ! image/jpeg, width=1600, height=1200, framerate=30/1 ! jpegdec ! videoconvert");
  cam.start();
  cvThread = new CVThread(intrinsic);
  cvThread.start();
  worldToCamera = new Se3_F64();
  initArena();

  printArray(Capture.list());
  surface.setSize(1920, 1080); //have to do this manually for detector to work
  fullScreen(1);// specifying renderer here appears to break the detector



  int readerPort1 = 1;
  int roverPort1 = 0;

  governor1 = new Governor(this, hexgrid, roverPort1, readerPort1);
  //println("governor instantiated");
  gridOutlines = createGraphics(camBufferWidth, camBufferHeight);
  hexgrid.drawOutlines(gridOutlines);
  println("setup complete");
}

void initArena() {
  println("waiting for cv thread");
  while (true) {
    if (cam.available()) {
      cam.read();
    }
    int numCorners = 7;
    if (cvThread.dataFlag) {
      //println("fiducials found");
      List<FiducialFound> found = cvThread.getFiducials();
      for ( FiducialFound f : found ) {
        if ((int)f.getId()==1234) {
          println("arena found");
          arena = new Arena();
          worldToCamera.set(f.getFiducialToCamera());
          Point2D_F64 [] pxCorners = new Point2D_F64[numCorners];
          Point3D_F64 [] rwcorners = { //rw coordinates of arena corners in centimeters, with CV marker at (0,0)
            new Point3D_F64(-180, 140, 0), 
            new Point3D_F64(-10, 140, 0), 
            new Point3D_F64(140, 110, 0), 
            new Point3D_F64(160, 30, 0), 
            new Point3D_F64(90, -90, 0), 
            new Point3D_F64(-110, -160, 0), 
            new Point3D_F64(-180, 0, 0), 
            //new Point3D_F64(90, 160, 0), 
          };
          for (int i = 0; i < numCorners; i++) {
            rwcorners[i].set(rwcorners[i].x/lambda, rwcorners[i].y/lambda, roverHeight/lambda);
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
    background(#3b3b3c);
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
        //int ident = (int) f.getId() - 1;
        //println(ident);
        if (f.getId()==6) {
          governor1.updateRoverLocation(f);
          //detector.render(this, f);
        }
      }
    }
    governor1.run();
  }
  ////canvas.beginDraw();
  image(cam, margin, margin, camBufferWidth, camBufferHeight);
  //image(arenaMask, 0, 0, camBufferWidth, camBufferHeight);
  image(gridOutlines, margin, margin);
  image(governor1.displayHUD(), 0, 0);
  pushMatrix();
  String stats = ("framerate: " + int(frameRate) + ",  CV latency: " + cvThread.latencyRatio + ", watchdog: " + governor1.getWatchdog());
  textSize(15);
  fill(255);
  translate(width - 350, height-20);
  text(stats, 0, 0);
  popMatrix();
  //arena.drawCorners();
}
