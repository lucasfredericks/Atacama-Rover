//class to hold command info for each rover step

class RoverCommand { // should this extend Hexagon class?
  Hexagon h;
  int cardinalDir;
  float radianDir;
  boolean reorient;
  boolean turnToHeading = true;
  boolean drive;
  PVector xy;
  int headingCheckCt = 0;
  RoverCommand(Hexagon h_, int cardinalDir_, boolean drive_) {
    h = h_;
    xy = h.getXY();
    drive = drive_;
    reorient = !drive_;
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
    h.fillin = true;
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
  boolean reorientStatus() {
    return reorient;
  }
  boolean turnToHeadingStatus(){
   return  turnToHeading;
  }

  boolean moveComplete() {
    if(turnToHeading){
     turnToHeading = false; 
     return false;
    }
    else if (drive) { //<>//
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
