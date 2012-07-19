(module main '#%kernel
  (define-values (initial-times)
    (cons (current-process-milliseconds) (current-inexact-milliseconds)))
  (define-values (buf) (box '()))
  (define-values (reciever) (make-log-receiver (current-logger) 'debug))
  (define-values (handler)
    (λ ()
      (letrec-values 
          ([(L) (λ ()
                  (define-values (v) (sync reciever))
                  (if (eq? 'gc-info (prefab-struct-key (vector-ref v 2)))
                      (set-box! buf (cons v (unbox buf)))
                      (void))
                  (L))])
        (L))))
  (thread handler)
  (executable-yield-handler
   (let-values ([(old-eyh) (executable-yield-handler)])
     (λ (v)
       ((dynamic-require 'gcstats/core 'continue) 
        buf initial-times 
        (cons (current-process-milliseconds) (current-inexact-milliseconds)))
       (old-eyh v)))))