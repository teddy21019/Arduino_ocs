/*
A Square Generator that produces square wave with differnt phase shifts depending on 
the pins you use. Each is shifted equally.
*/
import controlP5.*;
import processing.serial.*;
import cc.arduino.*;
import arduinoscope.*;

Arduino arduino;
ControlP5 cp5;
Oscilloscope[] scopes = new Oscilloscope[5]; //number of channels
Textfield int_text ;
float multiplier;
boolean keypause = false;
boolean reset = true;
int[] clkPin = {8,9,10};// the pin number of the square wave generater
int numPin = clkPin.length;
int[] clkState = new int[numPin];
long[] previousMillis = new long[numPin];
long interval = 3000;   // time interval (milliseconds) for squarewave generator
long start_time = 0 ;
long[] www = {1,2,2};


void setup() {
  size(900, 730); //change cavuns
  ControlP5 cp5 = new ControlP5(this);
  frame.setTitle("Arduinoscope");

  // COM dropdown
  DropdownList com = cp5.addDropdownList("com")
    .setPosition(110, 20)
    .setSize(200, 200);

  //interval input for squarewave
  int_text = cp5.addTextfield("interval")
    .setPosition(300, 20)
    .setText(""+interval);

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
  for (int i=0; i<numPin; i++) {
    clkState[i] = arduino.LOW;
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

    //reset start time as arduino device detected
    if (arduino != null) {
      if (reset==true) {
        for (int j = 0; j<numPin; j++)
          previousMillis[j] = interval/numPin*j+millis();
        reset = false;
      }
      val = arduino.analogRead(i)*9/10;
      scopes[i].addData(val);
      scopes[i].draw();
      val= val*10/9;
      textSize(20);
      text("A" + i, dim[0]+10, pos[1]+40);
      textSize(45);
      text(round(val*multiplier) + "V", dim[0]+10, pos[1] + 85);
      //     text("min: " + (scopes[i].getMinval()*multiplier) + "V", dim[0]+10, pos[1] + 60);
      //      text("max: " + (scopes[i].getMaxval()*multiplier) + "V", dim[0]+10, pos[1] + 75);
      textSize(12);
      for (int j=0; j<numPin; j++) {
        long currentMillis = Long.valueOf(millis());
        if (currentMillis-previousMillis[j] >= interval*www[j]) {
          previousMillis[j] = currentMillis;
          if (clkState[j]==arduino.LOW) {
            clkState[j]=arduino.HIGH;
          } else {
            clkState[j] = arduino.LOW;
          }
          arduino.digitalWrite(clkPin[j], clkState[j]);
        }
      }
    }
  }
}


void controlEvent(ControlEvent theEvent) {
  int val = int(theEvent.getValue());
  if (theEvent.getName() == "com") {
    arduino = new Arduino(this, Arduino.list()[val], 57600);
    for (int i =0; i<numPin; i++) {
      arduino.pinMode(clkPin[i], arduino.OUTPUT);
    }
  } else {
    scopes[val].setPause(!scopes[val].isPause());
  }
}

void keyPressed() {
  if ((keyCode == UP)||(keyCode == ENTER)) {
    String input_field = int_text.getText();
    if (TryParse(input_field)) {
      setInterval(Long.parseLong(input_field));
      reset=true;
    }
    int_text.setText(""+interval);
  } else if (keyCode == TAB) {
    keypause = !keypause;
    if (keypause) {
      noLoop();
    } else {
      loop();
    }
  }
}


void mouseWheel(MouseEvent event) {
  long e = 100*event.getCount();
  setInterval(interval+e);
}

boolean TryParse(String value) {
  try {
    Long.parseLong(value);
    return true;
  }
  catch(NumberFormatException e) {
    return false;
  }
}
void setInterval(long value) {
  interval = value;
  print("clk period= ");
  print(2*interval);
  println(" (ms)");
  int_text.setText(""+interval);
}