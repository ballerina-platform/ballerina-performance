import ballerina/data.xmldata;
import ballerina/http;

configurable string epKeyPath = ?;
configurable string epKeyPassword = ?;

type Order record {|
    string symbol;
    string buyerID;
    float price;
    int volume;
|};

type Invoice record {|
    Order[] 'order;
|};

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

service /xmlToCsv on securedEP {
    resource function post .(xml payload) returns string|error? {
        Invoice invoice = check xmldata:parseAsType(payload);
        string csvPayload = "symbol, buyerID, price, volume\n";
        csvPayload += string:'join("\n",
                ...invoice.'order.'map(item =>
                        string:'join(",",
                        item.symbol,
                        item.buyerID,
                        item.price.toString(),
                        item.volume.toString())));
        return check nettyEP->/'service/EchoService.post(csvPayload);
    }
}
