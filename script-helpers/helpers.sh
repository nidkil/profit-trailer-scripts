#!/bin/bash
source $CUR_DIR/script-helpers/color_vars.sh

# Usage: print_err "Error: could not find file [./tmp/does-not-exist]"
print_err() {
    echo ""
    echo -e "${Red}${1}${Color_Off}"
}

# Usage: download https://github.com/taniman/profit-trailer/releases/download/v1.2.6.20/ProfitTrailer.zip
download() {
    if [ "" = "$1" ]; then
        print_err "ERROR: Url not specified"
        exit
    fi
    local URL=$1
    echo $URL
    wget $URL -P $2 -o debug.log
}

# Usage: unique_bck_dir backup
unique_bck_dir() {
    if [ "" = "$1" ]; then
        print_err "ERROR: Backup directory not specified"
        exit
    fi
    local BCK_DIR=$1
    local DT=$(date +"%Y%m%d")
    N=0
    while [ $N -lt 10 ]; do
        BCK_SUBDIR=`printf %s-%02d $DT $N`
        if [ ! -d "$BCK_DIR/$BCK_SUBDIR" ]; then
           break
        fi
        N=$((N+=1))
    done
	echo $BCK_DIR/$BCK_SUBDIR
}

# Usage: del_dir tmp
del_dir() {
    if [ "" = "$1" ]; then
        print_err "ERROR: Directory not specified"
        exit
    fi
    if [ -d "$1" ]; then
        rm -rf $1
    fi
}

# Usage: del_file tmp/PAIR.properties
del_file() {
    if [ "" = "$1" ]; then
        print_err "ERROR: File not specified"
        exit
    fi
    if [ -f "$1" ]; then
        rm $1
    fi
}

# Usage: dir_exists /opt/profit-trailer/pt-binance-cur
# Usage: dir_exists /opt/profit-trailer/pt-binance-cur true
dir_exists() {
    if [ "" = "$1" ]; then
        print_err "ERROR: Directory not specified"
        exit
    fi
    if [[ $# -eq 2 && ( "$2" != "true" && "$2" != "false" ) ]]; then
        print_err "ERROR: Show ERROR can be: true or false"
        exit
    fi
    if [[ (! -d "$1") && (! -e "$1") ]]; then
        if [[ $2 == "true" ]]; then
            print_err "ERROR: Directory not found, please check the directory [$1]"
            # The following function must be defined in the main script
            handle_error
        fi
        echo "false"
    else
        echo "true"
    fi
}

# Usage: get_latest_release "taniman/profit-trailer"
get_latest_release() {
	RELEASE=$(curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub API
		grep '"tag_name":' |                                          			# Get tag_name line
		sed -E 's/.*"([^"]+)".*/\1/')                                  			# Get the version number
	echo $RELEASE
}

# Usage: stop_pt /opt/profit-trailer/pt-binance-cur
stop_pt() {
    if [ "" = "$1" ]; then
        print_err "ERROR: Directory not specified"
        exit
    fi
	PT_DIR=$1
	PORT=`cat $PT_DIR/application.properties | grep server.port`
	PORT=${PORT#*= }
	PWD=`cat $PT_DIR/application.properties | grep server.password`
	PWD=${PWD#*= }
	echo "Shutting down Profit Trailer [port=$PORT, pwd=$PWD]"
	STATUS=$(curl -c cookie-jar.txt -L -d "password=$PWD" http://localhost:${PORT}/login --write-out %{http_code} --silent --output /dev/null)
	echo "Server login response: $STATUS"
	STATUS=$(curl -b cookie-jar.txt -L http://localhost:${PORT}/stop --write-out %{http_code} --silent --output /dev/null)
	echo "Server stopped"
	pm2 list
}

# Usage: get_pm2_id pm2-PTMagic.json
get_pm2_id() {
    if [ "" = "$1" ]; then
        print_err "ERROR: pm2 config file not specified"
        exit
    fi
    if [ ! -f "$1" ]; then
        print_err "ERROR: pm2 config file not found [$1]"
        exit
    fi
	RESULT=$(cat $1 | grep name | sed -E "s/\"name\": \"(.*)\",/\1/")
	echo $RESULT
}