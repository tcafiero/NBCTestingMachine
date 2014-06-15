#include <SPI.h>
#include <Wire.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <stdlib.h>
#define ACTIVEOP_ADAPTOR0  2

byte PositionSelectorA[] = {0, 5, 14, 28, 59, 0, 0};
byte ChipSelect[] = {10, 9, 8};
byte Relay[] = {2, 3, 4, 5, 6, 7};

int myputc(char c, FILE *)
{
  Serial.write(c);
  return 0;
}

void setup() {
  Serial.begin(115200);
  fdevopen(&myputc, NULL);
  Wire.begin(ACTIVEOP_ADAPTOR0);                // join i2c bus with address
  Wire.onReceive(receiveEvent); // register event
}

void loop() {
}

void SelectorA(int id, int value) {
  byte Chip, Potentiometer;
  Chip = id / 6;
  Potentiometer = id % 6;
  // take the SS pin low to select the chip:
  digitalWrite(ChipSelect[Chip], LOW);
  //  send in the address and value via SPI:
  SPI.transfer(Potentiometer);
  SPI.transfer(PositionSelectorA[value]);
  // take the SS pin high to de-select the chip:
  digitalWrite(ChipSelect[Chip], HIGH);
}

void RelayCommand(int i, int level)
{
  digitalWrite(Relay[i], level);
}

void receiveEvent(int num)
{
  char command[10];
  for (byte i = 0; i < num; i++)
    command[i] = Wire.read();
  switch (command[0])
  {
    case 's':
      SelectorA(command[1], command[2]);
      break;
    case 'r':
      RelayCommand(command[1], command[2]);
      break;
    default:
      break;
  }
}
