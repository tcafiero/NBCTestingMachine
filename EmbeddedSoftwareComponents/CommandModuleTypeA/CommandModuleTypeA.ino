#include <SPI.h>
#include <Wire.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <stdlib.h>
#include <EEPROM.h>

#define ENABLE_EEPROM_PROG_PIN 9
// for SelectorTypeA {1, 2, 3, 4, 5};
// for Switch {11, 12, 13, 14, 15}
// for CurrentSensor {21, 22, 23, 24, 25};
// for SelectorTypeB {31, 32, 33, 34, 35};
int i2c_address;
//#define I2C_ADDRESS  1   /* this for first SelectorModule on the i2c BUS */
//#define I2C_ADDRESS  11 /* this for first SwtchModule on the i2c BUS */
//#define I2C_ADDRESS  21 /* this for first CurrentSensorModule on the i2c BUS */

int PositionSelectorA[] = {0, 5, 14, 28, 59, 0, 0};
int PositionSelectorB[] = {0, 13, 127, 242, 255, 0, 0};
const int ChipSelect= 10;
int Relay[] = {2, 3, 4, 5, 6};

int myputc(char c, FILE *)
{
  Serial.write(c);
  return 0;
}

void digitalPotWrite(int address, int value) {
  // take the SS pin low to select the chip:
  digitalWrite(ChipSelect,LOW);
  //  send in the address and value via SPI:
  SPI.transfer(address);
  SPI.transfer(value);
  // take the SS pin high to de-select the chip:
  digitalWrite(ChipSelect,HIGH); 
}

void setup() {
  Serial.begin(115200);
  fdevopen(&myputc, NULL);
  pinMode(ENABLE_EEPROM_PROG_PIN, INPUT);
  digitalWrite(ENABLE_EEPROM_PROG_PIN, HIGH);
  if (digitalRead(ENABLE_EEPROM_PROG_PIN) == LOW)
  {
    printf("Holistic Systems\n");
    printf("Input i2c address:\n");
    Serial.flush();
    Serial.setTimeout(20000);
    i2c_address=Serial.parseInt();
    if (i2c_address) EEPROM.write(0, i2c_address);
  };
  i2c_address = EEPROM.read(0);
  printf("Holistic Systems\n");
  printf("Module i2c address: %d\n", i2c_address);
  pinMode(ChipSelect, OUTPUT);
  for (byte i = 0; i < sizeof(Relay) ; i++)
    pinMode(Relay[i], OUTPUT);
  Wire.begin(i2c_address);                // join i2c bus with address
  SPI.begin();
  Wire.onReceive(receiveEvent); // register event
}

void loop() {
}

void SelectorA(int id, int value) {
  digitalPotWrite(id, PositionSelectorA[value]);
}

void SelectorB(int id, int value) {
  digitalPotWrite(id, PositionSelectorB[value]);
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
    case 'B':
      SelectorB(command[1], command[2]);
      break;
    case 'A':
      SelectorA(command[1], command[2]);
      break;
    case 'r':
      RelayCommand(command[1], command[2]);
      break;
    default:
      break;
  }
}
