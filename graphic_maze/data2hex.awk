# Converts BASIC DATA statements to hex
#
# This script assumes that the BASIC program is similar in structure
# to Graphic Maze's maze.bas. In particular, it assumes that there is
# one stream of DATA statements that has -1 as the last element.
#
# This also interprets lines of the form:
#
#     NNNN A = d+
#
# to specify the start address.
#
# This AWK script uses POSIX awk, which is terrible.  Sorry about
# that.  GNU awk (gawk) has many improvements over the original that
# had to be cut because not all Unix-like systems (I'm looking at you,
# MacOS) have gawk.
#

BEGIN {
    start_address = -1
    data = ""
}

# Process address lines of the form:
#
#     NNNN A = d+
#
# by saving the value of A in start_address.
#
/[[:digit:]]+ A *= *[[:digit:]]+/ {
    where = match($0, /([[:digit:]]+)$/)
    if (where != 0) {
	start_address=substr($0, RSTART, RLENGTH)
    }
}

# Process data lines of the form:
#
#     NNNN DATA[...]
#
# The line is appended to the data variable followed by everything
# after the "DATA". If the last element is "-1", then it is
# removed. This is assumed to be the last line of the program, but it
# is not checked.  Don't have two -1s—that's going to cause a problem.
#
/[[:digit:]]+ *DATA/ {
    match($0,/([[:digit:],-]*)$/)
    data = data "," substr($0, RSTART, RLENGTH)
    where = match(data, /,-1$/)
    if (where != 0) {
        data = substr(data, 2, length(data) - 4)
    }
}

# Process all of the segments in order of segment_start
#
END {
    hexdump(start_address, data)
}

# Dump a segment in hex
#
#   start: the start address of the segment
#   data: a comma-separated list of decimal values
#
# The result is similar to hexdump. xxd, unfortunately, can not parse
# the result correctly because it expects a certain number of bytes
# per line and gets confused if it doesn't find it.
#
function hexdump(start, data,   values, x, line, pos, addr) {
    count = split(data, values, ",")
    addr = start
    line = ""
    for (pos = 0; pos < addr % 16; pos++) {
	line = line "   "
    }
    for (x = 1; x <= count; x++) {
	line = line sprintf(" %02X", values[x])
	pos++
	addr++
	if (pos == 16) {
	    printf "%04X:%s\n", start, line
	    line = ""
	    pos = 0
	    start = addr
	}
    }
    if (pos > 0) {
	printf "%04X:%s\n", start, line
    }
    print ""
}
