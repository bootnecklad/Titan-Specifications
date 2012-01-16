# Titan - expanded instruction set. AWESOME! #

## Opcode summary ##

    0000 SHR
    0001 ADD
    0010 SUB
    0011 AND
    0100 LOR
    0101 XOR
    0110 NOT
    0111 PSH
    1000 POP
    1001 MOV
    1010 JMP
    1011 JPI
    1100 JSR
    1101 LDC
    1110 LDM
    1111 STM

## Notation ##

Rs = SOURCE REGISTER
Rd = DESTINATION REGISTER

## Flags ##

Z: Set if ALU operation stores a zero in the destination register.

C: Set if ALU operation carries a 1 bit from the high order bits. (What about SUB?)

S: Set if ALU operation stores a 2's complement negative number (high bit set).

## Arithmetic/Logic: ADD, SUB, AND, LOR, XOR, NOT ##

### Example: ADD Rd,Rs ###

Assembled:

    0001 0000
    SSSS DDDD

Where, SSSS and DDDD are the register operands for source and destination registers


### NOT Rn, SHR Rn ###

Assembled:

    0000 DDDD
    0110 DDDD

Where, DDDD is register operand for Rn.


## Stack operations ##

### PSH Rn ###

Assembled: 

    0111 SSSS

Where, SSSS is register operand for Rn.

### POP Rn ###

Assembled: 

    1000 DDDD


### MOV Rd,Rs ###

Assembled:

    1001 0000
    SSSS DDDD

Where, SSSS and DDDD are the register operands for source and destination registers


### Direct Jumps: JMP, JPZ, JPS, JPC ###

Only JMI has indexed addressing.

    Opcode    I   Cond
    -------  ---  -----
    1 0 1 0   0   0 0 0   -  JMP 0xZZZZ - Direct jump to 0xZZZZ
    1 0 1 0   0   0 0 1   -  JPZ 0xZZZZ - Jump if zero flag set
    1 0 1 0   0   0 1 0   -  JPS 0xZZZZ - Jump if sign flag set
    1 0 1 0   0   0 1 1   -  JPC 0xZZZZ - Jump if carry flag set
    1 0 1 0   1   - - -   -  JMI 0xZZ   - Where base address is in R1(high byte) and R2(low byte) offset by 0xZZ


### Jump Indirect ###

    JPI 0xZZZZ

Indirect jump, point to a location in memory (0xZZZZ) and jumps to the value stored in the address (Big endian)

Assembled:

    1011 0000
    XXXX XXXX
    YYYY YYYY

Where, XXXX XXXX YYYY YYYY is the address where the jump target is stored, in two bytes.


### JSR (Jump Subroutine) ###


	Opcode     Cond
    -------   -------
    1 1 0 0   0 0 0 0   -  JSR 0xZZZZ - Direct jump to 0xZZZZ
	1 1 0 0   0 0 0 1   -  RTN - Returns to address that is stored in return address stack.


	JSR 0xZZZZ
	
Assembled:

    1100 0000
    XXXX XXXX
    XXXX XXXX

Where, XXXX XXXX is 0xZZZZ.


### LDC Rn,0xXX ###

Assembled:

    1101 DDDD
    XXXX XXXX

Where, XXXX XXXX is 0xXX and DDDD is operand for Rn.


### LDM+STM (Load/Store Memory) ###

    LDM Rn,0xYYYY
    LDI Rn,0xYY

    STM Rn,0xYYYY
    STI Rn,0xYY

Assembled:

    Opcode    I   Dst
    -------   -   -----
    1 1 1 0   0   D D D   -  LDM Rn,0xYYYY - Load byte from memory, from address YYYY to DDD.
    1 1 1 0   1   D D D   -  LDI Rn,0xYY   - Indexed load byte from memory,
                                             from base address in R0(high byte) and R1(low byte), offset is 0xYY
    1 1 1 1   0   S S S   -  STM Rn,0xZZZZ - Store byte to memory, to address ZZZZ, byte from SSS.
    1 1 1 1   1   S S S   -  STM Rn,0xZZZZ - Indexed store byte to memory,
                                             to base address in R0(high byte) and R1(low byte), offset is 0xYY
