import ballerina/http;
import ballerina/log;

listener http:Listener securedEP = new (9090,
    secureSocket = {
        key: {
            path: "/home/ubuntu/ballerina-performance-distribution-1.1.1-SNAPSHOT/ballerinaKeystore.p12",
            password: "ballerina"
        }
    }
);

final http:Client nettyEP = check new ("https://netty:8688",
    secureSocket = {
        cert: {
            path: "/home/ubuntu/ballerina-performance-distribution-1.1.1-SNAPSHOT/ballerinaTruststore.p12",
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
