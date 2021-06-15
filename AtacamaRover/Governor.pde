class Governor { //<>//
  PApplet sketch;
  PGraphics HUDbuffer;
  PGraphics hexgridBuffer;
  PGraphics queueGUI;
  PGraphics sized;
  Hexgrid hexgrid;
  Rover rover;
  Queue queue;
  CardList cardList;
  int hexSize = 50;
  int cardWidth = 780;
  int cardHeight = 720;
  int indicatorWidth = 780;
  int indicatorHeight = 280;


  Governor(PApplet sketch_, Hexgrid hexgrid_, int roverPort, int readerPort) {
    sketch = sketch_;
    hexgrid = hexgrid_;
    String roverPortName = Serial.list()[roverPort];
    String queuePortName = Serial.list()[readerPort];
    cardList = new CardList(cardWidth, cardHeight);
    queueGUI = createGraphics(1080, 210);
    HUDbuffer = createGraphics(1920, 1080);
    hexgridBuffer = createGraphics(camBufferWidth, camBufferHeight);
    CommandList commandList = new CommandList(hexgrid);
    rover = new Rover(hexgrid, sketch, roverPortName);
    queue = new Queue(sketch, cardList, hexgrid, queuePortName, queueGUI, commandList);
    rover.initQueue(queue);
    queue.initRover(rover);
    hexgrid.drawOutlines(hexgridBuffer);
  }
  void run() {
    queue.update();
    rover.run();
    cardList.run();
    updateHUD();
  }

  int getWatchdog() {
    int watchdog = rover.watchdog;
    return watchdog;
  }

  void updateHUD() { //draw HUD

    hexgridBuffer.beginDraw();
    hexgridBuffer.clear();

    queue.drawHexes(hexgridBuffer);
    rover.displayHeading(hexgridBuffer);
    hexgridBuffer.endDraw();

    //display hex grid
    HUDbuffer.beginDraw();
    HUDbuffer.clear();
    HUDbuffer.pushMatrix();
    HUDbuffer.translate(margin, margin);
    HUDbuffer.image(hexgridBuffer, 0, 0, camBufferWidth, camBufferHeight);
    
    //display queue
    HUDbuffer.stroke(255);
    HUDbuffer.strokeWeight(4);
    HUDbuffer.noFill();
    HUDbuffer.translate(0, camBufferHeight + margin);
    HUDbuffer.image(queueGUI, 0, 0);
    //HUDbuffer.rect(0, 0, 1920, 120);
    HUDbuffer.popMatrix();
    
    //// display results indicator
    HUDbuffer.pushMatrix();
    HUDbuffer.translate(camBufferWidth + margin*2, margin);
    HUDbuffer.image(cardList.displayIndicator(), 0, 0);
    
    //display results card
    HUDbuffer.translate(0, indicatorHeight + margin);
    HUDbuffer.image(cardList.displayCard(), 0, 0, cardWidth, cardHeight);
    HUDbuffer.popMatrix();
    HUDbuffer.endDraw();
  }
  PGraphics displayHUD() {
    return HUDbuffer;
  }


  void updateRoverLocation(FiducialFound f) {
    rover.updateLocation(f);
  }
}
