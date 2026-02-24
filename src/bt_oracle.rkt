#lang racket
(provide bt->int int->bt)

(define (trit->int t)
  (match t
    ['T -1]
    ['0 0]
    ['1 1]
    [else (error 'bt->int "invalid trit: ~a" t)]))

(define (bt->int bt)
  (let loop ([ds bt] [place 1] [acc 0])
    (cond
      [(null? ds) acc]
      [else
       (loop (cdr ds)
             (* place 3)
             (+ acc (* (trit->int (car ds)) place)))])))

(define (int->bt n)
  (define (step k acc)
    (if (zero? k)
        acc
        (let* ([r (modulo k 3)]
               [digit (case r
                        [(0) '0]
                        [(1) '1]
                        [(2) 'T])]
               [next (case r
                       [(0) (/ k 3)]
                       [(1) (/ (- k 1) 3)]
                       [(2) (/ (+ k 1) 3)])])
          (step next (cons digit acc)))))
  (cond
    [(zero? n) '()]
    [else (reverse (step n '()))]))
