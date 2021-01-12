import boofcv.processing.*;
import processing.video.*;
import java.util.*;
import org.ejml.*;
import java.io.*;
import boofcv.struct.calib.*;
import boofcv.io.calibration.CalibrationIO;
Arena arena;
int arenaCorners = 5;

Capture cam;
SimpleFiducial detector;


Rover rover1;
int rover1ID = 6; // the fiducial binary identifier for rover 1

HexGrid hexGrid;
int hexSize = 100;

color bg = color(0, 0, 0, 0);
color hover = color(255);



void setup() {
        frameRate(30);
        String[] cameras = Capture.list();
        println(Capture.list());
        cam = new Capture(this, 1280, 720, cameras[1]);
        cam.start();

        surface.setSize(cam.width, cam.height);
        //frameRate(30);

        Serial[] myPorts = new Serial[4]; // Create a list of objects from Serial class
        int[] dataIn = new int[4];   // a list to hold data from the serial ports

        //Serial port identifiers
        int readerPort1 = 1;
        int roverPort1 = 0;
        String reader1portName = Serial.list()[readerPort1];
        String rover1portName = Serial.list()[roverPort1];
        detector = Boof.fiducialSquareBinaryRobust(0.1);
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

void draw() {

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
                ellipse(rover1.location.x, rover1.location.y, 10, 10);

                fill(255, 0, 0);
                ellipse(constrain(rover1.destination.x, 0, width), constrain(rover1.destination.y, 0, height), 20, 20);
        }
}
