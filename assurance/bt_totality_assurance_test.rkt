#lang racket

(require (except-in rackunit fail)
         minikanren
         (file "../src/bt_rel.rkt")
         (file "../test/support/bt_harness.rkt"))

(define (make-bound len)
  (build-list len (lambda (i) 'k)))

(define bound3 (make-bound 3))
(define maxabs3 (max-abs-for-len 3))
(define ints3 (int-range (- maxabs3) maxabs3))

(define (enum-mul-all)
  (for*/list ([x ints3]
              [y ints3]
              [z ints3]
              #:when (= (* x y) z))
    (list x y z)))

(define (mode-limits expected)
  (define n (max 1 (length (remove-duplicates expected equal?))))
  (values (min 24 n) (max (+ n 10) (* 6 n))))

(test-case "bt totality assurance: *o vvv mode over len<=3"
  (define expected (enum-mul-all))
  (define-values (k k2) (mode-limits expected))
  (check-bt-case-strict
   "*o/total/vvv"
   #:expected-set expected
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (fresh (x y z)
         (bto-boundedo x bound3)
         (bto-boundedo y bound3)
         (bto-boundedo z bound3)
         (*o x y z)
         (== q (list x y z)))))
   #:decode-answer decode-bt-tuple
   #:k k
   #:k2 k2
   #:timeout-ms 45000))
