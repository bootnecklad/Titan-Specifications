# Titan Emulator #

## Description ##

An Emulator for Titan written in scheme.

## Conventions ##

All conventions are in the specification which can be found [here](https://github.com/bootnecklad/Titan-Specifications/blob/master/Specifications.md)

## Usage ##

To use the emulator you need to do the following in the REPL:

    (install-opcodes)

Then loading machine code/writing registers can be done via the poke-values function:

    (poke-values titan 0 
       #b00000000   ; (NOP)
       #b11100001   ; (LDM #xFF00 R1)
       #b11111111
       #b00000000
       #b00000000   ; (NOP)
       #b00000000   ; (NOP)
       #b00000000   ; (NOP)
       #b00000000   ; (NOP)
       #b00000001)  ; (HLT)
       
You can provide the CPU with input, like you would with a serial terminal:

    (send-input titan "AAAAAA")


Then finally running the cpu will output register stages when execution has halted.

    (start-cpu titan)
