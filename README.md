iImport v3.39
=============

iImport is a script that automatically imports video content fetched by get_iplayer into iTunes, optionally re-encoding it with Handbrake for compatibility with the 1st Generation Apple TV. The script is designed to run on Mac OS X v10.6.8 or higher.


Details
-------

Episode and series names, artwork, descriptions and other metadata are collected or generated and added to the file using a number of third-party metadata editors. The aim is to result in an iTunes-friendly file that will work for a variety of Apple devices; most notably the Apple TV.

iImport also includes a re-encoding section, which examines a fetched file and determines whether it is compatible with the original Apple TV. The file is re-encoded using Handbrake if it is not. No re-encoding should be necessary for the 3rd generation Apple TV (1080p capable model). I've never owned a 2nd generation model, so you're on your own with that one!

In essence, the script provides a PVR function to iTunes via get_iplayer.


Dependencies
------------

The iImport scripts employ a number of different streaming, conversion and tagging programs to result in a iTunes-digestible file.


### Essential

- get_iplayer

http://git.infradead.org/get_iplayer.git

You may need to install HTML::Entities for Perl using:

 sudo cpan HTML::Entities

- ffmpeg

http://www.evermeet.cx/ffmpeg/

I had some audio sync issues with the most recent versions of FFMPEG (on the Apple TV, but not on my Mac). Using an older version worked perfectly. Weird.

https://dl.dropbox.com/u/331720/download/ffmpeg-r19400.zip

- rtmpdump

http://trick77.com/2011/07/30/rtmpdump-2-4-binaries-for-os-x-10-7-lion/

- atomicparsley

https://github.com/wez/atomicparsley

https://dl.dropbox.com/u/331720/download/atomicparsley.zip (Universal Binary v0.9.4)


### Optional

Only required if you wish to re-encode the download for the 1st Generation Apple TV:

- handbrakeCLI

http://handbrake.fr/downloads2.php

- mediainfo

http://mediainfo.sourceforge.net/en/Download/Mac_OS


Only required if you wish to tweet upon a successful import:

- TTYtter

http://www.floodgap.com/software/ttytter/

You will need to configure TTYtter according to it's own instructions before iImport will be able to use it.


Installation
------------

By default, the iImport script and the dependencies should live in /usr/local/bin, although this location can easily be changed by modifying the Options section of the script and the .plist files. The installation procedure goes as follows:

1. Install required components into /usr/local/bin and ensure that they have execute permissions.
2. Run get_iplayer at least once to have it set up appropriate folders, settings and plugins.
3. Incorporate the contents of the *options* file into your ~/.get_iplayer/options 
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

