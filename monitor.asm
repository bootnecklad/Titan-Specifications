; This is the basic MonitorOS for Titan.
; When assembled and the binary entered into Titan's memory, MonitorOS will show '>' prompt at the serial terminal.
; Bytes can be loaded into memory by typing a two byte address in hex, then a space, then the byte to be dumped.
;
; The below example shows 0xFE being entered into the address 0x0F07.
;
; > 0F07 FE
; >
;
; Currently there are three "commands" '/' 'C' and ' '
; 
; '/' - Read byte
; ' ' - Write byte (followed by a byte to write)
; 'C' - Clear byte
;
; This file is the MonitorOS for Marc Cleave's Titan Processor
; Copyright (C) 2011 Marc Cleave, bootnecklad@gmail.com
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
;

BEGIN:
   LDC R0,0x0A          ; ASCII value for LF (Line feed)
   STM R0,SERIAL_PORT_0 ; Outputs to terminal
   LDC R0,0x0D          ; ASCII value for CR (Carriage return)
   STM R0,SERIAL_PORT_0 ; Outputs to terminal
   LDC R0,0x3E          ; ASCII value for '>'
   STM R0,SERIAL_PORT_0 ; Outputs to terminal


GET_INPUT:
   LDC R1,0x05           ; Number of bytes of input to get
   LDC R2,0x01           ; Value need for incrementing/decrementing
   LDM R0,SERIAL_PORT_0  ; Gets byte from input
   TST R0                ; test to see if byte contains anything (if not, nothing was fetched)
   JPZ GET_INPUT         ; try again
   LDC RF,0x1B           ; ASCII value for ESC (Escape)
   XOR RF,R0             ; Checks if input byte was an ESC
   JPZ BEGIN             ; If the byte was an ESC, return to '>' prompt
   SUB R1,R2             ; Decrement byte count
   PSH R0                ; Pushes byte onto stack
   JPZ PARSE_INPUT       ; No more bytes to fetch so lets parse them!
   JMP GET_INPUT         ; Get another byte


PARSE_INPUT:
   POP R0       ; Pops latest value off the stack
   LDC R1,0x2F  ; ASCII value for '/' this is a READ command
   XOR R1,R0    ; Checks if byte is a '/'
   JPZ READ     ; Goes off to create address, read memory and output
   LDC R1,0x43  ; ASCII value for 'C' this is a CLEAR command
   XOR R1,R0    ; Checks if byte is a 'C'
   JPZ CLEAR    ; Goes off to create address and write a 00
   LDC R1,0x20  ; ASCII value for ' ' this is a WRITE command
   XOR R1,R0    ; Checks if byte is a space
   JPZ BYTE     ; Need to get two more bytes of input
   NOP          ; Its really easy to add functions to this program!
   JMP BEGIN    ; Obviously it was an invalid character and the user forgot to press ESC.


READ:
   JSR CREATE_ADDRESS  ; Creates address from ASCII 
   JSR XOR_SWAP        ; :>
   LDI R0,0x00         ; Loads the byte to be read, uses indexed load with NO offset, address in R1 and R2.
   PSH R0              ; Saves byte before manipulation
   LDC R1,0x0F        ; Part of byte to remove
   AND R0,R1          ; Upper nybble removed, ie bits UNSET, lower nybble left intact
   LDC R1,0x09
   SUB R1,R0          ; Does R1 = R1 - R0, if R0 is less than 9 then sign and zero not set.
   JPZ LOW_NYBBLE_30  ; Lower nybble is 9 so 0x30 must be added to create an ASCII byte
   JPS LOW_NYBBLE_37  ; R0 was greater than 9 so 0x37 must be added to create an ASCII byte
   JMP LOW_NYBBLE_30  ; R0 was less than 9 so nybble was less than 9, so 0x30 must be added to create an ASCII byte
   LOW_NYBBLE_30:
   LDC R1,0x30
   ADD R0,R1          ; Adds 0x30 to nybble to create ASCII data
   MOV RF,R0          ; Saves byte to be outputted
   JMP HIGH_NYBBLE
   LOW_NYBBLE_37:
   LDC R1,0x37
   ADD R0,R1          ; Adds 0x37 to nybble to create ASCII data
   MOV RF,R0          ; Saves byte to be outputted
   JMP HIGH_NYBBLE
   LDC R1,0xF0  ; Nybble of byte to be removed
   POP R0       ; Returns unaltered value
   AND R0,R1    ; Lower nybble removed
   SHR R0
   SHR R0
   SHR R0
   SHR R0  ; Shifted right four times to move it to lower nybble
   LDC R1,0x09
   SUB R1,R0           ; Does R1 = R1 - R0, if R0 is less than 9 then sign and zero not set.
   JPZ HIGH_NYBBLE_30  ; Lower nybble is 9 so 0x30 must be added to create an ASCII byte
   JPS HIGH_NYBBLE_37  ; R0 was greater than 9 so 0x37 must be added to create an ASCII byte
   JMP HIGH_NYBBLE_30  ; R0 was less than 9 so nybble was less than 9, so 0x30 must be added to create an ASCII byte
   HIGH_NYBBLE_30:
   LDC R1,0x30
   ADD R0,R1
   MOV RE,R0    ; Saves byte to be outputted
   JMP OUTPUT   ; Wooo!
   HIGH_NYBBLE_37:
   LDC R1,0x37
   ADD R0,R1
   MOV RE,R0    ; Saves byte etc
   OUTPUT:
   STM RE,SERIAL_PORT_0  ; Ouputs high nybble
   STM RF,SERIAL_PORT_0  ; Outputs low nybble
   JMP BEGIN

CREATE_ADDRESS:
   POP RE
   POP RF     ; DONT BREAK THE RETURN ADDRESS!
   
   
   PSH RF
   PSH RE     ; PUTS BACK RETURN ADDRESS :)
   RTN
   

XOR_SWAP:
   XOR R1,R2  ; Swaps R1 and R2
   XOR R2,R1  ; Only included in this program because XOR swaps are cool. :>
   XOR R1,R2  ; SETS UP ADDRESS BYTES FOR INDEXED STORE
   RTN


CLEAR:
   JSR CREATE_ADDRESS  ; Creates address from ASCII input
   JSR XOR_SWAP        ; Because XOR swaps are cool
   CLR R0              ; Clears R0
   STI R0,0x00         ; Indexed store to memory, uses address in registers and no offset
   JMP BEGIN           ; That was quick!


BYTE:
   LDC R1,0x02           ; Number of bytes of input to get
   LDC R2,0x01           ; Value need for incrementing/decrementing
   LDM R0,SERIAL_PORT_0  ; Gets byte from input
   TST R0                ; test to see if byte contains anything (if not, nothing was fetched)
   JPZ BYTE              ; try again
   LDC RF,0x1B           ; ASCII value for ESC (Escape)
   XOR RF,R0             ; Checks if input byte was an ESC
   JPZ BEGIN             ; If the byte was an ESC, return to '>' prompt
   SUB R1,R2             ; Decrement byte count
   PSH R0                ; Pushes byte onto stack
   JPZ MAKE_BYTE         ; No more bytes to fetch so lets parse them!
   JMP BYTE              ; Get another byte
   

MAKE_BYTE:
   POP R1
   POP R2
   
