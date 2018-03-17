import controlP5.*;
import processing.serial.*;
import cc.arduino.*;
import arduinoscope.*;

Arduino arduino;
ControlP5 cp5;
Oscilloscope[] scopes = new Oscilloscope[5]; //number of channels
float multiplier;
boolean keypause = false;
int Logic_pin[] = {8, 9, 10, 11}; // pin 10 for 1; pin 9 for 2
char input_key[] = {'q', 'w', 'e', 'r'};
int Logic_bit[] = {arduino.LOW, arduino.LOW, arduino.LOW, arduino.LOW}; 
String A[] = {"S0","S1","C1", "E","E"};

void setup() {
  size(900, 730); //change cavuns
  ControlP5 cp5 = new ControlP5(this);
  frame.setTitle("Arduinoscope");

  // COM dropdown
  DropdownList com = cp5.addDropdownList("com")
    .setPosition(110, 20)
    .setSize(200, 200);



  String[] arduinos = arduino.list();
  for (int i=0; i<arduinos.length; i++) {
    com.addItem(arduinos[i], i);
  }
  int[] dim = { width-130, height/scopes.length-10};//change channel height

  for (int i=0; i<scopes.length; i++) {
    int[] posv = new int[2];
    posv[0]=0;
    posv[1]=dim[1]*i+30;//change channel position

    // random color, that will look nice and be visible
    scopes[i] = new Oscilloscope(this, posv, dim);
    scopes[i].setLine_color(color((int)random(255), (int)random(127)+127, 255));

    cp5.addButton("pause" + i)
      .setLabel("pause")
      .setValue(i)
      .setPosition(dim[0]+10, posv[1] + 100)
      .updateSize();

    scopes[i].setPause(false);
  }
  // multiplier comes from 1st scope
  multiplier = scopes[0].getMultiplier()/scopes[0].getResolution();
}

void draw() {
  background(0);
  text("arduinoscope", 20, 20);

  int val;
  int[] dim;
  int[] pos;
  for (int i=0; i<scopes.length; i++) {
    dim = scopes[i].getDim();
    pos = scopes[i].getPos();
    scopes[i].drawBounds();
    stroke(127); 
    strokeWeight(1);
    line(0, pos[1]+8+dim[1], width, pos[1]+8+dim[1]);
    strokeWeight(2); //make signal lines thicker
    if (arduino != null) {
      val = arduino.analogRead(i)*9/10;
      scopes[i].addData(val);
      scopes[i].draw();
      val= val*10/9;
      textSize(20);
      text(A[i], dim[0]+10, pos[1]+40);
      textSize(45);
      text(round(val*multiplier) + "V", dim[0]+10, pos[1] + 85);
      //     text("min: " + (scopes[i].getMinval()*multiplier) + "V", dim[0]+10, pos[1] + 60);
      //      text("max: " + (scopes[i].getMaxval()*multiplier) + "V", dim[0]+10, pos[1] + 75);
      textSize(12);
    }
  }
}


void controlEvent(ControlEvent theEvent) {
  int val = int(theEvent.getValue());

  if (theEvent.getName() == "com") {
    arduino = new Arduino(this, Arduino.list()[val], 57600);
    for (int i=0; i<Logic_pin.length; i++)
      arduino.pinMode(Logic_pin[i], arduino.OUTPUT);
  } else {
    scopes[val].setPause(!scopes[val].isPause());
  }
}

void keyPressed() {

  for (int i=0; i<Logic_pin.length; i++) {
    if (key == input_key[i])
      arduino.digitalWrite(Logic_pin[i], arduino.HIGH);
  }
  if (keyCode == TAB) {
    keypause = !keypause;
    if (keypause) {
      noLoop();
    } else {
      loop();
    }
  }
}

void keyReleased() {
  for (int i=0; i<Logic_pin.length; i++) {
    if (key == input_key[i])
      arduino.digitalWrite(Logic_pin[i], arduino.LOW);
  }
}