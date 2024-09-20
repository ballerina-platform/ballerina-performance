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

import ballerina/data.xmldata;
import ballerina/http;

configurable string epKeyPath = ?;
configurable string epKeyPassword = ?;

type Order record {|
    string symbol;
    string buyerID;
    float price;
    int volume;
|};

type Invoice record {|
    Order[] 'order;
|};

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
            path: epKeyPath,
            password: epKeyPassword
        },
        verifyHostName: false
    }
);

service /xmlToCsv on securedEP {
    resource function post .(xml payload) returns string|error {
        Invoice invoice = check xmldata:parseAsType(payload);
        string csvPayload = "symbol, buyerID, price, volume\n";
        csvPayload += string:'join("\n", ...from Order item in invoice.'order
                    select string `${item.symbol},${item.buyerID},${item.price},${item.volume}`);
        return nettyEP->/'service/EchoService.post(csvPayload);
    }
}
