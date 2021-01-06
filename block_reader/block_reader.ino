/* To add:
   wait for query from rover before sending a command (sleep the rover's xbee and wake up intermittently
        to see if the reader board wants to send a command


*/



//define where your pins are
int latchPin = 8;
int dataPin = 10;
int clockPin = 9;
const byte interruptPin = 3;

volatile boolean button;
volatile int strokes;
boolean debug = false;

const int rows = 12;
uint8_t queue [rows] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

uint8_t commandLookup[17] = {
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
  ' ',      // 0000,  0     32      undefined
  ' ',      // 0001,  1     32      undefined
  ' ',      // 0010,  2     32      undefined
  's',      // 0011,  3     115     scan
  ' ',      // 0100,  4     32      undefined
  'q',      // 0101,  5     113     function
  's',      // 0110,  6     115     scan
  'l',      // 0111,  7     108     left
  ' ',      // 1000,  8     32     undefined
  's',      // 1001,  9     115     scan
  'q',      // 1010,  10    113     function queue
  'b',      // 1011,  11    98      back
  's',      // 1100,  12    115     scan
  'r',      // 1101,  13    114     right
  'f',      // 1110,  14    102      forward
  ' ',      // 1111,  15    32      undefined
  16,     // 10000, 16    endbyte
};

void clearQueue() {
  for (int i = 0; i < rows; i++) { //clear the queues
    queue[i] = 0;
  }
}

void sendCommand() {
  Serial.write(queue, rows);
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

  uint8_t tempByte = 0;      //binary 00000000
  uint8_t rightCompare = 15; //binary 00001111

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
    queue[j] = commandLookup[rightNibble];
    queue[j + 1] = commandLookup[leftNibble];
    if (debug) {
      Serial.println (leftNibble, BIN);
      Serial.println(rightNibble, BIN);
    }

  }
  uint8_t interesting = 16;
  queue[11] = interesting; //block 12 is an endbyte
}
void setup() {
  //start serial
  Serial.begin(115200);

  //define pin modes
  pinMode(latchPin, OUTPUT);
  pinMode(clockPin, OUTPUT);
  pinMode(dataPin, INPUT);
  pinMode(interruptPin, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(interruptPin), buttonPress, FALLING);

  button = false;
  clearQueue();
}

void buttonPress() {
  detachInterrupt(digitalPinToInterrupt(interruptPin));
  button = true;

  delay(20);
  attachInterrupt(digitalPinToInterrupt(interruptPin), buttonPress, FALLING);
}
void loop() {

  if (button) {
    button = false;
    clearQueue();
    shiftIn();
    delay(10);
    sendCommand();
  }
}
