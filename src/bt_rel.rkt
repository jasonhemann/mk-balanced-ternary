#lang racket
(require minikanren)
(provide (all-defined-out))

;; Host helper for REPL/tests, analogous to binary `build-num`.
;; Produces canonical LSD-first balanced-ternary numerals.
(define (build-num k)
  (cond
	[(zero? k) '()]
	[else
	  (case (modulo k 3)
		[(0) (cons '0 (build-num (/ k 3)))]
		[(1) (cons '1 (build-num (/ (- k 1) 3)))]
		[(2) (cons 'T (build-num (/ (+ k 1) 3)))])]))

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
    [(== '(T) y)
     (not-oneo x)
     (canco-shapeo x)
     (nego x z)]
    [(fresh (b0 yrest xb0 xyrest shifted)
       (nonzeroo x)
       (nonzeroo z)
       (not-oneo x)
       (== `(,b0 . ,yrest) y)
       (nonzeroo yrest)
       (len<=o x z)
       (len<=o y z)
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
       (== bt `(,d . ,rest))
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

;; Internal Euclidean-division bound relation from dividend/divisor shape:
;; length(bound) = 1 + len(n) + len(m).
(defrel (nmo-boundo n m bound)
  (fresh (nm)
    (== `(k . ,nm) bound)
    (len-appendo n m nm)))

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
    [(== a n)
     (nneg-boundedo n bound)]
    [(lto-boundedo n '() bound)
     (negateo n a)
     (nneg-boundedo a bound)]))

;; Relate a trit digit with its canonical one-digit numeral.
(defrel (digit-numo d n)
  (conde
    [(== d 'T) (== n '(T))]
    [(== d '0) (== n '())]
    [(== d '1) (== n '(1))]))

;; t = 3*r + d, where d is one trit.
(defrel (times3-plus-digito r d t)
  (conde
    [(== r '())
     (digit-numo d t)]
    [(== t `(,d . ,r))
     (nonzeroo r)
     (trito d)]))

;; Local quotient/remainder correction for one LSD-first step:
;; n = d + 3*n', with n' = m*q' + r' and t = d + 3*r'.
;; Choose k in {-1,0,1,2} so q = 3*q' + k and r = t - k*m.
(defrel (div-correcto t m qrest q r bound)
  (fresh (qshift)
    (shift3o qrest qshift)
    (conde
      ;; Clause 1 (k=-1): if t<0, pull one m from remainder into quotient.
      ;; q = 3*qrest - 1, r = t + m.
      [(lto-boundedo t '() bound)
       (pluso q '(1) qshift)
       (pluso t m r)]
      ;; Clause 2 (k=0): if 0<=t<m, quotient trit is 0.
      ;; q = 3*qrest, r = t.
      [(== r t)
       (== q qshift)
       (nneg-boundedo t bound)
       (lto-boundedo t m bound)]
      ;; Clause 3 (k=1): if m<=t<2m, quotient trit is +1.
      ;; q = 3*qrest + 1, r = t - m.
      [(fresh (u)
         (== r u)
         (nneg-boundedo u bound)
         (lto-boundedo u m bound)
         (pluso m u t)
         (pluso qshift '(1) q))]
      ;; Clause 4 (k=2): if 2m<=t<3m, quotient trit is +2 (BT term '(T 1)).
      ;; q = 3*qrest + 2, r = t - 2m.
      [(fresh (u mm)
         (== r u)
         (nneg-boundedo u bound)
         (lto-boundedo u m bound)
         (pluso m m mm)
         (pluso mm u t)
         (pluso qshift '(T 1) q))])))

;; Nonnegative Euclidean division core for positive divisor.
;; Recurrence follows n = d + 3*n' and fixes one quotient trit per step.
(defrel (divo-nat-boundedo n m q r bound)
  (nneg-boundedo n bound)
  (poso-boundedo m bound)
  (conde
    ;; Clause 1 (n<m): base long-division case q=0, r=n.
    ;; productive-modes: ggvv, gggv, ggvg
    ;; risk: open n/m can defer the strict-order split.
    [(== r n)
	 (== q '())
	 (fresh (mt md)
       (== m `(,mt . ,md))
       (nonzeroo md)
       (lto-boundedo n m bound))]
    ;; Clause 2 (m=1): exact unit-division case q=n, r=0.
    ;; productive-modes: ggvv, gggv
    ;; risk: open m can interleave with other clauses.
    [(== m '(1))
     (== q n)
     (== r '())]
    ;; Clause 3 (step): peel one dividend trit and recurse on nrest.
    ;; productive-modes: ggvv, gggv (bounded inverse templates)
    ;; risk: open t can fan correction branches in div-correcto.
    [(fresh (mt md d nrest)
       (== n `(,d . ,nrest))
	   (== m `(,mt . ,md))
	   (trito d)
       (nonzeroo md)
       (conde
         [(eq-boundedo n m bound)]
         [(lto-boundedo m n bound)])
       (fresh (qrest rrest t)
         (divo-nat-boundedo nrest m qrest rrest bound)
         (times3-plus-digito rrest d t)
         (div-correcto t m qrest q r bound)))])
  (nneg-boundedo q bound)
  (nneg-boundedo r bound)
  (lto-boundedo r m bound))

;; Euclidean division over bounded BT integers:
;; n = m*q + r, m != 0, and 0 <= r < |m|.
(defrel (divo-boundedo n m q r bound)
  (bto-boundedo n bound)
  (nonzeroo m)
  (bto-boundedo m bound)
  (conde
    ;; Clause 1 (m>0): run nat core directly or via |n| translation.
    ;; productive-modes: gggg, ggvv, bounded vggv
    ;; risk: open n sign split may interleave both branches.
    [(poso-boundedo m bound)
     (conde
       ;; Clause 1a (n>=0): direct nonnegative core.
       ;; productive-modes: gggg, ggvv
       ;; risk: open q/r may still explore deep bounded search.
       [(nneg-boundedo n bound)
        (nneg-boundedo q bound)
        (divo-nat-boundedo n m q r bound)]
       ;; Clause 1b (n<0): divide |n|, then map back to Euclidean pair.
       ;; productive-modes: gggg, ggvv
       ;; risk: inexact branch adds one quotient-shift/construction choice.
       [(fresh (an q0 r0)
          (lto-boundedo n '() bound)
          (negateo n an)
          (nneg-boundedo an bound)
          (conde
            ;; Clause 1b.i: exact division stays exact under sign flip.
            ;; Prune early when caller already constrains r = 0.
            [(== r '())
             (divo-nat-boundedo an m q0 '() bound)
             (negateo q0 q)]
            ;; Clause 1b.ii: otherwise shift quotient by -1 and complement remainder.
            ;; Prune exact branch early when caller constrains r /= 0.
            [(nonzeroo r)
             (divo-nat-boundedo an m q0 r0 bound)
             (nonzeroo r0)
             (fresh (q0+1)
               (pluso q0 '(1) q0+1)
               (negateo q0+1 q)
               (pluso r0 r m))]))])]
    ;; Clause 2 (m<0): divide by |m| and adjust quotient sign.
    ;; productive-modes: gggg, ggvv, bounded vggv
    ;; risk: open m sign split introduces additional translation work.
    [(fresh (am)
       (lto-boundedo m '() bound)
       (negateo m am)
       (poso-boundedo am bound)
       (conde
         ;; Clause 2a (n>=0): q sign flips, remainder unchanged.
         [(fresh (q0)
            (nneg-boundedo n bound)
            (divo-nat-boundedo n am q0 r bound)
            (negateo q0 q))]
         ;; Clause 2b (n<0): both signs negative; adjust as in m>0 case.
         [(fresh (an q0 r0)
            (lto-boundedo n '() bound)
            (negateo n an)
            (nneg-boundedo an bound)
            (conde
              ;; Clause 2b.i: exact division.
              ;; Prune early when caller already constrains r = 0.
              [(== r '())
               (divo-nat-boundedo an am q '() bound)]
              ;; Clause 2b.ii: inexact division, bump q by +1 and complement r.
              ;; Prune exact branch early when caller constrains r /= 0.
              [(nonzeroo r)
               (divo-nat-boundedo an am q0 r0 bound)
               (nonzeroo r0)
               (pluso q0 '(1) q)
               (pluso r0 r am)]))]))]))

(defrel (divo n m q r)
  (fresh (qbound)
    ;; Public wrapper (uniform policy, no q/r case split):
    ;; 1) derive structural bound from n,m shape,
    ;; 2) run bounded Euclidean core under that envelope,
    ;; 3) enforce quotient length.
    ;; productive-modes: gggg, ggvv, bounded inverse templates
    ;; risk: fully open alias classes remain intentionally unbounded.
    (nmo-boundo n m qbound)
    (divo-boundedo n m q r qbound)
    (len<=o q qbound)))
