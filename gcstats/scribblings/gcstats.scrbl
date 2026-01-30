#lang scribble/manual

@title{gcstats: GC Statistics for Racket}
@author{Sam Tobin-Hochstadt}

The @tt{gcstats} package provides GC (garbage collection) statistics
for Racket programs, similar to GHC's @tt{+RTS -s} option.

@section{Usage}

To collect GC statistics for a Racket program, use:

@commandline{racket -l gcstats <normal-racket-arguments>}

For example:

@commandline{racket -l gcstats -t "foo.rkt"}

or

@commandline{racket -l gcstats -l drracket}

When the program exits, @tt{gcstats} prints a summary of GC activity
to standard output.

@section{Example Output}

@verbatim|{
  2,715,625,408 bytes allocated in the heap
  2,687,494,428 bytes collected by GC
     73,728,640 bytes max heap size
     66,748,764 bytes max slop
     85,884,928 bytes peak total memory use

Generation 0:     147 collections,    1,120ms, 1,157.53ms elapsed
Generation 1:       6 collections,      596ms,   605.63ms elapsed

INIT  time       260 ms
MUT   time     8,996 ms (  9,038.51 ms elapsed)
GC    time     1,716 ms (  1,763.16 ms elapsed)
TOTAL time    10,972 ms ( 11,061.67 ms elapsed)

Max pause time:     123 ms
%GC time       16.02 %   ( 16.32 % elapsed)

Alloc rate     301,870,321 bytes per MUT second
}|

@section{Output Explanation}

@subsection{Memory Statistics}

@itemlist[
  @item{@bold{bytes allocated in the heap} --- Total bytes allocated by the program.}
  @item{@bold{bytes collected by GC} --- Total bytes reclaimed during garbage collection.}
  @item{@bold{bytes max heap size} --- Largest heap size observed at any GC.}
  @item{@bold{bytes max slop} --- Largest difference between memory allocated and
        memory the GC has reserved.}
  @item{@bold{bytes peak total memory use} --- Largest total memory use, including
        GC overhead.}
]

@subsection{Collection Statistics}

@itemlist[
  @item{@bold{Generation 0} --- Nursery (minor) collections: count and time in both
        process and elapsed time.}
  @item{@bold{Generation 1} --- Major collections: count and time in both process
        and elapsed time.}
  @item{@bold{Incremental} --- Incremental collections (if any): count and time.
        This line only appears if incremental collections occurred.}
]

@subsection{Time Statistics}

@itemlist[
  @item{@bold{INIT time} --- Time spent before logging started, primarily Racket
        startup and code loading.}
  @item{@bold{MUT time} --- Time the ``mutator'' (your program) was running,
        excluding GC.}
  @item{@bold{GC time} --- Total time spent in garbage collection.}
  @item{@bold{TOTAL time} --- Total time from initial invocation.}
  @item{@bold{Max pause time} --- Longest individual GC pause.}
  @item{@bold{%GC time} --- Percentage of time (after initialization) spent in GC.}
  @item{@bold{Alloc rate} --- Average allocation rate in bytes per second of
        mutator time.}
]
