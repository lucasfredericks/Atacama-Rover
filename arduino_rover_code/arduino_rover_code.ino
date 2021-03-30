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

uint8_t userInput;
uint8_t lastInput;

boolean turning = false;
boolean stopped;

boolean nudging = false;
boolean waitServos = false;
boolean wheelStraight;

unsigned long servoTimer;
int servoTimeout = 200;

unsigned long nudgeTimer;
int nudgeTimeout = 50;
const int dirApin = 12; // The pin controlling the direction of the A motors
const int dirBpin = 13; // Pin controlling direction of B motors
const int speedApin = 3; // Pin controlling speed of A motors (via PWM)
const int speedBpin = 11; // Pin controlling speed of B motors
const int driveSpeed = 150;
int turnMax = 150;
int turnMin = 120;
int turnVar;
const int brakeApin = 8;
const int brakeBpin = 9;

boolean input = false;

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

void turnServos() {
  if (wheelStraight == true) {
    analogWrite(speedApin, 0);
    analogWrite(speedBpin, 0);
    servo1.write(40); // 4
    servo2.write(130); // 5
    servo3.write(60); // 6
    servo4.write(130); // 7
    servoTimer = millis();
    waitServos = true;
  }
  else {
    waitServos = false;
  }
  wheelStraight = false;
}

void straightenServos() {
  if (wheelStraight == false) {
    analogWrite(speedApin, 0);
    analogWrite(speedBpin, 0);
    servo1.write(170);
    servo2.write(10);
    servo3.write(170);
    servo4.write(10);
    servoTimer = millis();
    waitServos = true;
  }
  else {
    waitServos = false;
  }
  wheelStraight = true;
}
void initReverse() {
  attachServos();
  straightenServos();
  digitalWrite(brakeApin, LOW);
  digitalWrite(brakeBpin, LOW);
  digitalWrite(dirApin, LOW);
  digitalWrite(dirBpin, LOW);  // Set both motors to forward
  //Serial.println(userInput);
}

void initForward() {
  attachServos();
  straightenServos();
  digitalWrite(brakeApin, LOW);
  digitalWrite(brakeBpin, LOW);
  digitalWrite(dirApin, HIGH);
  digitalWrite(dirBpin, HIGH);  // Set both motors to backwards
  //Serial.println(userInput);
}

void initLeft() {
  turnVar = turnMax;
  attachServos();
  turnServos();
  digitalWrite(brakeApin, LOW);
  digitalWrite(brakeBpin, LOW);
  digitalWrite(dirApin, LOW); // A side moves forward, B side backwards
  digitalWrite(dirBpin, HIGH);
  //Serial.println(userInput);
}

void initRight() {
  turnVar = turnMax;
  attachServos();
  turnServos();
  digitalWrite(brakeApin, LOW);
  digitalWrite(brakeBpin, LOW);
  digitalWrite(dirApin, HIGH);   // A side moves backwards, B side forwards
  digitalWrite(dirBpin, LOW);
  //Serial.println(userInput);

}

void dontmove() {
  analogWrite(speedApin, 0);
  analogWrite(speedBpin, 0);
  digitalWrite(brakeApin, HIGH);
  digitalWrite(brakeBpin, HIGH);
  stopped = true;
  detachServos();
  lastInput = userInput;
  //  if (turn && !stopped) {
  //    servoStraight();
  //    stopped = true;
  //    turn = !turn;
  //
  //  }
  //  else if (!turn && !stopped) {
  //    servoTurn();
  //    stopped = true;
  //    turn = !turn;
  //  }
}
void drive() {
  analogWrite(speedApin, driveSpeed);
  analogWrite(speedBpin, driveSpeed);
  lastInput = userInput;
}

void handshake() {
  if (input) {
    Serial.println(userInput);
    input = false;
  }
}

void setup() {
  pinMode(dirApin, OUTPUT);
  pinMode(dirBpin, OUTPUT);
  pinMode(speedApin, OUTPUT);
  pinMode(speedBpin, OUTPUT);
  pinMode(brakeApin, OUTPUT);
  pinMode(brakeBpin, OUTPUT);
  attachServos();
  straightenServos();
  delay(500);
  stopped = true;
  servoTimer = millis();
  nudgeTimer = millis();
  userInput = ' ';

  Serial.begin(9600);
}

void loop() {

  // read the incoming byte:
  if (Serial.available()) {
    input = true;
    userInput = Serial.read();
    //Serial.println(userInput);
    delay(5);

    if (userInput == 119) { // ACSCII 'w' move forward
      stopped = false;
      nudging = false;
      initForward();
      handshake();
    }
    else if (userInput == 87) {  // ASCII 'W' nudge forward
      stopped = false;
      nudging = true;
      initForward();
      nudgeTimer = millis();
    }
    else if (userInput == 97) {   // ASCII 'a' turn left
      stopped = false;
      nudging = false;
      initLeft();
      handshake();
    }
    else if (userInput == 65) {   //ASCII 'A' nudge left
      stopped = false;
      nudging = true;
      initLeft();
      nudgeTimer = millis();
    }
    else if (userInput == 115) {  // ASCII 's' move backward
      stopped = false;
      nudging = false;
      initReverse();
      handshake();
    }
    else if (userInput == 83) {  // ASCII 'S' nudge backward
      stopped = false;
      nudging = true;
      initReverse();
      nudgeTimer = millis();
    }
    else if (userInput == 100) {  // ACSCII 'd' turn right
      stopped = false;
      nudging = false;
      initRight();
      handshake();
    }
    else if (userInput == 68) { //ascii 'D' nudge right
      stopped = false;
      nudging = true;
      initRight();
      nudgeTimer = millis();
      //Serial.println("nudge");
    }
    else if (userInput == 32) { //space
      stopped = true;
      handshake();
    }
  }

  if (stopped == true) {
    dontmove();
    handshake();
  }
  else {
    if (waitServos) { //check whether servos had to turn
      if (nudging) {
        nudgeTimer = millis(); // continually reset the nudge timer until servos have had a chance to turn
      }
      if (millis() - servoTimer > servoTimeout) { //if servos have had time to turn
        waitServos = false;
      }
    }
    else {

      if (nudging) { // if not waiting for servos to turn
        drive();
        if (millis() - nudgeTimer > nudgeTimeout) {
          nudging = false;
          stopped = true;
          lastInput = 0; //allow repeat nudges
          handshake();
        }
      } else {
        drive();
        //Serial.println("drive");
        //handshake();
      }
    }
  }
}

//  if (turn && !stopped && turnVar >= turnMin) { //slow down over the course of the turn to reduce acceleration
//    turnVar -= 20;
//    analogWrite(speedApin, turnVar);
//    analogWrite(speedBpin, turnVar);
//    delay(1);
//
//  }
// }
