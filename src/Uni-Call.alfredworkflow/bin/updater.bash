#!/bin/bash
#
# This script will automatically download the newest `Uni Call.alfredworkflow`,
# verify its sha1 integrity, unzip it, and overwrite the old Uni Call Alfred
# workflow files with the new ones
#
# @Author: Guan Gui
# @Date:   2015-01-05 17:34:35
# @Email:  root@guiguan.net
# @Last modified by:   Guan Gui
# @Last modified time: 2015-01-13 01:46:45

sha1="$1"
unicall_bin_path=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
unicall_path=${unicall_bin_path%/bin}
tmp_dir="/var/tmp/net.guiguan.Uni-Call"
filename="Uni-Call.alfredworkflow"

declare -a on_exit_items

function on_exit()
{
    for i in "${on_exit_items[@]}"
    do
        echo -e "Cleaning up...\t$i"
        eval $i
    done
}

function add_on_exit()
{
    local n=${#on_exit_items[*]}
    on_exit_items[$n]="$*"
    if [[ $n -eq 0 ]]; then
        echo "Setting auto clean-up when exits..."
        trap on_exit EXIT
    fi
}

exec 1> >(logger -t "Uni Call Updater")
exec 2> >(logger -t "Uni Call Updater")

echo 'Killing Uni Call process...'
killall "Uni Call Satellite" > /dev/null 2>&1
echo 'Creating tmp directory...'
mkdir -p "$tmp_dir"
add_on_exit rm -rf "$tmp_dir"
cd "$tmp_dir"
echo 'Downloading the latest Uni Call from official website...'
curl -o "$filename" https://www.guiguan.net/download/uni-call-alfredworkflow/
if [ `openssl sha1 Uni-Call.alfredworkflow | awk '{print $2}'` != "$sha1" ]; then
    echo "Error: auto upgrade has failed, because the downloaded Uni Call file doesn't match the officially provided sha1 checksum" 1>&2
    "$unicall_bin_path/Uni Call.app/Contents/MacOS/Uni Call" -title "Auto upgrade failed" -message "The downloaded Uni Call is corrupted. Click me to visit Uni Call project page to manually download it" -sound "Ping" -group "upgrading" -open "http://unicall.guiguan.net" > /dev/null
    exit 1
fi
echo 'Unzipping...'
unzip -o "$filename" -d Uni-Call/ > /dev/null
echo 'Removing old Uni Call files...'
rm -rf $unicall_path/*
echo 'Deploying new Uni Call files...'
mv -f Uni-Call/* $unicall_path/
echo 'Relaunching Uni Call for post installation setup...'
sleep 2
osascript "$unicall_bin_path/invokealfredwithcmd.scpt" "call -"