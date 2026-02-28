#lang racket

(require (except-in rackunit fail)
         minikanren
         racket/engine
         racket/random
         (file "../src/bt_oracle.rkt")
         (prefix-in bt: (file "../src/bt_rel.rkt")))

(define (run1 thunk)
  (define sols (thunk))
  (if (null? sols) #f (car sols)))

(define (rand-int lo hi)
  (+ lo (random (+ 1 (- hi lo)))))

(define (check-times-out ms thunk)
  (define e (engine (lambda (enable-stop) (thunk))))
  (define done? (engine-run ms e))
  (when done?
    (define result (engine-result e))
    (engine-kill e)
    (fail-check (format "expected timeout (~a ms), got result: ~s" ms result)))
  (engine-kill e)
  (check-false done?))

(test-case "assurance: bt_rel pluso heavy randomized"
  (for ([k (in-range 1000)])
    (define a (rand-int -500 500))
    (define b (rand-int -500 500))
    (define ra (int->bt a))
    (define rb (int->bt b))
    (define rz (run1 (lambda () (run 1 (q) (bt:pluso ra rb q)))))
    (check-not-false rz)
    (check-equal? (bt->int rz) (+ a b))))

(test-case "assurance: bt_rel *o heavy randomized"
  (for ([k (in-range 550)])
    (define a (rand-int -120 120))
    (define b (rand-int -120 120))
    (define ra (int->bt a))
    (define rb (int->bt b))
    (define rz (run1 (lambda () (run 1 (q) (bt:*o ra rb q)))))
    (check-not-false rz)
    (check-equal? (bt->int rz) (* a b))))

(test-case "assurance: engine timeout for known divergent shared-variable query"
  ;; Known divergent shape under unbounded shared-variable aliasing.
  (check-times-out
   200
   (lambda ()
     (run 3 (q)
       (bt:*o q q q)))))

(test-case "assurance: engine returns on finite query (sanity)"
  (define e
    (engine
     (lambda (enable-stop)
       (run 1 (q) (bt:pluso '(1) '(1) q)))))
  (define done? (engine-run 120 e))
  (check-true done?)
  (check-equal? (engine-result e) '((T 1)))
  (engine-kill e))
