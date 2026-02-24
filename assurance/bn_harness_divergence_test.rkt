#lang racket

(require (except-in rackunit fail)
         minikanren
         (prefix-in bn: (file "../src/binary-numbers.rkt"))
         (file "../test/support/bn_harness.rkt"))

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
   #:timeout-ms 120))
