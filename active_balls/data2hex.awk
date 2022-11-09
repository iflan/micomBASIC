# Converts BASIC DATA statements to hex
#
# This script assumes that the BASIC program is similar in structure
# to The Active Balls loader.bas. In particular, it assumes that DATA
# statements are in groups terminated by a DATA statement that has a
# '*' as the first element. (The second element should be the sum of
# all the data in the group. The third element should be the lines the
# group is found on.)
#
# This also interprets lines of the form:
#
#     NNNN S=d+:GOSUB XXXX
#
# to specify a "segment" where S determines where the data groups are
# placed in memory. The number of GOSUB calls specifies how many
# groups belong to that segment.
#

BEGIN {
    segments = 0
    curr_seg = 0
    data = ""
}

# Process segment processing lines of the form:
#
#     NNNN S=d+:GOSUB XXXX[:GOSUB XXXX]*
#
# by saving the value of S in segment_start and the number of GOSUBs
# in segment_groups.
#
/[[:digit:]]+ S=[[:digit:]]+:/ {
    where = match($0, /S=([[:digit:]]+)/,parts)
    if (where != 0) {
	segment_start[segments] = parts[1]
	segment_groups[segments] = gsub(/GOSUB/,"", $0)
	segments++
    }
}

# Process data lines of the form:
#
#     NNNN DATA[...]
#
# If the first element is not "*", then "," is appended to data
# variable followed by everything after the "DATA".
#
# If the first element is "*", then it ends a group and data (minus
# the first character, which is always ",") is saved as the next
# element in segment_groups and cleared.
#
/[[:digit:]]+ DATA/ {
    where = match($0, /DATA\*/)
    if (where != 0) {
	segment_data[curr_seg] = substr(data, 2)
	segment_groups[curr_seg]--
	if (segment_groups[curr_seg] == 0) {
	    curr_seg++
	    data = ""
	}
    } else {
	match($0,/^.*DATA(.*)/,parts)
	data = data "," parts[1]
    }
}

# Process all of the segments in order of segment_start
#
END {
    # segment_order is a new array that has the indexes of the
    # segment_start array in order of the segment_start value.
    count = asorti(segment_start, segment_order, "@val_num_asc")
    # Dump each segment
    for (i = 1; i <= count; i++) {
	hexdump(segment_start[segment_order[i]],
		segment_data[segment_order[i]])
    }
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
    split(data, values, "[ ]*,[ ]*")
    addr = start
    line = ""
    for (pos = 0; pos < addr % 16; pos++) {
	line = line "   "
    }
    for (x in values) {
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
