#lang racket

(require rackunit
         minikanren
         racket/engine
         (file "../src/bt_rel.rkt")
         (file "support/bt_harness.rkt"))

(define div-bound '(k k k k k k))

(define (run-with-timeout timeout-ms thunk)
  (define e (engine (lambda (_stop) (thunk))))
  (define done? (engine-run timeout-ms e))
  (define out (and done? (engine-result e)))
  (engine-kill e)
  (values done? out))

(define (check-fast-empty name thunk #:timeout-ms [timeout-ms 1500])
  (define-values (done? out)
    (run-with-timeout timeout-ms thunk))
  (check-true done? (format "~a timed out" name))
  (check-equal? out '() (format "~a expected finite failure" name)))

(test-case "divo branch pruning: exact branches reject nonzero remainder quickly"
  ;; If these branches accidentally delay remainder-shape pruning, they tend to
  ;; wander before failing; this catches that regression path directly.
  (for ([c '((1a-exact 8 2 4)
             (1b-exact -8 2 -4)
             (2a-exact 8 -2 -4)
             (2b-exact -8 -2 4))])
    (match-define (list tag n m q) c)
    (check-fast-empty
     (format "~a: force nonzero r on exact quotient" tag)
     (lambda ()
       (run* (r)
         (divo-boundedo (int->bt-term n)
                        (int->bt-term m)
                        (int->bt-term q)
                        r
                        div-bound)
         (nonzeroo r))))))

(test-case "divo branch pruning: inexact branches reject zero remainder quickly"
  (for ([c '((1a-inexact 7 4 1)
             (1b-inexact -7 4 -2)
             (2a-inexact 7 -4 -1)
             (2b-inexact -7 -4 2))])
    (match-define (list tag n m q) c)
    (check-fast-empty
     (format "~a: force r=0 on inexact quotient" tag)
     (lambda ()
       (run* (r)
         (divo-boundedo (int->bt-term n)
                        (int->bt-term m)
                        (int->bt-term q)
                        r
                        div-bound)
         (== r '()))))))
