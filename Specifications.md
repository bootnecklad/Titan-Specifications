# Titan - Specifications #

## System Specifications ##

Currently, Titan has the following specifications:

    8 bit data bus
    16 8 bit registers, R0 -> RF
    16 bit data stack pointer(64k data stack) (Mapped to RD)
    16 bit return stack pointer(64k return stack) (Mapped to RE)
    16 bit program counter (Mapped to RF)
	64k addressable memory
    Capable of 10 8bit arithmetic functions
    Various addressing modes(Immediate, Indirect, Index, Offset)
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

Second byte of operations that take two registers as arguments is assembled into:

    S S S S  D D D D

Second byte of operation that take only one register as an argument is assembled into:

    S S S S  D D D D



## Interrupt/Exception operations ##

These are generally used as system calls, the interrupt vector addresses is stored in the EEPROM on the external address bus.
All registers are saved in a location in system memory when an interrupt is called. The interrupt will also return with an interrupt code, and the address the interrupt was called at.

    Opcode   Cond
    -------  -------
    0 0 1 0  0 0 0 0   -  (INT #xZZ) - Calls interrupt ZZ
    0 0 1 0  0 0 0 1   -  (RTE) - Return from exception/interrupt

Where ZZZZ ZZZZ is the interrupt to call.



## Stack operations ##

### Data stack ###

Used for storage of data during program runtime.

    Opcode   Operand
    -------  -------
    0 0 1 1  S S S S  - (PSH Rs) - Pushes Rs onto the data stack
    0 1 0 0  D D D D  - (POP Rd) - Pops the top of the data stack into Rd
    0 1 0 1  D D D D  - (PEK Rd) - Peeks the top of data stack into Rd

### Return stack ###

Return addresses are pushed onto the stack when Jump Subroutine instruction called. Modifificaiton is risky, could corrupt return address.

    Opcode   Operand
    -------  -------
    0 1 1 0  S S S S  - (PSH Rs) - Pushes Rs onto the data stack
    0 1 1 1  D D D D  - (POP Rd) - Pops the top of the data stack into Rd
    1 0 0 0  D D D D  - (PEK Rd) - Peeks the top of data stack into Rd

## Register operations ##

    Opcode   Cond
    -------  -------
    1 0 0 1  S S S S   -  (CLR Rs)      - Clears Rs
    1 0 1 0  0 0 0 0   -  (MOV Rs Rd)   - Moves Rs into Rd
    1 0 1 1  D D D D   -  (LDC #xZZ Rd) - Loads #xZZ into Rd


Second byte of MOV instruction is assembled into:

    S S S S  D D D D

Second byte of LDC instrucitno is assembled into:

    Z Z Z Z  Z Z Z Z



## Jumps ##

    Opcode   Cond
    -------  -------
    1 0 1 0  0 0 0 0  -  (JMP #xZZZZ)      - Jump to address #xZZZZ
    1 0 1 0  0 0 0 1  -  (JMP (#xZZZZ))    - Jump to the address in #xZZZZ
    1 0 1 0  0 0 1 0  -  (JMP Rs)          - Jump to the address in Rs
    1 0 1 0  0 0 1 1  -  (JMP (Rs))        - Jump to the address at the address in Rs
    1 0 1 0  0 1 0 0  -  (JMP + Rs)        - Jump to the address in Rn, then increment Rs
    1 0 1 0  0 1 0 1  -  (JMP (+ Rs))      - Jump to the address at the address in Rs, then increment Rs
    1 0 1 0  0 1 1 0  -  (JMP Rs #xZZZZ)   - Jump to Rs + #xZZZZ
    1 0 1 0  0 1 1 1  -  (JMP (Rs #xZZZZ)) - Jump to the address at Rs + #xZZZZ
    1 0 1 0  1 0 0 0  -  (JPZ #xZZZZ)      - Jump to address #xZZZZ if zero flag set
    1 0 1 0  1 0 0 1  -  (JNC #xZZZZ)      - Jump to address #xZZZZ if zero flag not set
    1 0 1 0  1 0 1 0  -  (JPS #xZZZZ)      - Jump to address #xZZZZ if sign flag set
    1 0 1 0  1 0 1 1  -  (JNS #xZZZZ)      - Jump to address #xZZZZ if sign flag not set
    1 0 1 0  1 1 0 0  -  (JPC #xZZZZ)      - Jump to address #xZZZZ if carry flag set
    1 0 1 0  1 1 0 1  -  (JNC #xZZZZ)      - Jump to address #xZZZZ if carry flag not set
    1 0 0 1  0 0 0 0  -  (JPS #xZZZZ)      - Push return address onto return stack and jump to address #xZZZZ
    1 0 1 0  0 0 0 0  -  (RET)             - POP return address of return stack into PC to return from subroutine

Operations that take a register as an argiment has second byte assembled as:

    S S S S  0 0 0 0

Addresses are split when assembled and stored in big endian after the instruciton or regiter source:

    H H H H  H H H H
    L L L L  L L L L



## Load/Store Memory ##

### Load from memory ###

    Opcode   Cond
    -------  -------
    1 0 1 1  0 0 0 0  -  (LDM #xZZZZ Rd)      - Load the conents of #xZZZZ into Rd
    1 0 1 1  0 0 0 1  -  (LDM (#xZZZZ) Rd)    - Load the contents of the address at #xZZZZ into Rd
    1 0 1 1  0 0 1 0  -  (LDM Rs Rd)          - Load the contents of the address in Rs into Rd
    1 0 1 1  0 0 1 1  -  (LDM (Rs) Rd)        - Load the contents of the address at the address in Rs into Rd
    1 0 1 1  0 1 0 0  -  (LDM + Rs Rd)        - Load the contents of the address in Rs into Rd, then increment Rs
    1 0 1 1  0 1 0 1  -  (LDM (+ Rs) Rd)      - Load the contents of the address at the address in Rs into Rd, then increment Rs
    1 0 1 1  0 1 1 0  -  (LDM Rs #xZZZZ Rd)   - Load the contents of the Rs + #xZZZZ into Rd
    1 0 1 1  0 1 1 1  -  (LDM (Rs #xZZZZ) Rd) - Load the contents of the address at the address Rs + #xZZZZ into Rd



### Store to memory ###

    Opcode   Cond
    -------  -------
    1 1 0 0  0 0 0 0  -  (STM Rs #xZZZZ)      - Store Rs to #xZZZZ
    1 1 0 0  0 0 0 1  -  (STM Rs (#xZZZZ))    - Store Rs to the address at #xZZZZ
    1 1 0 0  0 0 1 0  -  (STM Rs Rx)          - Store Rs to the address in Rx
    1 1 0 0  0 0 1 1  -  (STM Rs (Rx))        - Store Rs to the address at the address in Rx
    1 1 0 0  0 1 0 0  -  (STM Rs + Rx)        - Store Rs to the address in Rx, then increment Rx
    1 1 0 0  0 1 0 1  -  (STM Rs (+ Rx))      - Store Rs to the address at the address in Rx, then increment Rx
    1 1 0 0  0 1 1 0  -  (STM Rs Rx #xZZZZ)   - Store Rs to the address Rx + #xZZZZ
    1 1 0 0  0 1 1 1  -  (STM Rs (Rx #xZZZZ)) - Store Rs to the address at the address Rx + #xZZZZ

Operations that take on register as source or destination has second byte assembled as either depnding on source/destination:

    0 0 0 0  D D D D
    S S S S  0 0 0 0

Operations that take register source and destination has second byte assembled as:

    S S S S  D D D D

Operations that take two source registers has second byte assembled as:

    S S S S  D D D D



## Unused instruction space so far ##

Got any suggestions?

    Opcode   Cond
    -------  -------
    1 1 0 1  0 0 0 0
    1 1 1 0  0 0 0 0
    1 1 1 1  0 0 0 0



## ASSEMBLY CONVENTIONS ##

All instructions that have more than one operand generally has data travel from LEFT to RIGHT. Eg:

    (MOV Rs Rd)     - Moves Rs to Rd
    (STM Rs #xZZZZ) - Stores Rs to the address #xZZZZ

So an instructino OPR with SOURCE and DESTINATION as arguments follows the rule:

    (OPR SOURCE DESTINATION)



### Pseudo instructions ###

These pseudo instructions are built into the assembler, this makes code cleaner because it allows for more complex operations to be written. Pseudo instructions begin with a $

    ($TST Rs)               - XOR Rn,Rn - Tests if a register is zero or not.
    ($CMP Rx Rx)            - Performs a (SUB Rx Rx) but restores the registers, so effectively only sets flags.
    ($TRA #xSRC #xDST)      - Transfer byte of memory at address #xSRC to address #xDST
    ($BTR #xZZ #xSRC #xDST) - Block transfer of #xZZ number of bytes from #xSRC to #xDST
    ($PSA)                  - Push all registers onto return stack, apart from PC + RP
    ($POA)                  - Pop all registers from return stack, apart from PC + RP19


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


Below shows an ASCII string "BAR" that will be placed in memory at FOO, FOO is a label, beginning in memory at the first character of the string. Within the assembler .ASCII is translated to .LABEL and then .RAW. .ASCIZ is translated to .LABEL and .RAW with #x00 terminating the string.

    (.ASCII FOO "BAR")
    (.ASCIZ <label> "ZERO TERMINATED STRING, ADDS 0x00 AT END OF STRING")

Below is syntax for BYTE and WORD and DATA:

    (.RAW #xFF ...)
    (.BYTE <label> #xZZ)
    (.WORD <label> #xZZZZ)
    (.DATA <label> #xZZ #xZZ ... #xZZ)

Byte defines the label as a byte, this is used to map labels to interrupt codez, ie .BYTE END 0x05 ... INT END would call the interrupt 0x05. This is used to make software interrupts or get defined bytes into registers

Word defines the label as the address, this is used to map labels to addresses. This time, any referance to the label in the rest of the program will return the value of the word. ie (.WORD HUE 0xFE5A) Would return 0xFE5A in (JMP HUE)

Data will dump the list of data in order into memory, the label will return the address of the first item of the list of data. This is translated into .LABEL and .RAW within the assembler.

Raw does the same as Data but there is no label mapped to the area where it its dumped into memory.

Below is the syntax for including another file containing assembly, this allows routines to be called from another file.

    (.INCL "filename")