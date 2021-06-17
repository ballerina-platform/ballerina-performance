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
# Running the Load Test
# ----------------------------------------------------------------------------
set -e

(cd ~/; git clone https://github.com/anuruddhal/ballerina-performance)
echo "$1 perf.test.com" | sudo tee -a /etc/hosts
(cd ~/ballerina-performance/tests/"${2}"/scripts/; ./run.sh "${2}")
(cd ~/ballerina-performance/tests/"${2}"/results/; jtl-splitter.sh -- -f ~/ballerina-performance/tests/"${2}"/results/original.jtl -t 300 -u SECONDS -s)
ls -ltr ~/ballerina-performance/tests/"${2}"/results/
(cd ~/ballerina-performance/tests/"${2}"/results/; JMeterPluginsCMD.sh --generate-csv summary.csv --input-jtl original-measurement.jtl --plugin-type AggregateReport)
