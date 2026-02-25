#lang racket

(require (except-in rackunit fail)
         minikanren
         racket/random
         (prefix-in bn: (file "../src/binary-numbers.rkt"))
         (file "../test/support/bn_harness.rkt"))

(define deterministic-max 31)
(define deterministic-nats (nat-range 0 deterministic-max))

(test-case "bn harness ops assurance: *o multi-answer factor query"
  (check-bn-case
   "*o/factors-12"
   #:expected-set
   (lambda ()
     (for*/list ([a deterministic-nats]
                 [b deterministic-nats]
                 #:when (= (* a b) 12))
       (list a b)))
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (fresh (x y)
         (bno-boundo x 6)
         (bno-boundo y 6)
         (bn:*o x y (nat->bn 12))
         (== q (list x y)))))
   #:decode-answer decode-bn-tuple
   #:k 60
   #:k2 300
   #:timeout-ms 2000))

(test-case "bn harness ops assurance: run* completion for /o 199/85"
  (check-bn-case
   "/o/199-by-85/run*"
   #:expected-set (lambda ()
                    (list (list 2 29)))
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (fresh (quot rem)
         (bn:/o (nat->bn 199) (nat->bn 85) quot rem)
         (== q (list quot rem)))))
   #:decode-answer decode-bn-tuple
   #:k 1
   #:k2 200
   #:timeout-ms 7000))

(test-case "bn harness ops assurance: randomized /o over [0,220] (seeded)"
  (parameterize ([current-pseudo-random-generator
                  (make-pseudo-random-generator)])
    (random-seed 20260225)
    (check-bn-random
     "slow-div"
     #:trials 60
     #:range-max 220
     #:arity 2
     #:check
     (lambda (i vals)
       (define n (first vals))
       (define m (add1 (second vals)))
       (check-bn-case
        (format "rand-slow/~a//o" i)
        #:expected-set (lambda ()
                         (list (list (quotient n m)
                                     (remainder n m))))
        #:run-observed
        (lambda (limit)
          (run limit (q)
            (fresh (quot rem)
              (bn:/o (nat->bn n) (nat->bn m) quot rem)
              (== q (list quot rem)))))
        #:decode-answer decode-bn-tuple
        #:k 1
        #:k2 1
        #:timeout-ms 5000)))))

(test-case "bn harness divergence: known shared-variable shape times out"
  (check-bn-case
   "bn/divergent-shape"
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (fresh (x)
         (bn:*o '(1 1) `(1 . ,x) `(1 0 . ,x))
         (== q x))))
   #:expect-timeout? #t
   #:timeout-ms 120
   #:k2 1))

(test-case "bn harness divergence: finite bounded case still returns"
  (check-bn-case
   "bn/finite-sanity"
   #:expected-set (lambda ()
                    (list (list 2)))
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (bn:pluso '(1) '(1) q)))
   #:decode-answer decode-bn-tuple
   #:timeout-ms 120
   #:k 1
   #:k2 1))
