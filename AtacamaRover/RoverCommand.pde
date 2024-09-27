//class to hold command info for each rover step //<>//

class RoverCommand extends Hexagon {
  int cardinalDir;
  float radianDir;
  boolean reorient, drive, function, execute, inBounds, passable;
  boolean turnToHeading = true;
  boolean scan = false;
  //PVector xy;
  PImage icon;
  int headingCheckCt = 0;
  byte cmdByte;


  //Hexagon(Hexgrid hexgrid_, int hexQ_, int hexR_, int size_) {
  RoverCommand(Hexgrid hexgrid_, PVector hexKey_, int cardinalDir_, byte cmd_, boolean function_, boolean execute_) {
    super(hexgrid_, int(hexKey_.x), int(hexKey_.z));
    cmdByte = cmd_;
    execute = execute_;
    reorient = !drive;
    function = function_;
    inBounds = (hexgrid.inBounds(hexKey_));
    passable = (hexgrid.isItPassable(hexKey_));
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
    String iconName = "";
    if (cmdByte == 119) { // 'w' forward
      iconName = "forward.png";
    } else if (cmdByte == 97) { // 'a' counterclockwise
      iconName = "counterclockwise.png";
    } else if (cmdByte == 115) { // 's' back
      iconName = "uturn.png";
    } else if (cmdByte == 100) { // 'd' right/clockwise
      iconName = "clockwise.png";
    } else if (cmdByte==101) { // 'e' scan for life
      iconName = "scan.png";
      scan = true;
    }
    String path = sketchPath() + "/data/icons/" + iconName;
    icon= loadImage(path);
    super.fillin = execute;
    //println("rc created");
  }

  float getRadianDir() {
    return radianDir;
  }

  int getCardinalDir() {
    return cardinalDir;
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
}
