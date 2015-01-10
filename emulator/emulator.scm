;;; Titan emulator
;;;
;;; A, B, X, Y REGISTERS16 registers
;;; 16 bit PROGRAM COUNTER
;;; ZERO SIGN CARRY   ALU STATES
;;; 64k x 8bit MEMORY

(define nil '())
(use srfi-13)
(use srfi-69)
(use numbers)

;;;;;;;;
;;;
;;; UTILITIES
;;;
;;;;;;;;

(define (extract-lower-nibble value)
  (bitwise-and value #b00001111))

(define (extract-upper-nibble value)
  (arithmetic-shift (bitwise-and value #b11110000) -4))

(define (extract-lower-byte value)
  (bitwise-and value #b0000000011111111))

(define (extract-upper-byte value)
  (arithmetic-shift (bitwise-and value #b1111111100000000) -8))

(define (make-pc-value cpu)
  (bitwise-ior (arithmetic-shift (read-register cpu #xE) 8)
	       (read-register cpu #xF)))

(define (write-pc-value cpu value)
  (write-register! cpu #xE (extract-upper-byte value))
  (write-register! cpu #xF (extract-lower-byte value)))

(define (make-sp-value cpu)
  (bitwise-ior (arithmetic-shift (read-register cpu #xC) 8)
	       (read-register cpu #xD)))

(define (write-sp-value cpu value)
  (write-register! cpu #xC (extract-upper-byte value))
  (write-register! cpu #xD (extract-lower-byte value)))


(define (write-register-long! cpu register value)
  (case register
    ((PROGRAM-COUNTER) (write-pc-value cpu value))
    ((STACK-POINTER) (write-sp-value cpu value))))

(define (make-register-long cpu register)
  (case register
    ((PROGRAM-COUNTER) (make-pc-value cpu))
    ((STACK-POINTER) (make-sp-value cpu))))

(define (sign-bit? cpu register)
  (bit-set? (read-register cpu register) 7))

(define (LSB? cpu register)
  (bit-set? (read-register cpu register) 0))

(define (dec->hex n)
  (string-upcase (if (> n #xF)
		     (sprintf "~X " n)
		     (sprintf "0~X " n))))


;;;;;;;;
;;;
;;; PROCESSOR DEFINITIONS
;;;
;;;;;;;;

(define address-bus-size 16)
(define stack-pointer-size 16)
(define data-bus-size 8)
(define number-of-registers 4)

;;; defines the processor
(define-record cpu
  memory
  stack
  registers
  conditions)

;;;
(define (new-cpu)
  (make-cpu (make-vector (expt 2 address-bus-size) 0)
	    (make-vector (expt 2 stack-pointer-size) 0)
	    (make-vector 16 0)
	    (make-vector 3 #f)))

;;; reads particular address in memory
(define (read-memory cpu address)
  (vector-ref (cpu-memory cpu) address))

;;; writes word in memory
(define (write-memory! cpu address word)
  (vector-set! (cpu-memory cpu) address word))


;;; quad wrote this can u tell?
(define (poke-values cpu starting-address . bytes)
  (letrec ((write-bytes (lambda (address bytes)
                          (if (null? bytes)
                              (void)
                              (begin
                                (write-memory! cpu address (car bytes))
                                (write-bytes (+ address 1) (cdr bytes)))))))
    (write-bytes starting-address bytes)))


;;; REGISTER-ONE REGISTER-TWO ... REGISTER-F ... PROGRAM-COUNTER
(define (read-register-hue cpu register)
  (if (eq? 'PROGRAM-COUNTER register)
      (make-pc-value cpu)
      (vector-ref (cpu-registers cpu) register)))

(define (read-register cpu register)
  (if (symbol? register)
      (make-register-long cpu register)
      (vector-ref (cpu-registers cpu) register)))

;;; writes value to register
(define (write-register-hue! cpu register value)
  (if (eq? 'PROGRAM-COUNTER register)
      (write-pc-value cpu value)
      (vector-set! (cpu-registers cpu) register value)))

(define (write-regiter! cpu register value)
  (if (symbol? register)
	(make-register-long cpu register)
	(vector-set! (cpu-registers cpu) register value)))
	

;;; pushes register onto stack
;(define (push-register cpu register)
;  (vector-set! (cpu-stack cpu) (

;;; returns value of program counter
(define (pc cpu)
  (read-register cpu 'PROGRAM-COUNTER))

;;; return value in memory using the program counter as the address
(define (fetch-memory cpu)
  (read-memory cpu (pc cpu)))

;;; returns the state of one of conditional states
(define (condition? cpu condition)
  (case condition
    ((ZERO) (vector-ref (cpu-conditions cpu) 0))
    ((SIGN) (vector-ref (cpu-conditions cpu) 1))
    ((CARRY) (vector-ref (cpu-conditions cpu) 2))))

;;; sets the state of one of the conditional states
(define (condition-set! cpu condition state)
  (case condition
    ((ZERO) (vector-set! (cpu-conditions cpu) 0 state))
    ((SIGN) (vector-set! (cpu-conditions cpu) 1 state))
    ((CARRY) (vector-set! (cpu-conditions cpu)2 state))))

(define (make-conditional-jump-instruction condition)
  (lambda (cpu)
    (increment-PROGRAM-COUNTER cpu)
    (if (condition? condition)
	(write-register! cpu 'PROGRAM-COUNTER
			 (+ (arithmetic-shift (read-memory cpu (pc cpu)) 8)
			    (read-memory cpu (add1 (pc cpu)))))
	(begin
	  (increment-PROGRAM-COUNTER cpu)
	  (increment-PROGRAM-COUNTER cpu)))
    (controller cpu)))


;;; QUAD WROTE THIS
(define (make-arithmetic-instruction operator)
  (lambda (cpu)
    (increment-PROGRAM-COUNTER cpu)
    (let* ((register (fetch-memory cpu))
	   (source-register (extract-upper-nibble register))
	   (destination-register (extract-lower-nibble register)))
      (write-register! cpu
       destination-register
       (operator
	(read-register cpu source-register)
	(read-register cpu destination-register))))
    (set-condition-states cpu)
    (increment-PROGRAM-COUNTER cpu)
    (controller cpu)))

(define opcode-table
  (make-hash-table))

(define (lookup-opcode opcode)
  (hash-table-ref opcode-table opcode))

(define (install-opcode opcode action)
  (hash-table-set! opcode-table opcode action))

(define (install-opcodes)
  (install-opcode #b00000000 INSTRUCTION-nop)
  (install-opcode #b00000001 INSTRUCTION-hlt)
  (install-opcode #b00010000 (make-arithmetic-instruction +))
  (install-opcode #b00010001 (make-arithmetic-instruction (compose add1 +)))
  (install-opcode #b00010010 (make-arithmetic-instruction -))
  (install-opcode #b00010011 (make-arithmetic-instruction bitwise-and))
  (install-opcode #b00010100 (make-arithmetic-instruction bitwise-ior))
  (install-opcode #b00010101 (make-arithmetic-instruction bitwise-xor))
  (install-opcode #b00010110 INSTRUCTION-not)
  (install-opcode #b00010111 INSTRUCTION-shr)
  (install-opcode #b00011000 INSTRUCTION-inc)
  (install-opcode #b00011001 INSTRUCTION-dec)
  (install-opcode #b01100000 INSTRUCTION-clr)
  (install-opcode #b10010000 INSTRUCTION-mov)
  (install-opcode #b10100000 INSTRUCTION-jmp)
  (install-opcode #b10100001 (make-conditional-jump-instruction 'ZERO))
  (install-opcode #b10100010 (make-conditional-jump-instruction 'SIGN))
  (install-opcode #b10100011 (make-conditional-jump-instruction 'CARRY)))

(define (controller cpu)
  (let* ((address (pc cpu))
         (opcode (read-memory cpu address))
         (action (lookup-opcode opcode)))
    (action cpu)))

(define (set-condition-states cpu)
  (if (< 255 (read-register cpu (extract-lower-nibble (fetch-memory cpu))))
      (begin
	(condition-set! cpu 'CARRY #t)
	(write-register! cpu
	 (extract-lower-nibble (fetch-memory cpu))
	 (bitwise-and (read-register cpu (extract-lower-nibble (fetch-memory cpu))) #b11111111))))
  (if (sign-bit? cpu (read-register cpu (extract-lower-nibble (fetch-memory cpu))))
      (condition-set! cpu 'SIGN #t))
  (if (zero? (read-register cpu (extract-lower-nibble (fetch-memory cpu))))
      (condition-set! cpu 'ZERO #t)))
  
(define (print-registers-pretty cpu)
  (print-registers-pretty-func cpu (vector->list (cpu-registers cpu)) 0))

(define (print-registers-pretty-func cpu lst n)
  (if (null? lst)
      (begin (print "STACK-POINTER: " (dec->hex (make-sp-value cpu)))
	     (print "PROGRAM-COUNTER: " (dec->hex (make-pc-value cpu))))
      (begin (print "REGISTER-" (dec->hex n) ": " (dec->hex (car lst)))
	     (print-registers-pretty-func cpu (cdr lst) (add1 n)))))


(define (increment-PROGRAM-COUNTER cpu)
  (write-register! cpu 'PROGRAM-COUNTER (add1 (pc cpu))))

;;;;;;;;
;;;
;;; INSTRUCTION DEFINITIONS
;;;
;;;;;;;;

(define (INSTRUCTION-hlt cpu)
  (print-registers-pretty cpu))

(define (INSTRUCTION-nop cpu)
  (increment-PROGRAM-COUNTER cpu)
  (controller cpu))

(define (INSTRUCTION-add cpu)
  (increment-PROGRAM-COUNTER cpu)
  (write-register! cpu
   (extract-lower-nibble (fetch-memory cpu))
   (+ (read-register cpu (extract-lower-nibble (fetch-memory cpu)))
      (read-register cpu (extract-upper-nibble (fetch-memory cpu)))))
  (set-condition-states cpu)
  (increment-PROGRAM-COUNTER cpu)
  (controller cpu))

(define (INSTRUCTION-mov cpu)
  (increment-PROGRAM-COUNTER cpu)
  (write-register! cpu 
   (extract-lower-nibble (fetch-memory cpu))
   (read-register cpu (extract-upper-nibble (fetch-memory cpu))))
  (increment-PROGRAM-COUNTER cpu)
  (controller cpu))

 (define (INSTRUCTION-jmp cpu)
   (increment-PROGRAM-COUNTER cpu)
   (write-register! cpu 'PROGRAM-COUNTER
		   (+ (arithmetic-shift (fetch-memory cpu) 8)
		      (read-memory cpu (add1 (pc cpu)))))
   (controller cpu))

(define (INSTRUCTION-not cpu)
  (increment-PROGRAM-COUNTER cpu)
  (write-register! cpu
   (extract-upper-nibble (fetch-memory cpu))
   (bitwise-not (read-register cpu (extract-upper-nibble (fetch-memory cpu)))))
  (set-condition-states cpu)
  (increment-PROGRAM-COUNTER cpu)
  (controller cpu))

(define (INSTRUCTION-shr cpu)
  (increment-PROGRAM-COUNTER cpu)
  (if (LSB? cpu (read-register cpu (extract-upper-nibble (fetch-memory cpu))))
      (condition-set! cpu 'CARRY #t))
  (write-register! cpu
   (extract-upper-nibble (fetch-memory cpu))
   (arithmetic-shift (read-register cpu (extract-upper-nibble (fetch-memory cpu))) -1))
  (if (sign-bit? cpu (extract-upper-nibble (fetch-memory cpu)))
      (condition-set! cpu 'SIGN #t))
  (if (zero? (read-register cpu (extract-upper-nibble (fetch-memory cpu))))
      (condition-set! cpu 'ZERO #t))
  (increment-PROGRAM-COUNTER cpu)
  (controller cpu))

(define (INSTRUCTION-inc cpu)
  (increment-PROGRAM-COUNTER cpu)
  (write-register! cpu
   (extract-upper-nibble (fetch-memory cpu))
   (add1 (read-register cpu (extract-upper-nibble (fetch-memory cpu)))))
  (if (< 255 (read-register cpu (extract-upper-nibble (fetch-memory cpu))))
      (begin
	(condition-set! cpu 'CARRY #t)
	(write-register! cpu
	 (extract-upper-nibble (fetch-memory cpu))
	 (bitwise-and (read-register cpu (extract-upper-nibble (fetch-memory cpu))) #b11111111))))
  (if (sign-bit? cpu (extract-upper-nibble (fetch-memory cpu)))
      (condition-set! cpu 'SIGN #t))
  (if (zero? (read-register cpu (extract-upper-nibble (fetch-memory cpu))))
      (condition-set! cpu 'ZERO #t))
  (increment-PROGRAM-COUNTER cpu)
  (controller cpu))

(define (INSTRUCTION-dec cpu)
  (increment-PROGRAM-COUNTER cpu)
  (write-register! cpu
   (extract-upper-nibble (fetch-memory cpu))
   (- (read-register cpu (extract-upper-nibble (fetch-memory cpu))) 1))
  (if (< 255 (read-register cpu (extract-upper-nibble (fetch-memory cpu))))
      (begin
	(condition-set! cpu 'CARRY #t)
	(write-register! cpu
	 (extract-upper-nibble (fetch-memory cpu))
	 (bitwise-and (read-register cpu (extract-upper-nibble (fetch-memory cpu))) #b11111111))))
  (if (sign-bit? cpu (extract-upper-nibble (fetch-memory cpu)))
      (condition-set! cpu 'SIGN #t))
  (if (zero? (read-register cpu (extract-upper-nibble (fetch-memory cpu))))
      (condition-set! cpu 'ZERO #t))
  (increment-PROGRAM-COUNTER cpu)
  (controller cpu))

(define (INSTRUCTION-clr cpu)
   (write-register! cpu (extract-lower-nibble (fetch-memory cpu)) 0)
		    (increment-PROGRAM-COUNTER cpu)
		    (controller cpu))




;;;;;;;;;;;;;;;;;;;
;;;
;;; CONVENIENCE
;;;
;;;;;;;;;;;;;;;;;;;

(define titan (new-cpu))

(define (clr-pc cpu)
  (write-register! cpu 'PROGRAM-COUNTER 0))

(define (load-test-prog cpu)
  (poke-values cpu 0 
	       #b00000000
	       #b00000000
	       #b00000000
	       #b10010000
	       #b00000001
	       #b00000000
	       #b00000000
	       #b00010000
	       #b00000001
	       #b00000000
	       #b10100000
	       #b11110000
	       #b00000000)
  (poke-values cpu #b1111000000000000
	       #b10010000
	       #b00010010
	       #b00000000
	       #b00000001)
  (write-register! titan 0 1))


(define TEST-PROGRAM
  '((.LABEL ADDRESSES)
       (.WORD TEST-BRANCH #xF000)

    (NOP)
    (NOP)
    (NOP)
    (MOV R0 R1)
    (NOP)
    (NOP)
    (ADD R0 R1)
    (NOP)
    (JMP TEST-BRANCH)
    (NOP)

    (.LABEL TEST-BRANCH)
      (MOV R1 R2)
      (NOP)
      (HLT)))
