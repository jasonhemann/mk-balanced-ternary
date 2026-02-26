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

(define (mul-ground a b)
  (run1 (lambda () (run 1 (q) (*o (int->bt-term a) (int->bt-term b) q)))))

(define (plus-ground a b)
  (run1 (lambda () (run 1 (q) (pluso (int->bt-term a) (int->bt-term b) q)))))

(test-case "bt multiplicative laws: commutativity (exhaustive len<=3 domain)"
  (for* ([x ints3]
         [y ints3])
    (define xy (mul-ground x y))
    (define yx (mul-ground y x))
    (check-not-false xy)
    (check-not-false yx)
    (check-equal? (bt->int-term xy) (* x y))
    (check-equal? (bt->int-term yx) (* x y))
    (check-equal? xy yx)))

(test-case "bt multiplicative laws: associativity (exhaustive len<=2 domain)"
  (for* ([x ints2]
         [y ints2]
         [z ints2])
    (define left
      (run1
       (lambda ()
         (run 1 (q)
           (fresh (xy)
             (*o (int->bt-term x) (int->bt-term y) xy)
             (*o xy (int->bt-term z) q))))))
    (define right
      (run1
       (lambda ()
         (run 1 (q)
           (fresh (yz)
             (*o (int->bt-term y) (int->bt-term z) yz)
             (*o (int->bt-term x) yz q))))))
    (check-not-false left)
    (check-not-false right)
    (check-equal? (bt->int-term left) (* x y z))
    (check-equal? (bt->int-term right) (* x y z))
    (check-equal? left right)))

(test-case "bt multiplicative laws: distributivity over pluso (exhaustive len<=2 domain)"
  (for* ([x ints2]
         [y ints2]
         [z ints2])
    (define left
      (run1
       (lambda ()
         (run 1 (q)
           (fresh (yz)
             (pluso (int->bt-term y) (int->bt-term z) yz)
             (*o (int->bt-term x) yz q))))))
    (define right
      (run1
       (lambda ()
         (run 1 (q)
           (fresh (xy xz)
             (*o (int->bt-term x) (int->bt-term y) xy)
             (*o (int->bt-term x) (int->bt-term z) xz)
             (pluso xy xz q))))))
    (check-not-false left)
    (check-not-false right)
    (check-equal? (bt->int-term left) (* x (+ y z)))
    (check-equal? (bt->int-term right) (* x (+ y z)))
    (check-equal? left right)))

(test-case "bt multiplicative laws: identities and zero annihilator (exhaustive len<=3 domain)"
  (for ([x ints3])
    (define x*1
      (mul-ground x 1))
    (define 1*x
      (mul-ground 1 x))
    (define x*0
      (mul-ground x 0))
    (define 0*x
      (mul-ground 0 x))
    (check-not-false x*1)
    (check-not-false 1*x)
    (check-not-false x*0)
    (check-not-false 0*x)
    (check-equal? (bt->int-term x*1) x)
    (check-equal? (bt->int-term 1*x) x)
    (check-equal? (bt->int-term x*0) 0)
    (check-equal? (bt->int-term 0*x) 0)))

(test-case "bt multiplicative laws: randomized stress"
  (for ([i (in-range 250)])
    (define x (rand-int -120 120))
    (define y (rand-int -120 120))
    (define z (rand-int -120 120))
    (define xy (mul-ground x y))
    (define yz (mul-ground y z))
    (check-not-false xy)
    (check-not-false yz)
    (check-equal? (bt->int-term xy) (* x y))
    (check-equal? (bt->int-term yz) (* y z))
    (define left
      (run1 (lambda ()
              (run 1 (q)
                (*o xy (int->bt-term z) q)))))
    (define right
      (run1 (lambda ()
              (run 1 (q)
                (*o (int->bt-term x) yz q)))))
    (check-not-false left)
    (check-not-false right)
    (check-equal? (bt->int-term left) (* x y z))
    (check-equal? (bt->int-term right) (* x y z))
    (define yz-sum
      (plus-ground y z))
    (check-not-false yz-sum)
    (define dist-left
      (run1 (lambda ()
              (run 1 (q)
                (*o (int->bt-term x) yz-sum q)))))
    (define dist-right
      (run1 (lambda ()
              (run 1 (q)
                (fresh (xyv xzv)
                  (*o (int->bt-term x) (int->bt-term y) xyv)
                  (*o (int->bt-term x) (int->bt-term z) xzv)
                  (pluso xyv xzv q))))))
    (check-not-false dist-left)
    (check-not-false dist-right)
    (check-equal? (bt->int-term dist-left) (* x (+ y z)))
    (check-equal? (bt->int-term dist-right) (* x (+ y z)))))
