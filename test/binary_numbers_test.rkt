#lang racket

(require (except-in rackunit fail)
         minikanren
         racket/list
         racket/random
         (file "../src/binary-numbers.rkt"))

(define bits '(0 1))

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

(define (canonical-bn? bn)
  (or (null? bn) (= (last bn) 1)))

(define (run1 thunk)
  (define sols (thunk))
  (if (null? sols) #f (car sols)))

(define (plus-ground a b)
  (run1 (lambda () (run 1 (q) (pluso a b q)))))

(define (mul-ground a b)
  (run1 (lambda () (run 1 (q) (*o a b q)))))

(define (rand-int lo hi)
  (+ lo (random (+ 1 (- hi lo)))))

;; Test-only bounded canonical predicate.
(define (bno-boundo q maxlen)
  (define (gen-len len)
    (cond
      [(= len 1) (list '(1))]
      [else
       (apply append
              (for/list ([d bits])
                (map (lambda (rest) (cons d rest))
                     (gen-len (sub1 len)))))]))
  (define all-bns
    (append
     (list '())
     (apply append
            (for/list ([len (in-range 1 (add1 maxlen))])
              (gen-len len)))))
  (define (disj lst)
    (cond
      [(null? lst) (== #f #t)]
      [else
       (conde
         [(== q (car lst))]
         [(disj (cdr lst))])]))
  (disj all-bns))

;; Book-style one-bit relations used in chapter tests.
(defrel (bit-xoro x y r)
  (conde
    [(== 0 x) (== 0 y) (== 0 r)]
    [(== 0 x) (== 1 y) (== 1 r)]
    [(== 1 x) (== 0 y) (== 1 r)]
    [(== 1 x) (== 1 y) (== 0 r)]))

(defrel (bit-ando x y r)
  (conde
    [(== 0 x) (== 0 y) (== 0 r)]
    [(== 1 x) (== 0 y) (== 0 r)]
    [(== 0 x) (== 1 y) (== 0 r)]
    [(== 1 x) (== 1 y) (== 1 r)]))

(defrel (half-adder-booko x y r c)
  (bit-xoro x y r)
  (bit-ando x y c))

(defrel (full-adder-booko b x y r c)
  (fresh (w xy wz)
    (half-adder-booko x y w xy)
    (half-adder-booko w b r wz)
    (bit-xoro xy wz c)))

(test-case "book port: bit-xoro relation"
  (check-equal?
   (run* (x y) (bit-xoro x y 0))
   '((0 0) (1 1)))
  (check-equal?
   (run* (x y) (bit-xoro x y 1))
   '((0 1) (1 0)))
  (check-equal?
   (run* (x y r) (bit-xoro x y r))
   '((0 0 0) (0 1 1) (1 0 1) (1 1 0))))

(test-case "book port: bit-ando and half-adder"
  (check-equal?
   (run* (x y) (bit-ando x y 1))
   '((1 1)))
  (check-equal?
   (run* (r c) (half-adder-booko 1 1 r c))
   '((0 1)))
  (check-equal?
   (run* (x y r c) (half-adder-booko x y r c))
   '((0 0 0 0) (0 1 1 0) (1 0 1 0) (1 1 0 1))))

(test-case "book port: full-adder agrees with binary add3o/full-addero"
  (for* ([a bits] [b bits] [cin bits])
    (define got-book
      (run1 (lambda ()
              (run 1 (q)
                (fresh (s c)
                  (full-adder-booko cin a b s c)
                  (== q (list s c)))))))
    (define got-add3
      (run1 (lambda ()
              (run 1 (q)
                (fresh (s c)
                  (add3o cin a b s c)
                  (== q (list s c)))))))
    (define got-full
      (run1 (lambda ()
              (run 1 (q)
                (fresh (s c)
                  (full-addero cin a b s c)
                  (== q (list s c)))))))
    (check-not-false got-book)
    (check-equal? got-book got-add3)
    (check-equal? got-book got-full)))

(test-case "build-num examples from book"
  (check-equal? (build-num 0) '())
  (check-equal? (build-num 5) '(1 0 1))
  (check-equal? (build-num 7) '(1 1 1))
  (check-equal? (build-num 9) '(1 0 0 1))
  (check-equal? (build-num 19) '(1 1 0 0 1))
  (check-equal? (build-num 36) '(0 0 1 0 0 1)))

(test-case "poso/gt1o basics"
  (check-not-false (run1 (lambda () (run 1 (q) (poso '(1))))))
  (check-false (run1 (lambda () (run 1 (q) (poso '())))))
  (check-not-false (run1 (lambda () (run 1 (q) (gt1o '(0 1))))))
  (check-false (run1 (lambda () (run 1 (q) (gt1o '(1))))))
  (check-false (run1 (lambda () (run 1 (q) (gt1o '()))))))

(test-case "book-style pluso/minuso ground examples"
  (define pairs
    (run* (xy)
      (fresh (x y)
        (bno-boundo x 6)
        (bno-boundo y 6)
        (pluso x y '(1 0 1))
        (== xy (list x y)))))
  (for ([xy pairs])
    (check-equal? (+ (bn->int (first xy)) (bn->int (second xy))) 5))
  (for ([expected '(((1 0 1) ())
                    (() (1 0 1))
                    ((1) (0 0 1))
                    ((0 0 1) (1))
                    ((1 1) (0 1))
                    ((0 1) (1 1)))])
    (check-not-false (member expected pairs equal?)))
  (check-equal?
   (run* (q) (minuso '(0 0 0 1) '(1 0 1) q))
   '((1 1)))
  (check-equal?
   (run* (q) (minuso '(0 1 1) '(0 1 1) q))
   '(()))
  (check-equal?
   (run* (q) (minuso '(0 1 1) '(0 0 0 1) q))
   '()))

(test-case "book-style multiplication examples"
  (check-equal?
   (run* (p) (*o '(0 1) '(0 0 1) p))
   '((0 0 0 1)))
  (check-equal?
   (run 2 (n m) (*o n m '(1)))
   '(((1) (1))))
  (check-equal?
   (run* (p) (*o '(1 1 1) '(1 1 1 1 1 1) p))
   '((1 0 0 1 1 1 0 1 1))))

(test-case "logo base case for n=1 is canonical and non-overlapping"
  (define answers (run 2 (b) (logo '(1) b '() '())))
  (check-equal? (length answers) 2)
  (check-equal? (first answers) '(1))
  (check-not-false
   (run1 (lambda ()
           (run 1 (q)
             (fresh (b)
               (logo '(1) b '() '())
               (gt1o b)
               (== q 'ok)))))))

(test-case "naming aliases behave identically"
  (define a '(1 0 1 1))
  (define b '(1 1 0))
  (check-equal?
   (run1 (lambda () (run 1 (q) (add-carryo 0 a b q))))
   (run1 (lambda () (run 1 (q) (addero 0 a b q)))))
  (check-equal?
   (run1 (lambda () (run 1 (q) (add-carry-stepo 0 '(1) b q))))
   (run1 (lambda () (run 1 (q) (gen-addero 0 '(1) b q)))))
  (check-equal?
   (run 6 (q) (gt1o q))
   (run 6 (q) (>1o q)))
  (check-equal?
   (run1 (lambda () (run 1 (q) (odd-mulo '(1) '(1 0 1) '(1 1) q))))
   (run1 (lambda () (run 1 (q) (odd-*o '(1) '(1 0 1) '(1 1) q)))))
  (check-equal?
   (run1 (lambda () (run 1 (q) (bound-mulo q '(1 0 1) '(1 1) '(1)))))
   (run1 (lambda () (run 1 (q) (bound-*o q '(1 0 1) '(1 1) '(1)))))))

(test-case "pluso ground/ground randomized vs host arithmetic"
  (for ([k (in-range 140)])
    (define a (rand-int 0 200))
    (define b (rand-int 0 200))
    (define ra (int->bn a))
    (define rb (int->bn b))
    (define rz (plus-ground ra rb))
    (check-not-false rz)
    (check-true (canonical-bn? rz))
    (check-equal? (bn->int rz) (+ a b))))

(test-case "minuso agrees with subtraction on naturals"
  (for ([k (in-range 90)])
    (define a (rand-int 0 200))
    (define b (rand-int 0 a))
    (define ra (int->bn a))
    (define rb (int->bn b))
    (define rk
      (run1 (lambda () (run 1 (q) (minuso ra rb q)))))
    (check-not-false rk)
    (check-equal? (bn->int rk) (- a b))))

(test-case "pluso ground/var bounded returns only correct naturals"
  (for ([k (in-range 50)])
    (define a (rand-int 0 80))
    (define z (rand-int 0 80))
    (define ra (int->bn a))
    (define rz (int->bn z))
    (define sols
      (run 8 (q)
        (bno-boundo q 10)
        (pluso ra q rz)))
    (for ([q sols])
      (check-equal? (+ a (bn->int q)) z))
    (if (>= z a)
        (check-not-false (member (int->bn (- z a)) sols equal?))
        (check-equal? sols '()))))

(test-case "*o ground/ground randomized vs host arithmetic"
  (for ([k (in-range 90)])
    (define a (rand-int 0 90))
    (define b (rand-int 0 90))
    (define ra (int->bn a))
    (define rb (int->bn b))
    (define rz (mul-ground ra rb))
    (check-not-false rz)
    (check-true (canonical-bn? rz))
    (check-equal? (bn->int rz) (* a b))))

(test-case "*o ground/var bounded returns only valid factors"
  (for ([k (in-range 30)])
    (define a (rand-int 1 30))
    (define z (rand-int 0 180))
    (define ra (int->bn a))
    (define rz (int->bn z))
    (define sols
      (run 15 (q)
        (bno-boundo q 10)
        (*o ra q rz)))
    (for ([q sols])
      (check-equal? (* a (bn->int q)) z))
    (when (and (zero? (remainder z a))
               (<= (length (int->bn (quotient z a))) 10))
      (check-not-false (member (int->bn (quotient z a)) sols equal?)))))
