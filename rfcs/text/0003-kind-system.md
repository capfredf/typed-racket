- Feature Name: Kind System
- Start Date: 9/27/202
- RFC PR: #1143
- Feature Commit(s): PR #1143

# Summary

Typed Racket currently conflates polymorphic with type constructors.  This RPC
aims to provide a kind system to separate those two concepts. Note that higher
kinds and type-level lambdas will be discussed in difference RFCs.

# Motivation

Due to lack of a kind system, the type checker appromimates type-level
abstractions and applications a la recursive and polymorphic types, which has
caused confusion and issues. For example, `Listof`, which is actually a type
constructor, has kind `*`, because it is bound to `(All (a) (Rec b (U Null
(Pairof a b)))`. User-define types also face the same problem:

```racket
(define-type (I a) a)
(define (afunc [arg : I]) : Void
    (void))
```

Ideally, the program should not type-check because `I` is a type constructor
with the kind `* => *`. However, it type-checks because the type checker
treats `I` as an alias to `(All (a) a)`.

# Guide-level explanation

## Changes to define-type

`define-type` still has two forms:

- (define-type new-t t) creates new-t, an alias to t at the right hand side.

- (define-type (new-t a ...) t) creates an n-ary type constructor named `new-t`,
  whereas previously `new-t` was an alias to the polymorphic type `(All (a ...)
  t))`

## Print the kind of a type at the REPL.

`:kind`, is added for interactive uses at the Typed Racket REPL.  It prints the
 kind of a type-level expression. For example, `(:kind Integer)` will print `*`
 and `(:kind Listof)` will print `(=> * *)`.

## Programs annotated with ill-kinded types will be rejected

Due to the conflation of type constructors and polymorphic types, previously a
binding supposedly for a type constructor could be used as a shorthand for a
polymorphic type as shown above.  With the new changes, that problem will get
rejected and the type checker will report `I` in `[arg : I]` is not a type.


# Reference-level explanation

## `*`, `(=> * ... *)` and `(=o * ... *)`

All the base types now have kind *, but All the container /types/ are no longer
/types/ any more. They are type constructors. In other words, if we use :kind to
inspect those types, the result will be in the form of `(=> * ...)`. For
example, `Pairof` has kind `(=> * * *)`, `Listof` has kind `(=> * *)` and `U`
has kind `(=o * ... *)`. Here `=>` denotes a productive type constructor and
`=o` denotes an unproductive type constructor. The status of a type
constructor's productivity plays a critcal role in checking if a recurive type
is productive a not.

## Checking productivity of recursive types

The type variable of a recursive type must appear in productive position,
i.e. arguments to application of productive type constructors. For example:

- (Rec x x) is unproductive.

- (Rec x (U x Integer)) is unproductive, because U is unproductive and x is the
  same the level of the enviroment when checking operands to U.

- (Rec x (U Null (Pairof x Integer))) is productive, because U is productive and x
  is at one-level lower than the enviroment when checking operands to Pairof.

- (Rec x (Pairof (U x Integer) Integer)) is productive.


## two modes of productivity checking

Apart from the regular checking as shown above, the type checker needs to tell
whether a user-provided type constructor is productive or not, i.e. the type
checker needs to generate its status of productivity. We dub this mode
"synthesis".

.........


# Drawbacks and Alternatives
[drawbacks]: #drawbacks

## Drawbacks
Adds complexity to the type checker.

## Backward Compatibility

Previously, programs that abused bindings supposedly
for type constructors as shorthands for polymporphic types type-checked, but
with the new kind system, they will be rejected.

# Prior art
[prior-art]: #prior-art

As of Racket 7.8, Typed Racket doesn't have a kind system.