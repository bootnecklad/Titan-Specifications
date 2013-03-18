# Old-Titan instruction set from ~2009 #

Has four registers:

    program counter - 4 bits for 16 instructions
    registers A, B and C - 2 bit regusters
    3 bit alu result register


    FUNC OPER DT
    0000 0000 00

    FUNC - Function
    OPER - Operand
    DT - Data


    FUNC
    0 - halt
    1 - other function
    2 - address function
    4 - alu function
    8 - jump instruction

---------------

## ALU functions: ##

    0100 0XXX 00

    XXX:
    001 1 ADD
    010 2 SUB
    011 3 OR
    100 4 XOR
    101 5 AND
    110 6 NOT

---------------

## address function ( move registers around ) ##

    0010 SSDD 00

    00 Data
    01 Register A
    10 Register B
    11 Register C


if dest is 00 (invalid register), this copies data from the data to src

---------------

## jump instruction: ##

    1000 ADDR 00

jumps to the address at ADDR, ie if ADDR was 0110, then program branches to address 0110

---------------

## other function: ##

0001 XXXX 00

    XXXX:
    0001 - if A and B are not equal then skip next instruction ?
    0010 - feed aluresult to databus
    0011 - put alu result into register A
    0100 - put alu result into register B
    0101 - put alu result into register C