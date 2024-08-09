# transferinliner.tcl

setudef flag transferinliner

bind pubm * "% *https://transfer.archivete.am/*" outputATTLink

set ATTAntiFloodSeconds 5
set ATTAntiFloodLinkSeconds 120
set ATTExcludedExtensions {*.zst *.gz *.tar.gz *.tar *.tar.xz}

array set ::ATTAntiFlood {}
array set ::ATTAntiFloodLinks {}

proc outputATTLink {nick uhost hand chan text} {
    if {[channel get $chan transferinliner]} {
        if {[string index $text 0] == "!"} {
            putlog "\[transferinliner\] ignoring transfer link from $nick!$uhost in $chan - line starts with ! ($text)"
            return 0
        }
        set accthand [finduser -account [getaccount $nick]]
        if {[string match $accthand "*"]} {
            # not needed once eggdrop adds support for nickserv account to nick2hand
            set accthand [nick2hand $nick]
        }
        if {![string match $accthand "*"]} {
            if {[matchattr $accthand +B]} {
                putlog "\[transferinliner\] ignoring transfer link from $nick!$uhost in $chan (hand: $accthand), has chattr B"
                return 1
            }
        }
        global ATTAntiFlood ATTAntiFloodLinks ATTAntiFloodSeconds ATTAntiFloodLinkSeconds ATTExcludedExtensions
        # extract just the host from $uhost
        set atPosition [string last "@" $uhost]
        set host [string range $uhost [expr {$atPosition + 1}] end]
        if {[info exists ATTAntiFlood($host)]} {
            set currentTime [clock seconds]
            set elapsedTime [expr {$currentTime - $ATTAntiFlood($host)}]
            if {$elapsedTime <= $ATTAntiFloodSeconds} {
                putlog "\[transferinliner\] anti-flood: ignoring transfer link from $nick!$uhost in $chan, ($elapsedTime/$ATTAntiFloodSeconds seconds since last conversion for $host)"
                return 1
            }
        }
        set ATTLinks [regexp -all -inline {https?://transfer\.archivete\.am/(?!inline/)[^\s]*} $text]
        set urls [split $ATTLinks " "]
        set filteredUrls {}

        foreach url $urls {
            set excludeUrl 0
            foreach extension $ATTExcludedExtensions {
                if {[string match $extension $url]} {
                    set excludeUrl 1
                    break
                }
            }
            if {$excludeUrl == 0} {
                lappend filteredUrls $url
            }
        }

        set ATTLinks [join $filteredUrls " "]
        # if someone just sends https://transfer.archivete.am/, for example
        if {$ATTLinks == "https://transfer.archivete.am/"} { return }
        # only inline links were posted
        if {$ATTLinks == ""} { return }
        regsub -all {[^[:alnum:]]} $ATTLinks "" ATTLinksAF
        if {[info exists ATTAntiFloodLinks($ATTLinksAF)]} {
            set currentTime [clock seconds]
            set elapsedTime [expr {$currentTime - $ATTAntiFloodLinks($ATTLinksAF)}]
            if {$elapsedTime <= $ATTAntiFloodLinkSeconds} {
                putlog "\[transferinliner\] anti-flood: ignoring transfer link from $nick!$uhost in $chan, ($elapsedTime/$ATTAntiFloodLinkSeconds seconds since last conversion for $ATTLinksAF)"
                return 1
            }
        }
        putserv "PRIVMSG $chan :inline (for browser viewing): [join [string map -nocase [list "http://" "https://" "https://transfer.archivete.am/" "https://transfer.archivete.am/inline/"] $ATTLinks]]"
        set ATTAntiFlood($host) [clock seconds]
        set ATTAntiFloodLinks($ATTLinksAF) [clock seconds]
    }
}
