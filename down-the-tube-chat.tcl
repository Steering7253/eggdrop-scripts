bind pubm * "#down-the-tube *" dtt-privmsg

proc dtt-privmsg {nick uhost hand chan text} {
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
	
        putserv "PRIVMSG #down-the-tube-chat :<$nick> $text"
}

bind ctcp * "ACTION" dtt-action

proc dtt-action {nick uhost hand dest keyword text} {
    if {$dest == "#down-the-tube"} {
	if {[isop $nick $dest]} {
		set nick "@$nick"
	} elseif {[isvoice $nick $dest]} {
		set nick "+$nick"
	}
        putserv "PRIVMSG #down-the-tube-chat :\001ACTION <$nick> $text\001"
    }
}

bind notc * "*" dtt-notice

proc dtt-notice {nick uhost hand text {dest ""}} {
    if {$dest == "#down-the-tube"} {
	if {[isop $nick $dest]} {
		set nick "@$nick"
	} elseif {[isvoice $nick $dest]} {
		set nick "+$nick"
	}
        putserv "NOTICE #down-the-tube-chat :<$nick> $text"
    }
}

bind out * "% sent" dtt-out

proc dtt-out {queue text status} {
	set botnick $::botnick
	if {[botisop "#down-the-tube"]} {
		set botnick "@$botnick"
	} elseif {[botisvoice "#down-the-tube"]} {
		set botnick "+$botnick"
	}
    if {[string match "PRIVMSG #down-the-tube *" $text]} {
	    if {[string match "*\\\[remind\\\]*" $text]} {
	    putserv "PRIVMSG #down-the-tube-chat :<$botnick> [join [lrange [split $text ":"] 1 end] ":"]"
    }
    }
    if {[string match "NOTICE #down-the-tube *" $text]} {
	    if {[string match "*\\\[karma\\\]*" $text]} {
	    putserv "NOTICE #down-the-tube-chat :<$botnick> [join [lrange [split $text ":"] 1 end] ":"]"
    }
    }
}
