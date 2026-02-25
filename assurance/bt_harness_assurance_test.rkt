#lang racket

(require (except-in rackunit fail)
         minikanren
         racket/random
         (file "../src/bt_rel.rkt")
         (file "../test/support/bt_harness.rkt"))

(define (rand-int lo hi)
  (+ lo (random (+ 1 (- hi lo)))))

(test-case "bt harness assurance: pluso randomized over [-300,300]"
  (parameterize ([current-pseudo-random-generator
                  (make-pseudo-random-generator)])
    (random-seed 20260225)
    (check-bt-random
     "bt-plus"
     #:trials 260
     #:arity 2
     #:sample (lambda (i)
                (list (rand-int -300 300)
                      (rand-int -300 300)))
     #:check
     (lambda (i vals)
       (define a (first vals))
       (define b (second vals))
       (check-bt-case
        (format "bt-plus/~a" i)
        #:expected-set (lambda ()
                         (list (list (+ a b))))
        #:run-observed
        (lambda (limit)
          (run limit (q)
            (pluso (int->bt-term a) (int->bt-term b) q)))
        #:decode-answer decode-bt-tuple
        #:k 1
        #:k2 1
        #:timeout-ms 4000)))))

(test-case "bt harness assurance: *o randomized over [-120,120]"
  (parameterize ([current-pseudo-random-generator
                  (make-pseudo-random-generator)])
    (random-seed 20260301)
    (check-bt-random
     "bt-mul"
     #:trials 140
     #:arity 2
     #:sample (lambda (i)
                (list (rand-int -120 120)
                      (rand-int -120 120)))
     #:check
     (lambda (i vals)
       (define a (first vals))
       (define b (second vals))
       (check-bt-case
        (format "bt-mul/~a" i)
        #:expected-set (lambda ()
                         (list (list (* a b))))
        #:run-observed
        (lambda (limit)
          (run limit (q)
            (*o (int->bt-term a) (int->bt-term b) q)))
        #:decode-answer decode-bt-tuple
        #:k 1
        #:k2 1
        #:timeout-ms 4000)))))
