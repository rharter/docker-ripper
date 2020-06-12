#!/bin/bash

log() {
  echo "$(date "+%d.%m.%Y %T"): $1" | tee -a "$LOG_FILE"
}