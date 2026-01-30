#lang racket/base
;; Simple script that allocates memory to trigger GC
(for ([i 100000]) (cons i i))
