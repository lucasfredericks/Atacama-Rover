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
const int driveSpeed = 150;
int turnMax = 175;
int turnMin = 150;
int turnVar;
unsigned long servoTimer;
int servoTurnTime = 200;



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
  servoTimer = millis();

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
  servo1.write(40); // 4
  servo2.write(130); // 5
  servo3.write(60); // 6
  servo4.write(130); // 7
  servoTimer = millis();
  while (millis() - servoTimer < servoTurnTime) { //wait for servos to turn
  }
}

void servoStraight() {

  turn = false;
  attachServos();
  servo1.write(170);
  servo2.write(10);
  servo3.write(170);
  servo4.write(10);
  servoTimer = millis();
  while (millis() - servoTimer < servoTurnTime) {//wait for servos to turn

  }
  //delay(100);
}
void backwards() {

  // Moves the rover forward

  digitalWrite(brakeApin, LOW);
  digitalWrite(brakeBpin, LOW);
  servoStraight();
  digitalWrite(dirApin, LOW);
  digitalWrite(dirBpin, LOW);  // Set both motors to forward
  analogWrite(speedApin, driveSpeed);
  analogWrite(speedBpin, driveSpeed);  // Set both motors to drive speed
  //Serial.println(userInput);
}

void forward() {

  // Moves the rover backwards for 5 seconds
  digitalWrite(brakeApin, LOW);
  digitalWrite(brakeBpin, LOW);
  servoStraight();
  digitalWrite(dirApin, HIGH);
  digitalWrite(dirBpin, HIGH);  // Set both motors to backwards
  analogWrite(speedApin, driveSpeed);
  analogWrite(speedBpin, driveSpeed);  // Set both motors to full speed
  //Serial.println(userInput);
}

void turnLeft() {


  turnVar = turnMax;
  // Turns rover to the left
  digitalWrite(brakeApin, LOW);
  digitalWrite(brakeBpin, LOW);
  servoTurn();
  digitalWrite(dirApin, LOW); // A side moves forward, B side backwards
  digitalWrite(dirBpin, HIGH);
  analogWrite(speedApin, turnVar);
  analogWrite(speedBpin, turnVar);  // Set both motors to full speed
  //Serial.println(userInput);
}

void turnRight() {


  turnVar = turnMax;
  digitalWrite(brakeApin, LOW);
  digitalWrite(brakeBpin, LOW);
  servoTurn();
  // Turns rover to the right
  digitalWrite(dirApin, HIGH);   // A side moves backwards, B side forwards
  digitalWrite(dirBpin, LOW);
  analogWrite(speedApin, turnVar);
  analogWrite(speedBpin, turnVar);  // Set both motors to full speed
  //Serial.println(userInput);

}


void dontmove() {
  analogWrite(speedApin, 0);
  analogWrite(speedBpin, 0);
  digitalWrite(brakeApin, HIGH);
  digitalWrite(brakeBpin, HIGH);
  if (turn && !stopped) {
    servoStraight();
    stopped = true;
    turn = !turn;

  }
  else if (!turn && !stopped) {
    servoTurn();
    stopped = true;
    turn = !turn;
  }


  detachServos();
}

void loop() {

  // read the incoming byte:
  if (Serial.available()) {
    userInput = Serial.read();
    Serial.println(userInput);
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
  if (turn && !stopped && turnVar >= turnMin) { //slow down over the course of the turn to reduce acceleration
    turnVar -= 20;
    analogWrite(speedApin, turnVar);
    analogWrite(speedBpin, turnVar);
    delay(1);

  }
}
