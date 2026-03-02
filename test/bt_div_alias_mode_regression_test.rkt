#lang racket

(require rackunit
         minikanren
         racket/engine
         (file "../src/bt_rel.rkt"))

(define alias-bound '(k k k k))

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

(define (check-run-finite-failure name thunk #:timeout-ms [timeout-ms 1800])
  (check-run-terminates name '() thunk #:timeout-ms timeout-ms))

(test-case "divo alias regression: bounded n=r shared-variable classes close finitely"
  ;; First-principles classification:
  ;; with explicit finite outer bounds on x, these n=r alias queries should
  ;; close as finite success/failure checks.
  (check-run-terminates
   "n=r, m=2, q=0"
   '(() (1))
   (lambda ()
     (run 3 (x)
       (bto-boundedo x alias-bound)
       (divo x (build-num 2) '() x)))
   #:timeout-ms 2500)
  (check-run-terminates
   "n=r, m=-2, q=0"
   '(() (1))
   (lambda ()
     (run 3 (x)
       (bto-boundedo x alias-bound)
       (divo x (build-num -2) '() x)))
   #:timeout-ms 2500)
  (check-run-finite-failure
   "n=r, m=2, q=1"
   (lambda ()
     (run 3 (x)
       (bto-boundedo x alias-bound)
       (divo x (build-num 2) (build-num 1) x)))
   #:timeout-ms 2500)
  (check-run-finite-failure
   "n=r, m=-2, q=1"
   (lambda ()
     (run 3 (x)
       (bto-boundedo x alias-bound)
       (divo x (build-num -2) (build-num 1) x)))
   #:timeout-ms 2500)
  (check-run-finite-failure
   "n=r, m=2, q=-1"
   (lambda ()
     (run 3 (x)
       (bto-boundedo x alias-bound)
       (divo x (build-num 2) (build-num -1) x)))
   #:timeout-ms 2500))
