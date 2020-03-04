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

	# TODO: redirect to debug output
	git -C $envPPLibraryPath reset --hard
    git -C $envPPLibraryPath clean -f -d
    git -C $envPPLibraryPath checkout master
    
    firstTry=true

    while [[ $firstTry == true || $retry == "y" ]] 
    do
    	firstTry=false
        retry="n"
        git -C $envPPLibraryPath pull
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
	# TODO: only write this on debug please
	echo "Removing playlist data..."
	rm -rf "$envPPPlayListLocation/*.pro6pl"
	echo "Removed."
	# TODO: check no differences in format between windows and mac
	echo "Copying default playlist file across..."
	cp "$envPPLibraryPath/Config Templates/Default.pro6pl" "$envPPPlayListLocation/Default.pro6pl"
	echo "Copied"
	return 0
}

copyLabelTemplateFile () {
	# TODO: only write this on debug please
	# TODO: check no differences in format or content between windows and mac
	echo "Copying label templates across..."
	cp "$envPPLibraryPath/Config Templates/LabelsPreferences.pro6pref" "$envPPLabelLocation/LabelsPreferences.pro6pref"
	echo "Copied."
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
