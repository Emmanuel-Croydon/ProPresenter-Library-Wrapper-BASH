#!/bin/bash

readEnvironmentConfig() {
    if [ $# -ne 2 ]
    then
        >&2 echo "Missing args in ${FUNCNAME[0]}"
        exit 1
    fi
    local caught=0
    export "$1"="$2" || caught=1
    
    if [ $caught == 1 ]
    then
        return 1
    else
        return 0
    fi
}

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
    	printf "$userActionRequired\n" 1>&2
    	read response
        
    	if [ $(elementIn "$response" "${validResponses[@]}") == "TRUE" ]
    	then
    		echo "$response"
    		return 0
    	else
    		echo "Invalid input $response. Please enter one of the following: $validResponsesString" 1>&2
    		echo "---------------------------------------------------------------------------" 1>&2
    	fi
    done
}

syncMasterLibrary() {
	echo "Pulling down library from master node....."
    
	echoDebug git -C "$PPLibraryPath" reset --hard
    echoDebug git -C "$PPLibraryPath" clean -f -d
    echoDebug git -C "$PPLibraryPath" checkout master
    
    local firstTry=true

    while [[ $firstTry == true || $retry == "y" ]] 
    do
    	firstTry=false
        local retry="n"
        local caught=0
        echoDebug git -C "$PPLibraryPath" pull || caught=1
        if [ $caught == 1 ]
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
	open -a "ProPresenter"
	return $?
}

getTrackedFilePath() {
    if [ $# -ne 1 ]
    then
        >&2 echo "Incorrect args in ${FUNCNAME[0]}"
        exit 1
    fi
    
    local filePath
    local quotedFilePathRegex="([^.])([\"\'])(.*)([\"\'])"
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
    
    filePath=$([[ "$1" =~ $untrackedFilePathRegex ]] && echo ${BASH_REMATCH[2]})
    echo "$filePath"
    return 0
}

getWorkingBranchName() {
    local branchName="$(git -C "$PPLibraryPath" rev-parse --abbrev-ref HEAD)"
    echoDebug echo '$branchName'
    echo "$branchName"
    return 0
}

newBranch() {
    local dateTime=$(date +"%Y-%m-%d_%H%M")
    local machine=$(hostname)
    local user=$(whoami)
    local branchName="AUTO/$machine/$user/$dateTime"
    echoDebug git -C "$PPLibraryPath" checkout -b "$branchName"
    echoDebug git -C "$PPLibraryPath" branch
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
        local caught=0
        
        echoDebug git -C "$PPLibraryPath" push --set-upstream origin "$1" || caught=1
        
        if [ $caught == 1 ]
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
    
    echoDebug echo 'Invoke commit'
    echoDebug git -C "$PPLibraryPath" add "$1"
    echoDebug git -C "$PPLibraryPath" status
    
    local dateTime=$(date +"%Y-%m-%d_%H%M")
    local machine=$(hostname)
    local user=$(whoami)
    local caught=0
    echoDebug echo 'Change added'
    echoDebug git -C "$PPLibraryPath" commit -m "$2 $1 $dateTime $machine/$user" || caught=1
    if [ $caught == 1 ]
    then
        >&2 echo "Commit failed, please contact support"
        return 1
    else
        echoDebug echo 'Change committed'
        return 0
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
    
    while [[ $firstTry == true || $retry == "y" ]]
    do
        firstTry=false
        retry="n"
        
        local caught=0
        echoDebug git -C "$PPLibraryPath" push || caught=1
        
        if [ $caught == 1 ]
        then
            >&2 echo -e "Failed to push changes. Please check your network connection and then retry.\nIf network is currently unavailable, please do the following:\n\n1) Restart the app when a network connection is available. Do NOT sync with master library on start up.\n2) Quit ProPresenter to retry adding your changes to the master library.\n\nIf this problem persists, please contact support." || true
            retry=$(waitForUserResponse "Retry?")
        else
            echo "Pushed branch $branchName"
        fi
    done
    return 0
}

newPullRequest() {
    if [ $# -ne 1 ]
    then
        >&2 echo "Incorrect args in ${FUNCNAME[0]}"
        exit 1
    fi
    
    local branchName="$1"
    local dateTime=$(date +"%Y-%m-%d %H%M")
    local githubRequestUri="https://api.github.com/repos/$PPRepoLocation/pulls"
    local json='{"title": "'"AUTO pull request: $dateTime"'", "body": "'"Pull Request created automatically by ProPresenter-Library-Wrapper at $dateTime"'", "head": "'"$branchName"'", "base": "master"}'
    
    local response=$(curl -X POST -H "Content-Type: application/json" -H "Accept: application/vnd.github.v3+json" -H "Authorization: token $PPLibraryAuthToken" -d "$json" "$githubRequestUri" -w "%{http_code}\n" -s -o /dev/null)
    
    if [[ $response == 201 ]]
    then
        echo "Successfully opened a pull request on $branchName"
        return 0
    else
        >&2 echo "An error has occurred. Please give the support team the following information to add your changes: $branchName"
        sleep 5
        return 1
    fi
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
        if [[ "$element" == "$match" ]]
        then
            echo "TRUE"
            return 0
        fi
    done
    echo "FALSE"
    return 0
}

echoDebug() {
    if [[ "$-" == *x* ]]
    then
        local output
        output=$("$@" 2>&1)
        local exitCode="$?"
        >&2 echo "$output"
    else
        local output=$("$@" 2>&1)
        local exitCode="$?"
    fi
    
    if [ "$exitCode" -ne 0 ]
    then
        return "$exitCode"
    else
        return 0
    fi
}

checkInstall() {
    declare -a envVars=("PPLibraryPath" "PPRepoLocation" "PPLiveDevice")
    
    for envVar in "${envVars[@]}"
    do
        if [ -z "$envVar" ]
        then
            "An error has occurred with the installation of the ProPresenter Library Wrapper. Please contact support."
            exit 1
        fi
    done
}

writeSplashScreen() {
    printf '\e[32m
██████╗ ██████╗  ██████╗ ██████╗ ██████╗ ███████╗███████╗███████╗███╗   ██╗████████╗███████╗██████╗
██╔══██╗██╔══██╗██╔═══██╗██╔══██╗██╔══██╗██╔════╝██╔════╝██╔════╝████╗  ██║╚══██╔══╝██╔════╝██╔══██╗
██████╔╝██████╔╝██║   ██║██████╔╝██████╔╝█████╗  ███████╗█████╗  ██╔██╗ ██║   ██║   █████╗  ██████╔╝
██╔═══╝ ██╔══██╗██║   ██║██╔═══╝ ██╔══██╗██╔══╝  ╚════██║██╔══╝  ██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗
██║     ██║  ██║╚██████╔╝██║     ██║  ██║███████╗███████║███████╗██║ ╚████║   ██║   ███████╗██║  ██║
╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
                                                                                                    
██╗     ██╗██████╗ ██████╗  █████╗ ██████╗ ██╗   ██╗
██║     ██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗╚██╗ ██╔╝
██║     ██║██████╔╝██████╔╝███████║██████╔╝ ╚████╔╝
██║     ██║██╔══██╗██╔══██╗██╔══██║██╔══██╗  ╚██╔╝
███████╗██║██████╔╝██║  ██║██║  ██║██║  ██║   ██║
╚══════╝╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝
                                                                                                    
██╗    ██╗██████╗  █████╗ ██████╗ ██████╗ ███████╗██████╗
██║    ██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗
██║ █╗ ██║██████╔╝███████║██████╔╝██████╔╝█████╗  ██████╔╝
██║███╗██║██╔══██╗██╔══██║██╔═══╝ ██╔═══╝ ██╔══╝  ██╔══██╗
╚███╔███╔╝██║  ██║██║  ██║██║     ██║     ███████╗██║  ██║
 ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝     ╚══════╝╚═╝  ╚═╝
                                                              
                                                              
                                                              
                                                              
\e[0m
'
    sleep 1
    return 0
}
