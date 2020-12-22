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

const int dirApin = 12; // The pin controllin the direction of the A motors
const int dirBpin = 13; // Pin controlling direction of B motors
const int speedApin = 3; // Pin controlling speed of A motors (via PWM)
const int speedBpin = 11; // Pin controlling speed of B motors
const int turnSpeed = 175 ; // variable to set motor speed
const int driveSpeed = 175;

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
  attachServos();
  servo1.write(75); // 4 
  servo2.write(120); // 5 
  servo3.write(75); // 6 
  servo4.write(100); // 7 
}

void servoStraight() {
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
  analogWrite(speedBpin, driveSpeed);  // Set both motors to full speed
  Serial.println(userInput);
}

void forward() {
  servoStraight();
  // Moves the rover backwards for 5 seconds
  digitalWrite(brakeApin, LOW);
  digitalWrite(brakeBpin, LOW);
  digitalWrite(dirApin, HIGH);
  digitalWrite(dirBpin, HIGH);  // Set both motors to backwards
  analogWrite(speedApin, turnSpeed);
  analogWrite(speedBpin, turnSpeed);  // Set both motors to full speed
  Serial.println(userInput);
}

void turnLeft() {

  servoTurn();
  // Turns rover to the left
  digitalWrite(brakeApin, LOW);
  digitalWrite(brakeBpin, LOW);
  digitalWrite(dirApin, LOW); // A side moves forward, B side backwards
  digitalWrite(dirBpin, HIGH);
  analogWrite(speedApin, turnSpeed);
  analogWrite(speedBpin, turnSpeed);  // Set both motors to full speed
  Serial.println(userInput);
}

void turnRight() {

  servoTurn();
  digitalWrite(brakeApin, LOW);
  digitalWrite(brakeBpin, LOW);
  // Turns rover to the right
  digitalWrite(dirApin, HIGH);   // A side moves backwards, B side forwards
  digitalWrite(dirBpin, LOW);
  analogWrite(speedApin, turnSpeed);
  analogWrite(speedBpin, turnSpeed);  // Set both motors to full speed
  Serial.println(userInput);

}


void dontmove() {
  detachServos();
  digitalWrite(brakeApin, HIGH);
  digitalWrite(brakeBpin, HIGH);
  digitalWrite(dirApin, HIGH);
  digitalWrite(dirBpin, HIGH);
  analogWrite(speedApin, 0);
  analogWrite(speedBpin, 0);
}

void loop() {

  // read the incoming byte:
  if (Serial.available()) {
    userInput = Serial.read();
    //Serial.println(userInput);
    //    delay(delay_time);


    // ACSCII 'f' is 102 - this moves the rover forward
    if (userInput == 102) {
      forward();
    }
    // ACSCII 'b' is 98 - this moves the rover backwards
    if (userInput == 98) {
      backwards();
    }
    // ACSCII 'l' is 108 - this moves the rover left
    if (userInput == 108) {
      turnLeft();
    }
    // ACSCII 'r' is 114 - this moves the rover right
    if (userInput == 114) {
      turnRight();
    }
    if (userInput == 32) { //space
      dontmove();
    }
  }

}
