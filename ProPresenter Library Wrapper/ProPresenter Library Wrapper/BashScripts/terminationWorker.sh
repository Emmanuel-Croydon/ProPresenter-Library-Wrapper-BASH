#!/bin/bash

# ==================================================================================================
# TERMINATION WORKER
# ==================================================================================================
#

. ./library.sh

set -e

propertiesFile=~/Library/Preferences/ProPresenter\ Library\ Wrapper/envConfig.properties
while IFS="=" read -r key value
do
    readEnvironmentConfig "$key" "$value"
done < "$propertiesFile"

checkInstall
clear

if [ "$PPReadOnlyDevice" == 0 ]
then

    branchName=$(getWorkingBranchName)
    validArgs=("y" "n")

    for directory in $(ls "$PPLibraryPath")
    do
        changeTypes=("Added" "Modified" "Removed" "Unknown")
        
        for changeType in "${changeTypes[@]}"
        do
            rm -f "$TMPDIR/statusFilter"
            touch "$TMPDIR/statusFilter"
            statusPresent=0
            
            if [[ "$changeType" == 'Added' ]]
            then
                matcher="^\?\? "
                dirLevelMessage="Add items to '$directory'?"
                fileLevelMessage="    - Add '<FilePath>'?"
            elif [[ "$changeType" == 'Modified' ]]
            then
                matcher="^ M "
                dirLevelMessage="Modify items in '$directory'?"
                fileLevelMessage="    - Modify '<FilePath>'?"
            elif [[ "$changeType" == 'Removed' ]]
            then
                matcher="^ D "
                dirLevelMessage="Remove items from '$directory'?"
                fileLevelMessage="    - Remove '<FilePath>'?"
            elif [[ "$changeType" == 'Unknown' ]]
            then
                matcher="^(?!\?\? .*$)(?! D .*$)(?! M .*$).*"
            fi
            
            git -C "$PPLibraryPath" status "$PPLibraryPath/$directory" --porcelain=v1 >"$TMPDIR/status"
            
            while IFS= read -r -u3 line
            do
                if [[ "$line" =~ $matcher && changeType == 'Unknown' ]]
                then
                    echo 'Unknown change object detected - please contact support'
                elif [[ "$line" =~ $matcher && "$line" != *"Playlists/Library"* ]]
                then
                    echoDebug "$line"
                    echo "$line" >>"$TMPDIR/statusFilter"
                    statusPresent=1
                fi
            done 3<"$TMPDIR/status"

            if [[ "$changeType" != 'Unknown' && "$statusPresent" == 1 && $(waitForUserResponse "$dirLevelMessage" validArgs[@]) == 'y' ]]
            then
                echo ''
                while IFS= read -r -u5 line
                do
                    commitBool="n"
                    
                    if [[ "$line" =~ $matcher && "$changeType" == 'Added' ]]
                    then
                        filePath=$(getUntrackedFilePath "$line")
                        commitBool=$(waitForUserResponse "${fileLevelMessage/<FilePath>/$filePath}" validArgs[@])
                    elif [[ "$line" =~ $matcher ]]
                    then
                        filePath=$(getTrackedFilePath "$line")
                        if [[ "$filePath" != 'Playlists/Library' ]]
                        then
                            commitBool=$(waitForUserResponse "${fileLevelMessage/<FilePath>/$filePath}" validArgs[@])
                        else
                            commitBool="n"
                        fi
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
                done 5<"$TMPDIR/statusFilter"
                
                echo ''
                rm "$TMPDIR/status"
                rm "$TMPDIR/statusFilter"
            fi
        done
    done

    if [ "$branchName" != "master" ]
    then
        invokeChangePush "$branchName"
        newPullRequest "$branchName"
    else
        echo "No changes added."
    fi
fi
