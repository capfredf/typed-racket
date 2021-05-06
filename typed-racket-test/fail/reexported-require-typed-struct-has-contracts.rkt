#lang racket/base

(struct my-exn exn ())

(module u racket/base
  (struct apple (a))
  (struct pear (a) #:constructor-name make-pear)
  (provide (struct-out apple)
           (struct-out pear)))

(module t typed/racket
  (require/typed (submod ".." u)
    (#:struct apple ((a : Symbol)))
    (#:struct pear ((a : Number)) #:constructor-name make-pear))
  (provide apple apple-a make-pear))

;; (define counter 0)
;; (require 't)

;; (define-syntax-rule (verify-contract expr ...)
;;   (begin (with-handlers ([exn:fail:contract? (lambda _
;;                                                (set! counter (add1 counter)))])
;;            expr)
;;          ...))

;; (verify-contract (apple 42)
;;                  (apple-a 20)
;;                  (make-pear 'xxx))

;; (displayln counter)
