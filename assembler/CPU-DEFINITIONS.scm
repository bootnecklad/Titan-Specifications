(define nil '())

;; Defines all titan instruction opcode values and lengths
(define titan-instructions '((NO-OPERATION #x00 1)
                             (HALT #x01 1)
                             (ADD #x10 2)
                             (ADD-CARRY #x11 2)
                             (SUBTRACT #x12 2)
                             (AND #x13 2)
                             (IOR #x14 2)
                             (XOR #x15 2)
                             (NOT #x16 2)
                             (SHIFT-RIGHT #x17 2)
                             (INCREMENT #x18 2)
                             (DECREMENT #x19 2)
                             (INTERRUPT #x20 2)
                             (RETURN-INTERRUPT #x21 1)
                             (PUSH-DATA #x30 1)
                             (POP-DATA #x40 1)
                             (PEEK-DATA #x50 1)
                             (PUSH-RETURN #x60 1)
                             (POP-RETURN #x70 1)
                             (PEEK-RETURN #x80 1)
                             (CLEAR #x90 1)
                             (MOVE #xA0 2)
                             (LOAD-CONSTANT #xB0 2)
                             (JUMP #xC0 3)
                             (JUMP-INDIRECT #xC1 3)
                             (JUMP-REGISTER #xC2 2)
                             (JUMP-INDIRECT-REGISTER #xC3 2)
                             (JUMP-AUTOINCREMENT #xC4 2)
                             (JUMP-INDIRECT-AUTOINCREMENT #xC5 2)
                             (JUMP-OFFSET #xC6 4)
                             (JUMP-INDIRECT-OFFSET #xC7 4)
                             (JUMP-IF-ZERO #xC8 3)
                             (JUMP-IF-SIGN #xC9 3)
                             (JUMP-IF-CARRY #xCA 3)
                             (JUMP-SUBROUTINE #xCB 3)
                             (RETURN-SUBROUTINE #xCC 1)
                             (LOAD #xD0 3)
                             (LOAD-INDIRET #xD1 4)
                             (LOAD-REGISTER #xD2 3)
                             (LOAD-REGISTER-INDIRECT #xD4 3)
                             (LOAD-REGISTER-AUTOINCREMENT #xD5 3)
                             (LOAD-REGISTER-INDIRECT-AUTOINCREMENT #xD6 3)
                             (LOAD-OFFSET #xD7 5)
                             (LOAD-INDIRECT-OFFSET #xD8 5)
                             (STORE #xE0 4)
                             (STORE-INDIRET #xE1 4)
                             (STORE-REGISTER #xE2 3)
                             (STORE-REGISTER-INDIRECT #xE3 3)
                             (STORE-REGISTER-AUTOINCREMENT #xE4 3)
                             (STORE-REGISTER-INDIRECT-AUTOINCREMENT #xE5 3)
                             (STORE-OFFSET #xE6 5)
                             (STORE-INDIRECT-OFFSET #xE7 5)))

;; Defines the machine code values for different registers
(define registers '((R0 #x0) (R1 #x1) (R2 #x2) (R3 #x3) (R4 #x4) (R5 #x5) (R6 #x6) (R7 #x7)
                    (R8 #x8) (R9 #x9) (RA #xA) (RB #xB) (RC #xC) (RD #xD) (RE #xE) (RF #xF)
                    (REGISTER-0 #x0) (REGISTER-1 #x1) (REGISTER-2 #x2) (REGISTER-3 #x3)
                    (REGISTER-4 #x4) (REGISTER-5 #x5) (REGISTER-6 #x6) (REGISTER-7 #x7)
                    (REGISTER-8 #x8) (REGISTER-9 #x9) (REGISTER-A #xA) (REGISTER-B #xB)
                    (REGISTER-C #xC) (REGISTER-D #xD) (REGISTER-E #xE) (REGISTER-F #xF)
                    (DATA-STACK-POINTER-HIGH #xA) (DATA-STACK-POINTER-LOW #xB)
                    (RETURN-STACK-POINTER-HIGH #xC) (RETURN-STACK-POINTER-LOW #xD)
                    (PROGRAM-COUNTER-HIGH #xE) (PROGRAM-COUNTER-LOW #xF)))


;; Defines all the directives
(define directives '(.INCL .RAW .LABEL .BYTE .WORD .LABEL .DATA .ASCII .ASCIZ))

;; Creates list of all instructions
(define make-instr-lst
  (lambda (instrs)
    (if (null? instrs)
        nil
        (cons (list (first (car instrs)))
              (make-instr-lst (cdr instrs))))))

;; Creates list of instruction opcodes
(define make-instr-opcodes
  (lambda (instrs)
    (if (null? instrs)
        nil
        (cons (list (first (car instrs))
                    (second (car instrs)))
              (make-instr-opcodes (cdr instrs))))))

;; Creates list of instruction lengths
(define make-instr-lengths
  (lambda (instrs)
    (if (null? instrs)
        nil
        (cons (list (first (car instrs))
                    (third (car instrs)))
              (make-instr-lengths (cdr instrs))))))

;; Defines the lengths of all instructions in bytes
(define opcode-lengths (make-instr-lengths titan-instructions))

;; Defines the opcodes for all instructions
(define opcodes (make-instr-opcodes titan-instructions))


;;;; === Functions that actually ASSEMBLE instructions ====

;; Assembles instructions with byte format:
;; #x00 <- OPCODE
;; #xSD <- OPERAND
;; Where S is Register-Source and D is Register-Destination
(define assemble-RSRD
  (lambda (instr)
    (list (opcode instr)
          (combine-nibbles (first (operands instr))
                           (second (operands instr))))))

;; Assembles instructions with byte format:
;; #x0S
;; Where S is Register-Source (Also Destination, eg (NOT R0)
(define assemble-RS
  (lambda (instr)
    (list (bitwise-ior (opcode instr)
                       (first (operands instr))))))

;; Assembles Load Constant instruction
(define assemble-LDC
  (lambda (instr)
    (list (bitwise-ior (opcode instr)
                       (second (operands instr)))
          (first (operands instr)))))

;; Assembles standard JMP instruction, (JMP #xBABE)
(define assemble-JUMP
  (lambda (instr)
    (list (first instr)
          (split-address (first (operands instr))))))

(define assemble-JUMP-INDIRECT
  (lambda (instr)
    (list (opcode instr)
          (split-address (first (operands instr))))))

(define assemble-JUMP-REGISTER
  (lambda (instr)
    (list (opcode instr)
          (combine-nibbles (first (operands instr))
                           (second (operands instr))))))

(define assemble-JUMP-OFFSET
  (lambda (instr)
    (list (opcode instr)
          (combine-nibbles (first (operands instr))
                           (second (operands instr)))
          (split-address (third (operands instr))))))

(define assemble-LOAD
  (lambda (instr)
    (list (opcode instr)
          (combine-nibbles (second (operands instr))
                           0)
          (split-address (first (operands instr))))))

(define assemble-LOAD-REGISTER
  (lambda (instr)
    (list (opcode instr)
          (combine-nibbles (first (operands instr))
                           (second (operands instr)))
          (combine-nibbles (third (operands instr))
                           0))))

(define assemble-LOAD-OFFSET
  (lambda (instr)
    (list (opcode instr)
          (combine-nibbles (first (operands instr))
                           (second (operands instr)))
          (split-address (third (operands instr)))
          (combine-nibbles (fourth (operands instr))
                           0))))

(define assemble-STORE
  (lambda (instr)
    (list (opcode instr)
          (combine-nibbles (first (operands instr))
                           0)
          (split-address (second (operands instr))))))

(define assemble-STORE-REGISTER
  (lambda (instr)
    (list (opcode instr)
          (combine-nibbles (second (operands instr))
                           (third (operands instr)))
          (combine-nibbles (first (operands instr))
                           0))))

(define assemble-STORE-OFFSET
  (lambda (instr)
    (list (opcode instr)
          (combine-nibbles (second (operands instr))
                           (third (operands instr)))
          (combine-nibbles (first (operands instr))
                           0)
          (split-address (fourth (operands instr))))))
