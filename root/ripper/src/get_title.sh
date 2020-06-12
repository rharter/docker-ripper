#!/bin/bash

DIR=$(dirname "$BASH_SOURCE")
source "$DIR/identify.sh"

read_dom() {
	local IFS=\>
	read -d \< ENTITY CONTENT
}

# Get's bluray title by parsing XML in bdmt_eng.xml
function get_bluray_title() {
	local mount_point=$(mount | grep "$1" | cut -d' ' -f3)
	if [[ $? -ne 0 ]] || [[ -z $mount_point ]] || [[ ! -d $mount_point ]];then
		mount $1
	fi
	local mount_point=$(mount | grep "$1" | cut -d' ' -f3)
	if [[ $? -ne 0 ]] || [[ -z $mount_point ]] || [[ ! -d $mount_point ]];then
		echo "Can't mount drive"
		return 1
	fi

	local meta_file="$mount_point/BDMV/META/DL/bdmt_eng.xml"
	if [[ ! -f $meta_file ]];then
		echo "Disc is a bluray, but $meta_file doesn't exist."
		return 1
	fi

	local title=""
	local depth=0
	while read_dom; do
		if [[ $ENTITY == "di:name" ]];then
			title="$(echo "$CONTENT" | sed -E 's/[-]? BLU-RAY™?//I')"
		fi
	done < $meta_file

	echo $title
}

function get_title() {
	local drive=$1
	local type=$(identify $drive)

	case $type in
		"bluray" )
			get_bluray_title $drive
			;;
	esac
}

if [[ "$0" == "$BASH_SOURCE" ]];then
	echo "Title of disc in drive $1: $(get_title $1)"
fi
