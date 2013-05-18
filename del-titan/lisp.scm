          (do
            (print 120)

            (def Y 
              (lambda (f) 
                ((lambda (x) (x x)) 
                 (lambda (y) (f (lambda (z) ((y y) z)))))))

             (def fact
               (Y (lambda (f)
                    (lambda (n)
                      (if (= n 0)
                          1
                          (* n (f (- n 1))))))))

             (fact 5))