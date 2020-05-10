# ==================================================================================================
# STARTUP WORKER
# ==================================================================================================
#

#!/usr/bin/env bash

. ./library.sh

set -e

checkInstall

firstTry=true
repeat=false

while [[ "$repeat" == true || "$firstTry" == true ]]
do
	firstTry=false
	repeat=false

	if [ "$PPLiveDevice" == 1 ]
	then
		response="y"
		validArgs=("y" "n")
		response=$(waitForUserResponse "Re-sync ProPresenter library with master database? (y/n)\r\n(This will overwrite your local changes)" validArgs[@])
	else
		response="y"
	fi

	if [ "$response" == "y" ]
	then
		syncMasterLibrary
		removeLeftoverPlaylistData
		copyLabelTemplateFile
		startProPresenter
	elif [ "$response" == "n" ]
	then
		startProPresenter
	fi
done
