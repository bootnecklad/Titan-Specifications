;;; Test programs in machine code to rest implementation of instructions

(define nil '())

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
      ;(HLT)
      ))

(define (test-jmi-reg cpu)
  (poke-values cpu 0
	       #b00000000
	       #b10101001
	       #b00000001)
  (poke-values cpu #xFF
	       #b00000000
	       #b00000001))

(define (test-ldi cpu)
  (poke-values cpu 0
	       #b10110011
	       #b00000000
	       #b11111111
	       #b00000001)
  (poke-values cpu #x100
	       #xFF))

(define (test-ldi-reg cpu)
  (poke-values cpu 0
	       #b10111011
	       #b00000001
	       #b00000001)
  (poke-values cpu #xFF
	       #x55))

(define (test-sti cpu)
  (poke-values cpu 0
	       #b11000000
	       #b00000000
	       #b11111111
	       #b00000001
	       #b00000001))

(define (test-sti-reg cpu)
  (poke-values cpu 0
	       #b11001000
	       #b00010010
	       #b00000001))

(define (test-ldm cpu)
  (poke-values cpu 0
	       #b11100000
	       #b00000000
	       #b11111111
	       #b00000001)
  (poke-values cpu #xFF
	       #xAA))

(define (test-stm cpu)
  (poke-values cpu 0
	       #b11110000
	       #b00000000
	       #b11111111
	       #b00000001))

(define (test-ldc cpu)
  (poke-values cpu 0
	       #b11010000
	       #b10101010
	       #b00000001))
