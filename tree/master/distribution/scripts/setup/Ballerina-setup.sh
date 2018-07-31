#!/bin/sh

# Copyright (c) 2018, WSO2 Inc. (http://wso2.com) All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#Ballerina Instance setup
#run the script as eg ./Ballerina-setup.sh https://s3.us-east-2.amazonaws.com/ballerinaperformancetest/performance-ballerina/performance-ballerina-distribution-0.1.0-SNAPSHOT.tar.gz https://s3.us-#east-2.amazonaws.com/ballerinaperformancetest/performance-common/performance-common-distribution-0.1.1-SNAPSHOT.tar.gz https://s3.us-east-2.amazonaws.com/ballerinaperformancetest/key-file/ballerinaPT-key-#pair-useast2.pem performance-ballerina-distribution-0.1.0-SNAPSHOT.tar.gz performance-common-distribution-0.1.1-SNAPSHOT.tar.gz 0.980.1



script_dir=$(dirname "$0")
perf_ballerina_dist_url=$1
perf_common_dist_url=$2
key_file=$3
ballerina_dist_version=$4
perf_common_dist_version=$5
ballerina_version=$6
netty_host=$7

cd /home/ubuntu
wget ${perf_ballerina_dist_url}
wget ${perf_common_dist_url}
wget ${key_file}
tar xzf ${ballerina_dist_version}
tar xzf ${perf_common_dist_version}
wget https://product-dist.ballerina.io/downloads/${ballerina_version}/ballerina-platform-linux-installer-x64-${ballerina_version}.deb
sudo dpkg -i ballerina-platform-linux-installer-x64-${ballerina_version}.deb
cd sar
sudo ./install-sar.sh
cd ..
sudo cp /home/ubuntu/ballerina-scripts/bal/passthrough.bal /usr/lib/ballerina/ballerina-${ballerina_version}/bin
sudo cp /home/ubuntu/ballerina-scripts/bal/https_passthrough.bal /usr/lib/ballerina/ballerina-${ballerina_version}/bin
sudo cp /home/ubuntu/ballerina-scripts/bal/transformation.bal /usr/lib/ballerina/ballerina-${ballerina_version}/bin
sudo cp /home/ubuntu/ballerina-scripts/bal/https_transformation.bal /usr/lib/ballerina/ballerina-${ballerina_version}/bin
sudo cp /home/ubuntu/ballerina-scripts/bal/http2_https_passthrough.bal /usr/lib/ballerina/ballerina-${ballerina_version}/bin
sudo cp /home/ubuntu/ballerina-scripts/bal/websocket.bal /usr/lib/ballerina/ballerina-${ballerina_version}/bin
sudo -s <<EOF
echo "$netty_host netty" >> /etc/hosts
EOF
