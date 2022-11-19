# Makefile for graphic maze
#

# Setup for the cc65 compiler, assembler, and linker
#
CC65SYS = apple2
CC = cc65
AS = ca65
ASFLAGS = --target $(CC65SYS)
LD = ld65
LDFLAGS = -v

# Flags for extracting pages from an image
DDFLAGS=conv=notrunc,sync status=none

.PHONY: clean mazep

clean:
	$(RM) *.o maze.hex *.bin fastmaze.bas

# Convert the DATA statements in maze.bas to a hex dump.
maze.hex: maze.bas data2hex.awk
	awk -f data2hex.awk "$<" > "$@"

# Converts the hex dump to binary, putting the binary values at the
# starting offset in the file.  (This allows us to extract binary data
# from multiple locations in memory, if necessary, to create the final
# image for SourceGen.)  LC_CTYPE=C is a hack to ensure that bytes are
# printed, not UTF-8 or something else.
maze_full.bin: maze.hex hex2bin.awk
	LC_CTYPE=C awk -f hex2bin.awk < "$<" > "$@"

# Extract two pages at $B000 to make maze.bin
maze.bin: maze_full.bin
	dd $(DDFLAGS) if="$<" of="$@" bs=256 skip=$$((16#B0)) count=2

fastmaze.bin: fastmaze.o fastmaze.cfg
	$(LD) $(LDFLAGS) --config fastmaze.cfg --start-addr 8192 -o "$@" "$<" c64.lib apple2.lib

# Print the maze binary in a way that can be copy/pasted
# into the memory inspector in Virtual ][.
mazep: fastmaze.bin
	hexdump -e '16/1 "%02x " "\n"' fastmaze.bin

fastmaze.bas: fastmaze.bin maze.bas 
	hexdump -e '"DATA " 7/1 "%u," 1/1 "%u" "\n"' "$<" \
	  | awk 'BEGIN { line=1000 } \
		/ A *= *[[:digit:]]+$$/ { \
			match($$0, /= *[[:digit:]]+/); \
			$$0 = substr($$0, 1, RSTART) " 8192" } \
		/CALL 45088/ { sub(/45088/, "8192+32") } \
		/^[[:digit:]]+ *DATA/ { $$0 = "" } \
		/^DATA/ { print line, $$0; line+=10 } \
		!/^DATA/ && !/HIMEM/ && !/^$$/ { print $$0 } \
		END { print line, "DATA -1" }' maze.bas - \
		| sed -e 's/,,,*//' > "$@"
