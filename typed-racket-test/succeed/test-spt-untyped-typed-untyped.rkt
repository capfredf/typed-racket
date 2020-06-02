#lang racket

(module untyped racket
  (provide prop:foo foo? foo-ref)
  (define-values (prop:foo foo? foo-ref) (make-struct-type-property 'foo)))

(module typed typed/racket
  (require/typed (submod ".." untyped)
    [foo? (-> Any Boolean)]
    [prop:foo (Struct-Property (-> Self Number) foo?)]
    [foo-ref (Exist X (-> (Has-Struct-Property prop:foo) (-> X Number) : X))])
  (provide prop:foo bar foo-ref)
  #;(provide bar)

  (define (bar [x : (Has-Struct-Property prop:foo)])  : Number
    (let ([acc (foo-ref x)])
      (acc x)))
  #;(bar (world)))


(module+ main
  (require (submod ".." typed))
  (struct world [] #:property prop:foo (λ (self) 10))
  (define x (world))
  (define y (world))
  ((foo-ref x) y))
