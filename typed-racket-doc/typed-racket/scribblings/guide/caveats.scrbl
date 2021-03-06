#lang scribble/manual

@(require "../utils.rkt"
          scribble/example
          (for-label (only-meta-in 0 typed/racket)))

@(define the-eval (make-base-eval))
@(the-eval '(require typed/racket))

@title[#:tag "caveats"]{Caveats and Limitations}

This section describes limitations and subtle aspects of the
type system that programmers often stumble on while porting programs
to Typed Racket.

@section{The @racket[Integer] type and @racket[integer?]}

In Typed Racket, the @racket[Integer] type corresponds to values
that return @racket[#t] for the @racket[exact-integer?] predicate,
@bold{@emph{not}} the @racket[integer?] predicate. In particular,
values that return @racket[#t] for @racket[integer?] may be
@rtech{inexact number}s (e.g, @racket[1.0]).

When porting a program to Typed Racket, you may need to replace
uses of functions like @racket[round] and @racket[floor] with
corresponding exact functions like @racket[exact-round] and
@racket[exact-floor].

In other cases, it may be necessary to use @racket[assert]ions
or @racket[cast]s.

@section{Type inference for polymorphic functions}

Typed Racket's local type inference algorithm is currently not
able to infer types for polymorphic functions that are used
on higher-order arguments that are themselves polymorphic.

For example, the following program results in a type error
that demonstrates this limitation:

@examples[#:label #f #:eval the-eval
  (eval:error (map cons '(a b c d) '(1 2 3 4)))
]

The issue is that the type of @racket[cons] is also polymorphic:

@examples[#:label #f #:eval the-eval cons]

To make this expression type-check, the @racket[inst] form can
be used to instantiate the polymorphic argument (e.g., @racket[cons])
at a specific type:

@examples[#:label #f #:eval the-eval
  (map (inst cons Symbol Integer) '(a b c d) '(1 2 3 4))
]

@section{Typed-untyped interaction and contract generation}

When a typed module @racket[require]s bindings from an untyped
module (or vice-versa), there are some types that cannot be
converted to a corresponding contract.

This could happen because a type is not yet supported in the
contract system, because Typed Racket's contract generator has
not been updated, or because the contract is too difficult
to generate. In some of these cases, the limitation will be
fixed in a future release.

The following illustrates an example type that cannot be
converted to a contract:

@examples[#:label #f #:eval the-eval
  (eval:error
   (require/typed racket/base
     [object-name (case-> (-> Struct-Type-Property Symbol)
                          (-> Regexp (U String Bytes)))]))
]

This function type by cases is a valid type, but a corresponding
contract is difficult to generate because the check on the result
depends on the check on the domain. In the future, this may be
supported with dependent contracts.

A more approximate type will work for this case, but with a loss
of type precision at use sites:

@examples[#:label #f #:eval the-eval
  (require/typed racket/base
    [object-name (-> (U Struct-Type-Property Regexp)
                     (U String Bytes Symbol))])
  (object-name #rx"a regexp")
]

Use of @racket[define-predicate] also involves contract generation, and
so some types cannot have predicates generated for them. The following
illustrates a type for which a predicate can't be generated:

@examples[#:label #f #:eval the-eval
  (eval:error (define-predicate p? (All (A) (Listof A))))]

@section{Unsupported features}

Typed Racket currently does not support generic interfaces.

@section{Type generalization}

Not so much a caveat as a feature that may have unexpected consequences.
To make programming with invariant type constructors (such as @racket[Boxof])
easier, Typed Racket generalizes types that are used as arguments to invariant
type constructors. For example:

@examples[#:label #f #:eval the-eval
  0
  (define b (box 0))
  b
]

@racket[0] has type @racket[Zero], which means that @racket[b] ``should'' have
type @racket[(Boxof Zero)]. On the other hand, that type is not especially
useful, as it only allows @racket[0] to be stored in the box. Most likely, the
intent was to have a box of a more general type (such as @racket[Integer]) and
initialize it with @racket[0]. Type generalization does exactly that.

In some cases, however, type generalization can lead to unexpected results:

@examples[#:label #f #:eval the-eval
  (box (ann 1 Fixnum))
]

The intent of this code may be to create of box of @racket[Fixnum], but Typed
Racket will generalize it anyway. To create a box of @racket[Fixnum], the box
itself should have a type annotation:

@examples[#:label #f #:eval the-eval
  (ann (box 1) (Boxof Fixnum))
  ((inst box Fixnum) 1)
]

@section{Macros and compile-time computation}

Typed Racket will type-check all expressions at the run-time phase of
the given module and will prevent errors that would occur at run-time.
However, expressions at compile-time---including computations that
occur inside macros---are not checked.

Concretely, this means that expressions inside, for example, a
@racket[begin-for-syntax] block are not checked:

@examples[#:label #f #:eval the-eval
  (eval:error (begin-for-syntax (+ 1 "foo")))
]

Similarly, expressions inside of macros defined in Typed Racket are
not type-checked. On the other hand, the macro's expansion is always
type-checked:

@examples[#:label #f #:eval the-eval
  (eval:no-prompt
   (define-syntax (example-1 stx)
     (+ 1 "foo")
     #'1))
  (eval:no-prompt
   (define-syntax (example-2 stx)
     #'(+ 1 "foo")))
  (eval:error (example-1))
  (eval:error (example-2))
]

Note that functions defined in Typed Racket that are used at
compile-time in other typed modules or untyped modules will be
type-checked and then protected with contracts as described in
@secref["typed-untyped-interaction"].

Additionally, macros that are defined in Typed Racket modules cannot
be used in ordinary Racket modules because such uses can
circumvent the protections of the type system.

@section{Expensive contract boundaries}

Contract boundaries installed for typed-untyped interaction may cause
significant slowdowns. See @secref{contract-costs} for details.

@section{Pattern Matching and Occurrence Typing}


Because Typed Racket type checks code @emph{after} macro
expansion, certain forms---such as @racket[match]---are
difficult for Typed Racket to reason about completely. In
particular, in a @racket[match] clause, the type of an
identifier is often @emph{not} updated to reflect the fact
that a previous pattern failed to match. For example, in
the following function, the type checker is unaware that
if execution reaches the last clause then the
@racket[string?] predicate has already failed to match on
the value for @racket[x], and so @racket[(abs x)] in the
last clause fails to type check:

@examples[#:label #f #:eval the-eval
    (: size (-> (U String Integer) Integer))
  (eval:error
    (define (size x)
      (match x
        [(? string?) (string-length x)]
        [_ (abs x)])))]

Because they are much simpler forms, similar @racket[cond]
and @racket[if] expressions do type check successfully:


@examples[#:label #f #:eval the-eval
  (: size (-> (U String Integer) Integer))
  (define (size x)
      (cond
        [(string? x) (string-length x)]
        [else (abs x)]))]


One work around is to simply not rely on a catch-all "else"
clause that needs to know that previous patterns have failed
to match in order to type check:

@examples[#:label #f #:eval the-eval
  (: size (-> (U String Integer) Integer))
  (define (size x)
      (match x
        [(? string?) (string-length x)]
        [(? exact-integer?) (abs x)]))]

It is important to note, however, that @racket[match] @emph{
 always} inserts a catch-all failure clause if one is not
provided! This means that the type checker will not inform
the programmer that match clause coverage is insufficient
because the implicit (i.e. macro-inserted) failure clause
@emph{will} cover any cases the programmer failed to
anticipate with their pattern matching, e.g.:

@examples[#:label #f #:eval the-eval
  (: size (-> (U String Integer) Integer))
  (define (size x)
      (match x
        [(? string?) (string-length x)]))

  (eval:error
   (size 42))]

Patterns involving an ellipsis @racket[...] for repetition may generate a 
@racket[for] loop that requires annotations on variables to type check. 
The (deliberately obscure) code below does not type check without the type 
annotation on the match pattern variable @racket[c].

@codeblock[#:keep-lang-line? #f]{
  #lang typed/racket
  (: do-nothing (-> (Listof Integer) (Listof Integer)))
  (define (do-nothing lst)
    (match lst
      [(list (? number? #{c : (Listof Integer)}) ...)   c]))
}
  
@section{@racket[is-a?] and Occurrence Typing}

Typed Racket does not use the @racket[is-a?] predicate to refine object types
 because the target object may have been created in untyped code and
 @racket[is-a?] does not check the types of fields and methods.

For example, the code below defines a class type @racket[Pizza%], a subclass
 type @racket[Sauce-Pizza%], and a function @racket[get-sauce] (this
 function contains a type error).
The @racket[get-sauce] function uses @racket[is-a?] to test the class of its
 argument; if the test is successful, the function expects the argument to have
 a field named @racket[topping] that contains a value of type @racket[Sauce].

@codeblock{
  #lang typed/racket

  (define-type Pizza%
    (Class (field [topping Any])))

  (define-type Sauce
    (U 'tomato 'bbq 'no-sauce))

  (define-type Sauce-Pizza%
    (Class #:implements Pizza% (field [topping Sauce])))

  (define sauce-pizza% : Sauce-Pizza%
    (class object%
      (super-new)
      (field [topping 'tomato])))

  (define (get-sauce [pizza : (Instance Pizza%)]) : Sauce
    (cond
      [(is-a? pizza sauce-pizza%)
       (get-field topping pizza)] ; type error
      [else
       'bbq]))}

The type-error message explains that @racket[(get-field topping pizza)]
 can return any kind of value, even when @racket[pizza] is an instance
 of the @racket[sauce-pizza%] class.
In particular, @racket[pizza] could be an instance of an untyped subclass
 that sets its @racket[topping] to the integer @racket[0]:

@codeblock{
  ; #lang racket
  (define evil-pizza%
    (class sauce-pizza%
      (inherit-field topping)
      (super-new)
      (set! topping 0)))}

To downcast as intended, add a @racket[cast] after the @racket[is-a?] test.
Below is a complete example that passes the type checker and raises a run-time
 error to prevent the typed @racket[get-sauce] function from returning
 a non-@racket[Sauce] value.

@examples[#:eval (make-base-eval '(require racket/class))
  (module pizza typed/racket
    (provide get-sauce sauce-pizza%)

    (define-type Pizza%
      (Class (field [topping Any])))

    (define-type Sauce
      (U 'tomato 'bbq 'no-sauce))

    (define-type Sauce-Pizza%
      (Class #:implements Pizza% (field [topping Sauce])))

    (define sauce-pizza% : Sauce-Pizza%
      (class object%
        (super-new)
        (field [topping 'tomato])))

    (define (get-sauce [pizza : (Instance Pizza%)]) : Sauce
      (cond
        [(is-a? pizza sauce-pizza%)
         (define p+ (cast pizza (Instance Sauce-Pizza%)))
         (get-field topping p+)]
        [else
         'no-sauce])))

  (require 'pizza)

  (define evil-pizza%
    (class sauce-pizza%
      (inherit-field topping)
      (super-new)
      (set! topping 0)))

  (eval:error
    (get-sauce (new evil-pizza%)) #;(code:comment "runtime error"))
]
