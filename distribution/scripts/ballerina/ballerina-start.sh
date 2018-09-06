#!/bin/bash
# Copyright 2018 WSO2 Inc. (http://wso2.org)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ----------------------------------------------------------------------------
# Start Ballerina Service
# ----------------------------------------------------------------------------

bal_file=""
heap_size=""

function usage() {
    echo ""
    echo "Usage: "
    echo "$0 -b <bal_file> [-m <heap_size>] [-h] -- [ballerina_flags]"
    echo ""
    echo "-b: The Ballerina program."
    echo "-m: The heap memory size of Ballerina VM."
    echo "-h: Display this help and exit."
    echo ""
}

while getopts "b:m:h" opts; do
    case $opts in
    b)
        bal_file=${OPTARG}
        ;;
    m)
        heap_size=${OPTARG}
        ;;
    h)
        usage
        exit 0
        ;;
    \?)
        usage
        exit 1
        ;;
    esac
done
shift "$((OPTIND - 1))"

bal_flags="$@"

if [[ -z $bal_file ]]; then
    echo "Please provide the Ballerina program."
    exit 1
fi

if [[ -z $heap_size ]]; then
    heap_size="1G"
fi

ballerina_path=$HOME/ballerina/bal

if pgrep -f ballerina.*/bre >/dev/null; then
    echo "Shutting down Ballerina"
    pkill -f ballerina.*/bre
fi

if [ ! -d "${ballerina_path}/logs" ]; then
    mkdir ${ballerina_path}/logs
fi

log_files=(${ballerina_path}/logs/*)
if [ ${#log_files[@]} -gt 1 ]; then
    echo "Log files exists. Moving to /tmp/${bal_file}/"
    mkdir -p /tmp/${bal_file}
    mv ${ballerina_path}/logs/* /tmp/${bal_file}/
fi

echo "Setting Heap to ${heap_size}"

echo "Enabling GC Logs"
export JAVA_OPTS="-XX:+PrintGC -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:${ballerina_path}/logs/gc.log -Xms${heap_size} -Xmx${heap_size}"

ballerina_command="ballerina run ${bal_file} $bal_flags"
echo "Starting Ballerina: $ballerina_command"
cd $ballerina_path
nohup $ballerina_command &>${ballerina_path}/logs/ballerina.log &

# TODO Do a curl and check if service is started
echo "Waiting for 5 seconds to make sure that the server is ready to accept requests."
sleep 5
tail -10 ${ballerina_path}/logs/ballerina.log
