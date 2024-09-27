import java.util.Date;
class CardList {

  PImage[] percyPhotos;
  PImage currentCard;
  PImage hazardCard;
  Queue queue;

  int cardWidth = 1920;
  int cardHeight = 1080;
  PGraphics cardBuffer;
  LoadingBar loadingBar;

  boolean showCard = false;
  int index;

  long scanTimer = 0;
  long dispTimer;
  long dispTimeout = 120000;

  CardList(Queue queue_) {
    queue = queue_;
    cardBuffer = createGraphics(cardWidth, cardHeight);

    dispTimer = millis();
    String path = sketchPath() + "/data/cardImages/Percy/";
    String[] files = listFileNames(path);
    percyPhotos = new PImage[files.length];
    println("loading images");
    for (int i = 0; i < files.length; i++) {
      percyPhotos[i] = loadImage(path + files[i]);
      percyPhotos[i].resize(cardWidth, 0);
    }
    path = sketchPath() + "/data/cardImages/hazard.jpg";
    hazardCard = loadImage(path);
    println("done");
    currentCard = percyPhotos[0];
    //loadingBar = new LoadingBar(400, 40);
  }

  void run() {
    if (millis() - dispTimer > dispTimeout) {
      stopDisplayingCard();
    }
  }

  PImage displayCard() {
    cardBuffer.beginDraw();
    cardBuffer.rectMode(CENTER); 
    cardBuffer.clear();
    cardBuffer.noStroke();
    cardBuffer.pushMatrix();
    cardBuffer.translate(cardWidth / 2, cardHeight / 2);
    cardBuffer.imageMode(CENTER);
    cardBuffer.image(currentCard, 0, 0, cardWidth, cardHeight);
   cardBuffer.popMatrix();
    cardBuffer.endDraw();
    return cardBuffer;
  }

  void hazard() {
    currentCard = hazardCard;
    dispTimer = millis();
    showCard = true;
  }
  
  boolean scan(PVector location, PVector target){
   scanTimer = millis();
   if(location.equals(target)){
    lifeFound();
    return true;
   }else{
     return false;
   }
  }

  boolean scan(Hexagon location, Hexagon target) {
    println("location: " + location);
    println("target: " + target);
    scanTimer = millis();

    PVector lKey = location.getKey();
    PVector tKey = target.getKey();
    //println(d);
    //println(location);
    //println(target);
    if (lKey == tKey) {
      lifeFound();
      return true;
    } else {    
      return false;
    }
  }

  void lifeFound() {
    dispTimer = millis();
    currentCard = percyPhotos[index];
    showCard = true;
  }

  void stopDisplayingCard() {
    if (showCard) {
      showCard = false;
      index = (index + 1) % percyPhotos.length;
      currentCard = percyPhotos[index];
      queue.pickScanDest();
    }
  }

  String[] listFileNames(String dir) {
    File file = new File(dir);
    if (file.isDirectory()) {
      String names[] = file.list();
      return names;
    } else {
      // If it's not a directory
      return null;
    }
  }
}

class LoadingBar {
  int iter;
  int xLoc, yLoc, barWidth, barHeight, rectWidth, margin;

  LoadingBar(int barWidth_, int barHeight_) { 
    barWidth = barWidth_;
    barHeight = barHeight_;
    iter = 0;
    rectWidth = barWidth / 15;
    margin = barWidth % 15;
  }
  PGraphics display(int xLoc, int yLoc, PGraphics buffer) {
    buffer.noFill();
    color c = #00ffff;
    buffer.pushMatrix();
    buffer.translate(xLoc, yLoc);
    buffer.stroke(255, 100);
    buffer.strokeWeight(2);
    buffer.rect(0, 0, barWidth, barHeight + margin, 10);  
    buffer.translate( -barWidth / 2, 0);
    buffer.noStroke();
    for (int i = (rectWidth + margin) / 2; i < barWidth; i += rectWidth) {
      int alpha = min(abs(i - iter), abs(i - barWidth + iter));
      //int alpha = min(abs(i - iter), abs(i - barWidth - iter), i + barWidth - iter);
      map(alpha, 0, barWidth, 0, 255);
      buffer.fill(c, alpha);
      buffer.rect(i, 0, rectWidth - 5, barHeight, 5);
    }
    buffer.popMatrix();
    iter = (iter + 4) % barWidth;
    return buffer;
  }
}
