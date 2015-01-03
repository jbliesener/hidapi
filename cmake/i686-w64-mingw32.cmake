# See here: http://www.cmake.org/Wiki/CmakeMingw

set(CMAKE_SYSTEM_NAME Windows)

set(CMAKE_C_COMPILER i686-w64-mingw32-gcc)
set(CMAKE_CXX_COMPILER i686-w64-mingw32-g++)
set(CMAKE_RC_COMPILER i686-w64-mingw32-windres)

set(PKG_CONFIG_EXECUTABLE i686-w64-mingw32-pkg-config)

set(CMAKE_FIND_ROOT_PATH /usr/i686-w64-mingw32)

# Adjust the default behaviour of the FIND_XXX() commands:
#  - search headers and libraries in the target environment
#  - search programs in the host environment
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
