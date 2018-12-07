import ballerina/http;

@http:ServiceConfig {basePath:"/passthrough"}
service passthroughService on new http:Listener(9090) {

    @http:ResourceConfig {
        methods:["POST"],
        path:"/"
    }
    resource function passthrough(http:Caller caller, http:Request clientRequest) {
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