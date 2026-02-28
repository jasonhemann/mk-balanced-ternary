#lang racket

(require rackunit
         minikanren
         racket/engine
         (file "../../src/bt_rel.rkt")
         (file "../../examples/bt_absint_rel.rkt"))

(define (mk-bound len)
  (build-list len (lambda (_) 'k)))

(define B (mk-bound 3))

(define IDX0 (build-idx 0))
(define IDX1 (build-idx 1))

(define (run-with-timeout timeout-ms thunk)
  (define e (engine (lambda (_) (thunk))))
  (define done? (engine-run timeout-ms e))
  (define out (and done? (engine-result e)))
  (engine-kill e)
  (values done? out))

(test-case "abstract interval arithmetic primitives"
  (check-equal?
   (run* (q)
     (iaddo (cons (build-num -2) (build-num 1))
            (cons (build-num 3) (build-num 4))
            q
            B))
   (list (cons (build-num 1) (build-num 5))))
  (check-equal?
   (run* (q)
     (isubo (cons (build-num -2) (build-num 1))
            (cons (build-num 3) (build-num 4))
            q
            B))
   (list (cons (build-num -6) (build-num -2))))
  (check-equal?
   (run* (q)
     (imulo (cons (build-num -2) (build-num 1))
            (cons (build-num 3) (build-num 4))
            q
            B))
   (list (cons (build-num -8) (build-num 4)))))

(test-case "big-step expression eval over interval state"
  (define st (build-state (list (cons -2 1) (cons 3 4))))
  (check-equal?
   (run* (q)
     (aevalo `(add (var ,IDX0) (var ,IDX1)) st q B))
   (list (cons (build-num 1) (build-num 5)))))

(test-case "if-neg transfer: definite and unknown sign behavior"
  (define stmt
    `(if-neg (var ,IDX0)
             (assign ,IDX1 (lit ,(build-num 5)))
             (assign ,IDX1 (lit ,(build-num 7)))))
  (define fuel (build-fuel 4))
  (define top2 (make-top-state 2 B))
  (define st-neg (build-state (list (cons -3 -1) (cons 0 0))))
  (define st-pos (build-state (list (cons 2 3) (cons 0 0))))
  (define st-unk (build-state (list (cons -1 1) (cons 0 0))))

  (check-equal?
   (run* (q)
     (execo stmt st-neg q B fuel top2))
   (list (build-state (list (cons -3 -1) (cons 5 5)))))
  (check-equal?
   (run* (q)
     (execo stmt st-pos q B fuel top2))
   (list (build-state (list (cons 2 3) (cons 7 7)))))
  (check-equal?
   (run* (q)
     (execo stmt st-unk q B fuel top2))
   (list (build-state (list (cons -1 1) (cons 5 7))))))

(test-case "while-neg big-step with fuel"
  (define loop
    `(while-neg (var ,IDX0)
                (assign ,IDX0 (add (var ,IDX0) (lit ,(build-num 1))))))
  (define start (build-state (list (cons -3 -3))))
  (define top1 (make-top-state 1 B))

  ;; Enough fuel: x reaches 0.
  (check-equal?
   (run* (q)
     (execo loop start q B (build-fuel 6) top1))
   (list (build-state (list (cons 0 0)))))

  ;; Fuel exhausted: return top state by contract.
  (check-equal?
   (run* (q)
     (execo loop start q B (build-fuel 1) top1))
   (list top1)))

(test-case "backward query: synthesize pre-state from postcondition"
  (define stmt `(assign ,IDX0 (add (var ,IDX0) (lit ,(build-num 1)))))
  (define out (build-state (list (cons 0 0))))
  (define top1 (make-top-state 1 B))
  (define-values (done? sols)
    (run-with-timeout
     1000
     (lambda ()
       (run 1 (st-in)
         (state-boundedo st-in B)
         (execo stmt st-in out B (build-fuel 2) top1)))))
  (check-true done?)
  (check-equal? sols (list (build-state (list (cons -1 -1))))))
