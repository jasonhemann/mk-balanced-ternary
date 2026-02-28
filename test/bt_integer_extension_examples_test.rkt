#lang racket

(require rackunit
         minikanren
         (file "../src/bt_rel.rkt")
         (only-in (file "support/bt_harness.rkt")
                  int->bt-term
                  bt->int-term
                  max-abs-for-len
                  int-range
                  bto-boundo
                  decode-bt-tuple))

(define (pair<? a b)
  (cond
    [(< (first a) (first b)) #t]
    [(> (first a) (first b)) #f]
    [else (< (second a) (second b))]))

(define (decode-bt-pair ans)
  (match ans
    [(list x y)
     (define xi (bt->int-term x))
     (define yi (bt->int-term y))
     (and (not (false? xi))
          (not (false? yi))
          (list xi yi))]
    [_ #f]))

(test-case "bt integer extension examples: additive core modes"
  (check-equal?
   (map bt->int-term (run* (q) (pluso (int->bt-term 29) (int->bt-term 3) q)))
   '(32))
  (check-equal?
   (map bt->int-term (run* (q) (pluso (int->bt-term 3) q (int->bt-term 29))))
   '(26))
  (check-equal?
   (map bt->int-term (run* (q) (pluso q (int->bt-term 3) (int->bt-term 29))))
   '(26))
  (check-equal?
   (map bt->int-term (run* (q) (pluso q (int->bt-term 29) (int->bt-term 3))))
   '(-26)))

(test-case "bt integer extension examples: subtractive core modes"
  (check-equal?
   (map bt->int-term (run* (q) (minuso (int->bt-term 29) (int->bt-term 3) q)))
   '(26))
  (check-equal?
   (map bt->int-term (run* (q) (minuso (int->bt-term 29) q (int->bt-term 3))))
   '(26))
  (check-equal?
   (map bt->int-term (run* (q) (minuso q (int->bt-term 3) (int->bt-term 26))))
   '(29))
  (check-equal?
   (map bt->int-term (run* (q) (minuso (int->bt-term 29) (int->bt-term 29) q)))
   '(0))
  (check-equal?
   (map bt->int-term (run* (q) (minuso (int->bt-term 29) (int->bt-term 30) q)))
   '(-1)))

(test-case "bt integer extension examples: bounded pair decomposition for sum 6"
  (define len 4)
  (define maxabs (max-abs-for-len len))
  (define ints (int-range (- maxabs) maxabs))
  (define expected
    (for*/list ([x ints]
                [y ints]
                #:when (= (+ x y) 6))
      (list x y)))
  (define observed
    (for/list ([ans (run* (xy)
                     (fresh (x y)
                       (bto-boundo x len)
                       (bto-boundo y len)
                       (pluso x y (int->bt-term 6))
                       (== xy (list x y))))])
      (decode-bt-pair ans)))
  (check-equal?
   (sort (remove-duplicates observed equal?) pair<?)
   (sort expected pair<?)))

(test-case "bt integer extension examples: x+1=y stream has concrete then symbolic answers"
  (define succ
    (run 4 (q)
      (fresh (x y)
        (pluso x '(1) y)
        (== q (list x y)))))
  (check-equal? (decode-bt-pair (first succ)) '(0 1))
  (check-equal? (decode-bt-pair (second succ)) '(-1 0))
  (define third-decoded (decode-bt-pair (third succ)))
  (when third-decoded
    (check-equal? (+ (first third-decoded) 1)
                  (second third-decoded))))
