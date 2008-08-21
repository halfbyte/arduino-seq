/*
 * Button
 * by DojoDave <http://www.0j0.org>
 *
 * Turns on and off a light emitting diode(LED) connected to digital  
 * pin 13, when pressing a pushbutton attached to pin 7. 
 *
 * http://www.arduino.cc/en/Tutorial/Button
 */
 
#define SER_PIN 8
#define LATCH_PIN 9
#define CLK_PIN 10
#define SPEED_PIN 5

int ledPins[8] = {2,3,4,5,6,7,11,12};


unsigned int val = 0;                    // variable for reading the pin status
unsigned int position = 0;

unsigned char patterns[7] = {1,0,0,0,0,0,0};
unsigned char notes[6] = {0x24, 0x26, 0x27, 0x2A, 0x2C, 0x31};

long time = 0;
int selectedTrack = 0;
int oldVal = 0;
void setup() {
  int i = 0;
  pinMode(LATCH_PIN, OUTPUT);      // declare LED as output
  pinMode(CLK_PIN, OUTPUT);      // declare LED as output
  pinMode(SER_PIN, INPUT);     // declare pushbutton as input
  Serial.begin(31250);
  //Serial.begin(9600);
  digitalWrite(LATCH_PIN, LOW);
  digitalWrite(CLK_PIN, LOW);
  for(i=0;i<8;i++) pinMode(ledPins[i], OUTPUT);
  time = millis();
}



int readButtons(void) {
  int i=0;
  int buttonField = 0;
  digitalWrite(LATCH_PIN, HIGH);
  asm("nop\n nop\n");

  for(i=15;i>=0;i--) {
    int bit = 0;
    bit = digitalRead(SER_PIN);
    if (bit == LOW) buttonField = buttonField | (1 << i);
    digitalWrite(CLK_PIN, LOW);
    asm("nop\n nop\n");
    digitalWrite(CLK_PIN, HIGH);
    asm("nop\n nop\n");

  }
  digitalWrite(LATCH_PIN, LOW);
  //asm("nop\n nop\n");
  return buttonField;
}

void noteOn(char cmd, char data1, char data2) {
  Serial.print(cmd, BYTE);
  Serial.print(data1, BYTE);
  Serial.print(data2, BYTE);
}


  void updateLeds(void) {
    int i=0;
    for(i=0;i<8;i++) {
      digitalWrite(ledPins[i], ((patterns[selectedTrack] & (1 << i))) ? HIGH : LOW);
    }     
  }


void loop(){
  int i=0;
  int speedVal = 0;
  //int notes[8] = {24,25,26,27,28,29,30,31};
  val = readButtons();
  if(val!=oldVal) {
    // trigger buttons
    for(i=0;i<8;i++) {
      if((val & (1 << i)) && (!(oldVal & (1 << i)))) {
         patterns[selectedTrack] ^= (1 << i);
         updateLeds();
      }
    }
    for(i=8;i<15;i++) {
      if((val & (1 << i)) && (!(oldVal & (1 << i)))) {
         selectedTrack = i - 8;
         updateLeds();
      }
    }
    
    oldVal = val;
  }

  
  // here goes seq code
  
  speedVal = analogRead(SPEED_PIN) / 2;
  if (millis() > (time + speedVal)) {
    //seq code;
    for(i=0;i<6;i++) {
     if(patterns[i] & (1 << position)) {
        int velo = 0x40;
        if (patterns[6] & (1 << position)) velo = 0x7F;
        noteOn(0x99, notes[i], velo);
        noteOn(0x99, notes[i], 0x00);
     }
    }
    position = (position +1) % 8;    
    time = millis();
  }
}
