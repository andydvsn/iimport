#!/usr/bin/env bash

## iplayertagger.sh v1.00 (9th May 2022) by Andrew Davison

debug=0

if [ $# -ne 1 ]; then

	echo "Usage: $0 <location>"
	exit 1

fi

find "$1" -type f ! -iname ".*" ! -iname "*.m4a" ! -iname "*.sh" ! -iname "*.txt" | while read filepath; do

	metadata=$(mediainfo "$filepath")
	filename=$(basename -- "$filepath")
	dirpath=$(dirname "$filepath")
	extension="${filename##*.}"

	keyword=$(echo "$metadata" | grep Keyword | awk -F\:\  {'print $2'})
	[[ "$keyword" == "" ]] && keyword="XXXXXXXX"

	if [[ "$keyword" == "XXXXXXXX" ]]; then

		echo "$keyword : $filepath"
		pid=$(echo "$metadata" | grep -m 1 PLAY | awk -F\episode/ {'print $2'} | awk -F\  {'print $1'})

		[[ "$pid" != "" ]] && AtomicParsley "$filepath" --keyw "$pid" --overWrite > /dev/null || echo "No PID data found."

		keyword="$pid"

	fi

	#### ADD A BIT IN HERE THAT ADDS THE PID IN [ ] IN THE FILENAME LIKE THE NEW IPLAYERTOPLEX SCRIPT DOES.

	echo "$keyword : $filepath"
	echo

done

exit 0
