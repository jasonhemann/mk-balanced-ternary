#lang racket

(require rackunit
         minikanren
         racket/engine
         (file "../src/bt_rel.rkt"))

(define (run-with-timeout timeout-ms thunk)
  (define e (engine (lambda (_stop) (thunk))))
  (define done? (engine-run timeout-ms e))
  (define out (and done? (engine-result e)))
  (engine-kill e)
  (values done? out))

(define (check-run-terminates name expected thunk #:timeout-ms [timeout-ms 1800])
  (define-values (done? out)
    (run-with-timeout timeout-ms thunk))
  (check-true done? (format "~a timed out" name))
  (check-equal? out expected (format "~a wrong answers" name)))

(test-case "divo alias regression: n=r alias with q=0 returns bounded prefix"
  (check-run-terminates
   "n=r, m=2, q=0"
   '(() (1))
   (lambda ()
     (run 3 (x)
       (divo x (build-num 2) '() x)))))
