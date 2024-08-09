# proxitok2proxitok.tcl

setudef flag proxitok

bind pubm * "% *https://tiktok.com/*" outputProxiTokLink
bind pubm * "% *http://tiktok.com/*" outputProxiTokLink
bind pubm * "% *https://www.tiktok.com/*" outputProxiTokLink
bind pubm * "% *http://www.tiktok.com/*" outputProxiTokLink

set proxitokHost "farside.link/proxitok"
set proxitokAntiFloodSeconds 5

array set ::proxitokAntiFlood {}

proc outputProxiTokLink {nick uhost hand chan text} {
    if {[channel get $chan proxitok]} {
        if {[string index $text 0] == "!"} {
            putlog "\[tiktok2proxitok\] ignoring proxitok link from $nick!$uhost in $chan - line starts with ! ($text)"
            return 0
        }
        global proxitokHost proxitokAntiFlood proxitokAntiFloodSeconds
	set afbypass 0
        set accthand [finduser -account [getaccount $nick]]
        if {[string match $accthand "*"]} {
            # not needed once eggdrop adds support for nickserv account to nick2hand
            set accthand [nick2hand $nick]
        }
        if {(![string match $accthand "*"]) && ([matchattr $accthand +E])} {
                putlog "\[proxitok2proxitok\] anti-flood: bypassing anti-floor system for $nick!$uhost in $chan (hand: $accthand), has chattr E"
		set afbypass 1
            }
	# extract just the host from $uhost
        set atPosition [string last "@" $uhost]
        set host [string range $uhost [expr {$atPosition + 1}] end]
        if {([info exists proxitokAntiFlood($host)]) && ($afbypass == 0)} {
            set currentTime [clock seconds]
            set elapsedTime [expr {$currentTime - $proxitokAntiFlood($host)}]
            if {$elapsedTime <= $proxitokAntiFloodSeconds} {
                putlog "\[proxitok2proxitok\] anti-flood: ignoring proxitok link from $nick!$uhost in $chan, ($elapsedTime/$proxitokAntiFloodSeconds seconds since last conversion for $host)"
                return 1
            }
        }
        set proxitokLinks [regexp -all -inline {https?://(?:www\.)?(?:tiktok)\.com/[@-_.a-zA-Z0-9/]+} $text]
	# if someone just sends https://tiktok.com/, for example
	if {$proxitokLinks == ""} { return }
        putserv "PRIVMSG $chan :proxitok: [join [string map -nocase [list "@" "%40" "www." "" "http://" "https://" "tiktok.com" $proxitokHost] $proxitokLinks]]"
        set proxitokAntiFlood($host) [clock seconds]
    }
}
