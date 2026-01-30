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
                  ;; Extract all numeric values
                  (define allocated (extract-number #px"([0-9,]+) bytes allocated" s))
                  (define collected (extract-number #px"([0-9,]+) bytes collected" s))
                  (define max-heap (extract-number #px"([0-9,]+) bytes max heap" s))
                  (define max-slop (extract-number #px"([0-9,]+) bytes max slop" s))
                  (define peak-mem (extract-number #px"([0-9,]+) bytes peak total" s))
                  (define gc-pct (extract-number #px"%GC time +([0-9.]+)" s))
                  (define alloc-rate (extract-number #px"Alloc rate +([0-9,]+)" s))

                  ;; Test script allocates 100k cons cells (~1.6MB minimum)
                  ;; Be conservative and check for at least 1MB
                  (unless (and allocated (> allocated 1000000))
                    (error 'gcstats-test "bytes allocated should be > 1MB, got ~a" allocated))

                  ;; Can't collect more than allocated
                  (unless (and collected (<= collected allocated))
                    (error 'gcstats-test "bytes collected (~a) should be <= allocated (~a)"
                           collected allocated))

                  ;; Max heap should be reasonable relative to allocation
                  (unless (and max-heap (> max-heap 0) (<= max-heap allocated))
                    (error 'gcstats-test "max heap (~a) should be > 0 and <= allocated (~a)"
                           max-heap allocated))

                  ;; Max slop should be non-negative and less than max heap
                  (unless (and max-slop (>= max-slop 0) (<= max-slop max-heap))
                    (error 'gcstats-test "max slop (~a) should be >= 0 and <= max heap (~a)"
                           max-slop max-heap))

                  ;; Peak memory should be at least max heap
                  (unless (and peak-mem (>= peak-mem max-heap))
                    (error 'gcstats-test "peak memory (~a) should be >= max heap (~a)"
                           peak-mem max-heap))

                  ;; GC percentage should be between 0 and 100
                  (unless (and gc-pct (>= gc-pct 0) (<= gc-pct 100))
                    (error 'gcstats-test "GC percentage should be 0-100, got ~a" gc-pct))

                  ;; Alloc rate should be positive
                  (unless (and alloc-rate (> alloc-rate 0))
                    (error 'gcstats-test "alloc rate should be positive, got ~a" alloc-rate))

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
