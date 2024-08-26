import ballerina/data.jsondata;
import ballerina/http;

configurable string epKeyPath = ?;
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
            path: epKeyPath,
            password: epKeyPassword
        },
        verifyHostName: false
    }
);

service /contentBasedRouting on securedEP {
    resource function post .(@http:Payload json data) returns json|error {
        json prices = check jsondata:read(check data.payload.'order,
                `$..[?(@.symbol == 'GOOG')].price`);
        json[] priceList = check prices.ensureType();
        float googlePrice = check priceList[0].ensureType();
        if googlePrice == 42.8 {
            return check nettyEP->/'service/EchoService.post(googlePrice);
        }
        return check nettyEP->/'service/EchoService.post(prices);
    }
}

