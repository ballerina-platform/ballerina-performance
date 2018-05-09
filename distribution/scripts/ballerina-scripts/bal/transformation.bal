import ballerina/http;

endpoint http:Listener storeServiceEndpoint {
    port:9090
};

@http:ServiceConfig {
    basePath:"/HelloWorld"
}
service HelloWorld bind storeServiceEndpoint {
    @http:ResourceConfig {
        methods:["POST"],
        path:"/sayHello"
    }
    sayHello(endpoint outboundEP, http:Request req) {

        json payload = req.getJsonPayload() but {error => {}};
        xml xmlPayload = check payload.toXML({});
        http:Response res = new;
        res.setXmlPayload(xmlPayload);
        _ = outboundEP -> respond(res);
    }
}