/********************************************************
   PID Basic Example
   Reading analog input 0 to control analog PWM output 3
 ********************************************************/

#include <PID_v2.h>
#include <Encoder.h>
Encoder lEnc(3, 6);
Encoder rEnc(2, 5);


//motor shield pin map
int nD2 = 4; //Tri-state disables both outputs of both motor channels when LOW;
int M1DIR = 7; //Motor 1 direction input
int M1PWM = 9; //Motor 1 speed input
int M2DIR = 8; //Motor 2 direction input
int M2PWM = 10; //Motor 2 speed input
long lSetpoint;
long rSetpoint;

// Specify the links and initial tuning parameters
double Kp = .5, Ki = .01, Kd = 0.05;
PID_v2 lPID(Kp, Ki, Kd, PID::Direct);
PID_v2 rPID(Kp, Ki, Kd, PID::Direct);

void setup() {
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
             -3000);                   // setpoint
  rPID.Start(rEnc.read(),  // input
             0,                      // current output
             3000);                   // setpoint

}

void loop() {

  const double lInput = lEnc.read();
  const double lOutput = lPID.Run(lInput);
  const double rInput = rEnc.read();
  const double rOutput = rPID.Run(rInput);

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

}
