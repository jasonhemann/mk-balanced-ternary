#lang racket

(require (except-in rackunit fail)
         minikanren
         (except-in racket/list cartesian-product)
         (file "../src/bt_rel.rkt")
         (file "support/bt_harness.rkt"))

(define ints (int-range -40 40))
(define expected-singletons
  (for/list ([n ints]) (list n)))
(define expected-zero-product-pairs
  (for*/list ([x ints]
              [y ints]
              #:when (zero? (* x y)))
    (list x y)))

(define (normalize-set xs)
  (sort (remove-duplicates xs equal?) string<? #:key ~s))

(define (union-coverage coverages)
  (remove-duplicates (apply append coverages) equal?))

(define (disjoint-coverages? coverages)
  (for*/and ([i (in-range (length coverages))]
             [j (in-range (add1 i) (length coverages))])
    (null? (filter (lambda (x)
                     (member x (list-ref coverages j) equal?))
                   (list-ref coverages i)))))

(define (check-symbolic-partition raw expected [count #f])
  (when count
    (check-equal? (length raw) count))
  (define coverages
    (for/list ([ans raw])
      (raw-answer-coverage ans expected decode-bt-tuple)))
  (check-true (andmap list? coverages))
  (check-true (andmap pair? coverages))
  (check-equal?
   (normalize-set (union-coverage coverages))
   (normalize-set expected))
  (check-true (disjoint-coverages? coverages)))

(test-case "bt symbolic denotation: pluso identity answer set is exact over bounded host domain"
  (check-bt-case-strict
   "symbolic/pluso/id"
   #:expected-set (lambda () expected-singletons)
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (pluso '() q q)))
   #:decode-answer decode-bt-tuple
   #:k 2
   #:k2 2
   #:timeout-ms 800))

(test-case "bt symbolic denotation: pluso identity symbolic answers form a disjoint partition"
  (define raw
    (run 10 (q)
      (pluso '() q q)))
  (check-symbolic-partition raw expected-singletons 2))

(test-case "bt symbolic denotation: pluso right-identity mode stays denotationally exact"
  (check-bt-case-strict
   "symbolic/pluso/right-id"
   #:expected-set (lambda () expected-singletons)
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (pluso q '() q)))
   #:decode-answer decode-bt-tuple
   #:k 1
   #:k2 1
   #:timeout-ms 800))

(test-case "bt symbolic denotation: pluso right-identity symbolic answer is one disjoint class"
  (define raw
    (run 10 (q)
      (pluso q '() q)))
  (check-symbolic-partition raw expected-singletons 1))

(test-case "bt symbolic denotation: minuso self-cancel mode stays denotationally exact"
  (check-bt-case-strict
   "symbolic/minuso/self-cancel"
   #:expected-set (lambda () expected-singletons)
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (minuso q q '())))
   #:decode-answer decode-bt-tuple
   #:k 1
   #:k2 1
   #:timeout-ms 800))

(test-case "bt symbolic denotation: minuso self-cancel symbolic answer is one disjoint class"
  (define raw
    (run 10 (q)
      (minuso q q '())))
  (check-symbolic-partition raw expected-singletons 1))

(test-case "bt symbolic denotation: *o identity answer set is exact over bounded host domain"
  (check-bt-case-strict
   "symbolic/*o/id"
   #:expected-set (lambda () expected-singletons)
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (*o '(1) q q)))
   #:decode-answer decode-bt-tuple
   #:k 2
   #:k2 2
   #:timeout-ms 1200))

(test-case "bt symbolic denotation: *o identity symbolic answers form a disjoint partition"
  (define raw
    (run 10 (q)
      (*o '(1) q q)))
  (check-symbolic-partition raw expected-singletons 2))

(test-case "bt symbolic denotation: *o right-identity mode stays denotationally exact"
  (check-bt-case-strict
   "symbolic/*o/right-id"
   #:expected-set (lambda () expected-singletons)
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (*o q '(1) q)))
   #:decode-answer decode-bt-tuple
   #:k 4
   #:k2 4
   #:timeout-ms 1200))

(test-case "bt symbolic denotation: *o right-identity symbolic answers form a disjoint partition"
  (define raw
    (run 10 (q)
      (*o q '(1) q)))
  (check-symbolic-partition raw expected-singletons 4))

(test-case "bt symbolic denotation: *o zero-surface stays denotationally exact for pair outputs"
  (check-bt-case-strict
   "symbolic/*o/zero-surface"
   #:expected-set (lambda () expected-zero-product-pairs)
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (fresh (x y)
         (*o x y '())
         (== q (list x y)))))
   #:decode-answer decode-bt-tuple
   #:k 2
   #:k2 2
   #:timeout-ms 1200))

(test-case "bt symbolic denotation: *o zero-surface symbolic answers are disjoint over bounded host pairs"
  (define raw
    (run 10 (q)
      (fresh (x y)
        (*o x y '())
        (== q (list x y)))))
  (check-symbolic-partition raw expected-zero-product-pairs 2))
