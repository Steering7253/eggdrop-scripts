bind pubm * "#telegrab *" telegrab-privmsg

proc telegrab-privmsg {nick uhost hand chan text} {
	if {([string index $text 0] == "!") && ([string index $text 1] != " ")} {
	    return 0
	}
	if {([string match "*@archiveteam/Aramaki" $uhost]) || ([string match "*@hackint/user/h2ibot" $uhost])} {
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
	
        putserv "PRIVMSG #telegrab-chat :<$nick> $text"
}

bind ctcp * "ACTION" telegrab-action

proc telegrab-action {nick uhost hand dest keyword text} {
    if {$dest == "#telegrab"} {
	if {[isop $nick $dest]} {
		set nick "@$nick"
	} elseif {[isvoice $nick $dest]} {
		set nick "+$nick"
	}
        putserv "PRIVMSG #telegrab-chat :\001ACTION <$nick> $text\001"
    }
}

bind notc * "*" telegrab-notice

proc telegrab-notice {nick uhost hand text {dest ""}} {
    if {$dest == "#telegrab"} {
	if {[isop $nick $dest]} {
		set nick "@$nick"
	} elseif {[isvoice $nick $dest]} {
		set nick "+$nick"
	}
        putserv "NOTICE #telegrab-chat :<$nick> $text"
    }
}

bind out * "% sent" telegrab-out

proc telegrab-out {queue text status} {
	set botnick $::botnick
	if {[botisop "#telegrab"]} {
		set botnick "@$botnick"
	} elseif {[botisvoice "#telegrab"]} {
		set botnick "+$botnick"
	}
    if {[string match "PRIVMSG #telegrab *" $text]} {
	    if {[string match "*\\\[remind\\\]*" $text]} {
	    putserv "PRIVMSG #telegrab-chat :<$botnick> [join [lrange [split $text ":"] 1 end] ":"]"
    }
    }
    if {[string match "NOTICE #telegrab *" $text]} {
	    if {[string match "*\\\[karma\\\]*" $text]} {
	    putserv "NOTICE #telegrab-chat :<$botnick> [join [lrange [split $text ":"] 1 end] ":"]"
    }
    }
}
