; Target assembler: cc65 v2.19.0 [--target apple2 -C maze_cc65.cfg]
;
; Graphic Maze
; 
; This is a disassembly of the machine language routines POKEd into memory by
; the AppleSoft BASIC program in the listing.
; 
; How it works:
; 
; The basic idea is pretty simple. Imagine a grid of cells that have four walls,
; one in each direction.
; 
;   0. Start in some cell.
;   1. Pick a random direction, D.
;   2. If the cell in direction D has been visited, go to step 1.
;   3. Create a path to the cell in direction D.
;   4. Move to the cell in direction D.
;   5. Go to step 1.
; 
; This simple algorithm won’t actually work because eventually the path will
; curl on itself and get stuck because all cells in all directions have been
; visited without guaranteeing that the whole maze is full. To get around that,
; when the program gets stuck, it starts back at step 0 with a new starting
; point. That starting point is always the “next” cell in the grid, starting
; with the column. So, the first time it is (0,0), then (0,1), etc. This is
; guaranteed to fill the maze.
; 
; The program also has a few tricks to make things work out nicely:
; 
; First, each cell is actually 2 x 2 pixels so that the walls are visible.
; 
; Second, it looks at pixel values on the HGR2 screen to see if a cell has been
; visited. A black pixel has been visited, a white pixel has not.
; 
; Third, the BASIC program paints a rectangle on the screen, starting at (1,1),
; where the height and width are an odd number of pixels. The offset means that
; the rectangle is entirely surrounded by black pixels. If these are probed, the
; program will see them as visited. This keeps the maze from wandering out of
; the rectangle.
; 
; Fourth, instead of picking a direction at random, the program keeps a list of
; the possible directions and walks through that list to see which direction it
; can go. When it runs out of directions, it knows it’s time to start at step 0
; again. The direction list is shuffled every time it starts in a new cell. (The
; list is not shuffled very well, though.)
; 
; The BASIC program also sets the upper-left pixel to black to mark it as
; visited.
; 
; The most annoying thing about this program, though, is that the starting
; address is $B000. This causes it to clobber DOS 3.3. In ProDOS, it clobbers
; the BASIC Interpreter, which is very annoying.
; 
; The entry point from BASIC is $B020.
         .setcpu "65C02"
PATHDIR_IDX =    $05             ;Current offset into the PATHDIR array
RND_TEMP =       $06             ;Also storage for a RND result
BAS_HBASL =      $26             ;base address for hi-res drawing (lo part)
BAS_HMASK =      $30             ;hi-res graphics on-the-fly bit mask
MON_A1H  =       $3d             ;general purpose
BAS_FAC  =       $9d             ;floating point accumulator (6b)
PROBE_X  =       $0300           ;Cell probed to see if it is visited
PROBE_Y  =       $0302
CELL_X   =       $0303           ;Current cell from which probes are sent
CELL_Y   =       $0305
STARTCELL_X =    $0306           ;Used to see if CELL has changed
STARTCELL_Y =    $0308
CUR_X    =       $0309           ;Current grid cell from which CELL is initialized
CUR_Y    =       $030b
MAZE_WIDTH =     $030c           ;Width of the maze on the screen
MAZE_HEIGHT =    $030e           ;Height of the maze on the screen
PATHDIRS =       $0310           ;Array of possible path directions
BAS_RND  =       $efae           ;generate random number
BAS_HPOSN =      $f411           ;set hi-res position; horiz=(Y,X) vert=A
BAS_HPLOT0 =     $f457           ;plot point; horiz=(Y,X), vert=A
BAS_HPLOT2HK =   $f715           ;Hacky way of doing HPLOT TO that relies on the next BASIC instruction not being a TO token

         .org    $2000           ;Original started at $B000, but that was annoying
; INIT
INIT:    jsr     __randomize

; NEXT_PATH is the entry point from BASIC. It assumes that:
; 
; * The HGR2 screen is filled with a white rectangle with one black pixel at
; 2,2.
; * The PATHDIRS array is initialized with 0, 1, 2, 3 representing directions:
;   0: Y = Y - 2
;   1: X = X + 2
;   2: Y = Y + 2
;   3: X = X - 2
; * CUR_X = 2
; * CUR_Y = 2
; * CELL_X = 2
; * CELL_Y = 2
; * MAZE_WIDTH = width of maze * 2
; * MAZE_HEIGHT = height of maze * 2 
; 
; This returns when the maze is drawn.
NEXT_PATH:
         jsr     SHUFFLE         ;Shuffle the dir array
         ldx     #$02            ;Save CELL in STARTCELL
@nextcpy1:
         lda     CELL_X,x
         sta     STARTCELL_X,x
         dex
         bpl     @nextcpy1
         lda     #$00            ;Start at the beginning of the PATHDIRS array
         sta     PATHDIR_IDX
NEXT_DIR:
         ldx     #$02            ;Copy CELL to PROBE
@nextprobe:
         lda     CELL_X,x
         sta     PROBE_X,x
         dex
         bpl     @nextprobe
; Choose maze direction based on current index into PATHDIRS array
         ldx     PATHDIR_IDX
         lda     PATHDIRS,x
         bne     @chk1
         dec     PROBE_Y         ;On 0, Y = Y - 2
         dec     PROBE_Y
         jmp     @cont

@chk1:   cmp     #$01            ;On 1, X = X + 2 (two byte addition)
         bne     @chk2
         clc
         lda     PROBE_X
         adc     #$02
         sta     PROBE_X
         lda     PROBE_X+1
         adc     #$00
         sta     PROBE_X+1
         jmp     @cont

@chk2:   cmp     #$02            ;On 2, Y = Y + 2
         bne     @chk3
         inc     PROBE_Y
         inc     PROBE_Y
         jmp     @cont

@chk3:   sec                     ;On 3, X = X - 2 (two byte subtraction)
         lda     PROBE_X
         sbc     #$02
         sta     PROBE_X
         lda     PROBE_X+1
         sbc     #$00
         sta     PROBE_X+1
@cont:   ldx     PROBE_X         ;Check if pixel at PROBE_X, PROBE_Y is set
         ldy     PROBE_X+1
         lda     PROBE_Y
         jsr     CHECKXY
         lda     MON_A1H
         bne     DRAWPATH        ;If set...
         jmp     TRY_NEXT_DIR    ;Otherwise...

DRAWPATH:
         ldx     CELL_X
         ldy     CELL_X+1
         lda     CELL_Y
         jsr     BAS_HPLOT0      ;Start plotting at CELL_X, CELL_Y
         ldx     PROBE_X
         ldy     PROBE_X+1
         lda     PROBE_Y
         jsr     BAS_HPLOT2HK    ;Plot to PROBE_X, PROBE_Y
         ldx     #$02            ;Copy PROBE to CELL
@nextorig:
         lda     PROBE_X,x
         sta     CELL_X,x
         dex
         bpl     @nextorig
         jmp     NEXT_PATH

TRY_NEXT_DIR:
         inc     PATHDIR_IDX
         lda     PATHDIR_IDX
         cmp     #$04            ;Exhausted all directions?
         beq     CHECK_MOVED
         jmp     NEXT_DIR

CHECK_MOVED:
         lda     CELL_Y          ;Are we still in the same row?
         cmp     STARTCELL_Y
         beq     @check_x
@do_next_path:
         jmp     NEXT_PATH       ;No? Shuffle directions and start again.

@check_x:
         lda     STARTCELL_X     ;Are we still in the same column?
         cmp     CELL_X
         bne     @do_next_path   ;No? Shuffle and start again.
         lda     STARTCELL_X+1
         cmp     CELL_X+1
         bne     @do_next_path   ;No? Shuffle and start again.
         nop                     ;Bodge job?
         nop
         nop
NEXT_START:
         inc     CUR_Y           ;Increment Y
         inc     CUR_Y
         lda     MAZE_HEIGHT
         cmp     CUR_Y           ;Are we done with the column?
         bcs     chk_visited
         lda     #$02            ;Yes, start back at row 2...
         sta     CUR_Y
         clc                     ;...and move to next column (2 byte addition)
         lda     CUR_X
         adc     #$02
         sta     CUR_X
         lda     CUR_X+1
         adc     #$00
         sta     CUR_X+1
         lda     MAZE_WIDTH+1    ;Are we done with all columns?
         cmp     CUR_X+1         ;Compare high byte
         bcs     check_equal     ;If MAZE_WIDTH+1 >= CURX+1
RETURN:  rts

check_equal:
         bne     chk_visited     ;If MAZE_WITH+1 != CURX+1
         lda     MAZE_WIDTH      ;Need to check the low byte
         cmp     CUR_X
         bcc     RETURN
chk_visited:
         ldx     CUR_X           ;Check if CURX, CURY is visited
         ldy     CUR_X+1
         lda     CUR_Y
         jsr     CHECKXY
         lda     MON_A1H
         beq     @copy           ;If it's visited, start again at CURX, CURY
         jmp     NEXT_START      ;Otherwise, try another starting cell

@copy:   ldx     #$02            ;Copy CUR to ORIG
@nextorig:
         lda     CUR_X,x
         sta     CELL_X,x
         dex
         bpl     @nextorig
         jmp     NEXT_PATH

SHUFFLE:
         ldy     #$00            ;Signal we have no random bits
         jsr     RND2BITS
         beq     @swap1          ;If it is zero, it's a no-op
         tax                     ;Otherwise, use it as an index
         lda     PATHDIRS        ; and swap with first element
         pha                     ; of the array
         lda     PATHDIRS,x
         sta     PATHDIRS
         pla
         sta     PATHDIRS,x
@swap1:  jsr     RND2BITS        ;Get two more bits
         beq     @swap2          ;If it is zero, it's a no-op
         cmp     #$03            ;If it's 3, we have to try again.
         beq     @swap1
         tax
         lda     PATHDIRS+1      ;Swap bytes in PATHDIRS+1 and PATHDIRS+1,X
         pha
         lda     PATHDIRS+1,x
         sta     PATHDIRS+1
         pla
         sta     PATHDIRS+1,x
@swap2:  jsr     RND2BITS
         and     #%00000001
         beq     @return
         lda     PATHDIRS+2
         ldx     PATHDIRS+3
         sta     PATHDIRS+3
         stx     PATHDIRS+2
@return: rts

;RND2BITS returns two random bits in the bottom 2 bits of the accumulator.
;On entry, Y needs to have the number of bits left (0 on the first call).
;
;A: bottom two bits are a random number 0-3
;Y: number of random bits left + 2
RND2BITS:
         cpy     #$02            ;If there are less than two bits left
         bcc     @getrnd         ;Get some more
         dey                     ;Y = Y - 2
         dey
         lda     RND_TEMP        ;Shift the random number right
         lsr
         lsr
@store:  sta     RND_TEMP        ;Save it for next time
         and     #%00000011      ;Mask out all but the lower bits
         rts
@getrnd:
         jsr     RANDOM          ;Generate a random byte
         ldy     #$08            ;We have 8 usable bits
         bne     @store          ;Always taken

; CHECKXY checks whether a given pixel on the screen is on or off. If it is off,
; then $00 is stored in MON_A1H, otherwise $01 is stored in MON_A1H.
; 
; All registers are destroyed.
CHECKXY: jsr     BAS_HPOSN
         lda     (BAS_HBASL),y   ;Load screen byte for given X,Y position
         and     #$7f            ;Clear color palette bit
         and     BAS_HMASK       ;Mask out all but bit for X position
         beq     @save           ;Return 0 in MON_A1H
         lda     #$01            ;Return 1 in MON_A1H
@save:   sta     MON_A1H
         rts

; RANDOM returns a random byte. It calls the AppleSoft RND function, then mixes
; two of the resulting bytes, finally returning the byte in the A register.
; 
; A: random number 0 - 255
RANDOM:  jmp     _rand

         .import _rand,__randomize