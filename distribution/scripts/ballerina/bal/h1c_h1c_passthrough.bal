import ballerina/http;
import ballerina/log;

final http:Client nettyEP = check new ("http://netty:8688");

service /passthrough on new http:Listener(9090) {
    isolated resource function post .(http:Request clientRequest) returns http:Response {
        http:Response|http:ClientError response = nettyEP->forward("/service/EchoService", clientRequest);
        if (response is http:Response) {
            return response;
        } else {
            log:printError("Error at h1_h1_passthrough", 'error = response);
            http:Response res = new;
            res.statusCode = 500;
            res.setPayload(response.message());
            return res;
        }
    }
}
