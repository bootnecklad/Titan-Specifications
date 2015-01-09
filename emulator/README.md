# Titan Emulator #

## Description ##

An Emulator for Titan written in scheme.

## Conventions ##

All conventions are in the specification which can be found [here](https://github.com/bootnecklad/Titan-Specifications/blob/master/Specifications.md)

## Usage ##

To use the emulator you need to do the following in the REPL:

    (install-opcodes)

Then loading machine code/writing registers can be done via the poke-values function:

    (poke-values cpu 0 
               #b00000000
	       #b00000000
	       #b00000000
	       #b10010000
	       #b00000001
	       #b00000000
	       #b00000000
	       #b00010000
	       #b00000001
	       #b00000000
	       #b10100000
	       #b11110000
	       #b00000000)
    (poke-values cpu #b1111000000000000
	       #b10010000
	       #b00010010
	       #b00000000
	       #b00000001)
    (write-register! titan 0 1))


Then finally running the cpu will output register stages when execution has halted.

    (controller titan)