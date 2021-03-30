/*
Interface between Hexgrid and the Rover and Queue classes
 
 */

class Governor {
  Serial readerPort;
  Serial roverPort;
  Rover rover;
  Queue queue;

  Governor(int roverPort_, int readerPort_) {
    String readerPortName = Serial.list()[readerPort_];
    String roverPortName = Serial.list()[roverPort_];
  }
  Rover initRover(){
    
  }
}
