; This is the basic MonitorOS for Titan.
; When assembled and the binary entered into Titan's memory, MonitorOS will show '>' prompt at the serial terminal
; Bytes can be examined by typing a two byte address in hex, then pressing '/'
; Bytes can be stored by typing a byte in hex then pressing carriage return.
;
; The below example shows 0xFE being entered into the address 0x0F07.
;
; > 0F07/00 FE
; >
;
;
; This file is the MonitorOS for Marc Cleave's Titan Processor
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

.ORIG BEGIN

.WORD SERIAL_PORT_0 0xFF00 ; address of serial port output

BEGIN:
   LDC R0,0x0A          ; ASCII value for LF (Line feed)
   STM R0,SERIAL_PORT_0 ; Outputs to terminal
   LDC R0,0x0D          ; ASCII value for CR (Carriage return)
   STM R0,SERIAL_PORT_0 ; Outputs to terminal
   LDC R0,0x3E          ; ASCII value for '>'
   STM R0,SERIAL_PORT_0 ; Outputs to terminal
   LDC R2,0xDF
   CLR R3        ; creates orginal buffer address

MAINLOOP:
   LDM R0,SERIAL_PORT_0  ; Gets byte from input
   STM R0,SERIAL_PORT_0  ; Echos byte back
   TST R0                ; test to see if byte contains anything (if not, nothing was fetched)
   JPZ MAINLOOP          ; try again
   LDC R1,0x1B           ; ASCII value for ESC (Escape)
   XOR R0,R1             ; Checks if input byte was an ESC
   JPZ BEGIN             ; If the byte was an ESC, start again
   STI R0,[R2,R3]        ; stores input to buffer
   JPS INCREMENT         ; increments buffer address
   LDC R1,0x2F           ; ASCII value for '/' this is a READ command
   XOR R0,R1             ; Checks if byte is a '/'
   JPZ OUTMEMBYTE        ; Need to output byte in memory at inputted address
   JMP MAINLOOP          ; get another byte

; output byte in memory in address in buffer
OUTMEMBYTE:
   JPS CREATEADDR      ; creates high byte of address
   JPS INCREMENT       ; increments buffer
   JPS CREATEADDR      ; creates low byte of address
   POP R5
   POP R4              ; address created pushed onto stack in little endian style
   LDI R1,[R4,R5]      ; Loads the byte to be read, uses indexed load with NO offset, address in R1 and R2.
   PSH R1              ; Saves byte before manipulation
   LDC R0,0x0F         ; Part of byte to remove
   AND R0,R1           ; Upper nybble removed, ie bits UNSET, lower nybble left intact
   LDI R1,HASH_TABLE_BYTE  ; Data byte used to fetch the ASCII equvilent, ie if data is 0x5 then 0x35 is needed to be output to terminal
   STM R1,SERIAL_PORT_0 ; Output high ASCII byte to serial terminal
   POP R0
   SHR R1
   SHR R1
   SHR R1
   SHR R1              ; Shift the byte right four times, moves data to lower nybble
   NOT R0              ; turns 0x0F into 0xF0
   AND R0,R1           ; Lower nybble removed, bits set to 0
   LDI R1,HASH_TABLE_BYTE  ; Data -> ASCII complete
   STM R1,SERIAL_PORT_0   ; Outputs low ASCII byte
   BYTE:
   LDC R2,0xDF
   CLR R3        ; creates orginal buffer address
   LDM R0,SERIAL_PORT_0  ; Gets byte from input
   STM R0,SERIAL_PORT_0  ; echos back
   TST R0                ; test to see if byte contains anything (if not, nothing was fetched)
   JPZ BYTE              ; try again
   LDC R1,0x1B           ; ASCII value for ESC (Escape)
   XOR R0,R1             ; Checks if input byte was an ESC
   JPZ BEGIN             ; If the byte was an ESC, start again
   LDC R1,0x0D           ; ASCII value for CR (Carriage return)
   XOR R0,R1             ; Carriage return means input done
   JPZ STOREMEMBYTE      ; No more bytes to fetch so lets convert them
   STI R0,[R2,R3]        ; stores bytes in buffer
   JPS INCREMENT         ; increments buffer address
   JMP BYTE              ; Get another byte
   
CREATEADDR:
   LDI R1,[R2,R3] ; gets high nybble
   LDC R0,0x30    ; Remove constant from ASCII value, makes table smaller.
   SUB R0,R1      ; R1 = R1 - R0
   LDI R1,HASH_TABLE ; creates the actual nybble needed
   SHL R1
   SHL R1
   SHL R1
   SHL R1         ; creates intended high nybble
   MOV R1,R4
   JPS INCREMENT  ; increments pointer to buffer
   LDI R1,[R2,R3] ; gets low nybble
   SUB R0,R1      ; Removes constant
   LDI R1,HASH_TABLE
   ADD R1,R4      ; Combines high and low nybbles to create high byte of address
   POP R0
   POP R1         ; sneaky stack manipulation for subroutine address
   PSH R4         ; pushes high nybble to stack
   RET

STOREMEMBYTE:
   LDC R2,0xDF
   CLR R3        ; creates orginal buffer address
   LDI R1,[R2,R3]    ; gets high nybble of byte
   LDC R0,0x30       ; Remove constant from ASCII value, makes table smaller.
   SUB R0,R1         ; R0 = R0 - R1
   LDI R6,HASH_TABLE ; Value of low nybble in R6
   SHR R6
   SHR R6
   SHR R6
   SHR R6            ; shifts nybble right four times to align
   JPS INCREMENT     ; increments buffer address
   LDI R1,[R2,R3]    ; gets low nybble of byte
   SUB R1,R0         ; Removes constant
   LDI R7,HASH_TABLE ; Value of high nybble in R3
   ADD R7,R6         ; Combines high and low nybbles to create low byte of address
   STI R6,[R4,R5]    ; Uses address created at beginning
   JMP BEGIN

;16bit increment routine
INCREMENT:
   INC R3         ; increments low byte of 16bit value
   JPC INC_CARRY  ; if carry, then upper byte of value needs to be incremented
   RET            ; no carry, so return
INC_CARRY:
   INC R2         ; increments upper byte
   RET            ; returns
 
.DATA HASH_TABLE 0x00 0x01 0x02 0x03 0x04 0x05 0x06 0x07 0x08 0x09 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x0A 0x0B 0x0C 0x0D 0x0E 0x0F 

.DATA HASH_TABLE_BYTE 0x30 0x31 0x32 0x33 0x34 0x35 0x36 0x37 0x38 0x39 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x41 0x42 0x43 0x44 0x45 0x46