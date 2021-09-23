//Import libraries:
#include <ServoTimer2.h>
#include <PID_v2.h>
#include <Encoder.h>

//Create objects
ServoTimer2 NEservo;
ServoTimer2 SWservo;
ServoTimer2 NWservo;
ServoTimer2 SEservo;

Encoder lEnc(3, 6);
Encoder rEnc(2, 5);


//motor shield pin map
int nD2 = 4; //Tri-state disables both outputs of both motor channels when LOW;
int M1DIR = 15;// 7; //Motor 1 direction input
int M1PWM = 9; //Motor 1 speed input
int M2DIR = 14;// 8; //Motor 2 direction input
int M2PWM = 10; //Motor 2 speed input

int NEservoPin = 7; //analog 5
int SWservoPin = 12; //analog 4
int NWservoPin = 8; //analog 3
int SEservoPin = 11; //analog 2

int servoNEStraight = 30;
int servoNETurn = 80;

int servoSWStraight = 30;
int servoSWTurn = 70;

int servoNWStraight = 130;
int servoNWTurn = 80;

int servoSEStraight = 130;
int servoSETurn = 90;


// Specify the links and initial tuning parameters for PID
double Kp = .55, Ki = .05, Kd = 0.05;
//PID_v2 lPID(Kp, Ki, Kd, PID::Direct, PID::P_On::Measurement);
//PID_v2 rPID(Kp, Ki, Kd, PID::Direct, PID::P_On::Measurement);

PID_v2 lPID(Kp, Ki, Kd, PID::Direct);
PID_v2 rPID(Kp, Ki, Kd, PID::Direct);


//Set up variables
long lSetpoint;
long rSetpoint;
float turnConst;
float ticksPermm;

long watchdog;
long sleepDelay;

boolean moveComplete = true;
boolean turn = false;
boolean sleeping = false;
const byte numChars = 8; //max array size for incoming serial data
char receivedChars[numChars]; //buffer to receive serial chars
float val = 0.0;
uint8_t dir = 0;
boolean newData = false;

void attachServos() {

  if (!NEservo.attached()) {
    NEservo.attach(NEservoPin);
  }
  if (!SWservo.attached()) {
    SWservo.attach(SWservoPin);
  }
  if (!SEservo.attached()) {
    SEservo.attach(SEservoPin);
  }
  if (!NWservo.attached()) {
    NWservo.attach(NWservoPin);
  }
}
void detachServos() {
  if (NEservo.attached()) {
    NEservo.detach();
  }
  if (SWservo.attached()) {
    SWservo.detach();
  }
  if (SEservo.attached()) {
    SEservo.detach();
  }
  if (NWservo.attached()) {
    NWservo.detach();
  }
}
void servoTurn() {

  /*The maximum pulsewidth is 2250 and minimum is 750.
    Which would mean 750 is for 0 degree and 2250 is for 180 degree.
  */
  turn = true;
  attachServos();
  NEservo.write(servoNETurn);
  SWservo.write(servoSWTurn);
  SEservo.write(servoSETurn);
  NWservo.write(servoNWTurn);
  delay(200);
}
void servoStraight() {
  turn = false;
  attachServos();
  NEservo.write(servoNEStraight);
  SWservo.write(servoSWStraight);
  SEservo.write(servoSEStraight);
  NWservo.write(servoNWStraight);
  delay(200);
}
void dontMove() {
  analogWrite(M1PWM, 0);
  analogWrite(M2PWM, 0);
  detachServos();
}
void recvWithEndMarker() {
  static byte ndx = 0;
  char endMarker = '\n';
  char rc;

  // if (Serial.available() > 0) {
  while (Serial.available() > 0 && newData == false) {
    rc = Serial.read();

    if (rc != endMarker) {
      receivedChars[ndx] = rc;
      ndx++;
      if (ndx >= numChars) {
        ndx = numChars - 1;
      }
    }
    else {
      receivedChars[ndx] = '\0'; // terminate the string
      ndx = 0;
      parseData();
    }
  }
}
void parseData() {

  // split the data into its parts

  char * strtokIndx; // this is used by strtok() as an index

  strtokIndx = strtok(receivedChars, ",");     // get the first part - the string
  //Serial.println(strtokIndx);
  dir = atoi(strtokIndx);
  //Serial.println(dir);

  strtokIndx = strtok(NULL, ",");
  val = atof(strtokIndx);     // convert this part to a float
  newData = true;

}
void setEncoderTargets(double lPosition, double rPosition) {
  //  Serial.println("setting encoder targets");
  //  Serial.println(dir);
  //  Serial.println(val);
  attachServos();


  if (dir == 'w') {
    servoStraight();
    int encDelta = int(val * ticksPermm);
    lSetpoint = lPosition - encDelta;
    rSetpoint = rPosition + encDelta;
    lPID.Setpoint(lSetpoint);
    rPID.Setpoint(rSetpoint);
    //    return true;
  }
  else if (dir == 'a' || dir == 'd') {
    servoTurn();
    int encDelta = int(val * turnConst);
    if (dir == 'a') {
      //Serial.println("turning left");
      lSetpoint = lPosition + encDelta;
      rSetpoint = rPosition + encDelta;
      lPID.Setpoint(lSetpoint);
      rPID.Setpoint(rSetpoint);
    }
    else if (dir == 'd') {
      lSetpoint = lPosition - encDelta;
      rSetpoint = rPosition - encDelta;
      lPID.Setpoint(lSetpoint);
      rPID.Setpoint(rSetpoint);
      //Serial.println("turning right");
    }
  }
  else {
    goToSleep();
  }
}
void setGeometryConsts() {
  float wheelDiam = 65;
  float wheelCircum = wheelDiam * PI;
  float wheelbaseRadius = 145;
  int ticksPerRev = 3840;
  ticksPermm = ticksPerRev / wheelCircum;
  turnConst = ticksPermm * wheelbaseRadius;
}

void setup() {

  servoNETurn = map(servoNETurn, 0, 180, 750, 2250);
  servoNWTurn = map(servoNWTurn, 0, 180, 750, 2250);
  servoSETurn = map(servoSETurn, 0, 180, 750, 2250);
  servoSWTurn = map(servoSWTurn, 0, 180, 750, 2250);

  servoNEStraight= map(servoNEStraight, 0, 180, 750, 2250);
  servoNWStraight= map(servoNWStraight, 0, 180, 750, 2250);
  servoSEStraight= map(servoSEStraight, 0, 180, 750, 2250);
  servoSWStraight= map(servoSWStraight, 0, 180, 750, 2250);

  Serial.begin(9600);
  lSetpoint = lEnc.read();
  rSetpoint = rEnc.read();
  setGeometryConsts();

  watchdog = millis();
  sleepDelay = millis();

  attachServos();
  servoStraight();
  while(false){
    servoTurn();
    delay(3000);
    servoStraight();
    delay(3000);    
  }

  pinMode(M1DIR, OUTPUT);
  pinMode(M1PWM, OUTPUT);
  pinMode(M2DIR, OUTPUT);
  pinMode(M2PWM, OUTPUT);

  digitalWrite(nD2, HIGH);
  digitalWrite(M1DIR, LOW);
  analogWrite(M1PWM, 0);
  digitalWrite(M2DIR, LOW);
  analogWrite(M2PWM, 0);

  lPID.SetOutputLimits(-200, 200);
  rPID.SetOutputLimits(-200, 200);

  lPID.Start(lEnc.read(),  // input
             0,                      // current output
             0);                   // setpoint
  rPID.Start(rEnc.read(),  // input
             0,                      // current output
             0);                   // setpoint

  rPID.SetMode(1);
  lPID.SetMode(1);
  pinMode(nD2, OUTPUT);
  digitalWrite(nD2, HIGH);
  goToSleep();

}
void goToSleep() {
  if (!sleeping) {

    Serial.println('r');
    digitalWrite(nD2, LOW);
    detachServos();
    lPID.SetMode(0);
    rPID.SetMode(0);
    delay(10);
    sleeping = true;
  }
}

void wakeUp() {
  moveComplete = false;
  if (sleeping) {
    digitalWrite(nD2, HIGH);
    attachServos();
    //Serial.println("waking up");
    lPID.SetMode(1);
    rPID.SetMode(1);
    watchdog = millis();
    sleeping = false;

  }
}

void loop() {

  const double lPosition = lEnc.read();
  const double rPosition = rEnc.read();

  if (millis() - watchdog >= 5000) { //30 second timer
    if (sleeping) {
      Serial.println('r');
    }
    goToSleep();
    watchdog = millis();
  }
  recvWithEndMarker();
  if (newData) {
    //Serial.println(dir);
    //Serial.println(val);
    newData = false;
    wakeUp();
    setEncoderTargets(lPosition, rPosition);
  }
  const double lInput = lEnc.read();
  const double lOutput = lPID.Run(lInput);
  const double rInput = rEnc.read();
  const double rOutput = rPID.Run(rInput);

  if (false && millis() % 300 == 0) { //debug print
    Serial.print("L: ");
    Serial.print(lSetpoint);
    Serial.print(", ");
    Serial.print(lPosition);
    Serial.print(", ");
    Serial.print(lInput);
    Serial.print(", ");
    Serial.println(lOutput);
    Serial.print("R: ");
    Serial.print(rSetpoint);
    Serial.print(", ");
    Serial.println(rPosition);
    Serial.print(", ");
    Serial.print(rInput);
    Serial.print(", ");
    Serial.println(rOutput);
    Serial.println(" ");
  }
  if (moveComplete == false) {
    if (rOutput < 0) {
      digitalWrite(M2DIR, LOW);
    }
    else {
      digitalWrite(M2DIR, HIGH);
    }
    if (lOutput < 0) {
      digitalWrite(M1DIR, LOW);
    }
    else {
      digitalWrite(M1DIR, HIGH);
    }

    analogWrite(M1PWM, abs(lOutput));
    analogWrite(M2PWM, abs(rOutput));

    if ((abs(lOutput) < 40) && (abs(rOutput) < 40)) {
      moveComplete = true;
      goToSleep();
    }
  }
}
