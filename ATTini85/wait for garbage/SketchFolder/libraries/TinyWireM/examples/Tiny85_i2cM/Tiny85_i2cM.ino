/* ATtiny85 as an I2C Master  Ex1          BroHogan                      1/21/11
 * I2C master reading DS1621 temperature sensor. (display with leds)
 * SETUP:
 * ATtiny Pin 1 = (RESET) N/U                      ATtiny Pin 2 = (D3) LED3
 * ATtiny Pin 3 = (D4) to LED1                     ATtiny Pin 4 = GND
 * ATtiny Pin 5 = SDA on DS1621                    ATtiny Pin 6 = (D1) to LED2
 * ATtiny Pin 7 = SCK on DS1621                    ATtiny Pin 8 = VCC (2.7-5.5V)
 * NOTE! - It's very important to use pullups on the SDA & SCL lines!
 */

#include <TinyWireM.h>                  // I2C Master lib for ATTinys which use USI

#define SERVER           0x48           // 7 bit I2C address for Server
#define LED2_PIN         1              // ATtiny Pin 6
byte Num=0;

void setup(){
  pinMode(LED2_PIN,OUTPUT);
  Blink(LED2_PIN,2);                    // show it's alive
  TinyWireM.begin();                    // initialize I2C lib
  Init_Channel();                       // Setup Channel
  delay (3000);
}


void loop(){
  Num=0;
  Get_Channel();
  if ( Num >  0 )
    Blink(LED2_PIN,Num);    // blink Num times LED 2
   delay (200);
}


void Init_Channel(){ // Setup the DS1621 for one-shot mode
  TinyWireM.beginTransmission(SERVER);
  TinyWireM.send('A');                 // Access Command Register
  TinyWireM.endTransmission();          // Send to the slave
}


void Get_Channel(){  // Get the temperature from a DS1621
  TinyWireM.beginTransmission(SERVER);
  TinyWireM.send('5');                 // if one-shot, start conversions now
  TinyWireM.endTransmission();          // Send 1 byte to the slave
  TinyWireM.requestFrom(SERVER,1); // Request 1 byte from slave
  Num = TinyWireM.receive();          // get the temperature
  if (Num > 0x30 && Num <= 0x39)
    Num = Num-0x30;
   else
    Num=0;
}


void Blink(byte led, byte times){ // poor man's GUI
  for (byte i=0; i< times; i++){
    digitalWrite(led,HIGH);
    delay (400);
    digitalWrite(led,LOW);
    delay (175);
  }
}

