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
# Run all scripts.
# ----------------------------------------------------------------------------

script_start_time=$(date +%s)
script_dir=$(dirname "$0")
results_dir="$PWD/results-$(date +%Y%m%d%H%M%S)"
ballerina_performance_distribution=""
key_file=""
ballerina_installer_url=""
default_key_name="ballerina-perf-test"
key_name="$default_key_name"
default_s3_bucket_name="ballerinaperformancetest"
s3_bucket_name="$default_s3_bucket_name"
default_s3_bucket_region="us-east-2"
s3_bucket_region="$default_s3_bucket_region"
default_jmeter_client_ec2_instance_type="t2.micro"
jmeter_client_ec2_instance_type="$default_jmeter_client_ec2_instance_type"
default_jmeter_server_ec2_instance_type="t2.micro"
jmeter_server_ec2_instance_type="$default_jmeter_server_ec2_instance_type"
default_ballerina_ec2_instance_type="t2.micro"
ballerina_ec2_instance_type="$default_ballerina_ec2_instance_type"
default_netty_ec2_instance_type="t2.micro"
netty_ec2_instance_type="$default_netty_ec2_instance_type"
default_minimum_stack_creation_wait_time=10
minimum_stack_creation_wait_time=$default_minimum_stack_creation_wait_time

function usage() {
    echo ""
    echo "Usage: "
    echo "$0 -f <ballerina_performance_distribution> -k <key_file> -u <ballerina_installer_url> [-n <key_name>]"
    echo "   [-b <s3_bucket_name>] [-r <s3_bucket_region>]"
    echo "   [-J <jmeter_client_ec2_instance_type>] [-S <jmeter_server_ec2_instance_type>]"
    echo "   [-B <ballerina_ec2_instance_type>] [-N <netty_ec2_instance_type>]"
    echo "   [-w <minimum_stack_creation_wait_time>]"
    echo "   [-h] -- [run_performance_tests_options]"
    echo ""
    echo "-f: The Ballerina Performance Distribution containing the scripts to run performance tests."
    echo "-k: The Amazon EC2 Key File."
    echo "-u: The Ballerina Installer URL."
    echo "-n: The Amazon EC2 Key Name. Default: $default_key_name."
    echo "-b: The Amazon S3 Bucket Name. Default: $default_s3_bucket_name."
    echo "-r: The Amazon S3 Bucket Region. Default: $default_s3_bucket_region."
    echo "-J: The Amazon EC2 Instance Type for JMeter Client. Default: $default_jmeter_client_ec2_instance_type."
    echo "-S: The Amazon EC2 Instance Type for JMeter Server. Default: $default_jmeter_server_ec2_instance_type."
    echo "-B: The Amazon EC2 Instance Type for Ballerina. Default: $default_ballerina_ec2_instance_type."
    echo "-N: The Amazon EC2 Instance Type for Netty (Backend) Service. Default: $default_netty_ec2_instance_type."
    echo "-w: The minimum time to wait in minutes before polling for cloudformation stack's CREATE_COMPLETE status."
    echo "    Default: $default_minimum_stack_creation_wait_time."
    echo "-h: Display this help and exit."
    echo ""
}

while getopts "f:k:n:u:b:r:J:S:B:N:w:h" opts; do
    case $opts in
    f)
        ballerina_performance_distribution=${OPTARG}
        ;;
    k)
        key_file=${OPTARG}
        ;;
    n)
        key_name=${OPTARG}
        ;;
    u)
        ballerina_installer_url=${OPTARG}
        ;;
    b)
        s3_bucket_name=${OPTARG}
        ;;
    r)
        s3_bucket_region=${OPTARG}
        ;;
    J)
        jmeter_client_ec2_instance_type=${OPTARG}
        ;;
    S)
        jmeter_server_ec2_instance_type=${OPTARG}
        ;;
    B)
        ballerina_ec2_instance_type=${OPTARG}
        ;;
    N)
        netty_ec2_instance_type=${OPTARG}
        ;;
    w)
        minimum_stack_creation_wait_time=${OPTARG}
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

run_performance_tests_options="$@"

if [[ ! -f $ballerina_performance_distribution ]]; then
    echo "Please provide Ballerina Performance Distribution."
    exit 1
fi

ballerina_performance_distribution_filename=$(basename $ballerina_performance_distribution)

if [[ ${ballerina_performance_distribution_filename: -7} != ".tar.gz" ]]; then
    echo "Ballerina Performance Distribution must have .tar.gz extension"
    exit 1
fi

if [[ ! -f $key_file ]]; then
    echo "Please provide the key file."
    exit 1
fi

if [[ ${key_file: -4} != ".pem" ]]; then
    echo "AWS EC2 Key file must have .pem extension"
    exit 1
fi

if [[ -z $ballerina_installer_url ]]; then
    echo "Please provide the Ballerina Installer URL."
    exit 1
fi

if [[ -z $key_name ]]; then
    echo "Please provide the key name."
    exit 1
fi

if [[ -z $s3_bucket_name ]]; then
    echo "Please provide S3 bucket name."
    exit 1
fi

if [[ -z $s3_bucket_region ]]; then
    echo "Please provide S3 bucket region."
    exit 1
fi

if [[ -z $jmeter_client_ec2_instance_type ]]; then
    echo "Please provide the Amazon EC2 Instance Type for JMeter Client."
    exit 1
fi

if [[ -z $jmeter_server_ec2_instance_type ]]; then
    echo "Please provide the Amazon EC2 Instance Type for JMeter Server."
    exit 1
fi

if [[ -z $ballerina_ec2_instance_type ]]; then
    echo "Please provide the Amazon EC2 Instance Type for Ballerina."
    exit 1
fi

if [[ -z $netty_ec2_instance_type ]]; then
    echo "Please provide the Amazon EC2 Instance Type for Netty (Backend) Service."
    exit 1
fi

if ! [[ $minimum_stack_creation_wait_time =~ ^[0-9]+$ ]]; then
    echo "Please provide a valid minimum time to wait before polling for cloudformation stack's CREATE_COMPLETE status."
    exit 1
fi

key_filename=$(basename "$key_file")

if [[ "${key_filename%.*}" != "$key_name" ]]; then
    echo "Key file must match with the key name. i.e. $key_filename should be equal to $key_name.pem."
    exit 1
fi

function format_time() {
    # Duration in seconds
    local duration="$1"
    local minutes=$(echo "$duration/60" | bc)
    local seconds=$(echo "$duration-$minutes*60" | bc)
    if [[ $minutes -ge 60 ]]; then
        local hours=$(echo "$minutes/60" | bc)
        minutes=$(echo "$minutes-$hours*60" | bc)
        printf "%d hour(s), %02d minute(s) and %02d second(s)\n" $hours $minutes $seconds
    elif [[ $minutes -gt 0 ]]; then
        printf "%d minute(s) and %02d second(s)\n" $minutes $seconds
    else
        printf "%d second(s)\n" $seconds
    fi
}

function measure_time() {
    local end_time=$(date +%s)
    local start_time=$1
    local duration=$(echo "$end_time - $start_time" | bc)
    echo "$duration"
}

mkdir $results_dir
echo "Results will be downloaded to $results_dir"

temp_dir=$(mktemp -d)

# Get absolute paths
key_file=$(realpath $key_file)
ballerina_performance_distribution=$(realpath $ballerina_performance_distribution)

ln -s $key_file $temp_dir/$key_filename
ln -s $ballerina_performance_distribution $temp_dir/$ballerina_performance_distribution_filename

echo "Syncing files in $temp_dir to S3 Bucket $s3_bucket_name..."
aws s3 sync $temp_dir s3://$s3_bucket_name

# aws s3 cp $key_file s3://$s3_bucket_name
# aws s3 cp $ballerina_performance_distribution s3://$s3_bucket_name

cd $script_dir

echo "Validating stack..."
# Validate stack first
aws cloudformation validate-template --template-body file://ballerina_perf_test_cfn.yaml

stack_create_start_time=$(date +%s)
create_stack_command="aws cloudformation create-stack --stack-name ballerina-test-stack \
    --template-body file://ballerina_perf_test_cfn.yaml --parameters \
    ParameterKey=KeyName,ParameterValue=$key_name \
    ParameterKey=BucketName,ParameterValue=$s3_bucket_name \
    ParameterKey=BucketRegion,ParameterValue=$s3_bucket_region \
    ParameterKey=PerformanceBallerinaDistributionName,ParameterValue=$ballerina_performance_distribution_filename \
    ParameterKey=BallerinaInstallerURL,ParameterValue=$ballerina_installer_url \
    ParameterKey=JMeterClientInstanceType,ParameterValue=$jmeter_client_ec2_instance_type \
    ParameterKey=JMeterServerInstanceType,ParameterValue=$jmeter_server_ec2_instance_type \
    ParameterKey=BallerinaInstanceType,ParameterValue=$ballerina_ec2_instance_type \
    ParameterKey=BackendInstanceType,ParameterValue=$netty_ec2_instance_type \
    --capabilities CAPABILITY_IAM"

echo "Creating stack..."
echo "$create_stack_command"
# Create stack
stack_id="$($create_stack_command)"

echo "Created stack: $stack_id"

# Sleep for sometime before waiting
# This is required since the 'aws cloudformation wait stack-create-complete' will exit with a
# return code of 255 after 120 failed checks. The command polls every 30 seconds, which means that the
# maximum wait time is one hour.
# Due to the dependencies in CloudFormation template, the stack creation may take more than one hour.
echo "Waiting ${minimum_stack_creation_wait_time}m before polling for cloudformation stack's CREATE_COMPLETE status..."
sleep ${minimum_stack_creation_wait_time}m
# Wait till completion
echo "Polling till the stack creation completes..."
aws cloudformation wait stack-create-complete --stack-name $stack_id
printf "Stack creation time: %s\n" "$(format_time $(measure_time $stack_create_start_time))"

echo "Getting JMeter Client Public IP..."

jmeter_client_ip="$(aws cloudformation describe-stacks --stack-name $stack_id --query 'Stacks[0].Outputs[?OutputKey==`JMeterClientPublicIP`].OutputValue' --output text)"

echo "JMeter Client Public IP: $jmeter_client_ip"

# JMeter servers must be 2 (according to the cloudformation script)
run_performance_tests_command="./jmeter/run-performance-tests.sh ${run_performance_tests_options[@]} -n 2"
# Run performance tests
echo "Running performance tests: $run_performance_tests_command"
ssh -i $key_file -o "StrictHostKeyChecking=no" -t ubuntu@$jmeter_client_ip $run_performance_tests_command

scp -i $key_file -o "StrictHostKeyChecking=no" ubuntu@$jmeter_client_ip:results.zip $results_dir

if [[ ! -f $results_dir/results.zip ]]; then
    echo "Failed to download the results.zip"
    exit 500
fi

echo "Creating summary.csv..."
cd $results_dir
tar -xf $ballerina_performance_distribution
unzip -q results.zip
wget -q http://sourceforge.net/projects/gcviewer/files/gcviewer-1.35.jar/download -O gcviewer.jar
./jmeter/create-summary-csv.sh -d results -n Ballerina -p ballerina -j 2 -g gcviewer.jar

echo "Converting summary results to markdown format..."
./jmeter/csv-to-markdown-converter.py summary.csv summary.md

stack_delete_start_time=$(date +%s)
echo "Deleting the stack: $stack_id"
aws cloudformation delete-stack --stack-name $stack_id

echo "Polling till the stack deletion completes..."
aws cloudformation wait stack-delete-complete --stack-name $stack_id
printf "Stack deletion time: %s\n" "$(format_time $(measure_time $stack_delete_start_time))"

printf "Script execution time: %s\n" "$(format_time $(measure_time $script_start_time))"
