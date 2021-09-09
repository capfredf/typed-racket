#lang typed/scheme



(define-type (T+ elem)
  (U (A elem)))

(define-type (T elem)
  (U (T+ elem) 2))

(define-struct: (x) A ())
