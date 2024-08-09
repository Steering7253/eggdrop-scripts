#########################################################################################
# Name          m00nie::youtube
# Description   Uses youtube v3 API to search and return videos
#
# Version  3.1 - Yet more duration decoding fixes. Specific case of 00s videos less than 
#                an hour too. It also adds checks for videos <24 hours long (who knew)
#                Hope this is the last of the duration crap
#          3.0 - Again trying to fix or cover all scenarios for how duration is returned
#                in ISO format without needing to load another library. Hopefully correct..
#                Also reverted some encoding changed back to 2.6 as these were added in
#                error. Live stream detection should also be working again as that value
#                seems to have changed. 
#          2.9 - OMG the time 
#          2.8 - New variable "out" to more easily change the (I think lovely ;D) YouTube 
#                output at the beginning of any spam in this script. 
#          2.7 - Handles API problems (e.g. having an incorrect key) nicer. Also since
#                v1.9 of eggdrop utf8 is nativley handled so tries to accomodate that
#                within the script. 
#          2.6 - Add likes to auto spam (Thanks to ComputerTech for the suggestion)
#                also a small update to time formating
#          2.5 - Correctly returns results for channels rather than videos for !yt
#          2.4 - Fixing bug that meant date was again reported wrongly. Thanks
#               to caesar for suggesting the fix
#          2.3 - Fix for new date/time results from the API
#          2.2 - Reodering throttling to make it work better....
#          2.1 - Adds throttling to spammed links themselves (link_throt)
#               Also includes a fix on some character output with !yt searching
#               Thanks to <AlbozZ> for this spot and fix!
#          2.0 - Adds seperate flag for search and autoinfo (suggestion from m4s)
#                This is a change from previous versions
#               .chanset #chan +youtube = Enabled auto info grabbing on a URL spam
#               .chanset #chan +youtubesearch = Enabled access to search via !yt
#          1.9 - Adding throttling controls (per user and per chan)
#          1.8 - Chanset +youtube now controls search access!
#          1.7 - Modify SSL params (fixes issues on some systems)
#          1.6 - Small correction to "stream" categorisation.....
#          1.5 - Added UTF-8 support thanks to CatboxParadox (Requires eggdrop
#               to be compiled with UTF-8 support)
#          1.4 - Correct time format and live streams gaming etc
#          1.3 - Updated output to be RFC compliant for some IRCDs
#          1.2 - Added auto info grabber for spammed links
#          1.1 - Fixing regex!
#          1.0 - Initial release
# Website       https://www.m00nie.com/youtube-eggdrop-script-using-api-v3/
# Notes         Grab your own key @ https://developers.google.com/youtube/v3/
#########################################################################################
namespace eval m00nie {
   namespace eval youtube {
    # ----- CHANGE these variables -----
    # This key is your own and shoudl remain a secret (e.g please dont email it to me! Obtain it on the link above in the notes)
    # Set this in the config, not here
    #set m00nie::youtube::key "..."
    
    # Some people dont like coloured output! :O 
    # (you can see an example of the coloured output @ https://www.m00nie.com/youtube-eggdrop-script-using-api-v3/)
    # Whatever text (if any) you set the below variable to will be spammed prior to the first result of search or autoinfo
    #variable out "\002\00301,00You\00300,04Tube\003\002"
    variable out "\[youtube\]"
    
    # The two variables below control throttling in seconds. First is per user, second is per channel third is per link
    variable user_throt 5
    variable chan_throt 5
    variable link_throt 10


    # ---- Dont change things below this line -----
    package require http
    package require json
    # We need to verify the revision of TLS since prior to this version is missing auto host for SNI
    if { [catch {package require tls 1.7.11}] } {
    	# We dont have an autoconfigure option for SNI
    	putlog "m00nie::youtube *** WARNING *** OLD Version of TLS package installed please update to 1.7.11+ ... "
	http::register https 443 [list ::tls::socket -servername www.googleapis.com]
    } else {
    	package require tls 1.7.11
	http::register https 443 [list ::tls::socket -autoservername true]
    }
    bind pub - !yt m00nie::youtube::search
    bind pubm - * m00nie::youtube::autoinfo
    variable version "3.1"
    setudef flag youtube
    setudef flag youtubesearch
    variable regex {(?:http(?:s|).{3}|)(?:www.|)(?:youtube.com\/watch\?.*v=|youtu.be\/)([\w-]{11})}
    ::http::config -useragent "Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:129.0) Gecko/20100101 Firefox/129.0"
    variable throttled

#### Script Starts here #####

proc autoinfo {nick uhost hand chan text} {
    if {[channel get $chan youtube] && [regexp -nocase -- $m00nie::youtube::regex $text url id]} {
        if {[throttlecheck $nick $chan $id]} { return 0 }
	putlog "m00nie::youtube::autoinfo is running"
        putlog "m00nie::youtube::autoinfo url is: $url and id is: $id"
        set url "https://www.googleapis.com/youtube/v3/videos?id=$id&key=$m00nie::youtube::key&part=snippet,statistics,contentDetails&fields=items(snippet(title,channelTitle,publishedAt),statistics(viewCount,likeCount,dislikeCount),contentDetails(duration))"
        set ids [getinfo $url]

	# Catch probs...
	if {$ids eq "0"} {
		putlog "m00nie::youtube::autoinfo there was a problem :(" 
		return
	}
        set title [encoding convertfrom [lindex $ids 0 1 3]]

        set pubiso [lindex $ids 0 1 1]
        set pubiso [string map {"T" " " ".000Z" "" "Z" ""} $pubiso]
        set pubtime [clock format [clock scan $pubiso] -format {%Y-%m-%dT%H:%M:%SZ}]

        set user [encoding convertfrom [lindex $ids 0 1 5]]
        # Yes all quite horrible...
	# ... it gets worse. ISO time format really isnt my friend...
	# ... be sick on yourself.. I have 
        set isotime [lindex $ids 0 3 1]
	regsub -all {P} $isotime "" isotime
	# First off check for videos that are days and non 0 hours
	if {[regexp {^[0-9]*DT[0-9]*H} $isotime]} {
 		regexp {(^[0-9]*DT)?([0-9]*H)} $isotime x days hours
 		regsub -all {DT} $days "" days
 		regsub -all {H} $hours "" hours
 		set hours [expr ($days * 24) + $hours]
 		set nh "${hours}H"
 		regsub -all {^.*H} $isotime "$nh" isotime
	# Now check for videos that are days and "0" hours
	} elseif {[regexp {^[0-9]*D} $isotime]} {
		regexp {^[0-9]*D} $isotime days
 		regsub -all {D} $days "" days
 		set hours [expr $days * 24]
 		set nh "${hours}H"
 		regsub -all {^.*D} $isotime "$nh" isotime
	}
	# Everything else should be <24 hours and >24 shoud be formatted (maybe)
	
        regsub -all {T} $isotime "" isotime
	# No M or S returned e.g. PT10H for a 10:00:00 video...
	if {[regexp {^[0-9].*H$} $isotime]} {
		set isotime "${isotime}00M00S"
	# No M but we do have S e.g. PT10H01S for a 10:00:01 video...
	} elseif {[regexp {^[0-9]*H[0-9]*S$} $isotime]} {
		regsub {H} $isotime "H00M" isotime
	# No S but we do have M e.g. PT10M for a 10:00 video...
	} elseif {[regexp {^[0-9]*M$} $isotime]} {
		regsub {M} $isotime "M00S" isotime
	}
	# Now we should have some kind of "standard" to mangle as before
        regsub -all {H|M} $isotime ":" isotime
	regsub -all {S} $isotime "" isotime
	# Seems it can now return P0D (it use to be 0)
        if { [string index $isotime 0] == "0" || $isotime == "P0D" } {
            set isotime "live"
	} elseif { [string index $isotime end-1] == ":" } {
            set sec [string index $isotime end]
            set trim [string range $isotime 0 end-1]
            set isotime ${trim}0$sec
        } elseif { [string index $isotime end-2] != ":" } {
            set isotime "${isotime}s"
        }
        set views [lindex $ids 0 5 1]
	set like [lindex $ids 0 5 3]
	# At the moment not used (it looked a little messy)
	set dis [lindex $ids 0 5 5]
        puthelp "PRIVMSG $chan :$m00nie::youtube::out \002$title\002 by $user (duration: $isotime) on $pubtime, $views views \[Likes: $like\]"
    }
}

proc b0rkcheck {results} {
	putlog "m00nie::youtube::b0rkcheck is running"
	if {!([lindex $results 0 0] eq "items")} {
		putlog "m00nie::youtube::b0rkcheck looks to be a problem with the API - [lindex $results 0 0] [lindex $results 1 1]: [lindex $results 1 3]"
		return 0
	} else { 
		return 1
	}
}

proc throttlecheck {nick chan link} {
	if {[info exists m00nie::youtube::throttled($link)]} {
		putlog "m00nie::youtube::throttlecheck search term or video id: $link, is throttled at the moment"
		return 1
	} elseif {[info exists m00nie::youtube::throttled($chan)]} {
		putlog "m00nie::youtube::throttlecheck Channel $chan is throttled at the moment"
		return 1
	} elseif {[info exists m00nie::youtube::throttled($nick)]} {
		putlog "m00nie::youtube::throttlecheck User $nick is throttled at the moment"
                return 1
	} else {
		set m00nie::youtube::throttled($nick) [utimer $m00nie::youtube::user_throt [list unset m00nie::youtube::throttled($nick)]]
		set m00nie::youtube::throttled($chan) [utimer $m00nie::youtube::chan_throt [list unset m00nie::youtube::throttled($chan)]]
		set m00nie::youtube::throttled($link) [utimer $m00nie::youtube::link_throt [list unset m00nie::youtube::throttled($link)]]
		return 0
	}
}

proc getinfo { url } {
    for { set i 1 } { $i <= 5 } { incr i } {
            set rawpage [::http::data [::http::geturl "$url" -timeout 5000]]
            if {[string length rawpage] > 0} { break }
        }
        putlog "m00nie::youtube::getinfo Rawpage length is: [string length $rawpage]"
        if {[string length $rawpage] == 0} { error "youtube returned ZERO no data :( or we couldnt connect properly" }
        set results [json::json2dict $rawpage]
	# Check is we have errors
	if {[b0rkcheck $results]} {
		# We dont :)
		set ids [dict get $results items]
    		return $ids
	} else {		
		# We do have errors :(
		return 0
	}
}

proc search {nick uhost hand chan text} {
        if {![channel get $chan youtubesearch] } {
                return
        }
    	putlog "m00nie::youtube::search is running"
    	regsub -all {\s+} $text "%20" text
        if {[throttlecheck $nick $chan $text]} { return 0 }
    	set url "https://www.googleapis.com/youtube/v3/search?part=snippet&fields=items(id(videoId),id(channelId),snippet(title))&key=$m00nie::youtube::key&q=$text"
    	set ids [getinfo $url]
	
	# Catch probs...
        if {$ids eq "0"} {
                putlog "m00nie::youtube::autoinfo there was a problem :("
                return
        }

	set output "$m00nie::youtube::out "
    	for {set i 0} {$i < 5} {incr i} {
        	set id [lindex $ids $i 1 1]
        	set type [lindex $ids $i 1 0]
        	# Catch Channels rather than videos (youtu.be doesnt work for channels)
                if {$type eq "channelId"} {
                        set yout "https://www.youtube.com/channel/$id"
                } else {
                        set yout "https://youtu.be/$id"
                }
        	set desc [encoding convertfrom [lindex $ids $i 3 1]]
		set desc [string map -nocase [list "&amp;" "&" "&#39;" "'" "&quot;" "\""] $desc ]
        	append output "\002" $desc "\002 - " $yout " | "
    	}
    	set output [string range $output 0 end-2]
    	puthelp "PRIVMSG $chan :$output"
}
}
}
putlog "m00nie::youtube $m00nie::youtube::version loaded"

