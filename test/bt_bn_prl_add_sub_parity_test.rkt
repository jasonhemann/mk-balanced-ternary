#lang racket

(require rackunit
         minikanren
         (prefix-in bt: (file "../src/bt_rel.rkt"))
         (prefix-in bn: (file "../src/binary-numbers.rkt"))
         (only-in (file "support/bt_harness.rkt")
                  int->bt-term
                  bt->int-term
                  max-abs-for-len
                  int-range
                  decode-bt-tuple
                  bto-boundo)
         (only-in (file "support/bn_harness.rkt")
                  nat->bn
                  bn->nat
                  nat-range
                  decode-bn-tuple))

(define (pair<? a b)
  (cond
    [(< (first a) (first b)) #t]
    [(> (first a) (first b)) #f]
    [else (< (second a) (second b))]))

(define (decode-bn-pair ans)
  (match ans
    [(list x y)
     (define xi (bn->nat x))
     (define yi (bn->nat y))
     (and (not (false? xi))
          (not (false? yi))
          (list xi yi))]
    [_ #f]))

(define (decode-bt-pair ans)
  (match ans
    [(list x y)
     (define xi (bt->int-term x))
     (define yi (bt->int-term y))
     (and (not (false? xi))
          (not (false? yi))
          (list xi yi))]
    [_ #f]))

(test-case "prl parity add: core mode examples in binary baseline and BT mutatis mutandis"
  ;; Binary baseline from arith.prl:
  ;; add(29,3,X)=32; add(3,X,29)=26; add(X,3,29)=26; add(_,29,3) fails.
  (check-equal?
   (map bn->nat (run* (q) (bn:pluso (nat->bn 29) (nat->bn 3) q)))
   '(32))
  (check-equal?
   (map bn->nat (run* (q) (bn:pluso (nat->bn 3) q (nat->bn 29))))
   '(26))
  (check-equal?
   (map bn->nat (run* (q) (bn:pluso q (nat->bn 3) (nat->bn 29))))
   '(26))
  (check-equal?
   (run* (q) (bn:pluso q (nat->bn 29) (nat->bn 3)))
   '())

  ;; BT analogue over integers: same first three equations, and the last one
  ;; has the integer solution q = -26 instead of finite failure.
  (check-equal?
   (map bt->int-term (run* (q) (bt:pluso (int->bt-term 29) (int->bt-term 3) q)))
   '(32))
  (check-equal?
   (map bt->int-term (run* (q) (bt:pluso (int->bt-term 3) q (int->bt-term 29))))
   '(26))
  (check-equal?
   (map bt->int-term (run* (q) (bt:pluso q (int->bt-term 3) (int->bt-term 29))))
   '(26))
  (check-equal?
   (map bt->int-term (run* (q) (bt:pluso q (int->bt-term 29) (int->bt-term 3))))
   '(-26)))

(test-case "prl parity sub: core mode examples in binary baseline and BT mutatis mutandis"
  ;; Binary baseline from arith.prl:
  ;; sub(29,3,X)=26; sub(29,X,3)=26; sub(X,3,26)=29; sub(29,29,X)=0;
  ;; sub(29,30,_) fails.
  (check-equal?
   (map bn->nat (run* (q) (bn:minuso (nat->bn 29) (nat->bn 3) q)))
   '(26))
  (check-equal?
   (map bn->nat (run* (q) (bn:minuso (nat->bn 29) q (nat->bn 3))))
   '(26))
  (check-equal?
   (map bn->nat (run* (q) (bn:minuso q (nat->bn 3) (nat->bn 26))))
   '(29))
  (check-equal?
   (map bn->nat (run* (q) (bn:minuso (nat->bn 29) (nat->bn 29) q)))
   '(0))
  (check-equal?
   (run* (q) (bn:minuso (nat->bn 29) (nat->bn 30) q))
   '())

  ;; BT analogue over integers: same first four equations, and the last one
  ;; has the integer solution q = -1 instead of finite failure.
  (check-equal?
   (map bt->int-term (run* (q) (bt:minuso (int->bt-term 29) (int->bt-term 3) q)))
   '(26))
  (check-equal?
   (map bt->int-term (run* (q) (bt:minuso (int->bt-term 29) q (int->bt-term 3))))
   '(26))
  (check-equal?
   (map bt->int-term (run* (q) (bt:minuso q (int->bt-term 3) (int->bt-term 26))))
   '(29))
  (check-equal?
   (map bt->int-term (run* (q) (bt:minuso (int->bt-term 29) (int->bt-term 29) q)))
   '(0))
  (check-equal?
   (map bt->int-term (run* (q) (bt:minuso (int->bt-term 29) (int->bt-term 30) q)))
   '(-1)))

(test-case "prl parity add decomposition: all pairs summing to 6 (binary finite, BT bounded)"
  ;; Binary: add(X,Y,6) has exactly the natural-number pairs listed in arith.prl.
  (define binary-pairs
    (for/list ([ans (run* (xy)
                     (fresh (x y)
                       (bn:pluso x y (nat->bn 6))
                       (== xy (list x y))))])
      (decode-bn-pair ans)))
  (check-equal?
   (sort (remove-duplicates binary-pairs equal?) pair<?)
   '((0 6) (1 5) (2 4) (3 3) (4 2) (5 1) (6 0)))

  ;; BT: over integers the set is infinite, so we check the bounded analogue.
  (define len 4)
  (define maxabs (max-abs-for-len len))
  (define bt-ints (int-range (- maxabs) maxabs))
  (define expected-bt
    (for*/list ([x bt-ints]
                [y bt-ints]
                #:when (= (+ x y) 6))
      (list x y)))
  (define bt-pairs
    (for/list ([ans (run* (xy)
                     (fresh (x y)
                       (bto-boundo x len)
                       (bto-boundo y len)
                       (bt:pluso x y (int->bt-term 6))
                       (== xy (list x y))))])
      (decode-bt-pair ans)))
  (check-equal?
   (sort (remove-duplicates bt-pairs equal?) pair<?)
   (sort expected-bt pair<?)))

(test-case "prl parity symbolic generality: x+1=y yields concrete prefixes then symbolic classes"
  ;; Binary baseline mirrors the show-off stream in arith.prl comments.
  (define bn-succ
    (run 4 (q)
      (fresh (x y)
        (bn:pluso x '(1) y)
        (== q (list x y)))))
  (check-equal? (decode-bn-pair (first bn-succ)) '(0 1))
  (check-equal? (decode-bn-pair (second bn-succ)) '(1 2))
  (check-false (decode-bn-tuple (third bn-succ)))

  ;; BT analogue includes negative predecessor/successor pairs and symbolic
  ;; classes in the same query shape.
  (define bt-succ
    (run 4 (q)
      (fresh (x y)
        (bt:pluso x '(1) y)
        (== q (list x y)))))
  (check-equal? (decode-bt-pair (first bt-succ)) '(0 1))
  (check-equal? (decode-bt-pair (second bt-succ)) '(-1 0))
  (check-false (decode-bt-tuple (third bt-succ))))
