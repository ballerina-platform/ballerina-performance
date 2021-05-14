import ballerina/http;
import ballerina/log;

http:ListenerConfiguration serviceConfig = {
    httpVersion: "2.0",
    secureSocket: {
        key: {
            path: "${ballerina.home}/bre/security/ballerinaKeystore.p12",
            password: "ballerina"
        }
    }
};

http:ClientConfiguration clientConfig = {
    secureSocket: {
        cert: {
            path: "${ballerina.home}/bre/security/ballerinaTruststore.p12",
            password: "ballerina"
        },
        verifyHostName: false
    }
};

http:Client nettyEP = check new("https://netty:8688", clientConfig);

service http:Service /passthrough on new http:Listener(9090, serviceConfig) {

    resource function post .(http:Caller caller, http:Request clientRequest) {

        var response = nettyEP->forward("/service/EchoService", clientRequest);

        if (response is http:Response) {
            error? result = caller->respond(<@untainted>response);
        } else {
            log:printError("Error at h2_h1_passthrough", 'error = response);
            http:Response res = new;
            res.statusCode = 500;
            res.setPayload((<@untainted error>response).message());
            error? result = caller->respond(res);
        }
    }
}
