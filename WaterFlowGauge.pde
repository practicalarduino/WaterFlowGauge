/**
 * Water Flow Gauge
 *
 * Uses a hall-effect flow sensor to measure the rate of water flow and
 * output it via the serial connection once per second. The hall-effect
 * sensor connects to pin 2 and uses interrupt 0, and an LED on pin 13
 * pulses with each interrupt. Two volume counters and current flow rate
 * are also displayed on a 2-line by 16-character LCD module, and the
 * accumulated totals are stored in non-volatile memory to allow them to
 * continue incrementing after the device is reset or is power-cycled.
 *
 * Two counter-reset buttons are provided to reset the two accumulating
 * counters. This allows one counter to be left accumulating indefinitely
 * as a "total" flow volume, while the other can be reset regularly to
 * provide a counter for specific events such as having a shower, running
 * an irrigation system, or filling a washing machine.
 *
 * Copyright 2009 Jonathan Oxer <jon@oxer.com.au>
 * Copyright 2009 Hugh Blemings <hugh@blemings.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version. http://www.gnu.org/licenses/
 *
 * www.practicalarduino.com/projects/water-flow-gauge
123456789abcdef
1239.4L 8073.4L
 */

#include <LiquidCrystal.h>
// initialize the library with the numbers of the interface pins
LiquidCrystal lcd(9, 8, 7, 6, 5, 4);

// Specify the pins for the two counter reset buttons and indicator LED
byte resetButtonA = 11;
byte resetButtonB = 12;
byte statusLed    = 13;

byte sensorInterrupt = 0;  // 0 = pin 2; 1 = pin 3
byte sensorPin       = 2;

// The hall-effect flow sensor outputs approximately 4.5 pulses per second per
// litre/minute of flow.
float calibrationFactor = 4.5;

volatile byte pulseCount;  

float flowRate;
unsigned int flowMilliLitres;
unsigned long totalMilliLitresA;
unsigned long totalMilliLitresB;

unsigned long oldTime;

void setup()
{
  lcd.begin(16, 2);
  lcd.setCursor(0, 0);
  lcd.print("                ");
  lcd.setCursor(0, 1);
  lcd.print("                ");
  
  // Initialize a serial connection for reporting values to the host
  Serial.begin(38400);
   
  // Set up the status LED line as an output
  pinMode(statusLed, OUTPUT);
  digitalWrite(statusLed, HIGH);  // We have an active-low LED attached
  
  // Set up the pair of counter reset buttons and activate internal pull-up resistors
  pinMode(resetButtonA, INPUT);
  digitalWrite(resetButtonA, HIGH);
  pinMode(resetButtonB, INPUT);
  digitalWrite(resetButtonB, HIGH);
  
  pinMode(sensorPin, INPUT);
  digitalWrite(sensorPin, HIGH);

  pulseCount        = 0;
  flowRate          = 0.0;
  flowMilliLitres   = 0;
  totalMilliLitresA = 0;
  totalMilliLitresB = 0;
  oldTime           = 0;

  // The Hall-effect sensor is connected to pin 2 which uses interrupt 0.
  // Configured to trigger on a FALLING state change (transition from HIGH
  // state to LOW state)
  attachInterrupt(sensorInterrupt, pulseCounter, FALLING);
}

/**
 * Main program loop
 */
void loop()
{
  if(digitalRead(resetButtonA) == LOW)
  {
    totalMilliLitresA = 0;
    lcd.setCursor(0, 1);
    lcd.print("0L      ");
  }
  if(digitalRead(resetButtonB) == LOW)
  {
    totalMilliLitresB = 0;
    lcd.setCursor(8, 1);
    lcd.print("0L      ");
  }
  
  if( (digitalRead(resetButtonA) == LOW) || (digitalRead(resetButtonB) == LOW) )
  {
    digitalWrite(statusLed, LOW);
  } else {
    digitalWrite(statusLed, HIGH);
  }
  
  if((millis() - oldTime) > 1000)    // Only process counters once per second
  { 
    // Disable the interrupt while calculating flow rate and sending the value to
    // the host
    detachInterrupt(sensorInterrupt);
    //lcd.setCursor(15, 0);
    //lcd.print("*");
    
    // Because this loop may not complete in exactly 1 second intervals we calculate
    // the number of milliseconds that have passed since the last execution and use
    // that to scale the output. We also apply the calibrationFactor to scale the output
    // based on the number of pulses per second per units of measure (litres/minute in
    // this case) coming from the sensor.
    flowRate = ((1000.0 / (millis() - oldTime)) * pulseCount) / calibrationFactor;
    
    // Note the time this processing pass was executed. Note that because we've
    // disabled interrupts the millis() function won't actually be incrementing right
    // at this point, but it will still return the value it was set to just before
    // interrupts went away.
    oldTime = millis();
    
    // Divide the flow rate in litres/minute by 60 to determine how many litres have
    // passed through the sensor in this 1 second interval, then multiply by 1000 to
    // convert to millilitres.
    flowMilliLitres = (flowRate / 60) * 1000;
    
    // Add the millilitres passed in this second to the cumulative total
    totalMilliLitresA += flowMilliLitres;
    totalMilliLitresB += flowMilliLitres;
  
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
    Serial.print(int(flowRate));  // Print the integer part of the variable
    Serial.print(".");             // Print the decimal point
    // Determine the fractional part. The 10 multiplier gives us 1 decimal place.
    frac = (flowRate - int(flowRate)) * 10;
    Serial.print(frac, DEC) ;      // Print the fractional part of the variable

    // Print the number of litres flowed in this second
    Serial.print(" ");             // Output separator
    Serial.print(flowMilliLitres);

    // Print the cumulative total of litres flowed since starting
    Serial.print(" ");             // Output separator
    Serial.print(totalMilliLitresA);
    Serial.print(" ");             // Output separator
    Serial.println(totalMilliLitresB);
    
    lcd.setCursor(0, 0);
    lcd.print("                ");
    lcd.setCursor(0, 0);
    lcd.print("Flow: ");
    if(int(flowRate) < 10)
    {
      lcd.print(" ");
    }
    lcd.print((int)flowRate);   // Print the integer part of the variable
    lcd.print('.');             // Print the decimal point
    lcd.print(frac, DEC) ;      // Print the fractional part of the variable
    lcd.print(" L");
    lcd.print("/min");
    
    lcd.setCursor(0, 1);
    lcd.print(int(totalMilliLitresA / 1000));
    lcd.print("L");
    lcd.setCursor(8, 1);
    lcd.print(int(totalMilliLitresB / 1000));
    lcd.print("L");

    // Reset the pulse counter so we can start incrementing again
    pulseCount = 0;
    
    // Enable the interrupt again now that we've finished sending output
    attachInterrupt(sensorInterrupt, pulseCounter, FALLING);
  }
}

/**
 * Invoked by interrupt0 once per rotation of the hall-effect sensor. Interrupt
 * handlers should be kept as small as possible so they return quickly.
 */
void pulseCounter()
{
  // Increment the pulse counter
  pulseCount++;
}
