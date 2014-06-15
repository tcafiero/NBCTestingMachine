#include <SPI.h>
#include <Wire.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <stdlib.h>
#define I2C_ADDRESS  11 //for this kind of module legal address are 11, 12, 13, 14, 15, 16

byte PositionSelectorA[] = {0, 5, 14, 28, 59, 0, 0};
byte ChipSelect[] = {10, 9};
byte Relay[] = {2, 3, 4, 5, 6, 7};

int myputc(char c, FILE *)
{
  Serial.write(c);
  return 0;
}

void setup() {
  for(byte i=0; i < sizeof(ChipSelect) ; i++)
    pinMode(ChipSelect[i], OUTPUT);
  for(byte i=0; i < sizeof(Relay) ; i++)
    pinMode(Relay[i], OUTPUT);
  Serial.begin(115200);
  fdevopen(&myputc, NULL);
  Wire.begin(I2C_ADDRESS);                // join i2c bus with address
  SPI.begin();
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

void RelayCommand(int rel, int level)
{
  digitalWrite(Relay[rel], level);
}

void receiveEvent(int num)
{
  char command[10];
  for (byte i = 0; i < num; i++)
  {
    command[i] = Wire.read();
  }
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
