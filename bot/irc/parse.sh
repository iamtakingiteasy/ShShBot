#!/bin/sh

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What The Fuck You Want
# To Public License, Version 2, as published by Sam Hocevar. See
# http://sam.zoy.org/wtfpl/COPYING for more details.

say() {
(
	israw="$1"
	shift
	prepend="$1"
	shift
	nick="$1"
	shift
	room="$1"
	shift
	data="$1"
	shift

	trim=1

#	echo $room

	if echo "$room" | grep -vq "^#"; then
		trim=3
	fi
	if [ "$israw" = "true" ]; then
		stripper=""
	else
		stripper="[:cntrl:]"
	fi



	if [ $(echo "$data" | wc -l) -eq 1 ] && [ $(echo "$data" | wc -c) -le 450 ]; then
		if [ "$prepend" = true ]; then
			echo "PRIVMSG ${room} :$nick: $data" | tr -d "$stripper" | send
		else
			echo "PRIVMSG ${room} :$data" | tr -d "$stripper" | send
		fi
	else
		if [ "$prepend" = true ]; then
			i=1;
			echo "$data" | while read line; do
				echo "PRIVMSG ${room} :$nick: $line" | head -n $trim | tr -d "$stripper" | head -c 450 | send
				let i++
				if [ $i -ge $trim ]; then
					break
				fi
			done
			if [ $(echo "$data" | wc -l) -ge $trim ]; then
				echo "PRIVMSG ${room} :$nick: $(echo "$data" | wgetpaste 2>/dev/null)" | send
			fi
		else
			i=1;
			echo "$data" | while read line; do
				echo "PRIVMSG ${room} :$line" | head -n $trim | tr -d "$stripper" | head -c 450 | send
				let i++
				if [ $i -ge $trim ]; then
					break
				fi
			done
			if [ $(echo "$data" | wc -l) -ge $trim ]; then
				echo "PRIVMSG ${room} :$(echo "$data" | wgetpaste 2>/dev/null)" | send
			fi
		fi
		
	fi
)
}

privsay() {
(
	nick="$1"
	shift
	body="$1"
	shift

	echo "PRIVMSG ${nick} :${body}" | send
)
}



perform_join() {
(
	for room in $bot_rooms; do
		echo "JOIN ${room}" | send
	done
)
}

handle_ping() {
(
	from="$1"
	shift
	echo "PONG :${from}" | send
)
}

handle_privmsg() {
(
	nick="$1"
	shift
	rsrc="$1"
	shift
	room="$1"
	shift
	body="$1"
	shift
	. "${p_func}"
	if printf "%s\n" "$room" | grep -q '^#'; then
		func_main "groupchat" "${nick}" "${rsrc}" "${room}" "${body}"
	else
		func_main "privchat" "${nick}" "${rsrc}" "${room}" "${body}"
	fi
)
}

handle_notice() {
(
	:
)
}

handle_mode() {
(
	:
)
}

handle_quit() {
(
	:
)
}


handle_join() {
(
	:
)
}


handle_part() {
(
	:
)
}


parse() {
(
	if [ -e dream ]; then
		return	
	fi
#	cat 	
#	cat
	set -f
	message="`cat | tr '\r' '\n'`"
#	cat /tmp/cmd
#	return
#	echo "$message"
	if printf "%s\n" "${message}" | grep -q "^PING"; then
		from="`printf "%s\n" "${message}" | sed 's/[^:]*://g'`"
		printf "%s \033[37;1m%s \033[33;1m%s \033[34;1m%s\033[0m\n" "${from}" "PING" " " " "
		handle_ping "${from}"
	elif printf "%s\n" "${message}" | grep -q "^[^:]*:[^ ]* QUIT"; then
		from="`printf "%s\n" "${message}" | sed 's/^:\([^ ]*\).*/\1/g'`"
		body="`printf "%s\n" "${message}" | sed 's/^:[^ ]* [^ ]* :\(.*\)/\1/g'`"
		nick="`printf "%s\n" "${from}" | sed 's/\(^[^!]*\)!.*/\1/g'`"
		rsrc="`printf "%s\n" "${from}" | sed 's/^[^!]*!\(.*\)/\1/g'`"
		printf "%s \033[37;1m%s \033[33;1m%s \033[34;1m%s\033[0m\n" "${from}" "QUIT" " " "${body}"
		handle_quit "${nick}" "${rsrc}" "${body}"
	elif printf "%s\n" "${message}" | grep -q "^[^:]*:[^ ]* JOIN"; then
#		echo JOIN $message
		from="`printf "%s\n" "${message}" | sed 's/^:\([^ ]*\).*/\1/g'`"
		room="`printf "%s\n" "${message}" | sed 's/^:[^ ]* [^ ]* :\([^ ]*\).*/\1/g'`"
		printf "%s \033[37;1m%s \033[33;1m%s \033[34;1m%s\033[0m\n" "${from}" "JOIN" "${room}" " "
		nick="`printf "%s\n" "${from}" | sed 's/\(^[^!]*\)!.*/\1/g'`"
		rsrc="`printf "%s\n" "${from}" | sed 's/^[^!]*!\(.*\)/\1/g'`"
		handle_join  "${nick}" "${rsrc}" "${room}"
	else 
#		echo regular
		from="`printf "%s\n" "${message}" | sed 's/^:\([^ ]*\).*/\1/g'`"
		type="`printf "%s\n" "${message}" | sed 's/^:[^ ]* \([^ ]*\).*/\1/g'`"
		room="`printf "%s\n" "${message}" | sed 's/^:[^ ]* [^ ]* \([^ ]*\).*/\1/g'`"
		body="`printf "%s\n" "${message}" | sed 's/^:[^ ]* [^ ]* [^ ]* :\(.*\)/\1/g'`"

		nick="`printf "%s\n" "${from}" | sed 's/\(^[^!]*\)!.*/\1/g'`"
		rsrc="`printf "%s\n" "${from}" | sed 's/^[^!]*!\(.*\)/\1/g'`"

		printf "%s \033[37;1m%s \033[33;1m%s \033[34;1m%s\033[0m\n" "${from}" "${type}" "${room}" "${body}"

		case "${type}" in
			"PRIVMSG")
				handle_privmsg "${nick}" "${rsrc}" "${room}" "${body}"
			;;
			"NOTICE")
				handle_notice "${nick}" "${rsrc}" "${room}" "${body}"
			;;
			"MODE")
				handle_mode "${nick}" "${rsrc}" "${room}" "${body}"
			;;
			"PART")
				handle_part "${nick}" "${rsrc}" "${room}" "${body}"
			;;
			"001")
				perform_join
			;;
		esac
	fi
)
}

