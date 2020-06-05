#!/bin/bash

# ==================================================================================================
# TERMINATION WORKER
# ==================================================================================================
#

. ./library.sh

set -e

propertiesFile="./envConfig.properties"
while IFS="=" read -r key value
do
    readEnvironmntConfig "$key" "$value"
done < "$propertiesFile"

checkInstall

branchName=$(getWorkingBranchName)

exec 3<>/dev/null
git -C "$PPLibraryPath" status --porcelain=v1 >3

while IFS= read -r -u4 line
do
    validArgs=("y" "n")
    commitBool="n"
    untrackedRegex="^\?\? "
    modifiedRegex="^ M "
    deletedRegex="^ D "
    
    if [[ "$line" =~ $untrackedRegex ]]
    then
        changeType="Added"
        filePath=$(getUntrackedFilePath "$line")
        commitBool=$(waitForUserResponse "Add '$filePath'?" validArgs[@])
    elif [[ "$line" =~ $modifiedRegex ]]
    then
        changeType="Modified"
        filePath=$(getTrackedFilePath "$line")
        # TODO: get UUID regenerations and filter out
        commitBool=$(waitForUserResponse "Modify '$filePath'?" validArgs[@])
    elif [[ "$line" =~ $deletedRegex ]]
    then
        changeType="Removed"
        filePath=$(getTrackedFilePath "$line")
        commitBool=$(waitForUserResponse "Remove '$filePath'?" validArgs[@])
    else
        echo "Unknown object - please contact support"
        commitBool="n"
    fi
    
    if [ "$commitBool" == "y" ]
    then
        if [ "$branchName" == "master" ]
        then
            newBranch
            branchName=$(getWorkingBranchName)
            invokeChangeCommit "$filePath" "$changeType"
        else
            invokeChangeCommit "$filePath" "$changeType"
        fi
    elif [ "$commitBool" == "n" ]
    then
        # Do Nothing
        echoDebug echo "commitBool == n"
    fi
done 4<3

if [ "$branchName" != "master" ]
then
    invokeChangePush "$branchName"
    newPullRequest "$branchName"
else
    echo "No changes added."
fi

exec 3>&-
rm 3
