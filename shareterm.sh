#!/bin/bash
# Copyright (C) 2010 Michael Torrie (torriem@gmail.com)
#
# Licensed under the GNU General Public License Version 2
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# version 1.1
# prereqs: tmux and socat

# If macports is installed, add it to the path	 
if [ -d '/opt/local/bin' ]; then	 
        PATH=$PATH:/opt/local/bin	 
fi	 
		 
# If fink is installed, add it to the path	 
if [ -d '/sw' ]; then	 
        PATH=$PATH:/sw/bin	 
fi	 
	 
TMUX=$(which tmux)
SOCAT=$(which socat)

PSALL=$(ps ax)

if [ -z "$TMUX" -o -z "$SOCAT" ]; then
	echo Error!  This script requires tmux and socat to be installed and
	echo in the path.  If you are using RHEL or Fedora, use yum to
	echo install them.
	echo
	exit 1
fi

while getopts "vc:" options; do
	case "$options" in
	v) noverify="1";;
	c) CACERT="$OPTARG";;
	[?]) exit 1;;
	esac
done

shift $((OPTIND-1))


if [ "$#" -lt 2 ]; then
	echo "Please provide the host and port to connect a shared terminal"
	echo "to.  The remote host must be running shareterm-listen on the"
	echo "port specified."
	echo
	echo "usage: $0 [options] <khost> <port>"
	echo
	echo "Options:"
	echo "  -v            Do not verify server's SSL certificate"
	echo "  -c            Path to CA Certificate file."
	exit 1;
fi

SHARETERM_SESSION="shareterm-$1"

existing_procs=$(PSALL | grep "$SHARETERM_SESSION" | grep "attach" | awk ' { print $1 }' )

if [ ! -z "$existing_procs" ]; then
	kill $existing_procs
	sleep 1
fi	

existing_procs=$(PSALL | grep "$SHARETERM_SESSION" | grep "attach" | awk ' { print $1 }' )
if [ ! -z "$existing_procs" ]; then
	kill -9 $existing_procs
fi

existing_procs=$(PSALL | grep "$SHARETERM_SESSION" | grep "attach" | awk ' { print $1 }' )
if [ ! -z "$existing_procs" ]; then
	kill -9 $existing_procs
fi


# first we create a tmux session if necessary
$TMUX has -t "$SHARETERM_SESSION" > /dev/null || {
	$TMUX new -s "$SHARETERM_SESSION" -d || {
		echo "Could not create a tmux session!  Cannot continue."
		exit 1
	}
}

sslopts=""
if [ ! -z "$CACERT" ]; then
	sslopts="$sslopts,cafile=$CACERT"
fi

if [ "$noverify" == "1" ]; then
	sslopts="$sslopts,verify=0"
	echo "WARNING! Will not verify SSL certificate of server"
fi

echo "Establishing connection to $1:$2..."
socat SYSTEM:"tmux attach -t $SHARETERM_SESSION",pty,stderr OPENSSL:$1:$2,$sslopts &
socat_pid=$!
sleep 1

socat_running_still=$(ps ax | grep $socat_pid | grep -v grep | grep socat)
if [ -z "$socat_running_still" ]; then
	wait "$socat_pid"
	socat_err=$?
	echo
	echo Was not able to make socat connection to the remote host.  Is the
	echo remote host listening?  Check it and try again.  Socat error
	echo code was $socat_err.
	echo
	exit 1
fi

echo "Connection established.  Now joining the shared session."
echo "To exit the session, exit the terminal, or just disconnect"
echo "from the session with ^b-d (control-b, then d)."
echo "Press enter to connect."
read d

while [ "1" == "1" ]; do 
	result=$($TMUX attach -t $SHARETERM_SESSION)
	if [ "$result" == "[detached]" ]; then
		clients=$( $TMUX list-clients | grep $SHARETERM_SESSION)
		if [ ! -z "$clients" ]; then
			# we should ask the user if he wants to quit and
			# leave the session attached to the remote 
			# host--which is dangerous--or reattach.

			cat << MESSAGE
WARNING!  You have detached from a running session that is still
connected to the remote host.  This is a potential security risk
as you've granted unsupervised shell access to another party.
MESSAGE
			a=
			while [ ! "$a" == "d" -a ! "$a" == "r" -a ! "$a" == "n" ]; do
				echo
				echo \
'Do you want to (r)econnect to the session, (d)isconnect the remote'
				echo -n \
'party, or do (n)othing?  [R/d/n] '
				read a
				a=$( echo $a | tr A-Z a-z )
				if [ -z "$a" ]; then
					a=r
				fi
			done

			case $a in
			r)
				continue
				;;
			d)
				echo "Killing remote client"
				$TMUX kill-session -t $SHARETERM_SESSION
				break
				;;
			*)
				echo
				echo \
'Leaving session running.  To reconnect to this session use:'
				echo "$TMUX attach -t $SHARETERM_SESSION"
				echo
				break
				;;
			esac
		else
			# no clients; just quit
			break

		fi
	else
		break
	fi
done
				

