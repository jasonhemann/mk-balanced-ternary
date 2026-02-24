#lang racket

(require (except-in rackunit fail)
         minikanren
         racket/list
         racket/random)

(require (file "../src/bt_oracle.rkt")
         (file "../src/bt_rel.rkt"))

;; ----------------------------
;; Helpers for tests
;; ----------------------------

;; Convert oracle int->bt digits to the SYMBOL trits expected by relations.
;; This is redundant if your oracle already returns 'T/'0/'1.
(define (canonical-bt i)
  (int->bt i))

(define (bt=? a b)
  (equal? a b))

;; Run a goal and get the first solution (or #f)
(define (run1 thunk)
  (define sols (thunk))
  (if (null? sols) #f (car sols)))

;; Bounded canonical predicate for tests only.
;; Ensures:
;; - list length <= maxlen
;; - every digit is a trit (via trito from bt_rel.rkt)
;; - canonical: either '() or last digit != '0
;;
;; IMPORTANT: This uses host recursion on maxlen. That’s fine: it’s test harness,
;; not part of the arithmetic suite.
(define (bto-boundo q maxlen)
  ;; Generate all canonical bts up to maxlen using host recursion (test-only).
  (define trits '(T 0 1))
  (define (gen-len len)
    (cond
      [(= len 1) (list '(T) '(1))]
      [else
       (apply append
              (for/list ([d trits])
                (map (λ (rest) (cons d rest))
                     (gen-len (sub1 len)))))]))
  (define all-bts
    (append
      (list '())
      (apply append
             (for/list ([len (in-range 1 (add1 maxlen))])
               (gen-len len)))))
  ;; Deterministic finite disjunction over all generated candidates.
  (define (disj lst)
    (cond
      [(null? lst) (== #f #t)]
      [else
       (conde
         [(== q (car lst))]
         [(disj (cdr lst))])]))
  (disj all-bts))

;; Convenience: evaluate pluso in ground/ground mode
(define (plus-ground a b)
  (run1 (λ () (run 1 (q) (pluso a b q)))))

(define (mul-ground a b)
  (run1 (λ () (run 1 (q) (*o a b q)))))

;; Random int in [lo, hi]
(define (rand-int lo hi)
  (+ lo (random (+ 1 (- hi lo)))))

;; ----------------------------
;; Unit tests for oracle roundtrip
;; ----------------------------

(test-case "oracle roundtrip int->bt->int over [-200,200]"
  (for ([i (in-range -200 201)])
    (check-equal? (bt->int (canonical-bt i)) i)))

(test-case "oracle canonical: no trailing '0 except empty"
  (for ([i (in-range -200 201)])
    (define bt (canonical-bt i))
    (cond
      [(null? bt) (void)]
      [else (check-not-equal? (last bt) '0)])))

;; ----------------------------
;; add3o truth table test (if add3o is exported)
;; ----------------------------

(define trits '(T 0 1))

(define (trit->int t)
  (match t ['T -1] ['0 0] ['1 1]))

(define (int->sum/carry s)
  ;; returns values (s-trit, cout-trit) for total in [-3..3]
  ;; s in {-1,0,1}, cout in {-1,0,1}, total = s + 3*cout
  (cond
    [(= s -3) (values '0 'T)]
    [(= s -2) (values '1 'T)]
    [(= s -1) (values 'T '0)]
    [(= s  0) (values '0 '0)]
    [(= s  1) (values '1 '0)]
    [(= s  2) (values 'T '1)]
    [(= s  3) (values '0 '1)]
    [else (error "impossible total" s)]))

(test-case "add3o implements balanced ternary full adder (27 combos)"
  (for* ([a trits] [b trits] [cin trits])
    (define total (+ (trit->int a) (trit->int b) (trit->int cin)))
    (define-values (s* cout*) (int->sum/carry total))
    (define got
      (run1 (λ () (run 1 (q)
                       (fresh (s cout)
                         (add3o a b cin s cout)
                         (== q (list s cout)))))))
    (check-not-false got)
    (check-equal? got (list s* cout*))))

;; ----------------------------
;; pluso property tests
;; ----------------------------

(test-case "pluso ground/ground randomized vs oracle"
  (for ([k (in-range 180)])
    (define a (rand-int -200 200))
    (define b (rand-int -200 200))
    (define ra (canonical-bt a))
    (define rb (canonical-bt b))
    (define rz (plus-ground ra rb))
    (check-not-false rz)
    (check-equal? (bt->int rz) (+ a b))))

(test-case "nego behaves as additive inverse (randomized)"
  (for ([k (in-range 90)])
    (define a (rand-int -200 200))
    (define ra (canonical-bt a))
    (define nx
      (run1 (λ () (run 1 (q) (nego ra q)))))
    (check-not-false nx)
    (define sum (plus-ground ra nx))
    (check-not-false sum)
    (check-equal? sum '())))

(test-case "pluso ground/var with explicit bound returns only correct solutions"
  ;; For random a,z, solve for y in a+y=z, bounded.
  (for ([k (in-range 40)])
    (define a (rand-int -50 50))
    (define z (rand-int -50 50))
    (define ra (canonical-bt a))
    (define rz (canonical-bt z))
    (define expected (canonical-bt (- z a)))
    (define sols
      (run 5 (q)                ; cap number of answers
        (bto-boundo q 8)        ; cap digit-length
        (pluso ra q rz)))
    ;; every returned solution must be correct
    (for ([q sols])
      (check-equal? (bt->int q) (- z a)))
    ;; expected should appear (within the bound) unless bound too small
    (check-not-false (member expected sols bt=?))))

;; ----------------------------
;; *o property tests
;; ----------------------------

(test-case "*o ground/ground randomized vs oracle"
  (for ([k (in-range 120)])
    (define a (rand-int -80 80))
    (define b (rand-int -80 80))
    (define ra (canonical-bt a))
    (define rb (canonical-bt b))
    (define rz (mul-ground ra rb))
    (check-not-false rz)
    (check-equal? (bt->int rz) (* a b))))

(test-case "*o ground/var bounded: returned solutions satisfy equation"
  ;; Solve a*q = z for q, bounded. We don’t demand completeness.
  (for ([k (in-range 15)])
    (define a (rand-int -20 20))
    (define z (rand-int -60 60))
    (when (not (= a 0))
      (define ra (canonical-bt a))
      (define rz (canonical-bt z))
      (define sols
        (run 10 (q)
          (bto-boundo q 4)
          (*o ra q rz)))
      (for ([q sols])
        (check-equal? (* a (bt->int q)) z)))))
