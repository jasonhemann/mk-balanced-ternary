#lang racket

(require (except-in rackunit fail)
         minikanren
         (file "../src/binary-numbers.rkt")
         (file "support/bn_harness.rkt"))

(define bits '(0 1))

(define (expected-add3 b x y)
  (define total (+ b x y))
  (list (list (modulo total 2)
              (quotient total 2))))

(test-case "bn harness primitives: add3o truth table"
  (for* ([b bits]
         [x bits]
         [y bits])
    (check-bn-case
     (format "add3o/~a~a~a" b x y)
     #:expected-set (lambda ()
                      (expected-add3 b x y))
     #:run-observed (lambda (limit)
                      (run limit (q)
                        (fresh (r c)
                          (add3o b x y r c)
                          (== q (list r c)))))
     #:decode-answer (lambda (raw)
                       raw))))

(test-case "bn harness primitives: full-addero matches add3o semantics"
  (for* ([b bits]
         [x bits]
         [y bits])
    (check-bn-case
     (format "full-addero/~a~a~a" b x y)
     #:expected-set (lambda ()
                      (expected-add3 b x y))
     #:run-observed (lambda (limit)
                      (run limit (q)
                        (fresh (r c)
                          (full-addero b x y r c)
                          (== q (list r c)))))
     #:decode-answer (lambda (raw)
                       raw))))

;; Temporary harness meta-tests. Remove after the framework has been exercised
;; by additional relation suites.
(test-case "bn harness meta: spurious detection fails when triggered"
  (check-exn
   exn:fail?
   (lambda ()
     (check-bn-case
      "meta/spurious"
      #:expected-set (lambda ()
                       (list (list 1)))
      #:run-observed (lambda (limit)
                       (run 1 (q)
                         (== q '())))
      #:decode-answer decode-bn-tuple))))

(test-case "bn harness meta: missing answers emit warning"
  (reset-bn-warnings!)
  (check-bn-case
   "meta/missing"
   #:expected-set (lambda ()
                    (list (list 0)
                          (list 1)))
   #:run-observed (lambda (limit)
                    (list '()))
   #:decode-answer decode-bn-tuple
   #:k 1
   #:k2 2)
  (check-not-equal? (bn-warnings) '()))

(test-case "bn harness meta: timeout classification emits warning"
  (reset-bn-warnings!)
  (check-bn-case
   "meta/timeout"
   #:expected-set (lambda ()
                    '())
   #:run-observed (lambda (limit)
                    (let loop ()
                      (loop)))
   #:decode-answer (lambda (raw)
                     raw)
   #:timeout-ms 20
   #:k 1
   #:k2 2)
  (check-not-equal? (bn-warnings) '()))
