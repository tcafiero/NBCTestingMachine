;*********************************************************************************
;                                                                                *
;                         Software License Agreement                             *
;                                                                                *
; The software supplied herewith by Microchip Technology Incorporated            *
; (the "Company") is intended and supplied to you, the Company's customer, for   *
; use solely and exclusively on Microchip products.                              *
; The software is owned by the Company and/or its supplier, and is protected     *
; under applicable copyright laws. All rights are reserved. Any use in           *
; violation of the foregoing restrictions may subject the user to criminal       *
; sanctions under applicable laws, as well as to civil liability for the         *
; breach of the terms and conditions of this license.                            *
                                                                                 *
; THIS SOFTWARE IS PROVIDED IN AN "AS IS" CONDITION. NO WARRANTIES, WHETHER      *
; EXPRESS, IMPLIED OR STATUTORY, INCLUDING, BUT NOT LIMITED TO, IMPLIED          *
; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE APPLY       *
; TO THIS SOFTWARE THE COMPANY SHALL NOT, IN ANY CIRCUMSTANCES, BE LIABLE        *
; FOR SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES, FOR ANY REASON WHATSOEVER.   *
;                                                                                *
;*********************************************************************************
;*******************************************************************
; CAN-NET Education Board Customized for IO Expander Reference Design
;
; John Theys
; Diversified Engineering 
;
;*******************************************************************

          TITLE " IO Expander Reference Design "

;*******************************************************************

;-------------------------------------------;;
;  SELECT THE PROCESSOR YOU ARE USING!!!!!!  ;
;-------------------------------------------;;
 
#define PIC16C74A
;;#define PIC16F874
;; #define PIC16F877

;*******************************************************************

dVersion       equ  1
dRelease       equ  1

;----- PIC16C74A Micro -----;

#ifdef PIC16C74A

          LIST P=16C74A
          LIST r=dec,x=on,t=off

#include "P16C74A.INC"

  __CONFIG _BODEN_ON&_CP_OFF&_PWRTE_ON&_WDT_OFF&_HS_OSC
  __IDLOCS (dVersion<<8)|dRelease  ; version: vvrr , vv- version, rr - release

#endif

;----- PIC16F874 Micro -----;

#ifdef PIC16F874

          LIST P=16F874
          LIST r=dec,x=on,t=off

#include "P16F874.INC"

  __CONFIG _BODEN_ON&_CP_OFF&_WRT_ENABLE_ON&_PWRTE_ON&_WDT_OFF&_HS_OSC&_DEBUG_OFF&_CPD_OFF&_LVP_OFF
  __IDLOCS (dVersion<<8)|dRelease  ; version: vvrr , vv- version, rr - release

#endif

;----- PIC16F877 Micro -----;

#ifdef PIC16F877

          LIST P=16F877
          LIST r=dec,x=on,t=off

#include "P16F877.INC"

  __CONFIG _BODEN_ON&_CP_OFF&_WRT_ENABLE_ON&_PWRTE_ON&_WDT_OFF&_HS_OSC&_DEBUG_OFF&_CPD_OFF&_LVP_OFF
  __IDLOCS (dVersion<<8)|dRelease  ; version: vvrr , vv- version, rr - release

#endif

;---------------------------;

#include "MACROS16.INC"       ; general purpose macros
#include "MCP2510.INC"        ; 2510 definitions

          errorlevel 0,-306,-302,-305
 
;******** constants

;Crystal freq 7.3728 Hz, Instruction time = 0.54253 uS
;
; Timer 1: Uses 4:1 prescale => Tic is 2.1702 uSec
;       8 bit rollover 555.55 uSec
;       16 bit rollover 142.222 mSec
;
;   8 bit timers
;    TMR1L: 2.1702 uSec tics with maximum of 1/2 rollover = 277.77 uSec maximum
;    TMR1H: 555.55 uSec tics with maximum of 1/2 rollover = 71.111 msec maximum
;
;======================================================================
#define dTimePeriod 10        ; Alive counter (142 mS units)

;======================================================================

;************************

;************************
; special function defines

#define _SSPEN      SSPCON,SSPEN        ; SPI enable

;************************

;; General control flags definitions

#define tbWork          bGenFlags1,0   ; working bit
#define tbRecBroadcast  bGenFlags1,1   ; Rec msg is broadcast
#define tbNewSPI        bGenFlags1,2   ; new SPI data available
#define tbRxMsgPend     bGenFlags1,3   ; new CAN message received
#define tbTimedOut      bGenFlags1,4   ; Clear message area due to no message

;*****************  PIN DEFINITIONS **************************
#define tp2510_CS_    PORTA,4     ; CS_ for 2510 chip
#define tp2510_RS_    PORTC,0     ; RST_ 2510 chip

#define tpTxEnable    PORTC,2     ; Enable xmit for 485

;; LEDs
#define tpLED0        PORTD,0     
#define tpLED1        PORTD,1     
#define tpLED2        PORTD,2     
#define tpLED3        PORTD,3     
#define tpLED4        PORTD,4     
#define tpLED5        PORTD,5     
#define tpLED6        PORTD,6     
#define tpLED7        PORTD,7     

#define  tpLCD_RS     PORTE,0     ; command/data line
#define  tpLCDEnable  PORTE,1     ; chip select line

;*****************  LOCAL REGISTER STORAGE **************************
;
;
;============ BANK 0 =================

 cblock   0x20
     ;; interrupt variables
          bIntSaveSt       ; save Status
          bIntSaveFSR      ; save FSR
          bIntSavPCLATH    ; interrupt storage for PCLATH
          bIntWork         ; working
          iIntWork:2       ; working

     ;; general work space
          bGenFlags1       ; general control flags 1
          bWork            ; work byte
          bWork1           ; extra work byte
          iWork:2          ; work integer
          bCnt             ; work byte counter
          pWork            ; work pointer

     ;; Arithmetic
          iA:2             ; 2 byte integer
          iB:2             ; 2 byte integer
          _bcount          ; temporary storage
          _btemp           ; temporary storage
          bBCD_5           ; MSD of 5 digit BCD 
          bBCD43           ; digits 4 & 3 of 5 digit BCD 
          bBCD21           ; digits 2 & 1 of 5 digit BCD 

     ;; Timer1
          bGenClk          ; general clock    
          bTimeOutCnt      ; Alive timeout count

     ;; LCD variables (temporary internal to LCD routines )
          bLCDData
          bLCDTemp

     ;; Xmit CAN message
          bXmitPDU          ; received PDU  value
          bXmitUser         ; received User value
          bXmitNode         ; received Node value
          bXmitType         ; received Type value
          bXmitCmd          ; received Cmd  value

     ;; Received CAN message
          bRecClass        ; received Class value
          bRecSubDest      ; received SubClass or Destination value
          bRecSource       ; received Source value
          bRecCmd          ; received Cmd  value
          bRecWork         ; receive code working register
          bRecCount        ; number of bytes received
          pRecDataBase:8   ; received data

     ;; Low level SPI interface
          b2510RegAdr      ; Register address
          b2510RegData     ; Data sent/received
          b2510RegMask     ; Bit Mask

       ; following used in interrupt      
          bSPICnt          ; # bytes remaining to receive
          pSPIBuf          ; Pointer into buffer   
          pSPIBufBase:12   ; Base of SPI receive/xmit buffer

 endc

  
; storage for interrupt service routine
; W saved in one of these locations depending on the page selected 
; at the time the interrupt occured

bIntSaveW0 equ  0x7F       ; interrupt storage for W

;============ BANK 1 =================


bIntSaveW1 equ  0xFF       ; interrupt storage for W


;*******************************************************************
;********** LOCAL MACROS *******************************************
;*******************************************************************
; 
; Shift left 2 byte integer once.
iShiftL macro    iVar
        bcf      _C                ; clear carry bit    
        rlf      iVar,F
        rlf      iVar+1,F
        endm

; Shift right 2 byte integer once.
iShiftR macro    iVar
        bcf      _C               ; clear carry bit    
        rrf      iVar+1,F
        rrf      iVar,F
        endm

; Increment 2 byte integer
intInc  macro   iVar
        incf    iVar,F
        skipNZ
        incf    iVar+1,F
        endm

; 
;; --------------------------------------------------------
;; Set TRM1L 8 bit clock
;    TMR1L: 2.1702 uSec tics with maximum of 1/2 rollover = 277.77 uSec maximum
;; --------------------------------------------------------
Set1LClock macro bClk,Value
          movfw     TMR1L
          addlw     Value
          movwf     bClk
          endm

;; --------------------------------------------------------
;; Jump to jLabel if TMR1L (low byte) < bClk
;; --------------------------------------------------------
jmp1LNotYet macro bClk,jLabel

          movfw     TMR1L
          subwf     bClk,W
          andlw     0x80
          jmpZ      jLabel
          endm

;; --------------------------------------------------------
;; Jump to jLabel if TMR1L (low byte) < bClk
;; --------------------------------------------------------
jmp1LDone macro bClk,jLabel

          movfw     TMR1L
          subwf     bClk,W
          andlw     0x80
          jmpNZ     jLabel
          endm

; 
;; --------------------------------------------------------
;; Set TRM1H 8 bit clock
;    TMR1H: 277.77 uSec tics with maximum of 1/2 rollover = 35.555 msec maximum
;; --------------------------------------------------------
Set1HClock macro bClk,Value
          movfw     TMR1H
          addlw     Value
          movwf     bClk
          endm

;; --------------------------------------------------------
;; Jump to jLabel if TMR1H (low byte) < bClk
;; --------------------------------------------------------
jmp1HNotYet macro bClk,jLabel

          movfw     TMR1H
          subwf     bClk,W
          andlw     0x80
          jmpZ      jLabel
          endm

;; --------------------------------------------------------
;; Jump to jLabel if TMR1H (low byte) < bClk
;; --------------------------------------------------------
jmp1HDone macro bClk,jLabel

          movfw     TMR1H
          subwf     bClk,W
          andlw     0x80
          jmpNZ     jLabel
          endm



;********************************************************************
;      Begin Program Code
;********************************************************************

          ORG      0x0            ;memory @ 0x0
          nop                     ;nop ICD!!
          goto     HardStart

          ORG     04h             ;Interrupt Vector @ 0x4
;**********************************************************
; Interrupt service routine - must be at location 4 if page 1 is used
; Context save & restore takes ~20 instr
;**********************************************************
     ;; Global int bit, GIE, has been reset.
     ;; W saved in bIntSaveW0 or bIntSaveW1 depending on the bank selected at
     ;; the time the interrupt occured.
          movwf     bIntSaveW0      ; save W in either of two locations 
                                    ; depending on bank currently selected

     ;; only way to preserve Status bits (since movf sets Z) is with a 
     ;; swapf command now
          swapf     STATUS,W        ; Status to W with nibbles swapped
          BANK0
          movwf     bIntSaveSt
          movfw     FSR
          movwf     bIntSaveFSR     ; save FSR
          movf      PCLATH,W 
          movwf     bIntSavPCLATH   ; interrupt storage for PCLATH
          clrf      PCLATH          ; set to page 0

     ;; Must determine source of interrupt

     ;; SPI interrupt
          btfsc    _SSPIF        ; SPI interrupt
          goto     IntSPI

          jmpSet   _TMR1IF,jIntTimer1  ; Timer1 overflow interrupt flag

     ;; unknown
                   
     ;; restore registers and return
IntReturn          
          BANK0
          movf      bIntSavPCLATH,W   ; interrupt storage for PCLATH
          movwf     PCLATH
          movf      bIntSaveFSR,W  ; restore FSR
          movwf     FSR
          swapf     bIntSaveSt,W ; get swapped Status (now unswapped)
          movwf     STATUS       ; W to Status  ( bank select restored )
          swapf     bIntSaveW0,F ; swap original W in place
          swapf     bIntSaveW0,W ; now load and unswap ( no status change)
          retfie                 ; return from interrupt



;***************** LIBRARY STORAGE & FUNCTIONS ****************************


#include "CanLib.asm"         ; basic 2510 interface routines
                              ;  contains macros required for RefCode
#include "RefCode.asm"        ; code specific to reference design
#include "LCD4BIT.ASM"        ; LCD interface

;***************** Local Interrupt Handlers ****************************

          
;**********************************************************
;jIntTimer1 
;         Timer1 rollover interrupt.
;         16 bit rollover 142.222 mSec
;
;**********************************************************
jIntTimer1  ; Timer1 overflow interrupt flag
          bcf       _TMR1IF        ; timer1 rollover interrupt flag

     ;; Count down for alive clock
          jmpFeqZ   bTimeOutCnt,IntReturn  ; Already counted out

          decfsz    bTimeOutCnt,F      
          goto      IntReturn

     ;; Setup Alive timeout
          bL2bV     dTimePeriod,bTimeOutCnt

          bsf       tbTimedOut          
          goto      IntReturn

;**********************************************************
;IntSPI                                 
; 
; A single buffer, at pSPIBufBase, is used for both SPI receive and
; transmit.  When a byte is removed from the buffer to transmit it is
; replaced by the byte received.  
; 
; When here the buffer pointer, pSPIBuf, points to the last byte loaded 
; for transmission. This is the location that the received byte will be stored.
; 
; When here the count, bSPICnt, contains the number of bytes remaining
; to be received.  This is one less then the number remaining to be
; transmitted.  When bSPICnt reaches zero the transaction is complete.
; 
;         
;**********************************************************
IntSPI    
          bcf       _SSPIF              ; clear interrupt flag

     ;; Transfer received byte to the next location in the buffer
          bV2bV     pSPIBuf,FSR
          incf      pSPIBuf,F

          movfw     SSPBUF              ; get data & clear buffer flag
          movwf     INDF                ; put it into SPI buffer

          decfsz    bSPICnt,F
          goto      jIntSPI1            ; More bytes to send

     ;; Last transaction completed
          bsf       tp2510_CS_           ; CS_ for 2510 chip
          goto      IntReturn

jIntSPI1
     ;; Fetch next byte from buffer and load it for transmission
          incf      FSR,F
          movfw     INDF                ; get byte from buffer
          movwf     SSPBUF              ; send it
          goto      IntReturn


;**********************************************************
;**********************************************************
;**********************************************************

HardStart 
     ;; Initialize SFR, clear general ram
          PAGE1
          call      InitP
          PAGE0

     ;; Initialize LCD display
          call      LCDInit

          bsf       tpTxEnable          ; Enable xmit for 485

     ;; Setup SPI port
          call      InitSPIPort

     ;; Openning message            
          movlw     0x80
          call      WrtLCDInstr

          movlw     'I'
          call      WrtLCDData
          movlw     'O'
          call      WrtLCDData
          movlw     ' '
          call      WrtLCDData
          movlw     'E'
          call      WrtLCDData
          movlw     'X'
          call      WrtLCDData
          movlw     'P'
          call      WrtLCDData
          movlw     'A'
          call      WrtLCDData
          movlw     'N'
          call      WrtLCDData
          movlw     'D'
          call      WrtLCDData
          movlw     'E'
          call      WrtLCDData
          movlw     'R'
          call      WrtLCDData
          movlw     ' '
          call      WrtLCDData
          movlw     'B'
          call      WrtLCDData
          movlw     'R'
          call      WrtLCDData
          movlw     'D'
          call      WrtLCDData


     ;; ----------------- One time calculations ----------------

     ;; Reset 2510 Chip
          bcf       tp2510_RS_
          nop
          nop
          nop
          nop
          nop
          bsf       tp2510_RS_

     ;; Wait 28 mS for 2510 to initialize ( there is no significance to 28 mS -
     ;; we just selected a large time since time is not critical)
          Set1HClock bGenClk,100   ; 277.77 uSec tics
jInit5
          jmp1HNotYet bGenClk,jInit5


     ;; Setup all 2510 registers
          call      Init2510

     ;; Initialize reference design variables
          call      InitRef

;; --------------------------------------------------------
;; ----------- MAIN LOOP ----------------------------------
;; --------------------------------------------------------

jMainLoop clrwdt

     ;; Exchange and process messages with IO Expander nodes     
          call      ProcessRef
          goto      jMainLoop



;******************************************************
;Init2510
;*  Function:   Init_MCP2510()
;*      Place MCP2510 initialization here...
;*******************************************************
Init2510
     ;; Reset 2510
          call      Reset2510

     ;; set CLKOUT prescaler to div by 1
          bL2bV     0x03,b2510RegMask
          bL2bV     0x00,b2510RegData
          movlw     CANCTRL
          call      BitMod2510

;Set physical layer configuration 
;     Fosc = 16MHz
;     BRP        =   7  (divide by 8)
;     Sync Seg   = 1TQ
;     Prop Seg   = 1TQ
;     Phase Seg1 = 3TQ
;     Phase Seg2 = 3TQ
;
;    TQ = 2 * (1/Fosc) * (BRP+1) 
;     Bus speed = 1/(Total # of TQ) * TQ
;
          SPI_WriteL CNF1,0x07           ; set BRP to div by 8

;#define BTLMODE_CNF3    0x80
;#define SMPL_1X         0x00
;#define PHSEG1_3TQ      0x10
;#define PRSEG_1TQ       0x00
          SPI_WriteL CNF2,0x90

;#define PHSEG2_3TQ      0x02
          SPI_WriteL CNF3,0x02

;
     ;; Configure Receive buffer 0 Mask and Filters 
     ;; Receive buffer 0 will not be used
          SPI_WriteL RXM0SIDH,0xFF
          SPI_WriteL RXM0SIDL,0xFF

          SPI_WriteL RXF0SIDH,0xFF
          SPI_WriteL RXF0SIDL,0xFF

          SPI_WriteL RXF1SIDH,0xFF
          SPI_WriteL RXF1SIDL,0xFF


     ;; Configure Receive Buffer 1 Mask and Filters 

;; sidh  I2 I1 I0 C7 C6 C5 C4 C3           SID10-SID3
;; sidl  C2 C1 C0 -   E  - B  D6           SID2-SID0,u,E,u,EID17,EID16
;; eid8  D5 D4 D3 D2 D1 D0 S6 S5           EID15 - EID8
;; eid0  S4 S3 S2 S1 S0 C3 C1 C0           EID7  - EID0
;
;; Field      CAN reg
;; dPriority  SID10-SID8
;; dClass     SID7-SID0
;; dBroadcast EID17
;; dDest/Sub  EID16-EDI10
;; dSource    EID9-EID3
;; dCmd       EID2-EDI0

     ;; Set mask and filter to receive any Broadcast Class
          SPI_WriteL RXM1SIDH,0x00       ; SID6-SID3
          SPI_WriteL RXM1SIDL,0x0A       ; SID0-SID2
          SPI_WriteL RXM1EID8,0x00
          SPI_WriteL RXM1EID0,0x00 

     ;; Filter requires Broadcast message
          SPI_WriteL RXF2SIDH,0x00
          SPI_WriteL RXF2SIDL,0x0A       ; EXIDE flag and Broadcast message
          SPI_WriteL RXF2EID8,0x00
          SPI_WriteV RXF2EID0,0x00


     ;; Disable all MCP2510 Interrupts
          bL2bV     0x00,b2510RegData
          movlw     CANINTE
          call      Wrt2510Reg

     ;; Sets normal mode
          call      SetNormalMode
          return


;**********************************************************
;ProcessSPI
;
;**********************************************************
ProcessSPI
          skipSet   bSPICnt,2
     ;; buffer not full yet
          return

     ;; disable SPI interupt
          BANK1
          bcf       _SSPIE_P       ; SSP int enable (BANK 1)
          BANK0


     ;; enable SPI
          BANK1
          bsf       _SSPIE_P  ; SSP int enable (BANK 1)
          BANK0
          return



;*******************************************************************
;WaitMSec
;       Delay W number of Msec Routines (255 max)
;
;*******************************************************************

WaitMSec
          movwf   bCnt            ;store Msec -> bCnt

jWaitMSec0
          clrwdt                  ;clear wdt

;    TMR1L: 2.1702 uSec tics with maximum of 1/2 rollover = 277.77 uSec maximum
          Set1LClock bGenClk,113        ; 250 uS

jWaitMSec1
          jmp1LNotYet bGenClk,jWaitMSec1

          Set1LClock bGenClk,113        ; 250 uS
jWaitMSec2
          jmp1LNotYet bGenClk,jWaitMSec2

          Set1LClock bGenClk,113        ; 250 uS
jWaitMSec3
          jmp1LNotYet bGenClk,jWaitMSec3

          Set1LClock bGenClk,113        ; 250 uS
jWaitMSec4
          jmp1LNotYet bGenClk,jWaitMSec4

          decfsz    bCnt,F
          goto      jWaitMSec0
          return


#ifdef ROBUST
;; robust design - force WDT reset
          FILL (goto WDTReset0),(0x7FF-$)
WDTReset0 goto      WDTReset0
#endif


;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;;<<<<<<<<<<<<<<< P A G E  1  <<<<<<<<<<<<<<<<<<<<<<<<<<<<<
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
          ORG 0x800




;
;**********************************************************
;InitP
;         Initialize SFR registers
;
;         This pin setup is designed for the Diversified
;         Engineering CAN Education Board 
;        
;**********************************************************
InitP
          clrwdt                ; required before changing wdt to timer0

     ;; clear peripheral interrupts
        BANK1
          clrf      PIE1_P
       
     ;; OPTION_REG: PortB Pullups on.
     ;; no prescale for WDT -> should always > 7 mSec  ( 18 mS nominal)
     ;; Timer 0:  Use 64 prescale for 0.27127 * 64 = 17.361 uSec tics 

          movlw     B'01000101'        ; Timer0 prescale 64
          movwf     OPTION_REG_P

     ;; Clear Bank 0 
          movlw     0x20
          movwf     FSR
jInitClr1 clrf      INDF
          incf      FSR,F
          jmpClr    FSR,7,jInitClr1

     ;; Clear Bank 1
          movlw     0xA0
          movwf     FSR
jInitClr2 clrf      INDF
          incf      FSR,F
          jmpSet    FSR,7,jInitClr2

          BANK1

;; Set A/D off.

          BANK1
          movlw     b'00000110'
          movwf     ADCON1_P

    ;; Port A
    ;;      0  in   ad1
    ;;      1  in   ad2
    ;;      2  out  keypad strobe
    ;;      3  out  keypad strobe
    ;;      4  out  2510 CS
    ;;      5  out  keypad strobe

          BANK0
          movlw     B'00111100'     ;; initialize Port A outputs 
          movfw     PORTA           
          BANK1
          movlw     B'11000011'
          movwf     TRISA_P                 ;; set Port A


    ;; Port B 
    ;;      0  in   Interrupt from 2510
    ;;      1  out  row4 & LCD data
    ;;      2  out  row3 & LCD data
    ;;      3  out  row2 & LCD data
    ;;      4  out  row1 & LCD data
    ;;      5  in   RX0BF from 2510 
    ;;      6  in
    ;;      7  in

          BANK0
          movlw     B'00000000'     ;; initialize Port B outputs 
          movfw     PORTB           
          BANK1
          movlw     B'11100001'
          movwf     TRISB_P             ;; set Port B

    ;; Port C
    ;;      0  out   Reset 2510
    ;;      1  out   CS 25C040
    ;;      2  in
    ;;      3  out   SPI clock - master
    ;;      4  in    SPI data in
    ;;      5  out   SPI data out
    ;;      6  out   Tx
    ;;      7  in    Rx

          BANK0
          movlw     B'01000111'      ;; set 485 CS high, Tx high
          movwf     PORTC
          BANK1

          movlw     B'10010110'
          movwf     TRISC_P          ;; set Port C

          BANK0

    ;; Port D
    ;;      0  out   LED
    ;;      1  out   LED
    ;;      2  out   LED
    ;;      3  out   LED
    ;;      4  out   LED
    ;;      5  out   LED
    ;;      6  out   LED
    ;;      7  out   LED
 
          BANK0
          movlw     B'00000000'
          movwf     PORTD                   
          BANK1 
          movlw     B'00000000'
          movwf     TRISD_P          ;; set Port D

    ;; Port E
    ;;      0  out  LCD - RS => 1 - Data, 0 - Instr
    ;;      1  out  LCD - Enable
    ;;      2  in       enter

          BANK0
          movlw     B'00000000'
          movwf     PORTE           ;; Port C outputs       
          BANK1 

          movlw     B'00000100'    ;; do not set PORT_D as parallel port
          movwf     TRISE_P        ;; set Port E

      ;; configure Timer1:
          BANK0
          movlw     B'00100001'     ; Prescale = 4, Timer enabled 
          movwf     T1CON

          BANK1
          bsf       _TMR1IE_P      ; timer1 rollover interrupt enable (page 1)
          BANK0

     ;; for testing
          clrf      TMR1L
          clrf      TMR1H

     ;; turn on interrupts
        BANK0
          movlw     B'11000000'     ; Enable interrupts ( Periphrals only )
          movwf     INTCON

          return

#ifdef ROBUST
;; robust design - force WDT reset
          FILL (goto WDTReset1),(0xFFF-$)
WDTReset1  goto      WDTReset1
#endif

         END


