#lang racket

(require (except-in rackunit fail)
         minikanren
         racket/engine
         (file "../src/bt_rel.rkt")
         (file "../test/support/bt_harness.rkt"))

(define (run-with-timeout timeout-ms thunk)
  (define e (engine (lambda (enable-stop) (thunk))))
  (define done? (engine-run timeout-ms e))
  (define out (and done? (engine-result e)))
  (engine-kill e)
  (values done? out))

(define (bool-masks n)
  (for/list ([k (in-range (expt 2 n))])
    (for/list ([i (in-range n)])
      (not (zero? (bitwise-and k (arithmetic-shift 1 i)))))))

(define (mask->label mask)
  (list->string
   (map (lambda (g) (if g #\g #\v))
        mask)))

(define (mask-indices mask)
  (for/list ([g mask] [i (in-naturals)] #:when g) i))

(define (partial-from indices assignment arity)
  (define vec (make-vector arity #f))
  (for ([idx indices] [v assignment])
    (vector-set! vec idx v))
  (vector->list vec))

(define (matches-grounding? tuple mask partial)
  (for/and ([g mask] [tv tuple] [pv partial])
    (if g (equal? tv pv) #t)))

(define (unsat-cases arity sat-tuples domains)
  (for*/list ([mask (bool-masks arity)]
              #:unless (andmap not mask)
              #:do [(define indices (mask-indices mask))
                    (define assignments
                      (if (null? indices)
                          (list '())
                          (cartesian-product
                           (for/list ([idx indices])
                             (list-ref domains idx)))))]
              [as assignments]
              #:do [(define partial (partial-from indices as arity))]
              #:unless (ormap (lambda (tuple)
                                (matches-grounding? tuple mask partial))
                              sat-tuples))
    (list mask partial)))

(define (bind-int-if t maybe-int)
  (if maybe-int
      (== t (int->bt-term maybe-int))
      (== t t)))

(define (bind-trit-if t maybe-trit)
  (if maybe-trit
      (== t maybe-trit)
      (== t t)))

(define trits '(T 0 1))
(define bound-len 2)
(define bound (build-list bound-len (lambda (i) 'k)))
(define maxabs (max-abs-for-len bound-len))
(define ints (int-range (- maxabs) maxabs))

(define primitive-flows
  '(domain-bind-rel
    domain-rel-bind
    bind-domain-rel))

(define (assert-finite-failure! timeout-ms label thunk)
  (define-values (done? out)
    (run-with-timeout timeout-ms thunk))
  (unless done?
    (fail-check (format "~a timed out after ~ams" label timeout-ms)))
  (unless (null? out)
    (fail-check (format "~a expected finite failure, got ~s" label out))))

(define add3-sat-tuples
  (for*/list ([a trits]
              [b trits]
              [cin trits]
              [s trits]
              [cout trits]
              #:when
              (= (+ (if (eq? a 'T) -1 (if (equal? a 0) 0 1))
                    (if (eq? b 'T) -1 (if (equal? b 0) 0 1))
                    (if (eq? cin 'T) -1 (if (equal? cin 0) 0 1)))
                 (+ (if (eq? s 'T) -1 (if (equal? s 0) 0 1))
                    (* 3 (if (eq? cout 'T) -1 (if (equal? cout 0) 0 1))))))
    (list a b cin s cout)))

(define mul1-sat-tuples
  (for*/list ([x ints]
              [b trits]
              [out ints]
              #:when
              (= (* x (if (eq? b 'T) -1 (if (equal? b 0) 0 1)))
                 out))
    (list x b out)))

(define nego-sat-tuples
  (for*/list ([x ints]
              [y ints]
              #:when (= y (- x)))
    (list x y)))

(define (run-add3 flow partial)
  (define a0 (list-ref partial 0))
  (define b0 (list-ref partial 1))
  (define cin0 (list-ref partial 2))
  (define s0 (list-ref partial 3))
  (define cout0 (list-ref partial 4))
  (case flow
    [(domain-bind-rel)
     (run* (q)
       (fresh (a b cin s cout)
         (trito a) (trito b) (trito cin) (trito s) (trito cout)
         (bind-trit-if a a0)
         (bind-trit-if b b0)
         (bind-trit-if cin cin0)
         (bind-trit-if s s0)
         (bind-trit-if cout cout0)
         (add3o a b cin s cout)
         (== q (list a b cin s cout))))]
    [(domain-rel-bind)
     (run* (q)
       (fresh (a b cin s cout)
         (trito a) (trito b) (trito cin) (trito s) (trito cout)
         (add3o a b cin s cout)
         (bind-trit-if a a0)
         (bind-trit-if b b0)
         (bind-trit-if cin cin0)
         (bind-trit-if s s0)
         (bind-trit-if cout cout0)
         (== q (list a b cin s cout))))]
    [(bind-domain-rel)
     (run* (q)
       (fresh (a b cin s cout)
         (bind-trit-if a a0)
         (bind-trit-if b b0)
         (bind-trit-if cin cin0)
         (bind-trit-if s s0)
         (bind-trit-if cout cout0)
         (trito a) (trito b) (trito cin) (trito s) (trito cout)
         (add3o a b cin s cout)
         (== q (list a b cin s cout))))]))

(define (run-mul1 flow partial)
  (define x0 (list-ref partial 0))
  (define b0 (list-ref partial 1))
  (define out0 (list-ref partial 2))
  (case flow
    [(domain-bind-rel)
     (run* (q)
       (fresh (x b out)
         (bto-boundedo x bound)
         (trito b)
         (bto-boundedo out bound)
         (bind-int-if x x0)
         (bind-trit-if b b0)
         (bind-int-if out out0)
         (mul1o x b out)
         (== q (list x b out))))]
    [(domain-rel-bind)
     (run* (q)
       (fresh (x b out)
         (bto-boundedo x bound)
         (trito b)
         (bto-boundedo out bound)
         (mul1o x b out)
         (bind-int-if x x0)
         (bind-trit-if b b0)
         (bind-int-if out out0)
         (== q (list x b out))))]
    [(bind-domain-rel)
     (run* (q)
       (fresh (x b out)
         (bind-int-if x x0)
         (bind-trit-if b b0)
         (bind-int-if out out0)
         (bto-boundedo x bound)
         (trito b)
         (bto-boundedo out bound)
         (mul1o x b out)
         (== q (list x b out))))]))

(define (run-nego flow partial)
  (define x0 (list-ref partial 0))
  (define y0 (list-ref partial 1))
  (case flow
    [(domain-bind-rel)
     (run* (q)
       (fresh (x y)
         (bto-boundedo x bound)
         (bto-boundedo y bound)
         (bind-int-if x x0)
         (bind-int-if y y0)
         (nego x y)
         (== q (list x y))))]
    [(domain-rel-bind)
     (run* (q)
       (fresh (x y)
         (bto-boundedo x bound)
         (bto-boundedo y bound)
         (nego x y)
         (bind-int-if x x0)
         (bind-int-if y y0)
         (== q (list x y))))]
    [(bind-domain-rel)
     (run* (q)
       (fresh (x y)
         (bind-int-if x x0)
         (bind-int-if y y0)
         (bto-boundedo x bound)
         (bto-boundedo y bound)
         (nego x y)
         (== q (list x y))))]))

(test-case "bt primitive assurance: add3o finite-failure matrix across modes and flow order"
  (define unsat (unsat-cases 5 add3-sat-tuples
                             (list trits trits trits trits trits)))
  (check-true (pair? unsat))
  (for ([flow primitive-flows]
        [i (in-naturals)])
    (void i)
    (for ([entry unsat])
      (define mask (first entry))
      (define partial (second entry))
      (assert-finite-failure!
       300
       (format "add3o/~a/~a/~s" flow (mask->label mask) partial)
       (lambda ()
         (run-add3 flow partial))))))

(test-case "bt primitive assurance: mul1o finite-failure matrix across modes and flow order"
  (define unsat (unsat-cases 3 mul1-sat-tuples
                             (list ints trits ints)))
  (check-true (pair? unsat))
  (for ([flow primitive-flows])
    (for ([entry unsat])
      (define mask (first entry))
      (define partial (second entry))
      (assert-finite-failure!
       300
       (format "mul1o/~a/~a/~s" flow (mask->label mask) partial)
       (lambda ()
         (run-mul1 flow partial))))))

(test-case "bt primitive assurance: nego finite-failure matrix across modes and flow order"
  (define unsat (unsat-cases 2 nego-sat-tuples
                             (list ints ints)))
  (check-true (pair? unsat))
  (for ([flow primitive-flows])
    (for ([entry unsat])
      (define mask (first entry))
      (define partial (second entry))
      (assert-finite-failure!
       300
       (format "nego/~a/~a/~s" flow (mask->label mask) partial)
       (lambda ()
         (run-nego flow partial))))))
