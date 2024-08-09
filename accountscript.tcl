bind PUB * ,op acct_op

proc acct_op {nick user hand chan text} {
    set accthand [finduser -account [getaccount $nick]]
    if [string match $accthand "*"] {
      putserv "PRIVMSG $chan :$nick, you are not authenticated to NickServ and/or I don't know you!"
      return 1
    }
    if {[matchattr $accthand +o|+o $chan]} {
      pushmode $chan +o $text
      putserv "PRIVMSG $chan :ok"
    } else {
      putserv "PRIVMSG $chan :$nick, you do not have access to ,op"
    }
}


bind PUB * ,masskick acct_masskick

proc acct_masskick {nick user hand chan text} {
    set accthand [finduser -account [getaccount $nick]]
    if [string match $accthand "*"] {
      putserv "PRIVMSG $chan :$nick, you are not authenticated to NickServ and/or I don't know you!"
      return 1
    }
    if {[matchattr $accthand +o $chan]} {
      if {$text == ""} {
          putserv "PRIVMSG $chan :\[masskick\] usage: ,masskick <nick>"
          return 1
      }
      putserv "PRIVMSG $chan :\[masskick\] starting..."
      foreach chann [channels] {
          if {([botisop $chann]) && ([onchan $text $chann])} {
              putkick $chann $text "Your behaviour is not conducive to the desired environment."
              puthelp "PRIVMSG $chan :\[masskick\] kicked $text from $chann"
          }
      }
      puthelp "PRIVMSG $chan :\[masskick\] done"
    } else {
      putserv "PRIVMSG $chan :$nick, you do not have access to ,masskick"
    }
}

bind PUB * ,whoami acct_whoami

proc acct_whoami {nick user hand chan text} {
    set acct [getaccount $nick]
    set accthand [finduser -account $acct]
    if [string match $acct ""] {
      putserv "PRIVMSG $chan :idk"
      return 1
    }
    putserv "PRIVMSG $chan :$nick: you're authenticated to NickServ as $acct"
    if [string match $accthand ""] {
        putserv "PRIVMSG $chan :$nick: '$acct' isn't a known user to me, though."
    } else {
        putserv "PRIVMSG $chan :$nick: hi! '$acct' is also a known user to me! (flags: [chattr $accthand * $chan])"
    }
}

bind PUB * ,whois acct_whois

proc acct_whois {nick user hand chan text} {
    set search [string trim $text]
    if {$search == ""} {
        putserv "PRIVMSG $chan :gimmie someone to whois lol"
	return 1
    }
    if {[isbotnick $search]} {
        putserv "PRIVMSG $chan :hi! i'm eggdrop :3 (fireonlive thinks he owns me, but I actually own him)"
	return 1
    }
    set acct [getaccount $search]
    set accthand [finduser -account $acct]
    if [string match $acct "*"] {
      putserv "PRIVMSG $chan :idk"
      return 1
    }
    putserv "PRIVMSG $chan :$search is authenticated to NickServ as $acct"
    if [string match $accthand ""] {
        putserv "PRIVMSG $chan :$acct isn't a known user to me, though."
    } else {
        putserv "PRIVMSG $chan :$acct is also a known user to me! (flags: [chattr $accthand * $chan])"
    }
}

bind PUB * ,join acct_join

proc acct_join {nick user hand chan text} {
    set accthand [finduser -account [getaccount $nick]]
    if [string match $accthand "*"] {
      putserv "PRIVMSG $chan :$nick, you are not authenticated to NickServ and/or I don't know you!"
      return 1
    }
    if {[matchattr $accthand +o]} {
      channel add [string trim $text]
      channel set [string trim $text] +lkarma +transferinliner +seen +8ball
      putquick "PRIVMSG $chan :\[join\] joined [string trim $text] - set flags +lkarma +transferinliner +seen +8ball"
      savechannels
    } else {
      putserv "PRIVMSG $chan :$nick, you do not have access to ,join"
    }
}

bind MSG * join acct_join_pm

proc acct_join_pm {nick user hand text} {
    set accthand [finduser -account [getaccount $nick]]
    if [string match $accthand "*"] {
      putserv "NOTICE $nick :you are not authenticated to NickServ and/or I don't know you!"
      return 1
    }
    if {[matchattr $accthand +o]} {
      channel add [string trim $text]
      channel set [string trim $text] +lkarma +transferinliner +seen +8ball +nitter
      putquick "NOTICE $nick :\[join\] joined [string trim $text] - set flags +lkarma +transferinliner +seen +8ball +nitter"
      putquick "PRIVMSG #fire-trail :\[join\] $nick ($accthand) requested join [string trim $text]. joined and set flags +lkarma +transferinliner +seen +8ball +nitter"
      savechannels
    } else {
      putserv "NOTICE $nick :you do not have access to join"
    }
}
bind PUB * ,chflags acct_chflags
bind PUB * ,chanset acct_chflags

proc acct_chflags {nick user hand chan text} {
    set accthand [finduser -account [getaccount $nick]]
    if [string match $accthand "*"] {
      putserv "PRIVMSG $chan :$nick, you are not authenticated to NickServ and/or I don't know you!"
      return 1
    }
    if {[matchattr $accthand +o]} {
        set target [lindex [split $text] 0]
        set flags [join [lrange [split $text] 1 end] " "]
        channel set $target $flags
        putquick "PRIVMSG $chan :\[chanset\] set flags \"$flags\" for $target"
        savechannels
    } else {
      putserv "PRIVMSG $chan :$nick, you do not have access to ,chflags"
    }
}
