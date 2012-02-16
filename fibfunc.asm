; This is a fib program calculates up to 0x2F (47 decimal)
; for Marc Cleave's Titan Processor
; Copyright (C) 2012 Marc Cleave, bootnecklad@gmail.com
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
; GNU General Public License for more details.
; 
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

.WORD SERIAL_PORT_0 0xFFFD

.DATA HASH_TABLE 0x00 0x01 0x02 0x03 0x04 0x05 0x06 0x07 
                 0x08 0x09 0x00 0x00 0x00 0x00 0x00 0x00 
                 0x0A 0x0B 0x0C 0x0D 0x0E 0x0F

.DATA HASH_TABLE_BYTE 0x30 0x31 0x32 0x33 0x34 0x35 0x36 0x37
                      0x38 0x39 0x00 0x00 0x00 0x00 0x00 0x00
                      0x00 0x41 0x42 0x43 0x44 0x45 0x46

.ASCIZ ERROR "That value of fib cannot be calculated :("

.BYTE MAXFIB 0x2F  ; Fib 47 is largest value that can be stored in 32bits


BEGIN:
   LDC R1,0x1B   ; ASCII 'ESC' value


INPUT:
   LDM R0,SERIAL_PORT_0 ; Gets upper nybble of hex value of fib value to calc
   PSH R0               ; Saves before testing
   TST R0               ; If zero, nothing was fetched
   JPZ INPUT            ; Try again
   LDM R0,SERIAL_PORT_0 ; Gets lower nybble of hex value of fib value to calc
   PSH R0               ; Saves before testing
   TST R0               ; If zero, no value was fetched
   JPZ INPUT            ; Try again
   XOR R0,R1            ; Compares with ESC value, if ESC then start all over again
   JPZ INPUT            ; Start again!


ASCIITOBYTE:
   POP R1       ; Low nybble of fib value
   LDC R0,0x30  ; Remove constant from ASCII value, makes table smaller.
   SUB R0,R1    ; R1 = R1 - R0
   LDI R2,HASH_TABLE[R1]
   POP R1       ; High nybble of fib value
   SUB R0,R1    ; Removes constant
   LDI R3,HASH_TABLE[R1]
   ADD R3,R2    ; Combines high and low nybbles to create binary fib value
   MOV R2,R8    ; R8 will store counter


PREP:          ; Clears registers that hold values
   CLR R0      ; Fourth byte of Fn-2
   CLR R1      ; Third byte of Fn-2
   CLR R2      ; Second byte of Fn-2
   CLR R3      ; First byte of Fn-2
   CLR R4      ; Fourth byte of Fn-1
   CLR R5      ; Third byte of Fn-1
   CLR R6      ; Second byte of Fn-1
   CLR R7      ; First byte of Fn-1
   LDC R9,0x01 ; Holds decrement value and beginning value.
   MOV R9,R7   ; Sets up first number


LOOP:         ; Where the business goes down aw yea ;)
   PSH R7
   PSH R6
   PSH R5
   PSH R4     ; Fn-1 pushed onto stack
   JPS ADD32  ; Calls the 32bit add function
   SUB R9,R8  ; Decrements counter
   JPZ OUT    ; If zero then number calculated is done, so output!
   POP R0
   POP R1
   POP R2
   POP R3     ; Pops previous value of Fn-1 into Fn-2.
   JMP LOOP   ; See recursion, recursion


ADD32:        ; Adds Fn-1 and Fn-2
   ADD R3,R7  ; Adds first byte of both numbers
   JPC FBC1   ; If carry bit set then overflow occured, increment
ADDSB:
   ADD R2,R6  ; Adds second byte of both numbers
   JPC SBC1   ; Check for carry bit
ADDTB:
   ADD R1,R5  ; Adds third byte of both numbers
   JPC TBC1   ; Check for carry bit
ADDFB
   ADD R0,R4  ; Adds fourth byte of both numbers
   JPC ERR    ; This shouldnt occur, will do if you enter in bigger value than 0x2F
   RTN        ; Returns, addition succesful!
FBC1:
   ADC R2,R6  ; Increments second byte for overflow
   JPC FBC2   ; Checking for another overflow
   JMP ADDTB  ; Returns to adding 32bit number
SBC1:
   ADC R1,R5  ; Increments third byte for overflow
   JPC SBC2   ; Check for overflow
   JMP ADDFB  ; Returns to adding 32bit number
TBC1:
   ADC R0,R4  ; Increments fourth byte for overflow
   JPC ERR    ; If this overflowed, then youre f*cked
   RTN        ; Finished
FBC2:
   ADC R1,R5  ; Increment, YET AGAIN!
   JPC FBC3   ; This is quite repepepepeative code nomsain
   JMP ADDFB  ; Return, F yeah!
SBC2:
   ADD R0,R4  ; Increment for overflow
   JPC ERR    ; Shouldnt overflow
   RTN        ; Finished, so return
FBC3:
   ADC R0,R4  ; Any guesses?
   JPC ERR    ; Woops!
   RTN        ; Return, finished addition


OUT:
   PSH R4              ; Save byte
   MOV R4,R0           ; Moves byte for manipulation
   JPS BYTETOASCII     ; Converts fourth byte of fib number to ASCII and outputs
   PSH R5
   MOV R5,R0
   JPS BYTETOASCII
   PSH R6
   MOV R6,R0
   JPS BYTETOASCII
   PSH R7
   MOV R7,R0
   JPS BYTETOASCII
   JMP END             ; Program finished! :D

BYTETOASCII:
   POP R2
   POP R3   ; Saves return address from being destroyed
   PSH R0   ; Saves byte
   LDC R1,0x0F   ; Part of byte to remove
   AND R0,R1     ; Upper nybble removed, ie bits UNSET, lower nybble left intact
   LDI R0,HASH_TABLE_BYTE[R1]
   STM R0,SERIAL_PORT_0        ; Outputs upper nybble of byte
   POP R0
   SHR R1
   SHR R1
   SHR R1
   SHR R1              ; Shift the byte right four times, moves data to lower nybble
   LDC R1,0x0F
   AND R0,R1           ; Upper nybble removed, bits set to 0
   LDI R0,HASH_TABLE_BYTE[R1]  ; Gets lower nybble ASCII character
   STM R0,SERIAL_PORT_0        ; Outputs lower nybble of byte
   PSH R3
   PSH R2  ; Puts return address back on stack
   RTN


ERR:
   LDI R0,ERROR[R1]     ; Loads first byte of error message
   TST R0
   JPZ END
   ADD R9,R1            ; Increments offset
   STM R0,SERIAL_PORT_0 ; Outputs character to serial port

END:
   JPZ END