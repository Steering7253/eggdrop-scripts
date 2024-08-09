bind mode - * modeCacheFix

proc modeCacheFix {nick uhost hand chan mchange target} {
	if {$chan == "#fire-acl"} {
		if {([string match "*b*" $mchange]) || ([string match "*q*" $mchange])} {
			putlog "\[modeCacheFix\] $nick!$uhost ($hand) in $chan set $mchange $target, clearing cache on all channels.."
			foreach chann [channels] {
				if {($chann != "#fire-acl") && ([botisop $chann])} {
					putquick "MODE $chann +e-e *!*@invalidating-bants-cache *!*@invalidating-bants-cache"
				}
			}
		}
	}
}
