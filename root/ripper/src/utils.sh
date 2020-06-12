#!/bin/bash

function sanitize_filename() {
	local CLEANED=${CLEANED//[^a-zA-Z0-9_]/}
	echo $CLEANED
}