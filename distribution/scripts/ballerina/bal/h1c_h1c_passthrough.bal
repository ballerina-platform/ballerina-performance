import ballerina/http;
import ballerina/log;

http:Client nettyEP = check new("http://netty:8688");

service http:Service /passthrough on new http:Listener(9090) {
    resource function post .(http:Caller caller, http:Request clientRequest) {
        http:Response|http:ClientError response = nettyEP->forward("/service/EchoService", clientRequest);
        if (response is http:Response) {
            error? result = caller->respond(<@untainted>response);
        } else {
            log:printError("Error at h1c_h1c_passthrough", 'error = response);
            http:Response res = new;
            res.statusCode = 500;
            res.setPayload((<@untainted error>response).message());
            error? result = caller->respond(res);
        }
    }
}
