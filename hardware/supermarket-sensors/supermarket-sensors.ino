/* ----------------------------------------------------------------------------
PROJECT:
  Hello(NotSo)Fresh | EarthxHack online event (April 24-26, 2020)
DESCRIPTION:
  Supermarket monitoring sensors to keep track of the stocks and the shelf time
  of each product. The data is sent regularly to the Adafruit IO platform.
  The publishing functionality for the Adafruit platform is based on the
  "Adafruit IO Publish & Subscribe Example", by Todd Treece.
CHANGELOG:
  0.0 | Tracking stock and shelf time for one product (in the middle of the
      | shelf).
  1.0 | Added one more sensor (right of the shelf). Tracking two products now.
  1.1 | Publishing only the shelf times, the lines that apply to the stocks
      | have been commented. 
---------------------------------------------------------------------------- */

#include "config.h"

#define IO_LOOP_DELAY 5000
unsigned long lastUpdate = 0;

// Variables to store the stocks and the shelf times locally.
bool stock_middle = false;
int time_middle = 0;
bool stock_right = false;
int time_right = 0;

// Set up the feeds.
// AdafruitIO_Feed *stock_middle_feed = io.feed("stock_middle");
AdafruitIO_Feed *time_middle_feed = io.feed("time_middle");
// AdafruitIO_Feed *stock_right_feed = io.feed("stock_right");
AdafruitIO_Feed *time_right_feed = io.feed("time_right");

// Pin for the ultrasound sensor.
const int ping_pin = 4;
const int lux_pin = 34;

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
  // stock_middle_feed->get();
  time_middle_feed->get();
  // stock_right_feed->get();
  time_right_feed->get();

}

void loop() {

  // This function keeps the client connected to the Adafruit platform.
  // It must be always at the top of the main loop.
  io.run();


  // --- LOGIC FOR THE MIDDLE SHELF (using the ultrasound sensor) -------------
  // --------------------------------------------------------------------------
  // Variables for the duration of the "ping" and the distance in cm, used by
  // the ultrasound sensor.
  long duration;
  int distance_cm;

  // Variable to return the reading of the ADC, provided by the light sensor.
  float adc_voltage_lux;

  // The ultrasound sensor is triggered by a HIGH pulse of 2 or more
  // microseconds. A short LOW pulse beforehand ensures a clean HIGH pulse.
  pinMode(ping_pin, OUTPUT);
  digitalWrite(ping_pin, LOW);
  delayMicroseconds(2);
  digitalWrite(ping_pin, HIGH);
  delayMicroseconds(5);
  digitalWrite(ping_pin, LOW);

  // The same pin is used to read the signal from the PING))): a HIGH pulse
  // whose duration is the time (in microseconds) from the sending of the ping
  // to the reception of its echo off of an object.
  pinMode(ping_pin, INPUT);
  duration = pulseIn(ping_pin, HIGH);

  // Convert the time into distance in cm.
  distance_cm = microsecondsToCentimeters(duration);

  // If a bag is detected in the middle of the shelf, it means that there's
  // still enough in stock. Otherwise, the stock_middle flag will be toggled.
  if (distance_cm <= 25) {
    stock_middle = true;
  } else {
    stock_middle = false;
    time_middle = 0;
  }

  Serial.print("[DEBUG] Distance (cm): ");
  Serial.println(distance_cm);
  // --------------------------------------------------------------------------


  // --- LOGIC FOR THE RIGHT SHELF (using the luminosity sensor) --------------
  // --------------------------------------------------------------------------
  adc_voltage_lux = readAPDS9002Vout(lux_pin);

  // If there's produce in the right of the shelf, the bottom of the wooden box
  // will get darker. This means that there's still enough in stock of this
  // particular product. Otherwise, the stock_right flag will be toggled.
  if (adc_voltage_lux <= 0.10) {
    stock_right = true;
  } else {
    stock_right = false;
    time_right = 0;
  }

  Serial.print("[DEBUG] Luminosity, ADC Vout (V): ");
  Serial.println(adc_voltage_lux);
  // --------------------------------------------------------------------------


  // Values will be collected every second.
  delay(1000);

  if (millis() > (lastUpdate + IO_LOOP_DELAY)) {
    // Publish the feeds onto the Adafruit platform, first the middle stock.
    Serial.print("[INFO] Middle stock: ");
    if (stock_middle == true) {
      Serial.println("YES");
    } else {
      Serial.println("NO");
    }

    // stock_middle_feed->save(stock_middle);
    Serial.print("[INFO] Middle shelf time: ");
    Serial.println(time_middle);
    time_middle_feed->save(time_middle);

    // Then the right stock.
    Serial.print("[INFO] Right stock: ");
    if (stock_right == true) {
      Serial.println("YES");
    } else {
      Serial.println("NO");
    }

    // stock_right_feed->save(stock_right);
    Serial.print("[INFO] Right shelf time: ");
    Serial.println(time_right);
    time_right_feed->save(time_right);

    // After publishing, store the current time.
    lastUpdate = millis();
    
    // Increase the shelf time of all products according to the loop delay.
    // This one is given in milliseconds, so it's converted to seconds.
    time_middle += IO_LOOP_DELAY/1000;
    time_right += IO_LOOP_DELAY/1000;
  }

}

long microsecondsToCentimeters(long microseconds) {
  // The speed of sound is 340 m/s or 29 microseconds per centimeter.
  // The ping travels out and back, so to find the distance of the object we
  // take half of the distance travelled.
  return microseconds / 29 / 2;
}


float readAPDS9002Vout(uint8_t analogpin) {
    // MeasuredVout = ADC Value * (Vcc / 1023) * (3 / Vcc)
    // Vout samples are with reference to 3V Vcc
    // The above expression is simplified by cancelling out Vcc
    float MeasuredVout = analogRead(analogpin) * (3.0 / 1023.0);
    // Above 2.3V , the sensor value is saturated

    return MeasuredVout;
}
