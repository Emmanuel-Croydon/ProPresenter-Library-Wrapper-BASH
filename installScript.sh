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

checkRootPrivileges


# TODO: clone repo
# TODO: api token
