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

function usage() {
    echo ""
    echo "Usage: "
    echo -n "$0 -u <target_user> -b <performance_ballerina_dist_url> -c <performance_common_dist_url>"
    if declare -F usageCommand >/dev/null 2>&1; then
        echo "$(usageCommand)"
    else
        echo ""
    fi
    echo ""
    echo "-u: Target Username. Default 'ubuntu'."
    echo "-b: The URL to download 'Performance Ballerina Distribution'."
    echo "-c: The URL to download 'Performance Common Distribution'."
    if declare -F usageHelp >/dev/null 2>&1; then
        echo "$(usageHelp)"
    fi
    echo ""
}

while getopts "u:b:c:k:" opts; do
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
    echo "The user does not exist."
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

# Update packages
apt update
# Install OpenJDK
apt install -y openjdk-8-jdk

cd /home/$target_user
wget ${performance_ballerina_dist_url} -O performance-ballerina-distribution.tar.gz
wget ${perf_common_dist_url} -O performance-common-distribution.tar.gz

# Extract distributions
tar -xvf performance-ballerina-distribution.tar.gz
tar -xvf performance-common-distribution.tar.gz

./sar/install-sar.sh

FUNC=$(declare -f setup)
if [[ ! -z $FUNC ]]; then
    sudo bash -c "$FUNC; setup"
fi

chown -R $target_user:$target_user /home/$target_user
