Compression Options
-------------------

I tried many different compression settings for the Apple TV 1.

The last one is the one we stuck with for longest, getting a good balance between full 720p and picture quality before the ATV1 would explode.

We are now using the HandBrake defaults, but with 32-bit containers (no -6 option) as 64-bit containers still seem to cause problems.

1. This setting sort of works, but there's stuttering on fade-in and fade-out and some slightly iffy slow panning.

		/usr/local/bin/handbrake -i $IITMP/$1 -o $IITMP/"$PROGPLUGIN"_"$PROGPID"_handbrake.mp4 -e x264 -q 20.0 -a 1,1 -E faac,ac3 -B 160,160 -6 dpl2,auto -R Auto,Auto -D 0.0,0.0 -f mp4$PROGCROPPING -X 1280 -Y 720 --loose-anamorphic -m -x cabac=0:ref=2:me=umh:b-pyramid=none:b-adapt=2:trellis=0:weightp=0:vbv-maxrate=9500:vbv-bufsize=9500 &>/dev/null

2. This is a tryout of the recommended preset from dynaflash. 

		/usr/local/bin/handbrake -i $IITMP/$1 -o $IITMP/"$PROGPLUGIN"_"$PROGPID"_handbrake.mp4 -e x264 -q 20.0 -a 1,1 -E faac,ac3 -B 160,160 -6 dpl2,auto -R Auto,Auto -D 0.0,0.0 -f mp4$PROGCROPPING -X 1280 -Y 720 --loose-anamorphic -m -x mixed-refs=1:b-adapt=2:b-pyramid=none:trellis=0:weightp=0:vbv-maxrate=5500:vbv-bufsize=5500 &>/dev/null

3. I could still see oddness in the fades, so upped to me=umh rather than the default me=hex...

		/usr/local/bin/handbrake -i $IITMP/$1 -o $IITMP/"$PROGPLUGIN"_"$PROGPID"_handbrake.mp4 -e x264 -q 20.0 -a 1,1 -E faac,ac3 -B 160,160 -6 dpl2,auto -R Auto,Auto -D 0.0,0.0 -f mp4$PROGCROPPING -X 1280 -Y 720 --loose-anamorphic -m -x mixed-refs=1:me=umh:b-adapt=2:b-pyramid=none:trellis=0:weightp=0:vbv-maxrate=5500:vbv-bufsize=5500 &>/dev/null

4. ...but then decided against it as apparently this might be to do with a weighted b-frames bug. Trying again without (not tested the umh setting above yet). This setting works really well, except for some occasional framedrops on complex scenes and a weird stuttering line (occasional) with HandBrake svn4276 (2011100901).

		/usr/local/bin/handbrake -i $IITMP/$1 -o $IITMP/"$PROGPLUGIN"_"$PROGPID"_handbrake.mp4 -e x264 -q 20.0 -a 1,1 -E faac,ac3 -B 160,160 -6 dpl2,auto -R Auto,Auto -D 0.0,0.0 -f mp4$PROGCROPPING -X 1280 -Y 720 --loose-anamorphic -m -x mixed-refs=1:me=hex:b-adapt=2:b-pyramid=none:trellis=0:weightp=0:weightb=0:vbv-maxrate=4800:vbv-bufsize=4800 &>/dev/null

5. This setting worked really well, except for some occasional framedrops on complex scenes (usually water). Seemed better with HandBrake 0.9.8, but then a corrupt line started appearing on some HD content. This has now been dropped for the Handbrake recommended ATV1 preset, with minor changes for resolution size and container format.

		/usr/local/bin/handbrake -i $IITMP/$1 -o $IITMP/"$PROGPLUGIN"_"$PROGPID"_handbrake.mp4 -e x264 -q 20.0 -a 1,1 -E faac,ac3 -B 160,160 -6 dpl2,auto -R Auto,Auto -D 0.0,0.0 -f mp4$PROGCROPPING -X 1280 -Y 720 --loose-anamorphic -m -x mixed-refs=1:me=hex:b-adapt=2:b-pyramid=none:trellis=0:weightp=0:weightb=0:vbv-maxrate=4800:vbv-bufsize=4800 &>/dev/null

6. This one we ran with for a very long time, with a lot of success. Though some blockiness in dark backgrounds is visible, overall it was very good.

		/usr/local/bin/handbrake -i $IITMP/$1 -o $IITMP/"$PROGPLUGIN"_"$PROGPID"_handbrake.mp4 -e x264 -q 20.0 -a 1,1 -E faac,copy:ac3 -B 160,160 -6 dpl2,auto -R Auto,Auto -D 0.0,0.0 -f mp4$PROGCROPPING -X 1280 -Y 720 --loose-anamorphic -m -x cabac=0:ref=2:me=umh:b-pyramid=none:b-adapt=2:weightb=0:trellis=0:weightp=0:vbv-maxrate=9500:vbv-bufsize=9500:level=3.1

