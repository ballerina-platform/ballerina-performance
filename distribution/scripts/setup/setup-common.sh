#!/bin/bash -e
# Copyright (c) 2018, WSO2 Inc. (http://wso2.org) All Rights Reserved.
#
# WSO2 Inc. licenses this file to you under the Apache License,
# Version 2.0 (the "License"); you may not use this file except
# in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
# ----------------------------------------------------------------------------
# Setup script
# ----------------------------------------------------------------------------

# Make sure the script is running as root.
if [ "$UID" -ne "0" ]; then
    echo "You must be root to run $0. Try following"
    echo "sudo $0"
    exit 9
fi

target_user="ubuntu"
performance_ballerina_dist_url=""
performance_common_dist_url=""
dist_upgrade=false
declare -a packages

function usage() {
    echo ""
    echo "Usage: "
    echo -n "${script_name:-$0} -u <target_user> -b <performance_ballerina_dist_url> -c <performance_common_dist_url>"
    echo -n "  [-g] [-p <package>]"
    if declare -F usageCommand >/dev/null 2>&1; then
        echo " $(usageCommand)"
    else
        echo ""
    fi
    echo ""
    echo "-u: Target Username. Default 'ubuntu'."
    echo "-b: The URL to download 'Performance Ballerina Distribution'."
    echo "-c: The URL to download 'Performance Common Distribution'."
    echo "-g: Upgrade distribution"
    echo "-p: Package to install. You can give multiple -p options."
    if declare -F usageHelp >/dev/null 2>&1; then
        echo "$(usageHelp)"
    fi
    echo "-h: Display this help and exit."
    echo ""
}

while getopts "u:b:c:gp:h" opts; do
    case $opts in
    u)
        target_user=${OPTARG}
        ;;
    b)
        performance_ballerina_dist_url=${OPTARG}
        ;;
    c)
        performance_common_dist_url=${OPTARG}
        ;;
    g)
        dist_upgrade=true
        ;;
    p)
        packages+=("${OPTARG}")
        ;;
    h)
        usage
        exit 0
        ;;
    *)
        usage
        exit 1
        ;;
    esac
done

if [[ -z $target_user ]]; then
    echo "Please provide the username."
    exit 1
fi

if ! id -u $target_user >/dev/null 2>&1; then
    echo "The $target_user user does not exist."
    exit 1
fi

if [[ -z $performance_ballerina_dist_url ]]; then
    echo "Please provide the URL to download 'Performance Ballerina Distribution'."
    exit 1
fi

if [[ -z $performance_common_dist_url ]]; then
    echo "Please provide the URL to download 'Performance Common Distribution'."
    exit 1
fi

if declare -F validate >/dev/null 2>&1; then
    validate
fi

# Update packages
apt update

# Upgrade distribution
if [ "$dist_upgrade" = true ] ; then
    echo "Upgrading the distribution"
    apt -y dist-upgrade;apt -y autoremove;apt -y autoclean
fi

for p in ${packages[*]}; do
    echo "Installing $p package"
    apt install -y $p
done

cd /home/$target_user
performance_ballerina_dist_name="performance-ballerina-distribution.tar.gz"
performance_common_dist_name="performance-common-distribution.tar.gz"

if [[ ! -f $performance_ballerina_dist_name ]]; then
    wget ${performance_ballerina_dist_url} -O $performance_ballerina_dist_name
fi

if [[ ! -f $performance_common_dist_name ]]; then
    wget ${performance_common_dist_url} -O $performance_common_dist_name
fi

# Extract distributions
tar -xvf $performance_ballerina_dist_name
tar -xvf $performance_common_dist_name

./sar/install-sar.sh

FUNC=$(declare -f setup)
if [[ ! -z $FUNC ]]; then
    bash -c "$FUNC; setup"
fi

chown -R $target_user:$target_user /home/$target_user
