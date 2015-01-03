#! /bin/bash
#
# clean target directories
find build -mindepth 1 -maxdepth 1 -type d -not \( -name 'libs' -or -name 'progs' \) -print0 | xargs -0 -I {} rm -rf {}

