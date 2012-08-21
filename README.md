iImport v3.30
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
- ffmpeg

http://www.evermeet.cx/ffmpeg/

- rtmpdump

http://trick77.com/2011/07/30/rtmpdump-2-4-binaries-for-os-x-10-7-lion/

- atomicparsley

https://github.com/wez/atomicparsley
https://dl.dropbox.com/u/331720/download/atomicparsley.zip (Universal Binary v0.9.4)

- mediainfo

http://mediainfo.sourceforge.net/en/Download/Mac_OS

### Optional

- handbrakeCLI

http://handbrake.fr/downloads2.php

Only required if you wish to re-encode the download for the 1st Generation Apple TV.



Configuration
-------------

From v3.30, most options are taken directly from the ~/.get_iplayer/options file.  


Compression Options
-------------------

There have been a few different compression options for the Apple TV employed. The current options are as follows:

1. This setting sort of works, but there's stuttering on fade-in and fade-out and some slightly iffy slow panning.

/usr/local/bin/handbrake -i $IITMP/$1 -o $IITMP/"$PROGPLUGIN"_"$PROGPID"_handbrake.mp4 -e x264 -q 20.0 -a 1,1 -E faac,ac3 -B 160,160 -6 dpl2,auto -R Auto,Auto -D 0.0,0.0 -f mp4$PROGCROPPING -X 1280 -Y 720 --loose-anamorphic -m -x cabac=0:ref=2:me=umh:b-pyramid=none:b-adapt=2:trellis=0:weightp=0:vbv-maxrate=9500:vbv-bufsize=9500 &>/dev/null

2. This is a tryout of the recommended preset from dynaflash. 

/usr/local/bin/handbrake -i $IITMP/$1 -o $IITMP/"$PROGPLUGIN"_"$PROGPID"_handbrake.mp4 -e x264 -q 20.0 -a 1,1 -E faac,ac3 -B 160,160 -6 dpl2,auto -R Auto,Auto -D 0.0,0.0 -f mp4$PROGCROPPING -X 1280 -Y 720 --loose-anamorphic -m -x mixed-refs=1:b-adapt=2:b-pyramid=none:trellis=0:weightp=0:vbv-maxrate=5500:vbv-bufsize=5500 &>/dev/null

3. I could still see oddness in the fades, so upped to me=umh rather than the default me=hex...

/usr/local/bin/handbrake -i $IITMP/$1 -o $IITMP/"$PROGPLUGIN"_"$PROGPID"_handbrake.mp4 -e x264 -q 20.0 -a 1,1 -E faac,ac3 -B 160,160 -6 dpl2,auto -R Auto,Auto -D 0.0,0.0 -f mp4$PROGCROPPING -X 1280 -Y 720 --loose-anamorphic -m -x mixed-refs=1:me=umh:b-adapt=2:b-pyramid=none:trellis=0:weightp=0:vbv-maxrate=5500:vbv-bufsize=5500 &>/dev/null

4. ...but then decided against it as apparently this might be to do with a weighted b-frames bug. Trying again without (not tested the umh setting above yet). This setting works really well, except for some occasional framedrops on complex scenes and a weird stuttering line (occasional) with HandBrake svn4276 (2011100901).

/usr/local/bin/handbrake -i $IITMP/$1 -o $IITMP/"$PROGPLUGIN"_"$PROGPID"_handbrake.mp4 -e x264 -q 20.0 -a 1,1 -E faac,ac3 -B 160,160 -6 dpl2,auto -R Auto,Auto -D 0.0,0.0 -f mp4$PROGCROPPING -X 1280 -Y 720 --loose-anamorphic -m -x mixed-refs=1:me=hex:b-adapt=2:b-pyramid=none:trellis=0:weightp=0:weightb=0:vbv-maxrate=4800:vbv-bufsize=4800 &>/dev/null



How Does It Work?
-----------------

The scripts examine downloaded files and identify them from the programme ID (PID) added to their filename. The PID is then used to extract additional metadata from the get_iplayer cache, which is applied to the file in a way that will make the most sense to iTunes. The file is then imported into iTunes in the background.

This is achieved using bash shell scripting and smidge of AppleScript.
