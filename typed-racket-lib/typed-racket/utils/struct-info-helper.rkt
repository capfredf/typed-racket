#lang racket/base

(provide extract-struct-info/checked
         extract-struct-info/checked/context
         validate-struct-fields
         make-struct-info-self-ctor
         get-type-from-struct-info)

(require racket/struct-info
         "disarm.rkt"
         "../base-env/type-name-error.rkt")

(define (extract-struct-info/checked id)
  (extract-struct-info/checked/context id 'require/typed #f))

(define (extract-struct-info/checked/context id who ctx)
  (syntax-case id ()
   [id
    (and (identifier? #'id)
         (struct-info? (syntax-local-value #'id (lambda () #f))))
    (extract-struct-info (syntax-local-value #'id))]
   [_
    (raise-syntax-error
     who
     "expected an identifier bound to a structure type" ctx id)]))

(define (validate-struct-fields name fields all-selectors who ctx)
  (define sel-names
    ;; filter super selectors
    (let* ([name-str (regexp-quote (format "~a" (syntax-e name)))]
           [sel-rx (regexp (string-append "^" name-str "-(.*)$"))])
      (filter
        values
        (for/list ([sel-id (in-list all-selectors)])
          (define m (and sel-id (regexp-match sel-rx (format "~a" (syntax-e sel-id)))))
          (and m (cadr m))))))
  ;; check number of fields
  (let ([num-fields (length fields)]
        [num-sels (length sel-names)])
    (define missing-selectors?
      ;; selector names might be mangled, e.g. by contract-out
      (< num-sels (length all-selectors)))
    (unless (or missing-selectors?
                (= num-fields num-sels))
      (raise-syntax-error
        who
        (format "found ~a field~a in type, but ~a field~a in struct ~a"
                num-fields (if (= 1 num-fields) "" "s")
                num-sels (if (= 1 num-sels) "" "s") (syntax-e name))
        ctx)))
  ;; check field names
  (for ([field-id (in-list fields)]
        [expected-name (in-list sel-names)]
        [i (in-naturals)])
    (define field-name (format "~a" (syntax-e field-id)))
    (unless (string=? field-name expected-name)
      (raise-syntax-error
        who
        (format "expected field name ~a to be ~a, but found ~a"
                i expected-name field-name)
        ctx field-id)))
  (void))

;Copied from racket/private/define-struct
;FIXME when multiple bindings are supported
(define (self-ctor-transformer orig stx)
  (define (transfer-srcloc orig stx)
    (datum->syntax (disarm* orig) (syntax-e orig) stx orig))

  (syntax-case stx ()
    [(self arg ...) (datum->syntax stx
                                   (cons (syntax-property (transfer-srcloc orig #'self)
                                                          'constructor-for
                                                          (syntax-local-introduce #'self))
                                         (syntax-e (syntax (arg ...))))
                                   stx
                                   stx)]
    [_ (transfer-srcloc orig stx)]))


(struct struct-info-self-ctor (id info type type-is-constr)
  #:property prop:procedure
  (lambda (ins stx)
    (if (struct-info-self-ctor-type-is-constr ins)
        (self-ctor-transformer (struct-info-self-ctor-id ins) stx)
        (type-name-error stx)))
  #:property prop:struct-info (λ (x) (extract-struct-info (struct-info-self-ctor-info x))))

(define (get-type-from-struct-info ins)
  (if (struct-info-self-ctor? ins)
      (struct-info-self-ctor-type ins)
      #f))

(define (make-struct-info-self-ctor id info type [type-is-constr #t])
  (struct-info-self-ctor id info type type-is-constr))
