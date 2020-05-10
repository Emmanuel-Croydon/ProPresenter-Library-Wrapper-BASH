#!/usr/bin/env bash

# ==================================================================================================
# TERMINATION WORKER
# ==================================================================================================
#


. ./library.sh

set -e

branchName=$(getWorkingBranchName)

git -C "$PPLibraryPath" status --porcelain=v1 | while IFS= read -r line
do
    commitBool="n"
    untrackedRegex="^\?\? "
    modifiedRegex="^ M "
    deletedRegex="^ D "
    
    if [[ "$line" =~ $untrackedRegex ]]
    then
        changeType="Added"
        filePath=$(getUntrackedFilePath "$line")
        response=$(waitForUserResponse "Add '$filePath'?" validArgs[@])
    elif [[ "$line" =~ $modifiedRegex ]]
    then
        changeType="Modified"
        filePath=$(getTrackedFilePath "$line")
        # TODO: get UUID regenerations and filter out
        response=$(waitForUserResponse "Modify '$filePath'?" validArgs[@])
    elif [[ "$line" =~ $deletedRegex ]]
    then
        changeType="Removed"
        filePath=$(getTrackedFilePath "$line")
        response=$(waitForUserResponse "Remove '$filePath'?" validArgs[@])
    else
        echo "Unknown object - please contact support"
        commitBool="n"
    fi
    
    if [ "$commitBool" == "y" ]
    then
        if [ "$branchName" == "master" ]
        then
            branchName=newBranch
            invokeChangeCommit "$filePath" "$changeType"
        else
            invokeChangeCommit "$filePath" "$changeType"
        fi
    elif [ "$commitBool" == "n" ]
    then
        # Do Nothing
        echoDebug "commitBool == n"
    fi
done

if [ "$branchName" != "master" ]
then
    invokeChangePush "$branchName"
    #TODO: PR process
    echo "PR process"
else
    echo "No changes added."
fi
