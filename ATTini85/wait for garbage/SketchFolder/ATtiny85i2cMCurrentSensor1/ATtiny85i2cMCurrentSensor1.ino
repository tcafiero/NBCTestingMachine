
#include <TinyWireM.h>                  // I2C Master lib for ATTinys which use USI
#include <stdio.h>

#define SLAVE           0x48           // 7 bit I2C address for SLAVE PC
int CurrentSensor1=A2;
int CurrentSensor2=A3;

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
void p(char *fmt, ... ){
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
  TinyWireM.begin();                    // initialize I2C lib
}


void loop(){
  long Current1=0;
  long Current2=0;
  for (int i=0; i < 10 ; i++)
  {
    Current1 += analogRead(CurrentSensor1);
    Current2 += analogRead(CurrentSensor2);
  }
  Current1 /= 1000;
  Current2 /= 1000;
  p("Current1 = %d, Current2 = %d\n\r", Current1, Current2);
}




