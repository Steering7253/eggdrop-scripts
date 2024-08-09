# born after accidentally triggering hackint's spambot warnin

bind rawt * 470 gotForwarded

proc gotForwarded {from keyword text tags} {
    set fromChan [lindex [split $text] 1]
    set toChan [lindex [split $text] 2]
    channel set $fromChan +inactive
    putserv "PRIVMSG #fire-trail :\[forward protection\] got forwarded from $fromChan to $toChan, set $fromChan as inactive"
}
