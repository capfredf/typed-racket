#;#;
#<<END
TR opt: unboxed-let-functions8.rkt 2:64 (+ x 2.0+4.0i) -- unboxed binary float complex
TR opt: unboxed-let-functions8.rkt 2:67 x -- unbox float-complex
TR opt: unboxed-let-functions8.rkt 2:69 2.0+4.0i -- unboxed literal
END
#<<END
3.0+6.0i

END
#lang typed/scheme
#:optimize
#reader typed-racket-test/optimizer/reset-port

(letrec: ((f : (Float-Complex -> Float-Complex)     (lambda (x) (+ x 2.0+4.0i)))
          (g : (Float-Complex -> Float-Complex)     f)) ; f escapes! can't unbox its args
  (f 1.0+2.0i))
