(define REGISTER-TABLE (list (cons 'R0 #x0) (cons 'R1 #x1)
                             (cons 'R2 #x2) (cons 'R3 #x3)
                             (cons 'R4 #x4) (cons 'R5 #x5)
                             (cons 'R6 #x6) (cons 'R7 #x7)
                             (cons 'R8 #x8) (cons 'R9 #x9)
                             (cons 'RA #xA) (cons 'RB #xB)
                             (cons 'RC #xC) (cons 'RD #xD)
                             (cons 'RE #xE) (cons 'RF #xF)
                             (cons 'REGISTER-F #xF) (cons 'REGISTER-A #xA)))

;;; Instruction definitions

(define NOP
  (lambda args
    (cond 
     ((null? args) (list #x00))
     ((not (first args)) 1))))

(define HALT
  (lambda args
    (cond
     ((null? args) (list #xFF))
     ((first args) 1))))

(define ADD
  (lambda args
    (if (first args)
        (list #x01 (combine-registers (first args) (second args)))
        2)))

(define JUMP
  (lambda args
    (if (first args)
        (list #x02 (split-address (first args)))
        3)))

(define CLEAR
  (lambda args
    (if (first args)
        (list #0x99 (first args))
        1)))
        
(define .RAW
  (lambda args
    args))
