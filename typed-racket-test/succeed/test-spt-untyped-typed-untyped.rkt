#lang racket

(module untyped racket
  (provide prop:foo foo?)
  (define-values (prop:foo foo? foo-ref) (make-struct-type-property 'foo)))

(module typed typed/racket
  (require/typed (submod ".." untyped)
    [foo? (-> Any Boolean)]
    [prop:foo (Struct-Property Number foo?)])
  (provide prop:foo bar)
  #;(provide bar)

  (define (bar [x : (Has-Struct-Property prop:foo)])  : Number
    10)
  #;(bar (world)))


(module+ main
  (require (submod ".." typed))
  (struct world [] #:property prop:foo 10)
  (bar (world)))
