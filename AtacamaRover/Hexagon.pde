class Hexagon {
  float size;
  int pixelX, pixelY;
  Hexgrid hexgrid;
  float scaledX, scaledY, scaledSize;
  int hexQ, hexR;     //q for "column" = x axis, r for "row" = z axis
  PVector id;
  PVector pixelxy;
  Point2D_F64 normCoords;
  boolean fillin = false;
  int blinkAlpha = 0;
  boolean blink = false;


  float scale; //multiplier to convert from the size of the camera to the display size
  Rover occupant;

  Hexagon(Hexgrid hexgrid_, int hexQ_, int hexR_) {
    hexgrid = hexgrid_;
    hexQ = hexQ_;
    hexR = hexR_;
    int hexX = hexQ;
    int hexZ = hexR;
    int hexY = -hexX - hexZ;

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
    //.pixelToWorld(pixelxy).toVector();
    id = new PVector(hexX, hexY, hexZ);
  }

  PVector getKey() {
    return(id);
  }

  void drawHexOutline(PGraphics buffer) {
    buffer.pushMatrix();
    buffer.translate(scaledX, scaledY);
    buffer.noFill();
    buffer.strokeWeight(2);
    buffer.stroke(#a9e3df);
    buffer.beginShape();
    for (int i = 0; i <= 360; i +=60) {
      float theta = radians(i);
      float cornerX = camScale * size * cos(theta);
      float cornerY = camScale * size * sin(theta);
      buffer.vertex(cornerX, cornerY);
    }
    buffer.endShape(CLOSE);
    if (false) {
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

  void drawHexFill(PGraphics buffer, color c) {
    buffer.pushMatrix();
    buffer.translate(scaledX, scaledY);
    buffer.fill(c);
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
    constrain(blinkAlpha, 0, 255);
    //println("blink: " + blinkAlpha);
  }

  //void occupy(Rover rover) {
  //  occupied = true;
  //  occupant = rover;
  //}
  //void vacate() {
  //  occupied = false;
  //  occupant = null;
  //}

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
