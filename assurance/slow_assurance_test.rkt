#lang racket

(require (except-in rackunit fail)
         minikanren
         racket/engine
         racket/random
         (file "../src/bt_oracle.rkt")
         (prefix-in bt: (file "../src/bt_rel.rkt"))
         (prefix-in bn: (file "../src/binary-numbers.rkt")))

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

(define (bn->int bn)
  (let loop ([ds bn] [place 1] [acc 0])
    (cond
      [(null? ds) acc]
      [else
       (loop (cdr ds)
             (* place 2)
             (+ acc (* (car ds) place)))])))

(define (int->bn n)
  (cond
    [(zero? n) '()]
    [else (cons (modulo n 2) (int->bn (quotient n 2)))]))

(test-case "assurance: binary pluso/*o heavy randomized"
  (for ([k (in-range 1100)])
    (define a (rand-int 0 350))
    (define b (rand-int 0 350))
    (define ra (int->bn a))
    (define rb (int->bn b))
    (define sum (run1 (lambda () (run 1 (q) (bn:pluso ra rb q)))))
    (define prod (run1 (lambda () (run 1 (q) (bn:*o ra rb q)))))
    (check-not-false sum)
    (check-not-false prod)
    (check-equal? (bn->int sum) (+ a b))
    (check-equal? (bn->int prod) (* a b))))

(test-case "assurance: engine timeout for known divergent shared-variable query"
  ;; Known divergent shape from the original arithmetic discussion.
  ;; Equivalent to searching for X where 3*(2X+1) = (2X+1), which never resolves.
  (check-times-out
   120
   (lambda ()
     (run 1 (q)
       (fresh (x)
         (bn:*o '(1 1) `(1 . ,x) `(1 0 . ,x))
         (== q x))))))

(test-case "assurance: engine returns on finite query (sanity)"
  (define e
    (engine
     (lambda (enable-stop)
       (run 1 (q) (bn:pluso '(1) '(1) q)))))
  (define done? (engine-run 120 e))
  (check-true done?)
  (check-equal? (engine-result e) '((0 1)))
  (engine-kill e))
