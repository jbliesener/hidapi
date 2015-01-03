         HIDAPI library for Windows, Linux, FreeBSD and Mac OS X
        =========================================================

About
======

*** THIS README IS A FORK FROM signal11's VERSION. CHANGES ARE MARKED ***

HIDAPI is a multi-platform library which allows an application to interface
with USB and Bluetooth HID-Class devices on Windows, Linux, FreeBSD, and Mac
OS X.  HIDAPI can be either built as a shared library (.so or .dll) or
can be embedded directly into a target application by adding a single source
file (per platform) and a single header.

HIDAPI has four back-ends:
	* Windows (using hid.dll)
	* Linux/hidraw (using the Kernel's hidraw driver)
	* Linux/libusb (using libusb-1.0)
	* FreeBSD (using libusb-1.0)
	* Mac (using IOHidManager)

On Linux, either the hidraw or the libusb back-end can be used. There are
tradeoffs, and the functionality supported is slightly different.

Linux/hidraw (linux/hid.c):
This back-end uses the hidraw interface in the Linux kernel.  While this
back-end will support both USB and Bluetooth, it has some limitations on
kernels prior to 2.6.39, including the inability to send or receive feature
reports.  In addition, it will only communicate with devices which have
hidraw nodes associated with them.  Keyboards, mice, and some other devices
which are blacklisted from having hidraw nodes will not work. Fortunately,
for nearly all the uses of hidraw, this is not a problem.

*** The original version did not recover the "Usage Page" and "Usage" ***
*** fields. This version introduces a patch that works with kernels   ***
*** >= 2.6.38 that introduce the report_descriptor sysfs file         ***


Linux/FreeBSD/libusb (libusb/hid-libusb.c):
This back-end uses libusb-1.0 to communicate directly to a USB device. This
back-end will of course not work with Bluetooth devices.

HIDAPI also comes with a Test GUI. The Test GUI is cross-platform and uses
Fox Toolkit (http://www.fox-toolkit.org).  It will build on every platform
which HIDAPI supports.  Since it relies on a 3rd party library, building it
is optional but recommended because it is so useful when debugging hardware.

*** Building the GUI has not yet been integrated into the CMake build ***
*** process. Working on that...                                       ***

What Does the API Look Like?
=============================
The API provides the the most commonly used HID functions including sending
and receiving of input, output, and feature reports.  The sample program,
which communicates with a heavily hacked up version of the Microchip USB
Generic HID sample looks like this (with error checking removed for
simplicity):

#ifdef WIN32
#include <windows.h>
#endif
#include <stdio.h>
#include <stdlib.h>
#include "hidapi.h"

#define MAX_STR 255

int main(int argc, char* argv[])
{
	int res;
	unsigned char buf[65];
	wchar_t wstr[MAX_STR];
	hid_device *handle;
	int i;

	// Initialize the hidapi library
	res = hid_init();

	// Open the device using the VID, PID,
	// and optionally the Serial number.
	handle = hid_open(0x4d8, 0x3f, NULL);

	// Read the Manufacturer String
	res = hid_get_manufacturer_string(handle, wstr, MAX_STR);
	wprintf(L"Manufacturer String: %s\n", wstr);

	// Read the Product String
	res = hid_get_product_string(handle, wstr, MAX_STR);
	wprintf(L"Product String: %s\n", wstr);

	// Read the Serial Number String
	res = hid_get_serial_number_string(handle, wstr, MAX_STR);
	wprintf(L"Serial Number String: (%d) %s\n", wstr[0], wstr);

	// Read Indexed String 1
	res = hid_get_indexed_string(handle, 1, wstr, MAX_STR);
	wprintf(L"Indexed String 1: %s\n", wstr);

	// Toggle LED (cmd 0x80). The first byte is the report number (0x0).
	buf[0] = 0x0;
	buf[1] = 0x80;
	res = hid_write(handle, buf, 65);

	// Request state (cmd 0x81). The first byte is the report number (0x0).
	buf[0] = 0x0;
	buf[1] = 0x81;
	res = hid_write(handle, buf, 65);

	// Read requested state
	res = hid_read(handle, buf, 65);

	// Print out the returned buffer.
	for (i = 0; i < 4; i++)
		printf("buf[%d]: %d\n", i, buf[i]);

	// Finalize the hidapi library
	res = hid_exit();

	return 0;
}

If you have your own simple test programs which communicate with standard
hardware development boards (such as those from Microchip, TI, Atmel,
FreeScale and others), please consider sending me something like the above
for inclusion into the HIDAPI source.  This will help others who have the
same hardware as you do.

License
========
HIDAPI may be used by one of three licenses as outlined in LICENSE.txt.

Download
=========
HIDAPI can be downloaded from github
	git clone git://github.com/signal11/hidapi.git

*** This modified version is available at                             ***
*** https://github.com/jbliesener/hidapi                              ***

Build Instructions
===================

*** The original version used GNU autotools. This version uses        ***
*** CMake (www.cmake.org) as cross-platform build tool. Personally,   ***
*** I find CMake easier to use, as a single build description file    ***
*** is used for all platforms and CMake generates platform-specific   ***
*** build files in a directory called "build/<target-platform>" for   ***
*** each target platform. CMake also helps in finding prerequisites.  ***

Prerequisites:
---------------

***     CMake:                                                        ***
***     ------                                                        ***
***     You WILL need CMake (www.cmake.org). You can download it      ***
***     or install it through your favorite package manager. CMake    ***
***     is available for any platform and comes with a lot of helper  ***
***     packages.                                                     ***

	Linux:
	-------
	On Linux, you will need to install development packages for libudev,
	libusb and optionally Fox-toolkit (for the test GUI). On
	Debian/Ubuntu systems these can be installed by running:
	    sudo apt-get install libudev-dev libusb-1.0-0-dev libfox-1.6-dev
***     Fedora/RedHat uses                                            ***
***         sudo yum install libgudev1-devel libusb-devel fox-devel   ***
***     Also, make sure that you have pkgconfig installed.            ***

*************************************************************************
*** TODO: CHECK FOLLOWING SECTIONS                                    ***
*************************************************************************

	FreeBSD:
	---------
	On FreeBSD you will need to install GNU make, libiconv, and
	optionally Fox-Toolkit (for the test GUI). This is done by running
	the following:
	    pkg_add -r gmake libiconv fox16

	If you downloaded the source directly from the git repository (using
	git clone), you'll need Autotools:
	    pkg_add -r autotools

	Mac:
	-----
	On Mac, you will need to install Fox-Toolkit if you wish to build
	the Test GUI. There are two ways to do this, and each has a slight
	complication. Which method you use depends on your use case.

	If you wish to build the Test GUI just for your own testing on your
	own computer, then the easiest method is to install Fox-Toolkit
	using ports:
		sudo port install fox

	If you wish to build the TestGUI app bundle to redistribute to
	others, you will need to install Fox-toolkit from source.  This is
	because the version of fox that gets installed using ports uses the
	ports X11 libraries which are not compatible with the Apple X11
	libraries.  If you install Fox with ports and then try to distribute
	your built app bundle, it will simply fail to run on other systems.
	To install Fox-Toolkit manually, download the source package from
	http://www.fox-toolkit.org, extract it, and run the following from
	within the extracted source:
		./configure && make && make install

	Windows:
	---------
	On Windows, if you want to build the test GUI, you will need to get
	the hidapi-externals.zip package from the download site.  This
	contains pre-built binaries for Fox-toolkit.  Extract
	hidapi-externals.zip just outside of hidapi, so that
	hidapi-externals and hidapi are on the same level, as shown:

	     Parent_Folder
	       |
	       +hidapi
	       +hidapi-externals

	Again, this step is not required if you do not wish to build the
	test GUI.

*************************************************************************
*** TODO: END CHECK SECTION                                           ***
*************************************************************************


Building HIDAPI into a shared library on Unix Platforms:
---------------------------------------------------------

On Unix-like systems such as Linux, FreeBSD, Mac, and even Windows, using
Mingw or Cygwin, the easiest way to build a standard system-installed shared
library is to use 
***               CMake. Just create a directory "build" and, within  ***
*** that, your target-specific directory:                             ***
***                                                                   ***
***     md build                                                      ***
***     md build/linux64                                              ***
***     cd build/linux64                                              ***
***                                                                   ***
*** Then, start cmake and the build process:                          ***
***                                                                   ***
***     cmake ../..        (this reads and processes CMakeLists.txt)  ***
***     make                                                          ***
***                                                                   ***
*** This builds your library in a platform-specific subdirectory      ***
*** under build/libs. The directory name is compatible with jna (Java ***
*** Native Access, see https://github.com/twall/jna), but that's only ***
*** for those who want to embed hidapi into projects like hid4jave    ***
*** (see https://github.com/gary-rowe/hid4java).                      ***
***


Building on Windows:
---------------------

*** Right now, the build process under Windows requires MinGW32 or    ***
*** MinGW64 and follows the same steps as the abovementioned Unix     ***
*** build.                                                            ***

Building on OSX (Darwin):
-------------------------

*** Install XCode and CMake and follow the Unix instructions above.   ***

Cross Compiling
================

This section talks about cross compiling HIDAPI 
***                                             on Linux64 hosts,     ***
*** using CMake and associated "Toolchain" files. Actually, the       ***
*** process is quite easy: After installing the prerequisites, you    ***
*** create a "build" directory and, below that, a specific directory  ***
*** for each target. In each of those target directories, you call    ***
*** CMake, specifying a "Toolchain" file that tells CMake which       ***
*** compiler and libraries it should use.                             ***
***                                                                   ***
*** Toolchain files are provided for targets that run on Win32 (using ***
*** i686-w64-mingw32 as compiler), Win64 (using x86_64-w64-mingw32),  ***
*** Linux32 (using the "-m32" gcc/g++ parameter) and even for OSX     ***
*** (using osxcross - see https://github.com/tpoechtrager/osxcross)   ***
***                                                                   ***
*** For example, if you want to compile HIDAPI for Win64, you would   ***
*** type the following commands on a Linux64 host:                    ***
***                                                                         ***
***   md build                                                              ***
***   md build/win32                                                        ***
***   cd build/win32                                                        ***
***   cmake -DCMAKE_TOOLCHAIN_FILE=../../cmake/i686-w64-mingw32.cmake ../.. ***
***   make                                                                  ***
***                                                                         ***
*** This would create a file build/libs/win32-x86/hidapi.dll that runs***
*** under Win32.                                                      ***
***                                                                   ***
*** The included file "build.sh" tries to build all four cross-builds ***
*** plus a native Linux64 build.                                      ***
***                                                                   ***
*** Cross-compile Prerequisites                                       ***
*** ---------------------------                                       ***
***                                                                   ***
*** However, in order to be able to cross-compile, you need some pre- ***
*** requisites:                                                       ***
***                                                                   ***
*** For Win32: You must install mingw32 and mingw32-headers. If       ***
***            mingw32 is NOT installed in /usr/i686-w64-mingw32,     ***
***            please configure its path in                           ***
***            cmake/i686-w64-mingw32.cmake.                          ***
***                                                                   ***
*** For Win64: You must install mingw64 and mingw64-headers. If       ***
***            mingw64 is NOT installed in /usr/x86_64-w64-mingw32,   ***
***            please configure its path in                           ***
***            cmake/x86_64-w64-mingw32.cmake.                        ***
***                                                                   ***
*** For Linux32: You must install glibc-devel, libcstd++-devel and    ***
***              either libudev and libudev-devel (Fedora: libgudev1  ***
***              and libgudev1-devel) or libusb and libusb-devel for  ***
***              the i686-architecture.                               ***
***                                                                   ***
*** For OSX (Darwin): The osxcross project (see                       ***
***                   https://github.com/tpoechtrager/osxcross) uses  ***
***                   Linux' CLang compiler and provides additional   ***
***                   tools to create OSX libraries and executables.  ***
***                   You must install and build osxcross, as well as ***
***                   an OSX SDK (see osxcross page how to do this).  ***
***                   Finally,  you need to configure the SDK path in ***
***                   cmake/osx.cmake.                                ***


Signal 11 Software - 2010-04-11
                     2010-07-28
                     2011-09-10
                     2012-05-01
                     2012-07-03

*** Jorg Bliesener - 2015-01-02                                       ***

