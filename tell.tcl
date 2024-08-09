package require sqlite3

set tellfile "./tell.db"

if {![file exists $tellfile]} {
    sqlite3 tellDB $tellfile
    tellDB eval {CREATE TABLE IF NOT EXISTS messages (id INTEGER PRIMARY KEY, target TEXT, sender TEXT, channel TEXT, message TEXT)}
    tellDB close
}

bind pub * "!tell" tell

proc tell {nick uhost hand chan text} {
    global tellfile
    sqlite3 tellDB $tellfile

    set target [lindex [split $text] 0]
    set lowtarget [string tolower $target]
    set msg [join [lrange [split $text] 1 end] " "]
    set message [format "\[%s\] <%s> %s" [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ" -gmt true] $nick $msg]

    if {$target == ""} {
        putserv "NOTICE $chan :\[tell\] syntax: !tell <nick/hostmask> <message>"
        return 0
    }

    if {$msg == ""} {
        putserv "NOTICE $chan :\[tell\] syntax: !tell <nick/hostmask> <message>"
        return 0
    }

    if {$target == $nick} {
        putserv "NOTICE $nick :\[tell\] look at the shape you're in, talking to the walls again..."
        return 0
    }

    if {[onchan $target $chan]} {
        putserv "NOTICE $chan :\[tell\] $target is here - they should see your message :)"
        putserv "PRIVMSG #fire-trail :\[tell\] !tell requested (but skipped, they're on the channel) by $nick in $chan for $target: $msg"
    } else {
        tellDB eval {INSERT INTO messages (target, sender, channel, message) VALUES ($lowtarget, $nick, $chan, $message)}
        putserv "NOTICE $chan :\[tell\] ok, I'll tell $target when they join next"
        putserv "PRIVMSG #fire-trail :\[tell\] !tell requested by $nick in $chan for $target: $msg"
    }
    tellDB close
}

bind join * * tellJoin

proc tellJoin {nick uhost handle chan} {
    global tellfile
    sqlite3 tellDB $tellfile

    set target [string tolower $nick]
    set result [tellDB eval {SELECT message FROM messages WHERE target = $target AND channel = $chan}]

    if {[llength $result] > 0} {
        foreach row $result {
            putserv "PRIVMSG $chan :\[tell\] $nick: $row"
        }
        tellDB eval {DELETE FROM messages WHERE target = $target AND channel = $chan}
    }

    set target [string cat [string tolower $nick] "!" [string tolower $uhost]]
    set result [tellDB eval {SELECT message FROM messages WHERE $target GLOB LOWER(target) AND channel = $chan}]

    if {[llength $result] > 0} {
        foreach row $result {
            putserv "PRIVMSG $chan :\[tell\] $nick: $row"
        }
        tellDB eval {DELETE FROM messages WHERE $target GLOB LOWER(target) AND channel = $chan}
    }

    tellDB close
}

bind nick * * tellNick

proc tellNick {nick uhost handle chan newnick} {
    global tellfile
    sqlite3 tellDB $tellfile

    set target [string tolower $newnick]
    set result [tellDB eval {SELECT message FROM messages WHERE target = $target AND channel = $chan}]

    if {[llength $result] > 0} {
        foreach row $result {
            putserv "PRIVMSG $chan :\[tell\] $newnick: $row"
        }
        tellDB eval {DELETE FROM messages WHERE target = $target AND channel = $chan}
    }

    tellDB close
}
