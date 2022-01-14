#lang racket/base
(require rackunit rackunit/text-ui racket/place racket/list syntax/location)

(require (only-in "typecheck-tests.rkt" [tests tt:tests])
         (only-in "subtype-tests.rkt" [tests st:tests]))

;; (define total (length tt:tests))
;; (define workload 300)
;; (define n-workers (ceiling (/ total workload)))

(define (safe-take lst pos)
  (cond
    [(null? lst) lst]
    [(>= (length lst) pos) (take lst pos)]
    [else null]))

(define (safe-drop lst pos)
  (cond
    [(null? lst) lst]
    [(>= (length lst) pos) (drop lst pos)]
    [else null]))

;; (define all-tests (list (make-test-suite "hello" (test-eq? "EQ" 'a 'a))))
#;
(define (start get-ch id)
  (place/context aa
    ;;(eprintf "aa ~a ~n" (place-channel-get aa))
    (let loop ()
      [define a (place-channel-get get-ch)]
      (if (equal? a 'over) #t
          (begin (run-test (make-test-suite "hi" (safe-take (safe-drop all-tests (* a workload)) workload)))
                 (loop))))))

(require racket/runtime-path)

(define-runtime-path src-dir ".")
(define (start2 get-ch id)
  (place/context aa
    ;;(eprintf "aa ~a ~n" (place-channel-get aa))
    (let loop ()
      [define a (place-channel-get get-ch)]
      (if (equal? a 'over) #t
          (begin (run-tests (dynamic-require (build-path src-dir a) 'tests))
                 (loop))))))
#;
(define (prun)
  (define-values (put-ch get-ch) (place-channel))

  (define workers (build-list n-workers (lambda n (start get-ch n))))
  (eprintf "....~a ~n" 10)
  (for/list ([i (in-range n-workers)])
    (place-channel-put put-ch i))
  (eprintf "....~a ~n" 42)
  (for ([w (in-list workers)])
    (place-channel-put put-ch 'over))
  (eprintf "....~a ~n" 24)
  (for ([w (in-list workers)])
    (place-wait w)))

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
                    "type-constr-tests.rkt"))
(define (prun2)
  (define-values (put-ch get-ch) (place-channel))
  (define n-workers 16)
  (define workers (build-list n-workers (lambda n (start2 get-ch n))))
  (eprintf "....~a ~n" 10)
  (for/list ([i (in-list unit-tests)])
    (place-channel-put put-ch i))
  (eprintf "....~a ~n" 42)
  (for ([w (in-list workers)])
    (place-channel-put put-ch 'over))
  (eprintf "....~a ~n" 24)
  (for ([w (in-list workers)])
    (place-wait w)))
(module+ main
  (time (prun2)))
