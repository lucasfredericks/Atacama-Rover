/* //<>//
Based on Daniel Shiffman's A* Pathfinding Algorithm tutorial which can be found at: https://thecodingtrain.com/CodingChallenges/051.1-astar.html
*/

class AStar {
  Hexagon start;
  Hexagon target;
  Hexagon current;
  Hexgrid hexGrid;
  ArrayList <Hexagon> openSet;
  ArrayList <Hexagon> closedSet;
  ArrayList <Hexagon> path;
  
  int minDistance = 3;
  int maxPathLength = 12;
  int impassableRate = 3;
  
  
  AStar(Hexgrid hexGrid_) {
    hexGrid = hexGrid_;
    for (Map.Entry < PVector, Hexagon > me : hexGrid.allHexes.entrySet()) {
      Hexagon h = me.getValue();
      h.addNeighbors();
    }
    
    openSet = new ArrayList<Hexagon>();
    closedSet = new ArrayList<Hexagon>();
    path = new ArrayList<Hexagon>();
  }
  
  Hexagon createMap(Hexagon roverStart) {
    resetHexVars();
    start = roverStart;
    Hexagon h = pickHex();
    target = h;
    resetLists();   
    do{
      hexGrid.seedMap(impassableRate, start, target); //loop randomly assigning impassable hexes
    } while(!calculate() || path.size() > maxPathLength); //until there is a viable path less than max length
  return h;  
}
  
  
  void resetLists() {
    openSet.clear();
    closedSet.clear();
    path.clear();
    openSet.add(start);
  }
  
  Hexagon pickHex() {
    Hexagon h;
    Object[] keys = hexGrid.allHexes.keySet().toArray();
    do{
      Object randHexKey = keys[new Random().nextInt(keys.length)];
      h = hexGrid.getHex((PVector)randHexKey);
    } while(h == target || h == start || hexgrid.cubeDistance(h, target) < minDistance);
    return h;
    
  }
  
  void setTargets(Hexagon start_, Hexagon target_) {
    start = start_;
    target = target_;
    openSet.clear();
    closedSet.clear();
    path.clear();
    openSet.add(start);
  }
  
  float heuristic(Hexagon a, Hexagon b) {
    float d = hexGrid.cubeDistance(a, b);
    return d;
  }
  
  void generatePath() {
    path.clear();
    Hexagon temp = current;
    path.add(temp);
    while(temp.previous != null) {
      path.add(temp.previous);
      temp = temp.previous;
    }
    println("path length: " + (path.size() - 1));
  }
  void resetHexVars() {
    for (Map.Entry < PVector, Hexagon > me : hexGrid.allHexes.entrySet()) {
      Hexagon h = me.getValue();
      h.resetPathfindingVars();
    } 
  }
  
  boolean calculate() {
    while(true) {
      if (openSet.size() > 0) {
        int winner = 0;
        for (int i = 0; i < openSet.size(); i++) {
          if (openSet.get(i).f < openSet.get(winner).f) {
            winner = i;
          }
        }
        current = openSet.get(winner);
        
        //Did I finish?
        if (current == target) {
          println("target found");
          generatePath();
          return true;
        }
        
        //Best option moves from openSet to closedSet
        //openSet = removeFromArray(openSet, current);
        
        openSet.remove(current);
        closedSet.add(current);
        
        //check all the neighbors
        List<Hexagon> neighbors = current.neighbors;
        for (int i = 0; i < neighbors.size(); i++) {
          Hexagon neighbor = neighbors.get(i);
          
          //Valid next spot?
          if (!closedSet.contains(neighbor) && neighbor.passable) {
            float tempG = current.g + heuristic(neighbor, current);
            
            //Is this a better path than before?
            boolean newPath = false;
            if (openSet.contains(neighbor)) {
              if (tempG < neighbor.g) {
                neighbor.g = tempG;
                newPath = true;
              }
            } else {
              neighbor.g = tempG;
              newPath = true;
              openSet.add(neighbor);
            }
            //Yes, it's a better path
            if (newPath) {
              neighbor.heuristic = heuristic(neighbor, target);
              neighbor.f = neighbor.g + neighbor.heuristic;
              neighbor.previous = current;
            }
          }
        }
      } else { //no solution
        println("no solution");
        return false;
      }
    }
  }
  void displayPath() {
    //println(path);
    noFill();
    stroke(255, 0, 200);
    strokeWeight(4);
    beginShape();
    for (int i = 0; i < path.size(); i++) {
      Hexagon h = path.get(i);
      ellipse(h.pixelX, h.pixelY, 10, 10);
      vertex(h.pixelX, h.pixelY);
      //println(h.pixelxy);
    }
    endShape();
  }
}
