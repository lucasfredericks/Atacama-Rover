class Arena { //<>// //<>//
  Point2D_F64[] corners;
  PGraphics arenaMask;

  Arena() {
    arenaMask = createGraphics(camWidth, camHeight);
  }
  PGraphics init(Point2D_F64[] corners_) {
    corners = new Point2D_F64 [corners_.length];
    corners = corners_;
    arenaMask.beginDraw();
    arenaMask.fill(255);
    arenaMask.noStroke();
    arenaMask.background(0);
    arenaMask.beginShape();
    for (int i = 0; i < corners.length; i++) {
      arenaMask.vertex((float)corners[i].x, (float)corners[i].y);
    }
    arenaMask.endShape(CLOSE);
    arenaMask.endDraw();
    arenaMask.updatePixels();
    return (arenaMask);
  }


  void drawCorners() {
    stroke(255, 0, 0);
    strokeWeight(8);
    for (int i = 0; i < corners.length; i++) {
      double cornerX = (camScale*corners[i].x);
      double cornerY = (camScale*corners[i].y);
      ellipse((float)cornerX, (float)cornerY, 10, 10);
    }
  }
}

//PGraphics drawMask() {
//  arenaMask.beginDraw();
//  arenaMask.fill(0);
//  arenaMask.stroke(0);
//  arenaMask.strokeWeight(1);
//  arenaMask.background(255);
//  arenaMask.beginShape();
//  for (int i = 0; i < corners.length; i++) {
//    arenaMask.vertex(corners[i].x, corners[i].y);
//  }
//  arenaMask.endShape(CLOSE);
//  arenaMask.endDraw();
//}

//  void drawEdges() {
//    noFill();
//    beginShape();
//    PVector startPoint = new PVector(0, 0);
//    for (int i = 0; i < 5; i++) {
//      int x = (int) corners[i].x;
//      int y = (int) corners[i].y;
//      if (i == 0) {
//        startPoint.x = x;
//        startPoint.y = y;
//      }
//      vertex(x, y);
//    }
//    vertex(startPoint.x, startPoint.y);
//    endShape();
//  }

//  void interpolateHexes() {
//    PVector cornerA = new PVector();
//    PVector cornerB = new PVector();
//    for (int i = 0; i < arenaCorners; i++) {
//      cornerA = (corners[i].copy());
//      if (i == arenaCorners-1) {
//        cornerB = (corners[0].copy());
//      } else {
//        cornerB = (corners[i+1].copy());
//      }
//      float d = PVector.dist(cornerA, cornerB);
//      int n = int(d/hexSize);
//      for (int j = 0; j <= n; j++) {
//        PVector middle = new PVector();
//        middle = PVector.lerp(cornerA, cornerB, 1/d*hexSize*j);
//        //point(middle.x, middle.y);
//        int x = (int) middle.x;
//        int y = (int) middle.y;
//        Hexagon h = hexgrid.pixelToHex(x, y);
//        if (h != null) {
//          h.setState(false);
//        }
//      }

//      //get start vector
//      //get end vector
//      //find distance
//      //find the hex distance between the two points
//      //evenly sample n + 1 points between point A and point B each point will be A + (B-A) * 1.0/N * i
//      //pixelToHex
//      //mark hex OOB
//    }
//  }
//}
