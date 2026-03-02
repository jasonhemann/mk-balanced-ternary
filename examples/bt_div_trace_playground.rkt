#lang racket

(require minikanren
         racket/engine
         (file "../src/bt_rel.rkt")
         (file "../test/support/bt_harness.rkt"))

(provide (all-defined-out))

;; Small trace-oriented helpers:
;; - keep recursion depth/branching tight
;; - isolate exact vs inexact remainder paths
;; - use disequality constraints in playground queries where useful

(define div-bound '(k k k k k k))

(define (run-with-timeout timeout-ms thunk)
  (define e (engine (lambda (_stop) (thunk))))
  (define done? (engine-run timeout-ms e))
  (define out (and done? (engine-result e)))
  (engine-kill e)
  (values done? out))

(define (show label v)
  (printf "~a\n  ~s\n" label v)
  v)

(define (show-query label thunk #:timeout-ms [timeout-ms 3000] #:decoder [decoder values])
  (define-values (done? out)
    (run-with-timeout timeout-ms thunk))
  (show label
        (if done?
            (map decoder out)
            'timeout)))

(define div-correcto-seeds
  ;; (tag t m qrest) for k = -1, 0, 1, 2 in div-correcto.
  '((k-1 -1 4 0)
    (k0   2 4 0)
    (k1   6 4 0)
    (k2   9 4 0)))

(define (trace-div-correcto-seeds)
  (for/list ([s div-correcto-seeds])
    (match-define (list tag t m qrest) s)
    (show-query
     (format "div-correcto/~a" tag)
     (lambda ()
       (run* (ans)
         (fresh (q r)
           (div-correcto (int->bt-term t)
                         (int->bt-term m)
                         (int->bt-term qrest)
                         q r
                         div-bound)
           (== ans (list q r)))))
     #:decoder decode-bt-tuple)))

(define two-step-family
  ;; Same nonnegative path shape as 19/4: recurse, recurse, base, k=1, k=1.
  '((16 4)
    (17 4)
    (18 4)
    (19 4)))

(define (trace-two-step-family-run1)
  (for/list ([nm two-step-family])
    (match-define (list n m) nm)
    (show-query
     (format "run1 divo ~a/~a" n m)
     (lambda ()
       (run 1 (ans)
         (fresh (q r)
           (divo (int->bt-term n) (int->bt-term m) q r)
           (== ans (list q r)))))
     #:decoder decode-bt-tuple)))

(define (trace-two-step-family-run2)
  ;; Useful when you want to inspect the nonproductive tail after first answer.
  (for/list ([nm two-step-family])
    (match-define (list n m) nm)
    (show-query
     (format "run2 divo ~a/~a" n m)
     (lambda ()
       (run 2 (ans)
         (fresh (q r)
           (divo (int->bt-term n) (int->bt-term m) q r)
           (== ans (list q r)))))
     #:timeout-ms 5000
     #:decoder decode-bt-tuple)))

(define (trace-q-fixed-remainder-family)
  ;; Fix q=4 to jump directly into remainder behavior for 16..19 over divisor 4.
  (for/list ([n '(16 17 18 19)])
    (show-query
     (format "q-fixed remainder ~a/4 q=4" n)
     (lambda ()
       (run* (r)
         (divo (int->bt-term n)
               (int->bt-term 4)
               (int->bt-term 4)
               r)))
     #:decoder decode-bt)))

(define (trace-exclude-known-19/4)
  ;; Disequality in tests/playground is allowed and helps jump to branch tails.
  (show-query
   "exclude known solution for 19/4 (q =/= 4)"
   (lambda ()
     (run 1 (ans)
       (fresh (q r)
         (divo (int->bt-term 19) (int->bt-term 4) q r)
         (=/= q (int->bt-term 4))
         (== ans (list q r)))))
   #:timeout-ms 5000
   #:decoder decode-bt-tuple))
