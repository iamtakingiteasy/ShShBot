#!/bin/sh

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What The Fuck You Want
# To Public License, Version 2, as published by Sam Hocevar. See
# http://sam.zoy.org/wtfpl/COPYING for more details.

get_last_minute() {
(
        current_secs="$(date "+%T" | awk -F ':' '{print $1 * 60 * 60 + $2 * 60 + $3}')"
	cat | grep '^\[.*\['"$(date +%F)"'\]\[[0-9:]*\]' | tail -n 120 | sed 's|^.*\[\([0-9:]*\)\] .*|\1|g' | awk -v "secs=$current_secs" -F ':' '{osecs = ($1 * 60 * 60 + $2 * 60 + $3); if ((secs - osecs) < 60) print osecs}'
)
}



handle_cmd() {
(
	nick="$1"
	shift
	rsrc="$1"
	shift
	room="$1"
	shift

	lim_global=50
	lim_user=20

	lim_channel=6
	lim_uoc=3

	chan_colors=0
	
	plim_channel=$(printf "%d\n" $(cat channels | grep "^$room " | awk '{print $2}'))
	plim_uoc=$(printf "%d\n" $(cat channels | grep "^$room " | awk '{print $3}'))
	pcc=$(printf "%d\n" $(cat channels | grep "^$room " | awk '{print $4}'))


	if [ "$plim_channel" -gt 0 ]; then
		lim_channel=$plim_channel
	fi

	if [ "$plim_uoc" -gt 0 ]; then
		lim_uoc=$plim_uoc
	fi

	if [ "$pcc" -eq 1 ]; then
		chan_colors=1
	fi

#	echo $lim_channel $lim_uoc


	
	username=$(printf "$rsrc" | tr '1234567890' 'abcdefghi' | tr -cd 'a-zA-Z' | tr '[:upper:]' '[:lower:]' | sed 's/^[^!]*!~//' | head -c 32)
	if [ "$username" = "root" ] || [ "$username" = "database-kun" ]; then
		username="user"
	fi


	if grep -vq "^${rsrc}$" admins; then
		if [ -e "../block" ]; then
			say "false" "true" "$nick" "$room" "Sorry, bot is under maintenance. Please wait for unblocking"
			return
		fi
	fi


	if [ -e "locks/channel_dream_${room}" ]; then
		echo "[!] channel $room dream"
		return
	fi

	if [ -e "locks/user_dream_${username}" ]; then
		echo "[!] user $username dream"
		return
	fi

	if [ -e "locks/global_dream" ]; then
		echo "[!] global dream"
		return
	fi

	case $1 in
 		"xadmin")
 			if grep -q "^${rsrc}$" admins; then
 				echo "PRIVMSG $room :Administrator recognized" | send
 			fi
 		;;
 		"xraw")
 			if grep -q "^${rsrc}$" admins; then
 				shift
 				echo "$@" | send
 			fi
 		;;

		"xjoin")
			if grep -q "^${rsrc}$" admins; then
				echo "JOIN $@" | send
			fi
		;;
		"xpart")
			if grep -q "^${rsrc}$" admins; then
				echo "PART $@" | send
			fi
		;;
		"x"|"xsh")
			shift
			cmd="$@"
#			echo AAA $cmd
			cmdout="$(sudo ./exec_cmd "$username" "$cmd")"

			if [ -z "$cmdout" ]; then
				cmdout="no output"
			fi

			echo "[$room][$username]$(date "+[%F][%T]") $cmd" >> logs/MAIN_log
			echo "$cmdout" | sed 's/^/\t/g' >> logs/MAIN_log

			echo "[$room][$username]$(date "+[%F][%T]") $cmd" >> "logs/users/${username}.log"
			echo "$cmdout" | sed 's/^/\t/g' >> "logs/users/${username}.log"

			flood_user_on_channel=0
			if echo "$room" | grep -q '^#'; then
				echo "[$room][$username]$(date "+[%F][%T]") $cmd" >> "logs/channels/${room}.log"
				echo "$cmdout" | sed 's/^/\t/g' >> "logs/channels/${room}.log"
				flood_user_on_channel="$(cat "logs/channels/${room}.log" | grep "$username" | get_last_minute | wc -l)"
				flood_channel="$(get_last_minute < "logs/channels/${room}.log" | wc -l)"

				if [ "$flood_channel" -ge $lim_channel ]; then
					touch "locks/channel_dream_${room}"
					say "false" "false" "$nick" "$room" "flood block for 60 seconds"
					sleep 60 && { 
						echo "[+] room $room dream over";
						rm -f "locks/channel_dream_${room}"; 
					} &
					return
				fi

			fi

#			get_last_minute < "logs/MAIN_log"
			flood_global="$(get_last_minute < "logs/MAIN_log" | wc -l)"
			flood_user="$(get_last_minute < "logs/users/${username}.log" | wc -l)"
	
#			echo @@@ $flood_global - $lim_global
#			echo @@@ $flood_user - $lim_user

			echo "$cmdout"
			if [ "$flood_global" -gt $lim_global ]; then
				say "false" "false" "$nick" "$room" "performing global flood block"
				touch "locks/global_dream"
				sleep 60 && { 
					echo "[+] global dream over";
					rm -f "locks/global_dream"; 
				} &
				return
			fi

			if [ "$flood_user" -gt $lim_user ]; then
				touch "locks/user_dream_${username}"
				say "false" "true" "$nick" "$room" "flood block for 60 seconds"
				sleep 60 && { 
					echo "[+] user $username dream over";
					rm -f "locks/user_dream_${username}"; 
				} &
				return
			fi


			if [ -e "locks/cu_dream_${room}_${username}" ]; then
				echo "[!] user $username at channel $room semi-dream"
				room="$nick"
			else
        	                if [ "$flood_user_on_channel" -ge $lim_uoc ]; then
	                                touch "locks/cu_dream_${room}_${username}"
					say "false" "true" "$nick" "$room" "semi-flood block; output will be continued in private room"
                                	sleep 60 && {
						echo "[+] user $username at channel $room semi-block over"
						say "false" "false" "$nick" "$nick" "semi-flood block over"
                	                        rm -f "locks/cu_dream_${room}_${username}";
        	                        } &
					room="$nick"
	                        fi

			fi

			israw=$(sudo ./exec_cmd "$username" "[ -e ~/conf/raw ] && echo true")
			if [ -z "$israw" ]; then
				israw="false"
			fi
#			echo $israw

			prepend="false"
			if echo "$room" | grep -q '^#'; then
				prepend="true"
				if [ $chan_colors -eq 0 ]; then
					israw="false"
				fi
			fi
			say "$israw" "$prepend" "$nick" "$room" "$cmdout"
		;;
	esac

)
}

func_main() {
	type="$1"
	shift
	nick="$1"
	shift
	rsrc="$1"
	shift
	room="$1"
	shift
	body="$1"
	shift
	
	tchar="@"
	ptchar=$(cat channels | grep "^$room " | awk '{print $5}')
	if [ "$ptchar" ]; then
		tchar="$ptchar"
	fi

	case "${type}" in 
		"groupchat")
			if printf "%s\n" "${body}" | grep -q "^${tchar}"; then
				cmd="`printf "%s\n" "${body}" | sed "s/^${tchar}//g"`"
				handle_cmd "${nick}" "${rsrc}" "${room}" x$cmd
			fi
		;;
		"privchat")
			cmd="`printf "%s\n" "${body}" | sed "s/^${tchar}//g"`"
			if echo "$body" | grep -vq "^${tchar}"; then
#				echo 00000000000000000000
				cmd=" $cmd"
#			else
#				echo @@@@@@@@@@@@@@@@@@@@@@@@@@2
			fi
#			echo @@@ x$cmd
			handle_cmd "${nick}" "${rsrc}" "${nick}" x$cmd
		;;

	esac
}

