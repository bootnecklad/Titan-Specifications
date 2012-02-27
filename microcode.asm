; Titan Microcode
; Copyright (C) 2012 Marc Cleave, bootnecklad@gmail.com
; Assume that all bits are low unless specified here
; [H] - Set bit high until turned low
; [L] - Set bit low
; [S] - Set bit on only for that microinstruction
; 

Instruction Fetch:
   0) Output Signals for memory read
   1) Write INS_REG_1

ADD,ADC,SUB,AND,LOR,XOR:
   0) INC_PC [S]
   1) MEM_OE [H], MEM_READ [H], MEM_ENABLE [H]
   2) CLK_INS_REG_1[S]
   3) INS_REG_1_HIGH_REG_R[H], MEM_OE [L], MEM_READ [L], MEM_ENABLE [L]
   4) CLK_ALU_A[S]
   5) INS_REG_1_LOW_R[H], INS_REG_1_HIGH_REG_R[L]
   6) CLK_ALU_A[S]
   7) Output signals to ALU_DECODER, INS_REG_1_LOW_REG_W[H]
   8) REG_WRITE[S], FLAG_REG[S], INC_PC[S]

SHR,SHL,NOT:
   0) Increment PC
   1) Output signals for memory read
   2) Write INS_REG_1
   3) INS_REG_1_HIGH -> REG_READ
   4) Write ALU_A, CLR ALU_B
   5) Output signals to ALU_DECODER, INS_REG_1_LOW -> REG_WRITE
   6) Write REG_WRITE, Write FLAG_REG, Increment PC

PUSH:
   0) INS_REG_0_LOW -> REG_READ, Output signals for stack push(Databus->Stack, Increment SP)
   1) Write Stack
   2) REG_READ OFF, Increment PC   ; Can possibly be added into the 1) step

POP:
   0) INS_REG_0_LOW->REG_WRITE, Output signals for stack pop(Stack->Databus)
   1) REG_WRITE
   2) REG_READ OFF, Increment PC, Decrement STACK_POINTER

MOV:
   0) Increment PC
   1) Output signals for memory read
   2) Write INS_REG_1
   3) INS_REG_1_HIGH->REG_READ, INS_REG_1_LOW->REG_WRITE
   4) Write REG_WRITE, Increment PC

JMP:
   0) Increment PC
   1) Output signals for memory read
   2) Write INS_REG_1
   3) Increment PC
   4) Output signals for memory read
   5) Write INS_REG_2
   6) 0xFE->REG_WRITE, Output INS_REG_2 to Databus
   7) REG_WRITE
   8) 0xFF->REG_WRITE, Output INS_REG_1 to Databus
   9) REG_WRITE

JPZ:
   0) Increment PC
   1) Output signals for memory read
   2) Write INS_REG_1
   3) Increment PC
   4) Output signals for memory read
   5) Write INS_REG_2
   6) Increment PC
   7) Enable MC_Z_RESET   ; If the flag is set of the instruction then the microcode counter is reset, instruction doesnt execute
   8) 0xFE->REG_WRITE, Output INS_REG_2 to Databus
   9) REG_WRITE
   A) 0xFF->REG_WRITE, Output INS_REG_1 to Databus
   B) REG_WRITE

JPS:
   0) Increment PC
   1) Output signals for memory read
   2) Write INS_REG_1
   3) Increment PC
   4) Output signals for memory read
   5) Write INS_REG_2
   6) Increment PC
   7) Enable MC_S_RESET   ; If the flag is set of the instruction then the microcode counter is reset, instruction doesnt execute
   8) 0xFE->REG_WRITE, Output INS_REG_2 to Databus
   9) REG_WRITE
   A) 0xFF->REG_WRITE, Output INS_REG_1 to Databus
   B) REG_WRITE

JPC:
   0) Increment PC
   1) Output signals for memory read
   2) Write INS_REG_1
   3) Increment PC
   4) Output signals for memory read
   5) Write INS_REG_2
   6) Increment PC
   7) Enable MC_C_RESET   ; If the flag is set of the instruction then the microcode counter is reset, instruction doesnt execute
   8) 0xFE->REG_WRITE, Output INS_REG_2 to Databus
   9) REG_WRITE
   A) 0xFF->REG_WRITE, Output INS_REG_1 to Databus
   B) REG_WRITE

JPI:
   0) Increment PC
   1) Output signals for memory read
   2) Write INS_REG_1
   3) Increment PC
   4) Output signals for memory read
   5) Write INS_REG_2
   6) Enable INS_REG memory read signal
   7) Output signals for memory read
   8) Write INS_REG_1
   9) Increment PC
   A) Output signals for memory read
   B) Write INS_REG_2
   C) 0xFE->REG_WRITE, Output INS_REG_2 to Databus
   D) REG_WRITE
   E) 0xFF->REG_WRITE, Output INS_REG_1 to Databus
   F) REG_WRITE

JSR:
   0) 0xFE->REG_READ, Output signals for stack push(Databus->Stack, Increment SP)
   1) Write Stack
   2) REG_READ OFF   ; Can possibly be added into the 1) step
   3) 0xFF->REG_READ, Output signals for stack push(Databus->Stack, Increment SP)
   4) Write Stack
   5) REG_READ OFF   ; Can possibly be added into the 4) step
   6) Increment PC
   7) Output signals for memory read
   8) Write INS_REG_1
   9) Increment PC
   A) Output signals for memory read
   B) Write INS_REG_2
   C) 0xFE->REG_WRITE, Output INS_REG_2 to Databus
   D) REG_WRITE
   E) 0xFF->REG_WRITE, Output INS_REG_1 to Databus
   F) REG_WRITE

RTN:
   0) 0xFF->REG_WRITE, Output signals for stack pop(Stack->Databus)
   1) REG_WRITE
   2) REG_READ OFF, Increment PC, Decrement STACK_POINTER
   3) 0xFF->REG_WRITE, Output signals for stack pop(Stack->Databus)
   4) REG_WRITE
   5) REG_READ OFF, Increment PC, Decrement STACK_POINTER

JMI 0xZZZZ:
   0) Increment PC
   1) Output signals for memory read, 0xFE->REG_WRITE
   2) Write REG_WRITE
   3) Increment PC
   4) Output signals for memory read
   5) Write ALU_B
   6) 0x01->REG_READ
   7) Write ALU_A
   8) ADD to ALU_DECODER, 0xFE->REG_WRITE
   9) Write REG_WRITE
   A) Enable NOT_MC_C_RESET, CLR ALU_B ; If the flag is set, high byte of PC needs to be increment
   B) 0xFF->REG_READ
   C) Write ALU_A
   D) ADC to ALU_DECODER, 0xFF->REG_WRITE
   E) Write REG_WRITE

JMI [R1,R2]:
   0) 0x01->REG_READ, 0xFF->REG_WRITE
   1) REG_WRITE
   2) 0x02->REG_READ, 0xFE->REG_WRITE
   3) REG_WRITE

LDI 0xZZZZ:
   0) Increment PC
   1) Output signals for memory read
   2) Write INS_REG_1
   3) Increment PC
   4) Output signals for memory read
   5) Write ALU_B
   6) 0x01->REG_READ
   7) Write ALU_A, ADD to ALU_DECODER
   8) Write INS_REG_2, 0xD->MICROCODE_STEP   ; Load previous step, then increment then step E will be loaded into microcode registers
   9) NOT_MC_C to load MICROCODE_STEP, CLR ALU_B ; If the flag is set, high byte of address needs to be increment
   A) Output INS_REG_0 to Databus
   B) Write ALU_A
   C) ADC to ALU_DECODER
   D) Write INS_REG_1
   E) Enable INS_REG memory read signal, INS_REG_0_LOW->REG_WRITE
   F) REG_WRITE

STI 0xZZZZ:
   0) Increment PC
   1) Output signals for memory read
   2) Write INS_REG_1
   3) Increment PC
   4) Output signals for memory read
   5) Write ALU_B
   6) 0x01->REG_READ
   7) Write ALU_A, ADD to ALU_DECODER
   8) Write INS_REG_2, 0xD->MICROCODE_STEP   ; Load previous step, then increment then step E will be loaded into microcode registers
   9) NOT_MC_C to load MICROCODE_STEP, CLR ALU_B ; If the flag is set, high byte of address needs to be increment
   A) Output INS_REG_0 to Databus
   B) Write ALU_A
   C) ADC to ALU_DECODER
   D) Write INS_REG_1
   E) Enable INS_REG memory write signal, INS_REG_0_LOW->REG_READ
   F) Write memory

LDI [R1,R2]:
   0) 0x01->REG_READ
   1) Write INS_REG_1
   2) 0x02->REG_READ
   3) Write INS_REG_2
   4) Enable INS_REG memory read signal, INS_REG_0_LOW->REG_WRITE
   5) REG_WRITE

STI [R1,R2]:
   0) 0x01->REG_READ
   1) Write INS_REG_1
   2) 0x02->REG_READ
   3) Write INS_REG_2
   4) Enable INS_REG memory write signal, INS_REG_0_LOW->REG_READ
   5) Write memory

LDC:
   0) Increment PC
   1) Output signals for memory read, INS_REG_0_LOW->REG_WRITE
   2) REG_WRITE

LDM:
   0) Increment PC
   1) Output signals for memory read
   2) Write INS_REG_1
   3) Increment PC
   4) Output signals for memory read
   5) Write INS_REG_2
   6) Enable INS_REG memory read signal, INS_REG_0_LOW->REG_WRITE
   7) REG_WRITE

STM:
   0) Increment PC
   1) Output signals for memory read
   2) Write INS_REG_1
   3) Increment PC
   4) Output signals for memory read
   5) Write INS_REG_2
   6) Enable INS_REG memory write signal, INS_REG_0_LOW->REG_READ
   7) Write memory