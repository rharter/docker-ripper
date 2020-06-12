#!/bin/bash
#
# Read config values from a file in a safe way, returning the result.
#
# Usage: let value=$(config username)

config() {
	local val=$((grep -E "^$1=" "$CONFIG_FILE" 2> /dev/null || echo "$1=__DEFAULT__") | tail -1 | cut -d'=' -f2)

	if [[ $val == "__DEFAULT__" ]];then
		echo -n "$2"
	else
		echo -n $val
	fi
}

if [[ "$0" == "$BASH_SOURCE" ]];then
	echo $(config $1 $2)
fi
