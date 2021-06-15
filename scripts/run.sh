#!/bin/bash -e
# Copyright 2021 WSO2 Inc. (http://wso2.org)
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
# Execusion script for ballerina performance tests
# ----------------------------------------------------------------------------

usage () {
    echo ""
    echo "Usage: "
    echo "$0 [-s <http protocol>] [-n <host name>] [-r resource path>] [-p payload size>]"
    echo ""
    echo "-s: Http protocol ex - <http/https>"
    echo "-n: Host name of the k8s cluster. ex - perf-test.com"
    echo "-r: payload size"
    echo "-p: resource path of the service"
    echo "-u: concurrent users count"
    echo "-d: duration of the test"
    echo ""
    exit 1;
}

while getopts ":s:n:r:p:u:d:" o; do
    case "${o}" in
        s)
            s=${OPTARG}
        ;;
        n)
            n=${OPTARG}
        ;;
        r)
            r=${OPTARG}
        ;;
        p)
            p=${OPTARG}
        ;;
        u)
            u=${OPTARG}
        ;;
        d)
            d=${OPTARG}
        ;;
        *)
            usage
        ;;
    esac
done
shift $((OPTIND-1))

# if [ -z "${s}" ] || [ -z "${n}" ] || [ -z "${r}"] || [ -z "${p}"] || [ -z "${u}"] || [ -z "${d}"]; then
#     usage
# fi

# echo "Http Protocol = ${Juser}"

echo "Http Protocol = ${s}"
echo "Host Name = ${n}"
echo "Resource Path = ${p}"
echo "Payload size = ${r}"
echo "Users count = ${u}"
echo "Duration count = ${d}"

echo "executed"

# Generate Payloads
    # Make payload path

# Choose which jmx to use
    #http / http2 / get / post

# Pass variables for jmeter
# /buildArtifacts/apache-jmeter-4.0/bin/jmeter -n -t /buildArtifacts/scripts/original.jmx -l results.jtl
# /home/anjana/jmeter-test/apache-jmeter-5.3/bin/jmeter -n -t /home/anjana/repos/ballerina-performance/scripts/original.jmx -l results.jtl
echo "/home/anjana/jmeter-test/apache-jmeter-5.3/bin/jmeter -n -t /home/anjana/repos/ballerina-performance/distribution/scripts/jmeter/http-post-request.jmx -l results.jtl -Jusers=${u} -Jduration=${d} -Jhost=${n} -Jport=443 -Jprotocol=${s} -Jpath=${p} -Jresponse_size=${r}"

# -Djavax.net.ssl.keyStoreType=pkcs12 -Djavax.net.ssl.keyStore=/home/anjana/repos/ballerina-performance/scripts/ballerinaTruststore.p12 -Djavax.net.ssl.keyStorePassword=ballerina