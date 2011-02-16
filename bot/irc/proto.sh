#!/bin/sh

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What The Fuck You Want
# To Public License, Version 2, as published by Sam Hocevar. See
# http://sam.zoy.org/wtfpl/COPYING for more details.

# ################################## Init Section ############################ #

# paths
p_parse="${p_working_directory}/irc/parse.sh"
# strings
s_os_version="`uname -s`"
# bot
bot_nick="${s_bot_nick}";
bot_rooms="$(cat channels | awk '{print $1}')";


user_send() {
(
	message="$1"
	[ ! -z "$2" ] && shift
	printf "\033[32;1m%s\033[0m\n" "$message";
)
}

register() {
(
  echo "USER ${s_bot_nick} ${s_bot_nick} ${s_bot_nick} ${s_bot_nick}" | send
  echo "NICK ${bot_nick}" | send
)
}

client() {
	register
	cat | while read -r line; do
		if [ -e "locks/global_dream" ]; then
			continue
		fi
#		echo "$line"
		message="${line}"
		. "${p_parse}"
#		printf "%q\n" "${message}" | parse
		printf "%s\n" "${message}" | parse
	done
}

