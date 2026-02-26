#lang racket

(require (except-in rackunit fail)
         minikanren
         (except-in racket/list cartesian-product)
         (file "../src/bt_rel.rkt")
         (file "support/bt_harness.rkt"))

(define ints (int-range -40 40))
(define expected-singletons
  (for/list ([n ints]) (list n)))

(define (union-coverage coverages)
  (remove-duplicates (apply append coverages) equal?))

(define (disjoint-coverages? coverages)
  (for*/and ([i (in-range (length coverages))]
             [j (in-range (add1 i) (length coverages))])
    (null? (filter (lambda (x)
                     (member x (list-ref coverages j) equal?))
                   (list-ref coverages i)))))

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
  (define coverages
    (for/list ([ans raw])
      (raw-answer-coverage ans expected-singletons decode-bt-tuple)))
  (check-true (andmap list? coverages))
  (check-true (andmap pair? coverages))
  (check-equal?
   (sort (union-coverage coverages) < #:key first)
   (sort expected-singletons < #:key first))
  (check-true (disjoint-coverages? coverages)))

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
  (define coverages
    (for/list ([ans raw])
      (raw-answer-coverage ans expected-singletons decode-bt-tuple)))
  (check-true (andmap list? coverages))
  (check-true (andmap pair? coverages))
  (check-equal?
   (sort (union-coverage coverages) < #:key first)
   (sort expected-singletons < #:key first))
  (check-true (disjoint-coverages? coverages)))
