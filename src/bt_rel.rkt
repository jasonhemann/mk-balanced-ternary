#lang racket
(require minikanren)
(provide (all-defined-out))

(defrel (trito t)
  (conde
    [(== t 'T)]
    [(== t '0)]
    [(== t '1)]))

(defrel (add3o a b cin s cout)
  (conde
    [(== a 'T) (== b 'T) (== cin 'T) (== s '0) (== cout 'T)]
    [(== a 'T) (== b 'T) (== cin '0) (== s '1) (== cout 'T)]
    [(== a 'T) (== b 'T) (== cin '1) (== s 'T) (== cout '0)]

    [(== a 'T) (== b '0) (== cin 'T) (== s '1) (== cout 'T)]
    [(== a 'T) (== b '0) (== cin '0) (== s 'T) (== cout '0)]
    [(== a 'T) (== b '0) (== cin '1) (== s '0) (== cout '0)]

    [(== a 'T) (== b '1) (== cin 'T) (== s 'T) (== cout '0)]
    [(== a 'T) (== b '1) (== cin '0) (== s '0) (== cout '0)]
    [(== a 'T) (== b '1) (== cin '1) (== s '1) (== cout '0)]

    [(== a '0) (== b 'T) (== cin 'T) (== s '1) (== cout 'T)]
    [(== a '0) (== b 'T) (== cin '0) (== s 'T) (== cout '0)]
    [(== a '0) (== b 'T) (== cin '1) (== s '0) (== cout '0)]

    [(== a '0) (== b '0) (== cin 'T) (== s 'T) (== cout '0)]
    [(== a '0) (== b '0) (== cin '0) (== s '0) (== cout '0)]
    [(== a '0) (== b '0) (== cin '1) (== s '1) (== cout '0)]

    [(== a '0) (== b '1) (== cin 'T) (== s '0) (== cout '0)]
    [(== a '0) (== b '1) (== cin '0) (== s '1) (== cout '0)]
    [(== a '0) (== b '1) (== cin '1) (== s 'T) (== cout '1)]

    [(== a '1) (== b 'T) (== cin 'T) (== s 'T) (== cout '0)]
    [(== a '1) (== b 'T) (== cin '0) (== s '0) (== cout '0)]
    [(== a '1) (== b 'T) (== cin '1) (== s '1) (== cout '0)]

    [(== a '1) (== b '0) (== cin 'T) (== s '0) (== cout '0)]
    [(== a '1) (== b '0) (== cin '0) (== s '1) (== cout '0)]
    [(== a '1) (== b '0) (== cin '1) (== s 'T) (== cout '1)]

    [(== a '1) (== b '1) (== cin 'T) (== s '1) (== cout '0)]
    [(== a '1) (== b '1) (== cin '0) (== s 'T) (== cout '1)]
    [(== a '1) (== b '1) (== cin '1) (== s '0) (== cout '1)]))

(defrel (full-addero cin a b s cout)
  (add3o a b cin s cout))

(defrel (negtrito t nt)
  (conde
    [(== t 'T) (== nt '1)]
    [(== t '0) (== nt '0)]
    [(== t '1) (== nt 'T)]))

(defrel (nego x y)
  (conde
    [(== '() x) (== '() y)]
    [(fresh (a d na nd)
       (== `(,a . ,d) x)
       (== `(,na . ,nd) y)
       (negtrito a na)
       (nego d nd))]))

(defrel (negateo x y)
  (nego x y))

(defrel (add-carryo x y cin z)
  (conde
    [(== '() x) (== '() y)
     (conde
       [(== cin '0) (== '() z)]
       [(== cin '1) (== '(1) z)]
       [(== cin 'T) (== '(T) z)])]
    [(== '() x)
     (fresh (b yrest s cout zrest)
       (== `(,b . ,yrest) y)
       (sum-trim0o s zrest z)
       (add3o '0 b cin s cout)
       (add-carryo '() yrest cout zrest))]
    [(== '() y)
     (fresh (a xrest s cout zrest)
       (== `(,a . ,xrest) x)
       (sum-trim0o s zrest z)
       (add3o a '0 cin s cout)
       (add-carryo xrest '() cout zrest))]
    [(fresh (a xrest b yrest s cout zrest)
       (== `(,a . ,xrest) x)
       (== `(,b . ,yrest) y)
       (sum-trim0o s zrest z)
       (add3o a b cin s cout)
       (add-carryo xrest yrest cout zrest))]))

;; Construct z from s and zrest, trimming a trailing zero at the most-significant end.
(defrel (sum-trim0o s zrest z)
  (conde
    [(== zrest '()) (== s '0) (== z '())]
    [(== z `(,s . ,zrest))
     (conde
       [(=/= s '0)]
       [(== s '0)
        (fresh (a d) (== zrest `(,a . ,d)))])]))

(defrel (pluso x y z)
  (add-carryo x y '0 z))

(defrel (minuso x y z)
  (fresh (ny)
    (nego y ny)
    (pluso x ny z)))

(defrel (mul1o x b out)
  (conde
    [(== b '0) (== out '())]
    [(== b '1) (== out x)]
    [(== b 'T) (nego x out)]))

(defrel (*o x y z)
  (conde
    [(== '() x) (== '() z)]
    [(== '() y) (== '() z)]
    [(fresh (b0 yrest xb0 xyrest)
       (== `(,b0 . ,yrest) y)
       (mul1o x b0 xb0)
       (*o x yrest xyrest)
       (pluso xb0 `(0 . ,xyrest) z)
       (canco z))]))

;; Canonical: empty or last digit nonzero.
(defrel (canco bt)
  (conde
    [(== bt '())]
    [(fresh (d rest)
       (== bt (cons d rest))
       (trito d)
       (conde
         [(== rest '()) (=/= d '0)]
         [(fresh (a b)
            (== rest `(,a . ,b))
            (canco rest))]))]))

;; Length-bounded canonical BT numeral. The bound is represented as a
;; ground list, and the numeral length must be <= the bound length.
(defrel (len<=o bt bound)
  (conde
    [(== bt '())]
    [(fresh (d rest brest marker)
       (== bt `(,d . ,rest))
       (trito d)
       (== bound `(,marker . ,brest))
       (len<=o rest brest))]))

(defrel (bto-boundedo bt bound)
  (len<=o bt bound)
  (canco bt))

(defrel (zeroo n)
  (== n '()))

;; Return the current digit and remaining tail, treating exhausted numerals as 0.
(defrel (digit-stepo n d rest)
  (conde
    [(== n '()) (== d '0) (== rest '())]
    [(fresh (a r)
       (== n `(,a . ,r))
       (trito a)
       (== d a)
       (== rest r))]))

(defrel (digit<o a b)
  (conde
    [(== a 'T) (== b '0)]
    [(== a 'T) (== b '1)]
    [(== a '0) (== b '1)]))

(defrel (eq-boundedo x y bound)
  (conde
    [(== bound '())]
    [(fresh (h t dx dy xr yr)
       (== bound `(,h . ,t))
       (digit-stepo x dx xr)
       (digit-stepo y dy yr)
       (== dx dy)
       (eq-boundedo xr yr t))]))

;; Strict total order over BT numerals constrained by a shared digit-length bound.
(defrel (lto-boundedo x y bound)
  (fresh (h t dx dy xr yr)
    (== bound `(,h . ,t))
    (digit-stepo x dx xr)
    (digit-stepo y dy yr)
    (conde
      [(lto-boundedo xr yr t)]
      [(eq-boundedo xr yr t)
       (digit<o dx dy)])))

(defrel (poso-boundedo n bound)
  (bto-boundedo n bound)
  (lto-boundedo '() n bound))

(defrel (nneg-boundedo n bound)
  (bto-boundedo n bound)
  (conde
    [(== n '())]
    [(poso-boundedo n bound)]))

(defrel (abso-boundedo n a bound)
  (conde
    [(nneg-boundedo n bound)
     (== a n)]
    [(lto-boundedo n '() bound)
     (negateo n a)
     (nneg-boundedo a bound)]))

;; Euclidean division over bounded BT integers:
;; n = m*q + r, m != 0, and 0 <= r < |m|.
(defrel (divo n m q r bound)
  (bto-boundedo n bound)
  (bto-boundedo m bound)
  (bto-boundedo q bound)
  (bto-boundedo r bound)
  (=/= m '())
  (fresh (prod am)
    (*o m q prod)
    (pluso prod r n)
    (abso-boundedo m am bound)
    (nneg-boundedo r bound)
    (lto-boundedo r am bound)))

;; Backward-compatible alias while tests/docs migrate to `divo`.
(defrel (divo-boundedo n m q r bound)
  (divo n m q r bound))
