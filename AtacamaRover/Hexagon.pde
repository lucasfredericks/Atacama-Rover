class Hexagon {
  float size;
  int pixelX, pixelY;
  Hexgrid hexgrid;
  int hexQ, hexR, hexS;     //q for "column" = x axis, r for "row" = z axis
  float scaledX, scaledY, scaledSize;
  PVector id;
  PVector pixelxy;
  boolean fillin = false;
  int blinkAlpha = 0;
  boolean blink = false;
  Point2D_F64 normCoords;
  PImage impassableIcon;
  
  float scale; //multiplier to convert from the size of the camera to the display size


  //pathfinding variables
  float f = 0;
  float g = 0;
  float heuristic = 0;
  List<Hexagon> neighbors = new ArrayList<Hexagon>();
  Hexagon previous = null;
  boolean passable = true;

  //

  Hexagon(Hexgrid hexgrid_, int hexQ_, int hexR_) {
    hexgrid = hexgrid_;
    hexQ = hexQ_;
    hexR = hexR_;
    hexS = -hexQ - hexR;
    int hexX = hexQ;
    int hexZ = hexR;
    int hexY = hexS;

    size = hexSize;
    pixelxy = hexToPixel(hexQ, hexR);
    pixelX = int(pixelxy.x);
    pixelY = int(pixelxy.y);
    scaledX = pixelX*camScale;
    scaledY = pixelY*camScale;
    scaledSize = scale*size;
    //rwCoords = new Vector3D_F64();
    normCoords = new Point2D_F64(pixelxy.x, pixelxy.y);
    PerspectiveOps.convertPixelToNorm(intrinsic, normCoords, normCoords);
    id = new PVector(hexX, hexY, hexZ);
  }

  void assignIcon(PImage icon_){
    impassableIcon = icon_;
  }

  PVector getKey() {
    return(id);
  }
  
  void resetPathfindingVars(){
   f = 0;
   g = 0;
   heuristic = 0;
   addNeighbors();
   previous = null;
  }

  void addNeighbors() {
    neighbors.clear();
    Hexagon[] neighbors_ = hexgrid.getNeighbors(this);
    for (int i = 0; i < neighbors_.length; i++) {
      Hexagon h = neighbors_[i];
      if (h!= null && hexgrid.checkHex(h.id)) {
        neighbors.add(h);
      }
    }
  }

  void drawHexOutline(PGraphics buffer) {
    buffer.pushMatrix();
    buffer.translate(pixelX, pixelY);
    buffer.noFill();
    buffer.strokeWeight(4);
    buffer.stroke(0, 0, 255);
    buffer.beginShape();
    for (int i = 0; i <= 360; i +=60) {
      float theta = radians(i);
      float cornerX = size * cos(theta);
      float cornerY = size * sin(theta);
      buffer.vertex(cornerX, cornerY);
    }
    buffer.endShape(CLOSE);
    
    if (false) { //debug
      buffer.strokeWeight(2);
      buffer.stroke(0);
      buffer.fill(0);
      String ID = id.x + ", " + id.y + ", " + id.z;
      buffer.textSize(12);
      buffer.textAlign(CENTER, CENTER);
      buffer.text(ID, 0, 0);
    }
    buffer.popMatrix();
  }

  void drawHexOutline(PGraphics buffer, color c, int strokeWeight_) {
    buffer.pushMatrix();
    buffer.translate(pixelX, pixelY);
    buffer.noFill();
    buffer.strokeWeight(strokeWeight_);
    buffer.stroke(c);
    buffer.beginShape();
    for (int i = 0; i <= 360; i +=60) {
      float theta = radians(i);
      float cornerX = size * cos(theta);
      float cornerY = size * sin(theta);
      buffer.vertex(cornerX, cornerY);
    }
    buffer.endShape(CLOSE);
    buffer.popMatrix();
  }

  void drawHexFill(PGraphics buffer, color c) {
    buffer.pushMatrix();
    buffer.translate(pixelX, pixelY);
    buffer.fill(c);
    buffer.noStroke();
    buffer.beginShape();
    for (int i = 0; i <= 360; i +=60) {
      float theta = radians(i);
      float cornerX = size * cos(theta);
      float cornerY = size * sin(theta);
      buffer.vertex(cornerX, cornerY);
    }
    buffer.endShape();
    buffer.popMatrix();
  }

  void drawHexFill(PGraphics buffer, color c, int alpha) {
    buffer.pushMatrix();
    buffer.translate(pixelX, pixelY);
    buffer.fill(c, alpha);
    buffer.noStroke();
    buffer.beginShape();
    for (int i = 0; i <= 360; i +=60) {
      float theta = radians(i);
      float cornerX = size * cos(theta);
      float cornerY = size * sin(theta);
      buffer.vertex(cornerX, cornerY);
    }
    buffer.endShape();
    buffer.popMatrix();
  }

  void drawIcon(PGraphics buffer){
    buffer.pushMatrix();
    buffer.translate(pixelX, pixelY);
    buffer.push();
    buffer.noStroke();
    buffer.noFill();
    buffer.imageMode(CENTER);
    buffer.image(impassableIcon, 0, 0);
    buffer.pop();
    buffer.popMatrix();
  }

  void passable() {
    passable = true;
  }

  void impassable() {
    passable = false;
  }

  void blinkHex(PGraphics buffer) {
    buffer.beginDraw();
    buffer.pushMatrix();
    buffer.translate(pixelX, pixelY);
    buffer.fill(255, blinkAlpha);
    buffer.noStroke();
    buffer.beginShape();
    for (int i = 0; i <= 360; i +=60) {
      float theta = radians(i);
      float cornerX = size * cos(theta);
      float cornerY = size * sin(theta);
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
    constrain(blinkAlpha, 0, 255);
    buffer.endDraw();
    //println("blink: " + blinkAlpha);
  }

  PVector hexToPixel(int q, int r) {
    PVector temp = new PVector(0, 0);
    temp.x = hexSize * (3./2 * q);
    temp.y = hexSize * (sqrt(3)/2 * q + sqrt(3) * r);
    //println(temp);
    return(temp);
  }
  PVector getXY() {
    return (pixelxy);
  }
  double getDist(Se3_F64 roverToCamera) {
    //Point3D_F64 rwLoc = new Point3D_F64();
    Point3D_F64 rwCoords = new Point3D_F64(normCoords.x, normCoords.y, 1); //
    //PerspectiveOps.convertPixelToNorm(intrinsic, px, px);
    //rwLoc.set(px.x, px.y, 1);
    Vector3D_F64 roverLoc = roverToCamera.getT();
    rwCoords.scale(roverLoc.z); 
    //SePointOps_F64.transformReverse(roverToCamera, rwCoords, rwCoords);
    double dist = roverLoc.distance(rwCoords)*lambda*10;
    return dist;
  }
}
