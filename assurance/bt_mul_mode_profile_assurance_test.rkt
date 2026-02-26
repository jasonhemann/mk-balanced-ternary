#lang racket

(require (except-in rackunit fail)
         minikanren
         racket/engine
         (file "../src/bt_rel.rkt")
         (file "../test/support/bt_harness.rkt"))

(define (make-bound len)
  (build-list len (lambda (i) 'k)))

(define len 3)
(define bound (make-bound len))
(define maxabs (max-abs-for-len len))
(define ints (int-range (- maxabs) maxabs))

(define mode-timeout-ms
  (hash 'ggv 400
        'vgg 400
        'gvg 400
        'vvg 700))

(define (run-with-timeout timeout-ms thunk)
  (define e (engine (lambda (enable-stop) (thunk))))
  (define done? (engine-run timeout-ms e))
  (define out (and done? (engine-result e)))
  (engine-kill e)
  (values done? out))

(define (normalize decoded)
  (sort (remove-duplicates decoded equal?) string<? #:key ~s))

(define (decode-all raw)
  (for/list ([ans raw])
    (define d (decode-bt-tuple ans))
    (when (false? d)
      (fail-check (format "undecodable answer in mode profile: ~s" ans)))
    d))

(define (check-case mode label expected run-thunk)
  (define timeout-ms (hash-ref mode-timeout-ms mode))
  (define-values (done? raw)
    (run-with-timeout timeout-ms run-thunk))
  (unless done?
    (fail-check
     (format "~a timeout (>~ams) for case ~a"
             mode timeout-ms label)))
  (define got* (normalize (decode-all raw)))
  (define exp* (normalize expected))
  (unless (equal? got* exp*)
    (fail-check
     (format "~a mismatch for ~a; expected ~s got ~s"
             mode label exp* got*))))

(test-case "bt assurance: *o mode profile over len<=3 stays within per-query budgets"
  ;; Representative operational profile:
  ;; - ggv: x,y ground; solve z
  ;; - vgg: y,z ground; solve x
  ;; - gvg: x,z ground; solve y
  ;; - vvg: z ground; solve x,y
  (for* ([x ints]
         [y ints])
    (define p (* x y))
    (define expected
      (if (member p ints)
          (list (list p))
          '()))
    (check-case
     'ggv
     (format "~a*~a=?" x y)
     expected
     (lambda ()
       (run* (q)
         (fresh (z)
           (bto-boundedo z bound)
           (*o (int->bt-term x) (int->bt-term y) z)
           (== q z))))))

  (for* ([y ints]
         [z ints])
    (define expected
      (for/list ([x ints] #:when (= (* x y) z))
        (list x)))
    (check-case
     'vgg
     (format "?*~a=~a" y z)
     expected
     (lambda ()
       (run* (q)
         (fresh (x)
           (bto-boundedo x bound)
           (*o x (int->bt-term y) (int->bt-term z))
           (== q x))))))

  (for* ([x ints]
         [z ints])
    (define expected
      (for/list ([y ints] #:when (= (* x y) z))
        (list y)))
    (check-case
     'gvg
     (format "~a*?=~a" x z)
     expected
     (lambda ()
       (run* (q)
         (fresh (y)
           (bto-boundedo y bound)
           (*o (int->bt-term x) y (int->bt-term z))
           (== q y))))))

  (for ([z ints])
    (define expected
      (for*/list ([x ints]
                  [y ints]
                  #:when (= (* x y) z))
        (list x y)))
    (check-case
     'vvg
     (format "?*?=~a" z)
     expected
     (lambda ()
       (run* (q)
         (fresh (x y)
           (bto-boundedo x bound)
           (bto-boundedo y bound)
           (*o x y (int->bt-term z))
           (== q (list x y))))))))
