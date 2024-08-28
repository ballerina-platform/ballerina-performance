import ballerina/http;
import ballerina/io;
import ballerina/file;

configurable string epKeyPath = ?;
configurable string epKeyPassword = ?;

const FILE_NAME = "sample.json";

listener http:Listener securedEP = new (9090,
    secureSocket = {
        key: {
            path: epKeyPath,
            password: epKeyPassword
        }
    }
);

service /fileConnector on securedEP {
    resource function post .(@http:Payload json payload) returns json|error {
        check io:fileWriteJson(FILE_NAME, payload);
        json content = check io:fileReadJson(FILE_NAME);
        check file:remove(FILE_NAME);
        return content;
    }
}
