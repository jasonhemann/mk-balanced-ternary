#lang racket

(require rackunit
         minikanren
         (file "../src/bt_rel.rkt")
         (only-in (file "support/bt_harness.rkt")
                  int-range
                  decode-bt-tuple
                  raw-answer-coverage))

(define ints (int-range -40 40))
(define expected-singletons
  (for/list ([n ints]) (list n)))

(define (sort-singletons xs)
  (sort xs < #:key first))

(define (union-coverage coverages)
  (remove-duplicates (apply append coverages) equal?))

(define (disjoint-coverages? coverages)
  (for*/and ([i (in-range (length coverages))]
             [j (in-range (add1 i) (length coverages))])
    (null? (filter (lambda (x)
                     (member x (list-ref coverages j) equal?))
                   (list-ref coverages i)))))

(define (check-two-class-partition raw expected)
  (define coverages
    (for/list ([ans raw])
      (raw-answer-coverage ans expected decode-bt-tuple)))
  (check-equal? (length coverages) 2)
  (check-true (andmap list? coverages))
  (check-true (andmap pair? coverages))
  (define normalized (map sort-singletons coverages))
  (define zero-class '((0)))
  (define nonzero-class
    (sort-singletons
     (filter (lambda (x) (not (zero? (first x)))) expected)))
  (check-not-false (member zero-class normalized equal?))
  (check-not-false (member nonzero-class normalized equal?))
  (check-equal?
   (sort-singletons (union-coverage coverages))
   (sort-singletons expected))
  (check-true (disjoint-coverages? coverages)))

(test-case "bt symbolic partition: pluso identity has zero/nonzero classes"
  (define raw
    (run 10 (q)
      (pluso '() q q)))
  (check-false (decode-bt-tuple (second raw)))
  (check-two-class-partition raw expected-singletons))

(test-case "bt symbolic partition: *o identity has zero/nonzero classes"
  (define raw
    (run 10 (q)
      (*o '(1) q q)))
  (check-false (decode-bt-tuple (second raw)))
  (check-two-class-partition raw expected-singletons))

(test-case "bt symbolic partition: right-identity orientation preserves open answer shape"
  (check-equal?
   (run 10 (q)
     (pluso q '() q))
   '(_.0))
  (check-equal?
   (run 10 (q)
     (minuso q q '()))
   '(_.0)))
