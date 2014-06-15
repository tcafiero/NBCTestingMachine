/*
  Digital Pot Control

  This example controls an Analog Devices AD5206 digital potentiometer.
  The AD5206 has 6 potentiometer channels. Each channel's pins are labeled
  A - connect this to voltage
  W - this is the pot's wiper, which changes when you set it
  B - connect this to ground.

 The AD5206 is SPI-compatible,and to command it, you send two bytes,
 one with the channel number (0 - 5) and one with the resistance value for the
 channel (0 - 255).

 The circuit:
  * All A pins  of AD5206 connected to +5V
  * All B pins of AD5206 connected to ground
  * An LED and a 220-ohm resisor in series connected from each W pin to ground
  * CS - to digital pin 10  (SS pin)
  * SDI - to digital pin 11 (MOSI pin)
  * CLK - to digital pin 13 (SCK pin)

 created 10 Aug 2010
 by Tom Igoe

 Thanks to Heather Dewey-Hagborg for the original tutorial, 2005

*/


// inslude the SPI library:
#include <SPI.h>
#include <Wire.h>

#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <stdlib.h>

const byte PositionSelectorA[] = {0, 5, 14, 28, 59, 0, 0};
byte ChipSelect[] = {10, 9};
int i = 0;
char ch;
#define BUFSIZE 80
#define PARAMETERSNUM 10
char buffer[BUFSIZE];

int argvscanf( char *format, ... );
void ParserPutchar(int ch);
int ParserGetchar();
int CallFormat(char* src);
int argvscanf(  const char *format, ... );
void result(char *format, ...);
static void Scanner();
static void Execute(char *buffer);

char *SelectorA(int id, int value) {
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
  return "OK";
}

char *ExpanderWrite(byte place)
{
  Wire.beginTransmission(B0111000);     //Begin the transmission to PCF8574
  Wire.write(1<<place);                                //Send the data to PCF8574
  Wire.endTransmission();
  return("OK");
}
 
char *RelayCommand(int pin, int level)
{
  digitalWrite(pin, level);
  return "OK";
}

int serial_console_putc(char c, FILE *)
{
  Serial.write(c);
  return 0;
}
void SelectorA_wrapper(int argc, char **argv)
{
  int a;
  int b;
  argvscanf("%d %d", &a, &b);
  result("%s", SelectorA(a, b));
}

void RelayCommand_wrapper(int argc, char **argv)
{
  int a;
  int b;
  argvscanf("%d %d", &a, &b);
  result("%s", RelayCommand(a, b));
}

void ExpanderWrite_wrapper(int argc, char **argv)
{
  int a;
  argvscanf("%d", &a);
  result("%s", ExpanderWrite(a));
}


void ParserPutchar(int ch)
{
  Serial.write(ch);
}

int ParserGetchar()
{
  return Serial.read();;
}



void setup() {
  Wire.begin();
  Wire.beginTransmission(B01110000);     //Begin the transmission to PCF8574
  Wire.write(B00000000);                                //Send the data to PCF8574
  Wire.endTransmission();
  Serial.begin(115200);
  fdevopen(&serial_console_putc, NULL);
  // set the slaveSelectPin as an output:
  for(int i=0; i < sizeof(ChipSelect) ; i++)
    pinMode(ChipSelect[i], OUTPUT);
  pinMode(2, OUTPUT);
  // initialize SPI:
  SPI.begin();
  printf("Holistic Systems Micro Shell (Toni Cafiero all right reserved)\n");
  Serial.flush();
}

void loop() {
  //  digitalWrite(2, HIGH);   // turn the LED on (HIGH is the voltage level)
  //  delay(1000);               // wait for a second
  //  digitalWrite(2, LOW);    // turn the LED off by making the voltage LOW
  //  delay(1000);               // wait for a second
  //  printf("Value is:%3d\n", 4);
  while (Serial.available() > 0)
  {
    ch = (char)ParserGetchar();
    switch (ch)
    {
      case 0x8: 	if (i)
        {
          i--;
          ParserPutchar((int)ch);
        }
        break;
      case 0x0a:	buffer[i] = 0;
        Execute(buffer);
        i = 0;
        buffer[0] = 0;
        ParserPutchar(0xa);
        //ParserPutchar(0xd);
        ParserPutchar('>');
        break;
      default:		if (i >= BUFSIZE - 2)
        {
          ParserPutchar((int)0x7);
          break;
        }
        buffer[i++] = ch;
        ParserPutchar((int)ch);
    }
  }
  }



typedef struct
{
  char *name;
  void (*pfunc)(int argc, char **argv);
} PublishFunctionStruct;

PublishFunctionStruct PublishFunction[] =
{
  {"SelectorA", SelectorA_wrapper},
  {"RelayCommand", RelayCommand_wrapper},
  {"ExpanderWrite", ExpanderWrite_wrapper},
  {"", 0}
};


char *argv[PARAMETERSNUM];
int argc;


int CallFormat(char* src)
{
  int index, i;
  i = 0;
  do
  {
    for ( index = 0; *src != '\0' && *src != ' ' && i < PARAMETERSNUM; index++, src++)
      if (index == 0) argv[i++] = src;
    if ( *src == ' ' ) *src = '\0';
  }
  while (*++src != '\0');
  return i;
}

int argvscanf(  const char *format, ... )
{
  va_list ap;
  int conv = 1, *i;
  char *a;
  const char *fp;
  va_start ( ap, format );
  for ( fp = format; *fp != '\0'; fp++ ) {
    if ( *fp == '%' ) {
      switch ( *++fp ) {
        case 'd':
          i = va_arg ( ap, int * );
          *i = atoi ( argv[conv] );
          break;
        case 's':
          a = va_arg ( ap, char * );
          strncpy ( a, argv[conv], strlen ( argv[conv] ) + 1 );
          break;
      }
      conv++;
    }
  }
  va_end ( ap );
  return conv;
}


#if 0
int sscanf( char *src, char *format, ... )
{
  va_list ap;
  int conv = 0, *i, index;
  char *a, *fp, *sp = src, buf[BUFSIZE] = {'\0'};

  va_start ( ap, format );
  for ( fp = format; *fp != '\0'; fp++ ) {
    for ( index = 0; *sp != '\0' && *sp != ' '; index++ )
      buf[index] = *sp++;
    while ( *sp == ' ' ) sp++;
    while ( *fp != '%' ) fp++;
    if ( *fp == '%' ) {
      switch ( *++fp ) {
        case 'd':
          i = va_arg ( ap, int * );
          *i = atoi ( buf );
          break;
        case 's':
          a = va_arg ( ap, char * );
          strncpy ( a, buf, strlen ( buf ) + 1 );
          break;
      }
      conv++;
    }
  }
  va_end ( ap );
  return conv;
}
#endif

void result(char *format, ...)
{
  va_list ap;
  const char *fp;
  va_start ( ap, format );
  for ( fp = format; *fp != '\0'; fp++ ) {
    if ( *fp == '%' ) {
      switch ( *++fp ) {
        case 'd':
          printf("\nResult: %d", va_arg ( ap, int ));
          break;
        case 's':
          printf("\nResult: %s", va_arg ( ap, char * ));
          break;
      }
    }
  }
  va_end ( ap );
}

static void Scanner()
{
  int i;
  for (i = 0; strlen(PublishFunction[i].name); i++)
    if (strcmp(PublishFunction[i].name, argv[0]) == 0)
    {
      (*PublishFunction[i].pfunc)(0, argv);
      break;
    }
}

static void Execute(char *buffer)
{
  CallFormat(buffer);
  Scanner();
}



