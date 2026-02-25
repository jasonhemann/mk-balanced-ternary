#lang racket

(require (except-in rackunit fail)
         minikanren
         racket/random
         (file "../src/bt_rel.rkt")
         (file "support/bt_harness.rkt"))

(define deterministic-min -40)
(define deterministic-max 40)
(define deterministic-ints (int-range deterministic-min deterministic-max))

(define (rand-int lo hi)
  (+ lo (random (+ 1 (- hi lo)))))

(test-case "bt harness conversions: roundtrip over [-200,200]"
  (for ([n (in-range -200 201)])
    (check-equal? (bt->int-term (int->bt-term n)) n)
    (check-equal? (int->bt-term (or (bt->int-term (int->bt-term n)) 0))
                  (int->bt-term n)))
  (check-false (bt->int-term '(0)))
  (check-false (bt->int-term '(1 0)))
  (check-false (bt->int-term '(2)))
  (check-false (bt->int-term '(1 . 1)))
  (check-false (bt->int-term '(T 0))))

(test-case "bt harness deterministic: pluso multi-answer query"
  (define target 2)
  (check-bt-case
   "pluso/sum-2"
   #:expected-set
   (lambda ()
     (for*/list ([a deterministic-ints]
                 [b deterministic-ints]
                 #:when (= (+ a b) target))
       (list a b)))
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (fresh (x y)
         (bto-boundo x 4)
         (bto-boundo y 4)
         (pluso x y (int->bt-term target))
         (== q (list x y)))))
   #:decode-answer decode-bt-tuple
   #:k 20
   #:k2 200
   #:timeout-ms 1200))

(test-case "bt harness deterministic: minuso ground result"
  (check-bt-case
   "minuso/3-5"
   #:expected-set (lambda ()
                    (list (list -2)))
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (minuso (int->bt-term 3) (int->bt-term 5) q)))
   #:decode-answer decode-bt-tuple
   #:k 1
   #:k2 1
   #:timeout-ms 1200))

(test-case "bt harness deterministic: bounded inverse pluso"
  (check-bt-case
   "pluso/inverse"
   #:expected-set (lambda ()
                    (list (list 12)))
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (bto-boundo q 8)
       (pluso (int->bt-term 9) q (int->bt-term 21))))
   #:decode-answer decode-bt-tuple
   #:k 1
   #:k2 1
   #:timeout-ms 1200))

(test-case "bt harness deterministic: bounded inverse *o"
  (check-bt-case
   "*o/inverse"
   #:expected-set (lambda ()
                    (list (list 27)))
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (bto-boundo q 8)
       (*o (int->bt-term 3) q (int->bt-term 81))))
   #:decode-answer decode-bt-tuple
   #:k 1
   #:k2 1
   #:timeout-ms 1200))

(test-case "bt harness deterministic: partial term with tail variable"
  (define target 10)
  (check-bt-case
   "pluso/partial-tail"
   #:expected-set
   (lambda ()
     (for*/list ([tail deterministic-ints]
                 [y deterministic-ints]
                 #:when (= (+ 1 (* 3 tail) y) target))
       (list tail y)))
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (fresh (tail y)
         (bto-boundo tail 4)
         (bto-boundo y 4)
         (pluso `(1 . ,tail) y (int->bt-term target))
         (== q (list tail y)))))
   #:decode-answer decode-bt-tuple
   #:k 20
   #:k2 120
   #:timeout-ms 1200))

(test-case "bt harness randomized: pluso/minuso/*o over [-120,120]"
  (check-bt-random
   "ground-ops"
   #:trials 80
   #:arity 2
   #:sample (lambda (i)
              (list (rand-int -120 120)
                    (rand-int -120 120)))
   #:check
   (lambda (i vals)
     (define a (first vals))
     (define b (second vals))

     (check-bt-case
      (format "rand/~a/pluso" i)
      #:expected-set (lambda ()
                       (list (list (+ a b))))
      #:run-observed
      (lambda (limit)
        (run limit (q)
          (pluso (int->bt-term a) (int->bt-term b) q)))
      #:decode-answer decode-bt-tuple
      #:k 1
      #:k2 1
      #:timeout-ms 1200)

     (check-bt-case
      (format "rand/~a/minuso" i)
      #:expected-set (lambda ()
                       (list (list (- a b))))
      #:run-observed
      (lambda (limit)
        (run limit (q)
          (minuso (int->bt-term a) (int->bt-term b) q)))
      #:decode-answer decode-bt-tuple
      #:k 1
      #:k2 1
      #:timeout-ms 1200)

     (check-bt-case
      (format "rand/~a/*o" i)
      #:expected-set (lambda ()
                       (list (list (* a b))))
      #:run-observed
      (lambda (limit)
        (run limit (q)
          (*o (int->bt-term a) (int->bt-term b) q)))
      #:decode-answer decode-bt-tuple
      #:k 1
      #:k2 1
      #:timeout-ms 1200))))
