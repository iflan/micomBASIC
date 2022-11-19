# Graphic Maze

* Author: Kida Kazushige (木田 和重)
* Publisher: micomBASIC (マイコン BASIC)
* Date: [1985-01,
  p. 152](https://archive.org/details/micomBASIC-1985-01/page/152/mode/1up)
* Typed in by: @eientei on the applesaucefdc Discord server
* Translations: [Google Translate](http://translate.google.com)

## Overview

From the author:

> This is a ported version of "GRAPHIC MAZE" for the PC-6001 in the
> February 1983 issue. However, just porting it would be boring, so I
> rewrote the main routine in machine language.  As a result, what
> used to take up to 3 hours can now be completed within 5 minutes.

The program draws a maze on the hires screen. Pressing `SPACE` when
the maze is complete returns to the text screen and allows you to make
another maze.

## Running

There are two versions of the program:

*   The [original version](#original-version), directly from the
    magazine.
*   An [optimized version](#optimized-version) created by
    disassembling the original and optimizing some of the routines.

### Original version

Boot the `maze.dsk` disk image in your favorite emulator; the program
will start automatically.

The original version of the source is in `maze.bas`.

### Optimized version

Boot the `fastmaze.dsk` disk image in your favorite emulator; the
program will start automatically.

Building the optimized version requires `make`, `awk`, `sed`,
`hexdump`, and the [CC65 development tools](https://cc65.github.io/).
Once you have these, it should be as easy as:

```shell
make fastmaze.bas
```

The output will be in `fastmaze.bas` which can then be copy-pasted
into the emulator of your choice.  The assembly language routines are
in `fastmaze.s`.

## Disassembly

The disassembly was created with [SourceGen] by Andy McFadden from
6502bench.com. I found that it made disassembly easier overall, even
though it crashed all the time when running it under Wine.

[SourceGen]: https://github.com/fadden/6502bench/

To view the original disassembly:

*   Run:

    ```shell
    make maze.bin
    ```
    
*  Open `maze.bin.dis65` in SourceGen.

The disassembled code is interesting to look at and to try to
understand.

## Improvements

The current code is much faster than the original because it does not
rely on the [BASIC `RND` function], which is pretty slow (and not very
random[^1]). Instead, it uses cc65's `_rand` which is based on a [linear
congruential generator] that is much, much faster. This version runs
about twice as fast as the original.

There are several other optimizations that could be made, including:

*   Optimized X,Y address calculation (instead of using
    `HPOSN`). There are at least two methods for this:
    *   Table-based lookups.
    *   Woz's [1983 version](http://www.txbobsc.com/aal/1986/aal8612.html#a9).
*   Better register use.
    *   `CHECKXY` should just return the result in the `A` register.
    *   `_rand` just messes with `A` and `X`.
    *   `RND2BITS` could probably be improved or removed.
*   It's only necessary to shuffle the number of patterns used.

[BASIC `RND` function]: https://6502disassembly.com/a2-rom/Applesoft.html#SymRND
[`HPOSN`]: https://6502disassembly.com/a2-rom/Applesoft.html#SymHPOSN
[linear congruential generator]: https://en.wikipedia.org/wiki/Linear_congruential_generator
[^1]: There are several issues, it turns out.  See [Aldridge,
    J.W. Cautions regarding random number generation on the Apple
    II. _Behavior Research Methods, Instruments, & Computers_ **19**,
    397–399 (1987)](https://doi.org/10.3758/BF03202585) and [Modianos,
    D. T., Scott, R. C., & Cornwell, L. W. (1984). Random Number
    Generation on Microcomputers. Interfaces, **14(4)**,
    81–87](http://www.jstor.org/stable/25060592).

