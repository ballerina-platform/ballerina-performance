// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;

type Response record {|
    json w1;
    json w2;
|};

configurable string epKeyPath = ?;
configurable string epTrustStorePath = ?;
configurable string epKeyPassword = ?;

listener http:Listener securedEP = new (9090,
    secureSocket = {
        key: {
            path: epKeyPath,
            password: epKeyPassword
        }
    }
);

final http:Client nettyEP = check new ("netty:8688",
    secureSocket = {
        cert: {
            path: epTrustStorePath,
            password: epKeyPassword
        },
        verifyHostName: false
    }
);

function convert(json|error data) returns json =>
    data is error ? data.message() : data;

service /serviceChaining on securedEP {
    resource function post .(@http:Payload readonly & json payload) returns json {
        worker w1 {
            json|error response1 = nettyEP->/'service/EchoService.post(payload);
            convert(response1) -> function;
        }

        worker w2 {
            json|error response2 = nettyEP->/'service/EchoService.post(payload);
            convert(response2) -> function;
        }

        Response response = <- {w1, w2};
        return response;
    }
}
