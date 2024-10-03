import ballerina/http;
import ballerina/log;

listener http:Listener securedEP = new (9090,
    httpVersion = "2.0",
    secureSocket = {
        key: {
            path: "${ballerina.home}/bre/security/ballerinaKeystore.p12",
            password: "ballerina"
        }
    }
);

final http:Client nettyEP = check new ("https://netty:8688",
    httpVersion = "2.0",
    secureSocket = {
        cert: {
            path: "${ballerina.home}/bre/security/ballerinaTruststore.p12",
            password: "ballerina"
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
