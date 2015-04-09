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
; IO Expander Reference Design Code
; Code contained herein is specifically to support the IO Expander
; reference design.
;
; John Theys
; Diversified Engineering 
;
;*******************************************************************

;; Joystick dead zone in A/D units (out of 256).  The joystick 
;; will be considered to be in off position if the A/D reading is 
;; less than or equal to dDeadZone.
#define dDeadZone  10      


;========== BIT DEFINITIONS OF IO EXPANDER NODES ===============

;; The nine digital flags for the functions supported by the 
;; IO Expander nodes are maintained in two bytes of flags, 
;; bDigitalFlgs1 and bDigitalFlgs2.  The bit definitions are:
;; Bit locations in bDigitalFlgs1
#define dBitUp      0         ; Up
#define dBitDown    1         ; Down
#define dBitHorn    2         ; Horn   
#define dBitLeft    3         ; Left   
#define dBitRight   4         ; Right  
#define dBitForward 5         ; Forward (digital)
#define dBitReverse 6         ; Reverse (digital)

;; Bit locations in bDigitalFlgs2
#define dBitBattery 0         ; Battery LED
#define dBitKeyLED  1         ; Key LED
#define dBitKey     2         ; Key

;; The bit definitions are combined with the appropriate register
;; for convenient use with bit test, set and clear instructions.
;; Digital Flags
#define tbFlgUp      bDigitalFlgs1,dBitUp       ; Up
#define tbFlgDown    bDigitalFlgs1,dBitDown     ; Down
#define tbFlgHorn    bDigitalFlgs1,dBitHorn     ; Horn   
#define tbFlgLeft    bDigitalFlgs1,dBitLeft     ; Left   
#define tbFlgRight   bDigitalFlgs1,dBitRight    ; Right  
#define tbFlgForward bDigitalFlgs1,dBitForward  ; Forward (digital)
#define tbFlgReverse bDigitalFlgs1,dBitReverse  ; Reverse (digital)

#define tbFlgBattery bDigitalFlgs2,dBitBattery  ; Battery LED
#define tbFlgKeyLED  bDigitalFlgs2,dBitKeyLED   ; Key LED
#define tbFlgKey     bDigitalFlgs2,dBitKey      ; Key


;========== ID DEFINITIONS OF NODES ===============
; Message ID Format as applied to CAN register structures.  There are
; two message types: Broadcast and Directed.
;
;Broadcast message type:
; Broadcast messages are put on the bus for general consumption.  No 
; specific destination is specified.  Generally this would be sensor
; data made available to any nodes that might be interested in it.
; Each Class type can be subdivided with a Subclass modifier to
; provide more structure to the class types and to increase the number 
; of IDs availble.
; The form is:
;
;; Field      Sym   # Bits   Description
;; dPriority  I        3     Priority: a 0 has priority over a 1
;; dClass     C        8     Kind of information 
;; dBroadcast B        1     Must be set to 1 for braodcast format
;; dSubclass  D        7     Class dependent modifier. 
;; dSource    S        7     Source address
;; dCmd       C        3     Reserved for hardware restrictions of node
;; extended   E        1     Must be 1 to specify and extended ID format.
;
;Num Bits   3       8        1      7          7     3
;Fields  Priority Class      1   SubClass    Source Cmd
;
;Directed message type:
; Directed messages are put on the bus for use by a specific node or
; a set of specific nodes as specified by the Destination address.
; Generally this would be control data sent to a specific node.
; The form is:
;
;; Field      Sym   # Bits   Description
;; dPriority  I        3     Priority: a 0 has priority over a 1
;; dClass     C        8     Kind of information 
;; dBroadcast B        1     Must be set to 0 for directed format
;; dDest      D        8     Destination address
;; dSource    S        7     Source address
;; dCmd       C        3     Reserved for hardware restrictions of node
;; extended   E        1     Must be 1 to specify and extended ID format.
;
;Num Bits   3       8     1       7          7     3
;Fields  Priority Class   0   Destination  Source Cmd
;
;;
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
;============================================================
;============================================================
;============================================================
;
;
;Class Table
;1       I/O Expander Data Packet
;2       I/O Expander PWM
;3       I/O Expander Digital Outputs
;
;Source/Destination
;0       Master Controller
;10      Main Ctrl Brd
;11      Oper Ctrol Brd
;12      Valve Brd
;
;SubClass
;0       unused       
;
;Reference design example:
;
;============== Controler ====================
;Send                    
;Class = 2,3   Brdcast=0   Dest=10,11,12  Source=0  Cmd=0
;
;Receive
;Class = 1     Brdcast=1   SubClass=0     Source=10,11,12  Cmd=0
;
;
;============== Main Ctrl Brd ====================
;Send                    
;Class = 1     Brdcast=1   SubClass=0  Source=10  Cmd=0
;
;Receive
;Class = 2,3   Brdcast=0   Dest=10     Source=0   Cmd=0
;
;
;============== Operator Brd ====================
;Send                    
;Class = 1     Brdcast=1   SubClass=0  Source=11  Cmd=0
;
;Receive
;Class = 2,3   Brdcast=0   Dest=11     Source=0   Cmd=0
;
;
;============== Valve Brd ====================
;Send                    
;Class = 1     Brdcast=1   SubClass=0  Source=12  Cmd=0
;
;Receive
;Class = 2,3   Brdcast=0   Dest=12     Source=0   Cmd=0
;=======================================================
;=======================================================


;Class Table
;1       I/O Expander Data Packet
;2       I/O Expander PWM
;3       I/O Expander Digital Outputs
;
#define dClassExpData    1   ;  I/O Expander Data Packet
#define dClassExpPWM     2   ;  I/O Expander PWM
#define dClassExpDigital 3   ;  I/O Expander Digital Outputs

;Source/Destination
;0       Master Controller
;10      Main Ctrl Brd
;11      Oper Ctrol Brd
;12      Valve Brd

#define dAdrMasterCtrl   0     ;  Master Controller
#define dAdrMainCtrl     10    ;  Main Ctrl Brd
#define dAdrOperCtrl     11    ;  Oper Ctrol Brd
#define dAdrValveCtrl    12    ;  Valve Brd


;====== IO EXPANDER USER REGISTER DEFINITIONS ===============
; Must add 0x1C offset for direct access
#define dIO_GPLAT   (0x02+0x1C)      ; address of GPLAT register
#define dIO_PWM1DCH (0x09+0x1C)      ; address of upper 8 bits of PWM1

;CMD bits
#define dCmdRdADRegs 0        ; Cmd: Read A/D Regs
#define dCmdWrtRegs  0        ; Cmd: Write Regs


;=============================================================
;=============================================================
;=======  U S E F U L   M A C R O S  =========================
;=============================================================
;=============================================================

;******************************************************
;Load ID macro for Broadcast msg
;         Loads the TXB0 xmitter ID registers with extended identifier
;         for broadcast type message with Priority or 0.
;******************************************************
LoadTxBroadcastID macro Class,SubClass,Source,Cmd
          bL2bV     (Class >> 3), bWork
          SPI_WriteV TXB0SIDH,bWork
          bL2bV     LOW((Class << 5) | 0x0A | (SubClass >> 6)), bWork
          SPI_WriteV TXB0SIDL,bWork
          bL2bV     LOW((SubClass << 2) | (Source >> 5)), bWork
          SPI_WriteV TXB0EID8,bWork
          bL2bV     LOW((Source << 3) | Cmd), bWork
          SPI_WriteV TXB0EID0,bWork
          endm


;******************************************************
;Load ID macro for Directed msg
;         Loads the TXB0 xmitter ID registers with extended identifier
;         for Directed type message with Priority or 0.
;******************************************************
LoadTxDestID macro Class,Dest,Source,Cmd
          bL2bV     (Class >> 3), bWork
          SPI_WriteV TXB0SIDH,bWork
          bL2bV     LOW((Class << 5) | 0x08 | (Dest >> 6)), bWork
          SPI_WriteV TXB0SIDL,bWork
          bL2bV     LOW((Dest << 2) | (Source >> 5)), bWork
          SPI_WriteV TXB0EID8,bWork
          bL2bV     LOW((Source << 3) | Cmd), bWork
          SPI_WriteV TXB0EID0,bWork
          endm




;******************************************************
;WrtIOExpanderReg macro 
;         Write bits determined by Mask & bData to 
;         the IO Expander register Reg.
;         Note that Mask & Reg are literals and bData is a variable
;******************************************************
WrtIOExpanderReg macro Reg,Mask,bData
          SPI_WriteL TXB0DLC,0x03        ; 3 data bytes
          SPI_WriteL TXB0D0,Reg
          SPI_WriteL TXB0D1,Mask
          SPI_WriteV TXB0D2,bData
          SPI_Rts    RTS0                ; Transmit buffer 0 
          endm



;========== BIT DEFINITIONS OF LOCAL FLAGS ===============

#define tbXmitOperBrd     bCtrlFlgs,0 ; Send data to Operator Brd
#define tbXmitMainDigital bCtrlFlgs,1 ; Send flags to Main Brd
#define tbXmitDCDrive     bCtrlFlgs,2 ; Send DC Drive value to Main Brd
#define tbXmitValveBrd    bCtrlFlgs,3 ; Send data to Hydraulic Valve Brd
#define tbMainAlive       bCtrlFlgs,4 ; Alive flag for Main Control Brd
#define tbOperAlive       bCtrlFlgs,5 ; Alive flag for Operator Control Brd
#define tbValveAlive      bCtrlFlgs,6 ; Alive flag for Hydraulic Control Brd


;=============================================================
;======================= VARIABLES ===========================
;=============================================================
 cblock
          bCtrlFlgs           ; General control flags
          bGPIO               ; GPIO work register

          bDigitalFlgs1       ; digital flags #1
          bDigitalFlgs2       ; digital flags #2
          bBatteryLevel       ; Battery level 0 -> 255
          bDCDrive            ; DC Drive control level: 0 -> 255
          bPrevDCDrive        ; Previous value of bDCDrive

          bForward            ; Joy stick level: 0 -> 255
          bReverse            ; Joy stick level: 0 -> 255

 endc

;=============================================================

;******************************************************
;InitRef
;         Initialize reference design variables, etc
;******************************************************
InitRef

     ;; Setup Alive timeout
          bL2bV     dTimePeriod,bTimeOutCnt

          bcf       tbTimedOut
          bcf       tbMainAlive   ; Alive flag for Main Control Brd
          bcf       tbOperAlive   ; Alive flag for Operator Control Brd
          bcf       tbValveAlive  ; Alive flag for Hydraulic Control Brd


     ;; Force initial messages to each board
          bsf       tbXmitOperBrd     ; Send data to Operator Brd
          bsf       tbXmitMainDigital ; Send flags to Main Brd
          bsf       tbXmitDCDrive     ; Send DC Drive value to Main Brd
          bsf       tbXmitValveBrd    ; Send data to Hydraulic Valve Brd

          return

;******************************************************
;ProcessRef
;         Exchange CAN messages with IO Expander nodes.
;******************************************************

ProcessRef

     ;; Check for received CAN message
          call      CheckCANMsg
          jmpClr    tbRxMsgPend,jProc10

     ;; New CAN message received. Parse it.

          call      ParseCAN
          bcf       tbRxMsgPend         ; signal message processed

jProc10
     ;; Test for unresponsive node.
          jmpClr    tbTimedOut,jProc12
          bcf       tbTimedOut

          jmpClr    tbMainAlive ,jProc30 ; Main Control Brd dead
          jmpClr    tbOperAlive ,jProc30 ; Operator Control Brd dead
          jmpClr    tbValveAlive,jProc30 ; Hydraulic Control Brd dead

      ;; reset flags
          bcf       tbMainAlive   ; Alive flag for Main Control Brd
          bcf       tbOperAlive   ; Alive flag for Operator Control Brd
          bcf       tbValveAlive  ; Alive flag for Hydraulic Control Brd

     ;; toggle LED7 to indicate board is running.
          toggle    tpLED7

jProc12

     ;; Send pending messages to nodes.
          call      SendCAN
          return

jProc30
     ;; A board is dead - shut down system

     ;;=== !! Shut down not implemented !! ===
          call      SendCAN                   ;;??TST
          return


;******************************************************
;SendCAN
;         Send queued CAN messages to nodes. Returns immediately
;         if transmitter is busy.
;******************************************************
SendCAN

     ;; Is xmitter ready for new message?
          bL2bV     0x08,b2510RegMask
          movlw     TXB0CTRL
          call      TestANDeqZ
          skipZ
          return              ; xmitter busy


          jmpClr    tbXmitMainDigital,jSendCAN10
          bcf       tbXmitMainDigital

;; >>>>>>>>>>>>>>>>>>> MAIN CONTROL BOARD - DIGITAL <<<<<<<<<<<<<<<<<<

;; Outputs in message
;;    DC Drive PWM:           GP2 (PWM1 output)
;;    Battery LED digital:    GP3 (output)
;;    Key LED digital:        GP4 (output)

          clrf      bGPIO         ; GPIO work register
          tb2tb     tbFlgBattery,bGPIO,3
          tb2tb     tbFlgKeyLED,bGPIO,4

          LoadTxDestID dClassExpDigital,dAdrMainCtrl,dAdrMasterCtrl,dCmdWrtRegs
          WrtIOExpanderReg dIO_GPLAT,0xFF,bGPIO
          return


jSendCAN10
          jmpClr    tbXmitDCDrive,jSendCAN20
          bcf       tbXmitDCDrive

;; >>>>>>>>>>>>>>>>>>> MAIN CONTROL BOARD - PWM <<<<<<<<<<<<<<<<<<

;; Outputs in message
;;    DC Drive PWM:           GP2 (PWM1 output)
;;    Battery LED digital:    GP3 (output)
;;    Key LED digital:        GP4 (output)

          LoadTxDestID dClassExpPWM,dAdrMainCtrl,dAdrMasterCtrl,dCmdWrtRegs
          WrtIOExpanderReg dIO_PWM1DCH,0xFF,bDCDrive
          return



jSendCAN20
          jmpClr    tbXmitOperBrd,jSendCAN30
          bcf       tbXmitOperBrd

;; >>>>>>> OPERATOR CONTROL BOARD <<<<<<<<<<<<<<<<<<<<

;; Outputs in message
;;    Battery Meter PWM:      GP2 ( PWM1 output)

          LoadTxDestID dClassExpPWM,dAdrOperCtrl,dAdrMasterCtrl,dCmdWrtRegs
          WrtIOExpanderReg dIO_PWM1DCH,0xFF,bBatteryLevel
          return


jSendCAN30
          jmpClr    tbXmitValveBrd,jSendCAN40
          bcf       tbXmitValveBrd

;; >>>>>>> HYDRAULIC VALVE CONTROL BOARD <<<<<<<<<<<<<<<

;; Outputs in message
;;    Up digital:             GP0 (output)
;;    Down digital:           GP1 (output)
;;    Horn digital:           GP2 (output)
;;    Steer Left digital:     GP3 (output)
;;    Steer Right digital:    GP4 (output)
;;    Forward (digital):      GP5 (output)
;;    Reverse (digital):      GP6 (output)

          bV2bV     bDigitalFlgs1,bGPIO         ; GPIO work register
          bcf       bGPIO,7

          LoadTxDestID dClassExpDigital,dAdrValveCtrl,dAdrMasterCtrl,dCmdWrtRegs
          WrtIOExpanderReg dIO_GPLAT,0xFF,bGPIO
          return

jSendCAN40
          return

;******************************************************
;ParseCAN
;         Parse CAN message.  Assumes message has been received
;         and its ID parsed into PDU,User,Node,Type and Cmd values.
;******************************************************
ParseCAN

          jmpClr    tbRecBroadcast,jParCAN90           ; ignore Directed message
          jmpFneL   bRecClass,dClassExpData,jParCAN90  ; not Expander data packet
          jmpFneZ   bRecSubDest,jParCAN90              ; unknown SubClass

          jmpFneL   bRecCmd,dCmdRdADRegs,jParCAN80     ; not RdADRegs

     ;; This is a "Read A/D Regs" messages from an IO Expander node

     ;; Message contains 8 bytes:
     ;;     IOINTFL, GPIO, AN0H, AN1H, AN10L, AN2H, AN3H, AN23L
     ;;
     ;; Which node is it from?  

          jmpFneL   bRecSource,dAdrMainCtrl,jParCAN20

;; >>>>>>>>>>>>>>>>>>> MAIN CONTROL BOARD <<<<<<<<<<<<<<<<<<

     ;; Set alive flag
          bsf       tbMainAlive ; Alive flag for Main Control Brd

     ;; toggle LED0
          toggle    tpLED0

;;Inputs in message
;;    Battery level A/D:      GP0 ( AN0 input)
;;    Key digital:            GP1 (input)

     ;; Analyse digital flags
          bV2bV     pRecDataBase+1,bGPIO
          tb2tb     bGPIO,1,tbFlgKey
          
          jmpClr    tbFlgKey,jParCAN12

     ;; Key is on.  Set KeyLED on and allowed battery level to sent
          bsf       tbFlgKeyLED

     ;; Analyse analog values
          bV2bV     pRecDataBase+2,bBatteryLevel
          goto      jParCAN14

jParCAN12
     ;; Key is off.  Set KeyLED off and set battery level to zero.
     ;; Force all valves off.
          clrf      bDigitalFlgs1       ; digital flags #1
          clrf      bDigitalFlgs2       ; digital flags #2
          clrf      bBatteryLevel

jParCAN14
          bsf       tbXmitOperBrd       ; queue xmit to Operator Brd
          goto      jParCAN50



jParCAN20 jmpFneL   bRecSource,dAdrOperCtrl,jParCAN30

;; >>>>>>> OPERATOR CONTROL BOARD <<<<<<<<<<<<<<<<<<<<

     ;; Set alive flag
          bsf       tbOperAlive  ; Alive flag for Operator Control Brd

     ;; toggle LED1
          toggle    tpLED1

;;Inputs in message
;;        Forward A/D:            GP0 (AN0 input)
;;        Reverse A/D:            GP1 (AN1 input)
;;        Horn digital:           GP3 (input)
;;        Steer Left digital:     GP4 (input)
;;        Steer Right digital:    GP5 (input)
;;        Up digital:             GP6 (input)
;;        Down digital:           GP7 (input)

     ;; Analyse digital flags
          bV2bV     pRecDataBase+1,bGPIO
          tb2tb     bGPIO,3,tbFlgHorn  
          tb2tb     bGPIO,4,tbFlgLeft  
          tb2tb     bGPIO,5,tbFlgRight 
          tb2tb     bGPIO,6,tbFlgUp  
          tb2tb     bGPIO,7,tbFlgDown

     ;; Analyse analog values
          bV2bV     pRecDataBase+2,bForward
          bV2bV     pRecDataBase+3,bReverse

          jmpFleL   bForward,dDeadZone,jParCAN23  ; in dead zone
          jmpFgtL   bReverse,dDeadZone,jParCAN25  ; both on - error

     ;; Forward motion requested. Make sure Up & Down are off
          jmpSet    tbFlgUp,jParCAN25   ; Up requested
          jmpSet    tbFlgDown,jParCAN25 ; Down requested

          bsf       tbFlgForward       ; Forward valve
          bcf       tbFlgReverse       ; Reverse valve
          bV2bV     bForward,bDCDrive
          goto      jParCAN29


jParCAN23 jmpFleL   bReverse,dDeadZone,jParCAN26  ; both in dead zone

     ;; Reverse motion requested. Make sure Up & Down are off
          jmpSet    tbFlgUp,jParCAN25   ; Up requested
          jmpSet    tbFlgDown,jParCAN25 ; Down requested

          bcf       tbFlgForward       ; Forward valve
          bsf       tbFlgReverse       ; Reverse valve
          bV2bV     bReverse,bDCDrive
          goto      jParCAN29

jParCAN25
     ;; Error => stop all motion

     ;; Turn off all valves

          bcf       tbFlgForward       ; Forward valve
          bcf       tbFlgReverse       ; Reverse valve
          bcf       tbFlgUp            ; Up valve
          bcf       tbFlgDown          ; Down valve

     ;; Turn off DC Drive 
          clrf      bDCDrive            ; DC Drive control level
          goto      jParCAN29

jParCAN26
     ;; Both in dead zone => no horizontal movement requested

     ;; Turn off both horizontal valves

          bcf       tbFlgForward       ; Forward valve
          bcf       tbFlgReverse       ; Reverse valve

     ;; Is Up or Down requested
          jmpSet    tbFlgUp,jParCAN28   ; Up requested
          jmpSet    tbFlgDown,jParCAN28 ; Down requested

     ;; DC Drive not needed - turn it off
          clrf      bDCDrive            ; DC Drive control level
          goto      jParCAN29

jParCAN28
     ;; Up or Down motion requested. Set DC Drive to 50%.
          bL2bV     127,bDCDrive

jParCAN29
          bsf       tbXmitMainDigital   ; queue xmit of flags to Main Brd
          bsf       tbXmitValveBrd      ; queue xmit to Hydraulic Brd

          skipFeqF  bDCDrive,bPrevDCDrive
          bsf       tbXmitDCDrive       ; queue xmit of DC Drive value

     ;; update previous DCDrive value
          bV2bV     bDCDrive,bPrevDCDrive
          goto      jParCAN50



jParCAN30 jmpFneL   bRecSource,dAdrValveCtrl,jParCAN40

;; >>>>>>> HYDRAULIC VALVE CONTROL BOARD <<<<<<<<<<<<<<<

     ;; No inputs in message to analyse

     ;; Set alive flag
          bsf       tbValveAlive  ; Alive flag for Hydraulic Control Brd

     ;; toggle LED2
          toggle    tpLED2

          goto      jParCAN50

jParCAN40
jParCAN50


;; End of Parse
jParCAN80
jParCAN90
          return
