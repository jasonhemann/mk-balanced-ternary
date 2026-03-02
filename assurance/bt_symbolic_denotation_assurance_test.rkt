#lang racket

(require (except-in rackunit fail)
         minikanren
         racket/engine
         (file "../src/bt_rel.rkt")
         (file "../test/support/bt_harness.rkt"))

(define len 4)
(define maxabs (max-abs-for-len len))
(define ints (int-range (- maxabs) maxabs))

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

(define (run-with-timeout timeout-ms thunk)
  (define e (engine (lambda (enable-stop) (thunk))))
  (define done? (engine-run timeout-ms e))
  (define out (and done? (engine-result e)))
  (engine-kill e)
  (values done? out))

(define (check-symbolic-case name expected run-thunk
                             #:count count
                             #:limit [limit count]
                             #:timeout-ms [timeout-ms 2000])
  (define-values (done? raw)
    (run-with-timeout timeout-ms
                      (lambda ()
                        (run-thunk limit))))
  (unless done?
    (fail-check
     (format "~a timed out (>~ams)" name timeout-ms)))

  (check-equal? (length raw) count)
  (define coverages
    (for/list ([ans raw])
      (raw-answer-coverage ans expected decode-bt-tuple)))
  (check-true (andmap list? coverages))
  (check-true (andmap pair? coverages))
  (check-equal?
   (normalize-set (union-coverage coverages))
   (normalize-set expected))
  (check-true (disjoint-coverages? coverages)))

(test-case "bt assurance: symbolic denotation partitions remain exact/disjoint at len<=4"
  ;; Assurance companion to fast symbolic tests: same open-mode surfaces,
  ;; larger host domain and explicit per-case completion budgets.
  (check-symbolic-case
   "pluso-left-id"
   expected-singletons
   (lambda (limit)
     (run limit (q)
       (pluso '() q q)))
   #:count 2
   #:timeout-ms 1800)

  (check-symbolic-case
   "pluso-right-id"
   expected-singletons
   (lambda (limit)
     (run limit (q)
       (pluso q '() q)))
   #:count 1
   #:timeout-ms 1800)

  (check-symbolic-case
   "minuso-self-cancel"
   expected-singletons
   (lambda (limit)
     (run limit (q)
       (minuso q q '())))
   #:count 1
   #:timeout-ms 1800)

  (check-symbolic-case
   "mul-left-id"
   expected-singletons
   (lambda (limit)
     (run limit (q)
       (*o '(1) q q)))
   #:count 2
   #:timeout-ms 2200)

  (check-symbolic-case
   "mul-right-id"
   expected-singletons
   (lambda (limit)
     (run limit (q)
       (*o q '(1) q)))
   #:count 4
   #:timeout-ms 2200)

  (check-symbolic-case
   "mul-zero-surface"
   expected-zero-product-pairs
   (lambda (limit)
     (run limit (q)
       (fresh (x y)
         (*o x y '())
         (== q (list x y)))))
   #:count 2
   #:timeout-ms 2200))
