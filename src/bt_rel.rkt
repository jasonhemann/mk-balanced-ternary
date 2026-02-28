#lang racket
(require minikanren)
(provide (all-defined-out))

;; Host helper for REPL/tests, analogous to binary `build-num`.
;; Produces canonical LSD-first balanced-ternary numerals.
(define (build-num n)
  (unless (exact-integer? n)
    (error 'build-num "expected exact integer, got: ~a" n))
  (let loop ([k n])
    (cond
      [(zero? k) '()]
      [else
       (define r (modulo k 3))
       (define d (case r
                   [(0) '0]
                   [(1) '1]
                   [(2) 'T]))
       (define next (case r
                      [(0) (/ k 3)]
                      [(1) (/ (- k 1) 3)]
                      [(2) (/ (+ k 1) 3)]))
       (cons d (loop next))])))

(defrel (trito t)
  (conde
    [(== t 'T)]
    [(== t '0)]
    [(== t '1)]))

(defrel (nonzero-trito t)
  (conde
    [(== t 'T)]
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
    ;; Identity when one addend is exhausted and carry is zero.
    [(== cin '0) (== '() x)
     (== y z)
     (nonzeroo y)]
    [(== cin '0) (== '() y)
     (== x z)]
    ;; Carry propagation when one addend is exhausted.
    [(== cin '1) (== '() x)
     (nonzeroo y)
     (add-carryo '(1) y '0 z)]
    [(== cin '1) (== '() y)
     (add-carryo x '(1) '0 z)]
    [(== cin 'T) (== '() x)
     (nonzeroo y)
     (add-carryo '(T) y '0 z)]
    [(== cin 'T) (== '() y)
     (add-carryo x '(T) '0 z)]
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
       [(nonzero-trito s)]
       [(== s '0) (nonzeroo zrest)])]))

(defrel (pluso-raw x y z)
  (add-carryo x y '0 z))

(defrel (pluso x y z)
  ;; Preserve mK-style open identity answers while still constraining
  ;; non-trivial arithmetic to canonical shapes.
  (conde
    [(== '() x)
     (nonzeroo y)
     (== y z)]
    [(== '() y)
     (== x z)]
    [(fresh (xa xd ya yd)
       (== `(,xa . ,xd) x)
       (== `(,ya . ,yd) y)
       (pluso-raw x y z)
       (canco-shapeo x)
       (canco-shapeo y)
       (canco-shapeo z))]))

(defrel (minuso x y z)
  (pluso y z x))

(defrel (mul1o x b out)
  (conde
    [(== b '0) (== out '())]
    [(== b '1) (== out x)]
    [(== b 'T) (nego x out)]))

(defrel (factor1o a b)
  (conde
    [(== a '(1)) (== b '(1))]
    [(== a '(T)) (== b '(T))]))

(defrel (nonzeroo n)
  (fresh (a d)
    (== `(,a . ,d) n)))

(defrel (not-oneo n)
  (conde
    [(== '(T) n)]
    [(fresh (a d)
       (== `(,a . ,d) n)
       (nonzeroo d))]))

(defrel (*o x y z)
  (conde
    [(== '() x) (== '() z)]
    [(nonzeroo x) (== '() z) (== '() y)]
    [(== '(1) x) (nonzeroo y) (== y z)]
    [(== '(1) y) (not-oneo x) (== x z)]
    [(fresh (b0 yrest xb0 xyrest shifted)
       (nonzeroo x)
       (nonzeroo z)
       (not-oneo x)
       (not-oneo y)
       (len<=o x z)
       (len<=o y z)
       (== `(,b0 . ,yrest) y)
       (mul1o x b0 xb0)
       (*o x yrest xyrest)
       (shift3o xyrest shifted)
       (pluso xb0 shifted z))]))

;; Multiply by 3 (one trit shift) while keeping canonical zero.
(defrel (shift3o n out)
  (conde
    [(== n '()) (== out '())]
    [(nonzeroo n) (== out `(0 . ,n))]))

;; Canonical: empty or last digit nonzero.
(defrel (canco bt)
  (conde
    [(== bt '())]
    [(fresh (d rest)
       (== bt (cons d rest))
       (trito d)
       (conde
         [(== rest '()) (nonzero-trito d)]
         [(nonzeroo rest)
          (canco rest)]))]))

;; Canonical shape only: used on arithmetic surfaces to avoid forcing trit
;; grounding in open modes.
(defrel (canco-shapeo bt)
  (conde
    [(== bt '())]
    [(fresh (d rest)
       (== bt (cons d rest))
       (conde
         [(== rest '()) (nonzero-trito d)]
         [(nonzeroo rest)
          (canco-shapeo rest)]))]))

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

;; Copy only list shape (length), discarding payload values.
(defrel (len-copyo in out)
  (conde
    [(== in '()) (== out '())]
    [(fresh (a d marker outrest)
       (== `(,a . ,d) in)
       (== `(,marker . ,outrest) out)
       (len-copyo d outrest))]))

;; Build an output list whose length is len(x)+len(y).
(defrel (len-appendo x y out)
  (conde
    [(== x '()) (len-copyo y out)]
    [(fresh (a d marker outrest)
       (== `(,a . ,d) x)
       (== `(,marker . ,outrest) out)
       (len-appendo d y outrest))]))

;; Internal Euclidean-division bound derived from dividend/divisor shape:
;; length(bound) = 1 + len(n) + len(m).
(defrel (bound-from-nmo n m bound)
  (fresh (nm)
    (len-appendo n m nm)
    (== `(k . ,nm) bound)))

(defrel (zeroo n)
  (== n '()))

;; Return the current digit and remaining tail, treating exhausted numerals as 0.
(defrel (digit-stepo n d rest)
  (conde
    [(== n '()) (== d '0) (== rest '())]
    [(== n `(,d . ,rest))
     (trito d)]))

(defrel (digit<o a b)
  (conde
    [(== a 'T) (== b '0)]
    [(== a 'T) (== b '1)]
    [(== a '0) (== b '1)]))

(defrel (eq-boundedo x y bound)
  (conde
    [(== bound '())]
    [(fresh (h t dxy xr yr)
       (== bound `(,h . ,t))
       (digit-stepo x dxy xr)
       (digit-stepo y dxy yr)
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
(defrel (divo-boundedo n m q r bound)
  (bto-boundedo n bound)
  (bto-boundedo m bound)
  (bto-boundedo q bound)
  (bto-boundedo r bound)
  (nonzeroo m)
  (conde
    ;; Euclidean remainder is always 0 for |m|=1.
    [(== m '(1))
     (== r '())
     (== n q)]
    [(== m '(T))
     (== r '())
     (negateo q n)]
    [(fresh (mt mrest)
       (== m `(,mt . ,mrest))
       (nonzeroo mrest)
     (fresh (prod am)
       (*o m q prod)
       (pluso prod r n)
       (abso-boundedo m am bound)
       (nneg-boundedo r bound)
       (lto-boundedo r am bound)))]))

(defrel (divo n m q r)
  (conde
    ;; Quotient-zero path: n = r and 0 <= r < |m| with m != 0.
    [(== q '())
     (== n r)
     (nonzeroo m)
     (fresh (bound am)
       (len-copyo m bound)
       (bto-boundedo m bound)
       (bto-boundedo r bound)
       (nneg-boundedo r bound)
       (abso-boundedo m am bound)
       (lto-boundedo r am bound))]
    ;; Generic Euclidean flow for nonzero quotients.
    [(nonzeroo q)
     (fresh (bound)
       (bound-from-nmo n m bound)
       (divo-boundedo n m q r bound))]))
