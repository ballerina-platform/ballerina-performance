import ballerina/data.xmldata;
import ballerina/http;
import ballerina/log;

configurable string epKeyPath = ?;
configurable string epTrustStorePath = ?;
configurable string epKeyPassword = ?;

listener http:Listener securedEP = new (9090,
    secureSocket = {
        key: {
            path: epKeyPath,
            password: epKeyPassword
        }
    }
);

final http:Client nettyEP = check new ("https://netty:8688",
    secureSocket = {
        cert: {
            path: epTrustStorePath,
            password: epKeyPassword
        },
        verifyHostName: false
    }
);

service /transform on securedEP {
    isolated resource function post .(http:Request req) returns http:Response {
        json|error payload = req.getJsonPayload();
        if payload is error {
            return getErrorResponse(payload, http:STATUS_BAD_REQUEST);
        }
        xml|xmldata:Error? xmlPayload = xmldata:fromJson(payload);
        if xmlPayload is xmldata:Error? {
            return getErrorResponse(xmlPayload, http:STATUS_BAD_REQUEST);
        }
        http:Request clientReq = new;
        clientReq.setXmlPayload(xmlPayload);
        http:Response|http:ClientError response = nettyEP->/'service/EchoService.post(clientReq);
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
