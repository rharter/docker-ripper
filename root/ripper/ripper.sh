#!/bin/bash

. ./src/log.sh
. ./src/config.sh
. ./src/identify.sh
. ./src/get_title.sh
. ./src/utils.sh

# 1. Read Config and setup
CONFIG_FILE="$(pwd)/config.conf"

LOGPATH=$(config LOGPATH /opt/ripper/logs)
LOG_FILE="$LOGPATH/ripper.log"

if [[ ! -d "$LOGPATH" ]];then
  mkdir -p "$LOGPATH"
fi

DRIVE=${1:-/dev/sr0}

# Startup Info
log "Starting Ripper. Optical Discs in $DRIVE will be detected and ripped within 60 seconds."

BAD_THRESHOLD=5
let BAD_RESPONSE=0

# Loop!
# while true;do

  # Identify the disc type
  log "Identifying disc type..."
  disc_type=$(identify $DRIVE)
  log "Disc type is $disc_type"

  if [[ $disc_type == "loading" ]] || [[ $disc_type == "empty" ]];then
    exit
  fi
  
  # Check the error code
  if [[ $? -ne 0 ]]; then
    log "Unexpected makemkvcon output: $disc_type"
    let BAD_RESPONSE++

    if [[ $BAD_RESPONSE -ge $BAD_THRESHOLD ]];then
      log "Too many errors, ejecting disk and aborting"

      # Log the full makemkvcon output for debugging
      log $(makemkvcon -r --cache=1 info disc:9999)

      log $(eject $DRIVE 2>&1)
      exit 1
    fi
  else
    let BAD_RESPONSE=0
  fi

  # Get the title
  log "Getting title..."
  title=$(get_title $DRIVE)
  if [[ $? -ne 0 ]];then
    log "Failed to get title: $title"
    exit 1
  fi

  log "Title of $disc_type disc is $title"

  RAWPATH=$(config RAWPATH "/opt/ripper/media/raw/")
  if [[ ! -d "$RAWPATH" ]];then
    mkdir -p $RAWPATH
  fi
  
  case $disc_type in
    "dvd" | "bluray" )
      rawpath="$RAWPATH/$title"

      if [[ -d "$rawpath" ]];then
        ts=$(date +"%Y%m%d%H%M")
        rawpath="${rawpath}_$ts"
      fi
      mkdir -p "$rawpath"

      log "Processing files into $rawpath"

      #
      # Rip!!
      #
      log "Starting MakeMKV rip..."
      disc_num=$( makemkvcon -r info disc:9999 | grep "$DRIVE" | cut -d',' -f1 | cut -d':' -f2)
      makemkv_args=$(config MKV_ARGS "")
      minlength=$(config MINLENGTH 4800)

      if [[ $disc_type == "bluray" ]];then
        log "Backing up disc with command: makemkvcon -r --decrypt --minlength=${minlength} ${makemkv_args[@]} mkv disc:$disc_num all \"$rawpath\""
        makemkvcon -r --decrypt --minlength=${minlength} ${makemkv_args[@]} mkv disc:$disc_num all "$rawpath" | tee -a $LOG_FILE
        # log "Backing up disc with command: makemkvcon -r backup disc:$disc_num \"$rawpath\" --decrypt ${makemkv_args[@]}"
        # makemkvcon -r backup disc:$disc_num --decrypt ${makemkv_args[@]} "$rawpath" | tee -a $LOG_FILE
      fi

      log "MakeMKV exit code: $?"

      log "Done with disc, ejecting..."
      eject

      #
      # Transcode!!
      #
      MEDIA_PATH=$(config MEDIAPATH "/opt/movies/")
      ext=$(config DEST_EXT "mkv")
      hb_out_file="$MEDIA_PATH/$title.$ext"

      log "Starting transcode in the background..."
      ./src/transcode.sh -c "$CONFIG_FILE" -i "$rawpath" -o "$hb_out_file"&
      ;;
  esac

# 2. Check for disc in target drive
# 3. Identify the disc
#   a. Bluray or DVD
#     1. Backup the disc with MakeMKV
#     2. Transcode the file with Handbrake
#     3. Clean up the raw files
#   b. Music
#     1. Rip the music

# # Separate Raw Rip and Finished Rip Folders for DVDs and BluRays
# # Raw Rips go in the usual folder structure
# # Finished Rips are moved to a "finished" folder in it's respective STORAGE folder
# SEPARATERAWFINISH="true"

# # Paths
# STORAGE_CD="/out/Ripper/CD"
# STORAGE_DATA="/out/Ripper/DATA"
# STORAGE_DVD="/out/Ripper/DVD"
# STORAGE_BD="/out/Ripper/BluRay"
# DRIVE="/dev/sr0"

# BAD_THRESHOLD=5
# let BAD_RESPONSE=0

# # True is always true, thus loop indefinitely
# while true
# do
# # delete MakeMKV temp files
# cwd=$(pwd)
# cd /tmp
# rm -r *.tmp
# cd $cwd

# # get disk info through makemkv and pass output to INFO
# INFO=$"`makemkvcon -r --cache=1 info disc:9999 | grep DRV:0`"
# # check INFO for optical disk
# EMPTY=`echo $INFO | grep -o 'DRV:0,0,999,0,"'`
# OPEN=`echo $INFO | grep -o 'DRV:0,1,999,0,"'`
# LOADING=`echo $INFO | grep -o 'DRV:0,3,999,0,"'`
# BD1=`echo $INFO | grep -o 'DRV:0,2,999,12,"'`
# BD2=`echo $INFO | grep -o 'DRV:0,2,999,28,"'`
# DVD=`echo $INFO | grep -o 'DRV:0,2,999,1,"'`
# CD1=`echo $INFO | grep -o 'DRV:0,2,999,0,"'`
# CD2=`echo $INFO | grep -o '","","'$DRIVE'"'`



# # if [ $EMPTY = 'DRV:0,0,999,0,"' ]; then
# #  echo "$(date "+%d.%m.%Y %T") : No Disc"; &>/dev/null
# # fi
# if [ "$OPEN" = 'DRV:0,1,999,0,"' ]; then
#  echo "$(date "+%d.%m.%Y %T") : Disk tray open"
# fi
# if [ "$LOADING" = 'DRV:0,3,999,0,"' ]; then
#  echo "$(date "+%d.%m.%Y %T") : Disc still loading"
# fi

# if [ "$BD1" = 'DRV:0,2,999,12,"' ] || [ "$BD2" = 'DRV:0,2,999,28,"' ]; then
#  DISKLABEL=`echo $INFO | grep -o -P '(?<=",").*(?=",")'`
#  BDPATH="$STORAGE_BD"/"$DISKLABEL"
#  BLURAYNUM=`echo $INFO | grep $DRIVE | cut -c5`
#  mkdir -p "$BDPATH"
#  ALT_RIP="${RIPPER_DIR}/BLURAYrip.sh"
#  if [[ -f $ALT_RIP && -x $ALT_RIP ]]; then
#     echo "$(date "+%d.%m.%Y %T") : BluRay detected: Executing $ALT_RIP"
#     $ALT_RIP "$BLURAYNUM" "$BDPATH" "$LOG_FILE"
#  else
#     # BluRay/MKV
#     echo "$(date "+%d.%m.%Y %T") : BluRay detected: Saving MKV"
#     makemkvcon --profile=/config/default.mmcp.xml -r --decrypt --minlength=600 mkv disc:"$BLURAYNUM" all "$BDPATH" >> $LOG_FILE 2>&1
#  fi
#  if [ "$SEPARATERAWFINISH" = 'true' ]; then
#     BDFINISH="$STORAGE_BD"/finished/
#     mv -v "$BDPATH" "$BDFINISH"
#  fi
#  echo "$(date "+%d.%m.%Y %T") : Done! Ejecting Disk"
#  eject $DRIVE >> $LOG_FILE 2>&1
#  # permissions
#  chown -R nobody:users "$STORAGE_BD" && chmod -R g+rw "$STORAGE_BD"
# fi

# if [ "$DVD" = 'DRV:0,2,999,1,"' ]; then
#  DISKLABEL=`echo $INFO | grep -o -P '(?<=",").*(?=",")'` 
#  DVDPATH="$STORAGE_DVD"/"$DISKLABEL"
#  DVDNUM=`echo $INFO | grep $DRIVE | cut -c5`
#  mkdir -p "$DVDPATH"
#  ALT_RIP="${RIPPER_DIR}/DVDrip.sh"
#  if [[ -f $ALT_RIP && -x $ALT_RIP ]]; then
#     echo "$(date "+%d.%m.%Y %T") : DVD detected: Executing $ALT_RIP"
#     $ALT_RIP "$DVDNUM" "$DVDPATH" "$LOG_FILE"
#  else
#     # DVD/MKV
#     echo "$(date "+%d.%m.%Y %T") : DVD detected: Saving MKV"
#     makemkvcon --profile=/config/default.mmcp.xml -r --decrypt --minlength=600 mkv disc:"$DVDNUM" all "$DVDPATH" >> $LOG_FILE 2>&1
#  fi
#  if [ "$SEPARATERAWFINISH" = 'true' ]; then
#     DVDFINISH="$STORAGE_DVD"/finished/
#     mv -v "$DVDPATH" "$DVDFINISH" 
#  fi
#  echo "$(date "+%d.%m.%Y %T") : Done! Ejecting Disk"
#  eject $DRIVE >> $LOG_FILE 2>&1
#  # permissions
#  chown -R nobody:users "$STORAGE_DVD" && chmod -R g+rw "$STORAGE_DVD"
# fi

# if [ "$CD1" = 'DRV:0,2,999,0,"' ]; then
#  if [ "$CD2" = '","","'$DRIVE'"' ]; then
#   ALT_RIP="${RIPPER_DIR}/CDrip.sh"
#   if [[ -f $ALT_RIP && -x $ALT_RIP ]]; then
#      echo "$(date "+%d.%m.%Y %T") : CD detected: Executing $ALT_RIP"
#      $ALT_RIP "$DRIVE" "$STORAGE_CD" "$LOG_FILE"
#   else
#      # MP3 & FLAC
#      echo "$(date "+%d.%m.%Y %T") : CD detected: Saving MP3 and FLAC"
#      /usr/bin/ripit -d "$DRIVE" -c 0,2 -W -o "$STORAGE_CD" -b 320 --comment cddbid --playlist 0 -D '"$suffix/$artist/$album"'  --infolog "/log/autorip_"$LOG_FILE"" -Z 2 -O y --uppercasefirst --nointeraction >> $LOG_FILE 2>&1
#   fi
#   echo "$(date "+%d.%m.%Y %T") : Done! Ejecting Disk"
#   eject $DRIVE >> $LOG_FILE 2>&1
#   # permissions
#   chown -R nobody:users "$STORAGE_CD" && chmod -R g+rw "$STORAGE_CD"
#  else
#   DISKLABEL=`echo $INFO | grep $DRIVE | grep -o -P '(?<=",").*(?=",")'`  
#   ISOPATH="$STORAGE_DATA"/"$DISKLABEL"/"$DISKLABEL".iso
#   mkdir -p "$STORAGE_DATA"/"$DISKLABEL"
#   ALT_RIP="${RIPPER_DIR}/DATArip.sh"
#   if [[ -f $ALT_RIP && -x $ALT_RIP ]]; then
#      echo "$(date "+%d.%m.%Y %T") : Data-Disk detected: Executing $ALT_RIP"
#      $ALT_RIP "$DRIVE" "$ISOPATH" "$LOG_FILE"
#   else
#      # ISO
#      echo "$(date "+%d.%m.%Y %T") : Data-Disk detected: Saving ISO"
#      ddrescue $DRIVE $ISOPATH >> $LOG_FILE 2>&1
#   fi
#   echo "$(date "+%d.%m.%Y %T") : Done! Ejecting Disk"
#   eject $DRIVE >> $LOG_FILE 2>&1
#   # permissions
#   chown -R nobody:users "$STORAGE_DATA" && chmod -R g+rw "$STORAGE_DATA"
#  fi
# fi
# # Wait a minute
# sleep 1m
# done
