class Governor { //<>//
  PApplet sketch;
  PGraphics HUDbuffer;
  PGraphics hexgridBuffer;
  PGraphics queueGUI;
  PGraphics sized;
  PGraphics mapBuffer;
  PImage introCard;
  Hexgrid hexgrid;
  Rover rover;
  Queue queue;
  CardList cardList;
  int hexSize = 50;
  int indicatorWidth = 780;
  int indicatorHeight = 280;
  boolean first = true;


  Governor(PApplet sketch_, Hexgrid hexgrid_, int roverPort, int readerPort) {
    sketch = sketch_;
    hexgrid = hexgrid_;
    String roverPortName = Serial.list()[roverPort];
    String queuePortName = Serial.list()[readerPort];
    String tempPath = sketchPath() + "/data/cardimages/intro.jpg";
    introCard = loadImage(tempPath);
    queueGUI = createGraphics(1880, 210);
    HUDbuffer = createGraphics(1920, 1080);
    hexgridBuffer = createGraphics(camBufferWidth, camBufferHeight);
    mapBuffer = createGraphics(camBufferWidth, camBufferHeight);
    CommandList commandList = new CommandList(hexgrid);
    rover = new Rover(hexgrid, sketch, roverPortName);
    queue = new Queue(sketch, hexgrid, queuePortName, queueGUI, commandList);
    rover.initQueue(queue);
    queue.initRover(rover);
    hexgrid.drawOutlines(hexgridBuffer);
  }
  void run() {
    queue.update();
    rover.run();
    updateHUD();
  }

  int getWatchdog() {
    int watchdog = rover.watchdog;
    return watchdog;
  }

  void updateHUD() { //draw HUD
    
    hexgrid.drawMap(mapBuffer);
    
    hexgridBuffer.beginDraw();
    hexgridBuffer.clear();
    queue.drawHexes(hexgridBuffer);
    rover.displayHeading(hexgridBuffer);
    hexgridBuffer.endDraw();

    //display map grid
    HUDbuffer.beginDraw();
    HUDbuffer.imageMode(CORNER);
    HUDbuffer.clear();
    HUDbuffer.pushMatrix();
    HUDbuffer.translate(margin, margin);
   
    HUDbuffer.image(mapBuffer, 0, 0, camBufferWidth, camBufferHeight);
    HUDbuffer.image(hexgridBuffer, 0, 0, camBufferWidth, camBufferHeight);
   

    //display queue
    HUDbuffer.noStroke();
    HUDbuffer.fill(0);
    HUDbuffer.translate(0, camBufferHeight + margin);
    HUDbuffer.rect(0, 0, 1880, 210, 20);
    HUDbuffer.image(queueGUI, 0, 0, 1880, 210);
    HUDbuffer.popMatrix(); 

    //// display results indicator
    HUDbuffer.pushMatrix();
    HUDbuffer.translate(camBufferWidth + margin * 2, margin);

    //display intro card
    //HUDbuffer.translate(0, indicatorHeight + margin);
    HUDbuffer.image(introCard, 0, 0);
    HUDbuffer.popMatrix();


    if (queue.cardBool()) {
      HUDbuffer.imageMode(CENTER);
      HUDbuffer.image(queue.displayCard(), width/2, height/2, width-margin*2, height - margin*2);
    }
    HUDbuffer.endDraw();
  }
  PGraphics displayHUD() {
    return HUDbuffer;
  }


  void updateRoverLocation(FiducialFound f) {
    rover.updateLocation(f);
    if (first) {
      queue.pickScanDest();
      first = false;
    }
  }
}
