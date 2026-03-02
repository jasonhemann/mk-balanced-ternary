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

(define (check-finite-success name expected thunk #:timeout-ms [timeout-ms 700])
  (define-values (done? out)
    (run-with-timeout timeout-ms thunk))
  (check-true done? (format "~a timed out" name))
  (check-equal? out expected (format "~a wrong answers" name)))

(define (check-finite-failure name thunk #:timeout-ms [timeout-ms 700])
  (check-finite-success name '() thunk #:timeout-ms timeout-ms))

(define (check-expected-divergence name thunk #:timeout-ms [timeout-ms 300])
  (define-values (done? out)
    (run-with-timeout timeout-ms thunk))
  (check-false done?
               (format "~a unexpectedly completed with ~s" name out)))

(test-case "bt alias operational: finite success representatives"
  (check-finite-success
   "pluso 0+0=0"
   '(ok)
   (lambda ()
     (run 1 (w)
       (pluso '() '() '())
       (== w 'ok))))
  (check-finite-success
   "minuso 0-0=0"
   '(ok)
   (lambda ()
     (run 1 (w)
       (minuso '() '() '())
       (== w 'ok))))
  (check-finite-success
   "*o 1*1=1"
   '(ok)
   (lambda ()
     (run 1 (w)
       (*o '(1) '(1) '(1))
       (== w 'ok)))))

(test-case "bt alias operational: finite failure representatives"
  (check-finite-failure
   "pluso 1+1=/=1"
   (lambda ()
     (run 1 (w)
       (pluso '(1) '(1) '(1))
       (== w 'ok))))
  (check-finite-failure
   "minuso 1-1=/=1"
   (lambda ()
     (run 1 (w)
       (minuso '(1) '(1) '(1))
       (== w 'ok))))
  (check-finite-failure
   "*o 1*1=/=0"
   (lambda ()
     (run 1 (w)
       (*o '(1) '(1) '())
       (== w 'ok))))
  (check-finite-failure
   "divo impossible ground witness"
   (lambda ()
     (run 1 (w)
       (divo '(1) '(1) '() '(1))
       (== w 'ok)))))

(test-case "bt alias operational: expected divergence representatives"
  ;; Under pure-unification search, these shared-variable aliases are
  ;; operationally open and are not required to close unboundedly.
  (check-expected-divergence
   "pluso q q q run 2"
   (lambda ()
     (run 2 (q)
       (pluso q q q))))
  (check-expected-divergence
   "minuso q q q run 2"
   (lambda ()
     (run 2 (q)
       (minuso q q q))))
  (check-expected-divergence
   "*o q q q run 3"
   (lambda ()
     (run 3 (q)
       (*o q q q))))
  (check-expected-divergence
   "divo n=r, m=2, q=0 (bounded x, run 3)"
   (lambda ()
     (run 3 (x)
       (bto-boundedo x alias-bound)
       (divo x (build-num 2) '() x)))
   #:timeout-ms 1800)
  (check-expected-divergence
   "divo n=r, m=-2, q=0 (bounded x, run 3)"
   (lambda ()
     (run 3 (x)
       (bto-boundedo x alias-bound)
       (divo x (build-num -2) '() x)))
   #:timeout-ms 1800)
  (check-expected-divergence
   "divo n=r, m=2, q=1 (bounded x, run 3)"
   (lambda ()
     (run 3 (x)
       (bto-boundedo x alias-bound)
       (divo x (build-num 2) (build-num 1) x)))
   #:timeout-ms 1800)
  (check-expected-divergence
   "divo n=r, m=-2, q=1 (bounded x, run 3)"
   (lambda ()
     (run 3 (x)
       (bto-boundedo x alias-bound)
       (divo x (build-num -2) (build-num 1) x)))
   #:timeout-ms 1800)
  (check-expected-divergence
   "divo n=r, m=2, q=-1 (bounded x, run 3)"
   (lambda ()
     (run 3 (x)
       (bto-boundedo x alias-bound)
       (divo x (build-num 2) (build-num -1) x)))
   #:timeout-ms 1800)
  (check-expected-divergence
   "divo q=q*q+0 alias stream (run 2)"
   (lambda ()
     (run 2 (q)
       (divo q q q '()))))
  (check-expected-divergence
   "divo q=q, quotient 1, remainder q (run 1)"
   (lambda ()
     (run 1 (w)
       (fresh (q)
         (divo q q (build-num 1) q)
         (== w 'ok)))))
  (check-expected-divergence
   "divo n=m=r, q=1 (run 3)"
   (lambda ()
     (run 3 (x)
       (divo x x (build-num 1) x))))
  (check-expected-divergence
   "divo m=1, n=q=r (run 3)"
   (lambda ()
     (run 3 (x)
       (divo x (build-num 1) x x))))
  (check-expected-divergence
   "divo n=1, m=q=r (run 3)"
   (lambda ()
     (run 3 (x)
       (divo (build-num 1) x x x))))
  (check-expected-divergence
   "divo r=1, n=m=q (run 3)"
   (lambda ()
     (run 3 (x)
       (divo x x x (build-num 1))))))
