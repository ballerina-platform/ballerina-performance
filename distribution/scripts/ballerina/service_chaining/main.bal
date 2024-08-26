import ballerina/http;

type Person record {|
    string name;
    int age;
|};

type Response record {|
    json w1;
    json w2;
|};

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

function convert(json|error data) returns json {
    if data is error {
        return data.message().toJson();
    }
    return data;
}

service /serviceChaining on securedEP {
    resource function post .(@http:Payload json payload) returns json {
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
