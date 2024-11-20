# IRC Karma for Eggdrops by Lily (lily@disorg.net)
# This is a Karma database script for Eggdrop bots. 
# It has flood control built in, and basic self-karma prevention. 
# Requires TCL8.4 or greater, and the sqlite3 tcl lib. (not mysql!) 
# For deb/ubuntu, that is the libsqlite3-tcl package. Adjust for your flavor. 
# !! 3.x USERS PLEASE NOTE!!! The database change for 4.x means that unless 
# you manually edit your db, you will have to start over. Sorry! You may not want
# karma entropy and expiry anyway, and thats the big new feature here. 
# 1.0 - self karma prevention
# 2.0 - flood control, maries mods added 
# 2.5 - command triggers fixed, extra commands removed. comments added. 20101220
# 3.0 - converted to sqlite. code cleanup. 20111030
# 3.1 - search and help. 20111104
# 3.2 - changed dbfile varname to prevent namespace collison 20120220
# 4.0 - added db timestamping and karma expiry, changed scoring update loop. 20120828
# 4.1 - karma entropy 20120903
# 4.2 - !instant changes a random thing -/+1 , !random returns things. 20120905
# 4.3 - locked text change, faster decay for high vals, trim item whitespace 20130215 
# 4.4 - Immortal karma (user request). Expanded stats. Fixes (locked text, high val decay) 20130526
# 4.5 - strip ASCII codes from input. 20211221
# TODO - randomize days a little on entropy 

### Usage ###
# Once you have loaded this from your bots config and rehashed it, 
# do: .chanset #yourchannel +lkarma
# In your channel you can "!<item>++" and "!<item>--" with any word or phrase.
# "!good" and "!bad" return the top (and bottom) ten. "!khelp" for help. 
# "!lfind" returns locked items. "!ifind" returns immortalized items. 
# "!karma <item>" for score. "!stats" for total items and average karma (unlocked items). 
# "!find <item>" and "!rfind <item>" to search for things in the database.
# "!instant" changes a random thing -/+1 , "!random" returns some items.
# Privileged users can "!lock <item>", "!unlock <item>", and "!delete <item>"
# They can also "!immortalize <item>" and remove it from entropy. Cannot be unset. 

### Settings ###

set karma(logchan) "#fire-trail"

# Set this to f allow friends in the bot to use karma (+f flag)
# Set this to - if you want everyone to be able to.
set karma(flags) "-|-"

# Default flags allow only bot owners to lock/unlock karma.
set karma(lockflags) "n|-"

# Default flags allow only bot owners to delete karma from the database.
set karma(deleteflags) "n|-"

# x times in y seconds to trigger flood protection
set kfflood 4:300

###############################################
set karma(version) "4.5"
setudef flag lkarma
package require sqlite3
set kdbfile "./lkarma.db"
if {![file exists $kdbfile]} { 
  sqlite3 kdb $kdbfile
    kdb eval {CREATE TABLE lkarma(item TEXT NOT NULL COLLATE NOCASE, karma INTEGER NOT NULL, locked TEXT NOT NULL default 'N', modtime INTEGER NOT NULL)}
  kdb close
}

bind pubm $karma(flags) "% *--" fixkarma
bind pubm $karma(flags) "% *++" fixkarma

proc fixkarma {nick uhost hand chan text} {
  global karma kdbfile kfcount kfflood
  if {[string match "*+lkarma*" [channel info $chan]]} {  
    set nick [string map { "\{" "\\\{" "\}" "\\\}" "\[" "\\\[" "\]" "\\\]" } $nick]
    set uhost [string tolower $uhost]
    set acct [getaccount $nick]
    set hand [finduser -account $acct]
    set chan [string tolower $chan]    
    set item [string range $text 0 [expr [string length $text] -3]]
    set item [stripcodes bcruag $item]
    set item [string trim $item]
    if {$hand == "rss"} { return 0 }
    sqlite3 kdb $kdbfile
    if {$item == ""} {
      return 0
    }
    if {[string match -nocase *$nick* $item]} {
      puthelp "NOTICE $chan :\[karma\] self karma is a selfish pursuit."
      return 0
    }
    if {($acct != "*")} {
        if {([string match -nocase *$acct* $item])} {
            puthelp "NOTICE $chan :\[karma\] self karma is a selfish pursuit."
            return 0
        }
    }

    set score [string range $text end-1 end]
    if {[string match "++" $score]} {
      set scoring +1
    } elseif {[string match "--" $score]} {
      set scoring -1
    }  

    if {[kdb eval {SELECT locked FROM lkarma WHERE item=$item}] == "Y"} { 
      set lockedk [kdb eval {SELECT karma FROM lkarma WHERE item=$item}]
      puthelp "NOTICE $chan :\[karma\] '$item' now has $lockedk karma!"
      if {[string match "++" $score]} {
          puthelp "PRIVMSG $karma(logchan) :\[karma\] $nick!$uhost ($acct) ++'d locked '$item' in $chan - score: $lockedk"
      } elseif {[string match "--" $score]} {
          puthelp "PRIVMSG $karma(logchan) :\[karma\] $nick!$uhost ($acct) --'d locked '$item' in $chan - score: $lockedk" 
      }
        return 0
    }

    if {![info exists kfcount($uhost)]} {
      set kfcount($uhost) 0
    }

    if {$kfcount($uhost) == [lindex $kfflood 0]} {
      puthelp "NOTICE $nick :please dont flood the karmabot, $nick. try again later."
      if {[string match "++" $score]} {
          puthelp "PRIVMSG $karma(logchan) :\[karma\] *ignored - flood* $nick!$uhost ($acct) ++'d '$item' in $chan"
      } elseif {[string match "--" $score]} {
          puthelp "PRIVMSG $karma(logchan) :\[karma\] *ignored - flood* $nick!$uhost ($acct) --'d '$item' in $chan" 
      }
      return 0
    }

    # check if it was likely a command to another bot
    #if {[string index $text 0] == "!"} {
    #    if {[string match "++" $score]} {
    #        puthelp "PRIVMSG $karma(logchan) :\[karma\] *ignored - starts with !* $nick!$uhost ($acct) ++'d '$item' in $chan"
    #    } elseif {[string match "--" $score]} {
    #        puthelp "PRIVMSG $karma(logchan) :\[karma\] *ignored - starts with !* $nick!$uhost ($acct) --'d '$item' in $chan" 
    #    }
    #    return 0
    #}

    # ignore karma requests from bots
    set accthand [finduser -account [getaccount $nick]]
    if {[string match $accthand "*"]} {
	    # not needed once eggdrop adds support for nickserv account to nick2hand
	    set accthand [nick2hand $nick]
    }
    if {![string match $accthand "*"]} {
        if {[matchattr $accthand +B]} {
            if {[string match "++" $score]} {
                puthelp "PRIVMSG $karma(logchan) :\[karma\] *ignored - is a known bot* $nick!$uhost ($acct) ++'d '$item' in $chan"
           } elseif {[string match "--" $score]} {
               puthelp "PRIVMSG $karma(logchan) :\[karma\] *ignored - is a known bot* $nick!$uhost ($acct) --'d '$item' in $chan" 
           }
           return 0
        }
    }
    
    incr kfcount($uhost)
    set ktime [clock seconds]
    
    if {[llength [kdb eval {SELECT karma FROM lkarma WHERE item=$item}]] == 0} {
      kdb eval {INSERT INTO lkarma (item,karma,modtime) VALUES ($item,0,$ktime)}
    } 
    
    if {[kdb eval {SELECT karma FROM lkarma WHERE item=$item}] < 900} {
      kdb eval {UPDATE lkarma SET karma=karma+$scoring, modtime=$ktime WHERE item=$item}
    } { 
      kdb eval {UPDATE lkarma SET karma=karma+$scoring WHERE item=$item}
    }
    set newkarma [kdb eval {SELECT karma FROM lkarma WHERE item=$item}]
    puthelp "NOTICE $chan :\[karma\] '$item' now has $newkarma karma!"
    if {[string match "++" $score]} {
        puthelp "PRIVMSG $karma(logchan) :\[karma\] $nick!$uhost ($acct) ++'d '$item' in $chan - new score: $newkarma"
    } elseif {[string match "--" $score]} {
        puthelp "PRIVMSG $karma(logchan) :\[karma\] $nick!$uhost ($acct) --'d '$item' in $chan - new score: $newkarma" 
    }
    kdb close 
  }
}

###Other Commands###

bind pub $karma(flags) !khelp karmahelp
proc karmahelp {nick uhost hand chan text} {
  if {[string match "*+lkarma*" [channel info $chan]]} {
    if {![string match "" $text]} {return 0}
    puthelp "NOTICE $chan :\[karma\] you may \"<item>++\" and \"<item>--\" any word or phrase. \"!kbest\" and \"!kworst\" return the top (and bottom) ten. \"!karma \[item\]\" to look up individual scores. \"!kstats\" for statistics. Use \"!kfind <item>\" and \"!krfind <item>\" to search for things in the database ordered by karma in ascending or descending order (respectively), or just use \"!krand\" for ten random things."
  }
}

bind pub $karma(flags) !karma checkkarma
proc checkkarma {nick uhost hand chan text} {
  if {[regexp -nocase {(.*)(\+\+|\-\-)$} $text]} {return 0}
  if {[string match "*+lkarma*" [channel info $chan]]} {
    global karma kdbfile
    if {[string match "" $text]} {
      set text $nick
    } 
    set item [string trim $text]
    sqlite3 kdb $kdbfile
    set current [kdb eval {SELECT karma FROM lkarma WHERE item=$item}]
    if {[llength $current] == 0} {
      set current 0
    } 
    if {[kdb eval {SELECT locked FROM lkarma WHERE item=$item}] == "Y"} {
      puthelp "NOTICE $chan :\[karma\] \"$item\"\ is locked at \002$current\002."
    } else {
      puthelp "NOTICE $chan :\[karma\] \"$item\" has $current karma"
    }
    if {[kdb eval {SELECT locked FROM lkarma WHERE item=$item}] == "U"} {
        puthelp "NOTICE $chan :\[karma\] \"$item\" has been immortalized"
    }  
    kdb close
  }
}

bind pub $karma(flags) !kstats karmastats
proc karmastats {nick uhost hand chan text} {
  if {![string match "" $text]} {return 0}
  global karma kdbfile
  if {[string match "*+lkarma*" [channel info $chan]]} {
    sqlite3 kdb $kdbfile
    set lcount [kdb eval {SELECT COUNT(*) FROM lkarma WHERE locked='Y'}]
    set ucount [kdb eval {SELECT COUNT(*) FROM lkarma WHERE locked='U'}]
    set gcount [kdb eval {SELECT COUNT(*) FROM lkarma WHERE karma > 0 AND locked='N'}]
    set bcount [kdb eval {SELECT COUNT(*) FROM lkarma WHERE karma < 0 AND locked='N'}]
    set total [kdb eval {SELECT COUNT(*) FROM lkarma}]
    set average [kdb eval {SELECT AVG(karma) FROM lkarma WHERE locked='N'}] 
    set average [expr round($average)]
    puthelp "NOTICE $chan :\[karma\] stats: $total items in the database. good: $gcount, bad: $bcount, average karma: $average" 
    kdb close 
  }
}

bind pub $karma(flags) !kbest goodkarma
bind pub $karma(flags) !ktop goodkarma
proc goodkarma {nick uhost hand chan text} {
  if {![string match "" $text]} {return 0}
  global karma kdbfile
  if {[string match "*+lkarma*" [channel info $chan]]} {
    sqlite3 kdb $kdbfile
    foreach {item score} [kdb eval {SELECT item,karma FROM lkarma WHERE locked='N' ORDER BY karma DESC, item ASC LIMIT 0,10} ] {
      append outvar "$item: $score  "
    }
    puthelp "NOTICE $chan :\[karma\] $outvar"
    kdb close
  }
}

bind pub $karma(flags) !kworst badkarma
bind pub $karma(flags) !kbottom badkarma
proc badkarma {nick uhost hand chan text} {
  if {![string match "" $text]} {return 0}
  global karma kdbfile
  if {[string match "*+lkarma*" [channel info $chan]]} {
    sqlite3 kdb $kdbfile
    foreach {item score} [kdb eval {SELECT item,karma FROM lkarma WHERE locked='N' ORDER BY karma ASC, item ASC LIMIT 0,10}] {
      append outvar "$item: $score  "
    }
    puthelp "NOTICE $chan :\[karma\] $outvar"
    kdb close
  }
}

#bind pub $karma(flags) !lfind lockedkarma
#bind pub $karma(flags) !lkarma lockedkarma
#proc lockedkarma {nick uhost hand chan text} {
#  if {![string match "" $text]} {return 0}
#  global karma kdbfile
#  if {[string match "*+lkarma*" [channel info $chan]]} {
#    sqlite3 kdb $kdbfile
#    set lcount [kdb eval {SELECT COUNT(*) FROM lkarma WHERE locked='Y'}]
#    if {$lcount != 0} { 
#      foreach {item score} [kdb eval {SELECT item,karma FROM lkarma WHERE locked='Y' ORDER BY karma DESC} ] {
#        append outvar "$item:\002$score\002  "
#      }
#      puthelp "NOTICE $chan :\[karma\] \002$lcount\002 locked items: $outvar"
#    } { 
#      puthelp "NOTICE $chan :\[karma\] there are no locked items."
#    }
#    kdb close
#  }
#}
#
#bind pub $karma(flags) !ifind immkarma
#bind pub $karma(flags) !ikarma immkarma
#proc immkarma {nick uhost hand chan text} {
#  if {![string match "" $text]} {return 0}
#  global karma kdbfile
#  if {[string match "*+lkarma*" [channel info $chan]]} {
#    sqlite3 kdb $kdbfile
#    set icount [kdb eval {SELECT COUNT(*) FROM lkarma WHERE locked='U'}]
#    if {$icount != 0} { 
#       foreach {item score} [kdb eval {SELECT item,karma FROM lkarma WHERE locked='U' ORDER BY karma DESC} ] {
#        append outvar "$item:\002$score\002  "
#      }
#      puthelp "NOTICE $chan :\[karma\] \002$icount\002 immortal items: $outvar"
#    } { 
#      puthelp "NOTICE $chan :\[karma\] there are no immortal items."
#    } 
#    kdb close
#  }
#}

bind pub $karma(flags) !krand randkarma
proc randkarma {nick uhost hand chan text} {
  if {![string match "" $text]} {return 0}
  global karma kdbfile
  if {[string match "*+lkarma*" [channel info $chan]]} {
    sqlite3 kdb $kdbfile
    foreach {item score} [kdb eval {SELECT item,karma FROM lkarma WHERE locked='N' ORDER BY RANDOM() LIMIT 10} ] {
      append outvar "$item: $score  "
    }
    puthelp "NOTICE $chan :\[karma\] $outvar"
    kdb close
  }
}

#bind pub $karma(flags) !instant instantkarma
#proc instantkarma {nick uhost hand chan text} {
#  return 0
#  if {![string match "" $text]} {return 0}
#  global karma kdbfile kfcount kfflood
#  if {[string match "*+lkarma*" [channel info $chan]]} {
#    set uhost [string tolower $uhost]
#    set chan [string tolower $chan]    
#    sqlite3 kdb $kdbfile
#    if {![info exists kfcount($uhost:$chan)]} {
#      set kfcount($uhost:$chan) 0
#    }
#    if {$kfcount($uhost:$chan) == [lindex $kfflood 0]} {
#      puthelp "PRIVMSG $chan :Please dont flood karma, $nick, try again later."
#      return 0
#    }
#    incr kfcount($uhost:$chan)    
#    lappend choices "+1" "-1"
#    set scoring [lindex $choices [expr {int(rand()*[llength $choices])}]]
#    putlog "$scoring instant karma randomly selected"
#    sqlite3 kdb $kdbfile
#    set ktime [clock seconds]
#    set rando [kdb onecolumn {SELECT item FROM lkarma WHERE locked='N' ORDER BY RANDOM() LIMIT 1}]
#    kdb eval {UPDATE lkarma SET karma=karma+$scoring, modtime=$ktime WHERE item=$rando}
#    set newkarma [kdb eval {SELECT karma FROM lkarma WHERE item=$rando}]
#    puthelp "PRIVMSG $chan :Karma for \002$rando\002 is now \002$newkarma\002."     
#    kdb close
#  }
#}

bind pub $karma(flags) !kfind findkarma
proc findkarma {nick uhost hand chan text} {
  if {[regexp -nocase {(.*)(\+\+|\-\-)$} $text]} {return 0}
  if {[string match "*+lkarma*" [channel info $chan]]} {
    global karma kdbfile
    if {[string match "" $text]} {
      puthelp "NOTICE $chan :What should be found?"
    } {
      sqlite3 kdb $kdbfile
      set word [string trim $text]
      set spatrn "%$word%"
      set scount [kdb eval {SELECT COUNT(1) FROM lkarma WHERE item LIKE $spatrn}]
      if {$scount == 0 } {
        puthelp "NOTICE $chan :\[karma\] '$word' not found."
      } {
        if {$scount < 9 } {
          foreach {item score} [kdb eval {SELECT item,karma FROM lkarma WHERE item LIKE $spatrn ORDER BY karma DESC LIMIT 0,9}] {
            append sreturn "$item: '$score'  "
          }          
          puthelp "NOTICE $chan :\[karma\] $scount matches for '$word': $sreturn" 
        } {
            foreach {item score} [kdb eval {SELECT item,karma FROM lkarma WHERE item LIKE $spatrn ORDER BY karma DESC LIMIT 0,10}] {
            append spos "$item: $score  "
          }
          puthelp "NOTICE $chan :\[karma\] $scount matches for '$word'. top 10 matches: $spos"
        }
      }
      kdb close 
    }
  }
}

bind pub $karma(flags) !krfind rfindkarma
proc rfindkarma {nick uhost hand chan text} {
  if {[regexp -nocase {(.*)(\+\+|\-\-)$} $text]} {return 0}
  if {[string match "*+lkarma*" [channel info $chan]]} {
    global karma kdbfile
    if {[string match "" $text]} {
      puthelp "NOTICE $chan :\[karma\] what should be found?"
    } {
      sqlite3 kdb $kdbfile
      set word [string trim $text]
      set spatrn "%$word%"
      set scount [kdb eval {SELECT COUNT(1) FROM lkarma WHERE item LIKE $spatrn}]
      if {$scount == 0 } {
        puthelp "NOTICE $chan :\[karma\] '$word' not found"
      } {
        if {$scount < 9 } {
          foreach {item score} [kdb eval {SELECT item,karma FROM lkarma WHERE item LIKE $spatrn ORDER BY karma ASC LIMIT 0,9}] {
            append sreturn "$item: $score  "
          }          
          puthelp "NOTICE $chan :\[karma\] $scount matches for '$word': $sreturn" 
        } {
          foreach {item score} [kdb eval {SELECT item,karma FROM lkarma WHERE item LIKE $spatrn ORDER BY karma ASC LIMIT 0,10}] {
            append sneg "$item: $score  "
          }
          puthelp "NOTICE $chan :\[karma\] $scount matches for '$word'. bottom 10 matches: $sneg" 
        }
      }
      kdb close 
    }
  }
}

#bind pub $karma(lockflags) !lock lockkarma
#proc lockkarma {nick uhost hand chan text} {
#  if {[regexp -nocase {(.*)(\+\+|\-\-)$} $text]} {return 0}
#  global karma kdbfile
#  if {[string match "*+lkarma*" [channel info $chan]]} {
#    set item [string trim $text]
#    if {$item == ""} {
#      puthelp "NOTICE $chan :\[karma\] what should be locked?"
#      return
#    }
#    sqlite3 kdb $kdbfile
#    if {[llength [kdb eval {SELECT locked FROM lkarma WHERE item=$item}]] == 0} {
#      puthelp "NOTICE $chan :\[karma\] \002$item\002 is not in the database."
#    } {
#      if {[kdb eval {SELECT locked FROM lkarma WHERE item=$item}] != "N"} {
#        puthelp "NOTICE $chan :\[karma\] \002$item\002 is already locked."
#      } {
#        kdb eval {UPDATE lkarma SET locked='Y' WHERE item=$item}
#        puthelp "NOTICE $chan :\[karma\] \002$item\002 locked."
#      }
#    }
#    kdb close
#  }
#}
#
#bind pub $karma(lockflags) !unlock unlockkarma
#proc unlockkarma {nick uhost hand chan text} {
#  if {[regexp -nocase {(.*)(\+\+|\-\-)$} $text]} {return 0}
#  global karma kdbfile
#  if {[string match "*+lkarma*" [channel info $chan]]} {
#    set item [string trim $text]
#    if {$item == ""} {
#      puthelp "NOTICE $chan :\[karma\] what should be unlocked?"
#      return
#    }
#    sqlite3 kdb $kdbfile
#    if {[llength [kdb eval {SELECT locked FROM lkarma WHERE item=$item}]] == 0} {
#      puthelp "NOTICE $chan :\[karma\] \002$item\002 is not in the database."
#    } {
#      if {[kdb eval {SELECT locked FROM lkarma WHERE item=$item}] != "Y"} {
#        puthelp "NOTICE $chan :\[karma\] \002$item\002 is not locked."
#      } {
#        kdb eval {UPDATE lkarma SET locked='N' WHERE item=$item}
#        puthelp "NOTICE $chan :\[karma\] \002$item\002 unlocked."
#      }
#    }
#    kdb close
#  }
#}
#
#bind pub $karma(lockflags) !immortalize immortkarma
#proc immortkarma {nick uhost hand chan text} {
#  if {[regexp -nocase {(.*)(\+\+|\-\-)$} $text]} {return 0}
#  global karma kdbfile
#  if {[string match "*+lkarma*" [channel info $chan]]} {
#    set item [string trim $text]
#    if {$item == ""} {
#      puthelp "NOTICE $chan :\[karma\] what should be immortalized?"
#      return
#    }
#    sqlite3 kdb $kdbfile
#    if {[llength [kdb eval {SELECT locked FROM lkarma WHERE item=$item}]] == 0} {
#      puthelp "NOTICE $chan :\[karma\] \002$item\002 is not in the database."
#    } {
#      if {[kdb eval {SELECT locked FROM lkarma WHERE item=$item}] == "U"} {
#        puthelp "NOTICE $chan :\[karma\] \002$item\002 is already immortalized."
#      } {
#        kdb eval {UPDATE lkarma SET locked='U' WHERE item=$item}
#        puthelp "NOTICE $chan :\[karma\] \002$item\002 immortalized!"
#      }
#    }
#    kdb close
#  }
#}
#
#bind pub $karma(deleteflags) !delete deletekarma
#proc deletekarma {nick uhost hand chan text} {
#  if {[regexp -nocase {(.*)(\+\+|\-\-)$} $text]} {return 0}
#  global karma kdbfile
#  if {[string match "*+lkarma*" [channel info $chan]]} {
#    set item [string trim $text]
#    if {$item == ""} {
#      puthelp "NOTICE $chan :\[karma\] what should be deleted?"
#      return
#    }
#    sqlite3 kdb $kdbfile
#    if {[llength [kdb eval {SELECT item FROM lkarma WHERE item=$item}]] == 0} {
#      puthelp "NOTICE $chan :\[karma\] \002$item\002 is not in the database."
#    } {
#      if {[kdb eval {SELECT locked FROM lkarma WHERE item=$item}] != "N"} {
#        puthelp "NOTICE $chan :\[karma\] \002$item\002 can't be deleted."
#      } {
#        kdb eval {DELETE FROM lkarma WHERE item=$item}
#        puthelp "NOTICE $chan :\[karma\] \002$item\002 deleted."
#      }  
#    }
#    kdb close
#  }
#}

####TIMER CODE###

# removed call to this everything above for now, i don't like the karma fuzzing... the 'delete stuff at 0 karma for X days' could be interesting, though.
# was just going to wholesale remove that until I saw that lol
proc karmaupdate {} {
  return 0
#  global kdbfile
#  sqlite3 kdb $kdbfile
#  set kutime [clock seconds]
## plus/minus 1 to 5 days to kutime at random here? or in each loop? 
#
#  set xtime [expr $kutime - (90 * 86400)]
#  kdb eval {DELETE FROM lkarma WHERE modtime < $xtime AND karma between -1 and 1 and locked='N'}
#  kdb eval {UPDATE lkarma SET karma=karma-1, modtime=$kutime WHERE modtime < $xtime AND karma between 2 and 22 AND locked='N'}
#  kdb eval {UPDATE lkarma SET karma=karma+1, modtime=$kutime WHERE modtime < $xtime AND karma between -22 and -2 AND locked='N'}
#
#  set ytime [expr $kutime - (30 * 86400)]
#  kdb eval {UPDATE lkarma SET karma=karma-1, modtime=$kutime WHERE modtime < $ytime AND karma between 23 and 54 AND locked='N'}
#  kdb eval {UPDATE lkarma SET karma=karma+1, modtime=$kutime WHERE modtime < $ytime AND karma between -54 and -23 AND locked='N'}
#
#  set yytime [expr $kutime - (7 * 86400)]
#  kdb eval {UPDATE lkarma SET karma=karma-1, modtime=$kutime WHERE modtime < $yytime AND karma between 55 and 80 AND locked='N'}
#  kdb eval {UPDATE lkarma SET karma=karma+1, modtime=$kutime WHERE modtime < $yytime AND karma between -80 and -55 AND locked='N'} 
#
#  set yyytime [expr $kutime - (2 * 86400)]
#  kdb eval {UPDATE lkarma SET karma=karma-1, modtime=$kutime WHERE modtime < $yyytime AND karma between 81 and 120 AND locked='N'}
#  kdb eval {UPDATE lkarma SET karma=karma+1, modtime=$kutime WHERE modtime < $yyytime AND karma between -120 and -81 AND locked='N'}  
#
#  set ztime [expr $kutime - 86400]
#  kdb eval {UPDATE lkarma SET karma=karma-1, modtime=$kutime WHERE modtime < $ztime AND karma between 121 and 540 AND locked='N'}
#  kdb eval {UPDATE lkarma SET karma=karma+1, modtime=$kutime WHERE modtime < $ztime AND karma between -540 and -121 AND locked='N'}
#  
#    set zztime [expr $kutime - (86400 / 3)]
#  kdb eval {UPDATE lkarma SET karma=karma-1, modtime=$kutime WHERE modtime < $zztime AND karma between 541 and 959 AND locked='N'}
#  kdb eval {UPDATE lkarma SET karma=karma+1, modtime=$kutime WHERE modtime < $zztime AND karma between -959 and -541 AND locked='N'}
#
#    set zzztime [expr $kutime - (86400 / 5)]
#  kdb eval {UPDATE lkarma SET karma=karma-1, modtime=$kutime WHERE modtime < $zzztime AND karma > 960 AND locked='N'}
#  kdb eval {UPDATE lkarma SET karma=karma+1, modtime=$kutime WHERE modtime < $zzztime AND karma < -960 AND locked='N'}
#    
#  kdb close 
}

proc kfreset {} {
  global kfcount kfflood
  if {[info exists kfcount]} {
    unset kfcount
  }
  utimer [lindex $kfflood 1] kfreset
}

if {![string match *kfreset* [utimers]]} {
  global kfflood
  utimer [lindex $kfflood 1] kfreset
}
set kfflood [split $kfflood :]


putlog "LilyKarma $karma(version) loaded."
