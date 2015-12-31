;;; THIS ORIGINAL FILE WAS WRITTEN BY QUADRESCENCE
;;; https://github.com/tarballs_are_good
;;; https://bitbucket.org/tarballs_are_good
;;;
;;; Copyright (c) 2013 Robert Smith & Marc Cleave
;;; ???

(use extras)
(use (srfi 1))
(use (srfi 13))

(load "~/Code/Titan-Specifications/assembler/CPU-DEFINITIONS.scm")

(define nil '())

;;; errors out when something is not implemented
(define (not-implemented) (error "not implemented yet"))

(define assemble
  (lambda (program offset)
    (print-length (assembler program offset))
    (print-bytes (assembler program offset) offset 0)
    (newline)))

(define assemble-program
  (lambda (assembly machine-code)
    (if (null? assembly)
        machine-code
        (assemble-program (cdr assembly) (cons (assemble-instruction (first assembly))
                                               machine-code)))))

(define assemble-instruction
  (lambda (instr)
    (eval instr)))

;;; THE SLIGHTLY LESS DIRTY COULD ALMOST BE CONSIDERED CLEAN
(define (assembler prog offset)
  (let* ((prog-one (append-map desugar-directives-transformer prog))
         (prog-two (append-map desugar-pseudo-instruction-transformer prog-one))
         (prog-three (desugar-labels prog-two offset))
         (prog-four/env (alias-environment prog-three))
         (prog-four (first prog-four/env))
         (prog-five (map flatten prog-four))
         (env (append REGISTER-TABLE (second prog-four/env)))
         (prog-six (map (lambda (instr) (substitute-operands instr env)) prog-five)))
      ;   (prog-seven (flatten (reverse (assemble-program prog-six nil)))))
    prog-six))

;;; prints DA PROG
(define (print-bytes bytes addr n)
  (cond
   ((null? bytes) (newline))
   ((zero? (remainder n 4)) (newline) (print-word addr) (display ": ") (print-byte (car bytes)) (print-bytes (cdr bytes) (+ addr 4) (+ n 1)))
   (else (print-byte (car bytes)) (print-bytes (cdr bytes) addr (+ n 1)))))

(define (print-byte n)
  (display (string-upcase (if (> n #xF)
                              (sprintf "~X " n)
                              (sprintf "0~X " n)))))
(define (print-word n)
  (display (string-upcase (cond
                           ((<= n #xF) (sprintf "000~X " n))
                           ((<= n #xFF) (sprintf "00~X " n))
                           ((<= n #xFFF) (sprintf "0~X " n))
                           ((> n #xFFF) (sprintf "~X" n))))))

;;; prints length of program in bytes
(define (print-length bytes)
  (display "Length of program in bytes: ")
  (print (length bytes)))

;;; combines two nibbles to form a byte
(define combine-registers
  (lambda (high low)
    (bitwise-ior (arithmetic-shift high 4)
                 low)))

;;; creates two 8bit values from one number
(define (split-address addr)
  (list (arithmetic-shift addr -8)
        (bitwise-and #x00ff addr)))

(define (desugar-directives-transformer instr)
  (cond
   ((directive? instr) (desugar-directive instr))
   ((instruction? instr) (list instr))
   (else (error "INVALD TITAN ASM"))))

(define (desugar-directive directive)
  (case (car directive)
    ((.RAW .BYTE .WORD .LABEL) (list directive))
    ((.DATA) (list
              (list '.LABEL (cadr directive))
              (cons '.RAW (cddr directive))))
    ((.ASCII) (list
               (list '.LABEL (cadr directive))
               (cons '.RAW (map char->integer (string->list (caddr directive))))))
    ((.ASCIZ) (list
               (list '.LABEL (cadr directive))
               (append
                (cons '.RAW (map char->integer (string->list (caddr directive))))
                '(0))))
    (else (error "INVALID TITAN DIRECTIVE" (car directive)))))

(define (directive? instr)
  (and (pair? instr)
       (char=? #\. (string-ref (symbol->string (if (symbol? (car instr))
                                                   (car instr)
                                                   'NOTSYMBOL)) 0))))

(define (label? instr)
  (and (pair? instr)
       (eq? '.LABEL (car instr))))

(define (instruction? instr)
  (and (pair? instr)
       (not (directive? instr))))

(define (desugar-pseudo-instruction-transformer instr)
  (cond
   ((directive? instr) (list instr))
   ((instruction? instr) (desguar-pseudo-instruction instr))
   (else (error "INVALD TITAN ASM"))))

(define (desguar-pseudo-instruction instr)
  (case (car instr)
    (($CMP) (list (list 'NOP)))
    (else (list instr))))

(define (desugar-labels prog offset)
  (define (desugar prog resolved-prog len)
    (if (null? prog)
        (reverse resolved-prog)
        (let ((instr (car prog)))
          (if (label? instr)
              (desugar (cdr prog)
                       (cons
                        (list '.WORD (second instr) len)
                        resolved-prog)
                       len)
              (desugar (cdr prog)
                       (cons instr resolved-prog)
                       (+ len (compute-length instr)))))))
  ;; Desugar the labels of our program, starting with the length as
  ;; `offset'.
  (desugar prog nil offset))

(define (compute-length instr)
  (cond
   ((label? instr) 0)
   ((instruction? instr) (compute-instruction-length instr))
   ((directive? instr) (compute-directive-length instr))
   (else (error "INVALD TITAN ASM"))))

;;; computes the length of an instruction
(define compute-instruction-length
  (lambda (instr)
    (eval (list (first instr) #f))))

;;; computes the length of a directive
(define (compute-directive-length instr)
  (case (car instr)
    ((.RAW) (length (cdr instr)))
    ((.BYTE .WORD) 0)
    (else (begin (print instr)
                 (error "INVALID DIRECTIVE")))))

(define (alias-environment prog)
  (define (resolve prog resolved-prog env)
    (if (null? prog)
        (list (reverse resolved-prog) env)
        (let ((instr (car prog)))
          (cond
           ((directive? instr)
            (case (car instr)
              ;; We have a .BYTE or .WORD which define a
              ;; substitution. Add the substitution to our environment
              ;; and throw out the directive.
              ((.BYTE .WORD)
               (resolve (cdr prog)
                        resolved-prog
                        ;; NAME VALUE
                        (cons (cons (second instr) (third instr))
                              env)))
              ;; Directive doesn't have any alias bindings. Keep the
              ;; directive.
              (else (resolve (cdr prog)
                             (cons instr resolved-prog)
                             env))))
           ;; We have a normal instruction. Make substitutions if
           ;; necessary, and move on to the rest of the instructions.
           ((instruction? instr)
            (resolve (cdr prog)
                     (cons instr resolved-prog)
                     env))))))
  (resolve prog nil nil))

(define (substitute-operands instr env)
  (cons (car instr)
        (map (lambda (thing)
               (substitute-alias thing env))
             (cdr instr))))

(define (substitute-alias thing env)
  (cond
   ((not (symbol? thing)) thing)
   (else (env-lookup thing env))))

(define (register? s)
  (and (member s (map car REGISTER-TABLE)) #t))

(define (env-lookup name env)
  (if (null? env)
      (error "Couldn't resolve name" name)
      (let ((key-value (car env)))
        (if (eq? name (car key-value))
            ;; Return the value
            (cdr key-value)
            ;; Keep searching the environment.
            (env-lookup name (cdr env))))))



;;; ;;; ;;; ;;; ;;; ;;; ;;; ;;;


;;; gets program frome file
(define read-titan-file
  (lambda (filename)
    (call-with-input-file filename read)))

;;; opening files and things
(if (not (= (length (command-line-arguments)) 2))
    (print "Useage: assemble input-file address-offset")
    (assemble (read-titan-file (car (command-line-arguments)))
              (string->number (cadr (command-line-arguments)))))
