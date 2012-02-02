; Titan assembly program - Running Lights
; Displays a single LED that bounces back and forth between 0x01 and 0x08 on the displayed LEDs on the case.
; Display LEDs mapped too 0xFFFE(high byte of output) and 0xFFFD (low byte of output)
; Running lights uses lower byte.
; (C) Marc Cleave 01/02/2012


.WORD CASE_OUTPUT_LED 0xFFFD

START:
   LDC R1,0x01
   LDC R2,0x80
   MOV R1,R0

LOOP_LEFT:
   STM R0,CASE_OUTPUT_LED
   SHL R0
   JPC LOOP_RIGHT
   JMP LOOP_LEFT
   
LOOP_RIGHT:
   MOV R2,R0

LOOP:
   STM R0,CASE_OUTPUT_LED
   SHR R0
   JPZ LOOP_LEFT
   JMP LOOP