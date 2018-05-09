import ballerina/http;

endpoint http:Listener storeServiceEndpoint {
    port:9090
};

@http:ServiceConfig {
    basePath:"/HelloWorld"
}
service HelloWorld bind storeServiceEndpoint {
    @http:ResourceConfig {
        methods:["GET"],
        path:"/sayHello"
    }
    sayHello(endpoint outboundEP, http:Request req) {
        http:Response res = new;
        _ = outboundEP -> respond(res);
    }
}