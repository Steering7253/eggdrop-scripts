setudef flag 8ball

bind pub * "!8ball" 8ball

set 8ballantifloodsecs 3

# source: https://magic-8ball.com/magic-8-ball-answers/
set 8ballanswers {"it is certain" "it is decidedly so" "without a doubt" "yes definitely" "you may rely on it" "as i see it, yes" "most likely" "outlook good" "yes" "signs point to yes" "reply hazy, try again" "ask again later" "better not tell you now" "cannot predict now" "concentrate and ask again" "don’t count on it" "my reply is no" "my sources say no" "outlook not so good" "very doubtful"}

set 8ballantiflood [dict create]

proc 8ball {nick uhost hand chan text} {
    if {[channel get $chan 8ball]} {
        global 8ballanswers 8ballantiflood 8ballantifloodsecs
	set host [lindex [split $uhost @] 1]
        set key "$host,$chan"
        if {[dict exists $8ballantiflood $key] && ([clock seconds] - [dict get $8ballantiflood $key]) <= $8ballantifloodsecs} {
            putlog "\[8ball\] ignored '!8ball $text' from $nick!$uhost in $chan - anti-flood"
            return 1
        } else {
            dict set 8ballantiflood $key [clock seconds]
            putserv "PRIVMSG $chan :🎱: $nick, [lindex $8ballanswers [expr {int(rand()*[llength $8ballanswers])}]]"
        }
    }
}
