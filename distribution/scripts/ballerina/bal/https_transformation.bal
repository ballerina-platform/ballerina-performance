import ballerina/http;
import ballerina/log;

http:ServiceEndpointConfiguration serviceConfig = {
    secureSocket: {
        keyStore: {
            path: "${ballerina.home}/bre/security/ballerinaKeystore.p12",
            password: "ballerina"
        }
    }
};

http:ClientEndpointConfig sslClientConf = {
    secureSocket: {
        trustStore: {
            path: "${ballerina.home}/bre/security/ballerinaTruststore.p12",
            password: "ballerina"
        },
        verifyHostname: false
    }
};

http:Client nettyEP = new("https://netty:8688", config = sslClientConf);

@http:ServiceConfig { basePath: "/transform" }
service transformationService on new http:Listener(9090, config = serviceConfig) {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/"
    }
    resource function transform(http:Caller caller, http:Request req) {
        json|error payload = req.getJsonPayload();

        if (payload is json) {
            xml|error xmlPayload = payload.toXML({});

            if (xmlPayload is xml) {
                http:Request clinetreq = new;
                clinetreq.setXmlPayload(untaint xmlPayload);

                var response = nettyEP->post("/service/EchoService", clinetreq);

                if (response is http:Response) {
                    var result = caller->respond(response);
                } else {
                    log:printError("Error at https_transformation", err = response);
                    http:Response res = new;
                    res.statusCode = 500;
                    res.setPayload(<string>response.detail().message);
                    var result = caller->respond(res);
                }
            } else {
                log:printError("Error at https_transformation", err = xmlPayload);
                http:Response res = new;
                res.statusCode = 400;
                res.setPayload(untaint <string>xmlPayload.detail().message);
                var result = caller->respond(res);
            }

        } else {
            log:printError("Error at https_transformation", err = payload);
            http:Response res = new;
            res.statusCode = 400;
            res.setPayload(untaint <string>payload.detail().message);
            var result = caller->respond(res);
        }
    }
}
