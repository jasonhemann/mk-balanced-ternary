#lang racket

(require (except-in rackunit fail)
         minikanren
         (file "../src/bt_rel.rkt")
         (file "../src/bt_div_structural.rkt")
         (file "support/bt_harness.rkt"))

(define-syntax-rule (divo-test-case name body ...)
  (test-case name body ...))

(define (make-bound len)
  (build-list len (lambda (i) 'k)))

(define bound (make-bound 4))
(define maxabs (max-abs-for-len 4))
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

(define (run-div rel partial limit)
  (define n0 (list-ref partial 0))
  (define m0 (list-ref partial 1))
  (define q0 (list-ref partial 2))
  (define r0 (list-ref partial 3))
  (run limit (ans)
    (fresh (n m q r)
      (bind-int-if n n0)
      (bind-int-if m m0)
      (bind-int-if q q0)
      (bind-int-if r r0)
      (bto-boundedo n bound)
      (bto-boundedo m bound)
      (rel n m q r)
      (bto-boundedo q bound)
      (bto-boundedo r bound)
      (== ans (list n m q r)))))

(divo-test-case "bt div mode matrix: dual implementation parity on ground + bounded inverse masks"
  (define seeds
    (list
     ;; Chosen for stable fast closure while exercising sign variants.
     (list "pos" '(11 4 2 3))
     (list "neg-n" '(-11 4 -3 1))
     (list "neg-m" '(11 -4 -2 3))
     (list "both-neg" '(-11 -4 3 1))))
  (define implementations
    (list (list "main" divo)
          (list "struct" divo-structo)))
  (define masks
    (list
     '(#t #t #t #t) ; gggg
     '(#t #t #f #f) ; ggvv
     '(#t #t #t #f) ; gggv
     '(#t #t #f #t))) ; ggvg
  (for ([impl-entry implementations])
    (define impl-label (first impl-entry))
    (define rel (second impl-entry))
    (for ([seed-entry seeds])
      (define seed-label (first seed-entry))
      (define seed (second seed-entry))
      (for ([mask masks])
        (define partial (partial-from-mask seed mask))
        (define expected (expected-div partial))
        (check-true (pair? expected))
        (check-bt-case-strict
         (format "divo/modes/~a/~a/~a" impl-label seed-label (mask->label mask))
         #:expected-set expected
         #:run-observed (lambda (limit)
                          (run-div rel partial limit))
         #:decode-answer decode-bt-tuple
         #:k 1
         #:k2 1
         #:timeout-ms 6000)))))
