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
# Run Ballerina Performance Tests
# ----------------------------------------------------------------------------

script_dir=$(dirname "$0")
# Execute common script
. $script_dir/perf-test-common.sh

ballerina_ssh_host=ballerina
ballerina_host=$(get_ssh_hostname $ballerina_ssh_host)

declare -A test_scenario0=(
    [name]="passthrough_http"
    [bal]="passthrough.balx"
    [bal_flags]=""
    [path]="/passthrough"
    [jmx]="http-post-request.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario1=(
    [name]="passthrough_https"
    [bal]="https_passthrough.balx"
    [bal_flags]=""
    [path]="/passthrough"
    [jmx]="http-post-request.jmx"
    [protocol]="https"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario2=(
    [name]="transformation_http"
    [bal]="transformation.balx"
    [bal_flags]=""
    [path]="/transform"
    [jmx]="http-post-request.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario3=(
    [name]="transformation_https"
    [bal]="https_transformation.balx"
    [bal_flags]=""
    [path]="/transform"
    [jmx]="http-post-request.jmx"
    [protocol]="https"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario4=(
    [name]="passthrough_http2_https"
    [bal]="http2_https_passthrough.balx"
    [bal_flags]=""
    [path]="/passthrough"
    [jmx]="http2-post-request.jmx"
    [protocol]="https"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario5=(
    [name]="websocket"
    [bal]="websocket.balx"
    [bal_flags]=""
    [path]="/basic/ws"
    [jmx]="websocket.jmx"
    [protocol]=""
    [use_backend]=false
    [skip]=false
)
declare -A test_scenario10=(
    [name]="passthrough_http_observe_default"
    [bal]="passthrough.balx"
    [bal_flags]="--observe"
    [path]="/passthrough"
    [jmx]="http-post-request.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=true
)
declare -A test_scenario11=(
    [name]="passthrough_http_observe_metrics"
    [bal]="passthrough.balx"
    [bal_flags]="-e b7a.observability.metrics.enabled=true"
    [path]="/passthrough"
    [jmx]="http-post-request.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=true
)
declare -A test_scenario12=(
    [name]="passthrough_http_observe_tracing"
    [bal]="passthrough.balx"
    [bal_flags]="-e b7a.observability.tracing.enabled=true"
    [path]="/passthrough"
    [jmx]="http-post-request.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=true
)
declare -A test_scenario13=(
    [name]="passthrough_http_observe_metrics_noop"
    [bal]="passthrough.balx"
    [bal_flags]="-e b7a.observability.metrics.enabled=true -e b7a.observability.metrics.provider=noop"
    [path]="/passthrough"
    [jmx]="http-post-request.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=true
)
# declare -A test_scenario14=(
#     [name]="passthrough_http_observe_tracing_noop"
#     [bal]="passthrough.balx"
#     [bal_flags]="-e b7a.observability.tracing.enabled=true -e b7a.observability.tracing.name=noop"
#     [path]="/passthrough"
#     [jmx]="http-post-request.jmx"
#     [protocol]="http"
#     [use_backend]=true
#     [skip]=true
# )

function before_execute_test_scenario() {
    local bal_file=${scenario[bal]}
    local bal_flags=${scenario[bal_flags]}
    local service_path=${scenario[path]}
    local protocol=${scenario[protocol]}
    jmeter_params+=("host=$ballerina_host" "port=9090" "path=$service_path")
    jmeter_params+=("payload=$HOME/${msize}B.json" "response_size=${msize}B" "protocol=$protocol")
    JMETER_JVM_ARGS="-Xbootclasspath/p:$HOME/alpnboot.jar"
    echo "Starting Ballerina Service. Ballerina Program: $bal_file, Heap: $heap, Flags: ${bal_flags:-N/A}"
    ssh $ballerina_ssh_host "./ballerina/ballerina-start.sh -b $bal_file -m $heap -- $bal_flags"
}

function after_execute_test_scenario() {
    write_server_metrics ballerina $ballerina_ssh_host ballerina.*/bre
    scp -q $ballerina_ssh_host:ballerina/bal/logs/ballerina.log ${report_location}/ballerina.log
    scp -q $ballerina_ssh_host:ballerina/bal/logs/gc.log ${report_location}/ballerina_gc.log
}

test_scenarios
