class Hexagon { //<>//
  float size;
  int pixelX, pixelY;
  int hexQ, hexR; //q for "column" = x axis, r for "row" = z axis
  boolean inBounds;
  boolean changed;
  PVector id;

  Hexagon(int hexQ_, int hexR_, int size_) {
    hexQ = hexQ_;
    hexR = hexR_;
    int hexX = hexQ;
    int hexZ = hexR;
    int hexY = -hexX - hexZ;
    
    size = size_;
    PVector pixelxy = new PVector();
    pixelxy = hexToPixel(hexQ, hexR);
    pixelX = int(pixelxy.x);
    pixelY = int(pixelxy.y);
    id = new PVector(hexX, hexY, hexZ);
    inBounds = true;
    changed = true;
  }
  
  PVector getID(){
   return(id); 
  }

  void drawHex(color c, int alpha) {
    //if (inBounds) {
      pushMatrix();
      translate(pixelX, pixelY);

      fill(c, alpha);
      strokeWeight(1);
      stroke(255);
      beginShape();
      for (int i = 0; i <= 360; i +=60) {
        float theta = radians(i);
        float cornerX = size * cos(theta);
        float cornerY = size * sin(theta);
        vertex(cornerX, cornerY);
      }
      endShape();

      //      strokeWeight(2);
      //      stroke(0);
      //      fill(0);
      //      String ID = ("(" + hexQ + ", " + hexY + ", " + hexR + ")");
      //      textSize(8);
      //      textAlign(CENTER, CENTER);
      //      text(ID, 0, 0);
      popMatrix();
    //}
  }

  void setState(boolean on) {
    inBounds = on;
    changed = true;
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
      if (inBounds && !hexGrid.activeHexes.containsKey(id)) { //if newly in bounds, add to activeHexes hashmap
        hexGrid.activeHexes.put(id, this);
      } else if (!inBounds && hexGrid.activeHexes.containsKey(id)) //if newly oob, remove from activeHexes hashmap
      { 
        hexGrid.activeHexes.remove(id);
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
}
