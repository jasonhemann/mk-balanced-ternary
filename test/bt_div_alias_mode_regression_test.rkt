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

(test-case "divo alias regression: q=1 with n=m=r aliases finitely fails"
  (check-run-terminates
   "n=m=r, q=1"
   '()
   (lambda ()
     (run 3 (x)
       (divo x x (build-num 1) x)))))

(test-case "divo alias regression: m=1 with n=q=r aliases closes after x=0"
  (check-run-terminates
   "m=1, n=q=r"
   '(())
   (lambda ()
     (run 3 (x)
       (divo x (build-num 1) x x)))))

(test-case "divo alias regression: n=1 with m=q=r aliases finitely fails"
  (check-run-terminates
   "n=1, m=q=r"
   '()
   (lambda ()
     (run 3 (x)
       (divo (build-num 1) x x x)))))

(test-case "divo alias regression: r=1 with n=m=q aliases finitely fails"
  (check-run-terminates
   "r=1, n=m=q"
   '()
   (lambda ()
     (run 3 (x)
       (divo x x x (build-num 1))))))

(test-case "divo alias regression: n=r alias with nonzero q finitely fails"
  (check-run-terminates
   "n=r, m=2, q=1"
   '()
   (lambda ()
     (run 3 (x)
       (divo x (build-num 2) (build-num 1) x)))))

(test-case "divo alias regression: n=r alias with q=0 returns bounded prefix"
  (check-run-terminates
   "n=r, m=2, q=0"
   '(() (1))
   (lambda ()
     (run 3 (x)
       (divo x (build-num 2) '() x)))))
