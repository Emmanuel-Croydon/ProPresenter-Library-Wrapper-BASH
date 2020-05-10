# ==================================================================================================
# DEPLOYMENT SCRIPT
# ==================================================================================================
#

#!/bin/bash

set -e

addEnvironmentVariable() {
    if [ $# -ne 2 ]
    then
        >&2 echo "Incorrect args in ${FUNCNAME[0]}"
        exit 1
    fi

    local variableName=$1
    local variableValue=$2

    if [ ! -f ~/.bashrc ]
    then
    	touch ~/.bashrc
    fi

    sed -i "" "/$variableName/d" ~/.bashrc
    echo "export $variableName=$variableValue" >> ~/.bashrc

    if [ $? -eq 0 ]
    then
        echo "Successfully added $variableName : $variableValue"
        return 0
	else
	    return 1
	fi
}

checkRootPrivileges() {
	if [ $EUID -ne 0 ]
	then
		echo "$0 is not running as root. Please use sudo"
		exit 2
	fi
}

checkRootPrivileges

propertiesFile="./envConfig.properties"

while IFS="=" read -r key value
do
	addEnvironmentVariable "$key" "$value"
done < "$propertiesFile"

# TODO: clone repo
# TODO: api token
