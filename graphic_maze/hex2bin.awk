# Converts a hex dump to a binary image
#
# This script takes the output of data2hex.awk and creates a binary
# image with the given bytes at their appropriate locations. The file
# must have the lines in order and the data in the lines cannot
# overlap.
#
# Note that this script must have:
#
#   LC_TYPE=C
#
# in the environment.  (No other LC_* variable needs to be changed.)
#

BEGIN {
    addr = 0
}

# Matches the address at the start of a line
#
#     ABCD:
/^[[:xdigit:]]+:/ {
    count = split($0, parts, ":")
    if (count != 2) {
        print "something went wrong splitting" $0 "on ':'" > "/dev/stderr"
        exit
    }
    line_addr = parts[1]
    start = portablestrtonum("0x" line_addr)
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
        byte = portablestrtonum("0x" data[i])
        # Note that for this to work correctly, set LC_TYPE=C in the
        # environment, otherwise %c may produce UTF-8 or some other
        # encoding.
        printf("%c", byte)
        addr++
    }
}

# Converts a string containing an octal, hex, or decimal integer to an
# integer value.  This function comes straight from the GAWK User's
# Guide:
#
# https://www.gnu.org/software/gawk/manual/html_node/Strtonum-Function.html
#
# It is way more complicated than we need, but it's better just to
# copy the whole thing, lock, stock and barrel.
#
function portablestrtonum(str,        ret, n, i, k, c)
{
    if (str ~ /^0[0-7]*$/) {
        # octal
        n = length(str)
        ret = 0
        for (i = 1; i <= n; i++) {
            c = substr(str, i, 1)
            # index() returns 0 if c not in string,
            # includes c == "0"
            k = index("1234567", c)

            ret = ret * 8 + k
        }
    } else if (str ~ /^0[xX][[:xdigit:]]+$/) {
        # hexadecimal
        str = substr(str, 3)    # lop off leading 0x
        n = length(str)
        ret = 0
        for (i = 1; i <= n; i++) {
            c = substr(str, i, 1)
            c = tolower(c)
            # index() returns 0 if c not in string,
            # includes c == "0"
            k = index("123456789abcdef", c)

            ret = ret * 16 + k
        }
    } else if (str ~ \
  /^[-+]?([0-9]+([.][0-9]*([Ee][0-9]+)?)?|([.][0-9]+([Ee][-+]?[0-9]+)?))$/) {
        # decimal number, possibly floating point
        ret = str + 0
    } else
        ret = "NOT-A-NUMBER"

    return ret
}
