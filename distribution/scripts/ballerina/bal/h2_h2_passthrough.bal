import ballerina/http;
import ballerina/log;

http:ListenerConfiguration serviceConfig = {
    httpVersion: "2.0",
    secureSocket: {
        keyStore: {
            path: "${ballerina.home}/bre/security/ballerinaKeystore.p12",
            password: "ballerina"
        }
    }
};

http:ClientConfiguration clientConfig = {
    httpVersion: "2.0",
    secureSocket: {
        trustStore: {
            path: "${ballerina.home}/bre/security/ballerinaTruststore.p12",
            password: "ballerina"
        },
        verifyHostname: false
    }
};

http:Client nettyEP = new("https://netty:8688", clientConfig);

@http:ServiceConfig { basePath: "/passthrough" }
service passthroughService on new http:Listener(9090, serviceConfig) {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/"
    }
    resource function passthrough(http:Caller caller, http:Request clientRequest) {

        var response = nettyEP->forward("/service/EchoService", clientRequest);

        if (response is http:Response) {
            var result = caller->respond(<@untainted>response);
        } else {
            log:printError("Error at h2_h2_passthrough", <error>response);
            http:Response res = new;
            res.statusCode = 500;
            res.setPayload((<@untainted error>response).message());
            var result = caller->respond(res);
        }
    }
}
