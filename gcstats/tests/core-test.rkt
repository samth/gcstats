#lang at-exp racket/base

(require recspecs
         recspecs/shell
         racket/runtime-path
         racket/format
         racket/string)

;; Test script that allocates memory to trigger GC
(define-runtime-path test-script "test-script.rkt")

(define cmd (~a "racket -l gcstats -t " test-script))

;; Helper to extract a number from a line matching a pattern
(define (extract-number pattern output)
  (define m (regexp-match pattern output))
  (and m (string->number (regexp-replace* #rx"," (cadr m) ""))))

;; Test that gcstats produces expected output format
;; We use recspecs-output-filter to normalize numeric values and whitespace
;; AND validate that key metrics are sane
(parameterize ([recspecs-output-filter
                (lambda (s)
                  ;; Validate numeric values before normalizing
                  (define allocated (extract-number #px"([0-9,]+) bytes allocated" s))
                  (define collected (extract-number #px"([0-9,]+) bytes collected" s))
                  (define max-heap (extract-number #px"([0-9,]+) bytes max heap" s))
                  (define gc-pct (extract-number #px"%GC time +([0-9.]+)" s))

                  (unless (and allocated (> allocated 0))
                    (error 'gcstats-test "bytes allocated should be positive, got ~a" allocated))
                  (unless (and collected (>= collected 0))
                    (error 'gcstats-test "bytes collected should be non-negative, got ~a" collected))
                  (unless (and max-heap (> max-heap 0))
                    (error 'gcstats-test "max heap should be positive, got ~a" max-heap))
                  (unless (and gc-pct (<= gc-pct 100))
                    (error 'gcstats-test "GC percentage should be <= 100, got ~a" gc-pct))

                  ;; Replace numbers (with optional commas/decimals) with #
                  (define no-nums (regexp-replace* #px"[0-9][0-9,]*\\.?[0-9]*" s "#"))
                  ;; Collapse multiple spaces to single space
                  (regexp-replace* #px" +" no-nums " "))])
  @expect/shell[cmd]{

 # bytes allocated in the heap
 # bytes collected by GC
 # bytes max heap size
 # bytes max slop
 # bytes peak total memory use

Generation #: # collections, #ms, #ms elapsed

INIT time # ms
MUT time # ms ( # ms elapsed)
GC time # ms ( # ms elapsed)
TOTAL time # ms ( # ms elapsed)

Max pause time: # ms
%GC time # % ( # % elapsed)

Alloc rate # bytes per MUT second

})
