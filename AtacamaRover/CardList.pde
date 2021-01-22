import java.util.Date;
class CardList {

PImage[] foundLife;
PImage[] foundEvidence;
PImage[] notFound;
PImage instructions;
PImage currentCard;

int lastLife = 0;
int lastEvidence = 0;
int lastNoLife = 0;

int timer;
long timeout = 120000;

CardList() {
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
                foundEvidence[i] = loadImage(path+lifeFileNames[i]);
        }
        path = sketchPath() + "/data/cardImages/not_found/";
        String[] noLifeFileNames = listFileNames(path);
        foundEvidence = new PImage[noLifeFileNames.length];
        for (int i = 0; i < noLifeFileNames.length; i++) {
                foundEvidence[i] = loadImage(path+noLifeFileNames[i]);
        }
        path = sketchPath() + "/data/cardimages/instructions.png";
        instructions = loadImage(path);
        currentCard = instructions;
}

void run(){
        if(millis() - timer > 0 && currentCard != instructions) {
                currentCard = instructions;
        }
}

PImage display(){
        return currentCard;

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

PImage showInstructions(){
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
