#lang typed/racket/base

(module mod1 typed/racket/base
  (provide (all-defined-out))
  (struct a ([aa : Number]) #:type-name A)
  #;;
  (struct ba a ())
  #;;
  (struct bA A ()))

(module mod2 racket/base
  (require (submod ".." mod1))
  (define a2 (a 1))
  #;
  (a-aa (struct-copy a a2 [aa 2]))
  (a-aa (struct-copy A a2 [aa 2])))

(require 'mod2)
