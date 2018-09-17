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

export script_name="$0"
export script_dir=$(dirname "$0")
export download_url=""
export netty_host=""

function usageCommand() {
    echo "-u <download_url> -n <netty_host>"
}
export -f usageCommand

function usageHelp() {
    echo "-u: The download url of ballerina installer."
    echo "-n: The hostname of Netty Service."
}
export -f usageHelp

while getopts "gp:w:o:hu:n:" opt; do
    case "${opt}" in
    u)
        download_url=${OPTARG}
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
    if [[ -z $download_url ]]; then
        echo "Please provide the download url for the Ballerina Installer."
        exit 1
    fi

    if [[ -z $netty_host ]]; then
        echo "Please provide the hostname of Netty Service."
        exit 1
    fi
}
export -f validate

function setup() {
    if [[ ! -f ballerina_installer.deb ]]; then
        echo "Downloading Ballerina distribution"
        wget -q $download_url -O ballerina_installer.deb
    fi
    dpkg -i ballerina_installer.deb
    echo "$netty_host netty" >>/etc/hosts

    # Build Ballerina Files
    pushd $script_dir/../ballerina/bal
    for bal_file in *.bal; do
        echo "Building $bal_file file"
        ballerina build ${bal_file}
    done
    popd
}
export -f setup

$script_dir/setup-common.sh "${opts[@]}" "$@"
