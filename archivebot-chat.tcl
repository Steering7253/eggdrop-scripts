bind pubm * "#archivebot *" abc-privmsg

proc abc-privmsg {nick uhost hand chan text} {
	if {([string index $text 0] == "!") && (([string index $text 1] != " ") && ([string length $text] != "1"))} {
	    return 0
	}
	if {([string match "*@archiveteam/Aramaki" $uhost]) || ([string match "*@hackint/user/h2ibot" $uhost])} { 
        #if {([string match "*@archiveteam/Aramaki" $uhost] && ([string first ": Job" $text] != -1) && ([string first ": Sorry, I don't know anything about" $text != -1)) || ([string match "*@hackint/user/h2ibot" $uhost])} {}
	    return 0
	}
	if {[string index $text 0] == "\001"} {
            return 0
	}
	if {[isop $nick $chan]} {
		set nick "@$nick"
	} elseif {[isvoice $nick $chan]} {
		set nick "+$nick"
	}
	
        putserv "PRIVMSG #archivebot-chat :<$nick> $text"
}

bind ctcp * "ACTION" abc-action

proc abc-action {nick uhost hand dest keyword text} {
    if {$dest == "#archivebot"} {
	if {[isop $nick $dest]} {
		set nick "@$nick"
	} elseif {[isvoice $nick $dest]} {
		set nick "+$nick"
	}
        putserv "PRIVMSG #archivebot-chat :\001ACTION <$nick> $text\001"
    }
}

bind notc * "*" abc-notice

proc abc-notice {nick uhost hand text {dest ""}} {
    if {$dest == "#archivebot"} {
	if {[isop $nick $dest]} {
		set nick "@$nick"
	} elseif {[isvoice $nick $dest]} {
		set nick "+$nick"
	}
        putserv "NOTICE #archivebot-chat :<$nick> $text"
    }
}

bind out * "% sent" abc-out

proc abc-out {queue text status} {
	set botnick $::botnick
	if {[botisop "#archivebot"]} {
		set botnick "@$botnick"
	} elseif {[botisvoice "#archivebot"]} {
		set botnick "+$botnick"
	}
    if {[string match "PRIVMSG #archivebot *" $text]} {
	    if {[string match "*\\\[remind\\\]*" $text]} {
	    putserv "PRIVMSG #archivebot-chat :<$botnick> [join [lrange [split $text ":"] 1 end] ":"]"
    }
    }
    if {[string match "NOTICE #archivebot *" $text]} {
	    if {[string match "*\\\[karma\\\]*" $text]} {
	    putserv "NOTICE #archivebot-chat :<$botnick> [join [lrange [split $text ":"] 1 end] ":"]"
    }
    }
}
