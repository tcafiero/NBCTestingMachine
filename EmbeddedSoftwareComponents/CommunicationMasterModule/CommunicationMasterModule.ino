
#include <stdio.h>
#include <SPI.h>
#include <Wire.h>

#define N_SELECTORSPERMODULE 6
#define N_SWITCHESPERMODULE 5
#define N_CURRENTSENSORSPERMODULE 5
#define N_ADC 6

// byte CommandModuleAddress[] = {11, 12, 13, 14, 15, 16};
// byte FeedbackModuleAddress[] = {1, 2, 3, 4, 5, 6};

int SelectorModuleAddress[] = {1, 2, 3, 4, 5};
int SwitchModuleAddress[] = {11, 12, 13, 14, 15};
int CurrentSensorModuleAddress[] = {21, 22, 23, 24, 25};




unsigned int Raw[N_CURRENTSENSORSPERMODULE];
byte Wave[N_CURRENTSENSORSPERMODULE];
byte Edge[N_CURRENTSENSORSPERMODULE];

byte ClockCmd = 'c';
byte RawReq = 'd';
byte WaveReq = 'w';
byte EdgeReq = 'e';
byte SelectorACmd = 's';
byte SwitchCmd = 'r';
char outbuffer[120];

void InitMicroShell();
void MicroShell();

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
  Serial.flush();
  InitMicroShell();
  printf("Holistic Systems\n");
}

void loop()
{
  while (Serial.available() > 0)
    MicroShell();
}

char* CommandSelector(int Selector, int Position)
{
  Wire.beginTransmission(SelectorModuleAddress[Selector / N_SELECTORSPERMODULE]);
  Wire.write(SelectorACmd);             // sends value byte
  Wire.write(Selector % N_SELECTORSPERMODULE);
  Wire.write(Position);
  Wire.endTransmission();
  return "OK";
}

char* CommandSwitch(int Switch, int Position)
{
  Wire.beginTransmission(SwitchModuleAddress[Switch / N_SWITCHESPERMODULE]);
  Wire.write(SwitchCmd);
  Wire.write(Switch % N_SWITCHESPERMODULE);
  Wire.write(Position);
  Wire.endTransmission();
  return "OK";
}

char* RequestStatus(int Signal)
{
  Wire.beginTransmission(CurrentSensorModuleAddress[Signal / N_CURRENTSENSORSPERMODULE]);
  Wire.write(WaveReq);             // sends value byte
  Wire.endTransmission();     // stop transmitting
  delay(100);
  Wire.requestFrom(CurrentSensorModuleAddress[Signal / N_CURRENTSENSORSPERMODULE], N_CURRENTSENSORSPERMODULE);    // request N_CURRENTSENSORSPERMODULE bytes from slave device
  for (int i = 0 ; i < N_CURRENTSENSORSPERMODULE;)   // slave may send less than requested
  {
    if (Wire.available())
    {
      int val = Wire.read();
      Wave[i++] = val; // receive a byte as character
    }
  }
  sprintf(outbuffer, "Signal %d %d", Signal , Wave[Signal % N_CURRENTSENSORSPERMODULE]);
  return outbuffer;
}

char* RequestWave(int Signal)
{
  Wire.beginTransmission(CurrentSensorModuleAddress[Signal / N_CURRENTSENSORSPERMODULE]);
  Wire.write(WaveReq);             // sends value byte
  Wire.endTransmission();     // stop transmitting
  delay(100);
  Wire.requestFrom(CurrentSensorModuleAddress[Signal / N_CURRENTSENSORSPERMODULE], N_CURRENTSENSORSPERMODULE);    // request N_CURRENTSENSORSPERMODULE bytes from slave device
  for (int i = 0 ; i < N_CURRENTSENSORSPERMODULE;)   // slave may send less than requested
  {
    if (Wire.available())
    {
      int val = Wire.read();
      Wave[i++] = val; // receive a byte as character
    }
  }
  sprintf(outbuffer, "Wave %d: %-1x %-1x %-1x %-1x %-1x", CurrentSensorModuleAddress[Signal / N_CURRENTSENSORSPERMODULE], Wave[0], Wave[1], Wave[2], Wave[3], Wave[4]);
  return outbuffer;
}

char* RequestRawData(int Signal)
{
  Wire.beginTransmission(CurrentSensorModuleAddress[Signal / N_CURRENTSENSORSPERMODULE]);
  Wire.write(RawReq);             // sends value byte
  Wire.endTransmission();     // stop transmitting
  delay(100);
  Wire.requestFrom(CurrentSensorModuleAddress[Signal / N_CURRENTSENSORSPERMODULE], CurrentSensorModuleAddress[Signal / N_CURRENTSENSORSPERMODULE]*2);    // request n bytes from slave device
  char *ptr = (char *)Raw;
  for (int i = 0 ; i < CurrentSensorModuleAddress[Signal / N_CURRENTSENSORSPERMODULE]*2;)   // slave may send less than requested
  {
    if (Wire.available())
    {
      int val = Wire.read();
      ptr[i++] = val; // receive a byte as character
    }
  }
  sprintf(outbuffer, "Raw %d: %02x %02x %02x %02x %02x %02x", CurrentSensorModuleAddress[Signal / N_CURRENTSENSORSPERMODULE], Raw[0], Raw[1], Raw[2], Raw[3], Raw[4], Raw[5]);
  return outbuffer;
}
