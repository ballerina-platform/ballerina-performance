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

# Make sure the script is running as root.
if [ "$UID" -ne "0" ]; then
    echo "You must be root to run $0. Try following"
    echo "sudo $0"
    exit 9
fi

ballerina_path=""
ballerina_file=""
default_heap_size="1g"
heap_size="$default_heap_size"

function usage() {
    echo ""
    echo "Usage: "
    echo "$0 -p <ballerina_path> -b <ballerina_file> [-m <heap_size>] [-h] -- [ballerina_flags]"
    echo ""
    echo "-p: The Ballerina program path."
    echo "-b: The Ballerina program."
    echo "-m: The heap memory size of Ballerina VM. Default: $default_heap_size."
    echo "-h: Display this help and exit."
    echo ""
}

while getopts "p:b:m:h" opts; do
    case $opts in
    p)
        ballerina_path=${OPTARG}
        ;;
    b)
        ballerina_file=${OPTARG}
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

if [[ ! -d $ballerina_path ]]; then
    echo "Please provide the Ballerina path."
    exit 1
fi

if [[ ! -f $ballerina_path/$ballerina_file ]]; then
    echo "Please provide the Ballerina program."
    exit 1
fi

if [[ -z $heap_size ]]; then
    echo "Please provide the heap size for the Ballerina program."
    exit 1
fi

if pgrep -f ballerina.*/bre >/dev/null; then
    echo "Shutting down Ballerina"
    pkill -f ballerina.*/bre
    # Wait for few seconds
    sleep 5
fi

# Check whether process exists
if pgrep -f ballerina.*/bre >/dev/null; then
    echo "Killing Ballerina process!!"
    pkill -9 -f ballerina.*/bre
fi

if [ ! -d "${ballerina_path}/logs" ]; then
    mkdir ${ballerina_path}/logs
fi

log_files=(${ballerina_path}/logs/*)
if [ ${#log_files[@]} -gt 1 ]; then
    echo "Log files exists. Moving to /tmp/"
    mv ${ballerina_path}/logs/* /tmp/
fi

echo "Setting Heap to ${heap_size}"

echo "Enabling GC Logs"
export JAVA_OPTS="-XX:+PrintGC -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:${ballerina_path}/logs/gc.log"
JAVA_OPTS+=" -Xms${heap_size} -Xmx${heap_size}"
JAVA_OPTS+=" -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath="${ballerina_path}/logs/heap-dump.hprof""

ballerina_command="sudo ballerina run ${bal_flags} ${ballerina_file}"
echo "Starting Ballerina: $ballerina_command"
cd $ballerina_path
nohup $ballerina_command &>${ballerina_path}/logs/ballerina.log &

# TODO Do a curl and check if service is started
echo "Waiting to make sure that the server is ready to accept requests."
n=0
until [ $n -ge 60 ]; do
    nc -zv localhost 9090 && break
    n=$(($n + 1))
    sleep 1
done

# Wait few more seconds to get logs
sleep 5
tail -10 ${ballerina_path}/logs/ballerina.log
