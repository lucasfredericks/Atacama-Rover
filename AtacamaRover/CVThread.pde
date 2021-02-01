import boofcv.processing.*;
SimpleFiducial detector;
List<FiducialFound> found;

class CVThread extends Thread {
  volatile boolean ready;
  volatile boolean dataFlag;
  volatile long startFrame;
  volatile int latencyRatio;

  CVThread() {
    //camera = cam_;
    ready = true;
    dataFlag = false;
    detector = Boof.fiducialSquareBinaryRobust(0.1);
    String filePath = sketchPath() + "/data";
    CameraPinholeBrown intrinsic = CalibrationIO.load(new File(filePath, "intrinsic.yaml"));
    //detector.setIntrinsic(intrinsic);
    detector.guessCrappyIntrinsic(1280, 960);
    startFrame = frameCount;
  }
  void run() {
    while (true) {
      if (ready) {
        latencyRatio = int(frameCount - startFrame);
        //println("loop latency = " + (frameCount-startFrame));
        startFrame = frameCount;
        ready= false;
        found = detector.detect(cam);
        dataFlag = true;
        //println("thread loop");
      }
    }
  }

  List<FiducialFound> getFiducials() {
    ready = true;
    dataFlag = false;
    return found;
  }
}
