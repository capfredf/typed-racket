#lang racket

(module typed typed/racket
  (provide prop:foo foo?)
  (: prop:foo (Struct-Property Number))
  (: foo? (-> Any Boolean : (Has-Struct-Property prop:foo)))
  (: foo-ref (-> (Has-Struct-Property prop:foo) Number))
  (define-values (prop:foo foo? foo-ref) (make-struct-type-property 'foo))

  (provide bar bar1)

  (define (bar [x : (Has-Struct-Property prop:foo)])  : Number
    10)
  (define (bar1 [x : Number]) : Number
    x)
  #;(bar (world)))


(module+ main
  (require (submod ".." typed))
  (struct world [] #:property prop:foo 10)
  (bar (world)))
