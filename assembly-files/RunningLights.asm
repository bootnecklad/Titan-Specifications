; Titan assembly program - Running Lights
; Displays a single LED that bounces back and forth between 0x01 and 0x08 on the displayed LEDs on the case.
; Display LEDs mapped too 0xFFFE(high byte of output) and 0xFFFD (low byte of output)
; Running lights uses lower byte.
; (C) Marc Cleave 01/02/2012


(.WORD CASE-OUTPUT-LED 0xFFFD)

(.LABEL START)
   (LDC #x01 R1)
   (LDC #x80 R2)

(.LABEL SETUP-LEFT)
   (MOV R1 R0)

(.LABEL LOOP-LEFT)
   (STM R0 CASE-OUTPUT-LED)
   (SHL R0)
   ($JNC LOOP-LEFT)

(.LABEL SETUP-RIGHT)
   (MOV R2 R0)

(.LABEL LOOP-RIGHT)
   (MOV R2 R0)
   (STM R0 CASE-OUTPUT-LED)
   (SHR R0)
   (JPC SETUP-RIGHT)
   (JMP LOOP-RIGHT)
