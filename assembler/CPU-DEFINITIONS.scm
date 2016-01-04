;; Defines the lengths of the different opcodes, #f if length is variable
(define opcode-lengths '((NOP 1) (HLT 1) (ADD 2) (ADC 2) (SUB 2) (AND 2) (IOR 2) (XOR 2) (NOT 2)
                         (SHR 2) (INC 2) (DEC 2) (INT 2) (RTE 1) (CLR 1) (PSH 1) (POP 1) (PEK 1)
                         (DUP 1) (PSR 1) (POR 1) (PER 1) (DUR 1) (MOV 2) (JPZ 3) (JPS 3) (JPC 3)
                         (JPI 3) (JSR 3) (RTN 1) (LDC 2) (JMP #f) (LDM #f) (STM #f)))

;; Defines the machine code values for different opcodes
(define opcodes '((NOP #x00) (HLT #x01) (ADD #x10) (ADC #x11) (SUB #x12) (AND #x13) (IOR #x14) (XOR #x15)
                  (NOT #x16) (SHR #x17) (INC #x18) (DEC #x19) (INT #x20) (RTE #x21) (CLR #x60) (PSH #x70) 
                  (POP #x80) (PEK #x90) (DUP #x91) (PSR #x83) (POR #x75) (PER #x81) (DUR #x85) (MOV #x90)
                  (JMP #xA0) (JPZ #xA1) (JPS #xA2) (JPC #xA3) (JPI #xA4) (JSR #xA5) (RTN #xA6) (LDC #xD0)
                  (LDM #xE0) (STM #xF0)))

;; Defines the machine code values for different registers
(define registers '((R0 #x0) (R1 #x1) (R2 #x2) (R3 #x3) (R4 #x4) (R5 #x5) (R6 #x6) (R7 #x7)
                    (R8 #x8) (R9 #x9) (RA #xA) (RB #xB) (RC #xC) (RD #xD) (RE #xE) (RF #xF)))

;; Defines all the directives
(define directives '(.INCL .RAW .LABEL .BYTE .WORD .LABEL .DATA .ASCII .ASCIZ))



;; Assembles instructions with byte format:
;; #x00 <- OPCODE
;; #xSD <- OPERAND
;; Where S is Register-Source and D is Register-Destination
(define assemble-RSRD
  (lambda (instr)
    (list (car instr)
          (combine-nibbles (cadr instr)
                           (caddr instr)))))

;; Assembles instructions with byte format:
;; #x0S
;; Where S is Register-Source (Also Destination, eg (NOT R0)
(define assemble-RS
  (lambda (instr)
    (list (bitwise-ior (car instr)
                           (cadr instr)))))

;; Assembles Load Constant instruction
(define assemble-LDC
  (lambda (instr)
    (list (bitwise-ior (car instr) (caddr instr))
          (cadr instr))))

;; Assembles standard JMP instruction, (JMP #xBABE)
(define assemble-STD-JMP
  (lambda (instr)
    (list (car instr)
          (split-address (cadr instr)))))


;; Definitions for all cases of Load & Store instructions
;;; (LDM #xBABE R0) (LDM R0 R1)  (LDM (#xCAFE) R1) (LDM (+ R1) R0) (LDM (R2 #xDEAD) R3) (LDM (R0) R1) (LDM + R1 R3) (LDM R2 #xDEAD R3)
;;; (STM R0 #xBABE) (STM R1 R0)  (STM R1 (#xCAFE)) (STM R0 (+ R1)) (LDM R3 (R2 #xDEAD)) (STM R1 (R0)) (STM R3 + R1) (STM R3 R2 #xDEAD)

;; Needs implementing
(define assemble-LDM
  (lambda (orig-instr instr)
    (list (car instr) 0 (split-address #xFFFF))))

;; Needs implementing
(define assemble-STM
  (lambda (orig-instr instr)
    (list (car instr) 0 (split-address #xFFFF))))


;; Big dirty for assembling all JMP cases
(define assemble-JMP
  (lambda (orig-instr instr)
    (cond

 ;;; (JMP (Rs #xZZZZ)) - Jump to the address at Rs + #xZZZZ
     ((and (list? (second orig-instr))
           (register? (car (second orig-instr)))
           (= 2 (length (second orig-instr))))
      (list (bitwise-ior (car instr) 7) (combine-nibbles (second instr) 0) (split-address (last instr))))

;;; (JMP Rs #xZZZZ)   - Jump to Rs + #xZZZZ
     ((and (register? (second orig-instr))
           (number? (last instr))
           (= 3 (length instr)))
      (list (bitwise-ior (car instr) 6) (combine-nibbles (second instr) 0) (split-address (last instr))))


;;; (JMP (+ Rs))      - Jump to the address at the address in Rs, then increment Rs

     ((and (list? (operands orig-instr))
           (eq? '+ (cadr orig-instr)))
      (list (bitwise-ior (car instr) 5) (combine-nibbles (last instr) 0)))

;;; (JMP + Rs)        - Jump to the address in Rn, then increment Rs
     ((and (eq? '+ (first (operands orig-instr)))
           (register? (last orig-instr)))
      (list (bitwise-ior (car instr) 4) (combine-nibbles (last instr) 0)))

;;; (JMP #xZZZZ)      - Jump to address #xZZZZ
     ((and (number? (second instr))
           (not (list? (second orig-instr)))
           (not (register? (second orig-instr))))
      (list (bitwise-ior (car instr) 0) (split-address (second instr))))

;;; (JMP (#xZZZZ))    - Jump to the address in #xZZZZ
     ((and (number? (second instr))
           (list? (second orig-instr))
           (not (register? (car (second orig-instr)))))
      (list (bitwise-ior (car instr) 1) (split-address (second instr))))

;;; (JMP Rs)          - Jump to the address in Rs
     ((and (= (length instr) 2)
           (register? (second orig-instr)))
      (list (bitwise-ior (car instr) 2) (combine-nibbles (second instr) 0)))

;;; (JMP (Rs))        - Jump to the address at the address in Rs
     ((and (list? (second orig-instr))
           (register? (car (second orig-instr))))
      (list (bitwise-ior (car instr) 3) (combine-nibbles (last instr) 0))))))
