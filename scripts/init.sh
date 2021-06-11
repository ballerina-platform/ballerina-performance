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
# Installation script for setting up Apache JMeter
# ----------------------------------------------------------------------------

sudo apt-get update
sudo apt-get install openjdk-8-jdk -y
echo '20.62.233.131 perf.test.com' | sudo tee -a /etc/hosts
cd /buildArtifacts/scripts
sudo ./start-jmeter.sh -i /buildArtifacts -d