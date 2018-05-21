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
# Setup Ballerina Distro
# ----------------------------------------------------------------------------

script_dir=$(dirname "$0")
netty_host=$2

if [[ -z  $1  ]]; then
    echo "Please provide ballerina version and netty host. Example: $0 ballerina-platform-0.970.0 10.20.30.40"
    exit 1
fi

ballerina_version=$1

ballerina_path="$HOME/${ballerina_version}"

# Extract Ballerina Distro
if [[ ! -f $ballerina_path.zip ]]; then
    echo "Please download ${ballerina_version} to $HOME"
    exit 1
fi
if [[ ! -d $ballerina_path ]]; then
    echo "Extracting Ballerina Distro"
    unzip -q $ballerina_path.zip -d $HOME
    echo "Ballerina Distro is extracted"
else
    echo "Ballerina Distro is already extracted"
    exit 1
fi

mkdir -p ballerina_path/logs/

# TODO: Parameterize the ballerina files being copied
mv $ballerina_path $HOME/ballerina
cp $script_dir/bal/passthrough.bal $HOME/ballerina/bin
cp $script_dir/bal/https_passthrough.bal $HOME/ballerina/bin
cp $script_dir/bal/transformation.bal $HOME/ballerina/bin
cp $script_dir/bal/https_transformation.bal $HOME/ballerina/bin


#Add Netty Host to /etc/hosts
sudo -s <<EOF
echo "$netty_host netty" >> /etc/hosts
EOF

echo "Completed"
