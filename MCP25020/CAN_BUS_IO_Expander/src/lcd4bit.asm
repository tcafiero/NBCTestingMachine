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
;******************* LCD HANDLER **************************
;**********************************************************
;Uses PORT? as bus
;
;You must define the 3 control lines to control the LCD.
;#define  tpLCD_RW     PORT?,?     ; read/write line	
;#define  tpLCD_RS     PORT?,?     ; command/data line
;#define  tpLCDEnable  PORT?,?     ; chip select line
;**********************************************************
;********************************************************************
;                  Binary To BCD Conversion Routine
;      This routine converts a 16 Bit binary Number to a 5 Digit
; BCD Number.
;
;       The 16 bit binary number is input in locations iA_H and
; iA with the high byte in iA_H.
;       The 5 digit BCD number is returned in bBCD_5, bBCD43 and bBCD21 
;       with bBCD_5 containing the MSD in its right most nibble.
;
;   Performance :
;               Program Memory  :       35
;               Clock Cycles    :       885
;
;         Stack  2
;*******************************************************************;
iA2BCD    bcf     STATUS,0         ; clear the carry bit
          movlw   0x10
          movwf   _bcount
          clrf    bBCD_5
          clrf    bBCD43
          clrf    bBCD21
_iABCD_1  rlf     iA,F
          rlf     iA+1,F
          rlf     bBCD21,F
          rlf     bBCD43,F
          rlf     bBCD_5,F
;
          decfsz  _bcount,F
          goto    _iABCD_2
          retlw    0x00
;
_iABCD_2  movlw   bBCD21
          movwf   FSR
          call    _iABCD_3
;
          movlw   bBCD43
          movwf   FSR
          call    _iABCD_3
;
          movlw   bBCD_5
          movwf   FSR
          call    _iABCD_3
;
          goto    _iABCD_1
;
_iABCD_3  movlw   3
          addwf   0,W
          movwf   _btemp
          btfsc   _btemp,3         ; test if result > 7
          movwf   0
          movlw   0x30
          addwf   0,W
          movwf   _btemp
          btfsc   _btemp,7         ; test if result > 7
          movwf   0                ; save as MSD
          retlw    0x00
;
;**********************************************************
;ClearDisp
;       Clear display
;  
;         Stack 2  
;**********************************************************
ClearDisp
          movlw     0x01                 
          goto      WrtLCDInstr


;**********************************************************
;DispHex
;       Display two digit hex value in W on LCD at current address.
;  
;       Uses iA. 
;         Stack 3  
;**********************************************************
DispHex
          movwf    iA+1           ; save
          movwf    iA  
          rrf      iA,F
          rrf      iA,F
          rrf      iA,F
          rrf      iA,F
          movf     iA,W
          call     DispHexDig
          movf     iA+1,W
          call     DispHexDig
          return


;**********************************************************
;DispHexDig
;       Display one digit hex value in W on LCD at current address.
;  
;       Uses iA. 
;         Stack 2  
;**********************************************************
DispHexDig
          andlw    0x0F
          addlw    0x30
          movwf    iA
          jmpWleL  0x39,jDispHxD1
          movlw    0x07
          addwf    iA,F
jDispHxD1 movf     iA,W
          goto     WrtLCDData



;**********************************************************
;Disp2Number
;       Display 2 digit value in iA on LCD at current address.
;       Do not remove leading 0.  
;  
;        
;         Stack 3  
;**********************************************************
Disp2Number
     ;; convert to BCD
          call      iA2BCD              ; convert to 4 BCD digits in bBCD43 & bBCD21
     ;; remove leading zeros
          clrf      iB                  ; use to signal all zeros so far
          incf      iB,F                ; disable leading zero suppresion
          goto      jDisp2Number


;**********************************************************
;Disp3Number
;       Display 3 digit value in iA on LCD at current address.
;  
;        
;         Stack 3  
;**********************************************************
Disp3Number
     ;; convert to BCD
          call      iA2BCD              ; convert to 4 BCD digits in bBCD43 & bBCD21

     ;; remove leading zeros
          clrf      iB                  ; use to signal all zeros so far
          goto      jDisp3Number


;**********************************************************
;Disp4NumberZ
;       Display 4 digit value in iA on LCD at current address.
;       Don't remove leading zeros
;        
;         Stack 3  
;**********************************************************
Disp4NumberZ
     ;; convert to BCD
          call      iA2BCD              ; convert to 4 BCD digits in bBCD43 & bBCD21
          bsf       iB,0             ; don't remove leading zeros
          goto jDisp4Number

;**********************************************************
;Disp4Number
;       Display 4 digit value in iA on LCD at current address.
;  
;        
;         Stack 3  
;**********************************************************
Disp4Number
     ;; convert to BCD
          call      iA2BCD              ; convert to 4 BCD digits in bBCD43 & bBCD21

     ;; remove leading zeros
            clrf       iB            ; use to signal all zeros so far

     ;; convert to local LCD digits

jDisp4Number
            swapf    bBCD43,W        ; load and swap left & right nibbles
            andlw    0x0f         
            call     DispToL_LZ      ; check for leading zero
            call     WrtLCDData

jDisp3Number
            movf     bBCD43,W        ; load left & right nibbles
            andlw    0x0f         
            call     DispToL_LZ      ; check for leading zero
            call     WrtLCDData

jDisp2Number
            swapf    bBCD21,W        ; load and swap left & right nibbles
            andlw    0x0f         
            call     DispToL_LZ      ; check for leading zero
            call     WrtLCDData

            movf     bBCD21,W        ; load left & right nibbles
            andlw    0x0f         
            addlw    0x30
            call     WrtLCDData
            return

DispToL_LZ  
          ;; BCD nipple in W, Z flag set if it is 0
            jmpSet   iB,0,jDispNum_5 ; no longer looking for leading zeros
            jmpZ     jDispNum_4         ; it is a leading zero
            incf     iB,F            ; end of leading zeros
            goto     jDispNum_5     

jDispNum_4  movlw    0x20            ; replace with blank
            return

          ;; make into ASCII digit
jDispNum_5  addlw    0x30
            return

;**********************************************************
;LCDInit
;        
;           Initialize LCD module
;
;         Stack 4  
;**********************************************************
LCDInit
;; wait at least 15 mSec
            movlw    15              ; 15 mSec delay before begin
            call     WaitMSec

;;Reset Sequence
            movlw    0x33             
            call     WrtLCDResetSeq

            movlw    0x32           
            call     WrtLCDResetSeq

;;Instructions
            movlw    0x28            ; Function set: 4 bit data
            call     WrtLCDInstr

            movlw    0x06            ; Entry Mode: Inc 1, no shift
            call     WrtLCDInstr

            movlw    0x0C            ; Display ON, Cursor off, no blink
            call     WrtLCDInstr

            movlw    0x01            ; Display Clear
            call     WrtLCDInstr
            
            movlw    15              ; 15 mSec delay before begin
            call     WaitMSec

	    return


;**********************************************************
;WrtLCDResetSeq
;        
;**********************************************************
WrtLCDResetSeq
	movwf	bLCDData

          bcf       tpLCD_RS            ; LCD RS line

     ;; Send upper nibble 1st
	swapf     bLCDData,W       
          andlw     0x0F
          movwf     bLCDTemp
          bcf       _C
          rlf       bLCDTemp,W
          movwf     PORTB

          bsf       tpLCDEnable      
          nop                       
          nop                       
          nop                    
          bcf       tpLCDEnable

          movlw     5               
          call      WaitMSec
	
     ;; Send lower nibble 2nd
	movfw     bLCDData
          andlw     0x0F
          movwf     bLCDTemp
          bcf       _C
          rlf       bLCDTemp,W
          movwf     PORTB

          bsf       tpLCDEnable      
          nop                       
          nop                       
          nop                    
          bcf       tpLCDEnable

          movlw     1
          call      WaitMSec
          return

;**********************************************************
;WrtLCDAdrBuf
;        
;         Write to LCD bCnt bytes at FSR where 1st byte is
;         LCD address.  Cannot contain 0 bytes.
;
;         Stack 3  
;**********************************************************
WrtLCDAdrBuf
          movf     INDF,W
          call     WrtLCDInstr
          incf     FSR,F
          decf     bCnt,F

;**********************************************************
;WrtLCDBuf
;        
;           Write to LCD bCnt bytes at FSR.
;
;         Stack 3  
;**********************************************************
WrtLCDBuf
          movf     bCnt,F
          skipNZ
          return
          movf     INDF,W
          call     WrtLCDData
          incf     FSR,F
          decf     bCnt,F
          goto     WrtLCDBuf

;**********************************************************
;WrtLCDInstr
;        
;           Write instruction in W to LCD
;
;**********************************************************
WrtLCDInstr
       	bcf      tpLCD_RS        ; LCD RS line
         goto     WrtLCDByte
            
;**********************************************************
;WrtLCDData
;        
;           Write data byte in W to LCD
;
;**********************************************************
WrtLCDData
       	bsf      tpLCD_RS        ; LCD RS line
       ;; fall through to WrtLCDByte

;**********************************************************
;WrtLCDData
;        
;           Write byte in W to LCD - must set Data or Intruc 1st.
;
;**********************************************************

WrtLCDByte
	movwf	bLCDData

     ;; Send upper nibble 1st
	swapf     bLCDData,W       
          andlw     0x0F
          movwf     bLCDTemp
          bcf       _C
          rlf       bLCDTemp,W
          movwf     PORTB

          bsf       tpLCDEnable      
          nop                       
          nop                       
          nop                    
          bcf       tpLCDEnable

     ;; Send lower nibble 2nd
	movfw     bLCDData
          andlw     0x0F
          movwf     bLCDTemp
          bcf       _C
          rlf       bLCDTemp,W
          movwf     PORTB

          bsf       tpLCDEnable      
          nop                       
          nop                       
          nop                    
          bcf       tpLCDEnable

          Set1LClock bLCDData,20         ; ~ 40 uS
jWrtLCDByte1
          jmp1LNotYet bLCDData,jWrtLCDByte1
          return


