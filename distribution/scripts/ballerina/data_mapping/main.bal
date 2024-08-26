import ballerina/http;

configurable string epKeyPath = ?;
configurable string epKeyPassword = ?;

type Item record {|
    string symbol;
    string buyerID;
    float price;
    int volume;
|};

type OrderItem record {|
    string symbol;
    string purchaser;
    float unitPrice;
    int quantity;
    float totalCost;
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

service /dataMapping on securedEP {
    resource function post .(@http:Payload json data) returns json|error? {
        json 'order = check data.payload.'order;
        Item[] items = check 'order.fromJsonWithType();
        OrderItem[] orderItems = items.'map(item => transform(item));
        return check nettyEP->/'service/EchoService.post(orderItems);
    }
}

function transform(Item item) returns OrderItem => {
    symbol: item.symbol,
    purchaser: item.buyerID,
    unitPrice: item.price,
    quantity: item.volume,
    totalCost: item.price * item.volume
};
