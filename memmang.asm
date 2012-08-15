; LISP FUNCTIONS FOR TITAN?! MADNESS!
;
;
; Structure of allocated cell in memory:
;
; TAG BYTE
; HIGH BYTE
; LOW BYTE
; HIGH BYTE
; LOW BYTE
;
; Tag bit information for cells:
;
; X Y AAA BBB
;
; X - Dead or alive, 0=dead, 1=alive
; Y - No use yet!
; AAA - Data type of first 16bit value
; BBB - Data type of second 16bit value
;
; Types of data:
; 000 - NIL
; 001 - Data
; 010 - Pointer
; 011 - Function
; 100 - 



; Allocate
; Data and data type are stored on the stack
; Pointer to element is returned on the stack

ALLOCATE:
   POP R5
   POP R6
   POP R7         ; puts data type and data into registers
   LDM R1,0x03FF   ; high byte of next free element
   PSH R1
   LDM R2,0x0400   ; low byte of next free element
   PSH R2
   STI 
   LDC R0,0x80    ; bit setting for allocated element
   LOR R0,R5
   STI R5,[R1,R2]    ; sets element as allocated
   JPS INCREMENT
   STI R6,[R1,R2]   ; stores high byte of data
   JPS INCREMENT
   STI R7,[R1,R2]   ; stores low byte of data
   CLR R0
   STM R0,0x3FF
   STM R0,0x3FF
   RTE


; Unallocate
; Sets ellement to unallocated
; Pointer of element to be cleared stored on stack
; New free element address also updated

UNALLOCATE:
   POP RA
   POP RB
   CLR R0
   STI R0,[RA,RB]   ; sets element as unallocated
   STM RA,0x3FF     ; stores address of new empty element to next free element
   STM RB,0x400
   RTE

   
;16bit increment routine
INCREMENT:
   INC R2
   JPC INC_CARRY
   RET
INC_CARRY:
   INC R1
   RET

;16bit decrement routine
DECREMENT:
   NOT R1
   NOT R2
   JPS INCREMENT
   NOT R1
   NOT R2
   RET

; Setzero
; Sets all new elements to zero

SETZERO:
   CLR R0
   LDC R1,0x09   ; address to start at(high byte)
   CLR R2        ; address to start at(low byte)
   LDC R3,0x04   ; finish address(high byte)
   LDC R4,0x00   ; finish address(low byte)
LOOP:
   STI R0,[R1,R2]  ; clears byte in memory
   JPS DECREMENT   ; decrements the address
   PSH R3
   XOR R1,R3       ; compares current address to finish address
   JPZ LOOP_NEXT
LOOP_CONT:
   POP R3
   JMP LOOP
LOOP_NEXT:
   PSH R4
   XOR R2,R4
   JPZ LOOP_END
   POP R4
   JMP LOOP
LOOP_END:
   RTE


; cons, cons, cons
; stack contents before: (CAR, CDR): datatype, databyte(high), databyte(low), datatype, databyte(high), databyte(low)
; pointer to element stored on stack

CONS:
   POP R9
   POP RA
   POP RB         ; puts data type and data into registers
   LDM R1,0x3FF   ; high byte of next free element
   LDM R2,0x400   ; low byte of next free element
   SHL R9
   SHL R9
   SHL R9         ; shifts first data type left three times to move into correct position
   LDC R0,0x80    ; bit setting for allocated element
   LOR R0,R9
   POP R0         ; second data type
   LOR R0,R9      ; information for element to be allocated finished
   STI R9,[R1,R2] ; stores information to element
   JPS INCREMENT
   STI RA,[R1,R2] ; stores first byte of first data to element
   JPS INCREMENT
   STI RB,[R1,R2] ; stores second byte of first data to element
   POP RA
   POP RB
   STI RA,[R1,R2] ; stores first byte of second data to element
   JPS INCREMENT
   STI RB,[R1,R2] ; stores second byte of second data to element
   STM R0,0x3FF
   STM R0,0x3FF
   RTE	


; car
; pointer to list stored on stack: pointer(high), pointer(low)
; returned on stack: datatype, databyte(high), databyte(low)

CAR:
   POP R1
   POP R2   ; the address of the first element in the list
   LDI R9,[R1,R2]   ; datatype of data stored in the tag of the first element
   LDC R0,0x38      ; bit configuration to extract datatype
   AND R0,R9        ; removes unwanted bits
   SHR R9
   SHR R9
   SHR R9   ; datatype now in R9
   JPS INCREMENT
   LDI RA,[R1,R2]   ; high byte of data
   JPS INCREMENT
   LDI RB,[R1,R2]   ; low byte of data
   PSH RB
   PSH RA
   PSH R9   ; returns the first element in the list with datatype
   RTE


; cdr
; pointer to list stored on stack: pointer(high), pointer(low)
; pointer to cdr of list returned on stack: pointer(high), pointer(low)

CDR:
   POP R1
   POP R2   ; the address of the first element in the list
   LDC R0,0x03  ; offset of pointer
   ADD R0,R2    ; adds offset to low byte
   JPC CDR_CARRY ; will need to increment the high byte of pointer if carry detected
CDR_CONT:
   LDI RA,[R1,R2]   ; high byte of pointer
   JPS INCREMENT
   LDI RB,[R1,R2]   ; low byte of pointer
   PSH RB
   PSH RA  ; returns the pointer to rest of list on stack
   RTE
CDR_CARRY:
   INC R1        ; accounts for overflow
   JMP CDR_CONT  ; returns


; continuously scans all cells for dead cells and sets high and low bytes of next free element(cell)
; 
; total of 4k address space of cells, cells are 3 bytes long, allows for 1,365 possible cells.	
; first cells tag bit is at:

.WORD FirstCellAddress 0x0401

.WORD HIGH_BYTE_FREE_ELEMENT 0x03FF
.WORD LOW_BYTE_FREE_ELEMENT 0x0400

INT ScanCells:

CellCheck:
   LDM R1 ,HighByteFreeElement  ; loads high byte of address of (possible) next free element
   LDM R2 ,LowByteFreeElement   ; loads low byte of adress of (possible) next free element
   LDI R0 [R1 , R2]             ; loads the tag information of current (possible) next free element
   LDC R3 ,0x80                 ; mask to AND to get the DEAD/ALIVE bit
   AND R3,R0                    ; BLACK MAGIC!
   TST R0                       ; tests if the DEAD/ALIVE bit is set
   JPZ CellIsDead               ; if cell is dead, nothing needs to be done
   JMP FindDeadCellSetup        ; if cell is alive, a dead cell needs to be found to replace the address
CellIsDead:
   RTN                          ; Nothing needs to happen! Return to whatever was happening
FindDeadCellSetup:
   LDC R4 ,0x05      ; 
   LDC R5 ,0x55      ; total number of cells in hex
   LDC R1 ,0x04      ; loads high byte of first cell
   LDC R2 ,0x01      ; loads low byte of first cell
FindDeadCell:
   LDI R0 [R1 , R2]  ; loads the tag information of current (possible) next free element
   LDC R3 ,0x80      ; mask to AND to get the DEAD/ALIVE bit
   AND R3,R0         ; BLACK MAGIC!
   TST R0            ; tests if the DEAD/ALIVE bit is set
   JPZ DeadCellFound ; if cell is dead, need to update the next free cell address
   JPS DecrementCellCount ; decrements the number of cells to be searched
   JPZ ENDOFTHEWORLD ; shit, if this occurs there are no more free cells to allocate! QUAD, WE'VE RUN OUT OF CELLS, UR LISP IS DEAD!
   JPS NextCell      ; increment the current address pointing to cells (ie advanced to next cell address)
   JMP FindDeadCell  ; if cell is alive, a dead cell needs to be found to replace the address, ie loop back!
DeadCellFound:
   STM R1 ,HighByteFreeCell
   STM R2 ,LowByteFreeCell
   RTN ; finish ScanCells routine as next free cell has been updated
; 16bit offset addition
NextCell:
   LDC R0 ,0x03  ; cells are 3 bytes long
   ADD R0,R1     ; adds offset to point to next cell tab
   JPC HighAddrIncrement
   RET
HighAddrIncrement:
   INC R1
   RET
; 16bit decrement
; dirty cheating hack - ill look into it later
DecrementCellCount:
   NOT R4
   NOT R5
   INC R5
   JPC INC_CARRY
   NOT R4
   NOT R5
   RET
INC_CARRY:
   INC R4
   NOT R4
   NOT R5
   RET

; ill do it later
; I've done it! :)