#;
(exn-pred exn:fail:contract? #rx"string-length")
#lang racket/load

(module a typed/racket/shallow
  (provide p)
  (: p (Parameterof String Index))
  (define p (make-parameter 0 string-length)))

(require 'a)
(p 0)

