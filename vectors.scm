;;; (C) Marc Cleave 2013
;;; a vector has the format:
;;; '(i j k)
;;; where i is the i component, etc
;;;
;;; the vector equation of a line is given:
;;; '((x y z) (i j k))
;;;
;;; where (x y z) is the point on the line, u is the scalar multiple of the direction and (i j k) is the direction of the line


(define nil '())


;;; defines a vector to be used
(define toy-vector '(1 2 3))

;;; returns the i component of the vector
(define (i-pos vctr)
  (car vctr))

;;; returns the j component of the vector
(define (j-pos vctr)
  (cadr vctr))

;;; returns the k component of the vector
(define (k-pos vctr)
  (caddr vctr))

;;; returns the square of the argument
(define (square n)
  (expt n 2))

;;; returns the magnitude of a vector
(define (vector-size vctr)
  (sqrt (+ (square (i-pos vctr))
           (square (j-pos vctr))
           (square (k-pos vctr)))))

;;; creates a vector when given three components
(define (create-vector i j k)
  (list i j k))

;;; returns the inverse of a vector, ie (1 4 2) is (-1 -4 -2)
(define (invert-vector vctr)
  (create-vector (- (i-pos vctr))
                 (- (j-pos vctr))
                 (- (k-pos vctr))))

;;; returns the addition of two vectors
(define (add-vectors a b)
  (create-vector (+ (i-pos a) 
                    (i-pos b))
                 (+ (j-pos a) 
                    (j-pos b)) 
                 (+ (k-pos a) 
                    (k-pos b))))

;;; returns the subtraction of two vectors
(define (subtract-vectors a b)
  (create-vector (- (i-pos b) 
                    (i-pos a))
                 (- (j-pos b) 
                    (j-pos a))
                 (- (k-pos b)
                    (k-pos a))))

;;; returns the vector A->B when given A and B as point vectors
(define (find-vector-one a b)
  (add-vectors (invert-vector a) b))

;;; same as above but different method
(define (find-vector-two a b)
  (subtract-vectors a b))

;;; checks if the two vectors are equal
(define (direction-eq? a b)
  (and (= (i-pos b) 
          (i-pos a))
       (= (j-pos b) 
          (j-pos a))
       (= (k-pos b) 
          (k-pos a))))


;;; checks if the magnitude of two vectors are equal
(define (magnitude-eq? a b)
  (= (vector-size a) 
     (vector-size b)))

;;; returns the distance of two vectors
(define (distance a b)
  (vector-size (subtract-vectors a b)))

;;; returns the scalar product of two vectors
;;; a.b
(define (scalar-product a b)
  (+ (* (i-pos a) 
        (i-pos b))
     (* (j-pos a)
        (j-pos b))
     (* (k-pos a) 
        (k-pos b))))

;;; returns the angle between two vectors using:
;;;  cos x = a.b / |a||b|
(define (angle-between-vectors a b)
  (acos (/ (scalar-product a b)
           (* (vector-size a) 
              (vector-size b)))))

;;; convert radians into decimal
;;; scheme uses radians for its internal representation of angles
(define (rad->deg ang)
  (* ang (/ 180 3.14159)))

;;; creates a line given a point and a direction
(define (create-line point direction)
  (list point direction))


;;; returns the direction of a vector with a scalar multiple
(define (rm-scalar vctr)
  (cadr vctr))

;;; returns the point from an equation of the line
(define (get-point vctr)
  (car vctr))

;;; returns the direction from the equation of a line
(define (get-direction vctr)
  (cadadr vctr))

;;; returns if a vector lies on a line
(define (vector-on-line? eqn a)
  (= (/ (- (i-pos a) 
           (i-pos (get-point eqn))) 
        (i-pos (get-direction eqn)))
     (/ (- (j-pos a) 
           (j-pos (get-point eqn))) 
        (j-pos (get-direction eqn)))
     (/ (- (k-pos a) 
           (k-pos (get-point eqn)))
        (k-pos (get-direction eqn)))))

;;; returns if two vectors are parallel
(define (parallel? a b)
  (vectors-eq? (get-direction a) 
               (get-direction b)))

;;; returns if two vectors intersect
;;; haha... you think I'm going back to gaussian elimination? No thanks 
(define (intersect? a b)
  '())

;;; returns if two vectors are scew
;;; two vectors are skew if they do not intersect and are not parallel
(define (skew? a b)
  (not (and (intersect? a b) 
            (parallel? a b))))

;;; returns the angle of two vector equation of lines
(define (angle-between-lines a b)
  (angle-between-vectors (get-direction a) 
                         (get-direction b)))