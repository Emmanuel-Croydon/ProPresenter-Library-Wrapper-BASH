#!/bin/bash


waitForUserResponse() {
    if [ $# -eq 0 ]
    then
    	>&2 echo "Missing args in ${FUNCNAME[0]}"
    	exit 1
    elif [ $# -eq 1 ]
    then
    	userActionRequired="$1"
    	validResponses=("y" "n")
    else
	    userActionRequired="$1"
	    validResponses=("${!2}")
    fi
    
    validResponsesString=$(printf ", %s" "${validResponses[@]}")
    validResponsesString="${validResponsesString:2}"

    while [ 1 -eq 1 ]
    do
    	printf "$userActionRequired\n"
    	read response
    	responseValid=$(elementIn "$response" "${validResponses[@]}")
    	if [ "$responseValid" == true ]
    	then
    		responseReturned="$response"
    		return 0
    	else
    		echo "Invalid input. Please enter one of the following: $validResponsesString"
    		echo "---------------------------------------------------------------------------"
    	fi
    done
}

syncMasterLibrary() {
	echo "Pulling down library from master node....."

	echoDebug "$(git -C $envPPLibraryPath reset --hard)"
    echoDebug "$(git -C $envPPLibraryPath clean -f -d)"
    echoDebug "$(2>&1 git -C $envPPLibraryPath checkout master)"
    
    firstTry=true

    while [[ $firstTry == true || $retry == "y" ]] 
    do
    	firstTry=false
        retry="n"
        echoDebug "$(git -C $envPPLibraryPath pull)"
        if [ $? -ne 0 ]
        then
            >&2 echo "Failed to sync with master library. Please check your network connection and then retry." || true
            waitForUserResponse "Retry?"
            retry="$responseReturned"
        else
            echo "Completed."
        fi
    done
}

startProPresenter() {
	echo "Starting ProPresenter....."
	open -a "ProPresenter 6"
	# TODO: work out how to manage the process on a mac... do I need to return a pid here?
	return $?
}

removeLeftoverPlaylistData() {
	echoDebug "Removing playlist data..."
	rm -rf "$envPPPlayListLocation/*.pro6pl"
	echoDebug "Removed."
	echoDebug "Copying default playlist file across..."
	cp "$envPPLibraryPath/Config Templates/macOS_Default.pro6pl" "$envPPPlayListLocation/Default.pro6pl"
	echoDebug "Copied"
	return 0
}

copyLabelTemplateFile () {
	echoDebug "Copying label templates across..."
	cp "$envPPLibraryPath/Config Templates/macOS_LabelSettings.xml" "$envPPLabelLocation/LabelSettings.xml"
	echoDebug "Copied."
	return 0
}

elementIn() {
	if [ $# -lt 2 ]
    then
    	>&2 echo "Missing args in ${FUNCNAME[0]}"
    	exit 1
    fi

	local e match="$1"
	elementIn=false
	shift
	for e; do [[ "$e" == "$match" ]] && elementInArr=true; done
	echo "$elementInArr"
	return 0
}

echoDebug() {
	if [ $# -lt 1 ]
    then
    	>&2 echo "Missing args in ${FUNCNAME[0]}"
    	exit 1
    fi

	if [[ "$-" == *"x"* ]]
	then
		echo "$1"
	fi
	return 0
}
