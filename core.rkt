#lang s-exp racket/private/base

(struct gc-info (major? pre-amount pre-admin-amount code-amount
                 post-amount post-admin-amount
                 start-process-time end-process-time
                 start-time end-time)
  #:prefab)

(define initial-times #f)

(define (add-commas str)
  (regexp-replace* #px"([[:digit:]]+)([[:digit:]]{3})" str
                  (λ (all one two)
                    (string-append (add-commas one) "," two))))

(define (pad s n)
  (define l (string-length s))
  (cond [(= l n) s]
        [(< n l) (substring s 0 n)]
        [else (string-append (make-string (- n l) #\space) s)]))

(define (->string n [k 8])
  (define s
    (if (exact? n)
        (number->string n)
        (real->decimal-string n)))
  (if k
      (pad (add-commas s) k)
      (add-commas s)))

(define (summarize results end-proc-time end-time)
  (define gc-results (for*/list ([e (in-list results)]
                                 [v (in-value (vector-ref e 2))]
                                 #:when (gc-info? v))
                       v))
  (unless (pair? gc-results)
    (error "no results"))
  
  (define num-major (for/sum ([e gc-results] #:when (gc-info-major? e)) 1))
  (define num-minor (for/sum ([e gc-results] #:unless (gc-info-major? e)) 1))
  
  (define allocated (+ 
                     (gc-info-pre-amount (car gc-results))
                     (for/sum ([i (in-list gc-results)]
                               [j (in-list (cdr gc-results))])
                       (- ;; total heap size here
                          (gc-info-pre-amount j)
                          ;; size of heap after last collection
                          (gc-info-post-amount i)))))
  
  (define collected (for/sum ([i (in-list gc-results)])
                             (- (gc-info-pre-amount i)
                                (gc-info-post-amount i))))
  
  (define max-heap-size
    (apply max (for/list ([i gc-results]) (gc-info-pre-amount i))))
  (define max-used
    (apply max (for/list ([i gc-results]) 
                 (+ (gc-info-pre-admin-amount i)
                    (gc-info-code-amount i)))))
  (define max-slop 
    (apply max (for/list ([i gc-results]) 
                 (max
                  (- (gc-info-pre-admin-amount i)
                     (gc-info-pre-amount i))
                  (- (gc-info-post-admin-amount i)
                     (gc-info-post-amount i))))))
  (define startup-time (car initial-times))
  (define total-time (- end-proc-time startup-time))
  (define total-elapsed-time (- end-time (cdr initial-times)))
  
  (define minor-gc-time
    (for/sum ([i (in-list gc-results)] #:unless (gc-info-major? i))
      (- (gc-info-end-process-time i) (gc-info-start-process-time i))))
  (define minor-gc-elapsed-time 
    (for/sum ([i (in-list gc-results)] #:unless (gc-info-major? i))
      (- (gc-info-end-time i) (gc-info-start-time i))))
  
  (define major-gc-time 
    (for/sum ([i (in-list gc-results)] #:when (gc-info-major? i))
      (- (gc-info-end-process-time i) (gc-info-start-process-time i))))
  (define major-gc-elapsed-time
    (for/sum ([i (in-list gc-results)] #:when (gc-info-major? i))
      (- (gc-info-end-time i) (gc-info-start-time i))))
  
  (define gc-time (+ minor-gc-time major-gc-time))
  (define gc-elapsed-time (+ minor-gc-elapsed-time major-gc-elapsed-time))
  
  (define mut-time (- total-time gc-time))
  (define mut-elapsed-time (- total-elapsed-time gc-elapsed-time))
  
  (define gc% (* 100. (/ gc-time total-time)))
  (define gc-elapsed% (* 100. (/ gc-elapsed-time total-elapsed-time)))
  
  (define alloc-rate (* 1000. #|time in ms|# (/ allocated mut-time)))
  
  (string-append
   (format "~a bytes allocated in the heap\n" (->string allocated 15))
   (format "~a bytes collected by GC\n" (->string collected 15))
   (format "~a bytes max heap size\n" (->string max-heap-size 15))
   (format "~a bytes max slop\n" (->string max-slop 15))
   (format "~a bytes peak total memory use\n" (->string max-used 15))
   "\n"
   (format "Generation 0:~a collections, ~ams, ~ams elapsed\n"
           (->string num-minor) (->string minor-gc-time) 
           (->string minor-gc-elapsed-time))
   (format "Generation 1:~a collections, ~ams, ~ams elapsed\n"
           (->string num-major) (->string major-gc-time) 
           (->string major-gc-elapsed-time))
   "\n"
   (format "INIT  time~a ms\n"
           (->string startup-time 10))
   (format "MUT   time~a ms (~a ms elapsed)\n"
           (->string mut-time 10) 
           (->string mut-elapsed-time 10))
   (format "GC    time~a ms (~a ms elapsed)\n"
           (->string gc-time 10) (->string gc-elapsed-time 10))
   (format "TOTAL time~a ms (~a ms elapsed)\n"
           (->string (+ startup-time total-time) 10)
           (->string (+ startup-time total-elapsed-time) 10))
   "\n"
   (format "%GC time  ~a%   (~a% elapsed)\n"
           (->string gc% 10) (->string gc-elapsed% 6))
   "\n"
   (format "Alloc rate     ~a bytes per MUT second\n"
           (add-commas (number->string (inexact->exact (round alloc-rate)))))))

(define (continue buf times new-times)
  (set! initial-times times)  
  (define results (unbox buf))
  (cond [(null? results)
         (printf "No GC results available\n")]
        [else
         (newline) (newline)
         (display (summarize results (car new-times) (cdr new-times)))]))

(provide continue)
