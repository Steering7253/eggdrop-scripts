################################################
#################### ABOUT #####################
################################################
#
# Reminder-0.2 by Fredrik Bostrom
# for Eggdrop IRC bot
#
# Usage:
# !remind nick time message
#   - creates a new reminder for nick in the 
#     current channel at time with message
#   - time is a format parseable by the tcl 
#     command 'clock scan'. If the time consists
#     of several words, it has to be enclosed
#     in "".
#   - examples: 
#     !remind morbaq "tomorrow 10:00" Call Peter 
#     !remind morbaq "2009-12-31 23:59" Happy new year!
#
# !reminders 
#   - lists all active reminders
#
# !cancelReminder id
#   - cancels the reminder with id
#   - the id is the number preceeding the 
#     reminder in the list produced by 
#     !reminders
#   - note: the id may change as new reminders 
#     are added or old reminders removed. Always
#     check the id just before cancelling
#
#
################################################
################ CONFIGURATION #################
################################################

set datafile "scripts/reminders.dat"

################################################
######## DON'T EDIT BEOYND THIS LINE! ##########
################################################

bind pub - "!clockscan" pub:clockscan
bind pub - "!remind" pub:newReminder
bind pub - "!remindme" pub:newReminderfornick
bind pub - "!reminders" pub:getReminders
bind pub n "!cancelReminder" pub:cancelReminder
bind pub n "\$inspectReminders" pub:inspectReminders

array set reminders {}

# save to file
proc saveReminders {} {
    global reminders
    global datafile

    set file [open $datafile w+]
    puts $file [array get reminders] 
    close $file
}

# the run-at-time procedure
proc at {time args} {
    if {[llength $args]==1} {
	set args [lindex $args 0]
    }
    set dt [expr {($time - [clock seconds])*1000}]
    return [after $dt $args]
}

proc printReminder {reminderId {tonick ""} {fire "false"}} {
    global reminders

    # get the reminder
    set reminder $reminders($reminderId)

    set when [clock format [lindex $reminder 0] -format "%Y-%m-%dT%H:%M:%SZ"]
    set chan [lindex $reminder 1]
    set who [lindex $reminder 2]
    set timer [lindex $reminder 3]
    set what [lindex $reminder 4]

    if {$fire} {
	putserv "PRIVMSG $chan :\[remind\] $who: $what"
    } else {
	putserv "NOTICE $tonick :\[remind\] $reminderId: for $who at $when: $what"
    }
}

proc fireReminder {reminderId} {
    global reminders

    printReminder $reminderId "" "true"
    unset reminders($reminderId)
    saveReminders
}


proc pub:clockscan {nick host handle chan text} {
    set timeError ""
    # parse parameters
    set curTime [clock format [clock seconds] -format "%H:%M:%SZ" -gmt 1]
    regsub -all {([0-9]+)y$} $text "\\1 years $curTime" text
    regsub -all {([0-9]+)mo$} $text "\\1 months $curTime" text
    regsub -all {([0-9]+)w$} $text "\\1 weeks $curTime" text
    regsub -all {([0-9]+)d$} $text "\\1 days $curTime" text
    regsub -all {([0-9]+)hr?$} $text {\1 hours} text
    regsub -all {([0-9]+)m$} $text {\1 minutes} text
    regsub -all {([0-9]+)s$} $text {\1 seconds} text
    set time [catch {clock scan $text} timeResult]

    if {$time != 0} {
	    putserv "NOTICE $chan :\[remind\] unable to parse time: $timeResult"
	    return 1
    }

    set ISOTimeResult [clock format $timeResult -format "%Y-%m-%dT%H:%M:%SZ" -gmt 1]

    if {[clock seconds] > $timeResult} {
	    putserv "NOTICE $chan :\[clockscan\] error: \"$text\" (parsed as $timeResult → $ISOTimeResult) is in the past"
            return 1
    }

    putserv "NOTICE $chan :\[clockscan\] parsed \"$text\" as $timeResult → $ISOTimeResult"
}


proc pub:newReminderfornick {nick host handle chan text} {
    global reminders


    set timeError ""
    # parse parameters
    set id [clock seconds]
    set who $nick
    set when [lindex $text 0]
    set curTime [clock format [clock seconds] -format "%H:%M:%SZ" -gmt 1]
    regsub -all {([0-9]+)y$} $when "\\1 years $curTime" when
    regsub -all {([0-9]+)mo$} $when "\\1 months $curTime" when
    regsub -all {([0-9]+)w$} $when "\\1 weeks $curTime" when
    regsub -all {([0-9]+)d$} $when "\\1 days $curTime" when
    regsub -all {([0-9]+)hr?$} $when {\1 hours} when
    regsub -all {([0-9]+)m$} $when {\1 minutes} when
    regsub -all {([0-9]+)s$} $when {\1 seconds} when
    set time [catch {clock scan $when} timeResult]
    set what [lrange $text 1 end]

    if {$when == ""} {
	    putserv "NOTICE $chan :\[remind\] !remindme \"<time>\" <message> (time is a format parseable by the TCL command 'clock scan' - https://www.tcl.tk/man/tcl8.6/TclCmd/clock.html)"
	    return 0
    }

    if {$time != 0} {
	    putserv "NOTICE $chan :\[remind\] unable to parse time: $timeResult"
	    return 1
    }

    set ISOTimeResult [clock format $timeResult -format "%Y-%m-%dT%H:%M:%SZ" -gmt 1]

    if {[clock seconds] > $timeResult} {
	    putserv "NOTICE $chan :\[remind\] error: \"$when\" (parsed as $timeResult → $ISOTimeResult) is in the past"
            return 1
    }

    # create new entry
    set new [list $timeResult $chan $who null $what]

    # activate the event
    set timer [at $timeResult fireReminder $id]

    # putlog "new timer: $timer"

    # set the timer associated with this reminder
    set new [lreplace $new 3 3 $timer]
    # putlog "new reminder: $new"

    set reminders($id) $new
    saveReminders

    putserv "NOTICE $chan :\[remind\] ok, i'll remind you at $ISOTimeResult"
}

proc pub:newReminder {nick host handle chan text} {
    global reminders

    # parse parameters
    set id [clock seconds]
    set who [lindex $text 0]
    set when [lindex $text 1]
    set curTime [clock format [clock seconds] -format "%H:%M:%SZ" -gmt 1]
    regsub -all {([0-9]+)y$} $when "\\1 years $curTime" when
    regsub -all {([0-9]+)mo$} $when "\\1 months $curTime" when
    regsub -all {([0-9]+)w$} $when "\\1 weeks $curTime" when
    regsub -all {([0-9]+)d$} $when "\\1 days $curTime" when
    regsub -all {([0-9]+)hr?$} $when {\1 hours} when
    regsub -all {([0-9]+)m$} $when {\1 minutes} when
    regsub -all {([0-9]+)s$} $when {\1 seconds} when
    set time [catch {clock scan $when} timeResult]
    set what [lrange $text 2 end]

    if {$who == ""} {
	    putserv "NOTICE $chan :\[remind\] !remind <nick> \"<time>\" <message> (time is a format parseable by the TCL command 'clock scan' - https://www.tcl.tk/man/tcl8.6/TclCmd/clock.html)"
	    return 0
    }

    if {$time != 0} {
	    putserv "NOTICE $chan :\[remind\] unable to parse time: $timeResult"
	    return 1
    }

    set ISOTimeResult [clock format $timeResult -format "%Y-%m-%dT%H:%M:%SZ" -gmt 1]

    if {[clock seconds] > $timeResult} {
	    putserv "NOTICE $chan :\[remind\] error: \"$when\" (parsed as $ISOTimeResult) is in the past"
            return 1
    }

    # create new entry
    set new [list $timeResult $chan $who null $what]

    # activate the event
    set timer [at $timeResult fireReminder $id]

    # putlog "new timer: $timer"

    # set the timer associated with this reminder
    set new [lreplace $new 3 3 $timer]
    # putlog "new reminder: $new"

    set reminders($id) $new
    saveReminders

    putserv "NOTICE $chan :\[remind\] ok, i'll remind $who at $ISOTimeResult"
}

proc pub:getReminders {nick host handle chan text} {
    global reminders
    set chanReminders {}
    
    # count all reminders for this channel
    foreach {key value} [array get reminders] {
	if {[lindex $value 1] == $chan} {
	    lappend chanReminders $key
	}
    }

    # count the reminders
    set howMany [llength $chanReminders]

    # do we have reminders?
    if {$howMany < 1} {
	putserv "NOTICE $nick :\[remind\] no active reminders"
	return
    }

    # print reminders for this channel
    putserv "NOTICE $nick :\[remind\] $howMany active reminder(s):"
    foreach key $chanReminders {
	printReminder $key $nick
    }
}

proc pub:cancelReminder {nick host handle chan text} {
    global reminders

    set reminder $reminders($text)
    set timer [lindex $reminder 3]

    # putlog "Cancelling timer: $timer"
    after cancel $timer
    unset reminders($text)
    putserv "PRIVMSG $chan :Removed reminder with id $text"

    saveReminders
}

proc pub:inspectReminders {nick host handle chan text} {
    global reminders

    set timerString [after info]
    set reminderString [array get reminders]

    putserv "NOTICE $nick :Reminders: $reminderString"
    putserv "NOTICE $nick :Timers: $timerString"
}

proc initReminders {} {
    global reminders
    
    set reminderString [array get reminders]
    # putlog "Initiating reminders: $reminderString"

    # get current time
    set time [clock seconds]

    # get active timers
    set activeTimers [after info]

    # check for expired reminders and fire them
    foreach {key value} [array get reminders] {
	if {[lindex $value 0] < $time} {
	    fireReminder $key
	} elseif {[lsearch $activeTimers [lindex $value 3]] == -1} {
	    # if the reminder hasn't expired, check if the timer is already set
	    set timerId [at [lindex $value 0] fireReminder $key]
	    set reminders($key) [lreplace $value 3 3 $timerId]
	}
    }
    saveReminders
}


# read the old if they exist
set file [open $datafile]
set content [read $file]
close $file

if {$content == ""} {
    set content {}
}

array set reminders $content

initReminders


###################################
putlog "Reminder script loaded!"
###################################

