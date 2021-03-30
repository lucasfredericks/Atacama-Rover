
//define where your pins are
int latchPin = 8;
int dataPin = 10;
int clockPin = 9;
const byte interruptPin = 3;
volatile boolean button;

const int rows = 6;

uint8_t mainQueue [rows] = {0, 0, 0, 0, 0, 0};
uint8_t funcQueue [rows] = {0, 0, 0, 0, 0, 0};
uint8_t rightCompare = 15; //binary 00001111
boolean wait;
boolean function;
int mainCt;
int funcCt;
volatile int strokes;
boolean debug = false;

String commandLookup[16] = {
  /* Each shift register reads one byte from two code readers of four bits (i.e. a nibble) each.
     shiftIn() separates the two nibbles into two bytes where the first four digits are always zero,
     and the last four digits indicate the binary state of the four directional switches (W,S,E,N).

     Therefore, there are sixteen possible values per block reader (2^4), which we can
     refer to by integers 0-15.

     Since we are taking orientation into account for some commands
     but not others, there will be redundancy (i.e. a FUNC can be rotated to W,E or S,N,
     but will still resolve to the same command, but a Drive block can be rotated to N, E, S, or W,
     and each orientation will resolve to a unique directional command).
  */

  //char         bin    int   ascii   command
  " ",      // 0000,  0     32      undefined
  "n",      // 0001,  1     110     north
  "e",      // 0010,  2     101     east
  "d",      // 0011,  3     100     drill
  "s",      // 0100,  4     115     south
  "f",      // 0101,  5     102     function
  "d",      // 0110,  6     100     drill
  " ",      // 0111,  7     32      undefined
  "w",      // 1000,  8     119     west
  "d",      // 1001,  9     200     drill
  "f",      // 1010,  10    102     function
  " ",      // 1011,  11    32      undefined
  "d",      // 1100,  12    200     drill
  " ",      // 1101,  13    32      undefined
  " ",      // 1110,  14    32      undefined
  " ",      // 1111,  15    32      undefined
};
void clearQueue() {
  mainCt = 0;
  funcCt = 0;
  for (int i = 0; i < rows; i++) { //clear the queues
    mainQueue[i] = 0;
    funcQueue[i] = 0;
  }
}

String sendCommand() {

  String cmd = commandLookup[mainQueue[queueCt]];
  if (cmd == "FUNC") {
    sendFuncComands();
  }
  else if (cmd != " ") {
    Serial.println(cmd);
  }
}
}
void sendFuncComands() {
  for (int funcCt = 0; funcCt < rows; funcCt++) {
    String cmd = commandLookup[funcQueue[funcCt]];
    if (cmd != "FUNC" && cmd != " ") { //ignore recursive functions and unknown commands
      Serial.println(cmd);
      waitForResponse();
    }
  }
}

void waitForResponse() {
  while (!Serial.available()) {
  }
  if (Serial.available()) {
    uint8_t inByte = Serial.read();
    if (inByte = "ready") {
      return;
    }
    else if (inByte = "found") {
      resetCounter();
    }
  }
}
void resetCounter() {
  strokes = 0;
}

void shiftIn() {

  //Pulse the latch pin:
  //set it to 1 to collect parallel data
  digitalWrite(latchPin, 1);
  //set it to 1 to collect parallel data, wait
  delayMicroseconds(20);
  //set it to 0 to transmit data serially
  digitalWrite(latchPin, 0);


  //we will be holding the clock pin high at the
  //end of each time through the for loop

  //at the begining of each loop when we set the clock low, it will
  //be doing the necessary low to high drop to cause the shift
  //register's DataPin to change state based on the value
  //of the next bit in its serial information flow.

  uint8_t tempByte = 0;

  for (int j = 0; j < rows; j += 2) {
    for (int i = 0; i < 8; i ++) {
      digitalWrite(clockPin, 0);
      delayMicroseconds(2);
      boolean tempBool = digitalRead(dataPin);
      bitWrite(tempByte, i, tempBool);
      digitalWrite(clockPin, 1);
    }
    uint8_t rightNibble = tempByte & rightCompare;   // bitwise AND with 00001111 to extract the second nibble into its own byte
    uint8_t leftNibble = tempByte >> 4;              // bitshift right to extract the first nibble into its own byte
    mainQueue[j] = rightNibble;
    mainQueue[j + 1] = leftNibble;
    if (debug) {
      Serial.println (leftNibble, BIN);
      Serial.println(rightNibble, BIN);
    }
  }
  for (int j = 0; j < rows; j += 2) {
    for (int i = 0; i < 8; i ++) {
      digitalWrite(clockPin, 0);
      delayMicroseconds(2);
      boolean tempBool = digitalRead(dataPin);
      bitWrite(tempByte, i, tempBool);
      digitalWrite(clockPin, 1);
    }
    uint8_t rightNibble = tempByte & rightCompare;   // bitwise AND with 00001111 to extract the second nibble into its own byte
    uint8_t leftNibble = tempByte >> 4;              // bitshift right to extract the first nibble into its own byte
    funcQueue[j] = rightNibble;
    funcQueue[j + 1] = leftNibble;
    if (debug) {
      Serial.println (leftNibble, BIN);
      Serial.println(rightNibble, BIN);
    }
  }
}

void buttonPress() {
  detachInterrupt(digitalPinToInterrupt(interruptPin));
  button = true;
  strokes++;
  delay(20);
  attachInterrupt(digitalPinToInterrupt(interruptPin), buttonPress, FALLING);
}

void setup() {
  //start serial
  Serial.begin(9600);

  //define pin modes
  pinMode(latchPin, OUTPUT);
  pinMode(clockPin, OUTPUT);
  pinMode(dataPin, INPUT);
  pinMode(interruptPin, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(interruptPin), buttonPress, FALLING);

  strokes = 0;
  wait = true;
  button = false;
  function = false;
}


void loop() {

  if (button) {
    clearQueue();
    shiftIn();
  }
  if (!wait) {
    sendCommands();
  }
