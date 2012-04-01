; Simple program that continuously copies the serial input to the output
;
; hand assemebled from address 0x0000
;
; 0000  E0 ZZ ZZ F0
; 0004  ZZ ZZ A0 00
; 0008  00


.ORIG LOOP
.WORD SERIAL_PORT_0 0xFFFF   ; still need to decide which address the serial port will be at

LOOP:
   LDM R0,SERIAL_PORT_0
   STM R0,SERIAL_PORT_0
   JMP LOOP