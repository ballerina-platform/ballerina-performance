import ballerina/http;
import ballerina/log;

listener http:Listener securedEP = new(9090, {
    secureSocket: {
        key: {
            path: "${ballerina.home}/bre/security/ballerinaKeystore.p12",
            password: "ballerina"
        }
    }
});

http:Client nettyEP = check new("https://netty:8688", {
    secureSocket: {
        cert: {
            path: "${ballerina.home}/bre/security/ballerinaTruststore.p12",
            password: "ballerina"
        },
        verifyHostName: false
    }
});

service http:Service /passthrough on securedEP {
    resource function post .(http:Caller caller, http:Request clientRequest) {
        var response = nettyEP->forward("/service/EchoService", clientRequest);
        if (response is http:Response) {
            error? result = caller->respond(<@untainted>response);
        } else {
            log:printError("Error at h1_h1_passthrough", 'error = response);
            http:Response res = new;
            res.statusCode = 500;
            res.setPayload((<@untainted error>response).message());
            error? result = caller->respond(res);
        }
    }
}
