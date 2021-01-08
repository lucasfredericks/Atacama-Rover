import processing.serial.*; //<>//
import java.util.Iterator;


class Queue {

PApplet sketch;
Rover rover;
Serial myPort;
boolean newCommands;

ArrayList<Byte> commandArray;
ArrayList<PVector> destList;
float[] cardHtoTheta = {0,60,120,180,240,300};

Queue(PApplet sketch_, Rover rover_, String serial) {
        commandArray = new ArrayList<Byte>();
        destList = new ArrayList<PVector>;
        newCommands = false;

        rover = rover_;
        sketch = sketch_;
        myPort = new Serial(sketch, serial, 115200);

}
void update() {
        if ( myPort.available() > 0) { // If data is available,
                byte[] mainQueue = new byte[5];
                byte[] funcQueue = new byte[5];
                byte[] inBuffer = new byte[12];
                byte interesting = 16; //endByte
                inBuffer = myPort.readBytesUntil(interesting);
                if (inBuffer != null) {
                        myPort.readBytes(inBuffer);

                        for (int i = 0; i < 5; i++) {
                                mainQueue[i] = inBuffer[i];
                        }
                        for (int i = 0; i < 5; i++) {
                                funcQueue[i] = inBuffer[i+6];
                        }
                        myPort.clear();
                        parseCodingBlocks(mainQueue, funcQueue);
                        newCommands = true;
                }
        }
}
void parseCodingBlocks( byte[] mainQueue, byte[] funcQueue ) {
        boolean function = false;
        int cmdCount = 0;
        int funcCount = 0;
        byte tempByte;

        commandArray.clear();

        while (cmdCount < 5) {
                if (!function) {
                        tempByte = mainQueue[cmdCount];
                        if (tempByte == 113) //"function"
                                function = true;
                        else if (isValid(tempByte, function)) {
                                commandArray.add(tempByte);
                        }
                        if (!function) {
                                cmdCount++;
                        }
                }
                if (function) {
                        while (funcCount < 5) {
                                tempByte = funcQueue[funcCount];
                                if (isValid(tempByte, function)) {
                                        { //ignore recursive functions and invalid commands
                                                commandArray.add(tempByte);
                                        }
                                        funcCount++;
                                }
                        }
                        function = false;
                        funcCount = 0;
                        cmdCount++;
                }
        }

}
void parseCommandList {

        PVector lastXY = rover.pixelLocation;
        int cardinalHeading = roundHeading(rover.heading);
        Hexagon hexLoc = hexGrid.pixelToHex(lastXY);
        PVector key = new PVector();
        key.set(hexLoc.getKey())
        boolean drive;
        destList.clear();
        for (byte cmd: commandArray) {
                PVector destKey = new PVector();
                if (cmd == 119) { // 'w' forward
                        drive = true;
                } else if (cmd == 97) { // 'a' counterclockwise
                        drive = false;
                        cardinalHeading -= 1;
                } else if (cmd == 115) { // 's' back
                        drive = true;
                        cardinalHeading += 3;
                } else if (cmd == 100) { // 'd' right/clockwise
                        drive = true;
                        cardinalHeading += 1;
                }
                if(cardinalHeading<0) {cardinalHeading +=6;}
                if(cardinalHeading > 6) {cardinalHeading-=6}
                if(drive) {
                        key.add(hexGrid.neighbors[cardinalHeading]);
                        destList.add(destCoords);
                        drive = false;
                }
        }
}
int roundHeading(float h){
        if (degrees(h) > 330 || degrees(h) <= 30 ) { //refactor this into radians probably
                tempHeading = 0;
        } else if (degrees(h) >  30 && degrees(h) <= 90 ) {
                tempHeading = 1;
        } else if (degrees(h) >  90 && degrees(h) <= 150) {
                tempHeading = 2;
        } else if (degrees(h) > 150 && degrees(h) <= 210) {
                tempHeading = 3;
        } else if (degrees(h) > 210 && degrees(h) <= 270) {
                tempHeading = 4;
        } else if (degrees(h) > 270 && degrees(h) <= 330) {
                tempHeading = 5;
        }

}
boolean checkNext() {
        if (commandArray.isEmpty()) {
                return false;
        } else {
                return true;
        }
}

boolean checkNew() {
        if (newCommands) {
                newCommands = false;
                return true;
        } else {
                return false;
        }
}

byte getNext() {
        byte tempByte;
        tempByte = commandArray.get(0);
        return tempByte;
}

void complete() {
        if (!commandArray.isEmpty()) {
                commandArray.remove(0);
        }
}

boolean isValid(byte tempByte, boolean function) {

        if (tempByte == 119) {        // 'w' forward
                return true;
        } else if (tempByte ==97) {   // 'a' counterclockwise
                return true;
        } else if (tempByte == 115) { // 's' back
                return true;
        } else if (tempByte == 100) { // 'd' right/clockwise
                return true;
        } else if (tempByte == 101) { // 'e' scan for life
                return true;
        } else if (!function && tempByte ==  113) {// 'q' queue function
                return true;
        } else {
                return false;
        }
}
/*     The blocks use absolute directions, but steering is relative
   //      The arduino converts to relative commands and sends ascii characters
   //      for (f)orward, (b)ack, (l)eft, (r)ight, (q)ueue function, (s)earch,
   //      and (e)rror
 */
}
