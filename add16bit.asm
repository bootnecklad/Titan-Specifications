;;; 16 bit add functino on an 8 bit processor
;;; First value in R0,R1
;;; Second value in R2,R3
;;; Performs (ADD [R0 R1] [R2 R3])

(.LABEL ADD-16)
        (ADD R1 R3)             ; Adds low byte of two 16 bit numbers
        (JNC NO-CARRY)          ; If carry bit set then addition overflowed
        (INC R2)                ; Increment high byte to carry cary bit though
(.LABEL NO-CARRY)
        (ADD R0 R2)             ; Adds high byte of two numbers
