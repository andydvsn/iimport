 
                                                                                  iImport
=========================================================================================
                                                                     birdslikewires.co.uk


What Does iImport Do?
---------------------

iImport is a set of scripts that automatically import video content, fetched using get_iplayer, into iTunes.

The scripts are designed to run on Mac OS X systems running 10.5.8 or higher, both Intel and PowerPC.

Episode and series names, artwork, descriptions and other metadata are collected or generated and added to the file using a number of third-party metadata editors. The aim is to result in an iTunes-friendly file that will work for a variety of Apple devices; most notably the Apple TV. Additionally, there are two PHP files and a script that can be used to provide a simple web interface.

iImport also includes a re-encoding section, which examines a fetched file and determines whether it is compatible with the (currently first generation only) Apple TV. The file is re-encoded using Handbrake if it is not.

In essence, this provides a PVR function to iTunes for get_iplayer.


How Does It Work?
-----------------

The scripts examine files downloaded by get_iplayer and identify them from the programme ID (PID) added to their filename. The PID is then used to extract additional metadata from the get_iplayer cache files, which is applied to the file in a way that will make the most sense to iTunes. The file is then imported into iTunes in the background.

This is achieved using bash shell scripting and smidge of AppleScript, so I'm afraid iImport is of no use on Windows; although it could be adapted.
