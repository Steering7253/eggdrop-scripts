# tcl.tcl - evaluate TCL statements in channels right from your eggdrop!
# use at your own risk lmfao, i accept no liability

# who has access to this command? (ideally you'd bind n|, but this doesn't support services accounts yet)
set TCLNickServAccount "steering"

bind pub * ,tcl tclchancmd
bind pub * ,, tclchancmd

proc msgSplit {chan msg} {
    set max_length 410
    set constructedMsg "PRIVMSG $chan :$msg"
    # Check if the message is already within the allowed length
    if {[string length $constructedMsg] <= $max_length} {
        putquick "PRIVMSG $chan :$msg"
    } else {
        # Split the message into chunks of maximum length
        set num_chunks [expr {([string length $msg] + $max_length - 1) / $max_length}]
        for {set i 0} {$i < $num_chunks} {incr i} {
            set chunk [string range $msg [expr {$i * $max_length}] [expr {($i + 1) * $max_length - 1}]]
            putquick "PRIVMSG $chan :$chunk ([expr {$i + 1}]/$num_chunks)"
        }
    }
}

proc tclchancmd {nick user hand chan text} {
    global TCLNickServAccount
    set acct [getaccount $nick]
    set accthand [finduser -account $acct]
    if {$accthand != $TCLNickServAccount} {
        putserv "PRIVMSG $chan :no."
        return 1
    }

    set startTime [clock clicks -milliseconds]

    set result [catch {uplevel #0 $text} resultText]

    set endTime [clock clicks -milliseconds]
    set timeTaken [expr $endTime - $startTime]

    set lines [split $resultText "\n"]
    set numLines [llength $lines]

    if {[string trim $resultText] == ""} {
        set resultText "(no output)"
    }

    if {$numLines <= 1} {
        if {$result != 0} {
            msgSplit $chan "error $result: $resultText -${timeTaken}ms-"
        } else {
            msgSplit $chan "ok: $resultText -${timeTaken}ms-"
        }
    } else {
        if {$result != 0} {
            putquick "PRIVMSG $chan :error $result: ($numLines lines) -${timeTaken}ms-"
        } else {
            putquick "PRIVMSG $chan :ok: ($numLines lines) -${timeTaken}ms-"
        }
        set outputtedLines 1
        foreach line $lines {
            msgSplit $chan "${outputtedLines}/${numLines}: $line"
            incr outputtedLines
        }
    }
}

putlog "sourced tcl.tcl"
