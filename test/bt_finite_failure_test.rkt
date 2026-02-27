#lang racket

(require (except-in rackunit fail)
         minikanren
         (file "../src/bt_rel.rkt")
         (file "support/bt_harness.rkt"))

(define-syntax-rule (divo-test-case name body ...)
  (test-case name body ...))

(define (make-bound len)
  (build-list len (lambda (i) 'k)))

;; Keep the failure matrix small and exhaustive. len=2 gives domain [-4,4].
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

(define (find-mode-witnesses arity sat-tuples domain)
  (for/list ([mask (bool-masks arity)]
             #:do [(define indices (mask-indices mask))
                   (define assignments
                     (if (null? indices)
                         (list '())
                         (cartesian-product
                          (build-list (length indices) (lambda (i) domain)))))
                   (define witness
                     (for/first ([as assignments]
                                 #:do [(define partial
                                         (partial-from indices as arity))]
                                 #:unless
                                 (ormap (lambda (tuple)
                                          (matches-grounding? tuple mask partial))
                                        sat-tuples))
                       partial))]
             #:when witness)
    (list mask witness)))

(define (bind-int-if t maybe-int)
  (if maybe-int
      (== t (int->bt-term maybe-int))
      (== t t)))

(define (euclid-sat? n m q r)
  (and (not (zero? m))
       (= n (+ (* m q) r))
       (<= 0 r)
       (< r (abs m))))

(define plus-sat
  (for*/list ([x ints] [y ints] [z ints] #:when (= (+ x y) z))
    (list x y z)))

(define minus-sat
  (for*/list ([x ints] [y ints] [z ints] #:when (= (- x y) z))
    (list x y z)))

(define mul-sat
  (for*/list ([x ints] [y ints] [z ints] #:when (= (* x y) z))
    (list x y z)))

(define div-sat
  (for*/list ([n ints] [m ints] [q ints] [r ints]
              #:when (euclid-sat? n m q r))
    (list n m q r)))

(test-case "bt finite failure matrix: pluso modes with failure witnesses"
  ;; Mutatis mutandis from arith.prl should_fail classes: for every grounding
  ;; mode that admits unsatisfiable instances under the finite bound, we assert
  ;; finite failure with no timeout/missing warnings.
  (define cases (find-mode-witnesses 3 plus-sat ints))
  (check-true (pair? cases))
  (for ([entry cases])
    (define mask (first entry))
    (define witness (second entry))
    (define x (list-ref witness 0))
    (define y (list-ref witness 1))
    (define z (list-ref witness 2))
    (check-bt-case-strict
     (format "pluso/fail/~a" (mask->label mask))
     #:expected-set (lambda () '())
     #:run-observed
     (lambda (limit)
       (run limit (q)
         (fresh (rx ry rz)
           (bto-boundedo rx bound)
           (bto-boundedo ry bound)
           (bto-boundedo rz bound)
           (bind-int-if rx x)
           (bind-int-if ry y)
           (bind-int-if rz z)
           (pluso rx ry rz)
           (== q (list rx ry rz)))))
     #:decode-answer decode-bt-tuple
     #:k 8
     #:k2 16
     #:timeout-ms 1500)))

(test-case "bt finite failure matrix: minuso modes with failure witnesses"
  (define cases (find-mode-witnesses 3 minus-sat ints))
  (check-true (pair? cases))
  (for ([entry cases])
    (define mask (first entry))
    (define witness (second entry))
    (define x (list-ref witness 0))
    (define y (list-ref witness 1))
    (define z (list-ref witness 2))
    (check-bt-case-strict
     (format "minuso/fail/~a" (mask->label mask))
     #:expected-set (lambda () '())
     #:run-observed
     (lambda (limit)
       (run limit (q)
         (fresh (rx ry rz)
           (bto-boundedo rx bound)
           (bto-boundedo ry bound)
           (bto-boundedo rz bound)
           (bind-int-if rx x)
           (bind-int-if ry y)
           (bind-int-if rz z)
           (minuso rx ry rz)
           (== q (list rx ry rz)))))
     #:decode-answer decode-bt-tuple
     #:k 8
     #:k2 16
     #:timeout-ms 1500)))

(test-case "bt finite failure matrix: *o modes with failure witnesses"
  (define cases (find-mode-witnesses 3 mul-sat ints))
  (check-true (pair? cases))
  (for ([entry cases])
    (define mask (first entry))
    (define witness (second entry))
    (define x (list-ref witness 0))
    (define y (list-ref witness 1))
    (define z (list-ref witness 2))
    (check-bt-case-strict
     (format "*o/fail/~a" (mask->label mask))
     #:expected-set (lambda () '())
     #:run-observed
     (lambda (limit)
       (run limit (q)
         (fresh (rx ry rz)
           (bto-boundedo rx bound)
           (bto-boundedo ry bound)
           (bto-boundedo rz bound)
           (bind-int-if rx x)
           (bind-int-if ry y)
           (bind-int-if rz z)
           (*o rx ry rz)
           (== q (list rx ry rz)))))
     #:decode-answer decode-bt-tuple
     #:k 8
     #:k2 16
     #:timeout-ms 2000)))

(divo-test-case "bt finite failure matrix: divo modes with failure witnesses"
  (define cases (find-mode-witnesses 4 div-sat ints))
  (check-true (pair? cases))
  (for ([entry cases])
    (define mask (first entry))
    (define witness (second entry))
    (define n (list-ref witness 0))
    (define m (list-ref witness 1))
    (define qv (list-ref witness 2))
    (define r (list-ref witness 3))
    (check-bt-case-strict
     (format "divo/fail/~a" (mask->label mask))
     #:expected-set (lambda () '())
     #:run-observed
     (lambda (limit)
       (run limit (ans)
         (fresh (rn rm rq rr)
           (bto-boundedo rn bound)
           (bto-boundedo rm bound)
           (bto-boundedo rq bound)
           (bto-boundedo rr bound)
           (bind-int-if rn n)
           (bind-int-if rm m)
           (bind-int-if rq qv)
           (bind-int-if rr r)
           (divo rn rm rq rr)
           (== ans (list rn rm rq rr)))))
     #:decode-answer decode-bt-tuple
     #:k 8
     #:k2 20
     #:timeout-ms 2500)))
