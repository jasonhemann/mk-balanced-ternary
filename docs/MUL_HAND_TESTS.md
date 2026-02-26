# Multiplication Hand-Test Playbook (`*o`)

Use this when manually probing BT multiplication behavior in the REPL.

```racket
(require minikanren
         (file "../src/bt_rel.rkt")
         (file "../src/bt_oracle.rkt")
         (file "../test/support/bt_harness.rkt"))
```

## 1) Ground sanity

```racket
(run* (q) (*o (int->bt-term 4) (int->bt-term -3) q))
;; expected decoded: -12
```

```racket
(run* (q) (*o (int->bt-term -7) (int->bt-term -2) q))
;; expected decoded: 14
```

## 2) Identity and zero surfaces

```racket
(run 10 (q) (*o '(1) q q))
;; expected shape: '(() (_.0 . _.1))
```

```racket
(run 10 (q) (*o '() q '()))
;; expected shape: '(_.0)
```

```racket
(run* (q) (*o (int->bt-term 9) (int->bt-term 0) q))
;; expected decoded: 0
```

## 3) Inverse/factor modes

```racket
(run* (q) (*o (int->bt-term 3) q (int->bt-term 18)))
;; expected decoded set: (6)
```

```racket
(run* (q)
  (fresh (x y)
    (*o x y (int->bt-term 12))
    (== q (list x y))))
;; expected decoded set contains all factor pairs of 12 in BT domain
```

## 4) Partial-tail modes (bounded)

```racket
(run* (q)
  (fresh (tail y)
    (bto-boundo tail 3)
    (bto-boundo y 3)
    (*o `(1 . ,tail) y (int->bt-term 8))
    (== q (list tail y))))
;; compare decoded tuples to host equation:
;; (1 + 3*tail) * y = 8
```

## 5) Flow-order spot checks (bounded)

```racket
(define bound (build-list 2 (lambda (i) 'k)))
```

```racket
;; bounds -> bind -> rel
(run* (q)
  (fresh (x y z)
    (bto-boundedo x bound) (bto-boundedo y bound) (bto-boundedo z bound)
    (== x (int->bt-term 2))
    (== y (int->bt-term -2))
    (*o x y z)
    (== q z)))
```

```racket
;; bounds -> rel -> bind
(run* (q)
  (fresh (x y z)
    (bto-boundedo x bound) (bto-boundedo y bound) (bto-boundedo z bound)
    (*o x y z)
    (== x (int->bt-term 2))
    (== y (int->bt-term -2))
    (== q z)))
```

Both should decode to `-4` (stream order may differ by query shape).

## 6) Decode helper

```racket
(map decode-bt-tuple raw-answers)
```

Remember:
- compare denotational sets, not raw stream order;
- symbolic/open answers can be valid and intentionally non-ground.
