#lang racket/base
(require rackunit rackunit/text-ui racket/list racket/match racket/place)

(require "typecheck-tests.rkt")
;; (require (submod "typecheck-tests.rkt" cross-phase-failure)
;;          (submod "typecheck-tests.rkt" custom-ret)
;;          (submod "typecheck-tests.rkt" tester))

(define total (length all-tests))
(define workload (make-parameter #f))
(define n-workers (make-parameter #f))

(define (safe-take lst pos)
  (cond
    [(null? lst) lst]
    [(>= (length lst) pos) (take lst pos)]
    [else lst]))

(define (safe-drop lst pos)
  (cond
    [(null? lst) lst]
    [(>= (length lst) pos) (drop lst pos)]
    [else null]))

;; (define all-tests (list (make-test-suite "hello" (test-eq? "EQ" 'a 'a))))

(define (start get-ch id workload)
  (place/context aa
    ;;(eprintf "aa ~a ~n" (place-channel-get aa))
    (let loop ()
      [define a (place-channel-get get-ch)]
      (if (equal? a 'over) #t
          (begin (run-test (make-test-suite "hi" (safe-take (safe-drop all-tests (* a workload)) workload)))
                 (loop))))))


(define (prun)
  (define-values (put-ch get-ch) (place-channel))

  (define workers (build-list (n-workers) (lambda n (start get-ch n (workload)))))
  (eprintf "....~a ~n" 10)
  (for/list ([i (in-range (n-workers))])
    (place-channel-put put-ch i))
  (eprintf "....~a ~n" 42)
  (for ([w (in-list workers)])
    (place-channel-put put-ch 'over))
  (eprintf "....~a ~n" 24)
  (for ([w (in-list workers)])
    (place-wait w)))

(require racket/cmdline)
(module+ main
  (command-line #:args (wl)
                (workload (string->number wl))
                (n-workers (ceiling (/ total (workload)))))
  (time (prun)))
