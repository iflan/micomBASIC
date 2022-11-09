# The Active Balls
#

# Flags for extracting pages from an image
DDFLAGS=oflag=append conv=notrunc,sync status=none

.PHONY: clean

clean:
	rm active_balls.hex active_balls_full.bin active_balls.bin

# These targets extract the data from the original AppleSoft BASIC for
# use by SourceGen.

active_balls.hex: loader.bas data2hex.awk
	awk -f data2hex.awk "$<" > "$@"

active_balls_full.bin: active_balls.hex hex2bin.awk
	rm -f "$@"
	LC_CTYPE=C awk -f hex2bin.awk < "$<" > "$@"

active_balls.bin: active_balls_full.bin
	rm -f "$@"
	dd $(DDFLAGS) if="$<" of="$@" bs=256 obs=256 skip=3 count=1
	dd $(DDFLAGS) if="$<" of="$@" bs=256 obs=256 skip=64 count=3
	dd $(DDFLAGS) if="$<" of="$@" bs=256 obs=256 skip=80 count=1
	dd $(DDFLAGS) if="$<" of="$@" bs=256 obs=256 skip=96 count=4

