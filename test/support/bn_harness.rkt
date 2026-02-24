#lang racket

(require rackunit
         minikanren
         racket/engine
         racket/list
         racket/random)

(provide nat->bn
         bn->nat
         nat-range
         cartesian-product
         decode-bn
         decode-bn-tuple
         bno-boundo
         reset-bn-warnings!
         bn-warnings
         check-bn-case
         check-bn-random)

(struct bn-warning (kind case detail) #:transparent)

(define current-bn-warnings (make-parameter '()))

(define (reset-bn-warnings!)
  (current-bn-warnings '()))

(define (bn-warnings)
  (reverse (current-bn-warnings)))

(define (emit-warning! kind case-name detail)
  (current-bn-warnings
   (cons (bn-warning kind case-name detail)
         (current-bn-warnings)))
  (printf "WARNING[~a] ~a: ~a\n" kind case-name detail))

(define (nat->bn n)
  (cond
    [(negative? n)
     (error 'nat->bn "expected natural number, got: ~a" n)]
    [(zero? n) '()]
    [else
     (cons (modulo n 2)
           (nat->bn (quotient n 2)))]))

(define (bn-bits bn)
  (let loop ([t bn] [acc '()])
    (cond
      [(null? t) (reverse acc)]
      [(pair? t)
       (define d (car t))
       (if (or (equal? d 0) (equal? d 1))
           (loop (cdr t) (cons d acc))
           #f)]
      [else #f])))

(define (bn->nat bn)
  (define bits (bn-bits bn))
  (cond
    [(not bits) #f]
    [(null? bits) 0]
    [(equal? (last bits) 0) #f]
    [else
     (let loop ([ds bits] [place 1] [acc 0])
       (cond
         [(null? ds) acc]
         [else
          (loop (cdr ds)
                (* place 2)
                (+ acc (* (car ds) place)))]))]))

(define (nat-range lo hi)
  (for/list ([n (in-range lo (add1 hi))]) n))

(define (cartesian-product xss)
  (cond
    [(null? xss) (list '())]
    [else
     (apply append
            (for/list ([x (car xss)])
              (map (lambda (rest)
                     (cons x rest))
                   (cartesian-product (cdr xss)))))]))

(define (decode-bn-tuple raw)
  ;; A single answer like '(0 1) is a BN term, not a tuple.
  (define single (bn->nat raw))
  (cond
    [(not (false? single)) (list single)]
    [(list? raw)
     (let loop ([xs raw] [acc '()])
       (cond
         [(null? xs) (reverse acc)]
         [else
          (define n (bn->nat (car xs)))
          (if (false? n)
              #f
              (loop (cdr xs) (cons n acc)))]))]
    [else #f]))

(define (decode-bn raw)
  (decode-bn-tuple raw))

(define (bno-boundo q maxlen)
  (define bits '(0 1))
  (define (gen-len len)
    (cond
      [(= len 1) (list '(1))]
      [else
       (apply append
              (for/list ([d bits])
                (map (lambda (rest)
                       (cons d rest))
                     (gen-len (sub1 len)))))]))
  (define all-bns
    (append
     (list '())
     (apply append
            (for/list ([len (in-range 1 (add1 maxlen))])
              (gen-len len)))))
  (define (disj lst)
    (cond
      [(null? lst) (== #f #t)]
      [else
       (conde
         [(== q (car lst))]
         [(disj (cdr lst))])]))
  (disj all-bns))

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

(define (check-spurious! case-name expected decoded raw-answers)
  (for ([ans decoded]
        [raw raw-answers])
    (when (false? ans)
      (fail-check
       (format "~a: undecodable answer observed: ~s"
               case-name raw)))
    (unless (member ans expected equal?)
      (fail-check
       (format "~a: spurious answer observed: ~s (decoded ~s)"
               case-name raw ans)))))

(define (check-bn-case case-name
                       #:expected-set [expected-set (lambda () '())]
                       #:run-observed run-observed
                       #:decode-answer [decode-answer decode-bn-tuple]
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
      (define decoded-k (normalize-set (decode-observed decode-answer raw-k)))
      (check-spurious! case-name expected decoded-k raw-k))

    (cond
      [timed-out-k?
       (emit-warning! 'timeout case-name
                      (format "run ~a timed out at ~ams" k timeout-ms))]
      [timed-out-k2?
       (emit-warning! 'timeout case-name
                      (format "run ~a timed out at ~ams" k2 timeout-ms))]
      [else
       (define decoded-k2
         (normalize-set (decode-observed decode-answer raw-k2)))
       (check-spurious! case-name expected decoded-k2 raw-k2)

       (when (and (pair? expected) (null? decoded-k2))
         (emit-warning! 'missing case-name
                        "expected non-empty result set, observed empty by k2"))

       (define missing
         (filter (lambda (want)
                   (not (member want decoded-k2 equal?)))
                 expected))
       (when (pair? missing)
         (emit-warning! 'missing case-name
                        (format "missing ~a expected answers by run ~a"
                                (length missing) k2)))])))

(define (check-bn-random name
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
