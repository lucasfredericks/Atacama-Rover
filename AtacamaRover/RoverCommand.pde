//class to hold command info for each rover step //<>//

class RoverCommand { // should this extend Hexagon class?
  Hexagon h;
  int cardinalDir;
  float radianDir;
  boolean reorient, drive, scan;
  boolean turnToHeading = true;
  boolean execute;
  PVector xy;
  PImage icon;
  int headingCheckCt = 0;

//Hexagon(Hexgrid hexgrid_, int hexQ_, int hexR_, int size_) {
  RoverCommand(Hexagon h_, int cardinalDir_, boolean drive_, boolean scan_, String iconName, boolean execute_) {
    String path = sketchPath() + "/data/icons/" + iconName;
    icon = loadImage(path);
    h = h_;
    xy = h.getXY();
    drive = drive_;
    scan = scan_;
    execute = execute_;
    reorient = !drive;
    while (cardinalDir_ < 0 || cardinalDir_ >= 6) {
      if (cardinalDir_ < 0) {
        cardinalDir_ += 6;
      }
      if (cardinalDir_ >= 6) {
        cardinalDir_ -= 6;
      }
    }
    cardinalDir = cardinalDir_;
    float[] cardHtoTheta = {0, 60, 120, 180, 240, 300};
    radianDir = radians(cardHtoTheta[cardinalDir]);
    h.fillin = execute;
    //println("rc created");
  }

  Hexagon getHex() {
    return h;
  }
  float getRadianDir() {
    return radianDir;
  }
  int getCardinalDir() {
    return cardinalDir;
  }
  PVector getXY() {
    return xy;
  }
  boolean driveStatus() {
    return drive;
  }
  boolean scanStatus() {
    return scan;
  }
  boolean reorientStatus() {
    return reorient;
  }
  boolean turnToHeadingStatus() {
    return turnToHeading;
  }
  PImage getIcon() {
    return icon;
  }

  boolean moveComplete() {
    if (turnToHeading) {
      turnToHeading = false;
      return false;
    } else if (drive) {
      drive = false;
      return false;
    } else if (reorient) {
      reorient = false;
    }
    if (!turnToHeading && !drive && !reorient) {
      h.fillin = false;
      return true;
    } else {
      return false;
    }
  }
}
