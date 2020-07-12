#!/bin/bash

# ==================================================================================================
# TERMINATION WORKER
# ==================================================================================================
#

# TODO: work out how to build and distribute

. ./library.sh

set -e

propertiesFile="./envConfig.properties"
while IFS="=" read -r key value
do
    readEnvironmentConfig "$key" "$value"
done < "$propertiesFile"

checkInstall
clear

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
        reformatXML "$filePath"
        commitBool=$(waitForUserResponse "Add '$filePath'?" validArgs[@])
    elif [[ "$line" =~ $modifiedRegex ]]
    then
        changeType="Modified"
        filePath=$(getTrackedFilePath "$line")
        reformatXML "$filePath"
        
        onlyLineChanges=$(onlyLineChanges "$filePath")
        echoDebug echo "LINECHANGES: $onlyLineChanges"
        uuidRegen=$(getUuidRegen "$filePath")
        echoDebug echo "UUIDREGEN: $uuidRegen"
        
        if [[ "$onlyLineChanges" == "FALSE" ]] && [[ "$uuidRegen" == "FALSE" ]]
        then
            commitBool=$(waitForUserResponse "Modify '$filePath'?" validArgs[@])
        fi
    elif [[ "$line" =~ $deletedRegex ]]
    then
        changeType="Removed"
        filePath=$(getTrackedFilePath "$line")
        reformatXML "$filePath"
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

exec 3>&- && rm 3
