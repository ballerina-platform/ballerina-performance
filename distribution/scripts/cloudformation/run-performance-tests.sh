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
# Run performance tests on AWS Cloudformation Stacks
# ----------------------------------------------------------------------------

export script_name="$0"
export script_dir=$(dirname "$0")

export ballerina_installer=""
export ballerina_ec2_instance_type=""

export aws_cloudformation_template_filename="ballerina_perf_test_cfn.yaml"
export application_name="Ballerina"
export ec2_instance_name="ballerina"
export metrics_file_prefix="ballerina"

function usageCommand() {
    echo "-p <ballerina_installer> -B <ballerina_ec2_instance_type>"
}
export -f usageCommand

function usageHelp() {
    echo "-i: Ballerina Installer (Debian Package)."
    echo "-B: Amazon EC2 Instance Type for Ballerina."
}
export -f usageHelp

while getopts ":u:f:d:k:n:j:o:g:s:b:r:J:S:N:t:p:w:hi:B:" opt; do
    case "${opt}" in
    i)
        ballerina_installer=${OPTARG}
        ;;
    B)
        ballerina_ec2_instance_type=${OPTARG}
        ;;
    *)
        opts+=("-${opt}")
        [[ -n "$OPTARG" ]] && opts+=("$OPTARG")
        ;;
    esac
done
shift "$((OPTIND - 1))"

function validate() {
    if [[ ! -f $ballerina_installer ]]; then
        echo "Please provide the Ballerina Installer."
        exit 1
    fi

    export ballerina_installer_filename=$(basename $ballerina_installer)

    if [[ ${ballerina_installer_filename: -4} != ".deb" ]]; then
        echo "Ballerina Installer must have .deb extension"
        exit 1
    fi

    if [[ -z $ballerina_ec2_instance_type ]]; then
        echo "Please provide the Amazon EC2 Instance Type for Ballerina."
        exit 1
    fi
}
export -f validate

function create_links() {
    ballerina_installer=$(realpath $ballerina_installer)
    ln -s $ballerina_installer $temp_dir/$ballerina_installer_filename
}
export -f create_links

function get_test_metadata() {
    echo "ballerina_ec2_instance_type=$ballerina_ec2_instance_type"
}
export -f get_test_metadata

function get_cf_parameters() {
    echo "BallerinaInstallerName=$ballerina_installer_filename"
    echo "BallerinaInstanceType=$ballerina_ec2_instance_type"
}
export -f get_cf_parameters

function get_columns() {
    echo "Scenario Name"
    echo "Concurrent Users"
    echo "Message Size (Bytes)"
    echo "Back-end Service Delay (ms)"
    echo "Error %"
    echo "Throughput (Requests/sec)"
    echo "Average Response Time (ms)"
    echo "Standard Deviation of Response Time (ms)"
    echo "99th Percentile of Response Time (ms)"
    echo "Ballerina GC Throughput (%)"
    echo "Average Ballerina Memory Footprint After Full GC (M)"
}
export -f get_columns

$script_dir/cloudformation-common.sh "${opts[@]}" -- "$@"
