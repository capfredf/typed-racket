#lang racket/base
(require racket/match rackunit rackunit/text-ui racket/place racket/list syntax/location
         rackunit/private/format)

(require (only-in "typecheck-tests.rkt" [tests tt:tests])
         (only-in "subtype-tests.rkt" [tests st:tests]))


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
            (define results (run-test (dynamic-require (build-path src-dir a) 'tests)))
            (for/fold ([success success]
                       [failure failure]
                       [err err]
                       #:result (loop success failure err))
                      ([r (in-list results)])
              (display-test-result r #:suite-names (list (path->string (build-path src-dir a))))
              (cond
                [(test-success? r) (values (add1 success) failure err)]
                [(test-failure? r) (values success (add1 failure) err)]
                [else (values success failure (add1 err))])))))))

(define unit-tests (list
                    "typecheck-tests.rkt"
                    "subtype-tests.rkt"
                    "type-equal-tests.rkt"
                    "remove-intersect-tests.rkt"
                    "static-contract-conversion-tests.rkt"
                    "static-contract-instantiate-tests.rkt"
                    "static-contract-optimizer-tests.rkt"
                    "parse-type-tests.rkt"
                    "subst-tests.rkt"
                    "infer-tests.rkt"
                    "keyword-expansion-test.rkt"
                    "special-env-typecheck-tests.rkt"
                    "contract-tests.rkt"
                    "interactive-tests.rkt"
                    "type-printer-tests.rkt"
                    "type-alias-helper.rkt"
                    "class-tests.rkt"
                    "class-util-tests.rkt"
                    "check-below-tests.rkt"
                    "init-env-tests.rkt"
                    "prop-tests.rkt"
                    "metafunction-tests.rkt"
                    "generalize-tests.rkt"
                    "prims-tests.rkt"
                    "tooltip-tests.rkt"
                    "prefab-tests.rkt"
                    "json-tests.rkt"
                    "typed-units-tests.rkt"
                    "type-constr-tests.rkt"
                    ))
(define (prun2 p)
  (define-values (put-ch get-ch) (place-channel))
  (define n-workers p)
  (define workers (build-list n-workers (lambda (id) (start2 get-ch id))))
  (for/list ([i (in-list unit-tests)])
    (place-channel-put put-ch i))
  (for ([w (in-list workers)])
    (place-channel-put put-ch 'over))

  (for/fold ([success 0]
             [failure 0]
             [err 0]
             #:result (printf "success (~a), failure (~a), errror (~a)~n" success failure err))
            ([w (in-list workers)])
    (match-define (list s f e) (place-channel-get w))
    (values (+ s success)
            (+ f failure)
            (+ e err))))
(require racket/cmdline)
(module+ main
  (command-line #:args (p)
                (time (prun2 (string->number p)))))
