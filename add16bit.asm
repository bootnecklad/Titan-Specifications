ADD_16:
   CLR R0
   ADD R4,R2    ; Adds low byte of two 16 bit numbers
   JPC ADD16C0  ; If carry bit set then addition overflowed, need to increment high byte of one 16bit number
   JMP ADD16CC0 ; Carry bit not set, carry on.. (haha!)
   
ADD16C0:
   LDC R5,0x01
   ADD R5,R1    ; Increment high byte of one of the 16 bit numbers
   JPC ADD16C1  ; If incrementation overflowed then need to increment R0 (overflow register, ie addition will be greater than 65536)
   JMP ADD16CC0 ; Didn't happen...
   
ADD16C1:
   ADD R5,R0    ; Increments overflow register (R0), 0x01 already in R5, dont need to load again
   
ADD16CC0:
   ADD R3,R1    ; Adds high bytes of two 16bit numbers
   JPC ADD16OF  ; High bytes overflowed, need to increment overflow register
   JMP END      ; Finished! Result is in R1(high byte) and R2(low byte) if result overflowed then R0 contains overflow bit.
   
ADD16OF:
   LDC R5,0x01  ; Dont know if overflow register has already been incremented
   ADD R5,R0    ; Overflow register sorted
   JMP END      ; Finished!
   
END:
   JMP END