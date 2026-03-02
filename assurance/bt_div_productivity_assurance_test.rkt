#lang racket

(require rackunit
         minikanren
         racket/engine
         (file "../src/bt_rel.rkt")
         (file "../test/support/bt_harness.rkt"))

(define budgets-ms '(2000 6000 20000))

(define (make-bound len)
  (build-list len (lambda (_) 'k)))

(define bound2 (make-bound 2))
(define bound4 (make-bound 4))
;; Explicit internal envelope for finite-domain productivity checks.
(define div-bound (make-bound 8))

(define (run-with-timeout timeout-ms thunk)
  (define e (engine (lambda (_stop) (thunk))))
  (define done? (engine-run timeout-ms e))
  (cond
    [done?
     (define out (engine-result e))
     (engine-kill e)
     (values #t out)]
    [else
     (engine-kill e)
     (values #f #f)]))

(define (normalize-set xs)
  (sort (remove-duplicates xs equal?)
        string<?
        #:key ~s))

(define (decode-and-normalize name raw)
  (define decoded
    (for/list ([ans raw])
      (decode-bt-tuple ans)))
  (for ([ans raw] [dec decoded])
    (check-not-false dec
                     (format "~a produced undecodable answer: ~s"
                             name
                             ans)))
  (normalize-set decoded))

(define (check-required-finite-case name expected run-thunk)
  (define expected* (normalize-set expected))
  (define closed? #f)
  (for ([budget budgets-ms] #:break closed?)
    (define-values (done? raw)
      (run-with-timeout budget run-thunk))
    (when done?
      (set! closed? #t)
      (when (> budget (car budgets-ms))
        (printf "INFO[bt-div-productivity] ~a: slow closure at ~ams\n"
                name
                budget))
      (check-equal? (decode-and-normalize name raw)
                    expected*
                    (format "~a denotation mismatch" name))))
  (unless closed?
    (fail-check
     (format "~a: divergence bug (did not close by ~ams)"
             name
             (last budgets-ms)))))

(define (check-expected-divergence-case name run-thunk #:timeout-ms [timeout-ms 6000])
  (define-values (done? _raw)
    (run-with-timeout timeout-ms run-thunk))
  (check-false done?
               (format "~a unexpectedly closed within ~ams"
                       name
                       timeout-ms)))

(test-case "bt div productivity: required finite ground and inverse cases close"
  (check-required-finite-case
   "ground/19/4"
   (list (list 4 3))
   (lambda ()
     (run* (ans)
       (fresh (q r)
         (divo (int->bt-term 19) (int->bt-term 4) q r)
         (== ans (list q r))))))
  (check-required-finite-case
   "ground/10/-2"
   (list (list -5 0))
   (lambda ()
     (run* (ans)
       (fresh (q r)
         (divo (int->bt-term 10) (int->bt-term -2) q r)
         (== ans (list q r)))))))

(test-case "bt div productivity: bounded finite-failure alias closes"
  (check-required-finite-case
   "alias/n=r,m=2,q=1/len2"
   '()
   (lambda ()
     (run* (x)
       (bto-boundedo x bound2)
       (divo-boundedo x (int->bt-term 2) (int->bt-term 1) x div-bound)))))

(test-case "bt div productivity: currently open inverse/all-open classes are tracked as divergence"
  (check-expected-divergence-case
   "inverse-n/m=-2,q=-5,r=0"
   (lambda ()
     (run* (n)
       (bto-boundedo n bound4)
       (divo-boundedo n (int->bt-term -2) (int->bt-term -5) '() div-bound))))
  (check-expected-divergence-case
   "bounded/vvvv/len2"
   (lambda ()
     (run* (ans)
       (fresh (n m q r)
         (bto-boundedo n bound2)
         (bto-boundedo m bound2)
         (bto-boundedo q bound2)
         (bto-boundedo r bound2)
         (divo-boundedo n m q r div-bound)
         (== ans (list n m q r)))))))
