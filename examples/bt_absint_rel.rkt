#lang racket

(require minikanren
         minikanren/matche
         (file "../src/bt_rel.rkt"))

(provide (all-defined-out))

;; Core abstract-language grammar (relation input):
;;   idx   ::= '() | (s . idx)
;;   expr  ::= (lit bt) | (var idx) | (add expr expr)
;;           | (sub expr expr) | (mul expr expr)
;;   stmt  ::= (skip) | (assign idx expr) | (seq stmt stmt)
;;           | (if-neg expr stmt stmt) | (while-neg expr stmt)
;;   ival  ::= (bt . bt)   ; [lo, hi], lo <= hi
;;   state ::= (listof ival)
;;
;; Surface syntax parser/lowering lives in examples/bt_absint_surface.rkt.
;; A copy of the grammar is kept there for local readability.
;;
;; Surface syntax:
;;   expr  ::= integer | symbol | (+ expr expr) | (- expr expr)
;;           | (- expr) | (* expr expr)
;;   stmt  ::= skip
;;           | (set! symbol expr)
;;           | (begin stmt ...)
;;           | (if (< expr 0) stmt stmt)
;;           | (if (negative? expr) stmt stmt)
;;           | (while (< expr 0) stmt)
;;           | (while (negative? expr) stmt)
;; Variables are mapped by position from a user-provided list, e.g.
;;   '(x y z) => x:'(), y:'(s), z:'(s s).

;; Host helpers for playground/tests.
;; build-idx : Natural -> Idx
(define (build-idx n)
  (if (zero? n)
      '()
      `(s . ,(build-idx (sub1 n)))))

;; build-fuel : Natural -> Fuel
(define (build-fuel n)
  (build-list n (lambda (_) 'tick)))

;; build-ival : Integer Integer -> IVal
(define (build-ival lo hi)
  (cons (build-num lo) (build-num hi)))

;; build-state : (Dict Integer Integer) -> State
(define (build-state int-intervals)
  (for/list ([(lo hi) (in-dict int-intervals)])
    (build-ival lo hi)))

;; max-abs-from-bound : Bound -> Natural
(define (max-abs-from-bound bound)
  (/ (- (expt 3 (length bound)) 1) 2))

;; top-interval-from-bound : Bound -> IVal
(define (top-interval-from-bound bound)
  (define m (max-abs-from-bound bound))
  (build-ival (- m) m))

;; make-top-state : Natural Bound -> State
(define (make-top-state vars bound)
  (build-list vars (lambda (_) (top-interval-from-bound bound))))

;; Relation helpers.
(defrel (leqo-boundedo x y bound)
  (conde
    [(eq-boundedo x y bound)]
    [(lto-boundedo x y bound)]))

(defmatche (intervalo-boundedo iv bound)
  ([(,lo . ,hi) ,bound]
   (bto-boundedo lo bound)
   (bto-boundedo hi bound)
   (leqo-boundedo lo hi bound)))

(defmatche (iaddo i1 i2 io bound)
  ([(,l1 . ,u1) (,l2 . ,u2) (,lo . ,hi) ,bound]
   (intervalo-boundedo i1 bound)
   (intervalo-boundedo i2 bound)
   (pluso l1 l2 lo)
   (pluso u1 u2 hi)
   (intervalo-boundedo io bound)))

(defmatche (isubo i1 i2 io bound)
  ;; [l1,u1] - [l2,u2] = [l1-u2, u1-l2]
  ([(,l1 . ,u1) (,l2 . ,u2) (,lo . ,hi) ,bound]
   (intervalo-boundedo i1 bound)
   (intervalo-boundedo i2 bound)
   (minuso l1 u2 lo)
   (minuso u1 l2 hi)
   (intervalo-boundedo io bound)))

(defrel (min2o a b m bound)
  (conde
    [(eq-boundedo a b bound)
     (== m a)]
    [(lto-boundedo a b bound)
     (== m a)]
    [(lto-boundedo b a bound)
     (== m b)]))

(defrel (max2o a b m bound)
  (conde
    [(eq-boundedo a b bound)
     (== m a)]
    [(lto-boundedo a b bound)
     (== m b)]
    [(lto-boundedo b a bound)
     (== m a)]))

(defrel (imul4o p1 p2 p3 p4 lo hi bound)
  (fresh (m12 m34 x12 x34)
    (min2o p1 p2 m12 bound)
    (min2o p3 p4 m34 bound)
    (min2o m12 m34 lo bound)
    (max2o p1 p2 x12 bound)
    (max2o p3 p4 x34 bound)
    (max2o x12 x34 hi bound)))

(defmatche (imulo i1 i2 io bound)
  ;; min/max over the four endpoint products.
  ([(,l1 . ,u1) (,l2 . ,u2) (,lo . ,hi) ,bound]
   (fresh (p1 p2 p3 p4)
     (intervalo-boundedo i1 bound)
     (intervalo-boundedo i2 bound)
     (*o l1 l2 p1)
     (*o l1 u2 p2)
     (*o u1 l2 p3)
     (*o u1 u2 p4)
     (bto-boundedo p1 bound)
     (bto-boundedo p2 bound)
     (bto-boundedo p3 bound)
     (bto-boundedo p4 bound)
     (imul4o p1 p2 p3 p4 lo hi bound)
     (intervalo-boundedo io bound))))

(defmatche (ijoino i1 i2 io bound)
  ([(,l1 . ,u1) (,l2 . ,u2) (,lo . ,hi) ,bound]
   (intervalo-boundedo i1 bound)
   (intervalo-boundedo i2 bound)
   (min2o l1 l2 lo bound)
   (max2o u1 u2 hi bound)
   (intervalo-boundedo io bound)))

(defmatche (state-boundedo st bound)
  [(() ,bound)]
  ([(,iv . ,rest) ,bound]
   (intervalo-boundedo iv bound)
   (state-boundedo rest bound)))

(defmatche (state-refo st idx iv)
  ([(,v . ,rest) () ,iv]
   (== v iv))
  ([(,head . ,rest) (s . ,idx-rest) ,iv]
   (state-refo rest idx-rest iv)))

(defmatche (state-seto st idx iv out)
  ([(,old . ,rest) () ,iv (,v . ,rest)]
   (== v iv))
  ([(,head . ,rest) (s . ,idx-rest) ,iv (,head . ,out-rest)]
   (state-seto rest idx-rest iv out-rest)))

(defmatche (state-joino s1 s2 so bound)
  [(() () () ,bound)]
  ([(,i1 . ,r1) (,i2 . ,r2) (,io . ,ro) ,bound]
   (ijoino i1 i2 io bound)
   (state-joino r1 r2 ro bound)))

(defrel (aevalo expr st iv bound)
  (matche (expr)
    ([(lit ,n)]
     (bto-boundedo n bound)
     (== `(,n . ,n) iv))
    ([(var ,idx)]
     (state-refo st idx iv)
     (intervalo-boundedo iv bound))
    ([(add ,e1 ,e2)]
     (fresh (i1 i2)
       (aevalo e1 st i1 bound)
       (aevalo e2 st i2 bound)
       (iaddo i1 i2 iv bound)))
    ([(sub ,e1 ,e2)]
     (fresh (i1 i2)
       (aevalo e1 st i1 bound)
       (aevalo e2 st i2 bound)
       (isubo i1 i2 iv bound)))
    ([(mul ,e1 ,e2)]
     (fresh (i1 i2)
       (aevalo e1 st i1 bound)
       (aevalo e2 st i2 bound)
       (imulo i1 i2 iv bound)))))

(defmatche (definitely-nego iv bound)
  ([(,lo . ,hi) ,bound]
   (lto-boundedo hi '() bound)))

(defmatche (definitely-nonnego iv bound)
  ([(,lo . ,hi) ,bound]
   (conde
     [(eq-boundedo lo '() bound)]
     [(lto-boundedo '() lo bound)])))

(defmatche (maybe-splito iv bound)
  ([(,lo . ,hi) ,bound]
   (lto-boundedo lo '() bound)
   (conde
     [(eq-boundedo hi '() bound)]
     [(lto-boundedo '() hi bound)])))

(defrel (execo stmt st-in st-out bound fuel top-state)
  (matche (stmt)
    ([(skip)]
     (state-boundedo st-in bound)
     (== st-in st-out))
    ([(assign ,idx ,expr)]
     (fresh (iv)
       (state-boundedo st-in bound)
       (aevalo expr st-in iv bound)
       (state-seto st-in idx iv st-out)
       (state-boundedo st-out bound)))
    ([(seq ,s1 ,s2)]
     (fresh (st-mid)
       (execo s1 st-in st-mid bound fuel top-state)
       (execo s2 st-mid st-out bound fuel top-state)))
    ([(if-neg ,expr ,s-then ,s-else)]
     (fresh (test st-then st-else)
       (state-boundedo st-in bound)
       (aevalo expr st-in test bound)
       (conde
         [(definitely-nego test bound)
          (execo s-then st-in st-out bound fuel top-state)]
         [(definitely-nonnego test bound)
          (execo s-else st-in st-out bound fuel top-state)]
         [(maybe-splito test bound)
          (execo s-then st-in st-then bound fuel top-state)
          (execo s-else st-in st-else bound fuel top-state)
          (state-joino st-then st-else st-out bound)])))
    ([(while-neg ,expr ,body)]
     (matche (fuel)
       ([()]
        (state-boundedo top-state bound)
        (== st-out top-state))
       ([(,tick . ,fuel-rest)]
        (fresh (test st-body st-rec)
          (state-boundedo st-in bound)
          (aevalo expr st-in test bound)
          (conde
            [(definitely-nonnego test bound)
             (== st-out st-in)]
            [(definitely-nego test bound)
             (execo body st-in st-body bound fuel-rest top-state)
             (execo stmt st-body st-out bound fuel-rest top-state)]
            [(maybe-splito test bound)
             (execo body st-in st-body bound fuel-rest top-state)
             (execo stmt st-body st-rec bound fuel-rest top-state)
             (state-joino st-in st-rec st-out bound)])))))))
