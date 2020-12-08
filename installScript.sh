# ==================================================================================================
# DEPLOYMENT SCRIPT
# ==================================================================================================
#

#!/bin/bash

set -e

checkRootPrivileges() {
	if [ $EUID -ne 0 ]
	then
		echo "$0 is not running as root. Please use sudo"
		exit 2
	fi
}

getResponseObject() {
	if [ $# -ne 2 ]
    then
        >&2 echo "Missing args in ${FUNCNAME[0]}"
        exit 1
    fi

    while IFS=" " read -r line
	do
		local splitLine=($(echo $line | tr "=" "\n"))
		local key=${splitLine[0]}
		local value=${splitLine[1]}

		if [ "$key" == "$2" ]
		then
			echo "$value"
			return 0
		fi
	done <<< "$1"

	echo 'ITEM NOT FOUND'
	return 0
}

urlDecode() {
	if [ $# -ne 1 ]
    then
        >&2 echo "Missing args in ${FUNCNAME[0]}"
        exit 1
    fi

    local url="${1//+/ }"
    echo "${url//%/\\x}"
    return 0
}

getAuthToken() {
	local githubAuthDeviceFlowUri="https://github.com/login/device/code?client_id=9603bcd797e8961affd5&scope=repo"
	local response=$(curl -s -f -X POST "$githubAuthDeviceFlowUri")
	local listResponse=$(echo $response | tr "&" "\n")

	local verificationUri=$(urlDecode $(getResponseObject "$listResponse" "verification_uri"))
	local userCode=$(getResponseObject "$listResponse" "user_code")
	local deviceCode=$(getResponseObject "$listResponse" "device_code")
	local expiryLength=$(getResponseObject "$listResponse" "expires_in")

	local expiryTime=$((SECONDS+$expiryLength))
	local pollInterval=$(getResponseObject "$listResponse" "interval")
	local githubOauthPollAuthorizationUri="https://github.com/login/oauth/access_token?client_id=9603bcd797e8961affd5&device_code=$deviceCode&grant_type=urn:ietf:params:oauth:grant-type:device_code"

	>&2 echo "Please navigate to this URL $verificationUri and enter the following code: $userCode"

	local authorized=0
	local accessToken

	while [[ $SECONDS -lt $expiryTime && $authorized == '0' ]]
	do
		local authResponse=$(curl -s -f -X POST "$githubOauthPollAuthorizationUri")
		local authResponseList=$(echo $authResponse | tr "&" "\n")

		if [[ $(getResponseObject "$authResponseList" "access_token") != 'ITEM NOT FOUND' ]]
		then
			accessToken=$(getResponseObject "$authResponseList" "access_token")
			authorized=1
		fi

		sleep $pollInterval
	done

	if [ $authorized == '1' ]
	then
		>&2 echo "Access Token Received: $accessToken"
		echo "$accessToken"
		return 0
	else
		>&2 echo "Authorization has failed before expiry, please try again."
		return 1
	fi
}

substituteEnvironmentConfig() {
	sed -i '' '/^# Add environment config here >>>>>>$/,/^# <<<<<< add environment config here$/{/^# Add environment config here >>>>>>$/!{/^# <<<<<< add environment config here$/!d;};}' "./ProPresenter Library Wrapper.app/Contents/Resources/envConfig.properties"
	sed -i '' -e "/^# Add environment config here >>>>>>$/r envConfig.properties" -e '/^# Add environment config here >>>>>>$/a\' "./ProPresenter Library Wrapper.app/Contents/Resources/envConfig.properties"
	return 0
}

copyToApplicationDirectory() {
	rm -rf "/Applications/ProPresenter Library Wrapper.app"
	cp -r "./ProPresenter Library Wrapper.app" "/Applications/ProPresenter Library Wrapper.app"
	chown -R $(logname) "/Applications/ProPresenter Library Wrapper.app"
	return 0
}

cloneLibrary() {
	if [ $# -ne 2 ]
    then
        >&2 echo "Missing args in ${FUNCNAME[0]}"
        exit 1
    fi

	if [ -d "$1" ]
	then
		if [ -d "$1/.git" ]
		then
			rm -rf "$1/.git"
		fi
		git -C "$1" init
		git -C "$1" remote add origin "https://github.com/$2.git"
		git -C "$1" fetch
		git -C "$1" checkout -t origin/master -f

		chown -R $(logname) "$1"
		chmod -R 755 "$1"
	else
		echo "Could not find library directory"
	fi
	return 0
}

checkRootPrivileges

properties="./envConfig.properties"

if [ -f "$properties" ]
then
	while IFS="=" read -r key value
	do
    	if [ "$key" == 'PPLibraryAuthToken' ]
    	then
    		value="$(getAuthToken)"
    	elif [ "$key" == 'PPLibraryPath' ]
    	then
    		libraryPath="$value"
    	elif [ "$key" == 'PPRepoLocation' ]
    	then
    		repoPath="$value"
    	fi

    	printf '%s\n' "$key=$value"
	done < "$properties" > "$properties.tmp" && mv "$properties.tmp" "$properties"

	substituteEnvironmentConfig
	copyToApplicationDirectory
else
	echo "Properties file not found, exiting"
	exit 1
fi

cloneLibrary "$libraryPath" "$repoPath"


