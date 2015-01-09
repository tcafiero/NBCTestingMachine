//delete comment in following statement if you need echo
//#define ECHO 1

//delete comment in following statement if you need debug print
//#define DEBUG 1

// Do not touch following lines end comment
typedef struct
{
  char *name;
  void (*pfunc)(int argc, char **argv);
} PublishFunctionStruct;
int argvscanf(  const char *format, ... );
void result(char *format, ...);
// end untouchable


// Put here function prototype to expose with micro shell
char* CommandSwitch(int Switch, int Position);
char* CommandSelectorTypeA(int Switch, int Position);
char* CommandSelectorTypeB(int Switch, int Position);
char* RequestWave(int Signal);
char* RequestRawData(int Signal);
char* RequestStatus(int Signal);


// Put here function wrapper
void CommandSelectorTypeA_wrapper(int argc, char **argv)
{
  int a;
  int b;
  argvscanf("%d %d", &a, &b);
  #ifdef DEBUG
//  result("Result: %s\n", CommandSelectorTypeA(a, b));
  printf("Result: %s\n", CommandSelectorTypeA(a, b));
  #else
  CommandSelectorTypeA(a, b);  
  #endif
}
void CommandSelectorTypeB_wrapper(int argc, char **argv)
{
  int a;
  int b;
  argvscanf("%d %d", &a, &b);
  #ifdef DEBUG
//  result("Result: %s\n", CommandSelectorTypeB(a, b));
  printf("Result: %s\n", CommandSelectorTypeB(a, b));
  #else
  CommandSelectorTypeB(a, b);
  #endif
}
void CommandSwitch_wrapper(int argc, char **argv)
{
  int a;
  int b;
  argvscanf("%d %d", &a, &b);
  #ifdef DEBUG
  result("Result: %s\n", CommandSwitch(a, b));
  #else
  CommandSwitch(a, b);
  #endif
}
void RequestWave_wrapper(int argc, char **argv)
{
  int Signal;
  argvscanf("%d", &Signal);
  result("%s\n", RequestWave(Signal));
}
void RequestRawData_wrapper(int argc, char **argv)
{
  int Signal;
  argvscanf("%d", &Signal);
  result("%s\n", RequestRawData(Signal));
}
void RequestStatus_wrapper(int argc, char **argv)
{
  int Signal;
  argvscanf("%d", &Signal);
  result("%s\n", RequestStatus(Signal));
}

//Put here Publish function table
PublishFunctionStruct PublishFunction[] =
{
  {"CommandSwitch", CommandSwitch_wrapper},
  {"CommandSelectorA", CommandSelectorTypeA_wrapper},
  {"CommandSelectorB", CommandSelectorTypeB_wrapper},
  {"RequestWave", RequestWave_wrapper},
  {"RequestRawData", RequestRawData_wrapper},
  {"RequestStatus", RequestStatus_wrapper},
  {"", 0}
};

// Put here function ParserPutchar to output character
void ParserPutchar(int ch)
{
  Serial.write(ch);
}

// Put here function ParserGetchar to input character
int ParserGetchar()
{
  return Serial.read();
}




//Do not touch following lines

#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <stdlib.h>
#define BUFSIZE 80
#define PARAMETERSNUM 10
char buffer[BUFSIZE];
char *argv[PARAMETERSNUM];
int argc;
int i;

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
          printf("%d", va_arg ( ap, int ));
          ParserPutchar(0xa);
          ParserPutchar(0xd);
          break;
        case 's':
          printf("%s", va_arg ( ap, char * ));
          ParserPutchar(0xa);
          ParserPutchar(0xd);
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



void InitMicroShell()
{
  i = 0;
}

void MicroShell()
{
  char ch = (char)ParserGetchar();
  switch (ch)
  {
    case 0x8: 	if (i)
      {
#ifdef ECHO
        i--;
        ParserPutchar((int)ch);
#endif
      }
      break;
    case 0x0a:
    case 0x0d:
      buffer[i] = 0;
      ParserPutchar(0xd);
      Execute(buffer);
      i = 0;
      buffer[0] = 0;
      //ParserPutchar(0xd);
#ifdef ECHO
      ParserPutchar('>');
#endif
      break;
    default:		if (i >= BUFSIZE - 2)
      {
        ParserPutchar((int)0x7);
        break;
      }
      buffer[i++] = ch;
#ifdef ECHO
      ParserPutchar((int)ch);
#endif
  }
}
