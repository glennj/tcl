# the quick brown fox jumps over the lazy dog
# 5 rails
#
# t       k       f       s       h       d    : tkfshd
#  h     c _     _ o     p _     t e     _ o   : hc__co_te_o
#   e   i   b   n   x   m   o   _   _   y   g  : eibnxmo__yg
#    _ u     r w     _ u     v r     l z       : _urw_uvrlz
#     q       o       j       e       a        : qojea
# 
# 
# the quick brown fox jumps over the lazy dog
# tkfshdhc  co te oeibnxmo  yg urw uvrlzqojea

namespace eval railFenceCipher {
    namespace export encode decode
    namespace ensemble create

    proc encode {plaintext nrails} {
        set rails [dict create]
        coroutine nextRail railCycle $nrails

        foreach char [split $plaintext ""] {
            set r [nextRail]
            dict append rails $r $char
        }

        return [join [dict values $rails] ""]
    }

    proc decode {ciphertext nrails} {
        set len [string length $ciphertext]

        # determine the length of each rail
        set cycle [expr {2 * ($nrails - 1)}]
        set cycles [expr {$len / $cycle}]
        set railLengths [dict create]
        for {set r 0} {$r < $nrails} {incr r} {
            # "inner" rails consume 2 chars per cycle
            set mult [expr {($r == 0 || $r == $nrails - 1) ? 1 : 2}]
            dict set railLengths $r [expr {$mult * $cycles}]
        }

        # account for leftover characters
        coroutine nextRail railCycle $nrails
        for {set i 0} {$i < $len - $cycles * $cycle} {incr i} {
            set r [nextRail]
            dict incr railLengths $r
        }

        # extract the rails
        set regex [join [lmap l [dict values $railLengths] {
            string cat "(.{" $l "})"
        }] ""]
        set rails [lrange [regexp -inline $regex $ciphertext] 1 end]

        # recreate the plaintext
        coroutine nextRail railCycle $nrails
        for {set i 0} {$i < $len} {incr i} {
            set r [nextRail]
            append plaintext [string range [lindex $rails $r] 0 0]
            lset rails $r [string range [lindex $rails $r] 1 end]
        }

        return $plaintext
    }

    proc railCycle {nrails} {
        yield [info coroutine]
        set rail 0
        set dir 1
        while 1 {
            yield $rail
            if {$rail == $nrails - 1 && $dir == 1} {
                set dir -1
            } elseif {$rail == 0 && $dir == -1} {
                set dir 1
            }
            incr rail $dir
        }
    }
}
