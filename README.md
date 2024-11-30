## Wat is

fireonlive's eggdrop scripts for AT

## How do

```
set m00nie::youtube::key "youtube api key"
##### SCRIPTS #####

# This is a good place to load scripts to use with your bot.

# This line loads script.tcl from the scripts directory inside your Eggdrop's
# directory. All scripts should be put there, although you can place them where
# you like as long as you can supply a fully qualified path to them.
#
# source scripts/script.tcl

source scripts/alltools.tcl
#source scripts/action.fix.tcl

# This script enhances Eggdrop's built-in dcc '.whois' command to allow all
# users to '.whois' their own handle.
source scripts/dccwhois.tcl

# This script provides many useful informational functions, like setting
# users' URLs, e-mail address, ICQ numbers, etc. You can modify it to add
# extra entries.
#source scripts/userinfo.tcl
#loadhelp userinfo.help

source scripts/forwardedSpamProtection.tcl
source scripts/twitter2nitter.tcl
source scripts/transferinliner.tcl
source scripts/accountscript.tcl
source scripts/tcl.tcl
source scripts/lilykarma.tcl
source scripts/tell.tcl
source scripts/atme.tcl
source scripts/remind.tcl
source scripts/pixseen/pixseen.tcl
source scripts/8ball.tcl
source scripts/fix-solanum-ban-caching.tcl
source scripts/atmisc.tcl
#source scripts/bmotion/bMotion.tcl
source scripts/archivebot-chat.tcl
source scripts/down-the-tube-chat.tcl
source scripts/telegrab-chat.tcl
source scripts/youtube.tcl
```
