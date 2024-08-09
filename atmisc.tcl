bind pub * "!c" conoops

proc conoops {nick uhost hand chan text} {
        if {$chan eq "#archivebot"} {
        if {[isvoice $nick $chan] || [isop $nick $chan]} {
                    putserv "PRIVMSG $chan :oops, $nick! try !con :c"
        } else {
            putserv "PRIVMSG #fire-trail :\[atmisc\] ignored \"!c $text\" from $nick!$uhost in $chan - not a voice or an op"
        }
    }
}

bind pub * "!statussy" statussy
# the following three for systwi
bind pub * "!statys" statussy
bind pub * "!statis" statussy
bind pub * "!s" statussy

proc statussy {nick uhost hand chan text} {
        if {$chan eq "#archivebot"} {
        if {[isvoice $nick $chan] || [isop $nick $chan]} {
                    putserv "PRIVMSG $chan :!status $text"
        } else {
            putserv "PRIVMSG #fire-trail :\[atmisc\] ignored \"!statussy/!statys/!statis/!s $text\" from $nick!$uhost in $chan - not a voice or an op"
        }
    }
}

bind pub * "!help" abhelp

proc abhelp {nick uhost hand chan text} {
        if {$chan eq "#archivebot"} {
            putserv "PRIVMSG $chan :$nick: see https://archivebot.readthedocs.io/"
    }
}


bind pub * "!ignores" ignores
bind pub * "!igs" ignores

proc ignores {nick uhost hand chan text} {
    if {$chan eq "#archivebot"} {
        if {[isvoice $nick $chan] || [isop $nick $chan]} {
                    putserv "PRIVMSG $chan :$nick: http://archivebot.com/ignores/$text?compact=true"
        } else {
            putserv "PRIVMSG #fire-trail :\[atmisc\] ignored \"!ignores/!igs $text\" from $nick!$uhost in $chan - not a voice or an op"
        }
    }
}

package require uri

proc loadPublicSuffixList {filename} {
    set publicSuffixList [dict create]
    set file [open $filename]
    while {[gets $file line] >= 0} {
        if {[string trim $line] eq "" || [string index $line 0] eq "/" || [string index $line 0] eq "!"} {
            continue
        }
        # Normalize the line for processing
        set line [string map {"*." ""} $line]
        dict set publicSuffixList $line 1
    }
    close $file
    return $publicSuffixList
}

proc extractRegistrableDomain {domain publicSuffixList} {
    set parts [split $domain "."]
    set partCount [llength $parts]

    for {set i 0} {$i < $partCount} {incr i} {
        set suffix [join [lrange $parts $i end] "."]
        if {[dict exists $publicSuffixList $suffix]} {
            if {$i > 0} {
                return [join [lrange $parts [expr {$i - 1}] end] "."]
            } else {
                return $domain
            }
        }
    }
    return $domain
}


set PSLfilename "public_suffix_list.dat"
set thePSL [loadPublicSuffixList $PSLfilename]

bind pub * "!igd" igd

proc igd {nick uhost hand chan text} {
    if {$chan eq "#archivebot"} {
        if {[isvoice $nick $chan] || [isop $nick $chan]} {
            global thePSL
            set components [uri::split $text]
            set hostname [dict get $components "host"]
            set registrableDomain [extractRegistrableDomain $hostname $thePSL]
            set escapedDomain [string map { "." "\\." } $registrableDomain]
            putserv "PRIVMSG $chan :$nick: ^(http|ftp)s?://(\[^/\]*\[@.\])?$escapedDomain\\.?(:\\d+)?/"
        } else {
            putserv "PRIVMSG #fire-trail :\[atmisc\] ignored \"!igd $text\" from $nick!$uhost in $chan - not a voice or an op"
        }
    }
}

bind pub * "!b" bmeme

proc bmeme {nick uhost hand chan text} {
    putserv "PRIVMSG $chan :🅱️"
}

bind pub * "!ping" pingcmd

proc pingcmd {nick uhost hand chan text} {
    if {$text eq ""} {
        putserv "PRIVMSG $chan :$nick: pong!"
    } else {
        putserv "PRIVMSG $chan :$nick: pong ($text)!"
    }
}

bind pub * "!ß" punycode

proc punycode {nick uhost hand chan text} {
    putserv "PRIVMSG $chan :...scheiße!"
    putserv "PRIVMSG $chan :UnicodeError: ('IDNA does not round-trip', b'xn--scheie-fta', b'scheisse')"
}

bind pub * !z utctime
bind pub * !utc utctime

proc utctime {nick uhost hand chan text} {
	set now [clock seconds]
	set iso_time [clock format $now -format "%Y-%m-%dT%H:%M:%SZ" -gmt true]
	putserv "PRIVMSG $chan :$iso_time"
}
