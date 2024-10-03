import ballerina/http;
import ballerina/log;

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

final http:Client nettyEP = check new ("https://netty:8688",
    secureSocket = {
        cert: {
            path: epTrustStorePath,
            password: epKeyPassword
        },
        verifyHostName: false
    }
);

service /passthrough on securedEP {
    isolated resource function post .(http:Request clientRequest) returns http:Response {
        http:Response|http:ClientError response = nettyEP->forward("/service/EchoService", clientRequest);
        if (response is http:Response) {
            return response;
        } else {
            log:printError("Error at h1_h1_passthrough", 'error = response);
            http:Response res = new;
            res.statusCode = 500;
            res.setPayload(response.message());
            return res;
        }
    }
}
