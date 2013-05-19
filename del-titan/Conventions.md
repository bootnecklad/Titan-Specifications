# Conventions #

## Register Layout ##

[R0,R1] TEMP REG / WORKING REG
[R2,R3] TEMP REG / WORKING REG
[R4,R5] TEMP REG / WORKING REG
[R6,R7] INDEX REGISTER
[R8,R9] HEAP POINTER
[RA,RB] GOBAL POINTER


## Memory Map ##

0000-1FFF - SPACE FOR STUFF (8k)
2000-3FFF - PROGRAM SPACE (8k)
4000-43FF - GLOBAL LIST (1k)
4400-DFFF - HEAP (40k)