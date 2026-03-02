#lang racket

(require (except-in rackunit fail)
         minikanren
         racket/engine
         (file "../src/bt_rel.rkt")
         (file "../test/support/bt_harness.rkt"))

(define (make-bound len)
  (build-list len (lambda (i) 'k)))

;; Exhaustive bounded universe for flow-completeness checks.
;; len=2 => integers in [-4,4].
(define bound (make-bound 2))
(define maxabs (max-abs-for-len 2))
(define ints (int-range (- maxabs) maxabs))

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

(define (sat-tuples op)
  (for*/list ([x ints]
              [y ints]
              [z ints]
              #:when
              (case op
                [(pluso) (= (+ x y) z)]
                [(minuso) (= (- x y) z)]))
    (list x y z)))

(define (bind-int-if t maybe-int)
  (if maybe-int
      (== t (int->bt-term maybe-int))
      (== t t)))

(define (run-op flow op partial)
  (define x (list-ref partial 0))
  (define y (list-ref partial 1))
  (define z (list-ref partial 2))
  (define (goal rx ry rz)
    (case op
      [(pluso) (pluso rx ry rz)]
      [(minuso) (minuso rx ry rz)]))
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
         (goal rx ry rz)
         (== q (list rx ry rz))))]
    [(bounds-rel-bind)
     (run* (q)
       (fresh (rx ry rz)
         (bto-boundedo rx bound)
         (bto-boundedo ry bound)
         (bto-boundedo rz bound)
         (goal rx ry rz)
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
         (goal rx ry rz)
         (== q (list rx ry rz))))]))

(define (decoded-set raw)
  (sort (remove-duplicates (map decode-bt-tuple raw) equal?)
        string<?
        #:key ~s))

(test-case "bt assurance: pluso/minuso satisfiable mode instances are flow-complete (len<=2)"
  ;; For every satisfiable bounded grounding instance in every mode, each flow
  ;; ordering must terminate and return the exact expected answer set.
  (define timeout-ms 600)
  (for ([op '(pluso minuso)])
    (define sat (sat-tuples op))
    (for* ([mask (bool-masks 3)]
           #:do [(define indices (mask-indices mask))
                 (define assignments
                   (if (null? indices)
                       (list '())
                       (cartesian-product
                        (build-list (length indices) (lambda (i) ints)))))]
           [as assignments]
           #:do [(define partial (partial-from indices as 3))
                 (define expected
                   (for/list ([tuple sat]
                              #:when (matches-grounding? tuple mask partial))
                     tuple))]
           #:when (pair? expected))
      (define expected* (sort expected string<? #:key ~s))
      (for ([flow flows])
        (define-values (done? raw)
          (run-with-timeout timeout-ms
                            (lambda ()
                              (run-op flow op partial))))
        (unless done?
          (fail-check
           (format "~a/~a timeout for mask ~a partial ~s"
                   op flow (mask->label mask) partial)))
        (define got* (decoded-set raw))
        (unless (equal? got* expected*)
          (fail-check
           (format "~a/~a mismatch for mask ~a partial ~s; expected ~s got ~s"
                   op flow (mask->label mask) partial expected* got*)))))))
