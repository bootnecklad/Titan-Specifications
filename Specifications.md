# Titan - Specifications #

## System Specifications ##

Currently, Titan has the following specifications:

    8 bit data bus
    16 8 bit registers, mapped to them are the program counter and stack pointer
    16 bit stack pointer(64k stack)
    16 bit program counter
	64k addressable memory
    Capable of 10 8bit arithmetic functions
    Various addressing modes(Immediate, Indirect, Index, Register)
	Memory mapped I/O
	
	Planned Memory map:
	0000-9EFF - Fixed SRAM
	9F00-DFFF - Switchable 16k banked SRAM
	E000-FEFF - 8k EEPROM 
	FF00-FFFF - 256 I/O ports



## Front Panel Specifications ##

On the front panel there are eight control switches, they have the following function:

| LOAD ADDR* | CONT* | EXAMINE* | DEPOSIT* |    | STEP* | SINGLE/CONT | RUN/PRGM(HALT) | RESET* |

    LOAD ADDR         - Loads the address currently on the address switches into the PC[1]
    CONT              - Continues to the next address, ie increments the program counter[2]
    EXAMINE           - Displays the contents of memory 
    DEPOSIT           - Writes the value on the data input switches into memory
    STEP              - Single step the clock
    SINGLE/CONTINUOUS - Switch between single or continuous mode[3]
    RUN/PRGM(HALT)    - Switch between run and program mode(halted clock)
    RESET             - Send the reset line through the whole processor + expansion board[4]
    
    * - denotes that the switches are spring loaded, so will return to a zero(switch down) when released.
    
    [1] - When the 'LOAD ADDR' switch is zero then the value of the switches is used to directly access memory. The address to be examined or deposited to does not have to be clocked into the program counter.
    [2] - This allows various functions, for example the examine switch could be set high and the CONT switch toggled, this would coninuously display values in memory in from the next address.
    [3] - Various clock speeds below the processors maximum speed can be selected from within the case using some DIP switches.
    [4] - The reset line is common throughout the processor, it is also sent to the expansion board to reset any devices that would be plugged into the expansion board.



## ISA - Instruction Set Architecture ##

## Notation ##

Titan uses S-expression-style assembly. Each assembly program is a list of instructions. Instead of the assembler operating on assembly code as a textual representation, it instead has a SYMBOLIC representation.

    why does this symbolic stuff make a difference!!!

Symbolic expressions make instructions into manipulable objects, that can be created, modified, stored, and printed. Assembly programs and the component instructions are first-class, and functions can both take them as arguments and produce them as output.

    Rs = Source register
    Rd = Destination register
    Rl = Low byte source register
    Rh = High byte source register
    SSSS = Source register in binary
    DDDD = Destination register in binary
    LLLL = Low byte source register in binary
    HHHH = High byte source register in binary
    ZZZZ = Source/Destination Address in hex

## Flags ##

    Z: Set if ALU operation stores a zero in the destination register.

    C: Set if ALU operation carries a 1 bit from an ADD function.[1]

    S: Set if ALU operation stores a number with the MSB set.

[1] - The carry flag is *always* set in any ALU operation, for operations which don't require two arguments the B input is zero.

## CPU CTRL ##

    Opcode   Cond
    -------  -------
    0 0 0 0  0 0 0 0  - (NOP) - Performs a No Operation
    0 0 0 0  0 0 0 1  - (HLT) - Stops the clock

## Arithmetic ##

    Opcode   Cond
    -------  -------
    0 0 0 1  0 0 0 0   -  (ADD Rs Rd) - Adds source and destination register
    0 0 0 1  0 0 0 1   -  (ADC Rs Rd) - Add source and destination register with carry in high
    0 0 0 1  0 0 1 0   -  (SUB Rs Rd) - Subtracts source and destination register
    0 0 0 1  0 0 1 1   -  (AND Rs Rd) - Logical AND of source and destination register
    0 0 0 1  0 1 0 0   -  (IOR Rs Rd) - Logical OR of source and destination register
    0 0 0 1  0 1 0 1   -  (XOR Rs Rd) - Logical XOR of source and destination register
    0 0 0 1  0 1 1 0   -  (NOT Rs) - Invert/Complement of source register
    0 0 0 1  0 1 1 1   -  (SHR Rs) - Shifts all bits right away from carry of source register(LSB fed into carry)
    0 0 0 1  1 0 0 0   -  (INC Rs) - Increments the source register
    0 0 0 1  1 0 0 1   -  (DEC Rs) - Decrements the source register

## Interrupt/Exception operations ##

These are generally used as system calls, the interrupt vector addresses is stored in the EEPROM on the external address bus.
All registers are saved in a location in system memory when an interrupt is called. The interrupt will also return with an interrupt code, and the address the interrupt was called at.

    Opcode   Cond
    -------  -------
    0 0 1 0  0 0 0 0   -  (INT #x5A) - Calls interrupt 5A
    0 0 1 0  0 0 0 1   -  (RTE) - Return from exception/interrupt

Where ZZZZ ZZZZ is the interrupt to call.

## Stack operations ##

    Opcode   Operand
    -------  -------
    0 1 1 1  S S S S  - (PSH Rs) - Pushes Rs onto the stack
    1 0 0 0  D D D D  - (POP Rd) - Pops the top of the stack into Rd

## Register operations ##

    Opcode   Cond
    -------  -------
    0 1 1 0  S S S S   -  (CLR Rs)    - Clears Rs
    1 0 0 1  0 0 0 0   -  (MOV Rs Rd) - Moves Rs into Rd

Second byte of MOV instruction is assembled into:

SSSS DDDD


## Jumps ##

Only JMI has indexed addressing.

    Opcode    I   Cond
    -------  ---  -----
    1 0 1 0   0   0 0 0   -  (JMP #xZZZZ)   - Direct jump to 0xZZZZ
    1 0 1 0   0   0 0 1   -  (JPZ #xZZZZ)   - Jump if zero flag set
    1 0 1 0   0   0 1 0   -  (JPS #xZZZZ)   - Jump if sign flag set
    1 0 1 0   0   0 1 1   -  (JPC #xZZZZ)   - Jump if carry flag set
    1 0 1 0   0   1 0 0   -  (JPI #xZZZZ)   - Indirect jump, point to a location in memory (0xZZZZ) and jumps to the value stored in the address (Big endian)
    1 0 1 0   0   1 0 1   -  (JSR #xZZZZ)   - Push return address onto stack, direct jump to 0xZZZZ
    1 0 1 0   0   1 1 0   -  (RTN)          - Returns to address thats stored on stack
    1 0 1 0   1   0 0 0   -  (JMI #xZZZZ)   - Where base address is 0xZZZZ and offset is in R1
    1 0 1 0   1   0 0 1   -  (JMI #(R1 R2)) - Where address to jump to is in R1(high byte) and R2(low byte) (can only be R1 & R2)

## Indexed Load/Store Memory ##

    Opcode    I     Dst
    -------   --   ------
    1 0 1 1   0    D D D    -  (LDI Rd #xZZZZ)   - Indexed load byte from memory, from address ZZZZ, offset in R1
    1 1 0 0   0    S S S    -  (STI Rs #xZZZZ)   - Indexed store byte to memory, from address ZZZZ, offset in R1	
    1 0 1 1   1    D D D    -  (LDI Rd #(R1 R2)) - Indexed load byte from memory, from address in R1(high byte) and R2(low byte)	
    1 1 0 0   1    S S S    -  (STI Rs #(R1 R2)) - Indexed store byte to memory, from address in R1(high byte) and R2(low byte)



## Load Constant ##

    Opcode   Cond
    -------  -------
    1 1 0 1  D D D D   - (LDC Rd #xZZ)


## Load/Store Memory ##

    Opcode     Dst
    -------   ------
    1 1 1 0   D D D D   -  (LDM Rs #xZZZZ) - Load byte from memory, from address ZZZZ to DDDD
    1 1 1 1   S S S S   -  (STM Rd #xZZZZ) - Store byte to memory, to address ZZZZ, byte from SSSS.


	

	
	
## ASSEMBLY CONVENTIONS ##

### Pseudo instructions ###

These pseudo instructions are built into the assembler, this makes code cleaner.

    (SHL Rs) - Simple ADD Rn,Rn - shifts all bits towards the carry bit, highest significant bit sent into carry
    (TST Rs) - XOR Rn,Rn - Tests if a register is zero or not.
    (JNZ #xZZZZ) - Jump if no zero flag set
    (JNS #xZZZZ) - Jump if no sign flag set
    (JNC #xZZZZ) - Jump if no carry flag set


### Assembly directives ###

Labels are used to write programs, you dont want to be dealing with straight addresses. It hurts. A lot!

    (.LABEL LOOP)
       (LDI R0 #x0000)   ; Fetch byte from set of byes in memory
       (TST R0)          ; Tests byte fetched
       (JPZ END)         ; If 0x00 then end of the set
       (INC R1)          ; Next address must be +1 from previous
       (JMP LOOP)        ; Time to get next byte
    (.LABEL END)
       (JMP END)         ; infinte loop

Above example shoves a label and a couple of instructions.


Below shows an ASCII string "BAR" that will be placed in memory at FOO, FOO is a label, beginning in memory at the first character of the string

    (.ASCII FOO "BAR")
    (.ASCIZ <label> "ZERO TERMINATED STRING, ADDS 0x00 AT END OF STRING")

Below is syntax for BYTE and WORD and DATA:

    (.RAW #xFF)
    (.BYTE <label> #xZZ)
    (.WORD <label> #xZZZZ)
    (.DATA <label> #xZZ #xZZ ... #xZZ)

Byte defines the label as a byte, this is used to map labels to interrupt codez, ie .BYTE END 0x05 ... INT END would call the interrupt 0x05. This is used to make software interrupts or get defined bytes into registers

Word defines the label as the address, this is used to map labels to addresses. This time, any referance to the label in the rest of the program will return the value of the word. ie (.WORD HUE 0xFE5A) Would return 0xFE5A in (JMP HUE)

Data will dump the list of data in order into memory, the label will return the address of the first item of the list of data.

Raw does the same as Data but there is no label mapped to the area where it its dumped into memory.

Below is the syntax for including another file containing assembly, this allows routines to be called from another file.

    (.INCL "filename")