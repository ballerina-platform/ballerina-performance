import ballerina/http;

http:ServiceEndpointConfiguration serviceConfig = {
    httpVersion: "2.0",
    secureSocket: {
        keyStore: {
            path: "${ballerina.home}/bre/security/ballerinaKeystore.p12",
            password: "ballerina"
        }
    }
};

@http:ServiceConfig {basePath:"/passthrough"}
service passthroughService on new http:Listener(9090, config = serviceConfig) {

    http:Client nettyEP = new("http://netty:8688");

    @http:ResourceConfig {
        methods:["POST"],
        path:"/"
    }
    resource function passthrough (http:Caller caller, http:Request clientRequest) {
        
        var response = self.nettyEP -> forward("/service/EchoService", clientRequest);


        if (response is http:Response) {
                var result = caller -> respond(response);
        } else {
                http:Response res = new;
                res.statusCode = 500;
                res.setPayload(<string> response.detail().message);
                var result = caller->respond(res);

        }
    }
}

