iImport
=======

This repo holds two generations of scripts for turning get_iplayer downloads into a tidy media library:

- **Plex (or any other media server)** — a simple set of scripts (`iplayer.sh`, `iplayertoplex.sh`, `iplayertagger.sh`, `iplayerfaultfinder.sh`) that rename and file downloads into a folder structure that Plex (or Jellyfin, Emby, etc.) can scrape on its own. No iTunes-specific tagging, no re-encoding.
- **iTunes (legacy)** — the original `iimport` script, which handles a much more involved import into iTunes, including metadata tagging via AtomicParsley and optional re-encoding for older Apple TVs via HandBrake.

Following the discontinuation of iTunes with macOS 10.15 Catalina, I moved on to Plex as my home media server, so the iTunes path is no longer actively developed — it's kept here for reference and for anyone still running iTunes. New work happens on the Plex scripts.

Pick the section below that matches what you're using.


Plex (or other media server)
=============================

Details
-------

get_iplayer does the fetching; these scripts just take what it downloads and rename/move it into a library layout that a media server can scrape unassisted:

- **`iplayer.sh`** — a thin wrapper around `get_iplayer`. Supports a quick PVR adder (`iplayer.sh add <type> "<name>"`), a `pids` helper (`iplayer.sh pids [--get] <seriesid> [seriesnum]`) for resolving all episode PIDs of a BBC iPlayer series — e.g. `iplayer.sh pids b0b056g3` prints every episode PID across all series, or `iplayer.sh pids b0b056g3 3` narrows it to just series 3 — useful because get_iplayer's own programme cache can miss or misfile older episodes, but it can always fetch a known PID directly. Add `--get` (in any position) to have it hand the resolved PIDs straight to `get_iplayer --get --pid <pid1,pid2,...>` instead of just printing them. There's also a `pvr` mode that runs a PVR scan, and otherwise any other arguments are passed straight through to `get_iplayer`.
- **`iplayertoplex.sh`** — the script get_iplayer calls (via the `command` option, see below) once a download finishes. It works out whether the download is a film, a TV episode, or a radio programme, builds an appropriate destination path/filename, adjusts embedded metadata as needed (see below), and moves the file into place.
  - Films go to `<films>/<Name> (<year>)/<Name> (<year>).<ext>`, with the release year sourced from the BBC programme page or, if you provide an OMDb API key (see below), from OMDb. Metadata is stripped entirely (`--metaEnema`) so Plex looks up its own info rather than trusting whatever get_iplayer embedded.
  - TV episodes go to `<tv>/<Name>/Season <NN>/<Name> - sNNeNN - <Episode> (<resolution>p).<ext>` (or a `Specials` folder when there's no series number). The programme PID is written into the (otherwise unused) keyword tag so it can be recovered later.
  - One-off content with no episode title (no series/episode structure) is ambiguous — it could be a genuine film, or a one-off documentary that iPlayer also gives no episode title. To tell them apart, the script checks the `genre` iPlayer itself reports for the PID: anything containing `Documentary` is filed as a TV special under `<tv>/<Name>/Specials/` instead of going through the films path, and its metadata is left untouched (not stripped) since Plex is unlikely to find an online match for it anyway. This isn't foolproof — a real film that iPlayer itself tags with a `Documentary` genre would still be misfiled as a special — but it catches the common case.
  - Radio goes to `<radio>/<Name>/<Name> - <first broadcast date> - <Episode>.<ext>`. The album artist tag is cleared, since get_iplayer always sets it to "BBC Radio", which otherwise overrides the actual station Plex would show.
  - `<films>`, `<radio>` and `<tv>` are each independent, full paths — they don't have to live under a shared root, so it's fine to point them at different volumes/libraries.
- **`iplayertagger.sh`** — a cleanup pass for a whole directory: finds files missing the PID keyword tag and recovers/reapplies it from mediainfo's embedded playlist URL.
- **`iplayerfaultfinder.sh`** — a cleanup pass for a whole directory: strips stray `[...]` filename artefacts, flags/deletes files with unreadable or missing video, tags filenames with a detected resolution when missing, and removes lower-resolution duplicates when a higher-resolution copy of the same file already exists.

An optional `omdbapikey.txt` file, placed alongside `iplayertoplex.sh`, can hold an [OMDb](https://www.omdbapi.com/) API key used as a fallback for film release years when the BBC programme page doesn't have one.


Dependencies
------------

- get_iplayer

  http://git.infradead.org/get_iplayer.git

- AtomicParsley, mediainfo, jq

      brew install atomicparsley mediainfo jq


Installation
------------

1. Install get_iplayer, AtomicParsley, mediainfo and jq, and note their paths (the scripts assume Homebrew's Apple Silicon prefix, `/opt/homebrew/bin`, by default — adjust the paths at the top of each script if yours differs).
2. Copy `iplayer.sh`, `iplayertoplex.sh`, `iplayertagger.sh` and `iplayerfaultfinder.sh` somewhere convenient and make sure they're executable (`chmod +x`).
3. Run get_iplayer at least once to have it set up its folders, settings and plugins.
4. Set the contents of `~/.get_iplayer/options` to something like this, adjusting paths for your own library layout:

       type all
       output /tmp/iplayer
       fileprefix <pid>
       tvmode fhd,hd,sd
       radiomode high,std
       thumbsize 1920
       atomicparsley /opt/homebrew/bin/AtomicParsley
       ffmpeg /opt/homebrew/bin/ffmpeg
       whitespace 1
       nocopyright 1
       nopurge 1
       command "/path/to/iplayertoplex.sh" "<pid>" "<filename>" "<type>" "<nameshort>" "<episodeshort>" "<firstbcastdate>" "<seriesnum>" "<episodenum>" "/Volumes/Bay 2/Servers/Media/Films" "/Volumes/Bay 2/Servers/Media/Radio" "/Volumes/Bay 1/Servers/Media/Shows"

   The last three arguments to `command` are positional: the full destination paths for films, radio and TV respectively. They're independent of each other, so feel free to point them at different volumes or libraries — the example above keeps films and radio on one volume and shows on another.
5. Trigger a periodic PVR scan with cron (or launchd, if you prefer). For example, to scan every hour at 41 minutes past:

       41 * * * * "/path/to/iplayer.sh" pvr &> /tmp/iplayer.log

That's it — get_iplayer fetches new PVR content on its own schedule, and hands each finished download to `iplayertoplex.sh` to file into your library.


iTunes (legacy)
================

iImport is a script that automatically imports video content fetched by get_iplayer into iTunes, optionally re-encoding it with Handbrake for compatibility with the Apple TV. The script is designed to run on Mac OS X v10.6.8 or higher.

**NOTE:** Following the discontinuation of iTunes with macOS 10.15 Catalina I've taken the decision to move on to Plex as my home media server (see above). While iImport still works just fine, I'm unlikely to update this in the future.

Details
-------

Episode and series names, artwork, descriptions and other metadata are collected or generated and added to the file using a number of third-party metadata editors. The aim is to result in an iTunes-friendly file that will work for a variety of Apple devices; most notably the Apple TV.

If you find that the files you are importing cause problems with your Apple TV, iImport can re-encode them using HandBrake. Just edit the ATVENC option at the top of the script.

In essence, the script allows PVR functionality to iTunes using get_iplayer.


Dependencies
------------

The iImport scripts employ a number of different streaming, conversion and tagging programs to result in a iTunes-digestible file. Most of these dependencies (atomicparsley, ffmpeg, mediainfo, rtmpdump) can now be installed using [HomeBrew](http://brew.sh). After installing HomeBrew, just run:

	brew update
	brew install atomicparsley ffmpeg mediainfo rtmpdump get_iplayer

Check the [HomeBrew get_iplayer](https://github.com/dinkypumpkin/homebrew-get_iplayer) instructions for details on the get_iplayer installation using this method.

The [command line version of HandBrake](http://handbrake.fr/downloads2.php) is easily installed from their website.


### Essential

- get_iplayer 2.95 or later

http://git.infradead.org/get_iplayer.git

You may need to install HTML::Entities for Perl using:

	sudo cpan HTML::Entities

- ffmpeg

http://www.evermeet.cx/ffmpeg/

I had some audio sync issues with the most recent versions of FFMPEG (on the Apple TV, but not on my Mac). Using an older version worked perfectly. Weird.

https://dl.dropbox.com/u/331720/download/ffmpeg-r19400.zip

- atomicparsley

https://github.com/wez/atomicparsley

https://dl.dropbox.com/u/331720/download/atomicparsley.zip (Universal Binary v0.9.4)


### Optional

Only required if you wish to use the older Flash download method:

- rtmpdump

http://trick77.com/2011/07/30/rtmpdump-2-4-binaries-for-os-x-10-7-lion/


Only required if you wish to re-encode the download for the Apple TV:

- handbrakeCLI

http://handbrake.fr/downloads2.php

- mediainfo

http://mediainfo.sourceforge.net/en/Download/Mac_OS


Only required if you wish to tweet upon a successful import:

- TTYtter

http://www.floodgap.com/software/ttytter/

You will need to configure TTYtter according to it's own instructions before iImport will be able to use it. To be honest, I've not used this in a long time, so it may well be broken by now.


Installation
------------

By default, the iImport script and the dependencies should live in /usr/local/bin, although this location can easily be changed by modifying the Options section of the script and the .plist files. The installation procedure goes as follows:

1. Install required components into /usr/local/bin and ensure that they have execute permissions.
2. Run get_iplayer at least once to have it set up appropriate folders, settings and plugins.
3. Set the contents of `~/.get_iplayer/options` to:

       versionlist default
       fileprefix <type>_<pid>_iplayer
       atomicparsley /usr/local/bin/AtomicParsley
       ffmpeg /usr/local/bin/ffmpeg
       nopurge 1
       output /tmp/iimport
       type tv
       modes tvbest,radiobest
       thumbsize 640
       nocopyright 1
       command /usr/local/bin/iimport download

4. Ensure that the 'Copy files to iTunes Media Folder' option in the *Advanced* section of iTunes Preferences is *enabled*.

That should have you up and running. To run iImport automatically at set intervals to fetch content in your PVR list:

1. Copy *com.iimport.pvr.plist* and *com.iimport.stallcheck.plist* to ~/Library/LaunchAgents
2. Run 'launchctl load ~/Library/LaunchAgents/com.iimport.pvr.plist' in the Terminal.
3. Run 'launchctl load ~/Library/LaunchAgents/com.iimport.stallcheck.plist' in the Terminal.

iImport will then trigger get_iplayer to perform a fetch, importing any new content, every 20 minutes. Every 5 minutes, iImport will be run to check for stalled downloads, which it will then deal with automatically.


How Does It Work?
-----------------

When called by the LaunchAgent, iImport looks for things to import. Once done, iImport asks get_iplayer to run a PVR fetch for any content that has been available on the iPlayer for an hour or more. The delay is introduced because it sometimes takes a little time for HD content to become available, and by default we always preferentially fetch HD content.

Once a new download has completed, a new instance of iImport is called, this time by get_iplayer itself (as specified in the ~/.get_iplayer/options file). This second instance doesn't bother checking for new content, but will download a companion standard-def copy of a programme if specified (this is off by default). When each file is fetched they're tagged with appropriate information, then when everything is ready they're bundled into a folder which is imported by iTunes. The bundling together makes iTunes happier to pair HD and SD files for some reason.

In the middle of all this, if specified, the script will re-encode content into a format that the 1st Gen Apple TV can cope with.


Configuration
-------------

The locations of the output directory that get_iplayer uses and the location of AtomicParsley are both taken from the ~/.get_iplayer/options file. Everything else is configured in the Options section of the script itself. It's all annotated, so take a peek.


Enjoy!
