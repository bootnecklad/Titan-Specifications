;;; THIS ORIGINAL FILE WAS WRITTEN BY QUADRESCENCE
;;; https://github.com/tarballs_are_good
;;; https://bitbucket.org/tarballs_are_good
;;;
;;; Copyright (c) 2013 Robert Smith & Marc Cleave
;;; ???


;;;  first pass just counts how long every ins is and works out the address of variables and labels
;;;  second actually assembles the ins and uses the values it aquired from the first pass

(use srfi-13)
(define nil '())

;; Different components of a Titan program
(define (directive? instr)
  (and (pair? instr)
       (char=? #\. (string-ref (symbol->string (if (symbol? (car instr))
                                                 (car instr)
                                                 'NOTSYMBOL))  0))))

(define (label? instr)
  (and (pair? instr)
       (eq? '.LABEL (car instr))))

; (define (label? instr)
  ; (symbol? instr))

(define (instruction? instr)
  (and (pair? instr)
       (not (directive? instr))))

;; A way to extract parts of a list LST when F? is true.
(define (extract f? lst)
  (let loop ((remaining lst)
             (filtered nil))
    (if (null? remaining)
        (reverse filtered)
        (let ((item (car remaining)))
          (loop (cdr remaining)
                (if (f? item)
                    (cons item filtered)
                    filtered))))))

;; A way to extract components from a Titan program
(define (get-labels prog)
  (extract label? prog))

(define (get-instructions prog)
  (extract instruction? prog))

(define (get-directives prog)
  (extract directive? prog))

;;; defines the lengths of the different opcodes
(define opcode-lengths '( (NOP 1) (ADD 2) (ADC 2) (SUB 2) (AND 2) (LOR 2) (XOR 2) (NOT 2)
                          (SHR 2) (INC 2) (DEC 2) (INT 2) (RTE 1) (CLR 1) (PSH 1) (POP 1)
                          (MOV 2) (JMP 3) (JPZ 3) (JPS 3) (JPC 3) (JPI 3) (JSR 3) (RTN 1)
                          (JMI -1) (LDI -1) (STI -1) (LDC 2) (LDM 3) (STM 3)))

;;; defines the machine code values for different opcodes
(define opcodes '((NOP #x00) (ADD #x10) (ADC #x11) (SUB #x12) (AND #x13) (LOR #x14) (XOR #x14) (NOT #x16)
                  (SHR #x17) (INC #x18) (DEC #x19) (INT #x20) (RTE #x21) (CLR #x60) (PSH #x70) (POP #x80)
                  (MOV #x90) (JMP #xA0) (JPZ #xA1) (JPS #xA2) (JPC #xA3) (JPI #xA4) (JSR #xA5) (RTN #xA6)
                  (LDC #xD0) (LDM #xE0) (STM #xF0) (JMI -1) (LDI -1) (STI -1) (TST -1) (SHL -1)))


;;; defines the machine code values for different registers
(define registers '((R0 #x0) (R1 #x1) (R2 #x2) (R3 #x3) (R4 #x4) (R5 #x5) (R6 #x6) (R7 #x7)
                    (R8 #x8) (R9 #x9) (RA #xA) (RB #xB) (RC #xC) (RD #xD) (RE #xE) (RF #xF)))

;;; defines all the directives
(define directives '(.RAW .LABEL .BYTE .WORD .LABEL .DATA .ASCII .ASCIZ))


;;; gets the length of executable instruction (in bytes)
(define (instr-length instr)
  (if (member (car instr) (flatten opcode-lengths))
    (if (= -1 (cadr (member (car instr) (flatten opcode-lengths))))
      (compute-instruction-length instr)
      (cadr (member (car instr) (flatten opcode-lengths))))
    (begin (display (car instr)) (error "INVALID TITAN INSTRUCTION"))))

;;; gets length of instr, whether that be an instructions, label or directive

(define (compute-length instr)
  (cond
    ((label? instr) 0)
    ((instruction? instr) (instr-length instr))
    ((directive? instr) (compute-directive-length instr))
    (else (error "INVALD TITAN ASM"))))

;;; computes the lengths of special instructions
(define (compute-instruction-length instr)
  (if (contains-word? instr)
    2
    3))

;; tells us if an instruction contains an index word...
(define (contains-word? instr)
  (cond
    ((null? instr) #f)
    ((word? (car instr)) #t)
    (else (contains-word? (cdr instr)))))

;;; computes the length of a directive
(define (compute-directive-length instr)
  (case (car instr)
    ((.RAW) (length (cdr instr)))
    ((.BYTE .WORD .LABEL) 0)
    ((.DATA) (length (cddr instr)))
    ((.ASCII) (string-length (caddr instr)))
    ((.ASCIZ) (+ 1 (length (string->list (caddr instr)))))
    (else (error "INVALID DIRECTIVE"))))


;;; errors out when something is not implemented
(define (not-implemented) (error "not implemented yet"))

;;; quad
;;; loops through assembly program assigning lengths to instructions
(define (apply-lengths prog)
  (map compute-length prog))

;;; creats address list for program
(define (address-list prog)
  (cons 0 (running-total (apply-lengths prog) 0)))

;;; copies to a new list
(define (running-total lst sum)
  (if (null? lst)
    nil
    (cons (+ sum (car lst))
          (running-total (cdr lst) (+ sum (car lst))))))


;;; extracts high byte of index
(define (highbyte v)
  (vector-ref v 0))

;;; extracts low byte of index
(define (lowbyte v)
  (vector-ref v 1))

;;; tells us if an operand is an index, ie (Rh Rl)
(define (word? v)
  (vector? v))

;;; begins converting instructions into machine code values
(define (begin-convert prog)
  (if (null? prog)
    nil
    (cons (convert (car prog))
          (begin-convert (cdr prog)))))

;;; begins converting process
(define (convert instr)
  (cond
    ((label? instr) instr)
    ((instruction? instr) (convert-instr instr))
    ((directive? instr) (convert-directive instr))
    (else (error "INVALD TITAN ASSEMBLY"))))

;;; converts assembly instructions into machine code values
(define (convert-instr instr)
  (if (member (car instr) (flatten opcodes))
    (if (= -1 (cadr (member (car instr) (flatten opcodes))))
      (convert-special-instr instr)
      (cons (cadr (member (car instr) (flatten opcodes)))
            (cdr instr)))
    (begin (display instr) (error "INVALID TITAN INSTRUCTION"))))


;;; converts special instructions
(define (convert-special-instr instr)
  (if (contains-word? instr)
    (case (car instr)
      ((JMI) (cons #xA9 (vector->list (cadr instr))))
      ((LDI) (cons #xB8 (cons (cadr instr )(vector->list (caddr instr)))))
      ((STI) (cons #xC8 (cons (cadr instr )(vector->list (caddr instr))))))
    (case (car instr)
      ((JMI) (cons #xA8 (cdr instr)))
      ((LDI) (cons #xB0 (cdr instr)))
      ((STI) (cons #xC0 (cdr instr))))))


;;; converts directives into machine code form
(define (convert-directive instr)
  (begin ;(display instr)
  (case (car instr)
    ((.RAW) (cadr instr))
    ((.BYTE .WORD) instr)
    ((.DATA) (cddr instr))
    ((.LABEL) instr)
    ((.ASCII) (map char->integer (string->list (caddr instr))))
    ((.ASCIZ) (list (map char->integer (string->list (caddr instr))) 0))
    (else (error "INVALID TITAN DIRECTIVE")))))

;;; substitutes
(define (substitute prog label value)
  (map (lambda (element)
         (cond
           ((eq? label element) value)
           ((list? element) (substitute element label value))
           (else element)))
         prog))

(define (label-in-instr? label instr)
  (and (directive? instr)
       (eq? label (cadr instr))))

(define (get-position label prog pos)
  (cond
    ((null? prog) #f)
    ((label-in-instr? label (list-ref prog pos)) pos)
    (else (get-position label prog (+ 1 pos)))))

;;; gets the nth item in a list
(define (get-nth n lst)
  (if (>= n (length lst))
    nil
    (if (eq? n 0)
      (car lst)
      (get-nth (- n 1) (cdr lst) ))))

(define (extract-directives lst)
  (if (null? lst)
    nil
    (cons (cadar lst) (extract-directives (cdr lst)))))

(define (extract-addr lst prog offset)
  (if (null? lst)
    nil
    (cons (get-nth (get-position (car lst) prog 0) (add-offset offset (address-list prog)))
          (extract-addr (cdr lst) prog offset))))

;;; #;4> (map list '(1 2 3 4) '(5 6 7 8))
;;; ((1 5) (2 6) (3 7) (4 8))
(define (create-subs prog offset)
  (map list (extract-directives (get-directives prog))
            (extract-addr (extract-directives (get-directives prog)) prog offset)))

(define (substitute-all lst tbl)
  (if (null? tbl)
    lst
    (substitute-all (substitute lst (caar tbl) (cadar tbl)) (cdr tbl))))

;;; adds offset to address-list
(define (add-offset offset lst)
  (map (lambda (item) (+ item offset)) lst))

;;; combines two nibbles to form a byte
(define (combine-nibbles a b)
  (bitwise-ior (arithmetic-shift a 4) b))

;;; merges opcodes and operands
(define (merge orig-prog asm-prog)
  (if (null? orig-prog)
    nil
    (cons (do-merge (car orig-prog) (car asm-prog))
          (merge (cdr orig-prog) (cdr asm-prog)))))

;;; creates two 8bit values from one number
(define (split-address addr)
  (list (arithmetic-shift addr -8)
        (bitwise-and #x00ff addr)))

;;; removes directives from almost final program
(define (remove-directives prog)
  (if (null? prog)
    nil
    (cons (if (directive? (car prog))
            nil
            (car prog))
          (remove-directives (cdr prog)))))

;;; prints DA PROG
(define (print-bytes bytes n)
  (cond
    ((null? bytes) (newline))
    ((zero? (remainder n 16)) (newline) (print-byte (car bytes)) (print-bytes (cdr bytes) (+ n 1)))
    (else (print-byte (car bytes)) (print-bytes (cdr bytes) (+ n 1)))))

(define (print-byte n)
  (display (string-upcase (if (> n #xF)
                            (sprintf "~X " n)
                            (sprintf "0~X " n)))))


;;; prints length of program in bytes
(define (print-length bytes)
  (begin (display "Length of program in bytes: ")
         (print (length bytes))))

;;; this is the function that you actually call
(define (assemble prog offset)
  (begin (print-length (assembler prog offset))
         (print-bytes (assembler prog offset) 0)))

;;; THE BIG DIRTY
(define (assembler prog offset)
  (flatten (remove-directives (merge prog
                                    (substitute-all (substitute-all (begin-convert prog)
                                                                    (create-subs prog offset))
                                                    registers)))))

;;; does all the dirty work
(define (do-merge orig-instr instr)
  (begin ;(print orig-instr)
  (case (car orig-instr)
    ((ADD) (list (car instr) (combine-nibbles (cadr instr) (caddr instr))))
    ((ADC) (list (car instr) (combine-nibbles (cadr instr) (caddr instr))))
    ((SUB) (list (car instr) (combine-nibbles (cadr instr) (caddr instr))))
    ((AND) (list (car instr) (combine-nibbles (cadr instr) (caddr instr))))
    ((LOR) (list (car instr) (combine-nibbles (cadr instr) (caddr instr))))
    ((XOR) (list (car instr) (combine-nibbles (cadr instr) (caddr instr))))
    ((MOV) (list (car instr) (combine-nibbles (cadr instr) (caddr instr))))
    ((NOT) (list (car instr) (combine-nibbles (cadr instr) 0)))
    ((SHR) (list (car instr) (combine-nibbles (cadr instr) 0)))
    ((INC) (list (car instr) (combine-nibbles (cadr instr) 0)))
    ((DEC) (list (car instr) (combine-nibbles (cadr instr) 0)))
    ((CLR) (list (bitwise-ior (car instr) (cadr instr))))
    ((PSH) (list (bitwise-ior (car instr) (cadr instr))))
    ((POP) (list (bitwise-ior (car instr) (cadr instr))))
    ((JMI) (list (car instr) (if (= 3 (length instr))
                               (combine-nibbles (cadr instr) (caddr instr))
                               (split-address (cadr instr)))))
    ((LDI) (list (bitwise-ior (car instr) (cadr instr)) (if (= 4 (length instr))
                                                          (combine-nibbles (caddr instr) (cadddr instr))
                                                          (split-address (caddr instr)))))
    ((STI) (list (bitwise-ior (car instr) (cadr instr)) (if (= 4 (length instr))
                                                          (combine-nibbles (caddr instr) (cadddr instr))
                                                          (split-address (caddr instr)))))
    ((LDC) (list (bitwise-ior (car instr) (cadr instr)) (split-address (caddr instr))))
    ((LDM) (list (bitwise-ior (car instr) (cadr instr)) (split-address (caddr instr))))
    ((STM) (list (bitwise-ior (car instr) (cadr instr)) (split-address (caddr instr))))
    ((JMP) (list (car instr) (split-address (cadr instr))))
    ((JPZ) (list (car instr) (split-address (cadr instr))))
    ((JPS) (list (car instr) (split-address (cadr instr))))
    ((JPC) (list (car instr) (split-address (cadr instr))))
    ((JPI) (list (car instr) (split-address (cadr instr))))
    ((JSR) (list (car instr) (split-address (cadr instr))))
    (else instr))))

(define OPERATING-SYSTEM-CONSTANTS
'((.LABEL STRINGS)
  (.ASCIZ WELCOME-MESSAGE "WELCOME TO TITAN OPERATING SYSTEM")
  (.ASCIZ VERSION "TITAN-OS V1.0")
  (.ASCIZ DATE "123")

  ;;; define the addresses used by the monitor
  (.LABEL ADDRESSES)
    (.WORD SERIAL-PORT-0 #xFDFF)
    (.WORD SERIAL-PORT-1 #xFE00)
    (.WORD SERIAL-PORT-2 #xFE01)
    (.WORD INPUT-BUFFER #x8000)
    (.WORD RETURN-STACK-POINTER #x8400)
    (.WORD RETURN-STACK #x8402)

  (.LABEL COMMON-CHARS)
    (.BYTE RETURN #xFF)
    (.BYTE CHAR-NEWLINE #xFF)
    (.BYTE BACKSPACE #x08)))

(define prog-2
  '((.LABEL START)
      (NOP)
      (LDC R2 #x01)
      (JMI #(R1 R2))

    (.LABEL LOOP)
      (LDI R0 #(R1 R2))
      (LDI R0 STRING)
      (LOR R0 R0)
      (JPZ END)
      (ADD R2 R3)
      (STM R0 #xFDFE)
      (JMP LOOP)

    (.LABEL END)
      (JMP END)

    (.DATA LISP #x01 #x02 #x3)
    (.ASCII PROGE "HUE HUE HUE")
    (.ASCIZ STRING "HELLO WORLD")))

(define prog-1
  '((.LABEL HNG)
      (NOP)))

(define prog-0
  '((.LABEL START)
      (.RAW #x0 #x1 #x2)
	  (XOR R0 R1)
      (JMP LOOP)
      (LDI R1 LOOP)
      (LDI R1 #(R4 R5))
      (STI R1 LOOP)
      (STI R1 #(R4 R5))
      (JMI LOOP)
      (JMI #(R4 R5))
      (LDC R1 #xFF)
      (MOV R1 R2)
      (ADD R1 R2)
      (NOP)
      (CLR R1)
      (JMP START)
      (LDC R2 #x01)
      (LDM RF PROGE)

    (.LABEL LOOP)
      (JPZ END)
      (ADD R2 R3)
      (STM R0 SERIAL-PORT-0)
      (JMP LOOP)
      (.WORD QUAD #xBABE)

    (.LABEL END)
      (JMP END)
    (.WORD SERIAL-PORT-0 #xFDFF)
    (.ASCII PROGE "HUE HUE HUE")))


(define titan-prog
  '((.LABEL START)
      (NOP)
      (LDC R2 #x01)
      (JMI #(R1 R2))

    (.LABEL LOOP)
      (LDI R0 #(R1 R2))
      (LDI R0 STRING)
      (LOR R0 R0)
      (JPZ END)
      (ADD R2 R3)
      (STM R0 SERIAL-PORT-0)
      (JMP LOOP)

    (.LABEL END)
      (JMP END)

    (.BYTE HUE #xFF)
    (.WORD QUAD #xBABE)
    (.WORD SERIAL-PORT-0 #xFDFE)
    (.DATA LISP #x01 #x02 #x3)
    (.ASCII PROGE "HUE HUE HUE")
    (.ASCIZ STRING "HELLO WORLD")))

(define brainfuck

'((.LABEL BRAINFUCK)
  (.WORD CELLADDR #x0000) ; cells start at #x0000 and finish at #x7FFF
  (.WORD STARTADDR #x8000) ; address where commands start
  (.WORD SERIAL-PORT-0 #xFF00) ; address of serial port output

  (.LABEL INIT)
    (CLR R0)
    (CLR R1)
    (CLR R2)

  (.LABEL CLEAR-CELLS)
    (STI R0 #(R1 R2))  ; clearing the cells
    (JPS INCREMENT)   ; increments address to clear
    (JPS TESTZERO)    ; tests if 16 bit value is zero
    (JMP CLEAR-CELLS) ; continues clearing cells

  (.LABEL CLEAR-DONE)    ; program returns here if
    (POP R0)
    (POP R0)     ; gets rid of return address off of stack
    (JMP PROMPT) ; jumps to beginning prompt

;16bit increment routine
  (.LABEL INCREMENT)
    (INC R2)
    (JPC INC-CARRY)
    (RTN)
  (.LABEL INC-CARRY)
    (INC R1)
    (RTN)

;16bit decrement routine
  (.LABEL DECREMENT)
    (NOT R1)
    (NOT R2)
    (JPS INCREMENT)
    (NOT R1)
    (NOT R2)
    (RTN)

  (.LABEL TESTZERO)
    (LOR R2 R2)   ; tests low byte
    (JPZ LOR-CONT)
    (RTN)      ; 16bit value not zero
  (.LABEL LOR-CONT)
    (PSH R0)
    (LDC R2 #x80)
    (SUB R0 R2)
    (JPZ CLEAR-DONE) ; if jump occurs then all cells are clear
    (RTN)

  (.LABEL PROMPT)
    (LDC R0 #x0A)   ; ASCII value for LF (Line feed)
    (STM R0 SERIAL-PORT-0) ; Outputs to terminal
    (LDC R0 #x0D)   ; ASCII value for CR (Carriage RTNurn)
    (STM R0 SERIAL-PORT-0) ; Outputs to terminal
    (LDC R0 #x42)   ; ASCII value for '>'
    (STM R0 SERIAL-PORT-0) ; Outputs to terminal
    (LDC R1 #x80)           ; high byte of start address of commands
    (CLR R2)                ; low byte of start address of commands
    (JMP GETBRAINFUCK)   ; jumps to get input

  (.LABEL GETBRAINFUCK)
    (LDM R0 SERIAL-PORT-0)  ; Gets byte from input
    (STM R0 SERIAL-PORT-0)  ; Echos byte back
    (LOR R0 R0)                ; test to see if byte contains anything (if not  nothing was fetched)
    (JPZ GETBRAINFUCK)      ; try again
    (LDC R3 #x08)           ; ASCII value for BS (Backspace)
    (XOR R0 R3)             ; compares input against backspace value
    (JPZ BACKSPACE)         ; if input was backspace then character inputted needs to be removed
    (LDC R3 #x1B)           ; ASCII value for ESC (Escape)
    (XOR R0 R3)             ; Checks if input byte was an ESC
    (JPZ INIT)              ; If the byte was an ESC  start again
    (LDC R3 #x47)           ; ASCII value for 'G'
    (XOR R0 R3)
    (JPZ COMPILE)           ; if the byte was G  compile then execute
    (STI R0 #(R1 R2))       ; stores input to buffer
    (JPS INCREMENT)         ; increments buffer address
    (JMP GETBRAINFUCK)      ; get another byte
  (.LABEL BACKSPACE)
    (JPS DECREMENT)         ; moves buffer back one character
    (LDC R3 #x08)           ; ASCII value for BS (Backspace)
    (STM R3 SERIAL-PORT-0)  ; outputs backspace
    (PSH R3)                ; pushes (Backspace)
    (LDC R3 #x20)           ; ASCII value for Space
    (POP R3)                ; pops (Backspace)
    (STM R3 SERIAL-PORT-0)  ; outputs backspace again
    (JMP GETBRAINFUCK)      ; starts loop again

; this is where some magic happens omg!
; COMMAND  ASCII VALUE
;    +       #x2B
;            #x2C
;    -       #x2D
;    .       #x2E
;    <       #x3C
;    >       #x3E
;    [       #x5B
;    ]       #x5D
  (.LABEL COMPILE)
    (LDI R0 #(R1 R2))
    (LDC R3 #x2B) ; +
    (PSH R3)
    (XOR R0 R3)   ; compares input to + command
    (JPZ COMPILE-OUTPUT) ; will replace the as;dkfjas;kdf
    (POP R3)
    (LDC R3 #x2C) ;
    (PSH R3)
    (XOR R0 R3)
    (JPZ COMPILE-OUTPUT)
    (POP R3)
    (LDC R3 #x2D) ; -
    (PSH R3)
    (XOR R0 R3)
    (JPZ COMPILE-OUTPUT)
    (POP R3)
    (LDC R3 #x2E) ; .
    (PSH R3)
    (XOR R0 R3)
    (JPZ COMPILE-OUTPUT)
    (POP R3)
    (LDC R3 #x3C) ; >
    (PSH R3)
    (XOR R0 R3)
    (JPZ COMPILE-OUTPUT)
    (POP R3)
    (LDC R3 #x3E) ; <
    (PSH R3)
    (XOR R0 R3)
    (JPZ COMPILE-OUTPUT)
    (POP R3)
    (LDC R3 #x5B) ; [
    (PSH R3)
    (XOR R0 R3)
    (JPZ COMPILE-OUTPUT)
    (POP R3)
    (LDC R3 #x5D) ; ]
    (PSH R3)
    (XOR R0 R3)
    (JPZ COMPILE-OUTPUT)
    (POP R3)
    (LDC R3 #xFF); not a command so therefore STOP
    (STI R3 #(R1 R2)) ; stores STOP command
    (LDC R1 #x80) ; high byte of start address of commands
    (CLR R2)      ; low byte of start address of commands
    (JMP RUN) ; starts execution
  (.LABEL COMPILE-OUTPUT)
    (POP R3)
    (STI R3 #(R1 R2)) ; store command
    (JPS INCREMENT) ; increment
    (JMP COMPILE) ; compile next byte

  (.LABEL RUN)
    (LDI R0 #(R2 R3)) ; gets command to be executed
    (LDC R1 #x00) ; > command
    (XOR R0 R1) ; compares
    (JPZ INCPOINTER) ; executes increment pointer command
    (LDC R1 #x01) ; < command
    (XOR R0 R1) ; compares
    (JPZ DECPOINTER) ; executes decrement pointer command
    (LDC R1 #x02) ; + command
    (XOR R1 R1) ; compares
    (JPZ INCCELL) ; executes increment cell command
    (LDC R1 #x03) ; - command
    (XOR R0 R1) ; compares
    (JPZ DECCELL) ; executes decrement cell command
    (LDC R1 #x04) ; . command
    (XOR R1 R1) ; compares
    (JPZ OUTPUT) ; executes output command
    (LDC R1 #x05) ;   command
    (XOR R1 R1) ; compares
    (JPZ INPUT)  ; executes input command
    (LDC R1 #x06) ; [ command
    (XOR R0 R1) ; compares
    (JPZ JMPZERO) ; executes [ command
    (LDC R1 #x07) ; ] command
    (XOR R0 R1) ; compares
    (JPZ JMPBACK) ; executes ] command
    (JMP INIT) ; wasnt any of the above commands  therefore stop command

  (.LABEL INCINSTRUCTION)
    (INC R3)
    (JPC INS-CARRY)
    (JMP RUN)
  (.LABEL INS-CARRY)
    (INC R2)
    (JMP RUN)

  (.LABEL INCPOINTER)
    (INC R5)
    (JPC POINT-CARRY)
    (JMP INCINSTRUCTION)
  (.LABEL POINT-CARRY)
    (INC R4)
    (LDC R1 #x7F)
    (AND R1 R4) ; ensures that the datapointer stays 15 bits
    (JMP INCINSTRUCTION)

  (.LABEL DECPOINTER)
    (NOT R5)
    (INC R5)
    (JPZ DEC-CARRY)
    (NOT R5)
    (JMP INCINSTRUCTION)
  (.LABEL DEC-CARRY)
    (NOT R5)
    (NOT R4)
    (INC R4)
    (NOT R4)
    (LDC R1 #x7F)
    (AND R1 R4) ; ensures that the datapointer stays 15 bits
    (JMP INCINSTRUCTION)

  (.LABEL INCCELL)
    (LDI R0 #(R4 R5)) ; gets data currently in cell
    (INC R0)         ; increments the data
    (STI R0 #(R4 R5)) ; stores data back in cell
    (JMP INCINSTRUCTION)

  (.LABEL DECCELL)
    (LDI R0 #(R4 R5))
    (NOT R0)
    (INC R0)
    (NOT R0) ; decrements the data
    (STI R0 #(R4 R5)) ; stores data back in cell
    (JMP INCINSTRUCTION)

  (.LABEL INPUT)
    (LDM R0 SERIAL-PORT-0) ; gets input
    (STI R0 #(R4 R5)) ; stores input into cell
    (JMP INCINSTRUCTION)

  (.LABEL OUTPUT)
    (LDI R0 #(R4 R5)) ; gets data currently in cell
    (STM R0 SERIAL-PORT-0) ; outputs data to serial port
    (JMP INCINSTRUCTION)


; jump zero works by:
; get command
; if command is [ then push the current location onto the stack  goto beginning
; if command is ] then pop stack into temp
; compare current location with temp
; if equal then matching ] found  jump incinstruction
; if not equal then matching ] not found  so goto beginning
  (.LABEL JMPZERO)
    (PSH R5)
    (PSH R4) ; pushes current address onto stack
    (LDC R6 #x6) ; [ command
    (LDC R7 #x7) ; ] command
    (LDI R0 #(R4 R5)) ; gets data currently in cell
    (LOR R0 R0) ; tests if zero
    (JPZ MATCH) ; if data is zero then will need to find the matching ']'
    (POP R0)
    (POP R0) ; removes address from stack  not needed anymore
    (JMP INCINSTRUCTION) ; data was non-zero so carry on executing
  (.LABEL MATCH)
    (INC R3)
    (JPC MATCH-CARRY)
    (JMP MATCH-LOOP)
  (.LABEL MATCH-CARRY)
    (INC R2)
  (.LABEL MATCH-LOOP)
    (LDI R0 #(R2 R3)) ; gets another command
    (MOV R7 R1)
    (XOR R0 R1)  ; compares command to [ command
    (JPZ PUSH-MATCH) ; if command was [ then push current location
    (MOV R6 R1)
    (XOR R0 R1) ; compares command to ] command
    (JPZ POP-MATCH) ; if equal then pop and test location
    (JMP MATCH)   ; command was not [ or ] so loop back  start sequence again
  (.LABEL PUSH-MATCH)
    (PSH R3) ; low byte
    (PSH R2) ; high byte  pushes current location onto stack
    (JMP MATCH) ; start sequence again
  (.LABEL POP-MATCH)
    (POP R8) ; pops high byte
    (POP R9) ; pops low byte
    (XOR R5 R9) ; compares low byte
    (JPZ POP-CONT) ; if low byte equal  test high byte
    (JMP MATCH) ; if addresses not equal then matching ] not found  so start loop back
  (.LABEL POP-CONT)
    (XOR R4 R8) ; compares high byte
    (JPZ INCINSTRUCTION)
    (JMP MATCH) ; if addresses not equal then matching ] not found  so start loop back

; jump back is the opposite of jump zero
; it works BACKWARDS rather than forwards... :o
; i got lazy here and just added -B to the labels and changed the increment instruciton pointer to decrement
  (.LABEL JMPBACK)
    (PSH R5)
    (PSH R4) ; pushes current address onto stack
    (LDC R6 #x6) ; [ command
    (LDC R7 #x7) ; ] command
    (LDI R0 #(R4 R5)) ; gets data currently in cell
    (LOR R0 R0) ; tests if zero
    (JPZ MATCH-B) ; if data is zero then will need to find the matching '['
    (POP R0)
    (POP R0) ; removes address from stack  not needed anymore
    (JMP INCINSTRUCTION) ; data was non-zero so carry on executing
  (.LABEL MATCH-B)
    (NOT R3)
    (INC R3)
    (JPC MATCH-CARRY-B)
    (NOT R3)
    (JMP MATCH-LOOP-B)
  (.LABEL MATCH-CARRY-B)
    (NOT R3)
    (NOT R2)
    (INC R2)
    (NOT R2)
  (.LABEL MATCH-LOOP-B)
    (LDI R0 #(R2 R3)) ; gets another command
    (MOV R6 R1)
    (XOR R0 R1)  ; compares command to ] command
    (JPZ PUSH-MATCH-B) ; if command was ] then push current location
    (MOV R7 R1)
    (XOR R0 R1) ; compares command to [ command
    (JPZ POP-MATCH-B) ; if equal then pop and test location
    (JMP MATCH-B)   ; command was not [ or ] so loop back  start sequence again
  (.LABEL PUSH-MATCH-B)
    (PSH R3) ; low byte
    (PSH R2) ; high byte  pushes current location onto stack
    (JMP MATCH-B) ; start sequence again
  (.LABEL POP-MATCH-B)
    (POP R8) ; pops high byte
    (POP R9) ; pops low byte
    (XOR R5 R9) ; compares low byte
    (JPZ POP-CONT-B) ; if low byte equal  test high byte
    (JMP MATCH-B) ; if addresses not equal then matching ] not found  so start loop back
  (.LABEL POP-CONT-B)
    (XOR R4 R8) ; compares high byte
    (JPZ INCINSTRUCTION)
    (JMP MATCH-B))) ; if addresses not equal then matching ] not found  so start loop back


(define OPERATING-SYSTEM
`(,@OPERATING-SYSTEM-CONSTANTS

  (.LABEL PROMPT)
    ;;; output > prompt

  (.LABEL PARSE-INPUT)
    (NOP)

  ;;; Loads bytes from serial port to input buffer in memory
  (.LABEL GET-INPUT)
    (CLR R1)               ; Clear input buffer offset
    (LDM R0 SERIAL-PORT-0) ; Loads byte from serial port
    (LOR R0 R0)            ; Tests if byte is zero, (zero = no char present)
    (JPZ GET-INPUT)        ; If zero then go back and try again
    (STI R0 INPUT-BUFFER)  ; As the byte was valid input, store it to buffer
    (INC R1)               ; Increment input buffer offset
  (.LABEL CHECK-FOR-BACKSPACE)
    (LDC R2 #x08)          ; ASCII value for BS (Backspace)
    (XOR R0 R2)            ; compares input against backspace value
    (JPZ BACKSPACE)        ; if input was backspace then character inputted needs to be removed
  (.LABEL CHECK-FOR-ESCAPE)
    (LDC R2 #x1B)          ; ASCII value for ESC (Escape)
    (XOR R0 R2)            ; Checks if input byte was an ESC
    (JPZ PROMPT)           ; If the byte was an ESC  start again
  (.LABEL CHECK-FOR-RETURN)
    (LDC R2 RETURN)        ; Loads ASCII value for return char
    (XOR R0 R2)            ; Compares value, result is zero if equal
    (JPZ RETURN-HANDLER)   ; If value zero then all input is fetched
    (JMP GET-INPUT)        ; Value was not a return, so fetch more input
  (.LABEL RETURN-HANDLER)
    (STI R2 INPUT-BUFFER)  ; Store 0 for zero-terminated string
    (JMP PARSE-INPUT)      ; Begin parsing input
  (.LABEL BACKSPACE-HANDLER)
    (DEC R1)               ; moves buffer back one character
    (LDC R2 #x08)          ; ASCII value for BS (Backspace)
    (STM R2 SERIAL-PORT-0) ; outputs backspace
    (PSH R2)               ; pushes (Backspace)
    (LDC R2 #x20)          ; ASCII value for Space
    (POP R2)               ; pops (Backspace)
    (STM R3 SERIAL-PORT-0) ; outputs backspace again
    (JMP GET-INPUT)        ; starts loop again


  ;;; Returns the length of string in R0
  ;;; Pointer to string in #(R2 R3)
  (.LABEL STRING-LENGTH)
    (CLR R0)                   ; clears length counter
    (LDI R1 #(R2 R3))          ; loads first char of string
    (LOR R1 R1)                ; tests if zero terminater
    (JPZ STRING-LENGTH-RETURN) ; if zero (ie end of string) return length
    (INC R0)                   ; increment the length counter
    (JMP STRING-LENGTH)        ; loop back
  (.LABEL STRING-LENGTH-RETURN)
    (RTN)                      ; return from subroutine, leaving R0 with length

  ;;; Compares values in R0 & R1
  ;;; Returns 00 if unequal, FF if equal
  (.LABEL COMPARE)
    (XOR R0 R1)         ; compares two values
   (JPZ COMPARE-ZERO)   ; if zero, then values were equal
    (CLR R0)
    (RTN)               ; return from subroutine leaving zero(false) in R0
  (.LABEL COMPARE-ZERO)
    (CLR R0)
    (NOT R0)
    (RTN)               ; return from subroutine leaving not zero in R0

  ;;; Compares two strings
  ;;; string pointers in #(R2 R3)
  ;;;                    #(R4 R5)
  ;;; 00 in R0 if unequal
  ;;; FF if equal
  (.LABEL STRING-COMPARE)
    (PSH R3)
    (PSH R2)            ; saves value of first pointer
    (JPS STRING-LENGTH) ; routine that returns length of string
    (MOV R0 R6)         ; saves length in R6
    (MOV R4 R2)
    (MOV R5 R3)         ; moves value of second pointer
    (JPS STRING-LENGTH) ; routine that returns length of string
    (MOV R6 R1)         ; moves length of second string
    (POP R2)
    (POP R3)
    (JPS COMPARE)       ; routine that compares two lengths
    (NOT R0)
    (JPZ STRING-COMPARE-LOOP) ; if lengths equal then begin comparing chars
    (CLR R0)
    (RTN)               ; lengths inequal so return false (strings not the same)
  (.LABEL STRING-COMPARE-LOOP)
    (LDI R6 #(R2 R3))   ; loads char of first string
    (LDI R7 #(R4 R5))   ; loads char of second string
    (LOR R6 R6)         ; checks for zero terminator (end of string)
    (JPZ STRING-COMPARE-EQUAL) ; if end of string, return true
    (XOR R6 R7)         ; not zero terminator, so compare chars
    (JPZ STRING-CHAR-COMPARE-CONTINUE) ; if equal then increment pointers
    (CLR R0)
    (RTN)               ; chars not equal so return false
  (.LABEL STRING-CHAR-COMPARE-CONTINUE)
    (PSH R3)
    (PSH R2)            ; saves pointer to string
    (JPS INCREMENT-ADDRESS) ; increments pointer
    (POP R2)
    (POP R3)            ; puts incremented pointer back
    (PSH R5)
    (PSH R4)            ; saves pointer to string
    (JPS INCREMENT-ADDRESS) ; increments pointer
    (POP R4)
    (POP R5)            ; puts incremented pointer back
    (JMP STRING-COMPARE-LOOP) ; loops back to compare next char
  (.LABEL STRING-COMPARE-EQUAL)
    (CLR R0)
    (NOT R0)
    (RTN)               ; lengths are equal so return true


  ;;; sub routine to increment 16 bit value
  ;;; value stored on stack #(H L)
  ;;; R8 & R9 are temp store for return address
  (.LABEL INCREMENT-ADDRESS)
    (POP R8)
    (POP R9)   ; saves return address
    (POP R0)
    (POP R1)   ; gets value to increment off stack
    (INC R1)   ; increments lower byte
    (JPC INC-ADDR-CARRY) ; check for carry
    (PSH R1)
    (PSH R0)   ; no carry so no fix, push incremented value on stack
    (PSH R9)
    (PSH R8)   ; push return address back on stack
    (RTN)      ; return
  (.LABEL INC-ADDR-CARRY)
    (INC R0)   ; increment higher byte to account for carry
    (PSH R1)
    (PSH R0)   ; push incremented value on stack
    (PSH R9)
    (PSH R8)   ; push return address back on stack
    (RTN)))    ; return