;;; THIS ORIGINAL FILE WAS WRITTEN BY QUADRESCENCE
;;; THEN BNL POLISHED IT OFF. ;)
;;; https://github.com/tarballs_are_good
;;; https://bitbucket.org/tarballs_are_good
;;;
;;; Copyright (c) 2013 Robert Smith & Marc Cleave
;;; ???

(use extras)
(use srfi-1)
(use srfi-13)
(load "~/Code/Titan-Specifications/assembler/CPU-DEFINITIONS.scm")
(load "~/Code/Titan-Specifications/assembler/pseudo-instructions.scm")

(define nil '())

;; Errors out when something is not implemented
(define not-implemented
  (lambda ()
    (error "not implemented yet")))

;; Gets program frome file
(define read-titan-file
  (lambda (filename)
    (call-with-input-file filename read)))




;; === Different components of a Titan program ===

;; Checks if an instruction is a directive
(define directive?
  (lambda (instr)
    (and (pair? instr)
         (char=? #\. (string-ref (symbol->string (if (symbol? (car instr))
                                                      (car instr)
                                                      'NOTSYMBOL))  0)))))

;; Checks if an instruction is a label
(define label?
  (lambda (instr)
    (and (pair? instr)
         (eq? '.LABEL (car instr)))))

;; Checks if an instruction is an instruction
(define instruction?
  (lambda (instr)
    (and (pair? instr)
         (not (directive? instr)))))

;; Checks if argument is a register
(define (register? s)
  (and (member s (map car registers)) #t))

;; Checks if an operand is an index, ie (Rh Rl)
(define word-index?
  (lambda (operand)
    (and (list? operand)
         (register? (first operand))
         (register? (second operand)))))

;; A way to extract parts of a list LST when F? is true.
(define extract
  (lambda (f? lst)
    (let loop ((remaining lst)
               (filtered nil))
      (if (null? remaining)
          (reverse filtered)
          (let ((item (car remaining)))
            (loop (cdr remaining)
                  (if (f? item)
                      (cons item filtered)
                      filtered)))))))

;; === A way to extract components from a Titan program ===

;; extracts labels from program
(define get-labels
  (lambda (prog)
    (extract label? prog)))

;; Extracts instructions from program
(define get-instructions
  (lambda (prog)
    (extract instruction? prog)))

;; Extracts directives from program
(define get-directives
  (lambda (prog)
    (extract directive? prog)))

;; Extracts opcode from an instruction
(define opcode
  (lambda (instr)
    (car instr)))

;; Extracts operands from an instruction
(define operands
  (lambda (instr)
    (cdr instr)))




;; Gets length of instr, whether that be an instructions, label or directive
(define compute-length
  (lambda (instr)
    (cond
     ((label? instr) 0)
     ((instruction? instr) (instr-length instr))
     ((directive? instr) (compute-directive-length instr))
     (else (error "INVALD TITAN ASM"
                  instr)))))

;; Gets the length of executable instruction (in bytes)
(define instr-length
  (lambda (instr)
    (let ((instruction-length (member (car instr) (flatten opcode-lengths))))
      (if instruction-length
          (cadr instruction-length)
          (error "INVALID TITAN INSTRUCTION"
                 instr)))))

;; Computes the length of a directive
(define compute-directive-length
  (lambda (instr)
    (case (car instr)
      ((.RAW) (length (cdr instr)))
      ((.BYTE .WORD .LABEL) 0)
      ((.DATA) (length (cddr instr)))
      ((.ASCII) (string-length (caddr instr)))
      ((.ASCIZ) (+ 1 (string-length (caddr instr))))
      (else (error "INVALID DIRECTIVE"
                   instr)))))

;; Loops through assembly program assigning lengths to instructions
(define apply-lengths
  (lambda (prog)
    (map compute-length prog)))

;; Creates address list for program
(define address-list
  (lambda (prog)
    (cons 0 (running-total (apply-lengths prog) 0))))

;; Copies to a new list
(define running-total
  (lambda (lst sum)
    (if (null? lst)
        nil
        (cons (+ sum (car lst))
              (running-total (cdr lst) (+ sum (car lst)))))))

;; Begins conversion of assembly to binary
(define convert
  (lambda (instr)
    (cond
     ((instruction? instr) (convert-instr instr))
     ((directive? instr) (cdr instr))
     (else (error "INVALID TITAN INSTRUCTION"
                  instr)))))

;; Converts assembly instructions into machine code values
(define convert-instr
  (lambda (instr)
    (if (member (opcode instr) (flatten opcodes))
        (cons (cadr (member (opcode instr) (flatten opcodes)))
              (cdr instr))
        (error "INVALID TITAN INSTRUCTION"
               instr))))

;; Substitutes everything in the program&table
(define substitute-all
  (lambda (lst tbl)
    (if (null? tbl)
        lst
        (substitute-all (substitute lst (caar tbl) (cadar tbl)) (cdr tbl)))))

;; Does the dirty work for substituting
(define substitute
  (lambda (prog label value)
    (map (lambda (element)
           (cond
            ((eq? label element) value)
            ((list? element) (substitute element label value))
            (else element)))
         prog)))

;; Adds offset to address-list
(define add-offset
  (lambda (offset lst)
    (map (lambda (item) (+ item offset)) lst)))

;; Combines two nibbles to form a byte
(define combine-nibbles
  (lambda (a b)
    (bitwise-ior (arithmetic-shift a 4)
                 b)))

;; Creates two 8bit values from (should be) 16bit number
(define split-address
  (lambda (addr)
    (if (>= addr 65536)
        (error "INVALD TITAN ADDRESS"
               addr)
        (list (arithmetic-shift addr -8)
              (bitwise-and #x00ff addr)))))

;; 'Desugars' aka breaks down directives into simplest form
(define desugar-directive
  (lambda (directive)
    (case (car directive)
      ((.RAW .BYTE .WORD .LABEL) (list directive))
      ((.DATA) (list
                (list '.LABEL (cadr directive))
                (cons '.RAW (cddr directive))))
      ((.ASCII) (list
                 (list '.LABEL (cadr directive))
                 (cons '.RAW (map char->integer (string->list (caddr directive))))))
      ((.ASCIZ)  (list
                  (list '.LABEL (cadr directive))
                  (append
                   (cons '.RAW (map char->integer (string->list (caddr directive))))
                   '(0))))
      (else (error "INVALID TITAN DIRECTIVE"
                   (car directive))))))


(define desugar-directives-transformer
  (lambda (instr)
    (cond
     ((directive? instr) (desugar-directive instr))
     ((instruction? instr) (list instr))
     (else (error "INVALID TITAN INSTRUCTION"
                  instr)))))

(define (desugar-pseudo-instruction-transformer instr)
  (cond
   ((directive? instr) (list instr))
   ((instruction? instr) (desguar-pseudo-instruction instr))
   (else (error "INVALD TITAN ASM"))))

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

(define (env-lookup name env)
  (if (null? env)
      (error "Couldn't resolve name" name)
      (let ((key-value (car env)))
        (if (eq? name (car key-value))
            ;; Return the value
            (cdr key-value)
            ;; Keep searching the environment.
            (env-lookup name (cdr env))))))

;; Substitutes instruction for thing built up from environment
(define (substitute-instruction instr env)
  (cons (car instr)
        (map (lambda (thing)
               (substitute-alias thing env))
             (cdr instr))))

(define (substitute-alias thing env)
  (cond
   ((not (symbol? thing)) thing)
   ((register? thing) thing)
   (else (env-lookup thing env))))
  
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
                        ;;          NAME           VALUE
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

;; Merges opcodes and operands
(define (merge prog)
  (if (null? prog)
      nil
      (cons (do-merge (car prog))
            (merge (cdr prog)))))

;; Does all the dirty work for merge
(define (do-merge instr)
  (case (car instr)
    ((ADD) (assemble-RSRD instr))
    ((ADD-CARRY) (assemble-RSRD instr))
    ((SUBTRACT) (assemble-RSRD instr))
    ((AND) (assemble-RSRD instr))
    ((IOR) (assemble-RSRD instr))
    ((XOR) (assemble-RSRD instr))
    ((MOVE) (assemble-RSRD instr))
    ((NOT) (assemble-RS instr))
    ((SHIFT-RIGHT) (assemble-RS instr))
    ((INCREMENT) (assemble-RS instr))
    ((DECREMENT) (assemble-RS instr))
    ((CLEAR) (assemble-RS instr))
    ((PUSH-DATA) (assemble-RS instr))
    ((POP-DATA) (assemble-RS instr))
    ((PEEK-DATA) (assemble-RS instr))
    ((PUSH-RETURN) (assemble-RS instr))
    ((POP-RETURN) (assemble-RS instr))
    ((PEEK-RETURN) (assemble-RS instr))
    ((LOAD-CONSTANT) (assemble-LDC instr))
    ((JUMP) (assemble-JUMP-DIRECT instr))
    ((JUMP-INDIRECT)  (assemble-JUMP-INDIRECT instr))
    ((JUMP-REGISTER)  (assemble-JUMP-REGISTER instr))
    ((JUMP-INDIRECT-REGISTER)  (assemble-JUMP-INDIRECT-REGISTER instr))
    ((JUMP-AUTOINCREMENT)  (assemble-JUMP-AUTOINCREMENT instr))
    ((JUMP-INDIRECT-AUTOINCREMENT)  (assemble-JUMP-INDIRECT-AUTOINCREMENT instr))
    ((JUMP-OFFSET)  (assemble-JUMP-OFFSET instr))
    ((JUMP-INDIRECT-OFFSET)  (assemble-JUMP-INDIRECT-OFFSET instr))
    ((JUMP-IF-ZERO)  (assemble-JUMP-IF-ZERO instr))
    ((JUMP-IF-SIGN)  (assemble-JUMP-IF-SIGN instr))
    ((JUMP-IF-CARRY)  (assemble-JUMP-IF-CARRY instr))
    ((JUMP-SUBROUTINE)  (assemble-JUMP-SUBROUTINE instr))
    ((RETURN-SUBROUTINE)  (assemble-RETURN-SUBROUTINE instr))
    ((LOAD)  (assemble-LOAD instr))
    ((LOAD-INDIRET)  (assemble-LOAD-INDIRET instr))
    ((LOAD-REGISTER)  (assemble-LOAD-REGISTER instr))
    ((LOAD-REGISTER-INDIRECT)  (assemble-LOAD-REGISTER-INDIRECT instr))
    ((LOAD-REGISTER-AUTOINCREMENT)  (assemble-LOAD-REGISTER-AUTOINCREMENT instr))
    ((LOAD-REGISTER-INDIRECT-AUTOINCREMENT)  (assemble-LOAD-REGISTER-INDIRECT-AUTOINCREMENT instr))
    ((LOAD-OFFSET)  (assemble-LOAD-OFFSET instr))
    ((LOAD-INDIRECT-OFFSET)  (assemble-LOAD-INDIRECT-OFFSET instr))
    ((STORE)  (assemble-STORE instr))
    ((STORE-INDIRET)  (assemble-STORE-INDIRET instr))
    ((STORE-REGISTER)  (assemble-STORE-REGISTER instr))
    ((STORE-REGISTER-INDIRECT)  (assemble-STORE-REGISTER-INDIRECT instr))
    ((STORE-REGISTER-AUTOINCREMENT)  (assemble-STORE-REGISTER-AUTOINCREMENT instr))
    ((STORE-REGISTER-INDIRECT-AUTOINCREMENT) (assemble-STORE-REGISTER-INDIRECT-AUTOINCREMENT instr))
    ((STORE-OFFSET)  (assemble-STORE-OFFSET instr))
    ((STORE-INDIRECT-OFFSET) (assemble-STORE-INDIRECT-OFFSET instr))
    (else instr)))

;; Prints DA PROG in nice human readable format
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

;; Prints length of program in bytes
(define (print-length bytes)
  (display "Length of program in bytes: ")
  (print (length bytes)))

;; Function to call to assemble a program & print.
(define assemble
  (lambda (prog offset)
    (print-length (assembler prog offset))
    (print-bytes (assembler prog offset) offset 0)
    (display "\n")))

;;; THE SLIGHTLY LESS DIRTY COULD ALMOST BE CONSIDERED CLEAN
(define assembler
  (lambda (prog offset)
    (let*
        ; breaks down directives into simplest form
        ((prog-one (append-map desugar-directives-transformer prog))

         ; turns psuedo instructions into actual titan instructions
         (prog-two (append-map desugar-pseudo-instruction-transformer prog-one))
         
         ; 
         (prog-three (desugar-labels prog-two offset))

         ; Why is this even a thing, flatten is BAD?
         (prog-four (map flatten prog-three))

         ; BLACK MAGIC
         (prog-five/env (alias-environment prog-four))
         (prog-five (first prog-five/env))
         (env (second prog-five/env))

         ; Substitutes things built up in environment
         (prog-six (map (lambda (instr) (substitute-instruction instr env)) prog-five))

         ; Substitues registers for values
         (prog-seven (substitute-all prog-six registers))

         ; Turns instructions into opcode values
         (prog-eight (map convert prog-seven))

         ; Merges opcodes & operands into bytes
         (prog-nine (merge prog-eight))

         ; FLATTENS EVERYTHING, ie list of bytes
         (prog-ten (flatten prog-nine)))
      prog-ten)))

;; Opens file from command line arguments
(if (not (= (length (command-line-arguments)) 2))
    (print "Useage: assemble input-file address-offset")
    (assemble (read-titan-file (car (command-line-arguments)))
              (string->number (cadr (command-line-arguments)))))
