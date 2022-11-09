# Converts a hex dump to a binary image
#
# This script takes the output of data2hex.awk and creates a binary
# image with the given bytes at their appropriate locations. The file
# must have the lines in order and the data in the lines cannot
# overlap.
#

BEGIN {
    addr = 0
}

# Matches the address at the start of a line
#
#     ABCD:
/^[[:xdigit:]]+:/ {
    where = match($0, /^([[:xdigit:]]+):(.*)/, parts)
    if (where != 0) {
	start = strtonum("0x" parts[1])
	if (start < addr) {
	    printf("%04X < %04X: start < addr, lines are out of order!",
		   start, addr) > "/dev/stderr"
	}
	while (addr < start) {
	    printf("%c", 0)
	    addr++
	}
	count = split(parts[2], data, " ")
	for (i = 1; i <= count; i++) {
	    byte = strtonum("0x" data[i])
	    printf("%02X ", byte) > "/dev/stderr"
	    printf("%c", byte)
	    addr++
	}
    }
}
