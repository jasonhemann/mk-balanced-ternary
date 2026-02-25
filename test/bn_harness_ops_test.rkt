#lang racket

(require (except-in rackunit fail)
         minikanren
         (file "../src/binary-numbers.rkt")
         (file "support/bn_harness.rkt"))

(define deterministic-max 31)
(define deterministic-nats (nat-range 0 deterministic-max))

(test-case "bn harness conversions: roundtrip over [0,31]"
  (for ([n deterministic-nats])
    (check-equal? (bn->nat (nat->bn n)) n)
    (check-equal? (nat->bn (or (bn->nat (nat->bn n)) -1))
                  (nat->bn n)))
  (check-false (bn->nat '(0)))
  (check-false (bn->nat '(1 0)))
  (check-false (bn->nat '(2)))
  (check-false (bn->nat '(1 . 1))))

(test-case "bn harness deterministic: pluso multi-answer query"
  (define target 7)
  (check-bn-case
   "pluso/sum-7"
   #:expected-set
   (lambda ()
     (for*/list ([a deterministic-nats]
                 [b deterministic-nats]
                 #:when (= (+ a b) target))
       (list a b)))
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (fresh (x y)
         (bno-boundo x 6)
         (bno-boundo y 6)
         (pluso x y (nat->bn target))
         (== q (list x y)))))
   #:decode-answer decode-bn-tuple
   #:k 20
   #:k2 120
   #:timeout-ms 1000))

(test-case "bn harness deterministic: /o Euclidean semantics"
  (check-bn-case
   "/o/23-by-5"
   #:expected-set (lambda ()
                    (list (list 4 3)))
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (fresh (quot rem)
         (/o (nat->bn 23) (nat->bn 5) quot rem)
         (== q (list quot rem)))))
   #:decode-answer decode-bn-tuple
   #:k 1
   #:k2 1
   #:timeout-ms 1000)
  (check-bn-case
   "/o/24-by-6"
   #:expected-set (lambda ()
                    (list (list 4 0)))
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (fresh (quot rem)
         (/o (nat->bn 24) (nat->bn 6) quot rem)
         (== q (list quot rem)))))
   #:decode-answer decode-bn-tuple
   #:k 1
   #:k2 1
   #:timeout-ms 1000))

(test-case "bn harness deterministic: minuso failure when subtrahend is larger"
  (check-bn-case
   "minuso/3-5"
   #:expected-set (lambda ()
                    '())
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (minuso (nat->bn 3) (nat->bn 5) q)))
   #:decode-answer decode-bn-tuple
   #:k 1
   #:k2 1
   #:timeout-ms 1000))

(test-case "bn harness deterministic: bounded inverse pluso"
  (check-bn-case
   "pluso/inverse"
   #:expected-set (lambda ()
                    (list (list 12)))
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (bno-boundo q 8)
       (pluso (nat->bn 9) q (nat->bn 21))))
   #:decode-answer decode-bn-tuple
   #:k 1
   #:k2 1
   #:timeout-ms 1000))

(test-case "bn harness deterministic: bounded inverse *o"
  (check-bn-case
   "*o/inverse"
   #:expected-set (lambda ()
                    (list (list 27)))
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (bno-boundo q 8)
       (*o (nat->bn 3) q (nat->bn 81))))
   #:decode-answer decode-bn-tuple
   #:k 1
   #:k2 1
   #:timeout-ms 1000))

(test-case "bn harness deterministic: partial term with tail variable"
  (define target 9)
  (check-bn-case
   "pluso/partial-tail"
   #:expected-set
   (lambda ()
     (for*/list ([tail deterministic-nats]
                 [y deterministic-nats]
                 #:when (= (+ 1 (* 2 tail) y) target))
       (list tail y)))
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (fresh (tail y)
         (bno-boundo tail 5)
         (bno-boundo y 6)
         (pluso `(1 . ,tail) y (nat->bn target))
         (== q (list tail y)))))
   #:decode-answer decode-bn-tuple
   #:k 20
   #:k2 120
   #:timeout-ms 1000))

(test-case "bn harness randomized: pluso/minuso/*o over [0,300]"
  (check-bn-random
   "ground-ops"
   #:trials 90
   #:range-max 300
   #:arity 2
   #:check
   (lambda (i vals)
     (define a (first vals))
     (define b (second vals))
     (define hi (max a b))
     (define lo (min a b))

     (check-bn-case
      (format "rand/~a/pluso" i)
      #:expected-set (lambda ()
                       (list (list (+ a b))))
      #:run-observed
      (lambda (limit)
        (run limit (q)
          (pluso (nat->bn a) (nat->bn b) q)))
      #:decode-answer decode-bn-tuple
      #:k 1
      #:k2 1
      #:timeout-ms 1000)

     (check-bn-case
      (format "rand/~a/minuso" i)
      #:expected-set (lambda ()
                       (list (list (- hi lo))))
      #:run-observed
      (lambda (limit)
        (run limit (q)
          (minuso (nat->bn hi) (nat->bn lo) q)))
      #:decode-answer decode-bn-tuple
      #:k 1
      #:k2 1
      #:timeout-ms 1000)

     (check-bn-case
      (format "rand/~a/*o" i)
      #:expected-set (lambda ()
                       (list (list (* a b))))
      #:run-observed
      (lambda (limit)
        (run limit (q)
          (*o (nat->bn a) (nat->bn b) q)))
      #:decode-answer decode-bn-tuple
      #:k 1
      #:k2 1
      #:timeout-ms 1000))))
