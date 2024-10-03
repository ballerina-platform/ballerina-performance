import ballerina/http;
import ballerina/log;
import ballerina/xmldata;

final http:Client nettyEP = check new ("http://netty:8688");

service /transform on new http:Listener(9090) {
    isolated resource function post .(http:Request req) returns http:Response {
        json|error payload = req.getJsonPayload();
        if payload is error {
            return getErrorResponse(payload, http:STATUS_BAD_REQUEST);
        }
        xml|xmldata:Error? xmlPayload = xmldata:fromJson(payload);
        if xmlPayload is xmldata:Error? {
            return getErrorResponse(xmlPayload, http:STATUS_BAD_REQUEST);
        }
        http:Request clinetreq = new;
        clinetreq.setXmlPayload(xmlPayload);
        http:Response|http:ClientError response = nettyEP->post("/service/EchoService", clinetreq);
        if response is http:ClientError {
            return getErrorResponse(response, http:STATUS_INTERNAL_SERVER_ERROR);
        }
        return response;
    }
}

isolated function getErrorResponse(error? err, int statusCode) returns http:Response {
    log:printError("Error at h1_transformation", 'error = err);
    http:Response res = new;
    res.statusCode = statusCode;
    if err != () {
        res.setPayload(err.message());
    }
    return res;
}
