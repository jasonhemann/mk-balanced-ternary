#lang racket

(require rackunit
         minikanren
         racket/engine
         (file "../src/bt_rel.rkt")
         (file "../src/bt_div_structural.rkt")
         (file "support/bt_harness.rkt"))

(define (run-with-timeout timeout-ms thunk)
  (define e (engine (lambda (_stop) (thunk))))
  (define done? (engine-run timeout-ms e))
  (define out (and done? (engine-result e)))
  (engine-kill e)
  (values done? out))

(define (normalize-set xs)
  (sort (remove-duplicates xs equal?) string<? #:key ~s))

(define (euclid-div n m)
  (define q0 (quotient n m))
  (define r0 (remainder n m))
  (if (negative? r0)
      (if (positive? m)
          (values (sub1 q0) (+ r0 m))
          (values (add1 q0) (- r0 m)))
      (values q0 r0)))

(define (run1-div rel n m [timeout-ms 3000])
  (define-values (done? out)
    (run-with-timeout timeout-ms
                      (lambda ()
                        (run 1 (ans)
                          (fresh (q r)
                            (rel (int->bt-term n) (int->bt-term m) q r)
                            (== ans (list q r)))))))
  (values done?
          (and out
               (pair? out)
               (decode-bt-tuple (first out)))))

(test-case "bt structural div: nato classifier matches bounded host nonnegative set"
  (define bound '(k k k))
  (define maxabs (max-abs-for-len 3))
  (define ints (int-range (- maxabs) maxabs))
  (define-values (done? raw)
    (run-with-timeout 2500
                      (lambda ()
                        (run* (n)
                          (bto-boundedo n bound)
                          (nato n)))))
  (check-true done?)
  (define observed
    (normalize-set
     (for/list ([ans raw]
                #:do [(define dec (bt->int-term ans))]
                #:when dec)
       dec)))
  (define expected
    (normalize-set (filter (lambda (x) (>= x 0)) ints)))
  (check-equal? observed expected))

(test-case "bt structural div: nat core agrees with host Euclidean division (m>0,n>=0)"
  (for* ([n (in-range 0 16)]
         [m '(1 2 3 4 5)])
    (define-values (q r) (euclid-div n m))
    (define-values (done? got)
      (run1-div divo-nat-structo n m 3000))
    (check-true done? (format "divo-nat-structo timeout for ~a/~a" n m))
    (check-equal? got (list q r)
                  (format "divo-nat-structo mismatch for ~a/~a" n m))))

(test-case "bt structural div: signed surface agrees with current divo and host ground cases"
  (define pairs
    '((19 4) (19 -4) (-19 4) (-19 -4)
      (11 4) (-11 4) (11 -4) (-11 -4)
      (7 3) (-7 3) (7 -3) (-7 -3)
      (10 -2) (12 -2) (10 2) (-10 2)
      (1 1) (1 -1) (-1 1) (-1 -1)
      (0 1) (0 -1) (0 2) (0 -2)
      (2 3) (-2 3) (2 -3) (-2 -3)
      (4 1) (-4 1) (4 -1) (-4 -1)))
  (for ([nm pairs])
    (define n (first nm))
    (define m (second nm))
    (define-values (q r) (euclid-div n m))
    (define expected (list q r))
    (define-values (done-struct? got-struct)
      (run1-div divo-structo n m 4000))
    (check-true done-struct?
                (format "divo-structo timeout for ~a/~a" n m))
    (check-equal? got-struct expected
                  (format "divo-structo host mismatch for ~a/~a" n m)))
  ;; Keep parity checks with the current main divo on a representative subset.
  (for ([nm '((19 4) (19 -4) (-11 4) (-11 -4)
              (7 3) (-7 3) (10 -2) (0 -2))])
    (define n (first nm))
    (define m (second nm))
    (define-values (done-struct? got-struct)
      (run1-div divo-structo n m 6000))
    (define-values (done-main? got-main)
      (run1-div divo n m 12000))
    (check-true done-struct?
                (format "divo-structo parity timeout for ~a/~a" n m))
    (check-true done-main?
                (format "divo parity timeout for ~a/~a" n m))
    (check-equal? got-struct got-main
                  (format "divo parity mismatch for ~a/~a" n m))))
