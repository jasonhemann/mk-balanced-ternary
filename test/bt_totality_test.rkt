#lang racket

(require (except-in rackunit fail)
         minikanren
         (file "../src/bt_rel.rkt")
         (file "support/bt_harness.rkt"))

(define (make-bound len)
  (build-list len (lambda (i) 'k)))

(define bound3 (make-bound 3))
(define maxabs3 (max-abs-for-len 3))
(define ints3 (int-range (- maxabs3) maxabs3))

(define (maybe-values maybe domain)
  (if maybe (list maybe) domain))

(define (bind-int-if t maybe-int)
  (if maybe-int
      (== t (int->bt-term maybe-int))
      (== t t)))

(define (enum-mul x y z)
  (for*/list ([xi (maybe-values x ints3)]
              [yi (maybe-values y ints3)]
              [zi (maybe-values z ints3)]
              #:when (= (* xi yi) zi))
    (list xi yi zi)))

(define (mode-limits expected)
  (define n (max 1 (length (remove-duplicates expected equal?))))
  (values (min 20 n) (max (+ n 10) (* 6 n))))

(define mode-specs
  ;; Ground seed is 3 * 4 = 12. #f means logic variable.
  (list
   (list "ggg" 3 4 12)
   (list "ggv" 3 4 #f)
   (list "gvg" 3 #f 12)
   (list "vgg" #f 4 12)
   (list "gvv" 3 #f #f)
   (list "vgv" #f 4 #f)
   (list "vvg" #f #f 12)))

(test-case "bt totality: all factors of 12 under len<=3 bound"
  (define expected
    (for*/list ([x ints3]
                [y ints3]
                #:when (= (* x y) 12))
      (list x y)))
  (define-values (k k2) (mode-limits expected))
  (check-bt-case-strict
   "*o/factors-12/all"
   #:expected-set expected
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (fresh (x y)
         (bto-boundedo x bound3)
         (bto-boundedo y bound3)
         (*o x y (int->bt-term 12))
         (== q (list x y)))))
   #:decode-answer decode-bt-tuple
   #:k k
   #:k2 k2
   #:timeout-ms 2500))

(test-case "bt totality: *o mode matrix around 3*4=12 over len<=3 (excluding vvv)"
  ;; The fully open vvv mode is covered in assurance/bt_totality_assurance_test.rkt.
  (for ([spec mode-specs])
    (match-define (list label x y z) spec)
    (define expected (enum-mul x y z))
    (define-values (k k2) (mode-limits expected))
    (check-bt-case-strict
     (format "*o/total/~a" label)
     #:expected-set expected
     #:run-observed
     (lambda (limit)
       (run limit (q)
         (fresh (rx ry rz)
           (bto-boundedo rx bound3)
           (bto-boundedo ry bound3)
           (bto-boundedo rz bound3)
           (bind-int-if rx x)
           (bind-int-if ry y)
           (bind-int-if rz z)
           (*o rx ry rz)
           (== q (list rx ry rz)))))
     #:decode-answer decode-bt-tuple
     #:k k
     #:k2 k2
     #:timeout-ms 3000)))
