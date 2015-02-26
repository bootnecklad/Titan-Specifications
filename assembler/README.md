# Titan Assembler #

## Description ##

An Assembler for Titan written in scheme.

## Useage ##

    (assemble program-name address-offset)

### Example ###

First define a valid Titan program

    (define example-program '(
    (.LABEL LOOP)
       (LDI R0 #x0000)   ; Fetch byte from set of byes in memory
       (TST R0)          ; Tests byte fetched
       (JPZ END)         ; If 0x00 then end of the set
       (INC R1)          ; Next address must be +1 from previous
       (JMP LOOP)        ; Fetch next byte
    (.LABEL END)
       (HLT)))           ; Halt

Then,

    #;7> (assemble example-program 0)
    Length of program in bytes: 16
    
    0000 : B0 00 00 15 
    0004 : 00 A1 00 0D 
    0008 : 18 10 A0 00 
    000C : 00 A0 00 0D 

## Conventions ##

All conventions are in the specification which can be found [here](https://github.com/bootnecklad/Titan-Specifications/blob/master/Specifications.md)

## But bootnecklad there are assemblers out there already, why? ##

Because I can't keep track of them all the time or update them when I change something that annoys said writers of assemblers.