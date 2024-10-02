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
import ballerinax/java.jms;
import ballerinax/activemq.driver as _;

configurable string epKeyPath = ?;
configurable string epKeyPassword = ?;
configurable string jmsProviderUrl = ?;

const QUEUE_NAME = "order-queue";

listener http:Listener securedEP = new (9090,
    secureSocket = {
        key: {
            path: epKeyPath,
            password: epKeyPassword
        }
    }
);

service /httpToJms on securedEP {
    private final jms:MessageProducer orderProducer;

    function init() returns error? {
        jms:Connection connection = check new (
            initialContextFactory = "org.apache.activemq.jndi.ActiveMQInitialContextFactory",
            providerUrl = jmsProviderUrl
        );

        jms:Session session = check connection->createSession();
        self.orderProducer = check session.createProducer({ 
            'type: jms:QUEUE, 
            name: QUEUE_NAME
        });
    }

    resource function post .(map<json> payload) returns http:Accepted|error {
        jms:MapMessage message = {
            content: payload
        };
        check self.orderProducer->send(message);
        return http:ACCEPTED;
    }
}
