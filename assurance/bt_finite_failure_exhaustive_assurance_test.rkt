#lang racket

(require (except-in rackunit fail)
         minikanren
         racket/engine
         (file "../src/bt_rel.rkt")
         (file "../test/support/bt_harness.rkt"))

(define (make-bound len)
  (build-list len (lambda (i) 'k)))

;; Keep the domain small but exhaustive to cover all mode/failure shapes.
(define bound (make-bound 2))
(define maxabs (max-abs-for-len 2))
(define ints (int-range (- maxabs) maxabs))

(define flows '(bounds-bind-rel bounds-rel-bind bind-bounds-rel))
(define ops '(pluso minuso *o))

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
   (map (lambda (g) (if g #\g #\v)) mask)))

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
                [(minuso) (= (- x y) z)]
                [(*o) (= (* x y) z)]))
    (list x y z)))

(define (unsat-cases op)
  (define sat (sat-tuples op))
  (for*/list ([mask (bool-masks 3)]
              #:unless (equal? mask '(#f #f #f))
              #:do [(define indices (mask-indices mask))
                    (define assignments
                      (if (null? indices)
                          (list '())
                          (cartesian-product
                           (build-list (length indices) (lambda (i) ints)))))]
              [as assignments]
              #:do [(define partial (partial-from indices as 3))]
              #:unless (ormap (lambda (tuple)
                                (matches-grounding? tuple mask partial))
                              sat))
    (list mask partial)))

(define (bind-int-if t maybe-int)
  (if maybe-int
      (== t (int->bt-term maybe-int))
      (== t t)))

(define (op-goalo op x y z)
  (case op
    [(pluso) (pluso x y z)]
    [(minuso) (minuso x y z)]
    [(*o) (*o x y z)]))

(define (run-op flow op partial)
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
         (op-goalo op rx ry rz)
         (== q (list rx ry rz))))]
    [(bounds-rel-bind)
     (run* (q)
       (fresh (rx ry rz)
         (bto-boundedo rx bound)
         (bto-boundedo ry bound)
         (bto-boundedo rz bound)
         (op-goalo op rx ry rz)
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
         (op-goalo op rx ry rz)
         (== q (list rx ry rz))))]))

(test-case "bt assurance: exhaustive finite-failure across modes and logic flows (len<=2)"
  ;; For every operation, every grounding mode, and every unsatisfiable
  ;; grounded assignment under len<=2, all flow orderings below must terminate
  ;; and return the empty set.
  (define timeout-ms 600)
  (for ([op ops])
    (define cases (unsat-cases op))
    (check-true (pair? cases) (format "~a should have unsatisfiable mode instances" op))
    (for ([flow flows])
      (for ([entry cases])
        (define mask (first entry))
        (define partial (second entry))
        (define-values (done? out)
          (run-with-timeout timeout-ms
                            (lambda ()
                              (run-op flow op partial))))
        (unless done?
          (fail-check
           (format "~a/~a timeout for mask ~a partial ~s"
                   op flow (mask->label mask) partial)))
        (unless (null? out)
          (fail-check
           (format "~a/~a expected finite failure for mask ~a partial ~s; got ~s"
                   op flow (mask->label mask) partial out)))))))
