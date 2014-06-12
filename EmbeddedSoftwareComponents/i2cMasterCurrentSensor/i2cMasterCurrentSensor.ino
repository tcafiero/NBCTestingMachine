#include <Wire.h>
#include <stdio.h>
#define N_ADC 6

unsigned int Raw[N_ADC];
byte Wave[N_ADC];
byte Edge[N_ADC];

byte ClockCmd = 'c';
byte RawReq = 'd';
byte WaveReq = 'w';
byte EdgeReq = 'e';

int myputc(char c, FILE *)
{
  Serial.write(c);
  return 0;
}

void setup()
{
  fdevopen(&myputc, NULL);
  Wire.begin();        // join i2c bus (address optional for master)
  Serial.begin(115200);  // start serial for output
  printf("Holistic Systems\n\r");
}

void loop()
{
  byte i;
  #if 0
  Wire.beginTransmission(1);
  Wire.write(RawReq);             // sends value byte
  Wire.endTransmission();     // stop transmitting
  delay(1000);
  Wire.requestFrom(1, 12);    // request 6 bytes from slave device #2
  char *ptr=(char *)Raw;
  for (int i = 0 ; i < 12;)   // slave may send less than requested
  {
    if (Wire.available())
    {
      int val=Wire.read();
//      Serial.print(val, HEX);
      ptr[i++] = val; // receive a byte as character
      }
  }
//  Serial.println(";");
  printf("%-2x, %-2x, %-2x, %-2x, %-2x, %-2x\n\r", Raw[0], Raw[1], Raw[2], Raw[3], Raw[4], Raw[5]);
  #endif
  
  Wire.beginTransmission(1);
  Wire.write(WaveReq);             // sends value byte
  Wire.endTransmission();     // stop transmitting
  delay(100);
  Wire.requestFrom(1, 6);    // request 6 bytes from slave device #2
  for (int i = 0 ; i < 6;)   // slave may send less than requested
  {
    if (Wire.available())
    {
      int val=Wire.read();
      Wave[i++] = val; // receive a byte as character
      }
  }
  printf("%-1x, %-1x, %-1x, %-1x, %-1x, %-1x\n\r", Wave[0], Wave[1], Wave[2], Wave[3], Wave[4], Wave[5]);
}
