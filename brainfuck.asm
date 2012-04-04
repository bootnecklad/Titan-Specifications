; Brainfuck for Titan
; Marc Cleave (C) 2012
; 04/04/2012
; 
; Has 32k cells beginning at 0x0000 and finishing at 0x7FFF
; Commands start at 0x8000
; Instruction pointer in [R2,R3]
; Data pointer in [R4,R5]
;
; Brainfuck commands
;
; > 	increment the data pointer (to point to the next cell to the right).
; < 	decrement the data pointer (to point to the next cell to the left).
; + 	increment (increase by one) the byte at the data pointer.
; - 	decrement (decrease by one) the byte at the data pointer.
; . 	output the byte at the data pointer as an ASCII encoded character.
; , 	accept one byte of input, storing its value in the byte at the data pointer.
; [ 	if the byte at the data pointer is zero, then instead of moving the instruction pointer forward to the next command, jump it forward to the command after the matching ] command.
; ] 	if the byte at the data pointer is nonzero, then instead of moving the instruction pointer forward to the next command, jump it back to the command after the matching [ command.
;
; Char   Binary/Hex
; >      000
; <      001
; +      010
; -      011
; .      100
; ,      101
; [      110
; ]      111
; S      0xFF


.WORD CELLADDR 0x0000 ; cells start at 0x0000 and finish at 0x7FFF
.WORD STARTADDR 0x8000 ; address where commands start
.WORD SERIAL_PORT_0 0xFF00 ; address of serial port output

INIT:
   CLR R0
   CLR R1
   CLR R2

CLEAR_CELLS:
   STI R0,[R1,R2]  ; clearing the cells
   JPS INCREMENT   ; increments address to clear
   JPS TESTZERO    ; tests if 16 bit value is zero
   JMP CLEAR_CELLS ; continues clearing cells
CLEAR_DONE:    ; program returns here if 
   POP R0
   POP R0     ; gets rid of return address off of stack
   JMP PROMPT ; jumps to beginning prompt

;16bit increment routine
INCREMENT:
   INC R2
   JPC INC_CARRY
   RET
INC_CARRY:
   INC R1
   RET

TESTZERO:
   TST R2   ; tests low byte
   JPZ TST_CONT
   RET      ; 16bit value not zero
TST_CONT:
   PSH R0
   LDC R2,0x80
   SUB R0,R2
   JPZ CLEAR_DONE ; if jump occurs then all cells are clear
   RET

PROMPT:
   LDC R0,0x0A   ; ASCII value for LF (Line feed)
   STM R0,SERIAL_PORT_0 ; Outputs to terminal
   LDC R0,0x0D   ; ASCII value for CR (Carriage return)
   STM R0,SERIAL_PORT_0 ; Outputs to terminal
   LDC R0,0x3E   ; ASCII value for '>'
   STM R0,SERIAL_PORT_0 ; Outputs to terminal
   JMP GETBRAINFUCK   ; jumps to get input

GETBRAINFUCK:
   LDC R1,0x80 ; high byte of start address of commands
   CLR R2      ; low byte of start address of commands
   LDM R0,SERIAL_PORT_0  ; Gets byte from input
   TST R0                ; test to see if byte contains anything (if not, nothing was fetched)
   JPZ GETBRAINFUCK      ; try again
   STI R0,[R1,R2]
   JPS INCREMENT
   LDC R3,0x1B           ; ASCII value for ESC (Escape)
   XOR R0,R3             ; Checks if input byte was an ESC
   JPZ INIT              ; If the byte was an ESC, start again
   LDC R3,0x47           ; ASCII value for 'G'
   XOR R0,R3
   JPZ COMPILE           ; if the byte was G, compile then execute
   JMP GETBRAINFUCK      ; get another byte

COMPILE:
; this is where some magic happens omg!
; COMMAND  ASCII VALUE
;    +       0x2B
;    ,       0x2C
;    -       0x2D
;    .       0x2E
;    <       0x3C
;    >       0x3E
;    [       0x5B
;    ]       0x5D
   LDC R1,0x80 ; high byte of start address of commands
   CLR R2      ; low byte of start address of commands

RUN:
   LDM R1,[R2,R3] ; gets command to be executed
   LDC R0,0x00 ; > command
   XOR R0,R1 ; compares
   JPZ INCPOINTER ; executes increment pointer command
   LDC R0,0x01 ; < command
   XOR R0,R1 ; compares
   JPZ DECPOINTER ; executes decrement pointer command
   LDC R0,0x02 ; + command
   XOR R0,R1 ; compares
   JPZ INCCELL ; executes increment cell command
   LDC R0,0x03 ; - command
   XOR R0,R1 ; compares
   JPZ DECCELL ; executes decrement cell command
   LDC R0,0x04 ; . command
   XOR R0,R1 ; compares
   JPZ OUTPUT ; executes output command
   LDC R0,0x05 ; , command
   XOR R0,R1 ; compares
   JPZ INPUT  ; executes input command
   LDC R0,0x06 ; [ command
   XOR R0,R1 ; compares
   JPZ JMPZERO ; executes [ command
   LDC R0,0x07 ; ] command
   XOR R0,R1 ; compares
   JPZ JMPBACK ; executes ] command
   JPZ INIT ; wasnt any of the above commands, therefore stop command

INCINSTRUCTION:
   INC R3
   JPC INS_CARRY
   JMP RUN
INS_CARRY:
   INC R2
   JMP RUN

INCPOINTER:
   INC R5
   JPC POINT_CARRY
   JMP INCINSTRUCTION
POINT_CARRY:
   INC R4
   LDC R1,0x7F
   AND R1,R4 ; ensures that the datapointer stays 15 bits
   JMP INCINSTRUCTION

DECPOINTER:
   NOT R5
   INC R5
   JPZ DEC_CARRY
   NOT R5
   JMP INCINSTRUCTION
DEC_CARRY:
   NOT R5
   NOT R4
   INC R4
   NOT R4
   LDC R1,0x7F
   AND R1,R4 ; ensures that the datapointer stays 15 bits
   JMP INCINSTRUCTION

INCCELL:
   LDI R0,[R4,R5] ; gets data currently in cell
   INC R0         ; increments the data
   STI R0,[R4,R5] ; stores data back in cell
   JMP INCINSTRUCTION

DECCELL:
   LDI R0,[R4,R5]
   NOT R0
   INC R0
   NOT R0  ; decrements the data
   STI R0,[R4,R5] ; stores data back in cell
   JMP INCINSTRUCTION

INPUT:
   LDM R0,SERIAL_PORT_0 ; gets input
   STI R0,[R4,R5] ; stores input into cell
   JMP INCINSTRUCTION

OUTPUT:
   LDI R0,[R4,R5] ; gets data currently in cell
   STM R0,SERIAL_PORT_0 ; outputs data to serial port
   JMP INCINSTRUCTION


; jump zero works by:
; get command
; if command is [ then push the current location onto the stack, goto beginning
; if command is ] then pop stack into temp
; compare current location with temp
; if equal then matching ] found, jump incinstruction
; if not equal then matching ] not found, so goto beginning
JMPZERO:
   PSH R5
   PSH R4 ; pushes current address onto stack
   LDC R6,0x6 ; [ command
   LDC R7,0x7 ; ] command
   LDI R0,[R4,R5] ; gets data currently in cell
   TST R0 ; tests if zero
   JPZ MATCH ; if data is zero then will need to find the matching ']'
   POP R0
   POP R0 ; removes address from stack, not needed anymore
   JMP INCINSTRUCTION ; data was non-zero so carry on executing
MATCH:
   INC R3
   JPC MATCH_CARRY
   JMP MATCH_LOOP
MATCH_CARRY:
   INC R2
MATCH_LOOP:
   LDM R0,[R2,R3] ; gets another command
   MOV R7,R1
   XOR R0,R1  ; compares command to [ command
   JPZ PUSH_MATCH ; if command was [ then push current location
   MOV R6,R1
   XOR R0,R1 ; compares command to ] command
   JPZ POP_MATCH ; if equal then pop and test location
   JMP MATCH   ; command was not [ or ] so loop back, start sequence again
PUSH_MATCH:
   PSH R3 ; low byte
   PSH R2 ; high byte, pushes current location onto stack
   JMP MATCH ; start sequence again
POP_MATCH:
   POP R8 ; pops high byte
   POP R9 ; pops low byte
   XOR R5,R9 ; compares low byte
   JPZ POP_CONT ; if low byte equal, test high byte
   JMP MATCH ; if addresses not equal then matching ] not found, so start loop back
POP_CONT:
   XOR R4,R8 ; compares high byte
   JPZ INCINSTRUCTION
   JMP MATCH ; if addresses not equal then matching ] not found, so start loop back

; jump back is the opposite of jump zero
; it works BACKWARDS rather than forwards... :o  
; i got lazy here and just added _B to the labels and changed the increment instruciton pointer to decrement
JMPBACK:
   PSH R5
   PSH R4 ; pushes current address onto stack
   LDC R6,0x6 ; [ command
   LDC R7,0x7 ; ] command
   LDI R0,[R4,R5] ; gets data currently in cell
   TST R0 ; tests if zero
   JPZ MATCH_B ; if data is zero then will need to find the matching '['
   POP R0
   POP R0 ; removes address from stack, not needed anymore
   JMP INCINSTRUCTION ; data was non-zero so carry on executing
MATCH_B:
   NOT R3
   INC R3
   JPC MATCH_CARRY_B
   NOT R3
   JMP MATCH_LOOP_B
MATCH_CARRY_B:
   NOT R3
   NOT R2
   INC R2
   NOT R2
MATCH_LOOP_B:
   LDM R0,[R2,R3] ; gets another command
   MOV R6,R1
   XOR R0,R1  ; compares command to ] command
   JPZ PUSH_MATCH_B ; if command was ] then push current location
   MOV R7,R1
   XOR R0,R1 ; compares command to [ command
   JPZ POP_MATCH_B ; if equal then pop and test location
   JMP MATCH_B   ; command was not [ or ] so loop back, start sequence again
PUSH_MATCH_B:
   PSH R3 ; low byte
   PSH R2 ; high byte, pushes current location onto stack
   JMP MATCH_B ; start sequence again
POP_MATCH_B:
   POP R8 ; pops high byte
   POP R9 ; pops low byte
   XOR R5,R9 ; compares low byte
   JPZ POP_CONT_B ; if low byte equal, test high byte
   JMP MATCH_B ; if addresses not equal then matching ] not found, so start loop back
POP_CONT_B:
   XOR R4,R8 ; compares high byte
   JPZ INCINSTRUCTION
   JMP MATCH_B ; if addresses not equal then matching ] not found, so start loop back