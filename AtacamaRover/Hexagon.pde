class Hexagon {
  float size;
  int pixelX, pixelY;
  float scaledX, scaledY, scaledSize;
  int hexQ, hexR;     //q for "column" = x axis, r for "row" = z axis
  boolean inBounds;
  boolean changed;
  PVector id;
  PVector pixelxy;
  boolean occupied = false;
  boolean fillin = false;
  int blinkAlpha = 0;
  boolean blink = false;


  float scale; //multiplier to convert from the size of the camera to the display size
  Rover occupant;

  Hexagon(int hexQ_, int hexR_, int size_) {
    hexQ = hexQ_;
    hexR = hexR_;
    int hexX = hexQ;
    int hexZ = hexR;
    int hexY = -hexX - hexZ;

    size = size_;
    pixelxy = new PVector();
    pixelxy = hexToPixel(hexQ, hexR);
    pixelX = int(pixelxy.x);
    pixelY = int(pixelxy.y);
    scaledX = pixelX*camScale;
    scaledY = pixelY*camScale;
    scaledSize = scale*size;
    id = new PVector(hexX, hexY, hexZ);
    inBounds = true;
    changed = true;
  }

  PVector getKey() {
    return(id);
  }

  void drawHexOutline(PGraphics buffer) {
    //if (inBounds) {
    buffer.pushMatrix();
    buffer.translate(scaledX, scaledY);
    buffer.noFill();
    buffer.strokeWeight(2);
    buffer.stroke(0);
    buffer.beginShape();
    for (int i = 0; i <= 360; i +=60) {
      float theta = radians(i);
      float cornerX = camScale * size * cos(theta);
      float cornerY = camScale * size * sin(theta);
      buffer.vertex(cornerX, cornerY);
    }
    buffer.endShape();

    //      strokeWeight(2);
    //      stroke(0);
    //      fill(0);
    //      String ID = ("(" + hexQ + ", " + hexY + ", " + hexR + ")");
    //      textSize(8);
    //      textAlign(CENTER, CENTER);
    //      text(ID, 0, 0);
    buffer.popMatrix();
    //}
  }

  void drawHexFill(PGraphics buffer) {
    buffer.pushMatrix();
    buffer.translate(scaledX, scaledY);
    buffer.fill(255, 50);
    buffer.noStroke();
    buffer.beginShape();
    for (int i = 0; i <= 360; i +=60) {
      float theta = radians(i);
      float cornerX = camScale * size * cos(theta);
      float cornerY = camScale * size * sin(theta);
      buffer.vertex(cornerX, cornerY);
    }
    buffer.endShape();
    buffer.popMatrix();
  }
  void blinkHex(PGraphics buffer) {
    buffer.pushMatrix();
    buffer.translate(scaledX, scaledY);
    buffer.fill(255, blinkAlpha);
    buffer.noStroke();
    buffer.beginShape();
    for (int i = 0; i <= 360; i +=60) {
      float theta = radians(i);
      float cornerX = camScale * size * cos(theta);
      float cornerY = camScale * size * sin(theta);
      buffer.vertex(cornerX, cornerY);
    }
    buffer.endShape();
    buffer.popMatrix();  
    if (blinkAlpha<=0) {
      blink = true;
    }
    if (blinkAlpha >=255) {
      blink = false;
    }
    if (blink) {
      blinkAlpha+= 25;
    } else {
      blinkAlpha-=25;
    }
    constrain(blinkAlpha,0,255);
    //println("blink: " + blinkAlpha);
  }

  void setState(boolean on) {
    inBounds = on;
    changed = true;
  }

  void occupy(Rover rover) {
    occupied = true;
    occupant = rover;
  }
  void vacate() {
    occupied = false;
    occupant = null;
  }

  boolean checkMask() {
    boolean mask; // true means the hex will be inbounds
    if (pixelY <= 0 || pixelY >= height || pixelX <= 0 || pixelX >= width) {
      mask = false;
    } else {
      int val = arena.arenaMask.get(pixelX, pixelY);
      if (val != -1) {
        mask = true;
      } else {
        mask = false;
      }
    }
    //return(mask);
    return(true);
  }


  void updateHashMaps() {
    if (changed) {
      if (inBounds && !hexgrid.activeHexes.containsKey(id)) { //if newly in bounds, add to activeHexes hashmap
        hexgrid.activeHexes.put(id, this);
      } else if (!inBounds && hexgrid.activeHexes.containsKey(id)) //if newly oob, remove from activeHexes hashmap
      {
        hexgrid.activeHexes.remove(id);
      }
    }
    changed = false;
  }

  PVector hexToPixel(int q, int r) {
    PVector temp = new PVector(0, 0);
    temp.x = hexSize * (3./2 * q);
    temp.y = hexSize * (sqrt(3)/2 * q + sqrt(3) * r);
    return(temp);
  }
  PVector getXY() {
    return (pixelxy);
  }
}
