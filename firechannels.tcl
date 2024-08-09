bind join * "#fire-channels *" firechansonjoin

proc firechansonjoin {nick uhost hand chan} {
	global botnick
	if {[getaccount $nick] == "fireonlive"} {
		return 0
	}
	if {[getaccount $nick] == "eggdrop"} {
		return 0
	}

	if {$nick == "ChanServ"} {
		return 0
	}
	putquick "NOTICE $nick :one moment please..."
	putquick "INVITE $nick #0dayinitiative"
	putquick "INVITE $nick #afterdark"
	putquick "INVITE $nick #ai"
	putquick "INVITE $nick #archiveteam-twitter"
	putquick "INVITE $nick #datahoarders"
	putquick "INVITE $nick #fire-spam"
	putquick "INVITE $nick #fulldisclosure"
	putquick "INVITE $nick #hackernews"
	putquick "INVITE $nick #hackernews-firehose"
	putquick "INVITE $nick #infosec"
	putquick "INVITE $nick #intenttoship"
	putquick "INVITE $nick #m&a"
	putquick "INVITE $nick #memes"
	putquick "INVITE $nick #music"
	putquick "INVITE $nick #nanog"
	putquick "INVITE $nick #oss-security"
	putquick "INVITE $nick #pki"
	putquick "INVITE $nick #reddark"
	putquick "INVITE $nick #web3"
	putquick "NOTICE $nick :done! to subscribe to future channel changes please /msg $botnick chsub"
	putquick "KICK $chan $nick :check your invites!"
	newchanban $chan *!$uhost eggdrop "check your invites!" 1 sticky
}

bind MSG * chsub chsub

proc chsub {nick uhost hand text} {
    if {[getaccount $nick] == "*"} {
      putserv "NOTICE $nick :sorry $nick, you are not authenticated to NickServ"
      putserv "PRIVMSG #fire :\[chsub\] $nick!$uhost attempted to subscribe, but isn't auth'd with services"
      return 1
    } 
    if {[getaccount $nick] == ""} {
      putserv "NOTICE $nick :sorry $nick, you are not authenticated to NickServ"
      putserv "PRIVMSG #fire :\[chsub\] $nick!$uhost attempted to subscribe, but isn't auth'd with services"
      return 1
    } 
    putserv "NOTICE $nick :thanks! you've been added to the list"
    putserv "PRIVMSG #fire :\[chsub\] $nick!$uhost ([getaccount $nick]) subscribed to the channel changes list"

}
