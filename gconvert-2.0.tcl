#############################################
#  gconvert.tcl v2.0       by AkiraX        #
#                    <#AnimeFiends@EFNet>   #
#############################################

####### DESCRIPTION #########################
# Uses the google calculator to perform
# conversions and mathematics
#############################################

####### USAGE ###############################
# !convert <quantity> to <quantity>
# !math <equation> : perform mathematics
# !calc <equation> : same as !math
#############################################

####### CHANGELOG ###########################
# v2.0 : allow convert code to perform math
# v1.0 : support for google conversions
#############################################

####### LICENSE ############################# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, U
#############################################

package require http

bind pub -|- !convert gconvert:math
proc gconvert:run { nick host handle chan text } {
	set convert(nick) [join [lrange [split $nick] 0 0]]
	set convert(input) [join [lrange [split $text] 0 end]]

	# create google URL
	set token [http::config -useragent "Mozilla"]
	set convert(url) [gconvert:webstring "convert $convert(input)"]
	set convert(url) "http://www.google.com/search?hl=en&q=$convert(url)"

	set num_tries 0
	set try_again 1
	while { $try_again } {
		incr num_tries
		if { $num_tries > 3 } {
			set try_again 0
			break
		}

		# grab the info from google
		set token [http::geturl $convert(url) -timeout 15000]
		upvar #0 $token state
		if { $state(status) == "timeout" } {
			puthelp "PRIVMSG $chan :Sorry, your request timed out."
			return
		}
		set convert(html) [split [http::data $token] "\n"]
		http::cleanup $token

		# find the answer
		set num_lines 0
		set convert(answer) ""
		foreach line $convert(html) {
			incr num_lines
			if { $num_lines > 100 } {
				set try_again 0
				break
			}

			# take suggestions
			if { [regexp {Did you mean:} $line] } {
				# grab the new URL and start over
				regexp {Did you mean: </font><a href=(.*?) class=p>} $line match convert(url)
				set convert(url) "http://www.google.com$convert(url)"
				break
			}

			# find the calculator
			if { [regexp {src=/images/calc_img.gif} $line] } {
				regexp {src="/images/icons/onebox/calculator-40.gif".*<h2.*?><b>(.*?)</b></h2>} $line match convert(answer)
				regexp {<b>(.*?)</b>} $convert(answer) match convert(answer)
				set try_again 0
				break
			}
		}
	}

	if { $convert(answer) == "" } {
		puthelp "PRIVMSG $chan :Sorry, didn't work out."
		return
	}

	puthelp "PRIVMSG $chan :[gconvert:gstring $convert(answer)]"

	return
}

bind pub -|- !math gconvert:math
bind pub -|- !calc gconvert:math
proc gconvert:math { nick host handle chan text } {
	set calc(nick) [join [lrange [split $nick] 0 0]]
	set calc(input) [join [lrange [split $text] 0 end]]

	# create google URL
	set token [http::config -useragent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/535.2 (KHTML, like Gecko) Ubuntu/11.04 Chromium/15.0.871.0 Chrome/15.0.871.0 Safari/535.2"]
	set calc(url) [gconvert:webstring "$calc(input)"]
	set calc(url) "http://www.google.dk/search?hl=en&q=$calc(url)"
#	putlog "$calc(url)"
	set num_tries 0
	set try_again 1
	while { $try_again } {
		incr num_tries
#		putlog "$num_tries"
		if { $num_tries > 5 } {
			set try_again 0
			putlog "max tries"
			break
		}

		# grab the info from google
		set token [http::geturl $calc(url) -timeout 15000]
		upvar #0 $token state
		if { $state(status) == "timeout" } {
			puthelp "PRIVMSG $chan :Sorry, your request timed out."
			return
		}
		set calc(html) [split [http::data $token] "\n"]
		http::cleanup $token

		# find the answer
		set num_lines 0
		set calc(answer) ""
		foreach line $calc(html) {
			incr num_lines
			if { $num_lines > 1000 } {
				set try_again 0
				putlog "line max reached: $num_lines"
				break
			}
			
			# Find flight info
			if { [regexp {<a.href.*(Track.status.of.*)www\.flightstats\.com} $line match grab] } {
				regexp {Track status of [<b>]?(.*)</b> from (.*)\)</a></h3><tr><td.*"margin: 2px 0pt;">(.*)<br>(.*)<br><span class} $grab match flight route date dep arr
				putlog $grab
				#				regexp {>Track status of <b>(.*)</b>(.*)</a></h3></td></tr><tr>.*div style="margin: 1px 0pt;">(.*)<br>(.*)<br><font class="a">} $line match a b c d 
#				putlog "$flight $route $date $dep $arr"
				set calc(answer) "Track status of $flight: From $route) $date. $dep $arr"
				set try_again 0
				break
			}
			# Find weather info
			if { [regexp {class=\"?med\"?><b>Weather</b>} $line] } {
				regexp {<b>Weather</b> for <b>([a-zA-Z0-9, ]*)</b></div><div style=.*<b>([-0-9°C]*)</b>.*</div><div>Current: <b>(.*)</b>.*(Wind:.*h)?<br>(Humidity:.*\%).*>([0-9a-zA-Z]*)<br><img.*alt=.*title="([0-9a-zA-Z ]*)" width.*<nobr>([-0-9°C |]*)</nobr>.*>([0-9a-zA-Z]*)<br><img.*alt=.*title="([0-9a-zA-Z ]*)" width.*<nobr>([-0-9°C |]*)</nobr>.*>([0-9a-zA-Z]*)<br><img.*alt=.*title="([0-9a-zA-Z ]*)" width.*<nobr>([-0-9°C |]*)</nobr>.*>([0-9a-zA-Z]*)<br><img.*alt=.*title="([0-9a-zA-Z ]*)" width.*<nobr>([-0-9°C |]*)</nobr>} $line match a b c d e f g h i j k l m n o p q
				# \037 is irssi underline, \002 is bold
				set calc(answer) "Weather in \037$a\037: \002Now\002: $b, $c, $d, $e. \002$f\002: $g, $h. \002$i\002: $j, $k. \002$l\002: $m, $n. \002$o\002: $p, $q"
				set try_again 0
				putlog "Weather"
#				puthelp "PRIVMSG $nick :Hey, I tried. $q"
				break
			}
	
			# take suggestions
			if { [regexp {Did you mean:} $line] } {
				# grab the new URL and start over
				regexp {Did you mean: </font><a href=(.*?) class=p>} $line match calc(url)
				set calc(url) "http://www.google.com$calc(url)"
				putlog "Retry"
				break
			}

			# find the calculator
			if { [regexp {(src="/images/icons/onebox/calculator.*.gif".*)} $line match grab] } {
			#	putlog "$grab"
				regexp {src="/images/icons/onebox/calculator.*gif".*><td>&nbsp;<td style=(.*?)</h2>} $grab match calc(answer)
			#	putlog $calc(answer)
				regexp {<b>(.*?)</b>} $calc(answer) match calc(answer)
				#putlog "Hey, I tried. $line"
				set try_again 0
				break
			}
			# find time

# puthelp "PRIVMSG $chan FOO"
			if { [regexp {http://www.google.com/chart\?chs=40x30&amp;chc=localtime(.*)} $line match grab] } {
				regexp {<td valign=middle>(.*)</table></div><h2} $grab match calc(answer)
#				putlog $calc(answer)
				regexp {<b>(.*)</b>(.*)<b>(.*)</b> in <b>(.*)</b>(.*)} $calc(answer) match a b c d e
				putlog "time"
				if {  $calc(answer) == "" } {
					break
				}
				set calc(answer) "$a $b $c in $d$e"
				set try_again 0
				break
			}
		}
	}

	if { $calc(answer) == "" } {
		puthelp "PRIVMSG $chan :Sorry, didn't work out."
		return
	}

	puthelp "PRIVMSG $chan :[gconvert:gstring $calc(answer)]"

	return
}

proc gconvert:webstring { input } {
	set input [string map { {%} {%25} } $input]
	set input [string map { {&} {&amp;} } $input]
	set input [string map { {*} {%2A} } $input]
	set input [string map { {+} {%2B} } $input]
	set input [string map { {,} {%2C} } $input]
	set input [string map { {-} {%2D} } $input]
	set input [string map { {/} {%2F} } $input]
	set input [string map { {^} {%5E} } $input]
	set input [string map { {<} {&lt;} } $input]
	set input [string map { {>} {&gt;} } $input]
	set input [string map { {"} {&quot;} } $input]
	set input [string map { {'} {&#039;} } $input]
	set input [string map { { } {+} } $input]

	return $input
}

proc gconvert:gstring { input } {
	set input [string map { {<font size=-2> </font>} {,} } $input]
	set input [string map { {&#215;} {x} } $input]
	set input [string map { {10<sup>} {10^} } $input]
	set input [string map { {</sup>} {} } $input]

	return $input
}

putlog "gconvert.tcl v2.0 by AkiraX <#AnimeFiends@EFnet> loaded!"
