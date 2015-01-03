# toolchain file I use to cross compile on Linux
# targetting OSX/Darwin (x86_64). running:
# cmake -DCMAKE_TOOLCHAIN_FILE=/path/to/Toolchain-OSX-x86_64.cmake ....

SET(CMAKE_SYSTEM_NAME Darwin)

SET(CMAKE_C_COMPILER x86_64-apple-darwin14-cc)
SET(CMAKE_CXX_COMPILER x86_64-apple-darwin14-c++)

# where is the target environment
SET(CMAKE_FIND_ROOT_PATH /home/jbliesener/src/osxcross/target/SDK/MacOSX10.10.sdk)

# adjust the default behaviour of the FIND_XXX() commands:
# search headers and libraries in the target environment, search
# programs in the host environment
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
