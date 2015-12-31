(define REGISTER-TABLE (list (cons 'R0 #x0) (cons 'R1 #x1)
                             (cons 'R2 #x2) (cons 'R3 #x3)
                             (cons 'R4 #x4) (cons 'R5 #x5)
                             (cons 'R6 #x6) (cons 'R7 #x7)
                             (cons 'R8 #x8) (cons 'R9 #x9)
                             (cons 'RA #xA) (cons 'RB #xB)
                             (cons 'RC #xC) (cons 'RD #xD)
                             (cons 'RE #xE) (cons 'RF #xF)
                             (cons 'REGISTER-F #xF) (cons 'REGISTER-A #xA)))

;;; defines the lengths of the different opcodes
(define opcode-lengths '((NOP 1) (HLT 1) (ADD 2) (ADC 2) (SUB 2) (AND 2) (IOR 2) (XOR 2) (NOT 2)
                         (SHR 2) (INC 2) (DEC 2) (INT 2) (RTE 1) (CLR 1) (PSH 1) (POP 1) (PEK 1)
                         (DUP 1) (PSR 1) (POR 1) (PER 1) (DUR 1) (MOV 2) (JPZ 3) (JPS 3) (JPC 3)
                         (JPI 3) (JSR 3) (RTN 1) (LDC 2) (JMP #f) (LDM #f) (STM #f)))

;;; defines the machine code values for different opcodes
(define opcodes '((NOP #x00) (HLT #x01) (ADD #x10) (ADC #x11) (SUB #x12) (AND #x13) (IOR #x14) (XOR #x15)
                  (NOT #x16) (SHR #x17) (INC #x18) (DEC #x19) (INT #x20) (RTE #x21) (CLR #x60) (PSH #x70) 
                  (POP #x80) (PEK #x90) (DUP #x91) (PSR #x83) (POR #x75) (PER #x81) (DUR #x85) (MOV #x90)
                  (JMP #xA0) (JPZ #xA1) (JPS #xA2) (JPC #xA3) (JPI #xA4) (JSR #xA5) (RTN #xA6) (LDC #xD0)
                  (LDM #xE0) (STM #xF0)))

;;; defines the machine code values for different registers
(define registers '((R0 #x0) (R1 #x1) (R2 #x2) (R3 #x3) (R4 #x4) (R5 #x5) (R6 #x6) (R7 #x7)
                    (R8 #x8) (R9 #x9) (RA #xA) (RB #xB) (RC #xC) (RD #xD) (RE #xE) (RF #xF)))

;;; defines all the directives
(define directives '(.RAW .LABEL .BYTE .WORD .LABEL .DATA .ASCII .ASCIZ))
