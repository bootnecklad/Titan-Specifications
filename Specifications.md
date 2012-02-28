# Titan - expanded instruction set #

## Opcode summary ##

    0000 NOP
    0001 ART*
    0111 PSH
    1000 POP
    1001 REG*
    1010 JMP*
    1011 LDI*
    1100 STI*
    1101 LDC
    1110 LDM
    1111 STM

## Notation ##

Rn = SINGLE SOURCE REGISTER
Rs = SOURCE REGISTER
Rd = DESTINATION REGISTER
SSSS = Source register
DDDD = Destination register

## Flags ##

Z: Set if ALU operation stores a zero in the destination register.

C: Set if ALU operation carries a 1 bit from the high order bits. (What about SUB?)

S: Set if ALU operation stores a 2's complement negative number (high bit set).

## Arithmetic ADD, ADC,SUB ##

### Examples: ADD Rs,Rd  ADC Rs,Rd, SUB Rs,Rd, AND Rs,Rd  LOR Rs,Rd  XOR Rs,Rd, NOT Rs  SHL Rs  SHR Rs ###

    Opcode   Cond
    -------  -------
    0 0 0 1  0 0 0 0   -  ADD Rs,Rd - Adds source and destination register
	0 0 0 1  0 0 0 1   -  ADC Rs,Rd - Add source and destination register with carry in high
	0 0 0 1  0 0 1 0   -  SUB Rs,Rd - Subtracts source and destination register
    0 0 0 1  0 0 1 1   -  AND Rs,Rd - Logical AND of source and destination register
	0 0 0 1  0 1 0 0   -  LOR Rs,Rd - Logical OR of source and destination register
	0 0 0 1  0 1 0 1   -  XOR Rs,Rd - Logical XOR of source and destination register
    0 0 0 1  0 1 1 0   -  NOT Rs - Invert/Complement of source register
	0 0 0 1  0 1 1 1   -  SHR Rs - Shifts all bits right away from carry of source register(LSB fed into carry)


## Stack operations ##

### PSH Rn ###

Assembled: 

    0111 SSSS

Where, SSSS is register operand for Rn.

### POP Rn ###

Assembled: 

    1000 DDDD


## Register operations ##


### MOV Rs,Rd, CLR Rn, XCH Rs,Rd ###

    Opcode   Cond
    -------  -------
    1 0 0 1  0 0 0 0   -  MOV Rs,Rd - Moves Rs into Rd
	1 0 0 1  0 0 0 1   -  CLR Rn    - Clears Rn
	1 0 0 1  0 0 1 0   -  XCH Rs,Rd - Exchanges Rs and Rd, like XOR swap but quicker

Second byte of instruction is assembled into:

SSSS DDDD


### Direct Jumps: JMP, JPZ, JPS, JPC ###

Only JMI has indexed addressing.

    Opcode    I   Cond
    -------  ---  -----
    1 0 1 0   0   0 0 0   -  JMP 0xZZZZ - Direct jump to 0xZZZZ
    1 0 1 0   0   0 0 1   -  JPZ 0xZZZZ - Jump if zero flag set
    1 0 1 0   0   0 1 0   -  JPS 0xZZZZ - Jump if sign flag set
    1 0 1 0   0   0 1 1   -  JPC 0xZZZZ - Jump if carry flag set
	1 0 1 0   0   1 0 0   -  JPI 0xZZZZ - Indirect jump, point to a location in memory (0xZZZZ) and jumps to the value stored in the address (Big endian)
	1 0 1 0   0   1 0 1   -  JSR 0xZZZZ - Push return address onto stack, direct jump to 0xZZZZ
	1 0 1 0   0   1 1 0   -  RTN        - Returns to address thats stored on stack
    1 0 1 0   1   0 0 0   -  JMI 0xZZZZ - Where base address is 0xZZZZ and offset is in R1
	1 0 1 0   1   0 0 1   -  JMI [R1,R2]- Where address to jump to is in R1(high byte) and R2(low byte)

### LDI+STI (Indexed Load/Store Memory) ###

    LDI Rn,0xZZZZ
    LDI Rn
	
    STM Rn,0xZZZZ
    STI Rn

Assembled:

    Opcode    I     Dst
    -------   --   ------
    1 0 1 1   0    D D D    -  LDI Rn,0xZZZZ - Indexed load byte from memory, from address ZZZZ, offset in R1
	Z Z Z Z   Z    Z Z Z
	Z Z Z Z   Z    Z Z Z

	1 1 0 0   0    S S S    -  STI Rn,0xZZZZ - Indexed store byte to memory, from address ZZZZ, offset in R1
	Z Z Z Z   Z    Z Z Z
	Z Z Z Z   Z    Z Z Z
	
    1 0 1 1   1    D D D    -  LDI Rn,[R1,R2] - Indexed load byte from memory, from address in R1(high byte) and R2(low byte)
	
	1 1 0 0   1    S S S    -  STI Rn,[R1,R2] - Indexed store byte to memory, from address in R1(high byte) and R2(low byte)



### LDC Rn,0xZZ ###

Assembled:

    1101 DDDD
    ZZZZ ZZZZ

Where, ZZZZ ZZZZ is 0xZZ and DDDD is operand for Rn.


### LDM+STM (Load/Store Memory) ###

    LDM Rn,0xZZZZ

    STM Rn,0xZZZZ

Assembled:

    Opcode     Dst
    -------   ------
    1 1 1 0   D D D D   -  LDM Rn,0xZZZZ - Load byte from memory, from address ZZZZ to DDDD
    1 1 1 1   S S S S   -  STM Rn,0xZZZZ - Store byte to memory, to address ZZZZ, byte from SSS.


	

	
	
### ASSEMBLY CONVENTIONS ###

Labels are used to write programs, you dont want to be dealing with straight addresses. It hurts. A lot!

    LOOP:
       LDI R0,STRING[R3]     ; Gets next byte from string
       TST R0                ; Tests byte fetched from string
       JPZ END               ; If 0x00 then end of the string!
       ADD R2,R3             ; Next address to get string must be +1 from previous
       STM R0,SERIAL_PORT_0  ; Outputs ASCII data to 
       JMP LOOP              ; Time to get next character!

Above example shoves a label and a couple of instructions.


Below shows an ASCII string that will be placed in memory at FOO, FOO is a label, beginning in memory at the first character of the string

    .ASCII FOO "BAR ETC"
	.ASCIZ FOO "ZERO TERMINATED STRING, ADDS 0x00 AT END OF STRING"

Below is syntax for BYTE and WORD and DATA:

    .BYTE <label> 0xZZ
	.WORD <label> 0xZZZZ
	.DATA <label> 0xZZ 0xZZ ... 0xZZ

Titan byte is 8bits, Titan word is 16bits.

    .INCL "filename"

Above is the syntax for including another file containing assembly, this allows routines to be called from another file.