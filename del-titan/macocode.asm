LOCAL:
   LDC R0,0xnn   ; loads n
   MOV RD,R2
   MOV RC,R1     ; saves stack pointer
   ADD R0,RD
   JPC LocalCarry
   JMP LocalPerform
  LocalCarry:
   INC RC
  LocalPerform:
   POP R0  ; where does the value go after this?
   
INT_TO_DEL:
   LDC R0,0xnn   ; loads value to convert to tagged pointer format
   ADD R0,R0     ; Shifts value left

PRIM_PRINT:
;;; i have no idea how to convert a binary number into ASCII decimal. Help.

GC_IF_NEEDED:
;;; i dont know how to write a garbage collector


;;; RA holds the current heap pointer
PUSH_CLOSURE:
   LDC R1,0xnn    ; constant to beginning of heap pointer, assuming heap is only 256 bytes big
   STM R0,[R1,RA] ; stores address to heap
   PSH RA         ; pushes the pointer to the heap onto the stack

PEEK:
   POP R0
   PSH R0
   PSH R0 ; performs a PEEK.

GLOBAL:
   LDC R1,0xnn  ; loads location n of the global list
   LDC R2,0xnn  ; constant to beginning of global list, assuming global list is only 256 bytes big
   STI R0,[R2,R1] ; stores to global list

RESET_STACK:
   CLR RC
   CLR RD ; resets stack pointer

;;; RA holds the current heap pointer
SAVE_TOP:
   POP R0
   PSH R0 ; ensures that value is not lost
   LDC R1,0xnn  ; constant to beginning of heap pointer, assuming heap is only 256 bytes big
   STM R0,[R1,RA] ; stores value to heap

PRIM_EQ:
   POP R0
   POP R1
   PSH R1
   PSH R0 ; takes values off the top of the stack and restores them
   XOR R0,R1
   JPZ Equal
   LDC R0,0x00
   PSH R0
   JMP Finish
  Equal:
   LDC R0,0x02
   PSH R0
  Finish:

TOP:
   POP R1
   PSH R0  ; sets top of stack to contents of R1

REF:
   POP R1 ; gets pointer to some where in heap
   INC R1 ; increments the pointer
   LDC R2,0xnn ; constant to beginning of heap pointer, assuming heap is only 256 bytes big
   LDI R0,[R2,R1] ; gets value at offset