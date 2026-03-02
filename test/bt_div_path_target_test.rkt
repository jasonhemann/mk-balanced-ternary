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

(define (check-terminates-equal name expected thunk #:timeout-ms [timeout-ms 2000])
  (define-values (done? out)
    (run-with-timeout timeout-ms thunk))
  (check-true done? (format "~a timed out" name))
  (check-equal? out expected (format "~a wrong answers" name)))

(test-case "div-correcto targeted branch seeds (k=-1,0,1,2)"
  (for ([c '((k-1 -1 4 0 -1 3)
             (k0   2 4 0  0 2)
             (k1   6 4 0  1 2)
             (k2   9 4 0  2 1))])
    (match-define (list tag t m qrest q r) c)
    (check-terminates-equal
     (format "div-correcto/~a" tag)
     (list (list q r))
     (lambda ()
       (map decode-bt-tuple
            (run* (ans)
              (fresh (qq rr)
                (div-correcto (int->bt-term t)
                              (int->bt-term m)
                              (int->bt-term qrest)
                              qq rr
                              div-bound)
                (== ans (list qq rr)))))))))

(test-case "divo path seeds: two-step family around 19/4 closes quickly at run 1"
  ;; 16..19 with divisor 4 all follow the same nonnegative control-flow shape:
  ;; recurse, recurse, base (n<m), with k=1 correction at each step.
  (for ([c '((16 4 4 0)
             (17 4 4 1)
             (18 4 4 2)
             (19 4 4 3))])
    (match-define (list n m q r) c)
    (check-terminates-equal
     (format "divo/run1/~a/~a" n m)
     (list (list q r))
     (lambda ()
       (map decode-bt-tuple
            (run 1 (ans)
              (fresh (qq rr)
                (divo (int->bt-term n)
                      (int->bt-term m)
                      qq rr)
                (== ans (list qq rr)))))))))

(test-case "divo path seeds: fixed quotient isolates remainder quickly"
  (for ([c '((16 4 4 0)
             (17 4 4 1)
             (18 4 4 2)
             (19 4 4 3))])
    (match-define (list n m q r) c)
    (check-terminates-equal
     (format "divo/q-fixed/~a/~a" n m)
     (list (list r))
     (lambda ()
       (map decode-bt
            (run* (rr)
              (divo (int->bt-term n)
                    (int->bt-term m)
                    (int->bt-term q)
                    rr)))))))
