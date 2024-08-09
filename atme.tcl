setudef flag nohelp

bind pubm * "% *" atme

proc atme {nick uhost hand chan text} {
	global botnick
	set target [string trim [lindex [split $text] 0] ':,']
	if {$text == ",help"} {
		set target $botnick
	}
	if {([isbotnick $target]) || ($target == "🥚") || ($target == "🥚💧")} {
		set atcmd [lindex [split $text] 1]
		if {$text == ",help"} {
			set atcmd "help"
		}
		set args [join [lrange [split $text] 2 end] " "]
		switch -- $atcmd {
			"hi" {
				putserv "PRIVMSG $chan :hi, $nick!"
			}
			"help" {
				puthelp "NOTICE $nick :\[help\] !tell <nick/hostmask> <message>"
				puthelp "NOTICE $nick :\[help\] !seen \[-exact/-glob/-regex\] <nick>"
				puthelp "NOTICE $nick :\[help\] !remind <nick> \"<time>\" <message> - remind someone about something"
				puthelp "NOTICE $nick :\[help\] !remindme \"<time>\" <message> - remind yourself about something"
				puthelp "NOTICE $nick :\[help\]   - note: if your time declaration for remind(me) is more than one word please encapsulate it in quotation marks"
				puthelp "NOTICE $nick :\[help\] !clockscan <time> - test out what a reminder's firing time will look like without setting one"
				puthelp "NOTICE $nick :\[help\]   - note: <time> for remind(me)/clockscan is a format parseable by the TCL command 'clock scan' - https://www.tcl.tk/man/tcl8.6/TclCmd/clock.html"
				puthelp "NOTICE $nick :\[help\] karma: you may \"<item>++\" and \"<item>--\" any word or phrase. \"!kbest\" and \"!kworst\" return the top (and bottom) ten. \"!karma \[item\]\" to look up individual scores. \"!kstats\" for statistics. Use \"!kfind <item>\" and \"!krfind <item>\" to search for things in the database ordered by karma in ascending or descending order (respectively), or just use \"!krand\" for ten random things."
				puthelp "NOTICE $nick :\[help\] transferinliner: auto-converts https://transfer.archivete.am links to their /inline/ variant for browser viewing"
				#puthelp "NOTICE $nick :\[help\] twitter2nitter: auto-converts https://(twitter|x).com links to a nitter host for better logged-out viewing"
				puthelp "NOTICE $nick :\[help\] that's it for now!"
			}
		}
	}

}
