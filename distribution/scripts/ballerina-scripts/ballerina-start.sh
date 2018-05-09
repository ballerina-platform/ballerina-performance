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

# Required parameters -> heap size, ballerina file, flags

heap_size=$1
if [[ -z $heap_size ]]; then
    echo "Running with default heap 1 GB."
    heap_size="1G"
fi

bal_file=$2
if [[ -z $bal_file ]]; then
    echo "No bal file specified."
    exit 1
fi

flags="${@:3:99}"

ballerina_path=$HOME/ballerina

jvm_dir=""
for dir in /usr/lib/jvm/jdk1.8*; do
    [ -d "${dir}" ] && jvm_dir="${dir}" && break
done
export JAVA_HOME="${jvm_dir}"

if pgrep -f ballerina/bre > /dev/null; then
    echo "Shutting down Ballerina"
    pkill -f ballerina/bre
fi

log_files=(${ballerina_path}/logs/*)
if [ ${#log_files[@]} -gt 1 ]; then
    echo "Log files exists. Moving to /tmp/${bal_file}/"
    mkdir -p /tmp/${bal_file}
    mv ${ballerina_path}/logs/* /tmp/${bal_file}/;
fi

echo "Setting Heap to ${heap_size}"

echo "Enabling GC Logs"
export JAVA_OPTS="-XX:+PrintGC -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:${ballerina_path}/logs/gc.log -Xms${heap_size} -Xmx${heap_size}"

echo "Building bal file"
cd ${ballerina_path}/bin
./ballerina build ${bal_file}
cd $HOME

echo "Starting Ballerina with Flags: " $flags
nohup ${ballerina_path}/bin/ballerina run ${ballerina_path}/bin/${bal_file}x $flags &> ${ballerina_path}/logs/ballerina.log&

# TODO Do a curl and check if service is started
echo "Wait for 10 seconds to make sure that the server is ready to accept API requests."
sleep 10
