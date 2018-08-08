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
# Setup JMeter
# ----------------------------------------------------------------------------

# Make sure the script is running as root.
if [ "$UID" -ne "0" ]; then
    echo "You must be root to run $0. Try following"
    echo "sudo $0"
    exit 9
fi

export script_name="$0"
export key_file_url=""
script_dir=$(dirname "$0")

function usageCommand() {
    echo "-k <key_file_url>"
}
export -f usageCommand

function usageHelp() {
    echo "-k: The URL to download the private key."
}
export -f usageHelp

while getopts "u:b:c:hk:" opt; do
    case "${opt}" in
    k)
        key_file_url=${OPTARG}
        ;;
    *)
        opts+=("-${opt}")
        [[ -n "$OPTARG" ]] && opts+=("$OPTARG")
        ;;
    esac
done
shift "$((OPTIND - 1))"

function validate() {
    if [[ -z $key_file_url ]]; then
        echo "Please provide the URL to download the private key."
        exit 1
    fi
}
export -f validate

function setup() {
    echo "Setting up JMeter in $PWD"
    wget ${key_file_url} -O private_key.pem
    pushd jmeter
    # Download and setup JMeter
    wget http://www-us.apache.org/dist//jmeter/binaries/apache-jmeter-4.0.tgz -O apache-jmeter-4.0.tgz
    ./install-jmeter.sh -f apache-jmeter-4.0.tgz -i $PWD -p bzm-http2 -p websocket-samplers

    # Download alpnboot.jar
    wget http://search.maven.org/remotecontent?filepath=org/mortbay/jetty/alpn/alpn-boot/8.1.12.v20180117/alpn-boot-8.1.12.v20180117.jar -O alpnboot.jar

    popd
}
export -f setup

$script_dir/setup-common.sh "${opts[@]}" "$@"
