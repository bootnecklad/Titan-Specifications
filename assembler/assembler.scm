;;; THIS ORIGINAL FILE WAS WRITTEN BY QUADRESCENCE
;;; https://github.com/tarballs_are_good
;;; https://bitbucket.org/tarballs_are_good
;;;
;;; Copyright (c) 2013 Robert Smith & Marc Cleave
;;; ???


;;;  first pass just counts how long every ins is and works out the address of variables and labels
;;;  second actually assembles the ins and uses the values it aquired from the first pass

(use extras)
(use srfi-1)
(use srfi-13)
(load "~/Code/Titan-Specifications/assembler/CPU-DEFINITIONS.scm")
(load "~/Code/Titan-Specifications/assembler/pseudo-instructions.scm")

(define nil '())

;;; errors out when something is not implemented
(define (not-implemented) (error "not implemented yet"))

;;; gets program frome file
(define read-titan-file
  (lambda (filename)
    (call-with-input-file filename read)))

;; Different components of a Titan program
(define (directive? instr)
  (and (pair? instr)
       (char=? #\. (string-ref (symbol->string (if (symbol? (car instr))
                                                   (car instr)
                                                   'NOTSYMBOL))  0))))

(define (label? instr)
  (and (pair? instr)
       (eq? '.LABEL (car instr))))

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

;;; gets length of instr, whether that be an instructions, label or directive
(define (compute-length instr)
  (cond
   ((label? instr) 0)
   ((instruction? instr) (instr-length instr))
   ((directive? instr) (compute-directive-length instr))
   (else (error "INVALD TITAN ASM"))))

;;; gets the length of executable instruction (in bytes)
(define (instr-length instr)
  (if (member (car instr) (flatten opcode-lengths))
      (if (cadr (member (car instr) (flatten opcode-lengths)))
          (cadr (member (car instr) (flatten opcode-lengths)))
          (compute-instruction-length instr))
      (begin (display (car instr)) (error "INVALID TITAN INSTRUCTION"))))

(define register?
  (lambda (register)
    (if (and (symbol? register)
             (member register (flatten registers)))
        #t
        #f)))

(define autoincrement?
       (lambda (instr)
         (if (null? instr)
             #f
             (or (vector? (car instr))
                  (autoincrement? (cdr instr))))))

;;; computes the lengths of instructions with the same opcode but different addressing mode
(define compute-instruction-length
  (lambda (instr)
    (case (car instr)
      ((JMP) (compute-length-instr instr))
      ((LDM) (compute-length-instr instr))
      ((STM) (compute-length-instr (list (car instr) (caddr instr) (cadr instr))))
      (else (begin (print instr) (error "INVALID TITAN INSTRUCITON"))))))

(define compute-length-instr
  (lambda (instr)
    (cond
     ((list? (second instr)) (compute-length-list instr))
     ((and (= (length instr) 2)
           (or (symbol? (second instr))
               (number? (second instr)))) 3)
     ((and (<= (length instr) 2)
           (register? (second instr))) 2)
     ((and (register? (second instr))
           (register? (last instr))) 2)
     ((autoincrement? instr) 2)
     ((eq? '+ (second instr)) 2)
     ((or (symbol? (third instr))
          (number? (third instr))) 4)
     ((number? (second instr)) 4)
     (else (begin (print instr) (error "INVALID TITAN INSTRUCTION"))))))

(define compute-length-list
  (lambda (instr)
    (cond
     ((and (= 2 (length instr))
           (number? (car (second instr)))) 3)
     ((and (= 3 (length instr))
           (number? (car (second instr)))) 4)
     ((eq? '+ (car (second instr))) 2)
     ((and (register? (car (second instr)))
           (= 1 (length (second instr)))) 2)
     ((and (register? (car (second instr)))
           (= 2 (length (second instr)))) 4)
     (else 3))))

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
    ((.ASCIZ) (+ 1 (string-length (caddr instr))))
    (else (error "INVALID DIRECTIVE"))))

;;; loops through assembly program assigning lengths to instructions
(define (apply-lengths prog)
  (map compute-length prog))

;;; creats address list for program
(define (address-list prog)
  (cons 0 (running-total (apply-lengths prog)0)))

;;; copies to a new list
(define (running-total lst sum)
  (if (null? lst)
      nil
      (cons (+ sum (car lst))
            (running-total (cdr lst) (+ sum (car lst))))))

;;; tells us if an operand is an index, ie (Rh Rl)
(define (word? v)
  (vector? v))

;;; begins converting process
(define (convert instr)
  (cond
   ((instruction? instr) (convert-instr instr))
   ((directive? instr) (cdr instr))
   (else (begin (display instr) (error "INVALD TITAN ASSEMBLY")))))

;;; converts assembly instructions into machine code values
(define (convert-instr instr)
  (if (member (car instr) (flatten opcodes))
      (cons (cadr (member (car instr) (flatten opcodes)))
            (cdr instr))
      (begin (display instr) (error "INVALID TITAN INSTRUCTION"))))

(define (substitute-all lst tbl)
  (if (null? tbl)
      lst
      (substitute-all (substitute lst (caar tbl) (cadar tbl)) (cdr tbl))))

(define (substitute prog label value)
  (map (lambda (element)
	 (cond
	  ((eq? label element) value)
	  ((list? element) (substitute element label value))
	  (else element)))
       prog))

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

;;; this is the function that you actually call
(define (assemble prog offset)
  (print-length (assembler prog offset))
  (print-bytes (assembler prog offset) offset 0)
  (display "\n"))

(define (desugar-directive directive)
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
    (else (error "INVALID TITAN DIRECTIVE" (car directive)))))

(define (desugar-directives-transformer instr)
  (cond
   ((directive? instr) (desugar-directive instr))
   ((instruction? instr) (list instr))
   (else (error "INVALD TITAN ASM"))))

(define jmp-counter 0)

(define (counter)
  (begin (set! jmp-counter (add1 jmp-counter))
	 jmp-counter))

(define (desugar-pseudo-instruction-transformer instr)
  (cond
   ((directive? instr) (list instr))
   ((instruction? instr) (desguar-pseudo-instruction instr))
   (else (error "INVALD TITAN ASM"))))

(define (env-lookup name env)
  (if (null? env)
      (error "Couldn't resolve name" name)
      (let ((key-value (car env)))
        (if (eq? name (car key-value))
            ;; Return the value
            (cdr key-value)
            ;; Keep searching the environment.
            (env-lookup name (cdr env))))))

(define (register? s)
  (and (member s (map car registers)) #t))

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

(define convert-autoincrement
  (lambda (instr)
    (if (null? instr)
        nil
        (cons (if (vector? (car instr))
                  (vector-ref (car instr) 0)
                  (car instr))
              (convert-autoincrement (cdr instr))))))
  
;;; THE SLIGHTLY LESS DIRTY COULD ALMOST BE CONSIDERED CLEAN
(define (assembler prog offset)
  (let* ((prog-one (append-map desugar-directives-transformer prog))
         (prog-two (append-map desugar-pseudo-instruction-transformer prog-one))
         (prog-three (desugar-labels prog-two offset))
         (prog-three-point-five (map convert-autoincrement prog-three))
         (prog-three-point-six (map flatten prog-three-point-five))
         (prog-four/env (alias-environment prog-three-point-six))
         (prog-four (first prog-four/env))
         (env (second prog-four/env))
	 (prog-five (map (lambda (instr) (substitute-instruction instr env)) prog-four))
	 (prog-six (substitute-all prog-five registers))
	 (prog-seven (map convert prog-six))
         (prog-eight (first (alias-environment prog-three-point-five)))
	 (prog-nine (merge prog-eight prog-seven))
	 (prog-ten (flatten prog-nine)))
    prog-ten))

;;; does all the dirty work
(define (do-merge orig-instr instr)
  (case (car orig-instr)
    ((ADD) (assemble-RSRD instr))
    ((ADC) (assemble-RSRD instr))
    ((SUB) (assemble-RSRD instr))
    ((AND) (assemble-RSRD instr))
    ((IOR) (assemble-RSRD instr))
    ((XOR) (assemble-RSRD instr))
    ((MOV) (assemble-RSRD instr))
    ((NOT) (assemble-RS instr))
    ((SHR) (assemble-RS instr))
    ((INC) (assemble-RS instr))
    ((DEC) (assemble-RS instr))
    ((CLR) (assemble-RS instr))
    ((PSH) (assemble-RS instr))
    ((POP) (assemble-RS instr))
    ((LDC) (assemble-LDC instr))
    ((LDM) (assemble-LDM orig-instr instr))
    ((STM) (assemble-STM orig-instr instr))
    ((JMP) (assemble-JMP orig-instr instr))
    ((JPZ) (assemble-STD-JMP))
    ((JPS) (assemble-STD-JMP))
    ((JPC) (assemble-STD-JMP))
    ((JPI) (assemble-STD-JMP))
    ((JSR) (assemble-STD-JMP))
    (else instr)))

(define assemble-RSRD
  (lambda (instr)
    (list (car instr)
          (combine-nibbles (cadr instr)
                           (caddr instr)))))

(define assemble-RS
  (lambda (instr)
    (list (bitwise-ior (car instr)
                           (cadr instr)))))

(define assemble-LDC
  (lambda (instr)
    (list (bitwise-ior (car instr) (caddr instr))
          (cadr instr))))

(define assemble-STD-JMP
  (lambda (instr)
    (list (car instr)
          (split-address (cadr instr)))))


;;; (LDM #xBABE R0) (LDM R0 R1)  (LDM (#xCAFE) R1) (LDM (+ R1) R0) (LDM (R2 #xDEAD) R3) (LDM (R0) R1) (LDM + R1 R3) (LDM R2 #xDEAD R3)
;;; (STM R0 #xBABE) (STM R1 R0)  (STM R1 (#xCAFE)) (STM R0 (+ R1)) (LDM R3 (R2 #xDEAD)) (STM R1 (R0)) (STM R3 + R1) (STM R3 R2 #xDEAD)

(define assemble-LDM
  (lambda (orig-instr instr)
    (list (car instr) 0 (split-address #xFFFF))))

(define assemble-STM
  (lambda (orig-instr instr)
    (list (car instr) 0 (split-address #xFFFF))))


(define assemble-JMP
  (lambda (orig-instr instr)
    (cond

 ;;; (JMP (Rs #xZZZZ)) - Jump to the address at Rs + #xZZZZ
     ((and (list? (second orig-instr))
           (register? (car (second orig-instr)))
           (= 2 (length (second orig-instr))))
      (list (bitwise-ior (car instr) 7) (combine-nibbles (second instr) 0) (split-address (last instr))))

;;; (JMP Rs #xZZZZ)   - Jump to Rs + #xZZZZ
     ((and (register? (second orig-instr))
           (number? (last instr))
           (= 3 (length instr)))
      (list (bitwise-ior (car instr) 6) (combine-nibbles (second instr) 0) (split-address (last instr))))


;;; (JMP (+ Rs))      - Jump to the address at the address in Rs, then increment Rs

     ((and (list? (second orig-instr))
           (eq? '+ (cadr orig-instr)))
      (list (bitwise-ior (car instr) 5) (combine-nibbles (last instr) 0)))

;;; (JMP + Rs)        - Jump to the address in Rn, then increment Rs
     ((and (eq? '+ (cadr orig-instr))
           (register? (last orig-instr)))
      (list (bitwise-ior (car instr) 4) (combine-nibbles (last instr) 0)))

;;; (JMP #xZZZZ)      - Jump to address #xZZZZ
     ((and (number? (second instr))
           (not (list? (second orig-instr)))
           (not (register? (second orig-instr))))
      (list (bitwise-ior (car instr) 0) (split-address (second instr))))

;;; (JMP (#xZZZZ))    - Jump to the address in #xZZZZ
     ((and (number? (second instr))
           (list? (second orig-instr))
           (not (register? (car (second orig-instr)))))
      (list (bitwise-ior (car instr) 1) (split-address (second instr))))

;;; (JMP Rs)          - Jump to the address in Rs
     ((and (= (length instr) 2)
           (register? (second orig-instr)))
      (list (bitwise-ior (car instr) 2) (combine-nibbles (second instr) 0)))

;;; (JMP (Rs))        - Jump to the address at the address in Rs
     ((and (list? (second orig-instr))
           (register? (car orig-instr)))
      (list (bitwise-ior (car instr) 3) (combine-nibbles (last instr) 0))))))

;;; opening files and things

(if (not (= (length (command-line-arguments)) 2))
    (print "Useage: assemble input-file address-offset")
    (assemble (read-titan-file (car (command-line-arguments)))
              (string->number (cadr (command-line-arguments)))))
