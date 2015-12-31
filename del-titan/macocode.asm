
;;; DEL -- the name of the system -- needs to convert it into DEL (tagged ptr) FORMAT
;;; format of a DEL tagged pointer:
;;; A pointer ABCD is ABCD1
;;; An integer ABCD is ABCD0
(.LABEL INT->DEL)
	(CLR R2)
	(SHL R1)
	(JNC INT->DEL-NO-CARRY)
	(LDC R2 #x01)
(.LABEL INT->DEL-NO-CARRY)
	(SHL R0)
	(LOR R2 R0)

;;; Converts DEL TAGGED POINTER to integer
(.LABEL DEL->INT)
	(CLR R2)
	(SHR R0)
	(JNZ DEL->INT-NO-CARRY)
	(LDC R2 #x80)
(.LABEL DEL->INT-NO-CARRY)
	(SHL R1)
	(LOR R2 R1)

(.LABEL POINTER->DEL)
	(SHL R0)
	(INC R1)

(.LABEL DEL->POINTER)
	(D

(.LABEL DEL-PUSH)
	(PSH R1)
	(PSH R2)

(.LABEL DEL-POP)
	(POP R0)
	(POP R1)

(.LABEL DEL-PEEK)
	(POP R0)
	(POP R1)
	(PSH R1)
	(PSH R0)

(.LABEL DEL-HALT)
	(HLT)

   
; [R0,R1] should contain the number of bytes needed
(.LABEL GC-IF-NEEDED)
	(.BYTE HEAP-END-HIGHBYTE #xDF)
	(.BYTE HEAP-END-LOWBYTE #xFF)

	(LDC R2 HEAP-END-HIGHBYTE)
	(LDC R3 HEAP-END-LOWBYTE)
	(ADD R8 R1) 		; Adds low number of bytes needed to HEAP POINTER
	(JNC HEAP-POINTER-LOW-NO-CARRY)
	(INC R1)
(.LABEL HEAP-POINTER-NO-CARRY)
	(ADD R9 R0)
	(INC R1)
	(JNC HEAP-POINTER-HIGH-NO-CARRY)
	(INC R0)
(.LABEL HEAP-POINTER-HIGH-NO-CARRY)
	(SUB R1 R3)		; Subtract low bytes
	(JNC HEAP-POINTER-SUBTRACTION-FIX) ; Corrects for byte overflow
	(SUB R0 R2)			   ; Subtracts high bytes
	(JMP HEAP-POINTER-SUBTRACTION-END) ; Finishes subtraction
(.LABEL HEAP-POINTER-SUBTRACTION-FIX)
	(DEC R0)		; Correct for overflow
	(SUB R0 R2)		; Subtracts high bytes
(.LABEL HEAP-POINTER-SUBTRACTION-END)
	(JPS GC-NOT-NEEDED) 	; If negative (ie sign bit set) then plenty of bytes free
	(JMP DEL-HALT) 		; GC needed. Oh fuq.
(.LABEL GC-NOT-NEEDED)


; allocate and store [R0,R1] to the heap
(.LABEL ALLOCATE-AND-STORE)
	(LDC R2 #X02)
	(ADD R2 R9)
	(JNC POINTER-NO-CARRY)
	(INC R8)
(.LABEL POINTER-NO-CARRY)
	(STI R0 #(R8 R9))
	(INC R9)
	(JNC HEAP-NO-CARRY)
	(INC R8)
(.LABEL HEAP-NO-CARRY)
	(STI R1 #(R8 R9))
	(RTN)


; save top of stack to the heap
(.LABEL SAVE-TOP)
	(POP R0)
	(POP R1)
	(JSR ALLOCATE-AND-STORE)

; assume address is in [R0,R1]
; saves address to heap
; increments the address
; stores address on stack
(.LABEL PUSH-CLOSURE)
   (JSR ALLOCATE-AND-STORE)
   (INC R1)
   (PSH R1)
   (PSH R0)

;;; index is in index register [R6,R7]
;;; dont close more than 256 variables
;;; 
;;; take the top of the stack, which is a pointer
;;; visit that pointer/address whatever, move an offset of 1 
;;; take that value you find, and set it to the top
(.LABEL REF)
	(POP R0)
	(POP R1)
	(PSH R1)
	(PSH R0) ; Performs a peek
	(DEC R1) ; Performs DEL TO POINTER
	(ADD R7 R1)
	(JNC REF-NO-CARRY)
	(INC R0)
(.LABEL REF-NO-CARRY)
	(LDI R3 #(R0 R1))
	(INC R1)
	(JNC REF-POINTER-NO-CARRY)
	(INC R0)
(.LABEL REF-POINTER-N0-CARRY) 	; Adds offset from index register
	(LDI R2 #(R0 R1)) 	; Gets value of a closed variable from memory
	(PSH R3)
	(PSH R2)		; Pushes onto stack
 
(.LABEL RESET-STACK)
	(CLR RC)
	(CLR RD) 		; Clears stack
 
