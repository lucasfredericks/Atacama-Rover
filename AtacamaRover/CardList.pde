import java.util.Date; //<>//
class CardList {

  PImage[] foundLife;
  PImage[] foundEvidence;
  PImage[] notFound;
  PImage instructions;
  PImage currentCard;
  PImage indicatorLife;
  PImage indicatorNoLife;
  PImage indicatorSignOfLife;
  PImage indicatorOff;
  PImage currentIndicator;

  int cardWidth, cardHeight;
  PGraphics cardBuffer;
  Animation lines;
  boolean animate = false;

  LoadingBar loadingBar;


  int lastLife;
  int lastEvidence;
  int lastNoLife;

  long scanTimer = 0;
  long dispTimer;
  long dispTimeout = 120000;

  CardList(int cardWidth_, int cardHeight_) {
    cardWidth = cardWidth_;
    cardHeight = cardHeight_;
    cardBuffer = createGraphics(cardWidth, cardHeight);
    lastLife = 0;
    lastEvidence = 0;
    lastNoLife = 0;
    dispTimer = millis();
    lines = new Animation("cardImages/Line_animation/Line_animation_", 16);
    String path = sketchPath() + "/data/cardImages/found_evidence/";
    String[] evidenceFileNames = listFileNames(path);
    foundEvidence = new PImage[evidenceFileNames.length];
    for (int i = 0; i < evidenceFileNames.length; i++) {
      foundEvidence[i] = loadImage(path+evidenceFileNames[i]);
    }
    path = sketchPath() + "/data/cardImages/found_life/";
    String[] lifeFileNames = listFileNames(path);
    lifeFileNames = listFileNames(path);
    foundLife = new PImage[lifeFileNames.length];
    for (int i = 0; i < lifeFileNames.length; i++) {
      foundLife[i] = loadImage(path+lifeFileNames[i]);
    }
    path = sketchPath() + "/data/cardImages/not_found/";
    String[] noLifeFileNames = listFileNames(path);
    notFound = new PImage[noLifeFileNames.length];
    for (int i = 0; i < noLifeFileNames.length; i++) {
      notFound[i] = loadImage(path+noLifeFileNames[i]);
    }
    path = sketchPath() + "/data/cardimages/Intro.png";
    instructions = loadImage(path);
    currentCard = instructions;
    path = sketchPath() + "/data/results_indicator/";
    indicatorLife = loadImage(path+"indicatorLife.png");
    indicatorNoLife = loadImage(path+"indicatorNoLife.png");
    indicatorSignOfLife = loadImage(path+"indicatorSignOfLife.png");
    indicatorOff = loadImage(path+"indicatorOff.png");
    currentIndicator = indicatorOff;

    loadingBar = new LoadingBar(400, 40);
  }

  void run() {
    if (millis() - dispTimer > dispTimeout && currentCard != instructions) {
      currentCard = instructions;
    }
  }

  PImage displayCard() {
    cardBuffer.beginDraw();
    cardBuffer.rectMode(CENTER); 
    cardBuffer.clear();
    cardBuffer.noStroke();
    //cardBuffer.fill(#000000);
    cardBuffer.pushMatrix();
    cardBuffer.translate(cardWidth/2, cardHeight/2);
    //cardBuffer.rect(0, 0, cardWidth, cardHeight, 10);

    if (millis() - scanTimer < 1000) { //.8 second timer
      loadingBar.display(0, 0, cardBuffer);
    } else {
      cardBuffer.imageMode(CENTER);
      cardBuffer.image(currentCard, 0, 0, cardWidth, cardHeight);
      if (animate) {
        cardBuffer.imageMode(CORNER);
        cardBuffer.popMatrix();
        cardBuffer.pushMatrix();
        cardBuffer.translate(445, 112);
        cardBuffer.image(lines.display(), 0, 0, 300, 531);
      }
    }
    cardBuffer.popMatrix();
    cardBuffer.endDraw();
    return cardBuffer;
  }
  PImage displayIndicator() {
    return currentIndicator;
  }

  boolean scan(Hexagon location, Hexagon target) {
    scanTimer = millis();

    PVector lKey = location.getKey();
    PVector tKey = target.getKey();
    //println(d);
    //println(location);
    //println(target);
    float r = random(0, 10);
    if (lKey == tKey) {
      lifeFound();
      return true;
    } 
    float d = location.getXY().dist(target.getXY());

    if (d <= 2*hexSize) {
      if (r>3) {
        evidenceFound();
      } else { 
        noLifeFound();
      }
      //lifeFound();
    } else {
      if (r>=7) {
        evidenceFound(); 
        //lifeFound();
      } else {
        noLifeFound(); 
        //lifeFound();
      }
    }
    return false;
  }

  void lifeFound() {
    animate = true;
    dispTimer = millis();
    int i = lastLife;
    while (i == lastLife) {
      i = int(random(0, foundLife.length));
    }
    lastLife = i;
    currentCard = foundLife[i];
    currentIndicator = indicatorLife;
  }

  void evidenceFound() {
    animate = false;
    dispTimer = millis();
    int i = lastEvidence;
    while (i == lastEvidence) {
      i = int(random(0, foundEvidence.length));
    }
    lastEvidence = i;
    currentCard = foundEvidence[i];
    currentIndicator = indicatorSignOfLife;
  }

  void noLifeFound() {
    animate = false;
    dispTimer = millis();
    int i = lastNoLife;
    while (i == lastNoLife) {
      i = int(random(0, notFound.length));
    }
    lastNoLife = i;
    currentCard = notFound[i];
    currentIndicator = indicatorNoLife;
  }

  PImage showInstructions() {
    animate = false;
    currentCard = instructions;
    currentIndicator = indicatorOff;
    return instructions;
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
    rectWidth = barWidth/15;
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
    buffer.translate(-barWidth/2, 0);
    buffer.noStroke();
    for (int i = (rectWidth + margin)/2; i < barWidth; i+= rectWidth) {
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
class Animation {
  PImage[] images;
  int imageCount;
  int frame;

  Animation(String imagePrefix, int count) {
    imageCount = count;
    images = new PImage[imageCount];

    for (int i = 0; i < imageCount; i++) {
      // Use nf() to number format 'i' into four digits
      String filename = imagePrefix + nf(i, 4) + ".gif";
      images[i] = loadImage(filename);
    }
  }

  PImage display() {
    frame = (frame+1) % imageCount;
    PImage anim = images[frame];
    return anim;
  }
}
