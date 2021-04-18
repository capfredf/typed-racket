#lang racket/base

(module u racket/base
  (struct foo (a))
  (provide (struct-out foo)))

(module t typed/racket
  (require/typed/provide (submod ".." u)
    (#:struct foo ((a : Symbol))))
  (foo 'a))

(require 't racket/match)
(match (foo 'a)
  [(foo a) a])
