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
;========= MAIN CONTROL BOARD ===========
;12/4/01
;
;;Inputs in message
;;    Battery level A/D:      GP0 ( AN0 input)
;;    Key digital:            GP1 (input)
;;
;; Outputs in message
;;    DC Drive PWM:           GP2 (PWM1 output)
;;    Battery LED digital:    GP3 (output)
;;    Key LED digital:        GP4 (output)
;;
;;============== Main Ctrl Brd ====================
;;Send                    
;;Class = 1     Brdcast=1   SubClass=0  Source=10  Cmd=0
;;
;;Receive
;;Class = 2,3   Brdcast=0   Dest=10     Source=0   Cmd=0
;;
;;
;============================================
;============================================
;Configuration
;         Set GP7 to digital input
;
;============================================
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
;; dDest      D        7     Destination address
;; dSource    S        7     Source address
;; dCmd       C        3     Reserved for hardware restrictions of node
;; extended   E        1     Must be 1 to specify and extended ID format.
;
;Num Bits   3       8     1       7          7     3    = 29
;Fields  Priority Class   0   Destination  Source Cmd
;
;; Written in 4-bytes as a pure ID:
;; 00 00 00 I2   I1 I0 C7 C6    C5 C4 C3 C2   C1 C0  B D6
;; D5 D4 D3 D2   D1 D0 S6 S5    S4 S3 S2 S1   S0 C3 C1 C0

;; Written in form used internally by 250xx and by the 2510
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
; MCP250XX.ASM  Standard Assembly File, Version 1.00    Microchip Technology, Inc.

#include "MCP250XX.INC"

;*******************************************************************************
;*******************************************************************************
; Configuration Macros
;*******************************************************************************
;*******************************************************************************

;*******************************************************************************
; DEVICE
;
; Call this macro to set the device for mixed signal (MCP2505X)
; or digital only (MCP2502X).
;
; SET_DEVICE enter MCP2505X or MCP2502X

;DEVICE SET_DEVICE
  DEVICE MCP2505X

;*******************************************************************************
; RECEIVE_BUFFERS
;
; Call this macro to set up the receive buffers.  Macro paramaters are:
;
;       MASK            message identifier [eleven (max 7FFh) or twenty nine bits (max 1FFFFFFF)]
;       MID             enter STANDARD or EXTENDED
;       FILTER0         message identifier [eleven (max 7FFh) or twenty nine bits (max 1FFFFFFF)]
;       F0ID            enter STANDARD or EXTENDED
;       FILTER1         message identifier [eleven (max 7FFh) or twenty nine bits (max 1FFFFFFF)]
;       F1ID            enter STANDARD or EXTENDED
;
;RECEIVE_BUFFERS MASK, MID, FILTER0, F0ID, FILTER1, F1ID

;; Mask for all receive buffers: 1) compare to filter, 0) ignore
;; Note that Class ignores lowest two bits so that Class 2 & 3 can be received

;;   Priority = 0, Class = 0xFC, Broadcast = 1, Dest = 0x7F, 
;;         Source = 0x7F, Cmd = 0x07
;;   29 bit ID: 0 0011 1111 0011 1111 1111 1111 1111 : 0x03F3FFFF
;;      MASK            0x03F3FFF8
;;
;; For information request messages:  set to reject all messages
;; 29 bit ID: 1 1111 1111 1111 1111 1111 1111 1111 : 0x1FFFFFFF
;;       FILTER0         0x1FFFFFFF
;;
;; For input messages:
;;   Priority = 0, Class = 0x00, Broadcast = 0, Dest = 0x0A, 
;;         Source = 0x00, Cmd = 0x00
;; 29 bit ID: 0 0000 0000 0000 0010 1000 0000 0000 : 0x00002800
;;       FILTER1         0x00002800


  RECEIVE_BUFFERS    0x03F3FFFF, EXTENDED,0x1FFFFFFF, EXTENDED,0x00002800,EXTENDED


;*******************************************************************************
; TRANSMIT_BUFFERS
;
; Call this macro to set up the transmit buffers.  Macro parameters are:
;
;       TXB0            message identifier [eleven (max 7FFh) or twenty nine bits (max 1FFFFFFF)]
;       TXB0ID          enter STANDARD or EXTENDED
;       TXB1            message identifier [eleven (max 7FFh) or twenty nine bits (max 1FFFFFFF)]
;       TXB1ID          enter STANDARD or EXTENDED
;       TXB2            message identifier [eleven (max 7FFh) or twenty nine bits (max 1FFFFFFF)]
;       TXB2ID          enter STANDARD or EXTENDED

;TRANSMIT_BUFFERS TXB0, TXB0ID, TXB1, TXB1ID, TXB2, TXB2ID

; TX0 - Used for "On Bus" message
;;   Priority = 0, Class = 0x01, Broadcast = 1, SubClass = 0x00
;;         Source = 0x0A, Cmd = 0x00
;; 29 bit ID: 0 0000 0000 0110 0000 0000 0101 0000 : 0x00060050
;       TXB2            0x00060050

; TX1 - Used for Ack and Error messages
;;   Priority = 0, Class = 0x04, Broadcast = 1, SubClass = 0x00
;;         Source = 0x0A, Cmd = 0x00
;; 29 bit ID: 0 0000 0001 0010 0000 0000 0101 0000 : 0x00120050
;       TXB1            0x00120050

; TX2 - Used for OnChange, Analog threshold triggered, and scheduled  messages
;;   Priority = 0, Class = 0x01, Broadcast = 1, SubClass = 0x00
;;         Source = 0x0A, Cmd = 0x00
;; 29 bit ID: 0 0000 0000 0110 0000 0000 0101 0000 : 0x00060050
;       TXB2            0x00060050

  TRANSMIT_BUFFERS  0x00060050,EXTENDED,0x00120050,EXTENDED,0x00060050,EXTENDED

;*******************************************************************************
; CAN_BIT_TIMING
;
; Call this macro to set up the CAN bit timing.  Macro parameters are:
;
;       BRP     Baud Rate Prescaler     enter a value from 0 to 0x3F
;       SJW     Synchronized Jump Width enter a value from 1 to 4
;       PS1     Phase 1 Segment Width   enter a value from 1 to 8
;       PS2     Phase 2 Segment Width   enter a value from 2 to 8
;       PROP    Propagation Width       enter a value from 1 to 8
;       SP      Sample Point            enter TIMES_3 or TIMES_1
;       P2S     Phase 2 Source          enter PHASE2 or PHASE1_IPT
;       WF      Wake-up Filter          enter ENABLED or DISABLED

;CAN_BIT_TIMING   BRP, SJW, PS1, PS2, PROP, SP, P2S, WF

  CAN_BIT_TIMING 7, 1, 3, 3, 1, TIMES_1, PHASE2, DISABLED

;*******************************************************************************
; CAN_MODE
;
; Call this macro to set up the initial CAN mode.  Macro parameters are:
;
; MODE  enter NORMAL or LISTEN_ONLY
; PUMODE  enter PWRUP_NORM or PWRUP_LO
; TXID1MSG enter CMD_ACK or RX_OVRFLW
; ERROR_RECOVERY  enter ERR_RECVRY_LO or ERR_RECVRY_NORM
; TX_ON_ERROR enter TX_ON_ERR or NO_TX_ON_ERR
; SLEEPMODE enter SLEEP_EN or SLEEP_DIS
; MSGTYPE enter MSG_TYPE_DATA or MSG_TYPE_RTR
; PWM_POR enter PWM_POR_DEF OR PWM_POR_UNCH
; LOTOSLEEP enter LO_TO_SLEEP_EN OR LO_TO_SLEEP_DIS

;CAN_MODE MODE, PUMODE, TXID1MSG, ERROR_RECOVERY, TX_ON_ERROR, SLEEPMODE, MSGTYPE, PWM_POR, LOTOSLEEP

 CAN_MODE  NORMAL,PWRUP_NORM,RX_OVRFLW,ERR_RECVRY_NORM,NO_TX_ON_ERR,SLEEP_DIS,MSG_TYPE_RTR,PWM_POR_DEF,LO_TO_SLEEP_DIS

;*******************************************************************************
; SCHEDULED_TRANSMISSION
;
; Call this macro to set up scheduled transmission.  Macro parameters are:
;
;       MODE            enter ENABLED or DISABLED
;       INFO            enter NONE or ADC_RESULT
;       MULTIPLIER      enter a value from 1 to 0x10
;       FREQUENCY       enter X1_4096TOSC, X16_4096TOSC, X256_4096TOSC, or
;                               X4096_4096TOSC

;SCHEDULED_TRANSMISSION  MODE, INFO, MULTIPLIER, FREQUENCY

 SCHEDULED_TRANSMISSION  ENABLED,ADC_RESULT,2,X256_4096TOSC

;*******************************************************************************
; CLOCK_OUT
;
; Call this macro to configure the Clock Out Function.  Macro parameters are:
;
;       MODE            enter ENABLED or DISABLED
;       PRESCALER       enter CLK_FOSC, CLK_FOSC_2, CLK_FOSC_4, or CLK_FOSC_8

;CLOCK_OUT MODE, PRESCALER

 CLOCK_OUT  DISABLED,CLK_FOSC

;*******************************************************************************
; IO_DIRECTION
;
; Call this macro to set up the I/O direction for the  digital I/O's.
; Macro parameters are:
;
;       B6              enter INPUT or OUTPUT for pin GP6
;       B5              enter INPUT or OUTPUT for pin GP5
;       B4              enter INPUT or OUTPUT for pin GP4
;       B3              enter INPUT or OUTPUT for pin GP3
;       B2              enter INPUT or OUTPUT for pin GP2
;       B1              enter INPUT or OUTPUT for pin GP1
;       B0              enter INPUT or OUTPUT for pin GP0
;
;IO_DIRECTION    MACRO   B6, B5, B4, B3, B2, B1, B0

 IO_DIRECTION  INPUT,INPUT,OUTPUT,OUTPUT,OUTPUT,INPUT,INPUT

;*******************************************************************************
; IO_LATCH
;
; Call this macro to set the latch values for the digital I/O's.  Macro
; parameters are:
;
;       B6              enter 0 or 1 for pin GP6
;       B5              enter 0 or 1 for pin GP5
;       B4              enter 0 or 1 for pin GP4
;       B3              enter 0 or 1 for pin GP3
;       B2              enter 0 or 1 for pin GP2
;       B1              enter 0 or 1 for pin GP1
;       B0              enter 0 or 1 for pin GP0

;IO_LATCH  B6, B5, B4, B3, B2, B1, B0

 IO_LATCH 0,0,0,0,0,0,0

;*******************************************************************************
; IO_FUNCTION
;
; Call this macro to set the pin function to analog or digital.  Macro
; parameters are:
;
;       B3              enter ANALOG or DIGITAL for pin AN3
;       B2              enter ANALOG or DIGITAL for pin AN2
;       B1              enter ANALOG or DIGITAL for pin AN1
;       B0              enter ANALOG or DIGITAL for pin AN0

;IO_FUNCTION  B3, B2, B1, B0

 IO_FUNCTION  DIGITAL,DIGITAL,DIGITAL,ANALOG

;*******************************************************************************
; IO_XMIT_ON_CHANGE
;
; Call this macro to set the Transmit on Change for each pin.  Macro parameters
; are:
;
;       B7              enter DISABLED, IO_RISE, or IO_FALL for pin GP7
;       B6              enter DISABLED, IO_RISE, or IO_FALL for pin GP6
;       B5              enter DISABLED, IO_RISE, or IO_FALL for pin GP5
;       B4              enter DISABLED, IO_RISE, or IO_FALL for pin GP4
;       B3              enter DISABLED, IO_RISE, or IO_FALL for pin GP3
;       B2              enter DISABLED, IO_RISE, or IO_FALL for pin GP2
;       B1              enter DISABLED, IO_RISE, or IO_FALL for pin GP1
;       B0              enter DISABLED, IO_RISE, or IO_FALL for pin GP0

;IO_XMIT_ON_CHANGE   B7, B6, B5, B4, B3, B2, B1, B0

 IO_XMIT_ON_CHANGE DISABLED,DISABLED,DISABLED,DISABLED,DISABLED,DISABLED,IO_RISE,DISABLED


;*******************************************************************************
; IO_WEAK_PULLUPS
;
; Call this macro to configure weak pull-ups.  Macro parameters are:
;
;       MODE            enter ENABLED or DISABLED

; IO_WEAK_PULLUPS MODE

 IO_WEAK_PULLUPS DISABLED

;*******************************************************************************
; PWM1
;
; Call this macro to configure PWM1.  Macro parameters are:
;
;       TMRON           enter ENABLED or DISABLED
;       PRESCALER       Timer Prescaler; enter 1, 4, or 0x10
;       PERIOD          PWM Period; enter a value from 0 to 0xFF
;       DUTY_CYCLE      PWM Duty Cycle; enter a value from 0 to 0x3FF

;PWM1 TMRON, PRESCALER, PERIOD, DUTY_CYCLE

 PWM1 ENABLED,1,0xFF,0x200        ; 50%


;*******************************************************************************
; PWM2
;
; Call this macro to configure PWM2.  Macro parameters are:
;
;       TMRON           enter ENABLED or DISABLED
;       PRESCALER       Timer Prescaler; enter 1, 4, or 0x10
;       PERIOD          PWM Period; enter a value from 0 to 0xFF
;       DUTY_CYCLE      PWM Duty Cycle; enter a value from 0 to 0x3FF

;PWM2 TMRON, PRESCALER, PERIOD, DUTY_CYCLE

 PWM2 DISABLED,1,0xFF,0


;*******************************************************************************
; ADC_SETUP
;
; Call this macro to set up the ADC.  Macro parameters are:
;
;       MODE            enter ENABLED or DISABLED
;       SEQ_DELAY       Minimum Sequence Delay; enter TOSC32, TOSC64, TOSC128,
;                               TOSC256, TOSC512, TOSC1024, TOSC2048, or TOSC4096
;       CLOCK_SOURCE    Clock Source; enter ADC_FOSC_2, ADC_FOSC_8, ADC_FOSC_32,
;                               or ADC_FRC
;       VREF_POS        Vref+ Source; enter VDD or EXTERNAL
;       VREF_NEG        Vref- Source; enter VSS or EXTERNAL
;       TIME            Acquisition Time; enter X1_64TOSC, X2_64TOSC, X4_64TOSC,
;                               or X8_64TOSC
;
; Note: Be sure to call the macro IO_FUNCTION to configure the pins as
;       analog or digital.

;ADC_SETUP MODE, SEQ_DELAY, CLOCK_SOURCE, VREF_POS, VREF_NEG, TIME

; auto-conversion rate: (Fosc/4/256)/512 = 33 mS
 ADC_SETUP ENABLED,TOSC512,ADC_FOSC_32,VDD,VSS,X1_64TOSC


;*******************************************************************************
; ADC_COMPARES
;
; Call this macro to set up the ADC compare values.  Macro parameters are:
;
;       CHANNEL0        enter a value from 0 to 0x3FF
;       CHANNEL1        enter a value from 0 to 0x3FF
;       CHANNEL2        enter a value from 0 to 0x3FF
;       CHANNEL3        enter a value from 0 to 0x3FF

;ADC_COMPARES CHANNEL0, CHANNEL1, CHANNEL2, CHANNEL3

  ADC_COMPARES  0x3FF, 0x3FF, 0x3FF, 0x3FF


;*******************************************************************************
; SET_USER#
;
; Call these macros to set the user data values.  Macro parameters are:
;
;       VALUE   enter a value from 0 to 0xFF

        SET_USER0               0xFF
        SET_USER1               0xFF
        SET_USER2               0xFF
        SET_USER3               0xFF
        SET_USER4               0xFF
        SET_USER5               0xFF
        SET_USER6               0xFF
        SET_USER7               0xFF
        SET_USER8               0xFF
        SET_USER9               0xFF
        SET_USERA               0xFF
        SET_USERB               0xFF
        SET_USERC               0xFF
        SET_USERD               0xFF
        SET_USERE               0xFF
        SET_USERF               0xFF

;
; Generate Configuration Information - REQUIRED!
        GENERATE

        END
