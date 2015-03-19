# Titan Assembler #

## Description ##

An Assembler for Titan written in scheme.

## Useage ##

    (assemble program-name address-offset)

    ./assemble input-file address-offset

### Example ###

Write a valid titan program to a file:

    ((NOP)
     (ADD R1 R2)
     (.DATA VALUES 170 187 204)
     (NOP)
     (.LABEL LABEL-NAME-TEST)
     (ADD RF RA)
     (JUMP LABEL-NAME-TEST))

Then using CHICKEN, compile the assembler and assemble the file.

    $ csc assembler.scm -o assembler
    $ ./assemble
    Useage: assemble input-file address-offset
    $ ./assembler testprogram.asm 1000
    Length of program in bytes: 12
    
    03E8 : 00 01 12 AA 
    03EC : BB CC 00 01 
    03F0 : FA 02 03 EF 

## Conventions ##

All conventions are in the specification which can be found [here](https://github.com/bootnecklad/Titan-Specifications/blob/master/Specifications.md)

## But bootnecklad there are assemblers out there already, why? ##

Because I can't keep track of them and update them when I change something in the spec.