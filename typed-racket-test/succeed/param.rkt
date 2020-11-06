#lang typed/racket

(parameterize ([current-directory ".."])
  (current-directory)
  (current-directory ".."))


(: old-param Parameterization)
(define old-param (current-parameterization))

(current-directory "..")

(call-with-parameterization old-param (lambda () (current-directory)))

(parameterization? old-param)

(: a-var (Parameterof (U String Number) Number))
(define a-var (make-parameter (ann 10 Number) (lambda ([y : (U String Number)]) : Number (if (string? y) (string-length y) y))))
(ann a-var (Parameterof String Complex))
(define-type a-type (case-> (-> String Void) (-> Complex)))
(ann a-var a-type)
