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
;;           | (if (< expr 0) stmt stmt)
;;           | (if (negative? expr) stmt stmt)
;;           | (while (< expr 0) stmt)
;;           | (while (negative? expr) stmt)
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

;; surface-test->expr/env : (Hash Symbol Idx) SurfaceTest -> Expr
(define (surface-test->expr/env env t)
  (match t
    [`(< ,e 0) (surface->expr/env env e)]
    [`(negative? ,e) (surface->expr/env env e)]
    [`(neg? ,e) (surface->expr/env env e)]))

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
    [`(if ,tst ,s1 ,s2)
     `(if-neg ,(surface-test->expr/env env tst)
              ,(surface->stmt/env env s1)
              ,(surface->stmt/env env s2))]
    [`(while ,tst ,body)
     `(while-neg ,(surface-test->expr/env env tst)
                 ,(surface->stmt/env env body))]))

;; surface->expr : (Listof Symbol) SurfaceExpr -> Expr
(define (surface->expr vars e)
  (surface->expr/env (build-var-env vars) e))

;; surface->stmt : (Listof Symbol) SurfaceStmt -> Stmt
(define (surface->stmt vars s)
  (surface->stmt/env (build-var-env vars) s))
