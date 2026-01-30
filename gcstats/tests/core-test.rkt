#lang racket/base

(require rackunit
         racket/system
         racket/port
         racket/string)

;; Test that gcstats runs and produces expected output format
(define output
  (with-output-to-string
    (lambda ()
      (parameterize ([current-error-port (current-output-port)])
        ;; Run a simple program that allocates memory to trigger GC
        (system "racket -l gcstats -e '(for ([i 100000]) (cons i i))'")))))

;; Check that output contains expected sections
(check-true (string-contains? output "bytes allocated in the heap")
            "Output should contain allocation info")
(check-true (string-contains? output "bytes collected by GC")
            "Output should contain collection info")
(check-true (string-contains? output "bytes max heap size")
            "Output should contain max heap size")
(check-true (string-contains? output "INIT  time")
            "Output should contain init time")
(check-true (string-contains? output "MUT   time")
            "Output should contain mutator time")
(check-true (string-contains? output "GC    time")
            "Output should contain GC time")
(check-true (string-contains? output "TOTAL time")
            "Output should contain total time")
(check-true (string-contains? output "Alloc rate")
            "Output should contain allocation rate")
