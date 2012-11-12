## Installation

### For Racket with Planet2

    % raco pkg install gcstats

### For Racket 5.3.1

    % git clone git://github.com/samth/gcstats.git
    % raco link gcstats
    % raco setup gcstats

## Running

    % racket -l gcstats normal-racket-arguments

For example:

    % racket -l gcstats -t "foo.rkt"

or

    % racket -l gcstats -l drracket

## Example Output

```
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

%GC time       16.02%   ( 16.32% elapsed)

Alloc rate     301,870,321 bytes per MUT second
```

### Line-by-line explanation

```
  2,715,625,408 bytes allocated in the heap
```

How many bytes, total, were allocated by the program

```
  2,687,494,428 bytes collected by GC
```

How many bytes, total, were collected during the run of the program

```
     73,728,640 bytes max heap size
```

The largest heap size observed at any GC

```
     66,748,764 bytes max slop
```

The largest difference between the memory allocated and the memory
  the GC has servered.

```
     85,884,928 bytes peak total memory use
```

The largest total memory use, including GC overhead.

```
Generation 0:     147 collections,    1,120ms, 1,157.53ms elapsed
```

How many nursery collections there were, and how long they took, in
  both process and elapsed time.

```
Generation 1:       6 collections,      596ms,   605.63ms elapsed
```

How many major collections there were, and how long they took, in
  both process and elapsed time.

```
INIT  time       260 ms
```

Time spent in the process prior to the logging happening.  This is primarily Racket startup time, and code loading time.

```
MUT   time     8,996 ms (  9,038.51 ms elapsed)
```

How much time the "mutator", i.e. your program, was running.

```
GC    time     1,716 ms (  1,763.16 ms elapsed)
```

How much time the GC took.

```
TOTAL time    10,972 ms ( 11,061.67 ms elapsed)
```

The total time from the initial invocation.

```
%GC time       16.02%   ( 16.32% elapsed)
```

What percentage of the time (after initialization) was spent in GC.

```
Alloc rate     301,870,321 bytes per MUT second
```

The average rate of allocation, not counting GC time.


###### Output formatting borrowed from GHC

