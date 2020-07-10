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
    echo "Downloading keystore file to $HOME."
    scp $ballerina_ssh_host:/usr/lib/ballerina/distributions/jballerina-*/bre/security/ballerinaKeystore.p12 $HOME/
    scp $HOME/ballerinaKeystore.p12 $backend_ssh_host:
}
export -f initialize

declare -A test_scenario0=(
    [name]="h1c_h1c_passthrough"
    [display_name]="Passthrough HTTP service (h1c -> h1c)"
    [description]="An HTTP Service, which forwards all requests to an HTTP back-end service."
    [bal]="h1c_h1c_passthrough.jar"
    [bal_flags]=""
    [path]="/passthrough"
    [jmx]="http-post-request.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario1=(
    [name]="h1_h1_passthrough"
    [display_name]="Passthrough HTTPS service (h1 -> h1)"
    [description]="An HTTPS Service, which forwards all requests to an HTTPS back-end service."
    [bal]="h1_h1_passthrough.jar"
    [bal_flags]=""
    [path]="/passthrough"
    [jmx]="http-post-request.jmx"
    [protocol]="https"
    [use_backend]=true
    [backend_flags]="--ssl --key-store-file $HOME/ballerinaKeystore.p12 --key-store-password ballerina"
    [skip]=false
)
declare -A test_scenario2=(
    [name]="h1c_transformation"
    [display_name]="JSON to XML transformation HTTP service"
    [description]="An HTTP Service, which transforms JSON requests to XML and then forwards all requests to an HTTP back-end service."
    [bal]="h1c_transformation.jar"
    [bal_flags]=""
    [path]="/transform"
    [jmx]="http-post-request.jmx"
    [protocol]="http"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario3=(
    [name]="h1_transformation"
    [display_name]="JSON to XML transformation HTTPS service"
    [description]="An HTTPS Service, which transforms JSON requests to XML and then forwards all requests to an HTTPS back-end service."
    [bal]="h1_transformation.jar"
    [bal_flags]=""
    [path]="/transform"
    [jmx]="http-post-request.jmx"
    [protocol]="https"
    [use_backend]=true
    [backend_flags]="--ssl --key-store-file $HOME/ballerinaKeystore.p12 --key-store-password ballerina"
    [skip]=false
)
declare -A test_scenario4=(
    [name]="h2_h2_passthrough"
    [display_name]="Passthrough HTTP/2(over TLS) service (h2 -> h2)"
    [description]="An HTTPS Service exposed over HTTP/2 protocol, which forwards all requests to an HTTP/2(over TLS) back-end service."
    [bal]="h2_h2_passthrough.jar"
    [bal_flags]=""
    [path]="/passthrough"
    [jmx]="http2-post-request.jmx"
    [protocol]="https"
    [use_backend]=true
    [backend_flags]="--http2 --ssl --key-store-file $HOME/ballerinaKeystore.p12 --key-store-password ballerina"
    [skip]=false
)
declare -A test_scenario5=(
    [name]="h2_h1_passthrough"
    [display_name]="Passthrough HTTP/2(over TLS) service (h2 -> h1)"
    [description]="An HTTPS Service exposed over HTTP/2 protocol, which forwards all requests to an HTTPS back-end service."
    [bal]="h2_h1_passthrough.jar"
    [bal_flags]=""
    [path]="/passthrough"
    [jmx]="http2-post-request.jmx"
    [protocol]="https"
    [use_backend]=true
    [backend_flags]="--ssl --key-store-file $HOME/ballerinaKeystore.p12 --key-store-password ballerina"
    [skip]=false
)
declare -A test_scenario6=(
    [name]="h2_h1c_passthrough"
    [display_name]="Passthrough HTTP/2(over TLS) service (h2 -> h1c)"
    [bal]="h2_h1c_passthrough.jar"
    [description]="An HTTPS Service exposed over HTTP/2 protocol, which forwards all requests to an HTTP back-end service."
    [bal_flags]=""
    [path]="/passthrough"
    [jmx]="http2-post-request.jmx"
    [protocol]="https"
    [use_backend]=true
    [skip]=false
)
declare -A test_scenario7=(
    [name]="h2_h2_client_and_server_downgrade"
    [display_name]="HTTP/2 client and server downgrade service (h2 -> h2)"
    [description]="An HTTP/2(with TLS) server accepts requests from an HTTP/1.1(with TLS) client and the HTTP/2(with TLS) client sends requests to an HTTP/1.1(with TLS) back-end service. Both the upstream and the downgrade connection is downgraded to HTTP/1.1(with TLS)."
    [bal]="h2_h2_passthrough.jar"
    [bal_flags]=""
    [path]="/passthrough"
    [jmx]="http-post-request.jmx"
    [protocol]="https"
    [use_backend]=true
    [backend_flags]="--ssl --key-store-file $HOME/ballerinaKeystore.p12 --key-store-password ballerina"
    [skip]=false
)

function before_execute_test_scenario() {
    local bal_file=${scenario[bal]}
    local bal_flags=${scenario[bal_flags]}
    local service_path=${scenario[path]}
    local protocol=${scenario[protocol]}
    jmeter_params+=("host=$ballerina_host" "port=9090" "path=$service_path")
    jmeter_params+=("payload=$HOME/${msize}B.json" "response_size=${msize}B" "protocol=$protocol")
    JMETER_JVM_ARGS="-Xbootclasspath/p:/opt/alpnboot/alpnboot.jar"
    echo "Starting Ballerina Service. Ballerina Program: $bal_file, Heap: $heap, Flags: ${bal_flags:-N/A}"
    ssh $ballerina_ssh_host "sudo ./ballerina/ballerina-start.sh -p $HOME/ballerina/bal -b $bal_file -m $heap -- $bal_flags"
}

function after_execute_test_scenario() {
    write_server_metrics ballerina $ballerina_ssh_host ballerina.*/bre
    download_file $ballerina_ssh_host ballerina/bal/logs/ballerina.log ballerina.log
    download_file $ballerina_ssh_host ballerina/bal/logs/gc.log ballerina_gc.log
    download_file $ballerina_ssh_host ballerina/bal/logs/heap-dump.hprof ballerina_heap_dump.hprof
}

test_scenarios
