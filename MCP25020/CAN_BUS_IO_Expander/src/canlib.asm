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
;**********************************************************
; Supports DEI message protocol
; Last modification 10/18/01
;**********************************************************


; MCP2510 Instructions
#define d2510Rd      0x03      ; MCP2510 read instruction
#define d2510Wrt     0x02      ; MCP2510 write instruction
#define d2510Reset   0xC0      ; MCP2510 reset instruction
#define d2510RTS     0x80      ; MCP2510 RTS instruction
#define d2510Status  0xA0      ; MCP2510 Status instruction
#define d2510BitMod  0x05      ; MCP2510 bit modify instruction



;**********************************************************
;*************** SPECIAL CAN MACROS ***********************
;**********************************************************

; Read 2510 register Reg and return data in W.
SPI_Read macro Reg
          movlw     Reg
          call      Rd2510Reg
          endm

; Write literal byte to 2510 register Reg.
SPI_WriteL macro Reg,LitData
          movlw     LitData
          movwf     b2510RegData
          movlw     Reg
          call      Wrt2510Reg
          endm

; Write Data byte to 2510 register Reg.
SPI_WriteV macro Reg,RegData
          movfw     RegData
          movwf     b2510RegData
          movlw     Reg
          call      Wrt2510Reg
          endm

; Write W byte to 2510 register Reg.
SPI_WriteW macro Reg
          movwf     b2510RegData
          movlw     Reg
          call      Wrt2510Reg
          endm


; Write bits determined by Mask & Data to 2510 register Reg.
SPI_BitMod macro Reg,Mask,Data
          movlw     Mask
          movwf     b2510RegMask
          movlw     Data
          movwf     b2510RegData
          movlw     Reg
          call      BitMod2510
          endm

; Arm xmit buffers for xmission
SPI_Rts macro Data
          movlw     Data
          call      Rts2510
          endm


;**********************************************************
;**********************************************************
;Support routines for communicating with 2510 chip
;**********************************************************
;**********************************************************

;******************************************************
;CheckCANMsg
;
; Checks for message in Receive Buf 1.  If no message pending return
; with Z flag set.
;         
; If message pending:
;     Decodes bRecClass, bRecSubDest, bRecSource, bRecCmd 
;         and tbRecBroadcast.
;     Sets bRecCount with number of bytes of data received.
;     Load buffer at pRecDataBase with data
;     Clear 2510 Receive Buffer 1 interrupt flag
;     Set tbRxMsgPend flag and clear Z flag.
;
; NOTE: If message already pending doesn't check for new message
;     hence user must reset tbRxMsgPend before a new message can
;     be decoded.
;
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
;******************************************************/
CheckCANMsg

          bcf       _Z                  ; for return
          skipClr   tbRxMsgPend         ; new CAN message received
          return                        ; Message already pending

     ;; Test for Message pending in Receive Buffer 1
          SPI_Read  CANINTF
          andlw     0x02      

          skipNZ
          return              ; Nothing in Rec Buf 1

          bsf       tbRxMsgPend         ; new CAN message received

     ;; Get Class of message
          SPI_Read  RXB1SIDH        ; SID10 -> SID3 
          movwf     bRecClass       
          SPI_Read  RXB1SIDL        ; SID2 -> SID0 in upper 3 bits 
          movwf     bRecSubDest    ; use as temporary work register
          rlf       bRecSubDest,F  ; SID2 -> C
          rlf       bRecClass,F
          rlf       bRecSubDest,F  ; SID1 -> C
          rlf       bRecClass,F
          rlf       bRecSubDest,F  ; SID0 -> C: EID17,EID16 in bits 4,3
          rlf       bRecClass,F     ; now contains SID7 -> SID0

     ;; Get SubClass/Destination field of message
          SPI_Read  RXB1EID8
          movwf     bRecWork        ; EID15 -> EID8  (use as working)
          clrf      bRecSource      
          bcf       _C
          rrf       bRecWork,F      ; EID8 -> C:  0,EID15-EID9
          rrf       bRecSource,F    ; EID8,0,0,0,0,0,0,0; 0->C

          rrf       bRecWork,F      ; EID9 -> C: 0,0,EID15 -> EID10 
          rrf       bRecSource,F    ; EID9,EID8,0,0,0,0,0,0

          ;; move EID17,EID16 to upper two bits

          rrf       bRecSubDest,F    ; EID17,EID16 in bits 3,2
          swapf     bRecSubDest,W    ; EID17,EID16,x,x,x,x,x,x
          andlw     0xC0              ; EID17,EID16,0,0,0,0,0,0
          iorwf     bRecWork,W        ; EID17 -> EID10 
          movwf     bRecSubDest      ; EID17 -> EID10

     ;; Get Broadcast flag
          bcf       tbRecBroadcast
          jmpClr    bRecSubDest,7,jRxChk1
          bsf       tbRecBroadcast
          bcf       bRecSubDest,7   ; remove broadcast flag:0,EID16 -> EID10
jRxChk1


     ;; Get Source & Cmd fields of message
          bcf       _C
          rrf       bRecSource,F    ; 0,EID9,EID8,0,0,0,0,0

          SPI_Read  RXB1EID0
          movwf     bRecWork        ; EID7 -> EID0
          andlw     0x07            ; mask out all but Cmd bits   
          movwf     bRecCmd         ; 0,0,0,0,0,EID2 -> EID0

          rrf       bRecWork,F      ; x,EID7-EID1
          rrf       bRecWork,F      ; x,x,EID7-EID2
          rrf       bRecWork,W      ; x,x,x,EID7-EID3
          andlw     0x1F            ; mask out bits:0,0,0,EID7-EID3   
          iorwf     bRecSource,F    ; 0,EID9-EID3

     ;; Get number of bytes of data
          SPI_Read  RXB1DLC
          andlw     0x0F
          movwf     bRecCount

     ;; Get data from buffer. Up to 8 bytes based on 
          clrf      bCnt

jRxChk11  jmpFeqF   bCnt,bRecCount,jRxChk90            ; no data left

     ;; Calculate correct 2510 receive buffer location
          movlw     RXB1D0
          addwf     bCnt,W

     ;; Get data byte
          call      Rd2510Reg
          movwf     b2510RegData     ; temporary save

     ;; Calculate destination buffer location
          movlw     pRecDataBase
          addwf     bCnt,W
          movwf     FSR

     ;; Store data in buffer
          movfw     b2510RegData     ; temporary save
          movwf     INDF
          incf      bCnt,F
          goto      jRxChk11

jRxChk90
          SPI_BitMod CANINTF,0x02,0     ; Clear receive buffer 1 interrupt
          bcf       _Z                  ; signal data pending
          return


;**********************************************************
;SetConfigMode
;
;// Function Name: Set_Config_Mode()
;**********************************************************
SetConfigMode
;  SPI_BitMod(CANCTRL, 0xE0, 0x80);    //Config. mode/
          bL2bV     0xE0,b2510RegMask
          bL2bV     0x80,b2510RegData
          movlw     CANCTRL
          call      BitMod2510

jSetConfigM1
          movlw     CANSTAT
          call      Rd2510Reg
          andlw     0xE0
          xorlw     0x80
          jmpNZ     jSetConfigM1

          return


;**********************************************************
;SetNormalMode
;
;// Function Name: Set_Normal_Mode()
;**********************************************************
SetNormalMode

          bL2bV     0xE0,b2510RegMask
          bL2bV     0x00,b2510RegData
          movlw     CANCTRL
          call      BitMod2510

jSetNormalM1
          movlw     CANSTAT
          call      Rd2510Reg
          andlw     0xE0
          jmpNZ     jSetNormalM1

          return

;**********************************************************
;WaitANDeqZ
;         Fetch byte from address in W.
;         AND it with mask in b2510RegMask.
;         Return if results is zero else keep trying.
;         Uses b2510RegAdr to hold address.
;         
;**********************************************************
WaitANDeqZ
          movwf     b2510RegAdr         ; save

jWaitANDeqZ
          movfw     b2510RegAdr         ; save
          call      Rd2510Reg
          andwf     b2510RegMask,W
          jmpNZ     jWaitANDeqZ
          return


;**********************************************************
;TestANDeqZ
;         Fetch byte from address in W.
;         AND it with mask in b2510RegMask.
;         Return Z flag set if results is zero else clear Z.
;         
;**********************************************************
TestANDeqZ
          call      Rd2510Reg
          andwf     b2510RegMask,W
          return



;**********************************************************
;**********************************************************


;**********************************************************
;**************** BASIC COMMUNICATION *********************
;**********************************************************


;**********************************************************
;Get2510Status
;         Get Status byte from 2510.
;// Function Name: SPI_ReadStatus()
;**********************************************************
Get2510Status
          call      InitSPIBuf
          movlw     d2510Status          ; MCP2510 Status instruction
          call      LoadSPIByte
          movlw     1                   ; expect 1 byte answer
          call      LoadSPIZeros
          call      ExchangeSPI
          call      WaitSPIExchange
          return

;**********************************************************
;Rd2510Reg
;         Read 2510 register at address in W. Return results
;         in W. Uses b2510RegAdr to hold address.
;// Function Name: SPI_Read(uint address)
;**********************************************************
Rd2510Reg
          movwf     b2510RegAdr         ; save
          call      InitSPIBuf
          movlw     d2510Rd              ; MCP2510 read instruction
          call      LoadSPIByte
          movfw     b2510RegAdr         ; get address
          call      LoadSPIByte
          movlw     1                   ; expect 1 byte answer
          call      LoadSPIZeros
          call      ExchangeSPI
          call      WaitSPIExchange
          movfw     pSPIBufBase+2
          return

;**********************************************************
;Wrt2510Reg
;         Write byte in b2510RegData to 2510 register at location in W. 
;         Uses b2510RegAdr to hold address.
;// Function Name: SPI_Write(uint address)
;**********************************************************
Wrt2510Reg
          movwf     b2510RegAdr         ; save
          call      InitSPIBuf
          movlw     d2510Wrt             ; MCP2510 write instruction
          call      LoadSPIByte
          movfw     b2510RegAdr         ; get address
          call      LoadSPIByte
          movfw     b2510RegData        ; get data
          call      LoadSPIByte
          call      ExchangeSPI
          call      WaitSPIExchange
          return


;**********************************************************
;BitMod2510
;// Function Name: SPI_BitMod()
;         Write data in b2510RegData using mask in b2510RegMask to 
;         address in W. Uses b2510RegAdr to hold address.
;**********************************************************
BitMod2510
          movwf     b2510RegAdr         ; save
          call      InitSPIBuf

          movlw     d2510BitMod         ; MCP2510 bit modify instruction
          call      LoadSPIByte

          movfw     b2510RegAdr         ; address
          call      LoadSPIByte

          movfw     b2510RegMask        ; mask
          call      LoadSPIByte

          movfw     b2510RegData        ; data
          call      LoadSPIByte

          call      ExchangeSPI
          call      WaitSPIExchange
          return


;**********************************************************
;Rts2510
;         Request to send to MCP2510.
;         Send the request to send instruction to the CANbus Controller ORed
;         with value in W.  Uses b2510RegData.
;// Function Name: SPI_Reset()
;**********************************************************
Rts2510
          movwf     b2510RegData
          call      InitSPIBuf

          movlw     d2510RTS            ; MCP2510 RTS instruction
          iorwf     b2510RegData,W      ; get data and OR it with RTS
          call      LoadSPIByte

          call      ExchangeSPI
          call      WaitSPIExchange
          return


;**********************************************************
;Reset2510
;         Reset MCP2510.
;// Function Name: SPI_Reset()
;**********************************************************
Reset2510
          call      InitSPIBuf
          movlw     d2510Reset           ; MCP2510 reset instruction
          call      LoadSPIByte
          call      ExchangeSPI
          call      WaitSPIExchange
          return



;**********************************************************
;***************** LOCAL - DON'T CALL DIRECTLY ************
;**********************************************************

;**********************************************************
;InitSPIPort
;         Intialize SPI port
;**********************************************************
InitSPIPort
        BANK0
          bcf       _SSPEN         ; disable SPI     
          movlw     0x11           ; SPI Master, Idle high, Fosc/16
          movwf     SSPCON
          bsf       _SSPEN         ; enable SPI     
          bcf       _SSPIF         ; clear interrupt flag
          BANK1
          bsf       _SSPIE_P       ; SSP int enable (BANK 1)
          BANK0
          return

;**********************************************************
;InitSPIBuf
;         Initializes SPI buffer for transaction.  Sets up
;         FSR as buffer pointer.
;**********************************************************
InitSPIBuf
          clrf      bSPICnt
          movlw     pSPIBufBase
          movwf     pSPIBuf
          movwf     FSR
          return

;**********************************************************
;LoadSPIByte
;         Load byte in W to SPI buffer.  Assumes FSR is pointer.
;**********************************************************
LoadSPIByte
          movwf     INDF
          incf      FSR,F
          return

;**********************************************************
;LoadSPIZeros
;         Load number of zeros in W to SPI buffer.  
;         Assumes FSR is pointer.
;**********************************************************
LoadSPIZeros
          andlw     0xFF
          skipNZ
          return                        ; finished
          clrf      INDF
          incf      FSR,F
          addlw     0xFF                ; Subtract 1 from W
          jmpNZ     LoadSPIZeros
          return

;**********************************************************
;ExchangeSPI
;         Initiate SPI transaction.  
;**********************************************************
ExchangeSPI
     ;; Get number of bytes to exchange
          bV2bV     FSR,bSPICnt
          movlw     pSPIBufBase
          subwf     bSPICnt,F

          skipNZ
          return                        ; nothing to exchange

          movlw     pSPIBufBase
          movwf     pSPIBuf

     ;; Load 1st byte to begin exchange
          bcf       tp2510_CS_           ; CS_ for 2510 chip
          movfw     pSPIBufBase         ; get 1st byte in buffer
          movwf     SSPBUF              ; send it
          return


;**********************************************************
;WaitSPIExchange
;         Wait for SPI transaction to be completed.
;**********************************************************
WaitSPIExchange
          jmpFneZ   bSPICnt,WaitSPIExchange
          return

