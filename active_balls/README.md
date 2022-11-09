# The Active Balls

* Author: Shinji Minamiyama (南山 真爾)
* Publisher: micomBASIC (マイコン BASIC)
* Date: [1986-04,
  pp. 176-178](https://archive.org/details/micomBASIC-1986-04/page/176/mode/1up)
* Typed in by: @eientei on the applesaucefdc Discord server
* Translations: [Google Translate](http://translate.google.com)

## Overview

This is a basic arcade-style action game. The goal is to pop as many
of the "active balls" as possible without getting hit. The player
controls a "handbarrow"[^1] with a pointy spike pushed by two
people. If a ball hits the spike, it pops. If the ball hits a person,
the handbarrow is destroyed.

[^1]: A ["handbarrow"](https://en.wikipedia.org/wiki/Handbarrow) is a
      rectangular frame with poles at each end for being carried by
      two people. The sprite in the game is more like a
      ["handcar"](https://en.wikipedia.org/wiki/Handcar), though.

## How to Play

From the article:

> Use the `<` and `>` keys to move the handbarrow left and right to
> break the bouncing ball. Breaking as many balls as first appear will
> clear the stage ♥ (Bonus 200 points).

Every three stages, an extra ball is added, so on stage 4, 3 balls
need to be popped before progressing to the next stage. In every set
of 3 stages, the vertical acceleration of the balls can change,
causing them to bounce to a different height. This makes the game
quite challenging. (In fact, for me, the game is a bit too hard to
really be playable.)

### Running

In an emulator, boot to ProDOS, then add `active_balls.dsk` to a drive
and run:
```none
RUN LOADER
```

### Typing

To "type in" the code on an emulator:

0.  Ensure that you are booted in to DOS or ProDOS with
    `BASIC.SYSTEM`.
1.  Copy and paste `loader.bas` into the emulator. There are no spaces
    between the `REM`/`DATA` statements and what follows because
    AppleSoft stores what follows as bytes, including any white
    space. When listing, the `REM`/`DATA` statements will
    automatically have a space inserted afterwards. Therefore, if you
    enter a space during input, there will be _two spaces_.
2.  Save the program as `loader`:
    ```none
	SAVE LOADER
	```
3.  Copy and paste `bmain.bas` into the emulator.
4.  Save the program as `bmain`:
    ```none
	SAVE BMAIN
	```
5.  Run `loader.bas`:
    ```none
	RUN LOADER
	```

## BASIC

The BASIC portion of the program comes in two parts:

* `loader.bas`: Writes the machine language routines to memory.
* `bmain.bas`: Actual game.

The author includes some explanation of how the program works in the
article, which is really helpful. (It would have been more helpful if
I had read it before starting to try to disassemble the program. :-P)

### Machine language loader

`loader.bas` writes the machine language routines into memory. Because
this is a type-in, the author includes some rudimentary checksums to
try to catch any typing mistakes and localize them to a few lines of
`DATA` statements. This is surprisingly effective given the simplicity
of the checksum.

#### `10 - 90` Initialization and display setup

This section just clears the screen and writes `WAIT.....`, then
branches to the routine that reads the data at `3000`. Note that the
`POKE 770, 16` is important later, but not here. (It could actually be
omitted.)

#### `3000-3080` Data reader

This section is the main driver for the loader. It writes to the
following regions:

name       | start (dec) | start (hex) | length (hex) | length (dec)
-----------|-------------|-------------|--------------|--------------
zeros      |       24576 |        6000 |           80 |          128
characters |       24704 |        6080 |          340 |          832
display    |         784 |         310 |           5C |           92
tone       |         880 |         370 |            F |           15
handbarrow |       16384 |        4000 |           67 |          103
sounds     |       16487 |        4067 |           3F |           63
random     |       20480 |        5000 |            8 |            8
ball       |       16550 |        40A6 |          190 |          400

(The names of the regions are roughly taken from the table in the
article.)

*   `zeros`, the empty sprite, is written by line `3000`
*   `characters`, the handbarrow and balls, is written by line `3010`
*   `display`, the sprite drawing subroutine, is written by line
    `3020`
*   `tone`, the sound generation subroutine, is written by line `3030`
*   `handbarrow`, the handbarrow move subroutine, is written by line
    `3040`
*   `sounds`, these three routines are written by line `3050`
*   `random`, a subroutine to pick random numbers, is written by line
    `3060`
*   `ball`, the ball movement subroutine, is written by line `3070`

(I have no idea why it writes in this order.)

All of these machine language routines will be explored in detail.

#### `3500-3610` Data checker

This section of `loader.bas` expects the following:

*   `S` is the address at which to start writing data.
*   The next `DATA` statement will supply data for `S`.

In pseudo code, it works like:

```basic
    A = 0
    READ A$
	while A$ != '*'
	  POKE S, VAL(A$)
	  S++
	  A += VAL(A$)
	  READ A$
	READ I, A$
	if A == I
	  return
	else
	  PRINT "Data Error in "A$
	  end
```

As mentioned before, this is surprisingly effective.

## Game BASIC code

The game has the following sections:

* [setup](#setup) (lines 10-90, 980-1100)
* [game start](#game-start) (lines 900-970)
* [main loop](#main-loop) (lines 100-120)
* [death routine](#death-routine) (lines 130-260)
* [game over](#game-over) (lines 270-400)
* [pop routine](#pop-routine) (lines 410-440)
* [next stage](#next-stage) routine (lines 450-540)

### Setup

The setup code is responsible for:

*   initialization
*   initial game start animation

It starts on line 10:

```basic
10 GOSUB 980:POKE 770,16:LOMEM:28000
```

The `GOSUB 980` calls the random fill routine. This writes 256 bytes
of random integers in the range 0-26 at 20736 (`$5100`). These are
used later by the random routine at `$5000`. This routine also clears
the lo-res and high-res graphics screens.

Then `POKE 770,16` sets the height of all sprites. This is important
as it isn't set anywhere else (except in `loader.bas`).

`LOMEM:28000` sets the low memory mark for AppleSoft so it doesn't
clobber any of the machine language routines.

Line 20 sets up variables for the rest of the game:

```basic
20 A$="00001000011100001110101111101000":SC=0:B=3:R=1:F=0:GOSUB 1000
```

The global variables are:

*   `A$`: A pattern for making noise at the start of the game. See
    [lines 900-940](#game-start).
*   `SC`: Current score
*   `B`: Handbarrows left
*   `R`: Level
*   `F`: Balls popped this level

Other globals not initialized here:
*   `HS`: High score
*   `N`: Number of balls

The routine at 1000 shows the lo-res screen and then clears it with
snazzy window-shade style of animation.

The next section at line 30 sets up the machine language variables:

```basic
30 A=28672:FOR I=0 TO 7
40 POKE A+16+I,INT(RND(1)*37)
50 FOR L=3 TO 7 STEP 2
60 POKE A+L*16+I,0:NEXT:POKE A+16*9+I,1
70 POKE A+16*11+I,16-I*2:NEXT
80 POKE A+4,18:GOSUB 1020
90 GOSUB 900
```

Here `A` is the base address, 28672 (`$7000`). The `FOR I` loop sets
up various tables:

*   Line 40 gives each ball a random start X coordinate in the range
    0-36.
*   Lines 50-60 clear the Y coordinate, X velocity and Y velocity for
    each ball.
*   Line 60 also sets the Y acceleration for each ball to 1.
*   Line 70 sets the state of each ball in descending order. This
    causes the balls to appear at the top of the screen at different
    times.
*   Line 80 sets the start position for the handbarrow, then calls
    line 1020 to clear the graphics screen and print the scores.
	
Finally, line 90 calls the game start animation and setup.

Note that line 1060 is often called just to print the current score.


### Game start

This routine sets up the variables for the game and also makes some
noise.

Lines 900-940 are the noise makers:

```basic
900 FOR I=1 TO 32
910 ON VAL(MID$(A$,I,1)) GOTO 940
920 FOR L=0 TO 100:NEXT
930 NEXT:GOTO 950
940 CALL 16525:NEXT
```

Essentially, if there is a `1` in `A$` at `I`, then line 940 is
executed and it makes noise. Otherwise, it falls through to line 920
which just does a tight delay loop. Note that both line 940 and line
930 will go to line 950 when the `FOR I` loop finishes.

Lines 950-970 finish the setup for the current level:

```basic
950 L=INT((R-1)/3):N=L-INT (L/6)*6+2
960 L=R-1:I=L-INT(L/3)*3:IF I=2 THEN I=3
970 POKE A,N: POKE A+1,I: RETURN
```

In line 950, `L` is `floor((R-1)/3)`, which divides the levels into
batches of 3, with `L` being the current batch.

`N` is `L - (L mod 6) + 2`, which basically adds one ball every 3
levels. Note that at level 19, it drops back to 2. This prevents
having more than 7 balls at any time.

`I` is the number of possible accelerations for the balls (minus
one). On the first level of every batch of 3, there is only one
acceleration. On the second level of every batch, there are 2. On the
third there are 4.

The values of `N` and `I` are `POKE`d so the machine language routines
can access them.

### Main loop

The main loop is very simple:

```basic
100 CALL 16550:CALL 16384
110 IF NOT (PEEK(A+2) OR PEEK(A+3)) THEN 100
120 IF PEEK(A+3)>0 THEN 410
```

The first line calls the handbarrow move routine and the ball move
routine. It then checks the two end condition flags at `$7002`
(handbarrow hit) and `$7003` (ball popped). (Note that `A` is set on
line 30.) If both are zero, then it loops.

If `$7003` is set, then a ball was popped and control goes to the pop
routine. Otherwise, the handbarrow must have been destroyed, so
control falls through to the death routine.

### Death routine

The death routine has a couple of phases:

First, the handbarrow pushers dance a bit while the screen flickers
and there is noise. This is done with:

```basic
130 POKE 771,8:POKE 772,0:FOR I=0 TO 7
140 CALL 16525
150 GOSUB 240:NEXT
...
240 POKE -16298,0:J=I-INT(I/2)*2
250 POKE 773,98+J:CALL 784:POKE -16297,0
260 RETURN
```

The `POKE 771,8:POKE 772,0` sets part of the parameters for painting
the handbarrow sprite. In the routine at line 240, the
`J=I-INT(I/2)*2` causes `J` to be `I mod 2`. This feeds it no the
`POKE 773,98+J` which causes the handbarrow sprite to alternate
between the two versions. The `POKE -16298,0` and `POKE -16297,0`
cause the display to alternate between the hi-res screen and the
lo-res screen.

Second, there are three "skitter down" sounds as the handbarrow sprite
continues to dance, just more slowly:

```basic
160 FOR I=0 TO 2
170 FOR L=0 TO 45:NEXT:GOSUB 240
180 CALL 16506:NEXT:CALL 16525:POKE -16298,0
```

Next, there is a final drawing of the "dead" sprite with more noise
and a flicker:

```basic
180 CALL 16506:NEXT:CALL 16525:POKE -16298,0
190 POKE 772,128:POKE 773,98:CALL 784
200 POKE -16297,0:CALL 16525
```

Finally, there is a small delay and then the player continues or is
sent to the game over screen:

```basic
210 FOR I=0 TO 500:NEXT
220 B=B-1:IF B>0 THEN 30
230 GOTO 270
```

### Game over

The game over screen is pretty simple. Lines 270-290 just fill most of
the lo-res screen with gray using text printing which is faster than
lo-res line drawing.

Next, "GAME OVER" is printed in a similar manner. It's pretty clever.

Finally, the game waits for a key press while very quickly switching
between lo-res and hi-res, giving an interesting scroll effect on real
hardware. (On emulators, it doesn't work as well.)

```basic
370 FOR I=0 TO 30:POKE 49238,0:POKE 49239,0
375 :::::
380 NEXT
390 IF PEEK(49152)<>160 THEN 370
400 POKE 34,20: GOTO 20
```

Note that the number of colons on line 375 changes the effect because
it changes the timing of the flickering.

### Pop routine

Called `explode` in the source, this is a very simple routine that
just takes the number of balls popped and multiplies it by 10 and adds
it to the score.

If the level is cleared (`F >= N`), then it falls through to clear the
stage. Otherwise it goes back to the main loop.

### Next stage

This routine does a bit of clearing animation. It's not really worth
explaining because it's fairly straight forward.

Note that the player always gets 200 points for clearing the level.

## Machine Language

### Building a binary dump

For some reason, the author decided to put code in many different
parts of memory in many different fragments.  This makes disassembly
difficult because SourceGen wants one file.

The `data2hex.awk` script parses the `loader.bas` BASIC file and
creates a hex dump of the different regions in `active_balls.hex`. The
`hex2bin.awk` script turns that hex dump into binary.

All of this is nicely automated with the `Makefile`:

```shell
$ make active_balls.bin
```

After getting the binary dump, SourceGen is happy and we can actually
set the correct address for each segment.

### SourceGen disassembly

The author was kind enough to give the locations and names of some of
the machine language routines. I have tried to preserve them as much
as possible.

### Sprites

All the sprites in the game are drawn on byte boundaries, which makes
it very easy. This is why all of the X coordinates are given in
"columns"—they are not hi-res pixels.

The blank space at `SPRITE_BLANK` is used to erase both the handbarrow
and the balls, but usually just one column.

There's a "hidden" sprite at `$6380` which looks a bit like an
octopus. It's not used in the game, as far as I can tell.

The `DRAW_SPRITE` routine is similar to the `HPOSN` routine, but it
has been simplified. There are actually faster routines out there,
notably one by Woz, but they don't matter for this game.


### Sound

The `BUZZ` routine is used to great effect from both machine language
and from BASIC. I am especially impressed with how well the `NOISE`
routine makes use of code-as-data to generate a crackly sound.
