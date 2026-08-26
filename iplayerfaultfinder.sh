#!/usr/bin/env bash

## iplayerfaultfinder.sh v1.01 (6th May 2022) by Andrew Davison
##  Remove lower resolution duplicates.

debug=0

##
mediainfo="/opt/homebrew/bin/mediainfo"
##

if [ $# -ne 1 ]; then

	echo "Usage: $0 <location>"
	exit 1

fi


# Bin silly attempt at putting PID in the filename.
find "$1" -type f -iname "*\[*" | while read filepath; do

	nopid=$(echo "$filepath" | sed 's/\[[^]]*\]\ //g')
	mv -fv "$filepath" "$nopid"

done


# Find any low resolution files or those with unknown resolutions.
find "$1" -type f ! -iname \*\(1080p\)\* ! -iname \*\(720p\)\* ! -iname ".*" ! -iname "*.m4a" ! -iname "*.sh" ! -iname "*.txt" | while read filepath; do

	filename=$(basename -- "$filepath")
	dirpath=$(dirname "$filepath")
	extension="${filename##*.}"

	if [[ "$filename" =~ "(p)" ]]; then
		# Sometimes video files with no video appear. Remove duds and log.

		metadata=$($mediainfo "$filepath")
		filesize=$(du -h "$filepath" | awk -F\  {'print $1'} | cut -d M -f1)
		resolution=$(echo "$metadata" | grep Height | awk -F\:\  {'print $2'} | tr -d '[:space:]' | cut -d p -f1)
		videopresent=$(echo "$metadata" | grep -c "Advanced Video")

		if [[ "$resolution" == "" && $videopresent < 1 ]]; then

			echo -n "File is "$filesize" MB and missing video. Logging and deleting : "
			rm -fv "$filepath"

		else

			echo "File with "$resolution"p video looks unusual. Inspect : $filepath"

		fi

		mkdir -p /tmp/iplayer/logs
		echo "$filename" >> /tmp/iplayer/logs/inspection.log

	elif [[ ! "$filename" =~ "(" ]]; then
		# Where no resolution is found, try to determine it and append to filename.

		metadata=$($mediainfo "$filepath")
		resolution=$(echo "$metadata" | grep Height | awk -F\:\  {'print $2'} | tr -d '[:space:]' | cut -d p -f1)
		
		if [[ "$resolution" != "" ]]; then

			filewithres=$(echo "$filename" | sed -e "s/.$extension/ ("$resolution"p).$extension/")

			echo -n "Missing "$resolution"p resolution : "
			mv -fv "$filepath" "$dirpath/$filewithres"

		else

			echo "Cannot determine missing resolution : $filepath"

		fi

	else
		# Where a low resolution is found, determine whether a higher resolution copy exists and bin the small version.

		lowres=$(echo "$filename" | awk -F\( '{print $2}' | awk -F\) '{print $1}')
		lowresvalue=$(echo $lowres | cut -d p -f1)

		re='^[0-9]+$'
		if [[ ! $lowresvalue =~ $re ]]; then
			# Perhaps there are parentheses in the title. Try again.

			lowres=$(echo "$filename" | awk -F\( '{print $3}' | awk -F\) '{print $1}')
			lowresvalue=$(echo $lowres | cut -d p -f1)

			if [[ ! $lowresvalue =~ $re ]]; then

				echo "Resolution '$lowresvalue' is not a number! : $filepath"

			fi

		fi

		if [[ "$lowresvalue" != "" ]]; then

			resolutions=("720p" "1080p")

			for hires in "${resolutions[@]}"; do

				hirespath=$(echo "$filepath" | sed -e "s/ ($lowres)/ ($hires)/")

				if [ -f "$hirespath" ]; then

					echo -n "Found $lowres and $hires versions. Deleting $lowres version : "
					rm -fv "$filepath"

				fi

			done

		fi

	fi

done


# Where multiple high resolution copies exist, remove the lowest resolution.
find "$1" -type f -iname \*\(1080p\)\* | while read filepath; do

	resolutions=("720p")

	for lowres in "${resolutions[@]}"; do

		lowrespath=$(echo "$filepath" | sed -e "s/ (1080p)/ ($lowres)/")

		if [ -f "$lowrespath" ]; then

			echo -n "Found multiple high resolution versions. Deleting $lowres version : "
			rm -fv "$lowrespath"

		fi

	done

done


exit 0
