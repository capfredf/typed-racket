#lang racket/base
(require racket/match rackunit rackunit/text-ui racket/place racket/list syntax/location
         rackunit/private/format)

(require (only-in "typecheck-tests.rkt" [tests typecheck-tests])
         (only-in "subtype-tests.rkt" [tests subtype-tests])
         (only-in "type-equal-tests.rkt" [tests type-equal-tests])
         (only-in "remove-intersect-tests.rkt" [tests remove-intersect-tests])
         (only-in "static-contract-conversion-tests.rkt" [tests static-contract-conversion-tests])
         (only-in "static-contract-instantiate-tests.rkt" [tests static-contract-instantiate-tests])
         (only-in "static-contract-optimizer-tests.rkt" [tests static-contract-optimizer-tests])
         (only-in "parse-type-tests.rkt" [tests parse-type-tests])
         (only-in "subst-tests.rkt" [tests subst-tests])
         (only-in "infer-tests.rkt" [tests infer-tests])
         (only-in "keyword-expansion-test.rkt" [tests keyword-expansion-test])
         (only-in "special-env-typecheck-tests.rkt" [tests special-env-typecheck-tests])
         (only-in "contract-tests.rkt" [tests contract-tests])
         (only-in "interactive-tests.rkt" [tests interactive-tests])
         (only-in "type-printer-tests.rkt" [tests type-printer-tests])
         (only-in "type-alias-helper.rkt" [tests type-alias-helper])
         (only-in "class-tests.rkt" [tests class-tests])
         (only-in "class-util-tests.rkt" [tests class-util-tests])
         (only-in "check-below-tests.rkt" [tests check-below-tests])
         (only-in "init-env-tests.rkt" [tests init-env-tests])
         (only-in "prop-tests.rkt" [tests prop-tests])
         (only-in "metafunction-tests.rkt" [tests metafunction-tests])
         (only-in "generalize-tests.rkt" [tests generalize-tests])
         (only-in "prims-tests.rkt" [tests prims-tests])
         (only-in "tooltip-tests.rkt" [tests tooltip-tests])
         (only-in "prefab-tests.rkt" [tests prefab-tests])
         (only-in "json-tests.rkt" [tests json-tests])
         (only-in "typed-units-tests.rkt" [tests typed-units-tests])
         (only-in "type-constr-tests.rkt" [tests type-constr-tests]))

(define unit-tests (list typecheck-tests
                           subtype-tests
                           type-equal-tests
                           remove-intersect-tests
                           static-contract-conversion-tests
                           static-contract-instantiate-tests
                           static-contract-optimizer-tests
                           parse-type-tests
                           subst-tests
                           infer-tests
                           keyword-expansion-test
                           special-env-typecheck-tests
                           contract-tests
                           interactive-tests
                           type-printer-tests
                           type-alias-helper
                           class-tests
                           class-util-tests
                           check-below-tests
                           init-env-tests
                           prop-tests
                           metafunction-tests
                           generalize-tests
                           prims-tests
                           tooltip-tests
                           prefab-tests
                           json-tests
                           typed-units-tests
                           type-constr-tests))


(require racket/runtime-path)

(define state (make-hash))
(define-runtime-path src-dir ".")
(define (start2 get-ch id)
  (place/context aa
    (let loop ([success 0]
               [failure 0]
               [err 0])
      [define a (place-channel-get get-ch)]
      (if (equal? a 'over)
          (place-channel-put aa (list success failure err))
          (let ()
            (define results (run-test (list-ref unit-tests a)))
            (for/fold ([success success]
                       [failure failure]
                       [err err]
                       #:result (loop success failure err))
                      ([r (in-list results)])
              (display-test-result r)
              (cond
                [(test-success? r) (values (add1 success) failure err)]
                [(test-failure? r) (values success (add1 failure) err)]
                [else (values success failure (add1 err))])))))))

(define (prun2 p)
  (define-values (put-ch get-ch) (place-channel))
  (define n-workers p)
  (define workers (build-list n-workers (lambda (id) (start2 get-ch id))))
  (for/list ([(_ i) (in-indexed unit-tests)])
    (place-channel-put put-ch i))
  (for ([w (in-list workers)])
    (place-channel-put put-ch 'over))

  (for/fold ([success 0]
             [failure 0]
             [err 0]
             #:result (printf "~a success(es) ~a failure(s) ~a error(s) ~a test(s) run ~n"
                              success failure err (+ success failure err)))
            ([w (in-list workers)])
    (match-define (list s f e) (place-channel-get w))
    (values (+ s success)
            (+ f failure)
            (+ e err))))
(require racket/cmdline)
(module+ main
  (command-line #:args (p)
                (time (prun2 (string->number p)))))
