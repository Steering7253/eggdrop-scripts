# nitter2twitter.tcl

setudef flag nitter

#unbind pubm * "% *https://twitter.com/*" outputNitterLink
#unbind pubm * "% *http://twitter.com/*" outputNitterLink
#unbind pubm * "% *https://x.com/*" outputNitterLink
#unbind pubm * "% *http://x.com/*" outputNitterLink

#unbind pubm * "% *https://fixupx.com/*" outputNitterLink
#unbind pubm * "% *https://fixvx.com/*" outputNitterLink
#unbind pubm * "% *https://fxtwitter.com/*" outputNitterLink
#unbind pubm * "% *https://twittpr.com/*" outputNitterLink
#unbind pubm * "% *https://vxtwitter.com/*" outputNitterLink
#unbind pubm * "% *http://fixupx.com/*" outputNitterLink
#unbind pubm * "% *http://fixvx.com/*" outputNitterLink
#unbind pubm * "% *http://fxtwitter.com/*" outputNitterLink
#unbind pubm * "% *http://twittpr.com/*" outputNitterLink
#unbind pubm * "% *http://vxtwitter.com/*" outputNitterLink

bind pubm * "% *" outputNitterLink

set nitterHost "nitter.lucabased.xyz"
set nitterAntiFloodSeconds 5

array set ::nitterAntiFlood {}

proc outputNitterLink {nick uhost hand chan text} {
    if {[channel get $chan nitter]} {
	if {![regexp -- {https?://(twitter|x|fixupx|fixvx|fxtwitter|twittpr|vxtwitter)\.com} $text]} {
	    # no twitters found, return
            return 0
        }
        if {[string index $text 0] == "!"} {
            putlog "\[twitter2nitter\] ignoring twitter link from $nick!$uhost in $chan - line starts with ! ($text)"
            return 0
        }
        global nitterHost nitterAntiFlood nitterAntiFloodSeconds
	set afbypass 0
        set accthand [finduser -account [getaccount $nick]]
        if {[string match $accthand "*"]} {
            # not needed once eggdrop adds support for nickserv account to nick2hand
            set accthand [nick2hand $nick]
        }
        if {(![string match $accthand "*"]) && ([matchattr $accthand +E])} {
                putlog "\[twitter2nitter\] anti-flood: bypassing anti-flood system for $nick!$uhost in $chan (hand: $accthand), has chattr E"
		set afbypass 1
            }
	# extract just the host from $uhost
        set atPosition [string last "@" $uhost]
        set host [string range $uhost [expr {$atPosition + 1}] end]
        if {([info exists nitterAntiFlood($host)]) && ($afbypass == 0)} {
            set currentTime [clock seconds]
            set elapsedTime [expr {$currentTime - $nitterAntiFlood($host)}]
            if {$elapsedTime <= $nitterAntiFloodSeconds} {
                putlog "\[twitter2nitter\] anti-flood: ignoring twitter link from $nick!$uhost in $chan, ($elapsedTime/$nitterAntiFloodSeconds seconds since last conversion for $host)"
                return 1
            }
        }
        set twitterLinks [regexp -all -inline {https?://(?:twitter|x|fixupx|fixvx|fxtwitter|twittpr|vxtwitter)\.com/[-_.a-zA-Z0-9/]+} $text]
	# if someone just sends https://twitter.com/, for example
	if {$twitterLinks == ""} { return }
        putserv "PRIVMSG $chan :nitter: [join [string map -nocase [list "http://" "https://" "fixupx.com" $nitterHost "fixvx.com" $nitterHost "fxtwitter.com" $nitterHost "twittpr.com" $nitterHost "vxtwitter.com" $nitterHost "twitter.com" $nitterHost "x.com" $nitterHost] $twitterLinks]]"
        set nitterAntiFlood($host) [clock seconds]
    }
}

# this should NOT be enabled without care, is currently only used in #hackernews since 'rss' doesn't auto-convert twitter links in submissions
# there are no flood controls etc like above since 'rss' posts fast and this is only to be enabled in special cases
# note: currently `/notice #channel https://twitter.com/twitter` won't work, there needs to be something in front of it. a wildcard in `bind notc` doesn't seem to allow for `*` to match for nothing as it does in `bind pubm` (also tried `%` for "matches 0 or more non-space characters", no dice)

setudef flag nitternotice

bind notc * "% *https://twitter.com/*" processNitterNotice
bind notc * "% *http://twitter.com/*" processNitterNotice
bind notc * "% *https://x.com/*" processNitterNotice
bind notc * "% *http://x.com/*" processNitterNotice

proc processNitterNotice {nick uhost hand text {chan ""}} {
    if {$chan == ""} {
        # notice was delivered directly to the bot, ignore it
        return 0
    } else {
        if {[channel get $chan nitternotice]} {
            global nitterHost
	    set twitterLinks [regexp -all -inline {https?://(?:twitter|x)\.com/[-_.a-zA-Z0-9/]+} $text]
            putserv "NOTICE $chan :nitter: [join [string map -nocase [list "http://" "https://" "twitter.com" $nitterHost "x.com" $nitterHost] $twitterLinks]]"
        }
    }
}
