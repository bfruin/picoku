// Sweep
// by BARRAGAN <http://barraganstudio.com> 
// This example code is in the public domain.


#include <Servo.h> 
 
Servo myservo;  // create servo object to control a servo 
                // a maximum of eight servo objects can be created 
char val; //Data received from the serial port 
int pos = 0;    // variable to store the servo position 
int pos2; //Data received from the servo
int servoPin = 7;
 
void setup() { 
  myservo.attach(9);  // attaches the servo on pin 9 to the servo object 
  Serial.begin(9600);
  pinMode(servoPin, INPUT);
} 
 
 
void loop() { 
  if (Serial.available()) {
    val = Serial.read();
  }
  myservo.write(val);
} 
