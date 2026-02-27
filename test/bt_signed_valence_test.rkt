#lang racket

(require (except-in rackunit fail)
         minikanren
         (file "../src/bt_rel.rkt")
         (file "support/bt_harness.rkt"))

(define-syntax-rule (divo-test-case name body ...)
  (test-case name body ...))

(define (make-bound len)
  (build-list len (lambda (i) 'k)))

(define bound4 (make-bound 4))

(define (euclid-div n m)
  (define am (abs m))
  (define r (modulo n am))
  (define q (/ (- n r) m))
  (values q r))

(test-case "bt signed valence: pluso ground across sign combinations"
  (define cases
    (list (list 7 -5)
          (list -7 5)
          (list -8 -4)
          (list 8 4)
          (list 9 -9)
          (list -9 9)))
  (for ([ab cases])
    (define a (first ab))
    (define b (second ab))
    (check-bt-case-strict
     (format "pluso/sign/~a+~a" a b)
     #:expected-set (lambda ()
                      (list (list (+ a b))))
     #:run-observed
     (lambda (limit)
       (run limit (q)
         (pluso (int->bt-term a) (int->bt-term b) q)))
     #:decode-answer decode-bt-tuple
     #:k 1
     #:k2 1
     #:timeout-ms 1500)))

(test-case "bt signed valence: minuso subtracting negatives and crossing zero"
  (define triples
    (list (list 5 -7 12)
          (list -5 7 -12)
          (list -5 -7 2)
          (list 5 7 -2)
          (list -9 -9 0)
          (list 9 -9 18)
          (list -9 9 -18)))
  (for ([xyz triples])
    (define x (first xyz))
    (define y (second xyz))
    (define z (third xyz))
    (check-bt-case-strict
     (format "minuso/sign/~a-~a" x y)
     #:expected-set (lambda ()
                      (list (list z)))
     #:run-observed
     (lambda (limit)
       (run limit (q)
         (minuso (int->bt-term x) (int->bt-term y) q)))
     #:decode-answer decode-bt-tuple
     #:k 1
     #:k2 1
     #:timeout-ms 1500)))

(test-case "bt signed valence: inverse pluso/minuso with mixed signs"
  ;; These check that host arithmetic and relational inverse modes agree.
  (define inverse-cases
    (list (list 9 -4 5)
          (list 9 4 13)
          (list -9 4 -5)
          (list -9 -4 -13)
          (list 12 -7 5)
          (list -12 7 -5)))
  (for ([c inverse-cases])
    (define x (first c))
    (define y (second c))
    (define z (third c))
    (check-bt-case-strict
     (format "pluso/inverse-y/~a/~a" x z)
     #:expected-set (lambda ()
                      (list (list y)))
     #:run-observed
     (lambda (limit)
       (run limit (q)
         (bto-boundedo q bound4)
         (pluso (int->bt-term x) q (int->bt-term z))))
     #:decode-answer decode-bt-tuple
     #:k 1
     #:k2 1
     #:timeout-ms 2000)
    (check-bt-case-strict
     (format "minuso/inverse-y/~a/~a" x z)
     #:expected-set (lambda ()
                      (list (list (- x z))))
     #:run-observed
     (lambda (limit)
       (run limit (q)
         (bto-boundedo q bound4)
         (minuso (int->bt-term x) q (int->bt-term z))))
     #:decode-answer decode-bt-tuple
     #:k 1
     #:k2 1
     #:timeout-ms 2000)))

(test-case "bt signed valence: *o sign law and zero crossing"
  (define cases
    (list (list 6 -4 -24)
          (list -6 4 -24)
          (list -6 -4 24)
          (list 6 4 24)
          (list 0 -9 0)
          (list -9 0 0)))
  (for ([xyz cases])
    (define x (first xyz))
    (define y (second xyz))
    (define z (third xyz))
    (check-bt-case-strict
     (format "*o/sign/~a*~a" x y)
     #:expected-set (lambda ()
                      (list (list z)))
     #:run-observed
     (lambda (limit)
       (run limit (q)
         (*o (int->bt-term x) (int->bt-term y) q)))
     #:decode-answer decode-bt-tuple
     #:k 1
     #:k2 1
     #:timeout-ms 2000)))

(divo-test-case "bt signed valence: Euclidean divo across sign combinations"
  (define div-cases
    (list (list 11 4)
          (list 11 -4)
          (list -11 4)
          (list -11 -4)
          (list 7 3)
          (list 7 -3)
          (list -7 3)
          (list -7 -3)))
  (for ([nm div-cases])
    (define n (first nm))
    (define m (second nm))
    (define-values (q r) (euclid-div n m))
    (check-bt-case-strict
     (format "div/sign/~a/~a" n m)
     #:expected-set (lambda ()
                      (list (list q r)))
     #:run-observed
     (lambda (limit)
       (run limit (ans)
         (fresh (qq rr)
           (divo (int->bt-term n)
                          (int->bt-term m)
                          qq rr
                          bound4)
           (== ans (list qq rr)))))
     #:decode-answer decode-bt-tuple
     #:k 1
     #:k2 1
     #:timeout-ms 2500)
    (check-bt-case-strict
     (format "div/inverse-n/sign/~a/~a" m q)
     #:expected-set (lambda ()
                      (list (list n)))
     #:run-observed
     (lambda (limit)
       (run limit (nn)
         (bto-boundedo nn bound4)
         (divo nn
                        (int->bt-term m)
                        (int->bt-term q)
                        (int->bt-term r)
                        bound4)))
     #:decode-answer decode-bt-tuple
     #:k 1
     #:k2 1
     #:timeout-ms 2500)))

(test-case "bt signed valence: deterministic cross-sign agreement with Racket arithmetic"
  ;; Exhaust a small opposite-sign domain to keep this strict and stable.
  (define pairs
    (for*/list ([a (in-range 1 13)]
                [b (in-range -12 0)])
      (list a b)))
  (for ([ab pairs] [i (in-naturals)])
    (define a (first ab))
    (define b (second ab))
    (define-values (q r) (euclid-div a b))
    (check-bt-case-strict
     (format "cross-sign/pluso/~a" i)
     #:expected-set (lambda ()
                      (list (list (+ a b))))
     #:run-observed
     (lambda (limit)
       (run limit (qv)
         (pluso (int->bt-term a) (int->bt-term b) qv)))
     #:decode-answer decode-bt-tuple
     #:k 1
     #:k2 1
     #:timeout-ms 2500)
    (check-bt-case-strict
     (format "cross-sign/minuso/~a" i)
     #:expected-set (lambda ()
                      (list (list (- a b))))
     #:run-observed
     (lambda (limit)
       (run limit (qv)
         (minuso (int->bt-term a) (int->bt-term b) qv)))
     #:decode-answer decode-bt-tuple
     #:k 1
     #:k2 1
     #:timeout-ms 2500)
    (check-bt-case-strict
     (format "cross-sign/*o/~a" i)
     #:expected-set (lambda ()
                      (list (list (* a b))))
     #:run-observed
     (lambda (limit)
       (run limit (qv)
         (*o (int->bt-term a) (int->bt-term b) qv)))
     #:decode-answer decode-bt-tuple
     #:k 1
     #:k2 1
     #:timeout-ms 2500)
    (check-bt-case-strict
     (format "cross-sign/divo/~a" i)
     #:expected-set (lambda ()
                      (list (list q r)))
     #:run-observed
     (lambda (limit)
       (run limit (ans)
         (fresh (qq rr)
           (divo (int->bt-term a)
                          (int->bt-term b)
                          qq rr
                          bound4)
           (== ans (list qq rr)))))
     #:decode-answer decode-bt-tuple
     #:k 1
     #:k2 1
     #:timeout-ms 6000)))
