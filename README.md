iImport v3.33
=============

iImport is a script that automatically imports video content fetched by get_iplayer into iTunes, optionally re-compressing it with Handbrake for compatibility with the 1st Generation Apple TV. The script is designed to run on Mac OS X v10.6.8 or higher.

Please note that iImport is undergoing some redevelopment work at the moment, so not everything is in a particularly tidy state.


Introduction
------------

Episode and series names, artwork, descriptions and other metadata are collected or generated and added to the file using a number of third-party metadata editors. The aim is to result in an iTunes-friendly file that will work for a variety of Apple devices; most notably the Apple TV. Additionally, there are two PHP files and a script that can be used to provide a simple web interface.

iImport also includes a re-encoding section, which examines a fetched file and determines whether it is compatible with the (currently first generation only) Apple TV. The file is re-encoded using Handbrake if it is not.

In essence, this provides a PVR function to iTunes for get_iplayer.


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

I had some audio sync issues with the most recent versions of FFMPEG (on the Apple TV, not on my Mac). Using an older version worked perfectly. Weird.

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

By default, the iImport script and the dependencies should live in /usr/local/bin, although this location can easily be changed by modifying the Options section of the script. The installation procedure goes as follows:

1. Install required components into /usr/local/bin and ensure that they have execute permissions.
2. Run get_iplayer at least once to have it set up appropriate folders, settings and plugins.
3. Incorporate the contents of the *options* file into your ~/.get_iplayer/options 
4. Ensure that the 'Copy files to iTunes Media Folder' option in the *Advanced* section of iTunes Preferences is *enabled*.

That should have you up and running. To run iImport automatically at set intervals to fetch content in your PVR list:

1. Copy *com.iimport.pvr.plist* to ~/Library/LaunchAgents
2. Run 'launchctl load ~/Library/LaunchAgents/com.iimport.pvr.plist' in the Terminal.

iImport will then trigger get_iplayer to perform a fetch, importing any new content, every 20 minutes.


How Does It Work?
-----------------

When called by the LaunchAgent, iImport looks for things to import. Once done, iImport asks get_iplayer to run a PVR fetch for any content that has been available on the iPlayer for an hour or more. The delay is introduced because it sometimes takes a little time for HD content to become available, and by default we always preferentially fetch HD content.

Once a new download has completed, a new instance of iImport is called (as specified in the ~/.get_iplayer/options file) which handles the import. This second instance doesn't bother checking for new content online, but will download an SD copy of a programme if specified (this is off by default). When each  file is fetched they're tagged with appropriate information, then when everything is ready they're bundled into a folder, which is imported by iTunes using a sprinkling of AppleScript. The bundling into a folder makes iTunes happier to pair HD and SD files together for some reason.

In the middle of all this, if specified, the script will call on mediainfo to determine whether the file will play on a 1st Generation Apple TV. If it thinks it won't (most HD content doesn't), it calls on handbrake to re-encode the 720p content into a format that the Apple TV can cope with. This is a little irritating, but the resulting files are still very good quality indeed.


Configuration
-------------

The locations of the output directory that get_iplayer uses and the location of AtomicParsley are both taken from the ~/.get_iplayer/options file. Everything esle is configured in the Options section of the script itself. It's all annotated and very self-explanatory, so take a peek.


Compression Options
-------------------

There have been a few different compression options for the Apple TV employed. This is how we've ended up where we are:

1. This setting sort of works, but there's stuttering on fade-in and fade-out and some slightly iffy slow panning.

/usr/local/bin/handbrake -i $IITMP/$1 -o $IITMP/"$PROGPLUGIN"_"$PROGPID"_handbrake.mp4 -e x264 -q 20.0 -a 1,1 -E faac,ac3 -B 160,160 -6 dpl2,auto -R Auto,Auto -D 0.0,0.0 -f mp4$PROGCROPPING -X 1280 -Y 720 --loose-anamorphic -m -x cabac=0:ref=2:me=umh:b-pyramid=none:b-adapt=2:trellis=0:weightp=0:vbv-maxrate=9500:vbv-bufsize=9500 &>/dev/null

2. This is a tryout of the recommended preset from dynaflash. 

/usr/local/bin/handbrake -i $IITMP/$1 -o $IITMP/"$PROGPLUGIN"_"$PROGPID"_handbrake.mp4 -e x264 -q 20.0 -a 1,1 -E faac,ac3 -B 160,160 -6 dpl2,auto -R Auto,Auto -D 0.0,0.0 -f mp4$PROGCROPPING -X 1280 -Y 720 --loose-anamorphic -m -x mixed-refs=1:b-adapt=2:b-pyramid=none:trellis=0:weightp=0:vbv-maxrate=5500:vbv-bufsize=5500 &>/dev/null

3. I could still see oddness in the fades, so upped to me=umh rather than the default me=hex...

/usr/local/bin/handbrake -i $IITMP/$1 -o $IITMP/"$PROGPLUGIN"_"$PROGPID"_handbrake.mp4 -e x264 -q 20.0 -a 1,1 -E faac,ac3 -B 160,160 -6 dpl2,auto -R Auto,Auto -D 0.0,0.0 -f mp4$PROGCROPPING -X 1280 -Y 720 --loose-anamorphic -m -x mixed-refs=1:me=umh:b-adapt=2:b-pyramid=none:trellis=0:weightp=0:vbv-maxrate=5500:vbv-bufsize=5500 &>/dev/null

4. ...but then decided against it as apparently this might be to do with a weighted b-frames bug. Trying again without (not tested the umh setting above yet). This setting works really well, except for some occasional framedrops on complex scenes and a weird stuttering line (occasional) with HandBrake svn4276 (2011100901).

/usr/local/bin/handbrake -i $IITMP/$1 -o $IITMP/"$PROGPLUGIN"_"$PROGPID"_handbrake.mp4 -e x264 -q 20.0 -a 1,1 -E faac,ac3 -B 160,160 -6 dpl2,auto -R Auto,Auto -D 0.0,0.0 -f mp4$PROGCROPPING -X 1280 -Y 720 --loose-anamorphic -m -x mixed-refs=1:me=hex:b-adapt=2:b-pyramid=none:trellis=0:weightp=0:weightb=0:vbv-maxrate=4800:vbv-bufsize=4800 &>/dev/null

5.  This setting worked really well, except for some occasional framedrops on complex scenes (usually water). Seemed better with HandBrake 0.9.8, but then a corrupt line started appearing on some HD content. This has now been dropped for the Handbrake recommended ATV1 preset, with minor changes for resolution size and container format.

/usr/local/bin/handbrake -i $IITMP/$1 -o $IITMP/"$PROGPLUGIN"_"$PROGPID"_handbrake.mp4 -e x264 -q 20.0 -a 1,1 -E faac,ac3 -B 160,160 -6 dpl2,auto -R Auto,Auto -D 0.0,0.0 -f mp4$PROGCROPPING -X 1280 -Y 720 --loose-anamorphic -m -x mixed-refs=1:me=hex:b-adapt=2:b-pyramid=none:trellis=0:weightp=0:weightb=0:vbv-maxrate=4800:vbv-bufsize=4800 &>/dev/null


