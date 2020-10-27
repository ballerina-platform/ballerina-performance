import ballerina/http;
import ballerina/log;
import ballerina/xmlutils;

http:Client nettyEP = new("http://netty:8688");

@http:ServiceConfig { basePath: "/transform" }
service transformationService on new http:Listener(9090) {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/"
    }
    resource function transform(http:Caller caller, http:Request req) {
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
                    log:printError("Error at h1c_transformation", <error>response);
                    http:Response res = new;
                    res.statusCode = 500;
                    res.setPayload((<@untainted error>response).message());
                    var result = caller->respond(res);
                }
            } else {
                log:printError("Error at h1c_transformation", err = xmlPayload);
                http:Response res = new;
                res.statusCode = 400;
                res.setPayload(<@untainted> xmlPayload.message());
                var result = caller->respond(res);
            }
        } else {
            log:printError("Error at h1c_transformation", err = payload);
            http:Response res = new;
            res.statusCode = 400;
            res.setPayload(<@untainted> payload.message());
            var result = caller->respond(res);
        }
    }
}
