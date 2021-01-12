/* //<>// //<>// //<>//
   Hex grid calculations are based on the excellent interactive Hexagonal Grids guide
   from Amit Patel at Red Blob Games (https://www.redblobgames.com/grids/hexagons)

   There is also an implementation guide, which I did not see until I had done a lot of things the ugly way.
   If there is time, I will refactor this class into something resembling their much more elegant version.
   https://www.redblobgames.com/grids/hexagons/implementation.html
 */
class HexGrid {
HashMap<PVector, Hexagon> activeHexes;
HashMap<PVector, Hexagon> allHexes;
Arena arena;
PVector[] neighbors;
int qMin = -1;   //the q axis corresponds to the x axis on the screen. Higher values are further right
int qMax = 30;
int rMin = -13;   //the r axis is 30 degrees counterclockwise to the q/x axis. Higher values are down and to the left
int rMax = 13;
int hexSize;
Hexagon r1Hex;



HexGrid(int hexSize_) {

        arena = new Arena();

        neighbors = new PVector[6]; //pre-compute the 3D transformations to return adjacent hexes in 2D grid
        neighbors[0] = new PVector(0, 1, -1); // N
        neighbors[1] = new PVector(1, 0, -1); // NE
        neighbors[2] = new PVector(1, -1, 0); // SE
        neighbors[3] = new PVector(0, -1, 1); // S
        neighbors[4] = new PVector(-1, 0, 1); // SW
        neighbors[5] = new PVector(-1, 1, 0); // NW

        hexSize = hexSize_;

        allHexes = new HashMap<PVector, Hexagon>();
        activeHexes = new HashMap<PVector, Hexagon>();
        for (int q = qMin; q <= qMax; q++) {
                for (int r = rMin; r <= rMax; r++) {
                        int y = -q - r;
                        PVector loc = (hexToPixel(q, r));
                        if (loc.x > -hexSize && loc.x < width+hexSize && loc.y > 0-hexSize && loc.y < height+hexSize) {
                                PVector hexID = new PVector(q, y, r);
                                Hexagon h = new Hexagon(q, r, hexSize);
                                allHexes.put(hexID, h);
                        }
                }
        }
}

void update() {
        //arena.drawEdges();
        //arena.drawMask();
        //arena.arenaMask.loadPixels();
        for (Map.Entry<PVector, Hexagon> me : allHexes.entrySet()) {
                Hexagon h = me.getValue();
                //boolean status = h.checkMask();
                //boolean status = true; //debug
                h.setState(true);
        }
        //arena.interpolateHexes(); // find the hexes that lie along the lines between arena corners and mark them out of bounds
        for (Map.Entry<PVector, Hexagon> me : allHexes.entrySet()) {
                Hexagon h = me.getValue();
                h.updateHashMaps();
        }
}

void display() {
        for (Map.Entry<PVector, Hexagon> me : activeHexes.entrySet()) {
                Hexagon h = me.getValue();
                if (h.inBounds) {
                        h.drawHex();
                }
        }
}

void setCorners(int ident, int x, int y) {
        arena.setCorners(ident, x, y);
}

void occupyHex(Rover rover, Hexagon newHex, Hexagon lastHex) {

        newHex.occupy(rover);
        if (lastHex != null) {
                lastHex.vacate();
        }
}
  //PVector getHexKeyfromHex(Hexagon h){
  
  //}

Hexagon getHex(PVector hexKey) {   //hashmap lookup to return hexagon from PVector key
        Hexagon h = allHexes.get(hexKey);
        return(h);
}
PVector getXY(PVector hexKey) {   //hashmap lookup to return hexagon from PVector key
        Hexagon h = allHexes.get(hexKey);
        PVector hxy = h.getXY();
        return(hxy);
}

PVector getXY(Hexagon h){
  PVector hxy = h.getXY();
  return (hxy);
}

Hexagon getHex(Point2D_F64 hexKey_) {   //hashmap lookup to return hexagon from PVector key
        PVector hexKey = new PVector((float)hexKey_.x, (float)hexKey_.y);
        Hexagon h = allHexes.get(hexKey);
        return(h);
}

Hexagon pixelToHex(int xPixel, int yPixel) {   //find which hex a specified pixel lies in
        PVector hexID = new PVector();
        hexID.x = (2./3*xPixel)/hexSize;
        hexID.z = (-1./3 * xPixel + sqrt(3)/3 * yPixel)/hexSize;
        hexID.y = (-hexID.x - hexID.z);
        hexID = cubeRound(hexID);
        Hexagon h = allHexes.get(hexID);
        return h;
}

Hexagon[] getNeighbors(Hexagon h) {   //return an array of the 6 neighbor cells. If the neighbor is out of bounds, its array location will be null
        Hexagon[] neighborList = new Hexagon[6];
        PVector hexID = h.getKey();
        for (int i = 0; i < 6; i++) {
                PVector neighborID = hexID.copy();
                neighborID = neighborID.add(neighbors[i]);
                Hexagon neighbor = getHex(neighborID);
                if (neighbor == null) {
                        neighborList[i] = null;
                } else {
                        neighborList[i] = neighbor;
                }
        }
        return(neighborList);
}

Hexagon[] getNeighbors(PVector hexID) {   //overloaded method to accept a pvector key instead of a Hexagon object
        Hexagon[] neighborList = new Hexagon[6];
        for (int i = 0; i < 6; i++) {
                PVector neighborID = hexID.copy();
                neighborID = neighborID.add(neighbors[i]);
                Hexagon neighbor = getHex(neighborID);
                if (neighbor == null) {
                        neighborList[i] = null;
                } else {
                        neighborList[i] = neighbor;
                }
        }
        return(neighborList);
}

PVector hexToPixel(int q, int r) {
        PVector temp = new PVector(0, 0);
        temp.x = hexSize * (3./2 * q);
        temp.y = hexSize * (sqrt(3)/2 * q + sqrt(3) * r);
        return(temp);
}

PVector cubeRound(PVector hexID) {
        int rx = round(hexID.x);
        int ry = round(hexID.y);
        int rz = round(hexID.z);

        float xdiff = abs(rx - hexID.x);
        float ydiff = abs(ry - hexID.y);
        float zdiff = abs(rz - hexID.z);

        if (xdiff > ydiff && xdiff > zdiff) {
                rx = -ry-rz;
        } else if (ydiff > zdiff) {
                ry = -rx-rz;
        } else {
                rz = -rx-ry;
        }
        PVector rHexID = new PVector(rx, ry, rz);
        return(rHexID);
}
}
