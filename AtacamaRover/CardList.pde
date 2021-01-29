import java.util.Date; //<>//
class CardList {

  PImage[] foundLife;
  PImage[] foundEvidence;
  PImage[] notFound;
  PImage instructions;
  PImage currentCard;
  

  int lastLife;
  int lastEvidence;
  int lastNoLife;

  int timer;
  long timeout = 120000;

  CardList() {
    lastLife = 0;
    lastEvidence = 0;
    lastNoLife = 0;
    timer = millis();
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
    path = sketchPath() + "/data/cardimages/instructions.png";
    instructions = loadImage(path);
    currentCard = instructions;
  }

  void run() {
    if (millis() - timer > timeout && currentCard != instructions) {
      currentCard = instructions;
    }
  }

  PImage display() {
    return currentCard;
  }

  boolean scan(Hexagon location, Hexagon target) {
    float d = location.getXY().dist(target.getXY());
    println(d);
    println(location);
    println(target);
    float r = random(0, 10);
    if (location == target) {
      lifeFound();
      return true;
    } else if (d <= 2*hexSize) {
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
    timer = millis();
    int i = lastLife;
    while (i == lastLife) {
      i = int(random(0, foundLife.length));
    }
    currentCard = foundLife[i];
  }

  void evidenceFound() {
    timer = millis();
    int i = lastEvidence;
    while (i == lastEvidence) {
      i = int(random(0, foundEvidence.length));
    }
    currentCard = foundEvidence[i];
  }

  void noLifeFound() {
    timer = millis();
    int i = lastNoLife;
    while (i == lastNoLife) {
      i = int(random(0, notFound.length));
    }
    currentCard = notFound[i];
  }

  PImage showInstructions() {
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
