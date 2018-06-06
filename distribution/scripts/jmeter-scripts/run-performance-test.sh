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
# Run Performance Tests for Ballerina
# ----------------------------------------------------------------------------

if [[ -d results ]]; then
    echo "Results directory already exists"
    exit 1
fi

jmeter_dir=""
for dir in $HOME/apache-jmeter*; do
    [ -d "${dir}" ] && jmeter_dir="${dir}" && break
done
export JMETER_HOME="${jmeter_dir}"
export PATH=$JMETER_HOME/bin:$PATH

message_size=(50 1024 10240)
concurrent_users=(50 100 500)
ballerina_files=("passthrough.bal" "https_passthrough.bal" "transformation.bal" "https_transformation.bal" "http2_https_passthrough.bal" "websocket.bal")
# Only the default ballerina flag is configured, this can be extended by adding the other required ballerina flags
ballerina_flags=("\ ")
ballerina_flags_name=("default")
ballerina_heap_size=(1G 250M)
backend_sleep_time=(0 30 500 1000)

ballerina_host=10.42.0.6
api_path=/passthrough
websocket_path=/basic/ws
ballerina_ssh_host=ballerina

backend_ssh_host=netty
netty_port=8688

jmeter1_host=192.168.32.12
jmeter2_host=192.168.32.13
jmeter1_ssh_host=jmeter1
jmeter2_ssh_host=jmeter2

payload_type=ARRAY

# Test Duration in seconds
test_duration=600

# Warm-up time in minutes
warmup_time=5

mkdir results
cp $0 results

echo "Generating Payloads in $jmeter1_host"
ssh $jmeter1_ssh_host "./payloads/generate-payloads.sh" $payload_type
echo "Generating Payloads in $jmeter2_host"
ssh $jmeter2_ssh_host "./payloads/generate-payloads.sh" $payload_type


write_server_metrics() {
    server=$1
    ssh_host=$2
    pgrep_pattern=$3
    command_prefix=""
    if [[ ! -z $ssh_host ]]; then
        command_prefix="ssh $ssh_host"
    fi
    $command_prefix ss -s > ${report_location}/${server}_ss.txt
    $command_prefix uptime > ${report_location}/${server}_uptime.txt
    $command_prefix sar -q > ${report_location}/${server}_loadavg.txt
    $command_prefix sar -A > ${report_location}/${server}_sar.txt
    $command_prefix top -bn 1 > ${report_location}/${server}_top.txt
    if [[ ! -z $pgrep_pattern ]]; then
        $command_prefix ps u -p \`pgrep -f $pgrep_pattern\` > ${report_location}/${server}_ps.txt
    fi
}

for heap in ${ballerina_heap_size[@]}
do
    for bal_file in ${ballerina_files[@]}
    do
        COUNTER=-1
        for bal_flags in "${ballerina_flags[@]}"
        do
            COUNTER=$[$COUNTER +1]
            for u in ${concurrent_users[@]}
            do
                for msize in ${message_size[@]}
                do	    
		    #requests served by two jmeter servers
            	      total_users=$(($u * 2))

		    for sleep_time in ${backend_sleep_time[@]}
   	            do
 
                    report_location=$PWD/results/${heap}_heap/${bal_file}_bal/${ballerina_flags_name[$COUNTER]}_flags/${total_users}_users/${msize}B/${sleep_time}ms_sleep

                    echo "Report location is ${report_location}"
                    mkdir -p $report_location

                    echo "Starting ballerina Service"
                    ssh $ballerina_ssh_host "./ballerina-scripts/ballerina-start.sh $heap $bal_file $bal_flags"

		    if [[ ${bal_file} != "websocket.bal" ]]; then
		    echo "Starting Backend Service"
		    ssh $backend_ssh_host "./netty-service/netty-start.sh $sleep_time $netty_port"
		    fi		
		
                    echo "Starting Remote Jmeter server"
		    ssh $jmeter1_ssh_host "./jmeter/jmeter-server-start.sh $jmeter1_host"
                    ssh $jmeter2_ssh_host "./jmeter/jmeter-server-start.sh $jmeter2_host"

                    export JVM_ARGS="-Xms2g -Xmx2g -XX:+PrintGC -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:$report_location/jmeter_gc.log"
                    echo "# Running JMeter. Concurrent Users: $total_users Duration: $test_duration JVM Args: $JVM_ARGS" Ballerina host: $ballerina_host Path: $api_path Flags: $bal_flags

                    # Requests for HTTPS services
		    if [ ${bal_file} == "https_passthrough.bal" ] || [ ${bal_file} == "https_transformation.bal" ]; then
                        echo "Using HTTPS POST request jmx"
                        jmeter -n -t $HOME/jmeter-scripts/post-request-test.jmx -R $jmeter1_host,$jmeter2_host -X \
                            -Gusers=$u -Gduration=$test_duration -Ghost=$ballerina_host -Gport=9090 -Gpath=$api_path \
			    -Gpayload=$HOME/${msize}B.json -Gresponse_size=${msize}B \
                            -Gprotocol=https -l ${report_location}/results.jtl

		    elif [[ ${bal_file} == "http2_https_passthrough.bal" ]]; then
                    echo "Using HTTP2 HTTPS POST request jmx"
                        jmeter -n -t $HOME/jmeter-scripts/HTTP2-post-request.jmx -R $jmeter1_host,$jmeter2_host -X \
                            -Gusers=$u -Gduration=$test_duration -Ghost=$ballerina_host -Gport=9090 -Gpath=$api_path \
                            -Gpayload=$HOME/${msize}B.json -Gresponse_size=${msize}B \
                            -Gprotocol=https -l ${report_location}/results.jtl

		    elif [[ ${bal_file} == "websocket.bal" ]]; then
                     echo "Using Websocket Request Response jmx"
                        jmeter -n -t $HOME/jmeter-scripts/websocket-test.jmx -R $jmeter1_host,$jmeter2_host -X \
                            -Gusers=$u -Gduration=$test_duration -Ghost=$ballerina_host -Gport=9090 -Gpath=$websocket_path \
                            -Gpayload=$HOME/${msize}B.json -Gresponse_size=${msize}B \
                            -l ${report_location}/results.jtl

                    else
                        echo "Using POST request jmx"
                        jmeter -n -t $HOME/jmeter-scripts/post-request-test.jmx -R $jmeter1_host,$jmeter2_host -X \
                            -Gusers=$u -Gduration=$test_duration -Ghost=$ballerina_host -Gport=9090 -Gpath=$api_path \
                            -Gpayload=$HOME/${msize}B.json -Gresponse_size=${msize}B \
                            -Gprotocol=http -l ${report_location}/results.jtl
                    fi

                    echo "Writing Server Metrics"
                    write_server_metrics jmeter
                    write_server_metrics ballerina $ballerina_ssh_host ballerina/bre
		    write_server_metrics netty $backend_ssh_host netty
		    write_server_metrics jmeter1 $jmeter1_ssh_host
                    write_server_metrics jmeter2 $jmeter2_ssh_host

                    $HOME/jtl-splitter/jtl-splitter.sh ${report_location}/results.jtl $warmup_time
                    echo "Generating Dashboard for Warmup Period"
		    mkdir $report_location/dashboard-warmup
                    jmeter -g ${report_location}/results-warmup.jtl -o $report_location/dashboard-warmup
                    echo "Generating Dashboard for Measurement Period"
		    mkdir $report_location/dashboard-measurement
                    jmeter -g ${report_location}/results-measurement.jtl -o $report_location/dashboard-measurement

                    echo "Zipping JTL files in ${report_location}"
                    zip -jm ${report_location}/jtls.zip ${report_location}/results*.jtl

                    scp $ballerina_ssh_host:ballerina/logs/ballerina.log ${report_location}/ballerina.log
                    scp $ballerina_ssh_host:ballerina/logs/gc.log ${report_location}/ballerina_gc.log
		    scp $backend_ssh_host:netty-service/logs/netty.log ${report_location}/netty.log
                    scp $backend_ssh_host:netty-service/logs/nettygc.log ${report_location}/netty_gc.log
		    scp $jmeter1_ssh_host:jmetergc.log ${report_location}/jmeter1_gc.log
                    scp $jmeter2_ssh_host:jmetergc.log ${report_location}/jmeter2_gc.log
		    done                 
		done
            done
        done
    done
done

echo "Completed"
