#!/usr/bin/env bash

## iplayertoplex.sh v1.08 (27th August 2026) by Andrew Davison
##  Take downloaded content from get_iplayer and fumble it into Plex.

debug=0

###
atomicparsley="/opt/homebrew/bin/AtomicParsley"
bbcurl="https://www.bbc.co.uk/programmes"
iplayerurl="https://www.bbc.co.uk/iplayer/episode"
jq="/opt/homebrew/bin/jq"
mediainfo="/opt/homebrew/bin/mediainfo"
###

pathtothisscript="$(cd "$(dirname "$0")";pwd -P)"

pid="${1}"
filename="${2}"
type="${3}"
nameshort="${4}"
episodeshort="${5}"
firstbcastdate="${6}"
seriesnum="${7}"
episodenum="${8}"
films="${9}"
radio="${10}"
tv="${11}"

# Some shows (QI, notably) use lettered series on iPlayer ("Series S") instead of
# numbered ones. get_iplayer resolves seriesnum for these from the BBC's own internal
# series "position" metadata, which runs one series ahead of the plain alphabet-position
# convention TVDB (and thus Plex) actually uses -- verified against QI XL, where TVDB's
# Season 19 is "Series S" (S being the 19th letter), not the BBC's own position of 20.
# get_iplayer already tags the file with this before calling us (its own "tvsh"/"©alb"
# atom, e.g. "QI XL: Series R") -- read it straight back out rather than re-fetch it.
series=$($atomicparsley "$filename" -t 2>/dev/null | grep '^Atom "tvsh" contains:' | sed 's/^Atom "tvsh" contains: //' | sed 's/^.*: //')
if [[ "$series" =~ ^Series\ ([A-Za-z]+)$ ]]; then

	letters=$(tr '[:lower:]' '[:upper:]' <<< "${BASH_REMATCH[1]}")
	alphanum=0
	for (( i=0; i<${#letters}; i++ )); do
		c="${letters:$i:1}"
		alphanum=$(( alphanum * 26 + ( $(printf '%d' "'$c") - 64 ) ))
	done
	seriesnum="$alphanum"

fi

if [[ "$episodeshort" == "" ]] && [[ "$nameshort" != "" ]]; then

	# No episode title means this is either a genuine film or a one-off documentary that iPlayer
	# doesn't give an episode title either. Check iPlayer's own genre classification to tell them
	# apart; a false negative here (a documentary that slips through as a film) is expected, but
	# this at least catches the common case.
	genre=$(curl -sL "$iplayerurl/$pid" | grep -o 'id="tvip-enhanced-seo-metadata">.*</script>' | head -1 | sed -e 's#.*id="tvip-enhanced-seo-metadata">##' -e 's#</script>##' | $jq -r '.[0].genre // empty' 2>/dev/null)

	if [[ "$genre" == *"Documentary"* ]]; then
		# Keep it a TV special under its own show folder instead of the films bucket.
		episodeshort="$nameshort"
	else
		type="film"
	fi

fi
[[ "${#seriesnum}" -eq 1 ]] && seriesnum="0$seriesnum"
[[ "${#episodenum}" -eq 1 ]] && episodenum="0$episodenum"

safenameshort=$(echo $nameshort | sed -e 's/://g' | sed -e 's/\//-/g')
safeepisodeshort=$(echo $episodeshort | sed -e 's/://g'| sed -e 's/\//-/g')
fileext="${filename##*.}"
metadata=$($mediainfo "$filename")

echo
echo "$bbcurl/$pid"
echo
echo "pid                : $pid"
echo "filename           : $filename"
echo "type               : $type"
[[ -n "${genre+x}" ]] && echo "genre              : $genre"
echo "nameshort          : $nameshort"
echo "safenameshort      : $safenameshort"		
echo "episodeshort       : $episodeshort"
echo "safeepisodeshort   : $safeepisodeshort"
echo "firstbcastdate     : $firstbcastdate"
echo "series             : $series"
echo "seriesnum          : $seriesnum"
echo "episodenum         : $episodenum"
echo "films              : $films"
echo "radio              : $radio"
echo "tv                 : $tv"
echo "fileext            : $fileext"

if [[ "$type" == "film" ]] || [[ "$type" == "tv" ]]; then

	resolution=$(echo "$metadata" | grep Height | awk -F\:\  {'print $2'} | tr -d '[:space:]' | cut -d p -f1)

fi

if [[ "$type" == "film" ]]; then

	# Only the programme page seems to hold the real film release date.
	datepublished=$(curl -s "$bbcurl/$pid" | grep datePublished | $jq '.datePublished' | cut -d\" -f2)

	if [[ "$datepublished" != "" ]]; then

		echo "datepublished      : $datepublished"
		year="${datepublished:0:4}"

	elif [[ -f "$pathtothisscript/omdbapikey.txt" ]] ; then

		# Get the release date of the film from OMDb if we can.
		omdbapikey=$(cat "$pathtothisscript/omdbapikey.txt")

		# The Beeb doesn't always stick to the correct title for films and occasionally adds a prefix.
		if [[ "$nameshort" =~ ":" ]]; then
			omdbnameshort=$(echo "$nameshort" | awk -F\:\  {'print $2'})
		else
			omdbnameshort="$nameshort"
		fi
		omdbnameshort=$(echo $omdbnameshort | sed -e 's/ /+/g')
		echo "omdbnameshort      : $omdbnameshort"

		omdburl="https://www.omdbapi.com/?t=$omdbnameshort&apikey=$omdbapikey"
		omdbyear=$(curl -s $omdburl | $jq '.Year' | cut -d\" -f2)
		omdbyear="${omdbyear:0:4}"
		echo "omdbyear           : $omdbyear"

		if [[ "$omdbyear" == "null" ]] || [[ "$omdbyear" == "" ]]; then
			# We're out of options. Use the date we're given.
			year=$(echo $firstbcastdate | cut -d- -f1)
		else
			year="$omdbyear"
		fi

	fi

	# Finally! The year we will actually use.
	echo "year               : $year"

	destination_dir="$films/$safenameshort ($year)"
	destination_filename="$safenameshort ($year).$fileext"
	destination_path="$destination_dir/$destination_filename"

	# Strip all metadata from films; better for Plex to look up the real info.
	$atomicparsley "$filename" --metaEnema --overWrite > /dev/null

fi

if [[ "$type" == "radio" ]]; then

	destination_dir="$radio/$safenameshort"
	destination_filename="$safenameshort - $firstbcastdate - $safeepisodeshort.$fileext"
	destination_path="$destination_dir/$destination_filename"

	# Strip the album artist because it's always BBC Radio, which overrides the actual station in Plex default scanning.
	$atomicparsley "$filename" --albumArtist "" --overWrite > /dev/null

fi

if [[ "$type" == "tv" ]]; then

	# Build the path and sXXeXX identifier into the file name.
	[[ "$seriesnum" == "" ]] && destination_dir="$tv/$safenameshort/Specials" || destination_dir="$tv/$safenameshort/Season $seriesnum"
	[[ "$resolution" == "" ]] && optionalinformation="$safeepisodeshort" || optionalinformation="$safeepisodeshort ($resolution""p)"
	[[ "$episodenum" == "" ]] && destination_filename="$safenameshort - $firstbcastdate - $optionalinformation.$fileext" || destination_filename="$safenameshort - s$seriesnum""e$episodenum - $optionalinformation.$fileext"
	#destination_filename=$(echo "$destination_filename" |  sed 's/\//\\\//g')
	destination_path="$destination_dir/$destination_filename"

	# Add PID in the empty keyword field. Leave all other metadata intact, it's likely better than anything available elsewhere.
	$atomicparsley "$filename" --keyw "$pid" --overWrite > /dev/null

fi

echo
echo "==="
echo "Destination Path : $destination_path"
echo "==="
echo

if [[ "$filename" != "" ]] && [[ "$destination_dir" != "" ]] && [[ "$destination_filename" != "" ]] && [[ "$destination_path" != "" ]]; then

	echo -n "Moving '$destination_filename'..."
	mkdir -p "$destination_dir"

	if [[ "$debug" != "1" ]]; then
		echo
		echo
		if cp -v "$filename" "$destination_path"; then
			rm "$filename"
		else
			echo "WARNING: copy failed, leaving '$filename' in place." >&2
		fi
	else
		echo " not really, we're in debug mode!"
		echo
		echo "cp \"$filename\" \"$destination_path\" && rm \"$filename\""
	fi

else

	echo "Not all paths and filenames were present. You may want to check whether '$filename' exists."

fi

echo
exit 0
