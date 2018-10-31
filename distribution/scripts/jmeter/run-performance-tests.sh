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

function initialize() {
    export ballerina_ssh_host=ballerina
    export ballerina_host=$(get_ssh_hostname $ballerina_ssh_host)
}
export -f initialize

declare -A test_scenario0=(
    [name]="passthrough_http"
    [display_name]="Passthrough HTTP service"
    [description]="An HTTP Service, which forwards all requests to a back-end service."
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
    [display_name]="Passthrough HTTPS service"
    [description]="An HTTPS Service, which forwards all requests to a back-end service."
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
    [display_name]="JSON to XML transformation HTTP service"
    [description]="An HTTP Service, which transforms JSON requests to XML and then forwards all requests to a back-end service."
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
    [display_name]="JSON to XML transformation HTTPS service"
    [description]="An HTTPS Service, which transforms JSON requests to XML and then forwards all requests to a back-end service."
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
    [display_name]="Passthrough HTTP2 (HTTPS) service"
    [bal]="http2_https_passthrough.balx"
    [description]="An HTTPS Service exposed over HTTP2 protocol, which forwards all requests to a back-end service."
    [bal_flags]=""
    [path]="/passthrough"
    [jmx]="http2-post-request.jmx"
    [protocol]="https"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario5=(
    [name]="websocket"
    [display_name]="Websocket"
    [description]="Websocket service"
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
    [display_name]="Passthrough HTTP Service with Default Observability"
    [description]="Observability with default configs"
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
    [display_name]="Passthrough HTTP Service with Metrics"
    [description]="Metrics only"
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
    [display_name]="Passthrough HTTP Service with Tracing"
    [description]="Tracing only"
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
    [display_name]="Passthrough HTTP Service with Metrics (No-Op)"
    [description]="Metrics (with No-Op implementation) only"
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
#     [display_name]="Passthrough HTTP Service with Tracing (No-Op)"
#     [description]="Tracing (with No-Op implementation) only"
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
    JMETER_JVM_ARGS="-Xbootclasspath/p:/opt/alpnboot/alpnboot.jar"
    echo "Starting Ballerina Service. Ballerina Program: $bal_file, Heap: $heap, Flags: ${bal_flags:-N/A}"
    ssh $ballerina_ssh_host "./ballerina/ballerina-start.sh -p $HOME/ballerina/bal -b $bal_file -m $heap -- $bal_flags"
}

function after_execute_test_scenario() {
    write_server_metrics ballerina $ballerina_ssh_host ballerina.*/bre
    download_file $ballerina_ssh_host ballerina/bal/logs/ballerina.log ballerina.log
    download_file $ballerina_ssh_host ballerina/bal/logs/gc.log ballerina_gc.log
    download_file $ballerina_ssh_host ballerina/bal/logs/heap-dump.hprof ballerina_heap_dump.hprof
}

test_scenarios
