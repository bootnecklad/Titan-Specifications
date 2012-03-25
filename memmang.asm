; Simple Memory Pointer Managment of 16bit data to a pointer in memory




; Allocate:
; Data to be allocated is stored in RA(high) and RB(low)
; Pointer of element is returned in RA(high) and RB(low)
;

INT ALLOCATE:
   LDM R1 0x3FF   ; high byte of next free element
   PSH R1
   LDM R2 0x400   ; low byte of next free element
   PSH R2
   LDC R0 0x80    ; bit setting for allocated element
   STI R0 [R1,R2]    ; sets element as allocated
   JPS INCREMENT
   STI RA [R1,R2]   ; stores high byte of data
   JPS INCREMENT
   STI RB [R1,R2]   ; stores low byte of data
   POP RB
   POP RA
   RTE


; Unallocate:
; Sets byte to unallocated, clears databyte and clears next pointer
; Pointer of element to be cleared in RA(high) and RB(low)

INT UNALLOCATE:
   CLR R0
   STI R0 [RA,RB]   ; sets element as unallocated
   JPS INCREMENT
   STI R0 [RA,RB]   ; sets high byte to zero
   JPS INCREMENT
   STI R0 [RA,RB]   ; stores low byte of data
   JPS INCREMENT
   STI R0 [RA,RB]   ; clears high byte address next element
   JPS INCREMENT
   STI R0 [RA,RB]   ; clears low byte address next element
   STM RA 0x3FF     ; stores address of new empty element to next free element
   STM RB 0x400
   CLR RA
   CLR RB           ; clears pointer to element
   RTE

   
;16bit increment routine
INCREMENT:
   CLR R0
   ADC R0,R2
   JPC INC_CARRY
   RET
INC_CARRY:
   ADC R0,R1
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
INT SETZERO:
   CLR R0
   LDC R1 0x09   ; address to start at(high byte)
   CLR R2        ; address to start at(low byte)
   LDC R3 0x04   ; finish address(high byte)
   LDC R4 0x00   ; finish address(low byte)
LOOP:
   STI R0 [R1,R2]  ; clears byte in memory
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


; CONS?!
; awww yeah!
; Pointer of car list/element is in RA(high) and RB(low)
; Pointer of cdr list/element is in R8(high) and R9(low)
; R8 and R9 then cleared
INT CONS:
   LDC R0 0x03    ; offset of the next address in list
   ADD R0,RB   ; add offset to pointer
   JPC CONS_INC  ; accounts for overflow
CONS_CONT:
   STM RB [R8,R9]   ; stores low byte
   JPS INCREMENT    ; increments to point to next address
   STM R1 [R8,R9]   ; stores high byte
   CLR R8
   CLR R9   ; clears pointer to the 'cdr' of the list

CONS_INC:
   CLR R0
   ADC R0,RA ; 16 bit addition complete
   JMP CONS_CONT


; Findelement
; Finds an empty element and stores the address in 0x3FF and 0x400

INT FINDELEMENT:
   ; ill do it later