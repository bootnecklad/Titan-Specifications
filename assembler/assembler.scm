;;; THIS ORIGINAL FILE WAS WRITTEN BY QUADRESCENCE
;;; https://github.com/tarballs_are_good
;;; https://bitbucket.org/tarballs_are_good
;;;
;;; Copyright (c) 2013 Robert Smith & Marc Cleave
;;; ???


;;;  first pass just counts how long every ins is and works out the address of variables and labels
;;;  second actually assembles the ins and uses the values it aquired from the first pass

(use srfi-13)
(use (srfi 1))
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
                          (JMI #f) (LDI #f) (STI #f) (LDC 2) (LDM 3) (STM 3)))

;;; defines the machine code values for different opcodes
(define opcodes '((NOP #x00) (ADD #x10) (ADC #x11) (SUB #x12) (AND #x13) (LOR #x14) (XOR #x15) (NOT #x16)
                  (SHR #x17) (INC #x18) (DEC #x19) (INT #x20) (RTE #x21) (CLR #x60) (PSH #x70) (POP #x80)
                  (MOV #x90) (JMP #xA0) (JPZ #xA1) (JPS #xA2) (JPC #xA3) (JPI #xA4) (JSR #xA5) (RTN #xA6)
                  (LDC #xD0) (LDM #xE0) (STM #xF0) (JMI #f) (LDI #f) (STI #f) (TST #f) (SHL #f)))


;;; defines the machine code values for different registers
(define registers '((R0 #x0) (R1 #x1) (R2 #x2) (R3 #x3) (R4 #x4) (R5 #x5) (R6 #x6) (R7 #x7)
                    (R8 #x8) (R9 #x9) (RA #xA) (RB #xB) (RC #xC) (RD #xD) (RE #xE) (RF #xF)))

;;; defines all the directives
(define directives '(.RAW .LABEL .BYTE .WORD .LABEL .DATA .ASCII .ASCIZ))


;;; gets the length of executable instruction (in bytes)
(define (instr-length instr)
  (if (member (car instr) (flatten opcode-lengths))
      (if (cadr (member (car instr) (flatten opcode-lengths)))
          (cadr (member (car instr) (flatten opcode-lengths)))
          (compute-instruction-length instr))
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
    ((.ASCIZ) (+ 1 (string-length (caddr instr))))
    (else (error "INVALID DIRECTIVE"))))


;;; errors out when something is not implemented
(define (not-implemented) (error "not implemented yet"))

;;; quad
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
  (map convert prog))

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
      (if (cadr (member (car instr) (flatten opcodes)))
          (cons (cadr (member (car instr) (flatten opcodes)))
                (cdr instr))
          (convert-special-instr instr))
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
  (case (car instr)
    ((.RAW) (cdr instr))
    ((.BYTE .WORD) instr)
    ((.DATA) (cddr instr))
    ((.LABEL) instr)
    ((.ASCII) (map char->integer (string->list (caddr instr))))
    ((.ASCIZ) (append (map char->integer (string->list (caddr instr))) '(0)))
    (else (error "INVALID TITAN DIRECTIVE"))))

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
  (map cadr lst))

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
  (display "Length of program in bytes: ")
  (print (length bytes)))

;;; this is the function that you actually call
(define (assemble prog offset)
  (print-length (assembler prog offset))
  (print-bytes (assembler prog offset) 0))

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

(define (desguar-pseudo-instruction instr)
  (case (car instr)
    ((SHL) (list (list 'ADD (cadr instr) (cadr instr))))
    ((TST) (list (list 'XOR (cadr instr) (cadr instr))))
    (else (list instr))))

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

;;; THE SLIGHTLY LESS DIRTY COULD ALMOST BE CONSIDERED CLEAN
(define (assembler prog offset)
  (let* ((prog-one (append-map desugar-directives-transformer prog))
	 (prog-two (append-map desugar-pseudo-instruction-transformer prog-one))
	 (prog-three (desugar-labels prog-two offset))
	 (prog-four/env (alias-environment prog-three))
	 (prog-four (first prog-four/env))
	 (env (second prog-four/env))
	 (prog-five (map (lambda (instr) (substitute-instruction instr env)) prog-four)))
    prog-five))
    

;;; THE BIG DIRTY
;(define (assembler prog offset)
;  (flatten
;   (remove-directives
;    (merge prog
;           (substitute-all (substitute-all (begin-convert prog)
;                                           (create-subs prog offset))
;                           registers)))))


;;; does all the dirty work
(define (do-merge orig-instr instr)
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
    ((LDC) (list (bitwise-ior (car instr) (cadr instr)) (caddr instr)))
    ((LDM) (list (bitwise-ior (car instr) (cadr instr)) (split-address (caddr instr))))
    ((STM) (list (bitwise-ior (car instr) (cadr instr)) (split-address (caddr instr))))
    ((JMP) (list (car instr) (split-address (cadr instr))))
    ((JPZ) (list (car instr) (split-address (cadr instr))))
    ((JPS) (list (car instr) (split-address (cadr instr))))
    ((JPC) (list (car instr) (split-address (cadr instr))))
    ((JPI) (list (car instr) (split-address (cadr instr))))
    ((JSR) (list (car instr) (split-address (cadr instr))))
    (else instr)))
