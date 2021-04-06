class Rover { //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>//
    Serial myPort;
    PApplet sketch;
    Hexgrid hexgrid;
    Queue queue;
    DMatrixRMaj rMatrix;
    double[] euler;
    float heading = 0;
    float targetHeading = 0;
    float dist = 0;
    PVector destination;
    PVector location;
    boolean inBounds;
    //boolean ready;
    float turnMOE = 10;     // margin of error for turning. Given in degrees and converted to radians in constructor
    String command;
    float cmdMagnitude; //if the rover is moving forward, this is given in cm. If it's turning, it is in radians
    
    int watchdog;
    int checkCt;
    
    //status variables
    boolean handshake;   // tracks acknowldgement from rover
    
    Rover(Hexgrid hexgrid_, PApplet sketch_, String serial) {
        sketch = sketch_;
        hexgrid = hexgrid_;
        //rMatrix = new DMatrixRMaj();
        //location = new PVector();
        //destination = new PVector();
        //euler = new double[2];
        myPort = new Serial(sketch, serial, 9600);
        //destination = new PVector(.5*width, .5*height);
        location = new PVector(0,0);
        turnMOE = radians(turnMOE);
        //nudgeMOE = radians(nudgeMOE);
        //ready = true;
        handshake = true;
        watchdog = 6; //set watchdog high, so nothing will happen until the rover is located at least once

    }
    void initQueue(Queue queue_) {
        queue = queue_;
    }
    void resetVars() {
        command = "stop";
        checkCt = 0;
        handshake = true;
    }
    
    void run() {
        
        if (watchdog <= 5) {
            
            if (queue.checkNew()) { //if the user has pressed the button, stop the current command
                resetVars();
            }
            watchdog++;
            //displayHeading();
        } else {
            command = "stop";
        }   
        while(myPort.available()>0) {
            
            int inByte = myPort.read();
            if (inByte == 'r') {
                handshake = true;
            }
            if (handshake) {
                handshake = false;
                sendCommand();
            }
        }
    }
    void drive() {
        boolean turnBool = false; //boolean variables for wayfinding while driving (not about status of the current rovercommand)
        //boolean nudgeTurnBool = false;
        boolean driveBool = false;
        //boolean nudgeDriveBool = false;
        
        if (queue.isActiveCommand()) {
            targetHeading = queue.getHeading(); //
            targetHeading = normalizeRadians(targetHeading);
            float ldelta = heading - targetHeading;
            float rdelta = targetHeading - heading;
            ldelta = normalizeRadians(ldelta);
            rdelta = normalizeRadians(rdelta);
            
            destination = queue.getDestination();
            dist = queue.compareDistances(destination);
            //println(dist);
            
            //set drive/turn variables
            if (min(abs(ldelta), abs(rdelta))>turnMOE) { //do coarse turning first
                turnBool = true;
            } else { 
                turnBool = false;
            }
            if (dist >= hexSize / 4) {
                driveBool = true;
            } else {
                driveBool = false;
            }
            
            if (turnBool) {
                if (abs(ldelta)<abs(rdelta)) {
                    command = "left";
                    cmdMagnitude = ldelta;
              } else {
                    command = "right";
                    cmdMagnitude = rdelta;
              }
            } else if (driveBool) {
                command = "forward";
                cmdMagnitude = (float) queue.getDistance();
            } else {
                queue.moveComplete();
                resetVars();
            }
      }
    }
    
    float normalizeRadians(float theta) {
        while(theta < 0 || theta > TWO_PI) {
            if (theta < 0) {
                theta += TWO_PI;
            }
            if (theta > TWO_PI) {
                theta -= TWO_PI;
            }
      }
        return theta;
    }
    void sendCommand() {
        byte commandByte = ' ';     //invalid command will default to 'stop'
        
        if (command == "stop") {
            commandByte = ' ';
      } else if (command == "left") {
            commandByte = 'a';
      } else if (command == "right") {
            commandByte = 'd';
      } else if (command == "forward") {
            commandByte = 'w';
      }
        
        if (commandByte == 'a' || commandByte == 'd' || commandByte == 'w' || commandByte == ' ') {
            String cmdString = commandByte + "," + cmdMagnitude;
            myPort.write(cmdString);
            println(cmdString);
      }
    }
    void displayHeading(PGraphics buffer) {
        buffer.beginDraw();
        buffer.pushMatrix();
        buffer.translate(location.x * camScale, location.y * camScale);
        buffer.strokeWeight(2);
        buffer.fill(255, 0, 0);
        buffer.textSize(24);
        buffer.pushMatrix();
        buffer.rotate(heading);
        buffer.stroke(255, 0, 0);
        buffer.line(0, 0, 0, - 50);
        buffer.popMatrix();
        buffer.pushMatrix();
        buffer.rotate(targetHeading);
        buffer.stroke(0, 255, 0);
        buffer.line(0, 0, 0, - 50);
        buffer.popMatrix();
        buffer.noStroke();
        buffer.ellipse(0, 0, 10, 10);
        buffer.popMatrix();
        buffer.endDraw();

    }
}
//line(pixelLocation.x, pixelLocation.y, dy, dx);
