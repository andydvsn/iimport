#!/usr/bin/env bash

## iplayer.sh v1.04 (27th August 2026) by Andrew Davison
##  A cozy layer in front of get_iplayer.

get_iplayer="/opt/homebrew/bin/get_iplayer"
jq="/opt/homebrew/bin/jq"

if [[ "$1" == "add" ]]; then
	# Really quick PVR adder.

	if [ $# -ne 3 ]; then

		echo "Usage: $0 [add] <type> <quoted name>"
		exit 1

	else

		type="$2"
		show="$3"
		[[ "$type" != "radio" ]] && type="tv"
		[ ! -d /Users/$USER/.get_iplayer/pvr ] && mkdir -p /Users/$USER/.get_iplayer/pvr
		spacesbegone="$(echo -e "${3}" | tr -d '[[:space:]]')"
		echo -e "type $type\nsearch0 $3" > /Users/$USER/.get_iplayer/pvr/$2-$spacesbegone
		echo "$(date  +'%Y-%m-%d %H:%M:%S') : INFO : Added '$3' to the PVR."
		exit 0

	fi

elif [[ "$1" == "pids" ]]; then

	shift
	getflag=0
	posargs=()
	for arg in "$@"; do
		if [[ "$arg" == "--get" ]]; then
			getflag=1
		else
			posargs+=("$arg")
		fi
	done

	if [ ${#posargs[@]} -lt 1 ] || [ ${#posargs[@]} -gt 2 ]; then

		echo "Usage: $0 pids [--get] <seriesid> [seriesnum]"
		exit 1

	else

		seriesid="${posargs[0]}"
		seriesnum="${posargs[1]}"
		baseurl="https://www.bbc.co.uk/iplayer/episodes/$seriesid"
		pidscsv=""

		# Pulls the embedded page state out of the iPlayer HTML and hands back its JSON.
		fetchstate() {

			curl --silent --location "$1" | grep -o 'id="tvip-script-app-store">window.__IPLAYER_REDUX_STATE__ = .*' | sed -e 's/^.*window.__IPLAYER_REDUX_STATE__ = //' -e 's/;<\/script>.*$//'

		}

		state=$(fetchstate "$baseurl")

		if [[ "$state" == "" ]]; then
			echo "Could not retrieve iPlayer data for '$seriesid'. Check the series ID and try again." >&2
			exit 1
		fi

		progtitle=$($jq -r '.header.title' <<< "$state")
		echo "$(date  +'%Y-%m-%d %H:%M:%S') : INFO : $progtitle" >&2

		# The available series (ignoring the Trailers / More Like This slices).
		# Titles are usually "Series <number>", but some shows (QI, notably) use
		# lettered series on iPlayer ("Series S") instead -- keep those too.
		sliceids=()
		slicetitles=()
		while IFS=$'\t' read -r sid stitle; do
			sliceids+=("$sid")
			slicetitles+=("$stitle")
		done < <($jq -r '.header.availableSlices[] | select(.title | test("^Series [0-9A-Za-z]+$")) | [.id, .title] | @tsv' <<< "$state")

		# A lettered series' iPlayer title doesn't tell you its plain series number --
		# that's not simply alphabet position (letters can be skipped/reused down the
		# years). The BBC's own programmes API knows the real number regardless of the
		# display letter, via the parent series' "position" field. Same source
		# get_iplayer itself trusts, so this stays consistent with how existing imports
		# already got numbered.
		resolveslicenum() {

			local sliceid="$1"
			local firstpid
			firstpid=$($jq -r '.entities.results[0].episode.id // empty' <<< "$(fetchstate "$baseurl?seriesId=$sliceid&page=1")")
			[[ "$firstpid" == "" ]] && return
			curl --silent "https://www.bbc.co.uk/programmes/$firstpid.json" | $jq -r '.programme.parent.programme.position // empty'

		}

		if [[ "$seriesnum" != "" ]]; then

			target=""
			targettitle=""
			for i in "${!slicetitles[@]}"; do
				if [[ "${slicetitles[$i]}" == "Series $seriesnum" ]]; then
					target="${sliceids[$i]}"
					targettitle="${slicetitles[$i]}"
					break
				fi
			done

			if [[ "$target" == "" ]]; then
				for i in "${!slicetitles[@]}"; do
					[[ "${slicetitles[$i]}" =~ ^Series\ [A-Za-z]+$ ]] || continue
					realnum=$(resolveslicenum "${sliceids[$i]}")
					if [[ "$realnum" == "$seriesnum" ]]; then
						target="${sliceids[$i]}"
						targettitle="${slicetitles[$i]}"
						break
					fi
				done
			fi

			if [[ "$target" == "" ]]; then
				echo "$(date  +'%Y-%m-%d %H:%M:%S') : WARN : Series $seriesnum was not found for '$seriesid'." >&2
				exit 1
			fi

			sliceids=("$target")
			if [[ "$targettitle" == "Series $seriesnum" ]]; then
				slicetitles=("Series $seriesnum")
			else
				slicetitles=("Series $seriesnum ($targettitle)")
			fi

		fi

		for i in "${!sliceids[@]}"; do

			sliceid="${sliceids[$i]}"
			slicetitle="${slicetitles[$i]}"

			echo "$(date  +'%Y-%m-%d %H:%M:%S') : INFO : $slicetitle" >&2

			page=1
			totalpages=1

			while [ $page -le $totalpages ]; do

				pagestate=$(fetchstate "$baseurl?seriesId=$sliceid&page=$page")
				totalpages=$($jq -r '.pagination.totalPages // 1' <<< "$pagestate")

				while IFS=$'\t' read -r pid subtitle; do
					echo -e "$pid\t$subtitle"
					pidscsv="$pidscsv,$pid"
				done < <($jq -r '.entities.results[] | [.episode.id, (.episode.subtitle.default // .episode.subtitle.slice // "")] | @tsv' <<< "$pagestate")

				page=$((page+1))

			done

		done

		if [ $getflag -eq 1 ]; then

			pidscsv="${pidscsv:1}"

			if [[ "$pidscsv" != "" ]]; then
				echo "$(date  +'%Y-%m-%d %H:%M:%S') : INFO : Downloading ${pidscsv//,/, }..." >&2
				$get_iplayer --get --pid "$pidscsv"
			else
				echo "$(date  +'%Y-%m-%d %H:%M:%S') : WARN : No PIDs resolved, nothing to download." >&2
			fi

		fi

	fi

elif [[ "$1" == "pvr" ]]; then

	echo
	echo "$(date  +'%Y-%m-%d %H:%M:%S') : INFO : Scan starting!"
	echo
	$get_iplayer --pvr
	echo
	echo "$(date  +'%Y-%m-%d %H:%M:%S') : INFO : Scan complete."
	echo

else

	# Otherwise pass everything through to the real thing.
	$get_iplayer "$@"
	echo

fi

exit 0