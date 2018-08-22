import ballerina/http;

endpoint http:Listener transformationEP {
    port:9090
};

endpoint http:Client nettyEP {
    url:"http://netty:8688"
};

@http:ServiceConfig {basePath:"/transform"}
service<http:Service> transformationService bind transformationEP {

    @http:ResourceConfig {
        methods:["POST"],
        path:"/"
    }
    transform (endpoint outboundEP, http:Request req) {
	json payload = req.getJsonPayload() but {error => {}};
        xml xmlPayload = check payload.toXML({});
	http:Request clinetreq = new;
        clinetreq.setXmlPayload(untaint xmlPayload);

        var response = nettyEP -> post("/service/EchoService", clinetreq);
        match response {
            http:Response httpResponse => {
                _ = outboundEP -> respond(httpResponse);
            }
            http:error err => {
                http:Response errorResponse = new;
                json errMsg = {"error":"error occurred while invoking the service"};
                errorResponse.setJsonPayload(errMsg);
                _ = outboundEP -> respond(errorResponse);
            }
        }
    }
}
