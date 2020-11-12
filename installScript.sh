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

getAuthToken() {
	local githubAuthUri="https://api.github.com/authorizations"
	local user="$(hostname)/$(whoami)"
	local authBody='{"scopes": ["repo"], "note": "'"$user ProPresenter-Library-Wrapper"'"}'

	echo "Username: " 1>&2
	read username </dev/tty

	local response=$(curl -f -X POST -H "Content-Type: application/json" -H "Accept: application/vnd.github.v3.json" -u "$username" -d "$authBody" "$githubAuthUri")
	local tokenRegex='"token": [\"]([^"]*)[\"]'

	local token=$([[ "$response" =~ $tokenRegex ]] && echo ${BASH_REMATCH[1]})
	echo "$token"

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
    		value=$(getAuthToken)
    	elif [ "$key" == 'PPLibraryPath' ]
    	then
    		libraryPath="$value"
    	elif [ "$key" == 'PPRepoLocation' ]
    	then
    		repoPath="$value"
    	fi

    	printf '%s\n' "$key=$value"
	done < "$properties" > "$properties.tmp" && mv "$properties.tmp" "$properties"

	sed -n '1,5p' "$properties" >> "./ProPresenter Library Wrapper.app/Contents/Resources/envConfig.properties"
	rm -rf "/Applications/ProPresenter Library Wrapper.app"
	cp -r "./ProPresenter Library Wrapper.app" "/Applications/ProPresenter Library Wrapper.app"
else
	echo "Properties file not found, exiting"
	exit 1
fi

if [ -d "$libraryPath" ]
then
	git -C "$libraryPath" init
	git -C "$libraryPath" remote add origin "https://github.com/$repoPath.git"
	git -C "$libraryPath" fetch
	git -C "$libraryPath" checkout -t origin/master -f
else
	echo "Could not find library directory"
fi
