#!/bin/sh

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What The Fuck You Want
# To Public License, Version 2, as published by Sam Hocevar. See
# http://sam.zoy.org/wtfpl/COPYING for more details.

# ############################ Core Functions Section ######################## #

get_binary() {
(
	for binary in "$@"; do
		if command -v "${binary}" > /dev/null 2>&1; then
			printf "%s\n" "${binary}"
			break
		fi
	done
)
}

get_base_directory() {
(
	path="$1"
	[ ! -z "$2" ] && shift
	possible_path="`printf "%s\n" "${path}" | sed 's|/[^/]*$|/|'`"
	if [ "${possible_path}" = "${path}" ] && printf "%s\n" "${path}" | grep -v '/$' >/dev/null; then
		pwd
		exit 0
	fi
	if [ ! -d "${possible_path}" ] || [ ! -x "${possible_path}" ]; then
		exit 1
	fi
	cd "${possible_path}"
	pwd
)
}

printerr() {
(
	message="$1"
	[ ! -z "$2" ] && shift
	printf "%s %s\n" "[Error]" "${message}" 1>&2
)
}


print_help() {
(
	printf "%s\n" "\
USAGE: $0 [OPTIONS] [HOSTNAME]
Where [OPTIONS] are:
	-h	--help		This help message
	-p	--port		Port connect to
	-x	--protocol	Protocol file to use
	-n	--bot-nick	Bot nickname
	-s	--sock-file	Socket file
"
)
}

# ############################################################################ #


# ################################## Init Section ############################ #

# logic
l_supported_interacters_list="nc netcat telnet"
# paths
p_network_binary="`get_binary ${l_supported_interacters_list}`"
p_working_directory="`get_base_directory "$0"`"
p_protocol="${p_working_directory}/irc/proto.sh"
p_func="${p_working_directory}/func/main.sh"
p_socket_file="/tmp/shell-network-$$"
# strings
s_host="$(cat server)"
s_bot_nick="$(cat nick)"
# numerics
n_port="$(cat port)"

# ############################################################################ #


# ############################ Options Parse Section ######################### #


#if [ -z "$1" ]; then
#	set -- "--help"
#fi

while [ ! -z "$1" ]; do
	case "$1" in
		"-h" | "--help")
			print_help
			exit 0
		;;
		"-p" | "--port")
			n_port=`printf "%d" "$2" 2>/dev/null` || {
				printerr "Wrong port value: '$2'"
				exit 1
			}
			[ ! -z "$2" ] && shift
		;;
		"-x" | "--protocol")
			p_protocol="${p_working_directory}/$2"
			[ ! -z "$2" ] && shift			
		;;
		"-n" | "--bot-nick")
			s_bot_nick="$2"
			[ ! -z "$2" ] && shift			
		;;
		"-s" | "--sock-file")
			p_socket_file="$2"
			[ ! -z "$2" ] && shift
		;;
		*)
			s_host="$1"
		;;
	esac
	shift
done

# ############################################################################ #


# ############################ Options Check Section ######################### #

if [ ${n_port} -gt 65535 ] || [ ${n_port} -lt 1 ]; then
	printerr "Specified port (${n_port}) not in 1..65535 range"
	exit 1
fi

if [ -z "${p_network_binary}" ]; then
	printerr "No working network interact binary detected in PATH directories"
	exit 1
fi

if [ ! -x "${p_protocol}" ]; then
	printerr "Invalid protocol implementation: ${p_protocol}"
	exit 1
fi

if [ -z "`get_base_directory "${p_socket_file}"`" ]; then
	printerr "Invalid socket file path: ${p_socket_file}"
	exit 1
fi

# ############################################################################ #


############################### Main Functions Section ####################### #

open_socket() {
(
	if [ -f "${p_socket_file}" ]; then
		rm -f "${p_socket_file}"
	fi
	touch "${p_socket_file}" || {
		printerr "Invalid socket file path: ${p_socket_file}"
		exit 1
	}
)
}

close_socket() {
(
	if [ -f "${p_socket_file}" ]; then
		rm -f "${p_socket_file}"
	fi
)
}

user_disconnect() {
(
	return 0
)
}

user_send() {
(
	return 0
)
}

disconnect() {
	user_disconnect
	close_socket
	exit 0
}

send() {
(
	message="`cat`"
#	message="$1"
	[ ! -z "$2" ] && shift
	user_send "${message}"
	printf "%s\n" "${message}" >> "${p_socket_file}"
)
}

client() {
(
	cat
)
}

# ############################################################################ #


# ################################## Main Section ############################ #

trap disconnect 2
open_socket
. "${p_protocol}"
tail -f "${p_socket_file}" | "${p_network_binary}" "${s_host}" ${n_port} | client

# ############################################################################ #

