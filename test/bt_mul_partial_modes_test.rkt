#lang racket

(require (except-in rackunit fail)
         minikanren
         (file "../src/bt_rel.rkt")
         (file "support/bt_harness.rkt"))

(define ints1
  (let ([m (max-abs-for-len 1)])
    (int-range (- m) m)))

(define ints2
  (let ([m (max-abs-for-len 2)])
    (int-range (- m) m)))

(define ints3
  (let ([m (max-abs-for-len 3)])
    (int-range (- m) m)))

(test-case "bt *o partial mode: (1 . tail) * y = target (bounded tail/y)"
  (define target 8)
  (check-bt-case-strict
   "*o/partial/single-tail"
   #:expected-set
   (lambda ()
     (for*/list ([tail ints3]
                 [y ints3]
                 #:when (= (* (+ 1 (* 3 tail)) y) target))
       (list tail y)))
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (fresh (tail y)
         (bto-boundo tail 3)
         (bto-boundo y 3)
         (*o `(1 . ,tail) y (int->bt-term target))
         (== q (list tail y)))))
   #:decode-answer decode-bt-tuple
   #:k 30
   #:k2 120
   #:timeout-ms 2200))

(test-case "bt *o partial mode: two tail vars on multiplicands"
  (define target -20)
  (check-bt-case-strict
   "*o/partial/two-tails"
   #:expected-set
   (lambda ()
     (for*/list ([tx ints2]
                 [ty ints2]
                 #:when (= (* (+ 1 (* 3 tx))
                              (+ -1 (* 3 ty)))
                           target))
       (list tx ty)))
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (fresh (tx ty)
         (bto-boundo tx 2)
         (bto-boundo ty 2)
         (*o `(1 . ,tx) `(T . ,ty) (int->bt-term target))
         (== q (list tx ty)))))
   #:decode-answer decode-bt-tuple
   #:k 20
   #:k2 120
   #:timeout-ms 2200))

(test-case "bt *o partial mode: solve tail from one ground side"
  (check-bt-case-strict
   "*o/partial/inverse-tail"
   #:expected-set (lambda ()
                    (list (list 2)))
   #:run-observed
   (lambda (limit)
     (run limit (tail)
       (bto-boundo tail 2)
       (*o (int->bt-term 4) `(1 . ,tail) (int->bt-term 28))))
   #:decode-answer decode-bt-tuple
   #:k 1
   #:k2 1
   #:timeout-ms 2200))

(test-case "bt *o partial mode: bounded finite failure for unsat partial-tail shape"
  ;; With len<=1 bounds:
  ;; tail in [-1,1] => (1 + 3*tail) in {-2,1,4}
  ;; y in [-1,1]
  ;; Their products cannot be 5.
  (check-bt-case-strict
   "*o/partial/finite-failure"
   #:expected-set (lambda () '())
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (fresh (tail y)
         (bto-boundo tail 1)
         (bto-boundo y 1)
         (*o `(1 . ,tail) y (int->bt-term 5))
         (== q (list tail y)))))
   #:decode-answer decode-bt-tuple
   #:k 8
   #:k2 16
   #:timeout-ms 2200))
