(define nil '())




(define test-case '(
(.BYTE BYTE-LABEL #xAA)
(.WORD WORD-LABEL #xBBCC)
(.DATA DATA-LABEL #xDD #xEE)
(.DATA DATA-TWO-LABEL #xFF #xFF)
(.ASCII FOO "BAR")
(.ASCIZ FOO-BAR "BAR")
(.LABEL BEGIN)
(NOP)
;(HLT)
(.LABEL LOOP)
(ADD RF RF)
(ADC R1 R2)
(SUB R2 R3)
(AND R3 R4)
(LOR R4 R5)
(XOR R5 R6)
(NOT R7)
(SHR R8)
(INC R9)
(DEC RA)
(INT BYTE-LABEL)
(RTE)
(PSH RB)
(POP RC)
(CLR RB)
(MOV RB RA)
(JMP LOOP)
(JPZ LOOP)
(JPS LOOP)
(JPC LOOP)
(JPI LOOP)
(JSR LOOP)
(RTN)
(JMI LOOP)
(JMI #(R1 R2))
(LDI R0 FOO)
(STI R1 FOO)
(LDI R2 #(R1 R2))
(STI R3 #(R1 R2))
(LDC R0 #x99)
(LDM R1 WORD-LABEL)
(STM R2 WORD-LABEL)
(LDM R3 DATA-LABEL)
(STM R4 DATA-TWO-LABEL)
;(SHL R0)
;(TST R0)
))

; ==== Actual output: ====
;; #;87> (assemble test-case 0)
;; Length of program in bytes: 89
;;
;; DD EE FF FF 42 41 52 42 41 52 00 00 10 FF 11 12
;; 12 23 13 34 14 45 15 56 16 70 17 80 18 90 19 A0 
;; 20 AA 21 7B 8C 6B 90 BA A0 00 0C A1 00 0C A2 00 
;; 0C A3 00 0C A4 00 0C A5 00 0C A6 A8 00 0C A9 12 
;; B0 00 04 C1 00 04 BA 12 CB 12 D0 99 E1 BB CC F2 
;; BB CC E3 00 00 F4 00 02 

;; ==== Expected output: ====
;; Length of program in bytes: 89
;;
;; DD EE FF FF 42 41 52 42 41 52 00 00 10 01 11 12
;; 12 23 13 34 14 45 15 56 16 70 17 80 18 90 19 A0
;; 20 AA 21 7B 8C 6B 90 BA A0 00 0C A1 00 0C A2 00
;; 0C A3 00 0C A4 00 0C A5 00 0C A6 A8 00 0C A9 12
;; B0 00 04 C1 00 04 BA 12 CB 12 D0 99 E1 BB CC F2
;; BB CC E3 00 00 F4 00 02

;;; CONCLUSION: ASSEMBLER IS FIXED!


(define test-ldc '(

(LDC R0 #xFF)))

; Expected:
; D0 FF

; Actual:
; #;27> (assemble test-ldc 0)
; Length of program in bytes: 3
; 
; D0 00 FF

; Appears that the assembler seems to be turning the byte into a 16 bit value ?




(define test-xor '(

(XOR R5 R6)))

; Expected:
; 15 56

; Actual:
; #;29> (assemble test-xor 0)
; Length of program in bytes: 2
; 
; 14 56

; Appears that the assembler has incorrect opcode for XOR


(define test-jmp-word '(

(.WORD LOOP #xFFFF)
   (JMP LOOP)))

; Expected:
; A0 FF FF

; Actual:
; #;39> (assemble test-ldm-word 0)
; Length of program in bytes: 3
; 
; A0 00 00

; Appears that the assembler doesn't assign correct value to WORD directive ?
