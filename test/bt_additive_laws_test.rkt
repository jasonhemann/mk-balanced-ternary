#lang racket

(require (except-in rackunit fail)
         minikanren
         racket/random
         (file "../src/bt_rel.rkt")
         (file "support/bt_harness.rkt"))

(define (run1 thunk)
  (define sols (thunk))
  (if (null? sols) #f (car sols)))

(define (rand-int lo hi)
  (+ lo (random (+ 1 (- hi lo)))))

(define ints2
  (let ([m (max-abs-for-len 2)])
    (int-range (- m) m)))

(define ints3
  (let ([m (max-abs-for-len 3)])
    (int-range (- m) m)))

(define (plus-ground a b)
  (run1 (lambda () (run 1 (q) (pluso (int->bt-term a) (int->bt-term b) q)))))

(test-case "bt additive laws: pluso commutativity (exhaustive len<=3 domain)"
  (for* ([x ints3]
         [y ints3])
    (define xy (plus-ground x y))
    (define yx (plus-ground y x))
    (check-not-false xy)
    (check-not-false yx)
    (check-equal? (bt->int-term xy) (+ x y))
    (check-equal? (bt->int-term yx) (+ x y))
    (check-equal? xy yx)))

(test-case "bt additive laws: pluso associativity (exhaustive len<=2 domain)"
  (for* ([x ints2]
         [y ints2]
         [z ints2])
    (define left
      (run1
       (lambda ()
         (run 1 (q)
           (fresh (xy)
             (pluso (int->bt-term x) (int->bt-term y) xy)
             (pluso xy (int->bt-term z) q))))))
    (define right
      (run1
       (lambda ()
         (run 1 (q)
           (fresh (yz)
             (pluso (int->bt-term y) (int->bt-term z) yz)
             (pluso (int->bt-term x) yz q))))))
    (check-not-false left)
    (check-not-false right)
    (check-equal? (bt->int-term left) (+ x y z))
    (check-equal? (bt->int-term right) (+ x y z))
    (check-equal? left right)))

(test-case "bt additive laws: cancellation and inverse (exhaustive len<=3 domain)"
  (for* ([x ints3]
         [y ints3])
    (define restored
      (run1
       (lambda ()
         (run 1 (q)
           (fresh (z)
             (pluso (int->bt-term x) (int->bt-term y) z)
             (minuso z (int->bt-term y) q))))))
    (check-not-false restored)
    (check-equal? (bt->int-term restored) x))
  (for ([x ints3])
    (define inv
      (run1 (lambda ()
              (run 1 (q)
                (nego (int->bt-term x) q)))))
    (check-not-false inv)
    (define sum
      (run1 (lambda ()
              (run 1 (q)
                (pluso (int->bt-term x) inv q)))))
    (check-not-false sum)
    (check-equal? (bt->int-term sum) 0)))

(test-case "bt additive laws: randomized stress over wider range"
  (for ([i (in-range 300)])
    (define x (rand-int -200 200))
    (define y (rand-int -200 200))
    (define z (rand-int -200 200))
    (define xy (plus-ground x y))
    (define yz (plus-ground y z))
    (check-not-false xy)
    (check-not-false yz)
    (check-equal? (bt->int-term xy) (+ x y))
    (check-equal? (bt->int-term yz) (+ y z))
    (define left
      (run1 (lambda ()
              (run 1 (q)
                (pluso xy (int->bt-term z) q)))))
    (define right
      (run1 (lambda ()
              (run 1 (q)
                (pluso (int->bt-term x) yz q)))))
    (check-not-false left)
    (check-not-false right)
    (check-equal? (bt->int-term left) (+ x y z))
    (check-equal? (bt->int-term right) (+ x y z))
    (define restored
      (run1 (lambda ()
              (run 1 (q)
                (minuso xy (int->bt-term y) q)))))
    (check-not-false restored)
    (check-equal? (bt->int-term restored) x)))
