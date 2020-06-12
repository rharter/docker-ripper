#!/bin/bash
#
# Attempts to identify the disc type in drive 0.

# Attempts to id the disc type for the drive supplied
function identify() {
	# get disk info through makemkv and pass output to INFO
	local info="$(makemkvcon -r --cache=1 info disc:9999 | grep $1)"

	# check info for optical disk type
	local drive_state=$(echo "$info" | cut -d',' -f2)

	# AP_DriveStateNoDrive=256;
	# AP_DriveStateUnmounting=257;
	# AP_DriveStateEmptyClosed=0;
	# AP_DriveStateEmptyOpen=1;
	# AP_DriveStateInserted=2;
	# AP_DriveStateLoading=3;
	local type="__none__"
	case $drive_state in
		"256" | "257" | "0" | "1")
			type="empty"
			;;

		"3")
			type="loading"
			;;

		"2")
			local disk_type=$(echo "$info" | cut -d',' -f4)
			case $disk_type in
				"12" | "28" )
					type="bluray"
					;;
				"1" )
					type="dvd"
					;;
				"0" )
					# TODO We probably need to do better CD identification
					# CD1=`echo $INFO | grep -o 'DRV:0,2,999,0,"'`
					# CD2=`echo $INFO | grep -o '","","'$DRIVE'"'`
					type="music"
					;;
			esac
			;;
	esac

	# Dump the raw data and fail for un-identified types
	if [[ $type == "__none__" ]];then
		echo "$info"
		exit 1
	fi

	echo "$type"
}

if [[ "$0" == "$BASH_SOURCE" ]];then
	echo "Type of disc in drive $1: $(identify $1)"
fi
