#lang racket

(require (only-in racket/match match)
         (file "../src/bt_rel.rkt")
         (only-in (file "bt_absint_rel.rkt")
                  build-idx))

(provide (all-defined-out))

;; Core abstract-language grammar (target AST):
;;   idx   ::= '() | (s . idx)
;;   expr  ::= (lit bt) | (var idx) | (add expr expr)
;;           | (sub expr expr) | (mul expr expr)
;;   stmt  ::= (skip) | (assign idx expr) | (seq stmt stmt)
;;           | (if-neg expr stmt stmt) | (while-neg expr stmt)
;;   ival  ::= (bt . bt)   ; [lo, hi], lo <= hi
;;   state ::= (listof ival)
;;
;; Surface syntax accepted by this module:
;;   expr  ::= integer | symbol | (+ expr expr) | (- expr expr)
;;           | (- expr) | (* expr expr)
;;   stmt  ::= skip
;;           | (set! symbol expr)
;;           | (begin stmt ...)
;;           | (if-negative? expr stmt stmt)
;;           | (while-negative? expr stmt)
;; Variables are mapped by position from a user-provided list, e.g.
;;   '(x y z) => x:'(), y:'(s), z:'(s s).

;; build-var-env : (Listof Symbol) -> (Hash Symbol Idx)
(define (build-var-env vars)
  (for/hash ([x vars] [i (in-naturals)])
    (values x (build-idx i))))

;; lookup-var-index : (Hash Symbol Idx) Symbol -> Idx
(define (lookup-var-index env x)
  (hash-ref env x))

;; surface->expr/env : (Hash Symbol Idx) SurfaceExpr -> Expr
(define (surface->expr/env env e)
  (match e
    [(? integer? n)
     `(lit ,(build-num n))]
    [(? symbol? x)
     `(var ,(lookup-var-index env x))]
    [`(+ ,e1 ,e2)
     `(add ,(surface->expr/env env e1)
           ,(surface->expr/env env e2))]
    [`(- ,e1 ,e2)
     `(sub ,(surface->expr/env env e1)
           ,(surface->expr/env env e2))]
    [`(- ,e1)
     `(sub (lit ,(build-num 0))
           ,(surface->expr/env env e1))]
    [`(* ,e1 ,e2)
     `(mul ,(surface->expr/env env e1)
           ,(surface->expr/env env e2))]))

;; seqify : (Listof Stmt) -> Stmt
(define (seqify stmts)
  (cond
    [(null? stmts) '(skip)]
    [(null? (cdr stmts)) (car stmts)]
    [else `(seq ,(car stmts) ,(seqify (cdr stmts)))]))

;; surface->stmt/env : (Hash Symbol Idx) SurfaceStmt -> Stmt
(define (surface->stmt/env env s)
  (match s
    ['skip '(skip)]
    [`(set! ,x ,e)
     `(assign ,(lookup-var-index env x)
              ,(surface->expr/env env e))]
    [`(begin . ,ss)
     (seqify (map (lambda (st) (surface->stmt/env env st)) ss))]
    [`(if-negative? ,e ,s1 ,s2)
     `(if-neg ,(surface->expr/env env e)
              ,(surface->stmt/env env s1)
              ,(surface->stmt/env env s2))]
    [`(while-negative? ,e ,body)
     `(while-neg ,(surface->expr/env env e)
                 ,(surface->stmt/env env body))]))

;; surface->expr : (Listof Symbol) SurfaceExpr -> Expr
(define (surface->expr vars e)
  (surface->expr/env (build-var-env vars) e))

;; surface->stmt : (Listof Symbol) SurfaceStmt -> Stmt
(define (surface->stmt vars s)
  (surface->stmt/env (build-var-env vars) s))

(module+ test
  (require rackunit
           minikanren
           (file "bt_absint_rel.rkt"))

  (define (mk-bound len)
    (build-list len (lambda (_) 'k)))

  (define B (mk-bound 3))
  (define IDX0 (build-idx 0))
  (define IDX1 (build-idx 1))

  (test-case "surface parser lowers Racket-style syntax"
    (define vars '(x y))
    (check-equal?
     (surface->expr vars '(- x))
     `(sub (lit ,(build-num 0)) (var ,IDX0)))
    (check-equal?
     (surface->stmt vars '(if-negative? x (set! y 5) (set! y 7)))
     `(if-neg (var ,IDX0)
              (assign ,IDX1 (lit ,(build-num 5)))
              (assign ,IDX1 (lit ,(build-num 7)))))
    (define stmt
      (surface->stmt
       vars
       '(begin
          (set! y (+ x 1))
          (if-negative? y (set! y 5) (set! y 7)))))
    (define st-in (build-state (list (cons -3 -3) (cons 0 0))))
    (check-equal?
     (run* (q)
       (execo stmt st-in q B (build-fuel 5) (make-top-state 2 B)))
     (list (build-state (list (cons -3 -3) (cons 5 5))))))

  (test-case "capstone: factorial-style countdown with nested arithmetic"
    (define vars '(i acc chk))
    (define B4 (mk-bound 4))
    (define stmt
      (surface->stmt
       vars
       '(begin
          (set! acc 1)
          (while-negative? i
            (begin
              (set! acc (+ (* acc (- 0 i)) 0))
              (set! i (+ i 1))))
          (set! chk (+ (* acc 1) (+ i 0))))))
    (define st-in (build-state (list (cons -4 -4) (cons 0 0) (cons 0 0))))
    (define st-out (build-state (list (cons 0 0) (cons 24 24) (cons 24 24))))
    (check-equal?
     (run* (q)
       (execo stmt st-in q B4 (build-fuel 8) (make-top-state 3 B4)))
     (list st-out))))
