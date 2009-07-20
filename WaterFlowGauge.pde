/**
 * Water Flow Gauge
 *
 * Uses a hall-effect flow sensor to measure the rate of water flow and
 * output it via the serial connection once per second. The hall-effect
 * sensor connects to pin 2 and uses interrupt 0, and an LED on pin 13
 * pulses with each interrupt.
 *
 * Copyright 2009 Jonathan Oxer <jon@oxer.com.au>
 * Copyright 2009 Hugh Blemings <hugh@blemings.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version. http://www.gnu.org/licenses/
 *
 * www.practicalarduino.com/projects/easy/water-flow-gauge
 */

byte statusLed = 13;    // LED connected to digital pin 13

// The hall-effect flow sensor outputs approximately 4.5 pulses per second per
// litre/minute of flow.
float calibrationFactor = 4.5;

volatile byte pulseCount;  

float flowRate;
float flowLitres;
float totalLitres;

unsigned long oldTime;

void setup()
{
  // Initialize a serial connection for reporting values to the host
  Serial.begin(38400);

  // The Hall-effect sensor is connected to pin 2 which uses interrupt 0.
  // Configured to trigger on a FALLING state change (transition from HIGH
  // state to LOW state)
  attachInterrupt(0, pulse_counter, FALLING);
   
  // Set up the status LED line as an output
  pinMode(statusLed, OUTPUT);

  pulseCount  = 0;
  flowRate    = 0.0;
  flowLitres  = 0.0;
  totalLitres = 0.0;
  oldTime     = 0;
}

/**
 * Main program loop
 */
void loop()
{
  // Disable the interrupt while calculating flow rate and sending the value to
  // the host
  detachInterrupt(0);
  
  // Because this loop may not complete in exactly 1 second intervals we calculate
  // the number of milliseconds that have passed since the last execution and use
  // that to scale the output. We also apply the calibrationFactor to scale the output
  // based on the number of pulses per second per units of measure (litres/minute in
  // this case) coming from the sensor.
  flowRate = ((1000.0 / (millis() - oldTime)) * pulseCount) / calibrationFactor;
  
  // Divide the flow rate in litres/minute by 60 to determine how many litres have
  // passed through the sensor in this 1 second interval.
  flowLitres = flowRate / 60;
  
  // Add the litres passed in this second to the cumulative total
  totalLitres += flowLitres;

  // During testing it can be useful to output the literal pulse count value so you
  // can compare that and the calculated flow rate against the data sheets for the
  // flow sensor. Uncomment the following two lines to display the count value.
  //Serial.print(pulseCount, DEC);
  //Serial.print("  ");
  
  // Write the calculated value to the serial port. Because we want to output a
  // floating point value and print() can't handle floats we have to do some trickery
  // to output the whole number part, then a decimal point, then the fractional part.
  unsigned int frac;
  
  // Print the flow rate for this second in litres / minute
  Serial.print(int(flowRate));   // Print the integer part of the variable
  Serial.print(".");             // Print the decimal point
  // Determine the fractional part. The 100 multiplier gives us 2 decimal places.
  frac = (flowRate - int(flowRate)) * 100;
  Serial.print(frac, DEC) ;      // Print the fractional part of the variable

  // Print the number of litres flowed in this second
  Serial.print(" ");             // Output separator
  Serial.print(int(flowLitres));
  Serial.print(".");
  frac = (flowLitres - int(flowLitres)) * 100;
  Serial.print(frac, DEC) ;      // Print the fractional part of the variable

  // Print the cumulative total of litres flowed since starting
  Serial.print(" ");             // Output separator
  Serial.print(int(totalLitres));
  Serial.print(".");
  frac = (totalLitres - int(totalLitres)) * 100;
  Serial.println(frac, DEC) ;    // Print the fractional part of the variable

  // Reset the pulse counter and the time so we can start incrementing again
  pulseCount = 0;
  
  // Enable the interrupt again now that we've finished sending output
  attachInterrupt(0, pulse_counter, FALLING);

  // Update values every second
  delay(1000);
}

/**
 * Invoked by interrupt0 once per rotation of the hall-effect sensor. Interrupt
 * handlers should be kept as small as possible so they return quickly.
 */
void pulse_counter()
{
  // Increment the pulse counter
  pulseCount++;
  
  // Toggle the state of the status LED
  digitalWrite(statusLed, !digitalRead(statusLed));
}
