#lang racket

(require (except-in rackunit fail)
         minikanren
         (file "../src/bt_rel.rkt")
         (file "support/bt_harness.rkt"))

(define (make-bound len)
  (build-list len (lambda (i) 'k)))

(define bound (make-bound 2))
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

(define (mode-limits expected)
  (define n (max 1 (length (remove-duplicates expected equal?))))
  (values (min 20 n) (max (+ n 12) (* 10 n))))

(define (run-div partial limit)
  (define n0 (list-ref partial 0))
  (define m0 (list-ref partial 1))
  (define q0 (list-ref partial 2))
  (define r0 (list-ref partial 3))
  (run limit (ans)
    (fresh (n m q r)
      (bto-boundedo n bound)
      (bto-boundedo m bound)
      (bto-boundedo q bound)
      (bto-boundedo r bound)
      (bind-int-if n n0)
      (bind-int-if m m0)
      (bind-int-if q q0)
      (bind-int-if r r0)
      (divo n m q r bound)
      (== ans (list n m q r)))))

(test-case "bt div mode matrix: Euclidean modes for representative seeds"
  (define seeds
    (list
     (list "pos" '(4 3 1 1))
     (list "neg-n" '(-4 3 -2 2))
     (list "neg-m" '(-4 -3 2 2))))
  (for ([seed-entry seeds])
    (define seed-label (first seed-entry))
    (define seed (second seed-entry))
    (for ([mask (bool-masks 4)])
      (define partial (partial-from-mask seed mask))
      (define expected (expected-div partial))
      (check-true (pair? expected))
      (define-values (k k2) (mode-limits expected))
      (check-bt-case-strict
       (format "divo/modes/~a/~a" seed-label (mask->label mask))
       #:expected-set expected
       #:run-observed (lambda (limit)
                        (run-div partial limit))
       #:decode-answer decode-bt-tuple
       #:k k
       #:k2 k2
       #:timeout-ms 3500))))
