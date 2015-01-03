#! /bin/bash
#
# This shell file builds the 32 and 64 bit library files for linux and windows,
# as well as the OSX (Darwin) libraries and and places them in the appropriate subdirectories 
# under ./build/libs
#
# Prerequisites:
# 
# - Linux host with 64 bit architecture
# - gcc (tested with 4.9.2)
# - pkgconfig
# - The following packages must be installed for BOTH i686 and x86_64 architectures:
#   -- glibc-devel
#   -- libstdc++-devel
#   -- for linux build using libudev: libudev-devel (on Fedora libgudev1-devel)
#   -- for linux build using libusb and FreeBSD: libusb-devel
# - mingw32 in /usr/i686-w64-mingw32 (or adjust path in cmake/i686-w64-mingw32.cmake)
# - mingw64 in /usr/x86_64-w64-mingw32 (or adjust path in cmake/x86_64-w64-mingw32.cmake)
# - mingw32-headers
# - mingw64-headers
# - mingw32-crt
# - mingw64-crt
# - osxcross (https://github.com/tpoechtrager/osxcross) with OSX SDK installed (see osxcross README file)
#   (NOTE: SPECIFY THE FULL PATH OF THE INSTALLED SDK AS CMAKE_FIND_ROOT_PATH IN ./cmake/osx.cmake)


# Which linux driver?
LINUX_DRIVER=libudev
#LINUX_DRIVER=libusb

CM_FLAG=""
DIR_SUFFIX=""

# clean target directories
find build -mindepth 1 -maxdepth 1 -type d -not \( -name 'libs' -or -name 'progs' \) -print0 | xargs -0 -I {} rm -rf {}

mkdir build/win32
mkdir build/win64
mkdir build/osx

if [ "$LINUX_DRIVER" == "libudev" ]; then
  DIR_SUFFIX="udev"
fi

if [ "$LINUX_DRIVER" == "libusb" ]; then
  DIR_SUFFIX="libusb"
  CM_FLAG="-DUSE_LIBUSB=1"
fi

if [ "$DIR_SUFFIX" != "" ]; then
  mkdir build/linux32-$DIR_SUFFIX
  mkdir build/linux64-$DIR_SUFFIX

  cd build/linux64-$DIR_SUFFIX
  cmake $CM_FLAG ../..
  make

  cd ../linux32-$DIR_SUFFIX
  cmake $CM_FLAG -DCMAKE_TOOLCHAIN_FILE=../../cmake/i686-linux.cmake ../..
  make
fi

cd ../win64
cmake -DCMAKE_TOOLCHAIN_FILE=../../cmake/x86_64-w64-mingw32.cmake ../..
make
cd ../win32
cmake -DCMAKE_TOOLCHAIN_FILE=../../cmake/i686-w64-mingw32.cmake ../..
make
cd ../osx
cmake -DCMAKE_TOOLCHAIN_FILE=../../cmake/osx.cmake ../..
make
cd ..
