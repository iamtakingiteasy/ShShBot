#!/bin/sh

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What The Fuck You Want
# To Public License, Version 2, as published by Sam Hocevar. See
# http://sam.zoy.org/wtfpl/COPYING for more details.

say() {
(
#	set -x
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


	if printf "%s\n" "$room" | grep -vq "^#"; then
		trim=2
	fi
	if [ "$israw" = "true" ]; then
		stripper=""
	else
		stripper="[:cntrl:]"
	fi
	prep=""
	if [ "$prepend" = true ]; then
		prep="$nick: "
	fi

	stream_processor="$(cat stream_processor)"

	if [ -z "$stream_processor" ]; then
		stream_processor="cat"
	fi
	

	if [ $(printf "%s\n" "$data" | wc -l) -eq 1 ] && [ ${#data} -le 400 ]; then
		printf "%s\n" "PRIVMSG ${room} :${prep}$data" | tr -d "$stripper" | $stream_processor | send
	else
		i=0;
		printf "%s\n" "$data" | while read line && [ $i -lt $(($trim-1)) ]; do
			printf "%s\n" "PRIVMSG ${room} :${prep}$line" | tr -d "$stripper" | head -c 400 | $stream_processor | send
			i=$(($i+1))
		done

		app=""
		
		if [ $(printf "%s\n" "$data" | wc -l) -gt $trim ] || [ ${#data} -gt 400 ]; then
			app=" ... ( $(printf "%s\n" "$data" | wgetpaste | sed 's/Your paste can be seen here: //g') )"
#			if [ ${#data} -gt 400 ] && [ $(printf "%s\n" "$data" | wc -l) -le $trim ]; then
#				trim=$(($trim-1))
#			fi
		fi
		printf "%s\n" "PRIVMSG ${room} :${prep}$(printf "%s\n" "$data" | sed "$trim!d" | tr -d "$stripper" | head -c 400)${app}" | $stream_processor | send
		
	fi
)
}

privsay() {
(
	nick="$1"
	shift
	body="$1"
	shift

	printf "%s\n" "PRIVMSG ${nick} :${body}" | send
)
}



perform_join() {
(
	for room in $bot_rooms; do
		printf "%s\n" "JOIN ${room}" | send
	done
)
}

perform_autosend() {
(
	if [ -f "autosend" ]; then
		cat autosend | while read line; do
			printf "%s\n" "$line" | send
		done
	fi
)
}

handle_ping() {
(
	from="$1"
	shift
	printf "%s\n" "PONG :${from}" | send
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
	message="$(cat | tr '\r' '\n')"
#	cat /tmp/cmd
#	return
#	printf "%s\n" "$message"
	if printf "%s\n" "${message}" | grep -q "^PING"; then
		from="$(printf "%s\n" "${message}" | sed 's/[^:]*://g')"
		printf "%s \033[37;1m%s \033[33;1m%s \033[34;1m%s\033[0m\n" "${from}" "PING" " " " "
		handle_ping "${from}"
	elif printf "%s\n" "${message}" | grep -q "^[^:]*:[^ ]* QUIT"; then
		from="$(printf "%s\n" "${message}" | sed 's/^:\([^ ]*\).*/\1/g')"
		body="$(printf "%s\n" "${message}" | sed 's/^:[^ ]* [^ ]* :\(.*\)/\1/g')"
		nick="$(printf "%s\n" "${from}" | sed 's/\(^[^!]*\)!.*/\1/g')"
		rsrc="$(printf "%s\n" "${from}" | sed 's/^[^!]*!\(.*\)/\1/g')"
		printf "%s \033[37;1m%s \033[33;1m%s \033[34;1m%s\033[0m\n" "${from}" "QUIT" " " "${body}"
		handle_quit "${nick}" "${rsrc}" "${body}"
	elif printf "%s\n" "${message}" | grep -q "^[^:]*:[^ ]* JOIN"; then
		from="$(printf "%s\n" "${message}" | sed 's/^:\([^ ]*\).*/\1/g')"
		room="$(printf "%s\n" "${message}" | sed 's/^:[^ ]* [^ ]* :\([^ ]*\).*/\1/g')"
		printf "%s \033[37;1m%s \033[33;1m%s \033[34;1m%s\033[0m\n" "${from}" "JOIN" "${room}" " "
		nick="$(printf "%s\n" "${from}" | sed 's/\(^[^!]*\)!.*/\1/g')"
		rsrc="$(printf "%s\n" "${from}" | sed 's/^[^!]*!\(.*\)/\1/g')"
		handle_join  "${nick}" "${rsrc}" "${room}"
	else 
		from="$(printf "%s\n" "${message}" | sed 's/^:\([^ ]*\).*/\1/g')"
		type="$(printf "%s\n" "${message}" | sed 's/^:[^ ]* \([^ ]*\).*/\1/g')"
		room="$(printf "%s\n" "${message}" | sed 's/^:[^ ]* [^ ]* \([^ ]*\).*/\1/g')"
		body="$(printf "%s\n" "${message}" | sed 's/^:[^ ]* [^ ]* [^ ]* :\(.*\)/\1/g')"

		nick="$(printf "%s\n" "${from}" | sed 's/\(^[^!]*\)!.*/\1/g')"
		rsrc="$(printf "%s\n" "${from}" | sed 's/^[^!]*!\(.*\)/\1/g')"

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
				perform_autosend
#				perform_join
			;;
		esac
	fi
)
}

