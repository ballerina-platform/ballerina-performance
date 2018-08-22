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
jmeter_dir=""
for dir in $HOME/apache-jmeter*; do
    [ -d "${dir}" ] && jmeter_dir="${dir}" && break
done
export JMETER_HOME="${jmeter_dir}"
export PATH=$JMETER_HOME/bin:$PATH

# Concurrent users (these will by multiplied by the number of JMeter servers)
concurrent_users=(50 100 150 500 1000)
# Message Sizes
message_size=(50 1024 10240)
# Common backend sleep times (in milliseconds).
# This is not an array on purpose in order to use in test scenarios array.
# Sleep time is scenario specific since some scenarios do not use a backend.
backend_sleep_times="0 30 500 1000"
# Ballerina VM heap Sizes
heap_sizes=(250m 1g)

# Test Duration in seconds
test_duration=900
# Warm-up time in minutes
warmup_time=5
# Heap size of JMeter Client
jmeter_client_heap_size=2g
# Heap size of JMeter Server
jmeter_server_heap_size=4g

ballerina_ssh_host=ballerina
backend_ssh_host=netty
jmeter1_ssh_host=jmeter1
jmeter2_ssh_host=jmeter2
payload_type=ARRAY
# Estimate flag
estimate=false

function get_ssh_hostname() {
    ssh -G $1 | awk '/^hostname / { print $2 }'
}

ballerina_host=$(get_ssh_hostname $ballerina_ssh_host)
jmeter1_host=$(get_ssh_hostname $jmeter1_ssh_host)
jmeter2_host=$(get_ssh_hostname $jmeter2_ssh_host)

function usage() {
    echo ""
    echo "Usage: "
    echo "$0 [-d <test_duration>] [-w <warmup_time>] [-j <jmeter_server_heap_size>] [-k <jmeter_client_heap_size>]"
    echo ""
    echo "-d: Test Duration in seconds. Default $test_duration."
    echo "-w: Warm-up time in minutes. Default $warmup_time."
    echo "-j: Heap Size of JMeter Server. Default $jmeter_server_heap_size."
    echo "-k: Heap Size of JMeter Client. Default $jmeter_client_heap_size."
    echo "-e: Estimate time without executing tests."
    echo "-h: Display this help and exit."
    echo ""
}

while getopts "d:w:j:k:eh" opts; do
    case $opts in
    d)
        test_duration=${OPTARG}
        ;;
    w)
        warmup_time=${OPTARG}
        ;;
    j)
        jmeter_server_heap_size=${OPTARG}
        ;;
    k)
        jmeter_client_heap_size=${OPTARG}
        ;;
    e)
        estimate=true
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

if [[ -z $test_duration ]]; then
    echo "Please provide the test duration."
    exit 1
fi
if [[ -z $warmup_time ]]; then
    echo "Please provide the warmup time."
    exit 1
fi

declare -A test_scenario0=(
    [name]="passthrough_http"
    [bal]="passthrough.balx"
    [bal_flags]=""
    [path]="/passthrough"
    [jmx]="http-post-request.jmx"
    [protocol]="http"
    [sleep]="${backend_sleep_times}"
    [skip]=false
)
declare -A test_scenario1=(
    [name]="passthrough_https"
    [bal]="https_passthrough.balx"
    [bal_flags]=""
    [path]="/passthrough"
    [jmx]="http-post-request.jmx"
    [protocol]="https"
    [sleep]="${backend_sleep_times}"
    [skip]=false
)
declare -A test_scenario2=(
    [name]="transformation_http"
    [bal]="transformation.balx"
    [bal_flags]=""
    [path]="/transform"
    [jmx]="http-post-request.jmx"
    [protocol]="http"
    [sleep]="${backend_sleep_times}"
    [skip]=false
)
declare -A test_scenario3=(
    [name]="transformation_https"
    [bal]="https_transformation.balx"
    [bal_flags]=""
    [path]="/transform"
    [jmx]="http-post-request.jmx"
    [protocol]="https"
    [sleep]="${backend_sleep_times}"
    [skip]=false
)
declare -A test_scenario4=(
    [name]="passthrough_http2_https"
    [bal]="http2_https_passthrough.balx"
    [bal_flags]=""
    [path]="/passthrough"
    [jmx]="http2-post-request.jmx"
    [protocol]="https"
    [sleep]="${backend_sleep_times}"
    [skip]=false
)
declare -A test_scenario5=(
    [name]="websocket"
    [bal]="websocket.balx"
    [bal_flags]=""
    [path]="/basic/ws"
    [jmx]="post-request-test.jmx"
    [protocol]=""
    [sleep]="-1"
    [skip]=false
)
declare -A test_scenario10=(
    [name]="passthrough_http_observability"
    [bal]="passthrough.balx"
    [bal_flags]="--observe"
    [path]="/passthrough"
    [jmx]="http-post-request.jmx"
    [protocol]="http"
    [sleep]="${backend_sleep_times}"
    [skip]=true
)
declare -A test_scenario11=(
    [name]="passthrough_http_metrics"
    [bal]="passthrough.balx"
    [bal_flags]="-e b7a.observability.metrics.enabled=true"
    [path]="/passthrough"
    [jmx]="http-post-request.jmx"
    [protocol]="http"
    [sleep]="${backend_sleep_times}"
    [skip]=true
)
declare -A test_scenario12=(
    [name]="passthrough_http_tracing"
    [bal]="passthrough.balx"
    [bal_flags]="-e b7a.observability.tracing.enabled=true"
    [path]="/passthrough"
    [jmx]="http-post-request.jmx"
    [protocol]="http"
    [sleep]="${backend_sleep_times}"
    [skip]=true
)
declare -A test_scenario13=(
    [name]="passthrough_http_metrics_noop"
    [bal]="passthrough.balx"
    [bal_flags]="-e b7a.observability.metrics.enabled=true -e b7a.observability.metrics.provider=noop"
    [path]="/passthrough"
    [jmx]="http-post-request.jmx"
    [protocol]="http"
    [sleep]="${backend_sleep_times}"
    [skip]=true
)
declare -A test_scenario14=(
    [name]="passthrough_http_tracing_noop"
    [bal]="passthrough.balx"
    [bal_flags]="-e b7a.observability.tracing.enabled=true -e b7a.observability.tracing.name=noop"
    [path]="/passthrough"
    [jmx]="http-post-request.jmx"
    [protocol]="http"
    [sleep]="${backend_sleep_times}"
    [skip]=true
)

if [ "$estimate" = false ]; then
    if [[ -d results ]]; then
        echo "Results directory already exists"
        exit 1
    fi
    mkdir results
    cp $0 results

    declare -a payload_sizes
    for msize in ${message_size[@]}; do
        payload_sizes+=("-s" "$msize")
    done

    echo "Generating Payloads in $jmeter1_ssh_host"
    ssh $jmeter1_ssh_host "./payloads/generate-payloads.sh" -p $payload_type ${payload_sizes[@]}
    echo "Generating Payloads in $jmeter2_ssh_host"
    ssh $jmeter2_ssh_host "./payloads/generate-payloads.sh" -p $payload_type ${payload_sizes[@]}
fi

function format_time() {
    # Duration in seconds
    duration="$1"
    minutes=$(echo "$duration/60" | bc)
    seconds=$(echo "$duration-$minutes*60" | bc)
    if [ $minutes -ge 60 ]; then
        hours=$(echo "$minutes/60" | bc)
        minutes=$(echo "$minutes-$hours*60" | bc)
        printf "%d hour(s), %02d minute(s) and %02d second(s)\n" $hours $minutes $seconds
    else
        printf "%d minute(s) and %02d second(s)\n" $minutes $seconds
    fi
}

function measure_time() {
    end_time=$(date +%s)
    start_time=$1
    duration=$(echo "$end_time - $start_time" | bc)
    echo "$duration"
}

function write_server_metrics() {
    server=$1
    ssh_host=$2
    pgrep_pattern=$3
    command_prefix=""
    if [[ ! -z $ssh_host ]]; then
        command_prefix="ssh $ssh_host"
    fi
    $command_prefix ss -s >${report_location}/${server}_ss.txt
    $command_prefix uptime >${report_location}/${server}_uptime.txt
    $command_prefix sar -q >${report_location}/${server}_loadavg.txt
    $command_prefix sar -A >${report_location}/${server}_sar.txt
    $command_prefix top -bn 1 >${report_location}/${server}_top.txt
    if [[ ! -z $pgrep_pattern ]]; then
        $command_prefix ps u -p \`pgrep -f $pgrep_pattern\` >${report_location}/${server}_ps.txt
    fi
}

test_start_time=$(date +%s)
total_counter=0
declare -A scenario_counter
declare -A scenario_duration

function record_scenario_duration() {
    scenario_name="$1"
    duration="$2"
    # Increment counter
    current_scenario_counter="${scenario_counter[$scenario_name]}"
    if [[ ! -z $current_scenario_counter ]]; then
        scenario_counter[$scenario_name]=$(echo "$current_scenario_counter+1" | bc)
    else
        # Initialize counter
        scenario_counter[$scenario_name]=1
    fi
    # Save duration
    current_scenario_duration="${scenario_duration[$scenario_name]}"
    if [[ ! -z $current_scenario_duration ]]; then
        scenario_duration[$scenario_name]=$(echo "$current_scenario_duration+$duration" | bc)
    else
        # Initialize counter
        scenario_duration[$scenario_name]="$duration"
    fi
}

for heap in ${heap_sizes[@]}; do
    declare -n scenario
    for scenario in ${!test_scenario@}; do
        skip=${scenario[skip]}
        if [ $skip = true ]; then
            continue;
        fi
        scenario_name=${scenario[name]}
        bal_file=${scenario[bal]}
        bal_flags=${scenario[bal_flags]}
        service_path=${scenario[path]}
        jmx_file=${scenario[jmx]}
        protocol=${scenario[protocol]}
        sleep=${scenario[sleep]}
        declare -a sleep_times=($sleep)
        for u in ${concurrent_users[@]}; do
            for msize in ${message_size[@]}; do
                for sleep_time in ${sleep_times[@]}; do
                    # Increment total counter
                    let total_counter=total_counter+1
                    if [ "$estimate" = true ]; then
                        record_scenario_duration $scenario_name $test_duration
                        continue
                    fi
                    start_time=$(date +%s)
                    #requests served by two jmeter servers
                    total_users=$(($u * 2))

                    scenario_desc="Scenario Name: ${scenario_name}, Duration: $test_duration"
                    scenario_desc+=", Concurrent Users ${total_users}, Msg Size: ${msize}, Sleep Time: ${sleep_time}"
                    echo -n "# Starting the performance test."
                    echo " $scenario_desc"

                    report_location=$PWD/results/${scenario_name}/${heap}_heap/${total_users}_users/${msize}B/${sleep_time}ms_sleep

                    echo "Report location is ${report_location}"
                    mkdir -p $report_location

                    echo "Starting Ballerina Service. Ballerina Program: $bal_file, Heap: $heap, Flags: ${bal_flags:-N/A}"
                    ssh $ballerina_ssh_host "./ballerina/ballerina-start.sh -b $bal_file -m $heap -- $bal_flags"
                    if [[ $sleep_time -ge 0 ]]; then
                        echo "Starting Backend Service. Sleep Time: $sleep_time"
                        ssh $backend_ssh_host "./netty-service/netty-start.sh -t $sleep_time"
                    fi

                    echo "Starting Remote JMeter servers"
                    echo "Starting Remote JMeter server. SSH Host: $jmeter1_ssh_host, IP: $jmeter1_host, Path: $HOME, Heap: $jmeter_server_heap_size"
                    ssh $jmeter1_ssh_host "./jmeter/jmeter-server-start.sh -n $jmeter1_host -i $HOME -m $jmeter_server_heap_size -- -Xbootclasspath/p:$HOME/alpnboot.jar"
                    echo "Starting Remote JMeter server. SSH Host: $jmeter2_ssh_host, IP: $jmeter2_host, Path: $HOME, Heap: $jmeter_server_heap_size"
                    ssh $jmeter2_ssh_host "./jmeter/jmeter-server-start.sh -n $jmeter2_host -i $HOME -m $jmeter_server_heap_size -- -Xbootclasspath/p:$HOME/alpnboot.jar"
                    export JVM_ARGS="-Xms$jmeter_client_heap_size -Xmx$jmeter_client_heap_size -XX:+PrintGC -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:$report_location/jmeter_gc.log"

                    jmeter_command="jmeter -n -t $script_dir/${jmx_file} -R $jmeter1_host,$jmeter2_host -X"
                    jmeter_command+=" -Gusers=$u -Gduration=$test_duration -Ghost=$ballerina_host -Gport=9090 -Gpath=$service_path"
                    jmeter_command+=" -Gpayload=$HOME/${msize}B.json -Gresponse_size=${msize}B"
                    jmeter_command+=" -Gprotocol=$protocol -l ${report_location}/results.jtl"

                    echo "$jmeter_command"
                    # Run JMeter
                    $jmeter_command

                    echo "Writing Server Metrics"
                    write_server_metrics jmeter
                    write_server_metrics ballerina $ballerina_ssh_host ballerina/bre
                    write_server_metrics netty $backend_ssh_host netty
                    write_server_metrics jmeter1 $jmeter1_ssh_host
                    write_server_metrics jmeter2 $jmeter2_ssh_host

                    $HOME/jtl-splitter/jtl-splitter.sh -f ${report_location}/results.jtl -t $warmup_time
                    echo "Generating Dashboard for Warmup Period"
                    mkdir $report_location/dashboard-warmup
                    jmeter -g ${report_location}/results-warmup.jtl -o $report_location/dashboard-warmup
                    echo "Generating Dashboard for Measurement Period"
                    mkdir $report_location/dashboard-measurement
                    jmeter -g ${report_location}/results-measurement.jtl -o $report_location/dashboard-measurement

                    echo "Zipping JTL files in ${report_location}"
                    zip -jm ${report_location}/jtls.zip ${report_location}/results*.jtl

                    scp -q $ballerina_ssh_host:ballerina/logs/ballerina.log ${report_location}/ballerina.log
                    scp -q $ballerina_ssh_host:ballerina/logs/gc.log ${report_location}/ballerina_gc.log
                    scp -q $backend_ssh_host:netty-service/logs/netty.log ${report_location}/netty.log
                    scp -q $backend_ssh_host:netty-service/logs/nettygc.log ${report_location}/netty_gc.log
                    scp -q $jmeter1_ssh_host:jmetergc.log ${report_location}/jmeter1_gc.log
                    scp -q $jmeter2_ssh_host:jmetergc.log ${report_location}/jmeter2_gc.log

                    current_execution_duration="$(measure_time $start_time)"
                    echo -n "# Completed the performance test."
                    echo " $scenario_desc"
                    echo -e "Test execution time: $(format_time $current_execution_duration)\n"
                    record_scenario_duration $scenario_name $current_execution_duration
                done
            done
        done
    done
done

time_header=""
total_duration=""
if [ "$estimate" = true ]; then
    time_header="Estimated"
    total_duration="$(echo "$total_counter*$test_duration" | bc)"
else
    time_header="Actual"
    total_duration="$(measure_time $test_start_time)"
fi

echo "$time_header execution times:"
printf "%-30s  %20s  %50s\n" "Scenario" "Combination(s)" "$time_header Time"
sorted_names=($(
    for name in "${!scenario_counter[@]}"; do
        echo "$name"
    done | sort
))
for name in "${sorted_names[@]}"; do
    printf "%-30s  %20s  %50s\n" "$name" "${scenario_counter[$name]}" "$(format_time ${scenario_duration[$name]})"
done
printf "%30s  %20s  %50s\n" "Total" "$total_counter" "$(format_time $total_duration)"
