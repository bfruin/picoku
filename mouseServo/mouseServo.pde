import processing.serial.*;

Serial port;

void setup() {
  size(180, 180);
  println(Serial.list());
  port = new Serial(this, Serial.list()[0], 9600);
}

void draw() {
    int xpos = mouseX;
    println("xpos: " + xpos);
    port.write(xpos);
    
}
