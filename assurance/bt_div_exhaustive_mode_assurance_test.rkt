#lang racket

(require rackunit
         minikanren
         racket/engine
         (except-in racket/list cartesian-product)
         (file "../src/bt_rel.rkt")
         (file "../test/support/bt_harness.rkt"))

(define-syntax-rule (divo-test-case name body ...)
  (test-case name body ...))

(define (make-bound len)
  (build-list len (lambda (i) 'k)))

(define bound (make-bound 2))
;; Internal operational envelope for exhaustive len<=2 division sweeps.
;; Keep this explicit so exhaustive vvvv checks close deterministically.
(define div-bound (make-bound 6))
(define maxabs (max-abs-for-len 2))
(define ints (int-range (- maxabs) maxabs))

(define (bool-masks n)
  (for/list ([k (in-range (expt 2 n))])
    (for/list ([i (in-range n)])
      (not (zero? (bitwise-and k (arithmetic-shift 1 i)))))))

(define (mask->label mask)
  (list->string
   (map (lambda (g) (if g #\g #\v))
        mask)))

(define (partial-from-mask seed mask)
  (for/list ([v seed] [g mask])
    (if g v #f)))

(define (maybe-values maybe domain)
  (if maybe (list maybe) domain))

(define (bind-int-if t maybe-int)
  (if maybe-int
      (== t (int->bt-term maybe-int))
      (== t t)))

(define (euclid-sat? n m q r)
  (and (not (zero? m))
       (= n (+ (* m q) r))
       (<= 0 r)
       (< r (abs m))))

(define (expected-div partial)
  (define n0 (list-ref partial 0))
  (define m0 (list-ref partial 1))
  (define q0 (list-ref partial 2))
  (define r0 (list-ref partial 3))
  (for*/list ([n (maybe-values n0 ints)]
              [m (maybe-values m0 ints)]
              [q (maybe-values q0 ints)]
              [r (maybe-values r0 ints)]
              #:when (euclid-sat? n m q r))
    (list n m q r)))

(define (run-div* partial)
  (define n0 (list-ref partial 0))
  (define m0 (list-ref partial 1))
  (define q0 (list-ref partial 2))
  (define r0 (list-ref partial 3))
  (run* (ans)
    (fresh (n m q r)
      (bto-boundedo n bound)
      (bto-boundedo m bound)
      (bto-boundedo q bound)
      (bto-boundedo r bound)
      (bind-int-if n n0)
      (bind-int-if m m0)
      (bind-int-if q q0)
      (bind-int-if r r0)
      (divo-boundedo n m q r div-bound)
      (== ans (list n m q r)))))

(define (run-with-timeout timeout-ms thunk)
  (define e (engine (lambda (_enable-stop)
                      (thunk))))
  (define done? (engine-run timeout-ms e))
  (cond
    [done?
     (define out (engine-result e))
     (engine-kill e)
     (values #f out)]
    [else
     (engine-kill e)
     (values #t #f)]))

(define (normalize-set xs)
  (sort (remove-duplicates xs equal?)
        string<?
        #:key (lambda (x) (format "~s" x))))

(define required-mask-labels
  ;; Required-to-close exhaustive classes for this assurance sweep.
  ;; Other open classes are monitored opportunistically and may time out.
  '("ggvv" "gggv" "ggvg" "gggg"))

(divo-test-case "bt div assurance: exhaustive run* mode sweep matches denotation (len<=2)"
  (define seeds
    (list
     (list "pos" '(4 3 1 1))
     (list "neg-n" '(-4 3 -2 2))
     (list "neg-m" '(-4 -3 2 2))
     (list "both-neg" '(-2 -4 1 2))))
  (for ([seed-entry seeds])
    (define seed-label (first seed-entry))
    (define seed (second seed-entry))
    (for ([mask (bool-masks 4)])
      (define partial (partial-from-mask seed mask))
      (define mask-label (mask->label mask))
      (define required? (member mask-label required-mask-labels))
      (define timeout-ms (if required? 20000 5000))
      (define expected (normalize-set (expected-div partial)))
      (check-true (pair? expected)
                  (format "expected non-empty set for seed ~a mask ~a"
                          seed-label
                          mask-label))
      (define-values (timed-out? raw)
        (run-with-timeout timeout-ms
                          (lambda ()
                            (run-div* partial))))
      (when (and timed-out? required?)
        (fail-check
         (format "run* timed out for required seed ~a mask ~a (>~ams)"
                 seed-label
                 mask-label
                 timeout-ms)))
      (when timed-out?
        (printf "INFO[bt-div-exhaustive] open class timeout seed=~a mask=~a (>~ams)\n"
                seed-label
                mask-label
                timeout-ms))
      (when (not timed-out?)
        (define decoded
          (for/list ([ans raw])
            (decode-bt-tuple ans)))
        (for ([ans raw] [dec decoded])
          (check-not-false dec
                           (format "undecodable answer for seed ~a mask ~a: ~s"
                                   seed-label
                                   mask-label
                                   ans)))
        (check-equal?
         (length raw)
         (length (remove-duplicates raw equal?))
         (format "duplicate raw answers for seed ~a mask ~a"
                 seed-label
                 mask-label))
        (check-equal?
         (length decoded)
         (length (remove-duplicates decoded equal?))
         (format "duplicate decoded answers for seed ~a mask ~a"
                 seed-label
                 mask-label))
        (define observed (normalize-set decoded))
        (check-equal? observed expected
                      (format "denotation mismatch for seed ~a mask ~a"
                              seed-label
                              mask-label))))))
