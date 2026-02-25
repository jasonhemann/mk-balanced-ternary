#lang racket

(require (except-in rackunit fail)
         minikanren
         (file "../src/bt_rel.rkt")
         (file "support/bt_harness.rkt"))

(define (make-bound len)
  (build-list len (lambda (i) 'k)))

(define maxlen 2)
(define bt-bound (make-bound maxlen))
(define maxabs (max-abs-for-len maxlen))
(define ints (int-range (- maxabs) maxabs))
(define trits '(T 0 1))

(define (trit->int t)
  (cond
    [(eq? t 'T) -1]
    [(equal? t 0) 0]
    [else 1]))

(define (maybe-values maybe domain)
  (if maybe (list maybe) domain))

(define (mode-limits expected)
  (define n (max 1 (length (remove-duplicates expected equal?))))
  (values (min 16 n) (max (+ n 6) (* 8 n))))

(define (bind-if var maybe-int)
  (if maybe-int
      (== var (int->bt-term maybe-int))
      (== var var)))

(define (bind-trit-if var maybe-trit)
  (if maybe-trit
      (== var maybe-trit)
      (== var var)))

(define (enum-plus x y z)
  (for*/list ([xi (maybe-values x ints)]
              [yi (maybe-values y ints)]
              [zi (maybe-values z ints)]
              #:when (= (+ xi yi) zi))
    (list xi yi zi)))

(define (enum-minus x y z)
  (for*/list ([xi (maybe-values x ints)]
              [yi (maybe-values y ints)]
              [zi (maybe-values z ints)]
              #:when (= (- xi yi) zi))
    (list xi yi zi)))

(define (enum-mul x y z)
  (for*/list ([xi (maybe-values x ints)]
              [yi (maybe-values y ints)]
              [zi (maybe-values z ints)]
              #:when (= (* xi yi) zi))
    (list xi yi zi)))

(define (enum-mul1 x b out)
  (for*/list ([xi (maybe-values x ints)]
              [bi (maybe-values b trits)]
              [oi (maybe-values out ints)]
              #:when (= (* xi (trit->int bi)) oi))
    (list xi bi oi)))

(define (all-add3)
  (for*/list ([a trits]
              [b trits]
              [cin trits]
              [s trits]
              [cout trits]
              #:when (= (+ (trit->int a)
                           (trit->int b)
                           (trit->int cin))
                        (+ (trit->int s)
                           (* 3 (trit->int cout)))))
    (list a b cin s cout)))

(define add3-domain (all-add3))

(define (enum-add3 a b cin s cout)
  (for/list ([row add3-domain]
             #:when
             (match row
               [(list ra rb rcin rs rcout)
                (and (if a (equal? a ra) #t)
                     (if b (equal? b rb) #t)
                     (if cin (equal? cin rcin) #t)
                     (if s (equal? s rs) #t)
                     (if cout (equal? cout rcout) #t))]))
    row))

(define arith-mode-specs
  ;; Each tuple is (label x y z), where #f means logic variable.
  (list
   (list "ggg" 2 -1 1)
   (list "ggv" 2 -1 #f)
   (list "gvg" 2 #f 1)
   (list "vgg" #f -1 1)
   (list "gvv" 2 #f #f)
   (list "vgv" #f -1 #f)
   (list "vvg" #f #f 1)
   (list "vvv" #f #f #f)))

(test-case "bt bounds relation: canonical length-limited numerals over len<=2"
  (define expected
    (for/list ([n ints]) (list n)))
  (define-values (k k2) (mode-limits expected))
  (check-bt-case-strict
   "bounded-domain/len2"
   #:expected-set expected
   #:run-observed
   (lambda (limit)
     (run limit (q)
       (bto-boundedo q bt-bound)))
   #:decode-answer decode-bt-tuple
   #:k k
   #:k2 k2
   #:timeout-ms 1200))

(test-case "bt mode matrix: add3o all grounding patterns over trits"
  ;; Seed assignment comes from a valid add3 tuple: 1 + 1 + 1 = 0 + 3*1.
  (define seed '(1 1 1 0 1))
  (for* ([ga '(#f #t)]
         [gb '(#f #t)]
         [gcin '(#f #t)]
         [gs '(#f #t)]
         [gcout '(#f #t)])
    (define a (and ga (list-ref seed 0)))
    (define b (and gb (list-ref seed 1)))
    (define cin (and gcin (list-ref seed 2)))
    (define s (and gs (list-ref seed 3)))
    (define cout (and gcout (list-ref seed 4)))
    (define expected (enum-add3 a b cin s cout))
    (define-values (k k2) (mode-limits expected))
    (check-bt-case-strict
     (format "add3o/~a~a~a~a~a"
             (if ga "g" "v")
             (if gb "g" "v")
             (if gcin "g" "v")
             (if gs "g" "v")
             (if gcout "g" "v"))
     #:expected-set expected
     #:run-observed
     (lambda (limit)
       (run limit (q)
         (fresh (ra rb rcin rs rcout)
           (trito ra) (trito rb) (trito rcin) (trito rs) (trito rcout)
           (bind-trit-if ra a)
           (bind-trit-if rb b)
           (bind-trit-if rcin cin)
           (bind-trit-if rs s)
           (bind-trit-if rcout cout)
           (add3o ra rb rcin rs rcout)
           (== q (list ra rb rcin rs rcout)))))
     #:decode-answer (lambda (raw) raw)
     #:k k
     #:k2 k2
     #:timeout-ms 1200)))

(test-case "bt mode matrix: mul1o all grounding patterns over len<=2"
  (define specs
    (list
     (list "ggg" 2 1 2)
     (list "ggv" 2 1 #f)
     (list "gvg" 2 #f 2)
     (list "vgg" #f 1 2)
     (list "gvv" 2 #f #f)
     (list "vgv" #f 1 #f)
     (list "vvg" #f #f 2)
     (list "vvv" #f #f #f)))
  (define (decode-mul1 raw)
    (match raw
      [(list x b out)
       (define xi (bt->int-term x))
       (define oi (bt->int-term out))
       (if (or (false? xi) (false? oi))
           #f
           (list xi b oi))]
      [_ #f]))
  (for ([spec specs])
    (match-define (list label x b out) spec)
    (define expected (enum-mul1 x b out))
    (define-values (k k2) (mode-limits expected))
    (check-bt-case-strict
     (format "mul1o/~a" label)
     #:expected-set expected
     #:run-observed
     (lambda (limit)
       (run limit (q)
         (fresh (rx rb rout)
           (bto-boundedo rx bt-bound)
           (bto-boundedo rout bt-bound)
           (trito rb)
           (bind-if rx x)
           (bind-trit-if rb b)
           (bind-if rout out)
           (mul1o rx rb rout)
           (== q (list rx rb rout)))))
     #:decode-answer decode-mul1
     #:k k
     #:k2 k2
     #:timeout-ms 1200)))

(test-case "bt mode matrix: pluso all grounding patterns over len<=2"
  (for ([spec arith-mode-specs])
    (match-define (list label x y z) spec)
    (define expected (enum-plus x y z))
    (define-values (k k2) (mode-limits expected))
    (check-bt-case-strict
     (format "pluso/~a" label)
     #:expected-set expected
     #:run-observed
     (lambda (limit)
       (run limit (q)
         (fresh (rx ry rz)
           (bto-boundedo rx bt-bound)
           (bto-boundedo ry bt-bound)
           (bto-boundedo rz bt-bound)
           (bind-if rx x)
           (bind-if ry y)
           (bind-if rz z)
           (pluso rx ry rz)
           (== q (list rx ry rz)))))
     #:decode-answer decode-bt-tuple
     #:k k
     #:k2 k2
     #:timeout-ms 1600)))

(test-case "bt mode matrix: minuso all grounding patterns over len<=2"
  (for ([spec arith-mode-specs])
    (match-define (list label x y z) spec)
    (define expected (enum-minus x y z))
    (define-values (k k2) (mode-limits expected))
    (check-bt-case-strict
     (format "minuso/~a" label)
     #:expected-set expected
     #:run-observed
     (lambda (limit)
       (run limit (q)
         (fresh (rx ry rz)
           (bto-boundedo rx bt-bound)
           (bto-boundedo ry bt-bound)
           (bto-boundedo rz bt-bound)
           (bind-if rx x)
           (bind-if ry y)
           (bind-if rz z)
           (minuso rx ry rz)
           (== q (list rx ry rz)))))
     #:decode-answer decode-bt-tuple
     #:k k
     #:k2 k2
     #:timeout-ms 1600)))

(test-case "bt mode matrix: *o all grounding patterns over len<=2"
  (for ([spec arith-mode-specs])
    (match-define (list label x y z) spec)
    (define expected (enum-mul x y z))
    (define-values (k k2) (mode-limits expected))
    (check-bt-case-strict
     (format "*o/~a" label)
     #:expected-set expected
     #:run-observed
     (lambda (limit)
       (run limit (q)
         (fresh (rx ry rz)
           (bto-boundedo rx bt-bound)
           (bto-boundedo ry bt-bound)
           (bto-boundedo rz bt-bound)
           (bind-if rx x)
           (bind-if ry y)
           (bind-if rz z)
           (*o rx ry rz)
           (== q (list rx ry rz)))))
     #:decode-answer decode-bt-tuple
     #:k k
     #:k2 k2
     #:timeout-ms 2000)))

(test-case "bt bounded goals: conjunction order sanity for pluso and *o"
  (define (norm xs)
    (sort (remove-duplicates xs equal?) string<? #:key format))
  (define plus-a
    (run* (q)
      (fresh (x y z)
        (bto-boundedo x bt-bound)
        (bto-boundedo y bt-bound)
        (bto-boundedo z bt-bound)
        (== x (int->bt-term 2))
        (== y (int->bt-term -1))
        (pluso x y z)
        (== q z))))
  (define plus-b
    (run* (q)
      (fresh (x y z)
        (bto-boundedo x bt-bound)
        (bto-boundedo y bt-bound)
        (bto-boundedo z bt-bound)
        (pluso x y z)
        (== x (int->bt-term 2))
        (== y (int->bt-term -1))
        (== q z))))
  (check-equal? (norm (map decode-bt-tuple plus-a))
                (norm (map decode-bt-tuple plus-b)))

  (define mul-a
    (run* (q)
      (fresh (x y z)
        (bto-boundedo x bt-bound)
        (bto-boundedo y bt-bound)
        (bto-boundedo z bt-bound)
        (== x (int->bt-term 2))
        (== y (int->bt-term -2))
        (*o x y z)
        (== q z))))
  (define mul-b
    (run* (q)
      (fresh (x y z)
        (bto-boundedo x bt-bound)
        (bto-boundedo y bt-bound)
        (bto-boundedo z bt-bound)
        (*o x y z)
        (== x (int->bt-term 2))
        (== y (int->bt-term -2))
        (== q z))))
  (check-equal? (norm (map decode-bt-tuple mul-a))
                (norm (map decode-bt-tuple mul-b))))
