#!/bin/bash
#
# Transcode
#
# Uses HandBrakeCLI to transcode the supplied video source for use in media players.

LOCAL_DIR=$(dirname "$BASH_SOURCE")
. "$LOCAL_DIR"/config.sh

CONFIG_FILE="../config.conf"
IN_FILE=""
OUT_FILE=""

usage() {
	echo "Usage: $0 -c <config file> -i <source> -o <destination>"
	exit 1
}

while getopts "hc:i:o:" o; do
	case "${o}" in
		h )
			usage
			;;
		c )
			CONFIG_FILE=${OPTARG}
			;;
		i )
			IN_FILE=${OPTARG}
			;;
		o )
			OUT_FILE=${OPTARG}
			;;
		# * )
		# 	usage
		# 	;;
	esac
done
shift $((OPTIND-1))

if [ -z "${IN_FILE}" ] || [ -z "${OUT_FILE}"]; then
	usage
fi

log() {
	echo "$(date "+%d.%m.%Y %T"): $1"
}

log "Starting transcode..."
hb_args=$(config HB_ARGS_BD "--subtitle scan -F --subtitle-burned --audio-lang-list eng --all-audio")
hb_preset=$(config HB_PRESET_BD "High Profile")

log "Transcoding to file: $OUT_FILE"
log "Executing command: HandBrakeCLI -i \"$IN_FILE\" -o \"$OUT_FILE\" --main-feature --preset \"$hb_preset\" ${hb_args[@]}"
HandBrakeCLI -i "$IN_FILE" -o "$OUT_FILE" --main-feature --preset "$hb_preset" ${hb_args[@]} | tee -a $LOG_FILE

log "Handbrake finished with exit code: $?"
