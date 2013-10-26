;;; THIS ORIGINAL FILE WAS WRITTEN BY QUADRESCENCE
;;; https://github.com/tarballs_are_good
;;; https://bitbucket.org/tarballs_are_good
;;;
;;; Copyright (c) 2013 Robert Smith & Marc Cleave
;;; ???

(define nil '())

;; Different components of a Titan program
(define (directive? instr)
  (and (pair? instr)
       (char=? #\. (string-ref (symbol->string (car instr))
                               0))))

(define (label? instr)
  (symbol? instr))

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

;; An example Titan program
(define titan-prog
  '(START
    (LDC R2 #X01)
    (CLR R1)

    LOOP
    (LDI R0 STRING)
    (TST R0)
    (JPZ END)
    (ADD R2 R3)
    (STM R0 SERIAL_PORT_0)
    (JMP LOOP)

    END
    (JMP END)

    (.ASCIZ STRING "HELLO WORLD")
    (.WORD SERIAL_PORT_0 #XFDFF)))