; One of first Titan Assembly programs ever written
; I found it in an old backup of website from when I began the project
; First is the ORIGINAL program and the assembled machine code
; Then the NEW assembly program followed by the assembled machine code
; I believe there has been much improvement
;
; Number of bytes in old program: 19 bytes
; Number of bytes in new program: 9 bytes
; (9/(9+19))*100 = 32% more efficient!
;
; This shows that the new ISA is a success in this case. :>
;
; Marc Cleave - 11/01/2012
;
;
; ADDR   ASM             COMMENTS
; 00   jmp 0x0005    /Skips two numbers to be added together
; 03   0x56          /Number one
; 04   0x7f          /Number two
; 05   ldm 0x0003    /
; 06   psh a         /
; 07   pop b         /Loads number one into B
; 08   ldm 0x0004    /Loads number two into accumulator
; 0b   add           /Adds two numbers
; 0c   stm 0xffff    /Writes accumulator to I/O port 256, LED display on front panel
; 0f   jmp 0x000f    /Continuous loop
;
;
; Machine Code
;      
; 1001 0000
; 0000 0000
; 0000 0101
; 0101 0110
; 0111 1111
; 1110 0010
; 0000 0000
; 0000 0011
; 1110 0001
; 0000 0000
; 0000 0100
; 0001 0000
; 1111 0001
; 1111 1111
; 1111 1111
; 0000 0000
; 1001 0000
; 0000 0000
; 0000 1000
;
;
; BEGIN:
;    LDC R0,0x56   ; Loads first constant to be added
;   LDC R1,0x7F   ; Loads second constant to be added
;    ADD R0,R1     ; Adds the two values in R0 and R1
;    STM R0,0xFFFF ; Outputs new value to LED I/O Port   
;
; END:
;    JMP END       ; Continuous loop
;
;
; Machine code:
;
; 1101 0000
; 0101 0110
; 1101 0001
; 0111 1111
; 0001 0000
; 0000 0001
; 1111 0000
; 1111 1111
; 1111 1111
; 1010 0000
; 0000 0000
; 0000 1001





(define EFFICIENCY-EXAMPLE '(

(.WORD LED-OUTPUT #xFF00)

(.LABEL BEGIN)
   (LDC R0 #x56)
   (LDC R1 #x7F)
   (ADD R0 R1)
   (STM R0 LED-OUTPUT)

(.LABEL END)
   (JMP END)))



; Machine code:

;#;49> (assemble EFFICIENCY-EXAMPLE 0)
;Length of program in bytes: 14
;
;D0 00 56 D1 00 7F 10 01 F0 00 00 A0 00 09 
