
#include <TinyWireM.h>                  // I2C Master lib for ATTinys which use USI
#include <stdio.h>

#define SLAVE           0x48           // 7 bit I2C address for SLAVE PC
#define SAMPLES         8
#define CONVERSION_TIME 1              // the right value would be 1/10000*1000
int CurrentSensor1=A2;
int CurrentSensor2=A3;
byte i;
int Current1, Current2, AverageCurrent1, AverageCurrent2;
byte SearchingFallingEdge;

void putstr(char string[])
{
  int i=0;
  while(string[i])
  {
  TinyWireM.beginTransmission(SLAVE);
  TinyWireM.send(string[i++]);
  TinyWireM.endTransmission();          // Send to the slave
  }
}

#include <stdarg.h>
void i2cprintf(char *fmt, ... ){
        char buf[128]; // resulting string limited to 128 chars
        va_list args;
        va_start (args, fmt );
        vsnprintf(buf, 128, fmt, args);
        va_end (args);
        putstr(buf);
}
void setup(){
  pinMode(CurrentSensor1, INPUT);
  pinMode(CurrentSensor2, INPUT);
  delay(1000);
  AverageCurrent1=0;
  AverageCurrent2=0;
  for(i=0; i < 50; i++)
  {
    AverageCurrent1 += analogRead(CurrentSensor1);
    AverageCurrent2 += analogRead(CurrentSensor2);
    delay(CONVERSION_TIME);
  }
  AverageCurrent1 /= 50;
  AverageCurrent2 /= 50;
  i=0;
  Current1=0;
  Current2=0;
  SearchingFallingEdge=0;
  TinyWireM.begin();                    // initialize I2C lib
}


void loop(){
  if(abs(analogRead(CurrentSensor2)-AverageCurrent2) < 2)
  {
  if(i++ >= SAMPLES)
  {
   i=0;
    if(!SearchingFallingEdge)
    {
    if(abs(Current1/SAMPLES-AverageCurrent1) >= 5)
    {
      i2cprintf("ON\n\r");
      SearchingFallingEdge=1;
    }
    }
    else
    {
    if(abs(Current1/SAMPLES-AverageCurrent1) < 3)
    {
      i2cprintf("OFF\n\r");
      SearchingFallingEdge=0;
    }
    }
 //   i2cprintf("Current1 = %d, Current2= %d\n\r", Current1/SAMPLES, Current2/SAMPLES);
    Current1=0;
    Current2=0;
  }
  else
  {
    Current1 += analogRead(CurrentSensor1);
    delay(CONVERSION_TIME);
  }
  delay(1);
  }
//  else p("Noise is present data invalid\n\r");
}




