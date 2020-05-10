#!/usr/bin/env bash


waitForUserResponse() {
    if [ $# -eq 0 ]
    then
    	>&2 echo "Missing args in ${FUNCNAME[0]}"
    	exit 1
    elif [ $# -eq 1 ]
    then
    	local userActionRequired="$1"
    	local validResponses=("y" "n")
    else
	    local userActionRequired="$1"
	    local validResponses=("${!2}")
    fi
    
    local validResponsesString=$(printf ", %s" "${validResponses[@]}")
    validResponsesString="${validResponsesString:2}"
    
    local response

    while [ 1 -eq 1 ]
    do
    	printf "$userActionRequired\n"
    	read response

    	if [ $(elementIn "$response" "${validResponses[@]}") == true ]
    	then
    		echo "$response"
    		return 0
    	else
    		echo "Invalid input. Please enter one of the following: $validResponsesString"
    		echo "---------------------------------------------------------------------------"
    	fi
    done
}

syncMasterLibrary() {
	echo "Pulling down library from master node....."

	echoDebug "$(git -C "$PPLibraryPath" reset --hard)"
    echoDebug "$(git -C "$PPLibraryPath" clean -f -d)"
    echoDebug "$(2>&1 git -C "$PPLibraryPath" checkout master)"
    
    local firstTry=true

    while [[ $firstTry == true || $retry == "y" ]] 
    do
    	firstTry=false
        local retry="n"
        echoDebug "$(git -C "$PPLibraryPath" pull)"
        if [ $? -ne 0 ]
        then
            >&2 echo "Failed to sync with master library. Please check your network connection and then retry." || true
            retry=$(waitForUserResponse "Retry?")
        else
            echo "Completed."
        fi
    done
    return 0
}

startProPresenter() {
	echo "Starting ProPresenter....."
	open -a "ProPresenter 6"
	return $?
}

removeLeftoverPlaylistData() {
	echoDebug "Removing playlist data..."
	rm -rf "$PPPlayListLocation/*.pro6pl"
	echoDebug "Removed."
	echoDebug "Copying default playlist file across..."
	cp "$PPLibraryPath/Config Templates/macOS_Default.pro6pl" "$PPPlayListLocation/Default.pro6pl"
	echoDebug "Copied"
	return 0
}

copyLabelTemplateFile() {
	echoDebug "Copying label templates across..."
	cp "$PPLibraryPath/Config Templates/macOS_LabelSettings.xml" "$PPLabelLocation/LabelSettings.xml"
	echoDebug "Copied."
	return 0
}

getTrackedFilePath() {
    if [ $# -ne 1 ]
    then
        >&2 echo "Incorrect args in ${FUNCNAME[0]}"
        exit 1
    fi
    
    local filePath
    local quotedFilePathRegex="(.*)([\"\'])(.*)([\"\'])"
    local unquotedFilePathRegex="( [MD] )(.*)"
    
    filePath=$([[ "$1" =~ $quotedFilePathRegex ]] && echo ${BASH_REMATCH[3]})
    
    if [ -z "$filePath" ]
    then
        filePath=$([[ "$1" =~ $unquotedFilePathRegex ]] && echo ${BASH_REMATCH[2]})
    fi
    echo "$filePath"
    return 0
}

getUntrackedFilePath() {
    if [ $# -ne 1 ]
    then
        >&2 echo "Incorrect args in ${FUNCNAME[0]}"
        exit 1
    fi
    
    local filePath
    local untrackedFilePathRegex="(\?\? )(.*)"
    
    filePath=$([[ "$1" =~ $quotedFilePathRegex ]] && echo ${BASH_REMATCH[2]})
    echo "$filePath"
    return 0
}

getWorkingBranchName() {
    local branchName=$(git -C "$PPLibraryPath" rev-parse --abbrev-ref HEAD)
    echoDebug "$branchName"
    echo "$branchName"
    return 0
}

newBranch() {
    local dateTime=$(date +"%Y-%m-%d_%H%M")
    local machine=$(hostname)
    local user=$(whoami)
    local branchName="AUTO/$machine/$user/$dateTime"
    echoDebug "$(2>&1 git -C "$PPLibraryPath" checkout -b "$branchName")"
    if [ $? -eq 0 ]
    then
        invokeBranchPush "$branchName"
        return $?
    fi
}

invokeBranchPush() {
    if [ $# -ne 1 ]
    then
        >&2 echo "Incorrect args in ${FUNCNAME[0]}"
        exit 1
    fi
    
    local firstTry=true
    local retry
    echo "Creating branch"
    
    while [[ $firstTry == true || $retry == "y" ]]
    do
        firstTry=false
        retry="n"
        
        echoDebug $(2>&1 git -C "$PPLibraryPath" push --set-upstream origin "$1")
        
        if [ $? -ne 0 ]
        then
            >&2 echo -e "Failed to push branch. Please check your network connection and then retry.\nIf network is currently unavailable, please do the following:\n\n1) Restart the app when a network connection is available. Do NOT sync with master library on start up.\n2) Quit ProPresenter to retry adding your changes to the master library.\n\nIf this problem persists, please contact support." || true
            retry=$(waitForUserResponse "Retry?")
        else
            echo "Successfully pushed branch $branchName"
        fi
    done
    return 0
}

invokeChangeCommit() {
    if [ $# -ne 2 ]
    then
        >&2 echo "Incorrect args in ${FUNCNAME[0]}"
        exit 1
    fi
    
    echoDebug "Invoke commit"
    echoDebug $(2>&1 git -C "$PPLibraryPath" add "$1")
    
    local dateTime=$(date +"%Y-%m-%d_%H%M")
    local machine=$(hostname)
    local user=$(whoami)
    echoDebug "Change added"
    echoDebug $(2>&1 git -C "$PPLibraryPath" commit -m "$2 $1 $dateTime $machine/$user")
    if [ $? -ne 0 ]
    then
        echoDebug "Change committed"
        return 0
    else
        >&2 echo "Commit failed, please contact support"
        return 1
    fi
}

invokeChangePush() {
    if [ $# -ne 1 ]
    then
        >&2 echo "Incorrect args in ${FUNCNAME[0]}"
        exit 1
    fi
    
    local firstTry=true
    local retry
    echo "Creating branch"
    
    while [[ $firstTry == true || $retry == "y" ]]
    do
        firstTry=false
        retry="n"
        
        echoDebug $(2>&1 git -C "$PPLibraryPath" push)
        
        if [ $? -ne 0 ]
        then
            >&2 echo -e "Failed to push changes. Please check your network connection and then retry.\nIf network is currently unavailable, please do the following:\n\n1) Restart the app when a network connection is available. Do NOT sync with master library on start up.\n2) Quit ProPresenter to retry adding your changes to the master library.\n\nIf this problem persists, please contact support." || true
            retry=$(waitForUserResponse "Retry?")
        else
            echo "Pushed branch $branchName"
        fi
    done
    return 0
}

elementIn() {
	if [ $# -lt 2 ]
    then
    	>&2 echo "Missing args in ${FUNCNAME[0]}"
    	exit 1
    fi

	local element
    local match="$1"
	shift
	for element
    do
        [[ "$e" == "$match" ]] && echo true && return 0
    done
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

checkInstall() {
    declare -a envVars=("PPLibraryPath" "PPRepoLocation" "PPLabelLocation" "PPPlayListLocation" "PPLiveDevice")
    
    for envVar in "${envVars[@]}"
    do
        if [ -z "$envVar" ]
        then
            "An error has occurred with the installation of the ProPresenter Library Wrapper. Please contact support."
            exit 1
        fi
    done
}
