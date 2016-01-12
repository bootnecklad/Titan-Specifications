;;; LISP to Titan assembly compiler
;;; Use the Titan assembler to make executeable programs
;;;
;;; lisp -> tokenizer -> parser -> coad generator -> titan asm

;;; Only given functions: quote, atom, eq, cons, car, cdr, cond

(define nil '())

;;; used when writing in the middle of writing/testing functions
(define (not-implemented)
  (error "not implemented yet"))

(use (srfi 1))
(use (srfi 13))
(use (srfi 14))

;;; defines the allowed character set 
(define allowed-charset
  (char-set-union char-set:lower-case
                  char-set:digit
                  (string->char-set " ()-+!<>?")))

;;; checks if input character is in the allowed character set
(define (allowed-char? char)
  (char-set-contains? allowed-charset char))

;;; removes everything that isnt in the allowed character set
(define (remove-unwanted input-string)
  (list->string (filter allowed-char? (string->list input-string))))

;;; takes a string and produces a list of words
(define (words input-string)
  (string-split (remove-unwanted (string-downcase input-string))))

;;; splits ( and ) away from things
(define (remove-parens str)
  (define do-remove-parens
    (lambda (lst)
      (if (null? lst)
          nil
          (cond
           ((char=? #\( (car lst)) (list (car lst) (cdr lst)))
           ((char=? #\) (last lst)) (list (reverse (cdr (reverse lst))) (last lst)))
           (else lst)))))

  (do-remove-parens (string->list str)))


;;; puts strings back together from a list
(define (char-joiner lst)
  (if (null? lst)
      nil
      (cons (if (list? (car lst))
                (list->string (car lst))
                (list->string (list (car lst))))
            (char-joiner (cdr lst)))))

;;; tokeizes a tlisp string
(define tokenize-tlisp
  (lambda (str)
    (let* ((removed-spaces (words str))
           (removed-parens (map remove-parens removed-spaces))
           (string-stitched (map char-joiner removed-parens))
           (tokenized-str (flatten string-stitched)))
       tokenized-str)))

;;; 
(define operator?
  (lambda (str)
    (or (equal? str "(")
        (equal? str ")"))))

;;; quote, atom, eq, cons, car, cdr, cond
(define function?
  (lambda (str)
    (or (equal? str "quote")
        (equal? str "atom")
        (equal? str "eq")
        (equal? str "car")
        (equal? str "cond"))))

;;; creates environment of types
(define type-env
  (lambda (lst)
    (if (null? lst)
        nil
        (cons
         (cond
          ((operator? (car lst)) 'OPERATOR)
          ((string->number (car lst)) 'NUMBER)
          ((function? (car lst)) 'FUNCTION)
          (else 'KEYWORD))
         (type-env (cdr lst))))))

;;; combines tokenized program and type environment
(define (create-env prog env)
  (if (null? prog)
      nil
      (cons (cons (car prog)
                  (car env))
            (create-env (cdr prog)
                        (cdr env)))))
