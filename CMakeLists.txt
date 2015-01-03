
cmake_minimum_required(VERSION 2.8)
if(POLICY CMP0042)	
  cmake_policy(SET CMP0042 NEW) 
endif()

project(hid4java C CXX)

################# Architecture detection ###########################
# Based on the Qt 5 processor detection code, so should be very accurate
# https://qt.gitorious.org/qt/qtbase/blobs/master/src/corelib/global/qprocessordetection.h
# Currently handles arm (v5, v6, v7), x86 (32/64), ia64, and ppc (32/64)

# Regarding POWER/PowerPC, just as is noted in the Qt source,
# "There are many more known variants/revisions that we do not handle/detect."

set(archdetect_c_code "
#if defined(__arm__) || defined(__TARGET_ARCH_ARM)
    #if defined(__ARM_ARCH_7__) \\
        || defined(__ARM_ARCH_7A__) \\
        || defined(__ARM_ARCH_7R__) \\
        || defined(__ARM_ARCH_7M__) \\
        || (defined(__TARGET_ARCH_ARM) && __TARGET_ARCH_ARM-0 >= 7)
        #error cmake_ARCH armv7
    #elif defined(__ARM_ARCH_6__) \\
        || defined(__ARM_ARCH_6J__) \\
        || defined(__ARM_ARCH_6T2__) \\
        || defined(__ARM_ARCH_6Z__) \\
        || defined(__ARM_ARCH_6K__) \\
        || defined(__ARM_ARCH_6ZK__) \\
        || defined(__ARM_ARCH_6M__) \\
        || (defined(__TARGET_ARCH_ARM) && __TARGET_ARCH_ARM-0 >= 6)
        #error cmake_ARCH armv6
    #elif defined(__ARM_ARCH_5TEJ__) \\
        || (defined(__TARGET_ARCH_ARM) && __TARGET_ARCH_ARM-0 >= 5)
        #error cmake_ARCH armv5
    #else
        #error cmake_ARCH arm
    #endif
#elif defined(__i386) || defined(__i386__) || defined(_M_IX86)
    #error cmake_ARCH i386
#elif defined(__x86_64) || defined(__x86_64__) || defined(__amd64) || defined(_M_X64)
    #error cmake_ARCH x86_64
#elif defined(__ia64) || defined(__ia64__) || defined(_M_IA64)
    #error cmake_ARCH ia64
#elif defined(__ppc__) || defined(__ppc) || defined(__powerpc__) \\
      || defined(_ARCH_COM) || defined(_ARCH_PWR) || defined(_ARCH_PPC)  \\
      || defined(_M_MPPC) || defined(_M_PPC)
    #if defined(__ppc64__) || defined(__powerpc64__) || defined(__64BIT__)
        #error cmake_ARCH ppc64
    #else
        #error cmake_ARCH ppc
    #endif
#endif
#error cmake_ARCH unknown
")

# Set ppc_support to TRUE before including this file or ppc and ppc64
# will be treated as invalid architectures since they are no longer supported by Apple

function(target_architecture output_var)
    if(APPLE AND CMAKE_OSX_ARCHITECTURES)
        # On OS X we use CMAKE_OSX_ARCHITECTURES *if* it was set
        # First let's normalize the order of the values

        # Note that it's not possible to compile PowerPC applications if you are using
        # the OS X SDK version 10.6 or later - you'll need 10.4/10.5 for that, so we
        # disable it by default
        # See this page for more information:
        # http://stackoverflow.com/questions/5333490/how-can-we-restore-ppc-ppc64-as-well-as-full-10-4-10-5-sdk-support-to-xcode-4

        # Architecture defaults to i386 or ppc on OS X 10.5 and earlier, depending on the CPU type detected at runtime.
        # On OS X 10.6+ the default is x86_64 if the CPU supports it, i386 otherwise.

        foreach(osx_arch ${CMAKE_OSX_ARCHITECTURES})
            if("${osx_arch}" STREQUAL "ppc" AND ppc_support)
                set(osx_arch_ppc TRUE)
            elseif("${osx_arch}" STREQUAL "i386")
                set(osx_arch_i386 TRUE)
            elseif("${osx_arch}" STREQUAL "x86_64")
                set(osx_arch_x86_64 TRUE)
            elseif("${osx_arch}" STREQUAL "ppc64" AND ppc_support)
                set(osx_arch_ppc64 TRUE)
            else()
                message(FATAL_ERROR "Invalid OS X arch name: ${osx_arch}")
            endif()
        endforeach()

        # Now add all the architectures in our normalized order
        if(osx_arch_ppc)
            list(APPEND ARCH ppc)
        endif()

        if(osx_arch_i386)
            list(APPEND ARCH i386)
        endif()

        if(osx_arch_x86_64)
            list(APPEND ARCH x86_64)
        endif()

        if(osx_arch_ppc64)
            list(APPEND ARCH ppc64)
        endif()
    else()
        file(WRITE "${CMAKE_BINARY_DIR}/arch.c" "${archdetect_c_code}")

        enable_language(C)

        # Detect the architecture in a rather creative way...
        # This compiles a small C program which is a series of ifdefs that selects a
        # particular #error preprocessor directive whose message string contains the
        # target architecture. The program will always fail to compile (both because
        # file is not a valid C program, and obviously because of the presence of the
        # #error preprocessor directives... but by exploiting the preprocessor in this
        # way, we can detect the correct target architecture even when cross-compiling,
        # since the program itself never needs to be run (only the compiler/preprocessor)
        try_run(
            run_result_unused
            compile_result_unused
            "${CMAKE_BINARY_DIR}"
            "${CMAKE_BINARY_DIR}/arch.c"
            COMPILE_OUTPUT_VARIABLE ARCH
            CMAKE_FLAGS CMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES}
        )

        # Parse the architecture name from the compiler output
        string(REGEX MATCH "cmake_ARCH ([a-zA-Z0-9_]+)" ARCH "${ARCH}")

        # Get rid of the value marker leaving just the architecture name
        string(REPLACE "cmake_ARCH " "" ARCH "${ARCH}")

        # If we are compiling with an unknown architecture this variable should
        # already be set to "unknown" but in the case that it's empty (i.e. due
        # to a typo in the code), then set it to unknown
        if (NOT ARCH)
            set(ARCH unknown)
        endif()
    endif()

    set(${output_var} "${ARCH}" PARENT_SCOPE)
endfunction()

##################### detect library verision #########################
#
#file(READ src/c/HidDevice.c _versionRaw)
#string(REGEX REPLACE ".*char\\* +VERSION += +\\\"([0-9\\.]*)\\\".*" "\\1" _version ${_versionRaw})
#message(STATUS "Library version: ${_version}")

################### detect target architecture ########################

target_architecture(_architecture)
if(_architecture STREQUAL "i386" OR _architecture STREQUAL "i686")
    set(_architecture "x86")
elseif(_architecture STREQUAL "x86_64" OR _architecture STREQUAL "amd64" OR _architecture STREQUAL "universal")
    set(_architecture "x86-64")
#TODO: Handle ARM
endif()


######################### compiler settings ###########################

if("${CMAKE_C_COMPILER_ID}" STREQUAL "Clang")
    set(CMAKE_COMPILER_IS_CLANG 1)
endif()

if(CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_CLANG)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=gnu99 -fms-extensions -D_GNU_SOURCE -D_FILE_OFFSET_BITS=64 -Wall -Wextra -Wshadow -Wconversion -Wformat=2")
    
    if(CMAKE_COMPILER_IS_GNUCC)
        set(CMAKE_C_FLAGS_DEBUG "-Og -ggdb -D_FORTIFY_SOURCE=2")
    else()
        set(CMAKE_C_FLAGS_DEBUG "-O1 -g -D_FORTIFY_SOURCE=2")
    endif()
    set(CMAKE_C_FLAGS_RELEASE "-O2 -D_FORTIFY_SOURCE=2")
endif()


################### compile OS specific provider ######################

include_directories(include)
set(_sources include/hidapi.h)

if(WIN32)
    set(_osname "windows")
    set(_output_dir "win32-${_architecture}")
    list(APPEND _sources src/windows/hid.c)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(_osname "linux")
    set(_output_dir "linux-${_architecture}")

    OPTION(USE_LIBUSB "Use LibUSB instead of LibUDEV")
    if (USE_LIBUSB)
        list(APPEND _sources src/linux-libusb/hid.c)
    else()
        list(APPEND _sources src/linux/hid.c)
    endif()
elseif(APPLE)
    set(_osname "mac_os_x")
    set(_output_dir "darwin")
    list(APPEND _sources src/osx/hid.c)
endif()


# Determine libraries to link

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    find_package(PkgConfig REQUIRED)

    if (USE_LIBUSB)
        pkg_check_modules(LIBUSB REQUIRED libusb)
        find_library(LIBUSB1 usb)
    
        message(STATUS "LibUSB found here: ${LIBUSB_INCLUDE_DIRS}, ${LIBUSB1}")
        include_directories(${LIBUSB_INCLUDE_DIRS})
        list(APPEND _libraries ${LIBUSB1})
    else()
        pkg_check_modules(LIBUDEV REQUIRED libudev)
        find_library(LIBUDEV1 udev)

        message(STATUS "LibUDEV found here: ${LIBUDEV_INCLUDE_DIRS}, ${LIBUDEV1}")
        include_directories(${LIBUDEV_INCLUDE_DIRS})
        list(APPEND _libraries ${LIBUDEV1})
    endif()
endif()

if(WIN32)
    list(APPEND _libraries setupapi hid)
	add_definitions(-D_WIN32_WINNT=0x0602)
endif()

if (APPLE)
	find_library(_core CoreFoundation)
	find_library(_io IOKit)
	list(APPEND _libraries ${_core} ${_io})
endif()

# Set target directory

set (_output_dir "${CMAKE_BINARY_DIR}/../libs/${_output_dir}")

# Inform user

message(STATUS "Libraries to link: ${_libraries}")
message(STATUS "Library Architecture will be: ${_architecture}")
message(STATUS "Output directory will be ${_output_dir}")

# Compile & link

add_library(hidDeviceLib SHARED ${_sources})
add_library(hidDeviceLibStatic STATIC ${_sources})
target_link_libraries(hidDeviceLib ${_libraries})

set_target_properties(hidDeviceLib PROPERTIES OUTPUT_NAME "hidapi")
set_target_properties(hidDeviceLib PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${_output_dir})
set_target_properties(hidDeviceLib PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${_output_dir})

if(WIN32)
    set_target_properties(hidDeviceLib PROPERTIES PREFIX "")
endif()

add_executable(hidTest src/hidtest/hidtest.cpp)
target_link_libraries(hidTest hidDeviceLibStatic ${_libraries})

