//// We'll use SoftwareSerial to communicate with the XBee:
//#include <SoftwareSerial.h>
//
////For Atmega328P's
//// XBee's DOUT (TX) is connected to pin 2 (Arduino's Software RX)
//// XBee's DIN (RX) is connected to pin 3 (Arduino's Software TX)
//SoftwareSerial XBee(2, 3); // RX, TX
#include <Servo.h>
Servo servo1;
Servo servo2;
Servo servo3;
Servo servo4;

boolean turn = false;
boolean stopped = false;



const int dirApin = 12; // The pin controlling the direction of the A motors
const int dirBpin = 13; // Pin controlling direction of B motors
const int speedApin = 3; // Pin controlling speed of A motors (via PWM)
const int speedBpin = 11; // Pin controlling speed of B motors
const int driveSpeed = 120;
int turnMax = 255;
int turnMin = 100;

const int brakeApin = 8;
const int brakeBpin = 9;

uint8_t userInput;


void setup() {
  pinMode(dirApin, OUTPUT);
  pinMode(dirBpin, OUTPUT);
  pinMode(speedApin, OUTPUT);
  pinMode(speedBpin, OUTPUT);
  pinMode(brakeApin, OUTPUT);
  pinMode(brakeBpin, OUTPUT);
  attachServos();
  servoStraight();
  delay(100);
  detachServos();

  Serial.begin(9600);
}

void attachServos() {
  if (!servo1.attached()) {
    servo1.attach(4);
  }
  if (!servo2.attached()) {
    servo2.attach(5);
  }
  if (!servo3.attached()) {
    servo3.attach(6);
  }
  if (!servo4.attached()) {
    servo4.attach(7);
  }
}

void detachServos() {
  if (servo1.attached()) {
    servo1.detach();
  }
  if (servo2.attached()) {
    servo2.detach();
  }
  if (servo3.attached()) {
    servo3.detach();
  }
  if (servo4.attached()) {
    servo4.detach();
  }
}

void servoTurn() {
  turn = true;
  attachServos();
  servo1.write(75); // 4
  servo2.write(120); // 5
  servo3.write(75); // 6
  servo4.write(100); // 7
}

void servoStraight() {
  turn = false;
  attachServos();
  servo1.write(170);
  servo2.write(10);
  servo3.write(170);
  servo4.write(10);
}
void backwards() {

  // Moves the rover forward for 5 seconds
  servoStraight();
  digitalWrite(brakeApin, LOW);
  digitalWrite(brakeBpin, LOW);
  digitalWrite(dirApin, LOW);
  digitalWrite(dirBpin, LOW);  // Set both motors to forward
  analogWrite(speedApin, driveSpeed);
  analogWrite(speedBpin, driveSpeed);  // Set both motors to drive speed
  Serial.println(userInput);
}

void forward() {
  servoStraight();
  // Moves the rover backwards for 5 seconds
  digitalWrite(brakeApin, LOW);
  digitalWrite(brakeBpin, LOW);
  digitalWrite(dirApin, HIGH);
  digitalWrite(dirBpin, HIGH);  // Set both motors to backwards
  analogWrite(speedApin, driveSpeed);
  analogWrite(speedBpin, driveSpeed);  // Set both motors to full speed
  Serial.println(userInput);
}

void turnLeft() {

  servoTurn();
  turnMax = 255;
  // Turns rover to the left
  digitalWrite(brakeApin, LOW);
  digitalWrite(brakeBpin, LOW);
  digitalWrite(dirApin, LOW); // A side moves forward, B side backwards
  digitalWrite(dirBpin, HIGH);
  analogWrite(speedApin, turnMax);
  analogWrite(speedBpin, turnMax);  // Set both motors to full speed
  Serial.println(userInput);
}

void turnRight() {

  servoTurn();
  turnMax = 255;
  digitalWrite(brakeApin, LOW);
  digitalWrite(brakeBpin, LOW);
  // Turns rover to the right
  digitalWrite(dirApin, HIGH);   // A side moves backwards, B side forwards
  digitalWrite(dirBpin, LOW);
  analogWrite(speedApin, turnMax);
  analogWrite(speedBpin, turnMax);  // Set both motors to full speed
  Serial.println(userInput);

}


void dontmove() {
  analogWrite(speedApin, 0);
  analogWrite(speedBpin, 0);
  if (turn && !stopped) {
    servoStraight();
    stopped = true;

  }
  else if (!turn && !stopped) {
    servoTurn();
    stopped = true;
  }
  turn = !turn;
  digitalWrite(brakeApin, HIGH);
  digitalWrite(brakeBpin, HIGH);
  delay(50);
  detachServos();
}

void loop() {

  // read the incoming byte:
  if (Serial.available()) {
    userInput = Serial.read();
    //Serial.println(userInput);
    //    delay(delay_time);


    // ACSCII 'f' is 102 - this moves the rover forward
    if (userInput == 102) {
      stopped = false;
      forward();
    }
    // ACSCII 'b' is 98 - this moves the rover backwards
    else if (userInput == 98) {
      stopped = false;
      backwards();
    }
    // ACSCII 'l' is 108 - this moves the rover left
    else if (userInput == 108) {
      stopped = false;
      turnLeft();
    }
    // ACSCII 'r' is 114 - this moves the rover right
    else if (userInput == 114) {
      stopped = false;
      turnRight();
    }
    else if (userInput == 32) { //space
      dontmove();
    }
  }
  if (turn && !stopped && turnMax >= turnMin) { //slow down over the course of the turn to reduce acceleration
    turnMax -= 20;
    analogWrite(speedApin, turnMax);
    analogWrite(speedBpin, turnMax);
    delay(1);

  }
}
