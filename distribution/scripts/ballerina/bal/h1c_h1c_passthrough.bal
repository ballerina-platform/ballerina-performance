import ballerina/http;
import ballerina/log;

http:Client nettyEP =check new("http://netty:8688");

//@http:ServiceConfig { basePath: "/passthrough" }
service http:Service /passthrough on new http:Listener(9090) {

    //@http:ResourceConfig {
        //methods: ["POST"],
        //path: "/"
    //}
    resource function post .(http:Caller caller, http:Request clientRequest) {
        var response = nettyEP->forward("/service/EchoService", clientRequest);

        if (response is http:Response) {
            var result = caller->respond(<@untainted>response);
        } else {
            log:printError("Error at h1c_h1c_passthrough",err = <error>response);
            http:Response res = new;
            res.statusCode = 500;
            res.setPayload((<@untainted error>response).message());
            var result = caller->respond(res);
        }
    }
}
