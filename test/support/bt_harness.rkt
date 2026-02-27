#lang racket

(require rackunit
         minikanren
         racket/engine
         racket/list
         racket/random
         (file "../../src/bt_oracle.rkt"))

(provide int->bt-term
         bt->int-term
         max-abs-for-len
         int-range
         cartesian-product
         decode-bt
         decode-bt-tuple
         raw-answer-coverage
         bto-boundo
         reset-bt-warnings!
         bt-warnings
         check-bt-case
         check-bt-case-strict
         check-bt-random)

(struct bt-warning (kind case detail) #:transparent)

(define current-bt-warnings (make-parameter '()))

(define trits '(T 0 1))

(define (valid-trit? t)
  (or (eq? t 'T)
      (equal? t 0)
      (equal? t 1)))

(define (reset-bt-warnings!)
  (current-bt-warnings '()))

(define (bt-warnings)
  (reverse (current-bt-warnings)))

(define (emit-warning! kind case-name detail)
  (current-bt-warnings
   (cons (bt-warning kind case-name detail)
         (current-bt-warnings)))
  (printf "WARNING[~a] ~a: ~a\n" kind case-name detail))

(define (int->bt-term n)
  (unless (integer? n)
    (error 'int->bt-term "expected integer, got: ~a" n))
  (int->bt n))

(define (bt-digits bt)
  (let loop ([t bt] [acc '()])
    (cond
      [(null? t) (reverse acc)]
      [(pair? t)
       (define d (car t))
       (if (valid-trit? d)
           (loop (cdr t) (cons d acc))
           #f)]
      [else #f])))

(define (bt->int-term bt)
  (define digits (bt-digits bt))
  (cond
    [(not digits) #f]
    [(null? digits) 0]
    [(equal? (last digits) 0) #f]
    [else (bt->int bt)]))

(define (int-range lo hi)
  (for/list ([n (in-range lo (add1 hi))]) n))

(define (max-abs-for-len len)
  (/ (- (expt 3 len) 1) 2))

(define (cartesian-product xss)
  (cond
    [(null? xss) (list '())]
    [else
     (apply append
            (for/list ([x (car xss)])
              (map (lambda (rest)
                     (cons x rest))
                   (cartesian-product (cdr xss)))))]))

(define (decode-bt-tuple raw)
  ;; A single answer like '(0 1 T) is a BT term, not a tuple.
  (define single (bt->int-term raw))
  (cond
    [(not (false? single)) (list single)]
    [(list? raw)
     (let loop ([xs raw] [acc '()])
       (cond
         [(null? xs) (reverse acc)]
         [else
          (define n (bt->int-term (car xs)))
          (if (false? n)
              #f
              (loop (cdr xs) (cons n acc)))]))]
    [else #f]))

(define (decode-bt raw)
  (decode-bt-tuple raw))

(define (bto-boundo q maxlen)
  (define (gen-any len)
    (cond
      [(zero? len) (list '())]
      [else
       (apply append
              (for/list ([d trits])
                (map (lambda (rest)
                       (cons d rest))
                     (gen-any (sub1 len)))))]))
  (define (canonical-nonzero? bt)
    (and (pair? bt) (not (equal? (last bt) 0))))
  (define all-bts
    (append
     (list '())
     (apply append
            (for/list ([len (in-range 1 (add1 maxlen))])
              (filter canonical-nonzero? (gen-any len))))))
  (define (disj lst)
    (cond
      [(null? lst) (== #f #t)]
      [else
       (conde
         [(== q (car lst))]
         [(disj (cdr lst))])]))
  (disj all-bts))

(define (run-with-timeout timeout-ms thunk)
  (define e (engine (lambda (enable-stop)
                      (thunk))))
  (define done? (engine-run timeout-ms e))
  (cond
    [done?
     (define out (engine-result e))
     (engine-kill e)
     (values #f out)]
    [else
     (engine-kill e)
     (values #t #f)]))

(define (normalize-set xs)
  (remove-duplicates xs equal?))

(define (expectation-set expected-set)
  (normalize-set
   (if (procedure? expected-set)
       (expected-set)
       expected-set)))

(define (decode-observed decode-answer raw-answers)
  (for/list ([raw raw-answers])
    (decode-answer raw)))

(define (logic-var-symbol? x)
  (and (symbol? x)
       (regexp-match? #px"^_\\.?[0-9]+$" (symbol->string x))))

(define (known-constraint? x)
  (and (pair? x)
       (symbol? (car x))
       (member (car x) '(=/=) eq?)))

(define (split-raw-answer raw)
  (if (and (pair? raw)
           (pair? (cdr raw))
           (list? (cdr raw))
           (andmap known-constraint? (cdr raw)))
      (values (car raw) (cdr raw))
      (values raw '())))

(define (walk-subst t subst)
  (cond
    [(logic-var-symbol? t)
     (define hit (hash-ref subst t #f))
     (if hit (walk-subst hit subst) t)]
    [else t]))

(define (walk* t subst)
  (define w (walk-subst t subst))
  (cond
    [(pair? w)
     (cons (walk* (car w) subst)
           (walk* (cdr w) subst))]
    [else w]))

(define (ground-without-vars? t)
  (cond
    [(logic-var-symbol? t) #f]
    [(pair? t)
     (and (ground-without-vars? (car t))
          (ground-without-vars? (cdr t)))]
    [else #t]))

(define (unify-pattern pat val subst)
  (define p (walk-subst pat subst))
  (cond
    [(logic-var-symbol? p)
     (hash-set subst p val)]
    [(pair? p)
     (and (pair? val)
          (let ([s1 (unify-pattern (car p) (car val) subst)])
            (and s1 (unify-pattern (cdr p) (cdr val) s1))))]
    [(null? p)
     (and (null? val) subst)]
    [else
     (and (equal? p val) subst)]))

(define (disequality-ok? c subst)
  (cond
    [(and (equal? (car c) '=/=)
          (= (length c) 2)
          (list? (second c)))
     (for/and ([pair (second c)])
       (and (list? pair)
            (= (length pair) 2)
            (let* ([lhs (walk* (first pair) subst)]
                   [rhs (walk* (second pair) subst)])
              (not (and (ground-without-vars? lhs)
                        (ground-without-vars? rhs)
                        (equal? lhs rhs))))))]
    [else #f]))

(define (constraints-ok? constraints subst)
  (for/and ([c constraints])
    (disequality-ok? c subst)))

(define (expected->bt-term maybe-tuple)
  (cond
    [(and (list? maybe-tuple)
          (andmap integer? maybe-tuple))
     (if (= (length maybe-tuple) 1)
         (int->bt-term (first maybe-tuple))
         (map int->bt-term maybe-tuple))]
    [else #f]))

(define (covered-expected-by-raw raw expected)
  (define-values (term constraints) (split-raw-answer raw))
  (define expected-terms
    (for/list ([want expected])
      (cons want (expected->bt-term want))))
  (if (ormap (lambda (x) (false? (cdr x))) expected-terms)
      #f
      (for/list ([entry expected-terms]
                 #:when
                 (let* ([want-term (cdr entry)]
                        [subst (unify-pattern term want-term (hash))])
                   (and subst (constraints-ok? constraints subst))))
        (car entry))))

(define (raw-answer-coverage raw expected [decode-answer decode-bt-tuple])
  (define decoded (decode-answer raw))
  (cond
    [(not (false? decoded))
     (if (member decoded expected equal?) (list decoded) '())]
    [else
     (covered-expected-by-raw raw expected)]))

(define (normalize-observed! case-name expected decode-answer raw-answers)
  (define covered '())
  (for ([raw raw-answers])
    (define decoded (decode-answer raw))
    (cond
      [(not (false? decoded))
       (unless (member decoded expected equal?)
         (fail-check
          (format "~a: spurious answer observed: ~s (decoded ~s)"
                  case-name raw decoded)))
       (set! covered (cons decoded covered))]
      [else
       ;; Fallback for partially instantiated answers: compare denotation
       ;; against the finite expected set under BT-domain bounds.
       (define denotation (covered-expected-by-raw raw expected))
       (cond
         [(false? denotation)
          (fail-check
           (format "~a: symbolic answer unsupported for current expected-set shape: ~s"
                   case-name raw))]
         [(null? denotation)
          (fail-check
           (format "~a: spurious symbolic answer observed: ~s"
                   case-name raw))]
         [else
          (set! covered (append denotation covered))])]))
  (normalize-set covered))

(define (check-bt-case case-name
                       #:expected-set [expected-set (lambda () '())]
                       #:run-observed run-observed
                       #:decode-answer [decode-answer decode-bt-tuple]
                       #:k [k 5]
                       #:k2 [k2 10]
                       #:timeout-ms [timeout-ms 120]
                       #:expect-timeout? [expect-timeout? #f])
  (when expect-timeout?
    (define-values (timed-out? _)
      (run-with-timeout timeout-ms
                        (lambda ()
                          (run-observed k2))))
    (unless timed-out?
      (fail-check
       (format "~a: expected timeout (~ams), but query completed"
               case-name timeout-ms)))
    (void))

  (unless expect-timeout?
    (define expected (expectation-set expected-set))

    (define-values (timed-out-k? raw-k)
      (run-with-timeout timeout-ms
                        (lambda ()
                          (run-observed k))))
    (define-values (timed-out-k2? raw-k2)
      (run-with-timeout timeout-ms
                        (lambda ()
                          (run-observed k2))))

    (unless timed-out-k?
      (void (normalize-observed! case-name expected decode-answer raw-k)))

    (cond
      [timed-out-k?
       (emit-warning! 'timeout case-name
                      (format "run ~a timed out at ~ams" k timeout-ms))]
      [timed-out-k2?
       (emit-warning! 'timeout case-name
                      (format "run ~a timed out at ~ams" k2 timeout-ms))]
      [else
       (define covered-k2
         (normalize-observed! case-name expected decode-answer raw-k2))

       (when (and (pair? expected) (null? covered-k2))
         (emit-warning! 'missing case-name
                        "expected non-empty result set, observed empty by k2"))

       (define missing
         (filter (lambda (want)
                   (not (member want covered-k2 equal?)))
                 expected))
       (when (pair? missing)
         (emit-warning! 'missing case-name
                        (format "missing ~a expected answers by run ~a"
                                (length missing) k2)))])))

(define (check-bt-case-strict case-name
                              #:expected-set [expected-set (lambda () '())]
                              #:run-observed run-observed
                              #:decode-answer [decode-answer decode-bt-tuple]
                              #:k [k 5]
                              #:k2 [k2 10]
                              #:timeout-ms [timeout-ms 120]
                              #:expect-timeout? [expect-timeout? #f])
  (reset-bt-warnings!)
  (check-bt-case case-name
                 #:expected-set expected-set
                 #:run-observed run-observed
                 #:decode-answer decode-answer
                 #:k k
                 #:k2 k2
                 #:timeout-ms timeout-ms
                 #:expect-timeout? expect-timeout?)
  (define warns (bt-warnings))
  (unless (null? warns)
    (fail-check
     (format "~a: expected no warnings, got: ~s"
             case-name warns)))
  (reset-bt-warnings!))

(define (check-bt-random name
                         #:trials [trials 100]
                         #:range-max [range-max 300]
                         #:arity [arity 2]
                         #:sample [sample #f]
                         #:check check)
  (for ([i (in-range trials)])
    (define values
      (if sample
          (sample i)
          (for/list ([j (in-range arity)])
            (random (add1 range-max)))))
    (check i values)))
