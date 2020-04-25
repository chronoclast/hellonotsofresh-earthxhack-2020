/* ----------------------------------------------------------------------------
PROJECT: Hello(NotSo)Fresh | EarthxHack online event (April 24-26, 2020)
DESCRIPTION:
  Supermarket monitoring sensors to keep track of the stocks and the shelf time
  of each product. The data is sent regularly to the Adafruit IO platform.
  The publishing functionality for the Adafruit platform is based on the
  "Adafruit IO Publish & Subscribe Example", by Todd Treece.
CHANGELOG:
  0.0 | Tracking stock and shelf time for one product (in the middle of the
      | shelf).
---------------------------------------------------------------------------- */

#include "config.h"

#define IO_LOOP_DELAY 5000
unsigned long lastUpdate = 0;

// Variables to store the stocks and the shelf times locally.
bool stock_middle = false;
int time_middle = 0;

// Set up the feeds.
AdafruitIO_Feed *stock_middle_feed = io.feed("stock_middle");
AdafruitIO_Feed *time_middle_feed = io.feed("time_middle");

// Pin for the ultrasound sensor.
const int pingPin = 4;

void setup() {

  // Start the serial connection and wait for it to open.
  Serial.begin(115200);
  while(! Serial);

  // Connect to the Adafruit platform (io.adafruit.com).
  Serial.print("Connecting to Adafruit IO");
  io.connect();

  // Wait for the connection to establish.
  while(io.status() < AIO_CONNECTED) {
    Serial.print(".");
    delay(500);
  }

  // Connection successful; print the status message and get the feeds.
  Serial.println();
  Serial.println(io.statusText());
  stock_middle_feed->get();

}

void loop() {

  // io.run(); is required for all sketches.
  // it should always be present at the top of your loop
  // function. it keeps the client connected to
  // io.adafruit.com, and processes any incoming data.
  io.run();

  // Variables for the duration of the "ping" and the distance in cm.
  long duration;
  int cm;

  // The PING))) is triggered by a HIGH pulse of 2 or more microseconds.
  // Give a short LOW pulse beforehand to ensure a clean HIGH pulse:
  pinMode(pingPin, OUTPUT);
  digitalWrite(pingPin, LOW);
  delayMicroseconds(2);
  digitalWrite(pingPin, HIGH);
  delayMicroseconds(5);
  digitalWrite(pingPin, LOW);

  // The same pin is used to read the signal from the PING))): a HIGH pulse
  // whose duration is the time (in microseconds) from the sending of the ping
  // to the reception of its echo off of an object.
  pinMode(pingPin, INPUT);
  duration = pulseIn(pingPin, HIGH);

  // Convert the time into distance in cm.
  cm = microsecondsToCentimeters(duration);

  // If a bag is detected in the middle of the shelf, it that there's stock.
  // Otherwise 
  if (cm <= 25) {
    stock_middle = true;
  } else {
    stock_middle = false;
    time_middle = 0;
  }

  Serial.print("[DEBUG] Distance (cm): ");
  Serial.println(cm);

  delay(1000);


  if (millis() > (lastUpdate + IO_LOOP_DELAY)) {
    // Publish the feeds onto the Adafruit platform.
    Serial.print("[INFO] Middle stock: ");
    if (stock_middle == true) {
      Serial.println("YES");
    } else {
      Serial.println("NO");
    }
    stock_middle_feed->save(stock_middle);
    Serial.print("[INFO] Middle shelf time: ");
    Serial.println(time_middle);
    time_middle_feed->save(time_middle);

    // After publishing, store the current time.
    lastUpdate = millis();
    
    // Increase the shelf time of all products according to the loop delay.
    // This one is given in ms, so it's converted to s.
    time_middle += IO_LOOP_DELAY/1000;
  }

}

long microsecondsToCentimeters(long microseconds) {
  // The speed of sound is 340 m/s or 29 microseconds per centimeter.
  // The ping travels out and back, so to find the distance of the object we
  // take half of the distance travelled.
  return microseconds / 29 / 2;
}
