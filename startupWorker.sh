# export envPPPlayListLocation="/Users/jon/Library/Application Support/RenewedVision/ProPresenter6/Playlists"
# export envPPLiveDevice=1
# export envPPLibraryPath="/Volumes/Data/Jon/Workspace/TestRepo/ProPresenter-Test-Library"
# export envPPLabelLocation="/Users/jon/Library/Preferences/com.renewedvision.ProPresenter6"


#!/bin/bash

. ./library.sh

# TODO: this probably needs to move to orchestration worker
set -e

firstTry=true
repeat=false

while [[ "$repeat" == true || "$firstTry" == true ]]
do
	firstTry=false
	repeat=false

	if [ $envPPLiveDevice -eq 1 ]
	then
		response="y"
		validArgs=("y" "n")
		waitForUserResponse "Re-sync ProPresenter library with master database? (y/n)\r\n(This will overwrite your local changes)" validArgs[@]
		response="$responseReturned"
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