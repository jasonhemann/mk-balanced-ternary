# Repository Guidelines

Balanced-ternary miniKanren integer arithmetic (LSD-first)

Representation (RELATIONS):
- A balanced-ternary integer is a list of trits, least-significant first.
- Trits are symbols: 'T '0 '1 (where 'T means -1).
- Zero is '().
- Canonical form: either '() OR the most-significant trit (last element) is not '0.

Oracle (HOST CODE, used only in tests):
- bt->int : (Listof Trit) -> Integer
- int->bt : Integer -> (Listof Trit), producing canonical representation
- The oracle may use host arithmetic freely.
- Relations MUST NOT use host integer arithmetic (no +, -, *, quotient, remainder, etc.).

Deliverables / Milestones

M0 (Oracle)
- Implement src/bt_oracle.rkt: bt->int and int->bt using the above representation.
- int->bt must be canonical.

M1 (Core Relations; no ordering)
Implement in src/bt_rel.rkt:
- trito : trit is one of 'T '0 '1
- add3o : balanced full-adder
    add3o a b cin s cout  iff  a+b+cin = s + 3*cout
    (all five args are trits)
- nego : digitwise negation ('T<->'1, '0->'0)
- pluso : x + y = z  (x y z are bt lists), via ripple-carry using add3o
- minuso : x - y = z (define via pluso + nego)
- mul1o : x * trit = out, where trit in {'T,'0,'1}
- *o : x * y = z via y = b0 + 3*y' recurrence: (x*b0) + 3*(x*y')

Operational expectations (what must work)
- pluso and *o MUST behave correctly for:
  (a) ground/ground (x,y ground -> unique z)
  (b) ground/var with explicit bounds provided by tests (x,z ground -> finitely many y)
- var/var is not a required termination mode unless bounded.

Boundary canonicalization
- Do NOT enforce canonical form inside pluso/*o unless it is local and non-branching.
- Tests may constrain solutions with a bounded-canonical predicate (provided in test harness).

M2 (Optional later): Ordering
- If/when implementing <o/<=o, require an explicit max-digit bound parameter.
- Unbounded var/var ordering is not a goal.

Definition of done
- `raco test test/bt_rel_test.rkt` passes:
  - unit tests for add3o/pluso/*o edge cases
  - randomized property tests against oracle for [-200,200]
  - bounded ground/var tests (explicit max-digit bound), checking “all returned solutions are correct”
