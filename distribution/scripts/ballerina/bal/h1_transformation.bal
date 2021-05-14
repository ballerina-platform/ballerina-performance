import ballerina/http;
import ballerina/log;
import ballerina/xmldata;

http:ListenerConfiguration serviceConfig = {
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

service http:Service /transform on new http:Listener(9090, serviceConfig) {

    resource function post .(http:Caller caller, http:Request req) {
        json|error payload = req.getJsonPayload();

        if (payload is json) {
            xml|xmldata:Error? xmlPayload = xmldata:fromJson(payload);

            if (xmlPayload is xml) {
                http:Request clinetreq = new;
                clinetreq.setXmlPayload(<@untainted> xmlPayload);

                var response = nettyEP->post("/service/EchoService", clinetreq);

                if (response is http:Response) {
                    error? result = caller->respond(<@untainted>response);
                } else {
                    log:printError("Error at h1_transformation", 'error = response);
                    http:Response res = new;
                    res.statusCode = 500;
                    res.setPayload((<@untainted error>response).message());
                    error? result = caller->respond(res);
                }
            } else if (xmlPayload is xmldata:Error) {
                log:printError("Error at h1_transformation", 'error = xmlPayload);
                http:Response res = new;
                res.statusCode = 400;
                res.setPayload(<@untainted> xmlPayload.message());
                error? result = caller->respond(res);
            }
        } else {
            log:printError("Error at h1_transformation", 'error = payload);
            http:Response res = new;
            res.statusCode = 400;
            res.setPayload(<@untainted> payload.message());
            error? result = caller->respond(res);
        }
    }
}
