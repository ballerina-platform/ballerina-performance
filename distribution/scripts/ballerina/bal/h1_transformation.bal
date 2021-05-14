import ballerina/http;
import ballerina/log;
import ballerina/xmlutils;

http:ListenerConfiguration serviceConfig = {
    secureSocket: {
        keyStore: {
            path: "${ballerina.home}/bre/security/ballerinaKeystore.p12",
            password: "ballerina"
        }
    }
};

http:ClientConfiguration clientConfig = {
    secureSocket: {
        trustStore: {
            path: "${ballerina.home}/bre/security/ballerinaTruststore.p12",
            password: "ballerina"
        },
        verifyHostname: false
    }
};

http:Client nettyEP = check new("https://netty:8688", clientConfig);

service http:Service /transform on new http:Listener(9090, serviceConfig) {

    resource function post .(http:Caller caller, http:Request req) {
        json|error payload = req.getJsonPayload();

        if (payload is json) {
            xml|error xmlPayload = xmlutils:fromJSON(payload);

            if (xmlPayload is xml) {
                http:Request clinetreq = new;
                clinetreq.setXmlPayload(<@untainted> xmlPayload);

                var response = nettyEP->post("/service/EchoService", clinetreq);

                if (response is http:Response) {
                    var result = caller->respond(<@untainted>response);
                } else {
                    log:printError("Error at h1_transformation", err = <error>response);
                    http:Response res = new;
                    res.statusCode = 500;
                    res.setPayload((<@untainted error>response).message());
                    var result = caller->respond(res);
                }
            } else {
                log:printError("Error at h1_transformation", err = xmlPayload);
                http:Response res = new;
                res.statusCode = 400;
                res.setPayload(<@untainted> xmlPayload.message());
                var result = caller->respond(res);
            }
        } else {
            log:printError("Error at h1_transformation", err = payload);
            http:Response res = new;
            res.statusCode = 400;
            res.setPayload(<@untainted> payload.message());
            var result = caller->respond(res);
        }
    }
}
