import ballerina/http;

http:ServiceEndpointConfiguration helloWorldEPConfig = {
    secureSocket: {
        keyStore: {
            path: "${ballerina.home}/bre/security/ballerinaKeystore.p12",
            password: "ballerina"
        }
    }
};

listener http:Listener helloWorldEP = new(9095, config = helloWorldEPConfig);

service passthroughService on helloWorldEP {
    @http:ResourceConfig {
        methods:["POST"],
        path:"/passthrough"
    }
    resource function passthrough (http:Caller caller, http:Request clientRequest) {
        http:Client nettyEP = new("http://netty:8688");
        var response = nettyEP -> forward("/service/EchoService", clientRequest);


        if (response is http:Response) {
                var result = caller -> respond(response);
        } else if (response is error) {
                http:Response res = new;
                res.statusCode = 500;
                res.setPayload(<string> response.detail().message);
                var result = caller->respond(res);

        }
    }
}

