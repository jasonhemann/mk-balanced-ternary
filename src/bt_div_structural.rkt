#lang racket

(require minikanren
         (file "bt_rel.rkt"))

(provide (all-defined-out))

;; Extract the most-significant trit (tail end in LSD-first lists).
(defrel (msd-trito n d)
  (fresh (a rest)
    (== `(,a . ,rest) n)
    (conde
      [(== rest '()) (== d a)]
      [(nonzeroo rest) (msd-trito rest d)])))

;; Nonnegative/positive/negative classifiers without generic bound envelopes.
(defrel (nato n)
  (canco n)
  (conde
    [(== n '())]
    [(fresh (d)
       (msd-trito n d)
       (== d '1))]))

(defrel (posnato n)
  (nato n)
  (nonzeroo n))

(defrel (negato n)
  (canco n)
  (fresh (d)
    (msd-trito n d)
    (== d 'T)))

;; Natural-order helper specialized to nonnegative BT numerals.
;; y > x  <=>  exists positive natural delta with x + delta = y.
(defrel (lto-nato x y)
  (fresh (delta)
    (posnato delta)
    (pluso x delta y)))

;; Nonnegative correction step for one LSD-first long-division digit.
(defrel (div-correct-nato t m qrest q r)
  (fresh (qshift)
    (shift3o qrest qshift)
    (conde
      ;; k = -1 : only possible at t = -1, i.e. d='T and r'='().
      [(== t '(T))
       (pluso q '(1) qshift)
       (pluso t m r)]
      ;; k = 0
      [(== q qshift)
       (== r t)
       (nato r)
       (lto-nato r m)]
      ;; k = 1
      [(pluso qshift '(1) q)
       (pluso m r t)
       (nato r)
       (lto-nato r m)]
      ;; k = 2
      [(fresh (mm)
         (pluso m m mm)
         (pluso mm r t)
         (pluso qshift '(T 1) q)
         (nato r)
         (lto-nato r m))])))

;; Nonnegative Euclidean core (m > 0).
(defrel (divo-nat-structo n m q r)
  (nato n)
  (posnato m)
  (conde
    [(lto-nato n m)
     (== q '())
     (== r n)]
    [(== m '(1))
     (== q n)
     (== r '())]
    [(fresh (d nrest qrest rrest t)
       (== n `(,d . ,nrest))
       (trito d)
       (conde
         [(== n m)]
         [(lto-nato m n)])
       (divo-nat-structo nrest m qrest rrest)
       (times3-plus-digito rrest d t)
       (div-correct-nato t m qrest q r))])
  (nato q)
  (nato r)
  (lto-nato r m))

;; Alternative structural-dispatch Euclidean division surface.
;; This is a prototype path toward arithm.prl-style local dispatch.
(defrel (divo-structo n m q r)
  (canco n)
  (canco m)
  (nonzeroo m)
  (conde
    ;; m > 0
    [(posnato m)
     (conde
       [(nato n)
        (nato q)
        (divo-nat-structo n m q r)]
       [(fresh (an q0 r0)
          (negato n)
          (negateo n an)
          (nato an)
          (divo-nat-structo an m q0 r0)
          (conde
            [(== r0 '())
             (== r '())
             (negateo q0 q)]
            [(nonzeroo r0)
             (fresh (q0+1)
               (pluso q0 '(1) q0+1)
               (negateo q0+1 q)
               (pluso r0 r m))]))])]
    ;; m < 0
    [(fresh (am)
       (negato m)
       (negateo m am)
       (posnato am)
       (conde
         [(fresh (q0)
            (nato n)
            (divo-nat-structo n am q0 r)
            (negateo q0 q))]
         [(fresh (an q0 r0)
            (negato n)
            (negateo n an)
            (nato an)
            (divo-nat-structo an am q0 r0)
            (conde
              [(== r0 '())
               (== r '())
               (== q q0)]
              [(nonzeroo r0)
               (pluso q0 '(1) q)
               (pluso r0 r am)]))]))]))
