#lang racket

(require (except-in rackunit fail)
         minikanren
         racket/engine
         (only-in racket/list take)
         (file "../src/bt_rel.rkt")
         (file "../test/support/bt_harness.rkt"))

(define (make-bound len)
  (build-list len (lambda (i) 'k)))

(define flows '(bounds-bind-rel bounds-rel-bind bind-bounds-rel))

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

(define (bind-int-if t maybe-int)
  (if maybe-int
      (== t (int->bt-term maybe-int))
      (== t t)))

(define (context len)
  (define b (make-bound len))
  (define m (max-abs-for-len len))
  (define is (int-range (- m) m))
  (define sats
    (for*/list ([x is]
                [y is]
                [z is]
                #:when (= (* x y) z))
      (list x y z)))
  (list b is sats))

(define (run-flow flow bound partial)
  (define x (list-ref partial 0))
  (define y (list-ref partial 1))
  (define z (list-ref partial 2))
  (case flow
    [(bounds-bind-rel)
     (run* (q)
       (fresh (rx ry rz)
         (bto-boundedo rx bound)
         (bto-boundedo ry bound)
         (bto-boundedo rz bound)
         (bind-int-if rx x)
         (bind-int-if ry y)
         (bind-int-if rz z)
         (*o rx ry rz)
         (== q (list rx ry rz))))]
    [(bounds-rel-bind)
     (run* (q)
       (fresh (rx ry rz)
         (bto-boundedo rx bound)
         (bto-boundedo ry bound)
         (bto-boundedo rz bound)
         (*o rx ry rz)
         (bind-int-if rx x)
         (bind-int-if ry y)
         (bind-int-if rz z)
         (== q (list rx ry rz))))]
    [(bind-bounds-rel)
     (run* (q)
       (fresh (rx ry rz)
         (bind-int-if rx x)
         (bind-int-if ry y)
         (bind-int-if rz z)
         (bto-boundedo rx bound)
         (bto-boundedo ry bound)
         (bto-boundedo rz bound)
         (*o rx ry rz)
         (== q (list rx ry rz))))]))

(define (decoded-set raw)
  (sort (remove-duplicates (map decode-bt-tuple raw) equal?)
        string<?
        #:key ~s))

(define (satisfiable-partials ints sat-tuples)
  (for*/list ([mask (bool-masks 3)]
              #:do [(define indices (mask-indices mask))
                    (define assignments
                      (if (null? indices)
                          (list '())
                          (cartesian-product
                           (build-list (length indices) (lambda (i) ints)))))]
              [as assignments]
              #:do [(define partial (partial-from indices as 3))
                    (define expected
                      (for/list ([tuple sat-tuples]
                                 #:when (matches-grounding? tuple mask partial))
                        tuple))]
              #:when (pair? expected))
    (list mask partial expected)))

(define (unsatisfiable-partials ints sat-tuples)
  (for*/list ([mask (bool-masks 3)]
              #:do [(define indices (mask-indices mask))
                    (define assignments
                      (if (null? indices)
                          (list '())
                          (cartesian-product
                           (build-list (length indices) (lambda (i) ints)))))]
              [as assignments]
              #:do [(define partial (partial-from indices as 3))
                    (define expected
                      (for/list ([tuple sat-tuples]
                                 #:when (matches-grounding? tuple mask partial))
                        tuple))]
              #:when (null? expected))
    (list mask partial)))

(define (take-unsat-representatives unsats [per-mask 12])
  (define (score partial)
    (for/sum ([x partial] #:when (integer? x)) (abs x)))
  (define grouped (make-hash))
  (for ([entry unsats])
    (define mask (first entry))
    (hash-set! grouped mask (cons entry (hash-ref grouped mask '()))))
  (apply append
         (for/list ([mask (hash-keys grouped)])
           (define xs
             (sort (reverse (hash-ref grouped mask))
                   <
                   #:key (lambda (e) (score (second e)))))
           (take xs (min per-mask (length xs))))))

(define (take-sat-representatives sats [per-mask 20])
  (define (score partial)
    (for/sum ([x partial] #:when (integer? x)) (abs x)))
  (define grouped (make-hash))
  (for ([entry sats])
    (define mask (first entry))
    (hash-set! grouped mask (cons entry (hash-ref grouped mask '()))))
  (apply append
         (for/list ([mask (hash-keys grouped)])
           (define xs
             (sort (reverse (hash-ref grouped mask))
                   <
                   #:key (lambda (e) (score (second e)))))
           (take xs (min per-mask (length xs))))))

(define (check-flow-complete len timeout-ms [per-mask #f] [flow-set flows])
  (define ctx (context len))
  (define bound (first ctx))
  (define ints (second ctx))
  (define sat-tuples (third ctx))
  (define sat-cases0 (satisfiable-partials ints sat-tuples))
  (define sat-cases
    (if per-mask
        (take-sat-representatives sat-cases0 per-mask)
        sat-cases0))
  (for ([entry sat-cases])
    (define mask (first entry))
    (define partial (second entry))
    (define expected* (sort (third entry) string<? #:key ~s))
    (for ([flow flow-set])
      (define-values (done? raw)
        (run-with-timeout timeout-ms
                          (lambda ()
                            (run-flow flow bound partial))))
      (unless done?
        (fail-check
         (format "len~a/*o/~a timeout for mask ~a partial ~s"
                 len flow (mask->label mask) partial)))
      (define got* (decoded-set raw))
      (unless (equal? got* expected*)
        (fail-check
         (format "len~a/*o/~a mismatch for mask ~a partial ~s; expected ~s got ~s"
                 len flow (mask->label mask) partial expected* got*))))))

(define (check-finite-failure-representatives len timeout-ms [flow-set flows])
  (define ctx (context len))
  (define bound (first ctx))
  (define ints (second ctx))
  (define sat-tuples (third ctx))
  (define unsats (unsatisfiable-partials ints sat-tuples))
  (define reps (take-unsat-representatives unsats 12))
  (for ([entry reps])
    (define mask (first entry))
    (define partial (second entry))
    (for ([flow flow-set])
      (define-values (done? raw)
        (run-with-timeout timeout-ms
                          (lambda ()
                            (run-flow flow bound partial))))
      (unless done?
        (fail-check
         (format "len~a/*o/~a unsat timeout for mask ~a partial ~s"
                 len flow (mask->label mask) partial)))
      (unless (null? raw)
        (fail-check
         (format "len~a/*o/~a expected finite failure for mask ~a partial ~s; got ~s"
                 len flow (mask->label mask) partial raw))))))

(test-case "bt assurance: *o satisfiable mode instances are flow-complete (len<=2)"
  ;; For every satisfiable bounded grounding instance in every mode, each flow
  ;; ordering must terminate and return the exact expected answer set.
  (check-flow-complete 2 500))

(test-case "bt assurance: *o satisfiable mode instances are flow-complete (len<=3)"
  ;; Confidence bump over a wider bounded universe.
  ;; Use fixed representative satisfiable cases per mode mask to keep runtime
  ;; practical while still checking every mode and flow ordering.
  (check-flow-complete 3 1800 8 '(bounds-bind-rel bind-bounds-rel)))

(test-case "bt assurance: *o representative finite-failure checks across flows (len<=3)"
  ;; Full unsat exhaustiveness at len<=3 is expensive; this checks a fixed
  ;; representative unsat set per mode mask and flow ordering.
  (check-finite-failure-representatives 3 1800 '(bounds-bind-rel bind-bounds-rel)))

(test-case "bt assurance: *o len<=3 bounds-rel-bind smoke checks"
  ;; This flow ordering is much slower at len<=3, so keep it as a focused smoke
  ;; check in addition to the fuller representative checks above.
  (define len 3)
  (define bound (make-bound len))
  (define timeout-ms 12000)
  (define sat-partials
    '((1 1 1)
      (-1 0 0)))
  (define unsat-partials
    '((1 1 2)
      (0 -1 -1)))
  (for ([partial sat-partials])
    (define-values (done? raw)
      (run-with-timeout timeout-ms
                        (lambda ()
                          (run-flow 'bounds-rel-bind bound partial))))
    (unless done?
      (fail-check
       (format "len3/*o/bounds-rel-bind sat timeout for partial ~s" partial)))
    (unless (pair? raw)
      (fail-check
       (format "len3/*o/bounds-rel-bind expected sat result for partial ~s"
               partial))))
  (for ([partial unsat-partials])
    (define-values (done? raw)
      (run-with-timeout timeout-ms
                        (lambda ()
                          (run-flow 'bounds-rel-bind bound partial))))
    (unless done?
      (fail-check
       (format "len3/*o/bounds-rel-bind unsat timeout for partial ~s" partial)))
    (unless (null? raw)
      (fail-check
       (format "len3/*o/bounds-rel-bind expected finite failure for partial ~s; got ~s"
               partial raw)))))
