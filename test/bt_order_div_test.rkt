#lang racket

(require (except-in rackunit fail)
         minikanren
         (file "../src/bt_rel.rkt")
         (file "support/bt_harness.rkt"))

(define ENABLE-BT-DIVO-TESTS? #f)

(define-syntax-rule (divo-test-case name body ...)
  (when ENABLE-BT-DIVO-TESTS?
    (test-case name body ...)))

(define (make-bound len)
  (build-list len (lambda (i) 'k)))

(define bound2 (make-bound 2))
(define maxabs2 (max-abs-for-len 2))
(define ints2 (int-range (- maxabs2) maxabs2))

(define bound3 (make-bound 3))
(define ints3 (int-range -8 8))

(define (mode-limits expected)
  (define n (max 1 (length (remove-duplicates expected equal?))))
  (values (min 16 n) (max (+ n 8) (* 4 n))))

(define (euclid-div n m)
  (define am (abs m))
  (define r (modulo n am))
  (define q (/ (- n r) m))
  (values q r))

(test-case "bt ordering: lto-boundedo matches host < over len<=2 domain"
  (define expected
    (for*/list ([a ints2]
                [b ints2]
                #:when (< a b))
      (list a b)))
  (define-values (k k2) (mode-limits expected))
  (check-bt-case-strict
   "lto/len2/all"
   #:expected-set expected
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (fresh (x y)
         (bto-boundedo x bound2)
         (bto-boundedo y bound2)
         (lto-boundedo x y bound2)
         (== q (list x y)))))
   #:decode-answer decode-bt-tuple
   #:k k
   #:k2 k2
   #:timeout-ms 1600))

(test-case "bt ordering: abso-boundedo matches host abs over len<=2 domain"
  (define expected
    (for/list ([n ints2])
      (list n (abs n))))
  (define-values (k k2) (mode-limits expected))
  (check-bt-case-strict
   "abso/len2/all"
   #:expected-set expected
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (fresh (x ax)
         (bto-boundedo x bound2)
         (abso-boundedo x ax bound2)
         (== q (list x ax)))))
   #:decode-answer decode-bt-tuple
   #:k k
   #:k2 k2
   #:timeout-ms 1600))

(divo-test-case "bt division semantics: Euclidean ground (n,m)->(q,r)"
  (for* ([n ints3]
         [m ints3]
         #:when (not (zero? m)))
    (define-values (q r) (euclid-div n m))
    (check-bt-case-strict
     (format "div/ground/~a/~a" n m)
     #:expected-set (lambda ()
                      (list (list q r)))
     #:run-observed
     (lambda (limit)
       (run limit (ans)
         (fresh (qq rr)
           (divo (int->bt-term n)
                          (int->bt-term m)
                          qq rr
                          bound3)
           (== ans (list qq rr)))))
     #:decode-answer decode-bt-tuple
     #:k 1
     #:k2 1
     #:timeout-ms 2500)))

(divo-test-case "bt division inverse modes: recover q and n under Euclidean semantics"
  (for* ([n ints3]
         [m ints3]
         #:when (not (zero? m)))
    (define-values (q r) (euclid-div n m))
    (check-bt-case-strict
     (format "div/inverse-q/~a/~a" n m)
     #:expected-set (lambda ()
                      (list (list q)))
     #:run-observed
     (lambda (limit)
       (run limit (qq)
         (divo (int->bt-term n)
                        (int->bt-term m)
                        qq
                        (int->bt-term r)
                        bound3)))
     #:decode-answer decode-bt-tuple
     #:k 1
     #:k2 1
     #:timeout-ms 2500)
    (check-bt-case-strict
     (format "div/inverse-n/~a/~a" q m)
     #:expected-set (lambda ()
                      (list (list n)))
     #:run-observed
     (lambda (limit)
       (run limit (nn)
         (divo nn
                        (int->bt-term m)
                        (int->bt-term q)
                        (int->bt-term r)
                        bound3)))
     #:decode-answer decode-bt-tuple
     #:k 1
     #:k2 1
     #:timeout-ms 2500)))

(divo-test-case "bt division ground cases are deterministic (no duplicate proofs)"
  (for ([entry (list (list 4 3 1 1)
                     (list -4 3 -2 2)
                     (list -4 -3 2 2)
                     (list 4 -3 -1 1))])
    (define n (first entry))
    (define m (second entry))
    (define q (third entry))
    (define r (fourth entry))
    (define sols
      (run* (ans)
        (fresh (qq rr)
          (divo (int->bt-term n)
                         (int->bt-term m)
                         qq rr
                         bound3)
          (== ans (list qq rr)))))
    (check-equal? sols
                  (list (list (int->bt-term q)
                              (int->bt-term r))))))
