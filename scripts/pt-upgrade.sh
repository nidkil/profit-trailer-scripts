#!/bin/bash

# Get the current directory, the -P means if it is a symbolic link then follow it to the source directory
ORIG_DIR=$(pwd -P)
CUR_DIR=$(pwd)

source $CUR_DIR/helper-scripts/helpers.sh

# Get the parent directory of the current directory
PARENT_DIR=`dirname $ORIG_DIR`
# Strip the version number from the current directory
BASE_PATH=${ORIG_DIR%-v*}
CUR_INSTALLED=${ORIG_DIR#*-v}
# Setup some constants
ROOT_DIR="profit-trailer"
CFG_DIR="trading"
BCK_DIR="backup"
# Use parameter expansion to extract the exchange identifier
EXCHANGE=${BASE_PATH##*/pt-}
# Use parameter expansion to extract the final directory from the path
DIR_ONLY=${CUR_DIR##*/}

# Get the latest PT release
LATEST_RELEASE=$(get_latest_release "taniman/profit-trailer")

# Lets make sure we have a version number with 'v' and without
VERSION=$LATEST_RELEASE
if [[ ${VERSION:0:1} != "v" ]]; then
	VERSION_NUM=$VERSION
	VERSION="v$VERSION"
else
	POS=$((${#VERSION} - 1))
	VERSION_NUM=${VERSION:1:$POS}
fi

# Create the download link
BASE_URL="https://github.com/taniman/profit-trailer/releases/download"
FILE_NAME="ProfitTrailer.zip"
URL="$BASE_URL/$VERSION/$FILE_NAME"

TMP_DIR="tmp"
LOGS_DIR="logs"
WORK_DIR="$PARENT_DIR/pt-$EXCHANGE-$VERSION"
PREV_DIR=$ORIG_DIR

handle_error() {
    echo ""
    echo "This script upgrades a Profit Trailer (PT) instance to the latest version. It downloads"
    echo "the latest version from GitHub and installs it to a new directory. It copies the config"
	echo "and data files from a previous PT version to the new version. To do this safely it stops"
	echo "and restarts PT. Once the config and data files have been copied it will change the "
	echo "softlink (see important) to the new version. The old version will be kept in case a rollback"
	echo "is required."
    echo ""
	echo "This script must be run from inside the directory of the current PT instance you wish to"
	echo "upgrade. If the latest version is already installed it will display a warning message and"
	echo "exit."
    echo ""
    echo "IMPORTANT:"
    echo ""
	echo "1) This script expects that the following directory layout is used:"
    echo ""
    echo "  /opt/profit-trailer/pt-<exchange>-cur     softlink pointing to the current PT version"
    echo "  /opt/profit-trailer/pt-<exchange>-v<num>  current version and new version have different"
    echo "                             				  version numbers"
    echo ""
	echo "2) It also expects that PM2 is used to manage PT and process identifiers conform with the"
	echo "   following naming convention:"
    echo ""
    echo "  - pt-<exchange>  Profit Trailer"
    echo ""
    echo "Where <exchange> identifies the exchange the PT instance is running against."
    echo ""
	echo "The script will extract the unique exchange identifier from the directory name it is executed "
	echo "from."
	echo ""
    echo "Usage: pt-upgrade.sh [-d]"
    echo ""
    echo " -d  show initialized variables and exit script, for debugging purposes only"
    echo ""
    echo "Example: pt-upgrade.sh"
    echo ""
    exit
}

debug_info() {
	echo ""
	echo " ------------------- DEBUG INFO ----------"
	echo ""
	echo "    ORIG_DIR       : $ORIG_DIR"
	echo "    CUR_DIR        : $CUR_DIR"
	echo "    PARENT_DIR     : $PARENT_DIR"
	echo "    BASE_PATH      : $BASE_PATH"
	echo "    ROOT_DIR       : $ROOT_DIR"
	echo "    CFG_DIR        : $CFG_DIR"
	echo "    BCK_DIR        : $BCK_DIR"
	echo "    EXCHANGE       : $EXCHANGE"
	echo "    DIR_ONLY       : $DIR_ONLY"
	echo ""
	echo "    CUR_INSTALLED  : $CUR_INSTALLED"
	echo "    LATEST_RELEASE : $LATEST_RELEASE"
	echo "    VERSION        : $VERSION"
	echo "    VERSION_NUM    : $VERSION_NUM"
	echo ""
	echo "    BASE_URL       : $BASE_URL"
	echo "    FILE_NAME      : $FILE_NAME"
	echo "    URL            : $URL"
	echo ""
	echo "    TMP_DIR        : $TMP_DIR"
	echo "    LOGS_DIR       : $LOGS_DIR"
	echo "    WORK_DIR       : $WORK_DIR"
	echo "    PREV_DIR       : $PREV_DIR"
	echo ""
	echo " ------------------- DEBUG INFO ----------"
	echo ""
	exit
}

if [ $# -ne 0 ]; then
	if [[ $# -gt 1 ]]; then
		print_err "Error: Incorrect number of parameters, found $# but expected 1"
		handle_error	
	elif [[ $# -eq 1 && "$1" = "-d" ]]; then
		debug_info
	else
		print_err "Error: Unknown parameters [$1]"
		handle_error
	fi
fi

if [[ ("$DIR_ONLY" != "pt-"*) || ("$DIR_ONLY" != *"-cur") ]]; then
    print_err "Error: this script must be executed from the active (current) version of PT"
    handle_error
fi

if [[ "$CUR_INSTALLED" = "$LATEST_RELEASE" ]]; then
	echo -e "${Cyan}Latest version is already installed${Color_Off}"
	exit
else
	echo "There is a new release available [$LATEST_RELEASE]"
fi

echo "Checking if url exists [$URL]"
STATUS=$(curl -s --head -w %{http_code} $URL -o /dev/null)
if [[ $STATUS -ne 200 && $STATUS -ne 302 ]]; then
    print_err "Error: URL not found [code=$STATUS, URL=$URL]"
    print_err "       Check the version number [version=$VERSION]"
    handle_error
fi

if [[ "$CUR_DIR" == "$WORK_DIR" ]]; then
    echo "Current directory and working directory are the same [$WORK_DIR]"
else
    echo "Checking if working directory exists [$WORK_DIR]"
    EXISTS=$(dir_exists $WORK_DIR false)
    if [[ "$EXISTS" != "false" ]]; then
        echo -e "${Cyan}WARNING: Working directory exists [$WORK_DIR], delete it if you want to continue${Color_Off}"
		exit
    fi
fi

read -p "Are you sure you want to update to version ${LATEST_RELEASE} [yN]?" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit
fi
    
echo "Creating working directory [$WORK_DIR]"
mkdir -p $WORK_DIR

echo "Changing to working directory [$WORK_DIR]"
cd $WORK_DIR

echo "Downloading zip file from URL [$URL]"
download $URL .
echo "Unzipping zip file to temporary directory [$TMP_DIR]"
unzip -q *.zip -d ./$TMP_DIR

echo "Moving files from temporary directory [$TMP_DIR] to main directory [$WORK_DIR]"
mv $TMP_DIR/ProfitTrailer/* .
echo "Creating logs directory"
mkdir logs

echo "Cleaning up: deleting zip file, tmp directory and debug file"
rm *.zip debug.log
rm -rf $TMP_DIR

echo "Stopping Profit Trailer [$PREV_DIR]"
stop_pt $PREV_DIR

echo "Removing existing config files"
rm *.properties ./$CFG_DIR/*.properties

if [[ "$(dir_exists ./$LOGS_DIR)" == "false" ]]; then
	echo "Creating logs directory"
	mkdir ./$LOGS_DIR
fi

echo "Copying config files"
cp $PREV_DIR/configuration.properties .
cp $PREV_DIR/application.properties .
cp $PREV_DIR/$CFG_DIR/*.properties ./$CFG_DIR/.

echo "Copying data and log files"
cp $PREV_DIR/$LOGS_DIR/*.log ./$LOGS_DIR/.
cp $PREV_DIR/ProfitTrailerData.json* .

echo "Copying scripts"
cp $PREV_DIR/*.sh .
cp -r $PREV_DIR/script-helpers .

echo "Copying PM2 file"
cp -f $PREV_DIR/pm2-ProfitTrailer.json .

echo "Changing the softlink to the new version"
rm $CUR_DIR
ln -s $WORK_DIR $BASE_PATH-cur

echo "Cleaning up"
del_file cookie-jar.txt
del_file debug.log

echo "Make executable"
chmod 770 Run-ProfitTrailer.cmd

echo "Restarting Profit Trailer (PT) for: $EXCHANGE"
# We need to delete the previous PM2 profile, as it is pointing to the directory of the old PT version
pm2 delete pt-$EXCHANGE
pm2 start pm2-ProfitTrailer.json
