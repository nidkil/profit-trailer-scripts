#!/bin/bash

# Get the current directory, the -P means if it is a symbolic link then follow it to the source directory
ORIG_DIR=$(pwd -P)
CUR_DIR=$(pwd)

source $CUR_DIR/script-helpers/helpers.sh

SYM_LINKS=$(find /opt/proft-trailer/*-cur -type l)

while read -r SYM_LINK; do
    echo "Publishing scripts to: $SYM_LINK"
	cp -f *.sh $SYM_LINK/.
	cp -rf script-helpers $SYM_LINK/.
	# We don't want this script to be published
	rm $SYM_LINK/publish-script.sh
	chmod u+x $SYM_LINK/*.sh
done <<< "$SYM_LINKS"