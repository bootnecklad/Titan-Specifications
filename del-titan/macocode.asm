IntToDel:
   CLR R2
   SHL R1
   JPC ITDCarry
   JMP ITDNoCarry
 ITDCarry:
   LDC R2,0x01
 ITDNoCarry:
   SHL R0
   LOR R2,R0

DelToInt:
   CLR R2
   SHR R0
   JPC DTICarry
   JMP DTINoCarry
 DTICarry:
   LDC R2,0x80
 DTINoCarry:
   SHL R1
   LOR R2,R1

PrtToDel:
   INC R1

DelToPtr
   DEC R1

Push:
   PSH R1
   PSH R0

Pop:
   POP R0
   POP R1

Peek:
   POP R0
   POP R1
   PSH R1
   PSH R0

Halt:
   JMP Halt

   
; [R0,R1] should contain the number of bytes needed
GCIfNeeded:

.BYTE HeapENDHighByte 0xDF
.BYTE HeapENDLowByte 0xFF  

   LDC R2,HeapENDHighByte
   LDC R3,HeapENDLowByte
   ADD R8,R1
   JPC GCFixCarry
   JMP GCNoCarry
 GCFixCarry:
   INC R1
 GCNoCarry:
   ADD R9,R0
   INC R1
   JPC GCFixCarryInc
   JMP GCNoCarryInc
 GCFixCarryInc:
   INC R0
 GCNoCarryInc:    
   SUB R1,R3  ; subtracts low bytes
   JPC SUBFIX ; corrects for first byte overflow
   SUB R0,R2  ; subtracts high bytes
   JMP SUBEND ; finishes addition
 SUBFIX:
   DEC R0     ; corrects for overflow
   SUB R0,R2  ; subtracts high bytes
 SUBEND:
   JPS GCNotNeeded     ; [R2,R3] contains 
   JMP Halt ; RUH ROH
 GCNotNeeded:

; allocate and store [R0,R1] to the heap
AllocateAndStore:
   LDC R2,0x02
   ADD R2,R9
   JPC AllocateCarryFix
   JMP AllocateNoCarryFix
 AllocateCarryFix:
   INC R8
 AllocateNoCarryFix:
   STI R0,[R8,R9]
   INC R9
   STI R1,[R8,R9]
   DEC R9
   RTN

; save top of stack to the heap
SaveTop:
   POP R0
   POP R1
   JPS AllocateAndStore

; assume address is in [R0,R1]
; saves address to heap
; increments the address
; stores address on stack
PushClosure:
   JPS AllocateAndStore
   INC R1
   PSH R1
   PSH R0

; index is in index register [R6,R7]
; dont close more than 256 variables
Ref:
   POP R0
   POP R1
   PSH R1
   PSH R0   ; performs a peek
   DEC R1   ; performs DEL TO PTR
   ADD R7,R1
   JPC RefCarryFix
   JMP RefNoCarryFix
 RefCarryFix:
   INC R0
 RefNoCarryFix:   ; adds offset from index register
   LDI R3,[R0,R1]
   INC R1
   LDI R2,[R0,R1]   ; gets value of a closed variable from memory
   PSH R3
   PSH R2 ; pushes onto stack
 
ResetStack:
   CLR RC
   CLR RD ; clears stack pointer





 
 
 
 
 
 
 