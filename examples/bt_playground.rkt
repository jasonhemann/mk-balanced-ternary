#lang racket

(require minikanren
         (except-in racket/list cartesian-product)
         (file "../src/bt_rel.rkt")
         (file "../src/bt_oracle.rkt")
         (file "../test/support/bt_harness.rkt"))

(provide (all-defined-out))

;; Balanced ternary reminder:
;; -1 is symbol 'T, while 0 and 1 are numeric trits.

(define (bound len)
  (build-list len (lambda (_) 'k)))

(define LEN 3)
(define B (bound LEN))
(define MAXABS (max-abs-for-len LEN))
(define INTS (int-range (- MAXABS) MAXABS))

;; Useful expected domains for denotation checks.
(define singleton-domain
  (for/list ([n INTS]) (list n)))

(define pair-domain
  (for*/list ([x INTS] [y INTS]) (list x y)))

(define triple-domain
  (for*/list ([x INTS] [y INTS] [z INTS]) (list x y z)))

(define zero-pair-domain
  (for*/list ([x INTS]
              [y INTS]
              #:when (zero? (* x y)))
    (list x y)))

;; Convert raw (possibly symbolic) answers into a bounded denotation over
;; host integers.
(define (denotation raw expected)
  (sort
   (remove-duplicates
    (apply append
           (for/list ([ans raw])
             (raw-answer-coverage ans expected decode-bt-tuple)))
    equal?)
   string<?
   #:key ~s))

;; Pretty printer for quick REPL sessions.
(define (show label v)
  (printf "~a\n  ~s\n" label v)
  v)

;; Wrappers so it is obvious which encoder/decoder you are using.
(define (build-num* n)
  (build-num n))

(define (unbuild-num* bt)
  (bt->int bt))

;; Example snippets for DrRacket REPL:

(show "pluso identity raw" (run 10 (q) (pluso '() q q)))
(show "pluso identity denotation"
      (denotation (run 10 (q) (pluso '() q q)) singleton-domain))

(show "*o one identity raw" (run 10 (q) (*o '(1) q q)))
(show "*o one identity denotation"
      (denotation (run 10 (q) (*o '(1) q q)) singleton-domain))

(show "zero-product pair raw"
      (run 10 (q)
        (fresh (x y)
          (*o x y '())
          (== q (list x y)))))
(show "zero-product pair denotation"
      (denotation
       (run 10 (q)
         (fresh (x y)
           (*o x y '())
           (== q (list x y))))
       zero-pair-domain))

(show "div ground (run 1)"
      (run 1 (ans)
        (fresh (q r)
          (divo (build-num* 19) (build-num* 4) q r)
          (== ans (list q r)))))

(show "build/unbuild roundtrip"
      (for/list ([n (in-range -10 11)])
        (list n (build-num* n) (unbuild-num* (build-num* n)))))
