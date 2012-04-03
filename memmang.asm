; Simple Memory Pointer Managment of 16bit data to a pointer in memory
;
; Types of data:
; 000 - NIL
; 001 - Data
; 010 - Pointer
; 011 - Function
; 100 - 
;
; Tag bit information for cells:
;
; X Y AAA BBB
;
; X - Dead or alive, 0=dead, 1=alive
; Y - No use yet!
; AAA - Data type of first 16bit value
; BBB - Data type of second 16bit value



; Allocate:
; Data and data type are stored on the stack
; Pointer to element is returned on the stack
;

INT ALLOCATE:
   POP R9
   POP RA
   POP RB         ; puts data type and data into registers
   LDM R1,0x03FF   ; high byte of next free element
   PSH R1
   LDM R2,0x0400   ; low byte of next free element
   PSH R2
   STI 
   LDC R0,0x80    ; bit setting for allocated element
   LOR R0,R9
   STI R9,[R1,R2]    ; sets element as allocated
   JPS INCREMENT
   STI RA,[R1,R2]   ; stores high byte of data
   JPS INCREMENT
   STI RB,[R1,R2]   ; stores low byte of data
   CLR R0
   STM R0,0x3FF
   STM R0,0x3FF
   RTE


; Unallocate:
; Sets ellement to unallocated
; Pointer of element to be cleared stored on stack
; New free element address also updated
;

INT UNALLOCATE:
   CLR R0
   STI R0,[RA,RB]   ; sets element as unallocated
   STM RA,0x3FF     ; stores address of new empty element to next free element
   STM RB,0x400
   RTE

   
;16bit increment routine
INCREMENT:
   INC R2
   JPC INC_CARRY
   RET
INC_CARRY:
   INC R1
   RET

;16bit decrement routine
DECREMENT:
   NOT R1
   NOT R2
   JPS INCREMENT
   NOT R1
   NOT R2
   RET

; Setzero:
; Sets all new elements to zero
;
INT SETZERO:
   CLR R0
   LDC R1,0x09   ; address to start at(high byte)
   CLR R2        ; address to start at(low byte)
   LDC R3,0x04   ; finish address(high byte)
   LDC R4,0x00   ; finish address(low byte)
LOOP:
   STI R0,[R1,R2]  ; clears byte in memory
   JPS DECREMENT   ; decrements the address
   PSH R3
   XOR R1,R3       ; compares current address to finish address
   JPZ LOOP_NEXT
LOOP_CONT:
   POP R3
   JMP LOOP
LOOP_NEXT:
   PSH R4
   XOR R2,R4
   JPZ LOOP_END
   POP R4
   JMP LOOP
LOOP_END:
   RTE


; cons, cons, cons
; stack contents before: (CAR, CDR): datatype, databyte(high), databyte(low), datatype, databyte(high), databyte(low)
; pointer to element stored on stack
;
INT CONS
   POP R9
   POP RA
   POP RB         ; puts data type and data into registers
   LDM R1,0x3FF   ; high byte of next free element
   LDM R2,0x400   ; low byte of next free element
   SHL R9
   SHL R9
   SHL R9         ; shifts first data type left three times to move into correct position
   LDC R0,0x80    ; bit setting for allocated element
   LOR R0,R9
   POP R0         ; second data type
   LOR R0,R9      ; information for element to be allocated finished
   STI R9,[R1,R2] ; stores information to element
   JPS INCREMENT
   STI RA,[R1,R2] ; stores first byte of first data to element
   JPS INCREMENT
   STI RB,[R1,R2] ; stores second byte of first data to element
   POP RA
   POP RB
   STI RA,[R1,R2] ; stores first byte of second data to element
   JPS INCREMENT
   STI RB,[R1,R2] ; stores second byte of second data to element
   STM R0,0x3FF
   STM R0,0x3FF
   RTE	
   

INT FINDELEMENT:
   ; ill do it later