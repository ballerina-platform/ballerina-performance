import ballerina/http;
import ballerina/data.xmldata;

configurable string epKeyPath = ?;
configurable string epKeyPassword = ?;

listener http:Listener securedEP = new (9090,
    secureSocket = {
        key: {
            path: epKeyPath,
            password: epKeyPassword
        }
    }
);

final http:Client nettyEP = check new ("https://netty:8688",
    secureSocket = {
        cert: {
            path: epKeyPath,
            password: epKeyPassword
        },
        verifyHostName: false
    }
);

service /jsonToXml on securedEP {
    resource function post .(@http:Payload json data) returns xml?|error {
        json payload = check data.payload;
        xml? xmlPayload = check xmldata:fromJson(payload);
        return check nettyEP->/'service/EchoService.post(xmlPayload);
    }
}
