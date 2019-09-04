//import ballerina/http;
//import ballerina/log;
//
//http:ServiceEndpointConfiguration serviceConfig = {
//    secureSocket: {
//        keyStore: {
//            path: "${ballerina.home}/bre/security/ballerinaKeystore.p12",
//            password: "ballerina"
//        }
//    }
//};
//
//http:ClientEndpointConfig clientConfig = {
//    secureSocket: {
//        trustStore: {
//            path: "${ballerina.home}/bre/security/ballerinaTruststore.p12",
//            password: "ballerina"
//        },
//        verifyHostname: false
//    }
//};
//
//http:Client nettyEP = new("https://netty:8688", clientConfig);
//
//@http:ServiceConfig { basePath: "/transform" }
//service transformationService on new http:Listener(9090, serviceConfig) {
//
//    @http:ResourceConfig {
//        methods: ["POST"],
//        path: "/"
//    }
//    resource function transform(http:Caller caller, http:Request req) {
//        json|error payload = req.getJsonPayload();
//
//        if (payload is json) {
//            xml|error xmlPayload = payload.toXML({});
//
//            if (xmlPayload is xml) {
//                http:Request clinetreq = new;
//                clinetreq.setXmlPayload(<@untainted> xmlPayload);
//
//                var response = nettyEP->post("/service/EchoService", clinetreq);
//
//                if (response is http:Response) {
//                    var result = caller->respond(response);
//                } else {
//                    log:printError("Error at h1_transformation", err = response);
//                    http:Response res = new;
//                    res.statusCode = 500;
//                    res.setPayload(response.detail()?.message);
//                    var result = caller->respond(res);
//                }
//            } else {
//                log:printError("Error at h1_transformation", err = xmlPayload);
//                http:Response res = new;
//                res.statusCode = 400;
//                res.setPayload(<@untainted> xmlPayload.detail()?.message);
//                var result = caller->respond(res);
//            }
//
//        } else {
//            log:printError("Error at h1_transformation", err = payload);
//            http:Response res = new;
//            res.statusCode = 400;
//            res.setPayload(<@untainted> payload.detail()?.message);
//            var result = caller->respond(res);
//        }
//    }
//}
