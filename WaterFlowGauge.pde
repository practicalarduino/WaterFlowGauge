/**
 * WaterFlowGauge
 *
 * Uses a hall-effect flow sensor to measure the rate of water flow and
 * output it via the serial connection once per second. The hall-effect
 * sensor connects to pin 2 and uses interrupt 0, and an LED on pin 13
 * pulses with each interrupt.
 *
 * Copyright 2009 Jonathan Oxer <jon@oxer.com.au>
 * www.practicalarduino.com/projects/easy/water-flow-gauge
 */

// The hall-effect flow sensor outputs approximately 4.5 pulses per second per
// litre/minute of flow.
float calibrationFactor = 4.5;

int statusLed = 13;    // LED connected to digital pin 13

volatile byte pulseCount;
float flowRate;
unsigned long oldTime;

void setup()
{
  // Initialize a serial connection for reporting values to the host
  Serial.begin(38400);

  // The hall-effect sensor is connected to pin 2 which uses interrupt 0.
  // Configured to trigger on a FALLING state change (transition from HIGH
  // state to LOW state)
  attachInterrupt(0, pulse_counter, FALLING);

  // Set up the status LED line as an output
  pinMode(statusLed, OUTPUT);

  pulseCount = 0;
  flowRate   = 0;
  oldTime    = 0;
}


/**
 * Main program loop
 */
void loop()
{
  int whole, fract;
  // Update output value every second
  delay(1000);

  // Disable interrupt while calculating flow rate and sending value
  detachInterrupt(0);

  // Because this loop may not complete in exactly 1 second intervals we
  // calculate the number of milliseconds that have passed since the
  // last execution and use that to scale the output. We also apply the
  // calibrationFactor to scale the output based on the number of pulses
  // per second per units of measure (liters/minute in this case) coming
  // from the sensor.
  //flowRate = ((1000.0 / (millis() - oldTime)) * pulseCount) / calibrationFactor;

  // During testing it can be useful to output the literal pulse count
  // value so you can compare that and the calculated flow rate against
  // the data sheets for the flow sensor. Uncomment the following two
  // lines to display the raw count value.
  Serial.print(pulseCount, DEC);
  Serial.print("  ");

  // Write the calculated value to the serial port. Because we want to
  // output a floating point value and print() can't handle floats we
  // have to do some trickery to output the whole number part, then a
  // decimal point, then the fractional part.
  /*Serial.print(int(flowRate)); // Print the integer part of the variable
  Serial.print(".");           // Print the decimal point
  unsigned int frac;
  // Determine the fractional part. The "* 100" gives 2 decimal places
  frac = (flowRate - int(flowRate)) * 100;
  Serial.println(frac, DEC) ;  // Print the fractional part
  */
  // Reset the pulse counter and the time to start incrementing again
  pulseCount = 0;
  oldTime = millis();

  // Enable the interrupt again now that we've finished sending output
  attachInterrupt(0, pulse_counter, FALLING);
}


/**
 * Invoked by interrupt0 once per rotation of the hall-effect sensor.
 * Interrupt handlers should be kept as small as possible so they
 * return quickly
 */
void pulse_counter()
{
  // Increment the pulse counter
  pulseCount++;

  // Toggle the state of the status LED
  digitalWrite(statusLed, !digitalRead(statusLed));
}
