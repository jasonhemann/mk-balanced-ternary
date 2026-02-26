#lang racket

(require rackunit
         minikanren
         (except-in racket/list cartesian-product)
         (file "../src/bt_rel.rkt")
         (file "support/bt_harness.rkt"))

(define (make-bound len)
  (build-list len (lambda (i) 'k)))

(define bound2 (make-bound 2))
(define ints2 (int-range -4 4))

;; ------------------------------------------------------------
;; Local ablations used to demonstrate why boundary trit checks
;; are needed for bounded/decoding-based validation.
;; ------------------------------------------------------------

(defrel (bad-canco bt)
  (conde
    [(== bt '())]
    [(fresh (d rest)
       (== bt (cons d rest))
       (conde
         [(== rest '()) (=/= d '0)]
         [(nonzeroo rest)
          (bad-canco rest)]))]))

(defrel (bad-len<=o bt bound)
  (conde
    [(== bt '())]
    [(fresh (d rest brest marker)
       (== bt `(,d . ,rest))
       (== bound `(,marker . ,brest))
       (bad-len<=o rest brest))]))

(defrel (bad-bto-boundedo bt bound)
  (bad-len<=o bt bound)
  (bad-canco bt))

(defrel (bad-digit-stepo n d rest)
  (conde
    [(== n '()) (== d '0) (== rest '())]
    [(== n `(,d . ,rest))]))

(defrel (bad-eq-boundedo x y bound)
  (conde
    [(== bound '())]
    [(fresh (h t dxy xr yr)
       (== bound `(,h . ,t))
       (bad-digit-stepo x dxy xr)
       (bad-digit-stepo y dxy yr)
       (bad-eq-boundedo xr yr t))]))

;; ------------------------------------------------------------
;; Ablation checks
;; ------------------------------------------------------------

(test-case "bt boundary ablation: removing trito from canco/len<=o yields undecodable numerals"
  (define bad-raw
    (run 20 (q)
      (bad-bto-boundedo q bound2)))
  (define bad-decoded
    (map bt->int-term bad-raw))
  (check-true
   (ormap false? bad-decoded)
   "expected at least one undecodable numeral without boundary trito checks")

  (define good-raw
    (run* (q)
      (bto-boundedo q bound2)))
  (define good-decoded
    (map bt->int-term good-raw))
  (check-true
   (andmap (lambda (x) (not (false? x))) good-decoded)
   "all bounded numerals should decode under the non-ablated boundary relations")
  (check-equal?
   (sort (remove-duplicates good-decoded equal?) <)
   ints2))

(test-case "bt boundary ablation: removing trito from digit-stepo yields undecodable equality pairs"
  (define bad-raw
    (run 40 (q)
      (fresh (x y)
        (bad-bto-boundedo x bound2)
        (bad-bto-boundedo y bound2)
        (bad-eq-boundedo x y bound2)
        (== q (list x y)))))
  (define bad-decoded
    (map decode-bt-tuple bad-raw))
  (check-true
   (ormap false? bad-decoded)
   "expected at least one undecodable pair without boundary trito checks")

  (define good-raw
    (run 40 (q)
      (fresh (x y)
        (bto-boundedo x bound2)
        (bto-boundedo y bound2)
        (eq-boundedo x y bound2)
        (== q (list x y)))))
  (define good-decoded
    (map decode-bt-tuple good-raw))
  (check-true
   (andmap (lambda (x) (not (false? x))) good-decoded)
   "all bounded equality pairs should decode under non-ablated boundary relations"))

;; ------------------------------------------------------------
;; Boundary relation mode matrix checks
;; ------------------------------------------------------------

(test-case "bt boundary modes: canco enumerates exactly bounded canonical numerals"
  (define observed
    (run* (q)
      (len<=o q bound2)
      (canco q)))
  (define decoded
    (map bt->int-term observed))
  (check-true (andmap (lambda (x) (not (false? x))) decoded))
  (check-equal?
   (sort (remove-duplicates decoded equal?) <)
   ints2))

(test-case "bt boundary modes: canco accepts canonical terms and rejects trailing-zero forms"
  (for ([n ints2])
    (check-equal?
     (run* (q)
       (canco (int->bt-term n))
       (== q 'ok))
     '(ok)))
  (for ([bad (list '(0) '(1 0) '(T 0) '(0 0 1 0))])
    (check-equal?
     (run* (q)
       (canco bad)
       (== q 'ok))
     '())))

(test-case "bt boundary modes: canco-shapeo keeps open-head generality but still rejects trailing zero"
  (check-equal?
   (run 1 (q)
     (canco-shapeo `(,q 1)))
   '(_.0))
  (check-equal?
   (run* (q)
     (canco-shapeo `(,q 0)))
   '()))

(test-case "bt boundary modes: digit-stepo forward and inverse ground patterns"
  (check-equal?
   (run* (q)
     (fresh (d r)
       (digit-stepo '() d r)
       (== q (list d r))))
   '((0 ())))
  (check-equal?
   (run* (q)
     (fresh (d r)
       (digit-stepo '(1 T) d r)
       (== q (list d r))))
   '((1 (T))))
  (check-equal?
   (run* (q)
     (digit-stepo q 'T '(1)))
   '((T 1)))
  (check-equal?
   (run 4 (q)
     (digit-stepo q '0 '()))
   '(() (0))))
