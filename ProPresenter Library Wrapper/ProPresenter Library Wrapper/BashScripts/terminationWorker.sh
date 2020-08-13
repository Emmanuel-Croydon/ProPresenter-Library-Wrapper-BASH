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
    readEnvironmentConfig "$key" "$value"
done < "$propertiesFile"

checkInstall
clear

branchName=$(getWorkingBranchName)
validArgs=("y" "n")

exec 3<>/dev/null

for directory in $(ls "$PPLibraryPath")
do
    git -C "$PPLibraryPath" status "$PPLibraryPath/$directory" --porcelain=v1 >3

    if [[ $(git -C "$PPLibraryPath" status "$PPLibraryPath/$directory" --porcelain=v1) && "$directory" != 'Playlists' && $(waitForUserResponse "Make changes to '$directory'?" validArgs[@]) == 'y' ]]
    then
        while IFS= read -r -u4 line
        do
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
    fi
done

if [ "$branchName" != "master" ]
then
    invokeChangePush "$branchName"
    newPullRequest "$branchName"
else
    echo "No changes added."
fi

exec 3>&- && rm 3
