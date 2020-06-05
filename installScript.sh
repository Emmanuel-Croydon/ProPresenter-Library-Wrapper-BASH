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
	read username

	local response=$(curl -f -X POST -H "Content-Type: application/json" -H "Accept: application/vnd.github.v3.json" -u "$username" -d "$authBody" "$githubAuthUri")
	local tokenRegex='"token": [\"]([^"]*)[\"]'

	local token=$([[ "$response" =~ $tokenRegex ]] && echo ${BASH_REMATCH[1]})
	echo "$token"

	return 0
}

checkRootPrivileges
token=$(getAuthToken)
echo "$token"


# TODO: clone repo
# TODO: api token
