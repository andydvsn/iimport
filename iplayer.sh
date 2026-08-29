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
	forceflag=0
	posargs=()
	for arg in "$@"; do
		if [[ "$arg" == "--get" ]]; then
			getflag=1
		elif [[ "$arg" == "--force" ]]; then
			forceflag=1
		else
			posargs+=("$arg")
		fi
	done

	if [ ${#posargs[@]} -lt 1 ] || [ ${#posargs[@]} -gt 2 ]; then

		echo "Usage: $0 pids [--get] [--force] <seriesid> [seriesnum|start-end]"
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

		# A lettered series' plain number is its alphabet position (A=1, B=2, ...),
		# matching TVDB's own convention for shows like this (verified against QI XL:
		# TVDB Season 13/18/19 are Series M/R/S respectively). Deliberately NOT using
		# the BBC's own internal series "position" metadata here (what get_iplayer
		# itself relies on) -- that field runs one series ahead of the plain alphabet
		# count for QI, for reasons on the BBC's end, and get_iplayer just relays it
		# uncorrected. Since Plex/TVDB is what actually matters for our library, we
		# override the BBC's number rather than propagate its mislabelling further.
		resolveslicenum() {

			local letters="$1"
			letters=$(tr '[:lower:]' '[:upper:]' <<< "$letters")
			local num=0 i c
			for (( i=0; i<${#letters}; i++ )); do
				c="${letters:$i:1}"
				num=$(( num * 26 + ( $(printf '%d' "'$c") - 64 ) ))
			done
			echo "$num"

		}

		# Finds the slice for a single plain series number, checking a direct numeric
		# title match first, then falling back to lettered-series resolution. Echoes
		# back "sliceid<TAB>displaytitle" on success, nothing on failure.
		resolveseriesslice() {

			local num="$1" i target="" targettitle=""

			for i in "${!slicetitles[@]}"; do
				if [[ "${slicetitles[$i]}" == "Series $num" ]]; then
					target="${sliceids[$i]}"
					targettitle="${slicetitles[$i]}"
					break
				fi
			done

			if [[ "$target" == "" ]]; then
				for i in "${!slicetitles[@]}"; do
					[[ "${slicetitles[$i]}" =~ ^Series\ ([A-Za-z]+)$ ]] || continue
					local realnum
					realnum=$(resolveslicenum "${BASH_REMATCH[1]}")
					if [[ "$realnum" == "$num" ]]; then
						target="${sliceids[$i]}"
						targettitle="${slicetitles[$i]}"
						break
					fi
				done
			fi

			[[ "$target" == "" ]] && return 1

			if [[ "$targettitle" == "Series $num" ]]; then
				echo -e "$target\tSeries $num"
			else
				echo -e "$target\tSeries $num ($targettitle)"
			fi

		}

		if [[ "$seriesnum" != "" ]]; then

			if [[ "$seriesnum" =~ ^([0-9]+)-([0-9]+)$ ]]; then
				rangestart="${BASH_REMATCH[1]}"
				rangeend="${BASH_REMATCH[2]}"
			else
				rangestart="$seriesnum"
				rangeend="$seriesnum"
			fi

			if [ "$rangestart" -gt "$rangeend" ]; then
				echo "$(date  +'%Y-%m-%d %H:%M:%S') : WARN : Range '$seriesnum' is backwards -- start must not be greater than end." >&2
				exit 1
			fi

			newsliceids=()
			newslicetitles=()
			for (( num=rangestart; num<=rangeend; num++ )); do
				resolved=$(resolveseriesslice "$num") || {
					echo "$(date  +'%Y-%m-%d %H:%M:%S') : WARN : Series $num was not found for '$seriesid'." >&2
					continue
				}
				IFS=$'\t' read -r rid rtitle <<< "$resolved"
				newsliceids+=("$rid")
				newslicetitles+=("$rtitle")
			done

			if [ ${#newsliceids[@]} -eq 0 ]; then
				echo "$(date  +'%Y-%m-%d %H:%M:%S') : WARN : None of series $seriesnum were found for '$seriesid'." >&2
				exit 1
			fi

			sliceids=("${newsliceids[@]}")
			slicetitles=("${newslicetitles[@]}")

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
				forceargs=()
				[ $forceflag -eq 1 ] && forceargs=(--force)
				$get_iplayer --get "${forceargs[@]}" --pid "$pidscsv"
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