# Ensure the http package is available
package require http
package require tls
package require json
package require Tcl 8.6

bind pub - "!nitterstatus" nitterStatus

proc nitterStatus {nick host handle chan text} {
	# URL from where to fetch the JSON data
	set url "https://nitter.vloup.ch/.health"

	# Performing the HTTP GET request
	set data [exec curl -sS $url]
	#set data [http::data $response]
	#http::cleanup $response

	# Assuming the response data is stored in `data` variable and is the JSON string
	set jsonData [json::json2dict $data]

	# Continue as before
	set total [dict get $jsonData accounts total]
	set limited [dict get $jsonData accounts limited]
	set oldest [dict get $jsonData accounts oldest]
	set average [dict get $jsonData accounts average]
	set newest [dict get $jsonData accounts newest]

	# Function to convert date-time from local to UTC
	proc convertToUTC {dateTime} {
	    set utcTime [clock scan $dateTime -format "%Y-%m-%dT%H:%M:%S%z"]
	    set utcTime [clock format $utcTime -format "%Y-%m-%dT%H:%M:%SZ" -gmt 1]
	    return $utcTime
	}

	# Converting dates to UTC
	set oldestUTC [convertToUTC $oldest]
	set averageUTC [convertToUTC $average]
	set newestUTC [convertToUTC $newest]

	# Creating the desired output string
	putserv "PRIVMSG $chan :\[AT/nitter/status\] accounts remaining: $total, limited accounts $limited, oldest: $oldestUTC, average: $averageUTC, newest: $newestUTC"
}
