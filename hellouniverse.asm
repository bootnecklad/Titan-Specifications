; Titan assembly program that ouputs 'HELLO UNIVERSE' to the serial terminal
; 
; (C) Marc Cleave 27/01/2012

START:
   LDC R2,0x01  ; Needed for incrementing string byte count
   CLR R3       ; Clears R3 for indexed loading of bytes!!111


LOOP:
   LDI R0,STRING[R3]     ; Gets next byte from string
   TST R0                ; Tests byte fetched from string
   JPZ END               ; If 0x00 then end of the string!
   ADD R2,R3             ; Next address to get string must be +1 from previous
   STM R0,SERIAL_PORT_0  ; Outputs ASCII data to 
   JMP LOOP              ; Time to get next character!


END:
   JMP END  ; INFINITE LOOP HAHA!


STRING:
   0x48 ; ASCII 'H'
   0x45 ; ASCII 'E'
   0x4C ; ASCII 'L'
   0x4C ; 'L'
   0x4F ; 'O'
   0x20 ; ' '
   0x55 ; 'U'
   0x4E ; 'N'
   0x49 ; 'I'
   0x56 ; 'V'
   0x45 ; 'E'
   0x52 ; 'R'
   0x53 ; 'S'
   0x45 ; 'E'