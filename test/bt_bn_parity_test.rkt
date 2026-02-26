#lang racket

(require rackunit
         minikanren
         (prefix-in bt: (file "../src/bt_rel.rkt"))
         (prefix-in bn: (file "../src/binary-numbers.rkt"))
         (only-in (file "support/bt_harness.rkt")
                  int-range
                  decode-bt-tuple
                  raw-answer-coverage)
         (only-in (file "support/bn_harness.rkt")
                  nat-range
                  decode-bn-tuple
                  raw-bn-answer-coverage))

(define bt-ints (int-range -40 40))
(define bt-expected (for/list ([n bt-ints]) (list n)))

(define bn-nats (nat-range 0 80))
(define bn-expected (for/list ([n bn-nats]) (list n)))

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

(define (check-two-class-partition raw expected coverage-fn)
  (define coverages
    (for/list ([ans raw])
      (coverage-fn ans expected)))
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

(test-case "parity: pluso identity is a two-class symbolic partition in BT and binary suites"
  (define bt-raw
    (run 10 (q)
      (bt:pluso '() q q)))
  (define bn-raw
    (run 10 (q)
      (bn:pluso '() q q)))

  ;; Both suites return one concrete zero answer and one symbolic
  ;; nonzero class; this is the expected mK open-mode behavior.
  (check-false (decode-bt-tuple (second bt-raw)))
  (check-false (decode-bn-tuple (second bn-raw)))
  (check-two-class-partition
   bt-raw bt-expected
   (lambda (ans expected)
     (raw-answer-coverage ans expected decode-bt-tuple)))
  (check-two-class-partition
   bn-raw bn-expected
   (lambda (ans expected)
     (raw-bn-answer-coverage ans expected decode-bn-tuple))))

(test-case "parity: *o identity is a two-class symbolic partition in BT and binary suites"
  (define bt-raw
    (run 10 (q)
      (bt:*o '(1) q q)))
  (define bn-raw
    (run 10 (q)
      (bn:*o '(1) q q)))

  (check-false (decode-bt-tuple (second bt-raw)))
  (check-false (decode-bn-tuple (second bn-raw)))
  (check-two-class-partition
   bt-raw bt-expected
   (lambda (ans expected)
     (raw-answer-coverage ans expected decode-bt-tuple)))
  (check-two-class-partition
   bn-raw bn-expected
   (lambda (ans expected)
     (raw-bn-answer-coverage ans expected decode-bn-tuple))))

(test-case "parity: right-identity orientation keeps mK asymmetry for pluso/minuso"
  (check-equal?
   (run 10 (q)
     (bn:pluso q '() q))
   '(_.0))
  (check-equal?
   (run 10 (q)
     (bt:pluso q '() q))
   '(_.0))
  (check-equal?
   (run 10 (q)
     (bn:minuso q q '()))
   '(_.0))
  (check-equal?
   (run 10 (q)
     (bt:minuso q q '()))
   '(_.0)))
