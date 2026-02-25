#lang racket

(require (except-in rackunit fail)
         minikanren
         (file "../src/bt_rel.rkt")
         (file "support/bt_harness.rkt"))

(define trits '(T 0 1))

(define (trit->int t)
  (cond
    [(eq? t 'T) -1]
    [(equal? t 0) 0]
    [else 1]))

(define (int->sum/carry total)
  (cond
    [(= total -3) (list 0 'T)]
    [(= total -2) (list 1 'T)]
    [(= total -1) (list 'T 0)]
    [(= total 0) (list 0 0)]
    [(= total 1) (list 1 0)]
    [(= total 2) (list 'T 1)]
    [(= total 3) (list 0 1)]
    [else (error 'int->sum/carry "unexpected sum: ~a" total)]))

(define (trit-neg t)
  (cond
    [(eq? t 'T) 1]
    [(equal? t 0) 0]
    [else 'T]))

(test-case "bt harness primitives: trito domain"
  (check-bt-case
   "trito/domain"
   #:expected-set (lambda ()
                    trits)
   #:run-observed (lambda (limit)
                    (run limit (q)
                      (trito q)))
   #:decode-answer (lambda (raw)
                     raw)
   #:k 3
   #:k2 3))

(test-case "bt harness primitives: add3o truth table"
  (for* ([a trits]
         [b trits]
         [cin trits])
    (define expected (int->sum/carry (+ (trit->int a)
                                        (trit->int b)
                                        (trit->int cin))))
    (check-bt-case
     (format "add3o/~a~a~a" a b cin)
     #:expected-set (lambda ()
                      (list expected))
     #:run-observed (lambda (limit)
                      (run limit (q)
                        (fresh (s cout)
                          (add3o a b cin s cout)
                          (== q (list s cout)))))
     #:decode-answer (lambda (raw)
                       raw)
     #:k 1
     #:k2 1)))

(test-case "bt harness primitives: negtrito truth table"
  (for ([t trits])
    (check-bt-case
     (format "negtrito/~a" t)
     #:expected-set (lambda ()
                      (list (trit-neg t)))
     #:run-observed (lambda (limit)
                      (run limit (q)
                        (negtrito t q)))
     #:decode-answer (lambda (raw)
                       raw)
     #:k 1
     #:k2 1)))

(test-case "bt harness primitives: nego over small integer range"
  (for ([n (in-range -30 31)])
    (check-bt-case
     (format "nego/~a" n)
     #:expected-set (lambda ()
                      (list (list (- n))))
     #:run-observed
     (lambda (limit)
       (run limit (q)
         (nego (int->bt-term n) q)))
     #:decode-answer decode-bt-tuple
     #:k 1
     #:k2 1
     #:timeout-ms 800)))

(test-case "bt harness primitives: negateo alias matches nego"
  (for ([n (in-range -15 16)])
    (check-bt-case
     (format "negateo/~a" n)
     #:expected-set (lambda ()
                      (list (list (- n))))
     #:run-observed
     (lambda (limit)
       (run limit (q)
         (negateo (int->bt-term n) q)))
     #:decode-answer decode-bt-tuple
     #:k 1
     #:k2 1
     #:timeout-ms 800)))

(test-case "bt harness primitives: mul1o by trit"
  (for* ([n (in-range -20 21)]
         [t trits])
    (check-bt-case
     (format "mul1o/~a-by-~a" n t)
     #:expected-set
     (lambda ()
       (list
        (list
         (* n (trit->int t)))))
     #:run-observed
     (lambda (limit)
       (run limit (q)
         (mul1o (int->bt-term n) t q)))
     #:decode-answer decode-bt-tuple
     #:k 1
     #:k2 1
     #:timeout-ms 800)))
