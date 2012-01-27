# Titan - expanded instruction set #

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
    1011 LDI
    1100 STI
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

### Example: ADD Rs,Rd ###

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


### MOV Rs,Rd ###

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



### LDC Rn,0xXX ###

Assembled:

    1101 DDDD
    XXXX XXXX

Where, XXXX XXXX is 0xXX and DDDD is operand for Rn.


### LDM+STM (Load/Store Memory) ###

    LDM Rn,0xYYYY

    STM Rn,0xYYYY

Assembled:

    Opcode     Dst
    -------   ------
    1 1 1 0   D D D D   -  LDM Rn,0xYYYY - Load byte from memory, from address YYYY to DDDD
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

Below are examples for BYTE and WORD:

    .BYTE <label> 0xZZ
	.WORD <label> 0xZZZZ

Titan byte is 8bits, Titan word is 16bits.