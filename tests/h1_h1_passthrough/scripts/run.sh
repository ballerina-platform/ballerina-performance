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

generate-payloads.sh -p array -s 1024
jmeter -n -t /artifacts/tests/h1_h1_passthrough/scripts/http-post-request.jmx -l /artifacts/tests/h1_h1_passthrough/results/original.jtl -Jusers=60 -Jduration=900 -Jhost=perf.test.com -Jport=443 -Jprotocol=https -Jpath=passthrough -Jresponse_size=1024 -Jpayload="echo "$(pwd)"'/1024B.json'"
(cd /artifacts/tests/h1_h1_passthrough/results/; jtl-splitter.sh -- -f /artifacts/tests/h1_h1_passthrough/results/original.jtl -t 300 -u SECONDS -s)