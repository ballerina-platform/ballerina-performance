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
# Setup Ballerina
# ----------------------------------------------------------------------------

# Make sure the script is running as root.
if [ "$UID" -ne "0" ]; then
    echo "You must be root to run $0. Try following"
    echo "sudo $0"
    exit 9
fi

script_dir=$(dirname "$0")
export script_name="$0"
export ballerina_version=""
export netty_host=""

function usageCommand() {
    echo "-d <ballerina_version> -n <netty_host>"
}
export -f usageCommand

function usageHelp() {
    echo "-d: The version of Ballerina debian package."
    echo "-n: The hostname of Netty Service."
}
export -f usageHelp

while getopts "u:b:c:gp:hd:n:" opt; do
    case "${opt}" in
    d)
        ballerina_version=${OPTARG}
        ;;
    n)
        netty_host=${OPTARG}
        ;;
    *)
        opts+=("-${opt}")
        [[ -n "$OPTARG" ]] && opts+=("$OPTARG")
        ;;
    esac
done
shift "$((OPTIND - 1))"

function validate() {
    if [[ -z $ballerina_version ]]; then
        echo "Please provide the version of Ballerina debian package."
        exit 1
    fi

    if [[ -z $netty_host ]]; then
        echo "Please provide the hostname of Netty Service."
        exit 1
    fi
}
export -f validate

function setup() {
    wget https://product-dist.ballerina.io/downloads/${ballerina_version}/ballerina-platform-linux-installer-x64-${ballerina_version}.deb
    dpkg -i ballerina-platform-linux-installer-x64-${ballerina_version}.deb
    echo "$netty_host netty" >>/etc/hosts
}
export -f setup

$script_dir/setup-common.sh "${opts[@]}" "$@"
