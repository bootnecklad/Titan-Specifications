; Simple program that continuously copies the serial input to the output
;
; old program hand assemebled from address 0x0000
;
; 0000  E0 ZZ ZZ F0
; 0004  ZZ ZZ A0 00
; 0008  00


(.ORIG LOOP)
(.WORD SERIAL-PORT-0-IN #xFFFE)   ; still need to decide which address the serial port will be at
(.WORD SERIAL-PORT-0-OUT #xFFFF)

(.LABEL LOOP)
   ($TRA SERIAL-PORT-0-IN SERIAL-PORT-0-OUT)
   (JMP LOOP)


;;; new program using assembler
;;; 58> (assemble serial-loop 0)
;;; Length of program in bytes: 11
;;; 
;;; 0000 : 70 E0 FF FE 
;;; 0004 : F0 FF FF 80 
;;; 0008 : A0 00 00 
