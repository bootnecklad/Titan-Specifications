Titan - expanded instruction set. AWESOME!

0000 NOP
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




ADD, SUB, AND, LOR, XOR:

Syntax: ADD Rd,Rs

Rs = SOURCE REGISTER
Rd = DESTINATION REGISTER

Assembled:

0001 0000
SSSS DDDD

Where, SSSS and DDDD are the register operands for source and destination registers




NOT:

NOT Rn

Assembled:

0110 XXXX

Where, XXXX is register operand for Rn.



PSH, POP (Push and Pop, stack operations):

Syntax: PSH Rn, POP Rn

Assembled: 0111 XXXX

Where, XXXX is register operand for Rn.



MOV (Move):

MOV Rd,Rs

Rs = SOURCE REGISTER
Rd = DESTINATION REGISTER

Assembled:

1001 0000
SSSS DDDD
Where, SSSS and DDDD are the register operands for source and destination registers



JMP (Jump Direct):

Included: JMP, JPZ, JPS, JPC

Only JMP has indexed addressing.

Opcode    I    Src
-------  ---  -----
1 0 0 1   0   0 0 0   -  JMP 0xZZZZ - Standard direct jump to 0xZZZZ
1 0 0 1   0   0 0 1   -  JPZ 0xZZZZ - Standard jump if zero flag set
1 0 0 1   0   0 1 0   -  JPS 0xZZZZ - Standard jump if sign flag set
1 0 0 1   0   0 1 1   -  JPC 0xZZZZ - Standard jump if carry flag set
1 0 0 1   1   0 0 0   -  JMI 0xZZZZ - Where base address is in R1(high byte) and R2(low byte) offset by 0xZZ



JPI (Jump Indirect):

JPI 0xZZZZ

Indirect jump, point to a location in memory(0xZZZZ) and jumps to the value stored in the address (Big endian)

Assembled:

1011 0000
YYYY YYYY
YYYY YYYY

Where, YYYY YYYY YYYY YYYY is the address stored in ZZZZ and ZZZZ+1



JSR (Jump Subroutine):

JSR 0xZZZZ

Assembled:

1100 0000
XXXX XXXX
XXXX XXXX

Where, XXXX XXXX is 0xZZZZ.



LDC (Load Constant):

LDC Rn,0xXX

Assembled:

1101 YYYY
XXXX XXXX

Where, XXXX XXXX is 0xXX and YYYY is operand for Rn.



LDM+STM (Load/Store Memory):

LDM Rn,0xYYYY
LDI Rn,0xYY

STM Rn,0xYYYY
STI Rn,0xYY

Assembled:

1 1 1 0   0   D D D   -  LDM Rn,0xYYYY - Standard load byte from memory, from address YYYY to DDD.
1 1 1 0   1   D D D   -  LDI Rn,0xYY - Indexed load byte from memory, from base address in R0(high byte) and R1(low byte), offset is 0xYY

1 1 1 1   0   D S S   -  STM Rn,0xZZZZ - Standard store byte to memory, to address ZZZZ, byte from SSS.
1 1 1 1   1   D S S   -  STM Rn,0xZZZZ - Indexed store byte to memory, to base address in R0(high byte) and R1(low byte), offset is 0xYY