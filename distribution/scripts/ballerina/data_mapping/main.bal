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

configurable string epKeyPath = ?;
configurable string epTrustStorePath = ?;
configurable string epKeyPassword = ?;

type Order record {|
    string symbol;
    string buyerID;
    float price;
    int volume;
|};

type OrderItem record {|
    string symbol;
    string purchaser;
    int roundedPrice;
    int quantity;
    float totalCost;
|};

type Invoice record {|
    Order[] 'order;
|};

type Request record {|
    string size;
    Invoice payload;
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
            path: epTrustStorePath,
            password: epKeyPassword
        },
        verifyHostName: false
    }
);

service /dataMapping on securedEP {
    resource function post .(Request request) returns json|error? {
        Order[] orders = request.payload.'order;
        OrderItem[] orderItems = from Order 'order in orders
            select transform('order);
        return nettyEP->/'service/EchoService.post(orderItems);
    }
}

function transform(Order 'order) returns OrderItem => {
    symbol: 'order.symbol,
    purchaser: 'order.buyerID,
    quantity: 'order.volume * 2,
    totalCost: 'order.price * 'order.volume,
    roundedPrice: <int>'order.price
};
